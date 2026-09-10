class_name FSEffectCatalog
extends RefCounted

const EFFECT_PREFIX := "EFFECT_"
const EFFECT_ROOT := "res://authoring/assets/components/effects"

const ENTRIES := [
	{
		"id": "case_gold_beacon",
		"label": "案件金色信标",
		"category": "案件与目标",
		"path": EFFECT_ROOT + "/case_gold_beacon.tscn",
		"placement": "ground",
		"color": "#ffd166",
		"tags": ["案件", "金色", "信标", "交互"],
	},
	{
		"id": "ability_light_pillar",
		"label": "能力拾取光柱",
		"category": "能力与奖励",
		"path": EFFECT_ROOT + "/ability_light_pillar.tscn",
		"placement": "ground",
		"color": "#c9f26b",
		"tags": ["能力", "拾取", "黄绿", "光柱"],
	},
	{
		"id": "breakable_hint",
		"label": "可击破提示",
		"category": "玩法提示",
		"path": EFFECT_ROOT + "/breakable_hint.tscn",
		"placement": "ground",
		"color": "#ffb35c",
		"tags": ["可击破", "橙色", "提示"],
	},
	{
		"id": "door_red_seal",
		"label": "门锁红色封印",
		"category": "门与阻隔",
		"path": EFFECT_ROOT + "/door_red_seal.tscn",
		"placement": "ground",
		"color": "#ff4d4d",
		"tags": ["门锁", "红色", "封印", "阻隔"],
	},
	{
		"id": "objective_gold_pillar",
		"label": "目标金色光柱",
		"category": "案件与目标",
		"path": EFFECT_ROOT + "/objective_gold_pillar.tscn",
		"placement": "ground",
		"color": "#ffd45c",
		"tags": ["目标", "金色", "光柱"],
	},
	{
		"id": "rest_recovery_ring",
		"label": "休息恢复光环",
		"category": "休息与恢复",
		"path": EFFECT_ROOT + "/rest_recovery_ring.tscn",
		"placement": "ground",
		"color": "#d9ffe4",
		"tags": ["休息", "复活", "恢复", "白绿"],
	},
	{
		"id": "pressure_plate_pulse",
		"label": "压力机关脉冲",
		"category": "机关与触发",
		"path": EFFECT_ROOT + "/pressure_plate_pulse.tscn",
		"placement": "ground",
		"color": "#8eeaff",
		"tags": ["压力机关", "脉冲", "触发"],
	},
	{
		"id": "dangerous_ground_warning",
		"label": "危险地面警示",
		"category": "危险与敌人",
		"path": EFFECT_ROOT + "/dangerous_ground_warning.tscn",
		"placement": "ground",
		"color": "#ff4d4d",
		"tags": ["危险", "红色", "地面", "警示"],
	},
]


static func entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw_entry in ENTRIES:
		if raw_entry is Dictionary:
			result.append(raw_entry.duplicate(true))
	return result


static func find(p_effect_id: String) -> Dictionary:
	for entry in entries():
		if str(entry.get("id", "")) == p_effect_id:
			return entry
	return {}


static func effect_params(p_entry: Dictionary) -> Dictionary:
	return {
		"effect_id": str(p_entry.get("id", "")),
		"label": str(p_entry.get("label", "")),
		"path": str(p_entry.get("path", "")),
		"placement": str(p_entry.get("placement", "ground")),
		"color": str(p_entry.get("color", "")),
	}


static func effect_node(p_host: Node) -> Node3D:
	if not p_host:
		return null
	for child in p_host.get_children():
		if str(child.name).begins_with(EFFECT_PREFIX) and child is Node3D:
			return child as Node3D
	return null


static func apply_effect(p_host: Node, p_entry: Dictionary, p_owner: Node = null) -> Dictionary:
	if not (p_host is Node3D):
		return {"ok": false, "error": "事件特效只能挂到 Node3D 语义宿主下。"}
	var path := str(p_entry.get("path", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return {"ok": false, "error": "特效资源不存在或尚未导入：%s" % path}
	var packed := ResourceLoader.load(path)
	if not (packed is PackedScene):
		return {"ok": false, "error": "特效不是 PackedScene：%s" % path}
	remove_effect(p_host)
	var effect := (packed as PackedScene).instantiate() as Node3D
	if not effect:
		return {"ok": false, "error": "特效根节点不是 Node3D：%s" % path}
	effect.name = EFFECT_PREFIX + str(p_entry.get("id", "effect"))
	p_host.add_child(effect)
	if p_owner and p_owner.is_ancestor_of(effect):
		effect.owner = p_owner
	return {
		"ok": true,
		"node": effect,
		"effect": effect_params(p_entry),
	}


static func remove_effect(p_host: Node) -> int:
	if not p_host:
		return 0
	var removed := 0
	for child in p_host.get_children():
		if not str(child.name).begins_with(EFFECT_PREFIX):
			continue
		p_host.remove_child(child)
		child.free()
		removed += 1
	return removed
