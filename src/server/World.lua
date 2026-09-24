local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Stage3Shared")
local Art = require(Shared.Art)
local Config = require(Shared.Config)
local Camp = require(script.Parent.Camp)
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
	p("ForestTrail", Vector3.new(21, 0.2, 192), Vector3.new(0, 0.2, 94), sand, Enum.Material.Ground, true)
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
		local base = Camp.create(folder, i, plotColors[i])
		table.insert(bases, base)
		for _, descendant in ipairs(base.model:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant.Name == "BeltStripe" then
				table.insert(belts, descendant)
			end
		end
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
	local positions = Config.ForestNestPositions
	for i, pos in ipairs(positions) do
		local dedicated = i == Config.GodlyNestIndex
		local rarity = dedicated and "Godly" or Config.RarityOrder[(i - 1) % #Config.RarityOrder + 1]
		local creature = Config.Creatures[(i - 1) % #Config.Creatures + 1]
		local spec = Config.Rarities[rarity]
		local hints = { 100, 250, 500, 900 }
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
		local label = Art.billboard(
			platform,
			creature:upper() .. " EGG • " .. rarity:upper() .. "\nSuggested Speed " .. (hints[i] or 1200),
			spec.color,
			200,
			55,
			Vector3.new(0, 6.6, 0)
		)
		table.insert(nests, {
			id = i,
			position = pos,
			rarity = rarity,
			creature = creature,
			part = platform,
			label = label,
			event = false,
			fixedRarity = dedicated and "Godly" or nil,
			respawnDelay = dedicated and Config.GodlyNestRespawn or Config.EggRespawnTime,
		})
		if dedicated then
			nests[#nests].creature = nil -- Independent creature roll on every Godly appearance.
			platform:SetAttribute("NightEdgeColor", Config.Rarities.Godly.color)
			platform:SetAttribute("GodlyNest", true)
		end
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
	local hiddenNightSpots = {
		Vector3.new(-72, 2.4, 154),
		Vector3.new(72, 2.4, 171),
		Vector3.new(-63, 2.4, 92),
		Vector3.new(61, 2.4, 126),
		Vector3.new(0, 2.4, 181),
		Vector3.new(-49, 2.4, 43),
	}
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
	local function servicePoint(name, pos, color, title)
		local counter = p(name, Vector3.new(10, 3, 5), pos, Color3.fromRGB(84, 67, 52), Enum.Material.WoodPlanks, true)
		Art.billboard(counter, title, color, 230, 58, Vector3.new(0, 5, 0))
		return counter
	end
	local trainerShop = servicePoint(
		"TrainerWorkshop",
		Vector3.new(45, 1.5, 4),
		Config.Colors.Blue,
		"TRAINER WORKSHOP\nSpeed Lab upgrades"
	)
	local ranchShop =
		servicePoint("RanchWorks", Vector3.new(20, 1.5, 4), Config.Colors.Mint, "RANCH & PEN WORKS\nExpand your ranch")
	local exchangeShop =
		servicePoint("Exchange", Vector3.new(-20, 1.5, 4), Config.Colors.Gold, "THE EXCHANGE\nEggs • pets • items")
	local tradingPost =
		servicePoint("TradingPost", Vector3.new(-45, 1.5, 4), Config.Colors.Text, "TRADING POST\nSafe player trades")

	local trialStart = p(
		"TrialStart",
		Vector3.new(8, 0.25, 8),
		Vector3.new(-52, 0.4, 24),
		Config.Colors.Blue,
		Enum.Material.Neon,
		false
	)
	Art.billboard(trialStart, "GROVE CIRCUIT\nStart Trial", Config.Colors.Blue, 190, 48, Vector3.new(0, 3, 0))
	local trialGates = {
		Vector3.new(-52, 3, 55),
		Vector3.new(-23, 3, 93),
		Vector3.new(20, 3, 129),
		Vector3.new(52, 3, 94),
		Vector3.new(24, 3, 55),
		Vector3.new(-52, 3, 24),
	}
	for i, pos in ipairs(trialGates) do
		local gate = p("TrialGate" .. i, Vector3.new(0.5, 8, 8), pos, Config.Colors.Blue, Enum.Material.Neon, false)
		gate.Transparency = 0.7
		gate:SetAttribute("TrialGate", i)
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
		trainerShop = trainerShop,
		ranchShop = ranchShop,
		exchangeShop = exchangeShop,
		tradingPost = tradingPost,
		trialStart = trialStart,
		trialGates = trialGates,
		shrine = shrine,
		moon = moon,
		hiddenNightSpots = hiddenNightSpots,
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
