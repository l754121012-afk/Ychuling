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
const TerrainBrushCatalog := preload("res://scripts/authoring/FSTerrainBrushCatalog.gd")
const ModelPreview := preload("res://scripts/authoring/FSModelPreview.gd")
const GameView := preload("res://scripts/authoring/FSGameView.gd")
const PlaytestMode := preload("res://scripts/authoring/FSPlaytestMode.gd")
const ADDON_VERSION := "0.4.7"
const TOGGLE_ACTIVE_BG := Color("#c96b12")
const TOGGLE_ACTIVE_BG_HOVER := Color("#e07d18")
const TOGGLE_ACTIVE_BG_PRESSED := Color("#a9550b")
const TOGGLE_ACTIVE_BORDER := Color("#ffd089")
const TOGGLE_ACTIVE_TEXT := Color("#1d1207")
const TERRAIN_MODE_NONE := "none"
const TERRAIN_MODE_BRUSH := "brush"
const TERRAIN_MODE_ERASER := "eraser"
const TERRAIN_MODE_ADJUST := "adjust"
const TERRAIN_MODE_MULTI := "multiselect"
const TERRAIN_MODE_PAINT := "paint"
const GROUP_TERRAIN := "FS_GROUP_地形"
const GROUP_BUILDINGS := "FS_GROUP_建筑"
const GROUP_OBJECTS := "FS_GROUP_物件"
const GROUP_CHARACTERS := "FS_GROUP_角色"
const GROUP_EFFECTS := "FS_GROUP_特效"
const SCENE_GROUP_NAMES := [
	GROUP_TERRAIN,
	GROUP_BUILDINGS,
	GROUP_OBJECTS,
	GROUP_CHARACTERS,
	GROUP_EFFECTS,
]
const TERRAIN_MODEL_CATEGORIES := [
	"地形与平台",
	"城镇道路",
	"雨城水文",
	"围栏与墙",
	"地牢结构",
]
const BUILDING_MODEL_CATEGORIES := [
	"门与出入口",
	"墓园建筑",
	"城镇建筑",
]
const CHARACTER_MODEL_CATEGORIES := [
	"角色占位",
]
const MODEL_GALLERY_PATH := "res://authoring/scenes/model_gallery.tscn"

var _selected_node: Node
var _edited_root: Node
var _last_model_parent: Node
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
var _terrain_preset_option: OptionButton
var _terrain_shape_option: OptionButton
var _terrain_size_option: OptionButton
var _terrain_height_spin: SpinBox
var _terrain_thickness_spin: SpinBox
var _terrain_toggle_button: Button
var _terrain_adjust_button: Button
var _terrain_eraser_button: Button
var _terrain_multiselect_button: Button
var _terrain_apply_cell_button: Button
var _terrain_delete_cell_button: Button
var _terrain_eyedropper_button: Button
var _terrain_select_group_button: Button
var _terrain_copy_group_button: Button
var _terrain_clear_button: Button
var _terrain_status_label: Label
var _terrain_clear_dialog: ConfirmationDialog
var _terrain_brush_mode_active := false
var _terrain_eraser_mode_active := false
var _terrain_adjust_mode_active := false
var _terrain_multiselect_mode_active := false
var _terrain_has_selected_cell := false
var _terrain_selected_cell := Vector3i.ZERO
var _terrain_selected_cells: Dictionary = {}
var _terrain_selection_preview: Node3D
var _terrain_selection_mesh: BoxMesh
var _terrain_selection_material: StandardMaterial3D
var _terrain_stroke_active := false
var _terrain_stroke_changed := 0
var _terrain_stroke_added := 0
var _terrain_stroke_replaced := 0
var _terrain_stroke_erased := 0
var _terrain_last_cell := Vector3i.ZERO
var _terrain_has_last_cell := false
var _terrain_multiselect_stroke_active := false
var _terrain_multiselect_append := false
var _terrain_multiselect_last_cell := Vector3i.ZERO
var _terrain_multiselect_has_last_cell := false
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
var _focus_panning := false


func _ready() -> void:
	_build_ui()
	call_deferred("on_scene_changed")


