class_name EndScreen
extends CanvasLayer
## 1장 끝 화면 (docs/chapter1.md 10절): 제목 + 기록(플레이 시간·쓰러짐·발견한 비밀·빙의 횟수) + "계속 탐험하기 / 타이틀로".

signal done(keep: bool)

const SECRETS_TOTAL := 5 ## 수호의 깃털 3 + 낡은 쪽지 2

var _root: Control
var _draw: EndDraw
var _menu: MenuList
var _opened_at := 0


func _ready() -> void:
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_draw = EndDraw.new()
	_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_draw)
	_menu = MenuList.new()
	_menu.items = ["계속 탐험하기", "타이틀로"]
	_menu.position = Vector2(270, 286)
	_menu.size = Vector2(160, 40)
	_menu.chosen.connect(_on_chosen)
	_root.add_child(_menu)
	_root.visible = false


func open() -> bool:
	var st := GameState.stats
	_draw.lines = [
		["플레이 시간", GameState.format_time(GameState.run_time)],
		["쓰러진 횟수", str(int(st.get("deaths", 0)))],
		["발견한 비밀", "%d / %d" % [int(st.get("secrets", 0)), SECRETS_TOTAL]],
		["빙의 (여우 모드)", "%d 번" % int(st.get("fox_modes", 0))],
		["퍼펙트 회피", "%d 번" % int(st.get("perfect_dodges", 0))],
	]
	_draw.t = 0.0
	_root.visible = true
	_opened_at = Time.get_ticks_msec()
	get_tree().paused = true
	Music.jingle("jingle_quest")
	var keep: bool = await done
	_root.visible = false
	get_tree().paused = false
	return keep


func _on_chosen(i: int) -> void:
	done.emit(i == 0)


func _input(event: InputEvent) -> void:
	if not _root.visible or event.is_echo() or Time.get_ticks_msec() - _opened_at < 1500:
		return
	if _menu.handle_input(event) and is_inside_tree():
		get_viewport().set_input_as_handled()


class EndDraw extends Control:
	var lines: Array = []
	var t := 0.0
	var _font: Font

	func _ready() -> void:
		_font = get_theme_default_font()

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var a := clampf(t / 1.2, 0.0, 1.0)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.02, 0.05, 0.92 * a))
		# 푸른 여우불 입자
		for i in 24:
			var x := fmod(i * 97.0 + t * (8.0 + i % 5), size.x)
			var y := size.y - fmod(i * 53.0 + t * (14.0 + i % 7) * 2.0, size.y)
			draw_rect(Rect2(x, y, 2, 2), Color(0.55, 0.85, 1.0, 0.35 * a))
		var title := "1장 끝 — 마녀학교의 여우"
		var tw := _font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
		draw_string(_font, Vector2((size.x - tw) * 0.5, 74), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.85, 0.94, 1.0, a))
		var sub := "세라와 너울의 이야기는 계속됩니다."
		var sw := _font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(_font, Vector2((size.x - sw) * 0.5, 100), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(Palette.UI_DIM, a))
		draw_rect(Rect2(200, 116, 240, 1), Color(0.55, 0.85, 1.0, 0.5 * a))
		for i in lines.size():
			var la := clampf((t - 0.8 - i * 0.25) / 0.4, 0.0, 1.0)
			var l: Array = lines[i]
			var y := 146.0 + i * 22.0
			draw_string(_font, Vector2(214, y), String(l[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(Palette.UI_DIM, la))
			var v := String(l[1])
			var vw := _font.get_string_size(v, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			draw_string(_font, Vector2(426 - vw, y), v, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(Palette.UI_TEXT, la))
		draw_string(_font, Vector2(200, 344), "플레이해 주셔서 고맙습니다.", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(Palette.UI_DIM, a * 0.8))
