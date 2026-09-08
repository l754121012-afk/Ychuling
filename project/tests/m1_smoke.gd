extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/main/M2Route.tscn")
	if packed == null:
		push_error("SMOKE: main scene missing")
		quit(1)
		return
	var main: Node = packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var player_count := get_nodes_in_group("player").size()
	var ghost_count := get_nodes_in_group("ghosts").size()
	print("SMOKE player=%d ghosts=%d" % [player_count, ghost_count])
	quit(0 if player_count == 1 and ghost_count == 4 else 1)
