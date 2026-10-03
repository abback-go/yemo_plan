class_name MossStag
extends EnemyBase
## 이끼 사슴 (docs/chapter3.md 4절) — 숲의 순한 짐승. 등에 이끼와 작은 빛꽃이 자라고, 뿔엔 잎이 돋는다.
## - 순한 개체(blighted = false): 먼저 공격하지 않는다. 풀을 뜯고, 귀를 털고, 세라가 다가오면 고개를 든다.
##   맞으면 놀라 "콧김" → 그때부터 맞서 싸운다(다만 쉬는 시간이 길다).
## - 역병 개체(blighted = true): 몸 곳곳이 흰 수정으로 굳고 눈이 하얗게 빛난다. 처음부터 사납다.
## 패턴: 뿔 돌진(고개를 낮추고 앞발로 땅을 긁음 — 뿔이 붉게 번쩍, 0.85초 → 벽·낭떠러지까지 돌진, 벽에 박히면 비틀)
##       뿔 휘두르기(가까울 때: 앞발을 들고 일어섬 0.6초 → 앞쪽 큰 호)
## 쓰러뜨리면 죽지 않는다: 무릎 꿇고 흰 역병이 타서 떨어져 나간 뒤(정화) 일어나 숲으로 뛰어간다.

enum S { GRAZE, ALERT, STALK, CHARGE_WINDUP, CHARGE, STAGGER, SWEEP_WINDUP, SWEEP, RECOVER, PURIFY, LEAVE }

const HP := 700
const WALK_T := 2.0
const STALK_T := 2.6
const CHARGE_T := 12.5
const CHARGE_MAX_T := 14.0
const CHARGE_WINDUP := 0.85
const SWEEP_WINDUP := 0.6
const SWEEP_TIME := 0.22
const STAGGER_TIME := 1.1
const RECOVER_TIME := 0.7
const REST := Vector2(1.0, 1.6) ## 공격 사이 (최소, 최대) — 순한 개체는 1.5배
const BLIGHT_WHITE := Color("#e8e8f2")

@export var blighted := false

var state: S = S.GRAZE
var agitated := false
var _timer := 0.0
var _dur := 0.0
var _cd := 1.0
var _charge_from := 0.0
var _wander := 0.0
var _graze := 0.0
var _purify_t := 0.0
var _contact: EnemyAttackArea
var _sweep: EnemyAttackArea


func _build() -> void:
	max_hp = HP
	body_size = Vector2(30, 26)
	knock_mult = 0.4
	launch_mult = 0.4
	kind_id = "moss_stag"
	display_name = "이끼 사슴"
	subtitle = "숲을 지키는 순한 짐승" if not blighted else "흰 역병에 물든 숲의 짐승"
	_visual = StagVisual.new()
	(_visual as StagVisual).enemy = self
	add_child(_visual)
	_contact = add_attack_area(Vector2(28, 22), Vector2(6, -14), &"moss_stag")
	_contact.active = false
	_sweep = add_attack_area(Vector2(40, 30), Vector2(18, -18), &"moss_stag")
	_sweep.active = false
	agitated = blighted
	is_elite = true


func _ready() -> void:
	super()
	agitated = blighted
	subtitle = "숲을 지키는 순한 짐승" if not blighted else "흰 역병에 물든 숲의 짐승"
	_cd = randf_range(0.8, 1.4)


func state_k() -> float:
	return clampf(1.0 - _timer / _dur, 0.0, 1.0) if _dur > 0.0 else 0.0


func _enter(s: S, dur := 0.0) -> void:
	state = s
	_timer = dur
	_dur = dur


func purify_k() -> float:
	return clampf(_purify_t / 1.6, 0.0, 1.0)


