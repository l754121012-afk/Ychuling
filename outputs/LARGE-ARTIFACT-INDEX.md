# LARGE-ARTIFACT-INDEX（大体积产物索引）

> 用途：替代整读。先在本文件确认用途、体积和允许读法，再用 `rg`、统计或行范围取最小证据。
> 规则：超过 `64 KB` 或 `300` 行的文本禁止整读；`.tscn`、Manifest、`.jsonl` 日志和构建日志永远禁止整读。

## 图像与压缩硬门

- FIVESTAR 主开发会话禁止调用 `view_image`；原图、大 PNG/JPG、截图和审图结果都只能按路径引用，不得载入像素。视觉判断必须拆到独立审图会话，主会话不猜图。
- 2026-09-12 已实测：重复读取同一张地图会在单个会话中造成 `237 MB` 日志、`75` 次自动压缩和 `98` 次 `view_image`。
- 2026-09-13 再次实测：会话日志 `198,199,298 B`、`9,246` 条记录，`55` 条单行超过 `1M` 字符，`view_image` 相关记录 `627` 条并反复压缩；图像路径/缩略图规则必须升级为主会话零载入。
- `.jsonl` 会话日志和压缩摘要正文禁止读取；只允许统计体积、行数、记录类型、压缩次数和工具名。

## 当前审图交付

| 文件 | 尺寸 | 用途 | 主会话允许读法 |
| --- | ---: | --- | --- |
| `..\2026-09-14\co\outputs\spirit-sprawl-v9-region-adjustment-review-v1-integrated.png` | 4832x5868 | 8 张 v9 核对图整合版 | 只取路径、尺寸、哈希；禁止 `view_image` |
| `..\2026-09-13\godot\outputs\spirit-sprawl-v9-region-adjustment-review-v1-blue-scale.png` | 2200x1240 | 蓝块边长 `×2` 对照 | 只取路径、尺寸、哈希；禁止 `view_image` |
| `..\2026-09-13\godot\outputs\spirit-sprawl-v9-region-adjustment-review-v1-pink-split-overview.png` | 1470x1267 | 最大粉区按新蓝比例切分总览 | 只取路径、尺寸、哈希；禁止 `view_image` |
| `..\2026-09-13\godot\outputs\spirit-sprawl-v9-region-adjustment-review-v1-pink-split-*.png` | 见文件 | 粉区四向局部核对 | 只取路径、尺寸、哈希；禁止 `view_image` |
| `..\2026-09-13\godot\outputs\spirit-sprawl-v9-region-adjustment-review-v1-green-delete-*.png` | 见文件 | 绿色删除前后及接触点 | 只取路径、尺寸、哈希；禁止 `view_image` |

## 当前高风险文件

| 文件 | 体积 | 行数 | 用途 | 允许读法 |
| --- | ---: | ---: | --- | --- |
| `project/authoring/scenes/spirit_sprawl_candidate.tscn` | 361,060 B | 6,727 | 2026-09-12 失败的全景候选实验；不是真源，不继续搭布局 | 只查节点名、meta、指定 `semantic_id` 或单个节点块 |
| `project/authoring/manifests/spirit_sprawl_candidate.manifest.json` | 301,424 B | 13,416 | 候选场景机器清单；可能保留报错/对象统计线索 | 用 `rg` 查单个 `semantic_id`、`runtime_support`、`validation` 或统计 |
| `project/tools/fs_build_spirit_sprawl_candidate.gd` | 31,294 B | 952 | 候选场景生成器；只作失败回归和报错定位参考 | 先 `rg -n "func |const |ERROR|WARN"`，再读命中函数前后 |
| `project/authoring/semantic/spirit_sprawl_candidate.md` | 42,554 B | 249 | 候选场景人类清单，含 123 个物件 | 只按显示名、`semantic_id` 或分区 `rg` |
| `project/tests/spirit_sprawl_candidate_smoke.gd` | 5,001 B | 120 | 候选场景回归 smoke；可跑但不要把它当正式场景验收 | 可局部读；运行时只输出摘要 |
| `project/authoring/scenes/spirit_sprawl_geometry.tscn` | 706,175 B | 11,377 | 按用户确认 v4 顶视图生成的六倍扩区审核场景；3 个非对称陆区、2 座陆区桥、14 个离岸房间、14 座房间连接桥、36 个平台、363 段岸墙、436 个静态碰撞体 | 禁止整读；只查语义节点、桥轴、结构分布或指定 `semantic_id` |
| `project/tools/fs_build_spirit_sprawl_geometry.gd` | 46,965 B | 1,503 | 六倍扩区基础几何生成器；由 `240 x 156` cell span 生成陆区、桥、离岸房间和平台，校验房间水隔/私有桥连接，岸墙自动合并，输出到 `user://` | 先用 `rg` 找 `_build_*`、cell 常量、结构预算、桥/岸墙参数，再读命中行范围 |
| `project/authoring/manifests/first_night_authoring.manifest.json` | 67,913 B | 3,771 | 正式作者场景清单；当前内容可能仍是清场前发布物 | 用 `rg` 查 `semantic_id`、`runtime_support`、当前 zone |
| `project/authoring/scenes/first_night_authoring.tscn` | 3,348 B | 90 | 用户手调真源；当前从零搭建 | 可局部读，但禁止重建/覆盖 |

## 候选实验标记

- `spirit_sprawl_candidate` 是 `FAILED_REFERENCE`：用户明确表示“很多都是乱摆的没逻辑，构图布局也没还原参考图”，不作为后续场景真源。
- 保留候选文件仅用于复现和修复其中暴露的 F5/报错问题；不要在其上继续精修，也不要让它进入正式 F5 绑定。
- 基础地形、独立离岸房间、平台、陆区桥和房间连接桥已在独立审核场景 `spirit_sprawl_geometry.tscn` 中按确认轮廓重建并扩为 6 倍世界；房间周围至少留 2 格水且只接自己的桥，不再生成房间墙、门洞或柱子。正式维护只允许按应用工具替换 `FS_GROUP_地形`，候选场景仍保持失败参考，不参与正式验收。

## 最小读取配方

- 查候选对象：`rg -n -m 20 "<semantic_id>|display_name|<节点名>" <文件>`
- 查脚本入口：`rg -n -m 30 "^func |^const |push_error|build_errors|validation" project/tools/fs_build_spirit_sprawl_candidate.gd`
- 查 smoke 结果字段：`rg -n -m 30 "print|stats|ok|fail|error|warning" project/tests/spirit_sprawl_candidate_smoke.gd`
- 查大场景结构：只允许 `rg -n -m 20 "^\\[node|fivestar_semantic|semantic_id" <tscn>`，禁止 `Get-Content <tscn>`。
- 需要文件体积/行数：只运行 `Get-Item` 和 `Measure-Object -Line`，不要把文件正文一并输出。

## 使用边界

- 本文是定位索引，不是第二份交接簿。状态变化只改 `SESSION-HANDOFF.md` 的“当前交接”。
- 新增超过 `64 KB` 或 `300` 行的场景、Manifest、日志、生成器或分析产物时，必须在本表补一行。
- 任何全量读取请求先判断是否真的需要；若确有必要，先向用户说明体积和替代方案。
