@tool
extends VBoxContainer

const Schema := preload("res://scripts/authoring/FSAuthoringSchema.gd")
const Manifest := preload("res://scripts/authoring/FSSceneManifest.gd")
const Workflow := preload("res://scripts/authoring/FSWorkflow.gd")
const Scaffold := preload("res://scripts/authoring/FSRegionScaffold.gd")
const Runtime := preload("res://scripts/authoring/FSAuthoringRuntime.gd")
const VisualCatalog := preload("res://scripts/authoring/FSVisualCatalog.gd")
const EffectCatalog := preload("res://scripts/authoring/FSEffectCatalog.gd")
const EnvironmentCatalog := preload("res://scripts/authoring/FSEnvironmentCatalog.gd")
const GroundPaintCatalog := preload("res://scripts/authoring/FSGroundPaintCatalog.gd")
const ModelPreview := preload("res://scripts/authoring/FSModelPreview.gd")
const GameView := preload("res://scripts/authoring/FSGameView.gd")
const PlaytestMode := preload("res://scripts/authoring/FSPlaytestMode.gd")
const ADDON_VERSION := "0.3.3"
const MODEL_GALLERY_PATH := "res://authoring/scenes/model_gallery.tscn"

var _selected_node: Node
var _edited_root: Node
var _last_manifest: Dictionary = {}
var _workflow_document: Dictionary = {}
var _workflow_path := ""

var _selection_label: Label
var _runtime_support_label: Label
var _status_label: Label
var _region_edit: LineEdit
var _id_edit: LineEdit
var _display_name_edit: LineEdit
var _zone_edit: LineEdit
var _kind_option: OptionButton
var _behavior_option: OptionButton
var _tags_edit: LineEdit
var _links_edit: LineEdit
var _params_edit: TextEdit
var _model_filter_edit: LineEdit
var _model_category_option: OptionButton
var _model_list: ItemList
var _new_model_name_edit: LineEdit
var _model_preview: SubViewportContainer
var _model_shortcut := ""
var _model_apply_button: Button
var _model_create_button: Button
var _model_remove_button: Button
var _model_recommend_button: Button
var _model_ground_button: Button
var _model_support_button: Button
var _model_status_label: Label
var _effect_option: OptionButton
var _effect_apply_button: Button
var _effect_remove_button: Button
var _effect_status_label: Label
var _environment_option: OptionButton
var _environment_name_edit: LineEdit
var _environment_create_button: Button
var _environment_remove_button: Button
var _environment_status_label: Label
var _paint_preset_option: OptionButton
var _paint_shape_option: OptionButton
var _paint_radius_slider: HSlider
var _paint_opacity_slider: HSlider
var _paint_toggle_button: Button
var _paint_remove_button: Button
var _paint_status_label: Label
var _paint_mode_active := false
var _paint_stroke_active := false
var _paint_stroke_count := 0
var _paint_last_position := Vector3.ZERO
var _paint_has_last_position := false
var _open_scene_button: Button
var _save_scene_button: Button
var _apply_button: Button
var _clear_button: Button
var _validation_output: TextEdit
var _workflow_progress: TextEdit
var _workflow_step_label: Label
var _workflow_owner_label: Label
var _workflow_prompt_label: Label
var _workflow_note_edit: LineEdit
var _workflow_confirm_button: Button
var _confirm_dialog: ConfirmationDialog
var _recommended_models_dialog: ConfirmationDialog
var _focus_button: Button
var _game_view_button: Button
var _editor_view_button: Button
var _view_status_label: Label
var _playtest_build_button: Button
var _playtest_full_button: Button
var _playtest_status_label: Label
var _saved_editor_camera_transform := Transform3D.IDENTITY
var _saved_editor_camera_fov := 70.0
var _has_saved_editor_camera := false
var _game_view_active := false
var _game_view_focus_description := ""
var _focus_view_active := false
var _focus_view_description := ""
var _focus_center := Vector3.ZERO
var _focus_distance := GameView.FOCUS_MIN_DISTANCE
var _focus_radius := 1.0
var _focus_yaw_degrees := GameView.FOCUS_YAW_DEGREES
var _focus_elevation_degrees := GameView.FOCUS_ELEVATION_DEGREES
var _focus_orbiting := false


func _ready() -> void:
	_build_ui()
	call_deferred("on_scene_changed")


func on_scene_changed() -> void:
	if not Engine.is_editor_hint():
		return
	_edited_root = EditorInterface.get_edited_scene_root()
	if _edited_root:
		var root_data := Schema.data_from_node(_edited_root)
		if not str(root_data.get("semantic_id", "")).is_empty() and str(root_data.get("kind", "")) == "region":
			_region_edit.text = str(root_data["semantic_id"])
	_refresh_selection()
	_refresh_workflow()
	_refresh_view_status()
	_refresh_playtest_mode_ui()
	call_deferred("_repair_environment_nodes")


func on_editor_selection_changed() -> void:
	_refresh_selection()


