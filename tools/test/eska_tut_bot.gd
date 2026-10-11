extends Node
## 에스카 튜토리얼 자동 플레이 봇 (시험용 — 순간이동 eval 없이 실제 입력만으로 끝까지 가는지 본다).
## 시나리오에서 [2, "attach", "../tools/test/eska_tut_bot.gd"] 로 붙인다 (eska_tutorial_bot.json).
## 하는 일: 단계(STEPS)마다 정해진 손놀림 — 오른쪽으로 가며 공허 틈 앞에서 점프→점프→순간이동,
## 허수아비 앞에서 베기·천열, 망령 구슬이 몸 가까이 오면 ↑+스킬(딱 맞춤 — 0.5배·0.75배 두 번), 높이 뜬 망령에 ↓+스킬(낙성),
## 가마솥 옆(12px — 솥에 겹치지 않게)에서 ↑ → 달이기 화면에서 Z(거미줄)·Z(거미줄)·Z(달이기)·Z(넘기기)·Esc(닫기), 사냥개가 웅크리면 ↓+물약(속박),
## 거상: 다가가 천열 → 곧바로 ↓+물약(틈 달이기: 처음은 느려짐, 두 번째는 실전 박자) → 싸워 게이지를 채우고 D(고르기) → S(대마법).
## 적이 있으면 다가가 베고 스킬, 예고 동작이면 점프로 피한다. 달이기 화면이 열려 게임이 멈춘 동안에도 돌아야 해서 PROCESS_MODE_ALWAYS.

const PERFECT_DIST := 52.0 ## 구슬이 몸 가운데에서 이 안으로 들어오면 단공 (딱 맞춤 70 안, 몸에 닿기 전)
const NAK_MIN := 50.0 ## 낙성: 앞으로 이 거리 ~ NAK_MAX 안이면 쓴다
const NAK_MAX := 220.0
const THROW_MIN := 100.0 ## 속박: 사냥개가 앞으로 이 거리 ~ THROW_MAX 안이면 던진다 (병은 앞 약 150에 떨어짐)
const THROW_MAX := 200.0
const BOSS_RANGE := 190.0 ## 거상 앞 천열 거리
const UI_GAP := 0.18 ## 달이기 화면에서 누름 사이 (실제 초)
const POT_SIDE := 12.0 ## 가마솥 앞 서는 자리: 솥 가운데에서 왼쪽으로 이만큼 (그림이 겹치지 않게)
const PIT_JUMP := 40.0 ## 공허 틈 가장자리 이만큼 앞에서 점프

var stage: Node
var _t := 0.0
var _seq: Array = [] ## [남은 시간, 동작, 누름?]
var _log_t := 0.0
var _ui_t := 0.0 ## 달이기 화면: 마지막 누름 뒤 시간
var _ui_n := 0 ## 달이기 화면: 누른 수 (거미줄·거미줄·달이기)
var _ui_seen: Object = null


func _ready() -> void:
	stage = get_tree().current_scene
	process_mode = Node.PROCESS_MODE_ALWAYS


func _physics_process(delta: float) -> void:
	_t += delta
	if get_tree().paused:
		_brew_ui(delta)
		return
	var e: EEska = stage.eska
	if e == null or e.controls_locked:
		_release_all()
		return
	_run_seq(delta)
	var step: String = stage.STEPS[stage._step]
	var sub: int = stage._sub
	var x := e.global_position.x
	_log_t -= delta
	if _log_t <= 0.0:
		_log_t = 2.0
		print("BOT t=%.1f step=%s sub=%d x=%d hp=%d gauge=%.2f" % [_t, step, sub, int(x), e.hp, e.gauge_ratio()])
	match step:
		"move", "gap":
			_hold("es_right", true)
			if not _seq.is_empty():
				return
			var px: float = stage.PIT_X
			if x > px - PIT_JUMP - 20.0 and x < px - PIT_JUMP + 20.0 and e.is_on_floor():
				_combo([[0.0, "es_jump"], [0.28, "es_jump"], [0.55, "es_blink"]])
		"combo":
			var cx: float = stage.COMBO_X - 35.0
			_go_to(cx, 6.0)
			if absf(x - cx) < 10.0 and _seq.is_empty():
				_tap("es_attack")
		"cheonyeol":
			var tx: float = stage.CHEON_XS[0] - 170.0
			_go_to(tx, 6.0)
			if absf(x - tx) < 10.0 and _seq.is_empty() and sub == 1:
				_face(1)
				_tap("es_skill")
		"dangong":
			if sub <= 3:
				_deflect(e)
			else:
				_fight(e, step)
		"nakseong":
			_nakseong(e)
		"cauldron":
			_cauldron(e, sub)
		"hound":
			_hound(e, sub)
		"finale":
			_finale(e, sub)
		_:
			_release_all()


