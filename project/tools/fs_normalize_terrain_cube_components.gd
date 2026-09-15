extends SceneTree

const SCENE_PATH := "res://authoring/scenes/spirit_sprawl_geometry.tscn"
const TERRAIN_GROUP_NAME := "FS_GROUP_地形"
const LAND_PREFIXES := [
	"FLOOR",
	"BLOCK",
	"PLATFORM_DECK",
	"DECK",
	"STAIR_STEP",
]

var _cube_by_material: Dictionary = {}
var _unit_shape: BoxShape3D
var _converted_meshes := 0
var _converted_collisions := 0
var _skipped_visuals := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := ResourceLoader.load(SCENE_PATH) as PackedScene
	if packed == null:
		push_error("无法加载场景：%s" % SCENE_PATH)
		quit(1)
		return
	var scene := packed.instantiate()
	if scene == null:
		push_error("场景实例化失败。")
		quit(1)
		return
	root.add_child(scene)

	var terrain := scene.get_node_or_null(TERRAIN_GROUP_NAME)
	if terrain == null:
		push_error("场景缺少分组：%s" % TERRAIN_GROUP_NAME)
		quit(1)
		return

	_unit_shape = BoxShape3D.new()
	_unit_shape.size = Vector3.ONE
	_normalize_terrain(terrain, terrain)

	var repacked := PackedScene.new()
	var pack_error := repacked.pack(scene)
	if pack_error != OK:
		push_error("场景打包失败：%s" % error_string(pack_error))
		quit(1)
		return
	var save_error := ResourceSaver.save(repacked, SCENE_PATH)
	if save_error != OK:
		push_error("场景保存失败：%s" % error_string(save_error))
		quit(1)
		return

	print(
		"FS_NORMALIZE_TERRAIN_CUBES meshes=%d collisions=%d skipped=%d cube_resources=%d errors=0" % [
			_converted_meshes,
			_converted_collisions,
			_skipped_visuals,
			_cube_by_material.size(),
		]
	)
	quit(0)


func _normalize_terrain(
	p_node: Node,
	p_terrain_root: Node
) -> void:
	for child in p_node.get_children():
		if child is MeshInstance3D:
			var mesh_instance := child as MeshInstance3D
			if _is_land_component(mesh_instance, p_terrain_root):
				var old_mesh := mesh_instance.mesh
				if old_mesh is BoxMesh:
					var old_box := old_mesh as BoxMesh
					var size := old_box.size
					var material := old_box.material
					var old_scale := mesh_instance.scale
					mesh_instance.mesh = _cube_for_material(material)
					mesh_instance.scale = Vector3(
						old_scale.x * size.x,
						old_scale.y * size.y,
						old_scale.z * size.z
					)
					_converted_meshes += 1
					if _normalize_sibling_collision(mesh_instance):
						_converted_collisions += 1
			elif mesh_instance.mesh is BoxMesh:
				_skipped_visuals += 1
		_normalize_terrain(child, p_terrain_root)


func _is_land_component(p_node: MeshInstance3D, p_terrain_root: Node) -> bool:
	if not p_node.mesh is BoxMesh:
		return false
	var upper_name := str(p_node.name).to_upper()
	var is_land_name := false
	for prefix in LAND_PREFIXES:
		if upper_name.begins_with(prefix):
			is_land_name = true
			break
	if not is_land_name:
		return false

	var parent := p_node.get_parent()
	while parent != null and parent != p_terrain_root:
		var parent_name := str(parent.name).to_upper()
		if parent_name.contains("CANAL_WATER") or parent_name.contains("WALL_WORLD"):
			return false
		parent = parent.get_parent()
	return true


func _cube_for_material(p_material: Material) -> BoxMesh:
	var key := 0
	if p_material != null:
		key = int(p_material.get_instance_id())
	if _cube_by_material.has(key):
		return _cube_by_material[key] as BoxMesh
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE
	cube.material = p_material
	_cube_by_material[key] = cube
	return cube


func _normalize_sibling_collision(p_mesh_instance: MeshInstance3D) -> bool:
	var collision_name := "%s_COLLISION" % str(p_mesh_instance.name)
	var collision := p_mesh_instance.get_parent().get_node_or_null(
		NodePath(collision_name)
	) as CollisionShape3D
	if collision == null or not collision.shape is BoxShape3D:
		return false
	var old_shape := collision.shape as BoxShape3D
	var old_scale := collision.scale
	collision.shape = _unit_shape
	collision.scale = Vector3(
		old_scale.x * old_shape.size.x,
		old_scale.y * old_shape.size.y,
		old_scale.z * old_shape.size.z
	)
	return true
