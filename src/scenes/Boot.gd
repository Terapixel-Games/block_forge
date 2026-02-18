extends Node

const LEGACY_SAVE_PATH := "user://block_forge_save.json"

func _ready() -> void:
	_migrate_legacy_save_if_needed()
	call_deferred("_go_menu")

func _go_menu() -> void:
	RunManager.goto_menu()

func _migrate_legacy_save_if_needed() -> void:
	var meta_value: Variant = SaveManager.data.get("meta", {})
	var meta: Dictionary = meta_value if meta_value is Dictionary else {}
	if bool(meta.get("block_forge_legacy_migrated", false)):
		return

	if FileAccess.file_exists(LEGACY_SAVE_PATH):
		var file := FileAccess.open(LEGACY_SAVE_PATH, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			file.close()
			if parsed is Dictionary:
				var legacy: Dictionary = parsed as Dictionary
				var legacy_best: int = int(legacy.get("block_forge_high_score", 0))
				if legacy_best > int(SaveManager.get_best("block_forge_high_score", 0)):
					SaveManager.data["best"]["block_forge_high_score"] = legacy_best
				var legacy_games: int = int(legacy.get("games_played", 0))
				if legacy_games > SaveManager.games_played():
					SaveManager.data["meta"]["games_played"] = legacy_games

	SaveManager.data["meta"]["block_forge_legacy_migrated"] = true
	SaveManager.flush()
