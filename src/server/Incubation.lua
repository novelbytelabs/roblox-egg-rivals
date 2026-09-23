-- Deliberate element selection. A preview is not a deposit; the server times every confirmation.
local HttpService = game:GetService("HttpService")
local Shared = game:GetService("ReplicatedStorage").Stage3Shared
local C = require(Shared.Config)
local R = require(Shared.Rules)
local Incubation = {}
Incubation.__index = Incubation
function Incubation.new(gameService)
	return setmetatable({ game = gameService }, Incubation)
end
function Incubation:source(p, element, itemId)
	local g = self.game
	local pro = g.profiles[p]
	if not g:alive(p) or g:busy(p, true) or type(element) ~= "string" or not C.Elements[element] then
		return nil, "Choose an element after finishing your other activity."
	end
	local slot = pro.base.incubators[element]
	local root = g:root(p)
	if
		not slot
		or not root
		or not R.within(
			root.Position,
			slot.pad.Position,
			C.IncubatorHalfExtent,
			C.IncubatorHalfExtent,
			C.IncubatorHeight
		)
	then
		return nil, "Stand at your own " .. element .. " incubator."
	end
	if pro.incubations[element] then
		return nil, element .. " incubator is occupied."
	end
	local egg = g.carry[p]
	if egg and (itemId == nil or itemId == egg.id) then
		if egg.state ~= "Carried" or egg.carrier ~= p or g.eggs[egg.id] ~= egg then
			return nil, "Carried egg changed."
		end
		return { kind = "World", item = egg, id = egg.id, revision = egg.revision }
	end
	local item = R.id(itemId) and g.inventory.items[itemId] or nil
	if not R.eligible(item, p.UserId) or item.kind ~= "Egg" then
		return nil, "Select an unlocked egg you own."
	end
	return { kind = "Inventory", item = item, id = item.id, revision = item.revision }
end
function Incubation:preview(p, element, itemId)
	local source, err = self:source(p, element, itemId)
	if not source then
		return false, err
	end
	local g = self.game
	local item = source.item
	local preview = {
		id = HttpService:GenerateGUID(false),
		itemId = source.id,
		sourceKind = source.kind,
		revision = source.revision,
		element = element,
		expires = g:now() + C.PreviewLifetime,
		creature = item.creature,
		rarity = item.rarity,
		hatch = C.Rarities[item.rarity].hatch,
	}
	g.profiles[p].incubatorPreview = preview
	g.holds:cancel(p)
	g:feed(p, "incubatorPreview", preview)
	return true, preview
end
function Incubation:current(p, id)
	local pro = self.game.profiles[p]
	local v = pro and pro.incubatorPreview
	if not v or v.id ~= id or self.game:now() > v.expires then
		return nil
	end
	local source = self:source(p, v.element, v.itemId)
	if
		not source
		or source.kind ~= v.sourceKind
		or source.revision ~= v.revision
		or source.item.creature ~= v.creature
		or source.item.rarity ~= v.rarity
	then
		return nil
	end
	return v
end
function Incubation:fingerprint(v)
	return v.id .. "|" .. v.itemId .. "|" .. v.element .. "|" .. v.revision
end
function Incubation:hold(p, id, nonce)
	local v = self:current(p, id)
	if not v then
		self:cancel(p)
		return false, "Egg, element, or position changed. Review again."
	end
	local h, err = self.game.holds:begin(p, "incubate", self:fingerprint(v), C.IncubatorHold, nonce)
	if not h then
		return false, err
	end
	self.game:feed(
		p,
		"incubatorHold",
		{ token = h.token, nonce = h.nonce, started = h.started, duration = h.duration, previewId = v.id }
	)
	return true, h
end
function Incubation:confirm(p, id, token)
	local v = self:current(p, id)
	if not v then
		self:cancel(p)
		return false, "Incubation preview expired or changed."
	end
	local ok, err = self.game.holds:consume(p, "incubate", self:fingerprint(v), token)
	if not ok then
		return false, err
	end
	self.game.profiles[p].incubatorPreview = nil
	if v.sourceKind == "World" then
		ok, err = self.game:secure(p, v.element)
	else
		ok, err = self.game:incubate(p, v.itemId, v.element)
	end
	self.game:feed(p, "incubatorClosed", {})
	return ok, err
end
function Incubation:cancel(p)
	local pro = self.game.profiles[p]
	if pro and pro.incubatorPreview then
		pro.incubatorPreview = nil
		local h = self.game.holds.active[p]
		if h and h.kind == "incubate" then
			self.game.holds:cancel(p)
		end
		self.game:feed(p, "incubatorClosed", {})
	end
end
function Incubation:step()
	for p, pro in pairs(self.game.profiles) do
		if pro.incubatorPreview and not self:current(p, pro.incubatorPreview.id) then
			self:cancel(p)
		end
	end
end
return Incubation
