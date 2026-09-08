extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/main/M2Route.tscn")
	var main: Node = packed.instantiate()
	root.add_child(main)
	for _frame in range(30):
		await process_frame

	var player: Node3D = get_first_node_in_group("player")
	var source: Node3D = get_first_node_in_group("ghosts")
	for _hit in range(5):
		player.set("_invuln_time", 0.0)
		player.take_hit(source)
		await process_frame

	for _frame in range(10):
		await process_frame

	var ghost_count := get_nodes_in_group("ghosts").size()
	print("DEFEAT health=%s position=%s ghosts=%s" % [player.get("health"), player.global_position, ghost_count])
	quit(0 if int(player.get("health")) == 5 and ghost_count == 4 else 1)
