-- Shape-aware, local-space luminous contours. Smooth primitives use curved contours,
-- not misleading box outlines. Imported arbitrary meshes are explicitly unsupported.
local G = {}
function G.build(part)
	local mesh = part:FindFirstChildOfClass("SpecialMesh")
	local size = part.Size
	local offset = Vector3.zero
	local shape = part:IsA("Part") and part.Shape or nil
	if mesh then
		size *= mesh.Scale
		offset = mesh.Offset
		if mesh.MeshType == Enum.MeshType.Sphere then
			shape = Enum.PartType.Ball
		elseif mesh.MeshType ~= Enum.MeshType.Brick then
			return nil, "unsupported-mesh"
		end
	end
	if part:IsA("MeshPart") or part:IsA("UnionOperation") then
		return nil, "unsupported-mesh"
	end
	local h = size / 2
	local strokes = {}
	local function line(a, b)
		table.insert(strokes, { a = a + offset, b = b + offset })
	end
	local function ellipse(center, u, v)
		local normal = u:Cross(v).Unit
		local k = 4 / 3 * math.tan(math.pi / 8)
		for i = 0, 3 do
			local a, b = i * math.pi / 2, (i + 1) * math.pi / 2
			local ta = -u * math.sin(a) + v * math.cos(a)
			local tb = -u * math.sin(b) + v * math.cos(b)
			table.insert(strokes, {
				a = center + u * math.cos(a) + v * math.sin(a) + offset,
				b = center + u * math.cos(b) + v * math.sin(b) + offset,
				ta = ta.Unit,
				tb = tb.Unit,
				normal = normal,
				c0 = k * ta.Magnitude,
				c1 = k * tb.Magnitude,
			})
		end
	end
	if shape == Enum.PartType.Ball then
		ellipse(Vector3.zero, Vector3.new(h.X, 0, 0), Vector3.new(0, h.Y, 0))
		ellipse(Vector3.zero, Vector3.new(h.X, 0, 0), Vector3.new(0, 0, h.Z))
		ellipse(Vector3.zero, Vector3.new(0, h.Y, 0), Vector3.new(0, 0, h.Z))
		return strokes, "ellipsoid-contours"
	elseif shape == Enum.PartType.Cylinder then
		for _, x in ipairs({ -h.X, h.X }) do
			ellipse(Vector3.new(x, 0, 0), Vector3.new(0, h.Y, 0), Vector3.new(0, 0, h.Z))
		end
		for i = 0, 3 do
			local a = i * math.pi / 2
			line(
				Vector3.new(-h.X, h.Y * math.cos(a), h.Z * math.sin(a)),
				Vector3.new(h.X, h.Y * math.cos(a), h.Z * math.sin(a))
			)
		end
		return strokes, "cylinder-rims"
	elseif part:IsA("WedgePart") then
		local v = {
			Vector3.new(-h.X, -h.Y, -h.Z),
			Vector3.new(h.X, -h.Y, -h.Z),
			Vector3.new(-h.X, -h.Y, h.Z),
			Vector3.new(h.X, -h.Y, h.Z),
			Vector3.new(-h.X, h.Y, h.Z),
			Vector3.new(h.X, h.Y, h.Z),
		}
		for _, edge in ipairs({
			{ 1, 2 },
			{ 1, 3 },
			{ 2, 4 },
			{ 3, 4 },
			{ 3, 5 },
			{ 4, 6 },
			{ 5, 6 },
			{ 1, 5 },
			{ 2, 6 },
		}) do
			line(v[edge[1]], v[edge[2]])
		end
		return strokes, "wedge-edges"
	elseif shape == Enum.PartType.Block or part:IsA("SpawnLocation") then
		for _, y in ipairs({ -h.Y, h.Y }) do
			for _, z in ipairs({ -h.Z, h.Z }) do
				line(Vector3.new(-h.X, y, z), Vector3.new(h.X, y, z))
			end
		end
		for _, x in ipairs({ -h.X, h.X }) do
			for _, z in ipairs({ -h.Z, h.Z }) do
				line(Vector3.new(x, -h.Y, z), Vector3.new(x, h.Y, z))
			end
			for _, y in ipairs({ -h.Y, h.Y }) do
				line(Vector3.new(x, y, -h.Z), Vector3.new(x, y, h.Z))
			end
		end
		return strokes, "box-edges"
	end
	return nil, "unsupported-shape"
end
return G
