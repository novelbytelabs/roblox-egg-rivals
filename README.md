# Egg Rivals

Private canonical repository for Egg Rivals, a Roblox speed-heist, elemental-pet collection, living-ranch, social-economy, and opt-in rivalry game.

Current verified engineering candidate: `EGG-RIVALS-0.4.4-rc1`.

The exact-source 0.4.4 candidate passed **107/107** checks in a real two-client Roblox Studio regression. The exact tested source bytes are committed at `301448dd7cf9a8fda748d4c14b585615f170d30d`. Source digest: `be7aaa66d706a1fa86dfe0a2ad7a277ee69a80934688719bb7a1a430a7ce70d8`.

0.4.4 retains the Night/Forest refinement, Sprint Rivalry, Ranger Contracts and Elemental Tuning, then adds server-owned Social Drafting: a bounded non-stacking +10% permanent-Speed training bonus for nearby simultaneous trainers.

Human Social Drafting feel/tuning remains a separate owner-review gate. The prior 0.4.3 104/104, 0.4.2 99/99, 0.4.1 90/90, 0.4.0-rc2 86/86, rc1 77/77 and `MOONWOOD-0.3.2-r2` 24/24 candidates remain preserved historical evidence.

Core loop:

`train -> steal -> escape -> choose element -> hatch -> collect -> earn -> upgrade -> compete`

Canonical source is under `src/`. Rojo projects are `default.project.json` and `test.project.json`.

## Current direction

The owner wants continued emphasis on **main mechanics and play** rather than polish closure.

Social Drafting v1 is engineering-verified. It adds a mild cooperative training incentive while preserving solo viability, Elemental Tuning, normalized Trial/Sprint movement and existing economy/inventory authority.

No merge to `main` or Roblox publication is authorized by engineering verification alone.

## Design documentation

Start with:

- `docs/GAME_DESIGN.md` — concise overview and document map.
- `docs/DESIGN_BIBLE.md` — canonical product identity and design pillars.
- `docs/DECISION_LEDGER.md` — approvals, superseded decisions, deferrals, and unresolved questions.
- `docs/FEATURE_STATUS_MATRIX.md` — implementation state versus approved aspirations.
- `docs/STAGE3_040_RC2_VERIFICATION.md` — Night/Forest refinement evidence.
- `docs/STAGE3_041_VERIFICATION.md` — Sprint Rivalry evidence.
- `docs/STAGE3_044_VERIFICATION.md` — Social Drafting evidence.
- `docs/NEXT_SLICE_0.4.4_SOCIAL_DRAFTING.md` — implemented Social Drafting design packet.
- `docs/STAGE3_043_VERIFICATION.md` — Elemental Tuning evidence.
- `docs/NEXT_SLICE_0.4.3_ELEMENTAL_TUNING.md` — implemented Elemental Tuning design packet.
- `docs/STAGE3_042_VERIFICATION.md` — Ranger Contracts evidence.
- `docs/NEXT_SLICE_0.4.2_RANGER_CONTRACTS.md` — implemented Ranger Contracts design packet.
- `docs/PLAYTEST_0.4.0.md` — owner presentation/gameplay observations.

Generated `.rbxlx`, Studio recovery files, and local builds are not canonical source and must not be committed.

Item-transfer duels remain Studio-only pending a current Roblox publication-policy review. Progress remains session-only at the present development stage.
