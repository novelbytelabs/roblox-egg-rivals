local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Navigation = require(script.Parent.Navigation)
local Shared = ReplicatedStorage:WaitForChild("Stage3Shared")
local C = require(Shared.Config)
local R = require(Shared.Rules)
local Art = require(Shared.Art)
local Inventory = require(script.Parent.Inventory)
local Duel = require(script.Parent.Duel)
local World = require(script.Parent.World)
local Holds = require(script.Parent.Holds)
local SpeedLab = require(script.Parent.SpeedLab)
local Trials = require(script.Parent.Trials)
local Sprint = require(script.Parent.Sprint)
local Contracts = require(script.Parent.Contracts)
local Ranch = require(script.Parent.Ranch)
local Trade = require(script.Parent.Trade)
local Incubation = require(script.Parent.Incubation)
local HttpService = game:GetService("HttpService")
local Game = {}
Game.__index = Game

local STUDIO_RANCH_PETS = {
	{ "Common", "Skunk", "Fire" },
	{ "Uncommon", "Lizard", "Water" },
	{ "Rare", "Gorilla", "Earth" },
	{ "Epic", "Dragon", "Wind" },
	{ "Legendary", "Lizard", "Fire" },
	{ "Mythic", "Dragon", "Water" },
	{ "Godly", "Gorilla", "Earth" },
	{ "Rare", "Skunk", "Wind" },
}

function Game:now()
	return workspace:GetServerTimeNow()
end
function Game:root(p)
	return p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
end
function Game:humanoid(p)
	return p and p.Character and p.Character:FindFirstChildOfClass("Humanoid")
end
function Game:alive(p)
	local h = self:humanoid(p)
	return self.profiles[p] ~= nil and p.Parent == Players and h ~= nil and h.Health > 0 and self:root(p) ~= nil
end
function Game:busy(p, ignorePreview)
	local pro = self.profiles[p]
	return pro == nil
		or pro.duel ~= nil
		or pro.trade ~= nil
		or pro.exchange ~= nil
		or pro.trial ~= nil
		or pro.sprint ~= nil
		or (not ignorePreview and pro.incubatorPreview ~= nil)
end

function Game:updateTrainingState()
	local trainers = {}
	for p, pro in pairs(self.profiles) do
		local root = self:root(p)
		pro.training = self:alive(p)
			and not self:busy(p)
			and root ~= nil
			and R.within(root.Position, pro.base.treadmill.Position, 5, 2.9, 5)
		pro.drafting = false
		if pro.training then
			table.insert(trainers, p)
		end
	end
	for i = 1, #trainers - 1 do
		local a = trainers[i]
		local aPro = self.profiles[a]
		for j = i + 1, #trainers do
			local b = trainers[j]
			local bPro = self.profiles[b]
			if
				aPro
				and bPro
				and (aPro.base.treadmill.Position - bPro.base.treadmill.Position).Magnitude <= C.DraftRange
			then
				aPro.drafting = true
				bPro.drafting = true
			end
		end
	end
	return trainers
end
function Game:equipped(p, name)
	local t = p.Character and p.Character:FindFirstChild(name)
	return t and t:IsA("Tool") and t:GetAttribute("Stage3Tool") == true
end
function Game:feed(p, kind, data)
	if p.Parent == Players then
		self.net.Feed:FireClient(p, kind, data)
	end
end
function Game:notify(p, text, sound)
	self:feed(p, "toast", { text = text, sound = sound })
end
function Game:effect(kind, data)
	self.net.Effect:FireAllClients(kind, data)
end
function Game:safe(pos)
	return pos.Z <= C.SafeBoundaryZ
end
function Game:rate(p, key, period)
	local pro = self.profiles[p]
	if not pro then
		return false
	end
	local now = self:now()
	local last = pro.rates[key]
	if last and now - last < period then
		return false
	end
	pro.rates[key] = now
	return true
end
function Game:applySpeed(p)
	local pro = self.profiles[p]
	local h = self:humanoid(p)
	if not pro or not h then
		return
	end
	if pro.duel and p:GetAttribute("InDuel") then
		h.WalkSpeed = pro.duel.phase == "Active" and C.DuelWalkSpeed or 0
	elseif pro.sprint and pro.sprint.phase == "Countdown" then
		h.WalkSpeed = 0
	elseif pro.sprint and (pro.sprint.phase == "Active" or pro.sprint.phase == "Finishing") then
		h.WalkSpeed = pro.sprint.finished[p] and 0 or C.TrialSpeed
	elseif p:GetAttribute("InTrial") then
		h.WalkSpeed = C.TrialSpeed
	elseif pro.slowUntil > self:now() then
		h.WalkSpeed = 6
	else
		local overdrive = pro.lab and pro.lab.untilTime > self:now()
		local tuning = self.speedLab and self.speedLab:spec(pro) or C.Tunings.Standard
		local speed = R.speed(pro.speed.Value, overdrive, tuning.overdriveFactor)
		if pro.lab and pro.lab.precision and pro.tier >= C.PrecisionUnlockTier then
			speed = math.max(C.BaseWalkSpeed, speed * C.PrecisionFactor)
		end
		h.WalkSpeed = speed
	end
end
function Game:teleport(p, cf)
	local root = self:root(p)
	if not root then
		return
	end
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	p.Character:PivotTo(cf)
	local pro = self.profiles[p]
	if pro then
		pro.teleportSerial = (pro.teleportSerial or 0) + 1
	end
end
function Game:clearGear(p)
	for _, container in ipairs({ p:FindFirstChildOfClass("Backpack"), p.Character }) do
		if container then
			for _, t in ipairs(container:GetChildren()) do
				if t:IsA("Tool") and t:GetAttribute("Stage3Tool") then
					t:Destroy()
				end
			end
		end
	end
end
function Game:giveGear(p, duel)
	local backpack = p:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end
	self:clearGear(p)
	local names = duel and { "DuelBlaster" } or { "Bat", "SnarePod" }
	for _, name in ipairs(names) do
		local tool = Art.tool(name)
		tool:SetAttribute("Stage3Tool", true)
		tool.Parent = backpack
		if duel then
			local h = self:humanoid(p)
			if h then
				h:EquipTool(tool)
			end
		end
	end
