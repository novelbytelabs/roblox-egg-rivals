local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Stage3Shared")
local C = require(Shared.Config)
local R = require(Shared.Rules)
local U = require(script.Parent.UI)
local Effects = require(script.Parent.Effects)
local effects = Effects.new()
local net = ReplicatedStorage:WaitForChild("Stage3Net")
local request = net:WaitForChild("Request")
local stateEvent = net:WaitForChild("State")
local feed = net:WaitForChild("Feed")
local effectEvent = net:WaitForChild("Effect")
local records = net:WaitForChild("PetRecords")
local state = nil
local menu = nil
local selectedId = nil
local duelFingerprint = ""
local invFingerprint = ""
local render
local function send(name, data)
	request:FireServer(name, data or {})
end
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)
local gui = Instance.new("ScreenGui")
gui.Name = "MoonwoodUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 8
gui.Parent = player:WaitForChild("PlayerGui")
local root = Instance.new("Frame")
root.Name = "ResponsiveCanvas"
root.Size = UDim2.fromOffset(1080, 720)
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.5)
root.BackgroundTransparency = 1
root.Parent = gui
local scale = Instance.new("UIScale")
scale.Parent = root
local function resize()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local v = camera.ViewportSize
	scale.Scale = math.min(v.X / 1080, math.max(1, v.Y - 40) / 720)
end
local cameraConnection
local function bindCamera()
	if cameraConnection then
		cameraConnection:Disconnect()
	end
	if workspace.CurrentCamera then
		cameraConnection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
	end
	resize()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
bindCamera()
local brand = U.frame(root, "Brand", 16, 12, 258, 62, C.Colors.Ink)
U.text(brand, "Title", "EGG RIVALS", 14, 7, 230, 27, 24, C.Colors.Gold)
U.text(brand, "Subtitle", "MOONWOOD • FOREST SLICE", 14, 36, 232, 17, 11, C.Colors.Muted)
local phasePanel = U.frame(root, "Phase", 395, 12, 290, 62, C.Colors.Ink)
local phaseTitle = U.text(phasePanel, "Title", "DAYTIME", 12, 6, 266, 25, 19)
phaseTitle.TextXAlignment = Enum.TextXAlignment.Center
local phaseTime = U.text(phasePanel, "Timer", "", 12, 34, 266, 19, 12, C.Colors.Muted)
phaseTime.TextXAlignment = Enum.TextXAlignment.Center
local stats = U.frame(root, "Stats", 790, 12, 274, 62, C.Colors.Ink)
local speedText = U.text(stats, "Speed", "SPEED  0", 14, 7, 246, 24, 18, C.Colors.Mint)
local moneyText = U.text(stats, "Money", "COINS  0", 14, 34, 246, 21, 17, C.Colors.Gold)
local objective = U.frame(root, "Objective", 16, 515, 294, 125, C.Colors.Ink)
local objectiveTitle = U.text(objective, "Title", "01 / YOUR CAMP", 14, 10, 265, 24, 15, C.Colors.Gold)
local objectiveBody = U.text(objective, "Body", "Waiting for the server…", 14, 39, 265, 70, 15)
local mini = U.text(
	root,
	"SessionNotice",
	"Private vertical slice • session-only progress • " .. C.Build,
	17,
	695,
	900,
	18,
	11,
	C.Colors.Muted
)
local inventoryButton = U.button(root, "InventoryButton", "I   COLLECTION", 16, 653, 158, 35, function()
	menu = if menu == "inventory" then nil else "inventory"
	invFingerprint = ""
end)
local upgradeButton = U.button(root, "UpgradeButton", "U   TRAINER", 184, 653, 126, 35, function()
	menu = if menu == "shop" then nil else "shop"
end, C.Colors.Gold)
local helpButton = U.button(root, "HelpButton", "H   GUIDE", 320, 653, 105, 35, function()
	menu = if menu == "help" then nil else "help"
end, C.Colors.Blue)
local soundButton = U.button(root, "SoundButton", "SOUND ON", 935, 653, 129, 35, function()
	effects.muted = not effects.muted
end, C.Colors.Muted)
local carryText = U.text(root, "CarryIndicator", "", 338, 591, 404, 30, 17, C.Colors.Gold)
carryText.TextXAlignment = Enum.TextXAlignment.Center
local dropButton = U.button(root, "DropEggButton", "DROP EGG", 545, 632, 150, 36, function()
	send("drop")
end, C.Colors.Gold)
dropButton.Visible = false
local storeButton = U.button(root, "StoreEggButton", "STORE AT CAMP", 375, 632, 158, 36, function()
	send("store")
end, C.Colors.Mint)
storeButton.Visible = false
local toast = U.frame(root, "Toast", 295, 552, 490, 45, C.Colors.Panel)
toast.Visible = false
local toastText = U.text(toast, "Message", "", 12, 3, 466, 39, 16)
local toastToken = 0
local function notify(text, sound)
	toastToken += 1
	local token = toastToken
	toastText.Text = text
	toast.Visible = true
	if sound then
		effects:sound(sound)
	end
	task.delay(4, function()
		if token == toastToken then
			toast.Visible = false
		end
	end)