func on_scene_changed() -> void:
	if not Engine.is_editor_hint():
		return
	_set_terrain_mode(TERRAIN_MODE_NONE, false)
	_edited_root = EditorInterface.get_edited_scene_root()
	if _last_model_parent == _edited_root:
		_last_model_parent = null
	if (
		_last_model_parent != null
		and (
			not is_instance_valid(_last_model_parent)
			or not _belongs_to_edited_root(_last_model_parent)
		)
	):
		_last_model_parent = null
	if _edited_root:
		var edited_scene_path := _edited_root.scene_file_path
		var root_data := Schema.data_from_node(_edited_root)
		var root_kind := str(root_data.get("kind", ""))
		var root_semantic_id := str(root_data.get("semantic_id", ""))
		if (
			PlaytestMode.is_authoring_scene_path(edited_scene_path)
			and root_kind == "region"
			and not root_semantic_id.is_empty()
		):
			PlaytestMode.set_scene_path(edited_scene_path)
		if not root_semantic_id.is_empty() and root_kind == "region":
			_region_edit.text = root_semantic_id
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
	_playtest_build_button.tooltip_text = "F5 加载正式作者场景、玩家和实际跟随相机；优先落到场景承托面，只有完全无碰撞时才使用临时 y=0 兜底地面。不生成案件、敌人、NPC、地图或 HUD。"
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
	_model_create_button.tooltip_text = "直接把列表中的模型做成带中文名和稳定 semantic_id 的新物件，并自动放入地形、建筑、物件、角色或特效分类组；当前区域语义仍会写入 zone_id。"
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

	_add_heading(content, "地形画笔（实体）")
	var terrain_brush_help := Label.new()
	terrain_brush_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	terrain_brush_help.text = "在三维视图中按住左键连续刷出带碰撞的实体地形。画笔优先创建在当前选中节点的同一级；已有多个画笔时，绘制、擦除和选格会跟随当前选中节点所在上下文，而不是固定找第一个。移动网格节点后重新选中它或其父级仍可继续编辑；未选节点时才回退到 FS_GROUP_地形。按 1 米格自动吸附、同格覆盖去重。绘制、橡皮擦、单格选择和多格选择互斥。"
	content.add_child(terrain_brush_help)
	_terrain_preset_option = OptionButton.new()
	_terrain_preset_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_terrain_preset_option.fit_to_longest_item = false
	_terrain_preset_option.clip_text = true
	_terrain_preset_option.item_selected.connect(_on_terrain_preset_selected)
	content.add_child(_terrain_preset_option)
	var terrain_brush_row := HBoxContainer.new()
	content.add_child(terrain_brush_row)
	var terrain_shape_label := Label.new()
	terrain_shape_label.text = "笔刷形状"
	terrain_brush_row.add_child(terrain_shape_label)
	_terrain_shape_option = OptionButton.new()
	_terrain_shape_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	terrain_brush_row.add_child(_terrain_shape_option)
	_terrain_size_option = OptionButton.new()
	_terrain_size_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	terrain_brush_row.add_child(_terrain_size_option)
	var terrain_height_row := HBoxContainer.new()
	content.add_child(terrain_height_row)
	var terrain_height_label := Label.new()
	terrain_height_label.text = "垂直层（每层 1 米）"
	terrain_height_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	terrain_height_row.add_child(terrain_height_label)
	_terrain_height_spin = SpinBox.new()
	_terrain_height_spin.min_value = TerrainBrushCatalog.MIN_HEIGHT_LEVEL
	_terrain_height_spin.max_value = TerrainBrushCatalog.MAX_HEIGHT_LEVEL
	_terrain_height_spin.step = 1.0
	_terrain_height_spin.value = 0.0
	_terrain_height_spin.allow_greater = false
	_terrain_height_spin.allow_lesser = false
	_terrain_height_spin.custom_minimum_size = Vector2(92.0, 0.0)
	terrain_height_row.add_child(_terrain_height_spin)
	var terrain_thickness_row := HBoxContainer.new()
	content.add_child(terrain_thickness_row)
	var terrain_thickness_label := Label.new()
	terrain_thickness_label.text = "每格厚度（米）"
	terrain_thickness_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	terrain_thickness_row.add_child(terrain_thickness_label)
	_terrain_thickness_spin = SpinBox.new()
	_terrain_thickness_spin.min_value = TerrainBrushCatalog.MIN_THICKNESS
	_terrain_thickness_spin.max_value = TerrainBrushCatalog.MAX_THICKNESS
	_terrain_thickness_spin.step = TerrainBrushCatalog.THICKNESS_STEP
	_terrain_thickness_spin.value = TerrainBrushCatalog.default_thickness("grass_platform")
	_terrain_thickness_spin.allow_greater = false
	_terrain_thickness_spin.allow_lesser = false
	_terrain_thickness_spin.custom_minimum_size = Vector2(92.0, 0.0)
	terrain_thickness_row.add_child(_terrain_thickness_spin)
	var terrain_paint_mode_row := HBoxContainer.new()
	content.add_child(terrain_paint_mode_row)
	_terrain_toggle_button = Button.new()
	_terrain_toggle_button.text = "绘制"
	_terrain_toggle_button.tooltip_text = "开启后左键拖动连续刷实体地形。"
	_terrain_toggle_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_terrain_toggle_button.pressed.connect(_on_toggle_terrain_brush_pressed)
	terrain_paint_mode_row.add_child(_terrain_toggle_button)
	_terrain_eraser_button = Button.new()
	_terrain_eraser_button.text = "橡皮擦"
	_terrain_eraser_button.tooltip_text = "开启后左键拖动擦除画笔地形；使用当前笔刷形状、尺寸和垂直层。"
	_terrain_eraser_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_terrain_eraser_button.pressed.connect(_on_toggle_terrain_eraser_pressed)
	terrain_paint_mode_row.add_child(_terrain_eraser_button)
	var terrain_select_mode_row := HBoxContainer.new()
	content.add_child(terrain_select_mode_row)
	_terrain_adjust_button = Button.new()
	_terrain_adjust_button.text = "单格选择"
	_terrain_adjust_button.tooltip_text = "左键点选单格；按住 Ctrl 左键可继续加选或减选。"
	_terrain_adjust_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_terrain_adjust_button.pressed.connect(_on_toggle_terrain_adjust_pressed)
	terrain_select_mode_row.add_child(_terrain_adjust_button)
	_terrain_multiselect_button = Button.new()
	_terrain_multiselect_button.text = "多格选择"
	_terrain_multiselect_button.tooltip_text = "左键拖动时使用当前笔刷形状和尺寸批量加选；按住 Ctrl 拖动可从已选中移除。快捷键 Ctrl+Alt+3。"
	_terrain_multiselect_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_terrain_multiselect_button.pressed.connect(_on_toggle_terrain_multiselect_pressed)
	terrain_select_mode_row.add_child(_terrain_multiselect_button)
	var terrain_cell_action_row := HBoxContainer.new()
	content.add_child(terrain_cell_action_row)
	_terrain_apply_cell_button = Button.new()
	_terrain_apply_cell_button.text = "批量应用到选中格"
	_terrain_apply_cell_button.tooltip_text = "把当前地形、厚度和垂直层覆盖到所有已选中格。"
	_terrain_apply_cell_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_terrain_apply_cell_button.pressed.connect(_on_apply_terrain_cell_pressed)
	terrain_cell_action_row.add_child(_terrain_apply_cell_button)
	_terrain_delete_cell_button = Button.new()
	_terrain_delete_cell_button.text = "批量删除选中格"
	_terrain_delete_cell_button.tooltip_text = "删除所有已选中的画笔格，其他格子保持不变。"
	_terrain_delete_cell_button.pressed.connect(_on_delete_terrain_cell_pressed)
	terrain_cell_action_row.add_child(_terrain_delete_cell_button)
	_terrain_eyedropper_button = Button.new()
	_terrain_eyedropper_button.text = "吸取主选格"
	_terrain_eyedropper_button.tooltip_text = "把主选格的地形、厚度和垂直层复制到当前画笔参数。"
	_terrain_eyedropper_button.pressed.connect(_on_eyedropper_terrain_cell_pressed)
	terrain_cell_action_row.add_child(_terrain_eyedropper_button)
	var terrain_group_row := HBoxContainer.new()
	content.add_child(terrain_group_row)
	_terrain_select_group_button = Button.new()
	_terrain_select_group_button.text = "选中整组地形"
	_terrain_select_group_button.tooltip_text = "在场景树中选中共享 GridMap；随后可用 Godot 的移动、旋转和复制工具整体操作。"
	_terrain_select_group_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_terrain_select_group_button.pressed.connect(_on_select_terrain_group_pressed)
	terrain_group_row.add_child(_terrain_select_group_button)
	_terrain_copy_group_button = Button.new()
	_terrain_copy_group_button.text = "复制整组并偏移"
	_terrain_copy_group_button.tooltip_text = "复制整个实体地形网格到一个独立副本，并沿网格外接范围向侧面偏移。"
	_terrain_copy_group_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_terrain_copy_group_button.pressed.connect(_on_copy_terrain_group_pressed)
	terrain_group_row.add_child(_terrain_copy_group_button)
	var terrain_clear_row := HBoxContainer.new()
	content.add_child(terrain_clear_row)
	_terrain_clear_button = Button.new()
	_terrain_clear_button.text = "清空画笔地形"
	_terrain_clear_button.tooltip_text = "清空本场景中由实体地形画笔创建的全部格子；不会删除原有手工地形节点。"
	_terrain_clear_button.pressed.connect(_on_clear_terrain_brush_pressed)
	_terrain_clear_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	terrain_clear_row.add_child(_terrain_clear_button)
	_terrain_status_label = Label.new()
	_terrain_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_terrain_status_label.text = "画笔关闭。选择地形后开启，按住左键拖动即可连续铺设。"
	content.add_child(_terrain_status_label)
	_terrain_clear_dialog = ConfirmationDialog.new()
	_terrain_clear_dialog.title = "清空实体地形画笔"
	_terrain_clear_dialog.dialog_text = "将清除 FS_TERRAIN_BRUSH_地形画笔 网格中的全部格子。\n\n原有手工摆放的地形、建筑和物件不会被删除。是否继续？"
	_terrain_clear_dialog.confirmed.connect(_on_clear_terrain_brush_confirmed)
	add_child(_terrain_clear_dialog)
	_populate_terrain_brush_options()

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
		KEY_3:
			_on_toggle_terrain_multiselect_pressed()
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
	_focus_panning = false
	_game_view_active = false
	_focus_view_active = true
	_focus_view_description = _focus_selection_description(selected_nodes)
	_refresh_view_status()
	_set_status(
		"已舒适聚焦：%s。中键拖动环绕，Shift+中键平移，滚轮缩放；Shift+F 可再次取景。%s" % [
			_focus_view_description,
			"当前按无可见几何体回退到节点中心。" if bool(bounds.get("fallback", false)) else "",
		],
		false
	)


