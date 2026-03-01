extends Control

const SpinEngineScript := preload("res://scripts/spin_engine.gd")

@onready var _bet_input: SpinBox = %BetInput
@onready var _bonus_toggle: CheckButton = %BonusToggle
@onready var _spin_button: Button = %SpinButton
@onready var _result_label: RichTextLabel = %ResultLabel

var _engine: RefCounted = SpinEngineScript.new()

func _ready() -> void:
	var config: Dictionary = _load_config("res://data/game_config.json")
	_engine.call("set_config", config)
	_engine.call("set_seed", Time.get_unix_time_from_system())

	_spin_button.pressed.connect(_on_spin_pressed)
	_result_label.text = "Ready. Click SPIN to generate a result."

func _on_spin_pressed() -> void:
	var result: Dictionary = _engine.call("spin", int(_bet_input.value), _bonus_toggle.button_pressed)
	_result_label.text = _format_result(result)

func _load_config(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Unable to load config: %s" % path)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Config JSON is not a dictionary")
		return {}

	return parsed as Dictionary

func _format_result(result: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("[b]Spin Result[/b]")
	lines.append("Total Win: %s" % result.get("total_win", 0))
	lines.append("Scatters: %s | Bonus Trigger: %s" % [result.get("scatter_count", 0), result.get("bonus_trigger", false)])
	lines.append("Dragon Reel: %s | Dragon Start Row: %s | Knight Row: %s" % [
		result.get("dragon_reel", -1),
		result.get("dragon_start_row", -1),
		result.get("knight_row", -1)
	])
	lines.append("Fire Cells: %s" % [result.get("fire_cells", {})])
	lines.append("Multiplier Cells: %s" % [result.get("multiplier_cells", {})])

	lines.append("\n[b]Grid (rows top->bottom)[/b]")
	var grid: Array = result.get("grid", [])
	if grid.is_empty():
		lines.append("<empty>")
	else:
		var rows: int = int(grid[0].size())
		for row in range(rows):
			var row_symbols: Array[String] = []
			for col in range(grid.size()):
				row_symbols.append(str(grid[col][row]))
			lines.append("%s" % " | ".join(row_symbols))

	var wins: Array = result.get("wins", [])
	lines.append("\n[b]Line Wins[/b]")
	if wins.is_empty():
		lines.append("None")
	else:
		for win in wins:
			lines.append("Line %s: %s x%s => %s" % [win["line_index"], win["symbol"], win["multiplier"], win["amount"]])

	return "\n".join(lines)
