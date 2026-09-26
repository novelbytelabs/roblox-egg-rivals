-- Server-owned, bounded presentation episodes. This service never mutates an item or Coins.
local Shared = game:GetService("ReplicatedStorage").Stage3Shared
local C = require(Shared.Config)
local R = require(Shared.Rules)
local A = require(Shared.RanchActivityConfig)
local PetMotion = require(Shared.PetMotion)
local Motion = require(Shared.RanchMotion)
local Activities = {}
Activities.__index = Activities

local FIELDS = {
	"ActivityKind",
	"ActivityOrigin",
	"ActivityTarget",
	"ActivityFocus",
	"ActivityStarted",
	"ActivityEnds",
	"ActivityTravel",
	"ActivityPhase",
	"ActivityPartnerId",
	"ActivityOwnerUserId",
	"ActivityHome",
	"ActivitySerial",
	"ActivityHabitat",
	"ActivityGroupId",
}
local COMPANION_FIELDS = {
	"CompanionActivity",
	"CompanionUntil",
	"CompanionTarget",
	"CompanionOwnerUserId",
}
local function set(record, name, value)
	if record:GetAttribute(name) ~= value then
		record:SetAttribute(name, value)
	end
end
local function horizontal(a, b)
	local d = a - b
	return Vector2.new(d.X, d.Z).Magnitude
end
local function sorted(visible)
	table.sort(visible, function(a, b)
		if a.item.order == b.item.order then
			return a.item.id < b.item.id
		end
		return a.item.order < b.item.order
	end)
	return visible
end

function Activities.new(gameService)
	assert(R.integer(A.MaxPairs, 1, 4) and R.integer(A.NapMembers, 2, 4), "Invalid group budget")
	assert(R.integer(A.MaxGreeters, 1, 8) and R.integer(A.MaxSpectators, 1, 8), "Invalid reaction budget")
	assert(
		A.EpisodeSeconds >= 2 and A.GroupSeconds >= 2 and A.GroupInterval >= A.GroupSeconds,
		"Invalid activity duration"
	)
	assert(A.WalkSpeed > 0 and A.HomecomingCooldown >= A.HomecomingSeconds, "Invalid activity pacing")
	return setmetatable({ game = gameService }, Activities)
end

function Activities:reset(p)
	local g, pro = self.game, self.game.profiles[p]
	if not pro or not pro.ranch then
		return
	end
	pro.ranch.activities = {}
	pro.ranch.nextGroupAt = 0
	for _, record in ipairs(g.petRecords:GetChildren()) do
		if record:GetAttribute("OwnerUserId") == p.UserId or record:GetAttribute("ActivityOwnerUserId") == p.UserId then
			self:clear(record)
		end
		if
			record:GetAttribute("OwnerUserId") == p.UserId
			or record:GetAttribute("CompanionOwnerUserId") == p.UserId
		then
			for _, name in ipairs(COMPANION_FIELDS) do
				set(record, name, nil)
			end
		end
		if record:GetAttribute("OwnerUserId") == p.UserId then
			set(record, "BehaviorState", "Idle")
		end
	end
	set(pro.base.model, "ActivityResidentCount", 0)
end

function Activities:leaving(p)
	local pro = self.game.profiles[p]
	if not pro then
		return
	end
	self:reset(p)
	-- Game removes this owner's inventory before calling the ranch cleanup hook.
	pro.base.earningsLabel.Text = "YOUR RANCH\n0 pets • +0 Coins/min"
end

function Activities:training(p, pro)
	local root = self.game:root(p)
	return pro.training == true
		and self.game:alive(p)
		and not self.game:busy(p)
		and root ~= nil
		and R.within(root.Position, pro.base.treadmill.Position, 5, 2.9, 5)
end

function Activities:homecoming(p, reason)
	local g = self.game
	local pro = g.profiles[p]
	if not pro or not pro.ranch or not g:alive(p) then
		return false
	end
	if reason ~= "return" and reason ~= "respawn" and reason ~= "record" then
		return false
	end
	local r, now = pro.ranch, g:now()
	if reason == "record" then
		if now < (r.nextCelebration or 0) then
			return false
		end
		r.milestoneUntil = now + A.MilestoneSeconds
		r.nextCelebration = now + A.MilestoneCooldown
	else
		if now < (r.nextHomecoming or 0) then
			return false
		end
		r.greetUntil = now + A.HomecomingSeconds
		r.nextHomecoming = now + A.HomecomingCooldown
	end
	g:effect("homecoming", { userId = p.UserId, position = pro.base.respawnPad.Position, reason = reason })
	return true
