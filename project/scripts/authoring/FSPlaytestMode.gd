class_name FSPlaytestMode
extends RefCounted

const SETTING_PATH := "fivestar_authoring/playtest_mode"
const SCENE_SETTING_PATH := "fivestar_authoring/playtest_scene"
const AUTHORING_SCENE_DIR := "res://authoring/scenes/"
const AUTHORING_SCENE_SUFFIX := "_authoring.tscn"
const AUTHORING_PLAYER_SCALE := 1.0 / 3.0
const APPROVED_REVIEW_SCENES := [
	"res://authoring/scenes/spirit_sprawl_geometry.tscn",
]


static func is_enabled() -> bool:
	return bool(ProjectSettings.get_setting(SETTING_PATH, true))


static func set_enabled(p_enabled: bool) -> bool:
	ProjectSettings.set_setting(SETTING_PATH, p_enabled)
	return ProjectSettings.save() == OK


static func scene_path() -> String:
	return str(ProjectSettings.get_setting(SCENE_SETTING_PATH, "")).strip_edges()


static func is_authoring_scene_path(p_scene_path: String) -> bool:
	var path := p_scene_path.strip_edges().replace("\\", "/")
	if path.is_empty() or not path.begins_with(AUTHORING_SCENE_DIR):
		return false
	if (
		not path.get_file().ends_with(AUTHORING_SCENE_SUFFIX)
		and not APPROVED_REVIEW_SCENES.has(path)
	):
		return false
	return ResourceLoader.exists(path)


static func set_scene_path(p_scene_path: String) -> bool:
	var path := p_scene_path.strip_edges()
	if not is_authoring_scene_path(path):
		return false
	if path == scene_path():
		return true
	ProjectSettings.set_setting(SCENE_SETTING_PATH, path)
	return ProjectSettings.save() == OK


static func label() -> String:
	return "构建试玩" if is_enabled() else "完整游戏"
