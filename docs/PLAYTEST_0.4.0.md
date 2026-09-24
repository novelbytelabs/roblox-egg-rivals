# Egg Rivals 0.4.0 — Owner Playtest

Status: **IN PROGRESS — OWNER PRESENTATION / GAMEPLAY ACCEPTANCE PENDING**

Candidate: `EGG-RIVALS-0.4.0-rc1`  
Tested source: `e185b078b7fd9f598e62130fb1dcaf008885fdb1`  
Source digest: `33d29059abad739b7c3cdfeabf7cf27409328acf510edbb1f3c6b67da318d4e4`  
Engineering evidence: **77 passed / 0 failed**

## Purpose

Engineering verification established the mechanical candidate. This playtest evaluates the parts automation cannot establish: fun, clarity, feel, personality, spectacle, frustration, pacing, and desire to keep playing.

Do not convert subjective feedback into a code defect automatically. Record the observation first, then classify the required response.

## Review rubric

| Area | What to evaluate | Owner feedback | Disposition |
|---|---|---|---|
| Core fun | Is the train → steal → hatch → collect loop immediately enjoyable? | PENDING | PENDING |
| Movement | Speed progression, control, acceleration and Overdrive feel | PENDING | PENDING |
| Theft | Defender pressure, escape tension and interference readability | PENDING | PENDING |
| Camp | Can a player immediately understand training, respawn, incubators and ranch? | PENDING | PENDING |
| Incubation | Element choice, preview, hold interaction and hatch payoff | PENDING | PENDING |
| Pets | Do pets feel alive, readable and worth collecting? | PENDING | PENDING |
| Ranch | Does the ranch feel like a home and visible record of progress? | PENDING | PENDING |
| Godly | Does Godly rarity feel exceptional rather than merely numerical? | PENDING | PENDING |
| Night | Beauty, readability, transformation and hidden-egg search tension | PENDING | PENDING |
| Effects | Trails, impact splatter, particles and visual restraint | PENDING | PENDING |
| Economy | Prices, earning pace and progression satisfaction | PENDING | PENDING |
| Shops | Trainer Workshop, Ranch & Pen Works and Exchange clarity | PENDING | PENDING |
| Trading | Discoverability, exact offers, confirmation and confidence | PENDING | PENDING |
| Trial / ghost | Course fun, readability and motivation to improve | PENDING | PENDING |
| PvP | Bat/Snare interference and opt-in duel feel | PENDING | PENDING |
| Replay desire | After one session, is there a clear reason to keep playing? | PENDING | PENDING |

## Feedback classification

Use one disposition per finding:

- **BUG** — implemented behavior is incorrect or broken.
- **UX** — behavior works but is confusing, awkward or hard to discover.
- **TUNING** — numbers, timing, difficulty or pacing need adjustment.
- **PRESENTATION** — visuals, audio, animation, readability or spectacle need work.
- **DESIGN** — the intended mechanic itself should change.
- **MISSING** — an approved aspiration is absent and now matters in play.
- **KEEP** — observed behavior is working well and should be preserved.

Priority:

- **P0** — blocks play or risks ownership/state integrity.
- **P1** — materially damages the core loop or player understanding.
- **P2** — important polish, pacing or feature gap.
- **P3** — optional refinement.

## Findings

Record owner feedback here as it is observed. Preserve both positive and negative findings; do not keep only defects.

| Priority | Type | Observation | Evidence/context | Decision |
|---|---|---|---|---|
| — | — | Playtest started; feedback pending. | Verified 0.4.0 PLAY candidate | OPEN |

## Acceptance rule

Do not mark 0.4.0 owner-accepted until the owner explicitly accepts the presentation/gameplay candidate after playtesting.

Engineering status remains:

**ENGINEERING CANDIDATE VERIFIED; HUMAN PRESENTATION ACCEPTANCE PENDING**

## Owner feedback — 2026-09-24

The owner reported that the current game is fine for this development stage. Small issues are expected; main mechanics and play remain the priority. This is permission to continue development, not a blanket quality or publication acceptance for future builds.

| ID | Type | Owner observation / request | Action / evidence state |
|---|---|---|---|
| PT-01 | KEEP | Overall game is fine for now; prioritize mechanics and play. | Preserve existing core systems and the rc1 77/0 evidence. |
| PT-02 | PRESENTATION | Objects disappear into darkness; every object edge should have neon tracing. | rc2 adds shape-aware edge lights for supported visible world primitives and pet models; runtime and visual review pending. |
| PT-03 | TUNING | Glow is a tiny bit too intense. | rc2 reduces bloom intensity from 1.2 to 1.02, narrows its size and raises the threshold. Initial tuning, not owner-accepted appearance. |
| PT-04 | PRESENTATION | Particle trails are too short and too sparse. | rc2 uses 1.8-second lifetime, higher emission and bounded larger pools. Runtime and feel review pending. |
| PT-05 | DESIGN | Give players a flashlight for Night visibility. | Free hands-free personal flashlight, F toggle, no battery/price or item mutation. Runtime review pending. |
| PT-06 | DESIGN | More Forest eggs and Godly eggs available in the map. | Twelve nests including one marked Godly nest; longer dedicated respawn. Runtime and economy tuning review pending. |

Implementation-selected tuning: twelve total nests and a 600-second Godly-nest cooldown after successful removal. The owner asked for availability, not these exact numbers. Ordinary day/night roll tables remain unchanged; the dedicated nest nevertheless increases total Godly supply. That economy consequence is explicit and remains subject to playtest tuning.

Workflow: prefer live feature-branch updates. Pull the workstation with `git pull --ff-only` only when local build/runtime work is needed. Background work uses no chimes. START must succeed before foreground Studio input, and DONE follows the stop command immediately.
