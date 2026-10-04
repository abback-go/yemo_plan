extends "res://enemies/ch2/leonie_base.gd"
## 레오니 발렌하르트 — 밤의 황궁 광장 진검 결투 (docs/chapter2.md 2절 9, 4절). 2장 강자 보스, 체력 4000, 2페이즈.
## 마력 0: 모든 기술은 순수한 검술(흰 검압·잔상)이다. 예고는 늘 붉게, 빈틈은 분명하게.
##
## 1페이즈
##   잔상 돌진 베기: 낮게 자세를 잡음(0.45초, 지나갈 길이 땅에 붉은 선) → 잔상을 남기며 9칸 질주 + 끝에서 베기 → 0.6초 빈틈
##   3연격: 한 걸음씩 들어오며 세 번 벤다(예고 0.4·0.3·0.45초, 칼날이 붉게). 셋째가 가장 크다 → 0.7초 빈틈
##   받아치기 자세: 칼을 비스듬히 세움(최대 2.2초). 정면의 화염탄·여우불·폭풍은 베어 낸다(피해 0). 두 번 베어 내면 곧바로 반격 돌진.
##                  **불기둥(발밑)·불꽃 방벽(화상)·폭발에는 자세가 깨져 1.6초 휘청(피해 150%)**. 등 뒤는 그냥 맞는다.
##   검압 파동: 칼을 머리 위로(0.6초) → 내려치면 땅을 가르는 흰 충격파가 세라 쪽으로 달림 → 점프로 넘는다
##   일섬(一閃): 칼을 칼집에 넣고 깊게 웅크림(1.5초) — 화면이 어두워지고 그녀의 높이로 화면을 가로지르는 붉은 띠.
##              끝나기 0.2초 전 칼자루에 흰 빛이 반짝(신호) → 섬광 한 줄기와 함께 세라 너머로 순간이동하며 베어 버림(피해 2).
##              **대시 무적으로 피한다**(퍼펙트 회피면 위치 타임). 2단 점프로 아주 높이 있어도 피할 수 있다. 벤 뒤 1.2초 빈틈.
## 2페이즈 (체력 50%): 칼을 고쳐 잡는 연출(무적 1.4초) → 모든 예고·쉬는 시간 짧아짐, 공중 베기(두 번 연속 내리꽂기),
##   검압 파동 두 줄, 4연격, 일섬을 두 번 연달아(왕복) 쓰기도 한다.
## 쓰러지면 터지지 않고 검을 땅에 꽂고 무릎을 꿇은 채 남는다(defeated 신호 — 대본이 이어받음).

enum S { IDLE, STALK, DASH_WINDUP, DASH, DASH_END, COMBO_WINDUP, COMBO_HIT, GUARD, COUNTER_WINDUP, GUARD_BROKEN,
	WAVE_WINDUP, WAVE_SLAM, ISSEN_STANCE, ISSEN_AFTER, AIR_JUMP, AIR_HANG, AIR_DIVE, AIR_LAND, RECOVER, PHASE, BACKSTEP, DEFEATED }

const HP := 4000
const WALK_T := 2.6
const DASH_WINDUP := 0.45
const DASH_LEN_T := 9.0
const DASH_SPEED_T := 48.0
const COMBO_WINDUPS: Array[float] = [0.4, 0.3, 0.45, 0.3]
const GUARD_TIME := 2.2
const GUARD_BREAK_TIME := 1.6
const BROKEN_MULT := 1.5
const WAVE_WINDUP := 0.6
const WAVE_SPEED_T := 15.0
const ISSEN_STANCE := 1.5
const ISSEN_CUE := 0.2
const ISSEN_AFTER := 1.2
const ISSEN_CD := Vector2(18.0, 13.0) ## 1페이즈 · 2페이즈 재사용 대기
const AIR_HANG := 0.4
const AIR_DIVE_SPEED_T := 34.0
const PHASE_TIME := 1.4
const FAST := 0.8 ## 2페이즈 예고·휴식 배율

