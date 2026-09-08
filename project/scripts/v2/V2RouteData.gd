class_name V2RouteData
extends RefCounted

const DEFAULT_REGION := "res://content/route/first_night_region.json"


static func load_region(p_path: String = DEFAULT_REGION) -> Dictionary:
	if not FileAccess.file_exists(p_path):
		return {}
	var text := FileAccess.get_file_as_string(p_path)
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}


static func zone_by_id(p_region: Dictionary, p_zone_id: String) -> Dictionary:
	for zone in p_region.get("zones", []):
		if zone.get("id", "") == p_zone_id:
			return zone
	return {}


static func ability_by_id(p_region: Dictionary, p_ability_id: String) -> Dictionary:
	for ability in p_region.get("abilities", []):
		if ability.get("id", "") == p_ability_id:
			return ability
	return {}


static func quest_by_id(p_region: Dictionary, p_quest_id: String) -> Dictionary:
	for quest in p_region.get("quests", []):
		if quest.get("id", "") == p_quest_id:
			return quest
	return {}
