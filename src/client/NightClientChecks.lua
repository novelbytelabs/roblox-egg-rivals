-- Explicit TEST-bundle probes inspect the running production controllers.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local C = require(game:GetService("ReplicatedStorage").Stage3Shared.Config)
local Checks = {}
local function waitFor(fn, seconds)
	local deadline = os.clock() + seconds
	repeat
		if fn() then
			return true
		end
		task.wait(0.05)
	until os.clock() > deadline
	return false
end
function Checks.run(effects, virtual, out, kind)
	assert(RunService:IsStudio() and workspace:GetAttribute("Stage3AutoTest") == true)
	local fixture, box, pool
	local lamp = effects.flashlight
	local prior = lamp.wanted
	local function pressF()
		virtual:SendKey(true, Enum.KeyCode.F, false)
		task.wait(0.08)
		virtual:SendKey(false, Enum.KeyCode.F, false)
		task.wait(0.15)
	end
	local ok, err = xpcall(function()
		if kind == "NightEdges" then
			assert(
				waitFor(function()
					return workspace:GetAttribute("Night") == true
				end, 3),
				"Night did not replicate"
			)
			local root = Players.LocalPlayer.Character.HumanoidRootPart
			fixture = Instance.new("Part")
			fixture.Name = "NightEdgeRegressionBlock"
			fixture.Size = Vector3.new(4, 6, 8)
			fixture.CFrame = CFrame.new(root.Position + Vector3.new(8, 3, 0)) * CFrame.Angles(0.2, 0.5, 0.1)
			fixture.Anchored = true
			fixture.CanCollide = false
			fixture.CanQuery = false
			fixture.CanTouch = false
			fixture.Parent = workspace.Moonwood.Scenery
			local original = fixture.CFrame
			assert(
				waitFor(function()
					local r = effects.edges.records[fixture]
					return r and r.beams and #r.beams == 12 and r.enabled
				end, 12),
				"New world object did not receive all twelve edges"
			)
			local record = effects.edges.records[fixture]
			assert(record.kind == "box-edges")
			local firstBeam = record.beams[1]
			for _, beam in ipairs(record.beams) do
				assert(beam:IsA("Beam") and beam.Enabled and beam.LightInfluence == 0 and beam.LightEmission == 1)
				assert(beam.Attachment0.Parent == fixture and beam.Attachment1.Parent == fixture)
				assert(beam.Width0 > 0 and beam.Width0 <= 0.08)
			end
			for _, child in ipairs(record.folder:GetDescendants()) do
				assert(not child:IsA("BasePart"), "Edge renderer created physics parts")
			end
			fixture.Size = Vector3.new(6, 8, 10)
			assert(
				waitFor(function()
					local r = effects.edges.records[fixture]
					return r and r.beams and r.beams[1] ~= firstBeam and #r.beams == 12
				end, 4),
				"Resized object retained stale edge geometry"
			)
			assert(firstBeam.Parent == nil and fixture.CFrame == original)
			local retired = fixture
			fixture:Destroy()
			fixture = nil
			assert(
				waitFor(function()
					return effects.edges.records[retired] == nil
				end, 4),
				"Destroyed object leaked edge records"
			)
			local ready = waitFor(function()
				local s = effects.edges:snapshot()
				return s.rendered >= 100 and s.pending == 0
			end, 15)
			out.edges = effects.edges:snapshot()
			assert(ready, "Nearby edge construction did not settle")
			assert(out.edges.budgetCulled == 0, "Visible world edge budget was exhausted")
			assert(out.edges.unsupported == 0, "Current world contains untraced mesh shapes")
			local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
			assert(
				waitFor(function()
					return bloom and math.abs(bloom.Intensity - C.Visual.NightBloomIntensity) < 0.02
				end, 3),
				"Night bloom did not reach reduced tuning"
			)
			out.bloom = bloom.Intensity
		elseif kind == "Flashlight" then
			local before = lamp.toggles
			pressF()
			assert(
				waitFor(function()
					return lamp.wanted ~= prior and lamp.light.Enabled == lamp.wanted
				end, 3),
				"Real F input did not toggle the light"
			)
			assert(lamp.toggles == before + 1, "One key press toggled more than once")
			out.afterToggle = lamp:snapshot()
			assert(lamp.light.Shadows and lamp.light.Range == C.Visual.FlashlightRange)
			assert(
				lamp.body.Anchored and not lamp.body.CanCollide and not lamp.body.CanTouch and not lamp.body.CanQuery
			)
			box = Instance.new("TextBox")
			box.Name = "FlashlightTextFocusProbe"
			box.Size = UDim2.fromOffset(180, 36)
			box.Parent = lamp.gui
			box:CaptureFocus()
			assert(
				waitFor(function()
					return UIS:GetFocusedTextBox() == box
				end, 2),
				"Text field did not receive input focus"
			)
			local wanted = lamp.wanted
			pressF()
			assert(lamp.wanted == wanted and lamp.toggles == before + 1, "Typing F toggled the flashlight")
			box:ReleaseFocus(false)
			box:Destroy()
			box = nil
			pressF()
			assert(
				waitFor(function()
					return lamp.wanted == prior
				end, 2),
				"Second F press did not restore the light"
			)
			out.final = lamp:snapshot()
		elseif kind == "LongTrails" then
			assert(waitFor(function()
				return workspace:GetAttribute("Night") == true
			end, 3))
			pool = require(script.Parent.MotionParticles).new(effects.folder)
			local now = workspace:GetServerTimeNow()
			local pos = Players.LocalPlayer.Character.HumanoidRootPart.Position
			for i = 1, C.Visual.MaxTrailPerObject + 20 do
				pool:trail("long-trail", pos - Vector3.new(i * 0.4, 0, 0), C.Colors.Blue, now, 45)
			end
			assert(#pool.particles == C.Visual.MaxTrailPerObject and #pool.particles > 24)
			for _, particle in ipairs(pool.particles) do
				assert(particle.life == C.Visual.TrailLifetime and particle.life > 1)
			end
			pool:update(0.01, now + 0.9)
			assert(#pool.particles == C.Visual.MaxTrailPerObject, "Long trail disappeared before one second")
			local allocated = pool.allocated
			pool:update(0.01, now + C.Visual.TrailLifetime + 0.01)
			assert(#pool.particles == 0)
			pool:trail("reused", pos, C.Colors.Blue, now + C.Visual.TrailLifetime + 0.1, 45)
			assert(pool.allocated == allocated, "Trail expiry did not return particles to pool")
			out.particles = pool:snapshot()
			out.lifetime = C.Visual.TrailLifetime
			out.rateAt45 = math.min(C.Visual.TrailRateMax, 45 * C.Visual.TrailRatePerSpeed)
			assert(out.rateAt45 > 45 * 1.15)
		elseif kind == "NightDawn" then
			assert(waitFor(function()
				return workspace:GetAttribute("Night") == false
			end, 3))
			assert(
				waitFor(function()
					return effects.edges:snapshot().enabled == 0
				end, 4),
				"Night edge beams remained enabled after dawn"
			)
			out.edges = effects.edges:snapshot()
		else
			error("Unknown Night/Forest probe")
		end
	end, debug.traceback)
	virtual:SendKey(false, Enum.KeyCode.F, false)
	if box then
		box:ReleaseFocus(false)
		box:Destroy()
	end
	if fixture then
		fixture:Destroy()
	end
	if pool then
		pool.folder:Destroy()
		for _, part in ipairs(pool.free) do
			part:Destroy()
		end
	end
	if lamp.wanted ~= prior then
		pressF()
	end
	assert(ok, err)
end
return Checks
