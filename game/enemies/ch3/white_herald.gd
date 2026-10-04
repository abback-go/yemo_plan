class_name WhiteHerald
extends EnemyBase
## 백색 사도 (docs/chapter3.md 4절·7.4절) — 바깥 신들의 첫 사도. 3장 절정 보스 (체력 7000).
## 얼굴 없는 하얀 존재: 매끈한 흰 몸에 직선 무늬가 새겨져 있고, 얼굴 자리엔 세로 틈. 등 뒤로 천천히 도는 기하학 고리,
## 둘레를 도는 흰 조각들. 겹친 낮은 울림 + 높은 유리 소리(docs/bible/art.md 4절). 예고는 흰색(굵게 깜빡임).
## 수정 눈 셋(이마·양어깨)이 약점: 평소엔 수정 갑각 때문에 피해 50%. 동료(엘라리엔)가 snipe_eye()로 눈 하나를 쏘아 깨면
##   → 사도가 땅으로 떨어져 4초 무방비(피해 175%) + 깨진 눈마다 평소 피해가 15%씩 오른다(50 → 65 → 80 → 100%).
## 패턴:
##   빛창: 하늘에서 세라 자리(와 그 둘레)로 굵은 흰 띠가 깜빡임(1.0초) → 빛기둥이 꽂힘.
##   기하학 감옥: 세라 둘레에 육각형 꼭짓점이 하나씩 켜지고 변이 이어짐(1.0초) → 감옥이 좁아지며 닫힘. 안에 있으면 1. 빠져나가면 안전.
##   역병 소환: 바닥에 흰 문양 → 역병 포자 덩어리 / 작은 백색 진드기 (동시에 3마리까지).
## 페이즈: 66% → 2 (빛창 5줄, 감옥+빛창), 33% → 3 (더 빠르게, 소환 둘). phase_changed(n) — 대본이 대사("별의… 그릇…")를 넣는다.
## 대본용: snipe_eye() -> bool, eye_position(i) -> Vector2(전역), eyes_left() -> int, engaged = false로 기다림.

enum S { DORMANT, RISE, DRIFT, LANCE_WINDUP, LANCE, CAGE, SUMMON, STUNNED, RECOVER, DEFEATED }

const HeraldVisual := preload("res://enemies/ch3/white_herald_visual.gd")
const SummonSigil := preload("res://enemies/ch3/white_herald_sigil.gd")
const CageFx := preload("res://enemies/ch3/white_herald_cage.gd")
const LanceBeam := preload("res://enemies/ch3/white_herald_lance.gd")
const HP := 7000
const BODY := Vector2(36, 64)
const HOVER_T := 1.0 ## 처음 자리(바닥)에서 떠 있는 높이 (세라의 화염탄이 닿는 높이)
const LANCE_WINDUP := 1.0
const CAGE_WARN := 1.05
const SUMMON_WARN := 1.0
const STUN_TIME := 4.0
const BASE_MULT := [0.5, 0.65, 0.8, 1.0] ## 깨진 눈 수에 따른 평소 피해 배율
const STUN_MULT := 1.75
const REST := [1.5, 1.2, 0.95]
const MAX_ADDS := 3
const WHITE := Color("#f4f4ff")
const GREY := Color("#b8b8c6")

var state: S = S.DORMANT
var phase := 1
var eyes := 3
var _timer := 0.0
var _dur := 0.0
var _cd := 1.5
var _home := Vector2.ZERO
var _drift_to := Vector2.ZERO
var _pattern := 0
var _adds: Array = []
var _lines: Array[AimLine] = []
var _targets: Array[Vector2] = []
var _hum: AudioStreamPlayer
var _death_t := 0.0
var _broken_flash := 0.0


func _init() -> void:
	engaged = false


func _build() -> void:
	max_hp = HP
	body_size = BODY
	is_boss = true
	is_elite = false
	flying = true
	knock_mult = 0.0
	launch_mult = 0.0
	kind_id = "white_herald"
	display_name = "백색 사도"
	subtitle = "하늘 너머에서 온 첫 발"
	_visual = HeraldVisual.new()
	(_visual as HeraldVisual).enemy = self
	add_child(_visual)
	var c := add_attack_area(Vector2(26, 50), Vector2(0, -30), &"white_herald")
	c.dodgeable = false


