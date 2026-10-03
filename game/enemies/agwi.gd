class_name Agwi
extends EnemyBase
## 아귀(餓鬼) — 1장 보스 (docs/chapter1.md 1절, 7절, 12.4절, 12.5절): 학교 지하 봉인의 방에 묶인 "봉인된 굶주림".
## 키 약 9T, 굽은 등, 아주 긴 팔, 희미하게 빛나는 큰 입. 대본이 engaged = true로 바꿀 때까지 기다린다.
##
## 1페이즈 (보랏빛 봉인 사슬에 묶여 조금만 움직임)
## - 긴 팔 휩쓸기: 높게(푸른 예고, 팔을 머리 위로 → 땅에 붙어 있으면 안전) / 낮게(붉은 예고, 팔을 바닥에 끌며 → 점프).
## - 흡입: 고개를 숙이고 입을 벌려 세라를 8 T/s로 끌어당기고 폭주 게이지를 빨아들임. 이때 입이 약점(1.5배).
## - 검은 불덩이 3발: 느린 포물선.
## 체력 50%: phase_changed(2) → 사슬을 끊는 연출(무적) → 2페이즈 (자유롭게 걷고 뜀)
## - 그림자 손 3연속(세라 자리에 0.6초 검은 원 예고), 도약 내려찍기(+양옆 충격파), 탐식 잡기(긴 예고 → 빠른 돌진, 맞으면 1 피해).
## - 흡입·휩쓸기도 계속 쓰고, 휩쓸기는 높게↔낮게 연속으로 이어지기도 한다.
## 체력 25%: enraged (패턴 간격·예고가 조금 빨라짐).
## 공통: 몸은 질겨서 피해 80%. 내려찍기 착지 뒤·탐식 헛손질 뒤는 빈틈(100%). 푸른 여우불에 맞으면 움찔(0.4초, 2초에 한 번).
## 죽으면 터지지 않고 무너져 보랏빛 연기로 흩어진 뒤(1.6초) 처치 처리.

enum S {
	DORMANT, IDLE,
	SWEEP_WIND, SWEEP, SWEEP_REC,
	INHALE_WIND, INHALE, INHALE_REC,
	SPIT_WIND, SPIT, SPIT_REC,
	CHAIN_BREAK,
	HANDS_WIND, HANDS, HANDS_REC,
	LEAP_WIND, LEAP, LEAP_REC,
	GRAB_WIND, GRAB, GRAB_MISS, GRAB_EAT,
	FLINCH, DYING,
}

const T := GameConst.TILE
## 입 위치 (오른쪽을 볼 때, 발밑 원점): 평소 / 흡입 때 고개를 숙였을 때
const MOUTH_REST := Vector2(54, -112)
const MOUTH_LOW := Vector2(62, -38)
const BODY_MULT := 0.8 ## 플레이 피드백으로 하향 (0.5 → 0.8)
const OPEN_MULT := 1.0
const MOUTH_MULT := 1.5
const MOUTH_WEAK_RADIUS := 3.0 * 16.0

const SWEEP_WIND_TIME := 1.1
const SWEEP_COMBO_WIND := 0.8
const SWEEP_TIME := 0.7
const SWEEP_REC_TIME := 0.7
const SWEEP_REACH_T := 19.0
const SWEEP_HIGH_Y := -54.0 ## 높게: 바닥 위 36~72px (서 있는 세라 머리 위 27px보다 높음)
const SWEEP_HIGH_H := 36.0
const SWEEP_LOW_Y := -12.0 ## 낮게: 바닥 위 0~24px
const SWEEP_LOW_H := 24.0

const INHALE_WIND_TIME := 1.0
const INHALE_TIME := 3.0
const INHALE_REC_TIME := 1.2
const INHALE_PULL_T := 6.0
const INHALE_DRAIN := 15.0
const INHALE_COOLDOWN := 9.0
const INHALE_RANGE_T := 22.0 ## 이보다 멀면 끌려가지 않음 (투기장 절반 폭)

const SPIT_WIND_TIME := 0.8
const SPIT_INTERVAL := 0.24
const SPIT_REC_TIME := 0.8
const FIREBALL_FLIGHT := 1.15
const FIREBALL_GRAVITY := 380.0
const SPIT_RANGE_T := 20.0 ## 불덩이가 노리는 최대 거리

const CHAIN_BREAK_TIME := 3.2
const CHAIN_SNAP_AT := 1.7 ## 연출 시작 뒤 사슬이 끊기는 시각

const HANDS_WIND_TIME := 0.65
const HAND_WARN := 0.8
const HAND_UP := 0.35
const HAND_DOWN := 0.3
const HAND_GAP := 0.55
const HANDS_REC_TIME := 0.8

const LEAP_WIND_TIME := 1.0
const LEAP_LOCK := 0.25
const LEAP_HEIGHT_T := 4.5
const LEAP_MAX_T := 15.0
const LEAP_REC_TIME := 1.1
const WAVE_SPEED_T := 13.0
const WAVE_TIME := 0.75

const GRAB_WIND_TIME := 1.1
const GRAB_SPEED_T := 26.0
const GRAB_MAX_TIME := 0.42
const GRAB_MISS_TIME := 1.4
const GRAB_EAT_TIME := 1.1

const FLINCH_TIME := 0.4
const FLINCH_COOLDOWN := 2.0
const DYING_TIME := 1.6


