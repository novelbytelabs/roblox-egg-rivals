# Stage 3 Refinement 0.3.2 — Elemental Camps and Pet Pens

Status: IMPLEMENTED; MOONWOOD-0.3.2-r2 passed 24/24 engine checks. Human acceptance remains open.

This is a historical bounded engineering specification. Later canonical design decisions in DESIGN_BIBLE.md and DECISION_LEDGER.md govern future work, including Godly rarity and the revised hidden-Night-egg rules.

## Locked design decisions

- Preserve the accepted Stage 2 PoC and the 0.3.1 Moonwood candidate.
- Expand each player camp without expanding the overall vertical-slice world.
- Each camp receives four elemental incubators: Fire, Water, Wind, and Earth.
- The egg determines the base creature. The chosen incubator determines its element.
- Four base creatures are used in this slice: Skunk, Lizard, Gorilla, and Dragon.
- Resulting pets are combinations such as Fire Dragon, Water Dragon, Wind Dragon, and Earth Dragon.
- Rarity remains a separate progression/economy property from creature and element.
- The four daytime Forest nests map to the four base creatures.
- Night eggs use the same creature system and retain Legendary/Mythic rarity.
- Element selection is explicit. Auto-hatch no longer chooses an element on the player's behalf.
- Each elemental incubator is an independent slot, allowing up to four simultaneous incubations.
- Each camp receives a clearly marked personal respawn pad.
- Each camp receives a physical pet pen behind the camp.
- Exactly one owned pet may be the active companion at a time.
- The active companion follows behind its owner.
- Other owned pets are displayed in the owner's pen.
- The first hatched pet becomes active automatically if the player has no active pet.
- Collection UI provides SET ACTIVE and SEND TO PEN actions for pets.
- Penned and active pets both continue to generate their normal passive income.
- Duel stake selection may select either an active or penned eligible pet.
- A pet entering escrow disappears from active/pen presentation until the duel resolves.
- If ownership changes after a duel, that pet defaults to the winner's pen unless explicitly activated later.
- Physical drag-and-drop placement inside the pen is out of scope for this vertical slice.

## Acceptance targets

1. Four visually distinct elemental incubators exist at every player camp.
2. A carried egg can only be secured into the owner's selected elemental incubator.
3. A Dragon egg placed in each incubator yields the corresponding elemental Dragon.
4. Four incubations can run independently and display independent countdowns.
5. Personal respawn returns the player to their own marked camp pad.
6. One pet follows; additional pets remain visibly contained in the owner's pen.
7. Active/Pen state changes are server-authoritative and visible to every client.
8. Existing bat, snare, Warden, Night, training, economy, and duel mechanics remain intact.
9. Duel escrow/transfer remains atomic and compatible with elemental pets.
10. Two-client Studio regression must pass before 0.3.2 is accepted.

Display policy: eight penned pets per visible page; all owned pets remain in Collection and earn income. Use the pen-page buttons to view the rest.
