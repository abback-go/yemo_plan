class_name ClassBoard
extends Interactable
## 수업 게시판 (docs/magic.md 4절): ↑로 "마법 배우기" 창을 연다. 새로 신청할 수 있는 수업이 있으면 위에 "!".

var _t := 0.0
var _font: Font


func setup(p_room: Room, e: Dictionary, _eid: String) -> void:
	room = p_room
	position = room.tile_pos(e) + Vector2(8, 0)
	prompt = "마법 배우기 — 수업 게시판"
	area_size = Vector2(40, 44)
	z_index = -1
	_font = ThemeDB.fallback_font


func can_interact() -> bool:
	return is_visible_in_tree() and not Story.busy()


func interact() -> void:
	var w := World.get_world()
	if w:
		w.class_ui.open()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	# 나무 게시판 + 양피지 공고 셋 + 마법진 도장
	draw_rect(Rect2(-18, -40, 36, 26), Color("#4a3424"))
	draw_rect(Rect2(-18, -40, 36, 2), Color("#7a5a3a"))
	draw_rect(Rect2(-16, -14, 3, 14), Color("#3a281a"))
	draw_rect(Rect2(13, -14, 3, 14), Color("#3a281a"))
	for i in 3:
		var p := Vector2(-14 + i * 10, -37 + (i % 2) * 3)
		draw_rect(Rect2(p, Vector2(8, 11)), Color("#e8dcc0"))
		draw_rect(Rect2(p + Vector2(1, 3), Vector2(6, 1)), Color("#8a7a6a"))
		draw_rect(Rect2(p + Vector2(1, 6), Vector2(5, 1)), Color("#8a7a6a"))
		draw_circle(p + Vector2(4, 0), 1.0, Color("#c83a3a"))
	if ClassBoardUI.has_new():
		var y := -50.0 + sin(_t * 4.0) * 2.0
		draw_string(_font, Vector2(-3, y), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.GOLD)
