# Egg Rivals — Speed Lab and Treadmill System

Status: canonical design direction for 0.4.0 and beyond.

The treadmill is a signature progression machine, not a passive multiplier pad.

Canonical numerical rules now live in `ECONOMY_SPEED_RARITY_V2.md`.

The former 300-billion Speed target and 2x / 4x / 6x / 8x / 10x ladder are abolished.

## Core concepts

Egg Rivals exposes three understandable layers:

- **Speed** — permanent progression, currently 0..10,000;
- **Machine Grade** — the treadmill's capability tier;
- **Momentum** — temporary training performance while actively running.

Two supporting meters add tactical / presentation value:

- **Overdrive** — a stored movement burst earned by training;
- **Motion Energy** — temporary camp-power presentation energy.

This keeps the system deep without creating a wall of independent stats.

## Movement mapping

Permanent Speed is not Roblox `WalkSpeed`.

0.4.0 mapping:

`WalkSpeed = clamp(16 + 0.42 * sqrt(Speed), 16, 58)`

Overdrive may temporarily raise mapped movement, but never above 68 studs/s.
## Machine grades

Canonical 0.4.0 grades:

| Grade | Rate | Speed ceiling | Cost |
|---|---:|---:|---:|
| Starter | +1.00/s | 250 | Free |
| Boost | +1.50/s | 600 | 150 Coins |
| Turbo | +2.25/s | 1,200 | 650 Coins |
| Hyper | +3.25/s | 2,200 | 2,000 Coins |
| Flux | +4.50/s | 3,800 | 6,000 Coins |
| Quantum | +6.00/s | 6,000 | 18,000 Coins |
| Apex | +8.00/s | 10,000 | 55,000 Coins |

A player's Speed cannot train beyond the ceiling of the current grade.

Machine Grade never resets accumulated Speed.

## Physical machine progression

The treadmill visibly evolves through:

- Motor;
- Belt;
- Cooling System;
- Stabilizers;
- Power Core;
- Control Unit.

For 0.4.0, grade changes may drive the complete module appearance as one coherent machine upgrade.

Independent per-module purchase trees remain a future extension. Do not build a 30-upgrade component economy into 0.4.0.

The player should see substantial physical differences between Starter and Apex machinery.
## Momentum

Continuous training raises Momentum from 0% to 100% in 30 seconds.

Training efficiency interpolates from 1.00x to 1.75x.

Leaving the treadmill decays Momentum over 10 seconds.

Presentation strengthens with Momentum:

- belt speed;
- pitch / mechanical intensity;
- wind;
- particles;
- energy rings;
- machine lighting;
- pet reactions.

Heat is exciting presentation and a future tuning hook, not a breakdown punishment.

## Overdrive

Rules:

- 0..100 charge;
- full-Momentum charge rate: 2/s;
- proportional charge at lower Momentum;
- activation requires full charge;
- consumes full charge;
- lasts 5 seconds;
- adds 20% mapped movement;
- hard physical cap: 68 studs/s;
- allowed during open-world egg carrying;
- disabled in the duel arena;
- recharged only through treadmill training;
- survives ordinary death.

Overdrive directly connects training to theft/escape gameplay.
## Motion Energy

Motion Energy is a temporary 0..100 camp-power meter.

It starts charging once Momentum exceeds 75%.

At full training intensity it gains approximately 1.5 units/s.

It can power:

- camp lights;
- fountains;
- pet toys;
- habitat effects;
- celebration devices;
- cosmetic machinery.

It is not spendable Money and does not modify pet income or duel damage.

The emotional idea remains: **running makes the player's home come alive**.

## Training Trial

0.4.0 implements one polished timed course inside the existing Meadow / Forest footprint.

The course validates:

- start;
- ordered gates;
- finish;
- elapsed time;
- personal best.

Skipping or taking gates out of order invalidates the attempt.

The trial exists to test real movement execution instead of accumulated numbers alone.
## Personal ghost

A valid personal-best Training Trial stores replay data sufficient for a local translucent ghost.

The ghost:

- replays the best run;
- cannot collide;
- cannot trigger gates;
- cannot activate prompts;
- cannot affect world state.

Later friend-ghost support remains compatible.

## Elemental tuning

The approved concept remains, but it does not need to ship in 0.4.0 unless the core Speed Lab is already stable.

Elemental tuning is a treadmill mode, not a pet-stat bonus.

Directional identities:

- Fire — faster Overdrive charge;
- Water — smoother acceleration/control;
- Wind — stronger top-end movement feel;
- Earth — stronger recovery after interruption.

Any implementation must remain a tactical sidegrade rather than an objectively superior element.

## Pet integration

The active pet should react to training.

Approved behaviors include:

- running beside the treadmill;
- flying / hovering nearby;
- sitting and watching;
- cheering at a personal record;
- ranch residents reacting to milestone achievements.
## Milestones and machine records

The treadmill remembers meaningful player history.

Candidate records:

- Best Momentum;
- highest Speed reached;
- total training distance/time;
- best Trial time;
- Overdrives earned / used;
- major Speed milestones;
- current Machine Grade.

Milestone events may trigger:

- machine effects;
- ranch lighting;
- pet celebration;
- title / badge presentation;
- cosmetic unlocks.

Exact milestone values remain tuning parameters.

## Social drafting

Nearby players training together may receive a small social training bonus with connected wind/energy presentation.

The bonus must encourage congregation without making solo training nonviable.

This is approved design but is not required for the 0.4.0 acceptance gate unless added without destabilizing the slice.

## Sprint Challenges

0.4.0 normalized Sprint Challenges use:

- WalkSpeed 45;
- standard jump settings;
- no Overdrive;
- no pet/element movement bonus.

This makes Sprint Challenges a movement-skill contest.

An Open Class mode using actual permanent Speed is deferred.
## Design rules

- no rebirth / Speed wipe is required for machine progression;
- do not inflate numbers merely to imitate simulator conventions;
- do not directly multiply Roblox movement by treadmill upgrade factors;
- do not sell competitive movement power for Robux;
- keep permanent progression server-authoritative;
- keep visual effects client-efficient;
- preserve movement control at every progression tier.

The Speed Lab should feel like a customized racing machine whose performance and appearance communicate the owner's mastery.
