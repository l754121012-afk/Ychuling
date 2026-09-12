# M1 白盒运行说明

状态：Godot 工程已推进到 M2 路线白盒；headless smoke 与完整送走流程测试均通过。

本轮修复：玩家现在可以直接跨过高度不超过约 `0.42m` 的低台、地板和短台阶；高于该值的墙仍会触发原有反弹。Windows 改用原生 NVIDIA D3D12 渲染，避开本机当前异常的 Mesa Dozen Vulkan 后端。

V2 可见玩法：按 Tab 打开首夜城区地图；两个 NPC 用 E 对话提供世界观；第一案后拾取“夜巡印章”可强化清扫并打开下一段门；Boss 后靠近金色目标柱按 E 完成封印终点。

Q 键撤步冲撞会消耗 1 点体力；Shift 冲刺改为不消耗体力。靠近封印终点会显示 E 提示，若未按键也会在短暂停留后自动完成。

首夜城区已按 `first_night_region.json` 数据铺开 4 个区域色块（夜巡司 / 居住区 / 旧剧场·电视台 / Boss 封印场）与通用组件（灯、窗、牌匾、灵火堆、雾区、压力机关、可推箱、升降平台、罐罐等）；区域地板是薄视觉层，主路进度坐标未被遮挡。

## 工程位置

`C:\Users\李泽文\Documents\Codex\2026-09-08\3d-f-crypt-custodian-green-chs\project`

本机 Godot 4.7.2：`F:\Godot\4.7.2\Godot_v4.7.2-stable_win64.exe`

## 直接运行白盒

```powershell
& 'F:\Godot\4.7.2\Godot_v4.7.2-stable_win64.exe' --path 'C:\Users\李泽文\Documents\Codex\2026-09-08\3d-f-crypt-custodian-green-chs\project'
```

## 打开 Godot 编辑器

```powershell
& 'F:\Godot\4.7.2\Godot_v4.7.2-stable_win64.exe' -e --path 'C:\Users\李泽文\Documents\Codex\2026-09-08\3d-f-crypt-custodian-green-chs\project'
```

## 作者场景接管

打开编辑器后使用右侧 `FIVESTAR 场景语义工具`。正式作者场景是 `res://authoring/scenes/first_night_authoring.tscn`；用户负责布局、模型和视觉，Codex 通过 `semantic_id`、`kind`、`behavior`、`links`、`params` 和 `runtime_support` 实现功能。

当前作者场景已重置为从零搭建状态，只保留 `FS_REGION_FIRST_NIGHT` 和位于 `y=0` 的 `120 x 120` 构建平面 `FS_FLOOR_构建地面_BUILD_PLANE_0`。清场前布局在 `first_night_authoring.tscn.pre-reset-20260910-225140.bak`；不要自动恢复，也不要运行首次生成工具覆盖用户之后的手调内容。

构建阶段按 `F5` 默认进入“构建试玩”：只加载作者场景、临时 `y=0` 碰撞地面、玩家和实际跟随相机，不生成 HUD、地图、案件、鬼、NPC 或 Boss。玩家会从空中落到临时地面，便于检查比例、碰撞和实际玩家视角。需要运行完整 V2 玩法时，在右侧 Dock 的“F5 运行模式”点击“F5：完整游戏”，再按 `F5`；切换后若编辑器仍使用旧模式，完全关闭并重新打开 Godot 项目一次。

操作顺序：

