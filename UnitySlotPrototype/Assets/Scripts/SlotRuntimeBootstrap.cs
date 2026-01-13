using System.Collections.Generic;
using UnityEngine;

public class SlotRuntimeBootstrap : MonoBehaviour
{
    [SerializeField] private SlotController slotController;
    [SerializeField] private Color backgroundColor = new Color(0.05f, 0.04f, 0.1f, 0.95f);
    [SerializeField] private int fontSize = 20;
    [SerializeField] private Vector2 cellSize = new Vector2(140f, 70f);
    [SerializeField] private Vector2 gridSpacing = new Vector2(12f, 12f);

    private string balanceText = "Balance: 0";
    private string winText = "Win: 0";
    private string resultText = "Result: -";
    private List<string> cellLabels = new();

    private void Awake()
    {
        if (slotController == null)
        {
            slotController = GetComponent<SlotController>();
        }
    }

    private void Start()
    {
        HookEvents();
        InitializeGridLabels();
    }

    private void HookEvents()
    {
        if (slotController == null)
        {
            return;
        }

        slotController.OnBalanceChanged += UpdateBalance;
        slotController.OnWin += UpdateWin;
        slotController.OnResult += UpdateResult;
        slotController.OnGridUpdated += UpdateGrid;
    }

    private void InitializeGridLabels()
    {
        int columns = slotController != null ? slotController.Columns : 5;
        int rows = slotController != null ? slotController.Rows : 4;
        cellLabels.Clear();
        for (int i = 0; i < columns * rows; i++)
        {
            cellLabels.Add("--");
        }
    }

    private void UpdateBalance(int balance)
    {
        balanceText = $"Balance: {balance}";
    }

    private void UpdateWin(int win)
    {
        winText = $"Win: {win}";
    }

    private void UpdateResult(string result)
    {
        resultText = $"Result: {result}";
    }

    private void UpdateGrid(SlotSymbolDefinition[,] grid)
    {
        if (grid == null || cellLabels.Count == 0)
        {
            return;
        }

        int columns = grid.GetLength(0);
        int rows = grid.GetLength(1);
        int index = 0;
        for (int row = rows - 1; row >= 0; row--)
        {
            for (int column = 0; column < columns; column++)
            {
                if (index >= cellLabels.Count)
                {
                    return;
                }

                SlotSymbolDefinition symbol = grid[column, row];
                cellLabels[index] = symbol != null ? symbol.displayName : "--";
                index++;
            }
        }
    }

    private void OnGUI()
    {
        int columns = slotController != null ? slotController.Columns : 5;
        int rows = slotController != null ? slotController.Rows : 4;
        int cellCount = columns * rows;
        if (cellLabels.Count != cellCount)
        {
            InitializeGridLabels();
        }

        Rect backgroundRect = new Rect(0, 0, Screen.width, Screen.height);
        Color previousColor = GUI.color;
        GUI.color = backgroundColor;
        GUI.Box(backgroundRect, GUIContent.none);
        GUI.color = previousColor;

        Rect panelRect = new Rect((Screen.width - 900f) / 2f, (Screen.height - 520f) / 2f, 900f, 520f);
        GUI.Box(panelRect, GUIContent.none);

        Rect headerRect = new Rect(panelRect.x + 20f, panelRect.y + 20f, panelRect.width - 40f, 50f);
        GUI.Box(headerRect, GUIContent.none);

        GUIStyle labelStyle = new GUIStyle(GUI.skin.label)
        {
            fontSize = fontSize,
            alignment = TextAnchor.MiddleCenter,
            normal = { textColor = Color.white }
        };

        GUI.Label(new Rect(headerRect.x + 10f, headerRect.y, 260f, headerRect.height), balanceText, labelStyle);
        GUI.Label(new Rect(headerRect.center.x - 130f, headerRect.y, 260f, headerRect.height), winText, labelStyle);
        GUI.Label(new Rect(headerRect.xMax - 270f, headerRect.y, 260f, headerRect.height), resultText, labelStyle);

        float gridWidth = columns * cellSize.x + (columns - 1) * gridSpacing.x;
        float gridHeight = rows * cellSize.y + (rows - 1) * gridSpacing.y;
        float gridStartX = panelRect.center.x - gridWidth / 2f;
        float gridStartY = headerRect.yMax + 20f;

        GUIStyle cellStyle = new GUIStyle(GUI.skin.box)
        {
            fontSize = fontSize + 4,
            alignment = TextAnchor.MiddleCenter,
            normal = { textColor = Color.white }
        };

        int index = 0;
        for (int row = 0; row < rows; row++)
        {
            for (int column = 0; column < columns; column++)
            {
                float x = gridStartX + column * (cellSize.x + gridSpacing.x);
                float y = gridStartY + row * (cellSize.y + gridSpacing.y);
                Rect cellRect = new Rect(x, y, cellSize.x, cellSize.y);
                GUI.Box(cellRect, cellLabels[index], cellStyle);
                index++;
            }
        }

        Rect buttonRect = new Rect(panelRect.center.x - 100f, panelRect.yMax - 80f, 200f, 50f);
        if (GUI.Button(buttonRect, "SPIN"))
        {
            slotController?.Spin();
        }
    }
}
