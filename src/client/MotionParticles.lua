-- A bounded client-only particle solver. Existing trail instances become impact fragments.
-- Every particle is anchored, non-colliding, non-touching and non-queryable; no server physics objects.
local C = require(game:GetService("ReplicatedStorage").Stage3Shared.Config)
local Rules = require(game:GetService("ReplicatedStorage").Stage3Shared.MotionRules)
local P = {}
P.__index = P
function P.new(parent)
	local folder = Instance.new("Folder")
	folder.Name = "NeonParticlePool"
	folder.Parent = parent
	return setmetatable({
		folder = folder,
		particles = {},
		free = {},
		actors = {},
		allocated = 0,
		budget = C.Visual.HighBudget,
		rng = Random.new(),
		stats = { peak = 0, impacts = 0, reused = 0, canceled = 0, created = 0 },
		tick = 0,
	}, P)
end
function P:setBudget(budget)
	self.budget = math.clamp(math.floor(budget), 16, C.Visual.HighBudget)
end
function P:allocate()
	if #self.particles >= self.budget then
		return nil
	end
	local part = table.remove(self.free)
	if not part then
		if self.allocated >= C.Visual.HighBudget then
			return nil
		end
		part = Instance.new("Part")
		part.Name = "NeonParticle"
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = false
		part.Material = Enum.Material.Neon
		self.allocated += 1
	end
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.Transparency = 0.15
	part.Parent = self.folder
	return part
end
function P:trail(key, pos, color, now, speed)
	local count = 0
	for _, particle in ipairs(self.particles) do
		if particle.key == key and particle.mode == "Trail" then
			count += 1
		end
	end
	if count >= C.Visual.MaxTrailPerObject then
		return
	end
	local part = self:allocate()
	if not part then
		return
	end
	local scatter =
		Vector3.new(self.rng:NextNumber(-0.3, 0.3), self.rng:NextNumber(-0.5, 0.5), self.rng:NextNumber(-0.3, 0.3))
	local p = {
		part = part,
		key = key,
		pos = pos + scatter,
		color = color,
		created = now,
		life = math.clamp(0.25 + speed * 0.007, 0.35, 0.85),
		mode = "Trail",
		velocity = Vector3.new(0, 0.2, 0),
		size = self.rng:NextNumber(0.12, 0.3),
	}
	part.Position = p.pos
	part.Color = color
	table.insert(self.particles, p)
	self.stats.created += 1
end
function P:scatter(key, point, normal, now)
	local count = 0
	for _, p in ipairs(self.particles) do
		if p.key == key and p.mode == "Trail" then
			p.mode = "Converge"
			p.origin = p.pos
			p.point = point
			p.normal = normal
			p.created = now
			p.delay = count * 0.006
			p.life = C.Visual.FragmentLifetime + 0.2
			p.part.Shape = Enum.PartType.Block
			count += 1
		end
	end
	if count > 0 then
		self.stats.impacts += 1
		self.stats.reused += count
	end
	return count
