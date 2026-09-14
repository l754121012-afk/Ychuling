# SESSION-HANDOFF（会话交接簿）

> 冷启动只读：`AGENTS.md` + 本节（到下一个 `##` 标题为止）+ 本次任务指向的索引/行范围。脚本/场景/测试导航见 `CODE-INDEX.md`。

## 当前交接（新会话只读本节）

- **2026-09-14 上下文加固：**09-13 会话日志 `198,199,298 B`、`9,246` 条记录，`55` 条单行超过 `1M` 字符，`view_image` 相关记录 `627` 条，并反复压缩。根因是图像审阅与主开发混在同一会话；现已升级为 FIVESTAR 主会话图片零载入，`view_image` 一律禁用，图片只以路径、尺寸、哈希和离线统计进入主上下文，视觉判断另开独立审图会话。首次压缩迹象出现仍立即停止并回填。
- **2026-09-14 实体地形画笔已实现并增强：**右侧 Dock 新增“地形画笔（实体）”，提供草地平台、浮空平台、石质地面、道路地面、木桥/栈道，方形/圆形笔刷、`1 / 3 / 5 / 7` 格尺寸、`-8..24` 垂直层和 `0.10..2.00m` 每格厚度。按住左键拖动会连续铺设并在松开后自动保存；`0.4.7` 让画笔优先创建在当前选中节点的同一级，并让绘制、擦除、选格与整组操作跟随当前选中上下文；存在多个 `GridMap` 时不会固定误用第一个。网格拖到其他父级后，重新选中该网格或其所在父级仍可继续编辑；没有选中节点时才回退到旧的 `FS_GROUP_地形/FS_TERRAIN_BRUSH_地形画笔` 路径。格子按 1 米吸附、同格覆盖去重，每个格子同时有可视网格与 `BoxShape3D` 碰撞。此前的单格/多格选择、批量应用、批量删除、吸取、可见橡皮擦、整组选中和复制偏移继续保留；橡皮擦不会穿透成 `GridMap` 选择并误亮整组地形。整组选择可再次点击退出，开启单格/多格会自动退出整组，整组状态不再截断 Godot gizmo 输入，所有启用中的地形工具按钮使用橙色高亮。`Ctrl+Alt+3` 可切换多格选择，左键拖动按当前笔刷加选，按住 `Ctrl` 拖动减选。选择预览按 `GridMap.map_to_local()` 的格中心逐格显示，不再使用会整体偏移的坐标换算；临时预览节点不保存，中键仍保留舒适聚焦的环绕逻辑。整组副本保留格子、朝向、碰撞、厚度元数据和独立 `MeshLibrary`；支持局部擦除和仅清空当前画笔网格，不会删除用户原有手工地形、建筑、模型或地面贴面。`FS_GROUP_地形` 及其静态几何由生成/整理链路写入 Godot 原生 `_edit_lock_`，可见但不可误选；`FS_TERRAIN_BRUSH_地形画笔` 保持未锁定，不增加插件锁定按钮。
- **当前下一步门：**完全关闭并重新打开 Godot，确认 Dock 标题显示 `0.4.7`；然后在审核场景打开“地形画笔（实体）”，分别选中普通节点和已有画笔网格验证同级创建、拖走后续编辑、多画笔上下文切换，以及原有橡皮擦、整组移动/旋转、选格高亮、批量删除和复制偏移。确认旧静态地形在三维视图中可见但不可选，画笔网格仍能沿轮廓直接刷。
- **2026-09-13：六倍扩区与离岸地形房间已落地。**保留 v4 大区轮廓，在已确认的 3 倍基础上再把范围翻倍：世界为 `X=-120..120`、`Z=-79.2..79.2`，网格 `240 x 156`；当前正式审核地形为 3 个陆区、2 座陆区桥、14 个不规则离岸地形房间、36 个平台、14 座房间连接桥、72 级楼梯、363 段岸墙，共 436 个静态碰撞体。房间不再作为贴在主陆区上的房子，而是独立地形板块；房间周围至少留 2 格水，且只能接自己的桥。构建试玩玩家使用 `CharacterBody3D + move_and_slide`，受阻挡、重力和跳跃影响；从承托面缺口落下超过出生点下方 `8m` 时无损失回到出生点，不重置耐力、豆子或动量。
- **2026-09-13：用户手调后的审核场景已完成比例尺与场景树整理。**构建试玩中的玩家节点、移动/冲刺/攻击空间参数和跟随镜头一起缩放为 `1/3`，FOV、动作时长/冷却/伤害及正式玩法保持原比例；新建/已有作者物件按 `FS_GROUP_地形 / FS_GROUP_建筑 / FS_GROUP_物件 / FS_GROUP_角色 / FS_GROUP_特效` 五类稳定容器归档。插件当前版本为 `0.4.7`，修改后需完全关闭并重开 Godot 项目。
- **2026-09-13：地块组件已统一为单位正方体表达。**审核场景 `spirit_sprawl_geometry.tscn` 中 `FLOOR=44 / BLOCK=363 / PLATFORM_DECK=36 / DECK=2 / STAIR_STEP=72`，共 `517` 个地形可视网格和对应碰撞体改为 `BoxMesh(size=Vector3.ONE)` / `BoxShape3D(size=Vector3.ONE)` 加节点缩放；厚地板、平台等确实需要压扁的只保留必要的轴向拉伸，不再散落各自写死尺寸的长方体网格。位置、等效尺寸、材质和整体布局均未改变；生成链路也已同步改为单位方块输出。转换前备份：`C:\Users\李泽文\Documents\Codex\2026-09-13\godot\work\backups\spirit_sprawl_geometry.before-cube-normalize.tscn`；几何复验 `visuals=682/682 collision=675/675 visual_mismatch=0 collision_mismatch=0 max_delta=0.000000 errors=0`，地图 smoke 与此前一致。
- **2026-09-12：雨城灵潮基础几何 v4 已由用户确认。**真源：`G:\好简历\项目原画\Snipaste_2026-09-12_12-52-19.png`；确认后保持大区形状不变，按 `3` 倍尺度换算到 `X=-60+u*120`、`Z=-39.6+v*79.2`。
- v4 最终拓扑只保留 `north_knot / east_mainland / northeast_lobe` 共 3 个陆区和 `br_north_east / br_northeast_east` 共 2 座桥（X/Z 各 1）；左西脉、西南枝块、东南枝块及四座旧桥全部删除。用户随后补入大型墓穴门；当前分陆区结构为 `north_knot=7/6`、`east_mainland=4/3`、`northeast_lobe=2/1`（房间/平台）。
- 本次对齐方法已固定：先在工程外做简单、像素级概括标注图并交用户确认；用户确认 v4 后，才把掩膜换算成 Godot cell span。确认图：`C:\Users\李泽文\Documents\Codex\2026-09-12\co-2\outputs\spirit-sprawl-annotation-review-v4.png`。后续布局对齐继续沿用，不在主会话反复读原图硬猜。
- 审核场景：`project/authoring/scenes/spirit_sprawl_geometry.tscn`；当前拓扑稿：`outputs/spirit-sprawl-topology-v2.md`。本轮只做六倍扩区基础几何、离岸房间、桥连接、玩家物理与场景树整理，不含玩法、敌人、灯光、特效或小道具；未修改 `first_night_authoring.tscn`。
- 场景树顶层现仅保留五个分类容器；大型墓穴门按语义 tags 进入 `FS_GROUP_建筑`。归档前备份在工程外：`C:\Users\李泽文\Documents\Codex\2026-09-12\co-2\spirit_sprawl_geometry.before_groups_20260913_173734.tscn`。
- 实测生成器输出：`FS_SPIRIT_SPRAWL_GEOMETRY path=user://spirit_sprawl_geometry_6x_generated.tscn expansion=6 islands=3 bridges=16 room_bridges=14 rooms=14 platforms=36 stair_steps=72 shore_walls=363 room_validation_errors=0 world_walls=4 errors=0`；分布 `north_knot=rooms:6,platforms:12 east_mainland=rooms:6,platforms:12 northeast_lobe=rooms:2,platforms:12`。
- 当前顶层分组直系子节点：`FS_GROUP_地形=438 FS_GROUP_建筑=1 FS_GROUP_物件=0 FS_GROUP_角色=0 FS_GROUP_特效=0`。
- 实测 smoke 输出：`SPIRIT_SPRAWL_GEOMETRY_V12_A components=29 cells=1125 cell_meshes=1125 cell_collisions=1125 legacy_overlaps=0 edge_markers=179 bridge=108 jump=54 dash=15 special=2 graph_components=1 bridge_probes=108 gap_probes=47 special_steps=4 top_errors=0 errors=0`。29 个组件最终仍合并为 1 个连通图；区域间连接为 `bridge=108 / jump=54 / dash=15 / special=2`。
- 试玩 smoke：`V2_AUTHORING_PLAYTEST grounded=true floor=SURFACE_NORTH_KNOT scale=0.333333 move=2.133 dash=5.500 interact=1.133 camera_h=3.500 start_y=3.94 player_y=4.00 fall_respawn=true authored=true clean=true`。玩家节点、动作空间和镜头缩放只在该模式生效；正式玩法保持 `1.0`。
- F5 构建试玩已允许绑定正式 `*_authoring.tscn` 和基础几何审核场景。当前 `project.godot` 的 F5 目标为 `spirit_sprawl_geometry.tscn`；打开审核场景后插件会继续绑定它，打开正式作者场景后会切回 `first_night_authoring.tscn`。`spirit_sprawl_candidate.tscn` 仍明确拒绝。
- 真源仍是 `project/authoring/scenes/first_night_authoring.tscn`，由用户手调；禁止重建、覆盖或自动恢复备份。
- `spirit_sprawl_candidate` 是 `FAILED_REFERENCE`，不作为真源。文件保留仅供 F5/报错回归，不要继续精修。
- 当前工作区分支 `v2`，HEAD `c7b0d65`，仍有大量未提交改动和候选文件未跟踪。不要回滚、删除或覆盖用户工作。
- 下一会话先让用户重开 Godot 项目并按 F5 试玩当前区域；重点验收拆分后小区域密度、约 `60-30-10` 的桥/跳跃/冲刺抵达感、阻挡与坠落、玩家比例和五类容器。生成器只写 `user://`，正式审核场景若需重建必须先备份，并继续只用应用工具替换 `FS_GROUP_地形`，不得覆盖用户手调的建筑等内容。
- 插件脚本本轮有更新：用户必须完全关闭并重新打开 Godot 项目一次，实体地形画笔上下文与同级创建修复才会加载；只重开场景不算重载插件。Dock 标题显示 `0.4.7` 才表示本轮版本已生效。
- 新会话首次压缩/继续摘要出现时立即停止扩展并回填本节；禁止在压缩上下文里继续看图或猜图。

