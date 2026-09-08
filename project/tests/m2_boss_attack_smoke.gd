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
	ghost.configure_attack_style("boss")
	ghost.set("art_scale", 2.9)
	player.global_position = ghost.global_position + Vector3(0.0, 0.0, 3.0)
	ghost._start_shockwave()

	for _frame in range(120):
		await process_frame

	print("BOSS_ATTACK action=%s state=%s" % [ghost.get("_action"), ghost.get("state")])
	quit(0)
