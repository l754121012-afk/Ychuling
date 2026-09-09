# CODE-INDEX（脚本 / 场景 / 测试 导航索引）

> 目的：让新会话按“我要改哪个功能”直接跳到 文件+行，避免整读大脚本/多次重读。
> 行数为当前 HEAD（`db489e2`）实测。标“大字”的文件（>300 行）不要整读，用 `rg`/行范围定位。

## 场景（scenes/main/）

| 场景 | 根脚本 | 用途 |
| --- | --- | --- |
| `V2FirstLoop.tscn` | `M2RouteLab.gd` | V2 首夜城区主场景（当前交付基准） |
| `M2Route.tscn` | `M2RouteLab.gd` | 同一根脚本的旧路线场景 |
| `Main.tscn` | `MainLab.gd` | 早期主实验室（V2 不参与） |

## 脚本（scripts/）

### 玩法主控
- `main/M2RouteLab.gd`（667L，大字）— V2 首夜路线总控。`_ready`(88) 建 world/player/camera/hud；`_build_region_world()`(373) 从 JSON 建区域；路线门(418)/案件(193)/休息(406)/事件(611)/地图HUD(698)/失败复活(565) 都在这里。
- `main/MainLab.gd`（118L）— 早期实验室主控，V2 不用。

### 玩家 / 敌人
- `player/PlayerController.gd`（857L，大字）— 玩家状态机。冲刺(334)/Q 撤步(342)/蓄力陀螺(400)/追击连携(483)/重扫(608)/普攻(728)/受击(740)/复活(791)/弹反(819)。**参数与视觉同步改这里。**
- `actors/TestGhost.gd`（791L，大字）— 测试鬼，4 种攻击风格（swipe/shot/pool/lunge）。
- `actors/SpiritOrb.gd`（34L）— 幽灵弹/方弹，shot 系。

### v2 数据与区域系统
- `v2/V2RouteData.gd`（26L）— `load_region`(7) 读 JSON；`zone_by_id`(17)/`ability_by_id`(24)/`quest_by_id`(31)。
- `v2/V2RegionBuilder.gd`（131L）— `build(parent, region)`(12) JSON→世界（zone floor/props/gates/decor）；`zone_id_at_x`(49)；`_build_zone`(70) 用 `min_x/max_x`，忽略 `span`。
- `v2/V2RegionRuntime.gd`（75L）— 运行态门禁：`can_reach_zone`(41)/`can_open_gate`(52)/`collect_ability`(20)/`complete_quest`(27)/`build_save_data`(73)。
- `v2/V2SaveSystem.gd`（59L）— `save_run`(7)/`load_run`(31)/`has_save`(61)/`clear_run`(65)。

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

## 权威地图数据

- 区域 JSON：`project/content/route/first_night_region.json`（zones/props/decor/gates/abilities/quests）。
- 玩法施工图：`outputs/map-construction-blueprint.md`（怎么搭/布怪在哪/哪里能走）。
- 视觉风格：`outputs/map-style-notes.md` + 缩略图 `outputs/reference-map-thumb.png`（512×241）。**大参考图永不整读。**
- 顶视施工图：`outputs/map-v2-plan.png`；生图提示词：`outputs/map-v2-imagegen-prompt.md`。
