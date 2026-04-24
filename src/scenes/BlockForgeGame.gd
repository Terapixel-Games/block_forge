extends Control

const BOARD_SIZE: int = 8
const TRAY_SIZE: int = 3

const BlockForgeRules := preload("res://src/games/block_forge/BlockForgeRules.gd")
const BlockForgePieces := preload("res://src/games/block_forge/BlockForgePieces.gd")
const BlockForgeDifficulty := preload("res://src/games/block_forge/BlockForgeDifficulty.gd")

const BOARD_EMPTY_COLOR: Color = Color(0.19, 0.25, 0.33, 1.0)
const BOARD_FILLED_COLOR: Color = Color(0.62, 0.9, 0.92, 1.0)
const BOARD_PREVIEW_VALID_COLOR: Color = Color(0.45, 0.8, 0.96, 1.0)
const BOARD_PREVIEW_INVALID_COLOR: Color = Color(0.92, 0.45, 0.45, 1.0)
const BOARD_FLASH_COLOR: Color = Color(1.0, 0.98, 0.75, 0.65)
const TRAY_SELECTED_COLOR: Color = Color(0.85, 1.0, 0.88, 1.0)
const TRAY_IDLE_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)
const TRAY_USED_COLOR: Color = Color(0.68, 0.68, 0.7, 0.75)

@onready var shake_root: Control = $ShakeRoot
@onready var board_grid: GridContainer = $ShakeRoot/UI/Main/BoardPanel/BoardPadding/BoardGrid
@onready var tray_container: HBoxContainer = $ShakeRoot/UI/Main/TrayContainer
@onready var score_label: Label = $ShakeRoot/UI/Main/TopBar/ScoreLabel
@onready var combo_label: Label = $ShakeRoot/UI/Main/TopBar/ComboLabel
@onready var objective_label: Label = $ShakeRoot/UI/Main/ObjectiveLabel
@onready var status_label: Label = $ShakeRoot/UI/Main/StatusLabel
@onready var pause_overlay: Control = $PauseOverlay

var _board: Array = []
var _tray: Array = []
var _score: int = 0
var _combo: int = 0
var _revive_used: bool = false
var _powerups: Dictionary = {}
var _selected_piece_index: int = -1
var _preview_piece_index: int = -1
var _preview_origin: Vector2i = Vector2i(-999, -999)
var _preview_valid: bool = false
var _preview_cells: Array = []
var _board_buttons: Array = []
var _tray_buttons: Array = []
var _input_locked: bool = false
var _base_shake_pos: Vector2 = Vector2.ZERO
var _rng := RandomNumberGenerator.new()
var _turns_without_clear: int = 0
var _active_rival_target: int = 0

func _ready() -> void:
	_rng.randomize()
	_base_shake_pos = shake_root.position
	_build_board_buttons()
	_build_tray_buttons()
	_load_run_state()
	_render_all()
	_set_status("Select a tray piece.")

func _build_board_buttons() -> void:
	for child in board_grid.get_children():
		child.queue_free()
	_board_buttons.clear()
	board_grid.columns = BOARD_SIZE
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			var button := Button.new()
			button.custom_minimum_size = Vector2(62, 62)
			button.focus_mode = Control.FOCUS_NONE
			button.flat = false
			button.text = ""
			button.add_theme_stylebox_override("normal", _cell_style(Color(0.23, 0.31, 0.42, 0.65)))
			button.add_theme_stylebox_override("hover", _cell_style(Color(0.34, 0.47, 0.62, 0.8)))
			button.add_theme_stylebox_override("pressed", _cell_style(Color(0.4, 0.58, 0.76, 0.9)))
			button.add_theme_stylebox_override("disabled", _cell_style(Color(0.18, 0.24, 0.32, 0.6)))
			button.pressed.connect(_on_board_cell_pressed.bind(x, y))
			board_grid.add_child(button)
			_board_buttons.append(button)

