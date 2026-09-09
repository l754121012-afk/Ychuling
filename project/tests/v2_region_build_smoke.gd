extends SceneTree

const RouteData := preload("res://scripts/v2/V2RouteData.gd")
const RegionBuilder := preload("res://scripts/v2/V2RegionBuilder.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var region: Dictionary = RouteData.load_region()
	var root_node := Node3D.new()
	root.add_child(root_node)

	var handle: Dictionary = RegionBuilder.build(root_node, region)
	for _frame in range(6):
		await process_frame

	var zones: Dictionary = handle.get("zones", {})
	var gates: Dictionary = handle.get("gates", {})
	var floors: int = int(handle.get("floors", 0))
	var props: int = int(handle.get("props", 0))
	var decor: int = int(handle.get("decor", 0))
	var seal_gate: Node = gates.get("seal_door")

	print("V2_REGION floors=%s props=%s decor=%s gates=%s" % [
		floors,
		props,
		decor,
		(seal_gate.get("gate_id") if is_instance_valid(seal_gate) else "none"),
	])

	var ok: bool = floors >= 4 \
		and props > 0 \
		and decor > 0 \
		and zones.has("district_nightwatch") \
		and zones.has("district_residential") \
		and zones.has("district_theater") \
		and zones.has("district_seal") \
		and is_instance_valid(seal_gate)
	quit(0 if ok else 1)
