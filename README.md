# Egg Rivals

Private canonical repository for Egg Rivals, a Roblox speed-heist, elemental-pet collection, living-ranch, social-economy, and opt-in rivalry game.

Current verified engineering candidate: `EGG-RIVALS-0.4.0-rc2`.

The exact-source rc2 candidate passed **86/86** checks in a real two-client Roblox Studio regression. Tested source commit: `bc6ecffb62b13a2b50cfc029935e3decd6d597dc`. Source digest: `cd3456d8f2dcaef01b967582d599ec426ecb41d6dd51d2044c01912a0ef87a7f`.

rc2 implements the owner-requested Night/Forest refinement: broader shape-aware neon edge tracing, softer bloom, longer/denser particle trails, a free personal flashlight, twelve Forest nests, and one marked Godly Day nest.

Human presentation/gameplay acceptance of the rc2 tuning remains pending. The prior rc1 77/77 candidate and `MOONWOOD-0.3.2-r2` 24/24 baseline remain preserved as historical evidence.

Core loop:

`train -> steal -> escape -> choose element -> hatch -> collect -> earn -> upgrade -> compete`

Canonical source is under `src/`. Rojo projects are `default.project.json` and `test.project.json`.

## Current direction

The owner reports that the game is adequate for this development stage and wants continued emphasis on **main mechanics and play** rather than polish closure.

The next mechanics design packet is `docs/NEXT_SLICE_0.4.1_SPRINT_RIVALRY.md`. It defines a normalized two-player Sprint Challenge using the existing Grove Circuit/Trial movement rules. It is a design packet, not yet an implemented or verified race system.

No merge to `main` or Roblox publication is authorized by engineering verification alone.

## Design documentation

Start with:

- `docs/GAME_DESIGN.md` — concise overview and document map.
- `docs/DESIGN_BIBLE.md` — canonical product identity and design pillars.
- `docs/DECISION_LEDGER.md` — approvals, superseded decisions, deferrals, and unresolved questions.
- `docs/FEATURE_STATUS_MATRIX.md` — implementation state versus approved aspirations.
- `docs/STAGE3_040_RC2_VERIFICATION.md` — exact rc2 engineering evidence.
- `docs/PLAYTEST_0.4.0.md` — owner presentation/gameplay observations.
- `docs/NIGHT_FOREST_REFINEMENT_0.4.0.md` — rc2 Night/Forest refinement contract.
- `docs/NEXT_SLICE_0.4.1_SPRINT_RIVALRY.md` — next mechanics-first design packet.
- `docs/NEXT_SLICE_0.4.0_LIVING_WORLD.md` — historical 0.4.0 Living World implementation plan.
- `docs/ASTRA_0.4.0_EXECUTION_PACKET.md` — historical 0.4.0 execution packet.

Generated `.rbxlx`, Studio recovery files, and local builds are not canonical source and must not be committed.

Item-transfer duels remain Studio-only pending a current Roblox publication-policy review. Progress remains session-only at the present development stage.
