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
	ghost.global_position = Vector3(player.global_position.x, 0.0, player.global_position.z + 3.0)
	ghost._start_pool(player)
	for _frame in range(100):
		await process_frame
	print("POOL action=%s" % ghost.get("_action"))
	quit(0)
