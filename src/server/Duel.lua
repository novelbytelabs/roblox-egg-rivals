local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Stage3Shared")
local C = require(Shared.Config)
local R = require(Shared.Rules)
local Duel = {}
Duel.__index = Duel
function Duel.new(game)
	return setmetatable({ game = game, current = nil, sequence = 0 }, Duel)
end
function Duel:other(s, p)
	return p == s.a and s.b or s.a
end
function Duel:request(a, b)
	local g = self.game
	if a == b or not g:alive(a) or not g:alive(b) then
		return false, "Choose another active player."
	end
	if self.current or g.profiles[a].duel or g.profiles[b].duel then
		return false, "The duel court is busy."
	end
	if g.carry[a] or g.carry[b] then
		return false, "Secure or drop carried eggs before a duel."
	end
	if (g:root(a).Position - g:root(b).Position).Magnitude > 12 then
		return false, "Move closer to that player."
	end
	self.sequence += 1
	local s = {
		id = "duel-" .. self.sequence,
		a = a,
		b = b,
		phase = "Requested",
		deadline = g:now() + C.RequestTime,
		offers = {},
		ready = {},
		revision = 0,
		scores = { [a] = 0, [b] = 0 },
		escrow = false,
		round = 0,
		shotAt = {},
		timeouts = 0,
	}
	self.current = s
	g.profiles[a].duel = s
	g.profiles[b].duel = s
	a:SetAttribute("Busy", true)
	b:SetAttribute("Busy", true)
	g:notify(a, "Challenge sent. Waiting for " .. b.DisplayName .. ".")
	g:pushAll()
	return true
end
function Duel:reply(p, accept)
	local s = self.current
	if not s or s.b ~= p or s.phase ~= "Requested" then
		return false, "Challenge is no longer active."
	end
	if accept ~= true then
		self:finish(nil, "Challenge declined.")
		return true
	end
	if self.game.carry[s.a] or self.game.carry[s.b] then
		self:finish(nil, "A player started carrying an egg.")
		return false, "Try again after securing the egg."
	end
	s.phase = "Selecting"
	s.deadline = self.game:now() + C.SelectionTime
	self.game:pushAll()
	return true
end
function Duel:select(p, id)
	local s = self.current
	if not s or (p ~= s.a and p ~= s.b) or s.phase ~= "Selecting" then
		return false, "No stake selection is active."
	end
	if not RunService:IsStudio() then
		return false, "Item-transfer duels are disabled outside Studio pending policy review."
	end
	if type(id) ~= "string" or #id > 64 or not R.eligible(self.game.inventory.items[id], p.UserId) then
		return false, "Choose an unlocked item that you own."
	end
	s.offers[p] = id
	s.revision += 1
	s.ready = {}
	self.game:pushAll()
	return true
end
function Duel:confirm(p, revision)
	local s = self.current
	local g = self.game
	if not s or (p ~= s.a and p ~= s.b) or s.phase ~= "Selecting" then
		return false, "No duel offer to confirm."
	end
	if revision ~= s.revision then
		return false, "The offer changed. Review both items again."
	end
	if RunService:IsStudio() then
		if
			not R.eligible(g.inventory.items[s.offers[s.a]], s.a.UserId)
			or not R.eligible(g.inventory.items[s.offers[s.b]], s.b.UserId)
		then
			return false, "Both players must select an available item."
		end
	end
	s.ready[p] = true
	if s.ready[s.a] and s.ready[s.b] then
		if not g:alive(s.a) or not g:alive(s.b) then
			self:finish(nil, "A player became unavailable.")
			return false, "Duel canceled safely."
		end
		if g.carry[s.a] or g.carry[s.b] then
			self:finish(nil, "Secure carried eggs first.")
			return false, "Duel canceled safely."
		end
		if RunService:IsStudio() then
			local ok, err = g.inventory:escrow(s.a.UserId, s.offers[s.a], s.b.UserId, s.offers[s.b], s.id)
			if not ok then
				s.ready = {}
				return false, err
			end
			s.escrow = true
			g:reconcilePets() -- Remove staked pets from view before teleporting.
		end
		s.started = g:now()
		for _, who in ipairs({ s.a, s.b }) do
			who:SetAttribute("InDuel", true)
			g:clearGear(who)
		end
		self:startRound()
	end
	g:pushAll()
	return true
