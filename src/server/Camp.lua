-- Original modular camp geometry. Upgrades replace only owned presentation sections.
local Shared = game:GetService("ReplicatedStorage").Stage3Shared
local C = require(Shared.Config)
local Art = require(Shared.Art)
local Camp = {}
local wood = Color3.fromRGB(104, 71, 49)
local metal = Color3.fromRGB(35, 53, 61)
local function part(parent, name, size, pos, color, material, collide)
	local p = Art.part(parent, name, size, CFrame.new(pos), color, nil, material)
	p.CanCollide = collide == true
	p.CanQuery = collide == true
	return p
end
local function ring(parent, name, pos, radius, color, segments)
	local folder = Instance.new("Model")
	folder.Name = name
	folder.Parent = parent
	for i = 1, segments or 16 do
		local count = segments or 16
		local angle = i * 2 * math.pi / count
		local p = part(
			folder,
			"Arc",
			Vector3.new(radius * 2 * math.sin(math.pi / count) + 0.05, 0.13, 0.15),
			pos + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius),
			color,
			Enum.Material.Neon,
			false
		)
		p.CFrame *= CFrame.Angles(0, -angle - math.pi / 2, 0)
		p:SetAttribute("NightTint", color)
	end
	return folder
end
function Camp.create(parent, index, color)
	local x = (index - 2.5) * 42
	local m = Instance.new("Model")
	m.Name = "Base" .. index
	m:SetAttribute("BaseIndex", index)
	m.Parent = parent
	local b = { model = m, index = index, x = x, color = color, center = Vector3.new(x, 0.5, -40), owner = nil }
	part(m, "Deck", Vector3.new(38, 0.6, 38), Vector3.new(x, 0.3, -40), wood, Enum.Material.WoodPlanks, true)
	for _, dx in ipairs({ -18.7, 18.7 }) do
		local trim = part(
			m,
			"DeckTrim",
			Vector3.new(0.16, 0.08, 38),
			Vector3.new(x + dx, 0.65, -40),
			color,
			Enum.Material.Neon,
			false
		)
		trim:SetAttribute("NightTint", color)
	end
	local banner = part(m, "Nameplate", Vector3.new(0.1, 0.1, 0.1), Vector3.new(x, 7, -22), color, nil, false)
	banner.Transparency = 1
	b.nameLabel = Art.billboard(banner, "AVAILABLE CAMP", color, 240, 38, Vector3.zero)
	b.treadmill =
		part(m, "Treadmill", Vector3.new(11, 0.9, 6), Vector3.new(x - 6, 1, -40), metal, Enum.Material.Metal, true)
	b.treadmill:SetAttribute("Treadmill", true)
	for j = 1, 8 do
		local stripe = part(
			m,
			"BeltStripe",
			Vector3.new(0.16, 0.06, 5.2),
			Vector3.new(x - 11 + j * 1.2, 1.49, -40),
			color,
			nil,
			false
		)
		stripe:SetAttribute("BeltCenter", b.treadmill.Position)
		stripe:SetAttribute("BeltPhase", j / 8)
	end
	for _, dz in ipairs({ -3.1, 3.1 }) do
		part(
			m,
			"TrainerRail",
			Vector3.new(11, 0.25, 0.25),
			Vector3.new(x - 6, 3, -40 + dz),
			color,
			Enum.Material.Metal,
			false
		)
	end
	local screen =
		part(m, "Console", Vector3.new(0.3, 2, 4), Vector3.new(x - 12, 3, -40), metal, Enum.Material.Glass, false)
	b.recordLabel = Art.billboard(screen, "STARTER LAB\nSTEP ON TO TRAIN", color, 235, 72, Vector3.new(0, 2.5, 0))
	for _, dx in ipairs({ -13, 1 }) do
		part(m, "LabPost", Vector3.new(0.45, 7, 0.45), Vector3.new(x + dx, 3.5, -45), wood, Enum.Material.Wood, true)
	end
	for z = -45, -39, 3 do
		part(
			m,
			"LabCanopySlat",
			Vector3.new(15, 0.22, 1),
			Vector3.new(x - 6, 7.2, z),
			color,
			Enum.Material.Fabric,
			false
		)
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "RespawnPad"
	spawn.Size = Vector3.new(6, 0.3, 6)
	spawn.CFrame = CFrame.lookAt(Vector3.new(x + 7, 0.75, -40), Vector3.new(x + 7, 0.75, 40))
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.AllowTeamChangeOnTouch = false
	spawn.Material = Enum.Material.Slate
	spawn.Color = Color3.fromRGB(104, 132, 127)
	spawn.Parent = m
	b.respawnPad = spawn
	b.spawn = CFrame.lookAt(spawn.Position + Vector3.new(0, 3.5, 0), Vector3.new(x + 7, 4, 40))
	ring(m, "HomeRing", spawn.Position + Vector3.new(0, 0.2, 0), 2.5, color, 16)
	Art.billboard(spawn, "HOME", color, 110, 24, Vector3.new(0, 1.6, 0))
	b.incubators = {}
	local positions = {
		Fire = Vector3.new(x - 13, 1, -27),
		Water = Vector3.new(x + 13, 1, -27),
		Wind = Vector3.new(x - 13, 1, -53),
		Earth = Vector3.new(x + 13, 1, -53),
	}
	for _, element in ipairs(C.ElementOrder) do
		local style = C.Elements[element]
		local pos = positions[element]
		local inc = Instance.new("Model")
		inc.Name = element .. "Sanctum"
		inc:SetAttribute("Element", element)
		inc.Parent = m
		local pad = part(inc, element .. "Incubator", Vector3.new(6.5, 0.8, 6.5), pos, metal, Enum.Material.Metal, true)
		pad:SetAttribute("Element", element)
		pad:SetAttribute("BaseIndex", index)
		inc.PrimaryPart = pad
		local rim = ring(inc, "ElementRing", pos + Vector3.new(0, 0.5, 0), 2.9, style.color, 16)
		local dome = Art.part(
			inc,
			"Dome",
			Vector3.new(5.3, 4.8, 5.3),
			CFrame.new(pos + Vector3.new(0, 2.8, 0)),
			style.color,
			Enum.PartType.Ball,
			Enum.Material.Glass
		)
		dome.Transparency = 0.88
		if element == "Fire" then
			for j = 1, 4 do
				local a = j * math.pi / 2
				local coal = part(
					inc,
					"KilnStone",
					Vector3.new(1.1, 1.6, 1.1),
					pos + Vector3.new(math.cos(a) * 2.7, 0.7, math.sin(a) * 2.7),
					metal,
					Enum.Material.Basalt,
					false
				)
				coal.CFrame *= CFrame.Angles(0.2, a, 0.2)
				local ember = part(
					inc,
					"Ember",
					Vector3.new(0.3, 0.7, 0.3),
					coal.Position + Vector3.new(0, 1, 0),
					style.color,
					Enum.Material.Neon,
					false
				)
				ember:SetAttribute("NightTint", style.night)
			end
		elseif element == "Water" then
			ring(inc, "Ripple", pos + Vector3.new(0, 0.68, 0), 2.25, style.accent, 16)
			for j = 1, 5 do
				local bubble = Art.part(
					inc,
					"WaterBubble",
					Vector3.new(0.4, 0.5, 0.4),
					CFrame.new(pos + Vector3.new(-2.4 + j * 0.8, 3.5 + (j % 2) * 0.4, 2)),
					style.accent,
					Enum.PartType.Ball,
					Enum.Material.Glass
				)
				bubble.Transparency = 0.2
				bubble:SetAttribute("FloatRest", bubble.Position)
				bubble:SetAttribute("FloatPhase", j)
			end
		elseif element == "Wind" then
			ring(inc, "WindHalo", pos + Vector3.new(0, 4.4, 0), 2.65, style.accent, 16)
			for j = 1, 3 do
				local vane = part(
					inc,
					"WindVane",
					Vector3.new(0.2, 2, 0.8),
					pos + Vector3.new(-2.8 + (j - 1) * 2.8, 2.4, 2.6),
					style.color,
					Enum.Material.Neon,
					false
				)
				vane:SetAttribute("SpinRest", vane.CFrame)
				vane:SetAttribute("SpinRate", 0.7 + j * 0.1)
			end
		else
			for j = 1, 4 do
				local a = j * math.pi / 2
				local rock = part(
					inc,
					"RootStone",
					Vector3.new(1.1, 2.1, 1.2),
					pos + Vector3.new(math.cos(a) * 2.6, 1, math.sin(a) * 2.6),
					style.accent,
					Enum.Material.Slate,
					false
				)
				rock.CFrame *= CFrame.Angles(0.15, a, 0.2)
				part(
					inc,
					"Moss",
					Vector3.new(1.2, 0.22, 1.3),
					rock.Position + Vector3.new(0, 1.1, 0),
					style.color,
					Enum.Material.Grass,
					false
				)
			end
		end
		local marker = part(
			inc,
			"ElementBanner",
			Vector3.new(0.1, 0.1, 0.1),
			pos + Vector3.new(0, 5.4, 0),
			style.color,
			nil,
			false
		)
		marker.Transparency = 1
		local timer = Art.billboard(marker, element:upper() .. "\nChoose an egg", style.color, 190, 58, Vector3.zero)
		b.incubators[element] = { element = element, pad = pad, timer = timer, model = inc, ring = rim, dome = dome }
	end
	-- The gate stays fixed across expansions so attached interactions remain valid.
	b.penGate = part(m, "PenGate", Vector3.new(0.2, 0.2, 0.2), Vector3.new(x, 1, -62), color, nil, false)
	b.penGate.Transparency = 1
	b.earningsLabel = Art.billboard(b.penGate, "YOUR RANCH\n0 pets", color, 245, 52, Vector3.new(0, 4, 0))
	part(m, "PenWalk", Vector3.new(6, 0.2, 5), Vector3.new(x, 0.2, -60.5), wood, Enum.Material.WoodPlanks, true)
	b.applyGrade = function(tier)
		Camp.applyGrade(b, tier)
	end
	b.applyExpansion = function(level)
		Camp.applyExpansion(b, level)
	end
	Camp.applyGrade(b, 1)
	Camp.applyExpansion(b, 0)
	return b
