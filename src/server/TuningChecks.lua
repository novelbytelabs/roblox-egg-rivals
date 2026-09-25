local C = require(game:GetService("ReplicatedStorage").Stage3Shared.Config)
local R = require(game:GetService("ReplicatedStorage").Stage3Shared.Rules)

local Checks = {}

function Checks.run(g, check, a, b, results)
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

	local serial = 0
	local function place(p, pos)
		g:teleport(p, CFrame.new(pos))
		if not g.clientDiagnostics then
			task.wait(0.15)
			return
		end
		serial += 1
		local token = "tuning-fixture-" .. serial .. "-" .. tostring(g:now())
		g:feed(p, "completionInputProbe", { token = token, kind = "Position", target = pos })
		assert(
			waitFor(function()
				local diag = g.clientDiagnostics[p]
				local root = g:root(p)
				return diag
					and diag.token == token
					and diag.passed
					and root
					and Vector2.new(root.Position.X - pos.X, root.Position.Z - pos.Z).Magnitude <= 3
			end, 5),
			"Tuning fixture position did not settle"
		)
	end

	local function resetLab(p, tuning)
		local pro = g.profiles[p]
		pro.training = false
		pro.lab.momentum = 0
		pro.lab.charge = 0
		pro.lab.untilTime = 0
		pro.lab.tuning = tuning or "Standard"
		pro.base.treadmill:SetAttribute("Tuning", pro.lab.tuning)
		p:SetAttribute("InTrial", false)
		p:SetAttribute("InSprint", false)
		g:applySpeed(p)
	end

	local function integrate(spec, seconds, dt)
		local momentum, charge = 0, 0
		dt = dt or 0.1
		local elapsed = 0
		while elapsed < seconds - 1e-8 do
			local step = math.min(dt, seconds - elapsed)
			local integral
			momentum, integral = R.trainDelta(momentum, step, true, spec.momentumRamp, spec.momentumDecay)
			charge += spec.chargeRate * integral
			elapsed += step
		end
		return momentum, charge
	end

	check("Elemental tuning config preserves Standard and bounded sidegrade tradeoffs", function()
		assert(#C.TuningOrder == 5 and C.TuningOrder[1] == "Standard")
		local s, fire, water, wind, earth =
			C.Tunings.Standard, C.Tunings.Fire, C.Tunings.Water, C.Tunings.Wind, C.Tunings.Earth
		assert(s.momentumRamp == C.MomentumRamp and s.momentumDecay == C.MomentumDecay)
		assert(s.chargeRate == C.OverdriveChargeRate)
		assert(s.overdriveFactor == C.OverdriveFactor and s.overdriveDuration == C.OverdriveDuration)
		assert(fire.chargeRate > s.chargeRate and fire.momentumRamp > s.momentumRamp)
		assert(water.momentumRamp < s.momentumRamp and water.chargeRate < s.chargeRate)
		assert(wind.overdriveFactor > s.overdriveFactor and wind.overdriveDuration < s.overdriveDuration)
		assert(wind.chargeRate < s.chargeRate)
		assert(earth.momentumDecay > s.momentumDecay and earth.chargeRate < s.chargeRate)
		local m1, i1, e1 = R.trainDelta(0.25, 1.3, true)
		local m2, i2, e2 = R.trainDelta(0.25, 1.3, true, s.momentumRamp, s.momentumDecay)
		assert(math.abs(m1 - m2) < 1e-9 and math.abs(i1 - i2) < 1e-9 and math.abs(e1 - e2) < 1e-9)
	end)

	check("Fire, Water and Earth tuning produce the intended training sidegrades", function()
		local standardMomentum10 = select(1, integrate(C.Tunings.Standard, 10))
		local _, standardCharge60 = integrate(C.Tunings.Standard, 60)
		local fireMomentum10 = select(1, integrate(C.Tunings.Fire, 10))
		local _, fireCharge60 = integrate(C.Tunings.Fire, 60)
		local waterMomentum10 = select(1, integrate(C.Tunings.Water, 10))
		local _, waterCharge60 = integrate(C.Tunings.Water, 60)
		assert(fireMomentum10 < standardMomentum10)
		assert(fireCharge60 > standardCharge60)
		assert(waterMomentum10 > standardMomentum10)
		assert(waterCharge60 < standardCharge60)
		local standardDecay =
			select(1, R.trainDelta(1, 5, false, C.Tunings.Standard.momentumRamp, C.Tunings.Standard.momentumDecay))
		local earthDecay =
			select(1, R.trainDelta(1, 5, false, C.Tunings.Earth.momentumRamp, C.Tunings.Earth.momentumDecay))
		assert(earthDecay > standardDecay)
	end)

	check("Tuning selection is free, server-owned and locked against charge or Momentum cherry-picking", function()
		local pro = g.profiles[a]
		resetLab(a)
		local income = g.inventory:income(a.UserId)
		place(a, Vector3.new(0, 4, 90))
		assert(not g.speedLab:setTuning(a, "Fire"))
		place(a, g.world.trainerShop.Position + Vector3.new(0, 3, 3))
		assert(not g.speedLab:setTuning(a, "Void"))
		local wealthBefore = pro.money.Value + pro.coinRemainder
		local started = g:now()
		assert(g.speedLab:setTuning(a, "Fire"))
		local elapsed = math.max(0, g:now() - started)
		local passiveExpected = income * elapsed / 60
		local passiveActual = pro.money.Value + pro.coinRemainder - wealthBefore
		local passiveTolerance = income * 0.2 / 60 + 0.02
		assert(passiveTolerance < 40, "Free-tuning audit is too coarse to detect the smallest Ranger reward")
		assert(
			math.abs(passiveActual - passiveExpected) <= passiveTolerance,
			string.format(
				"Tuning changed Coins beyond passive income: actual %.4f expected %.4f tolerance %.4f",
				passiveActual,
				passiveExpected,
				passiveTolerance
			)
		)
		assert(pro.lab.tuning == "Fire" and g.inventory:income(a.UserId) == income)
		local changes = pro.lab.records.tuningChanges
		assert(g.speedLab:setTuning(a, "Fire") and pro.lab.records.tuningChanges == changes)
		pro.lab.momentum = 0.1
		assert(not g.speedLab:setTuning(a, "Water"))
		pro.lab.momentum = 0
		pro.lab.charge = 1
		assert(not g.speedLab:setTuning(a, "Water"))
		pro.lab.charge = 0
		pro.lab.untilTime = g:now() + 1
		assert(not g.speedLab:setTuning(a, "Water"))
		resetLab(a)
	end)

	check("Wind tuning gives a stronger shorter open-world burst while normalized movement ignores tuning", function()
		local pro = g.profiles[a]
		resetLab(a, "Wind")
		pro.tier = math.max(pro.tier, 4)
		pro.speed.Value = math.min(2200, C.Grades[pro.tier].cap)
		local standard = R.speed(pro.speed.Value, true, C.Tunings.Standard.overdriveFactor)
		local wind = R.speed(pro.speed.Value, true, C.Tunings.Wind.overdriveFactor)
		assert(wind > standard and wind <= C.OverdriveCap)
		pro.lab.charge = 100
		local now = g:now()
		assert(g.speedLab:activate(a))
		assert(math.abs(pro.lab.untilTime - now - C.Tunings.Wind.overdriveDuration) < 0.2)
		assert(math.abs(g:humanoid(a).WalkSpeed - wind) < 0.001, "Wind Overdrive engine speed mismatch")
		pro.lab.untilTime = g:now() + 5
		a:SetAttribute("InTrial", true)
		g:applySpeed(a)
		assert(g:humanoid(a).WalkSpeed == C.TrialSpeed)
		a:SetAttribute("InTrial", false)
		pro.sprint = { phase = "Active", finished = {} }
		a:SetAttribute("InSprint", true)
		g:applySpeed(a)
		assert(g:humanoid(a).WalkSpeed == C.TrialSpeed)
		pro.sprint = nil
		a:SetAttribute("InSprint", false)
		resetLab(a)
	end)

	check("Real client Trainer UI selects the exact authoritative elemental tuning", function()
		local pro = g.profiles[a]
		resetLab(a)
		place(a, g.world.trainerShop.Position + Vector3.new(0, 3, 3))
		local beforeIncome = g.inventory:income(a.UserId)
		local wealthBefore = pro.money.Value + pro.coinRemainder
		local started = g:now()
		g:push(a)
		g:feed(a, "openShop", { shop = "trainer" })
		local token = "tuning-input-" .. tostring(g:now())
		g:feed(a, "completionInputProbe", { token = token, kind = "Tuning", name = "Water" })
		assert(
			waitFor(function()
				local diag = g.clientDiagnostics[a]
				return diag and diag.token == token
			end, 8),
			"Real tuning input probe timed out"
		)
		local diag = g.clientDiagnostics[a]
		results.tuningClientDiagnostics = diag
		assert(diag.passed, diag.error)
		assert(diag.tuning == "Water" and pro.lab.tuning == "Water")
		local elapsed = math.max(0, g:now() - started)
		local passiveExpected = beforeIncome * elapsed / 60
		local passiveActual = pro.money.Value + pro.coinRemainder - wealthBefore
		local passiveTolerance = beforeIncome * 0.2 / 60 + 0.02
		assert(passiveTolerance < 40, "Real tuning audit is too coarse to detect the smallest Ranger reward")
		assert(
			math.abs(passiveActual - passiveExpected) <= passiveTolerance,
			string.format(
				"Real tuning input changed Coins beyond passive income: actual %.4f expected %.4f tolerance %.4f",
				passiveActual,
				passiveExpected,
				passiveTolerance
			)
		)
		assert(g.inventory:income(a.UserId) == beforeIncome)
		resetLab(a)
		g:push(a)
	end)

	resetLab(a)
	resetLab(b)
end

return Checks
