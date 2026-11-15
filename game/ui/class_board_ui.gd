class_name ClassBoardUI
extends CanvasLayer
## 마법 배우기 창 (docs/archive/sera/magic.md 4절): 수업 게시판에서 연다. 왼쪽 수업 목록(7종 — 1장 셋은 습득 표시),
## 오른쪽 설명·수업 과정·조건. "수업 신청" → 수업 퀘스트(kind = class) 시작 → 대본 cls_<마법>_begin.
## 수업 정의는 story/data_sys.gd 의 QUESTS (spell, unlock, unlock_text, teacher, steps).

var _root: Control
var _draw: BoardDraw
var _open := false
var _opened_at := 0
var sel := 0


func _ready() -> void:
	layer = 34
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_draw = BoardDraw.new()
	_draw.ui = self
	_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_draw)
	_root.visible = false


## 수업 판정은 Quests(core/quests.gd)에 있다. 아래는 예전 이름 (class_board 개체·시험 실행기가 부름)
static func class_of(spell: String) -> String:
	return Quests.class_of(spell)


## 0 습득 · 1 진행 중 · 2 신청 가능 · 3 잠김
static func status(spell: String) -> int:
	return Quests.class_status(spell)


static func has_new() -> bool:
	return Quests.has_new_class()


static func any_active() -> String:
	return Quests.active_class()


func open() -> void:
	sel = 0
	for i in Spells.ORDER.size():
		if status(Spells.ORDER[i]) in [1, 2]:
			sel = i
			break
	_root.visible = true
	_open = true
	_opened_at = Fx.now_ms()
	get_tree().paused = true
	Sfx.play(&"menu_open", -2.0, 0.0)


func close() -> void:
	_open = false
	_root.visible = false
	get_tree().paused = false
	Sfx.play(&"menu_close", -4.0, 0.0)


func _apply() -> void:
	var sp: String = Spells.ORDER[sel]
	var st := status(sp)
	if st != 2:
		Sfx.play(&"block", -4.0, 0.0)
		return
	var busy := any_active()
	if busy != "":
		_draw.msg = "진행 중인 수업(%s)을 먼저 마치자." % String(Spells.info(busy).name)
		_draw.msg_t = 2.0
		Sfx.play(&"block", -4.0, 0.0)
		return
	var q := class_of(sp)
	close()
	Quests.start(q)
	Music.jingle("jingle_quest")
	var begin := "cls_%s_begin" % sp
	if Story.has_script(begin):
		Story.run(begin)


func _input(event: InputEvent) -> void:
	if not _open or event.is_echo() or Fx.now_ms() - _opened_at < 200:
		return
	var handled := true
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var lp: Vector2 = event.position
		var hit := false
		for i in Spells.ORDER.size():
			if Rect2(36, 84 + i * 30, 210, 28).has_point(lp):
				sel = i
				hit = true
				Sfx.play(&"ui_move", 0.0, 0.0)
		if not hit and Rect2(270, 300, 120, 24).has_point(lp):
			_apply()
		elif not hit and (Rect2(0, 330, 640, 30).has_point(lp) or Rect2(560, 20, 70, 24).has_point(lp)):
			close()
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		sel = (sel + Spells.ORDER.size() - 1) % Spells.ORDER.size()
		Sfx.play(&"ui_move", 0.0, 0.0)
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		sel = (sel + 1) % Spells.ORDER.size()
		Sfx.play(&"ui_move", 0.0, 0.0)
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		close()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("jump") or event.is_action_pressed("attack"):
		_apply()
	else:
		handled = false
	if handled and is_inside_tree():
		get_viewport().set_input_as_handled()