1. 打开作者场景，选中行为宿主节点。
2. 填写 `semantic_id`、中文显示名、kind、behavior 等语义字段并点击“应用语义 / 改名”；复制节点后必须改唯一 `semantic_id`。
3. 手搭布局时按 `Shift+F` 可像 Blender 聚焦一样，按选中物件的包围盒舒适聚焦，并从约 36° 斜上方观察；多选会整体取景。聚焦后中键环绕、滚轮缩放会按当前模型尺寸限制在近距舒适范围，小物件也不会一步甩得过远。按 `Ctrl+Alt+1` 可从当前选中单一 `Node3D` 切入实际游戏视角，按 `Ctrl+Alt+2` 恢复进入前的编辑视角；Dock 的“观察视图”区也有同功能按钮。没有选中物件时会优先观察 `spawn` / 出生点，再回退场景原点；此操作不会修改或保存场景。
4. 在“可视模型（已导入）”中用固定高度列表搜索并选择模型，右侧预览始终保留；不必先选中场景节点。双击列表项，或填写中文名后点“创建选中模型为新物件”，可直接放入场景。要替换已有宿主时先选中宿主，再看预览并点“应用/替换模型”；应用会清理同一宿主下旧 `VISUAL_*`，不会把两个外观叠在一起。点“打开模型总览”会在只读 UI 浏览器中打开左侧列表和右侧实时预览。
5. 也可点击“一键区分未配模型”先给空白宿主补推荐原型和中文名。该操作会进入 `ZONE` / `REGION` 分组查找未登记物件，并把无法识别的名字列在校验输出。
6. 需要喷泉、瀑布、河流、河岸、水面、建筑出水或水车时点击“水体 / 喷泉”，在列表中选择模型；需要归到某个区域时先选中区域节点，再点“创建选中模型为新物件”直接放入该区域。`0.3.3` 新增宽/细瀑布、平静/急流直河、墙面出水口、喷泉竖直水柱、水管细流、排水槽落流、水池溢流边和可拉伸水流面片。
7. 选中语义宿主，在“事件特效（不替换模型）”中选择案件、能力、门锁、目标、休息、机关或危险提示并应用；事件特效与模型可同时存在。
8. 在“环境特效”中选灯光、雾、云、火焰、雨幕、风线或尘埃效果并点“创建环境特效”。它生成独立 `ENVIRONMENT_*` 节点，同类可重复创建并单独移动、调参或删除；不影响模型和事件特效。保存后重启或按 F5 仍会保留；若旧场景里只有空环境壳，插件会在打开场景时从元数据自动补建。
9. 需要频繁搭地板、道路、平台、楼梯、坡道、墙、柱或岩石时，先切到“地形与平台”。带承托类型的模型会自动生成 `SUPPORT_*` 碰撞，地板至少保留 `0.08` 米厚度；用户手搭碰撞不会被覆盖。
10. 需要给拉伸后的泥地、石板或平台补湿泥、青苔、石屑、水光、破败痕迹时，在“地面绘制（贴面）”选预设和笔触，点“开启地面画笔”，然后在三维视图地形碰撞面上左键点击或拖动。每笔松开后自动保存；选中 `GROUND_PAINT_*` 后点“删除选中绘制”可单独清理。
11. 若发现旧模型仍漂浮，点“修正场景模型落地”。普通模型会对齐宿主地面；水面、涟漪、泡沫、云和建筑附着水流会按显式浮动规则跳过。
12. 点击“校验当前场景”，处理到错误为 0；列表里若还有“剩余未登记节点”，选中后手动应用语义和模型。
13. 模型/特效/环境/绘制/落地/批量操作会尝试自动保存并显示结果；普通手改后按 `Ctrl+S`。插件脚本更新后先完全关闭并重新打开 Godot 项目，Dock 标题显示 `0.3.3` 表示已加载本轮修复；只重开场景不等于重载插件。右侧 Dock 与主画面之间的竖向分隔条可直接拖拽，模型/特效长名称不会再撑大最小宽度。
14. 点击“导出并发布”，生成 Manifest/Markdown 和运行时绑定。随后在面板“工作流”区按节点提示确认；每个节点确认前都会弹窗。

作者系统 smoke：

```powershell
& 'F:\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Users\李泽文\Documents\Codex\2026-09-08\3d-f-crypt-custodian-green-chs\project' --script 'res://tests/v2_authoring_smoke.gd'
```

预期输出：`V2_AUTHORING objects=71 errors=0 warnings=0 route_gates=2 markers=10 authored=true`。这里的 `objects=71` 来自 smoke 内部构建的临时完整测试脚手架，不是当前作者场景的对象数；它另覆盖环境持久化、新增水流和地面绘制。

F5 构建试玩 smoke：

