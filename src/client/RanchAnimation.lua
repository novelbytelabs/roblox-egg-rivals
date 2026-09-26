-- Local articulated motion for the existing primitive-built pets. No gameplay authority.
local A = require(game:GetService("ReplicatedStorage").Stage3Shared.RanchActivityConfig)
local Animation = {}

local HEAD = { Face = true, EyeWhite = true, Eye = true, Glint = true, Muzzle = true }
local EYES = { EyeWhite = true, Eye = true, Glint = true }
local function joint(pivot, rotation)
	return CFrame.new(pivot) * rotation * CFrame.new(-pivot)
end

function Animation.bind(model)
	local base = model:GetPivot()
	local face = model:FindFirstChild("Face")
	local neck = face and base:PointToObjectSpace(face.Position) + Vector3.new(0, -0.15, 0.25)
		or Vector3.new(0, 0.3, -0.5)
	local rig = { model = model, parts = {}, neck = neck, truncated = false }
	for _, part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") and part ~= model.PrimaryPart then
			local rest = base:ToObjectSpace(part.CFrame)
			local name = part.Name
			local role
			if HEAD[name] or (name == "Ear" and rest.Position.Z < -0.1) then
				role = "Head"
			elseif name == "Tail" or name == "TailStripe" then
				role = "Tail"
			elseif name == "Foot" then
				role = "Foot"
			elseif name == "Arm" or name == "Knuckle" then
				role = "Arm"
			elseif name == "Wing" or name == "WindFin" then
				role = "Wing"
			end
			if role then
				if #rig.parts >= A.MaxAnimatedParts then
					rig.truncated = true
				else
					local mesh = EYES[name] and part:FindFirstChildOfClass("SpecialMesh") or nil
					table.insert(rig.parts, {
						part = part,
						rest = rest,
						role = role,
						side = rest.Position.X < 0 and -1 or 1,
						phase = (rest.Position.Z < 0 and -1 or 1) * (rest.Position.X < 0 and -1 or 1),
						mesh = mesh,
						scale = mesh and mesh.Scale or nil,
					})
				end
			end
		end
	end
	return rig
end

function Animation.update(rig, base, now, behavior, kind, speed, seed, godly)
	local resting = behavior == "Rest" or kind == "GroupNap" or kind == "HabitatRest"
	local cheering = kind == "Welcome" or kind == "Homecoming" or kind == "Milestone"
	local moving = not resting and (speed > 0.6 or kind == "Training")
	local phase = now * 6 + seed * 0.7
	local blinkPhase = (now + seed * 0.31) % 5.3
	local blink = resting and 0.14 or (blinkPhase < 0.10 and 0.10 or 1)
	local headPitch = resting and 0.12 or math.sin(now * 1.3 + seed) * 0.025
	local headYaw = resting and 0 or math.sin(now * 0.85 + seed) * 0.10
	for _, entry in ipairs(rig.parts) do
		local part = entry.part
		if part.Parent == rig.model then
			local delta = CFrame.new()
			if entry.role == "Head" then
				delta = joint(rig.neck, CFrame.Angles(headPitch, headYaw, 0))
			elseif entry.role == "Tail" then
				local amplitude = resting and 0.025 or (godly and 0.04 or 0.14)
				delta = joint(Vector3.new(0, 0.05, 0.9), CFrame.Angles(0, math.sin(now * 2 + seed) * amplitude, 0))
			elseif entry.role == "Foot" then
				local stride = moving and math.sin(phase) * entry.phase or 0
				delta = joint(entry.rest.Position + Vector3.new(0, 0.18, 0), CFrame.Angles(stride * 0.28, 0, 0))
					* CFrame.new(0, math.max(0, stride) * 0.055, 0)
			elseif entry.role == "Arm" then
				local swing = moving and math.sin(phase) * entry.side * 0.19 or 0
				local cheer = cheering and (0.18 + math.abs(math.sin(now * 4)) * 0.25) or 0
				delta = joint(Vector3.new(entry.side * 1.2, 0.65, 0), CFrame.Angles(swing, 0, entry.side * cheer))
			elseif entry.role == "Wing" then
				local amplitude = resting and 0.025 or (godly and 0.075 or 0.24)
				delta = joint(
					Vector3.new(entry.side * 0.85, 0.45, 0.25),
					CFrame.Angles(0, 0, entry.side * math.sin(now * 3.5 + seed) * amplitude)
				)
			end
			-- Rebuild from the captured rest pose, never from the previous animated pose.
			part.CFrame = base * delta * entry.rest
			if entry.mesh and entry.mesh.Parent == part then
				entry.mesh.Scale = Vector3.new(entry.scale.X, entry.scale.Y * blink, entry.scale.Z)
			end
		end
	end
end

return Animation
