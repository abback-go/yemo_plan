class_name BTouch
extends CanvasLayer
## 빗자루 검 데모 터치 조작 (휴대폰 가로 화면 기준).
## 왼쪽 아래 고정 방향 패드(←→↑↓, 손가락을 떼지 않고 미끄러지면 방향이 바로 바뀜) · 오른쪽 아래 버튼 4개:
##          [스킬]
##     [모드]
##  [점프]     [공격]
## 공격(가장 큼)은 누르고 있으면 계속 나간다. 모드 버튼엔 지금 모드(마법·검술), 스킬 버튼엔 지금 스킬 이름과 쿨다운 호.
## 오른쪽 위 X = 나가기. 버튼은 키보드와 같은 동작 이름(InputEventAction)을 보낸다. 키를 누르면 숨고, 화면을 만지면 다시 보인다.

const PAD_OFF := Vector2(84, -84) ## 왼쪽 아래 모서리 기준 패드 중심
const PAD_R := 44.0
const PAD_GRAB := 82.0
const PAD_DEAD := 9.0
const SIDE_K := 0.6
const VERT_K := 0.75
const HIT_PAD := 6.0
const RING := Color("#b9a2ff")
const BUTTONS := [
	["attack", "es_attack", "공격", Vector2(-58, -60), 32.0],
	["jump", "es_jump", "점프", Vector2(-142, -44), 24.0],
	["skill", "es_skill", "스킬", Vector2(-52, -148), 24.0],
	["mode", "bl_mode", "모드", Vector2(-130, -120), 27.0],
]
const EXIT := ["exit", "es_exit", "X", Vector2(-20, 20), 13.0]

var eska: BEska
var active := false
var _touch := {} ## 손가락 번호 → 버튼 id 또는 "pad"
var _held := {}
var _pad_index := -1
var _pad_pos := Vector2.ZERO
var _dirs := {"es_left": false, "es_right": false, "es_up": false, "es_down": false}
var _view: View
var _sig := ""


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_view = View.new()
	_view.owner_ctl = self
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_view)
	active = DisplayServer.is_touchscreen_available()


func _exit_tree() -> void:
	release_all()


## 누른 버튼·방향·손가락 자리·모드·쿨다운이 바뀔 때만 다시 그린다
func _process(_delta: float) -> void:
	EKeys.touch_mode = active
	_view.visible = active
	if not active:
		return
	var sig := "%s|%s|%s" % [_held.keys(), _pad_pos.round() if _pad_index >= 0 else Vector2.INF, screen()]
	if is_instance_valid(eska):
		sig += "|%d|%d" % [eska.mode, int(eska.skill_ratio() * 30.0)]
	if sig != _sig:
		_sig = sig
		_view.queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_touch(event)
	elif event is InputEventScreenDrag:
		_on_drag(event)
	elif (event is InputEventKey and event.pressed and not event.echo) and active:
		active = false
		release_all()


func screen() -> Vector2:
	return get_viewport().get_visible_rect().size


func pad_center() -> Vector2:
	return Vector2(0.0, screen().y) + PAD_OFF


func button_center(b: Array) -> Vector2:
	var s := screen()
	if b[0] == EXIT[0]:
		return Vector2(s.x, 0.0) + (b[3] as Vector2)
	return s + (b[3] as Vector2)


func is_held(action: String) -> bool:
	return _held.has(action)


func _on_touch(e: InputEventScreenTouch) -> void:
	active = true
	if e.pressed:
		if _touch.has(e.index):
			return
		var b := _button_at(e.position)
		if not b.is_empty():
			_touch[e.index] = b[1]
			_press(b[1])
			get_viewport().set_input_as_handled()
			return
		if _pad_index < 0 and e.position.distance_to(pad_center()) < PAD_GRAB:
			_touch[e.index] = "pad"
			_pad_index = e.index
			_pad_pos = e.position
			_update_pad()
			get_viewport().set_input_as_handled()
	else:
		if not _touch.has(e.index):
			return
		var what: String = _touch[e.index]
		_touch.erase(e.index)
		if what == "pad":
			_pad_index = -1
			_set_dirs(false, false, false, false)
		else:
			_release(what)
		get_viewport().set_input_as_handled()


