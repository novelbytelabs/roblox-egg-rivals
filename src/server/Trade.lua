local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local C = require(game:GetService("ReplicatedStorage").Stage3Shared.Config)
local R = require(game:GetService("ReplicatedStorage").Stage3Shared.Rules)
local Trade = {}
Trade.__index = Trade

function Trade.new(gameService)
	return setmetatable({ game = gameService, sessions = {} }, Trade)
end

function Trade:context(s)
	local g = self.game
	if not s or self.sessions[s.id] ~= s or g:now() >= s.expires then
		return false, "Trade expired."
	end
	for _, p in ipairs({ s.a, s.b }) do
		local pro = g.profiles[p]
		if
			not g:alive(p)
			or not pro
			or pro.trade ~= s
			or pro.duel
			or pro.exchange
			or pro.trial
			or pro.incubatorPreview
			or g.carry[p]
		then
			return false, "A trader became unavailable."
		end
		if pro.hatched < 3 or pro.onboardingComplete ~= true then
			return false, "Trading is not unlocked."
		end
		if (g:root(p).Position - g.world.tradingPost.Position).Magnitude > C.ShopRange + 8 then
			return false, "A trader left the Trading Post."
		end
	end
	if (g:root(s.a).Position - g:root(s.b).Position).Magnitude > C.TradeRange then
		return false, "Traders moved too far apart."
	end
	return true
end
function Trade:validate(s)
	local ok, err = self:context(s)
	if not ok then
		self:close(s, err, false)
		return false, err
	end
	local expected = {}
	for _, p in ipairs({ s.a, s.b }) do
		if not self.game.inventory:validateIds(s.offers[p], C.MaxTradeItems) then
			self:close(s, "Invalid offer structure.", false)
			return false, "Invalid offer."
		end
		for _, id in ipairs(s.offers[p]) do
			local item = self.game.inventory.items[id]
			if
				expected[id]
				or not item
				or item.ownerId ~= p.UserId
				or item.state ~= "Trade"
				or item.reservation ~= s.id
				or item.locked
				or item.favorite
				or item.petMode == "Active"
				or s.itemSignatures[id] ~= R.itemSignature(item)
			then
				self:close(s, "An offered item changed. No transfer occurred.", false)
				return false, "Offer identity changed."
			end
			expected[id] = true
		end
	end
	for id, item in pairs(self.game.inventory.items) do
		if item.reservation == s.id and not expected[id] then
			self:close(s, "Reservation mismatch. All items returned.", false)
			return false, "Unexpected reserved item."
		end
	end
	return true
end
function Trade:other(s, p)
	if s.a == p then
		return s.b
	elseif s.b == p then
		return s.a
	end
end

function Trade:itemsContainGodly(ids)
	for _, id in ipairs(ids) do
		local item = self.game.inventory.items[id]
		if item and item.rarity == "Godly" then
			return true
		end
	end
	return false
end

function Trade:hasGodly(s)
	return self:itemsContainGodly(s.offers[s.a] or {}) or self:itemsContainGodly(s.offers[s.b] or {})
end
function Trade:request(a, b)
	local g = self.game
	if a == b or not g:alive(a) or not g:alive(b) or g:busy(a) or g:busy(b) then
		return false, "Both players must be available."
	end
	if g.carry[a] or g.carry[b] then
		return false, "Secure carried eggs before trading."
	end
	local pa, pb = g.profiles[a], g.profiles[b]
	if pa.hatched < 3 or pb.hatched < 3 or pa.onboardingComplete ~= true or pb.onboardingComplete ~= true then
		return false, "Trading unlocks after each player hatches three pets."
	end
	local ra, rb = g:root(a), g:root(b)
	if (ra.Position - rb.Position).Magnitude > C.TradeRange then
		return false, "Move closer to the other player."
	end
	if
		(ra.Position - g.world.tradingPost.Position).Magnitude > C.ShopRange + 8
		or (rb.Position - g.world.tradingPost.Position).Magnitude > C.ShopRange + 8
	then
		return false, "Both players must meet at the Trading Post."
	end
	local now = g:now()
	if (pa.tradeCooldown or 0) > now or (pb.tradeCooldown or 0) > now then
		return false, "A recent trade is still cooling down."
	end
	local s = {
		id = HttpService:GenerateGUID(false),
		a = a,
		b = b,
		requester = a,
		phase = "Requested",
		offers = { [a] = {}, [b] = {} },
		ready = { [a] = false, [b] = false },
		baseReady = { [a] = false, [b] = false },
		revision = 1,
		itemSignatures = {},
		expires = now + C.RequestTime,
	}
	pa.trade, pb.trade = s, s
	a:SetAttribute("Busy", true)
	b:SetAttribute("Busy", true)
	self.sessions[s.id] = s
	g:push(a)
	g:push(b)
	return true