func handle_editor_3d_gui_input(p_camera: Camera3D, p_event: InputEvent) -> int:
	if _terrain_group_selection_active():
		return 0
	if _terrain_adjust_mode_active and p_camera != null:
		var adjust_result := _handle_terrain_adjust_input(p_camera, p_event)
		if adjust_result != 0:
			return adjust_result
	if (_terrain_brush_mode_active or _terrain_eraser_mode_active) and p_camera != null:
		var terrain_result := _handle_terrain_brush_input(p_camera, p_event)
		if terrain_result != 0:
			return terrain_result
	if _paint_mode_active and p_camera != null:
		var paint_result := _handle_ground_paint_input(p_camera, p_event)
		if paint_result != 0:
			return paint_result
	if not _focus_view_active or p_camera == null:
		return 0
	if p_event is InputEventMouseButton:
		var button_event := p_event as InputEventMouseButton
		if button_event.button_index == MOUSE_BUTTON_MIDDLE:
			_focus_orbiting = button_event.pressed and not button_event.shift_pressed
			_focus_panning = button_event.pressed and button_event.shift_pressed
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
	if p_event is InputEventMouseMotion and (_focus_orbiting or _focus_panning):
		var motion := p_event as InputEventMouseMotion
		if _focus_panning:
			var viewport_height := 720.0
			var viewport := p_camera.get_viewport()
			if viewport:
				viewport_height = viewport.get_visible_rect().size.y
			var units_per_pixel := GameView.focus_pan_units_per_pixel(
				_focus_distance,
				p_camera.fov,
				viewport_height
			)
			var camera_basis := p_camera.global_transform.basis
			var camera_right := camera_basis.x.normalized()
			var camera_up := camera_basis.y.normalized()
			_focus_center += (
				-camera_right * motion.relative.x
				+ camera_up * motion.relative.y
			) * units_per_pixel
		else:
			var orbit := GameView.focus_orbit_step(motion.relative, _focus_radius)
			_focus_yaw_degrees += float(orbit["yaw_delta"])
			_focus_elevation_degrees = clampf(
				_focus_elevation_degrees + float(orbit["elevation_delta"]),
				GameView.FOCUS_MIN_ELEVATION_DEGREES,
				GameView.FOCUS_MAX_ELEVATION_DEGREES
			)
		_apply_focus_camera(p_camera)
		return 1
	return 0


func _handle_terrain_brush_input(p_camera: Camera3D, p_event: InputEvent) -> int:
	if p_event is InputEventMouseButton:
		var button_event := p_event as InputEventMouseButton
		if button_event.button_index != MOUSE_BUTTON_LEFT:
			return 0
		if button_event.pressed:
			_terrain_stroke_active = true
			_terrain_stroke_changed = 0
			_terrain_stroke_added = 0
			_terrain_stroke_replaced = 0
			_terrain_stroke_erased = 0
			_terrain_has_last_cell = false
			_terrain_brush_at_editor_position(p_camera, button_event.position, true)
			return 1
		if _terrain_stroke_active:
			_terrain_stroke_active = false
			_terrain_has_last_cell = false
			var saved := _commit_terrain_brush_stroke()
			_refresh_terrain_clear_button_state()
			_terrain_status_label.text = (
				"本笔已保存：新增 %d 格，覆盖 %d 格，擦除 %d 格。继续左键拖动或关闭画笔。"
				% [
					_terrain_stroke_added,
					_terrain_stroke_replaced,
					_terrain_stroke_erased,
				]
				if saved
				else "本笔已完成，但自动保存失败；请按 Ctrl+S。"
			)
			_terrain_stroke_changed = 0
			return 1
	if p_event is InputEventMouseMotion and _terrain_stroke_active:
		var motion := p_event as InputEventMouseMotion
		if motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_terrain_brush_at_editor_position(p_camera, motion.position, false)
			return 1
	return 0


func _handle_terrain_adjust_input(p_camera: Camera3D, p_event: InputEvent) -> int:
	if p_event is InputEventMouseButton:
		var button_event := p_event as InputEventMouseButton
		if button_event.button_index != MOUSE_BUTTON_LEFT:
			return 0
		if button_event.pressed:
			if _terrain_multiselect_mode_active:
				_terrain_multiselect_stroke_active = true
				_terrain_multiselect_append = not button_event.ctrl_pressed
				_terrain_multiselect_has_last_cell = false
				_select_terrain_cells_at_editor_position(
					p_camera,
					button_event.position,
					true,
					button_event.ctrl_pressed
				)
			else:
				_select_terrain_cell_at_editor_position(
					p_camera,
					button_event.position,
					button_event.ctrl_pressed
				)
			return 1
		if _terrain_multiselect_stroke_active:
			_terrain_multiselect_stroke_active = false
			_terrain_multiselect_has_last_cell = false
			_terrain_multiselect_append = false
			_terrain_status_label.text = _terrain_selection_status_text()
			return 1
	if p_event is InputEventMouseMotion and _terrain_multiselect_stroke_active:
		var motion := p_event as InputEventMouseMotion
		if motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_select_terrain_cells_at_editor_position(
				p_camera,
				motion.position,
				false,
				not _terrain_multiselect_append
			)
			return 1
	return 0


func _select_terrain_cell_at_editor_position(
	p_camera: Camera3D,
	p_screen_position: Vector2,
	p_toggle: bool = false
) -> void:
	var grid_map := _terrain_active_grid_map()
	if grid_map == null or grid_map.get_used_cells().is_empty():
		_clear_terrain_selection()
		_terrain_status_label.text = "当前场景还没有实体地形画笔格子。"
		return
	var hit := _raycast_ground_point(p_camera, p_screen_position)
	if not bool(hit.get("ok", false)):
		_clear_terrain_selection()
		_terrain_status_label.text = str(hit.get("error", "没有找到可选择的实体地形格。"))
		return
	var picked := TerrainBrushCatalog.pick_cell_at_world_position(
		grid_map,
		hit["position"]
	)
	if not bool(picked.get("ok", false)):
		_clear_terrain_selection()
		_terrain_status_label.text = str(
			picked.get("error", "没有选中实体地形格；请点击已有画笔格。")
		)
		return
	var cell: Vector3i = picked.get("cell", Vector3i.ZERO)
	if p_toggle and _terrain_selected_cells.has(cell):
		_terrain_selected_cells.erase(cell)
	else:
		if not p_toggle:
			_terrain_selected_cells.clear()
		_terrain_selected_cells[cell] = picked
		_terrain_selected_cell = cell
	_sync_terrain_selection_primary()
	_refresh_terrain_selection_preview()
	_refresh_terrain_cell_action_state()
	_terrain_status_label.text = _terrain_selection_status_text()


func _select_terrain_cells_at_editor_position(
	p_camera: Camera3D,
	p_screen_position: Vector2,
	p_force: bool,
	p_remove: bool
) -> void:
	var grid_map := _terrain_active_grid_map()
	if grid_map == null or grid_map.get_used_cells().is_empty():
		if p_force:
			_clear_terrain_selection()
			_terrain_status_label.text = "当前场景还没有实体地形画笔格子。"
		return
	var hit := _raycast_ground_point(p_camera, p_screen_position)
	if not bool(hit.get("ok", false)):
		if p_force:
			_terrain_status_label.text = str(hit.get("error", "没有找到可选择的实体地形格。"))
		return
	var center_cell := TerrainBrushCatalog.cell_for_world_position(
		grid_map,
		hit["position"],
		roundi(_terrain_height_spin.value)
	)
	if p_force:
		if not p_remove:
			_terrain_selected_cells.clear()
		_terrain_multiselect_last_cell = center_cell
		_terrain_multiselect_has_last_cell = true
		_apply_terrain_selection_stamp(grid_map, center_cell, p_remove)
	else:
		var from_cell := (
			_terrain_multiselect_last_cell
			if _terrain_multiselect_has_last_cell
			else center_cell
		)
		for stamp_cell in TerrainBrushCatalog.interpolate_cells(from_cell, center_cell):
			_apply_terrain_selection_stamp(grid_map, stamp_cell, p_remove)
		_terrain_multiselect_last_cell = center_cell
		_terrain_multiselect_has_last_cell = true
	_sync_terrain_selection_primary()
	_refresh_terrain_selection_preview()
	_refresh_terrain_cell_action_state()
	_terrain_status_label.text = _terrain_selection_status_text()


