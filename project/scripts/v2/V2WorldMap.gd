class_name V2WorldMap
extends Control

# 世界地图节点图：把《FIVESTAR》首夜城区当作一张节点式地图（参考“全图”连接拓扑，
# 但用我方区域与玩法角色重新落地）。每个节点是一个“房间/区段”，用 build state 标记开发进度。
#
# build state 语义（用户要求：正在做/做过的区域用特殊颜色标记）
#   LOCKED        = 尚未开始（灰）
#   IN_PROGRESS   = 正在做（琥珀/高亮）
#   DONE          = 已做（绿）

enum BuildState { LOCKED, IN_PROGRESS, DONE }

const STATE_LOCKED := BuildState.LOCKED
const STATE_IN_PROGRESS := BuildState.IN_PROGRESS
const STATE_DONE := BuildState.DONE

const COLOR_LOCKED := Color(0.30, 0.34, 0.42, 0.85)
const COLOR_IN_PROGRESS := Color(0.96, 0.74, 0.26)
const COLOR_DONE := Color(0.36, 0.85, 0.52)
const COLOR_BG := Color(0.07, 0.10, 0.12, 0.96)
const COLOR_EDGE := Color(0.56, 0.62, 0.72, 0.45)
const COLOR_TEXT := Color("#e9eef6")
const COLOR_DIM := Color(0.62, 0.68, 0.78, 0.9)

const NODE_W := 46.0
const NODE_H := 30.0
const GAP := 62.0
const ORIGIN := Vector2(70.0, 90.0)

## 房间数据：{id, name, role, x, y, state}
var rooms: Array[Dictionary] = []
## 连接：[ [idA, idB], ... ]（无向）
var edges: Array = []
## 当前玩家所在房间 id（用于高亮）
var current_id: String = ""
var _pulse_t := 0.0


static func state_color(p_state: int) -> Color:
	match p_state:
		STATE_IN_PROGRESS:
			return COLOR_IN_PROGRESS
		STATE_DONE:
			return COLOR_DONE
		_:
			return COLOR_LOCKED


func room(p_id: String) -> Dictionary:
	for r in rooms:
		if r.get("id", "") == p_id:
			return r
	return {}


func set_state(p_id: String, p_state: int) -> void:
	for r in rooms:
		if r.get("id", "") == p_id:
			r["state"] = p_state
			queue_redraw()
			return


func state_of(p_id: String) -> int:
	return int(room(p_id).get("state", STATE_LOCKED))


## 标记当前玩家所在房间并刷新。
func set_current(p_id: String) -> void:
	if current_id == p_id:
		return
	current_id = p_id
	queue_redraw()


## 依世界 X 坐标返回最近房间 id（找不到则回退空串）。
func room_for_world_x(p_wx: float) -> String:
	var best_id := ""
	var best_d := INF
	for r in rooms:
		var wx := float(r.get("wx", 0.0))
		var d := absf(wx - p_wx)
		if d < best_d:
			best_d = d
			best_id = str(r.get("id", ""))
	return best_id


func _process(delta: float) -> void:
	if current_id.is_empty() or not is_visible_in_tree():
		return
	_pulse_t += delta
	queue_redraw()


## 从数据建立节点图。seed 是完整图的数据（房间+连接），返回一个带默认状态的副本以供每次调用重建。
static func seed_night_watch() -> Dictionary:
	# 角色映射：rest=休息/安全；case=案件；encounter=遭遇；gate=门/捷径；key=能力；ritual=仪式；clue=线索
	return {
		"rooms": [
			{"id": "rest", "name": "夜巡司·休息", "role": "rest", "x": 0, "y": 2, "wx": -13.5, "state": STATE_DONE},
			{"id": "nw_hub", "name": "夜巡司·值房", "role": "encounter", "x": 1, "y": 2, "wx": -13.0, "state": STATE_IN_PROGRESS},
			{"id": "nw_clue", "name": "线索·档案", "role": "clue", "x": 0, "y": 1, "wx": -12.0, "state": STATE_IN_PROGRESS},
			{"id": "nw_gate", "name": "捷径·夜巡印", "role": "gate", "x": 2, "y": 2, "wx": -10.5, "state": STATE_IN_PROGRESS},
			{"id": "case_sofa", "name": "案件1·沙发", "role": "case", "x": 1, "y": 1, "wx": -8.0, "state": STATE_IN_PROGRESS},
			{"id": "nw_key", "name": "夜巡印章", "role": "key", "x": 2, "y": 0, "wx": -9.0, "state": STATE_LOCKED},
			{"id": "residential", "name": "居住区", "role": "zone", "x": 3, "y": 2, "wx": 4.0, "state": STATE_LOCKED},
			{"id": "case_tv", "name": "案件2·电视", "role": "case", "x": 4, "y": 1, "wx": 0.0, "state": STATE_LOCKED},
			{"id": "theater", "name": "旧剧场", "role": "zone", "x": 5, "y": 2, "wx": 4.5, "state": STATE_LOCKED},
			{"id": "case_wardrobe", "name": "案件3·衣柜", "role": "case", "x": 6, "y": 1, "wx": 8.0, "state": STATE_LOCKED},
			{"id": "boss", "name": "Boss·收工区", "role": "ritual", "x": 7, "y": 2, "wx": 11.0, "state": STATE_LOCKED},
			{"id": "seal", "name": "封印终点", "role": "objective", "x": 8, "y": 2, "wx": 18.0, "state": STATE_LOCKED},
		],
		"edges": [
			["rest", "nw_hub"],
			["rest", "nw_clue"],
			["nw_clue", "case_sofa"],
			["nw_hub", "case_sofa"],
			["nw_hub", "nw_gate"],
			["case_sofa", "nw_key"],
			["nw_gate", "residential"],
			["residential", "case_tv"],
			["case_tv", "theater"],
			["theater", "case_wardrobe"],
			["case_wardrobe", "boss"],
			["boss", "seal"],
		],
	}


