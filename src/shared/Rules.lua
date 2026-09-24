-- Shared, deterministic production rules. Tests exercise these functions directly.
local C = require(script.Parent.Config)
local R = {}
function R.finite(n)
	return type(n) == "number" and n == n and math.abs(n) < 1e12
end
function R.integer(n, lo, hi)
	return R.finite(n) and n % 1 == 0 and n >= lo and n <= hi
end
function R.id(s)
	return type(s) == "string" and #s > 0 and #s <= 80
end
function R.speed(points, overdrive, overdriveFactor)
	if not R.finite(points) then
		return C.BaseWalkSpeed
	end
	local speed = math.clamp(
		C.BaseWalkSpeed + C.SpeedFactor * math.sqrt(math.clamp(points, 0, C.SpeedCap)),
		C.BaseWalkSpeed,
		C.WalkSpeedCap
	)
	local factor = R.finite(overdriveFactor) and overdriveFactor > 0 and overdriveFactor or C.OverdriveFactor
	return overdrive and math.min(C.OverdriveCap, speed * factor) or speed
end
function R.vector(v)
	return typeof(v) == "Vector3" and R.finite(v.X) and R.finite(v.Y) and R.finite(v.Z)
end
function R.nextNight(rng)
	local roll = rng:NextNumber()
	if roll < 0.8 then
		return rng:NextInteger(240, 300)
	end
	if roll < 0.9 then
		return rng:NextInteger(120, 239)
	end
	return rng:NextInteger(301, 600)
end
function R.eligible(item, owner)
	return type(item) == "table"
		and item.ownerId == owner
		and item.state == "Inventory"
		and item.reservation == nil
		and item.duelId == nil
		and not item.locked
		and not item.favorite
end
function R.transferable(item, owner)
	return R.eligible(item, owner) and item.petMode ~= "Active"
end
function R.itemSignature(item)
	if type(item) ~= "table" then
		return "missing"
	end
	return table.concat({
		tostring(item.id),
		tostring(item.ownerId),
		tostring(item.revision),
		tostring(item.kind),
		tostring(item.rarity),
		tostring(item.creature),
		tostring(item.element),
		tostring(item.itemType),
		tostring(item.state),
		tostring(item.reservation),
		tostring(item.locked),
		tostring(item.favorite),
		tostring(item.petMode),
	}, "|")
end
function R.exchangeValue(item)
	if type(item) ~= "table" then
		return 0
	end
	if item.kind == "Item" then
		local spec = C.ItemTypes[item.itemType]
		return spec and spec.exchange or 0
	end
	local spec = C.Rarities[item.rarity]
	if not spec then
		return 0
	end
	if item.kind == "Pet" then
		return spec.income * 8
	end
	if item.kind == "Egg" then
		return math.floor(spec.income * 8 * 0.6)
	end
	return 0
end
function R.clock(seconds)
	if not R.finite(seconds) then
		return "--:--"
	end
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end
function R.within(position, center, halfX, halfZ, height)
	local d = position - center
	return math.abs(d.X) <= halfX and math.abs(d.Z) <= halfZ and d.Y >= -2 and d.Y <= height
end
function R.roll(rng, weights)
	local draw = rng:NextInteger(1, 10000)
	local sum = 0
	for _, rarity in ipairs(C.RarityOrder) do
		sum += weights[rarity] or 0
		if draw <= sum then
			return rarity
		end
	end
	error("Invalid rarity distribution")
end
function R.trainDelta(momentum, dt, training, momentumRamp, momentumDecay)
	assert(R.finite(dt) and dt >= 0, "Invalid training interval")
	momentumRamp = momentumRamp or C.MomentumRamp
	momentumDecay = momentumDecay or C.MomentumDecay
	assert(
		R.finite(momentumRamp) and momentumRamp > 0 and R.finite(momentumDecay) and momentumDecay > 0,
		"Invalid Momentum tuning"
	)
	momentum = math.clamp(momentum, 0, 1)
	if not training then
		return math.max(0, momentum - dt / momentumDecay), 0, 0
	end
	local rise = math.min(dt, (1 - momentum) * momentumRamp)
	local final = math.min(1, momentum + rise / momentumRamp)
	local integral = (momentum + final) * rise * 0.5 + (dt - rise)
	local start = math.clamp((C.EnergyThreshold - momentum) * momentumRamp, 0, rise)
	local a = math.clamp((momentum + start / momentumRamp - C.EnergyThreshold) / (1 - C.EnergyThreshold), 0, 1)
	local b = math.clamp((final - C.EnergyThreshold) / (1 - C.EnergyThreshold), 0, 1)
	local energy = (a + b) * (rise - start) * 0.5 + (dt - rise)
	return final, integral, energy
