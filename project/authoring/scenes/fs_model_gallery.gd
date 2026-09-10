@tool
extends Control

const VisualCatalog := preload("res://scripts/authoring/FSVisualCatalog.gd")
const ModelPreview := preload("res://scripts/authoring/FSModelPreview.gd")

var _all_entries: Array[Dictionary] = []
var _filtered_entries: Array[Dictionary] = []
var _search_edit: LineEdit
var _category_option: OptionButton
var _model_list: ItemList
var _count_label: Label
var _title_label: Label
var _details_label: Label
var _preview: SubViewportContainer
var _auto_rotate_check: CheckButton
var _locate_button: Button


func _ready() -> void:
	_build_ui()
	_populate()
	call_deferred("_select_first_visible")


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.color = Color("0b1016")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	margin.add_child(columns)

	var browser_panel := PanelContainer.new()
	browser_panel.custom_minimum_size = Vector2(380.0, 0.0)
	browser_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(browser_panel)

	var browser_margin := MarginContainer.new()
	browser_margin.add_theme_constant_override("margin_left", 14)
	browser_margin.add_theme_constant_override("margin_top", 14)
	browser_margin.add_theme_constant_override("margin_right", 14)
	browser_margin.add_theme_constant_override("margin_bottom", 14)
	browser_panel.add_child(browser_margin)

	var browser := VBoxContainer.new()
	browser.add_theme_constant_override("separation", 9)
	browser_margin.add_child(browser)

	var browser_title := Label.new()
	browser_title.text = "FIVESTAR 模型浏览器"
	browser_title.add_theme_font_size_override("font_size", 20)
	browser.add_child(browser_title)

	_search_edit = LineEdit.new()
	_search_edit.placeholder_text = "搜索中文名、英文 ID、标签或分类"
	_search_edit.clear_button_enabled = true
	_search_edit.text_changed.connect(_on_search_changed)
	browser.add_child(_search_edit)

	_category_option = OptionButton.new()
	_category_option.item_selected.connect(_on_category_changed)
	browser.add_child(_category_option)

	_count_label = Label.new()
	_count_label.add_theme_color_override("font_color", Color("9fb2c4"))
	browser.add_child(_count_label)

	_model_list = ItemList.new()
	_model_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_model_list.select_mode = ItemList.SELECT_SINGLE
	_model_list.allow_reselect = true
	_model_list.fixed_icon_size = Vector2i(0, 0)
	_model_list.item_selected.connect(_on_model_selected)
	_model_list.item_activated.connect(_on_model_activated)
	browser.add_child(_model_list)

	var navigation := HBoxContainer.new()
	browser.add_child(navigation)
	var previous_button := Button.new()
	previous_button.text = "上一项"
	previous_button.pressed.connect(_select_relative.bind(-1))
	navigation.add_child(previous_button)
	var next_button := Button.new()
	next_button.text = "下一项"
	next_button.pressed.connect(_select_relative.bind(1))
	navigation.add_child(next_button)
	_auto_rotate_check = CheckButton.new()
	_auto_rotate_check.text = "自动旋转"
	_auto_rotate_check.button_pressed = true
	_auto_rotate_check.toggled.connect(_on_auto_rotate_toggled)
	navigation.add_child(_auto_rotate_check)

	var preview_panel := PanelContainer.new()
	preview_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(preview_panel)

	var preview_margin := MarginContainer.new()
	preview_margin.add_theme_constant_override("margin_left", 18)
	preview_margin.add_theme_constant_override("margin_top", 18)
	preview_margin.add_theme_constant_override("margin_right", 18)
	preview_margin.add_theme_constant_override("margin_bottom", 18)
	preview_panel.add_child(preview_margin)

	var preview_column := VBoxContainer.new()
	preview_column.add_theme_constant_override("separation", 12)
	preview_margin.add_child(preview_column)

	_title_label = Label.new()
	_title_label.text = "选择左侧模型查看预览"
	_title_label.add_theme_font_size_override("font_size", 24)
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_column.add_child(_title_label)

	_preview = ModelPreview.new()
	_preview.custom_minimum_size = Vector2(0.0, 430.0)
	preview_column.add_child(_preview)

	_details_label = Label.new()
	_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details_label.add_theme_font_size_override("font_size", 14)
	_details_label.add_theme_color_override("font_color", Color("c8d5df"))
	preview_column.add_child(_details_label)

	var action_row := HBoxContainer.new()
	preview_column.add_child(action_row)
	var copy_button := Button.new()
	copy_button.text = "复制模型 ID"
	copy_button.pressed.connect(_copy_selected_id)
	action_row.add_child(copy_button)
	_locate_button = Button.new()
	_locate_button.text = "在文件系统中定位"
	_locate_button.pressed.connect(_locate_selected_file)
	action_row.add_child(_locate_button)