func load_from(p_data: Dictionary) -> void:
	rooms = []
	edges = []
	for r in p_data.get("rooms", []):
		rooms.append(r.duplicate())
	for e in p_data.get("edges", []):
		edges.append(e.duplicate())
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_BG)

	# 先画连接，再画节点，避免节点被连线覆盖。
	for e in edges:
		var a := room(str(e[0]))
		var b := room(str(e[1]))
		if a.is_empty() or b.is_empty():
			continue
		var pa := _center(a)
		var pb := _center(b)
		draw_line(pa, pb, COLOR_EDGE, 3.0)

	for r in rooms:
		var pos := _center(r) - Vector2(NODE_W, NODE_H) * 0.5
		var color := state_color(int(r.get("state", STATE_LOCKED)))
		var rect := Rect2(pos, Vector2(NODE_W, NODE_H))
		draw_rect(rect, color)
		draw_rect(rect, Color(0.0, 0.0, 0.0, 0.35), false, 2.0)

	# 当前所在房间：软光晕 + 脉冲描边，让玩家一眼看到自己在哪。
	if not current_id.is_empty():
		var cur := room(current_id)
		if not cur.is_empty():
			var cpos := _center(cur)
			var crect := Rect2(cpos - Vector2(NODE_W, NODE_H) * 0.5, Vector2(NODE_W, NODE_H))
			var a := 0.55 + 0.35 * sin(_pulse_t * 4.0)
			draw_rect(crect.grow(9.0), Color(1.0, 1.0, 0.95, 0.18 * a))
			draw_rect(crect.grow(3.0), Color(1.0, 1.0, 0.95, a), false, 3.0)

	# 角色字形（显示在节点中心）
	for r in rooms:
		var glyph := _role_glyph(str(r.get("role", "")))
		var font := ThemeDB.fallback_font
		var pos := _center(r) + Vector2(-NODE_W * 0.5 + 6.0, -10.0)
		draw_string(font, pos, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, COLOR_TEXT)
		# 缩略名（小字，超长则短写）
		var label := _short_name(str(r.get("name", "")))
		draw_string(font, pos + Vector2(0.0, 20.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, COLOR_DIM)

	_draw_legend()


func _center(p_room: Dictionary) -> Vector2:
	return ORIGIN + Vector2(float(p_room.get("x", 0)) * GAP, float(p_room.get("y", 0)) * GAP)


func _role_glyph(p_role: String) -> String:
	match p_role:
		"rest":
			return "❤"
		"case":
			return "◆"
		"encounter":
			return "☠"
		"gate":
			return "⚿"
		"key":
			return "⚷"
		"ritual":
			return "✸"
		"clue":
			return "?"
		"objective":
			return "★"
		_:
			return "·"


func _short_name(p_name: String) -> String:
	var parts := p_name.split("·")
	return parts[parts.size() - 1] if parts.size() > 1 else p_name


func _draw_legend() -> void:
	var font := ThemeDB.fallback_font
	var y := size.y - 46.0
	var entries := [
		[STATE_DONE, "已做"],
		[STATE_IN_PROGRESS, "正在做"],
		[STATE_LOCKED, "未开始"],
	]
	var x := 16.0
	for entry in entries:
		var color := state_color(int(entry[0]))
		draw_rect(Rect2(Vector2(x, y), Vector2(16.0, 16.0)), color)
		draw_rect(Rect2(Vector2(x, y), Vector2(16.0, 16.0)), Color(0, 0, 0, 0.35), false, 1.0)
		draw_string(font, Vector2(x + 22.0, y + 13.0), str(entry[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLOR_TEXT)
		x += 22.0 + 14.0 * str(entry[1]).length() + 26.0
