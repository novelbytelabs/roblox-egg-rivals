# Egg Rivals — Speed Lab and Treadmill System

Status: approved design direction. Some numerical tier values remain unresolved; see `DECISION_LEDGER.md`.

The treadmill should become one of Egg Rivals' signature progression systems. It is the player's personal Speed Lab: a machine that visibly evolves, records mastery, creates tactical opportunities, and becomes a status object at the base.

## Permanent Speed versus avatar movement

The player's persistent Speed stat may grow to extremely large values.

Huge progression values must not map linearly to Roblox `WalkSpeed`. A bounded or diminishing-return movement function converts progression into controllable avatar speed.

Treadmill multipliers affect **Speed earned per second**, not literal movement multiplied by the same factor.

The user proposed an eventual Speed ceiling of 300 billion. Treat that value as an approved target direction, but do not bind final movement physics directly to it.

## Momentum training

Remaining on the treadmill builds a Momentum meter.

Momentum represents training efficiency and machine intensity. The treadmill visibly spools up:

- belt motion increases;
- sound pitch / intensity increases;
- air and particle effects strengthen;
- machine components animate;
- lights, vibration, and energy presentation increase.

Momentum reaches a cap. Leaving the machine causes it to fall or reset according to final tuning.
## Physical machine modules

Progress should not feel like pressing a generic "+2x" button.

Approved visible module families include:

- Motor;
- Belt;
- Cooling System;
- Stabilizers;
- Power Core;
- Control Unit.

Module upgrades should physically change the treadmill. A starter mechanical belt may eventually evolve into a highly advanced magnetic / energy-driven machine with turbines, illuminated rails, energy rings, and other visible technology.

The machine's final training multiplier is the aggregate result of its progression, not the only thing the player sees.

## Overdrive

Training can charge a temporary Overdrive resource.

The player leaves the treadmill with a stored burst that can be activated during gameplay. Its primary use is tactical acceleration during theft / escape.

Overdrive is earned through training, tying the base activity directly to the heist loop.

Overdrive should not permanently replace the value of the persistent Speed stat.
## Speed Mastery

Keep the main visible progression understandable: one primary Speed stat.

At meaningful milestones, the player can unlock movement mastery improvements rather than exposing a cluttered spreadsheet of sub-stats.

Approved mastery directions include:

- quicker acceleration;
- tighter high-speed turning;
- improved recovery after knockback / interruption;
- better jump control;
- longer or more efficient Overdrive.

These should improve control and expression, not create an unreadable number system.

## Training Trials

The Speed Lab can launch timed movement courses.

A trial sends the player through a sequence of glowing gates around the Meadow / Forest and back to the camp.

Trials measure actual movement execution rather than simply accumulated Speed.

Rewards can include machine cosmetics, effects, titles, records, and progression unlocks.
## Personal ghost racing

The game records a player's best Training Trial.

A transparent ghost reproduces the best route/time so the player can race their previous performance.

Later social extensions may include racing a friend's stored ghost even when that friend is not actively racing.

Ghost racing turns Speed into a mastery loop rather than pure idle accumulation.

## Elemental tuning

The Speed Lab may temporarily tune toward Fire, Water, Wind, or Earth.

This does **not** create four permanent Speed stats.

Approved directional identities:

- Fire: faster Overdrive build;
- Water: smoother acceleration / control;
- Wind: stronger top-end movement;
- Earth: better recovery / resistance to interruption.

These should remain tactical sidegrades and small identities, not mandatory elemental power tiers.
## Pet integration

The ranch should react to training.

The active pet can run, fly, or hover alongside the treadmill, sit nearby, or cheer.

Penned pets may gather at the fence or visibly react when the owner reaches a meaningful record or Speed milestone.

Pet reactions make training feel connected to the living ranch rather than isolated machinery.

## Milestone celebrations

Large Speed milestones should be events.

Candidate milestone scales include 100, 1K, 10K, 1M, 1B, and later large values appropriate to the final economy.

A milestone can trigger:

- machine effects;
- camp lighting changes;
- pet celebrations;
- badges / titles;
- cosmetic unlocks;
- record-board updates.

The exact milestones are tuning values.
## Machine grades

Progression should not require wiping the player's Speed.

Instead, the treadmill itself can earn visible Machine Grades, such as:

`Starter -> Performance -> Turbo -> Hyper -> Quantum`

Names remain tunable.

Higher grades unlock technology, presentation, trials, module capability, and training efficiency while preserving accumulated Speed.

## Heat and cooling

High Momentum can create visible heat / energy tension.

Better cooling lets the machine sustain maximum training efficiency longer.

Heat should be exciting visual feedback, **not** an annoying breakdown mechanic that destroys progress or forces maintenance chores.

## Social drafting

Nearby players training together can create a small social "draft" bonus.

The visual presentation can connect machines with wind / energy effects as more players train nearby.

The bonus should encourage congregation without making solo play nonviable.
## Sprint Challenges

Not all rivalry needs guns.

Players may issue a Sprint Challenge that uses a short course and category / normalized rules appropriate to the mode.

Possible rewards include:

- titles;
- trophies;
- coins;
- cosmetic records;
- non-staked recognition.

This provides competitive Speed expression separate from FPS duels.

## Motion Energy

Training can also generate a secondary temporary resource: Motion Energy.

Motion Energy powers camp presentation and interactive ranch machinery rather than replacing Money or permanent Speed.

Candidate uses include:

- camp lights;
- pet toys;
- fountains;
- habitat effects;
- celebration devices;
- cosmetic machinery.

The design idea is literal: running makes the player's home come alive.
## Personal machine records

The treadmill should remember the player.

A local machine display can show:

- Best Momentum;
- Top movement / training record;
- Total distance trained;
- Best Trial;
- Overdrives earned or used;
- notable milestone records.

Other players walking past the base should be able to recognize that the owner has an exceptional machine.

The long-term emotional target is similar to a customized car in a racing game: the treadmill itself becomes a prestige object.

## Economy values requiring final reconciliation

The user proposed the following upgrade values:

- 2x training: 100 coins;
- 4x training: 1,000 coins;
- 6x training: 10,000 coins;
- 8x training: typed as `25,0000` coins;
- 10x training: 100,000 coins.

The same discussion also described "maximum of 5x" while listing five upgrade levels ending at 10x.

Do **not** silently resolve those contradictions in implementation. The likely interpretation is five upgrade levels with a 10x maximum, but this remains an explicit clarification gate.