end
function Trade:close(s, reason, committed)
	if not s or not self.sessions[s.id] then
		return
	end
	if not committed then
		self.game.inventory:release(s.id)
	end
	self.sessions[s.id] = nil
	self.game:reconcilePets()
	for _, p in ipairs({ s.a, s.b }) do
		local pro = self.game.profiles[p]
		if pro and pro.trade == s then
			pro.trade = nil
			pro.tradeCooldown = self.game:now() + C.TradeCooldown
			p:SetAttribute("Busy", pro.duel ~= nil or p:GetAttribute("InTrial") == true)
			self.game.holds:cancel(p)
			if reason then
				self.game:notify(p, reason)
			end
			self.game:push(p)
		end
	end
end

function Trade:reply(p, accept)
	local pro = self.game.profiles[p]
	local s = pro and pro.trade
	if not s or s.phase ~= "Requested" or p == s.requester then
		return false, "No trade invitation is waiting."
	end
	if accept ~= true then
		self:close(s, "Trade declined.", false)
		return true
	end
	local valid, err = self:validate(s)
	if not valid then
		return false, err
	end
	s.phase = "Selecting"
	s.expires = self.game:now() + C.TradeLifetime
	s.revision += 1
	self.game:push(s.a)
	self.game:push(s.b)
	return true
end
function Trade:offer(p, ids, revision)
	local pro = self.game.profiles[p]
	local s = pro and pro.trade
	if not s or s.phase ~= "Selecting" then
		return false, "No trade offer is being edited."
	end
	local valid, why = self:validate(s)
	if not valid then
		return false, why
	end
	if revision ~= s.revision then
		return false, "Review the latest trade offer."
	end
	if type(ids) ~= "table" then
		return false, "Invalid trade offer."
	end
	local ok, err = self.game.inventory:reserveOffer(p.UserId, ids, s.id, "Trade")
	if not ok then
		return false, err
	end
	s.offers[p] = table.clone(ids)
	s.itemSignatures = {}
	for _, side in ipairs({ s.a, s.b }) do
		for _, id in ipairs(s.offers[side]) do
			s.itemSignatures[id] = R.itemSignature(self.game.inventory.items[id])
		end
	end
	self.game:reconcilePets()
	s.ready[s.a], s.ready[s.b] = false, false
	s.baseReady[s.a], s.baseReady[s.b] = false, false
	s.revision += 1
	s.expires = self.game:now() + C.TradeLifetime
	self.game.holds:cancel(s.a)
	self.game.holds:cancel(s.b)
	self.game:push(s.a)
	self.game:push(s.b)
	return true
end

function Trade:fingerprint(s, p, stage)
	local parts = { s.id, tostring(s.revision), tostring(p.UserId), stage }
	for _, side in ipairs({ s.a, s.b }) do
		for _, id in ipairs(s.offers[side]) do
			table.insert(
				parts,
				id .. ":" .. tostring(self.game.inventory.items[id] and self.game.inventory.items[id].revision)
			)
		end
	end
	return table.concat(parts, "|")
end

