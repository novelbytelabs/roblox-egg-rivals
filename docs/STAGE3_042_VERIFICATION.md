# Egg Rivals 0.4.2 — Ranger Contracts engineering verification

Candidate: `EGG-RIVALS-0.4.2-rc1`
Tested source commit: `d0c14e6742b7cc14ddb4680a1fd9cd2dca5f7a1e`
Source digest: `87eaaa043f0dfae29585887fbd0bdf2dd8157fe6072c5052339c65c9dd29612c`
Status: **ENGINEERING CANDIDATE VERIFIED; OWNER CONTRACT UX / RETENTION REVIEW PENDING**.

The fresh exact-source Studio regression completed **99 checks in 196 seconds: 99 passed, 0 failed**. The run used one real Studio test server and two real Studio clients.

## Ranger Contracts coverage

The suite directly covers:

- physical Ranger Station with exactly three varied server-owned session contracts;
- authoritative Warm Up progress from real Speed Lab training;
- distinct Forest and hidden-Night retrieval semantics;
- real stored Forest and hidden Night eggs advancing only matching contracts;
- hatch, solo Trial and Sprint completion through authoritative production events;
- monotonic progress and exact-once completion;
- early, stale, unknown and duplicate claim rejection;
- Coin-ceiling failure preserving an unclaimed completed reward;
- session cleanup and fresh contract reconstruction;
- a real client opening the rendered Contract Board and clicking the exact completed contract claim;
- exact-once Coin reward without client-supplied progress, target or reward values.

The final candidate retains all prior 0.4.1 Sprint Rivalry, 0.4.0 Night/Forest, Trading Post, Exchange, ranch, Warden, incubation, duel, Trial and core-loop regressions.

## Exact evidence

- Engine result: `tests/engine-20260924T221303340660Z.json`
- Engine-result SHA-256: `2a3cf5714f740b7c66a74641f193924641332bff8dfc588e9b682df335f20740`
- PLAY artifact SHA-256: `e496ef91286db83c9a4456416a58f6bc25e9e59a19550e76e0a77de2a0a8792a`
- TEST artifact SHA-256: `6eddfe5e12aeba863d4772d94c64f75ba16a88e0cde0ddaba01743217305e36a`
- PLAY/TEST gameplay scripts: 36 byte-identical scripts
- Source unchanged after run: yes
- Real topology: one server + two clients
- Background OPEN cue: exit 0 before Studio launch
- Foreground START cue: exit 0 before F7 input
- Foreground DONE cue: exit 0 immediately after Stop
- Background CLOSE cue: exit 0 immediately after Studio close

## Preserved failures

Two complete 0.4.2 runs remain preserved:

- `tests/engine-20260924T192322556412Z.json`: 96 passed / 3 failed. The real Sprint acceptance fixture, Ranger retrieval fixture and rendered contract panel exposed synchronization defects.
- `tests/engine-20260924T205055541979Z.json`: 96 passed / 3 failed. Both racers physically completed, but passive-income observation had Heartbeat-boundary ambiguity; the retained duel timeout fixture used a fixed positioning delay; and the Ranger claim probe observed stale rendered contract state.

The final repair did **not** change trade range, Sprint economy, passive-income behavior, contract rewards, contract authority or client claim semantics. It synchronized test positioning/render state and bounded passive-income audit uncertainty tightly enough to still detect the smallest 40-Coin Ranger reward.

## Claim boundary

Engineering verification establishes the session-contract mechanics and retained regressions. It does not establish that contract selection, reward tuning, board presentation or session-retention value are fun or owner-accepted.

Progress remains session-only. Nothing was merged to `main` and nothing was published to Roblox.
