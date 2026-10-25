extends SceneTree
## 종언의 마녀 손맛 프로토타입 스모크 시험 (CI: .github/workflows/witch-web-build.yml).
## 장면을 열고 정해진 프레임에 키를 눌러 마법(흑백 균열) · 모드 바꾸기(검무) · 검 3연격 · 공간참 · 점프·이단점프·공중 베기 ·
## 순간이동 · 모드 되돌리기(접힘 파동) · 틈 자국 터뜨리기 · 이동을 한 번씩 돌린다. 끝에 결과를 확인해 실패면 종료 코드 1.
## 키 누름은 에스카 시험 실행기(tools/test/runner.gd)처럼 InputEventAction을 넣고 다음 프레임에 뗀다.
## 사용: cd witch_game && godot --headless --fixed-fps 60 --script ../tools/witch_smoke.gd

const END := 480
## [프레임, 동작 이름] — 그 프레임에 한 번 톡 누른다
const TAPS := [
	[20, "es_attack"], # 마법 모드: 흑백 균열 (0.5초 모아 터짐)
	[80, "bl_mode"], # 마법 → 검: 검무
	[140, "es_attack"], [156, "es_attack"], [172, "es_attack"], # 검 3연격
	[220, "es_skill"], # 공간참
	[270, "es_jump"], [282, "es_jump"], [288, "es_attack"], # 점프 · 이단점프 · 공중 베기
	[330, "es_blink"], # 순간이동
	[360, "bl_mode"], # 검 → 마법: 접힘 파동
	[390, "es_attack"], # 흑백 균열 (틈 자국이 있으면 터짐)
]
## [시작, 끝, 동작 이름] — 그동안 누르고 있는다
const HOLDS := [[440, 470, "es_left"]]

var frame := 0
var _release_next: Array = []
var _started := false


func _initialize() -> void:
	seed(20261025)
	change_scene_to_file("res://main.tscn")


func _send(action: String, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _process(_delta: float) -> bool:
	var stage := current_scene
	if stage == null or stage.get("eska") == null:
		return false
	if not _started:
		_started = true
		stage.eska.global_position = Vector2(470, 300) # 허수아비(530~) 앞
	frame += 1
	for a: String in _release_next:
		_send(a, false)
	_release_next.clear()
	for t: Array in TAPS:
		if int(t[0]) == frame:
			_send(String(t[1]), true)
			_release_next.append(String(t[1]))
	for h: Array in HOLDS:
		if int(h[0]) == frame:
			_send(String(h[2]), true)
		elif int(h[1]) == frame:
			_send(String(h[2]), false)
	if frame >= END:
		_finish(stage)
		return true
	return false


func _finish(stage: Node) -> void:
	var e = stage.eska
	var bursts := 0
	for d in stage.dummies:
		bursts += int(d.bursts)
	var line := "swings=%d blade_hits=%d rifts=%d scar_bursts=%d mode=%d pos=%s" % [
		e.swings, e.blade_hits, e.rifts, bursts, e.mode, str(e.global_position)]
	print("SMOKE ", line)
	var ok: bool = e.swings >= 6 and e.blade_hits >= 3 and e.rifts >= 2
	print("SMOKE OK" if ok else "SMOKE FAIL")
	quit(0 if ok else 1)