var phase := 1
var state: S = S.IDLE
var _timer := 0.0
var _dur := 0.0
var _combo := 0
var _combo_max := 3
var _parries := 0
var _issen_cd := 6.0
var _issen_queue := 0
var _issen_from := Vector2.ZERO
var _issen_to := Vector2.ZERO
var _cue_done := false
var _air_left := 0
var _air_target := Vector2.ZERO
var _dash_from := 0.0
var _dash_len := 0.0
var _last := ""
var _forced_issen := false
var _issen_pending := false
var _slash: EnemyAttackArea
var _big_slash: EnemyAttackArea
var _body_hit: EnemyAttackArea
var _fx: Node2D
var _dark: Node2D


func _init() -> void:
	engaged = false


func _build() -> void:
	max_hp = HP
	body_size = Vector2(14, 38)
	knock_mult = 0.0
	launch_mult = 0.0
	is_boss = true
	is_elite = false
	display_name = "레오니 발렌하르트"
	subtitle = "은사자 기사단장 · 제국제일검"
	kind_id = "leonie_duel"
	_setup_visual(false)
	_slash = add_attack_area(Vector2(36, 30), Vector2(20, -18), &"leonie", 1)
	_slash.active = false
	_big_slash = add_attack_area(Vector2(48, 40), Vector2(22, -20), &"leonie", 1)
	_big_slash.active = false
	_body_hit = add_attack_area(Vector2(18, 34), Vector2(0, -18), &"leonie", 1)
	_body_hit.active = false
	var fx := KE.Vis.new()
	fx.enemy = self
	fx.fn = _draw_fx
	fx.flip = false
	fx.z_index = 7
	add_child(fx)
	_fx = fx
	var dark := KE.Vis.new()
	dark.enemy = self
	dark.fn = _draw_dark
	dark.flip = false
	dark.z_index = -1
	dark.z_as_relative = false
	add_child(dark)
	_dark = dark


func _enter(s: S, d: float) -> void:
	state = s
	_timer = d
	_dur = d


func progress() -> float:
	return clampf(1.0 - _timer / _dur, 0.0, 1.0) if _dur > 0.0 else 1.0


func _tg(sec: float) -> float:
	return Difficulty.telegraph(sec * (FAST if phase == 2 else 1.0))


func _rest(sec: float) -> float:
	return Difficulty.rest(sec * (FAST if phase == 2 else 1.0))