## 바닥에서 솟는 그림자 손 하나
class ShadowHand:
	extends RefCounted
	var x := 0.0
	var y := 0.0
	var t := 0.0
	var area: EnemyAttackArea
	var erupted := false

	func done() -> bool:
		return t >= Agwi.HAND_WARN + Agwi.HAND_UP + Agwi.HAND_DOWN


## 내려찍기 뒤 바닥을 달리는 충격파
class ShockWave:
	extends RefCounted
	var x := 0.0
	var y := 0.0
	var dir := 1.0
	var t := 0.0
	var area: EnemyAttackArea


var state: S = S.DORMANT
var phase := 1
var sweep_high := false
var sweep_hand := Vector2.ZERO ## 휩쓰는 손 (전역)
var sweep_from_x := 0.0
var sweep_to_x := 0.0
var mouth_open := 0.1 ## 0~1 (그림)
var head_low := 0.0 ## 0~1 흡입 때 고개 숙임, 음수면 고개를 쳐듦
var chains_intact := true
var anchor_x := 0.0 ## 사슬 말뚝 중심 (전역 x)
var floor_y := 0.0 ## 바닥 높이 (전역 y)
var anchored := false
var leap_x := 0.0
var hands: Array[ShadowHand] = []
var waves: Array[ShockWave] = []
## 시험용: 비어 있지 않으면 이 순서대로 패턴을 고른다 (sweep_high, sweep_low, inhale, spit, hands, leap, grab)
var pattern_queue: Array = []

var _timer := 0.0
var _state_len := 1.0
var _air_t := 0.0
var _inhale_cd := 3.0
var _flinch_cd := 0.0
var _last := ""
var _spit_left := 0
var _spit_t := 0.0
var _hands_spawned := 0
var _hand_t := 0.0
var _grab_hit := false
var _phase_pending := false
var _is_enraged := false
var _snapped := false
var _dying := false
var _dying_done := false
var _die_dir := 1
var _sweep_combo := 0
var _fx_t := 0.0
var _step_t := 0.0
var _slam_t := 0.0
var _queue_i := 0
var _mouth_box_on := false

var _contact: EnemyAttackArea
var _arm_high: EnemyAttackArea
var _arm_low: EnemyAttackArea
var _mouth: EnemyAttackArea
var _slam: EnemyAttackArea
var _grab: EnemyAttackArea
var _hand_pool: Array[EnemyAttackArea] = []
var _wave_pool: Array[EnemyAttackArea] = []


func _build() -> void:
	max_hp = 3000 # 6000 → 3000 (플레이 피드백 "너무 어렵다")
	body_size = Vector2(72, 132)
	display_name = "아귀"
	subtitle = "봉인된 굶주림"
	kind_id = "agwi"
	is_boss = true
	knock_mult = 0.0
	launch_mult = 0.0
	engaged = false
	_visual = AgwiVisual.new()
	_visual.enemy = self
	add_child(_visual)
	_contact = add_attack_area(Vector2(40, 84), Vector2(0, -42), &"agwi", 1)
	_contact.dodgeable = false
	_contact.active = false
	_arm_high = add_attack_area(Vector2(40, SWEEP_HIGH_H), Vector2.ZERO, &"agwi", 1)
	_arm_low = add_attack_area(Vector2(40, SWEEP_LOW_H), Vector2.ZERO, &"agwi", 1)
	_mouth = add_attack_area(Vector2(34, 44), Vector2.ZERO, &"agwi", 1)
	_mouth.dodgeable = false
	_mouth.hit_player.connect(_on_mouth_bite)
	_slam = add_attack_area(Vector2(6.0 * T, 1.6 * T), Vector2(0, -0.8 * T), &"agwi", 1)
	_grab = add_attack_area(Vector2(3.0 * T, 5.0 * T), Vector2.ZERO, &"agwi", 1)
	_grab.hit_player.connect(func(_p: Node) -> void: _grab_hit = true)
	for i in 3:
		_hand_pool.append(add_attack_area(Vector2(22, 44), Vector2.ZERO, &"agwi", 1))
	for i in 2:
		_wave_pool.append(add_attack_area(Vector2(14, 16), Vector2.ZERO, &"agwi", 1))
	_clear_attacks()
	for a in _hand_pool:
		a.active = false
	for a in _wave_pool:
		a.active = false


# ─── 그림·대본용 ────────────────────────────────────────

func state_progress() -> float:
	return clampf(1.0 - _timer / maxf(_state_len, 0.001), 0.0, 1.0)


func state_elapsed() -> float:
	return _state_len - _timer


func is_enraged() -> bool:
	return _is_enraged


func is_dying() -> bool:
	return _dying


## 입 위치 (전역)
func mouth_global() -> Vector2:
	var m := MOUTH_REST.lerp(MOUTH_LOW, clampf(head_low, 0.0, 1.0))
	if head_low < 0.0:
		m += Vector2(-6.0, -10.0) * -head_low
	return global_position + Vector2(m.x * facing, m.y)


## 입이 약점으로 열려 있는가 (흡입 중)
func mouth_weak() -> bool:
	return state == S.INHALE or (state == S.INHALE_REC and state_elapsed() < 0.4)


## 사슬 말뚝 위치들 (전역): 목 사슬 2개(양옆 멀리), 허리 사슬 1개(발밑 가운데)
func chain_anchors() -> Array[Vector2]:
	var arr: Array[Vector2] = [
		Vector2(anchor_x - 7.0 * T, floor_y), Vector2(anchor_x + 7.0 * T, floor_y), Vector2(anchor_x, floor_y),
	]
	return arr