func _build_tray_buttons() -> void:
	for child in tray_container.get_children():
		child.queue_free()
	_tray_buttons.clear()
	for i in range(TRAY_SIZE):
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 170)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		button.pressed.connect(_on_tray_piece_pressed.bind(i))
		tray_container.add_child(button)
		_tray_buttons.append(button)

func _load_run_state() -> void:
	var pending_state: Dictionary = RunManager.consume_pending_block_forge_state()
	if pending_state.is_empty():
		_board = BlockForgeRules.create_board(BOARD_SIZE, BOARD_SIZE)
		_tray = _roll_playable_tray()
		_score = 0
		_combo = 0
		_revive_used = false
		_powerups = _shop_powerups_snapshot()
		_turns_without_clear = 0
		_active_rival_target = int(RunManager.get_active_rival_target())
		return
	_board = _sanitize_board(pending_state.get("board", []))
	_tray = _sanitize_tray(pending_state.get("tray", []))
	_score = int(pending_state.get("score", 0))
	_combo = int(pending_state.get("combo", 0))
	_revive_used = bool(pending_state.get("revive_used", false))
	_powerups = _sanitize_powerups(pending_state.get("powerups", _shop_powerups_snapshot()))
	_turns_without_clear = max(0, int(pending_state.get("turns_without_clear", 0)))
	_active_rival_target = int(pending_state.get("rival_target", RunManager.get_active_rival_target()))
	if _tray_is_empty():
		_tray = _roll_playable_tray()

func _sanitize_board(value: Variant) -> Array:
	if not (value is Array):
		return BlockForgeRules.create_board(BOARD_SIZE, BOARD_SIZE)
	var source: Array = value as Array
	if source.size() != BOARD_SIZE:
		return BlockForgeRules.create_board(BOARD_SIZE, BOARD_SIZE)
	var out: Array = []
	for y in range(BOARD_SIZE):
		if not (source[y] is Array):
			return BlockForgeRules.create_board(BOARD_SIZE, BOARD_SIZE)
		var row_src: Array = source[y] as Array
		if row_src.size() != BOARD_SIZE:
			return BlockForgeRules.create_board(BOARD_SIZE, BOARD_SIZE)
		var row: Array = []
		for x in range(BOARD_SIZE):
			row.append(int(row_src[x]))
		out.append(row)
	return out

func _sanitize_tray(value: Variant) -> Array:
	var tray: Array = [{}, {}, {}]
	if not (value is Array):
		return tray
	var source: Array = value as Array
	for i in range(min(TRAY_SIZE, source.size())):
		if source[i] is Dictionary and (source[i] as Dictionary).has("cells"):
			tray[i] = (source[i] as Dictionary).duplicate(true)
	return tray

func _roll_playable_tray() -> Array:
	var fallback: Array = [{}, {}, {}]
	var pressure: int = BlockForgeDifficulty.pressure_level(_board, _turns_without_clear)
	var max_cells: int = BlockForgeDifficulty.max_piece_cells_for_pressure(pressure)
	var force_lifeline: bool = BlockForgeDifficulty.should_force_lifeline(pressure, _turns_without_clear)
	for _attempt in range(32):
		var candidate: Array = []
		var has_lifeline: bool = false
		for _slot in range(TRAY_SIZE):
			var piece: Dictionary = _draw_piece_with_guardrails(max_cells, force_lifeline and _slot == 0)
			has_lifeline = has_lifeline or _piece_cell_count(piece) <= 2
			candidate.append(piece)
		if force_lifeline and not has_lifeline:
			candidate[0] = BlockForgePieces.piece_by_id("single")
		fallback = candidate
		if BlockForgeRules.any_move_possible(_board, candidate):
			return candidate
	return fallback

