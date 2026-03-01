extends Control

const SpinEngineScript := preload("res://scripts/spin_engine.gd")

@onready var _bet_input: SpinBox = %BetInput
@onready var _bonus_toggle: CheckButton = %BonusToggle
@onready var _spin_button: Button = %SpinButton
@onready var _bonus_status: Label = %BonusStatus
@onready var _grid_area: Control = %GridArea
@onready var _grid: GridContainer = %Grid
@onready var _payline_line: Line2D = %PaylineLine
@onready var _knight_slash_line: Line2D = %KnightSlashLine
@onready var _win_popup: Label = %WinPopup
@onready var _bonus_splash: Label = %BonusSplash
@onready var _dragon_sprite: TextureRect = %DragonSprite
@onready var _knight_sprite: TextureRect = %KnightSprite
@onready var _result_label: RichTextLabel = %ResultLabel

var _engine: RefCounted = SpinEngineScript.new()
var _cell_map: Dictionary = {}
var _config: Dictionary = {}
var _symbol_ids: Array[String] = ["10", "J", "Q", "K", "A", "SWORD", "SHIELD", "HELMET", "DRAGON_EYE", "WILD", "SCATTER", "DRAGON"]
var _symbol_colors := {
	"10": Color("1f3b73"), "J": Color("1f3b73"), "Q": Color("1f3b73"), "K": Color("1f3b73"), "A": Color("1f3b73"),
	"SWORD": Color("6c757d"), "SHIELD": Color("2b8a3e"), "HELMET": Color("7950f2"), "DRAGON_EYE": Color("c92a2a"),
	"WILD": Color("e67700"), "SCATTER": Color("c2255c"), "DRAGON": Color("8a2be2")
}
var _rng := RandomNumberGenerator.new()
var _is_spinning := false
var _in_bonus := false
var _bonus_spins_left := 0
var _bonus_total_win := 0.0

func _ready() -> void:
	_dragon_sprite.texture = load("res://assets/characters/dragon.svg")
	_knight_sprite.texture = load("res://assets/characters/knight.svg")
	_build_grid_cells(5, 5)

	_config = _load_config("res://data/game_config.json")
	_engine.call("set_config", _config)
	_engine.call("set_seed", Time.get_unix_time_from_system())

	_spin_button.pressed.connect(_on_spin_pressed)
	_result_label.text = "Ready. Click SPIN to generate a result."
	_update_bonus_status()
	_on_spin_pressed()

func _build_grid_cells(reels: int, rows: int) -> void:
	for child in _grid.get_children():
		child.queue_free()
	_cell_map.clear()

	for row in range(rows):
		for reel in range(reels):
			var cell := Control.new()
			cell.custom_minimum_size = Vector2(120, 100)

			var bg := ColorRect.new()
			bg.name = "Bg"
			bg.layout_mode = 1
			bg.anchors_preset = 15
			bg.anchor_right = 1.0
			bg.anchor_bottom = 1.0
			bg.grow_horizontal = 2
			bg.grow_vertical = 2
			cell.add_child(bg)

			var txt := Label.new()
			txt.name = "Txt"
			txt.layout_mode = 1
			txt.anchors_preset = 15
			txt.anchor_right = 1.0
			txt.anchor_bottom = 1.0
			txt.grow_horizontal = 2
			txt.grow_vertical = 2
			txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			txt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			txt.add_theme_font_size_override("font_size", 30)
			txt.add_theme_color_override("font_color", Color.WHITE)
			cell.add_child(txt)

			var mul := Label.new()
			mul.name = "Mul"
			mul.layout_mode = 1
			mul.anchors_preset = 5
			mul.anchor_left = 1.0
			mul.anchor_right = 1.0
			mul.offset_left = -64
			mul.offset_right = -8
			mul.offset_top = 4
			mul.offset_bottom = 30
			mul.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			mul.add_theme_font_size_override("font_size", 18)
			mul.add_theme_color_override("font_color", Color(1, 1, 0.4))
			mul.text = ""
			cell.add_child(mul)

			_grid.add_child(cell)
			_cell_map[_cell_key(reel, row)] = cell

func _on_spin_pressed() -> void:
	if _is_spinning:
		return
	_is_spinning = true
	_spin_button.disabled = true

	var result := await _play_single_spin(_bonus_toggle.button_pressed)
	if not _in_bonus and bool(result.get("bonus_trigger", false)):
		await _run_bonus_spins(10)

	_spin_button.disabled = false
	_is_spinning = false

