class_name Haetae
extends EnemyBase
## 해태 — 신계 수문의 미니보스 (docs/archive/sera/chapter1.md 7절·12.1절 P7·12.5절).
## 광화문 해태처럼 불을 먹는 신수: 붉은 불은 50%만 들어가고, 가끔 입을 벌려 주변의 불을 들이켜 20 회복한다
## (들이켜는 동안 맞은 붉은 불은 먹혀서 피해 0 + 조금 더 회복). 푸른 여우불은 제 피해가 들어가고 움찔하게 만든다.
## 패턴 (모두 예고 → 공격 → 빈틈):
##   돌진: 머리를 낮추고 뒷발로 땅을 긁음(0.9초, 붉은빛) → 벽까지 돌진(이때만 퍼펙트 회피 대상) → 벽에 박히면 1초 비틀거림
##   도약 + 불 숨결: 웅크림(0.6초, 착지 지점에 붉은 표시) → 세라 자리로 도약 → 고개를 젖히며 불을 모음(0.65초, 불길 범위가 붉게 보임)
##                   → 앞쪽 4T 부채꼴 불 1초 → 헐떡임 1초. 등 뒤나 4T 밖이 안전
##   불 먹기: 붉은 불을 3번 이상 맞고 5초가 지났거나, 8초가 지났을 때 → 입을 벌리고 주변 불을 빨아들임 → 회복
##   체력 50%(처음 한 번): enraged 신호 → 포효(화면 흔들림) → 이후 4.2초마다 기와 3장이 떨어짐(0.7초 전 바닥에 붉은 그림자)
## engaged가 false인 동안은 웅크려 잠든 채 아무것도 하지 않는다(대본이 켠다). 쓰러지면 터지지 않고 무릎 꿇고 사라진다.

enum S {
	DORMANT, RISE, STALK,
	CHARGE_WINDUP, CHARGE, WALL_STAGGER, SKID,
	CROUCH, LEAP, LAND, BREATH_WINDUP, BREATH, PANT,
	EAT_WINDUP, INHALE, SATED,
	FLINCH, ROAR, DEFEATED,
}

const RoofTile := preload("res://enemies/haetae_roof_tile.gd")
const HP := 1000 ## 첫 미니보스 = 여우 모드 시범전 (2600 → 1600 → 1000, 사용자 플레이 피드백)
const BODY := Vector2(62, 44)
const WALK_T := 3.0
const RISE_TIME := 0.9
const STALK_TIME := Vector2(1.35, 2.1) ## 공격 사이 어슬렁거리는 시간 (최소, 최대). 시범전이라 넉넉히
const STALK_TIME_ENRAGED := Vector2(0.85, 1.35)
# 돌진
const CHARGE_WINDUP := 1.2
const CHARGE_SPEED_T := 15.0
const CHARGE_SPEED_ENRAGED_T := 17.0
const CHARGE_MAX_T := 36.0
const WALL_STAGGER_TIME := 1.0
const SKID_TIME := 0.6
# 도약 + 불 숨결
const CROUCH_TIME := 0.8
const LEAP_TIME := 0.75
const LEAP_GRAVITY := 1050.0 ## 도약 포물선이 너무 높아 천장 발판에 부딪히지 않게 (꼭대기 약 4.6T)
const LEAP_MAX_T := 14.0
const LAND_TIME := 0.3
const BREATH_WINDUP := 0.85
const BREATH_TIME := 1.0
const PANT_TIME := 1.0
# 불 먹기
const RED_MULT := 0.5
const EAT_EVERY := 8.0
const EAT_RED_HITS := 3
const EAT_MIN_GAP := 5.0
const EAT_WINDUP := 0.5
const INHALE_TIME := 1.3
const SATED_TIME := 0.6
const EAT_HEAL := 20
const GULP_HEAL := 2 ## 들이켜는 중에 먹힌 붉은 불 1발당 추가 회복
# 움찔 (푸른 여우불)
const FLINCH_TIME := 0.35
const FLINCH_HEAVY_TIME := 0.7
const FLINCH_COOLDOWN := 2.0
const FOX_HEAVY := Hit.FOX_HEAVY
# 포효 · 기와
const ROAR_TIME := 1.6
const TILE_EVERY := 6.0
const TILE_WARN := 0.7
const MOUTH := Vector2(45, -31) ## 오른쪽을 볼 때 원점(발밑) → 입 (평소 자세)
const FIRE_FOX := Color(0.55, 0.85, 1.0)

