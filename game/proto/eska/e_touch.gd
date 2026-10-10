class_name ETouch
extends CanvasLayer
## 에스카 시제품 모바일 조작 (던전슬래셔 배치 참고).
## 왼쪽 아래 고정 방향키(↑↓←→, 대각선은 두 개가 같이 눌림) · 오른쪽 아래 버튼 6개:
##              [봉공] [종언참]
##       [순간이동]   [스킬]
##    [점프]   [공격]
## 스킬 버튼은 ↑를 누른 채 누르면 단공, 아니면 천열 (라벨이 바뀐다). 오른쪽 위 X는 나가기.
## 화면 비율이 달라도 방향키는 왼쪽 아래, 버튼은 오른쪽 아래 모서리에 붙는다.
## 버튼은 키보드와 같은 동작(InputEventAction, es_*)을 보낸다. 키를 누르면 숨고, 화면을 만지면 다시 보인다.

const PAD_OFF := Vector2(84, -84) ## 왼쪽 아래 모서리 기준 방향키 중심
const PAD_STEP := 31.0 ## 중심에서 각 화살표 칸까지
const PAD_KEY := 17.0 ## 화살표 칸 크기(반지름)
const PAD_GRAB := 74.0 ## 중심에서 이 거리 안을 누르면 방향키
const PAD_DEAD := 8.0 ## 가운데 이만큼은 아무 방향도 아님
const SIDE_K := 0.6 ## |가로| ≥ |세로|×0.6 이면 ←/→ (약 59도 안쪽 — 달리며 비스듬히 눌러도 잘 잡힘)
const VERT_K := 0.75 ## |세로| ≥ |가로|×0.75 이면 ↑/↓ (겹치는 구간은 대각선)
const HIT_PAD := 6.0

## id, 동작, 라벨, 오른쪽 아래 모서리 기준 위치, 반지름, 쿨다운 키
const BUTTONS := [
	["attack", "es_attack", "공격", Vector2(-54, -54), 31.0, ""],
	["jump", "es_jump", "점프", Vector2(-126, -40), 24.0, ""],
	["blink", "es_blink", "순간", Vector2(-120, -110), 22.0, ""],
	["skill", "es_skill", "천열", Vector2(-56, -126), 25.0, "skill"],
	["ult", "es_ult", "종언참", Vector2(-58, -190), 22.0, "ult"],
	["bind", "es_bind", "봉공", Vector2(-116, -178), 21.0, "bonggong"],
]
## 나가기: 오른쪽 위 모서리 기준
const EXIT := ["exit", "es_exit", "X", Vector2(-20, 20), 13.0, ""]
const ARROWS := [["es_left", Vector2.LEFT], ["es_right", Vector2.RIGHT], ["es_up", Vector2.UP], ["es_down", Vector2.DOWN]]

var eska: EEska
var active := false
var _touch := {} ## 손가락 번호 → 버튼 id 또는 "pad"
var _held := {}
var _pad_index := -1
var _pad_pos := Vector2.ZERO ## 방향키를 누른 손가락 위치 (화면 좌표)
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


var _sig := ""


## 바뀐 것이 있을 때만 다시 그린다 (누른 버튼·방향·화면 크기·쿨다운 초·종언참 준비 깜빡임)
func _process(_delta: float) -> void:
	_draw.visible = active
	if not active:
		return
	var sig := "%s|%s|%s|%s" % [str(_held.keys()), str(_dirs.values()), str(screen()), str(is_instance_valid(eska) and eska.is_up_held())]
	if is_instance_valid(eska):
		for id: String in ["cheonyeol", "dangong", "bonggong", "ult"]:
			sig += "|%d" % ceili(eska.cd_left(id) * 8.0)
		if eska.cd_left("ult") <= 0.0:
			sig += "|%d" % (Time.get_ticks_msec() / 50)
	if sig != _sig:
		_sig = sig
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


## 지금 화면 크기 (비율에 맞춰 늘어난 크기)
func screen() -> Vector2:
	return get_viewport().get_visible_rect().size


