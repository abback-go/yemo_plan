class_name ShadowHound
extends EnemyBase
## 그림자 늑대 (docs/archive/sera/chapter1.md 7절, 12.4절, 12.5절): 봉인에서 새어 나온 굶주림이 늑대 꼴을 한 것. 봉인 회랑.
## - 잠행: 바닥으로 스며들어 그림자 웅덩이가 되어 13 T/s로 미끄러져 온다(무적, 탄이 지나감).
## - 세라 발밑에 0.5초 물결 예고 → 솟아오르며 물기(피해 1, 퍼펙트 회피 가능) → 짧은 돌진.
## - 공략 포인트: 솟아오른 직후 1.2초는 숨을 고르며 빈틈(피해 1.5배).
## - 여우창문 원 안에서는 스며들지 못한다. 창문이 처음 붙잡으면 1.6초 어리둥절(빈틈) → 땅 위에서 으르렁 → 덮치기로 싸운다.
##   푸른 여우불이 잠행 중인 웅덩이에 닿아도 끌려 나와 어리둥절해진다 (12.4절 "잠행 불가").

enum S { PROWL, SINK, SUBMERGED, RIPPLE, ERUPT, DASH, OPEN, DAZED, GROWL, LUNGE }

const T := GameConst.TILE
const PROWL_SPEED_T := 4.5
const SINK_TIME := 0.4
const SLIDE_SPEED_T := 13.0
const SLIDE_MAX_TIME := 2.4
const RIPPLE_TIME := 0.5
const ERUPT_HEIGHT_T := 2.6
const DASH_SPEED_T := 15.0
const DASH_TIME := 0.28
const OPEN_TIME := 1.2
const DAZE_TIME := 1.6
const GROWL_TIME := 0.55
const LUNGE_SPEED_T := 13.0
const LUNGE_HEIGHT_T := 1.4
const OPEN_DAMAGE_MULT := 1.5

var state: S = S.PROWL
var strike_x := 0.0 ## 물결 예고 위치 (전역 x)
var _timer := 0.0
var _state_len := 1.0
var _air_t := 0.0
var _hidden := false ## 잠행 중 (피격 판정 꺼짐)
var _caught_by: Array[int] = [] ## 이미 붙잡힌 여우창문들의 instance id
var _bite: EnemyAttackArea
var _body_area: EnemyAttackArea


func _build() -> void:
	max_hp = 340
	body_size = Vector2(34, 24)
	display_name = "그림자 늑대"
	subtitle = "봉인에서 새어 나온 굶주림"
	kind_id = "shadow_hound"
	knock_mult = 0.7
	_visual = ShadowHoundVisual.new()
	_visual.enemy = self
	add_child(_visual)
	_body_area = add_attack_area(Vector2(body_size.x - 8, body_size.y - 4), Vector2(0, -body_size.y * 0.5), &"hound", 1)
	_body_area.dodgeable = false
	_bite = add_attack_area(Vector2(22, 32), Vector2.ZERO, &"hound", 1)
	_bite.active = false
	_set_state(S.PROWL, 0.8)


func state_progress() -> float:
	return clampf(1.0 - _timer / maxf(_state_len, 0.001), 0.0, 1.0)


func is_hidden() -> bool:
	return _hidden


func _set_state(s: S, time: float) -> void:
	state = s
	_timer = time
	_state_len = time


func _set_hidden(h: bool) -> void:
	if _hidden == h:
		return
	_hidden = h
	_hurtbox.set_deferred("monitorable", not h)
	_body_area.active = not h


## 여우창문 원 안인가 (원 안에 들면 그 창문을 돌려줌)
func _window_here() -> Node2D:
	for n in get_tree().get_nodes_in_group(&"fox_window"):
		var w := n as Node2D
		if w == null or not w.has_method("radius"):
			continue
		var r: float = w.call("radius")
		if r > 0.0 and global_position.distance_to(w.global_position) <= r:
			return w
	return null