func _on_drag(e: InputEventScreenDrag) -> void:
	if e.index != _pad_index:
		return
	_pad_pos = e.position
	_update_pad()
	get_viewport().set_input_as_handled()


func _update_pad() -> void:
	var off := _pad_pos - pad_center()
	if off.length() < PAD_DEAD:
		_set_dirs(false, false, false, false)
		return
	var ax := absf(off.x)
	var ay := absf(off.y)
	var side := ax >= ay * SIDE_K
	var vert := ay >= ax * VERT_K
	_set_dirs(side and off.x < 0.0, side and off.x > 0.0, vert and off.y < 0.0, vert and off.y > 0.0)


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
	if _held.has(action):
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
	_pad_index = -1
	for a: String in _dirs:
		_dirs[a] = false


func _button_at(pos: Vector2) -> Array:
	var best: Array = []
	var best_d := INF
	for b: Array in BUTTONS + [EXIT]:
		var d := pos.distance_to(button_center(b))
		if d <= float(b[4]) + HIT_PAD and d < best_d:
			best_d = d
			best = b
	return best


class View extends Control:
	var owner_ctl: BTouch

	func _draw() -> void:
		var tc := owner_ctl
		var font := get_theme_default_font()
		# 방향 패드: 둥근 바닥 + 네 화살표 (누른 쪽은 밝게)
		var pc := tc.pad_center()
		draw_circle(pc, BTouch.PAD_R, Color(0.05, 0.02, 0.09, 0.4))
		draw_arc(pc, BTouch.PAD_R, 0.0, TAU, 40, Color(BTouch.RING, 0.5), 1.5)
		for spec: Array in [["es_left", Vector2.LEFT], ["es_right", Vector2.RIGHT], ["es_up", Vector2.UP], ["es_down", Vector2.DOWN]]:
			var dv: Vector2 = spec[1]
			var on: bool = tc._dirs[spec[0]]
			var tip := pc + dv * (BTouch.PAD_R - 8.0)
			var base := pc + dv * (BTouch.PAD_R - 20.0)
			var o := dv.orthogonal() * 8.0
			draw_colored_polygon(PackedVector2Array([tip, base + o, base - o]), Color(1, 1, 1, 0.85) if on else Color(BTouch.RING, 0.45))
		if tc._pad_index >= 0:
			draw_circle(tc._pad_pos, 7.0, Color(1, 1, 1, 0.35))
		for b: Array in BTouch.BUTTONS + [BTouch.EXIT]:
			var c := tc.button_center(b)
			var r := float(b[4])
			var held := tc.is_held(b[1])
			draw_circle(c, r, Color(0.86, 0.78, 1.0, 0.35) if held else Color(0.05, 0.02, 0.09, 0.45))
			draw_arc(c, r, 0.0, TAU, 36, Color(BTouch.RING, 0.9 if held else 0.6), 1.5)
			var label: String = b[2]
			var col := Color(1, 1, 1, 0.92)
			if is_instance_valid(tc.eska):
				var e := tc.eska
				if b[0] == "mode":
					label = "검술" if e.mode == BEska.Mode.SWORD else "마법"
					col = Color("#e6dcff")
				elif b[0] == "skill":
					label = e.skill_name()
					var ratio := e.skill_ratio()
					if ratio > 0.0:
						col = Color(1, 1, 1, 0.4)
						draw_arc(c, r - 2.5, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - ratio), 30, Color(BTouch.RING, 0.95), 3.0)
			var fs := 11 if label.length() <= 2 else 9 # 세 글자 스킬 이름은 원 안에 들어가게 작게
			var sz := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
			draw_string(font, c + Vector2(-sz.x * 0.5, sz.y * 0.3), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
