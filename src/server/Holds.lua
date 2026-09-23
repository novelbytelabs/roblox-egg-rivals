-- Time validation for deliberate UI actions. This is not a client trust boundary bypass.
local HttpService = game:GetService("HttpService")
local C = require(game:GetService("ReplicatedStorage").Stage3Shared.Config)
local R = require(game:GetService("ReplicatedStorage").Stage3Shared.Rules)
local Holds = {}
Holds.__index = Holds
function Holds.new(gameService)
	return setmetatable({ game = gameService, active = {} }, Holds)
end
function Holds:begin(player, kind, fingerprint, duration, nonce)
	if
		not R.id(nonce)
		or not R.id(kind)
		or type(fingerprint) ~= "string"
		or #fingerprint > 1024
		or not R.finite(duration)
		or duration <= 0
		or duration > 10
	then
		return nil, "Invalid confirmation."
	end
	local h = {
		token = HttpService:GenerateGUID(false),
		nonce = nonce,
		kind = kind,
		fingerprint = fingerprint,
		started = self.game:now(),
		duration = duration,
	}
	h.expires = h.started + duration + C.HoldLifetime
	self.active[player] = h
	return h
end
function Holds:consume(player, kind, fingerprint, token)
	local h = self.active[player]
	if not h or h.kind ~= kind or h.token ~= token or h.fingerprint ~= fingerprint then
		return false, "Confirmation changed or was canceled."
	end
	local now = self.game:now()
	if now > h.expires then
		self.active[player] = nil
		return false, "Confirmation expired."
	end
	if now - h.started < h.duration then
		return false, "Keep holding to confirm."
	end
	self.active[player] = nil
	return true
end
function Holds:cancel(player, nonce)
	local h = self.active[player]
	if h and (nonce == nil or nonce == h.nonce) then
		self.active[player] = nil
	end
end
function Holds:step(now)
	for p, h in pairs(self.active) do
		if now > h.expires or not p.Parent then
			self.active[p] = nil
		end
	end
end
return Holds
