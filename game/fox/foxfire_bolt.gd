class_name FoxfireBolt
extends Area2D
## 여우 모드 X — 여우불 (v0.4, 플레이 피드백): 기본 공격처럼 약 1.2초마다 묵직한 한 발.
## 커다란 푸른 여우불 창이 앞쪽의 가까운 적을 따라 휘어지며(유도), 적을 꿰뚫고 계속 날아간다(관통, 적마다 한 번).
## 영혼의 불이라 벽은 통과한다. 폭발은 없다.

const BLUE := Color(0.45, 0.78, 1.0)
const CORE := Color(0.88, 0.97, 1.0)

var tuning: Tuning
var vel := Vector2.ZERO
var damage := 260
var max_dist := 320.0
var homing := 4.0
var _traveled := 0.0
var _hit := {}
var _done := false
var _t := 0.0
var _trail: Array[Vector2] = []


static func fire(pos: Vector2, dir: int, p_tuning: Tuning) -> void:
	var b := FoxfireBolt.new()
	b._init_bolt(pos, Vector2(dir, 0), p_tuning)
	Fx.effect_parent().add_child(b)
	Sfx.play(&"foxfire", 2.0, 0.05)


func _init_bolt(pos: Vector2, d: Vector2, p_tuning: Tuning) -> void:
	global_position = pos
	tuning = p_tuning
	vel = d * tuning.fox_shot_speed_t * GameConst.TILE
	damage = tuning.fox_shot_damage
	max_dist = tuning.fox_shot_range_t * GameConst.TILE
	homing = tuning.fox_shot_homing


func _ready() -> void:
	collision_layer = GameConst.L_PLAYER_ATTACK
	collision_mask = GameConst.L_ENEMY_HURT
	material = Fx.add_material
	z_index = 6
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(30, 14)
	cs.shape = r
	add_child(cs)
	area_entered.connect(_on_area)


func _physics_process(delta: float) -> void:
	if _done:
		return
	_t += delta
	var target := _nearest()
	if target:
		var want := (target.global_position + Vector2(0, -minf(target.body_size.y * 0.5, 40.0)) - global_position).angle()
		var cur := vel.angle()
		vel = vel.rotated(clampf(wrapf(want - cur, -PI, PI), -homing * delta, homing * delta))
	rotation = vel.angle()
	_trail.push_front(global_position)
	if _trail.size() > 12:
		_trail.pop_back()
	var step := vel * delta
	global_position += step
	_traveled += step.length()
	if Engine.get_physics_frames() % 2 == 0:
		Fx.burst(global_position - vel.normalized() * 12.0, 1, {spread = 40.0, speed_min = 10.0, speed_max = 40.0,
			lifetime = 0.3, gradient = Palette.fade_gradient(BLUE), add = true, gravity = Vector2(0, -30)})
	if _traveled >= max_dist:
		_finish()
	queue_redraw()


## 앞쪽(진행 방향)에 있는, 아직 꿰뚫지 않은 가장 가까운 적 (12칸 안)
func _nearest() -> EnemyBase:
	return EnemyQuery.nearest(get_tree(), _ahead_dist, 12.0 * GameConst.TILE) as EnemyBase


## 진행 방향 앞쪽이고 아직 안 꿰뚫은 적까지 거리 (아니면 INF)
func _ahead_dist(en: EnemyBase) -> float:
	if _hit.has(en):
		return INF
	var to: Vector2 = en.global_position - global_position
	if to.dot(vel) <= 0.0:
		return INF
	return to.length()


func _on_area(area: Area2D) -> void:
	if _done:
		return
	var target := area.get_parent()
	if target == null or not target.has_method("take_hit") or not target.is_alive() or _hit.has(target):
		return
	_hit[target] = true
	var hit := Hit.make(damage, &"foxfire_heavy", global_position, int(signf(vel.x)))
	hit.knockback_t = 1.4
	hit.hitstop = tuning.hitstop_heavy * 1.6
	hit.shake_t = tuning.shake_heavy_t
	hit.breaks_charge = true
	hit.zoom = tuning.zoom_punch * 0.8
	target.take_hit(hit)
	Sfx.play(&"hit_heavy", -2.0)
	Fx.burst(global_position, 18, {spread = 180.0, speed_min = 60.0, speed_max = 200.0, lifetime = 0.35,
		gradient = Palette.fade_gradient(BLUE), add = true})
	Fx.ring(global_position, 3.0, 22.0, BLUE, 0.22, 2.0)


func _finish() -> void:
	if _done:
		return
	_done = true
	set_deferred("monitoring", false)
	Fx.burst(global_position, 12, {spread = 180.0, speed_min = 30.0, speed_max = 90.0, lifetime = 0.35,
		gradient = Palette.fade_gradient(BLUE), add = true})
	queue_free()


func _draw() -> void:
	# 꼬리 (전역 자취를 지역 좌표로 — 회전되어 있으니 to_local로 그대로 씀)
	var prev := Vector2.ZERO
	for i in _trail.size():
		var p := to_local(_trail[i])
		var k := 1.0 - float(i) / _trail.size()
		draw_line(prev, p, Color(BLUE, 0.6 * k), 9.0 * k + 0.5)
		prev = p
	# 창 머리 (회전된 좌표: +x가 진행 방향)
	draw_circle(Vector2.ZERO, 18.0, Color(BLUE, 0.15))
	draw_colored_polygon(PackedVector2Array([Vector2(22, 0), Vector2(2, -7), Vector2(-14, -4), Vector2(-24, -9 + sin(_t * 30.0) * 2.0),
		Vector2(-18, 0), Vector2(-24, 9 + cos(_t * 30.0) * 2.0), Vector2(-14, 4), Vector2(2, 7)]), Color(BLUE, 0.9))
	draw_colored_polygon(PackedVector2Array([Vector2(19, 0), Vector2(3, -3.5), Vector2(-10, 0), Vector2(3, 3.5)]), CORE)
	draw_circle(Vector2(8, 0), 2.0, Color.WHITE)
