class_name IsoldeDuel
extends EnemyBase
## 이졸데 폰 크레스트 — 학교 결투 대회 결승 (3장 서브 s_duel_cup, docs/archive/sera/chapter3.md 11절). 고급반 엘리트의 서리 마법.
## 거리를 두는 결투가: 세라가 4칸 안으로 들어오면 서리 안개를 남기고 뒤로 미끄러져 물러나고, 9칸보다 멀면 걸어서 다가온다.
## 패턴 (예고는 모두 붉은색, Difficulty.telegraph):
##   서리 조각: 손끝에 냉기를 모았다가(0.55초) 세 갈래 얼음 조각 — 불꽃 방벽으로 되쏠 수 있다.
##   얼음 창: 가는 붉은 선이 세라를 따라옴(0.9초) → 흰 선 고정(0.35초) → 빠른 큰 얼음 창 (되쏠 수 있음).
##   서리 꽃밭: 세라 둘레 바닥 셋에 붉은 테두리(0.8초) → 얼음 가시가 솟음.
##   (체력 절반 아래) 빙판 질주: 붉은 띠 예고 뒤 세라 쪽으로 미끄러져 지나가며 뒤로 얼음 가시를 남김 /
##                    눈꽃 고리: 1초 모은 뒤 사방 8갈래 조각.
## 쓰러뜨리면(체력 0) 죽지 않고 무릎 — defeated 신호로 대본이 이어 받는다. 다시 도전할 수 있게 respawns.

enum S { IDLE, VOLLEY, LANCE_AIM, LANCE_LOCK, FLOOR, GLIDE_WARN, GLIDE, BLOOM, BLINK, REST }

const ICE := Color(0.72, 0.9, 1.0)
const ICE_D := Color(0.38, 0.6, 0.85)
const KEEP_T := 4.0 ## 이보다 가까우면 물러남
const FAR_T := 9.0 ## 이보다 멀면 걸어서 다가옴
const SHARD_SPEED := 250.0
const LANCE_SPEED := 470.0

var state: S = S.IDLE
var _timer := 0.0
var _dur := 0.0
var _phase := 1
var _cycle := 0
var _clock := 0.0
var _flip: Node2D
var _cv: CharacterVisual
var _line: AimLine
var _lance_dir := Vector2.LEFT
var _glide_dir := 1.0
var _glide_left := 0.0
var _trail_cd := 0.0
var _blink_cd := 0.0


func _build() -> void:
	max_hp = 2000
	body_size = Vector2(16, 36)
	knock_mult = 0.2
	launch_mult = 0.0
	is_boss = true
	display_name = "이졸데 폰 크레스트"
	subtitle = "결투 대회 결승 — 서리의 고급반"
	kind_id = "isolde_duel"
	respawns = true
	_flip = Node2D.new()
	add_child(_flip)
	_cv = CharacterVisual.new()
	_cv.setup("isolde")
	_flip.add_child(_cv)
	_visual = _flip
	_go(S.IDLE, 1.0)


func _ready() -> void:
	super()
	Ch3Sfx.ensure()


func _go(s: S, t: float) -> void:
	state = s
	_timer = t
	_dur = t


func _k() -> float:
	return clampf(1.0 - _timer / _dur, 0.0, 1.0) if _dur > 0.0 else 0.0


