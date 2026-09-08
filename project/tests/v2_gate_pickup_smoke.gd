extends SceneTree

const GateScript := preload("res://scripts/v2/V2AbilityGate.gd")
const PickupScript := preload("res://scripts/v2/V2AbilityPickup.gd")

var _received_pickup := ""


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var gate: StaticBody3D = GateScript.new()
	gate.set("gate_id", "seal_door")
	gate.set("required_boss", "seal_boss")
	root.add_child(gate)
	var allowed_before: bool = gate.can_open({}, false)
	var opened: bool = gate.try_open({"seal_key": true}, true)

	var pickup: Area3D = PickupScript.new()
	pickup.set("ability_id", "seal_key")
	pickup.set("ability_name", "封印钥匙")
	root.add_child(pickup)
	pickup.collected.connect(_on_pickup)
	pickup.collect()

	print("V2_GATE allowed_before=%s opened=%s pickup=%s" % [allowed_before, opened, _received_pickup])
	quit(0 if allowed_before == false and opened == true and _received_pickup == "seal_key" else 1)


func _on_pickup(p_ability: String) -> void:
	_received_pickup = p_ability