end

function Activities:clear(record)
	for _, name in ipairs(FIELDS) do
		set(record, name, nil)
	end
end

function Activities:godlies(ownerId)
	local out = {}
	for _, record in ipairs(self.game.petRecords:GetChildren()) do
		if
			record:GetAttribute("OwnerUserId") == ownerId
			and record:GetAttribute("Rarity") == "Godly"
			and record:GetAttribute("DisplayMode") == "Pen"
			and record:GetAttribute("Displayed") == true
			and record:GetAttribute("Locked") ~= true
		then
			local position = record:GetAttribute("PenPosition")
			if R.vector(position) then
				table.insert(out, position)
			end
		end
	end
	return out
end

function Activities:position(record, owner)
	if not record or not owner or not self.game.profiles[owner] then
		return nil
	end
	local data = Motion.read(record)
	if not data or data.ownerId ~= owner.UserId then
		return nil
	end
	local cf = Motion.pose(data, self.game:now(), self:godlies(owner.UserId))
	return cf.Position
end

function Activities:site(pro, element)
	local site = pro.base.activitySites and pro.base.activitySites[element]
	local area = pro.base.model:FindFirstChild("PenArea")
	if
		not site
		or site.element ~= element
		or not site.anchor
		or not site.model
		or not area
		or site.area ~= area
		or site.layout ~= pro.base.ranchLayoutSerial
	then
		return nil
	end
	if
		not site.anchor:IsA("BasePart")
		or not site.model:IsA("Model")
		or not site.anchor:IsDescendantOf(site.model)
		or not site.model:IsDescendantOf(area)
		or site.anchor:GetAttribute("BaseIndex") ~= pro.base.index
		or site.anchor:GetAttribute("Element") ~= element
		or not R.vector(site.anchor.Position)
	then
		return nil
	end
	local offset = site.anchor.Position - pro.base.penCenter
	if math.abs(offset.X) > pro.base.penBounds.X or math.abs(offset.Z) > pro.base.penBounds.Y then
		return nil
	end
	return site
end

function Activities:make(pro, entry, kind, target, focus, now, duration, godlies, key)
	local r, record, item = pro.ranch, entry.record, entry.item
	local home = record:GetAttribute("PenPosition")
	local seed = item.order
	target = PetMotion.constrain(target, home, pro.base.penCenter, pro.base.penBounds, godlies, seed)
	local previous = Motion.read(record)
	local origin = home
	if previous then
		origin = Motion.pose(previous, now, godlies).Position
	end
	r.activitySerial = (r.activitySerial or 0) + 1
	return {
		kind = kind,
		origin = origin,
		target = target,
		focus = focus,
		started = now,
		ends = now + duration,
		travel = math.clamp(horizontal(origin, target) / A.WalkSpeed, 0.25, duration * 0.65),
		phase = 0,
		ownerId = item.ownerId,
		home = home,
		layout = pro.base.ranchLayoutSerial or 0,
		serial = r.activitySerial,
		key = key,
	}
end

function Activities:valid(pro, entry, plan, members, now)
	if
		not plan
		or now >= plan.ends
		or plan.ownerId ~= entry.item.ownerId
		or plan.home ~= entry.record:GetAttribute("PenPosition")
		or plan.layout ~= (pro.base.ranchLayoutSerial or 0)
	then
		return false
	end
	if plan.habitat then
		local site = self:site(pro, plan.habitat)
		if not site or site.anchor ~= plan.siteAnchor or site.anchor.Position ~= plan.sitePosition then
			return false
		end
	end
	if plan.partnerId then
		local partner = members[plan.partnerId]
		if not partner or partner.item.ownerId ~= entry.item.ownerId or partner.item.rarity == "Godly" then
			return false
		end
	end
	return true
end

function Activities:publish(entry, plan, behavior, now)
	local record = entry.record
	if record:GetAttribute("BehaviorState") ~= behavior then
		set(record, "BehaviorStarted", now)
	end
	set(record, "BehaviorState", behavior)
	if not plan then
		self:clear(record)
		return
	end
	set(record, "ActivityOrigin", plan.origin)
	set(record, "ActivityTarget", plan.target)
	set(record, "ActivityFocus", plan.focus)
	set(record, "ActivityStarted", plan.started)
	set(record, "ActivityEnds", plan.ends)
	set(record, "ActivityTravel", plan.travel)
	set(record, "ActivityPhase", plan.phase)
	set(record, "ActivityPartnerId", plan.partnerId)
	set(record, "ActivityGroupId", plan.groupId)
	set(record, "ActivityHabitat", plan.habitat)
	set(record, "ActivityOwnerUserId", plan.ownerId)
	set(record, "ActivityHome", plan.home)
	set(record, "ActivityKind", plan.kind)
	set(record, "ActivitySerial", plan.serial)
