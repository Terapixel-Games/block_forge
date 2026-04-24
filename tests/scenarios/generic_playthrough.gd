extends "res://addons/arcade_core/testing/MovieScenario.gd"

var _ctx: Dictionary = {}
var _actions_total := 0
var _frames_observed := 0
var _runs_started := 0
var _score_final := 0
var _started_game := false
var _button_pressed_once := false
var _last_action_frame := -100000
var _action_interval := 12


func setup(context: Dictionary) -> void:
	_ctx = context.duplicate(true)
	var persona: Dictionary = actor_persona()
	_action_interval = maxi(1, int(persona.get("gameplay_action_interval_frames", persona.get("action_interval_frames", 12))))


func step(frame: int, delta: float) -> void:
	_frames_observed = frame
	var scene := _current_scene()
	if scene == null:
		return
	_try_start_game(scene)
	var game_node := _active_game_node(scene)
	if game_node != null:
		_runs_started = maxi(_runs_started, 1)
		if game_node.has_method("run_headless_steps"):
			game_node.call("run_headless_steps", 2, delta)
			_actions_total += 1
		if game_node.has_method("get_score"):
			_score_final = maxi(_score_final, int(game_node.call("get_score")))
	if not _button_pressed_once and frame - _last_action_frame >= _action_interval:
		if _press_first_available_button(scene):
			_button_pressed_once = true
			_last_action_frame = frame
			_actions_total += 1


func collect_metrics() -> Dictionary:
	return {
		"actions_total": _actions_total,
		"frames_observed": _frames_observed,
		"runs_started": _runs_started,
		"runs_finished": 0,
		"score_final": _score_final,
	}


func get_invariants() -> Array[Dictionary]:
	return [
		{"id": "scene_alive", "metric": "frames_observed", "op": ">=", "value": 60},
		{"id": "run_observed", "metric": "runs_started", "op": ">=", "value": 1},
	]


func get_checkpoints() -> Array[Dictionary]:
	return [
		{"id": "scene_observed", "metric": "frames_observed", "op": ">=", "value": 30},
	]


func _try_start_game(scene: Node) -> void:
	if _started_game:
		return
	if scene.has_method("start_game"):
		scene.call("start_game")
		_started_game = true
		_actions_total += 1


func _active_game_node(scene: Node) -> Node:
	if scene == null:
		return null
	var current_game: Variant = scene.get("current_game") if _has_script_property(scene, "current_game") else null
	if current_game is Node and is_instance_valid(current_game):
		return current_game
	return scene


func _press_first_available_button(root: Node) -> bool:
	var button := _find_first_button(root)
	if button == null:
		return false
	button.emit_signal("pressed")
	return true


func _find_first_button(root: Node) -> Button:
	if root is Button:
		var button := root as Button
		if button.visible and not button.disabled:
			return button
	for child in root.get_children():
		var result := _find_first_button(child)
		if result != null:
			return result
	return null


func _has_script_property(object: Object, property_name: String) -> bool:
	for info in object.get_property_list():
		if str(info.get("name", "")) == property_name:
			return true
	return false


func _current_scene() -> Node:
	var tree: SceneTree = _ctx.get("scene_tree")
	if tree == null:
		return null
	return tree.current_scene
