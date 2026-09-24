# Egg Rivals 0.4.1 — Sprint Rivalry engineering verification

Candidate: `EGG-RIVALS-0.4.1-rc1`  
Tested source commit: `25e300647b0c4ba38916f41452c7268d6bb6df76`  
Evidence commit: `cd80d0f01c880f6295b08926278e7dbc904b1b1a`  
Source digest: `84225f0b18b3886fa2d8a0cd0c2f8aa46b5438064b2fa3529a08b63cb6ab6a74`  
Status: **ENGINEERING CANDIDATE VERIFIED; OWNER SPRINT FEEL REVIEW PENDING**.

The fresh exact-source Studio regression completed **90 checks in 189 seconds: 90 passed, 0 failed**. The run used one real Studio test server and two real Studio clients.

## Exact evidence

- Engine result: `tests/engine-20260924T172227857145Z.json`
- Engine result SHA-256: `cd5fcb9b13350ee646c29c9063ac95047eb6abad5787c7e2ae8238b7418bcd25`
- PLAY artifact SHA-256: `6eacf53ec18f4b0cbf770d754401dc0ac93254934daaad0f2d66099021067a66`
- TEST artifact SHA-256: `75f7d965ef0a393799d6f5e128f2e499b32d9d9ea0276a7dcd4783fbc9738910`
- PLAY/TEST gameplay scripts: 34 byte-identical scripts
- Source unchanged after the run: yes
- Real topology: one server + two clients
- Foreground START cue: exit 0
- Foreground DONE cue: exit 0
- Background open cue: exit 0
- Background close cue: exit 0

## Sprint coverage

The suite directly covers explicit nearby challenge/decline, real client acceptance, server countdown, normalized WalkSpeed 45, Overdrive rejection without charge consumption, shared Grove Circuit gate validation, teleport/discontinuity DNF, real two-client finish, session record updates, racer collision fairness, exact inventory preservation, and no Sprint-specific Coin mutation while normal passive pet income continues.

The final economy regression integrates the same Heartbeat time used by passive income and compares `Coins + coinRemainder` with expected passive accrual. It does not pause or bypass the ordinary pet economy to get a green result.

## Preserved failure

`tests/engine-20260924T164642785506Z.json` remains preserved at **89 passed / 1 failed**. Both real Sprint clients completed successfully in that run, but the test incorrectly expected raw Coin balances to remain unchanged while passive pet income was active. The repair changed test isolation, not Sprint gameplay behavior.

## Launch note

The final candidate's first background Studio launch attempt exited during Wine setup before a Studio window or foreground input existed. The same exact execution copy was retried through the established background-launch path and produced the 90/90 result.

## Claim boundary

Engineering verification establishes the mechanical Sprint candidate and retained regressions. It does not establish that the Sprint challenge UI, countdown, route feel, or race pacing are fun or presentation-accepted.

Nothing was merged to `main` and nothing was published to Roblox.
