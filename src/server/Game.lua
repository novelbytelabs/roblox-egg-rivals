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
local Game = {}
Game.__index = Game
function Game:now()
	return workspace:GetServerTimeNow()
end
function Game:root(p)
	return p.Character and p.Character:FindFirstChild("HumanoidRootPart")
end
function Game:humanoid(p)
	return p.Character and p.Character:FindFirstChildOfClass("Humanoid")
end
function Game:alive(p)
	local h = self:humanoid(p)
	return self.profiles[p] ~= nil and p.Parent == Players and h ~= nil and h.Health > 0 and self:root(p) ~= nil
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
	elseif pro.slowUntil > self:now() then
		h.WalkSpeed = 6
	else
		h.WalkSpeed = R.speed(pro.speed.Value)
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
	money.Name = "Money"
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
		charges = 1,
		slowUntil = 0,
		duel = nil,
		rates = {},
		training = false,
		tutorial = 1,
		trainCarry = 0,
		incomeCarry = 0,
	}
	self.profiles[p] = pro
	p:SetAttribute("InDuel", false)
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
		h.Died:Connect(function()
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
function Game:spawnEgg(nest, rarity)
	if nest.egg then
		return
	end
	local creature = C.Rarities[rarity].creature
	local model = Art.egg(rarity, self.world.dynamic, creature)
	model:PivotTo(CFrame.new(nest.position))
	local id = "nest-" .. nest.id
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
	}
	model:SetAttribute("EggId", id)
	model:SetAttribute("State", "Home")
	egg.prompt = self:prompt(model.PrimaryPart, "Take Egg", rarity .. " " .. creature .. " Egg", function(p)
		local ok, err = self:take(p, id)
		if not ok then
			self:notify(p, err)
		end
	end)
	nest.egg = egg
	self.eggs[id] = egg
end
function Game:take(p, id)
	local egg = self.eggs[id]
	local pro = self.profiles[p]
	if not self:alive(p) or not pro or pro.duel then
		return false, "Finish your current duel first."
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
	if egg.immune == p and self:now() - egg.changed < 1 then
		return false, "Wait a moment before taking it back."
	end
	local root = self:root(p)
	if (root.Position - egg.model:GetPivot().Position).Magnitude > C.PickupRange then
		return false, "Move closer to the egg."
	end
	egg.state = "Carried"
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
	if egg.carrier then
		self.carry[egg.carrier] = nil
	end
	self:unweld(egg)
	egg.carrier = nil
	egg.immune = nil
	egg.state = "Home"
	egg.changed = self:now()
	egg.model:PivotTo(CFrame.new(egg.nest.position))
	egg.model:SetAttribute("State", "Home")
	egg.prompt.Enabled = true
end
function Game:drop(p, reason)
	local egg = self.carry[p]
	if not egg then
		return false
	end
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
		if slot and R.within(root.Position, slot.pad.Position, 3.25, 3.25, 9) then
			return element
		end
	end
	return nil
end

function Game:beginIncubation(p, item, element)
	local pro = self.profiles[p]
	local slot = pro and pro.base.incubators[element]
	if not pro or pro.duel then
		return false, "Finish the duel before incubating."
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
	item.state = "Incubating"
	item.element = element
	item.species = item.creature
	local model = Art.egg(item.rarity, self.world.dynamic, item.creature)
	model:PivotTo(CFrame.new(slot.pad.Position + Vector3.new(0, 2.5, 0)))
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
	if not pro or not egg or not self:alive(p) or pro.duel then
		return false, "No egg to secure."
	end
	local slot = pro.base.incubators[element]
	if not slot or not C.Elements[element] then
		return false, "Choose an elemental incubator at your camp."
	end
	if not R.within(self:root(p).Position, slot.pad.Position, 3.25, 3.25, 9) then
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
	self:unweld(egg)
	self.carry[p] = nil
	self.eggs[egg.id] = nil
	egg.nest.egg = nil
	egg.nest.respawn = self:now() + 8
	egg.model:Destroy()
	pro.tutorial = math.max(pro.tutorial, 4)
	self:notify(p, egg.creature .. " egg secured in the " .. element .. " incubator.", "pickup")
	self:push(p)
	return true
end