```powershell
& 'F:\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Users\李泽文\Documents\Codex\2026-09-08\3d-f-crypt-custodian-green-chs\project' --script 'res://tests/v2_authoring_playtest_smoke.gd'
```

预期输出：`V2_AUTHORING_PLAYTEST grounded=true floor=SUPPORT_floor start_y=3.81 player_y=1.80 authored=true clean=true`。它确认玩家落到用户搭建的实际承托面；只有当前场景完全没有可用碰撞面时，才回退到 `y=0` 临时地面。作者场景已加载且没有生成完整玩法节点。

注意：`tools/fs_build_authoring_scene.gd` 只用于首次生成或明确要求重置作者场景；用户开始手调后禁止运行，否则会覆盖布局和模型。完整流程见 [AUTHORING-WORKFLOW.md](./AUTHORING-WORKFLOW.md)。

## 渲染与报错分级

`project.godot` 已写入 Windows 专用设置 `rendering_device/driver.windows="d3d12"`。当前 NVIDIA 驱动没有暴露可用的原生 Vulkan 设备，Godot 会落到 Mesa Dozen Vulkan，并产生截图里的红色 `VK_ERROR_OUT_OF_HOST_MEMORY` / pipeline 错误；切到原生 NVIDIA D3D12 后，Forward+ 可正常启动且不再出现这组红色错误。

编辑器里的黄色提示多为模型导入、资源预览或 socket 提示，不影响 F5 运行。另有一条 `Can't use get_node() with absolute paths from outside the active scene tree.` 会在 Godot 扫描部分 smoke 脚本时出现；工程内没有运行时的绝对路径 `get_node()`，headless 解析和 F5 构建试玩均能通过，因此按编辑器扫描期提示处理，不需要为它改场景。

## 自动 smoke

```powershell
& 'F:\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Users\李泽文\Documents\Codex\2026-09-08\3d-f-crypt-custodian-green-chs\project' --script 'res://tests/m1_smoke.gd'
```

预期输出：`SMOKE player=1 ghosts=4`。

另有一条完整流程 smoke：

```powershell
& 'F:\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Users\李泽文\Documents\Codex\2026-09-08\3d-f-crypt-custodian-green-chs\project' --script 'res://tests/m2_progression_smoke.gd'
```

预期输出：`PROGRESSION shift_done=true reviews=4`。

攻击触发 smoke：

```powershell
& 'F:\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Users\李泽文\Documents\Codex\2026-09-08\3d-f-crypt-custodian-green-chs\project' --script 'res://tests/m2_attack_smoke.gd'
```

预期输出包含：`ATTACK health=2`（说明鬼攻击能命中玩家）。

弹射光球 smoke：

```powershell
& 'F:\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Users\李泽文\Documents\Codex\2026-09-08\3d-f-crypt-custodian-green-chs\project' --script 'res://tests/m2_shot_smoke.gd'
```

预期输出包含：`SHOT health=2`。

碰撞反弹 smoke：

```powershell
& 'F:\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Users\李泽文\Documents\Codex\2026-09-08\3d-f-crypt-custodian-green-chs\project' --script 'res://tests/m2_bounce_smoke.gd'
```

预期输出类似：`BOUNCE bounced=true start_x=0.00 min_x=-1.30 end_x=3.01 velocity=(0.003, 0.000, 0.000)`，表示撞到高墙后确实先后退再弹开。

低矮台阶跨越 smoke：

```powershell
& 'F:\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Users\李泽文\Documents\Codex\2026-09-08\3d-f-crypt-custodian-green-chs\project' --script 'res://tests/m2_step_up_smoke.gd'
```

预期输出：`STEP_UP low_ok=true low_y=1.17 low_z=-2.17 wall_ok=true wall_y=0.90 wall_z=1.59`。低台可以走上，高墙仍会挡住玩家；阈值约 `0.42m`。

连携撞击 smoke：

```powershell
& 'F:\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Users\李泽文\Documents\Codex\2026-09-08\3d-f-crypt-custodian-green-chs\project' --script 'res://tests/m2_followup_smoke.gd'
```

预期输出：`FOLLOWUP started=true state=0`。

