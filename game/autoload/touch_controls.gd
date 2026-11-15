extends CanvasLayer
## 모바일 터치 조작 (오토로드 TouchControls). 화면을 터치하면 나타나고, 키보드·패드를 쓰면 숨는다.
## - 왼쪽 절반 아무 곳: 떠 있는 조이스틱. 상하좌우를 "구역"으로 판정해서 달리다가 ↓가 실수로 눌리지 않게 한다
##   (↓+점프 = 발판 내려가기, ↑ = 상호작용이라 오입력이 곧 사고).
## - 오른쪽: 공격·점프·대시(큰 버튼), 불기둥·폭풍·여우창·물약(작은 버튼), 오른쪽 위: 지도·일시정지.
## - 버튼은 키보드와 같은 동작(InputEventAction)을 보내므로 세라 조작·멈춤 안내·대화가 그대로 반응한다.
## - 컷신·대화 중에는 숨고, 화면을 탭하면 대화·알림·지도가 넘어간다(ui_accept).
## - 메뉴(타이틀·일시정지·설정·끝 화면)는 각 메뉴가 탭을 직접 받는다(터치 → 마우스 흉내).

const HALF_X := 320.0 ## 이 x보다 왼쪽을 누르면 조이스틱
const STICK_R := 34.0 ## 조이스틱 받침 반지름
const KNOB_R := 14.0
const STICK_DEAD := 0.28 ## 받침 반지름 대비 이만큼은 움직여야 입력
const STICK_FOLLOW := 1.5 ## 손가락이 받침 반지름의 이 배수보다 멀어지면 받침이 따라온다
const SIDE_MIN := 0.38 ## 좌우: 수평에서 약 67도 안쪽
const VERT_MIN := 0.72 ## 위아래: 수직에서 약 44도 안쪽만 (대각선 아래로 달려도 ↓가 아님)
const HIT_PAD := 6.0 ## 버튼을 그린 원보다 이만큼 넓게 눌림 판정
const SCALES := [0.8, 1.0, 1.2] ## 설정 "터치 버튼 크기" 작게·보통·크게

const BLUE := Color(0.45, 0.78, 1.0)

## 버튼: id, 동작, 이름, 키 글자, 기준 모서리(0 오른쪽 아래 · 1 오른쪽 위)에서의 위치, 반지름
const BUTTONS := [
	["attack", "attack", "공격", "X", 0, Vector2(-44, -46), 28.0],
	["jump", "jump", "점프", "Z", 0, Vector2(-110, -40), 26.0],
	["dash", "dash", "대시", "C", 0, Vector2(-48, -112), 22.0],
	["window", "fox_window", "여우창", "D", 0, Vector2(-150, -118), 20.0],
	["potion", "potion", "물약", "Q", 0, Vector2(-26, -168), 20.0],
	["slot_a", "skill_1", "", "A", 0, Vector2(-118, -176), 20.0],
	["slot_s", "skill_2", "", "S", 0, Vector2(-70, -200), 20.0],
	["slot_f", "skill_3", "", "F", 0, Vector2(-26, -246), 22.0],
	["map", "map", "", "", 1, Vector2(-86, 32), 26.0], ## 미니맵 자리를 누르면 지도 (그림 없음)
	["pause", "pause", "II", "", 1, Vector2(-22, 20), 15.0],
]

## 멈춤 안내(TeachPrompt)에 보여 줄 터치 버튼 이름
const TOUCH_LABEL := {
	"move": "조이스틱 ◀▶", "move_left": "조이스틱 ◀", "move_right": "조이스틱 ▶", "jump": "점프", "attack": "공격",
	"dash": "대시", "skill_1": "A 마법", "skill_2": "S 마법", "skill_3": "F 고급 마법", "fox_window": "여우창", "potion": "물약",
	"move_up": "조이스틱 ▲", "move_down": "조이스틱 ▼", "map": "지도", "pause": "II",
}

var active := false ## 터치 모드 (마지막 입력이 터치)
var shown := false ## 지금 게임 조작을 그리고 받는 중

