-- Original primitive-built Moonwood models. No Toolbox scripts or external meshes.
local Config = require(script.Parent.Config)
local Art = {}
local function part(parent, name, size, cf, color, shape, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.Parent = parent
	return p
end
Art.part = part
function Art.model(name, parent)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	local root = part(m, "Root", Vector3.new(0.2, 0.2, 0.2), CFrame.new(), Color3.new())
	root.Transparency = 1
	m.PrimaryPart = root
	return m
end
local function ball(m, name, size, pos, col)
	local p = part(m, name, Vector3.new(1, 1, 1), CFrame.new(pos), col)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = size
	mesh.Parent = p
	return p
end
local function ear(m, pos, col, angle)
	local p = Instance.new("WedgePart")
	p.Name = "Ear"
	p.Size = Vector3.new(0.65, 1.3, 0.7)
	p.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(angle or 0))
	p.Color = col
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Parent = m
	return p
end
function Art.egg(rarity, parent, creature)
	local col = Config.Rarities[rarity].color
	creature = creature or Config.Rarities[rarity].creature
	local m = Art.model("Egg_" .. rarity .. "_" .. creature, parent)
	ball(m, "Shell", Vector3.new(2.7, 3.4, 2.7), Vector3.new(0, 0, 0), col)
	for i = 1, 6 do
		local a = i * math.pi / 3
		ball(
			m,
			"ShellMark",
			Vector3.new(0.34, 0.48, 0.16),
			Vector3.new(math.sin(a) * 1.2, -0.25, math.cos(a) * 1.2),
			col:Lerp(Color3.new(1, 1, 1), 0.6)
		)
	end
	if creature == "Skunk" then
		ball(m, "CreatureMark", Vector3.new(0.42, 2.2, 0.18), Vector3.new(0, 0.15, -1.31), Color3.new(1, 1, 1))
	elseif creature == "Lizard" then
		for y = -1, 1 do
			ball(
				m,
				"CreatureMark",
				Vector3.new(0.38, 0.25, 0.16),
				Vector3.new(0, y * 0.7, -1.34),
				Color3.fromRGB(61, 127, 78)
			)
		end
	elseif creature == "Gorilla" then
		ball(m, "CreatureMark", Vector3.new(1.2, 0.45, 0.17), Vector3.new(0, 0.45, -1.34), Color3.fromRGB(74, 71, 72))
	elseif creature == "Dragon" then
		for _, x in ipairs({ -0.55, 0.55 }) do
			ear(m, Vector3.new(x, 1.55, -0.25), Config.Colors.Gold, x < 0 and 24 or -24)
		end
	end
	if rarity ~= "Common" then
		local crown = part(
			m,
			"Crown",
			Vector3.new(1.1, 0.18, 1.1),
			CFrame.new(0, 1.55, 0),
			Config.Colors.Gold,
			Enum.PartType.Cylinder
		)
		crown.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
	end
	return m
end

local function petEyes(m, cream, ink, y, z)
	for _, x in ipairs({ -0.43, 0.43 }) do
		ball(m, "EyeWhite", Vector3.new(0.47, 0.52, 0.18), Vector3.new(x, y, z), cream)
		ball(m, "Eye", Vector3.new(0.24, 0.31, 0.12), Vector3.new(x, y - 0.02, z - 0.12), ink)
		ball(m, "Glint", Vector3.new(0.07, 0.09, 0.06), Vector3.new(x - 0.04, y + 0.06, z - 0.19), Color3.new(1, 1, 1))
	end
end