end

function Activities:solo(pro, entry, now, godlies)
	local r, item = pro.ranch, entry.item
	r.soloSequence = (r.soloSequence or 0) + 1
	local choice = (r.soloSequence + item.order) % 5
	local center, bounds = pro.base.penCenter, pro.base.penBounds
	local home = entry.record:GetAttribute("PenPosition")
	local site = self:site(pro, item.element)
	local kind, target, focus = "Idle", home, home + Vector3.new(0, 0, 1)
	if site and choice <= 1 then
		kind = "HabitatRest"
		local angle = (item.order % 8) * math.pi / 4
		target = site.anchor.Position + Vector3.new(math.cos(angle) * 1.2, 0, math.sin(angle) * 1.2)
		focus = site.anchor.Position
	elseif choice == 2 then
		kind = "Explore"
		local angle = item.order * 0.73 + r.soloSequence
		target = home + Vector3.new(math.cos(angle) * 2.4, 0, math.sin(angle) * 1.8)
		focus = target + Vector3.new(0, 0, 1)
	elseif choice == 3 then
		kind = "GateWatch"
		target = Vector3.new(home.X, center.Y, center.Z + bounds.Y - 0.5)
		focus = pro.base.penGate.Position
	else
		kind = "SoloPlay"
	end
	local duration = A.EpisodeSeconds + (item.order % 4) * A.EpisodeStagger
	local plan = self:make(pro, entry, kind, target, focus, now, duration, godlies)
	if kind == "HabitatRest" then
		plan.habitat = item.element
		plan.siteAnchor, plan.sitePosition = site.anchor, site.anchor.Position
	end
	return plan
end

