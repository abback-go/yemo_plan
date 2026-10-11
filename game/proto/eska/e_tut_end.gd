class_name ETutEnd
extends Control
## 튜토리얼 끝 화면: 어두운 막 위에 "돌파" 제목 · 익힌 마녀의 기술(마름모 줄) · 기록 두 줄 칸(걸린 시간·쓰러짐·맞음·최고 연타·딱 맞춤·틈 달이기) · 버튼 셋.
## 기술·기록은 하나씩 차례로 나타난다. 버튼은 키보드(↑↓·Enter/Space/Z)와 터치 모두. 고른 것은 chosen 신호로 알린다.

signal chosen(what: String) ## "retry" · "arena" · "title"

const PALE := EVfx.PALE
const VIOLET := EVfx.VIOLET
const MAGENTA := EVfx.MAGENTA
const INK := EVfx.INK
const EDGE := EVfx.EDGE

const COL_W := 136.0 ## 기록 한 칸(이름 ~ 값) 너비 — 두 칸이 나란히
const COL_GAP := 24.0
const ROW_H := 17.0

var stats: Array = [] ## [[이름, 값], ...] — 왼쪽 칸부터 위→아래, 반씩 나눠 두 칸
var learned: Array = [] ## 익힌 기술 이름 (제목 아래 한 줄)
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
	var c := Vector2(size.x * 0.5, size.y * 0.19)
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
	# 익힌 기술: 제목 아래 한 줄, 마름모로 이어짐
	var lw_all := 0.0
	for nm: String in learned:
		lw_all += _font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 22.0
	var lx := c.x - lw_all * 0.5
	for i in learned.size():
		var k := clampf((_t - 0.5 - 0.12 * float(i)) / 0.25, 0.0, 1.0)
		var nm := String(learned[i])
		var nw := _font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		if k > 0.0:
			var d := Vector2(lx + 5.0, c.y + 29.0)
			draw_colored_polygon(PackedVector2Array([d + Vector2(0, -3.5), d + Vector2(3.5, 0), d + Vector2(0, 3.5), d + Vector2(-3.5, 0)]), Color(MAGENTA.lerp(EDGE, 0.4), k))
			_text(Vector2(lx + 14.0, c.y + 33.0 + 4.0 * (1.0 - k)), nm, 11, Color(PALE, k))
		lx += nw + 22.0
	# 기록: 두 칸, 한 줄씩
	var half := ceili(stats.size() / 2.0)
	for i in stats.size():
		var k := clampf((_t - 0.9 - 0.15 * float(i)) / 0.25, 0.0, 1.0)
		if k <= 0.0:
			continue
		var col := i / half
		var row := i % half
		var x0 := c.x - COL_W - COL_GAP * 0.5 + float(col) * (COL_W + COL_GAP)
		var y := c.y + 58.0 + ROW_H * float(row) + 6.0 * (1.0 - k)
		var name := String(stats[i][0])
		var val := String(stats[i][1])
		var vw := _font.get_string_size(val, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		_text(Vector2(x0, y), name, 12, Color(VIOLET, k))
		_text(Vector2(x0 + COL_W - vw, y), val, 13, Color(PALE.lerp(Color.WHITE, 0.4), k))
		draw_line(Vector2(x0, y + 4), Vector2(x0 + COL_W, y + 4), Color(VIOLET, 0.15 * k), 1.0)


func _text(p: Vector2, s: String, fs: int, col: Color) -> void:
	draw_string_outline(_font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color(0, 0, 0, 0.7 * col.a))
	draw_string(_font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
