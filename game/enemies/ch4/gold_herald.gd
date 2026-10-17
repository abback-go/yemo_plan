class_name GoldHerald
extends EnemyBase
## 백금 사도 (docs/archive/sera/chapter4.md 4절·7.4절): 기록실에 내려앉은 바깥 신들의 사도 변종. 흰빛(바깥 신들)에 루멘의 금이 섞인 기하학 몸 —
## 가운데 팔면체 핵(세로로 갈라진 틈 = 얼굴 자리)과 둘레를 도는 거울판 3장. 목소리는 겹친 메아리("…그릇… 별의… 그릇…").
## - 거울판: 판이 막고 있는 쪽에서 날아온 화염탄은 튕겨 흰 조각탄으로 되돌아온다. 판 사이 틈이 세라 쪽을 향할 때 쏘거나,
##   불꽃 방벽으로 조각탄을 되쏘면(reflect) 판을 뚫고 핵에 박혀 휘청(1.2초).
## - 프리즘: 굵게 깜빡이는 흰 예고선 3(→ 2페이즈 5)줄 → 가는 빛줄기 0.35초.
## - 판 회전: 판이 하얗게 번쩍(0.6초) → 궤도가 4.5칸까지 넓어지며 빠르게 돎(2.4초, 판에 닿으면 1 피해) — 안쪽(핵 바로 밑)이나 바깥이 안전.
## - 격자: 세라 둘레 바닥에 흰 사각형 4(→ 6)개가 깜빡(1초) → 흰 기하 가시가 솟음.
## - 내려앉기: 세 번 공격마다 바닥으로 내려와 판을 떨어뜨림(2.2초): 핵이 드러나 피해 1.5배, 땅에 있으니 불기둥도 닿는다.
## 체력 50%: phase_changed(2) — 판이 빨라지고 프리즘·격자가 늘어난다. 쓰러지면 흰 기하 조각으로 부서져 흩어진다.

enum S { HOVER, PRISM_AIM, PRISM, SPIN_WARN, SPIN, LATTICE_WARN, LATTICE, DESCEND, GROUNDED, ASCEND, STAGGER, DYING }

const H := preload("res://enemies/ch4/holy.gd")
const VIS := preload("res://enemies/ch4/gold_herald_visual.gd")

const HP := 2400
const ORBIT := 42.0
const ORBIT_SPIN := 86.0
const PANEL_LEN := 24.0
const PANEL_ARC := 0.42 ## 판이 막는 각도 반폭 (라디안)
const HOVER_H := 3.2 ## 바닥 위 칸
const PRISM_AIM := 0.9
const PRISM_TIME := 0.35
const PRISM_SPREAD := 0.28
const SPIN_WARN := 0.6
const SPIN_TIME := 2.4
const LATTICE_WARN := 1.0
const LATTICE_TIME := 0.5
const GROUNDED_TIME := 2.2
const STAGGER_TIME := 1.2
const VOICE: Array[String] = ["…그릇… 별의… 그릇…", "…빛이 꺼진 자리에… 우리가 앉으리라…", "…문을… 열어라…"]

var state: S = S.HOVER
var phase := 1
var rot := 0.0 ## 판 회전 각
var orbit := ORBIT
var prism_dirs: Array = [] ## 프리즘 방향 (라디안)
var prism_paths: Array = [] ## 빛줄기 경로 (전역 PackedVector2Array)
var lattice: Array = [] ## 격자 칸 중심 (전역, 바닥)
var dying_k := 0.0
var _timer := 0.0
var _dur := 0.0
var _home := Vector2.INF
var _floor_y := 0.0
var _count := 0
var _last := ""
var _spin_speed := 1.4
var _voice_t := 4.0
var _beams: Array = []
var _panels: Array = []
var _spikes: Array = []


func _init() -> void:
	engaged = true


func _build() -> void:
	max_hp = HP
	body_size = Vector2(30, 34)
	flying = true
	is_boss = true
	is_elite = false
	knock_mult = 0.0
	launch_mult = 0.0
	display_name = "백금 사도"
	subtitle = "빛이 꺼진 자리의 손님"
	kind_id = "gold_herald"
	var v: Node2D = VIS.new()
	v.set("enemy", self)
	_visual = v
	add_child(v)
	var c := add_attack_area(Vector2(22, 26), Vector2(0, -20), &"gold_herald")
	c.dodgeable = false
	for i in 5:
		var b := H.SegmentArea.new()
		b.cause = &"gold_herald"
		b.dodgeable = true
		b.active = false
		add_child(b)
		_beams.append(b)
	for i in 3:
		var pa := H.SegmentArea.new()
		pa.cause = &"gold_herald"
		pa.dodgeable = true
		pa.active = false
		add_child(pa)
		_panels.append(pa)
	for i in 6:
		var sp := EnemyAttackArea.with_rect(Vector2(26, 36), Vector2(0, -18))
		sp.cause = &"gold_herald"
		sp.top_level = true
		sp.active = false
		add_child(sp)
		_spikes.append(sp)


