# Egg Rivals — Design Bible

Status: canonical approved design direction.

Egg Rivals is a Roblox speed-heist, elemental-pet collection, personal-ranch, social economy, and opt-in competitive game. The design should be immediately understandable to a young player while providing long-term mastery, collection, customization, social expression, and spectacle.

## Core fantasy

Train until you are fast enough to steal a defended egg, escape with it, choose what element it will become, hatch a living creature, build a remarkable ranch, and use what you collect in trading, progression, and optional rivalry.

The core progression loop is:

`train -> steal -> escape -> choose element -> hatch -> collect -> earn -> upgrade -> explore harder opportunities`

The competitive loop is:

`own valuable items -> challenge -> explicitly choose stakes -> confirm both offers -> first-to-five duel -> resolve ownership atomically`

The social loop is:

`build a distinctive camp -> display pets -> visit other ranches -> inspect -> trade/exchange -> celebrate rare creatures -> compete`

## Design pillars

1. Speed must matter physically, not only as a number.
2. Egg theft creates tension through pursuit, escape, and player interference.
3. The egg determines creature identity; the incubator determines element.
4. Pets are living residents, economic contributors, collectibles, and social objects.
5. A player's base should visibly tell the story of their progress.
6. Night should feel like entering another version of the same world.
7. Competitive play is opt-in and skill-forward.
8. Systems should reinforce the central game rather than become disconnected chores.
9. Starter systems should already feel good; progression adds depth, expression, and spectacle.
10. Server authority protects inventory, economy, stakes, progression, and competitive results.

## Standard rarity ladder

The approved standard ladder is:

`Common -> Uncommon -> Rare -> Epic -> Legendary -> Mythic -> Godly`

Godly is the highest approved standard rarity.

A Godly pet is not merely a higher number. Its presence changes pet social behavior. Other pets avoid casual play with it and maintain distance. Periodically a Godly pet rises into the air; pets of the same element stop what they are doing, orient toward it, and bow. Visitors can witness or trigger this reverence sequence.

The earlier standard-rarity use of `Secret` is superseded by Godly. Secret-like content may later exist as event content only if explicitly reintroduced.

## World and progression structure

The vertical slice remains intentionally compact. A polished Meadow/camp area and Forest theft zone are more important than a large empty map.

Long-term world progression can add distinct zones with increasing defender difficulty and different traversal identities. Recommended Speed is guidance, not a hard entrance gate. A slower player may enter a difficult zone and attempt a theft, but insufficient capability should make escape naturally difficult.

Carrying an egg does not reduce player movement speed.

The player should understand within minutes that training improves escape capability, pets create economic progress, and rarer creatures create collection and social value.

## Elemental creature system

Every egg carries a base creature identity. Current vertical-slice creature set:

- Skunk
- Lizard
- Gorilla
- Dragon

The player chooses one of four elemental incubators:

- Fire
- Water
- Wind
- Earth

The same Dragon egg can therefore become Fire Dragon, Water Dragon, Wind Dragon, or Earth Dragon. Rarity remains independent of creature and element.

The system must scale to additional creatures without multiplying bespoke code paths. Creature, element, rarity, cosmetic variant, ownership, and activity state are distinct item properties.

## Camp identity

Each player receives a personal camp containing, at minimum:

- training / Speed Lab area;
- four elemental incubators;
- a clearly designated personal respawn area;
- a pet pen behind or integrated with the base;
- collection and management access;
- visual space for later camp systems.

The base should become a visible expression of player progression rather than a menu shell.

Detailed specifications live in:

- `BASE_INCUBATION_RESPAWN.md`
- `PET_PEN_SYSTEM.md`
- `SPEED_LAB_SYSTEM.md`
- `NIGHT_SYSTEM.md`
- `HUB_SHOPS_AND_SOCIAL_ECONOMY.md`
- `PVP_AND_DUELS.md`
- `DECISION_LEDGER.md`
