extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	ProjectSettings.set_setting("fivestar_authoring/playtest_mode", false)
	var packed: PackedScene = load("res://scenes/main/M2Route.tscn")
	var main: Node = packed.instantiate()
	root.add_child(main)
	for _frame in range(10):
		await process_frame

	var player: Node3D = get_first_node_in_group("player")
	player.global_position = Vector3(-12.0, 0.9, 0.0)
	player.add_momentum(3)
	var ghosts := get_nodes_in_group("ghosts")
	for index in range(ghosts.size()):
		ghosts[index].global_position = Vector3(-11.4 + index * 0.7, 0.0, -0.8 if index % 2 == 0 else 0.8)
	player._start_heavy_sweep()

	for _frame in range(240):
		await process_frame

	print("HEAVY state=%s momentum=%s ghost_hits=%s" % [
		player.get("_state"),
		player.get("_momentum"),
		ghosts[0].get("_hits_remaining") if is_instance_valid(ghosts[0]) else "gone",
	])
	quit(0 if int(player.get("_state")) == 0 else 1)
