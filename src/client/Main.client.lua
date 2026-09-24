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
local HoldController = require(script.Parent.HoldController)
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
local pendingRanchUpgrade = nil
local tradeTargets = {}
local tradeSelection = {}
local tradeHold = nil
local tradePressing = false
local tradeFingerprint = ""
local exchangeHold = nil
local exchangePressing = false
local exchangeSelectedId = nil
local exchangeFingerprint = ""
local incubationPreview = nil
local incubationViews = {}
local holder
local incubationSpec
local render
local function send(name, data)
	request:FireServer(name, data or {})
end
holder = HoldController.new(send)
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
U.text(brand, "Subtitle", "LIVING WORLD • 0.4.0", 14, 36, 232, 17, 11, C.Colors.Muted)
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
local lockButton = U.button(modal, "LockItem", "FAVORITE / LOCK", 640, 13, 190, 31, function()
	if selectedId and state then
		for _, item in ipairs(state.items) do
			if item.id == selectedId then
				send("itemLock", { id = item.id, locked = not item.locked })
				break
			end
		end
	end
end, C.Colors.Blue)
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
U.text(shop, "Title", "SPEED LAB", 20, 15, 445, 35, 23, C.Colors.Gold)
U.button(shop, "Close", "X", 459, 17, 30, 30, function()
	menu = nil
end, C.Colors.Muted)
local shopDescription = U.text(shop, "Description", "", 20, 65, 466, 138, 18)
local buyButton = U.button(shop, "BuyUpgrade", "UPGRADE SPEED LAB", 20, 229, 470, 49, function()
	if state and state.lab then
		send("upgrade", { tier = state.lab.grade + 1 })
	end
end)
local ranchPanel = U.frame(root, "RanchPanel", 300, 195, 480, 250, C.Colors.Panel)
ranchPanel.Visible = false
U.text(ranchPanel, "Title", "RANCH & PEN WORKS", 20, 15, 400, 35, 23, C.Colors.Mint)
U.button(ranchPanel, "Close", "X", 430, 17, 30, 30, function()
	menu = nil
end, C.Colors.Muted)
local ranchDescription = U.text(ranchPanel, "Description", "", 20, 65, 440, 95, 17)
local ranchBuy = U.button(ranchPanel, "BuildExpansion", "BUILD EXPANSION", 20, 180, 440, 45, function()
	if pendingRanchUpgrade then
		send("ranchExpand", { level = pendingRanchUpgrade.level })
	end
end, C.Colors.Mint)
local tradePanel = U.frame(root, "TradePanel", 90, 86, 900, 500, C.Colors.Panel)
tradePanel.Visible = false
local tradeTitle = U.text(tradePanel, "Title", "TRADING POST", 18, 12, 650, 34, 24, C.Colors.Gold)
U.button(tradePanel, "Close", "X", 846, 14, 36, 31, function()
	holder:cancel()
	if state and state.trade then
		send("tradeCancel")
	end
	menu = nil
end, C.Colors.Muted)
local tradeInfo = U.text(tradePanel, "Info", "", 18, 50, 860, 110, 12, C.Colors.Muted)
local tradeGrid = U.grid(tradePanel, "TradeItems", 16, 170, 870, 228)
local tradeConfirm = U.button(tradePanel, "TradeConfirm", "HOLD TO CONFIRM", 18, 435, 410, 42, function() end)
local tradeCancel = U.button(tradePanel, "TradeCancel", "CANCEL • ALL ITEMS RETURN", 450, 435, 432, 42, function()
	send("tradeCancel")
end, C.Colors.Muted)
local tradeAccept = U.button(tradePanel, "TradeAccept", "ACCEPT TRADE", 18, 435, 410, 42, function()
	send("tradeReply", { accept = true })
end)
local tradeDecline = U.button(tradePanel, "TradeDecline", "DECLINE", 450, 435, 432, 42, function()
	send("tradeReply", { accept = false })
end, C.Colors.Muted)

local exchangePanel = U.frame(root, "ExchangePanel", 120, 100, 840, 460, C.Colors.Panel)
exchangePanel.Visible = false
U.text(exchangePanel, "Title", "THE EXCHANGE", 18, 12, 650, 34, 24, C.Colors.Gold)
U.button(exchangePanel, "Close", "X", 785, 14, 36, 31, function()
	holder:cancel()
	send("exchangeCancel")
	menu = nil
end, C.Colors.Muted)
local exchangeInfo = U.text(
	exchangePanel,
	"Info",
	"Select an item. Exchange returns Coins immediately.",
	18,
	50,
	800,
	45,
	15,
	C.Colors.Muted
)
local exchangeGrid = U.grid(exchangePanel, "ExchangeItems", 16, 105, 808, 260)
local exchangeConfirm = U.button(
	exchangePanel,
	"ExchangeConfirm",
	"SELECT AN ITEM",
	18,
	390,
	804,
	42,
	function() end,
	C.Colors.Gold
)

