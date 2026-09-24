local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local C = require(game:GetService("ReplicatedStorage").Stage3Shared.Config)

local Sprint = {}
Sprint.__index = Sprint

local GROUP = "EggRivalsSprint"

local function recordDefaults(records)
	records.sprintEntered = records.sprintEntered or 0
	records.sprintWins = records.sprintWins or 0
	records.sprintDNFs = records.sprintDNFs or 0
	records.sprintStreak = records.sprintStreak or 0
	records.bestSprintStreak = records.bestSprintStreak or 0
	return records
end

function Sprint.new(gameService)
	pcall(function()
		PhysicsService:RegisterCollisionGroup(GROUP)
	end)
	PhysicsService:CollisionGroupSetCollidable(GROUP, GROUP, false)
	return setmetatable({ game = gameService, sessions = {}, sequence = 0 }, Sprint)
end

function Sprint:other(s, p)
	if p == s.a then
		return s.b
	elseif p == s.b then
		return s.a
	end
end

function Sprint:available(p)
	local g = self.game
	local pro = g.profiles[p]
	return g:alive(p)
		and pro ~= nil
		and not g:busy(p)
		and g.carry[p] == nil
		and pro.lab.untilTime <= g:now()
end

function Sprint:context(s, requireNear)
	local g = self.game
	if not s or self.sessions[s.id] ~= s then
		return false, "Sprint session is stale."
	end
	for _, p in ipairs({ s.a, s.b }) do
		local pro = g.profiles[p]
		if
			not g:alive(p)
			or not pro
			or pro.sprint ~= s
			or pro.duel
			or pro.trade
			or pro.exchange
			or pro.trial
			or pro.incubatorPreview
			or g.carry[p]
		then
			return false, "A racer became unavailable."
		end
	end
	if requireNear and (g:root(s.a).Position - g:root(s.b).Position).Magnitude > C.SprintRange then
		return false, "Racers moved too far apart."
	end
	return true
end

function Sprint:request(a, b)
	local g = self.game
	if a == b or not self:available(a) or not self:available(b) then
		return false, "Choose another available player."
	end
	if (g:root(a).Position - g:root(b).Position).Magnitude > C.SprintRange then
		return false, "Move closer to that player."
	end
	self.sequence += 1
	local now = g:now()
	local s = {
		id = "sprint-" .. self.sequence,
		a = a,
		b = b,
		requester = a,
		phase = "Requested",
		deadline = now + C.SprintRequestTime,
		runs = {},
		finished = {},
		dnf = {},
		jump = {},
		collision = {},
	}
	self.sessions[s.id] = s
	g.profiles[a].sprint = s
	g.profiles[b].sprint = s
	a:SetAttribute("Busy", true)
	b:SetAttribute("Busy", true)
	g:notify(a, "Sprint challenge sent to " .. b.DisplayName .. ".")
	g:push(a)
	g:push(b)
	return true
end

function Sprint:reply(p, accept)
	local pro = self.game.profiles[p]
	local s = pro and pro.sprint
	if not s or s.phase ~= "Requested" or p ~= s.b then
		return false, "No Sprint invitation is waiting."
	end
	if accept ~= true then
		self:complete(s, nil, "Sprint declined.")
		return true
	end
	local ok, err = self:context(s, true)
	if not ok then
		self:complete(s, nil, err)
		return false, err
	end
	s.phase = "Staging"
	s.deadline = self.game:now() + C.SprintStageTime
	for _, racer in ipairs({ s.a, s.b }) do
		self.game:notify(racer, "Meet at the Grove Circuit start. Normalized race • no stakes.", "tick")
	end
	self.game:push(s.a)
	self.game:push(s.b)
	return true
end

function Sprint:setRaceCollision(s, p)
	s.collision[p] = s.collision[p] or {}
	local char = p.Character
	if not char then
		return
	end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			s.collision[p][part] = part.CollisionGroup
			part.CollisionGroup = GROUP
		end
	end
end

function Sprint:restoreRaceCollision(s, p)
	for part, group in pairs(s.collision[p] or {}) do
		if part.Parent then
			part.CollisionGroup = group
		end
	end
	s.collision[p] = nil
end

