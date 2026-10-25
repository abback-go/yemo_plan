extends Node2D
## 피해 숫자: LIFE초 동안 위로 떠오르며 사라진다.

const LIFE := 0.55
const RISE := 18.0

var text := ""
var color := Color.WHITE
var _t := 0.0
var _start := Vector2.ZERO


func setup(at: Vector2, value: String, c: Color) -> void:
	global_position = at
	_start = at
	text = value
	color = c


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
		return
	var k := _t / LIFE
	global_position = _start + Vector2(0, -RISE * (1.0 - (1.0 - k) * (1.0 - k)))
	queue_redraw()


func _draw() -> void:
	var a := clampf(1.0 - maxf(_t / LIFE - 0.6, 0.0) / 0.4, 0.0, 1.0)
	var c := Color(color.r, color.g, color.b, a)
	draw_string(Feel.font, Vector2(-20, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 40.0, Feel.FONT_SIZE, c)
