## floor_map.gd — 층 지도(거점) 화면: 방을 눌러 들어간다 (vertical-slice.md 5장 '층 구조', 대본 v3 2장).
##  · 방 = 아이콘(그 방에서 일어날 일) + 이름. 지나간 방과 이어진 방만 들어갈 수 있고, 지나간 방은 공짜로 지나간다(이동만).
##  · 처음 들어가는 방마다 랜턴의 촛불이 하나 탄다(오른쪽 칸의 랜턴). 촛불이 없으면 들어갈 때마다 어둠이 깊어진다.
##  · 방을 한 번 누르면 오른쪽 칸에 설명, 한 번 더 누르거나 「들어간다」를 누르면 들어간다.
## 그림(양피지 지도 바탕·아이콘·랜턴)은 아직 없어 코드로 그린 임시 모양. 데이터는 game_data.gd floorMaps·lantern·roomTypes, 문구는 script_data.gd map.
class_name FloorMap
extends Control

signal chosen(id)

const PANEL := Rect2(1440, 40, 440, 1000)    # 오른쪽 칸: 층 이름·랜턴·어둠·방 설명·범례
const ROOM_R := 40.0

var st: Dictionary
var M: Dictionary
var sel := ""
var hover := ""
var lantern_hot := 0.0     # 처음 지도 안내에서 랜턴을 비추는 빛
var enter_btn: Btn
var info_name: Label
var info_type: Label
var info_desc: Label
var info_cost: Label
var status_l: Label
var _t := 0.0
var _busy := false         # 안내 중에는 방을 고를 수 없다


func setup(state: Dictionary) -> void:
	st = state
	M = Rules.map_def(st)
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = Vector2(1920, 1080)
	var f := Vector2(PANEL.position.x + 30, 0)
	info_name = UI.label("", 34, Color("#f6e7c8"), "serif_bold")
	info_name.position = f + Vector2(0, 572)
	info_name.size = Vector2(PANEL.size.x - 60, 48)
	add_child(info_name)
	info_type = UI.label("", 22, Color("#d9b46a"), "sans_bold")
	info_type.position = f + Vector2(0, 622)
	info_type.size = Vector2(PANEL.size.x - 60, 30)
	add_child(info_type)
	info_desc = UI.label("", 24, Color("#e2d6cc"), "sans")
	info_desc.position = f + Vector2(0, 660)
	info_desc.size = Vector2(PANEL.size.x - 60, 110)
	info_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(info_desc)
	info_cost = UI.label("", 22, Color("#ffcf8a"), "sans_bold")
	info_cost.position = f + Vector2(0, 776)
	info_cost.size = Vector2(PANEL.size.x - 60, 60)
	info_cost.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(info_cost)
	enter_btn = UI.button(str(G.S.map.enter), 30, func(): _confirm(sel), "serif_bold")
	enter_btn.fit(Vector2(60, 14))
	enter_btn.position = Vector2(PANEL.get_center().x - enter_btn.size.x / 2.0, 850)
	enter_btn.name = "enter"
	enter_btn.visible = false
	add_child(enter_btn)
	status_l = UI.label("", 22, Color("#ff9aa4"), "sans_bold")
	status_l.position = f + Vector2(0, 470)
	status_l.size = Vector2(PANEL.size.x - 60, 80)
	status_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(status_l)
	_refresh()


func rooms() -> Dictionary:
	return M.get("rooms", {})


func room_pos(id: String) -> Vector2:
	var p: Array = rooms()[id].pos
	return Vector2(p[0], p[1])


func room_at(p: Vector2) -> String:
	for id in rooms():
		if room_pos(id).distance_to(p) <= ROOM_R + 10:
			return id
	return ""


func room_name(id: String) -> String:
	return str(G.S.map.rooms.get(id, {}).get("name", id))


## 처음 지도가 열릴 때 안내 (대본 v3 2장): 방 고르기 → 랜턴을 비추고 촛불 안내
func intro() -> void:
	_busy = true
	await G.guide.fire("mapFirst", {})
	if not is_inside_tree():
		return
	FX.anim(700, [{"k": 0.0}, {"k": 1.0}], func(v): lantern_hot = v.k, {"node": self, "key": "lantern_hot"})
	await G.guide.fire("lanternFirst", {})
	if not is_inside_tree():
		return
	FX.anim(900, [{"k": 1.0}, {"k": 0.0}], func(v): lantern_hot = v.k, {"node": self, "key": "lantern_hot"})
	_busy = false


