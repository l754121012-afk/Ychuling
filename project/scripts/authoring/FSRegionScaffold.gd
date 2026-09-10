class_name FSRegionScaffold
extends RefCounted

const Schema := preload("res://scripts/authoring/FSAuthoringSchema.gd")
const RouteData := preload("res://scripts/v2/V2RouteData.gd")
const EnvFactory := preload("res://scripts/v2/V2EnvFactory.gd")


# 将现有区域 JSON 展开成“可手调作者场景”。这里只创建普通 Godot 节点，不挂运行时行为，
# 避免用户保存作者场景后与运行时脚本重复创建碰撞或表现。
static func build(p_root: Node3D, p_region: Dictionary, p_region_id: String = "") -> Dictionary:
	var region_id := Schema.sanitize_token(p_region_id)
	if region_id.is_empty():
		region_id = Schema.sanitize_token(str(p_region.get("region_id", "region")))
	Schema.apply_to_node(p_root, Schema.make(
		region_id,
		"region",
		"none",
		"",
		["authored"],
		[],
		{"region_name": str(p_region.get("region_name", ""))}
	))
	p_root.add_to_group("fs.region_generated")

	_build_route_frame(p_root)
	_build_route_gates(p_root)

	var zone_count := 0
	var prop_count := 0
	var decor_count := 0
	var gate_count := 0
	for zone in p_region.get("zones", []):
		if zone.has("min_x") and zone.has("max_x"):
			var zone_result := _build_zone(p_root, zone, region_id)
			zone_count += 1
			prop_count += int(zone_result.get("props", 0))
			decor_count += int(zone_result.get("decor", 0))
		else:
			if str(zone.get("type", "")) == "rest":
				continue
			_build_route_marker(p_root, zone, region_id)

	var rest_count := 0
	for rest in p_region.get("rest_points", []):
		var rest_marker: Dictionary = rest.duplicate(true)
		rest_marker["id"] = "rest_%d" % rest_count
		rest_marker["type"] = "rest"
		_build_route_marker(p_root, rest_marker, region_id)
		rest_count += 1

	for gate in p_region.get("ability_gates", []):
		if not (gate.has("x") and gate.has("z")):
			continue
		var gate_node := EnvFactory.interactive_door(
			p_root,
			Vector3(float(gate.get("x", 0.0)), 0.0, float(gate.get("z", 0.0))),
			Vector3(0.5, 3.2, 2.0),
			Color("#6a4352")
		)
		_tag(gate_node, Schema.make(
			str(gate.get("id", "gate")),
			"gate",
			"gate",
			"",
			["authored"],
			[str(gate.get("unlocks_zone", ""))],
			{
				"required_ability": str(gate.get("required_ability", "")),
				"required_boss": str(gate.get("required_boss", "")),
				"required_quest": str(gate.get("required_quest", "")),
				"kind": str(gate.get("kind", "")),
				"prompt": str(gate.get("prompt", "")),
			}
		))
		gate_count += 1

	return {
		"region_id": region_id,
		"zones": zone_count,
		"props": prop_count,
		"decor": decor_count,
		"gates": gate_count,
		"rest": rest_count,
	}


static func load_and_build(p_root: Node3D, p_region_path: String = RouteData.DEFAULT_REGION) -> Dictionary:
	var region := RouteData.load_region(p_region_path)
	if region.is_empty():
		return {"error": "无法加载区域 JSON：%s" % p_region_path}
	return build(p_root, region, str(region.get("region_id", "")))