清扫连锁 smoke：

```powershell
& 'F:\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Users\李泽文\Documents\Codex\2026-09-08\3d-f-crypt-custodian-green-chs\project' --script 'res://tests/m2_chain_smoke.gd'
```

预期输出：`CHAIN chain_count=3 second_hits=3`。

扫劲横扫 smoke：

```powershell
& 'F:\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Users\李泽文\Documents\Codex\2026-09-08\3d-f-crypt-custodian-green-chs\project' --script 'res://tests/m2_heavy_smoke.gd'
```

预期输出：`HEAVY state=0 momentum=0 ghost_hits=3`。

失败重来 smoke：

```powershell
& 'F:\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Users\李泽文\Documents\Codex\2026-09-08\3d-f-crypt-custodian-green-chs\project' --script 'res://tests/m2_defeat_smoke.gd'
```

预期输出：`DEFEAT health=5 position=(-13.5,0.9,0) ghosts=4`。

Boss 攻击 smoke：

```powershell
& 'F:\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Users\李泽文\Documents\Codex\2026-09-08\3d-f-crypt-custodian-green-chs\project' --script 'res://tests/m2_boss_attack_smoke.gd'
```

预期输出：`BOSS_ATTACK action=0 state=0`。

延时落点 smoke：

```powershell
& 'F:\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Users\李泽文\Documents\Codex\2026-09-08\3d-f-crypt-custodian-green-chs\project' --script 'res://tests/m2_pool_attack_smoke.gd'
```

预期无脚本错误，延时落点会生成火球、金色爆光与上冲光柱。

V2 地图数据 smoke：

```powershell
& 'F:\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Users\李泽文\Documents\Codex\2026-09-08\3d-f-crypt-custodian-green-chs\project' --script 'res://tests/v2_region_build_smoke.gd'
```

预期输出：`V2_REGION floors=4 props=18 decor=24 gates=seal_door`。说明 `V2RegionBuilder` 能按 JSON 生成 4 个区域地板、18 个组件（含夜巡司值房柜台/线索档案桌/两立柱/三灯/可击破罐）、24 个装饰，并产出带世界坐标的 `seal_door` 实体门。

（`gates=seal_door` 是该脚本固定打印的 seal 门；`shortcut_gate` 属另一条捷径门，由下方 R1 冒烟覆盖。）

R1 夜巡司区实体冒烟：

```powershell
& 'F:\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Users\李泽文\Documents\Codex\2026-09-08\3d-f-crypt-custodian-green-chs\project' --script 'res://tests/v2_r1_nightwatch_smoke.gd'
```

预期输出：`V2_R1 props=18 shortcut=true req=night_stamp locked=true openable=true seal=true counter=true clue=true jar=true` 与 `V2_R1_MAP hub=IN_PROGRESS clue=IN_PROGRESS gate=IN_PROGRESS key=LOCKED hub_done_after=true`。说明捷径门是 `night_stamp` 能力门（无印章锁、有印章可开），值房柜台/线索档案桌/可击破罐可读，地图初始状态正确且 `nw_hub` 可翻 DONE。

R1 夜巡司区运行时冒烟（加载主场景 `V2FirstLoop.tscn`，驱动互动路径）：

```powershell
& 'F:\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Users\李泽文\Documents\Codex\2026-09-08\3d-f-crypt-custodian-green-chs\project' --script 'res://tests/v2_r1_runtime_smoke.gd'
```

预期输出：`V2_R1_RT clue=IN_PROGRESS->DONE gate_before=false lock_return=true gate_after_lock=false stamp_return=true gate_after_stamp=true gate_state=DONE key_state=DONE`。说明读线索档案把 `nw_clue` 翻 DONE；无印章按 E 仍锁着；拿到 `night_stamp` 按 E **能**开启捷径门并翻 `nw_gate/nw_key` 为 DONE。

其余 V2 数据/运行时 smoke：

