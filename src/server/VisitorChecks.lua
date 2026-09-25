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
		local beforeA = g.profiles[a].money.Value
		local beforeB = g.profiles[b].money.Value
		local beforeRevision = pet.revision
		near(g, a, pos + Vector3.new(0, 2, 4))
		assert(not g.ranch:react(a, pet.id, "RewardMe"))
		assert(g:action(a, "ranchReact", { id = pet.id, reaction = "Admire" }))
		assert(not g:action(a, "ranchReact", { id = pet.id, reaction = "Admire" }))
		assert(pet.ownerId == b.UserId and pet.state == "Inventory" and pet.revision == beforeRevision)
		assert(g.profiles[a].money.Value == beforeA and g.profiles[b].money.Value == beforeB)
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
