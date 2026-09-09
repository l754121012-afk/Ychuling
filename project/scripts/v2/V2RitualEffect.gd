class_name V2RitualEffect
extends Node3D

const DURATION := 1.4


func play(p_color: Color = Color("#ffe08a")) -> void:
	var ring := PlaceholderKit.ground_quad("art_key_v2_ritual_ring", p_color, Vector2(5.0, 5.0))
	ring.position.y = 0.06
	add_child(ring)
	ring.scale = Vector3(0.15, 0.15, 0.15)

	var ring_tween := create_tween()
	ring_tween.tween_property(ring, "scale", Vector3(2.2, 2.2, 2.2), 0.18)
	ring_tween.tween_property(ring, "scale", Vector3(0.35, 0.35, 0.35), 0.2)

	var beam := MeshInstance3D.new()
	beam.name = "art_key_v2_ritual_beam"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.6
	cylinder.bottom_radius = 0.6
	cylinder.height = 14.0
	beam.mesh = cylinder
	beam.material_override = PlaceholderKit.material_alpha(p_color, 0.75)
	beam.position.y = 7.0
	add_child(beam)
	beam.scale = Vector3(0.02, 0.02, 0.02)

	var beam_tween := create_tween()
	beam_tween.tween_interval(0.34)
	beam_tween.tween_property(beam, "scale", Vector3.ONE, 0.18)
	beam_tween.tween_interval(0.5)
	beam_tween.tween_property(beam, "scale", Vector3(1.5, 1.1, 1.5), 0.3)
	beam_tween.tween_callback(_finish)


func _finish() -> void:
	queue_free()
