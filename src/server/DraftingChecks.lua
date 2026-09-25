local C = require(game:GetService("ReplicatedStorage").Stage3Shared.Config)

local Checks = {}

function Checks.run(g, check, a, b, results)
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
		g:teleport(p, CFrame.new(pos))
		if not g.clientDiagnostics then
			task.wait(0.15)
			return
		end
		serial += 1
		local token = "drafting-fixture-" .. serial .. "-" .. tostring(g:now())
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
			"Drafting fixture position did not settle"
		)
	end

	local function settleAtHome()
		place(a, g.profiles[a].base.spawn.Position)
		place(b, g.profiles[b].base.spawn.Position)
		assert(
			waitFor(function()
				return not g.profiles[a].training and not g.profiles[b].training
			end, 3),
			"Drafting cleanup did not leave training"
		)
	end

	check("Social Drafting tuning is bounded and matches adjacent camp geometry", function()
		assert(C.DraftBonus == 0.10 and C.DraftBonus <= 0.15)
		assert(C.DraftRange > 42 and C.DraftRange < 84)
		local distance = (g.profiles[a].base.treadmill.Position - g.profiles[b].base.treadmill.Position).Magnitude
		assert(distance <= C.DraftRange, "Adjacent player labs are outside Social Drafting range")
	end)

	check("One trainer remains solo while two adjacent real trainers draft symmetrically", function()
		settleAtHome()
		place(a, g.profiles[a].base.treadmill.Position + Vector3.new(0, 3, 0))
		assert(
			waitFor(function()
				return g.profiles[a].training and not g.profiles[a].drafting and not g.profiles[b].training
			end, 3),
			"Solo training incorrectly activated drafting"
		)
		place(b, g.profiles[b].base.treadmill.Position + Vector3.new(0, 3, 0))
		assert(
			waitFor(function()
				return g.profiles[a].training
					and g.profiles[b].training
					and g.profiles[a].drafting
					and g.profiles[b].drafting
					and g.profiles[a].base.treadmill:GetAttribute("Drafting") == true
					and g.profiles[b].base.treadmill:GetAttribute("Drafting") == true
			end, 3),
			"Adjacent simultaneous trainers did not enter drafting"
		)
		local aLab = g.speedLab:snapshot(a)
		local bLab = g.speedLab:snapshot(b)
		assert(aLab.drafting and bLab.drafting and aLab.draftBonus == C.DraftBonus and bLab.draftBonus == C.DraftBonus)
		place(b, g.profiles[b].base.spawn.Position)
		assert(
			waitFor(function()
				return g.profiles[a].training and not g.profiles[a].drafting and not g.profiles[b].training
			end, 3),
			"Drafting did not end when the partner stopped training"
		)
		settleAtHome()
	end)

	check("Social Drafting is a non-stacking Speed-gain sidegrade with no tactical or economy authority", function()
		local pro = g.profiles[a]
		local money = pro.money.Value
		local income = g.inventory:income(a.UserId)
		local momentum = pro.lab.momentum
		local charge = pro.lab.charge
		local energy = pro.lab.energy
		pro.drafting = false
		assert(g.speedLab:trainingMultiplier(pro) == 1)
		pro.drafting = true
		assert(math.abs(g.speedLab:trainingMultiplier(pro) - 1.10) < 1e-9)
		assert(
			pro.money.Value == money
				and g.inventory:income(a.UserId) == income
				and pro.lab.momentum == momentum
				and pro.lab.charge == charge
				and pro.lab.energy == energy
		)
		pro.drafting = false
	end)

	settleAtHome()
	g:push(a)
	g:push(b)
end

return Checks