func _ai(delta: float) -> void:
	_clock += delta
	_flip.scale.x = facing
	_cv.modulate = Color(2, 2, 2) if flash_amount() > 0.0 else Color.WHITE
	_blink_cd = maxf(_blink_cd - delta, 0.0)
	if state != S.GLIDE:
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	if not engaged:
		return
	if _phase == 1 and hp < max_hp * 0.5:
		_phase = 2
		phase_changed.emit(2)
		Ch3Sfx.play(&"ch3_glass", -2.0, 0.0)
		Fx.ring(global_position + Vector2(0, -18), 6.0, 70.0, ICE, 0.5, 3.0)
	var p := player()
	if p == null or not p.is_alive():
		return
	_timer -= delta
	if state != S.GLIDE:
		face_player()
	# 너무 가까우면 물러남 (공격 모으는 중이 아닐 때)
	if state in [S.IDLE, S.REST] and _blink_cd <= 0.0 and absf(p.global_position.x - global_position.x) < KEEP_T * GameConst.TILE:
		_blink_back(p)
		return
	match state:
		S.IDLE, S.REST:
			# 결투 거리(9칸 안)를 지킨다 — 너무 멀면 걸어서 다가옴 (화면 밖에서 쏘지 않게)
			var dx := p.global_position.x - global_position.x
			var far := absf(dx) > FAR_T * GameConst.TILE
			if far:
				velocity.x = signf(dx) * 90.0
			_cv.walking = far
			if _timer <= 0.0 and absf(dx) <= (FAR_T + 3.0) * GameConst.TILE:
				_next(p)
		S.VOLLEY:
			_cv.set_pose("cast")
			if _timer <= 0.0:
				_cast_volley(p, 3, 0.2)
				_go(S.REST, Difficulty.rest(1.1))
		S.LANCE_AIM:
			_cv.set_pose("aim")
			_lance_dir = (p.center() - _hand()).normalized()
			if _line:
				_line.aim(_hand(), _lance_dir)
				_line.k = _k()
			if _timer <= 0.0:
				if _line:
					_line.lock()
				_go(S.LANCE_LOCK, Difficulty.telegraph(0.35))
		S.LANCE_LOCK:
			if _timer <= 0.0:
				_clear_line()
				var sh := _shard(_hand(), _lance_dir, LANCE_SPEED)
				sh.big = true
				Ch3Sfx.play(&"ch3_lance", -4.0, 0.1)
				_go(S.REST, Difficulty.rest(1.2))
		S.FLOOR:
			_cv.set_pose("cast")
			if _timer <= 0.0:
				_go(S.REST, Difficulty.rest(1.3))
		S.GLIDE_WARN:
			_cv.set_pose("guard")
			if _timer <= 0.0:
				_go(S.GLIDE, 0.0)
				_glide_left = 11.0 * GameConst.TILE
				Ch3Sfx.play(&"ch3_whip", -4.0, 0.1)
		S.GLIDE:
			_cv.set_pose("attack")
			velocity.x = _glide_dir * 360.0
			_glide_left -= absf(velocity.x) * delta
			_trail_cd -= delta
			if _trail_cd <= 0.0:
				_trail_cd = 0.16
				var sp := IceSpikes.new()
				sp.global_position = Vector2(global_position.x, global_position.y)
				sp.delay = Difficulty.telegraph(0.5)
				sp.w = 18.0
				Fx.effect_parent().add_child(sp)
			if _glide_left <= 0.0 or is_on_wall():
				velocity.x = 0.0
				_go(S.REST, Difficulty.rest(1.3))
		S.BLOOM:
			_cv.set_pose("special")
			if _timer <= 0.0:
				for i in 8:
					var a := TAU * i / 8.0 + _clock
					_shard(global_position + Vector2(0, -20), Vector2.from_angle(a), SHARD_SPEED * 0.8)
				Fx.ring(global_position + Vector2(0, -20), 6.0, 50.0, ICE, 0.4, 3.0)
				Ch3Sfx.play(&"ch3_crystal_break", -4.0, 0.1)
				_go(S.REST, Difficulty.rest(1.5))
		S.BLINK:
			if _timer <= 0.0:
				_go(S.REST, Difficulty.rest(0.5))
	if state in [S.IDLE, S.REST]:
		_cv.set_pose("idle")
	else:
		_cv.walking = false


func _next(p: Player) -> void:
	_cycle += 1
	var n := 3 if _phase == 1 else 5
	match _cycle % n:
		0:
			_go(S.VOLLEY, Difficulty.telegraph(0.55))
			Ch3Sfx.play(&"ch3_tick", -6.0, 0.1)
		1:
			_line = AimLine.new()
			Fx.effect_parent().add_child(_line)
			_line.aim(_hand(), (p.center() - _hand()).normalized())
			_go(S.LANCE_AIM, Difficulty.telegraph(0.9))
		2:
			_cast_floor(p)
			_go(S.FLOOR, 0.6)
		3:
			_glide_dir = signf(p.global_position.x - global_position.x)
			if _glide_dir == 0.0:
				_glide_dir = 1.0
			_go(S.GLIDE_WARN, Difficulty.telegraph(0.7))
		4:
			_go(S.BLOOM, Difficulty.telegraph(1.0))
			Ch3Sfx.play(&"ch3_tick", -4.0, 0.0)