end
local debugPanel = U.frame(root, "StudioTools", 850, 500, 214, 138, C.Colors.Panel)
debugPanel.Visible = RunService:IsStudio()
U.text(debugPanel, "Title", "STUDIO TEST CONTROLS", 10, 4, 194, 19, 11, C.Colors.Muted)
local bossButton = U.button(debugPanel, "BossToggle", "BOSS: ON", 10, 29, 194, 29, function()
	send("debugBoss", { enabled = not workspace:GetAttribute("BossEnabled") })
end)
U.button(debugPanel, "NightToggle", "TOGGLE NIGHT", 10, 64, 194, 29, function()
	send("debugNight")
end, C.Colors.Blue)
U.button(debugPanel, "TestItems", "ADD TEST ITEMS", 10, 99, 194, 29, function()
	send("debugItems")
end, C.Colors.Gold)
local modal = U.frame(root, "CollectionPanel", 90, 87, 900, 490, C.Colors.Panel)
modal.Visible = false
U.text(modal, "Title", "YOUR COLLECTION", 18, 12, 500, 35, 24, C.Colors.Gold)
U.text(
	modal,
	"Description",
	"Select an egg and choose its element. Select a pet to make it active or send it to your pen.",
	18,
	51,
	830,
	31,
	14,
	C.Colors.Muted
)
U.button(modal, "Close", "X", 845, 13, 36, 31, function()
	menu = nil
end, C.Colors.Muted)
local grid = U.grid(modal, "Items", 16, 92, 870, 282)
local elementButtons = {}
local elementX = { 18, 230, 442, 654 }
for index, element in ipairs(C.ElementOrder) do
	local style = C.Elements[element]
	elementButtons[element] = U.button(
		modal,
		element .. "Incubate",
		element:upper(),
		elementX[index],
		394,
		194,
		34,
		function()
			if selectedId then
				send("incubate", { id = selectedId, element = element })
			else
				notify("Select an egg first.")
			end
		end,
		style.color
	)