end
function Duel:startRound()
	local s = self.current
	if not s then
		return
	end
	s.round += 1
	local token = s.round
	s.phase = "Respawning"
	s.deadline = self.game:now() + 15
	task.spawn(function()
		for _, p in ipairs({ s.a, s.b }) do
			if self.current ~= s or s.round ~= token or p.Parent ~= Players then
				return
			end
			if not self.game:alive(p) then
				local ok = pcall(function()
					p:LoadCharacterAsync()
				end)
				if not ok then
					self:finish(nil, "Respawn failed. Stakes returned.")
					return
				end
			end
			local root = p.Character and p.Character:WaitForChild("HumanoidRootPart", 8)
			local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
			if self.current ~= s or s.round ~= token then
				return
			end
			if not root or not hum then
				self:finish(nil, "Avatar not ready. Stakes returned.")
				return
			end
			hum.Health = hum.MaxHealth
			hum.WalkSpeed = 0
			local pos = p == s.a and self.game.world.arenaA or self.game.world.arenaB
			local goal = p == s.a and self.game.world.arenaB or self.game.world.arenaA
			self.game:teleport(p, CFrame.lookAt(pos, goal))
			self.game:giveGear(p, true)
		end
		if self.current == s and s.round == token then
			s.phase = "Countdown"
			s.deadline = self.game:now() + C.Countdown
			self.game:pushAll()
		end
	end)
end
function Duel:eliminate(victim)
	local s = self.current
	if not s or s.phase ~= "Active" or (victim ~= s.a and victim ~= s.b) then
		return
	end
	local winner = self:other(s, victim)
	s.scores[winner] += 1
	s.phase = "RoundEnd"
	s.deadline = self.game:now() + C.BetweenRounds
	self.game:notify(winner, "Elimination! " .. s.scores[winner] .. " / " .. C.DuelTarget, "win")
	self.game:notify(victim, "Tagged out. Next round incoming.", "hit")
	for _, p in ipairs({ s.a, s.b }) do
		local h = self.game:humanoid(p)
		if h then
			h.WalkSpeed = 0
		end
	end
	if s.scores[winner] >= C.DuelTarget then
		self:finish(winner, "First to five!")
	else
		self.game:pushAll()
	end
end
function Duel:shoot(p, direction)
	local s = self.current
	local g = self.game
	if not s or s.phase ~= "Active" or (p ~= s.a and p ~= s.b) then
		return false, "Wait for the round to start."
	end
	if not R.vector(direction) or direction.Magnitude < 0.5 or direction.Magnitude > 1.5 then
		return false, "Invalid aim."
	end
	if not g:alive(p) or not g:equipped(p, "DuelBlaster") then
		return false, "Equip the blaster."
	end
	local now = g:now()
	if s.shotAt[p] and now - s.shotAt[p] < C.ShotCooldown then
		return false, "Cooldown"
	end
	s.shotAt[p] = now
	local opponent = self:other(s, p)
	local head = p.Character:FindFirstChild("Head")
	if not head or not g:alive(opponent) then
		return false, "Opponent not ready."
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { p.Character, g.world.dynamic, g.world.fx }
	local result = workspace:Raycast(head.Position, direction.Unit * C.DuelRange, params)
	local finish = result and result.Position or head.Position + direction.Unit * C.DuelRange
	g:effect("shot", { from = head.Position, to = finish, userId = p.UserId })
	if result and result.Instance:IsDescendantOf(opponent.Character) then
		g:humanoid(opponent):TakeDamage(C.DuelDamage)
		g:notify(p, "Hit confirmed", "tick")
		g:feed(opponent, "damage", {})
	end
	return true
end
function Duel:cancel(p, forfeit)
	local s = self.current
	if not s or (p ~= s.a and p ~= s.b) then
		return false, "No active duel."
	end
	if s.phase == "Requested" or s.phase == "Selecting" then
		self:finish(nil, "Duel canceled. No items lost.")
		return true
	end
	if forfeit ~= true then
		return false, "Use Confirm Forfeit to leave an active duel."
	end
	self:finish(self:other(s, p), p.DisplayName .. " forfeited.")
	return true