func _apply_terrain_selection_stamp(
	p_grid_map: GridMap,
	p_center_cell: Vector3i,
	p_remove: bool
) -> void:
	var offsets := TerrainBrushCatalog.brush_offsets(
		int(_selected_terrain_size()),
		_selected_option(_terrain_shape_option)
	)
	for offset in offsets:
		var cell := p_center_cell + offset
		if p_remove:
			_terrain_selected_cells.erase(cell)
			continue
		var info := TerrainBrushCatalog.get_cell_info(p_grid_map, cell)
		if not bool(info.get("ok", false)):
			continue
		_terrain_selected_cells[cell] = info
		_terrain_selected_cell = cell


func _show_terrain_selection(p_info: Dictionary) -> void:
	var grid_map := _terrain_active_grid_map()
	if grid_map == null or p_info.is_empty():
		_clear_terrain_selection()
		return
	_terrain_selected_cells.clear()
	var cell: Vector3i = p_info.get("cell", Vector3i.ZERO)
	_terrain_selected_cells[cell] = p_info
	_terrain_selected_cell = cell
	_terrain_has_selected_cell = true
	_refresh_terrain_selection_preview()
	_refresh_terrain_cell_action_state()


func _refresh_terrain_selection_preview() -> void:
	var grid_map := _terrain_active_grid_map()
	if grid_map == null or _terrain_selected_cells.is_empty():
		if is_instance_valid(_terrain_selection_preview):
			_terrain_selection_preview.visible = false
			_clear_terrain_selection_preview_instances()
		return
	if not is_instance_valid(_terrain_selection_preview):
		_terrain_selection_preview = Node3D.new()
		_terrain_selection_preview.name = "FS_TERRAIN_SELECTION_PREVIEW"
		_terrain_selection_preview.owner = null
		_terrain_selection_mesh = BoxMesh.new()
		_terrain_selection_mesh.size = Vector3.ONE
		_terrain_selection_material = StandardMaterial3D.new()
		_terrain_selection_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_terrain_selection_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_terrain_selection_material.albedo_color = Color(1.0, 0.82, 0.24, 0.42)
		_terrain_selection_material.emission_enabled = true
		_terrain_selection_material.emission = Color(1.0, 0.58, 0.08)
		_terrain_selection_mesh.material = _terrain_selection_material
		grid_map.add_child(_terrain_selection_preview)
	var cells := _terrain_selected_cells.keys()
	while _terrain_selection_preview.get_child_count() > cells.size():
		var extra := _terrain_selection_preview.get_child(
			_terrain_selection_preview.get_child_count() - 1
		)
		_terrain_selection_preview.remove_child(extra)
		extra.queue_free()
	for index in range(cells.size()):
		var cell: Vector3i = cells[index]
		var info: Dictionary = _terrain_selected_cells[cell]
		var preview_instance := (
			_terrain_selection_preview.get_child(index) as MeshInstance3D
			if index < _terrain_selection_preview.get_child_count()
			else null
		)
		if preview_instance == null:
			preview_instance = MeshInstance3D.new()
			preview_instance.name = "selected_%d" % index
			preview_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			preview_instance.mesh = _terrain_selection_mesh
			preview_instance.owner = null
			_terrain_selection_preview.add_child(preview_instance)
		preview_instance.transform = _terrain_selection_preview_transform(
			grid_map,
			cell,
			info
		)
	_terrain_selection_preview.visible = true


func _clear_terrain_selection_preview_instances() -> void:
	if not is_instance_valid(_terrain_selection_preview):
		return
	for child in _terrain_selection_preview.get_children():
		_terrain_selection_preview.remove_child(child)
		child.queue_free()


func _terrain_selection_preview_transform(
	p_grid_map: GridMap,
	p_cell: Vector3i,
	p_info: Dictionary
) -> Transform3D:
	var thickness := float(p_info.get("thickness", 0.1))
	var cell_basis := p_grid_map.get_cell_item_basis(p_cell)
	return Transform3D(
		cell_basis * Basis.from_scale(Vector3(
			p_grid_map.cell_size.x * 1.04,
			maxf(thickness + 0.08, 0.12),
			p_grid_map.cell_size.z * 1.04
		)),
		p_grid_map.map_to_local(p_cell)
	)


func _sync_terrain_selection_primary() -> void:
	var grid_map := _terrain_active_grid_map()
	var next_selection: Dictionary = {}
	for cell in _terrain_selected_cells.keys():
		var info := TerrainBrushCatalog.get_cell_info(grid_map, cell)
		if bool(info.get("ok", false)):
			next_selection[cell] = info
	_terrain_selected_cells = next_selection
	if _terrain_selected_cells.is_empty():
		_terrain_has_selected_cell = false
		_terrain_selected_cell = Vector3i.ZERO
		return
	if not _terrain_selected_cells.has(_terrain_selected_cell):
		_terrain_selected_cell = _terrain_selected_cells.keys()[0]
	_terrain_has_selected_cell = true


func _terrain_selection_status_text() -> String:
	var count := _terrain_selected_cells.size()
	if count <= 0:
		return "未选中实体地形格；左键点选或拖动框选。"
	if count == 1:
		var info: Dictionary = _terrain_selected_cells[_terrain_selected_cell]
		return "已选中 1 格：%s · %.2f 米 · 垂直层 %d。" % [
			str(info.get("preset_label", info.get("preset_id", "实体地形"))),
			float(info.get("thickness", 0.0)),
			int(info.get("height_level", 0)),
		]
	return "已选中 %d 个实体地形格；可直接批量应用、删除，或吸取主选格参数。" % count


func _clear_terrain_selection() -> void:
	_terrain_has_selected_cell = false
	_terrain_selected_cell = Vector3i.ZERO
	_terrain_selected_cells.clear()
	_terrain_multiselect_stroke_active = false
	_terrain_multiselect_has_last_cell = false
	_terrain_multiselect_append = false
	if is_instance_valid(_terrain_selection_preview):
		_terrain_selection_preview.visible = false
		_clear_terrain_selection_preview_instances()
		_terrain_selection_preview.queue_free()
	_terrain_selection_preview = null
	_terrain_selection_mesh = null
	_terrain_selection_material = null
	_refresh_terrain_cell_action_state()


func _terrain_brush_at_editor_position(
	p_camera: Camera3D,
	p_screen_position: Vector2,
	p_force: bool
) -> void:
	if not _edited_root:
		return
	var grid_result := TerrainBrushCatalog.ensure_grid_map(
		_edited_root,
		_edited_root,
		_selected_node
	)
	if not bool(grid_result.get("ok", false)):
		_terrain_status_label.text = str(grid_result.get("error", "无法创建实体地形网格。"))
		return
	var grid_map := grid_result.get("grid_map") as GridMap
	var hit := _raycast_ground_point(p_camera, p_screen_position)
	if not bool(hit.get("ok", false)):
		if p_force:
			_terrain_status_label.text = str(hit.get("error", "没有找到可绘制的位置。"))
		return
	var params := TerrainBrushCatalog.brush_params(
		(
			TerrainBrushCatalog.ERASER_ID
			if _terrain_eraser_mode_active
			else _selected_option(_terrain_preset_option)
		),
		_selected_option(_terrain_shape_option),
		int(_selected_terrain_size()),
		roundi(_terrain_height_spin.value),
		float(_terrain_thickness_spin.value)
	)
	var cell := TerrainBrushCatalog.cell_for_world_position(
		grid_map,
		hit["position"],
		int(params.get("height_level", 0))
	)
	var result: Dictionary
	if not p_force and _terrain_has_last_cell:
		result = TerrainBrushCatalog.apply_line(grid_map, _terrain_last_cell, cell, params)
	else:
		result = TerrainBrushCatalog.apply_stamp(grid_map, cell, params)
	if not bool(result.get("ok", false)):
		_terrain_status_label.text = str(result.get("error", "实体地形绘制失败。"))
		return
	_terrain_last_cell = cell
	_terrain_has_last_cell = true
	_terrain_stroke_added += int(result.get("added", 0))
	_terrain_stroke_replaced += int(result.get("replaced", 0))
	_terrain_stroke_erased += int(result.get("erased", 0))
	_terrain_stroke_changed += int(result.get("changed", 0))
	_terrain_status_label.text = (
		"正在%s %s：新增 %d，覆盖 %d，擦除 %d；共享网格中共 %d 格。"
		% [
			"擦除" if bool(params.get("is_eraser", false)) else "绘制",
			str(params.get("preset_label", "")),
			_terrain_stroke_added,
			_terrain_stroke_replaced,
			_terrain_stroke_erased,
			int(result.get("used_cells", grid_map.get_used_cells().size())),
		]
	)


