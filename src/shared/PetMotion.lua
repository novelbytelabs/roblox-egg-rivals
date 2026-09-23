-- Shared presentation geometry. Ownership and income never depend on these poses.
local C = require(script.Parent.Config)
local P = {}
P.GroundOffsets = { Skunk = 0.8, Lizard = 0.65, Gorilla = 1.13, Dragon = 0.85 }
function P.constrain(pos, home, center, bounds, godlies, seed)
	local function inside(v)
		return Vector3.new(
			math.clamp(v.X, center.X - bounds.X, center.X + bounds.X),
			v.Y,
			math.clamp(v.Z, center.Z - bounds.Y, center.Z + bounds.Y)
		)
	end
	pos = inside(pos)
	for _ = 1, 4 do
		for _, godly in ipairs(godlies) do
			local d = Vector3.new(pos.X - godly.X, 0, pos.Z - godly.Z)
			if d.Magnitude < C.GodlyDistance then
				local away = d.Magnitude > 0.001 and d.Unit or Vector3.new(math.cos(seed), 0, math.sin(seed))
				pos = inside(Vector3.new(godly.X, pos.Y, godly.Z) + away * (C.GodlyDistance + 0.03))
			end
		end
	end
	for _, godly in ipairs(godlies) do
		if Vector3.new(pos.X - godly.X, 0, pos.Z - godly.Z).Magnitude < C.GodlyDistance - 0.01 then
			return Vector3.new(home.X, pos.Y, home.Z)
		end
	end
	return pos
end
function P.pose(data, now, godlies)
	local home, center, bounds = data.home, data.center, data.bounds
	local seed = data.seed or 1
	local phase = now + (seed * 0.413)
	local base = Vector3.new(home.X, center.Y + 0.23 + (P.GroundOffsets[data.creature] or 0.85), home.Z)
	local pos = base
	local look = Vector3.new(0, 0, 1)
	local behavior = data.behavior or "Idle"
	local landing = false
	local grounded = true
	if data.godly then
		pos += Vector3.new(0, 0.4 + math.sin(phase * 1.3) * 0.08, 0)
		if behavior == "Ascend" then
			pos += Vector3.new(0, 3.8, 0)
		end
		grounded = false
	elseif behavior == "Wander" then
		local offset = Vector3.new(math.sin(phase * 0.7) * 1.25, 0, math.cos(phase * 0.65) * 1.1)
		pos += offset
		look = Vector3.new(math.cos(phase * 0.7), 0, -math.sin(phase * 0.65))
	elseif behavior == "Play" then
		local f = (phase % 2.2) / 1.55
		if f < 1 then
			pos += Vector3.new(math.sin(f * math.pi * 2) * 1.05, math.sin(f * math.pi) * 1.1, 0)
			look = Vector3.new(math.cos(f * math.pi * 2), 0, 0.5)
			grounded = false
		else
			landing = true
		end
	elseif behavior == "Rest" then
		pos += Vector3.new(0, -0.18, 0)
	elseif behavior == "Greet" or behavior == "Homecoming" then
		local slot = (data.index or seed) - 1
		local columns = math.max(4, math.floor(bounds.X * 2 / 5.1))
		local x = (slot % columns - (columns - 1) / 2) * 3.6
		local z = data.gate.Z - 3.3 - math.floor(slot / columns) * 3.6
		pos = Vector3.new(center.X + x, base.Y + math.abs(math.sin(phase * 4)) * 0.12, z)
		look = Vector3.new(0, 0, 1)
	elseif behavior == "Revere" and data.target then
		look = Vector3.new(data.target.X - pos.X, 0, data.target.Z - pos.Z)
		pos += Vector3.new(0, -0.14, 0)
	end
	if not data.godly then
		pos = P.constrain(pos, base, center, bounds, godlies or {}, seed)
	end
	if look.Magnitude < 0.001 then
		look = Vector3.new(0, 0, 1)
	end
	local cf = CFrame.lookAt(pos, pos + look.Unit)
	if behavior == "Revere" and not data.godly then
		cf *= CFrame.Angles(math.rad(22), 0, 0)
	end
	return cf, grounded, landing
end
return P