local incubatorPanel = U.frame(root, "IncubationPreview", 245, 150, 590, 345, C.Colors.Panel)
incubatorPanel.Visible = false
local incubatorTitle = U.text(incubatorPanel, "Title", "CHOOSE YOUR ELEMENT", 20, 12, 520, 32, 22, C.Colors.Gold)
local incubatorInfo = U.text(incubatorPanel, "Result", "", 20, 55, 550, 50, 16)
local incubatorPreviewLeft = U.frame(incubatorPanel, "EggPreview", 55, 108, 170, 140, C.Colors.Ink)
local incubatorPreviewRight = U.frame(incubatorPanel, "PetPreview", 365, 108, 170, 140, C.Colors.Ink)
U.text(incubatorPanel, "Arrow", "BECOMES", 235, 155, 120, 35, 16, C.Colors.Muted)
local incubatorConfirm = U.button(
	incubatorPanel,
	"ConfirmIncubation",
	"HOLD E • 0.75s",
	20,
	275,
	360,
	45,
	function() end
)
U.button(incubatorPanel, "CancelIncubation", "CANCEL", 400, 275, 170, 45, function()
	holder:cancel()
	send("incubationCancel")
	incubationPreview = nil
	menu = nil
	effects:selectIncubator(nil)
	render()
end, C.Colors.Muted)
incubationSpec = holder:bind({
	kind = "incubator",
	button = incubatorConfirm,
	beginName = "incubationHold",
	completeName = "incubationConfirm",
	valid = function()
		return menu == "incubation" and incubationPreview ~= nil
	end,
	context = function()
		return incubationPreview and incubationPreview.id
	end,
	args = function()
		return incubationPreview and { id = incubationPreview.id }
	end,
	complete = function(d)
		return { id = d.previewId, token = d.token }
	end,
})
holder:bind({
	kind = "trade",
	button = tradeConfirm,
	beginName = "tradeHoldBegin",
	completeName = "tradeHoldComplete",
	valid = function()
		return menu == "trade" and state and state.trade and state.trade.phase == "Selecting" and not state.trade.ready
	end,
	context = function()
		local d = state and state.trade
		return d and d.id .. ":" .. d.revision .. ":" .. tostring(d.baseReady)
	end,
	args = function()
		return {}
	end,
	complete = function(d)
		return { token = d.token, stage = d.stage }
	end,
})
holder:bind({
	kind = "exchange",
	button = exchangeConfirm,
	beginName = "exchangeBegin",
	completeName = "exchangeComplete",
	valid = function()
		return menu == "exchange" and exchangeSelectedId ~= nil and not (state and (state.trade or state.duel))
	end,
	context = function()
		return exchangeSelectedId
	end,
	args = function()
		return { id = exchangeSelectedId }
	end,
	complete = function(d)
		return { token = d.token }
	end,
})
-- Native world prompts can process E before a ContextAction callback runs.
-- The visible preview owns E, but HoldController still enforces focus, text-box,
-- menu, nonce and context checks. Its InputEnded connection owns key release.
UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode ~= Enum.KeyCode.E or not incubationPreview or menu ~= "incubation" then
		return
	end
	local active = holder.active
	if active and active.kind == "incubator" and active.key == Enum.KeyCode.E then
		return -- Repeated key-down events cannot restart an existing hold.
	end
	holder:start(incubationSpec, input)
end)
ContextActionService:BindActionAtPriority("EggRivalsIncubationHold", function()
	if
		not incubationPreview
		or menu ~= "incubation"
		or UserInputService:GetFocusedTextBox()
		or GuiService.MenuIsOpen
	then
		return Enum.ContextActionResult.Pass
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.ContextActionPriority.High.Value + 10, Enum.KeyCode.E)
local labHUD = U.frame(root, "LabMeters", 16, 86, 270, 112, C.Colors.Ink)
local momentumHUD = U.text(labHUD, "Momentum", "", 12, 5, 246, 25, 13, C.Colors.Mint)
local energyHUD = U.text(labHUD, "CampPower", "", 12, 32, 246, 23, 13, C.Colors.Gold)
local overdriveHUD = U.button(labHUD, "Overdrive", "Q • CHARGE OVERDRIVE", 10, 65, 250, 35, function()
	send("overdrive")
end, C.Colors.Blue)
local trialHUD = U.frame(root, "TrialHUD", 325, 85, 430, 83, C.Colors.Ink)
trialHUD.Visible = false
local trialStatus = U.text(trialHUD, "Status", "", 12, 4, 406, 39, 15, C.Colors.Blue)
U.button(trialHUD, "CancelTrial", "CANCEL TRIAL", 12, 47, 406, 26, function()
	send("trialCancel")
end, C.Colors.Muted)