func _play_single_spin(is_bonus: bool) -> Dictionary:
	_payline_line.visible = false
	_knight_slash_line.visible = false
	_win_popup.visible = false

	var result: Dictionary = _engine.call("spin", int(_bet_input.value), is_bonus)
	var pre_fire_grid: Array = result.get("pre_fire_grid", [])
	var final_grid: Array = result.get("grid", [])
	if pre_fire_grid.is_empty() or final_grid.is_empty():
		return result

	var reels: int = int(pre_fire_grid.size())
	var rows: int = int(pre_fire_grid[0].size())
	for reel in range(reels):
		await _spin_single_reel(reel, rows, 0.4)
		for row in range(rows):
			_set_cell_visual(reel, row, str(pre_fire_grid[reel][row]), false, 0)

	await _animate_dragon_fire(result)
	await _animate_knight_slash(result)
	_render_grid(final_grid, result.get("fire_cells", {}), result.get("multiplier_cells", {}))
	_result_label.text = _format_result(result)
	await _animate_wins(result)
	return result

func _run_bonus_spins(count: int) -> void:
	_in_bonus = true
	_bonus_spins_left = count
	_bonus_total_win = 0.0
	_update_bonus_status()

	while _bonus_spins_left > 0:
		var result := await _play_single_spin(true)
		_bonus_total_win += float(result.get("total_win", 0.0))
		_bonus_spins_left -= 1
		_update_bonus_status()
		await get_tree().create_timer(0.15).timeout

	await _show_bonus_splash()
	_in_bonus = false
	_update_bonus_status()

func _show_bonus_splash() -> void:
	_bonus_splash.text = "BONUS COMPLETE\nWIN %.2f" % _bonus_total_win
	_bonus_splash.visible = true
	_bonus_splash.modulate = Color(1, 1, 1, 1)
	await get_tree().create_timer(1.4).timeout
	_bonus_splash.visible = false

func _update_bonus_status() -> void:
	if _in_bonus:
		_bonus_status.text = "BONUS SPINS LEFT: %s" % _bonus_spins_left
	else:
		_bonus_status.text = ""

func _animate_dragon_fire(result: Dictionary) -> void:
	var fire_steps_all: Array = result.get("dragon_fire_steps", [])
	for dragon_steps in fire_steps_all:
		if typeof(dragon_steps) != TYPE_ARRAY:
			continue
		for step in dragon_steps:
			if typeof(step) != TYPE_DICTIONARY:
				continue
			var reel := int(step.get("reel", -1))
			var row := int(step.get("row", -1))
			if reel < 0 or row < 0:
				continue
			_set_cell_visual(reel, row, "WILD", true, 0)
			await get_tree().create_timer(0.08).timeout
		await get_tree().create_timer(0.10).timeout

func _animate_knight_slash(result: Dictionary) -> void:
	if not bool(result.get("knight_triggered", false)):
		return
	var row := int(result.get("knight_row", -1))
	if row < 0:
		return

	var y := _cell_center_local(0, row).y
	_knight_slash_line.default_color = Color(0.95, 0.2, 0.2, 1)
	_knight_slash_line.clear_points()
	_knight_slash_line.visible = true
	_knight_slash_line.add_point(Vector2(_grid_area.size.x, y))
	_knight_slash_line.add_point(Vector2(_grid_area.size.x, y))
	var tween := create_tween()
	tween.tween_method(func(v): _knight_slash_line.set_point_position(1, Vector2(v, y)), _grid_area.size.x, 0.0, 0.20)
	await tween.finished

	var hit_cols: Array = result.get("knight_hit_columns", [])
	var miss := bool(result.get("knight_miss", false))
	if miss:
		_win_popup.text = "MISS"
		_win_popup.visible = true
		_win_popup.modulate = Color(1, 0.6, 0.6, 1)
		_win_popup.position = Vector2(_grid_area.size.x - 140, y - 28)
		await get_tree().create_timer(0.45).timeout
		_win_popup.visible = false
	else:
		for col in hit_cols:
			var center := _cell_center_local(int(col), row)
			_win_popup.text = "xCOLUMN"
			_win_popup.visible = true
			_win_popup.modulate = Color(0.9, 1, 0.4, 1)
			_win_popup.position = center - Vector2(72, 28)
			await get_tree().create_timer(0.18).timeout
		_win_popup.visible = false

	_knight_slash_line.visible = false

