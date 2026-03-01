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
- A dedicated `DRAGON` symbol can land on any reel/row.
- After reels stop, each DRAGON symbol breathes fire down its column.
- Fire conversion is animated top-to-bottom from the DRAGON position.
- The DRAGON symbol itself and all symbols below it convert to `WILD` before payline evaluation.

### 2) Knight Slash (horizontal multiplier carrier)
- Knight can trigger on any spin based on mode chance.
- Knight chooses one row (`0..4`) and performs a horizontal slash.
- If slash intersects one or more Dragon-fire columns, all wilds in each intersected column become multiplier wilds.
- Multipliers are weighted (`x2`..`x250`) with high values much rarer.
- If slash does not intersect any fire column, it is a visible miss.

### 3) Multiplier placement
- Multiplier cells can only exist on cells that are both:
  - in Dragon fire area, and
  - on Knight slash row.
- Base multiplier range: `x2-x5`.
- Bonus multiplier range: `x3-x8`.

## Bonus game

- Trigger: **3 or more scatters** anywhere on grid.
- Initial implementation: one bonus variant only.
- Trigger awards 10 automatic free bonus spins.
- Bonus increases Dragon landing/expansion frequency, Knight slash frequency, and high multiplier odds.
- End-of-bonus splash displays total bonus win.

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