```powershell
& 'F:\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Users\李泽文\Documents\Codex\2026-09-08\3d-f-crypt-custodian-green-chs\project' --script 'res://tests/v2_route_data_smoke.gd'
& 'F:\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Users\李泽文\Documents\Codex\2026-09-08\3d-f-crypt-custodian-green-chs\project' --script 'res://tests/v2_region_runtime_smoke.gd'
& 'F:\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Users\李泽文\Documents\Codex\2026-09-08\3d-f-crypt-custodian-green-chs\project' --script 'res://tests/v2_env_components_smoke.gd'
& 'F:\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Users\李泽文\Documents\Codex\2026-09-08\3d-f-crypt-custodian-green-chs\project' --script 'res://tests/v2_gate_pickup_smoke.gd'
& 'F:\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Users\李泽文\Documents\Codex\2026-09-08\3d-f-crypt-custodian-green-chs\project' --script 'res://tests/v2_save_smoke.gd'
```

预期输出依次为：`V2_ROUTE region=first_night endpoint=objective quest_reward=night_stamp`、`V2_RUNTIME blocked=true stamp=true boss_blocked=true objective=true restored_key=true`、`V2_ENV platform_children=8 jar_valid=false`、`V2_GATE allowed_before=false opened=true pickup=seal_key`、`V2_SAVE saved=true seed=20260909 key=true rest=(-13.5, 0.9, 0.0)`。

## 当前可试内容

