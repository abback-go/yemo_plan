class_name AureliaBoss
extends EnemyBase
## 아우렐리아 — 4장 강자 보스 (docs/chapter4.md 4절·7.4절, docs/bible/characters.md 3절). 지금까지 가장 강한 적. 체력 9000(보통), 3페이즈.
## 대본이 engaged = true로 켤 때까지 창을 짚고 서 있다. 그림은 전용 CharacterVisual("aurelia")에 잔상·예고·빛 효과를 덧그림(aurelia_boss_visual.gd).
##
## 1페이즈 (100~66%) "규율의 창": 찌르기(0.55초 예고 — 창을 뒤로 당기고 창끝이 붉게) · 세 번 찌르기 · 빛의 창 비(세라 둘레 바닥에 붉은 예고 → 금빛 창이 꽂힘)
##   · 막기(정면 화염탄을 가끔 창을 비스듬히 들어 막음 → 반격 찌르기)
## 66%: 무릎 꿇고 "…아직입니다." → 빛 폭발로 밀어냄 → 2페이즈 "신성 돌진":
##   **신성 돌진**: 금빛 걸음으로 투기장 끝으로 사라졌다 나타남 → 화면을 가로지르는 금빛 예고 띠(가장자리 붉음, 0.9초) → 잔상을 끌며 반대편 끝까지 돌진(2 피해).
##   띠 높이는 세라가 선 높이(바닥/발판). 점프(띠 높이 2.4칸)·대시 무적·다른 높이의 발판으로 피한다. 돌진 뒤 미끄러지며 멈춘 0.8초가 빈틈.
##   **광륜 던지기**: 머리 뒤 광륜을 들어(붉은 테 0.55초) 원반처럼 던짐 — 날아갔다 돌아옴(점프로 넘음). 광륜이 없는 동안 피해 1.2배.
##   불꽃 방벽으로 광륜을 되쏘면 광륜이 주인을 쳐서 1.5초 휘청.
## 33%: 바깥 신들의 목소리 — 광륜이 금 가고 흰빛, 눈이 하얗게(폭주) → 3페이즈: 연속 돌진(2~3번, 양쪽에서) · 흰 창 비(두 물결) · 갈라진 광륜 두 번
##   · **심판의 창**: 하늘로 떠올라 화면만 한 빛의 창을 만든다(2.6초 — 바닥의 "안전한 그늘"이 파랗게 표시됨) → 내리꽂혀 투기장 전체로 흰금 충격파(2 피해).
##     엄폐 기둥 뒤(꽂힌 곳에서 보아 기둥에 가려진 곳)에 있거나, 불꽃 방벽·대시 무적이면 무사. 뒤에 2초 동안 지쳐 무릎(피해 1.5배).
## 레오니(동료): stagger(초)로 돌진·찌르기를 받아쳐 끊는다(Ally.special이 부름). 대본은 charge_windup_active()를 보고 레오니를 부를 수 있다.
##   block_charge_at(노드): 다음 돌진이 그 노드 x에서 막힌다(레오니가 정면으로 받아내는 연출).
## 쓰러지면 터지지 않고 무릎 꿇은 채 남는다(대본이 purify()·vanish()로 마무리).

signal staggered
signal charge_started(dir: int)

enum S {
	DORMANT, IDLE, WALK,
	THRUST_WIND, THRUST, THRUST_REC,
	RAIN_CAST, RAIN_REC,
	CHARGE_MOVE, CHARGE_WIND, CHARGE, CHARGE_REC,
	HALO_WIND, HALO_WAIT,
	JUDG_RISE, JUDG_WIND, JUDG_FALL, JUDG_REC,
	GUARD, STAGGER, PHASE, DOWN,
}

const HaloDisc := preload("res://enemies/ch4/aurelia_halo_disc.gd")
const H := preload("res://enemies/ch4/holy.gd")
const VIS := preload("res://enemies/ch4/aurelia_boss_visual.gd")
const T := 16.0

const HP := 9000
const WALK_T := 3.4
const KEEP_T := Vector2(2.5, 6.0)
const THRUST_WIND := 0.55
const THRUST_FAST := 0.32
const THRUST_TIME := 0.16
const THRUST_SPEED_T := 15.0
const THRUST_REC := 0.45
const THRUST_REACH := 52.0
const RAIN_CAST := 0.7
const CHARGE_WIND := 0.9
const CHARGE_WIND_P3 := 0.75
const CHARGE_SPEED_T := 34.0
const CHARGE_BAND := 38.0 ## 돌진 띠 높이 (px, 약 2.4칸)
const CHARGE_REC := 0.8
const HALO_WIND := 0.55
const HALO_SPEED_T := 17.0
const HALO_RANGE_T := 13.0
const JUDG_WIND := 2.6
const JUDG_WAVE_T := 34.0
const JUDG_REC := 2.0
const GUARD_TIME := 0.6
const PHASE_TIME := 2.2
const PHASE3_TIME := 3.0
const LINES_P1: Array[String] = ["물러나십시오.", "이단의 불은 이곳에 닿지 않습니다.", "판정합니다."]
const LINES_P3: Array[String] = ["물러—나—십시오.", "빛을… 더럽히는… 자.", "문을… 열어라…", "주여— 대답— 하소서—"]

