# Egg Rivals 0.4.0 — Living World + Progression Slice

Status: approved major implementation plan.

This is intentionally a large multi-hour engineering push. It is still bounded: it deepens the existing Meadow + Forest vertical slice rather than expanding into a new world.

Working release name:

**EGG-RIVALS-0.4.0 — LIVING WORLD**

## Objective

Transform the verified 0.3.2-r2 prototype into a substantially more distinctive Egg Rivals experience by integrating:

1. rational Speed / economy progression;
2. a real Speed Lab;
3. living ranch behavior;
4. Godly rarity / social presence;
5. safer and more expressive elemental incubation;
6. a complete Night gameplay/presentation transformation;
7. functional progression shops and Exchange;
8. safe player trading;
9. expanded regression evidence.

The slice should make the game feel qualitatively different, not merely add menus.

## Baseline

Starting reference: `MOONWOOD-0.3.2-r2`.

Preserve it unchanged and recoverable.

Its 24/24 multiplayer result remains historical evidence only. 0.4.0 must earn its own verification.
## In scope

### A. Economy / rarity v2
- replace old Speed and treadmill-number assumptions;
- Speed cap 10,000;
- bounded movement mapping;
- seven rarities through Godly;
- any creature at any rarity;
- independent creature / rarity / element;
- v2 hatch durations;
- v2 pet income;
- day and hidden-Night rarity tables;
- single core currency: Coins;
- Exchange values.

### B. Speed Lab v2
- seven machine grades;
- physical machine progression;
- Momentum;
- Overdrive;
- Motion Energy;
- machine records;
- milestone feedback;
- active-pet treadmill reaction;
- one real Training Trial;
- personal ghost for that trial.

The first implementation may make module appearance grade-driven. Independent per-module purchase trees are not required for 0.4.0.
### C. Camp / incubator v2
- square/readable camp organization;
- Fire, Water, Wind, Earth incubators separated to corners;
- unmistakable element architecture;
- no walk-over auto-assignment;
- 0.75-second hold-to-place;
- preview: creature + rarity + element + hatch time;
- independent countdowns;
- personal respawn remains intact;
- homecoming visual / pet reaction.

### D. Living Ranch v1
- resident behavior state machine;
- Idle;
- Wander;
- Rest;
- Play;
- Greet;
- Revere;
- one active companion;
- visible capacity / safe overflow;
- Welcome Party;
- Godly distance behavior;
- Godly reverence;
- owner homecoming;
- earnings board;
- walk-through gate;
- three physical Ranch Expansion tiers.

No feeding, health, breeding, or maintenance meters.
### E. Night 2.0
- Day nests visibly dormant and non-pickable;
- one hidden Night egg;
- curated hiding-location pool;
- carried Day eggs survive Night transition;
- hidden egg survives sunrise only if its contest is already active;
- no new Night boss;
- environmental clue field;
- Moon Shrine Night activation;
- full dark neon / blacklight presentation;
- element-reactive Night palette;
- speed-scaled particle motion trails;
- genuine full-stop collision splatter;
- pet-play Night impacts;
- restrained atmosphere changes;
- preserve 30x incubation acceleration.

Arena / Duel neon impact integration remains deferred.

### F. Functional hub progression
Implement, not placeholder:

- Trainer Workshop;
- Ranch & Pen Works;
- Exchange;
- Trading Post.

Other approved shops remain later work.
## Trainer Workshop 0.4.0

Provides the seven Speed Lab grade upgrades.

The world model / interface shows:

- current grade;
- current training rate;
- current Speed ceiling;
- next grade;
- next price;
- meaningful visual machine changes.

The shop may also expose Training Trial start / record information if that produces cleaner UX.

## Ranch & Pen Works 0.4.0

Provides the three physical ranch expansions:

- Expansion I — 12 visible pets — 800 Coins;
- Expansion II — 16 visible pets — 3,000 Coins;
- Expansion III — 24 visible pets — 12,000 Coins.

Each purchase changes actual geometry and usable display positions.

Additional Habitat / Theme / Comfort branches remain approved but do not need implementation in this slice.

## Exchange 0.4.0

Supports:

- eggs;
- pets;
- eligible Trail Supply items.

Uses exact server-owned item IDs.

Returns Coins.

Requires explicit confirmation and all safety restrictions from the resolved decisions.
## Trading Post 0.4.0