func _hand() -> Vector2:
	return global_position + Vector2(facing * 10.0, -22.0)


func _shard(pos: Vector2, d: Vector2, spd: float) -> FrostShard:
	var s := FrostShard.new()
	s.setup(pos, d, spd, {"style": "arrow", "damage": 1, "cause": "isolde", "life": 3.0})
	Fx.effect_parent().add_child(s)
	return s


func _cast_volley(p: Player, count: int, spread: float) -> void:
	var base := (p.center() - _hand()).angle()
	for i in count:
		var a := base + (i - (count - 1) * 0.5) * spread
		_shard(_hand(), Vector2.from_angle(a), SHARD_SPEED)
	Ch3Sfx.play(&"ch3_glass_low", -4.0, 0.1)


func _cast_floor(p: Player) -> void:
	var rw := _room_w()
	for i in 3:
		var sp := IceSpikes.new()
		var x := p.global_position.x + (i - 1) * 3.2 * GameConst.TILE
		sp.global_position = Vector2(clampf(x, 2.0 * GameConst.TILE, rw - 2.0 * GameConst.TILE), global_position.y)
		sp.delay = Difficulty.telegraph(0.8) + i * 0.08
		Fx.effect_parent().add_child(sp)
	Ch3Sfx.play(&"ch3_tick", -6.0, 0.1)


func _blink_back(p: Player) -> void:
	_blink_cd = 2.6
	var away := signf(global_position.x - p.global_position.x)
	if away == 0.0:
		away = 1.0
	var rw := _room_w()
	var x := global_position.x + away * 7.0 * GameConst.TILE
	if x < 3.0 * GameConst.TILE or x > rw - 3.0 * GameConst.TILE:
		x = p.global_position.x - away * 7.0 * GameConst.TILE
	Fx.burst(global_position + Vector2(0, -18), 18, {spread = 180.0, speed_min = 20.0, speed_max = 80.0, lifetime = 0.5,
		gradient = Palette.fade_gradient(ICE), size_min = 1.0, size_max = 2.5, gravity = Vector2.ZERO})
	global_position.x = clampf(x, 3.0 * GameConst.TILE, rw - 3.0 * GameConst.TILE)
	Fx.burst(global_position + Vector2(0, -18), 12, {spread = 180.0, speed_min = 10.0, speed_max = 50.0, lifetime = 0.4,
		gradient = Palette.fade_gradient(ICE), gravity = Vector2.ZERO})
	Sfx.play(&"whoosh", -6.0, 0.1)
	_go(S.BLINK, 0.25)


func _room_w() -> float:
	var w := World.get_world()
	return w.room.size_px.x if w and w.room else 640.0


func _clear_line() -> void:
	if is_instance_valid(_line):
		_line.queue_free()
	_line = null


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	queue_redraw()


func _draw() -> void:
	# 모으는 동안 손끝의 냉기
	if state in [S.VOLLEY, S.LANCE_AIM, S.BLOOM] and _timer > 0.0:
		var k := _k()
		var c := Vector2(10, -22) * Vector2(facing, 1)
		if state == S.BLOOM:
			c = Vector2(0, -20)
		draw_circle(c, 3.0 + k * 7.0, Color(ICE, 0.35))
		draw_circle(c, 1.5 + k * 2.5, Color(1, 1, 1, 0.85))
		for i in 6:
			var a := TAU * i / 6.0 + _clock * 3.0
			draw_line(c + Vector2.from_angle(a) * (5.0 + k * 6.0), c + Vector2.from_angle(a) * (8.0 + k * 9.0), Color(ICE, 0.6), 1.0)
	if state == S.GLIDE_WARN and _timer > 0.0:
		var a2 := 0.35 + 0.45 * sin(_clock * 26.0)
		draw_rect(Rect2(minf(0.0, _glide_dir * 176.0), -3, 176.0, 3), Color(Palette.DANGER, a2))
	if state == S.GLIDE:
		draw_line(Vector2(-_glide_dir * 30.0, -2), Vector2.ZERO, Color(ICE, 0.6), 3.0)


