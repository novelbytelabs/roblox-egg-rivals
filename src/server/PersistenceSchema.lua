local Shared = game:GetService("ReplicatedStorage").Stage3Shared
local C = require(Shared.Config)
local R = require(Shared.Rules)
local Art = require(Shared.Art)

local Schema = {}
Schema.VERSION = 1

local LAB_RECORD_KEYS = {
	"trainingSeconds",
	"distance",
	"bestMomentum",
	"overdrivesUsed",
	"overdrivesEarned",
	"sprintEntered",
	"sprintWins",
	"sprintDNFs",
	"bestSprint",
	"sprintStreak",
	"bestSprintStreak",
	"tuningChanges",
	"draftingSeconds",
	"precisionToggles",
	"overdriveCuts",
}

local function fail(message)
	return nil, message
end

local function boolean(value)
	return type(value) == "boolean"
end

local function enum(tableValue, value)
	return type(value) == "string" and tableValue[value] ~= nil
end

local function denseLength(value, maximum)
	if type(value) ~= "table" then
		return nil
	end
	local count = 0
	for key in pairs(value) do
		if not R.integer(key, 1, maximum) then
			return nil
		end
		count += 1
	end
	for index = 1, count do
		if value[index] == nil then
			return nil
		end
	end
	return count
end

local function welcomedList(item)
	local out = {}
	for key, value in pairs(item.welcomedOwners or {}) do
		if value == true then
			local userId = tonumber(key)
			if R.integer(userId, 1, 100000000000) then
				table.insert(out, userId)
			end
		end
	end
	table.sort(out)
	return out
end

local function welcomedMap(list)
	local out = {}
	for _, userId in ipairs(list) do
		out[tostring(userId)] = true
	end
	return out
end

local function captureItem(item)
	if
		item.reservation ~= nil
		or item.duelId ~= nil
		or (item.state ~= "Inventory" and item.state ~= "Incubating")
	then
		return fail("Cannot persist unresolved item transaction state.")
	end
	local data = {
		id = item.id,
		kind = item.kind,
		state = item.state,
		rarity = item.rarity,
		order = item.order,
		createdAt = item.createdAt,
		revision = item.revision,
		locked = item.locked == true,
		favorite = item.favorite == true,
	}
	if item.kind == "Item" then
		data.itemType = item.itemType
	elseif item.kind == "Egg" then
		data.creature = item.creature
		data.element = item.state == "Incubating" and item.element or nil
	elseif item.kind == "Pet" then
		data.creature = item.creature
		data.element = item.element
		data.petMode = item.petMode
		data.variant = item.variant or "Standard"
		data.welcomedOwners = welcomedList(item)
	else
		return fail("Unknown item kind.")
	end
	return data
end

local function captureLab(pro)
	local records = {}
	for _, key in ipairs(LAB_RECORD_KEYS) do
		records[key] = pro.lab.records[key]
	end
	return {
		tuning = pro.lab.tuning,
		milestone = pro.lab.milestone,
		records = records,
	}
end

function Schema.capture(gameService, player)
	local pro = gameService.profiles[player]
	if not pro or player.UserId == nil then
		return fail("Profile unavailable.")
	end
	if pro.duel or pro.trade or pro.exchange then
		return fail("Cannot persist unresolved ownership transaction.")
	end
	local items = {}
	for _, item in ipairs(gameService.inventory:list(player.UserId)) do
		local saved, err = captureItem(item)
		if not saved then
			return nil, err
		end
		table.insert(items, saved)
	end
	local incubations = {}
	for _, element in ipairs(C.ElementOrder) do
		local inc = pro.incubations[element]
		if inc then
			table.insert(incubations, {
				element = element,
				itemId = inc.itemId,
				remaining = inc.remaining,
			})
		end
	end
	local data = {
		version = Schema.VERSION,
		userId = player.UserId,
		sourceBuild = C.Build,
		savedAt = os.time(),
		progression = {
			speed = pro.speed.Value,
			money = pro.money.Value,
			coinRemainder = pro.coinRemainder,
			tier = pro.tier,
			tutorial = pro.tutorial,
			onboardingComplete = pro.onboardingComplete == true,
			hatched = pro.hatched,
			ranchLevel = pro.ranchLevel,
			activePetId = pro.activePetId,
			duelWeapon = pro.duelWeapon or "Blaster",
			baseTheme = pro.baseTheme or "Standard",
		},
		lab = captureLab(pro),
		items = items,
		incubations = incubations,
	}
	return Schema.validate(data, player.UserId)
