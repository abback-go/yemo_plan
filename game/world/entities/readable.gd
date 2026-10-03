class_name Readable
extends Interactable
## 읽을 수 있는 것: 게시판·책·비석·편지. text의 "|"는 줄(쪽) 나눔.
## look: board(게시판) · book(펼친 책) · stone(비석) · note(쪽지) · none(보이지 않음, 배경 소품을 조사)

var text := ""
var look := "board"
var _t := 0.0


func setup(p_room: Room, e: Dictionary, eid: String) -> void:
	room = p_room
	text = String(e.get("text", ""))
	look = String(e.get("look", "board"))
	position = room.tile_pos(e) + Vector2(8, 0)
	prompt = String(e.get("prompt", "읽기"))
	z_index = -1


func interact() -> void:
	Story.read(text.split("|"))


func _process(delta: float) -> void:
	_t += delta
	if look == "note" or look == "book":
		queue_redraw()


func _draw() -> void:
	match look:
		"board":
			draw_rect(Rect2(-2, -10, 3, 10), Color("#3a2a20"))
			draw_rect(Rect2(-14, -30, 28, 20), Color("#5a3e2a"))
			draw_rect(Rect2(-12, -28, 24, 16), Color("#8a6a48"))
			draw_rect(Rect2(-10, -26, 8, 6), Color("#e8dcc0"))
			draw_rect(Rect2(0, -25, 9, 8), Color("#d8ccb0"))
			draw_rect(Rect2(-8, -18, 7, 5), Color("#f0e0b0"))
			draw_circle(Vector2(-6, -26), 1.0, Color("#c03030"))
		"stone":
			draw_rect(Rect2(-8, -22, 16, 22), Color("#3a3a4a"))
			draw_rect(Rect2(-6, -26, 12, 4), Color("#3a3a4a"))
			for i in 4:
				draw_rect(Rect2(-5, -20 + i * 4, 10, 1), Color("#6a6a80"))
		"book":
			var y := -14.0 + sin(_t * 2.0) * 1.0
			draw_rect(Rect2(-3, -10, 6, 10), Color("#3a2a20"))
			draw_colored_polygon(PackedVector2Array([Vector2(-10, y), Vector2(0, y + 2), Vector2(0, y - 4), Vector2(-10, y - 6)]), Color("#e8dcc0"))
			draw_colored_polygon(PackedVector2Array([Vector2(10, y), Vector2(0, y + 2), Vector2(0, y - 4), Vector2(10, y - 6)]), Color("#d8ccb0"))
		"note":
			var y2 := -6.0 + sin(_t * 2.5) * 1.0
			draw_rect(Rect2(-4, y2 - 5, 8, 6), Color("#f0e8d0"))
			draw_rect(Rect2(-3, y2 - 3, 6, 1), Color("#8a7a6a"))
			draw_circle(Vector2(0, y2 - 10), 2.0 + sin(_t * 4.0), Color(1.0, 0.9, 0.5, 0.4))
