extends EStage
## 에스카 튜토리얼 "종언의 문턱" (기획: docs/eska/tutorial.md).
## 가로 4060px 한 줄 길: 깨어남 → 공허 틈(점프·이단점프·순간이동 한 번에) → 허수아비(베기 1번·천열)
## → 등불 망령(단공 "가르는 틈" 딱 맞춤 — 느린 구슬 0.5배, 다리로 0.75배 한 번 더) → 높이 뜬 망령(낙성) → 가마솥 쉼터(속박 달이기)
## → 사냥개(피하기·속박 던지기) → 검은 거상(천열로 찢고 갓 찢긴 틈에 물약 = 틈 달이기: 처음은 0.5배 느림, 두 번째는 실전 박자
##   → 성공마다 종언 게이지 +30% · 거상이 느긋해진 동안 게이지를 채움 → 대마법 고르기·발동) → 끝 화면.
## 진행은 단계(STEPS) 하나씩: _enter_이름()(있으면)으로 시작하고 _tick_이름()이 true를 돌려주면 다음 단계로.
## 안내 글의 키 이름은 입력 방식에 맞춰 바뀐다 (EKeys.label — 키보드 "A" / 터치 "스킬", 글 속 자리표는 ETutHud.fmt).
## 연출 중(_cutscene)에는 화면 표시(HUD)와 지난 안내를 숨긴다 — 영화 띠가 HUD 글자를 자르지 않게.
## 들어오는 길: 타이틀 메뉴 "에스카 튜토리얼" 또는 웹 주소 뒤 ?eska_tut

const W := 4060.0
const FLOOR := 300.0
const START_X := 200.0 ## 첫 확인점 (터치 방향키 밖)
const PIT_X := 600.0
const PIT_W := 250.0 ## 점프+이단점프(약 220)로는 모자라고 + 순간이동(150)이면 넘음
const HINT_AFTER := 3.0 ## 같은 자리에서 이만큼 머물면 안내 칸을 다시 흔든다

## 구간 경계 (봉인 문 자리)
const GATE_DUMMIES := 1660.0
const GATE_CASTER := 2280.0
const GATE_REST := 2740.0
const GATE_RUNNER := 3360.0
const COMBO_X := 1110.0 ## 베기 허수아비
const CHEON_XS: Array[float] = [1390.0, 1450.0, 1520.0] ## 천열 허수아비 셋
const CASTER_X := 2050.0
const REST_POT_X := 2540.0 ## 쉼터 가마솥
const BOSS_POT_X := 3460.0 ## 거상 앞 가마솥 (사냥개에게 쓴 병이 다시 차는 걸 보여 줌)
const BOSS_X := 3820.0
const BOSS_TRIGGER_X := 3530.0
const INTRO_FOCUS_K := 0.6 ## 등장 연출 카메라: 에스카(0) ~ 거상(1) 사이 이 자리
const LANTERN_XS: Array[float] = [START_X, 930.0, 1720.0, 2340.0, 2800.0, 3400.0]

## 단공 "가르는 틈" 배우기
const ORB_SLOW := 0.5 ## 첫 구슬 빠르기 배수 (150 → 75: 딱 맞춤 창 약 0.8초)
const ORB_BRIDGE := 0.75 ## 다리: 두 번째 딱 맞춤 구슬 (창 약 0.55초 → 보스 0.23초로 가는 계단)
const BRIDGE_GIVEUP := 25.0 ## 두 번째 딱 맞춤을 이만큼(실제 초) 못 하면 넘어간다
const SLOW_META := &"tut_slow" ## 이미 늦춘 구슬 표시
const CASTER_HP := 0.7 ## 망령 체력 배수 (딱 맞춤을 익힌 뒤 금방 쓰러지게)
const EARLY_SAY_GAP := 4.0 ## "너무 일렀다" 같은 말 사이 최소 간격 (실제 초)

## 낙성 배우기: 높이 뜬 망령 (HighWraith)
const HIGH_HP := 1.0
const NAK_RETRY := 1.2 ## 낙성이 빗나갔으면 이만큼 뒤 다시 쓸 수 있게
const MEMO := "「실에 실을 꼬면 무엇이든 붙든다.」 — 수첩의 메모" ## EPotions.HINTS["bind"]를 마녀가 읊음

## 거상
const BOSS_HP_MULT := 2.0 ## 2400 × 2 = 4800: 틈 달이기 둘(+60%)과 천열 둘로 게이지 대부분이 차고 나머지는 몇 초 싸움 → 남은 약 절반은 대마법 몫 (운석 3600이면 끝)
const BOSS_FLOOR := 0.1 ## 대마법을 쓰기 전에는 거상 체력이 이 몫 밑으로 내려가지 않음 ("끝은 대마법으로")
const BOSS_CALM := 2.6 ## 틈 달이기에 성공한 뒤 거상이 숨 고를 때마다 이만큼 더 쉼 (공격 빈도 약 절반)
const CHEON_REACH := 360.0 ## 천열을 쓴 순간 거상이 앞으로 이 안이면 틈 달이기 순간 (천열 참격 중심 150 + 반지름 약 190)
const RIFT_SLOW := 0.5 ## 첫 틈 달이기: 시간 배수
const RIFT_SLOW_REAL := 1.8 ## 느려지는 실제 시간 (게임 0.9초 — 첫 틈부터 0.5초인 "갓 찢긴" 창을 넉넉히 덮음)
const RIFT_WAIT := 2.8 ## 첫 시도: 이만큼(실제 초) 안에 병이 스미지 않으면 다시
const RIFT_GAUGE := 0.3 ## 틈 달이기 성공마다 종언 게이지 + 가득의 이 몫
const RIFT_TRIES := 3 ## 두 번째(느림 없는) 시도를 이만큼 놓치면 넘어간다
const POTION_SLOT := 2 ## ↓+물약 칸
const BIND_KEY := "web+web" ## 수첩의 속박 조합 (튜토리얼에서 처음 달여 "새 물약!"을 보게 잠시 지운다)

