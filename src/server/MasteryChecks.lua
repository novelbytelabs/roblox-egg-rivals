local C = require(game:GetService("ReplicatedStorage").Stage3Shared.Config)
local R = require(game:GetService("ReplicatedStorage").Stage3Shared.Rules)
local Checks = {}

local function waitFor(fn, seconds)
	local deadline = os.clock() + seconds
	repeat
		if fn() then
			return true
		end
		task.wait(0.05)
	until os.clock() > deadline
	return false
end

local function snapshot(pro)
	return {
		tier = pro.tier,
		speed = pro.speed.Value,
		precision = pro.lab.precision,
		charge = pro.lab.charge,
		untilTime = pro.lab.untilTime,
		slowUntil = pro.slowUntil,
		duel = pro.duel,
		sprint = pro.sprint,
		inTrial = false,
	}
end

local function restore(g, p, saved)
	local pro = g.profiles[p]
	pro.tier = saved.tier
	pro.speed.Value = saved.speed
	pro.lab.precision = saved.precision
	pro.lab.charge = saved.charge
	pro.lab.untilTime = saved.untilTime
	pro.slowUntil = saved.slowUntil
	pro.duel = saved.duel
	pro.sprint = saved.sprint
	p:SetAttribute("InDuel", false)
	p:SetAttribute("InTrial", false)
	pro.base.treadmill:SetAttribute("Precision", saved.precision == true)
	g:applySpeed(p)
	g:push(p)
end