func _build_ui() -> void:
	name = "FIVESTAR 场景语义工具"
	custom_minimum_size = Vector2(260.0, 0.0)

	var title := Label.new()
	title.text = "FIVESTAR 场景语义工具 · %s" % ADDON_VERSION
	title.add_theme_font_size_override("font_size", 17)
	add_child(title)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.text = "选择场景中的物件后登记语义。"
	add_child(_status_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	_add_heading(content, "作者场景")
	var scene_panel := VBoxContainer.new()
	content.add_child(scene_panel)
	var scene_path_row := HBoxContainer.new()
	scene_panel.add_child(scene_path_row)
	_region_edit = LineEdit.new()
	_region_edit.text = "first_night"
	_region_edit.placeholder_text = "region_id"
	_region_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene_path_row.add_child(_region_edit)
	_open_scene_button = Button.new()
	_open_scene_button.text = "打开作者场景"
	_open_scene_button.tooltip_text = "打开 res://authoring/scenes/<region_id>_authoring.tscn；不存在时不会覆盖或创建文件。"
	_open_scene_button.pressed.connect(_on_open_scene_pressed)
	scene_path_row.add_child(_open_scene_button)
	var scene_action_row := HBoxContainer.new()
	scene_panel.add_child(scene_action_row)
	_save_scene_button = Button.new()
	_save_scene_button.text = "保存当前场景"
	_save_scene_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_save_scene_button.tooltip_text = "保存当前 Authoring 场景，包括布局、中文节点名和已应用的模型。"
	_save_scene_button.pressed.connect(_on_save_scene_pressed)
	scene_action_row.add_child(_save_scene_button)
	var create_scene_button := Button.new()
	create_scene_button.text = "从 JSON 生成"
	create_scene_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	create_scene_button.tooltip_text = "生成可手调的 authoring 场景，不覆盖当前运行时主场景。"
	create_scene_button.pressed.connect(_on_create_scene_pressed)
	scene_action_row.add_child(create_scene_button)

	_add_heading(content, "F5 运行模式")
	var playtest_row := HBoxContainer.new()
	content.add_child(playtest_row)
	_playtest_build_button = Button.new()
	_playtest_build_button.text = "F5：构建试玩"
	_playtest_build_button.tooltip_text = "F5 只加载作者场景、临时 y=0 碰撞地面、玩家和实际跟随相机；不生成案件、敌人、NPC、地图或 HUD。"
	_playtest_build_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_playtest_build_button.pressed.connect(_on_playtest_build_pressed)
	playtest_row.add_child(_playtest_build_button)
	_playtest_full_button = Button.new()
	_playtest_full_button.text = "F5：完整游戏"
	_playtest_full_button.tooltip_text = "F5 运行现有完整 V2 流程。"
	_playtest_full_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_playtest_full_button.pressed.connect(_on_playtest_full_pressed)
	playtest_row.add_child(_playtest_full_button)
	_playtest_status_label = Label.new()
	_playtest_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_playtest_status_label)

	_add_heading(content, "观察视图")
	var view_help := Label.new()
	view_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	view_help.text = "选中物件后按 Shift+F 舒适聚焦，或切到游戏视角检查实际俯视效果。视图操作只移动编辑摄像机，不会修改或保存场景。"
	content.add_child(view_help)
	var view_action_row := VBoxContainer.new()
	content.add_child(view_action_row)
	_focus_button = Button.new()
	_focus_button.text = "舒适聚焦选中物件  Shift+F"
	_focus_button.tooltip_text = "按选中物件的包围盒自动取景，并从约 36° 斜上方观察。Godot 原生 F 仍可用于普通框选。"
	_focus_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_focus_button.pressed.connect(_on_focus_selection_pressed)
	view_action_row.add_child(_focus_button)
	_game_view_button = Button.new()
	_game_view_button.text = "切到游戏视角  Ctrl+Alt+1"
	_game_view_button.tooltip_text = "保存当前编辑视角，并从当前选中物件切入实际游戏摄像机视角。"
	_game_view_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_game_view_button.pressed.connect(_on_game_view_pressed)
	view_action_row.add_child(_game_view_button)
	_editor_view_button = Button.new()
	_editor_view_button.text = "恢复编辑视角  Ctrl+Alt+2"
	_editor_view_button.tooltip_text = "恢复进入游戏视角前保存的位置、旋转和 FOV。"
	_editor_view_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_editor_view_button.pressed.connect(_on_editor_view_pressed)
	view_action_row.add_child(_editor_view_button)
	_view_status_label = Label.new()
	_view_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_view_status_label.text = "当前：编辑视角（自由搭建）"
	content.add_child(_view_status_label)

	_add_heading(content, "选中物件语义")
	_selection_label = Label.new()
	_selection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_selection_label.text = "未选择节点"
	content.add_child(_selection_label)
	_runtime_support_label = Label.new()
	_runtime_support_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_runtime_support_label.text = "Codex 接管：--"
	content.add_child(_runtime_support_label)

	var form := GridContainer.new()
	form.columns = 2
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(form)
	_add_form_label(form, "semantic_id")
	_id_edit = LineEdit.new()
	_id_edit.placeholder_text = "unique_stable_id"
	_id_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_child(_id_edit)
	_add_form_label(form, "显示名（中文）")
	_display_name_edit = LineEdit.new()
	_display_name_edit.placeholder_text = "例如：墓穴门 A"
	_display_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_child(_display_name_edit)
	_add_form_label(form, "kind")
	_kind_option = OptionButton.new()
	_fill_options(_kind_option, Schema.kind_options())
	_kind_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_child(_kind_option)
	_add_form_label(form, "behavior")
	_behavior_option = OptionButton.new()
	_fill_options(_behavior_option, Schema.behavior_options())
	_behavior_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_child(_behavior_option)
	_add_form_label(form, "zone_id")
	_zone_edit = LineEdit.new()
	_zone_edit.placeholder_text = "district_nightwatch"
	_zone_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_child(_zone_edit)
	_add_form_label(form, "tags")
	_tags_edit = LineEdit.new()
	_tags_edit.placeholder_text = "主物件, 可互动"
	_tags_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_child(_tags_edit)
	_add_form_label(form, "links")
	_links_edit = LineEdit.new()
	_links_edit.placeholder_text = "target_semantic_id, another_id"
	_links_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_child(_links_edit)

	var params_label := Label.new()
	params_label.text = "params JSON"
	content.add_child(params_label)
	_params_edit = TextEdit.new()
	_params_edit.custom_minimum_size = Vector2(0.0, 84.0)
	_params_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_params_edit.text = "{}"
	content.add_child(_params_edit)

	_add_heading(content, "可视模型（已导入）")
	_model_filter_edit = LineEdit.new()
	_model_filter_edit.placeholder_text = "搜索中文名、英文 ID 或标签"
	_model_filter_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_model_filter_edit.text_changed.connect(_on_model_filter_changed)
	content.add_child(_model_filter_edit)
	_model_category_option = OptionButton.new()
	_model_category_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_model_category_option.item_selected.connect(_on_model_category_changed)
	content.add_child(_model_category_option)
	var water_shortcut_row := HBoxContainer.new()
	content.add_child(water_shortcut_row)
	var water_shortcut_button := Button.new()
	water_shortcut_button.text = "水体 / 喷泉"
	water_shortcut_button.tooltip_text = "固定显示喷泉、瀑布、河流、河岸、水面、水坑、排水口和水车，不混入药水瓶。"
	water_shortcut_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	water_shortcut_button.pressed.connect(_on_water_models_shortcut_pressed)
	water_shortcut_row.add_child(water_shortcut_button)
	var terrain_shortcut_button := Button.new()
	terrain_shortcut_button.text = "地形 / 平台"
	terrain_shortcut_button.tooltip_text = "固定显示可以承托玩家行走、站立和战斗的地板、平台、墙、楼梯、坡道、道路和柱体。"
	terrain_shortcut_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	terrain_shortcut_button.pressed.connect(_on_terrain_models_shortcut_pressed)
	water_shortcut_row.add_child(terrain_shortcut_button)
	var all_models_button := Button.new()
	all_models_button.text = "全部模型"
	all_models_button.tooltip_text = "清除搜索词并显示全部模型分类。"
	all_models_button.pressed.connect(_on_all_models_shortcut_pressed)
	water_shortcut_row.add_child(all_models_button)
	var model_utility_row := HBoxContainer.new()
	content.add_child(model_utility_row)
	var model_gallery_button := Button.new()
	model_gallery_button.text = "打开模型总览"
	model_gallery_button.tooltip_text = "只读打开全部已导入 GLB 的 UI 浏览器；左侧列表，右侧实时三维预览，不会修改当前作者场景。"
	model_gallery_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	model_gallery_button.pressed.connect(_on_open_model_gallery_pressed)
	model_utility_row.add_child(model_gallery_button)
	_model_ground_button = Button.new()
	_model_ground_button.text = "修正场景模型落地"
	_model_ground_button.tooltip_text = "把所有默认落地模型的底面对齐到宿主地面；显式浮动的水面、云和特效不会强行落地。"
	_model_ground_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_model_ground_button.pressed.connect(_on_ground_models_pressed)
	model_utility_row.add_child(_model_ground_button)
	_model_support_button = Button.new()
	_model_support_button.text = "修正场景承托碰撞"
	_model_support_button.tooltip_text = "为地板、平台、墙、楼梯、坡道和柱体补齐或刷新插件生成的承托碰撞；不删除你自己添加的碰撞体。"
	_model_support_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_model_support_button.pressed.connect(_on_refresh_support_collisions_pressed)
	model_utility_row.add_child(_model_support_button)
	var model_list_help := Label.new()
	model_list_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	model_list_help.text = "在列表中选择模型，不必先选中场景节点。双击列表项可直接创建物件。"
	content.add_child(model_list_help)
	_model_list = ItemList.new()
	_model_list.custom_minimum_size = Vector2(0.0, 170.0)
	_model_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_model_list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_model_list.select_mode = ItemList.SELECT_SINGLE
	_model_list.allow_reselect = true
	_model_list.item_selected.connect(_on_model_list_selected)
	_model_list.item_activated.connect(_on_model_list_activated)
	content.add_child(_model_list)
	_model_preview = ModelPreview.new()
	_model_preview.custom_minimum_size = Vector2(0.0, 190.0)
	content.add_child(_model_preview)
	var new_model_name_label := Label.new()
	new_model_name_label.text = "新物件中文名（可选）"
	content.add_child(new_model_name_label)
	_new_model_name_edit = LineEdit.new()
	_new_model_name_edit.placeholder_text = "例如：雨城喷泉；留空时使用模型中文名"
	_new_model_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_new_model_name_edit.text_submitted.connect(func(_text: String) -> void: _on_create_model_instance_pressed())
	content.add_child(_new_model_name_edit)
	var model_action_row := HBoxContainer.new()
	content.add_child(model_action_row)
	_model_apply_button = Button.new()
	_model_apply_button.text = "应用/替换模型"
	_model_apply_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_model_apply_button.pressed.connect(_on_apply_model_pressed)
	model_action_row.add_child(_model_apply_button)
	_model_remove_button = Button.new()
	_model_remove_button.text = "移除模型"
	_model_remove_button.pressed.connect(_on_remove_model_pressed)
	model_action_row.add_child(_model_remove_button)
	_model_create_button = Button.new()
	_model_create_button.text = "创建选中模型为新物件"
	_model_create_button.tooltip_text = "直接把列表中的模型做成带中文名和稳定 semantic_id 的新物件；选中区域时放入该区域，否则放到场景根节点。"
	_model_create_button.pressed.connect(_on_create_model_instance_pressed)
	content.add_child(_model_create_button)
	_model_recommend_button = Button.new()
	_model_recommend_button.text = "一键区分未配模型"
	_model_recommend_button.tooltip_text = "给尚未挂模型的物件补推荐原型，并识别名称中带墙、门、柱、平台、水体等关键词的未登记物件；已有有效模型和碰撞体不会覆盖，地板保留色板。"
	_model_recommend_button.pressed.connect(_on_recommend_models_pressed)
	content.add_child(_model_recommend_button)
	_model_status_label = Label.new()
	_model_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_model_status_label.text = "选择语义宿主后，可一键挂载或替换可视模型。"
	content.add_child(_model_status_label)
	_populate_model_categories()
	_rebuild_model_options()

	_add_heading(content, "事件特效（不替换模型）")
	var effect_help := Label.new()
	effect_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_help.text = "模型负责外观，特效负责案件、危险、机关和恢复等状态；同一物件可同时保留两者。"
	content.add_child(effect_help)
	_effect_option = OptionButton.new()
	_effect_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_effect_option.fit_to_longest_item = false
	_effect_option.clip_text = true
	_effect_option.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	content.add_child(_effect_option)
	var effect_action_row := HBoxContainer.new()
	content.add_child(effect_action_row)
	_effect_apply_button = Button.new()
	_effect_apply_button.text = "应用事件特效"
	_effect_apply_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_effect_apply_button.pressed.connect(_on_apply_effect_pressed)
	effect_action_row.add_child(_effect_apply_button)
	_effect_remove_button = Button.new()
	_effect_remove_button.text = "移除事件特效"
	_effect_remove_button.pressed.connect(_on_remove_effect_pressed)
	effect_action_row.add_child(_effect_remove_button)
	_effect_status_label = Label.new()
	_effect_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_effect_status_label.text = "选择语义宿主后，可叠加或替换一个事件特效。"
	content.add_child(_effect_status_label)
	_populate_effect_options()

	_add_heading(content, "环境美术特效（可叠加）")
	var environment_help := Label.new()
	environment_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	environment_help.text = "环境层可重复创建并同时存在，不会替换模型或事件特效。灯、雾、雨、风等节点创建后仍可在场景树中单独调整。"
	content.add_child(environment_help)
	_environment_option = OptionButton.new()
	_environment_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_environment_option.fit_to_longest_item = false
	_environment_option.clip_text = true
	_environment_option.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	content.add_child(_environment_option)
	_environment_name_edit = LineEdit.new()
	_environment_name_edit.placeholder_text = "环境节点中文名（可选）"
	_environment_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_environment_name_edit)
	var environment_action_row := HBoxContainer.new()
	content.add_child(environment_action_row)
	_environment_create_button = Button.new()
	_environment_create_button.text = "创建环境特效"
	_environment_create_button.tooltip_text = "在当前区域或选中物件所在的层级创建一个独立环境节点；可重复创建并叠加。"
	_environment_create_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_environment_create_button.pressed.connect(_on_create_environment_pressed)
	environment_action_row.add_child(_environment_create_button)
	_environment_remove_button = Button.new()
	_environment_remove_button.text = "删除选中环境"
	_environment_remove_button.tooltip_text = "仅删除当前选中的插件环境节点，不影响模型和其他环境层。"
	_environment_remove_button.pressed.connect(_on_remove_environment_pressed)
	environment_action_row.add_child(_environment_remove_button)
	_environment_status_label = Label.new()
	_environment_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_environment_status_label.text = "选择一种环境组件后直接创建；总览中可选灯光、云、雾、火焰、雨幕、风和尘埃。"
	content.add_child(_environment_status_label)
	_populate_environment_options()

	_add_heading(content, "地面绘制（贴面）")
	var paint_help := Label.new()
	paint_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	paint_help.text = "地形模型继续负责承托和碰撞；这里在大地形表面刷湿泥、青苔、石屑、水光和破败痕迹。开启画笔后，在三维视图里左键点击或拖动。每笔完成会自动保存为 GROUND_PAINT_ 节点。"
	content.add_child(paint_help)
	_paint_preset_option = OptionButton.new()
	_paint_preset_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_paint_preset_option.fit_to_longest_item = false
	_paint_preset_option.clip_text = true
	content.add_child(_paint_preset_option)
	_paint_shape_option = OptionButton.new()
	_paint_shape_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_paint_shape_option.fit_to_longest_item = false
	_paint_shape_option.clip_text = true
	content.add_child(_paint_shape_option)
	var paint_radius_label := Label.new()
	paint_radius_label.text = "笔刷半径"
	content.add_child(paint_radius_label)
	_paint_radius_slider = HSlider.new()
	_paint_radius_slider.min_value = GroundPaintCatalog.MIN_RADIUS
	_paint_radius_slider.max_value = GroundPaintCatalog.MAX_RADIUS
	_paint_radius_slider.step = 0.1
	_paint_radius_slider.value = 2.5
	_paint_radius_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_paint_radius_slider)
	var paint_opacity_label := Label.new()
	paint_opacity_label.text = "绘制浓度"
	content.add_child(paint_opacity_label)
	_paint_opacity_slider = HSlider.new()
	_paint_opacity_slider.min_value = 0.05
	_paint_opacity_slider.max_value = 1.0
	_paint_opacity_slider.step = 0.05
	_paint_opacity_slider.value = 0.7
	_paint_opacity_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_paint_opacity_slider)
	var paint_action_row := HBoxContainer.new()
	content.add_child(paint_action_row)
	_paint_toggle_button = Button.new()
	_paint_toggle_button.text = "开启地面画笔"
	_paint_toggle_button.tooltip_text = "开启后左键在编辑器三维视图的地面碰撞体上绘制；再次点击结束。"
	_paint_toggle_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_paint_toggle_button.pressed.connect(_on_toggle_paint_mode_pressed)
	paint_action_row.add_child(_paint_toggle_button)
	_paint_remove_button = Button.new()
	_paint_remove_button.text = "删除选中绘制"
	_paint_remove_button.tooltip_text = "删除当前选中的 GROUND_PAINT_ 绘制节点，不会删除地形模型。"
	_paint_remove_button.pressed.connect(_on_remove_paint_pressed)
	paint_action_row.add_child(_paint_remove_button)
	_paint_status_label = Label.new()
	_paint_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_paint_status_label.text = "画笔关闭。建议用“地形 / 平台”模型搭好碰撞地面后再绘制。"
	content.add_child(_paint_status_label)
	_populate_ground_paint_options()

	var action_row := HBoxContainer.new()
	content.add_child(action_row)
	_apply_button = Button.new()
	_apply_button.text = "应用语义 / 改名"
	_apply_button.tooltip_text = "把“显示名（中文）”等字段写回选中节点；只改中文名时也点这里。"
	_apply_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_button.pressed.connect(_on_apply_pressed)
	action_row.add_child(_apply_button)
	_clear_button = Button.new()
	_clear_button.text = "清除"
	_clear_button.pressed.connect(_on_clear_pressed)
	action_row.add_child(_clear_button)

	_add_heading(content, "校验与导出")
	var validate_row := HBoxContainer.new()
	content.add_child(validate_row)
	var validate_button := Button.new()
	validate_button.text = "校验当前场景"
	validate_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	validate_button.pressed.connect(func() -> void: _run_validation(false))
	validate_row.add_child(validate_button)
	var export_button := Button.new()
	export_button.text = "导出并发布"
	export_button.pressed.connect(func() -> void: _run_validation(true))
	validate_row.add_child(export_button)
	_validation_output = TextEdit.new()
	_validation_output.editable = false
	_validation_output.custom_minimum_size = Vector2(0.0, 130.0)
	_validation_output.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	content.add_child(_validation_output)

	_add_heading(content, "工作流")
	_workflow_progress = TextEdit.new()
	_workflow_progress.editable = false
	_workflow_progress.custom_minimum_size = Vector2(0.0, 150.0)
	content.add_child(_workflow_progress)
	_workflow_step_label = Label.new()
	_workflow_step_label.add_theme_font_size_override("font_size", 15)
	_workflow_step_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_workflow_step_label)
	_workflow_owner_label = Label.new()
	_workflow_owner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_workflow_owner_label)
	_workflow_prompt_label = Label.new()
	_workflow_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_workflow_prompt_label)
	_workflow_note_edit = LineEdit.new()
	_workflow_note_edit.placeholder_text = "确认备注，可留空"
	content.add_child(_workflow_note_edit)
	_workflow_confirm_button = Button.new()
	_workflow_confirm_button.text = "确认本节点"
	_workflow_confirm_button.pressed.connect(_on_confirm_workflow_pressed)
	content.add_child(_workflow_confirm_button)

	_confirm_dialog = ConfirmationDialog.new()
	_confirm_dialog.title = "确认工作流节点"
	_confirm_dialog.confirmed.connect(_on_workflow_confirmed)
	add_child(_confirm_dialog)

	_recommended_models_dialog = ConfirmationDialog.new()
	_recommended_models_dialog.title = "批量应用推荐模型"
	_recommended_models_dialog.dialog_text = "将给尚未挂模型的语义宿主补上推荐原型，修复空壳或零尺寸的旧模型节点，并识别名称中带墙、门、柱、平台、水体等关键词的未登记物件。\n\n已有有效模型、碰撞体和已填写显示名不会被覆盖；地板保留色板。\n\n完成后会自动保存当前场景。是否继续？"
	_recommended_models_dialog.confirmed.connect(_on_recommended_models_confirmed)
	add_child(_recommended_models_dialog)

	_set_form_enabled(false)


