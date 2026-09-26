-- These checks use real Studio players, real inventory services, geometry and client rendering.
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").Stage3Shared
local C = require(Shared.Config)
local R = require(Shared.Rules)
local A = require(Shared.RanchActivityConfig)
local Motion = require(Shared.RanchMotion)
local HttpService = game:GetService("HttpService")
local Checks = {}

local function copy(value, seen)
	if type(value) ~= "table" then
		return value
	end
	seen = seen or {}
	if seen[value] then
		return seen[value]
	end
	local out = {}
	seen[value] = out
	for key, child in pairs(value) do
		out[key] = copy(child, seen)
	end
	return out
end
local function waitFor(fn, seconds)
	local deadline = os.clock() + seconds
	repeat
		if fn() then
			return true
		end
		task.wait(0.05)
	until os.clock() >= deadline
	return false
end
local function signature(g, p)
	local rows = {}
	for _, item in ipairs(g.inventory:list(p.UserId)) do
		table.insert(rows, {
			item.id,
			item.ownerId,
			item.kind,
			item.rarity or "",
			item.creature or "",
			item.element or "",
			item.state,
			item.revision or 0,
			item.petMode or "",
			item.favorite == true,
			item.order or 0,
			item.locked == true,
			item.reservation or "",
		})
	end
	return HttpService:JSONEncode(rows)
end

