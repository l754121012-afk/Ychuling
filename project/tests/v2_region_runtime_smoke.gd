extends SceneTree

const RouteData := preload("res://scripts/v2/V2RouteData.gd")
const RuntimeScript := preload("res://scripts/v2/V2RegionRuntime.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var region: Dictionary = RouteData.load_region()
	var runtime = RuntimeScript.new()
	runtime.setup_region(region, 20260909)

	var early_blocked: bool = not runtime.can_reach_zone("seal_endpoint")
	runtime.complete_quest("side_a")
	var stamp_obtained: bool = runtime.abilities.has("night_stamp")
	var boss_still_blocked: bool = not runtime.can_reach_zone("boss_room")
	runtime.complete_quest("side_b")
	runtime.complete_boss()
	var objective_open: bool = runtime.can_reach_zone("seal_endpoint")

	var save_data: Dictionary = runtime.build_save_data(Vector3(-13.5, 0.9, 0.0), 3)
	var restored = RuntimeScript.new()
	restored.setup_region(region)
	restored.restore_from_save(save_data)

	print("V2_RUNTIME blocked=%s stamp=%s boss_blocked=%s objective=%s restored_key=%s" % [
		early_blocked,
		stamp_obtained,
		boss_still_blocked,
		objective_open,
		restored.abilities.has("night_stamp"),
	])
	quit(0 if early_blocked and stamp_obtained and boss_still_blocked and objective_open and restored.abilities.has("night_stamp") else 1)