end

local function validateWelcomed(value)
	local count = denseLength(value, 128)
	if count == nil then
		return nil
	end
	local out, seen = {}, {}
	for index, userId in ipairs(value) do
		if not R.integer(index, 1, 128) or not R.integer(userId, 1, 100000000000) or seen[userId] then
			return nil
		end
		seen[userId] = true
		table.insert(out, userId)
	end
	table.sort(out)
	return out
end

local function validateItem(source)
	if
		type(source) ~= "table"
		or not R.id(source.id)
		or not R.integer(source.order, 1, 1000000000)
		or not R.integer(source.createdAt, 0, 1000000000000)
		or not R.integer(source.revision, 0, 1000000000)
		or not boolean(source.locked)
		or not boolean(source.favorite)
		or (source.state ~= "Inventory" and source.state ~= "Incubating")
	then
		return fail("Invalid persistent item envelope.")
	end
	local item = {
		id = source.id,
		kind = source.kind,
		state = source.state,
		rarity = source.rarity,
		order = source.order,
		createdAt = source.createdAt,
		revision = source.revision,
		locked = source.locked,
		favorite = source.favorite,
	}
	if source.kind == "Item" then
		if source.state ~= "Inventory" or not C.ItemTypes[source.itemType] then
			return fail("Invalid persistent consumable.")
		end
		item.itemType = source.itemType
		item.rarity = C.ItemTypes[source.itemType].rarity
	elseif source.kind == "Egg" then
		if not C.Rarities[source.rarity] or not table.find(C.Creatures, source.creature) then
			return fail("Invalid persistent egg.")
		end
		if source.state == "Inventory" and source.element ~= nil then
			return fail("Inventory egg cannot have an element.")
		end
		if source.state == "Incubating" and not C.Elements[source.element] then
			return fail("Incubating egg requires an element.")
		end
		item.creature = source.creature
		item.element = source.element
	elseif source.kind == "Pet" then
		local welcomed = validateWelcomed(source.welcomedOwners or {})
		if
			source.state ~= "Inventory"
			or not C.Rarities[source.rarity]
			or not table.find(C.Creatures, source.creature)
			or not C.Elements[source.element]
			or (source.petMode ~= "Active" and source.petMode ~= "Pen")
			or not C.PetVariants[source.variant or "Standard"]
			or not welcomed
		then
			return fail("Invalid persistent pet.")
		end
		item.creature = source.creature
		item.element = source.element
		item.petMode = source.petMode
		item.variant = source.variant or "Standard"
		item.welcomedOwners = welcomed
	else
		return fail("Invalid persistent item kind.")
	end
	return item
end

