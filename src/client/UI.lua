local TweenService = game:GetService("TweenService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Stage3Shared")
local C = require(Shared.Config)
local Art = require(Shared.Art)
local U = {}
function U.corner(obj, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 12)
	c.Parent = obj
end
function U.frame(parent, name, x, y, w, h, color)
	local f = Instance.new("Frame")
	f.Name = name
	f.Position = UDim2.fromOffset(x, y)
	f.Size = UDim2.fromOffset(w, h)
	f.BackgroundColor3 = color or C.Colors.Panel
	f.BorderSizePixel = 0
	f.Parent = parent
	U.corner(f, 12)
	return f
end
function U.text(parent, name, text, x, y, w, h, size, color)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Text = text
	l.Position = UDim2.fromOffset(x, y)
	l.Size = UDim2.fromOffset(w, h)
	l.TextSize = size or 18
	l.Font = Enum.Font.GothamMedium
	l.TextColor3 = color or C.Colors.Text
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.BackgroundTransparency = 1
	l.TextWrapped = true
	l.Parent = parent
	return l
end
function U.button(parent, name, text, x, y, w, h, callback, color)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Text = text
	b.Position = UDim2.fromOffset(x, y)
	b.Size = UDim2.fromOffset(w, h)
	b.BackgroundColor3 = color or C.Colors.Mint
	b.TextColor3 = C.Colors.Ink
	b.Font = Enum.Font.GothamBold
	b.TextSize = 16
	b.BorderSizePixel = 0
	b.AutoButtonColor = true
	b.Parent = parent
	U.corner(b, 9)
	b.Activated:Connect(callback)
	return b
end
function U.preview(parent, item, x, y, w, h)
	local v = Instance.new("ViewportFrame")
	v.Name = "ItemView"
	v.Size = UDim2.fromOffset(w, h)
	v.Position = UDim2.fromOffset(x, y)
	v.BackgroundTransparency = 1
	v.Ambient = Color3.fromRGB(200, 210, 211)
	v.LightColor = Color3.new(1, 1, 1)
	v.LightDirection = Vector3.new(-1, -1, -1)
	v.Parent = parent
	local world = Instance.new("WorldModel")
	world.Parent = v
	local m
	if item.kind == "Item" then
		m = Art.model(item.species or item.itemType, world)
		local tool = Art.tool(item.itemType)
		for _, child in ipairs(tool:GetChildren()) do
			if child:IsA("BasePart") then
				child.Anchored = true
				child.CanCollide = false
				child.Parent = m
			end
		end
		tool:Destroy()
	elseif item.kind == "Pet" then
		m = Art.pet(item.creature, item.rarity, item.element, world)
	else
		m = Art.egg(item.rarity, world, item.creature)
	end
	m:PivotTo(CFrame.new())
	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.lookAt(Vector3.new(3.5, 2, -6), Vector3.new(0, 0.5, 0))
	camera.FieldOfView = 38
	camera.Parent = v
	v.CurrentCamera = camera
	return v
end
function U.card(parent, item, callback, selected)
	local col = C.Rarities[item.rarity].color
	local card = Instance.new("TextButton")
	card.Name = "Item_" .. item.id
	card.Size = UDim2.fromOffset(158, 184)
	card.BackgroundColor3 = selected and Color3.fromRGB(51, 86, 77) or C.Colors.Ink
	card.Text = ""
	card.BorderSizePixel = 0
	card.Parent = parent
	U.corner(card)
	local stroke = Instance.new("UIStroke")
	stroke.Color = selected and C.Colors.Mint or col
	stroke.Thickness = selected and 3 or 1
	stroke.Transparency = 0.25
	stroke.Parent = card
	U.preview(card, item, 6, 3, 146, 112)
	U.text(
		card,
		"Name",
		item.kind == "Egg" and item.rarity .. " " .. (item.creature or "Creature") .. " Egg" or item.species,
		9,
		112,
		140,
		28,
		15
	)
	U.text(
		card,
		"Rarity",
		(item.kind == "Pet" and ((item.element or "Earth"):upper() .. " • ") or "")
			.. item.rarity:upper()
			.. " • "
			.. item.kind,
		9,
		142,
		140,
		20,
		11,
		col
	)
	U.text(
		card,
		"State",
		item.locked and "LOCKED • FAVORITE"
			or item.state == "Inventory" and (item.kind == "Pet" and ((item.petMode or "Pen"):upper() .. " • +" .. tostring(
				item.income or C.Rarities[item.rarity].income
			) .. " / min") or (item.kind == "Item" and "Consumable • tradable" or "Choose an element"))
			or item.state,
		9,
		163,
		140,
		17,
		11,
		C.Colors.Muted
	)
	card.Activated:Connect(function()
		callback(item)
	end)
	return card
end
function U.grid(parent, name, x, y, w, h)
	local s = Instance.new("ScrollingFrame")
	s.Name = name
	s.Position = UDim2.fromOffset(x, y)
	s.Size = UDim2.fromOffset(w, h)
	s.BackgroundTransparency = 1
	s.BorderSizePixel = 0
	s.ScrollBarThickness = 5
	s.ScrollBarImageColor3 = C.Colors.Mint
	s.AutomaticCanvasSize = Enum.AutomaticSize.Y
	s.CanvasSize = UDim2.new()
	s.Parent = parent
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(158, 184)
	layout.CellPadding = UDim2.fromOffset(16, 16)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = s
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingLeft = UDim.new(0, 4)
	pad.Parent = s
	return s
end
function U.clearGrid(grid)
	for _, v in ipairs(grid:GetChildren()) do
		if v:IsA("GuiObject") then
			v:Destroy()
		end
	end
end
return U
