-- All item commits are prevalidated and non-yielding. Instance IDs never change.
local HttpService = game:GetService("HttpService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Stage3Shared")
local C = require(Shared.Config)
local R = require(Shared.Rules)
local Inventory = {}
Inventory.__index = Inventory
function Inventory.new()
	return setmetatable({ items = {}, sequence = 0, audit = {} }, Inventory)
end
function Inventory:list(owner)
	local out = {}
	for _, item in pairs(self.items) do
		if item.ownerId == owner then
			table.insert(out, item)
		end
	end
	table.sort(out, function(a, b)
		return a.order < b.order
	end)
	return out
end
function Inventory:record(action, ids)
	table.insert(self.audit, { action = action, ids = table.clone(ids), time = os.time() })
	if #self.audit > 100 then
		table.remove(self.audit, 1)
	end
end
function Inventory:refreshName(item)
	if item.kind == "Item" then
		item.species = C.ItemTypes[item.itemType].name
	elseif item.kind == "Pet" then
		item.species = item.element .. " " .. item.creature
	else
		item.species = item.creature
	end
	item.revision = (item.revision or 0) + 1
end
function Inventory:create(owner, kind, rarity, creature, element)
	if
		not R.integer(owner, -100000000000, 100000000000)
		or (kind ~= "Egg" and kind ~= "Pet")
		or not C.Rarities[rarity]
	then
		return nil, "Invalid item definition."
	end
	creature = creature or C.Creatures[1] -- Never infer creature from rarity.
	if not table.find(C.Creatures, creature) or (element ~= nil and not C.Elements[element]) then
		return nil, "Invalid creature or element."
	end
	if #self:list(owner) >= C.MaxItems then
		return nil, "Collection is full."
	end
	self.sequence += 1
	local item = {
		id = HttpService:GenerateGUID(false),
		kind = kind,
		rarity = rarity,
		creature = creature,
		element = kind == "Pet" and (element or "Earth") or nil,
		ownerId = owner,
		state = "Inventory",
		petMode = kind == "Pet" and "Pen" or nil,
		order = self.sequence,
		createdAt = os.time(),
		locked = false,
		favorite = false,
		variant = "Standard",
		welcomedOwners = {},
		revision = 0,
	}
	self:refreshName(item)
	self.items[item.id] = item
	return item
end
function Inventory:createConsumable(owner, itemType)
	local spec = C.ItemTypes[itemType]
	if not R.integer(owner, -100000000000, 100000000000) or not spec or #self:list(owner) >= C.MaxItems then
		return nil, "Item unavailable or collection full."
	end
	self.sequence += 1
	local item = {
		id = HttpService:GenerateGUID(false),
		kind = "Item",
		itemType = itemType,
		rarity = spec.rarity,
		ownerId = owner,
		state = "Inventory",
		order = self.sequence,
		createdAt = os.time(),
		locked = false,
		favorite = false,
		revision = 0,
	}
	self:refreshName(item)
	self.items[item.id] = item
	return item
end
function Inventory:consume(owner, id, itemType)
	local item = self.items[id]
	if not R.eligible(item, owner) or item.kind ~= "Item" or item.itemType ~= itemType then
		return false, "Consumable unavailable."
	end
	self.items[id] = nil
	self:record("consumed", { id })
	return true
end
function Inventory:consumables(owner, availableOnly)
	local out = {}
	for _, item in ipairs(self:list(owner)) do
		if item.kind == "Item" and item.itemType == "SnarePod" and (not availableOnly or R.eligible(item, owner)) then
			table.insert(out, item)
		end
	end
	return out
end
function Inventory:setLocked(owner, id, locked)
	local item = self.items[id]
	if not item or item.ownerId ~= owner or item.state ~= "Inventory" or type(locked) ~= "boolean" then
		return false, "Only an unreserved item you own can be locked."
	end
	item.locked = locked
	item.favorite = locked
	item.revision += 1
	return true
end
function Inventory:validateIds(ids, maximum)
	if type(ids) ~= "table" then
		return false
	end
	local count = 0
	for index, id in pairs(ids) do
		count += 1
		if count > maximum or not R.integer(index, 1, maximum) or not R.id(id) then
			return false
		end
	end
	if count > maximum then
		return false
	end
	local seen = {}
	for i = 1, count do
		local id = ids[i]
		if not id or seen[id] then
			return false
		end
		seen[id] = true
	end
	return true
end
-- Replace one side's offer atomically; failed changes preserve the old reservation.
function Inventory:reserveOffer(owner, ids, key, state)
	if not R.id(key) or (state ~= "Trade" and state ~= "Exchange") or not self:validateIds(ids, C.MaxTradeItems) then
		return false, "Invalid item list."
	end
	for _, id in ipairs(ids) do
		local item = self.items[id]
		local ownReservation = item and item.ownerId == owner and item.reservation == key and item.state == state
		if
			not item
			or (not ownReservation and not R.transferable(item, owner))
			or item.locked
			or item.favorite
			or item.petMode == "Active"
		then
			return false, "Choose unreserved, unlocked items; send active pets to the pen first."
		end
	end
	for _, item in pairs(self.items) do
		if item.ownerId == owner and item.reservation == key then
			item.reservation = nil
			item.state = "Inventory"
			item.revision += 1
		end
	end
	for _, id in ipairs(ids) do
		local item = self.items[id]
		item.reservation = key
		item.state = state
		item.revision += 1
	end
	self:record("reserve:" .. state, ids)
	return true
end
function Inventory:release(key)
	if not R.id(key) then
		return false
	end
	local ids = {}
	for id, item in pairs(self.items) do
		if item.reservation == key then
			item.reservation = nil
			item.state = "Inventory"
			item.revision += 1
			table.insert(ids, id)
		end
	end
	self:record("release", ids)