func _ai(delta: float) -> void:
	var t := GameConst.TILE
	_timer -= delta
	_issen_cd -= delta
	if state != S.ISSEN_STANCE:
		warn(0.0)
	var p := player()
	if not engaged or p == null or not p.is_alive():
		pose("idle")
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		_after_every = 0.0
		return
	if state == S.IDLE:
		_enter(S.STALK, 0.6)
	if state != S.PHASE:
		_check_thresholds()
	var dx := p.global_position.x - global_position.x
	match state:
		S.STALK:
			face_player()
			var want := 0.0
			if absf(dx) > 4.0 * t:
				want = signf(dx) * WALK_T * t
			elif absf(dx) < 2.0 * t:
				want = -signf(dx) * WALK_T * 0.5 * t
			velocity.x = move_toward(velocity.x, want, 600.0 * delta)
			pose("run" if absf(velocity.x) > 12.0 else "idle")
			if _timer <= 0.0 and is_on_floor():
				_choose(absf(dx) / t)
		# ─ 잔상 돌진 베기 ─
		S.DASH_WINDUP:
			velocity.x = 0.0
			pose("guard" if progress() < 0.4 else "charge")
			warn(progress())
			if _timer <= 0.0:
				_dash_from = global_position.x
				_enter(S.DASH, 0.4)
				_after_every = 0.025
				strike(_body_hit, Vector2(4, -18), 0.4)
				KE.snd(&"dash", &"dash", 2.0)
				KE.snd(&"wind", &"whoosh", -2.0)
		S.DASH:
			pose("charge")
			velocity.x = facing * DASH_SPEED_T * t
			if absf(global_position.x - _dash_from) >= _dash_len or _timer <= 0.0 or is_on_wall():
				_after_every = 0.0
				_body_hit.active = false
				velocity.x = facing * 3.0 * t
				pose("attack")
				strike(_slash, Vector2(18, -18), 0.12)
				KE.snd(&"sword_slash", &"swing", 2.0)
				Fx.shake(0.15, 0.15)
				_enter(S.DASH_END, _rest(0.6))
		S.DASH_END:
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
			if _timer <= 0.0:
				_enter(S.STALK, _rest(0.4))
		# ─ 연격 ─
		S.COMBO_WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			pose("windup")
			warn(progress())
			if _timer <= 0.0:
				var last := _combo == _combo_max - 1
				_enter(S.COMBO_HIT, 0.22)
				velocity.x = facing * (8.0 if last else 6.0) * t
				pose("attack" if _combo % 2 == 0 else "attack2")
				if last:
					strike(_big_slash, Vector2(22, -20), 0.12)
					Fx.shake(0.2, 0.15)
					KE.snd(&"sword_wave", &"swing", 2.0)
				else:
					strike(_slash, Vector2(20, -18), 0.1)
				KE.snd(&"sword_slash", &"swing", 0.0)
		S.COMBO_HIT:
			velocity.x = move_toward(velocity.x, 0.0, 1000.0 * delta)
			if _timer <= 0.0:
				_combo += 1
				if _combo < _combo_max:
					face_player()
					_enter(S.COMBO_WINDUP, _tg(COMBO_WINDUPS[_combo]))
				else:
					_enter(S.RECOVER, _rest(0.7))
		# ─ 받아치기 ─
		S.GUARD:
			velocity.x = 0.0
			face_player()
			pose("guard")
			if _timer <= 0.0:
				_enter(S.STALK, _rest(0.3))
		S.COUNTER_WINDUP:
			velocity.x = 0.0
			pose("charge")
			warn(progress())
			if _timer <= 0.0:
				_dash_len = minf(7.0 * t, _room_ahead(facing, 7.0 * t))
				_dash_from = global_position.x
				_enter(S.DASH, 0.35)
				_after_every = 0.025
				strike(_body_hit, Vector2(4, -18), 0.35)
				KE.snd(&"dash", &"dash", 2.0)
		S.GUARD_BROKEN:
			velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
			pose("hurt" if progress() < 0.3 else "kneel")
			if _timer <= 0.0:
				_enter(S.BACKSTEP, 0.4)
				face_player()
				velocity = Vector2(-facing * 180.0, -200.0)
		# ─ 검압 파동 ─
		S.WAVE_WINDUP:
			velocity.x = 0.0
			pose("windup")
			warn(progress())
			if _timer <= 0.0:
				pose("attack")
				_enter(S.WAVE_SLAM, _rest(0.6))
				_send_waves()
		S.WAVE_SLAM:
			velocity.x = 0.0
			if _timer <= 0.0:
				_enter(S.STALK, _rest(0.4))
		# ─ 일섬 ─
		S.ISSEN_STANCE:
			velocity.x = 0.0
			pose("special")
			warn(clampf(progress() * 1.2, 0.0, 1.0))
			if p:
				facing = 1 if dx >= 0.0 else -1
				_aim_issen(p)
			if not _cue_done and _timer <= ISSEN_CUE:
				_cue_done = true
				KE.snd(&"sword_clash", &"blip", 4.0, 0.0)
				Fx.flash(Color(1, 1, 1, 0.12), 0.08)
			if _timer <= 0.0:
				_issen_strike()
		S.ISSEN_AFTER:
			velocity.x = 0.0
			pose("attack" if progress() < 0.6 else "idle")
			if _timer <= 0.0:
				if _issen_queue > 0:
					_issen_queue -= 1
					_start_issen(0.75)
				else:
					_enter(S.STALK, _rest(0.3))
		# ─ 공중 베기 (2페이즈) ─
		S.AIR_JUMP:
			pose("charge")
			if velocity.y >= 0.0 or _timer <= 0.0:
				_enter(S.AIR_HANG, _tg(AIR_HANG))
				velocity = Vector2.ZERO
				flying = true
				_air_target = Vector2(p.global_position.x, KE.floor_at(self, p.global_position.x, p.global_position.y))
		S.AIR_HANG:
			velocity = Vector2.ZERO
			pose("windup")
			warn(progress())
			face_player()
			if _timer > 0.12:
				_air_target = Vector2(p.global_position.x, KE.floor_at(self, p.global_position.x, p.global_position.y))
			if _timer <= 0.0:
				_enter(S.AIR_DIVE, 0.6)
				_after_every = 0.03
				strike(_big_slash, Vector2(10, -20), 0.6)
				KE.snd(&"sword_slash", &"swing", 2.0)
		S.AIR_DIVE:
			pose("attack")
			var to := _air_target - global_position
			velocity = to.normalized() * AIR_DIVE_SPEED_T * t
			if to.length() < 10.0 or is_on_floor() or _timer <= 0.0:
				flying = false
				_after_every = 0.0
				_big_slash.active = false
				velocity = Vector2.ZERO
				Fx.shake(0.3, 0.2)
				KE.snd(&"slam", &"slam", 0.0)
				KE.debris(global_position, 10, Color("#8a8aa0"), Vector2.UP, 140.0)
				_air_left -= 1
				_enter(S.AIR_LAND, _rest(0.35 if _air_left > 0 else 0.8))
		S.AIR_LAND:
			velocity.x = 0.0
			pose("attack")
			if _timer <= 0.0:
				if _air_left > 0:
					_air_jump()
				else:
					_enter(S.STALK, _rest(0.3))
		S.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
			if vis.pose_t > 0.35:
				pose("idle")
			if _timer <= 0.0:
				_enter(S.STALK, _rest(0.3))
		S.BACKSTEP:
			pose("charge")
			if is_on_floor() and _dur - _timer > 0.1:
				velocity.x = 0.0
				if _issen_pending:
					_issen_pending = false
					_start_issen(_tg(ISSEN_STANCE))
				else:
					_enter(S.STALK, _rest(0.5))
		S.PHASE:
			velocity.x = 0.0
			pose("guard" if progress() < 0.6 else "idle")
			if _timer <= 0.0:
				_issen_cd = 4.0
				_enter(S.STALK, 0.3)


