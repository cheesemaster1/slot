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
@onready var _bonus_intro_overlay: ColorRect = %BonusIntroOverlay
@onready var _bonus_intro_title: Label = %BonusIntroTitle
@onready var _bonus_intro_body: Label = %BonusIntroBody
@onready var _bonus_intro_continue: Button = %BonusIntroContinue
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
var _reel_slow_roll_active := false
var _symbol_textures: Dictionary = {}

func _ready() -> void:
	_load_generated_symbol_textures()
	_set_side_character_panels()
	if not _dragon_sprite.resized.is_connected(_on_side_panel_resized):
		_dragon_sprite.resized.connect(_on_side_panel_resized)
	if not _knight_sprite.resized.is_connected(_on_side_panel_resized):
		_knight_sprite.resized.connect(_on_side_panel_resized)
	_build_grid_cells(5, 5)

	_config = _load_config("res://data/game_config.json")
	_engine.call("set_config", _config)
	_engine.call("set_seed", Time.get_unix_time_from_system())

	_spin_button.pressed.connect(_on_spin_pressed)
	_bonus_intro_continue.pressed.connect(_on_bonus_intro_continue_pressed)
	_result_label.text = "Ready. Click SPIN to generate a result."
	_update_bonus_status()
	_on_spin_pressed()


func _set_side_character_panels() -> void:
	if _symbol_textures.has("CHAR_DRAGON"):
		_dragon_sprite.texture = _symbol_textures["CHAR_DRAGON"]
		_dragon_sprite.modulate = Color(1, 1, 1, 1)
	else:
		_dragon_sprite.texture = null
		_dragon_sprite.modulate = Color(0.55, 0.28, 0.78, 1)
		_set_side_label(_dragon_sprite, "DRAGON")

	if _symbol_textures.has("CHAR_KNIGHT"):
		_knight_sprite.texture = _symbol_textures["CHAR_KNIGHT"]
		_knight_sprite.modulate = Color(1, 1, 1, 1)
	else:
		_knight_sprite.texture = null
		_knight_sprite.modulate = Color(0.25, 0.44, 0.86, 1)
		_set_side_label(_knight_sprite, "KNIGHT")

func _set_side_label(host: TextureRect, text: String) -> void:
	for child in host.get_children():
		child.queue_free()
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.layout_mode = 1
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH
	label.position = Vector2.ZERO
	label.size = host.size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 38)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	label.add_theme_constant_override("outline_size", 3)
	host.add_child(label)

func _on_side_panel_resized() -> void:
	for host in [_dragon_sprite, _knight_sprite]:
		if host == null:
			continue
		for child in host.get_children():
			if child is Label:
				(child as Label).size = host.size
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

			var icon := TextureRect.new()
			icon.name = "Icon"
			icon.layout_mode = 1
			icon.anchors_preset = 8
			icon.anchor_left = 0.5
			icon.anchor_top = 0.5
			icon.anchor_right = 0.5
			icon.anchor_bottom = 0.5
			icon.offset_left = -38
			icon.offset_top = -38
			icon.offset_right = 38
			icon.offset_bottom = 38
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.visible = false
			cell.add_child(icon)

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
		await _animate_scatter_trigger(result)
		await _show_bonus_intro(10)
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
	_reel_slow_roll_active = false
	var revealed_scatter_count := 0
	for reel in range(reels):
		var reel_duration := 0.4
		if _reel_slow_roll_active:
			reel_duration = 1.0
		await _spin_single_reel(reel, rows, reel_duration, _reel_slow_roll_active)
		for row in range(rows):
			_set_cell_visual(reel, row, str(pre_fire_grid[reel][row]), false, 0)
			if reel < 4 and str(pre_fire_grid[reel][row]) == "SCATTER":
				revealed_scatter_count += 1

		if not is_bonus and not _reel_slow_roll_active and reel < 4 and revealed_scatter_count >= 2:
			_reel_slow_roll_active = true
			await _show_mid_spin_popup("SCATTER TEASE")

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
		var added_spins := _bonus_retrigger_spins(int(result.get("scatter_count", 0)))
		if added_spins > 0:
			_bonus_spins_left += added_spins
			_update_bonus_status()
			await _show_mid_spin_popup("+%s FREE SPINS" % added_spins)
			await get_tree().create_timer(1.0).timeout
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

