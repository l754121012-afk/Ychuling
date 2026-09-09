class_name V2EnvFactory
extends RefCounted


static func platform(p_parent: Node, p_position: Vector3, p_size: Vector3, p_color: Color = Color("#8b96a8")) -> StaticBody3D:
	var body := StaticBody3D.new()
	p_parent.add_child(body)
	body.position = p_position
	var shape := BoxShape3D.new()
	shape.size = p_size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	var mesh := PlaceholderKit.box("art_key_v2_platform", p_color, p_size)
	body.add_child(mesh)
	return body


static func pillar(p_parent: Node, p_position: Vector3, p_radius: float = 0.5, p_height: float = 4.0, p_color: Color = Color("#7c8a9a")) -> MeshInstance3D:
	var mesh := PlaceholderKit.box("art_key_v2_pillar", p_color, Vector3(p_radius * 2.0, p_height, p_radius * 2.0))
	p_parent.add_child(mesh)
	mesh.position = p_position + Vector3(0.0, p_height * 0.5, 0.0)
	return mesh


static func plant(p_parent: Node, p_position: Vector3, p_scale: float = 1.0) -> Node3D:
	var host := Node3D.new()
	host.name = "DecorPlant"
	p_parent.add_child(host)
	host.position = p_position
	var stem := PlaceholderKit.box("art_key_v2_plant_stem", Color("#4f8f63"), Vector3(0.12, 1.0, 0.12) * p_scale)
	stem.position.y = 0.5 * p_scale
	host.add_child(stem)
	var leaf := PlaceholderKit.box("art_key_v2_plant_leaf", Color("#8bc47a"), Vector3(0.7, 0.12, 0.4) * p_scale)
	leaf.position = Vector3(0.3, 1.0, 0.0) * p_scale
	leaf.rotation_degrees = Vector3(0.0, 25.0, 10.0)
	host.add_child(leaf)
	return host


static func waterfall(p_parent: Node, p_position: Vector3, p_width: float = 3.0, p_height: float = 7.0) -> MeshInstance3D:
	var mesh := PlaceholderKit.box("art_key_v2_waterfall", Color("#79c7d6"), Vector3(p_width * 0.2, p_height, p_width))
	p_parent.add_child(mesh)
	mesh.position = p_position + Vector3(0.0, p_height * 0.5, 0.0)
	return mesh
