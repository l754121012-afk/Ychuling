extends SceneTree

const REGION_JSON := "res://content/route/first_night_region.json"
const OUTPUT_DIR := "C:/Users/李泽文/Documents/Codex/2026-09-08/3d-f-crypt-custodian-green-chs/outputs"
const PNG_PATH := OUTPUT_DIR + "/map-v2-schematic.png"

# Schematic extent (world x / z). Padding is added around this in screen space.
const X_MIN := -20.0
const X_MAX := 20.0
const Z_MIN := -8.0
const Z_MAX := 8.0

const MAP_L := 46.0
const MAP_T := 150.0
const MAP_R := 1954.0
const MAP_B := 1050.0

# Palette (per AGENTS.md visual rules):
#   gold  = can be sent away / case / seal objective
#   red   = enemy attack warning / boss
#   white + yellow-green = player feedback / rest
const COLOR_CASE := Color(0.95, 0.76, 0.30)   # gold
const COLOR_BOSS := Color(0.86, 0.33, 0.31)   # red
const COLOR_SEAL := Color(1.00, 0.84, 0.38)   # bright gold
const COLOR_REST := Color(0.81, 0.91, 0.42)   # yellow-green
const COLOR_ABILITY := Color(0.98, 0.92, 0.55)
const COLOR_BORDER := Color(0.12, 0.16, 0.22)

var _zones: Array[Dictionary] = []
var _anchors: Array[Dictionary] = []
var _cjk_font: Font


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_load_data()

	root.size = Vector2i(2000, 1100)
	var canvas := MapCanvas.new()
	canvas.zones = _zones
	canvas.anchors = _anchors
	root.add_child(canvas)
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.size = Vector2(2000, 1100)
	canvas.queue_redraw()

	for _frame in range(3):
		await process_frame

	var img: Image = root.get_texture().get_image()
	var err := img.save_png(PNG_PATH)
	print("SCHEMATIC saved=%s err=%s size=%sx%s png=%s" % [err == OK, err, img.get_width(), img.get_height(), PNG_PATH])
	quit(0 if err == OK else 1)


func _load_data() -> void:
	if not FileAccess.file_exists(REGION_JSON):
		print("ERR missing region json: %s" % REGION_JSON)
		quit(1)
		return
	var raw := FileAccess.get_file_as_string(REGION_JSON)
	var parsed: Variant = JSON.parse_string(raw)
	if parsed == null or not (parsed is Dictionary):
		print("ERR invalid region json")
		quit(1)
		return
	var data: Dictionary = parsed
	var zone_list: Array = data.get("zones", [])
	for z in zone_list:
		if not (z is Dictionary):
			continue
		var zd: Dictionary = z
		var zt: String = str(zd.get("type", ""))
		# Districts become colored blocks; every other entry is an anchor marker.
		if zt == "district" or zt == "region":
			_zones.append(zd)
		else:
			_anchors.append(zd)


