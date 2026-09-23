# Astra Execution Packet — Egg Rivals 0.4.0

Purpose: execute the major Living World + Progression slice autonomously for multiple hours while preserving evidence and scope.

## Binding sources

Read before editing:

1. `README.md`
2. `docs/GAME_DESIGN.md`
3. `docs/DESIGN_BIBLE.md`
4. `docs/DECISION_LEDGER.md`
5. `docs/RESOLVED_DESIGN_DECISIONS_0.4.0.md`
6. `docs/ECONOMY_SPEED_RARITY_V2.md`
7. `docs/NEXT_SLICE_0.4.0_LIVING_WORLD.md`
8. `docs/FEATURE_STATUS_MATRIX.md`
9. `docs/STAGE3_032_VERIFICATION.md`
10. relevant system docs for Night, ranch, Speed Lab, incubation, shops, and PvP.

If a later canonical document conflicts with an older historical document, the later explicit decision wins.

Do not reinterpret superseded 300-billion Speed or 2x/4x/6x/8x/10x treadmill ideas as current requirements.

## Mission

Implement `EGG-RIVALS-0.4.0 — LIVING WORLD` from the exact current repository baseline.

This is a large implementation task. Continue through the phases until a real blocker, exhausted authorization, or completed engineering verification.

Do not stop merely because one subsystem works.
## Required repository discipline

- Reconcile `main` with `origin/main`.
- Record exact starting commit.
- Work on branch `feature/0.4.0-living-world`.
- Never rewrite or force-push `main`.
- Preserve the 0.3.2-r2 reference.
- Canonical code lives under repository source, not generated Studio files.
- Do not commit generated `.rbxlx`, AutoRecovery, `site/`, or transient output.
- Keep changes coherent and reviewable.
- Commit at meaningful phase boundaries.
- Push the feature branch after coherent milestones and at the final safe boundary.

If the branch already exists, reconcile it rather than creating a competing implementation branch.

## Scope authority

Implement only the scope in `NEXT_SLICE_0.4.0_LIVING_WORLD.md`.

Do not add new zones, new creature families, breeding, extra currencies, public staking, arena expansion, or unrelated shops.

Do not substitute placeholders and claim completion.

A shop is only "implemented" if its approved transaction actually works end-to-end.

## Phase order

Proceed in this order unless dependency evidence requires a small local reorder:

0. baseline freeze / source map;
1. schema + economy v2;
2. Speed Lab v2;
3. camp + incubator v2;
4. Living Ranch v1;
5. Night 2.0;
6. Trainer Workshop / Ranch & Pen Works / Exchange / Trading Post;
7. source/static/build validation;
8. real two-client Studio regression;
9. exact-source PLAY candidate for human review.

Do not begin phase 8 while known phase 1–7 correctness failures remain.
## Implementation invariants

### Ownership
At every point, every egg/pet/item instance is in exactly one valid ownership/reservation state.

No trade, Exchange, duel, disconnect, Night transition, or pen action may duplicate or orphan an instance.

### Speed
Permanent Speed is 0..10,000 for this slice.

Use the canonical bounded movement mapping.

Grade ceilings are authoritative.

Overdrive cannot exceed 68 studs/s.

Duel arena disables Overdrive.

### Rarity
Creature, rarity, and element are independent.

Godly is a real rarity, not a renamed Mythic.

Day weights and Night weights must validate exactly.

### Ranch
Only one active follower.

Overflow pets remain owned and earning.

Welcome and reverence events cannot mutate ownership or economy.

Godly social behavior must not spam.

### Night
Ordinary Day eggs cannot be newly picked up at Night.

A Day egg already carried before transition remains valid.

Exactly one hidden Night egg exists per Night event.

Unclaimed hidden egg despawns at Day.

An already active Night-egg contest resolves normally across sunrise.
## Visual-performance rules

Night particle systems are client presentation.

Do not use server physics objects for decorative particle fragments.

Use bounded emitters / pooling / quality controls.

Do not create one Heartbeat connection per pet or per particle.

Pet behavior scheduling must be bounded.

Avoid unbounded PathfindingService calls for ranch pets.

The game must remain playable with multiple visible pets and two Studio clients.

## UI rules

Use clear world interaction before unnecessary modal UI.

Critical confirmations must show the exact target and result.

Incubator confirmation shows:

- creature;
- rarity;
- selected element;
- hatch duration.

Trade confirmation shows exact instance-level items on both sides.

Godly transfer and Exchange use the required extra hold confirmation.

UI must not silently confirm when focus changes or input is repeated.
## Testing rules

Exercise real production paths.

Test-only hooks may control time/random seeds where necessary, but must not bypass the production transaction / validation logic being tested.

Do not create a fake "pass" oracle disconnected from behavior.

Preserve failed evidence.

When a test fails:

1. record the exact failure;
2. identify whether code or test expectation is wrong;
3. make the smallest justified fix;
4. rerun relevant local checks;
5. later rerun the complete candidate suite.

Never delete an inconvenient regression check merely to reach green.

## Required evidence

For the final candidate, preserve:

- exact Git commit;
- exact source digest;
- static/format results;
- Rojo PLAY build result;
- Rojo TEST build result;
- complete engine-result JSON;
- named checks with pass/fail;
- client diagnostics;
- exact PLAY and TEST artifact hashes;
- proof that PLAY and TEST contain the same gameplay scripts except test harness/config differences;
- concise limitations / human-review boundary.

Do not claim human visual quality from automated evidence.
## Failure-preservation requirements

The following paths must be explicitly tested:

- Speed grade purchase with insufficient Coins;
- training at grade ceiling;
- Overdrive spam / repeated activation;
- invalid incubator ownership;
- wrong / stale selected egg;
- Night transition while carrying Day egg;
- hidden Night egg unclaimed at sunrise;
- welcome event while another event is active;
- multiple Godly pets;
- visitor reverence spam;
- Exchange of locked / active / reserved item;
- trade offer mutation after confirmation;
- trade disconnect before commit;
- trade disconnect during final confirm;
- stale trade instance ID;
- duplicate trade request;
- ranch expansion purchase twice;
- overflow pet display;
- existing Bat / Snare / Warden / duel regressions.

Every failure path ends in a valid authoritative state.

## Completion definition

Do not report `0.4.0 verified` until:

- full exact-source suite passes with 0 failures;
- source has not changed after that run;
- final artifacts are generated from that same source;
- evidence is written to the repository;
- feature status matrix is updated accurately.

If human presentation review has not happened, report:

`ENGINEERING CANDIDATE VERIFIED; HUMAN PRESENTATION ACCEPTANCE PENDING`

not "complete" or "released."
## Final handoff

At the safe final boundary provide:

- branch;
- exact HEAD;
- commits by phase;
- what changed;
- test/build results;
- artifact locations;
- remaining limitations;
- any tuning values that need owner feel-testing;
- the single next action for the owner.

Do not publish the Roblox experience.

Do not merge the feature branch to `main` without explicit owner authorization after review.

The desired outcome is a large, coherent, tested advancement of the existing Egg Rivals world, not a broad pile of partially connected features.
