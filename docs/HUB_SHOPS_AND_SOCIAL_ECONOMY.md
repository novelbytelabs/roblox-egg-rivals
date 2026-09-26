# Egg Rivals — Hub Shops and Social Economy

Status: approved design direction.

The hub should feel like a place where the game's systems live physically. Shops must reinforce the main loop rather than exist as arbitrary vending menus.

## Existing: Trail Supplies

Trail Supplies supports open-world heist tools.

Current / approved examples:

- Snare pods;
- future route-control or escape-support consumables where appropriate.

It should remain focused on the theft / interference loop.

## Ranch & Pen Works

This is the physical home for ranch progression and customization.

Approved categories include:

- Ranch Expansion;
- elemental habitat pieces;
- creature comforts;
- showcase structures;
- fence and gate styles;
- ground treatments;
- lights and signs;
- pen themes;
- large-creature facilities;
- visitor presentation;
- celebration upgrades.

The starter pen remains good without purchases. This shop adds depth and expression.
## Trading Post

The Trading Post supports safe player-to-player trading.

Required principles:

1. both players see the exact items on both sides;
2. both explicitly confirm;
3. any change to either offer clears confirmation;
4. Favorite / Locked items are ineligible;
5. the server validates ownership at final commit;
6. transfer is atomic;
7. cancellation, timeout, or disconnect cannot duplicate or destroy items.

The Trading Post can support eggs, pets, and other eligible items.

## Exchange

The Exchange is **not** limited to duplicate pets.

It accepts eligible:

- items;
- eggs;
- pets.

The exact return may vary by category and balance, for example coins, tokens, cosmetic currency, crafting / upgrade resources, or other approved value.

The Exchange provides a useful sink for unwanted inventory without requiring player-to-player trading.

Locked / Favorite items cannot be exchanged accidentally.
## Night Market

Implementation candidate: **0.4.8 v1 — verification pending**.

The Night Market is a world-state shop. During Day its shutter is closed, lights are dim and interaction is disabled. At Moonrise the stall opens and its neon lamps activate.

The initial inventory deliberately stays small:

- **Moon Compass — 35 Coins:** a one-use-per-Moonrise coarse directional clue;
- **Glow Map — 60 Coins:** a one-use-per-Moonrise broad Forest-sector clue.

These are ephemeral search services rather than persistent inventory items. They do not add a new currency, change egg rarity, modify player Speed, alter pet income or reveal an exact waypoint.

The free personal flashlight remains a baseline Night accessibility tool and is not sold here.

Server validation owns Night availability, proximity, cost, per-Moonrise use and clue generation.

## Trainer Workshop

The Trainer Workshop is the in-world home for Speed Lab progression.

It can provide:

- treadmill module upgrades;
- machine-grade progression;
- cosmetic machine parts;
- training-trial access or unlocks;
- record presentation;
- later elemental tuning systems.

The machine itself should visibly reflect purchased / earned upgrades.
## Duel Armory

Implementation candidate: **0.4.9 v1 — verification pending**.

The Duel Armory is the physical loadout home for the opt-in competitive arena. The initial sidegrades are free session choices rather than purchases:

- **Blaster:** balanced baseline cadence and range;
- **Rail:** slower, harder precision shot with longer reach;
- **Scatter:** short-range five-pellet spread.

Server-owned weapon specs control damage, cooldown, range, pellet count and spread. The maximum theoretical damage cadence is kept in a narrow envelope so each choice changes style rather than selling raw superiority.

Players must be alive, free of another activity and physically at the Armory to change loadout. A challenge or active duel locks the selection. The selected loadout determines the exact duel tool each round.

Future Armory depth may add skins, sights, tracer effects and animations. Those remain presentation systems rather than paid combat power.

Do not sell direct competitive superiority for Robux.

## Pet Outfitter

Implementation candidate: **0.4.10 v1 — verification pending**.

The Pet Outfitter supports cosmetic identity without changing pet authority or competitive/economic power.

The initial free session styles are:

- **Standard:** the original creature, element and rarity presentation;
- **Ranger:** a low-profile elemental collar with a gold ranger tag;
- **Starlight:** four subtle elemental body sparks.

Players must be alive, free of another activity, physically at the Outfitter and styling an exact available pet they own. Reserved/traded/escrowed pets and foreign pets cannot be mutated through the Outfitter.

The style is stored in the existing pet `variant` field, appears in Collection previews, ranch/companion rendering and read-only visitor inspection, and naturally survives the existing trade/duel transfer paths.

v1 intentionally does **not** use size cosmetics, large hats, trails, crown-like shapes or rarity-colored replacement effects. Creature silhouette, elemental flair, rarity gem and Godly halo remain readable and authoritative.

These styles cost no Coins or Robux and do not alter income, movement, rarity, creature, element or duel power.

Future cosmetic directions may include additional collars, hats, trails, auras, nameplate styles or idle-animation variations only when they preserve the same readability and no-power rules.

## Quest Board / Ranger Station

This location provides rotating objectives that reinforce existing systems.

Examples:

- steal a set number of Forest eggs;
- hatch a Water pet;
- complete a training milestone;
- win or participate in a duel;
- find the hidden Night egg;
- use a heist tool successfully.

Quests should direct players toward the game's systems rather than become disconnected chores.

## Elemental Bazaar

The Elemental Bazaar supports Fire, Water, Wind, and Earth identity.

Candidate offerings:

- elemental ranch decorations;
- incubator cosmetics;
- pet visual effects;
- habitat objects;
- base presentation.

It should deepen elemental expression without creating four separate pay-to-win economies.

## Explicitly rejected

There is **no Egg Appraiser** in the approved shop plan.

Creature, rarity, hatch information, and collection knowledge should be exposed through existing systems where useful rather than requiring a dedicated appraisal shop.