## 공격 사이 쉬는 시간 배율 (하향 조정으로 1.3배 여유)
func _cadence() -> float:
	return (0.7 if _is_enraged else 1.0) * 1.3


func _set_state(s: S, time: float) -> void:
	state = s
	_timer = time
	_state_len = time


# ─── 매 프레임 ──────────────────────────────────────────

func _ai(delta: float) -> void:
	if not anchored:
		anchored = true
		anchor_x = global_position.x
		floor_y = global_position.y
	_tick_hands(delta)
	_tick_waves(delta)
	_update_pose(delta)
	_flinch_cd -= delta
	_inhale_cd -= delta
	if _slam_t > 0.0:
		_slam_t -= delta
		if _slam_t <= 0.0:
			_slam.active = false
	if _dying:
		_ai_dying(delta)
		return
	if not engaged:
		state = S.DORMANT
		velocity.x = 0.0
		_contact.active = false
		return
	if state == S.DORMANT:
		_contact.active = true
		Sfx.play(&"growl", -2.0, 0.0)
		_to_idle(1.2)
	if _phase_pending and state != S.CHAIN_BREAK:
		_start_chain_break()
	var p := player()
	match state:
		S.IDLE:
			_ai_idle(delta, p)
		S.SWEEP_WIND:
			velocity.x = 0.0
			_timer -= delta
			sweep_hand = _sweep_rest_hand()
			if _timer <= 0.0:
				_set_state(S.SWEEP, SWEEP_TIME)
				(_arm_high if sweep_high else _arm_low).active = true
				Sfx.play(&"swing", 2.0, 0.0)
				Sfx.play_pitch(&"whoosh", 1.3 if sweep_high else 0.7, 0.0)
		S.SWEEP:
			_timer -= delta
			var k := state_progress()
			var e := k * k * (3.0 - 2.0 * k)
			sweep_hand = Vector2(lerpf(sweep_from_x, sweep_to_x, e), floor_y + (SWEEP_HIGH_Y if sweep_high else SWEEP_LOW_Y))
			var arm := _arm_high if sweep_high else _arm_low
			arm.global_position = sweep_hand
			_fx_t -= delta
			if not sweep_high and _fx_t <= 0.0:
				_fx_t = 0.05
				Fx.burst(Vector2(sweep_hand.x, floor_y - 2.0), 3, {
					direction = Vector2(-facing, -1.0), spread = 30.0, speed_min = 40.0, speed_max = 110.0,
					lifetime = 0.3, size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 300),
				})
			if _timer <= 0.0:
				_arm_high.active = false
				_arm_low.active = false
				_set_state(S.SWEEP_REC, SWEEP_REC_TIME)
				Sfx.play(&"slam", -4.0, 0.1)
				Fx.shake(0.25, 0.2)
		S.SWEEP_REC:
			_timer -= delta
			var k2 := state_progress()
			var rest := _sweep_rest_hand()
			sweep_hand = Vector2(lerpf(sweep_to_x, rest.x, k2 * k2), lerpf(sweep_hand.y, rest.y, k2))
			if _timer <= 0.0:
				if _sweep_combo > 0:
					_sweep_combo -= 1
					_start_sweep(not sweep_high, SWEEP_COMBO_WIND)
				else:
					_to_idle(0.9)
		S.INHALE_WIND:
			velocity.x = 0.0
			_timer -= delta
			if _timer <= 0.0:
				_set_state(S.INHALE, INHALE_TIME + (0.5 if _is_enraged else 0.0))
				_mouth.global_position = mouth_global()
				_mouth.active = true
				_set_mouth_hurtbox(true)
				Sfx.play_pitch(&"storm", 0.5, 0.0)
		S.INHALE:
			velocity.x = 0.0
			_timer -= delta
			_mouth.global_position = mouth_global()
			_inhale_pull(delta, p)
			if _timer <= 0.0:
				_end_inhale()
		S.INHALE_REC:
			_timer -= delta
			if state_elapsed() > 0.4:
				_set_mouth_hurtbox(false)
			if _timer <= 0.0:
				_set_mouth_hurtbox(false)
				_to_idle(0.8)
		S.SPIT_WIND:
			velocity.x = 0.0
			_timer -= delta
			if p and _timer > 0.2:
				face_player()
			if _timer <= 0.0:
				_set_state(S.SPIT, 3.0)
				_spit_left = 3
				_spit_t = 0.0
		S.SPIT:
			_spit_t -= delta
			if _spit_left > 0 and _spit_t <= 0.0:
				_fire_dark(p, 3 - _spit_left)
				_spit_left -= 1
				_spit_t = SPIT_INTERVAL
			elif _spit_left == 0 and _spit_t <= 0.0:
				_set_state(S.SPIT_REC, SPIT_REC_TIME)
		S.SPIT_REC:
			_timer -= delta
			if _timer <= 0.0:
				_to_idle(0.8)
		S.CHAIN_BREAK:
			_ai_chain_break(delta, p)
		S.HANDS_WIND:
			velocity.x = 0.0
			_timer -= delta
			if _timer <= 0.0:
				_set_state(S.HANDS, 4.0)
				_hands_spawned = 0
				_hand_t = 0.0
				Sfx.play(&"slam", 0.0, 0.0)
				Fx.shake(0.3, 0.2)
		S.HANDS:
			_timer -= delta
			_hand_t -= delta
			if _hands_spawned < 3 and _hand_t <= 0.0 and p:
				_spawn_hand(p, _hands_spawned)
				_hands_spawned += 1
				_hand_t = HAND_GAP * (0.8 if _is_enraged else 1.0)
			if _hands_spawned >= 3 and hands.is_empty():
				_set_state(S.HANDS_REC, HANDS_REC_TIME)
		S.HANDS_REC:
			_timer -= delta
			if _timer <= 0.0:
				_to_idle(0.7)
		S.LEAP_WIND:
			velocity.x = 0.0
			_timer -= delta
			if p and _timer > LEAP_LOCK:
				face_player()
				leap_x = clampf(p.global_position.x, global_position.x - LEAP_MAX_T * T, global_position.x + LEAP_MAX_T * T)
			if _timer <= 0.0:
				var vy := sqrt(2.0 * _gravity * LEAP_HEIGHT_T * T)
				var flight := 2.0 * vy / _gravity
				velocity = Vector2((leap_x - global_position.x) / flight, -vy)
				_air_t = 0.0
				_contact.dodgeable = true
				_set_state(S.LEAP, 3.0)
				Sfx.play_pitch(&"jump", 0.5, 2.0)
				Sfx.play(&"whoosh", 0.0, 0.0)
		S.LEAP:
			_air_t += delta
			if _air_t > 0.1 and is_on_floor():
				_land_slam()
		S.LEAP_REC:
			velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)
			_timer -= delta
			if _timer <= 0.0:
				_to_idle(0.6)
		S.GRAB_WIND:
			velocity.x = 0.0
			_timer -= delta
			if p and _timer > 0.2:
				face_player()
			if _timer <= 0.0:
				_set_state(S.GRAB, GRAB_MAX_TIME)
				_grab.position = Vector2(facing * 2.2 * T, -2.6 * T)
				_grab.active = true
				_grab_hit = false
				_contact.dodgeable = true
				Sfx.play(&"dash", 2.0, 0.0)
				Sfx.play_pitch(&"whoosh", 0.8, 2.0)
		S.GRAB:
			_timer -= delta
			velocity.x = facing * GRAB_SPEED_T * T
			_grab.position = Vector2(facing * 2.2 * T, -2.6 * T)
			if _grab_hit:
				_grab.active = false
				_contact.dodgeable = false
				velocity.x = 0.0
				_set_state(S.GRAB_EAT, GRAB_EAT_TIME)
				Sfx.play(&"squish", 2.0, 0.0)
				Sfx.play_pitch(&"growl", 0.8, 0.0)
			elif _timer <= 0.0 or (is_on_wall() and state_elapsed() > 0.05):
				_grab.active = false
				_contact.dodgeable = false
				_set_state(S.GRAB_MISS, GRAB_MISS_TIME)
				Sfx.play(&"slam", 0.0, 0.0)
				Fx.shake(0.4, 0.25)
				Fx.burst(global_position + Vector2(facing * 3.0 * T, -4), 14, {
					direction = Vector2.UP, spread = 70.0, speed_min = 40.0, speed_max = 120.0, lifetime = 0.5,
					gradient = Palette.fade_gradient(Palette.GROUND_TOP), size_min = 1.5, size_max = 3.0, gravity = Vector2(0, 250),
				})
		S.GRAB_EAT:
			velocity.x = 0.0
			_timer -= delta
			_fx_t -= delta
			if _fx_t <= 0.0:
				_fx_t = 0.3
				Sfx.play(&"squish", -2.0, 0.2)
			if _timer <= 0.0:
				_to_idle(0.5)
		S.GRAB_MISS:
			velocity.x = move_toward(velocity.x, 0.0, 2400.0 * delta)
			_timer -= delta
			if _timer <= 0.0:
				_to_idle(0.5)
		S.FLINCH:
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
			_timer -= delta
			if _timer <= 0.0:
				_to_idle(0.5)