var state: S = S.DORMANT
var is_enraged := false
var red_hits := 0 ## 마지막 불 먹기 이후 맞은 붉은 불 횟수
var fed_glow := 0.0 ## 불을 먹었을 때 갈기·꼬리 불꽃이 커지는 양 (0~1)
var leap_target := Vector2.INF ## 착지 예고 지점 (전역, 바닥)
var _timer := 0.0
var _dur := 0.0
var _state_t := 0.0
var _since_eat := 0.0
var _flinch_cd := 0.0
var _fx_timer := 0.0
var _snd_timer := 0.0
var _spark_cd := 0.0
var _tile_timer := 0.0
var _last_attack := ""
var _repeat := 0
var _charge_start_x := 0.0
var _charge_frames := 0
var _air_t := 0.0
var _absorbed := 0
var _roar_pending := false
var _death_t := 0.0
var _tiles: Array[Node] = []
var _contact: EnemyAttackArea
var _breath_near: EnemyAttackArea
var _breath_far: EnemyAttackArea


func _init() -> void:
	engaged = false # 대본이 켤 때까지 기다린다 (방 데이터·시험 명령이 나중에 덮어쓸 수 있게 _init에서)


func _build() -> void:
	max_hp = HP
	body_size = BODY
	is_boss = true
	is_elite = false
	knock_mult = 0.0
	launch_mult = 0.0
	_gravity = LEAP_GRAVITY
	kind_id = "haetae"
	display_name = "해태"
	subtitle = "신계의 수문장"
	_visual = HaetaeVisual.new()
	_visual.enemy = self
	add_child(_visual)
	_contact = add_attack_area(Vector2(60, 34), Vector2(0, -19), &"haetae", 1)
	_breath_near = add_attack_area(Vector2(48, 24), Vector2.ZERO, &"haetae_fire", 1)
	_breath_far = add_attack_area(Vector2(28, 32), Vector2.ZERO, &"haetae_fire", 1)
	_contact.active = false
	_breath_near.active = false
	_breath_far.active = false


func _ready() -> void:
	super()
	collision_mask = GameConst.L_WORLD # 큰 몸은 통과 발판 위에 올라서지 않는다 (발판은 세라의 피난처)


## 지금 상태의 진행도 0~1 (시간이 정해진 상태만)
func state_k() -> float:
	return clampf(1.0 - _timer / _dur, 0.0, 1.0) if _dur > 0.0 else 0.0


func state_time() -> float:
	return _state_t


## 쓰러진 뒤 무릎 꿇는 진행도 0~1
func death_k() -> float:
	return clampf(_death_t / 1.0, 0.0, 1.0)


## 맞았을 때 밝아지는 양 (0~0.5): 기반 클래스처럼 1이 아니라 절반만, 시간에 따라 옅어진다
func flash_amount() -> float:
	return clampf(_flash / (tuning.enemy_flash_time + 0.03), 0.0, 1.0) * 0.5


## 입 위치 (자세마다 고개 각도가 달라 그림과 맞춘다)
func mouth() -> Vector2:
	var m := MOUTH
	match state:
		S.BREATH, S.BREATH_WINDUP:
			m = Vector2(45, -24)
		S.INHALE, S.EAT_WINDUP:
			m = Vector2(47, -36)
		S.ROAR:
			m = Vector2(48, -42)
	return global_position + Vector2(m.x * facing, m.y)


func _enter(s: S, dur := 0.0) -> void:
	state = s
	_timer = dur
	_dur = dur
	_state_t = 0.0
	_fx_timer = 0.0


func _enter_stalk(mult := 1.0) -> void:
	var r := STALK_TIME_ENRAGED if is_enraged else STALK_TIME
	_enter(S.STALK, randf_range(r.x, r.y) * mult)


