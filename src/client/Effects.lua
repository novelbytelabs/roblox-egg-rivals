local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ContentProvider = game:GetService("ContentProvider")
local Lighting = game:GetService("Lighting")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Stage3Shared")
local Art = require(Shared.Art)
local C = require(Shared.Config)
local PetMotion = require(Shared.PetMotion)
local RanchMotion = require(Shared.RanchMotion)
local RanchAnimation = require(script.Parent.RanchAnimation)
local MotionParticles = require(script.Parent.MotionParticles)
local NightEdges = require(script.Parent.NightEdges)
local Flashlight = require(script.Parent.Flashlight)
local UIS = game:GetService("UserInputService")
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
	local self = setmetatable({
		folder = folder,
		sample = sample,
		muted = false,
		pets = {},
		petRigs = {},
		fireflies = {},
		beltLines = {},
		runTrack = nil,
		motionRigs = {},
		petMotion = {},
		ghost = nil,
		ghostFrames = nil,
		ghostStarted = 0,
		visuals = {},
		animations = {},
		selection = {},
		presentationTick = 0,
	}, E)
	self.particles = MotionParticles.new(folder)
	self.edges = NightEdges.new(folder)
	self.flashlight = Flashlight.new(folder)
	local function nightChanged()
		local night = workspace:GetAttribute("Night") == true
		TweenService:Create(Lighting, TweenInfo.new(2), {
			ClockTime = night and 0.05 or 14,
			Brightness = night and 0.65 or 2,
			Ambient = night and Color3.fromRGB(15, 18, 43) or Color3.fromRGB(111, 135, 132),
			OutdoorAmbient = night and Color3.fromRGB(24, 28, 68) or Color3.fromRGB(142, 160, 148),
		}):Play()
		local grade = Lighting:FindFirstChild("MoonwoodGrade")
		if grade then
			TweenService:Create(grade, TweenInfo.new(2), {
				Contrast = night and 0.32 or 0.07,
				Saturation = night and 0.38 or 0.06,
				TintColor = night and Color3.fromRGB(190, 205, 255) or Color3.new(1, 1, 1),
			}):Play()
		end
		local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
		if bloom then
			TweenService:Create(bloom, TweenInfo.new(2), {
				Intensity = night and C.Visual.NightBloomIntensity or 0.2,
				Size = night and C.Visual.NightBloomSize or 18,
				Threshold = night and C.Visual.NightBloomThreshold or 1.5,
			}):Play()
		end
		local world = workspace:FindFirstChild("Moonwood")
		if world then
			for _, part in ipairs(world:GetDescendants()) do
				self:registerVisual(part)
				self:nightVisual(part, night)
			end
		end
		local air = Lighting:FindFirstChild("MoonwoodAir")
		if air then
			TweenService:Create(air, TweenInfo.new(2), {
				Density = night and 0.3 or 0.24,
				Color = night and Color3.fromRGB(85, 95, 175) or Color3.fromRGB(205, 227, 211),
				Decay = night and Color3.fromRGB(35, 26, 85) or Color3.fromRGB(119, 148, 147),
			}):Play()
		end
	end
	workspace:GetAttributeChangedSignal("Night"):Connect(nightChanged)
	nightChanged()
	local world = workspace:FindFirstChild("Moonwood")
	if world then
		world.DescendantAdded:Connect(function(obj)
			task.defer(function()
				if obj.Parent then
					self:registerVisual(obj)
					self:nightVisual(obj, workspace:GetAttribute("Night") == true)
				end
			end)
		end)
	end
	UIS.InputBegan:Connect(function(input, processed)
		if processed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		local target = Players.LocalPlayer:GetMouse().Target
		if target and target:IsDescendantOf(folder) and target:GetAttribute("PetId") and self.onPetSelected then
			self.onPetSelected(target:GetAttribute("PetId"), target:GetAttribute("OwnerUserId"))
		end
	end)
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
function E:registerVisual(part)
	if not part:IsA("BasePart") then
		return
	end
	local world = workspace:FindFirstChild("Moonwood")
	local arena = world and world:FindFirstChild("MooncourtArena")
	if arena and part:IsDescendantOf(arena) then
		return
	end
	if not self.visuals[part] then
		self.visuals[part] = { color = part.Color, material = part.Material }
	end
	if part:GetAttribute("SpinRest") or part:GetAttribute("FloatRest") or part:GetAttribute("CampPowered") then
		self.animations[part] = true
	end
