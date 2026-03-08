# Neon Nights Slot Prototype (Unity)

This project now targets Unity for the production-ready slot experience. The web prototype is kept for quick UI iteration, but the Unity project is the source of truth for gameplay and animation work moving forward.

## Unity project

The Unity project lives in `UnitySlotPrototype/`. Open it in Unity 6000.3.3f1 (or newer 6000.3.x).

### Key scripts

- `SlotController.cs` handles reel layout, spins, paylines, and win evaluation.
- `SlotSpinAnimator.cs` provides a reusable reel spin animation that can be wired to UI or 3D reels.

### Quick setup

1. Open `UnitySlotPrototype/` in Unity Hub.
2. Load the included `Assets/Scenes/SlotPrototype.unity` scene (or press Play to use the default build scene).
3. Press Play to see the runtime UI panel and placeholder symbols render.
4. Assign symbols (ScriptableObject or inspector entries) and hook up your reel visuals.
5. In the scene, wire `SlotSpinAnimator` to your reel transforms if you replace the placeholder container.

## Legacy web prototype

You can still open `index.html` directly for a quick visual reference or run the Node server:

```bash
npm run dev
```

Then visit `http://localhost:8000`.