## 历史实现状态（默认不读；需要时 rg）

- 以下为 2026-09-10 至 2026-09-12 的 `0.3.8` 历史记录，保留用于定位，不属于默认冷启动上下文。
- 玩家移动：`PlayerController.gd` 新增 `_try_step_up()`，普通移动、落地且未受击时可跨过约 `0.42m` 的低台；高于阈值、坡度不适合落脚的障碍仍保留原有反弹。冲刺/高墙碰撞行为不变。
- 渲染：`project.godot` 写入 `rendering_device/driver.windows="d3d12"`。本机 Godot 原先落到 Mesa Dozen Vulkan 并报 `VK_ERROR_OUT_OF_HOST_MEMORY`；改用原生 NVIDIA D3D12 后 Forward+ 正常启动，红字消失。
- 报错分级：黄色导入/预览/socket 提示通常非致命；`Can't use get_node() with absolute paths from outside the active scene tree.` 出现在编辑器扫描部分 smoke 脚本期间，工程内无运行时绝对路径 `get_node()`，headless 解析和 F5 构建试玩均通过，暂按编辑器扫描期提示处理。
- 本轮新增 `tests/m2_step_up_smoke.gd`；`m2_bounce_smoke.gd` 改为自建地板和高墙，不再依赖用户正在手搭的路线场景。
- 作者场景：`project/authoring/scenes/first_night_authoring.tscn` 保持用户手搭真源。当前从零搭建状态只有 `FS_REGION_FIRST_NIGHT`、位于 `y=0` 的 `120 x 120` 构建平面 `FS_FLOOR_构建地面_BUILD_PLANE_0`，以及一块带 `SUPPORT_floor` 承托碰撞的泥土地面 `FS_DECOR_地牢泥土地面_VISUAL_DUNGEON_DIRT_1`；旧布局备份为 `*.pre-reset-20260910-225140.bak`，不要自动恢复或重建。
- 已实现：右侧 Dock `FIVESTAR 场景语义工具` 可登记中文显示名/分组/校验/导出/发布；Manifest 每物件带 `display_name`、`visual` 和 `runtime_support`。
- 可视原型：`project/authoring/assets/model_catalog.json` 收录 141 个精选中文模型项，插件还会自动扫描全部已导入 GLB 并与精选目录去重合并；支持搜索/分类/实时三维预览/应用/替换/移除，并可“一键区分未配模型”，只补空白宿主，不覆盖已有模型、碰撞或自定义显示名。
- 模型总览：`project/authoring/scenes/model_gallery.tscn` 现在是只读 UI 浏览器，不再把所有目录模型铺成实体场景节点。左侧为搜索、分类和文字列表，右侧为独立 `SubViewport` 三维实时预览、自动旋转、模型 ID、资源路径、复制 ID 和文件定位；Dock 的固定高度模型列表下方也有同一套实时预览。
- 模型创建易用性：Dock 模型选择已从会遮住预览的 `OptionButton` 改为固定 `170px` 高度的可滚动 `ItemList`，列表和 `190px` 预览同时可见。没有选中节点时也会保留模型搜索/分类/列表；选中模型即可使用“创建选中模型为新物件”，双击列表项同效。创建区新增“新物件中文名（可选）”，留空时仍使用模型中文名；创建后节点名包含中文显示名与稳定 ASCII `semantic_id`。现有物件改中文名后点“应用语义 / 改名”。
- 观察视图：Dock 新增“观察视图”，`Shift+F` 按当前选中 `Node3D` 的世界包围盒舒适聚焦，从约 36° 斜上方看向物件中心，多选可整体取景；`0.3.5` 在 `EditorPlugin` 中启用常驻 3D 输入转发，聚焦后中键环绕、`Shift+中键`平移和滚轮缩放不再被 Godot 原生编辑相机按世界尺度抢走，均按当前物件尺寸使用近距微调尺度；`0.3.8` 保留反转后的直觉中键水平环绕，上下俯仰保持原方向。`Ctrl+Alt+1` 从当前选中单一 `Node3D` 切入实际游戏视角，`Ctrl+Alt+2` 恢复进入前保存的编辑视角；没有选中物件时优先找 `spawn` / 出生点，再回退场景原点。参数由 `scripts/authoring/FSGameView.gd` 与运行相机共用，只移动编辑器摄像机，不写入作者场景。
- F5 构建试玩：允许加载正式 `*_authoring.tscn` 和已批准的基础几何审核场景 `spirit_sprawl_geometry.tscn`，失败候选场景继续拒绝。打开哪个有效场景就绑定哪个 F5 目标，并生成玩家和实际跟随相机；不生成 HUD、地图、案件、鬼、NPC 或 Boss。玩家从约 `y=4` 下落，优先落到场景实际承托面；只有完全没有碰撞面时才回退到 `y=0` 临时地面。构建试玩会同时把玩家节点、移动/加速/跳跃/冲刺/Q/横扫/交互/追击/越障距离，以及跟随相机高度和后移缩放到 `1/3`；FOV `52`、动作时长/冷却/伤害保持不变。Dock 的“F5 运行模式”可切到“完整游戏”，再按 `F5` 运行现有 V2 流程；模式保存在 `project.godot` 的 `fivestar_authoring/playtest_mode`，加载场景保存在 `fivestar_authoring/playtest_scene`。
- 雨城水文：`project/authoring/assets/components/water/` 提供瀑布、直河、河角、河岸、水面、水坑涟漪和排水口；`0.3.3` 新增宽/细瀑布水幕、平静/急流直河道、墙面出水口、喷泉竖直水柱、水管细流、排水槽落流、水池溢流边和可拉伸水流面片。瀑布按高度贴合，河道沿长边重复拼片，面片可平面拉伸，建筑附着水流保持浮动。
- 地形与承托：精选目录新增 24 个“地形与平台”高频搭建件，覆盖道路、木板、平台、石阶、坡道、墙、柱体、岩石、地牢地板、半高墙和碎石障碍。这些条目带 `floor/platform/wall/stairs/column/obstacle` 承托类型，应用后自动生成 `SUPPORT_*` 碰撞；地板至少 `0.08` 米厚，用户手搭碰撞不会被覆盖。
- 环境表现：9 种可叠加环境特效（暖色灯笼光、冷色聚光、月光、地面雾、低云层、火焰与动态光、成片雨幕、环境风线、尘埃微粒）使用独立 `ENVIRONMENT_*` 节点，可与 8 种事件特效同时存在，并可单独移动、调参和删除。`0.3.3` 递归写入作者场景 `owner`，并在打开场景时从元数据修复空的旧环境节点，解决 F5/重启后不可见。
- 地面绘制：右侧 Dock 新增“地面绘制（贴面）”，提供湿泥、青苔、石屑、水光、破败土痕和圆/长椭圆/方形笔触；左键点击或拖动时优先命中地形碰撞，否则回退 `y=0`，每笔自动保存为无碰撞的 `GROUND_PAINT_*`。当前用于白盒视觉补层，真正避免拉伸泥地纹理问题仍以三平面材质或 `Terrain3D` 为主。
- 本轮修复：批量识别可进入 `ZONE` / `REGION` 查找新加的柱子、墙、门、悬浮平台、建筑和水体，同时仍跳过行为宿主内部的生成视觉子节点；无法识别的剩余节点会列在校验输出。单点建筑挂模型时排除 `AuthoringMarker` 尺寸，不再被缩成不可见大小。模型替换改为先构建新模型、成功后再清理旧 `VISUAL_*` 和旧式嵌套模型，宝箱/水车等不会继续叠在同一个语义宿主上。
- 分配报错修复：旧版 `apply_model` 会递归改写 GLB 预制体内部节点的 `owner`，保存后把门、动画等内部节点重复序列化。`0.2.3` 只让 `VISUAL_*` 外壳和预制体实例根归作者场景持有；`tools/fs_repair_owner_duplicates.gd` 已修复旧场景，删除重复内部节点 55 个，复检 `remaining=0`，原文件备份为 `*.owner-fix.bak`。这段历史记录当时的插件版本为 `0.3.9`：固定高度模型列表与实时预览、无宿主直接创建/中文命名、UI 模型浏览器、模型/事件/环境三层分离、五类场景树容器、新建后只选中分类容器且不自动展开刚创建物件、批量落地修正、8 种事件特效、9 种环境特效、地面贴面绘制、10 种新增雨城水流、近距尺寸自适应聚焦、反转后的直觉中键水平环绕、安全节点路径、编辑/游戏观察视角切换和 F5 构建试玩/完整游戏切换；普通模型默认贴地，水面/涟漪/泡沫/云/建筑附着水流显式浮动。模型和特效控件不再按最长条目撑大 Dock 最小宽度，右侧面板可以拖窄。
- 接管边界：代码只认 ASCII `semantic_id`/`kind`/`behavior`/`links`/`params` 与运行分组；节点名中的中文只作查找，GLB 只作可视壳。`VISUAL_<model_id>` 子节点永远不得登记语义。
- 七节点工作流：规格确认 → 场景手调 → 语义校验 → 导出并发布 → 功能实现 → 试玩验收 → 交接回填。每节点有负责人、说明、确认提示和二次确认框。
- 当前状态：`project/authoring/workflows/first_night.json` 仍是 `current_step=0`，七个节点全 `PENDING`，明确等待用户确认第 1 节点；不要替用户静默确认。
- 清单状态：清场前留下的历史发布清单为 70 个对象，`runtime=11 native=2 marker=10 pending=2 none=45`；它不代表当前空场景。用户重搭并重新导出前，不要把它当作当前真源，也不要用它判断功能物件是否还存在。
- 本轮验证：全工程 headless 编辑器解析通过；`v2_authoring_smoke.gd` 输出 `V2_AUTHORING objects=71 errors=0 warnings=0 route_gates=2 markers=10 authored=true`。这里的 `71` 来自 smoke 内部临时搭建的完整测试脚手架，不是当前作者场景对象数；smoke 另断言五类容器映射、容器 owner、拒绝把分类容器记成语义父级、新建后选中分类容器而不全选新建物件，以及原有精选目录、承托碰撞、环境持久化、水流、地面绘制、近距视角和场景重载。`v2_authoring_playtest_smoke.gd` 输出 `V2_AUTHORING_PLAYTEST grounded=true floor=SURFACE_NORTH_KNOT scale=0.333333 move=2.133 dash=5.500 interact=1.133 camera_h=3.500 start_y=3.97 player_y=4.00 fall_respawn=true authored=true clean=true`；玩家落到 `SURFACE_NORTH_KNOT`，没有生成 HUD/地图/鬼。旧 `v2_r1_runtime_smoke` 因当前作者场景缺少旧路线 marker 而输出未通过；这是作者接管后的预期基线变化，不要为跑通该旧 smoke 自动重建场景。
- 保存语义：模型创建/应用/替换/移除、批量补模型、落地修正、事件/环境特效、地面绘制每笔和删除绘制会尝试自动保存，状态栏会明确报告保存结果；普通手改和“应用语义 / 改名”仍按 Godot 的未保存状态处理，必要时按 `Ctrl+S`。若状态栏提示自动保存失败，必须先按 `Ctrl+S` 再继续。
- 重载语义：修改插件脚本后需完全关闭并重新打开 Godot 项目；只重开场景不算重载插件，未重开时右侧 Dock 可能仍运行旧逻辑。Dock 标题显示 `0.4.7` 表示本轮修复已加载；Dock 更新不等于场景已保存。F5 模式写入项目设置后，若编辑器进程仍使用旧值，同样完全重开项目一次。
- 下一步：用户确认第 1 节点规格后，从 `build_plane_0` 开始手搭场景。一旦开始编辑，禁止再运行 `tools/fs_build_authoring_scene.gd`，否则会覆盖手调内容。
- 文档入口：`outputs/AUTHORING-WORKFLOW.md`（七节点、手调登记、中文命名、模型目录、接管分类、失败回退、AI 接手指令）。

