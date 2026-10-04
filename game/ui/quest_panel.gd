class_name QuestPanel
extends Control
## 퀘스트창 (일시정지 → 퀘스트): 메인 / 서브 / 수업 세 칸. ←→ 칸 바꾸기, ↑↓ 넘기기, Esc·Z 돌아가기. 터치: 칸 이름을 누름.

signal closed

const TABS := ["메인", "서브", "수업"]

var tab := 0
var _scroll := 0
var _font: Font
var _t := 0.0


func _ready() -> void:
	_font = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func open() -> void:
	_scroll = 0


func handle_input(event: InputEvent) -> bool:
	if not visible:
		return false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var lp: Vector2 = (make_input_local(event) as InputEventMouseButton).position
		for i in TABS.size():
			if Rect2(60 + i * 90, 64, 80, 22).has_point(lp):
				tab = i
				_scroll = 0
				Sfx.play(&"ui_move", 0.0, 0.0)
				return true
		if Rect2(0, 316, 640, 44).has_point(lp):
			closed.emit()
			return true
		return true
	if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		tab = (tab + TABS.size() - 1) % TABS.size()
		_scroll = 0
		Sfx.play(&"ui_move", 0.0, 0.0)
		return true
	if event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		tab = (tab + 1) % TABS.size()
		_scroll = 0
		Sfx.play(&"ui_move", 0.0, 0.0)
		return true
	if event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		_scroll += 1
		return true
	if event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		_scroll = maxi(_scroll - 1, 0)
		return true
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept") or event.is_action_pressed("jump") or event.is_action_pressed("attack"):
		Sfx.play(&"ui_ok", 0.0, 0.0)
		closed.emit()
		return true
	return false


func _process(delta: float) -> void:
	_t += delta
	if visible:
		queue_redraw()


func _lines() -> Array:
	var out: Array = [] ## [문자열, 색, 크기 12]
	match tab:
		0:
			var cur := Objectives.current()
			out.append(["지금 할 일", Palette.UI_DIM])
			out.append(["▶ " + (cur if cur != "" else "자유롭게 둘러보자"), Palette.UI_TEXT])
			out.append(["", Palette.UI_DIM])
			out.append(["지나온 길", Palette.UI_DIM])
			var done: Array = Objectives.done_list()
			for i in range(done.size() - 1, -1, -1):
				out.append(["✓ " + String(done[i]), Color(Palette.UI_DIM, 0.8)])
		1, 2:
			var kind := "side" if tab == 1 else "class"
			var act: Array = Quests.listed(1, kind)
			var fin: Array = Quests.listed(2, kind)
			if act.is_empty() and fin.is_empty():
				out.append(["아직 없다." if tab == 1 else "중앙 홀의 수업 게시판에서 수업을 신청하자.", Palette.UI_DIM])
			for q in act:
				var id: String = q[0]
				var d: Dictionary = q[1]
				out.append(["◆ " + String(d.get("title", id)) + "   — " + Characters.display_name(String(d.get("giver", ""))), Palette.GOLD])
				var steps: Array = d.get("steps", [])
				var n := Quests.step(id)
				for i in steps.size():
					if i < n:
						out.append(["   ✓ " + String(steps[i]), Color(Palette.UI_DIM, 0.7)])
					elif i == n:
						out.append(["   ▶ " + String(steps[i]), Palette.UI_TEXT])
				out.append(["", Palette.UI_DIM])
			for q2 in fin:
				var d2: Dictionary = q2[1]
				out.append(["✓ " + String(d2.get("title", q2[0])), Color(Palette.UI_DIM, 0.8)])
	return out


func _draw() -> void:
	draw_string(_font, Vector2(60, 50), "퀘스트", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Palette.GOLD)
	for i in TABS.size():
		var r := Rect2(60 + i * 90, 64, 80, 22)
		var on := i == tab
		draw_rect(r, Color(1, 1, 1, 0.08) if on else Color(1, 1, 1, 0.02))
		draw_rect(r, Color(Palette.GOLD, 0.8) if on else Color(Palette.UI_DIM, 0.4), false, 1.0)
		var tw := _font.get_string_size(TABS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(_font, r.position + Vector2((r.size.x - tw) * 0.5, 16), TABS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_TEXT if on else Palette.UI_DIM)
	var lines := _lines()
	var max_rows := 13
	_scroll = clampi(_scroll, 0, maxi(lines.size() - max_rows, 0))
	for i in mini(max_rows, lines.size() - _scroll):
		var l: Array = lines[i + _scroll]
		draw_string(_font, Vector2(60, 112 + i * 16), String(l[0]), HORIZONTAL_ALIGNMENT_LEFT, 520, 12, l[1])
	if lines.size() > max_rows:
		draw_string(_font, Vector2(560, 330), "↑↓", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_DIM)
	var hint := "칸을 눌러 바꾸기 · 아래를 눌러 돌아가기" if TouchControls.active else "←→ 칸 · ↑↓ 넘기기 · Z 돌아가기"
	draw_string(_font, Vector2(60, 340), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_DIM)
