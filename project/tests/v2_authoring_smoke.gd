extends SceneTree

const Schema := preload("res://scripts/authoring/FSAuthoringSchema.gd")
const Scaffold := preload("res://scripts/authoring/FSRegionScaffold.gd")
const Manifest := preload("res://scripts/authoring/FSSceneManifest.gd")
const Runtime := preload("res://scripts/authoring/FSAuthoringRuntime.gd")
const Workflow := preload("res://scripts/authoring/FSWorkflow.gd")
const VisualCatalog := preload("res://scripts/authoring/FSVisualCatalog.gd")
const EffectCatalog := preload("res://scripts/authoring/FSEffectCatalog.gd")
const EnvironmentCatalog := preload("res://scripts/authoring/FSEnvironmentCatalog.gd")
const GroundPaintCatalog := preload("res://scripts/authoring/FSGroundPaintCatalog.gd")
const TerrainBrushCatalog := preload("res://scripts/authoring/FSTerrainBrushCatalog.gd")
const ModelPreview := preload("res://scripts/authoring/FSModelPreview.gd")
const GameView := preload("res://scripts/authoring/FSGameView.gd")
const AuthoringDock := preload("res://addons/fivestar_authoring/fs_authoring_dock.gd")
const RouteData := preload("res://scripts/v2/V2RouteData.gd")
const GateScript := preload("res://scripts/v2/V2AbilityGate.gd")
const PickupScript := preload("res://scripts/v2/V2AbilityPickup.gd")
const BreakableScript := preload("res://scripts/v2/V2Breakable.gd")

