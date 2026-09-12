extends SceneTree

const MainScene := preload("res://scenes/main/V2FirstLoop.tscn")
const PlaytestMode := preload("res://scripts/authoring/FSPlaytestMode.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	ProjectSettings.set_setting(PlaytestMode.SETTING_PATH, true)
	var lab := MainScene.instantiate()
	root.add_child(lab)
	await process_frame

	var player := lab.get_node_or_null("Player") as PlayerController
	var ground := lab.get_node_or_null("PlaytestGround") as StaticBody3D
	var authored := lab.get_node_or_null("FS_REGION_FIRST_NIGHT")
	var started_y := player.global_position.y if player else 0.0
	var landed := false
	var floor_collider_name := ""
	for _index in range(150):
		await physics_frame
		if player and player.is_on_floor():
			landed = true
			floor_collider_name = _floor_collider_name(player)
			break

	var no_gameplay_nodes := (
		lab.get_node_or_null("Hud") == null
		and lab.get_node_or_null("RegionMap") == null
		and get_nodes_in_group("ghosts").is_empty()
	)
	var ok := true
	ok = _expect(bool(lab.get("_playtest_mode")), "主场景必须进入构建试玩模式") and ok
	ok = _expect(authored != null, "构建试玩必须加载作者场景") and ok
	ok = _expect(ground != null, "构建试玩必须生成临时 y=0 碰撞地面") and ok
	ok = _expect(player != null, "构建试玩必须生成玩家") and ok
	ok = _expect(started_y >= 3.5, "玩家应从空中开始下落，实际 y=%s" % started_y) and ok
	ok = _expect(landed, "玩家必须落到临时地面") and ok
	ok = _expect(not floor_collider_name.is_empty(), "玩家落地时必须记录实际碰撞面") and ok
	ok = _expect(
		floor_collider_name != "PlaytestGround" or player == null or player.global_position.y < 1.1,
		"只有落到临时兜底地面时才应接近 y=0，实际碰撞面=%s，y=%.2f" % [
			floor_collider_name,
			player.global_position.y if player else -1.0,
		]
	) and ok
	ok = _expect(no_gameplay_nodes, "构建试玩不得生成 HUD、地图或敌人") and ok
	print("V2_AUTHORING_PLAYTEST grounded=%s floor=%s start_y=%.2f player_y=%.2f authored=%s clean=%s" % [
		landed,
		floor_collider_name,
		started_y,
		player.global_position.y if player else -1.0,
		authored != null,
		no_gameplay_nodes,
	])
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
		return str((collider as Node).name)
	return ""