var state: S = S.DORMANT
var phase := 1
const PHASE_AT: Array[float] = [0.66, 0.33] ## 1→2, 2→3 페이즈 문턱 (체력 비율, 한 방에 넘지 못함)
var berserk := false
var halo_out := false ## 광륜을 던진 동안 (그림에서 머리 뒤 광륜을 숨김)
var charge_dir := 1
var charge_y := 0.0 ## 돌진 띠 가운데 높이 (전역)
var charge_from := 0.0
var charge_to := 0.0
var jud_x := 0.0 ## 심판의 창 꽂히는 곳
var jud_floor := 0.0
var jud_wave := -1.0 ## 충격파 반지름 (px), -1 = 없음
var jud_safe: Array = [] ## [x0, x1] 안전한 그늘 구간 (전역)
var arena_l := 0.0
var arena_r := 0.0
var floor_y := 0.0
var top_y := 0.0
var discs: Array = []
## 시험용: 비어 있지 않으면 이 순서대로 패턴을 고른다 (thrust·triple·rain·charge·halo·judgment)
var test_queue: Array = []
var _timer := 0.0
var _dur := 0.0
var _combo := 0
var _charges_left := 0
var _count := 0
var _last := ""
var _guard_cd := 0.0
var _counter := false
var _wave_hit := false
var _blocker: Node2D = null
var _speak_t := 6.0
var _afterimage_t := 0.0
var _setup_done := false
var _spear: H.SegmentArea
var _band: H.SegmentArea


func _init() -> void:
	engaged = false


func _build() -> void:
	max_hp = HP
	body_size = Vector2(16, 40)
	is_boss = true
	is_elite = false
	knock_mult = 0.0
	launch_mult = 0.0
	display_name = "아우렐리아"
	subtitle = "루멘 대신전의 수호자"
	kind_id = "aurelia_boss"
	var v: Node2D = VIS.new()
	v.set("enemy", self)
	_visual = v
	add_child(v)
	_spear = H.SegmentArea.new()
	_spear.cause = &"aurelia"
	_spear.dodgeable = true
	_spear.active = false
	add_child(_spear)
	_band = H.SegmentArea.new()
	_band.cause = &"aurelia_charge"
	_band.damage = 2
	_band.dodgeable = true
	_band.active = false
	add_child(_band)


func _ready() -> void:
	super()
	collision_mask = GameConst.L_WORLD # 발판은 무시 (발판은 세라의 피난처)


# ─── 대본·그림용 ────────────────────────────────────────

func progress() -> float:
	return clampf(1.0 - _timer / _dur, 0.0, 1.0) if _dur > 0.0 else 1.0


func is_charging() -> bool:
	return state == S.CHARGE


func charge_windup_active() -> bool:
	return state == S.CHARGE_WIND


func can_be_parried() -> bool:
	return state in [S.CHARGE_WIND, S.CHARGE, S.THRUST_WIND, S.THRUST, S.HALO_WIND, S.WALK, S.IDLE]


## 레오니가 다음 돌진을 이 노드 위치에서 받아낸다
func block_charge_at(n: Node2D) -> void:
	_blocker = n


## 동료(레오니)의 받아치기: 지금 공격을 끊고 sec초 휘청 (받는 피해 1.5배)
func stagger(sec: float) -> bool:
	if not _alive or state in [S.DORMANT, S.PHASE, S.DOWN, S.JUDG_RISE, S.JUDG_WIND, S.JUDG_FALL]:
		return false
	_attacks_off()
	collision_mask = GameConst.L_WORLD
	flying = false
	_go(S.STAGGER, sec)
	velocity = Vector2(-facing * 6.0 * T, -120.0)
	H.snd(&"sword_clash", &"block", 2.0)
	H.snd(&"parry", &"hit_heavy", 0.0)
	Fx.hitstop(0.12)
	Fx.shake(0.4, 0.3)
	var at := global_position + Vector2(facing * 10, -24)
	Fx.burst(at, 30, {
		spread = 180.0, speed_min = 60.0, speed_max = 240.0, lifetime = 0.45,
		gradient = H.gold_grad(), size_min = 1.0, size_max = 3.0, gravity = Vector2(0, 300), add = true,
	})
	Fx.ring(at, 4.0, 46.0, H.WHITE, 0.3, 3.0)
	staggered.emit()
	return true


func purify() -> void:
	berserk = false
	var v := _char()
	if v:
		v.set_meta("berserk", false)
		v.set_pose("kneel")


func vanish() -> void:
	queue_free()


func _char() -> CharacterVisual:
	return _visual.get("ch") as CharacterVisual if _visual else null


func pose(p: String) -> void:
	var v := _char()
	if v:
		v.set_pose(p)