## 방을 고를 때까지 기다린다. 반환: 들어갈 방 id (처음 들어가는 방)
func run() -> String:
	if G.autoguide:
		get_tree().create_timer(FX.ms(700) / 1000.0).timeout.connect(_auto)
	var id = await chosen
	return str(id)


## 자동 진행: --rooms=방,방… 순서대로 들어갈 수 있는 첫 방, 다 돌았으면 계단 앞 홀 → 가장 깊은 곳
func _auto() -> void:
	if not is_inside_tree():
		return
	if _busy or G.dialog.is_busy():
		get_tree().create_timer(0.3).timeout.connect(_auto)
		return
	var plan: Array = str(G.params.get("rooms", "")).split(",", false)
	plan.append_array(["stairs", str(M.get("end", "deep"))])
	for id in plan:
		if Rules.room_state(st, id) == "open":
			_confirm(id)
			return


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		var h := room_at(e.position)
		if h != hover:
			hover = h
			_refresh()
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if G.dialog.guide_open():
			G.dialog.advance()
			return
		if _busy:
			return
		var id := room_at(e.position)
		if id == "":
			return
		if id == sel:
			_confirm(id)
		else:
			select(id)


func select(id: String) -> void:
	sel = id
	G.ctl.note("map select " + id)
	_refresh()


## 들어가기: 처음 들어가는 방이면 고른 것으로 끝낸다. 지나간 방이면 그 자리로 옮기기만 한다(공짜)
func _confirm(id: String) -> void:
	if id == "" or _busy:
		return
	var stt := Rules.room_state(st, id)
	if stt == "locked":
		FX.toast(str(G.S.map.locked))
		return
	if stt == "visited":
		if st.progress.room != id:
			Rules.enter_room(st, id)
			G.ctl.note("map move " + id)
			_refresh()
		return
	_busy = true
	G.ctl.note("map enter " + id)
	chosen.emit(id)


## 시험: 그 방으로 바로 들어간다(들어갈 수 있으면)
func pick(id: String) -> bool:
	if Rules.room_state(st, id) == "locked":
		return false
	_busy = false
	_confirm(id)
	return true


func _refresh() -> void:
	var p: Dictionary = st.progress
	var show := sel if sel != "" else hover
	enter_btn.visible = false
	if show == "":
		info_name.text = ""
		info_type.text = ""
		info_desc.text = ""
		info_cost.text = ""
	else:
		var R: Dictionary = rooms()[show]
		var stt := Rules.room_state(st, show)
		info_name.text = room_name(show)
		info_type.text = str(G.S.map.types.get(str(R.type), ""))
		info_desc.text = str(G.S.map.rooms.get(show, {}).get("desc", ""))
		var cost := ""
		match stt:
			"visited":
				cost = str(G.S.map.here) if p.room == show else str(G.S.map.visited)
			"open":
				if not bool(R.get("candle", true)):
					cost = str(G.S.map.free)
				elif int(p.candles) > 0:
					cost = str(G.S.map.cost)
				else:
					cost = str(G.S.map.costDark)
			_:
				cost = str(G.S.map.locked)
		info_cost.text = cost
		info_cost.add_theme_color_override("font_color", Color("#ff7a86") if stt == "open" and int(p.candles) <= 0 else Color("#ffcf8a"))
		if show == sel and stt == "open":
			enter_btn.set_text(str(G.S.map.enter))
			enter_btn.visible = true
		elif show == sel and stt == "visited" and p.room != show:
			enter_btn.set_text(str(G.S.map.move))
			enter_btn.visible = true
		enter_btn.fit(Vector2(60, 14))
		enter_btn.position = Vector2(PANEL.get_center().x - enter_btn.size.x / 2.0, 850)
		enter_btn.pulse = stt == "open"
	var lines := []
	if int(p.darkness) > 0:
		lines.append(str(G.S.map.darkness).replace("{n}", str(p.darkness)))
	if bool(p.get("omen", false)):
		lines.append(str(G.S.map.omen))
	status_l.text = "\n".join(lines)
	queue_redraw()