func _on_tray_piece_pressed(piece_index: int) -> void:
	if _input_locked or pause_overlay.visible:
		return
	if piece_index < 0 or piece_index >= _tray.size():
		return
	var piece: Dictionary = _tray[piece_index] as Dictionary
	if piece.is_empty():
		return
	if _selected_piece_index == piece_index:
		_selected_piece_index = -1
		_clear_preview()
		_set_status("Piece deselected.")
	else:
		_selected_piece_index = piece_index
		_clear_preview()
		_set_status("Tap a board cell to place this piece.")
	_render_all()

func _on_board_cell_pressed(x: int, y: int) -> void:
	if _input_locked or pause_overlay.visible:
		return
	if _selected_piece_index < 0:
		_set_status("Select a tray piece first.")
		return
	var piece: Dictionary = _tray[_selected_piece_index] as Dictionary
	if piece.is_empty():
		return
	var origin := Vector2i(x, y)
	var is_same_target: bool = (_preview_piece_index == _selected_piece_index and _preview_origin == origin)
	var can_place: bool = BlockForgeRules.can_place(_board, piece, origin)
	if is_same_target and _preview_valid and can_place:
		_clear_preview()
		_render_board()
		_commit_move(piece, origin)
		return
	_update_preview(_selected_piece_index, piece, origin, can_place)
	_render_board()
	if not can_place:
		_bump_cell(x, y)
		_set_status("Piece does not fit there.")
		return
	_set_status("Tap again to place.")

func _commit_move(piece: Dictionary, origin: Vector2i) -> void:
	_input_locked = true
	var placed_cells: Array = _piece_cells(piece, origin)
	_board = BlockForgeRules.place(_board, piece, origin)
	_tray[_selected_piece_index] = {}
	_selected_piece_index = -1
	_clear_preview()
	_render_board()
	await _animate_placement(placed_cells)

	var clear_result: Dictionary = BlockForgeRules.clear_lines(_board)
	var cleared_lines: int = int(clear_result.get("count", 0))
	if cleared_lines > 0:
		_turns_without_clear = 0
		_combo += 1
		var clear_cells: Array = _cells_from_clear_result(clear_result)
		await _animate_clear(clear_cells)
		_board = clear_result.get("board", _board)
		if cleared_lines > 1:
			await _shake_screen(cleared_lines)
	else:
		_combo = 0
		_turns_without_clear += 1

	var score_data: Dictionary = BlockForgeRules.score_for_move(placed_cells.size(), cleared_lines, _combo)
	_score += int(score_data.get("total", 0))

	if _tray_is_empty():
		_tray = _roll_playable_tray()
	_render_all()
	_set_status(_score_breakdown_text(score_data))

	if not BlockForgeRules.any_move_possible(_board, _tray):
		_set_status("No legal placement left. Run complete.")
		await get_tree().create_timer(0.18).timeout
		_finish_run()
		return
	_input_locked = false

func _finish_run() -> void:
	var snapshot := {
		"board": _board.duplicate(true),
		"tray": _tray.duplicate(true),
		"score": _score,
		"combo": _combo,
		"revive_used": _revive_used,
		"powerups": _powerups.duplicate(true),
		"turns_without_clear": _turns_without_clear,
		"rival_target": _active_rival_target,
	}
	RunManager.cache_block_forge_state(snapshot)
	RunManager.end_block_forge(_score)

func _shop_powerups_snapshot() -> Dictionary:
	if SaveManager.has_method("get_shop_powerups"):
		return SaveManager.get_shop_powerups()
	return {"revive": 0}

func _sanitize_powerups(value: Variant) -> Dictionary:
	var out: Dictionary = {}
	if not (value is Dictionary):
		return out
	for key_variant in (value as Dictionary).keys():
		var key: String = str(key_variant).strip_edges().to_lower()
		if key.is_empty():
			continue
		out[key] = max(0, int((value as Dictionary)[key_variant]))
	return out