func _go(s: S, time := 0.0) -> void:
	state = s
	_timer = time
	_dur = time


# ─── 투기장 ─────────────────────────────────────────────

func _setup_arena() -> void:
	_setup_done = true
	var space := get_world_2d().direct_space_state
	floor_y = global_position.y
	top_y = H.ceiling_above(space, Vector2(global_position.x, floor_y - 30.0), 20.0 * T)
	arena_l = _wall_x(-1)
	arena_r = _wall_x(1)


## 방의 바깥 벽 (엄폐 기둥은 낮아서 위로 넘겨 본다)
func _wall_x(dir: int) -> float:
	var space := get_world_2d().direct_space_state
	var y := floor_y - 6.0 * T
	var r := space.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(global_position.x, y), Vector2(global_position.x + dir * 80.0 * T, y), GameConst.L_WORLD))
	if r.is_empty():
		var w := World.get_world()
		return 8.0 if dir < 0 else (w.room.size_px.x - 8.0 if w and w.room else global_position.x + 30.0 * T)
	var p: Vector2 = r.position
	return p.x


# ─── 매 프레임 ──────────────────────────────────────────

func _ai(delta: float) -> void:
	if not _setup_done:
		_setup_arena()
	_timer -= delta
	_guard_cd -= delta
	_tick_discs(delta)
	_tick_judgment(delta)
	var p := player()
	if state == S.DORMANT:
		velocity.x = 0.0
		pose("idle")
		if engaged:
			_go(S.IDLE, 1.0)
			_speak("…판정합니다.")
		return
	if state == S.DOWN:
		velocity.x = 0.0
		return
	if p == null or not p.is_alive():
		_attacks_off()
		velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
		if state != S.PHASE:
			pose("idle" if not berserk else "berserk_idle")
		return
	_speak_t -= delta
	if _speak_t <= 0.0 and state in [S.IDLE, S.WALK]:
		_speak_t = randf_range(9.0, 14.0)
		var lines := LINES_P3 if berserk else LINES_P1
		_speak(lines[randi() % lines.size()])
	match state:
		S.IDLE, S.WALK:
			_ai_neutral(p, delta)
		S.THRUST_WIND:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _timer <= 0.0:
				_do_thrust()
		S.THRUST:
			velocity.x = facing * THRUST_SPEED_T * T
			_place_spear()
			if _timer <= 0.0:
				_spear.active = false
				if _combo > 0:
					_combo -= 1
					face_player()
					_go(S.THRUST_WIND, Difficulty.telegraph(THRUST_FAST))
					pose("windup")
					H.snd(&"spear", &"charger_windup", -6.0)
				else:
					_go(S.THRUST_REC, THRUST_REC)
					pose("guard" if not berserk else "berserk_guard")
		S.THRUST_REC, S.RAIN_REC:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _timer <= 0.0:
				_to_idle(Difficulty.rest(_cadence(0.7)))
		S.RAIN_CAST:
			velocity.x = 0.0
			if _timer <= 0.0:
				_go(S.RAIN_REC, 0.4)
		S.CHARGE_MOVE:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_begin_charge_windup()
		S.CHARGE_WIND:
			velocity = Vector2.ZERO
			if Engine.get_physics_frames() % 3 == 0:
				H.sparkle(global_position + Vector2(charge_dir * 30, -20), 3, 16.0, 0.0, 0.3, berserk)
			if _timer <= 0.0:
				_start_charge()
		S.CHARGE:
			_charge(delta)
		S.CHARGE_REC:
			velocity.x = move_toward(velocity.x, 0.0, 1400.0 * delta)
			if _timer <= 0.0:
				flying = false
				if _charges_left > 0:
					_charges_left -= 1
					_prepare_charge(p, true)
				else:
					_to_idle(Difficulty.rest(_cadence(0.6)))
		S.HALO_WIND:
			velocity.x = 0.0
			if _timer <= 0.0:
				_throw_halo(p)
		S.HALO_WAIT:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if discs.is_empty() or _timer <= 0.0:
				halo_out = false
				_to_idle(Difficulty.rest(_cadence(0.5)))
		S.JUDG_RISE:
			velocity = Vector2((jud_x - global_position.x) * 3.0, (top_y + 4.0 * T - global_position.y) * 3.0)
			if _timer <= 0.0:
				_go(S.JUDG_WIND, Difficulty.telegraph(JUDG_WIND))
				H.snd(&"heartbeat", &"overload_warn", 0.0)
				Fx.shake(0.1, JUDG_WIND)
		S.JUDG_WIND:
			velocity = Vector2((jud_x - global_position.x) * 3.0, (top_y + 4.0 * T - global_position.y) * 3.0)
			if _timer <= 0.0:
				_judgment_fall()
		S.JUDG_FALL:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				flying = false
				_go(S.JUDG_REC, JUDG_REC)
				pose("berserk_kneel")
		S.JUDG_REC:
			velocity.x = 0.0
			if _timer <= 0.0:
				_to_idle(Difficulty.rest(0.6))
		S.GUARD:
			velocity.x = 0.0
			if _timer <= 0.0:
				if _counter:
					_counter = false
					face_player()
					_combo = 0
					_go(S.THRUST_WIND, Difficulty.telegraph(THRUST_FAST + 0.08))
					pose("windup")
				else:
					_to_idle(0.3)
		S.STAGGER:
			velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
			pose("hurt" if not berserk else "berserk_hurt")
			if _timer <= 0.0:
				_to_idle(0.4)
		S.PHASE:
			velocity.x = 0.0
			_tick_phase(delta)


