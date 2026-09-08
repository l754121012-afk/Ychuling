class_name V2RegionRuntime
extends RefCounted

const RouteDataScript := preload("res://scripts/v2/V2RouteData.gd")

var region: Dictionary = {}
var abilities: Dictionary = {}
var quest_flags: Dictionary = {}
var boss_defeated := false
var current_zone := ""
var night_seed := 0


func setup_region(p_region: Dictionary, p_seed: int = 0) -> void:
	region = p_region
	night_seed = p_seed
	current_zone = "rest"


func collect_ability(p_ability_id: String) -> bool:
	if not _ability_exists(p_ability_id):
		return false
	abilities[p_ability_id] = true
	return true


func complete_quest(p_quest_id: String) -> Dictionary:
	quest_flags[p_quest_id] = true
	var quest: Dictionary = RouteDataScript.quest_by_id(region, p_quest_id)
	if not quest.is_empty() and quest.has("reward_ability"):
		var reward: String = quest.get("reward_ability", "")
		if not reward.is_empty():
			collect_ability(reward)
	return quest


func complete_boss() -> void:
	boss_defeated = true


func can_reach_zone(p_zone_id: String) -> bool:
	if p_zone_id == "rest":
		return true
	for gate in region.get("ability_gates", []):
		if gate.get("unlocks_zone", "") != p_zone_id:
			continue
		if not can_open_gate(gate):
			return false
	return true


func can_open_gate(p_gate: Dictionary) -> bool:
	var required_ability: String = p_gate.get("required_ability", "")
	var required_boss: String = p_gate.get("required_boss", "")
	var required_quest: String = p_gate.get("required_quest", "")
	if not required_ability.is_empty() and not abilities.has(required_ability):
		return false
	if not required_boss.is_empty() and not boss_defeated:
		return false
	if not required_quest.is_empty() and not quest_flags.has(required_quest):
		return false
	return true


func restore_from_save(p_save: Dictionary) -> void:
	night_seed = int(p_save.get("seed", 0))
	abilities = p_save.get("abilities", {})
	quest_flags = p_save.get("quest_flags", {})
	boss_defeated = bool(p_save.get("boss_open", false))
	current_zone = "rest"


func build_save_data(p_rest_point: Vector3, p_current_case: int) -> Dictionary:
	return {
		"seed": night_seed,
		"rest_point": p_rest_point,
		"current_case": p_current_case,
		"boss_open": boss_defeated,
		"abilities": abilities,
		"quest_flags": quest_flags,
		"unlocked_gates": _unlocked_gate_ids(),
	}


func _ability_exists(p_ability_id: String) -> bool:
	for ability in region.get("abilities", []):
		if ability.get("id", "") == p_ability_id:
			return true
	return false


func _unlocked_gate_ids() -> Array:
	var result: Array = []
	for gate in region.get("ability_gates", []):
		if can_open_gate(gate):
			result.append(gate.get("id", ""))
	return result