var _scale := 1.0
var _touch := {} ## 터치 index → 버튼 id 또는 "stick"
var _held := {} ## 지금 누르고 있는 동작 → true
var _stick_index := -1
var _stick_base := Vector2.ZERO
var _stick_pos := Vector2.ZERO
var _dirs := {"move_left": false, "move_right": false, "move_up": false, "move_down": false}
var _draw: TouchDraw


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_draw = TouchDraw.new()
	_draw.owner_ctl = self
	_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_draw)
	active = DisplayServer.is_touchscreen_available() \
		and (OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"))


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		release_all()


func _process(_delta: float) -> void:
	_scale = float(SCALES[clampi(int(GameState.settings.get("touch_scale", 1)), 0, SCALES.size() - 1)])
	shown = active and _play_context()
	_draw.visible = shown
	if shown:
		_draw.queue_redraw()


## 게임 조작을 보여 줄 때: 세라가 살아 있고 조작 가능, 멈춤 화면이 아님 (멈춤 안내는 버튼을 눌러야 하므로 예외)
func _play_context() -> bool:
	var p := get_tree().get_first_node_in_group(GameConst.GROUP_PLAYER) as Player
	if p == null or not p.is_alive():
		return false
	var w := World.get_world()
	if w and w.teach and w.teach.is_active():
		return true
	if get_tree().paused:
		return false
	return p.controls_enabled


# ─── 입력 ───────────────────────────────────────────────

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
	if not active:
		active = true
		shown = _play_context() # 키보드를 쓰다가 처음 터치해도 그 손가락이 바로 조작이 되게
	if e.pressed:
		if _touch.has(e.index):
			return
		if shown:
			var b := _button_at(e.position)
			if b != "":
				_touch[e.index] = b
				_press(_button_action(b))
				get_viewport().set_input_as_handled()
				return
			if e.position.x < HALF_X and _stick_index < 0:
				_touch[e.index] = "stick"
				_stick_index = e.index
				_stick_base = _clamp_base(e.position)
				_stick_pos = e.position
				_update_stick()
				get_viewport().set_input_as_handled()
				return
		_screen_tap()
	else:
		if not _touch.has(e.index):
			return
		var what: String = _touch[e.index]
		_touch.erase(e.index)
		if what == "stick":
			_stick_index = -1
			_set_dirs(false, false, false, false)
		else:
			_release(_button_action(what))


func _on_drag(e: InputEventScreenDrag) -> void:
	if e.index != _stick_index:
		return
	_stick_pos = e.position
	var off := _stick_pos - _stick_base
	var far := STICK_R * STICK_FOLLOW
	if off.length() > far:
		_stick_base += off.normalized() * (off.length() - far)
	_update_stick()


## 대화·알림·지도가 탭을 기다리면 확인 입력을 보낸다
func _screen_tap() -> void:
	var w := World.get_world()
	if w == null:
		return
	if (w.dialogue and w.dialogue.accepts_tap()) or (w.notice and w.notice.accepts_tap()) \
			or (w.map_screen and w.map_screen.accepts_tap()):
		_send("ui_accept", true)
		_send("ui_accept", false)


func _update_stick() -> void:
	var off := (_stick_pos - _stick_base) / STICK_R
	var len := off.length()
	if len < STICK_DEAD:
		_set_dirs(false, false, false, false)
		return
	var n := off / len
	_set_dirs(n.x < -SIDE_MIN, n.x > SIDE_MIN, n.y < -VERT_MIN, n.y > VERT_MIN)


func _set_dirs(l: bool, r: bool, u: bool, d: bool) -> void:
	var want := {"move_left": l, "move_right": r, "move_up": u, "move_down": d}
	for a in want:
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


## 키보드와 똑같이: 상태(Input.is_action_pressed)도 바뀌고 _input/_unhandled_input에도 전달된다
func _send(action: String, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	ev.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(ev)


func release_all() -> void:
	for a in _held.keys():
		_release(a)
	_touch.clear()
	_stick_index = -1
	for a in _dirs:
		_dirs[a] = false


# ─── 버튼 배치 ───────────────────────────────────────────

func _button_action(id: String) -> String:
	for b in BUTTONS:
		if b[0] == id:
			return b[1]
	return ""


func button_center(b: Array) -> Vector2:
	if b[0] == "map":
		return Vector2(554, 32) # HUD 미니맵 가운데 (크기 설정과 무관)
	var corner := Vector2(640, 360) if int(b[4]) == 0 else Vector2(640, 0)
	return corner + (b[5] as Vector2) * _scale


func button_radius(b: Array) -> float:
	if b[0] == "map":
		return 26.0
	return float(b[6]) * _scale


## 칸 버튼에 끼운 마법 ID (여우 모드 S는 비어 있어도 구미호 폭풍)
func slot_spell(id: String) -> String:
	match id:
		"slot_a":
			return Spells.equipped("a")
		"slot_s":
			var sp := Spells.equipped("s")
			if sp == "":
				var p := get_tree().get_first_node_in_group(GameConst.GROUP_PLAYER) as Player
				if p != null and p.is_fox():
					return "storm"
			return sp
		"slot_f":
			return Spells.equipped("f")
	return ""


## 지금 보이는 버튼인가 (배우지 않은 스킬·받지 않은 물약은 숨김)
func button_visible(id: String) -> bool:
	match id:
		"slot_a", "slot_s":
			return slot_spell(id) != ""
		"slot_f":
			return GameState.has_ability("meteor") or GameState.has_ability("phoenix")
		"window":
			return GameState.has_ability("fox_window")
		"potion":
			return GameState.potions_max > 0
		"map":
			return World.get_world() != null
	return true


func _button_at(pos: Vector2) -> String:
	var best := ""
	var best_d := INF
	for b in BUTTONS:
		if not button_visible(b[0]):
			continue
		var d := pos.distance_to(button_center(b))
		if d <= button_radius(b) + HIT_PAD and d < best_d:
			best_d = d
			best = b[0]
	return best


func _clamp_base(pos: Vector2) -> Vector2:
	var r := STICK_R + 4.0
	return Vector2(clampf(pos.x, r, HALF_X - r), clampf(pos.y, r + 40.0, 360.0 - r))


func is_held(action: String) -> bool:
	return _held.has(action)


func stick_state() -> Dictionary:
	return {"on": _stick_index >= 0, "base": _stick_base, "pos": _stick_pos, "dirs": _dirs}


## 멈춤 안내가 기다리는 동작 (버튼을 깜빡여 알려 줌)
func teach_wanted() -> Array:
	var w := World.get_world()
	if w and w.teach and w.teach.is_active():
		return w.teach.wanted()
	return []


class TouchDraw extends Control:
	var owner_ctl: Node
	var _font: Font
	var _t := 0.0

	func _ready() -> void:
		_font = ThemeDB.fallback_font

	func _process(delta: float) -> void:
		_t += delta

	func _draw() -> void:
		var tc = owner_ctl
		var p := get_tree().get_first_node_in_group(GameConst.GROUP_PLAYER) as Player
		var fox := p != null and p.is_fox()
		var ring_col := BLUE if fox else Palette.FIRE_OUT
		var wanted: Array = tc.teach_wanted()
		var pulse := 0.5 + 0.5 * sin(_t * 8.0)
		# 조이스틱
		var st: Dictionary = tc.stick_state()
		var move_wanted := false
		for a in ["move", "move_left", "move_right", "move_up", "move_down"]:
			if wanted.has(a):
				move_wanted = true
		if st.on:
			var base: Vector2 = st.base
			draw_circle(base, STICK_R, Color(1, 1, 1, 0.07))
			draw_arc(base, STICK_R, 0.0, TAU, 32, Color(1, 1, 1, 0.35), 2.0)
			var dirs: Dictionary = st.dirs
			_draw_dir(base, Vector2.LEFT, dirs.move_left)
			_draw_dir(base, Vector2.RIGHT, dirs.move_right)
			_draw_dir(base, Vector2.UP, dirs.move_up)
			_draw_dir(base, Vector2.DOWN, dirs.move_down)
			var knob: Vector2 = st.pos
			if knob.distance_to(base) > STICK_R:
				knob = base + (knob - base).normalized() * STICK_R
			draw_circle(knob, KNOB_R, Color(1, 1, 1, 0.38))
			draw_arc(knob, KNOB_R, 0.0, TAU, 20, Color(1, 1, 1, 0.6), 1.0)
		else:
			# 손가락을 대면 생기는 자리를 흐리게 알려 줌
			var ghost := Vector2(84, 284)
			var a := 0.12 + (0.35 * pulse if move_wanted else 0.0)
			draw_arc(ghost, STICK_R, 0.0, TAU, 32, Color(1, 1, 1, a), 2.0)
			draw_circle(ghost, KNOB_R, Color(1, 1, 1, a * 0.8))
			if move_wanted:
				draw_arc(ghost, STICK_R + 5.0, 0.0, TAU, 32, Color(Palette.GOLD, 0.4 + 0.5 * pulse), 2.0)
		# 버튼
		for b in BUTTONS:
			var id: String = b[0]
			if not tc.button_visible(id):
				continue
			var c: Vector2 = tc.button_center(b)
			var r: float = tc.button_radius(b)
			var held: bool = tc.is_held(String(b[1]))
			if id == "map":
				# 미니맵(HUD가 그림)이 곧 지도 버튼: 누를 때만 테두리
				if held:
					draw_rect(Rect2(506, 6, 96, 52), Color(ring_col, 0.9), false, 2.0)
				continue
			draw_circle(c, r, Color(ring_col, 0.42) if held else Color(0.04, 0.03, 0.08, 0.42))
			_draw_cooldown(id, c, r, p)
			draw_arc(c, r, 0.0, TAU, 32, Color(ring_col, 0.85 if held else 0.55), 2.0)
			if wanted.has(String(b[1])):
				draw_arc(c, r + 4.0, 0.0, TAU, 32, Color(Palette.GOLD, 0.4 + 0.5 * pulse), 2.0)
			var label := _label(id, String(b[2]), fox)
			if id.begins_with("slot_"):
				var sp: String = tc.slot_spell(id)
				label = String(Spells.info(sp).get("short", "")) if sp != "" else "—"
				if fox and sp == "pillar":
					label = "여우비"
				elif fox and sp == "storm":
					label = "구미호"
			if id == "slot_f":
				draw_arc(c, r + 2.0, 0.0, TAU, 32, Color(Palette.GOLD, 0.6), 1.0)
			var fs := 12
			var tw := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var text_col := Color(Palette.UI_TEXT, 0.95 if held else 0.8)
			draw_string_outline(_font, c + Vector2(-tw * 0.5, 4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color(0, 0, 0, 0.6))
			draw_string(_font, c + Vector2(-tw * 0.5, 4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, text_col)
			var key := String(b[3])
			if id == "potion":
				key = "%d" % GameState.potions
			if key != "":
				var kp := c + Vector2(r * 0.55, -r * 0.55)
				draw_string_outline(_font, kp, key, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color(0, 0, 0, 0.7))
				draw_string(_font, kp, key, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(Palette.GOLD, 0.85))

	func _label(id: String, label: String, fox: bool) -> String:
		if not fox:
			return label
		match id:
			"attack": return "여우불"
		return label

	func _draw_cooldown(id: String, c: Vector2, r: float, p: Player) -> void:
		if p == null:
			return
		if not id.begins_with("slot_"):
			return
		var sp: String = owner_ctl.slot_spell(id)
		if sp == "":
			return
		var cd: Vector2 = p.spell_cooldown(sp)
		var left := cd.x
		var total := maxf(cd.y, 0.01)
		if left <= 0.0:
			return
		var k := clampf(left / total, 0.0, 1.0)
		var pts := PackedVector2Array([c])
		var steps := 24
		for i in steps + 1:
			var ang := -PI * 0.5 + TAU * k * float(i) / steps
			pts.append(c + Vector2(cos(ang), sin(ang)) * r)
		if pts.size() >= 3:
			draw_colored_polygon(pts, Color(0, 0, 0, 0.55))

	func _draw_dir(base: Vector2, d: Vector2, on: bool) -> void:
		var tip := base + d * (STICK_R - 4.0)
		var side := Vector2(-d.y, d.x) * 5.0
		var back := tip - d * 7.0
		draw_colored_polygon(PackedVector2Array([tip, back + side, back - side]), Color(Palette.GOLD, 0.9) if on else Color(1, 1, 1, 0.25))
