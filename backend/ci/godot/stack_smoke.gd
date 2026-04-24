extends SceneTree

const MAIN_SCENE_PATH := "res://src/scenes/Boot.tscn"

func _init() -> void:
    var packed_scene: PackedScene = load(MAIN_SCENE_PATH)
    if packed_scene == null:
        push_error("Unable to load %s" % MAIN_SCENE_PATH)
        quit(1)
        return

    var scene := packed_scene.instantiate()
    if scene == null:
        push_error("Unable to instantiate %s" % MAIN_SCENE_PATH)
        quit(1)
        return

    scene.queue_free()
    print("Godot smoke test passed.")
    quit(0)
