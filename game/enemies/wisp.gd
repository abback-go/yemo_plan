class_name Wisp
extends EnemyBase
## 도깨비불 (docs/archive/sera/chapter1.md 7절·12.5절): 신계 숲의 첫 상대. 공략 포인트 = "쏘고 피하는 기본".
## 둥둥 떠서 세라와 6~8T 거리를 재다가 → 킥킥 웃으며 부풀고(예고 0.6초, 붉은 고리) →
## 느린 초록 불덩이 3발 부채꼴(9 T/s) → 1.9초 쉬며 다시 거리를 잰다.
## 세 번 맞을 때마다 "펑" 하고 3~4T 떨어진 곳으로 순간이동한다(사라짐·불씨 자국·나타남이 다 보이게).

enum S { DRIFT, TELEGRAPH, SHOOT, BLINK_OUT, BLINK_IN }

const HP := 110
const DETECT_T := 15.0 ## 이 거리 안에 세라가 들어오면 깨어나 거리를 잰다
const PREF_DIST_T := 7.0 ## 세라와 유지하려는 가로 거리
const HOVER_T := 1.5 ## 세라 발밑에서 이만큼 위(머리 높이)에 떠 있으려 한다. 위아래로 0.7T씩 오르내려 가끔은 점프해서 쏴야 맞는다
const SPEED_T := 3.6 ## 떠다니는 최고 속도 (T/s)
const ACCEL := 150.0 ## 떠다니는 가속 (px/s²)
const FIRST_DELAY := 1.1 ## 깨어난 뒤 첫 예고까지
const TELEGRAPH_TIME := 0.6
const SHOOT_TIME := 0.3 ## 쏜 뒤 반동으로 밀려나는 시간
const COOLDOWN := 1.9 ## 쏜 뒤 다음 예고까지
const SHOT_RANGE_T := 12.0 ## 이 거리 안이고 시야가 트였을 때만 쏜다
const SHOT_SPEED_T := 9.0
const SHOT_SPREAD_DEG := 17.0
const BLINK_EVERY := 3 ## 이만큼 맞을 때마다 순간이동
const BLINK_OUT_TIME := 0.16
const BLINK_IN_TIME := 0.24
const BLINK_DIST_T := 3.5
const CENTER := Vector2(0, -7) ## 원점(발밑) → 불꽃 중심
const GREEN := Color(0.55, 1.0, 0.7)

var state: S = S.DRIFT
var aim_dir := Vector2.LEFT
var blink_to := Vector2.ZERO ## 순간이동 도착 지점 (전역, 불꽃 중심)
var _timer := 0.0
var _blink_t := 0.0
var _cooldown := FIRST_DELAY
var _hits := 0
var _awake := false
var _home := Vector2.ZERO
var _side := 1.0 ## 세라의 어느 쪽에 떠 있을지 (-1 왼쪽 / 1 오른쪽)
var _contact: EnemyAttackArea
var _glow: LightGlow


func _build() -> void:
	max_hp = HP
	body_size = Vector2(14, 14)
	flying = true
	knock_mult = 0.6
	launch_mult = 0.0 # 떠 있는 불이라 띄워지지 않는다
	kind_id = "wisp"
	display_name = "도깨비불"
	subtitle = "신계의 장난꾸러기"
	_visual = WispVisual.new()
	_visual.enemy = self
	add_child(_visual)
	# 몸에 닿으면 뜨겁다(작게). 걷다가 스친 건 퍼펙트 회피 대상이 아니다
	_contact = add_attack_area(Vector2(9, 9), CENTER, &"wisp", 1)
	_contact.dodgeable = false
	_glow = LightGlow.make(CENTER, 30.0, GREEN, 0.32)
	add_child(_glow)


func _ready() -> void:
	super()
	collision_mask = GameConst.L_WORLD # 떠다니는 불은 통과 발판에 걸리지 않는다
	_home = global_position
	_side = float(facing) * -1.0


func center() -> Vector2:
	return global_position + CENTER


## 예고 진행도 0~1 (그림에서 부풀기·붉은 고리에 씀)
func telegraph_k() -> float:
	return clampf(1.0 - _timer / TELEGRAPH_TIME, 0.0, 1.0) if state == S.TELEGRAPH else 0.0


