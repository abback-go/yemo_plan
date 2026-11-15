class_name SparkFx
extends Node2D
## 맞은 자리에 0.1초 번쩍이는 십자 섬광 (타격감 강조)

var size := 8.0
var color := Palette.FIRE_CORE
var _t := 0.0
const LIFE := 0.1


func _ready() -> void:
	z_index = 7
	rotation = randf_range(-0.3, 0.3)


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var k := 1.0 - _t / LIFE
	var s := size * (0.6 + 0.4 * k)
	var c := Color(color, k)
	for a in [0.0, PI * 0.5]:
		var d := Vector2(cos(a), sin(a))
		var side := Vector2(-d.y, d.x) * s * 0.18
		draw_colored_polygon(PackedVector2Array([d * s, side, -d * s, -side]), c)
	draw_circle(Vector2.ZERO, s * 0.3, Color(Palette.FIRE_HOT, k))
