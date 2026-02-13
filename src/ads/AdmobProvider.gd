extends Node
class_name AdmobProvider

signal interstitial_loaded
signal interstitial_closed
signal rewarded_loaded
signal rewarded_earned
signal rewarded_closed

const ANDROID_DEBUG_APP_ID: String = "ca-app-pub-3940256099942544~3347511713"
const ANDROID_DEBUG_INTERSTITIAL_ID: String = "ca-app-pub-3940256099942544/1033173712"
const ANDROID_DEBUG_REWARDED_ID: String = "ca-app-pub-3940256099942544/5224354917"
const IOS_DEBUG_APP_ID: String = "ca-app-pub-3940256099942544~1458002511"
const IOS_DEBUG_INTERSTITIAL_ID: String = "ca-app-pub-3940256099942544/4411468910"
const IOS_DEBUG_REWARDED_ID: String = "ca-app-pub-3940256099942544/1712485313"

var admob: Node
var _initialized: bool = false
var _interstitial_ready: bool = false
var _rewarded_ready: bool = false
var _pending_interstitial_load: bool = false
var _pending_rewarded_load: bool = false

func configure(app_id: String, interstitial_id: String, rewarded_id: String) -> void:
	if admob != null:
		return
	var admob_script: Script = load("res://addons/AdmobPlugin/Admob.gd") as Script
	if admob_script == null:
		push_warning("AdmobProvider: Admob plugin script is missing.")
		return
	admob = admob_script.new()
	var use_real_ids: bool = not OS.is_debug_build()
	_set_if_exists(admob, "is_real", use_real_ids)
	_set_if_exists(admob, "android_real_application_id", app_id)
	_set_if_exists(admob, "ios_real_application_id", app_id)
	_set_if_exists(admob, "android_debug_application_id", ANDROID_DEBUG_APP_ID)
	_set_if_exists(admob, "ios_debug_application_id", IOS_DEBUG_APP_ID)
	_set_if_exists(admob, "android_real_interstitial_id", interstitial_id)
	_set_if_exists(admob, "ios_real_interstitial_id", interstitial_id)
	_set_if_exists(admob, "android_debug_interstitial_id", ANDROID_DEBUG_INTERSTITIAL_ID)
	_set_if_exists(admob, "ios_debug_interstitial_id", IOS_DEBUG_INTERSTITIAL_ID)
	_set_if_exists(admob, "android_real_rewarded_id", rewarded_id)
	_set_if_exists(admob, "ios_real_rewarded_id", rewarded_id)
	_set_if_exists(admob, "android_debug_rewarded_id", ANDROID_DEBUG_REWARDED_ID)
	_set_if_exists(admob, "ios_debug_rewarded_id", IOS_DEBUG_REWARDED_ID)
	add_child(admob)
	admob.connect("initialization_completed", Callable(self, "_on_initialized"))
	admob.connect("interstitial_ad_loaded", Callable(self, "_on_interstitial_loaded"))
	admob.connect("interstitial_ad_failed_to_load", Callable(self, "_on_interstitial_failed_to_load"))
	admob.connect("interstitial_ad_dismissed_full_screen_content", Callable(self, "_on_interstitial_closed"))
	admob.connect("rewarded_ad_loaded", Callable(self, "_on_rewarded_loaded"))
	admob.connect("rewarded_ad_failed_to_load", Callable(self, "_on_rewarded_failed_to_load"))
	admob.connect("rewarded_ad_user_earned_reward", Callable(self, "_on_rewarded_earned"))
	admob.connect("rewarded_ad_dismissed_full_screen_content", Callable(self, "_on_rewarded_closed"))
	if admob.has_method("initialize"):
		admob.call("initialize")

func load_interstitial(_ad_unit_id: String) -> void:
	if admob == null:
		return
	if not _initialized:
		_pending_interstitial_load = true
		return
	if admob.has_method("load_interstitial_ad"):
		admob.call("load_interstitial_ad")

func load_rewarded(_ad_unit_id: String) -> void:
	if admob == null:
		return
	if not _initialized:
		_pending_rewarded_load = true
		return
	if admob.has_method("load_rewarded_ad"):
		admob.call("load_rewarded_ad")

func show_interstitial(_ad_unit_id: String) -> bool:
	if admob == null or not _interstitial_ready:
		return false
	_interstitial_ready = false
	if admob.has_method("show_interstitial_ad"):
		admob.call("show_interstitial_ad")
		return true
	return false

func show_rewarded(_ad_unit_id: String) -> bool:
	if admob == null or not _rewarded_ready:
		return false
	_rewarded_ready = false
	if admob.has_method("show_rewarded_ad"):
		admob.call("show_rewarded_ad")
		return true
	return false

func _on_interstitial_loaded(_ad_info, _response_info = null) -> void:
	_interstitial_ready = true
	emit_signal("interstitial_loaded")

func _on_interstitial_failed_to_load(_ad_info, _error_data) -> void:
	_interstitial_ready = false

func _on_interstitial_closed(_ad_info) -> void:
	_interstitial_ready = false
	emit_signal("interstitial_closed")

func _on_rewarded_loaded(_ad_info, _response_info = null) -> void:
	_rewarded_ready = true
	emit_signal("rewarded_loaded")

func _on_rewarded_failed_to_load(_ad_info, _error_data) -> void:
	_rewarded_ready = false

func _on_rewarded_earned(_ad_info, _reward_data) -> void:
	emit_signal("rewarded_earned")

func _on_rewarded_closed(_ad_info) -> void:
	_rewarded_ready = false
	emit_signal("rewarded_closed")

func _on_initialized(_status_data = null) -> void:
	_initialized = true
	if _pending_interstitial_load:
		_pending_interstitial_load = false
		load_interstitial("")
	if _pending_rewarded_load:
		_pending_rewarded_load = false
		load_rewarded("")

func _set_if_exists(target: Object, property_name: String, value: Variant) -> void:
	for property_data in target.get_property_list():
		if String(property_data.get("name", "")) == property_name:
			target.set(property_name, value)
			return