## 순간이동 진행도 0~1
func blink_k() -> float:
	match state:
		S.BLINK_OUT:
			return clampf(1.0 - _blink_t / BLINK_OUT_TIME, 0.0, 1.0)
		S.BLINK_IN:
			return clampf(1.0 - _blink_t / BLINK_IN_TIME, 0.0, 1.0)
	return 0.0


func is_blinking() -> bool:
	return state == S.BLINK_OUT or state == S.BLINK_IN


func _physics_process(delta: float) -> void:
	super(delta)
	if not _alive or not is_blinking():
		return
	# 순간이동은 넉백 중에도 멈추지 않게 여기서 센다 (_ai는 넉백 중엔 불리지 않음)
	velocity = Vector2.ZERO
	_blink_t -= delta * Fx.enemy_time
	if _blink_t <= 0.0:
		if state == S.BLINK_OUT:
			_arrive()
		else:
			state = S.DRIFT
			_set_tangible(true)


func _ai(delta: float) -> void:
	if is_blinking():
		velocity = Vector2.ZERO
		return
	_timer -= delta
	_cooldown -= delta
	var p := player()
	match state:
		S.DRIFT:
			_drift(delta, p)
			if _awake and _cooldown <= 0.0 and _can_shoot(p):
				_start_telegraph()
		S.TELEGRAPH:
			velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
			if p and p.is_alive():
				aim_dir = (p.center() - center()).normalized()
				facing = 1 if aim_dir.x >= 0.0 else -1
			if _timer <= 0.0:
				_fire()
		S.SHOOT:
			velocity = velocity.move_toward(Vector2.ZERO, 220.0 * delta)
			if _timer <= 0.0:
				state = S.DRIFT


# ─── 떠다니기 ───────────────────────────────────────────

func _drift(delta: float, p: Player) -> void:
	var t := GameConst.TILE
	# 세라가 없으면 처음 자리 근처에서 살랑살랑
	var target := _home + CENTER + Vector2(sin(_t * 0.7) * 1.5 * t, sin(_t * 1.7) * 0.4 * t)
	if p and p.is_alive():
		var d := center().distance_to(p.center())
		if not _awake and d <= DETECT_T * t:
			_wake()
		if _awake and d <= DETECT_T * 1.6 * t:
			var dx := global_position.x - p.global_position.x
			if absf(dx) > 2.0 * t:
				_side = signf(dx)
			# 세라 옆 6~8T, 머리 높이 근처를 장난스럽게 오르내리며 맴돈다
			target = p.global_position + Vector2(
				_side * (PREF_DIST_T + sin(_t * 1.3) * 1.0) * t,
				-(HOVER_T + sin(_t * 1.6) * 0.7) * t)
			face_player()
	var to := target - center()
	var want := (to * 2.2).limit_length(SPEED_T * t)
	velocity = velocity.move_toward(want, ACCEL * delta)
	if is_on_wall():
		_side = -_side # 벽에 막히면 반대편으로 돌아간다


func _wake() -> void:
	if _awake:
		return
	_awake = true
	_cooldown = maxf(_cooldown, FIRST_DELAY)
	Sfx.play(&"giggle", -6.0, 0.1)


func _can_shoot(p: Player) -> bool:
	if p == null or not p.is_alive():
		return false
	if center().distance_to(p.center()) > SHOT_RANGE_T * GameConst.TILE:
		return false
	return has_los(center(), p.center())


# ─── 예고 → 부채꼴 3발 ──────────────────────────────────

func _start_telegraph() -> void:
	state = S.TELEGRAPH
	_timer = TELEGRAPH_TIME
	face_player()
	Sfx.play(&"giggle", -1.0, 0.08)


func _fire() -> void:
	var p := player()
	if p and p.is_alive():
		aim_dir = (p.center() - center()).normalized()
	var mouth := center() + aim_dir * 5.0
	for i in 3:
		var a := deg_to_rad(SHOT_SPREAD_DEG) * float(i - 1)
		shoot(mouth, aim_dir.rotated(a), SHOT_SPEED_T * GameConst.TILE, "foxwisp", {
			damage = 1, radius = 3.5, life = 3.2, cause = "wisp",
		})
	Sfx.play(&"ignite", -5.0, 0.12)
	Fx.burst(mouth, 10, {
		direction = aim_dir, spread = 40.0, speed_min = 30.0, speed_max = 90.0, lifetime = 0.3,
		gradient = Palette.fade_gradient(GREEN), size_min = 1.0, size_max = 2.5, gravity = Vector2(0, -40), add = true,
	})
	velocity = -aim_dir * 70.0 # 쏜 반동으로 살짝 뒤로
	state = S.SHOOT
	_timer = SHOOT_TIME
	_cooldown = COOLDOWN


