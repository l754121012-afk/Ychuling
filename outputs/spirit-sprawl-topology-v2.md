# 雨城灵潮基础几何拓扑 v2（六倍扩区）

> 真源：`G:\好简历\项目原画\Snipaste_2026-09-12_12-52-19.png`。
> 本文记录用户确认的大区轮廓、水域、岸墙、桥、世界边界，以及扩区后细分出的房间与平台；不包含敌人、灯光、特效或小道具。

## 已确认结果

- 2026-09-12 外置审查图 v4 已获用户确认：“ok，现在的准确了。”
- 保留陆区：`north_knot`、`east_mainland`、`northeast_lobe`。
- 保留桥：`br_north_east`、`br_northeast_east`。
- 删除陆区：`west_spine`、`southwest_lobe`、`southeast_spur`。
- 删除桥：`br_west_north`、`br_west_southwest`、`br_southwest_center`、`br_center_southeast`。
- 大区轮廓保持不变；在世界已经扩为 `3` 倍的基础上，再把范围翻倍到 `6` 倍线性尺寸。每个陆区继续细分可站立平台和独立的不规则离岸地形房间，房间与主陆区、其它房间之间以水域隔开，有路线的地方只通过桥连接。
- 确认图：`C:\Users\李泽文\Documents\Codex\2026-09-12\co-2\outputs\spirit-sprawl-annotation-review-v4.png`。

## 对齐流程

后续参考图布局对齐沿用本次方法：

1. 先在工程外生成简单、像素级、可独立查看的概括标注图，不在主会话反复注入原图。
2. 用户逐轮只指出误识别和偏差，确认后再把已确认掩膜换算成 Godot cell span。
3. 先生成并审查基础几何，不提前接入玩法、敌人、灯光、特效或小道具。
4. 确认后的轮廓才允许写入生成器；审查图版本与构建场景必须能相互追溯。

## 坐标与边界

- 顶视图约 `521 x 344`，上北下南；世界北向为 `-Z`。
- 映射：`u = px / 521`，`v = py / 344`，`X = -120 + u * 240`，`Z = -79.2 + v * 158.4`。
- 世界边界：`X=-120..120`，`Z=-79.2..79.2`。
- 主地面 `Y=0`；水面/河床为纯视觉层，不提供碰撞承托。
- 施工网格为 `240 x 156`，每格约 `1.0 x 1.015m`；该网格是确认稿的 6 倍线性尺寸，不是把单个物件简单放大。
- 旧六区六桥、旧六岛横排、旧 7 岛 8 桥对称布局、`Z=±8.5` 边界和 `approved_a/review_only` 标记均已作废。

## 陆区

| semantic ID | 名称 | 顶视作用 |
| --- | --- | --- |
| `north_knot` | 北中分叉陆区 | 北中部分叉节点，向南逐渐收窄并形成中央长支 |
| `east_mainland` | 东岸连续主陆区 | 右侧最大连续陆区，中北部最宽，南端分叉收束 |
| `northeast_lobe` | 东北离岸枝块 | 东北独立枝块，通过短桥接东岸主陆区 |

最终掩膜不再识别参考图左上、西南和东南的额外陆块；中央与南部保留大面积水域负空间。每行陆区由连续 cell span 生成一个盒体，避免逐格碰撞数量膨胀。

## 水域

- `canal_water` 是覆盖全世界的可视水面与河床，陆区和桥面占据的格位将其切分成不规则水道。
- 水面无碰撞，不提供主地面；玩家不能靠水面承托跨越。
- 水域阻挡依赖岸墙和地面缺口，不用纯贴图承担阻挡。

## 桥

| semantic ID | 轴向 | 连接 |
| --- | --- | --- |
| `br_north_east` | X | `north_knot` -> `east_mainland` 的陆区桥 |
| `br_northeast_east` | Z | `northeast_lobe` -> `east_mainland` 的陆区桥 |

- 每个离岸房间额外生成一座 `br_room_*` 连接桥，tags 为 `bridge/room_connection`，`links` 指向自己的房间和所属陆区；当前共 `14` 座。

## 细分结构

- 房间是独立的不规则地形板块，不再是带墙、门洞或柱子的房子；房间周围至少保留 `2` 格水，只允许和自己的连接桥接触。
- 平台保持低承托结构并带楼梯；当前 `north_knot` 为 `6` 个房间、`12` 个平台，`east_mainland` 为 `6` 个房间、`12` 个平台，`northeast_lobe` 为 `2` 个房间、`12` 个平台。
- 当前总计：`14` 个房间、`14` 座房间连接桥、`36` 个平台、`72` 级楼梯和 `436` 个静态碰撞体。

## 墙体

- `SHORE_*`：由岛和房间 cell 的水岸暴露边自动生成并合并，共 363 段；桥格参与连通判断，桥入口不会生成内部岸墙，桥面侧边保留栏杆视觉。
- `wall_world_w`：`X=-120.3`，长度 `158.4`。
- `wall_world_e`：`X=120.3`，长度 `158.4`。
- `wall_world_n`：`Z=-79.5`，长度 `240.0`。
- `wall_world_s`：`Z=79.5`，长度 `240.0`。

## 施工输出

- 生成器：`project/tools/fs_build_spirit_sprawl_geometry.gd`
- 审核场景：`project/authoring/scenes/spirit_sprawl_geometry.tscn`
- smoke：`project/tests/spirit_sprawl_geometry_smoke.gd`
- 生成器实测：`FS_SPIRIT_SPRAWL_GEOMETRY path=user://spirit_sprawl_geometry_6x_generated.tscn expansion=6 islands=3 bridges=16 room_bridges=14 rooms=14 platforms=36 stair_steps=72 shore_walls=363 room_validation_errors=0 world_walls=4 errors=0`
- 分布实测：`north_knot=rooms:6,platforms:12 east_mainland=rooms:6,platforms:12 northeast_lobe=rooms:2,platforms:12`
- smoke 实测：`SPIRIT_SPRAWL_GEOMETRY islands=3 bridges=16 room_bridges=14 axis_x=1 axis_z=1 semantic=77 rooms=14 platforms=36 shore_walls=363 world_walls=4 floor_hits=14 support_hits=36 water_blocked=4 room_gap_errors=0 errors=0`
