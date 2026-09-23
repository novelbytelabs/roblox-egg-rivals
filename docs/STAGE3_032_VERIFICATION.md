# Moonwood elemental refinement — verified candidate

Candidate: MOONWOOD-0.3.2-r2
Source digest: 0539ceee262ad0044f00984ed6e2ab6b9a29ed4a9d6ccaf117def73dfa3a719e
Status: ENGINE REGRESSION PASS; HUMAN PRESENTATION ACCEPTANCE PENDING.

The real two-client Studio suite completed 24 checks in 77 seconds: 24 passed, 0 failed.
Evidence: ../tests/latest-engine-results.json and the versioned engine result files.
The PLAY and TEST builds contain byte-identical script sources. Only test settings differ.
No result from 0.3.0, 0.3.1 or an earlier 0.3.2 revision was substituted for this run.

Implemented and checked:
- Four independent elemental incubators and four simultaneous elemental Dragon hatches.
- Skunk, Lizard, Gorilla and Dragon models in Fire, Water, Wind and Earth variants.
- One active companion; penned pets remain owned and continue earning income.
- Pen pages show at most eight pets, within the physical pen, without deleting overflow.
- Stored eggs retain their creature and rarity until an element is selected.
- Personal SpawnLocations survive an actual death/respawn, with normal equipment restored.
- Bat, snare, safe-zone, training, Night and income regression checks.
- Exact duel offers, escrow visibility, damage, cover, first-to-five and item transfer.
- Collection keyboard open/close, post-duel camera and Warden obstacle routing.

Earlier failures remain saved. Fixes include the menu nil-ternary bug, personal spawn
assignment, escrow visibility, pen bounds and collision-checked Warden detours.
Client audio loaded in the test. Human audibility, appearance and gameplay feel still need review.
Progress remains session-only. Item-transfer duels remain Studio-only. Nothing was published.
