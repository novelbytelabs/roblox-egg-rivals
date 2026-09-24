-- Client-only self-lit Beam edges. Attachments follow their source objects without
-- per-edge physics parts or per-object frame connections. No through-wall outlines.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Stage3Shared")
local C = require(Shared.Config)
local Geometry = require(Shared.NightGeometry)
local N = {}
N.__index = N
function N.new(parent)
	local folder = Instance.new("Folder")
	folder.Name = "NightEdgeLights"
	folder.Parent = parent
	return setmetatable(
		{ folder = folder, records = {}, roots = {}, tick = 0, rendered = 0, unsupported = 0, budgetCulled = 0 },
		N
	)
end
function N:track(root)
	if self.roots[root] then
		return
	end
	local function register(part)
		if part:IsA("BasePart") and not part:IsA("Terrain") and not self.records[part] then
			local ancestor = part
			while ancestor and ancestor ~= root.Parent do
				if ancestor.Name == "MooncourtArena" or ancestor:GetAttribute("NightEdgeExcluded") then
					return
				end
				ancestor = ancestor.Parent
			end
			self.records[part] = {}
		end
	end
	for _, part in ipairs(root:GetDescendants()) do
		register(part)
	end
	self.roots[root] = root.DescendantAdded:Connect(register)
end
function N:release(record)
	if record.folder then
		record.folder:Destroy()
		for _, a in ipairs(record.attachments) do
			a:Destroy()
		end
		self.rendered -= 1
	end
	record.folder = nil
	record.attachments = nil
	record.beams = nil
	record.signature = nil
end
local function signature(part)
	local mesh = part:FindFirstChildOfClass("SpecialMesh")
	return tostring(part.Size)
		.. ":"
		.. tostring(part:IsA("Part") and part.Shape)
		.. ":"
		.. (mesh and (tostring(mesh.MeshType) .. tostring(mesh.Scale) .. tostring(mesh.Offset)) or "")
end
local function colorFor(part)
	local obj = part
	while obj and obj ~= workspace do
		local tint = obj:GetAttribute("NightEdgeColor") or obj:GetAttribute("NightTint")
		if typeof(tint) == "Color3" then
			return tint
		end
		local element = obj:GetAttribute("Element")
		if C.Elements[element] then
			return C.Elements[element].night
		end
		obj = obj.Parent
	end
	local hue, saturation = part.Color:ToHSV()
	return Color3.fromHSV(hue, math.max(0.5, saturation), 1)
end
function N:build(part, record)
	local strokes, kind = Geometry.build(part)
	record.kind = kind
	if not strokes then
		record.unsupported = true
		record.unsupportedSignature = signature(part)
		return false
	end
	record.unsupported = nil
	local folder = Instance.new("Folder")
	folder.Name = "Edges_" .. part.Name
	folder.Parent = self.folder
	record.folder = folder
	record.attachments = {}
	record.beams = {}
	local memo = {}
	local function attachment(pos, right, normal)
		local key = tostring(pos) .. ":" .. tostring(right)
		if memo[key] then
			return memo[key]
		end
		local a = Instance.new("Attachment")
		a.Name = "NightEdgeAnchor"
		a.CFrame = right and CFrame.fromMatrix(pos, right, normal, right:Cross(normal)) or CFrame.new(pos)
		a.Parent = part
		table.insert(record.attachments, a)
		memo[key] = a
		return a
	end
	local color = ColorSequence.new(colorFor(part))
	for _, s in ipairs(strokes) do
		local beam = Instance.new("Beam")
		beam.Name = "NeonEdge"
		beam.Attachment0 = attachment(s.a, s.ta, s.normal)
		beam.Attachment1 = attachment(s.b, s.tb, s.normal)
		beam.Width0 = C.Visual.EdgeWidth
		beam.Width1 = C.Visual.EdgeWidth
		beam.Color = color
		beam.LightEmission = 1
		beam.LightInfluence = 0
		beam.Brightness = C.Visual.EdgeBrightness
		beam.Transparency = NumberSequence.new(0.16)
		beam.FaceCamera = true
		beam.Segments = s.c0 and 8 or 1
		beam.CurveSize0 = s.c0 or 0
		beam.CurveSize1 = s.c1 or 0
		beam.Enabled = workspace:GetAttribute("Night") == true
		beam.Parent = folder
		table.insert(record.beams, beam)
	end
	record.signature = signature(part)
	record.enabled = workspace:GetAttribute("Night") == true
	self.rendered += 1
	return true
end
function N:update(dt)
	self.tick += dt
	if self.tick < C.Visual.EdgeUpdateInterval then
		return
	end
	self.tick = 0
	local world = workspace:FindFirstChild("Moonwood")
	if world then
		self:track(world)
	end
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local night = workspace:GetAttribute("Night") == true
	local pending = {}
	local unsupported = 0
	for part, record in pairs(self.records) do
		if not part:IsDescendantOf(workspace) then
			self:release(record)
			self.records[part] = nil
		else
			if record.unsupported and signature(part) ~= record.unsupportedSignature then
				record.unsupported = nil
			end
			local distance = (part.Position - camera.CFrame.Position).Magnitude - part.Size.Magnitude / 2
			local visible = part.Transparency < 0.98
				and part.LocalTransparencyModifier < 0.98
				and not part:GetAttribute("NightEdgeExcluded")
			if not visible or distance > C.Visual.EdgeDistance + 24 then
				self:release(record)
			elseif record.folder and signature(part) ~= record.signature then
				self:release(record)
			end
			if record.folder then
				if record.enabled ~= night then
					for _, beam in ipairs(record.beams) do
						beam.Enabled = night
					end
					record.enabled = night
				end
			elseif visible and distance <= C.Visual.EdgeDistance then
				if record.unsupported then
					unsupported += 1
				else
					table.insert(pending, { part = part, record = record, distance = distance })
				end
			end
		end
	end
	table.sort(pending, function(a, b)
		return a.distance < b.distance
	end)
	local created = 0
	for _, entry in ipairs(pending) do
		if created >= C.Visual.EdgeBuildPerTick or self.rendered >= C.Visual.EdgePartBudget then
			break
		end
		if self:build(entry.part, entry.record) then
			created += 1
		end
	end
	self.pending = math.max(0, #pending - created)
	self.unsupported = unsupported
	self.budgetCulled = self.rendered >= C.Visual.EdgePartBudget and math.max(0, #pending - created) or 0
	for root, connection in pairs(self.roots) do
		if not root:IsDescendantOf(workspace) then
			connection:Disconnect()
			self.roots[root] = nil
		end
	end
end
function N:snapshot()
	local tracked, beams, enabled = 0, 0, 0
	for _, record in pairs(self.records) do
		tracked += 1
		if record.beams then
			beams += #record.beams
			if record.enabled then
				enabled += #record.beams
			end
		end
	end
	return {
		tracked = tracked,
		rendered = self.rendered,
		beams = beams,
		enabled = enabled,
		unsupported = self.unsupported,
		budgetCulled = self.budgetCulled,
		pending = self.pending or 0,
	}
end
function N:destroy()
	for _, connection in pairs(self.roots) do
		connection:Disconnect()
	end
	for _, record in pairs(self.records) do
		self:release(record)
	end
	self.records = {}
	self.roots = {}
	self.folder:Destroy()
end
return N