end
function R.credit(balance, remainder, coinsPerMinute, dt)
	assert(
		R.integer(balance, 0, C.MaxCoins)
			and R.finite(remainder)
			and remainder >= 0
			and remainder < 1.000001
			and R.finite(coinsPerMinute)
			and coinsPerMinute >= 0
			and R.finite(dt)
			and dt >= 0,
		"Invalid currency input"
	)
	local value = remainder + coinsPerMinute * dt / 60
	local whole = math.floor(value + 1e-9)
	return math.min(C.MaxCoins, balance + whole), math.max(0, value - whole)
end
function R.validate()
	assert(#C.RarityOrder == 7 and #C.Creatures == 4 and #C.ElementOrder == 4)
	for _, weights in ipairs({ C.DayWeights, C.NightWeights }) do
		local total = 0
		for rarity, weight in pairs(weights) do
			assert(C.Rarities[rarity] and R.integer(weight, 0, 10000), "Invalid rarity weight")
			total += weight
		end
		assert(total == 10000, "Rarity weights must sum to 10000")
	end
	local previous = 0
	for i, grade in ipairs(C.Grades) do
		assert(
			grade.cap > previous and grade.cap <= C.SpeedCap and grade.rate > 0 and R.integer(grade.cost, 0, C.MaxCoins)
		)
		assert(i ~= 1 or grade.cost == 0)
		previous = grade.cap
	end
	assert(previous == C.SpeedCap)
	for _, rarity in ipairs(C.RarityOrder) do
		local s = C.Rarities[rarity]
		assert(s.hatch > 0 and s.income > 0 and s.boss > 0 and not s.creature, "Rarity cannot imply creature")
	end
	for _, expansion in ipairs(C.Expansions) do
		assert(expansion.capacity == expansion.columns * expansion.rows)
	end
	assert(#C.TuningOrder == 5 and C.TuningOrder[1] == "Standard")
	local seenTunings = {}
	for _, name in ipairs(C.TuningOrder) do
		local tuning = C.Tunings[name]
		assert(tuning and not seenTunings[name], "Invalid elemental tuning identity")
		seenTunings[name] = true
		assert(
			R.finite(tuning.momentumRamp)
				and tuning.momentumRamp > 0
				and R.finite(tuning.momentumDecay)
				and tuning.momentumDecay > 0
				and R.finite(tuning.chargeRate)
				and tuning.chargeRate > 0
				and R.finite(tuning.overdriveFactor)
				and tuning.overdriveFactor >= 1
				and tuning.overdriveFactor <= 1.25
				and R.finite(tuning.overdriveDuration)
				and tuning.overdriveDuration > 0
				and tuning.overdriveDuration <= C.OverdriveDuration,
			"Invalid elemental tuning values"
		)
	end
	local standard = C.Tunings.Standard
	assert(
		standard.momentumRamp == C.MomentumRamp
			and standard.momentumDecay == C.MomentumDecay
			and standard.chargeRate == C.OverdriveChargeRate
			and standard.overdriveFactor == C.OverdriveFactor
			and standard.overdriveDuration == C.OverdriveDuration,
		"Standard tuning must preserve the verified baseline"
	)
	assert(C.Tunings.Fire.chargeRate > standard.chargeRate and C.Tunings.Fire.momentumRamp > standard.momentumRamp)
	assert(C.Tunings.Water.momentumRamp < standard.momentumRamp and C.Tunings.Water.chargeRate < standard.chargeRate)
	assert(
		C.Tunings.Wind.overdriveFactor > standard.overdriveFactor
			and C.Tunings.Wind.overdriveDuration < standard.overdriveDuration
			and C.Tunings.Wind.chargeRate < standard.chargeRate
	)
	assert(C.Tunings.Earth.momentumDecay > standard.momentumDecay and C.Tunings.Earth.chargeRate < standard.chargeRate)
	assert(#C.ForestNestPositions == 12 and R.integer(C.GodlyNestIndex, 1, #C.ForestNestPositions))
	assert(C.GodlyNestRespawn > C.EggRespawnTime)
	for _, position in ipairs(C.ForestNestPositions) do
		assert(
			R.vector(position) and math.abs(position.X) < 90 and position.Z > C.SafeBoundaryZ and position.Z <= 200,
			"Invalid Forest nest"
		)
	end
	assert(C.Visual.LowBudget <= C.Visual.HighBudget and C.Visual.MaxTrailPerObject <= C.Visual.HighBudget)
	assert(C.Visual.TrailLifetime > 0 and C.Visual.EdgePartBudget > 0 and C.Visual.EdgeWidth > 0)
	return true
end
return R
