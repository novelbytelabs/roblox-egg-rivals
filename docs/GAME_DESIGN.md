# Egg Rivals — Game Design Overview

Status: canonical overview. Detailed system specifications linked below carry equal design authority; the Decision Ledger resolves conflicts by latest explicit owner decision.

Egg Rivals combines speed progression, defended egg theft, elemental hatching, collectible living pets, personal ranches, social trading/economy, open-world interference, and optional skill rivalry.

Core progression:

`train -> steal -> escape -> choose element -> hatch -> collect -> earn -> upgrade -> explore`

Core competitive loops:

`challenge -> choose exact offers -> confirm -> duel -> resolve ownership`

`challenge -> normalized sprint -> ordered gates -> finish -> session record`

Standard rarity:

`Common -> Uncommon -> Rare -> Epic -> Legendary -> Mythic -> Godly`

Four elements:

`Fire • Water • Wind • Earth`

Current vertical-slice creatures:

`Skunk • Lizard • Gorilla • Dragon`

The egg determines creature identity. The incubator determines elemental form. Rarity is independent of both.

## Current engineering state

`EGG-RIVALS-0.4.0-rc2` is the current verified engineering candidate.

It passed **86/86** exact-source checks in a real two-client Roblox Studio regression. Tested source commit: `bc6ecffb62b13a2b50cfc029935e3decd6d597dc`. Source digest: `cd3456d8f2dcaef01b967582d599ec426ecb41d6dd51d2044c01912a0ef87a7f`.

rc2 retains the full 0.4.0 Living World mechanics and adds the owner-directed Night/Forest refinement. Engineering verification establishes the tested mechanics, not owner acceptance of appearance, pacing, fun, or tuning.

The source audit also corrected several stale “not implemented” labels. Current source already contains grade-driven treadmill modules, session machine records, Speed milestone events, owner-homecoming behavior, autonomous ranch states, Night clue regions, and Moon Shrine presentation paths.

## Current design direction

The owner wants mechanics-first continuation. The next bounded design target is a normalized two-player Sprint Challenge that reuses the existing validated Grove Circuit movement/gate system.

The design goals are:

- opt-in two-player movement rivalry;
- equal `45` WalkSpeed and standard jump settings;
- no Overdrive, pet bonus, element bonus, item stakes, or economic reward;
- server-owned countdown, gate order, finish, timeout and winner;
- reuse of existing anti-teleport/discontinuous-movement validation;
- session-only records and visible progression feedback;
- no new zone, currency, persistence system, or public-wagering dependency.

See [0.4.1 Sprint Rivalry](NEXT_SLICE_0.4.1_SPRINT_RIVALRY.md).

## Canonical detailed specifications

- [Design Bible](DESIGN_BIBLE.md)
- [Core Gameplay](CORE_GAMEPLAY.md)
- [Base, Incubators, and Respawn](BASE_INCUBATION_RESPAWN.md)
- [Pet Pen and Ranch](PET_PEN_SYSTEM.md)
- [Speed Lab and Treadmill](SPEED_LAB_SYSTEM.md)
- [Night System](NIGHT_SYSTEM.md)
- [Hub Shops and Social Economy](HUB_SHOPS_AND_SOCIAL_ECONOMY.md)
- [PvP and Duels](PVP_AND_DUELS.md)
- [Production Guardrails](PRODUCTION_GUARDRAILS.md)
- [Decision Ledger](DECISION_LEDGER.md)
- [Feature Status Matrix](FEATURE_STATUS_MATRIX.md)
- [rc2 Engineering Verification](STAGE3_040_RC2_VERIFICATION.md)
- [Owner Playtest](PLAYTEST_0.4.0.md)
- [0.4.1 Sprint Rivalry](NEXT_SLICE_0.4.1_SPRINT_RIVALRY.md)

## Design discipline

The latest explicit owner decision overrides earlier conflicting ideas.

Starter experiences should already be enjoyable. Progression adds expression, capability, mastery, spectacle, organization, or social value.

New systems should reinforce the Egg Rivals loop rather than become disconnected chores. Existing tested services should be extended or reused when they already own the required authority.