## 입 벌림·고개 숙임을 상태에 맞춰 부드럽게 (입 위치가 공격 판정에도 쓰임)
func _update_pose(delta: float) -> void:
	var want_low := 0.0
	var want_open := 0.12 + 0.05 * sin(_t * 2.0)
	match state:
		S.INHALE_WIND:
			want_low = 1.0
			want_open = state_progress()
		S.INHALE:
			want_low = 1.0
			want_open = 1.0
		S.INHALE_REC:
			want_low = 1.0 if state_elapsed() < 0.4 else 0.0
			want_open = 0.3
		S.SPIT_WIND:
			want_low = -0.6
			want_open = 0.55
		S.SPIT:
			want_low = -0.4
			want_open = 0.85
		S.CHAIN_BREAK:
			want_low = -0.8 if _snapped else -0.3
			want_open = 1.0 if _snapped else 0.25
		S.HANDS_WIND, S.HANDS:
			want_low = 0.45
			want_open = 0.4
		S.GRAB_WIND:
			want_low = -0.5
			want_open = 0.9
		S.GRAB:
			want_low = 0.3
			want_open = 1.0
		S.GRAB_EAT:
			want_low = 0.1
			want_open = absf(sin(_t * 12.0)) * 0.7
		S.GRAB_MISS:
			want_low = 0.9
			want_open = 0.5
		S.LEAP_REC:
			want_low = 0.35
			want_open = 0.4
		S.FLINCH:
			want_low = -0.4
			want_open = 0.35
		S.DYING:
			want_low = 0.8
			want_open = 0.6
	head_low = move_toward(head_low, want_low, delta * 3.5)
	mouth_open = move_toward(mouth_open, want_open, delta * 6.0)


