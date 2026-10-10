extends Node
## 에스카 튜토리얼 자동 플레이 봇 (시험용 — 순간이동 eval 없이 실제 입력만으로 끝까지 가는지 본다).
## 시나리오에서 [2, "attach", "../tools/test/eska_tut_bot.gd"] 로 붙인다 (eska_tutorial_bot.json).
## 하는 일: 단계(STEPS)마다 정해진 손놀림 — 오른쪽으로 가며 턱 앞에서 점프·이단점프, 장막 앞에서 순간이동, 틈에서 점프→점프→순간이동,
## 허수아비 앞에서 연격·천열, 적이 있으면 다가가 베고 스킬, 예고 동작이면 점프로 피한다.

var stage: Node
var _t := 0.0
var _seq: Array = [] ## [남은 시간, 동작, 누름?]
var _log_t := 0.0


func _ready() -> void:
	stage = get_tree().current_scene


func _physics_process(delta: float) -> void:
	_t += delta
	var e: EEska = stage.eska
	if e == null or e.controls_locked:
		_release_all()
		return
	_run_seq(delta)
	var step: String = stage.STEPS[stage._step]
	var x := e.global_position.x
	_log_t -= delta
	if _log_t <= 0.0:
		_log_t = 2.0
		print("BOT t=%.1f step=%s x=%d hp=%d" % [_t, step, int(x), e.hp])
	match step:
		"move", "jump", "double", "blink", "gap":
			_hold("es_right", true)
			if not _seq.is_empty():
				return
			if e.is_on_floor() and x > 560.0 and x < 600.0:
				_tap("es_jump")
			elif e.is_on_floor() and x > 820.0 and x < 860.0:
				_combo([[0.0, "es_jump"], [0.25, "es_jump"]])
			elif x > 1255.0 and x < 1300.0 and e.is_on_floor():
				_tap("es_blink")
			elif x > 1440.0 and x < 1480.0 and e.is_on_floor():
				_combo([[0.0, "es_jump"], [0.28, "es_jump"], [0.55, "es_blink"]])
		"combo":
			_go_to(1975.0, 6.0)
			if absf(x - 1975.0) < 10.0 and _seq.is_empty():
				_combo([[0.0, "es_attack"], [0.16, "es_attack"], [0.32, "es_attack"], [0.5, "es_attack"]])
		"cheonyeol":
			_go_to(2120.0, 6.0)
			if absf(x - 2120.0) < 10.0 and _seq.is_empty() and stage._sub == 1:
				_face(1)
				_tap("es_skill")
		"dangong", "bonggong", "finale":
			_fight(e, step)
		_:
			_release_all()


func _fight(e: EEska, step: String) -> void:
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
	elif step == "bonggong" and e.cd_left("bonggong") <= 0.0:
		_tap("es_bind")
	elif step == "finale" and e.cd_left("ult") <= 0.0:
		_tap("es_ult")
	elif e.cd_left("cheonyeol") <= 0.0 and not foe is ECaster:
		_tap("es_skill")
	else:
		_combo([[0.0, "es_attack"], [0.16, "es_attack"], [0.32, "es_attack"], [0.5, "es_attack"]])


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


func _release_all() -> void:
	for a in ["es_left", "es_right", "es_up", "es_jump", "es_attack", "es_skill", "es_blink", "es_bind", "es_ult"]:
		if Input.is_action_pressed(a):
			Input.action_release(a)
	_seq.clear()
