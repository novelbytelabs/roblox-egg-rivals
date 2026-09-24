-- Real Roblox-engine integration tests. Fixtures use two Studio test Players.
-- Direct service calls exercise production validators, physics, damage, timers,
-- escrow and disconnect paths. These are not a substitute for human feel testing.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Shared = game:GetService("ReplicatedStorage").Stage3Shared
local C = require(Shared.Config)
local Rules = require(Shared.Rules)
local ContractChecks = require(script.Parent.ContractChecks)
local Tests = {}
function Tests.run(g)
	assert(RunService:IsStudio(), "Studio tests only")
	local results = {
		build = C.Build,
		sourceDigest = workspace:GetAttribute("Stage3SourceDigest"),
		tests = {},
		started = os.time(),
		passed = 0,
		failed = 0,
	}
	local function check(name, fn)
		local ok, err = xpcall(fn, debug.traceback)
		table.insert(results.tests, { name = name, passed = ok, error = not ok and tostring(err) or nil })
		if ok then
			results.passed += 1
			print("[STAGE3 PASS] " .. name)
		else
			results.failed += 1
			warn("[STAGE3 FAIL] " .. name .. ": " .. tostring(err))
		end
		return ok
	end
	local function waitFor(fn, timeout)
		local deadline = os.clock() + timeout
		repeat
			if fn() then
				return true
			end
			task.wait(0.05)
		until os.clock() > deadline
		return false
	end
	local fixtureSerial = 0
	local function near(p, pos)
		g:teleport(p, CFrame.new(pos))
		if not g.clientDiagnostics then
			task.wait(0.15)
			return
		end
		fixtureSerial += 1
		local token = "core-fixture-" .. fixtureSerial .. "-" .. tostring(g:now())
		g:feed(p, "completionInputProbe", { token = token, kind = "Position", target = pos })
		assert(
			waitFor(function()
				local diag = g.clientDiagnostics[p]
				local root = g:root(p)
				return diag
					and diag.token == token
					and diag.passed
					and root
					and Vector2.new(root.Position.X - pos.X, root.Position.Z - pos.Z).Magnitude <= 3
			end, 5),
			"Core fixture position did not settle"
		)
	end
	local function equip(p, name)
		local tool = p.Backpack:FindFirstChild(name) or p.Character:FindFirstChild(name)
		assert(tool, "Missing tool " .. name)
		g:humanoid(p):EquipTool(tool)
		task.wait(0.12)
	end
	local function dayEgg(index)
		local nest = g.world.nests[index]
		assert(nest, "Missing Day nest " .. tostring(index))
		if not nest.egg then
			assert(
				waitFor(function()
					return nest.egg ~= nil
				end, C.EggRespawnTime + 2),
				"Day nest " .. index .. " did not respawn"
			)
		end
		local egg = nest.egg
		assert(egg and g.eggs[egg.id] == egg, "Day nest egg registry invariant failed")
		return egg
	end
	local function report()
		results.finished = os.time()
		local text = HttpService:JSONEncode(results)
		local v = Instance.new("StringValue")
		v.Name = "Stage3TestResults"
		v.Value = text
		v.Parent = game.ReplicatedStorage
		print("[STAGE3 RESULTS] " .. text)
		local ok, err = pcall(function()
			HttpService:PostAsync(
				"http://127.0.0.1:38473/stage3-results",
				text,
				Enum.HttpContentType.ApplicationJson,
				false,
				{ ["X-Stage3-Token"] = "moonwood-local-integration" }
			)
		end)
		if not ok then
			warn("[STAGE3 COLLECTOR] " .. tostring(err))
		end
		-- Leave this test session open for inspection; automatic teardown hung on this Vinegar host.
	end
	if
		not waitFor(function()
			local ps = Players:GetPlayers()
			return #ps >= 2 and g:alive(ps[1]) and g:alive(ps[2])
		end, 45)
	then
		check("two real Studio clients connected", function()
			error("Two test players did not connect in 45 seconds")
		end)
		report()
		return
	end
	local ps = Players:GetPlayers()
	table.sort(ps, function(a, b)
		return a.Name < b.Name
	end)
	local a, b = ps[1], ps[2]
	ContractChecks.run(g, check, a)
	check("World, four elemental camps, respawns, pens and named models", function()
		assert(
			#g.world.bases == 4
				and #g.world.nests == #C.ForestNestPositions
				and #g.world.nests == 12
				and #g.world.hiddenNightSpots >= 4
		)
		assert(g.world.guardian:FindFirstChild("Heart"))
		assert(g.world.nests[1].egg and g.world.nests[4].egg)
		assert(g.profiles[a].base ~= g.profiles[b].base)
		for _, base in ipairs(g.world.bases) do
			for _, element in ipairs(C.ElementOrder) do
				assert(base.incubators[element] and base.incubators[element].pad:GetAttribute("Element") == element)
			end
			assert(base.respawnPad:IsA("SpawnLocation") and base.penCenter)
		end
		assert(
			(g.profiles[a].base.spawn.Position - (g.profiles[a].base.respawnPad.Position + Vector3.new(0, 3.5, 0))).Magnitude
				< 0.1
		)
	end)
	check("0.4.0 rules validate, Speed is monotonic/bounded, and Night cadence stays bounded", function()
		assert(Rules.validate())
		assert(Rules.speed(0) == C.BaseWalkSpeed)
		local previous = Rules.speed(0)
		for speed = 100, C.SpeedCap, 100 do
			local mapped = Rules.speed(speed)
			assert(mapped >= previous and mapped <= C.WalkSpeedCap)
			previous = mapped
		end
		assert(math.abs(Rules.speed(C.SpeedCap) - C.WalkSpeedCap) < 0.001)
		assert(Rules.speed(C.SpeedCap, true) <= C.OverdriveCap)
		assert(Rules.speed(0 / 0) == C.BaseWalkSpeed and not Rules.vector(Vector3.new(0 / 0, 0, 0)))
		local rng = Random.new(301)
		local typical = 0
		for _ = 1, 1000 do
			local n = Rules.nextNight(rng)
			assert(n >= 120 and n <= 600)
			if n >= 240 and n <= 300 then
				typical += 1
			end
		end
		assert(typical > 730 and typical < 870)
	end)

	check("Rarity, creature, and element are independent across all supported combinations", function()
		local Inventory = require(script.Parent.Inventory)
		local inv = Inventory.new()
		local owner = -44040
		for _, rarity in ipairs(C.RarityOrder) do
			for _, creature in ipairs(C.Creatures) do
				local egg = assert(inv:create(owner, "Egg", rarity, creature))
				assert(egg.rarity == rarity and egg.creature == creature and egg.element == nil)
				inv.items[egg.id] = nil
				for _, element in ipairs(C.ElementOrder) do
					local pet = assert(inv:create(owner, "Pet", rarity, creature, element))
					assert(pet.rarity == rarity and pet.creature == creature and pet.element == element)
					inv.items[pet.id] = nil
				end
			end
		end
		assert(C.DayWeights.Godly == 5 and C.NightWeights.Godly == 100)
		assert(C.Rarities.Godly.hatch == 7200 and C.Rarities.Godly.income == 2500)
	end)

	check("Momentum, Overdrive bounds, fractional Coin credit, and Exchange values are deterministic", function()
		local m, integral, energy = Rules.trainDelta(0, C.MomentumRamp, true)
		assert(math.abs(m - 1) < 0.001 and integral > 14.9 and integral < 15.1)
		assert(energy >= 0)
		local decayed = select(1, Rules.trainDelta(1, C.MomentumDecay, false))
		assert(decayed == 0)
		local balance, remainder = Rules.credit(0, 0, 6, 5)
		assert(balance == 0 and math.abs(remainder - 0.5) < 0.001)
		balance, remainder = Rules.credit(balance, remainder, 6, 5)
		assert(balance == 1 and remainder < 0.001)
		local Inventory = require(script.Parent.Inventory)
		local inv = Inventory.new()
		local common = assert(inv:create(-44041, "Pet", "Common", "Skunk", "Earth"))
		local godly = assert(inv:create(-44041, "Egg", "Godly", "Dragon"))
		assert(Rules.exchangeValue(common) == 48)
		assert(Rules.exchangeValue(godly) == 12000)
	end)
	check("Training accrues only on own treadmill", function()
		workspace:SetAttribute("BossEnabled", false)
		local pro = g.profiles[a]
		near(a, pro.base.treadmill.Position + Vector3.new(0, 3, 0))
		local before = pro.speed.Value
		task.wait(1.25)
		assert(pro.speed.Value > before)
		near(a, pro.base.spawn.Position)
		local after = pro.speed.Value
		task.wait(1.2)
		assert(pro.speed.Value == after)
		near(a, g.profiles[b].base.treadmill.Position + Vector3.new(0, 3, 0))
		task.wait(1.2)
		assert(pro.speed.Value == after)
	end)
	check("Remote pickup cannot bypass proximity", function()
		local egg = dayEgg(1)
		near(a, g.profiles[a].base.spawn.Position)
		assert(not g:take(a, egg.id))
		assert(egg.state == "Home" and egg.carrier == nil)
	end)
	local firstPet
	local heistOK = check("Bat drops carried egg with BossEnabled false; no shared base ownership", function()
		local egg = dayEgg(1)
		assert(egg)
		near(a, egg.model:GetPivot().Position + Vector3.new(0, 2, -4))
		assert(g:take(a, egg.id))
		near(b, g:root(a).Position + Vector3.new(3, 0, 0))
		equip(b, "Bat")
		assert(g:bat(b))
		assert(not g.carry[a] and egg.state == "Dropped")
		assert(g:take(b, egg.id))
		assert(g.carry[b] == egg)
		near(b, g.profiles[a].base.incubators.Fire.pad.Position + Vector3.new(0, 3, 0))
		assert(not g:secure(b, "Fire"))
		near(b, g.profiles[b].base.incubators.Fire.pad.Position + Vector3.new(0, 3, 0))
		assert(g:secure(b, "Fire"), "Explicit Fire incubator placement failed")
		assert(g.profiles[b].incubations.Fire ~= nil, "Fire incubation did not start")
		firstPet = g.profiles[b].incubations.Fire.itemId
		assert(g.inventory.items[firstPet].ownerId == b.UserId)
		assert(g.inventory.items[firstPet].creature == "Skunk")
		assert(g.inventory.items[firstPet].element == "Fire")
	end)
	if heistOK then
		check("Day hatch countdown and real 30x night acceleration", function()
			task.wait(1)
			local inc = g.profiles[b].incubations.Fire
			local item = g.inventory.items[firstPet]
			assert(inc and item and inc.remaining < C.Rarities[item.rarity].hatch)
			-- Bound wall-clock test time without bypassing the production hatch conversion path.
			inc.remaining = 30
			g:setNight(true)
			assert(waitFor(function()
				return g.profiles[b].incubations.Fire == nil
			end, 2))
			assert(g.inventory.items[firstPet].kind == "Pet")
			assert(g.inventory.items[firstPet].species == "Fire Skunk")
			assert(g.inventory.items[firstPet].petMode == "Active")
			assert(g.petRecords:FindFirstChild(firstPet):GetAttribute("DisplayMode") == "Active")
			local before = g.profiles[b].money.Value
			g.profiles[b].coinRemainder = 0.95
			task.wait(1)
			assert(g.profiles[b].money.Value > before)
			assert(g.nightEgg ~= nil and g.nightEgg.rarity ~= nil)
			assert(g.nightEgg.rarity == "Legendary" or g.nightEgg.rarity == "Mythic" or g.nightEgg.rarity == "Godly")
			g:setNight(false)
		end)
	end
	check("All four elements hatch independent Dragon variants without changing rarity", function()
		near(a, g.profiles[a].base.center + Vector3.new(0, 3, 0))
		local baseline = assert(g.inventory:create(a.UserId, "Pet", "Common", "Skunk", "Fire"))
		g:reconcilePets()
		assert(g:setPetMode(a, baseline.id, "Active"))
		local eggs = {}
		for _, element in ipairs(C.ElementOrder) do
			local item = assert(g.inventory:create(a.UserId, "Egg", "Common", "Dragon"))
			eggs[element] = item
			near(a, g.profiles[a].base.incubators[element].pad.Position + Vector3.new(0, 3, 0))
			assert(g:incubate(a, item.id, element))
			assert(g.profiles[a].incubations[element].itemId == item.id)
		end
		local extra = assert(g.inventory:create(a.UserId, "Egg", "Common", "Skunk"))
		assert(not g:incubate(a, extra.id, "Fire"), "Occupied incubator accepted another egg")
		assert(not g:incubate(b, extra.id, "Water"), "Foreign item was accepted")
		assert(not g:incubate(a, extra.id, "Lightning"), "Invalid element was accepted")
		assert(extra.state == "Inventory" and extra.element == nil)
		task.wait(0.5)
		for _, element in ipairs(C.ElementOrder) do
			assert(g.profiles[a].incubations[element].remaining < 20)
		end
		g:setNight(true)
		assert(
			waitFor(function()
				return next(g.profiles[a].incubations) == nil
			end, 2),
			"Four real night-accelerated hatches did not finish"
		)
		g:setNight(false)
		for _, element in ipairs(C.ElementOrder) do
			local item = eggs[element]
			assert(item.kind == "Pet" and item.creature == "Dragon" and item.element == element)
			assert(item.species == element .. " Dragon" and item.rarity == "Common" and item.petMode == "Pen")
		end
		assert(g:setPetMode(a, eggs.Water.id, "Active"))
		assert(baseline.petMode == "Pen" and g.profiles[a].activePetId == eggs.Water.id)
		assert(not g:setPetMode(b, eggs.Water.id, "Active"), "Another player activated a foreign pet")
		assert(g.petRecords[eggs.Water.id]:GetAttribute("DisplayMode") == "Active")
		assert(g:setPetMode(a, eggs.Water.id, "Pen"))
		assert(g.profiles[a].activePetId == nil)
	end)
	check("Night dormancy, hidden egg lifecycle, and cross-sunrise contests preserve ownership", function()
		workspace:SetAttribute("BossEnabled", false)
		g:setNight(false)
		local carriedDay = dayEgg(2)
		assert(carriedDay and carriedDay.state == "Home")
		near(a, carriedDay.model:GetPivot().Position + Vector3.new(0, 2, -4))
		assert(g:take(a, carriedDay.id))
		g:setNight(true)
		assert(g.carry[a] == carriedDay, "Moonrise deleted an already-carried Day egg")
		assert(g.nightEgg and g.nightEgg.state == "Home", "Night did not create exactly one hidden egg")
		local nightId = g.nightEgg.id
		assert(g.eggs[nightId] == g.nightEgg)
		local dormant = dayEgg(4)
		if dormant and dormant.state == "Home" then
			near(b, dormant.model:GetPivot().Position + Vector3.new(0, 2, -4))
			assert(not g:take(b, dormant.id), "Dormant Day nest allowed a new Night pickup")
		end
		g:setNight(false)
		assert(g.carry[a] == carriedDay, "Sunrise canceled the Day egg carry contest")
		assert(g.eggs[nightId] == nil, "Unclaimed hidden Night egg survived dawn")
		g:resetEgg(carriedDay)

		g:setNight(true)
		local active = g.nightEgg
		assert(active and active.state == "Home")
		near(a, active.model:GetPivot().Position + Vector3.new(0, 2, -4))
		assert(g:take(a, active.id))
		g:setNight(false)
		assert(g.carry[a] == active and g.eggs[active.id] == active, "Active Night contest did not survive dawn")
		assert(g:drop(a, "manual"))
		assert(active.state == "Dropped" and g.eggs[active.id] == active)
		g:resetEgg(active)
		assert(g.eggs[active.id] == nil and g.nightEgg == nil, "Resolved post-dawn Night contest leaked an egg")
	end)

	check("All sixteen creature-element models are constructible and distinct", function()
		local Art = require(Shared.Art)
		local folder = Instance.new("Folder")
		folder.Parent = game.ServerStorage
		local names = {}
		for _, creature in ipairs(C.Creatures) do
			for _, element in ipairs(C.ElementOrder) do
				local model = Art.pet(creature, "Common", element, folder)
				assert(model.Name == element .. " " .. creature and model.PrimaryPart and model:FindFirstChild("Body"))
				names[model.Name] = true
			end
		end
		local count = 0
		for _ in pairs(names) do
			count += 1
		end
		folder:Destroy()
		assert(count == 16)
	end)
	check("Pen paging keeps every displayed pet within the pen and preserves income", function()
		local starterCapacity = C.Expansions[1].capacity
		for _ = 1, starterCapacity + 1 do
			assert(g.inventory:create(b.UserId, "Pet", "Common", "Skunk", "Earth"))
		end
		g:reconcilePets()
		local pro = g.profiles[b]
		assert(pro.penCount > starterCapacity and pro.penPages >= 2)
		local income = g.inventory:income(b.UserId)
		local shownIds = {}
		for page = 1, pro.penPages do
			assert(g:setPenPage(b, page))
			local visible = 0
			for _, r in ipairs(g.petRecords:GetChildren()) do
				if r:GetAttribute("OwnerUserId") == b.UserId and r:GetAttribute("Displayed") then
					local mode = r:GetAttribute("DisplayMode")
					if mode == "Pen" then
						local pos = r:GetAttribute("PenPosition")
						assert(typeof(pos) == "Vector3" and math.abs(pos.X - pro.base.penCenter.X) <= 10)
						assert(math.abs(pos.Z - pro.base.penCenter.Z) <= 3)
						visible += 1
						shownIds[r.Name] = true
					elseif mode == "Active" then
						assert(r:GetAttribute("PenPosition") == nil)
					end
				end
			end
			assert(visible > 0 and visible <= starterCapacity)
			assert(g.inventory:income(b.UserId) == income)
		end
		local count = 0
		for _ in pairs(shownIds) do
			count += 1
		end
		assert(count == pro.penCount)
		assert(not g:setPenPage(b, 999) and not g:setPenPage(b, 0 / 0))
		assert(g:setPenPage(b, 1))
	end)
	check("Egg storage preserves unhatched creature identity at the owner's camp only", function()
		local egg = dayEgg(3)
		near(b, egg.model:GetPivot().Position + Vector3.new(0, 2, -4))
		assert(g:take(b, egg.id))
		assert(not g:storeEgg(b))
		near(b, g.profiles[a].base.spawn.Position)
		assert(not g:storeEgg(b))
		near(b, g.profiles[b].base.spawn.Position)
		local before = #g.inventory:list(b.UserId)
		assert(g:storeEgg(b))
		assert(not g.carry[b] and #g.inventory:list(b.UserId) == before + 1)
		local list = g.inventory:list(b.UserId)
		local stored = list[#list]
		assert(stored.kind == "Egg" and stored.creature == "Gorilla" and stored.element == nil)
	end)
	check("Upgrade price, ownership, double-purchase rejection", function()
		local pro = g.profiles[a]
		near(a, pro.base.spawn.Position)
		pro.money.Value = 0
		assert(not g:buyUpgrade(a, 2))
		pro.money.Value = C.Grades[2].cost
		assert(g:buyUpgrade(a, 2))
		assert(pro.tier == 2 and pro.money.Value == 0)
		assert(not g:buyUpgrade(a))
		assert(pro.money.Value == 0)
		near(a, pro.base.treadmill.Position + Vector3.new(0, 3, 0))
		local before = pro.speed.Value
		task.wait(1.2)
		assert(pro.speed.Value - before >= 2)
		near(a, pro.base.spawn.Position)
	end)
	check("Safe-zone bat and snare rejection", function()
		near(a, g.profiles[a].base.spawn.Position)
		equip(a, "Bat")
		assert(not g:bat(a))
		equip(a, "SnarePod")
		assert(not g:placeTrap(a))
		assert(g.profiles[a].charges == 1)
	end)
	check("Snare arms, affects only carriers, expires slow independently of boss", function()
		near(a, Vector3.new(0, 4, 51))
		equip(a, "SnarePod")
		task.wait(1.1)
		assert(g:placeTrap(a))
		local trap = g.traps[#g.traps]
		assert(trap)
		local egg = dayEgg(2)
		near(b, egg.model:GetPivot().Position + Vector3.new(0, 2, -4))
		assert(g:take(b, egg.id))
		task.wait(C.TrapArmTime + 0.1)
		near(b, trap.part.Position + Vector3.new(0, 3, 0))
		assert(waitFor(function()
			return g.profiles[b].slowUntil > g:now()
		end, 1))
		assert(g:humanoid(b).WalkSpeed == 6)
		task.wait(C.TrapSlowTime + 0.2)
		assert(g:humanoid(b).WalkSpeed == Rules.speed(g.profiles[b].speed.Value))
		g:resetEgg(g.carry[b])
	end)
	local itemA = g.inventory:create(a.UserId, "Egg", "Common")
	local itemB = g.inventory.items[firstPet] or g.inventory:create(b.UserId, "Pet", "Common", "Skunk", "Fire")
	local spare = g.inventory:create(b.UserId, "Egg", "Uncommon")
	local function prep()
		if g.duels.current then
			g.duels:finish(nil, "Test cleanup")
		end
		if g.carry[a] then
			g:resetEgg(g.carry[a])
		end
		if g.carry[b] then
			g:resetEgg(g.carry[b])
		end
		near(a, Vector3.new(-2, 4, 0))
		near(b, Vector3.new(2, 4, 0))
	end
	check("Duel decline changes no ownership", function()
		prep()
		assert(not g.duels:request(a, a))
		assert(g.duels:request(a, b))
		assert(g.duels:reply(b, false))
		assert(g.duels.current == nil)
		assert(itemA.ownerId == a.UserId and itemB.ownerId == b.UserId)
	end)
	check("Offer ownership, stale confirmation, revision reset and cancel", function()
		prep()
		assert(g.duels:request(a, b))
		assert(g.duels:reply(b, true))
		assert(not g.duels:select(a, itemB.id))
		assert(g.duels:select(a, itemA.id))
		local stale = g.duels.current.revision
		assert(g.duels:select(b, itemB.id))
		assert(not g.duels:confirm(a, stale))
		assert(g.duels:confirm(a, g.duels.current.revision))
		assert(g.duels.current.ready[a])
		assert(g.duels:select(b, spare.id))
		assert(not g.duels.current.ready[a])
		assert(g.duels:cancel(a))
		assert(itemA.state == "Inventory" and itemB.state == "Inventory")
	end)
	local duelOK = check("Both confirmations create exact escrow and equip both blasters", function()
		prep()
		assert(g:setPetMode(b, itemB.id, "Active"))
		assert(g.duels:request(a, b))
		assert(g.duels:reply(b, true))
		assert(g.duels:select(a, itemA.id))
		assert(g:setPetMode(b, itemB.id, "Active") == false, "Pet mode changed while selecting")
		assert(g.duels:select(b, itemB.id))
		local rev = g.duels.current.revision
		assert(g.duels:confirm(a, rev))
		assert(g.duels:confirm(b, rev))
		assert(waitFor(function()
			return g.duels.current and g.duels.current.phase == "Active"
		end, 18))
		assert(itemA.state == "Escrow" and itemB.state == "Escrow" and spare.state == "Inventory")
		assert(
			g.petRecords[itemB.id]:GetAttribute("Locked") and not g.petRecords[itemB.id]:GetAttribute("Displayed"),
			"Escrowed pet remained visible"
		)
		assert(g:equipped(a, "DuelBlaster") and g:equipped(b, "DuelBlaster"))
		assert(g:humanoid(a).WalkSpeed == C.DuelWalkSpeed and g:humanoid(b).WalkSpeed == C.DuelWalkSpeed)
	end)
	if duelOK then
		check("Blaster finite-input guard and real arena cover occlusion", function()
			assert(not g.duels:shoot(a, Vector3.new(0 / 0, 0, 0)))
			local ah = a.Character.Head.Position
			local bh = b.Character.Head.Position
			local block = Instance.new("Part")
			block.Name = "RegressionCover"
			block.Size = Vector3.new(3, 12, 12)
			block.Anchored = true
			block.Position = (ah + bh) / 2
			block.Parent = g.world.arena
			local before = g:humanoid(b).Health
			assert(g.duels:shoot(a, (bh - ah).Unit))
			task.wait(0.1)
			assert(g:humanoid(b).Health == before)
			block:Destroy()
			task.wait(C.ShotCooldown + 0.1)
		end)
		check("Five real damage eliminations finish once; selected pet transfers income ownership", function()
			for round = 1, C.DuelTarget do
				assert(
					waitFor(function()
						return g.duels.current and g.duels.current.phase == "Active" and g:alive(a) and g:alive(b)
					end, 18),
					"Round did not start"
				)
				for _ = 1, 3 do
					local direction = (b.Character.Head.Position - a.Character.Head.Position).Unit
					assert(g.duels:shoot(a, direction))
					task.wait(C.ShotCooldown + 0.06)
				end
				if round < C.DuelTarget then
					assert(g.duels.current.scores[a] == round)
				end
			end
			assert(waitFor(function()
				return g.duels.current == nil
			end, 3))
			assert(itemA.ownerId == a.UserId and itemB.ownerId == a.UserId)
			assert(itemA.state == "Inventory" and itemB.state == "Inventory" and spare.ownerId == b.UserId)
			assert(itemB.petMode == "Pen")
			assert(g.petRecords[itemB.id]:GetAttribute("OwnerUserId") == a.UserId)
			assert(g.petRecords[itemB.id]:GetAttribute("DisplayMode") == "Pen")
			assert(not a:GetAttribute("InDuel") and not a:GetAttribute("Busy"))
			assert(g:root(a).Position.Z < C.SafeBoundaryZ)
		end)
	end
	check("Offer timeout returns to the world without item loss", function()
		prep()
		assert(g.duels:request(a, b))
		g.duels.current.deadline = g:now() - 1
		assert(waitFor(function()
			return g.duels.current == nil
		end, 1))
		assert(spare.ownerId == b.UserId)
	end)
	check("Client HUD, collection key input, tool bindings and post-duel camera", function()
		local token = "post-duel-" .. tostring(os.clock())
		g:feed(a, "clientProbe", { token = token })
		assert(
			waitFor(function()
				return g.clientDiagnostics[a] and g.clientDiagnostics[a].token == token
			end, 12),
			"Client probe did not return"
		)
		local d = g.clientDiagnostics[a]
		results.clientDiagnostics = d
		assert(d.passed, d.error)
	end)
	check("Warden catches after unpause and returns finite transforms home", function()
		prep()
		local egg = dayEgg(1)
		assert(egg)
		near(a, egg.model:GetPivot().Position + Vector3.new(0, 2, -5))
		assert(g:take(a, egg.id))
		g.world.guardian:PivotTo(CFrame.new(g:root(a).Position + Vector3.new(0, 0, -10)))
		workspace:SetAttribute("BossEnabled", true)
		assert(
			waitFor(function()
				return g.carry[a] == nil
			end, 8),
			"Warden did not catch a stationary carrier"
		)
		assert(egg.state == "Home" and g:root(a).Position.Z < C.SafeBoundaryZ)
		task.wait(2)
		assert(Rules.vector(g.world.guardian:GetPivot().Position), "Nonfinite Warden transform")
		workspace:SetAttribute("BossEnabled", false)
	end)
	check("Death respawn returns to the owner's marked pad with normal gear", function()
		prep()
		g:humanoid(a).Health = 0
		assert(
			waitFor(function()
				return g:alive(a)
			end, 15),
			"Player did not respawn"
		)
		task.wait(0.3)
		assert((g:root(a).Position - g.profiles[a].base.spawn.Position).Magnitude < 8)
		assert(a.Backpack:FindFirstChild("Bat") and a.Backpack:FindFirstChild("SnarePod"))
	end)
	check("Warden navigation does not tunnel through a wall", function()
		local Navigation = require(script.Parent.Navigation)
		local nav = Navigation.new(g.world.decor)
		local wall = Instance.new("Part")
		wall.Name = "NavigationRegressionWall"
		wall.Size = Vector3.new(16, 14, 3)
		wall.Position = Vector3.new(0, 7, 56)
		wall.Anchored = true
		wall.Parent = g.world.decor
		local from = Vector3.new(0, 4, 42)
		local target = Vector3.new(0, 4, 70)
		assert(not nav:clear(from, target))
		local pos = from
		local deadline = os.clock() + 10
		repeat
			pos = select(1, nav:advance(pos, target, 19, 0.05, g:now()))
			assert(not (math.abs(pos.X) < 10 and math.abs(pos.Z - 56) < 3), "Warden tunneled through wall")
			task.wait(0.05)
		until (pos - target).Magnitude < 2 or os.clock() > deadline
		wall:Destroy()
		assert((pos - target).Magnitude < 2, "Warden failed to route around obstacle")
	end)
	require(script.Parent.LivingWorldChecks).run(g, check, a, b, results)
	require(script.Parent.NightForestChecks).run(g, check, a, b, results)
	require(script.Parent.SprintChecks).run(g, check, a, b, results)
	require(script.Parent.ContractsChecks).run(g, check, a, b, results)
	require(script.Parent.TuningChecks).run(g, check, a, b, results)
	check("Actual client disconnect cancels selection without escrow loss", function()
		prep()
		assert(g.duels:request(a, b))
		assert(g.duels:reply(b, true))
		b:Kick("Stage 3 regression: intentional disconnect")
		assert(waitFor(function()
			return g.duels.current == nil
		end, 4))
		assert(itemA.ownerId == a.UserId and itemA.state == "Inventory")
	end)
	report()
end
return Tests
