# SESSION-HANDOFF（会话交接簿）

## 最小上下文块（新会话先只读这一节，其余按需定位，不要整读）

- 本次任务：交付首夜城区「有机手绘发光」风格地图 `outputs/map-v2-organic.png`（接近参考图，供确认布局）。
- Godot：`F:\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe`；工程根 `...\project`；渲染必须带窗口。
- 地图数据：`project/content/route/first_night_region.json`。
- 4 大区：夜巡司 / 居住区 / 旧剧场·电视台 / Boss 封印场。
- 关键锚点：rest、case_sofa、case_tv、case_wardrobe、boss_room、seal_endpoint。
- 门：shortcut_east 需 night_stamp；seal_door 需 seal_boss（world door @ x=15.4）。
- 视觉规则：红=敌攻击预告；金=可送走；白/黄绿=玩家动作反馈；武器中性色。
- 输入：RMB 满蓄松手→陀螺；X 静止长按0.8s→回血；Tab 地图；E 交互；Q 撤步耗1体力；Shift 冲刺不耗体力。
- 死亡回最近休息点；三小关回第一小关。

> 强制：禁止把 `G:/好简历/项目原画/清道夫地图.png` 等大参考图加载进模型上下文；只读 `outputs/map-style-notes.md` 与缩略图 `outputs/reference-map-thumb.png`。

> 用途：让每个新会话“冷启动”，不继承上个会话的聊天记录。
> 我们约定：一个里程碑/一个清晰任务开一个新会话；每次收尾先回填本文件，再交试玩。
> 这样会话上下文永远保持小，不会因为“上下文长度限制”而失败或行为漂移。

## 为什么需要它

Codex 单次会话的上下文是有限的。如果在一个长会话里反复重读大文档、大日志、长代码，窗口会被撑满并触发自动压缩；压缩会丢掉早期细节，表现为“会话因上下文失败 / 前后不一致 / 反复问同一件事”。

治本不是调大上下文（没有这个开关），而是**别让一个会话承载太多**：把“可复用的项目事实”落到文件里，新会话只读文件，从根上避免撑满。

## 防循环执行规则（每次收尾 & 开工都检查）

1. 一个会话只做 **一件** 明确的事；收尾回填本文件，再交用户。
2. 新会话开工只读“最小上下文块”+`AGENTS.md`，不再整读已定稿大文档；要细节用 `rg` 行定位。
3. **禁止把大参考图/大 PNG 整张读入上下文**。地图类任务只读 `outputs/map-style-notes.md`（风格要点）与 `outputs/reference-map-thumb.png`（缩略图）。
4. 若中断：从本文件最新状态恢复，**不从头重读**上一轮脚本/参考图。
5. 交付前必须跑一次可复现的命令并列出预期输出，避免“口头说完成其实没做”。

## 每次收尾必做的 3 步

1. **回填状态**：更新下文 `## 当前状态` 和 `## 下一步`。写下改了哪些参数（含前后值）、跑了什么 smoke、预期输出。
2. **写运行文档**：若能用 Godot 跑起来，同步更新 [M1-RUN.md](./M1-RUN.md) 的运行命令与预期输出。
3. **归档/打点**：阶段性成果 commit（V1 已打 `v1.0-basic-stable`），新里程碑开始就开新会话。

## 新会话启动口令（直接粘贴）

```
继续《五星除灵》FIVESTAR。工作区在 C:\Users\李泽文\Documents\Codex\2026-09-08\3d-f-crypt-custodian-green-chs。
先读 outputs/SESSION-HANDOFF.md，再读它指向的设计文档；恢复上下文后按“下一步”执行。
只做本次目标；不要重读已定稿的大文档全文，需要细节时用关键词定位。
收尾前回填 outputs/SESSION-HANDOFF.md，并列出 smoke 预期输出。
```

## 当前状态

