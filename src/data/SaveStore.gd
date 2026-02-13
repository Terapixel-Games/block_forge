extends Node

const SAVE_PATH := "user://block_forge_save.json"
const DEFAULT_DATA := {
	"block_forge_high_score": 0,
	"games_played": 0,
}

var data: Dictionary = DEFAULT_DATA.duplicate(true)
var _initialized: bool = false

func _ready() -> void:
	initialize()

func initialize() -> void:
	if _initialized:
		return
	_initialized = true
	load_save()

func load_save() -> void:
	data = DEFAULT_DATA.duplicate(true)
	if not FileAccess.file_exists(SAVE_PATH):
		save()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		for key in DEFAULT_DATA.keys():
			if parsed.has(key):
				data[key] = int(parsed[key])

func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))
	file.close()

func set_high_score(score: int) -> void:
	if score > get_high_score():
		data["block_forge_high_score"] = score
		save()

func increment_games_played() -> void:
	data["games_played"] = get_games_played() + 1
	save()

func get_high_score() -> int:
	return int(data.get("block_forge_high_score", 0))

func get_games_played() -> int:
	return int(data.get("games_played", 0))
