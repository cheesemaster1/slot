class_name SlotMath
extends RefCounted

# Payouts are for bet size 1 and represent 3/4/5 of-a-kind from left to right.
const PAYOUTS := {
	"10": {3: 0.20, 4: 1.00, 5: 5.00},
	"J": {3: 0.20, 4: 1.00, 5: 5.00},
	"Q": {3: 0.30, 4: 1.50, 5: 7.50},
	"K": {3: 0.30, 4: 1.50, 5: 7.50},
	"A": {3: 0.40, 4: 2.00, 5: 10.00},
	"SWORD": {3: 1.00, 4: 5.00, 5: 15.00},
	"SHIELD": {3: 1.00, 4: 5.00, 5: 15.00},
	"HELMET": {3: 1.50, 4: 7.50, 5: 17.50},
	"DRAGON_EYE": {3: 2.00, 4: 10.00, 5: 20.00},
	"WILD": {5: 25.00}
}

func count_symbol(grid: Array, symbol_id: String) -> int:
	var count := 0
	for col in grid:
		for symbol in col:
			if symbol == symbol_id:
				count += 1
	return count

func evaluate_paylines(grid: Array, paylines: Array, bet: int, multiplier_cells: Dictionary) -> Dictionary:
	var total_win := 0.0
	var wins: Array = []

	for line_index in range(paylines.size()):
		var line: Array = paylines[line_index]
		if line.size() < 5:
			continue

		var symbols: Array[String] = []
		for point in line:
			var x := int(point[0])
			var y := int(point[1])
			symbols.append(str(grid[x][y]))

		var base_symbol := _resolve_base_symbol(symbols)
		if base_symbol == "" or base_symbol == "SCATTER":
			continue

		var matches := _count_left_matches(symbols, base_symbol)
		if matches < 3:
			continue

		var payout := float(PAYOUTS.get(base_symbol, {}).get(matches, 0.0))
		if payout <= 0.0:
			continue

		var line_win := payout * float(bet)
		var applied_multiplier := 1
		for i in range(matches):
			var point: Array = line[i]
			var cell_key := "%s,%s" % [int(point[0]), int(point[1])]
			if multiplier_cells.has(cell_key):
				applied_multiplier = max(applied_multiplier, int(multiplier_cells[cell_key]))

		line_win *= float(applied_multiplier)
		total_win += line_win

		wins.append({
			"line_index": line_index,
			"symbol": base_symbol,
			"matches": matches,
			"multiplier": applied_multiplier,
			"amount": line_win
		})

	return {
		"total_win": total_win,
		"wins": wins
	}

func _resolve_base_symbol(symbols: Array[String]) -> String:
	for s in symbols:
		if s != "WILD":
			return s
	return "WILD"

func _count_left_matches(symbols: Array[String], base_symbol: String) -> int:
	var matches := 0
	for s in symbols:
		if s == base_symbol or s == "WILD":
			matches += 1
		else:
			break
	return matches