func _ai_idle(delta: float, p: Player) -> void:
	_timer -= delta
	if p == null or not p.is_alive():
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		return
	face_player()
	if phase == 1:
		# 사슬에 묶여 말뚝 중심에서 2.5T까지만 다가옴
		var want_x := clampf(p.global_position.x, anchor_x - 2.5 * T, anchor_x + 2.5 * T)
		var dx := want_x - global_position.x
		velocity.x = signf(dx) * 1.2 * T if absf(dx) > 4.0 else 0.0
	else:
		var dist := absf(p.global_position.x - global_position.x)
		if dist > 8.0 * T:
			velocity.x = facing * 3.2 * T
			_step_t -= delta
			if _step_t <= 0.0:
				_step_t = 0.5
				Sfx.play_pitch(&"land", 0.5, -2.0)
				Fx.shake(0.08, 0.1)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
	if _timer <= 0.0:
		_choose(p)


func _to_idle(wait: float) -> void:
	_clear_attacks()
	_set_mouth_hurtbox(false)
	_set_state(S.IDLE, wait * _cadence())


func _clear_attacks() -> void:
	_arm_high.active = false
	_arm_low.active = false
	_mouth.active = false
	_grab.active = false
	_contact.dodgeable = false


# ─── 패턴 고르기 ────────────────────────────────────────

func _choose(p: Player) -> void:
	var dist := absf(p.global_position.x - global_position.x)
	var pick := ""
	if not pattern_queue.is_empty():
		pick = String(pattern_queue[_queue_i % pattern_queue.size()])
		_queue_i += 1
	else:
		var opts: Dictionary = {}
		if phase == 1:
			opts = {"sweep": 4.0, "spit": 3.0, "inhale": 3.0 if _inhale_cd <= 0.0 else 0.0}
			if dist > 17.0 * T:
				opts["sweep"] = 1.0
		else:
			opts = {
				"sweep": 3.0, "spit": 1.5, "inhale": 2.0 if _inhale_cd <= 0.0 else 0.0,
				"hands": 3.0, "leap": 3.0 if dist > 3.0 * T else 1.0, "grab": 3.0 if dist < 13.0 * T else 1.0,
			}
		if opts.has(_last):
			opts[_last] = float(opts[_last]) * 0.25
		var total := 0.0
		for key in opts:
			total += float(opts[key])
		var r := randf() * total
		for key in opts:
			r -= float(opts[key])
			if r <= 0.0:
				pick = String(key)
				break
		if pick == "":
			pick = "spit"
	_last = pick.trim_suffix("_high").trim_suffix("_low")
	match pick:
		"sweep":
			_start_sweep(randf() < 0.5, SWEEP_WIND_TIME)
			if phase == 2 or _is_enraged:
				_sweep_combo = 1 if randf() < 0.5 else 0
		"sweep_high":
			_start_sweep(true, SWEEP_WIND_TIME)
		"sweep_low":
			_start_sweep(false, SWEEP_WIND_TIME)
		"inhale":
			_start_inhale()
		"spit":
			_start_spit()
		"hands":
			_start_hands()
		"leap":
			_start_leap()
		"grab":
			_start_grab()
		_:
			_start_spit()


# ─── 휩쓸기 ─────────────────────────────────────────────

func _start_sweep(high: bool, wind: float) -> void:
	sweep_high = high
	face_player()
	_set_state(S.SWEEP_WIND, wind * (0.85 if _is_enraged else 1.0))
	var y := floor_y + (SWEEP_HIGH_Y if high else SWEEP_LOW_Y)
	sweep_from_x = global_position.x + facing * 2.0 * T
	sweep_to_x = _wall_x(Vector2(global_position.x, y), SWEEP_REACH_T)
	sweep_hand = _sweep_rest_hand()
	if high:
		# 높게: 밝게 올라가는 소리 + 팔을 머리 위로 (푸른 예고)
		Sfx.play_pitch(&"sniper_aim", 1.5, 0.0)
		Sfx.play_pitch(&"window", 1.3, -4.0)
	else:
		# 낮게: 낮게 긁는 소리 + 팔을 바닥에 끌어 뒤로 (붉은 예고)
		Sfx.play_pitch(&"growl", 0.6, 2.0)
		Sfx.play(&"crumble", -3.0, 0.0)


## 예고 중 손 위치 (전역): 높게는 머리 위, 낮게는 뒤쪽 바닥
func _sweep_rest_hand() -> Vector2:
	if sweep_high:
		return global_position + Vector2(facing * 26.0, -176.0)
	return global_position + Vector2(-facing * 46.0, -4.0)


## facing 쪽으로 최대 reach_t 안에서 벽 바로 앞 x
func _wall_x(from: Vector2, reach_t: float) -> float:
	var to := from + Vector2(facing * reach_t * T, 0)
	var q := PhysicsRayQueryParameters2D.create(from, to, GameConst.L_WORLD)
	var r := get_world_2d().direct_space_state.intersect_ray(q)
	if r.is_empty():
		return to.x
	var hit: Vector2 = r["position"]
	return hit.x - facing * 1.0 * T


# ─── 흡입 ───────────────────────────────────────────────