local guide = U.frame(root, "GuidePanel", 210, 140, 660, 377, C.Colors.Panel)
guide.Visible = false
U.text(guide, "Title", "WELCOME TO EGG RIVALS", 20, 15, 580, 33, 25, C.Colors.Gold)
U.button(guide, "Close", "X", 610, 17, 30, 30, function()
	menu = nil
end, C.Colors.Muted)
U.text(
	guide,
	"Instructions",
	"1. Train at your Speed Lab. Momentum improves training and charges Overdrive.\n2. Follow the lantern trail into the Forest and steal an egg.\n3. Escape the Warden. Choose Fire, Water, Wind, or Earth deliberately at your camp.\n4. One pet follows; the rest live in your ranch and all still earn Coins.\n5. At Night the daytime nests go dormant and one valuable egg is hidden.\n6. Upgrade your Speed Lab, expand your ranch, trade safely, and master the Grove Circuit.\n\nWASD: move • Space: jump • Q: Overdrive • I: collection • U: Speed Lab • H: guide\n1 / 2: equip tools • Click: use equipped tool\n\nProgress is session-only in this engineering slice.",
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
		table.insert(
			parts,
			item.id
				.. item.state
				.. item.kind
				.. tostring(item.element)
				.. tostring(item.petMode)
				.. tostring(item.revision)
		)
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
local function itemLabel(item)
	if item.kind == "Pet" then
		return item.rarity .. " " .. (item.species or ((item.element or "") .. " " .. (item.creature or "Pet")))
	elseif item.kind == "Egg" then
		return item.rarity .. " " .. (item.creature or "Creature") .. " Egg"
	end
	return item.itemType or item.kind
end

local function offerSummary(items)
	if not items or #items == 0 then
		return "nothing selected"
	end
	local out = {}
	for _, item in ipairs(items) do
		table.insert(out, itemLabel(item) .. " [" .. item.id .. "]")
	end
	return table.concat(out, ", ")
end

local function tradeIds()
	local ids = {}
	for id, selected in pairs(tradeSelection) do
		if selected then
			table.insert(ids, id)
		end
	end
	table.sort(ids)
	return ids
end

local function paintTrade()
	if not state or menu ~= "trade" then
		return
	end
	local d = state.trade
	local fp = (
		d
			and (d.id .. ":" .. d.revision .. ":" .. tostring(d.ready) .. ":" .. tostring(d.baseReady) .. ":" .. tostring(
				d.otherReady
			))
		or "targets"
	)
	for _, item in ipairs(state.items) do
		fp ..= item.id .. item.state .. tostring(item.revision) .. tostring(item.petMode)
	end
	for _, target in ipairs(tradeTargets) do
		fp ..= tostring(target.userId) .. tostring(target.unlocked)
	end
	if fp == tradeFingerprint then
		return
	end
	tradeFingerprint = fp
	U.clearGrid(tradeGrid)
	if d then
		tradeSelection = {}
		for _, item in ipairs(d.mine) do
			tradeSelection[item.id] = true
		end
	end
	tradeConfirm.Visible = false
	tradeCancel.Visible = false
	tradeAccept.Visible = false
	tradeDecline.Visible = false
	if not d then
		tradeTitle.Text = "TRADING POST"
		tradeInfo.Text = #tradeTargets == 0
				and "No nearby eligible players. Both players must stand at the Trading Post."
			or "Choose a nearby player. Trading unlocks after each player hatches three pets."
		for _, target in ipairs(tradeTargets) do
			local button = U.button(tradeGrid, "Target" .. target.userId, target.name, 0, 0, 158, 90, function()
				if target.unlocked then
					send("tradeRequest", { userId = target.userId })
				else
					notify(target.name .. " has not unlocked trading yet.")
				end
			end, target.unlocked and C.Colors.Mint or C.Colors.Muted)
			button.TextWrapped = true
		end
		return
	end
	tradeTitle.Text = "TRADE WITH " .. d.opponent:upper()
	if d.phase == "Requested" then
		tradeInfo.Text = d.recipient and (d.opponent .. " wants to trade. No item can move until both players confirm.")
			or ("Waiting for " .. d.opponent .. " to accept…")
		tradeAccept.Visible = d.recipient
		tradeDecline.Visible = d.recipient
		tradeCancel.Visible = not d.recipient
		return
	end
	tradeInfo.Text = "YOU: " .. offerSummary(d.mine) .. "\nTHEM: " .. offerSummary(d.theirs)
	tradeConfirm.Visible = true
	tradeCancel.Visible = true
	tradeConfirm.Text = d.ready and "CONFIRMED • WAITING"
		or (d.hasGodly and d.baseReady and "HOLD 5s • GODLY FINAL CONFIRM" or "HOLD 3s • CONFIRM EXACT OFFERS")
	for _, item in ipairs(state.items) do
		if (item.state == "Inventory" or item.state == "Trade") and not item.locked and item.petMode ~= "Active" then
			U.card(tradeGrid, item, function(clicked)
				tradeSelection[clicked.id] = not tradeSelection[clicked.id]
				local ids = tradeIds()
				if #ids <= C.MaxTradeItems then
					send("tradeOffer", { ids = ids, revision = state.trade.revision })
				else
					tradeSelection[clicked.id] = nil
					notify("A trade offer can contain at most " .. C.MaxTradeItems .. " items.")
				end
				tradeFingerprint = ""
			end, tradeSelection[item.id] == true)
		end
	end
end

local function paintExchange()
	if not state or menu ~= "exchange" then
		return
	end
	local fp = exchangeSelectedId or ""
	for _, item in ipairs(state.items) do
		fp ..= item.id .. item.state .. tostring(item.revision) .. tostring(item.petMode)
	end
	if fp == exchangeFingerprint then
		return
	end
	exchangeFingerprint = fp
	U.clearGrid(exchangeGrid)
	local selected
	for _, item in ipairs(state.items) do
		if item.id == exchangeSelectedId then
			selected = item
		end
		if item.state == "Inventory" and not item.locked and item.petMode ~= "Active" and (item.exchange or 0) > 0 then
			U.card(exchangeGrid, item, function(clicked)
				exchangeSelectedId = clicked.id
				exchangeFingerprint = ""
				paintExchange()
			end, item.id == exchangeSelectedId)
		end
	end
	if selected then
		exchangeInfo.Text = itemLabel(selected) .. " • Exchange value: " .. tostring(selected.exchange) .. " Coins"
		exchangeConfirm.Text = selected.rarity == "Godly" and "HOLD 5s • EXCHANGE GODLY"
			or "HOLD TO EXCHANGE • " .. selected.exchange .. " COINS"
	else
		exchangeInfo.Text = "Select an unlocked item. Active pets must return to the pen first."
		exchangeConfirm.Text = "SELECT AN ITEM"
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
	if incubationPreview then
		menu = "incubation"
	end
	local active = d and d.phase ~= "Requested" and d.phase ~= "Selecting"
	local selecting = d and d.phase == "Selecting"
	if d then
		menu = nil
	elseif state.trade then
		menu = "trade"
	end
	incubatorPanel.Visible = menu == "incubation" and incubationPreview ~= nil
	labHUD.Visible = not active
	trialHUD.Visible = state.trial and state.trial.active == true
	modal.Visible = menu == "inventory"
	shop.Visible = menu == "shop"
	ranchPanel.Visible = menu == "ranch"
	tradePanel.Visible = menu == "trade"
	exchangePanel.Visible = menu == "exchange"
	guide.Visible = menu == "help"
	if tradePanel.Visible then
		paintTrade()
	end
	if exchangePanel.Visible then
		paintExchange()
	end
	if ranchPanel.Visible and pendingRanchUpgrade then
		ranchDescription.Text = pendingRanchUpgrade.name
			.. "\n\nVisible capacity: "
			.. pendingRanchUpgrade.capacity
			.. " pets\nCost: "
			.. pendingRanchUpgrade.cost
			.. " Coins"
		ranchBuy.Text = "BUILD " .. pendingRanchUpgrade.name:upper() .. " • " .. pendingRanchUpgrade.cost .. " COINS"
	end
	inventoryButton.Visible = not d and not incubationPreview
	upgradeButton.Visible = not d and not incubationPreview
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
			.. " EGG • hold E at your chosen elemental incubator"
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
	local lab = state.lab
	local trainText = ""
	if lab then
		momentumHUD.Text = "MOMENTUM  " .. math.floor(lab.momentum * 100) .. "%  • " .. lab.gradeName
		energyHUD.Text = "CAMP POWER  " .. math.floor(lab.energy) .. "%"
		overdriveHUD.Text = lab.charge >= 100 and "Q • OVERDRIVE READY"
			or ("Q • OVERDRIVE " .. math.floor(lab.charge) .. "%")
		trainText = state.training
				and ("   +" .. tostring(lab.rate) .. "/s • " .. math.floor(lab.momentum * 100) .. "% MOMENTUM")
			or ("   " .. lab.gradeName)
	end
	speedText.Text = "SPEED  " .. state.speed .. trainText
	moneyText.Text = "COINS  " .. state.money .. "   (+" .. state.income .. " / min)"
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
	lockButton.Visible = selectedItem ~= nil and selectedItem.state == "Inventory"
	lockButton.Text = selectedItem and selectedItem.locked and "UNLOCK FAVORITE" or "FAVORITE / LOCK"
	if state.lab then
		local grade = C.Grades[state.lab.grade]
		local nextGrade = C.Grades[state.lab.grade + 1]
		shopDescription.Text = grade.name:upper()
			.. " SPEED LAB\n\nTraining rate: +"
			.. tostring(grade.rate)
			.. " Speed/sec\nSpeed ceiling: "
			.. tostring(grade.cap)
			.. "\nMomentum: "
			.. tostring(math.floor(state.lab.momentum * 100))
			.. "% • Overdrive: "
			.. tostring(math.floor(state.lab.charge))
			.. "%"
		if nextGrade then
			shopDescription.Text ..= "\n\nNEXT: " .. nextGrade.name:upper() .. " • " .. nextGrade.cost .. " Coins"
			buyButton.Text = "INSTALL " .. nextGrade.name:upper() .. " • " .. nextGrade.cost .. " COINS"
			buyButton.Active = true
		else
			shopDescription.Text ..= "\n\nAPEX INSTALLED • launch-era maximum"
			buyButton.Text = "APEX OWNED"
			buyButton.Active = false
		end
	end
	local objectives = {
		{ "01 / TRAIN AT CAMP " .. state.base, "Find your named camp. Stand on the treadmill until Speed reaches 60." },
		{
			"02 / TAKE A FOREST EGG",
			"Follow the lantern trail. Common eggs are easiest to escape with. Press E to take an egg.",
		},
		{
			"03 / CHOOSE AN ELEMENT",
			"Escape home. Press E to review an elemental incubator, then hold E to confirm your choice.",
		},
		{
			"04 / BUILD YOUR PET PEN",
			"Your first pet follows automatically. Use I to send pets to the pen or make one active.",
		},
		{
			"05 / UPGRADE YOUR TRAINER",
			"Pets earn Coins automatically. At 150 Coins, visit your Speed Lab or Trainer Workshop.",
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
	elseif kind == "ranchUpgrade" then
		pendingRanchUpgrade = data
		menu = "ranch"
		render()
	elseif kind == "openTrade" then
		holder:cancel()
		tradeFingerprint = ""
		tradeTargets = data.targets or {}
		tradeSelection = {}
		tradeHold = nil
		menu = "trade"
		render()
	elseif kind == "tradeHold" then
		holder:ack("trade", data)
	elseif kind == "openExchange" then
		holder:cancel()
		exchangeFingerprint = ""
		exchangeSelectedId = nil
		exchangeHold = nil
		menu = "exchange"
		render()
	elseif kind == "exchangeHold" then
		holder:ack("exchange", data)
	elseif kind == "incubatorHold" then
		holder:ack("incubator", data)
	elseif kind == "incubatorPreview" then
		holder:cancel()
		incubationPreview = data
		menu = "incubation"
		for _, view in ipairs(incubationViews) do
			view:Destroy()
		end
		incubationViews = {}
		table.insert(
			incubationViews,
			U.preview(
				incubatorPreviewLeft,
				{ kind = "Egg", creature = data.creature, rarity = data.rarity },
				0,
				0,
				170,
				140
			)
		)
		table.insert(
			incubationViews,
			U.preview(
				incubatorPreviewRight,
				{ kind = "Pet", creature = data.creature, rarity = data.rarity, element = data.element },
				0,
				0,
				170,
				140
			)
		)
		incubatorTitle.Text = data.element:upper() .. " INCUBATOR"
		incubatorTitle.TextColor3 = C.Elements[data.element].color
		incubatorInfo.Text = data.rarity
			.. " "
			.. data.creature
			.. " Egg → "
			.. data.element
			.. " "
			.. data.creature
			.. "\nHatch time: "
			.. R.clock(data.hatch)
			.. " • same rarity"
		incubatorConfirm.Text = "HOLD E OR THIS BUTTON • 0.75s"
		effects:selectIncubator(data.element, state and state.base)
		render()
	elseif kind == "incubatorClosed" then
		holder:cancel()
		incubationPreview = nil
		if menu == "incubation" then
			menu = nil
		end
		effects:selectIncubator(nil)
		render()
	elseif kind == "selectIncubatorEgg" then
		notify("Select an egg, then choose " .. data.element .. " while standing at this incubator.")
		menu = "inventory"
		invFingerprint = ""
		render()
	elseif kind == "trialGhost" then
		effects:setGhost(data.frames, data.started)
	elseif kind == "trialEnded" then
		effects:clearGhost()
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
	local ownCharacter = player.Character
	local isOwn = ownCharacter ~= nil and prompt:IsDescendantOf(ownCharacter)
	prompt.Enabled = not isOwn
		and target ~= nil
		and target ~= player
		and target:GetAttribute("Busy") ~= true
		and player:GetAttribute("Busy") ~= true
end
local function trackPrompt(v)
	if v:IsA("ProximityPrompt") and v.Name == "DuelPrompt" then
		prompts[v] = true
		refreshPrompt(v)
		v:GetAttributeChangedSignal("TargetUserId"):Connect(function()
			if v.Parent then
				refreshPrompt(v)
			end
		end)
	end
end
workspace.DescendantAdded:Connect(trackPrompt)
for _, v in ipairs(workspace:GetDescendants()) do
	trackPrompt(v)
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
	elseif keyCode == Enum.KeyCode.Q and not (state and state.duel) then
		send("overdrive")
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
	if incubationPreview and (keyCode == Enum.KeyCode.I or keyCode == Enum.KeyCode.U or keyCode == Enum.KeyCode.H) then
		holder:cancel()
		send("incubationCancel")
		incubationPreview = nil
		effects:selectIncubator(nil)
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
	Enum.KeyCode.Q,
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
	holder:step()
	if state and state.trial and state.trial.active then
		trialStatus.Text = string.format(
			"GROVE CIRCUIT • %.2fs\nGate %d / %d",
			now - state.trial.started,
			state.trial.nextGate,
			state.trial.total
		)
	end
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
		incubatorPanel.Visible = menu == "incubation" and incubationPreview ~= nil and not d
		modal.Visible = menu == "inventory" and not d
		shop.Visible = menu == "shop" and not d
		ranchPanel.Visible = menu == "ranch" and not d
		tradePanel.Visible = menu == "trade" and not d
		exchangePanel.Visible = menu == "exchange" and not d
		guide.Visible = menu == "help" and not active
		if modal.Visible then
			paintInventory()
		elseif tradePanel.Visible then
			paintTrade()
		elseif exchangePanel.Visible then
			paintExchange()
		end
	end
end)
effects.onPetSelected = function(id, ownerId)
	local record = records:FindFirstChild(id)
	if not record then
		return
	end
	if ownerId == player.UserId and not (state and (state.duel or state.trade)) then
		selectedId = id
		menu = "inventory"
		invFingerprint = ""
		render()
	else
		notify(
			tostring(record:GetAttribute("Species"))
				.. " • "
				.. tostring(record:GetAttribute("Rarity"))
				.. " • "
				.. tostring(record:GetAttribute("Income"))
				.. " Coins/min"
		)
	end
end
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

-- Real input and presentation probes, only reachable in the explicit Studio TEST bundle.
if RunService:IsStudio() and workspace:GetAttribute("Stage3AutoTest") == true then
	feed.OnClientEvent:Connect(function(kind, data)
		if kind ~= "completionInputProbe" then
			return
		end
		task.spawn(function()
			local out = { token = data.token, build = C.Build, kind = data.kind }
			local virtual = data.kind ~= "Position" and UserInputService:CreateVirtualInput() or nil
			local function waitFor(fn, seconds)
				local untilTime = os.clock() + seconds
				repeat
					if fn() then
						return true
					end
					task.wait(0.03)
				until os.clock() > untilTime
				return false
			end
			local function point(button)
				local inset = GuiService:GetGuiInset()
				return button.AbsolutePosition + button.AbsoluteSize / 2 + inset
			end
			local function mouse(button, duration)
				-- A newly created grid card exists before its layout and input callback settle.
				RunService.RenderStepped:Wait()
				RunService.RenderStepped:Wait()
				local pos = point(button)
				virtual:SendMousePosition(pos)
				virtual:SendMouseButton(pos, Enum.UserInputType.MouseButton1, true, 0)
				task.wait(duration)
				virtual:SendMouseButton(pos, Enum.UserInputType.MouseButton1, false, 0)
			end
			local cleanup
			local ok, err = xpcall(function()
				if
					data.kind == "NightEdges"
					or data.kind == "Flashlight"
					or data.kind == "LongTrails"
					or data.kind == "NightDawn"
				then
					require(script.Parent.NightClientChecks).run(effects, virtual, out, data.kind)
				elseif data.kind == "Position" then
					-- Observe the normal replicated teleport. Do not move the character,
					-- change network ownership, or inject input to make the fixture pass.
					assert(typeof(data.target) == "Vector3")
					local began, stableSince = os.clock(), nil
					local settled = waitFor(function()
						local char = player.Character
						local actor = char and char:FindFirstChild("HumanoidRootPart")
						local offset = actor and actor.Position - data.target
						if actor then
							out.position = { actor.Position.X, actor.Position.Y, actor.Position.Z }
						end
						if offset and Vector2.new(offset.X, offset.Z).Magnitude <= 3 and math.abs(offset.Y) <= 6 then
							stableSince = stableSince or os.clock()
						else
							stableSince = nil
						end
						return stableSince and os.clock() - stableSince >= 0.15
					end, 4)
					out.elapsed = os.clock() - began
					assert(settled, "Client did not observe the requested fixture position")
				elseif data.kind == "Hold" then
					local button
					if data.holdKind == "incubator" then
						assert(
							waitFor(function()
								return incubatorPanel.Visible
									and incubationPreview
									and incubationPreview.itemId == data.itemId
							end, 3),
							"Exact incubation preview is not visible"
						)
						button = incubatorConfirm
					elseif data.holdKind == "trade" then
						assert(
							waitFor(function()
								return tradePanel.Visible
									and state.trade
									and state.trade.id == data.sessionId
									and state.trade.phase == "Selecting"
									and not state.trade.ready
							end, 3),
							"Exact trade session is not visible"
						)
						assert(tradeInfo.Text:find(data.itemId, 1, true), "Exact offered item is absent")
						button = tradeConfirm
					elseif data.holdKind == "exchange" then
						assert(
							waitFor(function()
								return exchangePanel.Visible and exchangeGrid:FindFirstChild("Item_" .. data.itemId)
							end, 3),
							"Exact exchange item card is not visible"
						)
						mouse(exchangeGrid:FindFirstChild("Item_" .. data.itemId), 0.08)
						assert(
							waitFor(function()
								return exchangeSelectedId == data.itemId
							end, 2),
							"Exchange card did not select its item"
						)
						out.selectedItemId = exchangeSelectedId
						button = exchangeConfirm
					else
						error("Unknown hold probe")
					end
					RunService.RenderStepped:Wait()
					local pos = point(button)
					local completed = holder.completed
					cleanup = function()
						virtual:SendMouseButton(pos, Enum.UserInputType.MouseButton1, false, 0)
					end
					virtual:SendMousePosition(pos)
					virtual:SendMouseButton(pos, Enum.UserInputType.MouseButton1, true, 0)
					assert(
						waitFor(function()
							return holder.active and holder.active.receipt
						end, 2),
						"Mouse input did not receive a matching hold acknowledgement"
					)
					local receipt = holder.active.receipt
					assert(receipt.duration == data.duration, "Hold duration changed")
					out.nonce, out.holdToken = receipt.nonce, receipt.token
					out.holdKind, out.duration, out.started = data.holdKind, receipt.duration, receipt.started
					assert(
						waitFor(function()
							return holder.completed > completed
						end, data.duration + 3),
						"Actual held input did not complete"
					)
					cleanup()
					cleanup = nil
					assert(holder.completed == completed + 1, "Actual hold sent more than one completion")
					assert(
						workspace:GetServerTimeNow() - receipt.started >= data.duration,
						"Client completed too early"
					)
					assert(
						waitFor(function()
							if data.holdKind == "incubator" then
								return incubationPreview == nil
							end
							if data.holdKind == "trade" then
								local trade = state and state.trade
								return not trade
									or (receipt.stage == "Base" and trade.hasGodly and trade.baseReady)
									or trade.ready
							end
							for _, item in ipairs(state.items) do
								if item.id == data.itemId then
									return false
								end
							end
							return true
						end, 3),
						"Server did not acknowledge the completed operation"
					)
					out.completed = holder.completed - completed
				elseif data.kind == "Incubator" then
					assert(
						waitFor(function()
							return incubatorPanel.Visible and incubationPreview ~= nil
						end, 3),
						"Incubator preview not rendered"
					)
					assert(
						incubatorInfo.Text:find("Dragon") and incubatorInfo.Text:find("Rare"),
						"Preview omitted exact creature or rarity"
					)
					local function inputSnapshot()
						return {
							focused = holder.focused,
							menu = menu,
							preview = incubationPreview and incubationPreview.id,
							active = holder.active ~= nil,
							canceled = holder.canceled,
							completed = holder.completed,
							keyDown = UserInputService:IsKeyDown(Enum.KeyCode.E),
							textFocused = UserInputService:GetFocusedTextBox() ~= nil,
							menuOpen = GuiService.MenuIsOpen,
						}
					end
					out.earlyBefore = inputSnapshot()
					out.inputEvents = {}
					local connections = {}
					for _, entry in ipairs({
						{ "Begin", UserInputService.InputBegan },
						{ "End", UserInputService.InputEnded },
					}) do
						table.insert(
							connections,
							entry[2]:Connect(function(input, processed)
								if input.KeyCode == Enum.KeyCode.E then
									table.insert(
										out.inputEvents,
										{ event = entry[1], processed = processed, time = os.clock() }
									)
								end
							end)
						)
					end
					cleanup = function()
						virtual:SendKey(false, Enum.KeyCode.E, false)
						for _, connection in ipairs(connections) do
							connection:Disconnect()
						end
					end
					local canceled = holder.canceled
					virtual:SendKey(true, Enum.KeyCode.E, false)
					task.wait(0.15)
					out.earlyDown = inputSnapshot()
					virtual:SendKey(false, Enum.KeyCode.E, false)
					task.wait(0.25)
					out.earlyAfter = inputSnapshot()
					assert(
						incubationPreview ~= nil and holder.active == nil and holder.canceled > canceled,
						"Early release was not canceled"
					)
					local completed = holder.completed
					virtual:SendKey(true, Enum.KeyCode.E, false)
					assert(
						waitFor(function()
							return incubationPreview == nil
						end, 3),
						"Held E did not complete incubation"
					)
					virtual:SendKey(false, Enum.KeyCode.E, false)
					assert(holder.completed == completed + 1, "Hold controller did not complete exactly once")
					out.canceled = holder.canceled - canceled
					out.completed = holder.completed - completed
				elseif data.kind == "Trade" then
					assert(
						waitFor(function()
							return tradePanel.Visible and state.trade and state.trade.phase == "Selecting"
						end, 3),
						"Trade UI missing"
					)
					assert(tradeInfo.Text:find(data.itemId, 1, true), "Offer display omits exact item identity")
					local card = tradeGrid:FindFirstChild("Item_" .. data.itemId)
					assert(card, "Trade card missing")
					local revision = state.trade.revision
					mouse(card, 0.1)
					assert(
						waitFor(function()
							return state.trade and state.trade.revision > revision
						end, 2),
						"Card removal did not submit a revisioned offer"
					)
					card = tradeGrid:FindFirstChild("Item_" .. data.itemId)
					assert(card)
					revision = state.trade.revision
					mouse(card, 0.1)
					assert(
						waitFor(function()
							return state.trade and state.trade.revision > revision
						end, 2),
						"Card add did not submit a revisioned offer"
					)
					mouse(tradeConfirm, 3.3)
					assert(
						waitFor(function()
							return state.trade and state.trade.ready
						end, 2),
						"Real mouse hold failed to confirm exact trade"
					)
					out.revision = state.trade.revision
					out.ready = state.trade.ready
				elseif data.kind == "Trial" then
					local PathfindingService = game:GetService("PathfindingService")
					local char = player.Character
					local humanoid = char and char:FindFirstChildOfClass("Humanoid")
					local actor = char and char:FindFirstChild("HumanoidRootPart")
					assert(actor and humanoid and waitFor(function()
						return state and state.trial and state.trial.active
					end, 3))
					local steering = Vector3.zero
					local bindName = "EggRivalsTrialRegressionInput"
					RunService:BindToRenderStep(bindName, Enum.RenderPriority.Last.Value, function()
						humanoid:Move(steering, false)
					end)
					cleanup = function()
						RunService:UnbindFromRenderStep(bindName)
						humanoid:Move(Vector3.zero, false)
					end
					local deadline = os.clock() + 90
					for index, target in ipairs(data.gates) do
						local path = PathfindingService:CreatePath({
							AgentRadius = 2,
							AgentHeight = 6,
							AgentCanJump = true,
							WaypointSpacing = 5,
						})
						path:ComputeAsync(actor.Position, target)
						local waypoints = path.Status == Enum.PathStatus.Success and path:GetWaypoints()
							or { { Position = target } }
						for _, waypoint in ipairs(waypoints) do
							repeat
								local delta = waypoint.Position - actor.Position
								delta = Vector3.new(delta.X, 0, delta.Z)
								if delta.Magnitude < 2.8 then
									break
								end
								assert(
									os.clock() < deadline and state.trial and state.trial.active,
									"Trial navigation timed out or run was invalidated"
								)
								steering = delta.Unit
								if waypoint.Action == Enum.PathWaypointAction.Jump then
									humanoid.Jump = true
								end
								task.wait(0.02)
							until false
						end
						steering = Vector3.zero
						assert(
							waitFor(function()
								return not state.trial.active or state.trial.nextGate > index
							end, 2),
							"Gate " .. index .. " was not registered by server"
						)
					end
					assert(
						waitFor(function()
							return state.trial and not state.trial.active and state.trial.best ~= nil
						end, 3),
						"Valid physical run did not save personal best"
					)
					out.best = state.trial.best
				elseif data.kind == "Particles" then
					assert(
						waitFor(function()
							return workspace:GetAttribute("Night") == true
						end, 3),
						"Night state was not replicated"
					)
					local MotionParticles = require(script.Parent.MotionParticles)
					local group = Instance.new("Folder")
					group.Name = "ParticleRegression"
					group.Parent = workspace
					local pool = MotionParticles.new(group)
					cleanup = function()
						for _, part in ipairs(pool.free) do
							part:Destroy()
						end
						group:Destroy()
					end
					pool:setBudget(16)
					local actor = Instance.new("Part")
					actor.Anchored = true
					actor.CanCollide = false
					actor.CanQuery = false
					actor.Size = Vector3.new(2, 2, 2)
					actor.Position = Vector3.new(0, 3, 40)
					actor.Parent = group
					local now = workspace:GetServerTimeNow()
					local color = C.Elements.Water.night
					pool:observe(
						"landing",
						actor,
						color,
						actor.Position + Vector3.new(0, 0.5, 0),
						Vector3.new(0, -24, 0),
						false,
						now,
						0.1,
						18,
						false,
						4.4
					)
					assert(#pool.particles > 0, "No genuine trail particles created")
					local before = {}
					for _, p in ipairs(pool.particles) do
						before[p.part] = true
					end
					pool:observe(
						"landing",
						actor,
						color,
						actor.Position,
						Vector3.zero,
						true,
						now + 0.03,
						0.03,
						18,
						false,
						4.4
					)
					assert(pool.stats.impacts == 1, "Real landing ray did not classify contact")
					pool:update(0.05, now + 0.24)
					for _, p in ipairs(pool.particles) do
						assert(
							before[p.part] and p.mode == "Fragment",
							"Impact replaced trail material instead of reusing it"
						)
					end
					pool:observe(
						"cancel",
						actor,
						color,
						actor.Position + Vector3.new(0, 0.5, 0),
						Vector3.new(0, -24, 0),
						false,
						now + 0.3,
						0.1,
						18,
						false,
						4.4
					)
					pool:observe(
						"cancel",
						actor,
						color,
						actor.Position,
						Vector3.zero,
						true,
						now + 0.33,
						0.03,
						18,
						false,
						4.4
					)
					pool:observe(
						"cancel",
						actor,
						color,
						actor.Position + Vector3.new(0.1, 0, 0),
						Vector3.new(4, 0, 0),
						true,
						now + 0.36,
						0.03,
						18,
						false,
						4.4
					)
					assert(pool.stats.canceled > 0, "Resumed motion did not cancel pending explosion")
					for i = 1, 500 do
						pool:trail("budget" .. i, actor.Position, color, now + 0.4, 40)
					end
					assert(#pool.particles <= 16 and pool.allocated <= 16)
					for _, p in ipairs(pool.particles) do
						assert(
							p.part.Anchored and not p.part.CanCollide and not p.part.CanTouch and not p.part.CanQuery
						)
					end
					out.particles = pool:snapshot()
				else
					error("Unknown completion input probe")
				end
			end, debug.traceback)
			pcall(function()
				if virtual then
					virtual:SendKey(false, Enum.KeyCode.E, false)
				end
			end)
			if cleanup then
				cleanup()
			end
			out.passed = ok
			out.error = not ok and tostring(err) or nil
			net.ClientDiagnostics:FireServer(out)
		end)
	end)
end
