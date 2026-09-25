# Egg Rivals Roadmap

## Current engineering candidate

**EGG-RIVALS-0.4.3-rc1 — ELEMENTAL TUNING v1** is the current verified engineering candidate.

- Exact tested source bytes committed at: `f4be2411712ffec3f3dfd8c23f69dea7307a45d1`
- Source digest: `0875af46f723f9a964062a3d255d126450934438dc91699d1f76a066eef648be`
- Exact-source multiplayer regression: **104 passed / 0 failed**
- Real Studio topology: one server + two clients
- PLAY/TEST gameplay scripts: **37 byte-identical**
- Human Elemental Tuning feel/balance review: **PENDING**
- Roblox publication: **NOT PERFORMED**
- Merge to `main`: **NOT AUTHORIZED**

The 0.4.2 99/99 Ranger candidate, 0.4.1 90/90 Sprint candidate, 0.4.0-rc2 86/86 Night/Forest candidate, rc1 77/77 candidate and `MOONWOOD-0.3.2-r2` 24/24 baseline remain preserved historical references.

## 0.4.3 achieved mechanically

Engineering verification covers:

- Standard mode reproducing the verified Speed Lab baseline;
- free server-owned Fire, Water, Wind and Earth treadmill tuning;
- Fire: faster Overdrive charge with slower Momentum build;
- Water: faster Momentum build with slower Overdrive charge;
- Wind: stronger but shorter open-world Overdrive burst with slower charge;
- Earth: longer Momentum retention with slower Overdrive charge;
- switching only at the player's Speed Lab or Trainer Workshop;
- no switching with stored Momentum, stored charge or active Overdrive;
- no tuning purchase, new currency, pet-stat coupling or inventory authority;
- absolute 68 studs/s Overdrive cap retained;
- Training Trial and Sprint movement remaining normalized at WalkSpeed 45;
- real client selection through the rendered Trainer UI;
- all prior Ranger, Sprint, Night/Forest, trade, Exchange, ranch, Warden, incubation, duel and Trial regressions.

Exact evidence: `docs/STAGE3_043_VERIFICATION.md`.

## Current product gate

Mechanics-first development may continue, but owner feel review remains separate. Eventually evaluate:

1. whether each tuning mode has an understandable identity;
2. whether the tradeoffs feel meaningful without producing an obvious dominant choice;
3. whether switching rules are understandable;
4. whether Wind's stronger/shorter burst feels useful;
5. whether tuning makes training and open-world escape decisions more interesting.

## Mechanics backlog

Approved mechanics still available for future slices include:

- Speed Mastery / control-focused unlocks — approved concept but not yet sufficiently specified for implementation;
- social drafting for nearby players training together;
- richer ranch interaction and visitor mechanics;
- deeper shop ecosystems;
- additional creatures and later zones;
- persistence when the project reaches MVP scope.

The next slice should deepen the central game rather than add disconnected systems. Social drafting is the most tightly specified remaining Speed Lab mechanic and is the preferred next bounded design target.

## Later production gates

Persistence, broader zones, mobile/console support, public policy-reviewed staking, monetization implementation, broader live operations and public Roblox release remain later work.

No feature branch merges to `main` until owner review explicitly authorizes it.