func _start_inhale() -> void:
	face_player()
	_inhale_cd = INHALE_COOLDOWN + (2.0 if phase == 2 else 0.0)
	_set_state(S.INHALE_WIND, INHALE_WIND_TIME)
	Sfx.play_pitch(&"growl", 0.7, 0.0)
	Sfx.play_pitch(&"overload_warn", 0.6, -6.0)


func _inhale_pull(delta: float, p: Player) -> void:
	_fx_t -= delta
	if _fx_t <= 0.0:
		_fx_t = 0.4
		Sfx.play_pitch(&"whoosh", 0.6, -6.0)
	# 빨려 드는 먼지
	if Engine.get_physics_frames() % 4 == 0:
		var m := mouth_global()
		var at := Vector2(global_position.x + facing * randf_range(3.0, 16.0) * T, floor_y - randf_range(0.3, 5.0) * T)
		Fx.burst(at, 1, {
			direction = (m - at).normalized(), spread = 5.0, speed_min = 220.0, speed_max = 300.0, lifetime = 0.45,
			gradient = Palette.fade_gradient(Color(0.75, 0.6, 1.0, 0.8)), size_min = 1.0, size_max = 2.0, gravity = Vector2.ZERO,
		})
	if p == null or not p.is_alive():
		return
	var side := 1 if p.global_position.x >= global_position.x else -1
	if side != facing or p.state == Player.State.DASH:
		return
	if absf(p.global_position.x - global_position.x) > INHALE_RANGE_T * T:
		return
	var dx := mouth_global().x - p.global_position.x
	if absf(dx) > 4.0:
		var step := signf(dx) * minf(INHALE_PULL_T * T * delta, absf(dx) - 4.0)
		p.move_and_collide(Vector2(step, 0.0))
	p.overload = maxf(0.0, p.overload - INHALE_DRAIN * delta)


func _on_mouth_bite(_p: Node) -> void:
	if state != S.INHALE:
		return
	Sfx.play(&"squish", 2.0, 0.0)
	Sfx.play_pitch(&"roar", 1.2, -4.0)
	_end_inhale()


func _end_inhale() -> void:
	_mouth.active = false
	_set_state(S.INHALE_REC, INHALE_REC_TIME)


## 흡입 중엔 고개를 숙인 입까지 피격 판정을 넓힌다 (판정이 둘이면 범위 공격이 두 번 맞으므로 하나를 늘림)
func _set_mouth_hurtbox(on: bool) -> void:
	if on == _mouth_box_on or _hurtbox == null or _hurtbox.get_child_count() == 0:
		return
	_mouth_box_on = on
	var cs := _hurtbox.get_child(0) as CollisionShape2D
	if cs == null or not (cs.shape is RectangleShape2D):
		return
	var rect := cs.shape as RectangleShape2D
	var half := body_size.x * 0.5 + 2.0
	if on:
		var front := facing * (MOUTH_LOW.x + 16.0)
		var x0 := minf(-half, front)
		var x1 := maxf(half, front)
		rect.set_deferred("size", Vector2(x1 - x0, body_size.y + 4.0))
		cs.set_deferred("position", Vector2((x0 + x1) * 0.5, -body_size.y * 0.5))
	else:
		rect.set_deferred("size", body_size + Vector2(4, 4))
		cs.set_deferred("position", Vector2(0, -body_size.y * 0.5))


# ─── 검은 불덩이 ────────────────────────────────────────

func _start_spit() -> void:
	face_player()
	_set_state(S.SPIT_WIND, SPIT_WIND_TIME * (0.85 if _is_enraged else 1.0))
	Sfx.play_pitch(&"ignite", 0.6, 0.0)
	Sfx.play_pitch(&"growl", 0.9, -6.0)


func _fire_dark(p: Player, index: int) -> void:
	if p == null:
		return
	var from_pos := mouth_global()
	var offs := [0.0, -2.5, 2.5]
	var px := clampf(p.global_position.x, global_position.x - SPIT_RANGE_T * T, global_position.x + SPIT_RANGE_T * T)
	var tgt := Vector2(px + float(offs[index]) * T * facing, p.global_position.y - 6.0)
	var flight := FIREBALL_FLIGHT * (0.88 if _is_enraged else 1.0)
	var vx := (tgt.x - from_pos.x) / flight
	var vy := (tgt.y - from_pos.y - 0.5 * FIREBALL_GRAVITY * flight * flight) / flight
	var v := Vector2(vx, vy)
	shoot(from_pos, v.normalized(), v.length(), "dark", {
		gravity = FIREBALL_GRAVITY, damage = 1, radius = 6.0, cause = "agwi", life = 4.0,
	})
	Sfx.play_pitch(&"shoot_heavy", 0.55, 0.0)
	Fx.burst(from_pos, 8, {
		direction = v.normalized(), spread = 40.0, speed_min = 30.0, speed_max = 90.0, lifetime = 0.35,
		gradient = Palette.fade_gradient(Color(0.55, 0.3, 0.9)), size_min = 1.5, size_max = 3.0,
	})


# ─── 페이즈 전환: 사슬 끊기 ─────────────────────────────

func _start_chain_break() -> void:
	_phase_pending = false
	_clear_attacks()
	_set_mouth_hurtbox(false)
	_sweep_combo = 0
	_snapped = false
	_fx_t = 0.0
	velocity.x = 0.0
	_set_state(S.CHAIN_BREAK, CHAIN_BREAK_TIME)
	phase = 2 # 사슬은 연출 중간(CHAIN_SNAP_AT)에 끊어짐 — 그림은 chains_intact로 구분
	phase_changed.emit(2)
	Sfx.play(&"chain", 0.0, 0.0)
	Sfx.play_pitch(&"growl", 0.6, 2.0)