func _shortcut_input(p_event: InputEvent) -> void:
	if not (p_event is InputEventKey):
		return
	var key_event := p_event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if (
		key_event.keycode == KEY_F
		and key_event.shift_pressed
		and not key_event.ctrl_pressed
		and not key_event.alt_pressed
	):
		_on_focus_selection_pressed()
		get_viewport().set_input_as_handled()
		return
	if not key_event.ctrl_pressed or not key_event.alt_pressed:
		return
	match key_event.keycode:
		KEY_1:
			_on_game_view_pressed()
			get_viewport().set_input_as_handled()
		KEY_2:
			_on_editor_view_pressed()
			get_viewport().set_input_as_handled()


func _on_focus_selection_pressed() -> void:
	var selected_nodes: Array[Node] = []
	for node in EditorInterface.get_selection().get_selected_nodes():
		if node is Node3D:
			selected_nodes.append(node)
	if selected_nodes.is_empty():
		_set_status("先选择一个或多个三维物件，再使用舒适聚焦。", true)
		return
	var camera := _editor_camera()
	if camera == null:
		_set_status("无法访问编辑器三维摄像机；请让三维视图保持可见后重试。", true)
		return
	var bounds := GameView.combined_world_aabb(selected_nodes)
	if not bool(bounds.get("found", false)):
		_set_status("无法计算选中物件的包围盒。", true)
		return
	var aspect := 1.7777778
	var viewport := EditorInterface.get_editor_viewport_3d(0)
	if viewport:
		var visible_size := viewport.get_visible_rect().size
		if visible_size.y > 0.0:
			aspect = visible_size.x / visible_size.y
	var pose := GameView.focus_pose_for_aabb(bounds["aabb"], aspect)
	camera.fov = GameView.FOCUS_FOV
	camera.global_transform = pose["transform"]
	_focus_center = pose["center"]
	_focus_distance = float(pose["distance"])
	_focus_radius = float(pose["radius"])
	_focus_yaw_degrees = float(pose["yaw_degrees"])
	_focus_elevation_degrees = float(pose["elevation_degrees"])
	_focus_orbiting = false
	_game_view_active = false
	_focus_view_active = true
	_focus_view_description = _focus_selection_description(selected_nodes)
	_refresh_view_status()
	_set_status(
		"已舒适聚焦：%s。中键拖动环绕，滚轮缩放；Shift+F 可再次取景。%s" % [
			_focus_view_description,
			"当前按无可见几何体回退到节点中心。" if bool(bounds.get("fallback", false)) else "",
		],
		false
	)


func handle_editor_3d_gui_input(p_camera: Camera3D, p_event: InputEvent) -> int:
	if _paint_mode_active and p_camera != null:
		var paint_result := _handle_ground_paint_input(p_camera, p_event)
		if paint_result != 0:
			return paint_result
	if not _focus_view_active or p_camera == null:
		return 0
	if p_event is InputEventMouseButton:
		var button_event := p_event as InputEventMouseButton
		if button_event.button_index == MOUSE_BUTTON_MIDDLE:
			_focus_orbiting = button_event.pressed
			return 1
		if (
			button_event.pressed
			and button_event.button_index in [
				MOUSE_BUTTON_WHEEL_UP,
				MOUSE_BUTTON_WHEEL_DOWN,
			]
		):
			var wheel_factor := button_event.factor
			if is_zero_approx(wheel_factor):
				wheel_factor = 1.0 if button_event.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0
			elif button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				wheel_factor = -absf(wheel_factor)
			_focus_distance = GameView.focus_zoom_step(
				_focus_distance,
				_focus_radius,
				wheel_factor
			)
			_apply_focus_camera(p_camera)
			return 1
	if p_event is InputEventMouseMotion and _focus_orbiting:
		var motion := p_event as InputEventMouseMotion
		var orbit := GameView.focus_orbit_step(motion.relative)
		_focus_yaw_degrees += float(orbit["yaw_delta"])
		_focus_elevation_degrees = clampf(
			_focus_elevation_degrees + float(orbit["elevation_delta"]),
			GameView.FOCUS_MIN_ELEVATION_DEGREES,
			GameView.FOCUS_MAX_ELEVATION_DEGREES
		)
		_apply_focus_camera(p_camera)
		return 1
	return 0


func _handle_ground_paint_input(p_camera: Camera3D, p_event: InputEvent) -> int:
	if p_event is InputEventMouseButton:
		var button_event := p_event as InputEventMouseButton
		if button_event.button_index != MOUSE_BUTTON_LEFT:
			return 0
		if button_event.pressed:
			_paint_stroke_active = true
			_paint_stroke_count = 0
			_paint_has_last_position = false
			_paint_at_editor_position(p_camera, button_event.position, true)
			return 1
		if _paint_stroke_active:
			_paint_stroke_active = false
			_paint_has_last_position = false
			var saved := _commit_ground_paint_stroke()
			_paint_status_label.text = (
				"本笔已保存：%d 个绘制贴面。继续左键拖动，或关闭画笔。"
				% _paint_stroke_count
				if saved
				else "本笔已生成，但自动保存失败；请按 Ctrl+S。"
			)
			_paint_stroke_count = 0
			return 1
	if p_event is InputEventMouseMotion and _paint_stroke_active:
		var motion := p_event as InputEventMouseMotion
		if motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_paint_at_editor_position(p_camera, motion.position, false)
			return 1
	return 0


