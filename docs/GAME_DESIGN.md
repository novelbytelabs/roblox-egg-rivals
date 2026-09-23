# Egg Rivals — Game Design Overview

Status: canonical overview. Detailed system specifications linked below carry equal design authority; the Decision Ledger resolves conflicts by latest explicit owner decision.

Egg Rivals combines speed progression, defended egg theft, elemental hatching, collectible living pets, personal ranches, social trading/economy, open-world interference, and optional first-to-five rivalry.

Core progression:

`train -> steal -> escape -> choose element -> hatch -> collect -> earn -> upgrade -> explore`

Core competitive loop:

`challenge -> choose exact offers -> confirm -> duel -> resolve ownership`

Standard rarity:

`Common -> Uncommon -> Rare -> Epic -> Legendary -> Mythic -> Godly`

Four elements:

`Fire • Water • Wind • Earth`

Current vertical-slice creatures:

`Skunk • Lizard • Gorilla • Dragon`

The egg determines creature identity. The incubator determines elemental form. Rarity is independent of both.

## Canonical detailed specifications

- [Design Bible](DESIGN_BIBLE.md)
- [Core Gameplay](CORE_GAMEPLAY.md)
- [Base, Incubators, and Respawn](BASE_INCUBATION_RESPAWN.md)
- [Pet Pen and Ranch](PET_PEN_SYSTEM.md)
- [Speed Lab and Treadmill](SPEED_LAB_SYSTEM.md)
- [Night System](NIGHT_SYSTEM.md)
- [Hub Shops and Social Economy](HUB_SHOPS_AND_SOCIAL_ECONOMY.md)
- [PvP and Duels](PVP_AND_DUELS.md)
- [Live Operations](LIVE_OPERATIONS.md)
- [Production Guardrails](PRODUCTION_GUARDRAILS.md)
- [World and Balance References](WORLD_AND_BALANCE_REFERENCES.md)
- [Decision Ledger](DECISION_LEDGER.md)
- [Resolved 0.4.0 Decisions](RESOLVED_DESIGN_DECISIONS_0.4.0.md)
- [Economy, Speed, and Rarity v2](ECONOMY_SPEED_RARITY_V2.md)
- [0.4.0 Living World Plan](NEXT_SLICE_0.4.0_LIVING_WORLD.md)
- [Feature Status Matrix](FEATURE_STATUS_MATRIX.md)

## Current engineering baseline

`MOONWOOD-0.3.2-r2` is the current verified reference.

It passed 24/24 two-client Roblox Studio engineering checks. Human presentation and gameplay-feel acceptance is a separate gate.

The verified baseline does **not** automatically implement every newly documented approved design direction. New features must be delivered as bounded candidates and regression-tested.

## Design discipline

The latest explicit owner decision overrides earlier conflicting ideas.

Do not silently normalize ambiguous economy numbers or revive superseded systems.

Starter experiences should already be enjoyable. Upgrades add expression, capability, mastery, spectacle, organization, or social value.

New systems should reinforce the Egg Rivals loop rather than turn the game into unrelated minigames or maintenance chores.
