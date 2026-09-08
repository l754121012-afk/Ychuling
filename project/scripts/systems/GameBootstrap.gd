extends Node


func _ready() -> void:
	_clear_action("move_up")
	_clear_action("move_down")
	_clear_action("move_left")
	_clear_action("move_right")
	_clear_action("jump")
	_clear_action("attack")
	_clear_action("spin")
	_clear_action("dash")
	_clear_action("interact")
	_clear_action("heal")
	_clear_action("map")
	_clear_action("pause")
	_clear_action("confirm")
	_clear_action("cancel")

	_add_key("move_up", KEY_W)
	_add_key("move_up", KEY_UP)
	_add_key("move_down", KEY_S)
	_add_key("move_down", KEY_DOWN)
	_add_key("move_left", KEY_A)
	_add_key("move_left", KEY_LEFT)
	_add_key("move_right", KEY_D)
	_add_key("move_right", KEY_RIGHT)

	_add_key("jump", KEY_SPACE)
	_add_joy_button("jump", JOY_BUTTON_A)
	_add_mouse("attack", MOUSE_BUTTON_LEFT)
	_add_joy_button("attack", JOY_BUTTON_X)
	_add_mouse("spin", MOUSE_BUTTON_RIGHT)
	_add_key("dash", KEY_SHIFT)
	_add_key("interact", KEY_E)
	_add_joy_button("interact", JOY_BUTTON_Y)
	_add_key("heal", KEY_X)
	_add_key("map", KEY_M)
	_add_key("pause", KEY_ESCAPE)
	_add_joy_button("pause", JOY_BUTTON_START)
	_add_key("confirm", KEY_ENTER)
	_add_key("cancel", KEY_ESCAPE)


func _clear_action(p_action: StringName) -> void:
	if InputMap.has_action(p_action):
		var events := InputMap.action_get_events(p_action)
		for event in events:
			InputMap.action_erase_event(p_action, event)
	else:
		InputMap.add_action(p_action)


func _add_key(p_action: StringName, p_keycode: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = p_keycode
	InputMap.action_add_event(p_action, event)


func _add_mouse(p_action: StringName, p_button: MouseButton) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = p_button
	InputMap.action_add_event(p_action, event)


func _add_joy_button(p_action: StringName, p_button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = p_button
	InputMap.action_add_event(p_action, event)
