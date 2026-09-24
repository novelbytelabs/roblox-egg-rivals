# Egg Rivals — Feature Status Matrix

Purpose: distinguish approved design from implemented and verified behavior.

Status meanings:

- **VERIFIED BASELINE** — present in `MOONWOOD-0.3.2-r2` and covered by the 24/24 engine suite.
- **ENGINEERING VERIFIED / PRESENTATION PENDING** — implemented in the 0.4.0 engineering candidate and covered by exact-source regression; human presentation/gameplay acceptance remains pending where experiential.
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
| Godly rarity | ENGINEERING VERIFIED / PRESENTATION PENDING | Independent top rarity covered by exact-source rules and transfer checks |
| Godly reverence behavior | ENGINEERING VERIFIED / PRESENTATION PENDING | Eligible resident selection and same-element bow routing passed; visual feel remains human-review scope |
| Free new-pet welcome party | ENGINEERING VERIFIED / PRESENTATION PENDING | Batched acquisition behavior passed; presentation feel remains pending |
| Owner homecoming greetings | APPROVED / NOT YET IMPLEMENTED | Pet reactions at base |
| Walk-through pen gate | PARTIAL / REFINEMENT PENDING | Physical pen exists |
| Rich autonomous pet social behavior | PARTIAL / REFINEMENT PENDING | Baseline display exists |
| Ranch Expansion branch | ENGINEERING VERIFIED / PRESENTATION PENDING | 8/12/16/24-slot geometry and duplicate-purchase rejection passed |
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
| Momentum training | ENGINEERING VERIFIED / PRESENTATION PENDING | Integral, threshold and decay behavior passed |
| Visible treadmill modules | APPROVED / NOT YET IMPLEMENTED | Motor/Belt/Cooling/etc. |
| Overdrive | ENGINEERING VERIFIED / PRESENTATION PENDING | Bounds, repeat rejection, expiry and duel/trial restrictions passed |
| Speed Mastery | APPROVED / NOT YET IMPLEMENTED | Control-focused unlocks |
| Training Trials | ENGINEERING VERIFIED / PRESENTATION PENDING | Ordered gates, anti-teleport checks and real-client completion passed |
| Personal ghost racer | ENGINEERING VERIFIED / PRESENTATION PENDING | Replayable personal-best path passed |
| Elemental treadmill tuning | APPROVED / NOT YET IMPLEMENTED | Tactical sidegrades |
| Pet treadmill spectators | PARTIAL / PRESENTATION PENDING | Active pet has an existing training reaction path; richer spectator behavior remains desired |
| Speed milestone celebrations | APPROVED / NOT YET IMPLEMENTED | Major progression moments |
| Machine Grades | ENGINEERING VERIFIED / PRESENTATION PENDING | All seven grade caps and ownership preservation passed |
| Heat/cooling presentation | APPROVED / NOT YET IMPLEMENTED | Nonpunitive |
| Social drafting | APPROVED / NOT YET IMPLEMENTED | Group training bonus |
| Sprint Challenges | APPROVED / NOT YET IMPLEMENTED | Movement rivalry |
| Motion Energy | ENGINEERING VERIFIED / PRESENTATION PENDING | Energy accounting and camp-power behavior passed; presentation feel remains pending |
| Machine personal records | APPROVED / NOT YET IMPLEMENTED | Prestige/status |
| System | Status | Notes |
|---|---|---|
| Night 30x incubation | VERIFIED BASELINE | Existing acceleration |
| No normal egg taking at Night | ENGINEERING VERIFIED / PRESENTATION PENDING | Night dormancy and cross-sunrise ownership checks passed |
| One hidden Night egg | ENGINEERING VERIFIED / PRESENTATION PENDING | Hidden-egg lifecycle and sunrise cleanup passed |
| Environmental Night clues | PARTIAL / PRESENTATION REVIEW | Existing client clue-spark field and server ClueRegion path; earlier absence label was inaccurate |
| Full neon-blacklight transformation | PARTIAL / OWNER REFINEMENT | Lighting and tints already exist; rc2 extends edge coverage and softens bloom |
| Element-specific Night palette | IMPLEMENTED / PRESENTATION PENDING | Existing per-element Night colors; appearance not independently accepted |
| Particle motion trails | ENGINEERING VERIFIED / PRESENTATION PENDING | Client pool reuse/budget checks passed; visual quality remains pending |
| Full-stop collision splatter | ENGINEERING VERIFIED / PRESENTATION PENDING | Contact/full-stop classifier passed; visual quality remains pending |
| Moon Shrine Night clue role | SOURCE PATH PRESENT / REVIEW PENDING | Server Awake/ClueRegion and client clue presentation exist; tuning remains open |
| Night Market | APPROVED / NOT YET IMPLEMENTED | Closed by day |
| Arena neon collision effects | DEFERRED | Revisit with arena polish |
| System | Status | Notes |
|---|---|---|
| Trail Supplies | VERIFIED BASELINE / PARTIAL | Existing snare shop |
| Ranch & Pen Works | ENGINEERING VERIFIED / PRESENTATION PENDING | Ranch expansion transaction and geometry checks passed |
| Trading Post | ENGINEERING VERIFIED / PRESENTATION PENDING | Real timed holds, concurrency, mutation, timeout and disconnect paths passed |
| Exchange | ENGINEERING VERIFIED / PRESENTATION PENDING | Pets, eggs, consumables, Godly holds and stale/departure paths passed |
| Trainer Workshop | ENGINEERING VERIFIED / PRESENTATION PENDING | Grade progression and Speed Lab transaction rules passed |
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