end
function Game:setup(p)
	if self.profiles[p] then
		return
	end
	local base
	for _, b in ipairs(self.world.bases) do
		if not b.owner then
			base = b
			break
		end
	end
	if not base then
		p:Kick("This four-player vertical-slice test is full.")
		return
	end
	base.owner = p
	p.RespawnLocation = base.respawnPad
	base.nameLabel.Text = p.DisplayName .. "'S CAMP"
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = p
	local speed = Instance.new("IntValue")
	speed.Name = "Speed"
	speed.Parent = stats
	local money = Instance.new("IntValue")
	money.Name = "Coins"
	money.Parent = stats
	local inv = Instance.new("Folder")
	inv.Name = "Inventory"
	inv.Parent = p
	local pro = {
		base = base,
		speed = speed,
		money = money,
		tier = 1,
		autoHatch = false,
		incubations = {},
		activePetId = nil,
		penPage = 1,
		inventoryFolder = inv,
		charges = 0,
		onboardingComplete = false,
		slowUntil = 0,
		duel = nil,
		trade = nil,
		exchange = nil,
		rates = {},
		training = false,
		drafting = false,
		tutorial = 1,
		coinRemainder = 0,
		ranchLevel = 0,
		hatched = 0,
		teleportSerial = 0,
		trial = nil,
		bestTrial = nil,
		sprint = nil,
	}
	self.profiles[p] = pro
	assert(self.inventory:createConsumable(p.UserId, "SnarePod"))
	pro.charges = #self.inventory:consumables(p.UserId, true)
	self.speedLab:setup(pro)
	self.contracts:setup(p)
	self.ranch:setup(p)
	base.applyGrade(pro.tier)
	base.applyExpansion(pro.ranchLevel)
	p:SetAttribute("InDuel", false)
	p:SetAttribute("InTrial", false)
	p:SetAttribute("InSprint", false)
	p:SetAttribute("Busy", false)
	p:SetAttribute("BaseIndex", table.find(self.world.bases, base))
	speed.Changed:Connect(function()
		self:applySpeed(p)
	end)
	local function characterAdded(char)
		local h = char:WaitForChild("Humanoid", 10)
		local root = char:WaitForChild("HumanoidRootPart", 10)
		if not h or not root or p.Character ~= char or not self.profiles[p] then
			return
		end
		if not p:GetAttribute("InDuel") then
			self:teleport(p, base.spawn)
			self:giveGear(p, false)
			self.ranch:homecoming(p, "respawn")
		end
		self:applySpeed(p)
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "DuelPrompt"
		prompt.ActionText = "Challenge"
		prompt.ObjectText = p.DisplayName
		prompt.KeyboardKeyCode = Enum.KeyCode.R
		prompt.MaxActivationDistance = 9
		prompt.RequiresLineOfSight = false
		prompt.HoldDuration = 0.2
		prompt.Parent = root
		prompt:SetAttribute("TargetUserId", p.UserId)
		prompt.Triggered:Connect(function(challenger)
			if self:rate(challenger, "challenge", 1) then
				local ok, err = self.duels:request(challenger, p)
				if not ok then
					self:notify(challenger, err)
				end
			end
		end)
		local sprintPrompt = Instance.new("ProximityPrompt")
		sprintPrompt.Name = "SprintPrompt"
		sprintPrompt.ActionText = "Sprint"
		sprintPrompt.ObjectText = p.DisplayName
		sprintPrompt.KeyboardKeyCode = Enum.KeyCode.T
		sprintPrompt.MaxActivationDistance = C.SprintRange
		sprintPrompt.RequiresLineOfSight = false
		sprintPrompt.HoldDuration = 0.2
		sprintPrompt.Parent = root
		sprintPrompt:SetAttribute("TargetUserId", p.UserId)
		sprintPrompt.Triggered:Connect(function(challenger)
			if self:rate(challenger, "sprintChallenge", 1) then
				local ok, err = self.sprints:request(challenger, p)
				if not ok then
					self:notify(challenger, err)
				end
			end
		end)
		h.Died:Connect(function()
			self.incubation:cancel(p)
			self.trades:leaving(p)
			if pro.exchange then
				self:exchangeCancel(p, "Exchange canceled on respawn.")
			end
			if pro.trial then
				self.trials:finish(p, false, "Trial ended on respawn.")
			end
			if pro.sprint then
				self.sprints:died(p)
			end
			self.holds:cancel(p)
			if self.carry[p] then
				self:drop(p, "death")
			end
			self.duels:eliminate(p)
		end)
		self:push(p)
	end
	p.CharacterAdded:Connect(characterAdded)
	if p.Character then
		task.spawn(characterAdded, p.Character)
	end
	self:push(p)
end
function Game:prompt(part, action, text, callback)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = action
	prompt.ObjectText = text
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 9
	prompt.HoldDuration = 0.15
	prompt.Parent = part
	prompt.Triggered:Connect(callback)
	return prompt
