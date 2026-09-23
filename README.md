# Egg Rivals

Private canonical repository for Egg Rivals, a Roblox speed-heist, elemental-pet collection, living-ranch, social-economy, and opt-in rivalry game.

Current verified engineering baseline: `MOONWOOD-0.3.2-r2`.

The imported baseline passed 24/24 two-client Roblox Studio engine checks. Human presentation and gameplay-feel review remains a separate gate.

Core loop:

`train -> steal -> escape -> choose element -> hatch -> collect -> earn -> upgrade -> compete`

Canonical source is under `src/`. Rojo projects are `default.project.json` and `test.project.json`.

## Design documentation

Start with:

- `docs/GAME_DESIGN.md` — concise overview and document map.
- `docs/DESIGN_BIBLE.md` — canonical product identity and design pillars.
- `docs/DECISION_LEDGER.md` — approvals, superseded decisions, deferrals, and unresolved questions.
- `docs/ECONOMY_SPEED_RARITY_V2.md` — canonical Speed/economy/rarity replacement.
- `docs/NEXT_SLICE_0.4.0_LIVING_WORLD.md` — next major implementation slice.
- `docs/ASTRA_0.4.0_EXECUTION_PACKET.md` — long-running implementation packet.

Detailed system specifications cover core gameplay, camp/incubation/respawn, pet ranch, Speed Lab, Night, shops/social economy, PvP/duels, live operations, and production guardrails.

Generated `.rbxlx`, Studio recovery files, and local builds are not canonical source and must not be committed.

Item-transfer duels remain Studio-only pending a current Roblox publication-policy review. Progress remains session-only at the present development stage.

For implementation planning, `docs/FEATURE_STATUS_MATRIX.md` separates already verified baseline behavior from approved but not-yet-implemented design.