const REGION_ID := "authoring_smoke"
const SCENE_PATH := "res://authoring/scenes/authoring_smoke_authoring.tscn"
const BINDING_PATH := "res://authoring/runtime/authoring_smoke.json"
const TEMP_OUTPUT_ROOT := "user://fs_authoring_smoke"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	var workflow_steps := Workflow.steps()
	ok = _expect(workflow_steps.size() == 7, "作者工作流必须固定为七个节点") and ok
	for step in workflow_steps:
		ok = _expect(
			step.has("title") and step.has("owner") and step.has("instruction") and step.has("prompt"),
			"工作流节点必须包含负责人、说明、提示和确认要求：%s" % str(step)
		) and ok
	var workflow_document := Workflow.create_document(REGION_ID, SCENE_PATH)
	ok = _expect(
		int(workflow_document.get("current_step", -1)) == 0
		and str(workflow_document.get("steps", [{}])[0].get("status", "")) == "PENDING",
		"新工作流必须停在规格确认且不得静默确认"
	) and ok
	var malformed_workflow := {
		"current_step": 99,
		"status": "COMPLETE",
		"steps": [
			{
				"id": "spec_confirm",
				"status": "DONE",
				"confirmed_at": "2026-09-12T12:00:00",
				"note": "保留节点 1 确认记录",
			},
			"invalid step",
			{"id": "scene_edit", "status": "BROKEN"},
		],
	}
	var normalized_workflow := Workflow.normalize_document(
		malformed_workflow,
		REGION_ID,
		SCENE_PATH
	)
	var normalized_steps: Array = normalized_workflow.get("steps", [])
	var preserved_state: Dictionary = {}
	if not normalized_steps.is_empty() and normalized_steps[0] is Dictionary:
		preserved_state = normalized_steps[0]
	ok = _expect(
		normalized_steps.size() == 7
		and int(normalized_workflow.get("current_step", -1)) == 1
		and str(normalized_workflow.get("status", "")) == "ACTIVE"
		and str(preserved_state.get("status", "")) == "DONE"
		and str(preserved_state.get("confirmed_at", "")) == "2026-09-12T12:00:00"
		and str(preserved_state.get("note", "")) == "保留节点 1 确认记录",
		"损坏的工作流文档必须恢复为七个节点并保留已有确认记录"
	) and ok
	var malformed_progress := Workflow.progress_text(malformed_workflow)
	ok = _expect(
		malformed_progress.contains("[x] 1 / 7 规格确认")
		and malformed_progress.contains("[>] 2 / 7 场景手调"),
		"异常工作流进度必须安全显示当前待确认节点"
	) and ok
	var malformed_confirmation := malformed_workflow.duplicate(true)
	Workflow.confirm_current(malformed_confirmation, "场景手调已完成")
	ok = _expect(
		int(malformed_confirmation.get("current_step", -1)) == 2
		and str(malformed_confirmation.get("steps", [{}])[1].get("note", "")) == "场景手调已完成",
		"异常工作流在执行确认后必须继续推进而不是越界"
	) and ok

	var region: Dictionary = RouteData.load_region()
	ok = _expect(not region.is_empty(), "默认区域 JSON 应可加载") and ok
	if region.is_empty():
		quit(1)
		return

	var source_root := Node3D.new()
	source_root.name = "FS_REGION_AUTHORING_SMOKE"
	root.add_child(source_root)
	var scaffold: Dictionary = Scaffold.build(source_root, region, REGION_ID)
	var pickup := Node3D.new()
	pickup.name = "FS_ABILITY_SMOKE_PICKUP"
	source_root.add_child(pickup)
	Schema.apply_to_node(pickup, Schema.make(
		"smoke_pickup",
		"ability",
		"pickup",
		REGION_ID,
		["authored", "smoke"],
		[],
		{"ability_id": "smoke_ability", "ability_name": "Smoke Ability"}
	))
	_assign_owner(source_root, source_root)

	var manifest := Manifest.build(source_root, SCENE_PATH, REGION_ID)
	var validation: Dictionary = manifest.get("validation", {})
	var errors: Array = validation.get("errors", [])
	var warnings: Array = validation.get("warnings", [])
	ok = _expect(errors.is_empty(), "作者清单不应有错误：%s" % "; ".join(errors)) and ok
	ok = _expect(warnings.is_empty(), "作者清单不应有无意义警告：%s" % "; ".join(warnings)) and ok
	ok = _expect(int(manifest.get("object_count", 0)) >= 70, "作者场景应包含完整路线语义对象") and ok
	ok = _expect(not _find_object(manifest, "spawn").is_empty(), "应登记出生点") and ok
	ok = _expect(not _find_object(manifest, "case_sofa").is_empty(), "应登记案件的语义点") and ok
	ok = _expect(not _find_object(manifest, "seal_endpoint").is_empty(), "应登记封印终点") and ok
	ok = _expect(not _find_object(manifest, "route_gate_0").is_empty(), "应登记路线进度门") and ok
	var smoke_pickup_object := _find_object(manifest, "smoke_pickup")
	ok = _expect(
		str(smoke_pickup_object.get("runtime_support", "")) == "runtime",
		"已实现行为必须标记为 runtime 接管"
	) and ok
	ok = _expect(Schema.runtime_support_for("prop", "pushable") == "native", "可推箱必须标记为 Godot 原生接管") and ok
	ok = _expect(Schema.runtime_support_for("rest", "rest") == "marker", "休息点必须标记为运行时标记") and ok
	ok = _expect(
		Schema.runtime_support_for("interactive", "interact") == "pending",
		"尚未实现的行为必须标记为 pending"
	) and ok

	var catalog_entries := VisualCatalog.entries()
	ok = _expect(catalog_entries.size() >= 40, "内置模型目录应提供足量原型模型") and ok
	for entry in catalog_entries:
		ok = _expect(
			not str(entry.get("id", "")).is_empty()
			and not str(entry.get("label", "")).is_empty()
			and not str(entry.get("category", "")).is_empty(),
			"模型目录项必须包含 ID、中文名和分类：%s" % str(entry)
		) and ok
		ok = _expect(
			ResourceLoader.exists(str(entry.get("path", ""))),
			"模型目录中的 GLB 必须已经导入：%s" % str(entry.get("path", ""))
		) and ok
		var packed_model = ResourceLoader.load(str(entry.get("path", "")))
		ok = _expect(
			packed_model is PackedScene,
			"模型目录中的资源必须可加载为 PackedScene：%s" % str(entry.get("path", ""))
		) and ok
		if packed_model is PackedScene:
			var model_instance = (packed_model as PackedScene).instantiate()
			ok = _expect(
				model_instance is Node3D and model_instance.get_child_count() > 0,
				"模型目录资源必须实例化为非空 Node3D：%s" % str(entry.get("path", ""))
			) and ok
			model_instance.free()
	var all_catalog_entries := VisualCatalog.all_entries()
	ok = _expect(
		all_catalog_entries.size() >= 288,
		"模型总览必须发现三套 Kenney 资产中的全部模型，实际 %d" % all_catalog_entries.size()
	) and ok
	var all_catalog_ids := {}
	for entry in all_catalog_entries:
		var entry_id := str(entry.get("id", ""))
		ok = _expect(
			not entry_id.is_empty() and not all_catalog_ids.has(entry_id),
			"自动模型目录不得产生空 ID 或重复 ID：%s" % entry_id
		) and ok
		all_catalog_ids[entry_id] = true
		ok = _expect(
			ResourceLoader.exists(str(entry.get("path", ""))),
			"模型总览中的资源必须已导入：%s" % str(entry.get("path", ""))
		) and ok
	var gallery_scene = ResourceLoader.load("res://authoring/scenes/model_gallery.tscn")
	ok = _expect(gallery_scene is PackedScene, "只读模型总览场景必须可加载") and ok
	if gallery_scene is PackedScene:
		var gallery_instance := (gallery_scene as PackedScene).instantiate()
		ok = _expect(
			gallery_instance is Control and gallery_instance.name == "FIVESTAR_MODEL_GALLERY_READONLY",
			"模型总览必须是独立的只读 UI 场景"
		) and ok
		gallery_instance.free()
	var authoring_dock = AuthoringDock.new()
	root.add_child(authoring_dock)
	ok = _expect(
		authoring_dock._model_list is ItemList
		and is_equal_approx(authoring_dock._model_list.custom_minimum_size.y, 170.0),
		"Dock 模型列表必须是固定高度的 ItemList，不能退回会遮住预览的 OptionButton"
	) and ok
	ok = _expect(
		authoring_dock._new_model_name_edit is LineEdit,
		"Dock 创建区必须提供新物件中文名输入框"
	) and ok
	ok = _expect(
		authoring_dock._focus_button is Button,
		"Dock 必须提供独立的舒适聚焦选中物件按钮"
	) and ok
	ok = _expect(
		not authoring_dock._model_filter_edit.editable
		and authoring_dock._model_create_button.disabled
		and authoring_dock._terrain_eraser_button.disabled
		and authoring_dock._terrain_multiselect_button.disabled
		and authoring_dock._terrain_select_group_button.disabled
		and authoring_dock._terrain_copy_group_button.disabled,
		"没有作者场景时必须禁用模型浏览器和实体地形批量工具"
	) and ok
	ok = _expect(
		authoring_dock._model_list.item_count >= 40,
		"模型浏览器应填充可创建的模型列表"
	) and ok
	authoring_dock._edited_root = root
	authoring_dock._set_form_enabled(false)
	ok = _expect(
		authoring_dock._model_filter_edit.editable
		and not authoring_dock._model_category_option.disabled
		and authoring_dock._new_model_name_edit.editable
		and not authoring_dock._model_create_button.disabled
		and not authoring_dock._selected_model_id().is_empty(),
		"没有选中场景节点时也必须能从模型列表直接创建物件"
	) and ok
	authoring_dock.free()
	var focus_root := Node3D.new()
	var focus_visual := MeshInstance3D.new()
	var focus_mesh := BoxMesh.new()
	focus_mesh.size = Vector3(2.0, 4.0, 2.0)
	focus_visual.mesh = focus_mesh
	focus_visual.position = Vector3(10.0, 2.0, -3.0)
	focus_root.add_child(focus_visual)
	root.add_child(focus_root)
	var focus_bounds := GameView.world_aabb_for_node(focus_root)
	ok = _expect(
		bool(focus_bounds.get("found", false))
		and _vector3_close(focus_bounds["aabb"].get_center(), Vector3(10.0, 2.0, -3.0), 0.02),
		"舒适聚焦必须按选中物件的世界包围盒计算中心"
	) and ok
	var focus_pose := GameView.focus_pose_for_aabb(focus_bounds["aabb"], 16.0 / 9.0)
	var focus_transform: Transform3D = focus_pose["transform"]
	var focus_center: Vector3 = focus_pose["center"]
	var focus_direction := (focus_transform.origin - focus_center).normalized()
	ok = _expect(
		focus_direction.y > 0.45
		and focus_direction.y < 0.75
		and float(focus_pose["distance"]) >= GameView.FOCUS_MIN_DISTANCE,
		"舒适聚焦必须从斜上方观察并保持合理距离：%s" % str(focus_pose)
	) and ok
	focus_root.free()
	var effect_entries := EffectCatalog.entries()
	ok = _expect(effect_entries.size() >= 8, "作者特效目录应提供完整的状态提示组件") and ok
	for entry in effect_entries:
		ok = _expect(
			not str(entry.get("id", "")).is_empty()
			and not str(entry.get("label", "")).is_empty()
			and ResourceLoader.exists(str(entry.get("path", ""))),
			"事件特效目录必须包含可加载资源：%s" % str(entry)
		) and ok
	var environment_entries := EnvironmentCatalog.entries()
	ok = _expect(
		environment_entries.size() == 9,
		"环境特效目录必须提供灯光、云、雾、火、雨、风和尘埃九类组件"
	) and ok
	var environment_root := Node3D.new()
	root.add_child(environment_root)
	for entry in environment_entries:
		var first_environment := EnvironmentCatalog.apply_environment(
			environment_root,
			entry,
			environment_root
		)
		var second_environment := EnvironmentCatalog.apply_environment(
			environment_root,
			entry,
			environment_root
		)
		var first_node := first_environment.get("node") as Node3D
		var second_node := second_environment.get("node") as Node3D
		ok = _expect(
			bool(first_environment.get("ok", false))
			and bool(second_environment.get("ok", false))
			and first_node != null
			and second_node != null
			and first_node != second_node
			and EnvironmentCatalog.is_environment_node(first_node)
			and EnvironmentCatalog.is_environment_node(second_node),
			"环境特效必须可重复创建并同时存在：%s" % str(entry)
		) and ok
		ok = _expect(
			first_node != null and first_node.get_child_count() > 0,
			"环境特效节点必须包含可见灯光、网格或粒子：%s" % str(entry)
		) and ok
		ok = _expect(
			first_node != null and _all_owned_by(first_node, environment_root),
			"环境特效生成后必须递归写入作者场景 owner，否则 F5 或重开会丢失：%s" % str(entry)
		) and ok
		if first_node and second_node:
			ok = _expect(
				EnvironmentCatalog.remove_environment(first_node)
				and is_instance_valid(second_node),
				"删除一个环境层不得影响同类型的另一个环境层"
			) and ok
	environment_root.free()
	var repair_environment_root := Node3D.new()
	repair_environment_root.name = "FS_ENVIRONMENT_REPAIR_SMOKE"
	root.add_child(repair_environment_root)
	var repair_environment_result := EnvironmentCatalog.apply_environment(
		repair_environment_root,
		EnvironmentCatalog.find("fire"),
		repair_environment_root
	)
	var repairable_environment := repair_environment_result.get("node") as Node3D
	ok = _expect(
		bool(repair_environment_result.get("ok", false)) and repairable_environment != null,
		"环境特效修复测试必须能先创建火与动态光节点"
	) and ok
	if repairable_environment:
		for child in repairable_environment.get_children():
			repairable_environment.remove_child(child)
			child.free()
	var repair_result := EnvironmentCatalog.repair_environment_nodes(
		repair_environment_root,
		repair_environment_root
	)
	ok = _expect(
		bool(repair_result.get("ok", false))
		and int(repair_result.get("rebuilt", 0)) == 1
		and repairable_environment != null
		and repairable_environment.get_child_count() > 0
		and _all_owned_by(repairable_environment, repair_environment_root),
		"旧场景中的空环境节点必须能从元数据补建并重新归作者场景持有：%s" % str(repair_result)
	) and ok
	repair_environment_root.free()
	var persisted_authoring_scene = ResourceLoader.load(
		"res://authoring/scenes/first_night_authoring.tscn"
	)
	ok = _expect(
		persisted_authoring_scene is PackedScene,
		"当前作者场景必须可作为 PackedScene 重新加载"
	) and ok
	if persisted_authoring_scene is PackedScene:
		var persisted_instance = (persisted_authoring_scene as PackedScene).instantiate()
		var persisted_environment_count := 0
		for candidate in persisted_instance.find_children("*", "Node", true, false):
			if EnvironmentCatalog.is_environment_node(candidate):
				persisted_environment_count += 1
				ok = _expect(
					candidate.get_child_count() > 0
					and _all_owned_by(candidate, persisted_instance),
					"重新打开作者场景后环境节点必须有内容且归属场景根：%s" % str(candidate.name)
				) and ok
		persisted_instance.free()

	var support_entries := VisualCatalog.support_shortcut_entries()
	var support_profiles := {}
	for entry in support_entries:
		support_profiles[str(entry.get("support_profile", "none"))] = true
	for support_profile in ["floor", "platform", "wall", "stairs", "column", "obstacle"]:
		ok = _expect(
			support_profiles.has(support_profile),
			"地形 / 平台快捷目录必须覆盖承托类型：%s" % support_profile
		) and ok
	ok = _expect(
		support_entries.size() >= 24,
		"地形 / 平台快捷目录必须提供足量可频繁搭建的承托模型，实际 %d" % support_entries.size()
	) and ok

	var support_host := Node3D.new()
	var support_root := Node3D.new()
	support_root.add_child(support_host)
	Schema.apply_to_node(support_host, Schema.make(
		"support_collision_smoke",
		"prop",
		"none",
		REGION_ID
	))
	var support_model_result := VisualCatalog.apply_model(
		support_host,
		VisualCatalog.find("road_bend"),
		support_root
	)
	var support_collision_result := VisualCatalog.ensure_support_collision(
		support_host,
		support_root
	)
	var support_collision_node := support_collision_result.get("node") as Node
	ok = _expect(
		bool(support_model_result.get("ok", false))
		and bool(support_collision_result.get("ok", false))
		and support_collision_node != null
		and float(support_collision_result.get("size", Vector3.ZERO).y) >= 0.079,
		"地板类模型必须自动生成至少 0.08 米厚的承托碰撞：%s" % str(support_collision_result)
	) and ok
	var support_removed := VisualCatalog.remove_auto_support_collision(support_host)
	ok = _expect(
		support_removed >= 1 and not is_instance_valid(support_collision_node),
		"插件自动承托碰撞必须可安全刷新或删除"
	) and ok
	support_root.free()

	var user_collision_host := Node3D.new()
	var user_collision_root := Node3D.new()
	user_collision_root.add_child(user_collision_host)
	Schema.apply_to_node(user_collision_host, Schema.make(
		"user_collision_smoke",
		"prop",
		"none",
		REGION_ID
	))
	var user_shape := CollisionShape3D.new()
	user_shape.name = "UserFloorCollision"
	user_shape.shape = BoxShape3D.new()
	user_collision_host.add_child(user_shape)
	VisualCatalog.apply_model(
		user_collision_host,
		VisualCatalog.find("road_bend"),
		user_collision_root
	)
	var user_collision_result := VisualCatalog.ensure_support_collision(
		user_collision_host,
		user_collision_root
	)
	ok = _expect(
		is_instance_valid(user_shape)
		and bool(user_collision_result.get("skipped", false))
		and str(user_collision_result.get("reason", "")).contains("用户自建碰撞"),
		"自动承托碰撞刷新必须保留用户手搭碰撞，不得覆盖或删除"
	) and ok
	user_collision_root.free()

	var tiny_limits := GameView.focus_zoom_limits(0.1)
	var large_limits := GameView.focus_zoom_limits(4.0)
	var tiny_distance := float(tiny_limits["max"])
	var tiny_zoom_out := GameView.focus_zoom_step(tiny_distance, 0.1, 1.0)
	var orbit_step := GameView.focus_orbit_step(Vector2(10.0, 0.0), 0.1)
	var large_orbit_step := GameView.focus_orbit_step(Vector2(10.0, 0.0), 4.0)
	ok = _expect(
		float(tiny_limits["min"]) >= 0.14
		and float(tiny_limits["max"]) <= 2.6
		and absf(tiny_zoom_out - tiny_distance * GameView.FOCUS_WHEEL_ZOOM_FACTOR) <= 0.001
		and float(large_limits["max"]) > float(tiny_limits["max"]) * 10.0,
		"舒适聚焦缩放必须按当前包围盒尺寸限制近距和远距，而不是固定大步长：%s / %s" % [
			str(tiny_limits),
			str(large_limits),
		]
	) and ok
	ok = _expect(
		absf(float(orbit_step["yaw_delta"])) > 0.0
		and float(orbit_step["yaw_delta"]) > 0.0
		and float(GameView.focus_orbit_step(Vector2(0.0, 10.0), 0.1)["elevation_delta"]) > 0.0
		and absf(float(orbit_step["yaw_delta"])) <= 2.0
		and absf(float(orbit_step["yaw_delta"])) < absf(float(large_orbit_step["yaw_delta"]))
		and is_zero_approx(float(orbit_step["elevation_delta"])),
		"舒适聚焦中键水平环绕必须反转为直觉方向并保持原上下方向，同时按物件尺寸减速：%s / %s" % [
			str(orbit_step),
			str(large_orbit_step),
		]
	) and ok
	var tiny_focus_pose := GameView.focus_pose_for_aabb(
		AABB(Vector3.ZERO, Vector3(0.2, 0.2, 0.2))
	)
	var large_focus_pose := GameView.focus_pose_for_aabb(
		AABB(Vector3.ZERO, Vector3(4.0, 4.0, 4.0))
	)
	var tiny_pan_units := GameView.focus_pan_units_per_pixel(
		float(tiny_focus_pose["distance"])
	)
	var large_pan_units := GameView.focus_pan_units_per_pixel(
		float(large_focus_pose["distance"])
	)
	ok = _expect(
		float(tiny_focus_pose["distance"]) < 0.6
		and float(large_focus_pose["distance"]) > float(tiny_focus_pose["distance"]) * 4.0
		and tiny_pan_units < large_pan_units,
		"舒适聚焦必须按物件尺寸决定取景距离和拖拽单位：%s / %s / %s / %s" % [
			str(tiny_focus_pose["distance"]),
			str(large_focus_pose["distance"]),
			str(tiny_pan_units),
			str(large_pan_units),
		]
	) and ok

	var selection_root := Node3D.new()
	selection_root.name = "FS_REGION_SELECTION_SMOKE"
	root.add_child(selection_root)
	Schema.apply_to_node(selection_root, Schema.make(
		"selection_smoke",
		"region",
		"none",
		REGION_ID
	))
	var selection_parent := Node3D.new()
	selection_parent.name = "FS_ZONE_SELECTION_SMOKE"
	var selection_child := Node3D.new()
	selection_parent.add_child(selection_child)
	selection_root.add_child(selection_parent)
	Schema.apply_to_node(selection_parent, Schema.make(
		"selection_zone",
		"zone",
		"none",
		REGION_ID
	))
	var selection_dock = AuthoringDock.new()
	root.add_child(selection_dock)
	selection_dock._edited_root = selection_root
	selection_dock._last_model_parent = selection_parent
	selection_dock._selected_node = selection_root
	ok = _expect(
		selection_dock._model_instance_parent() == selection_parent,
		"编辑器选中区域根节点时，新建模型必须继续使用上次有效父语义层"
	) and ok
	selection_dock._last_model_parent = null
	selection_dock._remember_model_parent(selection_root)
	ok = _expect(
		selection_dock._last_model_parent == null,
		"场景根节点不得被记录为后续新建模型的默认父级"
	) and ok
	ok = _expect(
		selection_dock._model_instance_parent() == selection_parent,
		"没有可用选择时必须回退到区域内的第一个语义容器，而不是场景根节点"
	) and ok
	var terrain_group := selection_dock._model_group_parent({"category": "地形与平台"})
	var building_group := selection_dock._model_group_parent({"category": "城镇建筑"})
	var object_group := selection_dock._model_group_parent({"category": "城镇互动"})
	var character_group := selection_dock._model_group_parent({"category": "角色占位"})
	ok = _expect(
		terrain_group != null
		and building_group != null
		and object_group != null
		and character_group != null
		and str(terrain_group.name) == AuthoringDock.GROUP_TERRAIN
		and str(building_group.name) == AuthoringDock.GROUP_BUILDINGS
		and str(object_group.name) == AuthoringDock.GROUP_OBJECTS
		and str(character_group.name) == AuthoringDock.GROUP_CHARACTERS,
		"新建模型必须按地形、建筑、物件和角色分类进入稳定容器"
	) and ok
	ok = _expect(
		terrain_group.owner == selection_root
		and selection_dock._scene_group_name_for_entry({"category": "雨城水文"}) == AuthoringDock.GROUP_TERRAIN
		and selection_dock._scene_group_name_for_entry({"category": "门与出入口"}) == AuthoringDock.GROUP_BUILDINGS
		and selection_dock._scene_group_name_for_entry({"category": "角色占位"}) == AuthoringDock.GROUP_CHARACTERS
		and selection_dock._scene_group_name_for_entry({"category": "未登记分类"}) == AuthoringDock.GROUP_OBJECTS,
		"分类容器必须由作者场景根节点持有并使用完整类别映射"
	) and ok
	selection_dock._last_model_parent = null
	selection_dock._remember_model_parent(object_group)
	ok = _expect(
		selection_dock._last_model_parent == null,
		"分类容器不得被记录为后续新建模型的语义父级"
	) and ok
	ok = _expect(
		selection_dock._model_parent_for_selection(object_group) == selection_parent,
		"选中分类容器时必须回溯到区域内的语义父级"
	) and ok
	selection_dock._select_created_parent(selection_parent)
	ok = _expect(
		selection_dock._selected_node == selection_parent
		and selection_dock._selected_node != selection_child,
		"存在非根父语义层时，新建模型后必须只选中该父层"
	) and ok
	var created_selection_node := Node3D.new()
	object_group.add_child(created_selection_node)
	selection_dock._select_created_parent(selection_root, created_selection_node)
	ok = _expect(
		selection_dock._selected_node == object_group
		and selection_dock._selected_node != created_selection_node
		and selection_dock._selected_node != selection_root,
		"新建物件后必须选中分类容器而不能自动展开并选中刚创建物件"
	) and ok
	selection_dock.free()
	selection_root.free()

	var key_entry := VisualCatalog.find("dungeon_key")
	ok = _expect(not key_entry.is_empty(), "模型目录应包含钥匙模型") and ok
	ok = _expect(
		ResourceLoader.exists(str(key_entry.get("path", ""))),
		"模型目录中的 GLB 必须已经导入：%s" % str(key_entry.get("path", ""))
	) and ok
	if not key_entry.is_empty():
		var preview := ModelPreview.new()
		root.add_child(preview)
		preview.set_model(key_entry)
		ok = _expect(
			preview.get_child_count() >= 1,
			"模型预览组件必须能建立独立的三维预览视口"
		) and ok
		preview.free()

	var named_host := Node3D.new()
	named_host.name = "Unregistered"
	var named_data := Schema.make(
		"visual_smoke",
		"prop",
		"none",
		REGION_ID,
		["authored", "visual_smoke"],
		[],
		{},
		"中文测试物"
	)
	named_data = Schema.apply_to_node(named_host, named_data)
	named_host.name = Schema.node_name(named_data)
	ok = _expect(
		str(named_host.name) == "FS_PROP_中文测试物_VISUAL_SMOKE",
		"中文显示名必须进入节点名，同时保留稳定英文 ID"
	) and ok
	if not key_entry.is_empty():
		var visual_result := VisualCatalog.apply_model(named_host, key_entry)
		ok = _expect(bool(visual_result.get("ok", false)), "模型目录应可实例化 GLB") and ok
		ok = _expect(
			VisualCatalog.model_id_from_node(named_host) == "dungeon_key",
			"应用模型后必须生成稳定的 VISUAL_<model_id> 子节点"
		) and ok
		var named_params: Dictionary = named_data.get("params", {}).duplicate(true)
		named_params["visual"] = VisualCatalog.visual_params(key_entry)
		named_data["params"] = named_params
		named_data = Schema.apply_to_node(named_host, named_data)
		var named_manifest := Manifest.build(named_host, "res://visual_smoke.tscn", REGION_ID)
		var named_object := _find_object(named_manifest, "visual_smoke")
		ok = _expect(
			str(named_object.get("display_name", "")) == "中文测试物",
			"机器清单必须保留中文显示名"
		) and ok
		ok = _expect(
			str(named_object.get("visual", {}).get("model_id", "")) == "dungeon_key",
			"机器清单必须保留可视模型选择"
		) and ok
	named_host.free()

	if not key_entry.is_empty():
		var replacement_root := Node3D.new()
		var replacement_host := Node3D.new()
		replacement_root.add_child(replacement_host)
		Schema.apply_to_node(replacement_host, Schema.make(
			"replacement_smoke",
			"prop",
			"none",
			REGION_ID
		))
		VisualCatalog.apply_model(replacement_host, key_entry)
		var watermill_entry := VisualCatalog.find("watermill")
		var replacement_result := VisualCatalog.apply_model(replacement_host, watermill_entry)
		ok = _expect(
			bool(replacement_result.get("ok", false))
			and _count_nodes_with_prefix(replacement_host, VisualCatalog.VISUAL_PREFIX) == 1
			and VisualCatalog.model_id_from_node(replacement_host) == "watermill",
			"连续替换水体组件后必须只保留当前模型，不能宝箱和水车叠加"
		) and ok
		replacement_root.free()

		var legacy_root := Node3D.new()
		var legacy_outer := Node3D.new()
		var legacy_inner := Node3D.new()
		legacy_root.add_child(legacy_outer)
		legacy_outer.add_child(legacy_inner)
		Schema.apply_to_node(legacy_outer, Schema.make("legacy_outer_smoke", "prop", "none", REGION_ID))
		Schema.apply_to_node(legacy_inner, Schema.make("legacy_inner_smoke", "decor", "none", REGION_ID))
		VisualCatalog.apply_model(legacy_inner, key_entry)
		var legacy_result := VisualCatalog.apply_model(legacy_outer, VisualCatalog.find("watermill"))
		ok = _expect(
			bool(legacy_result.get("ok", false))
			and _count_nodes_with_prefix(legacy_outer, VisualCatalog.VISUAL_PREFIX) == 1
			and not is_instance_valid(legacy_inner),
			"替换模型时必须清理旧版嵌套语义宿主和其中的旧模型"
		) and ok
		legacy_root.free()

		var ground_host := StaticBody3D.new()
		var ground_collision := CollisionShape3D.new()
		var ground_shape := BoxShape3D.new()
		ground_shape.size = Vector3(2.0, 1.0, 2.0)
		ground_collision.shape = ground_shape
		ground_collision.position = Vector3(0.0, 1.5, 0.0)
		ground_host.add_child(ground_collision)
		Schema.apply_to_node(ground_host, Schema.make(
			"grounding_smoke",
			"prop",
			"none",
			REGION_ID
		))
		var grounded_result := VisualCatalog.apply_model(ground_host, key_entry)
		var grounded_visual := grounded_result.get("node") as Node3D
		var grounded_bounds := VisualCatalog._node_aabb_in_parent(grounded_visual)
		ok = _expect(
			absf(grounded_bounds.position.y - 1.0) <= 0.02,
			"普通落地模型必须把底面对齐到宿主地面，实际底面 %.4f" % grounded_bounds.position.y
		) and ok
		var floating_result := VisualCatalog.apply_model(
			ground_host,
			VisualCatalog.find("water_surface")
		)
		var ground_fix_result := VisualCatalog.ground_model(ground_host)
		ok = _expect(
			bool(floating_result.get("ok", false))
			and str(floating_result.get("visual", {}).get("placement", "")) == "float"
			and bool(ground_fix_result.get("skipped", false)),
			"显式浮动的水面必须保持浮动，批量落地不得强制下压"
		) and ok
		ground_host.free()

		var effect_root := Node3D.new()
		var effect_host := Node3D.new()
		effect_root.add_child(effect_host)
		Schema.apply_to_node(effect_host, Schema.make(
			"effect_coexist_smoke",
			"case",
			"none",
			REGION_ID
		))
		VisualCatalog.apply_model(effect_host, key_entry)
		var effect_result := EffectCatalog.apply_effect(
			effect_host,
			EffectCatalog.find("case_gold_beacon"),
			effect_root
		)
		var effect_node := effect_result.get("node") as Node3D
		ok = _expect(
			bool(effect_result.get("ok", false))
			and VisualCatalog.visual_node(effect_host) != null
			and effect_node != null,
			"同一语义宿主必须能同时保留可视模型和事件特效"
		) and ok
		var effect_data := Schema.data_from_node(effect_host)
		var effect_params: Dictionary = effect_data.get("params", {}).duplicate(true)
		effect_params["visual"] = VisualCatalog.visual_params(key_entry)
		effect_params["effect"] = effect_result.get("effect", {})
		effect_data["params"] = effect_params
		Schema.apply_to_node(effect_host, effect_data)
		var effect_manifest := Manifest.build(effect_host, "res://effect_smoke.tscn", REGION_ID)
		var effect_object := _find_object(effect_manifest, "effect_coexist_smoke")
		ok = _expect(
			str(effect_object.get("visual", {}).get("model_id", "")) == "dungeon_key"
			and str(effect_object.get("effect", {}).get("effect_id", "")) == "case_gold_beacon",
			"机器清单必须分别保留 params.visual 与 params.effect：%s" % str(effect_object)
		) and ok
		VisualCatalog.remove_model(effect_host)
		ok = _expect(
			is_instance_valid(effect_node),
			"移除可视模型不得连带删除独立事件特效"
		) and ok
		effect_root.free()

	var owner_root := Node3D.new()
	owner_root.name = "FS_REGION_OWNER_SMOKE"
	root.add_child(owner_root)
	var owner_host := Node3D.new()
	owner_root.add_child(owner_host)
	Schema.apply_to_node(owner_host, Schema.make(
		"owner_model_smoke",
		"prop",
		"none",
		REGION_ID,
		["authored", "owner_smoke"]
	))
	if not key_entry.is_empty():
		var owner_result := VisualCatalog.apply_model(owner_host, key_entry, owner_root)
		ok = _expect(bool(owner_result.get("ok", false)), "带 owner 的模型挂载必须成功") and ok
		var owner_visual := owner_result.get("node") as Node3D
		var owner_instance := owner_visual.get_child(0) if owner_visual else null
		ok = _expect(
			owner_visual != null and owner_visual.owner == owner_root,
			"VISUAL_ 外壳必须由作者场景根节点持有"
		) and ok
		ok = _expect(
			owner_instance != null and owner_instance.owner == owner_root,
			"PackedScene 实例根节点必须由作者场景根节点持有"
		) and ok
		var leaked_owner := false
		if owner_instance:
			for child in owner_instance.get_children():
				if child.owner == owner_root:
					leaked_owner = true
					break
		ok = _expect(
			not leaked_owner,
			"预制体内部节点不得改成作者场景 owner，否则保存后会重复序列化"
		) and ok
		var owner_packed := PackedScene.new()
		var owner_pack_error := owner_packed.pack(owner_root)
		ok = _expect(owner_pack_error == OK, "带模型实例的作者场景应可安全打包") and ok
		if owner_pack_error == OK:
			var owner_state := owner_packed.get_state()
			var serialized_visual_internals := false
			for index in range(owner_state.get_node_count()):
				var packed_path := str(owner_state.get_node_path(index))
				if (
					packed_path.contains("/VISUAL_dungeon_key/")
					and not packed_path.ends_with("/VISUAL_dungeon_key/Model")
				):
					serialized_visual_internals = true
					break
			ok = _expect(
				not serialized_visual_internals,
				"PackedScene 内部节点不得作为作者场景节点重复写入"
			) and ok
	owner_root.free()

	var recommended_root := Node3D.new()
	var recommended_jar := Node3D.new()
	var recommended_floor := Node3D.new()
	recommended_root.add_child(recommended_jar)
	recommended_root.add_child(recommended_floor)
	Schema.apply_to_node(recommended_jar, Schema.make(
		"night_jar_recommended",
		"breakable",
		"breakable",
		REGION_ID
	))
	Schema.apply_to_node(recommended_floor, Schema.make(
		"route_floor_recommended",
		"floor"
	))
	var recommended_result := VisualCatalog.apply_recommended_models(recommended_root, recommended_root)
	ok = _expect(
		int(recommended_result.get("applied", 0)) == 1
		and int(recommended_result.get("skipped", 0)) == 1,
		"推荐模型应只补尚未配置且匹配的原型，结构地板应跳过"
	) and ok
	ok = _expect(
		VisualCatalog.model_id_from_node(recommended_jar) == "urn_round",
		"可击破罐应推荐骨灰瓮模型"
	) and ok
	ok = _expect(
		str(Schema.data_from_node(recommended_jar).get("display_name", "")) == "圆骨灰瓮"
		and str(recommended_jar.name).contains("圆骨灰瓮"),
		"推荐模型应补齐中文显示名和节点名"
	) and ok
	recommended_root.free()

	var unregistered_root := Node3D.new()
	unregistered_root.name = "FS_REGION_UNREGISTERED_SMOKE"
	var unregistered_zone := Node3D.new()
	unregistered_zone.name = "FS_ZONE_UNREGISTERED_ZONE"
	unregistered_root.add_child(unregistered_zone)
	Schema.apply_to_node(unregistered_zone, Schema.make(
		"unregistered_smoke_zone",
		"zone",
		"none",
		REGION_ID,
		[],
		[],
		{},
		"未登记测试区域"
	))
	var unregistered_cases: Array[Dictionary] = [
		{"name": "石柱", "model": "stone_pillar_large"},
		{"name": "城墙", "model": "town_wall"},
		{"name": "木门", "model": "simple_door"},
		{"name": "悬浮平台", "model": "wood_planks"},
		{"name": "雨城小屋", "model": "crypt_small"},
		{"name": "喷泉", "model": "fountain_round_detail"},
		{"name": "瀑布", "model": "waterfall"},
		{"name": "河流", "model": "river_straight"},
		{"name": "积水", "model": "water_surface"},
	]
	var unregistered_nodes: Array[Node3D] = []
	for case in unregistered_cases:
		var unregistered_node := Node3D.new()
		unregistered_node.name = str(case["name"])
		unregistered_zone.add_child(unregistered_node)
		unregistered_nodes.append(unregistered_node)
	var unregistered_semantic_parent := Node3D.new()
	unregistered_semantic_parent.name = "FS_REST_UNREGISTERED_PARENT"
	unregistered_root.add_child(unregistered_semantic_parent)
	var child_inside_semantic_host := MeshInstance3D.new()
	child_inside_semantic_host.name = "AuthoringJarBody"
	child_inside_semantic_host.mesh = SphereMesh.new()
	unregistered_semantic_parent.add_child(child_inside_semantic_host)
	Schema.apply_to_node(unregistered_semantic_parent, Schema.make(
		"unregistered_parent_rest",
		"rest",
		"rest",
		REGION_ID,
		[],
		[],
		{},
		"未登记父节点"
	))
	var unknown_unregistered_node := Node3D.new()
	unknown_unregistered_node.name = "UnclassifiedNodeXYZ"
	unregistered_zone.add_child(unknown_unregistered_node)
	_assign_owner(unregistered_root, unregistered_root)
	var unregistered_result := VisualCatalog.apply_recommended_models(unregistered_root, unregistered_root)
	ok = _expect(
		int(unregistered_result.get("registered", 0)) == unregistered_cases.size(),
		"批量推荐必须自动登记区域容器内名称可识别的未分配物件：%s" % str(unregistered_result)
	) and ok
	ok = _expect(
		not child_inside_semantic_host.has_meta(Schema.META_KEY),
		"已有语义宿主内部的模型子节点不得被自动登记为独立物件"
	) and ok
	ok = _expect(
		unregistered_result.get("remaining_unregistered", []).has("UnclassifiedNodeXYZ"),
		"批量推荐结果必须报告无法按名称识别的剩余节点：%s" % str(unregistered_result)
	) and ok
	for index in range(unregistered_cases.size()):
		var case := unregistered_cases[index]
		var unregistered_node := unregistered_nodes[index]
		var unregistered_data := Schema.data_from_node(unregistered_node)
		ok = _expect(
			str(unregistered_data.get("display_name", "")) == str(case["name"]),
			"自动登记必须保留中文物件名：%s" % str(case["name"])
		) and ok
		ok = _expect(
			VisualCatalog.model_id_from_node(unregistered_node) == str(case["model"]),
			"自动登记物件推荐模型错误：%s 应为 %s，实际 %s" % [
				str(case["name"]),
				str(case["model"]),
				VisualCatalog.model_id_from_node(unregistered_node),
			]
		) and ok
		ok = _expect(
			VisualCatalog.is_model_visual_usable(unregistered_node),
			"自动登记的物件必须包含可见几何体：%s" % str(case["name"])
		) and ok
	unregistered_root.free()

	for recommendation_case in [
		{"kind": "decor", "behavior": "none", "semantic": "waterfall", "tags": ["waterfall"], "expected": "waterfall"},
		{"kind": "trigger", "behavior": "pressure_plate", "semantic": "pressure", "tags": ["pressure"], "expected": "pressure_plate"},
		{"kind": "decor", "behavior": "none", "semantic": "window", "tags": ["window"], "expected": "town_window"},
		{"kind": "prop", "behavior": "none", "semantic": "platform", "tags": ["platform"], "expected": "wood_planks"},
		{"kind": "prop", "behavior": "none", "semantic": "floating_block", "tags": ["悬浮"], "expected": "wood_planks"},
		{"kind": "prop", "behavior": "none", "semantic": "boundary_wall", "tags": ["墙"], "expected": "town_wall"},
		{"kind": "prop", "behavior": "none", "semantic": "back_door", "tags": ["door"], "expected": "simple_door"},
		{"kind": "decor", "behavior": "none", "semantic": "stone_column", "tags": ["column"], "expected": "stone_pillar_large"},
		{"kind": "prop", "behavior": "none", "semantic": "route_wall_north", "tags": ["route", "boundary"], "expected": "town_wall"},
	]:
		var recommended_id := VisualCatalog.recommended_model_id(
			str(recommendation_case["kind"]),
			str(recommendation_case["behavior"]),
			str(recommendation_case["semantic"]),
			Schema.string_array(recommendation_case["tags"])
		)
		ok = _expect(
			recommended_id == str(recommendation_case["expected"]),
			"推荐映射错误：%s 应为 %s，实际 %s" % [
				str(recommendation_case["semantic"]),
				str(recommendation_case["expected"]),
				recommended_id,
			]
		) and ok

	var chinese_hint_host := Node3D.new()
	Schema.apply_to_node(chinese_hint_host, Schema.make(
		"generic_scene_object",
		"prop",
		"none",
		REGION_ID,
		[],
		[],
		{},
		"石柱"
	))
	var chinese_hint_entry := VisualCatalog.recommended_model_for_node(chinese_hint_host)
	ok = _expect(
		str(chinese_hint_entry.get("id", "")) == "stone_pillar_large",
		"推荐模型必须读取手动填写的中文显示名"
	) and ok
	chinese_hint_host.free()

	var water_matches := VisualCatalog.water_shortcut_entries()
	for water_id in [
		"fountain_round_detail",
		"waterfall",
		"river_straight",
		"river_corner",
		"riverbank",
		"water_surface",
		"plunge_pool_foam",
		"puddle_ripple",
		"drain_outfall",
		"waterfall_wide",
		"waterfall_narrow",
		"river_calm_straight",
		"river_rapids_straight",
		"wall_spout",
		"fountain_jet",
		"faucet_flow",
		"drain_runoff",
		"pool_overflow",
		"water_flow_sheet",
		"watermill",
	]:
		var found_water := false
		for match_entry in water_matches:
			if str(match_entry.get("id", "")) == water_id:
				found_water = true
				break
		ok = _expect(found_water, "雨城快捷筛选必须包含水体组件：%s" % water_id) and ok
	var water_shortcut_has_potion := false
	for water_entry in water_matches:
		if str(water_entry.get("id", "")) == "dungeon_potion":
			water_shortcut_has_potion = true
			break
	ok = _expect(not water_shortcut_has_potion, "水体快捷筛选不得混入药水瓶") and ok
	for float_water_id in [
		"wall_spout",
		"fountain_jet",
		"faucet_flow",
		"drain_runoff",
		"pool_overflow",
	]:
		ok = _expect(
			VisualCatalog.placement_for_model_id(float_water_id) == "float",
			"建筑附着类水流不得被自动强制落地：%s" % float_water_id
		) and ok

	var paint_root := Node3D.new()
	paint_root.name = "FS_GROUND_PAINT_SMOKE"
	root.add_child(paint_root)
	var paint_parent := Node3D.new()
	paint_parent.name = GroundPaintCatalog.GROUP_NAME
	paint_root.add_child(paint_parent)
	paint_parent.owner = paint_root
	var paint_params := GroundPaintCatalog.brush_params("water_sheen", "oval", 2.5, 0.7)
	var paint_result := GroundPaintCatalog.apply_stamp(
		paint_parent,
		Vector3(1.0, 0.2, 2.0),
		Vector3.UP,
		paint_root,
		paint_params
	)
	var paint_node := paint_result.get("node") as MeshInstance3D
	ok = _expect(
		bool(paint_result.get("ok", false))
		and paint_node != null
		and GroundPaintCatalog.is_paint_node(paint_node)
		and paint_node.owner == paint_root
		and paint_node.mesh != null
		and paint_node.material_override != null,
		"地面绘制必须生成可持久化、无碰撞的 MeshInstance3D 贴面：%s" % str(paint_result)
	) and ok
	ok = _expect(
		paint_node != null
		and GroundPaintCatalog.remove_paint_node(paint_node)
		and not is_instance_valid(paint_node),
		"地面绘制必须支持独立删除且不影响地形"
	) and ok
	paint_root.free()

	var terrain_root := Node3D.new()
	terrain_root.name = "FS_TERRAIN_BRUSH_SMOKE"
	root.add_child(terrain_root)
	var terrain_grid_result := TerrainBrushCatalog.ensure_grid_map(terrain_root, terrain_root)
	var terrain_grid := terrain_grid_result.get("grid_map") as GridMap
	var terrain_library: MeshLibrary = terrain_grid.mesh_library if terrain_grid else null
	var terrain_shapes: Array = terrain_library.get_item_shapes(0) if terrain_library else []
	ok = _expect(
		bool(terrain_grid_result.get("ok", false))
		and terrain_grid != null
		and TerrainBrushCatalog.is_terrain_grid_map(terrain_grid)
		and terrain_grid.get_parent().name == TerrainBrushCatalog.GROUP_TERRAIN
		and terrain_library != null
		and terrain_library.get_item_list().size() == TerrainBrushCatalog.terrain_presets().size()
		and terrain_shapes.size() == 2
		and terrain_shapes[0] is BoxShape3D,
		(
			"实体地形画笔必须创建一个带视觉与碰撞定义的共享 GridMap："
			+ "parent=%s library_count=%d shapes=%s shape_class=%s result=%s"
			% [
				str(terrain_grid.get_parent().name) if terrain_grid else "null",
				terrain_library.get_item_list().size() if terrain_library else -1,
				str(terrain_shapes),
				terrain_shapes[0].get_class() if not terrain_shapes.is_empty() else "none",
				str(terrain_grid_result),
			]
		)
	) and ok
	var terrain_placement_root := Node3D.new()
	terrain_placement_root.name = "FS_TERRAIN_BRUSH_PLACEMENT_SMOKE"
	root.add_child(terrain_placement_root)
	var terrain_selected_sibling := Node3D.new()
	terrain_selected_sibling.name = "SELECTED_SIBLING"
	terrain_placement_root.add_child(terrain_selected_sibling)
	var terrain_placement_result := TerrainBrushCatalog.ensure_grid_map(
		terrain_placement_root,
		terrain_placement_root,
		terrain_selected_sibling
	)
	var terrain_placement_grid := terrain_placement_result.get("grid_map") as GridMap
	ok = _expect(
		bool(terrain_placement_result.get("ok", false))
		and terrain_placement_grid != null
		and terrain_placement_grid.get_parent() == terrain_placement_root,
		"实体地形画笔必须优先创建在当前选中节点的同一级：%s" % str(terrain_placement_result)
	) and ok
	var terrain_moved_parent := Node3D.new()
	terrain_moved_parent.name = "MOVED_PARENT"
	terrain_placement_root.add_child(terrain_moved_parent)
	terrain_placement_grid.reparent(terrain_moved_parent)
	var terrain_found_after_move := TerrainBrushCatalog.find_grid_map(terrain_placement_root)
	var terrain_resumed_result := TerrainBrushCatalog.ensure_grid_map(
		terrain_placement_root,
		terrain_placement_root,
		terrain_placement_grid
	)
	ok = _expect(
		terrain_found_after_move == terrain_placement_grid
		and TerrainBrushCatalog.find_grid_map(
			terrain_placement_root,
			terrain_moved_parent
		) == terrain_placement_grid
		and terrain_resumed_result.get("grid_map") == terrain_placement_grid
		and terrain_placement_grid.get_parent() == terrain_moved_parent,
		"实体地形画笔拖到其他父级后仍必须能按元数据继续编辑：%s" % str(terrain_resumed_result)
	) and ok
	var terrain_context_root := Node3D.new()
	terrain_context_root.name = "FS_TERRAIN_CONTEXT_SMOKE"
	root.add_child(terrain_context_root)
	var context_a_parent := Node3D.new()
	context_a_parent.name = "CONTEXT_A"
	terrain_context_root.add_child(context_a_parent)
	var context_a_selected := Node3D.new()
	context_a_selected.name = "SELECTED_A"
	context_a_parent.add_child(context_a_selected)
	var context_b_parent := Node3D.new()
	context_b_parent.name = "CONTEXT_B"
	terrain_context_root.add_child(context_b_parent)
	var context_b_selected := Node3D.new()
	context_b_selected.name = "SELECTED_B"
	context_b_parent.add_child(context_b_selected)
	var context_a_grid := TerrainBrushCatalog.ensure_grid_map(
		terrain_context_root,
		terrain_context_root,
		context_a_selected
	).get("grid_map") as GridMap
	var context_b_grid := TerrainBrushCatalog.ensure_grid_map(
		terrain_context_root,
		terrain_context_root,
		context_b_selected
	).get("grid_map") as GridMap
	var context_a_moved_parent := Node3D.new()
	context_a_moved_parent.name = "CONTEXT_A_MOVED"
	context_a_parent.add_child(context_a_moved_parent)
	if context_a_grid != null:
		context_a_grid.reparent(context_a_moved_parent)
	ok = _expect(
		context_a_grid != null
		and context_b_grid != null
		and TerrainBrushCatalog.find_grid_map(
			terrain_context_root,
			context_a_selected
		) == context_a_grid
		and TerrainBrushCatalog.find_grid_map(
			terrain_context_root,
			context_b_selected
		) == context_b_grid,
		"存在多个实体地形画笔时，操作目标必须跟随当前选中节点所在上下文，而不是固定选择第一个网格"
	) and ok
	terrain_context_root.free()
	var grass_params := TerrainBrushCatalog.brush_params("grass_platform", "circle", 3, 0)
	var grass_stamp := TerrainBrushCatalog.apply_stamp(
		terrain_grid,
		Vector3i.ZERO,
		grass_params
	)
	ok = _expect(
		bool(grass_stamp.get("ok", false))
		and int(grass_stamp.get("added", 0)) == 5
		and int(grass_stamp.get("used_cells", 0)) == 5,
		"3 × 3 圆形实体笔刷必须一次写入 5 个相互独立的网格格"
	) and ok
	var grass_repeat := TerrainBrushCatalog.apply_stamp(
		terrain_grid,
		Vector3i.ZERO,
		grass_params
	)
	ok = _expect(
		int(grass_repeat.get("changed", -1)) == 0
		and int(grass_repeat.get("unchanged", 0)) == 5
		and int(grass_repeat.get("used_cells", 0)) == 5,
		"重复刷同一区域必须按格子去重，而不是继续复制节点"
	) and ok
	var grass_line := TerrainBrushCatalog.apply_line(
		terrain_grid,
		Vector3i.ZERO,
		Vector3i(2, 0, 0),
		grass_params
	)
	ok = _expect(
		int(grass_line.get("added", 0)) == 6
		and int(grass_line.get("touched_cells", 0)) == 11
		and int(grass_line.get("used_cells", 0)) == 11,
		"按住拖动时必须补齐相邻采样点之间的网格，避免形成断点：%s" % str(grass_line)
	) and ok
	var eraser_params := TerrainBrushCatalog.brush_params(
		TerrainBrushCatalog.ERASER_ID,
		"circle",
		3,
		0
	)
	var erased := TerrainBrushCatalog.apply_stamp(
		terrain_grid,
		Vector3i(1, 0, 0),
		eraser_params
	)
	ok = _expect(
		int(erased.get("erased", 0)) == 5
		and int(erased.get("used_cells", 0)) == 6,
		"实体地形擦除必须只移除画笔网格中的格子"
	) and ok
	var thick_cell := Vector3i(8, 1, 8)
	var thick_params := TerrainBrushCatalog.brush_params(
		"stone_ground",
		"square",
		1,
		1,
		TerrainBrushCatalog.MAX_THICKNESS
	)
	var thick_stamp := TerrainBrushCatalog.apply_stamp(
		terrain_grid,
		thick_cell,
		thick_params
	)
	var thick_info := TerrainBrushCatalog.get_cell_info(terrain_grid, thick_cell)
	var thick_item := int(thick_info.get("item_id", TerrainBrushCatalog.INVALID_ITEM))
	var thick_shapes: Array = (
		terrain_library.get_item_shapes(thick_item)
		if terrain_library != null and thick_item >= 0
		else []
	)
	var thick_shape := thick_shapes[0] as BoxShape3D if not thick_shapes.is_empty() else null
	ok = _expect(
		bool(thick_stamp.get("ok", false))
		and int(thick_stamp.get("added", 0)) == 1
		and thick_item >= TerrainBrushCatalog.terrain_presets().size()
		and terrain_library.get_item_list().size() == TerrainBrushCatalog.terrain_presets().size() + 1
		and bool(thick_info.get("ok", false))
		and str(thick_info.get("preset_id", "")) == "stone_ground"
		and is_equal_approx(
			float(thick_info.get("thickness", 0.0)),
			TerrainBrushCatalog.MAX_THICKNESS
		)
		and thick_shape != null
		and is_equal_approx(thick_shape.size.y, TerrainBrushCatalog.MAX_THICKNESS),
		"实体地形画笔必须支持每格厚度，并为自定义厚度创建共享网格项目：%s" % str(thick_info)
	) and ok
	var thick_pick_position := terrain_grid.to_global(Vector3(
		float(thick_cell.x) * terrain_grid.cell_size.x,
		float(thick_cell.y) * terrain_grid.cell_size.y
			+ TerrainBrushCatalog.MAX_THICKNESS * 0.5
			+ TerrainBrushCatalog.MAX_CELL_PICK_DISTANCE * 0.60,
		float(thick_cell.z) * terrain_grid.cell_size.z
	))
	var thick_pick := TerrainBrushCatalog.pick_cell_at_world_position(
		terrain_grid,
		thick_pick_position
	)
	ok = _expect(
		bool(thick_pick.get("ok", false))
		and thick_pick.get("cell") == thick_cell
		and float(thick_pick.get("thickness", 0.0)) == TerrainBrushCatalog.MAX_THICKNESS,
		"2.00 米厚地形格必须能在顶部拾取范围内被反查选中：%s" % str(thick_pick)
	) and ok
	var removed_thick := TerrainBrushCatalog.remove_cell(terrain_grid, thick_cell)
	ok = _expect(
		bool(removed_thick.get("ok", false))
		and int(removed_thick.get("removed", 0)) == 1
		and int(removed_thick.get("used_cells", 0)) == 6
		and not bool(TerrainBrushCatalog.get_cell_info(terrain_grid, thick_cell).get("ok", false)),
		"单格删除必须只移除选中格并保留其余实体地形"
	) and ok
	var restored_thick := TerrainBrushCatalog.apply_stamp(
		terrain_grid,
		thick_cell,
		thick_params
	)
	ok = _expect(
		bool(restored_thick.get("ok", false))
		and int(restored_thick.get("added", 0)) == 1
		and int(restored_thick.get("used_cells", 0)) == 7,
		"自定义厚度格删除后必须可以按原参数恢复"
	) and ok
	var terrain_scene_path := "user://fs_terrain_brush_smoke.tscn"
	var terrain_packed := PackedScene.new()
	var terrain_pack_error := terrain_packed.pack(terrain_root)
	var terrain_save_error := ResourceSaver.save(terrain_packed, terrain_scene_path)
	var terrain_loaded_scene := load(terrain_scene_path) as PackedScene
	var terrain_loaded_root := (
		terrain_loaded_scene.instantiate()
		if terrain_loaded_scene != null
		else null
	)
	var terrain_loaded_grid := (
		TerrainBrushCatalog.find_grid_map(terrain_loaded_root)
		if terrain_loaded_root != null
		else null
	)
	var loaded_thick_info := (
		TerrainBrushCatalog.get_cell_info(terrain_loaded_grid, thick_cell)
		if terrain_loaded_grid != null
		else {}
	)
	var loaded_thick_item := int(
		loaded_thick_info.get("item_id", TerrainBrushCatalog.INVALID_ITEM)
	)
	var loaded_thick_shapes: Array = (
		terrain_loaded_grid.mesh_library.get_item_shapes(loaded_thick_item)
		if terrain_loaded_grid != null
		and terrain_loaded_grid.mesh_library != null
		and loaded_thick_item >= 0
		else []
	)
	var loaded_thick_shape := (
		loaded_thick_shapes[0] as BoxShape3D
		if not loaded_thick_shapes.is_empty()
		else null
	)
	ok = _expect(
		terrain_pack_error == OK
		and terrain_save_error == OK
		and terrain_loaded_grid != null
		and terrain_loaded_grid.mesh_library != null
		and terrain_loaded_grid.mesh_library.get_item_list().size() == TerrainBrushCatalog.terrain_presets().size() + 1
		and terrain_loaded_grid.get_used_cells().size() == 7
		and bool(loaded_thick_info.get("ok", false))
		and is_equal_approx(
			float(loaded_thick_info.get("thickness", 0.0)),
			TerrainBrushCatalog.MAX_THICKNESS
		)
		and loaded_thick_shape != null
		and is_equal_approx(loaded_thick_shape.size.y, TerrainBrushCatalog.MAX_THICKNESS),
		"实体地形画笔、自定义厚度及 MeshLibrary 碰撞定义必须随场景保存和重载：%s" % str(loaded_thick_info)
	) and ok
	var terrain_dock = AuthoringDock.new()
	root.add_child(terrain_dock)
	terrain_dock._edited_root = terrain_root
	terrain_dock._set_form_enabled(true)
	ok = _expect(
		terrain_dock._terrain_clear_button != null
		and not terrain_dock._terrain_clear_button.disabled
		and not terrain_dock._terrain_eraser_button.disabled
		and not terrain_dock._terrain_multiselect_button.disabled
		and not terrain_dock._terrain_select_group_button.disabled
		and not terrain_dock._terrain_copy_group_button.disabled
		and terrain_dock._terrain_thickness_spin != null
		and terrain_dock._terrain_apply_cell_button.disabled
		and terrain_dock._terrain_delete_cell_button.disabled
		and terrain_dock._terrain_eyedropper_button.disabled,
		"实体地形存在格子时清空和整组按钮必须可用，批量操作在未选中格时必须禁用"
	) and ok
	terrain_dock._on_toggle_terrain_multiselect_pressed()
	ok = _expect(
		terrain_dock._terrain_multiselect_mode_active
		and not terrain_dock._terrain_eraser_mode_active
		and terrain_dock._terrain_multiselect_button.text.contains("已开启")
		and bool(terrain_dock._terrain_multiselect_button.get_meta("fs_toggle_active", false))
		and terrain_dock._terrain_multiselect_button.has_theme_stylebox_override("normal"),
		"多格选择按钮必须切换到橙色启用的可拖动批量加选模式"
	) and ok
	terrain_dock._on_toggle_terrain_eraser_pressed()
	ok = _expect(
		terrain_dock._terrain_eraser_mode_active
		and not terrain_dock._terrain_multiselect_mode_active
		and terrain_dock._terrain_eraser_button.text.contains("已开启")
		and bool(terrain_dock._terrain_eraser_button.get_meta("fs_toggle_active", false))
		and not bool(terrain_dock._terrain_multiselect_button.get_meta("fs_toggle_active", true)),
		"橡皮擦与多格选择必须互斥切换，并同步切换橙色启用态"
	) and ok
	var terrain_camera := Camera3D.new()
	terrain_root.add_child(terrain_camera)
	terrain_camera.global_position = Vector3(0.0, 8.0, 0.0)
	terrain_camera.look_at(Vector3.ZERO, Vector3.FORWARD)
	var eraser_probe := InputEventMouseButton.new()
	eraser_probe.button_index = MOUSE_BUTTON_LEFT
	eraser_probe.pressed = true
	eraser_probe.position = Vector2(64.0, 64.0)
	ok = _expect(
		terrain_dock.handle_editor_3d_gui_input(terrain_camera, eraser_probe) == 1
		and terrain_dock._terrain_eraser_mode_active
		and not terrain_dock._terrain_group_selection_active()
		and not bool(terrain_dock._terrain_select_group_button.get_meta("fs_toggle_active", true)),
		"橡皮擦模式必须消费三维左键输入，不能穿透为 GridMap 选择并误亮整组地形"
	) and ok
	terrain_dock._set_terrain_mode(AuthoringDock.TERRAIN_MODE_NONE, false)
	terrain_dock._select_terrain_grid_map(terrain_grid)
	var group_gizmo_probe := InputEventMouseButton.new()
	group_gizmo_probe.button_index = MOUSE_BUTTON_LEFT
	group_gizmo_probe.pressed = true
	ok = _expect(
		terrain_dock._terrain_group_selection_active()
		and terrain_dock._terrain_select_group_button.text == "结束整组选择"
		and bool(terrain_dock._terrain_select_group_button.get_meta("fs_toggle_active", false))
		and terrain_dock.handle_editor_3d_gui_input(null, group_gizmo_probe) == 0,
		"选中整组地形必须进入可再次点击退出的橙色整组状态，并放行左键给 Godot gizmo"
	) and ok
	terrain_dock._on_toggle_terrain_multiselect_pressed()
	ok = _expect(
		terrain_dock._terrain_multiselect_mode_active
		and not terrain_dock._terrain_group_selection_active()
		and terrain_dock._terrain_select_group_button.text == "选中整组地形"
		and not bool(terrain_dock._terrain_select_group_button.get_meta("fs_toggle_active", true)),
		"进入单格或多格选择时必须自动退出整组选择，避免整组 gizmo 截断选格输入"
	) and ok
	terrain_dock._set_terrain_mode(AuthoringDock.TERRAIN_MODE_NONE, false)
	terrain_dock._select_terrain_grid_map(terrain_grid)
	terrain_dock._on_select_terrain_group_pressed()
	ok = _expect(
		not terrain_dock._terrain_group_selection_active()
		and terrain_dock._terrain_select_group_button.text == "选中整组地形",
		"再次点击整组按钮必须能结束整组选择"
	) and ok
	terrain_grid.set_cell_item(thick_cell, thick_item, 1)
	var duplicate_result := TerrainBrushCatalog.duplicate_grid_map(terrain_grid, terrain_root)
	var duplicate_grid := duplicate_result.get("grid_map") as GridMap
	var duplicate_thick_info := (
		TerrainBrushCatalog.get_cell_info(duplicate_grid, thick_cell)
		if duplicate_grid != null
		else {}
	)
	var duplicate_meta: Dictionary = (
		duplicate_grid.get_meta(TerrainBrushCatalog.META_KEY, {})
		if duplicate_grid != null
		else {}
	)
	var duplicate_palette: Dictionary = duplicate_meta.get("item_palette", {})
	var duplicate_group_source: GridMap = null
	if duplicate_grid != null:
		terrain_dock._selected_node = duplicate_grid
		duplicate_group_source = terrain_dock._terrain_group_grid_map()
	ok = _expect(
		bool(duplicate_result.get("ok", false))
		and duplicate_grid != null
		and duplicate_grid != terrain_grid
		and duplicate_grid.name != terrain_grid.name
		and duplicate_grid.get_parent() == terrain_grid.get_parent()
		and duplicate_grid.owner == terrain_root
		and duplicate_grid.mesh_library != terrain_library
		and duplicate_grid.get_used_cells().size() == terrain_grid.get_used_cells().size()
		and duplicate_grid.get_cell_item(thick_cell) == thick_item
		and duplicate_grid.get_cell_item_orientation(thick_cell) == 1
		and bool(duplicate_thick_info.get("ok", false))
		and duplicate_palette.has(str(thick_item))
		and TerrainBrushCatalog.is_terrain_grid_map(duplicate_grid)
		and duplicate_group_source == duplicate_grid
		and is_equal_approx(
			duplicate_grid.position.x - terrain_grid.position.x,
			float(duplicate_result.get("offset_x", 0.0))
		),
		"复制整组必须保留格子、朝向、厚度元数据、owner 和独立 MeshLibrary，并生成可继续选中的偏移副本：%s"
		% str(duplicate_result)
	) and ok
	if duplicate_grid:
		duplicate_grid.free()
	terrain_dock._selected_node = null
	terrain_grid.set_cell_item(thick_cell, thick_item, 0)
	var batch_cells := terrain_grid.get_used_cells()
	var batch_cell_a: Vector3i = batch_cells[0]
	var batch_cell_b: Vector3i = batch_cells[1]
	terrain_dock._terrain_selected_cells.clear()
	terrain_dock._terrain_selected_cells[batch_cell_a] = TerrainBrushCatalog.get_cell_info(
		terrain_grid,
		batch_cell_a
	)
	terrain_dock._terrain_selected_cells[batch_cell_b] = TerrainBrushCatalog.get_cell_info(
		terrain_grid,
		batch_cell_b
	)
	terrain_dock._terrain_selected_cell = batch_cell_a
	terrain_dock._terrain_has_selected_cell = true
	terrain_dock._select_option(terrain_dock._terrain_preset_option, "road_ground")
	terrain_dock._terrain_thickness_spin.value = TerrainBrushCatalog.default_thickness("road_ground")
	terrain_dock._on_apply_terrain_cell_pressed()
	ok = _expect(
		str(TerrainBrushCatalog.get_cell_info(
			terrain_grid,
			batch_cell_a
		).get("preset_id", "")) == "road_ground"
		and str(TerrainBrushCatalog.get_cell_info(
			terrain_grid,
			batch_cell_b
		).get("preset_id", "")) == "road_ground",
		"批量应用必须一次性更新所有已选中格"
	) and ok
	terrain_dock._on_delete_terrain_cell_pressed()
	ok = _expect(
		terrain_grid.get_cell_item(batch_cell_a) == TerrainBrushCatalog.INVALID_ITEM
		and terrain_grid.get_cell_item(batch_cell_b) == TerrainBrushCatalog.INVALID_ITEM,
		"批量删除必须一次性移除所有已选中格"
	) and ok
	terrain_dock._terrain_has_selected_cell = true
	terrain_dock._terrain_selected_cell = thick_cell
	terrain_dock._refresh_terrain_cell_action_state()
	terrain_dock._show_terrain_selection(thick_info)
	ok = _expect(
		not terrain_dock._terrain_apply_cell_button.disabled
		and not terrain_dock._terrain_delete_cell_button.disabled
		and not terrain_dock._terrain_eyedropper_button.disabled
		and terrain_dock._terrain_selection_preview != null
		and terrain_dock._terrain_selection_preview.owner == null,
		"单格被选中后调整按钮必须可用，临时选择预览不得进入场景持久层"
	) and ok
	var preview_cells := terrain_grid.get_used_cells()
	var preview_cell_count := mini(preview_cells.size(), 3)
	terrain_dock._terrain_selected_cells.clear()
	for index in range(preview_cell_count):
		var preview_cell: Vector3i = preview_cells[index]
		terrain_dock._terrain_selected_cells[preview_cell] = TerrainBrushCatalog.get_cell_info(
			terrain_grid,
			preview_cell
		)
	if not preview_cells.is_empty():
		terrain_dock._terrain_selected_cell = preview_cells[0]
	terrain_dock._terrain_has_selected_cell = not preview_cells.is_empty()
	terrain_dock._refresh_terrain_selection_preview()
	var preview_aligned: bool = (
		terrain_dock._terrain_selection_preview != null
		and terrain_dock._terrain_selection_preview is Node3D
		and terrain_dock._terrain_selection_preview.get_child_count() == preview_cell_count
	)
	var preview_debug: Array[String] = []
	for index in range(preview_cell_count):
		var preview_cell: Vector3i = preview_cells[index]
		var preview_instance := (
			terrain_dock._terrain_selection_preview.get_child(index) as MeshInstance3D
		)
		var actual_origin := (
			preview_instance.transform.origin
			if preview_instance != null
			else Vector3.INF
		)
		var expected_origin := terrain_grid.map_to_local(preview_cell)
		if (
			preview_instance == null
			or not _vector3_close(actual_origin, expected_origin, 0.0001)
		):
			preview_debug.append(
				"%s actual=%s expected=%s" % [
					str(preview_cell),
					str(actual_origin),
					str(expected_origin),
				]
			)
		preview_aligned = (
			preview_aligned
			and preview_instance != null
			and _vector3_close(
				actual_origin,
				expected_origin,
				0.0001
			)
		)
	ok = _expect(
		preview_aligned,
		(
			"单格和多格选择预览必须直接使用 GridMap.map_to_local，不能手工乘格坐标导致高亮错位："
			+ "; ".join(preview_debug)
		)
	) and ok
	terrain_dock._clear_terrain_selection()
	TerrainBrushCatalog.clear_terrain(terrain_grid)
	terrain_dock._refresh_terrain_clear_button_state()
	ok = _expect(
		terrain_dock._terrain_clear_button.disabled,
		"实体地形清空后清空按钮必须立即变灰"
	) and ok
	terrain_dock.free()
	if terrain_loaded_root:
		terrain_loaded_root.free()
	terrain_root.free()
	if FileAccess.file_exists(terrain_scene_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(terrain_scene_path))

	var repair_root := Node3D.new()
	var repair_mesh_host := MeshInstance3D.new()
	var repair_mesh := BoxMesh.new()
	repair_mesh_host.mesh = repair_mesh
	repair_root.add_child(repair_mesh_host)
	Schema.apply_to_node(repair_mesh_host, Schema.make(
		"placeholder_repair_smoke",
		"prop",
		"none",
		REGION_ID,
		["authored", "宝箱"]
	))
	var repair_model_result := VisualCatalog.apply_recommended_model(repair_mesh_host)
	repair_mesh_host.mesh = repair_mesh
	VisualCatalog.apply_recommended_models(repair_root)
	ok = _expect(
		bool(repair_model_result.get("ok", false)) and repair_mesh_host.mesh == null,
		"已有有效模型时也必须隐藏旧宿主占位方块"
	) and ok
	repair_root.free()

	var wall_host := StaticBody3D.new()
	var wall_collision := CollisionShape3D.new()
	var wall_shape := BoxShape3D.new()
	wall_shape.size = Vector3(40.0, 2.6, 0.6)
	wall_collision.shape = wall_shape
	wall_host.add_child(wall_collision)
	Schema.apply_to_node(wall_host, Schema.make(
		"route_wall_smoke",
		"prop",
		"none",
		REGION_ID,
		["authored", "route", "boundary"]
	))
	var wall_result := VisualCatalog.apply_recommended_model(wall_host)
	ok = _expect(
		VisualCatalog.model_id_from_node(wall_host) == "town_wall",
		"长墙宿主应推荐城镇石墙"
	) and ok
	ok = _expect(
		_vector3_close(
			_vector3_from_array(wall_result.get("visual", {}).get("fitted_size", [])),
			Vector3(40.0, 2.6, 0.6),
			0.02
		),
		"长墙拼片后的总包围盒必须贴合宿主：%s" % str(wall_result.get("visual", {}).get("fitted_size", []))
	) and ok
	ok = _expect(
		int(wall_result.get("visual", {}).get("repeat_count", 0)) > 1,
		"长墙应使用重复模块而不是单块拉伸"
	) and ok
	wall_host.free()

	var point_host := Node3D.new()
	Schema.apply_to_node(point_host, Schema.make(
		"single_point_building_smoke",
		"prop",
		"none",
		REGION_ID
	))
	var point_result := VisualCatalog.apply_model(point_host, VisualCatalog.find("crypt_small"))
	ok = _expect(bool(point_result.get("ok", false)), "无碰撞体的单点宿主也应能挂载建筑模型") and ok
	ok = _expect(
		_vector3_length(_vector3_from_array(point_result.get("visual", {}).get("fitted_size", []))) > 0.0001,
		"单点宿主挂载建筑后不能是空包围盒"
	) and ok
	var point_water_result := VisualCatalog.apply_model(point_host, VisualCatalog.find("river_straight"))
	ok = _expect(
		bool(point_water_result.get("ok", false))
		and VisualCatalog.is_model_visual_usable(point_host),
		"点状宿主挂载长河模型时应回退为单个有效实例"
	) and ok
	point_host.free()

	var plain_building_host := Node3D.new()
	var marker_building_host := Node3D.new()
	var marker_mesh := MeshInstance3D.new()
	marker_mesh.name = "AuthoringMarker"
	marker_mesh.mesh = SphereMesh.new()
	marker_building_host.add_child(marker_mesh)
	Schema.apply_to_node(plain_building_host, Schema.make(
		"plain_single_building_smoke",
		"prop"
	))
	Schema.apply_to_node(marker_building_host, Schema.make(
		"marker_single_building_smoke",
		"prop"
	))
	var plain_building_result := VisualCatalog.apply_model(
		plain_building_host,
		VisualCatalog.find("crypt_small")
	)
	var marker_building_result := VisualCatalog.apply_model(
		marker_building_host,
		VisualCatalog.find("crypt_small")
	)
	ok = _expect(
		_vector3_close(
			_vector3_from_array(plain_building_result.get("visual", {}).get("fitted_size", [])),
			_vector3_from_array(marker_building_result.get("visual", {}).get("fitted_size", [])),
			0.01
		),
		"AuthoringMarker 不应把单点建筑缩成不可见的标记尺寸"
	) and ok
	plain_building_host.free()
	marker_building_host.free()

	var repair_host := Node3D.new()
	var broken_visual := Node3D.new()
	broken_visual.name = "VISUAL_broken"
	repair_host.add_child(broken_visual)
	Schema.apply_to_node(repair_host, Schema.make(
		"repair_window_smoke",
		"decor",
		"none",
		REGION_ID,
		["authored", "window"]
	))
	var model_repair_result := VisualCatalog.apply_recommended_models(repair_host, repair_host)
	ok = _expect(
		int(model_repair_result.get("repaired", 0)) == 1
		and VisualCatalog.model_id_from_node(repair_host) == "town_window",
		"空壳 VISUAL_ 节点必须被批量操作识别并重建"
	) and ok
	ok = _expect(
		VisualCatalog.is_model_visual_usable(repair_host),
		"修复后的 VISUAL_ 节点必须包含有效几何体"
	) and ok
	repair_host.free()

	var spawn_object := _find_object(manifest, "spawn")
	if not spawn_object.is_empty():
		var spawn_node := source_root.get_node_or_null(str(spawn_object["node_path"]))
		ok = _expect(spawn_node != null and spawn_node.is_in_group("fs.kind.spawn"), "出生点应进入语义分组") and ok

	var duplicate_root := Node3D.new()
	var duplicate_a := Node3D.new()
	var duplicate_b := Node3D.new()
	duplicate_root.add_child(duplicate_a)
	duplicate_root.add_child(duplicate_b)
	Schema.apply_to_node(duplicate_a, Schema.make("duplicate_id", "prop"))
	Schema.apply_to_node(duplicate_b, Schema.make("duplicate_id", "prop"))
	var duplicate_manifest := Manifest.build(duplicate_root, "res://duplicate.tscn", REGION_ID)
	var duplicate_errors: Array = duplicate_manifest.get("validation", {}).get("errors", [])
	ok = _expect(_has_error_containing(duplicate_errors, "重复 semantic_id"), "重复 semantic_id 必须被清单校验拦截") and ok
	duplicate_root.free()

	var packed := PackedScene.new()
	var pack_error := packed.pack(source_root)
	ok = _expect(pack_error == OK, "作者场景应可打包") and ok
	if pack_error == OK:
		var packed_names: Array[String] = []
		var packed_state := packed.get_state()
		for index in range(packed_state.get_node_count()):
			packed_names.append("%s@%s" % [
				str(packed_state.get_node_name(index)),
				str(packed_state.get_node_path(index)),
			])
		var packed_has_pickup := false
		var packed_has_night_jar := false
		for path in packed_names:
			if path.begins_with("FS_ABILITY_SMOKE_PICKUP@"):
				packed_has_pickup = true
			if path.begins_with("FS_BREAKABLE_NIGHT_JAR@"):
				packed_has_night_jar = true
		ok = _expect(packed_has_pickup, "自定义拾取节点应进入打包场景：%s" % str(packed_names)) and ok
		ok = _expect(packed_has_night_jar, "现有可击破节点应进入打包场景：%s" % str(packed_names)) and ok
	if pack_error == OK:
		_ensure_project_dir(SCENE_PATH.get_base_dir())
		var save_error := ResourceSaver.save(packed, SCENE_PATH)
		ok = _expect(save_error == OK, "作者场景应可保存") and ok

	var write_result: Dictionary = {}
	var publish_result: Dictionary = {}
	if ok:
		write_result = Manifest.write_manifest(manifest, TEMP_OUTPUT_ROOT)
		ok = _expect(bool(write_result.get("ok", false)), "作者清单应可写出") and ok
	if ok:
		publish_result = Runtime.publish(manifest, str(write_result["json_path"]), SCENE_PATH)
		ok = _expect(bool(publish_result.get("ok", false)), "作者场景应可发布") and ok
	if ok:
		ok = _expect(Runtime.resolve_published_scene(REGION_ID) == SCENE_PATH, "运行时应解析到已发布作者场景") and ok

	var runtime_root := Node3D.new()
	root.add_child(runtime_root)
	var handle: Dictionary = {}
	if ok:
		handle = Runtime.build(runtime_root, region, SCENE_PATH)
		for _frame in range(3):
			await process_frame
		ok = _expect(bool(handle.get("authored", false)), "运行时应实例化作者场景") and ok
		ok = _expect(handle.get("route_gates", {}).size() == 2, "运行时应接管两道路线门") and ok
		ok = _expect(handle.get("markers", {}).has("rest_0"), "运行时应识别作者休息点") and ok
		var pickup_node: Node = handle.get("pickups", {}).get("smoke_pickup")
		var runtime_scene_root: Node = handle.get("scene_root")
		var authored_pickup := runtime_scene_root.find_child("FS_ABILITY_SMOKE_PICKUP", true, false) if runtime_scene_root else null
		ok = _expect(
			is_instance_valid(pickup_node) and pickup_node.get_script() == PickupScript,
			"拾取语义应注入拾取行为（已登记：%s，作者节点：%s，直接子节点：%s）" % [
				str(handle.get("pickups", {}).keys()),
				str(authored_pickup != null),
				str(runtime_scene_root.get_children().map(func(node: Node) -> String: return str(node.name))) if runtime_scene_root else "none",
			]
		) and ok
		var gate_node: Node = handle.get("gates", {}).get("seal_door")
		ok = _expect(is_instance_valid(gate_node) and gate_node.get_script() == GateScript, "门语义应注入门锁行为") and ok

		var breakable_object := _find_object(manifest, "night_jar")
		var scene_root: Node = handle.get("scene_root")
		var breakable_node: Node = scene_root.get_node_or_null(str(breakable_object.get("node_path", ""))) if not breakable_object.is_empty() else null
		ok = _expect(
			is_instance_valid(breakable_node) and breakable_node.get_script() == BreakableScript,
			"可击破语义应注入可击破行为：path=%s node=%s script=%s" % [
				str(breakable_object.get("node_path", "")),
				str(breakable_node != null),
				str(breakable_node.get_script()) if breakable_node else "none",
			]
		) and ok

	print("V2_AUTHORING objects=%s errors=%s warnings=%s route_gates=%s markers=%s authored=%s" % [
		int(manifest.get("object_count", 0)),
		errors.size(),
		warnings.size(),
		handle.get("route_gates", {}).size(),
		handle.get("markers", {}).size(),
		bool(handle.get("authored", false)),
	])

	runtime_root.free()
	source_root.free()
	_cleanup_temp_files(write_result)
	quit(0 if ok else 1)