end
function P:observe(key, part, color, position, velocity, grounded, now, dt, threshold, contactHint, groundOffset)
	local a = self.actors[key]
	if not a or a.part ~= part then
		a = {
			part = part,
			position = position,
			velocity = Vector3.zero,
			grounded = grounded,
			lastFastAt = -math.huge,
			lastFastVelocity = Vector3.zero,
			latched = false,
			carry = 0,
			lastSeen = now,
		}
		self.actors[key] = a
	end
	a.lastSeen = now
	local speed = velocity.Magnitude
	local night = workspace:GetAttribute("Night") == true
	local camera = workspace.CurrentCamera
	local far = camera and (camera.CFrame.Position - position).Magnitude > 150
	local warped = (position - a.position).Magnitude > math.max(20, speed * math.max(dt, 0.016) * 4 + 3)
	if not night or far or warped then
		a.lastFastAt = -math.huge
		a.position = position
		a.velocity = velocity
		a.grounded = grounded
		a.speed = speed
		return
	end
	threshold = threshold or C.Visual.TrailThreshold
	if speed >= threshold then
		a.lastFastAt = now
		a.lastFastVelocity = velocity
		a.latched = false
	end
	local contact = false
	local point, normal = position, Vector3.yAxis
	if speed <= C.Visual.StopSpeed and now - a.lastFastAt <= C.Visual.ImpactWindow then
		local world = workspace:FindFirstChild("Moonwood")
		if world then
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Include
			local targets = { world:FindFirstChild("Scenery") }
			for _, obj in ipairs(world:GetChildren()) do
				if obj:IsA("Model") and obj:GetAttribute("BaseIndex") then
					table.insert(targets, obj)
				end
			end
			params.FilterDescendantsInstances = targets
			params.RespectCanCollide = true
			local landing = (not a.grounded and grounded) or contactHint == true
			if landing then
				local hit = workspace:Raycast(
					position + Vector3.new(0, 0.15, 0),
					Vector3.new(0, -(groundOffset or 3.8), 0),
					params
				)
				if hit and a.lastFastVelocity.Y < 1 then
					contact = true
					point = hit.Position
					normal = hit.Normal
				end
			end
			if not contact and a.lastFastVelocity.Magnitude > 0.1 then
				local flat = Vector3.new(a.lastFastVelocity.X, 0, a.lastFastVelocity.Z)
				if flat.Magnitude > 0.1 then
					local hit =
						workspace:Blockcast(CFrame.new(position), Vector3.new(1.4, 1.6, 1.4), flat.Unit * 1.05, params)
					if hit then
						contact = true
						point = hit.Position
						normal = hit.Normal
					end
				end
			end
		end
	end
	if Rules.impact(a.lastFastAt > 0, a.lastFastAt, now, speed, contact, a.latched) then
		self:scatter(key, point + normal * 0.1, normal, now)
		a.latched = true
	end
	if Rules.moving(speed) then
		for _, p in ipairs(self.particles) do
			if p.key == key and p.mode == "Converge" then
				p.mode = "Fade"
				p.created = now
				p.life = 0.14
				self.stats.canceled += 1
			end
		end
	end
	if speed >= threshold then
		a.carry += math.min(dt, 0.1) * math.min(65, speed * 1.15)
		local count = math.min(6, math.floor(a.carry))
		a.carry -= count
		for i = 1, count do
			self:trail(key, a.position:Lerp(position, i / math.max(1, count)), color, now, speed)
		end
	else
		a.carry = 0
	end
	a.position = position
	a.velocity = velocity
	a.grounded = grounded
	a.speed = speed
end
function P:update(dt, now)
	dt = math.min(dt, 0.05)
	local night = workspace:GetAttribute("Night") == true
	for i = #self.particles, 1, -1 do
		local p = self.particles[i]
		local age = now - p.created
		if age >= p.life or not night or i > self.budget then
			p.part.Parent = nil
			table.insert(self.free, p.part)
			table.remove(self.particles, i)
		else
			if p.mode == "Converge" then
				local a = self.actors[p.key]
				if not a or a.speed > C.Visual.StopSpeed then
					p.mode = "Fade"
					p.created = now
					p.life = 0.14
				else
					local t = math.clamp((age - p.delay) / 0.12, 0, 1)
					p.pos = p.origin:Lerp(p.point, t)
					if t >= 1 then
						p.mode = "Fragment"
						p.created = now
						p.life = C.Visual.FragmentLifetime
						p.velocity = Vector3.new(
							self.rng:NextNumber(-9, 9),
							self.rng:NextNumber(7, 15),
							self.rng:NextNumber(-9, 9)
						) + p.normal * 4
					end
				end
			elseif p.mode == "Fragment" then
				p.velocity += Vector3.new(0, -22, 0) * dt
				p.pos += p.velocity * dt
			else
				p.pos += p.velocity * dt
			end
			local fraction = math.clamp((now - p.created) / p.life, 0, 1)
			local hue, saturation = p.color:ToHSV()
			p.part.Color = Color3.fromHSV(
				(hue + (p.mode == "Fragment" and fraction * 0.28 or fraction * 0.05)) % 1,
				math.max(0.4, saturation),
				1
			)
			local size = math.max(0.03, p.size * (1 - fraction))
			p.part.Size = p.mode == "Fragment" and Vector3.new(size, size * 1.8, size * 0.7)
				or Vector3.new(size, size, size)
			p.part.Transparency = 0.12 + fraction * 0.88
			p.part.CFrame = CFrame.new(p.pos) * CFrame.Angles(age * 9, age * 5, 0)
		end
	end
	self.stats.peak = math.max(self.stats.peak, #self.particles)
	self.tick += dt
	if self.tick >= 1 then
		self.tick = 0
		for key, a in pairs(self.actors) do
			if not a.part.Parent or now - a.lastSeen > 2 then
				self.actors[key] = nil
			end
		end
	end
end
function P:snapshot()
	local out = table.clone(self.stats)
	out.active = #self.particles
	out.allocated = self.allocated
	out.budget = self.budget
	return out
end
return P
