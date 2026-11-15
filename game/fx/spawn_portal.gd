class_name SpawnPortal
extends Node2D
## 적 등장 소환진: 바닥에 원이 그려지고 빛기둥이 솟은 뒤 on_done을 부른다.

const DURATION := 0.5

var on_done: Callable
var _t := 0.0
var _done := false


func _ready() -> void:
	z_index = 2
	Sfx.play(&"spawn", -4.0)


func _process(delta: float) -> void:
	_t += delta
	if not _done and _t >= DURATION:
		_done = true
		Fx.burst(global_position + Vector2(0, -10), 16, {
			spread = 180.0, speed_min = 20.0, speed_max = 90.0, lifetime = 0.4,
			gradient = Palette.soul_gradient(), size_min = 1.0, size_max = 2.5, gravity = Vector2(0, -30),
		})
		if on_done.is_valid():
			on_done.call()
	if _t >= DURATION + 0.3:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var k := clampf(_t / DURATION, 0.0, 1.0)
	var fade := 1.0 - clampf((_t - DURATION) / 0.3, 0.0, 1.0)
	var c := Color(Palette.ENEMY_EYE, 0.8 * fade)
	# 바닥 타원 소환진
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0 + _t * 3.0
		pts.append(Vector2(cos(a) * 14.0 * k, sin(a) * 3.0 * k))
	pts.append(pts[0])
	draw_polyline(pts, c, 1.0)
	for i in 6:
		var a := TAU * i / 6.0 - _t * 4.0
		draw_rect(Rect2(Vector2(cos(a) * 10.0 * k, sin(a) * 2.2 * k) - Vector2(0.5, 0.5), Vector2(1.5, 1.5)), c)
	# 빛기둥
	var h := 30.0 * k
	draw_rect(Rect2(-6.0 * k, -h, 12.0 * k, h), Color(Palette.ENEMY_SOUL, 0.18 * fade))
	draw_rect(Rect2(-2.0 * k, -h, 4.0 * k, h), Color(1, 1, 1, 0.3 * fade))
