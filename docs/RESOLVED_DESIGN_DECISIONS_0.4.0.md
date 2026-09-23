# Egg Rivals — Resolved Design Decisions for 0.4.0

Status: canonical decisions for the next major slice.

This document resolves the ambiguity queue that remained after the initial Egg Rivals design reconciliation.

## 1. Old Speed model is abolished

Superseded and no longer canonical:

- 300-billion Speed target;
- ambiguous "maximum 5x";
- 2x / 4x / 6x / 8x / 10x treadmill ladder;
- the typed 8x price `25,0000`;
- the older Starter/Bronze/Silver/Gold/Plasma/Hyper linear treadmill ladder.

Canonical replacement: `ECONOMY_SPEED_RARITY_V2.md`.

The 0.4.0 permanent Speed ceiling is 10,000 with bounded movement mapping.

## 2. Creature and rarity are independent

Any supported creature may occur at any rarity.

Examples that are all valid:

- Common Dragon;
- Mythic Skunk;
- Godly Lizard;
- Rare Gorilla.

Element is also independent. Rarity is never inferred from creature identity.
## 3. Elements do not grant pet combat / income power

For 0.4.0, Fire, Water, Wind, and Earth provide:

- identity;
- visual language;
- pet behavior flavor;
- habitat preferences;
- collection variety.

Pet income is determined by rarity, not element.

Element does not increase duel damage, theft speed, hatch income, or rarity odds.

The separate Speed Lab elemental-tuning concept remains a small tactical training/movement sidegrade and is not derived from the active pet.

## 4. Godly acquisition

Godly is the top standard rarity.

Initial rates:

- ordinary daytime egg roll: 0.05%;
- hidden Night egg: 1%.

Godly cannot be purchased directly from a shop.

It may be hatched, traded, won through a permitted internal test duel, or granted through a separately authorized live event.

Godly hatch time: 120 minutes base.

Godly passive income: 2,500 Coins/minute.

## 5. Night transition with carried eggs

When Night begins:

- new daytime egg pickups are disabled;
- an already-carried daytime egg remains valid;
- its carrier may complete the escape and incubate it normally;
- it is not deleted or forcibly returned solely because the clock changed.

This avoids punishing a player for a world-state transition they did not control.
## 6. Daytime nests during Night

Daytime nests remain physically visible but enter a dormant / sealed state.

Their pickup prompts are disabled.

Visual treatment should make "dormant until Day" obvious without hiding the geography players learned.

## 7. Hidden Night egg lifecycle

Exactly one Night egg is active per Night event.

It spawns at one location selected from a curated hiding-location pool.

If unclaimed when Day begins, it despawns.

If already carried when Day begins, it remains valid until the current theft resolves.

If dropped after Day begins during that same unresolved carry contest, it remains contestable until secured or otherwise resolved. It does not disappear under the carrier.

0.4.0 does not add a separate Night boss. The Night egg's challenge is discovery plus open-world contest pressure.

## 8. Hidden Night egg creature

Creature is random and independent of Night rarity.

The current 0.4.0 creature pool is:

- Skunk;
- Lizard;
- Gorilla;
- Dragon.

Future creature additions automatically become eligible only when explicitly added to the Night pool.
## 9. Pen display capacity

Ownership and income are not limited by physical display capacity.

Starter pen visible capacity: 8 pets.

Planned Ranch Expansion visible capacities:

- Starter: 8;
- Expansion I: 12;
- Expansion II: 16;
- Expansion III: 24.

Overflow remains owned and paged / rotated safely.

Initial expansion costs:

- Expansion I: 800 Coins;
- Expansion II: 3,000 Coins;
- Expansion III: 12,000 Coins.

Each expansion changes actual ranch geometry, not only a numeric limit.

## 10. Godly reverence frequency

Natural reverence:

- eligible only while a Godly pet is visibly resident;
- random interval: 4–7 minutes;
- requires at least one visible same-element non-Godly pet to bow;
- one reverence sequence per ranch at a time.

Visitor-triggered reverence:

- one request per ranch every 120 seconds;
- uses a visible interaction, not hidden proximity spam;
- if several Godly pets exist, server chooses one eligible resident;
- cannot interrupt an active welcome party or another reverence event.

Target sequence length: approximately 6–8 seconds.
## 11. Welcome-party acquisition rules

A welcome party occurs when a pet becomes a genuine new arrival for the current owner through:

