# Egg Rivals Roadmap

## Current engineering candidate

**EGG-RIVALS-0.4.4-rc1 — SOCIAL DRAFTING v1** is the current verified engineering candidate.

- Exact tested source bytes committed at: `301448dd7cf9a8fda748d4c14b585615f170d30d`
- Source digest: `be7aaa66d706a1fa86dfe0a2ad7a277ee69a80934688719bb7a1a430a7ce70d8`
- Exact-source multiplayer regression: **107 passed / 0 failed**
- Real Studio topology: one server + two clients
- PLAY/TEST gameplay scripts: **38 byte-identical**
- Human Social Drafting feel/tuning review: **PENDING**
- Roblox publication: **NOT PERFORMED**
- Merge to `main`: **NOT AUTHORIZED**

The 0.4.3 104/104 Elemental Tuning, 0.4.2 99/99 Ranger, 0.4.1 90/90 Sprint, 0.4.0-rc2 86/86 Night/Forest, rc1 77/77 and `MOONWOOD-0.3.2-r2` 24/24 results remain preserved historical references.

## 0.4.4 achieved mechanically

Engineering verification covers:

- server-derived Social Drafting from real simultaneous treadmill training;
- adjacent-camp geometry within a 50-stud Drafting radius;
- +10% permanent-Speed gain while Drafting;
- boolean, non-stacking semantics;
- symmetric activation and deterministic deactivation when a partner stops;
- no mutation of Momentum, Overdrive charge/rules, Motion Energy, Coins, pet income, Ranger rewards, inventory or competitive movement normalization;
- Drafting state exposed through Speed Lab snapshot, treadmill attributes and presentation;
- clean composition with Elemental Tuning;
- all retained Ranger, Sprint, Night/Forest, trading, Exchange, ranch, Warden, incubation, duel and Trial regressions.

Exact evidence: `docs/STAGE3_044_VERIFICATION.md`.

## Current product gate

Mechanics-first development may continue, while owner feel review remains separate. Eventually evaluate:

1. whether +10% is noticeable without making solo training feel inferior;
2. whether 50 studs communicates the intended adjacent-camp social behavior;
3. whether DRAFT +10% is understandable at a glance;
4. whether players naturally choose to train together;
5. whether Elemental Tuning and Drafting together remain legible.

## Next mechanics-first design target

The most coherent approved gap is **richer ranch interaction and visitor mechanics**.

A bounded 0.4.5 design should deepen the existing social loop—visit a ranch, inspect pets, react harmlessly, and enter existing trade interactions—without adding ownership authority, currency, persistence, feeding chores or a new zone.

Speed Mastery remains approved but too underspecified to implement without first defining its control-focused unlocks.

## Later production gates

Persistence, broader zones, mobile/console support, deeper shop ecosystems, additional creatures, public policy-reviewed staking, monetization implementation, broader live operations and public Roblox release remain later work.

No feature branch merges to `main` until owner review explicitly authorizes it.
