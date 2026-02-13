extends Control

@onready var quit_button: Button = $Center/Panel/VBox/QuitButton

func _ready() -> void:
	if OS.has_feature("web"):
		quit_button.visible = false

func _on_start_pressed() -> void:
	RunManager.start_block_forge()

func _on_quit_pressed() -> void:
	get_tree().quit()