func _ready() -> void:
	super()
	collision_mask = GameConst.L_WORLD


func progress() -> float:
	return clampf(1.0 - _timer / _dur, 0.0, 1.0) if _dur > 0.0 else 1.0


func _go(s: S, time := 0.0) -> void:
	state = s
	_timer = time
	_dur = time


func core() -> Vector2:
	return global_position + Vector2(0, -20)


func panels_dropped() -> bool:
	return state == S.GROUNDED or state == S.DESCEND or state == S.DYING


## 판 i의 각 (라디안)
func panel_angle(i: int) -> float:
	return rot + TAU * i / 3.0


func _ai(delta: float) -> void:
	var t := GameConst.TILE
	if _home == Vector2.INF:
		_home = global_position
		var space := get_world_2d().direct_space_state
		var fy := H.floor_below(space, global_position + Vector2(0, -4), 20.0 * t)
		_floor_y = fy if fy != INF else global_position.y
	_timer -= delta
	var p := player()
	var spin_mult := _spin_speed * (1.4 if phase == 2 else 1.0)
	if state == S.SPIN:
		rot += delta * spin_mult * 3.2
		orbit = move_toward(orbit, ORBIT_SPIN, delta * 120.0)
	elif not panels_dropped():
		rot += delta * spin_mult
		orbit = move_toward(orbit, ORBIT, delta * 80.0)
	_update_panel_areas()
	_voice_t -= delta
	if _voice_t <= 0.0 and p and engaged:
		_voice_t = randf_range(7.0, 11.0)
		_speak(VOICE[randi() % VOICE.size()])
	if not engaged or p == null or not p.is_alive():
		velocity = Vector2.ZERO
		_all_off()
		return
	# 떠 있기 (내려앉기·서 있기 제외)
	var hover_y := _floor_y - HOVER_H * t + sin(_t * 1.2) * 0.4 * t
	if state in [S.HOVER, S.PRISM_AIM, S.PRISM, S.SPIN_WARN, S.SPIN, S.LATTICE_WARN, S.LATTICE, S.ASCEND, S.STAGGER]:
		var want_x := clampf(lerpf(global_position.x, p.global_position.x, 0.5), _home.x - 14.0 * t, _home.x + 14.0 * t)
		var speed := 0.8 if state == S.HOVER else 0.25
		velocity = Vector2((want_x - global_position.x) * speed, (hover_y - global_position.y) * 2.5)
	match state:
		S.HOVER:
			if _timer <= 0.0:
				_choose(p)
		S.PRISM_AIM:
			_aim_prism(p, delta)
			if _timer <= 0.0:
				_go(S.PRISM, PRISM_TIME)
				H.snd(&"star_burst", &"sniper_shot", -2.0)
				Fx.flash(Color(1, 1, 1, 0.12), 0.1)
		S.PRISM:
			_fire_prism()
			if _timer <= 0.0:
				_beams_off()
				prism_paths.clear()
				_go(S.HOVER, Difficulty.rest(0.9))
		S.SPIN_WARN:
			if _timer <= 0.0:
				_go(S.SPIN, SPIN_TIME)
				H.snd(&"whoosh", &"whoosh", 0.0)
		S.SPIN:
			if _timer <= 0.0:
				_go(S.HOVER, Difficulty.rest(0.8))
		S.LATTICE_WARN:
			if _timer <= 0.0:
				_go(S.LATTICE, LATTICE_TIME)
				_erupt_lattice()
		S.LATTICE:
			if _timer <= 0.0:
				for sp in _spikes:
					(sp as EnemyAttackArea).active = false
				lattice.clear()
				_go(S.HOVER, Difficulty.rest(0.8))
		S.DESCEND:
			velocity = Vector2(0, 220.0)
			if is_on_floor() or _timer <= 0.0:
				velocity = Vector2.ZERO
				_go(S.GROUNDED, GROUNDED_TIME)
				Fx.shake(0.2, 0.2)
				H.snd(&"slam", &"slam", -4.0)
				H.sparkle(global_position, 14, 10.0, 20.0, 0.6, true)
		S.GROUNDED:
			velocity = Vector2(0, 30.0) # 바닥에 붙어 있게 (불기둥 표적 = 땅 위)
			if _timer <= 0.0:
				_go(S.ASCEND, 0.6)
		S.ASCEND:
			if _timer <= 0.0:
				_go(S.HOVER, Difficulty.rest(0.6))
		S.STAGGER:
			if _timer <= 0.0:
				_go(S.HOVER, 0.5)


