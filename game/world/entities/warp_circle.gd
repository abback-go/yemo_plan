class_name WarpCircle
extends Interactable
## 전이진 (docs/archive/sera/systems2.md 6절): ↑로 목적지 창을 연다. 바닥에 도는 보라 마법진.
## 방 데이터: {t = "warp", x, y, area = "kingdom", cond = "..."} — area는 이 전이진이 있는 지역(목록에서 "여기" 표시)

var area := "school"
var _t := 0.0


func setup(p_room: Room, e: Dictionary, _eid: String) -> void:
	room = p_room
	area = String(e.get("area", p_room.data.area))
	position = room.tile_pos(e) + Vector2(8, 0)
	prompt = "전이진"
	area_size = Vector2(44, 40)
	z_index = -1
	material = Fx.add_material
	add_child(LightGlow.make(Vector2(0, -6), 50.0, Color(0.7, 0.55, 1.0), 0.45))


func can_interact() -> bool:
	return is_visible_in_tree() and not Story.busy()


func interact() -> void:
	var w := World.get_world()
	if w == null:
		return
	if WarpDB.unlocked().size() <= 1:
		Story.toast("전이진이 고요하다. 아직 이어진 곳이 없다.")
		return
	w.warp_ui.open(area)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var col := Color(0.7, 0.55, 1.0)
	var hot := Color(0.92, 0.85, 1.0)
	# 바닥 마법진 (납작한 타원)
	for i in 3:
		var r := 22.0 - i * 6.0
		var pts := PackedVector2Array()
		for k in 33:
			var a := TAU * k / 32.0
			pts.append(Vector2(cos(a) * r, sin(a) * r * 0.28 - 1.0))
		draw_polyline(pts, Color(col, 0.7 - i * 0.15), 1.0)
	for k in 6:
		var a := _t * 0.8 + TAU * k / 6.0
		var p := Vector2(cos(a) * 16.0, sin(a) * 4.5 - 1.0)
		draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), hot)
	# 위로 오르는 빛
	for k in 5:
		var ph := fmod(_t * 0.7 + k * 0.2, 1.0)
		var x := sin(k * 2.3) * 14.0
		draw_rect(Rect2(x, -2.0 - ph * 30.0, 1, 3), Color(hot, 0.6 * (1.0 - ph)))