func _commit_terrain_brush_stroke() -> bool:
	if _terrain_stroke_changed <= 0:
		return true
	if EditorInterface.has_method("mark_scene_as_unsaved"):
		EditorInterface.call("mark_scene_as_unsaved")
	_refresh_terrain_clear_button_state()
	return EditorInterface.save_scene() == OK


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


func _set_terrain_mode(p_mode: String, p_announce: bool = true) -> void:
	var mode := p_mode
	if mode not in [
		TERRAIN_MODE_NONE,
		TERRAIN_MODE_BRUSH,
		TERRAIN_MODE_ERASER,
		TERRAIN_MODE_ADJUST,
		TERRAIN_MODE_MULTI,
		TERRAIN_MODE_PAINT,
	]:
		mode = TERRAIN_MODE_NONE
	var selection_mode := mode in [TERRAIN_MODE_ADJUST, TERRAIN_MODE_MULTI]
	var had_selection_mode := _terrain_adjust_mode_active
	if mode != TERRAIN_MODE_NONE and _terrain_group_selection_active():
		_end_terrain_group_selection(false)

	_terrain_brush_mode_active = mode == TERRAIN_MODE_BRUSH
	_terrain_eraser_mode_active = mode == TERRAIN_MODE_ERASER
	_terrain_adjust_mode_active = selection_mode
	_terrain_multiselect_mode_active = mode == TERRAIN_MODE_MULTI
	_terrain_stroke_active = false
	_terrain_has_last_cell = false
	if not _terrain_multiselect_mode_active:
		_terrain_multiselect_stroke_active = false
		_terrain_multiselect_has_last_cell = false
		_terrain_multiselect_append = false

	_paint_mode_active = mode == TERRAIN_MODE_PAINT
	_paint_stroke_active = false
	_paint_has_last_position = false
	if mode in [TERRAIN_MODE_BRUSH, TERRAIN_MODE_ERASER, TERRAIN_MODE_PAINT]:
		_focus_view_active = false
		_focus_orbiting = false
		_focus_panning = false

	if _terrain_toggle_button:
		_terrain_toggle_button.text = "绘制：已开启" if mode == TERRAIN_MODE_BRUSH else "绘制"
	if _terrain_eraser_button:
		_terrain_eraser_button.text = (
			"橡皮擦：已开启" if mode == TERRAIN_MODE_ERASER else "橡皮擦"
		)
	if _terrain_adjust_button:
		_terrain_adjust_button.text = (
			"单格选择：已开启" if mode == TERRAIN_MODE_ADJUST else "单格选择"
		)
	if _terrain_multiselect_button:
		_terrain_multiselect_button.text = (
			"多格选择：已开启" if mode == TERRAIN_MODE_MULTI else "多格选择"
		)
	if _paint_toggle_button:
		_paint_toggle_button.text = (
			"地面画笔：已开启" if mode == TERRAIN_MODE_PAINT else "开启地面画笔"
		)
	_set_toggle_button_active(_terrain_toggle_button, mode == TERRAIN_MODE_BRUSH)
	_set_toggle_button_active(_terrain_eraser_button, mode == TERRAIN_MODE_ERASER)
	_set_toggle_button_active(_terrain_adjust_button, mode == TERRAIN_MODE_ADJUST)
	_set_toggle_button_active(_terrain_multiselect_button, mode == TERRAIN_MODE_MULTI)
	_set_toggle_button_active(_paint_toggle_button, mode == TERRAIN_MODE_PAINT)

	if (had_selection_mode and not selection_mode) or mode == TERRAIN_MODE_NONE:
		_clear_terrain_selection()

	match mode:
		TERRAIN_MODE_BRUSH:
			_terrain_status_label.text = (
				"地形画笔已开启。左键按住拖动连续铺设；松开后自动保存。"
				+ "调整“垂直层”可搭建浮空平台。"
			)
			if p_announce:
				_set_status("实体地形画笔已开启；按左键拖动即可连续绘制。", false)
		TERRAIN_MODE_ERASER:
			_terrain_status_label.text = (
				"橡皮擦已开启。左键按住拖动会按当前形状、尺寸和垂直层擦除画笔格。"
			)
			if p_announce:
				_set_status("实体地形橡皮擦已开启；按左键拖动即可擦除。", false)
		TERRAIN_MODE_ADJUST:
			_terrain_status_label.text = (
				"单格选择已开启。左键点击已有画笔格；按住 Ctrl 可加选或减选。"
			)
			if p_announce:
				_set_status("单格选择已开启；右侧按钮可批量应用、删除或吸取。", false)
		TERRAIN_MODE_MULTI:
			_terrain_status_label.text = (
				"多格选择已开启。左键拖动按当前笔刷形状批量加选；按住 Ctrl 拖动可减选。"
			)
			if p_announce:
				_set_status("多格选择已开启；拖动圈选后可直接批量应用或删除。", false)
		TERRAIN_MODE_PAINT:
			_paint_status_label.text = (
				"画笔已开启。左键在三维视图地面碰撞体上点击或拖动；每笔松开后自动保存。"
			)
			if p_announce:
				_set_status("地面画笔已开启；可先用 Shift+F 调整观察位置。", false)
		_:
			_terrain_status_label.text = (
				"地形工具已关闭。画笔地形继续保存在 %s 下。"
				% TerrainBrushCatalog.GRID_MAP_NAME
			)
			_paint_status_label.text = "画笔已关闭。绘制贴面会继续保存在 GROUND_PAINT_ 地面绘制 节点下。"
	_refresh_terrain_cell_action_state()


func _on_toggle_paint_mode_pressed() -> void:
	if not _edited_root:
		_set_status("没有打开的作者场景。", true)
		return
	_set_terrain_mode(
		TERRAIN_MODE_NONE if _paint_mode_active else TERRAIN_MODE_PAINT
	)


func _on_toggle_terrain_brush_pressed() -> void:
	if not _edited_root:
		_set_status("没有打开的作者场景。", true)
		return
	_set_terrain_mode(
		TERRAIN_MODE_NONE if _terrain_brush_mode_active else TERRAIN_MODE_BRUSH
	)


func _on_toggle_terrain_eraser_pressed() -> void:
	if not _edited_root:
		_set_status("没有打开的作者场景。", true)
		return
	_set_terrain_mode(
		TERRAIN_MODE_NONE if _terrain_eraser_mode_active else TERRAIN_MODE_ERASER
	)


func _on_toggle_terrain_adjust_pressed() -> void:
	if not _edited_root:
		_set_status("没有打开的作者场景。", true)
		return
	_set_terrain_mode(
		TERRAIN_MODE_NONE if _terrain_adjust_mode_active else TERRAIN_MODE_ADJUST
	)