func _spin_single_reel(reel: int, rows: int, duration: float) -> void:
	var elapsed := 0.0
	while elapsed < duration:
		for row in range(rows):
			var symbol := _symbol_ids[_rng.randi_range(0, _symbol_ids.size() - 1)]
			_set_cell_visual(reel, row, symbol, false, 0)
		await get_tree().create_timer(0.06).timeout
		elapsed += 0.06

func _render_grid(grid: Array, fire_cells: Dictionary, multiplier_cells: Dictionary) -> void:
	var reels := int(grid.size())
	var rows := int(grid[0].size())
	for row in range(rows):
		for reel in range(reels):
			var key := _cell_key(reel, row)
			_set_cell_visual(
				reel,
				row,
				str(grid[reel][row]),
				fire_cells.has(key),
				int(multiplier_cells.get(key, 0))
			)

func _set_cell_visual(reel: int, row: int, symbol: String, is_fire: bool, multiplier: int) -> void:
	var cell: Control = _cell_map.get(_cell_key(reel, row), null)
	if cell == null:
		return
	var bg: ColorRect = cell.get_node("Bg")
	var txt: Label = cell.get_node("Txt")
	var mul: Label = cell.get_node("Mul")

	var base: Color = _symbol_colors.get(symbol, Color("1f3b73"))
	if multiplier > 0:
		base = base.lightened(0.35)
	elif is_fire:
		base = base.lightened(0.18)
	bg.color = base
	txt.text = symbol
	mul.text = "x%s" % multiplier if multiplier > 0 else ""

func _animate_wins(result: Dictionary) -> void:
	var wins: Array = result.get("wins", [])
	if wins.is_empty():
		return
	var paylines: Array = _config.get("paylines", [])
	for win in wins:
		var idx := int(win.get("line_index", -1))
		if idx < 0 or idx >= paylines.size():
			continue
		await _animate_payline(paylines[idx], float(win.get("amount", 0.0)))

func _animate_payline(line: Array, amount: float) -> void:
	_payline_line.clear_points()
	_payline_line.visible = true
	for point in line:
		if typeof(point) != TYPE_ARRAY or (point as Array).size() < 2:
			continue
		var p: Array = point
		_payline_line.add_point(_cell_center_local(int(p[0]), int(p[1])))
		await get_tree().create_timer(0.06).timeout
	var popup_center := _cell_center_local(int(line[2][0]), int(line[2][1]))
	_win_popup.text = "+%.2f" % amount
	_win_popup.visible = true
	_win_popup.modulate = Color(1, 1, 1, 1)
	_win_popup.position = popup_center - Vector2(80, 30)
	var tween := create_tween()
	tween.tween_property(_win_popup, "position:y", _win_popup.position.y - 45, 0.45)
	tween.parallel().tween_property(_win_popup, "modulate:a", 0.0, 0.45)
	await tween.finished
	_win_popup.visible = false
	_payline_line.visible = false

func _cell_center_local(reel: int, row: int) -> Vector2:
	var reels := int(_config.get("grid", {}).get("reels", 5))
	var rows := int(_config.get("grid", {}).get("rows", 5))
	var area_size := _grid_area.size
	if area_size.x <= 0.0 or area_size.y <= 0.0:
		area_size = Vector2(680, 520)
	return Vector2((float(reel) + 0.5) * (area_size.x / float(reels)), (float(row) + 0.5) * (area_size.y / float(rows)))

func _cell_key(reel: int, row: int) -> String:
	return "%s,%s" % [reel, row]

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
	lines.append("Total Win: %.2f" % float(result.get("total_win", 0.0)))
	lines.append("Line Wins: %s" % (result.get("wins", []) as Array).size())
	lines.append("Scatters: %s | Bonus Trigger: %s" % [result.get("scatter_count", 0), result.get("bonus_trigger", false)])
	lines.append("Dragon Triggers: %s | Knight: %s row=%s" % [
		(result.get("dragon_triggers", []) as Array).size(),
		result.get("knight_triggered", false),
		result.get("knight_row", -1)
	])
	lines.append("Knight Hit Cols: %s | Miss: %s" % [result.get("knight_hit_columns", []), result.get("knight_miss", false)])
	lines.append("Multiplier Cells: %s" % [result.get("multiplier_cells", {})])
	return "\n".join(lines)
