# Egg Rivals — Economy, Speed, and Rarity v2

Status: canonical replacement for the earlier huge-number treadmill and provisional rarity economy.

This specification deliberately abolishes the earlier 300-billion Speed target, the ambiguous 5x/10x treadmill ladder, and the typed coin values attached to it.

## Speed v2

Launch-era permanent Speed range:

`0 .. 10,000`

This is a progression stat, not Roblox `WalkSpeed`.

Avatar movement uses:

`WalkSpeed = clamp(16 + 0.42 * sqrt(Speed), 16, 58)`

This gives large visible progression while preserving controllable movement.

The 10,000 ceiling is the 0.4.0 / launch-era cap, not a claim that Egg Rivals can never extend progression later.

## Speed Lab grades

| Grade | Training rate | Speed ceiling | Upgrade cost |
|---|---:|---:|---:|
| Starter | +1.00 Speed/s | 250 | Free |
| Boost | +1.50 Speed/s | 600 | 150 Coins |
| Turbo | +2.25 Speed/s | 1,200 | 650 Coins |
| Hyper | +3.25 Speed/s | 2,200 | 2,000 Coins |
| Flux | +4.50 Speed/s | 3,800 | 6,000 Coins |
| Quantum | +6.00 Speed/s | 6,000 | 18,000 Coins |
| Apex | +8.00 Speed/s | 10,000 | 55,000 Coins |

The grade ceiling prevents a low-grade treadmill from training indefinitely to endgame capability.
## Momentum

Continuous training ramps Momentum from 0% to 100% over 30 seconds.

Momentum multiplies the grade training rate from 1.00x at zero Momentum to 1.75x at full Momentum.

Leaving the treadmill causes Momentum to decay over 10 seconds rather than instantly vanish.

Heat remains visual / efficiency feedback. It does not break the treadmill or delete progress.

## Overdrive

Training also charges one tactical Overdrive meter.

Rules for 0.4.0:

- charge range: 0..100;
- full-Momentum charge rate: 2 charge/s;
- lower Momentum charges proportionally;
- activation consumes 100 charge;
- duration: 5 seconds;
- movement increase: +20% over current mapped movement;
- absolute movement cap while active: 68 studs/s;
- allowed while carrying an open-world egg;
- disabled inside the duel arena;
- recharges only through treadmill training;
- death does not erase stored charge.

Overdrive is tactical escape capability, not a second permanent Speed stat.
## Motion Energy

Motion Energy is a temporary camp-power meter, not a spendable currency.

Rules:

- range: 0..100;
- begins charging once Momentum exceeds 75%;
- full-rate charge: 1.5 units/s;
- powers cosmetic camp systems such as lights, fountains, pet toys, habitat effects, and celebration devices;
- it does not buy items or increase duel damage;
- 0.4.0 may consume / decay it only for presentation;
- persistence is not required for this slice.

This preserves the idea that the player's running literally makes the camp come alive without creating another economy.

## Rarity ladder

Canonical standard rarity:

`Common -> Uncommon -> Rare -> Epic -> Legendary -> Mythic -> Godly`

Any base creature can occur at any standard rarity.

Creature, rarity, and element are independent properties.

A Godly Skunk is as structurally valid as a Godly Dragon.
## Daytime rarity weights

Initial 0.4.0 tuning:

| Rarity | Weight |
|---|---:|
| Common | 48.00% |
| Uncommon | 28.00% |
| Rare | 14.00% |
| Epic | 7.00% |
| Legendary | 2.40% |
| Mythic | 0.55% |
| Godly | 0.05% |

Weights sum to 100%.

Godly is therefore approximately 1 in 2,000 ordinary daytime egg rolls before zone-specific modifiers.

No shop sells a Godly pet directly.

## Hidden Night egg rarity

The single hidden Night egg uses:

| Rarity | Weight |
|---|---:|
| Legendary | 80% |
| Mythic | 19% |
| Godly | 1% |

Creature is selected independently from the current creature pool.

The Night egg remains valuable without making Godly routine.
## Hatch times

Initial 0.4.0 base durations:

| Rarity | Hatch time |
|---|---:|
| Common | 20 seconds |
| Uncommon | 45 seconds |
| Rare | 2 minutes |
| Epic | 5 minutes |
| Legendary | 15 minutes |
| Mythic | 45 minutes |
| Godly | 120 minutes |

Night applies the existing 30x incubation-rate acceleration while Night is active.

The timer resumes ordinary speed when Night ends.

## Passive pet income

All owned pets continue generating income whether active, penned, or currently not on the visible pen page.

Initial income:

| Rarity | Coins / minute |
|---|---:|
| Common | 6 |
| Uncommon | 15 |
| Rare | 40 |
| Epic | 100 |
| Legendary | 275 |
| Mythic | 750 |
| Godly | 2,500 |

Server income uses an accumulator so payouts can remain integer Coins without losing fractional earnings between payout ticks.
## Core currency

0.4.0 uses **Coins as the single progression currency**.

Do not introduce a second mandatory progression currency in this slice.

Cosmetic / event currencies may be considered later only if they solve a demonstrated design problem.

## Exchange valuation

The Exchange returns Coins.

For pets:

`ExchangeValue = 8 * CoinsPerMinute`

For unhatched eggs:

`EggExchangeValue = floor(0.60 * equivalent pet ExchangeValue)`

Examples:

- Common pet: 48 Coins;
- Rare pet: 320 Coins;
- Epic pet: 800 Coins;
- Godly pet: 20,000 Coins.

Other item categories use explicit fixed values.

The Exchange is intentionally a sink / cleanup option, not the best way to maximize collection value.
## Exchange safety

An item cannot be exchanged while:

- Favorite / Locked;
- carried;
- incubating;
- in trade;
- in duel escrow;
- otherwise server-reserved.

An active companion must be sent to the pen before exchange.

Godly exchange requires a separate five-second hold confirmation showing the exact pet.

## Speed economy rationale

Coin prices are now tied to the pet-income economy rather than arbitrary large simulator numbers.

The intended early rhythm is:

- first Speed Lab upgrade within minutes after obtaining early pets;
- mid grades require a meaningful but reachable collection;
- Quantum and Apex are goals supported by stronger collections, not tutorial purchases.

Prices remain tuning parameters, but the architecture and order are now resolved.