# ─── 매 프레임 ──────────────────────────────────────────

func _ai(delta: float) -> void:
	_update_areas()
	fed_glow = maxf(fed_glow - delta * 0.7, 0.0)
	if state == S.DORMANT:
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		if engaged:
			face_player()
			_enter(S.RISE, RISE_TIME)
			_since_eat = 0.0
			Sfx.play(&"growl", 0.0, 0.0)
			Fx.shake(0.15, 0.4)
		return
	_timer -= delta
	_state_t += delta
	_since_eat += delta
	_flinch_cd -= delta
	_fx_timer -= delta
	_snd_timer -= delta
	_spark_cd -= delta
	if is_enraged:
		_tile_timer -= delta
		if _tile_timer <= 0.0:
			_tile_timer = TILE_EVERY
			_drop_tiles()
	var t := GameConst.TILE
	match state:
		S.RISE:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _timer <= 0.0:
				_enter_stalk(0.6)
		S.STALK:
			_stalk(delta)
		S.CHARGE_WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _fx_timer <= 0.0:
				_fx_timer = 0.22
				# 뒷발로 땅 긁기
				Fx.burst(global_position + Vector2(-facing * 22, -2), 6, {
					direction = Vector2(-facing, -0.8), spread = 30.0, speed_min = 40.0, speed_max = 110.0, lifetime = 0.35,
					gradient = Palette.fade_gradient(Color("#7e74a8")), size_min = 1.0, size_max = 2.5, gravity = Vector2(0, 300),
				})
				Sfx.play(&"land", -6.0, 0.2)
			if _timer <= 0.0:
				_start_charge()
		S.CHARGE:
			_charge()
		S.WALL_STAGGER:
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
			if _timer <= 0.0:
				_enter_stalk(0.5)
		S.SKID:
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
			if _fx_timer <= 0.0:
				_fx_timer = 0.06
				_dust(global_position + Vector2(facing * 20, 0), 3)
			if _timer <= 0.0:
				_enter_stalk(0.7)
		S.CROUCH:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			_aim_leap()
			if _timer <= 0.0:
				_start_leap()
		S.LEAP:
			_air_t += delta
			if (is_on_floor() and _air_t > 0.12) or _air_t > 2.0:
				_land()
		S.LAND:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _timer <= 0.0:
				_enter(S.BREATH_WINDUP, BREATH_WINDUP)
				Sfx.play(&"ignite", 0.0, 0.05)
		S.BREATH_WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _fx_timer <= 0.0:
				_fx_timer = 0.06
				_gather_sparks(18.0, 0.2)
			if _timer <= 0.0:
				_enter(S.BREATH, BREATH_TIME)
				Sfx.play(&"storm", 0.0, 0.05)
				Fx.shake(0.15, 0.3)
		S.BREATH:
			velocity.x = 0.0
			if _fx_timer <= 0.0:
				_fx_timer = 0.035
				_breath_fx()
			if _snd_timer <= 0.0:
				_snd_timer = 0.33
				Sfx.play(&"storm", -7.0, 0.1)
			if _timer <= 0.0:
				_enter(S.PANT, PANT_TIME)
		S.PANT:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _fx_timer <= 0.0:
				_fx_timer = 0.2
				Fx.burst(mouth(), 3, {
					direction = Vector2(facing, -1), spread = 25.0, speed_min = 15.0, speed_max = 40.0, lifetime = 0.6,
					gradient = Palette.fade_gradient(Color(0.6, 0.58, 0.68, 0.7)), size_min = 1.5, size_max = 3.0, gravity = Vector2(0, -30),
				})
			if _timer <= 0.0:
				_enter_stalk(0.8)
		S.EAT_WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _timer <= 0.0:
				_enter(S.INHALE, INHALE_TIME)
				Sfx.play(&"whoosh", 0.0, 0.0)
		S.INHALE:
			velocity.x = 0.0
			if _fx_timer <= 0.0:
				_fx_timer = 0.06
				_gather_sparks(5.5 * t, 0.36)
			if _snd_timer <= 0.0:
				_snd_timer = 0.4
				Sfx.play(&"whoosh", -3.0, 0.1)
			if _timer <= 0.0:
				_finish_eat()
		S.SATED:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _timer <= 0.0:
				_enter_stalk(0.7)
		S.FLINCH:
			velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
			if _timer <= 0.0:
				_flinch_cd = FLINCH_COOLDOWN
				_enter_stalk(0.5)
		S.ROAR:
			velocity.x = 0.0
			if _fx_timer <= 0.0:
				_fx_timer = 0.3
				Fx.ring(mouth(), 10.0, 150.0, Color(1.0, 0.45, 0.3, 0.7), 0.5, 3.0)
				_ceiling_dust()
			if _timer <= 0.0:
				_enter_stalk(0.4)


