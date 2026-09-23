local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ContentProvider = game:GetService("ContentProvider")
local Lighting = game:GetService("Lighting")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Stage3Shared")
local Art = require(Shared.Art)
local C = require(Shared.Config)
local E = {}
E.__index = E
function E.new()
	local folder = Instance.new("Folder")
	folder.Name = "LocalMoonwoodEffects"
	folder.Parent = workspace
	local sample = Instance.new("Sound")
	sample.SoundId = "rbxassetid://12221990"
	sample.Volume = 0.25
	sample.Parent = game:GetService("SoundService")
	task.spawn(function()
		local ok, err = pcall(function()
			ContentProvider:PreloadAsync({ sample })
		end)
		print("[STAGE3 AUDIO] pingLoaded=" .. tostring(sample.IsLoaded) .. " preload=" .. tostring(ok))
		if not ok then
			warn("[STAGE3 AUDIO] " .. tostring(err))
		end
	end)
	local self = setmetatable(
		{ folder = folder, sample = sample, muted = false, pets = {}, fireflies = {}, beltLines = {}, runTrack = nil },
		E
	)
	local function nightChanged()
		local night = workspace:GetAttribute("Night") == true
		TweenService:Create(Lighting, TweenInfo.new(2), {
			ClockTime = night and 0.2 or 14,
			Brightness = night and 1.2 or 2,
			Ambient = night and Color3.fromRGB(64, 78, 114) or Color3.fromRGB(111, 135, 132),
			OutdoorAmbient = night and Color3.fromRGB(88, 103, 138) or Color3.fromRGB(142, 160, 148),
		}):Play()
	end
	workspace:GetAttributeChangedSignal("Night"):Connect(nightChanged)
	nightChanged()
	for i = 1, 20 do
		local p = Art.part(
			folder,
			"Firefly",
			Vector3.new(0.14, 0.14, 0.14),
			CFrame.new(),
			C.Colors.Gold,
			Enum.PartType.Ball,
			Enum.Material.Neon
		)
		p.Transparency = 1
		table.insert(self.fireflies, { part = p, phase = i * 2.7, x = math.sin(i * 4.5) * 24, z = 40 + i * 6 })
	end
	return self
end
function E:sound(kind)
	if self.muted then
		return
	end
	local pitches = { tick = 1.3, pickup = 1.6, hit = 0.65, shot = 2.1, swing = 0.45, win = 1.8, night = 0.7 }
	local s = self.sample:Clone()
	s.PlaybackSpeed = pitches[kind] or 1
	s.Volume = kind == "shot" and 0.08 or 0.2
	s.Parent = game:GetService("SoundService")
	s:Play()
	Debris:AddItem(s, 4)
	if kind == "win" or kind == "night" then
		for i = 1, 2 do
			task.delay(i * 0.14, function()
				if self.muted then
					return
				end
				local note = self.sample:Clone()
				note.PlaybackSpeed = (pitches[kind] or 1) * (1 + i * 0.15)
				note.Volume = 0.12
				note.Parent = game:GetService("SoundService")
				note:Play()
				Debris:AddItem(note, 4)
			end)
		end
	end
end
function E:burst(position, color)
	for i = 1, 10 do
		local a = i * math.pi / 5
		local p = Art.part(
			self.folder,
			"Spark",
			Vector3.new(0.2, 0.2, 0.2),
			CFrame.new(position),
			color,
			Enum.PartType.Ball,
			Enum.Material.Neon
		)
		TweenService:Create(
			p,
			TweenInfo.new(0.55, Enum.EasingStyle.Quad),
			{ Position = position + Vector3.new(math.cos(a) * 3, 1 + i % 3, math.sin(a) * 3), Transparency = 1 }
		):Play()
		Debris:AddItem(p, 0.65)
	end
end
function E:effect(kind, d)
	local camera = workspace.CurrentCamera
	local pos = d.position or d.from
	if pos and camera and (camera.CFrame.Position - pos).Magnitude > 200 then
		return
	end
	if kind == "shot" then
		local len = (d.to - d.from).Magnitude
		if len > 0.01 then
			local beam = Art.part(
				self.folder,
				"BlasterPulse",
				Vector3.new(0.075, 0.075, len),
				CFrame.lookAt((d.from + d.to) / 2, d.to),
				C.Colors.Blue,
				nil,
				Enum.Material.Neon
			)
			TweenService:Create(beam, TweenInfo.new(0.12), { Transparency = 1 }):Play()
			Debris:AddItem(beam, 0.15)
			self:burst(d.to, C.Colors.Blue)
			self:sound("shot")
		end
	elseif kind == "swing" then
		if d.userId ~= Players.LocalPlayer.UserId then
			self:sound("swing")
		end
	elseif kind == "night" then
		self:sound("night")
	elseif pos then
		self:burst(pos, C.Rarities[d.rarity or "Common"].color)
	end
