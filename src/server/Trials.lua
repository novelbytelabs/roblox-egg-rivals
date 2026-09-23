-- One normalized circuit. Only real player-root movement can advance gates.
local C = require(game:GetService("ReplicatedStorage").Stage3Shared.Config)
local R = require(game:GetService("ReplicatedStorage").Stage3Shared.Rules)
local Trials = {}
Trials.__index = Trials
function Trials.new(gameService)
	return setmetatable({ game = gameService }, Trials)
end
function Trials:start(p)
	local g = self.game
	if not g:alive(p) or g:busy(p) or g.carry[p] then
		return false, "Finish your other activity and put down the egg."
	end
	if (g:root(p).Position - g.world.trialStart.Position).Magnitude > 10 then
		return false, "Visit the Grove Circuit start in the Meadow."
	end
	local pro = g.profiles[p]
	local h = g:humanoid(p)
	local start = g.world.trialStart.Position + Vector3.new(0, 3, 0)
	g:teleport(p, CFrame.lookAt(start, g.world.trialGates[1]))
	pro.lab.untilTime = 0
	pro.trial = {
		started = g:now(),
		nextGate = 1,
		samples = {},
		sampleCarry = 0,
		lastTime = g:now(),
		lastPos = start,
		teleportSerial = pro.teleportSerial,
		finishArmed = false,
		travel = {},
		jumpPower = h.JumpPower,
		jumpHeight = h.JumpHeight,
		useJumpPower = h.UseJumpPower,
	}
	h.UseJumpPower = true
	h.JumpPower = 50
	p:SetAttribute("InTrial", true)
	p:SetAttribute("Busy", true)
	g:applySpeed(p)
	g:feed(p, "trialGhost", { frames = pro.bestTrial and pro.bestTrial.frames or {}, started = pro.trial.started })
	g:notify(p, "GO! Follow numbered gates in order. Everyone runs at 45.", "pickup")
	g:push(p)
	return true
end
function Trials:finish(p, valid, reason)
	local g = self.game
	local pro = g.profiles[p]
	local trial = pro and pro.trial
	if not trial then
		return false, "No trial is active."
	end
	local elapsed = g:now() - trial.started
	if valid and trial.nextGate > #g.world.trialGates and elapsed > 0 then
		local root = g:root(p)
		table.insert(trial.samples, { t = elapsed, position = root.Position, look = root.CFrame.LookVector })
		if not pro.bestTrial or elapsed < pro.bestTrial.time then
			pro.bestTrial = { time = elapsed, frames = trial.samples }
			g:notify(p, string.format("PERSONAL BEST • %.2fs! Your ghost is ready for the next run.", elapsed), "win")
		else
			g:notify(p, string.format("Circuit complete • %.2fs. Best %.2fs.", elapsed, pro.bestTrial.time), "win")
		end
	else
		g:notify(p, reason or "Trial canceled. No record changed.")
	end
	pro.trial = nil
	p:SetAttribute("InTrial", false)
	p:SetAttribute("Busy", pro.duel ~= nil or pro.trade ~= nil)
	local h = g:humanoid(p)
	if h then
		h.UseJumpPower = trial.useJumpPower
		h.JumpPower = trial.jumpPower
		h.JumpHeight = trial.jumpHeight
	end
	g:applySpeed(p)
	g:feed(p, "trialEnded", {})
	g:push(p)
	return true
end
function Trials:validateMovement(p, now)
	local g = self.game
	local pro = g.profiles[p]
	local trial = pro and pro.trial
	if not trial then
		return false
	end
	if not g:alive(p) or now - trial.started > C.TrialTimeout or trial.teleportSerial ~= pro.teleportSerial then
		self:finish(p, false, "Trial stopped: respawn, teleport, or timeout.")
		return false
	end
	local root = g:root(p)
	local pos = root.Position
	if now <= trial.lastTime then
		return true
	end
	local elapsed = math.max(0.001, now - trial.lastTime)
	local delta = pos - trial.lastPos
	local horizontal = Vector3.new(delta.X, 0, delta.Z).Magnitude
	if horizontal > C.TrialSpeed * elapsed * 1.5 + 6 or math.abs(delta.Y) > 35 then
		self:finish(p, false, "Trial invalid: discontinuous movement. No record saved.")
		return false
	end
	table.insert(trial.travel, { time = now, distance = horizontal })
	while #trial.travel > 1 and trial.travel[1].time < now - 1 do
		table.remove(trial.travel, 1)
	end
	local distance = 0
	for _, entry in ipairs(trial.travel) do
		distance += entry.distance
	end
	if distance > C.TrialSpeed * 1.3 + 8 then
		self:finish(p, false, "Trial invalid: movement exceeded circuit settings.")
		return false
	end
	trial.lastTime, trial.lastPos = now, pos
	return true
end
function Trials:gate(p, index)
	local g = self.game
	local pro = g.profiles[p]
	local trial = pro and pro.trial
	if not trial or not g:alive(p) or not R.integer(index, 1, #g.world.trialGates) then
		return false, "No valid trial gate."
	end
	if not self:validateMovement(p, g:now()) then
		return false, "Movement invalidated the trial."
	end
	if index ~= trial.nextGate then
		self:finish(p, false, "Gate order missed. Try the circuit again.")
		return false, "Wrong gate order."
	end
	if (g:root(p).Position - g.world.trialGates[index]).Magnitude > C.TrialGateRadius then
		return false, "Move through the actual gate."
	end
	if index == #g.world.trialGates and not trial.finishArmed then
		return false, "Leave the start before finishing."
	end
	trial.nextGate += 1
	g:feed(p, "trialGate", { index = index })
	if trial.nextGate > #g.world.trialGates then
		self:finish(p, true)
	else
		g:push(p)
	end
	return true
end
function Trials:step(p, dt, now)
	local g = self.game
	local pro = g.profiles[p]
	local trial = pro.trial
	if not trial then
		return
	end
	if not g:alive(p) or now - trial.started > C.TrialTimeout or trial.teleportSerial ~= pro.teleportSerial then
		self:finish(p, false, "Trial stopped: respawn, teleport, or timeout.")
		return
	end
	if not self:validateMovement(p, now) then
		return
	end
	local root = g:root(p)
	local pos = root.Position
	if (pos - g.world.trialStart.Position).Magnitude > 12 then
		trial.finishArmed = true
	end
	trial.sampleCarry += dt
	if
		trial.sampleCarry >= C.TrialSampleInterval
		and #trial.samples < math.ceil(C.TrialTimeout / C.TrialSampleInterval) + 2
	then
		trial.sampleCarry = 0
		table.insert(trial.samples, { t = now - trial.started, position = pos, look = root.CFrame.LookVector })
	end
	-- Future gates cannot be skipped. The finish is also the start and is armed only after departure.
	for i = trial.nextGate, #g.world.trialGates do
		if
			(i ~= #g.world.trialGates or trial.finishArmed)
			and (pos - g.world.trialGates[i]).Magnitude <= C.TrialGateRadius
		then
			self:gate(p, i)
			break
		end
	end
end
function Trials:snapshot(p)
	local pro = self.game.profiles[p]
	local trial = pro.trial
	return {
		active = trial ~= nil,
		started = trial and trial.started or nil,
		nextGate = trial and trial.nextGate or nil,
		total = #self.game.world.trialGates,
		best = pro.bestTrial and pro.bestTrial.time or nil,
	}
end
return Trials