class MapCanvas extends Control:
	var zones: Array[Dictionary] = []
	var anchors: Array[Dictionary] = []
	# Windows CJK-capable system fonts; fallback_font has no Han glyphs so plain
	# draw_string of Chinese text comes out blank. SystemFont loads these locally.
	var _cjk: SystemFont

	func _ready() -> void:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Microsoft YaHei", "Microsoft YaHei UI", "SimHei", "Microsoft YaHei Light"])
		_cjk = f

	func _to_screen(p: Vector2) -> Vector2:
		var nx := (p.x - X_MIN) / (X_MAX - X_MIN)
		var ny := (p.y - Z_MIN) / (Z_MAX - Z_MIN)
		return Vector2(MAP_L + nx * (MAP_R - MAP_L), MAP_T + ny * (MAP_B - MAP_T))

	func _font() -> Font:
		return _cjk if _cjk != null else ThemeDB.fallback_font

	func _draw() -> void:
		draw_rect(Rect2(0, 0, size.x, size.y), Color(0.07, 0.09, 0.12))

		# Title
		draw_string(_font(), Vector2(46, 64), "《五星除灵》首夜城区 · 地图示意（平面）", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color(0.95, 0.96, 1.0))
		draw_string(_font(), Vector2(46, 112), "案件 → 拿取夜巡印章 → 重返 → 收工区 → 封印终点（行为循环）", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.72, 0.78, 0.86))

		# Zone blocks
		for z in zones:
			var zx0: float = float(z.get("min_x", 0.0))
			var zx1: float = float(z.get("max_x", 0.0))
			var depth: float = float(z.get("depth", 16.0))
			var name: String = str(z.get("name", ""))
			var color: Color = Color(str(z.get("floor_color", "#444444")))
			var p0 := _to_screen(Vector2(zx0, -depth * 0.5))
			var p1 := _to_screen(Vector2(zx1, depth * 0.5))
			var rect := Rect2(p0, p1 - p0)
			draw_rect(rect, color)
			var border := Color(color.lightened(0.25))
			draw_rect(rect, border, false, 2.0)
			# District label, centered high inside the block.
			var label_y := p0.y + 34.0
			draw_string(_font(), Vector2((p0.x + p1.x) * 0.5 - 90.0, label_y), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(0.98, 0.99, 1.0))
			draw_string(_font(), Vector2((p0.x + p1.x) * 0.5 - 62.0, label_y + 30.0), "EXP %s" % _two(zx0), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.85, 0.9, 0.95))

		# Center route line
		var line0 := _to_screen(Vector2(X_MIN + 0.5, 0.0))
		var line1 := _to_screen(Vector2(X_MAX - 0.5, 0.0))
		draw_dashed_line(line0, line1, Color(0.5, 0.6, 0.7), 2.0, 10.0)

		# Anchor markers
		for a in anchors:
			_draw_anchor(a)

		# Legend
		_draw_legend()

	func _draw_anchor(a: Dictionary) -> void:
		var aid: String = str(a.get("id", ""))
		var at: String = str(a.get("type", ""))
		var ax: float = float(a.get("x", 0.0))
		var az: float = float(a.get("z", 0.0))
		var pos := _to_screen(Vector2(ax, az))

		var label: String
		var color: Color
		var r: float = 17.0
		match aid:
			"rest":
				label = "休息点"
				color = COLOR_REST
			"case_sofa":
				label = "案件1·沙发灰影"
				color = COLOR_CASE
			"case_tv":
				label = "案件2·电视歌声"
				color = COLOR_CASE
			"case_wardrobe":
				label = "案件3·衣柜呼吸"
				color = COLOR_CASE
			"boss_room":
				label = "Boss·收工区"
				color = COLOR_BOSS
			"seal_endpoint":
				label = "封印终点"
				color = COLOR_SEAL
			_:
				return

		draw_circle(pos, r, Color(0.05, 0.07, 0.10))
		draw_circle(pos, r - 2.0, color)
		draw_circle(pos, r - 8.0, Color(1, 1, 1))

		# Ability marker sits beside 案件2 (night_stamp reward).
		if aid == "case_tv":
			var apo := pos + Vector2(0, 44)
			draw_circle(apo, r - 2.0, Color(0.05, 0.07, 0.10))
			draw_circle(apo, r - 4.0, COLOR_ABILITY)
			draw_string(_font(), apo + Vector2(-40, 6), "夜巡印章", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, COLOR_ABILITY)

		# Label under the marker, with outline for readability.
		var lp := pos + Vector2(-130.0, r + 24.0)
		for o in [Vector2(-2, -2), Vector2(2, -2), Vector2(-2, 2), Vector2(2, 2)]:
			draw_string(_font(), lp + o, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, COLOR_BORDER)
		draw_string(_font(), lp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1, 1, 1))

	func _draw_legend() -> void:
		var y0 := MAP_B + 8.0
		draw_string(_font(), Vector2(46, y0 - 10), "图例：", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.8, 0.85, 0.9))
		var items := [
			["案件（金）", COLOR_CASE],
			["Boss 收工区（红）", COLOR_BOSS],
			["封印终点（亮金）", COLOR_SEAL],
			["休息点（黄绿）", COLOR_REST],
			["夜巡印章（能力）", COLOR_ABILITY],
		]
		var x := 120.0
		for it in items:
			draw_rect(Rect2(x, y0 - 30.0, 18.0, 18.0), it[1])
			draw_string(_font(), Vector2(x + 24.0, y0 - 14.0), it[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.9, 0.92, 0.96))
			x += 210.0

	func _two(v: float) -> String:
		return str(int(v)) if v == floor(v) else "%.1f" % v
