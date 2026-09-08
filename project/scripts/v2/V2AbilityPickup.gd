class_name V2AbilityPickup
extends Area3D

signal collected(ability_id: String)

@export var ability_id := ""
@export var ability_name := ""


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_setup_visual()


func collect() -> void:
	collected.emit(ability_id)
	queue_free()


func _on_body_entered(p_body: Node3D) -> void:
	if p_body and p_body.is_in_group("player"):
		collect()


func _setup_visual() -> void:
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.8
	collision.shape = sphere
	collision.position.y = 0.8
	add_child(collision)

	var glow := PlaceholderKit.box("art_key_v2_pickup_%s" % ability_id, Color("#f5fbff"), Vector3(0.7, 0.7, 0.7))
	glow.position.y = 0.9
	add_child(glow)

	var core := PlaceholderKit.box("art_key_v2_pickup_core", Color("#e8f6ff"), Vector3(0.35, 0.35, 0.35))
	core.position.y = 1.15
	add_child(core)