end
function E:nightVisual(part, night)
	local original = self.visuals[part]
	if not original or not part.Parent then
		return
	end
	local tint = part:GetAttribute("NightTint")
	local plant = part.Name:find("Fern") or part.Name:find("MushroomCap")
	part.Material = night and (typeof(tint) == "Color3" or plant) and Enum.Material.Neon or original.material
	if night and typeof(tint) == "Color3" then
		part.Color = tint
	elseif night and plant then
		part.Color = part.Name:find("Mushroom") and Color3.fromRGB(244, 60, 221) or Color3.fromRGB(82, 230, 171)
	elseif night and part.Name == "OakCrown" then
		part.Color = original.color:Lerp(Color3.fromRGB(36, 114, 107), 0.6)
	else
		part.Color = original.color
	end
end
function E:selectIncubator(element, baseIndex)
	for _, highlight in ipairs(self.selection) do
		highlight:Destroy()
	end
	self.selection = {}
	if not element then
		return
	end
	local world = workspace:FindFirstChild("Moonwood")
	local base = world and world:FindFirstChild("Base" .. tostring(baseIndex))
	if not base then
		return
	end
	for _, name in ipairs(C.ElementOrder) do
		local model = base:FindFirstChild(name .. "Sanctum")
		if model then
			local highlight = Instance.new("Highlight")
			highlight.Name = "IncubatorSelection"
			highlight.Adornee = model
			highlight.DepthMode = Enum.HighlightDepthMode.Occluded
			highlight.FillColor = name == element and C.Elements[name].color or Color3.new(0, 0, 0)
			highlight.FillTransparency = name == element and 0.8 or 0.25
			highlight.OutlineColor = C.Elements[name].accent
			highlight.OutlineTransparency = name == element and 0 or 1
			highlight.Parent = self.folder
			table.insert(self.selection, highlight)
		end
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
function E:setGhost(frames, started)
	self.ghostFrames = type(frames) == "table" and frames or nil
	self.ghostStarted = tonumber(started) or workspace:GetServerTimeNow()
	if self.ghostFrames and #self.ghostFrames > 1 then
		if not self.ghost or not self.ghost.Parent then
			self.ghost = Art.part(
				self.folder,
				"PersonalGhost",
				Vector3.new(2.4, 5, 1.5),
				CFrame.new(),
				Color3.fromRGB(110, 225, 255),
				nil,
				Enum.Material.Neon
			)
			self.ghost.Transparency = 0.62
			self.ghost.CanCollide = false
			self.ghost.CanTouch = false
			self.ghost.CanQuery = false
		end
		self.ghost.Parent = self.folder
	end
end

function E:clearGhost()
	self.ghostFrames = nil
	if self.ghost then
		self.ghost.Parent = nil
	end
end

