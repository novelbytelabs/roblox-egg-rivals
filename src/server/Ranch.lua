local Players = game:GetService("Players")
local C = require(game:GetService("ReplicatedStorage").Stage3Shared.Config)
local R = require(game:GetService("ReplicatedStorage").Stage3Shared.Rules)
local Activities = require(script.Parent.RanchActivities)
local Ranch = {}
Ranch.__index = Ranch

function Ranch.new(gameService)
	return setmetatable({ game = gameService, nextTick = 0, activities = Activities.new(gameService) }, Ranch)
end

local function ownerKey(userId)
	return tostring(userId)
end

function Ranch:setup(p)
	local now = self.game:now()
	self.game.profiles[p].ranch = {
		queue = {},
		welcomeUntil = 0,
		nextWelcome = now,
		greetUntil = 0,
		reverenceUntil = 0,
		reverencePet = nil,
		nextReverence = now + self.game.rng:NextInteger(C.ReverenceMin, C.ReverenceMax),
		visitorCooldown = 0,
		wasHome = true,
		leftAt = nil,
		welcomeIds = {},
	}
	self.activities:reset(p)
end

function Ranch:acquired(p, item)
	local pro = self.game.profiles[p]
	if
		not pro
		or not pro.ranch
		or not item
		or item.kind ~= "Pet"
		or item.ownerId ~= p.UserId
		or self.game.inventory.items[item.id] ~= item
	then
		return false
	end
	item.welcomedOwners = item.welcomedOwners or {}
	local key = ownerKey(p.UserId)
	if item.welcomedOwners[key] then
		return false
	end
	item.welcomedOwners[key] = true
	table.insert(pro.ranch.queue, { id = item.id, arrived = self.game:now() })
	return true
end

function Ranch:homecoming(p, reason)
	return self.activities:homecoming(p, reason)
end

function Ranch:leaving(p)
	self.activities:leaving(p)
end

function Ranch:visiblePets(p)
	local pro = self.game.profiles[p]
	local out = {}
	if not pro then
		return out
	end
	for _, item in ipairs(self.game.inventory:list(p.UserId)) do
		if item.kind == "Pet" and item.state == "Inventory" and item.petMode ~= "Active" then
			local record = self.game.petRecords:FindFirstChild(item.id)
			if record and record:GetAttribute("Displayed") == true then
				table.insert(out, { item = item, record = record })
			end
		end
	end
	return out
end

