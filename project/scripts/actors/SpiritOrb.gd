class_name SpiritOrb
extends Node3D

const SPEED := 8.5
const LIFETIME := 2.2

@export var art_scale := 1.0
var direction := Vector3.FORWARD
var _lifetime := LIFETIME
var _hit_done := false


func _ready() -> void:
	add_to_group("spirit_orbs")
	var mesh := MeshInstance3D.new()
	mesh.name = "art_key_ghost_shot_orb"
	mesh.mesh = PlaceholderKit.sphere_mesh(0.5, 1.0)
	mesh.material_override = PlaceholderKit.emissive_material(Color("#b7e7ff"), 2.2)
	add_child(mesh)

	var glow := MeshInstance3D.new()
	glow.name = "art_key_ghost_shot_glow"
	glow.mesh = PlaceholderKit.sphere_mesh(0.18, 0.36)
	glow.material_override = PlaceholderKit.emissive_material(Color("#eaffff"), 2.5)
	add_child(glow)


func launch(p_direction: Vector3) -> void:
	direction = p_direction.normalized()


func _physics_process(delta: float) -> void:
	_lifetime -= delta
	global_position += direction * SPEED * delta
	if _lifetime <= 0.0:
		queue_free()
		return
	var player := get_tree().get_first_node_in_group("player")
	if player and not _hit_done and global_position.distance_to(player.global_position) < 1.1:
		_hit_done = true
		if player.has_method("take_hit"):
			player.take_hit(self)
		queue_free()