func _cadence(base: float) -> float:
	return base * BossKit.phase_mult(phase, [1.0, 0.9, 0.75])


func _to_idle(wait: float) -> void:
	_attacks_off()
	collision_mask = GameConst.L_WORLD
	flying = false
	_go(S.IDLE, wait)
	pose("idle" if not berserk else "berserk_idle")


func _attacks_off() -> void:
	_spear.active = false
	_band.active = false


## 걷기·간격 맞추기·패턴 고르기
func _ai_neutral(p: Player, delta: float) -> void:
	face_player()
	var dx := p.global_position.x - global_position.x
	var adx := absf(dx) / T
	var want := 0.0
	if adx > KEEP_T.y:
		want = facing * WALK_T * T
	elif adx < KEEP_T.x:
		want = -facing * WALK_T * 0.7 * T
	velocity.x = move_toward(velocity.x, want, 700.0 * delta)
	if absf(velocity.x) > 10.0:
		if state != S.WALK:
			state = S.WALK
		pose("run" if not berserk else "berserk_run")
	else:
		pose("idle" if not berserk else "berserk_idle")
	if _timer <= 0.0 and is_on_floor():
		_choose(p)


func _choose(p: Player) -> void:
	_count += 1
	var adx := absf(p.global_position.x - global_position.x) / T
	var pool: Array[String] = []
	match phase:
		1:
			pool.append_array(["thrust", "triple", "rain"] if adx < 7.0 else ["rain", "triple", "rain"])
		2:
			pool.append_array(["charge", "halo", "rain", "triple", "charge"])
		3:
			if _count % 4 == 0 or _last == "phase3":
				pool.append("judgment")
			else:
				pool.append_array(["charge", "halo", "rain", "charge"])
	var pick := BossKit.pick_attack(pool, _last, test_queue, "thrust")
	_last = pick
	match pick:
		"thrust":
			_combo = 0
			_go(S.THRUST_WIND, Difficulty.telegraph(THRUST_WIND))
			pose("windup" if not berserk else "berserk_windup")
			H.snd(&"spear", &"charger_windup", -4.0)
		"triple":
			_combo = 2
			_go(S.THRUST_WIND, Difficulty.telegraph(THRUST_WIND))
			pose("windup" if not berserk else "berserk_windup")
			H.snd(&"spear", &"charger_windup", -4.0)
		"rain":
			_lance_rain(p)
		"charge":
			_charges_left = (randi() % 2 + 1) if phase == 3 else 0
			_prepare_charge(p, false)
		"halo":
			_go(S.HALO_WIND, Difficulty.telegraph(HALO_WIND))
			pose("cast" if not berserk else "berserk_cast")
			H.snd(&"star_twinkle", &"reveal", -4.0)
		"judgment":
			_start_judgment(p)


# ─── 찌르기 ─────────────────────────────────────────────

func _do_thrust() -> void:
	_go(S.THRUST, THRUST_TIME)
	_spear.damage = 1
	_spear.active = true
	_place_spear()
	pose(("attack2" if _combo == 1 else "attack") if not berserk else ("berserk_attack2" if _combo == 1 else "berserk_attack"))
	H.snd(&"spear", &"swing", 0.0)
	H.snd(&"sword_slash", &"whoosh", -6.0)
	Fx.shake(0.08, 0.12)
	var tip := global_position + Vector2(facing * THRUST_REACH, -24)
	Fx.burst(tip, 8, {
		direction = Vector2(facing, 0), spread = 25.0, speed_min = 60.0, speed_max = 160.0, lifetime = 0.25,
		gradient = H.white_grad() if berserk else H.gold_grad(), size_min = 1.0, size_max = 2.0, gravity = Vector2.ZERO, add = true,
	})


func _place_spear() -> void:
	var y := global_position.y - 24.0
	if _combo == 1:
		_spear.set_segment(global_position + Vector2(facing * 4, -18), global_position + Vector2(facing * 40, -50), 14.0)
	else:
		_spear.set_segment(Vector2(global_position.x + facing * 6, y), Vector2(global_position.x + facing * THRUST_REACH, y), 12.0)


# ─── 빛의 창 비 ─────────────────────────────────────────

