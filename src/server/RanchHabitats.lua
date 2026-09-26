-- Free starter activity landmarks. These are not a shop, economy or maintenance system.
local Shared = game:GetService("ReplicatedStorage").Stage3Shared
local C = require(Shared.Config)
local A = require(Shared.RanchActivityConfig)
local Art = require(Shared.Art)
local H = {}

function H.build(base, area, center, bounds)
	local sites = {}
	base.ranchLayoutSerial = (base.ranchLayoutSerial or 0) + 1
	area:SetAttribute("RanchLayoutSerial", base.ranchLayoutSerial)
	local folder = Instance.new("Folder")
	folder.Name = "RanchHabitats"
	folder.Parent = area
	local count = 0

	local function piece(parent, name, position, size, color, material, shape)
		local p = Art.part(parent, name, size, CFrame.new(position), color, shape, material)
		p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = false, false, false, false
		count += 1
		return p
	end

	local function night(part, color)
		part:SetAttribute("NightTint", color)
		return part
	end

	for index, element in ipairs(C.ElementOrder) do
		local style = C.Elements[element]
		local xSign = index % 2 == 1 and -1 or 1
		local zSign = index <= 2 and -1 or 1
		local position = center + Vector3.new(xSign * bounds.X * 0.72, 0.2, zSign * bounds.Y * 0.64)
		local model = Instance.new("Model")
		model.Name = element .. "Habitat"
		model:SetAttribute("Element", element)
		model.Parent = folder

		local anchor = piece(model, "ActivityAnchor", position, Vector3.new(0.1, 0.1, 0.1), style.color)
		anchor.Transparency = 1
		anchor:SetAttribute("RanchActivityTarget", true)
		anchor:SetAttribute("BaseIndex", base.index)
		anchor:SetAttribute("Element", element)
		local habitatLabel =
			Art.billboard(anchor, element:upper() .. " HABITAT", style.color, 150, 30, Vector3.new(0, 2.5, 0))
		habitatLabel.Parent.MaxDistance = 55
		for step = 1, 3 do
			local approach = center:Lerp(position, step / 4) + Vector3.new(0, 0.22, 0)
			piece(
				model,
				"HabitatStep",
				approach,
				Vector3.new(1.55, 0.07, 1.05),
				style.accent:Lerp(Color3.fromRGB(144, 136, 118), 0.62),
				Enum.Material.Cobblestone
			)
		end

		local patch = piece(
			model,
			"HabitatPatch",
			position,
			Vector3.new(5.2, 0.12, 4.2),
			style.accent:Lerp(Color3.fromRGB(92, 108, 82), 0.55),
			Enum.Material.Slate
		)

		if element == "Fire" then
			patch.Material = Enum.Material.Basalt
			for i = 1, 6 do
				local angle = i * math.pi / 3
				local stone = piece(
					model,
					"FireRingStone",
					position + Vector3.new(math.cos(angle) * 1.45, 0.32, math.sin(angle) * 1.45),
					Vector3.new(0.9, 0.55, 0.8),
					Color3.fromRGB(68, 58, 56),
					Enum.Material.Basalt
				)
				stone.CFrame *= CFrame.Angles(0.12, angle, 0.08)
			end
			local ember = night(
				piece(
					model,
					"EmberCore",
					position + Vector3.new(0, 0.58, 0),
					Vector3.new(1.25, 1.25, 1.25),
					style.color,
					Enum.Material.Neon,
					Enum.PartType.Ball
				),
				style.night
			)
			local light = Instance.new("PointLight")
			light.Color = style.color
			light.Range = 9
			light.Brightness = 0.7
			light.Parent = ember
		elseif element == "Water" then
			patch.Material = Enum.Material.Slate
			local pool = night(
				piece(
					model,
					"ShallowPool",
					position + Vector3.new(0, 0.13, 0),
					Vector3.new(4.4, 0.12, 3.35),
					style.color,
					Enum.Material.Glass
				),
				style.night
			)
			pool.Transparency = 0.23
			for _, offset in ipairs({
				Vector3.new(-2.05, 0.32, 0),
				Vector3.new(2.05, 0.32, 0),
				Vector3.new(0, 0.32, -1.55),
				Vector3.new(0, 0.32, 1.55),
			}) do
				piece(
					model,
					"PoolStone",
					position + offset,
					Vector3.new(0.8, 0.5, 0.8),
					Color3.fromRGB(102, 126, 132),
					Enum.Material.Slate
				)
			end
			piece(
				model,
				"FountainPedestal",
				position + Vector3.new(0, 0.55, -0.55),
				Vector3.new(0.55, 1.0, 0.55),
				style.accent,
				Enum.Material.Slate
			)
			local fountain = night(
				piece(
					model,
					"FountainGlow",
					position + Vector3.new(0, 1.22, -0.55),
					Vector3.new(0.48, 0.48, 0.48),
					style.color,
					Enum.Material.Neon,
					Enum.PartType.Ball
				),
				style.night
			)
			fountain:SetAttribute("FloatRest", fountain.Position)
			fountain:SetAttribute("FloatPhase", index)
		elseif element == "Wind" then
			patch.Material = Enum.Material.Grass
			local platform = piece(
				model,
				"WindDeck",
				position + Vector3.new(0, 0.48, -0.25),
				Vector3.new(4.2, 0.22, 2.7),
				Color3.fromRGB(131, 104, 75),
				Enum.Material.WoodPlanks
			)
			platform:SetAttribute("NightTint", style.night)
			for _, x in ipairs({ -1.65, 1.65 }) do
				for _, z in ipairs({ -1.0, 1.0 }) do
					piece(
						model,
						"PerchPost",
						position + Vector3.new(x, 0.24, z - 0.25),
						Vector3.new(0.28, 0.75, 0.28),
						Color3.fromRGB(101, 78, 58),
						Enum.Material.Wood
					)
				end
			end
			for _, x in ipairs({ -1.15, 1.15 }) do
				local streamer = night(
					piece(
						model,
						"HabitatStreamer",
						position + Vector3.new(x, 1.55, -0.9),
						Vector3.new(0.12, 2.25, 0.48),
						style.color,
						Enum.Material.Fabric
					),
					style.night
				)
				streamer:SetAttribute("SpinRest", streamer.CFrame)
				streamer:SetAttribute("SpinRate", 0.35 + math.abs(x) * 0.08)
			end
			local halo = night(
				piece(
					model,
					"WindGlow",
					position + Vector3.new(0, 1.05, 0.65),
					Vector3.new(0.55, 0.55, 0.55),
					style.accent,
					Enum.Material.Neon,
					Enum.PartType.Ball
				),
				style.night
			)
			halo:SetAttribute("FloatRest", halo.Position)
			halo:SetAttribute("FloatPhase", index + 2)
		else
			patch.Material = Enum.Material.Grass
			local log = piece(
				model,
				"RestingLog",
				position + Vector3.new(-0.5, 0.38, -0.45),
				Vector3.new(3.2, 0.65, 0.75),
				Color3.fromRGB(111, 78, 51),
				Enum.Material.Wood
			)
			log.CFrame *= CFrame.Angles(0, math.rad(14), 0)
			log:SetAttribute("NightTint", style.night)
			for _, offset in ipairs({
				Vector3.new(1.55, 0.28, 0.85),
				Vector3.new(1.05, 0.38, -1.15),
				Vector3.new(-1.65, 0.24, 1.0),
			}) do
				local rock = piece(
					model,
					"MossStone",
					position + offset,
					Vector3.new(0.9, 0.55, 0.8),
					style.accent,
					Enum.Material.Slate
				)
				rock.CFrame *= CFrame.Angles(0.08, offset.X * 0.3, 0.1)
			end
			for _, x in ipairs({ -1.1, 1.25 }) do
				piece(
					model,
					"GardenStem",
					position + Vector3.new(x, 0.65, 1.25),
					Vector3.new(0.18, 1.2, 0.18),
					Color3.fromRGB(72, 126, 72),
					Enum.Material.Grass
				)
				piece(
					model,
					"GardenLeaf",
					position + Vector3.new(x, 1.28, 1.25),
					Vector3.new(0.8, 0.2, 0.55),
					style.color,
					Enum.Material.Grass
				)
			end
		end

		sites[element] = {
			anchor = anchor,
			model = model,
			area = area,
			position = position,
			element = element,
			layout = base.ranchLayoutSerial,
		}
	end

	assert(count <= A.MaxHabitatParts, "Ranch habitat construction exceeded its fixed part budget")
	base.activitySites = sites
	base.model:SetAttribute("RanchLayoutSerial", base.ranchLayoutSerial)
	folder:SetAttribute("PartCount", count)
	return sites
end

return H
