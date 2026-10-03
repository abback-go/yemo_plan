class_name Notice
extends CanvasLayer
## 알림 모음: 짧은 토스트, 지역 이름, 물건 획득, 마법 습득(확인을 누를 때까지 멈춤), 적 이름표.

signal confirmed

var _draw: NoticeDraw
var _waiting := false
var _opened_at := 0


func _ready() -> void:
	layer = 38
	process_mode = Node.PROCESS_MODE_ALWAYS
	_draw = NoticeDraw.new()
	_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_draw)


func toast(text: String, time := 2.4) -> void:
	_draw.toast = text
	_draw.toast_t = time


func area_name(text: String) -> void:
	_draw.area = text
	_draw.area_t = 3.0


func item_get(title: String, desc: String, icon := "") -> void:
	_draw.item = [title, desc, icon]
	_draw.item_t = 3.2
	Sfx.play(&"pickup", 0.0, 0.0)


func enemy_card(name_text: String, sub: String, boss := false) -> void:
	_draw.card = [name_text, sub, boss]
	_draw.card_t = 2.6


## 마법 습득: 게임을 멈추고 큰 연출 → 확인을 누르면 계속
func ability_get(title: String, keys: String, desc: String) -> void:
	_draw.ability = [title, keys, desc]
	_draw.ability_t = 0.0
	_waiting = true
	_opened_at = Time.get_ticks_msec()
	get_tree().paused = true
	Music.jingle("jingle_ability")
	Sfx.play(&"reveal", 0.0, 0.0)
	await confirmed
	_draw.ability = []
	get_tree().paused = false


## 터치: 화면 탭으로 확인할 수 있는가
func accepts_tap() -> bool:
	return _waiting


func _input(event: InputEvent) -> void:
	if not _waiting or event.is_echo():
		return
	if Time.get_ticks_msec() - _opened_at < 900:
		return
	if event.is_action_pressed("jump") or event.is_action_pressed("attack") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_waiting = false
		confirmed.emit()