func _update_areas() -> void:
	var live := engaged and _alive and state != S.DORMANT
	_contact.active = live
	_contact.dodgeable = state == S.CHARGE or state == S.LEAP # 걷는 몸에 스친 건 회피가 아니다
	var breathing := live and state == S.BREATH
	_breath_near.active = breathing and _state_t > 0.04
	_breath_far.active = breathing and _state_t > 0.12 # 불길이 뻗어 나가는 데 잠깐 걸린다
	_breath_near.position = Vector2(facing * 56, -20) # 턱 밑(머리 아래)도 불길 안
	_breath_far.position = Vector2(facing * 94, -16)


# ─── 어슬렁거리기 · 패턴 고르기 ─────────────────────────

func _stalk(delta: float) -> void:
	var t := GameConst.TILE
	var p := player()
	if p and p.is_alive():
		face_player()
		var dx := p.global_position.x - global_position.x
		var adx := absf(dx) / t
		if adx > 7.0:
			velocity.x = signf(dx) * WALK_T * t
		elif adx < 3.5:
			velocity.x = -signf(dx) * WALK_T * 0.6 * t # 너무 붙으면 한 걸음 물러남
		else:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	if _roar_pending and is_on_floor():
		_start_roar()
		return
	if _timer <= 0.0 and is_on_floor() and p and p.is_alive():
		_choose_attack()


func _wants_eat() -> bool:
	if red_hits >= EAT_RED_HITS and _since_eat >= EAT_MIN_GAP:
		return true
	return red_hits >= 1 and _since_eat >= EAT_EVERY


func _choose_attack() -> void:
	var p := player()
	face_player()
	if _wants_eat():
		_start_eat()
		return
	var adx := absf(p.global_position.x - global_position.x) / GameConst.TILE
	var charge_chance := 0.45
	if adx >= 9.0:
		charge_chance = 0.6
	elif adx <= 4.5:
		charge_chance = 0.25
	var pick := "charge" if randf() < charge_chance else "leap"
	if pick == _last_attack and _repeat >= 1:
		pick = "leap" if pick == "charge" else "charge" # 같은 패턴은 두 번까지만
	_repeat = _repeat + 1 if pick == _last_attack else 0
	_last_attack = pick
	if pick == "charge":
		_enter(S.CHARGE_WINDUP, CHARGE_WINDUP)
		Sfx.play(&"charger_windup", 2.0, 0.0)
		Sfx.play(&"growl", -2.0, 0.05)
	else:
		_enter(S.CROUCH, CROUCH_TIME)
		_aim_leap()
		Sfx.play(&"growl", -2.0, 0.1)


# ─── 돌진 ───────────────────────────────────────────────

func _start_charge() -> void:
	_enter(S.CHARGE)
	_charge_start_x = global_position.x
	_charge_frames = 0
	Sfx.play(&"charger_charge", 2.0, 0.0)
	Sfx.play(&"dash", -2.0, 0.0)
	Fx.shake(0.12, 0.2)


