# Egg Rivals

Private canonical repository for Egg Rivals, a Roblox speed-heist, elemental-pet collection, living-ranch, social-economy, and opt-in rivalry game.

Current verified engineering candidate: `EGG-RIVALS-0.4.2-rc1`.

The exact-source 0.4.2 candidate passed **99/99** checks in a real two-client Roblox Studio regression. Tested source commit: `d0c14e6742b7cc14ddb4680a1fd9cd2dca5f7a1e`. Source digest: `87eaaa043f0dfae29585887fbd0bdf2dd8157fe6072c5052339c65c9dd29612c`.

0.4.2 retains the rc2 Night/Forest refinement and 0.4.1 Sprint Rivalry, then adds a physical Ranger Station with three server-owned session contracts, authoritative progress, and exact-once Coin claims.

Human contract UX, reward tuning and retention value remain separate owner-review gates. The prior 0.4.1 90/90, 0.4.0-rc2 86/86, rc1 77/77 and `MOONWOOD-0.3.2-r2` 24/24 candidates remain preserved historical evidence.

Core loop:

`train -> steal -> escape -> choose element -> hatch -> collect -> earn -> upgrade -> compete`

Canonical source is under `src/`. Rojo projects are `default.project.json` and `test.project.json`.

## Current direction

The owner wants continued emphasis on **main mechanics and play** rather than polish closure.

Ranger Contracts are engineering-verified. They now route players through training, Forest retrieval, hatching, Grove Circuit, Moonrise and Sprint without adding a new zone, persistence dependency or currency.

No merge to `main` or Roblox publication is authorized by engineering verification alone.

## Design documentation

Start with:

- `docs/GAME_DESIGN.md` — concise overview and document map.
- `docs/DESIGN_BIBLE.md` — canonical product identity and design pillars.
- `docs/DECISION_LEDGER.md` — approvals, superseded decisions, deferrals, and unresolved questions.
- `docs/FEATURE_STATUS_MATRIX.md` — implementation state versus approved aspirations.
- `docs/STAGE3_040_RC2_VERIFICATION.md` — Night/Forest refinement evidence.
- `docs/STAGE3_041_VERIFICATION.md` — Sprint Rivalry evidence.
- `docs/STAGE3_042_VERIFICATION.md` — Ranger Contracts evidence.
- `docs/NEXT_SLICE_0.4.2_RANGER_CONTRACTS.md` — implemented Ranger Contracts design packet.
- `docs/PLAYTEST_0.4.0.md` — owner presentation/gameplay observations.

Generated `.rbxlx`, Studio recovery files, and local builds are not canonical source and must not be committed.

Item-transfer duels remain Studio-only pending a current Roblox publication-policy review. Progress remains session-only at the present development stage.
