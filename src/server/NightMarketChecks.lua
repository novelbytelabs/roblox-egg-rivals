local C = require(game:GetService("ReplicatedStorage").Stage3Shared.Config)
local Checks = {}

local function nearMarket(g, p)
	g:teleport(p, CFrame.new(g.world.nightMarket.counter.Position + Vector3.new(0, 2, -6)))
end

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

local function clientPurchase(g, p)
	local token = "night-market-" .. tostring(g:now())
	g:feed(p, "openNightMarket", {})
	g:feed(p, "completionInputProbe", { token = token, kind = "NightMarket" })
	assert(
		waitFor(function()
			return g.clientDiagnostics[p] and g.clientDiagnostics[p].token == token
		end, 8),
		"Real client Night Market probe timed out"
	)
	local data = g.clientDiagnostics[p]
	assert(data.passed, data.error)
	return data
end

local function assertMarketState(g, open)
	local market = g.world.nightMarket
	assert(market.counter:GetAttribute("Open") == open)
	assert(market.shutter.CanCollide == not open)
	assert((market.shutter.Transparency >= 0.99) == open)
	assert(g.nightMarketPrompt.Enabled == open)
	for _, lamp in ipairs(market.lamps) do
		assert(lamp.light.Enabled == open)
	end
end

function Checks.run(g, check, a, _b, results)
	local pro = assert(g.profiles[a])
	local savedMoney = pro.money.Value
	local savedRoot = g:root(a) and g:root(a).CFrame
	local savedNight = workspace:GetAttribute("Night") == true
	local savedBoss = workspace:GetAttribute("BossEnabled")
	local savedPhase = g.phaseEnds
	local savedSpeed = pro.speed.Value
	local beforeCount = #g.inventory:list(a.UserId)
	local beforeIncome = g.inventory:income(a.UserId)
	workspace:SetAttribute("BossEnabled", false)
	if g.carry[a] then
		g:resetEgg(g.carry[a])
	end
	g:setNight(false)
	nearMarket(g, a)

	check("Night Market is physically closed by Day and cannot charge Coins", function()
		assertMarketState(g, false)
		pro.money.Value = 500
		local before = pro.money.Value
		local ok, why = g:buyNightAid(a, "MoonCompass")
		assert(not ok and why == "The Night Market opens only at Moonrise.")
		assert(pro.money.Value == before)
	end)

	check("Moonrise opens the Night Market and rejects unknown aids without mutation", function()
		assert(g:setNight(true))
		g.phaseEnds = g:now() + 600
		nearMarket(g, a)
		assertMarketState(g, true)
		assert(g.nightEgg and g.nightEgg.state == "Home")
		local before = pro.money.Value
		local ok = g:buyNightAid(a, "ExactWaypoint")
		assert(not ok and pro.money.Value == before)
	end)

	check("Moon Compass gives one coarse clue per Moonrise for the exact configured cost", function()
		local before = pro.money.Value
		local ok, clue = g:buyNightAid(a, "MoonCompass")
		assert(ok and type(clue) == "string" and #clue > 20)
		assert(not clue:find("%d"), "Compass clue leaked numeric location detail")
		assert(pro.money.Value == before - C.NightMarketAids.MoonCompass.cost)
		local after = pro.money.Value
		assert(not g:buyNightAid(a, "MoonCompass"))
		assert(pro.money.Value == after)
	end)

	check("Glow Map gives a broad sector once without revealing coordinates", function()
		local before = pro.money.Value
		local ok, clue = g:buyNightAid(a, "GlowMap")
		assert(ok and clue:find("GROVE") and clue:find("FOREST"))
		assert(not clue:find("%d"), "Glow Map clue leaked numeric location detail")
		assert(pro.money.Value == before - C.NightMarketAids.GlowMap.cost)
		local after = pro.money.Value
		assert(not g:buyNightAid(a, "GlowMap"))
		assert(pro.money.Value == after)
	end)

	check("Night Market refuses clues once the hidden egg leaves its hiding place", function()
		local egg = assert(g.nightEgg)
		g:teleport(a, CFrame.new(egg.nest.position + Vector3.new(0, 3, 0)))
		assert(g:take(a, egg.id))
		nearMarket(g, a)
		local before = pro.money.Value
		local ok, why = g:buyNightAid(a, "MoonCompass")
		assert(not ok and why == "The hidden Moonrise egg is already in play.")
		assert(pro.money.Value == before)
		assert(g:drop(a, "night-market-test"))
		assert(g:resetEgg(egg))
	end)

	check("A new Moonrise resets aid eligibility while preserving inventory and progression", function()
		local firstEpoch = g.nightEpoch
		assert(g:setNight(false))
		assertMarketState(g, false)
		assert(g:setNight(true))
		g.phaseEnds = g:now() + 600
		nearMarket(g, a)
		assert(g.nightEpoch == firstEpoch + 1)
		local diagnostic = clientPurchase(g, a)
		assert(diagnostic.clue and pro.nightMarketUsed.MoonCompass == true)
		assert(#g.inventory:list(a.UserId) == beforeCount)
		assert(g.inventory:income(a.UserId) == beforeIncome)
		assert(pro.speed.Value == savedSpeed)
	end)

	check("Dawn closes the Night Market immediately", function()
		assert(g:setNight(false))
		assertMarketState(g, false)
	end)

	results.nightMarketDiagnostics = {
		aids = { "MoonCompass", "GlowMap" },
		realClientPurchase = true,
		compassCost = C.NightMarketAids.MoonCompass.cost,
		mapCost = C.NightMarketAids.GlowMap.cost,
		coordinateFree = true,
	}
	pro.money.Value = savedMoney
	if savedRoot and g:root(a) then
		g:teleport(a, savedRoot)
	end
	g:setNight(savedNight)
	g.phaseEnds = math.max(savedPhase, g:now() + 10)
	workspace:SetAttribute("BossEnabled", savedBoss)
	g:push(a)
end

return Checks