function Sprint:prepareCountdown(s)
	local g = self.game
	local center = g.world.trialStart.Position
	for _, p in ipairs({ s.a, s.b }) do
		if (g:root(p).Position - center).Magnitude > C.SprintStartRadius then
			return false
		end
	end
	s.phase = "Countdown"
	s.deadline = g:now() + C.SprintCountdown
	local offsets = { [s.a] = -2.5, [s.b] = 2.5 }
	for _, p in ipairs({ s.a, s.b }) do
		local h = g:humanoid(p)
		s.jump[p] = { use = h.UseJumpPower, power = h.JumpPower, height = h.JumpHeight }
		p:SetAttribute("InSprint", true)
		self:setRaceCollision(s, p)
		h.UseJumpPower = true
		h.JumpPower = 0
		h.WalkSpeed = 0
		local start = center + Vector3.new(offsets[p], 3, 0)
		g:teleport(p, CFrame.lookAt(start, g.world.trialGates[1]))
	end
	g:push(s.a)
	g:push(s.b)
	return true
end

function Sprint:startRace(s)
	local g = self.game
	local ok, err = self:context(s, false)
	if not ok then
		self:complete(s, nil, err)
		return false
	end
	for _, p in ipairs({ s.a, s.b }) do
		if (g:root(p).Position - g.world.trialStart.Position).Magnitude > C.SprintStartRadius + 5 then
			self:complete(s, nil, "A racer left the starting area.")
			return false
		end
	end
	local started = g:now()
	s.phase = "Active"
	s.started = started
	s.deadline = started + C.TrialTimeout
	for _, p in ipairs({ s.a, s.b }) do
		s.runs[p] = g.trials:routeBegin(p, started)
		local records = recordDefaults(g.profiles[p].lab.records)
		records.sprintEntered += 1
		local h = g:humanoid(p)
		h.UseJumpPower = true
		h.JumpPower = 50
		g:applySpeed(p)
		g:notify(p, "GO! First valid finish wins.", "pickup")
	end
	g:push(s.a)
	g:push(s.b)
	return true
end

function Sprint:finishParticipant(s, p, now)
	if s.finished[p] then
		return
	end
	local g = self.game
	local run = s.runs[p]
	if not run or run.nextGate <= #g.world.trialGates then
		return
	end
	local elapsed = now - s.started
	s.finished[p] = elapsed
	local records = recordDefaults(g.profiles[p].lab.records)
	if not records.bestSprint or elapsed < records.bestSprint then
		records.bestSprint = elapsed
	end
	if not s.winner then
		s.winner = p
	end
	local h = g:humanoid(p)
	if h then
		h.WalkSpeed = 0
	end
	local other = self:other(s, p)
	if s.finished[other] then
		self:complete(s, s.winner, "Both racers finished.")
	else
		s.phase = "Finishing"
		s.deadline = now + C.SprintFinishGrace
		g:push(s.a)
		g:push(s.b)
	end
end

function Sprint:dnf(s, p, reason)
	if not s or self.sessions[s.id] ~= s or s.dnf[p] or s.finished[p] then
		return
	end
	s.dnf[p] = reason or "Run invalid."
	local other = self:other(s, p)
	if not s.winner and other and not s.dnf[other] then
		s.winner = other
	end
	self:complete(s, s.winner, (p and p.DisplayName or "A racer") .. " received a DNF: " .. s.dnf[p])
end

function Sprint:formatTime(value)
	return value and string.format("%.2fs", value) or "DNF"
end

function Sprint:complete(s, winner, reason)
	if not s or self.sessions[s.id] ~= s then
		return
	end
	local g = self.game
	self.sessions[s.id] = nil
	if s.started then
		for _, p in ipairs({ s.a, s.b }) do
			local pro = g.profiles[p]
			if pro then
				local records = recordDefaults(pro.lab.records)
				if s.dnf[p] then
					records.sprintDNFs += 1
				end
				if winner == p then
					records.sprintWins += 1
					records.sprintStreak += 1
					records.bestSprintStreak = math.max(records.bestSprintStreak, records.sprintStreak)
				elseif winner then
					records.sprintStreak = 0
				end
			end
		end
	end
	for _, p in ipairs({ s.a, s.b }) do
		local pro = g.profiles[p]
		local other = self:other(s, p)
		if pro and pro.sprint == s then
			pro.sprint = nil
			local mine = self:formatTime(s.finished[p])
			local theirs = self:formatTime(s.finished[other])
			local title = not s.started and "SPRINT CANCELED"
				or (s.dnf[p] and "SPRINT DNF")
				or (winner == p and "SPRINT WIN")
				or (winner and "SPRINT LOSS")
				or "SPRINT COMPLETE"
			pro.result = {
				title = title,
				text = (reason or "Sprint complete.") .. " No Coins or items moved.",
				score = mine .. "  •  " .. theirs,
				untilTime = g:now() + 12,
			}
		end
		self:restoreRaceCollision(s, p)
		if p.Parent == Players then
			p:SetAttribute("InSprint", false)
			local h = g:humanoid(p)
			local jump = s.jump[p]
			if h and jump then
				h.UseJumpPower = jump.use
				h.JumpPower = jump.power
				h.JumpHeight = jump.height
			end
			if pro then
				p:SetAttribute(
					"Busy",
					pro.duel ~= nil or pro.trade ~= nil or pro.exchange ~= nil or pro.trial ~= nil or pro.incubatorPreview ~= nil
				)
				g:applySpeed(p)
				g:push(p)
			end
		end
	end
