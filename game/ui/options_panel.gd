class_name OptionsPanel
extends Control
## 설정 (docs/archive/sera/chapter1.md 10절): 전체·음악·효과음 음량, 화면 흔들림, 피해 숫자, 전체 화면(웹 제외).
## ↑↓ 고르기, ←→ 바꾸기, Z/Esc 돌아가기. 바꾸는 즉시 적용·저장. 터치로 줄을 누르면 바로 바뀐다.
## 터치 화면이면 "터치 버튼 크기"(작게·보통·크게)도 보인다.

signal closed

const SIZE_NAMES := ["작게", "보통", "크게"]
const DIFF_NAMES := ["쉬움 (초보자)", "보통"]

var _rows: Array = []
var _sel := 0
var _font: Font
var _t := 0.0


func _ready() -> void:
	_font = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(340, 180)


func open() -> void:
	_rows = [
		["전체 음량", "master", "vol"],
		["음악", "music", "vol"],
		["효과음", "sfx", "vol"],
		["화면 흔들림", "shake", "bool"],
		["피해 숫자", "damage_numbers", "bool"],
	]
	if OS.get_name() != "Web":
		_rows.append(["전체 화면", "fullscreen", "bool"])
	_rows.append(["난이도", "difficulty", "size2"])
	if DisplayServer.is_touchscreen_available() or TouchControls.active:
		_rows.append(["터치 버튼 크기", "touch_scale", "size"])
	_rows.append(["돌아가기", "", "back"])
	_sel = 0


func handle_input(event: InputEvent) -> bool:
	if not visible:
		return false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		return _tap((make_input_local(event) as InputEventMouseButton).position)
	if event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		_sel = (_sel - 1 + _rows.size()) % _rows.size()
		Sfx.play(&"ui_move", 0.0, 0.0)
		return true
	if event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		_sel = (_sel + 1) % _rows.size()
		Sfx.play(&"ui_move", 0.0, 0.0)
		return true
	var row: Array = _rows[_sel]
	var dir := 0
	if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		dir = -1
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		dir = 1
	var ok := event.is_action_pressed("ui_accept") or event.is_action_pressed("jump") or event.is_action_pressed("attack")
	if event.is_action_pressed("ui_cancel") or (ok and row[2] == "back"):
		Sfx.play(&"ui_ok", 0.0, 0.0)
		closed.emit()
		return true
	if dir != 0 or ok:
		var key: String = row[1]
		match row[2]:
			"vol":
				var v := float(GameState.settings[key]) + (0.1 * dir if dir != 0 else 0.1)
				if ok and dir == 0 and v > 1.001:
					v = 0.0
				GameState.settings[key] = clampf(snappedf(v, 0.1), 0.0, 1.0)
			"bool":
				GameState.settings[key] = not bool(GameState.settings[key])
			"size":
				GameState.settings[key] = wrapi(int(GameState.settings[key]) + (dir if dir != 0 else 1), 0, SIZE_NAMES.size())
			"size2":
				GameState.settings[key] = wrapi(int(GameState.settings[key]) + (dir if dir != 0 else 1), 0, DIFF_NAMES.size())
		GameState.apply_settings()
		GameState.save_settings()
		Sfx.play(&"ui_move", 0.0, 0.0)
		return true
	return false


## 터치·마우스: 누른 줄을 고르고 바로 바꾼다. 음량은 막대의 누른 칸으로, 그 밖은 한 칸씩 올림(끝에서 0)
func _tap(lp: Vector2) -> bool:
	for i in _rows.size():
		var y := 22.0 + i * 20.0
		if not Rect2(-16, y - 15, 350, 20).has_point(lp):
			continue
		_sel = i
		var row: Array = _rows[i]
		var key: String = row[1]
		match row[2]:
			"back":
				Sfx.play(&"ui_ok", 0.0, 0.0)
				closed.emit()
				return true
			"vol":
				var v := float(GameState.settings[key]) + 0.1
				if lp.x >= 150.0 and lp.x < 290.0:
					v = clampf(floorf((lp.x - 150.0) / 14.0) + 1.0, 1.0, 10.0) / 10.0
				elif v > 1.001:
					v = 0.0
				GameState.settings[key] = clampf(snappedf(v, 0.1), 0.0, 1.0)
			"bool":
				GameState.settings[key] = not bool(GameState.settings[key])
			"size":
				GameState.settings[key] = wrapi(int(GameState.settings[key]) + 1, 0, SIZE_NAMES.size())
			"size2":
				GameState.settings[key] = wrapi(int(GameState.settings[key]) + 1, 0, DIFF_NAMES.size())
		GameState.apply_settings()
		GameState.save_settings()
		Sfx.play(&"ui_move", 0.0, 0.0)
		return true
	return false


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	draw_string(_font, Vector2(0, 0), "설정", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.GOLD)
	for i in _rows.size():
		var row: Array = _rows[i]
		var y := 22.0 + i * 20.0
		var sel := i == _sel
		var col := Palette.UI_TEXT if sel else Palette.UI_DIM
		if sel:
			draw_rect(Rect2(-6, y - 13, 330, 18), Color(1, 1, 1, 0.05))
			draw_colored_polygon(PackedVector2Array([Vector2(-14 + sin(_t * 8.0), y - 9), Vector2(-8 + sin(_t * 8.0), y - 5), Vector2(-14 + sin(_t * 8.0), y - 1)]), Palette.FIRE_OUT)
		draw_string(_font, Vector2(0, y), String(row[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
		match row[2]:
			"vol":
				var v := float(GameState.settings[row[1]])
				for k in 10:
					var on := k < int(round(v * 10.0))
					draw_rect(Rect2(150 + k * 14, y - 9, 10, 8), Palette.FIRE_HOT if on else Color("#2a2238"))
				draw_string(_font, Vector2(300, y), "%d" % int(round(v * 100.0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
			"bool":
				draw_string(_font, Vector2(150, y), "켜짐" if bool(GameState.settings[row[1]]) else "꺼짐", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
			"size2":
				draw_string(_font, Vector2(150, y), DIFF_NAMES[clampi(int(GameState.settings[row[1]]), 0, DIFF_NAMES.size() - 1)], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
			"size":
				draw_string(_font, Vector2(150, y), SIZE_NAMES[clampi(int(GameState.settings[row[1]]), 0, SIZE_NAMES.size() - 1)], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
	draw_string(_font, Vector2(0, 22.0 + _rows.size() * 20.0 + 6), "눌러서 바꾸기" if TouchControls.active else "←→ 바꾸기 · Esc 돌아가기", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(Palette.UI_DIM, 0.7))