const STEPS := ["wake", "move", "gap", "combo", "cheonyeol", "dangong", "nakseong", "cauldron", "hound", "finale", "end"]

var tut: ETutHud
var brew_tip: ETutHud.BrewTip
var gates := {} ## 이름 → ETutProps.Gate
var lanterns: Array[ETutProps.Lantern] = []
var dummies: Array[PDummy] = []
var ring: ETutProps.PerfectRing
var pot_rest: ECauldron
var pot_boss: ECauldron
var foe: EEnemy ## 지금 구간의 적
var boss: EColossus

var _step := -1
var _st := 0.0 ## 단계 안 시간 (실제 초)
var _sub := 0 ## 단계 안 작은 순서
var _idle := 0.0 ## 안내 다시 흔들기용 머문 시간
var _last_x := 0.0
var _clock := 0.0
var _deaths := 0
var _falls := 0
var _hits_taken := 0
var _best_combo := 0
var _hp_seen := EEska.MAX_HP
var _real_ms := 0
var _perfects := 0 ## 단공 딱 맞춤 횟수 (끝 화면)
var _orb_slow := ORB_SLOW ## 지금 새로 나오는 구슬에 거는 빠르기 배수
var _sweeps := {} ## 본 단공(Upsweep) 인스턴스 번호 → 알린 것 (1 = 딱 맞춤, 2 = 이름)
var _say_cd := 0.0 ## 잔소리 간격
var _rift0 := 0 ## 시작할 때 EPotions.rift_brews (끝 화면: 이번에 한 틈 달이기)
var _splash_seen: Dictionary = {} ## 지켜보기 시작할 때의 EPotions.last_splash (새로 깨진 병인지 보기)
var _stitch_seen := 0
var _was_cheon := false
var _misses := 0 ## 두 번째 틈 달이기에서 놓친 수
var _boss_st_prev := -1
var _calm := false ## 거상이 느긋해짐 (틈 달이기 성공 뒤)
var _ult_seen := 0
var _ult_used := false
var _floor_said := false
var _bind_taught := false
var _book_hid := false
var _refill_said := false
var _open_seen := 0 ## 이미 본 달이기 화면 열린 횟수


# ═══════════════════════════════════════════════════════════
# 만들기
# ═══════════════════════════════════════════════════════════

func _build() -> void:
	stage_w = W
	floor_y = FLOOR
	cam_top = FLOOR - 520.0
	respawn_at = Vector2(START_X, FLOOR)
	music = "temple_dark"
	EScenery.build(self, W, FLOOR)
	# 바닥 (공허 틈에서 끊김) + 양 끝 벽
	solid(Rect2(-40, FLOOR, PIT_X + 40, 160))
	solid(Rect2(PIT_X + PIT_W, FLOOR, W - PIT_X - PIT_W + 40, 160))
	solid(Rect2(-40, FLOOR - 500, 56, 620))
	solid(Rect2(W - 16, FLOOR - 500, 56, 620))
	var pit := ETutProps.Pit.new()
	pit.w = PIT_W
	pit.position = Vector2(PIT_X, FLOOR)
	add_child(pit)
	# 가마솥 둘: 쉼터(속박 달이기) · 거상 앞(들르면 다시 가득)
	pot_rest = ECauldron.place(self, Vector2(REST_POT_X, FLOOR))
	pot_boss = ECauldron.place(self, Vector2(BOSS_POT_X, FLOOR))
	# 봉인 문: 허수아비 끝 · 망령 끝 · 쉼터 끝 · 사냥개 끝 (구간에 들어서면 뒤도 닫힘)
	for spec: Array in [["dummies", GATE_DUMMIES], ["caster", GATE_CASTER], ["rest", GATE_REST], ["runner", GATE_RUNNER]]:
		var g := ETutProps.Gate.new()
		g.position = Vector2(float(spec[1]), FLOOR)
		add_child(g)
		gates[spec[0]] = g
	# 확인점 등불
	for x: float in LANTERN_XS:
		var l := ETutProps.Lantern.new()
		l.position = Vector2(x, FLOOR)
		add_child(l)
		lanterns.append(l)
	# 허수아비: 베기용 하나 + 천열용 셋
	for x: float in [COMBO_X] + CHEON_XS:
		var d := PDummy.new()
		d.setup("small")
		d.position = Vector2(x, FLOOR)
		add_child(d)
		dummies.append(d)


func _start() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 41
	add_child(layer)
	tut = ETutHud.new()
	tut.touch = touch
	layer.add_child(tut)
	var tip_layer := CanvasLayer.new() # 달이기 화면(45) 위 — 멈춤 중에도 돈다
	tip_layer.layer = 46
	tip_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(tip_layer)
	brew_tip = ETutHud.BrewTip.new()
	brew_tip.cauldron = pot_rest
	tip_layer.add_child(brew_tip)
	hud.show_keys = false
	eska.hurt_taken.connect(_on_hurt)
	# ↓칸은 비워 두고 쉼터에서 속박을 달여 채운다. 종언 게이지는 거상 앞에서 처음 깨어난다 (그 전 피해는 게이지에 안 쌓임)
	eska.belt.slots[POTION_SLOT] = {}
	eska.mods["gauge"] = 0.0
	_book_hid = EPotions.notebook.has(BIND_KEY)
	EPotions.notebook.erase(BIND_KEY)
	_rift0 = EPotions.rift_brews
	lanterns[0].light()
	_next()