- V2 主入口现在是 `scenes/main/V2FirstLoop.tscn`：清完 3 个上门现场与收工 Boss 后，封印门打开；靠近右侧金色目标柱按 E 完成 V2 封印终点任务。
- 每个现场先亮起当前派单，清掉现场鬼后该区变绿，下一条路线门打开。
- 3 单完成后会出现较大的收工事件鬼，送走它即完成一晚。
- 左上角显示派单进度、现场名、剩余鬼数与好评数；控件与 M1 相同。
- 鬼有四种攻击语言：近身挥击、弹射光球、延时红色落点圈、蓄力冲锋；攻击前都会变色/地面圈提示。
- 敌人不再用全身变色表达攻击；改由手臂动作、挥击弧光、弹射光球、红色落点/前摇标识表达。金色身体+金色圆环仍只代表可 E 送走，且不会自己恢复。
- 玩家被击中会弹飞并进入短暂无敌，最大生命 5 格；三小关阶段只有外部一个休息点，任何一小关死亡都会清掉整段进度并从第一小关重来；Boss 阶段死亡从 Boss 前休息点重来。
- 新增体力：最大 15，冲刺消耗约 1，横扫重击消耗约 3；消耗后短暂停顿再自动恢复，资源不足时冲刺/重击不会发动。
- 横扫重击改为单次干净横扫：一次 AoE 判定 + 一次推开，不再表现成多段旋转。
- RMB 现在区分短按与长按：短按为单次横扫重击；长按约 0.6 秒蓄满后保持待命，松开右键才进入 2 秒陀螺旋转。
- 横扫视觉为一次扩散冲击环，陀螺才使用持续旋转光环，两者已分开。
- 角色面板已移动到左上角：头像、名称、5 格生命与体力条都集中显示；派单/案件进度文字移到右上方。
- 左上状态面板已缩小并去掉无意义头像框；按“名字-生命液面-豆子-体力”紧凑排列。
- 生命改为单个大型容器，内部亮色液体随血量升降，液面有轻微波纹；豆子上限 3，高亮白色圆点；受伤且持豆时必须保持静止并长按 X 约 0.8 秒才回血，移动时不能回血。
- 失败时从最近休息点醒来，不会原地直接继续；三小关阶段的内部案件不会成为“白送”的检查点。
- 红色现在只用于攻击预告；敌人武器改为中性色。延时落点会附带从天砸落的火球视觉，弹射光球加大并自发光。
- 延时落点现在还会从地面升起一束浅金光柱作为实际落点特效。
- 连携可用时玩家脚下会出现白色提示环并显示“连携就绪”，点击 RMB 不会误触发横扫。
- 连携窗口只由玩家直接撞击或 LMB/RMB 直接命中的目标开启；鬼-鬼、撞墙等二次碰撞不会开启连携。窗口内 RMB 固定进入连携。
- 蓄力成功后会获得霸体：受击仍扣血但不会打断蓄力或后续陀螺释放。
- 扫劲满时玩家武器变红并提示“下一次 LMB 双倍清扫”；LMB 会消耗扫劲打出双倍清扫。
- RMB 横扫的击退速度已加倍，被扫飞的怪会飞得更远。
- 新增碰撞伤害：被玩家直接击中或撞过的鬼会在接下来 2 秒内因撞墙/撞鬼持续受碰撞伤害，且同窗口内碰撞次数越多单次伤害越高；鬼-鬼连锁不额外开启连携。
- 玩家清扫时会生成短暂弧光，判定距离已延长到扫把前方。
- 鼠标右键改成“横扫重击”：赵信 R 式单次 360 横扫，一次性 AoE 判定并把周围鬼强力推开；碰撞与连锁会积累“扫劲”，扫劲越大横扫范围与推开力越大。
- 左下角新增“夜班除灵师”角色面板与 3 格血量显示。
- 新增高速碰撞反弹：冲刺撞墙/撞鬼会轻弹，鬼受击会飞，撞到其他鬼会传导速度。
- 高速反弹已加强：反弹速度保留更高、碰撞点有浅绿色扩散圈；碰撞/特效资源改为缓存复用，减少周期性渲染卡顿。
- 反弹现在使用碰撞前的实际移动速度，普通跑动撞墙也会明显弹回，不再只是停在墙边。
- 冲刺参数：速度 16.5，持续时间 0.37（在上一版 0.28 基础上再加约 1/3 距离）；冲刺中可向方向键转向并轻微减速，结束后剩余速度会快速收束。
- 攻击响应优化：冲刺中按攻击可立刻取消冲刺出刀，攻击判定时间 0.14 -> 0.10，伤害触发提前；攻击范围与宽容度加大，贴身和侧面命中更好。
- 鬼被打空会先白光膨胀爆开，同时随机 2-3 块从中心弹出旋转消失，随后中心弹出更小的金色吸收块；块无实体碰撞。
- 主动撞击奖励：撞到活鬼后 2 秒内按 RMB，会先出现准备闪光，再瞬间闪现到目标后方并原地短 AOE 旋转。
- LMB 清扫会留下 0.7 秒推击标签；带标签的鬼撞到活鬼会让对方受一次连锁伤害并继承标签，HUD 显示清扫连锁数。
- HUD 新增“扫劲”3 格：玩家主动撞击、清扫连锁都会充能；横扫重击会消耗全部扫劲。
- 普通现场鬼数翻倍为每场 4 只；收工 Boss 阶段除大鬼外额外生成 3 只小怪。
- 当前受击次数数值：普通小怪 8、Boss 阶段小怪 4、收工 Boss 24；Boss 体型为普通鬼的 2.9 倍。
- 收工 Boss 已配置 5 种攻击：近身挥击、蓄力冲锋、弹射光球、延时落点、自中心冲击波；35% 概率会预定下一招形成连段。
- 所有攻击型鬼都带武器：挥击类为宽刃，冲锋类为长枪，弹射类为法杖/光球，落点/冲击波为重型打击物。
- Boss 额外拥有四肢：双腿会在移动时交替迈步，武器随抬臂/瞄准/挥击动作一起运动，方便读取攻击意图。

M1 已反馈并修正：边界墙加高，不能再跳跃出关；移动速度从 7.2 降到 6.4，加速度从 18 降到 14。

战斗反馈已修正：清扫判定框与扫把尖端对齐并降低判定高度；鬼被清扫后会被击退；敌人攻击已补光球/弧光/红色预警等视觉。

碰撞特色与后续扩展方案见 [06-弹珠碰撞玩法扩展.md](./design/06-弹珠碰撞玩法扩展.md)。
战斗动作与颜色规则见 [07-战斗视觉语言与颜色规则.md](./design/07-战斗视觉语言与颜色规则.md)。

当前键位全部是“暂定映射”，M1.1 会用 Crypt Custodian 设置页逐项校准后冻结，文件在 `project/docs/control-baseline-provisional.md`。
