## map_view.gd — 크게 보이는 층·방 지도: 지나온 방, 현재 방, 앞으로의 갈림. 아이콘·선·돌판은 코드로 그린다.
## 마녀만 보는 죽음 표식: 2층 깊은 곳에 붉은 실 표식을 흐리게 둔다(정체는 설명하지 않는다 — 대본 3.1).
class_name MapView
extends Control

signal closed

var close_btn: Btn
var first := false
var _t := 0.0
const PANEL := Rect2(250, 168, 1420, 896)   # 위쪽 대사창(왼쪽 위)과 겹치지 않게 아래로


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = Vector2(1920, 1080)
	close_btn = UI.button(G.ui("mapClose"), 30, func(): close())
	close_btn.style_kind = "small"
	close_btn.fit(Vector2(54, 12))
	close_btn.position = Vector2(PANEL.end.x - close_btn.size.x - 30, PANEL.end.y - close_btn.size.y - 26)
	add_child(close_btn)


func open(is_first := false) -> void:
	first = is_first
	visible = true
	modulate.a = 0.0
	FX.anim(300, [{"a": 0.0}, {"a": 1.0}], func(v): modulate.a = v.a, {"node": self, "key": "map"})
	G.ctl.note("map open")
	if is_first:
		close_btn.disabled = true
		await G.guide.fire("mapFirst", {})
		close_btn.disabled = false
		close_btn.pulse = true
	if G.autoguide:
		await get_tree().create_timer(0.6).timeout
		if visible:
			close()


func close() -> void:
	if G.dialog.guide_open():
		return
	close_btn.pulse = false
	var a := FX.anim(220, [{"a": 1.0}, {"a": 0.0}], func(v): modulate.a = v.a, {"node": self, "key": "map"})
	await FX.until(a)
	visible = false
	G.ctl.note("map close")
	closed.emit()


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
		accept_event()
		if G.dialog.guide_open():
			G.dialog.advance()


func _process(d: float) -> void:
	if visible:
		_t += d
		queue_redraw()


## 방의 화면 위치
func room_pos(id: String) -> Vector2:
	var r: Dictionary = GameData.D.map.rooms[id]
	var band := floor_band(int(r.floor))
	var rows := 3.0 if int(r.floor) == 1 else 1.0
	return Vector2(band.position.x + 150 + float(r.col) * 215.0, band.position.y + band.size.y * (float(r.row) + 0.5) / rows)


