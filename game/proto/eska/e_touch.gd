class_name ETouch
extends CanvasLayer
## 에스카 시제품 모바일 조작 (던전슬래셔 배치 참고).
## 왼쪽 아래 고정 방향키(↑↓←→, 대각선은 두 개가 같이 눌림) · 오른쪽 아래 버튼 7개 — 공격(가장 큼)을 엄지 자리 삼아
## 가까운 고리에 점프·순간·스킬, 바깥 고리에 물약·대마법(+작은 고르기):
##              [대마법](고르기)
##     [물약] [순간]    [스킬]
##         [점프]    [공격]
## 스킬 버튼은 방향키 ↑ = 단공, ↓ = 낙성, 그냥 = 천열 (라벨이 바뀐다). 쿨다운 중에도 이름은 그대로 두고, 둘레 호가 남은 몫만큼 비고
## 이름 아래 작은 남은 초가 붙는다. 공격 버튼은 누르고 있으면 계속 벤다(EEska가 눌림을 봄).
## 대마법 버튼(S): 고른 대마법 이름 + 종언 게이지 달(차오름, 가득이면 밝게 맥박) · 옆 작은 버튼(D)으로 고르기 순환.
## 물약 버튼(F): 방향키 방향(그냥·↑·↓)에 해당하는 허리띠 칸의 병 색 + 남은 병 수. 오른쪽 위 X는 나가기.
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
## 공격 중심에서 가까운 고리(약 84px): 점프·순간·스킬 / 바깥 고리(약 150px): 물약·대마법 + 대마법 옆 작은 고르기
const BUTTONS := [
	["attack", "es_attack", "공격", Vector2(-56, -56), 31.0, ""],
	["jump", "es_jump", "점프", Vector2(-139, -42), 24.0, ""],
	["blink", "es_blink", "순간", Vector2(-121, -111), 26.0, ""],
	["skill", "es_skill", "천열", Vector2(-54, -140), 25.0, "skill"],
	["potion", "es_potion", "물약", Vector2(-204, -100), 21.0, ""],
	["ult", "es_bind", "대마법", Vector2(-134, -190), 24.0, ""],
	["ult_next", "es_ult_next", "", Vector2(-84, -210), 14.0, ""],
]
## 대마법 버튼에 쓰는 짧은 이름 (원 안에 들어가게)
const ULT_SHORT := {"blackstar": "흑성", "meteor": "유성우", "doom": "운석", "bonggong": "봉공"}
const ULT_PULSE := 12.0 ## 게이지가 가득일 때 맥박 그림을 초당 이만큼만 다시 그림
const CD_ARC_W := 3.0 ## 쿨다운 호 굵기
const CD_DIM := 0.4 ## 쿨다운 중 이름 진하기
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
var _t := 0.0 ## 맥박용 시간


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