end
function Inventory:transfer(key, ownerA, idsA, ownerB, idsB)
	if
		ownerA == ownerB
		or not self:validateIds(idsA, C.MaxTradeItems)
		or not self:validateIds(idsB, C.MaxTradeItems)
		or #idsA + #idsB == 0
	then
		return false, "Invalid trade."
	end
	local changes, seen = {}, {}
	for _, side in ipairs({ { ownerA, ownerB, idsA }, { ownerB, ownerA, idsB } }) do
		for _, id in ipairs(side[3]) do
			local item = self.items[id]
			if
				seen[id]
				or not item
				or item.ownerId ~= side[1]
				or item.reservation ~= key
				or item.state ~= "Trade"
				or item.locked
				or item.favorite
				or item.petMode == "Active"
			then
				return false, "Offer ownership changed."
			end
			seen[id] = true
			table.insert(changes, { item = item, from = side[1], to = side[2] })
		end
	end
	if #self:list(ownerA) - #idsA + #idsB > C.MaxItems or #self:list(ownerB) - #idsB + #idsA > C.MaxItems then
		return false, "A receiving collection is full."
	end
	-- No events, waits, callbacks or asset loads inside this commit.
	for _, change in ipairs(changes) do
		local item = change.item
		item.ownerId = change.to
		item.state = "Inventory"
		item.reservation = nil
		item.revision += 1
		if item.kind == "Pet" then
			item.petMode = "Pen"
		end
	end
	local ids = {}
	for _, change in ipairs(changes) do
		table.insert(ids, change.item.id)
	end
	self:record("tradeCommitted", ids)
	return true, changes
end

function Inventory:escrow(ownerA, idA, ownerB, idB, duelId)
	local a, b = self.items[idA], self.items[idB]
	if idA == idB or ownerA == ownerB or not R.eligible(a, ownerA) or not R.eligible(b, ownerB) then
		return false, "A stake is unavailable or locked."
	end
	if #self:list(ownerA) >= C.MaxItems or #self:list(ownerB) >= C.MaxItems then
		return false, "Each player needs one free collection slot for a possible win."
	end
	a.state, b.state = "Escrow", "Escrow"
	a.duelId, b.duelId = duelId, duelId
	a.revision += 1
	b.revision += 1
	self:record("duelEscrow", { idA, idB })
	return true
end
function Inventory:settle(duelId, ids, winnerId)
	if not self:validateIds(ids, 2) or #ids ~= 2 then
		return false, "Invalid escrow item list."
	end
	local selected, changes = {}, {}
	for _, id in ipairs(ids) do
		local item = self.items[id]
		if not item or item.state ~= "Escrow" or item.duelId ~= duelId then
			return false, "Escrow invariant failed."
		end
		table.insert(selected, item)
	end
	if winnerId ~= nil then
		if winnerId ~= selected[1].ownerId and winnerId ~= selected[2].ownerId then
			return false, "Winner is not a duel participant."
		end
		local incoming = 0
		for _, item in ipairs(selected) do
			if item.ownerId ~= winnerId then
				incoming += 1
			end
		end
		if #self:list(winnerId) + incoming > C.MaxItems then
			return false, "Winner collection is full."
		end
	end
	for _, item in ipairs(selected) do
		local before = item.ownerId
		if winnerId ~= nil then
			item.ownerId = winnerId
		end
		item.state = "Inventory"
		item.duelId = nil
		item.revision += 1
		if item.kind == "Pet" then
			item.petMode = "Pen"
		end
		if before ~= item.ownerId then
			table.insert(changes, { item = item, from = before, to = item.ownerId })
		end
	end
	self:record("duelSettled", ids)
	return true, changes
end
function Inventory:exchange(owner, id, key, balance)
	local item = self.items[id]
	if
		not item
		or item.ownerId ~= owner
		or item.state ~= "Exchange"
		or item.reservation ~= key
		or item.locked
		or item.favorite
		or item.petMode == "Active"
	then
		return false, "Exchange item is no longer available."
	end
	local value = R.exchangeValue(item)
	if value <= 0 or balance.Value + value > C.MaxCoins then
		return false, "Exchange cannot credit this item."
	end
	-- Both mutations are synchronous and prevalidated; no client-supplied price is accepted.
	self.items[id] = nil
	balance.Value += value
	self:record("exchanged", { id })
	return true, value
end
function Inventory:income(owner)
	local value = 0
	for _, item in pairs(self.items) do
		if item.ownerId == owner and item.kind == "Pet" then
			value += C.Rarities[item.rarity].income
		end
	end
	return value -- Coins per minute; income follows ownership, including reservations.
end
function Inventory:snapshotItem(item)
	return {
		id = item.id,
		kind = item.kind,
		itemType = item.itemType,
		rarity = item.rarity,
		creature = item.creature,
		element = item.element,
		species = item.species,
		petMode = item.petMode,
		state = item.state,
		locked = item.locked,
		favorite = item.favorite,
		variant = item.variant,
		revision = item.revision,
		income = item.kind == "Pet" and C.Rarities[item.rarity].income or 0,
		exchange = R.exchangeValue(item),
	}
end
function Inventory:snapshot(owner)
	local out = {}
	for _, item in ipairs(self:list(owner)) do
		table.insert(out, self:snapshotItem(item))
	end
	return out
end
function Inventory:removeOwner(owner)
	local ids = {}
	for id, item in pairs(self.items) do
		if item.ownerId == owner then
			assert(item.state ~= "Escrow" and not item.reservation, "Unresolved reservation at session exit")
			table.insert(ids, id)
		end
	end
	for _, id in ipairs(ids) do
		self.items[id] = nil
	end
	self:record("sessionEnded", ids)
end
return Inventory