static func _build_route_frame(p_root: Node3D) -> void:
	var floor_body := StaticBody3D.new()
	p_root.add_child(floor_body)
	floor_body.position = Vector3(0.0, -0.5, 0.0)
	var floor_collision := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(40.0, 1.0, 16.0)
	floor_collision.shape = floor_shape
	floor_body.add_child(floor_collision)
	floor_body.add_child(PlaceholderKit.box("art_key_route_floor", Color("#39475d"), Vector3(40.0, 1.0, 16.0)))
	_tag(floor_body, Schema.make(
		"route_floor",
		"floor",
		"none",
		"",
		["authored", "route"],
		[],
		{"size": [40.0, 1.0, 16.0]}
	))

	var boundaries := [
		["route_wall_north", Vector3(40.0, 2.6, 0.6), Vector3(0.0, 1.3, -8.5)],
		["route_wall_south", Vector3(40.0, 2.6, 0.6), Vector3(0.0, 1.3, 8.5)],
		["route_wall_west", Vector3(0.6, 2.6, 18.0), Vector3(-20.5, 1.3, 0.0)],
		["route_wall_east", Vector3(0.6, 2.6, 18.0), Vector3(20.5, 1.3, 0.0)],
	]
	for boundary in boundaries:
		var body := StaticBody3D.new()
		p_root.add_child(body)
		body.position = boundary[2]
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = boundary[1]
		collision.shape = shape
		body.add_child(collision)
		body.add_child(PlaceholderKit.box("art_key_%s" % str(boundary[0]), Color("#435065"), boundary[1]))
		_tag(body, Schema.make(
			str(boundary[0]),
			"prop",
			"none",
			"",
			["authored", "route", "boundary"],
			[],
			{"size": boundary[1]}
		))

	var start_pad := PlaceholderKit.box("art_key_route_start", Color("#b58b4a"), Vector3(2.0, 0.08, 3.4))
	start_pad.position = Vector3(-13.8, 0.04, 0.0)
	p_root.add_child(start_pad)

	var spawn := Node3D.new()
	spawn.position = Vector3(-14.6, 0.9, 0.0)
	p_root.add_child(spawn)
	var spawn_visual := PlaceholderKit.box("AuthoringMarker", Color("#f2d77a"), Vector3(0.8, 0.08, 0.8))
	spawn_visual.position.y = 0.04 - spawn.position.y
	spawn.add_child(spawn_visual)
	_tag(spawn, Schema.make(
		"spawn",
		"spawn",
		"spawn",
		"",
		["authored", "route"],
		[],
		{}
	))


static func _build_route_gates(p_root: Node3D) -> void:
	var route_gates := [
		["route_gate_0", 0, -4.0],
		["route_gate_1", 1, 4.0],
	]
	for route_gate in route_gates:
		var body := StaticBody3D.new()
		p_root.add_child(body)
		body.position = Vector3(float(route_gate[2]), 1.5, 0.0)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.28, 3.0, 16.4)
		collision.shape = shape
		body.add_child(collision)
		body.add_child(PlaceholderKit.box("art_key_route_gate", Color("#6d7a90"), Vector3(0.28, 3.0, 16.4)))
		_tag(body, Schema.make(
			str(route_gate[0]),
			"route_gate",
			"route_gate",
			"",
			["authored", "route"],
			[],
			{"index": int(route_gate[1])}
		))


static func _build_zone(p_root: Node3D, p_zone: Dictionary, p_region_id: String) -> Dictionary:
	var zone_id := str(p_zone.get("id", "zone"))
	var center := Vector3(float(p_zone.get("x", 0.0)), 0.0, float(p_zone.get("z", 0.0)))
	var host := Node3D.new()
	host.position = center
	p_root.add_child(host)
	_tag(host, Schema.make(
		zone_id,
		"zone",
		"none",
		zone_id,
		["authored"],
		[],
		{
			"name": str(p_zone.get("name", zone_id)),
			"min_x": float(p_zone.get("min_x", 0.0)),
			"max_x": float(p_zone.get("max_x", 0.0)),
			"depth": float(p_zone.get("depth", 16.0)),
		}
	))

	var floor_color := Color("#45546d")
	if p_zone.has("floor_color"):
		floor_color = Color(str(p_zone.get("floor_color")))
	var floor := EnvFactory.zone_floor(
		host,
		Vector3(0.0, 0.02, 0.0),
		Vector3(float(p_zone.get("span", 4.0)) * 2.0, 0.04, float(p_zone.get("depth", 16.0))),
		floor_color
	)
	_tag(floor, Schema.make(
		"%s_floor" % zone_id,
		"floor",
		"none",
		zone_id,
		["authored"],
		[],
		{"color": floor_color.to_html(false)}
	))

	var banner := Label3D.new()
	banner.text = str(p_zone.get("name", zone_id))
	banner.position = Vector3(0.0, 2.6, -6.5)
	banner.modulate = Color("#ffe9a8")
	banner.outline_modulate = Color("#141a26")
	banner.font_size = 72
	banner.pixel_size = 0.01
	banner.outline_size = 24
	host.add_child(banner)

	var prop_count := 0
	var prop_index := 0
	for prop in p_zone.get("props", []):
		var world_position := Vector3(float(prop.get("x", center.x)), 0.0, float(prop.get("z", center.z)))
		var prop_id := str(prop.get("id", "%s_prop_%d" % [zone_id, prop_index]))
		_build_prop(host, world_position - center, prop, prop_id, zone_id)
		prop_count += 1
		prop_index += 1

	var decor_count := 0
	var decor_index := 0
	for decor in p_zone.get("decor", []):
		var world_position := Vector3(float(decor.get("x", center.x)), 0.0, float(decor.get("z", center.z)))
		var decor_id := str(decor.get("id", "%s_decor_%d" % [zone_id, decor_index]))
		_build_decor(host, world_position - center, decor, decor_id, zone_id)
		decor_count += 1
		decor_index += 1

	return {"props": prop_count, "decor": decor_count}


