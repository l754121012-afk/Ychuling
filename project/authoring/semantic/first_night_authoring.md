# FIVESTAR 作者场景清单

- 场景：`res://authoring/scenes/first_night_authoring.tscn`
- 区域：`first_night`
- 物件：`70`
- 生成时间：`2026-09-10T13:23:15`

## 物件

| semantic_id | kind | behavior | runtime | zone | 节点名 | tags/links |
| --- | --- | --- | --- | --- | --- | --- |
| `first_night` | `region` | `none` | `none` | `` | `FS_REGION_FIRST_NIGHT` | tag:authored |
| `boss_room` | `boss` | `boss` | `marker` | `first_night` | `FS_BOSS_BOSS_ROOM` | tag:authored, tag:boss |
| `case_sofa` | `case` | `case` | `marker` | `first_night` | `FS_CASE_CASE_SOFA` | tag:authored, tag:case |
| `case_tv` | `case` | `case` | `marker` | `first_night` | `FS_CASE_CASE_TV` | tag:authored, tag:case |
| `case_wardrobe` | `case` | `case` | `marker` | `first_night` | `FS_CASE_CASE_WARDROBE` | tag:authored, tag:case |
| `route_floor` | `floor` | `none` | `none` | `` | `FS_FLOOR_ROUTE_FLOOR` | tag:authored, tag:route |
| `seal_door` | `gate` | `gate` | `runtime` | `` | `FS_GATE_SEAL_DOOR` | tag:authored, link:seal_endpoint |
| `shortcut_gate` | `gate` | `gate` | `runtime` | `` | `FS_GATE_SHORTCUT_GATE` | tag:authored, link:shortcut_east |
| `shortcut_east` | `nav` | `trigger` | `marker` | `first_night` | `FS_NAV_SHORTCUT_EAST` | tag:authored, tag:path |
| `seal_endpoint` | `objective` | `objective` | `marker` | `first_night` | `FS_OBJECTIVE_SEAL_ENDPOINT` | tag:authored, tag:objective |
| `route_wall_east` | `prop` | `none` | `none` | `` | `FS_PROP_ROUTE_WALL_EAST` | tag:authored, tag:route, tag:boundary |
| `route_wall_north` | `prop` | `none` | `none` | `` | `FS_PROP_ROUTE_WALL_NORTH` | tag:authored, tag:route, tag:boundary |
| `route_wall_south` | `prop` | `none` | `none` | `` | `FS_PROP_ROUTE_WALL_SOUTH` | tag:authored, tag:route, tag:boundary |
| `route_wall_west` | `prop` | `none` | `none` | `` | `FS_PROP_ROUTE_WALL_WEST` | tag:authored, tag:route, tag:boundary |
| `rest_0` | `rest` | `rest` | `marker` | `first_night` | `FS_REST_REST_0` | tag:authored, tag:rest |
| `rest_1` | `rest` | `rest` | `marker` | `first_night` | `FS_REST_REST_1` | tag:authored, tag:rest |
| `rest_2` | `rest` | `rest` | `marker` | `first_night` | `FS_REST_REST_2` | tag:authored, tag:rest |
| `route_gate_0` | `route_gate` | `route_gate` | `runtime` | `` | `FS_ROUTE_GATE_ROUTE_GATE_0` | tag:authored, tag:route |
| `route_gate_1` | `route_gate` | `route_gate` | `runtime` | `` | `FS_ROUTE_GATE_ROUTE_GATE_1` | tag:authored, tag:route |
| `spawn` | `spawn` | `spawn` | `marker` | `` | `FS_SPAWN_SPAWN` | tag:authored, tag:route |
| `district_nightwatch` | `zone` | `none` | `none` | `district_nightwatch` | `FS_ZONE_DISTRICT_NIGHTWATCH` | tag:authored |
| `night_jar` | `breakable` | `breakable` | `runtime` | `district_nightwatch` | `FS_BREAKABLE_NIGHT_JAR` | tag:authored, tag:breakable |
| `district_nightwatch_decor_0` | `decor` | `none` | `none` | `district_nightwatch` | `FS_DECOR_DISTRICT_NIGHTWATCH_DECOR_0` | tag:authored, tag:waterfall |
| `district_nightwatch_decor_1` | `decor` | `none` | `none` | `district_nightwatch` | `FS_DECOR_DISTRICT_NIGHTWATCH_DECOR_1` | tag:authored, tag:plant |
| `district_nightwatch_decor_2` | `decor` | `none` | `none` | `district_nightwatch` | `FS_DECOR_DISTRICT_NIGHTWATCH_DECOR_2` | tag:authored, tag:lamp |
| `district_nightwatch_decor_3` | `decor` | `none` | `none` | `district_nightwatch` | `FS_DECOR_DISTRICT_NIGHTWATCH_DECOR_3` | tag:authored, tag:plaque |
| `district_nightwatch_decor_4` | `decor` | `none` | `none` | `district_nightwatch` | `FS_DECOR_DISTRICT_NIGHTWATCH_DECOR_4` | tag:authored, tag:spirit_fire |
| `district_nightwatch_decor_5` | `decor` | `none` | `none` | `district_nightwatch` | `FS_DECOR_DISTRICT_NIGHTWATCH_DECOR_5` | tag:authored, tag:mist |
| `district_nightwatch_prop_4` | `decor` | `none` | `none` | `district_nightwatch` | `FS_DECOR_DISTRICT_NIGHTWATCH_PROP_4` | tag:authored, tag:lamp |
| `district_nightwatch_prop_5` | `decor` | `none` | `none` | `district_nightwatch` | `FS_DECOR_DISTRICT_NIGHTWATCH_PROP_5` | tag:authored, tag:lamp |
| `district_nightwatch_prop_7` | `decor` | `none` | `none` | `district_nightwatch` | `FS_DECOR_DISTRICT_NIGHTWATCH_PROP_7` | tag:authored, tag:lamp |
| `district_nightwatch_floor` | `floor` | `none` | `none` | `district_nightwatch` | `FS_FLOOR_DISTRICT_NIGHTWATCH_FLOOR` | tag:authored |
| `district_nightwatch_prop_2` | `prop` | `none` | `none` | `district_nightwatch` | `FS_PROP_DISTRICT_NIGHTWATCH_PROP_2` | tag:authored, tag:pillar |
| `district_nightwatch_prop_3` | `prop` | `none` | `none` | `district_nightwatch` | `FS_PROP_DISTRICT_NIGHTWATCH_PROP_3` | tag:authored, tag:pillar |
| `nw_clue_desk` | `prop` | `none` | `none` | `district_nightwatch` | `FS_PROP_NW_CLUE_DESK` | tag:authored, tag:platform |
| `nw_counter` | `prop` | `none` | `none` | `district_nightwatch` | `FS_PROP_NW_COUNTER` | tag:authored, tag:platform |
| `district_residential` | `zone` | `none` | `none` | `district_residential` | `FS_ZONE_DISTRICT_RESIDENTIAL` | tag:authored |
| `night_jar_0` | `breakable` | `breakable` | `runtime` | `district_residential` | `FS_BREAKABLE_NIGHT_JAR_0` | tag:authored, tag:breakable |
| `night_jar_1` | `breakable` | `breakable` | `runtime` | `district_residential` | `FS_BREAKABLE_NIGHT_JAR_1` | tag:authored, tag:breakable |
| `night_jar_2` | `breakable` | `breakable` | `runtime` | `district_residential` | `FS_BREAKABLE_NIGHT_JAR_2` | tag:authored, tag:breakable |
| `district_residential_decor_0` | `decor` | `none` | `none` | `district_residential` | `FS_DECOR_DISTRICT_RESIDENTIAL_DECOR_0` | tag:authored, tag:plant |
| `district_residential_decor_1` | `decor` | `none` | `none` | `district_residential` | `FS_DECOR_DISTRICT_RESIDENTIAL_DECOR_1` | tag:authored, tag:plant |
| `district_residential_decor_2` | `decor` | `none` | `none` | `district_residential` | `FS_DECOR_DISTRICT_RESIDENTIAL_DECOR_2` | tag:authored, tag:pillar |
| `district_residential_decor_3` | `decor` | `none` | `none` | `district_residential` | `FS_DECOR_DISTRICT_RESIDENTIAL_DECOR_3` | tag:authored, tag:pillar |
| `district_residential_decor_4` | `decor` | `none` | `none` | `district_residential` | `FS_DECOR_DISTRICT_RESIDENTIAL_DECOR_4` | tag:authored, tag:window |
| `district_residential_decor_5` | `decor` | `none` | `none` | `district_residential` | `FS_DECOR_DISTRICT_RESIDENTIAL_DECOR_5` | tag:authored, tag:lamp |
| `district_residential_decor_6` | `decor` | `none` | `none` | `district_residential` | `FS_DECOR_DISTRICT_RESIDENTIAL_DECOR_6` | tag:authored, tag:spirit_fire |
| `district_residential_floor` | `floor` | `none` | `none` | `district_residential` | `FS_FLOOR_DISTRICT_RESIDENTIAL_FLOOR` | tag:authored |
| `district_residential_prop_1` | `prop` | `pushable` | `native` | `district_residential` | `FS_PROP_DISTRICT_RESIDENTIAL_PROP_1` | tag:authored, tag:box |
| `district_residential_prop_0` | `trigger` | `pressure_plate` | `pending` | `district_residential` | `FS_TRIGGER_DISTRICT_RESIDENTIAL_PROP_0` | tag:authored, tag:pressure |
| `district_seal` | `zone` | `none` | `none` | `district_seal` | `FS_ZONE_DISTRICT_SEAL` | tag:authored |
| `district_seal_decor_0` | `decor` | `none` | `none` | `district_seal` | `FS_DECOR_DISTRICT_SEAL_DECOR_0` | tag:authored, tag:pillar |
| `district_seal_decor_1` | `decor` | `none` | `none` | `district_seal` | `FS_DECOR_DISTRICT_SEAL_DECOR_1` | tag:authored, tag:pillar |
| `district_seal_decor_2` | `decor` | `none` | `none` | `district_seal` | `FS_DECOR_DISTRICT_SEAL_DECOR_2` | tag:authored, tag:lamp |
| `district_seal_decor_3` | `decor` | `none` | `none` | `district_seal` | `FS_DECOR_DISTRICT_SEAL_DECOR_3` | tag:authored, tag:spirit_fire |
| `district_seal_decor_4` | `decor` | `none` | `none` | `district_seal` | `FS_DECOR_DISTRICT_SEAL_DECOR_4` | tag:authored, tag:waterfall |
| `district_seal_floor` | `floor` | `none` | `none` | `district_seal` | `FS_FLOOR_DISTRICT_SEAL_FLOOR` | tag:authored |
| `district_seal_prop_1` | `prop` | `pushable` | `native` | `district_seal` | `FS_PROP_DISTRICT_SEAL_PROP_1` | tag:authored, tag:box |
| `district_seal_prop_2` | `prop` | `lift` | `runtime` | `district_seal` | `FS_PROP_DISTRICT_SEAL_PROP_2` | tag:authored, tag:lift |
| `district_seal_prop_0` | `trigger` | `pressure_plate` | `pending` | `district_seal` | `FS_TRIGGER_DISTRICT_SEAL_PROP_0` | tag:authored, tag:pressure |
| `district_theater` | `zone` | `none` | `none` | `district_theater` | `FS_ZONE_DISTRICT_THEATER` | tag:authored |
| `theater_jar` | `breakable` | `breakable` | `runtime` | `district_theater` | `FS_BREAKABLE_THEATER_JAR` | tag:authored, tag:breakable |
| `district_theater_decor_0` | `decor` | `none` | `none` | `district_theater` | `FS_DECOR_DISTRICT_THEATER_DECOR_0` | tag:authored, tag:plant |
| `district_theater_decor_1` | `decor` | `none` | `none` | `district_theater` | `FS_DECOR_DISTRICT_THEATER_DECOR_1` | tag:authored, tag:pillar |
| `district_theater_decor_2` | `decor` | `none` | `none` | `district_theater` | `FS_DECOR_DISTRICT_THEATER_DECOR_2` | tag:authored, tag:lamp |
| `district_theater_decor_3` | `decor` | `none` | `none` | `district_theater` | `FS_DECOR_DISTRICT_THEATER_DECOR_3` | tag:authored, tag:window |
| `district_theater_decor_4` | `decor` | `none` | `none` | `district_theater` | `FS_DECOR_DISTRICT_THEATER_DECOR_4` | tag:authored, tag:spirit_fire |
| `district_theater_decor_5` | `decor` | `none` | `none` | `district_theater` | `FS_DECOR_DISTRICT_THEATER_DECOR_5` | tag:authored, tag:plaque |
| `district_theater_floor` | `floor` | `none` | `none` | `district_theater` | `FS_FLOOR_DISTRICT_THEATER_FLOOR` | tag:authored |
| `district_theater_prop_0` | `prop` | `lift` | `runtime` | `district_theater` | `FS_PROP_DISTRICT_THEATER_PROP_0` | tag:authored, tag:lift |

## 校验

- 错误：`0`
- 警告：`0`
