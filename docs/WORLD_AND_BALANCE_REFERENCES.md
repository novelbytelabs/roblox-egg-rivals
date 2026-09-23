> Historical reference only. The earlier 300-billion Speed target and multiplier ladders are abolished. Current rules are in ECONOMY_SPEED_RARITY_V2.md.

# Egg Rivals — World and Balance References

Status: historical approved baselines and compatible future direction. These values are **not** stronger than later decisions in `DECISION_LEDGER.md`.

This file preserves useful numbers from earlier design work so they are not lost while preventing them from silently overriding newer decisions.

## Zone progression reference

Earlier approved world direction:

| Order | Zone | Recommended Speed | Primary rarity direction |
|---:|---|---:|---|
| 0 | Meadow Hub | 0 | Common |
| 1 | Forest | 100 | Common–Uncommon |
| 2 | Lake | 250 | Uncommon–Rare |
| 3 | Desert | 500 | Rare–Epic |
| 4 | Jungle | 900 | Rare–Legendary |
| 5 | Arctic | 1,600 | Epic–Legendary |
| 6 | Volcano | 2,600 | Legendary–Mythic |
| 7 | Later endgame / special area | post-MVP | upper-tier / event content |

These are recommended Speed values, not hard entry gates.

The current vertical slice intentionally focuses on Meadow + Forest. The larger world is later work.

The old `Secret/Void` naming and Secret rarity relationship are not current canon because Godly now tops the standard rarity ladder.
## Earlier daytime rarity weighting

Historical tuning baseline:

| Rarity | Weight |
|---|---:|
| Common | 45% |
| Uncommon | 28% |
| Rare | 15% |
| Epic | 8% |
| Legendary | 3% |
| Mythic | 0.9% |
| Secret | 0.1% |

This table predates Godly.

Do **not** use it unchanged for production. It is preserved as a reference for the shape of the earlier rarity curve.

A new distribution should explicitly include Godly and the revised Night system before implementation.

## Earlier hatch-duration reference

Previously discussed ranges:

- Common: about 20 seconds to 2 minutes;
- Uncommon: about 2–5 minutes;
- Rare: about 5–10 minutes;
- Epic: about 10–30 minutes;
- Legendary: approximately 2 hours 30 minutes;
- Mythic: approximately 2 hours 30 minutes;
- Godly: not yet locked.

The 20-second early hatch experience remains a useful onboarding reference.
## Earlier rarity-income reference

Historical pet-income multipliers:

- Common: 1x
- Uncommon: 2x
- Rare: 5x
- Epic: 12x
- Legendary: 35x
- Mythic: 80x
- former Secret: 200x+

These are balance references only.

Godly now replaces Secret as the top standard rarity, but its final income relationship is unresolved.

## Earlier treadmill ladder

Historical Stage-1 baseline:

- Starter: +1 Speed/sec, free;
- Bronze: +2, 100 Money;
- Silver: +4, 750 Money;
- Gold: +8, 5,000 Money;
- Plasma: +16, 30,000 Money;
- Hyper: +32, 175,000 Money.

This simple ladder is superseded by the approved Speed Lab system and newer owner-provided multiplier proposal.

Keep it only as evidence of earlier pacing assumptions.
## Earlier Night spawn reference

An earlier Night concept used:

- at least one high-value event egg;
- approximately 80% Legendary / 20% Mythic special-spawn mix.

The newer rule supersedes the fixed known-spawn model:

- normal daytime eggs cannot be taken during Night;
- exactly one special high-value Night egg is hidden somewhere from a curated random-location set;
- its final rarity distribution, including possible Godly participation, remains open.

The 30x incubation acceleration remains approved.

## Balance governance

Whenever later testing changes a number:

1. record the current value in the relevant canonical system document;
2. keep historically useful old values here if they explain prior tests;
3. never represent an old benchmark as current design;
4. distinguish economy tuning from architectural rules.

The goal is traceability without design drift.