end

function Camp.applyGrade(b, tier)
	assert(C.Grades[tier], "Invalid lab grade")
	local old = b.model:FindFirstChild("LabModules")
	local modules = Instance.new("Model")
	modules.Name = "LabModules"
	local origin = b.treadmill.Position
	local color = b.color:Lerp(Color3.fromRGB(192, 130, 255), (tier - 1) / 9)
	local motor = Art.part(
		modules,
		"Motor",
		Vector3.new(2.2, 1.6, 1.6),
		CFrame.new(origin + Vector3.new(-5.4, 0.8, 0)),
		metal,
		Enum.PartType.Cylinder,
		Enum.Material.Metal
	)
	motor:SetAttribute("SpinRest", motor.CFrame)
	motor:SetAttribute("SpinRate", tier)
	for j = 1, tier do
		part(
			modules,
			"GradeIndicator",
			Vector3.new(0.35, 0.15, 0.5),
			origin + Vector3.new(-4.5 + j * 1.1, 0.6, 3.1),
			color,
			Enum.Material.Neon,
			false
		)
	end
	if tier >= 2 then
		for i = 1, 5 do
			part(
				modules,
				"CoolingFin",
				Vector3.new(0.14, 1.3, 1.4),
				origin + Vector3.new(3.5 + i * 0.25, 1, -3.4),
				Color3.fromRGB(116, 155, 171),
				Enum.Material.Metal,
				false
			)
		end
	end
	if tier >= 3 then
		for _, z in ipairs({ -3.5, 3.5 }) do
			local fan = part(
				modules,
				"Turbine",
				Vector3.new(1.8, 0.15, 0.45),
				origin + Vector3.new(-3, 1.5, z),
				color,
				Enum.Material.Metal,
				false
			)
			fan:SetAttribute("SpinRest", fan.CFrame)
			fan:SetAttribute("SpinRate", 4 + tier)
		end
	end
	if tier >= 4 then
		for _, z in ipairs({ -3.1, 3.1 }) do
			local rail = part(
				modules,
				"MagneticRail",
				Vector3.new(10, 0.25, 0.4),
				origin + Vector3.new(0, 2, z),
				color,
				Enum.Material.Neon,
				false
			)
			rail:SetAttribute("NightTint", C.Elements.Wind.night)
		end
	end
	if tier >= 5 then
		local core = Art.part(
			modules,
			"PowerCore",
			Vector3.new(1.1, 1.1, 1.1),
			CFrame.new(origin + Vector3.new(4.6, 2, 0)),
			color,
			Enum.PartType.Ball,
			Enum.Material.Neon
		)
		local light = Instance.new("PointLight")
		light.Brightness = 0.8
		light.Range = 12
		light.Color = color
		light.Parent = core
		core:SetAttribute("CampPowered", true)
	end
	if tier >= 6 then
		ring(modules, "QuantumRing", origin + Vector3.new(0, 4.4, 0), 3.2, color, 20)
	end
	if tier >= 7 then
		ring(modules, "ApexRing", origin + Vector3.new(0, 5.4, 0), 2.7, C.Colors.Gold, 20)
		for _, z in ipairs({ -3.7, 3.7 }) do
			part(
				modules,
				"Stabilizer",
				Vector3.new(2, 0.3, 0.9),
				origin + Vector3.new(0, 0.3, z),
				C.Colors.Gold,
				Enum.Material.Metal,
				false
			)
		end
	end
	if old then
		old:Destroy()
	end
	modules.Parent = b.model
	b.treadmill:SetAttribute("Tier", tier)