func _ai_chain_break(delta: float, p: Player) -> void:
	velocity.x = 0.0
	_timer -= delta
	_fx_t -= delta
	var el := state_elapsed()
	if not _snapped:
		if _fx_t <= 0.0:
			_fx_t = 0.3
			Sfx.play(&"chain", -6.0, 0.15)
			Fx.shake(0.12, 0.15)
		if el >= CHAIN_SNAP_AT:
			_snapped = true
			chains_intact = false
			_fx_t = 0.0
			Sfx.play(&"chain", 6.0, 0.0)
			Sfx.play(&"roar", 4.0, 0.0)
			Sfx.play_pitch(&"explode", 0.6, -2.0)
			Fx.shake(1.0, 0.6)
			Fx.flash(Color(0.6, 0.3, 1.0, 0.35), 0.25)
			Fx.zoom_punch(0.06)
			for a in chain_anchors():
				Fx.burst(a + Vector2(0, -6), 10, {
					direction = Vector2.UP, spread = 60.0, speed_min = 60.0, speed_max = 180.0, lifetime = 0.7,
					gradient = Palette.fade_gradient(Color(0.7, 0.45, 1.0)), size_min = 1.5, size_max = 3.0, gravity = Vector2(0, 400),
				})
	else:
		# 포효: 고리가 퍼지고 세라를 살짝 밀어냄 (피해 없음)
		if _fx_t <= 0.0:
			_fx_t = 0.3
			Fx.ring(mouth_global(), 10.0, 7.0 * T, Color(0.6, 0.35, 1.0), 0.5, 3.0)
		if p and p.is_alive() and el < CHAIN_SNAP_AT + 0.7:
			var away := signf(p.global_position.x - global_position.x)
			if away == 0.0:
				away = 1.0
			if absf(p.global_position.x - global_position.x) < 10.0 * T:
				p.move_and_collide(Vector2(away * 6.0 * T * delta, 0.0))
	if _timer <= 0.0:
		_phase_pending = false
		_to_idle(0.6)


# ─── 2페이즈: 그림자 손 ─────────────────────────────────

func _start_hands() -> void:
	face_player()
	_set_state(S.HANDS_WIND, HANDS_WIND_TIME)
	Sfx.play_pitch(&"growl", 0.75, 0.0)


func _spawn_hand(p: Player, i: int) -> void:
	var h := ShadowHand.new()
	h.x = p.global_position.x
	h.y = _ground_below(p.global_position)
	h.area = _hand_pool[i % _hand_pool.size()]
	hands.append(h)
	Sfx.play_pitch(&"growl", 0.5, -8.0)


func _ground_below(pos: Vector2) -> float:
	var q := PhysicsRayQueryParameters2D.create(pos + Vector2(0, -4), pos + Vector2(0, 12.0 * T), GameConst.L_WORLD | GameConst.L_PLATFORM)
	var r := get_world_2d().direct_space_state.intersect_ray(q)
	if r.is_empty():
		return floor_y
	var hit: Vector2 = r["position"]
	return hit.y


func _tick_hands(delta: float) -> void:
	for h in hands:
		h.t += delta
		var up := h.t >= HAND_WARN and h.t < HAND_WARN + HAND_UP
		if up and not h.erupted:
			h.erupted = true
			Sfx.play(&"slam", -3.0, 0.1)
			Sfx.play(&"squish", -4.0, 0.1)
			Fx.shake(0.15, 0.12)
			Fx.burst(Vector2(h.x, h.y - 2), 12, {
				direction = Vector2.UP, spread = 25.0, speed_min = 80.0, speed_max = 200.0, lifetime = 0.45,
				gradient = Palette.fade_gradient(Color(0.35, 0.15, 0.55)), size_min = 1.5, size_max = 3.0,
				gravity = Vector2(0, 200), add = false,
			})
		h.area.active = up and not _dying
		h.area.global_position = Vector2(h.x, h.y - 22.0)
	for i in range(hands.size() - 1, -1, -1):
		if hands[i].done():
			hands[i].area.active = false
			hands.remove_at(i)


# ─── 2페이즈: 도약 내려찍기 ─────────────────────────────

func _start_leap() -> void:
	face_player()
	_set_state(S.LEAP_WIND, LEAP_WIND_TIME * (0.85 if _is_enraged else 1.0))
	var p := player()
	leap_x = p.global_position.x if p else global_position.x
	Sfx.play_pitch(&"charger_windup", 0.6, 0.0)
	Sfx.play_pitch(&"growl", 0.8, -4.0)


func _land_slam() -> void:
	velocity.x = 0.0
	_contact.dodgeable = false
	_slam.active = true
	_slam_t = 0.15
	_set_state(S.LEAP_REC, LEAP_REC_TIME)
	Sfx.play(&"slam", 4.0, 0.0)
	Sfx.play_pitch(&"explode", 0.5, -4.0)
	Fx.shake(0.9, 0.4)
	Fx.zoom_punch(0.04)
	Fx.ring(global_position + Vector2(0, -4), 8.0, 4.0 * T, Color(0.6, 0.35, 1.0), 0.35, 3.0)
	Fx.burst(global_position + Vector2(0, -4), 24, {
		direction = Vector2.UP, spread = 80.0, speed_min = 60.0, speed_max = 200.0, lifetime = 0.6,
		gradient = Palette.fade_gradient(Palette.GROUND_TOP), size_min = 1.5, size_max = 3.5, gravity = Vector2(0, 300),
	})
	for i in 2:
		var w := ShockWave.new()
		w.dir = -1.0 if i == 0 else 1.0
		w.x = global_position.x + w.dir * 2.0 * T
		w.y = global_position.y
		w.area = _wave_pool[i]
		waves.append(w)


