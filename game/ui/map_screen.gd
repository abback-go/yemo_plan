class_name MapScreen
extends CanvasLayer
## 지도 (docs/chapter1.md 4.3절): 방문한 방을 칸 격자로 그린다. 현재 방은 깜빡이고 세라 위치 점, 기록 지점은 촛불 표시.

var _root: Control
var _draw: MapDraw
var _open := false
var _opened_at := 0


func _ready() -> void:
	layer = 36
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_draw = MapDraw.new()
	_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_draw)
	_root.visible = false


func is_open() -> bool:
	return _open


func open() -> void:
	if _open:
		return
	_open = true
	_opened_at = Time.get_ticks_msec()
	_draw.refresh()
	_root.visible = true
	get_tree().paused = true
	Sfx.play(&"ui_move", 0.0, 0.0)


func close() -> void:
	_open = false
	_root.visible = false
	get_tree().paused = false


func _input(event: InputEvent) -> void:
	if not _open or event.is_echo() or Time.get_ticks_msec() - _opened_at < 150:
		return
	if event.is_action_pressed("map") or event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel") \
			or event.is_action_pressed("attack") or event.is_action_pressed("dash"):
		get_viewport().set_input_as_handled()
		close()


class MapDraw extends Control:
	var _rooms: Array = []
	var _area := "school"
	var _t := 0.0
	var _font: Font
	var _cur := ""
	var _ppos := Vector2(0.5, 0.5)

	func _ready() -> void:
		_font = ThemeDB.fallback_font

	func refresh() -> void:
		_rooms.clear()
		_cur = GameState.room
		var cd := RoomIndex.data(_cur)
		_area = cd.area if cd else "school"
		var w := World.get_world()
		if w and w.room:
			_ppos = (w.player.global_position / w.room.size_px).clamp(Vector2.ZERO, Vector2.ONE)
		for id in RoomIndex.ROOMS:
			var d := RoomIndex.data(id)
			if d and d.area == _area:
				_rooms.append(d)

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(0, 0, 640, 360), Color(0.02, 0.015, 0.04, 0.94))
		var title := "신계" if _area == "shingye" else "마녀학교"
		draw_string(_font, Vector2(24, 30), "지도 — " + title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.GOLD)
		draw_string(_font, Vector2(24, 344), "Tab 닫기", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_DIM)
		# 격자 범위
		var mn := Vector2i(999, 999)
		var mx := Vector2i(-999, -999)
		for d in _rooms:
			mn = Vector2i(mini(mn.x, d.cell.x), mini(mn.y, d.cell.y))
			mx = Vector2i(maxi(mx.x, d.cell.x + d.cells.x), maxi(mx.y, d.cell.y + d.cells.y))
		if _rooms.is_empty():
			return
		var gw := float(mx.x - mn.x)
		var gh := float(mx.y - mn.y)
		var cs := minf(560.0 / gw, 270.0 / gh)
		cs = minf(cs, 70.0)
		var origin := Vector2(320 - gw * cs * 0.5, 190 - gh * cs * 0.5)
		for d in _rooms:
			var visited: bool = GameState.visited.has(d.id)
			var r := Rect2(origin + Vector2(d.cell - mn) * cs + Vector2(2, 2), Vector2(d.cells) * cs - Vector2(4, 4))
			if not visited:
				continue
			var cur: bool = d.id == _cur
			var fill := Color("#2a2440") if not cur else Color("#4a3a6a").lerp(Color("#6a5a9a"), 0.5 + 0.5 * sin(_t * 4.0))
			draw_rect(r, fill)
			draw_rect(r, Color("#8a80b0"), false, 1.0)
			var has_save := false
			for e in d.entities:
				if String(e.get("t", "")) == "save":
					has_save = true
			if has_save:
				draw_circle(r.position + Vector2(r.size.x - 7, 7), 3.0, Color(1.0, 0.8, 0.45))
			if cs >= 36.0:
				var short: String = d.title.split("· ")[-1]
				var name_w := _font.get_string_size(short, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
				if name_w < r.size.x - 4:
					draw_string(_font, r.position + Vector2((r.size.x - name_w) * 0.5, r.size.y * 0.5 + 5), short, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_TEXT if cur else Palette.UI_DIM)
			if cur:
				var pp := r.position + _ppos * r.size
				draw_circle(pp, 3.0 + sin(_t * 6.0), Color(1.0, 0.45, 0.35))
		# 아래쪽: 현재 방 이름
		var cd := RoomIndex.data(_cur)
		if cd:
			draw_string(_font, Vector2(24, 50), "현재: " + cd.title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_TEXT)
