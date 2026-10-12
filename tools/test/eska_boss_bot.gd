extends Node
## 검성 보스전 자동 플레이 봇 (시험용 — 전투 시간·맞은 횟수로 난이도를 잰다).
## 시나리오에서 [2, "attach", "../tools/test/eska_boss_bot.gd"] 로 붙인다 (eska_boss_bot.json).
## 루프2: 에스카의 기술을 모두 쓴다 —
##   이동 · 기본 베기 · 천열 · 낙성(↓A, 조금 떨어진 틈에) · 순간이동(예고 끝에 맞춰 피함) · 점프(비검 파도·낙화 충격파)
##   · 단공(↑A)으로 다가오는 비검 파도·머리 위 천검 칼빛을 지움 (단공이 튕겨내기를 할 줄 알 때만 — 모르면 예전처럼 점프·피하기)
##   · 대마법(게이지 가득: 무너짐·묶임·긴 틈에 종말의 운석, 오래 기다리면 아무 틈에나)
##   · 물약: 체력 3 이하면 치유(F) · 메아리(↑F)를 틈 앞에 · 반격 자세(눈 감음)에 속박/비명(↓F) 던지기
##   · 틈 달이기(루프3): 천열을 쓰고 0.3~0.5초 뒤 ↓F를 던져 천열이 찢은 틈에 스미게 (진함 + 강자 저항 무시 + 꿰맬 때 한 번 더)
##   · 단공은 "딱 맞춤"(발사체가 몸 70px 안에 왔을 때 지움 → 쿨다운 초기화·게이지)을 노려 그 거리에서 누름
##   · 그림자 일섬(루프5): 분신이 있으면 천열(+틈 달이기)·낙성·베기로 분신을 먼저 베고, 대마법이 차 있으면 분신 줄에 씀.
##     일섬선은 단공으로 가르거나(딱 맞춤 때) 터지기 직전에 뛰어 넘음
## 다른 작업자가 만드는 기능(단공 튕겨내기·물약 개편·틈 달이기)은 있으면 쓰고, 없으면 건너뛴다 — 합친 뒤 그대로 다시 잴 수 있게.
## 사람처럼 반응이 늦도록 예고를 본 뒤 REACT초가 지나야 움직인다. 2초마다 상태, 끝나면 "BOT RESULT" 한 줄.
## 솜씨 조절(환경 변수):
##   ESKA_BOT_MISS = 피하기를 놓칠 확률(기본 0) · ESKA_BOT_SKIP = 반격 틈을 그냥 보낼 확률(기본 0)
##   ESKA_BOT_REACT = 반응 시간(기본 0.12) · ESKA_BOT_SEED = 난수 씨앗 · ESKA_BOT_BELT = 허리띠 "heal,echo,bind" (빈 값이면 기본)
##   ESKA_BOT_KIT = 0이면 예전처럼 마법·물약·대마법 없이 (비교용) · ESKA_BOT_DEFLECT = 1이면 단공 튕겨내기를 처음부터 시도
##   예) 잘하는 사람: ESKA_BOT_MISS=0.2 ESKA_BOT_SKIP=0.3 · 서툰 사람: ESKA_BOT_MISS=0.35 ESKA_BOT_SKIP=0.5 ESKA_BOT_REACT=0.2

const REACT_DEFAULT := 0.12 ## 예고를 알아차리는 데 걸리는 시간
const BLINK_LEAD := 0.07 ## 공격이 나가기 이만큼 전에 순간이동 (무적 0.15~0.2초)
const NEAR := 64.0 ## 때릴 때 붙는 거리
const SAFE := 120.0 ## 기다릴 때 거리
const NAK_MIN := 60.0 ## 낙성을 쓰는 거리 (이보다 가까우면 천열·베기)
const NAK_MAX := 220.0
const THROW_MIN := 30.0 ## 물약을 던지는 거리 (병이 포물선으로 약 130px 날아감)
const THROW_MAX := 135.0
const HEAL_AT := 3 ## 체력이 이 아래(이하)면 치유
const ULT_WANT := "doom" ## 고를 대마법 (한 방 3600 — 무너짐·묶임에 맞춰)
const ULT_IMPATIENT := 6.0 ## 게이지가 가득 찬 뒤 이만큼 지나면 아무 틈에나 쓴다
const DANGONG_FIRE := 0.06 ## 단공을 누른 뒤 판정이 생기기까지 (EEska.CAST_FIRE)
const PERFECT_AIM := 58.0 ## 판정이 생기는 순간 파도가 몸에서 이만큼 안이면 "딱 맞춤" (EKenseiFx.Wave 판정 반너비 15 포함, 기준 70)
const PERFECT_MIN := 22.0 ## 이보다 가까우면 이미 늦음 (파도에 맞음)
const DEFLECT_RAIN_LEAD := 0.18 ## 천검 칼빛이 떨어지기 이만큼 전에 단공 (판정 0.22초 안에 떨어지기 전)
const RIFT_THROW_MIN := 0.3 ## 천열 뒤 이만큼~ 지나 틈에 던짐 (병이 손 근처 틈을 무시하는 0.12초·40px를 지나 천열 틈에 닿게)
const RIFT_THROW_MAX := 0.5
const ROW_OUT := 52.0 ## 분신 줄 끝에서 이만큼 바깥에 서서 천열 (일섬선 ±45 밖, 천열이 줄 전체에 닿는 거리)
const ROW_TOL := 10.0
const RIFT_THROW_WAIT := 0.3 ## 던질 때가 됐는데 다른 동작 중이면 이만큼 더 기다렸다가 포기
const DEFLECT_CHECK := 0.25 ## 단공 뒤 이만큼 지나 발사체가 남아 있으면 "튕겨내기 없음"으로 봄
const DEFLECT_GIVE_UP := 2 ## 이만큼 실패하면 튕겨내기를 그만 씀
const SLOT_HEAL := 0
const SLOT_ECHO := 1
const SLOT_THROW := 2
const PROJECTILE_GROUP := &"es_projectile"