end
function Duel:finish(winner, reason)
	local s = self.current
	if not s then
		return
	end
	self.current = nil -- Idempotence barrier before notifications, respawns, or transfers.
	local g = self.game
	if s.escrow then
		local ok, err = g.inventory:settle(s.id, { s.offers[s.a], s.offers[s.b] }, winner and winner.UserId or nil)
		if not ok then
			warn("[STAGE3] " .. err)
			reason = "Escrow error: test must stop for inspection."
		end
	end
	for _, p in ipairs({ s.a, s.b }) do
		local profile = g.profiles[p]
		if profile then
			profile.duel = nil
			profile.result = {
				title = winner and (winner == p and "VICTORY" or "DUEL COMPLETE") or "DUEL CANCELED",
				text = reason
					.. (
						s.escrow and (winner and " Selected items transferred to the winner." or " Items returned.")
						or " Practice duel: no item transfers."
					),
				score = tostring(s.scores[p]) .. " - " .. tostring(s.scores[self:other(s, p)]),
				untilTime = g:now() + 12,
			}
		end
		if p.Parent == Players then
			p:SetAttribute("InDuel", false)
			p:SetAttribute("Busy", false)
			g:clearGear(p)
			local hum = g:humanoid(p)
			if hum and hum.Health > 0 then
				g:teleport(p, profile.base.spawn)
				g:applySpeed(p)
				g:giveGear(p, false)
			else
				task.spawn(function()
					if p.Parent == Players then
						pcall(function()
							p:LoadCharacterAsync()
						end)
					end
				end)
			end
		end
	end
	g:reconcilePets()
	g:pushAll()
end
function Duel:leaving(p)
	local s = self.current
	if s and (p == s.a or p == s.b) then
		local active = s.escrow and s.phase ~= "Selecting"
		self:finish(active and self:other(s, p) or nil, p.DisplayName .. " left the session.")
	end
end
function Duel:step(now)
	local s = self.current
	if not s then
		return
	end
	if s.started and now - s.started > 600 then
		self:finish(nil, "Match timeout. Stakes returned.")
		return
	end
	if s.phase == "Active" then
		for _, p in ipairs({ s.a, s.b }) do
			local root = self.game:root(p)
			if root and not R.within(root.Position, self.game.world.arenaCenter, 43, 33, 35) then
				self:eliminate(p)
				return
			end
		end
	end
	if now < s.deadline then
		return
	end
	if s.phase == "Requested" or s.phase == "Selecting" then
		self:finish(nil, "Duel invitation or offer expired.")
	elseif s.phase == "Countdown" then
		s.phase = "Active"
		s.deadline = now + C.RoundTime
		for _, p in ipairs({ s.a, s.b }) do
			self.game:applySpeed(p)
			self.game:notify(p, "GO!", "tick")
		end
		self.game:pushAll()
	elseif s.phase == "RoundEnd" then
		self:startRound()
	elseif s.phase == "Active" then
		s.timeouts += 1
		if s.timeouts >= 2 then
			self:finish(nil, "Two rounds timed out. Stakes returned.")
		else
			self:startRound()
		end
	elseif s.phase == "Respawning" then
		self:finish(nil, "Respawn timeout. Stakes returned.")
	end
end
function Duel:snapshot(p)
	local s = self.current
	if not s or (p ~= s.a and p ~= s.b) then
		return nil
	end
	local other = self:other(s, p)
	local items = self.game.inventory.items
	local function offer(who)
		local item = items[s.offers[who]]
		return item
				and {
					id = item.id,
					kind = item.kind,
					rarity = item.rarity,
					creature = item.creature,
					element = item.element,
					species = item.species,
					petMode = item.petMode,
				}
			or nil
	end
	return {
		id = s.id,
		phase = s.phase,
		opponent = other.DisplayName,
		recipient = p == s.b,
		mine = offer(p),
		theirs = offer(other),
		ready = s.ready[p] == true,
		otherReady = s.ready[other] == true,
		revision = s.revision,
		score = s.scores[p],
		otherScore = s.scores[other],
		deadline = s.deadline,
		studioStakes = RunService:IsStudio(),
	}
end
return Duel
