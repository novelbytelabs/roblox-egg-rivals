# Egg Rivals Roadmap

## Current engineering candidate

**EGG-RIVALS-0.4.2-rc1 — RANGER CONTRACTS + SESSION MASTERY** is the current verified engineering candidate.

- Tested source commit: `d0c14e6742b7cc14ddb4680a1fd9cd2dca5f7a1e`
- Source digest: `87eaaa043f0dfae29585887fbd0bdf2dd8157fe6072c5052339c65c9dd29612c`
- Exact-source multiplayer regression: **99 passed / 0 failed**
- Real Studio topology: one server + two clients
- Human Contract Board / reward / retention review: **PENDING**
- Roblox publication: **NOT PERFORMED**
- Merge to `main`: **NOT AUTHORIZED**

The 0.4.1 90/90 Sprint candidate, 0.4.0-rc2 86/86 Night/Forest candidate, rc1 77/77 candidate and `MOONWOOD-0.3.2-r2` 24/24 baseline remain preserved historical references.

## 0.4.2 achieved mechanically

Engineering verification covers:

- a physical Ranger Station / Contract Board in the existing hub;
- exactly three varied server-owned session contracts per player;
- authoritative progress from Speed Lab training, Forest retrieval, real hatching, solo Trial completion, hidden-Night retrieval and Sprint completion;
- no client-supplied progress, targets or reward amounts;
- existing Coins only;
- separate COMPLETE and CLAIMED states;
- early, stale, unknown and duplicate claim rejection;
- Coin-ceiling failure that preserves the unclaimed reward;
- exact-once real client claim from the rendered contract row;
- session cleanup/reconstruction;
- all retained Sprint, Night/Forest, trading, Exchange, ranch, Warden, incubation, duel and Trial regressions.

Exact evidence: `docs/STAGE3_042_VERIFICATION.md`.

## Current product gate

Mechanics-first development may continue, but owner review remains separate. The owner should eventually evaluate:

1. whether the Ranger Station answers “what should I do next?”;
2. whether three contracts feel varied rather than chore-like;
3. whether Coin rewards are meaningful without overpowering pet income;
4. whether contract completion/claim feedback is readable;
5. whether contracts increase rotation through existing systems and replay desire.

## Mechanics backlog

Approved mechanics still available for future slices include:

- elemental treadmill tuning;
- Speed Mastery / control-focused unlocks;
- social drafting;
- richer ranch interaction and visitor mechanics;
- deeper shop ecosystems;
- additional creatures and later zones;
- persistence when the project reaches MVP scope.

The next slice should deepen the central game rather than add disconnected systems.

## Later production gates

Persistence, broader zones, mobile/console support, public policy-reviewed staking, monetization implementation, broader live operations and public Roblox release remain later work.

No feature branch merges to `main` until owner review explicitly authorizes it.
