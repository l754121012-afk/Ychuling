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
	var ghosts := get_nodes_in_group("ghosts")
	if ghosts.size() < 2:
		quit(1)
		return
	var first: Node3D = ghosts[0]
	var second: Node3D = ghosts[1]
	player.global_position = Vector3(-12.0, 0.9, 0.0)
	first.global_position = Vector3(-10.2, 0.0, 0.0)
	second.global_position = Vector3(-8.4, 0.0, 0.0)
	first.on_cleaned(player, true)

	for _frame in range(50):
		await process_frame

	var chain_count: int = main.get("_chain_count")
	print("CHAIN chain_count=%s second_hits=%s" % [
		chain_count,
		second.get("_hits_remaining") if is_instance_valid(second) else "gone",
	])
	quit(0 if chain_count >= 1 else 1)
