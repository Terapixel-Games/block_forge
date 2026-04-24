extends RefCounted

const GENERIC_PLAYTHROUGH = preload("res://tests/scenarios/generic_playthrough.gd")


func create(scenario_id: String):
	match scenario_id.strip_edges().to_lower():
		"generic_playthrough":
			return GENERIC_PLAYTHROUGH.new()
		_:
			return null


func list_ids() -> PackedStringArray:
	return PackedStringArray([
		"generic_playthrough",
	])


func default_id() -> String:
	return "generic_playthrough"
