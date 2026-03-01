# Dragon & Knight Slot - Design Baseline (v0.2)

## Core game setup

- Grid: **5 reels x 5 rows**
- Initial win model: configurable left-to-right paylines
- Symbols:
  - Low: `10`, `J`, `Q`, `K`, `A`
  - Premium: `SWORD`, `SHIELD`, `HELMET`, `DRAGON_EYE`
  - Special: `WILD`, `SCATTER`

## Corrected feature behavior

### 1) Dragon Breath (vertical partial-to-full wild conversion)
- Dragon can trigger on any spin based on mode chance.
- Dragon chooses:
  - reel index (`0..4`)
  - **start row** (`0..4`)
- All cells from `start_row` down to the bottom of that reel become `WILD`.
  - If start row is top (`0`), full reel becomes wild.
  - If start row is mid (`2`), lower segment becomes wild.

### 2) Knight Slash (horizontal multiplier carrier)
- Knight can trigger on any spin based on mode chance.
- Knight chooses one row (`0..4`).
- Knight **does not** change symbols to wild.
- Knight only applies multipliers where its row intersects active Dragon fire cells.

### 3) Multiplier placement
- Multiplier cells can only exist on cells that are both:
  - in Dragon fire area, and
  - on Knight slash row.
- Base multiplier range: `x2-x5`.
- Bonus multiplier range: `x3-x8`.

## Bonus game

- Trigger: **3 or more scatters** anywhere on grid.
- Initial implementation: one bonus variant only.
- Bonus increases Dragon/Knight trigger rates and multiplier range.

## Probability targets (starting point)

### Base game
- Dragon: `0.22`
- Knight: `0.20`
- Both override: `0.10`

### Bonus game
- Dragon: `0.45`
- Knight: `0.40`
- Both override: `0.30`

## Iteration roadmap

1. **Logic lock-in**
   - validate fire span and intersection multipliers over many spins
2. **Visual pass**
   - reel spin animation, Dragon/Knight VFX overlays
3. **Balancing**
   - tune symbol weights, payouts, and feature rates with simulation
4. **Bonus depth**
   - add retriggers and feature upgrades