## 项目定位

- 工程：`C:\Users\李泽文\Documents\Codex\2026-09-08\3d-f-crypt-custodian-green-chs`；分支 `v2`；`master` 冻结于 tag `v1.0-basic-stable`。本轮 `0.4.7` 的实体地形画笔同级创建、多画笔上下文跟随和拖走后续编辑修复及此前的五类容器、构建试玩缩放与 F5 作者场景绑定按工作区和 `git log -1 --oneline` 为准。
- 框架：Godot 4.7.2。本机：`F:\Godot\4.7.2\Godot_v4.7.2-stable_win64.exe`（渲染**必须带窗口**）；`..._console.exe`（headless 跑 smoke）。
- 工程根：`...\project`；主场景 `res://scenes/main/V2FirstLoop.tscn`（根脚本 `M2RouteLab.gd`）。
- 阶段：V2 行为循环白盒（不换美术资产，不做 Demo/盈利验证）。红/金/白黄绿视觉规则与输入语义见 `AGENTS.md`。

## 读取攻略（坚决避免二次整读）

- 脚本/测试：先查 `outputs/CODE-INDEX.md` 定位 文件+行，再用 `rg`/行范围局部读；**不要整读 >300 行的大脚本**。
- 作者场景/功能接管：先读 `outputs/AUTHORING-WORKFLOW.md` 与 `project/authoring/manifests/<region>.manifest.json`；用户已手调后禁止重建作者场景。
- 当前雨城灵潮地图 → 只读本文件当前交接 + `outputs/spirit-sprawl-topology-v2.md`；施工入口为 `project/tools/fs_build_spirit_sprawl_geometry.gd`，审核场景为 `project/authoring/scenes/spirit_sprawl_geometry.tscn`。
- 当前真源图片 → `G:\好简历\项目原画\Snipaste_2026-09-12_12-52-19.png`，只按当前交接里的映射使用；不要把原图或大 PNG 注入上下文。
- 旧地图施工图、风格缩略图、生图提示词、`map-v2-plan`、读图转述模板和“左下角区域”方案已作废，不再作为任务入口。