func _process(d: float) -> void:
	_t += d
	queue_redraw()


func _draw() -> void:
	var p: Dictionary = st.progress
	# 바탕: 어두운 돌바닥 + 양피지 흉내(임시)
	draw_rect(Rect2(Vector2.ZERO, size), Color("#07050a"))
	var paper := Rect2(30, 30, PANEL.position.x - 50, 1020)
	draw_style_box(UI.box(Color(0.16, 0.13, 0.1, 0.96), Color("#6a5232"), 18, 3), paper)
	draw_style_box(UI.box(Color(0, 0, 0, 0), Color(0.5, 0.36, 0.2, 0.35), 12, 1), paper.grow(-12))
	# 어둠: 단계만큼 지도 가장자리가 어두워진다
	var dk := clampf(float(p.darkness) * 0.12, 0.0, 0.55)
	if dk > 0:
		for i in 6:
			draw_style_box(UI.box(Color(0, 0, 0, 0), Color(0, 0, 0, dk * (1.0 - i / 6.0)), 18, 40), paper.grow(-i * 34))
	# 연결선
	for ln in M.get("links", []):
		var a := room_pos(ln[0])
		var b := room_pos(ln[1])
		var va: bool = p.visited.has(ln[0])
		var vb: bool = p.visited.has(ln[1])
		var col := Color(0.42, 0.36, 0.3, 0.45)
		var wd := 2.5
		if va and vb:
			col = Color("#d9b46a")
			wd = 4.0
		elif va or vb:
			col = Color(0.85, 0.75, 0.6, 0.75)
			wd = 3.0
		var dd := (b - a)
		var n := int(dd.length() / 16.0)
		var from := a + dd.normalized() * ROOM_R
		var to := b - dd.normalized() * ROOM_R
		if va and vb:
			draw_line(from, to, col, wd, true)
		else:
			# 아직 지나가지 않은 길은 점선
			var d2 := to - from
			for i in n:
				if i % 2 == 0:
					draw_line(from + d2 * (float(i) / n), from + d2 * (float(i + 1) / n), col, wd, true)
	# 방
	var lf := Assets.font("sans_bold")
	for id in rooms():
		var R: Dictionary = rooms()[id]
		var c := room_pos(id)
		var stt := Rules.room_state(st, id)
		var icon: String = str(GameData.D.roomTypes.get(str(R.type), {}).get("icon", "question"))
		var a2 := 1.0
		if stt == "locked":
			a2 = 0.34
		elif stt == "visited":
			a2 = 0.82
		var hot := 0.0
		if id == sel:
			hot = 1.0
		elif id == hover and stt != "locked":
			hot = 0.6
		elif stt == "open":
			hot = 0.3 + 0.3 * sin(_t * 3.0)
		Icons.medallion(self, c, ROOM_R, icon, hot, a2)
		if stt == "visited":
			# 지나간 방: 금빛 테두리 한 겹
			draw_arc(c, ROOM_R + 8, 0, TAU, 40, Color(0.85, 0.7, 0.4, 0.55), 2.0, true)
		if p.room == id:
			draw_arc(c, ROOM_R + 16 + 3 * sin(_t * 4.0), 0, TAU, 48, Color(1, 0.82, 0.5, 0.95), 3.0, true)
			draw_string(lf, c + Vector2(-80, -ROOM_R - 26), str(G.S.map.here), HORIZONTAL_ALIGNMENT_CENTER, 160, 20, Color("#ffe2a8"))
		if id == sel:
			draw_arc(c, ROOM_R + 12, 0, TAU, 48, Color("#ffd36b"), 3.0, true)
		var nm := room_name(id)
		var tw := lf.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 21).x
		draw_style_box(UI.box(Color(0.05, 0.04, 0.035, 0.92), Color(0.45, 0.36, 0.22, 0.7 * a2), 6, 1), Rect2(c.x - tw / 2.0 - 10, c.y + ROOM_R + 10, tw + 20, 32))
		draw_string(lf, Vector2(c.x - 120, c.y + ROOM_R + 33), nm, HORIZONTAL_ALIGNMENT_CENTER, 240, 21, Color(0.96, 0.9, 0.82, maxf(a2, 0.55)))
	# 오른쪽 칸
	draw_style_box(UI.box(Color(0.06, 0.04, 0.045, 0.96), Color("#6e2a31"), 16, 2), PANEL)
	var f := Assets.font("serif_bold")
	draw_string(f, PANEL.position + Vector2(30, 62), str(G.S.map.floors.get(Rules.floor_now(st), G.S.map.title)), HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color("#f6e7c8"))
	draw_rect(Rect2(PANEL.position + Vector2(24, 84), Vector2(PANEL.size.x - 48, 1)), Color(0.55, 0.2, 0.25, 0.6))
	_draw_lantern(Vector2(PANEL.get_center().x, 300))
	draw_rect(Rect2(PANEL.position + Vector2(24, 556), Vector2(PANEL.size.x - 48, 1)), Color(0.55, 0.2, 0.25, 0.6))
	# 범례 (아이콘 7종)
	var types := ["battle", "elite", "event", "rest", "train", "trade", "omen"]
	var fs := Assets.font("sans")
	for i in types.size():
		var t: String = types[i]
		var col := i % 2
		var row := i / 2
		var lc := PANEL.position + Vector2(48 + col * 200, 896 + row * 28)
		Icons.draw(self, str(GameData.D.roomTypes[t].icon), lc, 11.0, Color("#f0e6d8"), 0.9)
		draw_string(fs, lc + Vector2(20, 7), str(G.S.map.types[t]), HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(0.85, 0.8, 0.74))


