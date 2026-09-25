# Egg Rivals 0.4.5 — Visitor Ranch Interactions v1

Status: **ENGINEERING VERIFIED — 110/110 EXACT-SOURCE REGRESSION; OWNER FEEL REVIEW PENDING**

Purpose: deepen the approved ranch/social loop by turning visible pets in another player's ranch into safe social objects without giving visitors any ownership, economy or progression authority.

## Implementation / verification status

The bounded v1 implementation is present and engineering-verified. Exact evidence is recorded in `STAGE3_045_VERIFICATION.md` and `tests/engine-20260925T030114542554Z.json`.

The implementation uses the existing Ranch authority surface, validates exact foreign displayed pets and proximity on the server, preserves Trading Post transfer boundaries, and adds no ownership/economy authority to the visitor. Owner social feel and panel presentation remain separate playtest claims.

## Existing foundations

The current client already renders globally replicated pet records and allows a foreign pet click to show basic species/rarity/income information.

The Ranch service already owns visitor-triggered Godly reverence with real proximity and cooldown validation.

0.4.5 extends those existing paths instead of adding a second ranch or social authority system.

## Visitor inspection

Clicking another player's displayed penned pet requests an exact server-validated inspection.

The visitor panel shows:

- owner display name;
- creature/species;
- element;
- rarity;
- passive income.

Inspection is read-only.

The server accepts inspection only when:

- the visitor is alive and not in another busy activity;
- the target is a real authoritative Pet inventory record;
- the pet is currently displayed in Pen mode;
- the owner is a different connected player;
- the visitor is within 14 studs of the pet's authoritative pen position.

The client cannot use inspection to move, lock, trade, exchange, stake, activate, sell or otherwise mutate the foreign pet.

## Admire reaction

The visitor panel exposes one harmless v1 reaction: **ADMIRE PET**.

The server revalidates the exact pet and proximity and applies a 3-second per-visitor reaction cooldown.

A valid Admire:

- emits presentation at the pet;
- notifies the visitor;
- notifies the owner;
- changes no item field;
- changes no Coins, pet income, Speed, Momentum, Overdrive, Motion Energy, contracts, trade state or duel state.

Reaction text is social presentation, not a reward.

## Godly reverence

The visitor panel also exposes **REQUEST REVERENCE**.

This uses the already-existing Ranch `requestReverence` authority. Its Godly eligibility, same-element resident requirement, ranch proximity and 120-second visitor cooldown remain unchanged.

0.4.5 does not create a weaker alternate reverence path.

## Trading boundary

The panel tells visitors that trading remains at the Trading Post.

0.4.5 does not weaken the existing rule that both players deliberately meet at the Trading Post and review exact offers before any transfer.

A later visitor feature may provide navigation or invitation assistance, but ranch inspection itself never creates a trade or reservation.

## Verification requirements

Directly cover:

- exact foreign-pet inspection data;
- owner-self rejection;
- proximity rejection;
- hidden/unavailable pet rejection;
- valid Admire through the production action path;
- unsupported reaction rejection;
- immediate duplicate reaction cooldown;
- exact preservation of pet owner/state/revision;
- no Coin mutation caused by interaction;
- retained visitor Godly reverence behavior;
- all prior 107 checks remain green.

Final engineering acceptance requires formatted source, PLAY/TEST build success, exact gameplay-script byte identity and a fresh real one-server/two-client Studio run with zero failures.

## Out of scope

Visitor item mutation, pet gifting, remote trade execution, tips/donations, reaction rewards, likes/follower counts, guest ranch editing, feeding, happiness, persistence, new currency, teleport-to-ranch matchmaking and public wagering are excluded.

## Claim boundary

This packet defines the 0.4.5 implementation candidate. It does not claim that the panel layout, Admire frequency or visitor social value are owner-accepted until playtesting.