func _choose(adx: float) -> void:
	face_player()
	var t := GameConst.TILE
	if _forced_issen or (_issen_cd <= 0.0 and randf() < 0.7):
		_forced_issen = false
		_issen_queue = 1 if phase == 2 and randf() < 0.5 else 0
		if adx < 6.0 and _room_ahead(-facing, 4.0 * t) > 3.0 * t:
			# 거리가 가까우면 크게 물러나 거리를 벌린 뒤 칼을 거둔다
			_issen_pending = true
			_enter(S.BACKSTEP, 0.5)
			velocity = Vector2(-facing * 300.0, -240.0)
			KE.snd(&"dash", &"dash", -2.0)
		else:
			_start_issen(_tg(ISSEN_STANCE))
		return
	var options: Array[String] = []
	if adx > 7.0:
		options = ["dash", "dash", "wave"]
	elif adx > 3.5:
		options = ["combo", "dash", "guard", "wave"]
	else:
		options = ["combo", "combo", "guard", "back"]
	if phase == 2:
		options.append("air")
		options.append("air")
	var pick: String = options[randi() % options.size()]
	if pick == _last and randf() < 0.75:
		pick = options[(options.find(pick) + 1) % options.size()]
	_last = pick
	match pick:
		"dash":
			_dash_len = minf(DASH_LEN_T * t, _room_ahead(facing, DASH_LEN_T * t))
			_enter(S.DASH_WINDUP, _tg(DASH_WINDUP))
			KE.snd(&"swing", &"swing", -10.0)
		"combo":
			_combo = 0
			_combo_max = 4 if phase == 2 else 3
			_enter(S.COMBO_WINDUP, _tg(COMBO_WINDUPS[0]))
		"guard":
			_parries = 0
			_enter(S.GUARD, GUARD_TIME)
			KE.snd(&"sword_clash", &"block", -8.0)
		"wave":
			_enter(S.WAVE_WINDUP, _tg(WAVE_WINDUP))
			KE.snd(&"swing", &"charger_windup", -6.0)
		"back":
			_enter(S.BACKSTEP, 0.4)
			velocity = Vector2(-facing * 200.0, -220.0)
		"air":
			_air_left = 2
			_air_jump()


func _air_jump() -> void:
	var p := player()
	face_player()
	_enter(S.AIR_JUMP, 0.6)
	flying = false
	velocity.y = -430.0
	if p:
		velocity.x = clampf((p.global_position.x - global_position.x) * 0.6, -160.0, 160.0)
	KE.snd(&"jump", &"jump", 0.0)