class BoardDraw extends Control:
	var ui: ClassBoardUI
	var msg := ""
	var msg_t := 0.0
	var _font: Font
	var _t := 0.0

	func _ready() -> void:
		_font = ThemeDB.fallback_font

	func _process(delta: float) -> void:
		_t += delta
		msg_t = maxf(msg_t - delta, 0.0)
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.02, 0.06, 0.92))
		# 양피지 판
		draw_rect(Rect2(24, 24, 592, 312), Color("#1c1626"))
		draw_rect(Rect2(24, 24, 592, 312), Color(Palette.GOLD, 0.5), false, 1.0)
		draw_string(_font, Vector2(40, 56), "마법 배우기 — 수업 게시판", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Palette.GOLD)
		draw_string(_font, Vector2(560, 38), "닫기", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_DIM)
		for i in Spells.ORDER.size():
			var sp: String = Spells.ORDER[i]
			var st := ClassBoardUI.status(sp)
			var r := Rect2(36, 84 + i * 30, 210, 28)
			var on := i == ui.sel
			draw_rect(r, Color(1, 1, 1, 0.08 if on else 0.02))
			if on:
				draw_rect(r, Color(Palette.FIRE_OUT, 0.8), false, 1.0)
			var g := Spells.grade(sp)
			var gcol: Color = [Color("#c8c0d8"), Color("#7ac8ff"), Palette.GOLD][g]
			draw_rect(Rect2(r.position + Vector2(4, 6), Vector2(3, 16)), gcol)
			var nm := String(Spells.info(sp).name) if st != 3 else String(Spells.info(sp).name) + " ?"
			draw_string(_font, r.position + Vector2(14, 18), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_TEXT if st != 3 else Palette.UI_DIM)
			var tag: String = ["습득", "진행 중", "신청 가능", "잠김"][st]
			var tcol: Color = [Color("#8ae07a"), Palette.GOLD, Color("#ffb070"), Palette.UI_DIM][st]
			draw_string(_font, r.position + Vector2(150, 18), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, tcol)
		# 오른쪽
		var sp2: String = Spells.ORDER[ui.sel]
		var inf := Spells.info(sp2)
		var st2 := ClassBoardUI.status(sp2)
		var x := 270.0
		var g2 := Spells.grade(sp2)
		draw_string(_font, Vector2(x, 100), String(inf.name), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Palette.UI_TEXT)
		draw_string(_font, Vector2(x, 120), "%s 마법 · 담당 %s" % [Spells.GRADE_NAMES[g2], String(inf.teacher)], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, [Color("#c8c0d8"), Color("#7ac8ff"), Palette.GOLD][g2])
		draw_multiline_string(_font, Vector2(x, 142), String(inf.desc), HORIZONTAL_ALIGNMENT_LEFT, 330, 12, 3, Palette.UI_DIM)
		var q := ClassBoardUI.class_of(sp2)
		var y := 200.0
		if q == "":
			draw_string(_font, Vector2(x, y), "1장에서 이미 배운 마법이다.", HORIZONTAL_ALIGNMENT_LEFT, 330, 12, Palette.UI_DIM)
		else:
			var d := Quests.def(q)
			if st2 == 3:
				draw_string(_font, Vector2(x, y), "🔒 " + String(d.get("unlock_text", "아직 들을 수 없다.")), HORIZONTAL_ALIGNMENT_LEFT, 330, 12, Color("#ff9a8a"))
				y += 22
			draw_string(_font, Vector2(x, y), "수업 과정", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.GOLD)
			var steps: Array = d.get("steps", [])
			var n := Quests.step(q)
			for i in steps.size():
				var done := st2 == 0 or (st2 == 1 and i < n)
				var cur := st2 == 1 and i == n
				draw_string(_font, Vector2(x + 6, y + 18 + i * 16), ("✓ " if done else ("▶ " if cur else "· ")) + String(steps[i]), HORIZONTAL_ALIGNMENT_LEFT, 324, 12, Palette.UI_TEXT if cur else Palette.UI_DIM)
		if st2 == 2:
			var br := Rect2(x, 300, 120, 24)
			var pulse := 0.5 + 0.5 * sin(_t * 4.0)
			draw_rect(br, Color(Palette.FIRE_OUT, 0.25 + 0.15 * pulse))
			draw_rect(br, Color(Palette.FIRE_HOT, 0.9), false, 1.0)
			draw_string(_font, br.position + Vector2(30, 16), "수업 신청", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_TEXT)
		if msg_t > 0.0:
			draw_string(_font, Vector2(x, 292), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(Palette.GOLD, minf(msg_t, 1.0)))
		var hint := "수업을 누르고 '수업 신청'" if TouchControls.active else "↑↓ 고르기 · Z 신청 · Esc 닫기"
		draw_string(_font, Vector2(40, 326), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_DIM)