function Game:incubate(p, id, element)
	local pro = self.profiles[p]
	local item = self.inventory.items[id]
	if not pro or pro.duel then
		return false, "Finish the duel before incubating."
	end
	if type(id) ~= "string" or type(element) ~= "string" or not C.Elements[element] then
		return false, "Choose an egg and an elemental incubator."
	end
	local root = self:root(p)
	if not root or not R.within(root.Position, pro.base.center, 19, 22, 12) then
		return false, "Return to your camp to incubate an egg."
	end
	return self:beginIncubation(p, item, element)
end

function Game:setPetMode(p, id, mode)
	local pro = self.profiles[p]
	local item = self.inventory.items[id]
	if not pro or pro.duel then
		return false, "Finish the duel first."
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
		pro.penPages = math.max(1, math.ceil(penCount / C.MaxVisiblePets))
		pro.penCount = penCount
		pro.penPage = math.clamp(pro.penPage or 1, 1, pro.penPages)
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
					local page = math.floor((index - 1) / C.MaxVisiblePets) + 1
					local slot = (index - 1) % C.MaxVisiblePets
					displayed = page == pro.penPage
					position = pro.base.penCenter
						+ Vector3.new((slot % 4 - 1.5) * 6, 1.6, (math.floor(slot / 4) - 0.5) * 5)
				end
				record:SetAttribute("Displayed", displayed == true)
				record:SetAttribute("PenPosition", position)
				record.Parent = records
			end
		end
	end
end

function Game:setPenPage(p, page)
	local pro = self.profiles[p]
	if
		not pro
		or pro.duel
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
	if not pro or not egg or pro.duel or not self:alive(p) then
		return false, "Carry an egg home first."
	end
	if not R.within(self:root(p).Position, pro.base.center, 19, 22, 12) then
		return false, "Return to your own camp to store the egg."
	end
	local item, err = self.inventory:create(p.UserId, "Egg", egg.rarity, egg.creature)
	if not item then
		return false, err
	end
	self:unweld(egg)
	self.carry[p] = nil
	self.eggs[egg.id] = nil
	egg.nest.egg = nil
	egg.nest.respawn = self:now() + 8
	egg.model:Destroy()
	self:notify(p, "Egg stored. Open Collection to choose its element later.", "pickup")
	self:push(p)
	return true
end

function Game:bat(p)
	if not self:alive(p) or self.profiles[p].duel or not self:equipped(p, "Bat") then
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
function Game:buyUpgrade(p)
	local pro = self.profiles[p]
	local root = self:root(p)
	if not pro or pro.duel or not root then
		return false, "You cannot upgrade right now."
	end
	if (root.Position - pro.base.treadmill.Position).Magnitude > 20 then
		return false, "Return to your own training deck."
	end
	if pro.tier >= 2 then
		return false, "Bronze treadmill is already unlocked."
	end
	if pro.money.Value < C.UpgradeCost then
		return false, "You need 100 coins."
	end
	pro.money.Value -= C.UpgradeCost
	pro.tier = 2
	pro.tutorial = 6
	pro.base.treadmill:SetAttribute("Tier", 2)
	local label = pro.base.model:FindFirstChild("Console")
	if label and label:FindFirstChild("Label") then
		label.Label.Text.Text = "BRONZE TRAINER\n+2 Speed / second"
	end
	self:notify(p, "Bronze unlocked! Training now gives +2 Speed each second.", "win")
	self:push(p)
	return true
end
function Game:buyTrap(p)
	local pro = self.profiles[p]
	local root = self:root(p)
	if not pro or pro.duel or not root or (root.Position - self.world.shop.Position).Magnitude > 16 then
		return false, "Visit Trail Supplies in the Meadow."
	end
	if pro.charges >= 5 then
		return false, "You can carry five snare pods."
	end
	if pro.money.Value < C.TrapCost then
		return false, "You need 15 coins for a snare pod."
	end
	pro.money.Value -= C.TrapCost
	pro.charges += 1
	self:push(p)
	self:notify(p, "Snare pod purchased.", "pickup")
	return true
