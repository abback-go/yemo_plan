class_name RoomDoor
extends Interactable
## ↑로 드나드는 문·계단·관문. lock 플래그가 없으면 잠겨 있다.
## style: wood(나무 아치문) · iron(철문) · grand(큰 문) · stair_up · stair_down · shrine(홍살문) · portal(여우비 문)

var door_id := ""
var to_room := ""
var to_id := ""
var style := "wood"
var label := ""
var lock := ""
var lock_msg := "잠겨 있다."
var _t := 0.0


func setup(p_room: Room, e: Dictionary, eid: String) -> void:
	room = p_room
	door_id = eid
	to_room = String(e.get("to", ""))
	to_id = String(e.get("to_id", ""))
	style = String(e.get("style", "wood"))
	label = String(e.get("label", ""))
	lock = String(e.get("lock", ""))
	lock_msg = String(e.get("lock_msg", lock_msg))
	position = room.tile_pos(e) + Vector2(8, 0)
	area_size = Vector2(30, 40)
	z_index = -1
	match style:
		"stair_up": prompt = "올라가기"
		"stair_down": prompt = "내려가기"
		"portal": prompt = "들어가기"
		_: prompt = "들어가기"
	if label != "":
		prompt += " — " + label


func is_locked() -> bool:
	return lock != "" and not RoomData.cond_ok(lock)


func interact() -> void:
	if is_locked():
		Sfx.play(&"door", -6.0, 0.0)
		Story.toast(lock_msg)
		return
	var w := World.get_world()
	if w and to_room != "":
		Sfx.play(&"door", -2.0, 0.05)
		w.go(to_room, to_id)


func _process(delta: float) -> void:
	_t += delta
	if style == "portal":
		queue_redraw()


func _draw() -> void:
	var dark := Color(0.04, 0.03, 0.06)
	match style:
		"wood", "grand":
			var w := 22.0 if style == "wood" else 34.0
			var h := 34.0 if style == "wood" else 46.0
			# 아치 테두리 돌
			var frame := PackedVector2Array()
			for i in 13:
				var a := PI + PI * i / 12.0
				frame.append(Vector2(cos(a) * (w * 0.5 + 4), -h + w * 0.5 + sin(a) * (w * 0.5 + 4)))
			frame.append(Vector2(w * 0.5 + 4, 0))
			frame.append(Vector2(-w * 0.5 - 4, 0))
			draw_colored_polygon(frame, room.theme.top.darkened(0.2))
			var door := PackedVector2Array()
			for i in 13:
				var a := PI + PI * i / 12.0
				door.append(Vector2(cos(a) * w * 0.5, -h + w * 0.5 + sin(a) * w * 0.5))
			door.append(Vector2(w * 0.5, 0))
			door.append(Vector2(-w * 0.5, 0))
			var wood := Color("#4a2e22") if not is_locked() else Color("#3a2a2a")
			draw_colored_polygon(door, wood)
			for i in range(-int(w * 0.5) + 4, int(w * 0.5), 5):
				draw_line(Vector2(i, -h + 6), Vector2(i, 0), wood.darkened(0.35), 1.0)
			draw_rect(Rect2(w * 0.25 - 2, -h * 0.45, 3, 3), Color("#d8a84a"))
			if is_locked():
				draw_rect(Rect2(-w * 0.5, -h * 0.5, w, 3), Color("#6a6a78"))
		"iron":
			draw_rect(Rect2(-14, -36, 28, 36), Color("#2a2a34"))
			for i in 6:
				draw_rect(Rect2(-12 + i * 5, -34, 2, 34), Color("#4a4a5a"))
			draw_rect(Rect2(-14, -36, 28, 2), Color("#6a6a80"))
			if is_locked():
				draw_rect(Rect2(-4, -20, 8, 8), Color("#8a7a4a"))
		"stair_up", "stair_down":
			var up := style == "stair_up"
			draw_rect(Rect2(-14, -36, 28, 36), dark)
			for i in 5:
				var y := -6.0 - i * 6.0 if up else -30.0 + i * 6.0
				draw_rect(Rect2(-12 + i * 4, y, 24 - i * 4, 3), Color(room.theme.top, 0.6 - i * 0.08))
			draw_rect(Rect2(-16, -38, 32, 3), room.theme.top_hi.darkened(0.3))
			draw_rect(Rect2(-16, -38, 3, 38), room.theme.top.darkened(0.2))
			draw_rect(Rect2(13, -38, 3, 38), room.theme.top.darkened(0.2))
		"shrine":
			# 홍살문: 붉은 기둥 두 개 + 위의 살
			var red := Color("#9a2a24")
			draw_rect(Rect2(-22, -54, 4, 54), red)
			draw_rect(Rect2(18, -54, 4, 54), red)
			draw_rect(Rect2(-26, -56, 52, 4), red.lightened(0.1))
			draw_rect(Rect2(-24, -48, 48, 3), red)
			for i in 9:
				draw_rect(Rect2(-20 + i * 5, -56, 1, 8), red.darkened(0.2))
			draw_circle(Vector2(0, -52), 3.0, Color("#e8c060"))
		"portal":
			var k := 0.5 + 0.5 * sin(_t * 3.0)
			for i in 4:
				draw_arc(Vector2(0, -22), 12.0 + i * 4 + k * 2.0, 0, TAU, 24, Color(0.45, 0.75, 1.0, 0.5 - i * 0.1), 2.0)
			draw_circle(Vector2(0, -22), 10.0, Color(0.7, 0.9, 1.0, 0.5))
