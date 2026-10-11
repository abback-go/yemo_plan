extends Node
## 검성 보스전 자동 플레이 봇 (시험용 — 전투 시간·맞은 횟수로 난이도를 잰다).
## 시나리오에서 [2, "attach", "../tools/test/eska_boss_bot.gd"] 로 붙인다 (eska_boss_bot.json).
## 쓰는 것: 이동 · 기본 베기 · 천열 · 순간이동(예고 끝에 맞춰 피함) · 점프(비검 파도·낙화 충격파만). 물약·대마법·봉공·단공은 안 씀.
## 사람처럼 반응이 늦도록 예고를 본 뒤 REACT초가 지나야 움직인다. 2초마다 상태, 끝나면 "BOT RESULT" 한 줄.
## 솜씨 조절(환경 변수): ESKA_BOT_MISS = 피하기를 놓칠 확률(기본 0) · ESKA_BOT_SKIP = 반격 틈을 그냥 보낼 확률(기본 0)
##   예) 잘하는 사람 흉내: ESKA_BOT_MISS=0.2 ESKA_BOT_SKIP=0.3

const REACT := 0.12 ## 예고를 알아차리는 데 걸리는 시간
const BLINK_LEAD := 0.07 ## 공격이 나가기 이만큼 전에 순간이동 (무적 0.15초)
const NEAR := 64.0 ## 때릴 때 붙는 거리
const SAFE := 120.0 ## 기다릴 때 거리

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
var _skip := false ## 이번 틈은 그냥 보냄
var _done_t := 0.0
var _fight_frames := 0 ## 싸움 중 프레임 수 (게임 시간 = /60 — 멈춤·느려짐 연출 포함, 실제 체감 시간)
const QUIT_AFTER := 7.0 ## 이기고 이만큼 뒤 끝냄 (끝 화면까지 보이게)
const GIVE_UP := 600.0 ## 이만큼(초) 지나도 못 이기면 끝냄


func _ready() -> void:
	stage = get_tree().current_scene
	miss_rate = float(OS.get_environment("ESKA_BOT_MISS")) if OS.has_environment("ESKA_BOT_MISS") else 0.0
	skip_rate = float(OS.get_environment("ESKA_BOT_SKIP")) if OS.has_environment("ESKA_BOT_SKIP") else 0.0
	if OS.has_environment("ESKA_BOT_SEED"):
		seed(int(OS.get_environment("ESKA_BOT_SEED"))) # 판마다 다른 흐름 (검성의 기술 고르기도 바뀜)
	print("BOT skill miss=%.2f skip=%.2f" % [miss_rate, skip_rate])


## 그려지는 프레임마다 (멈춤 연출 중에도 하나씩 — 사람이 느끼는 시간)
func _process(_delta: float) -> void:
	if stage != null and int(stage.get("fight")) == EBossStage.F.FIGHT:
		_fight_frames += 1


func _physics_process(delta: float) -> void:
	_t += delta
	_run_seq(delta)
	var e: EEska = stage.get("eska")
	var bo: Variant = stage.get("boss")
	var b: EKensei = bo if is_instance_valid(bo) else null
	if e == null:
		return
	if not e.hurt_taken.is_connected(_on_hurt):
		e.hurt_taken.connect(_on_hurt)

	_log_t -= delta
	if _log_t <= 0.0:
		_log_t = 2.0
		print("BOT t=%.1f fight=%.1fs %s boss=%s" % [_t, float(_fight_frames) / 60.0, stage.fight_state(), stage.boss_info()])
	var fight: int = stage.get("fight")
	if fight == EBossStage.F.WON:
		if not _done:
			_done = true
			_done_t = _t
			print("BOT RESULT won fight_time=%.1fs (game frames/60) deaths=%d hits_taken=%d dodges=%d missed=%d" % [float(_fight_frames) / 60.0, int(stage.get("deaths")), int(stage.get("hits_taken")), dodges, missed])
		_release_all()
		if _t - _done_t > QUIT_AFTER:
			get_tree().quit()
		return
	if _t > GIVE_UP:
		print("BOT RESULT gave_up fight_time=%.1fs %s boss=%s" % [float(_fight_frames) / 60.0, stage.fight_state(), stage.boss_info()])
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
	else:
		_seen_t += delta
	_fight(e, b)


