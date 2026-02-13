extends Node

signal rewarded_earned
signal rewarded_closed

const APP_ID := "ca-app-pub-8413230766502262~4431975968"
const INTERSTITIAL_ID := "ca-app-pub-8413230766502262/9772756961"
const REWARDED_ID := "ca-app-pub-8413230766502262/3231399348"

const MockAdProviderScript := preload("res://src/ads/MockAdProvider.gd")
const AdmobProviderScript := preload("res://src/ads/AdmobProvider.gd")

var _provider: Node
var _rewarded_request_active: bool = false

func _ready() -> void:
	if Engine.has_singleton("AdmobPlugin"):
		_provider = AdmobProviderScript.new()
	else:
		_provider = MockAdProviderScript.new()
	add_child(_provider)
	_provider.call("configure", APP_ID, INTERSTITIAL_ID, REWARDED_ID)
	_provider.connect("interstitial_closed", Callable(self, "_on_interstitial_closed"))
	_provider.connect("rewarded_earned", Callable(self, "_on_rewarded_earned"))
	_provider.connect("rewarded_closed", Callable(self, "_on_rewarded_closed"))
	_provider.call("load_interstitial", INTERSTITIAL_ID)
	_provider.call("load_rewarded", REWARDED_ID)

func on_game_finished() -> void:
	SaveStore.increment_games_played()
	maybe_show_interstitial()

func maybe_show_interstitial() -> void:
	if _provider == null:
		return
	var games_played: int = SaveStore.get_games_played()
	if games_played <= 0 or games_played % 3 != 0:
		return
	var shown: bool = bool(_provider.call("show_interstitial", INTERSTITIAL_ID))
	if not shown:
		_provider.call("load_interstitial", INTERSTITIAL_ID)

func show_rewarded_continue() -> bool:
	if _provider == null:
		return false
	if _rewarded_request_active:
		return false
	_rewarded_request_active = true
	var shown: bool = bool(_provider.call("show_rewarded", REWARDED_ID))
	if not shown:
		_rewarded_request_active = false
		_provider.call("load_rewarded", REWARDED_ID)
	return shown

func _on_interstitial_closed() -> void:
	if _provider != null:
		_provider.call("load_interstitial", INTERSTITIAL_ID)

func _on_rewarded_earned() -> void:
	emit_signal("rewarded_earned")

func _on_rewarded_closed() -> void:
	_rewarded_request_active = false
	if _provider != null:
		_provider.call("load_rewarded", REWARDED_ID)
	emit_signal("rewarded_closed")