## 나갈 때: 잠시 지운 수첩의 속박 조합을 되돌려 둔다 (훈련장은 처음부터 안다)
func _exit_tree() -> void:
	if _book_hid and not EPotions.notebook.has(BIND_KEY):
		EPotions.notebook[BIND_KEY] = "bind"
	super._exit_tree()


# ═══════════════════════════════════════════════════════════
# 진행
# ═══════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	super._process(delta)
	# 단계 시계는 실제 시간 (느려짐·멈춤 연출 중에도 대사·순서가 제 속도로)
	var now := Fx.now_ms()
	var real := minf(float(now - _real_ms) * 0.001, 0.1) if _real_ms > 0 else delta
	_real_ms = now
	if _step < 0 or _step >= STEPS.size():
		return
	_st += real
	_say_cd = maxf(_say_cd - real, 0.0)
	if STEPS[_step] != "end":
		_clock += real
	_best_combo = maxi(_best_combo, eska.hit_count)
	_track_idle(delta)
	_check_lanterns()
	_check_fall()
	_scan_fx()
	if call("_tick_" + STEPS[_step]):
		_next()


func _next() -> void:
	_step += 1
	_st = 0.0
	_sub = 0
	_idle = 0.0
	if _step < STEPS.size() and has_method("_enter_" + STEPS[_step]):
		call("_enter_" + STEPS[_step])


## 거의 같은 자리에 머문 시간 (헤매는지 보기)
func _track_idle(delta: float) -> void:
	if absf(eska.global_position.x - _last_x) > 24.0:
		_last_x = eska.global_position.x
		_idle = 0.0
	else:
		_idle += delta
	if _idle > HINT_AFTER:
		_idle = 0.0
		tut.nudge()


func _check_lanterns() -> void:
	for i in lanterns.size():
		var l := lanterns[i]
		if not l.lit and eska.global_position.x > l.global_position.x - 8.0 and eska.is_on_floor():
			l.light()
			respawn_at = Vector2(l.global_position.x, FLOOR)


## 공허 틈에 떨어지면: 피해 없이 바로 앞 확인점으로 되돌림 (두 번째부터는 요령 한 줄)
func _check_fall() -> void:
	if eska.global_position.y > FLOOR + 110.0 and not eska.is_dead():
		_deaths += 1
		_falls += 1
		Fx.flash(Color(0.6, 0.2, 1.0, 0.3), 0.2)
		eska.respawn(respawn_at)
		tut.say("공허는 마녀를 삼키지 못한다." if _falls == 1 else "높이 뛰어 한 번 더 딛고, 떨어지기 전에 순간이동.")


## 이펙트 층 훑기: 새 망령 구슬은 느리게(_orb_slow) · 단공(Upsweep)이 딱 맞춤을 냈는지 · 너무 일찍 지웠는지
func _scan_fx() -> void:
	var fxp := Fx.effect_parent()
	if fxp == null:
		return
	for n: Node in fxp.get_children():
		if n is ECaster.Orb:
			if not n.has_meta(SLOW_META):
				n.set_meta(SLOW_META, true)
				(n as ECaster.Orb).vel *= _orb_slow
		elif n is ESkillFx.Upsweep:
			var up := n as ESkillFx.Upsweep
			var id := up.get_instance_id()
			var told := int(_sweeps.get(id, 0))
			if up.perfects > 0 and told != 1:
				_sweeps[id] = 1
				_perfects += 1
				_on_perfect()
			elif told == 0 and up.deflected > 0 and up.perfects == 0 and up.t > ESkillFx.Upsweep.ACTIVE:
				_sweeps[id] = 2
				_on_early()
	if _sweeps.size() > 16: # 사라진 것 정리
		for id: int in _sweeps.keys():
			if not is_instance_id_valid(id):
				_sweeps.erase(id)


func _on_hurt(hp: int) -> void:
	if hp < _hp_seen:
		_hits_taken += 1
		if STEPS[_step] == "dangong" and _learning_deflect() and _say_cd <= 0.0:
			_say_cd = EARLY_SAY_GAP
			tut.say("조금만 더 빨리 — 구슬이 고리에 들어오는 순간.")
	_hp_seen = hp


func _on_eska_died() -> void:
	_deaths += 1
	super._on_eska_died()


func _on_floor_at(x0: float, x1: float, top: float) -> bool:
	var p := eska.global_position
	return eska.is_on_floor() and p.x >= x0 and p.x <= x1 and p.y <= top + 2.0


# ═══════════════════════════════════════════════════════════
# 단계들 (_enter_* 시작 · _tick_* 끝났으면 true)
# ═══════════════════════════════════════════════════════════

func _enter_wake() -> void:
	_cutscene(true)
	eska.art.visible = false
	tut.fade_to(0.0, 1.6)