end
local activePetButton = U.button(modal, "SetActivePet", "SET ACTIVE", 18, 394, 210, 34, function()
	if selectedId then
		send("petMode", { id = selectedId, mode = "Active" })
	end
end)
local penPetButton = U.button(modal, "SendPetToPen", "SEND TO PEN", 245, 394, 210, 34, function()
	if selectedId then
		send("petMode", { id = selectedId, mode = "Pen" })
	end
end, C.Colors.Gold)
local collectionCount = U.text(modal, "Count", "", 18, 440, 552, 30, 13, C.Colors.Muted)
local penPrevious = U.button(modal, "PenPrevious", "< PEN PAGE", 582, 439, 142, 32, function()
	if state and (state.penPage or 1) > 1 then
		send("penPage", { page = state.penPage - 1 })
	end
end, C.Colors.Muted)
local penNext = U.button(modal, "PenNext", "PEN PAGE >", 735, 439, 142, 32, function()
	if state and (state.penPage or 1) < (state.penPages or 1) then
		send("penPage", { page = state.penPage + 1 })
	end
end, C.Colors.Muted)
local shop = U.frame(root, "TrainerPanel", 285, 184, 510, 306, C.Colors.Panel)
shop.Visible = false
U.text(shop, "Title", "UPGRADE YOUR TRAINER", 20, 15, 445, 35, 23, C.Colors.Gold)
U.button(shop, "Close", "X", 459, 17, 30, 30, function()
	menu = nil
end, C.Colors.Muted)
local shopDescription = U.text(shop, "Description", "", 20, 65, 466, 138, 18)
local buyButton = U.button(shop, "BuyUpgrade", "UNLOCK BRONZE • 100 COINS", 20, 229, 470, 49, function()
	send("upgrade")
end)
local guide = U.frame(root, "GuidePanel", 210, 140, 660, 377, C.Colors.Panel)
guide.Visible = false
U.text(guide, "Title", "WELCOME TO MOONWOOD", 20, 15, 580, 33, 25, C.Colors.Gold)
U.button(guide, "Close", "X", 610, 17, 30, 30, function()
	menu = nil
end, C.Colors.Muted)
U.text(
	guide,
	"Instructions",
	"1. Find the camp with your name. Stand on its treadmill to train.\n2. Follow the lantern trail into the Forest. E takes an egg.\n3. Outrun the Warden and choose Fire, Water, Wind, or Earth at your camp.\n4. One pet can follow you; the rest live in your pen and all still earn coins.\n5. Outside the safe zone, bats knock eggs loose. Snares slow carriers.\n6. R challenges another player. Review BOTH offers before confirming.\n\nWASD: move • Space: jump • Mouse: look / aim • 1 / 2: equip tools\nI: collection • U: trainer • H: guide • Click: use equipped tool\n\nNo progress is saved between sessions in this vertical slice.",
	20,
	59,
	620,
	294,
	17
)
local duelPanel = U.frame(root, "DuelOfferPanel", 90, 80, 900, 500, C.Colors.Panel)
duelPanel.Visible = false
local duelTitle = U.text(duelPanel, "Title", "DUEL OFFER", 18, 11, 700, 35, 24, C.Colors.Gold)
local offerMine = U.text(duelPanel, "YourOffer", "", 18, 52, 422, 51, 15)
local offerTheirs = U.text(duelPanel, "TheirOffer", "", 460, 52, 422, 51, 15, C.Colors.Blue)
local duelGrid = U.grid(duelPanel, "EligibleItems", 16, 121, 870, 267)
local offerNote = U.text(duelPanel, "Review", "", 18, 391, 865, 42, 14, C.Colors.Muted)
local confirmButton = U.button(duelPanel, "ConfirmOffers", "CONFIRM BOTH OFFERS", 18, 445, 390, 36, function()
	if state and state.duel then
		send("confirm", { revision = state.duel.revision })
	end
end)
U.button(duelPanel, "CancelOffer", "CANCEL • NO LOSS", 435, 445, 447, 36, function()
	send("cancel")
end, C.Colors.Muted)
local invite = U.frame(root, "Invitation", 270, 214, 540, 260, C.Colors.Panel)
invite.Visible = false
local inviteTitle = U.text(invite, "Title", "", 20, 15, 500, 42, 24, C.Colors.Gold)
local inviteText = U.text(invite, "Text", "", 20, 69, 500, 100, 17)
U.button(invite, "Accept", "ACCEPT", 20, 191, 240, 44, function()
	send("reply", { accept = true })
end)
U.button(invite, "Decline", "DECLINE", 280, 191, 240, 44, function()
	send("reply", { accept = false })
end, C.Colors.Muted)
local pendingPanel = U.frame(root, "PendingInvitation", 321, 109, 438, 82, C.Colors.Panel)
pendingPanel.Visible = false
local pendingText = U.text(pendingPanel, "Waiting", "Waiting for opponent…", 12, 3, 414, 32, 16)
U.button(pendingPanel, "CancelRequest", "CANCEL REQUEST", 110, 42, 218, 30, function()
	send("cancel")
end, C.Colors.Muted)
local scorePanel = U.frame(root, "DuelScore", 300, 86, 480, 85, C.Colors.Ink)
scorePanel.Visible = false
local scoreText = U.text(scorePanel, "Score", "", 12, 7, 456, 36, 25)
scoreText.TextXAlignment = Enum.TextXAlignment.Center
local roundText = U.text(scorePanel, "Round", "", 12, 45, 456, 27, 15, C.Colors.Gold)
roundText.TextXAlignment = Enum.TextXAlignment.Center
local crossGui = Instance.new("ScreenGui")
crossGui.Name = "MoonwoodAim"
crossGui.IgnoreGuiInset = true
crossGui.ResetOnSpawn = false
crossGui.DisplayOrder = 9
crossGui.Parent = player.PlayerGui
local cross = U.text(crossGui, "Crosshair", "+", 0, 0, 40, 40, 30, C.Colors.Text)
cross.AnchorPoint = Vector2.new(0.5, 0.5)
cross.Position = UDim2.fromScale(0.5, 0.5)
cross.TextXAlignment = Enum.TextXAlignment.Center
cross.Visible = false
local health = U.text(root, "DuelHealth", "", 438, 610, 208, 30, 19, C.Colors.Mint)
health.TextXAlignment = Enum.TextXAlignment.Center
health.Visible = false
local forfeitPanel = U.frame(root, "ForfeitPanel", 805, 613, 259, 34, C.Colors.Ink)
forfeitPanel.Visible = false
local forfeitArmed = false
local forfeitButton = U.button(forfeitPanel, "Forfeit", "FORFEIT DUEL", 0, 0, 259, 34, function()
	if forfeitArmed then
		send("cancel", { forfeit = true })
		forfeitArmed = false
	else
		forfeitArmed = true
	end
end, C.Colors.Red)
local result = U.frame(root, "DuelResult", 300, 228, 480, 220, C.Colors.Panel)
result.Visible = false
local resultTitle = U.text(result, "Title", "", 20, 15, 440, 40, 30, C.Colors.Gold)
resultTitle.TextXAlignment = Enum.TextXAlignment.Center
local resultBody = U.text(result, "Body", "", 20, 62, 440, 100, 18)
resultBody.TextXAlignment = Enum.TextXAlignment.Center
local dismissedResult = nil
U.button(result, "Continue", "BACK TO THE GROVE", 75, 170, 330, 35, function()
	dismissedResult = state and state.result and state.result.untilTime
	result.Visible = false
end)
local damage = U.frame(root, "DamageFlash", 0, 0, 1080, 720, C.Colors.Red)
damage.BackgroundTransparency = 1
damage.ZIndex = 10
local function paintInventory()
	if not state then
		return
	end
	local parts = { selectedId or "" }
	for _, item in ipairs(state.items) do
		table.insert(parts, item.id .. item.state .. item.kind .. tostring(item.element) .. tostring(item.petMode))
	end
	local fp = table.concat(parts, "|")
	if fp == invFingerprint then
		return
	end
	invFingerprint = fp
	U.clearGrid(grid)
	for _, item in ipairs(state.items) do
		U.card(grid, item, function(clicked)
			selectedId = clicked.id
			invFingerprint = ""
			paintInventory()
			render()
		end, item.id == selectedId)
	end
	if #state.items == 0 then
		U.text(grid, "Empty", "No items yet. Bring an egg back from the Forest.", 5, 8, 800, 50, 20, C.Colors.Muted)
	end
