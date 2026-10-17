class_name RingFx
extends Node2D
## 퍼져 나가며 옅어지는 고리. Fx.ring()으로 만든다.

var r_from := 4.0
var r_to := 32.0
var color := Color.WHITE
var duration := 0.25
var width := 2.0
var _t := 0.0


func _ready() -> void:
	z_index = 6


func _process(delta: float) -> void:
	_t += delta
	if _t >= duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _t / duration
	var e := 1.0 - pow(1.0 - k, 3.0) # 처음엔 빠르게, 끝에서 느리게
	var r := lerpf(r_from, r_to, e)
	var c := Color(color, color.a * (1.0 - k))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, c, maxf(width * (1.0 - k * 0.5), 1.0))
