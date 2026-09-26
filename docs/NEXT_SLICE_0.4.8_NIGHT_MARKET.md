# Egg Rivals 0.4.8 — Night Market v1

Status: **IMPLEMENTED / VERIFICATION PENDING**

## Purpose

Make Moonrise feel more like a world event by activating a small physical shop that helps players search for the hidden Night egg without trivializing the hunt.

## Bounded v1

- Physical Night Market stall in the safe hub.
- Closed shutter, disabled prompt and dim lamps during Day.
- Open shutter, enabled prompt and neon lamps during Moonrise.
- Moon Compass: 35 Coins, coarse relative direction, once per player per Moonrise.
- Glow Map: 60 Coins, broad Forest sector, once per player per Moonrise.
- No persistent item, new currency, exact waypoint or coordinate payload.
- Free flashlight remains free.

## Authority

The server validates:

- current Night state;
- player activity and life state;
- Night Market proximity;
- hidden egg still being at its hiding place;
- exact Coin price;
- per-player/per-Night usage;
- clue generation.

Coins are deducted only after every validation succeeds.

## Regression coverage

The 0.4.8 source adds a Night Market regression family covering:

- physical Day closure;
- Day purchase rejection without charge;
- Moonrise opening;
- unknown-aid rejection;
- exact Coin costs;
- once-per-Moonrise limits;
- coordinate-free clue text;
- rejection after the hidden egg leaves its hiding place;
- new-Night eligibility reset;
- no inventory/income/Speed mutation;
- dawn closure;
- a real client panel/button purchase reaching authoritative server Coins.

A fresh exact-source one-server/two-client Studio regression is still required before engineering verification.
