# CODE-INDEX（脚本 / 场景 / 测试 导航索引）

> 目的：让新会话按“我要改哪个功能”直接跳到 文件+行，避免整读大脚本/多次重读。
> 行数为最近一轮整理时实测；改动后用 `rg`/行范围定位，标“大字”的文件（>300 行）不要整读。

## 场景（scenes/main/）

| 场景 | 根脚本 | 用途 |
| --- | --- | --- |
| `V2FirstLoop.tscn` | `M2RouteLab.gd` | V2 首夜城区主场景（当前交付基准） |
| `M2Route.tscn` | `M2RouteLab.gd` | 同一根脚本的旧路线场景 |
| `Main.tscn` | `MainLab.gd` | 早期主实验室（V2 不参与） |

## 脚本（scripts/）

### 玩法主控
- `main/M2RouteLab.gd`（762L，大字）— V2 首夜路线总控。`_ready`(88) 建 world/player/camera/hud；`_build_region_world()`(373) 从 JSON 建区域；路线门(418)/案件(193)/休息(406)/事件(611)/地图HUD(698：实例化 `V2WorldMap`)/地图刷新(746)/失败复活(565) 都在这里。
- `main/MainLab.gd`（118L）— 早期实验室主控，V2 不用。

### 玩家 / 敌人
- `player/PlayerController.gd`（857L，大字）— 玩家状态机。冲刺(334)/Q 撤步(342)/蓄力陀螺(400)/追击连携(483)/重扫(608)/普攻(728)/受击(740)/复活(791)/弹反(819)。**参数与视觉同步改这里。**
- `actors/TestGhost.gd`（791L，大字）— 测试鬼，4 种攻击风格（swipe/shot/pool/lunge）。
- `actors/SpiritOrb.gd`（34L）— 幽灵弹/方弹，shot 系。

### v2 数据与区域系统
- `v2/V2RouteData.gd`（26L）— `load_region`(7) 读 JSON；`zone_by_id`(17)/`ability_by_id`(24)/`quest_by_id`(31)。
- `v2/V2RegionBuilder.gd`（131L）— `build(parent, region)`(12) JSON→世界（zone floor/props/gates/decor），仅在没有有效作者场景绑定时作为回退；`zone_id_at_x`(49)；`_build_zone`(70) 用 `min_x/max_x`，忽略 `span`。
- `v2/V2RegionRuntime.gd`（75L）— 运行态门禁：`can_reach_zone`(41)/`can_open_gate`(52)/`collect_ability`(20)/`complete_quest`(27)/`build_save_data`(73)。
- `v2/V2SaveSystem.gd`（59L）— `save_run`(7)/`load_run`(31)/`has_save`(61)/`clear_run`(65)。

