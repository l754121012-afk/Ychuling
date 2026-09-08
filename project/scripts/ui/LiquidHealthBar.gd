class_name LiquidHealthBar
extends Control

const LIQUID_COLOR := Color("#cfeaff")
const VESSEL_COLOR := Color("#111922")
const RIM_COLOR := Color("#7d8ca0")

var ratio := 1.0
var _time := 0.0


func set_ratio(p_ratio: float) -> void:
	ratio = clampf(p_ratio, 0.0, 1.0)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var area := Rect2(Vector2.ZERO, size)
	draw_rect(area, VESSEL_COLOR)

	var liquid_height := area.size.y * ratio
	var liquid_rect := Rect2(0.0, area.size.y - liquid_height, area.size.x, liquid_height)
	if liquid_rect.size.y > 0.0:
		draw_rect(liquid_rect, LIQUID_COLOR)
		_draw_liquid_surface(liquid_rect)

	draw_rect(area, RIM_COLOR, false, 3.0)


func _draw_liquid_surface(p_liquid_rect: Rect2) -> void:
	var top := p_liquid_rect.position.y
	var wave_amplitude := 1.8
	var segments := 22
	var points := PackedVector2Array()
	var step_x := p_liquid_rect.size.x / float(segments)
	for index in range(segments + 1):
		var x := p_liquid_rect.position.x + step_x * index
		var wave_y := sin((_time * 2.4 + index * 0.9)) * wave_amplitude
		points.append(Vector2(x, top + wave_y))
		points.append(Vector2(x, top + 3.0 + wave_y))
	for index in range(segments + 1):
		points.append(Vector2(p_liquid_rect.end.x - step_x * index, p_liquid_rect.end.y))
	draw_colored_polygon(points, Color(0.8, 0.95, 1.0, 0.35))
