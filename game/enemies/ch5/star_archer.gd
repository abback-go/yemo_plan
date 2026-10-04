extends StarConstruct
## 별 궁수 (docs/chapter5.md 4절): 엘라리엔을 흉내 낸 별빛 구조체. 엘프 숲 시련의 상대(엘라리엔이 먼 가지에서 엄호).
## 거리를 벌리고 쏜다: 가까이 붙으면 별가루로 흩어졌다가 멀리서 모인다(3초에 한 번).
##   저격: 활시위를 당기는 동안 가는 예고선이 세라를 따라온다 → 마지막 0.25초는 붉게 굳음 → 아주 빠른 빛 화살 (선에서 비키기)
##   부채 화살: 0.6초 → 세 발이 부채꼴로
##   별 화살비: 하늘로 쏘아 올림 → 세라 주위 바닥 네 곳에 붉은 기둥 예고 → 0.9초 뒤 쏟아짐
##   큰 별 궁수(grand): 화살비가 별자리 모양 일곱 곳 + 저격 두 번 연속

const T := GameConst.TILE
const AIM_TRACK := 0.75
const AIM_LOCK := 0.25
const ARROW_SPEED := 28.0
const KEEP_MIN := 6.0
const KEEP_MAX := 12.0

var _aim_line: StStrike
var _shots_left := 0
var _attacks := 0


func _build() -> void:
	_setup_construct(1000, Vector2(14, 34), "별 궁수", "바람을 읽던 눈의 그림자", "star_archer", "archer")
	set_state("idle", 0.8)


func _ai(delta: float) -> void:
	_tick(delta)
	var p := player()
	if not engaged or p == null or not p.is_alive():
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		_clear_aim()
		return
	var dx := p.global_position.x - global_position.x
	var adx := absf(dx)
	match state:
		"idle", "walk":
			_cd -= delta
			facing = 1 if dx > 0 else -1
			var want := 0.0
			if adx < KEEP_MIN * T and not ledge_at(-facing):
				# 뒷걸음질 (바라보는 반대쪽)
				want = -facing * 2.2 * T
				if _blink_cd <= 0.0 and adx < 3.5 * T:
					_blink_away(p)
					return
			elif adx > KEEP_MAX * T:
				want = facing * 2.0 * T
			velocity.x = move_toward(velocity.x, want, 500.0 * delta)
			state = "walk" if absf(want) > 0.0 else "idle"
			if _cd <= 0.0 and adx < 22.0 * T:
				_choose(adx)
		"aim":
			velocity.x = 0.0
			face_player()
			if is_instance_valid(_aim_line):
				_aim_line.global_position = _bow_pos()
				if _timer > Difficulty.telegraph(AIM_LOCK):
					_aim_line.to = p.center()
			if _timer <= 0.0:
				_release_aimed()
		"fan_wind":
			velocity.x = 0.0
			face_player()
			if _timer <= 0.0:
				var base := (p.center() - _bow_pos()).normalized()
				for i in 3:
					StShot.fire(_bow_pos(), base.rotated((i - 1) * 0.2), ARROW_SPEED * 0.75 * T, "arrow", {"radius": 3.0, "damage": 1, "cause": "star_archer", "life": 2.0})
				StArt.sfx(&"arrow_shot", &"sniper_shot", -2.0)
				set_state("release", 0.3)
		"rain_wind":
			velocity.x = 0.0
			if _timer <= 0.0:
				_arrow_rain(p)
				set_state("release", 0.4)
		"release":
			if _timer <= 0.0:
				if _shots_left > 0:
					_shots_left -= 1
					_start_aim()
				else:
					_cd = Difficulty.rest(1.1 if not grand else 0.8)
					set_state("idle", 0.2)


func _bow_pos() -> Vector2:
	return global_position + Vector2(facing * 12.0 * (1.3 if grand else 1.0), -22.0 * (1.3 if grand else 1.0))


func _choose(adx: float) -> void:
	_attacks += 1
	face_player()
	var roll := randf()
	if _attacks % 3 == 0:
		set_state("rain_wind", Difficulty.telegraph(0.5))
		StArt.sfx(&"bow_draw", &"sniper_aim", -2.0)
	elif adx < 9.0 * T and roll < 0.4:
		set_state("fan_wind", Difficulty.telegraph(0.6))
		StArt.sfx(&"bow_draw", &"sniper_aim", -2.0)
	else:
		_shots_left = 1 if grand else 0
		_start_aim()


func _start_aim() -> void:
	var p := player()
	if p == null:
		return
	set_state("aim", Difficulty.telegraph(AIM_TRACK + AIM_LOCK))
	StArt.sfx(&"bow_draw", &"sniper_aim", -2.0)
	_clear_aim()
	_aim_line = StStrike.spawn(_bow_pos(), "beam", Vector2(0, 3), _timer, {"to": p.center(), "damage": 0, "hold": 0.0, "fade": 0.05})


func _release_aimed() -> void:
	var to := _aim_line.to if is_instance_valid(_aim_line) else global_position + Vector2(facing * 100, 0)
	_clear_aim()
	var dir := (to - _bow_pos()).normalized()
	StShot.fire(_bow_pos(), dir, ARROW_SPEED * T, "arrow", {"radius": 3.0, "damage": 1, "cause": "star_archer", "life": 2.0})
	StArt.sfx(&"arrow_shot", &"sniper_shot", 0.0)
	Fx.burst(_bow_pos(), 8, {direction = dir, spread = 30.0, speed_min = 60.0, speed_max = 140.0, lifetime = 0.25, gradient = Palette.fade_gradient(StArt.STAR), add = true})
	set_state("release", 0.35)


func _clear_aim() -> void:
	if is_instance_valid(_aim_line):
		_aim_line.queue_free()
	_aim_line = null


func _arrow_rain(p: Player) -> void:
	StArt.sfx(&"arrow_shot", &"sniper_shot", -2.0)
	for i in 5:
		StShot.fire(_bow_pos(), Vector2(randf_range(-0.2, 0.2), -1).normalized(), 30.0 * T, "arrow", {"radius": 2.0, "damage": 0, "life": 0.4, "hits_world": false})
	var n := 7 if grand else 4
	var span := 9.0 * T if grand else 5.0 * T
	var gy := ground_y(p.global_position.x, p.global_position.y - 8.0)
	for i in n:
		var x := p.global_position.x + lerpf(-span, span, float(i) / (n - 1)) + randf_range(-6, 6)
		var y := ground_y(x, gy - 16.0)
		StStrike.spawn(Vector2(x, y), "pillar", Vector2(12, 9.0 * T), Difficulty.telegraph(0.9) + i * 0.06, {"damage": 1, "cause": "star_archer", "hold": 0.12, "fade": 0.3, "sound": "arrow_hit"})


func _blink_away(p: Player) -> void:
	_blink_cd = 3.0
	var room_w := World.get_world().room.size_px.x if World.get_world() and World.get_world().room else 640.0
	var side := 1.0 if p.global_position.x < room_w * 0.5 else -1.0
	var x := clampf(p.global_position.x + side * randf_range(8.0, 11.0) * T, 2.0 * T, room_w - 2.0 * T)
	star_blink(Vector2(x, ground_y(x, global_position.y - 2.0 * T)))
	facing = 1 if p.global_position.x > x else -1
	_cd = minf(_cd, 0.4)


func _die(dir: int) -> void:
	_clear_aim()
	super._die(dir)
