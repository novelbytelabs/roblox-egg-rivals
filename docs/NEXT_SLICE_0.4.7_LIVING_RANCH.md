# Egg Rivals 0.4.7 — Living Ranch and Pet Activity Depth

Status: **DESIGNED — IMPLEMENTATION IN PROGRESS; VERIFICATION PENDING**.

## Authority and frozen boundary

This slice follows the owner's explicit Living Ranch sprint instruction, not a stale roadmap NEXT marker. Its product authorities are `DESIGN_BIBLE.md`, `PET_PEN_SYSTEM.md`, `BASE_INCUBATION_RESPAWN.md`, and the pet-integration sections of `SPEED_LAB_SYSTEM.md`.

Parent lineage: `feature/0.4.0-living-world` at `a25ebb9bb5a9561a4b2de62177cb1f3a0e0445a2`.

Child branch: `feature/0.4.7-living-ranch`.

The parent contains 0.4.6 Speed Mastery implementation, not a verified 0.4.6 candidate. Its reported 112/2 and 113/1 runs remain failure evidence. This child must not move the parent ref, replace historical verification files, merge main, publish Roblox, or inherit a runtime PASS.

## Product goal

Make hatching another creature visibly enrich the player's home. Starter pet life is free. Pets create attachment and social expression without feeding, health, breeding, happiness, neglect penalties, or other maintenance chores.

| Priority | Bounded delivery | Explicit limit |
|---|---|---|
| Pet activity | Timed habitat visits, coordinated naps, paired playful chasing, gate watching, species-specific poses | Displayed residents only; no unbounded pathfinding |
| Homecoming | Short owner-return and respawn acknowledgment, plus separately throttled milestone cheers | No repeated extension/spam; celebrations retain priority |
| Training response | Active companion runs, watches or hovers beside training; a bounded resident subset watches from inside the pen | No Speed, income, charge or competitive authority |
| Habitat groundwork | Four free elemental gathering/rest/play anchors with visible elemental props | Not the full purchasable Habitat Builder tree |
| Earnings readability | Preserve and directly check authoritative total-pet and Coins/min board, including overflow | No second payout calculator or competing board writer |
| Architecture | Shared bounded pose rules, server-selected semantic activity, finite target generation/lifecycle | No new currency, persistence, shop, or remote activity command |

## Existing behavior to preserve

The parent already has Idle/Wander/Rest/Play, welcome batching, homecoming triggers, Godly reverence, visitor inspection/Admire, active companions and a real earnings board. Extend these paths rather than rebuilding them or labelling them missing.

Ownership remains in Inventory/Game. Ranch activities read the authoritative item and display records. They may update presentation records but must not edit item ownership, revision, favorite/lock state, pet mode, income, currency, player movement or progression.

## Activity scheduling

Use the existing bounded Ranch tick. Select ordinary activity episodes on a slower cadence, initially 12 seconds, rather than launching per-pet tasks or pathfinding requests.

Ordinary episodes use deterministic selection from eligible displayed residents. A ranch has at most one two-pet chase pair and one three-pet nap group at a time. Godly residents never join either. Other residents use their own elemental habitat or their assigned home position.

Priority is: active reverence, welcome party, eligible homecoming/milestone greeting, bounded training spectators, ordinary activity. Ascend/Revere remain the established Godly states. Extra activity metadata refines existing behavior states instead of changing inventory semantics.

A pet removed from display, transferred, reserved, sent active, or deleted immediately becomes ineligible. Re-select targets at the next Ranch tick and invalidate stale group membership. Unavailable habitat targets fall back to the pet's own valid home position. No foreign ranch target is admissible.

## Habitat groundwork

Build one compact motif for each element inside the current PenArea: Fire ember stones, Water pool/ripple, Wind perch/vane, Earth roots/logs. Use bounded nonphysical presentation parts and same-owner target attachments.

Targets belong to a particular PenArea generation. A physical expansion destroys the old area's objects and builds a fresh set. Deleted targets are not continuously resurrected; affected activity falls back safely until a new area is built. Habitat props must not obstruct the gate, create colliders, affect prompts, or grant elemental power.