var stage: Node
var _t := 0.0
var _seq: Array = [] ## [남은 시간, 동작, 누름?]
var _log_t := 0.0
var _done := false
var _seen_st := -1 ## 마지막으로 본 검성 상태
var _seen_t := 0.0 ## 그 상태를 본 뒤 시간
var _dodged := false ## 이번 공격은 이미 피했나
var dodges := 0
var missed := 0
var miss_rate := 0.0
var skip_rate := 0.0
var react := REACT_DEFAULT
var use_kit := true
var _skip := false ## 이번 틈은 그냥 보냄
var _done_t := 0.0
var _fight_frames := 0 ## 싸움 중 프레임 수 (게임 시간 = /60 — 멈춤·느려짐 연출 포함, 실제 체감 시간)
const QUIT_AFTER := 7.0 ## 이기고 이만큼 뒤 끝냄 (끝 화면까지 보이게)
const GIVE_UP := 600.0 ## 이만큼(초) 지나도 못 이기면 끝냄

# 기술 쓴 횟수 (결과 줄)
var n_cheonyeol := 0
var n_nakseong := 0
var n_dangong := 0
var n_deflect := 0 ## 단공으로 지운 발사체 수 (확인된 것)
var n_ult := 0
var n_heal := 0
var n_echo := 0
var n_throw := 0
var n_throw_ctr := 0
var n_rift_throw := 0
var n_perfect := 0 ## 단공 "딱 맞춤" (쿨다운이 바로 초기화된 것)
var _rift_plan := -1.0 ## 천열 뒤 틈에 던질 때까지 남은 시간 (-1 = 없음)
var _brews0 := 0 ## 시작 때 EPotions.rift_brews (틈에 스민 병 수 셈)
var _rift_to: Node2D ## 틈 달이기로 노리는 표적 (없으면 검성)
var n_shadow := 0 ## 본 분신 수
var n_shadow_kill := 0 ## 베어 없앤 분신 수
var n_shadow_hurt := 0 ## 그림자 일섬선에 맞은 수
var _shadow_seen := {} ## 분신 instance_id → true
var _shadow_on := false ## 분신이 나와 있는 중
var _shadow_skip := false ## 이번 분신 무리는 상대하지 않음 (ESKA_BOT_SKIP 확률)
var n_break := 0 ## 검성 버팀이 무너진 횟수
var n_hurt := 0 ## 맞은 횟수 (봇이 직접 셈 — 치유와 상관없이)
var _break_hooked: Node = null
var _last_hp := EEska.MAX_HP
var _deflect_ok := false ## 단공이 튕겨내기를 할 줄 아나 (소스로 짐작 + 실제로 확인)
var _deflect_fail := 0
var _deflect_watch: Array = [] ## [남은 시간, 노드]
var _full_t := 0.0 ## 게이지가 가득 찬 뒤 시간
var _ctr_thrown := false ## 이번 반격 자세에 이미 던졌나
var _act_cd := 0.0 ## 물약·대마법 고르기 등 "생각하는" 동작 사이 최소 간격


func _ready() -> void:
	stage = get_tree().current_scene
	miss_rate = _env_f("ESKA_BOT_MISS", 0.0)
	skip_rate = _env_f("ESKA_BOT_SKIP", 0.0)
	react = _env_f("ESKA_BOT_REACT", REACT_DEFAULT)
	use_kit = OS.get_environment("ESKA_BOT_KIT") != "0"
	if OS.has_environment("ESKA_BOT_SEED"):
		seed(int(OS.get_environment("ESKA_BOT_SEED"))) # 판마다 다른 흐름 (검성의 기술 고르기도 바뀜)
	_deflect_ok = use_kit and (_source_has("res://proto/eska/e_skill_fx.gd", "es_projectile") or _source_has("res://proto/eska/e_eska.gd", "es_projectile")
		or _source_has("res://proto/eska/e_magic_fx.gd", "es_projectile")) or OS.get_environment("ESKA_BOT_DEFLECT") == "1"
	print("BOT skill miss=%.2f skip=%.2f react=%.2f kit=%s deflect_guess=%s" % [miss_rate, skip_rate, react, str(use_kit), str(_deflect_ok)])


