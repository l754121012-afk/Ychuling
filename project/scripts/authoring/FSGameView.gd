class_name FSGameView
extends RefCounted

const CAMERA_HEIGHT := 10.5
const CAMERA_BACK := 5.0
const LOOK_HEIGHT := 1.0
const CAMERA_FOV := 52.0
const FOCUS_FOV := 55.0
const FOCUS_YAW_DEGREES := 38.0
const FOCUS_ELEVATION_DEGREES := 36.0
const FOCUS_MARGIN := 1.18
const FOCUS_MIN_DISTANCE := 2.2
const FOCUS_MAX_DISTANCE := 180.0
const FOCUS_MIN_RADIUS_DISTANCE_FACTOR := 0.35
const FOCUS_MAX_RADIUS_DISTANCE_FACTOR := 25.0
const FOCUS_MIN_RADIUS_DISTANCE := 0.15
const FOCUS_MIN_RADIUS_MAX_DISTANCE := 2.0
const FOCUS_WHEEL_ZOOM_FACTOR := 0.9
const FOCUS_ORBIT_DEGREES_PER_PIXEL := 0.16
const FOCUS_MIN_ELEVATION_DEGREES := -80.0
const FOCUS_MAX_ELEVATION_DEGREES := 80.0


static func camera_position_for_focus(p_focus: Vector3) -> Vector3:
	return p_focus + Vector3(0.0, CAMERA_HEIGHT, CAMERA_BACK)


static func look_target_for_focus(p_focus: Vector3) -> Vector3:
	return p_focus + Vector3(0.0, LOOK_HEIGHT, 0.0)


static func camera_transform_for_focus(p_focus: Vector3) -> Transform3D:
	var transform := Transform3D.IDENTITY
	transform.origin = camera_position_for_focus(p_focus)
	return transform.looking_at(look_target_for_focus(p_focus), Vector3.UP)


static func apply_to_camera(p_camera: Camera3D, p_focus: Vector3) -> void:
	p_camera.fov = CAMERA_FOV
	p_camera.global_transform = camera_transform_for_focus(p_focus)


static func combined_world_aabb(p_nodes: Array) -> Dictionary:
	var found := false
	var combined := AABB()
	for node in p_nodes:
		if not (node is Node3D):
			continue
		var node_result := world_aabb_for_node(node as Node3D)
		if not bool(node_result.get("found", false)):
			continue
		var node_aabb: AABB = node_result["aabb"]
		combined = node_aabb if not found else combined.merge(node_aabb)
		found = true
	if found:
		return {"found": true, "aabb": combined}
	if p_nodes.size() == 1 and p_nodes[0] is Node3D:
		var node := p_nodes[0] as Node3D
		var center := node.global_transform.origin
		return {
			"found": true,
			"aabb": AABB(
				center - Vector3(0.6, 0.6, 0.6),
				Vector3(1.2, 1.2, 1.2)
			),
			"fallback": true,
		}
	return {"found": false}


static func world_aabb_for_node(p_node: Node3D) -> Dictionary:
	return _collect_visual_aabb(p_node, AABB(), false)


static func focus_pose_for_aabb(p_aabb: AABB, p_aspect: float = 1.7777778) -> Dictionary:
	var center := p_aabb.get_center()
	var size := p_aabb.size
	var radius := maxf(size.length() * 0.5, 0.35)
	var yaw := deg_to_rad(FOCUS_YAW_DEGREES)
	var elevation := deg_to_rad(FOCUS_ELEVATION_DEGREES)
	var camera_direction := Vector3(
		cos(yaw) * cos(elevation),
		sin(elevation),
		sin(yaw) * cos(elevation)
	).normalized()
	var provisional := _looking_transform(
		center + camera_direction * maxf(radius * 2.0, 1.0),
		center
	)
	var camera_right := provisional.basis.x.normalized()
	var camera_up := provisional.basis.y.normalized()
	var vertical_half_fov := tan(deg_to_rad(FOCUS_FOV * 0.5))
	var horizontal_half_fov := vertical_half_fov * maxf(p_aspect, 0.15)
	var distance := FOCUS_MIN_DISTANCE
	for index in range(8):
		var offset := Vector3(
			size.x if (index & 1) != 0 else 0.0,
			size.y if (index & 2) != 0 else 0.0,
			size.z if (index & 4) != 0 else 0.0
		)
		var relative := (p_aabb.position + offset) - center
		var depth_offset := relative.dot(camera_direction)
		distance = maxf(
			distance,
			absf(relative.dot(camera_up)) / vertical_half_fov + depth_offset
		)
		distance = maxf(
			distance,
			absf(relative.dot(camera_right)) / horizontal_half_fov + depth_offset
		)
	distance = clampf(
		distance * FOCUS_MARGIN,
		FOCUS_MIN_DISTANCE,
		FOCUS_MAX_DISTANCE
	)
	var camera_position := center + camera_direction * distance
	return {
		"transform": _looking_transform(camera_position, center),
		"center": center,
		"distance": distance,
		"radius": radius,
		"size": size,
		"yaw_degrees": FOCUS_YAW_DEGREES,
		"elevation_degrees": FOCUS_ELEVATION_DEGREES,
	}


