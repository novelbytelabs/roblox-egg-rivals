# Egg Rivals — Base, Incubators, and Respawn

Status: approved design direction.

Each player's camp is a compact personal headquarters. It combines training, elemental hatching, respawn/homecoming, pet display, and future customization without becoming a maze.

## Square-base layout

The preferred layout uses a broadly square camp with one elemental incubator at each corner.

This creates maximum physical separation between Fire, Water, Wind, and Earth and reduces accidental placement.

The exact corner assignment may be tuned for navigation, but the player should be able to identify all four incubators immediately from the center of the base.

The pet pen sits behind or naturally adjacent to the camp. The Speed Lab occupies its own readable training area. The personal respawn area remains clear of incubator traffic and pet clutter.

## Four independent elemental incubators

Each base has:

- Fire incubator;
- Water incubator;
- Wind incubator;
- Earth incubator.

Each incubator is an independent slot. Multiple eggs may therefore incubate simultaneously when they occupy different elemental slots.

The egg determines creature and rarity. The incubator determines element.
## Element visual language

Each incubator must be unmistakable at a glance and at a distance.

### Fire
- red / orange / hot-magenta family;
- ember particles;
- heat shimmer or energy distortion;
- warm glow and animated flame-like accents.

### Water
- blue / cyan family;
- ripples;
- droplets, bubbles, or flowing-light motion;
- reflective / liquid presentation.

### Wind
- white / cyan / violet family;
- air ribbons;
- rotating streamers or rings;
- upward / floating motion.

### Earth
- green / gold / stone-brown family;
- roots, rocks, leaves, crystal or soil accents;
- grounded pulsing effects.

Color is not the only signal. Shape, motion, signage, sound, and architecture must also communicate element.
## Preventing wrong-incubator placement

Element choice must be deliberate.

Approved safeguards include:

1. physical separation by corner;
2. tall elemental arch / banner or unmistakable world marker;
3. strong local highlight when an incubator is targeted;
4. dimming or de-emphasizing non-target incubators during confirmation;
5. a short hold-to-place interaction instead of accidental walk-over deposit;
6. a concise preview before final placement.

Example preview:

`DRAGON EGG + FIRE -> FIRE DRAGON`

The preview should also expose rarity and hatch time when useful.

The UI should not imply that one element is objectively "correct." The highlighted incubator is the player's selected destination.
## Incubation presentation

Once an egg is committed:

- the physical egg appears inside the selected incubator;
- the incubator shows creature, element, rarity, and remaining time;
- element-specific effects intensify;
- Night acceleration is visually obvious when active;
- completion transitions into a hatch celebration rather than silently changing inventory data.

Each incubator shows its own independent countdown.

Stored, unhatched eggs retain creature identity and rarity until an element is chosen.

## Hatch result

A completed hatch yields a pet record containing at least:

- unique instance ID;
- creature;
- element;
- rarity;
- ownership;
- passive income;
- cosmetic variant;
- Favorite / Lock state;
- active / pen state;
- acquisition metadata.

The first pet may become the active companion if no active pet exists.
## Personal respawn area

Every player base has a dedicated, clearly marked respawn platform.

The respawn area should:

- be visually distinct from training and incubation;
- remain free of clutter;
- use the player's camp identity / color;
- place the character safely with predictable facing;
- restore ordinary non-duel equipment and controls;
- return the player to their own camp, not a shared anonymous spawn.

The respawn point is a real gameplay spawn destination, not just decorative floor art.

## Arrival / homecoming effect

Respawn should feel like returning home.

Approved presentation can include:

- a short soft energy burst;
- temporary visual shimmer;
- camp-color or elemental accents;
- nearby pets looking toward the player;
- active companion approaching the player;
- penned pets briefly gathering at the fence / gate.

Any invulnerability window, if added, must be explicit and server-authoritative rather than assumed from the visual effect.
## Camp readability

The player should be able to stand near the center of their base and understand:

- where they train;
- where they respawn;
- which corner creates which element;
- where their pets live;
- how to access collection / ranch management.

Use architecture before floating UI whenever practical.

## Future camp expression

The camp can later integrate:

- Speed Lab machine-grade presentation;
- Ranch & Pen Works customizations;
- elemental habitat decoration;
- Motion Energy powered effects;
- trophies / records;
- favorite-pet showcases;
- Night-specific lighting transformation.

These systems should preserve navigational clarity as the base becomes more elaborate.