class NoticeDraw extends Control:
	var toast := ""
	var toast_t := 0.0
	var area := ""
	var area_t := 0.0
	var item: Array = []
	var item_t := 0.0
	var card: Array = []
	var card_t := 0.0
	var ability: Array = []
	var ability_t := 0.0
	var _font: Font
	var _t := 0.0

	func _ready() -> void:
		_font = ThemeDB.fallback_font

	func _process(delta: float) -> void:
		# 메뉴·지도·게시판으로 멈춘 동안엔 감추고 시간도 멈춤 (마법 습득 창은 예외 — 그게 멈춘 이유)
		var n := get_parent() as Notice
		var hold := get_tree().paused and n != null and not n._waiting
		visible = not hold
		if hold:
			return
		_t += delta
		toast_t = maxf(toast_t - delta, 0.0)
		area_t = maxf(area_t - delta, 0.0)
		item_t = maxf(item_t - delta, 0.0)
		card_t = maxf(card_t - delta, 0.0)
		ability_t += delta
		queue_redraw()

	func _fade(t: float, total: float) -> float:
		return clampf(minf((total - t) * 4.0, t * 2.5), 0.0, 1.0)

	func _center_text(y: float, text: String, size: int, col: Color) -> void:
		var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		draw_string(_font, Vector2(320 - w * 0.5, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

	func _draw() -> void:
		if toast_t > 0.0:
			var a := clampf(toast_t * 3.0, 0.0, 1.0)
			var w := _font.get_string_size(toast, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 24
			var r := Rect2(320 - w * 0.5, 44, w, 20)
			draw_rect(r, Color(0.03, 0.02, 0.06, 0.85 * a))
			draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), Color(Palette.GOLD, 0.7 * a))
			_center_text(58, toast, 12, Color(Palette.UI_TEXT, a))
		if area_t > 0.0:
			var a2 := clampf(minf(area_t, 3.0 - area_t) * 2.0, 0.0, 1.0)
			var w2 := _font.get_string_size(area, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
			draw_rect(Rect2(320 - w2 * 0.5 - 40, 92, w2 + 80, 1), Color(Palette.GOLD, 0.6 * a2))
			draw_rect(Rect2(320 - w2 * 0.5 - 40, 124, w2 + 80, 1), Color(Palette.GOLD, 0.6 * a2))
			_center_text(116, area, 24, Color(Palette.UI_TEXT, a2))
		if item_t > 0.0 and item.size() == 3:
			var a3 := clampf(minf(item_t, 3.2 - item_t) * 4.0, 0.0, 1.0)
			var r3 := Rect2(170, 70, 300, 48)
			draw_rect(r3, Color(0.03, 0.02, 0.06, 0.92 * a3))
			draw_rect(Rect2(r3.position, Vector2(r3.size.x, 2)), Color(1.0, 0.85, 0.5, a3))
			draw_circle(r3.position + Vector2(24, 24), 12, Color(1.0, 0.85, 0.5, 0.25 * a3))
			draw_circle(r3.position + Vector2(24, 24), 5, Color(1.0, 0.95, 0.8, a3))
			draw_string(_font, r3.position + Vector2(44, 20), String(item[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(Palette.GOLD, a3))
			draw_string(_font, r3.position + Vector2(44, 38), String(item[1]), HORIZONTAL_ALIGNMENT_LEFT, 250, 12, Color(Palette.UI_TEXT, a3))
		if card_t > 0.0 and card.size() == 3:
			var a4 := clampf(minf(card_t, 2.6 - card_t) * 4.0, 0.0, 1.0)
			var slide := (1.0 - a4) * 30.0
			var x := 24.0 - slide
			var y := 228.0 if not bool(card[2]) else 150.0
			draw_rect(Rect2(x - 8, y - 18, 220, 40), Color(0.03, 0.02, 0.06, 0.75 * a4))
			draw_rect(Rect2(x - 8, y - 18, 3, 40), Color(Palette.DANGER, a4))
			draw_string(_font, Vector2(x, y), String(card[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(Palette.UI_TEXT, a4))
			draw_string(_font, Vector2(x, y + 15), String(card[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(Palette.UI_DIM, a4))
		if ability.size() == 3:
			var a5 := clampf(ability_t * 2.5, 0.0, 1.0)
			draw_rect(Rect2(0, 0, 640, 360), Color(0.02, 0.01, 0.05, 0.6 * a5))
			# 마법진
			var c := Vector2(320, 130)
			for i in 3:
				draw_arc(c, 40.0 + i * 14.0 + sin(_t * 2.0 + i) * 2.0, 0, TAU, 40, Color(1.0, 0.8, 0.45, (0.5 - i * 0.12) * a5), 1.0)
			for i in 8:
				var ang := _t * 0.5 + TAU * i / 8.0
				draw_line(c + Vector2(cos(ang), sin(ang)) * 40, c + Vector2(cos(ang + 2.4), sin(ang + 2.4)) * 40, Color(1.0, 0.8, 0.45, 0.35 * a5), 1.0)
			draw_circle(c, 14, Color(1.0, 0.9, 0.6, 0.6 * a5))
			_center_text(208, "새 마법을 익혔다", 12, Color(Palette.UI_DIM, a5))
			_center_text(234, String(ability[0]), 24, Color(Palette.GOLD, a5))
			_center_text(258, String(ability[1]), 12, Color(Palette.UI_TEXT, a5))
			var lines := String(ability[2]).split("\n")
			for i in lines.size():
				_center_text(282 + i * 16, lines[i], 12, Color(Palette.UI_TEXT, 0.85 * a5))
			if ability_t > 0.9 and fmod(_t, 1.0) < 0.7:
				_center_text(340, "Z 계속", 12, Color(Palette.UI_DIM, a5))