func _ai(delta: float) -> void:
	var t := GameConst.TILE
	_place(_contact, Vector2(6, -14))
	_place(_sweep, Vector2(18, -18))
	_timer -= delta
	var p := player()
	if not engaged or p == null or not p.is_alive():
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		return
	var dx := p.global_position.x - global_position.x
	var adx := absf(dx)
	match state:
		S.GRAZE:
			_contact.active = false
			# 순한 개체: 어슬렁거리며 풀을 뜯는다. 세라가 가까우면 고개를 들고 바라봄
			_wander -= delta
			if _wander <= 0.0:
				_wander = randf_range(2.0, 4.0)
				_graze = randf_range(1.2, 2.4)
				if randf() < 0.5:
					facing = -facing
			if _graze > 0.0:
				_graze -= delta
				velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
			else:
				var want := facing * WALK_T * t * 0.5
				if is_on_wall() or _ledge_ahead():
					facing = -facing
					want = 0.0
				velocity.x = move_toward(velocity.x, want, 200.0 * delta)
			if adx < 5.0 * t:
				face_player()
				_graze = maxf(_graze, 0.3)
			if agitated:
				_enter(S.ALERT, 0.6)
				face_player()
				Ch3Sfx.play(&"ch3_bellow", -2.0, 0.1)
		S.ALERT:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if _timer <= 0.0:
				_enter(S.STALK)
		S.STALK:
			face_player()
			_cd -= delta
			var want2 := 0.0
			if adx > 5.5 * t and not _ledge_ahead():
				want2 = facing * STALK_T * t
			elif adx < 2.5 * t and not _ledge_behind():
				want2 = -facing * STALK_T * t * 0.6
			velocity.x = move_toward(velocity.x, want2, 400.0 * delta)
			if _cd <= 0.0 and absf(p.global_position.y - global_position.y) < 3.0 * t:
				if adx < 3.2 * t:
					_enter(S.SWEEP_WINDUP, Difficulty.telegraph(SWEEP_WINDUP))
					Ch3Sfx.play(&"ch3_bellow", -6.0, 0.15)
				else:
					_enter(S.CHARGE_WINDUP, Difficulty.telegraph(CHARGE_WINDUP))
					Sfx.play(&"charger_windup", -3.0, 0.05)
		S.CHARGE_WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if fmod(_timer, 0.2) < delta:
				Fx.burst(global_position + Vector2(facing * 8, 0), 3, {direction = Vector2(-facing, -1), spread = 30.0, speed_min = 20.0,
					speed_max = 50.0, lifetime = 0.3, gradient = Palette.fade_gradient(Color("#6a5a3a")), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 200)})
			if _timer <= 0.0:
				_enter(S.CHARGE)
				_charge_from = global_position.x
				_contact.active = true
				_contact.dodgeable = true
				Sfx.play(&"charger_charge", -2.0)
		S.CHARGE:
			velocity.x = facing * CHARGE_T * t
			if Engine.get_physics_frames() % 3 == 0:
				Fx.burst(global_position + Vector2(-facing * 10, -2), 2, {direction = Vector2(-facing, -0.6), spread = 25.0, speed_min = 30.0,
					speed_max = 70.0, lifetime = 0.3, gradient = Palette.fade_gradient(Color("#7a8a5a")), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 160)})
			if is_on_wall():
				_contact.active = false
				velocity.x = -facing * 3.0 * t
				velocity.y = -140.0
				_enter(S.STAGGER, STAGGER_TIME)
				Sfx.play(&"slam", -2.0, 0.1)
				Fx.shake(0.2, 0.25)
				Fx.burst(global_position + Vector2(facing * 16, -16), 12, {spread = 120.0, direction = Vector2(-facing, -0.5), speed_min = 40.0,
					speed_max = 120.0, lifetime = 0.4, gradient = Palette.fade_gradient(Color("#c8d8a0")), size_min = 1.0, size_max = 2.5})
			elif _ledge_ahead() or absf(global_position.x - _charge_from) > CHARGE_MAX_T * t:
				_contact.active = false
				_enter(S.RECOVER, RECOVER_TIME)
		S.STAGGER:
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
			if _timer <= 0.0:
				_rest()
		S.SWEEP_WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _timer <= 0.0:
				_enter(S.SWEEP, SWEEP_TIME)
				_sweep.active = true
				_sweep.dodgeable = true
				Ch3Sfx.play(&"ch3_whip", -2.0, 0.1)
				Sfx.play(&"swing", -2.0, 0.1)
				velocity.x = facing * 3.0 * t
		S.SWEEP:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if _timer <= 0.0:
				_sweep.active = false
				_enter(S.RECOVER, RECOVER_TIME)
		S.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if _timer <= 0.0:
				_rest()


func _rest() -> void:
	_enter(S.STALK)
	_cd = Difficulty.rest(randf_range(REST.x, REST.y) * (1.0 if blighted else 1.5))


func _place(a: EnemyAttackArea, off: Vector2) -> void:
	var cs := a.get_child(0) as CollisionShape2D
	if cs:
		cs.position = Vector2(off.x * facing, off.y)


func _ledge_ahead() -> bool:
	return _ledge(facing)


func _ledge_behind() -> bool:
	return _ledge(-facing)


func _ledge(dir: int) -> bool:
	var space := get_world_2d().direct_space_state
	var from := global_position + Vector2(dir * 18, -4)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 20), GameConst.L_WORLD | GameConst.L_PLATFORM)
	return space.intersect_ray(q).is_empty()