func _tick_wake() -> bool:
	if _sub == 0 and _st > 0.6:
		_sub = 1
		tut.chapter("종언의 문턱", "에스카 · 종언의 마녀")
	if _sub == 1 and _st > 1.4:
		_sub = 2
		eska.art.visible = true
		eska.respawn(eska.global_position) # 공간 틈에서 나타남
	if _sub == 2 and _st > 3.4:
		_sub = 3
		tut.say("……봉인이 풀렸다. 다시, 걸어 볼까.")
	if _st > 4.6:
		_cutscene(false)
		return true
	return false


func _enter_move() -> void:
	tut.prompt(["es_left", "es_right"], "미끄러지듯 이동")


func _tick_move() -> bool:
	if eska.global_position.x > START_X + 160.0:
		tut.done()
		return true
	return false


## 공허 틈 하나: 점프 → 공중에서 한 번 더 → 순간이동 (이단점프와 순간이동을 한 구간에서)
func _tick_gap() -> bool:
	if _sub == 0 and eska.global_position.x > PIT_X - 170.0 and not tut.has_prompt():
		_sub = 1
		tut.say("공허의 틈. 뛰어도 닿지 않는다 — 허공을 딛고, 사라져 건넌다.")
		tut.prompt(["es_jump", "→", "공중에서", "es_jump", "→", "es_blink"], "이어서 건너기")
	if _on_floor_at(PIT_X + PIT_W, W, FLOOR):
		tut.done()
		return true
	return false


func _tick_combo() -> bool:
	if _sub == 0 and eska.global_position.x > COMBO_X - 210.0:
		_sub = 1
		tut.say("허수아비. 손끝 하나면 충분하다.")
		tut.prompt(["es_attack"], "베기 — 달리면서도 벨 수 있다")
	if _sub == 1 and eska.hit_count >= 1:
		tut.done()
		return true
	return false


func _tick_cheonyeol() -> bool:
	if _sub == 0 and _st > 1.2:
		_sub = 1
		_ready_skill("cheonyeol")
		tut.prompt(["es_skill"], "천열 — 앞의 공간을 통째로 벤다")
	if _sub == 1 and eska.st == EEska.St.CAST and eska.cast_kind == "cheonyeol":
		_sub = 2
		_st = 0.0
	if _sub == 2 and _st > 0.9:
		var hit := 0
		for d in dummies:
			if d._since_hit < 1.2:
				hit += 1
		if hit >= 2:
			tut.done()
			gates["dummies"].open()
			tut.say("길이 열렸다.")
			return true
		_sub = 1 # 너무 멀었다 — 다시
		tut.say("조금 더 다가가서.")
		tut.nudge()
	return false


## 등불 망령: 구슬이 몸에 닿기 직전 ↑+스킬 = 단공 "가르는 틈"의 딱 맞춤 (구슬 0.5배, 몸 둘레에 딱 맞춤 고리)
## → 다리: 0.75배 구슬로 한 번 더 → 망령을 쓰러뜨림
## sub: 1 첫 딱 맞춤 기다림 · 2 칭찬 · 3 두 번째(0.75배) 기다림 · 4 칭찬 · 5 쓰러뜨리기
func _tick_dangong() -> bool:
	match _sub:
		0:
			if eska.global_position.x > GATE_DUMMIES + 80.0:
				_sub = 1
				_orb_slow = ORB_SLOW
				gates["dummies"].close()
				foe = _spawn_caster(CASTER_X)
				ring = ETutProps.PerfectRing.new()
				ring.eska = eska
				add_child(ring)
				tut.say("핏빛 구슬 — 닿기 직전에 머리 위 공간을 가른다.")
				_ready_skill("dangong")
				tut.prompt(["구슬이 몸에 닿기 직전", "es_up", "+", "es_skill"], "가르는 틈 — 딱 맞춤")
		2:
			if _st > 1.4 and not tut.has_prompt():
				_sub = 3
				_st = 0.0
				_orb_slow = ORB_BRIDGE
				tut.say("한 번 더. 이번엔 구슬이 조금 빠르다.")
				tut.prompt(["한 번 더", "es_up", "+", "es_skill"], "딱 맞춤 — 구슬이 빨라졌다")
		3:
			if _st > BRIDGE_GIVEUP: # 계단 하나 — 못 해도 막지 않는다
				_sub = 4
				_st = 0.0
				tut.done()
				ring.on = false
				tut.say("감은 잡았다. 실전에선 더 빠르다.")
		4:
			if _st > 1.4 and not tut.has_prompt():
				_sub = 5
				tut.prompt(["es_attack", "/", "es_up", "+", "es_skill"], "이제 망령을 쓰러뜨린다")
	if _sub >= 4 and _dead(foe):
		tut.done()
		_orb_slow = ORB_SLOW
		return true
	if _learning_deflect() and _dead(foe): # 딱 맞춤을 익히기 전에 쓰러뜨렸으면 하나 더
		foe = _spawn_caster(clampf(eska.global_position.x + 160.0, GATE_DUMMIES + 140.0, GATE_CASTER - 180.0))
		tut.say("하나 더. 이번엔 구슬을 갈라라.")
	return false


func _learning_deflect() -> bool:
	return STEPS[_step] == "dangong" and (_sub == 1 or _sub == 3)


func _spawn_caster(x: float) -> EEnemy:
	return EWaves.spawn(self, "caster", Vector2(x, FLOOR - 120.0), CASTER_HP, GATE_DUMMIES + 20.0, GATE_CASTER - 20.0)


