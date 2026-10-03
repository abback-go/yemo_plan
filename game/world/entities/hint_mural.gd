class_name HintMural
extends Node2D
## 여우창문으로만 보이는 벽화 (docs/chapter1.md 12.2절): 봉화 순서 단서 등. 한 번 드러나면 계속 보인다.
## symbols: 그릴 순서 ["moon", "fox", "flame", "star"], text: 아래에 새긴 글

var key := ""
var symbols: Array = []
var text := ""
var size_t := Vector2(6, 4)
var _rev := false
var _t := 0.0
var _font: Font


func setup(room: Room, e: Dictionary, eid: String) -> void:
	key = "mural_%s_%s" % [room.data.id, eid]
	symbols = e.get("symbols", [])
	text = String(e.get("text", ""))
	size_t = Vector2(float(e.get("w", 6)), float(e.get("h", 4)))
	position = room.tile_pos(e)
	add_to_group(&"hint_mural")
	_rev = GameState.has_flag(key)
	z_index = -1
	_font = ThemeDB.fallback_font


func try_reveal(center: Vector2, radius: float) -> bool:
	if _rev:
		return false
	var r := Rect2(global_position, size_t * 16.0)
	var closest := Vector2(clampf(center.x, r.position.x, r.end.x), clampf(center.y, r.position.y, r.end.y))
	if closest.distance_to(center) > radius:
		return false
	_rev = true
	GameState.set_flag(key)
	Sfx.play(&"reveal", 0.0, 0.0)
	return true


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var sz := size_t * 16.0
	draw_rect(Rect2(Vector2.ZERO, sz), Color(0.1, 0.09, 0.15, 0.6))
	draw_rect(Rect2(Vector2.ZERO, sz), Color(0.3, 0.28, 0.4, 0.5), false, 1.0)
	if not _rev:
		# 지워진 듯 흐린 얼룩만
		for i in 5:
			draw_rect(Rect2(8 + i * 14, sz.y * 0.4, 8, 6), Color(0.3, 0.28, 0.38, 0.4))
		return
	var a := 0.7 + 0.3 * sin(_t * 2.0)
	var col := Color(0.6, 0.85, 1.0, a)
	var n := symbols.size()
	for i in n:
		var c := Vector2(sz.x * (i + 0.5) / n, sz.y * 0.4)
		match String(symbols[i]):
			"moon":
				draw_circle(c, 7, col)
				draw_circle(c + Vector2(3, -2), 6, Color(0.1, 0.09, 0.15))
			"fox":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-7, -2), c + Vector2(-8, -9), c + Vector2(-2, -5), c + Vector2(2, -5), c + Vector2(8, -9), c + Vector2(7, -2), c + Vector2(0, 6)]), col)
			"flame":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-5, 6), c + Vector2(0, -9), c + Vector2(5, 6)]), col)
			"star":
				for k in 5:
					var ang := -PI * 0.5 + TAU * k / 5.0
					draw_line(c, c + Vector2(cos(ang), sin(ang)) * 8, col, 2.0)
		draw_string(_font, c + Vector2(-3, 18), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
	if text != "":
		draw_string(_font, Vector2(4, sz.y - 4), text, HORIZONTAL_ALIGNMENT_LEFT, sz.x - 8, 12, Color(0.75, 0.9, 1.0, a))