func _on_toggle_terrain_multiselect_pressed() -> void:
	if not _edited_root:
		_set_status("没有打开的作者场景。", true)
		return
	_set_terrain_mode(
		TERRAIN_MODE_NONE
		if _terrain_multiselect_mode_active
		else TERRAIN_MODE_MULTI
	)


func _on_terrain_preset_selected(p_index: int) -> void:
	if _terrain_thickness_spin == null:
		return
	if p_index < 0 or p_index >= _terrain_preset_option.item_count:
		return
	var preset_id := str(_terrain_preset_option.get_item_metadata(p_index))
	_terrain_thickness_spin.value = TerrainBrushCatalog.default_thickness(preset_id)


func _on_apply_terrain_cell_pressed() -> void:
	var selected_cells := _terrain_selected_cells.keys()
	if not _terrain_has_selected_cell or selected_cells.is_empty():
		_set_status("请先在三维视图里选中至少一个实体地形格。", true)
		return
	var grid_map := _terrain_active_grid_map()
	if grid_map == null:
		_clear_terrain_selection()
		_set_status("实体地形网格不存在。", true)
		return
	var preset_id := _selected_option(_terrain_preset_option)
	if preset_id == TerrainBrushCatalog.ERASER_ID:
		_delete_selected_terrain_cell(grid_map)
		return
	var item_id := TerrainBrushCatalog.resolve_item_id(
		grid_map,
		preset_id,
		float(_terrain_thickness_spin.value)
	)
	if item_id < 0:
		_set_status("无法创建当前地形和厚度的实体项目。", true)
		return
	var changed := 0
	for cell_value in selected_cells:
		var cell: Vector3i = cell_value
		if grid_map.get_cell_item(cell) == item_id:
			continue
		grid_map.set_cell_item(cell, item_id)
		changed += 1
	_sync_terrain_selection_primary()
	_refresh_terrain_selection_preview()
	_mark_editor_scene_unsaved()
	var save_error := _save_editor_scene()
	_refresh_terrain_clear_button_state()
	_refresh_terrain_cell_action_state()
	var applied_info := TerrainBrushCatalog.get_cell_info(
		grid_map,
		_terrain_selected_cell
	)
	_terrain_status_label.text = "已应用 %s · %.2f 米到 %d 个选中格（更新 %d 格）%s。" % [
		str(applied_info.get("preset_label", preset_id)),
		float(applied_info.get("thickness", _terrain_thickness_spin.value)),
		selected_cells.size(),
		changed,
		"并保存" if save_error == OK else "，但自动保存失败，请按 Ctrl+S",
	]
	_set_status(_terrain_status_label.text, save_error != OK)


func _on_delete_terrain_cell_pressed() -> void:
	if not _terrain_has_selected_cell or _terrain_selected_cells.is_empty():
		_set_status("请先在三维视图里选中至少一个实体地形格。", true)
		return
	var grid_map := _terrain_active_grid_map()
	if grid_map == null:
		_clear_terrain_selection()
		_set_status("实体地形网格不存在。", true)
		return
	_delete_selected_terrain_cell(grid_map)


func _delete_selected_terrain_cell(p_grid_map: GridMap) -> void:
	var selected_cells := _terrain_selected_cells.keys()
	if selected_cells.is_empty():
		_set_status("请先在三维视图里选中至少一个实体地形格。", true)
		return
	var removed := 0
	for cell_value in selected_cells:
		var cell: Vector3i = cell_value
		var result := TerrainBrushCatalog.remove_cell(p_grid_map, cell)
		if not bool(result.get("ok", false)):
			_set_status(str(result.get("error", "删除选中实体地形格失败。")), true)
			return
		removed += int(result.get("removed", 0))
	_clear_terrain_selection()
	_refresh_terrain_clear_button_state()
	_refresh_terrain_cell_action_state()
	if removed <= 0:
		_terrain_status_label.text = "选中的格子已经为空。"
		_set_status(_terrain_status_label.text, false)
		return
	_mark_editor_scene_unsaved()
	var save_error := _save_editor_scene()
	_terrain_status_label.text = "已删除 %d 个选中格%s。" % [
		removed,
		"并保存" if save_error == OK else "，但自动保存失败，请按 Ctrl+S",
	]
	_set_status(_terrain_status_label.text, save_error != OK)


func _on_eyedropper_terrain_cell_pressed() -> void:
	if not _terrain_has_selected_cell:
		_set_status("请先在三维视图里选中一个实体地形格。", true)
		return
	var grid_map := _terrain_active_grid_map()
	var info := (
		TerrainBrushCatalog.get_cell_info(grid_map, _terrain_selected_cell)
		if grid_map != null
		else {}
	)
	if not bool(info.get("ok", false)):
		_clear_terrain_selection()
		_set_status("选中的格子已不存在，请重新点选。", true)
		return
	_select_option(_terrain_preset_option, str(info.get("preset_id", "")))
	_terrain_thickness_spin.value = float(info.get("thickness", TerrainBrushCatalog.MIN_THICKNESS))
	_terrain_height_spin.value = float(info.get("height_level", 0))
	_terrain_status_label.text = "已吸取 %s · %.2f 米 · 垂直层 %d 到当前画笔参数。" % [
		str(info.get("preset_label", info.get("preset_id", "实体地形"))),
		float(info.get("thickness", 0.0)),
		int(info.get("height_level", 0)),
	]
	_set_status(_terrain_status_label.text, false)


func _on_select_terrain_group_pressed() -> void:
	if not _edited_root:
		_set_status("没有打开的作者场景。", true)
		return
	if _terrain_group_selection_active():
		_end_terrain_group_selection()
		return
	var grid_map := _terrain_group_grid_map()
	if grid_map == null or grid_map.get_used_cells().is_empty():
		_set_status("当前场景还没有实体地形画笔格子。", false)
		return
	_select_terrain_grid_map(grid_map)
	_terrain_status_label.text = (
		"已选中整组实体地形网格。现在可用 Godot 的移动工具整体移动，"
		+ "或用“复制整组并偏移”创建独立副本；再次点击“结束整组选择”可退出。"
	)
	_set_status(_terrain_status_label.text, false)


func _on_copy_terrain_group_pressed() -> void:
	if not _edited_root:
		_set_status("没有打开的作者场景。", true)
		return
	var grid_map := _terrain_group_grid_map()
	if grid_map == null or grid_map.get_used_cells().is_empty():
		_set_status("当前场景还没有实体地形画笔格子。", false)
		return
	var result := TerrainBrushCatalog.duplicate_grid_map(grid_map, _edited_root)
	if not bool(result.get("ok", false)):
		_set_status(str(result.get("error", "复制整组实体地形失败。")), true)
		return
	var duplicate := result.get("grid_map") as GridMap
	_select_terrain_grid_map(duplicate)
	_mark_editor_scene_unsaved()
	var save_error := _save_editor_scene()
	_terrain_status_label.text = "已复制 %d 个地形格到 %s%s。" % [
		int(result.get("used_cells", 0)),
		str(duplicate.name) if duplicate != null else "副本",
		"并保存" if save_error == OK else "，但自动保存失败，请按 Ctrl+S",
	]
	_set_status(_terrain_status_label.text, save_error != OK)


func _select_terrain_grid_map(p_grid_map: GridMap) -> void:
	if p_grid_map == null:
		return
	_set_terrain_mode(TERRAIN_MODE_NONE, false)
	_selected_node = p_grid_map
	var editor_selection = _editor_selection()
	if editor_selection:
		if EditorInterface.has_method("edit_node"):
			EditorInterface.edit_node(p_grid_map)
		else:
			editor_selection.clear()
			editor_selection.add_node(p_grid_map)
		_refresh_selection()
	else:
		_refresh_terrain_group_button_state()
	_refresh_terrain_clear_button_state()