func _charge() -> void:
	var t := GameConst.TILE
	var spd := (CHARGE_SPEED_ENRAGED_T if is_enraged else CHARGE_SPEED_T) * t
	velocity.x = facing * spd
	_charge_frames += 1
	if _fx_timer <= 0.0:
		_fx_timer = 0.05
		_dust(global_position + Vector2(-facing * 24, -2), 3)
	if _snd_timer <= 0.0:
		_snd_timer = 0.22 # 쿵쿵 발소리
		Sfx.play(&"land", -3.0, 0.15)
		Fx.shake(0.06, 0.1)
	var hit_wall := is_on_wall() and _charge_frames > 2 and signf(get_wall_normal().x) == -float(facing)
	if hit_wall:
		_wall_slam()
	elif absf(global_position.x - _charge_start_x) >= CHARGE_MAX_T * t or _state_t > 3.0:
		_enter(S.SKID, SKID_TIME)
	elif _roar_pending and _state_t > 0.3:
		_enter(S.SKID, SKID_TIME * 0.5)


func _wall_slam() -> void:
	_enter(S.WALL_STAGGER, WALL_STAGGER_TIME)
	velocity.x = -facing * 90.0 # 튕겨 나옴
	Fx.shake(0.45, 0.35)
	Fx.hitstop(0.05)
	Sfx.play(&"slam", 2.0, 0.05)
	Sfx.play(&"crumble", -4.0, 0.1)
	var at := global_position + Vector2(facing * 34, -26)
	Fx.burst(at, 18, {
		direction = Vector2(-facing, -0.6), spread = 70.0, speed_min = 50.0, speed_max = 150.0, lifetime = 0.55,
		gradient = Palette.fade_gradient(Color("#8a8fb8")), size_min = 1.5, size_max = 3.5, gravity = Vector2(0, 450),
	})
	Fx.ring(at, 4.0, 30.0, Color(1, 0.9, 0.7, 0.6), 0.25, 2.0)


# ─── 도약 + 불 숨결 ─────────────────────────────────────

## 웅크린 동안 세라 자리를 따라 착지 지점을 정한다 (벽 너머로는 뛰지 않음)
func _aim_leap() -> void:
	var t := GameConst.TILE
	var p := player()
	var dx := 0.0
	if p:
		dx = clampf(p.global_position.x - global_position.x, -LEAP_MAX_T * t, LEAP_MAX_T * t)
	if absf(dx) < 1.5 * t:
		dx = facing * 1.5 * t # 너무 가까우면 제자리에서 살짝 뛴다
	var y := global_position.y - 24.0
	var half := body_size.x * 0.5 + 4.0
	var to := global_position.x + dx + signf(dx) * half
	var r := get_world_2d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters2D.create(Vector2(global_position.x, y), Vector2(to, y), GameConst.L_WORLD))
	var tx := global_position.x + dx
	if not r.is_empty():
		var wall_x: float = r.position.x
		tx = wall_x - signf(dx) * half
	leap_target = Vector2(tx, global_position.y)
	facing = 1 if dx >= 0.0 else -1


func _start_leap() -> void:
	_aim_leap()
	_enter(S.LEAP)
	_air_t = 0.0
	velocity.y = -0.5 * _gravity * LEAP_TIME
	velocity.x = (leap_target.x - global_position.x) / LEAP_TIME
	Sfx.play(&"whoosh", 0.0, 0.05)
	Sfx.play(&"jump", -2.0, 0.0)
	_dust(global_position, 8)


func _land() -> void:
	_enter(S.LAND, LAND_TIME)
	velocity.x = 0.0
	leap_target = Vector2.INF
	Fx.shake(0.35, 0.3)
	Sfx.play(&"slam", 0.0, 0.05)
	_dust(global_position + Vector2(-26, 0), 8)
	_dust(global_position + Vector2(26, 0), 8)
	if _roar_pending:
		_start_roar()


func _breath_fx() -> void:
	var m := mouth()
	Fx.burst(m, 4, {
		direction = Vector2(facing, 0.42).normalized(), spread = 16.0, speed_min = 180.0, speed_max = 260.0,
		damping = 110.0, lifetime = 0.32, size_min = 2.0, size_max = 4.0, gravity = Vector2(0, -80),
	})
	Fx.burst(m + Vector2(facing * 30, 10), 2, {
		direction = Vector2(facing, 0.2), spread = 40.0, speed_min = 40.0, speed_max = 120.0,
		lifetime = 0.3, size_min = 2.0, size_max = 3.5, gravity = Vector2(0, -120),
	})


