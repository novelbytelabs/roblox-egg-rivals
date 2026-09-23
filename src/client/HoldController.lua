-- One client input controller. The server owns timing, identity and final eligibility.
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local H = {}
H.__index = H
function H.new(send)
	local self = setmetatable({ send = send, active = nil, focused = true, completed = 0, canceled = 0 }, H)
	UIS.InputEnded:Connect(function(input)
		local a = self.active
		if
			a
			and (
				(a.inputType ~= Enum.UserInputType.Keyboard and input.UserInputType == a.inputType)
				or (a.inputType == Enum.UserInputType.Keyboard and input.KeyCode == a.key)
			)
		then
			self:cancel()
		end
	end)
	UIS.WindowFocusReleased:Connect(function()
		self.focused = false
		self:cancel()
	end)
	UIS.WindowFocused:Connect(function()
		self.focused = true
	end)
	return self
end
function H:cancel()
	local a = self.active
	if not a then
		return
	end
	self.active = nil
	self.canceled += 1
	self.send("holdCancel", { nonce = a.nonce })
	if a.button and a.button.Parent then
		a.button:SetAttribute("HoldProgress", nil)
	end
end
function H:start(spec, input)
	if self.active then
		self:cancel()
	end
	if not self.focused or not spec.valid() or GuiService.MenuIsOpen or UIS:GetFocusedTextBox() then
		return false
	end
	local args = spec.args()
	if not args then
		return false
	end
	local nonce = HttpService:GenerateGUID(false)
	args.nonce = nonce
	self.active = {
		kind = spec.kind,
		button = spec.button,
		nonce = nonce,
		spec = spec,
		inputType = input.UserInputType,
		key = input.KeyCode,
		context = spec.context(),
		requested = os.clock(),
	}
	self.send(spec.beginName, args)
	return true
end
function H:bind(spec)
	spec.button.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			self:start(spec, input)
		end
	end)
	return spec
end
function H:ack(kind, data)
	local a = self.active
	if not a or a.kind ~= kind or a.nonce ~= data.nonce or not a.spec.valid() or a.context ~= a.spec.context() then
		if data.nonce then
			self.send("holdCancel", { nonce = data.nonce })
		end
		return false
	end
	a.receipt = data
	return true
end
function H:step()
	local a = self.active
	if not a then
		return
	end
	if
		not a.spec.valid()
		or a.context ~= a.spec.context()
		or GuiService.MenuIsOpen
		or not self.focused
		or UIS:GetFocusedTextBox()
		or os.clock() - a.requested > 12
	then
		self:cancel()
		return
	end
	local d = a.receipt
	if not d then
		a.button.Text = "CONNECTING CONFIRMATION…"
		return
	end
	local elapsed = workspace:GetServerTimeNow() - d.started
	local progress = math.clamp(elapsed / d.duration, 0, 1)
	a.button:SetAttribute("HoldProgress", progress)
	a.button.Text = string.format("KEEP HOLDING • %.1fs", math.max(0, d.duration - elapsed))
	if elapsed >= d.duration + 0.04 then
		self.active = nil
		self.completed += 1
		a.button:SetAttribute("HoldProgress", nil)
		self.send(a.spec.completeName, a.spec.complete(d))
		a.button.Text = "CHECKING EXACT SELECTION…"
	end
end
return H