func _piece_cells(piece: Dictionary, origin: Vector2i) -> Array:
	var out: Array = []
	for cell_variant in piece.get("cells", []):
		var cell: Vector2i = _to_vec2i(cell_variant)
		out.append(Vector2i(origin.x + cell.x, origin.y + cell.y))
	return out

func _cells_from_clear_result(clear_result: Dictionary) -> Array:
	var unique: Dictionary = {}
	var rows: Array = clear_result.get("rows", [])
	var cols: Array = clear_result.get("cols", [])
	for row_index_variant in rows:
		var row_index: int = int(row_index_variant)
		for x in range(BOARD_SIZE):
			unique["%s:%s" % [x, row_index]] = Vector2i(x, row_index)
	for col_index_variant in cols:
		var col_index: int = int(col_index_variant)
		for y in range(BOARD_SIZE):
			unique["%s:%s" % [col_index, y]] = Vector2i(col_index, y)
	return unique.values()

func _render_all() -> void:
	_render_board()
	_render_tray()
	score_label.text = "Score: %d" % _score
	combo_label.text = "Combo: %d" % _combo
	_refresh_objective_text()

func _render_board() -> void:
	var preview_lookup: Dictionary = {}
	for preview_cell_variant in _preview_cells:
		var preview_cell: Vector2i = _to_vec2i(preview_cell_variant)
		preview_lookup["%s:%s" % [preview_cell.x, preview_cell.y]] = true
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			var button: Button = _board_button(x, y)
			button.modulate = BOARD_FILLED_COLOR if int(_board[y][x]) != 0 else BOARD_EMPTY_COLOR
			var cell_key: String = "%s:%s" % [x, y]
			if preview_lookup.has(cell_key):
				button.modulate = BOARD_PREVIEW_VALID_COLOR if _preview_valid else BOARD_PREVIEW_INVALID_COLOR
			button.scale = Vector2.ONE

func _render_tray() -> void:
	for i in range(TRAY_SIZE):
		var button: Button = _tray_buttons[i]
		var piece: Dictionary = _tray[i] as Dictionary
		if piece.is_empty():
			button.disabled = true
			button.text = "USED"
			button.modulate = TRAY_USED_COLOR
			continue
		button.disabled = false
		button.text = _piece_preview_text(piece)
		button.modulate = TRAY_SELECTED_COLOR if i == _selected_piece_index else TRAY_IDLE_COLOR

func _piece_preview_text(piece: Dictionary) -> String:
	var bounds: Vector2i = BlockForgePieces.bounds(piece)
	var occupied: Dictionary = {}
	for cell_variant in piece.get("cells", []):
		var cell: Vector2i = _to_vec2i(cell_variant)
		occupied["%s:%s" % [cell.x, cell.y]] = true
	var lines: Array = []
	for y in range(bounds.y):
		var row: String = ""
		for x in range(bounds.x):
			row += "X" if occupied.has("%s:%s" % [x, y]) else "."
		lines.append(row)
	var title: String = str(piece.get("id", "piece")).replace("_", " ").capitalize()
	return "%s\n%s" % [title, "\n".join(lines)]

func _tray_is_empty() -> bool:
	for piece_variant in _tray:
		if piece_variant is Dictionary and not (piece_variant as Dictionary).is_empty():
			return false
	return true

func _score_breakdown_text(score_data: Dictionary) -> String:
	return "Placed +%d | Lines +%d | Combo +%d" % [
		int(score_data.get("placed", 0)),
		int(score_data.get("line_bonus", 0)),
		int(score_data.get("combo_bonus", 0)),
	]

func _refresh_objective_text() -> void:
	var pressure: int = BlockForgeDifficulty.pressure_level(_board, _turns_without_clear)
	var pressure_name: String = str(["Stable", "Rising", "High", "Critical"][clampi(pressure, 0, 3)])
	var target_text: String = "Rival target: %d" % _active_rival_target if _active_rival_target > 0 else "Rival target: build one in results"
	if _active_rival_target > 0 and _score >= _active_rival_target:
		target_text = "Rival target beaten. Push for season best."
	objective_label.text = "Objective: place all tray pieces, clear lines, and keep runs alive.\nFail: run ends when no tray piece fits. %s | Pressure: %s" % [target_text, pressure_name]

