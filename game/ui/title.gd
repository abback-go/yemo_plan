extends Control
## 타이틀 화면. 브라우저는 첫 입력 전에는 소리를 막으므로 여기서 입력을 한 번 받는다.

const BG := preload("res://levels/background.gd")

var _t := 0.0
var _sera: PlayerVisual
var _font: Font
var _started := false
var _text: Control


func _ready() -> void:
	Fx.reset()
	get_tree().paused = false
	_font = get_theme_default_font()
	var sky := BG.SkyDraw.new()
	add_child(sky)
	var school := BG.LayerDraw.new()
	school.kind = BG.LayerDraw.Kind.SCHOOL
	school.position = Vector2(-200, 0)
	add_child(school)
	var forest := BG.LayerDraw.new()
	forest.kind = BG.LayerDraw.Kind.FOREST_NEAR
	forest.position = Vector2(0, 10)
	add_child(forest)

	var ground := ColorRect.new()
	ground.color = Palette.GROUND
	ground.position = Vector2(0, 318)
	ground.size = Vector2(640, 42)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ground)
	var ground_top := ColorRect.new()
	ground_top.color = Palette.GROUND_TOP
	ground_top.position = Vector2(0, 318)
	ground_top.size = Vector2(640, 2)
	ground_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ground_top)

	_sera = PlayerVisual.new()
	_sera.position = Vector2(150, 318)
	_sera.scale = Vector2(3, 3)
	add_child(_sera)

	# 글자는 배경 그림보다 위에 그려야 하므로 마지막 자식으로
	_text = TitleText.new()
	_text.title = self
	_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_text)


func _process(delta: float) -> void:
	_t += delta
	_sera.overload_ratio = 0.3 + 0.3 * sin(_t * 0.8)
	_sera.update_pose(delta)
	_text.queue_redraw()


func draw_text_on(c: CanvasItem) -> void:
	# 글자 뒤 반투명 판 (배경의 불 켜진 창이 글자를 방해하지 않게)
	c.draw_rect(Rect2(258, 40, 300, 268), Color(0.03, 0.02, 0.06, 0.62))
	c.draw_rect(Rect2(258, 40, 2, 268), Color(Palette.FIRE_OUT, 0.6))
	# 제목
	c.draw_string(_font, Vector2(270, 92), "YEMO", HORIZONTAL_ALIGNMENT_LEFT, -1, 48, Palette.FIRE_HOT)
	c.draw_string(_font, Vector2(272, 116), "폐급 마녀 세라 · 조작·전투 프로토타입 v0.2", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_TEXT)
	# 조작법
	var lines := [
		"←→  이동          Z  점프 (길게 = 높이)",
		"X   화염탄 (연타 3타)   C  대시",
		"A   불기둥          S  화염 폭풍",
		"Esc 일시정지        F1 디버그 표시",
		"패드: A 점프 · X 공격 · B 대시 · LB/RB 스킬",
	]
	for i in lines.size():
		c.draw_string(_font, Vector2(272, 150 + i * 16), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_DIM)
	c.draw_string(_font, Vector2(272, 238), "스킬을 연달아 쓰면 폭주 게이지가 찹니다.", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.FIRE_MID)
	c.draw_string(_font, Vector2(272, 254), "가득 차면 강제 폭발 — 적도 나도 다칩니다.", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.FIRE_MID)
	if fmod(_t, 1.0) < 0.65:
		c.draw_string(_font, Vector2(272, 296), "아무 키나 눌러 시작", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.GOLD)


func _input(event: InputEvent) -> void:
	if _started or _t < 0.3:
		return
	var pressed: bool = (event is InputEventKey and event.pressed and not event.echo) \
		or (event is InputEventJoypadButton and event.pressed) \
		or (event is InputEventMouseButton and event.pressed)
	if pressed:
		_started = true
		Sfx.play(&"ui_ok", 0.0, 0.0)
		GameState.new_run()
		GameState.start_stage()


class TitleText extends Control:
	var title: Node

	func _draw() -> void:
		title.draw_text_on(self)
