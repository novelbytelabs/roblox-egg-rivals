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
		momentum = 0,
		charge = 0,
		energy = 0,
		untilTime = 0,
		fraction = 0,
		sync = 0,
		milestone = 0,
		records = { trainingSeconds = 0, distance = 0, bestMomentum = 0, overdrivesUsed = 0, overdrivesEarned = 0 },
	}
end
function SpeedLab:step(p, dt, now)
	local g = self.game
	local pro = g.profiles[p]
	local lab = pro.lab
	local grade = C.Grades[pro.tier]
	local training = pro.training == true
	local momentum, integral, energyIntegral = R.trainDelta(lab.momentum, dt, training)
	lab.momentum = momentum
	pro.speed.Value = math.clamp(pro.speed.Value, 0, grade.cap)
	if training then
		lab.fraction += grade.rate * (dt + C.MomentumBonus * integral)
		local whole = math.floor(lab.fraction + 1e-9)
		pro.speed.Value = math.min(grade.cap, pro.speed.Value + whole)
		lab.fraction = math.max(0, lab.fraction - whole)
		if pro.speed.Value >= grade.cap then
			lab.fraction = 0
		end
		local before = lab.charge
		if now >= lab.untilTime then
			lab.charge = math.min(100, lab.charge + C.OverdriveChargeRate * integral)
		end
		if before < 100 and lab.charge >= 100 then
			lab.records.overdrivesEarned += 1
			g:notify(p, "Overdrive ready! Q gives a five-second escape burst.", "win")
		end
		lab.energy = math.min(100, lab.energy + C.EnergyRate * energyIntegral)
		lab.records.trainingSeconds += dt
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
			.. "%"
	end
end
function SpeedLab:activate(p)
	local g = self.game
	if not g:alive(p) or g:busy(p) then
		return false, "Overdrive is for open-world movement only."
	end
	local lab = g.profiles[p].lab
	if lab.charge < 100 or lab.untilTime > g:now() then
		return false, "Train to fully charge Overdrive."
	end
	lab.charge = 0
	lab.untilTime = g:now() + C.OverdriveDuration
	lab.records.overdrivesUsed += 1
	g:applySpeed(p)
	g:effect("overdrive", { position = g:root(p).Position, userId = p.UserId })
	g:notify(p, "OVERDRIVE • five seconds!", "pickup")
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
	return {
		grade = pro.tier,
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
