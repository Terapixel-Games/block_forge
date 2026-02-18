extends Node

var _freeze_timer := 0.0
var _shake_timer := 0.0
var _shake_strength := 0.0
var _camera: Camera2D = null
var _camera_base_offset := Vector2.ZERO

func bind_camera(cam: Camera2D) -> void:
    _camera = cam
    _camera_base_offset = cam.offset

func hit_freeze(duration: float) -> void:
    _freeze_timer = max(_freeze_timer, duration)
    Engine.time_scale = 0.0

func micro_shake(duration: float, strength_px: float) -> void:
    _shake_timer = max(_shake_timer, duration)
    _shake_strength = max(_shake_strength, strength_px)

func _process(delta: float) -> void:
    if _freeze_timer > 0.0:
        _freeze_timer -= delta
        if _freeze_timer <= 0.0:
            Engine.time_scale = 1.0

    if _camera == null:
        return

    if _shake_timer > 0.0:
        _shake_timer -= delta
        var falloff: float = max(0.0, _shake_timer)
        var ox: float = randf_range(-_shake_strength, _shake_strength) * falloff
        var oy: float = randf_range(-_shake_strength, _shake_strength) * falloff
        _camera.offset = _camera_base_offset + Vector2(ox, oy)
    else:
        _camera.offset = _camera_base_offset

func _exit_tree() -> void:
    Engine.time_scale = 1.0
    if _camera != null:
        _camera.offset = _camera_base_offset