func _env_f(name: String, def: float) -> float:
	return float(OS.get_environment(name)) if OS.has_environment(name) and OS.get_environment(name) != "" else def


## 스크립트 소스에 글자가 있나 (다른 작업자의 기능이 들어왔는지 짐작 — 실제 동작은 쓰면서 확인)
func _source_has(path: String, what: String) -> bool:
	if not ResourceLoader.exists(path):
		return false
	var sc := load(path) as GDScript
	return sc != null and sc.source_code.contains(what)


## 처음 한 번: 허리띠를 정함 (ESKA_BOT_BELT)
func _setup_belt(e: EEska) -> void:
	var belt := OS.get_environment("ESKA_BOT_BELT")
	if belt == "":
		return
	var ids := belt.split(",")
	for i in mini(ids.size(), 3):
		if EPotions.has(ids[i]):
			e.belt.set_slot(i, ids[i], false)


## 그려지는 프레임마다 (멈춤 연출 중에도 하나씩 — 사람이 느끼는 시간)
func _process(_delta: float) -> void:
	if stage != null and int(stage.get("fight")) == EBossStage.F.FIGHT:
		_fight_frames += 1


func _physics_process(delta: float) -> void:
	_t += delta
	_act_cd = maxf(_act_cd - delta, 0.0)
	if _rift_plan > -RIFT_THROW_WAIT:
		_rift_plan -= delta
	_run_seq(delta)
	_tick_deflect_watch(delta)
	var e: EEska = stage.get("eska")
	var bo: Variant = stage.get("boss")
	var b: EKensei = bo if is_instance_valid(bo) else null
	if e == null:
		return
	if not e.hurt_taken.is_connected(_on_hurt):
		e.hurt_taken.connect(_on_hurt)
		_setup_belt(e)
		_brews0 = EPotions.rift_brews
	if e.hp > _last_hp:
		_last_hp = e.hp # 치유 물약 (신호 없이 오름)

	_log_t -= delta
	if _log_t <= 0.0:
		_log_t = 2.0
		print("BOT t=%.1f fight=%.1fs %s boss=%s gauge=%d%%" % [_t, float(_fight_frames) / 60.0, stage.fight_state(), stage.boss_info(), int(e.gauge_ratio() * 100.0)])
	var fight: int = stage.get("fight")
	if fight == EBossStage.F.WON:
		if not _done:
			_done = true
			_done_t = _t
			print("BOT RESULT won fight_time=%.1fs (game frames/60) deaths=%d hits_taken=%d dodges=%d missed=%d %s" % [float(_fight_frames) / 60.0, int(stage.get("deaths")), int(stage.get("hits_taken")), dodges, missed, _kit_summary()])
		_release_all()
		if _t - _done_t > QUIT_AFTER:
			get_tree().quit()
		return
	if _t > GIVE_UP:
		print("BOT RESULT gave_up fight_time=%.1fs %s boss=%s %s" % [float(_fight_frames) / 60.0, stage.fight_state(), stage.boss_info(), _kit_summary()])
		get_tree().quit()
		return
	if e.is_dead() or e.controls_locked:
		_release_all()
		return
	if fight == EBossStage.F.WAIT:
		_hold("es_right", true)
		_hold("es_left", false)
		return
	if fight != EBossStage.F.FIGHT or not is_instance_valid(b) or b.is_dead():
		_release_all()
		return
	if b.st != _seen_st:
		_seen_st = b.st
		_seen_t = 0.0
		_dodged = false
		_skip = randf() < skip_rate
		if b.st != EKensei.S.CTR_STANCE:
			_ctr_thrown = false
	else:
		_seen_t += delta
	if _break_hooked != b:
		_break_hooked = b
		b.poise_broken.connect(func(_x: EEnemy) -> void: n_break += 1)
	_full_t = _full_t + delta if e.gauge_ratio() >= 1.0 else 0.0
	_fight(e, b)


func _kit_summary() -> String:
	return "shadows=%d killed=%d shadow_hurt=%d hurts=%d breaks=%d cheonyeol=%d nakseong=%d dangong=%d deflect=%d(perfect=%d ok=%s) ult=%d heal=%d echo=%d throw=%d(ctr=%d rift=%d brewed=%d)" % [
		n_shadow, n_shadow_kill, n_shadow_hurt, n_hurt, n_break, n_cheonyeol, n_nakseong, n_dangong, n_deflect, n_perfect, str(_deflect_ok), n_ult, n_heal, n_echo, n_throw, n_throw_ctr, n_rift_throw,
		EPotions.rift_brews - _brews0]