end
function Game:placeTrap(p)
	local pro = self.profiles[p]
	local root = self:root(p)
	if not self:alive(p) or pro.duel or not self:equipped(p, "SnarePod") then
		return false, "Equip a snare pod outside a duel."
	end
	if not self:rate(p, "trap", 1) then
		return false, "Cooldown"
	end
	if pro.charges <= 0 then
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
	pro.charges -= 1
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
	local snapshot = {
		build = C.Build,
		speed = pro.speed.Value,
		money = pro.money.Value,
		tier = pro.tier,
		charges = pro.charges,
		base = p:GetAttribute("BaseIndex"),
		training = pro.training,
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
function Game:action(p, name, data)
	if type(name) ~= "string" or #name > 32 or not self.profiles[p] then
		return false, "Invalid request."
	end
	if type(data) ~= "table" then
		data = {}
	end
	if not self:rate(p, "network", 0.035) then
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
		return self:buyUpgrade(p)
	elseif name == "buyTrap" then
		return self:buyTrap(p)
	elseif name == "incubate" then
		return self:incubate(p, data.id, data.element)
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
		if self.profiles[p].duel then
			return false, "Finish the duel first."
		end
		if not self:rate(p, "debugItems", 2) then
			return false, "Cooldown"
		end
		self.inventory:create(p.UserId, "Egg", "Common", "Skunk")
		self.inventory:create(p.UserId, "Egg", "Epic", "Dragon")
		self.inventory:create(p.UserId, "Pet", "Rare", "Gorilla", "Water")
		self:reconcilePets()
		self:push(p)
		return true
	end
	return false, "Unknown action."
end
function Game:setNight(enabled)
	workspace:SetAttribute("Night", enabled)
	self.phaseEnds = self:now() + (enabled and C.NightDuration or R.nextNight(self.rng))
	workspace:SetAttribute("PhaseEnds", self.phaseEnds)
	if enabled then
		local n = self.world.nests[5]
		if not n.egg then
			self:spawnEgg(n, self.rng:NextNumber() < 0.8 and "Legendary" or "Mythic")
		end
		self:effect("night", {})
		for p in pairs(self.profiles) do
			self:notify(p, "Moonrise! All incubators run at 30x. The Moon Shrine has awakened.", "night")
		end
	end
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
		if (egg.state == "Carried" and root and not self:safe(root.Position)) or egg.state == "Dropped" then
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
	self.duels:step(now)
	if now >= self.phaseEnds then
		self:setNight(not workspace:GetAttribute("Night"))
	end
	for p, pro in pairs(self.profiles) do
		local root = self:root(p)
		local alive = self:alive(p)
		pro.training = alive and not pro.duel and R.within(root.Position, pro.base.treadmill.Position, 5, 2.9, 5)
		if pro.training then
			pro.trainCarry += dt
			if pro.trainCarry >= C.TrainInterval then
				local n = math.floor(pro.trainCarry / C.TrainInterval)
				pro.trainCarry -= n * C.TrainInterval
				pro.speed.Value += n * pro.tier
				if pro.speed.Value >= 60 then
					pro.tutorial = math.max(pro.tutorial, 2)
				end
			end
		else
			pro.trainCarry = 0
		end
		pro.incomeCarry += dt
		if pro.incomeCarry >= C.PetIncomeInterval then
			local n = math.floor(pro.incomeCarry / C.PetIncomeInterval)
			pro.incomeCarry -= n * C.PetIncomeInterval
			pro.money.Value += self.inventory:income(p.UserId) * n
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
					self:effect("hatch", {
						position = slot.pad.Position + Vector3.new(0, 3, 0),
						rarity = item.rarity,
						element = element,
					})
					self:notify(
						p,
						item.species .. " hatched! +" .. C.Rarities[item.rarity].income .. " coins / 2s.",
						"win"
					)
					self:reconcilePets()
					self:push(p)
				end
			else
				slot.timer.Text = element:upper() .. " INCUBATOR\nAvailable"
			end
		end
		if self.carry[p] and alive then
			local element = self:nearIncubator(p)
			if element and not pro.incubations[element] then
				self:secure(p, element)
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
	for _, nest in ipairs(self.world.nests) do
		if not nest.egg and not nest.event and (not nest.respawn or now >= nest.respawn) then
			self:spawnEgg(nest, nest.rarity)
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
	self.world = World.build()
	self.navigation = Navigation.new(self.world.decor)
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
		if not nest.event then
			self:spawnEgg(nest, nest.rarity)
		end
	end
	for _, b in ipairs(self.world.bases) do
		self:prompt(b.treadmill, "Trainer options", "Your camp trainer", function(p)
			if b.owner == p then
				self:feed(p, "openShop", {})
			else
				self:notify(p, "Use the trainer at your own camp.")
			end
		end)
	end
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
		self.duels:leaving(p)
		if self.carry[p] then
			self:resetEgg(self.carry[p])
		end
		local pro = self.profiles[p]
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
