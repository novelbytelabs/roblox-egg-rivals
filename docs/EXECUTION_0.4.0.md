# Egg Rivals 0.4.0 execution record

## Authority and baseline

- Task: execute ASTRA_0.4.0_EXECUTION_PACKET.md and its canonical sources.
- Starting commit: `59ecbbe5e6ab3160edea0d7b9f6bdc47843f318a`.
- Branch: `feature/0.4.0-living-world`; main and remote were reconciled before editing.
- No merge to main. No Roblox publication. Session-only progression remains explicit.
- All listed binding sources and relevant system documents were read completely.
- Phase 0: PASS. All 13 imported gameplay files match the verified 0.3.2-r2 manifest byte-for-byte.
- Native PLAY and TEST baseline builds and formatting checks passed.
- Evidence: `tests/baselines/moonwood-0.3.2-r2.json`.
- Historical engine results are preserved, not reused as 0.4.0 results.
- Initial REPL helper declaration failed; it was corrected before the evidence file was created.

## Source/dependency map

Existing Config/Rules/Inventory gain the v2 schema and validated economics.
Game remains the composition root for ownership, heists, incubation and existing combat.
New focused server modules will implement Speed Lab, trial validation, ranch scheduling and commerce.
Camp construction and client presentation stay separate from transaction authority.
Duel/Navigation retain their tested responsibilities and receive only integration/regression changes.
Tests will retain equivalent baseline coverage while extending it for the new rules.

## Historical first unresolved gate

At the start of this execution record, Phase 1 was the first unresolved gate: canonical configuration, item reservations, currency accumulation and schema migration. That statement is retained as historical execution context.

## Final engineering verification

- Final candidate: `EGG-RIVALS-0.4.0-rc1`.
- Exact HEAD: `e185b078b7fd9f598e62130fb1dcaf008885fdb1`.
- Exact source digest: `33d29059abad739b7c3cdfeabf7cf27409328acf510edbb1f3c6b67da318d4e4`.
- StyLua check: PASS.
- Native PLAY and TEST builds: PASS.
- PLAY/TEST gameplay script-byte identity: PASS across 26 scripts.
- Fresh real Studio topology: one server plus two clients.
- Exact-source engine result: `tests/engine-20260923T204200Z.json`, 77 passed / 0 failed.
- Engine result SHA-256: `86b1edf0b8a7b15e0c6dcc40b513e2c2104dc285221dec5b3cc847e25309089d`.
- Source remained unchanged after the run.
- Final engineering status: **ENGINEERING CANDIDATE VERIFIED; HUMAN PRESENTATION ACCEPTANCE PENDING**.
- No merge to `main`. No Roblox publication.

See `docs/STAGE3_040_VERIFICATION.md` and `tests/CANDIDATE_STATUS.json` for the bounded verification record. Historical failed engine results remain preserved.
