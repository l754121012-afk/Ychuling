extends SceneTree

# 顶视施工平面图：把关卡“能走/不能走/门/怪/特殊玩法”画实，去掉装饰性光晕。
const OUTPUT_DIR := "C:/Users/李泽文/Documents/Codex/2026-09-08/3d-f-crypt-custodian-green-chs/outputs"
const PNG_PATH := OUTPUT_DIR + "/map-v2-plan.png"

const X_MIN := -20.0
const X_MAX := 20.0
const Z_MIN := -8.0
const Z_MAX := 8.0

# 屏幕安全区
const SCREEN_L := 130.0
const SCREEN_T := 132.0
const SCREEN_R := 1930.0
const SCREEN_B := 900.0

# 区块面板颜色（按施工图）
const FILL_NIGHT := Color(0.17, 0.23, 0.31)   # 夜巡司 深蓝灰 #2b3a4e
const FILL_RESI  := Color(0.29, 0.23, 0.18)   # 居住区 棕 #4a3b2e
const FILL_THEATER := Color(0.29, 0.17, 0.23) # 旧剧场 酒红 #4a2c3c
const FILL_SEAL  := Color(0.18, 0.29, 0.25)   # 封印场 墨绿 #2f4a40
const WALL_DARK  := Color(0.05, 0.07, 0.10)
const WALL_TOP   := Color(0.45, 0.53, 0.60)
const WALL_IN    := Color(0.66, 0.72, 0.78)
const ROAD_FILL  := Color(0.60, 0.64, 0.68)
const ROAD_EDGE  := Color(0.84, 0.87, 0.90)
const ROAD_DASH  := Color(0.95, 0.78, 0.34)
const CANAL      := Color(0.02, 0.04, 0.06)
const GOLD       := Color(0.95, 0.76, 0.30)
const GOLD_BRT   := Color(1.00, 0.84, 0.38)
const REST_COL   := Color(0.81, 0.91, 0.42)
const ENEMY_COL  := Color(0.90, 0.40, 0.34)
const BOSS_RED   := Color(0.86, 0.28, 0.26)
const BOSS_RED2  := Color(0.42, 0.10, 0.11)
const LABEL      := Color(0.98, 0.92, 0.70)
const WHITE      := Color(0.96, 0.97, 0.98)
const HATCH      := Color(0.95, 0.86, 0.55)

# 区块（世界 X 范围）
const DISTRICTS := [
	{"min_x": -19.5, "max_x": -10.0, "fill": FILL_NIGHT, "label": "夜巡司", "sub": "起点 / 安全屋"},
	{"min_x": -10.0, "max_x": 4.5, "fill": FILL_RESI, "label": "居住区", "sub": "夜市摊棚 · 案件一/二"},
	{"min_x": 4.5, "max_x": 10.5, "fill": FILL_THEATER, "label": "旧剧场·电视台", "sub": "三层回环 · 案件三"},
	{"min_x": 10.5, "max_x": 20.0, "fill": FILL_SEAL, "label": "Boss 封印场", "sub": "站台·钟塔·封印"},
]

const GATE_X := [-10.0, 4.5, 10.5]     # 区块间暗沟
const ROUTE_GATES_X := [-4.0, 4.0]     # 路由门 R1 / R2
const SEAL_DOOR_X := 15.4
const ABILITY_SITE := Vector2(-8.0, -3.6)

const CASES := [
	{"label": "案件1  沙发下灰影", "x": -8.0, "room": "战斗房 A",
		"ghosts": [Vector2(-9.6, -1.7), Vector2(-8.3, -0.7), Vector2(-8.1, 0.9), Vector2(-6.7, 1.5)],
		"styles": ["挥", "弹", "圈", "冲"]},
	{"label": "案件2  电视里歌声", "x": 0.0, "room": "战斗房 B",
		"ghosts": [Vector2(-1.7, -1.5), Vector2(-0.7, -0.7), Vector2(0.7, 0.8), Vector2(1.5, 1.5)],
		"styles": ["弹", "圈", "冲", "挥"]},
	{"label": "案件3  衣柜里呼吸声", "x": 8.0, "room": "舞台 · 后台",
		"ghosts": [Vector2(6.8, -1.6), Vector2(7.7, -0.7), Vector2(8.5, 0.8), Vector2(9.4, 1.6)],
		"styles": ["冲", "挥", "弹", "圈"]},
]