function Checks.run(g, check, a, b, results)
	assert(RunService:IsStudio() and workspace:GetAttribute("Stage3AutoTest") == true)
	local function place(p, cf)
		local token = "ranch-position-" .. p.UserId .. "-" .. tostring(g:now())
		g:teleport(p, cf)
		g:feed(p, "completionInputProbe", { token = token, kind = "Position", target = cf.Position })
		assert(
			waitFor(function()
				local root = g:root(p)
				local diag = g.clientDiagnostics[p]
				return root
					and (root.Position - cf.Position).Magnitude < 6
					and diag
					and diag.token == token
					and diag.passed
			end, 5),
			"Ranch fixture did not settle on both client and server"
		)
	end
	local function scenario(name, body)
		check(name, function()
			local saved, created = {}, {}
			for _, p in ipairs({ a, b }) do
				assert(g:alive(p) and not g:busy(p) and not g.carry[p], "Ranch fixture requires free real players")
				local pro = g.profiles[p]
				saved[p] = {
					ranch = copy(pro.ranch),
					level = pro.ranchLevel,
					page = pro.penPage,
					active = pro.activePetId,
					position = g:root(p).CFrame,
					money = pro.money.Value,
					remainder = pro.coinRemainder,
					speed = pro.speed.Value,
					lab = copy(pro.lab),
					tutorial = pro.tutorial,
					rates = copy(pro.rates),
					contracts = copy(g.contracts.sessions[p]),
				}
			end
			local function pet(p, rarity, creature, element, order)
				local item, err = g.inventory:create(p.UserId, "Pet", rarity, creature, element)
				assert(item, err)
				created[item.id] = true
				item.order = -2000 + order
				return item
			end
			local ok, err = xpcall(function()
				for _, p in ipairs({ a, b }) do
					local pro = g.profiles[p]
					place(p, CFrame.new(pro.base.center + Vector3.new(0, 4, 0)))
					pro.ranchLevel, pro.penPage = 0, 1
					pro.base.applyExpansion(0)
					pro.ranch.queue, pro.ranch.welcomeIds, pro.ranch.activities = {}, {}, {}
					pro.ranch.welcomeUntil, pro.ranch.greetUntil, pro.ranch.reverenceUntil = 0, 0, 0
					pro.ranch.milestoneUntil, pro.ranch.reverencePet = 0, nil
					pro.ranch.nextReverence = g:now() + 3600
					pro.ranch.nextHomecoming, pro.ranch.nextCelebration = 0, 0
					pro.ranch.nextGroupAt, pro.ranch.groupSerial = 0, 0
					pro.ranch.wasHome, pro.ranch.leftAt = true, nil
				end
				local items = {
					pet(a, "Godly", "Dragon", "Fire", 1),
					pet(a, "Common", "Skunk", "Fire", 2),
					pet(a, "Common", "Lizard", "Fire", 3),
					pet(a, "Rare", "Gorilla", "Water", 4),
					pet(a, "Common", "Dragon", "Wind", 5),
					pet(a, "Rare", "Skunk", "Earth", 6),
					pet(a, "Common", "Lizard", "Water", 7),
					pet(a, "Rare", "Gorilla", "Earth", 8),
					pet(a, "Rare", "Dragon", "Wind", 9),
					pet(a, "Common", "Skunk", "Fire", 10),
				}
				local foreign = pet(b, "Rare", "Lizard", "Water", 1)
				assert(g:setPetMode(a, items[10].id, "Active"))
				g:reconcilePets()
				g.ranch:updateRecords(a, g:now())
				g.ranch:updateRecords(b, g:now())
				body(items, foreign)
			end, debug.traceback)
			local cleanOK, cleanErr = xpcall(function()
				for id in pairs(created) do
					g.inventory.items[id] = nil
				end
				for _, p in ipairs({ a, b }) do
					local pro, old = g.profiles[p], saved[p]
					pro.ranch, pro.ranchLevel, pro.penPage, pro.activePetId = old.ranch, old.level, old.page, old.active
					pro.money.Value, pro.coinRemainder = old.money, old.remainder
					pro.speed.Value, pro.lab = old.speed, old.lab
					pro.tutorial, pro.rates = old.tutorial, old.rates
					g.contracts.sessions[p] = old.contracts
					if old.active and g.inventory.items[old.active] then
						g.inventory.items[old.active].petMode = "Active"
					end
					pro.base.applyExpansion(old.level)
				end
				g:reconcilePets()
				for _, p in ipairs({ a, b }) do
					place(p, saved[p].position)
					g:applySpeed(p)
					g.ranch:updateRecords(p, g:now())
				end
				g:pushAll()
			end, debug.traceback)
			assert(cleanOK, "Living Ranch cleanup failed: " .. tostring(cleanErr))
			assert(ok, err)
		end)
	end

	scenario("Living Ranch builds four free nonphysical habitat landmarks at every expansion", function()
		local pro = g.profiles[a]
		local before = signature(g, a)
		local income = g.inventory:income(a.UserId)
		for level = 0, #C.Expansions - 1 do
			pro.ranchLevel = level
			pro.base.applyExpansion(level)
			g:reconcilePets()
			local area = assert(pro.base.model:FindFirstChild("PenArea"))
			assert(area:GetAttribute("PresentationVersion") == 2)
			assert(area:FindFirstChild("RanchPath") and area:FindFirstChild("RanchPlaza"))
			local arch = assert(area:FindFirstChild("RanchEntryArch"))
			local openLeaves = 0
			for _, part in ipairs(arch:GetDescendants()) do
				if part:IsA("BasePart") and part.Name == "OpenGateLeaf" then
					openLeaves += 1
					assert(not part.CanCollide and not part.CanTouch and not part.CanQuery)
				end
			end
			assert(openLeaves == 2)
			local model = area:FindFirstChild("RanchHabitats")
			assert(model and model:GetAttribute("PartCount") <= A.MaxHabitatParts)
			for _, element in ipairs(C.ElementOrder) do
				local site = assert(g.ranch.activities:site(pro, element))
				assert(site.element == element and site.anchor:GetAttribute("BaseIndex") == pro.base.index)
				for _, part in ipairs(site.model:GetDescendants()) do
					if part:IsA("BasePart") then
						assert(part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery)
					end
				end
			end
		end
		assert(signature(g, a) == before and g.inventory:income(a.UserId) == income)
	end)

	scenario("Studio ranch tools grant test funds and a bounded multi-element ranch pack", function()
		local pro = g.profiles[a]
		local beforeMoney = pro.money.Value
		local beforeIds = {}
		for _, item in ipairs(g.inventory:list(a.UserId)) do
			beforeIds[item.id] = true
		end
		assert(g:action(a, "debugCoins", {}))
		assert(pro.money.Value == math.min(C.MaxCoins, beforeMoney + 250000))
		assert(g:action(a, "debugRanch", {}))
		local added, elements = 0, {}
		for _, item in ipairs(g.inventory:list(a.UserId)) do
			if not beforeIds[item.id] then
				added += 1
				elements[item.element] = true
				assert(item.kind == "Pet" and item.ownerId == a.UserId and item.petMode == "Pen")
				g.inventory.items[item.id] = nil
			end
		end
		assert(added == 8)
		for _, element in ipairs(C.ElementOrder) do
			assert(elements[element] == true)
		end
		g:reconcilePets()
	end)

	scenario(
		"Living Ranch episodes remain stable between decision times and recover missing habitat targets",
		function(items)
			local pro = g.profiles[a]
			pro.ranch.activities, pro.ranch.nextGroupAt = {}, g:now() + 3600
			local now = g:now()
			g.ranch:updateRecords(a, now)
			local record = assert(g.petRecords:FindFirstChild(items[2].id))
			local serial = record:GetAttribute("ActivitySerial")
			g.ranch:updateRecords(a, now + 0.1)
			assert(record:GetAttribute("ActivitySerial") == serial)
			local entry = { item = items[2], record = record }
			local plan
			for _ = 1, 5 do
				plan = g.ranch.activities:solo(pro, entry, now, g.ranch.activities:godlies(a.UserId))
				if plan.habitat then
					break
				end
			end
			assert(plan and plan.habitat == "Fire")
			pro.ranch.activities[items[2].id] = plan
			pro.base.activitySites.Fire.model:Destroy()
			g.ranch:updateRecords(a, now + 0.2)
			assert(record:GetAttribute("ActivityHabitat") == nil)
			assert(record:GetAttribute("ActivityKind") == "Idle")
			assert(R.vector(record:GetAttribute("ActivityTarget")))
			local foreignSite = g.profiles[b].base.activitySites.Water
			pro.base.activitySites.Water = foreignSite
			assert(g.ranch.activities:site(pro, "Water") == nil)
		end
	)

	scenario("Living Ranch paired play and group naps remain bounded to eligible same-owner residents", function()
		local pro = g.profiles[a]
		local pairsSeen = {}
		for _, entry in ipairs(g.ranch:visiblePets(a)) do
			local partnerId = entry.record:GetAttribute("ActivityPartnerId")
			if partnerId then
				local partner = assert(g.inventory.items[partnerId])
				assert(partnerId ~= entry.item.id and partner.ownerId == a.UserId)
				assert(partner.rarity ~= "Godly" and entry.item.rarity ~= "Godly")
				local partnerRecord = assert(g.petRecords:FindFirstChild(partnerId))
				assert(partnerRecord:GetAttribute("ActivityPartnerId") == entry.item.id)
				pairsSeen[entry.record:GetAttribute("ActivityGroupId")] = true
			end
		end
		local pairCount = 0
		for _ in pairs(pairsSeen) do
			pairCount = pairCount + 1
		end
		assert(pairCount >= 1 and pairCount <= A.MaxPairs)
		pro.ranch.activities, pro.ranch.nextGroupAt, pro.ranch.groupSerial = {}, 0, 2
		g.ranch:updateRecords(a, g:now())
		local napCount, element = 0, nil
		for _, entry in ipairs(g.ranch:visiblePets(a)) do
			if entry.record:GetAttribute("ActivityKind") == "GroupNap" then
				napCount = napCount + 1
				element = element or entry.item.element
				assert(entry.item.element == element and entry.item.rarity ~= "Godly")
			end
		end
		assert(napCount >= 2 and napCount <= A.NapMembers)
	end)

	scenario("Living Ranch removes interrupted partner links when a resident becomes active", function()
		local pro = g.profiles[a]
		local selected
		for _, entry in ipairs(g.ranch:visiblePets(a)) do
			if entry.record:GetAttribute("ActivityPartnerId") then
				selected = entry
				break
			end
		end
		assert(selected, "Pair fixture did not form")
		local partnerId = selected.record:GetAttribute("ActivityPartnerId")
		assert(g:setPetMode(a, partnerId, "Active"))
		g.ranch:updateRecords(a, g:now())
		assert(selected.record:GetAttribute("ActivityPartnerId") == nil)
		assert(pro.ranch.activities[partnerId] == nil)
		for _, entry in ipairs(g.ranch:visiblePets(a)) do
			local partner = entry.record:GetAttribute("ActivityPartnerId")
			if partner then
				assert(g.petRecords[partner]:GetAttribute("ActivityPartnerId") == entry.item.id)
			end
		end
	end)

	scenario(
		"Living Ranch return greeting uses a real absence and does not repeat while the owner stays home",
		function()
			local pro = g.profiles[a]
			place(a, CFrame.new(0, 4, 30))
			assert(waitFor(function()
				return pro.ranch.wasHome == false and pro.ranch.leftAt ~= nil
			end, 3))
			local departed = pro.ranch.leftAt
			assert(waitFor(function()
				return g:now() - departed >= C.HomeAwayTime + 0.1
			end, C.HomeAwayTime + 3))
			place(a, CFrame.new(pro.base.center + Vector3.new(0, 4, 0)))
			assert(waitFor(function()
				return pro.ranch.wasHome and pro.ranch.greetUntil > g:now()
			end, 3))
			local deadline = pro.ranch.greetUntil
			task.wait(C.RanchTick + 0.1)
			assert(pro.ranch.greetUntil == deadline)
		end
	)

	scenario("Living Ranch rejects stale owner and expired activity snapshots without invalid geometry", function(items)
		local record = assert(g.petRecords:FindFirstChild(items[2].id))
		local data = assert(Motion.read(record))
		assert(Motion.valid(data, g:now()))
		data.activityOwner = b.UserId
		assert(not Motion.valid(data, g:now()))
		assert(R.vector(Motion.pose(data, g:now(), g.ranch.activities:godlies(a.UserId)).Position))
		data = assert(Motion.read(record))
		data.ends = data.started - 1
		assert(not Motion.valid(data, g:now()))
		assert(R.vector(Motion.pose(data, g:now(), g.ranch.activities:godlies(a.UserId)).Position))
		local pro = g.profiles[a]
		g.ranch:setup(a)
		assert(next(pro.ranch.activities) == nil and record:GetAttribute("ActivityKind") == nil)
		g.ranch:updateRecords(a, g:now())
		assert(record:GetAttribute("ActivityOwnerUserId") == a.UserId)
	end)

	scenario(
		"Living Ranch homecoming and milestones are independently rate-limited without authority changes",
		function()
			local pro = g.profiles[a]
			local inventory = signature(g, a)
			local coins, remainder, speed = pro.money.Value, pro.coinRemainder, pro.speed.Value
			-- No waits occur between these production calls and assertions.
			assert(g.ranch:homecoming(a, "return"))
			local untilTime = pro.ranch.greetUntil
			assert(not g.ranch:homecoming(a, "return"))
			assert(not g.ranch:homecoming(a, "respawn"))
			assert(pro.ranch.greetUntil == untilTime)
			assert(g.ranch:homecoming(a, "record"))
			assert(not g.ranch:homecoming(a, "record"))
			assert(not g.ranch:homecoming(a, "unsupported"))
			g.ranch:updateRecords(a, g:now())
			assert(signature(g, a) == inventory)
			assert(pro.money.Value == coins and pro.coinRemainder == remainder and pro.speed.Value == speed)
		end
	)

	scenario(
		"Living Ranch training spectators follow authoritative training without changing progression",
		function(items)
			local pro = g.profiles[a]
			place(a, CFrame.new(pro.base.treadmill.Position + Vector3.new(0, 3, 0)))
			assert(
				waitFor(function()
					return pro.training == true
				end, 3),
				"Real treadmill training did not begin"
			)
			local companion = assert(g.petRecords:FindFirstChild(items[10].id))
			local watchers = 0
			assert(
				waitFor(function()
					watchers = 0
					for _, entry in ipairs(g.ranch:visiblePets(a)) do
						if entry.record:GetAttribute("ActivityKind") == "TrainingWatch" then
							watchers = watchers + 1
						end
					end
					return watchers > 0 and companion:GetAttribute("CompanionActivity") == "Training"
				end, A.MilestoneSeconds + A.HomecomingSeconds + 4),
				"Training reaction did not follow higher-priority celebrations"
			)
			local inventory, speed, coins, charge = signature(g, a), pro.speed.Value, pro.money.Value, pro.lab.charge
			g.ranch:updateRecords(a, g:now())
			assert(watchers <= A.MaxSpectators)
			assert(companion:GetAttribute("CompanionActivity") == "Training")
			assert(companion:GetAttribute("CompanionTarget") == pro.base.treadmill.Position)
			assert(signature(g, a) == inventory and pro.speed.Value == speed and pro.money.Value == coins)
			assert(pro.lab.charge == charge)
			place(a, CFrame.new(pro.base.center + Vector3.new(0, 4, 0)))
			assert(waitFor(function()
				return pro.training == false
			end, 3))
			g.ranch:updateRecords(a, g:now())
			assert(companion:GetAttribute("CompanionActivity") ~= "Training")
			for _, entry in ipairs(g.ranch:visiblePets(a)) do
				assert(entry.record:GetAttribute("ActivityKind") ~= "TrainingWatch")
			end
		end
	)

	scenario("Living Ranch sampled activity stays inside pens and respects every Godly exclusion", function()
		local godlies = g.ranch.activities:godlies(a.UserId)
		local now = g:now()
		for _, entry in ipairs(g.ranch:visiblePets(a)) do
			local data = assert(Motion.read(entry.record))
			for sample = 0, 40 do
				local cf = Motion.pose(data, now + sample * 0.25, godlies)
				local pos = cf.Position
				assert(R.vector(pos))
				assert(math.abs(pos.X - data.center.X) <= data.bounds.X + 0.01)
				assert(math.abs(pos.Z - data.center.Z) <= data.bounds.Y + 0.01)
				if not data.godly then
					for _, anchor in ipairs(godlies) do
						assert(Vector2.new(pos.X - anchor.X, pos.Z - anchor.Z).Magnitude >= C.GodlyDistance - 0.01)
					end
				end
			end
		end
	end)

	scenario(
		"Living Ranch paging and active switches prune activities without losing ownership or income",
		function(items)
			local pro = g.profiles[a]
			local count, income = #g.inventory:list(a.UserId), g.inventory:income(a.UserId)
			assert(pro.penPages > 1)
			assert(g:setPenPage(a, 2))
			g.ranch:updateRecords(a, g:now())
			for id in pairs(pro.ranch.activities) do
				local record = assert(g.petRecords:FindFirstChild(id))
				assert(record:GetAttribute("Displayed") and record:GetAttribute("DisplayMode") == "Pen")
			end
			assert(g:setPetMode(a, items[2].id, "Active"))
			g.ranch:updateRecords(a, g:now())
			assert(pro.ranch.activities[items[2].id] == nil)
			local active = 0
			for _, item in ipairs(g.inventory:list(a.UserId)) do
				if item.kind == "Pet" and item.petMode == "Active" then
					active = active + 1
				end
			end
			assert(active == 1 and #g.inventory:list(a.UserId) == count and g.inventory:income(a.UserId) == income)
		end
	)

	scenario("Living Ranch activities yield to welcome parties and same-element Godly reverence", function(items)
		local pro, now = g.profiles[a], g:now()
		pro.ranch.welcomeUntil, pro.ranch.welcomeIds = now + 4, { items[2].id }
		g.ranch:updateRecords(a, now)
		assert(g.petRecords[items[2].id]:GetAttribute("BehaviorState") == "Greet")
		assert(g.petRecords[items[2].id]:GetAttribute("WelcomeMember") == true)
		assert(not g.ranch:startReverence(a, true))
		pro.ranch.welcomeUntil, pro.ranch.visitorCooldown = 0, 0
		assert(g.ranch:startReverence(a, true))
		g.ranch:updateRecords(a, g:now())
		for _, entry in ipairs(g.ranch:visiblePets(a)) do
			local expected = entry.item.id == pro.ranch.reverencePet and "Ascend"
				or (entry.item.element == "Fire" and entry.item.rarity ~= "Godly" and "Revere" or "Idle")
			assert(entry.record:GetAttribute("BehaviorState") == expected)
			assert(entry.record:GetAttribute("ActivityKind") == nil)
		end
	end)

	scenario(
		"Living Ranch earnings include hidden and active owned pets while visitor sampling stays read-only",
		function(items)
			local total = 0
			for _, item in ipairs(g.inventory:list(a.UserId)) do
				if item.kind == "Pet" then
					total = total + 1
				end
			end
			local text = g.profiles[a].base.earningsLabel.Text
			assert(text:find(tostring(total) .. " pets", 1, true))
			assert(text:find("+" .. g.inventory:income(a.UserId) .. " Coins/min", 1, true))
			local record = assert(g.petRecords:FindFirstChild(items[2].id))
			local before = signature(g, a)
			assert(R.vector(g.ranch.activities:position(record, a)))
			assert(g.ranch.activities:position(record, b) == nil)
			assert(signature(g, a) == before)
		end
	)

	scenario("Living Ranch habitat preferences use each pet's own element and current layout only", function(items)
		local pro = g.profiles[a]
		local before, income = signature(g, a), g.inventory:income(a.UserId)
		for _, index in ipairs({ 2, 4, 5, 6 }) do
			local item = items[index]
			local entry = { item = item, record = assert(g.petRecords:FindFirstChild(item.id)) }
			local plan
			for _ = 1, 5 do
				plan = g.ranch.activities:solo(pro, entry, g:now(), g.ranch.activities:godlies(a.UserId))
				if plan.habitat then
					break
				end
			end
			assert(plan and plan.habitat == item.element)
			assert(plan.siteAnchor == pro.base.activitySites[item.element].anchor)
		end
		local oldSite = pro.base.activitySites.Fire
		pro.base.applyExpansion(pro.ranchLevel)
		local current = pro.base.activitySites.Fire
		assert(current.area ~= oldSite.area and current.layout ~= oldSite.layout)
		pro.base.activitySites.Fire = oldSite
		assert(g.ranch.activities:site(pro, "Fire") == nil)
		pro.base.activitySites.Fire = current
		assert(g.ranch.activities:site(pro, "Fire") == current)
		assert(signature(g, a) == before and g.inventory:income(a.UserId) == income)
	end)

	scenario("Living Ranch reservation clears presentation eligibility without changing ownership", function(items)
		local item = items[2]
		local pro = g.profiles[a]
		local key = "ranch-reservation-" .. tostring(g:now())
		assert(g.inventory:reserveOffer(a.UserId, { item.id }, key, "Trade"))
		g:reconcilePets()
		local record = assert(g.petRecords:FindFirstChild(item.id))
		local before = signature(g, a)
		g.ranch:updateRecords(a, g:now())
		assert(pro.ranch.activities[item.id] == nil and record:GetAttribute("ActivityKind") == nil)
		assert(record:GetAttribute("Displayed") == false and item.ownerId == a.UserId)
		assert(signature(g, a) == before and item.state == "Trade")
		g.inventory:release(key)
		g:reconcilePets()
		g.ranch:updateRecords(a, g:now())
		assert(item.state == "Inventory" and record:GetAttribute("ActivityOwnerUserId") == a.UserId)
	end)

	scenario(
		"Living Ranch actual inventory transfer discards the old owner's activity and keeps income accounting",
		function(items)
			local item = items[2]
			local key = "ranch-transfer-" .. tostring(g:now())
			local total = #g.inventory:list(a.UserId) + #g.inventory:list(b.UserId)
			local income = g.inventory:income(a.UserId) + g.inventory:income(b.UserId)
			assert(g.inventory:reserveOffer(a.UserId, { item.id }, key, "Trade"))
			assert(g.inventory:transfer(key, a.UserId, { item.id }, b.UserId, {}))
			g:reconcilePets()
			local beforeA, beforeB = signature(g, a), signature(g, b)
			g.ranch:updateRecords(a, g:now())
			g.ranch:updateRecords(b, g:now())
			local record = assert(g.petRecords:FindFirstChild(item.id))
			assert(item.ownerId == b.UserId and record:GetAttribute("OwnerUserId") == b.UserId)
			assert(g.profiles[a].ranch.activities[item.id] == nil)
			assert(record:GetAttribute("ActivityOwnerUserId") == b.UserId)
			assert(signature(g, a) == beforeA and signature(g, b) == beforeB)
			assert(#g.inventory:list(a.UserId) + #g.inventory:list(b.UserId) == total)
			assert(g.inventory:income(a.UserId) + g.inventory:income(b.UserId) == income)
		end
	)

	scenario("Living Ranch rest poses and ordinary episode changes never manufacture a landing hint", function(items)
		local pro, item = g.profiles[a], items[2]
		local entry = { item = item, record = assert(g.petRecords:FindFirstChild(item.id)) }
		local now, gods = g:now(), g.ranch.activities:godlies(a.UserId)
		for _, kind in ipairs({
			"Idle",
			"Explore",
			"HabitatRest",
			"GroupNap",
			"GateWatch",
			"TrainingWatch",
			"Homecoming",
		}) do
			local home = entry.record:GetAttribute("PenPosition")
			local plan =
				g.ranch.activities:make(pro, entry, kind, home, pro.base.penGate.Position, now, A.EpisodeSeconds, gods)
			g.ranch.activities:publish(entry, plan, kind == "GroupNap" and "Rest" or "Idle", now)
			local data = assert(Motion.read(entry.record))
			for sample = 0, 32 do
				local cf, _, landing = Motion.pose(data, now + sample * A.EpisodeSeconds / 32, gods)
				assert(R.vector(cf.Position) and not landing, kind .. " manufactured a landing event")
			end
		end
	end)

	scenario(
		"Living Ranch active switches clear stale companion metadata and keep exactly one follower",
		function(items)
			local pro = g.profiles[a]
			for _, item in ipairs({ items[2], items[3], items[4], items[5] }) do
				assert(g:setPetMode(a, item.id, "Active"))
				g.ranch:updateRecords(a, g:now())
				local active = 0
				for _, record in ipairs(g.petRecords:GetChildren()) do
					if record:GetAttribute("OwnerUserId") == a.UserId then
						if record:GetAttribute("DisplayMode") == "Active" then
							active = active + 1
							assert(record.Name == item.id and record:GetAttribute("CompanionOwnerUserId") == a.UserId)
						else
							assert(record:GetAttribute("CompanionOwnerUserId") == nil)
						end
					end
				end
				assert(active == 1 and pro.activePetId == item.id)
			end
		end
	)

	scenario("Real client renders Living Ranch activity within bounds using exact owner identity", function()
		local ids = {}
		for _, entry in ipairs(g.ranch:visiblePets(a)) do
			table.insert(ids, entry.item.id)
		end
		local token = "living-ranch-render-" .. tostring(g:now())
		g:feed(a, "ranchActivityProbe", { token = token, ids = ids })
		assert(
			waitFor(function()
				local diag = g.clientDiagnostics[a]
				return diag and diag.token == token
			end, 9),
			"No real-client Living Ranch observation was received"
		)
		local diag = g.clientDiagnostics[a]
		results.livingRanchClient = diag
		assert(diag.passed, diag.error)
		assert(diag.samples == 16 and diag.observed == #ids and diag.moved and diag.limbMoved)
		assert(diag.habitatCount == #C.ElementOrder and diag.habitatParts <= A.MaxHabitatParts)
	end)
end

function Checks.afterDisconnect(g, check, context)
	check("Actual owner disconnect clears ranch activities and the vacant earnings board", function()
		local base = assert(context.base)
		assert(
			waitFor(function()
				return g.profiles[context.player] == nil
					and base.owner == nil
					and base.model:GetAttribute("ActivityResidentCount") == 0
					and base.earningsLabel.Text == "YOUR RANCH\n0 pets • +0 Coins/min"
			end, 3),
			"Actual departing-owner ranch cleanup did not settle"
		)
		for _, record in ipairs(g.petRecords:GetChildren()) do
			assert(record:GetAttribute("ActivityOwnerUserId") ~= context.userId)
			assert(record:GetAttribute("CompanionOwnerUserId") ~= context.userId)
		end
	end)
end

return Checks