func _fight(e: EEska, b: EKensei) -> void:
	var dx := b.global_position.x - e.global_position.x
	var dist := absf(dx)
	var to := 1 if dx > 0.0 else -1
	if use_kit and _seq.is_empty() and _deflect(e, b):
		return
	if _dodge(e, b, dist, to):
		return
	var punish := b.st in [EKensei.S.SHADOW_HOLD, EKensei.S.SHADOW_REST, EKensei.S.IAI_REST, EKensei.S.TRI_REST, EKensei.S.WAVE_REST, EKensei.S.CTR_RELAX, EKensei.S.LEAP_REST, EKensei.S.RAIN_HOLD, EKensei.S.RAIN_REST, EKensei.S.IDLE, EKensei.S.WALK, EKensei.S.IAI_SHEATHE, EKensei.S.IAI_FOLLOW] or b.break_t > 0.0 or b.is_bound()
	if b.st == EKensei.S.CTR_STANCE or b.st == EKensei.S.PHASE or (_skip and b.break_t <= 0.0 and not b.is_bound()):
		punish = false
	if use_kit and _seq.is_empty() and _act_cd <= 0.0 and _kit(e, b, dist, to, punish):
		return
	if use_kit and _shadows(e, b):
		return
	var want := NEAR if punish else SAFE
	if dist > want + 14.0:
		_walk(to)
	elif dist < want - 14.0 and not punish:
		_walk(-to)
	else:
		_walk(0)
	if not _seq.is_empty():
		return
	if punish and not _wave_near(e):
		if dist < 150.0 and e.facing != to:
			_tap("es_right" if to > 0 else "es_left")
			return
		if dist < 160.0 and e.cd_left("cheonyeol") <= 0.0 and e.is_on_floor():
			n_cheonyeol += 1
			_tap("es_skill")
			# 틈 달이기: 천열이 찢은 틈에 0.3~0.5초 뒤 병을 넣음 (검성이 던지는 거리 안이고 아직 묶이지 않았을 때)
			if use_kit and dist <= THROW_MAX and not b.is_bound() and _slot_is_throw(e, SLOT_THROW):
				_rift_plan = randf_range(RIFT_THROW_MIN, RIFT_THROW_MAX)
				_rift_to = null
		elif use_kit and dist >= NAK_MIN and dist <= NAK_MAX and e.cd_left("nakseong") <= 0.0 and e.facing == to and e.is_on_floor():
			n_nakseong += 1
			_combo([[0.0, "es_down", true], [0.0, "es_skill", true], [0.05, "es_skill", false], [0.08, "es_down", false]])
		elif dist < 150.0 and float(e.get("_atk_cd")) <= 0.0:
			_tap("es_attack")


## 물약·대마법 (쓸 때 true — 이번 프레임은 그것만)
func _kit(e: EEska, b: EKensei, dist: float, to: int, punish: bool) -> bool:
	if e.st != EEska.St.NORMAL or not e.is_on_floor():
		return false
	var calm := b.st in [EKensei.S.IDLE, EKensei.S.WALK, EKensei.S.IAI_REST, EKensei.S.TRI_REST, EKensei.S.WAVE_REST, EKensei.S.LEAP_REST, EKensei.S.RAIN_REST, EKensei.S.CTR_RELAX] or b.break_t > 0.0 or b.is_bound()
	var hazard := _hazard_near(e)
	# 1) 치유: 체력이 낮고 지금 안전하면
	if e.hp <= HEAL_AT and calm and not hazard and (dist > 90.0 or b.break_t > 0.0 or b.is_bound()) and _slot_ready(e, SLOT_HEAL, "heal"):
		n_heal += 1
		_use_slot(SLOT_HEAL)
		return true
	# 2) 반격 자세(눈 감음): 속박·비명을 던져 깸
	if b.st == EKensei.S.CTR_STANCE and not _ctr_thrown and _seen_t >= react and dist >= THROW_MIN and dist <= THROW_MAX and _slot_is_throw(e, SLOT_THROW):
		if e.facing != to:
			_tap("es_right" if to > 0 else "es_left")
			return true
		_ctr_thrown = true
		n_throw += 1
		n_throw_ctr += 1
		_use_slot(SLOT_THROW)
		return true
	# 3) 틈 달이기: 천열 뒤 정해 둔 때가 되면 던짐 (검성 쪽을 보고)
	if _rift_plan <= 0.0 and _rift_plan > -RIFT_THROW_WAIT:
		if is_instance_valid(_rift_to) and not (_rift_to as EEnemy).is_dead():
			var rdx := _rift_to.global_position.x - e.global_position.x
			dist = absf(rdx)
			to = 1 if rdx > 0.0 else -1
		if not _slot_is_throw(e, SLOT_THROW) or dist > THROW_MAX + 20.0:
			_rift_plan = -RIFT_THROW_WAIT
		elif e.facing != to:
			_tap("es_right" if to > 0 else "es_left")
			return true
		else:
			_rift_plan = -RIFT_THROW_WAIT
			n_throw += 1
			n_rift_throw += 1
			_use_slot(SLOT_THROW)
			return true
	# 4) 대마법: 게이지 가득 → 고른 것을 맞춘 뒤 무너짐·묶임·긴 틈에 (오래 기다리면 아무 틈에나)
	if e.gauge_ratio() >= 1.0:
		if e.selected_ult() != ULT_WANT:
			_tap("es_ult_next")
			_act_cd = 0.12
			return true
		var good := _alive_shadows(b).size() >= 2 or b.break_t > 0.6 or b.is_bound() or b.st in [EKensei.S.LEAP_REST, EKensei.S.CTR_RELAX, EKensei.S.IAI_REST, EKensei.S.TRI_REST]
		if (good or (_full_t > ULT_IMPATIENT and punish)) and dist < 260.0 and not hazard:
			n_ult += 1
			_hold("es_left", false)
			_hold("es_right", false)
			_tap("es_bind")
			_act_cd = 0.6
			return true
	# 5) 메아리: 걸려 있지 않고, 검성이 멀거나 쉬는 동안 (천열이 곧 돌아올 때)
	if not _echo_on(e) and calm and not hazard and dist > 110.0 and e.cd_left("cheonyeol") < 1.0 and _slot_ready(e, SLOT_ECHO, "echo"):
		n_echo += 1
		_use_slot(SLOT_ECHO)
		return true
	return false