func _ready() -> void:
	super()
	_home = global_position
	collision_mask = 0
	Ch3Sfx.ensure()
	_hum = AudioStreamPlayer.new()
	_hum.stream = Ch3Sfx.hum_stream()
	_hum.bus = &"SFX"
	_hum.volume_db = -60.0
	add_child(_hum)
	_hum.play()


func state_k() -> float:
	return clampf(1.0 - _timer / _dur, 0.0, 1.0) if _dur > 0.0 else 0.0


func eyes_left() -> int:
	return eyes


## 수정 눈 위치 (전역): 0 이마, 1 앞 어깨, 2 뒤 어깨. 깨진 눈은 Vector2.INF
func eye_position(i: int) -> Vector2:
	if i >= eyes or i < 0:
		return Vector2.INF
	var offs := [Vector2(0, -78), Vector2(14, -58), Vector2(-14, -58)]
	var o: Vector2 = offs[i]
	return global_position + Vector2(o.x * facing, o.y + (_visual as HeraldVisual).bob())


## 동료 저격: 눈 하나를 깨고 사도를 무방비로 만든다. 깰 눈이 없으면 무방비만(짧게)
func snipe_eye() -> bool:
	if not _alive or state == S.DEFEATED:
		return false
	var broke := eyes > 0
	if broke:
		var at := eye_position(eyes - 1)
		eyes -= 1
		Ch3Sfx.play(&"ch3_crystal_break", 4.0, 0.0)
		Fx.burst(at, 26, {spread = 180.0, speed_min = 40.0, speed_max = 160.0, lifetime = 0.7,
			gradient = Palette.fade_gradient(WHITE), size_min = 1.5, size_max = 3.0, gravity = Vector2(0, 160)})
		Fx.ring(at, 4.0, 46.0, WHITE, 0.4, 3.0)
	Fx.flash(Color(1, 1, 1, 0.35), 0.3)
	Fx.shake(0.3, 0.4)
	Fx.hitstop(0.1)
	_broken_flash = 1.0
	_clear_lines()
	_enter(S.STUNNED, STUN_TIME if broke else 2.0)
	return broke


func _enter(s: S, dur := 0.0) -> void:
	state = s
	_timer = dur
	_dur = dur


func _ai(delta: float) -> void:
	var t := GameConst.TILE
	_timer -= delta
	_broken_flash = maxf(_broken_flash - delta * 1.5, 0.0)
	_hum.volume_db = move_toward(_hum.volume_db, -16.0 if engaged else -30.0, delta * 20.0)
	var p := player()
	var hover := _home + Vector2(0, -HOVER_T * t)
	if state == S.DORMANT:
		global_position = global_position.lerp(hover + Vector2(0, sin(_t * 0.8) * 3.0), clampf(delta * 2.0, 0.0, 1.0))
		if engaged:
			_enter(S.RISE, 1.4)
			Ch3Sfx.play(&"ch3_glass_low", 4.0, 0.0)
			Fx.shake(0.2, 1.0)
		return
	if not engaged or p == null or not p.is_alive():
		_clear_lines()
		return
	_check_phase()
	match state:
		S.RISE:
			if _timer <= 0.0:
				_enter(S.DRIFT)
				_cd = 0.8
		S.DRIFT:
			# 세라 위 비스듬한 자리로 천천히 미끄러짐 (생물이 아닌 듯 일정한 속도)
			if _drift_to == Vector2.ZERO or global_position.distance_to(_drift_to) < 4.0:
				var side := -1.0 if randf() < 0.5 else 1.0
				_drift_to = Vector2(clampf(p.global_position.x + side * randf_range(4.0, 7.0) * t, _home.x - 14.0 * t, _home.x + 14.0 * t), hover.y)
			global_position = global_position.move_toward(_drift_to, 2.6 * t * delta)
			facing = 1 if p.global_position.x >= global_position.x else -1
			_cd -= delta
			if _cd <= 0.0:
				_next_attack(p)
		S.LANCE_WINDUP:
			for i in _lines.size():
				_lines[i].k = state_k()
				if _timer < _dur * 0.3:
					_lines[i].lock()
			if _timer <= 0.0:
				_strike_lances()
				_enter(S.LANCE, 0.5)
		S.LANCE:
			if _timer <= 0.0:
				_rest()
		S.CAGE, S.SUMMON:
			if _timer <= 0.0:
				_rest()
		S.STUNNED:
			# 땅으로 떨어져 무방비
			var ground := Vector2(global_position.x, _home.y + 0.3 * t) # 제자리에서 곧장 떨어짐
			global_position = global_position.move_toward(ground, 260.0 * delta)
			if _timer <= 0.0:
				_enter(S.RECOVER, 1.0)
				Ch3Sfx.play(&"ch3_glass_low", 0.0, 0.0)
		S.RECOVER:
			global_position = global_position.move_toward(hover, 3.0 * t * delta)
			if _timer <= 0.0:
				_enter(S.DRIFT)
				_cd = 0.6


