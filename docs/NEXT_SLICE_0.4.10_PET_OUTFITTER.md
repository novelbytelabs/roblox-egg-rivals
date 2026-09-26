# Egg Rivals 0.4.10 — Pet Outfitter v1

Status: **IMPLEMENTED / VERIFICATION PENDING**

## Purpose

Add visible pet identity without changing collection authority, pet economics, rarity readability or competitive power.

## Bounded v1

A physical Pet Outfitter in the safe hub offers three free session styles:

- **Standard** — original presentation.
- **Ranger** — low-profile elemental collar plus ranger tag.
- **Starlight** — four subtle elemental body sparks.

The existing pet `variant` field is the sole cosmetic identity field for this slice.

## Authority and invariants

The server validates:

- exact owned pet id;
- pet is currently available in Inventory;
- pet is not reserved;
- player is alive and not busy/carrying;
- physical Outfitter proximity;
- exact allowlisted style.

Changing style increments only item revision and variant. It does not alter owner, pet mode, creature, element, rarity, income, Speed, Coins, size or Godly behavior.

Existing trade and duel transfer code preserves `variant` automatically because item identity is retained.

## Presentation

The same variant is rendered in:

- Collection viewport previews;
- active companion rendering;
- ranch resident rendering;
- ranch nameplates;
- read-only visitor inspection.

Cosmetic parts are primitive-built, nonphysical and excluded from Night edge tracing. v1 deliberately avoids size cosmetics, crowns and large silhouette-obscuring accessories.

## Regression coverage

The 0.4.10 regression family covers:

- exactly three allowlisted styles;
- remote, foreign, unknown and reserved mutation rejection;
- active and penned pet styling;
- no owner/mode/rarity/element/creature/income/Speed/Coins mutation;
- no-op style selection preserving revision;
- PetRecord and inventory snapshot replication;
- read-only visitor variant inspection;
- a real client Outfitter selection reaching authoritative state and rendered pet cosmetics.

Fresh exact-source one-server/two-client Studio regression remains required before engineering verification.