function Checks.run(g, check, a)
	check("Speed Mastery unlocks Precision without changing permanent Speed", function()
		local pro = g.profiles[a]
		local saved = snapshot(pro)
		local beforeMoney = pro.money.Value
		local beforeRemainder = pro.coinRemainder
		local beforeToggles = pro.lab.records.precisionToggles or 0
		pro.slowUntil = 0
		pro.duel, pro.sprint = nil, nil
		a:SetAttribute("InDuel", false)
		a:SetAttribute("InTrial", false)
		pro.lab.untilTime = 0
		pro.lab.charge = 0
		pro.lab.precision = false
		pro.tier = C.PrecisionUnlockTier - 1
		pro.speed.Value = math.min(C.Grades[pro.tier].cap, 600)
		assert(not g.speedLab:setPrecision(a, true))
		assert(not pro.lab.precision and (pro.lab.records.precisionToggles or 0) == beforeToggles)

		pro.tier = C.PrecisionUnlockTier
		pro.speed.Value = C.Grades[pro.tier].cap
		local permanent = pro.speed.Value
		local normal = R.speed(permanent, false, g.speedLab:spec(pro).overdriveFactor)
		assert(g.speedLab:setPrecision(a, true))
		local expected = math.max(C.BaseWalkSpeed, normal * C.PrecisionFactor)
		assert(math.abs(g:humanoid(a).WalkSpeed - expected) < 0.001)
		assert(pro.speed.Value == permanent)
		assert(g.speedLab:setPrecision(a, false))
		assert(math.abs(g:humanoid(a).WalkSpeed - normal) < 0.001)
		assert((pro.lab.records.precisionToggles or 0) == beforeToggles + 2)
		assert(pro.money.Value == beforeMoney and pro.coinRemainder == beforeRemainder)
		restore(g, a, saved)
	end)

	check("Precision never overrides Snare, Trial, Sprint or Duel movement authority", function()
		local pro = g.profiles[a]
		local saved = snapshot(pro)
		pro.tier = C.PrecisionUnlockTier
		pro.speed.Value = C.Grades[pro.tier].cap
		pro.lab.precision = true
		pro.lab.untilTime = 0
		pro.slowUntil = g:now() + 5
		g:applySpeed(a)
		assert(g:humanoid(a).WalkSpeed == 6)

		pro.slowUntil = 0
		a:SetAttribute("InTrial", true)
		g:applySpeed(a)
		assert(g:humanoid(a).WalkSpeed == C.TrialSpeed)
		a:SetAttribute("InTrial", false)

		pro.sprint = { phase = "Active", finished = {} }
		g:applySpeed(a)
		assert(g:humanoid(a).WalkSpeed == C.TrialSpeed)
		pro.sprint = nil

		pro.duel = { phase = "Active" }
		a:SetAttribute("InDuel", true)
		g:applySpeed(a)
		assert(g:humanoid(a).WalkSpeed == C.DuelWalkSpeed)
		pro.duel = nil
		a:SetAttribute("InDuel", false)

		local normalBurst = R.speed(pro.speed.Value, true, g.speedLab:spec(pro).overdriveFactor)
		pro.lab.untilTime = g:now() + 5
		g:applySpeed(a)
		assert(math.abs(g:humanoid(a).WalkSpeed - math.max(C.BaseWalkSpeed, normalBurst * C.PrecisionFactor)) < 0.001)
		restore(g, a, saved)
	end)

	check("Hyper Speed Mastery cuts active Overdrive with no refund or duplicate use", function()
		local pro = g.profiles[a]
		local saved = snapshot(pro)
		local beforeMoney = pro.money.Value
		local beforeRemainder = pro.coinRemainder
		local beforeUsed = pro.lab.records.overdrivesUsed or 0
		local beforeCuts = pro.lab.records.overdriveCuts or 0
		pro.duel, pro.sprint = nil, nil
		pro.slowUntil = 0
		a:SetAttribute("InDuel", false)
		a:SetAttribute("InTrial", false)
		pro.lab.precision = false
		pro.lab.charge = 100
		pro.lab.untilTime = 0
		pro.tier = C.OverdriveCutUnlockTier - 1
		assert(g.speedLab:activate(a))
		local lockedUntil = pro.lab.untilTime
		assert(lockedUntil > g:now() and not g.speedLab:activate(a))
		assert(pro.lab.untilTime == lockedUntil and pro.lab.charge == 0)
		pro.lab.untilTime = 0

		pro.tier = C.OverdriveCutUnlockTier
		pro.lab.charge = 100
		assert(g.speedLab:activate(a))
		assert((pro.lab.records.overdrivesUsed or 0) == beforeUsed + 2)
		assert(pro.lab.charge == 0 and pro.lab.untilTime > g:now())
		assert(g.speedLab:activate(a))
		assert(pro.lab.untilTime == 0 and pro.lab.charge == 0)
		assert((pro.lab.records.overdrivesUsed or 0) == beforeUsed + 2)
		assert((pro.lab.records.overdriveCuts or 0) == beforeCuts + 1)
		assert(pro.money.Value == beforeMoney and pro.coinRemainder == beforeRemainder)
		restore(g, a, saved)
	end)

	check("Real client C input toggles authoritative Precision Mode", function()
		local pro = g.profiles[a]
		local saved = snapshot(pro)
		pro.duel, pro.sprint = nil, nil
		pro.slowUntil = 0
		a:SetAttribute("InDuel", false)
		a:SetAttribute("InTrial", false)
		pro.tier = C.PrecisionUnlockTier
		pro.speed.Value = C.Grades[pro.tier].cap
		pro.lab.precision = false
		pro.lab.charge = 0
		pro.lab.untilTime = 0
		g:applySpeed(a)
		g:push(a)
		local token = "mastery-input-" .. tostring(g:now())
		g:feed(a, "completionInputProbe", { token = token, kind = "Mastery" })
		assert(
			waitFor(function()
				local diag = g.clientDiagnostics and g.clientDiagnostics[a]
				return diag and diag.token == token and diag.passed and diag.precision == true
			end, 6),
			"Real client Precision input did not complete"
		)
		assert(pro.lab.precision == true)
		assert(g.speedLab:setPrecision(a, false))
		restore(g, a, saved)
	end)
end

return Checks