end

function Sprint:cancel(p)
	local pro = self.game.profiles[p]
	local s = pro and pro.sprint
	if not s then
		return false, "No Sprint is active."
	end
	if s.phase == "Active" or s.phase == "Finishing" then
		self:dnf(s, p, "Race canceled.")
	else
		self:complete(s, nil, "Sprint canceled.")
	end
	return true
end

function Sprint:died(p)
	local pro = self.game.profiles[p]
	local s = pro and pro.sprint
	if not s then
		return
	end
	if s.phase == "Active" or s.phase == "Finishing" then
		self:dnf(s, p, "Respawn during race.")
	else
		self:complete(s, nil, "Sprint canceled on respawn.")
	end
end

function Sprint:leaving(p)
	local pro = self.game.profiles[p]
	local s = pro and pro.sprint
	if not s then
		return
	end
	if s.phase == "Active" or s.phase == "Finishing" then
		self:dnf(s, p, "Player disconnected.")
	else
		self:complete(s, nil, "Sprint canceled because a player disconnected.")
	end
end

function Sprint:step(dt, now)
	local sessions = {}
	for _, s in pairs(self.sessions) do
		table.insert(sessions, s)
	end
	for _, s in ipairs(sessions) do
		if self.sessions[s.id] == s then
			local ok, err = self:context(s, s.phase == "Requested")
			if not ok then
				self:complete(s, nil, err)
			elseif s.phase == "Requested" then
				if now >= s.deadline then
					self:complete(s, nil, "Sprint invitation expired.")
				end
			elseif s.phase == "Staging" then
				if now >= s.deadline then
					self:complete(s, nil, "Sprint staging timed out.")
				else
					self:prepareCountdown(s)
				end
			elseif s.phase == "Countdown" then
				if now >= s.deadline then
					self:startRace(s)
				end
			elseif s.phase == "Active" or s.phase == "Finishing" then
				for _, p in ipairs({ s.a, s.b }) do
					if self.sessions[s.id] ~= s then
						break
					end
					if not s.finished[p] then
						local observedNow = self.game:now()
						local passed, why, event = self.game.trials:routeStep(p, s.runs[p], dt, observedNow)
						if not passed then
							self:dnf(s, p, why)
							break
						elseif event then
							self.game:feed(p, "sprintGate", { index = event.index })
							if event.finished then
								self:finishParticipant(s, p, self.game:now())
							else
								self.game:push(s.a)
								self.game:push(s.b)
							end
						end
					end
				end
				if self.sessions[s.id] == s and s.phase == "Finishing" and now >= s.deadline then
					local other = self:other(s, s.winner)
					if other and not s.finished[other] then
						self:dnf(s, other, "Finish grace expired.")
					end
				end
			end
		end
	end
end

function Sprint:snapshot(p)
	local pro = self.game.profiles[p]
	local s = pro and pro.sprint
	if not s then
		return nil
	end
	local other = self:other(s, p)
	local run = s.runs[p]
	return {
		id = s.id,
		phase = s.phase,
		opponent = other and other.DisplayName or "Unknown",
		opponentUserId = other and other.UserId or nil,
		recipient = p == s.b,
		deadline = s.deadline,
		started = s.started,
		nextGate = run and run.nextGate or nil,
		total = #self.game.world.trialGates,
		finished = s.finished[p] ~= nil,
		mineTime = s.finished[p],
		otherTime = other and s.finished[other] or nil,
		winnerUserId = s.winner and s.winner.UserId or nil,
	}
end

return Sprint
