local RunService = game:GetService("RunService")
local C = require(game:GetService("ReplicatedStorage").Stage3Shared.Config)
local R = require(game:GetService("ReplicatedStorage").Stage3Shared.Rules)

local Checks = {}

function Checks.run(g, check, a, b, results)
	assert(RunService:IsStudio() and workspace:GetAttribute("Stage3AutoTest"))

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

	local serial = 0
	local function place(p, pos)
		serial += 1
		local token = "sprint-fixture-" .. serial .. "-" .. tostring(g:now())
		g:teleport(p, CFrame.new(pos))
		g:feed(p, "completionInputProbe", { token = token, kind = "Position", target = pos })
		assert(
			waitFor(function()
				local diag = g.clientDiagnostics[p]
				local root = g:root(p)
				return diag
					and diag.token == token
					and diag.passed
					and root
					and Vector2.new(root.Position.X - pos.X, root.Position.Z - pos.Z).Magnitude <= 3
			end, 5),
			"Sprint fixture position did not settle"
		)
	end

	local function stage()
		local center = g.world.trialStart.Position
		place(a, center + Vector3.new(-2, 3, -5))
		place(b, center + Vector3.new(2, 3, -5))
	end

	local function inventorySignature(p)
		local rows = {}
		for _, item in ipairs(g.inventory:list(p.UserId)) do
			table.insert(rows, R.itemSignature(item))
		end
		table.sort(rows)
		return table.concat(rows, "\\n")
	end

	check("Sprint challenge requires an exact nearby eligible opponent and declines safely", function()
		stage()
		local coinsA, coinsB = g.profiles[a].money.Value, g.profiles[b].money.Value
		local countA, countB = #g.inventory:list(a.UserId), #g.inventory:list(b.UserId)
		assert(not g.sprints:request(a, a))
		assert(g.sprints:request(a, b))
		local sa, sb = g.sprints:snapshot(a), g.sprints:snapshot(b)
		assert(sa and sb and sa.id == sb.id and sa.phase == "Requested")
		assert(not sa.recipient and sb.recipient)
		assert(not g.sprints:request(a, b), "Duplicate Sprint request bypassed busy state")
		assert(g.sprints:reply(b, false))
		assert(g.profiles[a].sprint == nil and g.profiles[b].sprint == nil)
		assert(g.profiles[a].money.Value == coinsA and g.profiles[b].money.Value == coinsB)
		assert(#g.inventory:list(a.UserId) == countA and #g.inventory:list(b.UserId) == countB)
	end)

	check(
		"Sprint countdown locks movement then applies equal normalized movement without spending Overdrive",
		function()
			stage()
			local recordsA, recordsB = g.profiles[a].lab.records, g.profiles[b].lab.records
			local enteredA, enteredB = recordsA.sprintEntered or 0, recordsB.sprintEntered or 0
			assert(g.sprints:request(a, b))
			assert(g.sprints:reply(b, true))
			assert(waitFor(function()
				return g.profiles[a].sprint and g.profiles[a].sprint.phase == "Countdown"
			end, 2))
			assert(g:humanoid(a).WalkSpeed == 0 and g:humanoid(b).WalkSpeed == 0)
			assert(waitFor(function()
				return g.profiles[a].sprint and g.profiles[a].sprint.phase == "Active"
			end, C.SprintCountdown + 2))
			assert(g:humanoid(a).WalkSpeed == C.TrialSpeed and g:humanoid(b).WalkSpeed == C.TrialSpeed)
			assert((recordsA.sprintEntered or 0) == enteredA + 1 and (recordsB.sprintEntered or 0) == enteredB + 1)
			local charge = g.profiles[a].lab.charge
			g.profiles[a].lab.charge = 100
			local ok = g.speedLab:activate(a)
			assert(not ok and g.profiles[a].lab.charge == 100, "Sprint consumed or allowed Overdrive")
			g.profiles[a].lab.charge = charge
			assert(g.sprints:cancel(a))
			assert(g.profiles[a].sprint == nil and g.profiles[b].sprint == nil)
			assert(g:humanoid(a).WalkSpeed ~= C.TrialSpeed and g:humanoid(b).WalkSpeed ~= C.TrialSpeed)
		end
	)

	check("Sprint teleport discontinuity produces DNF and deterministic cleanup", function()
		stage()
		local wins = g.profiles[b].lab.records.sprintWins or 0
		assert(g.sprints:request(a, b))
		assert(g.sprints:reply(b, true))
		assert(waitFor(function()
			return g.profiles[a].sprint and g.profiles[a].sprint.phase == "Active"
		end, C.SprintCountdown + 3))
		g:teleport(a, CFrame.new(g.world.trialStart.Position + Vector3.new(45, 3, 0)))
		assert(waitFor(function()
			return g.profiles[a].sprint == nil and g.profiles[b].sprint == nil
		end, 2))
		assert((g.profiles[a].lab.records.sprintDNFs or 0) > 0)
		assert((g.profiles[b].lab.records.sprintWins or 0) == wins + 1)
		assert(not a:GetAttribute("InSprint") and not b:GetAttribute("InSprint"))
	end)

	check("Real two-client Sprint movement completes one normalized race with no economy mutation", function()
		stage()
		local proA, proB = g.profiles[a], g.profiles[b]
		local inventoryA, inventoryB = inventorySignature(a), inventorySignature(b)
		local incomeA, incomeB = g.inventory:income(a.UserId), g.inventory:income(b.UserId)
		local wealthA = proA.money.Value + proA.coinRemainder
		local wealthB = proB.money.Value + proB.coinRemainder
		assert(
			proA.money.Value < C.MaxCoins and proB.money.Value < C.MaxCoins,
			"Sprint economy fixture hit Coin ceiling"
		)
		local expectedPassiveA, expectedPassiveB = 0, 0
		local economyConnection = RunService.Heartbeat:Connect(function(dt)
			expectedPassiveA += incomeA * dt / 60
			expectedPassiveB += incomeB * dt / 60
		end)
		local enteredA = proA.lab.records.sprintEntered or 0
		local enteredB = proB.lab.records.sprintEntered or 0
		local winsA = proA.lab.records.sprintWins or 0
		local winsB = proB.lab.records.sprintWins or 0
		local raceOK, raceErr = xpcall(function()
			assert(g.sprints:request(a, b))
			local inviteToken = "sprint-invite-" .. tostring(g:now())
			g:feed(b, "completionInputProbe", { token = inviteToken, kind = "SprintInvite" })
			assert(
				waitFor(function()
					local diag = g.clientDiagnostics[b]
					return diag and diag.token == inviteToken
				end, 5),
				"Real Sprint invitation input did not return"
			)
			assert(g.clientDiagnostics[b].passed, g.clientDiagnostics[b].error)
			assert(
				waitFor(function()
					return proA.sprint and proA.sprint.phase == "Active"
				end, C.SprintCountdown + 5),
				"Sprint did not reach Active after real acceptance"
			)
			local tokenA = "sprint-run-a-" .. tostring(g:now())
			local tokenB = "sprint-run-b-" .. tostring(g:now())
			g:feed(a, "completionInputProbe", { token = tokenA, kind = "Sprint", gates = g.world.trialGates })
			g:feed(b, "completionInputProbe", { token = tokenB, kind = "Sprint", gates = g.world.trialGates })
			assert(
				waitFor(function()
					local da, db = g.clientDiagnostics[a], g.clientDiagnostics[b]
					return da and db and da.token == tokenA and db.token == tokenB
				end, 45),
				"Real Sprint client movement diagnostics did not finish"
			)
			local da, db = g.clientDiagnostics[a], g.clientDiagnostics[b]
			results.sprintDiagnostics = { da, db }
			assert(da.passed, da.error)
			assert(db.passed, db.error)
			assert(
				waitFor(function()
					return proA.sprint == nil and proB.sprint == nil
				end, C.SprintFinishGrace + 3),
				"Sprint session did not clean up"
			)
			assert((proA.lab.records.sprintEntered or 0) == enteredA + 1)
			assert((proB.lab.records.sprintEntered or 0) == enteredB + 1)
			assert((proA.lab.records.sprintWins or 0) + (proB.lab.records.sprintWins or 0) == winsA + winsB + 1)
			assert(type(proA.lab.records.bestSprint) == "number")
			assert(type(proB.lab.records.bestSprint) == "number")
		end, debug.traceback)
		economyConnection:Disconnect()
		if not raceOK then
			local session = proA.sprint or proB.sprint
			if session then
				g.sprints:complete(session, nil, "Fixture cleanup after failed real-client Sprint probe.")
			end
		end
		assert(raceOK, raceErr)
		local actualPassiveA = proA.money.Value + proA.coinRemainder - wealthA
		local actualPassiveB = proB.money.Value + proB.coinRemainder - wealthB
		assert(
			math.abs(actualPassiveA - expectedPassiveA) < 0.01,
			"Sprint changed player A Coins beyond passive income"
		)
		assert(
			math.abs(actualPassiveB - expectedPassiveB) < 0.01,
			"Sprint changed player B Coins beyond passive income"
		)
		assert(g.inventory:income(a.UserId) == incomeA and g.inventory:income(b.UserId) == incomeB)
		assert(inventorySignature(a) == inventoryA and inventorySignature(b) == inventoryB)
	end)
end

return Checks
