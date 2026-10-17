extends StarConstruct
## 별 창기사 (docs/archive/sera/chapter5.md 4절): 아우렐리아를 흉내 낸 별빛 구조체. 신전 시련의 상대(아우렐리아와 함께).
## 아우렐리아의 짧은 판: 신성 돌진(예고선 → 플랫폼을 가로지르는 별빛 돌진), 찌르기. 큰 별 창기사(grand)는 빛의 창 비.
##   돌진: 0.7초 동안 창을 뒤로 당김 + 바라보는 쪽으로 붉은 띠(돌진 길) → 22칸/초로 꿰뚫고 지나감 → 벽·끝에서 0.9초 빈틈(피해 1.25배)
##   찌르기: 가까우면 0.4초 예고 뒤 앞을 길게 찌름
##   빛의 창 비(grand): 창을 하늘로 → 세라 둘레 다섯 곳에 붉은 기둥 → 빛의 창이 꽂힘
## 돌진 중엔 앞에서 오는 화염탄을 창끝으로 흘린다(피해 30%). 옆·뒤·불기둥은 그대로.

const T := GameConst.TILE
const WALK := 2.2
const CHARGE_WIND := 0.7
const CHARGE_SPEED := 22.0
const CHARGE_MAX := 14.0
const THRUST_WIND := 0.4

var _charge_area: EnemyAttackArea
var _thrust: EnemyAttackArea
var _charge_left := 0.0
var _attacks := 0


func _build() -> void:
	_setup_construct(1400, Vector2(16, 40), "별 창기사", "빛을 지키던 창의 그림자", "star_lancer", "lancer")
	_charge_area = add_attack_area(Vector2(34, 30), Vector2(14, -18), &"star_lancer", 1)
	_charge_area.active = false
	_thrust = add_attack_area(Vector2(46, 14), Vector2(28, -20), &"star_lancer", 1)
	_thrust.active = false
	set_state("idle", 0.7)


func _ai(delta: float) -> void:
	_tick(delta)
	var gk := 1.25 if grand else 1.0
	place_area(_charge_area, Vector2(14, -18) * gk)
	place_area(_thrust, Vector2(28, -20) * gk)
	var p := player()
	if not engaged or p == null or not p.is_alive():
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		_charge_area.active = false
		_thrust.active = false
		return
	var dx := p.global_position.x - global_position.x
	var adx := absf(dx)
	match state:
		"idle", "walk":
			_cd -= delta
			facing = 1 if dx > 0 else -1
			var want := 0.0
			if adx > 4.0 * T and adx < 16.0 * T and not ledge_ahead():
				want = facing * WALK * T
			velocity.x = move_toward(velocity.x, want, 400.0 * delta)
			state = "walk" if want != 0.0 else "idle"
			if _cd <= 0.0 and adx < 18.0 * T and absf(p.global_position.y - global_position.y) < 5.0 * T:
				_choose(adx)
		"windup":
			velocity.x = 0.0
			if _timer <= 0.0:
				set_state("charge", 1.2)
				_charge_left = CHARGE_MAX * T
				_charge_area.active = true
				_charge_area.dodgeable = true
				StArt.sfx(&"holy_charge", &"charger_charge", 0.0)
				Fx.shake(0.15, 0.2)
		"charge":
			velocity.x = facing * CHARGE_SPEED * T
			_charge_left -= CHARGE_SPEED * T * delta
			if fmod(_t, 0.04) < delta:
				add_afterimage("charge")
				Fx.burst(global_position + Vector2(-facing * 8, -18), 3, {direction = Vector2(-facing, 0), spread = 20.0, speed_min = 30.0, speed_max = 80.0,
					lifetime = 0.3, gradient = Palette.fade_gradient(StArt.STAR), add = true})
			if _charge_left <= 0.0 or is_on_wall() or ledge_ahead(20.0):
				_charge_area.active = false
				velocity.x = facing * 2.0 * T
				set_state("recover", Difficulty.rest(0.9))
				Fx.shake(0.2, 0.2)
				StArt.sfx(&"holy_hit", &"slam", -4.0)
		"thrust_wind":
			velocity.x = 0.0
			if _timer <= 0.0:
				_thrust.active = true
				_thrust.dodgeable = true
				velocity.x = facing * 4.0 * T
				set_state("thrust", 0.18)
				StArt.sfx(&"spear", &"swing", 0.0)
		"thrust":
			velocity.x = move_toward(velocity.x, 0.0, 1400.0 * delta)
			if _timer <= 0.0:
				_thrust.active = false
				set_state("recover", Difficulty.rest(0.6))
		"rain_wind":
			velocity.x = 0.0
			if _timer <= 0.0:
				_spear_rain(p)
				set_state("recover", Difficulty.rest(0.9))
		"recover":
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
			if _timer <= 0.0:
				_cd = Difficulty.rest(0.7 if grand else 1.0)
				set_state("idle", 0.2)


func _choose(adx: float) -> void:
	_attacks += 1
	face_player()
	if grand and _attacks % 3 == 0:
		set_state("rain_wind", Difficulty.telegraph(0.7))
		StArt.sfx(&"holy_charge", &"charger_windup", -6.0)
		return
	if adx < 3.5 * T:
		set_state("thrust_wind", Difficulty.telegraph(THRUST_WIND))
		StArt.sfx(&"charger_windup", &"charger_windup", -4.0)
		return
	set_state("windup", Difficulty.telegraph(CHARGE_WIND))
	StArt.sfx(&"charger_windup", &"charger_windup", 0.0)
	var reach := absf(wall_x(CHARGE_MAX * T, -18.0) - global_position.x) + 20.0
	StStrike.spawn(global_position + Vector2(facing * reach * 0.5, -18), "band", Vector2(reach, 30 * (1.25 if grand else 1.0)), _timer, {"damage": 0, "hold": 0.0, "fade": 0.05})


func _spear_rain(p: Player) -> void:
	for i in 5:
		var x := p.global_position.x + (i - 2) * 3.0 * T + randf_range(-8, 8)
		var y := ground_y(x, p.global_position.y - 24.0)
		StStrike.spawn(Vector2(x, y), "pillar", Vector2(14, 10.0 * T), Difficulty.telegraph(0.9) + absf(i - 2) * 0.12, {"damage": 1, "cause": "star_lancer", "hold": 0.14, "fade": 0.35, "sound": "holy_hit", "shake": 0.06})


func modify_damage(hit: Hit) -> float:
	if state == "charge" and hit.kind in [&"bolt", &"bolt_heavy"]:
		var from_front := signf(hit.source_pos.x - global_position.x) == float(facing)
		if from_front:
			return 0.3
	if state == "recover":
		return 1.25
	return 1.0


func _resists_knockback(hit: Hit) -> bool:
	return state in ["charge", "thrust"] and not hit.breaks_charge
