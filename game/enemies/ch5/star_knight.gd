extends StarConstruct
## 별 기사 (docs/archive/sera/chapter5.md 4절): 레오니를 흉내 낸 별빛 구조체. 제국 시련의 상대(레오니와 함께 싸운다).
## 레오니의 짧은 판: 잔상 돌진 베기, 3연 베기, 받아치기 자세, 검압 파동. 큰 별 기사(grand)는 "별의 일섬"까지.
##   잔상 돌진: 0.55초 웅크림(검 끝이 붉게, 바닥에 붉은 선) → 7칸을 잔상 셋과 함께 가르며 지나감 → 0.7초 빈틈
##   3연 베기: 가까우면 짧은 예고마다 앞을 벤다 (마지막이 가장 크다)
##   받아치기: 검을 세워 1.4초 — 그동안 화염탄·여우불은 베어 내고(무효) 곧장 반격 돌진(0.3초 번쩍임 예고).
##             불기둥·화염 폭풍·방벽·되쏜 탄은 자세를 깨뜨려 1초 휘청(피해 1.3배)
##   검압 파동: 머리 위로 들어 내리치면 바닥을 달리는 빛 파동(점프로 넘기)
##   별의 일섬(grand): 1.3초 칼집 자세 → 방 전체를 가로지르는 빛의 띠 (대시 무적으로 피하거나 높은 발판으로)

const T := GameConst.TILE
const WALK := 2.8
const DASH_WIND := 0.55
const DASH_SPEED := 26.0
const DASH_DIST := 7.0
const COMBO_WIND := 0.3
const COMBO_HIT := 0.12
const GUARD_TIME := 1.4
const WAVE_WIND := 0.6
const IAI_WIND := 1.3
const UNBLOCKABLE := Hit.PASS_SHIELD_STAR_KNIGHT

var _slash: EnemyAttackArea
var _dash_area: EnemyAttackArea
var _dash_left := 0.0
var _combo_n := 0
var _countered := false
var _since_guard := 0.0
var _attacks := 0
var _ai_t := 0.0


func _build() -> void:
	_setup_construct(1300, Vector2(16, 36), "별 기사", "검 하나로 선 자의 그림자", "star_knight", "knight")
	_slash = add_attack_area(Vector2(34, 30), Vector2(18, -18), &"star_knight", 1)
	_slash.active = false
	_dash_area = add_attack_area(Vector2(26, 30), Vector2(6, -16), &"star_knight", 1)
	_dash_area.active = false
	set_state("idle", 0.6)


func _ai(delta: float) -> void:
	_tick(delta)
	_since_guard += delta
	place_area(_slash, Vector2(18, -18) * (1.25 if grand else 1.0))
	place_area(_dash_area, Vector2(6, -16))
	var p := player()
	if not engaged or p == null or not p.is_alive():
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		_slash.active = false
		_dash_area.active = false
		return
	var dx := p.global_position.x - global_position.x
	var adx := absf(dx)
	match state:
		"idle", "walk":
			_cd -= delta
			if adx > 2.5 * T:
				facing = 1 if dx > 0 else -1
			var want := 0.0
			if adx > 3.0 * T and adx < 14.0 * T and not ledge_ahead():
				want = facing * WALK * T
				state = "walk"
			else:
				state = "idle"
			velocity.x = move_toward(velocity.x, want, 500.0 * delta)
			if _cd <= 0.0 and adx < 16.0 * T and absf(p.global_position.y - global_position.y) < 4.0 * T:
				_choose(adx)
		"windup":
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _timer > 0.15:
				face_player()
			if _timer <= 0.0:
				_start_dash()
		"dash":
			velocity.x = facing * DASH_SPEED * T
			_dash_left -= DASH_SPEED * T * delta
			if fmod(_t, 0.05) < delta:
				add_afterimage("dash")
			if _dash_left <= 0.0 or is_on_wall() or ledge_ahead(18.0):
				_dash_area.active = false
				_slash.active = true
				_slash.dodgeable = true
				set_state("slash", 0.18)
				StArt.sfx(&"sword_slash", &"swing", 0.0)
				velocity.x = facing * 3.0 * T
		"slash":
			velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)
			if _timer <= 0.0:
				_slash.active = false
				set_state("recover", Difficulty.rest(0.7))
		"combo_wind":
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _timer <= 0.0:
				_slash.active = true
				_slash.dodgeable = true
				velocity.x = facing * (5.0 + _combo_n * 2.0) * T
				set_state("combo", COMBO_HIT)
				StArt.sfx(&"sword_slash", &"swing", -2.0 + _combo_n)
		"combo":
			velocity.x = move_toward(velocity.x, 0.0, 1500.0 * delta)
			if _timer <= 0.0:
				_slash.active = false
				_combo_n += 1
				if _combo_n < 3:
					face_player()
					set_state("combo_wind", Difficulty.telegraph(COMBO_WIND * (0.85 if _combo_n == 1 else 1.1)))
				else:
					set_state("recover", Difficulty.rest(0.8))
		"guard":
			velocity.x = 0.0
			face_player()
			if _countered:
				_countered = false
				set_state("counter_flash", Difficulty.telegraph(0.3))
				Fx.flash(Color(1.0, 0.95, 0.8, 0.25), 0.1)
			elif _timer <= 0.0:
				_since_guard = 0.0
				set_state("idle", 0.4)
		"counter_flash":
			velocity.x = 0.0
			if _timer <= 0.0:
				_start_dash(0.75)
		"wave_wind":
			velocity.x = 0.0
			if _timer <= 0.0:
				set_state("wave", 0.35)
				_fire_wave()
		"wave":
			if _timer <= 0.0:
				set_state("recover", Difficulty.rest(0.6))
		"iai":
			velocity.x = 0.0
			if _timer <= 0.0:
				set_state("iai_cut", 0.5)
				StArt.sfx(&"sword_slash", &"swing", 4.0)
				# 반대편으로 순간이동 (베고 지나간 자리)
				var to_x := clampf(global_position.x + facing * 12.0 * T, global_position.x - 12.0 * T, global_position.x + 12.0 * T)
				to_x = wall_x(12.0 * T)
				add_afterimage("dash")
				global_position.x = to_x
				add_afterimage("iai_cut")
		"iai_cut":
			if _timer <= 0.0:
				set_state("recover", Difficulty.rest(1.0))
		"recover", "stagger":
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			if _timer <= 0.0:
				_cd = Difficulty.rest(0.5 if grand else 0.8)
				set_state("idle", 0.3)


