@tool
extends EditorPlugin

const AuthoringDock := preload("res://addons/fivestar_authoring/fs_authoring_dock.gd")

var _dock: Control


func _enter_tree() -> void:
	set_input_event_forwarding_always_enabled()
	_dock = AuthoringDock.new()
	_dock.name = "FIVESTAR Authoring"
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)
	var selection := EditorInterface.get_selection()
	if not selection.selection_changed.is_connected(_on_selection_changed):
		selection.selection_changed.connect(_on_selection_changed)
	if not scene_changed.is_connected(_on_scene_changed):
		scene_changed.connect(_on_scene_changed)
	call_deferred("_refresh_dock")


func _exit_tree() -> void:
	var selection := EditorInterface.get_selection()
	if selection.selection_changed.is_connected(_on_selection_changed):
		selection.selection_changed.disconnect(_on_selection_changed)
	if scene_changed.is_connected(_on_scene_changed):
		scene_changed.disconnect(_on_scene_changed)
	if _dock:
		remove_control_from_docks(_dock)
		_dock.queue_free()
	_dock = null


func _on_selection_changed() -> void:
	if _dock:
		_dock.call("on_editor_selection_changed")


func _on_scene_changed(_p_scene_root: Node = null) -> void:
	if _dock:
		_dock.call_deferred("on_scene_changed")


func _refresh_dock() -> void:
	if _dock:
		_dock.call_deferred("on_scene_changed")


func _forward_3d_gui_input(p_camera: Camera3D, p_event: InputEvent) -> int:
	if _dock and _dock.has_method("handle_editor_3d_gui_input"):
		return int(_dock.call("handle_editor_3d_gui_input", p_camera, p_event))
	return EditorPlugin.AFTER_GUI_INPUT_PASS