# ─── 세 번 맞으면 순간이동 ───────────────────────────────

func _on_hit(_hit: Hit, _dir: int) -> void:
	_wake()
	_hits += 1
	if _hits % BLINK_EVERY == 0 and not is_blinking():
		_start_blink()


## 사라졌다 나타나는 동안은 맞지도, 밀리지도, 닿아도 뜨겁지도 않다
func _resists_knockback(_hit: Hit) -> bool:
	return is_blinking()


func _set_tangible(on: bool) -> void:
	_hurtbox.set_deferred("monitorable", on)
	_contact.active = on


func _start_blink() -> void:
	blink_to = _pick_blink_target()
	state = S.BLINK_OUT
	_blink_t = BLINK_OUT_TIME
	_knock_timer = 0.0
	_set_tangible(false)
	_cooldown = maxf(_cooldown, 0.9) # 나타나자마자 쏘지는 않는다
	var c := center()
	Sfx.play(&"whoosh", -3.0, 0.1)
	Fx.ring(c, 3.0, 18.0, GREEN, 0.25, 2.0)
	Fx.burst(c, 16, {
		spread = 180.0, speed_min = 30.0, speed_max = 100.0, damping = 80.0, lifetime = 0.4,
		gradient = Palette.fade_gradient(GREEN), size_min = 1.0, size_max = 2.5, gravity = Vector2(0, -30), add = true,
	})
	# 어디로 갔는지 보이게: 출발점 → 도착점 사이에 불씨 자국
	for k in range(1, 5):
		var at := c.lerp(blink_to, k / 5.0)
		Fx.burst(at, 3, {
			spread = 180.0, speed_min = 5.0, speed_max = 20.0, lifetime = 0.35 + k * 0.05,
			gradient = Palette.fade_gradient(Color(GREEN, 0.8)), size_min = 1.0, size_max = 1.8,
			gravity = Vector2(0, -20), add = true,
		})


func _arrive() -> void:
	global_position = blink_to - CENTER
	velocity = Vector2.ZERO
	state = S.BLINK_IN
	_blink_t = BLINK_IN_TIME
	Fx.ring(blink_to, 20.0, 4.0, GREEN, 0.22, 2.0)
	Fx.burst(blink_to, 10, {
		spread = 180.0, speed_min = 20.0, speed_max = 70.0, lifetime = 0.3,
		gradient = Palette.fade_gradient(GREEN), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, -30), add = true,
	})
	Sfx.play(&"giggle", -5.0, 0.15)


## 3~4T 떨어진, 벽에 박히지 않는 자리 (세라에게서 멀어지는 쪽·위쪽을 먼저 본다)
func _pick_blink_target() -> Vector2:
	var t := GameConst.TILE
	var c := center()
	var away := -float(dir_to_player())
	var angles: Array[float] = [-0.55, -1.15, 0.0, -2.0, 0.45, 2.6]
	if randf() < 0.5:
		angles[0] = -1.15
		angles[1] = -0.55
	var space := get_world_2d().direct_space_state
	var shape := RectangleShape2D.new()
	shape.size = body_size + Vector2(6, 6)
	var best := c
	var best_len := 0.0
	for a in angles:
		var dir := Vector2(away * cos(a), sin(a))
		var dist := (BLINK_DIST_T + randf_range(-0.4, 0.5)) * t
		var to := c + dir * dist
		var ray := space.intersect_ray(PhysicsRayQueryParameters2D.create(c, to + dir * 10.0, GameConst.L_WORLD))
		if not ray.is_empty():
			var free_len := c.distance_to(ray.position) - 14.0
			if free_len > best_len:
				best_len = free_len
				best = c + dir * free_len
			continue
		var q := PhysicsShapeQueryParameters2D.new()
		q.shape = shape
		q.transform = Transform2D(0.0, to)
		q.collision_mask = GameConst.L_WORLD
		if space.intersect_shape(q, 1).is_empty():
			return to
	return best