## 단공으로 발사체 지우기 (쓰면 true)
func _deflect(e: EEska, b: EKensei) -> bool:
	if not _deflect_ok or e.cd_left("dangong") > 0.0 or e.st != EEska.St.NORMAL or not e.is_on_floor():
		return false
	if b.st in [EKensei.S.IAI_WIND, EKensei.S.IAI_DASH, EKensei.S.CTR_WIND, EKensei.S.TRI_CUT, EKensei.S.LEAP_HANG, EKensei.S.LEAP_FALL]:
		return false # 몸으로 오는 공격이 먼저
	var ex := e.global_position.x
	for n: Node in get_tree().get_nodes_in_group(PROJECTILE_GROUP):
		if n.has_meta("bot_deflect"):
			continue
		var target := false
		if n is EKenseiFx.Wave:
			var w := n as EKenseiFx.Wave
			var rel := ex - w.position.x
			var at_fire := absf(rel) - w.speed * DANGONG_FIRE # 판정이 생길 때의 거리
			target = signf(rel) == float(w.dir) and at_fire <= PERFECT_AIM and at_fire >= PERFECT_MIN
		elif n is EKenseiFx.ShadowCut:
			var c := n as EKenseiFx.ShadowCut
			var left := c.delay - c.t
			target = ex > c.band.position.x - 4.0 and ex < c.band.end.x + 4.0 and left > DANGONG_FIRE + 0.02 and left < 0.24
		elif n is EKenseiFx.RainBlade:
			var r := n as EKenseiFx.RainBlade
			target = r.t < r.warn and r.warn - r.t < DEFLECT_RAIN_LEAD and absf(r.position.x - ex) < EKenseiFx.RainBlade.HALF_W + 10.0
		elif n is Node2D:
			target = (n as Node2D).global_position.distance_to(e.center()) < 90.0
		if not target:
			continue
		if randf() < miss_rate:
			n.set_meta("bot_deflect", true)
			missed += 1
			return false
		n.set_meta("bot_deflect", true)
		_deflect_watch.append([DEFLECT_CHECK, n])
		n_dangong += 1
		_hold("es_left", false)
		_hold("es_right", false)
		_combo([[0.0, "es_up", true], [0.0, "es_skill", true], [0.05, "es_skill", false], [0.08, "es_up", false]])
		return true
	return false


## 단공 뒤: 발사체가 지워졌나 확인 (안 지워졌으면 튕겨내기가 아직 없는 것으로 보고 점프·피하기로 돌아감)
func _tick_deflect_watch(delta: float) -> void:
	var keep: Array = []
	for it: Array in _deflect_watch:
		it[0] = float(it[0]) - delta
		if float(it[0]) > 0.0:
			keep.append(it)
			continue
		var n: Variant = it[1]
		var gone: bool = not is_instance_valid(n) or not (n as Node).is_in_group(PROJECTILE_GROUP)
		if gone:
			n_deflect += 1
			var e: EEska = stage.get("eska")
			if e != null and e.cd_left("dangong") <= 0.0:
				n_perfect += 1 # 딱 맞춤이면 쿨다운이 바로 초기화됨
		else:
			_deflect_fail += 1
			if _deflect_fail >= DEFLECT_GIVE_UP and n_deflect == 0:
				_deflect_ok = false
				print("BOT deflect not available — falling back to jump/dodge")
	_deflect_watch = keep


