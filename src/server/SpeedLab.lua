local Shared = game:GetService("ReplicatedStorage").Stage3Shared
local C = require(Shared.Config)
local R = require(Shared.Rules)
local SpeedLab = {}
SpeedLab.__index = SpeedLab
function SpeedLab.new(gameService)
	return setmetatable({ game = gameService }, SpeedLab)
end
function SpeedLab:setup(pro)
	pro.lab = {
		tuning = "Standard",
		precision = false,
		momentum = 0,
		charge = 0,
		energy = 0,
		untilTime = 0,
		fraction = 0,
		sync = 0,
		milestone = 0,
		records = {
			trainingSeconds = 0,
			distance = 0,
			bestMomentum = 0,
			overdrivesUsed = 0,
			overdrivesEarned = 0,
			sprintEntered = 0,
			sprintWins = 0,
			sprintDNFs = 0,
			bestSprint = nil,
			sprintStreak = 0,
			bestSprintStreak = 0,
			tuningChanges = 0,
			draftingSeconds = 0,
			precisionToggles = 0,
			overdriveCuts = 0,
		},
	}
	pro.base.treadmill:SetAttribute("Tuning", "Standard")
	pro.base.treadmill:SetAttribute("Drafting", false)
	pro.base.treadmill:SetAttribute("DraftBonus", C.DraftBonus)
	pro.base.treadmill:SetAttribute("Precision", false)
end
function SpeedLab:spec(pro)
	local lab = pro and pro.lab
	return C.Tunings[(lab and lab.tuning) or "Standard"] or C.Tunings.Standard
end
function SpeedLab:trainingMultiplier(pro)
	return pro and pro.drafting == true and (1 + C.DraftBonus) or 1
end
function SpeedLab:mastery(pro)
	return {
		precisionUnlocked = pro ~= nil and pro.tier >= C.PrecisionUnlockTier,
		overdriveCutUnlocked = pro ~= nil and pro.tier >= C.OverdriveCutUnlockTier,
	}
end
function SpeedLab:step(p, dt, now)
	local g = self.game
	local pro = g.profiles[p]
	local lab = pro.lab
	local grade = C.Grades[pro.tier]
	local training = pro.training == true
	local drafting = training and pro.drafting == true
	local draftMultiplier = self:trainingMultiplier(pro)
	local tuning = self:spec(pro)
	local momentum, integral, energyIntegral =
		R.trainDelta(lab.momentum, dt, training, tuning.momentumRamp, tuning.momentumDecay)
	lab.momentum = momentum
	pro.speed.Value = math.clamp(pro.speed.Value, 0, grade.cap)
	if training then
		local speedBefore = pro.speed.Value
		lab.fraction += grade.rate * draftMultiplier * (dt + C.MomentumBonus * integral)
		local whole = math.floor(lab.fraction + 1e-9)
		pro.speed.Value = math.min(grade.cap, pro.speed.Value + whole)
		lab.fraction = math.max(0, lab.fraction - whole)
		if pro.speed.Value >= grade.cap then
			lab.fraction = 0
		end
		if pro.speed.Value > speedBefore then
			g.contracts:observe(p, "speed", { value = pro.speed.Value })
		end
		local before = lab.charge
		if now >= lab.untilTime then
			lab.charge = math.min(100, lab.charge + tuning.chargeRate * integral)
		end
		if before < 100 and lab.charge >= 100 then
			lab.records.overdrivesEarned += 1
			g:notify(p, "Overdrive ready! Q gives a five-second escape burst.", "win")
		end
		lab.energy = math.min(100, lab.energy + C.EnergyRate * energyIntegral)
		lab.records.trainingSeconds += dt
		if drafting then
			lab.records.draftingSeconds += dt
		end
		lab.records.distance += R.speed(pro.speed.Value) * dt
		lab.records.bestMomentum = math.max(lab.records.bestMomentum, momentum)
		if pro.speed.Value >= 60 then
			pro.tutorial = math.max(2, pro.tutorial)
		end
	else
		lab.energy = math.max(0, lab.energy - C.EnergyDrain * dt)
	end
	local milestone = lab.milestone
	while C.SpeedMilestones[lab.milestone + 1] and pro.speed.Value >= C.SpeedMilestones[lab.milestone + 1] do
		lab.milestone += 1
	end
	if milestone ~= lab.milestone then
		g:effect("milestone", { position = pro.base.treadmill.Position, userId = p.UserId })
		g:notify(p, "Speed milestone: " .. C.SpeedMilestones[lab.milestone] .. "! Your ranch is cheering.", "win")
		if g.ranch then
			g.ranch:homecoming(p, "record")
		end
	end
	if lab.untilTime > 0 and now >= lab.untilTime then
		lab.untilTime = 0
		g:applySpeed(p)
	end
	lab.sync += dt
	if lab.sync >= 0.25 then
		lab.sync = 0
		pro.base.treadmill:SetAttribute("Momentum", math.floor(lab.momentum * 100) / 100)
		pro.base.treadmill:SetAttribute("Energy", math.floor(lab.energy))
		pro.base.treadmill:SetAttribute("Training", training)
		pro.base.treadmill:SetAttribute("Drafting", drafting)
		pro.base.treadmill:SetAttribute("DraftBonus", C.DraftBonus)
		pro.base.recordLabel.Text = grade.name:upper()
			.. " LAB • "
			.. grade.rate
			.. "/s\nSPEED "
			.. pro.speed.Value
			.. " / "
			.. grade.cap
			.. "\nMOMENTUM "
			.. math.floor(lab.momentum * 100)
			.. "% • POWER "
			.. math.floor(lab.energy)
			.. "%\nTUNE "
			.. lab.tuning:upper()
			.. (drafting and ("\nDRAFT +" .. math.floor(C.DraftBonus * 100) .. "%") or "")
			.. (lab.precision and ("\nPRECISION " .. math.floor(C.PrecisionFactor * 100) .. "%") or "")
	end
