extends "res://scripts/presentation_contract_test.gd"
var diag_battles := 0
func _battle(main: Node, rotate: bool, fps: int, speed: float) -> Dictionary:
    var result: Dictionary = super._battle(main,rotate,fps,speed)
    var path := "user://battle-%d.bin" % diag_battles
    var file := FileAccess.open(path,FileAccess.WRITE)
    file.store_buffer(var_to_bytes({"normalized_original":result,"attempt":main.battle_log.attempt_id,
        "scope":main._snapshot_data().utility_scope_id,"raw_events":main.battle_log.events.duplicate(true)}))
    file.close()
    print("DIAG_BATTLE_DUMP=",ProjectSettings.globalize_path(path))
    diag_battles += 1
    return result
