# Night and Forest refinement — 0.4.0 rc2

Authority: owner playtest feedback on 2026-09-24. Work remains on `feature/0.4.0-living-world`; no merge or Roblox publication.

## Design contract

| Request | Concrete behavior | Verification boundary |
|---|---|---|
| Trace object edges | Self-lit Beam strips on all eligible nearby primitive edges; rounded shapes receive contours/rims | Actual engine edge count, resize/despawn cleanup and budget diagnostics; human readability remains separate |
| Slightly softer glow | Bloom intensity 1.02 instead of 1.2; size 28 instead of 32; threshold 0.8 instead of 0.65 | Runtime reaches configured values; owner judges appearance |
| Longer, denser trails | 1.8-second lifetime; speed-scaled emission up to 96/s; up to 160 trail particles per object | Lifetime, density, expiry, reuse and existing stop/impact checks |
| Flashlight | Free hands-free personal light; F/HUD toggle; 56-stud range; shadows; no battery or economy | Real F input, text-focus rejection, nonphysical light rig |
| More eggs | Twelve distinct nest sites, preserving the original four and the existing world footprint | World construction, spacing and the complete theft/Trial regression |
| Godly eggs | One marked, defended Godly Day nest; random supported creature; 600-second replacement after removal | Actual Godly identity, pickup, Night transition and production respawn schedule |

Tuning is provisional. A dedicated Godly target raises total Godly supply even though normal day/night weighted probabilities do not change. No direct shop purchase or client-awarded inventory is introduced.

## Rendering and resource boundaries

Edge strips are client-only Beams and attachments, not colliding Parts. The current supported scene uses blocks, wedges, spheres and cylinders; arbitrary imported mesh edges require explicit topology handling. Smooth surfaces do not have artificial box edges.

Invisible triggers, transient particles, and the deferred duel arena are excluded. Edges are distance-culled at 180 studs, with a 1600-part bound and batched creation. Coverage overflow is reported by diagnostics rather than hidden. The high/low motion-particle budgets are 960/320. None of these settings establishes performance on mobile or console.

The flashlight is personal client presentation, not a new transferable inventory item. It pauses when the character is absent/dead, the client loses focus, or the player is in a duel. Respawn turns it off. It does not grant competitive power or reveal objects through walls.

## Regression plan

Retain all 77 rc1 checks. Update the original four-nest construction expectation to the explicitly requested twelve-nest specification, not to an unconstrained lower bound. Add nine checks for Forest topology, dedicated Godly identity, cooldown boundaries, real Godly pickup/Night behavior, shape contours, runtime edge lifecycle, real flashlight input, longer trails and dawn cleanup.

The cooldown test controls a fixture deadline to exercise both schedule boundaries. It does not claim a ten-minute real-time wait. Hold-confirmation tests retain their real durations and production input paths.

Build fresh paired PLAY/TEST artifacts, verify byte identity, make a writable exact-byte TEST execution copy, and use the real one-server/two-client Studio path. Preserve all failures. The rc1 77/0 result is not evidence that rc2 passes.

## Continued design work

The owner's priority remains main game mechanics and play. Do not turn this update into a broad cosmetic rewrite. Next, reconcile remaining 0.4.0 requirements against actual source and evidence, keeping implemented-but-unreviewed presentation distinct from absent mechanics. Preserve existing homecoming, shrine and treadmill-reaction code where present.

Potential next mechanics packet: a clearly scoped normalized two-player Sprint Challenge using existing Trial gates, equal movement settings, no stakes, and server-owned start/finish/timeout rules. This is a design proposal only; no race system, currencies, persistence or new zones are added in this update.

## Status

Implementation prepared. Exact-source Studio regression and human review of the changed presentation remain pending.

## API references

Roblox Creator Hub: Beam, SpotLight, and BloomEffect reference pages. The renderer uses documented attachments, additive emission, camera-facing beam surfaces and shadowed local lighting; it does not use an always-on-top selection outline.
