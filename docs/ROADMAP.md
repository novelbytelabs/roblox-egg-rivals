# Egg Rivals Roadmap

## Current engineering candidate

**EGG-RIVALS-0.4.0-rc2** is the current verified engineering candidate.

- Tested source commit: `bc6ecffb62b13a2b50cfc029935e3decd6d597dc`
- Source digest: `cd3456d8f2dcaef01b967582d599ec426ecb41d6dd51d2044c01912a0ef87a7f`
- Exact-source multiplayer regression: **86 passed / 0 failed**
- Real Studio topology: one server + two clients
- Human presentation/gameplay recheck: **PENDING**
- Roblox publication: **NOT PERFORMED**
- Merge to `main`: **NOT AUTHORIZED**

The rc1 77/77 candidate and `MOONWOOD-0.3.2-r2` 24/24 baseline remain preserved as historical references.

## rc2 Night / Forest refinement

Engineering verification now covers:

- twelve Forest nest sites in the existing world footprint;
- one marked Godly Day nest with server-owned theft and 600-second replacement;
- broader shape-aware Night edge tracing;
- softer bloom tuning;
- longer/denser bounded particle trails;
- free personal flashlight on `L`;
- dawn cleanup and all retained rc1 invariants.

Appearance and tuning remain owner-playtest adjustable.

## Source-audit corrections

Several earlier “missing” labels were stale. Current source already contains:

- grade-driven treadmill module geometry;
- session machine records;
- Speed milestone effects and notifications;
- owner-homecoming behavior;
- ranch Idle/Wander/Rest/Play/Greet/Revere states;
- active-pet treadmill reaction;
- Night clue regions and Moon Shrine presentation.

These should be refined or extended rather than restarted.

## Next mechanics-first design target

**0.4.1 — Sprint Rivalry + Progression Feedback**

The first packet is [NEXT_SLICE_0.4.1_SPRINT_RIVALRY.md](NEXT_SLICE_0.4.1_SPRINT_RIVALRY.md).

Primary target:

1. two-player opt-in Sprint Challenge;
2. normalized movement at WalkSpeed 45;
3. existing Grove Circuit route and gate validation;
4. no stakes, Coins, premium rewards or new currency;
5. no Overdrive/pet/element movement advantage;
6. server-owned invitation, countdown, route validity, finish and winner;
7. session records exposed through the existing Speed Lab record surface.

This is deliberately narrower than a new zone or broad content expansion.

## Later production gates

Persistence, broader zones, mobile/console support, additional creatures, broader shop ecosystems, public policy-reviewed staking, monetization implementation, live operations and public Roblox release remain later work.

No feature branch merges to `main` until owner review explicitly authorizes it.
