-- Read-only observations of actual replicated records and rendered pets in Studio tests.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Shared = ReplicatedStorage:WaitForChild("Stage3Shared")
local C = require(Shared.Config)
local R = require(Shared.Rules)
local A = require(Shared.RanchActivityConfig)
local Motion = require(Shared.RanchMotion)
local ClientChecks = {}

function ClientChecks.bind(effects)
	if not RunService:IsStudio() or workspace:GetAttribute("Stage3AutoTest") ~= true then
		return nil
	end
	local net = ReplicatedStorage:WaitForChild("Stage3Net")
	local diagnostics = net:WaitForChild("ClientDiagnostics")
	local records = net:WaitForChild("PetRecords")
	local running = false
	return net.Feed.OnClientEvent:Connect(function(kind, data)
		if kind ~= "ranchActivityProbe" or running or type(data) ~= "table" or type(data.token) ~= "string" then
			return
		end
		running = true
		task.spawn(function()
			local out = { token = data.token, samples = 0, moved = false, limbMoved = false, observed = 0 }
			local ok, err = xpcall(function()
				assert(type(data.ids) == "table" and #data.ids >= 2 and #data.ids <= 24)
				local deadline = os.clock() + 5
				local ready = false
				repeat
					ready = true
					for _, id in ipairs(data.ids) do
						local record, model = records:FindFirstChild(id), effects.pets[id]
						ready = ready and record ~= nil and model ~= nil and model.Parent ~= nil
					end
					if not ready then
						task.wait(0.05)
					end
				until ready or os.clock() >= deadline
				assert(ready, "Displayed activity pets were not rendered")
				local ownerId = records:FindFirstChild(data.ids[1]):GetAttribute("OwnerUserId")
				local owner = assert(Players:GetPlayerByUserId(ownerId))
				local world = assert(workspace:FindFirstChild("Moonwood"))
				local base = assert(world:FindFirstChild("Base" .. tostring(owner:GetAttribute("BaseIndex"))))
				local area = assert(base:FindFirstChild("PenArea"))
				local habitats = assert(area:FindFirstChild("RanchHabitats"), "Real habitat props are missing")
				local parts = 0
				for _, element in ipairs(C.ElementOrder) do
					local site = assert(habitats:FindFirstChild(element .. "Habitat"))
					assert(site:GetAttribute("Element") == element)
					local anchor = assert(site:FindFirstChild("ActivityAnchor"))
					assert(anchor:GetAttribute("BaseIndex") == base:GetAttribute("BaseIndex"))
					assert(anchor:GetAttribute("Element") == element and R.vector(anchor.Position))
					for _, part in ipairs(site:GetDescendants()) do
						if part:IsA("BasePart") then
							parts = parts + 1
							assert(part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery)
						end
					end
				end
				assert(#habitats:GetChildren() == #C.ElementOrder and parts <= A.MaxHabitatParts)
				assert(area:GetAttribute("RanchLayoutSerial") == base:GetAttribute("RanchLayoutSerial"))
				out.habitatCount, out.habitatParts = #C.ElementOrder, parts
				local first, firstLimb = {}, {}
				for sample = 1, 16 do
					for _, id in ipairs(data.ids) do
						local record, model = assert(records:FindFirstChild(id)), assert(effects.pets[id])
						local position = model:GetPivot().Position
						local center, bounds = record:GetAttribute("PenCenter"), record:GetAttribute("PenBounds")
						assert(R.vector(position) and R.vector(center) and typeof(bounds) == "Vector2")
						assert(record:GetAttribute("OwnerUserId") == ownerId, "Probe mixed foreign ranch records")
						assert(record:GetAttribute("Displayed") and record:GetAttribute("DisplayMode") == "Pen")
						assert(math.abs(position.X - center.X) <= bounds.X + 0.05)
						assert(math.abs(position.Z - center.Z) <= bounds.Y + 0.05)
						local pose = Motion.read(record)
						local anchors = {}
						for _, other in ipairs(records:GetChildren()) do
							if
								other:GetAttribute("OwnerUserId") == record:GetAttribute("OwnerUserId")
								and other:GetAttribute("Rarity") == "Godly"
								and other:GetAttribute("Displayed")
								and other:GetAttribute("DisplayMode") == "Pen"
							then
								table.insert(anchors, other:GetAttribute("PenPosition"))
							end
						end
						local sampleTime = workspace:GetServerTimeNow()
						if pose and Motion.valid(pose, sampleTime) then
							local expected = Motion.pose(pose, sampleTime, anchors).Position
							assert(
								(position - expected).Magnitude <= 1,
								"Rendered root disagrees with shared activity sampler"
							)
						end
						local interaction = assert(model:FindFirstChild("PetInteraction"))
						assert(interaction:GetAttribute("OwnerUserId") == record:GetAttribute("OwnerUserId"))
						assert(interaction:GetAttribute("PetId") == id)
						local rig = effects.petRigs and effects.petRigs[id]
						assert(rig and not rig.truncated, "Pet articulation rig missing or over budget")
						for _, part in ipairs(model:GetDescendants()) do
							if part:IsA("BasePart") then
								assert(part.Anchored and not part.CanCollide and not part.CanTouch)
								if
									part.Name == "Tail"
									or part.Name == "Foot"
									or part.Name == "Arm"
									or part.Name == "Wing"
								then
									local relative = model:GetPivot():ToObjectSpace(part.CFrame)
									local previous = firstLimb[part]
									if
										previous
										and (
											(relative.Position - previous.Position).Magnitude > 0.002
											or relative.LookVector:Dot(previous.LookVector) < 0.99999
											or relative.UpVector:Dot(previous.UpVector) < 0.99999
										)
									then
										out.limbMoved = true
									end
									firstLimb[part] = previous or relative
								end
							end
						end
						if record:GetAttribute("Rarity") ~= "Godly" then
							for _, other in ipairs(records:GetChildren()) do
								if
									other:GetAttribute("OwnerUserId") == record:GetAttribute("OwnerUserId")
									and other:GetAttribute("Rarity") == "Godly"
									and other:GetAttribute("Displayed")
									and other:GetAttribute("DisplayMode") == "Pen"
								then
									local anchor = other:GetAttribute("PenPosition")
									local d = Vector2.new(position.X - anchor.X, position.Z - anchor.Z).Magnitude
									assert(d >= C.GodlyDistance - 0.05, "Rendered activity entered Godly exclusion")
								end
							end
						end
						if first[id] and (position - first[id]).Magnitude > 0.08 then
							out.moved = true
						end
						first[id] = first[id] or position
					end
					out.samples = sample
					task.wait(0.1)
				end
				out.observed = #data.ids
				assert(out.moved, "Activity snapshots produced no visible motion")
				assert(out.limbMoved, "Rendered pet limbs did not articulate independently of root motion")
			end, debug.traceback)
			out.passed, out.error = ok, ok and nil or tostring(err)
			diagnostics:FireServer(out)
			running = false
		end)
	end)
end

return ClientChecks