func _lance_rain(p: Player) -> void:
	_go(S.RAIN_CAST, RAIN_CAST)
	pose("cast" if not berserk else "berserk_cast")
	H.snd(&"holy_charge", &"ignite", -4.0)
	var space := get_world_2d().direct_space_state
	var n := 5 if phase == 1 else (7 if phase == 2 else 9)
	var waves := 1 if phase < 3 else 2
	var base := p.global_position.x
	for w in waves:
		for i in n:
			var k := i - (n - 1) / 2
			var x := base + k * 2.6 * T + (1.3 * T if w == 1 else 0.0)
			x = clampf(x, arena_l + T, arena_r - T)
			var fy := H.floor_below(space, Vector2(x, p.global_position.y - 30.0), 10.0 * T)
			if fy == INF:
				fy = floor_y
			var warn := Difficulty.telegraph(0.95 + absf(k) * 0.12 + w * 0.7)
			H.lance_drop(x, fy, top_y + 8.0, warn, 1, berserk, false)


# ─── 신성 돌진 ──────────────────────────────────────────

## 투기장 끝으로 금빛 걸음 (세라에게서 먼 쪽) → 예고
func _prepare_charge(p: Player, chained: bool) -> void:
	_clear_discs()
	var space := get_world_2d().direct_space_state
	# 띠 높이: 세라가 선 높이 (바닥 또는 발판)
	var stand := H.floor_below(space, p.global_position + Vector2(0, -6), 3.0 * T)
	if stand == INF:
		stand = floor_y
	charge_y = stand - CHARGE_BAND * 0.5
	var from_left := p.global_position.x > (arena_l + arena_r) * 0.5
	if chained:
		from_left = charge_dir < 0 # 연속 돌진은 반대쪽에서
	charge_dir = 1 if from_left else -1
	charge_from = (arena_l + 2.0 * T) if from_left else (arena_r - 2.0 * T)
	charge_to = (arena_r - 1.5 * T) if from_left else (arena_l + 1.5 * T)
	# 사라짐 (빛기둥)
	H.sparkle(global_position + Vector2(0, -20), 20, 8.0, 80.0, 0.6, berserk)
	Fx.ring(global_position + Vector2(0, -20), 4.0, 30.0, H.GOLD, 0.25, 2.0)
	H.snd(&"warp", &"whoosh", -4.0)
	_go(S.CHARGE_MOVE, 0.28)
	velocity = Vector2.ZERO
	flying = true
	var tw := create_tween()
	tw.tween_interval(0.12)
	tw.tween_callback(func() -> void:
		if state != S.CHARGE_MOVE:
			return
		global_position = Vector2(charge_from, stand)
		facing = charge_dir
		H.sparkle(global_position + Vector2(0, -20), 20, 8.0, 80.0, 0.6, berserk)
		Fx.ring(global_position + Vector2(0, -20), 30.0, 4.0, H.GOLD, 0.25, 2.0))


func _begin_charge_windup() -> void:
	_go(S.CHARGE_WIND, Difficulty.telegraph(CHARGE_WIND_P3 if phase == 3 else CHARGE_WIND))
	pose("charge" if not berserk else "berserk_charge")
	H.snd(&"holy_charge", &"charger_windup", 0.0)
	Sfx.play(&"charger_windup", -2.0, 0.0)
	charge_started.emit(charge_dir)


func _start_charge() -> void:
	_go(S.CHARGE, 2.0)
	collision_mask = 0 # 신성 돌진은 엄폐 기둥도 꿰뚫고 지나간다 (돌 부스러기)
	_band.damage = 2
	_band.active = true
	H.snd(&"holy_charge", &"charger_charge", 4.0)
	Sfx.play(&"dash", 0.0, 0.0)
	Fx.shake(0.35, 0.3)
	Fx.flash(Color(1.0, 0.92, 0.65, 0.18) if not berserk else Color(1, 1, 1, 0.22), 0.12)


