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
		count = count + 1
		return p
	end
	for index, element in ipairs(C.ElementOrder) do
		local style = C.Elements[element]
		local xSign = index % 2 == 1 and -1 or 1
		local zSign = index <= 2 and -1 or 1
		local position = center + Vector3.new(xSign * bounds.X * 0.62, 0.2, zSign * bounds.Y * 0.52)
		local model = Instance.new("Model")
		model.Name = element .. "Habitat"
		model:SetAttribute("Element", element)
		model.Parent = folder
		local anchor = piece(model, "ActivityAnchor", position, Vector3.new(0.1, 0.1, 0.1), style.color)
		anchor.Transparency = 1
		anchor:SetAttribute("RanchActivityTarget", true)
		anchor:SetAttribute("BaseIndex", base.index)
		anchor:SetAttribute("Element", element)
		local ground =
			piece(model, "HabitatPatch", position, Vector3.new(3, 0.12, 2.4), style.accent, Enum.Material.Slate)
		if element == "Fire" then
			ground.Material = Enum.Material.Basalt
			for sign = -1, 1, 2 do
				local ember = piece(
					model,
					"EmberStone",
					position + Vector3.new(sign * 0.65, 0.25, 0),
					Vector3.new(0.65, 0.35, 0.7),
					style.color,
					Enum.Material.Neon
				)
				ember:SetAttribute("NightTint", style.night)
			end
		elseif element == "Water" then
			local pool = piece(
				model,
				"ShallowPool",
				position + Vector3.new(0, 0.12, 0),
				Vector3.new(2.5, 0.1, 1.9),
				style.color,
				Enum.Material.Glass
			)
			pool.Transparency = 0.25
			pool:SetAttribute("NightTint", style.night)
		elseif element == "Wind" then
			local perch = piece(
				model,
				"AiryPerch",
				position + Vector3.new(0, 0.45, -0.55),
				Vector3.new(2.4, 0.2, 0.45),
				style.accent,
				Enum.Material.Wood
			)
			perch:SetAttribute("NightTint", style.night)
			local vane = piece(
				model,
				"HabitatStreamer",
				position + Vector3.new(1, 1.3, -0.7),
				Vector3.new(0.1, 1.5, 0.4),
				style.color,
				Enum.Material.Fabric
			)
			vane:SetAttribute("SpinRest", vane.CFrame)
			vane:SetAttribute("SpinRate", 0.45)
		else
			ground.Material = Enum.Material.Grass
			local log = piece(
				model,
				"RestingLog",
				position + Vector3.new(0, 0.3, -0.45),
				Vector3.new(2.4, 0.5, 0.55),
				Color3.fromRGB(111, 78, 51),
				Enum.Material.Wood
			)
			log:SetAttribute("NightTint", style.night)
			piece(
				model,
				"MossStone",
				position + Vector3.new(0.85, 0.2, 0.5),
				Vector3.new(0.6, 0.3, 0.6),
				style.color,
				Enum.Material.Grass
			)
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
