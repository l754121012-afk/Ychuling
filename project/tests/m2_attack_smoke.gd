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
	ghost.global_position = player.global_position + Vector3(0.0, 0.0, 2.2)
	ghost.global_position.x = player.global_position.x

	for _frame in range(150):
		await process_frame

	print("ATTACK health=%s ghost_action=%s" % [player.get("health"), ghost.get("_action")])
	quit(0)
