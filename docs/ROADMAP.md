# Egg Rivals Roadmap

## Current engineering baseline

**EGG-RIVALS-0.4.5-rc1 — VISITOR RANCH INTERACTIONS v1** remains the latest engineering-verified candidate.

- Exact-source multiplayer regression: **110 passed / 0 failed**
- Real Studio topology: one server + two clients
- Human presentation review remains a separate gate
- Roblox publication: **NOT PERFORMED**
- Merge to `main`: **NOT AUTHORIZED**

The 0.4.4 107/107 Social Drafting, 0.4.3 104/104 Elemental Tuning, 0.4.2 99/99 Ranger Contracts, 0.4.1 90/90 Sprint Rivalry, 0.4.0-rc2 86/86 Night/Forest and earlier baselines remain preserved historical references.

## Verification queue

### 0.4.6 — Speed Mastery v1

**IMPLEMENTED / VERIFICATION PENDING**

Precision Mode and Overdrive Cut are implemented on the dedicated repair branch. Historical 112/2 and 113/1 failure evidence remains preserved. A fresh zero-failure exact-source Studio regression is still required before promotion.

### 0.4.7 — Living Ranch + Pet Activity

**IMPLEMENTED / VERIFICATION PENDING**

The branch contains richer ranch activity, habitat, homecoming and presentation work plus later pen usability improvements. The owner is satisfied with current pen progress, so further pen-layout polish is not the active roadmap target. Fresh exact-source Studio verification remains required.

### 0.4.8 — Night Market v1

**IMPLEMENTED / VERIFICATION PENDING**

The Night Market is physically closed by Day and opens at Moonrise. Two bounded, one-use-per-Moonrise Coin aids narrow the hidden-egg search without exposing coordinates or an exact waypoint:

- **Moon Compass** — coarse relative direction.
- **Glow Map** — broad Forest sector.

Server authority owns eligibility, cost, per-Night usage and clue generation. A real-client purchase probe is included in the regression family.

### 0.4.9 — Duel Armory v1

**IMPLEMENTED / VERIFICATION PENDING**

The physical Duel Armory offers three free session loadouts:

- **Blaster** — balanced baseline cadence and range.
- **Rail** — slower, harder precision shot with longer reach.
- **Scatter** — short-range five-pellet spread.

Theoretical maximum damage cadence is deliberately bounded within roughly ten percent across the three loadouts. Selection is server-owned, costs no Coins or Robux, cannot change during a duel, and determines the exact duel tool and server shot rules.

### 0.4.10 — Pet Outfitter v1

**IMPLEMENTED / VERIFICATION PENDING**

The physical Pet Outfitter offers three free cosmetic styles for exact owned pets:

- **Standard** — original pet presentation.
- **Ranger** — a low-profile elemental collar and ranger tag.
- **Starlight** — four subtle elemental body sparks.

Styles reuse the existing pet `variant` field, persist through existing inventory transfers, and replicate to ranch/companion rendering plus read-only visitor inspection. They do not alter creature, element, rarity, income, size, movement, Godly halo behavior, Coins or Robux.

### 0.4.11 — Elemental Bazaar v1

**IMPLEMENTED / VERIFICATION PENDING**

The physical Elemental Bazaar offers five free ranch presentation themes:

- **Standard Camp** — no elemental overlay.
- **Ember Court** — Fire.
- **Tide Court** — Water.
- **Gale Court** — Wind.
- **Root Court** — Earth.

A selected theme adds a bounded nonphysical presentation layer to the player’s camp and recolors only the camp nameplate. Existing Fire/Water/Wind/Earth incubators keep their own authoritative element identity and the starter ranch habitats remain unchanged.

Themes cost no Coins or Robux, replace rather than stack, and do not mutate inventory, pets, pet income, Speed, lab grade, ranch expansion, visible capacity or activity layout.

## Next approved gameplay sequence

After the verification queue and completed shop slices:

1. **Persistence / MVP production** — save progression, then broaden creatures, zones and platform support.

The project should remain centered on the established loop rather than drifting into unrelated side systems.