The full Habitat Builder, Creature Comforts, Showcase, Pen Manager, themes and large-creature facility branches remain future work.

## Homecoming and training

Initial homecoming tuning is a four-second response with a ten-second return/respawn cooldown. Milestone cheers have a separate eight-second cooldown. Repeated calls must not extend the active response indefinitely. These numbers are implementation tuning, not new owner-mandated product laws.

At most four penned residents greet/watch from safe positions inside their pen. The single active companion may acknowledge its owner and react beside the owner's treadmill. Skunk/Lizard pacing, Gorilla watching, and Dragon hovering give species different presentation. Once training ends, the active pet resumes following; residents return to ordinary activity. No extra active companion is created.

## Client rendering

Use the existing Effects pet renderer and shared PetMotion. The server supplies activity identity, target, phase and timing; the client interpolates poses. Every resident pose remains constrained to its pen and outside visible Godly exclusion radii, including interpolation between episodes. Missing or stale data degrades to a valid idle/home pose.

Preserve Night trail-to-impact conversion. A rest animation or deliberate slowdown must not manufacture a collision event. Only established contact/landing behavior may provide the existing impact hint.

On ownership transfer, refresh the existing client interaction object's owner metadata. Rendering and clicks must not retain the previous owner's identity.

## Source boundary

Expected production changes are limited to Ranch, shared PetMotion, Effects integration and a build label. Add focused shared activity rules and a server habitat builder. Inventory, trade, Exchange, duel, Sprint, Trial, Speed authority, prices and income rules remain unchanged.

The inherited Overdrive fixture imports `Rules` but uses `R.speed` in its expected-speed expressions. The child should correct this identifier only. The recorded error `attempt to index nil with 'speed'` is consistent with that source defect; the previous profile-loss explanation is not established. The frozen parent remains unchanged, and the correction must be separately identifiable for a later 0.4.6 repair candidate.

## Direct regression plan

Retain every prior test family, including Mastery. Add direct checks for:

1. bounded, finite same-owner habitat targets across all expansion sizes;
2. episode stability, valid behavior choices and capped chase/nap/spectator membership;
3. same-element habitat preference with safe missing-target fallback;
4. Godly exclusion from casual groups and retained same-element reverence;
5. cooldown-limited return/respawn and milestone greetings;
6. active companion uniqueness and species-appropriate training response;
7. immediate cancellation of training reactions when training ends;
8. activity cleanup on paging, reservation, transfer and profile replacement;
9. no inventory, income, Coins or Speed mutation by non-yielding activity transitions;
10. earnings board correctness with undisplayed overflow pets;
11. finite, bounded rendered poses at multiple times, with no false rest-impact hint;
12. real-client observation of server-selected activity, visible habitat props and moving pet models.

Read-only Studio diagnostic code may observe actual rendering. It must not complete activities, claim rewards, or bypass production validators. No mocked result may replace the real engine result.

## Verification boundary and RDC budget

This sprint performs GitHub source/design/test work first. It does not open Studio or consume RDC for reads or editing.

At the runtime boundary, use a dedicated local worktree so the owner's WIP and frozen 0.4.6 checkout remain intact. Batch preflight, formatting, Rojo PLAY/TEST builds, script-byte identity, exact-source freezing and writable TEST-copy hashing before launching Studio.

Runtime order: background-open cue succeeds immediately before background Studio launch; foreground START succeeds before any mouse/keyboard action; persisted result precedes Stop; foreground DONE immediately follows Stop; close the exact editor; background-close immediately follows the close command. All cue failures are explicit failures. Do not substitute chimes or steal focus during startup.

A fresh one-server/two-client run with zero failures is required. Preserve failed runs and source identities. If 0.4.6 is separately promoted, test that exact candidate separately; a 0.4.7 result does not retroactively verify its parent.

## Claim ceiling

Source implementation, source review, native formatting/build success, real engine success and owner presentation acceptance are distinct states. This packet grants none of the latter merely by existing.