function Trade:beginHold(p, nonce)
	local pro = self.game.profiles[p]
	local s = pro and pro.trade
	if not s or s.phase ~= "Selecting" or #s.offers[s.a] == 0 or #s.offers[s.b] == 0 then
		return false, "Both sides need an offer first."
	end
	local valid, err = self:validate(s)
	if not valid then
		return false, err
	end
	if s.ready[p] then
		return false, "Your offer is already confirmed."
	end
	local stage = s.baseReady[p] and self:hasGodly(s) and "Godly" or "Base"
	if stage == "Godly" and s.ready[p] then
		return false, "Your trade is already confirmed."
	end
	local duration = stage == "Godly" and C.GodlyHold or C.TradeHold
	local hold, err = self.game.holds:begin(p, "trade" .. stage, self:fingerprint(s, p, stage), duration, nonce)
	if not hold then
		return false, err
	end
	self.game:feed(p, "tradeHold", {
		token = hold.token,
		nonce = hold.nonce,
		started = hold.started,
		stage = stage,
		duration = duration,
		revision = s.revision,
		sessionId = s.id,
	})
	return true
end
function Trade:completeHold(p, token, stage)
	local pro = self.game.profiles[p]
	local s = pro and pro.trade
	if not s or s.phase ~= "Selecting" or (stage ~= "Base" and stage ~= "Godly") then
		return false, "Trade confirmation is stale."
	end
	local valid, why = self:validate(s)
	if not valid then
		return false, why
	end
	if s.ready[p] or (stage == "Godly" and (not s.baseReady[p] or not self:hasGodly(s))) then
		return false, "This confirmation stage is not active."
	end
	local ok, err = self.game.holds:consume(p, "trade" .. stage, self:fingerprint(s, p, stage), token)
	if not ok then
		return false, err
	end
	if stage == "Base" and self:hasGodly(s) then
		s.baseReady[p] = true
		self.game:notify(p, "Godly item detected. Hold once more for the five-second final confirmation.")
		self.game:push(p)
		return true
	end
	s.baseReady[p] = true
	s.ready[p] = true
	if not (s.ready[s.a] and s.ready[s.b]) then
		self.game:push(s.a)
		self.game:push(s.b)
		return true
	end
	local committed, result = self.game.inventory:transfer(s.id, s.a.UserId, s.offers[s.a], s.b.UserId, s.offers[s.b])
	if not committed then
		self:close(s, "Trade canceled: " .. tostring(result), false)
		return false, result
	end
	for _, change in ipairs(result) do
		if change.item.kind == "Pet" then
			local owner = Players:GetPlayerByUserId(change.to)
			if owner and self.game.profiles[owner] then
				self.game.ranch:acquired(owner, change.item)
			end
		end
	end
	self.game:reconcilePets()
	self:close(s, "Trade complete.", true)
	return true
end
function Trade:cancel(p)
	local pro = self.game.profiles[p]
	local s = pro and pro.trade
	if not s then
		return false, "No trade is active."
	end
	self:close(s, "Trade canceled. All items returned.", false)
	return true
end

function Trade:leaving(p)
	local pro = self.game.profiles[p]
	if pro and pro.trade then
		self:close(pro.trade, "Trade canceled because a player disconnected.", false)
	end
end

function Trade:step(now)
	local sessions = {}
	for _, s in pairs(self.sessions) do
		table.insert(sessions, s)
	end
	for _, s in ipairs(sessions) do
		self:validate(s)
	end
end

function Trade:snapshot(p)
	local pro = self.game.profiles[p]
	local s = pro and pro.trade
	if not s then
		return nil
	end
	local other = self:other(s, p)
	local function snapshots(ids)
		local out = {}
		for _, id in ipairs(ids) do
			local item = self.game.inventory.items[id]
			if item then
				table.insert(out, self.game.inventory:snapshotItem(item))
			end
		end
		return out
	end
	return {
		id = s.id,
		phase = s.phase,
		revision = s.revision,
		opponent = other and other.DisplayName or "Unknown",
		opponentUserId = other and other.UserId or nil,
		recipient = p ~= s.requester,
		mine = snapshots(s.offers[p] or {}),
		theirs = snapshots(s.offers[other] or {}),
		ready = s.ready[p] == true,
		otherReady = s.ready[other] == true,
		baseReady = s.baseReady[p] == true,
		hasGodly = self:hasGodly(s),
		deadline = s.expires,
	}
end

return Trade
