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

`EGG-RIVALS-0.4.1-rc1` is the current verified engineering candidate.

It passed **90/90** exact-source checks in a real two-client Roblox Studio regression. Tested source commit: `25e300647b0c4ba38916f41452c7268d6bb6df76`. Source digest: `84225f0b18b3886fa2d8a0cd0c2f8aa46b5438064b2fa3529a08b63cb6ab6a74`.

0.4.1 retains the full verified Night/Forest refinement and adds normalized two-player Sprint Rivalry using the shared Grove Circuit route validator. Engineering verification establishes tested mechanics, not owner acceptance of appearance, pacing, fun, or tuning.

The source audit also corrected several stale “not implemented” labels. Current source already contains grade-driven treadmill modules, session machine records, Speed milestone events, owner-homecoming behavior, autonomous ranch states, Night clue regions, and Moon Shrine presentation paths.

## Current design direction

Sprint Rivalry is now engineering-verified. The next mechanics-first target is a **Ranger Contracts / Quest Board** layer that directs players back through systems already present in the game.

The design goals are:

- reinforce training, theft, hatching, Night, Grove Circuit and Sprint;
- use server-owned progress and exact one-time completion;
- use Coins as the only progression reward;
- avoid a new zone, currency, persistence requirement or public-wagering dependency;
- create short session goals that make the existing vertical slice more replayable.

See [0.4.2 Ranger Contracts](NEXT_SLICE_0.4.2_RANGER_CONTRACTS.md).

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
- [0.4.1 Engineering Verification](STAGE3_041_VERIFICATION.md)
- [0.4.2 Ranger Contracts](NEXT_SLICE_0.4.2_RANGER_CONTRACTS.md)

## Design discipline

The latest explicit owner decision overrides earlier conflicting ideas.

Starter experiences should already be enjoyable. Progression adds expression, capability, mastery, spectacle, organization, or social value.

New systems should reinforce the Egg Rivals loop rather than become disconnected chores. Existing tested services should be extended or reused when they already own the required authority.