func _show_bonus_intro(start_spins: int) -> void:
	_bonus_intro_title.text = "DRAGON TALES"
	_bonus_intro_body.text = "%s Free Spins\n2 Scatters = +2 Spins\n3+ Scatters = +4 Spins" % start_spins
	_bonus_intro_overlay.visible = true
	_bonus_intro_continue.disabled = false
	await _bonus_intro_continue.pressed
	_bonus_intro_overlay.visible = false

func _on_bonus_intro_continue_pressed() -> void:
	_bonus_intro_continue.disabled = true

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

func _spin_single_reel(reel: int, rows: int, duration: float, slow_roll: bool) -> void:
	var elapsed := 0.0
	var tick := 0.12 if slow_roll else 0.06
	while elapsed < duration:
		for row in range(rows):
			var symbol := _symbol_ids[_rng.randi_range(0, _symbol_ids.size() - 1)]
			_set_cell_visual(reel, row, symbol, false, 0)
		await get_tree().create_timer(tick).timeout
		elapsed += tick

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
	var icon: TextureRect = cell.get_node("Icon")
	var mul: Label = cell.get_node("Mul")

	var base: Color = _symbol_colors.get(symbol, Color("1f3b73"))
	if multiplier > 0:
		base = base.lightened(0.35)
	elif is_fire:
		base = base.lightened(0.18)
	bg.color = base
	if _symbol_textures.has(symbol):
		icon.texture = _symbol_textures[symbol]
		icon.visible = true
		txt.text = symbol
		txt.add_theme_font_size_override("font_size", 13)
		txt.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	else:
		icon.texture = null
		icon.visible = false
		txt.text = symbol
		txt.add_theme_font_size_override("font_size", 30)
		txt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mul.text = "x%s" % multiplier if multiplier > 0 else ""

func _load_generated_symbol_textures() -> void:
	var asset_aliases := _asset_aliases()
	var symbol_ids: Array[String] = ["10", "J", "Q", "K", "A", "SWORD", "SHIELD", "HELMET", "DRAGON_EYE", "WILD", "SCATTER", "DRAGON"]
	for symbol in symbol_ids:
		var tex := _load_texture_from_roots_with_variants(
			["res://assets/generated/symbols", "res://assets/symbols"],
			_build_asset_name_variants(symbol, asset_aliases.get(symbol, [])),
			["png", "webp", "jpg", "jpeg", "svg"]
		)
		if tex != null:
			_symbol_textures[symbol] = tex

	var dragon_tex := _load_texture_from_roots_with_variants(
		["res://assets/generated/characters", "res://assets/characters"],
		_build_asset_name_variants("dragon", asset_aliases.get("CHAR_DRAGON", [])),
		["png", "webp", "jpg", "jpeg", "svg"]
	)
	if dragon_tex != null:
		_symbol_textures["CHAR_DRAGON"] = dragon_tex
	var knight_tex := _load_texture_from_roots_with_variants(
		["res://assets/generated/characters", "res://assets/characters"],
		_build_asset_name_variants("knight", asset_aliases.get("CHAR_KNIGHT", [])),
		["png", "webp", "jpg", "jpeg", "svg"]
	)
	if knight_tex != null:
		_symbol_textures["CHAR_KNIGHT"] = knight_tex