func _paint_at_editor_position(
	p_camera: Camera3D,
	p_screen_position: Vector2,
	p_force: bool
) -> void:
	if not _edited_root:
		return
	var hit := _raycast_ground_point(p_camera, p_screen_position)
	if not bool(hit.get("ok", false)):
		if p_force:
			_paint_status_label.text = str(hit.get("error", "没有找到可绘制的地面。"))
		return
	var position: Vector3 = hit["position"]
	var radius := float(_paint_radius_slider.value)
	if (
		not p_force
		and _paint_has_last_position
		and _paint_last_position.distance_to(position) < radius * GroundPaintCatalog.STAMP_SPACING_RATIO
	):
		return
	var parent := _ground_paint_parent()
	var params := GroundPaintCatalog.brush_params(
		_selected_option(_paint_preset_option),
		_selected_option(_paint_shape_option),
		radius,
		float(_paint_opacity_slider.value)
	)
	var result := GroundPaintCatalog.apply_stamp(
		parent,
		position,
		hit["normal"],
		_edited_root,
		params
	)
	if not bool(result.get("ok", false)):
		_paint_status_label.text = str(result.get("error", "绘制失败。"))
		return
	_paint_last_position = position
	_paint_has_last_position = true
	_paint_stroke_count += 1
	_paint_status_label.text = "正在绘制 %s：%d 笔。" % [
		str(params.get("preset_label", "")),
		_paint_stroke_count,
	]


func _raycast_ground_point(p_camera: Camera3D, p_screen_position: Vector2) -> Dictionary:
	var ray_origin := p_camera.project_ray_origin(p_screen_position)
	var ray_normal := p_camera.project_ray_normal(p_screen_position)
	var ray_end := ray_origin + ray_normal * 5000.0
	var world := p_camera.get_world_3d()
	if world:
		var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		query.collide_with_areas = false
		query.collide_with_bodies = true
		var hit: Dictionary = world.direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			return {
				"ok": true,
				"position": hit.get("position", Vector3.ZERO),
				"normal": hit.get("normal", Vector3.UP),
			}
	var ground_plane := Plane(Vector3.UP, 0.0)
	var plane_hit = ground_plane.intersects_ray(ray_origin, ray_normal)
	if plane_hit == null:
		return {"ok": false, "error": "视线前方没有地面碰撞体，也没有命中 y=0 构建平面。"}
	return {
		"ok": true,
		"position": plane_hit,
		"normal": Vector3.UP,
	}


func _ground_paint_parent() -> Node3D:
	var existing := _edited_root.get_node_or_null(GroundPaintCatalog.GROUP_NAME)
	if existing is Node3D:
		return existing as Node3D
	var group := Node3D.new()
	group.name = GroundPaintCatalog.GROUP_NAME
	_edited_root.add_child(group)
	group.owner = _edited_root
	return group


func _commit_ground_paint_stroke() -> bool:
	if _paint_stroke_count <= 0:
		return true
	if EditorInterface.has_method("mark_scene_as_unsaved"):
		EditorInterface.call("mark_scene_as_unsaved")
	return EditorInterface.save_scene() == OK


func _on_toggle_paint_mode_pressed() -> void:
	if _paint_mode_active:
		_paint_mode_active = false
		_paint_stroke_active = false
		_paint_has_last_position = false
		_paint_toggle_button.text = "开启地面画笔"
		_paint_status_label.text = "画笔已关闭。绘制贴面会继续保存在 GROUND_PAINT_ 地面绘制 节点下。"
		return
	if not _edited_root:
		_set_status("没有打开的作者场景。", true)
		return
	_paint_mode_active = true
	_focus_view_active = false
	_paint_toggle_button.text = "地面画笔：已开启"
	_paint_status_label.text = "画笔已开启。左键在三维视图地面碰撞体上点击或拖动；每笔松开后自动保存。"
	_set_status("地面画笔已开启；可先用 Shift+F 调整观察位置。", false)


func _on_remove_paint_pressed() -> void:
	if not _selected_node or not GroundPaintCatalog.is_paint_node(_selected_node):
		_set_status("请先在场景树中选中一个 GROUND_PAINT_ 绘制节点。", true)
		return
	var removed_name := str(_selected_node.name)
	if not GroundPaintCatalog.remove_paint_node(_selected_node):
		_set_status("删除地面绘制失败。", true)
		return
	_selected_node = null
	if EditorInterface.has_method("mark_scene_as_unsaved"):
		EditorInterface.call("mark_scene_as_unsaved")
	var save_error := EditorInterface.save_scene()
	if save_error != OK:
		_set_status(
			"已删除绘制 %s，但自动保存失败：%s。请按 Ctrl+S。" % [
				removed_name,
				error_string(save_error),
			],
			true
		)
	else:
		_set_status("已删除并保存地面绘制：%s。" % removed_name, false)
	_refresh_selection()


func _populate_ground_paint_options() -> void:
	_paint_preset_option.clear()
	for entry in GroundPaintCatalog.presets():
		_paint_preset_option.add_item(str(entry.get("label", "")))
		_paint_preset_option.set_item_metadata(
			_paint_preset_option.item_count - 1,
			str(entry.get("id", ""))
		)
	if _paint_preset_option.item_count > 0:
		_paint_preset_option.select(0)
	_paint_shape_option.clear()
	for entry in GroundPaintCatalog.shapes():
		_paint_shape_option.add_item(str(entry.get("label", "")))
		_paint_shape_option.set_item_metadata(
			_paint_shape_option.item_count - 1,
			str(entry.get("id", ""))
		)
	if _paint_shape_option.item_count > 0:
		_paint_shape_option.select(0)


func _repair_environment_nodes() -> void:
	if not _edited_root:
		return
	var result := EnvironmentCatalog.repair_environment_nodes(_edited_root, _edited_root)
	var repaired := int(result.get("repaired", 0))
	var rebuilt := int(result.get("rebuilt", 0))
	if repaired <= 0 and rebuilt <= 0:
		return
	if EditorInterface.has_method("mark_scene_as_unsaved"):
		EditorInterface.call("mark_scene_as_unsaved")
	var save_error := EditorInterface.save_scene()
	_set_status(
		"已修复环境特效持久化：补建 %d 个，修复归属 %d 个。%s" % [
			rebuilt,
			repaired,
			"已保存。" if save_error == OK else "自动保存失败，请按 Ctrl+S。",
		],
		save_error != OK or not bool(result.get("ok", true))
	)


func _apply_focus_camera(p_camera: Camera3D) -> void:
	p_camera.fov = GameView.FOCUS_FOV
	p_camera.global_transform = GameView.focus_camera_transform(
		_focus_center,
		_focus_yaw_degrees,
		_focus_elevation_degrees,
		_focus_distance
	)


func _on_game_view_pressed() -> void:
	var camera := _editor_camera()
	if camera == null:
		_set_status("无法访问编辑器三维摄像机；请让三维视图保持可见后重试。", true)
		return
	if not _game_view_active:
		_saved_editor_camera_transform = camera.global_transform
		_saved_editor_camera_fov = camera.fov
		_has_saved_editor_camera = true
	_game_view_active = true
	_focus_view_active = false
	_focus_orbiting = false
	var focus := _view_focus_position()
	GameView.apply_to_camera(camera, focus)
	_game_view_focus_description = _view_focus_description()
	_refresh_view_status()
	_set_status("已切到游戏视角：观察 %s。按 Ctrl+Alt+2 恢复编辑视角。" % _game_view_focus_description, false)


func _on_editor_view_pressed() -> void:
	if not _game_view_active and not _focus_view_active:
		_set_status("当前已经是编辑视角。", false)
		return
	if not _has_saved_editor_camera:
		_set_status("没有可恢复的编辑视角记录。", true)
		return
	var camera := _editor_camera()
	if camera == null:
		_set_status("无法访问编辑器三维摄像机；请让三维视图保持可见后重试。", true)
		return
	camera.fov = _saved_editor_camera_fov
	camera.global_transform = _saved_editor_camera_transform
	_game_view_active = false
	_focus_view_active = false
	_focus_orbiting = false
	_has_saved_editor_camera = false
	_game_view_focus_description = ""
	_focus_view_description = ""
	_refresh_view_status()
	_set_status("已恢复编辑视角。", false)


func _on_playtest_build_pressed() -> void:
	_set_playtest_mode(true)


func _on_playtest_full_pressed() -> void:
	_set_playtest_mode(false)


func _set_playtest_mode(p_enabled: bool) -> void:
	var saved := PlaytestMode.set_enabled(p_enabled)
	_refresh_playtest_mode_ui()
	var selected := "构建试玩" if p_enabled else "完整游戏"
	if saved:
		_set_status("F5 已切换为%s，并写入项目设置。若运行进程仍使用旧值，请完全重开项目一次。" % selected, false)
	else:
		_set_status("F5 已切换为%s，但项目设置写入失败。请检查 project.godot 是否可写。" % selected, true)


func _refresh_playtest_mode_ui() -> void:
	if not _playtest_status_label:
		return
	var enabled := PlaytestMode.is_enabled()
	_playtest_status_label.text = "当前 F5：%s" % PlaytestMode.label()
	if _playtest_build_button:
		_playtest_build_button.disabled = enabled
	if _playtest_full_button:
		_playtest_full_button.disabled = not enabled


func _editor_camera() -> Camera3D:
	var viewport := EditorInterface.get_editor_viewport_3d(0)
	if viewport == null:
		return null
	return viewport.get_camera_3d()


func _view_focus_position() -> Vector3:
	var selected := EditorInterface.get_selection().get_selected_nodes()
	if selected.size() == 1 and selected[0] is Node3D:
		return _node_world_position(selected[0])
	var spawn := _find_spawn_marker()
	if spawn:
		return _node_world_position(spawn)
	if _edited_root is Node3D:
		return _node_world_position(_edited_root)
	return Vector3.ZERO