end
function Camp.applyExpansion(b, level)
	local spec = C.Expansions[level + 1]
	assert(spec, "Invalid ranch expansion")
	local area = Instance.new("Model")
	area.Name = "PenArea"
	area:SetAttribute("Level", level)
	local center = Vector3.new(b.x, 0.2, -62 - spec.depth / 2)
	part(
		area,
		"PetPenFloor",
		Vector3.new(spec.width, 0.25, spec.depth),
		center,
		Color3.fromRGB(82, 120, 76),
		Enum.Material.Grass,
		true
	)
	local halfW, halfD = spec.width / 2, spec.depth / 2
	-- Paddocks are added as real sections; the fixed entry stays open and accessible.
	for row = 1, spec.rows do
		local z = center.Z + (row - (spec.rows + 1) / 2) * 5.5
		part(
			area,
			"Paddock" .. row,
			Vector3.new(spec.width - 2, 0.07, 5.3),
			Vector3.new(b.x, 0.37, z),
			row % 2 == 0 and Color3.fromRGB(92, 134, 81) or Color3.fromRGB(78, 118, 70),
			Enum.Material.Grass,
			true
		)
		if row > 2 then
			for _, dx in ipairs({ -halfW + 1, halfW - 1 }) do
				part(
					area,
					"PaddockCorner",
					Vector3.new(0.5, 2, 0.5),
					Vector3.new(b.x + dx, 1.2, z),
					wood,
					Enum.Material.Wood,
					true
				)
			end
		end
	end
	for _, height in ipairs({ 0.9, 2 }) do
		part(
			area,
			"BackRail",
			Vector3.new(spec.width, 0.22, 0.35),
			center + Vector3.new(0, height, -halfD),
			wood,
			Enum.Material.Wood,
			true
		)
		for _, side in ipairs({ -1, 1 }) do
			part(
				area,
				"SideRail",
				Vector3.new(0.35, 0.22, spec.depth),
				center + Vector3.new(side * halfW, height, 0),
				wood,
				Enum.Material.Wood,
				true
			)
			part(
				area,
				"FrontRail",
				Vector3.new(halfW - 3, 0.22, 0.35),
				center + Vector3.new(side * (halfW + 3) / 2, height, halfD),
				wood,
				Enum.Material.Wood,
				true
			)
		end
	end
	for _, dx in ipairs({ -halfW, -3, 3, halfW }) do
		local post = part(
			area,
			"GatePost",
			Vector3.new(0.55, 2.6, 0.55),
			Vector3.new(b.x + dx, 1.4, -62),
			wood,
			Enum.Material.Wood,
			true
		)
		if math.abs(dx) == 3 then
			local lamp = part(
				area,
				"CampLamp",
				Vector3.new(0.55, 0.55, 0.55),
				post.Position + Vector3.new(0, 1.5, 0),
				b.color,
				Enum.Material.Neon,
				false
			)
			lamp:SetAttribute("CampPowered", true)
			local light = Instance.new("PointLight")
			light.Range = 14
			light.Brightness = 0.5
			light.Color = b.color
			light.Parent = lamp
		end
	end
	local slots = {}
	for row = 0, spec.rows - 1 do
		for col = 0, spec.columns - 1 do
			table.insert(
				slots,
				center + Vector3.new((col - (spec.columns - 1) / 2) * 5.2, 1.8, (row - (spec.rows - 1) / 2) * 5.5)
			)
		end
	end
	local old = b.model:FindFirstChild("PenArea")
	if old then
		old:Destroy()
	end
	area.Parent = b.model
	b.penCenter = center
	b.penSlots = slots
	b.penBounds = Vector2.new(halfW - 2.5, halfD - 2.5)
	b.model:SetAttribute("PenCapacity", spec.capacity)
	b.model:SetAttribute("RanchLevel", level)
end
return Camp