## 바뀐 것이 있을 때만 다시 그린다 (누른 버튼·방향·화면 크기·쿨다운 초)
func _process(delta: float) -> void:
	if EKeys.touch_mode != active: # 안내 글(EKeys.label)이 입력 방식을 따라가게
		EKeys.touch_mode = active
	_draw.visible = active
	if not active:
		return
	var sig := "%s|%s|%s" % [str(_held.keys()), str(_dirs.values()), str(screen())]
	if is_instance_valid(eska):
		sig += "|%s|%d|%d|%d" % [eska.skill_for_dir(), eska.potion_slot_for_dir(), eska.ult_index, int(eska.gauge_ratio() * 60.0)]
		for id: String in EEska.CD:
			sig += "|%d" % ceili(eska.cd_left(id) * 8.0)
		for sl: Dictionary in eska.belt.slots:
			sig += "|%s%d" % [String(sl.get("id", "")), int(sl.get("left", 0))]
		if eska.gauge_ratio() >= 1.0:
			_t += delta
			sig += "|%d" % int(_t * ULT_PULSE)
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
		id = eska.skill_for_dir()
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
		if is_instance_valid(tc.eska):
			match id:
				"ult":
					_draw_ult(tc, font, c, r, held)
					return
				"ult_next":
					_draw_cycle(c, r, held)
					return
				"potion":
					_draw_potion(tc, font, c, r, held)
					return
		var cd: Array = tc.cooldown_of(String(b[5]))
		var ratio: float = cd[0]
		var label: String = b[2]
		if id == "skill" and is_instance_valid(tc.eska):
			label = EEska.NAMES[tc.eska.skill_for_dir()]
		var fs := 11 if label.length() >= 3 else 12
		if ratio > 0.0:
			# 쿨다운: 바탕을 어둡게, 둘레는 찬 몫(1 - 남은 몫)만 밝은 호로 — 위에서 시계 방향으로 다시 차오름
			draw_circle(c, r, Color(0, 0, 0, 0.35))
			draw_arc(c, r, 0.0, TAU, 40, Color(RING, 0.25), 2.0)
			var done := 1.0 - ratio
			if done > 0.0:
				draw_arc(c, r - 1.0, -PI / 2.0, -PI / 2.0 + TAU * done, maxi(int(40.0 * done), 3), Color(RING, 0.95), CD_ARC_W)
		else:
			draw_arc(c, r, 0.0, TAU, 40, Color(RING, 0.95 if held else 0.6), 2.0)
		var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var tp := c + Vector2(-tw * 0.5, 4 if ratio <= 0.0 else 1)
		var la := (0.95 if held else 0.85) if ratio <= 0.0 else CD_DIM
		draw_string_outline(font, tp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color(0, 0, 0, 0.7))
		draw_string(font, tp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, la))
		if ratio > 0.0:
			var sec := "%d" % ceili(float(cd[1]))
			var sw := font.get_string_size(sec, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
			var sp := c + Vector2(-sw * 0.5, 12)
			draw_string_outline(font, sp, sec, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, 3, Color(0, 0, 0, 0.7))
			draw_string(font, sp, sec, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(EVfx.PALE, 0.9))

	## 대마법(S): 둘레 고리 = 종언 게이지(위에서 시계 방향으로 참), 가운데 위 달이 차오름, 아래 고른 대마법 이름.
	## 가득이면 고리·달이 밝게 맥박. 모자라면 전체가 흐림
	func _draw_ult(tc: ETouch, font: Font, c: Vector2, r: float, held: bool) -> void:
		var e := tc.eska
		var f := e.gauge_ratio()
		var full := f >= 1.0
		var beat := 0.5 + 0.5 * sin(tc._t * 6.0) if full else 0.0
		if full:
			draw_circle(c, r + 3.0 + 2.0 * beat, Color(EVfx.MAGENTA, 0.18 + 0.14 * beat))
			draw_circle(c, r, Color(EVfx.PLUM, 0.55 + 0.2 * beat))
		draw_arc(c, r, 0.0, TAU, 40, Color(RING, 0.35), 2.0)
		if f > 0.0:
			draw_arc(c, r, -PI / 2.0, -PI / 2.0 + TAU * f, maxi(int(40.0 * f), 3), EVfx.EDGE if full else Color(RING, 0.95), 3.0 if full else 2.5)
		var mc := c + Vector2(0, -7.0)
		var mr := 6.5
		draw_circle(mc, mr + 1.0, Color(EVfx.INK, 0.9))
		if f >= EHud.MOON_MIN:
			draw_colored_polygon(EHud.moon_shape(mc, mr, f), EVfx.PALE.lerp(Color.WHITE, 0.5 * beat) if full else Color(EVfx.PALE, 0.75))
		draw_arc(mc, mr + 1.0, 0.0, TAU, 20, Color(RING, 0.7), 1.0)
		var label: String = ULT_SHORT.get(e.selected_ult(), "")
		var fs := 11
		var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var tp := c + Vector2(-tw * 0.5, 13.0)
		draw_string_outline(font, tp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color(0, 0, 0, 0.75))
		draw_string(font, tp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.95) if full or held else Color(1, 1, 1, 0.55))

	## 대마법 고르기(D): 작은 원 안에 도는 화살표
	func _draw_cycle(c: Vector2, r: float, held: bool) -> void:
		var col := Color(1, 1, 1, 0.95 if held else 0.7)
		draw_arc(c, r, 0.0, TAU, 24, Color(RING, 0.95 if held else 0.6), 1.5)
		var ar := r * 0.5
		draw_arc(c, ar, -PI * 0.15, PI * 1.35, 14, col, 1.5)
		var tip := c + Vector2(cos(-PI * 0.15), sin(-PI * 0.15)) * ar
		draw_colored_polygon(PackedVector2Array([tip + Vector2(3.5, 0.5), tip + Vector2(-2.5, -2.5), tip + Vector2(-0.5, 3.5)]), col)

	## 물약(F): 방향키 방향(그냥·↑·↓)에 맞는 허리띠 칸의 병 + 남은 병 수 + 칸 표시. 빈 칸·다 쓴 칸은 흐림
	func _draw_potion(tc: ETouch, font: Font, c: Vector2, r: float, held: bool) -> void:
		var e := tc.eska
		var i := e.potion_slot_for_dir()
		var sl: Dictionary = e.belt.slots[i] if i < e.belt.slots.size() else {}
		var has := String(sl.get("id", "")) != ""
		var left := int(sl.get("left", 0))
		var ok := has and left > 0
		var look := EHud.potion_look(sl)
		draw_arc(c, r, 0.0, TAU, 40, Color(RING, 0.95 if held else (0.6 if ok else 0.3)), 2.0)
		EHud.bottle(self, c + Vector2(-3.0, 1.0), 1.5, look.color, 1.0 if ok else 0.4, ok)
		EHud.belt_mark(self, font, c + Vector2(5.0, -6.0), i, 10, Color(EVfx.PALE, 0.9))
		var num := "%d" % left if has else "-"
		draw_string_outline(font, c + Vector2(5.0, 10.0), num, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color(0, 0, 0, 0.75))
		draw_string(font, c + Vector2(5.0, 10.0), num, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.95 if ok else 0.45))
