extends Node
## 손맛 공통 (자동 로드 "Feel"): 입력 등록 · 히트스톱 · 화면 흔들림 · 글꼴.
## 히트스톱은 Engine.time_scale을 잠깐 낮췄다가 실제 시간(ms)으로 되돌린다 — 에스카 fx.gd와 같은 방식.

const HITSTOP_SCALE := 0.03
const FONT_PATH := "res://fonts/Galmuri11.woff2"
const FONT_SIZE := 12

var camera: Camera2D
var font: Font
var _hitstop_until := 0
var _shake_amp := 0.0
var _shake_until := 0
var _shake_len := 1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_add_action("move_left", [KEY_LEFT, KEY_A], [JOY_BUTTON_DPAD_LEFT])
	_add_action("move_right", [KEY_RIGHT, KEY_D], [JOY_BUTTON_DPAD_RIGHT])
	_add_action("jump", [KEY_Z, KEY_SPACE], [JOY_BUTTON_A])
	_add_action("attack", [KEY_X, KEY_J], [JOY_BUTTON_X])
	_add_action("reset", [KEY_R], [JOY_BUTTON_BACK])
	_add_action("toggle_info", [KEY_TAB, KEY_F1], [JOY_BUTTON_START])
	_load_font()


func _add_action(action: StringName, keys: Array, buttons: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
	for b in buttons:
		var jb := InputEventJoypadButton.new()
		jb.button_index = b
		InputMap.action_add_event(action, jb)


## 픽셀 글꼴(갈무리11)은 흐리지 않게 그린다
func _load_font() -> void:
	var f := load(FONT_PATH) as FontFile
	if f == null:
		font = ThemeDB.fallback_font
		return
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.hinting = TextServer.HINTING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font = f


func now_ms() -> int:
	return Time.get_ticks_msec()


func hitstop(sec: float) -> void:
	if sec <= 0.0:
		return
	var until := now_ms() + int(sec * 1000.0)
	if until <= _hitstop_until:
		return
	_hitstop_until = until
	Engine.time_scale = HITSTOP_SCALE


## 지금 흔들림보다 약하면 무시한다 (센 흔들림을 덮어쓰지 않게)
func shake(amp: float, sec: float) -> void:
	if amp < _current_shake():
		return
	_shake_amp = amp
	_shake_len = maxi(1, int(sec * 1000.0))
	_shake_until = now_ms() + _shake_len


func _current_shake() -> float:
	var left := _shake_until - now_ms()
	if left <= 0:
		return 0.0
	return _shake_amp * float(left) / float(_shake_len)


func _process(_delta: float) -> void:
	if _hitstop_until > 0 and now_ms() >= _hitstop_until:
		_hitstop_until = 0
		Engine.time_scale = 1.0
	if camera != null:
		var a := _current_shake()
		if a > 0.0:
			camera.offset = Vector2(roundf(randf_range(-a, a)), roundf(randf_range(-a, a)))
		else:
			camera.offset = Vector2.ZERO