## 딱 맞춤이 났다 (단공 쿨다운이 곧바로 다시 참)
func _on_perfect() -> void:
	if not _learning_deflect():
		return
	tut.done()
	if _sub == 1:
		_sub = 2
		tut.say("딱 맞췄다 — 단공이 곧바로 다시 차오른다.")
	else:
		_sub = 4
		ring.on = false
		tut.say("빨라져도 맞췄다.")
	_st = 0.0


## 구슬을 지우긴 했지만 너무 일렀다
func _on_early() -> void:
	if _learning_deflect() and _say_cd <= 0.0:
		_say_cd = EARLY_SAY_GAP
		tut.say("너무 일렀다. 구슬이 고리 안에 들어온 뒤에.")
		tut.nudge()


## 높이 뜬 망령: 베기·단공이 닿지 않는 높이 → ↓+스킬 낙성
func _tick_nakseong() -> bool:
	if _sub == 0:
		_sub = 1
		foe = _spawn_high()
		tut.say("저 높이엔 칼이 닿지 않는다. 하늘을 찢어 떨어뜨린다.")
		_ready_skill("nakseong")
		tut.prompt(["es_down", "+", "es_skill"], "낙성 — 높이 뜬 적 위로 별 조각이 쏟아진다")
	# 빗나갔으면 곧 다시 쓸 수 있게 (배우는 동안 쿨다운 4초를 기다리지 않음)
	if eska.st != EEska.St.CAST and eska.cd_left("nakseong") > 0.0 and eska.cd_left("nakseong") < float(EEska.CD["nakseong"]) - NAK_RETRY:
		_ready_skill("nakseong")
	if _dead(foe):
		tut.done()
		gates["caster"].open()
		gates["dummies"].open()
		tut.say("길이 열렸다. 저 앞에 따뜻한 김이 오른다.")
		return true
	return false


func _spawn_high() -> EEnemy:
	var e := HighWraith.new()
	e.max_hp = int(round(float(e.max_hp) * HIGH_HP))
	e.x_min = GATE_DUMMIES + 40.0
	e.x_max = GATE_CASTER - 20.0
	# 에스카가 바라보는 쪽 앞 (낙성이 노리는 앞 30~240 안), 머리 위 높이
	var side := float(eska.facing)
	var x := eska.global_position.x + side * HighWraith.SIDE
	if x < e.x_min + 20.0 or x > e.x_max - 20.0:
		x = eska.global_position.x - side * HighWraith.SIDE
	e.position = Vector2(clampf(x, e.x_min + 20.0, e.x_max - 20.0), FLOOR - 16.0 - HighWraith.HIGH_UP)
	add_child(e)
	return e


## 가마솥 쉼터: 수첩 메모를 보고 거미줄+거미줄 = 속박을 달여 ↓칸에 담는다 (달이기 화면 아래 띠가 할 일 한 줄)
func _tick_cauldron() -> bool:
	match _sub:
		0:
			if eska.global_position.x > REST_POT_X - 140.0:
				_sub = 1
				tut.say("가마솥 — 마녀의 쉼터. 들르기만 해도 물약이 다시 가득 찬다.")
		1:
			if pot_rest.near:
				_sub = 2
				tut.say(MEMO)
				tut.prompt(["가마솥 앞에서", "es_up"], "열기 — 거미줄 둘로 속박을 달인다")
		2:
			# 달이기 화면이 열려 있는 동안은 장면이 멈춰 있으므로, 띠(BrewTip)가 센 "열린 횟수"로 열렸다 닫힌 것을 안다
			if brew_tip.opened > _open_seen and pot_rest.ui == null:
				_open_seen = brew_tip.opened
				tut.done()
				if _slot_is(POTION_SLOT, "bind"):
					_sub = 4
					_st = 0.0
					gates["rest"].open()
					tut.say("속박. 던지면 무엇이든 붙든다 — {es_down}+{es_potion}.")
				else:
					_sub = 3
					_st = 0.0
		3:
			if _st > 1.1:
				_sub = 2
				tut.say(MEMO)
				tut.prompt(["가마솥 앞에서", "es_up"], "다시 열고 거미줄 둘을 ↓칸에")
		4:
			return _st > 0.4
	return false


func _slot_is(i: int, id: String) -> bool:
	return String(eska.belt.slot(i).get("id", "")) == id


## 사냥개: 첫 웅크림에 피하기 → ↓+물약 속박을 던져 묶기 (묶이면 통과) → 쓰러뜨림
func _tick_hound() -> bool:
	if _sub == 0 and eska.global_position.x > GATE_REST + 80.0:
		_sub = 1
		gates["rest"].close()
		gates["runner"].close()
		foe = EWaves.spawn(self, "runner", Vector2(GATE_RUNNER - 300.0, FLOOR), 1.0, GATE_REST + 20.0, GATE_RUNNER - 20.0)
	if _sub == 1 and is_instance_valid(foe) and (foe as ERunner).st == ERunner.S.WIND:
		# 첫 돌진 예고: 잠깐 느려지며 피하는 법을 알려 줌
		_sub = 2
		Fx.slowmo(0.25, 0.6)
		tut.say("붉게 웅크리면 돌진한다 — 뛰거나, 사라져라.")
		tut.prompt(["es_jump", "/", "es_blink"], "피하기")
		_st = 0.0
	if _sub == 2 and _st > 2.0:
		_sub = 3
		tut.done()
	if _sub == 3 and not tut.has_prompt():
		_sub = 4
		_splash_seen = EPotions.last_splash
		tut.prompt(["es_down", "+", "es_potion"], "속박을 던져 묶는다 — 앞으로 약 다섯 걸음")
	if _sub == 4:
		var sp: Dictionary = EPotions.last_splash
		if not is_same(sp, _splash_seen) and String(sp.get("id", "")) == "bind" and int(sp.get("hits", 0)) > 0 and _any_bound():
			_sub = 5
			_bind_taught = true
			tut.done()
			tut.say("묶였다. 지금 벤다.")
		elif int(eska.belt.slot(POTION_SLOT).get("left", 0)) <= 0:
			_refill_slot(POTION_SLOT)
			tut.say("병이 다시 찼다. 가까이 끌어들여 던져라.")
	if _sub >= 1 and _dead(foe):
		if not _bind_taught: # 묶기 전에 쓰러뜨렸으면 하나 더
			var far := GATE_REST + 70.0 if eska.global_position.x > (GATE_REST + GATE_RUNNER) * 0.5 else GATE_RUNNER - 70.0 # 멀리서 다가오게 (던질 거리)
			foe = EWaves.spawn(self, "runner", Vector2(far, FLOOR), 1.0, GATE_REST + 20.0, GATE_RUNNER - 20.0)
			tut.say("또 온다. 이번엔 묶어라.")
			if _sub < 4:
				tut.done() # 피하기 안내가 떠 있었으면 접고 곧바로 속박 안내로
				_sub = 3
			return false
		tut.done()
		gates["runner"].open()
		return true
	return false