func floor_band(n: int) -> Rect2:
	var y := PANEL.position.y + 100.0
	var hs := {1: 330.0, 2: 150.0, 3: 150.0, 4: 56.0}
	for i in range(1, n):
		y += hs.get(i, 70.0) + 14.0
	return Rect2(PANEL.position.x + 40, y, PANEL.size.x - 80, hs.get(n, 70.0))


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.62))
	draw_style_box(UI.box(Color(0.07, 0.06, 0.055, 0.97), Color("#8a6a3a"), 16, 3), PANEL)
	draw_style_box(UI.box(Color(0, 0, 0, 0), Color(0.55, 0.42, 0.24, 0.4), 12, 1), PANEL.grow(-10))
	var f := Assets.font("serif_bold")
	var fs := Assets.font("sans_bold")
	draw_string(f, PANEL.position + Vector2(50, 66), G.ui("mapTitle"), HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color("#f6e7c8"))
	var st: Dictionary = G.ctl.st
	var prog: Dictionary = st.progress
	var M: Dictionary = GameData.D.map
	# 층 띠
	for fl in M.floors:
		var n: int = fl.n
		var band := floor_band(n)
		var locked: bool = fl.get("locked", false) or n > int(prog.floor)
		draw_style_box(UI.box(Color(0.12, 0.1, 0.09, 0.6) if not locked else Color(0.06, 0.06, 0.06, 0.6), Color(0.4, 0.32, 0.22, 0.5), 10, 1), band)
		Icons.stone_tile(self, band.position + Vector2(-2, 22), 40, n == int(prog.floor), locked)
		var nm := str(G.S.map.floors.get(n, str(n)))
		draw_string(f, band.position + Vector2(30, 32), nm if not locked else str(G.S.map.floorShort).replace("{n}", str(n)) + " · ???", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#d9c9b8") if not locked else Color(0.5, 0.48, 0.45))
	# 갈 수 없게 된 길 (갈림길에서 고르지 않은 길)
	var path: String = st.flags.get("path", "")
	# 연결선
	for ln in M.links:
		if int(M.rooms[ln[0]].floor) > int(prog.floor) or int(M.rooms[ln[1]].floor) > int(prog.floor):
			continue
		var a := room_pos(ln[0])
		var b := room_pos(ln[1])
		var both: bool = prog.visited.has(ln[0]) and prog.visited.has(ln[1])
		var dead: bool = path != "" and (ln[0] in ["corpse", "rest", "train"] or ln[1] in ["corpse", "rest", "train"]) and not (ln[0] == path or ln[1] == path)
		var col := Color("#d9b46a") if both else Color(0.6, 0.55, 0.48, 0.55)
		if dead:
			col = Color(0.35, 0.33, 0.3, 0.35)
		if int(GameData.D.map.rooms[ln[0]].floor) != int(GameData.D.map.rooms[ln[1]].floor):
			# 층을 잇는 계단: 점선
			var d := b - a
			var n2 := int(d.length() / 14)
			for i in n2:
				if i % 2 == 0:
					draw_line(a + d * (float(i) / n2), a + d * (float(i + 1) / n2), col, 3.0, true)
		else:
			draw_line(a, b, col, 4.0 if both else 2.5, true)
	# 방
	for id in M.rooms:
		var r: Dictionary = M.rooms[id]
		if int(r.floor) > int(prog.floor):
			continue
		var p := room_pos(id)
		var visited: bool = prog.visited.has(id)
		var cur: bool = prog.room == id
		var dead2: bool = path != "" and id in ["corpse", "rest", "train"] and id != path
		var a2 := 1.0 if visited else 0.7
		if dead2:
			a2 = 0.28
		Icons.medallion(self, p, 34.0, r.icon, 1.0 if cur else 0.0, a2)
		if dead2:
			draw_line(p + Vector2(-22, -22), p + Vector2(22, 22), Color(0.8, 0.2, 0.2, 0.6), 3.0, true)
			draw_line(p + Vector2(22, -22), p + Vector2(-22, 22), Color(0.8, 0.2, 0.2, 0.6), 3.0, true)
		if cur:
			draw_arc(p, 50 + 4 * sin(_t * 4.0), 0, TAU, 48, Color(1, 0.82, 0.5, 0.9), 3.0, true)
			draw_string(fs, p + Vector2(-80, -58), G.ui("mapHere"), HORIZONTAL_ALIGNMENT_CENTER, 160, 20, Color("#ffe2a8"))
		# 방 이름: 연결선 위에서도 읽히게 어두운 판을 깐다
		var nm2 := str(G.S.map.rooms.get(id, id))
		var lf := Assets.font("sans_bold")
		var tw := lf.get_string_size(nm2, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x
		draw_style_box(UI.box(Color(0.05, 0.04, 0.035, 0.92 * maxf(a2, 0.6)), Color(0.45, 0.36, 0.22, 0.6 * a2), 6, 1), Rect2(p.x - tw / 2.0 - 10, p.y + 44, tw + 20, 30))
		draw_string(lf, p + Vector2(-90, 66), nm2, HORIZONTAL_ALIGNMENT_CENTER, 180, 19, Color(0.95, 0.9, 0.82, maxf(a2, 0.5)))
		# 마녀만 보는 죽음 표식 (흐리게, 설명 없이)
		var dm = r.get("deathMark", false)
		var show_mark := false
		if dm is bool:
			show_mark = dm
		elif str(dm) == "hero":
			show_mark = st.party.allies.hero.status != "dead"
		else:
			var fm = Rules.fate_by_id(st, str(dm))
			show_mark = fm != null and fm.alive and int(fm.floor) == int(r.floor)
		if show_mark:
			Icons.death_mark(self, p + Vector2(46, -40), 16.0, _t, 0.5)
	# 범례
	draw_string(fs, Vector2(PANEL.position.x + 50, PANEL.end.y - 40), G.ui("mapLegend"), HORIZONTAL_ALIGNMENT_LEFT, PANEL.size.x - 360, 20, Color(0.82, 0.76, 0.68))