## 已作废地图方案（默认不读，不重新提出）

- 六岛东西横排、六座固定 X 向桥、`Z=±8.5` 边界、`approved_a`、`review_only`、左下角夜巡司区施工和旧语义节点均已作废。
- `map-construction-blueprint.md`、`map-style-notes.md`、`reference-map-thumb.png`、`map-v2-plan.png`、`map-v2-imagegen-prompt.md`、`vision-map-reading-template.md`、`map-vision-reading-left-bottom.md` 仅保留为历史文件，不再作为真源、任务入口或新会话回忆内容。
- `spirit_sprawl_candidate` 永久是 `FAILED_REFERENCE`，只保留用于 F5/报错回归，不继续精修、不作为替代方案。

## 设计文档索引（仅为定位锚点，别全文读；细节用 `rg`）

- `outputs/README.md` 交付物总览。
- `outputs/design/04-正式GDD-FIVESTAR.md` 总 GDD。
- `outputs/design/09-版本路线-V2行为循环.md` V2 路线。
- `outputs/design/11-V2剩余待办与地图组件清单.md` V2 待办来源。
- `outputs/spirit-sprawl-topology-v2.md` 当前雨城灵潮基础几何拓扑。
- `outputs/M1-RUN.md` 运行 / smoke 命令与预期输出（权威）。
