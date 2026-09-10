class_name FSPlaytestMode
extends RefCounted

const SETTING_PATH := "fivestar_authoring/playtest_mode"


static func is_enabled() -> bool:
	return bool(ProjectSettings.get_setting(SETTING_PATH, true))


static func set_enabled(p_enabled: bool) -> bool:
	ProjectSettings.set_setting(SETTING_PATH, p_enabled)
	return ProjectSettings.save() == OK


static func label() -> String:
	return "构建试玩" if is_enabled() else "完整游戏"
