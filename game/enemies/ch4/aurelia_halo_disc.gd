extends EnemyAttackArea
## 아우렐리아(aurelia_boss.gd)의 빛 고리.

var boss: AureliaBoss
var white := false
var delay := 0.0
var start := Vector2.ZERO
var lane_y := 0.0
var dir := 1.0
var range_px := 200.0
var speed := 260.0
var reflected := false
var _t := 0.0
var _x := 0.0
var _out := true
var _spin := 0.0
var _reflect_dmg := 150


func _ready() -> void:
	cause = &"aurelia_halo"
	damage = 1
	dodgeable = true
	active = false
	z_index = 6
	material = Fx.add_material
	add_to_group(&"enemy_projectile")
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 9.0
	cs.shape = c
	add_child(cs)
	global_position = start
	visible = false


func reflect(_new_dir: Vector2, dmg: int) -> void:
	if reflected or not active:
		return
	reflected = true
	active = false
	_reflect_dmg = dmg
	Sfx.play(&"reflect", 0.0, 0.0)


func _physics_process(delta: float) -> void:
	var d := delta * Fx.enemy_time
	_t += d
	_spin += d * 18.0
	if _t < delay:
		return
	if not visible:
		visible = true
		active = true
		_x = 0.0
		Sfx.play(&"whoosh", -2.0, 0.1)
	if boss == null or not is_instance_valid(boss) or not boss.is_alive():
		queue_free()
		return
	if reflected:
		# 되쏘아짐: 주인에게 날아가 맞힘
		var to := boss.global_position + Vector2(0, -26)
		global_position = global_position.move_toward(to, 520.0 * delta)
		if global_position.distance_to(to) < 10.0:
			boss.halo_reflected_hit(_reflect_dmg * 2)
			Fx.ring(global_position, 4.0, 40.0, Color(1.0, 0.75, 0.4), 0.3, 3.0)
			queue_free()
		queue_redraw()
		return
	var y := lerpf(start.y, lane_y, clampf((_t - delay) / 0.2, 0.0, 1.0))
	if _out:
		_x += speed * d * (1.0 - clampf(_x / range_px, 0.0, 0.85))
		global_position = Vector2(start.x + dir * _x, y)
		if _x >= range_px * 0.97:
			_out = false
	else:
		# 돌아옴: 주인 손으로
		var home := boss.global_position + Vector2(0, -30)
		global_position = global_position.move_toward(Vector2(home.x, lane_y if absf(global_position.x - home.x) > 24.0 else home.y), speed * 1.1 * d)
		if global_position.distance_to(home) < 12.0:
			queue_free()
			return
	if Engine.get_physics_frames() % 2 == 0:
		Fx.burst(global_position, 2, {spread = 180.0, speed_min = 10.0, speed_max = 40.0, lifetime = 0.3,
			gradient = Palette.fade_gradient(Color(1, 1, 1) if white else Color(1.0, 0.86, 0.45)), size_min = 1.0, size_max = 2.0,
			gravity = Vector2.ZERO, add = true})
	queue_redraw()


func _draw() -> void:
	var gold := Color(1.0, 0.86, 0.45) if not white else Color(1.0, 0.98, 0.9)
	if reflected:
		gold = Color(1.0, 0.6, 0.3)
	draw_circle(Vector2.ZERO, 13.0, Color(gold, 0.15))
	draw_arc(Vector2.ZERO, 9.0, 0, TAU, 24, Color(gold, 0.95), 2.5)
	draw_arc(Vector2.ZERO, 6.0, 0, TAU, 18, Color(gold, 0.5), 1.0)
	for i in 10:
		var a := _spin + TAU * i / 10.0
		draw_line(Vector2(cos(a), sin(a)) * 10.0, Vector2(cos(a), sin(a)) * 13.5, Color(gold, 0.85), 1.0)
	if white:
		draw_line(Vector2(-7, -3), Vector2(2, 1), Color.WHITE, 1.0)
		draw_line(Vector2(2, 1), Vector2(5, 6), Color.WHITE, 1.0)
