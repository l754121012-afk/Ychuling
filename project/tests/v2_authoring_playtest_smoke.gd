extends SceneTree

const MainScene := preload("res://scenes/main/V2FirstLoop.tscn")
const PlaytestMode := preload("res://scripts/authoring/FSPlaytestMode.gd")
const GameView := preload("res://scripts/authoring/FSGameView.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var ok := true
	var approved_review_path := "res://authoring/scenes/spirit_sprawl_geometry.tscn"
	var rejected_candidate_path := "res://authoring/scenes/spirit_sprawl_candidate.tscn"
	ok = _expect(
		PlaytestMode.is_authoring_scene_path(approved_review_path),
		"基础几何审核场景必须允许作为 F5 目标"
	) and ok
	ok = _expect(
		not PlaytestMode.is_authoring_scene_path(rejected_candidate_path),
		"失败候选场景不得允许作为 F5 目标"
	) and ok
	ok = _expect(
		PlaytestMode.set_scene_path(approved_review_path),
		"基础几何审核场景必须可绑定为 F5 目标"
	) and ok
	ok = _expect(
		PlaytestMode.scene_path() == approved_review_path,
		"基础几何审核场景绑定后必须成为当前 F5 目标"
	) and ok
	ok = _expect(
		not PlaytestMode.set_scene_path(rejected_candidate_path),
		"失败候选场景不得写入 F5 目标"
	) and ok

	ProjectSettings.set_setting(PlaytestMode.SETTING_PATH, true)
	ProjectSettings.set_setting(
		PlaytestMode.SCENE_SETTING_PATH,
		"res://scenes/main/V2FirstLoop.tscn"
	)
	var fallback_lab := MainScene.instantiate()
	root.add_child(fallback_lab)
	await process_frame
	var fallback_handle = fallback_lab.get("_region_handle")
	var fallback_scene_path := str(fallback_handle.get("scene_path", ""))
	var expected_fallback_path := "res://authoring/scenes/first_night_authoring.tscn"
	ok = _expect(
		fallback_scene_path == expected_fallback_path,
		"非法 F5 场景必须回退到正式作者场景，实际 %s" % fallback_scene_path
	) and ok
	fallback_lab.queue_free()
	await process_frame
	await process_frame

	ProjectSettings.set_setting(PlaytestMode.SCENE_SETTING_PATH, approved_review_path)
	var lab := MainScene.instantiate()
	root.add_child(lab)
	await process_frame

	var player := lab.get_node_or_null("Player") as PlayerController
	var ground := lab.get_node_or_null("PlaytestGround") as StaticBody3D
	var handle = lab.get("_region_handle")
	var loaded_scene_path := str(handle.get("scene_path", ""))
	var authored_scene_root = handle.get("scene_root")
	var started_y := player.global_position.y if player else 0.0
	var landed := false
	var floor_collider_name := ""
	for _index in range(180):
		await physics_frame
		if player and player.is_on_floor():
			landed = true
			floor_collider_name = _floor_collider_name(player)
			break
	for _index in range(30):
		await process_frame
	lab.call("_update_follow_camera", 100.0)

	var no_gameplay_nodes := (
		lab.get_node_or_null("Hud") == null
		and lab.get_node_or_null("RegionMap") == null
		and get_nodes_in_group("ghosts").is_empty()
	)
	ok = _expect(bool(lab.get("_playtest_mode")), "主场景必须进入构建试玩模式") and ok
	ok = _expect(authored_scene_root != null, "构建试玩必须加载作者场景") and ok
	ok = _expect(
		loaded_scene_path == approved_review_path,
		"三倍扩区场景必须能直接作为 F5 目标，实际 %s" % loaded_scene_path
	) and ok
	ok = _expect(ground == null, "正式几何有承托时不得创建临时兜底地面") and ok
	ok = _expect(player != null, "构建试玩必须生成玩家") and ok
	var authoring_scale := player.scale.x if player else 0.0
	ok = _expect(
		player != null
		and absf(authoring_scale - PlaytestMode.AUTHORING_PLAYER_SCALE) < 0.001,
		"构建试玩中的玩家必须缩放为原来的三分之一，实际 scale=%s" % authoring_scale
	) and ok
	var spatial_metrics: Dictionary = player.get_spatial_metrics() if player else {}
	ok = _expect(
		player != null
		and absf(float(spatial_metrics.get("scale", 0.0)) - PlaytestMode.AUTHORING_PLAYER_SCALE) < 0.001,
		"玩家空间参数比例必须与节点缩放一致，实际 %s" % spatial_metrics.get("scale", 0.0)
	) and ok
	ok = _expect(
		player != null
		and absf(float(spatial_metrics.get("move_speed", 0.0)) - PlayerController.MOVE_SPEED * PlaytestMode.AUTHORING_PLAYER_SCALE) < 0.001
		and absf(float(spatial_metrics.get("dash_speed", 0.0)) - PlayerController.DASH_SPEED * PlaytestMode.AUTHORING_PLAYER_SCALE) < 0.001
		and absf(float(spatial_metrics.get("interact_range", 0.0)) - PlayerController.INTERACT_RANGE * PlaytestMode.AUTHORING_PLAYER_SCALE) < 0.001,
		"移动、冲刺和交互距离必须按玩家比例同步缩小，实际 %s" % spatial_metrics
	) and ok
	var camera := lab.get("_camera") as Camera3D
	var camera_target := GameView.camera_position_for_focus(
		player.global_position,
		PlaytestMode.AUTHORING_PLAYER_SCALE
	) if player else Vector3.ZERO
	var camera_error := camera.global_position.distance_to(camera_target) if camera and player else -1.0
	var camera_height := camera.global_position.y - player.global_position.y if camera and player else -1.0
	ok = _expect(
		camera != null
		and camera_error < 0.05,
		"构建试玩镜头必须按玩家比例同步缩小，实际误差 %.3f，镜头高度 %.3f" % [
			camera_error,
			camera_height,
		]
	) and ok
	ok = _expect(started_y >= 3.5, "玩家应从空中开始下落，实际 y=%s" % started_y) and ok
	ok = _expect(landed, "玩家必须落地") and ok
	ok = _expect(not floor_collider_name.is_empty(), "玩家落地时必须记录实际碰撞面") and ok
	ok = _expect(
		(
			floor_collider_name.begins_with("SURFACE_")
			or floor_collider_name.begins_with("SUPPORT_")
		),
		"玩家必须落在正式场景承托面上，实际碰撞面=%s，y=%.2f" % [
			floor_collider_name,
			player.global_position.y if player else -1.0,
		]
	) and ok

	var fall_spawn := player.spawn_point if player else Vector3.ZERO
	var health_before_fall := player.health if player else 0
	var fall_respawn_ok := false
	if player:
		player.stamina = 4.0
		player.beans = 1
		player.set("_stamina_regen_timer", 999.0)
		player.global_position = fall_spawn + Vector3.DOWN * (
			PlayerController.FALL_RESPAWN_DEPTH + 1.0
		)
		await physics_frame
		await physics_frame
		fall_respawn_ok = (
			player.global_position.distance_to(fall_spawn) < 0.5
			and is_equal_approx(player.stamina, 4.0)
			and player.beans == 1
			and player.health == health_before_fall
			and not bool(player.get("_defeated"))
		)
	ok = _expect(
		fall_respawn_ok,
		"坠落只应回出生点，不能扣血或重置耐力/豆子：pos=%s stamina=%.2f beans=%d health=%d" % [
			player.global_position if player else Vector3.ZERO,
			player.stamina if player else -1.0,
			player.beans if player else -1,
			player.health if player else -1,
		]
	) and ok
	ok = _expect(no_gameplay_nodes, "构建试玩不得生成 HUD、地图或敌人") and ok
	print("V2_AUTHORING_PLAYTEST grounded=%s floor=%s scale=%.6f move=%.3f dash=%.3f interact=%.3f camera_h=%.3f start_y=%.2f player_y=%.2f fall_respawn=%s authored=%s clean=%s" % [
		landed,
		floor_collider_name,
		authoring_scale,
		float(spatial_metrics.get("move_speed", 0.0)),
		float(spatial_metrics.get("dash_speed", 0.0)),
		float(spatial_metrics.get("interact_range", 0.0)),
		camera_height,
		started_y,
		player.global_position.y if player else -1.0,
		fall_respawn_ok,
		authored_scene_root != null,
		no_gameplay_nodes,
	])
	PlaytestMode.set_scene_path(approved_review_path)
	quit(0 if ok else 1)


func _expect(p_condition: bool, p_message: String) -> bool:
	if not p_condition:
		push_error(p_message)
	return p_condition


func _floor_collider_name(p_player: CharacterBody3D) -> String:
	if p_player == null:
		return ""
	var query := PhysicsRayQueryParameters3D.create(
		p_player.global_position + Vector3.UP * 0.25,
		p_player.global_position + Vector3.DOWN * 2.0
	)
	query.exclude = [p_player.get_rid()]
	var hit: Dictionary = p_player.get_world_3d().direct_space_state.intersect_ray(query)
	var collider: Object = hit.get("collider")
	if collider is Node:
		var node := collider as Node
		var direct_name := str(node.name)
		while node != null:
			var node_name := str(node.name)
			if node_name.begins_with("SURFACE_") or node_name.begins_with("SUPPORT_"):
				return node_name
			node = node.get_parent()
		return direct_name
	return ""
