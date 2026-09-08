# M1 白盒运行说明

状态：Godot 工程已推进到 M2 路线白盒；headless smoke 与完整送走流程测试均通过。

V2 可见玩法：按 Tab 打开首夜城区地图；两个 NPC 用 E 对话提供世界观；第一案后拾取“夜巡印章”可强化清扫并打开下一段门；Boss 后靠近金色目标柱按 E 完成封印终点。

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

预期输出类似：`BOUNCE start_x=-19 end_x=-17.1`，表示撞墙后确实向后弹回。

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
