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
	var pre_fire_grid: Array = _build_grid(is_bonus)
	var scatter_count: int = int(_math.call("count_symbol", pre_fire_grid, "SCATTER"))
	var bonus_trigger: bool = scatter_count >= int(_config["bonus"]["scatter_trigger"])

	var grid: Array = _clone_grid(pre_fire_grid)
	var dragon_resolution: Dictionary = _apply_dragon_fire_from_symbols(grid)
	var knight_state: Dictionary = _resolve_knight_state(is_bonus)
	var multiplier_resolution: Dictionary = _resolve_multipliers(dragon_resolution["fire_cells"], knight_state, is_bonus)
	var pay_eval: Dictionary = _math.call("evaluate_paylines", grid, _config["paylines"], bet, multiplier_resolution["multiplier_cells"])

	return {
		"pre_fire_grid": pre_fire_grid,
		"grid": grid,
		"dragon_triggers": dragon_resolution["dragon_triggers"],
		"dragon_fire_steps": dragon_resolution["fire_steps"],
		"knight_triggered": knight_state["triggered"],
		"knight_row": knight_state["row"],
		"knight_hit_columns": multiplier_resolution["hit_columns"],
		"knight_miss": multiplier_resolution["miss"],
		"fire_cells": dragon_resolution["fire_cells"],
		"multiplier_cells": multiplier_resolution["multiplier_cells"],
		"scatter_count": scatter_count,
		"bonus_trigger": bonus_trigger,
		"total_win": pay_eval["total_win"],
		"wins": pay_eval["wins"]
	}

func _build_grid(is_bonus: bool) -> Array:
	var reels := int(_config["grid"]["reels"])
	var rows := int(_config["grid"]["rows"])
	var mode := "bonus" if is_bonus else "base"
	var spin_weights: Dictionary = _config.get("spin_weights", {})
	var weight_map: Dictionary = spin_weights.get(mode, _config["weights"])

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

func _resolve_knight_state(is_bonus: bool) -> Dictionary:
	var mode := "bonus" if is_bonus else "base"
	var chance: Dictionary = _config["feature_chance"][mode]
	var triggered: bool = float(_rng.call("randf")) < float(chance["knight"])
	var row := -1
	if triggered:
		row = int(_rng.call("randi_range", 0, int(_config["grid"]["rows"]) - 1))
	return {"triggered": triggered, "row": row}

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

func _resolve_multipliers(fire_cells: Dictionary, knight_state: Dictionary, is_bonus: bool) -> Dictionary:
	var triggered := bool(knight_state["triggered"])
	var knight_row := int(knight_state["row"])
	if not triggered or knight_row < 0:
		return {"multiplier_cells": {}, "hit_columns": [], "miss": false}

	var hit_columns: Array = []
	for key in fire_cells.keys():
		var parts := str(key).split(",")
		if parts.size() != 2:
			continue
		var col := int(parts[0])
		var row := int(parts[1])
		if row == knight_row and not hit_columns.has(col):
			hit_columns.append(col)

	if hit_columns.is_empty():
		return {"multiplier_cells": {}, "hit_columns": [], "miss": true}

	var mode := "bonus" if is_bonus else "base"
	var multiplier_weights: Dictionary = _config["multiplier_weights"][mode]
	var multiplier_cells: Dictionary = {}

	for col in hit_columns:
		var value := int(_rng.call("pick_weighted", multiplier_weights))
		for key in fire_cells.keys():
			var parts := str(key).split(",")
			if parts.size() != 2:
				continue
			if int(parts[0]) == int(col):
				multiplier_cells[key] = value

	return {"multiplier_cells": multiplier_cells, "hit_columns": hit_columns, "miss": false}