## 주변에서 입으로 빨려 드는 불씨 (radius px 둘레에서, travel초 만에 도착)
func _gather_sparks(radius: float, travel: float) -> void:
	var m := mouth()
	var g := Palette.cached_gradient(PackedFloat32Array([0.0, 0.7, 1.0]),
		PackedColorArray([Color(Palette.FIRE_OUT, 0.25), Palette.FIRE_HOT, Color(Palette.FIRE_CORE, 0.0)]))
	for i in 5:
		var a := randf() * TAU
		var r := radius * randf_range(0.75, 1.0)
		var from := m + Vector2(cos(a), sin(a)) * r
		Fx.burst(from, 2, {
			direction = (m - from).normalized(), spread = 4.0, speed_min = r / travel, speed_max = r / (travel * 0.9),
			lifetime = travel, lifetime_random = 0.05, gradient = g, size_min = 1.5, size_max = 3.0,
			gravity = Vector2.ZERO, add = true,
		})


# ─── 불 먹기 ────────────────────────────────────────────

func _start_eat() -> void:
	_enter(S.EAT_WINDUP, EAT_WINDUP)
	_absorbed = 0
	Sfx.play(&"growl", -3.0, 0.1)


func _finish_eat() -> void:
	var heal := EAT_HEAL + _absorbed * GULP_HEAL
	hp = mini(hp + heal, max_hp)
	red_hits = 0
	_since_eat = 0.0
	_absorbed = 0
	fed_glow = 1.0
	_enter(S.SATED, SATED_TIME)
	Sfx.play(&"potion", 0.0, 0.0)
	Sfx.play(&"ignite", -4.0, 0.0)
	var m := mouth()
	Fx.ring(m, 4.0, 40.0, Color(1.0, 0.75, 0.35), 0.4, 3.0)
	Fx.burst(global_position + Vector2(0, -26), 22, {
		spread = 180.0, speed_min = 20.0, speed_max = 70.0, lifetime = 0.7, box = Vector2(26, 14),
		gradient = Palette.fade_gradient(Palette.FIRE_HOT), size_min = 1.0, size_max = 2.5, gravity = Vector2(0, -60), add = true,
	})
	_float_text("+%d" % heal, Color(0.6, 1.0, 0.5))


func _float_text(text: String, col: Color) -> void:
	if not GameState.settings.get("damage_numbers", true):
		return
	var l := Label.new()
	l.text = text
	var ls := LabelSettings.new()
	ls.font_size = 12
	ls.font_color = col
	ls.outline_size = 4
	ls.outline_color = Color("#0d1a10")
	l.label_settings = ls
	l.position = global_position + Vector2(-12, -body_size.y - 22)
	l.z_index = 20
	Fx.effect_parent().add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 16.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.3).set_delay(0.6)
	tw.tween_callback(l.queue_free)


# ─── 피해 반응 ──────────────────────────────────────────

func modify_damage(hit: Hit) -> float:
	if not engaged or state == S.DORMANT:
		return 0.0
	if EnemyBase.is_fox_hit(hit):
		return 1.0
	if state == S.INHALE:
		return 0.0 # 들이켜는 중의 붉은 불은 먹힌다
	return RED_MULT


func _on_blocked(hit: Hit) -> void:
	if state == S.INHALE and not EnemyBase.is_fox_hit(hit):
		_absorbed += 1
		fed_glow = minf(fed_glow + 0.3, 1.0)
		var m := mouth()
		Fx.burst(m, 5, {
			spread = 180.0, speed_min = 10.0, speed_max = 40.0, lifetime = 0.25,
			size_min = 1.5, size_max = 3.0, gravity = Vector2.ZERO,
		})
		if _spark_cd <= 0.0:
			_spark_cd = 0.15
			Sfx.play(&"ignite", -10.0, 0.2) # 꿀꺽
		return
	super(hit)


