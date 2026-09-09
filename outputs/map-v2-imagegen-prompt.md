# 首夜城区 生图提示词（可读施工/顶视版）

> 定位：给生图模型（Midjourney / DALL·E / Flux 这类）用的**纯视觉+布局描述**提示词。
> 目标风格：像游戏实际的**顶视平面图 / 可读施工图纸**，功能分区一眼分清，不走“发光装饰”路线。
> 精确坐标与布怪以 `outputs/map-construction-blueprint.md` 为准；本文件只负责画面如何表达关卡如何组成。

---

## 一、可直接粘贴的主提示词（中文）

> 游戏关卡顶视平面图（约 2:1 宽幅），像成熟的关卡手册/地编施工图：深色底、浅色可走路面、深色不可走边界。画面横向（左西右东）排布 4 个有实体形状的功能区，每个区是带围墙的地块，中间一条浅色主路沿线贯穿；区块之间用深色窄沟隔开表示不可走。
>
> 从左到右依次：
> 1. 夜巡司（左，窄，蓝灰）：安全屋/起点，一个发光小锚点+金色休息点。
> 2. 居住区（中左，最宽，棕）：夜市主题，高低错落的摊棚。主路南侧有两个案件点，每个案件点四周散 4 个红色小圆点（代表敌人：挥/弹/冲/圈）。
> 3. 旧剧场·电视台（中右，窄，酒红）：有观众席、舞台、二层包厢、后台吊杆层等分层结构。一个案件点+周围 4 个敌人红点。
> 4. Boss 封印场（右，绿）：车站主题，站台、时钟塔台阶、断桥。右侧一个红色锯齿尖刺环（外围警示），环中心是 Boss；再往右一个金色封印终点光柱。
>
> 道路：主路沿 Z≈0 一线贯穿四区，北侧（上方）另有一条支路（天台捷径）绕过居住区与剧场，支路上有一个金色锁标记。
>
> 阻挡与门：所有锁定门用一个金色挂锁标记（锁体+底座）。从左到右：路由门 R1（清案1解锁）、路由门 R2（清案2解锁）、捷径门（需夜巡印章）、Boss 门（红环左下，需支线）、封印门（红环右，需击败 Boss）。封印门右侧是可见但锁住的封印终点。区块之间有深色窄沟=不可走。
>
> 标注：地名/门名文字清晰不重叠；右下角放图例：金色小方块=案件事件、五角星=休息/安全屋、金色钥匙=能力/捷径、红色锯齿环=Boss、金色挂锁=锁定门、浅色路面=可走、深色沟/墙=不可走。
>
> 风格：干净、扁平、可读的主视图，像关卡手册插图。不要照片写实、不要霓虹赛博朋克、不要大面积发光/雾效、不要明亮白天。

---

## 二、可选英文版（部分生图模型更吃英文）

> Game level top-down plan (roughly 2:1), like a clean level-build blueprint / handbook diagram: dark ground, pale walkable floors, dark non-walkable boundary. Four distinct shaped districts across the image left-to-right, each a walled plot, linked by one pale main road; dark narrow moats separate districts.
>
> Left to right: 1) Nightwatch Station (narrow, slate-blue): safe-house start, small glowing anchor + gold rest point. 2) Residential (widest, brown): night-market, staggered stalls; two case markers south of the main road, each ringed by 4 small red enemy dots. 3) Old Theater / TV Station (narrow, wine-red): tiered audience, stage, second-floor balcony, backstage rigging loft; one case marker + 4 red enemy dots. 4) Seal Boss Arena (green): station theme, platform, clock-tower steps, broken bridge; a red jagged spike ring (perimeter warning) around the Boss, and beyond it a gold seal-endpoint light pillar.
>
> Roads: one main road at Z≈0 across all districts; a second northern branch (rooftop shortcut) passes the Residential and Theater, with a gold padlock on it.
>
> Blocking & gates: every locked gate marked by a single gold padlock. Left to right: R1 (clear case 1), R2 (clear case 2), shortcut (needs night-stamp), Boss gate (lower-left of red ring, needs side quest), seal door (right of red ring, needs Boss). Beyond the seal door is the visible-but-locked seal endpoint. Dark narrow moats between districts = non-walkable.
>
> Labels legible and non-overlapping. Bottom-right legend: gold square=case, star=rest, gold key=ability/shortcut, red spike ring=Boss, gold padlock=locked gate, pale floor=walkable, dark moat/wall=non-walkable.
>
> Clean, flat, readable handbook top-down. Not photorealistic, not neon cyberpunk, not heavy glow/fog, not bright daytime.

---

## 三、与布局图的差异

- **`outputs/map-v2-plan.png`（布局图，已出）**：工程侧按坐标渲染的**施工信息可视化**，区域边界/房间隔墙/主路支路/暗沟阻挡/4 只怪点位/门位/Boss 环/封印终点都按真实坐标摆放，可直接指导地编。
- **本提示词（生图）**：给生图模型理解的纯视觉描述，只能表达“相对大小、形状、连接、可走/不可走、门、怪、Boss 在哪”，无法精确到坐标。两者方向不同，适合对比哪种表达对关卡搭建更有用。
