extends Node2D
## 별빛 결계 그림 (아스트리드)
## 하늘 문(sky_gate.gd)의 보호막 그림.

var k := 1.0
var _t := 0.0


func _ready() -> void:
	z_index = 8
	material = Fx.add_material


func _process(d: float) -> void:
	_t += d
	queue_redraw()


func _draw() -> void:
	var hexp := PackedVector2Array()
	for i in 7:
		var a := TAU * i / 6.0 + _t * 0.5
		hexp.append(Vector2(cos(a), sin(a)) * 28.0)
	draw_colored_polygon(hexp, Color(0.9, 0.88, 1.0, 0.1 * k))
	draw_polyline(hexp, Color(0.9, 0.88, 1.0, 0.8 * k), 1.0)
	for i in 6:
		StArt.star(self, hexp[i], 2.0, Color(1, 1, 1, k), _t)
