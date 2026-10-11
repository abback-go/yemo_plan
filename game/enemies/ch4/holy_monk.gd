class_name HolyMonk
extends EnemyBase
## 성갑 수도사 (docs/archive/sera/chapter4.md 4절·7.4절): 대신전을 지키는 수도사. 금빛 두건 + 성갑, 앞에 육각형 빛의 방패, 해 머리 지팡이.
## 늘 낮게 기도문을 웅얼거린다(머리 위로 작은 해 문양이 떠오름).
## - 빛의 방패: 정면 화염탄을 막고 **세라에게 되돌려 보낸다**(금테 두른 붉은 불, 1 피해). 되돌아온 탄을 불꽃 방벽으로 다시 되쏘면
##   (Hit.kind = reflect) 방패가 깨져 2.5초 휘청(받는 피해 1.5배). 푸른 여우불도 방패를 깬다.
## - 불기둥(발밑)·폭주 폭발·유성·불사조·동료 공격은 방패를 무시한다. 화염 폭풍은 정면에서 30%만.
## - 등이 약점: 세라가 뒤로 가면 1초 동안 깨닫지 못하고(명상 중), 천천히 돌아선다(0.35초).
## 패턴: 지팡이 내려치기(예고 0.8초 — 지팡이가 붉게 → 바닥을 따라 양쪽으로 충격파, 점프로 넘음) → 1초 빈틈(방패가 내려감)
##        방패 밀치기(예고 0.5초 → 짧은 돌진)

enum S { IDLE, ADVANCE, TURN, SLAM_WINDUP, SLAM, SLAM_RECOVER, PUSH_WINDUP, PUSH, PUSH_RECOVER, STAGGER, PRAY }

const H := preload("res://enemies/ch4/holy.gd")
const VIS := preload("res://enemies/ch4/holy_monk_visual.gd")

const HP := 900
const WALK_T := 1.6
const KEEP_T := 3.5
const NOTICE_BEHIND := 1.0 ## 등 뒤로 간 세라를 알아차리기까지
const TURN_TIME := 0.35
const SLAM_WINDUP := 0.8
const SLAM_TIME := 0.15
const SLAM_RECOVER := 1.0
const WAVE_SPEED_T := 9.0
const WAVE_LIFE := 1.1
const PUSH_WINDUP := 0.5
const PUSH_TIME := 0.22
const PUSH_SPEED_T := 13.0
const PUSH_RECOVER := 0.5
const STAGGER_TIME := 2.5
const PRAY_TIME := 0.8
const SHIELD_FRONT := Vector2(13, -18) ## 방패 위치 (오른쪽을 볼 때)
const REFLECT_SPEED := 300.0
const BLOCK_KINDS := Hit.FIRE_BOLTS
const PIERCE_KINDS := Hit.PASS_SHIELD_MONK

var state: S = S.ADVANCE
var shield_hp := 1.0 ## 0이면 깨짐 (그림이 읽음)
var shield_flash := 0.0
var chant := 0.0 ## 웅얼거림 박자 (그림)
var _timer := 0.0
var _dur := 0.0
var _behind_t := 0.0
var _cd := 1.2
var _waves: Array = []
var _contact: EnemyAttackArea
var _push: EnemyAttackArea
var _glyph_t := 0.0


func _build() -> void:
	max_hp = HP
	body_size = Vector2(18, 34)
	cull_offscreen = false # 화면 밖 생략 안 함: 충격파를 그림 노드가 멀리까지 그림
	knock_mult = 0.4
	launch_mult = 0.5
	display_name = "성갑 수도사"
	subtitle = "빛은 되돌아온다"
	kind_id = "holy_monk"
	var v: Node2D = VIS.new()
	v.set("enemy", self)
	_visual = v
	add_child(v)
	_contact = add_attack_area(Vector2(16, 30), Vector2(0, -16), &"holy_monk")
	_contact.dodgeable = false
	_push = add_attack_area(Vector2(14, 30), Vector2(14, -16), &"holy_monk")
	_push.active = false


