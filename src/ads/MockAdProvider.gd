extends Node
class_name MockAdProvider

signal interstitial_loaded
signal interstitial_closed
signal rewarded_loaded
signal rewarded_earned
signal rewarded_closed

var _interstitial_ready: bool = true
var _rewarded_ready: bool = true

func configure(_app_id: String, _interstitial_id: String, _rewarded_id: String) -> void:
	pass

func load_interstitial(_ad_unit_id: String) -> void:
	_interstitial_ready = true
	emit_signal("interstitial_loaded")

func load_rewarded(_ad_unit_id: String) -> void:
	_rewarded_ready = true
	emit_signal("rewarded_loaded")

func show_interstitial(_ad_unit_id: String) -> bool:
	if not _interstitial_ready:
		return false
	_interstitial_ready = false
	call_deferred("_emit_interstitial_closed")
	return true

func show_rewarded(_ad_unit_id: String) -> bool:
	if not _rewarded_ready:
		return false
	_rewarded_ready = false
	call_deferred("_emit_rewarded_earned")
	call_deferred("_emit_rewarded_closed")
	return true

func _emit_interstitial_closed() -> void:
	emit_signal("interstitial_closed")

func _emit_rewarded_earned() -> void:
	emit_signal("rewarded_earned")

func _emit_rewarded_closed() -> void:
	emit_signal("rewarded_closed")
