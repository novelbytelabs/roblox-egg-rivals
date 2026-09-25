# Egg Rivals 0.4.4 — Social Drafting engineering verification

Candidate: `EGG-RIVALS-0.4.4-rc1`
Exact tested source bytes committed at: `301448dd7cf9a8fda748d4c14b585615f170d30d`
Source digest: `be7aaa66d706a1fa86dfe0a2ad7a277ee69a80934688719bb7a1a430a7ce70d8`
Status: **ENGINEERING CANDIDATE VERIFIED; OWNER SOCIAL DRAFTING FEEL REVIEW PENDING**.

The fresh exact-source Studio regression completed **107 checks in 201 seconds: 107 passed, 0 failed**. The run used one real Studio test server and two real Studio clients.

## Social Drafting coverage

The suite directly covers:

- one trainer remaining solo without Drafting;
- two adjacent real trainers entering Drafting symmetrically;
- Drafting ending when either partner stops training;
- a bounded +10% permanent-Speed gain multiplier;
- non-stacking Drafting semantics;
- 50-stud range matching adjacent camp geometry;
- authoritative server-derived state rather than client-supplied partners/multipliers;
- no Drafting authority over Coins, pet income, Momentum, Overdrive charge, Motion Energy, inventory or competitive normalization;
- treadmill attributes and Speed Lab snapshot exposing Drafting state;
- all retained Elemental Tuning, Ranger Contracts, Sprint, Night/Forest, trade, Exchange, ranch, Warden, incubation, duel and Trial regressions.

## Exact evidence

- Engine result: `tests/engine-20260925T021744179535Z.json`
- Engine-result SHA-256: `67bd9d98831564bee4319ac0ff86176fcfb2622fbded344b34c34374427c7eab`
- PLAY artifact SHA-256: `5785268205abb55858984667bc09544409bbd7957836b4a16d202d885e5637fb`
- TEST artifact SHA-256: `03ff0ac085c2345313bf6024ed89691a16df3b7ca688cf888ea581f060cb9070`
- PLAY/TEST gameplay scripts: 38 byte-identical scripts
- Source unchanged after the run: yes
- Real topology: one server + two clients
- Background OPEN cue: exit 0 immediately before Studio launch
- Foreground START cue: exit 0 before Studio mouse/keyboard input
- Foreground DONE cue: exit 0 immediately after Stop
- Background CLOSE cue: exit 0 immediately after the exact Studio close command

## Preserved evidence and repair

The 0.4.4 evidence history remains preserved:

- `tests/engine-20260925T014225856424Z.json`: **107/107** on pre-repair source digest `07088ec5...`. It established the Social Drafting mechanics, but the later four-chime audit required a fresh fully observed run before promotion.
- Round 54: background OPEN succeeded, then Vinegar exited during Wine setup before any Studio window or foreground input. This is preserved as a setup/launch failure, not a gameplay failure.
- `tests/engine-20260925T020859883596Z.json`: **106/107**. All Social Drafting checks passed; the retained Warden catch regression intermittently failed its fixture.
- Source review showed the Warden test mixed unpause/catch semantics with an arbitrary local navigation route even though the following test separately owns obstacle-routing validation. Commit `301448d` changed only that fixture: the carrier and Warden now use a known-clear central Forest corridor and explicitly assert that corridor is collision-clear. Production Warden speed, catch range, alert delay, navigation logic and the 8-second catch requirement were not weakened.
- The repaired exact source then passed **107/107** in round 56.

## Claim boundary

Engineering verification establishes the bounded Social Drafting mechanics and retained regressions. It does not establish that +10%, 50 studs, belt feedback or the social motivation are fun or owner-accepted.

Progress remains session-only. Nothing was merged to `main` and nothing was published to Roblox.
