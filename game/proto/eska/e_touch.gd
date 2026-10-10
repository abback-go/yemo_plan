class_name ETouch
extends CanvasLayer
## 에스카 시제품 모바일 조작 (던전슬래셔 배치 참고).
## 왼쪽 아래 고정 조이스틱 · 오른쪽 아래 버튼 6개:
##              [봉공] [종언참]
##       [순간이동]   [스킬]
##    [점프]   [공격]
## 스킬 버튼은 조이스틱을 위로 밀고 누르면 단공, 아니면 천열 (라벨이 바뀐다). 오른쪽 위 X는 나가기.
## 버튼은 키보드와 같은 동작(InputEventAction, es_*)을 보낸다. 키를 누르면 숨고, 화면을 만지면 다시 보인다.

const STICK_BASE := Vector2(78, 284)
const STICK_R := 36.0
const KNOB_R := 15.0
const STICK_GRAB := 120.0 ## 받침 중심에서 이 거리 안(왼쪽 아래)을 누르면 조이스틱
const STICK_DEAD := 0.3
const SIDE_MIN := 0.38
const UP_MIN := 0.62 ## 위: 수직에서 약 52도 안쪽 (달리면서 비스듬히 밀어도 단공이 잘 나가게)
const DOWN_MIN := 0.75
const HIT_PAD := 6.0

## id, 동작, 라벨, 오른쪽 아래 모서리 기준 위치, 반지름, 쿨다운 키
const BUTTONS := [
	["attack", "es_attack", "공격", Vector2(-54, -54), 31.0, ""],
	["jump", "es_jump", "점프", Vector2(-126, -40), 24.0, ""],
	["blink", "es_blink", "순간", Vector2(-120, -110), 22.0, ""],
	["skill", "es_skill", "천열", Vector2(-56, -126), 25.0, "skill"],
	["ult", "es_ult", "종언참", Vector2(-58, -190), 22.0, "ult"],
	["bind", "es_bind", "봉공", Vector2(-116, -178), 21.0, "bonggong"],
	["exit", "es_exit", "X", Vector2(-20, -340), 13.0, ""],
]

var eska: EEska
var active := false
var _touch := {} ## 손가락 번호 → 버튼 id 또는 "stick"
var _held := {}
var _stick_index := -1
var _stick_pos := STICK_BASE
var _dirs := {"es_left": false, "es_right": false, "es_up": false, "es_down": false}
var _draw: Pad


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_draw = Pad.new()
	_draw.owner_ctl = self
	_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_draw)
	active = DisplayServer.is_touchscreen_available()


func _exit_tree() -> void:
	release_all()


func _process(_delta: float) -> void:
	_draw.visible = active
	if active:
		_draw.queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_touch(event)
	elif event is InputEventScreenDrag:
		_on_drag(event)
	elif (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventJoypadButton and event.pressed):
		if active:
			active = false
			release_all()


func _on_touch(e: InputEventScreenTouch) -> void:
	active = true
	if e.pressed:
		if _touch.has(e.index):
			return
		var b := _button_at(e.position)
		if b != "":
			_touch[e.index] = b
			_press(_action_of(b))
			get_viewport().set_input_as_handled()
			return
		if _stick_index < 0 and e.position.distance_to(STICK_BASE) < STICK_GRAB and e.position.x < 320.0:
			_touch[e.index] = "stick"
			_stick_index = e.index
			_stick_pos = e.position
			_update_stick()
			get_viewport().set_input_as_handled()
	else:
		if not _touch.has(e.index):
			return
		var what: String = _touch[e.index]
		_touch.erase(e.index)
		if what == "stick":
			_stick_index = -1
			_stick_pos = STICK_BASE
			_set_dirs(false, false, false, false)
		else:
			_release(_action_of(what))
		get_viewport().set_input_as_handled()


func _on_drag(e: InputEventScreenDrag) -> void:
	if e.index != _stick_index:
		return
	_stick_pos = e.position
	_update_stick()
	get_viewport().set_input_as_handled()


func _update_stick() -> void:
	var off := (_stick_pos - STICK_BASE) / STICK_R
	var l := off.length()
	if l < STICK_DEAD:
		_set_dirs(false, false, false, false)
		return
	var n := off / l
	_set_dirs(n.x < -SIDE_MIN, n.x > SIDE_MIN, n.y < -UP_MIN, n.y > DOWN_MIN)


func _set_dirs(l: bool, r: bool, u: bool, d: bool) -> void:
	var want := {"es_left": l, "es_right": r, "es_up": u, "es_down": d}
	for a: String in want:
		if want[a] != _dirs[a]:
			_dirs[a] = want[a]
			if want[a]:
				_press(a)
			else:
				_release(a)