Unlock condition:

- onboarding complete;
- player has hatched at least three pets.

Required flow:

1. player selects another nearby player;
2. target accepts / declines trade session;
3. each side adds exact eligible items;
4. both see exact instance-level offers;
5. any offer mutation resets confirmation;
6. each performs final three-second confirm hold;
7. Godly transfer adds a separate five-second final hold;
8. server revalidates all ownership and reservations;
9. atomic commit transfers both sides;
10. failure / disconnect / timeout returns all items unchanged.

Trade eligibility includes eggs, pets, and approved items.

Active companion must be returned to pen before offering.

No escrow implementation may create duplicate or orphan states.

## Training Trial + ghost

0.4.0 implements one polished course in the existing Meadow / Forest footprint.

The trial records:

- start;
- gate order;
- finish;
- elapsed time;
- personal best.

A local translucent ghost replays the player's best valid run.

Ghost data is presentation-only. It cannot trigger gates or world interactions.
## Out of scope

Do not add during this slice:

- Lake / Desert / Jungle / Arctic / Volcano;
- new creature families beyond the current four;
- breeding;
- feeding / health / happiness chores;
- persistent DataStore production rollout;
- mobile / console controls;
- additional currencies;
- public item-stake publishing;
- arena weapon expansion;
- arena neon collision effects;
- full Quest Board;
- Pet Outfitter;
- Duel Armory expansion;
- Elemental Bazaar;
- Night Market commerce;
- per-module 30-upgrade treadmill tree;
- procedural AI-generated pets.

These remain future work unless the owner explicitly changes scope.

## Phase 0 — Baseline freeze and reconciliation

Before mutation:

- pull / reconcile `main`;
- record exact starting HEAD;
- create implementation branch;
- preserve source digest;
- build current PLAY and TEST artifacts;
- confirm source is 0.3.2-r2 equivalent;
- read all canonical design docs;
- identify every source path affected;
- do not rely on stale Studio-generated files.
## Phase 1 — Schema and economy migration

Implement authoritative data/config first.

Required concepts:

- rarity table through Godly;
- independent creature / rarity / element;
- Speed v2;
- Speed Lab grade;
- Momentum;
- Overdrive charge;
- Motion Energy;
- ranch expansion level;
- trade eligibility state;
- pet social state where authoritative state is needed.

Do not scatter economy constants across scripts.

Create one canonical config surface with validation.

Migration from current in-memory session structures must not lose current test inventory behavior.

No persistence migration is required because 0.4.0 remains session-only.

## Phase 2 — Speed Lab

Implement:

- movement mapping;
- grade ceiling;
- grade training rates;
- Momentum ramp / decay;
- Overdrive charge / activation;
- Motion Energy;
- machine visuals;
- records;
- trial;
- ghost;
- pet reaction.

Server owns permanent Speed, grade, purchases, Overdrive charge, and Trial validity.

Client owns cosmetic effects and ghost rendering.
## Phase 3 — Base and incubation

Rebuild camp layout without increasing overall world footprint unnecessarily.

Implement four-corner incubators and deliberate selection.

Preserve:

- independent incubations;
- stored eggs;
- respawn;
- pen;
- safe-zone behavior.

Regression must prove an egg cannot be placed in another player's incubator or assigned to an unintended element.

## Phase 4 — Living Ranch

Implement pet behavior scheduling with server-authoritative ownership and client-efficient animation.

Important performance principle:

The server chooses meaningful pet state and interaction eligibility. Clients can animate local presentation without sending pet authority back to the server.

Implement:

- baseline state transitions;
- welcome event batching;
- homecoming;
- Godly exclusion radius;
- reverence scheduling / visitor cooldown;
- physical expansions;
- safe overflow.

Do not let dozens of pets generate unbounded pathfinding jobs.
## Phase 5 — Night 2.0

Implement mechanical Night rules first:

- dormant nests;
- hidden egg lifecycle;
- curated spawn set;
- clue field;
- carry-through transitions.

Then implement presentation:

- Lighting / Atmosphere transition;
- neon world treatment;
- elemental palette;
- Moon Shrine activation;
- trails;
- full-stop collision splatter;
- pet-play impact integration.

Night visuals should be client-scalable.

Provide quality tiers or bounded emission counts so lower-end clients do not collapse under particle load.

No combat-stat effect comes from neon presentation.

