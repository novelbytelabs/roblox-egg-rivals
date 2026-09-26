# Egg Rivals

Private canonical repository for Egg Rivals, a Roblox speed-heist, elemental-pet collection, living-ranch, social-economy, and opt-in rivalry game.

Current verified engineering candidate: `EGG-RIVALS-0.4.5-rc1`.

The exact-source 0.4.5 Visitor Ranch candidate passed **110/110** checks in a real two-client Roblox Studio regression. The 0.4.4 107/107 Social Drafting, 0.4.3 104/104 Elemental Tuning, 0.4.2 99/99 Ranger Contracts, 0.4.1 90/90 Sprint Rivalry, 0.4.0-rc2 86/86 Night/Forest and earlier baselines remain preserved historical evidence.

Current implementation queue:

- **0.4.6 Speed Mastery v1** — implemented on its repair branch; fresh exact-source Studio verification pending.
- **0.4.7 Living Ranch + Pet Activity** — implemented on its feature branch; fresh exact-source Studio verification pending. The owner is satisfied with current pen progress, so further pen-layout polish is not the active roadmap target.
- **0.4.8 Night Market v1** — implemented on `feature/0.4.8-night-market`; verification pending. It adds a physically closed-by-day Moonrise shop with bounded coarse search aids and no exact hidden-egg waypoint.

Core loop:

`train -> steal -> escape -> choose element -> hatch -> collect -> earn -> upgrade -> compete`

Canonical source is under `src/`. Rojo projects are `default.project.json` and `test.project.json`.

## Current direction

The owner wants continued emphasis on **main mechanics and play** rather than additional pen-layout polish.

The active verification queue is 0.4.6 Speed Mastery followed by 0.4.7 Living Ranch. GitHub-first feature development has resumed with 0.4.8 Night Market. After Night Market, the approved shop roadmap continues with Duel Armory, Pet Outfitter and Elemental Bazaar before later persistence, broader-world and production work.

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
- `docs/NEXT_SLICE_0.4.5_VISITOR_RANCH.md` — Visitor Ranch Interactions implementation candidate.
- `docs/STAGE3_043_VERIFICATION.md` — Elemental Tuning evidence.
- `docs/NEXT_SLICE_0.4.3_ELEMENTAL_TUNING.md` — implemented Elemental Tuning design packet.
- `docs/STAGE3_042_VERIFICATION.md` — Ranger Contracts evidence.
- `docs/NEXT_SLICE_0.4.2_RANGER_CONTRACTS.md` — implemented Ranger Contracts design packet.
- `docs/PLAYTEST_0.4.0.md` — owner presentation/gameplay observations.

Generated `.rbxlx`, Studio recovery files, and local builds are not canonical source and must not be committed.

Item-transfer duels remain Studio-only pending a current Roblox publication-policy review. Progress remains session-only at the present development stage.