func _check_phase() -> void:
	var want := 1
	if hp <= max_hp * 0.33:
		want = 3
	elif hp <= max_hp * 0.66:
		want = 2
	if want > phase:
		phase = want
		phase_changed.emit(phase)
		Ch3Sfx.play(&"ch3_glass", 4.0, 0.0)
		Fx.flash(Color(1, 1, 1, 0.3), 0.4)
		Fx.shake(0.25, 0.6)
		if phase == 2:
			enraged.emit()


func _rest() -> void:
	_enter(S.DRIFT)
	_cd = Difficulty.rest(REST[phase - 1])


func _next_attack(p: Player) -> void:
	var seq := ["lance", "cage", "lance", "summon"]
	if phase >= 2:
		seq = ["lance", "cage", "lance", "summon", "cage"]
	var a: String = seq[_pattern % seq.size()]
	_pattern += 1
	_adds = _adds.filter(func(e: Variant) -> bool: return is_instance_valid(e) and (e as EnemyBase).is_alive())
	if a == "summon" and _adds.size() >= MAX_ADDS:
		a = "lance"
	match a:
		"lance":
			_start_lances(p)
		"cage":
			_start_cage(p)
		"summon":
			_start_summon(p)


# ─── 빛창 ───────────────────────────────────────────────

func _start_lances(p: Player) -> void:
	var t := GameConst.TILE
	var n := 3 if phase == 1 else 5
	_targets.clear()
	_clear_lines()
	for i in n:
		var off := (i - (n - 1) * 0.5) * 3.2 * t
		if i == (n - 1) / 2:
			off = p.velocity.x * 0.35 # 가운데 줄은 세라가 갈 자리
		var target := p.global_position + Vector2(off, 0)
		var sky := Vector2(target.x + randf_range(-5.0, 5.0) * t, global_position.y - 12.0 * t)
		_targets.append(sky)
		var l := AimLine.new()
		l.white = true
		l.band = 12.0
		l.max_len = 40.0 * t
		Fx.effect_parent().add_child(l)
		l.aim(sky, (target - sky).normalized())
		_lines.append(l)
	_enter(S.LANCE_WINDUP, Difficulty.telegraph(LANCE_WINDUP))
	Ch3Sfx.play(&"ch3_glass", -2.0, 0.1)


func _strike_lances() -> void:
	Ch3Sfx.play(&"ch3_lance", 0.0, 0.05)
	Fx.shake(0.18, 0.25)
	for l in _lines:
		if not is_instance_valid(l):
			continue
		var beam := LanceBeam.new()
		beam.setup(l.from, l.end)
		Fx.effect_parent().add_child(beam)
	_clear_lines()


func _clear_lines() -> void:
	for l in _lines:
		if is_instance_valid(l):
			l.queue_free()
	_lines.clear()


# ─── 기하학 감옥 ────────────────────────────────────────

func _start_cage(p: Player) -> void:
	var cage := CageFx.new()
	cage.setup(p.center(), 3.0 * GameConst.TILE, Difficulty.telegraph(CAGE_WARN))
	Fx.effect_parent().add_child(cage)
	_enter(S.CAGE, cage.warn + 0.6)
	Ch3Sfx.play(&"ch3_glass_low", 0.0, 0.05)