## Phase 6 — Shops, Exchange, Trading

Implement Trainer Workshop and Ranch & Pen Works against the real new progression state.

Implement Exchange with atomic removal + Coin credit.

Implement Trading Post with full two-party state machine.

Failure preservation is mandatory:

- offer mutation;
- cancellation;
- timeout;
- disconnect;
- invalidated item;
- lost proximity;
- duplicate request;
- stale confirmation.

All failure paths must end with a valid ownership state.
## Phase 7 — Automated verification

Do not merely rerun the old 24 checks and claim success.

Preserve equivalent coverage for every old invariant and add direct coverage for new behavior.

Required new test families:

### Economy / rarity
- rarity weights validate and sum to 100;
- any creature can exist at every rarity;
- element does not modify rarity income;
- Godly values exist;
- Exchange formula / safety;
- integer payout accumulator preserves fractional income.

### Speed
- mapping monotonic and bounded;
- each grade ceiling enforced;
- purchase price / ownership;
- Momentum ramp / decay;
- Overdrive cannot exceed cap;
- duel disables Overdrive;
- Motion Energy has no economy authority;
- Trial gate order;
- invalid Trial does not set record.

### Incubation
- corner ownership;
- explicit element choice;
- no walk-over placement;
- simultaneous independent slots;
- preview data corresponds to server result.
### Ranch
- welcome party on genuine acquisition;
- no party on ordinary reload/setup;
- grouped arrivals;
- Godly exclusion;
- natural reverence cooldown;
- visitor trigger cooldown;
- only same-element pets bow;
- expansion capacity 8/12/16/24;
- overflow safe;
- all owned pets keep income.

### Night
- Day nest prompts disable;
- carried Day egg survives transition;
- exactly one hidden egg;
- unclaimed hidden egg removed at dawn;
- claimed contest persists through dawn;
- Night rarity distribution only allows Legendary/Mythic/Godly;
- creature independent of rarity;
- 30x incubation still correct;
- ordinary Day state restored.

### Trade
- unlock rule;
- exact ownership validation;
- offer mutation clears confirmations;
- Godly extra confirmation;
- lock protection;
- active pet rejection;
- atomic transfer;
- disconnect / cancel / timeout preserves both inventories.

### Regression
- Bat;
- Snare;
- Warden;
- safe zones;
- income;
- duel decline;
- duel escrow;
- first-to-five;
- camera;
- respawn;
- client collection controls.
## Phase 8 — Real Studio multiplayer run

Produce a fresh immutable TEST candidate.

Run the complete suite in real two-client Roblox Studio.

The result file must identify:

- build;
- source digest;
- start / finish;
- each named check;
- passed / failed;
- client diagnostics.

A source change after the test invalidates the candidate's verified status.

Do not substitute earlier results.

## Phase 9 — Human presentation candidate

Only after automated verification passes:

- build a separate PLAY artifact from the exact tested source;
- prove script-source identity between TEST and PLAY;
- open PLAY for owner evaluation;
- leave no stale multiplayer test windows;
- archive stale AutoRecovery safely.

Human review should focus on:

- Speed feel;
- treadmill delight;
- camp readability;
- incubator safety;
- pet life / personality;
- Godly spectacle;
- ranch expansion;
- Night beauty and readability;
- neon trail / impact effect;
- hidden-egg search tension;
- shop clarity;
- trading UX.
## Acceptance gate

0.4.0 is an **engineering candidate** only when all of the following are true:

- source is formatted / parses;
- Rojo PLAY build succeeds;
- Rojo TEST build succeeds;
- previous core invariants have equivalent regression coverage;
- all new server-authority invariants pass;
- real two-client Studio suite passes with 0 failures;
- exact source digest is recorded;
- no test-only bypass exists in PLAY;
- no generated Studio artifact is treated as canonical source.

0.4.0 becomes **owner accepted** only after human visual / gameplay review.

## Engineering constraints

- preserve 0.3.2-r2;
- canonical source is repository source;
- no destructive migration of the baseline;
- no publishing;
- no hidden policy-dependent public staking;
- no silent scope expansion;
- no placeholder shop fronts counted as implementation;
- no fake test results;
- no claiming presentation quality from automated tests;
- do not trade correctness for visual polish.

This is a major slice, but it remains one coherent program: make the existing Egg Rivals world feel alive, valuable, magical, and worth mastering.