const BOSS_POS := Vector2(11.0, 0.0)
const BOSS_MINIONS := [Vector2(7.8, -1.8), Vector2(14.4, -1.4), Vector2(11.8, 2.7)]
const SEAL_POS := Vector2(16.0, 0.0)
const REST_POINTS := [Vector2(-13.5, 0.0), Vector2(-3.6, 0.0), Vector2(4.4, 0.0)]

var _cjk: SystemFont

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(2000, 1100)
	var c := PlanMap.new()
	root.add_child(c)
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.size = Vector2(2000, 1100)
	c.queue_redraw()
	for _f in range(4):
		await process_frame
	var img: Image = root.get_texture().get_image()
	var err := img.save_png(PNG_PATH)
	print("PLAN saved=%s err=%s size=%sx%s png=%s" % [err == OK, err, img.get_width(), img.get_height(), PNG_PATH])
	quit(0 if err == OK else 1)


class PlanMap extends Control:
	var _cjk: SystemFont

	func _ready() -> void:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Microsoft YaHei", "Microsoft YaHei UI", "SimHei", "Microsoft YaHei Light"])
		_cjk = f

	func _font() -> Font:
		return _cjk if _cjk != null else ThemeDB.fallback_font

	# 世界 -> 屏幕
	func S(p: Vector2) -> Vector2:
		var nx := (p.x - X_MIN) / (X_MAX - X_MIN)
		var ny := (p.y - Z_MIN) / (Z_MAX - Z_MIN)
		return Vector2(SCREEN_L + nx * (SCREEN_R - SCREEN_L), SCREEN_T + ny * (SCREEN_B - SCREEN_T))

	func _rect(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> PackedVector2Array:
		return PackedVector2Array([a, b, c, d])

	func _draw() -> void:
		# 1) 虚空底（不可走）
		draw_rect(Rect2(0, 0, size.x, size.y), Color(0.045, 0.06, 0.085))

		# 2) 区块面板（房间地板 + 墙）
		for d in DISTRICTS:
			_draw_plate(float(d["min_x"]), float(d["max_x"]), d["fill"])

		# 3) 区块间暗沟（不可走边界）
		for gx in GATE_X:
			_draw_canal(gx)

		# 4) 房间隔墙（把每个区块分成房间，留门洞）
		_draw_partitions()

		# 5) 主路 + 支路（可走路面）
		_draw_roads()

		# 6) 平台高低差（hachure）
		_draw_platforms()

		# 7) 路由门 / 能力门 / 世界门（物理阻挡条 + 金色挂锁）
		for gx in ROUTE_GATES_X:
			_draw_route_gate(gx)
		_draw_shortcut_gate()
		_draw_seal_gate()

		# 8) 玩法标记
		for c in CASES:
			_draw_case(c)
		for rp in REST_POINTS:
			_draw_rest(rp)
		_draw_ability()
		_draw_boss()
		_draw_seal()
		_draw_minions()

		# 9) 地名 + 说明（不重叠）
		_draw_zone_labels()

		# 10) 标题 / 图例 / 指北 / 比例
		_draw_header()
		_draw_legend()
		_draw_compass_scale()

	# ---------- 地面 ----------
	func _draw_plate(minx: float, maxx: float, fill: Color) -> void:
		var inset := 0.10
		var a := S(Vector2(minx + inset, Z_MIN + 0.10))
		var b := S(Vector2(maxx - inset, Z_MIN + 0.10))
		var c := S(Vector2(maxx - inset, Z_MAX - 0.10))
		var d := S(Vector2(minx + inset, Z_MAX - 0.10))
		# 地板
		draw_colored_polygon(_rect(a, b, c, d), fill)
		# 墙底（外圈深色）
		draw_polyline(PackedVector2Array([a, b, c, d, a]), WALL_DARK, 10.0, true)
		# 墙顶（内侧高光表示墙厚）
		draw_polyline(PackedVector2Array([a, b, c, d, a]), WALL_TOP, 3.0, true)
		# 内阴角
		draw_polyline(PackedVector2Array([a + Vector2(8, 8), b + Vector2(-8, 8), c + Vector2(-8, -8), d + Vector2(8, -8), a + Vector2(8, 8)]), Color(WALL_IN.r, WALL_IN.g, WALL_IN.b, 0.5), 1.5, true)

	func _draw_canal(gx: float) -> void:
		var a := S(Vector2(gx - 0.30, Z_MIN))
		var b := S(Vector2(gx + 0.30, Z_MAX))
		draw_rect(Rect2(min(a.x, b.x), SCREEN_T, abs(b.x - a.x), SCREEN_B - SCREEN_T), CANAL)
		# 暗沟内几道深线
		for i in range(4):
			var x: float = lerpf(a.x, b.x, (float(i) + 0.5) / 4.0)
			draw_line(Vector2(x, SCREEN_T + 6), Vector2(x, SCREEN_B - 6), Color(0.10, 0.16, 0.14, 0.5), 1.0)

	# ---------- 房间隔墙（每区块内再分房，留 1.2 世界单位门洞） ----------
	func _draw_partitions() -> void:
		# 夜巡司：起点大堂 | 休息前厅
		_room_wall(-14.0, -7.6, 7.6)
		# 居住区：战斗房A | 摊棚中庭 | 战斗房B
		_room_wall(-5.9, -7.6, -1.2)
		_room_wall(-5.9, 1.2, 7.6)
		_room_wall(-0.9, -7.6, -1.2)
		_room_wall(-0.9, 1.2, 7.6)
		# 旧剧场：前厅 | 观众席 | 舞台/后台
		_room_wall(6.2, -7.6, 7.6)
		# 封印场：站台 | 钟塔台阶 | 封印
		_room_wall(13.8, -7.6, 7.6)

	func _room_wall(x: float, z0: float, z1: float) -> void:
		var a := S(Vector2(x, z0))
		var b := S(Vector2(x, z1))
		draw_line(a, b, WALL_DARK, 8.0)
		draw_line(a, b, WALL_TOP, 2.0)
		# 门洞标记（在 Z=0 主路处留门口）
		var g0 := S(Vector2(x, -1.5))
		var g1 := S(Vector2(x, 1.5))
		draw_line(g0, g1, Color(0.55, 0.82, 0.78), 3.0)

	# ---------- 路面 ----------
	func _draw_roads() -> void:
		# 主路：X 全宽，Z≈0
		var m0 := S(Vector2(X_MIN + 0.6, -1.5))
		var m1 := S(Vector2(X_MAX - 0.6, -1.5))
		var m2 := S(Vector2(X_MAX - 0.6, 1.5))
		var m3 := S(Vector2(X_MIN + 0.6, 1.5))
		draw_colored_polygon(_rect(m0, m1, m2, m3), ROAD_FILL)
		draw_polyline(PackedVector2Array([m0, m1]), ROAD_EDGE, 2.0, true)
		draw_polyline(PackedVector2Array([m3, m2]), ROAD_EDGE, 2.0, true)
		# 中心虚线
		var r0 := S(Vector2(X_MIN + 1.0, 0.0))
		var r1 := S(Vector2(X_MAX - 1.0, 0.0))
		draw_dashed_line(r0, r1, ROAD_DASH, 2.5, 18.0)

		# 支路1：主路 -> 夜巡印章（南侧）
		var pa := S(Vector2(-8.0, 0.0))
		var pb := S(ABILITY_SITE)
		draw_line(pa, pb, ROAD_FILL, 14.0)
		draw_line(pa, pb, ROAD_EDGE, 1.5)

		# 支路2：天台抄近路（北侧，经居住区->剧场顶棚，需 night_stamp）
		var s0 := S(Vector2(-8.0, -3.6))
		var s1 := S(Vector2(-5.5, -6.4))
		var s2 := S(Vector2(10.0, -6.4))
		var s3 := S(Vector2(12.0, -2.2))
		var sp := PackedVector2Array([s0, s1, s2, s3])
		draw_polyline(sp, ROAD_FILL, 12.0, true)
		draw_polyline(sp, ROAD_EDGE, 1.5, true)

	# ---------- 平台高低差（斜线填充） ----------
	func _draw_platforms() -> void:
		# 居住区摊棚 0.4/0.9/1.3（主路南侧）
		_hatch(Vector2(-4.8, 2.4), Vector2(-1.0, 6.6))
		_draw_label(S(Vector2(-2.9, 4.5)) + Vector2(-70, -22), "摊棚 0.4/0.9/1.3", 15, HATCH)
		# 旧剧场 观众席/舞台（北侧+中）
		_hatch(Vector2(6.4, -6.6), Vector2(10.0, -3.2))
		_draw_label(S(Vector2(8.2, -4.9)) + Vector2(-60, -22), "观众席·舞台·包厢", 15, HATCH)
		# 封印场 站台/钟塔台阶/断桥（主路北侧）
		_hatch(Vector2(11.0, -6.6), Vector2(15.2, -3.0))
		_draw_label(S(Vector2(13.1, -4.8)) + Vector2(-60, -22), "站台·钟塔台阶·断桥", 15, HATCH)

	func _hatch(p0: Vector2, p1: Vector2) -> void:
		var a := S(p0)
		var b := S(Vector2(p1.x, p0.y))
		var c := S(p1)
		var d := S(Vector2(p0.x, p1.y))
		draw_colored_polygon(_rect(a, b, c, d), Color(0.30, 0.30, 0.26, 0.5))
		# 斜线
		var span := b.x - a.x
		for i in range(int(span / 9.0)):
			var x := a.x + i * 9.0
			draw_line(Vector2(x, c.y), Vector2(x + (c.y - a.y), a.y), Color(HATCH.r, HATCH.g, HATCH.b, 0.35), 1.0)

	# ---------- 门 ----------
	func _draw_route_gate(x: float) -> void:
		var a := S(Vector2(x, Z_MIN + 0.4))
		var b := S(Vector2(x, Z_MAX - 0.4))
		# 阻挡墙（跨全 Z，除主路门口外）
		draw_line(a, b, Color(0.03, 0.05, 0.07), 12.0)
		draw_line(a, b, WALL_TOP, 2.0)
		var lock := S(Vector2(x, 0.0))
		_draw_lock(lock, 1.0)
		_draw_label(lock + Vector2(14, -44), "路由门 R%d" % (1 if x < 0 else 2), 18, GOLD)

	func _draw_shortcut_gate() -> void:
		var p := S(Vector2(-5.2, -6.4))
		_draw_lock(p, 0.9)
		_draw_label(p + Vector2(-70, -40), "捷径门(需夜巡印章)", 16, GOLD)

	func _draw_seal_gate() -> void:
		var a := S(Vector2(SEAL_DOOR_X, Z_MIN + 0.4))
		var b := S(Vector2(SEAL_DOOR_X, Z_MAX - 0.4))
		draw_line(a, b, Color(0.03, 0.05, 0.07), 12.0)
		draw_line(a, b, WALL_TOP, 2.0)
		var lock := S(Vector2(SEAL_DOOR_X, 0.0))
		_draw_lock(lock, 1.15, true)
		_draw_label(lock + Vector2(14, -46), "封印门(需击败Boss)", 18, GOLD_BRT)

	func _draw_lock(p: Vector2, sc: float, is_seal: bool = false) -> void:
		var s := 34.0 * sc
		var col := GOLD_BRT if is_seal else GOLD
		draw_arc(p + Vector2(0, -s * 0.25), s * 0.45, PI, TAU, 24, Color(0.08, 0.09, 0.11, 0.95), 6.0)
		var body := Rect2(p.x - s * 0.55, p.y - s * 0.05, s * 1.1, s * 0.85)
		draw_rect(body, Color(0.08, 0.09, 0.11, 0.95))
		draw_rect(body.grow(-3.0), col)
		draw_circle(p + Vector2(0, s * 0.30), s * 0.14, Color(0.08, 0.09, 0.11, 0.95))

	# ---------- 玩法标记 ----------
	func _draw_case(c: Dictionary) -> void:
		var cp := S(Vector2(float(c["x"]), 0.0))
		draw_circle(cp, 22, Color(0.04, 0.06, 0.08))
		draw_circle(cp, 17, GOLD)
		draw_circle(cp, 6, Color(1, 1, 1))
		for gi in range(4):
			var g := S(Vector2(c["ghosts"][gi]))
			draw_circle(g, 9, Color(0.05, 0.07, 0.08))
			draw_circle(g, 6, ENEMY_COL)
			_draw_label(g + Vector2(12, -6), str(c["styles"][gi]), 15, Color(1, 0.94, 0.92))

	func _draw_rest(p: Vector2) -> void:
		var s := S(p)
		draw_circle(s, 15, Color(0.05, 0.08, 0.06))
		draw_circle(s, 11, REST_COL)
		_draw_label(s + Vector2(-30, 34), "休息", 14, REST_COL)

	func _draw_ability() -> void:
		var p := S(ABILITY_SITE)
		draw_circle(p, 20, Color(0.05, 0.07, 0.10))
		draw_circle(p, 15, GOLD_BRT)
		_draw_label(p + Vector2(-74, -34), "夜巡印章(能力)", 16, GOLD_BRT)

	func _draw_boss() -> void:
		var p := S(BOSS_POS)
		var R := 88.0
		# 红色锯齿环（只能走进，中为 Boss）
		var teeth := 20
		var pts := PackedVector2Array()
		for i in range(teeth * 2):
			var a := TAU * float(i) / float(teeth * 2)
			var rad := R if i % 2 == 0 else R * 0.82
			pts.push_back(p + Vector2(cos(a) * rad, sin(a) * rad))
		draw_colored_polygon(pts, Color(BOSS_RED.r, BOSS_RED.g, BOSS_RED.b, 0.30))
		draw_polyline(pts, BOSS_RED, 3.0, true)
		draw_circle(p, 28, Color(0.04, 0.02, 0.02))
		draw_circle(p, 22, BOSS_RED)
		draw_circle(p, 9, Color(0.08, 0.02, 0.02))
		_draw_label(p + Vector2(-78, 56), "收工 Boss(需支线)", 18, BOSS_RED)

	func _draw_minions() -> void:
		for m in BOSS_MINIONS:
			var mp := S(m)
			draw_circle(mp, 9, Color(0.05, 0.07, 0.08))
			draw_circle(mp, 6, BOSS_RED)

	func _draw_seal() -> void:
		var p := S(SEAL_POS)
		draw_circle(p, 26, Color(0.04, 0.06, 0.08))
		draw_circle(p, 20, GOLD_BRT)
		draw_circle(p, 16, Color(1.0, 0.96, 0.7, 0.45))
		draw_circle(p, 7, Color(1, 1, 1, 0.9))
		_draw_label(p + Vector2(-70, 44), "封印终点", 18, GOLD_BRT)

	# ---------- 文字 ----------
	func _draw_zone_labels() -> void:
		for d in DISTRICTS:
			var a := S(Vector2(float(d["min_x"]), Z_MIN))
			var b := S(Vector2(float(d["max_x"]), Z_MAX))
			var cx := (a.x + b.x) * 0.5
			var cy := a.y + 46.0
			_draw_label(Vector2(cx - 70, cy), str(d["label"]), 26, WHITE)
			_draw_label(Vector2(cx - 60, cy + 32), str(d["sub"]), 15, GOLD)

	func _draw_header() -> void:
		_draw_label(Vector2(60, 66), "《五星除灵》首夜城区 · 顶视施工平面图", 32, Color(0.98, 0.96, 0.9))
		_draw_label(Vector2(60, 108), "自西向东推进：起点 → 清案逐段开门 → 收工 Boss → 封印终点", 19, Color(0.72, 0.80, 0.86))

	func _draw_legend() -> void:
		var y := SCREEN_B + 66.0
		_draw_label(Vector2(60, y), "图例", 20, Color(0.86, 0.90, 0.94))
		var items := [
			["案件点(金)", GOLD],
			["敌人出生点(红)", ENEMY_COL],
			["休息点(黄绿)", REST_COL],
			["能力点(亮金)", GOLD_BRT],
			["Boss(红锯环)", BOSS_RED],
			["封印终点", GOLD_BRT],
		]
		var x := 150.0
		for it in items:
			draw_rect(Rect2(x, y - 20.0, 16, 16), it[1])
			_draw_label(Vector2(x + 22.0, y), it[0], 17, Color(0.92, 0.93, 0.96))
			x += 250.0
		_draw_label(Vector2(60, y + 40), "深色条=不可走墙/暗沟；浅色带=可走主路/支路；斜线=平台高低差", 16, Color(0.70, 0.76, 0.82))

	func _draw_compass_scale() -> void:
		var ax := SCREEN_R - 120.0
		var ay := SCREEN_T - 10.0
		_draw_label(Vector2(ax - 14, ay - 48), "北", 22, WHITE)
		draw_line(Vector2(ax, ay + 10), Vector2(ax, ay - 40), WALL_TOP, 3.0)
		draw_line(Vector2(ax - 10, ay - 28), Vector2(ax, ay - 42), WALL_TOP, 2.5)
		draw_line(Vector2(ax + 10, ay - 28), Vector2(ax, ay - 42), WALL_TOP, 2.5)
		# 比例尺
		var sx := SCREEN_L
		var sy := SCREEN_B + 16.0
		draw_line(Vector2(sx, sy), Vector2(sx + 180, sy), ROAD_DASH, 3.0)
		for i in range(5):
			var px := sx + i * 45.0
			draw_line(Vector2(px, sy - 6), Vector2(px, sy + 6), ROAD_DASH, 2.0)
		_draw_label(Vector2(sx, sy + 24), "约 10 世界单位", 15, Color(0.70, 0.76, 0.82))

	func _draw_label(p: Vector2, text: String, font_size: int, col: Color) -> void:
		for o in [Vector2(-2, -2), Vector2(2, -2), Vector2(-2, 2), Vector2(2, 2)]:
			draw_string(_font(), p + o, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.03, 0.03, 0.05))
		draw_string(_font(), p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)