func _charge(delta: float) -> void:
	velocity = Vector2(charge_dir * CHARGE_SPEED_T * T, 0.0)
	var cy := charge_y
	_band.set_segment(Vector2(global_position.x - charge_dir * 12.0, cy), Vector2(global_position.x + charge_dir * 58.0, cy), CHARGE_BAND)
	_afterimage_t -= delta
	if _afterimage_t <= 0.0:
		_afterimage_t = 0.035
		_visual.call("afterimage")
	if Engine.get_physics_frames() % 2 == 0:
		Fx.burst(global_position + Vector2(-charge_dir * 10, -2), 4, {
			direction = Vector2(-charge_dir, -0.6), spread = 40.0, speed_min = 40.0, speed_max = 140.0, lifetime = 0.4,
			gradient = H.white_grad() if berserk else H.gold_grad(), size_min = 1.0, size_max = 3.0, gravity = Vector2(0, 200), add = true,
		})
		Fx.shake(0.12, 0.1)
	# 레오니가 받아냄
	if _blocker and is_instance_valid(_blocker):
		var bx := _blocker.global_position.x
		if (charge_dir > 0 and global_position.x + 30.0 >= bx) or (charge_dir < 0 and global_position.x - 30.0 <= bx):
			global_position.x = bx - charge_dir * 30.0
			_blocker = null
			_band.active = false
			stagger(1.6)
			return
	# 기둥을 꿰뚫을 때 돌 부스러기
	if Engine.get_physics_frames() % 3 == 0:
		var q := PhysicsPointQueryParameters2D.new()
		q.position = global_position + Vector2(charge_dir * 8, -20)
		q.collision_mask = GameConst.L_WORLD
		if not get_world_2d().direct_space_state.intersect_point(q).is_empty():
			Fx.burst(q.position, 10, {
				direction = Vector2(charge_dir, -0.5), spread = 60.0, speed_min = 60.0, speed_max = 200.0, lifetime = 0.5,
				gradient = Palette.fade_gradient(Color("#b8b4cc")), size_min = 1.5, size_max = 3.5, gravity = Vector2(0, 500),
			})
			Fx.shake(0.25, 0.15)
	var arrived := (charge_dir > 0 and global_position.x >= charge_to) or (charge_dir < 0 and global_position.x <= charge_to)
	if arrived or _timer <= 0.0:
		_band.active = false
		collision_mask = GameConst.L_WORLD
		velocity.x = charge_dir * 6.0 * T
		_go(S.CHARGE_REC, Difficulty.rest(CHARGE_REC if _charges_left == 0 else 0.35))
		pose("guard" if not berserk else "berserk_guard")
		H.snd(&"slam", &"slam", -2.0)
		Fx.burst(global_position, 16, {
			direction = Vector2(-charge_dir, -1), spread = 50.0, speed_min = 40.0, speed_max = 150.0, lifetime = 0.45,
			gradient = Palette.fade_gradient(Color("#a8a0c0")), size_min = 1.5, size_max = 3.0, gravity = Vector2(0, 400),
		})


# ─── 광륜 던지기 ────────────────────────────────────────

func _throw_halo(p: Player) -> void:
	halo_out = true
	var n := 2 if phase == 3 else 1
	for i in n:
		var d := HaloDisc.new()
		d.boss = self
		d.white = berserk
		d.delay = i * 0.55
		var y := floor_y - 20.0
		d.start = global_position + Vector2(facing * 10, -34)
		d.lane_y = y
		d.dir = float(signf(p.global_position.x - global_position.x)) if p.global_position.x != global_position.x else float(facing)
		d.range_px = HALO_RANGE_T * T
		d.speed = HALO_SPEED_T * T
		Fx.effect_parent().add_child(d)
		discs.append(d)
	_go(S.HALO_WAIT, 4.0)
	pose("attack" if not berserk else "berserk_attack")
	H.snd(&"spear", &"whoosh", 0.0)


func _tick_discs(_delta: float) -> void:
	for d in discs.duplicate():
		if not is_instance_valid(d):
			discs.erase(d)


## 광륜이 되쏘아져 돌아와 주인을 침
func halo_reflected_hit(dmg: int) -> void:
	var h := Hit.make(dmg, &"reflect", global_position + Vector2(facing * 20, -30))
	take_hit(h)
	if _alive and state != S.PHASE:
		stagger(1.5)


# ─── 심판의 창 ──────────────────────────────────────────

func _clear_discs() -> void:
	for d in discs:
		if is_instance_valid(d):
			(d as Node).queue_free()
	discs.clear()
	halo_out = false


func _start_judgment(p: Player) -> void:
	_clear_discs()
	jud_x = clampf(p.global_position.x, arena_l + 6.0 * T, arena_r - 6.0 * T)
	jud_floor = floor_y
	jud_wave = -1.0
	_wave_hit = false
	_compute_safe()
	flying = true
	_go(S.JUDG_RISE, 0.8)
	pose("berserk_special")
	H.snd(&"sky_crack", &"roar", 0.0)
	_speak("심판—을.")
	Fx.flash(Color(1, 1, 1, 0.2), 0.3)


## 꽂히는 곳에서 바닥을 따라 보아 기둥에 가려지는 구간 = 안전한 그늘
func _compute_safe() -> void:
	jud_safe.clear()
	var space := get_world_2d().direct_space_state
	var origin := Vector2(jud_x, jud_floor - 16.0)
	var x := arena_l + 4.0
	var run_start := INF
	while x <= arena_r - 4.0:
		var tgt := Vector2(x, jud_floor - 16.0)
		var r := space.intersect_ray(PhysicsRayQueryParameters2D.create(origin, tgt, GameConst.L_WORLD))
		var blocked := not r.is_empty() and absf(x - jud_x) > 8.0
		if blocked:
			var stand := space.intersect_ray(PhysicsRayQueryParameters2D.create(tgt, tgt + Vector2(0, 20), GameConst.L_WORLD))
			var inside := space.intersect_point(_pp(tgt))
			if not stand.is_empty() and inside.is_empty():
				if run_start == INF:
					run_start = x
			elif run_start != INF:
				jud_safe.append([run_start, x - 4.0])
				run_start = INF
		elif run_start != INF:
			jud_safe.append([run_start, x - 4.0])
			run_start = INF
		x += 4.0
	if run_start != INF:
		jud_safe.append([run_start, arena_r - 4.0])