func _any_bound() -> bool:
	for n: Node in get_children():
		if n is ERunner and not (n as EEnemy).is_dead() and (n as EEnemy).is_bound():
			return true
	return false


## 칸 i가 비었으면 다시 가득 (던지는 물약이 아니면 속박으로)
func _refill_slot(i: int) -> void:
	var s: Dictionary = eska.belt.slot(i)
	var id := String(s.get("id", ""))
	if id == "" or EPotions.kind(id) != "throw":
		eska.belt.set_slot(i, "bind")
	elif s.has("max"):
		s["left"] = s["max"]


## 거상. sub: 0 다가감 · 1~3 등장 연출 · 4 천열 기다림 · 5 첫 틈 달이기(0.5배) · 6 꿰맴 · 7 두 번째 안내
## · 8 두 번째 틈 달이기(느림 없음) · 9 숨 고르기 · 10 게이지 · 11~12 고르기 · 13~14 대마법 · 15 마무리
func _tick_finale() -> bool:
	match _sub:
		0:
			if pot_boss.refills > 0 and not _refill_said:
				_refill_said = true
				tut.say("가마솥에 들르니 병이 다시 가득 찼다.")
			if eska.global_position.x > BOSS_TRIGGER_X:
				_sub = 1
				_st = 0.0
				brew_tip.cauldron = pot_boss
				gates["runner"].close()
				_cutscene(true)
				Music.play("boss", 1.2)
				# 에스카와 거상이 한 화면에 들어오게 둘 사이(거상 쪽으로 치우침)를 화면 가운데로 — 터치 치우침(CamBias)은 연출 중 약해짐
				cam.set("focus_p", Vector2(lerpf(eska.global_position.x, BOSS_X, INTRO_FOCUS_K), FLOOR - 70.0))
				var tw := create_tween()
				tw.tween_property(cam, "focus_w", 1.0, 0.7).set_trans(Tween.TRANS_SINE)
		1:
			if _st > 0.8:
				_sub = 2
				boss = EWaves.spawn(self, "colossus", Vector2(BOSS_X, FLOOR), BOSS_HP_MULT, GATE_RUNNER + 30.0, W - 30.0) as EColossus
				EFoeFx.rift(Vector2(BOSS_X, FLOOR - 40.0), 60.0)
				Fx.shake(0.9, 0.5)
				Sfx.play_pitch(&"roar", 0.7, 0.0)
				tut.chapter("검은 거상", "문턱을 지키는 것") # 연출 중엔 HUD를 숨기므로 이름은 튜토리얼 연출로
				hud.boss = boss
				hud.boss_name = "검은 거상"
				tut.boss_bar = true
				eska.mods["gauge"] = 1.0 # 종언 게이지가 깨어남 — 이제부터 준 피해만큼 찬다
		2:
			if _st > 2.6:
				_sub = 3
				var tw := create_tween()
				tw.tween_property(cam, "focus_w", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
				_cutscene(false)
				_st = 0.0
		3:
			if _st > 1.2:
				_sub = 4
				tut.say("단단하다. 찢고, 갓 찢긴 틈에 물약을 스미게 한다.")
				_arm_rift(["es_skill"], "천열 — 거상 앞 공간을 찢는다")
		4:
			# 천열이 나가는 순간 거상이 앞에 있으면: 시간이 느려지고 "지금 ↓+물약"
			var cheon := eska.st == EEska.St.CAST and eska.cast_kind == "cheonyeol"
			if cheon and not _was_cheon:
				if _boss_in_reach():
					_sub = 5
					_st = 0.0
					_splash_seen = EPotions.last_splash
					Fx.slowmo(RIFT_SLOW, RIFT_SLOW_REAL)
					tut.focus_to(1.0)
					tut.done()
					tut.prompt(["지금", "es_down", "+", "es_potion"], "갓 찢긴 틈에 병을 스미게")
				else:
					tut.say("더 가까이서 찢어라.")
			_keep_cheon_ready()
			_was_cheon = cheon
		5:
			var r := _rift_result()
			if r > 0:
				_rift_success()
				_sub = 6
				_st = 0.0
				_stitch_seen = EPotions.stitches
				tut.say("틈이 물약을 삼켰다 — 진하게, 거상째 묶는다.")
			elif r < 0 or _st > RIFT_WAIT:
				tut.focus_to(0.0)
				tut.say("늦었다. 갓 찢긴 틈이어야 한다 — 찢고, 곧바로.")
				_arm_rift(["es_skill"], "천열 — 거상 앞 공간을 찢는다")
				_sub = 4
				_st = 0.0
		6:
			if EPotions.stitches > _stitch_seen or _st > 2.0:
				_sub = 7
				_st = 0.0
				tut.focus_to(0.0)
				if EPotions.stitches > _stitch_seen:
					tut.say("꿰매어 닫힐 때 한 번 더 조인다.")
		7:
			if _st > 1.8 and not tut.has_prompt():
				_sub = 8
				_st = 0.0
				_misses = 0
				tut.say("이번엔 시간이 느려지지 않는다. 실전 박자로 한 번 더.")
				_arm_rift(["es_skill", "→", "곧바로", "es_down", "+", "es_potion"], "느림 없이 틈 달이기")
		8:
			_keep_cheon_ready()
			var r := _rift_result()
			if r > 0:
				_rift_success()
				_sub = 9
				_st = 0.0
				tut.say("이것이 마녀의 박자다.")
			elif r < 0:
				_misses += 1
				if _misses >= RIFT_TRIES: # 막지 않는다 — 감각은 거상전 내내 익힌다
					tut.done()
					_sub = 9
					_st = 0.0
					tut.say("박자는 몸이 기억한다. 계속 간다.")
				else:
					tut.say("늦었다 — 천열이 나가자마자 던진다.")
					tut.nudge()
					_arm_rift(["es_skill", "→", "곧바로", "es_down", "+", "es_potion"], "느림 없이 틈 달이기")
		9:
			if _st > 1.6 and not tut.has_prompt():
				_sub = 10
				tut.prompt(["es_attack", "es_skill"], _gauge_text())
		10:
			tut.set_text(_gauge_text())
			if eska.gauge_ratio() >= 1.0:
				_sub = 11
				tut.done()
				tut.say("종언이 찼다.")
		11:
			if not tut.has_prompt():
				_sub = 12
				_ult_seen = eska.ult_index
				tut.prompt(["es_ult_next"], "대마법 고르기 — 흑성 · 유성우 · 운석 · 봉공")
		12:
			if eska.ult_index != _ult_seen:
				_sub = 13
				tut.done()
		13:
			if not tut.has_prompt():
				_sub = 14
				tut.prompt(["es_bind"], _ult_text())
		14:
			tut.set_text(_ult_text())
	# 게이지가 찬 뒤엔 고르기를 건너뛰고 바로 써도 된다
	if _sub >= 11 and _sub <= 14 and eska.st == EEska.St.ULT and not _ult_used:
		_ult_used = true
		_sub = 15
		tut.done()
	if _sub >= 2:
		_boss_rules()
	if _sub >= 2 and _dead(boss):
		return true
	return false


## 틈 달이기 안내 (다시 시도할 때도): 천열 바로 쓸 수 있게, ↓칸에 던질 병이 있게, 새 병을 지켜보기 시작
func _arm_rift(keys: Array, text: String) -> void:
	_ready_skill("cheonyeol")
	var s: Dictionary = eska.belt.slot(POTION_SLOT)
	if int(s.get("left", 0)) <= 0 or EPotions.kind(String(s.get("id", "bind"))) != "throw":
		_refill_slot(POTION_SLOT)
	_was_cheon = false
	_splash_seen = EPotions.last_splash
	tut.prompt(keys, text)


## 천열을 쓰고 1.5초가 지났는데 틈 달이기를 못 했으면 천열을 다시 쓸 수 있게 (배우는 동안 쿨다운 5초를 기다리지 않음)
func _keep_cheon_ready() -> void:
	if eska.st != EEska.St.CAST and eska.cd_left("cheonyeol") > 0.0 and eska.cd_left("cheonyeol") < float(EEska.CD["cheonyeol"]) - 1.5:
		_ready_skill("cheonyeol")
		if int(eska.belt.slot(POTION_SLOT).get("left", 0)) <= 0:
			_refill_slot(POTION_SLOT)


## 지켜보기 시작한 뒤 새로 깨진 병: 1 = 갓 찢긴 틈에 스밈 · -1 = 늦은 틈이거나 그냥 깨짐 · 0 = 아직
func _rift_result() -> int:
	var sp: Dictionary = EPotions.last_splash
	if is_same(sp, _splash_seen) or sp.is_empty():
		return 0
	_splash_seen = sp
	if sp.has("rift") and bool(sp.get("fresh", true)):
		return 1
	return -1


## 틈 달이기 성공: 안내 체크 + 종언 게이지 보상 + 거상이 느긋해짐
func _rift_success() -> void:
	tut.done()
	eska.add_gauge(RIFT_GAUGE * EEska.GAUGE_MAX)
	_calm = true


func _boss_in_reach() -> bool:
	if not is_instance_valid(boss) or boss.is_dead():
		return false
	var dx := (boss.global_position.x - eska.global_position.x) * float(eska.facing)
	return dx > -30.0 and dx < CHEON_REACH


func _gauge_text() -> String:
	return "베고 찢을수록 종언 게이지가 찬다 — %d%%" % int(eska.gauge_ratio() * 100.0)


func _ult_text() -> String:
	return "대마법 「%s」 — 종언을 내린다" % String(EEska.ULT_NAMES.get(eska.selected_ult(), ""))


## 거상 싸움 규칙: 틈 달이기에 성공한 뒤엔 숨 고르기가 길어짐(공격 빈도 약 절반) · 대마법을 쓰기 전에는 BOSS_FLOOR 밑으로 안 내려감
func _boss_rules() -> void:
	if not is_instance_valid(boss) or boss.is_dead():
		return
	var st := int(boss.st)
	if _calm and _boss_st_prev == EColossus.S.REST and st == EColossus.S.WALK:
		boss._cool += BOSS_CALM
	_boss_st_prev = st
	var floor_hp := int(float(boss.max_hp) * BOSS_FLOOR)
	if not _ult_used and boss.hp < floor_hp:
		boss.hp = floor_hp
		if not _floor_said:
			_floor_said = true
			tut.say("거상이 버틴다 — 끝은 대마법으로.")


func _enter_end() -> void:
	_cutscene(true) # 마무리 연출: HUD·지난 안내 숨김
	tut.focus_to(0.0)
	Fx.slowmo(0.2, 1.4)
	Fx.flash(Color(1.0, 0.85, 1.0, 0.6), 0.5)
	for n: Node in get_children():
		if n is EEnemy and not (n as EEnemy).is_dead():
			(n as EEnemy).banish()
	eska.invuln = 999.0


func _tick_end() -> bool:
	if _sub == 0 and _st > 1.6:
		_sub = 1
		Music.play("")
		Music.jingle("jingle_chapter")
		tut.bars_to(1.0)
		touch.release_all()
		touch.process_mode = Node.PROCESS_MODE_DISABLED
		touch.visible = false
		var end := ETutEnd.new()
		var secs := int(_clock)
		end.learned = ["가르는 틈", "낙성", "물약 달이기", "틈 달이기", "대마법"]
		end.stats = [["걸린 시간", "%d분 %02d초" % [secs / 60, secs % 60]], ["쓰러짐", "%d번" % _deaths],
			["맞음", "%d번" % _hits_taken], ["딱 맞춤", "%d번" % _perfects],
			["틈 달이기", "%d번" % (EPotions.rift_brews - _rift0)], ["최고 연타", "%d HIT" % _best_combo]]
		end.chosen.connect(_on_end_chosen)
		tut.get_parent().add_child(end)
	return false


func _on_end_chosen(what: String) -> void:
	tut.fade_to(1.0, 0.4)
	await get_tree().create_timer(0.45, true, false, true).timeout
	Fx.reset()
	match what:
		"retry":
			get_tree().reload_current_scene()
		"arena":
			get_tree().change_scene_to_file("res://proto/eska/eska_arena.tscn")
		_:
			GameState.go_title()


## 배우라고 안내하는 순간에는 그 기술을 바로 쓸 수 있게 (먼저 써 버려 쿨다운 중이면 헷갈림). 대마법은 실제 게이지로만
func _ready_skill(id: String) -> void:
	eska.cooldowns[id] = 0.0


## 연출 중: 조작 막기 + 영화 띠 + 화면 표시(HUD)·터치 버튼·지난 안내 숨김
func _cutscene(on: bool) -> void:
	eska.controls_locked = on
	hud.cinematic = on
	hud.visible = not on
	tut.bars_to(1.0 if on else 0.0)
	touch.visible = not on
	if on:
		tut.clear()
		touch.release_all()


func _dead(e: EEnemy) -> bool:
	return not is_instance_valid(e) or e.is_dead()


## 시험 실행기 eval용: 지금 단계
func step_name() -> String:
	return "%s sub=%d x=%d hp=%d" % [STEPS[_step] if _step < STEPS.size() else "?", _sub, int(eska.global_position.x), eska.hp]


## 시험 실행기 eval용: 에스카 몸 가운데에서 off만큼 떨어진 곳에 에스카를 향해 날아오는 망령 구슬 하나 (튜토리얼 빠르기로 느려짐)
func test_orb(off: Vector2) -> void:
	var o := ECaster.Orb.new()
	o.position = eska.center() + off
	o.vel = -off.normalized() * ECaster.ORB_SPEED
	Fx.effect_parent().add_child(o)


## 시험 실행기 eval용: 터치 화면으로 보기 (조작 버튼·안내 이름)
func test_touch(on: bool) -> void:
	touch.active = on
	EKeys.touch_mode = on


## 높이 뜬 망령 (낙성 배우기): 보통 망령처럼 옆으로 거리를 두되 에스카 머리 위 HIGH_UP 높이에 떠 있다 — 베기·단공이 닿지 않는다.
## 생각(조준·쏘기)은 그대로 쓰고, 떠다니는 자리만 높게 바꾼다.
class HighWraith extends ECaster:
	const HIGH_UP := 158.0 ## 에스카 몸 가운데에서 위로
	const SIDE := 150.0 ## 옆으로 거리 (낙성이 노리는 앞 30~240 안)
	const BOB := 8.0

	func _think(delta: float) -> void:
		super._think(delta)
		if st != S.FLOAT or not eska_ok():
			return
		var ec := eska.center()
		var want := ec + Vector2(_side * (SIDE + 20.0 * sin(t * 0.7)), -HIGH_UP + sin(t * 1.3) * BOB)
		want.x = clampf(want.x, x_min + 20.0, x_max - 20.0)
		var v := (want - global_position) * 2.2
		velocity = velocity.move_toward(v.limit_length(115.0), 320.0 * delta)