local function addElementFlair(m, element, col, accent)
	if element == "Fire" then
		for i = -1, 1 do
			ear(m, Vector3.new(i * 0.35, 1.65 + math.abs(i) * 0.1, 0.45), accent, i * 15).Size =
				Vector3.new(0.28, 0.9, 0.55)
		end
		local glow = m:FindFirstChild("Body")
		if glow then
			local light = Instance.new("PointLight")
			light.Color = accent
			light.Brightness = 0.6
			light.Range = 8
			light.Parent = glow
		end
	elseif element == "Water" then
		for i = 1, 3 do
			ball(
				m,
				"Bubble",
				Vector3.new(0.26 + i * 0.08, 0.26 + i * 0.08, 0.26 + i * 0.08),
				Vector3.new(-0.8 + i * 0.45, 1.25 + i * 0.28, 0.55),
				accent
			)
		end
	elseif element == "Wind" then
		for _, x in ipairs({ -1, 1 }) do
			local w = ear(m, Vector3.new(x * 1.2, 0.35, 0.45), accent, x * 42)
			w.Name = "WindFin"
			w.Size = Vector3.new(0.18, 1.3, 1.5)
		end
	elseif element == "Earth" then
		for z = 0, 2 do
			ear(m, Vector3.new(0, 1.15 - z * 0.1, 0.35 + z * 0.5), accent, 0).Size = Vector3.new(0.25, 0.65, 0.5)
		end
		ball(m, "Leaf", Vector3.new(0.8, 0.2, 0.4), Vector3.new(0.2, 1.65, 0), Color3.fromRGB(91, 193, 127))
	end
end

function Art.pet(creature, rarity, element, parent)
	element = element or "Earth"
	local style = Config.Elements[element] or Config.Elements.Earth
	local bodyCol = style.color
	local accent = style.accent
	local cream = Color3.fromRGB(255, 242, 210)
	local ink = Config.Colors.Ink
	local m = Art.model(element .. " " .. creature, parent)
	if creature == "Skunk" then
		local dark = bodyCol:Lerp(Color3.fromRGB(28, 32, 35), 0.62)
		ball(m, "Body", Vector3.new(1.8, 1.45, 2.15), Vector3.new(0, 0, 0.1), dark)
		ball(m, "Face", Vector3.new(1.45, 1.25, 1.25), Vector3.new(0, 0.55, -0.85), dark)
		petEyes(m, cream, ink, 0.72, -1.43)
		ball(m, "Stripe", Vector3.new(0.42, 0.36, 1.9), Vector3.new(0, 0.72, 0.25), cream)
		local tail = ball(m, "Tail", Vector3.new(0.95, 0.95, 2.4), Vector3.new(0.35, 0.25, 1.75), dark)
		tail.CFrame *= CFrame.Angles(-0.65, 0.15, 0.1)
		ball(m, "TailStripe", Vector3.new(0.38, 0.4, 1.6), Vector3.new(0.35, 0.62, 1.9), cream)
	elseif creature == "Lizard" then
		ball(m, "Body", Vector3.new(1.7, 0.9, 2.5), Vector3.new(0, 0, 0.25), bodyCol)
		ball(m, "Face", Vector3.new(1.3, 0.85, 1.3), Vector3.new(0, 0.2, -1.15), bodyCol)
		petEyes(m, cream, ink, 0.38, -1.69)
		for _, x in ipairs({ -0.8, 0.8 }) do
			for _, z in ipairs({ -0.45, 0.75 }) do
				ball(m, "Foot", Vector3.new(0.65, 0.25, 0.55), Vector3.new(x, -0.48, z), accent)
			end
		end
		local tail = ball(m, "Tail", Vector3.new(0.48, 0.48, 3.0), Vector3.new(0, -0.05, 2.25), bodyCol)
		tail.CFrame *= CFrame.Angles(0, 0.22, 0)
	elseif creature == "Gorilla" then
		ball(m, "Body", Vector3.new(2.4, 2.0, 1.7), Vector3.new(0, 0.1, 0.15), bodyCol)
		ball(m, "Face", Vector3.new(1.55, 1.45, 1.35), Vector3.new(0, 1.1, -0.65), bodyCol:Lerp(cream, 0.18))
		ball(m, "Muzzle", Vector3.new(1.0, 0.58, 0.48), Vector3.new(0, 0.85, -1.25), accent)
		petEyes(m, cream, ink, 1.35, -1.18)
		for _, x in ipairs({ -1.45, 1.45 }) do
			ball(m, "Arm", Vector3.new(0.75, 1.65, 0.78), Vector3.new(x, -0.05, 0), bodyCol)
			ball(m, "Knuckle", Vector3.new(0.78, 0.48, 0.8), Vector3.new(x, -0.85, -0.28), accent)
		end
	else
		ball(m, "Body", Vector3.new(2.0, 1.55, 2.2), Vector3.new(0, 0, 0.1), bodyCol)
		ball(m, "Face", Vector3.new(1.55, 1.35, 1.4), Vector3.new(0, 0.65, -1.0), bodyCol)
		petEyes(m, cream, ink, 0.87, -1.58)
		for _, x in ipairs({ -1.15, 1.15 }) do
			local wing = ear(m, Vector3.new(x, 0.45, 0.25), accent, x * 34)
			wing.Name = "Wing"
			wing.Size = Vector3.new(0.24, 1.75, 1.8)
			ear(m, Vector3.new(x * 0.48, 1.65, -0.5), Config.Colors.Gold, x * -22)
		end
		local tail = ball(m, "Tail", Vector3.new(0.48, 0.48, 2.8), Vector3.new(0, 0.0, 2.0), bodyCol)
		tail.CFrame *= CFrame.Angles(0, -0.15, 0)
	end
	addElementFlair(m, element, bodyCol, accent)
	local rarityGem =
		ball(m, "RarityGem", Vector3.new(0.28, 0.28, 0.2), Vector3.new(0, 0.25, -1.7), Config.Rarities[rarity].color)
	rarityGem.Material = Enum.Material.Neon
	return m