func _choose(adx: float) -> void:
	_attacks += 1
	face_player()
	if grand and _attacks % 4 == 0:
		_start_iai()
		return
	if adx < 3.5 * T:
		if _since_guard > 5.0 and randf() < 0.35:
			set_state("guard", GUARD_TIME)
			StArt.sfx(&"parry", &"block", -4.0)
			return
		_combo_n = 0
		set_state("combo_wind", Difficulty.telegraph(COMBO_WIND))
		StArt.sfx(&"sword_clash", &"chain", -8.0)
	elif adx > 7.0 * T and randf() < 0.45:
		set_state("wave_wind", Difficulty.telegraph(WAVE_WIND))
		StArt.sfx(&"sword_wave", &"charger_windup", -4.0)
	else:
		set_state("windup", Difficulty.telegraph(DASH_WIND))
		StArt.sfx(&"charger_windup", &"charger_windup", -2.0)
		# 바닥의 붉은 돌진 선
		var len := DASH_DIST * T + 24.0
		StStrike.spawn(global_position + Vector2(facing * len * 0.5, -14), "band", Vector2(len, 22), _timer, {"hold": 0.0, "fade": 0.05, "damage": 0})


func _start_dash(dist_mult := 1.0) -> void:
	set_state("dash", 0.6)
	_dash_left = DASH_DIST * T * dist_mult
	_dash_area.active = true
	_dash_area.dodgeable = true
	StArt.sfx(&"dash", &"dash", 0.0)
	add_afterimage("windup")


func _fire_wave() -> void:
	Fx.shake(0.15, 0.15)
	StArt.sfx(&"sword_wave", &"slam", -2.0)
	var s := StShot.fire(global_position + Vector2(facing * 18, -7), Vector2(facing, 0), 10.0 * T, "wave", {"radius": 6.0, "damage": 1, "cause": "star_knight", "life": 2.5})
	s.hits_world = true


func _start_iai() -> void:
	set_state("iai", Difficulty.telegraph(IAI_WIND))
	StArt.sfx(&"bow_draw", &"charger_windup", -2.0)
	var y := global_position.y - 14.0
	var w := 40.0 * T
	StStrike.spawn(Vector2(global_position.x + facing * 6.0 * T, y), "band", Vector2(w, 30), _timer, {"hold": 0.12, "fade": 0.35, "damage": 1, "cause": "star_knight", "shake": 0.35})


func modify_damage(hit: Hit) -> float:
	if state == "guard":
		if hit.kind in UNBLOCKABLE:
			_break_guard()
			return 1.3
		_countered = true
		return 0.0
	if state == "stagger":
		return 1.3
	return 1.0


func _break_guard() -> void:
	set_state("stagger", 1.0)
	StArt.sfx(&"parry", &"block", 0.0)
	Fx.burst(global_position + Vector2(facing * 8, -20), 14, {spread = 120.0, speed_min = 40.0, speed_max = 140.0, lifetime = 0.4,
		gradient = Palette.fade_gradient(StArt.STAR), add = true})


func _on_blocked(hit: Hit) -> void:
	super._on_blocked(hit)
	# 검으로 베어 냄: 별빛 불꽃
	Fx.burst(global_position + Vector2(facing * 10, -20), 10, {direction = Vector2(facing, -0.4), spread = 50.0, speed_min = 60.0, speed_max = 150.0,
		lifetime = 0.25, gradient = Palette.fade_gradient(StArt.STAR), add = true})
	StArt.sfx(&"parry", &"block", 0.0)


func _resists_knockback(hit: Hit) -> bool:
	return state in ["dash", "slash", "iai", "guard"] and not hit.breaks_charge