## 단공 딱 맞춤: 제자리에서 구슬을 기다렸다가 몸 가까이 오면 ↑+스킬
func _deflect(e: EEska) -> void:
	if e.global_position.x < stage.GATE_DUMMIES + 100.0:
		_hold("es_right", true)
		return
	_hold("es_right", false)
	_hold("es_left", false)
	if not _seq.is_empty():
		return
	for n: Node in get_tree().get_nodes_in_group(EEnemy.PROJECTILE_GROUP):
		var o := n as Node2D
		if o == null:
			continue
		var d := o.global_position.distance_to(e.center())
		if d < PERFECT_DIST and e.cd_left("dangong") <= 0.0:
			_combo([[0.0, "es_up", true], [0.02, "es_skill"], [0.1, "es_up", false]])
			return


## 높이 뜬 망령: 앞 NAK_MIN~NAK_MAX 안에 두고 ↓+스킬
func _nakseong(e: EEska) -> void:
	var foe: Node2D = stage.foe
	if not is_instance_valid(foe):
		_hold("es_right", true)
		return
	if not _seq.is_empty():
		return
	var dx := foe.global_position.x - e.global_position.x
	var want := 140.0 * signf(dx)
	if absf(dx) > NAK_MAX:
		_hold("es_right", dx > 0.0)
		_hold("es_left", dx < 0.0)
		return
	if absf(dx) < NAK_MIN:
		_hold("es_right", dx - want > 0.0)
		_hold("es_left", dx - want < 0.0)
		return
	_hold("es_right", false)
	_hold("es_left", false)
	_face(1 if dx > 0.0 else -1)
	if e.cd_left("nakseong") <= 0.0 and e.facing == int(signf(dx)):
		_combo([[0.0, "es_down", true], [0.02, "es_skill"], [0.1, "es_down", false]])


## 가마솥: 앞에 서서 ↑를 톡 (뗄 때 열림)
func _cauldron(e: EEska, sub: int) -> void:
	var pot: Node2D = stage.pot_rest
	var px := pot.global_position.x - POT_SIDE
	_go_to(px, 3.0)
	if sub == 2 and absf(e.global_position.x - px) < 6.0 and e.is_on_floor() and _seq.is_empty() and stage.pot_rest.ui == null:
		_combo([[0.1, "es_up"]])


## 달이기 화면 (게임 멈춤): 거미줄 → 거미줄 → 달이기 → (결과) 넘기기 → 닫기. 띠(BrewTip)가 초점을 거미줄·↓칸에 맞춰 둔다
func _brew_ui(delta: float) -> void:
	_release_moves()
	var ui: Object = stage.pot_rest.ui if is_instance_valid(stage.pot_rest) else null
	if ui == null:
		ui = stage.pot_boss.ui if is_instance_valid(stage.pot_boss) else null
	if ui == null:
		return
	if ui != _ui_seen:
		_ui_seen = ui
		_ui_n = 0
		_ui_t = 0.0
	_ui_t += delta
	if _ui_t < UI_GAP:
		return
	match String(ui.get("phase")):
		"pick":
			if String(stage.eska.belt.slot(2).get("id", "")) == "bind":
				_ui_tap("es_exit")
			elif _ui_n < 3:
				_ui_tap("es_jump")
				_ui_n += 1
		"reveal":
			if _ui_t > 0.6:
				_ui_tap("es_jump")


func _ui_tap(a: String) -> void:
	_ui_t = 0.0
	var ev := InputEventAction.new()
	ev.action = a
	ev.pressed = true
	Input.parse_input_event(ev)
	var up := InputEventAction.new()
	up.action = a
	up.pressed = false
	Input.parse_input_event(up)
	print("BOT ui ", a, " t=%.1f" % _t)