function E:updatePresentation(dt, t, state)
	local world = workspace:FindFirstChild("Moonwood")
	if not world then
		return
	end
	local function labFor(part)
		local parent = part.Parent
		while parent and parent ~= world do
			if parent:IsA("Model") and parent:GetAttribute("BaseIndex") then
				return parent:FindFirstChild("Treadmill")
			end
			parent = parent.Parent
		end
		return nil
	end
	for part in pairs(self.animations) do
		if not part.Parent then
			self.animations[part] = nil
			self.visuals[part] = nil
		else
			local lab = labFor(part)
			local momentum = lab and lab:GetAttribute("Momentum") or 0
			local energy = lab and lab:GetAttribute("Energy") or 0
			local rest = part:GetAttribute("SpinRest")
			local floating = part:GetAttribute("FloatRest")
			if rest then
				part.CFrame = rest
					* CFrame.Angles(0, 0, t * (part:GetAttribute("SpinRate") or 1) * (0.15 + momentum * 2))
			elseif floating then
				part.Position = floating
					+ Vector3.new(0, math.sin(t * 1.8 + (part:GetAttribute("FloatPhase") or 0)) * 0.28, 0)
			end
			if part:GetAttribute("CampPowered") then
				local intensity = math.clamp(energy / 100, 0, 1)
				local original = self.visuals[part]
				part.Color = Color3.fromRGB(25, 40, 48):Lerp(original.color, 0.2 + intensity * 0.8)
				local light = part:FindFirstChildOfClass("PointLight")
				if light then
					light.Brightness = 0.15 + intensity * 2
				end
			end
		end
	end
	self.presentationTick += dt
	if self.presentationTick >= 0.4 then
		self.presentationTick = 0
		for part, original in pairs(self.visuals) do
			if not part.Parent then
				self.visuals[part] = nil
			elseif part:GetAttribute("Dormant") ~= nil then
				part.Color = part:GetAttribute("Dormant") and Color3.fromRGB(50, 44, 99) or original.color
			end
		end
		self.particles:setBudget(workspace:GetAttribute("ReducedEffects") and C.Visual.LowBudget or C.Visual.HighBudget)
	end
	local shrine = world:FindFirstChild("MoonShrine", true)
	local moon = world:FindFirstChild("MoonCrystal", true)
	local awake = shrine and shrine:GetAttribute("Awake") == true
	if moon then
		local original = self.visuals[moon]
		if original then
			moon.Color = awake and Color3.fromHSV((t * 0.035) % 1, 0.55, 1) or original.color
			moon.Transparency = awake and 0 or 0.25
		end
	end
	local clue = shrine and shrine:GetAttribute("ClueRegion")
	self.clueSparks = self.clueSparks or {}
	if typeof(clue) == "Vector3" then
		for i = 1, 12 do
			local spark = self.clueSparks[i]
			if not spark then
				spark = Art.part(
					self.folder,
					"MoonSpore",
					Vector3.new(0.17, 0.17, 0.17),
					CFrame.new(),
					C.Colors.Blue,
					Enum.PartType.Ball,
					Enum.Material.Neon
				)
				self.clueSparks[i] = spark
			end
			spark.Position = clue
				+ Vector3.new(
					math.sin(i * 3.1 + t * 0.2) * 13,
					2 + (t * 0.35 + i) % 5,
					math.cos(i * 2.1 + t * 0.2) * 13
				)
			spark.Color = Color3.fromHSV((0.57 + i * 0.013 + math.sin(t) * 0.03) % 1, 0.5, 1)
			spark.Transparency = awake and 0.2 or 1
		end
	else
		for _, spark in ipairs(self.clueSparks) do
			spark.Transparency = 1
		end
	end
	if self.runTrack and state and state.training and state.lab then
		self.runTrack:AdjustSpeed(0.85 + state.lab.momentum * 1.4)
	end
end