- 阶段：M2 行为循环白盒（V2）。
- Godot：4.7.2（本机 `F:\Godot\4.7.2\Godot_v4.7.2-stable_win64.exe`）。
- 主场景：`project` 下的 V2 首夜城区路线；Godot 工程根 = `...\3d-f-crypt-custodian-green-chs\project`。
- 已落地：互动光圈收束 + 冲天光柱演出（夜巡印章 / Boss 清除 / 封印终点 / 案件交付 / 能力门开门 / Boss 揭示）；通用地图组件（平台、柱子、可击破罐罐、装饰植物、瀑布、灯、窗、牌匾、灵火堆、雾区、压力机关、可推箱、升降平台）。
- 地图数据化闭环已接通：`first_night_region.json` -> `V2RouteData.load_region` -> `V2RegionBuilder.build` -> `V2EnvFactory` 生成区域地板/组件；`M2RouteLab._build_region_world()` 已接入，旧的 `_build_v2_env_decor` 硬编码装饰已删除。
- 首次区域分区已落地 4 个大区：夜巡司 / 居住区 / 旧剧场·电视台 / Boss 封印场（按 JSON 的 zones+props+decor 铺色块与组件，主路/案件/Boss/封印坐标未被遮挡）。
- 地图确认示意已出 `outputs/map-v2-schematic.png`（2000x1100）+ 俯视/带字裁剪标注 `outputs/map-v2-topdown*.png`，由 `project/tests/v2_map_*.gd` 输出。用户反馈：「这只是大纲，和我要的效果相去甚远」，要求先做成接近参考图（`G:/好简历/项目原画/清道夫地图.png`）的「有机手绘发光」风，再进行后续。
- 2026-09-09 流程治理（本次会话）：已把参考风格固化为文本 `outputs/map-style-notes.md`，并生成本机只读缩略图 `outputs/reference-map-thumb.png`（512x241）。今后地图类任务只读这两个文件，**禁止整图载入模型上下文**，以根治“重复压缩上下文 / 反复重做”问题。`AGENTS.md` 已强制化（一会话一任务、先锁意图再花大成本、大图禁整读、Godot 渲染带窗口、撞同一堵墙就停止重试）。
- 关键输入：Tab 地图开合；NPC 用 E 对话；Q 撤步冲撞耗 1 体力；Shift 冲刺不耗体力；靠近关键目标按 E（也可短暂停留自动完成）。
- 关键不可违反的规则：红=敌攻击预告、金=可送走、白/黄绿=玩家动作反馈、武器中性色；死亡回最近休息点，三小关回第一小关；RMB 满蓄松手才转陀螺；X 静止长按 0.8s 才回血。

## 下一步

- **首项（待用户确认方向后才动）：产出 `outputs/map-v2-organic.png`（约 2000×1100）**，做出接近参考图的「有机手绘发光」风——近黑暗酒红角落、青绿发光有机岛屿、深窄暗运河、黑阴影团、金色挂锁、Boss 红锯齿环、金色标签、斜细雨丝；中文正常、不重叠。渲染带窗口（headless 下 `root.get_texture()` 为 null）。
- 该项直接读 `outputs/map-style-notes.md` + `outputs/reference-map-thumb.png`，**不要读原图**。出图后交用户确认，用户点头再进入下一项。
- 探索与能力循环（E）：地图上保留“可见不可达”目标；每个新能力至少改变一次旧区域路径/可击破物；死亡后能力按正式存档规则保留。
- Boss 与战斗区域（F）：Boss 从 NPC 揭示后进入独立舞台，补战斗边界、阶段转场、受击演出（当前 Boss 仍在主走廊）。
- 随机派单与第二区域（G）：案件顺序随机化；第二区域入口只做解锁状态；存档把已完成能力/支线/Boss 写进 `user://`。
- 统一可互动门：E 门 / 能力门 / Boss 门统一成一套节点与开法（`V2AbilityGate` 已存在，需接 E 门与压力机关联动）。

## 设计文档索引（先读这些，别通读全文）

- `outputs/README.md` 交付物总览。
- `outputs/design/04-正式GDD-FIVESTAR.md` 总 GDD。
- `outputs/design/09-版本路线-V2行为循环.md` V2 路线。
- `outputs/design/11-V2剩余待办与地图组件清单.md` V2 剩余待办（本文件“下一步”的源头）。
- `outputs/design/13-雨城前两关地图细化.md` 首两关地图。
- `outputs/M1-RUN.md` 运行 / smoke 命令与预期输出。

> 维护规则：本文件只写“维持连续开发所需的高信号事实”，控制在 60–80 行。与代码/参数相关的改动务必同步到本文件，不要让上下文漂移。
