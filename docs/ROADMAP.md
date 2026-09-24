# Egg Rivals Roadmap

## Current engineering candidate

**EGG-RIVALS-0.4.1-rc1 — SPRINT RIVALRY** is the current verified engineering candidate.

- Tested source commit: `25e300647b0c4ba38916f41452c7268d6bb6df76`
- Source digest: `84225f0b18b3886fa2d8a0cd0c2f8aa46b5438064b2fa3529a08b63cb6ab6a74`
- Exact-source multiplayer regression: **90 passed / 0 failed**
- Real Studio topology: one server + two clients
- Human Sprint feel/presentation review: **PENDING**
- Roblox publication: **NOT PERFORMED**
- Merge to `main`: **NOT AUTHORIZED**

The 0.4.0-rc2 86/86 Night/Forest candidate, rc1 77/77 candidate, and `MOONWOOD-0.3.2-r2` 24/24 baseline remain preserved historical references.

## 0.4.1 achieved mechanically

Engineering verification covers:

- explicit nearby Sprint challenge and accept/decline;
- shared server countdown and normalized WalkSpeed 45;
- shared Grove Circuit gate and anti-teleport validation;
- no Overdrive consumption or permanent-Speed advantage;
- racer collision-group fairness;
- first-valid-finish winner and DNF cleanup;
- real two-client physical route completion;
- session Sprint records;
- exact inventory preservation;
- no Sprint-specific Coin mutation while normal passive pet income continues;
- retained Trial/ghost, Night/Forest, trading, Exchange, ranch, Warden and duel regressions.

Exact evidence: `docs/STAGE3_041_VERIFICATION.md`.

## Current product gate

Mechanics-first development may continue, but human review remains separate. The owner should eventually evaluate challenge discoverability, countdown clarity, route readability, winner feedback and whether repeated Sprint races are actually fun.

## Next mechanics-first design target

**0.4.2 — Ranger Contracts + Session Mastery**

The goal is to give players a clear reason to rotate through systems that already exist rather than adding another zone.

Primary direction:

1. physical Ranger Station / Quest Board in the existing hub;
2. a small server-owned catalog of session contracts;
3. contracts reinforce training, Forest egg theft, hatching, Grove Circuit, Night and Sprint;
4. exact progress comes only from authoritative production events/state;
5. rewards use existing Coins only;
6. no new currency, persistence dependency, battle pass, daily-login timer or Robux power;
7. no contract requires public item wagering;
8. completion/reward is idempotent and cannot duplicate under repeated input.

Design packet: `docs/NEXT_SLICE_0.4.2_RANGER_CONTRACTS.md`.

## Later production gates

Persistence, broader zones, mobile/console support, additional creatures, deeper ranch customization, broader shop ecosystems, public policy-reviewed staking, monetization implementation, live operations and public Roblox release remain later work.

No feature branch merges to `main` until owner review explicitly authorizes it.
