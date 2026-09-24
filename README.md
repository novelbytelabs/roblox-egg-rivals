# Egg Rivals

Private canonical repository for Egg Rivals, a Roblox speed-heist, elemental-pet collection, living-ranch, social-economy, and opt-in rivalry game.

Current verified engineering candidate: `EGG-RIVALS-0.4.1-rc1`.

The exact-source 0.4.1 candidate passed **90/90** checks in a real two-client Roblox Studio regression. Tested source commit: `25e300647b0c4ba38916f41452c7268d6bb6df76`. Source digest: `84225f0b18b3886fa2d8a0cd0c2f8aa46b5438064b2fa3529a08b63cb6ab6a74`.

0.4.1 retains the rc2 Night/Forest refinement and adds normalized two-player Sprint Rivalry with session records and no race stakes or race currency.

Human presentation/gameplay acceptance remains separate. The prior rc2 86/86, rc1 77/77 and `MOONWOOD-0.3.2-r2` 24/24 candidates remain preserved historical evidence.

Core loop:

`train -> steal -> escape -> choose element -> hatch -> collect -> earn -> upgrade -> compete`

Canonical source is under `src/`. Rojo projects are `default.project.json` and `test.project.json`.

## Current direction

The owner reports that the game is adequate for this development stage and wants continued emphasis on **main mechanics and play** rather than polish closure.

Sprint Rivalry is now engineering-verified. The next mechanics design packet is `docs/NEXT_SLICE_0.4.2_RANGER_CONTRACTS.md`, which uses session contracts to reinforce existing core systems without adding a new zone or currency.

No merge to `main` or Roblox publication is authorized by engineering verification alone.

## Design documentation

Start with:

- `docs/GAME_DESIGN.md` — concise overview and document map.
- `docs/DESIGN_BIBLE.md` — canonical product identity and design pillars.
- `docs/DECISION_LEDGER.md` — approvals, superseded decisions, deferrals, and unresolved questions.
- `docs/FEATURE_STATUS_MATRIX.md` — implementation state versus approved aspirations.
- `docs/STAGE3_040_RC2_VERIFICATION.md` — exact rc2 engineering evidence.
- `docs/STAGE3_041_VERIFICATION.md` — exact Sprint Rivalry engineering evidence.
- `docs/PLAYTEST_0.4.0.md` — owner presentation/gameplay observations.
- `docs/NIGHT_FOREST_REFINEMENT_0.4.0.md` — rc2 Night/Forest refinement contract.
- `docs/NEXT_SLICE_0.4.1_SPRINT_RIVALRY.md` — implemented Sprint Rivalry design packet.
- `docs/NEXT_SLICE_0.4.2_RANGER_CONTRACTS.md` — next mechanics-first design packet.
- `docs/NEXT_SLICE_0.4.0_LIVING_WORLD.md` — historical 0.4.0 Living World implementation plan.
- `docs/ASTRA_0.4.0_EXECUTION_PACKET.md` — historical 0.4.0 execution packet.

Generated `.rbxlx`, Studio recovery files, and local builds are not canonical source and must not be committed.

Item-transfer duels remain Studio-only pending a current Roblox publication-policy review. Progress remains session-only at the present development stage.
