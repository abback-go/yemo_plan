class_name FoxfireBolt
extends Area2D
## 여우 모드 X — 여우불 (docs/chapter1.md 4.8절).
## 1·2타: 적을 살짝 따라가는 여우불 2발 / 3타: 관통하는 여우불 창 + 끝에서 폭발.

const BLUE := Color(0.45, 0.78, 1.0)
const CORE := Color(0.88, 0.97, 1.0)

var heavy := false
var tuning: Tuning
var vel := Vector2.ZERO
var damage := 16
var max_dist := 224.0
var _traveled := 0.0
var _hit := {}
var _done := false
var _t := 0.0
var _trail: Array[Vector2] = []
var _home := 0.0


static func fire(pos: Vector2, dir: int, p_heavy: bool, p_tuning: Tuning) -> void:
	if p_heavy:
		var b := FoxfireBolt.new()
		b._init_bolt(pos, Vector2(dir, 0), true, p_tuning)
		Fx.effect_parent().add_child(b)
		Sfx.play(&"foxfire", 2.0, 0.05)
	else:
		for i in 2:
			var b2 := FoxfireBolt.new()
			b2._init_bolt(pos + Vector2(0, -5 + i * 10), Vector2(dir, -0.12 + i * 0.24).normalized(), false, p_tuning)
			Fx.effect_parent().add_child(b2)
		Sfx.play(&"foxfire", -2.0, 0.08)


func _init_bolt(pos: Vector2, d: Vector2, p_heavy: bool, p_tuning: Tuning) -> void:
	global_position = pos
	heavy = p_heavy
	tuning = p_tuning
	var speed := 38.0 * GameConst.TILE if heavy else 32.0 * GameConst.TILE
	vel = d * speed
	damage = 48 if heavy else 16
	max_dist = (16.0 if heavy else 14.0) * GameConst.TILE
	_home = 0.0 if heavy else 5.0


func _ready() -> void:
	collision_layer = GameConst.L_PLAYER_ATTACK
	collision_mask = GameConst.L_ENEMY_HURT | (0 if heavy else GameConst.L_WORLD)
	material = Fx.add_material
	z_index = 6
	var cs := CollisionShape2D.new()
	if heavy:
		var r := RectangleShape2D.new()
		r.size = Vector2(26, 10)
		cs.shape = r
	else:
		var c := CircleShape2D.new()
		c.radius = 5.0
		cs.shape = c
	add_child(cs)
	area_entered.connect(_on_area)
	body_entered.connect(func(_b: Node) -> void: _finish())


func _physics_process(delta: float) -> void:
	if _done:
		return
	_t += delta
	if _home > 0.0:
		var target := _nearest()
		if target:
			var want := (target.global_position + Vector2(0, -12) - global_position).angle()
			var cur := vel.angle()
			vel = vel.rotated(clampf(wrapf(want - cur, -PI, PI), -_home * delta, _home * delta))
	_trail.push_front(global_position)
	if _trail.size() > (10 if heavy else 7):
		_trail.pop_back()
	var step := vel * delta
	global_position += step
	_traveled += step.length()
	if _traveled >= max_dist:
		_finish()
	queue_redraw()


func _nearest() -> Node2D:
	var best: Node2D = null
	var bd := 10.0 * GameConst.TILE
	for e in get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
		if not e.is_alive():
			continue
		var to: Vector2 = e.global_position - global_position
		if to.dot(vel) <= 0.0:
			continue
		var d := to.length()
		if d < bd:
			bd = d
			best = e
	return best


func _on_area(area: Area2D) -> void:
	if _done:
		return
	var target := area.get_parent()
	if target == null or not target.has_method("take_hit") or not target.is_alive() or _hit.has(target):
		return
	_hit[target] = true
	var hit := Hit.make(damage, &"foxfire_heavy" if heavy else &"foxfire", global_position, int(signf(vel.x)))
	hit.knockback_t = 1.2 if heavy else 0.3
	hit.hitstop = tuning.hitstop_heavy if heavy else tuning.hitstop_light
	hit.shake_t = tuning.shake_heavy_t if heavy else tuning.shake_light_t
	hit.breaks_charge = heavy
	hit.zoom = tuning.zoom_punch * 0.6 if heavy else 0.0
	target.take_hit(hit)
	Sfx.play(&"hit_heavy" if heavy else &"hit", -3.0)
	Fx.burst(global_position, 10, {spread = 180.0, speed_min = 40.0, speed_max = 140.0, lifetime = 0.3,
		gradient = Palette.fade_gradient(BLUE), add = true})
	if not heavy:
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	set_deferred("monitoring", false)
	if heavy:
		# 창 끝 폭발
		var r := 2.4 * GameConst.TILE
		for e in get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
			if e.is_alive() and not _hit.has(e) and (e.global_position + Vector2(0, -10)).distance_to(global_position) <= r + 8.0:
				var hit := Hit.make(24, &"foxfire_heavy", global_position)
				hit.knockback_t = 1.0
				e.take_hit(hit)
		Fx.ring(global_position, 4.0, r, BLUE, 0.3, 2.0)
		Fx.burst(global_position, 26, {spread = 180.0, speed_min = 50.0, speed_max = 180.0, lifetime = 0.45,
			gradient = Palette.fade_gradient(BLUE), add = true, damping = 120.0})
		Sfx.play(&"blast", -4.0)
	queue_free()


func _draw() -> void:
	var prev := Vector2.ZERO
	for i in _trail.size():
		var p := to_local(_trail[i])
		var k := 1.0 - float(i) / _trail.size()
		draw_line(prev, p, Color(BLUE, 0.55 * k), (6.0 if heavy else 3.5) * k + 0.5)
		prev = p
	if heavy:
		var d := vel.normalized()
		var side := Vector2(-d.y, d.x)
		draw_colored_polygon(PackedVector2Array([d * 16.0, side * 5.0, -d * 12.0, -side * 5.0]), Color(BLUE, 0.9))
		draw_colored_polygon(PackedVector2Array([d * 14.0, side * 2.0, -d * 6.0, -side * 2.0]), CORE)
		# 여우 꼬리 같은 날개
		draw_colored_polygon(PackedVector2Array([-d * 2.0, -d * 14.0 + side * 9.0 * sin(_t * 20.0), -d * 6.0]), Color(BLUE, 0.6))
	else:
		var f := 1.0 + 0.2 * sin(_t * 30.0)
		draw_circle(Vector2.ZERO, 5.5 * f, Color(BLUE, 0.6))
		draw_circle(Vector2.ZERO, 3.0 * f, CORE)
		draw_colored_polygon(PackedVector2Array([Vector2(-2, -3), -vel.normalized() * 10.0 + Vector2(0, -2), Vector2(-2, 3)]), Color(BLUE, 0.7))