func _send_waves() -> void:
	var t := GameConst.TILE
	Fx.shake(0.3, 0.2)
	KE.snd(&"sword_wave", &"slam", 2.0)
	KE.debris(global_position + Vector2(facing * 14.0, 0), 12, Color("#c8c8d8"), Vector2(facing, -1), 160.0)
	KE.wave(global_position + Vector2(facing * 14.0, 0), facing, WAVE_SPEED_T * t, 24.0 * t, "sword", 20.0)
	if phase == 2:
		# 두 줄: 하나는 늦게 (점프 타이밍을 두 번)
		var tw := create_tween()
		tw.tween_interval(0.42)
		tw.tween_callback(func() -> void:
			if _alive:
				KE.wave(global_position + Vector2(facing * 14.0, 0), facing, WAVE_SPEED_T * t, 24.0 * t, "sword", 20.0))


func _start_issen(stance: float) -> void:
	_cue_done = false
	_enter(S.ISSEN_STANCE, stance)
	KE.snd(&"sword_clash", &"block", -6.0)
	KE.snd(&"heartbeat", &"overload_pulse", -2.0)
	var p := player()
	if p:
		face_player()
		_aim_issen(p)


## 일섬의 끝점: 세라 너머 5칸(벽 앞에서 멈춤)
func _aim_issen(p: Player) -> void:
	var t := GameConst.TILE
	var dir := 1 if p.global_position.x >= global_position.x else -1
	var want := absf(p.global_position.x - global_position.x) + 5.0 * t
	var room := _room_ahead(dir, 40.0 * t)
	var len := clampf(want, 3.0 * t, room)
	_issen_from = global_position
	_issen_to = Vector2(global_position.x + dir * len, global_position.y)


func _issen_strike() -> void:
	var cut := IssenCut.new()
	cut.setup(_issen_from, _issen_to)
	Fx.effect_parent().add_child(cut)
	# 지나간 자리에 잔상
	for i in 6:
		var k := (i + 0.5) / 6.0
		var ghost_pos := _issen_from.lerp(_issen_to, k)
		var g := CharacterVisual.new()
		g.setup("leonie")
		g.set_pose("charge")
		g.position = ghost_pos
		g.scale.x = float(facing)
		g.modulate = Color(AFTER_COL, 0.5 * (1.0 - k * 0.5))
		g.material = Fx.add_material
		Fx.effect_parent().add_child(g)
		var tw := g.create_tween()
		tw.tween_property(g, "modulate:a", 0.0, 0.35 + k * 0.2)
		tw.tween_callback(g.queue_free)
	global_position = _issen_to
	warn(0.0)
	_enter(S.ISSEN_AFTER, _rest(ISSEN_AFTER))
	pose("attack")
	_issen_cd = ISSEN_CD.x if phase == 1 else ISSEN_CD.y
	KE.snd(&"sword_slash", &"shoot_heavy", 6.0, 0.0)
	KE.snd(&"sword_wave", &"storm_final", 0.0, 0.0)
	Fx.flash(Color(1, 1, 1, 0.55), 0.2)
	Fx.shake(0.5, 0.35)
	Fx.hitstop(0.08)


func modify_damage(hit: Hit) -> float:
	if not engaged or state in [S.PHASE, S.DEFEATED]:
		return 0.0
	if hit.kind == &"ally":
		return 0.3
	if state == S.GUARD_BROKEN:
		return BROKEN_MULT
	if state == S.GUARD and hit_side(hit, 4.0, 1) > 0:
		return 1.0 if hit.kind in GUARD_BREAK else 0.0
	return 1.0


func _on_blocked(hit: Hit) -> void:
	if state == S.GUARD:
		parry_fx(hit)
		_parries += 1
		if _parries >= 2:
			_enter(S.COUNTER_WINDUP, _tg(0.3))
			KE.snd(&"sword_clash", &"block", 0.0)
		return
	super(hit)


