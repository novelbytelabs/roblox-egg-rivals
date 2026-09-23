-- Classification rule used by the real client particle renderer and integration tests.
local C = require(script.Parent.Config)
local M = {}
function M.impact(recentFast, lastFastAt, now, speed, contact, latched)
	return contact == true
		and not latched
		and recentFast == true
		and now - lastFastAt <= C.Visual.ImpactWindow
		and speed <= C.Visual.StopSpeed
end
function M.moving(speed)
	return speed > C.Visual.ResumeSpeed
end
return M
