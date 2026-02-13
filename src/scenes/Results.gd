extends Control

@onready var score_label: Label = $Center/Panel/VBox/ScoreLabel
@onready var best_label: Label = $Center/Panel/VBox/BestLabel
@onready var continue_button: Button = $Center/Panel/VBox/ContinueButton

var _waiting_for_reward: bool = false

func _ready() -> void:
	_update_labels()
	if not AdManager.is_connected("rewarded_earned", Callable(self, "_on_rewarded_earned")):
		AdManager.connect("rewarded_earned", Callable(self, "_on_rewarded_earned"))
	if not AdManager.is_connected("rewarded_closed", Callable(self, "_on_rewarded_closed")):
		AdManager.connect("rewarded_closed", Callable(self, "_on_rewarded_closed"))

func _exit_tree() -> void:
	if AdManager.is_connected("rewarded_earned", Callable(self, "_on_rewarded_earned")):
		AdManager.disconnect("rewarded_earned", Callable(self, "_on_rewarded_earned"))
	if AdManager.is_connected("rewarded_closed", Callable(self, "_on_rewarded_closed")):
		AdManager.disconnect("rewarded_closed", Callable(self, "_on_rewarded_closed"))

func _update_labels() -> void:
	score_label.text = "Score: %d" % RunManager.last_score
	best_label.text = "Best: %d" % SaveStore.get_high_score()
	continue_button.visible = RunManager.can_continue_current_run()
	continue_button.disabled = false
	continue_button.text = "Continue (Rewarded)"
	_waiting_for_reward = false

func _on_restart_pressed() -> void:
	RunManager.start_block_forge()

func _on_menu_pressed() -> void:
	RunManager.goto_menu()

func _on_continue_pressed() -> void:
	if _waiting_for_reward or not RunManager.can_continue_current_run():
		return
	_waiting_for_reward = true
	continue_button.disabled = true
	var shown: bool = AdManager.show_rewarded_continue()
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
