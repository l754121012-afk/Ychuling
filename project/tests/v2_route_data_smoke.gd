extends SceneTree

const RouteData := preload("res://scripts/v2/V2RouteData.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var region: Dictionary = RouteData.load_region()
	var endpoint: Dictionary = RouteData.zone_by_id(region, "seal_endpoint")
	var quest: Dictionary = RouteData.quest_by_id(region, "side_a")
	print("V2_ROUTE region=%s endpoint=%s quest_reward=%s" % [
		region.get("region_id", "missing"),
		endpoint.get("type", "missing"),
		quest.get("reward_ability", "missing"),
	])
	quit(0 if region.get("region_id", "") == "first_night" and endpoint.get("type", "") == "objective" and quest.get("reward_ability", "") == "night_stamp" else 1)