func _on_hit(hit: Hit, _dir: int) -> void:
	if state == S.GUARD and hit.kind in GUARD_BREAK:
		_enter(S.GUARD_BROKEN, GUARD_BREAK_TIME)
		velocity.x = -facing * 70.0
		Fx.shake(0.25, 0.2)
		KE.snd(&"sword_clash", &"block", 2.0)
		KE.star_burst(global_position + Vector2(facing * 10.0, -24), 14, Color(1, 0.9, 0.7), 140.0, 0.4)
		var hud := get_tree().get_first_node_in_group(&"hud")
		if hud and hud.has_method("banner"):
			hud.banner("자세가 무너졌다!", 1.0)
	_check_thresholds()


## 체력 기준: 80%에서 첫 일섬(반드시 보여 줌), 50%에서 2페이즈
func _check_thresholds() -> void:
	if phase == 1 and hp > 0 and hp * 2 <= max_hp:
		phase = 2
		_area_timers.clear()
		for c in get_children():
			if c is EnemyAttackArea:
				(c as EnemyAttackArea).active = false
		_after_every = 0.0
		flying = false
		_enter(S.PHASE, PHASE_TIME)
		phase_changed.emit(2)
		Fx.shake(0.4, 0.5)
		Fx.flash(Color(1, 0.3, 0.3, 0.2), 0.3)
		Fx.ring(global_position + Vector2(0, -20), 6.0, 90.0, Color(1, 1, 1, 0.8), 0.5, 3.0)
		KE.snd(&"sword_wave", &"roar", 0.0)
	if hp < max_hp * 0.8 and not has_meta("first_issen"):
		set_meta("first_issen", true)
		_forced_issen = true # 체력 80%에서 첫 일섬 (반드시 보여 준다)


func _die(_dir: int) -> void:
	_alive = false
	_record_defeat("kills", false) # 등급 처치는 세지 않는다 (예전 동작 그대로)
	_enter(S.DEFEATED, 0.0)
	Fx.hitstop(0.2)
	Fx.slowmo(0.35, 0.8)
	Fx.flash(Color(1, 1, 1, 0.4), 0.3)
	Fx.shake(0.4, 0.4)
	KE.snd(&"sword_clash", &"block", 4.0)
	_disable_body()
	_after_every = 0.0
	warn(0.0)
	pose("kneel")
	defeated.emit(self)


func _physics_process(delta: float) -> void:
	super(delta)
	if not _alive:
		pose("kneel")
		_post_death_fall(delta)


# ─── 예고 그림 (뒤집지 않는 층) ─────────────────────────

func _draw_fx(c: Node2D) -> void:
	var t := GameConst.TILE
	match state:
		S.DASH_WINDUP:
			var k := progress()
			var a := KE.warn_pulse(_t, k)
			c.draw_line(Vector2(facing * 8.0, -1), Vector2(facing * _dash_len, -1), Color(KE.DANGER, 0.25 + 0.5 * a), 2.0)
			c.draw_line(Vector2(facing * _dash_len, -6), Vector2(facing * _dash_len, 2), Color(KE.DANGER, 0.6 * a), 2.0)
		S.WAVE_WINDUP:
			var a2 := KE.warn_pulse(_t, progress())
			for i in 5:
				var x := facing * (16.0 + i * 3.0 * t)
				c.draw_line(Vector2(x, -1), Vector2(x + facing * 1.5 * t, -1), Color(KE.DANGER, 0.5 * a2), 2.0)
		S.AIR_HANG:
			var a3 := KE.warn_pulse(_t, progress())
			var to := _air_target - global_position
			c.draw_line(Vector2(0, -18), to, Color(KE.DANGER, 0.25 + 0.45 * a3), 2.0)
			c.draw_set_transform(to + Vector2(0, -1), 0.0, Vector2(1.0, 0.3))
			c.draw_arc(Vector2.ZERO, 16.0, 0, TAU, 18, Color(KE.DANGER, 0.4 + 0.5 * a3), 2.0)
			c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		S.ISSEN_STANCE:
			# 화면을 가로지르는 붉은 띠: 그녀의 높이 (바닥 ~ 2.6칸)
			var k4 := progress()
			var a4 := KE.warn_pulse(_t, k4)
			var x0 := _issen_from.x - global_position.x
			var x1 := _issen_to.x - global_position.x
			var lo := minf(x0, x1)
			var hi := maxf(x0, x1)
			var band := Rect2(lo - 6.0, -2.6 * t, hi - lo + 12.0, 2.6 * t)
			c.draw_rect(band, Color(KE.DANGER, 0.08 + 0.12 * a4))
			c.draw_line(Vector2(lo - 400.0, -1.3 * t), Vector2(hi + 400.0, -1.3 * t), Color(KE.DANGER, 0.15 + 0.4 * a4 * k4), 1.0)
			c.draw_line(Vector2(lo, -2.6 * t), Vector2(hi, -2.6 * t), Color(KE.DANGER, 0.35 * a4), 1.0)
			c.draw_line(Vector2(lo, 0), Vector2(hi, 0), Color(KE.DANGER, 0.35 * a4), 1.0)
			if _cue_done:
				# 칼자루의 흰 반짝임 (지금 피해라!)
				var s := 4.0 + (ISSEN_CUE - _timer) * 50.0
				KArt.star4(c, Vector2(facing * 4.0, -14), s, Color(1, 1, 1, 0.95))
				KArt.glow(c, Vector2(facing * 4.0, -14), s * 2.0, Color(1, 1, 1, 0.6), 3)
				c.draw_line(Vector2(lo, -1.3 * t), Vector2(hi, -1.3 * t), Color(1, 1, 1, 0.7), 1.0)
		S.PHASE:
			var k5 := progress()
			for i in 6:
				var ang := TAU * i / 6.0 + _t
				c.draw_line(Vector2(0, -20) + Vector2(cos(ang), sin(ang)) * (10.0 + 30.0 * k5), Vector2(0, -20) + Vector2(cos(ang), sin(ang)) * (16.0 + 40.0 * k5), Color(1, 1, 1, 0.6 * (1.0 - k5)), 1.0)


