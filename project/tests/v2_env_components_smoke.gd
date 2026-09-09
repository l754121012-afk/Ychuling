extends SceneTree

const EnvFactory := preload("res://scripts/v2/V2EnvFactory.gd")
const BreakableScript := preload("res://scripts/v2/V2Breakable.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root_node := Node3D.new()
	root.add_child(root_node)
	EnvFactory.platform(root_node, Vector3.ZERO, Vector3(3.0, 0.4, 2.0))
	EnvFactory.pillar(root_node, Vector3(5.0, 0.0, 0.0))
	EnvFactory.plant(root_node, Vector3(-2.0, 0.0, 0.0))
	EnvFactory.waterfall(root_node, Vector3(-5.0, 0.0, 0.0))

	var jar: StaticBody3D = BreakableScript.new()
	jar.set("breakable_id", "test_jar")
	root_node.add_child(jar)
	jar.position = Vector3(1.0, 0.0, 2.0)
	jar.on_cleaned(null)
	for _frame in range(10):
		await process_frame
	print("V2_ENV platform_children=%s jar_valid=%s" % [root_node.get_child_count(), is_instance_valid(jar)])
	quit(0 if root_node.get_child_count() >= 4 and not is_instance_valid(jar) else 1)