func progress() -> float:
	return clampf(1.0 - _timer / _dur, 0.0, 1.0) if _dur > 0.0 else 1.0


func shield_up() -> bool:
	return shield_hp > 0.0 and state in [S.IDLE, S.ADVANCE, S.TURN, S.PUSH_WINDUP, S.PUSH, S.PUSH_RECOVER, S.SLAM_WINDUP]


func _go(s: S, time := 0.0) -> void:
	state = s
	_timer = time
	_dur = time


func _ai(delta: float) -> void:
	var t := GameConst.TILE
	shield_flash = maxf(shield_flash - delta, 0.0)
	chant += delta
	_tick_waves(delta)
	var cs := _push.get_child(0) as CollisionShape2D
	cs.position = Vector2(14 * facing, -16)
	_hum(delta)
	var p := player()
	if not engaged or p == null or not p.is_alive():
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		return
	if state == S.IDLE:
		_go(S.ADVANCE)
	var dx := p.global_position.x - global_position.x
	var adx := absf(dx)
	var ahead := signf(dx) == float(facing) or adx < 4.0
	_timer -= delta
	match state:
		S.ADVANCE:
			_cd -= delta
			if not ahead:
				_behind_t += delta
				if _behind_t >= NOTICE_BEHIND:
					_behind_t = 0.0
					_go(S.TURN, TURN_TIME)
					H.snd(&"chain", &"chain", -10.0)
					return
			else:
				_behind_t = 0.0
			var want := 0.0
			if ahead and adx > KEEP_T * t and not ledge_ahead(12.0, 16.0):
				want = facing * WALK_T * t
			elif ahead and adx < 2.0 * t and not ledge_at(-facing, 12.0, 16.0):
				want = -facing * WALK_T * 0.6 * t
			velocity.x = move_toward(velocity.x, want, 400.0 * delta)
			if _cd <= 0.0 and ahead and absf(p.global_position.y - global_position.y) < 3.0 * t:
				if adx < 6.0 * t and randf() < 0.65:
					_go(S.SLAM_WINDUP, Difficulty.telegraph(SLAM_WINDUP))
					H.snd(&"spear", &"charger_windup", -4.0)
				elif adx < 7.0 * t:
					_go(S.PUSH_WINDUP, Difficulty.telegraph(PUSH_WINDUP))
					H.snd(&"spear", &"charger_windup", -6.0)
		S.TURN:
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			if _timer <= 0.0:
				facing = -facing
				_go(S.ADVANCE)
		S.SLAM_WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			if _timer <= 0.0:
				_do_slam()
		S.SLAM:
			velocity.x = 0.0
			if _timer <= 0.0:
				_go(S.SLAM_RECOVER, SLAM_RECOVER)
		S.SLAM_RECOVER, S.PUSH_RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if _timer <= 0.0:
				_cd = Difficulty.rest(randf_range(1.0, 1.6))
				_go(S.ADVANCE)
		S.PUSH_WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			if _timer <= 0.0:
				_go(S.PUSH, PUSH_TIME)
				_push.active = true
				H.snd(&"holy_hit", &"charger_charge", -4.0)
		S.PUSH:
			velocity.x = facing * PUSH_SPEED_T * t
			if _timer <= 0.0 or is_on_wall() or ledge_ahead(12.0, 16.0):
				_push.active = false
				velocity.x = facing * 2.0 * t
				_go(S.PUSH_RECOVER, PUSH_RECOVER)
		S.STAGGER:
			velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
			if _timer <= 0.0:
				_go(S.PRAY, PRAY_TIME)
				H.snd(&"reveal", &"reveal", -8.0)
		S.PRAY:
			velocity.x = 0.0
			if _timer <= 0.0:
				shield_hp = 1.0
				shield_flash = 0.25
				H.sparkle(global_position + Vector2(SHIELD_FRONT.x * facing, SHIELD_FRONT.y), 16, 8.0)
				Fx.ring(global_position + Vector2(SHIELD_FRONT.x * facing, SHIELD_FRONT.y), 14.0, 4.0, H.GOLD, 0.3, 2.0)
				_cd = 0.8
				_go(S.ADVANCE)