func _choose(p: Player) -> void:
	_count += 1
	if _count % 4 == 0:
		_go(S.DESCEND, 1.2)
		_speak("…!")
		return
	var opts: Array[String] = ["prism", "spin", "lattice"]
	opts.erase(_last)
	var pick: String = opts[randi() % opts.size()]
	_last = pick
	match pick:
		"prism":
			_go(S.PRISM_AIM, Difficulty.telegraph(PRISM_AIM))
			prism_dirs.clear()
			_aim_prism(p, 1.0)
			H.snd(&"sky_crack", &"sniper_aim", -4.0)
		"spin":
			_go(S.SPIN_WARN, Difficulty.telegraph(SPIN_WARN))
			H.snd(&"star_twinkle", &"reveal", -4.0)
		"lattice":
			_go(S.LATTICE_WARN, Difficulty.telegraph(LATTICE_WARN))
			_place_lattice(p)
			H.snd(&"star_twinkle", &"reveal", -4.0)


func _aim_prism(p: Player, delta: float) -> void:
	var n := 3 if phase == 1 else 5
	var to := (p.center() - core()).angle()
	if prism_dirs.size() != n:
		prism_dirs.clear()
		for i in n:
			prism_dirs.append(to + (i - (n - 1) * 0.5) * PRISM_SPREAD)
	else:
		# 예고 동안 세라를 조금 따라감 (끝 무렵엔 고정)
		var follow := 0.0 if progress() > 0.7 else clampf(delta * 1.5, 0.0, 1.0)
		var mid: float = prism_dirs[(n - 1) / 2]
		var diff := wrapf(to - mid, -PI, PI) * follow
		for i in n:
			prism_dirs[i] = float(prism_dirs[i]) + diff
	var space := get_world_2d().direct_space_state
	prism_paths.clear()
	for d in prism_dirs:
		prism_paths.append(H.trace(space, core(), Vector2.RIGHT.rotated(float(d)), 24.0 * GameConst.TILE, false))


func _fire_prism() -> void:
	var space := get_world_2d().direct_space_state
	prism_paths.clear()
	for i in _beams.size():
		var b: H.SegmentArea = _beams[i]
		if i < prism_dirs.size():
			var path := H.trace(space, core(), Vector2.RIGHT.rotated(float(prism_dirs[i])), 24.0 * GameConst.TILE, true, get_physics_process_delta_time())
			prism_paths.append(path)
			b.set_segment(path[0], path[1], 5.0)
			b.active = true
		else:
			b.active = false


func _beams_off() -> void:
	for b in _beams:
		(b as EnemyAttackArea).active = false


func _place_lattice(p: Player) -> void:
	lattice.clear()
	var n := 4 if phase == 1 else 6
	var space := get_world_2d().direct_space_state
	var base := p.global_position.x
	var offs: Array[float] = [0.0, -2.2, 2.2, -4.4, 4.4, 6.6]
	var shift := (1.0 if randf() < 0.5 else -1.0) * 0.8
	for i in n:
		var x := base + (offs[i] + shift) * 32.0 * 0.5
		var fy := H.floor_below(space, Vector2(x, p.global_position.y - 24.0), 6.0 * GameConst.TILE)
		if fy != INF:
			lattice.append(Vector2(x, fy))


func _erupt_lattice() -> void:
	Fx.shake(0.15, 0.2)
	H.snd(&"star_burst", &"pillar", -4.0)
	for i in _spikes.size():
		var sp: EnemyAttackArea = _spikes[i]
		if i < lattice.size():
			var c: Vector2 = lattice[i]
			sp.global_position = c
			sp.active = true
			H.sparkle(c + Vector2(0, -12), 10, 8.0, 0.0, 0.5, true)
		else:
			sp.active = false


func _update_panel_areas() -> void:
	for i in _panels.size():
		var pa: H.SegmentArea = _panels[i]
		var a := panel_angle(i)
		var c := core() + Vector2(cos(a), sin(a)) * orbit
		var tang := Vector2(-sin(a), cos(a))
		pa.set_segment(c - tang * PANEL_LEN * 0.5, c + tang * PANEL_LEN * 0.5, 6.0)
		pa.active = state == S.SPIN and _alive


func _all_off() -> void:
	_beams_off()
	for pa in _panels:
		(pa as EnemyAttackArea).active = false
	for sp in _spikes:
		(sp as EnemyAttackArea).active = false


## 판이 이 방향(핵에서 본 각)을 막고 있나
func _panel_blocks(dir_angle: float) -> bool:
	if panels_dropped():
		return false
	for i in 3:
		if absf(wrapf(panel_angle(i) - dir_angle, -PI, PI)) < PANEL_ARC:
			return true
	return false