func _resists_knockback(_hit: Hit) -> bool:
	return state == S.CHARGE


func _on_hit(hit: Hit, _dir: int) -> void:
	if not agitated:
		# 순한 사슴을 때렸다: 놀라서 맞선다
		agitated = true
		facing = 1 if hit.source_pos.x > global_position.x else -1
	if state == S.CHARGE and hit.breaks_charge:
		_contact.active = false
		_enter(S.STAGGER, 0.7)


## 쓰러지면 정화: 죽지 않고 무릎 꿇었다가 일어나 숲으로 돌아간다
func _die(_dir: int) -> void:
	_alive = false
	if not respawns:
		GameState.mark_killed(uid)
	GameState.add("purified")
	StyleRank.on_kill()
	Fx.hitstop(tuning.hitstop_kill)
	defeated.emit(self)
	collision_layer = 0
	_hurtbox.set_deferred("monitorable", false)
	_contact.active = false
	_sweep.active = false
	_enter(S.PURIFY)
	_purify_t = 0.0
	velocity.x = 0.0
	Ch3Sfx.play(&"ch3_purify", 0.0, 0.0)
	Fx.flash(Color(0.85, 1.0, 0.7, 0.18), 0.3)


func _physics_process(delta: float) -> void:
	super(delta)
	if _alive:
		return
	_flash = maxf(_flash - delta, 0.0) # 기반 클래스는 쓰러진 뒤 깜빡임을 줄이지 않는다
	_purify_t += delta
	if not is_on_floor():
		velocity.y = minf(velocity.y + _gravity * delta, 600.0)
	if state == S.PURIFY:
		velocity.x = 0.0
		# 흰 조각이 타서 떨어지고 초록 빛이 피어오름
		if Engine.get_physics_frames() % 4 == 0 and _purify_t < 1.4:
			var c := global_position + Vector2(randf_range(-14, 14), randf_range(-24, -6))
			Fx.burst(c, 2, {direction = Vector2.UP, spread = 40.0, speed_min = 10.0, speed_max = 40.0, lifetime = 0.7,
				gradient = Palette.fade_gradient(BLIGHT_WHITE if blighted and randf() < 0.5 else Color(0.75, 1.0, 0.55)), size_min = 1.0,
				size_max = 2.0, gravity = Vector2(0, -30), add = true})
		if _purify_t >= 1.8:
			state = S.LEAVE
			_purify_t = 0.0
			face_player()
			facing = -facing # 세라 반대쪽(숲)으로
			velocity.y = -260.0
			Ch3Sfx.play(&"ch3_bellow", -6.0, 0.1)
	elif state == S.LEAVE:
		velocity.x = facing * 9.0 * GameConst.TILE
		if is_on_floor() and _purify_t > 0.2:
			velocity.y = -200.0
		if _visual:
			_visual.modulate.a = clampf(1.0 - (_purify_t - 0.4) / 0.6, 0.0, 1.0)
		if _purify_t > 1.0:
			queue_free()
	move_and_slide()
	if _visual:
		_visual.queue_redraw()


