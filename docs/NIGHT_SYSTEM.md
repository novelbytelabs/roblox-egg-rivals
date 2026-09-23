# Egg Rivals — Night System

Status: approved design direction.

Night is not merely lower brightness. It is a temporary transformation of the entire Egg Rivals world into a dark, beautiful neon / blacklight version of itself.

The design objective is immediate recognition: when Night begins, the player should feel that the world has changed state.

## Mechanical restraint

Night should remain mechanically focused.

Approved core Night mechanics:

1. normal daytime eggs cannot be taken during Night;
2. one special high-value Night egg spawns at a randomly selected hidden location;
3. players search for that egg through exploration and subtle environmental clues;
4. active incubation receives the approved Night acceleration;
5. Night ends and normal daytime egg behavior returns.

Do not fill Night with unrelated minigames or a large independent progression tree.

The spectacle should come primarily from visual transformation, search tension, the hidden egg, and interactions with systems that already exist.
## Timing baseline

Previously approved baseline:

- Night occurs on a randomized schedule;
- common interval approximately 4–5 minutes;
- it may occasionally happen sooner or later;
- hard maximum wait approximately 10 minutes;
- baseline Night duration approximately 45 seconds;
- active incubation runs at 30x during Night.

These remain balance values and may be tuned after playtesting.

## Hidden Night egg

The Night egg should **not** appear at an obvious fixed nest.

It spawns from a curated set of genuinely searchable hiding locations.

A location should be hidden enough to reward exploration but not so obscure that discovery depends on random pixel hunting.

Do not display a direct waypoint to the egg.

Instead, the surrounding region can communicate subtle clues.
## Environmental search clues

Approved clue language includes:

- unusually bright glowing spores;
- localized neon mist;
- environmental flicker;
- faint pulses;
- intensified blacklight flora;
- distant or directional audio hints;
- Moon Shrine reactions.

Clues should narrow attention without directly revealing the exact egg position.

The Moon Shrine is a strong Night anchor. At Night it can awaken through glowing runes, rising particles, slow color cycling, and vague environmental guidance.

The exact relationship between the shrine and the hidden egg remains tunable.

## Full blacklight transformation

When Night begins:

- the sky becomes substantially darker;
- foliage gains blacklight / fluorescent character;
- paths and important architecture receive restrained neon edge language;
- signs and interactive objects become more luminous;
- camps transform rather than merely dim;
- eggs and magical objects gain stronger glow;
- moving magical objects become visually traceable.

The world should remain navigable. Darkness is atmosphere, not an accessibility punishment.
## Element-reactive neon

Do not wash the entire world in a single purple tint.

Each element preserves a distinct Night identity:

- Fire: hot neon orange, red, and magenta;
- Water: electric blue and teal;
- Wind: white, cyan, and violet;
- Earth: lime, emerald, and gold.

This palette applies to incubators, pets, habitat effects, trails, and other elemental presentation.

## Particle-based motion trails

Fast glowing objects can emit trails made from particles.

Approved examples:

- high-speed players;
- active pets;
- certain pet-play movements;
- the Night egg or related magical objects;
- the Warden / boss where visually appropriate;
- other clearly magical high-velocity objects.

Trail length and density should increase with meaningful speed.

The trail itself is particle material, not merely a static line renderer.
## Full-stop collision splatter

The Night impact effect follows a specific physical idea:

**the particles that form a moving object's neon trail become the material that visually splatters when the object reaches a genuine full-stop collision.**

The effect should behave conceptually as follows:

1. object moves fast enough to generate a particle trail;
2. object reaches a genuine stop through impact / landing;
3. trail material appears to overtake the stopped object and burst outward from the impact region;
4. fragments scatter like colorful neon firework sparks;
5. colors may shift while fragments expand and dissipate;
6. impact emission continues only while the object remains effectively stopped;
7. as soon as meaningful movement resumes, impact emission stops and the moving trail behavior resumes.

A slowdown alone does not qualify. The trigger is a full-stop collision / landing state.

The visual should suggest conservation of the trail's accumulated motion rather than spawning unrelated confetti.
## Approved examples

Use the effect selectively for high-value motion moments such as:

- a fast player landing after a jump;
- a glowing pet striking the ground during play;
- a major pet-to-environment play impact;
- a Warden impact;
- other gameplay collisions where the Night presentation benefits.

The duel arena / RIVALS combat version is explicitly deferred. Do not expand this visual system into arena combat until that workstream is revisited.

## Performance and restraint

This is a visual-direction rule, not a locked particle algorithm.

Tune:

- emission threshold;
- velocity threshold;
- stop threshold;
- trail length;
- particle count;
- lifetime;
- collision duration;
- color sequencing;
- pooling;
- client quality level.

The effect must scale down gracefully on weaker devices.

The user explicitly does not want to overdo Night mechanics. Favor a few exceptional effects over constant visual noise.
## Night atmosphere

Additional approved presentation:

- ambient behavior quiets or changes;
- some pets stop and look outward as Night begins;
- camp lights switch into neon mode;
- music / ambience becomes deeper and more mysterious;
- fireflies / fluorescent particles become more visible;
- the hidden egg's region feels subtly abnormal.

## Godly pets at Night

Godly reverence may intensify visually at Night:

- stronger aura;
- floating neon crown / ring;
- amplified elemental light;
- same-element bow sequence illuminated by Night effects.

This enhances an existing pet behavior rather than introducing a separate Night mechanic.

## Night Market

The Night Market is physically closed during the day.

At Night its lights turn on and the location becomes active.

It may offer lanterns, maps, clue tools, or limited-use aids that help narrow the hidden egg search without revealing the exact location.

Its purpose is to reinforce Night as a world event, not to trivialize the search.