- hatching;
- completed player trade;
- permitted duel transfer;
- live-event reward;
- explicit developer/test grant.

Loading an already-owned pet from persistence does not trigger a welcome party.

Several arrivals within three seconds are grouped into one celebration.

Ranch welcome events have an eight-second minimum spacing to prevent spam.

## 12. Overdrive

0.4.0 rules are locked in `ECONOMY_SPEED_RARITY_V2.md`.

Key points:

- one 0..100 charge meter;
- charge only through treadmill training;
- 5-second activation;
- +20% mapped movement;
- hard cap 68 studs/s;
- usable while carrying an open-world egg;
- disabled in duel arena;
- death does not erase charge.

## 13. Motion Energy

Motion Energy is a temporary 0..100 camp-power meter.

It is not Money, not premium currency, and not inventory.

It powers presentation systems. It does not increase duel damage or pet income.

Persistence is unnecessary for 0.4.0.
## 14. Sprint Challenges

0.4.0 Sprint Challenges use normalized movement.

Both competitors receive the same race movement settings:

- WalkSpeed: 45;
- standard jump settings;
- no Overdrive;
- no pet / element movement bonuses.

Permanent Speed remains visible as progression elsewhere, but Sprint Challenges test route execution and movement skill.

An "Open Class" race using permanent Speed is deferred until normalized racing is proven fun.

## 15. Exchange currency and value

0.4.0 uses Coins only.

Exchange returns Coins, not a new token.

Pet Exchange value equals eight minutes of that rarity's passive income.

Unhatched egg Exchange value equals 60% of the equivalent pet value.

Locked / reserved items cannot be exchanged.

Godly Exchange requires explicit five-second confirmation.

## 16. Trading restrictions

Trading unlocks after the player has completed the onboarding loop and hatched three pets.

Trade requirements:

- both players see exact instance-level offers;
- offer change clears confirmations;
- final confirmation includes a three-second hold;
- Godly transfer requires a separate five-second final hold;
- locked, carried, incubating, escrowed, or server-reserved items are ineligible;
- active companion must be sent to pen before trade;
- five-second cooldown after completion or cancellation;
- server commits atomically.
## 17. Shop currencies

Coins are the only required progression currency in 0.4.0.

No mandatory gems, shells, tickets, or elemental currencies.

Later event/cosmetic currency requires a separate design decision.

## 18. Zone scope

0.4.0 does **not** add Lake, Desert, Jungle, Arctic, Volcano, or endgame zones.

Meadow + Forest remain the major-slice world footprint.

The push adds depth and transformation to the existing world rather than breadth.

Future zone names/order remain directional references, not locked production content.

## 19. Respawn protection

No separate timed invulnerability buff is required in 0.4.0 because the personal camp is already a safe zone.

Respawn shimmer is presentation only.

If a later spawn can occur outside a safe zone, protection must be designed explicitly then.

## 20. Admin / developer privilege

The superseded 15x Admin Pen is abolished.

Admin/developer status does not grant permanent economic acceleration.

Server-authorized admin/dev capabilities may include:

- testing;
- controlled live events;
- moderation;
- diagnostics;
- explicit cosmetic recognition.

They do not silently create superior income, hatch rate, Speed, or duel power.
## 21. Public duel stakes

No new decision is required for 0.4.0 implementation.

Item-transfer staking remains Studio-only.

Public deployment remains blocked on a current Roblox policy review.

The major slice must not publish or enable policy-dependent public staking.

## 22. Night particle constants

Exact particle counts and thresholds remain implementation-tuning constants rather than product-law values.

Initial engineering targets may be chosen and measured in 0.4.0.

The invariant design rule remains:

- meaningful fast movement creates a particle trail;
- genuine collision to effectively stopped state converts the visual momentum into splatter;
- slowdown alone does not trigger it;
- resumed meaningful motion immediately ends stopped-impact emission.

## 23. Incubator error prevention

0.4.0 adopts:

- one incubator at each camp corner;
- unique architecture per element;
- highlight of selected target;
- non-target dimming during confirmation;
- 0.75-second hold-to-place;
- result preview showing creature + chosen element + rarity + hatch duration.

A carried egg is never auto-assigned to an element merely by crossing a trigger volume.

## 24. Currency / economy tuning governance

Prices and income values in 0.4.0 are initial tuning, not immutable lore.

Change them only through explicit balance evidence.

Do not change architectural rules such as independent rarity/creature/element, atomic ownership, or bounded movement merely to fix an economy number.
