# Egg Rivals 0.4.3 — Elemental Tuning v1

Status: **IMPLEMENTATION CANDIDATE — VERIFICATION PENDING**

Purpose: deepen the signature Speed Lab without adding a new currency, zone, persistence requirement or pet-stat power system.

## Scope decision

The canonical Speed Lab specification already defines elemental treadmill tuning. The feature-status matrix also names “Speed Mastery,” but its actual mechanics are not defined tightly enough to implement without inventing new product law.

Therefore 0.4.3 implements **Elemental Tuning v1 only**. Speed Mastery remains approved-but-undefined future design work.

## Core rule

Elemental tuning is a **free server-owned treadmill mode**.

It is not derived from the active pet. It does not change pet income, egg rarity, permanent Speed caps, grade prices, duel damage, Sprint normalization, Training Trial normalization or inventory/economy authority.

The verified Standard mode remains available and preserves the existing Speed Lab baseline exactly.

## Modes

| Mode | Benefit | Tradeoff |
|---|---|---|
| Standard | Existing balanced baseline | None |
| Fire | Faster Overdrive charge | Slower Momentum build |
| Water | Faster Momentum build | Slower Overdrive charge |
| Wind | Stronger open-world Overdrive burst | Shorter burst and slower charge |
| Earth | Momentum persists longer after interruption | Slower Overdrive charge |

Initial tuning values are implementation parameters, not immutable lore.

## Switching rule

Players may switch mode only at their own Speed Lab or Trainer Workshop.

Switching is free but requires:

- no active duel, trade, Exchange, Trial, Sprint or incubation confirmation;
- Momentum approximately zero;
- Overdrive charge approximately zero;
- no active Overdrive burst.

This prevents charging under one mode and immediately cherry-picking another mode for its burst/recovery benefit.

## Competitive boundary

Elemental tuning applies to ordinary Speed Lab training and open-world Overdrive only.

- Training Trial remains normalized at WalkSpeed 45.
- Sprint Challenge remains normalized at WalkSpeed 45.
- Duel movement remains governed by duel rules.
- The existing 68 studs/s Overdrive hard cap remains absolute.
- No tuning may be purchased for Robux or Coins.

## Verification requirements

Directly verify:

- Standard reproduces current baseline values;
- every tuning is a bounded sidegrade with its documented tradeoff;
- invalid/stale tuning identities fail closed;
- selection is free and does not mutate Coins, inventory or pet income;
- switching cannot occur with stored Momentum, stored Overdrive charge or an active burst;
- Wind cannot exceed the 68 studs/s cap;
- Trial and Sprint movement ignore tuning;
- one real client uses the rendered Trainer UI to select an exact mode;
- all existing 99 checks remain green.

Final engineering acceptance requires a fresh exact-source one-server/two-client Studio run with zero failures and exact PLAY/TEST script-byte identity.

## Out of scope

Speed Mastery unlock trees, elemental pets granting movement bonuses, tuning purchases, tuning persistence, tuning-specific race classes, new machine component economies, new currencies and additional zones are excluded.

## Claim boundary

This packet defines the 0.4.3 implementation candidate. It does not claim Elemental Tuning is verified or fun until fresh engine and owner evidence exists.
