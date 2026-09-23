-- Pure rules are shared by the server and the real-engine regression tests.
local R = {}
function R.finite(n)
	return type(n) == "number" and n == n and math.abs(n) < 1e12
end
function R.speed(points)
	if not R.finite(points) then
		return 16
	end
	return 16 + 0.4 * math.sqrt(math.max(0, points))
end
function R.vector(v)
	return typeof(v) == "Vector3" and R.finite(v.X) and R.finite(v.Y) and R.finite(v.Z)
end
function R.nextNight(rng)
	-- 80% in 4-5 minutes, 10% earlier, 10% later; hard bounds 2-10 minutes.
	local roll = rng:NextNumber()
	if roll < 0.8 then
		return rng:NextInteger(240, 300)
	end
	if roll < 0.9 then
		return rng:NextInteger(120, 239)
	end
	return rng:NextInteger(301, 600)
end
function R.eligible(item, ownerId)
	return item ~= nil and item.ownerId == ownerId and item.state == "Inventory"
end
function R.clock(seconds)
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end
function R.within(position, center, halfX, halfZ, height)
	local d = position - center
	return math.abs(d.X) <= halfX and math.abs(d.Z) <= halfZ and d.Y >= -2 and d.Y <= height
end
return R
