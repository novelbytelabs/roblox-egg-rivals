# Egg Rivals 0.4.3 — Elemental Tuning engineering verification

Candidate: `EGG-RIVALS-0.4.3-rc1`  
Exact tested source bytes committed at: `f4be2411712ffec3f3dfd8c23f69dea7307a45d1`  
Source digest: `0875af46f723f9a964062a3d255d126450934438dc91699d1f76a066eef648be`  
Status: **ENGINEERING CANDIDATE VERIFIED; OWNER ELEMENTAL TUNING FEEL REVIEW PENDING**.

The fresh exact-source Studio regression completed **104 checks in 198 seconds: 104 passed, 0 failed**. The run used one real Studio test server and two real Studio clients.

## Elemental Tuning coverage

The suite directly covers:

- Standard reproducing the verified Speed Lab baseline;
- Fire, Water, Wind and Earth as bounded sidegrades with explicit benefit/tradeoff pairs;
- invalid tuning identities failing closed;
- free server-owned selection with no tuning reward or purchase path;
- no mutation of pet income or inventory authority;
- switching blocked by stored Momentum, stored Overdrive charge or an active burst;
- switching limited to the owner's Speed Lab or Trainer Workshop;
- Wind producing a stronger, shorter open-world burst without exceeding the 68 studs/s cap;
- Training Trial and Sprint remaining normalized at WalkSpeed 45;
- one real client selecting Water through the rendered Trainer UI and observing authoritative server state;
- all retained 0.4.2 Ranger, 0.4.1 Sprint, Night/Forest, trading, Exchange, ranch, Warden, incubation, duel and Trial regressions.

Passive pet income remains live during tests. Coin audits compare `Coins + coinRemainder` with expected passive accrual rather than pausing production economy behavior.

## Exact evidence

- Engine result: `tests/engine-20260925T012102080077Z.json`
- Engine-result SHA-256: `9367396993c03c313762a0a54501a83574bb53e4b258c188fe264cf071ccf4b1`
- PLAY artifact SHA-256: `a6c5f025f18d6f721e42200a65960c7a81594b8b8fcea91204b65c9874b73c03`
- TEST artifact SHA-256: `cc669075256750e082084e3fa7c7270f8181b85cb668a46ef8030cc3f666346a`
- PLAY/TEST gameplay scripts: 37 byte-identical scripts
- Source unchanged after the run: yes
- Real topology: one server + two clients
- Background OPEN cue: exit 0 before Studio launch
- Foreground START cue: exit 0 before Studio mouse/keyboard input
- Foreground DONE cue: exit 0 immediately after Stop
- Background CLOSE cue: exit 0 immediately after the exact Studio close command

## Preserved failures

Two exact-source 0.4.3 failure runs remain preserved:

- `tests/engine-20260924T223247624961Z.json`: **101 passed / 3 failed**. The failures were test-observation defects: a fixed training wait, raw Coin equality despite passive income, and exact floating-point WalkSpeed equality.
- `tests/engine-20260925T011415715222Z.json`: **103 passed / 1 failed**. The real client successfully selected Water and authoritative state changed correctly; the remaining check still required raw Coins to remain identical while passive pet income was active.

The repairs changed only test observation/synchronization. Production Elemental Tuning behavior was unchanged between the failed and final candidates.

## Claim boundary

Engineering verification establishes the Elemental Tuning mechanics and retained regressions. It does not establish that the tuning identities, numerical tradeoffs or UI feel are fun or owner-accepted.

Progress remains session-only. Nothing was merged to `main` and nothing was published to Roblox.
