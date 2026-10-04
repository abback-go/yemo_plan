extends "res://enemies/ch2/leonie_base.gd"
## 레오니 — 은사자 기사단 연무장 목검 대련 (docs/chapter2.md 2절 5, 4절). 체력 싸움이 아니다.
## 끝나는 조건: 세라가 **세 번 맞히기**(result = "hits") 또는 **60초 버티기**(result = "time").
##   세라 체력이 1이 되면 레오니가 먼저 멈춘다(result = "yield", "그만. 오늘은 여기까지다.") — 대련이라 쓰러뜨리지 않는다.
## 끝나면 defeated 신호(대본이 이어받음). hits_taken = 맞은 횟수, time_left = 남은 초.
## 맛보기 기술: 두 번 베기(예고 0.45초씩), 짧은 잔상 돌진(예고 0.6초), 받아치기 자세(정면 화염탄을 목검으로 쳐 냄 → 불기둥이면 깨지고 1번으로 침).
## 맞을 때마다 0.6초 동안은 더 맞지 않는다(한 번에 여러 번 세지 않게). 체력바 = 남은 "맞히기" 칸.

const SPAR_TIME := 60.0
const HITS_TO_WIN := 3
const HIT_GRACE := 0.6
const WALK_T := 2.2

enum S { IDLE, STALK, COMBO_WINDUP, COMBO_HIT, DASH_WINDUP, DASH, GUARD, FLINCH, BACKSTEP, RECOVER, DONE }

var hits_taken := 0
var time_left := SPAR_TIME
var result := "" ## hits · time · yield
var state: S = S.IDLE
var _timer := 0.0
var _dur := 0.0
var _combo := 0
var _grace := 0.0
var _dash_from := 0.0
var _dash_len := 0.0
var _last := ""
var _slash: EnemyAttackArea
var _body_hit: EnemyAttackArea


func _init() -> void:
	engaged = false


func _build() -> void:
	max_hp = HITS_TO_WIN
	body_size = Vector2(14, 38)
	knock_mult = 0.0
	launch_mult = 0.0
	is_boss = true
	is_elite = false
	respawns = true
	display_name = "레오니"
	subtitle = "목검 대련 — 세 번 맞히거나 60초 버티기"
	kind_id = "leonie_spar"
	_setup_visual(true)
	_slash = add_attack_area(Vector2(44, 30), Vector2(22, -18), &"leonie_spar", 1)
	_slash.active = false
	_body_hit = add_attack_area(Vector2(16, 32), Vector2(0, -18), &"leonie_spar", 1)
	_body_hit.active = false


func _ready() -> void:
	super()
	# 난이도 배율과 상관없이 "맞히기 3칸"
	max_hp = HITS_TO_WIN
	hp = HITS_TO_WIN


func _enter(s: S, d: float) -> void:
	state = s
	_timer = d
	_dur = d


func progress() -> float:
	return clampf(1.0 - _timer / _dur, 0.0, 1.0) if _dur > 0.0 else 1.0


func _ai(delta: float) -> void:
	var t := GameConst.TILE
	_timer -= delta
	_grace -= delta
	warn(0.0)
	var p := player()
	if state == S.DONE:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		if result != "hits":
			pose("idle")
		return
	if not engaged or p == null:
		pose("idle")
		velocity.x = 0.0
		return
	if state == S.IDLE:
		_enter(S.STALK, 1.0)
	time_left = maxf(time_left - delta, 0.0)
	subtitle = "목검 대련 — 남은 시간 %d초" % int(ceil(time_left))
	if p.hp <= 1 and p.is_alive():
		_finish("yield")
		return
	if time_left <= 0.0:
		_finish("time")
		return
	var dx := p.global_position.x - global_position.x
	match state:
		S.STALK:
			face_player()
			pose("run" if absf(velocity.x) > 10.0 else "idle")
			var want := signf(dx) * WALK_T * t if absf(dx) > 2.2 * t else 0.0
			velocity.x = move_toward(velocity.x, want, 500.0 * delta)
			if _timer <= 0.0 and is_on_floor():
				_choose(absf(dx) / t)
		S.COMBO_WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			pose("windup")
			warn(progress())
			if _timer <= 0.0:
				_enter(S.COMBO_HIT, 0.25)
				velocity.x = facing * 6.0 * t
				pose("attack" if _combo == 0 else "attack2")
				strike(_slash, Vector2(22, -18), 0.12)
				KE.snd(&"sword_slash", &"swing", 0.0)
		S.COMBO_HIT:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _timer <= 0.0:
				_combo += 1
				if _combo < 2:
					face_player()
					_enter(S.COMBO_WINDUP, Difficulty.telegraph(0.45))
				else:
					_enter(S.RECOVER, Difficulty.rest(0.9))
		S.DASH_WINDUP:
			velocity.x = 0.0
			pose("guard" if progress() < 0.5 else "charge")
			warn(progress())
			if _timer <= 0.0:
				_dash_from = global_position.x
				_dash_len = minf(6.0 * t, _room_ahead(facing, 6.0 * t))
				_enter(S.DASH, 0.22)
				_after_every = 0.03
				strike(_body_hit, Vector2(4, -18), 0.22)
				KE.snd(&"dash", &"dash", 0.0)
		S.DASH:
			pose("charge")
			velocity.x = facing * 30.0 * t
			if absf(global_position.x - _dash_from) >= _dash_len or _timer <= 0.0 or is_on_wall():
				_after_every = 0.0
				velocity.x = 0.0
				pose("attack")
				strike(_slash, Vector2(22, -18), 0.12)
				KE.snd(&"sword_slash", &"swing", 0.0)
				_enter(S.RECOVER, Difficulty.rest(1.0))
		S.GUARD:
			velocity.x = 0.0
			face_player()
			pose("guard")
			if _timer <= 0.0:
				_enter(S.STALK, 0.6)
		S.FLINCH:
			pose("hurt")
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
			if _timer <= 0.0:
				_enter(S.BACKSTEP, 0.35)
				face_player()
				velocity = Vector2(-facing * 160.0, -180.0)
		S.BACKSTEP:
			pose("charge")
			if is_on_floor() and _dur - _timer > 0.1:
				_enter(S.STALK, Difficulty.rest(0.8))
		S.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if vis.pose_t > 0.3:
				pose("idle")
			if _timer <= 0.0:
				_enter(S.STALK, 0.4)


