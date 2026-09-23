# Egg Rivals — Open-World Interference and Duels

Status: approved design direction.

Egg Rivals contains two distinct competitive systems:

1. open-world interference that contests a carried egg;
2. opt-in arena duels with explicit offers and first-to-five combat.

They should not collapse into one continuous deathmatch.

## Open-world interference

Open-world hostile tools exist to make egg theft contestable.

Baseline Bat behavior:

- only meaningful against another player carrying an egg;
- short range;
- a valid hit knocks the egg loose;
- the carrier is reset / displaced according to current theft rules;
- the dropped egg remains physically present;
- the defender attempts to reclaim it;
- another player can grab it first.

The Bat should have readable swing animation, server-side range validation, and a cooldown.

Safe zones disable hostile interference.

## Snare

The Snare is an approved route-control tool.

It can be placed outside safe areas and temporarily slows an enemy egg carrier.

The snare should:

- arm clearly;
- expire;
- be server-authoritative;
- affect the theft contest rather than permanently harm inventory;
- remain bounded in count so routes do not become unplayable.
## Future interference directions

Compatible later tools include:

- Launch Pad Trap: throws / redirects a carrier;
- Barrier Trap: temporary route denial.

These are later directions, not a requirement to fill the map with hazards.

Open-world interference should preserve the heist loop. Non-carriers should not become farmable targets for unrelated rewards.

## Duel challenge

Duels are opt-in.

A player challenges another player at close range. The target receives Accept / Decline.

Players carrying active theft eggs cannot enter a duel until the egg is secured or dropped.

Once accepted, both players review the duel offer.

## Explicit stake selection

Each player chooses one eligible owned item.

Eligible categories may include eggs, pets, and other approved stakeable items.

The UI must show both exact offers before either player commits.

Changing either offer clears both confirmations.

Favorite / Locked items are ineligible.

The server revalidates ownership immediately before escrow.
## Escrow

Selected stakes enter server-controlled escrow before arena combat.

Escrow rules:

- both exact instance IDs are known;
- neither item remains freely mutable during the duel;
- disconnect / timeout / cancellation has deterministic resolution;
- no duplicate transfer;
- no silent item deletion;
- winning transfer is atomic.

A pet entering escrow disappears from normal active / pen presentation until resolved.

If a pet transfers to the winner, it defaults to the winner's pen unless the winner later chooses it as active.

## Arena match

Current baseline:

- isolated duel arena;
- symmetric DuelBlaster baseline;
- first player to 5 eliminations wins;
- real damage / elimination rounds;
- score is server-owned;
- cover blocks shots;
- server validates shot cadence and hit conditions;
- players return to the main world after resolution.

The duel system is intended to evoke the skill-forward RIVALS-style competitive fantasy while remaining its own Egg Rivals implementation.
## Competitive progression

Production weapon candidates can include:

- balanced Blaster;
- Burst weapon;
- precision Rail weapon;
- short-range Scatter weapon.

Different weapons should be sidegrades / styles rather than direct purchased superiority.

The Duel Armory is primarily a home for unlock presentation, balanced weapon choice, skins, sights, effects, and animations.

Paid monetization must not determine duel outcomes through raw power.

## Sprint rivalry

Speed competition also exists outside FPS duels.

Sprint Challenges and Training Trials can provide rivalry through movement skill, records, ghosts, trophies, and titles.

This keeps "Rivals" broader than gun combat.

## Publication gate

Item-transfer duels require a current Roblox policy review before public launch.

Until that review is completed, Studio-only staking is a safe development constraint.

If public item wagering is not acceptable under current platform rules, preserve the same offer / escrow / match architecture but substitute an approved non-item-transfer reward such as trophies or duel tokens.