function E:update(dt, state, records)
	self.edges:update(dt)
	self.flashlight:update()
	local t = workspace:GetServerTimeNow()
	if self.ghost and self.ghost.Parent and self.ghostFrames and #self.ghostFrames > 1 then
		local elapsed = workspace:GetServerTimeNow() - self.ghostStarted
		local frames = self.ghostFrames
		local last = frames[#frames]
		if elapsed > last.t then
			self.ghost.Parent = nil
		else
			local a, b = frames[1], frames[2]
			for i = 2, #frames do
				if frames[i].t >= elapsed then
					a = frames[i - 1]
					b = frames[i]
					break
				end
			end
			local span = math.max(0.001, b.t - a.t)
			local alpha = math.clamp((elapsed - a.t) / span, 0, 1)
			local pos = a.position:Lerp(b.position, alpha)
			local look = a.look:Lerp(b.look, alpha)
			self.ghost.CFrame = CFrame.lookAt(pos, pos + Vector3.new(look.X, 0, look.Z))
		end
	end
	local visible = {}
	local all = records:GetChildren()
	local godlies = {}
	for _, record in ipairs(all) do
		if
			record:GetAttribute("Rarity") == "Godly"
			and record:GetAttribute("Displayed")
			and record:GetAttribute("DisplayMode") == "Pen"
			and not record:GetAttribute("Locked")
		then
			local owner = record:GetAttribute("OwnerUserId")
			local pos = record:GetAttribute("PenPosition")
			godlies[owner] = godlies[owner] or {}
			if typeof(pos) == "Vector3" then
				table.insert(godlies[owner], pos)
			end
		end
	end
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
		local grounded, landing = false, false
		local poseData
		if
			record:GetAttribute("Displayed") ~= false
			and not record:GetAttribute("Locked")
			and table.find(C.Creatures, creature)
			and C.Rarities[rarity]
			and C.Elements[element]
		then
			if mode == "Active" and root and not owner:GetAttribute("InDuel") then
				target = RanchMotion.companion(record, root, t)
			elseif mode == "Pen" then
				poseData = RanchMotion.read(record)
				if poseData then
					target, grounded, landing = RanchMotion.pose(poseData, t, godlies[ownerId])
				end
			end
		end
		if target then
			visible[record.Name] = true
			local pet = self.pets[record.Name]
			if not pet then
				pet = Art.pet(creature, rarity, element, self.folder)
				self.petRigs[record.Name] = RanchAnimation.bind(pet)
				self.edges:track(pet)
				pet:PivotTo(target)
				self.pets[record.Name] = pet
				local label = Art.billboard(
					pet.PrimaryPart,
					(species or element .. " " .. creature)
						.. " • "
						.. rarity
						.. "\n+"
						.. tostring(record:GetAttribute("Income") or 0)
						.. " Coins/min",
					C.Elements[element].color,
					200,
					42,
					Vector3.new(0, 3, 0)
				)
				label.Parent.MaxDistance = 24
				local hitbox =
					Art.part(pet, "PetInteraction", Vector3.new(3.5, 3.8, 3.5), target, C.Elements[element].color)
				hitbox.Transparency = 1
				hitbox.CanQuery = true
				hitbox:SetAttribute("PetId", record.Name)
				hitbox:SetAttribute("OwnerUserId", ownerId)
			end
			local interaction = pet:FindFirstChild("PetInteraction")
			if interaction then
				interaction:SetAttribute("OwnerUserId", ownerId)
			end
			local from = pet:GetPivot()
			local alpha = 1 - math.exp(-(mode == "Active" and 10 or 8) * dt)
			local nextCF = (from.Position - target.Position).Magnitude > 35 and target or from:Lerp(target, alpha)
			if poseData then
				if grounded and landing then
					nextCF = target
				end
				if not poseData.godly then
					local constrained = PetMotion.constrain(
						nextCF.Position,
						poseData.home,
						poseData.center,
						poseData.bounds,
						godlies[ownerId] or {},
						poseData.seed
					)
					nextCF = CFrame.new(constrained) * nextCF.Rotation
				end
			end
			pet:PivotTo(nextCF)
			local velocity = dt > 0 and (nextCF.Position - from.Position) / dt or Vector3.zero
			RanchAnimation.update(
				self.petRigs[record.Name],
				nextCF,
				t,
				record:GetAttribute("BehaviorState"),
				mode == "Active" and record:GetAttribute("CompanionActivity") or record:GetAttribute("ActivityKind"),
				velocity.Magnitude,
				record:GetAttribute("BehaviorSeed") or 1,
				rarity == "Godly"
			)
			self.particles:observe(
				"pet:" .. record.Name,
				pet.PrimaryPart,
				C.Elements[element].night,
				nextCF.Position,
				velocity,
				grounded,
				t,
				dt,
				C.Visual.PetTrailThreshold,
				landing,
				3
			)
			for _, shard in ipairs(pet:GetChildren()) do
				local rest = shard:GetAttribute("PetHaloRest")
				if rest then
					shard.CFrame = nextCF * CFrame.Angles(0, t * 0.55, 0) * rest
				end
			end
		end
	end
	for id, pet in pairs(self.pets) do
		if not visible[id] then
			pet:Destroy()
			self.pets[id] = nil
			self.petRigs[id] = nil
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
		if line.Parent then
			local base = line.Parent
			local lab = base:FindFirstChild("Treadmill")
			local momentum = lab and lab:GetAttribute("Momentum") or 0
			local drafting = lab and lab:GetAttribute("Drafting") == true
			local draftVisual = drafting and 0.18 or 0
			line.Position = Vector3.new(
				center.X - 4.5 + ((phase + t * (0.12 + momentum * 0.5 + draftVisual)) % 1) * 9,
				center.Y + 0.49,
				center.Z
			)
		end
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
	for _, owner in ipairs(Players:GetPlayers()) do
		local char = owner.Character
		local actor = char and char:FindFirstChild("HumanoidRootPart")
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if actor and humanoid and humanoid.Health > 0 and not owner:GetAttribute("InDuel") then
			self.particles:observe(
				"player:" .. owner.UserId,
				actor,
				Color3.fromRGB(75, 230, 255),
				actor.Position,
				actor.AssemblyLinearVelocity,
				humanoid.FloorMaterial ~= Enum.Material.Air,
				t,
				dt,
				C.Visual.TrailThreshold,
				false,
				4.4
			)
		end
	end
	self.particles:update(dt, t)
	self:updatePresentation(dt, t, state)
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
