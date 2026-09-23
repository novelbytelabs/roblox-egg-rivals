local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Stage3Shared")
local Art = require(Shared.Art)
local Config = require(Shared.Config)
local W = {}
function W.build()
	assert(
		not workspace:FindFirstChild("Moonwood"),
		"Moonwood already exists. Stop the old test before starting another."
	)
	local folder = Instance.new("Folder")
	folder.Name = "Moonwood"
	folder.Parent = workspace
	local decor = Instance.new("Folder")
	decor.Name = "Scenery"
	decor.Parent = folder
	local dynamic = Instance.new("Folder")
	dynamic.Name = "LiveObjects"
	dynamic.Parent = folder
	local fx = Instance.new("Folder")
	fx.Name = "Effects"
	fx.Parent = folder
	local function p(name, size, pos, col, mat, collide, parent)
		local obj = Art.part(parent or decor, name, size, CFrame.new(pos), col, nil, mat)
		obj.CanCollide = collide == true
		obj.CanQuery = collide == true
		return obj
	end
	local grass = Color3.fromRGB(88, 130, 85)
	local wood = Color3.fromRGB(117, 78, 51)
	local sand = Color3.fromRGB(198, 180, 133)
	local stone = Color3.fromRGB(147, 157, 145)
	p("Meadow", Vector3.new(200, 4, 300), Vector3.new(0, -2, 60), grass, Enum.Material.Grass, true)
	p(
		"ForestFloor",
		Vector3.new(188, 0.15, 158),
		Vector3.new(0, 0.05, 112),
		Color3.fromRGB(61, 104, 69),
		Enum.Material.Grass,
		true
	)
	p("HubWalk", Vector3.new(155, 0.2, 21), Vector3.new(0, 0.14, -17), sand, Enum.Material.Sand, true)
	p("ForestTrail", Vector3.new(21, 0.2, 166), Vector3.new(0, 0.2, 81), sand, Enum.Material.Ground, true)
	for _, z in ipairs({ 70, 113, 150 }) do
		p("TrailBranch", Vector3.new(76, 0.2, 12), Vector3.new(0, 0.22, z), sand, Enum.Material.Ground, true)
	end
	p(
		"SafeLine",
		Vector3.new(145, 0.12, 0.8),
		Vector3.new(0, 0.25, Config.SafeBoundaryZ),
		Config.Colors.Mint,
		Enum.Material.Neon,
		false
	)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MeadowSpawn"
	spawn.Size = Vector3.new(8, 0.3, 8)
	spawn.CFrame = CFrame.lookAt(Vector3.new(0, 0.45, -4), Vector3.new(0, 0.45, 50))
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = stone
	spawn.Material = Enum.Material.Slate
	spawn.Parent = folder
	-- Architectural gates and readable world-space signage.
	for _, x in ipairs({ -13, 13 }) do
		p("GatePost", Vector3.new(2, 14, 2), Vector3.new(x, 7, 28), wood, Enum.Material.Wood, true)
		p("GateCap", Vector3.new(3, 1, 3), Vector3.new(x, 14, 28), Config.Colors.Gold, Enum.Material.Metal, false)
	end
	p("ForestArch", Vector3.new(30, 2, 3), Vector3.new(0, 13, 28), wood, Enum.Material.Wood, false)
	local sign = p("ForestSign", Vector3.new(0.2, 0.2, 0.2), Vector3.new(0, 11, 27), stone, nil, false)
	sign.Transparency = 1
	Art.billboard(sign, "MOONWOOD FOREST\nSteal. Escape. Hatch.", Config.Colors.Text, 330, 72, Vector3.new(0, 1, 0))
	local safeSign = p("SafeSign", Vector3.new(0.2, 0.2, 0.2), Vector3.new(-21, 3, 18), stone, nil, false)
	safeSign.Transparency = 1
	Art.billboard(
		safeSign,
		"MEADOW SAFE ZONE\nNo bats or snares here",
		Config.Colors.Mint,
		220,
		50,
		Vector3.new(0, 1, 0)
	)
	local bases = {}
	local belts = {}
	local plotColors = {
		Color3.fromRGB(112, 220, 183),
		Color3.fromRGB(139, 192, 249),
		Color3.fromRGB(233, 179, 127),
		Color3.fromRGB(197, 161, 235),
	}
	for i = 1, 4 do
		local x = (i - 2.5) * 42
		local c = plotColors[i]
		local m = Instance.new("Model")
		m.Name = "Base" .. i
		m.Parent = folder
		p("Deck", Vector3.new(38, 0.6, 40), Vector3.new(x, 0.3, -47), wood, Enum.Material.WoodPlanks, true, m)
		for _, side in ipairs({ -1, 1 }) do
			p(
				"CanopyPost",
				Vector3.new(0.7, 9, 0.7),
				Vector3.new(x + side * 16, 4.5, -59),
				wood,
				Enum.Material.Wood,
				true,
				m
			)
		end
		local roof = p("Canopy", Vector3.new(36, 0.45, 20), Vector3.new(x, 9.2, -50), c, Enum.Material.Fabric, false, m)
		roof.CFrame *= CFrame.Angles(0.04, 0, 0)
		local banner = p("Nameplate", Vector3.new(0.2, 0.2, 0.2), Vector3.new(x, 7, -26), stone, nil, false, m)
		banner.Transparency = 1
		local name = Art.billboard(banner, "AVAILABLE BASE", c, 240, 44, Vector3.zero)

		local treadmill = p(
			"Treadmill",
			Vector3.new(11, 0.9, 6),
			Vector3.new(x - 11, 1, -39),
			Color3.fromRGB(41, 57, 57),
			Enum.Material.Metal,
			true,
			m
		)
		treadmill:SetAttribute("Treadmill", true)
		for j = 1, 8 do
			local line = p(
				"BeltStripe",
				Vector3.new(0.16, 0.06, 5.2),
				Vector3.new(x - 16 + j * 1.2, 1.49, -39),
				c,
				Enum.Material.SmoothPlastic,
				false,
				m
			)
			line:SetAttribute("BeltCenter", treadmill.Position)
			line:SetAttribute("BeltPhase", j / 8)
			table.insert(belts, line)
		end
		for _, z in ipairs({ -42, -36 }) do
			p("TreadmillRail", Vector3.new(11, 0.25, 0.25), Vector3.new(x - 11, 3, z), c, Enum.Material.Metal, false, m)
		end
		local screen = p(
			"Console",
			Vector3.new(0.25, 1.2, 3),
			Vector3.new(x - 17, 3.1, -39),
			Color3.fromRGB(36, 93, 84),
			Enum.Material.Neon,
			false,
			m
		)
		Art.billboard(screen, "AUTO TRAIN\n+1 Speed / second", c, 180, 50, Vector3.new(0, 2, 0))

		local respawnPad = Instance.new("SpawnLocation")
		respawnPad.Name = "RespawnPad"
		respawnPad.Size = Vector3.new(7, 0.35, 7)
		respawnPad.CFrame = CFrame.lookAt(Vector3.new(x - 10, 0.55, -55), Vector3.new(x - 10, 0.55, 40))
		respawnPad.Anchored = true
		respawnPad.Neutral = true
		respawnPad.Duration = 0
		respawnPad.AllowTeamChangeOnTouch = false
		respawnPad.Color = c
		respawnPad.Material = Enum.Material.Neon
		respawnPad.Parent = m
		Art.billboard(respawnPad, "YOUR RESPAWN", c, 150, 34, Vector3.new(0, 3.2, 0))

		local incubators = {}
		local incLayout = {
			Fire = Vector3.new(x + 5, 1, -38),
			Water = Vector3.new(x + 13, 1, -38),
			Wind = Vector3.new(x + 5, 1, -50),
			Earth = Vector3.new(x + 13, 1, -50),
		}
		for _, element in ipairs(Config.ElementOrder) do
			local style = Config.Elements[element]
			local pos = incLayout[element]
			local incubator =
				p(element .. "Incubator", Vector3.new(6.5, 0.8, 6.5), pos, style.accent, Enum.Material.Metal, true, m)
			incubator:SetAttribute("Element", element)
			local ring = Art.part(
				m,
				element .. "Ring",
				Vector3.new(0.2, 6.2, 6.2),
				CFrame.new(pos + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.pi / 2),
				style.color,
				Enum.PartType.Cylinder,
				Enum.Material.Neon
			)
			local dome = Art.part(
				m,
				element .. "Dome",
				Vector3.new(5.6, 5, 5.6),
				CFrame.new(pos + Vector3.new(0, 2.8, 0)),
				style.color,
				Enum.PartType.Ball,
				Enum.Material.Glass
			)
			dome.Transparency = 0.82
			local timer = Art.billboard(
				incubator,
				element:upper() .. " INCUBATOR\nAvailable",
				style.color,
				170,
				58,
				Vector3.new(0, 5.6, 0)
			)
			incubators[element] = { element = element, pad = incubator, timer = timer, ring = ring, dome = dome }
		end

		local penCenter = Vector3.new(x, 0.2, -77)
		p(
			"PetPenFloor",
			Vector3.new(30, 0.25, 14),
			penCenter,
			Color3.fromRGB(82, 120, 76),
			Enum.Material.Grass,
			true,
			m
		)
		-- Six-stud entrance at the front; no jumping required to enter the pen.
		p(
			"PenFence",
			Vector3.new(30, 2.4, 0.35),
			penCenter + Vector3.new(0, 1.2, -7),
			wood,
			Enum.Material.Wood,
			true,
			m
		)
		for _, dx in ipairs({ -9, 9 }) do
			p(
				"PenFence",
				Vector3.new(12, 2.4, 0.35),
				penCenter + Vector3.new(dx, 1.2, 7),
				wood,
				Enum.Material.Wood,
				true,
				m
			)
		end
		for _, dx in ipairs({ -15, 15 }) do
			p(
				"PenFence",
				Vector3.new(0.35, 2.4, 14),
				penCenter + Vector3.new(dx, 1.2, 0),
				wood,
				Enum.Material.Wood,
				true,
				m
			)
		end
		local penSign =
			p("PenSign", Vector3.new(0.2, 0.2, 0.2), penCenter + Vector3.new(0, 3.2, -6), stone, nil, false, m)
		penSign.Transparency = 1
		Art.billboard(penSign, "PET PEN\nStored companions", c, 180, 46, Vector3.zero)

		local b = {
			model = m,
			x = x,
			center = Vector3.new(x, 0.5, -47),
			spawn = CFrame.lookAt(respawnPad.Position + Vector3.new(0, 3.5, 0), Vector3.new(x, 4, 40)),
			respawnPad = respawnPad,
			treadmill = treadmill,
			incubators = incubators,
			penCenter = penCenter,
			nameLabel = name,
			color = c,
			owner = nil,
		}
		table.insert(bases, b)
	end
	local shop = p("SupplyCounter", Vector3.new(9, 3, 4), Vector3.new(71, 1.5, 4), wood, Enum.Material.WoodPlanks, true)
	p(
		"ShopAwning",
		Vector3.new(12, 0.4, 8),
		Vector3.new(71, 7, 4),
		Color3.fromRGB(192, 216, 165),
		Enum.Material.Fabric,
		false
	)
	for _, x in ipairs({ 66, 76 }) do
		p("ShopPost", Vector3.new(0.5, 7, 0.5), Vector3.new(x, 3.5, 6), wood, Enum.Material.Wood, true)
	end
	Art.billboard(shop, "TRAIL SUPPLIES\nSnare pod • 15 coins", Config.Colors.Gold, 240, 64, Vector3.new(0, 6, 0))
	local nests = {}
	local positions =
		{ Vector3.new(-28, 2.4, 70), Vector3.new(28, 2.4, 70), Vector3.new(-28, 2.4, 113), Vector3.new(28, 2.4, 150) }
	for i, pos in ipairs(positions) do
		local rarity = Config.RarityOrder[i]
		local spec = Config.Rarities[rarity]
		local platform =
			p("Nest" .. i, Vector3.new(8, 1, 8), pos - Vector3.new(0, 1.8, 0), stone, Enum.Material.Slate, true)
		for j = 1, 10 do
			local a = j * math.pi / 5
			local twig = p(
				"NestTwig",
				Vector3.new(3.1, 0.25, 0.35),
				pos + Vector3.new(math.cos(a) * 2.2, -1.1, math.sin(a) * 2.2),
				wood,
				Enum.Material.Wood,
				false
			)
			twig.CFrame *= CFrame.Angles(0, -a + math.pi / 2, 0)
		end
		Art.billboard(
			platform,
			rarity:upper() .. " " .. spec.creature:upper() .. " EGG\nSuggested Speed " .. spec.hint,
			spec.color,
			200,
			55,
			Vector3.new(0, 6.6, 0)
		)
		table.insert(nests, { id = i, position = pos, rarity = rarity, part = platform, event = false })
	end
	local shrinePos = Vector3.new(42, 3, 113)
	local shrine = p(
		"MoonShrine",
		Vector3.new(10, 1.2, 10),
		shrinePos - Vector3.new(0, 2, 0),
		Color3.fromRGB(95, 100, 133),
		Enum.Material.Slate,
		true
	)
	for _, dx in ipairs({ -4, 4 }) do
		p(
			"ShrinePillar",
			Vector3.new(1.3, 9, 1.3),
			shrinePos + Vector3.new(dx, 1.5, 4),
			stone,
			Enum.Material.Slate,
			true
		)
	end
	local moon = p(
		"MoonCrystal",
		Vector3.new(1.6, 1.6, 1.6),
		shrinePos + Vector3.new(0, 6, 4),
		Config.Colors.Gold,
		Enum.Material.Neon,
		false
	)
	moon.CFrame *= CFrame.Angles(0, 0, math.pi / 4)
	Art.billboard(shrine, "MOON SHRINE\nAwakens at night", Config.Colors.Gold, 200, 60, Vector3.new(0, 9, 0))
	table.insert(nests, { id = 5, position = shrinePos, rarity = "Legendary", part = shrine, event = true })
	-- Seeded scenery avoids dropping colliders into the tested heist corridors.
	local rng = Random.new(303)
	for i = 1, 75 do
		local x = rng:NextNumber(-94, 94)
		local z = rng:NextNumber(38, 196)
		if
			math.abs(x) > 44
			or (
				math.abs(x) > 13
				and math.abs(x) < 20
				and math.abs(z - 70) > 11
				and math.abs(z - 113) > 11
				and math.abs(z - 150) > 11
			)
		then
			local h = rng:NextNumber(11, 20)
			local trunk =
				p("OakTrunk", Vector3.new(1.7, h, 1.7), Vector3.new(x, h / 2, z), wood, Enum.Material.Wood, true)
			trunk.CFrame *= CFrame.Angles(0, rng:NextNumber(0, 3), 0)
			for j = 1, 3 do
				local pos = Vector3.new(x + (j - 2) * 2.7, h + j * 1.6, z)
				local crown = Art.part(
					decor,
					"OakCrown",
					Vector3.new(10 - j, 6, 9 - j),
					CFrame.new(pos) * CFrame.Angles(0.1, j * 0.4, 0.2),
					Color3.fromRGB(52 + j * 15, 99 + j * 12, 61 + j * 8),
					Enum.PartType.Ball,
					Enum.Material.Grass
				)
				crown.CastShadow = true
			end
		end
	end
	for i = 1, 90 do
		local x = rng:NextNumber(-87, 87)
		local z = rng:NextNumber(38, 188)
		if math.abs(x) > 40 or (math.abs(x) > 13 and math.abs(x) < 20) then
			for j = 1, 3 do
				local stem = Art.part(
					decor,
					"FernFrond",
					Vector3.new(0.12, rng:NextNumber(0.6, 1.6), 0.25),
					CFrame.new(x + j * 0.22, 0.5, z) * CFrame.Angles(0, j, (-2 + j) * 0.5),
					Color3.fromRGB(104, 156, 100)
				)
				stem.CastShadow = false
			end
			if i % 4 == 0 then
				Art.part(
					decor,
					"MushroomStem",
					Vector3.new(0.2, 0.7, 0.2),
					CFrame.new(x, 0.4, z + 1),
					Color3.fromRGB(244, 225, 195)
				)
				local cap = Art.part(
					decor,
					"MushroomCap",
					Vector3.new(1, 1, 1),
					CFrame.new(x, 0.85, z + 1),
					Color3.fromRGB(216, 142, 100)
				)
				local mesh = Instance.new("SpecialMesh")
				mesh.MeshType = Enum.MeshType.Sphere
				mesh.Scale = Vector3.new(0.85, 0.35, 0.85)
				mesh.Parent = cap
			end
		end
	end
	for i = 1, 48 do
		local x = rng:NextNumber(-90, 90)
		local z = rng:NextNumber(-60, 187)
		if math.abs(x) > 79 then
			local rock = p(
				"RimRock",
				Vector3.new(6, 5, 7) * rng:NextNumber(0.7, 1.7),
				Vector3.new(x, 1, z),
				stone,
				Enum.Material.Slate,
				true
			)
			rock.CFrame *= CFrame.Angles(0.1, rng:NextNumber(0, 5), 0.3)
		end
	end
	for _, z in ipairs({ 25, 57, 93, 135, 168 }) do
		for _, x in ipairs({ -11, 11 }) do
			p("LanternPost", Vector3.new(0.3, 3.3, 0.3), Vector3.new(x, 1.6, z), wood, Enum.Material.Wood, false)
			local lamp = p(
				"Lantern",
				Vector3.new(0.75, 0.9, 0.75),
				Vector3.new(x, 3.6, z),
				Config.Colors.Gold,
				Enum.Material.Neon,
				false
			)
			local l = Instance.new("PointLight")
			l.Color = Color3.fromRGB(255, 219, 158)
			l.Brightness = 0.65
			l.Range = 14
			l.Parent = lamp
		end
	end
	local guardian = Art.guardian(dynamic)
	local home = Vector3.new(0, 4, 91)
	guardian:PivotTo(CFrame.new(home))
	local guardianLabel = Art.billboard(
		guardian.PrimaryPart,
		"THE GROVE WARDEN\nGuarding the nests",
		Config.Colors.Gold,
		260,
		66,
		Vector3.new(0, 7, 0)
	)
	-- Isolated duel courtyard: cover blocks shots; no world objects can enter.
	local arenaCenter = Vector3.new(340, 1, 80)
	local arena = Instance.new("Model")
	arena.Name = "MooncourtArena"
	arena.Parent = folder
	p(
		"ArenaFloor",
		Vector3.new(84, 2, 64),
		arenaCenter - Vector3.new(0, 1, 0),
		Color3.fromRGB(85, 107, 109),
		Enum.Material.Slate,
		true,
		arena
	)
	for _, x in ipairs({ -43, 43 }) do
		p(
			"ArenaWall",
			Vector3.new(2, 17, 66),
			arenaCenter + Vector3.new(x, 7, 0),
			Color3.fromRGB(48, 70, 73),
			Enum.Material.Slate,
			true,
			arena
		)
	end
	for _, z in ipairs({ -33, 33 }) do
		p(
			"ArenaWall",
			Vector3.new(86, 17, 2),
			arenaCenter + Vector3.new(0, 7, z),
			Color3.fromRGB(48, 70, 73),
			Enum.Material.Slate,
			true,
			arena
		)
	end
	for _, pos in ipairs({
		Vector3.new(-11, 2, -12),
		Vector3.new(11, 2, 12),
		Vector3.new(-22, 1.5, 14),
		Vector3.new(22, 1.5, -14),
	}) do
		p("ArenaCover", Vector3.new(8, pos.Y * 2, 6), arenaCenter + pos, stone, Enum.Material.Slate, true, arena)
		p(
			"CoverCap",
			Vector3.new(8.2, 0.12, 6.2),
			arenaCenter + pos + Vector3.new(0, pos.Y + 0.06, 0),
			Config.Colors.Mint,
			Enum.Material.Neon,
			false,
			arena
		)
	end
	for _, x in ipairs({ -39, 39 }) do
		for _, z in ipairs({ -29, 29 }) do
			p(
				"ArenaColumn",
				Vector3.new(2, 18, 2),
				arenaCenter + Vector3.new(x, 8, z),
				stone,
				Enum.Material.Slate,
				true,
				arena
			)
			local lamp = p(
				"ArenaLight",
				Vector3.new(2.5, 0.6, 2.5),
				arenaCenter + Vector3.new(x, 17, z),
				Config.Colors.Gold,
				Enum.Material.Neon,
				false,
				arena
			)
			local light = Instance.new("PointLight")
			light.Range = 45
			light.Brightness = 2
			light.Color = Color3.fromRGB(220, 237, 227)
			light.Parent = lamp
		end
	end
	p(
		"ArenaMidline",
		Vector3.new(0.15, 0.05, 62),
		arenaCenter + Vector3.new(0, 0.1, 0),
		Config.Colors.Mint,
		Enum.Material.Neon,
		false,
		arena
	)
	local lighting = game:GetService("Lighting")
	lighting.ClockTime = 14
	lighting.Brightness = 2
	lighting.Ambient = Color3.fromRGB(111, 135, 132)
	lighting.OutdoorAmbient = Color3.fromRGB(142, 160, 148)
	lighting.GlobalShadows = true
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "MoonwoodAir"
	atmosphere.Density = 0.24
	atmosphere.Color = Color3.fromRGB(205, 227, 211)
	atmosphere.Decay = Color3.fromRGB(119, 148, 147)
	atmosphere.Haze = 1
	atmosphere.Parent = lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.2
	bloom.Size = 18
	bloom.Threshold = 1.5
	bloom.Parent = lighting
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "MoonwoodGrade"
	grade.Contrast = 0.07
	grade.Saturation = 0.06
	grade.Parent = lighting
	return {
		folder = folder,
		decor = decor,
		dynamic = dynamic,
		fx = fx,
		bases = bases,
		belts = belts,
		nests = nests,
		spawn = spawn,
		shop = shop,
		guardian = guardian,
		guardianHome = home,
		guardianLabel = guardianLabel,
		arena = arena,
		arenaCenter = arenaCenter,
		arenaA = arenaCenter + Vector3.new(-30, 4, 0),
		arenaB = arenaCenter + Vector3.new(30, 4, 0),
	}
end
return W
