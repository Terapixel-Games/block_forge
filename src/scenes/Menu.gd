extends Control

@onready var quit_button: Button = $Center/Panel/VBox/QuitButton
@onready var objective_label: Label = $Center/Panel/VBox/ObjectiveLabel

func _ready() -> void:
	if OS.has_feature("web"):
		quit_button.visible = false
	var rival_target: int = int(RunManager.get_active_rival_target())
	if rival_target > 0:
		objective_label.text += "\nSeason rival target: %d" % rival_target

func _on_start_pressed() -> void:
	RunManager.start_block_forge()

func _on_quit_pressed() -> void:
	get_tree().quit()
