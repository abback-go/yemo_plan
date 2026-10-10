class_name ECaster
extends EEnemy
## 원거리 "붉은 등불 망령": 에스카와 거리를 두고 떠다니다(옆 95~155 · 위 52~80 — 단공·천열이 닿는 거리), 등불이 타오르며 조준(0.75초, 붉은 조준선)
## → 핏빛 구슬 한 발(초속 150). 구슬은 참격으로 베어 없앨 수 있다(ECaster.Orb — 겨누기 대상은 아님).
## 조준하는 동안 맞으면 끊긴다.

enum S { FLOAT, AIM }

const AIM_T := 0.75
const LOCK_T := 0.2 ## 쏘기 직전 이 시간 동안은 조준선이 멈춤 (피할 틈)
const ORB_SPEED := 150.0

var st := S.FLOAT
var st_t := 0.0
var _cool := 1.4
var _side := 1.0
var _aim := Vector2.ZERO


func _init() -> void:
	max_hp = 240
	size = Vector2(20, 26)
	flying = true
	contact_dmg = 0


func _ready() -> void:
	super._ready()
	_side = 1.0 if randf() < 0.5 else -1.0


func core() -> Vector2:
	return global_position + Vector2(0, -9 + sin(t * 2.4) * 2.0)


func _think(delta: float) -> void:
	st_t += delta
	_cool = maxf(_cool - delta, 0.0)
	if not eska_ok():
		velocity = velocity.move_toward(Vector2.ZERO, 200.0 * delta)
		return
	var ec := eska.center()
	facing = toward_eska()
	match st:
		S.FLOAT:
			# 에스카와 같은 쪽을 유지 (너무 가까우면 반대로 넘어가지 않고 물러남)
			var dx := global_position.x - ec.x
			if absf(dx) > 40.0:
				_side = signf(dx)
			var want := ec + Vector2(_side * (125.0 + 30.0 * sin(t * 0.7)), -66.0 + sin(t * 1.3) * 14.0)
			want.x = clampf(want.x, x_min + 20.0, x_max - 20.0)
			if want.x <= x_min + 21.0 or want.x >= x_max - 21.0:
				_side = -_side # 벽에 몰리면 반대편으로 건너감
			var v := (want - global_position) * 2.2
			velocity = velocity.move_toward(v.limit_length(115.0), 320.0 * delta)
			if _cool <= 0.0 and global_position.distance_to(ec) < 330.0:
				st = S.AIM
				st_t = 0.0
				_aim = ec
				Sfx.play_pitch(&"sniper_aim", 1.2, -10.0)
		S.AIM:
			velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
			if st_t < AIM_T - LOCK_T:
				_aim = _aim.lerp(ec, 1.0 - exp(-delta * 12.0))
			if st_t >= AIM_T:
				_fire()
				st = S.FLOAT
				st_t = 0.0
				_cool = 1.8 + randf() * 0.6


func _fire() -> void:
	var o := Orb.new()
	var from := core()
	o.vel = (_aim - from).normalized() * ORB_SPEED
	o.position = from
	Fx.effect_parent().add_child(o)
	velocity -= o.vel.normalized() * 70.0 # 반동
	Sfx.play_pitch(&"sniper_shot", 1.3, -8.0)
	var pp := PParticles.get_layer(true)
	for i in 6:
		pp.spawn(from, o.vel.normalized().rotated(randf_range(-0.6, 0.6)) * randf_range(40, 110), Vector2.ZERO, 0.25, 1.5, RED_HOT, RED_DEEP, 0, 4.0)


func _interrupted() -> void:
	if st == S.AIM:
		st = S.FLOAT
		st_t = 0.0
		_cool = 0.8


# ═══════════════════════════════════════════════════════════
# 그림: 찢어진 검은 두건 + 뼈 가면(붉은 실눈) + 가슴의 붉은 등불, 아래로 너풀대는 자락
# ═══════════════════════════════════════════════════════════

