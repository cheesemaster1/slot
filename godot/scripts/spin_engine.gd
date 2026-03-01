class_name SpinEngine
extends RefCounted

const RngServiceScript := preload("res://scripts/rng_service.gd")
const SlotMathScript := preload("res://scripts/slot_math.gd")

var _rng: RefCounted = RngServiceScript.new()
var _math: RefCounted = SlotMathScript.new()
var _config: Dictionary = {}

func set_config(config: Dictionary) -> void:
	_config = config

func set_seed(seed_value: int) -> void:
	_rng.call("seed_rng", seed_value)

func spin(bet: int, is_bonus: bool = false) -> Dictionary:
	var grid: Array = _build_grid()
	var feature_state: Dictionary = _resolve_features(is_bonus)
	var fire_cells: Dictionary = _apply_dragon_fire(grid, feature_state)
	var multiplier_cells: Dictionary = _resolve_multipliers(fire_cells, feature_state, is_bonus)
	var pay_eval: Dictionary = _math.call("evaluate_paylines", grid, _config["paylines"], bet, multiplier_cells)

	var scatter_count: int = int(_math.call("count_symbol", grid, "SCATTER"))
	var bonus_trigger: bool = scatter_count >= int(_config["bonus"]["scatter_trigger"])

	return {
		"grid": grid,
		"dragon_reel": feature_state["dragon_reel"],
		"dragon_start_row": feature_state["dragon_start_row"],
		"knight_row": feature_state["knight_row"],
		"fire_cells": fire_cells,
		"multiplier_cells": multiplier_cells,
		"scatter_count": scatter_count,
		"bonus_trigger": bonus_trigger,
		"total_win": pay_eval["total_win"],
		"wins": pay_eval["wins"]
	}

func _build_grid() -> Array:
	var reels := int(_config["grid"]["reels"])
	var rows := int(_config["grid"]["rows"])
	var weight_map: Dictionary = _config["weights"]

	var grid: Array = []
	for x in range(reels):
		var column: Array = []
		for _y in range(rows):
			column.append(_rng.call("pick_weighted", weight_map))
		grid.append(column)
	return grid

func _resolve_features(is_bonus: bool) -> Dictionary:
	var mode := "bonus" if is_bonus else "base"
	var chance: Dictionary = _config["feature_chance"][mode]

	var force_both: bool = float(_rng.call("randf")) < float(chance["both_override"])
	var dragon: bool = force_both or (float(_rng.call("randf")) < float(chance["dragon"]))
	var knight: bool = force_both or (float(_rng.call("randf")) < float(chance["knight"]))

	var dragon_reel := -1
	var dragon_start_row := -1
	var knight_row := -1

	if dragon:
		dragon_reel = int(_rng.call("randi_range", 0, int(_config["grid"]["reels"]) - 1))
		dragon_start_row = int(_rng.call("randi_range", 0, int(_config["grid"]["rows"]) - 1))

	if knight:
		knight_row = int(_rng.call("randi_range", 0, int(_config["grid"]["rows"]) - 1))

	return {
		"dragon_reel": dragon_reel,
		"dragon_start_row": dragon_start_row,
		"knight_row": knight_row
	}

func _apply_dragon_fire(grid: Array, feature_state: Dictionary) -> Dictionary:
	var dragon_reel := int(feature_state["dragon_reel"])
	var dragon_start_row := int(feature_state["dragon_start_row"])
	if dragon_reel < 0 or dragon_start_row < 0:
		return {}

	var rows := int(_config["grid"]["rows"])
	var fire_cells: Dictionary = {}
	for row in range(dragon_start_row, rows):
		grid[dragon_reel][row] = "WILD"
		var key := "%s,%s" % [dragon_reel, row]
		fire_cells[key] = true

	return fire_cells

func _resolve_multipliers(fire_cells: Dictionary, feature_state: Dictionary, is_bonus: bool) -> Dictionary:
	var knight_row := int(feature_state["knight_row"])
	if knight_row < 0:
		return {}

	var mode := "bonus" if is_bonus else "base"
	var pool: Array = _config["multipliers"][mode]
	var multiplier_cells: Dictionary = {}

	for key in fire_cells.keys():
		var parts := str(key).split(",")
		if parts.size() != 2:
			continue
		var row := int(parts[1])
		if row == knight_row:
			multiplier_cells[key] = int(_rng.call("pick_from_array", pool))

	return multiplier_cells
