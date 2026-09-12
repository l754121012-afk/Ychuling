extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := Node3D.new()
	world.name = "BounceCase"
	root.add_child(world)
	_add_box(world, Vector3(8.0, 0.2, 8.0), Vector3(0.0, -0.1, 0.0), "Floor")
	_add_box(world, Vector3(0.5, 2.4, 8.0), Vector3(-2.0, 1.2, 0.0), "HighWall")

	var player := PlayerController.new()
	player.name = "Player"
	world.add_child(player)
	player.global_position = Vector3(0.0, 0.92, 0.0)
	for _frame in range(4):
		await physics_frame

	var start_x: float = player.global_position.x
	var min_x: float = start_x
	player._start_dash(Vector3(-1.0, 0.0, 0.0))
	for _frame in range(45):
		await physics_frame
		min_x = minf(min_x, player.global_position.x)

	var end_x: float = player.global_position.x
	var end_velocity: Vector3 = player.get("velocity")
	var bounced: bool = min_x < start_x - 0.8 and end_x > start_x + 0.2 and end_velocity.x >= 0.0
	print("BOUNCE bounced=%s start_x=%.2f min_x=%.2f end_x=%.2f velocity=(%.3f, %.3f, %.3f)" % [
		bounced,
		start_x,
		min_x,
		end_x,
		end_velocity.x,
		end_velocity.y,
		end_velocity.z,
	])
	quit(0 if bounced else 1)


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