## 살아 있는 분신들
func _alive_shadows(b: EKensei) -> Array:
	var out := []
	for n: Node in b.shadows():
		var sh := n as EEnemy
		if sh != null and not sh.is_dead():
			out.append(sh)
			if not _shadow_seen.has(sh.get_instance_id()):
				_shadow_seen[sh.get_instance_id()] = true
				n_shadow += 1
				sh.died.connect(func(x: EEnemy) -> void:
					if not bool(x.get("expired")):
						n_shadow_kill += 1
					print("BOT SHADOW %s fight=%.1fs" % ["killed" if not bool(x.get("expired")) else "expired", float(_fight_frames) / 60.0]))
	return out


## 그림자 일섬 분신 대응: 줄 끝 바깥(가까운 쪽)으로 나가 줄을 바라보고 천열 한 번으로 줄 전체를 벰(+틈 달이기) · 낙성 · 베기 (쓰면 true)
func _shadows(e: EEska, b: EKensei) -> bool:
	var list := _alive_shadows(b)
	if list.is_empty():
		_shadow_on = false
		return false
	if not _shadow_on:
		_shadow_on = true
		_shadow_skip = randf() < skip_rate # 서툰 사람: 이번 분신은 그냥 둠 (피하기만)
		print("BOT SHADOW set fight=%.1fs cheonyeol_cd=%.1f nakseong_cd=%.1f gauge=%d%% skip=%s" % [float(_fight_frames) / 60.0, e.cd_left("cheonyeol"), e.cd_left("nakseong"), int(e.gauge_ratio() * 100.0), str(_shadow_skip)])
	if _shadow_skip:
		return false
	var lo := INF
	var hi := -INF
	for sh: EEnemy in list:
		lo = minf(lo, sh.global_position.x)
		hi = maxf(hi, sh.global_position.x)
	var ex := e.global_position.x
	# 줄 끝에서 ROW_OUT만큼 바깥 (벽에 막히면 반대쪽)
	var left_spot := lo - ROW_OUT
	var right_spot := hi + ROW_OUT
	var spot := left_spot if absf(ex - left_spot) <= absf(ex - right_spot) else right_spot
	if spot < 330.0:
		spot = right_spot
	elif spot > 1090.0:
		spot = left_spot
	var to := 1 if spot < lo else -1 # 줄을 바라보는 쪽
	var near: EEnemy = list[0]
	for sh: EEnemy in list:
		if absf(sh.global_position.x - ex) < absf(near.global_position.x - ex):
			near = sh
	var d := absf(near.global_position.x - ex)
	if OS.has_environment("ESKA_BOT_DEBUG") and Engine.get_physics_frames() % 10 == 0:
		print("BOT SHDBG ex=%d spot=%d lo=%d hi=%d face=%d to=%d st=%d seq=%d cd=%.2f" % [int(ex), int(spot), int(lo), int(hi), e.facing, to, e.st, _seq.size(), e.cd_left("cheonyeol")])
	if absf(ex - spot) > ROW_TOL * 2.0:
		_walk(1 if spot > ex else -1)
	else:
		_walk(0)
	if not _seq.is_empty() or e.st != EEska.St.NORMAL:
		return true
	var placed := absf(ex - spot) <= ROW_TOL * 2.0
	if placed and e.facing != to:
		_tap("es_right" if to > 0 else "es_left")
		return true
	if placed and e.facing == to and e.cd_left("cheonyeol") <= 0.0 and e.is_on_floor():
		n_cheonyeol += 1
		_tap("es_skill")
		if _slot_is_throw(e, SLOT_THROW):
			_rift_plan = randf_range(RIFT_THROW_MIN, RIFT_THROW_MAX)
			_rift_to = near
		return true
	if d >= NAK_MIN and d <= NAK_MAX and e.cd_left("nakseong") <= 0.0 and e.is_on_floor():
		n_nakseong += 1
		_combo([[0.0, "es_down", true], [0.0, "es_skill", true], [0.05, "es_skill", false], [0.08, "es_down", false]])
		return true
	if d < 130.0 and e.facing == to and float(e.get("_atk_cd")) <= 0.0:
		_tap("es_attack")
	return true


func _slot_ready(e: EEska, slot: int, want_id: String) -> bool:
	var s: Dictionary = e.belt.slot(slot)
	return String(s.get("id", "")) == want_id and int(s.get("left", 0)) > 0


func _slot_is_throw(e: EEska, slot: int) -> bool:
	var s: Dictionary = e.belt.slot(slot)
	var id := String(s.get("id", ""))
	return id in ["bind", "scream"] and int(s.get("left", 0)) > 0


func _echo_on(e: EEska) -> bool:
	if float(e.mods.get("echo", 0.0)) > 0.0:
		return true
	for it: Dictionary in EPotions.active_buffs(e):
		if String(it.get("id", "")) == "echo":
			return true
	return false


## 허리띠 칸 쓰기: 0 = F · 1 = ↑F · 2 = ↓F
func _use_slot(slot: int) -> void:
	_hold("es_left", false)
	_hold("es_right", false)
	_act_cd = 0.5
	match slot:
		SLOT_ECHO:
			_combo([[0.0, "es_up", true], [0.0, "es_potion", true], [0.05, "es_potion", false], [0.08, "es_up", false]])
		SLOT_THROW:
			_combo([[0.0, "es_down", true], [0.0, "es_potion", true], [0.05, "es_potion", false], [0.08, "es_down", false]])
		_:
			_tap("es_potion")


