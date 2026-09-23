local RunService = game:GetService("RunService")
local gameService = require(script.Parent.Game).new()
if RunService:IsStudio() and workspace:GetAttribute("Stage3AutoTest") == true then
	task.spawn(function()
		local ok, err = xpcall(function()
			require(script.Parent.Tests).run(gameService)
		end, debug.traceback)
		if not ok then
			warn("[STAGE3 TEST FATAL] " .. tostring(err))
		end
	end)
end
