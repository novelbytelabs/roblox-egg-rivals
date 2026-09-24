local C = require(game:GetService("ReplicatedStorage").Stage3Shared.Config)
local R = require(game:GetService("ReplicatedStorage").Stage3Shared.Rules)

local RouteRun = {}

function RouteRun.begin(g, p, started)
	local root = g:root(p)
	assert(root, "Route runner needs a live character root")
	return {
		started = started or g:now(),
		nextGate = 1,
		samples = {},
		sampleCarry = 0,
		lastTime = started or g:now(),
		lastPos = root.Position,
		teleportSerial = g.profiles[p].teleportSerial,
		finishArmed = false,
		travel = {},
	}
end

function RouteRun.validate(g, p, run, now)
	local pro = g.profiles[p]
	if not pro or not g:alive(p) then
		return false, "Run stopped: player unavailable."
	end
	if now - run.started > C.TrialTimeout then
		return false, "Run stopped: timeout."
	end
	if run.teleportSerial ~= pro.teleportSerial then
		return false, "Run stopped: teleport detected."
	end
	local root = g:root(p)
	local pos = root.Position
	if now <= run.lastTime then
		return true
	end
	local elapsed = math.max(0.001, now - run.lastTime)
	local delta = pos - run.lastPos
	local horizontal = Vector3.new(delta.X, 0, delta.Z).Magnitude
	if horizontal > C.TrialSpeed * elapsed * 1.5 + 6 or math.abs(delta.Y) > 35 then
		return false, "Run invalid: discontinuous movement."
	end
	table.insert(run.travel, { time = now, distance = horizontal })
	while #run.travel > 1 and run.travel[1].time < now - 1 do
		table.remove(run.travel, 1)
	end
	local distance = 0
	for _, entry in ipairs(run.travel) do
		distance += entry.distance
	end
	if distance > C.TrialSpeed * 1.3 + 8 then
		return false, "Run invalid: movement exceeded normalized settings."
	end
	run.lastTime = now
	run.lastPos = pos
	return true
end

function RouteRun.gate(g, p, run, index, now)
	if not R.integer(index, 1, #g.world.trialGates) then
		return false, "No valid route gate.", false
	end
	local ok, err = RouteRun.validate(g, p, run, now)
	if not ok then
		return false, err, true
	end
	if index ~= run.nextGate then
		return false, "Gate order missed.", true
	end
	if (g:root(p).Position - g.world.trialGates[index]).Magnitude > C.TrialGateRadius then
		return false, "Move through the actual gate.", false
	end
	if index == #g.world.trialGates and not run.finishArmed then
		return false, "Leave the start before finishing.", false
	end
	run.nextGate += 1
	return true, nil, false, run.nextGate > #g.world.trialGates
end

function RouteRun.step(g, p, run, dt, now)
	local ok, err = RouteRun.validate(g, p, run, now)
	if not ok then
		return false, err, nil, true
	end
	local root = g:root(p)
	local pos = root.Position
	if (pos - g.world.trialStart.Position).Magnitude > 12 then
		run.finishArmed = true
	end
	run.sampleCarry += dt
	if
		run.sampleCarry >= C.TrialSampleInterval
		and #run.samples < math.ceil(C.TrialTimeout / C.TrialSampleInterval) + 2
	then
		run.sampleCarry = 0
		table.insert(run.samples, { t = now - run.started, position = pos, look = root.CFrame.LookVector })
	end
	for i = run.nextGate, #g.world.trialGates do
		if
			(i ~= #g.world.trialGates or run.finishArmed)
			and (pos - g.world.trialGates[i]).Magnitude <= C.TrialGateRadius
		then
			local passed, why, invalidate, finished = RouteRun.gate(g, p, run, i, now)
			if not passed then
				return false, why, nil, invalidate
			end
			return true, nil, { index = i, finished = finished }, false
		end
	end
	return true
end

function RouteRun.finalSample(g, p, run, now)
	local root = g:root(p)
	if root then
		table.insert(run.samples, { t = now - run.started, position = root.Position, look = root.CFrame.LookVector })
	end
end

return RouteRun