func _paint_body(a: float) -> void:
	var bob := sin(t * 2.4) * 2.0
	var lean := clampf(velocity.x * float(facing) / 120.0, -1.0, 1.0) * 0.12
	xf(Vector2(0, bob), lean)
	var aim := smoothstep(0.0, AIM_T, st_t) if st == S.AIM else 0.0
	# 자락: 아래로 갈수록 갈라지며 흔들림
	var hem := PackedVector2Array()
	hem.append(Vector2(-9, -16))
	for i in 7:
		var f := float(i) / 6.0
		var x := lerpf(-10.0, 9.0, f)
		var y := 2.0 + (4.0 if i % 2 == 0 else -1.0) + sin(t * 6.0 + f * 5.0) * 1.8
		hem.append(Vector2(x + sin(t * 4.0 + f * 3.0) * 1.5 - lean * 20.0, y))
	hem.append(Vector2(9, -15))
	hem.append(Vector2(3, -26))
	hem.append(Vector2(-4, -27))
	pd.draw_colored_polygon(hem, col(BLACK, a))
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-6, -14), Vector2(-3, -24), Vector2(1, -24), Vector2(-2, -8), Vector2(-7, -2)]), col(SHADE, a))
	# 뼈 가면
	var m := Vector2(3, -18)
	pd.draw_set_transform_matrix(_base * Transform2D(lean, Vector2.ONE, 0.0, Vector2(0, bob)) * Transform2D(0.0, Vector2(1.0, 1.25), 0.0, m))
	pd.draw_circle(Vector2.ZERO, 4.6, col(BONE, a))
	xf(Vector2(0, bob), lean)
	pd.draw_line(m + Vector2(-2.5, -1.0), m + Vector2(-0.5, -0.4), Color(RED.lerp(RED_HOT, aim), a), 1.2)
	pd.draw_line(m + Vector2(1.0, -0.4), m + Vector2(3.4, -1.2), Color(RED.lerp(RED_HOT, aim), a), 1.2)
	pd.draw_line(m + Vector2(-1.0, 2.2), m + Vector2(-0.2, 4.8), col(BONE_DIM, a), 0.8)
	# 등불
	var c := Vector2(0, -9)
	var pulse := 0.5 + 0.5 * sin(t * 5.0)
	pd.glow(c, 7.0 + 4.0 * pulse + 10.0 * aim, Color(RED, (0.35 + 0.4 * aim) * a), 0.0)
	pd.draw_circle(c, 2.6 + aim * 1.0, Color(RED_DEEP, a))
	pd.draw_circle(c, 1.6 + aim * 1.0, Color(RED.lerp(RED_HOT, aim), a))
	# 주위를 도는 뼈 조각 둘
	for i in 2:
		var an := t * 2.2 + float(i) * PI
		var p := c + Vector2(cos(an) * 11.0, sin(an) * 4.0 - 2.0)
		pd.draw_colored_polygon(PackedVector2Array([p + Vector2(-1.5, 0), p + Vector2(0, -3), p + Vector2(1.5, 0), p + Vector2(0, 2)]), col(BONE_DIM, a * (0.6 + 0.4 * sin(an))))
	pd.draw_set_transform(Vector2.ZERO)
	if st == S.AIM:
		_paint_aim(a, aim)


## 조준선: 등불에서 겨눈 곳까지 점선 (멈추면 굵고 밝아짐)
func _paint_aim(a: float, f: float) -> void:
	var from := core() - global_position
	var to := _aim - global_position
	var locked := st_t >= AIM_T - LOCK_T
	var d := to - from
	var n := int(d.length() / 9.0)
	var c := Color(RED_HOT if locked else RED, (0.25 + 0.55 * f) * a)
	for i in n:
		if i % 2 == 0:
			pd.draw_line(from + d * (float(i) / n), from + d * (float(i + 1) / n), c, 1.5 if locked else 1.0)
	if locked:
		pd.draw_arc(to, 5.0, 0.0, TAU, 12, c, 1.0)


## 핏빛 구슬: 참격으로 벨 수 있는 표적(체력 1, 겨누기 대상 아님). 에스카에 닿으면 피해 1, 땅·벽에 닿거나 4초 지나면 터짐
class Orb extends PDraw.Canvas:
	var vel := Vector2.ZERO
	var lockable := false
	var _life := 4.0
	var _t := 0.0
	var _dead := false
	var _trail := PackedVector2Array()

	func _ready() -> void:
		add_to_group(PDummy.GROUP)
		z_index = 4

	func hit_rect() -> Rect2:
		return Rect2(global_position - Vector2(6, 6), Vector2(12, 12))

	func center() -> Vector2:
		return global_position

	func is_dead() -> bool:
		return _dead

	func take_hit(_dmg: int, _from: Vector2, _opts := {}) -> void:
		_pop(true)

	func bind(_sec: float, _awake: bool, _fox := true, _style := "") -> void:
		pass

	func unbind() -> void:
		pass

	func _process(delta: float) -> void:
		if _dead:
			return
		_t += delta
		global_position += vel * delta
		_trail.append(global_position)
		if _trail.size() > 7:
			_trail.remove_at(0)
		var e := EEska.find(get_tree())
		if is_instance_valid(e) and not e.is_dead() and e.hurt_rect().grow(4.0).has_point(global_position):
			if e.hurt(1, global_position - vel.normalized() * 20.0):
				_pop(false)
				return
		var q := PhysicsPointQueryParameters2D.new()
		q.position = global_position
		q.collision_mask = 1
		if _t >= _life or not get_world_2d().direct_space_state.intersect_point(q, 1).is_empty():
			_pop(false)
			return
		queue_redraw()

	## 터짐 (cut = 베어서 — 흰 섬광이 더 큼)
	func _pop(cut: bool) -> void:
		if _dead:
			return
		_dead = true
		remove_from_group(PDummy.GROUP)
		var pp := PParticles.get_layer(true)
		for i in (10 if cut else 6):
			pp.spawn(global_position, Vector2.from_angle(randf() * TAU) * randf_range(40, 140), Vector2(0, 200), randf_range(0.2, 0.4), randf_range(1.0, 2.2),
				EEnemy.RED_HOT, EEnemy.RED_DEEP, 0, 3.0)
		if cut:
			Sfx.play_pitch(&"block", 1.4, -8.0)
		queue_free()

	func _paint() -> void:
		var n := _trail.size()
		for i in range(1, n):
			var f := float(i) / float(n)
			pd.line2(_trail[i - 1] - global_position, _trail[i] - global_position, Color(EEnemy.RED, 0.0), Color(EEnemy.RED, 0.6 * f), 1.0, 5.0 * f)
		var p := 1.0 + 0.15 * sin(_t * 30.0)
		pd.glow(Vector2.ZERO, 11.0 * p, Color(EEnemy.RED, 0.45), 0.0)
		pd.draw_circle(Vector2.ZERO, 5.0 * p, EEnemy.RED)
		pd.draw_circle(Vector2.ZERO, 3.2, EEnemy.BLACK)
		pd.draw_circle(Vector2(-1, -1), 1.3, EEnemy.RED_HOT)
