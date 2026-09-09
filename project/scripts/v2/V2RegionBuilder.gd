class_name V2RegionBuilder
extends RefCounted

const RouteData := preload("res://scripts/v2/V2RouteData.gd")
const EnvFactory := preload("res://scripts/v2/V2EnvFactory.gd")
const GateScript := preload("res://scripts/v2/V2AbilityGate.gd")
const BreakableScript := preload("res://scripts/v2/V2Breakable.gd")


# 按 Region JSON 生成区域世界（环境层），并把“改 JSON -> 跑地图”落地。
# 返回句柄字典：{ "zones": {id: Node3D}, "gates": {id: V2AbilityGate}, "props": int, "decor": int, "floors": int }
static func build(p_parent: Node, p_region: Dictionary) -> Dictionary:
	var zones := {}
	var gates := {}
	var prop_count := 0
	var decor_count := 0
	var floor_count := 0

	for zone in p_region.get("zones", []):
		if not (zone.has("min_x") and zone.has("max_x")):
			continue
		var zone_host := _build_zone(p_parent, zone)
		zones[zone.get("id", "")] = zone_host
		floor_count += 1
		for prop in zone.get("props", []):
			_spawn_prop(p_parent, zone, prop)
			prop_count += 1
		for decor in zone.get("decor", []):
			_spawn_decor(p_parent, decor)
			decor_count += 1

	for gate in p_region.get("ability_gates", []):
		# 只有带世界坐标的门才会生成实体；逻辑门（仅 required_ability/required_quest）不落世界，避免在走廊原点叠一堵墙。
		if not (gate.has("x") and gate.has("z")):
			continue
		var node: Node = _build_gate(p_parent, gate)
		if node:
			gates[gate.get("id", "")] = node

	return {
		"zones": zones,
		"gates": gates,
		"props": prop_count,
		"decor": decor_count,
		"floors": floor_count,
	}


static func zone_id_at_x(p_region: Dictionary, p_x: float) -> String:
	var fallback := ""
	for zone in p_region.get("zones", []):
		if not (zone.has("min_x") and zone.has("max_x")):
			continue
		var min_x := float(zone.get("min_x"))
		var max_x := float(zone.get("max_x"))
		if p_x >= min_x and p_x <= max_x:
			return zone.get("id", "")
		if fallback.is_empty():
			fallback = zone.get("id", "")
	return fallback


static func zone_by_id(p_region: Dictionary, p_zone_id: String) -> Dictionary:
	for zone in p_region.get("zones", []):
		if zone.get("id", "") == p_zone_id:
			return zone
	return {}


static func _build_zone(p_parent: Node, p_zone: Dictionary) -> Node3D:
	var host := Node3D.new()
	host.name = "Zone_%s" % str(p_zone.get("id", "zone"))
	p_parent.add_child(host)
	var center := Vector3(float(p_zone.get("x", 0.0)), 0.0, float(p_zone.get("z", 0.0)))
	var span := float(p_zone.get("span", 4.0))
	var depth := float(p_zone.get("depth", 16.0))
	var floor_color: Color = Color("#45546d")
	if p_zone.has("floor_color"):
		floor_color = Color(str(p_zone.get("floor_color")))
	# zone_floor 内部已经 add_child 到 host，这里不要再包一层 add_child，否则会报“已有父节点”。
	EnvFactory.zone_floor(host, center + Vector3(0.0, 0.02, 0.0), Vector3(span * 2.0, 0.04, depth), floor_color)

	var banner := Label3D.new()
	banner.name = "ZoneBanner"
	banner.text = str(p_zone.get("name", p_zone.get("id", "")))
	banner.position = center + Vector3(0.0, 2.6, -6.5)
	banner.modulate = Color("#ffe9a8")
	banner.outline_modulate = Color("#141a26")
	banner.font_size = 72
	banner.pixel_size = 0.01
	banner.outline_size = 24
	host.add_child(banner)
	return host


static func _spawn_prop(p_parent: Node, p_zone: Dictionary, p_prop: Dictionary) -> void:
	var kind := str(p_prop.get("type", "pillar"))
	var pos := Vector3(float(p_prop.get("x", p_zone.get("x", 0.0))), 0.0, float(p_prop.get("z", 0.0)))
	match kind:
		"platform":
			EnvFactory.platform(p_parent, pos, Vector3(float(p_prop.get("sx", 3.0)), float(p_prop.get("sy", 0.4)), float(p_prop.get("sz", 2.0))), _color(p_prop, "#8b96a8"))
		"pillar":
			EnvFactory.pillar(p_parent, pos, float(p_prop.get("r", 0.5)), float(p_prop.get("h", 4.0)), _color(p_prop, "#7c8a9a"))
		"plant":
			EnvFactory.plant(p_parent, pos, float(p_prop.get("scale", 1.0)))
		"waterfall":
			EnvFactory.waterfall(p_parent, pos, float(p_prop.get("w", 3.0)), float(p_prop.get("h", 7.0)))
		"lamp":
			EnvFactory.lamp(p_parent, pos, float(p_prop.get("r", 0.65)), _color(p_prop, "#ffd98a"))
		"window":
			EnvFactory.window(p_parent, pos, float(p_prop.get("w", 1.0)), float(p_prop.get("h", 1.6)), _color(p_prop, "#9fd8ff"))
		"plaque":
			EnvFactory.plaque(p_parent, pos, _color(p_prop, "#b58b4a"))
		"spirit_fire":
			EnvFactory.spirit_fire(p_parent, pos, float(p_prop.get("scale", 1.0)), _color(p_prop, "#7ad7cf"))
		"mist":
			EnvFactory.mist_zone(p_parent, pos, Vector2(float(p_prop.get("sw", 5.0)), float(p_prop.get("sd", 3.0))), _color(p_prop, "#9fb8cf"))
		"breakable":
			var jar: StaticBody3D = BreakableScript.new()
			jar.set("breakable_id", str(p_prop.get("id", "jar")))
			p_parent.add_child(jar)
			jar.position = pos
		"pressure":
			EnvFactory.pressure_plate(p_parent, pos, float(p_prop.get("size", 1.4)), _color(p_prop, "#c9b45a"))
		"box":
			EnvFactory.pushable_box(p_parent, pos, float(p_prop.get("size", 1.0)), _color(p_prop, "#7f6e50"))
		"lift":
			EnvFactory.lift_platform(p_parent, pos, float(p_prop.get("lift", 2.0)), float(p_prop.get("dur", 2.4)))


static func _spawn_decor(p_parent: Node, p_decor: Dictionary) -> void:
	_spawn_prop(p_parent, {"x": p_decor.get("x", 0.0), "z": p_decor.get("z", 0.0)}, p_decor)


static func _build_gate(p_parent: Node, p_gate: Dictionary) -> Node:
	var pos := Vector3(float(p_gate.get("x", 0.0)), 0.0, float(p_gate.get("z", 0.0)))
	var gate: StaticBody3D = GateScript.new()
	gate.set("gate_id", p_gate.get("id", ""))
	gate.set("required_ability", p_gate.get("required_ability", ""))
	gate.set("required_boss", p_gate.get("required_boss", ""))
	gate.set("required_quest", p_gate.get("required_quest", ""))
	gate.set("kind", p_gate.get("kind", ""))
	gate.set("prompt", p_gate.get("prompt", ""))
	p_parent.add_child(gate)
	gate.position = pos
	return gate


static func _color(p_data: Dictionary, p_default: String) -> Color:
	if p_data.has("color"):
		return Color(str(p_data.get("color")))
	return Color(p_default)
