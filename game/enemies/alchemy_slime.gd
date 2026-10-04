class_name AlchemySlime
extends EnemyBase
## 연금 슬라임 (docs/chapter1.md 7절, 12.4절, 12.5절): 연금술실에서 버려진 "실패한 과제물"이 봉인의 마력을 먹고 움직인다.
## - 통통 뛰기: 0.35초 웅크림 + 착지할 자리에 그림자 예고 → 짧은 뜀.
## - 크게 뛰어 내려찍기: 0.8초 깊게 웅크림(붉은 테두리, 붉은 그림자 예고) → 높이 뛰어 세라 자리에 쿵. 착지 뒤 1초 납작(빈틈).
## - 공략 포인트: 불에 맞을수록 달아오름(청록 → 노랑 → 주황). 세 번째 단계에서 부풀어 1.2초 뒤 자폭(반경 3.5T).
##   자폭은 세라·다른 적·금 간 벽(그룹 "cracked_wall"의 crack_break())까지 휘말린다. 여우불은 즉시 과열시킨다.
##   체력이 먼저 바닥나도 끓어 넘쳐 자폭한다. 자폭하면 처치로 친다.

enum S { IDLE, HOP_WIND, HOP, LAND, LEAP_WIND, LEAP, SLAM, SWELL }

const T := GameConst.TILE
const HOP_WIND_TIME := 0.35
const HOP_HEIGHT_T := 1.6
const HOP_DIST_T := 3.5
const LEAP_WIND_TIME := 0.8
const LEAP_LOCK_TIME := 0.25 ## 내려찍기 예고 마지막 이 시간 동안은 착지 지점이 고정됨 (피할 틈)
const LEAP_HEIGHT_T := 5.0
const LEAP_DIST_T := 10.0
const SLAM_REC_TIME := 1.0
const HEAT_STEP := 80.0 ## 불 피해량만큼 달아오르고, 이만큼마다 한 단계 (3단계 = 240)
const HEAT_COOL := 22.0 ## 불을 안 맞으면 초당 식는 양
const HEAT_COOL_DELAY := 1.4
const SWELL_TIME := 1.2
const SWELL_CREEP_T := 2.5 ## 부푼 채 세라 쪽으로 기어가는 속도 (T/s, 세라 11 T/s면 충분히 도망감)
const BLAST_RADIUS_T := 3.5
const BLAST_ENEMY_DAMAGE := 150
const WALL_SLACK_T := 1.0 ## 금 간 벽 노드 위치까지 거리 여유

var state: S = S.IDLE
var heat := 0.0
var land_x := 0.0 ## 착지 예정 x (전역) — 그림자 예고 위치
var ground_y := 0.0 ## 뛰기 시작한 바닥 높이 (그림자를 그릴 높이)
var _timer := 0.0
var _state_len := 1.0
var _air_t := 0.0
var _cool_wait := 0.0
var _hops := 0
var _exploded := false
var _wobble := 0.0 ## 맞거나 착지할 때 출렁임 (그림에서 사용)
var _steam_t := 0.0
var _body_area: EnemyAttackArea
var _slam_area: EnemyAttackArea


func _build() -> void:
	max_hp = 380
	body_size = Vector2(34, 24)
	cull_offscreen = false # 화면 밖 생략 안 함: 착지 표시가 몸에서 멀리 그려짐
	display_name = "연금 슬라임"
	subtitle = "실패한 과제물"
	kind_id = "alchemy_slime"
	knock_mult = 0.6
	launch_mult = 0.7
	_visual = AlchemySlimeVisual.new()
	_visual.enemy = self
	add_child(_visual)
	_body_area = add_attack_area(Vector2(body_size.x - 8, body_size.y - 6), Vector2(0, -body_size.y * 0.5 + 2), &"slime", 1)
	_body_area.dodgeable = false
	_slam_area = add_attack_area(Vector2(body_size.x + 4.0 * T, 14), Vector2(0, -7), &"slime", 1)
	_slam_area.active = false
	_timer = 0.8
	land_x = global_position.x


## 달아오름 단계 0~3
func heat_stage() -> int:
	return mini(int(heat / HEAT_STEP), 3)


## 0~1: 다음 단계까지가 아니라 전체 달아오름 정도 (색 변화용)
func heat_ratio() -> float:
	return clampf(heat / (HEAT_STEP * 3.0), 0.0, 1.0)


## 현재 상태의 진행도 0~1 (그림에서 사용)
func state_progress() -> float:
	return clampf(1.0 - _timer / maxf(_state_len, 0.001), 0.0, 1.0)


func wobble() -> float:
	return _wobble


func is_exploding() -> bool:
	return state == S.SWELL


func _set_state(s: S, time: float) -> void:
	state = s
	_timer = time
	_state_len = time


