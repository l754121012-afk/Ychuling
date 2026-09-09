# SESSION-HANDOFF（会话交接簿）

> 冷启动只读：本文件 + `AGENTS.md` + 本次任务指向的文档。脚本/场景/测试导航见 `CODE-INDEX.md`。

## 当前任务

- **本次：接管 FIVESTAR 旧项目 → 从地图“左下角区域”（西南角 = 夜巡司区）开始实现，按区域逐一做完一块就喊用户进游戏测试验证。**
- 先决已做：完成上下文瘦身（新增 `outputs/CODE-INDEX.md`；本文件与 `AGENTS.md` 已去掉元叙述，只留状态与协议）。
- 上一刀：新增 `v2/V2WorldMap.gd`（节点式世界地图，`LOCKED/IN_PROGRESS/DONE` 三态配色），集成进 Tab 地图（`M2RouteLab.gd` `_setup_map_hud` 以它替换旧区域文字层），含“当前位置”软光晕高亮；冒烟 `v2_world_map_smoke.gd` 通过。
- 本轮已做（R1 夜巡司区收尾）：`v2/V2Breakable.gd` 补可见罐体（`JarBody`+`JarRim`，原只有碰撞球）；`first_night_region.json` 夜巡司区 +7 个值房物件（柜台/两立柱/三灯/线索档案桌），`shortcut_gate` 由数据层改为带世界坐标实体门 `(-10.3,-4)`；`M2RouteLab.gd` 新增 `_build_shortcut_gate_marker`（顶上金锁）、`_try_region_gate`（靠近按 E：满足条件开、否则给对应锁提示）、`_on_shortcut_gate_opened`（仪式光柱+翻地图状态）、线索档案 NPC（读档翻 `nw_clue` DONE），并把主 `_process` 的 E 互动改为“先 `_try_region_gate`，失败再 `_try_v2_npc`”。新增冒烟 `v2_r1_nightwatch_smoke.gd`（实体+地图态）与 `v2_r1_runtime_smoke.gd`（互动路径），均通过。
- **关键修复**：`M2RouteLab.gd` `_try_region_gate` 里误用 `Node.get("属性", 默认值)` 两参调用（Godot `Object.get` 只接受 1 参），导致加载主场景即 `Parse Error: Too many arguments for "get()"`。已改为单参 `gate.get("属性")`（属性由 `V2AbilityGate` `@export` 保证存在）。此前只跑静态冒烟没加载主场景故未暴露；已用真实场景加载 smoke（`m2_q_tech_smoke`）验证并修复。
- 验证：既有完整冒烟（`v2_world_map` / `v2_region_build` / `v2_region_runtime` / `v2_env_components` / `v2_save` / `v2_route_data` / `v2_gate_pickup` 与全部 m2_*、真实场景 `m2_q_tech`）全部 EXIT=0。`v2_map_organic` 为地图截图导出，headless 无真实渲染器必然失败，属既有特性非回归。
- 下一步：喊用户进游戏（带窗口上帝视角，见 M1-RUN「直接运行白盒」）验证夜巡司区：出生在夜巡司能看见值房柜台/线索档案桌/锁住的捷径门金锁/可击破罐；按 E 读线索档案；拿夜巡印章后回来按 E 开捷径门；按 Tab 看 R1 状态色（夜巡司区应在标记为“正在做/已做”）。

## 项目定位

- 工程：`C:\Users\李泽文\Documents\Codex\2026-09-08\3d-f-crypt-custodian-green-chs`；分支 `v2`（HEAD `db489e2`）；`master` 冻结于 tag `v1.0-basic-stable`。
- 框架：Godot 4.7.2。本机：`F:\Godot\4.7.2\Godot_v4.7.2-stable_win64.exe`（渲染**必须带窗口**）；`..._console.exe`（headless 跑 smoke）。
- 工程根：`...\project`；主场景 `res://scenes/main/V2FirstLoop.tscn`（根脚本 `M2RouteLab.gd`）。
- 阶段：V2 行为循环白盒（不换美术资产，不做 Demo/盈利验证）。红/金/白黄绿视觉规则与输入语义见 `AGENTS.md`。

## 读取攻略（坚决避免二次整读）

- 脚本/测试：先查 `outputs/CODE-INDEX.md` 定位 文件+行，再用 `rg`/行范围局部读；**不要整读 >300 行的大脚本**。
- 地图怎么搭/布怪/门锁/颜色 → 只读 `outputs/map-construction-blueprint.md`（权威施工图）。
- 视觉风格 → 只读 `outputs/map-style-notes.md` + 缩略图 `outputs/reference-map-thumb.png`（512×241）。**大参考图永不整读。**
- 顶视施工图 → `outputs/map-v2-plan.png`；生图提示词 → `outputs/map-v2-imagegen-prompt.md`。

## 左下角区域 = 夜巡司区（本次实现范围）

- 数据源：`project/content/route/first_night_region.json` → `V2RouteData.load_region` → `V2RegionBuilder.build`。
- 区段：`district_nightwatch`，`min_x=-19.5`、`max_x=-10.0`（X 负 = 西南/W），`z=0`，地色 `#2b3a4e`。玩家整体从西向东推进。
- 锚点：休息点 `rest`(-13.5, 0, 0)；案1 沙发 `case_sofa`(-8, 0, 0) 已在居住区边界西侧；`shortcut_gate` 需 `night_stamp`。
- props：可击破罐 `night_jar`(-16.5, 5.6)。
- decor：waterfall(-13,-5.4)/plant(-11.5,4.5)/lamp(-17,5.6)/plaque(-15,6.2)/spirit_fire(-12,-5.5)/mist(-14,6.5)。
- 边界墙：北 Z=-8.5、南 Z=+8.5（40×2.6×0.6）；西 X=-20.5、东 X=20.5（0.6×2.6×18）。可行走大致 X±20、Z±8。
- 开工顺序：先落实本区地板/装饰/边界，再接入 rest 复活点与案1 R1 门（R1 物理墙 x=-4，清案1 开门）。

## 设计文档索引（仅为定位锚点，别全文读；细节用 `rg`）

- `outputs/README.md` 交付物总览。
- `outputs/design/04-正式GDD-FIVESTAR.md` 总 GDD。
- `outputs/design/09-版本路线-V2行为循环.md` V2 路线。
- `outputs/design/11-V2剩余待办与地图组件清单.md` V2 待办来源。
- `outputs/design/13-雨城前两关地图细化.md` 首两关地图。
- `outputs/M1-RUN.md` 运行 / smoke 命令与预期输出（权威）。