func _populate() -> void:
	_all_entries = VisualCatalog.all_entries()
	_all_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_key := "%s/%s/%s" % [
			str(a.get("category", "")),
			str(a.get("label", "")),
			str(a.get("id", "")),
		]
		var b_key := "%s/%s/%s" % [
			str(b.get("category", "")),
			str(b.get("label", "")),
			str(b.get("id", "")),
		]
		return a_key.naturalnocasecmp_to(b_key) < 0
	)
	_category_option.clear()
	_category_option.add_item("全部分类")
	_category_option.set_item_metadata(0, "")
	for category in VisualCatalog.categories():
		_category_option.add_item(category)
		_category_option.set_item_metadata(_category_option.item_count - 1, category)
	_category_option.select(0)
	_rebuild_list()


func _on_search_changed(_p_text: String) -> void:
	_rebuild_list()


func _on_category_changed(_p_index: int) -> void:
	_rebuild_list()


func _rebuild_list() -> void:
	if not _model_list:
		return
	var query := _search_edit.text.strip_edges().to_lower()
	var category := str(_category_option.get_item_metadata(_category_option.selected))
	_filtered_entries.clear()
	for entry in _all_entries:
		if not category.is_empty() and str(entry.get("category", "")) != category:
			continue
		if not query.is_empty() and query not in _search_text(entry):
			continue
		_filtered_entries.append(entry)
	_model_list.clear()
	for entry in _filtered_entries:
		var item_index := _model_list.add_item("%s  ·  %s" % [
			str(entry.get("label", "")),
			str(entry.get("category", "")),
		])
		_model_list.set_item_metadata(item_index, str(entry.get("id", "")))
		_model_list.set_item_tooltip(item_index, "%s\n%s" % [
			str(entry.get("id", "")),
			str(entry.get("path", "")),
		])
	_count_label.text = "显示 %d / %d 个模型" % [_filtered_entries.size(), _all_entries.size()]
	_select_first_visible()


func _select_first_visible() -> void:
	if _filtered_entries.is_empty() or not _model_list:
		_title_label.text = "没有匹配的模型"
		_details_label.text = ""
		_preview.clear_model()
		_locate_button.disabled = true
		return
	if _model_list.item_count > 0:
		_model_list.select(0)
		_on_model_selected(0)


func _on_model_selected(p_index: int) -> void:
	if p_index < 0 or p_index >= _filtered_entries.size():
		return
	var entry := _filtered_entries[p_index]
	_title_label.text = "%s  ·  %s" % [
		str(entry.get("label", "")),
		str(entry.get("category", "")),
	]
	_details_label.text = "ID：%s\n资源：%s\n标签：%s" % [
		str(entry.get("id", "")),
		str(entry.get("path", "")),
		", ".join(entry.get("tags", [])) if not entry.get("tags", []).is_empty() else "无",
	]
	_preview.set_model(entry)
	_locate_button.disabled = false


func _on_model_activated(p_index: int) -> void:
	_on_model_selected(p_index)


func _select_relative(p_offset: int) -> void:
	if _model_list.item_count == 0:
		return
	var selected := _model_list.get_selected_items()
	var index := selected[0] if not selected.is_empty() else 0
	index = posmod(index + p_offset, _model_list.item_count)
	_model_list.select(index)
	_model_list.ensure_current_is_visible()
	_on_model_selected(index)


func _copy_selected_id() -> void:
	var entry := _selected_entry()
	if entry.is_empty():
		return
	DisplayServer.clipboard_set(str(entry.get("id", "")))


func _locate_selected_file() -> void:
	var entry := _selected_entry()
	if entry.is_empty():
		return
	if EditorInterface.has_method("select_file"):
		EditorInterface.select_file(str(entry.get("path", "")))


func _selected_entry() -> Dictionary:
	var selected := _model_list.get_selected_items() if _model_list else PackedInt32Array()
	if selected.is_empty():
		return {}
	var index := selected[0]
	if index < 0 or index >= _filtered_entries.size():
		return {}
	return _filtered_entries[index]


func _search_text(p_entry: Dictionary) -> String:
	return " ".join([
		str(p_entry.get("id", "")),
		str(p_entry.get("label", "")),
		str(p_entry.get("category", "")),
		" ".join(p_entry.get("tags", [])),
		str(p_entry.get("path", "")),
	]).to_lower()


func _on_auto_rotate_toggled(p_enabled: bool) -> void:
	_preview.set_auto_rotate(p_enabled)
