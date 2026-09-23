# Egg Rivals 0.4.0 — engineering verification

Candidate: `EGG-RIVALS-0.4.0-rc1`
Commit: `e185b078b7fd9f598e62130fb1dcaf008885fdb1`
Source digest: `33d29059abad739b7c3cdfeabf7cf27409328acf510edbb1f3c6b67da318d4e4`
Status: **ENGINEERING CANDIDATE VERIFIED; HUMAN PRESENTATION ACCEPTANCE PENDING**.

The fresh exact-source Studio regression completed 77 checks in 147 seconds: **77 passed, 0 failed**. The test used one real Studio test server and two real Studio clients. The guarded Studio command asserted the exact source digest before starting the multiplayer test.

Evidence:

- Engine result: `tests/engine-20260923T204200Z.json`
- Engine result SHA-256: `86b1edf0b8a7b15e0c6dcc40b513e2c2104dc285221dec5b3cc847e25309089d`
- PLAY artifact SHA-256: `6dd403f065b6cd84ca1d171f01802049e2ce24f0085ab98f6f33044144d6a51b`
- TEST artifact SHA-256: `31477102a960cd90dbafb1bbbcdc7a15dc51555116e6a7ed69a5f747033d0680`
- PLAY/TEST gameplay scripts: 26 byte-identical scripts
- START cue exit: 0
- DONE cue exit: 0
- Source unchanged after the engine run: yes

Verified mechanical coverage includes bounded Speed and Momentum, Machine Grades, Overdrive, Motion Energy, timed incubation confirmation, reservation-safe Trading Post transfers, Godly confirmation, Exchange, ranch expansions, welcome/reverence routing, Night egg lifecycle, bounded client particle reuse, full-stop neon impact classification, Training Trial ordering, real client movement, personal-best replay, and the existing Bat, Snare, Warden, respawn and duel regressions.

Earlier exact-source failures remain preserved in the versioned `tests/engine-*.json` evidence. In particular, `engine-20260923T163701Z.json` records the 67/8 hold-confirmation and Trial failures, and `engine-20260923T184932Z.json` records the later 75/2 proximity-fixture failures. They were not replaced by the final result.

Human visual quality, presentation feel and gameplay feel have not been accepted. Session-only progression remains explicit. Nothing was published to Roblox and nothing was merged to `main`.
