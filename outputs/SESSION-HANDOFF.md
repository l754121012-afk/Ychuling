# SESSION-HANDOFF（会话交接簿）

> 冷启动只读：本文件 + `AGENTS.md` + 本次任务指向的文档。脚本/场景/测试导航见 `CODE-INDEX.md`。

## 当前任务

- **本次：接管 FIVESTAR 旧项目 → 从地图“左下角区域”（西南角 = 夜巡司区）开始实现。**
- 先决已做：完成上下文瘦身（新增 `outputs/CODE-INDEX.md`；本文件与 `AGENTS.md` 已去掉元叙述，只留状态与协议）。
- 首刀已做：新增 `v2/V2WorldMap.gd`（节点式世界地图，`LOCKED/IN_PROGRESS/DONE` 三态配色），并集成进 Tab 地图（`M2RouteLab.gd` `_setup_map_hud` 以它替换旧区域文字层），含“当前位置”软光晕高亮；冒烟 `v2_world_map_smoke.gd` 通过。下一步：夜巡司区 3D 落位（休息/值房/线索/捷径门/案1连通/可击破物）。

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