func _find_object(p_manifest: Dictionary, p_id: String) -> Dictionary:
	for object in p_manifest.get("objects", []):
		if str(object.get("semantic_id", "")) == p_id:
			return object
	return {}


func _count_nodes_with_prefix(p_node: Node, p_prefix: String) -> int:
	var count := 0
	for child in p_node.get_children():
		if str(child.name).begins_with(p_prefix):
			count += 1
		count += _count_nodes_with_prefix(child, p_prefix)
	return count


func _has_error_containing(p_errors: Array, p_text: String) -> bool:
	for error in p_errors:
		if str(error).contains(p_text):
			return true
	return false


func _expect(p_condition: bool, p_message: String) -> bool:
	if not p_condition:
		push_error("AUTHORING_SMOKE: %s" % p_message)
	return p_condition


func _vector3_from_array(p_value: Variant) -> Vector3:
	if p_value is Vector3:
		return p_value
	if p_value is Array and p_value.size() >= 3:
		return Vector3(float(p_value[0]), float(p_value[1]), float(p_value[2]))
	return Vector3.ZERO


func _vector3_length(p_value: Vector3) -> float:
	return p_value.length()


func _vector3_close(p_left: Vector3, p_right: Vector3, p_tolerance: float) -> bool:
	return p_left.distance_to(p_right) <= p_tolerance


func _assign_owner(p_node: Node, p_owner: Node) -> void:
	for child in p_node.get_children():
		child.owner = p_owner
		_assign_owner(child, p_owner)


func _all_owned_by(p_node: Node, p_owner: Node) -> bool:
	if p_node != p_owner and p_node.owner != p_owner:
		return false
	for child in p_node.get_children():
		if not _all_owned_by(child, p_owner):
			return false
	return true


func _cleanup_temp_files(p_write_result: Dictionary) -> void:
	for path in [
		SCENE_PATH,
		SCENE_PATH + ".uid",
		BINDING_PATH,
		str(p_write_result.get("json_path", "")),
		str(p_write_result.get("markdown_path", "")),
	]:
		if path.is_empty():
			continue
		var absolute := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(absolute)


func _ensure_project_dir(p_path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(p_path))
