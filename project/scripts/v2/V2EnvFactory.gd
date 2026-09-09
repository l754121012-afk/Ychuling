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


# 区域主题地板：只在已有走廊上铺一层薄色板，作为“区域身份”的可读色块，不参与碰撞。
static func zone_floor(p_parent: Node, p_center: Vector3, p_size: Vector3, p_color: Color) -> MeshInstance3D:
	var mesh := PlaceholderKit.box("art_key_v2_zone_floor", p_color, p_size)
	p_parent.add_child(mesh)
	mesh.position = p_center
	return mesh


static func lamp(p_parent: Node, p_position: Vector3, p_radius: float = 0.65, p_color: Color = Color("#ffd98a")) -> Node3D:
	var host := Node3D.new()
	host.name = "DecorLamp"
	p_parent.add_child(host)
	host.position = p_position
	var pole := PlaceholderKit.box("art_key_v2_lamp_pole", Color("#8b96a8"), Vector3(0.14, 2.6, 0.14))
	pole.position.y = 1.3
	host.add_child(pole)
	var head := PlaceholderKit.box("art_key_v2_lamp_head", p_color, Vector3(p_radius * 1.4, p_radius, p_radius * 1.4))
	head.material_override = PlaceholderKit.emissive_material(p_color, 1.8)
	head.position.y = 2.75
	host.add_child(head)
	return host


static func window(p_parent: Node, p_position: Vector3, p_width: float = 1.0, p_height: float = 1.6, p_color: Color = Color("#9fd8ff")) -> MeshInstance3D:
	var mesh := PlaceholderKit.box("art_key_v2_window", p_color, Vector3(p_width, p_height, 0.16))
	mesh.material_override = PlaceholderKit.material_alpha(p_color, 0.55)
	p_parent.add_child(mesh)
	mesh.position = p_position
	return mesh


static func plaque(p_parent: Node, p_position: Vector3, p_color: Color = Color("#b58b4a")) -> MeshInstance3D:
	var mesh := PlaceholderKit.box("art_key_v2_plaque", p_color, Vector3(0.9, 0.5, 0.24))
	p_parent.add_child(mesh)
	mesh.position = p_position
	return mesh


static func spirit_fire(p_parent: Node, p_position: Vector3, p_scale: float = 1.0, p_color: Color = Color("#7ad7cf")) -> Node3D:
	var host := Node3D.new()
	host.name = "DecorSpiritFire"
	p_parent.add_child(host)
	host.position = p_position
	var base := PlaceholderKit.box("art_key_v2_spirit_fire_base", Color("#48534f"), Vector3(0.8, 0.16, 0.8) * p_scale)
	base.position.y = 0.08 * p_scale
	host.add_child(base)
	var flame := PlaceholderKit.box("art_key_v2_spirit_fire", p_color, Vector3(0.5, 0.9, 0.5) * p_scale)
	flame.material_override = PlaceholderKit.emissive_material(p_color, 2.4)
	flame.position.y = 0.62 * p_scale
	host.add_child(flame)
	return host


static func mist_zone(p_parent: Node, p_position: Vector3, p_size: Vector2 = Vector2(5.0, 3.0), p_color: Color = Color("#9fb8cf")) -> MeshInstance3D:
	var mesh := PlaceholderKit.ground_quad("art_key_v2_mist_zone", p_color, p_size)
	mesh.material_override = PlaceholderKit.material_alpha(p_color, 0.26)
	p_parent.add_child(mesh)
	mesh.position = p_position + Vector3(0.0, 0.05, 0.0)
	return mesh


# 压力机关：Area3D 触发器，玩家/箱子压上会发 pressed 信号，可在运行时连到门/机关。
static func pressure_plate(p_parent: Node, p_position: Vector3, p_size: float = 1.4, p_color: Color = Color("#c9b45a")) -> Area3D:
	var plate := Area3D.new()
	plate.name = "PressurePlate"
	p_parent.add_child(plate)
	plate.position = p_position
	var shape := BoxShape3D.new()
	shape.size = Vector3(p_size, 0.24, p_size)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = 0.12
	plate.add_child(collision)
	var mesh := PlaceholderKit.box("art_key_v2_pressure_plate", p_color, Vector3(p_size, 0.1, p_size))
	mesh.position.y = 0.14
	plate.add_child(mesh)
	plate.set_meta("press_color", p_color)
	return plate


# 可推箱：RigidBody3D 物理箱，可被撞击/推动。
static func pushable_box(p_parent: Node, p_position: Vector3, p_size: float = 1.0, p_color: Color = Color("#7f6e50")) -> RigidBody3D:
	var box := RigidBody3D.new()
	box.name = "PushableBox"
	p_parent.add_child(box)
	box.position = p_position
	var shape := BoxShape3D.new()
	shape.size = Vector3(p_size, p_size, p_size)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = p_size * 0.5
	box.add_child(collision)
	var mesh := PlaceholderKit.box("art_key_v2_pushable_box", p_color, Vector3(p_size, p_size, p_size))
	mesh.position.y = p_size * 0.5
	box.add_child(mesh)
	box.mass = 3.0
	return box


# 升降平台：AnimatableBody3D 上下往返，站在上面的角色会随平台移动。
static func lift_platform(p_parent: Node, p_position: Vector3, p_lift_height: float = 2.0, p_duration: float = 2.4, p_size: Vector3 = Vector3(2.4, 0.3, 2.0)) -> AnimatableBody3D:
	var lift := AnimatableBody3D.new()
	lift.name = "LiftPlatform"
	p_parent.add_child(lift)
	lift.position = p_position
	var shape := BoxShape3D.new()
	shape.size = p_size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = p_size.y * 0.5
	lift.add_child(collision)
	var mesh := PlaceholderKit.box("art_key_v2_lift_platform", Color("#3f6d8c"), p_size)
	mesh.position.y = p_size.y * 0.5
	lift.add_child(mesh)
	var tween := lift.create_tween()
	tween.set_loops()
	tween.tween_property(lift, "position", p_position + Vector3(0.0, p_lift_height, 0.0), p_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(lift, "position", p_position, p_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return lift


# 统一可互动门：E 门 / 能力门 / Boss 门共用一套节点与开法。
static func interactive_door(p_parent: Node, p_position: Vector3, p_size: Vector3 = Vector3(0.5, 3.2, 2.0), p_color: Color = Color("#6a4352")) -> StaticBody3D:
	var door := StaticBody3D.new()
	door.name = "InteractiveDoor"
	p_parent.add_child(door)
	door.position = p_position
	var shape := BoxShape3D.new()
	shape.size = p_size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = p_size.y * 0.5
	door.add_child(collision)
	var mesh := PlaceholderKit.box("art_key_v2_interactive_door", p_color, p_size)
	mesh.position.y = p_size.y * 0.5
	door.add_child(mesh)
	return door
