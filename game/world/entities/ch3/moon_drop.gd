class_name MoonDrop
extends Node2D
## 달샘의 달빛 방울 (docs/chapter3.md 7.3절 — 달샘 퍼즐). 천장의 틈(이 개체 자리)에서 period초마다 달빛 방울이 천천히 떨어진다.
## 해롭지 않다. 불꽃 방벽(ward)에 닿으면 되쏘아져 곧장 위로 날아올라, 위에 걸린 달빛 수정(moon_crystal)을 밝힌다.
## (flame_ward가 enemy_projectile 그룹의 reflect()를 부른다 — docs/systems2.md 3절)
## 방 데이터: {t = "moon_drop", x, y, period = 2.4, phase = 0.0, on_if = ""}

var period := 2.4
var on_if := ""
var _t := 0.0


func setup(room: Room, e: Dictionary, _eid: String) -> void:
	position = room.tile_pos(e) + Vector2(8, 4)
	period = float(e.get("period", 2.4))
	_t = float(e.get("phase", 0.0))
	on_if = String(e.get("on_if", ""))
	z_index = 3


func _physics_process(delta: float) -> void:
	_t += delta
	if _t >= period:
		_t = 0.0
		if RoomData.cond_ok(on_if):
			var o := MoonOrb.new()
			o.global_position = global_position + Vector2(0, 4)
			Fx.effect_parent().add_child(o)
	queue_redraw()


func _draw() -> void:
	# 천장 틈으로 드는 달빛 기둥 + 맺히는 방울
	var k := clampf(_t / period, 0.0, 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-5, -4), Vector2(5, -4), Vector2(14, 120), Vector2(-14, 120)]), Color(0.75, 0.88, 1.0, 0.05))
	draw_rect(Rect2(-6, -4, 12, 2), Color(0.85, 0.92, 1.0, 0.5))
	draw_circle(Vector2(0, 2), 1.0 + k * 2.5, Color(0.9, 0.96, 1.0, 0.4 + 0.5 * k))


## 달빛 방울 (되쏘면 위로)
class MoonOrb extends Area2D:
	var reflected := false
	var active := true
	var _vel := Vector2(0, 46)
	var _t := 0.0
	var _hit := false

	func _ready() -> void:
		add_to_group(&"enemy_projectile")
		collision_layer = 0
		collision_mask = GameConst.L_WORLD
		monitoring = true
		var cs := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = 4.0
		cs.shape = c
		add_child(cs)
		body_entered.connect(func(_b: Node) -> void: _pop())
		area_entered.connect(_on_area)
		material = Fx.add_material
		z_index = 5

	func reflect(_dir: Vector2, _damage: int) -> void:
		if reflected:
			return
		reflected = true
		_vel = Vector2(0, -260)
		collision_mask = GameConst.L_WORLD | GameConst.L_ENEMY_HURT
		Ch3Sfx.play(&"ch3_glass", -4.0, 0.1)
		Fx.ring(global_position, 3.0, 18.0, Color(0.85, 0.92, 1.0), 0.3, 2.0)

	func _on_area(a: Area2D) -> void:
		if not reflected or _hit:
			return
		var t := a.get_parent()
		if t and t.has_method("take_hit"):
			_hit = true
			t.take_hit(Hit.make(1, &"reflect", global_position, 0))
			_pop()

	func _physics_process(delta: float) -> void:
		_t += delta
		global_position += _vel * delta
		if _t > 6.0:
			queue_free()
		queue_redraw()

	func _pop() -> void:
		Fx.burst(global_position, 8, {spread = 180.0, speed_min = 10.0, speed_max = 40.0, lifetime = 0.4,
			gradient = Palette.fade_gradient(Color(0.85, 0.92, 1.0)), size_min = 1.0, size_max = 2.0, gravity = Vector2.ZERO, add = true})
		queue_free()

	func _draw() -> void:
		var g := 0.8 + 0.2 * sin(_t * 8.0)
		draw_circle(Vector2.ZERO, 7.0, Color(0.75, 0.88, 1.0, 0.12 * g))
		draw_circle(Vector2.ZERO, 3.5, Color(0.85, 0.93, 1.0, 0.8 * g))
		draw_circle(Vector2(-1, -1), 1.2, Color(1, 1, 1, g))
		if reflected:
			draw_line(Vector2.ZERO, Vector2(0, 14), Color(0.85, 0.93, 1.0, 0.5), 2.0)
