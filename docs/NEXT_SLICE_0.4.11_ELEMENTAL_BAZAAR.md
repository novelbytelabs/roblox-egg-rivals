# Egg Rivals 0.4.11 — Elemental Bazaar v1

Status: **IMPLEMENTED / VERIFICATION PENDING**

## Purpose

Deepen elemental camp identity without creating paid power, separate element economies or ambiguous incubator readability.

## Bounded v1

A physical Elemental Bazaar in the safe hub offers five free session ranch themes:

- Standard Camp;
- Ember Court / Fire;
- Tide Court / Water;
- Gale Court / Wind;
- Root Court / Earth.

Each nonstandard theme adds a bounded nonphysical overlay: four small themed decorations plus a twelve-segment camp sigil. Changing theme replaces the prior overlay.

## Authority and invariants

The server validates:

- exact allowlisted theme;
- alive/free player state;
- no carried egg;
- physical Bazaar proximity.

Theme state belongs to the player profile for the session and is mirrored on the player’s base model.

No theme mutates:

- inventory or pet variants;
- pet income;
- Coins;
- Speed;
- lab grade;
- ranch expansion or visible capacity;
- ranch activity layout;
- incubator Element attributes;
- pet or duel power.

The camp resets to Standard when its owner leaves.

## Regression coverage

The 0.4.11 regression family covers:

- Standard plus exactly four elemental themes;
- remote and unknown selection rejection;
- replacement instead of stacking;
- bounded nonphysical theme part budget;
- preserved incubator element identity;
- preserved inventory/economy/progression/ranch-layout authority;
- a real client Bazaar selection reaching authoritative profile and replicated camp presentation.

Fresh exact-source one-server/two-client Studio regression remains required before engineering verification.
