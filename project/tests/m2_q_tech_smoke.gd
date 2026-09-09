extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/main/V2FirstLoop.tscn")
	var main: Node = packed.instantiate()
	root.add_child(main)
	for _frame in range(10):
		await process_frame

	var player: Node3D = get_first_node_in_group("player")
	var start_x: float = player.global_position.x
	player._start_q_tech(Vector3.RIGHT)
	for _frame in range(80):
		await process_frame
	print("Q_TECH start=%s end=%s state=%s stamina=%s" % [start_x, player.global_position.x, player.get("_state"), player.get("stamina")])
	quit(0 if player.global_position.x > start_x + 1.0 and int(player.get("_state")) == 0 else 1)
