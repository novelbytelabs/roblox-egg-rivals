# Egg Rivals

Private canonical repository for Egg Rivals, a Roblox speed-heist, elemental-pet collection, living-ranch, social-economy, and opt-in rivalry game.

Current verified engineering candidate: `EGG-RIVALS-0.4.0-rc1`.

The exact-source candidate passed **77/77** checks in a real two-client Roblox Studio regression. Tested source commit: `e185b078b7fd9f598e62130fb1dcaf008885fdb1`. Human presentation and gameplay-feel acceptance remains the active gate.

The prior `MOONWOOD-0.3.2-r2` 24/24 candidate remains preserved as the historical baseline.

Core loop:

`train -> steal -> escape -> choose element -> hatch -> collect -> earn -> upgrade -> compete`

Canonical source is under `src/`. Rojo projects are `default.project.json` and `test.project.json`.

## Current gate

0.4.0 is **ENGINEERING CANDIDATE VERIFIED; HUMAN PRESENTATION ACCEPTANCE PENDING**.

Owner playtesting should evaluate fun, movement feel, camp readability, pet life, ranch progression, Night presentation, shop/trading UX, and overall replay desire. Record findings in `docs/PLAYTEST_0.4.0.md`.

No merge to `main` or Roblox publication is authorized by engineering verification alone.

## Design documentation

Start with:

- `docs/GAME_DESIGN.md` — concise overview and document map.
- `docs/DESIGN_BIBLE.md` — canonical product identity and design pillars.
- `docs/DECISION_LEDGER.md` — approvals, superseded decisions, deferrals, and unresolved questions.
- `docs/ECONOMY_SPEED_RARITY_V2.md` — canonical Speed/economy/rarity replacement.
- `docs/FEATURE_STATUS_MATRIX.md` — implementation state versus approved aspirations.
- `docs/STAGE3_040_VERIFICATION.md` — exact 0.4.0 engineering evidence.
- `docs/PLAYTEST_0.4.0.md` — owner presentation/gameplay review.
- `docs/NEXT_SLICE_0.4.0_LIVING_WORLD.md` — historical implementation plan for the 0.4.0 Living World push.
- `docs/ASTRA_0.4.0_EXECUTION_PACKET.md` — historical execution packet for that push.

Detailed system specifications cover core gameplay, camp/incubation/respawn, pet ranch, Speed Lab, Night, shops/social economy, PvP/duels, live operations, and production guardrails.

Generated `.rbxlx`, Studio recovery files, and local builds are not canonical source and must not be committed.

Item-transfer duels remain Studio-only pending a current Roblox publication-policy review. Progress remains session-only at the present development stage.
