extends SceneTree

const OUTPUT_DIR := "C:/Users/李泽文/Documents/Codex/2026-09-08/3d-f-crypt-custodian-green-chs/outputs"
const PNG_PATH := OUTPUT_DIR + "/map-v2-organic.png"

# World extent (matches the construction blueprint).
const X_MIN := -20.0
const X_MAX := 20.0
const Z_MIN := -8.0
const Z_MAX := 8.0

const MAP_L := 60.0
const MAP_T := 150.0
const MAP_R := 1940.0
const MAP_B := 1030.0

# Palette per AGENTS.md visual rules + map-style-notes organic look.
const COL_TEAL_CORE := Color(0.43, 0.90, 0.78)   # #6fe6c8
const COL_TEAL_MID  := Color(0.20, 0.72, 0.61)   # #33b8a0
const COL_GOLD      := Color(0.95, 0.76, 0.30)
const COL_GOLD_BRT  := Color(1.00, 0.84, 0.38)
const COL_REST      := Color(0.81, 0.91, 0.42)
const COL_BOSS_RED  := Color(0.86, 0.28, 0.26)
const COL_BOSS_RED2 := Color(0.42, 0.10, 0.11)
const COL_LABEL     := Color(0.98, 0.90, 0.62)
const COL_WINE_EDGE := Color(0.14, 0.06, 0.07)

# Districts: min_x / max_x / depth / label / theme seed
const DISTRICTS := [
	{"id": "nightwatch", "min_x": -19.5, "max_x": -10.0, "label": "夜巡司", "seed": 11.0, "sub": "安全屋"},
	{"id": "residential", "min_x": -10.0, "max_x": 4.5, "label": "居住区", "seed": 23.0, "sub": "夜市·案件"},
	{"id": "theater", "min_x": 4.5, "max_x": 10.5, "label": "旧剧场·电视台", "seed": 37.0, "sub": "散场·案件"},
	{"id": "seal", "min_x": 10.5, "max_x": 20.0, "label": "Boss 封印场", "seed": 53.0, "sub": "收工·封印"},
]

# Case battles: center X + 4 ghost spawn points (X,Z) + style.
const CASES := [
	{"label": "案件1 沙发灰影", "x": -8.0,
		"ghosts": [Vector2(-9.6, -1.7), Vector2(-8.3, -0.7), Vector2(-8.1, 0.9), Vector2(-6.7, 1.5)],
		"styles": ["挥", "弹", "圈", "冲"]},
	{"label": "案件2 电视歌声", "x": 0.0,
		"ghosts": [Vector2(-1.7, -1.5), Vector2(-0.7, -0.7), Vector2(0.7, 0.8), Vector2(1.5, 1.5)],
		"styles": ["弹", "圈", "冲", "挥"]},
	{"label": "案件3 衣柜呼吸", "x": 8.0,
		"ghosts": [Vector2(6.8, -1.6), Vector2(7.7, -0.7), Vector2(8.5, 0.8), Vector2(9.4, 1.6)],
		"styles": ["冲", "挥", "弹", "圈"]},
]

const BOSS_POS := Vector2(11.0, 0.0)
const BOSS_MINIONS := [Vector2(7.8, -1.8), Vector2(14.4, -1.4), Vector2(11.8, 2.7)]
const SEAL_POS := Vector2(16.0, 0.0)
const SEAL_DOOR_X := 15.4
const REST_POINTS := [Vector2(-13.5, 0.0), Vector2(-3.6, 0.0), Vector2(4.4, 0.0)]
const ROUTE_GATES_X := [-4.0, 4.0]
const ABILITY_SITE := Vector2(-8.0, -3.6)

var _cjk: SystemFont


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(2000, 1100)
	var canvas := OrganicMap.new()
	root.add_child(canvas)
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.size = Vector2(2000, 1100)
	canvas.queue_redraw()
	for _frame in range(4):
		await process_frame
	var img: Image = root.get_texture().get_image()
	var err := img.save_png(PNG_PATH)
	print("ORGANIC saved=%s err=%s size=%sx%s png=%s" % [err == OK, err, img.get_width(), img.get_height(), PNG_PATH])
	quit(0 if err == OK else 1)