func _ai(delta: float) -> void:
	_wobble = maxf(_wobble - delta * 2.5, 0.0)
	_update_heat(delta)
	var p := player()
	match state:
		S.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			_timer -= delta
			if _timer <= 0.0 and is_on_floor():
				_choose(p)
		S.HOP_WIND:
			velocity.x = 0.0
			_timer -= delta
			if _timer <= 0.0:
				_launch(HOP_HEIGHT_T)
				_set_state(S.HOP, 1.0)
				Sfx.play(&"squish", -6.0, 0.15)
		S.HOP, S.LEAP:
			_air_t += delta
			if _air_t > 0.08 and is_on_floor():
				_land(state == S.LEAP)
		S.LEAP_WIND:
			velocity.x = 0.0
			_timer -= delta
			if p and _timer > LEAP_LOCK_TIME:
				face_player()
				land_x = _clamp_target(p.global_position.x, LEAP_DIST_T)
			if _timer <= 0.0:
				_launch(LEAP_HEIGHT_T)
				_set_state(S.LEAP, 1.5)
				Sfx.play(&"jump", -2.0, 0.0)
				Sfx.play(&"squish", -2.0, 0.0)
		S.LAND, S.SLAM:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			_timer -= delta
			if state == S.SLAM and _timer < _state_len - 0.15:
				_slam_area.active = false
			if _timer <= 0.0:
				_slam_area.active = false
				_set_state(S.IDLE, randf_range(0.35, 0.6))
		S.SWELL:
			_timer -= delta
			_body_area.dodgeable = false
			if is_on_floor() and p and _timer > 0.3:
				velocity.x = move_toward(velocity.x, dir_to_player() * SWELL_CREEP_T * T, 300.0 * delta)
			else:
				velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if _timer <= 0.0:
				_explode()


func _choose(p: Player) -> void:
	if p == null or not p.is_alive():
		_timer = 0.5
		return
	var dx := absf(p.global_position.x - global_position.x)
	var dy := absf(p.global_position.y - global_position.y)
	if dx > 15.0 * T or dy > 8.0 * T:
		_timer = 0.5 # 너무 멀면 제자리에서 출렁이며 기다림
		return
	face_player()
	ground_y = global_position.y
	if _hops >= 2 and dx > 2.5 * T and dx < LEAP_DIST_T * T:
		_hops = 0
		_set_state(S.LEAP_WIND, LEAP_WIND_TIME)
		land_x = _clamp_target(p.global_position.x, LEAP_DIST_T)
		Sfx.play(&"charger_windup", -4.0, 0.0)
	else:
		_hops += 1
		_set_state(S.HOP_WIND, HOP_WIND_TIME)
		land_x = _clamp_target(p.global_position.x, HOP_DIST_T)


## 목표 x를 최대 거리 안으로 (벽 너머로 뛰지 않게 바닥 끝·벽은 move_and_slide가 막아 줌)
func _clamp_target(x: float, max_t: float) -> float:
	return clampf(x, global_position.x - max_t * T, global_position.x + max_t * T)


func _launch(height_t: float) -> void:
	var vy := sqrt(2.0 * _gravity * height_t * T)
	var flight := 2.0 * vy / _gravity
	velocity.y = -vy
	velocity.x = (land_x - global_position.x) / flight
	_air_t = 0.0
	_body_area.dodgeable = true


func _land(big: bool) -> void:
	_body_area.dodgeable = false
	velocity.x = 0.0
	_wobble = 1.0
	if big:
		_set_state(S.SLAM, SLAM_REC_TIME)
		_slam_area.active = true
		Sfx.play(&"slam", 0.0, 0.05)
		Sfx.play(&"squish", 0.0, 0.1)
		Fx.shake(0.3, 0.25)
		Fx.ring(global_position + Vector2(0, -2), 6.0, 2.6 * T, _goo_color(), 0.3, 2.0)
		Fx.burst(global_position + Vector2(0, -4), 14, {
			direction = Vector2.UP, spread = 75.0, speed_min = 60.0, speed_max = 160.0, lifetime = 0.5,
			gradient = Palette.fade_gradient(_goo_color()), size_min = 1.5, size_max = 3.0, gravity = Vector2(0, 420),
		})
	else:
		_set_state(S.LAND, 0.25)
		Sfx.play(&"squish", -5.0, 0.15)
		Fx.burst(global_position + Vector2(0, -2), 5, {
			direction = Vector2.UP, spread = 70.0, speed_min = 30.0, speed_max = 70.0, lifetime = 0.3,
			gradient = Palette.fade_gradient(_goo_color()), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 300),
		})


func _on_landed_from_launch() -> void:
	super._on_landed_from_launch()
	if state == S.HOP or state == S.LEAP:
		_land(false)


func _update_heat(delta: float) -> void:
	if state == S.SWELL:
		return
	if _cool_wait > 0.0:
		_cool_wait -= delta
	elif heat > 0.0:
		heat = maxf(heat - HEAT_COOL * delta, 0.0)
	# 달아오른 만큼 김이 피어오름
	if heat_stage() >= 1:
		_steam_t -= delta
		if _steam_t <= 0.0:
			_steam_t = 0.45 - 0.12 * heat_stage()
			Fx.burst(global_position + Vector2(randf_range(-8, 8), -body_size.y), 2, {
				direction = Vector2.UP, spread = 20.0, speed_min = 15.0, speed_max = 35.0, lifetime = 0.6,
				gradient = Palette.fade_gradient(Color(1.0, 0.85, 0.7, 0.5)), size_min = 1.5, size_max = 3.0,
				gravity = Vector2(0, -20), add = false,
			})


