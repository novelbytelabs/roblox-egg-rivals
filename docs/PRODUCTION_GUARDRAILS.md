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

### Current persistence implementation status

0.5.0 implements only the **schema/restore foundation**. It version-checks and validates durable player data, rejects unresolved ownership-transaction states, preserves exact inventory IDs, and reconstructs resumable incubations and ranch presentation.

0.5.0 intentionally performs **no DataStore reads or writes**. DataStore transport, session ownership/locking, retry policy, shutdown saves, migrations, rollback and production observability remain 0.5.1+ work.

Roblox's current production guidance should be followed for that transport layer: use server-only DataStore access, prefer a small fixed set of stores with one/few keys per player, buffer gameplay state in memory, prefer UpdateAsync for multi-server-safe dependent writes, handle transient failures with bounded ordered retries, and keep Studio away from production data.
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