func pad_center() -> Vector2:
	return Vector2(0.0, screen().y) + PAD_OFF


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
			_release(_action_of(what))
		get_viewport().set_input_as_handled()


## 손가락을 떼지 않고 화살표 사이를 미끄러지면 방향이 바로 바뀐다
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
	_pad_index = -1
	for a: String in _dirs:
		_dirs[a] = false


func _action_of(id: String) -> String:
	if id == EXIT[0]:
		return EXIT[1]
	for b: Array in BUTTONS:
		if b[0] == id:
			return b[1]
	return ""


## 동작(es_*)의 화면 버튼 자리 [중심, 반지름] — 튜토리얼이 그 버튼 둘레를 빛낸다. 없으면 []
func spot(action: String) -> Array:
	for b: Array in BUTTONS:
		if b[1] == action:
			return [button_center(b), float(b[4])]
	for a: Array in ARROWS:
		if a[0] == action:
			return [pad_center() + (a[1] as Vector2) * PAD_STEP, PAD_KEY]
	return []


func button_center(b: Array) -> Vector2:
	var s := screen()
	if b[0] == EXIT[0]:
		return Vector2(s.x, 0.0) + (b[3] as Vector2)
	return s + (b[3] as Vector2)


func _button_at(pos: Vector2) -> String:
	var best := ""
	var best_d := INF
	for b: Array in BUTTONS + [EXIT]:
		var d := pos.distance_to(button_center(b))
		if d <= float(b[4]) + HIT_PAD and d < best_d:
			best_d = d
			best = b[0]
	return best


func is_held(action: String) -> bool:
	return _held.has(action)


func pad_state() -> Dictionary:
	return {"on": _pad_index >= 0, "pos": _pad_pos, "center": pad_center(), "dirs": _dirs}


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
		_draw_pad(tc)
		for b: Array in BUTTONS + [EXIT]:
			_draw_button(tc, font, b)

	## 고정 방향키: 가운데 받침 + 바깥을 향해 뾰족한 육각 화살표 칸 4개
	func _draw_pad(tc: ETouch) -> void:
		var c := tc.pad_center()
		var on_any := tc._pad_index >= 0
		draw_circle(c, PAD_STEP + PAD_KEY + 4.0, Color(0.05, 0.03, 0.09, 0.28))
		draw_arc(c, PAD_STEP + PAD_KEY + 4.0, 0.0, TAU, 48, Color(1, 1, 1, 0.16 if not on_any else 0.26), 1.0)
		for spec: Array in ARROWS:
			var dv: Vector2 = spec[1]
			var on: bool = tc._dirs[spec[0]]
			var kc := c + dv * PAD_STEP
			var hex := _hex(kc, dv, PAD_KEY)
			draw_colored_polygon(hex, Color(RING, 0.5) if on else Color(0.04, 0.03, 0.08, 0.5))
			var rim := hex.duplicate()
			rim.append(hex[0])
			draw_polyline(rim, Color(RING, 0.95) if on else Color(RING, 0.55), 2.0 if on else 1.5, true)
			# 화살표
			var tip := kc + dv * 7.0
			var side := dv.orthogonal() * 6.0
			draw_colored_polygon(PackedVector2Array([tip, kc - dv * 3.0 + side, kc - dv * 3.0 - side]), Color(1, 1, 1, 0.95) if on else Color(1, 1, 1, 0.55))
		draw_circle(c, 5.0, Color(1, 1, 1, 0.12))

	## 바깥쪽(dv)으로 뾰족하고 안쪽은 납작한 육각형
	func _hex(kc: Vector2, dv: Vector2, r: float) -> PackedVector2Array:
		var o := dv.orthogonal()
		return PackedVector2Array([
			kc + dv * r,
			kc + dv * (r * 0.45) + o * r * 0.82,
			kc - dv * (r * 0.8) + o * r * 0.82,
			kc - dv * r,
			kc - dv * (r * 0.8) - o * r * 0.82,
			kc + dv * (r * 0.45) - o * r * 0.82,
		])

	func _draw_button(tc: ETouch, font: Font, b: Array) -> void:
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