end
function SpeedLab:activate(p)
	local g = self.game
	if not g:alive(p) or g:busy(p) then
		return false, "Overdrive is for open-world movement only."
	end
	local pro = g.profiles[p]
	local lab = pro.lab
	local now = g:now()
	if lab.untilTime > now then
		if pro.tier < C.OverdriveCutUnlockTier then
			return false, "Hyper Speed Mastery is required to cut Overdrive early."
		end
		lab.untilTime = 0
		lab.records.overdriveCuts += 1
		g:applySpeed(p)
		g:notify(p, "OVERDRIVE CUT • no charge refunded", "tick")
		g:push(p)
		return true
	end
	if lab.charge < 100 then
		return false, "Train to fully charge Overdrive."
	end
	local tuning = self:spec(pro)
	lab.charge = 0
	lab.untilTime = now + tuning.overdriveDuration
	lab.records.overdrivesUsed += 1
	g:applySpeed(p)
	g:effect("overdrive", { position = g:root(p).Position, userId = p.UserId })
	g:notify(
		p,
		string.format("OVERDRIVE • %.1fs • %s tune", tuning.overdriveDuration, lab.tuning:upper()),
		"pickup"
	)
	g:push(p)
	return true
end
function SpeedLab:setPrecision(p, active)
	local g = self.game
	local pro = g.profiles[p]
	if type(active) ~= "boolean" or not pro or not g:alive(p) or g:busy(p) then
		return false, "Precision Mode is unavailable right now."
	end
	if pro.tier < C.PrecisionUnlockTier then
		return false, "Install Turbo to unlock Precision Mode."
	end
	local lab = pro.lab
	if lab.precision == active then
		return true
	end
	lab.precision = active
	lab.records.precisionToggles += 1
	pro.base.treadmill:SetAttribute("Precision", active)
	g:applySpeed(p)
	g:notify(p, active and "PRECISION MODE • controlled open-world pace" or "PRECISION MODE OFF", "tick")
	g:push(p)
	return true
end
function SpeedLab:setTuning(p, name)
	local g = self.game
	local pro = g.profiles[p]
	local tuning = type(name) == "string" and C.Tunings[name] or nil
	if not pro or not tuning or not g:alive(p) or g:busy(p) then
		return false, "That tuning mode is unavailable."
	end
	local root = g:root(p)
	if
		not root
		or (
			(root.Position - pro.base.treadmill.Position).Magnitude > 20
			and (root.Position - g.world.trainerShop.Position).Magnitude > C.ShopRange
		)
	then
		return false, "Visit Trainer Workshop or your own Speed Lab to change tuning."
	end
	local state = pro.lab
	if state.momentum > 0.001 or state.charge > 0.001 or state.untilTime > g:now() then
		return false, "Let Momentum and Overdrive return to zero before changing tuning."
	end
	if state.tuning == name then
		return true
	end
	state.tuning = name
	state.records.tuningChanges += 1
	pro.base.treadmill:SetAttribute("Tuning", name)
	g:notify(p, name:upper() .. " tuning selected • " .. tuning.description, "tick")
	g:push(p)
	return true
end

function SpeedLab:buy(p, nextTier)
	local g = self.game
	local pro = g.profiles[p]
	if not g:alive(p) or g:busy(p) or not R.integer(nextTier, 2, #C.Grades) or nextTier ~= pro.tier + 1 then
		return false, "That upgrade is stale or unavailable."
	end
	local pos = g:root(p).Position
	if
		(pos - pro.base.treadmill.Position).Magnitude > 20
		and (pos - g.world.trainerShop.Position).Magnitude > C.ShopRange
	then
		return false, "Visit Trainer Workshop or your own Speed Lab."
	end
	local grade = C.Grades[nextTier]
	if pro.money.Value < grade.cost then
		return false, "Need " .. grade.cost .. " Coins for " .. grade.name .. "."
	end
	pro.money.Value -= grade.cost
	pro.tier = nextTier
	if pro.hatched > 0 then
		pro.tutorial = 6
		pro.onboardingComplete = true
	end
	pro.base.applyGrade(nextTier)
	g:notify(p, grade.name .. " installed. Your Speed is preserved.", "win")
	g:push(p)
	return true
end
function SpeedLab:snapshot(p)
	local pro = self.game.profiles[p]
	local lab = pro.lab
	local tuning = self:spec(pro)
	local mastery = self:mastery(pro)
	return {
		grade = pro.tier,
		precision = lab.precision == true,
		precisionUnlocked = mastery.precisionUnlocked,
		precisionFactor = C.PrecisionFactor,
		overdriveCutUnlocked = mastery.overdriveCutUnlocked,
		tuning = lab.tuning,
		tuningDescription = tuning.description,
		drafting = pro.drafting == true,
		draftBonus = C.DraftBonus,
		tuningSpec = {
			momentumRamp = tuning.momentumRamp,
			momentumDecay = tuning.momentumDecay,
			chargeRate = tuning.chargeRate,
			overdriveFactor = tuning.overdriveFactor,
			overdriveDuration = tuning.overdriveDuration,
		},
		gradeName = C.Grades[pro.tier].name,
		rate = C.Grades[pro.tier].rate,
		cap = C.Grades[pro.tier].cap,
		momentum = lab.momentum,
		charge = lab.charge,
		energy = lab.energy,
		untilTime = lab.untilTime,
		records = table.clone(lab.records),
	}
end
return SpeedLab
