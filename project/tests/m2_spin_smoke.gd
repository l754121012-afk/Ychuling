extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/main/M2Route.tscn")
	var main: Node = packed.instantiate()
	root.add_child(main)
	for _frame in range(10):
		await process_frame

	var player: Node3D = get_first_node_in_group("player")
	var ghost: Node3D = get_first_node_in_group("ghosts")
	ghost.global_position = Vector3(player.global_position.x + 1.2, 0.0, player.global_position.z)
	player._start_spin()

	var spin_seen := false
	for _frame in range(150):
		await process_frame
		if int(player.get("_state")) == 4:
			spin_seen = true

	print("SPIN spin_seen=%s state=%s ghost_hits=%s" % [
		spin_seen,
		player.get("_state"),
		ghost.get("_hits_remaining") if is_instance_valid(ghost) else "gone",
	])
	quit(0 if spin_seen else 1)
