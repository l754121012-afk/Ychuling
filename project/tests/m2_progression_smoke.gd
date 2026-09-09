extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/main/M2Route.tscn")
	var main: Node = packed.instantiate()
	root.add_child(main)
	for _frame in range(6):
		await process_frame

	var route: Node = main
	var steps := 0
	while not route.get("_shift_done") and steps < 240:
		steps += 1
		var ghosts := get_nodes_in_group("ghosts")
		if ghosts.is_empty():
			if not route.get("_has_night_stamp") and is_instance_valid(route.get("_reward_pickup")):
				route._on_ability_collected("night_stamp")
			elif route.get("_boss_waiting_npc"):
				route._start_final_event()
			elif route.get("_boss_key_granted") and not route.get("_shift_done"):
				var player := get_first_node_in_group("player")
				player.global_position = Vector3(18.0, 0.9, 0.0)
			await process_frame
			continue
		for ghost in ghosts:
			if not is_instance_valid(ghost):
				continue
			if ghost.is_send_off_ready():
				ghost.start_send_off(null)
			else:
				for _hit in range(ghost.hits_to_stagger):
					ghost.on_cleaned(null)
		for _frame in range(2):
			await process_frame

	if not route.get("_shift_done") and route.get("_boss_key_granted"):
		var player := get_first_node_in_group("player")
		player.global_position = Vector3(18.0, 0.9, 0.0)
		for _frame in range(10):
			await process_frame

	print("PROGRESSION shift_done=%s reviews=%s steps=%s" % [route.get("_shift_done"), route.get("_review_count"), steps])
	quit(0 if route.get("_shift_done") and int(route.get("_review_count")) >= 4 else 1)