function Activities:groups(pro, available, plans, now, godlies)
	local r = pro.ranch
	if now < (r.nextGroupAt or 0) or #available < 2 then
		return
	end
	r.nextGroupAt = now + A.GroupInterval
	r.groupSerial = (r.groupSerial or 0) + 1
	local groupId = tostring(pro.base.index) .. ":" .. tostring(r.groupSerial)
	local napActive = false
	for _, plan in pairs(plans) do
		if plan.kind == "GroupNap" then
			napActive = true
			break
		end
	end
	if r.groupSerial % 3 == 0 and not napActive then
		local leader = available[1]
		local members = { leader }
		for i = 2, #available do
			local candidate = available[i]
			if candidate.item.element == leader.item.element and #members < A.NapMembers then
				table.insert(members, candidate)
			end
		end
		if #members >= 2 then
			local site = self:site(pro, leader.item.element)
			local focus = site and site.anchor.Position or leader.record:GetAttribute("PenPosition")
			for i, member in ipairs(members) do
				local target = focus + Vector3.new((i - (#members + 1) / 2) * 2.2, 0, -1)
				local plan = self:make(pro, member, "GroupNap", target, focus, now, A.GroupSeconds, godlies)
				plan.groupId = groupId
				plan.habitat = site and leader.item.element or nil
				plan.siteAnchor = site and site.anchor or nil
				plan.sitePosition = site and site.anchor.Position or nil
				plans[member.item.id] = plan
			end
			return
		end
	end
	local used, pairsMade, existing = {}, 0, {}
	for _, plan in pairs(plans) do
		if plan.kind == "PairPlay" and plan.groupId and not existing[plan.groupId] then
			existing[plan.groupId] = true
			pairsMade = pairsMade + 1
		end
	end
	for i, first in ipairs(available) do
		if not used[first.item.id] and pairsMade < A.MaxPairs then
			for j = i + 1, #available do
				local second = available[j]
				local a = first.record:GetAttribute("PenPosition")
				local b = second.record:GetAttribute("PenPosition")
				if not used[second.item.id] and horizontal(a, b) <= A.PairDistance then
					local focus = (a + b) / 2
					for k, member in ipairs({ first, second }) do
						local phase = (k - 1) * math.pi
						local target = focus + Vector3.new(math.cos(phase), 0, math.sin(phase)) * A.ChaseRadius
						local plan = self:make(pro, member, "PairPlay", target, focus, now, A.GroupSeconds, godlies)
						plan.partnerId = k == 1 and second.item.id or first.item.id
						plan.groupId = groupId .. ":" .. tostring(pairsMade + 1)
						plan.phase = phase
						plans[member.item.id] = plan
						used[member.item.id] = true
					end
					-- Both partners enter their orbit on the same clock, despite unequal approach distances.
					local firstPlan, secondPlan = plans[first.item.id], plans[second.item.id]
					local travel = math.max(firstPlan.travel, secondPlan.travel)
					firstPlan.travel, secondPlan.travel = travel, travel
					pairsMade = pairsMade + 1
					break
				end
			end
		end
	end
end

function Activities:updateCompanion(p, pro, now)
	local item = pro.activePetId and self.game.inventory.items[pro.activePetId]
	if
		not item
		or item.kind ~= "Pet"
		or item.ownerId ~= p.UserId
		or item.state ~= "Inventory"
		or item.petMode ~= "Active"
	then
		return
	end
	local record = self.game.petRecords:FindFirstChild(item.id)
	if not record or record:GetAttribute("OwnerUserId") ~= p.UserId then
		return
	end
	local r = pro.ranch
	local kind, untilTime, target = "Follow", now + C.RanchTick * 3, nil
	if self.game:alive(p) and not self.game:busy(p) then
		if r.greetUntil > now then
			kind, untilTime = "Homecoming", r.greetUntil
		elseif (r.milestoneUntil or 0) > now then
			kind, untilTime = "Milestone", r.milestoneUntil
		elseif self:training(p, pro) then
			kind, target = "Training", pro.base.treadmill.Position
		end
	end
	set(record, "CompanionActivity", kind)
	set(record, "CompanionUntil", untilTime)
	set(record, "CompanionTarget", target)
	set(record, "CompanionOwnerUserId", p.UserId)
end

function Activities:updateRecords(ranch, p, now)
	local g, pro = self.game, self.game.profiles[p]
	if not pro or not pro.ranch then
		return
	end
	local r = pro.ranch
	r.activities = r.activities or {}
	local plans, members = r.activities, {}
	local visible = sorted(ranch:visiblePets(p))
	local eligible = {}
	for _, entry in ipairs(visible) do
		local item, record = entry.item, entry.record
		if
			g.inventory.items[item.id] == item
			and item.ownerId == p.UserId
			and item.state == "Inventory"
			and record:GetAttribute("OwnerUserId") == p.UserId
			and record:GetAttribute("DisplayMode") == "Pen"
			and record:GetAttribute("Locked") ~= true
			and R.vector(record:GetAttribute("PenPosition"))
		then
			members[item.id] = entry
			table.insert(eligible, entry)
		end
	end
	visible = eligible
	for id in pairs(plans) do
		if not members[id] then
			plans[id] = nil
		end
	end
	local godlies = self:godlies(p.UserId)
	local chosen = r.reverenceUntil > now and members[r.reverencePet] or nil
	if r.reverenceUntil > now and (not chosen or chosen.item.rarity ~= "Godly") then
		r.reverenceUntil, r.reverencePet = 0, nil
		chosen = nil
	end
	local behaviorFor, available = {}, {}
	local root = g:root(p)
	local training = self:training(p, pro)
	for index, entry in ipairs(visible) do
		local item, record = entry.item, entry.record
		local behavior, kind, target, focus, key, duration
		local home, center, bounds = record:GetAttribute("PenPosition"), pro.base.penCenter, pro.base.penBounds
		if chosen then
			behavior = item.id == chosen.item.id and "Ascend"
				or (item.rarity ~= "Godly" and item.element == chosen.item.element and "Revere" or "Idle")
		elseif item.rarity == "Godly" then
			behavior = "Idle"
		elseif r.welcomeUntil > now then
			behavior, kind, key, duration = "Greet", "Welcome", "welcome:" .. r.welcomeUntil, r.welcomeUntil - now
		elseif r.greetUntil > now and index <= A.MaxGreeters then
			behavior, kind, key, duration = "Homecoming", "Homecoming", "home:" .. r.greetUntil, r.greetUntil - now
		elseif (r.milestoneUntil or 0) > now and index <= A.MaxGreeters then
			behavior, kind, key, duration =
				"Play", "Milestone", "milestone:" .. r.milestoneUntil, r.milestoneUntil - now
		elseif training and index <= A.MaxSpectators then
			behavior, kind, key, duration = "Idle", "TrainingWatch", "training", A.EpisodeSeconds
		end
		if behavior and not kind then
			plans[item.id] = nil
		elseif kind then
			local columns = math.max(4, math.floor(bounds.X * 2 / 5.1))
			local slot = index - 1
			target = center
				+ Vector3.new(
					(slot % columns - (columns - 1) / 2) * 3.6,
					0,
					bounds.Y - 0.7 - math.floor(slot / columns) * 3.6
				)
			focus = kind == "TrainingWatch" and pro.base.treadmill.Position
				or (kind == "Homecoming" and root and root.Position or pro.base.penGate.Position)
			local current = plans[item.id]
			if not self:valid(pro, entry, current, members, now) or current.key ~= key then
				plans[item.id] = self:make(pro, entry, kind, target, focus, now, math.max(0.5, duration), godlies, key)
			else
				current.focus = focus
			end
		else
			local current = plans[item.id]
			local site = current and current.habitat and self:site(pro, current.habitat) or nil
			local lostHabitat = current
				and current.habitat
				and (not site or site.anchor ~= current.siteAnchor or site.anchor.Position ~= current.sitePosition)
			if lostHabitat then
				-- A removed/replaced landmark falls back to this pet's own home, not a foreign target.
				plans[item.id] =
					self:make(pro, entry, "Idle", home, home + Vector3.new(0, 0, 1), now, A.EpisodeSeconds, godlies)
			elseif not self:valid(pro, entry, current, members, now) or current.key ~= nil then
				plans[item.id] = nil
				table.insert(available, entry)
			end
		end
		behaviorFor[item.id] = behavior
		set(record, "BehaviorSeed", item.order)
		set(record, "Godly", item.rarity == "Godly")
		set(record, "RanchGatePosition", pro.base.penGate.Position)
		set(record, "PenCenter", pro.base.penCenter)
		set(record, "PenBounds", pro.base.penBounds)
		set(record, "ReverenceTarget", behavior == "Revere" and chosen.record:GetAttribute("PenPosition") or nil)
		set(record, "WelcomeMember", r.welcomeUntil > now and table.find(r.welcomeIds, item.id) ~= nil)
	end
	-- A partner interrupted by a higher-priority event cannot leave an orphaned chase.
	local queued, napCounts = {}, {}
	for _, entry in ipairs(available) do
		queued[entry.item.id] = true
	end
	for _, entry in ipairs(visible) do
		local id = entry.item.id
		local plan = plans[id]
		if plan and plan.partnerId then
			local partnerPlan = plans[plan.partnerId]
			if
				not partnerPlan
				or partnerPlan.partnerId ~= id
				or partnerPlan.groupId ~= plan.groupId
				or behaviorFor[plan.partnerId] ~= nil
			then
				plans[id] = nil
				if not behaviorFor[id] and not queued[id] then
					table.insert(available, entry)
					queued[id] = true
				end
			end
		elseif plan and plan.kind == "GroupNap" and plan.groupId then
			napCounts[plan.groupId] = (napCounts[plan.groupId] or 0) + 1
		end
	end
	for _, entry in ipairs(visible) do
		local id = entry.item.id
		local plan = plans[id]
		if plan and plan.kind == "GroupNap" and (napCounts[plan.groupId] or 0) < 2 then
			plans[id] = nil
			if not behaviorFor[id] and not queued[id] then
				table.insert(available, entry)
				queued[id] = true
			end
		end
	end
	self:groups(pro, available, plans, now, godlies)
	for _, entry in ipairs(available) do
		if not plans[entry.item.id] then
			plans[entry.item.id] = self:solo(pro, entry, now, godlies)
		end
	end
	for _, entry in ipairs(visible) do
		local plan = plans[entry.item.id]
		local behavior = behaviorFor[entry.item.id]
		if not behavior then
			local kind = plan and plan.kind or "Idle"
			behavior = (kind == "PairPlay" or kind == "SoloPlay") and "Play"
				or (
					(kind == "GroupNap" or kind == "HabitatRest") and "Rest"
					or (kind == "Explore" and "Wander" or "Idle")
				)
		end
		self:publish(entry, plan, behavior, now)
	end
	for _, record in ipairs(g.petRecords:GetChildren()) do
		if record:GetAttribute("ActivityOwnerUserId") == p.UserId and not members[record.Name] then
			self:clear(record)
		end
		if
			record:GetAttribute("CompanionOwnerUserId") == p.UserId
			and (
				record:GetAttribute("OwnerUserId") ~= p.UserId
				or record.Name ~= pro.activePetId
				or record:GetAttribute("DisplayMode") ~= "Active"
				or record:GetAttribute("Locked") == true
			)
		then
			for _, name in ipairs(COMPANION_FIELDS) do
				set(record, name, nil)
			end
		end
	end
	self:updateCompanion(p, pro, now)
	set(pro.base.model, "ActivityResidentCount", #visible)
end

return Activities