### 作者场景 / 接管工作流
- `scripts/authoring/FSAuthoringSchema.gd` — 语义字段/命名/分组/`runtime_support_for`。用户登记物件后由它统一规范化。
- `scripts/authoring/FSModelPreview.gd` — 独立 `SubViewport` 三维模型预览，自动居中、缩放、落地、灯光和旋转；Dock 与模型总览共用。
- `scripts/authoring/FSVisualCatalog.gd` — 读取/搜索 141 项精选目录并自动扫描全部已导入 GLB，合并去重后进行中文推荐映射、替换式模型应用/移除、批量补模型和落地修正；模型永远挂在语义宿主下。包含 `floor/platform/wall/stairs/column/obstacle` 承托类型和 `SUPPORT_*` 自动碰撞，保留用户手搭碰撞；`0.3.3` 增加 10 个雨城水流快捷项和建筑附着水流的浮动放置规则。
- `scripts/authoring/FSEffectCatalog.gd` — 8 种事件/状态特效目录；事件特效独立挂在语义宿主下，不替换 `VISUAL_*`。
- `scripts/authoring/FSEnvironmentCatalog.gd` — 9 种灯光/大气/天气/粒子环境特效目录；使用独立 `ENVIRONMENT_*` 节点，可重复叠加、单独调参和删除，与模型和事件特效互不替换。`0.3.3` 递归写入作者场景 `owner`，并能从元数据补建旧场景中的空环境节点，保证 F5/重启后仍存在。
- `scripts/authoring/FSGroundPaintCatalog.gd` — 地面贴面绘制目录/工厂：湿泥、青苔、石屑、水光、破败土痕，圆/长椭圆/方形笔触；在命中地形碰撞面后生成无碰撞 `GROUND_PAINT_*` `MeshInstance3D`，统一归入 `GROUND_PAINT_地面绘制`，不属于玩法语义。
- `scripts/authoring/FSWorkflow.gd` — 七节点定义、状态保存、当前节点和显式确认；状态在 `project/authoring/workflows/<region>.json`。
- `scripts/authoring/FSRegionScaffold.gd` — 从 region JSON 生成可手调的普通 Godot 场景（用户开始手调后不要再覆盖重建）。
- `scripts/authoring/FSSceneManifest.gd` — 扫描作者场景生成 Manifest/Markdown；只导出语义数据，不让 AI 整读 `.tscn`。
- `scripts/authoring/FSAuthoringRuntime.gd` — 加载已发布作者场景，按语义挂门、拾取、可击破、升降和 marker；没有有效绑定时回退旧 builder。
- `scripts/authoring/FSGameView.gd` — 编辑器与运行态共用游戏摄像机规格：高度 `10.5`、后移 `5.0`、FOV `52`、视线中心抬高 `1.0`；另提供选中物件世界包围盒与 `Shift+F` 舒适聚焦姿态计算。
- `scripts/authoring/FSPlaytestMode.gd` — 持久化 `fivestar_authoring/playtest_mode`；默认开启构建试玩，Dock 可切回完整游戏。
- `addons/fivestar_authoring/fs_authoring_dock.gd` — 右侧 `FIVESTAR 场景语义工具`：中文显示名，固定高度模型列表、实时三维预览、无宿主直接创建/中文命名、替换式应用、批量补模型、全部模型总览、落地修正、事件/环境特效、地面贴面绘制、校验、导出发布、七节点确认框。当前版本 `0.3.3`，包含“观察视图”和“F5 运行模式”：`Shift+F` 按选中物件包围盒舒适聚焦，聚焦后按模型半径限制中键环绕和滚轮缩放；新建模型只选中父语义层。`Ctrl+Alt+1` 从当前选中物件切到实际游戏视角，`Ctrl+Alt+2` 恢复原编辑视角；F5 可切换构建试玩/完整游戏。观察操作只移动编辑器摄像机，不改场景。
- `tools/fs_build_authoring_scene.gd` — 首次从 JSON 生成/覆盖正式作者场景；用户开始手调后禁用。
- `tools/fs_repair_owner_duplicates.gd` — 修复旧版模型递归 `owner` 导致的作者场景内部节点重复；先备份，再清重复节点，不重建布局。
- `project/authoring/assets/model_catalog.json` — 141 个精选中文模型目录项，其中“地形与平台”24 项，并新增 10 个雨城水流组件；插件自动扫描 Kenney 已导入 GLB 后合并去重。`params.visual` 保存可视选择，`params.effect` 保存事件特效，环境节点和 `GROUND_PAINT_*` 独立保存；都不参与行为判断。
- `authoring/scenes/model_gallery.tscn` / `authoring/scenes/fs_model_gallery.gd` — 只读 UI 模型浏览器：左侧搜索/分类/列表，右侧实时三维预览、自动旋转、复制 ID 和文件定位；只为当前选中项建立预览，不实例化整个目录，不修改作者场景。
- `authoring/assets/components/effects/` + `scripts/authoring/FSEffectCatalog.gd` — 案件金色信标、能力光柱、可击破提示、门锁红封印、目标金柱、休息光环、压力机关脉冲、危险地面警示 8 种事件特效。
- `project/authoring/scenes/first_night_authoring.tscn` — 当前用户手搭真源：区域根节点、`y=0` 的 `120 x 120` 构建平面、两块地牢地面模型与 `SUPPORT_*`、成片雨幕和火焰与动态光环境节点。禁止用生成工具覆盖；清场前布局备份为 `*.pre-reset-20260910-225140.bak`。
- `project/authoring/manifests/first_night_authoring.manifest.json` — Codex 功能实现的机器清单，含每物件 `runtime_support`。
- `project/authoring/semantic/first_night_authoring.md` — 人类摘要，含接管分类。
- `outputs/AUTHORING-WORKFLOW.md` — 七节点接管工作流、用户手调步骤、失败回退和 AI 接手指令。

### v2 世界地图（Tab 覆盖层）
- `v2/V2WorldMap.gd`（230L）— 节点式世界地图（`extends Control`）。构建状态配色：`LOCKED`(灰)/`IN_PROGRESS`(琥珀)/`DONE`(绿)。`seed_night_watch()`(66) 内置夜巡司区首图快照（12 房间+12 连接）；`load_from`(114) 重建节点图；`_draw`(120) 先画边再画节点；`room_for_world_x`(46) 依世界 X 找最近房间；`set_current`(39) 高亮_当前房间（软光晕+脉冲描边）；`set_state`(30) 改进度并刷新。集成点：`M2RouteLab.gd` 的 `_setup_map_hud`(698)——以此替换旧 `_zone_marker_labels` 区域文字层。

### v2 环境组件 / 门 / 拾取 / 可击破 / 仪式
- `v2/V2EnvFactory.gd`（156L）— 环境组件 static 工厂：platform(5)/pillar(19)/plant(26)/waterfall(41)/zone_floor(49)/lamp(56)/window(71)/plaque(79)/spirit_fire(86)/mist(101)/pressure_plate(110)/pushable_box(129)/lift(148)/interactive_door(170)。
- `v2/V2AbilityGate.gd`（59L）— 能力门 StaticBody3D：`can_open`(23)/`try_open`(41)/`is_open`(55)。
- `v2/V2AbilityPickup.gd`（27L）— 能力拾取 Area3D：`collect`(15)。
- `v2/V2Breakable.gd`（28L）— 可击破物：`on_cleaned`(17)。
- `v2/V2RitualEffect.gd`（30L）— 仪式/光柱演出：`play`(7)。

