class_name V2SaveSystem
extends RefCounted

const DEFAULT_PATH := "user://fivestar_v2.cfg"


static func save_run(
	p_seed: int,
	p_rest_point: Vector3,
	p_abilities: Dictionary,
	p_quest_flags: Dictionary,
	p_unlocked_gates: Array,
	p_current_case: int,
	p_boss_open: bool,
	p_path: String = DEFAULT_PATH
) -> bool:
	var config := ConfigFile.new()
	config.set_value("run", "seed", p_seed)
	config.set_value("run", "rest_x", p_rest_point.x)
	config.set_value("run", "rest_y", p_rest_point.y)
	config.set_value("run", "rest_z", p_rest_point.z)
	config.set_value("run", "current_case", p_current_case)
	config.set_value("run", "boss_open", p_boss_open)
	config.set_value("flags", "abilities", p_abilities)
	config.set_value("flags", "quests", p_quest_flags)
	config.set_value("flags", "gates", p_unlocked_gates)
	var error := config.save(p_path)
	return error == OK


static func load_run(p_path: String = DEFAULT_PATH) -> Dictionary:
	if not FileAccess.file_exists(p_path):
		return {
			"exists": false,
			"seed": 0,
			"rest_point": Vector3.ZERO,
			"current_case": 0,
			"boss_open": false,
			"abilities": {},
			"quest_flags": {},
			"unlocked_gates": [],
		}
	var config := ConfigFile.new()
	config.load(p_path)
	return {
		"exists": true,
		"seed": int(config.get_value("run", "seed", 0)),
		"rest_point": Vector3(
			float(config.get_value("run", "rest_x", 0.0)),
			float(config.get_value("run", "rest_y", 0.0)),
			float(config.get_value("run", "rest_z", 0.0))
		),
		"current_case": int(config.get_value("run", "current_case", 0)),
		"boss_open": bool(config.get_value("run", "boss_open", false)),
		"abilities": config.get_value("flags", "abilities", {}),
		"quest_flags": config.get_value("flags", "quests", {}),
		"unlocked_gates": config.get_value("flags", "gates", []),
	}


static func has_save(p_path: String = DEFAULT_PATH) -> bool:
	return FileAccess.file_exists(p_path)


static func clear_run(p_path: String = DEFAULT_PATH) -> void:
	if not FileAccess.file_exists(p_path):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(p_path))