## 0.4.0 engineering candidate status

The 0.4.0 exact-source engineering candidate passed **77/77** checks. Systems with direct mechanical coverage are labeled **ENGINEERING VERIFIED / PRESENTATION PENDING** above.

The original Living World plan intentionally mixed mechanical requirements with experiential aspirations. The green engineering suite does not imply that every presentation goal shipped. Important approved gaps still visible in this matrix include:

- owner homecoming reactions and richer autonomous pet life;
- visible treadmill modules, records, milestones and pet training reactions;
- elemental treadmill tuning, social drafting and Sprint Challenges;
- environmental Night clues, Moon Shrine activation and full blacklight transformation;
- broader ranch habitats, comforts, showcases, themes and visitor expression;
- Night Market, Duel Armory, Pet Outfitter, Quest Board and Elemental Bazaar.

The active gate is owner playtesting of the exact verified candidate. Record findings in `PLAYTEST_0.4.0.md`.

Do not promote presentation-dependent scope to **VERIFIED BASELINE** from engine evidence alone. Human presentation/gameplay acceptance remains a separate gate.

## rc2 owner-feedback refinement

| Requirement | Current engineering status | Scope / brief rubric |
|---|---|---|
| Broad Night edge traces | IMPLEMENTED / REGRESSION PENDING | Supported object edges and smooth contours remain readable without through-wall highlighting |
| Softer bloom | IMPLEMENTED / REGRESSION PENDING | Slightly less intense glow; human appearance review remains separate |
| Longer, denser trails | IMPLEMENTED / REGRESSION PENDING | Longer visual wake while preserving reuse and hard allocation limits |
| Personal flashlight | IMPLEMENTED / REGRESSION PENDING | Free F-toggle light; no battery, purchase or authority mutation |
| Forest egg supply | IMPLEMENTED / REGRESSION PENDING | Twelve nests within the existing footprint |
| Marked Godly opportunity | IMPLEMENTED / REGRESSION PENDING | Real Godly theft target, independent creature roll and longer replacement delay |

Source review corrected several earlier absence claims above. Do not infer missing implementation from an absent test name, and do not infer visual acceptance from existing source. The rc1 77/0 result remains historical for any changed source.
