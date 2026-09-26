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

local function nearBazaar(g, p)
	g:teleport(p, CFrame.new(g.world.elementalBazaar.Position + Vector3.new(0, 2, -6)))
end

local function inventorySignature(g, p)
	return HttpService:JSONEncode(g.inventory:snapshot(p.UserId))
end

local function themeParts(base)
	local model = base.model:FindFirstChild("BazaarTheme")
	local count = 0
	if model then
		for _, obj in ipairs(model:GetDescendants()) do
			if obj:IsA("BasePart") then
				count += 1
				assert(obj.Anchored and not obj.CanCollide and not obj.CanTouch and not obj.CanQuery)
			end
		end
	end
	return model, count
end

local function clientTheme(g, p, theme)
	local token = "elemental-bazaar-" .. tostring(g:now())
	g:feed(p, "openElementalBazaar", {})
	g:feed(p, "completionInputProbe", { token = token, kind = "ElementalBazaar", theme = theme })
	assert(
		waitFor(function()
			return g.clientDiagnostics[p] and g.clientDiagnostics[p].token == token
		end, 8),
		"Real client Elemental Bazaar probe timed out"
	)
	local data = g.clientDiagnostics[p]
	assert(data.passed, data.error)
	return data
end

function Checks.run(g, check, a, _b, results)
	local pro = assert(g.profiles[a])
	local savedTheme = pro.baseTheme
	local savedRoot = g:root(a) and g:root(a).CFrame
	local beforeInventory = inventorySignature(g, a)
	local beforeIncome = g.inventory:income(a.UserId)
	local beforeMoney, beforeRemainder, beforeSpeed = pro.money.Value, pro.coinRemainder, pro.speed.Value
	local beforeTier, beforeRanch = pro.tier, pro.ranchLevel
	local beforeCapacity = pro.ranchDisplayCapacity
	local beforeLayout = pro.base.ranchLayoutSerial

	check("Elemental Bazaar exposes Standard plus exactly four elemental cosmetic themes", function()
		assert(#C.BazaarThemeOrder == 5 and C.BazaarThemeOrder[1] == "Standard")
		local seen = {}
		for _, name in ipairs(C.BazaarThemeOrder) do
			local spec = assert(C.BazaarThemes[name])
			assert(not seen[name])
			seen[name] = true
			if name == "Standard" then
				assert(spec.element == nil)
			else
				assert(spec.element == name and C.Elements[name])
			end
		end
	end)

	check("Elemental Bazaar rejects remote and unknown theme changes without mutation", function()
		g:teleport(a, CFrame.new(0, 3, 8))
		local theme = pro.baseTheme
		assert(not g:setBaseTheme(a, "Fire"))
		assert(not g:setBaseTheme(a, "Unknown"))
		assert(pro.baseTheme == theme and pro.base.model:GetAttribute("BaseTheme") == theme)
	end)

	check("Bazaar themes replace instead of stacking and remain nonphysical", function()
		nearBazaar(g, a)
		for _, theme in ipairs({ "Fire", "Water", "Wind", "Earth" }) do
			assert(g:setBaseTheme(a, theme))
			assert(pro.baseTheme == theme and pro.base.model:GetAttribute("BaseTheme") == theme)
			local model, count = themeParts(pro.base)
			assert(model and model:GetAttribute("Theme") == theme)
			assert(model:GetAttribute("Element") == theme)
			assert(count >= 16 and count <= 20, "Bazaar presentation escaped its bounded part budget")
			local folders = 0
			for _, child in ipairs(pro.base.model:GetChildren()) do
				if child.Name == "BazaarTheme" then
					folders += 1
				end
			end
			assert(folders == 1)
		end
		assert(g:setBaseTheme(a, "Standard"))
		assert(themeParts(pro.base) == nil)
	end)

	check("Bazaar presentation preserves incubator, ranch, inventory and economy authority", function()
		nearBazaar(g, a)
		local money, remainder, speed = pro.money.Value, pro.coinRemainder, pro.speed.Value
		local signature, income = inventorySignature(g, a), g.inventory:income(a.UserId)
		local capacity, layout = pro.ranchDisplayCapacity, pro.base.ranchLayoutSerial
		assert(g:setBaseTheme(a, "Water"))
		for _, element in ipairs(C.ElementOrder) do
			local incubator = assert(pro.base.incubators[element])
			assert(incubator.model:GetAttribute("Element") == element)
			assert(incubator.pad:GetAttribute("Element") == element)
		end
		assert(pro.money.Value == money and pro.coinRemainder == remainder and pro.speed.Value == speed)
		assert(pro.tier == beforeTier and pro.ranchLevel == beforeRanch)
		assert(pro.ranchDisplayCapacity == capacity and pro.base.ranchLayoutSerial == layout)
		assert(inventorySignature(g, a) == signature and g.inventory:income(a.UserId) == income)
	end)

	check("Real client Elemental Bazaar selection reaches authoritative ranch presentation", function()
		nearBazaar(g, a)
		assert(g:setBaseTheme(a, "Standard"))
		g:push(a)
		local diagnostic = clientTheme(g, a, "Fire")
		assert(diagnostic.theme == "Fire" and pro.baseTheme == "Fire")
		local model = assert(pro.base.model:FindFirstChild("BazaarTheme"))
		assert(model:GetAttribute("Element") == "Fire")
		assert(inventorySignature(g, a) == beforeInventory)
		assert(g.inventory:income(a.UserId) == beforeIncome)
	end)

	results.bazaarDiagnostics = {
		themes = C.BazaarThemeOrder,
		freeCosmetics = true,
		realClientSelection = true,
	}
	pro.baseTheme = savedTheme or "Standard"
	pro.base.applyTheme(pro.baseTheme)
	pro.money.Value, pro.coinRemainder, pro.speed.Value = beforeMoney, beforeRemainder, beforeSpeed
	assert(pro.tier == beforeTier and pro.ranchLevel == beforeRanch)
	assert(pro.ranchDisplayCapacity == beforeCapacity and pro.base.ranchLayoutSerial == beforeLayout)
	assert(inventorySignature(g, a) == beforeInventory and g.inventory:income(a.UserId) == beforeIncome)
	if savedRoot and g:root(a) then
		g:teleport(a, savedRoot)
	end
	g:push(a)
end

return Checks
