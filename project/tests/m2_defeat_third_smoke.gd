extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/main/M2Route.tscn")
	var main: Node = packed.instantiate()
	root.add_child(main)
	for _frame in range(10):
		await process_frame

	main.set("_case_index", 2)
	main.set("_review_count", 3)
	main._handle_player_defeat()
	for _frame in range(20):
		await process_frame

	var player: Node3D = get_first_node_in_group("player")
	print("DEATH_THIRD case_index=%s review=%s pos=%s" % [main.get("_case_index"), main.get("_review_count"), player.global_position])
	quit(0 if int(main.get("_case_index")) == 0 and int(main.get("_review_count")) == 0 else 1)
