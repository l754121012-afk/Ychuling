# SESSION-HANDOFF（会话交接簿）

> 冷启动只读：本文件 + `AGENTS.md` + 本次任务指向的文档。脚本/场景/测试导航见 `CODE-INDEX.md`。

## 当前任务

- **本次：建立“用户手调作者场景 + Codex 语义接管”的长期工作流，解决 Codex 对模型/布局还原不准和会话上下文压力。**
- 作者场景：`project/authoring/scenes/first_night_authoring.tscn` 保持用户手搭真源，当前包含 `FS_REGION_FIRST_NIGHT`、`y=0` 的 `120 x 120` 构建平面、两块地牢地面模型及其 `SUPPORT_*` 碰撞，以及成片雨幕和火焰与动态光两个环境特效；旧布局备份为 `*.pre-reset-20260910-225140.bak`，不要自动恢复或重建。
- 已实现：右侧 Dock `FIVESTAR 场景语义工具` 可登记中文显示名/分组/校验/导出/发布；Manifest 每物件带 `display_name`、`visual` 和 `runtime_support`。
- 可视原型：`project/authoring/assets/model_catalog.json` 收录 141 个精选中文模型项，插件还会自动扫描全部已导入 GLB 并与精选目录去重合并；支持搜索/分类/实时三维预览/应用/替换/移除，并可“一键区分未配模型”，只补空白宿主，不覆盖已有模型、碰撞或自定义显示名。
- 模型总览：`project/authoring/scenes/model_gallery.tscn` 现在是只读 UI 浏览器，不再把所有目录模型铺成实体场景节点。左侧为搜索、分类和文字列表，右侧为独立 `SubViewport` 三维实时预览、自动旋转、模型 ID、资源路径、复制 ID 和文件定位；Dock 的固定高度模型列表下方也有同一套实时预览。
- 模型创建易用性：Dock 模型选择已从会遮住预览的 `OptionButton` 改为固定 `170px` 高度的可滚动 `ItemList`，列表和 `190px` 预览同时可见。没有选中节点时也会保留模型搜索/分类/列表；选中模型即可使用“创建选中模型为新物件”，双击列表项同效。创建区新增“新物件中文名（可选）”，留空时仍使用模型中文名；创建后节点名包含中文显示名与稳定 ASCII `semantic_id`。现有物件改中文名后点“应用语义 / 改名”。
- 观察视图：Dock 新增“观察视图”，`Shift+F` 按当前选中 `Node3D` 的世界包围盒舒适聚焦，从约 36° 斜上方看向物件中心，多选可整体取景；聚焦后中键环绕、滚轮缩放按当前模型半径限制在近距微调范围，避免小物件旋转或缩放一步跨得过远。`Ctrl+Alt+1` 从当前选中单一 `Node3D` 切入实际游戏视角，`Ctrl+Alt+2` 恢复进入前保存的编辑视角；没有选中物件时优先找 `spawn` / 出生点，再回退场景原点。参数由 `scripts/authoring/FSGameView.gd` 与运行相机共用，只移动编辑器摄像机，不写入作者场景。
- F5 构建试玩：默认 `F5` 只加载已发布作者场景、兜底 `y=0` 碰撞地面、玩家和实际跟随相机；不生成 HUD、地图、案件、鬼、NPC 或 Boss。玩家从约 `y=4` 下落，有用户碰撞地面时落在实际地形上，否则落到兜底平面，适合检查正在手搭场景的比例、碰撞和玩家视角。Dock 的“F5 运行模式”可切到“完整游戏”，再按 `F5` 运行现有 V2 流程；设置保存在 `project.godot` 的 `fivestar_authoring/playtest_mode`。
- 雨城水文：`project/authoring/assets/components/water/` 提供瀑布、直河、河角、河岸、水面、水坑涟漪和排水口；`0.3.3` 新增宽/细瀑布水幕、平静/急流直河道、墙面出水口、喷泉竖直水柱、水管细流、排水槽落流、水池溢流边和可拉伸水流面片。瀑布按高度贴合，河道沿长边重复拼片，面片可平面拉伸，建筑附着水流保持浮动。
- 地形与承托：精选目录新增 24 个“地形与平台”高频搭建件，覆盖道路、木板、平台、石阶、坡道、墙、柱体、岩石、地牢地板、半高墙和碎石障碍。这些条目带 `floor/platform/wall/stairs/column/obstacle` 承托类型，应用后自动生成 `SUPPORT_*` 碰撞；地板至少 `0.08` 米厚，用户手搭碰撞不会被覆盖。
- 环境表现：9 种可叠加环境特效（暖色灯笼光、冷色聚光、月光、地面雾、低云层、火焰与动态光、成片雨幕、环境风线、尘埃微粒）使用独立 `ENVIRONMENT_*` 节点，可与 8 种事件特效同时存在，并可单独移动、调参和删除。`0.3.3` 递归写入作者场景 `owner`，并在打开场景时从元数据修复空的旧环境节点，解决 F5/重启后不可见。
- 地面绘制：右侧 Dock 新增“地面绘制（贴面）”，提供湿泥、青苔、石屑、水光、破败土痕和圆/长椭圆/方形笔触；左键点击或拖动时优先命中地形碰撞，否则回退 `y=0`，每笔自动保存为无碰撞的 `GROUND_PAINT_*`。当前用于白盒视觉补层，真正避免拉伸泥地纹理问题仍以三平面材质或 `Terrain3D` 为主。
- 本轮修复：批量识别可进入 `ZONE` / `REGION` 查找新加的柱子、墙、门、悬浮平台、建筑和水体，同时仍跳过行为宿主内部的生成视觉子节点；无法识别的剩余节点会列在校验输出。单点建筑挂模型时排除 `AuthoringMarker` 尺寸，不再被缩成不可见大小。模型替换改为先构建新模型、成功后再清理旧 `VISUAL_*` 和旧式嵌套模型，宝箱/水车等不会继续叠在同一个语义宿主上。
- 分配报错修复：旧版 `apply_model` 会递归改写 GLB 预制体内部节点的 `owner`，保存后把门、动画等内部节点重复序列化。`0.2.3` 只让 `VISUAL_*` 外壳和预制体实例根归作者场景持有；`tools/fs_repair_owner_duplicates.gd` 已修复旧场景，删除重复内部节点 55 个，复检 `remaining=0`，原文件备份为 `*.owner-fix.bak`。当前插件为 `0.3.3`：固定高度模型列表与实时预览、无宿主直接创建/中文命名、UI 模型浏览器、模型/事件/环境三层分离、批量落地修正、8 种事件特效、9 种环境特效、地面贴面绘制、10 种新增雨城水流、近距尺寸自适应聚焦、新建后只选父语义层、编辑/游戏观察视角切换和 F5 构建试玩/完整游戏切换；普通模型默认贴地，水面/涟漪/泡沫/云/建筑附着水流显式浮动。模型和特效控件不再按最长条目撑大 Dock 最小宽度，右侧面板可以拖窄。
- 接管边界：代码只认 ASCII `semantic_id`/`kind`/`behavior`/`links`/`params` 与运行分组；节点名中的中文只作查找，GLB 只作可视壳。`VISUAL_<model_id>` 子节点永远不得登记语义。
- 七节点工作流：规格确认 → 场景手调 → 语义校验 → 导出并发布 → 功能实现 → 试玩验收 → 交接回填。每节点有负责人、说明、确认提示和二次确认框。
- 当前状态：`project/authoring/workflows/first_night.json` 仍是 `current_step=0`，七个节点全 `PENDING`，明确等待用户确认第 1 节点；不要替用户静默确认。
- 清单状态：清场前留下的历史发布清单为 70 个对象，`runtime=11 native=2 marker=10 pending=2 none=45`；它不代表当前空场景。用户重搭并重新导出前，不要把它当作当前真源，也不要用它判断功能物件是否还存在。
- 本轮验证：全工程 headless 编辑器解析通过；`v2_authoring_smoke.gd` 输出 `V2_AUTHORING objects=71 errors=0 warnings=0 route_gates=2 markers=10 authored=true`。这里的 `71` 来自 smoke 内部临时搭建的完整测试脚手架，不是当前作者场景对象数；smoke 另断言精选目录、24 个地形/平台件、6 类承托 profile、自动承托碰撞和用户碰撞保留、9 种环境特效可重复叠加与单独删除、环境节点 owner/空节点修复、当前作者场景重载后环境仍存在、10 种新增水流注册与浮动规则、地面绘制创建/删除/持久化、近距缩放/小步环绕，以及新建后只选中父语义层。`v2_authoring_playtest_smoke.gd` 输出 `V2_AUTHORING_PLAYTEST grounded=true floor=SUPPORT_floor start_y=3.81 player_y=1.80 authored=true clean=true`，确认玩家落到用户搭建的实际承托面且没有生成 HUD/地图/鬼。旧 `v2_r1_runtime_smoke` 因当前作者场景缺少旧路线 marker 而输出未通过；这是作者接管后的预期基线变化，不要为跑通该旧 smoke 自动重建场景。
- 保存语义：模型创建/应用/替换/移除、批量补模型、落地修正、事件/环境特效、地面绘制每笔和删除绘制会尝试自动保存，状态栏会明确报告保存结果；普通手改和“应用语义 / 改名”仍按 Godot 的未保存状态处理，必要时按 `Ctrl+S`。若状态栏提示自动保存失败，必须先按 `Ctrl+S` 再继续。
- 重载语义：修改插件脚本后需完全关闭并重新打开 Godot 项目；只重开场景不算重载插件，未重开时右侧 Dock 可能仍运行旧逻辑。Dock 标题显示 `0.3.3` 表示本轮修复已加载；Dock 更新不等于场景已保存。F5 模式写入项目设置后，若编辑器进程仍使用旧值，同样完全重开项目一次。
- 下一步：用户确认第 1 节点规格后，从 `build_plane_0` 开始手搭场景。一旦开始编辑，禁止再运行 `tools/fs_build_authoring_scene.gd`，否则会覆盖手调内容。
- 文档入口：`outputs/AUTHORING-WORKFLOW.md`（七节点、手调登记、中文命名、模型目录、接管分类、失败回退、AI 接手指令）。