## 비검 파도·천검 칼빛이 곧 닿나 (물약을 마실 때 본다)
func _hazard_near(e: EEska) -> bool:
	var ex := e.global_position.x
	for n: Node in get_tree().get_nodes_in_group(EKenseiFx.GROUP):
		if n is EKenseiFx.Wave:
			var w := n as EKenseiFx.Wave
			var rel := ex - w.position.x
			if signf(rel) == float(w.dir) and absf(rel) < 200.0:
				return true
		elif n is EKenseiFx.RainBlade:
			var r := n as EKenseiFx.RainBlade
			if r.t < r.warn + 0.1 and absf(r.position.x - ex) < 40.0:
				return true
	return false


## 위험하면 피한다 (피하는 중이면 true)
func _dodge(e: EEska, b: EKensei, dist: float, to: int) -> bool:
	var p := b.p()
	var blink_ready := float(e.get("_blink_cd")) <= 0.0 and (e.is_on_floor() or bool(e.get("_air_blink")))
	match b.st:
		EKensei.S.IAI_WIND:
			var left := b._wind(EKensei.IAI_WIND) - b.st_t
			_walk(0)
			if not _dodged and _seen_t >= react and left <= BLINK_LEAD and blink_ready:
				_blink(to) # 일섬이 지나가는 순간 무적으로 뚫고 그 뒤로
			return true
		EKensei.S.IAI_DASH:
			return true
		EKensei.S.CTR_WIND:
			var left := float(EKensei.CTR_WIND[p]) - b.st_t
			if dist < EKensei.CTR_REACH + 20.0:
				if not _dodged and left <= BLINK_LEAD and blink_ready:
					_blink(-to)
				return true
		EKensei.S.TRI_WIND, EKensei.S.TRI_CUT:
			if dist < 130.0:
				var soon := false
				if b.st == EKensei.S.TRI_WIND:
					soon = b._wind(EKensei.TRI_WIND) - b.st_t <= BLINK_LEAD
				else:
					soon = b._k < 2 and float(EKensei.TRI_GAP[p]) - b.st_t <= BLINK_LEAD
				# 등 뒤가 벽이면 물러설 수 없으니 검성을 뚫고 순간이동
				var cornered := (-to < 0 and e.global_position.x < 370.0) or (-to > 0 and e.global_position.x > 1050.0)
				if soon and dist < 100.0 and blink_ready and _seen_t >= react * 0.5:
					_blink(to if cornered else -to)
				elif not cornered:
					_walk(-to)
				else:
					_walk(0)
				return true
		EKensei.S.LEAP_WIND, EKensei.S.LEAP_UP, EKensei.S.LEAP_HANG, EKensei.S.LEAP_FALL:
			var lx: float = b.get("_leap_x")
			var ldx := e.global_position.x - lx
			if absf(ldx) < EKensei.LEAP_REACH + 16.0:
				var away := 1 if ldx >= 0.0 else -1
				if e.global_position.x < 340.0:
					away = 1
				elif e.global_position.x > 1080.0:
					away = -1
				_walk(away)
				if b.st == EKensei.S.LEAP_FALL and blink_ready and absf(ldx) < EKensei.LEAP_REACH:
					_blink(away)
				return true
		EKensei.S.WAVE_WIND:
			# 낮게 웅크림 = 비검: 바로 앞이면 파도가 나오는 순간에 맞춰 뛴다
			var left := b._wind(EKensei.WAVE_WIND) - b.st_t
			if dist < 80.0:
				_walk(0)
				if not _dodged and left <= 0.1 and e.is_on_floor() and _seen_t >= react:
					_dodged = true
					if randf() < miss_rate:
						missed += 1
					else:
						_combo([[0.0, "es_jump", true], [0.3, "es_jump", false]])
				return true
		EKensei.S.CTR_STANCE, EKensei.S.PHASE, EKensei.S.RAIN_WIND:
			if b.st == EKensei.S.CTR_STANCE and use_kit and not _ctr_thrown and _slot_is_throw(e, SLOT_THROW):
				return false # 던질 자리로 (_kit이 맡음)
			_walk(0)
			if dist < 90.0:
				_walk(-to)
			return true
	# 위험물: 비검 파도는 점프, 천검 칼빛은 빈틈으로
	var ex := e.global_position.x
	for n: Node in get_tree().get_nodes_in_group(EKenseiFx.GROUP):
		if n is EKenseiFx.Wave:
			var w := n as EKenseiFx.Wave
			var rel := ex - w.position.x
			var close := 30.0 + (w.speed + maxf(-e.velocity.x * float(w.dir), 0.0)) * 0.09 # 다가오는 빠르기만큼 일찍
			if signf(rel) == float(w.dir) and absf(rel) < close and e.is_on_floor() and _seq.is_empty() and not w.has_meta("bot_seen"):
				w.set_meta("bot_seen", true)
				if w.has_meta("bot_deflect") and _deflect_ok:
					continue # 단공으로 지우는 중
				if randf() < miss_rate:
					missed += 1
					return false
				_combo([[0.0, "es_jump", true], [0.3, "es_jump", false]])
				return true
		elif n is EKenseiFx.ShadowCut:
			# 그림자 일섬선: 그 위에 서 있으면 터지기 직전에 뛰어 넘음
			var c := n as EKenseiFx.ShadowCut
			if c.has_meta("bot_deflect") and _deflect_ok:
				continue
			var left := c.delay - c.t
			if ex > c.band.position.x - 6.0 and ex < c.band.end.x + 6.0 and left < 0.16 and left > 0.0 and e.is_on_floor() and _seq.is_empty() and not c.has_meta("bot_seen"):
				c.set_meta("bot_seen", true)
				if randf() < miss_rate:
					missed += 1
					return false
				dodges += 1
				_combo([[0.0, "es_jump", true], [0.3, "es_jump", false]])
				return true
		elif n is EKenseiFx.RainBlade:
			var r := n as EKenseiFx.RainBlade
			if r.has_meta("bot_deflect") and _deflect_ok:
				continue
			if r.t < r.warn and absf(r.position.x - ex) < EKenseiFx.RainBlade.HALF_W + 9.0:
				_walk(1 if ex >= r.position.x else -1)
				if r.warn - r.t < 0.12 and blink_ready:
					_blink(1 if ex >= r.position.x else -1)
				return true
	return false


