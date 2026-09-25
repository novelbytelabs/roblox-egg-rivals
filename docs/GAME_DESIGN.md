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

`EGG-RIVALS-0.4.4-rc1` is the current verified engineering candidate.

It passed **107/107** exact-source checks in a real two-client Roblox Studio regression. Exact tested source bytes are committed at `301448dd7cf9a8fda748d4c14b585615f170d30d`. Source digest: `be7aaa66d706a1fa86dfe0a2ad7a277ee69a80934688719bb7a1a430a7ce70d8`.

The candidate retains the Living World systems, normalized Sprint Rivalry, Ranger Contracts and Elemental Tuning, then adds Social Drafting v1: a server-derived, non-stacking +10% permanent-Speed training bonus for nearby simultaneous trainers.

Engineering verification establishes mechanics and retained regressions. It does **not** establish Social Drafting motivation/tuning, elemental-tuning fun, presentation quality or long-term retention value.

## Current product gate

The owner continues mechanics-first development while keeping human feel review separate.

Current playtesting should evaluate the retained Ranger/Sprint systems, Elemental Tuning and Social Drafting:

- whether Social Drafting is noticeable without making solo training feel inferior;
- whether each tuning identity is immediately understandable;
- whether its benefit/tradeoff feels meaningful but not mandatory;
- whether switching restrictions are clear;
- whether open-world escape choices become more interesting;
- whether contracts still provide useful direction across the core systems.

Approved design does not imply implementation. `FEATURE_STATUS_MATRIX.md` remains the current implementation-status authority.

## Design discipline

The latest explicit owner decision overrides earlier conflicting ideas.

Starter experiences should already be enjoyable. Progression adds expression, capability, mastery, spectacle, organization, or social value.

New systems should reinforce the Egg Rivals loop rather than become disconnected chores. Existing tested services should be extended or reused when they already own the required authority.
