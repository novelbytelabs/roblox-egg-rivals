# Egg Rivals — Decision Ledger

Purpose: preserve explicit approvals, superseded ideas, deferrals, and unresolved questions so implementation cannot silently rewrite the design.

Precedence rule: a later explicit owner decision overrides an earlier conflicting direction.

## Identity and scope

**APPROVED**
- Game name: **Egg Rivals**.
- Current focus: one polished vertical slice before expanding the world.
- Core identity: Speed progression + defended egg theft + elemental hatching + living pet ranch + social economy + optional rivalry.
- PC is the current polished development target.
- Mobile/tablet, Xbox, and PlayStation remain later platform targets.
- VR is out of scope.
- Starter systems should feel complete; upgrades add richness rather than fix intentionally bad starter experiences.

**CURRENT ENGINEERING CANDIDATE**
- `EGG-RIVALS-0.4.1-rc1`.
- Tested source: `25e300647b0c4ba38916f41452c7268d6bb6df76`.
- 90/90 exact-source two-client Studio checks passed.
- 0.4.0-rc2 86/86, rc1 77/77 and `MOONWOOD-0.3.2-r2` 24/24 remain preserved historical references.
- Human presentation / gameplay-feel acceptance remains a distinct gate.

## Rarity

**APPROVED**
`Common -> Uncommon -> Rare -> Epic -> Legendary -> Mythic -> Godly`

Godly is the highest standard rarity.

**SUPERSEDED**
- The earlier standard ladder ending in `Secret`.
- Secret may return only as separately approved event / special content.
## Elemental incubation

**APPROVED**
- Four elements: Fire, Water, Wind, Earth.
- Egg determines creature.
- Incubator determines element.
- Rarity remains independent.
- Four incubators per camp.
- Prefer one incubator in each corner of a square base for separation.
- Multiple elemental incubations can operate independently.
- Placement should be deliberate, not accidental.
- Strong element-specific visual language.
- Result preview such as `Dragon Egg + Fire -> Fire Dragon`.
- Short confirmation / hold interaction is an approved UX direction.
- Visible per-incubator countdowns.
- Stored unhatched eggs preserve creature and rarity.

**VERTICAL-SLICE CREATURE BASELINE**
- Skunk
- Lizard
- Gorilla
- Dragon

The owner approved keeping the initial creature set small; the current verified implementation uses these four.

## Respawn

**APPROVED**
- personal respawn pad at each camp;
- clear and clutter-free placement;
- player returns to their own camp;
- homecoming presentation;
- pets may react to the player's return;
- active pet may approach on respawn.
## Pet pen / ranch

**APPROVED**
- physical pen behind / integrated with base;
- walk-through gate;
- pets can remain visibly in pen instead of all following;
- exactly one active follower;
- penned pets continue generating income;
- resident autonomous behavior;
- inspectable pets / nameplates;
- Favorite / Lock protection;
- safe pet actions: Follow, Pen, Lock, Trade, Exchange, Duel Stake;
- visitor inspection without mutation authority;
- earnings board;
- elemental habitat behavior;
- favorite / showcase positions;
- pet-size-aware facilities;
- owner homecoming reactions;
- free welcoming party for every newly added pet.

**APPROVED PROGRESSION BRANCHES**
- Ranch Expansion;
- Habitat Builder;
- Creature Comforts;
- Showcase Upgrades;
- Pen Manager;
- Visitor Features;
- Celebration Upgrades;
- Pen Themes;
- Large Creature Facilities;
- Pet Activity Upgrades.

**EXPLICITLY EXCLUDED FOR NOW**
- feeding meters;
- breeding;
- health chores;
- happiness maintenance;
- pet decay from neglect.
## Godly pet behavior

**APPROVED**
- ordinary pets keep their distance from Godly pets;
- ordinary pets do not casually play with a Godly pet;
- periodically the Godly pet rises into the air;
- same-element pets stop current behavior;
- same-element pets face and bow to the Godly pet;
- visitors can witness or trigger the reverence event;
- Night may intensify the presentation without changing the core behavior.

## Pen upgrade history

**SUPERSEDED BY THE BRANCHED RANCH SYSTEM**
The earlier simple linear pen upgrade proposal:
- size doubling;
- fence color/material;
- another size doubling;
- daytime 2x hatch;
- admin/dev 15x hatch.

The owner explicitly rejected that sequence as too elementary after approving the richer ranch design.

Do not implement the old linear ladder unless explicitly revived.

## Welcome party

**APPROVED AS FREE BASELINE**
Newly added pet arrives -> residents notice -> gather -> celebrate -> disperse.

Upgrade branches may enhance the presentation with confetti, music, elemental effects, arches, fireworks, and rarity-specific celebrations.
## Speed Lab / treadmill