func _choose(adx: float) -> void:
	face_player()
	var pick := "combo"
	if adx > 6.0:
		pick = "dash"
	elif adx > 3.5:
		pick = ["dash", "guard", "combo"][randi() % 3]
	else:
		pick = ["combo", "combo", "guard"][randi() % 3]
	if pick == _last:
		pick = "combo" if pick != "combo" else "guard"
	_last = pick
	match pick:
		"combo":
			_combo = 0
			_enter(S.COMBO_WINDUP, Difficulty.telegraph(0.45))
			KE.snd(&"swing", &"swing", -10.0)
		"dash":
			_enter(S.DASH_WINDUP, Difficulty.telegraph(0.6))
		"guard":
			_enter(S.GUARD, 2.0)


func _finish(why: String) -> void:
	if state == S.DONE:
		return
	result = why
	_enter(S.DONE, 0.0)
	_after_every = 0.0
	for c in get_children():
		if c is EnemyAttackArea:
			(c as EnemyAttackArea).active = false
	# _alive는 그대로 둔다(물리·자세는 계속). is_alive()가 false를 돌려 체력바가 사라지고 대본의 wait_enemy가 끝난다
	defeated.emit(self)
	KE.snd(&"clear", &"clear", -2.0)
	if why == "hits":
		var tw := create_tween()
		tw.tween_interval(0.7)
		tw.tween_callback(func() -> void: pose("idle"))


func is_alive() -> bool:
	return state != S.DONE


func modify_damage(_hit: Hit) -> float:
	return 0.0 # 체력 대신 맞힌 횟수를 센다 (take_hit에서 처리)


func take_hit(hit: Hit) -> void:
	if state == S.DONE or not engaged:
		return
	if _grace > 0.0:
		return
	# 받아치기 자세: 정면 불은 목검으로 쳐 냄, 불기둥·방벽 등은 자세를 깨고 1번으로 침
	if state == S.GUARD and hit_side(hit, 4.0, 1) > 0 and not hit.kind in GUARD_BREAK:
		parry_fx(hit)
		return
	if state in [S.DASH] and hit.kind in PARRYABLE and hit_side(hit, 4.0, 1) > 0:
		parry_fx(hit)
		return
	hits_taken += 1
	hp = maxi(HITS_TO_WIN - hits_taken, 0)
	_grace = HIT_GRACE
	_flash = tuning.enemy_flash_time + 0.06
	Fx.hitstop(0.06)
	Fx.shake(0.12)
	KE.snd(&"hit", &"hit", -2.0)
	Fx.burst(global_position + Vector2(0, -22), 10, {spread = 180.0, speed_min = 40.0, speed_max = 110.0, lifetime = 0.3,
		gradient = Palette.fade_gradient(Color(1.0, 0.85, 0.6)), size_min = 1.0, size_max = 2.0})
	var pl := player()
	if pl:
		pl.on_hit_landed(hit)
	if GameState.settings.get("damage_numbers", true):
		Fx.damage_number(global_position + Vector2(0, -44), hits_taken, true)
	if hits_taken >= HITS_TO_WIN:
		pose("hurt")
		_finish("hits")
		return
	_area_timers.clear()
	_slash.active = false
	_body_hit.active = false
	_after_every = 0.0
	_enter(S.FLINCH, 0.3)
	velocity.x = -facing * 60.0
