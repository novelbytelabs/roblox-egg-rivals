local C = require(game:GetService("ReplicatedStorage").Stage3Shared.Config)
local Checks = {}

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

local function nearArmory(g, p)
	g:teleport(p, CFrame.new(g.world.duelArmory.Position + Vector3.new(0, 2, -6)))
end

local function clientSelect(g, p, weapon)
	local token = "duel-armory-" .. weapon .. "-" .. tostring(g:now())
	g:feed(p, "openDuelArmory", {})
	g:feed(p, "completionInputProbe", { token = token, kind = "DuelArmory", weapon = weapon })
	assert(
		waitFor(function()
			return g.clientDiagnostics[p] and g.clientDiagnostics[p].token == token
		end, 8),
		"Real client Duel Armory probe timed out"
	)
	local data = g.clientDiagnostics[p]
	assert(data.passed, data.error)
	return data
end

function Checks.run(g, check, a, _b, results)
	local pro = assert(g.profiles[a])
	local savedWeapon = pro.duelWeapon
	local savedRoot = g:root(a) and g:root(a).CFrame
	local savedMoney = pro.money.Value
	local savedRemainder = pro.coinRemainder
	local savedSpeed = pro.speed.Value
	local itemCount = #g.inventory:list(a.UserId)
	local income = g.inventory:income(a.UserId)

	check("Duel Armory exposes three bounded sidegrades with comparable maximum output", function()
		assert(#C.DuelWeaponOrder == 3)
		local minimum, maximum = math.huge, 0
		local tools = {}
		for _, name in ipairs(C.DuelWeaponOrder) do
			local spec = assert(C.DuelWeapons[name])
			assert(not tools[spec.tool] and spec.damage > 0 and spec.cooldown > 0 and spec.range > 0)
			tools[spec.tool] = true
			local output = spec.damage * spec.pellets / spec.cooldown
			minimum = math.min(minimum, output)
			maximum = math.max(maximum, output)
		end
		assert(maximum / minimum <= 1.10, "Armory sidegrades exceed the bounded damage-cadence envelope")
		assert(C.DuelWeapons.Rail.range > C.DuelWeapons.Blaster.range)
		assert(C.DuelWeapons.Scatter.range < C.DuelWeapons.Blaster.range)
		assert(C.DuelWeapons.Scatter.pellets == 5 and C.DuelWeapons.Scatter.spread > 0)
	end)

	check("Duel Armory rejects remote and unknown loadout changes without economy mutation", function()
		g:teleport(a, CFrame.new(0, 3, 8))
		local before = pro.money.Value
		assert(not g.duels:setWeapon(a, "Rail"))
		assert(not g.duels:setWeapon(a, "Unknown"))
		assert(pro.duelWeapon == savedWeapon and pro.money.Value == before)
	end)

	check("Armory loadout selection is free, server-owned and blocked during a duel", function()
		nearArmory(g, a)
		for _, name in ipairs(C.DuelWeaponOrder) do
			assert(g.duels:setWeapon(a, name))
			assert(pro.duelWeapon == name)
		end
		local before = pro.duelWeapon
		pro.duel = { phase = "Selecting" }
		assert(not g.duels:setWeapon(a, "Blaster"))
		assert(pro.duelWeapon == before)
		pro.duel = nil
		assert(pro.money.Value == savedMoney and pro.coinRemainder == savedRemainder)
		assert(#g.inventory:list(a.UserId) == itemCount and g.inventory:income(a.UserId) == income)
		assert(pro.speed.Value == savedSpeed)
	end)

	check("Selected sidegrade produces exactly the matching duel tool", function()
		nearArmory(g, a)
		assert(g.duels:setWeapon(a, "Scatter"))
		g:giveGear(a, true)
		local tool = a.Backpack:FindFirstChild("DuelScatter") or a.Character:FindFirstChild("DuelScatter")
		assert(tool and tool:GetAttribute("DuelWeapon") == "Scatter")
		for _, name in ipairs({ "DuelBlaster", "DuelRail" }) do
			assert(not a.Backpack:FindFirstChild(name) and not a.Character:FindFirstChild(name))
		end
		g:giveGear(a, false)
	end)

	check("Scatter geometry is bounded while Rail remains a single precision ray", function()
		local forward = Vector3.new(0, 0, -1)
		local scatter = g.duels:shotDirections(forward, C.DuelWeapons.Scatter)
		local rail = g.duels:shotDirections(forward, C.DuelWeapons.Rail)
		assert(#scatter == C.DuelWeapons.Scatter.pellets and #rail == 1)
		for _, direction in ipairs(scatter) do
			assert(math.abs(direction.Magnitude - 1) < 0.001)
			local angle = math.deg(math.acos(math.clamp(direction:Dot(forward), -1, 1)))
			assert(angle <= C.DuelWeapons.Scatter.spread + 0.2)
		end
		assert((rail[1] - forward).Magnitude < 0.001)
	end)

	check("Real client Armory choice reaches authoritative loadout without charging Coins", function()
		nearArmory(g, a)
		assert(g.duels:setWeapon(a, "Blaster"))
		g:push(a)
		local diagnostic = clientSelect(g, a, "Rail")
		assert(diagnostic.weapon == "Rail" and pro.duelWeapon == "Rail")
	end)

	results.armoryDiagnostics = {
		weapons = C.DuelWeaponOrder,
		freeSidegrades = true,
		realClientSelection = true,
	}
	pro.duelWeapon = savedWeapon or "Blaster"
	pro.money.Value = savedMoney
	pro.coinRemainder = savedRemainder
	if savedRoot and g:root(a) then
		g:teleport(a, savedRoot)
	end
	g:giveGear(a, false)
	g:push(a)
end

return Checks
