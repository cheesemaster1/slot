# Neon Nights Slot Prototype

A lightweight HTML/CSS/JS prototype for a playful, neon-themed slot game concept. It focuses on core gameplay loops and a few unique mechanics to evolve later with higher fidelity assets and bonus features.

## Run locally

### Option 1: Node static server

```bash
npm run dev
```

Then open `http://localhost:8000`.

### Option 2: Python static server

```bash
python -m http.server 8000
```

Then open `http://localhost:8000/index.html`.

## Mechanics included

- Heat Meter upgrades symbols to wilds on the next spin once filled.
- Neon Wild substitutes for any symbol and pays 5x on a 3-of-a-kind.
- After Dark Scatter triggers 5 free spins on 3 scatters.
- Hot wins during free spins award +2 extra spins.
