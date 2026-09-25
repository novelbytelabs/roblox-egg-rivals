# Egg Rivals

Private canonical repository for Egg Rivals, a Roblox speed-heist, elemental-pet collection, living-ranch, social-economy, and opt-in rivalry game.

Current verified engineering candidate: `EGG-RIVALS-0.4.3-rc1`.

The exact-source 0.4.3 candidate passed **104/104** checks in a real two-client Roblox Studio regression. The exact tested source bytes are committed at `f4be2411712ffec3f3dfd8c23f69dea7307a45d1`. Source digest: `0875af46f723f9a964062a3d255d126450934438dc91699d1f76a066eef648be`.

0.4.3 retains the Night/Forest refinement, Sprint Rivalry and Ranger Contracts, then adds free server-owned Elemental Tuning v1 for the Speed Lab: Standard, Fire, Water, Wind and Earth sidegrades with bounded tradeoffs.

Human tuning feel/balance remains a separate owner-review gate. The prior 0.4.2 99/99, 0.4.1 90/90, 0.4.0-rc2 86/86, rc1 77/77 and `MOONWOOD-0.3.2-r2` 24/24 candidates remain preserved historical evidence.

Core loop:

`train -> steal -> escape -> choose element -> hatch -> collect -> earn -> upgrade -> compete`

Canonical source is under `src/`. Rojo projects are `default.project.json` and `test.project.json`.

## Current direction

The owner wants continued emphasis on **main mechanics and play** rather than polish closure.

Elemental Tuning v1 is engineering-verified. It deepens the Speed Lab with free tactical sidegrades while preserving normalized Trial/Sprint movement, the 68 studs/s Overdrive cap, and existing economy/inventory authority.

No merge to `main` or Roblox publication is authorized by engineering verification alone.

## Design documentation

Start with:

- `docs/GAME_DESIGN.md` — concise overview and document map.
- `docs/DESIGN_BIBLE.md` — canonical product identity and design pillars.
- `docs/DECISION_LEDGER.md` — approvals, superseded decisions, deferrals, and unresolved questions.
- `docs/FEATURE_STATUS_MATRIX.md` — implementation state versus approved aspirations.
- `docs/STAGE3_040_RC2_VERIFICATION.md` — Night/Forest refinement evidence.
- `docs/STAGE3_041_VERIFICATION.md` — Sprint Rivalry evidence.
- `docs/STAGE3_043_VERIFICATION.md` — Elemental Tuning evidence.
- `docs/NEXT_SLICE_0.4.3_ELEMENTAL_TUNING.md` — implemented Elemental Tuning design packet.
- `docs/STAGE3_042_VERIFICATION.md` — Ranger Contracts evidence.
- `docs/NEXT_SLICE_0.4.2_RANGER_CONTRACTS.md` — implemented Ranger Contracts design packet.
- `docs/PLAYTEST_0.4.0.md` — owner presentation/gameplay observations.

Generated `.rbxlx`, Studio recovery files, and local builds are not canonical source and must not be committed.

Item-transfer duels remain Studio-only pending a current Roblox publication-policy review. Progress remains session-only at the present development stage.
