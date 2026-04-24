extends Control

@onready var score_label: Label = $Center/Panel/VBox/ScoreLabel
@onready var best_label: Label = $Center/Panel/VBox/BestLabel
@onready var result_label: Label = $Center/Panel/VBox/ResultLabel
@onready var rival_label: Label = $Center/Panel/VBox/RivalLabel
@onready var continue_button: Button = $Center/Panel/VBox/ContinueButton

var _waiting_for_reward: bool = false

func _ready() -> void:
	_update_labels()
	if not AdManager.is_connected("rewarded_powerup_earned", Callable(self, "_on_rewarded_earned")):
		AdManager.connect("rewarded_powerup_earned", Callable(self, "_on_rewarded_earned"))
	if not AdManager.is_connected("rewarded_closed", Callable(self, "_on_rewarded_closed")):
		AdManager.connect("rewarded_closed", Callable(self, "_on_rewarded_closed"))

func _exit_tree() -> void:
	if AdManager.is_connected("rewarded_powerup_earned", Callable(self, "_on_rewarded_earned")):
		AdManager.disconnect("rewarded_powerup_earned", Callable(self, "_on_rewarded_earned"))
	if AdManager.is_connected("rewarded_closed", Callable(self, "_on_rewarded_closed")):
		AdManager.disconnect("rewarded_closed", Callable(self, "_on_rewarded_closed"))

func _update_labels() -> void:
	score_label.text = "Score: %d" % RunManager.last_score
	best_label.text = "Best: %d" % int(SaveManager.get_best("block_forge_high_score", 0))
	_apply_run_meta(RunManager.get_last_run_meta())
	continue_button.visible = RunManager.can_continue_current_run()
	continue_button.disabled = false
	var stocked_revives: int = RunManager.get_available_revives_for_continue()
	if stocked_revives > 0:
		continue_button.text = "Continue (Use Revive x%d)" % stocked_revives
	else:
		continue_button.text = "Continue (Rewarded)"
	_waiting_for_reward = false

func _apply_run_meta(meta: Dictionary) -> void:
	var is_new_best: bool = bool(meta.get("is_new_best", false))
	if is_new_best:
		result_label.text = "New personal best run."
		result_label.modulate = Color(1.0, 0.93, 0.58)
	else:
		var best_delta: int = int(meta.get("best_delta", 0))
		result_label.text = "Need %d to beat your best." % max(1, best_delta)
		result_label.modulate = Color(0.86, 0.93, 1.0)

	var rival_target: int = int(meta.get("rival_target", 0))
	var rival_delta: int = int(meta.get("rival_delta", 0))
	var rival_cleared: bool = bool(meta.get("rival_cleared", false))
	var season_key: String = str(meta.get("season_key", ""))
	var season_best: int = int(meta.get("season_best", 0))
	if rival_target > 0:
		if rival_cleared:
			rival_label.text = "Season rival cleared. Next target: %d" % rival_target
			rival_label.modulate = Color(1.0, 0.9, 0.55)
		else:
			rival_label.text = "Season rival target %d (%d to go)" % [rival_target, max(1, rival_delta)]
			rival_label.modulate = Color(0.87, 0.94, 1.0)
	else:
		rival_label.text = ""
	if season_best > 0:
		rival_label.text += " | Season best %d" % season_best
	if not season_key.is_empty():
		rival_label.text += " [%s]" % season_key

func _on_restart_pressed() -> void:
	RunManager.start_block_forge()

func _on_menu_pressed() -> void:
	RunManager.goto_menu()

func _on_continue_pressed() -> void:
	if _waiting_for_reward or not RunManager.can_continue_current_run():
		return
	if RunManager.get_available_revives_for_continue() > 0:
		var resumed_by_stock: bool = RunManager.continue_block_forge_with_shop_powerup()
		if not resumed_by_stock:
			_update_labels()
		return
	_waiting_for_reward = true
	continue_button.disabled = true
	var shown: bool = AdManager.show_rewarded_for_powerup()
	if not shown:
		_waiting_for_reward = false
		continue_button.disabled = false
		continue_button.text = "Ad unavailable"

func _on_rewarded_earned() -> void:
	if not _waiting_for_reward:
		return
	_waiting_for_reward = false
	var resumed: bool = RunManager.continue_block_forge_after_reward()
	if not resumed:
		_update_labels()

func _on_rewarded_closed() -> void:
	if _waiting_for_reward:
		_waiting_for_reward = false
		continue_button.disabled = false