func _end_terrain_group_selection(p_announce: bool = true) -> void:
	var had_group_selection := _terrain_group_selection_active()
	var editor_selection = _editor_selection()
	if editor_selection:
		editor_selection.clear()
	_selected_node = null
	_refresh_selection()
	_refresh_terrain_clear_button_state()
	if p_announce and had_group_selection:
		_terrain_status_label.text = "已结束整组选择。现在可切换单格选择或多格选择。"
		_set_status(_terrain_status_label.text, false)


func _on_clear_terrain_brush_pressed() -> void:
	if not _edited_root:
		_set_status("没有打开的作者场景。", true)
		return
	var grid_map := _terrain_active_grid_map()
	if grid_map == null or grid_map.get_used_cells().is_empty():
		_set_status("当前场景还没有实体地形画笔格子。", false)
		return
	_terrain_clear_dialog.popup_centered(Vector2i(520, 190))


func _on_clear_terrain_brush_confirmed() -> void:
	if not _edited_root:
		return
	var grid_map := _terrain_active_grid_map()
	var result := TerrainBrushCatalog.clear_terrain(grid_map)
	if not bool(result.get("ok", false)):
		_set_status(str(result.get("error", "清空画笔地形失败。")), true)
		return
	_clear_terrain_selection()
	_refresh_terrain_clear_button_state()
	if EditorInterface.has_method("mark_scene_as_unsaved"):
		EditorInterface.call("mark_scene_as_unsaved")
	var save_error := EditorInterface.save_scene()
	_terrain_status_label.text = "已清空 %d 个画笔地形格。" % int(result.get("removed", 0))
	_set_status(
		_terrain_status_label.text + ("已保存。" if save_error == OK else "自动保存失败，请按 Ctrl+S。"),
		save_error != OK
	)


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


func _populate_terrain_brush_options() -> void:
	_terrain_preset_option.clear()
	for entry in TerrainBrushCatalog.presets():
		_terrain_preset_option.add_item(str(entry.get("label", "")))
		_terrain_preset_option.set_item_metadata(
			_terrain_preset_option.item_count - 1,
			str(entry.get("id", ""))
		)
	if _terrain_preset_option.item_count > 0:
		_terrain_preset_option.select(0)
	_terrain_shape_option.clear()
	for entry in TerrainBrushCatalog.shapes():
		_terrain_shape_option.add_item(str(entry.get("label", "")))
		_terrain_shape_option.set_item_metadata(
			_terrain_shape_option.item_count - 1,
			str(entry.get("id", ""))
		)
	if _terrain_shape_option.item_count > 0:
		_terrain_shape_option.select(0)
	_terrain_size_option.clear()
	for entry in TerrainBrushCatalog.sizes():
		_terrain_size_option.add_item(str(entry.get("label", "")))
		_terrain_size_option.set_item_metadata(
			_terrain_size_option.item_count - 1,
			int(entry.get("value", 1))
		)
	if _terrain_size_option.item_count > 0:
		_terrain_size_option.select(1 if _terrain_size_option.item_count > 1 else 0)


