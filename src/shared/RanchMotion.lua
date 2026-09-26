-- One presentation sampler is shared by the renderer and server visitor proximity.
-- Replicated poses never confer ownership, rewards, combat or movement authority.
local A = require(script.Parent.RanchActivityConfig)
local PetMotion = require(script.Parent.PetMotion)
local M = {}

local function finite(n)
	return type(n) == "number" and n == n and math.abs(n) < 1e12
end
local function vector(v)
	return typeof(v) == "Vector3" and finite(v.X) and finite(v.Y) and finite(v.Z)
end
local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end
local function facing(position, target)
	local direction = flat(target - position)
	if direction.Magnitude < 0.001 then
		direction = Vector3.new(0, 0, 1)
	end
	return CFrame.lookAt(position, position + direction.Unit)
end

function M.read(record)
	local home = record:GetAttribute("PenPosition")
	local center = record:GetAttribute("PenCenter")
	local bounds = record:GetAttribute("PenBounds")
	if not vector(home) or not vector(center) or typeof(bounds) ~= "Vector2" then
		return nil
	end
	if not finite(bounds.X) or not finite(bounds.Y) or bounds.X <= 0 or bounds.Y <= 0 then
		return nil
	end
	local seed = record:GetAttribute("BehaviorSeed")
	local index = record:GetAttribute("DisplayIndex")
	local gate = record:GetAttribute("RanchGatePosition")
	local target = record:GetAttribute("ReverenceTarget")
	return {
		home = home,
		center = center,
		bounds = bounds,
		seed = finite(seed) and seed or 1,
		index = finite(index) and index or 1,
		creature = record:GetAttribute("Creature"),
		behavior = record:GetAttribute("BehaviorState"),
		godly = record:GetAttribute("Rarity") == "Godly",
		gate = vector(gate) and gate or center + Vector3.new(0, 0, bounds.Y),
		target = vector(target) and target or nil,
		ownerId = record:GetAttribute("OwnerUserId"),
		activityOwner = record:GetAttribute("ActivityOwnerUserId"),
		activityHome = record:GetAttribute("ActivityHome"),
		kind = record:GetAttribute("ActivityKind"),
		origin = record:GetAttribute("ActivityOrigin"),
		destination = record:GetAttribute("ActivityTarget"),
		focus = record:GetAttribute("ActivityFocus"),
		started = record:GetAttribute("ActivityStarted"),
		ends = record:GetAttribute("ActivityEnds"),
		travel = record:GetAttribute("ActivityTravel"),
		phase = record:GetAttribute("ActivityPhase") or 0,
	}
end

function M.valid(data, now)
	return data ~= nil
		and finite(now)
		and A.Kinds[data.kind] == true
		and finite(data.ownerId)
		and data.activityOwner == data.ownerId
		and data.activityHome == data.home
		and vector(data.origin)
		and vector(data.destination)
		and vector(data.focus)
		and finite(data.started)
		and finite(data.ends)
		and finite(data.travel)
		and finite(data.phase)
		and data.travel >= 0.25
		and data.ends > data.started
		and now >= data.started - A.SnapshotGrace
		and now <= data.ends + A.SnapshotGrace
end

function M.pose(data, now, godlies)
	local baseline, grounded, landing = PetMotion.pose(data, now, godlies)
	-- The original Godly and same-element bow semantics always win.
	if data.godly or data.behavior == "Revere" or not M.valid(data, now) then
		return baseline, grounded, landing
	end
	local age = math.max(0, now - data.started)
	local progress = math.clamp(age / data.travel, 0, 1)
	local eased = progress * progress * (3 - 2 * progress)
	local destination = data.destination
	local localTime = math.max(0, age - data.travel)
	local afterArrival = progress >= 1
	local height = data.center.Y + 0.23 + (PetMotion.GroundOffsets[data.creature] or 0.85)
	local phase = now + data.seed * 0.413
	grounded, landing = true, false
	local pitch, roll = 0, 0
	local focus = data.focus
	if data.kind == "PairPlay" and afterArrival then
		local angle = data.phase + localTime * 2 * math.pi / A.ChasePeriod
		destination = data.focus + Vector3.new(math.cos(angle), 0, math.sin(angle)) * A.ChaseRadius
		focus = destination + Vector3.new(-math.sin(angle), 0, math.cos(angle))
	elseif (data.kind == "SoloPlay" or data.kind == "Milestone") and afterArrival then
		local fraction = (localTime % 2.2) / 1.55
		if fraction < 1 then
			destination = destination + (Vector3.new(math.sin(fraction * math.pi * 2) * 0.65, 0, 0))
			height = height + (math.sin(fraction * math.pi) * (data.creature == "Gorilla" and 0.45 or 0.85))
			grounded = false
		else
			landing = true
		end
	elseif (data.kind == "GroupNap" or data.kind == "HabitatRest") and afterArrival then
		height = height - (0.18)
		height = height + (math.sin(phase * 1.1) * 0.025)
		pitch = data.creature == "Gorilla" and 0.10 or 0.03
		roll = data.creature == "Skunk" and 0.12 or 0
	elseif data.kind == "Homecoming" or data.kind == "Welcome" then
		height = height + (math.abs(math.sin(phase * 4)) * 0.12)
	elseif afterArrival then
		-- Small species-specific looking/sniffing motions rather than perpetual bouncing.
		if data.creature == "Lizard" then
			roll = math.sin(phase * 1.7) * 0.035
		elseif data.creature == "Skunk" then
			pitch = math.sin(phase * 1.6) * 0.035
		elseif data.creature == "Gorilla" then
			pitch = math.sin(phase * 0.8) * 0.025
		elseif data.creature == "Dragon" then
			height = height + (0.18 + math.sin(phase * 1.4) * 0.06)
			grounded = false
		end
	end
	local position = data.origin:Lerp(destination, eased)
	position = Vector3.new(position.X, height, position.Z)
	if not afterArrival then
		focus = destination
	end
	position = PetMotion.constrain(position, data.home, data.center, data.bounds, godlies or {}, data.seed)
	return facing(position, focus) * CFrame.Angles(pitch, 0, roll), grounded, landing
end

function M.companion(record, root, now)
	local creature = record:GetAttribute("Creature")
	local normal = root.CFrame * CFrame.new(3.2, 0.35 + math.sin(now * 3) * 0.18, 5.2)
	if record:GetAttribute("CompanionOwnerUserId") ~= record:GetAttribute("OwnerUserId") then
		return normal
	end
	local untilTime = record:GetAttribute("CompanionUntil")
	if not finite(untilTime) or now > untilTime then
		return normal
	end
	local kind = record:GetAttribute("CompanionActivity")
	local trainer = record:GetAttribute("CompanionTarget")
	if kind == "Training" and vector(trainer) then
		local y = creature == "Dragon" and (2.3 + math.sin(now * 2.2) * 0.25)
			or (creature == "Gorilla" and 1.0 or 0.8)
		if creature == "Lizard" or creature == "Skunk" then
			y = y + (math.abs(math.sin(now * 7)) * 0.14)
		end
		local position = trainer + Vector3.new(1.5, y, 4.4)
		return facing(position, trainer)
	elseif kind == "Homecoming" or kind == "Milestone" then
		local position = (root.CFrame * CFrame.new(2.8, 0.35, 4.5)).Position
		position = position + (Vector3.new(0, math.abs(math.sin(now * 4)) * 0.12, 0))
		return facing(position, root.Position)
	end
	return normal
end

return M
