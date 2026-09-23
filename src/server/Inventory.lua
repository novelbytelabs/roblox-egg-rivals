local HttpService = game:GetService("HttpService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Stage3Shared")
local Config = require(Shared.Config)
local Rules = require(Shared.Rules)
local Inventory = {}
Inventory.__index = Inventory

function Inventory.new()
	return setmetatable({ items = {}, sequence = 0 }, Inventory)
end

function Inventory:list(owner)
	local list = {}
	for _, item in pairs(self.items) do
		if item.ownerId == owner then
			table.insert(list, item)
		end
	end
	table.sort(list, function(a, b)
		return a.order < b.order
	end)
	return list
end

local function displayName(item)
	if item.kind == "Pet" and item.element then
		return item.element .. " " .. item.creature
	end
	return item.creature
end

function Inventory:create(owner, kind, rarity, creature, element)
	assert(kind == "Egg" or kind == "Pet", "Invalid item kind")
	assert(Config.Rarities[rarity], "Invalid rarity")
	creature = creature or Config.Rarities[rarity].creature
	assert(table.find(Config.Creatures, creature), "Invalid creature")
	if element ~= nil then
		assert(Config.Elements[element], "Invalid element")
	end
	if #self:list(owner) >= Config.MaxItems then
		return nil, "Inventory is full."
	end
	self.sequence += 1
	local item = {
		id = HttpService:GenerateGUID(false),
		kind = kind,
		rarity = rarity,
		creature = creature,
		element = kind == "Pet" and (element or "Earth") or element,
		ownerId = owner,
		state = "Inventory",
		petMode = kind == "Pet" and "Pen" or nil,
		order = self.sequence,
		createdAt = os.time(),
	}
	item.species = displayName(item)
	self.items[item.id] = item
	return item
end

function Inventory:refreshName(item)
	item.species = displayName(item)
end

function Inventory:escrow(ownerA, idA, ownerB, idB, duelId)
	local a, b = self.items[idA], self.items[idB]
	if idA == idB or ownerA == ownerB or not Rules.eligible(a, ownerA) or not Rules.eligible(b, ownerB) then
		return false, "An offered item is no longer available."
	end
	a.state = "Escrow"
	b.state = "Escrow"
	a.duelId = duelId
	b.duelId = duelId
	return true
end

function Inventory:settle(duelId, ids, winnerId)
	local selected = {}
	for _, id in ipairs(ids) do
		local item = self.items[id]
		if not item or item.state ~= "Escrow" or item.duelId ~= duelId then
			return false, "Escrow invariant failed."
		end
		table.insert(selected, item)
	end
	for _, item in ipairs(selected) do
		if winnerId ~= nil then
			item.ownerId = winnerId
			if item.kind == "Pet" then
				item.petMode = "Pen"
			end
		end
		item.state = "Inventory"
		item.duelId = nil
	end
	return true
end

function Inventory:removeOwner(owner)
	for id, item in pairs(self.items) do
		if item.ownerId == owner and item.state ~= "Escrow" then
			self.items[id] = nil
		end
	end
end

function Inventory:income(owner)
	local income = 0
	for _, item in ipairs(self:list(owner)) do
		if item.kind == "Pet" and item.state == "Inventory" then
			income += Config.Rarities[item.rarity].income
		end
	end
	return income
end

function Inventory:snapshot(owner)
	local data = {}
	for _, item in ipairs(self:list(owner)) do
		table.insert(data, {
			id = item.id,
			kind = item.kind,
			rarity = item.rarity,
			creature = item.creature,
			element = item.element,
			species = item.species,
			petMode = item.petMode,
			state = item.state,
			income = item.kind == "Pet" and Config.Rarities[item.rarity].income or 0,
		})
	end
	return data
end

return Inventory
