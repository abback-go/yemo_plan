class_name PBench
extends Node
## 성능 측정(개발용): 훈련장에서 마법을 정해진 순서로 쏘며 단계마다 프레임 시간(평균·95%)과 그리기 호출 수를 출력한다.
## 켜는 법: 웹은 주소 뒤에 ?pbench, 데스크톱·헤드리스는 환경 변수 PBENCH=1. 끝나면 "PBENCH done"을 찍는다.
## 결과 줄: "PBENCH 단계 frame=평균ms p95=ms max=ms draws=평균 nodes=노드수" (docs/dev/proto.md 성능 절)

const PHASES := [
	["blank", 90], ["noscript", 90], ["idle", 120], ["claw", 150], ["foxrain", 150], ["asura", 180], ["laser", 150], ["meteor", 150],
	["phoenix", 170], ["bind", 360], ["fox_dash", 150], ["all", 360],
]

var arena: Node
var _phase := -1
var _pf := 0
var _t_last := 0
var _wait := 30
var _ft: Array[int] = []
var _dc: Array[float] = []
var _rel: Array[String] = []


static func wanted() -> bool:
	if OS.get_environment("PBENCH") == "1":
		return true
	if OS.has_feature("web"):
		var q: Variant = JavaScriptBridge.eval("window.location.search", true)
		return q is String and String(q).contains("pbench")
	return false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _tap(a: String) -> void:
	Input.action_press(a)
	_rel.append(a)


func _process(_d: float) -> void:
	for a in _rel:
		Input.action_release(a)
	_rel.clear()
	var now := Time.get_ticks_usec()
	var sera: PSera = arena.sera
	if _phase < 0:
		_wait -= 1
		if _wait <= 0:
			arena.dbg("key_mode", 1)
			arena.dbg("no_cooldown", true)
			arena.dbg("all_lv", true)
			arena.dbg("tails", 9)
			sera.global_position = Vector2(200, 400)
			_phase = 0
			_pf = 0
			_t_last = now
		return
	if _pf > 10:
		_ft.append(now - _t_last)
		if now - _t_last > (250000 if OS.has_feature("web") else 100000):
			print("PBENCH spike %s frame=%d %.0fms" % [PHASES[_phase][0], _pf, (now - _t_last) / 1000.0])
		_dc.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	_t_last = now
	var name: String = PHASES[_phase][0]
	_drive(name, _pf, sera)
	_pf += 1
	if _pf >= int(PHASES[_phase][1]):
		_report(name)
		_phase += 1
		_pf = 0
		_ft.clear()
		_dc.clear()
		if sera.is_fox():
			sera.fox_time = 0.01
		sera.global_position = Vector2(200, 400)
		sera.velocity = Vector2.ZERO
		if _phase >= PHASES.size():
			print("PBENCH done")
			if not OS.has_feature("web"):
				get_tree().quit()
			queue_free()


func _drive(name: String, i: int, sera: PSera) -> void:
	match name:
		"blank":
			# 아무것도 안 그림(엔진 기본 비용) — 첫 프레임에 숨기고, 다음 단계 시작에 되돌림
			if i == 0:
				_set_vis(false)
		"noscript":
			# 그림은 그대로, 매 프레임 스크립트(다시 그리기)만 멈춤 → idle과의 차이 = 스크립트 비용
			if i == 0:
				_set_vis(true)
				_set_proc(false)
		"idle":
			if i == 0:
				_set_proc(true)
		"claw":
			if i % 8 == 0:
				_tap("pr_claw")
		"foxrain":
			if i % 40 == 0:
				_tap("pr_s_foxrain")
		"asura":
			if i == 2:
				_tap("pr_s_asura")
		"laser":
			if i == 2:
				Input.action_press("pr_s_laser")
			if i == 100:
				Input.action_release("pr_s_laser")
		"meteor":
			if i % 70 == 2:
				_tap("pr_s_meteor")
		"phoenix":
			if i == 2:
				_tap("pr_s_phoenix")
		"bind":
			if i == 2:
				_tap("pr_s_bind")
		"fox_dash":
			if i == 1:
				sera.gauge = 1.0
				_tap("pr_transform")
			if i % 20 == 10:
				_tap("pr_dash")
			if i % 20 == 15:
				_tap("pr_claw")
		"all":
			if i == 2:
				sera.gauge = 1.0
				_tap("pr_transform")
			if i == 6:
				_tap("pr_s_bind")
			if i == 40:
				_tap("pr_s_phoenix")
			if i % 30 == 20:
				_tap("pr_s_fireball")
			if i % 45 == 25:
				_tap("pr_s_foxrain")
			if i % 70 == 60:
				_tap("pr_s_meteor")
			if i % 8 == 3:
				_tap("pr_claw")
			if i == 200:
				_tap("pr_s_asura")


func _set_vis(on: bool) -> void:
	for c in arena.get_children():
		if c is CanvasItem:
			(c as CanvasItem).visible = on
		elif c is CanvasLayer:
			(c as CanvasLayer).visible = on


func _set_proc(on: bool) -> void:
	for n in arena.find_children("*", "", true, false):
		if n != self:
			n.set_process(on)
			n.set_physics_process(on)
	arena.set_process(on)


func _report(name: String) -> void:
	var s := _ft.duplicate()
	s.sort()
	var avg := 0.0
	for v in s:
		avg += float(v)
	avg /= maxf(float(s.size()), 1.0)
	var dc := 0.0
	for v in _dc:
		dc += v
	dc /= maxf(float(_dc.size()), 1.0)
	var p95: float = float(s[mini(int(s.size() * 0.95), s.size() - 1)]) if not s.is_empty() else 0.0
	var mx: float = float(s[s.size() - 1]) if not s.is_empty() else 0.0
	print("PBENCH %-9s frame=%6.2fms p95=%6.2fms max=%6.2fms draws=%5.0f nodes=%d" % [name, avg / 1000.0, p95 / 1000.0, mx / 1000.0, dc, Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])
