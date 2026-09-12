extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var low_result := await _run_case(Vector3(4.0, 0.3, 4.0), Vector3(0.0, 0.15, 0.0), 30)
	var wall_result := await _run_case(Vector3(4.0, 2.0, 0.5), Vector3(0.0, 1.0, 0.25), 45)

	var low_ok := float(low_result.y) > 1.05 and float(low_result.z) < 1.9
	var wall_ok := float(wall_result.y) < 1.1 and float(wall_result.z) > 0.9
	print("STEP_UP low_ok=%s low_y=%.2f low_z=%.2f wall_ok=%s wall_y=%.2f wall_z=%.2f" % [
		low_ok,
		low_result.y,
		low_result.z,
		wall_ok,
		wall_result.y,
		wall_result.z,
	])
	quit(0 if low_ok and wall_ok else 1)


func _run_case(p_obstacle_size: Vector3, p_obstacle_position: Vector3, p_frames: int) -> Dictionary:
	var world := Node3D.new()
	world.name = "StepUpCase"
	root.add_child(world)
	_add_box(world, Vector3(8.0, 0.2, 8.0), Vector3(0.0, -0.1, 0.0), "Floor")
	_add_box(world, p_obstacle_size, p_obstacle_position, "Obstacle")

	var player := PlayerController.new()
	player.name = "Player"
	world.add_child(player)
	player.global_position = Vector3(0.0, 0.92, 2.7)
	for _frame in range(4):
		await physics_frame

	Input.action_press("move_up")
	for _frame in range(p_frames):
		await physics_frame
	Input.action_release("move_up")
	await physics_frame

	var result := {
		"y": player.global_position.y,
		"z": player.global_position.z,
	}
	world.queue_free()
	await process_frame
	return result


func _add_box(p_parent: Node3D, p_size: Vector3, p_position: Vector3, p_name: String) -> void:
	var body := StaticBody3D.new()
	body.name = p_name
	body.position = p_position
	var shape := BoxShape3D.new()
	shape.size = p_size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	p_parent.add_child(body)
