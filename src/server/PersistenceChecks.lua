local HttpService = game:GetService("HttpService")
local C = require(game:GetService("ReplicatedStorage").Stage3Shared.Config)
local Schema = require(script.Parent.PersistenceSchema)
local Checks = {}

local function copy(value)
	return HttpService:JSONDecode(HttpService:JSONEncode(value))
end

local function pure(value, seen)
	local kind = typeof(value)
	if kind == "nil" or kind == "string" or kind == "number" or kind == "boolean" then
		return true
	end
	if kind ~= "table" then
		return false
	end
	seen = seen or {}
	if seen[value] then
		return false
	end
	seen[value] = true
	for key, child in pairs(value) do
		local keyType = typeof(key)
		if (keyType ~= "string" and keyType ~= "number") or not pure(child, seen) then
			return false
		end
	end
	seen[value] = nil
	return true
end

local function findItem(record, id)
	for _, item in ipairs(record.items) do
		if item.id == id then
			return item
		end
	end
end

function Checks.run(g, check, a, b, results)
	local pro = assert(g.profiles[a])
	assert(not g:busy(a) and not g.carry[a], "Persistence fixture requires a free player")
	local baseline, baselineErr = Schema.capture(g, a)
	assert(baseline, baselineErr)

	check("Persistence schema captures only DataStore-safe durable state", function()
		assert(baseline.version == Schema.VERSION and baseline.userId == a.UserId)
		assert(pure(baseline))
		local encoded = HttpService:JSONEncode(baseline)
		assert(type(encoded) == "string" and #encoded > 20)
		assert(baseline.trade == nil and baseline.duel == nil and baseline.trial == nil and baseline.sprint == nil)
		assert(baseline.progression and baseline.lab and baseline.items and baseline.incubations)
	end)

	check("Persistence capture refuses unresolved item transaction state without mutation", function()
		local item = assert(g.inventory:list(a.UserId)[1])
		local state, reservation, duelId, revision = item.state, item.reservation, item.duelId, item.revision
		item.state = "Trade"
		local record = Schema.capture(g, a)
		assert(record == nil)
		item.state, item.reservation, item.duelId, item.revision = state, reservation, duelId, revision
		local restored, err = Schema.capture(g, a)
		assert(restored, err)
	end)

	check("Persistence validation rejects wrong owner, impossible progression, duplicate and sparse inventory", function()
		local wrongOwner = copy(baseline)
		wrongOwner.userId = b.UserId
		assert(Schema.validate(wrongOwner, a.UserId) == nil)
		local impossible = copy(baseline)
		impossible.progression.speed = C.Grades[impossible.progression.tier].cap + 1
		assert(Schema.validate(impossible, a.UserId) == nil)
		local duplicate = copy(baseline)
		assert(duplicate.items[1])
		table.insert(duplicate.items, copy(duplicate.items[1]))
		assert(Schema.validate(duplicate, a.UserId) == nil)
		local sparse = copy(baseline)
		local first = sparse.items[1]
		sparse.items[1] = nil
		sparse.items[2] = first
		assert(Schema.validate(sparse, a.UserId) == nil)
	end)

	check("Persistence schema round-trips exact durable profile state and resets transient lab state", function()
		local tier = math.min(3, #C.Grades)
		pro.tier = tier
		pro.speed.Value = math.min(123, C.Grades[tier].cap)
		pro.money.Value = math.min(4321, C.MaxCoins)
		pro.coinRemainder = 0.375
		pro.tutorial = 6
		pro.onboardingComplete = true
		pro.hatched = 7
		pro.ranchLevel = math.min(2, #C.Expansions - 1)
		pro.duelWeapon = C.DuelWeapons.Rail and "Rail" or "Blaster"
		pro.baseTheme = C.BazaarThemes.Water and "Water" or "Standard"
		pro.base.applyGrade(pro.tier)
		pro.base.applyExpansion(pro.ranchLevel)
		pro.base.applyTheme(pro.baseTheme)
		pro.lab.tuning = C.Tunings.Wind and "Wind" or "Standard"
		pro.lab.milestone = math.min(2, #C.SpeedMilestones)
		pro.lab.records.trainingSeconds = 123.5
		pro.lab.records.distance = 987.25
		pro.lab.records.bestMomentum = 0.82
		pro.lab.records.overdrivesUsed = 4
		pro.lab.records.overdrivesEarned = 5
		pro.lab.records.sprintEntered = 6
		pro.lab.records.sprintWins = 3
		pro.lab.records.sprintDNFs = 1
		pro.lab.records.bestSprint = 18.75
		pro.lab.records.sprintStreak = 2
		pro.lab.records.bestSprintStreak = 4
		pro.lab.records.tuningChanges = 3
		pro.lab.records.draftingSeconds = 44.5
		pro.lab.records.precisionToggles = 7
		pro.lab.records.overdriveCuts = 2
		pro.lab.momentum = 0.77
		pro.lab.charge = 81
		pro.lab.energy = 66
		pro.lab.precision = true
		pro.lab.untilTime = g:now() + 99

		local pet = assert(g.inventory:create(a.UserId, "Pet", "Epic", "Lizard", "Water"))
		pet.variant = "Ranger"
		pet.welcomedOwners[tostring(a.UserId)] = true
		pet.welcomedOwners[tostring(b.UserId)] = true
		assert(g:setPetMode(a, pet.id, "Active"))
		assert(g.inventory:setLocked(a.UserId, pet.id, true))
		local egg = assert(g.inventory:create(a.UserId, "Egg", "Rare", "Dragon"))
		assert(g:beginIncubation(a, egg, "Earth"))
		pro.incubations.Earth.remaining = 12.5
		g:reconcilePets()

		local saved, saveErr = Schema.capture(g, a)
		assert(saved, saveErr)
		assert(pure(saved))
		assert(findItem(saved, pet.id).variant == "Ranger")
		assert(findItem(saved, egg.id).state == "Incubating")
		assert(#saved.incubations == 1 and saved.incubations[1].itemId == egg.id)
		local corruptIncubation = copy(saved)
		corruptIncubation.incubations[1].itemId = pet.id
		assert(Schema.validate(corruptIncubation, a.UserId) == nil)

		local extra = assert(g.inventory:create(a.UserId, "Egg", "Common", "Skunk"))
		pro.speed.Value = 0
		pro.money.Value = 0
		pro.coinRemainder = 0
		pro.tier = 1
		pro.ranchLevel = 0
		pro.activePetId = nil
		pet.petMode = "Pen"
		pet.variant = "Standard"
		pro.baseTheme = "Standard"
		pro.duelWeapon = "Blaster"
		g.speedLab:setup(pro)

		local ok, applyErr = Schema.apply(g, a, saved)
		assert(ok, applyErr)
		assert(g.inventory.items[extra.id] == nil)
		assert(pro.tier == saved.progression.tier)
		assert(pro.speed.Value == saved.progression.speed)
		assert(pro.money.Value == saved.progression.money)
		assert(pro.coinRemainder == saved.progression.coinRemainder)
		assert(pro.ranchLevel == saved.progression.ranchLevel)
		assert(pro.baseTheme == saved.progression.baseTheme)
		assert(pro.duelWeapon == saved.progression.duelWeapon)
		assert(pro.activePetId == pet.id)
		local restoredPet = assert(g.inventory.items[pet.id])
		assert(restoredPet.petMode == "Active" and restoredPet.variant == "Ranger")
		assert(restoredPet.locked and restoredPet.favorite)
		assert(restoredPet.welcomedOwners[tostring(a.UserId)] and restoredPet.welcomedOwners[tostring(b.UserId)])
		local restoredEgg = assert(g.inventory.items[egg.id])
		assert(restoredEgg.state == "Incubating" and restoredEgg.element == "Earth")
		local incubation = assert(pro.incubations.Earth)
		assert(incubation.itemId == egg.id and incubation.remaining == 12.5)
		assert(incubation.model and incubation.model.Parent == g.world.dynamic)
		assert(pro.lab.tuning == saved.lab.tuning and pro.lab.milestone == saved.lab.milestone)
		assert(pro.lab.records.trainingSeconds == 123.5 and pro.lab.records.bestSprint == 18.75)
		assert(pro.lab.momentum == 0 and pro.lab.charge == 0 and pro.lab.energy == 0)
		assert(pro.lab.precision == false and pro.lab.untilTime == 0)
	end)

	check("Persistence baseline restore removes fixture state and preserves exact original durable record", function()
		local ok, err = Schema.apply(g, a, baseline)
		assert(ok, err)
		local restored, captureErr = Schema.capture(g, a)
		assert(restored, captureErr)
		assert(restored.userId == baseline.userId)
		assert(restored.progression.speed == baseline.progression.speed)
		assert(restored.progression.money == baseline.progression.money)
		assert(restored.progression.tier == baseline.progression.tier)
		assert(restored.progression.ranchLevel == baseline.progression.ranchLevel)
		assert(restored.progression.activePetId == baseline.progression.activePetId)
		assert(restored.progression.baseTheme == baseline.progression.baseTheme)
		assert(restored.progression.duelWeapon == baseline.progression.duelWeapon)
		assert(#restored.items == #baseline.items and #restored.incubations == #baseline.incubations)
		for index, item in ipairs(baseline.items) do
			local actual = restored.items[index]
			assert(actual.id == item.id and actual.kind == item.kind and actual.state == item.state)
			assert(actual.revision == item.revision and actual.order == item.order)
		end
	end)

	results.persistenceSchemaDiagnostics = {
		version = Schema.VERSION,
		dataStoreWrites = false,
		roundTrip = true,
		corruptionRejected = true,
	}
end

return Checks