func _on_hit(hit: Hit, _dir: int) -> void:
	if EnemyBase.is_fox_hit(hit):
		_try_flinch(hit)
	else:
		red_hits += 1
		_red_spark(hit)
	if not is_enraged and hp > 0 and hp * 2 <= max_hp:
		is_enraged = true
		enraged.emit()
		if state == S.LEAP or state == S.CHARGE:
			_roar_pending = true # 착지·멈춘 뒤에 포효
		else:
			_start_roar()


## 붉은 불에 맞으면 불씨가 입으로 빨려 든다 (불을 먹는다는 힌트)
func _red_spark(hit: Hit) -> void:
	fed_glow = minf(fed_glow + 0.12, 1.0)
	if _spark_cd > 0.0:
		return
	_spark_cd = 0.1
	var side := signf(hit.source_pos.x - global_position.x)
	if side == 0.0:
		side = float(facing)
	var from := global_position + Vector2(side * 26.0, -24.0)
	var m := mouth()
	Fx.burst(from, 5, {
		direction = (m - from).normalized(), spread = 20.0, speed_min = 60.0, speed_max = 130.0, lifetime = 0.3,
		size_min = 1.0, size_max = 2.0, gravity = Vector2.ZERO,
	})


func _try_flinch(hit: Hit) -> void:
	var eating := state == S.INHALE or state == S.EAT_WINDUP
	if state in [S.CHARGE, S.LEAP, S.LAND, S.BREATH, S.ROAR, S.DORMANT, S.RISE, S.FLINCH, S.DEFEATED]:
		return
	if not eating and _flinch_cd > 0.0:
		return
	var heavy := hit.kind in FOX_HEAVY
	_enter(S.FLINCH, FLINCH_HEAVY_TIME if heavy or eating else FLINCH_TIME)
	velocity.x = -facing * 40.0
	_absorbed = 0 # 먹던 불은 토해 낸다
	Sfx.play(&"growl", -3.0, 0.2)
	Fx.burst(global_position + Vector2(facing * 22, -32), 12, {
		spread = 180.0, speed_min = 30.0, speed_max = 110.0, lifetime = 0.4,
		gradient = Palette.fade_gradient(FIRE_FOX), size_min = 1.0, size_max = 2.5, gravity = Vector2(0, -40), add = true,
	})
	if eating:
		Fx.burst(mouth(), 10, {
			direction = Vector2(facing, -0.3), spread = 50.0, speed_min = 40.0, speed_max = 120.0, lifetime = 0.35,
			size_min = 1.5, size_max = 3.0, gravity = Vector2(0, 120),
		})


# ─── 포효 · 기와 ────────────────────────────────────────

func _start_roar() -> void:
	_roar_pending = false
	_enter(S.ROAR, ROAR_TIME)
	velocity.x = 0.0
	face_player()
	_tile_timer = 0.9 # 포효 도중 첫 기와
	Sfx.play(&"roar", 3.0, 0.0)
	Fx.shake(0.6, 1.0)
	Fx.flash(Color(1.0, 0.3, 0.2, 0.28), 0.3)


## 천장에서 먼지가 떨어진다 (기와가 흔들린다는 예고)
func _ceiling_dust() -> void:
	var space := get_world_2d().direct_space_state
	for i in 3:
		var x := global_position.x + randf_range(-18.0, 18.0) * GameConst.TILE
		var from := Vector2(x, global_position.y - 30.0)
		var r := space.intersect_ray(PhysicsRayQueryParameters2D.create(from, from + Vector2(0, -16.0 * GameConst.TILE), GameConst.L_WORLD))
		if r.is_empty():
			continue
		var at: Vector2 = r.position
		Fx.burst(at + Vector2(0, 3), 5, {
			direction = Vector2.DOWN, spread = 15.0, speed_min = 10.0, speed_max = 40.0, lifetime = 0.8,
			gradient = Palette.fade_gradient(Color("#8a86a8")), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 160),
		})


