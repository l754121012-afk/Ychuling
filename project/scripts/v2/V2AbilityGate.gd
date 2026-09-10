class_name V2AbilityGate
extends StaticBody3D

signal opened(gate_id: String)

@export var gate_id := ""
@export var required_ability := ""
@export var required_boss := ""
@export var required_quest := ""
@export var kind := "" # "e" | "ability" | "boss" | "quest"
@export var prompt := ""

var quest_flags: Dictionary = {}

var _opened := false
var _collision_built := false
var _visual_built := false


func _ready() -> void:
	runtime_initialize()


func runtime_initialize() -> void:
	if not _collision_built:
		_build_collision()
		_collision_built = true
	if not _visual_built:
		_build_visual()
		_visual_built = true


func can_open(p_abilities: Dictionary, p_boss_defeated: bool) -> bool:
	if _opened:
		return true
	if not required_ability.is_empty() and not p_abilities.has(required_ability):
		return false
	if not required_boss.is_empty() and not p_boss_defeated:
		return false
	if not required_quest.is_empty() and not quest_flags.has(required_quest):
		return false
	return true


func can_interact(p_abilities: Dictionary, p_boss_defeated: bool, p_quest_flags: Dictionary = {}) -> bool:
	if not p_quest_flags.is_empty():
		quest_flags = p_quest_flags
	return can_open(p_abilities, p_boss_defeated)


func try_open(p_abilities: Dictionary, p_boss_defeated: bool) -> bool:
	if not can_open(p_abilities, p_boss_defeated):
		return false
	_open_now()
	return true


func attempt_open(p_abilities: Dictionary, p_boss_defeated: bool, p_quest_flags: Dictionary = {}) -> bool:
	if not can_interact(p_abilities, p_boss_defeated, p_quest_flags):
		return false
	_open_now()
	return true


func is_open() -> bool:
	return _opened


func _open_now() -> void:
	_opened = true
	collision_layer = 0
	collision_mask = 0
	for child in get_children():
		if child is MeshInstance3D:
			child.visible = false
	opened.emit(gate_id)


func _build_collision() -> void:
	if _has_direct_child_of_type(CollisionShape3D):
		return
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.5, 3.2, 2.0)
	var collision := CollisionShape3D.new()
	collision.name = "GateCollision"
	collision.shape = shape
	collision.position.y = 1.6
	add_child(collision)


func _build_visual() -> void:
	if _has_direct_child_of_type(MeshInstance3D):
		return
	var visual := PlaceholderKit.box("art_key_v2_gate_%s" % gate_id, Color("#6a4352"), Vector3(0.5, 3.2, 2.0))
	visual.name = "GateVisual"
	visual.position.y = 1.6
	add_child(visual)


func _has_direct_child_of_type(p_type: Variant) -> bool:
	for child in get_children():
		if is_instance_of(child, p_type):
			return true
	return false
