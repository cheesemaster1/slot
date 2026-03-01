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
	var pre_fire_grid: Array = _build_grid()
	var scatter_count: int = int(_math.call("count_symbol", pre_fire_grid, "SCATTER"))
	var bonus_trigger: bool = scatter_count >= int(_config["bonus"]["scatter_trigger"])

	var grid: Array = _clone_grid(pre_fire_grid)
	var dragon_resolution: Dictionary = _apply_dragon_fire_from_symbols(grid)
	var feature_state: Dictionary = _resolve_knight_feature(is_bonus)
	var multiplier_cells: Dictionary = _resolve_multipliers(dragon_resolution["fire_cells"], feature_state, is_bonus)
	var pay_eval: Dictionary = _math.call("evaluate_paylines", grid, _config["paylines"], bet, multiplier_cells)

	return {
		"pre_fire_grid": pre_fire_grid,
		"grid": grid,
		"dragon_triggers": dragon_resolution["dragon_triggers"],
		"dragon_fire_steps": dragon_resolution["fire_steps"],
		"knight_row": feature_state["knight_row"],
		"fire_cells": dragon_resolution["fire_cells"],
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

func _clone_grid(source: Array) -> Array:
	var copy: Array = []
	for col in source:
		copy.append((col as Array).duplicate())
	return copy

func _resolve_knight_feature(is_bonus: bool) -> Dictionary:
	var mode := "bonus" if is_bonus else "base"
	var chance: Dictionary = _config["feature_chance"][mode]
	var knight: bool = float(_rng.call("randf")) < float(chance["knight"])
	var knight_row := -1
	if knight:
		knight_row = int(_rng.call("randi_range", 0, int(_config["grid"]["rows"]) - 1))
	return {"knight_row": knight_row}

func _apply_dragon_fire_from_symbols(grid: Array) -> Dictionary:
	var reels := int(_config["grid"]["reels"])
	var rows := int(_config["grid"]["rows"])
	var dragon_triggers: Array = []
	var fire_steps: Array = []
	var fire_cells: Dictionary = {}

	for reel in range(reels):
		for row in range(rows):
			if str(grid[reel][row]) != "DRAGON":
				continue

			dragon_triggers.append({"reel": reel, "row": row})
			var steps_for_dragon: Array = []
			for y in range(row, rows):
				grid[reel][y] = "WILD"
				var key := "%s,%s" % [reel, y]
				fire_cells[key] = true
				steps_for_dragon.append({"reel": reel, "row": y})
			fire_steps.append(steps_for_dragon)

	return {
		"dragon_triggers": dragon_triggers,
		"fire_steps": fire_steps,
		"fire_cells": fire_cells
	}

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