end
function Game:spawnEgg(nest, rarity, creature)
	if nest.egg then
		return
	end
	creature = creature or nest.creature or C.Creatures[self.rng:NextInteger(1, #C.Creatures)]
	assert(C.Rarities[rarity] and table.find(C.Creatures, creature), "Invalid egg spawn")
	assert(not nest.fixedRarity or rarity == nest.fixedRarity, "Dedicated nest rarity mismatch")
	local model = Art.egg(rarity, self.world.dynamic, creature)
	model:PivotTo(CFrame.new(nest.position))
	self.eggSequence = (self.eggSequence or 0) + 1
	local id = "nest-" .. tostring(nest.id) .. "-" .. self.eggSequence
	local egg = {
		id = id,
		nest = nest,
		rarity = rarity,
		creature = creature,
		model = model,
		state = "Home",
		carrier = nil,
		changed = self:now(),
		immune = nil,
		revision = 0,
		nightEvent = nest.event == true,
		claimed = false,
	}
	model:SetAttribute("EggId", id)
	model:SetAttribute("State", "Home")
	egg.prompt = self:prompt(model.PrimaryPart, "Take Egg", rarity .. " " .. creature .. " Egg", function(p)
		local ok, err = self:take(p, id)
		if not ok then
			self:notify(p, err)
		end
	end)
	if nest.label then
		nest.label.Text = creature:upper() .. " EGG • " .. rarity:upper() .. "\nEscape the Grove Warden"
		nest.label.TextColor3 = C.Rarities[rarity].color
	end
	if egg.nightEvent then
		egg.prompt.MaxActivationDistance = 6
		local label = model:FindFirstChildWhichIsA("BillboardGui", true)
		if label then
			label.MaxDistance = 14
		end
	end
	nest.egg = egg
	self.eggs[id] = egg
end
function Game:take(p, id)
	local egg = self.eggs[id]
	local pro = self.profiles[p]
	if not self:alive(p) or self:busy(p) then
		return false, "Finish your current activity first."
	end
	if self.carry[p] then
		return false, "You are already carrying an egg."
	end
	if #self.inventory:list(p.UserId) >= C.MaxItems then
		return false, "Your collection is full."
	end
	if not egg or (egg.state ~= "Home" and egg.state ~= "Dropped") then
		return false, "That egg is unavailable."
	end
	if workspace:GetAttribute("Night") and egg.state == "Home" and not egg.nightEvent then
		return false, "Daytime nests are dormant during Moonrise."
	end
	if egg.immune == p and self:now() - egg.changed < 1 then
		return false, "Wait a moment before taking it back."
	end
	local root = self:root(p)
	if (root.Position - egg.model:GetPivot().Position).Magnitude > C.PickupRange then
		return false, "Move closer to the egg."
	end
	egg.state = "Carried"
	egg.revision += 1
	egg.claimed = true
	egg.carrier = p
	egg.changed = self:now()
	egg.immune = nil
	self.carry[p] = egg
	egg.prompt.Enabled = false
	egg.model:SetAttribute("State", "Carried")
	-- All visual parts weld to the root. Neither mass nor collision reduces running speed.
	egg.model:PivotTo(root.CFrame * CFrame.new(0, 0.1, -3))
	for _, v in ipairs(egg.model:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Anchored = false
			v.Massless = true
			local weld = Instance.new("WeldConstraint")
			weld.Name = "CarryWeld"
			weld.Part0 = root
			weld.Part1 = v
			weld.Parent = v
		end
	end
	pro.tutorial = math.max(pro.tutorial, 3)
	self:effect("pickup", { position = root.Position, rarity = egg.rarity })
	self:notify(p, "Egg taken! Escape to your camp.", "pickup")
	self:push(p)
	return true
end
function Game:unweld(egg)
	for _, v in ipairs(egg.model:GetDescendants()) do
		if v:IsA("WeldConstraint") and v.Name == "CarryWeld" then
			v:Destroy()
		end
	end
	for _, v in ipairs(egg.model:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Anchored = true
		end
	end
end
function Game:resetEgg(egg)
	if not egg or self.eggs[egg.id] ~= egg then
		return false
	end
	if egg.carrier then
		self.incubation:cancel(egg.carrier)
		self.carry[egg.carrier] = nil
	end
	self:unweld(egg)
	egg.carrier, egg.immune = nil, nil
	egg.revision += 1
	if egg.nightEvent and (workspace:GetAttribute("Night") ~= true or egg ~= self.nightEgg) then
		self:retireEgg(egg)
		return true
	end
	egg.state, egg.changed, egg.claimed = "Home", self:now(), false
	egg.model:PivotTo(CFrame.new(egg.nest.position))
	egg.model:SetAttribute("State", "Home")
	egg.prompt.Enabled = workspace:GetAttribute("Night") ~= true or egg.nightEvent
	return true
end
function Game:retireEgg(egg)
	if not egg or self.eggs[egg.id] ~= egg then
		return false
	end
	if egg.carrier then
		self.incubation:cancel(egg.carrier)
		self.carry[egg.carrier] = nil
		self:unweld(egg)
	end
	self.eggs[egg.id] = nil
	if egg.nest.egg == egg then
		egg.nest.egg = nil
	end
	egg.nest.respawn = self:now() + (egg.nest.respawnDelay or C.EggRespawnTime)
	if egg == self.nightEgg then
		self.nightEgg, self.nightNest = nil, nil
	end
	egg.carrier, egg.state = nil, "Resolved"
	egg.model:Destroy()
	return true
end

function Game:drop(p, reason)
	local egg = self.carry[p]
	if not egg then
		return false
	end
	self.incubation:cancel(p)
	egg.revision += 1
	local position = egg.model:GetPivot().Position
	self:unweld(egg)
	self.carry[p] = nil
	egg.carrier = nil
	egg.immune = p
	egg.state = "Dropped"
	egg.changed = self:now()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { self.world.decor }
	local result = workspace:Raycast(position + Vector3.new(0, 5, 0), Vector3.new(0, -60, 0), params)
	position = Vector3.new(position.X, result and result.Position.Y + 1.8 or 2, position.Z)
	egg.model:PivotTo(CFrame.new(position))
	egg.model:SetAttribute("State", "Dropped")
	egg.prompt.Enabled = true
	self:effect("drop", { position = position, rarity = egg.rarity })
	if reason == "bat" and self.profiles[p] then
		self:teleport(p, self.profiles[p].base.spawn)
		self:notify(p, "The egg was knocked loose! Return to the trail.", "hit")
	end
	self:push(p)
	return true
end
function Game:nearIncubator(p)
	local pro = self.profiles[p]
	local root = self:root(p)
	if not pro or not root then
		return nil
	end
	for _, element in ipairs(C.ElementOrder) do
		local slot = pro.base.incubators[element]
		if
			slot
			and R.within(
				root.Position,
				slot.pad.Position,
				C.IncubatorHalfExtent,
				C.IncubatorHalfExtent,
				C.IncubatorHeight
			)
		then
			return element
		end
	end
	return nil
end

function Game:beginIncubation(p, item, element)
	local pro = self.profiles[p]
	local slot = pro and pro.base.incubators[element]
	if not pro or self:busy(p) or not self:alive(p) then
		return false, "Finish your current activity before incubating."
	end
	if not C.Elements[element] or not slot then
		return false, "Choose Fire, Water, Wind, or Earth."
	end
	if pro.incubations[element] then
		return false, element .. " incubator is occupied."
	end
	if not R.eligible(item, p.UserId) or item.kind ~= "Egg" then
		return false, "Select an unlocked egg you own."
	end
	local model = Art.egg(item.rarity, self.world.dynamic, item.creature)
	model:PivotTo(CFrame.new(slot.pad.Position + Vector3.new(0, 2.5, 0)))
	item.state = "Incubating"
	item.element = element
	item.species = item.creature
	item.revision += 1
	pro.incubations[element] = {
		itemId = item.id,
		remaining = C.Rarities[item.rarity].hatch,
		model = model,
		element = element,
	}
	self:push(p)
	return true
end

function Game:secure(p, element)
	local pro = self.profiles[p]
	local egg = self.carry[p]
	if not pro or not egg or not self:alive(p) or self:busy(p) then
		return false, "No egg to secure."
	end
	local slot = pro.base.incubators[element]
	if not slot or not C.Elements[element] then
		return false, "Choose an elemental incubator at your camp."
	end
	if
		not R.within(
			self:root(p).Position,
			slot.pad.Position,
			C.IncubatorHalfExtent,
			C.IncubatorHalfExtent,
			C.IncubatorHeight
		)
	then
		return false, "Carry the egg onto your chosen elemental incubator."
	end
	if pro.incubations[element] then
		return false, element .. " incubator is occupied."
	end
	local item, err = self.inventory:create(p.UserId, "Egg", egg.rarity, egg.creature)
	if not item then
		return false, err
	end
	local ok, incErr = self:beginIncubation(p, item, element)
	if not ok then
		self.inventory.items[item.id] = nil
		return false, incErr
	end
	self.contracts:observe(p, egg.nightEvent and "night_secure" or "forest_secure")
	self:retireEgg(egg)
	pro.tutorial = math.max(pro.tutorial, 4)
	self:notify(p, egg.creature .. " egg secured in the " .. element .. " incubator.", "pickup")
	self:push(p)
	return true
end

function Game:incubate(p, id, element)
	local pro = self.profiles[p]
	local item = self.inventory.items[id]
	if not pro or self:busy(p) then
		return false, "Finish your other activity before incubating."
	end
	if type(id) ~= "string" or type(element) ~= "string" or not C.Elements[element] then
		return false, "Choose an egg and an elemental incubator."
	end
	local slot = pro.base.incubators[element]
	local root = self:root(p)
	if
		not root
		or not slot
		or not R.within(
			root.Position,
			slot.pad.Position,
			C.IncubatorHalfExtent,
			C.IncubatorHalfExtent,
			C.IncubatorHeight
		)
	then
		return false, "Stand at your chosen " .. element .. " incubator to place the egg."
	end
	return self:beginIncubation(p, item, element)
end

function Game:setPetMode(p, id, mode)
	local pro = self.profiles[p]
	local item = self.inventory.items[id]
	if not pro or self:busy(p) then
		return false, "Finish your current activity first."
	end
	if not item or item.ownerId ~= p.UserId or item.kind ~= "Pet" or item.state ~= "Inventory" then
		return false, "Select an available pet you own."
	end
	if mode == "Active" then
		local previous = pro.activePetId and self.inventory.items[pro.activePetId]
		if previous and previous.ownerId == p.UserId and previous.state == "Inventory" then
			previous.petMode = "Pen"
		end
		pro.activePetId = item.id
		item.petMode = "Active"
		self:notify(p, item.species .. " is now following you.", "tick")
	elseif mode == "Pen" then
		item.petMode = "Pen"
		if pro.activePetId == item.id then
			pro.activePetId = nil
		end
		self:notify(p, item.species .. " returned to the pet pen.", "tick")
	else
		return false, "Invalid pet mode."
	end
	item.revision += 1
	self:reconcilePets()
	self:push(p)
	return true
end

function Game:reconcilePets()
	local records = self.petRecords
	for _, record in ipairs(records:GetChildren()) do
		local item = self.inventory.items[record.Name]
		if not item or item.kind ~= "Pet" then
			record:Destroy()
		end
	end
	for owner, pro in pairs(self.profiles) do
		local active = pro.activePetId and self.inventory.items[pro.activePetId]
		if
			not active
			or active.ownerId ~= owner.UserId
			or active.kind ~= "Pet"
			or active.state ~= "Inventory"
			or active.petMode ~= "Active"
		then
			pro.activePetId = nil
		end
		local items = self.inventory:list(owner.UserId)
		local penCount = 0
		for _, item in ipairs(items) do
			if item.kind == "Pet" and item.state == "Inventory" and item.id ~= pro.activePetId then
				penCount += 1
			end
		end
		local capacity = C.Expansions[(pro.ranchLevel or 0) + 1].capacity
		pro.penPages = math.max(1, math.ceil(penCount / capacity))
		pro.penCount = penCount
		pro.penPage = math.clamp(pro.penPage or 1, 1, pro.penPages)
		local totalPets = 0
		for _, owned in ipairs(items) do
			if owned.kind == "Pet" then
				totalPets += 1
			end
		end
		pro.base.earningsLabel.Text = "YOUR RANCH\n"
			.. totalPets
			.. " pets • +"
			.. self.inventory:income(owner.UserId)
			.. " Coins/min"
		local index = 0
		for _, item in ipairs(items) do
			if item.kind == "Pet" then
				local unlocked = item.state == "Inventory"
				local activePet = unlocked and item.id == pro.activePetId
				if unlocked then
					item.petMode = activePet and "Active" or "Pen"
				end
				local record = records:FindFirstChild(item.id) or Instance.new("Folder")
				record.Name = item.id
				record:SetAttribute("OwnerUserId", item.ownerId)
				record:SetAttribute("BehaviorSeed", item.order)
				record:SetAttribute("PenCenter", pro.base.penCenter)
				record:SetAttribute("PenBounds", pro.base.penBounds)
				record:SetAttribute("Income", C.Rarities[item.rarity].income)
				record:SetAttribute("Favorite", item.favorite)
				record:SetAttribute("Training", pro.training == true)
				record:SetAttribute("Creature", item.creature)
				record:SetAttribute("Species", item.species)
				record:SetAttribute("Rarity", item.rarity)
				record:SetAttribute("Element", item.element)
				record:SetAttribute("Locked", not unlocked)
				record:SetAttribute("DisplayMode", activePet and "Active" or "Pen")
				local displayed = activePet
				local position = nil
				if unlocked and not activePet then
					index += 1
					local capacity = C.Expansions[(pro.ranchLevel or 0) + 1].capacity
					local page = math.floor((index - 1) / capacity) + 1
					local slot = (index - 1) % capacity + 1
					displayed = page == pro.penPage
					position = pro.base.penSlots[slot]
				end
				record:SetAttribute("DisplayIndex", index)
				record:SetAttribute("Displayed", displayed == true)
				record:SetAttribute("PenPosition", position)
				record.Parent = records
			end
		end
	end
	for owner in pairs(self.profiles) do
		self.ranch:updateRecords(owner, self:now())
	end
end

function Game:setPenPage(p, page)
	local pro = self.profiles[p]
	if
		not pro
		or self:busy(p)
		or type(page) ~= "number"
		or page ~= page
		or page % 1 ~= 0
		or page < 1
		or page > (pro.penPages or 1)
	then
		return false, "Choose an available pen page."
	end
	pro.penPage = page
	self:reconcilePets()
	self:push(p)
	return true
end

function Game:storeEgg(p)
	local pro, egg = self.profiles[p], self.carry[p]
	if not pro or not egg or self:busy(p) or not self:alive(p) then
		return false, "Carry an egg home first."
	end
	if not R.within(self:root(p).Position, pro.base.center, 19, 22, 12) then
		return false, "Return to your own camp to store the egg."
	end
	local item, err = self.inventory:create(p.UserId, "Egg", egg.rarity, egg.creature)
	if not item then
		return false, err
	end
	self.contracts:observe(p, egg.nightEvent and "night_secure" or "forest_secure")
	self:retireEgg(egg)
	self:notify(p, "Egg stored. Open Collection to choose its element later.", "pickup")
	self:push(p)
	return true
end

function Game:bat(p)
	if not self:alive(p) or self:busy(p) or not self:equipped(p, "Bat") then
		return false, "Equip your bat outside a duel."
	end
	if not self:rate(p, "bat", C.BatCooldown) then
		return false, "Cooldown"
	end
	local root = self:root(p)
	if self:safe(root.Position) then
		return false, "Safe zone: bats cannot hit players here."
	end
	self:effect("swing", { userId = p.UserId })
	for victim, egg in pairs(self.carry) do
		local target = self:root(victim)
		if
			victim ~= p
			and target
			and not self:safe(target.Position)
			and (target.Position - root.Position).Magnitude <= C.BatRange
		then
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { p.Character, victim.Character, self.world.dynamic, self.world.fx }
			local wall = workspace:Raycast(root.Position, target.Position - root.Position, params)
			if not wall then
				self:drop(victim, "bat")
				self:notify(p, "Clean hit! Pick up the dropped egg.", "hit")
				return true
			end
		end
	end
	return false, "Miss: get within 7 studs of an egg carrier."
end
function Game:buyUpgrade(p, nextTier)
	local pro = self.profiles[p]
	if not pro then
		return false, "No player profile."
	end
	return self.speedLab:buy(p, nextTier)
end
function Game:exchangeBegin(p, id, nonce)
	local pro = self.profiles[p]
	local item = self.inventory.items[id]
	if not pro or not self:alive(p) or self:busy(p) then
		return false, "You cannot use the Exchange right now."
	end
	if not R.id(id) or not R.id(nonce) or not R.transferable(item, p.UserId) then
		return false, "Choose an unlocked, unreserved item. Send active pets to the pen first."
	end
	if (self:root(p).Position - self.world.exchangeShop.Position).Magnitude > C.ShopRange then
		return false, "Visit the Exchange."
	end
	local key = "exchange:" .. HttpService:GenerateGUID(false)
	local ok, err = self.inventory:reserveOffer(p.UserId, { id }, key, "Exchange")
	if not ok then
		return false, err
	end
	local duration = item.rarity == "Godly" and C.GodlyHold or C.ExchangeHold
	local fingerprint = key .. "|" .. id .. "|" .. tostring(item.revision)
	local hold, holdErr = self.holds:begin(p, "exchange", fingerprint, duration, nonce)
	if not hold then
		self.inventory:release(key)
		return false, holdErr
	end
	pro.exchange = {
		key = key,
		id = id,
		fingerprint = fingerprint,
		expires = hold.expires,
		token = hold.token,
		revision = item.revision,
		value = R.exchangeValue(item),
	}
	p:SetAttribute("Busy", true)
	self:feed(p, "exchangeHold", {
		nonce = hold.nonce,
		started = hold.started,
		token = hold.token,
		duration = duration,
		item = self.inventory:snapshotItem(item),
		value = R.exchangeValue(item),
	})
	self:push(p)
	return true
end

function Game:exchangeComplete(p, token)
	local pro = self.profiles[p]
	local x = pro and pro.exchange
	if not x then
		return false, "No Exchange confirmation is active."
	end
	local item = self.inventory.items[x.id]
	if
		not self:alive(p)
		or self:now() >= x.expires
		or (self:root(p).Position - self.world.exchangeShop.Position).Magnitude > C.ShopRange
		or not item
		or item.revision ~= x.revision
		or R.exchangeValue(item) ~= x.value
		or pro.duel
		or pro.trade
		or pro.trial
	then
		self:exchangeCancel(p, "Exchange canceled: item, activity, or position changed.")
		return false, "Exchange conditions changed. Review the item again."
	end
	local ok, err = self.holds:consume(p, "exchange", x.fingerprint, token)
	if not ok then
		return false, err
	end
	local done, value = self.inventory:exchange(p.UserId, x.id, x.key, pro.money)
	if not done then
		self.inventory:release(x.key)
		pro.exchange = nil
		p:SetAttribute("Busy", pro.duel ~= nil or pro.trade ~= nil or p:GetAttribute("InTrial") == true)
		return false, value
	end
	pro.exchange = nil
	p:SetAttribute("Busy", pro.duel ~= nil or pro.trade ~= nil or p:GetAttribute("InTrial") == true)
	self:reconcilePets()
	self:notify(p, "Exchange complete: +" .. tostring(value) .. " Coins.", "win")
	self:push(p)
	return true
end

function Game:exchangeCancel(p, reason)
	local pro = self.profiles[p]
	local x = pro and pro.exchange
	if not x then
		return false, "No Exchange confirmation is active."
	end
	self.holds:cancel(p)
	self.inventory:release(x.key)
	pro.exchange = nil
	p:SetAttribute("Busy", pro.duel ~= nil or pro.trade ~= nil or p:GetAttribute("InTrial") == true)
	if reason then
		self:notify(p, reason)
	end
	self:push(p)
	return true
end

function Game:buyTrap(p)
	local pro, root = self.profiles[p], self:root(p)
	if not self:alive(p) or self:busy(p) or (root.Position - self.world.shop.Position).Magnitude > C.ShopRange then
		return false, "Visit Trail Supplies while available."
	end
	if #self.inventory:consumables(p.UserId, false) >= C.MaxTrapCharges then
		return false, "You can carry five snare pods."
	end
	if pro.money.Value < C.TrapCost then
		return false, "Need " .. C.TrapCost .. " Coins for a snare pod."
	end
	local item, err = self.inventory:createConsumable(p.UserId, "SnarePod")
	if not item then
		return false, err
	end
	pro.money.Value -= C.TrapCost
	self:push(p)
	self:notify(p, "Snare pod purchased. It is also tradable and exchangeable.", "pickup")
	return true
end

function Game:placeTrap(p)
	local pro = self.profiles[p]
	local root = self:root(p)
	if not self:alive(p) or self:busy(p) or not self:equipped(p, "SnarePod") then
		return false, "Equip a snare pod outside a duel."
	end
	if not self:rate(p, "trap", 1) then
		return false, "Cooldown"
	end
	local pod = self.inventory:consumables(p.UserId, true)[1]
	if not pod then
		return false, "Buy more pods at Trail Supplies."
	end
	local pos = root.Position + root.CFrame.LookVector * 5
	if self:safe(pos) or pos.Z > 190 or math.abs(pos.X) > 85 then
		return false, "Place snares on the Forest trail, outside the safe zone."
	end
	local count = 0
	for _, t in ipairs(self.traps) do
		if t.owner == p then
			count += 1
		end
	end
	if count >= C.MaxTraps then
		return false, "You already have two active snares."
	end
	pos = Vector3.new(pos.X, 0.36, pos.Z)
	local trap = Art.part(
		self.world.dynamic,
		"Snare",
		Vector3.new(0.25, 5, 5),
		CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2),
		C.Colors.Mint,
		Enum.PartType.Cylinder,
		Enum.Material.Neon
	)
	local label = Art.billboard(trap, "ARMING…", C.Colors.Mint, 150, 30, Vector3.new(0, 1.5, 0))
	local consumed, err = self.inventory:consume(p.UserId, pod.id, "SnarePod")
	if not consumed then
		trap:Destroy()
		return false, err
	end
	table.insert(self.traps, {
		owner = p,
		part = trap,
		label = label,
		armed = self:now() + C.TrapArmTime,
		expires = self:now() + C.TrapLifetime,
	})
	self:notify(p, "Snare deployed. It slows enemy egg carriers.", "tick")
	self:push(p)
	return true
end
function Game:push(p)
	local pro = self.profiles[p]
	if not pro or p.Parent ~= Players then
		return
	end
	local egg = self.carry[p]
	local incubators = {}
	for _, element in ipairs(C.ElementOrder) do
		local inc = pro.incubations[element]
		if inc then
			local item = self.inventory.items[inc.itemId]
			incubators[element] = {
				remaining = inc.remaining,
				rarity = item and item.rarity or "Common",
				creature = item and item.creature or "Unknown",
			}
		end
	end
	pro.charges = #self.inventory:consumables(p.UserId, true)
	local snapshot = {
		onboardingComplete = pro.onboardingComplete == true,
		hatched = pro.hatched,
		build = C.Build,
		speed = pro.speed.Value,
		money = pro.money.Value,
		tier = pro.tier,
		charges = pro.charges,
		base = p:GetAttribute("BaseIndex"),
		training = pro.training,
		drafting = pro.drafting == true,
		autoHatch = false,
		activePetId = pro.activePetId,
		penPage = pro.penPage,
		penPages = pro.penPages or 1,
		penCount = pro.penCount or 0,
		items = self.inventory:snapshot(p.UserId),
		income = self.inventory:income(p.UserId),
		carrying = egg and egg.rarity or nil,
		carryingCreature = egg and egg.creature or nil,
		tutorial = pro.tutorial,
		incubators = incubators,
		lab = self.speedLab:snapshot(p),
		trial = self.trials:snapshot(p),
		sprint = self.sprints:snapshot(p),
		contracts = self.contracts:snapshot(p),
		ranchLevel = pro.ranchLevel,
		ranchCapacity = C.Expansions[pro.ranchLevel + 1].capacity,
		ranch = self.ranch:snapshot(p),
		trade = self.trades:snapshot(p),
		duel = self.duels:snapshot(p),
		result = pro.result and pro.result.untilTime > self:now() and pro.result or nil,
		serverTime = self:now(),
		bossEnabled = workspace:GetAttribute("BossEnabled"),
		studio = RunService:IsStudio(),
	}
	-- Replicated diagnostic inventory mirrors authoritative records, never the reverse.
	local seen = {}
	for _, item in ipairs(snapshot.items) do
		seen[item.id] = true
		local entry = pro.inventoryFolder:FindFirstChild(item.id)
		if not entry then
			entry = Instance.new("Folder")
			entry.Name = item.id
			entry.Parent = pro.inventoryFolder
		end
		for key, value in pairs(item) do
			if key ~= "id" then
				entry:SetAttribute(key, value)
			end
		end
	end
	for _, entry in ipairs(pro.inventoryFolder:GetChildren()) do
		if not seen[entry.Name] then
			entry:Destroy()
		end
	end
	self.net.State:FireClient(p, snapshot)
end
function Game:pushAll()
	for p in pairs(self.profiles) do
		self:push(p)
	end
end
function Game:tradeTargets(p)
	local out = {}
	local root = self:root(p)
	if not root or (root.Position - self.world.tradingPost.Position).Magnitude > C.ShopRange + 8 then
		return out
	end
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= p and self:alive(other) then
			local otherRoot = self:root(other)
			local pro = self.profiles[other]
			if
				otherRoot
				and pro
				and (otherRoot.Position - root.Position).Magnitude <= C.TradeRange
				and (otherRoot.Position - self.world.tradingPost.Position).Magnitude <= C.ShopRange + 8
			then
				table.insert(out, {
					userId = other.UserId,
					name = other.DisplayName,
					unlocked = pro.hatched >= 3 and pro.onboardingComplete == true,
				})
			end
		end
	end
	return out
end

function Game:action(p, name, data)
	if type(name) ~= "string" or #name > 32 or not self.profiles[p] then
		return false, "Invalid request."
	end
	if type(data) ~= "table" then
		data = {}
	end
	if not self:rate(p, "network:" .. name, name == "sync" and 0.15 or 0.02) then
		return false, "Cooldown"
	end
	if name == "sync" then
		self:push(p)
		return true
	elseif name == "bat" then
		return self:bat(p)
	elseif name == "shoot" then
		return self.duels:shoot(p, data.direction)
	elseif name == "trap" then
		return self:placeTrap(p)
	elseif name == "upgrade" then
		return self:buyUpgrade(p, data.tier)
	elseif name == "overdrive" then
		return self.speedLab:activate(p)
	elseif name == "precision" then
		return self.speedLab:setPrecision(p, data.active)
	elseif name == "tuning" then
		return self.speedLab:setTuning(p, data.name)
	elseif name == "trialStart" then
		return self.trials:start(p)
	elseif name == "trialCancel" then
		return self.trials:finish(p, false, "Trial canceled. No record changed.")
	elseif name == "sprintReply" then
		return self.sprints:reply(p, data.accept)
	elseif name == "sprintCancel" then
		return self.sprints:cancel(p)
	elseif name == "contractClaim" then
		return self.contracts:claim(p, data.id)
	elseif name == "ranchExpand" then
		return self.ranch:buyExpansion(p, data.level)
	elseif name == "ranchInspect" then
		local ok, result = self.ranch:inspect(p, data.id)
		if ok then
			self:feed(p, "visitorPet", result)
			return true
		end
		return false, result
	elseif name == "ranchReact" then
		return self.ranch:react(p, data.id, data.reaction)
	elseif name == "ranchRevere" then
		local owner = R.integer(data.userId, -100000000000, 100000000000) and Players:GetPlayerByUserId(data.userId)
			or nil
		return self.ranch:requestReverence(p, owner)
	elseif name == "tradeRequest" then
		local target = R.integer(data.userId, -100000000000, 100000000000) and Players:GetPlayerByUserId(data.userId)
			or nil
		return self.trades:request(p, target)
	elseif name == "tradeReply" then
		return self.trades:reply(p, data.accept)
	elseif name == "tradeOffer" then
		return self.trades:offer(p, data.ids, data.revision)
	elseif name == "tradeHoldBegin" then
		return self.trades:beginHold(p, data.nonce)
	elseif name == "tradeHoldComplete" then
		return self.trades:completeHold(p, data.token, data.stage)
	elseif name == "tradeCancel" then
		return self.trades:cancel(p)
	elseif name == "exchangeBegin" then
		return self:exchangeBegin(p, data.id, data.nonce)
	elseif name == "exchangeComplete" then
		return self:exchangeComplete(p, data.token)
	elseif name == "exchangeCancel" then
		return self:exchangeCancel(p, "Exchange canceled. Item returned.")
	elseif name == "buyTrap" then
		return self:buyTrap(p)
	elseif name == "incubate" then
		return self.incubation:preview(p, data.element, data.id)
	elseif name == "incubationHold" then
		return self.incubation:hold(p, data.id, data.nonce)
	elseif name == "incubationConfirm" then
		return self.incubation:confirm(p, data.id, data.token)
	elseif name == "incubationCancel" then
		self.incubation:cancel(p)
		return true
	elseif name == "holdCancel" then
		if not R.id(data.nonce) then
			return false, "Invalid hold identity."
		end
		local h = self.holds.active[p]
		if h and h.nonce == data.nonce then
			if h.kind == "exchange" then
				return self:exchangeCancel(p)
			end
			self.holds:cancel(p, data.nonce)
		end
		return true
	elseif name == "itemLock" then
		if self:busy(p) then
			return false, "Finish your current activity first."
		end
		local ok, err = self.inventory:setLocked(p.UserId, data.id, data.locked)
		if ok then
			self:reconcilePets()
			self:push(p)
		end
		return ok, err
	elseif name == "autoHatch" then
		return false, "Choose an elemental incubator for each egg."
	elseif name == "store" then
		return self:storeEgg(p)
	elseif name == "penPage" then
		return self:setPenPage(p, data.page)
	elseif name == "petMode" then
		return self:setPetMode(p, data.id, data.mode)
	elseif name == "drop" then
		return self:drop(p, "manual")
	elseif name == "reply" then
		return self.duels:reply(p, data.accept)
	elseif name == "select" then
		return self.duels:select(p, data.id)
	elseif name == "confirm" then
		return self.duels:confirm(p, data.revision)
	elseif name == "cancel" then
		return self.duels:cancel(p, data.forfeit)
	elseif name == "debugBoss" and RunService:IsStudio() and type(data.enabled) == "boolean" then
		workspace:SetAttribute("BossEnabled", data.enabled)
		self.world.guardian:PivotTo(CFrame.new(self.world.guardianHome))
		self:pushAll()
		return true
	elseif name == "debugNight" and RunService:IsStudio() then
		self:setNight(not workspace:GetAttribute("Night"))
		return true
	elseif name == "debugItems" and RunService:IsStudio() then
		if self:busy(p) then
			return false, "Finish your current activity first."
		end
		if not self:rate(p, "debugItems", 2) then
			return false, "Cooldown"
		end
		self.inventory:create(p.UserId, "Egg", "Common", "Skunk")
		self.inventory:create(p.UserId, "Egg", "Epic", "Dragon")
		local pet = self.inventory:create(p.UserId, "Pet", "Rare", "Gorilla", "Water")
		if pet then
			self.ranch:acquired(p, pet)
		end
		self:reconcilePets()
		self:push(p)
		return true
	elseif name == "debugCoins" and RunService:IsStudio() then
		if not self:rate(p, "debugCoins", 0.5) then
			return false, "Cooldown"
		end
		local pro = self.profiles[p]
		pro.money.Value = math.min(C.MaxCoins, pro.money.Value + 250000)
		self:notify(p, "Studio funds added: +250,000 Coins.", "win")
		self:push(p)
		return true
	elseif name == "debugRanch" and RunService:IsStudio() then
		if self:busy(p) then
			return false, "Finish your current activity first."
		end
		if not self:rate(p, "debugRanch", 1) then
			return false, "Cooldown"
		end
		local pro = self.profiles[p]
		local target = C.Expansions[pro.ranchLevel + 1].capacity
		local current = 0
		for _, item in ipairs(self.inventory:list(p.UserId)) do
			if item.kind == "Pet" then
				current += 1
			end
		end
		local added = 0
		for index = current + 1, target do
			local spec = STUDIO_RANCH_PETS[((index - 1) % #STUDIO_RANCH_PETS) + 1]
			local pet = self.inventory:create(p.UserId, "Pet", spec[1], spec[2], spec[3])
			if pet then
				self.ranch:acquired(p, pet)
				added += 1
			end
		end
		self:reconcilePets()
		self:notify(p, "Studio ranch filled: " .. tostring(current + added) .. " / " .. tostring(target) .. " pets.", "win")
		self:push(p)
		return true
	elseif name == "debugMaxRanch" and RunService:IsStudio() then
		if self:busy(p) then
			return false, "Finish your current activity first."
		end
		if not self:rate(p, "debugMaxRanch", 1) then
			return false, "Cooldown"
		end
		local pro = self.profiles[p]
		pro.money.Value = math.max(pro.money.Value, 250000)
		pro.ranchLevel = #C.Expansions - 1
		pro.penPage = 1
		pro.activePetId = nil
		for _, item in ipairs(self.inventory:list(p.UserId)) do
			if item.kind == "Pet" and item.state == "Inventory" then
				item.petMode = "Pen"
			end
		end
		pro.base.applyExpansion(pro.ranchLevel)
		local target = C.Expansions[pro.ranchLevel + 1].capacity
		local current = 0
		for _, item in ipairs(self.inventory:list(p.UserId)) do
			if item.kind == "Pet" then
				current += 1
			end
		end
		for index = current + 1, target do
			local spec = STUDIO_RANCH_PETS[((index - 1) % #STUDIO_RANCH_PETS) + 1]
			local pet = self.inventory:create(p.UserId, "Pet", spec[1], spec[2], spec[3])
			if pet then
				self.ranch:acquired(p, pet)
			end
		end
		self:reconcilePets()
		self:notify(p, "Grand Ranch test loaded: full display + 250,000 Coins.", "win")
		self:push(p)
		return true
	end
	return false, "Unknown action."
end
function Game:setNight(enabled)
	if type(enabled) ~= "boolean" then
		return false
	end
	local wasNight = workspace:GetAttribute("Night") == true
	if wasNight == enabled then
		return true
	end
	workspace:SetAttribute("Night", enabled)
	self.phaseEnds = self:now() + (enabled and C.NightDuration or R.nextNight(self.rng))
	workspace:SetAttribute("PhaseEnds", self.phaseEnds)
	for _, nest in ipairs(self.world.nests) do
		if nest.egg and nest.egg.state == "Home" then
			nest.egg.prompt.Enabled = not enabled
		end
		nest.part:SetAttribute("Dormant", enabled)
	end
	if enabled then
		self.nightEpoch = (self.nightEpoch or 0) + 1
		local spot = self.world.hiddenNightSpots[self.rng:NextInteger(1, #self.world.hiddenNightSpots)]
		local nest = {
			id = "night-" .. self.nightEpoch,
			position = spot,
			event = true,
			creature = C.Creatures[self.rng:NextInteger(1, #C.Creatures)],
		}
		self.nightNest = nest
		self:spawnEgg(nest, R.roll(self.rng, C.NightWeights), nest.creature)
		self.nightEgg = nest.egg
		-- Broad local clue region, deliberately offset from the actual hiding place.
		local region = Vector3.new(math.floor(spot.X / 35) * 35 + 17.5, 1, math.floor(spot.Z / 35) * 35 + 17.5)
		self.world.shrine:SetAttribute("Awake", true)
		self.world.shrine:SetAttribute("ClueRegion", region)
		self:effect("night", { shrine = self.world.shrine.Position })
		for p in pairs(self.profiles) do
			self:notify(
				p,
				"MOONRISE • Nests are dormant. Search the Forest for one hidden egg. Hatching runs at 30x.",
				"night"
			)
		end
	else
		local retired = {}
		for _, egg in pairs(self.eggs) do
			if egg.nightEvent and egg.state == "Home" then
				table.insert(retired, egg)
			end
		end
		for _, egg in ipairs(retired) do
			self:retireEgg(egg)
		end
		self.world.shrine:SetAttribute("Awake", false)
		self.world.shrine:SetAttribute("ClueRegion", nil)
	end
	self:pushAll()
	return true
end

function Game:bossStep(dt, now)
	local w = self.world
	local boss = w.guardian
	local targetEgg
	local closest = math.huge
	if workspace:GetAttribute("BossEnabled") == false then
		w.guardianLabel.Text = "THE GROVE WARDEN\nPaused for Studio testing"
		return
	end
	local bpos = boss:GetPivot().Position
	for _, egg in pairs(self.eggs) do
		local root = egg.carrier and self:root(egg.carrier)
		if
			not egg.nightEvent
			and ((egg.state == "Carried" and root and not self:safe(root.Position)) or egg.state == "Dropped")
		then
			local pos = root and root.Position or egg.model:GetPivot().Position
			local d = (pos - bpos).Magnitude
			if d < closest and now - egg.changed > C.BossAlertDelay then
				closest = d
				targetEgg = egg
			end
		end
	end
	local target = w.guardianHome
	local speed = 18
	if targetEgg then
		local root = targetEgg.carrier and self:root(targetEgg.carrier)
		target = root and root.Position or targetEgg.model:GetPivot().Position
		speed = C.Rarities[targetEgg.rarity].boss
		w.guardianLabel.Text = targetEgg.state == "Carried" and "GROVE WARDEN • CHASING"
			or "GROVE WARDEN • RECOVERING"
	else
		w.guardianLabel.Text = "THE GROVE WARDEN\nGuarding the nests"
	end
	target = Vector3.new(target.X, 4, math.max(C.SafeBoundaryZ + 3, target.Z))
	local delta = target - bpos
	local length = delta.Magnitude
	if length > 0.15 then
		local position, direction = self.navigation:advance(bpos, target, speed, dt, now)
		if direction then
			boss:PivotTo(CFrame.lookAt(position, position + direction))
		end
	end
	if targetEgg and length <= C.CatchDistance then
		if targetEgg.carrier then
			local victim = targetEgg.carrier
			self:resetEgg(targetEgg)
			self:teleport(victim, self.profiles[victim].base.spawn)
			self:notify(victim, "Caught by the Warden. Train more Speed and try again.", "hit")
			self:push(victim)
		elseif targetEgg.state == "Dropped" and now - targetEgg.changed > 1 then
			self:resetEgg(targetEgg)
		end
	end
end
function Game:step(dt)
	local now = self:now()
	self.holds:step(now)
	self.incubation:step()
	self.duels:step(now)
	self.ranch:step(now)
	self.trades:step(now)
	self.sprints:step(dt, now)
	for p, pro in pairs(self.profiles) do
		if
			pro.exchange
			and (
				now >= pro.exchange.expires
				or not self:alive(p)
				or (self:root(p).Position - self.world.exchangeShop.Position).Magnitude > C.ShopRange
			)
		then
			self:exchangeCancel(p, "Exchange interrupted. Item returned.")
		end
	end
	if now >= self.phaseEnds then
		self:setNight(not workspace:GetAttribute("Night"))
	end
	self:updateTrainingState()
	for p, pro in pairs(self.profiles) do
		self.speedLab:step(p, dt, now)
		local newMoney, remainder = R.credit(pro.money.Value, pro.coinRemainder, self.inventory:income(p.UserId), dt)
		pro.money.Value = newMoney
		pro.coinRemainder = remainder
		if pro.trial then
			self.trials:step(p, dt, now)
		end
		for _, element in ipairs(C.ElementOrder) do
			local inc = pro.incubations[element]
			local slot = pro.base.incubators[element]
			if inc then
				local multiplier = workspace:GetAttribute("Night") and C.NightMultiplier or 1
				inc.remaining = math.max(0, inc.remaining - dt * multiplier)
				local item = self.inventory.items[inc.itemId]
				slot.timer.Text = element:upper()
					.. " • "
					.. (item and item.creature:upper() or "EGG")
					.. "\n"
					.. R.clock(inc.remaining)
					.. (multiplier > 1 and " • 30x" or "")
				if inc.remaining <= 0 and item then
					item.kind = "Pet"
					item.state = "Inventory"
					item.element = element
					self.inventory:refreshName(item)
					if pro.activePetId == nil then
						pro.activePetId = item.id
						item.petMode = "Active"
					else
						item.petMode = "Pen"
					end
					inc.model:Destroy()
					pro.incubations[element] = nil
					pro.tutorial = math.max(pro.tutorial, 5)
					pro.hatched += 1
					self.contracts:observe(p, "hatch")
					if pro.tier > 1 then
						pro.tutorial = 6
						pro.onboardingComplete = true
					end
					self.ranch:acquired(p, item)
					self:effect("hatch", {
						position = slot.pad.Position + Vector3.new(0, 3, 0),
						rarity = item.rarity,
						element = element,
					})
					self:notify(
						p,
						item.species .. " hatched! +" .. C.Rarities[item.rarity].income .. " Coins/min.",
						"win"
					)
					self:reconcilePets()
					self:push(p)
				end
			else
				slot.timer.Text = element:upper() .. " INCUBATOR\nAvailable"
			end
		end
		if pro.slowUntil > 0 and now >= pro.slowUntil then
			pro.slowUntil = 0
			self:applySpeed(p)
		end
	end
	-- Traps and bat results are independent of BossEnabled.
	for i = #self.traps, 1, -1 do
		local trap = self.traps[i]
		local remove = now >= trap.expires or trap.owner.Parent ~= Players
		if not remove and now >= trap.armed then
			trap.label.Text = "SNARE • " .. math.ceil(trap.expires - now) .. "s"
			for carrier in pairs(self.carry) do
				local root = self:root(carrier)
				if
					carrier ~= trap.owner
					and root
					and not self:safe(root.Position)
					and (Vector3.new(root.Position.X, trap.part.Position.Y, root.Position.Z) - trap.part.Position).Magnitude
						< C.TrapRadius
				then
					self.profiles[carrier].slowUntil = now + C.TrapSlowTime
					self:applySpeed(carrier)
					self:notify(carrier, "Snared! Slowed for 2.5 seconds.", "hit")
					self:effect("snare", { position = root.Position })
					remove = true
					break
				end
			end
		end
		if remove then
			trap.part:Destroy()
			table.remove(self.traps, i)
		end
	end
	self:bossStep(dt, now)
	if not workspace:GetAttribute("Night") then
		for _, nest in ipairs(self.world.nests) do
			if not nest.egg and (not nest.respawn or now >= nest.respawn) then
				self:spawnEgg(nest, nest.fixedRarity or R.roll(self.rng, C.DayWeights), nest.creature)
			elseif not nest.egg and nest.fixedRarity and nest.label then
				nest.label.Text = "GODLY GROVE\nReturns in " .. R.clock(nest.respawn - now)
			end
		end
	end
	self.syncTime += dt
	if self.syncTime >= 0.5 then
		self.syncTime = 0
		self:pushAll()
	end
end
function Game.new()
	local self = setmetatable({
		profiles = {},
		carry = {},
		eggs = {},
		traps = {},
		syncTime = 0,
		rng = Random.new(),
		inventory = Inventory.new(),
	}, Game)
	R.validate()
	self.world = World.build()
	self.navigation = Navigation.new(self.world.decor)
	self.holds = Holds.new(self)
	self.incubation = Incubation.new(self)
	self.speedLab = SpeedLab.new(self)
	self.trials = Trials.new(self)
	self.sprints = Sprint.new(self)
	self.contracts = Contracts.new(self)
	self.ranch = Ranch.new(self)
	self.trades = Trade.new(self)
	self.duels = Duel.new(self)
	local folder = Instance.new("Folder")
	folder.Name = "Stage3Net"
	folder.Parent = ReplicatedStorage
	self.net = {}
	for _, name in ipairs({ "Request", "State", "Feed", "Effect" }) do
		local e = Instance.new("RemoteEvent")
		e.Name = name
		e.Parent = folder
		self.net[name] = e
	end
	if RunService:IsStudio() and workspace:GetAttribute("Stage3AutoTest") == true then
		local diagnostic = Instance.new("RemoteEvent")
		diagnostic.Name = "ClientDiagnostics"
		diagnostic.Parent = folder
		self.clientDiagnostics = {}
		diagnostic.OnServerEvent:Connect(function(p, data)
			if type(data) == "table" and type(data.token) == "string" then
				self.clientDiagnostics[p] = data
			end
		end)
	end
	self.petRecords = Instance.new("Folder")
	self.petRecords.Name = "PetRecords"
	self.petRecords.Parent = folder
	workspace:SetAttribute("BossEnabled", true)
	workspace:SetAttribute("Night", false)
	workspace:SetAttribute("Stage3Build", C.Build)
	self.phaseEnds = self:now() + R.nextNight(self.rng)
	workspace:SetAttribute("PhaseEnds", self.phaseEnds)
	for _, nest in ipairs(self.world.nests) do
		self:spawnEgg(nest, nest.fixedRarity or R.roll(self.rng, C.DayWeights), nest.creature)
	end
	for _, b in ipairs(self.world.bases) do
		self:prompt(b.treadmill, "Trainer options", "Your Speed Lab", function(p)
			if b.owner == p then
				self:feed(p, "openShop", { shop = "trainer" })
			else
				self:notify(p, "Use the Speed Lab at your own camp.")
			end
		end)
		for _, element in ipairs(C.ElementOrder) do
			local slot = b.incubators[element]
			local prompt = self:prompt(slot.pad, "Review Egg", element .. " Incubator", function(p)
				if b.owner ~= p then
					self:notify(p, "This incubator belongs to another camp.")
					return
				end
				local pro = self.profiles[p]
				if pro and pro.incubatorPreview then
					return -- The open preview owns confirmation until it is closed.
				end
				if self.carry[p] then
					local ok, err = self.incubation:preview(p, element)
					if not ok then
						self:notify(p, err)
					end
				else
					self:feed(p, "selectIncubatorEgg", { element = element })
				end
			end)
			prompt.Name = "IncubatorPrompt"
			prompt.HoldDuration = 0
			prompt:SetAttribute("Element", element)
			prompt:SetAttribute("BaseIndex", b.index)
			slot.prompt = prompt
		end
	end
	for _, b in ipairs(self.world.bases) do
		self:prompt(b.penGate, "Honor Godly", "Ranch Gate", function(visitor)
			if b.owner and b.owner ~= visitor then
				local ok, err = self.ranch:requestReverence(visitor, b.owner)
				if not ok then
					self:notify(visitor, err)
				end
			end
		end)
	end
	self:prompt(self.world.trainerShop, "Open upgrades", "Trainer Workshop", function(p)
		self:feed(p, "openShop", { shop = "trainer" })
	end)
	self:prompt(self.world.rangerStation, "Review contracts", "Ranger Station", function(p)
		if self:busy(p) then
			self:notify(p, "Finish your current activity before reviewing contracts.")
			return
		end
		self:feed(p, "openContracts", {})
	end)
	self:prompt(self.world.trialStart, "Start Trial", "Grove Circuit", function(p)
		local ok, err = self.trials:start(p)
		if not ok then
			self:notify(p, err)
		end
	end)
	self:prompt(self.world.ranchShop, "Ranch upgrades", "Ranch & Pen Works", function(p)
		local pro = self.profiles[p]
		if not pro then
			return
		end
		local nextLevel = pro.ranchLevel + 1
		if nextLevel >= #C.Expansions then
			self:notify(p, "Grand Ranch already built.")
			return
		end
		local spec = C.Expansions[nextLevel + 1]
		self:feed(p, "ranchUpgrade", {
			level = nextLevel,
			name = spec.name,
			cost = spec.cost,
			capacity = spec.capacity,
		})
	end)
	self:prompt(self.world.tradingPost, "Find trader", "Trading Post", function(p)
		self:feed(p, "openTrade", {
			targets = self:tradeTargets(p),
			unlocked = self.profiles[p].hatched >= 3 and self.profiles[p].onboardingComplete == true,
		})
	end)
	self:prompt(self.world.exchangeShop, "Open Exchange", "The Exchange", function(p)
		self:feed(p, "openExchange", {})
	end)
	self:prompt(self.world.shop, "Buy snare • 15 coins", "Trail Supplies", function(p)
		local ok, err = self:buyTrap(p)
		if not ok then
			self:notify(p, err)
		end
	end)
	self.net.Request.OnServerEvent:Connect(function(p, name, data)
		local ok, err = self:action(p, name, data)
		if not ok and err and err ~= "Cooldown" and self:rate(p, "errorToast", 0.8) then
			self:notify(p, err)
		end
	end)
	Players.PlayerAdded:Connect(function(p)
		self:setup(p)
	end)
	Players.PlayerRemoving:Connect(function(p)
		self.incubation:cancel(p)
		self.holds:cancel(p)
		self.trades:leaving(p)
		self.sprints:leaving(p)
		self.contracts:remove(p)
		self.duels:leaving(p)
		if self.carry[p] then
			self:resetEgg(self.carry[p])
		end
		local pro = self.profiles[p]
		if pro and pro.exchange then
			self:exchangeCancel(p)
		end
		if pro then
			for _, element in ipairs(C.ElementOrder) do
				local inc = pro.incubations[element]
				if inc then
					inc.model:Destroy()
				end
				pro.base.incubators[element].timer.Text = element:upper() .. " INCUBATOR\nAvailable"
			end
			pro.base.owner = nil
			pro.base.nameLabel.Text = "AVAILABLE BASE"
		end
		self.inventory:removeOwner(p.UserId)
		self.ranch:leaving(p)
		self.profiles[p] = nil
		self:reconcilePets()
	end)
	for _, p in ipairs(Players:GetPlayers()) do
		self:setup(p)
	end
	local elapsed = 0
	self.heartbeat = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.05 then
			return
		end
		local step = elapsed
		elapsed = 0
		self:step(step)
	end)
	print("[STAGE3] " .. C.Build .. " ready. Private vertical slice; progress is session-only.")
	return self
end
return Game
