extends Node

const MENU_SCENE := "res://src/scenes/Menu.tscn"
const GAME_SCENE := "res://src/scenes/Game.tscn"
const RESULTS_SCENE := "res://src/scenes/Results.tscn"

const BlockForgeRules := preload("res://src/games/block_forge/BlockForgeRules.gd")
const REVIVE_POWERUP_ID := "revive"
const SCORE_KEY := "block_forge_high_score"
const RUN_COUNT_KEY := "block_forge/fun/run_count"
const SESSION_STREAK_KEY := "block_forge/fun/session_streak"
const LAST_DAY_KEY := "block_forge/fun/last_day"
const SEASON_BEST_PREFIX := "block_forge/fun/season_best/"
const RIVAL_TARGET_PREFIX := "block_forge/fun/rival_target/"

var last_score: int = 0
var last_run_meta: Dictionary = {}
var _last_run_state: Dictionary = {}
var _pending_game_state: Dictionary = {}

func goto_menu() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)

func start_block_forge() -> void:
	_pending_game_state.clear()
	_last_run_state.clear()
	_pending_game_state["powerups"] = _shop_powerups_snapshot()
	_pending_game_state["revive_used"] = false
	_pending_game_state["rival_target"] = get_active_rival_target()
	get_tree().change_scene_to_file(GAME_SCENE)

func end_block_forge(score: int) -> void:
	last_score = score
	var best_score: int = int(SaveManager.get_best(SCORE_KEY, 0))
	last_run_meta = _build_run_meta(score, best_score)
	if score > best_score:
		SaveManager.set_best(SCORE_KEY, score)
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
	if get_available_revives_for_continue() > 0:
		return true
	return not bool(_last_run_state.get("revive_used", false))

func get_available_revives_for_continue() -> int:
	if _last_run_state.is_empty():
		return 0
	var powerups: Dictionary = _run_powerups(_last_run_state)
	return max(0, int(powerups.get(REVIVE_POWERUP_ID, 0)))

func continue_block_forge_with_shop_powerup() -> bool:
	if _last_run_state.is_empty():
		return false
	var available_revives: int = get_available_revives_for_continue()
	if available_revives <= 0:
		return false

	var resumed_state: Dictionary = _last_run_state.duplicate(true)
	var revive_result: Dictionary = BlockForgeRules.apply_revive(resumed_state.get("board", []), 10)
	resumed_state["board"] = revive_result.get("board", resumed_state.get("board", []))

	var powerups: Dictionary = _run_powerups(resumed_state)
	powerups[REVIVE_POWERUP_ID] = available_revives - 1
	resumed_state["powerups"] = powerups

	if SaveManager.has_method("consume_shop_powerup"):
		SaveManager.consume_shop_powerup(REVIVE_POWERUP_ID, 1)

	_last_run_state = resumed_state.duplicate(true)
	_pending_game_state = resumed_state.duplicate(true)
	if not _pending_game_state.has("rival_target"):
		_pending_game_state["rival_target"] = get_active_rival_target()
	get_tree().change_scene_to_file(GAME_SCENE)
	return true

func continue_block_forge_after_reward() -> bool:
	if not can_continue_current_run():
		return false
	var resumed_state: Dictionary = _last_run_state.duplicate(true)
	var revive_result: Dictionary = BlockForgeRules.apply_revive(resumed_state.get("board", []), 10)
	resumed_state["board"] = revive_result.get("board", resumed_state.get("board", []))
	resumed_state["revive_used"] = true
	_last_run_state = resumed_state.duplicate(true)
	_pending_game_state = resumed_state.duplicate(true)
	if not _pending_game_state.has("rival_target"):
		_pending_game_state["rival_target"] = get_active_rival_target()
	get_tree().change_scene_to_file(GAME_SCENE)
	return true

func get_last_run_meta() -> Dictionary:
	return last_run_meta.duplicate(true)

func get_active_rival_target() -> int:
	var season: String = _season_key()
	var rival_key: String = "%s%s" % [RIVAL_TARGET_PREFIX, season]
	var current: int = int(SaveManager.get_setting(rival_key, 0))
	if current > 0:
		return current
	var baseline: int = _baseline_rival_target(int(SaveManager.get_best(SCORE_KEY, 0)))
	SaveManager.set_setting(rival_key, baseline)
	return baseline

func _shop_powerups_snapshot() -> Dictionary:
	if SaveManager.has_method("get_shop_powerups"):
		return SaveManager.get_shop_powerups()
	return {REVIVE_POWERUP_ID: 0}

func _run_powerups(state: Dictionary) -> Dictionary:
	var source: Variant = state.get("powerups", {})
	var powerups: Dictionary = {}
	if typeof(source) == TYPE_DICTIONARY:
		for key in (source as Dictionary).keys():
			var id := str(key).strip_edges().to_lower()
			if id.is_empty():
				continue
			powerups[id] = max(0, int((source as Dictionary)[key]))
	return powerups

func _build_run_meta(score: int, best_before: int) -> Dictionary:
	var today: String = _today_key()
	var season: String = _season_key()
	var run_count: int = int(SaveManager.get_setting(RUN_COUNT_KEY, 0)) + 1
	SaveManager.set_setting(RUN_COUNT_KEY, run_count)

	var last_day: String = str(SaveManager.get_setting(LAST_DAY_KEY, ""))
	var session_streak: int = int(SaveManager.get_setting(SESSION_STREAK_KEY, 0))
	if last_day == today:
		session_streak += 1
	else:
		session_streak = 1
	SaveManager.set_setting(SESSION_STREAK_KEY, session_streak)
	SaveManager.set_setting(LAST_DAY_KEY, today)

	var season_best_key: String = "%s%s" % [SEASON_BEST_PREFIX, season]
	var season_best: int = int(SaveManager.get_setting(season_best_key, 0))
	if score > season_best:
		season_best = score
		SaveManager.set_setting(season_best_key, season_best)

	var rival_key: String = "%s%s" % [RIVAL_TARGET_PREFIX, season]
	var rival_target: int = int(SaveManager.get_setting(rival_key, 0))
	if rival_target <= 0:
		rival_target = _baseline_rival_target(max(best_before, season_best))
	var rival_cleared: bool = score >= rival_target
	if rival_cleared:
		rival_target = max(rival_target + 120, _round_up_step(score + 120, 50))
	SaveManager.set_setting(rival_key, rival_target)

	return {
		"is_new_best": score > best_before,
		"best_delta": max(0, best_before - score),
		"run_count": run_count,
		"session_streak": session_streak,
		"season_key": season,
		"season_best": season_best,
		"rival_target": rival_target,
		"rival_delta": max(0, rival_target - score),
		"rival_cleared": rival_cleared,
	}

func _today_key() -> String:
	var d: Dictionary = Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d.get("year", 1970), d.get("month", 1), d.get("day", 1)]

func _season_key() -> String:
	var d: Dictionary = Time.get_date_dict_from_system()
	var year: int = int(d.get("year", 1970))
	var month: int = int(d.get("month", 1))
	var day: int = int(d.get("day", 1))
	var week: int = int(ceil(float(day + (month - 1) * 30) / 7.0))
	week = clampi(week, 1, 53)
	return "%04d-W%02d" % [year, week]

func _baseline_rival_target(seed_score: int) -> int:
	return max(200, _round_up_step(seed_score + 75, 25))

func _round_up_step(value: int, step: int) -> int:
	var safe_step: int = maxi(1, step)
	return int(ceil(float(max(1, value)) / float(safe_step))) * safe_step