## 사냥개: 속박을 배우는 동안(sub 4)은 웅크리거나 다가오면 ↓+물약, 그 밖엔 싸움
func _hound(e: EEska, sub: int) -> void:
	if sub == 4 and _seq.is_empty():
		for n: Node in stage.get_children():
			if n is ERunner and not (n as EEnemy).is_dead():
				var r := n as ERunner
				var dx := r.global_position.x - e.global_position.x
				if absf(dx) > THROW_MIN and absf(dx) < THROW_MAX and r.st != ERunner.S.DASH and e.is_on_floor():
					_hold("es_right", false)
					_hold("es_left", false)
					_face(1 if dx > 0.0 else -1)
					_combo([[0.03, "es_down", true], [0.05, "es_potion"], [0.14, "es_down", false]])
					return
	_fight(e, "hound")


## 거상: 천열 → 곧바로 ↓+물약 (sub 4·5 = 첫 시도·느려짐, sub 8 = 두 번째·느림 없음) → 싸움 → D(sub 12) → S(sub 14)
func _finale(e: EEska, sub: int) -> void:
	var boss: Node2D = stage.boss
	if (sub == 4 or sub == 8) and is_instance_valid(boss):
		var dx := boss.global_position.x - e.global_position.x
		if not _seq.is_empty():
			return
		if absf(dx) > BOSS_RANGE + 20.0:
			_hold("es_right", dx > 0.0)
			_hold("es_left", dx < 0.0)
			return
		_hold("es_right", false)
		_hold("es_left", false)
		_face(1 if dx > 0.0 else -1)
		if e.cd_left("cheonyeol") <= 0.0 and e.st == EEska.St.NORMAL:
			# 천열 → 시전 중에 ↓+물약을 눌러 둠 (입력 기억으로 시전이 끝나자마자 던짐)
			_combo([[0.0, "es_skill"], [0.06, "es_down", true], [0.08, "es_potion"], [0.4, "es_down", false]])
		return
	if sub == 5:
		return # 첫 시도에서 이미 눌러 둠
	if sub == 12 and _seq.is_empty():
		_tap("es_ult_next")
		return
	if sub == 14 and _seq.is_empty() and e.st == EEska.St.NORMAL:
		_tap("es_bind")
		return
	_fight(e, "finale")


func _fight(e: EEska, _step: String) -> void:
	var foe: Node2D = null
	for n: Node in stage.get_children():
		if n is EEnemy and not (n as EEnemy).is_dead():
			if foe == null or absf((n as Node2D).global_position.x - e.global_position.x) < absf(foe.global_position.x - e.global_position.x):
				foe = n
	if foe == null:
		_hold("es_right", true) # 다음 구간으로
		_hold("es_left", false)
		return
	var dx := foe.global_position.x - e.global_position.x
	# 예고 동작이면 피하기
	var st = foe.get("st")
	if (foe is ERunner and st == ERunner.S.WIND) or (foe is EColossus and st == EColossus.S.WIND and absf(dx) < 110.0):
		if e.is_on_floor() and _seq.is_empty():
			_combo([[0.0, "es_jump"], [0.3, "es_jump"]])
		return
	if not _seq.is_empty():
		return
	var want := 40.0 if not foe is ECaster else 10.0
	if absf(dx) > want + 20.0:
		_hold("es_right", dx > 0.0)
		_hold("es_left", dx < 0.0)
		return
	_hold("es_right", false)
	_hold("es_left", false)
	_face(1 if dx > 0.0 else -1)
	if foe is ECaster and e.cd_left("dangong") <= 0.0:
		_combo([[0.0, "es_up", true], [0.03, "es_skill"], [0.1, "es_up", false]])
	elif e.cd_left("cheonyeol") <= 0.0 and not foe is ECaster:
		_tap("es_skill")
	else:
		_combo([[0.0, "es_attack"], [0.36, "es_attack"], [0.72, "es_attack"]])


func _go_to(tx: float, tol: float) -> void:
	var x: float = stage.eska.global_position.x
	_hold("es_right", x < tx - tol)
	_hold("es_left", x > tx + tol)


func _face(d: int) -> void:
	if stage.eska.facing != d:
		_tap("es_right" if d > 0 else "es_left")


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


func _release_moves() -> void:
	for a in ["es_left", "es_right", "es_up", "es_down"]:
		if Input.is_action_pressed(a):
			Input.action_release(a)


func _release_all() -> void:
	for a in ["es_left", "es_right", "es_up", "es_down", "es_jump", "es_attack", "es_skill", "es_blink", "es_bind", "es_potion", "es_ult_next"]:
		if Input.is_action_pressed(a):
			Input.action_release(a)
	_seq.clear()