func _fight(e: EEska, b: EKensei) -> void:
	var dx := b.global_position.x - e.global_position.x
	var dist := absf(dx)
	var to := 1 if dx > 0.0 else -1
	if _dodge(e, b, dist, to):
		return
	var punish := b.st in [EKensei.S.IAI_REST, EKensei.S.TRI_REST, EKensei.S.WAVE_REST, EKensei.S.CTR_RELAX, EKensei.S.LEAP_REST, EKensei.S.RAIN_HOLD, EKensei.S.RAIN_REST, EKensei.S.IDLE, EKensei.S.WALK, EKensei.S.IAI_SHEATHE, EKensei.S.IAI_FOLLOW] or b.break_t > 0.0
	if b.st == EKensei.S.CTR_STANCE or b.st == EKensei.S.PHASE or (_skip and b.break_t <= 0.0):
		punish = false
	var want := NEAR if punish else SAFE
	if dist > want + 14.0:
		_walk(to)
	elif dist < want - 14.0 and not punish:
		_walk(-to)
	else:
		_walk(0)
	if not _seq.is_empty():
		return
	if punish and dist < 150.0:
		if e.facing != to:
			_tap("es_right" if to > 0 else "es_left")
			return
		if e.cd_left("cheonyeol") <= 0.0 and dist < 160.0 and e.is_on_floor():
			_tap("es_skill")
		elif float(e.get("_atk_cd")) <= 0.0:
			_tap("es_attack")


## 위험하면 피한다 (피하는 중이면 true)
func _dodge(e: EEska, b: EKensei, dist: float, to: int) -> bool:
	var p := b.p()
	var blink_ready := float(e.get("_blink_cd")) <= 0.0 and (e.is_on_floor() or bool(e.get("_air_blink")))
	match b.st:
		EKensei.S.IAI_WIND:
			var left := b._wind(EKensei.IAI_WIND) - b.st_t
			_walk(0)
			if not _dodged and _seen_t >= REACT and left <= BLINK_LEAD and blink_ready:
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
				if soon and dist < 100.0 and blink_ready and _seen_t >= REACT * 0.5:
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
		EKensei.S.CTR_STANCE, EKensei.S.PHASE, EKensei.S.RAIN_WIND:
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
				if randf() < miss_rate:
					missed += 1
					return false
				_combo([[0.0, "es_jump", true], [0.3, "es_jump", false]])
				return true
		elif n is EKenseiFx.RainBlade:
			var r := n as EKenseiFx.RainBlade
			if r.t < r.warn and absf(r.position.x - ex) < EKenseiFx.RainBlade.HALF_W + 9.0:
				_walk(1 if ex >= r.position.x else -1)
				if r.warn - r.t < 0.12 and blink_ready:
					_blink(1 if ex >= r.position.x else -1)
				return true
	# 낙화 착지 뒤 남은 충격 — 없음 (즉시)
	return false


## 맞았을 때 무엇에 맞았는지 (공정함 점검용)
func _on_hurt(hp: int) -> void:
	var b: Variant = stage.get("boss")
	var what: String = EKensei.S.keys()[(b as EKensei).st] if is_instance_valid(b) else "?"
	print("BOT HURT hp=%d boss_st=%s fight=%.1fs" % [hp, what, float(_fight_frames) / 60.0])


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
	for a in ["es_left", "es_right", "es_up", "es_jump", "es_attack", "es_skill", "es_blink", "es_bind"]:
		if Input.is_action_pressed(a):
			Input.action_release(a)
	_seq.clear()