## 이끼 사슴 그림: 오른쪽을 볼 때 기준. 몸통·목·머리·뿔·다리 4개(걸음), 등의 이끼와 빛꽃, 역병 수정.
class StagVisual extends Node2D:
	const FUR := Color("#7a5e3e")
	const FUR_SH := Color("#4e3a26")
	const FUR_HI := Color("#a8845a")
	const BELLY := Color("#c8b088")
	const MOSS := Color("#4e8a36")
	const MOSS_HI := Color("#86c058")
	const ANTLER := Color("#d8c8a0")
	const BLIGHT := Color("#e8e8f2")
	const BLIGHT_SH := Color("#a8a8b8")
	var enemy: MossStag
	var _walk := 0.0

	func _process(delta: float) -> void:
		if enemy == null:
			return
		scale.x = enemy.facing
		_walk += absf(enemy.velocity.x) * delta * 0.12
		z_index = 1

	func _c(col: Color, white: float) -> Color:
		return col.lerp(Color.WHITE, white)

	func _draw() -> void:
		if enemy == null:
			return
		var t := enemy._t
		var st := enemy.state
		var k := enemy.state_k()
		var w := enemy.flash_amount() * 0.7
		var bl := enemy.blighted
		var pk := 0.0
		if st == MossStag.S.PURIFY or st == MossStag.S.LEAVE:
			pk = enemy.purify_k() if st == MossStag.S.PURIFY else 1.0
			bl = enemy.blighted and pk < 0.75
		var body_y := -17.0 + sin(t * 2.0) * 0.4
		var head_drop := 0.0 # +면 고개 숙임
		var rear := 0.0 # 앞발 들기 (휘두르기)
		var kneel := 0.0
		var red := 0.0
		var stride := 0.0
		match st:
			MossStag.S.GRAZE:
				head_drop = 9.0 if enemy._graze > 0.0 else 0.0
				stride = 1.0 if absf(enemy.velocity.x) > 4.0 else 0.0
			MossStag.S.ALERT:
				head_drop = -2.0
			MossStag.S.STALK:
				stride = 1.0 if absf(enemy.velocity.x) > 4.0 else 0.0
			MossStag.S.CHARGE_WINDUP:
				head_drop = 6.0 * k
				body_y += 1.5 * k
				red = k * (0.7 + 0.3 * sin(t * 30.0))
			MossStag.S.CHARGE:
				head_drop = 6.0
				stride = 2.0
				red = 0.4
			MossStag.S.STAGGER:
				head_drop = 3.0 + sin(t * 18.0) * 1.5
			MossStag.S.SWEEP_WINDUP:
				rear = 8.0 * k
				head_drop = -4.0 * k
				red = k * (0.7 + 0.3 * sin(t * 30.0))
			MossStag.S.SWEEP:
				rear = 8.0 * (1.0 - k)
				head_drop = 8.0 * k
			MossStag.S.PURIFY:
				kneel = clampf(pk * 3.0, 0.0, 1.0) * (1.0 - clampf((pk - 0.8) * 5.0, 0.0, 1.0))
				head_drop = 6.0 * kneel
			MossStag.S.LEAVE:
				stride = 2.0
		var ph := _walk
		# 몸통 기울기 (앞발 들기)
		var front := Vector2(9, body_y - rear)
		var back := Vector2(-10, body_y + kneel * 6.0)
		# 다리 4개 (뒤쪽 둘은 어둡게)
		for i in 4:
			var is_front := i >= 2
			var far := i % 2 == 0
			var hip := (front if is_front else back) + Vector2(-2 if far else 2, 4)
			var swing := sin(ph + (0.0 if is_front else PI) + (PI * 0.5 if far else 0.0)) * 3.0 * stride
			var foot := Vector2(hip.x + swing, 0)
			if is_front and rear > 0.0:
				foot = hip + Vector2(4, 8 - rear * 0.3)
			if kneel > 0.0:
				foot = Vector2(hip.x + (6 if is_front else -4) * kneel, -2 * kneel)
			var col := _c(FUR_SH if far else FUR, w)
			var knee := hip.lerp(foot, 0.5) + Vector2(-1.5 if is_front else 1.5, 0)
			draw_line(hip, knee, col, 2.5)
			draw_line(knee, foot, col, 2.0)
			draw_rect(Rect2(foot.x - 1.5, foot.y - 2, 3, 2), _c(Color("#2a2018"), w))
		# 몸통 (타원)
		var body := PackedVector2Array()
		for i in 16:
			var a := TAU * i / 16.0
			var base := back.lerp(front, 0.5 + cos(a) * 0.5)
			body.append(base + Vector2(cos(a) * 3.0, sin(a) * 7.0))
		draw_colored_polygon(body, _c(FUR, w))
		draw_colored_polygon(PackedVector2Array([back + Vector2(0, 2), front + Vector2(0, 2), front + Vector2(-1, 6), back + Vector2(1, 6)]), _c(BELLY, w))
		draw_line(back + Vector2(1, -6), front + Vector2(-1, -6), _c(FUR_HI, w), 1.0)
		# 짧은 꼬리 (흰 털)
		draw_colored_polygon(PackedVector2Array([back + Vector2(-2, -5), back + Vector2(-6, -7 + sin(t * 4.0)), back + Vector2(-3, -2)]), _c(Color("#f0e8d8"), w))
		# 등의 이끼와 빛꽃 (역병이면 흰 수정이 섞임)
		for i in 6:
			var mp := back.lerp(front, float(i) / 5.0) + Vector2(0, -7 - (i % 2))
			if bl and i % 2 == 0:
				_crystal(mp + Vector2(0, 1), 4.0 + (i % 3), w)
			else:
				draw_circle(mp, 2.5, _c(MOSS, w))
				draw_rect(Rect2(mp.x - 1, mp.y - 2.5, 2, 1), _c(MOSS_HI, w))
				if i % 2 == 1:
					var g := 0.6 + 0.4 * sin(t * 2.0 + i)
					draw_rect(Rect2(mp.x, mp.y - 4, 1, 1), Color(0.85, 1.0, 0.5, g))
		# 목과 머리
		var neck_top := front + Vector2(5, -10 + head_drop)
		draw_line(front + Vector2(1, -3), neck_top, _c(FUR, w), 5.0)
		draw_line(front + Vector2(2, -2), neck_top + Vector2(1, 2), _c(BELLY, w), 2.0)
		var hc := neck_top + Vector2(3, 0)
		draw_colored_polygon(PackedVector2Array([hc + Vector2(-4, -4), hc + Vector2(2, -4), hc + Vector2(9, 1), hc + Vector2(8, 4), hc + Vector2(-3, 4)]), _c(FUR, w))
		draw_line(hc + Vector2(-3, -4), hc + Vector2(3, -4), _c(FUR_HI, w), 1.0)
		draw_rect(Rect2(hc.x + 7, hc.y + 1, 2, 2), _c(Color("#2a2018"), w)) # 코
		draw_line(hc + Vector2(-2, 3), hc + Vector2(6, 3.5), _c(BELLY, w), 1.0)
		# 귀
		var ear_flick := sin(t * 9.0) * 1.5 if fmod(t, 4.0) < 0.3 else 0.0
		draw_colored_polygon(PackedVector2Array([hc + Vector2(-2, -2), hc + Vector2(-7, -5 + ear_flick), hc + Vector2(-2, 0)]), _c(FUR_SH, w))
		# 눈 (역병: 하얗게 빛남)
		if bl:
			draw_rect(Rect2(hc.x + 1, hc.y - 1.5, 2, 1.5), Color(1, 1, 1))
			draw_circle(hc + Vector2(2, -1), 3.0, Color(1, 1, 1, 0.25))
		else:
			draw_rect(Rect2(hc.x + 1, hc.y - 1.5, 1.5, 1.5), _c(Color("#1a1210"), w))
			draw_rect(Rect2(hc.x + 1, hc.y - 1.5, 1, 1), Color(1, 1, 1, 0.6))
		# 뿔 (가지처럼, 잎과 빛꽃 — 역병이면 흰 기하학 뿔)
		var ant_col := _c(BLIGHT if bl else ANTLER, w)
		if red > 0.0:
			ant_col = ant_col.lerp(Palette.DANGER, red)
		var ab := hc + Vector2(-1, -3)
		var tips := [Vector2(-4, -10), Vector2(2, -13), Vector2(7, -9)]
		for tp in tips:
			var tip: Vector2 = ab + (tp as Vector2)
			if bl:
				draw_line(ab, tip, ant_col, 1.5)
				draw_line(tip, tip + Vector2(0, -3), ant_col, 1.0)
			else:
				var mid := ab.lerp(tip, 0.5) + Vector2(-1, 0)
				draw_line(ab, mid, ant_col, 1.5)
				draw_line(mid, tip, ant_col, 1.0)
				draw_line(mid, mid + Vector2(-3, -2), ant_col, 1.0)
		if not bl:
			draw_colored_polygon(PackedVector2Array([ab + Vector2(2, -13), ab + Vector2(5, -15), ab + Vector2(3, -12)]), _c(MOSS_HI, w))
			var g2 := 0.6 + 0.4 * sin(t * 1.7)
			draw_rect(Rect2(ab.x - 4, ab.y - 11, 1, 1), Color(0.9, 1.0, 0.6, g2))
			draw_circle(ab + Vector2(-4, -11), 2.5, Color(0.9, 1.0, 0.6, 0.15 * g2))
		else:
			_crystal(ab + Vector2(2, -13), 4.0, w)
		if red > 0.0:
			draw_circle(ab + Vector2(2, -9), 7.0, Color(Palette.DANGER, 0.25 * red))
		# 몸통의 역병 수정
		if bl:
			_crystal(back + Vector2(4, 0), 5.0, w)
			_crystal(front + Vector2(-3, 3), 4.0, w)
		# 정화: 초록 빛 고리
		if st == MossStag.S.PURIFY:
			var rk := fmod(pk * 3.0, 1.0)
			draw_arc(Vector2(0, -14), 10.0 + rk * 16.0, 0, TAU, 20, Color(0.8, 1.0, 0.6, 0.5 * (1.0 - rk)), 1.0)

	func _crystal(c: Vector2, s: float, w: float) -> void:
		var col := BLIGHT.lerp(Color.WHITE, w)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.4, 0), c + Vector2(-s * 0.4, -s * 0.6), c + Vector2(0, -s), c + Vector2(s * 0.4, -s * 0.6), c + Vector2(s * 0.4, 0)]), col)
		draw_line(c, c + Vector2(0, -s), BLIGHT_SH, 1.0)