end
local function offerText(prefix, item, ready)
	if not item then
		return prefix .. ": choose an item"
	end
	return prefix
		.. ": "
		.. (item.kind == "Pet" and item.species or item.rarity .. " " .. (item.creature or "Creature") .. " Egg")
		.. "\n"
		.. item.rarity
		.. " • "
		.. item.id:sub(1, 8)
		.. (ready and " • CONFIRMED" or "")
end
render = function()
	if not state then
		return
	end
	local d = state.duel
	local active = d and d.phase ~= "Requested" and d.phase ~= "Selecting"
	local selecting = d and d.phase == "Selecting"
	if d then
		menu = nil
	end
	modal.Visible = menu == "inventory"
	shop.Visible = menu == "shop"
	guide.Visible = menu == "help"
	inventoryButton.Visible = not d
	upgradeButton.Visible = not d
	helpButton.Visible = not active
	objective.Visible = not active
	debugPanel.Visible = RunService:IsStudio() and not active
	scorePanel.Visible = active == true
	cross.Visible = active == true
	health.Visible = active == true
	forfeitPanel.Visible = active == true
	forfeitButton.Text = forfeitArmed and "F • CONFIRM FORFEIT" or "F • FORFEIT DUEL"
	duelPanel.Visible = selecting == true
	invite.Visible = d ~= nil and d.phase == "Requested" and d.recipient
	pendingPanel.Visible = d ~= nil and d.phase == "Requested" and not d.recipient
	if state.carrying then
		carryText.Text = "CARRYING "
			.. state.carrying:upper()
			.. " "
			.. tostring(state.carryingCreature or "CREATURE"):upper()
			.. " EGG • choose an elemental incubator"
	else
		local activeInc
		for _, element in ipairs(C.ElementOrder) do
			local inc = state.incubators and state.incubators[element]
			if inc then
				activeInc = element:upper()
					.. " "
					.. tostring(inc.creature or "CREATURE"):upper()
					.. " • "
					.. R.clock(inc.remaining)
				break
			end
		end
		carryText.Text = activeInc and ("INCUBATING " .. activeInc) or ""
	end
	carryText.Visible = not active
	dropButton.Visible = state.carrying ~= nil and not d
	storeButton.Visible = dropButton.Visible
	speedText.Text = "SPEED  " .. state.speed .. (state.training and "   +" .. state.tier .. " / sec" or "")
	moneyText.Text = "COINS  " .. state.money .. "   (+" .. state.income .. " / 2s)"
	bossButton.Text = state.bossEnabled and "BOSS: ON" or "BOSS: OFF"
	bossButton.BackgroundColor3 = state.bossEnabled and C.Colors.Red or C.Colors.Mint
	collectionCount.Text = #state.items
		.. " / "
		.. C.MaxItems
		.. " items • "
		.. (state.penCount or 0)
		.. " penned • page "
		.. (state.penPage or 1)
		.. " / "
		.. (state.penPages or 1)
	local selectedItem
	for _, item in ipairs(state.items) do
		if item.id == selectedId then
			selectedItem = item
			break
		end
	end
	local eggSelected = selectedItem and selectedItem.kind == "Egg" and selectedItem.state == "Inventory"
	local petSelected = selectedItem and selectedItem.kind == "Pet" and selectedItem.state == "Inventory"
	for _, element in ipairs(C.ElementOrder) do
		elementButtons[element].Visible = eggSelected == true
	end
	activePetButton.Visible = petSelected == true
	penPetButton.Visible = petSelected == true
	shopDescription.Text = state.tier >= 2
			and "BRONZE TRAINER UNLOCKED\n\nYour treadmill grants +2 Speed each second. Your training stat is not reduced when carrying an egg.\n\nMore tiers arrive after the vertical slice."
		or "STARTER  →  BRONZE\n\nDouble your training: +1 → +2 Speed / second.\nCost: 100 coins. Purchase at your own camp.\n\nYour balance: "
			.. state.money
			.. " coins."
	buyButton.Text = state.tier >= 2 and "BRONZE OWNED" or "UNLOCK BRONZE • 100 COINS"
	local objectives = {
		{ "01 / TRAIN AT CAMP " .. state.base, "Find your named camp. Stand on the treadmill until Speed reaches 60." },
		{ "02 / TAKE A FOREST EGG", "Follow the lantern trail. The Common nest is easiest. Press E near an egg." },
		{
			"03 / CHOOSE AN ELEMENT",
			"Outrun the Warden, then carry the egg onto Fire, Water, Wind, or Earth at your camp.",
		},
		{
			"04 / BUILD YOUR PET PEN",
			"Your first pet follows automatically. Use I to send pets to the pen or make one active.",
		},
		{
			"05 / UPGRADE YOUR TRAINER",
			"Your pet earns coins automatically. At 100 coins, return to camp and press U.",
		},
		{ "THE GROVE IS YOURS", "Collect all four Forest pets, try a snare, or challenge another player with R." },
	}
	local objectiveData = objectives[math.clamp(state.tutorial, 1, 6)]
	objectiveTitle.Text = objectiveData[1]
	objectiveBody.Text = objectiveData[2]
	if modal.Visible then
		paintInventory()
	end
	if d then
		pendingText.Text = "Waiting for " .. d.opponent .. "…"
		inviteTitle.Text = d.opponent .. " CHALLENGES YOU"
		inviteText.Text = "First to five eliminations. You will review and choose items before the duel starts.\n"
			.. (d.studioStakes and "Studio-only item-transfer test. No Robux." or "Practice duel. No item transfers.")
		duelTitle.Text = "REVIEW YOUR DUEL WITH " .. d.opponent:upper()
		offerMine.Text = offerText("YOUR OFFER", d.mine, d.ready)
		offerTheirs.Text = offerText("THEIR OFFER", d.theirs, d.otherReady)
		offerNote.Text = d.studioStakes
				and "Winner receives these two selected items. Changing either offer clears BOTH confirmations. No other collection items are at risk."
			or "Practice mode: confirm to play. No items will move."
		confirmButton.Text = d.ready and "CONFIRMED • WAITING FOR OPPONENT" or "CONFIRM BOTH OFFERS"
		local fp = d.id .. ":" .. d.revision
		for _, item in ipairs(state.items) do
			fp ..= item.id .. item.state
		end
		if selecting and fp ~= duelFingerprint then
			duelFingerprint = fp
			U.clearGrid(duelGrid)
			for _, item in ipairs(state.items) do
				if item.state == "Inventory" then
					U.card(duelGrid, item, function(clicked)
						send("select", { id = clicked.id })
					end, d.mine and d.mine.id == item.id)
				end
			end
			if #state.items == 0 then
				U.text(
					duelGrid,
					"Empty",
					"Collect an egg or pet first, or use ADD TEST ITEMS in Studio before challenging.",
					0,
					15,
					840,
					80,
					18
				)
			end
		end
		scoreText.Text = "YOU  " .. d.score .. "  :  " .. d.otherScore .. "  " .. d.opponent
		roundText.Text = d.phase == "Countdown" and "GET READY"
			or (d.phase == "Active" and "FIRST TO 5 • 3 HITS TO ELIMINATE" or d.phase:upper())
	else
		duelFingerprint = ""
		forfeitArmed = false
	end
	result.Visible = state.result ~= nil and state.result.untilTime ~= dismissedResult and not d
	if result.Visible then
		resultTitle.Text = state.result.title
		resultBody.Text = state.result.score .. "\n" .. state.result.text
	end
