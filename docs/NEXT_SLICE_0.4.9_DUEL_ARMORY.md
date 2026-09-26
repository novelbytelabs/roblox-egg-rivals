# Egg Rivals 0.4.9 — Duel Armory v1

Status: **IMPLEMENTED / VERIFICATION PENDING**

## Purpose

Give opt-in arena duels meaningful play-style choice without introducing paid competitive superiority.

## Bounded v1

A physical Duel Armory in the safe hub offers three free session loadouts:

- **Blaster** — 34 damage, 0.30 s cadence, 250-stud range.
- **Rail** — 55 damage, 0.50 s cadence, 300-stud range.
- **Scatter** — five 13-damage pellets, 0.55 s cadence, 85-stud range and bounded spread.

Their theoretical maximum damage cadence stays within roughly ten percent. Range, precision and pellet behavior are the intended tradeoffs.

## Authority

The server owns:

- Armory proximity and activity eligibility;
- selected session loadout;
- exact equipped duel tool;
- damage;
- shot cooldown;
- range;
- pellet count;
- spread;
- duel-time loadout lock.

Changing loadout costs no Coins or Robux and does not mutate inventory, pet income or permanent Speed.

## Presentation

Each sidegrade receives a distinct primitive-built tool silhouette/accent. Duel offer and active-round UI expose both players' loadouts.

Cosmetic skins, sights, tracers and animation variants remain later Armory depth.

## Regression coverage

The 0.4.9 regression family covers:

- exactly three configured sidegrades;
- bounded theoretical output;
- expected range/pellet tradeoffs;
- remote and unknown selection rejection;
- free server-owned selection;
- selection lock during a duel;
- exact selected duel tool;
- bounded Scatter ray geometry;
- Rail single-ray precision geometry;
- real client Armory selection reaching authoritative state.

Existing DuelBlaster behavior remains the default, so retained duel regressions continue to exercise the baseline path.

Fresh exact-source one-server/two-client Studio regression remains required before engineering verification.
