class_name RngService
extends RefCounted

var _rng := RandomNumberGenerator.new()

func seed_rng(seed_value: int) -> void:
	_rng.seed = seed_value

func randf() -> float:
	return _rng.randf()

func randi_range(min_value: int, max_value: int) -> int:
	return _rng.randi_range(min_value, max_value)

func pick_weighted(weight_map: Dictionary) -> String:
	var total_weight := 0
	for key in weight_map.keys():
		total_weight += int(weight_map[key])

	if total_weight <= 0:
		return ""

	var roll := randi_range(1, total_weight)
	var cumulative := 0

	for key in weight_map.keys():
		cumulative += int(weight_map[key])
		if roll <= cumulative:
			return str(key)

	return str(weight_map.keys()[0])

func pick_from_array(values: Array) -> Variant:
	if values.is_empty():
		return null
	return values[randi_range(0, values.size() - 1)]
