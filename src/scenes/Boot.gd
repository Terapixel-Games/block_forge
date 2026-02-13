extends Node

func _ready() -> void:
	SaveStore.initialize()
	call_deferred("_go_menu")

func _go_menu() -> void:
	RunManager.goto_menu()
