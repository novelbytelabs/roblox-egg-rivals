-- Real-engine service and client-input regressions. Fixture setup never replaces validators.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").Stage3Shared
local C = require(Shared.Config)
local Rules = require(Shared.Rules)
local PetMotion = require(Shared.PetMotion)
local MotionRules = require(Shared.MotionRules)
local Checks = {}
local function copy(v)
	if type(v) ~= "table" then
		return v
	end
	local out = {}
	for k, x in pairs(v) do
		out[k] = copy(x)
	end
	return out
end
function Checks.run(g, check, a, b, results)
	assert(RunService:IsStudio() and workspace:GetAttribute("Stage3AutoTest"))
	local function waitFor(fn, seconds)
		local untilTime = os.clock() + seconds
		repeat
			if fn() then
				return true
			end
			task.wait(0.05)
		until os.clock() > untilTime
		return false
	end
	-- The real client owns input. A server-created hold acknowledgement is intentionally
	-- canceled by HoldController when no input owns its nonce. Never disable that guard.
	local probeSerial = 0
	local function clientHold(p, kind, itemId, duration, earlyCheck)
		probeSerial += 1
		local token = "hold-input-" .. probeSerial .. "-" .. tostring(g:now())
		local started = g:now()
		g:push(p)
		if kind == "exchange" then
			g:feed(p, "openExchange", {})
		end
		g:feed(p, "completionInputProbe", {
			token = token,
			kind = "Hold",
			holdKind = kind,
			itemId = itemId,
			duration = duration,
			sessionId = g.profiles[p].trade and g.profiles[p].trade.id,
		})
		local h
		local observed = waitFor(function()
			local active = g.holds.active[p]
			if active and active.started >= started then
				h = active
				return true
			end
			local diag = g.clientDiagnostics[p]
			return diag and diag.token == token
		end, 4)
		if not h then
			local diag = g.clientDiagnostics[p]
			if diag and diag.token == token then
				results.livingClientDiagnostics = results.livingClientDiagnostics or {}
				table.insert(results.livingClientDiagnostics, diag)
				error(diag.error or "Client finished without an observed real hold")
			end
		end
		assert(observed and h, "Real client did not start " .. kind .. " hold")
		assert(h.duration == duration, "Server changed the required hold duration")
		assert(g:now() - h.started < duration, "Early-confirmation check missed the live hold")
		if earlyCheck then
			earlyCheck(h)
		end
		assert(
			waitFor(function()
				return g.clientDiagnostics[p] and g.clientDiagnostics[p].token == token
			end, duration + 7),
			"Real client hold result was not received"
		)
		local diag = g.clientDiagnostics[p]
		results.livingClientDiagnostics = results.livingClientDiagnostics or {}
		table.insert(results.livingClientDiagnostics, diag)
		assert(diag.passed, diag.error)
		assert(diag.nonce == h.nonce and diag.holdToken == h.token, "Client/server hold identities differ")
		assert(g:now() - h.started >= duration, "Hold completed before real elapsed time")
		return h
	end
	local function tooEarly(ok, err)
		assert(
			not ok and err == "Keep holding to confirm.",
			"Early hold was not rejected by the timer: " .. tostring(err)
		)
	end
	local fixtureSerial = 0
	local function near(p, pos)
		fixtureSerial += 1
		local token = "fixture-position-" .. fixtureSerial .. "-" .. tostring(g:now())
		local started = g:now()
		local attempts = 1
		local nextReassert = started + 0.6
		g:teleport(p, CFrame.new(pos))
		g:feed(p, "completionInputProbe", { token = token, kind = "Position", target = pos })
		local stableSince
		local settled = waitFor(function()
			local root = g:root(p)
			local offset = root and root.Position - pos
			local serverNear = offset and Vector2.new(offset.X, offset.Z).Magnitude <= 3 and math.abs(offset.Y) <= 6
			if serverNear then
				stableSince = stableSince or g:now()
			else
				stableSince = nil
				if attempts < 3 and g:now() >= nextReassert then
					attempts += 1
					nextReassert = g:now() + 0.6
					g:teleport(p, CFrame.new(pos))
				end
			end
			local diag = g.clientDiagnostics[p]
			if not diag or diag.token ~= token then
				return false
			end
			if not diag.passed then
				return true
			end -- Preserve the observed failure below.
			return stableSince and g:now() - stableSince >= 0.25
		end, 5)
		local root = g:root(p)
		local diag = g.clientDiagnostics[p]
		local observed = diag and diag.token == token and diag or nil
		results.fixturePositions = results.fixturePositions or {}
		table.insert(results.fixturePositions, {
			token = token,
			userId = p.UserId,
			target = { pos.X, pos.Y, pos.Z },
			server = root and { root.Position.X, root.Position.Y, root.Position.Z } or nil,
			client = observed,
			elapsed = g:now() - started,
			attempts = attempts,
			teleportSerial = g.profiles[p].teleportSerial,
		})
		assert(
			settled and observed and observed.passed and stableSince,
			"Fixture position did not settle after "
				.. attempts
				.. " server placement attempt(s): target="
				.. tostring(pos)
				.. " server="
				.. tostring(root and root.Position)
				.. " client="
				.. tostring(observed and observed.error)
		)
	end
	local function quiet()
		for _, p in ipairs({ a, b }) do
			g.incubation:cancel(p)
			g.trades:cancel(p)
			if g.profiles[p].exchange then
				g:exchangeCancel(p)
			end
			if g.profiles[p].trial then
				g.trials:finish(p, false, "Fixture cleanup")
			end
			if g.carry[p] then
				g:resetEgg(g.carry[p])
			end
			g.holds:cancel(p)
		end
		if g.duels.current then
			g.duels:finish(nil, "Fixture cleanup")
		end
	end
	local function scenario(name, fn)
		check(name, function()
			quiet()
			local saved = {}
			for _, p in ipairs({ a, b }) do
				local pro = g.profiles[p]
				saved[p] = {
					position = g:root(p).CFrame,
					tier = pro.tier,
					speed = pro.speed.Value,
					money = pro.money.Value,
					remainder = pro.coinRemainder,
					hatched = pro.hatched,
					onboard = pro.onboardingComplete,
					level = pro.ranchLevel,
					page = pro.penPage,
					active = pro.activePetId,
					lab = copy(pro.lab),
					ranch = copy(pro.ranch),
					best = copy(pro.bestTrial),
					rates = copy(pro.rates),
					tradeCooldown = pro.tradeCooldown,
					tutorial = pro.tutorial,
				}
			end
			local ids = {}
			local worldEggs = {}
			local oldPhase = g.phaseEnds
			local oldNight = workspace:GetAttribute("Night") == true
			local oldBoss = workspace:GetAttribute("BossEnabled")
			g:setNight(false)
			g.phaseEnds = g:now() + 3600
			workspace:SetAttribute("BossEnabled", false)
			local function item(p, kind, rarity, creature, element)
				local value, err
				if kind == "Item" then
					value, err = g.inventory:createConsumable(p.UserId, "SnarePod")
				else
					value, err =
						g.inventory:create(p.UserId, kind, rarity or "Common", creature or "Skunk", element or "Earth")
				end
				assert(value, err)
				ids[value.id] = true
				value.order = -1000 + #g.inventory:list(p.UserId)
				return value
			end
			local function egg(p)
				local nest = {
					id = "regression-" .. tostring(g:now()),
					position = Vector3.new(0, 2.4, 45),
					event = false,
					creature = "Dragon",
				}
				g:spawnEgg(nest, "Common", "Dragon")
				table.insert(worldEggs, nest.egg)
				near(p, nest.position + Vector3.new(0, 2, -3))
				assert(g:take(p, nest.egg.id))
				return nest.egg
			end
			local function atPost()
				near(a, g.world.tradingPost.Position + Vector3.new(-3, 2, 4))
				near(b, g.world.tradingPost.Position + Vector3.new(3, 2, 4))
				for _, p in ipairs({ a, b }) do
					local pro = g.profiles[p]
					pro.onboardingComplete = true
					pro.hatched = 3
					pro.tradeCooldown = 0
					pro.rates = {}
				end
			end
			local function trade(x, y)
				atPost()
				assert(g:action(a, "tradeRequest", { userId = b.UserId }))
				assert(g.trades:reply(b, true))
				assert(g.trades:offer(a, { x.id }, g.profiles[a].trade.revision))
				assert(g.trades:offer(b, { y.id }, g.profiles[b].trade.revision))
				return g.profiles[a].trade
			end
			local ok, err = xpcall(function()
				fn(item, egg, atPost, trade, near, waitFor)
			end, debug.traceback)
			local cleanOK, cleanErr = xpcall(function()
				quiet()
				for _, e in ipairs(worldEggs) do
					if g.eggs[e.id] then
						g:retireEgg(e)
					end
				end
				for _, p in ipairs({ a, b }) do
					local pro = g.profiles[p]
					for element, inc in pairs(pro.incubations) do
						if ids[inc.itemId] then
							inc.model:Destroy()
							pro.incubations[element] = nil
						end
					end
				end
				for id in pairs(ids) do
					g.inventory.items[id] = nil
				end
				for _, p in ipairs({ a, b }) do
					local pro, s = g.profiles[p], saved[p]
					pro.tier = s.tier
					pro.speed.Value = s.speed
					pro.money.Value = s.money
					pro.coinRemainder = s.remainder
					pro.hatched = s.hatched
					pro.onboardingComplete = s.onboard
					pro.ranchLevel = s.level
					pro.penPage = s.page
					pro.activePetId = s.active
					pro.lab = s.lab
					pro.ranch = s.ranch
					pro.bestTrial = s.best
					pro.rates = s.rates
					pro.tradeCooldown = s.tradeCooldown
					pro.tutorial = s.tutorial
					pro.base.applyGrade(s.tier)
					pro.base.applyExpansion(s.level)
					pro.training = false
					p:SetAttribute("Busy", false)
					g:teleport(p, s.position)
					g:applySpeed(p)
				end
				g.ranch.nextTick = 0
				g:reconcilePets()
				g:pushAll()
				g:setNight(oldNight)
				g.phaseEnds = math.max(oldPhase, g:now() + 30)
				workspace:SetAttribute("BossEnabled", oldBoss)
			end, debug.traceback)
			assert(cleanOK, "Fixture cleanup failed: " .. tostring(cleanErr))
			assert(ok, err)
		end)
	end

	scenario("Speed Lab enforces all seven grade caps without losing ownership", function()
		local pro = g.profiles[a]
		local count = #g.inventory:list(a.UserId)
		for tier, grade in ipairs(C.Grades) do
			pro.tier = tier
			pro.speed.Value = grade.cap - 1
			g.speedLab:setup(pro)
			pro.training = true
			g.speedLab:step(a, 5, g:now())
			assert(pro.speed.Value == grade.cap and pro.lab.fraction == 0)
			g.speedLab:step(a, 5, g:now())
			assert(pro.speed.Value == grade.cap)
		end
		assert(#g.inventory:list(a.UserId) == count)
	end)
	scenario("Overdrive works with a carried egg, rejects repeat activation, and expires", function(_, egg)
		local carried = egg(a)
		local pro = g.profiles[a]
		pro.tier = 7
		pro.speed.Value = C.SpeedCap
		pro.lab.charge = 100
		assert(g:action(a, "overdrive", {}))
		assert(g.carry[a] == carried and pro.lab.charge == 0 and g:humanoid(a).WalkSpeed == C.OverdriveCap)
		assert(not g.speedLab:activate(a))
		pro.lab.untilTime = g:now() - 0.01
		g.speedLab:step(a, 0, g:now())
		assert(g:humanoid(a).WalkSpeed == C.WalkSpeedCap and pro.lab.untilTime == 0)
	end)
	scenario("Overdrive refuses real duel selection and trial activity without consuming charge", function()
		near(a, Vector3.new(-2, 4, 0))
		near(b, Vector3.new(2, 4, 0))
		local pro = g.profiles[a]
		pro.lab.charge = 100
		assert(g.duels:request(a, b))
		assert(not g.speedLab:activate(a))
		assert(pro.lab.charge == 100)
		assert(g.duels:cancel(a))
		near(a, g.world.trialStart.Position + Vector3.new(0, 3, 0))
		assert(g.trials:start(a))
		assert(not g.speedLab:activate(a))
		assert(g:humanoid(a).WalkSpeed == C.TrialSpeed and pro.lab.charge == 100)
	end)
	scenario("Motion Energy powers the camp without changing Coins or pet income", function()
		local pro = g.profiles[a]
		pro.training = true
		g.speedLab:setup(pro)
		local money, income = pro.money.Value, g.inventory:income(a.UserId)
		g.speedLab:step(a, 22.5, g:now())
		assert(pro.lab.energy == 0)
		g.speedLab:step(a, 20, g:now())
		assert(pro.lab.energy > 0 and pro.lab.energy <= 100)
		assert(pro.money.Value == money and g.inventory:income(a.UserId) == income)
		local before = pro.lab.energy
		pro.training = false
		g.speedLab:step(a, 2, g:now())
		assert(pro.lab.energy < before)
	end)
	scenario(
		"Incubator preview and real timed confirmation preserve creature, rarity and chosen element",
		function(item)
			local value = item(a, "Egg", "Rare", "Dragon")
			near(a, g.profiles[a].base.incubators.Water.pad.Position + Vector3.new(0, 3, 0))
			assert(g:action(a, "incubate", { id = value.id, element = "Water" }))
			local v = g.profiles[a].incubatorPreview
			assert(v and value.state == "Inventory")
			local h = clientHold(a, "incubator", value.id, C.IncubatorHold, function(active)
				tooEarly(g.incubation:confirm(a, v.id, active.token))
				assert(value.state == "Inventory" and g.profiles[a].incubatorPreview == v)
			end)
			assert(
				value.state == "Incubating"
					and value.creature == "Dragon"
					and value.rarity == "Rare"
					and value.element == "Water"
			)
			assert(not g.incubation:confirm(a, v.id, h.token))
		end
	)
	scenario("Unsolicited hold acknowledgements are canceled without committing inventory", function(item)
		local value = item(a, "Egg", "Rare", "Dragon")
		near(a, g.profiles[a].base.incubators.Water.pad.Position + Vector3.new(0, 3, 0))
		assert(g.incubation:preview(a, "Water", value.id))
		local v = g.profiles[a].incubatorPreview
		assert(g.incubation:hold(a, v.id, "unsolicited-regression"))
		local token = g.holds.active[a].token
		assert(
			waitFor(function()
				return g.holds.active[a] == nil
			end, 2),
			"Unowned acknowledgement was not canceled"
		)
		assert(not g.incubation:confirm(a, v.id, token))
		assert(value.state == "Inventory" and value.ownerId == a.UserId)
	end)

	scenario("Incubator preview rejects foreign eggs, wrong camp and stale changed items", function(item)
		local value = item(a, "Egg", "Common", "Lizard")
		near(b, g.profiles[a].base.incubators.Fire.pad.Position + Vector3.new(0, 3, 0))
		assert(not g.incubation:preview(b, "Fire", value.id))
		near(a, g.profiles[a].base.incubators.Fire.pad.Position + Vector3.new(0, 3, 0))
		assert(g.incubation:preview(a, "Fire", value.id))
		local v = g.profiles[a].incubatorPreview
		assert(g.incubation:hold(a, v.id, "inc-changed"))
		local h = g.holds.active[a]
		assert(g.inventory:setLocked(a.UserId, value.id, true))
		assert(not g.incubation:confirm(a, v.id, h.token))
		assert(value.state == "Inventory" and value.element == nil)
	end)
	scenario("Incubator cancels on departure and does not auto-secure a carried egg", function(_, egg)
		local carried = egg(a)
		near(a, g.profiles[a].base.incubators.Earth.pad.Position + Vector3.new(0, 3, 0))
		task.wait(0.3)
		assert(g.carry[a] == carried and not g.profiles[a].incubations.Earth)
		assert(g.incubation:preview(a, "Earth"))
		local v = g.profiles[a].incubatorPreview
		assert(g.incubation:hold(a, v.id, "inc-away"))
		near(a, g.profiles[a].base.spawn.Position)
		g.incubation:step()
		assert(not g.profiles[a].incubatorPreview and g.carry[a] == carried and not g.holds.active[a])
	end)

	scenario(
		"Trading unlock requires onboarding and three hatches; invalid targets are rejected",
		function(_, _, atPost)
			atPost()
			g.profiles[a].hatched = 2
			assert(not g.trades:request(a, b))
			g.profiles[a].hatched = 3
			g.profiles[a].onboardingComplete = false
			assert(not g.trades:request(a, b))
			g.profiles[a].onboardingComplete = true
			assert(not g.trades:request(a, a) and not g.trades:request(a, nil))
		end
	)
	scenario(
		"Trading request dispatch resolves actual Studio Player IDs and revisioned offers",
		function(item, _, _, trade)
			local x = item(a, "Pet", "Rare", "Gorilla", "Wind")
			local y = item(b, "Egg", "Epic", "Dragon")
			local s = trade(x, y)
			assert(g.trades:snapshot(a).mine[1].id == x.id and g.trades:snapshot(a).theirs[1].id == y.id)
			local stale = s.revision - 1
			assert(not g.trades:offer(a, {}, stale))
			assert(x.state == "Trade" and y.state == "Trade")
			assert(g.trades:cancel(a))
			assert(
				x.ownerId == a.UserId and y.ownerId == b.UserId and x.state == "Inventory" and y.state == "Inventory"
			)
		end
	)
	scenario("Trading refuses locked, active, foreign, duplicate and stale instance offers", function(item, _, atPost)
		local x = item(a, "Pet", "Common", "Skunk", "Fire")
		local y = item(b, "Egg", "Rare", "Lizard")
		local locked = item(a, "Pet", "Epic", "Dragon", "Fire")
		assert(g.inventory:setLocked(a.UserId, locked.id, true))
		g:reconcilePets()
		assert(g:setPetMode(a, x.id, "Active"))
		atPost()
		assert(g.trades:request(a, b))
		assert(g.trades:reply(b, true))
		local s = g.profiles[a].trade
		for _, ids in ipairs({ { x.id }, { locked.id }, { y.id }, { "missing-instance" }, { y.id, y.id } }) do
			assert(not g.trades:offer(a, ids, s.revision))
		end
		assert(x.ownerId == a.UserId and locked.locked and y.ownerId == b.UserId)
	end)
	scenario(
		"Trading uses two real three-second holds and commits both offers exactly once",
		function(item, _, _, trade)
			local x = item(a, "Pet", "Rare", "Skunk", "Fire")
			local y = item(b, "Pet", "Epic", "Dragon", "Water")
			trade(x, y)
			local incomeA = g.inventory:income(a.UserId)
			local ha = clientHold(a, "trade", x.id, 3, function(active)
				tooEarly(g.trades:completeHold(a, active.token, "Base"))
			end)
			assert(g.profiles[a].trade.ready[a] and not g.profiles[a].trade.ready[b])
			assert(x.ownerId == a.UserId and y.ownerId == b.UserId)
			assert(not g.trades:completeHold(a, ha.token, "Base"))
			local hb = clientHold(b, "trade", y.id, 3, function(active)
				tooEarly(g.trades:completeHold(b, active.token, "Base"))
				assert(x.ownerId == a.UserId and y.ownerId == b.UserId)
			end)
			assert(ha.duration == 3 and hb.duration == 3)
			assert(x.ownerId == b.UserId and y.ownerId == a.UserId and x.petMode == "Pen" and y.petMode == "Pen")
			assert(g.inventory:income(a.UserId) == incomeA - 40 + 100)
			assert(not g.trades:completeHold(b, hb.token, "Base"))
			assert(y.welcomedOwners[tostring(a.UserId)] and x.welcomedOwners[tostring(b.UserId)])
		end
	)
	scenario("Concurrent real client trade holds commit one atomic exchange", function(item, _, _, trade)
		local x = item(a, "Pet", "Rare", "Skunk", "Fire")
		local y = item(b, "Pet", "Epic", "Dragon", "Water")
		trade(x, y)
		local outcomes = {}
		for _, side in ipairs({ { a, x }, { b, y } }) do
			local target, offer = side[1], side[2]
			task.spawn(function()
				local ok, result = pcall(clientHold, target, "trade", offer.id, 3, function(active)
					tooEarly(g.trades:completeHold(target, active.token, "Base"))
					assert(x.ownerId == a.UserId and y.ownerId == b.UserId)
				end)
				outcomes[target] = { ok = ok, result = result }
			end)
		end
		local overlapped = waitFor(function()
			local ha, hb = g.holds.active[a], g.holds.active[b]
			return ha
				and hb
				and ha.kind == "tradeBase"
				and hb.kind == "tradeBase"
				and ha.duration == 3
				and hb.duration == 3
				and ha.token ~= hb.token
		end, 2)
		-- Let both input probes settle before checking overlap, so a failed overlap
		-- cannot leave input work running inside the following scenario.
		assert(
			waitFor(function()
				return outcomes[a] and outcomes[b]
			end, 15),
			"Concurrent input probes did not finish"
		)
		assert(outcomes[a].ok, outcomes[a].result)
		assert(outcomes[b].ok, outcomes[b].result)
		assert(overlapped, "Two actual client holds never overlapped")
		assert(x.ownerId == b.UserId and y.ownerId == a.UserId)
		assert(x.state == "Inventory" and y.state == "Inventory")
		assert(not g.profiles[a].trade and not g.profiles[b].trade)
		assert(not g.trades:completeHold(a, outcomes[a].result.token, "Base"))
		assert(not g.trades:completeHold(b, outcomes[b].result.token, "Base"))
	end)

	scenario(
		"Godly trade requires the additional real five-second confirmation on both sides",
		function(item, _, _, trade)
			local x = item(a, "Pet", "Godly", "Lizard", "Earth")
			local y = item(b, "Pet", "Mythic", "Dragon", "Wind")
			trade(x, y)
			for _, side in ipairs({ { a, x }, { b, y } }) do
				clientHold(side[1], "trade", side[2].id, 3, function(active)
					tooEarly(g.trades:completeHold(side[1], active.token, "Base"))
					assert(not g.trades:completeHold(side[1], active.token, "Godly"))
				end)
			end
			local s = g.profiles[a].trade
			assert(s.baseReady[a] and s.baseReady[b] and not s.ready[a] and not s.ready[b])
			assert(x.ownerId == a.UserId and y.ownerId == b.UserId)
			local ha = clientHold(a, "trade", x.id, 5, function(active)
				tooEarly(g.trades:completeHold(a, active.token, "Godly"))
			end)
			assert(s.ready[a] and not s.ready[b] and x.ownerId == a.UserId)
			local hb = clientHold(b, "trade", y.id, 5, function(active)
				tooEarly(g.trades:completeHold(b, active.token, "Godly"))
				assert(x.ownerId == a.UserId and y.ownerId == b.UserId)
			end)
			assert(ha.duration == 5 and hb.duration == 5)
			assert(not g.trades:completeHold(b, hb.token, "Godly"))
			assert(x.ownerId == b.UserId and y.ownerId == a.UserId)
		end
	)
	scenario("Offer mutation cancels both pending holds and refuses stale confirmations", function(item, _, _, trade)
		local x = item(a, "Egg", "Rare", "Dragon")
		local y = item(b, "Egg", "Epic", "Lizard")
		local z = item(b, "Egg", "Common", "Skunk")
		local s = trade(x, y)
		assert(g.trades:beginHold(a, "stale-a"))
		assert(g.trades:beginHold(b, "stale-b"))
		local token = g.holds.active[a].token
		assert(g.trades:offer(b, { z.id }, s.revision))
		assert(not g.holds.active[a] and not g.holds.active[b])
		assert(not s.ready[a] and not s.ready[b] and not g.trades:completeHold(a, token, "Base"))
		assert(y.state == "Inventory" and z.state == "Trade")
	end)
	scenario("Trade timeout and lost proximity release exact reservations without transfer", function(item, _, _, trade)
		local x = item(a, "Egg", "Rare", "Skunk")
		local y = item(b, "Egg", "Epic", "Gorilla")
		local s = trade(x, y)
		s.expires = g:now() - 1
		g.trades:step(g:now())
		assert(not g.profiles[a].trade and x.state == "Inventory" and y.state == "Inventory")
		s = trade(x, y)
		near(b, g.profiles[b].base.spawn.Position)
		g.trades:step(g:now())
		assert(not g.profiles[a].trade and x.ownerId == a.UserId and y.ownerId == b.UserId)
	end)
	scenario(
		"Trade disconnect handler cancels final confirmation and preserves both owners",
		function(item, _, _, trade)
			local x = item(a, "Pet", "Rare", "Dragon", "Earth")
			local y = item(b, "Egg", "Epic", "Gorilla")
			trade(x, y)
			assert(g.trades:beginHold(a, "depart-a"))
			assert(g.trades:beginHold(b, "depart-b"))
			g.trades:leaving(b)
			assert(not g.profiles[a].trade and not g.profiles[b].trade)
			assert(not g.holds.active[a] and not g.holds.active[b])
			assert(
				x.ownerId == a.UserId and y.ownerId == b.UserId and x.state == "Inventory" and y.state == "Inventory"
			)
		end
	)

	scenario("Exchange commits pets, eggs and consumables through real timed service confirmation", function(item)
		near(a, g.world.exchangeShop.Position + Vector3.new(0, 2, 4))
		for _, kind in ipairs({ "Pet", "Egg", "Item" }) do
			local value = item(a, kind, "Rare", "Skunk", "Fire")
			local expected = Rules.exchangeValue(value)
			local before, remainder = g.profiles[a].money.Value, g.profiles[a].coinRemainder
			local passiveBefore = before + remainder
			local started = g:now()
			local income = g.inventory:income(a.UserId)
			local changes, previous, exactCredits = {}, before, 0
			local observer = g.profiles[a].money.Changed:Connect(function(current)
				local delta = current - previous
				previous = current
				table.insert(changes, delta)
				if delta == expected then
					exactCredits += 1
				end
			end)
			local ok, h = pcall(clientHold, a, "exchange", value.id, C.ExchangeHold, function(active)
				tooEarly(g:exchangeComplete(a, active.token))
				assert(g.inventory.items[value.id] == value and value.ownerId == a.UserId)
			end)
			observer:Disconnect()
			results.exchangeCreditDiagnostics = results.exchangeCreditDiagnostics or {}
			table.insert(
				results.exchangeCreditDiagnostics,
				{ kind = kind, expected = expected, changes = changes, exactCredits = exactCredits }
			)
			assert(ok, h)
			assert(exactCredits == 1, "Exchange did not credit the exact value exactly once")
			assert(not g.inventory.items[value.id])
			-- Real input also permits real passive-income ticks. Check the exact exchange
			-- credit exactly once through the read-only money-change observer above.
			local after = g.profiles[a].money.Value + g.profiles[a].coinRemainder
			local maxPassive = income / 60 * (g:now() - started + 0.2)
			assert(after >= passiveBefore + expected - 0.001 and after <= passiveBefore + expected + maxPassive)
			assert(not g:exchangeComplete(a, h.token))
		end
	end)
	scenario("Godly Exchange requires five seconds and never accepts active or favorite pets", function(item)
		near(a, g.world.exchangeShop.Position + Vector3.new(0, 2, 4))
		local value = item(a, "Pet", "Godly", "Skunk", "Water")
		g:reconcilePets()
		assert(g:setPetMode(a, value.id, "Active"))
		assert(not g:exchangeBegin(a, value.id, "active"))
		assert(g:setPetMode(a, value.id, "Pen"))
		assert(g.inventory:setLocked(a.UserId, value.id, true))
		assert(not g:exchangeBegin(a, value.id, "locked"))
		assert(g.inventory:setLocked(a.UserId, value.id, false))
		local h = clientHold(a, "exchange", value.id, 5, function(active)
			tooEarly(g:exchangeComplete(a, active.token))
		end)
		assert(h.duration == 5 and not g:exchangeComplete(a, h.token))
		assert(not g.inventory.items[value.id])
	end)
	scenario("Exchange departure and stale item state return the reservation without deleting it", function(item)
		local value = item(a, "Egg", "Epic", "Gorilla")
		near(a, g.world.exchangeShop.Position + Vector3.new(0, 2, 4))
		assert(g:exchangeBegin(a, value.id, "ex-away"))
		local token = g.holds.active[a].token
		near(a, g.profiles[a].base.spawn.Position)
		assert(not g:exchangeComplete(a, token) and value.state == "Inventory" and value.ownerId == a.UserId)
	end)

	scenario("Ranch expansions build real 8, 12, 16 and 24-slot geometry; duplicates cannot charge", function(item)
		local pro = g.profiles[a]
		pro.ranchLevel = 0
		pro.base.applyExpansion(0)
		for _ = 1, 26 do
			item(a, "Pet", "Common", "Skunk", "Earth")
		end
		g:reconcilePets()
		local income = g.inventory:income(a.UserId)
		near(a, g.world.ranchShop.Position + Vector3.new(0, 2, 4))
		assert(#pro.base.penSlots == 8)
		for level = 1, 3 do
			pro.money.Value = 0
			assert(not g.ranch:buyExpansion(a, level))
			pro.money.Value = C.Expansions[level + 1].cost
			assert(g.ranch:buyExpansion(a, level))
			assert(pro.money.Value == 0)
			assert(#pro.base.penSlots == C.Expansions[level + 1].capacity)
			assert(pro.base.model:GetAttribute("PenCapacity") == #pro.base.penSlots)
			assert(not g.ranch:buyExpansion(a, level) and pro.money.Value == 0)
			assert(g.inventory:income(a.UserId) == income)
			for _, pos in ipairs(pro.base.penSlots) do
				assert(math.abs(pos.X - pro.base.penCenter.X) <= pro.base.penBounds.X)
				assert(math.abs(pos.Z - pro.base.penCenter.Z) <= pro.base.penBounds.Y)
			end
		end
	end)
	scenario(
		"Welcome parties batch new acquisitions by time and do not replay for an already-welcomed owner",
		function(item)
			local pro = g.profiles[a]
			g.ranch:setup(a)
			local r = pro.ranch
			local now = g:now()
			local values = {}
			for i = 1, 5 do
				local v = item(a, "Pet", "Common", "Skunk", "Earth")
				table.insert(values, v)
				g.ranch:acquired(a, v)
			end
			assert(#r.queue == 5)
			g.ranch:acquired(a, values[1])
			assert(#r.queue == 5)
			g.ranch.nextTick = 0
			g.ranch:step(now + 1)
			assert(r.welcomeUntil <= now + 1)
			g.ranch.nextTick = 0
			g.ranch:step(now + C.WelcomeBatch + 0.2)
			assert(r.welcomeUntil > now + C.WelcomeBatch and #r.queue == 0)
			assert(r.nextWelcome >= now + C.WelcomeBatch + C.WelcomeGap)
			g.ranch:acquired(a, values[1])
			assert(#r.queue == 0)
		end
	)
	scenario("Godly reverence selects an eligible resident and only same-element non-Godly pets bow", function(item)
		local fire = item(a, "Pet", "Godly", "Dragon", "Fire")
		local water = item(a, "Pet", "Godly", "Skunk", "Water")
		item(a, "Pet", "Common", "Lizard", "Fire")
		item(a, "Pet", "Rare", "Gorilla", "Water")
		g:reconcilePets()
		g.ranch:setup(a)
		local pro = g.profiles[a]
		local now = g:now()
		pro.ranch.greetUntil = 0
		pro.ranch.nextReverence = now - 1
		g.ranch.nextTick = 0
		g.ranch:step(now)
		local chosen = g.inventory.items[pro.ranch.reverencePet]
		assert(chosen and chosen.rarity == "Godly")
		local bowed = 0
		for _, entry in ipairs(g.ranch:visiblePets(a)) do
			local state = entry.record:GetAttribute("BehaviorState")
			if state == "Revere" then
				assert(entry.item.rarity ~= "Godly" and entry.item.element == chosen.element)
				bowed += 1
			end
			if entry.item.id ~= chosen.id and entry.item.rarity == "Godly" then
				assert(state ~= "Play" and state ~= "Revere")
			end
		end
		assert(bowed > 0 and pro.ranch.nextReverence >= now + C.ReverenceMin)
		assert(not g.ranch:startReverence(a, false))
		assert(fire.ownerId == a.UserId and water.ownerId == a.UserId)
	end)
	scenario("Visitor reverence routing accepts Studio players and enforces the ranch cooldown", function(item)
		item(a, "Pet", "Godly", "Dragon", "Fire")
		item(a, "Pet", "Common", "Skunk", "Fire")
		g:reconcilePets()
		g.ranch:setup(a)
		near(b, g.profiles[a].base.penGate.Position + Vector3.new(0, 2, 2))
		assert(g:action(b, "ranchRevere", { userId = a.UserId }))
		local r = g.profiles[a].ranch
		r.reverenceUntil = 0
		assert(not g.ranch:requestReverence(b, a) and r.visitorCooldown > g:now())
	end)
	scenario("Pet poses stay inside expanded pens and outside every Godly exclusion radius", function()
		for _, spec in ipairs(C.Expansions) do
			local center = Vector3.new(0, 0.2, 0)
			local bounds = Vector2.new(spec.width / 2 - 2.5, spec.depth / 2 - 2.5)
			local gods = { Vector3.new(-7.8, 1, -2.75), Vector3.new(7.8, 1, -2.75) }
			local home = Vector3.new(-2.6, 1, 2.75)
			for i = 1, 200 do
				local cf = PetMotion.pose({
					home = home,
					center = center,
					bounds = bounds,
					seed = 17,
					index = 3,
					creature = "Skunk",
					behavior = ({ "Wander", "Play", "Greet", "Revere" })[i % 4 + 1],
					gate = Vector3.new(0, 0, bounds.Y + 2.5),
					target = gods[1],
				}, i * 0.11, gods)
				local pos = cf.Position
				assert(math.abs(pos.X) <= bounds.X + 0.001 and math.abs(pos.Z) <= bounds.Y + 0.001)
				for _, godly in ipairs(gods) do
					assert(Vector3.new(pos.X - godly.X, 0, pos.Z - godly.Z).Magnitude >= C.GodlyDistance - 0.01)
				end
			end
		end
	end)
	scenario("Neon impact classifier requires contact and a full stop, not braking or walking", function()
		assert(not MotionRules.impact(true, 10, 10.1, 0, false, false))
		assert(not MotionRules.impact(true, 10, 10.1, 3, true, false))
		assert(not MotionRules.impact(true, 10, 11, 0, true, false))
		assert(not MotionRules.impact(true, 10, 10.1, 0, true, true))
		assert(MotionRules.impact(true, 10, 10.1, 0, true, false))
		assert(MotionRules.moving(C.Visual.ResumeSpeed + 0.01))
	end)
	scenario("Trial rejects out-of-order gates and teleport discontinuities without replacing a record", function()
		local pro = g.profiles[a]
		local old = pro.bestTrial
		near(a, g.world.trialStart.Position + Vector3.new(0, 3, 0))
		assert(g.trials:start(a))
		assert(not g.trials:gate(a, 2))
		assert(not pro.trial and pro.bestTrial == old)
		near(a, g.world.trialStart.Position + Vector3.new(0, 3, 0))
		assert(g.trials:start(a))
		g:teleport(a, CFrame.new(g.world.trialGates[1]))
		g.trials:step(a, 0.05, g:now())
		assert(not pro.trial and pro.bestTrial == old and not a:GetAttribute("InTrial"))
	end)
	scenario("Client incubation input releases early without committing, then completes an actual hold", function(item)
		local value = item(a, "Egg", "Rare", "Dragon")
		near(a, g.profiles[a].base.incubators.Fire.pad.Position + Vector3.new(0, 3, 0))
		assert(g.incubation:preview(a, "Fire", value.id))
		local token = "incubator-input-" .. tostring(g:now())
		g:feed(a, "completionInputProbe", { token = token, kind = "Incubator", itemId = value.id })
		assert(
			waitFor(function()
				return g.clientDiagnostics[a] and g.clientDiagnostics[a].token == token
			end, 12),
			"Client input probe timed out"
		)
		local diag = g.clientDiagnostics[a]
		results.livingClientDiagnostics = results.livingClientDiagnostics or {}
		table.insert(results.livingClientDiagnostics, diag)
		assert(diag.passed, diag.error)
		assert(value.state == "Incubating" and value.element == "Fire")
	end)
	scenario("Client particle pool reuses existing trail fragments and caps active effects", function()
		g:setNight(true)
		local token = "particle-pool-" .. tostring(g:now())
		g:feed(a, "completionInputProbe", { token = token, kind = "Particles" })
		assert(
			waitFor(function()
				return g.clientDiagnostics[a] and g.clientDiagnostics[a].token == token
			end, 12),
			"Particle probe timed out"
		)
		local diag = g.clientDiagnostics[a]
		results.livingClientDiagnostics = results.livingClientDiagnostics or {}
		table.insert(results.livingClientDiagnostics, diag)
		assert(diag.passed, diag.error)
	end)
	scenario(
		"Client trade cards send revisioned offers and a real mouse hold confirms them",
		function(item, _, _, trade)
			local x = item(a, "Pet", "Rare", "Gorilla", "Fire")
			local y = item(b, "Egg", "Epic", "Dragon")
			trade(x, y)
			local token = "trade-input-" .. tostring(g:now())
			g:feed(a, "completionInputProbe", { token = token, kind = "Trade", itemId = x.id })
			assert(
				waitFor(function()
					return g.clientDiagnostics[a] and g.clientDiagnostics[a].token == token
				end, 14),
				"Trade client probe timed out"
			)
			local diag = g.clientDiagnostics[a]
			results.livingClientDiagnostics = results.livingClientDiagnostics or {}
			table.insert(results.livingClientDiagnostics, diag)
			assert(diag.passed, diag.error)
			assert(g.profiles[a].trade.ready[a] and x.ownerId == a.UserId)
			local h = clientHold(b, "trade", y.id, 3, function(active)
				tooEarly(g.trades:completeHold(b, active.token, "Base"))
			end)
			assert(not g.trades:completeHold(b, h.token, "Base"))
			assert(x.ownerId == b.UserId and y.ownerId == a.UserId)
		end
	)

	scenario("Real client movement completes ordered Trial gates and produces a replayable personal best", function()
		local pro = g.profiles[a]
		pro.bestTrial = nil
		near(a, g.world.trialStart.Position + Vector3.new(0, 3, 0))
		assert(g.trials:start(a))
		local token = "trial-movement-" .. tostring(g:now())
		g:feed(a, "completionInputProbe", { token = token, kind = "Trial", gates = g.world.trialGates })
		assert(
			waitFor(function()
				return g.clientDiagnostics[a] and g.clientDiagnostics[a].token == token
			end, 100),
			"Trial client probe timed out"
		)
		local diag = g.clientDiagnostics[a]
		results.livingClientDiagnostics = results.livingClientDiagnostics or {}
		table.insert(results.livingClientDiagnostics, diag)
		assert(diag.passed, diag.error)
		assert(pro.bestTrial and #pro.bestTrial.frames > 5 and not pro.trial)
		local last = -1
		for _, frame in ipairs(pro.bestTrial.frames) do
			assert(frame.t > last and Rules.vector(frame.position))
			last = frame.t
		end
		results.trialRestoreDiagnostics = {
			inTrial = a:GetAttribute("InTrial"),
			actualWalkSpeed = g:humanoid(a).WalkSpeed,
			expectedWalkSpeed = Rules.speed(pro.speed.Value),
			points = pro.speed.Value,
			slowUntil = pro.slowUntil,
			overdriveUntil = pro.lab.untilTime,
			now = g:now(),
		}
		assert(not a:GetAttribute("InTrial"), "Trial attribute was not cleared")
		-- Humanoid stores WalkSpeed as Float32. Require exact storage-level equality,
		-- not an arbitrary tolerance against a double-precision arithmetic result.
		local expectedStorage = buffer.create(4)
		buffer.writef32(expectedStorage, 0, Rules.speed(pro.speed.Value))
		results.trialRestoreDiagnostics.expectedStoredWalkSpeed = buffer.readf32(expectedStorage, 0)
		assert(
			g:humanoid(a).WalkSpeed == buffer.readf32(expectedStorage, 0),
			string.format(
				"Trial movement restoration: actual=%.17g expected=%.17g points=%d",
				g:humanoid(a).WalkSpeed,
				Rules.speed(pro.speed.Value),
				pro.speed.Value
			)
		)
	end)
end
return Checks