func _on_hit(hit: Hit, _dir: int) -> void:
	_wobble = 1.0
	if state == S.SWELL or _exploded:
		return
	var before := heat_stage()
	if EnemyBase.is_fox_hit(hit):
		heat = HEAT_STEP * 3.0 # 푸른 여우불은 즉시 과열
	else:
		heat += float(hit.damage)
	_cool_wait = HEAT_COOL_DELAY
	var after := heat_stage()
	if after >= 3:
		_start_swell()
	elif after > before:
		Sfx.play(&"ignite", -3.0, 0.05)
		Fx.burst(global_position + Vector2(0, -body_size.y * 0.6), 8, {
			spread = 180.0, speed_min = 30.0, speed_max = 80.0, lifetime = 0.35, size_min = 1.0, size_max = 2.0,
			gravity = Vector2(0, -60),
		})


func _start_swell() -> void:
	heat = HEAT_STEP * 3.0
	_slam_area.active = false
	_body_area.dodgeable = false
	_set_state(S.SWELL, SWELL_TIME)
	_wobble = 1.0
	Sfx.play(&"overheat", 0.0, 0.0)
	Sfx.play(&"overload_warn", -4.0, 0.0)
	Fx.ring(global_position + Vector2(0, -body_size.y * 0.5), 4.0, BLAST_RADIUS_T * T, Color(Palette.DANGER, 0.6), 0.5, 1.0)


## 체력이 바닥나도 바로 죽지 않고 끓어 넘쳐 자폭한다
func _die(dir: int) -> void:
	if not _exploded:
		hp = maxi(hp, 1)
		if state != S.SWELL:
			_start_swell()
		return
	super._die(dir)


func _explode() -> void:
	if _exploded:
		return
	_exploded = true
	var c := global_position + Vector2(0, -body_size.y * 0.5)
	var r := BLAST_RADIUS_T * T
	# 세라: 둥근 공격 영역을 잠깐 띄운다 (대시 무적으로 스치면 퍼펙트 회피)
	var blast := EnemyAttackArea.new()
	blast.cause = &"slime"
	blast.damage = 1
	blast.dodgeable = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = r
	shape.shape = circle
	blast.add_child(shape)
	Fx.effect_parent().add_child(blast)
	blast.global_position = c
	get_tree().create_timer(0.2).timeout.connect(blast.queue_free)
	# 다른 적도 휘말림 (다른 슬라임은 연쇄 과열)
	for n in get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
		var e := n as EnemyBase
		if e == null or e == self or not e.is_alive():
			continue
		var ec := e.global_position + Vector2(0, -e.body_size.y * 0.5)
		if ec.distance_to(c) <= r + e.body_size.x * 0.5:
			var h := Hit.make(BLAST_ENEMY_DAMAGE, &"blast", c)
			h.knockback_t = 2.0
			h.launch_t = 1.2
			h.hitstop = 0.05
			h.shake_t = 0.2
			e.take_hit(h)
	# 금 간 벽 (비밀 깃털 — docs/chapter1.md 12.5절, 12.6절)
	for n in get_tree().get_nodes_in_group(&"cracked_wall"):
		var w := n as Node2D
		if w and w.has_method("crack_break") and w.global_position.distance_to(c) <= r + WALL_SLACK_T * T:
			w.call("crack_break")
	# 연출
	Sfx.play(&"explode", 3.0, 0.0)
	Sfx.play(&"squish", 0.0, 0.0)
	Fx.shake(0.55, 0.35)
	Fx.flash(Color(1.0, 0.6, 0.25, 0.3), 0.14)
	Fx.zoom_punch(0.04)
	Fx.ring(c, 6.0, r, Palette.FIRE_OUT, 0.32, 3.0)
	Fx.ring(c, 4.0, r * 0.75, Color(0.5, 1.0, 0.85), 0.4, 2.0)
	Fx.burst(c, 40, {
		spread = 180.0, speed_min = 60.0, speed_max = r * 4.5, damping = r * 3.0, lifetime = 0.5,
		size_min = 1.5, size_max = 4.0, gravity = Vector2(0, -40),
	})
	Fx.burst(c, 22, {
		spread = 180.0, speed_min = 60.0, speed_max = 220.0, lifetime = 0.7,
		gradient = Palette.fade_gradient(Color(0.4, 0.95, 0.8)), size_min = 1.5, size_max = 3.0, gravity = Vector2(0, 500),
	})
	Fx.burst(c, 8, {
		spread = 180.0, speed_min = 80.0, speed_max = 200.0, lifetime = 0.5,
		gradient = Palette.fade_gradient(Color(0.9, 0.97, 1.0)), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 600),
	}) # 플라스크 유리 조각
	hp = 0
	_die(dir_to_player())


## 지금 몸 색 (그림·파티클 공용): 청록 → 노랑 → 주황 → 붉은 주황
func _goo_color() -> Color:
	return AlchemySlimeVisual.goo_color(heat_ratio())
