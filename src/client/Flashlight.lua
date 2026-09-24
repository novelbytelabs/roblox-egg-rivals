-- Free, hands-free personal flashlight: no purchase, battery, remote, or inventory mutation.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local C = require(game:GetService("ReplicatedStorage"):WaitForChild("Stage3Shared").Config)
local F = {}
F.__index = F
function F.new(parent)
	local body = Instance.new("Part")
	body.Name = "PersonalFlashlight"
	body.Size = Vector3.new(0.26, 0.28, 0.55)
	body.Anchored = true
	body.CanCollide = false
	body.CanTouch = false
	body.CanQuery = false
	body.CastShadow = false
	body.Material = Enum.Material.Metal
	body.Color = Color3.fromRGB(35, 43, 48)
	body.Transparency = 1
	body.Parent = parent
	local light = Instance.new("SpotLight")
	light.Name = "FlashlightCone"
	light.Face = Enum.NormalId.Front
	light.Angle = C.Visual.FlashlightAngle
	light.Range = C.Visual.FlashlightRange
	light.Brightness = C.Visual.FlashlightBrightness
	light.Color = Color3.fromRGB(239, 246, 255)
	light.Shadows = true
	light.Enabled = false
	light.Parent = body
	local gui = Instance.new("ScreenGui")
	gui.Name = "FlashlightHUD"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 9
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	local button = Instance.new("TextButton")
	button.Name = "FlashlightToggle"
	button.Size = UDim2.fromOffset(170, 36)
	button.AnchorPoint = Vector2.new(1, 1)
	button.Position = UDim2.new(1, -18, 1, -84)
	button.BackgroundColor3 = C.Colors.Panel
	button.BackgroundTransparency = 0.12
	button.TextColor3 = C.Colors.Text
	button.Font = Enum.Font.GothamMedium
	button.TextSize = 14
	button.Text = "[F] Flashlight: OFF"
	button.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	local self = {
		body = body,
		light = light,
		gui = gui,
		button = button,
		wanted = false,
		keyDown = false,
		focused = true,
		toggles = 0,
		connections = {},
	}
	setmetatable(self, F)
	local function connect(signal, fn)
		table.insert(self.connections, signal:Connect(fn))
	end
	connect(button.Activated, function()
		self:toggle()
	end)
	connect(UIS.InputBegan, function(input, processed)
		if input.KeyCode ~= Enum.KeyCode.F then
			return
		end
		if not processed and not self.keyDown and not UIS:GetFocusedTextBox() and not GuiService.MenuIsOpen then
			self:toggle()
		end
		self.keyDown = true
	end)
	connect(UIS.InputEnded, function(input)
		if input.KeyCode == Enum.KeyCode.F then
			self.keyDown = false
		end
	end)
	connect(UIS.WindowFocusReleased, function()
		self.focused = false
		self.keyDown = false
		self.light.Enabled = false
	end)
	connect(UIS.WindowFocused, function()
		self.focused = true
	end)
	connect(Players.LocalPlayer.CharacterAdded, function()
		self.wanted = false
		self.light.Enabled = false
	end)
	return self
end
function F:toggle()
	if GuiService.MenuIsOpen or UIS:GetFocusedTextBox() then
		return
	end
	self.wanted = not self.wanted
	self.toggles += 1
end
function F:update()
	local player = Players.LocalPlayer
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	local human = char and char:FindFirstChildOfClass("Humanoid")
	local camera = workspace.CurrentCamera
	local allowed = head
		and human
		and human.Health > 0
		and camera
		and self.focused
		and not player:GetAttribute("InDuel")
	local enabled = self.wanted and allowed and true or false
	self.light.Enabled = enabled
	self.body.Transparency = enabled and 0 or 1
	self.button.Text = "[F] Flashlight: " .. (enabled and "ON" or (self.wanted and "PAUSED" or "OFF"))
	if enabled then
		local direction = camera.CFrame.LookVector
		local desired = head.Position + camera.CFrame.RightVector * 0.55 + Vector3.new(0, -0.3, 0) + direction * 0.45
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { char, self.body.Parent }
		params.RespectCanCollide = true
		local hit = workspace:Raycast(head.Position, desired - head.Position, params)
		local origin = hit and hit.Position + hit.Normal * 0.08 or desired
		self.body.CFrame = CFrame.lookAt(origin, origin + direction)
	end
end
function F:snapshot()
	return {
		wanted = self.wanted,
		enabled = self.light.Enabled,
		toggles = self.toggles,
		range = self.light.Range,
		shadows = self.light.Shadows,
	}
end
function F:destroy()
	for _, connection in ipairs(self.connections) do
		connection:Disconnect()
	end
	self.gui:Destroy()
	self.body:Destroy()
end
return F
