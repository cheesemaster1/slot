# Dragon & Knight Slots (Godot 4 Prototype)

This repository contains a **runnable Godot 4 skeleton** for a 5x5 slot game inspired by RIP City pacing with custom mechanics:

- **Dragon Breath (vertical wild conversion):** `DRAGON` symbols can land anywhere on the grid. After reels stop, each DRAGON breathes fire downward in its own column, turning itself and all symbols below into `WILD` before paylines are evaluated.
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

## Checked-in progress screenshots

To capture screenshots that are committed to the repo (so you can review progress without running locally):

```bash
./scripts/capture_screenshots.sh
```

This writes:
- `docs/screenshots/godot_progress_1.svg`
- `docs/screenshots/godot_progress_2.svg`

These files are tracked in git and intended for quick visual PR review.
The screenshots are committed as text-based SVG files with embedded JPEG data so review tools that reject binary diffs can still handle them.

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

## Payout table (bet = 1)

This prototype now evaluates line wins for 3/4/5-of-a-kind from left to right using the provided payout values (ordered from lowest to highest symbol value).

## UI/feedback improvements in this iteration

- Symbols now render as centered text labels in each tile for readability during fast prototyping.
- Reel spin sequence animates reel-by-reel before final result settles.
- Winning paylines animate with a moving line overlay.
- A floating `+win` popup appears on the grid for each line win.

## Current scope

- This is a **logic-first skeleton** for rapid iteration.
- Art, reel animation, and production balancing are intentionally deferred.