func _ai(delta: float) -> void:
	var p := player()
	_bite.position = Vector2(facing * 14.0, -18.0)
	# 여우창문: 처음 붙잡히면 끌려 나와 어리둥절, 원 안에서는 잠행 불가
	var win := _window_here()
	if win and not _caught_by.has(win.get_instance_id()):
		_caught_by.append(win.get_instance_id())
		_daze(true)
		return
	match state:
		S.PROWL:
			_timer -= delta
			if p and p.is_alive():
				face_player()
				var dx := p.global_position.x - global_position.x
				var want := 0.0
				if absf(dx) > 6.0 * T:
					want = signf(dx) * PROWL_SPEED_T * T
				elif absf(dx) < 3.0 * T:
					want = -signf(dx) * PROWL_SPEED_T * 0.6 * T
				velocity.x = move_toward(velocity.x, want, 900.0 * delta)
				if _timer <= 0.0 and absf(dx) < 16.0 * T:
					if win == null:
						_set_state(S.SINK, SINK_TIME)
						Sfx.play(&"squish", -4.0, 0.0)
						Sfx.play(&"growl", -8.0, 0.1)
					else:
						_set_state(S.GROWL, GROWL_TIME)
						Sfx.play(&"growl", -2.0, 0.05)
			else:
				velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		S.SINK:
			velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)
			_timer -= delta
			if _timer < SINK_TIME * 0.6:
				_set_hidden(true)
			if _timer <= 0.0:
				_set_state(S.SUBMERGED, SLIDE_MAX_TIME)
		S.SUBMERGED:
			_timer -= delta
			var target := p.global_position.x if p else global_position.x
			var dx2 := target - global_position.x
			if dx2 != 0.0:
				facing = 1 if dx2 > 0.0 else -1
			velocity.x = signf(dx2) * minf(SLIDE_SPEED_T * T, absf(dx2) / maxf(delta, 0.001))
			if absf(dx2) < 4.0 or _timer <= 0.0 or (is_on_wall() and _timer < SLIDE_MAX_TIME - 0.2):
				velocity.x = 0.0
				strike_x = global_position.x
				_set_state(S.RIPPLE, RIPPLE_TIME)
				Sfx.play(&"growl", -3.0, 0.05)
		S.RIPPLE:
			velocity.x = 0.0
			_timer -= delta
			if _timer <= 0.0:
				_erupt()
		S.ERUPT:
			_air_t += delta
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
			if _air_t > 0.3:
				_bite.active = false
			if _air_t > 0.08 and is_on_floor():
				face_player()
				_set_state(S.DASH, DASH_TIME)
				_bite.active = true
				_body_area.dodgeable = true
				Sfx.play(&"dash", -6.0, 0.1)
		S.DASH:
			_timer -= delta
			velocity.x = facing * DASH_SPEED_T * T
			if _timer <= 0.0 or is_on_wall():
				_open(OPEN_TIME)
		S.OPEN, S.DAZED:
			_timer -= delta
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
			if _timer <= 0.0:
				_set_state(S.PROWL, 0.5 if state == S.OPEN else 0.3)
		S.GROWL:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			_timer -= delta
			if _timer > 0.15:
				face_player()
			if _timer <= 0.0:
				_set_state(S.LUNGE, 1.0)
				velocity.y = -sqrt(2.0 * _gravity * LUNGE_HEIGHT_T * T)
				velocity.x = facing * LUNGE_SPEED_T * T
				_air_t = 0.0
				_bite.active = true
				_body_area.dodgeable = true
				Sfx.play(&"swing", -2.0, 0.1)
		S.LUNGE:
			_air_t += delta
			if _air_t > 0.08 and is_on_floor():
				_open(OPEN_TIME * 0.85)


func _erupt() -> void:
	_set_hidden(false)
	face_player()
	_set_state(S.ERUPT, 1.0)
	velocity.y = -sqrt(2.0 * _gravity * ERUPT_HEIGHT_T * T)
	velocity.x = 0.0
	_air_t = 0.0
	_bite.active = true
	_bite.dodgeable = true
	Sfx.play(&"swing", 0.0, 0.05)
	Sfx.play(&"squish", -4.0, 0.1)
	Fx.burst(Vector2(strike_x, global_position.y - 2.0), 16, {
		direction = Vector2.UP, spread = 35.0, speed_min = 60.0, speed_max = 200.0, lifetime = 0.5,
		gradient = Palette.fade_gradient(Color(0.35, 0.15, 0.55)), size_min = 1.5, size_max = 3.5, gravity = Vector2(0, 250),
		add = false,
	})


func _open(time: float) -> void:
	_bite.active = false
	_body_area.dodgeable = false
	_set_state(S.OPEN, time)


## 여우창문·여우불에 붙잡힘: 땅 위로 끌려 나와 어리둥절
func _daze(from_window: bool) -> void:
	var was_hidden := _hidden
	_set_hidden(false)
	_bite.active = false
	_body_area.dodgeable = false
	_set_state(S.DAZED, DAZE_TIME)
	if was_hidden:
		velocity = Vector2(0, -160.0) # 바닥에서 튀어나옴
	Sfx.play(&"reveal" if from_window else &"block", -2.0, 0.0)
	Sfx.play(&"growl", -6.0, 0.0)
	var c := global_position + Vector2(0, -body_size.y * 0.5)
	Fx.ring(c, 4.0, 2.2 * T, Color(0.6, 0.85, 1.0), 0.35, 2.0)
	Fx.burst(c, 12, {
		spread = 180.0, speed_min = 40.0, speed_max = 110.0, lifetime = 0.45,
		gradient = Palette.fade_gradient(Color(0.35, 0.15, 0.55)), size_min = 1.5, size_max = 3.0, add = false,
	})


## 잠행 중에는 거리로 맞히는 범위 공격도 닿지 않는다. 단 푸른 여우불은 끌어낸다
func take_hit(hit: Hit) -> void:
	if _hidden:
		if EnemyBase.is_fox_hit(hit):
			_daze(false)
		return
	super.take_hit(hit)


func modify_damage(_hit: Hit) -> float:
	if state == S.OPEN or state == S.DAZED:
		return OPEN_DAMAGE_MULT
	return 1.0


func _on_hit(hit: Hit, _dir: int) -> void:
	# 땅 위 으르렁(예고) 중에 띄워지면 덮치기가 끊긴다
	if hit.launch_t > 0.0 and state == S.GROWL:
		_open(0.6)


func _on_landed_from_launch() -> void:
	super._on_landed_from_launch()
	if state == S.ERUPT or state == S.LUNGE or state == S.DASH:
		_open(0.6)