func _pp(p: Vector2) -> PhysicsPointQueryParameters2D:
	var q := PhysicsPointQueryParameters2D.new()
	q.position = p
	q.collision_mask = GameConst.L_WORLD
	return q


func _judgment_fall() -> void:
	_go(S.JUDG_FALL, 0.9)
	global_position = Vector2(jud_x, jud_floor - 2.0)
	velocity = Vector2.ZERO
	jud_wave = 0.0
	H.snd(&"meteor_impact", &"explode", 4.0)
	H.snd(&"holy_hit", &"slam", 2.0)
	Fx.shake(1.0, 0.8)
	Fx.hitstop(0.1)
	Fx.flash(Color(1, 1, 0.95, 0.65), 0.45)
	Fx.ring(Vector2(jud_x, jud_floor - 20.0), 10.0, 160.0, H.WHITE, 0.6, 6.0)
	Fx.burst(Vector2(jud_x, jud_floor - 10.0), 60, {
		direction = Vector2.UP, spread = 80.0, speed_min = 80.0, speed_max = 360.0, lifetime = 0.9,
		gradient = H.white_grad(), size_min = 1.5, size_max = 4.0, gravity = Vector2(0, 300), add = true,
	})


## 충격파가 투기장을 휩씀: 세라 x를 지날 때 한 번 판정 (엄폐·방벽·무적이면 무사)
func _tick_judgment(delta: float) -> void:
	if jud_wave < 0.0:
		return
	jud_wave += JUDG_WAVE_T * T * delta
	var p := player()
	if p and p.is_alive() and not _wave_hit and absf(p.global_position.x - jud_x) <= jud_wave:
		_wave_hit = true
		if _judgment_safe(p):
			H.sparkle(p.center(), 12, 10.0, 20.0, 0.5, true)
			if H.player_warding(p):
				Fx.ring(H.ward_center(p), 6.0, 40.0, Color(1.0, 0.7, 0.4), 0.3, 3.0)
				StyleRank.bonus("심판을 막았다!", 20.0)
			else:
				StyleRank.bonus("그늘에 숨었다!", 12.0)
		else:
			p.take_damage(2, &"aurelia_judgment", jud_x)
	if jud_wave > maxf(jud_x - arena_l, arena_r - jud_x) + 2.0 * T:
		jud_wave = -1.0


func _judgment_safe(p: Player) -> bool:
	if p.is_invincible() or H.player_warding(p):
		return true
	var space := get_world_2d().direct_space_state
	var origin := Vector2(jud_x, jud_floor - 16.0)
	var r := space.intersect_ray(PhysicsRayQueryParameters2D.create(origin, p.center(), GameConst.L_WORLD))
	return not r.is_empty()


# ─── 피격·페이즈 ────────────────────────────────────────

func modify_damage(hit: Hit) -> float:
	if state in [S.DORMANT, S.PHASE, S.DOWN, S.JUDG_RISE, S.JUDG_WIND] or not engaged:
		return 0.0
	if state == S.GUARD and hit.kind in [&"bolt", &"bolt_heavy", &"ally"]:
		return 0.0
	var mult := 1.0
	if state in [S.STAGGER, S.JUDG_REC]:
		mult = 1.5
	elif halo_out:
		mult = 1.2
	if hit.kind == &"ally":
		mult *= 0.6 # 레오니의 검도 창대로 흘린다 (틈을 만드는 건 받아치기)
	# 정면 화염탄을 가끔 막는다 (1·2페이즈)
	if phase < 3 and state in [S.IDLE, S.WALK] and _guard_cd <= 0.0 and (hit.kind == &"bolt" or hit.kind == &"bolt_heavy"):
		var from := -float(hit.direction) if hit.direction != 0 else signf(hit.source_pos.x - global_position.x)
		if from == float(facing) and randf() < 0.35:
			_guard_cd = 3.0
			_counter = randf() < 0.6
			_go(S.GUARD, GUARD_TIME)
			pose("guard")
			return 0.0
	return mult


func _on_blocked(hit: Hit) -> void:
	if state == S.GUARD:
		var at := global_position + Vector2(facing * 12, -26)
		H.snd(&"parry", &"block", -2.0)
		Fx.ring(at, 3.0, 20.0, H.GOLD, 0.2, 2.0)
		H.sparkle(at, 8, 4.0, 10.0, 0.3)
		return
	if state in [S.PHASE, S.JUDG_RISE, S.JUDG_WIND]:
		H.sparkle(global_position + Vector2(0, -24), 4, 8.0)
		return
	super(hit)


func take_hit(hit: Hit) -> void:
	if state == S.DOWN:
		return
	var before := hp
	super(hit)
	if not _alive or hp <= 0:
		return
	var n := BossKit.phase_cross(self, phase, before, PHASE_AT)
	if n > 0:
		_start_phase(n)


