local RunService = game:GetService("RunService")
local C = require(game:GetService("ReplicatedStorage").Stage3Shared.Config)

local Checks = {}

function Checks.run(g, check, a, b, results)
	assert(RunService:IsStudio() and workspace:GetAttribute("Stage3AutoTest") == true)

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

	local function reset(ids)
		g.contracts:setup(a, ids)
		return g.contracts:snapshot(a)
	end

	check("Ranger Station exposes exactly three varied server-owned session contracts", function()
		assert(g.world.rangerStation and g.world.rangerStation:IsDescendantOf(g.world.decor))
		assert(g.world.rangerStation:FindFirstChildOfClass("ProximityPrompt"), "Ranger Station has no physical prompt")
		local snapshot = g.contracts:snapshot(a)
		assert(#snapshot == C.ContractCount)
		local ids, kinds = {}, {}
		for _, contract in ipairs(snapshot) do
			assert(not ids[contract.id] and contract.target > 0 and contract.rewardCoins > 0)
			ids[contract.id] = true
			kinds[contract.kind] = true
		end
		local kindCount = 0
		for _ in pairs(kinds) do
			kindCount += 1
		end
		assert(kindCount == C.ContractCount, "Initial contract selection lost category variety")
	end)

	check("Warm Up progress comes from authoritative Speed Lab training and stays monotonic", function()
		reset({ "warm_up", "field_retrieval", "clean_run" })
		local pro = g.profiles[a]
		local savedSpeed, savedTier, savedTraining = pro.speed.Value, pro.tier, pro.training
		local savedLab = pro.lab
		pro.speed.Value = 0
		pro.tier = 1
		pro.training = true
		g.speedLab:setup(pro)
		g.contracts:setup(a, { "warm_up", "field_retrieval", "clean_run" })
		for _ = 1, 80 do
			g.speedLab:step(a, 1, g:now())
		end
		local c = g.contracts.sessions[a].byId.warm_up
		assert(c.completed and c.progress == c.target)
		local atTarget = c.progress
		g.contracts:observe(a, "speed", { value = 20 })
		assert(c.progress == atTarget, "Contract progress regressed")
		pro.speed.Value, pro.tier, pro.training, pro.lab = savedSpeed, savedTier, savedTraining, savedLab
		g.contracts:setup(a)
	end)

	check("Forest and Moonrise retrieval events remain distinct", function()
		reset({ "warm_up", "field_retrieval", "night_retrieval" })
		assert(g.contracts:observe(a, "forest_secure"))
		local session = g.contracts.sessions[a]
		assert(session.byId.field_retrieval.completed)
		assert(not session.byId.night_retrieval.completed)
		assert(g.contracts:observe(a, "night_secure"))
		assert(session.byId.night_retrieval.completed)
	end)

	check("Real stored Forest and hidden Night eggs advance only their matching retrieval contracts", function()
		reset({ "warm_up", "field_retrieval", "night_retrieval" })
		local oldBoss = workspace:GetAttribute("BossEnabled")
		local oldEnd = g.phaseEnds
		workspace:SetAttribute("BossEnabled", false)
		g:setNight(false)
		local session = g.contracts.sessions[a]
		local ordinary
		for _, nest in ipairs(g.world.nests) do
			if not nest.fixedRarity and nest.egg and nest.egg.state == "Home" then
				ordinary = nest.egg
				break
			end
		end
		assert(ordinary)
		g:teleport(a, CFrame.new(ordinary.nest.position + Vector3.new(0, 3, 0)))
		assert(g:take(a, ordinary.id))
		g:teleport(a, CFrame.new(g.profiles[a].base.center + Vector3.new(0, 3, 0)))
		assert(g:storeEgg(a))
		assert(session.byId.field_retrieval.completed and not session.byId.night_retrieval.completed)

		g:setNight(true)
		local nightEgg = g.nightEgg
		assert(nightEgg and nightEgg.nightEvent)
		g:teleport(a, CFrame.new(nightEgg.nest.position + Vector3.new(0, 3, 0)))
		assert(g:take(a, nightEgg.id))
		g:teleport(a, CFrame.new(g.profiles[a].base.center + Vector3.new(0, 3, 0)))
		assert(g:storeEgg(a))
		assert(session.byId.night_retrieval.completed)
		g:setNight(false)
		g.phaseEnds = oldEnd
		workspace:SetAttribute("BossEnabled", oldBoss)
	end)

	check("Hatch, solo Trial and Sprint contract kinds complete only on their authoritative events", function()
		reset({ "new_arrival", "clean_run", "finish_together" })
		local session = g.contracts.sessions[a]
		g.contracts:observe(a, "hatch")
		assert(session.byId.new_arrival.completed and not session.byId.clean_run.completed)
		g.contracts:observe(a, "trial_finish")
		assert(session.byId.clean_run.completed and not session.byId.finish_together.completed)
		g.contracts:observe(a, "sprint_finish")
		assert(session.byId.finish_together.completed)
		local progress = session.byId.finish_together.progress
		g.contracts:observe(a, "sprint_finish")
		assert(session.byId.finish_together.progress == progress, "Completed Sprint contract advanced twice")
	end)

	check("Early, unknown and duplicate Ranger claims cannot mint Coins", function()
		reset({ "warm_up", "field_retrieval", "clean_run" })
		local pro = g.profiles[a]
		local before = pro.money.Value
		assert(not g.contracts:claim(a, "field_retrieval"))
		assert(not g.contracts:claim(a, "not-a-contract"))
		assert(pro.money.Value == before)
		g.contracts:observe(a, "forest_secure")
		assert(g.contracts:claim(a, "field_retrieval"))
		local after = pro.money.Value
		assert(after == before + 60)
		assert(not g.contracts:claim(a, "field_retrieval"))
		assert(pro.money.Value == after)
	end)

	check("Coin ceiling failure preserves a completed Ranger reward for later claim", function()
		reset({ "new_arrival", "clean_run", "finish_together" })
		local pro = g.profiles[a]
		local saved = pro.money.Value
		g.contracts:observe(a, "hatch")
		pro.money.Value = C.MaxCoins
		assert(not g.contracts:claim(a, "new_arrival"))
		local c = g.contracts.sessions[a].byId.new_arrival
		assert(c.completed and not c.claimed and pro.money.Value == C.MaxCoins)
		pro.money.Value = saved
	end)

	check("Contract session cleanup removes stale state and rebuilds a fresh three-contract session", function()
		g.contracts:remove(a)
		assert(g.contracts.sessions[a] == nil and #g.contracts:snapshot(a) == 0)
		g.contracts:setup(a)
		assert(#g.contracts:snapshot(a) == C.ContractCount)
	end)

	check("Real client Ranger claim uses the rendered exact contract ID once", function()
		reset({ "warm_up", "field_retrieval", "clean_run" })
		g.contracts:observe(a, "forest_secure")
		local contract = g.contracts.sessions[a].byId.field_retrieval
		local before = g.profiles[a].money.Value
		g:feed(a, "openContracts", {})
		local token = "contract-claim-" .. tostring(g:now())
		g:feed(a, "completionInputProbe", {
			kind = "ContractClaim",
			token = token,
			contractId = contract.id,
			rewardCoins = contract.rewardCoins,
		})
		assert(
			waitFor(function()
				local diag = g.clientDiagnostics[a]
				return diag and diag.token == token
			end, 8),
			"Real client contract claim probe timed out"
		)
		local diag = g.clientDiagnostics[a]
		results.contractClientDiagnostics = diag
		assert(diag.passed, diag.error)
		assert(contract.claimed and g.profiles[a].money.Value >= before + contract.rewardCoins)
		local after = g.profiles[a].money.Value
		assert(not g.contracts:claim(a, contract.id))
		assert(g.profiles[a].money.Value == after)
	end)

	g.contracts:setup(a)
	g.contracts:setup(b)
end

return Checks
