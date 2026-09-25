local RunService = game:GetService("RunService")
local C = require(game:GetService("ReplicatedStorage").Stage3Shared.Config)
local V = {}

local function near(g, p, pos)
	g:teleport(p, CFrame.new(pos))
	task.wait(0.05)
end

local function visiblePet(g, owner)
	local pet = assert(g.inventory:create(owner.UserId, "Pet", "Epic", "Lizard", "Water"))
	pet.petMode = "Pen"
	g:reconcilePets()
	local record = assert(g.petRecords:FindFirstChild(pet.id))
	local index = assert(record:GetAttribute("DisplayIndex"))
	local capacity = C.Expansions[g.profiles[owner].ranchLevel + 1].capacity
	g.profiles[owner].penPage = math.floor((index - 1) / capacity) + 1
	g:reconcilePets()
	assert(record:GetAttribute("Displayed") == true and record:GetAttribute("DisplayMode") == "Pen")
	return pet, record
end

function V.run(g, check, a, b)
	check("Visitor inspection exposes exact read-only pet identity only at the ranch", function()
		local pet, record = visiblePet(g, b)
		local pos = assert(record:GetAttribute("PenPosition"))
		local beforeMoney = g.profiles[b].money.Value
		local beforeRevision = pet.revision
		near(g, a, pos + Vector3.new(0, 2, 4))
		local ok, data = g.ranch:inspect(a, pet.id)
		assert(ok and data.id == pet.id and data.ownerUserId == b.UserId and data.ownerName == b.DisplayName)
		assert(data.species == pet.species and data.element == pet.element and data.rarity == pet.rarity)
		assert(data.income == C.Rarities[pet.rarity].income)
		assert(pet.ownerId == b.UserId and pet.state == "Inventory" and pet.revision == beforeRevision)
		assert(g.profiles[b].money.Value == beforeMoney)
		assert(g:action(a, "ranchInspect", { id = pet.id }))
		near(g, a, g.profiles[a].base.spawn.Position)
		assert(not g.ranch:inspect(a, pet.id))
	end)

	check("Visitor Admire is proximity and cooldown bounded without economy or ownership authority", function()
		local pet, record = visiblePet(g, b)
		local pos = assert(record:GetAttribute("PenPosition"))
		local proA, proB = g.profiles[a], g.profiles[b]
		local incomeA, incomeB = g.inventory:income(a.UserId), g.inventory:income(b.UserId)
		local wealthA = proA.money.Value + proA.coinRemainder
		local wealthB = proB.money.Value + proB.coinRemainder
		local expectedPassiveA, expectedPassiveB = 0, 0
		local maxHeartbeatDt = 0
		local economyConnection = RunService.Heartbeat:Connect(function(dt)
			maxHeartbeatDt = math.max(maxHeartbeatDt, dt)
			expectedPassiveA += incomeA * dt / 60
			expectedPassiveB += incomeB * dt / 60
		end)
		local beforeRevision = pet.revision
		local interactionOK, interactionErr = xpcall(function()
			near(g, a, pos + Vector3.new(0, 2, 4))
			assert(not g.ranch:react(a, pet.id, "RewardMe"))
			assert(g:action(a, "ranchReact", { id = pet.id, reaction = "Admire" }))
			assert(not g:action(a, "ranchReact", { id = pet.id, reaction = "Admire" }))
		end, debug.traceback)
		economyConnection:Disconnect()
		assert(interactionOK, interactionErr)
		assert(pet.ownerId == b.UserId and pet.state == "Inventory" and pet.revision == beforeRevision)
		local actualPassiveA = proA.money.Value + proA.coinRemainder - wealthA
		local actualPassiveB = proB.money.Value + proB.coinRemainder - wealthB
		-- Game income and this audit listener can straddle the yielding test thread by
		-- one scheduler boundary on each side plus the resume frame. Keep the allowance
		-- below one integer Coin so any Visitor Ranch reward/mutation is still detected.
		local boundaryDt = math.max(maxHeartbeatDt, 1 / 60) * 3
		local toleranceA = incomeA * boundaryDt / 60 + 0.02
		local toleranceB = incomeB * boundaryDt / 60 + 0.02
		assert(
			toleranceA < 1 and toleranceB < 1,
			"Visitor economy fixture income is too high for exact reward detection"
		)
		assert(
			math.abs(actualPassiveA - expectedPassiveA) <= toleranceA,
			string.format(
				"Admire changed visitor Coins beyond passive income: actual %.4f expected %.4f tolerance %.4f",
				actualPassiveA,
				expectedPassiveA,
				toleranceA
			)
		)
		assert(
			math.abs(actualPassiveB - expectedPassiveB) <= toleranceB,
			string.format(
				"Admire changed owner Coins beyond passive income: actual %.4f expected %.4f tolerance %.4f",
				actualPassiveB,
				expectedPassiveB,
				toleranceB
			)
		)
		assert(g.inventory:income(a.UserId) == incomeA and g.inventory:income(b.UserId) == incomeB)
	end)

	check("Owners and unavailable pets cannot use the visitor interaction path", function()
		local pet, record = visiblePet(g, b)
		local pos = assert(record:GetAttribute("PenPosition"))
		near(g, b, pos + Vector3.new(0, 2, 4))
		assert(not g.ranch:inspect(b, pet.id))
		assert(not g.ranch:react(b, pet.id, "Admire"))
		record:SetAttribute("Displayed", false)
		near(g, a, pos + Vector3.new(0, 2, 4))
		assert(not g.ranch:inspect(a, pet.id))
		assert(not g.ranch:react(a, pet.id, "Admire"))
		g:reconcilePets()
	end)
end

return V