## 체력 0: 죽지 않고 무릎 — 조용히 사라지고 대본이 같은 자리에 인물을 세운다
func _die(_dir: int) -> void:
	_defeat_quiet("", false, false, 0.0) # 결투: 처치 표시·통계·등급을 남기지 않는다 (예전 동작 그대로)
	_clear_line()
	for pr in get_tree().get_nodes_in_group(&"enemy_projectile"):
		if pr is FrostShard:
			pr.queue_free()
	Fx.hitstop(0.12)
	Fx.ring(global_position + Vector2(0, -18), 6.0, 60.0, ICE, 0.5, 3.0)
	Sfx.play(&"enemy_die", -4.0, 0.0)
	var t := create_tween()
	t.tween_property(_visual, "modulate:a", 0.0, 0.35)
	t.tween_callback(queue_free)


## 얼음 조각 (엘프 화살과 같은 규칙: 지형에 박히면 부서짐, 불꽃 방벽으로 되쏘면 녹은 불꽃 조각이 됨)
class FrostShard extends ElfArrow:
	var big := false

	func _stick() -> void:
		active = false
		Ch3Sfx.play(&"ch3_glass_low", -8.0, 0.15)
		Fx.burst(global_position, 8, {spread = 180.0, speed_min = 20.0, speed_max = 80.0, lifetime = 0.3,
			gradient = Palette.fade_gradient(Color(0.75, 0.9, 1.0)), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 200)})
		queue_free()

	func _draw() -> void:
		var s := 1.6 if big else 1.0
		var col := Palette.FIRE_HOT if reflected else Color(0.78, 0.92, 1.0)
		var core := Palette.FIRE_CORE if reflected else Color(1, 1, 1)
		for i in _trail.size():
			var p := to_local(_trail[i])
			var k := 1.0 - float(i) / maxf(_trail.size(), 1)
			draw_circle(p, 1.5 * k * s, Color(col, 0.3 * k))
		draw_colored_polygon(PackedVector2Array([Vector2(9, 0) * s, Vector2(0, -3) * s, Vector2(-9, 0) * s, Vector2(0, 3) * s]), Color(col, 0.9))
		draw_line(Vector2(-6, 0) * s, Vector2(7, 0) * s, core, 1.0)
		draw_circle(Vector2(4, 0) * s, 4.0 * s, Color(col, 0.18))


## 얼음 가시: 붉은 테두리 예고 뒤 솟아 세라를 맞힘
class IceSpikes extends TelegraphHazard:
	var w := 34.0

	func _ready() -> void:
		z_index = 3
		hit_time = 0.3
		life = 0.7
		area = EnemyAttackArea.with_rect(Vector2(w, 30), Vector2(0, -15))
		area.active = false
		area.cause = &"isolde"
		add_child(area)

	func _on_fire() -> void:
		Ch3Sfx.play(&"ch3_crystal_break", -10.0, 0.15)
		Fx.burst(global_position, 10, {direction = Vector2.UP, spread = 30.0, speed_min = 60.0, speed_max = 140.0, lifetime = 0.35,
			gradient = Palette.fade_gradient(Color(0.75, 0.9, 1.0))})

	func _draw() -> void:
		if _t < delay:
			var a := 0.35 + 0.5 * sin(_t * 22.0)
			draw_rect(Rect2(-w * 0.5, -3, w, 3), Color(Palette.DANGER, a))
			draw_rect(Rect2(-w * 0.5, -3, w, 3), Color(Palette.DANGER, 0.9), false, 1.0)
			return
		var k := clampf((_t - delay) / 0.1, 0.0, 1.0) * clampf((delay + 0.7 - _t) / 0.3, 0.0, 1.0)
		var n := maxi(int(w / 8.0), 2)
		for i in n:
			var x := -w * 0.5 + (i + 0.5) * w / n
			var h := 26.0 * k * (0.7 + 0.3 * float(i % 2))
			draw_colored_polygon(PackedVector2Array([Vector2(x - 4, 0), Vector2(x, -h), Vector2(x + 4, 0)]), Color(0.7, 0.88, 1.0, 0.95))
			draw_line(Vector2(x, 0), Vector2(x, -h), Color(1, 1, 1, 0.8), 1.0)
