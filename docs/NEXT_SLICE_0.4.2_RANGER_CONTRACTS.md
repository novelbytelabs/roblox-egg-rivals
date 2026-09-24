# Egg Rivals 0.4.2 — Ranger Contracts + Session Mastery

Status: **ENGINEERING VERIFIED — 99/99 EXACT-SOURCE REGRESSION; OWNER CONTRACT UX / RETENTION REVIEW PENDING**

Purpose: make the existing vertical slice more replayable by giving players short, readable goals that deliberately route them through Egg Rivals systems already present.


## Implementation / verification status

The bounded 0.4.2 implementation is now present and engineering-verified. The final exact-source candidate passed **99/99** checks with one real Studio server and two real clients.

The implementation includes the physical Ranger Station, three varied server-owned contracts, authoritative production-event progress, explicit completion/claim separation, existing-Coin rewards, Coin-ceiling failure preservation, session cleanup, and a real client claim through the rendered contract UI.

Exact evidence: `STAGE3_042_VERIFICATION.md` and `tests/engine-20260924T221303340660Z.json`.

Owner judgment of Contract Board clarity, reward tuning and retention value remains separate from engineering verification.

This slice does **not** add a zone, currency, persistence requirement, battle pass, daily-login mechanic, or paid power.

## Design goals

1. Give a player an immediate answer to “what should I do next?”
2. Reinforce the core loop instead of creating disconnected chores.
3. Encourage use of training, theft, incubation, Night, Grove Circuit and Sprint.
4. Reward play with the existing Coin economy only.
5. Keep progress and reward authority entirely on the server.
6. Make repeated completion impossible.
7. Remain session-only until the future persistence workstream.

## World presence

Add a **Ranger Station / Contract Board** to the existing hub.

The board should be readable as a physical place, not merely a permanent HUD widget.

A nearby prompt opens a compact contract panel showing contract name, one-sentence objective, current progress / target, Coin reward, and COMPLETE / CLAIMED state.

## Contract model

Each player receives three active session contracts.

The server chooses from a fixed catalog after profile setup. Contract IDs, targets, baselines, progress and rewards are server-owned. Initial selection should favor variety across core progression, world/collection, and mastery/rivalry.

No client-supplied progress is accepted.

## Initial contract catalog

### TRAINING — Warm Up
Gain 100 permanent Speed through valid treadmill training. Reward: 40 Coins.

### FOREST — Field Retrieval
Secure one Forest egg into owned inventory or an elemental incubator. Reward: 60 Coins. Failed theft, a dropped egg, or another player's egg does not count.

### HATCHING — New Arrival
Complete one real hatch. Reward: 75 Coins.

### GROVE CIRCUIT — Clean Run
Complete one valid solo Training Trial. Reward: 80 Coins. Invalid or teleported runs do not count.

### MOONRISE — Night Retrieval
Secure the hidden Night egg during its live contest. Reward: 150 Coins. The marked Day Godly nest does not satisfy this contract.

### SPRINT — Finish Together
Complete one valid normalized Sprint Challenge. Reward: 100 Coins. Winning is not required. DNF, cancellation and expired invitations do not count.

## Progress semantics

A contract has `id`, `kind`, `baseline` where needed, `progress`, `target`, `rewardCoins`, `completed`, and `claimed`.

Progress is monotonic. Completion and reward are separate states. A completed contract can be claimed exactly once. Repeated requests, stale UI or reordered client input cannot duplicate Coins.

## Reward semantics

Rewards use existing Coins only. No gems, tickets, Ranger tokens, loot boxes, rarity multipliers, premium currency or permanent paid advantage are introduced.

Reward credit must fail closed at the existing Coin ceiling. A failed claim remains unclaimed so it can be retried after the balance is valid.

## Architecture

Preferred server service: `src/server/Contracts.lua`.

Responsibilities:
- per-player contract initialization;
- fixed catalog/selection;
- authoritative progress evaluation;
- idempotent completion/claim;
- snapshot generation;
- session cleanup.

`Game.lua` remains the composition root.

Use existing authoritative production transitions. If a reusable server-only domain event keeps integration bounded, use one explicit `Contracts:observe(player, event, data)` interface rather than client shadow counters.

Recommended observation points:
- Speed gain from authoritative Speed Lab training;
- Forest egg secure/store/incubation ownership transition;
- real hatch conversion;
- valid solo Trial finish;
- exact hidden Night egg secure transition;
- valid Sprint finish.

## Client

Add a compact Contract Board panel.

The client may request board open, render the server snapshot, and request claim by exact contract ID. The client never supplies progress, completion, target or reward values.

## Failure preservation

Directly test duplicate claim, early claim, unknown/stale ID, Coin ceiling failure, failed/remote egg theft, dropped egg, invalid Trial, canceled/DNF Sprint, exact-once progress, exact-once reward, inventory preservation and session cleanup.

## Regression requirements

Retain all current 90 checks.

Add direct coverage for every implemented contract kind and real client claim input.

Final engineering acceptance requires formatted source, PLAY/TEST builds, script-byte identity, a fresh exact-source one-server/two-client Studio suite, zero failures, exact result/source identities, and no test-only completion path in PLAY.

## Out of scope

Persistent daily/weekly quests, battle pass, login-streak pressure, reroll monetization, premium contracts, new currency, global leaderboard, new zone, procedural quest text and public duel wagering dependency are excluded from this slice.

## Claim boundary

This packet began as the 0.4.2 implementation target. The bounded mechanics are now engineering-verified at 99/99. Contract UX, reward tuning and retention value remain owner-review claims.
