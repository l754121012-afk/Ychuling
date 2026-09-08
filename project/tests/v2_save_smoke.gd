extends SceneTree

const SaveScript := preload("res://scripts/v2/V2SaveSystem.gd")
const TEST_PATH := "user://fivestar_v2_smoke.cfg"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	SaveScript.clear_run(TEST_PATH)
	var saved := SaveScript.save_run(
		20260909,
		Vector3(-13.5, 0.9, 0.0),
		{"seal_key": true, "night_stamp": true},
		{"side_a": true, "side_b": false},
		["gate_east", "boss_room"],
		2,
		true,
		TEST_PATH
	)
	var data: Dictionary = SaveScript.load_run(TEST_PATH)
	print("V2_SAVE saved=%s seed=%s key=%s rest=%s" % [
		saved,
		data.get("seed"),
		data.get("abilities", {}).get("seal_key", false),
		data.get("rest_point"),
	])
	SaveScript.clear_run(TEST_PATH)
	quit(0 if saved and int(data.get("seed", 0)) == 20260909 and bool(data.get("abilities", {}).get("seal_key", false)) else 1)
