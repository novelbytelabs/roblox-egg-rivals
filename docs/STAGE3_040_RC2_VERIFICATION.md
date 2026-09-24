# Egg Rivals 0.4.0 rc2 — Night and Forest engineering verification

Candidate: `EGG-RIVALS-0.4.0-rc2`
Tested source commit: `bc6ecffb62b13a2b50cfc029935e3decd6d597dc`
Source digest: `cd3456d8f2dcaef01b967582d599ec426ecb41d6dd51d2044c01912a0ef87a7f`
Status: **ENGINEERING CANDIDATE VERIFIED; OWNER PRESENTATION RECHECK PENDING**.

The fresh exact-source Studio regression completed **86 checks: 86 passed, 0 failed**. It used one real Studio test server and two real Studio clients. Source remained unchanged after execution.

## Verified owner-feedback refinement

- twelve Forest nests within the existing world footprint;
- one marked server-authoritative Godly Day nest with independent creature roll and 600-second replacement delay;
- ordinary day/night rarity-roll tables preserved;
- broader client-only Night edge tracing using bounded shape-aware Beam geometry;
- softer Night bloom tuning;
- longer, denser bounded particle trails with reuse and impact conversion preserved;
- free personal flashlight on `L`, with no inventory/economy authority and no duel-forfeit collision;
- dawn cleanup of edge presentation;
- all prior rc1 regression invariants retained.

## Exact evidence

- Engine result: `tests/engine-20260924T161604676807Z.json`
- Engine-result SHA-256: `f64453606427f99a962907ef5617e9a3c84283d4253524ddff187c166d4c98c9`
- PLAY artifact SHA-256: `99d049283b9b4feb049e8fe7709c90e9d71fb6c5c065c1c660f4126892b00d43`
- TEST artifact SHA-256: `2fa17eb4affc32f6ed0e309a742b0286b2b10b483ab1999ff8c42708bea4252f`
- PLAY/TEST gameplay scripts: 31 byte-identical scripts
- Real topology: one server + two clients
- Foreground START cue: exit 0
- Foreground DONE cue: exit 0
- Background OPEN cue: exit 0 before Studio launch
- Background CLOSE cue: exit 0 immediately after Studio close
- Source unchanged after run: yes

## Preserved failures

Two complete rc2 attempts remain preserved rather than overwritten:

- `tests/engine-20260924T153932019873Z.json`: 85 passed / 1 failed; real Godly pickup fixture placement did not settle.
- `tests/engine-20260924T155026855692Z.json`: 85 passed / 1 failed; scenario cleanup placement raced the next Overdrive fixture.

The final repair synchronized saved-CFrame cleanup through the existing real-client/server position observation rather than weakening production proximity or removing the client assertion.

## Claim boundary

Automated evidence establishes the engineering candidate, not visual quality or owner acceptance of the new tuning. Bloom, edge density, trail density/length, flashlight feel, nest count and Godly cooldown remain owner-playtest tunable. Progress remains session-only. Nothing was published to Roblox and nothing was merged to `main`.
