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
	var ghost: Node3D = get_first_node_in_group("ghosts")
	ghost.global_position = Vector3(player.global_position.x, 0.0, player.global_position.z + 2.0)
	player._mark_followup_target(ghost)
	var started: bool = player._try_start_followup()

	for _frame in range(140):
		await process_frame

	print("FOLLOWUP started=%s state=%s ghost_hits=%s" % [
		started,
		player.get("_state"),
		ghost.get("_hits_remaining") if is_instance_valid(ghost) else "gone",
	])
	quit(0 if started and int(player.get("_state")) == 0 else 1)