func _selected_terrain_size() -> int:
	return int(_selected_option(_terrain_size_option))


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
	_focus_panning = false
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
	_focus_panning = false
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
	var scene_path := PlaytestMode.scene_path()
	var scene_valid := PlaytestMode.is_authoring_scene_path(scene_path)
	if not scene_valid:
		var region_id := Schema.sanitize_token(_region_edit.text)
		if region_id.is_empty():
			region_id = "first_night"
		scene_path = Runtime.scene_path_for_region(region_id)
		scene_valid = PlaytestMode.is_authoring_scene_path(scene_path)
	var scene_suffix := ""
	if enabled:
		if scene_valid:
			scene_suffix = "（实际加载：%s）" % scene_path.get_file()
		else:
			scene_suffix = "（未找到合法作者场景，当前会回退为空场景）"
	_playtest_status_label.text = "当前 F5：%s%s" % [PlaytestMode.label(), scene_suffix]
	_playtest_status_label.tooltip_text = (
		"允许 res://authoring/scenes/*_authoring.tscn 和已批准的基础几何审核场景；"
		+ "普通游戏场景与候选场景不会写入 F5 目标。"
	)
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
		_view_status_label.text = "当前：舒适聚焦 · %s（中键环绕 / Shift+中键平移 / 滚轮缩放）" % _focus_view_description
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
		_refresh_terrain_group_button_state()
		return
	_selected_node = selected[0]
	if _belongs_to_edited_root(_selected_node):
		_remember_model_parent(_model_parent_for_selection(_selected_node))
	var node_path := _safe_node_path(_edited_root, _selected_node)
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
	_refresh_terrain_group_button_state()


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
	var context_parent := _model_instance_parent()
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
	call_deferred("_select_created_parent", context_parent, environment_node)


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

	var context_parent := _model_instance_parent()
	var parent := _model_group_parent(entry)

	var semantic_id := _next_visual_instance_id(model_id)
	var typed_name := _new_model_name_edit.text.strip_edges() if _new_model_name_edit else ""
	var display_name := typed_name if not typed_name.is_empty() else str(entry.get("label", model_id)).strip_edges()
	var data := Schema.make(
		semantic_id,
		"decor",
		"none",
		_zone_id_for_parent(context_parent),
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

	call_deferred("_select_created_parent", context_parent, host)
	_run_validation(false)


func _select_created_parent(p_parent: Node, p_created_node: Node = null) -> void:
	var selection_target: Node = null
	if p_created_node != null and _belongs_to_edited_root(p_created_node):
		selection_target = p_created_node.get_parent()
	if selection_target == null or not _is_valid_model_parent(selection_target):
		selection_target = p_parent
	if selection_target == null or not _is_valid_model_parent(selection_target):
		selection_target = _default_model_parent()
	if selection_target == null:
		return
	_selected_node = selection_target
	if p_parent != null and not _is_scene_group(p_parent):
		_remember_model_parent(p_parent)
	var editor_selection = _editor_selection()
	if editor_selection:
		if EditorInterface.has_method("edit_node"):
			EditorInterface.edit_node(selection_target)
		else:
			editor_selection.clear()
			editor_selection.add_node(selection_target)
		_refresh_selection()


func _editor_selection():
	if not Engine.is_editor_hint():
		return null
	return EditorInterface.get_selection()


func _model_instance_parent() -> Node:
	if (
		_selected_node
		and _selected_node != _edited_root
		and _belongs_to_edited_root(_selected_node)
	):
		var selected_parent := _model_parent_for_selection(_selected_node)
		if selected_parent:
			_remember_model_parent(selected_parent)
			return selected_parent
	if _is_valid_model_parent(_last_model_parent) and _last_model_parent != _edited_root:
		return _last_model_parent
	return _default_model_parent()


func _model_parent_for_selection(p_selection: Node) -> Node:
	if p_selection == null or not _belongs_to_edited_root(p_selection):
		return _default_model_parent()
	var selection := p_selection
	var selected_name := str(selection.name)
	if (
		selected_name.begins_with(VisualCatalog.VISUAL_PREFIX)
		or selected_name.begins_with(VisualCatalog.EFFECT_PREFIX)
		or selected_name.begins_with(EnvironmentCatalog.ENVIRONMENT_PREFIX)
	):
		selection = selection.get_parent()
	while selection != null and _is_scene_group(selection):
		selection = selection.get_parent()
	if selection == null or selection == _edited_root:
		return _default_model_parent()
	var selected_data := Schema.data_from_node(selection)
	if str(selected_data.get("kind", "")) in ["zone", "region"]:
		return selection
	var candidate := selection.get_parent()
	if _is_valid_model_parent(candidate):
		return candidate
	return _default_model_parent()


func _default_model_parent() -> Node:
	if (
		_is_valid_model_parent(_last_model_parent)
		and _last_model_parent != _edited_root
	):
		return _last_model_parent
	if _edited_root == null:
		return null
	var pending: Array[Node] = []
	for child in _edited_root.get_children():
		if child is Node:
			pending.append(child)
	while not pending.is_empty():
		var node: Node = pending.pop_front()
		if node is Node3D:
			var data := Schema.data_from_node(node)
			if str(data.get("kind", "")) in ["zone", "region"]:
				_remember_model_parent(node)
				return node
		for child in node.get_children():
			pending.append(child)
	return _edited_root


func _remember_model_parent(p_parent: Node) -> void:
	if (
		p_parent == null
		or p_parent == _edited_root
		or _is_scene_group(p_parent)
		or not _is_valid_model_parent(p_parent)
	):
		return
	_last_model_parent = p_parent


func _is_valid_model_parent(p_node: Node) -> bool:
	return (
		p_node != null
		and is_instance_valid(p_node)
		and p_node is Node3D
		and _belongs_to_edited_root(p_node)
	)


func _environment_parent() -> Node:
	return _ensure_scene_group(GROUP_EFFECTS)


func _model_group_parent(p_entry: Dictionary) -> Node:
	return _ensure_scene_group(_scene_group_name_for_entry(p_entry))


func _scene_group_name_for_entry(p_entry: Dictionary) -> String:
	var category := str(p_entry.get("category", "")).strip_edges()
	if TERRAIN_MODEL_CATEGORIES.has(category):
		return GROUP_TERRAIN
	if BUILDING_MODEL_CATEGORIES.has(category):
		return GROUP_BUILDINGS
	if CHARACTER_MODEL_CATEGORIES.has(category):
		return GROUP_CHARACTERS
	return GROUP_OBJECTS


func _is_scene_group(p_node: Node) -> bool:
	return p_node != null and SCENE_GROUP_NAMES.has(str(p_node.name))


func _ensure_scene_group(p_group_name: String) -> Node:
	if _edited_root == null:
		return null
	var existing := _edited_root.get_node_or_null(NodePath(p_group_name))
	if existing is Node3D:
		existing.owner = _edited_root
		return existing
	var group := Node3D.new()
	group.name = p_group_name
	_edited_root.add_child(group)
	group.owner = _edited_root
	return group


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
	if _terrain_preset_option:
		_terrain_preset_option.disabled = not has_scene
	if _terrain_shape_option:
		_terrain_shape_option.disabled = not has_scene
	if _terrain_size_option:
		_terrain_size_option.disabled = not has_scene
	if _terrain_height_spin:
		_terrain_height_spin.editable = has_scene
	if _terrain_thickness_spin:
		_terrain_thickness_spin.editable = has_scene
	if _terrain_toggle_button:
		_terrain_toggle_button.disabled = not has_scene
	if _terrain_eraser_button:
		_terrain_eraser_button.disabled = not has_scene
	if _terrain_adjust_button:
		_terrain_adjust_button.disabled = not has_scene
	if _terrain_multiselect_button:
		_terrain_multiselect_button.disabled = not has_scene
	if not has_scene:
		_clear_terrain_selection()
	_refresh_terrain_cell_action_state()
	_refresh_terrain_clear_button_state()
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


func _refresh_terrain_clear_button_state() -> void:
	if _terrain_clear_button == null:
		return
	var terrain_grid := _terrain_active_grid_map() if _edited_root else null
	_terrain_clear_button.disabled = (
		_edited_root == null
		or terrain_grid == null
		or terrain_grid.get_used_cells().is_empty()
	)
	var group_grid := _terrain_group_grid_map() if _edited_root else null
	var group_unavailable := (
		_edited_root == null
		or group_grid == null
		or group_grid.get_used_cells().is_empty()
	)
	if _terrain_select_group_button:
		_terrain_select_group_button.disabled = group_unavailable
	if _terrain_copy_group_button:
		_terrain_copy_group_button.disabled = group_unavailable
	_refresh_terrain_group_button_state()


func _refresh_terrain_group_button_state() -> void:
	if _terrain_select_group_button == null:
		return
	var active := _terrain_group_selection_active()
	_terrain_select_group_button.text = "结束整组选择" if active else "选中整组地形"
	_terrain_select_group_button.tooltip_text = (
		"当前已选中整组地形；再次点击会退出整组操作，恢复单格或多格选择。"
		if active
		else "在场景树中选中共享 GridMap；随后可用 Godot 的移动、旋转和复制工具整体操作。"
	)
	_set_toggle_button_active(_terrain_select_group_button, active)


func _terrain_group_selection_active() -> bool:
	return (
		_edited_root != null
		and _selected_node is GridMap
		and _belongs_to_edited_root(_selected_node)
		and TerrainBrushCatalog.is_terrain_grid_map(_selected_node)
		and not _selected_node.get_used_cells().is_empty()
	)


func _refresh_terrain_cell_action_state() -> void:
	var has_scene := _edited_root != null
	var has_selection := has_scene and not _terrain_selected_cells.is_empty()
	if _terrain_apply_cell_button:
		_terrain_apply_cell_button.disabled = not has_selection
	if _terrain_delete_cell_button:
		_terrain_delete_cell_button.disabled = not has_selection
	if _terrain_eyedropper_button:
		_terrain_eyedropper_button.disabled = not has_selection


func _mark_editor_scene_unsaved() -> void:
	if not Engine.is_editor_hint():
		return
	EditorInterface.mark_scene_as_unsaved()


func _save_editor_scene() -> Error:
	if not Engine.is_editor_hint():
		return OK
	return EditorInterface.save_scene()


func _terrain_group_grid_map() -> GridMap:
	if (
		_edited_root != null
		and _selected_node is GridMap
		and _belongs_to_edited_root(_selected_node)
		and TerrainBrushCatalog.is_terrain_grid_map(_selected_node)
		and not _selected_node.get_used_cells().is_empty()
	):
		return _selected_node as GridMap
	return _terrain_active_grid_map()


func _terrain_active_grid_map() -> GridMap:
	return TerrainBrushCatalog.find_grid_map(_edited_root, _selected_node)


func _set_toggle_button_active(p_button: Button, p_active: bool) -> void:
	if p_button == null:
		return
	p_button.set_meta("fs_toggle_active", p_active)
	for color_name in [
		"font_color",
		"font_hover_color",
		"font_pressed_color",
	]:
		p_button.remove_theme_color_override(color_name)
	for style_name in ["normal", "hover", "pressed"]:
		p_button.remove_theme_stylebox_override(style_name)
	if not p_active:
		return
	p_button.add_theme_color_override("font_color", TOGGLE_ACTIVE_TEXT)
	p_button.add_theme_color_override("font_hover_color", TOGGLE_ACTIVE_TEXT)
	p_button.add_theme_color_override("font_pressed_color", TOGGLE_ACTIVE_TEXT)
	p_button.add_theme_stylebox_override(
		"normal",
		_make_toggle_active_style(TOGGLE_ACTIVE_BG)
	)
	p_button.add_theme_stylebox_override(
		"hover",
		_make_toggle_active_style(TOGGLE_ACTIVE_BG_HOVER)
	)
	p_button.add_theme_stylebox_override(
		"pressed",
		_make_toggle_active_style(TOGGLE_ACTIVE_BG_PRESSED)
	)


func _make_toggle_active_style(p_background: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = p_background
	style.border_color = TOGGLE_ACTIVE_BORDER
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	style.content_margin_left = 8.0
	style.content_margin_top = 4.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 4.0
	return style


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


func _safe_node_path(p_root: Node, p_node: Node) -> String:
	if p_root == null or p_node == null:
		return "<节点尚未进入编辑树>"
	if p_node == p_root:
		return "."
	var parts: Array[String] = []
	var current: Node = p_node
	while current != null and current != p_root:
		parts.append(str(current.name))
		current = current.get_parent()
	if current != p_root:
		return "<节点不属于当前作者场景>"
	parts.reverse()
	return "/".join(parts)


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
