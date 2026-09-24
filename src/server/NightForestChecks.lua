-- Engine integration of owner feedback. Existing regression checks remain intact.
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").Stage3Shared
local C = require(Shared.Config)
local Geometry = require(Shared.NightGeometry)
local Checks = {}
function Checks.run(g, check, a, b, results)
	assert(RunService:IsStudio() and workspace:GetAttribute("Stage3AutoTest") == true)
	local function waitFor(fn, seconds)
		local deadline = os.clock() + seconds
		repeat
			if fn() then
				return true
			end
			task.wait(0.05)
		until os.clock() > deadline
		return false
	end
	local function probe(kind, target)
		local token = "night-forest-" .. kind .. "-" .. tostring(g:now())
		g:feed(a, "completionInputProbe", { kind = kind, token = token, target = target })
		assert(
			waitFor(function()
				return g.clientDiagnostics[a] and g.clientDiagnostics[a].token == token
			end, 35),
			"Client probe timed out: " .. kind
		)
		local d = g.clientDiagnostics[a]
		results.nightForestDiagnostics = results.nightForestDiagnostics or {}
		table.insert(results.nightForestDiagnostics, d)
		assert(d.passed, d.error)
		return d
	end
	local oldNight = workspace:GetAttribute("Night")
	local oldBoss = workspace:GetAttribute("BossEnabled")
	local oldEnd = g.phaseEnds
	local home = g:root(a) and g:root(a).CFrame
	workspace:SetAttribute("BossEnabled", false)
	g:setNight(false)
	g.phaseEnds = g:now() + 600
	check("Forest contains twelve distinct nests without expanding the world footprint", function()
		assert(#g.world.nests == 12 and #g.world.nests == #C.ForestNestPositions)
		local ids = {}
		for _, nest in ipairs(g.world.nests) do
			assert(not ids[nest.id])
			ids[nest.id] = true
			assert(nest.part:IsDescendantOf(g.world.decor) and nest.part.CanCollide)
			assert(math.abs(nest.position.X) < 90 and nest.position.Z > C.SafeBoundaryZ and nest.position.Z <= 200)
			for _, other in ipairs(g.world.nests) do
				if other ~= nest then
					assert((nest.position - other.position).Magnitude >= 10, "Overlapping nest sites")
				end
			end
		end
	end)
	check("Marked Godly nest creates a real Godly egg while ordinary rarity weights stay unchanged", function()
		local count = 0
		for _, nest in ipairs(g.world.nests) do
			if nest.fixedRarity then
				count += 1
				assert(nest.fixedRarity == "Godly" and nest.creature == nil)
			end
		end
		assert(count == 1)
		local nest = g.world.nests[C.GodlyNestIndex]
		assert(nest.part:GetAttribute("GodlyNest") and nest.egg and nest.egg.rarity == "Godly")
		assert(
			g.eggs[nest.egg.id] == nest.egg and not nest.egg.nightEvent and table.find(C.Creatures, nest.egg.creature)
		)
		local expected =
			{ Common = 4800, Uncommon = 2800, Rare = 1400, Epic = 700, Legendary = 240, Mythic = 55, Godly = 5 }
		for rarity, weight in pairs(expected) do
			assert(C.DayWeights[rarity] == weight)
		end
		assert(C.NightWeights.Godly == 100)
	end)
	check("Godly nest cooldown rejects early replacement and uses the production respawn schedule", function()
		local nest = g.world.nests[C.GodlyNestIndex]
		local egg = nest.egg
		assert(egg and egg.state == "Home")
		local before = g:now()
		assert(g:retireEgg(egg))
		assert(nest.respawn >= before + C.GodlyNestRespawn)
		g:step(0)
		assert(nest.egg == nil and g.eggs[egg.id] == nil)
		-- Controlled deadline fixture. This checks scheduling boundaries, not a ten-minute wall-clock wait.
		nest.respawn = g:now() - 0.01
		g:step(0)
		assert(nest.egg and nest.egg.id ~= egg.id and nest.egg.rarity == "Godly")
		results.godlyRespawnDiagnostics =
			{ delay = C.GodlyNestRespawn, oldId = egg.id, newId = nest.egg.id, deadlineFixture = true }
	end)
	check("Real Godly pickup survives Night transition and respects dormant daytime nests", function()
		local nest = g.world.nests[C.GodlyNestIndex]
		local egg = nest.egg
		g:teleport(a, CFrame.new(nest.position + Vector3.new(0, 3, 0)))
		probe("Position", nest.position + Vector3.new(0, 3, 0))
		assert(g:take(a, egg.id))
		assert(g.carry[a] == egg and egg.rarity == "Godly")
		g:setNight(true)
		assert(g.carry[a] == egg and g.eggs[egg.id] == egg)
		assert(g:drop(a, "night-regression"))
		assert(egg.state == "Dropped")
		g:setNight(false)
		assert(g:resetEgg(egg))
		g:setNight(true)
		assert(not egg.prompt.Enabled)
		local accepted, why = g:take(a, egg.id)
		assert(not accepted and why == "Daytime nests are dormant during Moonrise.")
		-- Home restoration is fixture cleanup, handled after the Night/Forest checks.
		-- Do not make this gameplay assertion depend on a second long-distance test teleport.
	end)
	check("Night contours follow box, sphere, cylinder and wedge geometry instead of box-only proxies", function()
		local part = Instance.new("Part")
		local wedge = Instance.new("WedgePart")
		local ok, err = xpcall(function()
			part.Size = Vector3.new(4, 6, 8)
			local lines, kind = Geometry.build(part)
			assert(#lines == 12 and kind == "box-edges")
			part.Shape = Enum.PartType.Ball
			lines, kind = Geometry.build(part)
			assert(#lines == 12 and kind == "ellipsoid-contours")
			for _, line in ipairs(lines) do
				assert(line.c0 and line.c1 and line.ta.Magnitude > 0.99)
			end
			part.Shape = Enum.PartType.Cylinder
			lines, kind = Geometry.build(part)
			assert(#lines == 12 and kind == "cylinder-rims")
			lines, kind = Geometry.build(wedge)
			assert(#lines == 9 and kind == "wedge-edges")
		end, debug.traceback)
		part:Destroy()
		wedge:Destroy()
		assert(ok, err)
	end)
	check("Night edge lights cover nearby world objects and rebuild and clean up actual geometry", function()
		g:setNight(true)
		-- Hold the Night fixture while input/rendering checks run; cadence has separate coverage.
		g.phaseEnds = g:now() + 600
		probe("NightEdges")
	end)
	check("Real flashlight input toggles a nonphysical personal light without colliding with duel controls", function()
		probe("Flashlight")
	end)
	check("Longer denser trails retain bounded allocation and expired-particle reuse", function()
		probe("LongTrails")
	end)
	check("Dawn disables the new edge lights without leaving active Night geometry", function()
		g:setNight(false)
		probe("NightDawn")
	end)
	if g.carry[a] then
		g:resetEgg(g.carry[a])
	end
	if home and g:root(a) then
		g:teleport(a, home)
	end
	g:setNight(oldNight == true)
	g.phaseEnds = math.max(oldEnd, g:now() + 10)
	workspace:SetAttribute("BossEnabled", oldBoss)
end
return Checks
