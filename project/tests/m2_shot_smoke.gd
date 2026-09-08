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
	var shot_ghost: Node3D = null
	for ghost in get_nodes_in_group("ghosts"):
		if int(ghost.get("attack_style")) == 4:
			shot_ghost = ghost
			break
	if shot_ghost:
		shot_ghost.global_position = Vector3(player.global_position.x, 0.0, player.global_position.z + 3.0)
		shot_ghost._fire_shot(player)

	var orbs_at_half := 0
	var orb_z := -999.0
	var orb_y := -999.0
	var player_y := -999.0
	for _frame in range(60):
		await process_frame
		if _frame == 30:
			var orbs := get_nodes_in_group("spirit_orbs")
			orbs_at_half = orbs.size()
			if not orbs.is_empty():
				orb_z = orbs[0].global_position.z
				orb_y = orbs[0].global_position.y
				player_y = player.global_position.y

	var action_text := "none"
	if is_instance_valid(shot_ghost):
		action_text = str(shot_ghost.get("_action"))
	print("SHOT health=%s found=%s action=%s orbs=%s orb_zy=%s/%s player_zy=%s/%s" % [player.get("health"), shot_ghost != null, action_text, orbs_at_half, orb_z, orb_y, player.global_position.z, player_y])
	quit(0 if shot_ghost != null else 1)