**APPROVED**
- Momentum training;
- visible machine modules;
- Motor, Belt, Cooling System, Stabilizers, Power Core, Control Unit;
- charged Overdrive used outside training;
- movement mastery unlocks;
- Training Trials;
- personal ghost racing;
- possible friend ghost racing later;
- elemental tuning as tactical sidegrades;
- pet spectators / reactions;
- Speed milestone celebrations;
- treadmill Machine Grades without resetting Speed;
- heat/cooling as visual efficiency tension, not punitive breakdown;
- social drafting when players train together;
- Sprint Challenges;
- Motion Energy that powers camp presentation;
- personal machine records;
- treadmill as visible prestige/status object.

**APPROVED PHYSICS PRINCIPLE**
Permanent Speed maps to controlled avatar movement with bounded scaling.

**SUPERSEDED SPEED MODEL**
The former 300-billion target and 2x / 4x / 6x / 8x / 10x treadmill ladder are abolished.

Canonical Speed/economy values are now defined in `ECONOMY_SPEED_RARITY_V2.md`.

## Sprint rivalry — 0.4.1 verified

**IMPLEMENTED / ENGINEERING VERIFIED**
- explicit nearby two-player Sprint challenge;
- explicit accept / decline;
- normalized WalkSpeed 45 and standard jump settings;
- no Overdrive, permanent-Speed, pet or element movement advantage;
- Grove Circuit gate order and discontinuity / teleport validation shared with Training Trial;
- racer-to-racer body blocking disabled without disabling world collision;
- first valid finish determines winner;
- DNF / death / disconnect cleanup is deterministic;
- session records track entries, wins, DNFs, best time and streaks;
- no item stakes, race currency or Sprint-specific Coin reward;
- real two-client race completion passed exact-source regression.

Evidence: `STAGE3_041_VERIFICATION.md`. Human race feel and presentation remain separate from engineering verification.


## Night mechanics

**APPROVED**
- normal daytime eggs cannot be taken during Night;
- one special high-value Night egg spawns in a random curated hidden location;
- search rather than direct waypoint;
- subtle local environmental clues;
- Night remains mechanically focused;
- existing incubation receives 30x acceleration during Night;
- approximately 4–5 minute common interval;
- hard maximum wait about 10 minutes;
- about 45 seconds baseline duration.

Exact schedule remains balance-tunable.
## Night presentation

**APPROVED**
- full dark neon / blacklight world transformation;
- glowing / fluorescent foliage and signs;
- elemental Night color identities;
- moving glowing objects leave particle trails;
- trail intensity / length scales with meaningful speed;
- the trail itself is particle material;
- genuine full-stop collision converts trail presentation into a neon splatter;
- splatter behaves like colorful firework fragments;
- fragments may change color while dissipating;
- collision emission continues only while the object remains stopped;
- meaningful movement immediately ends impact emission and resumes trail behavior;
- slowing down without a full stop does not qualify.

Approved examples:
- fast player landings;
- pet-play impacts;
- Warden / major world impacts;
- other selective magical collisions.

**DEFERRED**
- arena / RIVALS combat integration of this particle-collision system.

**DESIGN RESTRAINT**
Do not overload Night with mechanics. Visual transformation and hidden-egg search are the center.
## Night atmosphere

**APPROVED DIRECTIONS**
- normal ambient behavior changes / hushes;
- some pets stop and look outward at Night onset;
- camp lights switch to neon mode;
- deeper mysterious audio;
- glowing spores / mist / pulses near hidden-egg region;
- Moon Shrine visually awakens and may offer vague clues;
- Godly reverence becomes visually stronger at Night;
- Night Market opens physically only at Night.

## Hub locations

**APPROVED**
- Trail Supplies
- Ranch & Pen Works
- Trading Post
- Night Market
- Trainer Workshop
- Duel Armory
- Pet Outfitter
- Exchange
- Quest Board / Ranger Station
- Elemental Bazaar

**EXPLICITLY REJECTED**
- Egg Appraiser

**EXCHANGE CLARIFICATION**
Exchange supports items, eggs, and pets; it is not a duplicate-only system.
## Trading and social economy

**APPROVED**
- exact two-sided offers;
- both players confirm;
- changing an offer invalidates confirmation;
- locked items are protected;
- server validates and atomically transfers;
- disconnect / cancellation cannot duplicate or delete inventory.

Night Market aids discovery but does not reveal the exact hidden egg.

Duel Armory should focus on balanced sidegrades and cosmetics, not paid raw power.

Pet Outfitter is cosmetic.

Quest Board objectives should reinforce existing systems.

Elemental Bazaar reinforces elemental identity without four separate pay-to-win economies.

## Open-world interference

**APPROVED**
- Bat contests egg carriers;
- valid hit drops egg;
- defender physically attempts recovery;
- another player may steal dropped egg first;
- Snare temporarily slows carriers;
- safe zones disable hostile interference;
- permanent inventory is not deleted by ordinary open-world PvP.