func _asset_aliases() -> Dictionary:
	return {
		"10": ["10-stylizedsymbo", "10-stylizedsymbol"],
		"J": ["J-stylizedsymbol"],
		"Q": ["Q-stylizedsymbol"],
		"K": ["K-stylizedsymbol"],
		"A": ["A-stylizedSymbol", "A-stylizedsymbol"],
		"SWORD": ["Sword-stylized Symbol", "Sword-stylizedsymbol"],
		"SHIELD": ["Shield-stylilzedsymbol", "Shield-stylizedsymbol"],
		"HELMET": ["Helmet-stylizedsymbol"],
		"DRAGON_EYE": ["Dragoneye-stylizedsymbol", "DragonEye-stylizedsymbol"],
		"WILD": ["WILD-stylizedsymbol"],
		"SCATTER": ["Scatter-stylizedsymbol"],
		"DRAGON": ["Dragonfire-sylizedsymbol", "Dragonfire-stylizedsymbol"],
		"CHAR_DRAGON": ["Dragon side panel"],
		"CHAR_KNIGHT": ["knight side panel", "Knight side panel"]
	}

func _build_asset_name_variants(asset_id: String, extra_aliases: Array = []) -> Array[String]:
	var variants: Array[String] = []
	for raw_name in [asset_id] + extra_aliases:
		var base := str(raw_name).strip_edges()
		var normalized := base.to_lower()
		var underscored := normalized.replace("-", "_").replace(" ", "_")
		var dashed := underscored.replace("_", "-")
		var spaced := underscored.replace("_", " ")
		for variant in [base, base.to_lower(), base.to_upper(), normalized, underscored, dashed, spaced]:
			if not variants.has(variant):
				variants.append(variant)
	return variants

func _load_texture_from_roots_with_variants(base_dirs: Array[String], name_variants: Array[String], extensions: Array[String]) -> Texture2D:
	for base_dir in base_dirs:
		for name_variant in name_variants:
			for ext in extensions:
				var path := "%s/%s.%s" % [base_dir, name_variant, ext]
				var tex := _load_texture_from_file(path)
				if tex != null:
					return tex
	return null

func _load_texture_from_file(res_path: String) -> Texture2D:
	if ResourceLoader.exists(res_path):
		var loaded := load(res_path)
		if loaded is Texture2D:
			return loaded
	var abs_path := ProjectSettings.globalize_path(res_path)
	if not FileAccess.file_exists(abs_path):
		return null
	var image := Image.load_from_file(abs_path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

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

func _animate_scatter_trigger(result: Dictionary) -> void:
	var pre_fire_grid: Array = result.get("pre_fire_grid", [])
	if pre_fire_grid.is_empty():
		return
	var trigger_count := int(_config.get("bonus", {}).get("scatter_trigger", 3))
	var scatter_cells: Array[Vector2i] = []
	for reel in range(pre_fire_grid.size()):
		var column: Array = pre_fire_grid[reel]
		for row in range(column.size()):
			if str(column[row]) == "SCATTER":
				scatter_cells.append(Vector2i(reel, row))
	if scatter_cells.size() < trigger_count:
		return

	for _pulse in range(3):
		for pos in scatter_cells:
			_set_cell_visual(pos.x, pos.y, "SCATTER", true, 0)
		await get_tree().create_timer(0.14).timeout
		for pos in scatter_cells:
			_set_cell_visual(pos.x, pos.y, "SCATTER", false, 0)
		await get_tree().create_timer(0.12).timeout

func _bonus_retrigger_spins(scatter_count: int) -> int:
	if scatter_count >= 3:
		return 4
	if scatter_count >= 2:
		return 2
	return 0

func _show_mid_spin_popup(message: String) -> void:
	_win_popup.text = message
	_win_popup.visible = true
	_win_popup.modulate = Color(1, 0.95, 0.55, 1)
	_win_popup.position = Vector2((_grid_area.size.x * 0.5) - 150, (_grid_area.size.y * 0.5) - 24)
	await get_tree().create_timer(0.4).timeout
	_win_popup.visible = false

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