end

function Art.guardian(parent)
	local m = Art.model("ForestGuardian", parent)
	local bark = Color3.fromRGB(107, 78, 54)
	local stone = Color3.fromRGB(133, 154, 121)
	local moss = Color3.fromRGB(66, 112, 77)
	part(m, "Torso", Vector3.new(4, 3.4, 2.6), CFrame.new(0, 0, 0), bark)
	part(m, "Breastplate", Vector3.new(3.3, 2.7, 0.5), CFrame.new(0, 0, -1.45), stone)
	part(m, "Head", Vector3.new(3, 2.3, 2.3), CFrame.new(0, 2.7, -0.15), stone)
	for _, x in ipairs({ -1, 1 }) do
		part(m, "Arm", Vector3.new(1.2, 3.4, 1.4), CFrame.new(x * 2.65, -0.1, 0) * CFrame.Angles(0, 0, x * -0.12), bark)
		ball(m, "ShoulderMoss", Vector3.new(2, 1.1, 1.9), Vector3.new(x * 2.35, 1.6, 0), moss)
		part(m, "Leg", Vector3.new(1.4, 2.3, 1.8), CFrame.new(x * 1.1, -2.6, 0), stone)
		part(
			m,
			"Eye",
			Vector3.new(0.6, 0.3, 0.15),
			CFrame.new(x * 0.68, 2.9, -1.37),
			Config.Colors.Gold,
			nil,
			Enum.Material.Neon
		)
		part(
			m,
			"Antler",
			Vector3.new(0.4, 2.3, 0.4),
			CFrame.new(x * 1.45, 4.4, 0) * CFrame.Angles(0, 0, x * -0.4),
			bark
		)
		ball(m, "AntlerLeaves", Vector3.new(1.8, 0.8, 1.4), Vector3.new(x * 1.85, 5.3, 0), moss)
	end
	local crystal = part(
		m,
		"Heart",
		Vector3.new(0.65, 0.9, 0.4),
		CFrame.new(0, 0.1, -1.8) * CFrame.Angles(0, 0, 0.5),
		Config.Colors.Mint,
		nil,
		Enum.Material.Neon
	)
	local light = Instance.new("PointLight")
	light.Color = Config.Colors.Mint
	light.Range = 12
	light.Brightness = 0.6
	light.Parent = crystal
	for _, v in ipairs(m:GetChildren()) do
		if v:IsA("BasePart") and (v.Name == "Arm" or v.Name == "Leg") then
			v:SetAttribute("RestPose", v.CFrame)
		end
	end
	return m