class OrganicMap extends Control:
	var _cjk: SystemFont

	func _ready() -> void:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Microsoft YaHei", "Microsoft YaHei UI", "SimHei", "Microsoft YaHei Light"])
		_cjk = f

	func _font() -> Font:
		return _cjk if _cjk != null else ThemeDB.fallback_font

	func _to_screen(p: Vector2) -> Vector2:
		var nx := (p.x - X_MIN) / (X_MAX - X_MIN)
		var ny := (p.y - Z_MIN) / (Z_MAX - Z_MIN)
		return Vector2(MAP_L + nx * (MAP_R - MAP_L), MAP_T + ny * (MAP_B - MAP_T))

	# Organic blob points (irregular island edge).
	func _blob(cx: float, cy: float, rx: float, ry: float, seed: float, n: int = 72, k: float = 0.14) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in range(n):
			var t := TAU * float(i) / float(n)
			var noise := 1.0 + k * sin(t * 3.0 + seed) + 0.07 * sin(t * 7.0 + seed * 1.7) + 0.05 * sin(t * 13.0 + seed * 2.3)
			pts.push_back(Vector2(cx + cos(t) * rx * noise, cy + sin(t) * ry * noise))
		return pts

	func _draw() -> void:
		# Base: near-black ground.
		draw_rect(Rect2(0, 0, size.x, size.y), Color(0.055, 0.065, 0.095))
		# Wine-red vignette corners.
		_draw_vignette()
		# Dark canal bands between districts (x = boundaries).
		for bx in [-10.0, 4.5, 10.5]:
			var c0 := _to_screen(Vector2(bx - 0.22, Z_MIN))
			var c1 := _to_screen(Vector2(bx + 0.22, Z_MAX))
			for i in range(6):
				var w := 1.0 + float(i) * 0.9
				draw_line(c0, c1, Color(0.02, 0.03, 0.05, 0.5), w)

		# Glowing teal islands per district.
		for d in DISTRICTS:
			var p0 := _to_screen(Vector2(float(d["min_x"]), Z_MIN))
			var p1 := _to_screen(Vector2(float(d["max_x"]), Z_MAX))
			var cx := (p0.x + p1.x) * 0.5
			var cy := (p0.y + p1.y) * 0.5
			var rx := (p1.x - p0.x) * 0.5 * 0.98
			var ry := (p1.y - p0.y) * 0.5 * 0.94
			var seed := float(d["seed"])
			# layered glow: halo -> mid -> core
			draw_polygon(_blob(cx, cy, rx * 1.18, ry * 1.18, seed, 84, 0.20), _fill(Color(COL_TEAL_CORE.r, COL_TEAL_CORE.g, COL_TEAL_CORE.b, 0.10)))
			draw_polygon(_blob(cx, cy, rx, ry, seed, 84, 0.16), _fill(Color(COL_TEAL_MID.r, COL_TEAL_MID.g, COL_TEAL_MID.b, 0.28)))
			draw_polygon(_blob(cx, cy, rx * 0.66, ry * 0.60, seed + 9.0, 72, 0.12), _fill(COL_TEAL_CORE * Color(1, 1, 1, 0.22)))
			# dark shadow blobs (building/tree silhouettes)
			for s in range(5):
				var ang := seed + s * 1.7
				var ox := cx + cos(ang) * rx * 0.42
				var oy := cy + sin(ang) * ry * 0.42
				var r := 40.0 + (s % 3) * 34.0
				draw_circle(Vector2(ox, oy), r, Color(0.03, 0.05, 0.06, 0.75))

		# Main route line (Z≈0).
		var r0 := _to_screen(Vector2(X_MIN + 1.0, 0.0))
		var r1 := _to_screen(Vector2(X_MAX - 1.0, 0.0))
		draw_dashed_line(r0, r1, Color(0.55, 0.7, 0.75, 0.45), 2.0, 12.0)

		# Gates (gold padlocks) R1 / R2 / seal_door.
		for gx in ROUTE_GATES_X:
			_draw_lock(_to_screen(Vector2(gx, 0.0)), 1.0)
		_draw_lock(_to_screen(Vector2(SEAL_DOOR_X, 0.0)), 1.15, true)

		# Ability site (夜巡印章).
		var ap := _to_screen(ABILITY_SITE)
		draw_circle(ap, 15, Color(0.05, 0.07, 0.1))
		draw_circle(ap, 11, COL_GOLD_BRT)
		_draw_label(ap + Vector2(-52, 8), "夜巡印章", 22, COL_GOLD_BRT)

		# Cases (gold circles) + ghost dots.
		for c in CASES:
			var cp := _to_screen(Vector2(float(c["x"]), 0.0))
			_draw_case(cp)
			for gi in range(4):
				var g := _to_screen(Vector2(c["ghosts"][gi]))
				draw_circle(g, 7.0, Color(0.06, 0.08, 0.1))
				draw_circle(g, 4.5, Color(0.90, 0.50, 0.42))
				_draw_label(g + Vector2(8, -8), str(c["styles"][gi]), 15, Color(1, 0.95, 0.95))

		# Rest points (yellow-green).
		for rp in REST_POINTS:
			var rp2 := _to_screen(rp)
			draw_circle(rp2, 14, Color(0.05, 0.07, 0.1))
			draw_circle(rp2, 10, COL_REST)

		# Boss: red sawtooth ring + boss room.
		var bp := _to_screen(BOSS_POS)
		_draw_boss_ring(bp)
		for m in BOSS_MINIONS:
			var mp := _to_screen(m)
			draw_circle(mp, 7, Color(0.06, 0.08, 0.1))
			draw_circle(mp, 4.5, COL_BOSS_RED)

		# Seal endpoint (bright gold core).
		var sp := _to_screen(SEAL_POS)
		_draw_seal(sp)

		# District labels.
		for d in DISTRICTS:
			var p0 := _to_screen(Vector2(float(d["min_x"]), Z_MIN))
			var p1 := _to_screen(Vector2(float(d["max_x"]), Z_MAX))
			var cx := (p0.x + p1.x) * 0.5
			_draw_label(Vector2(cx - 70.0, p1.y - 46.0), str(d["label"]), 30, Color(1, 1, 1))
			_draw_label(Vector2(cx - 40.0, p1.y - 18.0), str(d["sub"]), 16, COL_GOLD)

		# Title + caption.
		_draw_label(Vector2(60, 66), "《五星除灵》首夜城区 · 施工布局（有机发光版）", 34, Color(0.98, 0.96, 0.9))
		_draw_label(Vector2(60, 114), "案件 → 夜巡印章 → 逐段开门 → 收工 Boss → 封印终点", 20, Color(0.75, 0.82, 0.88))

		# Rain streaks.
		_draw_rain()

		_draw_legend()

	func _fill(c: Color) -> PackedColorArray:
		var arr := PackedColorArray()
		arr.append(c)
		return arr

	func _draw_vignette() -> void:
		var corners := [
			[Vector2(0, 0), Vector2(360, 0), Vector2(0, 360)],
			[Vector2(size.x, 0), Vector2(size.x - 360, 0), Vector2(size.x, 360)],
			[Vector2(0, size.y), Vector2(360, size.y), Vector2(0, size.y - 360)],
			[Vector2(size.x, size.y), Vector2(size.x - 360, size.y), Vector2(size.x, size.y - 360)],
		]
		for tri in corners:
			draw_colored_polygon(PackedVector2Array(tri), Color(COL_WINE_EDGE.r, COL_WINE_EDGE.g, COL_WINE_EDGE.b, 0.35))

	func _draw_case(p: Vector2) -> void:
		draw_circle(p, 20, Color(0.05, 0.07, 0.1))
		draw_circle(p, 16, COL_GOLD)
		draw_circle(p, 6, Color(1, 1, 1))
		_draw_label(p + Vector2(-90, 30), "案件", 18, COL_GOLD)

	func _draw_lock(p: Vector2, scale: float, is_seal: bool = false) -> void:
		var s := 34.0 * scale
		var col := COL_GOLD_BRT if is_seal else COL_GOLD
		# shackle
		draw_arc(p + Vector2(0, -s * 0.25), s * 0.45, PI, TAU, 24, Color(0.10, 0.10, 0.12, 0.9), 6.0)
		# body
		var body := Rect2(p.x - s * 0.55, p.y - s * 0.05, s * 1.1, s * 0.85)
		draw_rect(body, Color(0.10, 0.10, 0.12, 0.9))
		draw_rect(body.grow(-3.0), col)
		draw_circle(p + Vector2(0, s * 0.30), s * 0.14, Color(0.10, 0.10, 0.12, 0.9))
		_draw_label(p + Vector2(-36, s * 1.25), "封印门" if is_seal else "路由门", 16, col)

	func _draw_boss_ring(p: Vector2) -> void:
		var R := 84.0
		# sawtooth ring
		var teeth := 20
		var pts := PackedVector2Array()
		for i in range(teeth * 2):
			var a := TAU * float(i) / float(teeth * 2)
			var rad := R if i % 2 == 0 else R * 0.82
			pts.push_back(p + Vector2(cos(a) * rad, sin(a) * rad))
		draw_colored_polygon(pts, Color(COL_BOSS_RED.r, COL_BOSS_RED.g, COL_BOSS_RED.b, 0.42))
		draw_polyline(pts, COL_BOSS_RED, 3.0, true)
		# core boss marker
		draw_circle(p, 26, Color(0.05, 0.07, 0.1))
		draw_circle(p, 21, COL_BOSS_RED)
		draw_circle(p, 8, Color(0.08, 0.02, 0.02))
		_draw_label(p + Vector2(-70, 48), "Boss 收工区", 20, COL_BOSS_RED)

	func _draw_seal(p: Vector2) -> void:
		draw_circle(p, 24, Color(0.05, 0.07, 0.1))
		draw_circle(p, 19, COL_GOLD_BRT)
		draw_circle(p, 16, Color(1.0, 0.96, 0.7, 0.45))
		draw_circle(p, 7, Color(1, 1, 1, 0.9))
		_draw_label(p + Vector2(-74, 42), "封印终点", 20, COL_GOLD_BRT)

	func _draw_rain() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 20260910
		for i in range(120):
			var x := rng.randf_range(0, size.x)
			var y := rng.randf_range(40, size.y)
			var len := rng.randf_range(24, 60)
			var a := Vector2(0.16, 0.16).normalized()
			draw_line(Vector2(x, y), Vector2(x, y) + a * len, Color(0.7, 0.82, 0.88, 0.10), 1.4)

	func _draw_label(p: Vector2, text: String, font_size: int, col: Color) -> void:
		for o in [Vector2(-2, -2), Vector2(2, -2), Vector2(-2, 2), Vector2(2, 2)]:
			draw_string(_font(), p + o, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.05, 0.05, 0.07))
		draw_string(_font(), p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)

	func _draw_legend() -> void:
		var y := MAP_B + 12.0
		_draw_label(Vector2(60, y), "图例：", 20, Color(0.82, 0.86, 0.9))
		var items := [
			["案件·可送走（金）", COL_GOLD],
			["Boss 收工区（红锯环）", COL_BOSS_RED],
			["封印终点（亮金）", COL_GOLD_BRT],
			["休息点（黄绿）", COL_REST],
			["夜巡印章（能力）", COL_GOLD_BRT],
		]
		var x := 150.0
		for it in items:
			draw_rect(Rect2(x, y - 20.0, 16, 16), it[1])
			_draw_label(Vector2(x + 22.0, y), it[0], 18, Color(0.92, 0.93, 0.96))
			x += 220.0
