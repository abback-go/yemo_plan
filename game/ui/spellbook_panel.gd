class_name SpellbookPanel
extends Control
## 마법서 (일시정지 → 마법서, docs/magic.md): 7종의 등급·레벨·장착. 마도석으로 레벨을 올린다.
## ↑↓ 마법 고르기, ←→ 할 일 고르기(레벨 올리기·A·S·F에 끼우기), Z 실행, Esc 돌아가기. 터치: 줄·단추를 누름.

signal closed

var sel := 0
var act := 0
var _font: Font
var _t := 0.0
var _flash := 0.0
var _msg := ""
var _msg_t := 0.0


func _ready() -> void:
	_font = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func open() -> void:
	act = 0
	_msg = ""


func _id() -> String:
	return Spells.ORDER[sel]


## 이 마법에 할 수 있는 일 목록: [이름, 키]
func _actions() -> Array:
	var id := _id()
	if not Spells.learned(id):
		return []
	var out: Array = []
	if Spells.level(id) < 3:
		out.append(["레벨 올리기 (마도석 %d)" % Spells.next_cost(id), "lv"])
	match String(Spells.info(id).get("slot", "")):
		"as":
			out.append(["A에 끼우기", "a"])
			out.append(["S에 끼우기", "s"])
		"f":
			out.append(["F에 끼우기", "f"])
	return out


func _do(key: String) -> void:
	var id := _id()
	match key:
		"lv":
			if Spells.level_up(id):
				_flash = 1.0
				Sfx.play(&"levelup", 0.0, 0.0)
				Music.jingle("jingle_levelup")
				_msg = "%s Lv%d!" % [String(Spells.info(id).name), Spells.level(id)]
			else:
				Sfx.play(&"block", -4.0, 0.0)
				_msg = "마도석이 모자란다." if Spells.level(id) < 3 else "이미 최고 레벨이다."
		"a", "s", "f":
			Spells.equip(key, id)
			Sfx.play(&"ui_ok", 0.0, 0.0)
			_msg = "%s 칸에 %s" % [key.to_upper(), String(Spells.info(id).name)]
	_msg_t = 1.8


func handle_input(event: InputEvent) -> bool:
	if not visible:
		return false
	var acts := _actions()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var lp: Vector2 = (make_input_local(event) as InputEventMouseButton).position
		for i in Spells.ORDER.size():
			if Rect2(40, 92 + i * 30, 200, 28).has_point(lp):
				if sel != i:
					sel = i
					act = 0
					Sfx.play(&"ui_move", 0.0, 0.0)
				return true
		for j in acts.size():
			if Rect2(260 + j * 116, 296, 112, 22).has_point(lp):
				act = j
				_do(String(acts[j][1]))
				return true
		if Rect2(0, 330, 640, 30).has_point(lp):
			closed.emit()
		return true
	if event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		sel = (sel + Spells.ORDER.size() - 1) % Spells.ORDER.size()
		act = 0
		Sfx.play(&"ui_move", 0.0, 0.0)
		return true
	if event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		sel = (sel + 1) % Spells.ORDER.size()
		act = 0
		Sfx.play(&"ui_move", 0.0, 0.0)
		return true
	if not acts.is_empty() and (event.is_action_pressed("ui_left") or event.is_action_pressed("move_left")):
		act = (act + acts.size() - 1) % acts.size()
		Sfx.play(&"ui_move", 0.0, 0.0)
		return true
	if not acts.is_empty() and (event.is_action_pressed("ui_right") or event.is_action_pressed("move_right")):
		act = (act + 1) % acts.size()
		Sfx.play(&"ui_move", 0.0, 0.0)
		return true
	if event.is_action_pressed("ui_cancel"):
		Sfx.play(&"ui_ok", 0.0, 0.0)
		closed.emit()
		return true
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump") or event.is_action_pressed("attack"):
		if acts.is_empty():
			closed.emit()
		else:
			_do(String(acts[clampi(act, 0, acts.size() - 1)][1]))
		return true
	return false


func _process(delta: float) -> void:
	_t += delta
	_flash = maxf(_flash - delta * 2.0, 0.0)
	_msg_t = maxf(_msg_t - delta, 0.0)
	if visible:
		queue_redraw()


func _grade_col(g: int) -> Color:
	match g:
		1: return Color("#7ac8ff")
		2: return Palette.GOLD
	return Color("#c8c0d8")


