# Egg Rivals — Production Guardrails

Status: approved baseline constraints.

## Platform scope

Current polished development target: PC / Roblox Studio.

Later intended platforms:

- mobile / tablet;
- Xbox;
- PlayStation.

VR is out of scope.

Controls and UI should avoid assumptions that make later mobile/console adaptation unnecessarily expensive, but Stage 3 does not require those ports.

## Persistence

Current verified vertical slice is session-only.

MVP persistence is expected for at least:

- Speed and Speed Lab progression;
- Money / currencies;
- inventory item instance records;
- pet records and ownership;
- egg creature / rarity / element state;
- active / penned pet state;
- ranch upgrades and customization;
- treadmill modules / grade;
- incubations and remaining duration;
- unlocked cosmetics / progression.

Persistence implementation belongs to MVP, not the already-verified Stage 3 baseline.
## Server authority and anti-exploit

The server owns:

- economy mutations;
- inventory ownership;
- egg pickup / secure validation;
- incubation / hatch conversion;
- pet state;
- trade and Exchange transfers;
- duel escrow and scoring;
- combat validation;
- progression purchases;
- live-event authoritative state.

Clients request actions and render presentation. They do not assert ownership or rewards.

Important controls include proximity validation, rate limits, unique item IDs, duplicate rejection, atomic transfer, deterministic disconnect handling, and bounded RemoteEvent inputs.

## Monetization direction

Approved safe direction favors:

- cosmetics;
- pet skins / effects;
- emotes;
- ranch / base themes;
- private servers;
- display / collection presentation;
- other noncompetitive convenience.

Do not sell direct duel power for Robux.

Starter systems should remain enjoyable without purchases. Paid customization should increase expression and spectacle, not repair intentionally bad usability.

## Generated artifacts

Repository source is canonical.

Generated `.rbxlx` files, Studio recovery files, and local build artifacts are not authoritative source and should not be committed unless an explicit archival decision says otherwise.