## 일섬 자세 동안 화면을 어둡게 (그녀 주위를 넓게 덮는 반투명 검정)
func _draw_dark(c: Node2D) -> void:
	if state != S.ISSEN_STANCE:
		return
	var k := clampf(progress() * 3.0, 0.0, 1.0)
	c.draw_rect(Rect2(-1400, -900, 2800, 1300), Color(0.0, 0.0, 0.02, 0.5 * k))


## 일섬의 섬광: 지나간 길을 따라 흰 선 + 짧은 순간의 피해 판정(피해 2, 대시로 피함)
class IssenCut extends EnemyAttackArea:
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	var _t := 0.0

	func setup(p_from: Vector2, p_to: Vector2) -> void:
		from = p_from
		to = p_to
		global_position = Vector2((from.x + to.x) * 0.5, from.y)

	func _ready() -> void:
		cause = &"leonie_issen"
		damage = 2
		dodgeable = true
		active = true
		z_index = 8
		material = Fx.add_material
		var s := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(absf(to.x - from.x) + 20.0, 2.6 * GameConst.TILE)
		s.shape = r
		s.position = Vector2(0, -1.3 * GameConst.TILE)
		add_child(s)
		# 갈라지는 불티
		for i in 8:
			var k := (i + 0.5) / 8.0
			var p := from.lerp(to, k) + Vector2(0, -1.3 * GameConst.TILE)
			Fx.burst(p, 4, {spread = 40.0, direction = Vector2(0, -1 if i % 2 == 0 else 1), speed_min = 40.0, speed_max = 120.0, lifetime = 0.35,
				gradient = Palette.fade_gradient(Color(1, 1, 1)), size_min = 1.0, size_max = 2.0, gravity = Vector2.ZERO, add = true})

	func _physics_process(delta: float) -> void:
		_t += delta
		if _t > 0.1:
			active = false
		if _t > 0.6:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var half := absf(to.x - from.x) * 0.5 + 10.0
		var y := -1.3 * GameConst.TILE
		var k := clampf(1.0 - _t / 0.6, 0.0, 1.0)
		var w := 10.0 * k * k + 1.0
		draw_rect(Rect2(-half, y - w * 0.5, half * 2.0, w), Color(1, 1, 1, 0.85 * k))
		draw_rect(Rect2(-half, y - w * 1.5, half * 2.0, w * 3.0), Color(0.75, 0.85, 1.0, 0.25 * k))
		draw_line(Vector2(-half - 30.0, y), Vector2(half + 30.0, y), Color(1, 1, 1, k), 1.0)