static func focus_zoom_limits(p_radius: float) -> Dictionary:
	var radius := maxf(p_radius, 0.01)
	return {
		"min": maxf(
			FOCUS_MIN_RADIUS_DISTANCE,
			radius * FOCUS_MIN_RADIUS_DISTANCE_FACTOR
		),
		"max": maxf(
			FOCUS_MIN_RADIUS_MAX_DISTANCE,
			radius * FOCUS_MAX_RADIUS_DISTANCE_FACTOR
		),
	}


static func focus_camera_transform(
	p_center: Vector3,
	p_yaw_degrees: float,
	p_elevation_degrees: float,
	p_distance: float
) -> Transform3D:
	var yaw := deg_to_rad(p_yaw_degrees)
	var elevation := deg_to_rad(clampf(
		p_elevation_degrees,
		FOCUS_MIN_ELEVATION_DEGREES,
		FOCUS_MAX_ELEVATION_DEGREES
	))
	var camera_direction := Vector3(
		cos(yaw) * cos(elevation),
		sin(elevation),
		sin(yaw) * cos(elevation)
	).normalized()
	return _looking_transform(
		p_center + camera_direction * maxf(p_distance, 0.001),
		p_center
	)


static func focus_orbit_step(p_relative: Vector2) -> Dictionary:
	return {
		"yaw_delta": -p_relative.x * FOCUS_ORBIT_DEGREES_PER_PIXEL,
		"elevation_delta": p_relative.y * FOCUS_ORBIT_DEGREES_PER_PIXEL,
	}


static func focus_zoom_step(p_distance: float, p_radius: float, p_wheel_factor: float) -> float:
	var limits := focus_zoom_limits(p_radius)
	var target := p_distance
	if p_wheel_factor < 0.0:
		target = p_distance / FOCUS_WHEEL_ZOOM_FACTOR
	elif p_wheel_factor > 0.0:
		target = p_distance * FOCUS_WHEEL_ZOOM_FACTOR
	return clampf(target, float(limits["min"]), float(limits["max"]))


static func _collect_visual_aabb(
	p_node: Node,
	p_aabb: AABB,
	p_found: bool
) -> Dictionary:
	var found := p_found
	var combined := p_aabb
	if p_node is VisualInstance3D:
		var visual := p_node as VisualInstance3D
		if visual.is_visible_in_tree():
			var local_aabb := visual.get_aabb()
			if local_aabb.size.length_squared() > 0.000001:
				var world_aabb := transform_aabb(local_aabb, visual.global_transform)
				combined = world_aabb if not found else combined.merge(world_aabb)
				found = true
	for child in p_node.get_children():
		var child_result := _collect_visual_aabb(child, combined, found)
		combined = child_result["aabb"]
		found = bool(child_result["found"])
	return {"found": found, "aabb": combined}


static func transform_aabb(p_aabb: AABB, p_transform: Transform3D) -> AABB:
	var transformed := AABB(p_transform * p_aabb.position, Vector3.ZERO)
	for index in range(8):
		var offset := Vector3(
			p_aabb.size.x if (index & 1) != 0 else 0.0,
			p_aabb.size.y if (index & 2) != 0 else 0.0,
			p_aabb.size.z if (index & 4) != 0 else 0.0
		)
		transformed = transformed.expand(p_transform * (p_aabb.position + offset))
	return transformed


static func _looking_transform(p_origin: Vector3, p_target: Vector3) -> Transform3D:
	var transform := Transform3D.IDENTITY
	transform.origin = p_origin
	return transform.looking_at(p_target, Vector3.UP)