## 랜턴: 쇠틀 + 촛불 칸 (이 층에서 받은 만큼 — 탄 촛불은 꺼진 심지)
func _draw_lantern(c: Vector2) -> void:
	var p: Dictionary = st.progress
	var n := int(p.candles)
	var slots := maxi(n, int(p.get("candlesStart", n)))
	if lantern_hot > 0:
		for i in 5:
			draw_circle(c + Vector2(0, 20), 150.0 + i * 26.0, Color(1, 0.7, 0.3, 0.05 * lantern_hot))
	var fr := Rect2(c + Vector2(-150, -120), Vector2(300, 250))
	var glow := 0.35 + 0.08 * sin(_t * 5.0) if n > 0 else 0.0
	draw_style_box(UI.box(Color(0.12, 0.08, 0.05, 0.9), Color(0.3, 0.27, 0.25), 14, 4), fr)
	if glow > 0:
		draw_style_box(UI.box(Color(1, 0.6, 0.2, glow * 0.25), Color.TRANSPARENT, 12), fr.grow(-8))
	# 손잡이 고리
	draw_arc(c + Vector2(0, -132), 26, PI, TAU, 24, Color(0.3, 0.27, 0.25), 5.0, true)
	var per_row := 4
	var rows := int(ceil(slots / float(per_row)))
	for i in slots:
		var r := i / per_row
		var k := i % per_row
		var cnt := mini(per_row, slots - r * per_row)
		var x := c.x - (cnt - 1) * 34.0 + k * 68.0
		var y := c.y + 60 - (rows - 1 - r) * 92.0
		var lit := i < n
		draw_rect(Rect2(x - 11, y - 46, 22, 58), Color("#e8dcc4") if lit else Color("#6e665c"))
		draw_line(Vector2(x, y - 46), Vector2(x, y - 54), Color(0.15, 0.1, 0.05), 2.0, true)
		if lit:
			var fl := 1.0 + 0.12 * sin(_t * 9.0 + i)
			Icons.draw(self, "flame", Vector2(x, y - 68), 16.0 * fl, Color.WHITE, 1.0)
	var fs := Assets.font("sans_bold")
	var txt := str(G.S.map.candles).replace("{n}", str(n))
	draw_string(fs, Vector2(PANEL.position.x, c.y + 170), str(G.S.map.lantern) + " · " + txt, HORIZONTAL_ALIGNMENT_CENTER, PANEL.size.x, 26, Color("#ffe2a8") if n > 0 else Color("#ff7a86"))