static func _build_prop(
	p_parent: Node3D,
	p_local_position: Vector3,
	p_prop: Dictionary,
	p_id: String,
	p_zone_id: String
) -> void:
	var prop_type := str(p_prop.get("type", "platform"))
	var node: Node3D
	match prop_type:
		"platform":
			node = EnvFactory.platform(
				p_parent,
				p_local_position,
				Vector3(float(p_prop.get("sx", 3.0)), float(p_prop.get("sy", 0.4)), float(p_prop.get("sz", 2.0))),
				_color(p_prop, "#8b96a8")
			)
		"pillar":
			node = EnvFactory.pillar(
				p_parent,
				p_local_position,
				float(p_prop.get("r", 0.5)),
				float(p_prop.get("h", 4.0)),
				_color(p_prop, "#7c8a9a")
			)
		"breakable":
			node = _build_breakable(p_parent, p_local_position)
		"pressure":
			node = EnvFactory.pressure_plate(
				p_parent,
				p_local_position,
				float(p_prop.get("size", 1.4)),
				_color(p_prop, "#c9b45a")
			)
		"box":
			node = EnvFactory.pushable_box(
				p_parent,
				p_local_position,
				float(p_prop.get("size", 1.0)),
				_color(p_prop, "#7f6e50")
			)
		"lift":
			node = _build_plain_lift(p_parent, p_local_position)
		"lamp":
			node = EnvFactory.lamp(
				p_parent,
				p_local_position,
				float(p_prop.get("r", 0.65)),
				_color(p_prop, "#ffd98a")
			)
		_:
			node = EnvFactory.platform(
				p_parent,
				p_local_position,
				Vector3(float(p_prop.get("sx", 1.2)), float(p_prop.get("sy", 0.4)), float(p_prop.get("sz", 1.2))),
				_color(p_prop, "#8b96a8")
			)
	var semantic := _classify_prop(prop_type, p_prop, p_id, p_zone_id)
	_tag(node, semantic)


static func _build_decor(
	p_parent: Node3D,
	p_local_position: Vector3,
	p_decor: Dictionary,
	p_id: String,
	p_zone_id: String
) -> void:
	var decor_type := str(p_decor.get("type", "plant"))
	var node: Node3D
	match decor_type:
		"plant":
			node = EnvFactory.plant(p_parent, p_local_position, float(p_decor.get("scale", 1.0)))
		"waterfall":
			node = EnvFactory.waterfall(
				p_parent,
				p_local_position,
				float(p_decor.get("w", 3.0)),
				float(p_decor.get("h", 7.0))
			)
		"lamp":
			node = EnvFactory.lamp(
				p_parent,
				p_local_position,
				float(p_decor.get("r", 0.65)),
				_color(p_decor, "#ffd98a")
			)
		"window":
			node = EnvFactory.window(
				p_parent,
				p_local_position,
				float(p_decor.get("w", 1.0)),
				float(p_decor.get("h", 1.6)),
				_color(p_decor, "#9fd8ff")
			)
		"plaque":
			node = EnvFactory.plaque(p_parent, p_local_position, _color(p_decor, "#b58b4a"))
		"spirit_fire":
			node = EnvFactory.spirit_fire(
				p_parent,
				p_local_position,
				float(p_decor.get("scale", 1.0)),
				_color(p_decor, "#7ad7cf")
			)
		"mist":
			node = EnvFactory.mist_zone(
				p_parent,
				p_local_position,
				Vector2(float(p_decor.get("sw", 5.0)), float(p_decor.get("sd", 3.0))),
				_color(p_decor, "#9fb8cf")
			)
		"pillar":
			node = EnvFactory.pillar(
				p_parent,
				p_local_position,
				float(p_decor.get("r", 0.45)),
				float(p_decor.get("h", 3.5)),
				_color(p_decor, "#7c8a9a")
			)
		_:
			node = EnvFactory.plant(p_parent, p_local_position)
	_tag(node, Schema.make(
		p_id,
		"decor",
		"none",
		p_zone_id,
		["authored", decor_type],
		[],
		p_decor.duplicate(true)
	))


