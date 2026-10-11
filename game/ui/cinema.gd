class_name Cinema
extends CanvasLayer
## 연출 화면층 (docs/archive/sera/systems2.md 8절): 레터박스, 화면 색 덮기, 큰 제목 카드, 장 카드, 엔딩 크레디트.
## 대본은 Cut의 c.letterbox / c.tint / c.title_card / c.chapter_card / c.credits로 쓴다.

signal card_done

var _bars := 0.0 ## 0~1 레터박스 정도
var _bars_target := 0.0
var _tint: ColorRect
var _tint_tween: Tween
var _draw: CinemaDraw


func _ready() -> void:
	layer = 61 # 화면 페이드(60) 위: 검은 화면에서도 장 카드·크레디트가 보임, 대화창(62) 아래
	process_mode = Node.PROCESS_MODE_ALWAYS
	_tint = ColorRect.new()
	_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tint.color = Color(0, 0, 0, 0)
	add_child(_tint)
	_draw = CinemaDraw.new()
	_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_draw.owner_cinema = self
	add_child(_draw)


func _process(delta: float) -> void:
	_bars = move_toward(_bars, _bars_target, delta * 3.0)
	_draw.bars = _bars
	_draw.queue_redraw()


func letterbox(on: bool) -> void:
	_bars_target = 1.0 if on else 0.0


func tint(color: Color, time := 0.5) -> void:
	if _tint_tween:
		_tint_tween.kill()
	_tint_tween = create_tween()
	_tint_tween.tween_property(_tint, "color", color, maxf(time, 0.01))


## 화면 가운데 큰 글씨 카드. sec 동안 보였다가 사라짐
func title_card(title: String, sub := "", sec := 2.5, small := "") -> void:
	_draw.card_title = title
	_draw.card_sub = sub
	_draw.card_small = small
	_draw.card_t = 0.0
	_draw.card_len = sec
	_draw.card_on = true
	var was := _bars_target
	letterbox(true)
	await get_tree().create_timer(sec, true, false, true).timeout
	_draw.card_on = false
	if was <= 0.0:
		letterbox(false)
	card_done.emit()


## 장 카드: "2장" + 제목 (징글)
func chapter_card(n: int) -> void:
	var t: Array = ChapterFlow.title(n)
	Music.jingle("jingle_chapter")
	await title_card(String(t[1]), String(t[2]) if t.size() > 2 else "", 3.2, String(t[0]))


## 엔딩 크레디트: 줄 목록이 아래에서 위로 흐름 (점프·공격으로 빨리 감기)
func credits(lines: Array, sec := 40.0) -> void:
	_draw.credit_lines = lines
	_draw.credit_t = 0.0
	_draw.credit_len = sec
	_draw.credits_on = true
	var t := 0.0
	while t < sec:
		await get_tree().process_frame
		var spd := 4.0 if (Input.is_action_pressed("jump") or Input.is_action_pressed("attack")) else 1.0
		var d := get_process_delta_time() * spd
		t += d
		_draw.credit_t = t
	_draw.credits_on = false


class CinemaDraw extends Control:
	var owner_cinema: Cinema
	var bars := 0.0
	var card_on := false
	var card_title := ""
	var card_sub := ""
	var card_small := ""
	var card_t := 0.0
	var card_len := 2.5
	var credits_on := false
	var credit_lines: Array = []
	var credit_t := 0.0
	var credit_len := 40.0
	var _font: Font

	func _ready() -> void:
		_font = ThemeDB.fallback_font

	func _process(delta: float) -> void:
		if card_on:
			card_t += delta

	func _center(text: String, y: float, size: int, col: Color) -> void:
		var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		draw_string_outline(_font, Vector2((640 - w) * 0.5, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, Color(0, 0, 0, col.a * 0.8))
		draw_string(_font, Vector2((640 - w) * 0.5, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

	func _draw() -> void:
		if bars > 0.0:
			var h := 34.0 * bars
			draw_rect(Rect2(0, 0, 640, h), Color.BLACK)
			draw_rect(Rect2(0, 360 - h, 640, h), Color.BLACK)
		if card_on:
			var a := clampf(minf(card_t / 0.5, (card_len - card_t) / 0.6), 0.0, 1.0)
			draw_rect(Rect2(0, 130, 640, 100), Color(0.02, 0.015, 0.04, 0.55 * a))
			var lw := 220.0 * clampf(card_t / 0.8, 0.0, 1.0)
			draw_rect(Rect2(320 - lw, 140, lw * 2.0, 1), Color(Palette.GOLD, 0.7 * a))
			draw_rect(Rect2(320 - lw, 220, lw * 2.0, 1), Color(Palette.GOLD, 0.7 * a))
			if card_small != "":
				_center(card_small, 162, 12, Color(Palette.GOLD, a))
			_center(card_title, 196, 24, Color(1, 0.96, 0.9, a))
			if card_sub != "":
				_center(card_sub, 214, 12, Color(Palette.UI_DIM, a))
		if credits_on:
			draw_rect(Rect2(0, 0, 640, 360), Color(0.01, 0.01, 0.03, 0.85))
			var total := credit_lines.size() * 18.0 + 360.0
			var y0 := 360.0 - (credit_t / credit_len) * total
			for i in credit_lines.size():
				var y := y0 + i * 18.0
				if y < -20.0 or y > 380.0:
					continue
				var line := String(credit_lines[i])
				var head := line.begins_with("#")
				_center(line.trim_prefix("#").strip_edges(), y, 12, Palette.GOLD if head else Palette.UI_TEXT)
