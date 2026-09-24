-- One normalized circuit. Solo Trial and Sprint Rivalry share RouteRun validation.
local C = require(game:GetService("ReplicatedStorage").Stage3Shared.Config)
local RouteRun = require(script.Parent.RouteRun)

local Trials = {}
Trials.__index = Trials

function Trials.new(gameService)
	return setmetatable({ game = gameService }, Trials)
end

function Trials:routeBegin(p, started)
	return RouteRun.begin(self.game, p, started)
end

function Trials:routeValidate(p, run, now)
	return RouteRun.validate(self.game, p, run, now)
end

function Trials:routeGate(p, run, index, now)
	return RouteRun.gate(self.game, p, run, index, now)
end

function Trials:routeStep(p, run, dt, now)
	return RouteRun.step(self.game, p, run, dt, now)
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
	local jumpPower, jumpHeight, useJumpPower = h.JumpPower, h.JumpHeight, h.UseJumpPower
	g:teleport(p, CFrame.lookAt(start, g.world.trialGates[1]))
	pro.lab.untilTime = 0
	local trial = self:routeBegin(p, g:now())
	trial.jumpPower = jumpPower
	trial.jumpHeight = jumpHeight
	trial.useJumpPower = useJumpPower
	pro.trial = trial
	h.UseJumpPower = true
	h.JumpPower = 50
	p:SetAttribute("InTrial", true)
	p:SetAttribute("Busy", true)
	g:applySpeed(p)
	g:feed(p, "trialGhost", { frames = pro.bestTrial and pro.bestTrial.frames or {}, started = trial.started })
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
		RouteRun.finalSample(g, p, trial, g:now())
		if not pro.bestTrial or elapsed < pro.bestTrial.time then
			pro.bestTrial = { time = elapsed, frames = trial.samples }
			g:notify(p, string.format("PERSONAL BEST • %.2fs! Your ghost is ready for the next run.", elapsed), "win")
		else
			g:notify(p, string.format("Circuit complete • %.2fs. Best %.2fs.", elapsed, pro.bestTrial.time), "win")
		end
		g.contracts:observe(p, "trial_finish")
	else
		g:notify(p, reason or "Trial canceled. No record changed.")
	end
	pro.trial = nil
	p:SetAttribute("InTrial", false)
	p:SetAttribute("Busy", pro.duel ~= nil or pro.trade ~= nil or pro.sprint ~= nil)
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
	local ok, err = self:routeValidate(p, trial, now)
	if not ok then
		self:finish(p, false, err)
		return false
	end
	return true
end

function Trials:gate(p, index)
	local g = self.game
	local pro = g.profiles[p]
	local trial = pro and pro.trial
	if not trial then
		return false, "No valid trial gate."
	end
	local ok, err, invalidate, finished = self:routeGate(p, trial, index, g:now())
	if not ok then
		if invalidate then
			self:finish(p, false, err)
		end
		return false, err
	end
	g:feed(p, "trialGate", { index = index })
	if finished then
		self:finish(p, true)
	else
		g:push(p)
	end
	return true
end

function Trials:step(p, dt, now)
	local pro = self.game.profiles[p]
	local trial = pro and pro.trial
	if not trial then
		return
	end
	local ok, err, event = self:routeStep(p, trial, dt, now)
	if not ok then
		self:finish(p, false, err)
		return
	end
	if event then
		self.game:feed(p, "trialGate", { index = event.index })
		if event.finished then
			self:finish(p, true)
		else
			self.game:push(p)
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