## 项目定位

- 工程：`C:\Users\李泽文\Documents\Codex\2026-09-08\3d-f-crypt-custodian-green-chs`；分支 `v2`；`master` 冻结于 tag `v1.0-basic-stable`。本轮 `0.3.3` 作者场景、水流、地面绘制和环境持久化改动按 `git log -1 --oneline` 为准。
- 框架：Godot 4.7.2。本机：`F:\Godot\4.7.2\Godot_v4.7.2-stable_win64.exe`（渲染**必须带窗口**）；`..._console.exe`（headless 跑 smoke）。
- 工程根：`...\project`；主场景 `res://scenes/main/V2FirstLoop.tscn`（根脚本 `M2RouteLab.gd`）。
- 阶段：V2 行为循环白盒（不换美术资产，不做 Demo/盈利验证）。红/金/白黄绿视觉规则与输入语义见 `AGENTS.md`。

## 读取攻略（坚决避免二次整读）

- 脚本/测试：先查 `outputs/CODE-INDEX.md` 定位 文件+行，再用 `rg`/行范围局部读；**不要整读 >300 行的大脚本**。
- 作者场景/功能接管：先读 `outputs/AUTHORING-WORKFLOW.md` 与 `project/authoring/manifests/<region>.manifest.json`；用户已手调后禁止重建作者场景。
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
