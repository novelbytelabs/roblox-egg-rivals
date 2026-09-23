-- Review contribution, not yet part of the candidate or an executed result.
-- Integrate as a server ModuleScript and invoke run(g, check, a) from Tests.run.
-- Every assertion exercises the actual production module; no fake engine or pass oracle.
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").Stage3Shared
local C = require(Shared.Config)
local R = require(Shared.Rules)
local Inventory = require(script.Parent.Inventory)
local Holds = require(script.Parent.Holds)
local ContractChecks = {}
local function close(a, b)
	assert(math.abs(a - b) < 1e-6, string.format("%.12f ~= %.12f", a, b))
end
local function definitions()
	local inv = Inventory.new()
	local a = assert(inv:create(-404001, "Pet", "Rare", "Skunk", "Fire"))
	local b = assert(inv:create(-404002, "Pet", "Epic", "Dragon", "Water"))
	return inv, a, b
end
function ContractChecks.run(g, check, realPlayer)
	assert(RunService:IsStudio() and workspace:GetAttribute("Stage3AutoTest") == true, "TEST artifact only")
	assert(
		realPlayer and realPlayer:IsA("Player") and realPlayer.Parent == game:GetService("Players"),
		"Real Studio client required"
	)
	check("Momentum integral is invariant to timestep partitioning", function()
		local m, area, power = R.trainDelta(0.1, 47, true)
		local split, area2, power2 = 0.1, 0, 0
		for _ = 1, 470 do
			local nextM, a, e = R.trainDelta(split, 0.1, true)
			split = nextM
			area2 += a
			power2 += e
		end
		close(m, split)
		close(area, area2)
		close(power, power2)
		assert(m == 1 and power > 0)
	end)
	check("Motion Energy has no integral below its momentum threshold", function()
		local m, _, energy = R.trainDelta(0, C.EnergyThreshold * C.MomentumRamp, true)
		close(m, C.EnergyThreshold)
		close(energy, 0)
		local _, _, hot = R.trainDelta(m, (1 - m) * C.MomentumRamp, true)
		close(hot, (1 - C.EnergyThreshold) * C.MomentumRamp / 2)
	end)
	check("Idle momentum decays without generating training or energy credit", function()
		local m, area, energy = R.trainDelta(1, 5, false)
		close(m, 0.5)
		close(area, 0)
		close(energy, 0)
		local zero = R.trainDelta(m, 50, false)
		assert(zero == 0)
	end)
	check("Fractional Coin credit survives six thousand small timesteps", function()
		local balance, remainder = 0, 0
		for _ = 1, 6000 do
			balance, remainder = R.credit(balance, remainder, 6, 0.01)
		end
		assert(balance == 6)
		close(remainder, 0)
		assert(balance == select(1, R.credit(0, 0, 6, 60)))
	end)
	check("Invalid currency inputs are rejected rather than credited", function()
		for _, tuple in ipairs({
			{ -1, 0, 6, 1 },
			{ 0, 0, -6, 1 },
			{ 0, 0, 6, -1 },
			{ 0, -0.1, 6, 1 },
			{ 0, 0, 0 / 0, 1 },
			{
				0,
				0,
				6,
				math.huge,
			},
		}) do
			assert(not pcall(function()
				R.credit(table.unpack(tuple))
			end))
		end
	end)
	check("Movement mapping rejects nonfinite values and caps Overdrive", function()
		assert(R.speed(0 / 0) == C.BaseWalkSpeed and R.speed(math.huge) == C.BaseWalkSpeed)
		assert(R.speed(-100) == C.BaseWalkSpeed)
		assert(R.speed(C.SpeedCap * 10) == C.WalkSpeedCap)
		assert(R.speed(C.SpeedCap, true) == C.OverdriveCap)
		assert(not R.integer(1.5, 0, 10) and not R.integer(0 / 0, 0, 10))
	end)
	check("Failed inventory definitions leave item count and sequence unchanged", function()
		local inv = Inventory.new()
		local sequence = inv.sequence
		assert(not inv:create(0 / 0, "Egg", "Common", "Skunk"))
		assert(not inv:create(-404001, "Unknown", "Common", "Skunk"))
		assert(not inv:create(-404001, "Egg", "Secret", "Skunk"))
		assert(not inv:create(-404001, "Egg", "Common", "Unknown"))
		assert(not inv:create(-404001, "Pet", "Common", "Skunk", "Unknown"))
		assert(inv.sequence == sequence and next(inv.items) == nil)
	end)
	check("Inventory capacity rejection preserves existing instances", function()
		local inv = Inventory.new()
		local ids = {}
		for i = 1, C.MaxItems do
			ids[i] = assert(inv:create(-404001, "Egg", "Common", "Skunk")).id
		end
		local sequence = inv.sequence
		assert(not inv:create(-404001, "Egg", "Godly", "Dragon"))
		assert(not inv:createConsumable(-404001, "SnarePod"))
		assert(#inv:list(-404001) == C.MaxItems and inv.sequence == sequence)
		for _, id in ipairs(ids) do
			assert(inv.items[id] and inv.items[id].ownerId == -404001)
		end
	end)
	check("Invalid replacement offers preserve the exact previous reservation", function()
		local inv, a, b = definitions()
		assert(inv:reserveOffer(a.ownerId, { a.id }, "contract-trade", "Trade"))
		local before = R.itemSignature(a)
		assert(not inv:reserveOffer(a.ownerId, { b.id }, "contract-trade", "Trade"))
		assert(not inv:reserveOffer(a.ownerId, { a.id, a.id }, "contract-trade", "Trade"))
		assert(not inv:reserveOffer(a.ownerId, { [2] = a.id }, "contract-trade", "Trade"))
		assert(R.itemSignature(a) == before and b.state == "Inventory")
	end)
	check("Favorite and active companion restrictions protect transfers", function()
		local inv, a = definitions()
		assert(inv:setLocked(a.ownerId, a.id, true))
		assert(not R.transferable(a, a.ownerId))
		assert(not inv:reserveOffer(a.ownerId, { a.id }, "contract-lock", "Trade"))
		assert(inv:setLocked(a.ownerId, a.id, false))
		a.petMode = "Active"
		assert(not inv:reserveOffer(a.ownerId, { a.id }, "contract-lock", "Trade"))
		a.petMode = "Pen"
		assert(inv:reserveOffer(a.ownerId, { a.id }, "contract-lock", "Trade"))
		assert(not inv:setLocked(a.ownerId, a.id, true))
	end)
	check("Two-sided item transfer preserves IDs and transfers only once", function()
		local inv, a, b = definitions()
		local ownerA, ownerB = a.ownerId, b.ownerId
		assert(inv:reserveOffer(ownerA, { a.id }, "contract-atomic", "Trade"))
		assert(inv:reserveOffer(ownerB, { b.id }, "contract-atomic", "Trade"))
		local ok, changes = inv:transfer("contract-atomic", ownerA, { a.id }, ownerB, { b.id })
		assert(ok and #changes == 2)
		assert(inv.items[a.id] == a and inv.items[b.id] == b)
		assert(a.ownerId == ownerB and b.ownerId == ownerA and a.state == "Inventory" and b.state == "Inventory")
		assert(a.petMode == "Pen" and b.petMode == "Pen" and a.reservation == nil and b.reservation == nil)
		local sigA, sigB = R.itemSignature(a), R.itemSignature(b)
		assert(not inv:transfer("contract-atomic", ownerA, { a.id }, ownerB, { b.id }))
		assert(R.itemSignature(a) == sigA and R.itemSignature(b) == sigB)
	end)
	check("Failed final item transfer preserves both original owners", function()
		local inv, a, b = definitions()
		local ownerA, ownerB = a.ownerId, b.ownerId
		assert(inv:reserveOffer(ownerA, { a.id }, "contract-invalid", "Trade"))
		assert(inv:reserveOffer(ownerB, { b.id }, "contract-invalid", "Trade"))
		b.locked = true
		assert(not inv:transfer("contract-invalid", ownerA, { a.id }, ownerB, { b.id }))
		assert(a.ownerId == ownerA and b.ownerId == ownerB and a.reservation == "contract-invalid")
		inv:release("contract-invalid")
		assert(a.state == "Inventory" and b.state == "Inventory" and not a.reservation and not b.reservation)
	end)
	check("Income follows current owner across a completed transfer", function()
		local inv, a, b = definitions()
		local ownerA, ownerB = a.ownerId, b.ownerId
		local incomeA, incomeB = inv:income(ownerA), inv:income(ownerB)
		assert(inv:reserveOffer(ownerA, { a.id }, "contract-income", "Trade"))
		assert(inv:reserveOffer(ownerB, { b.id }, "contract-income", "Trade"))
		assert(inv:income(ownerA) == incomeA and inv:income(ownerB) == incomeB)
		assert(inv:transfer("contract-income", ownerA, { a.id }, ownerB, { b.id }))
		assert(inv:income(ownerA) == incomeB and inv:income(ownerB) == incomeA)
	end)
	check("Exchange value, credit and removal form one nonrepeatable transaction", function()
		local inv, a = definitions()
		local owner = a.ownerId
		local coins = Instance.new("IntValue")
		coins.Value = 17
		assert(inv:reserveOffer(owner, { a.id }, "contract-exchange", "Exchange"))
		local ok, value = inv:exchange(owner, a.id, "contract-exchange", coins)
		assert(ok and value == 320 and coins.Value == 337 and inv.items[a.id] == nil)
		assert(not inv:exchange(owner, a.id, "contract-exchange", coins) and coins.Value == 337)
		coins:Destroy()
	end)
	check("Exchange failure at currency ceiling preserves the reserved item", function()
		local inv, a = definitions()
		local coins = Instance.new("IntValue")
		coins.Value = C.MaxCoins
		assert(inv:reserveOffer(a.ownerId, { a.id }, "contract-ceiling", "Exchange"))
		assert(not inv:exchange(a.ownerId, a.id, "contract-ceiling", coins))
		assert(inv.items[a.id] == a and coins.Value == C.MaxCoins and a.state == "Exchange")
		inv:release("contract-ceiling")
		assert(a.state == "Inventory" and a.reservation == nil)
		coins:Destroy()
	end)
	check("SnarePod records are real consumables with bounded resale value", function()
		local inv = Inventory.new()
		local pod = assert(inv:createConsumable(-404001, "SnarePod"))
		assert(pod.kind == "Item" and pod.itemType == "SnarePod" and pod.species == "Snare Pod")
		assert(R.exchangeValue(pod) == C.TrapExchangeValue and R.exchangeValue(pod) < C.TrapCost)
		assert(inv:setLocked(pod.ownerId, pod.id, true))
		assert(#inv:consumables(pod.ownerId, true) == 0 and #inv:consumables(pod.ownerId, false) == 1)
	end)
	check("Unrelated winners cannot settle duel escrow", function()
		local inv, a, b = definitions()
		assert(inv:escrow(a.ownerId, a.id, b.ownerId, b.id, "contract-duel"))
		local sigA, sigB = R.itemSignature(a), R.itemSignature(b)
		assert(not inv:settle("contract-duel", { a.id, b.id }, -404999))
		assert(R.itemSignature(a) == sigA and R.itemSignature(b) == sigB)
		assert(inv:settle("contract-duel", { a.id, b.id }, nil))
		assert(a.state == "Inventory" and b.state == "Inventory")
	end)
	check("Timed confirmation cannot complete early, with wrong identity, or twice", function()
		local holds = Holds.new(g)
		local h = assert(holds:begin(realPlayer, "contract", "exact-item-v1", 0.12, "contract-nonce"))
		assert(not holds:consume(realPlayer, "contract", "exact-item-v1", h.token))
		task.wait(0.14)
		assert(not holds:consume(realPlayer, "contract", "changed-item-v2", h.token))
		assert(not holds:consume(realPlayer, "wrong-kind", "exact-item-v1", h.token))
		assert(holds:consume(realPlayer, "contract", "exact-item-v1", h.token))
		assert(not holds:consume(realPlayer, "contract", "exact-item-v1", h.token))
	end)
	check("Canceled and expired confirmations cannot later be reused", function()
		local holds = Holds.new(g)
		local h = assert(holds:begin(realPlayer, "contract", "exact-item", 0.1, "nonce-a"))
		holds:cancel(realPlayer, "wrong-nonce")
		assert(holds.active[realPlayer] == h)
		holds:cancel(realPlayer, "nonce-a")
		task.wait(0.12)
		assert(not holds:consume(realPlayer, "contract", "exact-item", h.token))
		local expired = assert(holds:begin(realPlayer, "contract", "exact-item", 0.1, "nonce-b"))
		-- Explicit deadline fixture, not a bypass of production confirmation logic.
		expired.expires = g:now() - 1
		assert(not holds:consume(realPlayer, "contract", "exact-item", expired.token))
		assert(holds.active[realPlayer] == nil)
	end)
end
return ContractChecks