local function validateLab(source)
	if
		type(source) ~= "table"
		or not C.Tunings[source.tuning]
		or not R.integer(source.milestone, 0, #C.SpeedMilestones)
		or type(source.records) ~= "table"
	then
		return fail("Invalid persistent Speed Lab.")
	end
	local records = {}
	for _, key in ipairs(LAB_RECORD_KEYS) do
		local value = source.records[key]
		if key == "bestSprint" and value == nil then
			records[key] = nil
		elseif not R.finite(value) or value < 0 then
			return fail("Invalid Speed Lab record " .. key .. ".")
		else
			records[key] = value
		end
	end
	if records.bestMomentum > 1.000001 then
		return fail("Invalid best momentum.")
	end
	return {
		tuning = source.tuning,
		milestone = source.milestone,
		records = records,
	}
end

function Schema.validate(source, expectedUserId)
	if
		type(source) ~= "table"
		or source.version ~= Schema.VERSION
		or not R.integer(source.userId, 1, 100000000000)
		or source.userId ~= expectedUserId
		or type(source.sourceBuild) ~= "string"
		or #source.sourceBuild > 128
		or not R.integer(source.savedAt, 0, 1000000000000)
	then
		return fail("Invalid persistence record header.")
	end
	local p = source.progression
	if
		type(p) ~= "table"
		or not R.integer(p.tier, 1, #C.Grades)
		or not R.integer(p.speed, 0, C.Grades[p.tier].cap)
		or not R.integer(p.money, 0, C.MaxCoins)
		or not R.finite(p.coinRemainder)
		or p.coinRemainder < 0
		or p.coinRemainder >= 1
		or not R.integer(p.tutorial, 1, 20)
		or not boolean(p.onboardingComplete)
		or not R.integer(p.hatched, 0, 1000000000)
		or not R.integer(p.ranchLevel, 0, #C.Expansions - 1)
		or not C.DuelWeapons[p.duelWeapon]
		or not C.BazaarThemes[p.baseTheme]
		or (p.activePetId ~= nil and not R.id(p.activePetId))
	then
		return fail("Invalid persistent progression.")
	end
	local lab, labErr = validateLab(source.lab)
	if not lab then
		return nil, labErr
	end
	local itemCount = denseLength(source.items, C.MaxItems)
	if itemCount == nil then
		return fail("Invalid persistent inventory.")
	end
	local items, byId = {}, {}
	for index, raw in ipairs(source.items) do
		if not R.integer(index, 1, C.MaxItems) then
			return fail("Invalid inventory index.")
		end
		local item, itemErr = validateItem(raw)
		if not item then
			return nil, itemErr
		end
		if byId[item.id] then
			return fail("Duplicate persistent item id.")
		end
		byId[item.id] = item
		table.insert(items, item)
	end
	local incubations, incubationByItem, incubationByElement = {}, {}, {}
	local incubationCount = denseLength(source.incubations, #C.ElementOrder)
	if incubationCount == nil then
		return fail("Invalid persistent incubations.")
	end
	for index, raw in ipairs(source.incubations) do
		if
			not R.integer(index, 1, #C.ElementOrder)
			or type(raw) ~= "table"
			or not C.Elements[raw.element]
			or not R.id(raw.itemId)
			or not R.finite(raw.remaining)
			or raw.remaining < 0
			or incubationByItem[raw.itemId]
			or incubationByElement[raw.element]
		then
			return fail("Invalid persistent incubation.")
		end
		local item = byId[raw.itemId]
		if
			not item
			or item.kind ~= "Egg"
			or item.state ~= "Incubating"
			or item.element ~= raw.element
			or raw.remaining > C.Rarities[item.rarity].hatch
		then
			return fail("Incubation does not match its egg.")
		end
		incubationByItem[raw.itemId] = true
		incubationByElement[raw.element] = true
		table.insert(incubations, {
			element = raw.element,
			itemId = raw.itemId,
			remaining = raw.remaining,
		})
	end
	for _, item in ipairs(items) do
		if item.kind == "Egg" and item.state == "Incubating" and not incubationByItem[item.id] then
			return fail("Incubating egg is missing its incubation record.")
		end
	end
	if p.activePetId then
		local active = byId[p.activePetId]
		if not active or active.kind ~= "Pet" or active.petMode ~= "Active" then
			return fail("Active pet id does not match an active pet.")
		end
	end
	for _, item in ipairs(items) do
		if item.kind == "Pet" and item.petMode == "Active" and item.id ~= p.activePetId then
			return fail("Multiple active pets in persistence record.")
		end
	end
	return {
		version = Schema.VERSION,
		userId = source.userId,
		sourceBuild = source.sourceBuild,
		savedAt = source.savedAt,
		progression = {
			speed = p.speed,
			money = p.money,
			coinRemainder = p.coinRemainder,
			tier = p.tier,
			tutorial = p.tutorial,
			onboardingComplete = p.onboardingComplete,
			hatched = p.hatched,
			ranchLevel = p.ranchLevel,
			activePetId = p.activePetId,
			duelWeapon = p.duelWeapon,
			baseTheme = p.baseTheme,
		},
		lab = lab,
		items = items,
		incubations = incubations,
	}
end

local function internalItems(record, owner)
	local out = {}
	for _, saved in ipairs(record.items) do
		local item = {
			id = saved.id,
			kind = saved.kind,
			state = saved.state,
			rarity = saved.rarity,
			order = saved.order,
			createdAt = saved.createdAt,
			revision = saved.revision,
			locked = saved.locked,
			favorite = saved.favorite,
			ownerId = owner,
		}
		if saved.kind == "Item" then
			item.itemType = saved.itemType
		elseif saved.kind == "Egg" then
			item.creature = saved.creature
			item.element = saved.element
			item.welcomedOwners = {}
		else
			item.creature = saved.creature
			item.element = saved.element
			item.petMode = saved.petMode
			item.variant = saved.variant
			item.welcomedOwners = welcomedMap(saved.welcomedOwners)
		end
		table.insert(out, item)
	end
	return out
end

function Schema.apply(gameService, player, source)
	local pro = gameService.profiles[player]
	if not pro or gameService:busy(player) or gameService.carry[player] then
		return false, "Persistence restore requires a free live profile."
	end
	local record, err = Schema.validate(source, player.UserId)
	if not record then
		return false, err
	end
	for _, saved in ipairs(record.items) do
		local collision = gameService.inventory.items[saved.id]
		if collision and collision.ownerId ~= player.UserId then
			return false, "Persistence item id collides with another owner."
		end
	end
	for _, inc in pairs(pro.incubations) do
		if inc.model and inc.model.Parent then
			inc.model:Destroy()
		end
	end
	pro.incubations = {}
	local ok, inventoryErr = gameService.inventory:replaceOwner(player.UserId, internalItems(record, player.UserId))
	if not ok then
		return false, inventoryErr
	end
	local p = record.progression
	pro.tier = p.tier
	pro.speed.Value = p.speed
	pro.money.Value = p.money
	pro.coinRemainder = p.coinRemainder
	pro.tutorial = p.tutorial
	pro.onboardingComplete = p.onboardingComplete
	pro.hatched = p.hatched
	pro.ranchLevel = p.ranchLevel
	pro.penPage = 1
	pro.activePetId = p.activePetId
	pro.duelWeapon = p.duelWeapon
	pro.baseTheme = p.baseTheme
	pro.slowUntil = 0
	pro.training = false
	pro.drafting = false
	pro.bestTrial = nil
	gameService.speedLab:setup(pro)
	pro.lab.tuning = record.lab.tuning
	pro.lab.milestone = record.lab.milestone
	for key, value in pairs(record.lab.records) do
		pro.lab.records[key] = value
	end
	pro.base.treadmill:SetAttribute("Tuning", pro.lab.tuning)
	pro.base.applyGrade(pro.tier)
	pro.base.applyExpansion(pro.ranchLevel)
	pro.base.applyTheme(pro.baseTheme)
	gameService.ranch:setup(player)
	for _, saved in ipairs(record.incubations) do
		local item = assert(gameService.inventory.items[saved.itemId])
		local slot = assert(pro.base.incubators[saved.element])
		local model = Art.egg(item.rarity, gameService.world.dynamic, item.creature)
		model:PivotTo(CFrame.new(slot.pad.Position + Vector3.new(0, 2.5, 0)))
		pro.incubations[saved.element] = {
			itemId = item.id,
			remaining = saved.remaining,
			model = model,
			element = saved.element,
		}
	end
	gameService:reconcilePets()
	gameService:applySpeed(player)
	gameService:push(player)
	return true
end

return Schema