func _draw() -> void:
	draw_string(_font, Vector2(40, 50), "마법서", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Palette.GOLD)
	# 장착 요약 + 마도석
	var eq := "A %s · S %s · F %s" % [_slot_name("a"), _slot_name("s"), _slot_name("f")]
	draw_string(_font, Vector2(150, 48), eq, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_TEXT)
	draw_colored_polygon(PackedVector2Array([Vector2(520, 38), Vector2(525, 44), Vector2(520, 50), Vector2(515, 44)]), Color("#a070ff"))
	draw_string(_font, Vector2(530, 48), "마도석 %d" % Spells.stones(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#d0b8ff"))
	# 왼쪽 목록
	for i in Spells.ORDER.size():
		var id: String = Spells.ORDER[i]
		var r := Rect2(40, 92 + i * 30, 200, 28)
		var on := i == sel
		var learned := Spells.learned(id)
		draw_rect(r, Color(1, 1, 1, 0.08 if on else 0.02))
		if on:
			draw_rect(r, Color(Palette.FIRE_OUT, 0.8), false, 1.0)
		var g := Spells.grade(id)
		draw_rect(Rect2(r.position + Vector2(4, 6), Vector2(3, 16)), _grade_col(g))
		var nm := String(Spells.info(id).name) if learned else "？？？"
		draw_string(_font, r.position + Vector2(14, 18), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_TEXT if learned else Palette.UI_DIM)
		if learned:
			var lv := Spells.level(id)
			for k in 3:
				var sc := r.position + Vector2(150 + k * 14, 14)
				_star(sc, 4.0, Palette.GOLD if k < lv else Color("#3a3450"))
	# 오른쪽 설명
	var id2 := _id()
	var inf := Spells.info(id2)
	var x := 260.0
	var learned2 := Spells.learned(id2)
	var g2 := Spells.grade(id2)
	draw_string(_font, Vector2(x, 100), String(inf.name) if learned2 else "아직 모르는 마법", HORIZONTAL_ALIGNMENT_LEFT, -1, 24 if learned2 else 12, Palette.UI_TEXT)
	draw_string(_font, Vector2(x, 120), "%s 마법 · %s" % [Spells.GRADE_NAMES[g2], String(inf.teacher)], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, _grade_col(g2))
	if learned2:
		draw_multiline_string(_font, Vector2(x, 142), String(inf.desc), HORIZONTAL_ALIGNMENT_LEFT, 346, 12, 2, Palette.UI_DIM)
		var lvs: Array = inf.lv
		var cur := Spells.level(id2)
		for k in lvs.size():
			var yy := 196 + k * 22
			var col := Palette.UI_TEXT if k + 1 == cur else (Color(Palette.UI_DIM, 0.9) if k + 1 < cur else Color(Palette.UI_DIM, 0.55))
			_star(Vector2(x + 4, yy - 4), 4.0, Palette.GOLD if k < cur else Color("#3a3450"))
			draw_string(_font, Vector2(x + 14, yy), "Lv%d  %s" % [k + 1, String(lvs[k])], HORIZONTAL_ALIGNMENT_LEFT, 336, 12, col)
	else:
		draw_string(_font, Vector2(x, 142), "학교 중앙 홀의 수업 게시판에서 배울 수 있을지도 모른다.", HORIZONTAL_ALIGNMENT_LEFT, 350, 12, Palette.UI_DIM)
	var acts := _actions()
	for j in acts.size():
		var r2 := Rect2(x + j * 116, 296, 112, 22)
		var on2 := j == act
		draw_rect(r2, Color(Palette.FIRE_OUT, 0.25 if on2 else 0.08))
		draw_rect(r2, Color(Palette.FIRE_OUT, 0.9 if on2 else 0.4), false, 1.0)
		var tw := _font.get_string_size(String(acts[j][0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(_font, r2.position + Vector2((r2.size.x - tw) * 0.5, 15), String(acts[j][0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_TEXT if on2 else Palette.UI_DIM)
	if _msg_t > 0.0:
		draw_string(_font, Vector2(x, 286), _msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(Palette.GOLD, minf(_msg_t, 1.0)))
	if _flash > 0.0:
		draw_rect(Rect2(36, 88 + sel * 30, 208, 36), Color(1, 0.9, 0.6, 0.4 * _flash), false, 2.0)
	var hint := "눌러서 고르기 · 아래를 눌러 돌아가기" if TouchControls.active else "↑↓ 마법 · ←→ 할 일 · Z 실행 · Esc 돌아가기"
	draw_string(_font, Vector2(40, 346), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_DIM)


func _slot_name(slot: String) -> String:
	var id := Spells.equipped(slot)
	return String(Spells.info(id).get("short", "—")) if id != "" else "—"


func _star(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI * 0.5 + TAU * i / 10.0
		var rr := r if i % 2 == 0 else r * 0.45
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(pts, col)