## 기도문 웅얼거림: 머리 위로 작은 해 문양이 떠오른다 (그림 대신 입자)
func _hum(delta: float) -> void:
	_glyph_t -= delta
	if _glyph_t > 0.0:
		return
	_glyph_t = randf_range(1.4, 2.2)
	if state in [S.ADVANCE, S.IDLE, S.PRAY]:
		Fx.burst(global_position + Vector2(-2 * facing, -38), 2, {
			direction = Vector2.UP, spread = 20.0, speed_min = 8.0, speed_max = 16.0, lifetime = 1.4,
			gradient = H.gold_grad(), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, -6), add = true,
		})


func _do_slam() -> void:
	_go(S.SLAM, SLAM_TIME)
	H.snd(&"holy_hit", &"slam", -2.0)
	Fx.shake(0.18, 0.2)
	var at := global_position + Vector2(facing * 12, 0)
	Fx.ring(at + Vector2(0, -3), 3.0, 26.0, H.GOLD, 0.25, 2.0)
	Fx.burst(at, 14, {
		direction = Vector2.UP, spread = 70.0, speed_min = 40.0, speed_max = 120.0, lifetime = 0.4,
		gradient = H.gold_grad(), size_min = 1.0, size_max = 2.5, gravity = Vector2(0, 300), add = true,
	})
	for dir in [-1, 1]:
		_spawn_wave(at, float(dir))


## 바닥을 따라 달리는 금빛 충격파 (점프로 넘는다)
func _spawn_wave(at: Vector2, dir: float) -> void:
	var a := EnemyAttackArea.with_rect(Vector2(12, 14), Vector2(0, -7))
	a.cause = &"holy_monk"
	a.damage = 1
	a.top_level = true
	a.global_position = at
	add_child(a)
	_waves.append({"area": a, "dir": dir, "t": 0.0})


func _tick_waves(delta: float) -> void:
	var space := get_world_2d().direct_space_state
	for w in _waves.duplicate():
		var a: EnemyAttackArea = w.area
		w.t = float(w.t) + delta
		var dir: float = w.dir
		var np := a.global_position + Vector2(dir * WAVE_SPEED_T * GameConst.TILE * delta, 0)
		# 벽에 닿거나 바닥이 끊기면 사라짐
		var wall := space.intersect_ray(PhysicsRayQueryParameters2D.create(a.global_position + Vector2(0, -6), np + Vector2(dir * 6, -6), GameConst.L_WORLD))
		var ground := space.intersect_ray(PhysicsRayQueryParameters2D.create(np + Vector2(0, -4), np + Vector2(0, 10), GameConst.L_WORLD | GameConst.L_PLATFORM))
		a.global_position = np
		if Engine.get_physics_frames() % 3 == 0:
			Fx.burst(np + Vector2(0, -2), 2, {
				direction = Vector2(-dir, -1), spread = 30.0, speed_min = 20.0, speed_max = 60.0, lifetime = 0.3,
				gradient = H.gold_grad(), size_min = 1.0, size_max = 2.5, gravity = Vector2(0, 200), add = true,
			})
		if float(w.t) >= WAVE_LIFE or not wall.is_empty() or ground.is_empty() or not _alive:
			a.queue_free()
			_waves.erase(w)


func wave_positions() -> Array:
	var out := []
	for w in _waves:
		var a: EnemyAttackArea = w.area
		out.append([a.global_position, float(w.t) / WAVE_LIFE, float(w.dir)])
	return out


