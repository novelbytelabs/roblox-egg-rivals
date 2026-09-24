local C = require(game:GetService("ReplicatedStorage").Stage3Shared.Config)

local Contracts = {}
Contracts.__index = Contracts

local CATALOG = {
	warm_up = {
		kind = "TRAINING",
		name = "WARM UP",
		objective = "Gain 100 permanent Speed through valid treadmill training.",
		target = 100,
		rewardCoins = 40,
	},
	field_retrieval = {
		kind = "FOREST",
		name = "FIELD RETRIEVAL",
		objective = "Secure one Forest egg into your collection or an elemental incubator.",
		target = 1,
		rewardCoins = 60,
	},
	new_arrival = {
		kind = "HATCHING",
		name = "NEW ARRIVAL",
		objective = "Complete one real hatch.",
		target = 1,
		rewardCoins = 75,
	},
	clean_run = {
		kind = "GROVE CIRCUIT",
		name = "CLEAN RUN",
		objective = "Complete one valid solo Training Trial.",
		target = 1,
		rewardCoins = 80,
	},
	night_retrieval = {
		kind = "MOONRISE",
		name = "NIGHT RETRIEVAL",
		objective = "Secure the hidden Night egg during its live contest.",
		target = 1,
		rewardCoins = 150,
	},
	finish_together = {
		kind = "SPRINT",
		name = "FINISH TOGETHER",
		objective = "Complete one valid normalized Sprint Challenge.",
		target = 1,
		rewardCoins = 100,
	},
}

local GROUPS = {
	{ "warm_up", "new_arrival" },
	{ "field_retrieval", "night_retrieval" },
	{ "clean_run", "finish_together" },
}

local function finite(value)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function copyContract(id, baseline)
	local spec = CATALOG[id]
	assert(spec, "Unknown contract catalog ID")
	return {
		id = id,
		kind = spec.kind,
		name = spec.name,
		objective = spec.objective,
		baseline = baseline or 0,
		progress = 0,
		target = spec.target,
		rewardCoins = spec.rewardCoins,
		completed = false,
		claimed = false,
	}
end

function Contracts.new(gameService)
	return setmetatable({ game = gameService, sessions = {} }, Contracts)
end

function Contracts:selectionFor(p)
	local offset = math.abs(p.UserId) % 2
	local out = {}
	for index, group in ipairs(GROUPS) do
		local choice = ((offset + index - 1) % #group) + 1
		table.insert(out, group[choice])
	end
	return out
end

function Contracts:setup(p, forcedIds)
	local pro = self.game.profiles[p]
	assert(pro, "Contract setup requires a profile")
	local ids = forcedIds or self:selectionFor(p)
	assert(type(ids) == "table" and #ids == C.ContractCount, "Contract selection must contain exactly three IDs")
	local session = { order = {}, byId = {} }
	for _, id in ipairs(ids) do
		assert(type(id) == "string" and CATALOG[id] and not session.byId[id], "Invalid or duplicate contract ID")
		local baseline = id == "warm_up" and pro.speed.Value or 0
		local contract = copyContract(id, baseline)
		session.byId[id] = contract
		table.insert(session.order, contract)
	end
	self.sessions[p] = session
	return session
end

function Contracts:remove(p)
	self.sessions[p] = nil
end

function Contracts:observe(p, event, data)
	local session = self.sessions[p]
	if not session or type(event) ~= "string" then
		return false
	end
	data = type(data) == "table" and data or {}
	local changed = false
	for _, contract in ipairs(session.order) do
		if not contract.completed then
			local before = contract.progress
			if contract.id == "warm_up" and event == "speed" and finite(data.value) then
				contract.progress = math.max(contract.progress, data.value - contract.baseline)
			elseif contract.id == "field_retrieval" and event == "forest_secure" then
				contract.progress += 1
			elseif contract.id == "new_arrival" and event == "hatch" then
				contract.progress += 1
			elseif contract.id == "clean_run" and event == "trial_finish" then
				contract.progress += 1
			elseif contract.id == "night_retrieval" and event == "night_secure" then
				contract.progress += 1
			elseif contract.id == "finish_together" and event == "sprint_finish" then
				contract.progress += 1
			end
			contract.progress = math.clamp(contract.progress, 0, contract.target)
			if contract.progress ~= before then
				changed = true
			end
			if contract.progress >= contract.target then
				contract.completed = true
				changed = true
				self.game:notify(
					p,
					contract.name .. " complete! Visit Ranger Station to claim " .. contract.rewardCoins .. " Coins.",
					"win"
				)
			end
		end
	end
	return changed
end

function Contracts:claim(p, id)
	if type(id) ~= "string" or #id > 64 then
		return false, "Invalid contract."
	end
	local session = self.sessions[p]
	local contract = session and session.byId[id]
	if not contract then
		return false, "That contract is stale or unavailable."
	end
	if contract.claimed then
		return false, "That contract reward was already claimed."
	end
	if not contract.completed then
		return false, "Complete the contract before claiming its reward."
	end
	local pro = self.game.profiles[p]
	if not pro or pro.money.Value > C.MaxCoins - contract.rewardCoins then
		return false, "Coin balance is too high to claim this reward."
	end
	pro.money.Value += contract.rewardCoins
	contract.claimed = true
	self.game:notify(p, contract.name .. " claimed • +" .. contract.rewardCoins .. " Coins.", "pickup")
	self.game:push(p)
	return true
end

function Contracts:snapshot(p)
	local session = self.sessions[p]
	local out = {}
	if not session then
		return out
	end
	for _, contract in ipairs(session.order) do
		table.insert(out, {
			id = contract.id,
			kind = contract.kind,
			name = contract.name,
			objective = contract.objective,
			progress = contract.progress,
			target = contract.target,
			rewardCoins = contract.rewardCoins,
			completed = contract.completed,
			claimed = contract.claimed,
		})
	end
	return out
end

Contracts.Catalog = CATALOG

return Contracts