# ─── 소환 ───────────────────────────────────────────────

func _start_summon(p: Player) -> void:
	var t := GameConst.TILE
	var count := 1 if phase == 1 else 2
	for i in count:
		var x := clampf(p.global_position.x + (-1.0 if i == 0 else 1.0) * randf_range(5.0, 8.0) * t, _home.x - 16.0 * t, _home.x + 16.0 * t)
		var sig := SummonSigil.new()
		sig.setup(Vector2(x, _home.y), Difficulty.telegraph(SUMMON_WARN), "white_mite" if (phase >= 2 and i == 1) else "blight_spore", self)
		Fx.effect_parent().add_child(sig)
	_enter(S.SUMMON, Difficulty.telegraph(SUMMON_WARN) + 0.4)
	Ch3Sfx.play(&"ch3_glass", -4.0, 0.1)


func add_summon(kind: String, at: Vector2) -> void:
	var w := World.get_world()
	if w == null or w.room == null or not _alive:
		return
	var e: EnemyBase
	if kind == "white_mite":
		var m := WhiteMite.new()
		m.small = true
		e = m
	else:
		e = BlightSpore.new()
	e.position = at
	e.uid = uid + ":add%d" % Fx.now_ms()
	e.respawns = true
	e.facing = -1
	w.room.add_entity(e)
	w.room.enemies.append(e)
	_adds.append(e)


# ─── 피해 ───────────────────────────────────────────────

func modify_damage(hit: Hit) -> float:
	if state == S.DORMANT or state == S.RISE or state == S.DEFEATED:
		return 0.0
	var base: float = BASE_MULT[3 - clampi(eyes, 0, 3)]
	if state == S.STUNNED:
		return STUN_MULT
	if hit.kind == &"ally":
		return 1.0
	return base


func _on_blocked(_hit: Hit) -> void:
	Ch3Sfx.play(&"ch3_tick", -4.0, 0.2)


func flash_amount() -> float:
	return clampf(_flash / (tuning.enemy_flash_time + 0.03), 0.0, 1.0) * 0.6


func _die(_dir: int) -> void:
	_defeat_quiet("kills", true, false, 0.2) # 등급 처치(StyleRank)는 세지 않는다 (예전 동작 그대로)
	_clear_lines()
	_enter(S.DEFEATED)
	_death_t = 0.0
	for e in _adds:
		if is_instance_valid(e) and (e as EnemyBase).is_alive():
			(e as EnemyBase).take_hit(Hit.make(99999, &"blast", (e as Node2D).global_position))
	Ch3Sfx.play(&"ch3_crystal_break", 6.0, 0.0)
	Ch3Sfx.play(&"ch3_glass_low", 6.0, 0.0)
	Fx.flash(Color(1, 1, 1, 0.6), 0.8)
	Fx.shake(0.4, 1.2)


func _physics_process(delta: float) -> void:
	super(delta)
	if _alive:
		return
	_flash = maxf(_flash - delta, 0.0) # 기반도 줄이므로 2배 빠르게 걷힌다 (예전 동작 그대로)
	_death_t += delta
	if _hum:
		_hum.volume_db = move_toward(_hum.volume_db, -80.0, delta * 25.0)
	# 금이 번지고 → 조각조각 흩어지며 사라짐
	if _death_t > 1.2 and Engine.get_physics_frames() % 2 == 0:
		Fx.burst(global_position + Vector2(randf_range(-18, 18), randf_range(-80, -10)), 3, {spread = 180.0, speed_min = 20.0,
			speed_max = 90.0, lifetime = 0.9, gradient = Palette.fade_gradient(WHITE), size_min = 1.0, size_max = 2.5, gravity = Vector2(0, -20)})
	if _death_t > 3.0:
		queue_free()
	if _visual:
		_visual.queue_redraw()


func death_k() -> float:
	return clampf(_death_t / 3.0, 0.0, 1.0)


func _exit_tree() -> void:
	_clear_lines()
