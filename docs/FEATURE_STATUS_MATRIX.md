# Egg Rivals — Feature Status Matrix

Purpose: distinguish approved design from implemented and verified behavior.

Status meanings:

- **VERIFIED BASELINE** — present in `MOONWOOD-0.3.2-r2` and covered by the 24/24 engine suite.
- **APPROVED / NOT YET IMPLEMENTED** — canonical design direction, but not part of the verified baseline.
- **PARTIAL / REFINEMENT PENDING** — a simpler baseline exists, but the newly approved design extends or changes it.
- **DEFERRED** — intentionally postponed.
- **EXCLUDED** — explicitly out of scope unless later revived.

| System | Status | Notes |
|---|---|---|
| Four elemental incubators | VERIFIED BASELINE | Fire, Water, Wind, Earth |
| Four simultaneous incubations | VERIFIED BASELINE | Independent elemental slots |
| Creature + element separation | VERIFIED BASELINE | Egg creature, incubator element |
| Skunk / Lizard / Gorilla / Dragon | VERIFIED BASELINE | Current slice set |
| Personal respawn | VERIFIED BASELINE | Actual death/respawn tested |
| Stored unhatched eggs | VERIFIED BASELINE | Creature identity preserved |
| One active pet + penned pets | VERIFIED BASELINE | Server-authoritative state |
| Penned pet income | VERIFIED BASELINE | Income preserved |
| Pen paging / overflow ownership | VERIFIED BASELINE | No pet deletion |
| Bat and Snare | VERIFIED BASELINE | Multiplayer regression passed |
| Warden pursuit/navigation | VERIFIED BASELINE | Collision-routing regression passed |
| First-to-five DuelBlaster duel | VERIFIED BASELINE | Studio staking architecture tested |
| System | Status | Notes |
|---|---|---|
| Godly rarity | APPROVED / NOT YET IMPLEMENTED | New top standard rarity |
| Godly reverence behavior | APPROVED / NOT YET IMPLEMENTED | Same-element pets bow |
| Free new-pet welcome party | APPROVED / NOT YET IMPLEMENTED | Ranch social behavior |
| Owner homecoming greetings | APPROVED / NOT YET IMPLEMENTED | Pet reactions at base |
| Walk-through pen gate | PARTIAL / REFINEMENT PENDING | Physical pen exists |
| Rich autonomous pet social behavior | PARTIAL / REFINEMENT PENDING | Baseline display exists |
| Ranch Expansion branch | APPROVED / NOT YET IMPLEMENTED | Physical sections |
| Habitat Builder | APPROVED / NOT YET IMPLEMENTED | Elemental habitats |
| Creature Comforts | APPROVED / NOT YET IMPLEMENTED | Toys/beds/pools/etc. |
| Showcase Upgrades | APPROVED / NOT YET IMPLEMENTED | Featured pets/podiums |
| Pen Manager | APPROVED / NOT YET IMPLEMENTED | Sorting/groups/automation |
| Visitor Features | APPROVED / NOT YET IMPLEMENTED | Inspect/reactions/trade entry |
| Celebration Upgrades | APPROVED / NOT YET IMPLEMENTED | Enhanced welcome events |
| Pen Themes | APPROVED / NOT YET IMPLEMENTED | Ranch aesthetics |
| Large Creature Facilities | APPROVED / NOT YET IMPLEMENTED | Giant stalls/caves/paddocks |
| Pet Activity Upgrades | APPROVED / NOT YET IMPLEMENTED | Rich play routines |
| System | Status | Notes |
|---|---|---|
| Momentum training | APPROVED / NOT YET IMPLEMENTED | Speed Lab |
| Visible treadmill modules | APPROVED / NOT YET IMPLEMENTED | Motor/Belt/Cooling/etc. |
| Overdrive | APPROVED / NOT YET IMPLEMENTED | Earn through training |
| Speed Mastery | APPROVED / NOT YET IMPLEMENTED | Control-focused unlocks |
| Training Trials | APPROVED / NOT YET IMPLEMENTED | Timed movement gates |
| Personal ghost racer | APPROVED / NOT YET IMPLEMENTED | Race best run |
| Elemental treadmill tuning | APPROVED / NOT YET IMPLEMENTED | Tactical sidegrades |
| Pet treadmill spectators | APPROVED / NOT YET IMPLEMENTED | Ranch reaction |
| Speed milestone celebrations | APPROVED / NOT YET IMPLEMENTED | Major progression moments |
| Machine Grades | APPROVED / NOT YET IMPLEMENTED | No Speed reset |
| Heat/cooling presentation | APPROVED / NOT YET IMPLEMENTED | Nonpunitive |
| Social drafting | APPROVED / NOT YET IMPLEMENTED | Group training bonus |
| Sprint Challenges | APPROVED / NOT YET IMPLEMENTED | Movement rivalry |
| Motion Energy | APPROVED / NOT YET IMPLEMENTED | Powers camp presentation |
| Machine personal records | APPROVED / NOT YET IMPLEMENTED | Prestige/status |
| System | Status | Notes |
|---|---|---|
| Night 30x incubation | VERIFIED BASELINE | Existing acceleration |
| No normal egg taking at Night | APPROVED / NOT YET IMPLEMENTED | Newer Night rule |
| One hidden Night egg | APPROVED / NOT YET IMPLEMENTED | Random curated hiding spot |
| Environmental Night clues | APPROVED / NOT YET IMPLEMENTED | No exact waypoint |
| Full neon-blacklight transformation | APPROVED / NOT YET IMPLEMENTED | Major visual pass |
| Element-specific Night palette | APPROVED / NOT YET IMPLEMENTED | Fire/Water/Wind/Earth |
| Particle motion trails | APPROVED / NOT YET IMPLEMENTED | Speed-scaled |
| Full-stop collision splatter | APPROVED / NOT YET IMPLEMENTED | Trail material becomes burst |
| Moon Shrine Night clue role | APPROVED / NOT YET IMPLEMENTED | Exact clue strength tunable |
| Night Market | APPROVED / NOT YET IMPLEMENTED | Closed by day |
| Arena neon collision effects | DEFERRED | Revisit with arena polish |
| System | Status | Notes |
|---|---|---|
| Trail Supplies | VERIFIED BASELINE / PARTIAL | Existing snare shop |
| Ranch & Pen Works | APPROVED / NOT YET IMPLEMENTED | Ranch progression |
| Trading Post | APPROVED / NOT YET IMPLEMENTED | Safe two-sided trade |
| Exchange | APPROVED / NOT YET IMPLEMENTED | Items, eggs, pets |
| Trainer Workshop | APPROVED / NOT YET IMPLEMENTED | Speed Lab progression |
| Duel Armory | APPROVED / NOT YET IMPLEMENTED | Balanced sidegrades/cosmetics |
| Pet Outfitter | APPROVED / NOT YET IMPLEMENTED | Cosmetics |
| Quest Board / Ranger Station | APPROVED / NOT YET IMPLEMENTED | Rotating core-loop objectives |
| Elemental Bazaar | APPROVED / NOT YET IMPLEMENTED | Elemental cosmetics/habitats |
| Egg Appraiser | EXCLUDED | Explicitly rejected |
| Public item-transfer staking | DEFERRED / POLICY GATE | Requires current Roblox review |
| Persistence | DEFERRED TO MVP | Current build session-only |
| Mobile/tablet controls | DEFERRED TO MVP/LATER | PC first |
| Xbox / PlayStation controls | DEFERRED TO MVP/LATER | PC first |
| VR | EXCLUDED | Out of scope |
| Feeding/breeding/health chores | EXCLUDED | Do not turn ranch into maintenance sim |
## Governance

A feature moving from **APPROVED** to **VERIFIED BASELINE** requires:

1. a bounded implementation candidate;
2. preserved prior verified reference;
3. source-level review;
4. relevant automated / multiplayer regression;
5. explicit evidence tied to the exact candidate;
6. human presentation / gameplay acceptance where the feature is experiential.

Do not update this matrix from aspiration alone.