func _set_status(message: String) -> void:
	status_label.text = message

func _draw_piece_with_guardrails(max_cells: int, force_lifeline: bool) -> Dictionary:
	var target_limit: int = max(1, max_cells)
	for _attempt in range(28):
		var piece: Dictionary = BlockForgePieces.random_piece(_rng)
		var cells: int = _piece_cell_count(piece)
		if cells <= target_limit:
			if force_lifeline and cells > 2:
				continue
			return piece
	if force_lifeline:
		return BlockForgePieces.piece_by_id("single")
	return BlockForgePieces.random_piece(_rng)

func _piece_cell_count(piece: Dictionary) -> int:
	var cells_variant: Variant = piece.get("cells", [])
	if cells_variant is Array:
		return (cells_variant as Array).size()
	return 0

func _update_preview(piece_index: int, piece: Dictionary, origin: Vector2i, is_valid: bool) -> void:
	_preview_piece_index = piece_index
	_preview_origin = origin
	_preview_valid = is_valid
	_preview_cells = _piece_cells(piece, origin)

func _clear_preview() -> void:
	_preview_piece_index = -1
	_preview_origin = Vector2i(-999, -999)
	_preview_valid = false
	_preview_cells.clear()

func _board_button(x: int, y: int) -> Button:
	return _board_buttons[y * BOARD_SIZE + x] as Button

func _cell_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.93, 0.97, 1.0, 0.28)
	return style

func _to_vec2i(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		var v2: Vector2 = value
		return Vector2i(int(v2.x), int(v2.y))
	if value is Dictionary:
		return Vector2i(int(value.get("x", 0)), int(value.get("y", 0)))
	return Vector2i.ZERO

func _bump_cell(x: int, y: int) -> void:
	var cell: Button = _board_button(x, y)
	var tween: Tween = create_tween()
	tween.tween_property(cell, "scale", Vector2(0.88, 0.88), 0.06)
	tween.tween_property(cell, "scale", Vector2.ONE, 0.1)

func _animate_placement(cells: Array) -> void:
	if cells.is_empty():
		return
	var tween: Tween = create_tween()
	for cell_variant in cells:
		var cell: Vector2i = _to_vec2i(cell_variant)
		var button: Button = _board_button(cell.x, cell.y)
		button.scale = Vector2(0.82, 0.82)
		tween.parallel().tween_property(button, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished

func _animate_clear(cells: Array) -> void:
	if cells.is_empty():
		return
	var tween: Tween = create_tween()
	for cell_variant in cells:
		var cell: Vector2i = _to_vec2i(cell_variant)
		var button: Button = _board_button(cell.x, cell.y)
		tween.parallel().tween_property(button, "modulate", BOARD_FLASH_COLOR, 0.12)
	await tween.finished

func _shake_screen(intensity_lines: int) -> void:
	var intensity: float = min(8.0, 1.8 + float(intensity_lines) * 1.6)
	var tween: Tween = create_tween()
	for _step in range(6):
		var offset := Vector2(
			_rng.randf_range(-intensity, intensity),
			_rng.randf_range(-intensity * 0.5, intensity * 0.5)
		)
		tween.tween_property(shake_root, "position", _base_shake_pos + offset, 0.02)
	tween.tween_property(shake_root, "position", _base_shake_pos, 0.05)
	await tween.finished

func _on_pause_pressed() -> void:
	if _input_locked:
		return
	pause_overlay.visible = true
	_set_status("Paused")

func _on_resume_pressed() -> void:
	pause_overlay.visible = false
	_set_status("Select a tray piece.")

func _on_menu_pressed() -> void:
	pause_overlay.visible = false
	RunManager.goto_menu()
