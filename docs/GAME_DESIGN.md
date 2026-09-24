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

`EGG-RIVALS-0.4.2-rc1` is the current verified engineering candidate.

It passed **99/99** exact-source checks in a real two-client Roblox Studio regression. Tested source commit: `d0c14e6742b7cc14ddb4680a1fd9cd2dca5f7a1e`. Source digest: `87eaaa043f0dfae29585887fbd0bdf2dd8157fe6072c5052339c65c9dd29612c`.

The candidate retains the 0.4.0 Living World systems and 0.4.1 normalized Sprint Rivalry, then adds Ranger Contracts: three server-owned session goals that observe authoritative training, retrieval, hatch, Trial, Night and Sprint events and award existing Coins exactly once after explicit claim.

Engineering verification establishes mechanics and retained regressions. It does **not** establish contract fun, reward tuning, presentation quality or long-term retention value.

## Current product gate

The owner continues mechanics-first development while keeping human feel review separate.

Ranger playtesting should focus on whether contracts:

- give a young player an obvious next action;
- rotate play through the core Egg Rivals systems;
- feel optional and motivating rather than chore-like;
- pay enough Coins to matter without replacing pet income;
- make repeated sessions more purposeful.

Approved design does not imply implementation. `FEATURE_STATUS_MATRIX.md` remains the current implementation-status authority.

## Design discipline

The latest explicit owner decision overrides earlier conflicting ideas.

Starter experiences should already be enjoyable. Progression adds expression, capability, mastery, spectacle, organization, or social value.

New systems should reinforce the Egg Rivals loop rather than become disconnected chores. Existing tested services should be extended or reused when they already own the required authority.
