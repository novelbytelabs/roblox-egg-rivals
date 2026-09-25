# Egg Rivals 0.4.4 — Social Drafting v1

Status: **ENGINEERING VERIFIED — 107/107 EXACT-SOURCE REGRESSION; OWNER SOCIAL FEEL REVIEW PENDING**

Purpose: make simultaneous Speed Lab training mildly social without creating a new currency, zone, party system, or dependency on persistent progression.


## Implementation / verification status

The bounded implementation is present and engineering-verified. The final exact-source candidate passed **107/107** checks with one real Studio server and two real clients.

The verified implementation uses server-derived, non-stacking +10% permanent-Speed gain for simultaneously training players whose own treadmill centers are within 50 studs. It does not alter Momentum, Overdrive, Motion Energy, Coins, pet income, Ranger rewards, Trial/Sprint normalization or inventory authority.

Exact evidence: `STAGE3_044_VERIFICATION.md` and `tests/engine-20260925T021744179535Z.json`.

Owner judgment of the +10% value, 50-stud range, presentation and whether Drafting makes training more socially enjoyable remains separate from engineering verification.

## Existing design authority

The canonical Speed Lab specification approves a small social training bonus for nearby players training together and requires solo training to remain viable.

The current camp geometry places adjacent treadmill centers 42 studs apart. 0.4.4 therefore uses the actual world geometry rather than an arbitrary global grouping rule.

## Core rule

A player receives **Social Drafting** while:

- actively training on their own treadmill;
- at least one other eligible player is simultaneously training on their own treadmill;
- the two treadmill centers are within 50 studs.

The v1 bonus is **+10% permanent-Speed training gain**.

The bonus is boolean and non-stacking. Two or three nearby partners do not create +20% or +30%.

The 50-stud radius and 10% bonus are initial tuning parameters, not immutable lore.

## Authority and exclusions

The server derives drafting from authoritative player/training state. The client never declares a partner or multiplier.

Drafting changes only permanent-Speed gain while valid training is active.

It does not modify Momentum, Overdrive charge/rules, Motion Energy, grade caps/prices, Coins, pet income, Ranger rewards, egg systems, Duel movement/damage, Training Trial normalization, Sprint normalization, inventory, trade or Exchange authority.

Elemental Tuning and Social Drafting compose cleanly: tuning controls its documented Momentum/Overdrive behavior; drafting applies only to permanent-Speed gain.

## Presentation minimum

The Speed Lab console exposes DRAFT +10% while active. The Trainer panel exposes the current bonus. Client belt-stripe motion accelerates slightly as presentation only.

## Verification requirements

- solo training does not draft;
- two real adjacent trainers draft symmetrically;
- drafting ends when either partner stops;
- the bonus is exactly one non-stacking multiplier;
- activation alone does not mutate Coins, pet income, Momentum, Overdrive charge or Motion Energy;
- snapshot and treadmill attributes expose drafting state;
- all existing 104 checks remain green.

Final engineering acceptance requires formatted source, PLAY/TEST builds, exact gameplay-script byte identity and a fresh one-server/two-client Studio suite with zero failures.

## Out of scope

Parties, matchmaking, group currencies, persistent social bonuses, stacking tiers, cross-zone drafting, Robux boosts, pet-derived social bonuses and Open-Class racing bonuses are excluded.

## Claim boundary

This packet began as the 0.4.4 implementation target. The bounded mechanics are now engineering-verified at 107/107. The +10% value, 50-stud range, visual feedback and social motivation remain owner-review claims.