end
stateEvent.OnClientEvent:Connect(function(data)
	state = data
	render()
end)
feed.OnClientEvent:Connect(function(kind, data)
	if kind == "toast" then
		notify(data.text, data.sound)
	elseif kind == "damage" then
		damage.BackgroundTransparency = 0.86
		TweenService:Create(damage, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
	elseif kind == "openShop" then
		menu = "shop"
		render()
	end
end)
effectEvent.OnClientEvent:Connect(function(kind, data)
	effects:effect(kind, data)
end)
-- Prompts never appear on your own avatar, on busy players, or during your own offer/duel.
local prompts = setmetatable({}, { __mode = "k" })
local function refreshPrompt(prompt)
	local targetId = prompt:GetAttribute("TargetUserId")
	local target = targetId and Players:GetPlayerByUserId(targetId)
	prompt.Enabled = target ~= nil
		and target ~= player
		and target:GetAttribute("Busy") ~= true
		and player:GetAttribute("Busy") ~= true
end
workspace.DescendantAdded:Connect(function(v)
	if v:IsA("ProximityPrompt") and v.Name == "DuelPrompt" then
		prompts[v] = true
	end
end)
for _, v in ipairs(workspace:GetDescendants()) do
	if v:IsA("ProximityPrompt") and v.Name == "DuelPrompt" then
		prompts[v] = true
	end
end
local boundTools = setmetatable({}, { __mode = "k" })
local swinging = setmetatable({}, { __mode = "k" })
local function bindTool(tool)
	if not tool:IsA("Tool") or boundTools[tool] then
		return
	end
	if tool.Name ~= "Bat" and tool.Name ~= "SnarePod" and tool.Name ~= "DuelBlaster" then
		return
	end
	boundTools[tool] = true
	tool.Activated:Connect(function()
		if menu or (state and state.duel and (state.duel.phase == "Selecting" or state.duel.phase == "Requested")) then
			return
		end
		if tool.Name == "Bat" then
			if swinging[tool] then
				return
			end
			swinging[tool] = true
			effects:sound("swing")
			local original = tool.Grip
			TweenService:Create(tool, TweenInfo.new(0.11), { Grip = original * CFrame.Angles(math.rad(-95), 0.4, 0) })
				:Play()
			send("bat")
			task.delay(0.14, function()
				if tool.Parent then
					TweenService:Create(tool, TweenInfo.new(0.14), { Grip = original }):Play()
				end
			end)
			task.delay(C.BatCooldown, function()
				swinging[tool] = nil
			end)
		elseif tool.Name == "SnarePod" then
			send("trap")
		elseif tool.Name == "DuelBlaster" and workspace.CurrentCamera then
			send("shoot", { direction = workspace.CurrentCamera.CFrame.LookVector })
			local original = tool.Grip
			TweenService:Create(tool, TweenInfo.new(0.055), { Grip = original * CFrame.new(0, 0, 0.2) }):Play()
			task.delay(0.06, function()
				if tool.Parent then
					TweenService:Create(tool, TweenInfo.new(0.1), { Grip = original }):Play()
				end
			end)
		end
	end)
end
local function watch(container)
	for _, v in ipairs(container:GetChildren()) do
		bindTool(v)
	end
	container.ChildAdded:Connect(bindTool)
end
local function watchCharacter(char)
	watch(char)
	task.defer(function()
		local backpack = player:WaitForChild("Backpack", 10)
		if backpack then
			watch(backpack)
		end
	end)
end
watch(player:WaitForChild("Backpack"))
player.CharacterAdded:Connect(watchCharacter)
if player.Character then
	watch(player.Character)
end
local function handleShortcut(keyCode)
	if keyCode == Enum.KeyCode.M then
		effects.muted = not effects.muted
		return
	end
	if state and state.duel then
		if keyCode == Enum.KeyCode.F and state.duel.phase ~= "Selecting" and state.duel.phase ~= "Requested" then
			if forfeitArmed then
				send("cancel", { forfeit = true })
				forfeitArmed = false
			else
				forfeitArmed = true
				task.delay(3, function()
					forfeitArmed = false
				end)
			end
			render()
		end
		return
	end
	if keyCode == Enum.KeyCode.I then
		menu = if menu == "inventory" then nil else "inventory"
		invFingerprint = ""
	elseif keyCode == Enum.KeyCode.U then
		menu = if menu == "shop" then nil else "shop"
	elseif keyCode == Enum.KeyCode.H then
		menu = if menu == "help" then nil else "help"
	end
	render()
end

-- Own these shortcuts before the default camera consumes I for zoom.
ContextActionService:BindActionAtPriority(
	"MoonwoodShortcuts",
	function(_, inputState, input)
		if UserInputService:GetFocusedTextBox() or GuiService.MenuIsOpen then
			return Enum.ContextActionResult.Pass
		end
		if input.KeyCode == Enum.KeyCode.F and not (state and state.duel) then
			return Enum.ContextActionResult.Pass
		end
		if inputState == Enum.UserInputState.Begin then
			handleShortcut(input.KeyCode)
		end
		return Enum.ContextActionResult.Sink
	end,
	false,
	Enum.ContextActionPriority.High.Value,
	Enum.KeyCode.I,
	Enum.KeyCode.U,
	Enum.KeyCode.H,
	Enum.KeyCode.M,
	Enum.KeyCode.F
)
local wasActive = false
local savedCameraMode = player.CameraMode
local savedMinZoom = player.CameraMinZoomDistance
local savedMaxZoom = player.CameraMaxZoomDistance
local savedDistance = 12
local promptElapsed = 0
RunService.RenderStepped:Connect(function(dt)
	local now = workspace:GetServerTimeNow()
	local isNight = workspace:GetAttribute("Night") == true
	phaseTitle.Text = isNight and "MOONRISE • HATCHING 30x" or "DAYTIME"
	phaseTitle.TextColor3 = isNight and C.Colors.Gold or C.Colors.Text
	phaseTime.Text = (isNight and "Ends in " or "Moonrise in ")
		.. R.clock((workspace:GetAttribute("PhaseEnds") or now) - now)
	local d = state and state.duel
	local active = d ~= nil and d.phase ~= "Selecting" and d.phase ~= "Requested"
	if active ~= wasActive then
		if active then
			savedCameraMode = player.CameraMode
			savedMinZoom = player.CameraMinZoomDistance
			savedMaxZoom = player.CameraMaxZoomDistance
			local camera = workspace.CurrentCamera
			savedDistance =
				math.clamp(camera and (camera.CFrame.Position - camera.Focus.Position).Magnitude or 12, 8, 24)
			player.CameraMode = Enum.CameraMode.LockFirstPerson
		else
			player.CameraMode = savedCameraMode
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			if savedCameraMode ~= Enum.CameraMode.LockFirstPerson then
				-- Returning to Classic alone leaves the camera at first-person zoom.
				player.CameraMaxZoomDistance = math.max(savedMaxZoom, savedDistance)
				player.CameraMinZoomDistance = savedDistance
				task.delay(0.2, function()
					if not player:GetAttribute("InDuel") then
						player.CameraMinZoomDistance = savedMinZoom
						player.CameraMaxZoomDistance = savedMaxZoom
					end
				end)
			end
		end
		wasActive = active
	end
	if d and d.phase == "Countdown" then
		roundText.Text = "GET READY • " .. math.max(0, math.ceil(d.deadline - now))
	end
	if active then
		local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		health.Text = "HEALTH  " .. (h and math.ceil(h.Health) or 0) .. " / 100"
		UserInputService.MouseIconEnabled = false
	else
		UserInputService.MouseIconEnabled = true
	end
	soundButton.Text = effects.muted and "SOUND OFF" or "SOUND ON"
	promptElapsed += dt
	if promptElapsed > 0.15 then
		promptElapsed = 0
		for prompt in pairs(prompts) do
			if prompt.Parent then
				refreshPrompt(prompt)
			else
				prompts[prompt] = nil
			end
		end
	end
	effects:update(dt, state, records)
	if state then
		modal.Visible = menu == "inventory" and not d
		shop.Visible = menu == "shop" and not d
		guide.Visible = menu == "help" and not active
		if modal.Visible then
			paintInventory()
		end
	end
end)
send("sync")
print("[STAGE3 CLIENT] " .. C.Build .. " HUD and Tool.Activated bindings ready.")

if RunService:IsStudio() and workspace:GetAttribute("Stage3AutoTest") == true then
	feed.OnClientEvent:Connect(function(kind, data)
		if kind ~= "clientProbe" then
			return
		end
		task.spawn(function()
			task.wait(0.4)
			local out = {
				token = data.token,
				build = C.Build,
				cameraMode = tostring(player.CameraMode),
				audioLoaded = effects.sample.IsLoaded,
			}
			local ok, err = xpcall(function()
				local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				local own = r and r:FindFirstChild("DuelPrompt")
				assert(own and not own.Enabled, "Own challenge prompt was visible")
				assert(root.AbsoluteSize.X > 0 and scale.Scale > 0, "HUD has no dimensions")
				local right = stats.AbsolutePosition.X + stats.AbsoluteSize.X
				assert(right <= workspace.CurrentCamera.ViewportSize.X + 2, "HUD exceeds viewport width")
				assert(not cross.Visible, "Crosshair stayed visible outside duel")
				assert(player.CameraMode == Enum.CameraMode.Classic, "Camera did not return to Classic")
				out.cameraDistance = (workspace.CurrentCamera.CFrame.Position - workspace.CurrentCamera.Focus.Position).Magnitude
				assert(out.cameraDistance > 3, "Camera remained stuck in first person")
				out.boundTools = 0
				for tool in pairs(boundTools) do
					if tool.Parent then
						out.boundTools += 1
					end
				end
				assert(out.boundTools >= 2, "Tool.Activated bindings missing")
				-- Exercise the real UI input path rather than calling its callbacks directly.
				local virtual = UserInputService:CreateVirtualInput()
				virtual:SendKey(true, Enum.KeyCode.I, false)
				task.wait(0.08)
				virtual:SendKey(false, Enum.KeyCode.I, false)
				task.wait(0.3)
				assert(modal.Visible, "I did not open collection")
				out.itemCards = 0
				for _, v in ipairs(grid:GetChildren()) do
					if v:IsA("TextButton") then
						out.itemCards += 1
					end
				end
				assert(out.itemCards == #state.items, "Inventory UI lost a record")
				virtual:SendKey(true, Enum.KeyCode.I, false)
				task.wait(0.08)
				virtual:SendKey(false, Enum.KeyCode.I, false)
				task.wait(0.2)
				assert(not modal.Visible, "I did not close collection")
			end, debug.traceback)
			out.passed = ok
			out.error = not ok and tostring(err) or nil
			net.ClientDiagnostics:FireServer(out)
		end)
	end)
end
