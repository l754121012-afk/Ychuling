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
	player.global_position = Vector3(-19.0, 0.9, 0.0)
	player._start_dash(Vector3(-1.0, 0.0, 0.0))
	var start_x: float = player.global_position.x
	for _frame in range(45):
		await process_frame
	print("BOUNCE start_x=%s end_x=%s velocity=%s" % [start_x, player.global_position.x, player.get("velocity")])
	quit(0 if player.global_position.x > start_x + 0.2 else 1)