func modify_damage(hit: Hit) -> float:
	var front := hit_side(hit, 6.0) > 0
	var mult := 1.5 if state == S.STAGGER else 1.0
	if hit.kind == &"reflect":
		if front and shield_up():
			_break_shield(true)
		return 1.0 * mult
	if EnemyBase.is_fox_hit(hit) and front and shield_up() and not (hit.kind in PIERCE_KINDS):
		_break_shield(false)
		return 1.0
	if hit.kind in PIERCE_KINDS or not front or not shield_up():
		return mult
	if hit.kind in BLOCK_KINDS:
		return 0.0
	if hit.kind == &"storm" or hit.kind == &"storm_final":
		return 0.3
	return 1.0


## 방패에 막힘: 화염탄이면 세라에게 되돌려 보낸다
func _on_blocked(hit: Hit) -> void:
	shield_flash = 0.15
	var at := global_position + Vector2(SHIELD_FRONT.x * facing, clampf(hit.source_pos.y - global_position.y, -30.0, -6.0))
	H.snd(&"reflect", &"block", -2.0, 0.08)
	Fx.ring(at, 3.0, 18.0, H.GOLD, 0.2, 2.0)
	H.sparkle(at, 8, 4.0, 20.0, 0.3)
	if hit.kind in BLOCK_KINDS:
		var p := player()
		var dir := Vector2(float(facing), 0.0)
		if p:
			dir = (p.center() - at).normalized()
			dir = Vector2(signf(dir.x) if dir.x != 0.0 else float(facing), clampf(dir.y, -0.35, 0.35)).normalized()
		# 화염탄의 충돌 처리 중이라 다음 프레임에 쏜다 (물리 질의 중엔 영역을 켤 수 없음)
		call_deferred("_send_back", at + dir * 6.0, dir)


func _send_back(at: Vector2, dir: Vector2) -> void:
	if not _alive:
		return
	var s := H.shoot(at, dir, REFLECT_SPEED, "reflect", {"damage": 1, "cause": "holy_monk_reflect", "radius": 4.0, "life": 2.0})
	s.dodgeable = true


func _break_shield(by_reflect: bool) -> void:
	shield_hp = 0.0
	_push.active = false
	_go(S.STAGGER, STAGGER_TIME)
	velocity.x = -facing * 3.0 * GameConst.TILE
	var at := global_position + Vector2(SHIELD_FRONT.x * facing, SHIELD_FRONT.y)
	H.snd(&"holy_hit", &"crumble", 0.0)
	Sfx.play(&"block", 0.0, 0.0)
	Fx.shake(0.18, 0.2)
	Fx.flash(Color(1.0, 0.9, 0.6, 0.15), 0.12)
	Fx.burst(at, 22, {
		direction = Vector2(-facing, -0.4), spread = 100.0, speed_min = 60.0, speed_max = 180.0, lifetime = 0.55,
		gradient = H.gold_grad(), size_min = 1.0, size_max = 3.0, gravity = Vector2(0, 260), add = true,
	})
	Fx.ring(at, 4.0, 34.0, H.WHITE, 0.3, 2.0)
	if by_reflect:
		StyleRank.bonus("되쏘기!", 10.0)


func _resists_knockback(hit: Hit) -> bool:
	return (state == S.PUSH or state == S.SLAM_WINDUP or state == S.SLAM) and not hit.breaks_charge


func _on_hit(hit: Hit, _dir: int) -> void:
	if state == S.ADVANCE and hit_side(hit, 6.0) < 0:
		_behind_t = maxf(_behind_t, NOTICE_BEHIND * 0.5) # 등을 맞으면 조금 빨리 돌아본다


func _die(dir: int) -> void:
	for w in _waves:
		var a: EnemyAttackArea = w.area
		a.queue_free()
	_waves.clear()
	H.sparkle(global_position + Vector2(0, -18), 24, 12.0, 30.0, 0.9)
	super(dir)
