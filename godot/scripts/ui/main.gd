extends Control

const SpinEngineScript := preload("res://scripts/spin_engine.gd")

@onready var _bet_input: SpinBox = %BetInput
@onready var _bonus_toggle: CheckButton = %BonusToggle
@onready var _spin_button: Button = %SpinButton
@onready var _grid: GridContainer = %Grid
@onready var _dragon_sprite: TextureRect = %DragonSprite
@onready var _knight_sprite: TextureRect = %KnightSprite
@onready var _result_label: RichTextLabel = %ResultLabel

var _engine: RefCounted = SpinEngineScript.new()
var _symbol_textures: Dictionary = {}
var _cells: Array[TextureRect] = []

func _ready() -> void:
	_load_symbol_textures()
	_dragon_sprite.texture = load("res://assets/characters/dragon.svg")
	_knight_sprite.texture = load("res://assets/characters/knight.svg")
	_build_grid_cells(5, 5)

	var config: Dictionary = _load_config("res://data/game_config.json")
	_engine.call("set_config", config)
	_engine.call("set_seed", Time.get_unix_time_from_system())

	_spin_button.pressed.connect(_on_spin_pressed)
	_result_label.text = "Ready. Click SPIN to generate a result."
	_on_spin_pressed()

func _load_symbol_textures() -> void:
	var symbols := ["10", "J", "Q", "K", "A", "SWORD", "SHIELD", "HELMET", "DRAGON_EYE", "WILD", "SCATTER"]
	for symbol in symbols:
		_symbol_textures[symbol] = load("res://assets/symbols/%s.svg" % symbol)

func _build_grid_cells(reels: int, rows: int) -> void:
	for c in _cells:
		c.queue_free()
	_cells.clear()

	for _i in range(reels * rows):
		var tr := TextureRect.new()
		tr.custom_minimum_size = Vector2(120, 100)
		tr.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_grid.add_child(tr)
		_cells.append(tr)

func _on_spin_pressed() -> void:
	var result: Dictionary = _engine.call("spin", int(_bet_input.value), _bonus_toggle.button_pressed)
	_render_grid(result.get("grid", []), result.get("fire_cells", {}), result.get("multiplier_cells", {}))
	_result_label.text = _format_result(result)

func _render_grid(grid: Array, fire_cells: Dictionary, multiplier_cells: Dictionary) -> void:
	if grid.is_empty():
		return

	var reels: int = int(grid.size())
	var rows: int = int(grid[0].size())
	for row in range(rows):
		for reel in range(reels):
			var index := row * reels + reel
			if index >= _cells.size():
				continue
			var symbol := str(grid[reel][row])
			var cell := _cells[index]
			cell.texture = _symbol_textures.get(symbol, null)

			var key := "%s,%s" % [reel, row]
			if multiplier_cells.has(key):
				cell.modulate = Color(1.0, 1.0, 0.3, 1.0)
			elif fire_cells.has(key):
				cell.modulate = Color(1.0, 0.65, 0.65, 1.0)
			else:
				cell.modulate = Color(1, 1, 1, 1)

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

	return "\n".join(lines)