end
function E:update(dt, state, records)
	local t = os.clock()
	local visible = {}
	local all = records:GetChildren()
	table.sort(all, function(a, b)
		return a.Name < b.Name
	end)
	for _, record in ipairs(all) do
		local ownerId = record:GetAttribute("OwnerUserId")
		local creature = record:GetAttribute("Creature") or record:GetAttribute("Species")
		local species = record:GetAttribute("Species")
		local rarity = record:GetAttribute("Rarity")
		local element = record:GetAttribute("Element") or "Earth"
		local mode = record:GetAttribute("DisplayMode") or "Pen"
		local owner = ownerId and Players:GetPlayerByUserId(ownerId)
		local root = owner and owner.Character and owner.Character:FindFirstChild("HumanoidRootPart")
		local target
		if
			record:GetAttribute("Displayed") ~= false
			and not record:GetAttribute("Locked")
			and creature
			and C.Rarities[rarity]
			and C.Elements[element]
		then
			if mode == "Active" and root and not owner:GetAttribute("InDuel") then
				target = root.CFrame * CFrame.new(3.2, 0.35 + math.sin(t * 3) * 0.18, 5.2)
			elseif mode == "Pen" then
				local penPosition = record:GetAttribute("PenPosition")
				if typeof(penPosition) == "Vector3" then
					target = CFrame.lookAt(
						penPosition + Vector3.new(0, math.sin(t * 1.8 + #record.Name) * 0.08, 0),
						penPosition + Vector3.new(0, 0, 10)
					)
				end
			end
		end
		if target then
			visible[record.Name] = true
			local pet = self.pets[record.Name]
			if not pet then
				pet = Art.pet(creature, rarity, element, self.folder)
				pet:PivotTo(target)
				self.pets[record.Name] = pet
				Art.billboard(
					pet.PrimaryPart,
					species or (element .. " " .. creature),
					C.Elements[element].color,
					155,
					27,
					Vector3.new(0, 3, 0)
				)
			end
			local from = pet:GetPivot()
			local alpha = 1 - math.exp(-(mode == "Active" and 10 or 6) * dt)
			pet:PivotTo((from.Position - target.Position).Magnitude > 35 and target or from:Lerp(target, alpha))
		end
	end
	for id, pet in pairs(self.pets) do
		if not visible[id] then
			pet:Destroy()
			self.pets[id] = nil
		end
	end
	for _, fly in ipairs(self.fireflies) do
		fly.part.Transparency = workspace:GetAttribute("Night") and 0.2 or 1
		fly.part.Position = Vector3.new(
			fly.x + math.sin(t * 0.5 + fly.phase) * 3,
			3 + math.sin(t + fly.phase) * 1.2,
			fly.z + math.cos(t * 0.7 + fly.phase) * 2
		)
	end
	if #self.beltLines == 0 then
		local w = workspace:FindFirstChild("Moonwood")
		if w then
			for _, v in ipairs(w:GetDescendants()) do
				if v:GetAttribute("BeltPhase") then
					table.insert(self.beltLines, v)
				end
			end
		end
	end
	for _, line in ipairs(self.beltLines) do
		local center = line:GetAttribute("BeltCenter")
		local phase = line:GetAttribute("BeltPhase")
		line.Position = Vector3.new(center.X - 4.5 + ((phase + t * 0.15) % 1) * 9, center.Y + 0.49, center.Z)
	end
	local world = workspace:FindFirstChild("Moonwood")
	local live = world and world:FindFirstChild("LiveObjects")
	local guardian = live and live:FindFirstChild("ForestGuardian")
	if guardian and guardian.PrimaryPart then
		local cf = guardian:GetPivot()
		local moving = self.lastGuardian and (cf.Position - self.lastGuardian).Magnitude > 0.002
		self.lastGuardian = cf.Position
		for _, limb in ipairs(guardian:GetChildren()) do
			local rest = limb:GetAttribute("RestPose")
			if rest then
				local side = rest.Position.X > 0 and 1 or -1
				local swing = moving and math.sin(t * 9) * 0.32 * side * (limb.Name == "Arm" and -1 or 1)
					or math.sin(t * 1.4) * 0.025
				limb.CFrame = cf * rest * CFrame.Angles(swing, 0, 0)
			end
		end
	end
	local character = Players.LocalPlayer.Character
	if character ~= self.runCharacter then
		self.runCharacter = character
		self.runTrack = nil
		self.triedRun = false
	end
	if state and state.training and character then
		if not self.runTrack and not self.triedRun then
			self.triedRun = true
			local animate = character:FindFirstChild("Animate")
			local group = animate and (animate:FindFirstChild("run") or animate:FindFirstChild("walk"))
			local animation = group and group:FindFirstChildWhichIsA("Animation", true)
			local h = character:FindFirstChildOfClass("Humanoid")
			local animator = h and h:FindFirstChildOfClass("Animator")
			if animation and animator then
				local ok, track = pcall(function()
					return animator:LoadAnimation(animation)
				end)
				if ok then
					self.runTrack = track
					track.Looped = true
					track.Priority = Enum.AnimationPriority.Movement
				end
			end
		end
		if self.runTrack and not self.runTrack.IsPlaying then
			self.runTrack:Play(0.15)
		end
	elseif self.runTrack and self.runTrack.IsPlaying then
		self.runTrack:Stop(0.15)
	end
end
return E