static func _build_breakable(p_parent: Node3D, p_local_position: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	p_parent.add_child(body)
	body.position = p_local_position
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.55
	collision.shape = sphere
	collision.position.y = 0.55
	body.add_child(collision)
	var mesh := PlaceholderKit.box("AuthoringJarBody", Color("#b08d5f"), Vector3(0.62, 0.78, 0.62))
	mesh.position.y = 0.42
	body.add_child(mesh)
	var rim := PlaceholderKit.box("AuthoringJarRim", Color("#c9a05e"), Vector3(0.42, 0.26, 0.42))
	rim.position.y = 0.96
	body.add_child(rim)
	return body


static func _build_route_marker(p_root: Node3D, p_marker: Dictionary, p_region_id: String) -> void:
	var marker_type := str(p_marker.get("type", "path"))
	var host := Node3D.new()
	host.position = Vector3(
		float(p_marker.get("x", 0.0)),
		float(p_marker.get("y", 0.0)),
		float(p_marker.get("z", 0.0))
	)
	p_root.add_child(host)
	var color := Color("#57d4a5")
	var kind := "nav"
	var behavior := "none"
	var marker_size := Vector3(1.2, 0.12, 1.2)
	var marker_height := 0.06
	match marker_type:
		"rest":
			color = Color("#57d4a5")
			kind = "rest"
			behavior = "rest"
			marker_size = Vector3(1.2, 0.07, 1.2)
			marker_height = 0.04
		"case":
			color = Color("#ffd166")
			kind = "case"
			behavior = "case"
			marker_size = Vector3(4.4, 0.1, 4.6)
			marker_height = 0.05
		"boss":
			color = Color("#ef5b5b")
			kind = "boss"
			behavior = "boss"
		"objective":
			color = Color("#f4c95d")
			kind = "objective"
			behavior = "objective"
			marker_size = Vector3(1.2, 4.0, 1.2)
			marker_height = 2.0
		"path":
			color = Color("#7ad7cf")
			kind = "nav"
			behavior = "trigger"
	var marker := PlaceholderKit.box("AuthoringMarker", color, marker_size)
	marker.position.y = marker_height - host.position.y
	host.add_child(marker)
	_tag(host, Schema.make(
		str(p_marker.get("id", "%s_%s" % [marker_type, p_region_id])),
		kind,
		behavior,
		p_region_id,
		["authored", marker_type],
		[],
		p_marker.duplicate(true)
	))


static func _build_plain_lift(p_parent: Node3D, p_local_position: Vector3) -> AnimatableBody3D:
	var lift := AnimatableBody3D.new()
	p_parent.add_child(lift)
	lift.position = p_local_position
	var size := Vector3(2.4, 0.3, 2.0)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position.y = size.y * 0.5
	lift.add_child(collision)
	var mesh := PlaceholderKit.box("art_key_v2_lift_platform", Color("#3f6d8c"), size)
	mesh.position.y = size.y * 0.5
	lift.add_child(mesh)
	return lift


static func _classify_prop(
	p_type: String,
	p_prop: Dictionary,
	p_id: String,
	p_zone_id: String
) -> Dictionary:
	match p_type:
		"breakable":
			return Schema.make(p_id, "breakable", "breakable", p_zone_id, ["authored", p_type], [], p_prop.duplicate(true))
		"pressure":
			return Schema.make(p_id, "trigger", "pressure_plate", p_zone_id, ["authored", p_type], [], p_prop.duplicate(true))
		"box":
			return Schema.make(p_id, "prop", "pushable", p_zone_id, ["authored", p_type], [], p_prop.duplicate(true))
		"lift":
			return Schema.make(p_id, "prop", "lift", p_zone_id, ["authored", p_type], [], p_prop.duplicate(true))
		"lamp":
			return Schema.make(p_id, "decor", "none", p_zone_id, ["authored", p_type], [], p_prop.duplicate(true))
	return Schema.make(p_id, "prop", "none", p_zone_id, ["authored", p_type], [], p_prop.duplicate(true))


static func _tag(p_node: Node3D, p_data: Dictionary) -> void:
	Schema.apply_to_node(p_node, p_data)
	p_node.name = Schema.node_name(p_data)
	p_node.add_to_group("fs.region_generated")


static func _color(p_data: Dictionary, p_default: String) -> Color:
	if p_data.has("color"):
		return Color(str(p_data.get("color")))
	return Color(p_default)
