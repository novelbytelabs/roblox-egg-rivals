# Egg Rivals

Private canonical repository for Egg Rivals, a Roblox speed-heist, pet-collection, base-building, and opt-in duel game.

Current engineering baseline: `MOONWOOD-0.3.2-r2`.

The imported baseline passed 24/24 two-client Roblox Studio engine checks. Human presentation and gameplay-feel review remains an explicit gate.

Core loop:

`train -> steal an egg -> escape -> choose an element -> hatch a pet -> earn -> upgrade -> collect -> compete`

Four elemental incubators determine pet element: Fire, Water, Wind, and Earth. Creature identity comes from the egg.

Current source is under `src/`. Rojo projects are `default.project.json` and `test.project.json`.

Design direction is maintained in `docs/GAME_DESIGN.md`, with focused visual guidance in `docs/NIGHT_VISUAL_DIRECTION.md`.

Generated `.rbxlx` files, Studio recovery files, and local builds are not canonical source and must not be committed.

Item-transfer duels remain Studio-only pending a Roblox publication-policy review. Progress is session-only at the current stage.
