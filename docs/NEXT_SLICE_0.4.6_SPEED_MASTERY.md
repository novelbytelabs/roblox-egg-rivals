# Egg Rivals 0.4.6 — Speed Mastery v1

Status: **IMPLEMENTATION CANDIDATE — VERIFICATION PENDING**

Purpose: deepen Speed progression with control-focused mastery unlocks without increasing the permanent Speed ceiling, adding another currency, or weakening normalized competitive movement.

## Design intent

Speed Mastery is not another multiplier ladder.

Permanent Speed, Machine Grade, Momentum, Elemental Tuning, Social Drafting and Overdrive already provide progression and tactical power. Mastery adds **control over high movement capability**.

The v1 candidate adds two server-owned unlocks derived from Machine Grade:

1. **Precision Mode** — deliberate slower open-world pacing for tight navigation.
2. **Overdrive Cut** — voluntarily end an active Overdrive burst early.

No separate Mastery currency, XP bar, purchase tree, rebirth or persistence dependency is introduced.

## Precision Mode

Unlock: **Turbo grade** (Machine Grade 3).

Control: **C** toggles Precision Mode.

When active in ordinary open-world movement:

- the server computes the normal mapped movement first;
- Precision applies 70% of that mapped speed;
- final WalkSpeed never falls below the ordinary 16-stud/s baseline;
- permanent Speed is unchanged;
- Machine Grade is unchanged;
- Momentum, Overdrive charge and Motion Energy are unchanged;
- Coins and inventory are unchanged.

Precision may remain selected while carrying an open-world egg because it only reduces movement capability.

### Authority priority

Precision never overrides stronger movement authorities.

Priority remains:

1. duel;
2. Sprint countdown / normalized Sprint movement;
3. normalized solo Training Trial;
4. Snare slow;
5. ordinary open-world movement, including Overdrive and Precision.

Therefore Precision cannot alter Duel, Sprint or Trial movement and cannot defeat a Snare.

Precision selection may remain toggled while another authority is active, but it is ignored until ordinary open-world movement resumes.

## Overdrive Cut

Unlock: **Hyper grade** (Machine Grade 4).

Control: **Q** retains its existing Overdrive function.

When no burst is active, Q behaves exactly as before and requires a full charge.

When a burst is active:

- Hyper-or-higher players may press Q again to end the burst immediately;
- stored charge remains zero;
- no charge is refunded;
- the existing Overdrive-use record is not duplicated;
- one separate Overdrive-cut record increments;
- movement is recomputed immediately.

Below Hyper grade, an active Overdrive cannot be cut early.

This is a control affordance, not extra movement power.

## UI

The Speed Lab HUD exposes Precision state:

- locked before Turbo;
- C • PRECISION OFF when unlocked;
- C • PRECISION ON when active.

During a cuttable active Overdrive, the existing Q control reads **Q • CUT OVERDRIVE**.

The Trainer panel explains both unlocks and their required grades.

## Records

Session records add:

- Precision toggles;
- Overdrive cuts.

These are informational only and create no reward or progression authority.

## Server interface

Preferred additions stay inside the existing Speed Lab authority:

- SpeedLab:setPrecision(player, active)
- expanded SpeedLab:activate(player) semantics for early cut
- mastery fields in SpeedLab:snapshot(player)

Game.lua remains the composition root and applies movement priority.

The client may request an explicit Precision boolean. The client does not supply speed values, mastery unlock state, cut duration or charge refunds.

## Verification requirements

Directly cover:

- Precision rejected before Turbo;
- explicit Precision enable/disable at Turbo or above;
- exact open-world reduction from the normal mapped speed;
- minimum movement floor preserved;
- permanent Speed unchanged;
- Precision cannot alter Trial movement;
- Precision cannot alter Sprint movement;
- Precision cannot alter Duel movement;
- Precision cannot override Snare speed;
- Precision composes with an active Overdrive only by reducing the mapped burst;
- active Overdrive cannot be cut before Hyper;
- Hyper-or-higher Overdrive Cut ends the burst immediately;
- Cut refunds no charge and does not double-count Overdrive use;
- Precision / Cut mutate no Coins or inventory;
- real client C input reaches authoritative Precision state;
- all prior 110 checks remain green.

## Out of scope

- higher permanent Speed ceiling;
- dash, teleport, wall-run, slide or grappling mechanics;
- stamina;
- new mastery currency;
- paid movement power;
- Mastery affecting normalized Sprint or Training Trial;
- Mastery affecting duel movement;
- Mastery negating Snare;
- persistence;
- mobile/gamepad bindings beyond keeping later adaptation feasible.

## Claim boundary

This packet defines the 0.4.6 implementation candidate. It does not claim the 70% Precision factor, Turbo/Hyper thresholds, HUD presentation or feel are owner-accepted until playtesting.
