class_name PracticeTarget
extends Node2D
## 실습장 과녁 (docs/chapter1.md 12.3절): 위아래·좌우로 움직이고, 불에 맞으면 hold초 동안 켜진다.
## 퍼즐 처리기(TargetPuzzle, entity "puzzle" mode=targets)가 "모두 켜짐 + 폭주 70 미만"을 확인한다.

var group := ""
var lit_t := 0.0
var hold := 3.0
var axis := Vector2.ZERO ## 움직이는 방향·폭 (px). 0이면 고정
var period := 2.4
var _base := Vector2.ZERO
var _t := 0.0
var _hurt: Area2D


func setup(room: Room, e: Dictionary, _eid: String) -> void:
	group = String(e.get("group", "targets"))
	hold = float(e.get("hold", 3.0))
	axis = Vector2(float(e.get("dx", 0)), float(e.get("dy", 0))) * 16.0
	period = float(e.get("period", 2.4))
	_t = float(e.get("phase", 0.0))
	position = room.tile_pos(e) + Vector2(8, 0)
	_base = position
	add_to_group(&"practice_target")
	_hurt = Area2D.new()
	_hurt.collision_layer = GameConst.L_ENEMY_HURT
	_hurt.collision_mask = 0
	_hurt.monitoring = false
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 10
	cs.shape = c
	cs.position = Vector2(0, -18)
	_hurt.add_child(cs)
	add_child(_hurt)


func is_alive() -> bool:
	return true


func is_on_floor() -> bool:
	return true


func is_lit() -> bool:
	return lit_t > 0.0


func take_hit(_hit: Hit) -> void:
	if lit_t <= 0.0:
		Sfx.play(&"ignite", -4.0, 0.1)
		Fx.burst(global_position + Vector2(0, -18), 10, {spread = 180.0, speed_min = 30.0, speed_max = 80.0, lifetime = 0.3})
	lit_t = hold


func _physics_process(delta: float) -> void:
	_t += delta
	if axis != Vector2.ZERO:
		position = _base + axis * sin(_t * TAU / period)
	if lit_t > 0.0:
		lit_t -= delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-1, -8, 2, 8), Color("#4a3426"))
	var lit := lit_t > 0.0
	var ring := Color("#e8dcc0")
	var mid := Color("#c03030")
	if lit:
		ring = Color(1.0, 0.85, 0.5)
		mid = Palette.FIRE_HOT
		draw_circle(Vector2(0, -18), 14, Color(Palette.FIRE_OUT, 0.25))
	draw_circle(Vector2(0, -18), 10, ring)
	draw_circle(Vector2(0, -18), 7, mid)
	draw_circle(Vector2(0, -18), 3.5, ring)
	if lit:
		# 남은 시간 호
		draw_arc(Vector2(0, -18), 12, -PI * 0.5, -PI * 0.5 + TAU * (lit_t / hold), 16, Palette.FIRE_HOT, 1.0)