func _press(action: String) -> void:
	if action == "" or _held.has(action):
		return
	_held[action] = true
	_send(action, true)


func _release(action: String) -> void:
	if not _held.has(action):
		return
	_held.erase(action)
	_send(action, false)


func _send(action: String, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	ev.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(ev)


func release_all() -> void:
	for a: String in _held.keys():
		_release(a)
	_touch.clear()
	_stick_index = -1
	_stick_pos = STICK_BASE
	for a: String in _dirs:
		_dirs[a] = false


func _action_of(id: String) -> String:
	for b: Array in BUTTONS:
		if b[0] == id:
			return b[1]
	return ""


func button_center(b: Array) -> Vector2:
	return Vector2(640, 360) + (b[3] as Vector2)


func _button_at(pos: Vector2) -> String:
	var best := ""
	var best_d := INF
	for b: Array in BUTTONS:
		var d := pos.distance_to(button_center(b))
		if d <= float(b[4]) + HIT_PAD and d < best_d:
			best_d = d
			best = b[0]
	return best


func is_held(action: String) -> bool:
	return _held.has(action)


func stick_state() -> Dictionary:
	return {"on": _stick_index >= 0, "pos": _stick_pos, "dirs": _dirs}


## 쿨다운 비율·남은 초 (스킬 버튼은 지금 고를 기술 기준)
func cooldown_of(key: String) -> Array:
	if not is_instance_valid(eska) or key == "":
		return [0.0, 0.0]
	var id := key
	if key == "skill":
		id = "dangong" if eska.is_up_held() else "cheonyeol"
	return [eska.cd_ratio(id), eska.cd_left(id)]


class Pad extends Control:
	const RING := Color("#a98bff")
	var owner_ctl: ETouch

	func _draw() -> void:
		var tc := owner_ctl
		var font := get_theme_default_font()
		# 고정 조이스틱
		var st: Dictionary = tc.stick_state()
		var base := STICK_BASE
		draw_circle(base, STICK_R, Color(0.05, 0.03, 0.09, 0.35))
		draw_arc(base, STICK_R, 0.0, TAU, 40, Color(1, 1, 1, 0.45 if st.on else 0.28), 2.0)
		var dirs: Dictionary = st.dirs
		for spec: Array in [["es_left", Vector2.LEFT], ["es_right", Vector2.RIGHT], ["es_up", Vector2.UP], ["es_down", Vector2.DOWN]]:
			var on: bool = dirs[spec[0]]
			var dv: Vector2 = spec[1]
			var tip := base + dv * (STICK_R - 5.0)
			var side := dv.orthogonal() * 4.0
			draw_colored_polygon(PackedVector2Array([tip, tip - dv * 6.0 + side, tip - dv * 6.0 - side]), Color(RING, 0.95) if on else Color(1, 1, 1, 0.3))
		var knob: Vector2 = st.pos
		if knob.distance_to(base) > STICK_R:
			knob = base + (knob - base).normalized() * STICK_R
		draw_circle(knob, KNOB_R, Color(1, 1, 1, 0.42 if st.on else 0.24))
		draw_arc(knob, KNOB_R, 0.0, TAU, 24, Color(1, 1, 1, 0.65), 1.0)
		# 버튼
		for b: Array in BUTTONS:
			var id: String = b[0]
			var c := tc.button_center(b)
			var r: float = b[4]
			var held := tc.is_held(String(b[1]))
			draw_circle(c, r, Color(RING, 0.45) if held else Color(0.04, 0.03, 0.08, 0.45))
			var cd: Array = tc.cooldown_of(String(b[5]))
			var ratio: float = cd[0]
			if ratio > 0.0:
				var pts := PackedVector2Array([c])
				var steps := 24
				for i in steps + 1:
					var a := -PI / 2.0 + TAU * ratio * float(i) / float(steps)
					pts.append(c + Vector2(cos(a), sin(a)) * r)
				draw_colored_polygon(pts, Color(0, 0, 0, 0.55))
			draw_arc(c, r, 0.0, TAU, 40, Color(RING, 0.95 if held else 0.6), 2.0)
			if id == "ult" and ratio <= 0.0:
				var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006)
				draw_arc(c, r + 3.0, 0.0, TAU, 40, Color(1, 1, 1, 0.35 + 0.4 * pulse), 1.5)
			var label: String = b[2]
			if id == "skill" and is_instance_valid(tc.eska) and tc.eska.is_up_held():
				label = "단공"
			var fs := 11 if label.length() >= 3 else 12
			if ratio > 0.0:
				label = "%d" % ceili(float(cd[1]))
				fs = 14
			var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var tp := c + Vector2(-tw * 0.5, 4)
			draw_string_outline(font, tp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color(0, 0, 0, 0.7))
			draw_string(font, tp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.95 if held else 0.85))