end
function Art.tool(name)
	local tool = Instance.new("Tool")
	tool.Name = name
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	local h = part(tool, "Handle", Vector3.new(0.38, 1.4, 0.38), CFrame.new(), Color3.fromRGB(49, 60, 63))
	if name == "Bat" then
		local bat = part(
			tool,
			"Barrel",
			Vector3.new(3.2, 0.82, 0.82),
			CFrame.new(0, 2, 0) * CFrame.Angles(0, 0, math.pi / 2),
			Color3.fromRGB(160, 102, 56),
			Enum.PartType.Cylinder,
			Enum.Material.Wood
		)
		part(tool, "Band", Vector3.new(0.85, 0.18, 0.85), CFrame.new(0, 1.2, 0), Config.Colors.Gold)
		tool.Grip = CFrame.new(0, -0.5, 0) * CFrame.Angles(math.rad(25), 0, 0)
	elseif name == "DuelBlaster" then
		part(
			tool,
			"Body",
			Vector3.new(0.85, 0.85, 2.5),
			CFrame.new(0, 0.6, -0.85),
			Color3.fromRGB(55, 98, 110),
			nil,
			Enum.Material.Metal
		)
		part(
			tool,
			"Barrel",
			Vector3.new(0.65, 0.65, 1.8),
			CFrame.new(0, 0.65, -2.5),
			Color3.fromRGB(49, 60, 63),
			nil,
			Enum.Material.Metal
		)
		part(
			tool,
			"Coil",
			Vector3.new(0.76, 0.76, 0.2),
			CFrame.new(0, 0.65, -2.8),
			Config.Colors.Blue,
			nil,
			Enum.Material.Neon
		)
		part(
			tool,
			"Sight",
			Vector3.new(0.12, 0.2, 0.3),
			CFrame.new(0, 1.13, -1.4),
			Config.Colors.Gold,
			nil,
			Enum.Material.Neon
		)
		local muzzle = Instance.new("Attachment")
		muzzle.Name = "Muzzle"
		muzzle.Position = Vector3.new(0, 0.65, -3.4)
		muzzle.Parent = h
		tool.Grip = CFrame.new(0, -0.35, 0.3)
	else
		part(
			tool,
			"Pod",
			Vector3.new(1.4, 0.4, 1.4),
			CFrame.new(0, 0.8, 0),
			Config.Colors.Mint,
			nil,
			Enum.Material.Metal
		)
	end
	for _, p in ipairs(tool:GetChildren()) do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.Massless = true
			if p ~= h then
				local w = Instance.new("WeldConstraint")
				w.Part0 = h
				w.Part1 = p
				w.Parent = p
			end
		end
	end
	return tool
end
function Art.billboard(parent, text, color, width, height, offset)
	local b = Instance.new("BillboardGui")
	b.Name = "Label"
	b.Size = UDim2.fromOffset(width or 190, height or 52)
	b.StudsOffset = offset or Vector3.new(0, 3, 0)
	b.AlwaysOnTop = false
	b.MaxDistance = 55
	b.Parent = parent
	local t = Instance.new("TextLabel")
	t.Name = "Text"
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold
	t.TextSize = 16
	t.TextColor3 = color or Config.Colors.Text
	t.TextStrokeTransparency = 0.35
	t.TextWrapped = true
	t.Text = text
	t.Parent = b
	return t
end
return Art