func _view_focus_description() -> String:
	var selected := EditorInterface.get_selection().get_selected_nodes()
	if selected.size() == 1 and selected[0] is Node3D:
		return str(selected[0].name)
	if _find_spawn_marker():
		return "出生点 spawn"
	if _edited_root is Node3D:
		return "场景原点"
	return "世界原点"


func _focus_selection_description(p_nodes: Array[Node]) -> String:
	if p_nodes.size() == 1:
		return str(p_nodes[0].name)
	return "已选中的 %d 个物件" % p_nodes.size()


func _node_world_position(p_node: Node3D) -> Vector3:
	if p_node.is_inside_tree():
		return p_node.global_position
	return p_node.global_transform.origin


func _find_spawn_marker() -> Node3D:
	if _edited_root == null:
		return null
	var pending: Array[Node] = [_edited_root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is Node3D:
			var data := Schema.data_from_node(node)
			var semantic_id := str(data.get("semantic_id", "")).to_lower()
			var kind := str(data.get("kind", "")).to_lower()
			var behavior := str(data.get("behavior", "")).to_lower()
			var node_name := str(node.name).to_lower()
			if semantic_id == "spawn" or kind == "spawn" or behavior == "spawn" or "spawn" in node_name or "出生" in node_name:
				return node as Node3D
		for child in node.get_children():
			pending.append(child)
	return null


func _refresh_view_status() -> void:
	if _view_status_label == null:
		return
	if _game_view_active:
		_view_status_label.text = "当前：游戏视角 · 观察 %s" % _game_view_focus_description
	elif _focus_view_active:
		_view_status_label.text = "当前：舒适聚焦 · %s（中键环绕 / 滚轮缩放）" % _focus_view_description
	else:
		_view_status_label.text = "当前：编辑视角（自由搭建）"


func _refresh_selection() -> void:
	var selected: Array[Node] = []
	var editor_selection = _editor_selection()
	if editor_selection:
		selected = editor_selection.get_selected_nodes()
	if selected.size() != 1:
		_selected_node = null
		_selection_label.text = "请选择一个节点。当前选择：%d" % selected.size()
		_runtime_support_label.text = "Codex 接管：--"
		_set_form_enabled(false)
		return
	_selected_node = selected[0]
	var node_path := "<节点尚未进入编辑树>"
	if _edited_root:
		if _selected_node == _edited_root:
			node_path = "."
		elif _edited_root.is_inside_tree() and _selected_node.is_inside_tree() and _edited_root.get_tree() == _selected_node.get_tree() and _edited_root.is_ancestor_of(_selected_node):
			node_path = str(_edited_root.get_path_to(_selected_node))
	var data := Schema.data_from_node(_selected_node)
	if data.is_empty():
		data = Schema.make(_suggest_id(_selected_node), _suggest_kind(_selected_node), "none")
	_selection_label.text = "%s（%s）\n%s" % [
		str(_selected_node.name),
		_selected_node.get_class(),
		node_path,
	]
	_id_edit.text = str(data.get("semantic_id", ""))
	_display_name_edit.text = str(data.get("display_name", ""))
	_zone_edit.text = str(data.get("zone_id", ""))
	_tags_edit.text = ", ".join(Schema.string_array(data.get("tags", [])))
	_links_edit.text = ", ".join(Schema.string_array(data.get("links", [])))
	_params_edit.text = JSON.stringify(data.get("params", {}), "\t", true)
	_select_option(_kind_option, str(data.get("kind", "prop")))
	_select_option(_behavior_option, str(data.get("behavior", "none")))
	_runtime_support_label.text = _runtime_support_text(Schema.runtime_support_for(
		str(data.get("kind", "prop")),
		str(data.get("behavior", "none"))
	))
	_refresh_model_picker(data)
	_refresh_effect_picker(data)
	_set_form_enabled(true)


func _on_apply_pressed() -> void:
	if not _selected_node:
		_set_status("先选择一个节点。", true)
		return
	var params = {}
	var params_text := _params_edit.text.strip_edges()
	if not params_text.is_empty():
		params = JSON.parse_string(params_text)
		if not (params is Dictionary):
			_set_status("params 必须是合法 JSON 对象。", true)
			return
	var data := Schema.make(
		_id_edit.text,
		_selected_option(_kind_option),
		_selected_option(_behavior_option),
		_zone_edit.text,
		Schema.string_array(_tags_edit.text),
		Schema.string_array(_links_edit.text),
		params,
		_display_name_edit.text
	)
	data = Schema.apply_to_node(_selected_node, data)
	_selected_node.name = Schema.node_name(data)
	_runtime_support_label.text = _runtime_support_text(Schema.runtime_support_for(
		str(data.get("kind", "")),
		str(data.get("behavior", ""))
	))
	if EditorInterface.has_method("mark_scene_as_unsaved"):
		EditorInterface.call("mark_scene_as_unsaved")
	_set_status("已登记 %s / %s / %s。" % [
		str(data["kind"]),
		str(data.get("display_name", "未命名")),
		str(data["semantic_id"]),
	], false)
	_refresh_selection()
	_run_validation(false)


func _on_clear_pressed() -> void:
	if not _selected_node:
		return
	if _selected_node.has_meta(Schema.META_KEY):
		_selected_node.remove_meta(Schema.META_KEY)
	for group in _selected_node.get_groups():
		if str(group).begins_with("fs."):
			_selected_node.remove_from_group(group)
	if EditorInterface.has_method("mark_scene_as_unsaved"):
		EditorInterface.call("mark_scene_as_unsaved")
	_set_status("已清除选中节点的语义。", false)
	_refresh_selection()


func _populate_model_categories() -> void:
	_model_category_option.clear()
	_model_category_option.add_item("全部分类")
	_model_category_option.set_item_metadata(0, "")
	for category in VisualCatalog.categories():
		_model_category_option.add_item(category)
		_model_category_option.set_item_metadata(_model_category_option.item_count - 1, category)
	_model_category_option.select(0)


func _rebuild_model_options(p_selected_id: String = "") -> void:
	if not _model_list:
		return
	var category := _selected_option(_model_category_option)
	var matches: Array[Dictionary] = []
	if _model_shortcut == "water":
		matches = VisualCatalog.water_shortcut_entries()
	elif _model_shortcut == "terrain":
		matches = VisualCatalog.support_shortcut_entries()
	else:
		matches = VisualCatalog.search(_model_filter_edit.text if _model_filter_edit else "", category)
	_model_list.clear()
	for entry in matches:
		var model_id := str(entry.get("id", ""))
		var label := str(entry.get("label", model_id))
		var item_index := _model_list.add_item("%s  ·  %s" % [label, model_id])
		_model_list.set_item_metadata(item_index, model_id)
		_model_list.set_item_tooltip(item_index, "%s\n%s\n双击可直接创建物件" % [label, model_id])
	if not p_selected_id.is_empty():
		_select_model_list_item(p_selected_id)
	if _model_list.item_count > 0 and _model_list.get_selected_items().is_empty():
		_model_list.select(0)
	_refresh_model_preview()
	_refresh_create_button_state()
	if _model_status_label:
		var scope := "找到 "
		if _model_shortcut == "water":
			scope = "水体 / 喷泉："
		elif _model_shortcut == "terrain":
			scope = "地形 / 平台："
		_model_status_label.text = "%s%d 个模型。%s" % [
			scope,
			matches.size(),
			"当前选择：%s" % p_selected_id if not p_selected_id.is_empty() else "",
		]


func _selected_model_id() -> String:
	if not _model_list:
		return ""
	var selected := _model_list.get_selected_items()
	if selected.is_empty():
		return ""
	var index := selected[0]
	if index < 0 or index >= _model_list.item_count:
		return ""
	return str(_model_list.get_item_metadata(index))


func _select_model_list_item(p_model_id: String) -> void:
	if not _model_list:
		return
	for index in range(_model_list.item_count):
		if str(_model_list.get_item_metadata(index)) == p_model_id:
			_model_list.select(index)
			_model_list.ensure_current_is_visible()
			return


func _refresh_create_button_state() -> void:
	if not _model_create_button:
		return
	_model_create_button.disabled = _edited_root == null or _selected_model_id().is_empty()


func _on_model_filter_changed(_p_text: String) -> void:
	_model_shortcut = ""
	_rebuild_model_options()


func _on_model_category_changed(_p_index: int) -> void:
	_model_shortcut = ""
	_rebuild_model_options()


func _on_model_list_selected(_p_index: int) -> void:
	_refresh_model_preview()
	_refresh_create_button_state()


func _on_model_list_activated(_p_index: int) -> void:
	_on_create_model_instance_pressed()


func _refresh_model_preview() -> void:
	if not _model_preview or not _model_list:
		return
	var entry := VisualCatalog.find(_selected_model_id())
	if entry.is_empty():
		_model_preview.clear_model()
		return
	_model_preview.set_model(entry)


func _on_water_models_shortcut_pressed() -> void:
	_model_filter_edit.text = ""
	_model_category_option.select(0)
	_model_shortcut = "water"
	_rebuild_model_options()


func _on_terrain_models_shortcut_pressed() -> void:
	_model_filter_edit.text = ""
	_model_category_option.select(0)
	_model_shortcut = "terrain"
	_rebuild_model_options()


func _on_all_models_shortcut_pressed() -> void:
	_model_filter_edit.text = ""
	_model_category_option.select(0)
	_model_shortcut = ""
	_rebuild_model_options()


func _on_open_model_gallery_pressed() -> void:
	if not ResourceLoader.exists(MODEL_GALLERY_PATH):
		_set_status("模型总览场景不存在：%s" % MODEL_GALLERY_PATH, true)
		return
	EditorInterface.open_scene_from_path(MODEL_GALLERY_PATH)
	_set_status("正在打开只读模型总览：%s" % MODEL_GALLERY_PATH, false)


func _on_ground_models_pressed() -> void:
	if not _edited_root:
		_set_status("没有打开的作者场景。", true)
		return
	var result := VisualCatalog.ground_all_models(_edited_root)
	if EditorInterface.has_method("mark_scene_as_unsaved"):
		EditorInterface.call("mark_scene_as_unsaved")
	var save_error := EditorInterface.save_scene()
	var save_text := "已自动保存。" if save_error == OK else "自动保存失败：%s。请按 Ctrl+S 重试。" % error_string(save_error)
	var failed := int(result.get("failed", 0))
	_set_status(
		"模型落地：修正 %d，浮动/无模型跳过 %d，失败 %d。%s" % [
			int(result.get("corrected", 0)),
			int(result.get("skipped", 0)),
			failed,
			save_text,
		],
		failed > 0 or save_error != OK
	)
	var report: Array[String] = []
	for error in result.get("errors", []):
		report.append(str(error))
	if not report.is_empty():
		_validation_output.text = "\n".join(report)
	_refresh_selection()


func _on_refresh_support_collisions_pressed() -> void:
	if not _edited_root:
		_set_status("没有打开的作者场景。", true)
		return
	var result: Dictionary = VisualCatalog.refresh_all_support_collisions(_edited_root)
	if EditorInterface.has_method("mark_scene_as_unsaved"):
		EditorInterface.call("mark_scene_as_unsaved")
	var save_error := EditorInterface.save_scene()
	var failed := int(result.get("failed", 0))
	var save_text := "已自动保存。" if save_error == OK else "自动保存失败：%s。请按 Ctrl+S 重试。" % error_string(save_error)
	_set_status(
		"承托碰撞：修正 %d，跳过 %d，失败 %d。%s" % [
			int(result.get("corrected", 0)),
			int(result.get("skipped", 0)),
			failed,
			save_text,
		],
		failed > 0 or save_error != OK
	)
	var report: Array[String] = []
	for error in result.get("errors", []):
		report.append(str(error))
	if not report.is_empty():
		_validation_output.text = "\n".join(report)
	_refresh_selection()


func _refresh_model_picker(p_data: Dictionary) -> void:
	var params: Dictionary = p_data.get("params", {})
	var visual: Dictionary = params.get("visual", {}) if params.get("visual", {}) is Dictionary else {}
	var model_id := str(visual.get("model_id", ""))
	if model_id.is_empty() and _selected_node:
		model_id = VisualCatalog.model_id_from_node(_selected_node)
	var entry := VisualCatalog.find(model_id)
	if entry.is_empty():
		if not model_id.is_empty():
			_model_status_label.text = "当前模型不在目录中：%s" % model_id
		elif _selected_node and VisualCatalog.model_id_from_node(_selected_node).is_empty():
			_model_status_label.text = "当前语义宿主没有可视模型。"
		return
	_select_option(_model_category_option, str(entry.get("category", "")))
	_rebuild_model_options(model_id)
	_model_status_label.text = "当前模型：%s（%s）" % [
		str(entry.get("label", "")),
		str(entry.get("id", "")),
	]


func _populate_effect_options() -> void:
	if not _effect_option:
		return
	_effect_option.clear()
	for entry in EffectCatalog.entries():
		_effect_option.add_item("%s  ·  %s" % [
			str(entry.get("label", "")),
			str(entry.get("id", "")),
		])
		_effect_option.set_item_metadata(_effect_option.item_count - 1, str(entry.get("id", "")))
	if _effect_option.item_count > 0:
		_effect_option.select(0)


func _populate_environment_options() -> void:
	if not _environment_option:
		return
	_environment_option.clear()
	for entry in EnvironmentCatalog.entries():
		_environment_option.add_item("%s  ·  %s" % [
			str(entry.get("label", "")),
			str(entry.get("id", "")),
		])
		_environment_option.set_item_metadata(
			_environment_option.item_count - 1,
			str(entry.get("id", ""))
		)
	if _environment_option.item_count > 0:
		_environment_option.select(0)


func _refresh_effect_picker(p_data: Dictionary) -> void:
	var params: Dictionary = p_data.get("params", {})
	var effect: Dictionary = params.get("effect", {}) if params.get("effect", {}) is Dictionary else {}
	var effect_id := str(effect.get("effect_id", ""))
	if effect_id.is_empty() and _selected_node:
		var effect_node := EffectCatalog.effect_node(_selected_node)
		if effect_node:
			effect_id = str(effect_node.name).trim_prefix(EffectCatalog.EFFECT_PREFIX)
	var entry := EffectCatalog.find(effect_id)
	if entry.is_empty():
		if effect_id.is_empty():
			_effect_status_label.text = "当前语义宿主没有事件特效。"
		else:
			_effect_status_label.text = "当前特效不在目录中：%s" % effect_id
		return
	_select_option(_effect_option, effect_id)
	_effect_status_label.text = "当前特效：%s（%s）" % [
		str(entry.get("label", "")),
		str(entry.get("id", "")),
	]


func _on_create_environment_pressed() -> void:
	if not _edited_root:
		_set_status("没有打开的作者场景。", true)
		return
	var effect_id := _selected_option(_environment_option)
	var entry := EnvironmentCatalog.find(effect_id)
	if entry.is_empty():
		_set_status("请选择一个目录中的环境特效。", true)
		return
	var parent := _environment_parent()
	var display_name := _environment_name_edit.text.strip_edges() if _environment_name_edit else ""
	var result := EnvironmentCatalog.apply_environment(
		parent,
		entry,
		_edited_root,
		display_name
	)
	if not bool(result.get("ok", false)):
		_set_status(str(result.get("error", "环境特效创建失败。")), true)
		return
	var environment_node := result.get("node") as Node3D
	if EditorInterface.has_method("mark_scene_as_unsaved"):
		EditorInterface.call("mark_scene_as_unsaved")
	var save_error := EditorInterface.save_scene()
	var node_name := str(environment_node.name) if environment_node else str(entry.get("label", effect_id))
	if save_error != OK:
		_set_status(
			"环境特效已创建，但自动保存失败：%s。请按 Ctrl+S 重试。" % error_string(save_error),
			true
		)
	else:
		_set_status("已创建并保存环境特效：%s。" % node_name, false)
	if _environment_name_edit:
		_environment_name_edit.text = ""
	_select_created_parent(parent)


func _on_remove_environment_pressed() -> void:
	if not EnvironmentCatalog.is_environment_node(_selected_node):
		_set_status("请先选中一个由插件创建的 ENVIRONMENT_ 环境节点。", true)
		return
	var removed_name := str(_selected_node.name)
	if not EnvironmentCatalog.remove_environment(_selected_node):
		_set_status("删除环境节点失败。", true)
		return
	_selected_node = null
	if EditorInterface.has_method("mark_scene_as_unsaved"):
		EditorInterface.call("mark_scene_as_unsaved")
	var save_error := EditorInterface.save_scene()
	if save_error != OK:
		_set_status(
			"已删除环境节点 %s，但自动保存失败：%s。请按 Ctrl+S 重试。" % [
				removed_name,
				error_string(save_error),
			],
			true
		)
	else:
		_set_status("已删除并保存环境节点：%s。" % removed_name, false)
	_refresh_selection()


func _on_apply_model_pressed() -> void:
	if not _selected_node:
		_set_status("先选择一个语义宿主节点。", true)
		return
	var data := Schema.data_from_node(_selected_node)
	if data.is_empty():
		_set_status("请先点击“应用语义”，再挂载可视模型。", true)
		return
	var model_id := _selected_model_id()
	var entry := VisualCatalog.find(model_id)
	if entry.is_empty():
		_set_status("请选择一个目录中的模型。", true)
		return
	var result := VisualCatalog.apply_model(_selected_node, entry, _edited_root)
	if not bool(result.get("ok", false)):
		_set_status(str(result.get("error", "模型挂载失败。")), true)
		return
	var params: Dictionary = data.get("params", {}).duplicate(true)
	params["visual"] = result.get("visual", {})
	data["params"] = params
	data = Schema.apply_to_node(_selected_node, data)
	_selected_node.name = Schema.node_name(data)
	_params_edit.text = JSON.stringify(params, "\t", true)
	if EditorInterface.has_method("mark_scene_as_unsaved"):
		EditorInterface.call("mark_scene_as_unsaved")
	var save_error := EditorInterface.save_scene()
	if save_error != OK:
		_set_status(
			"模型已应用，但自动保存失败：%s。请按 Ctrl+S 重试。" % error_string(save_error),
			true
		)
	else:
		_set_status("已应用并保存模型 %s。" % str(entry.get("label", model_id)), false)
	_refresh_selection()
	_run_validation(false)


func _on_apply_effect_pressed() -> void:
	if not _selected_node:
		_set_status("先选择一个语义宿主节点。", true)
		return
	var data := Schema.data_from_node(_selected_node)
	if data.is_empty():
		_set_status("请先点击“应用语义”，再挂载事件特效。", true)
		return
	var effect_id := _selected_option(_effect_option)
	var entry := EffectCatalog.find(effect_id)
	if entry.is_empty():
		_set_status("请选择一个目录中的事件特效。", true)
		return
	var result := EffectCatalog.apply_effect(_selected_node, entry, _edited_root)
	if not bool(result.get("ok", false)):
		_set_status(str(result.get("error", "事件特效应用失败。")), true)
		return
	var params: Dictionary = data.get("params", {}).duplicate(true)
	params["effect"] = result.get("effect", {})
	data["params"] = params
	data = Schema.apply_to_node(_selected_node, data)
	_selected_node.name = Schema.node_name(data)
	_params_edit.text = JSON.stringify(params, "\t", true)
	if EditorInterface.has_method("mark_scene_as_unsaved"):
		EditorInterface.call("mark_scene_as_unsaved")
	var save_error := EditorInterface.save_scene()
	if save_error != OK:
		_set_status(
			"特效已应用，但自动保存失败：%s。请按 Ctrl+S 重试。" % error_string(save_error),
			true
		)
	else:
		_set_status("已应用并保存事件特效 %s。" % str(entry.get("label", effect_id)), false)
	_refresh_selection()


func _on_remove_effect_pressed() -> void:
	if not _selected_node:
		_set_status("先选择一个语义宿主节点。", true)
		return
	var data := Schema.data_from_node(_selected_node)
	if data.is_empty():
		_set_status("选中节点没有语义，无法记录特效变更。", true)
		return
	var removed := EffectCatalog.remove_effect(_selected_node)
	var params: Dictionary = data.get("params", {}).duplicate(true)
	params.erase("effect")
	data["params"] = params
	data = Schema.apply_to_node(_selected_node, data)
	_selected_node.name = Schema.node_name(data)
	_params_edit.text = JSON.stringify(params, "\t", true)
	if EditorInterface.has_method("mark_scene_as_unsaved"):
		EditorInterface.call("mark_scene_as_unsaved")
	var save_error := EditorInterface.save_scene()
	if save_error != OK:
		_set_status(
			"已移除特效，但自动保存失败：%s。请按 Ctrl+S 重试。" % error_string(save_error),
			true
		)
	else:
		_set_status("已移除并保存 %d 个事件特效节点。" % removed, false)
	_refresh_selection()


func _on_create_model_instance_pressed() -> void:
	if not _edited_root:
		_set_status("没有打开的作者场景。", true)
		return
	var model_id := _selected_model_id()
	var entry := VisualCatalog.find(model_id)
	if entry.is_empty():
		_set_status("请先选择一个目录中的模型。", true)
		return

	var parent := _model_instance_parent()

	var semantic_id := _next_visual_instance_id(model_id)
	var typed_name := _new_model_name_edit.text.strip_edges() if _new_model_name_edit else ""
	var display_name := typed_name if not typed_name.is_empty() else str(entry.get("label", model_id)).strip_edges()
	var data := Schema.make(
		semantic_id,
		"decor",
		"none",
		_zone_id_for_parent(parent),
		["新增模型", str(entry.get("category", ""))],
		[],
		{},
		display_name
	)
	var host := Node3D.new()
	parent.add_child(host)
	host.owner = _edited_root
	data = Schema.apply_to_node(host, data)
	host.name = Schema.node_name(data)

	var result := VisualCatalog.apply_model(host, entry, _edited_root)
	if not bool(result.get("ok", false)):
		parent.remove_child(host)
		host.free()
		_set_status(str(result.get("error", "新增模型失败。")), true)
		return
	var params: Dictionary = data.get("params", {}).duplicate(true)
	params["visual"] = result.get("visual", {})
	data["params"] = params
	data = Schema.apply_to_node(host, data)
	host.name = Schema.node_name(data)

	if EditorInterface.has_method("mark_scene_as_unsaved"):
		EditorInterface.call("mark_scene_as_unsaved")
	var save_error := EditorInterface.save_scene()
	if save_error != OK:
		_set_status(
			"模型已新增，但自动保存失败：%s。请按 Ctrl+S 重试。" % error_string(save_error),
			true
		)
	else:
		_set_status("已新增并保存：%s（%s）。" % [display_name, semantic_id], false)
	if _new_model_name_edit:
		_new_model_name_edit.text = ""

	_select_created_parent(parent)
	_run_validation(false)


func _select_created_parent(p_parent: Node) -> void:
	if p_parent == null or not _belongs_to_edited_root(p_parent):
		p_parent = _edited_root
	if p_parent == null:
		return
	_selected_node = p_parent
	var editor_selection = _editor_selection()
	if editor_selection:
		editor_selection.clear()
		editor_selection.add_node(p_parent)
		_refresh_selection()


func _editor_selection():
	if not Engine.is_editor_hint():
		return null
	return EditorInterface.get_selection()


func _model_instance_parent() -> Node:
	if not _selected_node or not _belongs_to_edited_root(_selected_node):
		return _edited_root
	var selection := _selected_node
	var selected_name := str(selection.name)
	if (
		selected_name.begins_with(VisualCatalog.VISUAL_PREFIX)
		or selected_name.begins_with(VisualCatalog.EFFECT_PREFIX)
	):
		selection = selection.get_parent()
	var selected_data := Schema.data_from_node(selection)
	if str(selected_data.get("kind", "")) in ["zone", "region"]:
		return selection
	var candidate := selection.get_parent()
	if candidate and _belongs_to_edited_root(candidate):
		return candidate
	return _edited_root


func _environment_parent() -> Node:
	if _selected_node and EnvironmentCatalog.is_environment_node(_selected_node):
		var parent := _selected_node.get_parent()
		if parent and _belongs_to_edited_root(parent):
			return parent
	return _model_instance_parent()


func _on_remove_model_pressed() -> void:
	if not _selected_node:
		_set_status("先选择一个语义宿主节点。", true)
		return
	var data := Schema.data_from_node(_selected_node)
	if data.is_empty():
		_set_status("选中节点没有语义，无法记录模型变更。", true)
		return
	var removed := VisualCatalog.remove_model(_selected_node)
	var params: Dictionary = data.get("params", {}).duplicate(true)
	params.erase("visual")
	data["params"] = params
	data = Schema.apply_to_node(_selected_node, data)
	_selected_node.name = Schema.node_name(data)
	_params_edit.text = JSON.stringify(params, "\t", true)
	if EditorInterface.has_method("mark_scene_as_unsaved"):
		EditorInterface.call("mark_scene_as_unsaved")
	var save_error := EditorInterface.save_scene()
	if save_error != OK:
		_set_status(
			"已移除模型，但自动保存失败：%s。请按 Ctrl+S 重试。" % error_string(save_error),
			true
		)
	else:
		_set_status("已移除并保存 %d 个可视模型节点。" % removed, false)
	_refresh_selection()


func _on_recommend_models_pressed() -> void:
	if not _edited_root:
		_set_status("没有打开的作者场景。", true)
		return
	_recommended_models_dialog.popup_centered(Vector2i(560, 220))


func _on_open_scene_pressed() -> void:
	var region_id := Schema.sanitize_token(_region_edit.text)
	if region_id.is_empty():
		_set_status("region_id 不能为空。", true)
		return
	var scene_path := "res://authoring/scenes/%s_authoring.tscn" % region_id
	if not FileAccess.file_exists(scene_path):
		_set_status("作者场景不存在：%s。请先点击“从 JSON 生成”。" % scene_path, true)
		return
	EditorInterface.open_scene_from_path(scene_path)
	_set_status("正在打开作者场景：%s" % scene_path, false)


func _on_save_scene_pressed() -> void:
	if not _edited_root:
		_set_status("没有打开的作者场景。", true)
		return
	var save_error := EditorInterface.save_scene()
	if save_error != OK:
		_set_status("保存场景失败：%s" % error_string(save_error), true)
		return
	_set_status("已保存当前场景：%s" % str(_edited_root.scene_file_path), false)


func _on_recommended_models_confirmed() -> void:
	if not _edited_root:
		return
	var result := VisualCatalog.apply_recommended_models(_edited_root, _edited_root)
	if EditorInterface.has_method("mark_scene_as_unsaved"):
		EditorInterface.call("mark_scene_as_unsaved")
	var failed := int(result.get("failed", 0))
	var save_error := EditorInterface.save_scene()
	var save_text := "已自动保存。" if save_error == OK else "自动保存失败：%s。请按 Ctrl+S 重试。" % error_string(save_error)
	var remaining: Array = result.get("remaining_unregistered", [])
	var status := "推荐模型：识别登记 %d，新应用 %d，修复 %d，跳过 %d，失败 %d，剩余未登记 %d。%s" % [
		int(result.get("registered", 0)),
		int(result.get("applied", 0)),
		int(result.get("repaired", 0)),
		int(result.get("skipped", 0)),
		failed,
		remaining.size(),
		save_text,
	]
	_set_status(status, failed > 0 or save_error != OK)
	var report_lines: Array[String] = []
	for error in result.get("errors", []):
		report_lines.append(str(error))
	if not remaining.is_empty():
		report_lines.append("剩余未登记节点（需选中后手动填写语义）：%s" % ", ".join(remaining.slice(0, 12).map(func(value: Variant) -> String: return str(value))))
		if remaining.size() > 12:
			report_lines.append("其余未登记节点：%d 个。" % (remaining.size() - 12))
	if not report_lines.is_empty():
		_validation_output.text = "\n".join(report_lines)
	_refresh_selection()
	_run_validation(false)


func _on_create_scene_pressed() -> void:
	var region_id := Schema.sanitize_token(_region_edit.text)
	if region_id.is_empty():
		_set_status("region_id 不能为空。", true)
		return
	var scene_path := "res://authoring/scenes/%s_authoring.tscn" % region_id
	if FileAccess.file_exists(scene_path):
		EditorInterface.open_scene_from_path(scene_path)
		_set_status("场景已存在，直接打开：%s" % scene_path, false)
		return
	_ensure_project_dir(scene_path.get_base_dir())
	var root := Node3D.new()
	root.name = "FS_REGION_%s" % region_id.to_upper()
	var result := Scaffold.load_and_build(root, "res://content/route/first_night_region.json")
	if result.has("error"):
		root.free()
		_set_status(str(result["error"]), true)
		return
	_assign_owner(root, root)
	var packed := PackedScene.new()
	var pack_error := packed.pack(root)
	if pack_error != OK:
		root.free()
		_set_status("作者场景打包失败：%s" % error_string(pack_error), true)
		return
	var save_error := ResourceSaver.save(packed, scene_path)
	root.free()
	if save_error != OK:
		_set_status("作者场景保存失败：%s" % error_string(save_error), true)
		return
	EditorInterface.open_scene_from_path(scene_path)
	_set_status("已生成作者场景：%s" % scene_path, false)


func _run_validation(p_export: bool) -> bool:
	_edited_root = EditorInterface.get_edited_scene_root()
	if not _edited_root:
		_set_status("没有打开的场景。", true)
		return false
	var region_id := Schema.sanitize_token(_region_edit.text)
	var scene_path := str(_edited_root.scene_file_path)
	if p_export and not _save_edited_scene_for_publish(scene_path):
		return false
	_last_manifest = Manifest.build(_edited_root, scene_path, region_id)
	var validation: Dictionary = _last_manifest.get("validation", {})
	var errors: Array = validation.get("errors", [])
	var warnings: Array = validation.get("warnings", [])
	var lines: Array[String] = [
		"物件：%d" % int(_last_manifest.get("object_count", 0)),
		"错误：%d" % errors.size(),
		"警告：%d" % warnings.size(),
	]
	var support_counts := {
		"runtime": 0,
		"native": 0,
		"marker": 0,
		"pending": 0,
		"none": 0,
	}
	for object in _last_manifest.get("objects", []):
		var support := str(object.get("runtime_support", "none"))
		support_counts[support] = int(support_counts.get(support, 0)) + 1
	lines.append("接管：runtime=%d native=%d marker=%d pending=%d none=%d" % [
		int(support_counts["runtime"]),
		int(support_counts["native"]),
		int(support_counts["marker"]),
		int(support_counts["pending"]),
		int(support_counts["none"]),
	])
	for error in errors:
		lines.append("ERROR  %s" % str(error))
	for warning in warnings:
		lines.append("WARN   %s" % str(warning))
	_validation_output.text = "\n".join(lines)
	if p_export:
		if not errors.is_empty():
			_set_status("存在语义错误，不能导出。", true)
			return false
		var write_result := Manifest.write_manifest(_last_manifest)
		if not bool(write_result.get("ok", false)):
			_set_status(str(write_result.get("error", "导出失败")), true)
			return false
		var publish_result := Runtime.publish(
			_last_manifest,
			str(write_result.get("json_path", "")),
			scene_path
		)
		if not bool(publish_result.get("ok", false)):
			_set_status(str(publish_result.get("error", "发布失败")), true)
			return false
		_set_status("已导出并发布：%s" % str(publish_result.get("binding_path", "")), false)
	elif not errors.is_empty():
		_set_status("校验发现 %d 个错误。" % errors.size(), true)
	else:
		_set_status("校验通过，%d 个警告。" % warnings.size(), false)
	_refresh_workflow()
	return errors.is_empty()


func _refresh_workflow() -> void:
	var region_id := Schema.sanitize_token(_region_edit.text)
	if region_id.is_empty():
		region_id = "first_night"
	_workflow_path = Workflow.path_for_region(region_id)
	var scene_path := Runtime.scene_path_for_region(region_id)
	_workflow_document = Workflow.load_or_create(_workflow_path, region_id, scene_path)
	if str(_workflow_document.get("region_id", "")) != region_id:
		_workflow_document = Workflow.create_document(region_id, scene_path)
		Workflow.save(_workflow_path, _workflow_document)
	if str(_workflow_document.get("status", "")) == "COMPLETE":
		_workflow_progress.text = "%s\n\n[完成] 工作流已全部确认" % Workflow.progress_text(_workflow_document)
		_workflow_step_label.text = "工作流完成"
		_workflow_owner_label.text = "可开始新的区域或新的里程碑。"
		_workflow_prompt_label.text = ""
		_workflow_confirm_button.disabled = true
		return
	var step := Workflow.current_step(_workflow_document)
	_workflow_progress.text = Workflow.progress_text(_workflow_document)
	_workflow_step_label.text = str(step.get("title", ""))
	_workflow_owner_label.text = "负责：%s\n%s" % [str(step.get("owner", "")), str(step.get("instruction", ""))]
	_workflow_prompt_label.text = "确认提示：%s" % str(step.get("prompt", ""))
	_workflow_confirm_button.disabled = false


func _on_confirm_workflow_pressed() -> void:
	if _workflow_document.is_empty():
		return
	var step := Workflow.current_step(_workflow_document)
	var step_id := str(step.get("id", ""))
	if step_id == "semantic_audit" or step_id == "manifest_export":
		if not _run_validation(step_id == "manifest_export"):
			return
		if step_id == "semantic_audit":
			var validation: Dictionary = _last_manifest.get("validation", {})
			if not validation.get("errors", []).is_empty():
				_set_status("请先清除语义错误。", true)
				return
	_confirm_dialog.dialog_text = "%s\n\n确认后进入下一节点。\n\n备注：%s" % [
		str(step.get("prompt", "")),
		_workflow_note_edit.text.strip_edges() if not _workflow_note_edit.text.strip_edges().is_empty() else "无",
	]
	_confirm_dialog.popup_centered(Vector2i(520, 220))


func _on_workflow_confirmed() -> void:
	if _workflow_document.is_empty():
		return
	Workflow.confirm_current(_workflow_document, _workflow_note_edit.text.strip_edges())
	Workflow.save(_workflow_path, _workflow_document)
	_workflow_note_edit.text = ""
	_set_status("已确认工作流节点。", false)
	_refresh_workflow()


func _set_form_enabled(p_enabled: bool) -> void:
	for control in [
		_id_edit,
		_display_name_edit,
		_zone_edit,
		_kind_option,
		_behavior_option,
		_tags_edit,
		_links_edit,
		_params_edit,
		_model_apply_button,
		_model_remove_button,
		_effect_option,
		_effect_apply_button,
		_effect_remove_button,
		_environment_option,
		_environment_create_button,
		_environment_remove_button,
		_apply_button,
		_clear_button,
	]:
		if not control:
			continue
		if control is LineEdit:
			control.editable = p_enabled
		elif control is TextEdit:
			control.editable = p_enabled
		elif control is BaseButton or control is OptionButton:
			control.disabled = not p_enabled
	var has_scene := _edited_root != null
	if _model_filter_edit:
		_model_filter_edit.editable = has_scene
	if _model_category_option:
		_model_category_option.disabled = not has_scene
	if _model_list:
		_model_list.mouse_filter = Control.MOUSE_FILTER_STOP if has_scene else Control.MOUSE_FILTER_IGNORE
	if _new_model_name_edit:
		_new_model_name_edit.editable = has_scene
	if _model_recommend_button:
		_model_recommend_button.disabled = not has_scene
	if _model_ground_button:
		_model_ground_button.disabled = not has_scene
	if _model_support_button:
		_model_support_button.disabled = not has_scene
	if _environment_name_edit:
		_environment_name_edit.editable = has_scene
	if _environment_create_button:
		_environment_create_button.disabled = not has_scene
	if _environment_remove_button:
		_environment_remove_button.disabled = not has_scene or not EnvironmentCatalog.is_environment_node(_selected_node)
	if _paint_preset_option:
		_paint_preset_option.disabled = not has_scene
	if _paint_shape_option:
		_paint_shape_option.disabled = not has_scene
	if _paint_radius_slider:
		_paint_radius_slider.editable = has_scene
	if _paint_opacity_slider:
		_paint_opacity_slider.editable = has_scene
	if _paint_toggle_button:
		_paint_toggle_button.disabled = not has_scene
	if _paint_remove_button:
		_paint_remove_button.disabled = not has_scene or not GroundPaintCatalog.is_paint_node(_selected_node)
	_refresh_create_button_state()


func _set_status(p_text: String, p_is_error: bool) -> void:
	_status_label.text = p_text
	_status_label.add_theme_color_override("font_color", Color("#ff8d8d") if p_is_error else Color("#b9d7c3"))


func _runtime_support_text(p_support: String) -> String:
	match p_support:
		"runtime":
			return "Codex 接管：runtime（按语义注入并实现）"
		"native":
			return "Codex 接管：native（保留 Godot 原生物理）"
		"marker":
			return "Codex 接管：marker（读取点位与坐标）"
		"pending":
			return "Codex 接管：pending（已登记，功能待实现）"
	return "Codex 接管：none（纯场景物件）"


func _fill_options(p_option: OptionButton, p_options: Array[Dictionary]) -> void:
	p_option.clear()
	for item in p_options:
		p_option.add_item(str(item["label"]))
		p_option.set_item_metadata(p_option.item_count - 1, str(item["id"]))


func _select_option(p_option: OptionButton, p_id: String) -> void:
	for index in range(p_option.item_count):
		if str(p_option.get_item_metadata(index)) == p_id:
			p_option.select(index)
			return


func _selected_option(p_option: OptionButton) -> String:
	var index := p_option.selected
	if index < 0:
		return ""
	return str(p_option.get_item_metadata(index))


func _suggest_id(p_node: Node) -> String:
	var parent_hint := ""
	if p_node.get_parent():
		parent_hint = str(p_node.get_parent().name).to_lower()
	var base := Schema.sanitize_token(str(p_node.name))
	if base.begins_with("fs_"):
		base = base.trim_prefix("fs_")
	if parent_hint.begins_with("fs_zone_"):
		parent_hint = parent_hint.trim_prefix("fs_zone_")
	return Schema.sanitize_token("%s_%s" % [parent_hint, base] if not parent_hint.is_empty() else base)


func _next_visual_instance_id(p_model_id: String) -> String:
	var model_token := Schema.sanitize_token(p_model_id)
	var used := {}
	_collect_semantic_ids(_edited_root, used)
	var index := 1
	while true:
		var candidate := Schema.sanitize_token("visual_%s_%d" % [model_token, index])
		if not used.has(candidate):
			return candidate
		index += 1
	return Schema.sanitize_token("visual_%s" % model_token)


func _collect_semantic_ids(p_node: Node, p_result: Dictionary) -> void:
	var data := Schema.data_from_node(p_node)
	var semantic_id := str(data.get("semantic_id", ""))
	if not semantic_id.is_empty():
		p_result[semantic_id] = true
	for child in p_node.get_children():
		_collect_semantic_ids(child, p_result)


func _belongs_to_edited_root(p_node: Node) -> bool:
	var current: Node = p_node
	while current != null:
		if current == _edited_root:
			return true
		current = current.get_parent()
	return false


func _zone_id_for_parent(p_parent: Node) -> String:
	var parent_data := Schema.data_from_node(p_parent)
	if str(parent_data.get("kind", "")) == "zone":
		return str(parent_data.get("semantic_id", ""))
	return str(parent_data.get("zone_id", ""))


func _suggest_kind(p_node: Node) -> String:
	if p_node is Node3D:
		return "prop"
	return "trigger"


func _add_heading(p_parent: Control, p_text: String) -> void:
	var separator := HSeparator.new()
	p_parent.add_child(separator)
	var label := Label.new()
	label.text = p_text
	label.add_theme_font_size_override("font_size", 15)
	p_parent.add_child(label)


func _add_form_label(p_parent: Control, p_text: String) -> void:
	var label := Label.new()
	label.text = p_text
	p_parent.add_child(label)


func _assign_owner(p_node: Node, p_owner: Node) -> void:
	for child in p_node.get_children():
		child.owner = p_owner
		_assign_owner(child, p_owner)


func _ensure_project_dir(p_path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(p_path))


func _save_edited_scene_for_publish(p_scene_path: String) -> bool:
	if p_scene_path.is_empty():
		_set_status("当前场景没有保存路径，无法发布。", true)
		return false
	var save_error := EditorInterface.save_scene()
	if save_error != OK:
		_set_status("作者场景保存失败：%s" % error_string(save_error), true)
		return false
	return true
