class_name WarpMenu
extends CanvasLayer
## 전이진 목적지 고르기 (게임을 멈춤). ↑↓ 고르기, Z 이동, Esc 닫기. 터치: 목적지를 누름.

var _root: Control
var _menu: MenuList
var _points: Array = []
var _here := ""
var _open := false
var _opened_at := 0
var _draw: WarpDraw


func _ready() -> void:
	layer = 34
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_draw = WarpDraw.new()
	_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_draw)
	_menu = MenuList.new()
	_menu.position = Vector2(220, 140)
	_menu.size = Vector2(240, 120)
	_menu.line_height = 22.0
	_menu.chosen.connect(_on_chosen)
	_root.add_child(_menu)
	_root.visible = false


func is_open() -> bool:
	return _open


func open(here_area: String) -> void:
	_here = here_area
	_points = WarpDB.unlocked()
	var items: Array[String] = []
	for p in _points:
		items.append(String(p[3]) + ("  (여기)" if String(p[0]) == _here else ""))
	items.append("닫기")
	_menu.items = items
	_menu.selected = 0
	_root.visible = true
	_open = true
	_opened_at = Time.get_ticks_msec()
	get_tree().paused = true
	Sfx.play(&"menu_open", -2.0, 0.0)


func close() -> void:
	_open = false
	_root.visible = false
	get_tree().paused = false


func _input(event: InputEvent) -> void:
	if not _open or event.is_echo() or Time.get_ticks_msec() - _opened_at < 200:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()
		return
	if _menu.handle_input(event) and is_inside_tree():
		get_viewport().set_input_as_handled()


func _on_chosen(i: int) -> void:
	if i >= _points.size():
		close()
		return
	var p: Array = _points[i]
	if String(p[0]) == _here:
		Sfx.play(&"block", -4.0, 0.0)
		return
	close()
	var w := World.get_world()
	if w == null:
		return
	Sfx.play(&"warp", 0.0, 0.0)
	Fx.flash(Color(0.7, 0.6, 1.0, 0.6), 0.3)
	Fx.ring(w.player.center(), 4.0, 60.0, Color(0.75, 0.6, 1.0), 0.5, 3.0)
	w.go(String(p[1]), String(p[2]))


class WarpDraw extends Control:
	var _font: Font
	var _t := 0.0

	func _ready() -> void:
		_font = ThemeDB.fallback_font

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(0, 0, 640, 360), Color(0.02, 0.015, 0.05, 0.8))
		var c := Vector2(320, 180)
		for i in 3:
			draw_arc(c, 120.0 + i * 18.0, _t * (0.3 + i * 0.1), _t * (0.3 + i * 0.1) + TAU * 0.8, 48, Color(0.7, 0.55, 1.0, 0.25 - i * 0.06), 2.0)
		draw_string(_font, Vector2(220, 118), "전이진 — 어디로 갈까?", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.GOLD)
