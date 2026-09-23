-- Server-side movement: navigation mesh plus collision-checked, retained detours.
local PathfindingService = game:GetService("PathfindingService")
local N = {}
N.__index = N
function N.new(scenery)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { scenery }
	params.RespectCanCollide = true
	return setmetatable({ params = params, lastRequest = -math.huge, pending = false, points = {}, index = 1 }, N)
end
function N:cast(from, to)
	local delta = to - from
	if delta.Magnitude < 0.01 then
		return nil
	end
	return workspace:Blockcast(CFrame.new(from), Vector3.new(4.6, 5.6, 4.6), delta, self.params)
end
function N:clear(from, to)
	return self:cast(from, to) == nil
end
function N:detour(from, goal, obstacle)
	if not obstacle or not obstacle:IsA("BasePart") then
		return nil
	end
	local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
	for _, sx in ipairs({ -1, 1 }) do
		for _, sy in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				local v = obstacle.CFrame:PointToWorldSpace(obstacle.Size * Vector3.new(sx, sy, sz) * 0.5)
				minX, maxX = math.min(minX, v.X), math.max(maxX, v.X)
				minZ, maxZ = math.min(minZ, v.Z), math.max(maxZ, v.Z)
			end
		end
	end
	local margin = 4
	local corners = {
		Vector3.new(minX - margin, from.Y, minZ - margin),
		Vector3.new(maxX + margin, from.Y, minZ - margin),
		Vector3.new(maxX + margin, from.Y, maxZ + margin),
		Vector3.new(minX - margin, from.Y, maxZ + margin),
	}
	local best, length = nil, math.huge
	for _, a in ipairs(corners) do
		if self:clear(from, a) then
			if self:clear(a, goal) then
				local cost = (from - a).Magnitude + (a - goal).Magnitude
				if cost < length then
					best, length = { a, goal }, cost
				end
			else
				for _, b in ipairs(corners) do
					if a ~= b and self:clear(a, b) and self:clear(b, goal) then
						local cost = (from - a).Magnitude + (a - b).Magnitude + (b - goal).Magnitude
						if cost < length then
							best, length = { a, b, goal }, cost
						end
					end
				end
			end
		end
	end
	return best
end
function N:request(from, to, now)
	if self.pending or now - self.lastRequest < 0.8 then
		return
	end
	self.pending, self.lastRequest = true, now
	local requestedGoal = to
	task.spawn(function()
		local path = PathfindingService:CreatePath({
			AgentRadius = 3,
			AgentHeight = 8,
			AgentCanJump = false,
			WaypointSpacing = 4,
		})
		local ok = pcall(function()
			path:ComputeAsync(from - Vector3.new(0, 3, 0), to - Vector3.new(0, 3, 0))
		end)
		self.pending = false
		if
			ok
			and path.Status == Enum.PathStatus.Success
			and self.routeGoal
			and (self.routeGoal - requestedGoal).Magnitude <= 6
			and self.index > #self.points
		then
			self.points = {}
			for _, waypoint in ipairs(path:GetWaypoints()) do
				table.insert(self.points, Vector3.new(waypoint.Position.X, from.Y, waypoint.Position.Z))
			end
			self.index = 2
		end
	end)
end
function N:advance(from, target, speed, dt, now)
	local goal = Vector3.new(target.X, from.Y, target.Z)
	if (goal - from).Magnitude < 0.15 then
		return from, nil
	end
	local block = self:cast(from, goal)
	local towards = goal
	if block then
		if not self.routeGoal or (self.routeGoal - goal).Magnitude > 6 then
			self.points, self.index, self.routeGoal = {}, 1, goal
		end
		while self.points[self.index] and (self.points[self.index] - from).Magnitude < 0.65 do
			self.index += 1
		end
		if self.index > #self.points then
			self:request(from, goal, now)
			local route = self:detour(from, goal, block.Instance)
			if route then
				self.points, self.index = route, 1
			end
		end
		towards = self.points[self.index]
		if not towards then
			return from, nil
		end
	else
		self.points, self.index, self.routeGoal = {}, 1, goal
	end
	local d = towards - from
	if d.Magnitude < 0.01 then
		return from, nil
	end
	local nextPosition = from + d.Unit * math.min(speed * math.min(dt, 0.15), d.Magnitude)
	if not self:clear(from, nextPosition) then
		self.points, self.index = {}, 1
		self:request(from, goal, now)
		return from, nil
	end
	return nextPosition, d.Unit
end
return N