## 맞았을 때 무엇에 맞았는지 (공정함 점검용)
func _on_hurt(hp: int) -> void:
	if hp >= _last_hp:
		_last_hp = hp
		return # 부활·포식으로 오른 것
	_last_hp = hp
	n_hurt += 1
	for n: Node in get_tree().get_nodes_in_group(EKenseiFx.GROUP):
		if n is EKenseiFx.ShadowCut and bool(n.get("_burst")) and float(n.get("t")) - float(n.get("delay")) < 0.12:
			n_shadow_hurt += 1
			break
	var b: Variant = stage.get("boss")
	var what: String = EKensei.S.keys()[(b as EKensei).st] if is_instance_valid(b) else "?"
	print("BOT HURT hp=%d boss_st=%s fight=%.1fs" % [hp, what, float(_fight_frames) / 60.0])


## 비검 파도가 가까이 오고 있나 (천열처럼 몸이 묶이는 기술을 쓰기 전에 본다)
func _wave_near(e: EEska) -> bool:
	for n: Node in get_tree().get_nodes_in_group(EKenseiFx.GROUP):
		if n is EKenseiFx.Wave:
			var w := n as EKenseiFx.Wave
			var rel := e.global_position.x - w.position.x
			if signf(rel) == float(w.dir) and absf(rel) < 160.0:
				return true
	return false


func _blink(dir: int) -> void:
	_dodged = true
	if randf() < miss_rate:
		missed += 1 # 놓침: 아무것도 안 함
		return
	dodges += 1
	var key := "es_right" if dir > 0 else "es_left"
	_hold("es_left", false)
	_hold("es_right", false)
	_combo([[0.0, key, true], [0.0, "es_blink", true], [0.05, "es_blink", false], [0.1, key, false]])


func _walk(dir: int) -> void:
	if not _seq.is_empty():
		return
	_hold("es_right", dir > 0)
	_hold("es_left", dir < 0)


func _hold(a: String, on: bool) -> void:
	if on and not Input.is_action_pressed(a):
		Input.action_press(a)
	elif not on and Input.is_action_pressed(a):
		Input.action_release(a)


func _tap(a: String) -> void:
	_combo([[0.0, a]])


## [시각, 동작] 은 눌렀다 0.05초 뒤 뗌, [시각, 동작, true/false] 는 누르기/떼기만
func _combo(list: Array) -> void:
	for it: Array in list:
		if it.size() == 3:
			_seq.append([float(it[0]), String(it[1]), bool(it[2])])
		else:
			_seq.append([float(it[0]), String(it[1]), true])
			_seq.append([float(it[0]) + 0.05, String(it[1]), false])


func _run_seq(delta: float) -> void:
	for i in range(_seq.size() - 1, -1, -1):
		_seq[i][0] -= delta
	var keep: Array = []
	for it: Array in _seq:
		if float(it[0]) <= 0.0:
			_hold(String(it[1]), bool(it[2]))
		else:
			keep.append(it)
	_seq = keep


func _release_all() -> void:
	for a in ["es_left", "es_right", "es_up", "es_down", "es_jump", "es_attack", "es_skill", "es_blink", "es_bind", "es_potion", "es_ult_next"]:
		if Input.is_action_pressed(a):
			Input.action_release(a)
	_seq.clear()
