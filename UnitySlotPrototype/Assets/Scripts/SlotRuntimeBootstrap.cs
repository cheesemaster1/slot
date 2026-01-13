using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class SlotRuntimeBootstrap : MonoBehaviour
{
    [SerializeField] private SlotController slotController;
    [SerializeField] private Color backgroundColor = new Color(0.05f, 0.04f, 0.1f, 0.95f);
    [SerializeField] private int fontSize = 24;
    [SerializeField] private Vector2 cellSize = new Vector2(140f, 70f);
    [SerializeField] private Vector2 gridSpacing = new Vector2(12f, 12f);

    private Text balanceText;
    private Text winText;
    private Text resultText;
    private List<Text> cellTexts = new();

    private void Awake()
    {
        if (slotController == null)
        {
            slotController = GetComponent<SlotController>();
        }
    }

    private void Start()
    {
        BuildUI();
        HookEvents();
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

    private void BuildUI()
    {
        Canvas canvas = CreateCanvas();
        CreateBackground(canvas.transform);

        RectTransform panel = CreatePanel(canvas.transform, new Vector2(900f, 520f));
        panel.anchoredPosition = Vector2.zero;

        RectTransform header = CreatePanel(panel, new Vector2(860f, 60f));
        header.anchoredPosition = new Vector2(0f, 210f);
        header.GetComponent<Image>().color = new Color(0.12f, 0.1f, 0.2f, 0.9f);

        balanceText = CreateLabel(header, "Balance: 0", TextAnchor.MiddleLeft);
        balanceText.rectTransform.anchoredPosition = new Vector2(-280f, 0f);

        winText = CreateLabel(header, "Win: 0", TextAnchor.MiddleCenter);
        winText.rectTransform.anchoredPosition = new Vector2(0f, 0f);

        resultText = CreateLabel(header, "Result: -", TextAnchor.MiddleRight);
        resultText.rectTransform.anchoredPosition = new Vector2(260f, 0f);

        RectTransform grid = CreateGrid(panel, new Vector2(700f, 320f));
        grid.anchoredPosition = new Vector2(0f, 20f);

        CreateGridCells(grid, slotController != null ? slotController.Columns : 5,
            slotController != null ? slotController.Rows : 4);

        RectTransform buttonArea = CreatePanel(panel, new Vector2(300f, 80f));
        buttonArea.anchoredPosition = new Vector2(0f, -210f);
        buttonArea.GetComponent<Image>().color = new Color(0.12f, 0.1f, 0.2f, 0.9f);

        Button spinButton = CreateButton(buttonArea, "SPIN");
        spinButton.onClick.AddListener(() => slotController?.Spin());
    }

    private Canvas CreateCanvas()
    {
        GameObject canvasObject = new GameObject("SlotCanvas", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
        Canvas canvas = canvasObject.GetComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;

        CanvasScaler scaler = canvasObject.GetComponent<CanvasScaler>();
        scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        scaler.referenceResolution = new Vector2(1280f, 720f);
        return canvas;
    }

    private void CreateBackground(Transform parent)
    {
        Image image = CreateImage(parent, new Vector2(0, 0));
        image.color = backgroundColor;
        RectTransform rect = image.rectTransform;
        rect.anchorMin = Vector2.zero;
        rect.anchorMax = Vector2.one;
        rect.offsetMin = Vector2.zero;
        rect.offsetMax = Vector2.zero;
    }

    private RectTransform CreatePanel(Transform parent, Vector2 size)
    {
        Image image = CreateImage(parent, size);
        image.color = new Color(0.08f, 0.07f, 0.15f, 0.95f);
        RectTransform rect = image.rectTransform;
        rect.sizeDelta = size;
        rect.anchorMin = new Vector2(0.5f, 0.5f);
        rect.anchorMax = new Vector2(0.5f, 0.5f);
        rect.pivot = new Vector2(0.5f, 0.5f);
        return rect;
    }

    private RectTransform CreateGrid(Transform parent, Vector2 size)
    {
        GameObject gridObject = new GameObject("SlotGrid", typeof(RectTransform), typeof(GridLayoutGroup));
        gridObject.transform.SetParent(parent, false);
        RectTransform rect = gridObject.GetComponent<RectTransform>();
        rect.sizeDelta = size;
        rect.anchorMin = new Vector2(0.5f, 0.5f);
        rect.anchorMax = new Vector2(0.5f, 0.5f);
        rect.pivot = new Vector2(0.5f, 0.5f);

        GridLayoutGroup grid = gridObject.GetComponent<GridLayoutGroup>();
        grid.cellSize = cellSize;
        grid.spacing = gridSpacing;
        grid.childAlignment = TextAnchor.MiddleCenter;
        return rect;
    }

    private void CreateGridCells(RectTransform grid, int columns, int rows)
    {
        int cellCount = columns * rows;
        for (int i = 0; i < cellCount; i++)
        {
            Image cell = CreateImage(grid, cellSize);
            cell.color = new Color(0.13f, 0.12f, 0.25f, 0.9f);
            Text label = CreateLabel(cell.transform, "--", TextAnchor.MiddleCenter);
            label.fontSize = fontSize + 6;
            cellTexts.Add(label);
        }
    }

    private Image CreateImage(Transform parent, Vector2 size)
    {
        GameObject imageObject = new GameObject("Image", typeof(RectTransform), typeof(Image));
        imageObject.transform.SetParent(parent, false);
        RectTransform rect = imageObject.GetComponent<RectTransform>();
        rect.sizeDelta = size;
        return imageObject.GetComponent<Image>();
    }

    private Text CreateLabel(Transform parent, string text, TextAnchor alignment)
    {
        GameObject textObject = new GameObject("Label", typeof(RectTransform), typeof(Text));
        textObject.transform.SetParent(parent, false);
        Text label = textObject.GetComponent<Text>();
        label.text = text;
        label.alignment = alignment;
        label.font = Resources.GetBuiltinResource<Font>("Arial.ttf");
        label.fontSize = fontSize;
        label.color = Color.white;
        RectTransform rect = label.rectTransform;
        rect.sizeDelta = new Vector2(300f, 40f);
        return label;
    }

    private Button CreateButton(Transform parent, string label)
    {
        Image buttonImage = CreateImage(parent, new Vector2(240f, 60f));
        buttonImage.color = new Color(0.9f, 0.3f, 0.8f, 1f);
        Button button = buttonImage.gameObject.AddComponent<Button>();
        Text buttonLabel = CreateLabel(buttonImage.transform, label, TextAnchor.MiddleCenter);
        buttonLabel.fontSize = fontSize + 4;
        buttonLabel.color = Color.black;
        return button;
    }

    private void UpdateBalance(int balance)
    {
        if (balanceText != null)
        {
            balanceText.text = $"Balance: {balance}";
        }
    }

    private void UpdateWin(int win)
    {
        if (winText != null)
        {
            winText.text = $"Win: {win}";
        }
    }

    private void UpdateResult(string result)
    {
        if (resultText != null)
        {
            resultText.text = $"Result: {result}";
        }
    }

    private void UpdateGrid(SlotSymbolDefinition[,] grid)
    {
        if (grid == null || cellTexts.Count == 0)
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
                if (index >= cellTexts.Count)
                {
                    return;
                }

                SlotSymbolDefinition symbol = grid[column, row];
                cellTexts[index].text = symbol != null ? symbol.displayName : "--";
                index++;
            }
        }
    }
}
