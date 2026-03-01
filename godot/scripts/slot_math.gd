class_name SlotMath
extends RefCounted

# Basic placeholder payout table for 5-of-a-kind matches.
const PAYOUT_5OAK := {
	"10": 5,
	"J": 5,
	"Q": 6,
	"K": 6,
	"A": 8,
	"SWORD": 12,
	"SHIELD": 14,
	"HELMET": 16,
	"DRAGON_EYE": 20,
	"WILD": 25
}

func count_symbol(grid: Array, symbol_id: String) -> int:
	var count := 0
	for col in grid:
		for symbol in col:
			if symbol == symbol_id:
				count += 1
	return count

func evaluate_paylines(grid: Array, paylines: Array, bet: int, multiplier_cells: Dictionary) -> Dictionary:
	var total_win := 0
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

		var all_match := true
		for s in symbols:
			if s != base_symbol and s != "WILD":
				all_match = false
				break

		if not all_match:
			continue

		var line_win := int(PAYOUT_5OAK.get(base_symbol, 0)) * bet
		if line_win <= 0:
			continue

		var applied_multiplier := 1
		for point in line:
			var cell_key := "%s,%s" % [int(point[0]), int(point[1])]
			if multiplier_cells.has(cell_key):
				applied_multiplier = max(applied_multiplier, int(multiplier_cells[cell_key]))

		line_win *= applied_multiplier
		total_win += line_win

		wins.append({
			"line_index": line_index,
			"symbol": base_symbol,
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
