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
	for _index in range(150):
		await physics_frame
		if player and player.is_on_floor():
			landed = true
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
	ok = _expect(player == null or player.global_position.y < 1.1, "玩家落地高度应接近 y=0 地面") and ok
	ok = _expect(no_gameplay_nodes, "构建试玩不得生成 HUD、地图或敌人") and ok
	print("V2_AUTHORING_PLAYTEST grounded=%s start_y=%.2f player_y=%.2f authored=%s clean=%s" % [
		landed,
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
