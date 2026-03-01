# Dragon & Knight Slots (Godot 4 Prototype)

This repository contains a **runnable Godot 4 skeleton** for a 5x5 slot game inspired by RIP City pacing with custom mechanics:

- **Dragon Breath (vertical wild conversion):** Dragon picks one reel and a start row. That reel becomes `WILD` from that row downward.
- **Knight Slash (horizontal multipliers):** Knight picks one row and applies multipliers only where that row intersects active Dragon fire cells.
- **Bonus trigger:** 3+ scatters enters bonus logic mode (higher feature chances).

## Local Godot 4 setup in this repo (portable)

To bootstrap a local portable Godot 4 binary (no system install required):

```bash
./scripts/setup_godot4.sh
```

This downloads the official Linux binary into `tools/godot/` and creates `tools/godot/godot4`.

You can then run checks/headless load from repo root:

```bash
./tools/godot/godot4 --headless --path godot --quit --check-only
```

## Run locally in Godot 4

1. Open the `godot/` folder as a project in Godot 4.
2. Press Play.
3. Use the simple debug UI:
   - choose bet size
   - optional bonus-mode toggle
   - click **SPIN**
4. Inspect generated grid, fire cells, multiplier cells, and line wins in the result panel.

## Placeholder art assets

I added simple generated placeholder SVG assets for all current symbols plus side characters:
- symbols: `godot/assets/symbols/*.svg`
- characters: `godot/assets/characters/dragon.svg`, `godot/assets/characters/knight.svg`

These are temporary stand-ins so we can test layout and gameplay flow before final art.
The art is stored as text-based SVG files (not binary PNG) to avoid branch/update issues with binary-file restrictions.

## Repository layout

- `docs/slot_design.md` — game design baseline and mechanic notes
- `godot/project.godot` — Godot project file
- `godot/scenes/main.tscn` — simple runnable UI scene
- `godot/data/game_config.json` — symbols, weights, chances, paylines
- `godot/scripts/`:
  - `rng_service.gd` — RNG helpers
  - `slot_math.gd` — line/scatter evaluation
  - `spin_engine.gd` — spin generation + feature resolution
  - `ui/main.gd` — UI glue for debug spin loop

## Current scope

- This is a **logic-first skeleton** for rapid iteration.
- Art, reel animation, and production balancing are intentionally deferred.