### 占位 / UI / 引导
- `placeholder/PlaceholderKit.gd`（103L）— 占位配色；`box("art_key_v2_*", color, size)`。
- `ui/LiquidHealthBar.gd`（36L）— 液态血条。
- `systems/GameBootstrap.gd`（59L）— 启动引导。

## 测试（tests/）

> smoke 统一命令：`& 'F:\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path '<工程>\project' --script 'res://tests/<脚本>.gd'`
> 渲染类（出图/截图）必须**带窗口**（`Godot_v4.7.2-stable_win64.exe`），headless 下 `root.get_texture()` 为 null。

| 测试脚本 | 行 | 预期输出签名 |
| --- | --- | --- |
| `m1_smoke.gd` | 17 | `SMOKE player=1 ghosts=4` |
| `m2_progression_smoke.gd` | 41 | `PROGRESSION shift_done=true reviews=4` |
| `m2_attack_smoke.gd` | 17 | `ATTACK health=2` |
| `m2_shot_smoke.gd` | 36 | `SHOT health=2 ...` |
| `m2_bounce_smoke.gd` | 17 | `BOUNCE start_x=-19 end_x=-17.1 ...` |
| `m2_followup_smoke.gd` | 22 | `FOLLOWUP started=true state=0 ...` |
| `m2_chain_smoke.gd` | 28 | `CHAIN chain_count=... second_hits=...` |
| `m2_heavy_smoke.gd` | 24 | `HEAVY ...` |
| `m2_defeat_smoke.gd` | 20 | `DEFEAT ...` |
| `m2_boss_attack_smoke.gd` | 19 | `BOSS ...` |
| `m2_pool_attack_smoke.gd` | 17 | `POOL ...` |
| `m2_q_tech_smoke.gd` | 16 | `QTECH ...` |
| `m2_spin_smoke.gd` | 24 | `SPIN ...` |
| `v2_route_data_smoke.gd` | 14 | `V2_ROUTE region=... endpoint=... quest_reward=...` |
| `v2_region_build_smoke.gd` | 33 | `V2_REGION floors=... props=... decor=... gates=...` |
| `v2_region_runtime_smoke.gd` | 28 | `V2_RUNTIME blocked=... stamp=... boss_blocked=... objective=... restored_key=...` |
| `v2_env_components_smoke.gd` | 21 | `V2_ENV platform_children=... jar_valid=...` |
| `v2_gate_pickup_smoke.gd` | 23 | `V2_GATE allowed_before=... opened=... pickup=...` |
| `v2_save_smoke.gd` | 26 | `V2_SAVE saved=... seed=... key=... rest=...` |
| `v2_map_plan.gd` | 347 | 顶视施工图渲染（带窗口）→ `outputs/map-v2-plan.png` |
| `v2_map_schematic.gd` / `v2_map_capture.gd` / `v2_map_organic.gd` | 175/107/245 | 其余地图渲染辅助，旧参考非基准 |
| `v2_world_map_smoke.gd` | 64 | `V2_WORLDMAP rooms=12 edges=12 rest=DONE hub=IN_PROGRESS seal_init=LOCKED map@-13.5=rest map@-8=case_sofa map@11=boss seal_after=DONE current=case_sofa` |
| `v2_authoring_smoke.gd` | — | `V2_AUTHORING objects=71 errors=0 warnings=0 route_gates=2 markers=10 authored=true`（`objects=71` 是 smoke 内部临时脚手架，不是当前作者场景；另验证精选目录、24 项地形/平台、自动承托碰撞与用户碰撞保留、环境特效 owner/空节点修复与场景重载、10 个新增水流及浮动规则、地面绘制创建/删除、近距尺寸自适应聚焦、新建后只选父层、UI 模型总览、三维预览、替换清理、落地和事件特效共存） |
| `v2_authoring_playtest_smoke.gd` | — | `V2_AUTHORING_PLAYTEST grounded=true floor=SUPPORT_floor start_y=3.81 player_y=1.80 authored=true clean=true`（验证 F5 构建试玩落到用户搭建的实际承托面，而不是强制落到 `y=0`） |

## 权威地图数据

- 区域 JSON：`project/content/route/first_night_region.json`（zones/props/decor/gates/abilities/quests）。
- 玩法施工图：`outputs/map-construction-blueprint.md`（怎么搭/布怪在哪/哪里能走）。
- 视觉风格：`outputs/map-style-notes.md` + 缩略图 `outputs/reference-map-thumb.png`（512×241）。**大参考图永不整读。**
- 顶视施工图：`outputs/map-v2-plan.png`；生图提示词：`outputs/map-v2-imagegen-prompt.md`。