**LATER-COMPATIBLE DIRECTIONS**
- launch-pad traps;
- temporary barriers.
## Duels

**APPROVED**
- opt-in challenge;
- Accept / Decline;
- exact player-selected item offer;
- both offers visible;
- both players explicitly confirm;
- server escrow;
- isolated arena;
- skill-forward DuelBlaster baseline;
- first to 5 eliminations;
- server-owned score and damage validation;
- cover blocks shots;
- winner receives agreed stakes in Studio test architecture;
- transferred pets default to winner's pen;
- deterministic timeout / disconnect handling.

**FAIRNESS**
Competitive loadouts should be sidegrades / styles. Robux must not directly purchase superior duel power.

**PUBLICATION GATE**
Public item-transfer duel behavior requires a current Roblox policy review before release. Studio-only staking remains the development baseline until that review.

## Live operations

**APPROVED / COMPATIBLE BASELINE**
- Night;
- Egg Rush;
- Speed Surge;
- Giant Egg Invasion;
- Rare Rain;
- controlled playful admin events.

Live events should create temporary excitement without invalidating permanent progression.
## World / zone philosophy

**APPROVED**
- no hard Speed entry gates;
- zones can advertise recommended Speed;
- difficult defender / route design creates practical progression;
- slower players remain free to attempt harder content;
- carrying an egg does not reduce Speed;
- compact polished vertical slice before large map expansion.

Earlier zone concepts such as Forest, Lake, Desert, Jungle, Arctic, Volcano, and later endgame areas remain compatible long-term world directions, not immediate build requirements.

## Development discipline

**APPROVED**
- preserve verified builds as recoverable references;
- canonical source lives in the repository, not Studio recovery files;
- generated `.rbxlx` files are artifacts;
- do not silently claim a later candidate inherits an earlier test result;
- multiplayer regression is required after bounded implementation batches;
- human gameplay / appearance acceptance remains separate from automated engineering verification.

## Ambiguity resolution status

The former treadmill and economy ambiguity queue was resolved for 0.4.0.

Canonical resolutions are in:
- ECONOMY_SPEED_RARITY_V2.md
- RESOLVED_DESIGN_DECISIONS_0.4.0.md

The 300-billion Speed target, ambiguous 5x/10x ladder, and typed 25,0000 price are abolished.

Public duel staking remains a policy-gated future deployment question, not a 0.4.0 design ambiguity.

## Historical balance preservation

Earlier zone, rarity-weight, hatch-time, income-multiplier, treadmill, and Night-spawn numbers are preserved in `WORLD_AND_BALANCE_REFERENCES.md`.

Those values are historical references where later decisions supersede them.

In particular, the earlier approximately 80% Legendary / 20% Mythic Night special-spawn mix is superseded by the newer one-hidden-Night-egg rule. The hidden egg's final rarity distribution remains unresolved.

## 0.4.0 resolution packet adopted

The owner approved the assistant's proposed ambiguity resolutions and authorized forward planning on that basis.

Canonical implementation decisions are therefore the values and rules in:

- `RESOLVED_DESIGN_DECISIONS_0.4.0.md`;
- `ECONOMY_SPEED_RARITY_V2.md`;
- `NEXT_SLICE_0.4.0_LIVING_WORLD.md`.

These later documents supersede conflicting earlier Speed, treadmill, rarity, Night-transition, trading, Exchange, and ranch-capacity assumptions.

The next authorized planning target is a major multi-hour 0.4.0 Living World + Progression slice. This authorization does not authorize merging an implementation branch into `main` without owner review.

## 2026-09-24 owner playtest direction — Night and Forest

The owner accepts the existing build as adequate for continued mechanics-first development. Small refinements remain expected. No merge or public publication follows from that statement.

New authorized changes: broad neon object-edge coverage, slightly softer glow, longer/denser trails, a player flashlight, and more Forest eggs including Godly availability.

The rc2 implementation uses twelve Forest nests with one marked Godly target and a 600-second replacement delay after removal. These are implementation-selected initial tuning values. The dedicated nest is not a shop, does not award an item automatically, and uses ordinary server-validated theft, carrying, storage and incubation. Creature selection remains independent; normal rarity-roll tables are unchanged. Overall Godly supply is deliberately higher, so prior aggregate rarity expectations no longer describe this dedicated encounter.

The hidden Night egg remains a separate single-egg event. All ordinary Forest nests, including the marked Godly nest, become dormant at Night. An already-carried egg survives the transition.

Current candidate and evidence status is in `tests/CANDIDATE_STATUS.json`. The rc2 86/86 result remains historical and was not substituted by the later 0.4.1 90/90 Sprint candidate. Owner presentation review and later design obligations remain distinct from engineering verification.