func _tick_waves(delta: float) -> void:
	for w in waves:
		w.t += delta
		w.x += w.dir * WAVE_SPEED_T * T * delta
		w.area.active = not _dying
		w.area.global_position = Vector2(w.x, w.y - 8.0)
	for i in range(waves.size() - 1, -1, -1):
		var w := waves[i]
		var blocked := false
		if w.t > 0.05:
			var q := PhysicsRayQueryParameters2D.create(Vector2(w.x, w.y - 8.0), Vector2(w.x + w.dir * 8.0, w.y - 8.0), GameConst.L_WORLD)
			blocked = not get_world_2d().direct_space_state.intersect_ray(q).is_empty()
		if w.t >= WAVE_TIME or blocked:
			w.area.active = false
			waves.remove_at(i)


# ─── 2페이즈: 탐식 잡기 ─────────────────────────────────

func _start_grab() -> void:
	face_player()
	_set_state(S.GRAB_WIND, GRAB_WIND_TIME * (0.85 if _is_enraged else 1.0))
	Sfx.play_pitch(&"roar", 1.5, -2.0)
	Sfx.play_pitch(&"charger_windup", 0.8, -2.0)


# ─── 피격 ───────────────────────────────────────────────

func modify_damage(hit: Hit) -> float:
	if not engaged or state == S.CHAIN_BREAK or _dying:
		return 0.0
	if mouth_weak() and hit.source_pos.distance_to(mouth_global()) <= MOUTH_WEAK_RADIUS:
		return MOUTH_MULT
	if state == S.LEAP_REC or state == S.GRAB_MISS:
		return OPEN_MULT
	return BODY_MULT


func take_hit(hit: Hit) -> void:
	if _dying:
		return
	var before := hp
	super.take_hit(hit)
	if _dying or hp <= 0:
		return
	# 50% 아래로는 사슬 끊기 연출을 반드시 거친다 (한 방에 50%를 넘겨 깎여도 50%에서 멈춤)
	var half := int(max_hp * 0.5)
	if phase == 1 and hp <= half:
		if before > half:
			hp = half
		_phase_pending = true
	if not _is_enraged and hp * 4 <= max_hp:
		_is_enraged = true
		enraged.emit()
		Sfx.play_pitch(&"roar", 0.8, 0.0)


func _on_hit(hit: Hit, _dir: int) -> void:
	if EnemyBase.is_fox_hit(hit) and _flinch_cd <= 0.0 and hp > 0:
		if state != S.CHAIN_BREAK and state != S.DORMANT and state != S.DYING and state != S.FLINCH:
			_start_flinch()


## 푸른 여우불이 무섭다: 움찔
func _start_flinch() -> void:
	_flinch_cd = FLINCH_COOLDOWN
	_clear_attacks()
	_set_mouth_hurtbox(false)
	_sweep_combo = 0
	_set_state(S.FLINCH, FLINCH_TIME)
	velocity.x = -facing * 2.0 * T
	Sfx.play_pitch(&"growl", 1.7, -2.0)
	Fx.ring(mouth_global(), 6.0, 2.5 * T, Color(0.55, 0.85, 1.0), 0.3, 2.0)


# ─── 죽음: 무너져 연기로 ────────────────────────────────

func _die(dir: int) -> void:
	if _dying_done:
		super._die(dir)
		return
	if _dying:
		return
	_dying = true
	_die_dir = dir
	hp = 0
	_clear_attacks()
	_slam.active = false
	_contact.active = false
	for h in hands:
		h.area.active = false
	hands.clear()
	for w in waves:
		w.area.active = false
	waves.clear()
	_set_mouth_hurtbox(false)
	_hurtbox.set_deferred("monitorable", false)
	velocity = Vector2.ZERO
	_set_state(S.DYING, DYING_TIME)
	Sfx.play_pitch(&"roar", 0.55, 2.0)
	Sfx.play(&"crumble", 0.0, 0.0)
	Fx.shake(0.6, 0.8)
	Fx.flash(Color(0.5, 0.3, 0.9, 0.3), 0.3)


func _ai_dying(delta: float) -> void:
	velocity.x = 0.0
	_timer -= delta
	_fx_t -= delta
	if _fx_t <= 0.0:
		_fx_t = 0.08
		var k := state_progress()
		var at := global_position + Vector2(randf_range(-30.0, 50.0) * facing, -randf_range(10.0, 140.0) * (1.0 - 0.6 * k))
		Fx.burst(at, 5, {
			direction = Vector2.UP, spread = 50.0, speed_min = 15.0, speed_max = 60.0, lifetime = 1.1,
			gradient = Palette.fade_gradient(Color(0.45, 0.3, 0.65, 0.8)), size_min = 2.0, size_max = 4.5,
			gravity = Vector2(0, -50), add = false,
		})
	if _timer <= 0.0:
		_dying_done = true
		_die(_die_dir)
