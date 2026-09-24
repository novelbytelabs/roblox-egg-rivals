# Egg Rivals 0.4.1 — Sprint Rivalry + Progression Feedback

Status: **ENGINEERING VERIFIED — 90/90 EXACT-SOURCE REGRESSION; OWNER FEEL REVIEW PENDING**

Purpose: add a second skill-forward rivalry mode without creating a new zone, economy, weapon system, or progression reset.

## Implementation / verification status

The 0.4.1 implementation is now present and engineering-verified. The final exact-source candidate passed **90/90** checks with one real Studio server and two real clients.

Sprint reuses the shared Grove Circuit route validator, applies normalized movement, records session results, suppresses racer body-blocking without disabling world collision, and creates no stakes or race currency.

Exact evidence: `STAGE3_041_VERIFICATION.md` and `tests/engine-20260924T172227857145Z.json`.

Owner race feel, UI clarity and pacing remain playtest questions rather than engineering claims.

This packet follows the owner's mechanics-first direction. It reuses the already-validated Grove Circuit and Trial movement rules rather than creating a competing race framework.

## Design goals

1. Make "Rivals" mean more than gun combat.
2. Let two players compete on movement skill under equal physical settings.
3. Reuse the Grove Circuit's gate order, anti-teleport validation, timeout and movement sampling.
4. Keep permanent Speed meaningful elsewhere without deciding normalized races through accumulated stats.
5. Produce session records and bragging value, not economic power.

## Sprint Challenge v1

### Challenge flow

- A player may challenge one nearby eligible player with a dedicated **Sprint** interaction.
- Duel challenge and Sprint challenge remain separate actions.
- Recommended control: `T` for the player Sprint prompt. `R` remains Duel.
- Target receives explicit Accept / Decline with challenger name and "Normalized race • no stakes".
- Request expires after 20 seconds.
- Both players must remain eligible through acceptance.

### Eligibility

A participant must:

- be alive;
- not be in a duel, trade, Exchange, incubation confirmation or Training Trial;
- not be carrying an egg;
- be within challenge range when requested;
- be within the Grove Circuit start area when the race actually arms.

A changed/invalid state cancels cleanly.

### Normalized movement

During an active Sprint Challenge:

- WalkSpeed = 45;
- standard jump settings;
- Overdrive disabled and not consumed;
- no permanent-Speed movement advantage;
- no pet movement bonus;
- no elemental movement bonus;
- no Snare/Bat effect on race participants;
- no item stakes;
- no Coins, premium currency or inventory reward.

Permanent Speed remains visible progression in the open world and ordinary training.

### Start

After both players accept and reach the start area:

1. server records both exact participants;
2. both are placed on two small start offsets facing Gate 1;
3. movement is locked during a 3-second server countdown;
4. one server timestamp starts both competitors;
5. normalized movement is applied simultaneously.

The race may use separate starting offsets, but both competitors follow the same route and gate centers.

### Route validation

Reuse the Grove Circuit's existing invariants:

- ordered gates;
- real player-root proximity;
- discontinuity / teleport rejection;
- timeout;
- normalized speed envelope;
- server-owned gate advancement.

Do not create a weaker "race-only" validator.

A racer who becomes invalid receives DNF. An invalid attempt cannot create a record.

### Winner

The first valid participant to complete the final gate after the shared start wins.

Server records:

- winner user ID;
- loser user ID;
- each valid finish time if available;
- DNF reason when applicable.

The first valid finish may establish the winner immediately, but cleanup must remain deterministic for the other participant.

### Collision fairness

Racers should not body-block one another.

Implementation should use a dedicated Roblox collision group for active Sprint racers:

- racer ↔ racer collision disabled;
- racer ↔ world collision preserved;
- collision assignment restored on finish/cancel/respawn/disconnect.

Do not disable normal world collision by setting character parts non-collidable.

### Session records

Extend the existing Speed Lab/session record surface rather than creating a new currency.

Candidate records:

- Sprint races entered;
- Sprint wins;
- Sprint DNFs;
- best valid Sprint time;
- current win streak;
- best win streak.

No persistence is required for this slice.

### Presentation

Minimum readable presentation:

- challenge panel identifies opponent;
- countdown: 3 / 2 / 1 / GO;
- active HUD shows opponent, elapsed time and next gate;
- finish shows WIN / LOSS / DNF and both times when valid;
- Trainer/Speed Lab record surface exposes Sprint wins and best time.

Presentation must not obscure movement.

## Architecture

### New server service

Preferred: `src/server/Sprint.lua`.

Responsibilities:

- invitation lifecycle;
- eligibility/revalidation;
- shared session identity;
- shared countdown/start timestamp;
- winner/DNF resolution;
- disconnect/respawn cleanup;
- session records.

### Reuse Trials

Do not copy the Trial movement validator.

Refactor `Trials.lua` only as much as needed to expose a reusable normalized route-run primitive for:

- solo Training Trial;
- Sprint participant.

Shared validation should own gate order, movement continuity, timeout and sampling.

Solo ghost behavior remains solo-only unless later explicitly extended.

### Game integration

`Game.lua` remains the composition root.

Sprint state must participate in the busy/eligibility model so a player cannot simultaneously enter:

- duel;
- trade;
- Exchange;
- Training Trial;
- Sprint;
- incubation confirmation.

### Client

Add only the UI/input needed for explicit challenge/acceptance and race status.

Do not infer a race from proximity alone.

## Failure preservation

Required paths:

- self challenge;
- target out of range;
- target becomes busy before acceptance;
- challenger starts carrying an egg before acceptance;
- participant leaves start area before countdown;
- disconnect before start;
- disconnect during race;
- death/respawn;
- out-of-order gate;
- teleport/discontinuous movement;
- timeout;
- simultaneous/near-simultaneous finish;
- duplicate accept/request;
- stale session ID;
- Overdrive attempt during race;
- item/Bat/Snare attempts against race state.

Every path returns both players to valid open-world state and preserves inventory/economy.

## Verification target

Do not claim Sprint Challenge implemented from unit/state checks alone.

Add direct checks for:

- exact two-player invitation;
- explicit accept/decline;
- shared start timestamp;
- equal WalkSpeed 45;
- Overdrive rejection without charge consumption;
- ordered real movement through gates;
- teleport rejection;
- first valid finish winner;
- DNF cleanup;
- disconnect cleanup;
- session record update exactly once;
- no inventory/Coins mutation;
- no regression to solo Training Trial or personal ghost.

Final acceptance requires a fresh exact-source one-server/two-client Studio run with zero failures.

## Out of scope

- persistent leaderboards;
- friend ghosts;
- Open Class permanent-Speed racing;
- race wagering;
- race currency;
- Robux power;
- additional courses;
- new zones;
- vehicles;
- matchmaking queues;
- more than two racers.

## Claim boundary

This document began as the implementation design packet. The bounded implementation is now engineering-verified at 90/90. Human race feel, presentation quality and longer-term retention value remain separate claims.
