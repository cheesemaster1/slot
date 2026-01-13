using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SlotController : MonoBehaviour
{
    [Header("Reel Layout")]
    [SerializeField] private int columns = 5;
    [SerializeField] private int rows = 4;
    [SerializeField] private float spinDuration = 1.2f;
    [SerializeField] private float spinStagger = 0.1f;

    [Header("Symbols")]
    [SerializeField] private SlotSymbolDefinition[] symbols;

    [Header("Economy")]
    [SerializeField] private int startingBalance = 1000;
    [SerializeField] private int bet = 25;

    [Header("Paylines")]
    [SerializeField] private List<Payline> paylines = new();

    private int balance;
    private int lastWin;
    private SlotSymbolDefinition[,] currentGrid;
    private bool spinning;

    public event Action<int> OnBalanceChanged;
    public event Action<int> OnWin;
    public event Action<string> OnResult;

    private void Awake()
    {
        balance = startingBalance;
        currentGrid = new SlotSymbolDefinition[columns, rows];
        if (paylines.Count == 0)
        {
            paylines = PaylineLibrary.DefaultPaylines(columns, rows);
        }
        OnBalanceChanged?.Invoke(balance);
    }

    public void Spin()
    {
        if (spinning)
        {
            return;
        }

        if (balance < bet)
        {
            OnResult?.Invoke("Not enough balance");
            return;
        }

        balance -= bet;
        OnBalanceChanged?.Invoke(balance);
        StartCoroutine(SpinRoutine());
    }

    private IEnumerator SpinRoutine()
    {
        spinning = true;
        for (int column = 0; column < columns; column++)
        {
            StartCoroutine(SpinColumn(column));
            yield return new WaitForSeconds(spinStagger);
        }

        yield return new WaitForSeconds(spinDuration);
        EvaluateGrid();
        spinning = false;
    }

    private IEnumerator SpinColumn(int column)
    {
        float elapsed = 0f;
        while (elapsed < spinDuration)
        {
            for (int row = 0; row < rows; row++)
            {
                currentGrid[column, row] = SlotSymbolPicker.Pick(symbols);
            }
            elapsed += Time.deltaTime;
            yield return null;
        }

        for (int row = 0; row < rows; row++)
        {
            currentGrid[column, row] = SlotSymbolPicker.Pick(symbols);
        }
    }

    private void EvaluateGrid()
    {
        lastWin = 0;
        foreach (Payline line in paylines)
        {
            int lineWin = SlotMath.EvaluateLine(line, currentGrid, bet);
            lastWin += lineWin;
        }

        balance += lastWin;
        OnBalanceChanged?.Invoke(balance);
        OnWin?.Invoke(lastWin);
        OnResult?.Invoke(lastWin > 0 ? $"Win {lastWin}!" : "No win");
    }
}

[Serializable]
public class Payline
{
    public string name;
    public int[] rows;

    public Payline(string name, int[] rows)
    {
        this.name = name;
        this.rows = rows;
    }
}

[Serializable]
public class SlotSymbolDefinition
{
    public string id;
    public int payout;
    public bool isWild;
}

public static class SlotSymbolPicker
{
    public static SlotSymbolDefinition Pick(SlotSymbolDefinition[] symbols)
    {
        if (symbols == null || symbols.Length == 0)
        {
            return null;
        }

        int index = UnityEngine.Random.Range(0, symbols.Length);
        return symbols[index];
    }
}

public static class SlotMath
{
    public static int EvaluateLine(Payline line, SlotSymbolDefinition[,] grid, int bet)
    {
        if (line.rows == null || line.rows.Length == 0)
        {
            return 0;
        }

        int columns = grid.GetLength(0);
        SlotSymbolDefinition baseSymbol = null;
        int matchCount = 0;

        for (int column = 0; column < columns; column++)
        {
            int row = Mathf.Clamp(line.rows[column], 0, grid.GetLength(1) - 1);
            SlotSymbolDefinition symbol = grid[column, row];
            if (symbol == null)
            {
                break;
            }

            if (baseSymbol == null && !symbol.isWild)
            {
                baseSymbol = symbol;
            }

            if (baseSymbol == null || symbol.isWild || symbol.id == baseSymbol.id)
            {
                matchCount++;
            }
            else
            {
                break;
            }
        }

        if (matchCount < 3)
        {
            return 0;
        }

        SlotSymbolDefinition payoutSymbol = baseSymbol ?? grid[0, line.rows[0]];
        return payoutSymbol != null ? payoutSymbol.payout * bet : 0;
    }
}

public static class PaylineLibrary
{
    public static List<Payline> DefaultPaylines(int columns, int rows)
    {
        int middle = rows / 2;
        var lines = new List<Payline>
        {
            new Payline("Middle", RepeatRow(columns, middle)),
            new Payline("Top", RepeatRow(columns, rows - 1)),
            new Payline("Bottom", RepeatRow(columns, 0)),
            new Payline("High", ZigZag(columns, rows - 1, middle)),
            new Payline("Low", ZigZag(columns, 0, middle)),
            new Payline("V", VShape(columns, middle, 0)),
            new Payline("Inverted V", VShape(columns, middle, rows - 1)),
            new Payline("Wave", Wave(columns, middle, rows)),
            new Payline("Saw", Saw(columns, rows)),
            new Payline("Stair", Stair(columns, rows)),
        };

        return lines;
    }

    private static int[] RepeatRow(int columns, int row)
    {
        int[] rows = new int[columns];
        for (int i = 0; i < columns; i++)
        {
            rows[i] = row;
        }
        return rows;
    }

    private static int[] ZigZag(int columns, int edge, int middle)
    {
        int[] rows = new int[columns];
        for (int i = 0; i < columns; i++)
        {
            rows[i] = i % 2 == 0 ? edge : middle;
        }
        return rows;
    }

    private static int[] VShape(int columns, int middle, int edge)
    {
        int[] rows = new int[columns];
        int half = columns / 2;
        for (int i = 0; i < columns; i++)
        {
            int offset = Math.Abs(i - half);
            rows[i] = i == half ? middle : edge;
            if (rows[i] == edge && offset > 1)
            {
                rows[i] = middle;
            }
        }
        return rows;
    }

    private static int[] Wave(int columns, int middle, int rows)
    {
        int[] result = new int[columns];
        for (int i = 0; i < columns; i++)
        {
            float wave = Mathf.Sin(i * Mathf.PI / (columns - 1));
            int row = Mathf.RoundToInt((rows - 1) * wave);
            result[i] = Mathf.Clamp(row, 0, rows - 1);
        }
        return result;
    }

    private static int[] Saw(int columns, int rows)
    {
        int[] result = new int[columns];
        for (int i = 0; i < columns; i++)
        {
            result[i] = i % rows;
        }
        return result;
    }

    private static int[] Stair(int columns, int rows)
    {
        int[] result = new int[columns];
        int current = 0;
        for (int i = 0; i < columns; i++)
        {
            result[i] = current;
            current = (current + 1) % rows;
        }
        return result;
    }
}
