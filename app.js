const reels = [
  document.getElementById("reel-0"),
  document.getElementById("reel-1"),
  document.getElementById("reel-2"),
];
const balanceEl = document.getElementById("balance");
const betEl = document.getElementById("bet");
const winEl = document.getElementById("win");
const resultEl = document.getElementById("result");
const spinButton = document.getElementById("spin");
const betDown = document.getElementById("bet-down");
const betUp = document.getElementById("bet-up");
const heatFill = document.getElementById("heat-fill");
const freeSpinsEl = document.getElementById("free-spins");

const symbols = [
  { id: "rose", label: "Rose", payout: 2 },
  { id: "heels", label: "Heels", payout: 2 },
  { id: "lace", label: "Lace", payout: 3 },
  { id: "mask", label: "Mask", payout: 4 },
  { id: "vip", label: "VIP", payout: 6 },
  { id: "wild", label: "Wild", payout: 5, isWild: true },
  { id: "scatter", label: "Scatter", payout: 0, isScatter: true },
];

const paytable = {
  vip: 6,
  mask: 4,
  lace: 3,
  heels: 2,
  rose: 2,
  wild: 5,
};

let balance = 1000;
let bet = 25;
let heat = 0;
let freeSpins = 0;
let spinning = false;

const clamp = (value, min, max) => Math.max(min, Math.min(max, value));

const updateUI = () => {
  balanceEl.textContent = balance;
  betEl.textContent = bet;
  winEl.textContent = 0;
  heatFill.style.width = `${heat}%`;
  freeSpinsEl.textContent = freeSpins;
};

const randomSymbol = () => {
  const roll = Math.random();
  if (roll > 0.92) return symbols.find((symbol) => symbol.id === "scatter");
  if (roll > 0.84) return symbols.find((symbol) => symbol.id === "wild");
  const regulars = symbols.filter((symbol) => !symbol.isWild && !symbol.isScatter);
  return regulars[Math.floor(Math.random() * regulars.length)];
};

const createReelSymbols = () => Array.from({ length: 3 }, randomSymbol);

const renderReels = (matrix) => {
  matrix.forEach((reelSymbols, index) => {
    const reel = reels[index];
    reel.innerHTML = "";
    reelSymbols.forEach((symbol) => {
      const tile = document.createElement("div");
      tile.className = `symbol ${symbol.isWild ? "wild" : ""} ${symbol.isScatter ? "scatter" : ""}`;
      tile.textContent = symbol.label;
      reel.appendChild(tile);
    });
  });
};

const countScatters = (matrix) =>
  matrix.flat().filter((symbol) => symbol.isScatter).length;

const evaluatePayline = (matrix) => {
  const lineSymbols = [matrix[0][1], matrix[1][1], matrix[2][1]];
  const wilds = lineSymbols.filter((symbol) => symbol.isWild).length;
  const baseSymbol = lineSymbols.find((symbol) => !symbol.isWild) || lineSymbols[0];
  const match = lineSymbols.every(
    (symbol) => symbol.id === baseSymbol.id || symbol.isWild
  );
  if (!match) return { win: 0, label: "No win" };
  const payoutKey = baseSymbol.isWild ? "wild" : baseSymbol.id;
  const payout = paytable[payoutKey] || 0;
  return {
    win: payout * bet,
    label: `${baseSymbol.label} line hit${wilds ? " with wild" : ""}`,
  };
};

const applyHeat = (matrix) => {
  if (heat < 100) return matrix;
  heat = 0;
  resultEl.textContent = "Heat popped! Symbols upgraded to wilds.";
  return matrix.map((reelSymbols) =>
    reelSymbols.map((symbol) =>
      symbol.isScatter ? symbol : symbols.find((item) => item.id === "wild")
    )
  );
};

const spin = () => {
  if (spinning) return;
  if (balance < bet && freeSpins === 0) {
    resultEl.textContent = "Not enough balance.";
    return;
  }

  spinning = true;
  spinButton.disabled = true;

  if (freeSpins === 0) {
    balance -= bet;
  } else {
    freeSpins -= 1;
  }

  let matrix = reels.map(createReelSymbols);
  matrix = applyHeat(matrix);
  renderReels(matrix);

  const lineResult = evaluatePayline(matrix);
  const scatterCount = countScatters(matrix);
  let totalWin = lineResult.win;

  if (lineResult.win > 0) {
    heat = clamp(heat + 25, 0, 100);
  } else {
    heat = clamp(heat + 10, 0, 100);
  }

  if (scatterCount >= 3) {
    freeSpins += 5;
    resultEl.textContent = "After Dark triggered! +5 free spins.";
  } else {
    resultEl.textContent = lineResult.label;
  }

  if (freeSpins > 0 && totalWin >= bet * 4) {
    freeSpins += 2;
    resultEl.textContent = "Hot win! +2 extra free spins.";
  }

  balance += totalWin;
  winEl.textContent = totalWin;
  updateUI();

  spinning = false;
  spinButton.disabled = false;
};

betDown.addEventListener("click", () => {
  bet = clamp(bet - 5, 5, 100);
  updateUI();
});

betUp.addEventListener("click", () => {
  bet = clamp(bet + 5, 5, 100);
  updateUI();
});

spinButton.addEventListener("click", spin);

renderReels(reels.map(createReelSymbols));
updateUI();
