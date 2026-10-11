class_name ETutEnd
extends Control
## 튜토리얼 끝 화면: 어두운 막 위에 "돌파" 제목 · 기록(걸린 시간·쓰러짐·맞음·최고 연타) · 버튼 셋.
## 기록 줄은 하나씩 차례로 나타난다. 버튼은 키보드(↑↓·Enter/Space/Z)와 터치 모두. 고른 것은 chosen 신호로 알린다.

signal chosen(what: String) ## "retry" · "arena" · "title"

const PALE := EVfx.PALE
const VIOLET := EVfx.VIOLET
const MAGENTA := EVfx.MAGENTA
const INK := EVfx.INK
const EDGE := EVfx.EDGE

var stats: Array = [] ## [[이름, 값], ...]
var _t := 0.0
var _font: Font
var _buttons: Array[Button] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_font = get_theme_default_font()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	for spec: Array in [["다시 하기", "retry"], ["훈련장으로", "arena"], ["타이틀로", "title"]]:
		var b := Button.new()
		b.text = String(spec[0])
		b.custom_minimum_size = Vector2(150, 26)
		b.focus_mode = Control.FOCUS_ALL
		b.add_theme_font_size_override("font_size", 13)
		b.add_theme_stylebox_override("normal", _style(Color(INK, 0.85), Color(VIOLET, 0.5)))
		b.add_theme_stylebox_override("hover", _style(Color(EVfx.PLUM, 0.9), Color(MAGENTA, 0.9)))
		b.add_theme_stylebox_override("focus", _style(Color(EVfx.PLUM, 0.9), Color(EDGE, 1.0)))
		b.add_theme_stylebox_override("pressed", _style(Color(MAGENTA, 0.6), Color(EDGE, 1.0)))
		b.add_theme_color_override("font_color", PALE)
		b.add_theme_color_override("font_focus_color", Color.WHITE)
		b.add_theme_color_override("font_hover_color", Color.WHITE)
		var what := String(spec[1])
		b.pressed.connect(func() -> void:
			Sfx.play(&"ui_ok", -4.0)
			chosen.emit(what))
		b.focus_entered.connect(func() -> void: Sfx.play(&"ui_move", -10.0))
		box.add_child(b)
		_buttons.append(b)
	box.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_interval(1.6)
	tw.tween_property(box, "modulate:a", 1.0, 0.4)
	tw.tween_callback(func() -> void: _buttons[0].grab_focus())
	resized.connect(func() -> void: box.position = Vector2(size.x * 0.5 - 75.0, size.y * 0.62))
	box.position = Vector2(get_viewport_rect().size.x * 0.5 - 75.0, get_viewport_rect().size.y * 0.62)


func _style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(4)
	return s


func _unhandled_input(event: InputEvent) -> void:
	# Z·X로도 고르기 (게임 키 그대로)
	if event.is_action_pressed("es_jump") or event.is_action_pressed("es_attack"):
		for b in _buttons:
			if b.has_focus():
				b.pressed.emit()
				get_viewport().set_input_as_handled()
				return


func _process(delta: float) -> void:
	_t += delta
	var vs := get_viewport_rect().size
	if size != vs:
		size = vs
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.0, 0.04, minf(_t / 0.6, 1.0) * 0.72))
	var c := Vector2(size.x * 0.5, size.y * 0.22)
	var inn := clampf(_t / 0.6, 0.0, 1.0)
	var e := 1.0 - pow(1.0 - inn, 3.0)
	var title := "종언의 문턱 — 돌파"
	var fs := 26
	var tw := _font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var sc := 1.15 - 0.15 * e
	draw_set_transform(c, 0.0, Vector2(sc, sc))
	draw_string_outline(_font, Vector2(-tw * 0.5, 0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, Color(INK, inn))
	draw_string(_font, Vector2(-tw * 0.5, 0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(EDGE, inn))
	draw_set_transform(Vector2.ZERO)
	var lw := (tw * 0.5 + 60.0) * e
	draw_line(c + Vector2(-lw, 12), c + Vector2(lw, 12), Color(MAGENTA, 0.7 * inn), 1.0)
	# 기록: 한 줄씩
	for i in stats.size():
		var k := clampf((_t - 0.6 - 0.18 * float(i)) / 0.25, 0.0, 1.0)
		if k <= 0.0:
			continue
		var y := c.y + 36.0 + 18.0 * float(i) + 6.0 * (1.0 - k)
		var name := String(stats[i][0])
		var val := String(stats[i][1])
		var vw := _font.get_string_size(val, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		_text(Vector2(c.x - 110.0, y), name, 12, Color(VIOLET, k))
		_text(Vector2(c.x + 110.0 - vw, y), val, 13, Color(PALE.lerp(Color.WHITE, 0.4), k))
		draw_line(Vector2(c.x - 110.0, y + 4), Vector2(c.x + 110.0, y + 4), Color(VIOLET, 0.15 * k), 1.0)


func _text(p: Vector2, s: String, fs: int, col: Color) -> void:
	draw_string_outline(_font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color(0, 0, 0, 0.7 * col.a))
	draw_string(_font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