func _start_phase(n: int) -> void:
	phase = n
	_attacks_off()
	_charges_left = 0
	halo_out = false
	flying = false
	velocity = Vector2.ZERO
	_go(S.PHASE, PHASE_TIME if n == 2 else PHASE3_TIME)
	phase_changed.emit(n)
	if n == 2:
		pose("kneel")
		_speak("…아직입니다.")
		H.snd(&"holy_hit", &"slam", -2.0)
	else:
		pose("kneel")
		enraged.emit()
		H.snd(&"sky_crack", &"roar", 2.0)
		_speak("주여— 어째서— 대답이—")


var _phase_burst := false


func _tick_phase(_delta: float) -> void:
	var k := progress()
	if phase == 2:
		if k > 0.55 and not _phase_burst:
			_phase_burst = true
			pose("cast")
			_light_burst(false)
		if _timer <= 0.0:
			_phase_burst = false
			_last = ""
			_to_idle(0.3)
	else:
		if k > 0.45 and not berserk:
			berserk = true
			var v := _char()
			if v:
				v.set_meta("berserk", true)
			pose("berserk_special")
			_light_burst(true)
			_speak("물러—나—십시오.")
		if _timer <= 0.0:
			_last = "phase3"
			_to_idle(0.2)


## 빛 폭발: 세라를 밀어냄 (피해 없음)
func _light_burst(white: bool) -> void:
	Fx.shake(0.7, 0.6)
	Fx.flash(Color(1, 1, 1, 0.5) if white else Color(1.0, 0.92, 0.6, 0.4), 0.4)
	var c := global_position + Vector2(0, -24)
	Fx.ring(c, 8.0, 180.0, H.WHITE if white else H.GOLD, 0.6, 5.0)
	Fx.ring(c, 4.0, 120.0, H.GOLD, 0.45, 3.0)
	Fx.burst(c, 50, {
		spread = 180.0, speed_min = 60.0, speed_max = 260.0, lifetime = 0.8, damping = 40.0,
		gradient = H.white_grad() if white else H.gold_grad(), size_min = 1.5, size_max = 3.5, gravity = Vector2(0, 40), add = true,
	})
	H.snd(&"star_burst", &"explode", 0.0)
	var p := player()
	if p and p.is_alive() and p.global_position.distance_to(global_position) < 9.0 * T:
		var d := signf(p.global_position.x - global_position.x)
		p.velocity = Vector2((d if d != 0.0 else 1.0) * 380.0, -240.0)


func _speak(text: String) -> void:
	var l := Label.new()
	l.text = text
	var ls := LabelSettings.new()
	ls.font_size = 10
	ls.font_color = Color(1.0, 0.92, 0.7) if not berserk else Color(1, 1, 1)
	ls.outline_size = 3
	ls.outline_color = Color("#14101c")
	l.label_settings = ls
	l.position = global_position + Vector2(-34, -66)
	l.z_index = 22
	Fx.effect_parent().add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 8.0, 2.2)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.6).set_delay(1.8)
	tw.tween_callback(l.queue_free)
	if berserk:
		var l2 := l.duplicate() as Label
		l2.position += Vector2(2, 1)
		l2.modulate = Color(1, 1, 1, 0.35)
		Fx.effect_parent().add_child(l2)
		var tw2 := l2.create_tween()
		tw2.tween_property(l2, "modulate:a", 0.0, 2.2)
		tw2.tween_callback(l2.queue_free)


# ─── 쓰러짐: 무릎 꿇은 채 남는다 ────────────────────────

func _die(_dir: int) -> void:
	if state == S.DOWN:
		return
	_attacks_off()
	for d in discs:
		if is_instance_valid(d):
			(d as Node).queue_free()
	discs.clear()
	jud_wave = -1.0
	_alive = false
	hp = 0
	_record_defeat()
	Fx.hitstop(0.2)
	Fx.slowmo(0.35, 0.8)
	Fx.shake(0.8, 0.8)
	Fx.flash(Color(1, 1, 1, 0.6), 0.5)
	H.snd(&"sky_crack", &"roar", 0.0)
	collision_layer = 0
	collision_mask = GameConst.L_WORLD # 돌진 중(벽 통과)에 쓰러져도 투기장 바닥에 내려앉게
	_hurtbox.set_deferred("monitorable", false)
	_flash = 0.0 # 마지막 일격의 흰 번쩍임이 남지 않게
	flying = false
	velocity = Vector2.ZERO
	_go(S.DOWN)
	pose("berserk_kneel" if berserk else "kneel")
	defeated.emit(self)


func _physics_process(delta: float) -> void:
	super(delta)
	if not _alive:
		_t += delta
		_flash = maxf(_flash - delta, 0.0) # 기반도 줄이므로 2배 빠르게 걷힌다 (예전 동작 그대로)
		_post_death_fall(delta)
		if _visual:
			_visual.queue_redraw()


# ═══════════════════════════════════════════════════════════
# 던진 광륜 (원반처럼 날아갔다 돌아옴). 불꽃 방벽으로 되쏘면 주인을 친다
# ═══════════════════════════════════════════════════════════
