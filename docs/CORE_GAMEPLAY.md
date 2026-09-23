# Egg Rivals — Core Gameplay

Status: approved direction. Exact balance values remain tunable unless marked locked.

## Train

Players train Speed on their own treadmill / Speed Lab. Training is automatic while physically using the machine. Higher machine capability increases the rate at which the persistent Speed stat is earned.

The progression number may become extremely large, but avatar movement must remain controllable. Raw Speed is mapped through a bounded or diminishing-return movement function rather than used directly as Roblox `WalkSpeed`.

Training is not intended to remain a passive waiting mechanic. The approved Speed Lab design adds mastery, records, social play, temporary tactical benefits, machine customization, and visual progression. See `SPEED_LAB_SYSTEM.md`.

## Steal

Eggs exist in defended locations. Each active egg has:

- creature identity;
- rarity;
- zone / spawn identity;
- hatch duration;
- defender relationship;
- state and ownership metadata.

A player deliberately takes an available egg and carries it physically while escaping.

Carrying an egg does **not** reduce movement speed.
## Defender chase

Taking a defended egg causes its NPC defender to pursue the carrier.

The defender should make recommended Speed meaningful without imposing hard zone gates. Slower players are allowed to attempt difficult thefts; they simply face a poor chance of escape.

A successful defender catch ends the theft attempt and returns or resets the egg. The player is returned to the appropriate safe/home state.

A dropped egg is not magically reclaimed. The defender physically attempts to recover it, giving nearby players an opportunity to take it first.

## Open-world interference

Open-world PvP exists primarily to contest a currently carried egg.

The Bat is the baseline short-range interference tool. A valid hit on an egg carrier:

1. knocks the egg loose;
2. resets / returns the carrier as defined by the current zone rules;
3. leaves the egg physically contestable;
4. allows another player to grab it before the defender recovers it.

Safe/home areas disable hostile interference.

The Snare is an approved complementary tool that temporarily slows a carrier. Later route-control tools such as launch pads or temporary barriers remain compatible directions, but should not turn the open world into continuous deathmatch.
## Secure and incubate

Returning an egg to the player's camp does not arbitrarily assign an element. The player chooses Fire, Water, Wind, or Earth.

The selected elemental incubator determines the pet element while the egg preserves creature identity and rarity.

Placement must be deliberate enough to prevent an accidental wrong-element hatch. Physical separation, readable architecture, highlighting, preview, and confirmation are part of the incubator UX.

Up to four elemental incubations can run independently in the current camp design.

## Hatch and earn

Hatching transforms the egg record into a living pet record while preserving its creature, rarity, ownership history, and chosen element.

Pets generate passive income. Penned pets and the single active companion continue earning unless a later balance rule explicitly changes this.

Early hatch timing should provide fast feedback. A basic/tiny egg may hatch in roughly 20 seconds. Higher rarities can extend into minutes and, for upper tiers, hours. The previously approved Legendary/Mythic reference duration was approximately 2 hours 30 minutes; final Godly timing remains a balance decision.

Night acceleration applies to active incubation as defined in `NIGHT_SYSTEM.md`.
## Collection and item safety

Players can own many eggs, pets, and other eligible items. Ownership is independent of whether an item is physically displayed.

Important safety rules:

- permanent inventory cannot be deleted by ordinary open-world interference;
- Favorite/Lock prevents accidental trade, exchange, or duel staking;
- server authority validates all transfers and mutations;
- unique item instance IDs prevent ambiguous ownership;
- physical pet display capacity never destroys or discards overflow pets.

The Collection UI is a management surface, not the sole representation of ownership. Important creatures should also exist visibly in the player's ranch when possible.

## Progression philosophy

Egg Rivals should reward:

- training capability;
- movement skill;
- theft execution;
- collection breadth;
- rarity discovery;
- elemental variants;
- ranch presentation;
- social exchange;
- optional competitive skill.

No single subsystem should make the others irrelevant.