function Ranch:startReverence(owner, visitorTriggered)
	local g = self.game
	local pro = g.profiles[owner]
	local now = g:now()
	if not pro or not pro.ranch then
		return false, "Ranch unavailable."
	end
	local r = pro.ranch
	if r.reverenceUntil > now or r.welcomeUntil > now then
		return false, "The ranch is already celebrating."
	end
	if visitorTriggered and r.visitorCooldown > now then
		return false, "This ranch needs time before another reverence."
	end
	if not visitorTriggered and r.nextReverence > now then
		return false, "The next reverence is not due."
	end
	local visible = self:visiblePets(owner)
	local eligible = {}
	for _, entry in ipairs(visible) do
		if entry.item.rarity == "Godly" then
			for _, other in ipairs(visible) do
				if other.item.rarity ~= "Godly" and other.item.element == entry.item.element then
					table.insert(eligible, entry)
					break
				end
			end
		end
	end
	if #eligible == 0 then
		return false, "A visible Godly and same-element resident are needed."
	end
	local chosen = eligible[g.rng:NextInteger(1, #eligible)]
	r.reverenceUntil = now + C.ReverenceDuration
	r.reverencePet = chosen.item.id
	r.nextReverence = now + g.rng:NextInteger(C.ReverenceMin, C.ReverenceMax)
	if visitorTriggered then
		r.visitorCooldown = now + C.ReverenceCooldown
	end
	g:effect("reverence", {
		ownerUserId = owner.UserId,
		petId = chosen.item.id,
		element = chosen.item.element,
		position = chosen.record:GetAttribute("PenPosition"),
		visitorTriggered = visitorTriggered == true,
	})
	return true
end

function Ranch:requestReverence(visitor, owner)
	local g = self.game
	local pro = g.profiles[owner]
	if not g:alive(visitor) or not pro or visitor == owner then
		return false, "Visit another player's ranch first."
	end
	local root = g:root(visitor)
	if not root or (root.Position - pro.base.penGate.Position).Magnitude > 12 then
		return false, "Move to the ranch gate."
	end
	local now = g:now()
	if pro.ranch.visitorCooldown > now then
		return false, "This ranch needs a moment before another reverence."
	end
	local ok, err = self:startReverence(owner, true)
	if ok then
		pro.ranch.visitorCooldown = now + C.ReverenceCooldown
	end
	return ok, err
end

function Ranch:visitorPet(visitor, petId)
	local g = self.game
	if not g:alive(visitor) or g:busy(visitor) or not R.id(petId) then
		return nil, "Finish your current activity and visit another player's displayed pet."
	end
	local item = g.inventory.items[petId]
	local record = g.petRecords:FindFirstChild(petId)
	if
		not item
		or item.kind ~= "Pet"
		or item.state ~= "Inventory"
		or not record
		or record:GetAttribute("Displayed") ~= true
		or record:GetAttribute("DisplayMode") ~= "Pen"
		or record:GetAttribute("OwnerUserId") ~= item.ownerId
	then
		return nil, "That ranch pet is not available to visitors."
	end
	local owner = Players:GetPlayerByUserId(item.ownerId)
	if not owner or owner == visitor or not g.profiles[owner] then
		return nil, "Visit another player's ranch pet."
	end
	local position = self.activities:position(record, owner) or record:GetAttribute("PenPosition")
	local root = g:root(visitor)
	if not R.vector(position) or not root or (root.Position - position).Magnitude > C.VisitorInspectRange then
		return nil, "Move closer to that ranch pet."
	end
	return { owner = owner, item = item, record = record, position = position }
end

function Ranch:inspect(visitor, petId)
	local target, err = self:visitorPet(visitor, petId)
	if not target then
		return false, err
	end
	local item, owner = target.item, target.owner
	return true,
		{
			id = item.id,
			ownerUserId = owner.UserId,
			ownerName = owner.DisplayName,
			creature = item.creature,
			species = item.species,
			element = item.element,
			rarity = item.rarity,
			income = C.Rarities[item.rarity].income,
		}
end

function Ranch:react(visitor, petId, reaction)
	if reaction ~= "Admire" then
		return false, "Choose an available ranch reaction."
	end
	local target, err = self:visitorPet(visitor, petId)
	if not target then
		return false, err
	end
	local g = self.game
	if not g:rate(visitor, "ranchReaction", C.VisitorReactionCooldown) then
		return false, "Give the ranch a moment before reacting again."
	end
	local item, owner = target.item, target.owner
	g:effect("visitorReaction", {
		visitorUserId = visitor.UserId,
		ownerUserId = owner.UserId,
		petId = item.id,
		rarity = item.rarity,
		position = target.position,
	})
	g:notify(visitor, "You admired " .. owner.DisplayName .. "'s " .. item.species .. ".", "tick")
	g:notify(owner, visitor.DisplayName .. " admired your " .. item.species .. ".", "tick")
	return true
end

function Ranch:buyExpansion(p, level)
	local g = self.game
	local pro = g.profiles[p]
	if not pro or not g:alive(p) or g:busy(p) then
		return false, "You cannot expand the ranch right now."
	end
	if not R.integer(level, 1, #C.Expansions - 1) or level ~= pro.ranchLevel + 1 then
		return false, "That ranch expansion is stale or unavailable."
	end
	if (g:root(p).Position - g.world.ranchShop.Position).Magnitude > C.ShopRange then
		return false, "Visit Ranch & Pen Works."
	end
	local spec = C.Expansions[level + 1]
	if pro.money.Value < spec.cost then
		return false, "Need " .. spec.cost .. " Coins for " .. spec.name .. "."
	end
	pro.money.Value -= spec.cost
	pro.ranchLevel = level
	pro.penPage = 1
	pro.base.applyExpansion(level)
	g:reconcilePets()
	g:notify(p, spec.name .. " built. Your ranch now shows up to " .. spec.capacity .. " pets.", "win")
	g:push(p)
	return true
end
function Ranch:updateRecords(p, now)
	self.activities:updateRecords(self, p, now)
end

function Ranch:step(now)
	if now < self.nextTick then
		return
	end
	self.nextTick = now + C.RanchTick
	for p, pro in pairs(self.game.profiles) do
		local r = pro.ranch
		if r then
			local root = self.game:root(p)
			local home = root and R.within(root.Position, pro.base.center, 21, 55, 30) or false
			if home and not r.wasHome then
				if r.leftAt and now - r.leftAt >= C.HomeAwayTime then
					self:homecoming(p, "return")
				end
				r.leftAt = nil
			elseif not home and r.wasHome then
				r.leftAt = now
			end
			r.wasHome = home
			for i = #r.queue, 1, -1 do
				local item = self.game.inventory.items[r.queue[i].id]
				if not item or item.ownerId ~= p.UserId or item.kind ~= "Pet" then
					table.remove(r.queue, i)
				end
			end
			if
				#r.queue > 0
				and now >= r.nextWelcome
				and r.welcomeUntil <= now
				and r.reverenceUntil <= now
				and now >= r.queue[1].arrived + C.WelcomeBatch
			then
				local cutoff = r.queue[1].arrived + C.WelcomeBatch
				local batch = {}
				while r.queue[1] and r.queue[1].arrived <= cutoff do
					table.insert(batch, table.remove(r.queue, 1).id)
				end
				r.welcomeUntil = now + C.WelcomeDuration
				r.nextWelcome = now + C.WelcomeGap
				r.welcomeIds = batch
				self.game:effect(
					"welcomeParty",
					{ userId = p.UserId, petIds = batch, position = pro.base.penGate.Position }
				)
			end
			if r.reverenceUntil <= now then
				r.reverencePet = nil
				if now >= r.nextReverence then
					local ok = self:startReverence(p, false)
					if not ok then
						r.nextReverence = now + self.game.rng:NextInteger(C.ReverenceMin, C.ReverenceMax)
					end
				end
			end
			self:updateRecords(p, now)
		end
	end
end

function Ranch:snapshot(p)
	local pro = self.game.profiles[p]
	if not pro then
		return nil
	end
	local spec = C.Expansions[pro.ranchLevel + 1]
	return {
		level = pro.ranchLevel,
		name = spec.name,
		capacity = spec.capacity,
		displayCapacity = pro.ranchDisplayCapacity
			or math.min(spec.capacity, C.RanchVisibleSlots[pro.ranchLevel + 1] or C.MaxVisiblePets),
		nextCost = C.Expansions[pro.ranchLevel + 2] and C.Expansions[pro.ranchLevel + 2].cost or nil,
	}
end

return Ranch
