local HttpService = game:GetService("HttpService")
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

local function nearOutfitter(g, p)
	g:teleport(p, CFrame.new(g.world.petOutfitter.Position + Vector3.new(0, 2, -6)))
end

local function clientStyle(g, p, id, variant)
	local token = "pet-outfitter-" .. tostring(g:now())
	g:feed(p, "openPetOutfitter", {})
	g:feed(p, "completionInputProbe", { token = token, kind = "PetOutfitter", id = id, variant = variant })
	assert(
		waitFor(function()
			return g.clientDiagnostics[p] and g.clientDiagnostics[p].token == token
		end, 8),
		"Real client Pet Outfitter probe timed out"
	)
	local data = g.clientDiagnostics[p]
	assert(data.passed, data.error)
	return data
end

function Checks.run(g, check, a, b, results)
	local pro = assert(g.profiles[a])
	local savedRoot = g:root(a) and g:root(a).CFrame
	local savedBRoot = g:root(b) and g:root(b).CFrame
	local savedPage = pro.penPage
	local savedMoney, savedRemainder, savedSpeed = pro.money.Value, pro.coinRemainder, pro.speed.Value
	local beforeIncome = g.inventory:income(a.UserId)
	local created = {}
	local createdCount = 0
	local function pet(owner, rarity, creature, element)
		local item = assert(g.inventory:create(owner.UserId, "Pet", rarity, creature, element))
		createdCount += 1
		item.order = -9000 - createdCount
		created[item.id] = true
		return item
	end
	local own = pet(a, "Epic", "Lizard", "Water")
	local other = pet(b, "Rare", "Skunk", "Fire")
	pro.penPage = 1
	g:reconcilePets()

	check("Pet Outfitter exposes exactly three cosmetic-only styles with Standard as baseline", function()
		assert(#C.PetVariantOrder == 3 and C.PetVariantOrder[1] == "Standard")
		local seen = {}
		for _, name in ipairs(C.PetVariantOrder) do
			assert(C.PetVariants[name] and not seen[name])
			seen[name] = true
			assert(not name:lower():find("godly") and not name:lower():find("crown"))
		end
	end)

	check("Pet Outfitter rejects remote, foreign, reserved and unknown cosmetic mutations", function()
		g:teleport(a, CFrame.new(0, 3, 8))
		assert(not g:setPetVariant(a, own.id, "Ranger"))
		nearOutfitter(g, a)
		assert(not g:setPetVariant(a, other.id, "Ranger"))
		assert(not g:setPetVariant(a, own.id, "Unknown"))
		local key = HttpService:GenerateGUID(false)
		assert(g.inventory:reserveOffer(a.UserId, { own.id }, key, "Trade"))
		assert(not g:setPetVariant(a, own.id, "Ranger"))
		g.inventory:release(key)
		assert(own.variant == "Standard" and own.state == "Inventory")
	end)

	check("Owned active or penned pets accept styles without changing gameplay authority", function()
		nearOutfitter(g, a)
		assert(g:setPetMode(a, own.id, "Active"))
		local mode, owner, rarity, element, creature = own.petMode, own.ownerId, own.rarity, own.element, own.creature
		local money, remainder, speed = pro.money.Value, pro.coinRemainder, pro.speed.Value
		local income = g.inventory:income(a.UserId)
		local revision = own.revision
		assert(g:setPetVariant(a, own.id, "Ranger"))
		assert(own.variant == "Ranger" and own.revision == revision + 1)
		assert(own.petMode == mode and own.ownerId == owner and own.rarity == rarity)
		assert(own.element == element and own.creature == creature)
		assert(pro.money.Value == money and pro.coinRemainder == remainder and pro.speed.Value == speed)
		assert(g.inventory:income(a.UserId) == income)
		assert(g:setPetVariant(a, own.id, "Ranger"))
		assert(own.revision == revision + 1, "No-op cosmetic selection changed revision")
		assert(g:setPetMode(a, own.id, "Pen"))
	end)

	check("Pet cosmetic variant replicates to ranch records, snapshots and read-only visitor inspection", function()
		nearOutfitter(g, a)
		assert(g:setPetVariant(a, own.id, "Starlight"))
		g:reconcilePets()
		local record = assert(g.petRecords:FindFirstChild(own.id))
		assert(record:GetAttribute("Variant") == "Starlight")
		local snapshot = g.inventory:snapshotItem(own)
		assert(snapshot.variant == "Starlight")
		local pos = assert(record:GetAttribute("PenPosition"))
		g:teleport(b, CFrame.new(pos + Vector3.new(0, 2, 4)))
		local ok, data = g.ranch:inspect(b, own.id)
		assert(ok and data.variant == "Starlight")
		assert(own.ownerId == a.UserId and own.variant == "Starlight")
	end)

	check("Real client Pet Outfitter changes exact pet cosmetic and renders it without gameplay mutation", function()
		nearOutfitter(g, a)
		assert(g:setPetVariant(a, own.id, "Standard"))
		g:reconcilePets()
		g:push(a)
		local income = g.inventory:income(a.UserId)
		local mode, rarity, element, creature = own.petMode, own.rarity, own.element, own.creature
		local diagnostic = clientStyle(g, a, own.id, "Ranger")
		assert(diagnostic.variant == "Ranger" and own.variant == "Ranger")
		assert(g.inventory:income(a.UserId) == income)
		assert(own.petMode == mode and own.rarity == rarity and own.element == element and own.creature == creature)
	end)

	results.outfitterDiagnostics = {
		styles = C.PetVariantOrder,
		freeCosmetics = true,
		realClientRendering = true,
	}
	for id in pairs(created) do
		g.inventory.items[id] = nil
	end
	pro.penPage = savedPage
	pro.money.Value, pro.coinRemainder, pro.speed.Value = savedMoney, savedRemainder, savedSpeed
	assert(g.inventory:income(a.UserId) == beforeIncome)
	g:reconcilePets()
	if savedRoot and g:root(a) then
		g:teleport(a, savedRoot)
	end
	if savedBRoot and g:root(b) then
		g:teleport(b, savedBRoot)
	end
	g:pushAll()
end

return Checks
