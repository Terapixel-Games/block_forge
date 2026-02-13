extends Node

const MENU_SCENE := "res://src/scenes/Menu.tscn"
const GAME_SCENE := "res://src/scenes/Game.tscn"
const RESULTS_SCENE := "res://src/scenes/Results.tscn"

const BlockForgeRules := preload("res://src/games/block_forge/BlockForgeRules.gd")

var last_score: int = 0
var _last_run_state: Dictionary = {}
var _pending_game_state: Dictionary = {}

func goto_menu() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)

func start_block_forge() -> void:
	_pending_game_state.clear()
	_last_run_state.clear()
	get_tree().change_scene_to_file(GAME_SCENE)

func end_block_forge(score: int) -> void:
	last_score = score
	SaveStore.set_high_score(score)
	AdManager.on_game_finished()
	goto_results()

func goto_results() -> void:
	get_tree().change_scene_to_file(RESULTS_SCENE)

func cache_block_forge_state(state: Dictionary) -> void:
	_last_run_state = state.duplicate(true)

func consume_pending_block_forge_state() -> Dictionary:
	var snapshot := _pending_game_state.duplicate(true)
	_pending_game_state.clear()
	return snapshot

func can_continue_current_run() -> bool:
	if _last_run_state.is_empty():
		return false
	return not bool(_last_run_state.get("revive_used", false))

func continue_block_forge_after_reward() -> bool:
	if not can_continue_current_run():
		return false
	var resumed_state: Dictionary = _last_run_state.duplicate(true)
	var revive_result: Dictionary = BlockForgeRules.apply_revive(resumed_state.get("board", []), 10)
	resumed_state["board"] = revive_result.get("board", resumed_state.get("board", []))
	resumed_state["revive_used"] = true
	_last_run_state = resumed_state.duplicate(true)
	_pending_game_state = resumed_state.duplicate(true)
	get_tree().change_scene_to_file(GAME_SCENE)
	return true
