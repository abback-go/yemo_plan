## btn.gd — 붉은 테두리 둥근 버튼 (HTML 판 .btn). 마우스·터치 공통.
## 휴대폰처럼 화면이 작으면 누르는 영역을 실제 화면 44px 이상으로 넓힌다(보이는 크기는 그대로).
class_name Btn
extends Control

signal pressed

var lbl: Label
var hover := false
var down := false
var disabled := false
var pulse := false
var style_kind := "main"   # main | small | choice
var _t := 0.0


func setup(text: String, size: int, font := "serif_bold") -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	lbl = UI.label(text, size, Color("#f7e9eb"), font, HORIZONTAL_ALIGNMENT_CENTER)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(lbl)
	mouse_entered.connect(func(): hover = true; queue_redraw())
	mouse_exited.connect(func(): hover = false; down = false; queue_redraw())
	fit()


## 글자에 맞춰 크기(여백 포함)
func fit(pad := Vector2(64, 16)) -> void:
	var s := lbl.get_combined_minimum_size()
	size = s + pad * 2.0
	lbl.position = Vector2.ZERO
	lbl.size = size
	pivot_offset = size / 2.0


func set_text(t: String) -> void:
	lbl.text = t


func _process(delta: float) -> void:
	if pulse:
		_t += delta
		queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var rad := minf(size.y / 2.0, 40.0)
	var a := 0.45 if disabled else 1.0
	var top := Color("#6a2230") if hover and not disabled else Color("#4a1820")
	var bot := Color("#2d0c11") if hover and not disabled else Color("#1d080b")
	if style_kind == "small":
		top = Color("#5a2730") if hover else Color("#3a1d22")
		bot = Color("#2a0f14") if hover else Color("#1a0b0e")
	var glow := 0.5
	if pulse and not disabled:
		glow = 0.55 + 0.45 * (0.5 + 0.5 * sin(_t * TAU / 1.2))
	if hover and not disabled:
		glow = 0.9
	# 빛
	var sb := UI.box(Color(0, 0, 0, 0), Color(1, 0.16, 0.24, 0.35 * glow * a), int(rad) + 8, 8)
	sb.draw_center = false
	draw_style_box(sb, r.grow(6))
	# 몸통(세로 그라데이션 흉내: 두 겹)
	var body := UI.box(Color(bot.r, bot.g, bot.b, 0.96 * a), Color(UI.RED.r, UI.RED.g, UI.RED.b, a) if style_kind != "small" else Color(0.55, 0.2, 0.25, a), int(rad), 2)
	draw_style_box(body, r)
	var upper := UI.box(Color(top.r, top.g, top.b, 0.7 * a), Color.TRANSPARENT, int(rad))
	upper.corner_radius_bottom_left = 0
	upper.corner_radius_bottom_right = 0
	draw_style_box(upper, Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, r.size.y * 0.5 - 2)))
	lbl.modulate.a = a


func _has_point(p: Vector2) -> bool:
	var need := 44.0 / maxf(0.05, FX.css_scale)
	var pad := Vector2(maxf(0.0, (need - size.x) / 2.0), maxf(0.0, (need - size.y) / 2.0))
	return Rect2(-pad, size + pad * 2.0).has_point(p)


func _gui_input(e: InputEvent) -> void:
	if disabled:
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			down = true
			accept_event()
		elif down:
			down = false
			accept_event()
			if _has_point(e.position):
				pressed.emit()
