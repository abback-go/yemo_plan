extends EnemyAttackArea
## 빛기둥: 하늘에서 땅까지 꽂히는 굵은 흰 빛 (0.3초 판정)
## 흰 전령(white_herald.gd)의 빛창.

var a := Vector2.ZERO
var b := Vector2.ZERO
var _t := 0.0


func setup(p_a: Vector2, p_b: Vector2) -> void:
	a = p_a
	b = p_b


func _ready() -> void:
	cause = &"herald_lance"
	damage = 1
	dodgeable = true
	z_index = 6
	material = Fx.add_material
	global_position = (a + b) * 0.5
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(a.distance_to(b), 10)
	cs.shape = rs
	cs.rotation = (b - a).angle()
	add_child(cs)
	Fx.burst(b, 16, {direction = Vector2.UP, spread = 70.0, speed_min = 40.0, speed_max = 140.0, lifetime = 0.5,
		gradient = Palette.fade_gradient(Color(1, 1, 1)), size_min = 1.0, size_max = 2.5, gravity = Vector2(0, 200), add = true})
	Fx.ring(b, 4.0, 26.0, Color(1, 1, 1), 0.3, 2.0)


func _physics_process(delta: float) -> void:
	_t += delta * Fx.enemy_time
	active = _t < 0.3
	if _t > 0.6:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var la := to_local(a)
	var lb := to_local(b)
	var k := clampf(1.0 - _t / 0.6, 0.0, 1.0)
	var w := 14.0 * (1.0 if _t < 0.3 else k * 1.5)
	draw_line(la, lb, Color(1, 1, 1, 0.25 * k), w + 8.0)
	draw_line(la, lb, Color(0.9, 0.92, 1.0, 0.8 * k), w)
	draw_line(la, lb, Color(1, 1, 1, k), maxf(w * 0.3, 1.0))
