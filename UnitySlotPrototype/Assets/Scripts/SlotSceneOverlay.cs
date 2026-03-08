using UnityEngine;

public class SlotSceneOverlay : MonoBehaviour
{
    private void OnGUI()
    {
        GUIStyle style = new GUIStyle(GUI.skin.label)
        {
            fontSize = 20,
            fontStyle = FontStyle.Bold,
            normal = { textColor = Color.white }
        };

        GUI.Label(new Rect(20, 20, 600, 30), "Neon Nights Unity Prototype Loaded", style);
        GUI.Label(new Rect(20, 50, 600, 24), "Hook up reel visuals and symbols to see gameplay.", GUI.skin.label);
    }
}