func _drop_tiles() -> void:
	var p := player()
	if p == null or not p.is_alive():
		return
	var t := GameConst.TILE
	var px := p.global_position.x
	var side := 1.0 if randf() < 0.5 else -1.0
	var xs: Array[float] = [px, px + side * randf_range(4.0, 6.5) * t, px - side * randf_range(6.0, 9.0) * t]
	for i in xs.size():
		_spawn_tile(xs[i], p.global_position.y, TILE_WARN + i * 0.18)


func _spawn_tile(x: float, ref_y: float, warn: float) -> void:
	var t := GameConst.TILE
	var space := get_world_2d().direct_space_state
	# 방 밖(벽 너머)으로 나가지 않게: 세라 높이에서 가로로 벽을 확인
	var probe_y := ref_y - 20.0
	var from_x := global_position.x
	var p := player()
	if p:
		from_x = p.global_position.x
	var side := Vector2(x, probe_y)
	var wall := space.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(from_x, probe_y), side, GameConst.L_WORLD))
	if not wall.is_empty():
		var wx: float = wall.position.x
		x = wx - signf(x - from_x) * 12.0
	var down := space.intersect_ray(PhysicsRayQueryParameters2D.create(
		Vector2(x, probe_y), Vector2(x, probe_y + 8.0 * t), GameConst.L_WORLD | GameConst.L_PLATFORM))
	if down.is_empty():
		return
	var floor_y: float = down.position.y
	var up := space.intersect_ray(PhysicsRayQueryParameters2D.create(
		Vector2(x, floor_y - 4.0), Vector2(x, floor_y - 14.0 * t), GameConst.L_WORLD))
	var top_y := floor_y - 14.0 * t
	if not up.is_empty():
		var uy: float = up.position.y
		top_y = uy + 6.0
	var tile := RoofTile.new()
	tile.setup(Vector2(x, floor_y), top_y, warn)
	Fx.effect_parent().add_child(tile)
	_tiles.append(tile)


func _clear_tiles() -> void:
	for n in _tiles:
		if is_instance_valid(n):
			n.queue_free()
	_tiles.clear()


func _dust(at: Vector2, amount: int) -> void:
	Fx.burst(at, amount, {
		direction = Vector2.UP, spread = 70.0, speed_min = 20.0, speed_max = 70.0, lifetime = 0.4,
		gradient = Palette.fade_gradient(Color("#7e74a8")), size_min = 1.0, size_max = 2.5, gravity = Vector2(0, 120),
	})


# ─── 쓰러짐: 터지지 않고 무릎 꿇은 뒤 사라진다 ──────────

func _die(_dir: int) -> void:
	_defeat_quiet()
	_enter(S.DEFEATED)
	_death_t = 0.0
	velocity.x = 0.0
	leap_target = Vector2.INF
	_clear_tiles()
	Sfx.play(&"growl", 0.0, 0.0)
	Fx.shake(0.3, 0.5)
	Fx.flash(Color(1, 1, 1, 0.25), 0.25)
	_dust(global_position + Vector2(-24, 0), 10)
	_dust(global_position + Vector2(24, 0), 10)
	if _visual:
		var tw := create_tween()
		tw.tween_interval(1.6)
		tw.tween_callback(_fade_sparkle)
		tw.tween_property(_visual, "modulate:a", 0.0, 1.4)
		tw.tween_callback(queue_free)
	else:
		queue_free()


## 사라지기 시작할 때: 금빛 불씨가 피어오른다 (터지는 연출 대신)
func _fade_sparkle() -> void:
	Fx.burst(global_position + Vector2(0, -24), 26, {
		spread = 180.0, speed_min = 10.0, speed_max = 50.0, lifetime = 1.2, box = Vector2(28, 18),
		gradient = Palette.fade_gradient(Color(1.0, 0.8, 0.5)), size_min = 1.0, size_max = 2.5,
		gravity = Vector2(0, -40), add = true,
	})


func _physics_process(delta: float) -> void:
	super(delta)
	if _alive:
		return
	# 쓰러진 뒤: 공중이었다면 바닥까지 내려앉고, 무릎 꿇는 그림을 계속 그린다
	_death_t += delta
	_post_death_fall(delta)
	if _visual:
		_visual.queue_redraw()


# ─── 기와 ───────────────────────────────────────────────