func modify_damage(hit: Hit) -> float:
	if state == S.DYING:
		return 0.0
	var mult := 1.5 if (state == S.GROUNDED or state == S.STAGGER) else 1.0
	if hit.kind == &"reflect":
		if state != S.GROUNDED:
			_go(S.STAGGER, STAGGER_TIME)
			_beams_off()
			H.snd(&"holy_hit", &"block", 0.0)
			Fx.ring(core(), 4.0, 40.0, Color.WHITE, 0.3, 2.0)
		return 1.5
	if hit.kind in Hit.PASS_SHIELD_GOLD_HERALD:
		return mult
	var src := hit.source_pos
	if hit.direction != 0:
		src = core() + Vector2(-hit.direction * 20.0, 0)
	elif src.distance_to(global_position) < 8.0:
		return mult # 몸 안에서 터진 것 (시험 명령 등)
	var ang := (src - core()).angle()
	if _panel_blocks(ang):
		return 0.0
	return mult


func _on_blocked(hit: Hit) -> void:
	var src := hit.source_pos if hit.direction == 0 else core() + Vector2(-hit.direction * 20.0, 0)
	var dir := (src - core()).normalized()
	var at := core() + dir * orbit
	Fx.ring(at, 3.0, 16.0, Color.WHITE, 0.2, 2.0)
	H.snd(&"reflect", &"block", -4.0)
	if hit.kind == &"bolt" or hit.kind == &"bolt_heavy":
		call_deferred("_shard_back", at, dir)


func _shard_back(at: Vector2, dir: Vector2) -> void:
	if not _alive:
		return
	H.shoot(at, Vector2(signf(dir.x) if dir.x != 0.0 else 1.0, clampf(dir.y, -0.3, 0.3)).normalized(), 240.0, "shard", {"damage": 1, "cause": "gold_herald", "radius": 4.0, "life": 2.2})


func take_hit(hit: Hit) -> void:
	super(hit)
	if _alive and phase == 1 and hp * 2 <= max_hp:
		phase = 2
		phase_changed.emit(2)
		_speak("…그릇이… 반항한다…")
		Fx.flash(Color(1, 1, 1, 0.2), 0.2)
		H.snd(&"sky_crack", &"roar", -2.0)


func _speak(text: String) -> void:
	var l := Label.new()
	l.text = text
	var ls := LabelSettings.new()
	ls.font_size = 10
	ls.font_color = Color(0.95, 0.95, 1.0)
	ls.outline_size = 3
	ls.outline_color = Color("#101018")
	l.label_settings = ls
	l.position = global_position + Vector2(-46, -58)
	l.z_index = 20
	Fx.effect_parent().add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 8.0, 2.0)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.6).set_delay(1.6)
	tw.tween_callback(l.queue_free)
	# 겹친 메아리 (조금 어긋난 두 번째 글자)
	var l2 := l.duplicate() as Label
	l2.position += Vector2(2, 1)
	l2.modulate = Color(1, 1, 1, 0.35)
	Fx.effect_parent().add_child(l2)
	var tw2 := l2.create_tween()
	tw2.tween_property(l2, "modulate:a", 0.0, 2.0)
	tw2.tween_callback(l2.queue_free)


func _die(dir: int) -> void:
	if state == S.DYING:
		return
	_all_off()
	lattice.clear()
	prism_paths.clear()
	_go(S.DYING, 1.4)
	_alive = false
	_record_defeat()
	defeated.emit(self)
	_disable_body(false) # 판·가시는 _all_off()가 껐고, 몸 접촉 판정은 예전처럼 켜 둔 채
	velocity = Vector2.ZERO
	H.snd(&"sky_crack", &"roar", 0.0)
	Fx.shake(0.4, 0.6)
	Fx.flash(Color(1, 1, 1, 0.3), 0.3)
	var tw := create_tween()
	tw.tween_property(self, "dying_k", 1.0, 1.2)
	tw.tween_callback(func() -> void:
		Fx.burst(core(), 40, {
			spread = 180.0, speed_min = 40.0, speed_max = 200.0, lifetime = 1.0, damping = 40.0,
			gradient = H.white_grad(), size_min = 1.5, size_max = 3.5, gravity = Vector2(0, 60), add = true,
		})
		Fx.ring(core(), 6.0, 70.0, Color.WHITE, 0.5, 3.0)
		H.sparkle(core(), 30, 16.0, 40.0, 1.2))
	tw.tween_property(_visual, "modulate:a", 0.0, 0.3)
	tw.tween_callback(queue_free)


func _physics_process(delta: float) -> void:
	super(delta)
	if not _alive and _visual:
		_t += delta
		_visual.queue_redraw()
