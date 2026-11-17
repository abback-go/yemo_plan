## fate_hud.gd — 탐사 화면 구석의 운명 표시(살아 있는 운명의 죽음 카드 작은 그림 + 이름 + Lv)와 지도 버튼 (prototype-v2-spec.md 4.1·3.1).
## 운명 카드를 누르면 크게 보기(탭하면 닫힘), 지도 버튼(또는 M 키)을 누르면 층 지도(MapView).
class_name FateHud
extends Control

const THUMB := 0.46        # 작은 카드 배율 (카드 원본 240×360)
var cards: Array = []      # [{"uid", "view", "rect"}]
var map_rect := Rect2()
var big: Control = null
var map: MapView = null
var _key := ""
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(1920, 1080)
	refresh()


func _u() -> float:
	return clampf(FX.ui, 1.0, 1.6)


## 운명이 바뀌면(바침·거스름·레벨업) 다시 그린다
func refresh() -> void:
	var st: Dictionary = G.ctl.st
	if st.is_empty():
		return
	var act := Rules.active_fates(st)
	var key := ""
	for f in act:
		key += "%s:%d|" % [f.id, int(f.level)]
	key += str(_u())
	if key == _key:
		return
	_key = key
	for c in cards:
		c.view.queue_free()
	cards = []
	var u := _u()
	var x := 22.0
	for f in act:
		if not st.cards.has(f.card):
			continue
		var cv := CardView.new()
		add_child(cv)
		cv.setup_face(st, f.card)
		var kk := THUMB * u
		cv.set_rect(Vector2(x, 20), kk, true)
		cv.smooth = false
		cv.taut = 0.6
		var r := Rect2(Vector2(x, 20), Vector2(CardView.W, CardView.H) * kk)
		var nm := Rules.card_name(st.cards[f.card].id, false, Rules.level(st, f.card))
		var lw: float = Assets.font("sans_bold").get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, int(20 * u)).x + 16 * u
		if lw > r.size.x:
			# 이름표가 카드보다 넓으면 카드를 이름표 가운데에 둔다(옆 카드 이름표와 겹치지 않게)
			r.position.x += (lw - r.size.x) / 2.0
			cv.set_rect(r.position, kk, true)
		cards.append({"uid": f.card, "view": cv, "rect": r, "who": f.who})
		x += maxf(r.size.x, lw) + 14.0
	var bs := 92.0 * u
	map_rect = Rect2(Vector2(1920 - 22 - bs, 20), Vector2(bs, bs))
	queue_redraw()


func _process(d: float) -> void:
	_t += d
	refresh()
	queue_redraw()


func _draw() -> void:
	var u := _u()
	var st: Dictionary = G.ctl.st
	var f := Assets.font("sans_bold")
	for c in cards:
		var r: Rect2 = c.rect
		# 붉은 실이 걸린 듯 테두리가 맥박친다
		var p := 0.5 + 0.5 * sin(_t * 3.0)
		draw_style_box(UI.box(Color(0, 0, 0, 0), Color(1, 0.16, 0.24, 0.35 + 0.35 * p), int(10 * u), int(3 * u)), r.grow(3 * u))
		var nm := Rules.card_name(st.cards[c.uid].id, false, Rules.level(st, c.uid)) if st.cards.has(c.uid) else ""
		var fs := int(20 * u)
		var tw := f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var tr := Rect2(r.position.x + r.size.x / 2.0 - tw / 2.0 - 8 * u, r.end.y + 6 * u, tw + 16 * u, fs + 10 * u)
		draw_style_box(UI.box(Color(0.04, 0.0, 0.01, 0.85), Color("#7a0010"), int(6 * u), 1), tr)
		draw_string(f, Vector2(tr.position.x + 8 * u, tr.position.y + fs * 0.98), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#ffb6bd"))
	# 지도 버튼
	var mr := map_rect
	draw_style_box(UI.box(Color(0.06, 0.04, 0.03, 0.85), UI.GOLD, int(12 * u), int(2 * u)), mr)
	var c0 := mr.get_center() + Vector2(0, -8 * u)
	var w := mr.size.x * 0.46
	var pts := PackedVector2Array([c0 + Vector2(-w / 2, -w * 0.32), c0 + Vector2(-w / 6, -w * 0.42), c0 + Vector2(w / 6, -w * 0.32), c0 + Vector2(w / 2, -w * 0.42),
		c0 + Vector2(w / 2, w * 0.32), c0 + Vector2(w / 6, w * 0.42), c0 + Vector2(-w / 6, w * 0.32), c0 + Vector2(-w / 2, w * 0.42)])
	draw_colored_polygon(pts, Color("#d9c9a8"))
	draw_line(c0 + Vector2(-w / 6, -w * 0.42), c0 + Vector2(-w / 6, w * 0.32), Color("#6a5a40"), 2.0 * u)
	draw_line(c0 + Vector2(w / 6, -w * 0.32), c0 + Vector2(w / 6, w * 0.42), Color("#6a5a40"), 2.0 * u)
	draw_circle(c0 + Vector2(w * 0.1, 0), 4.0 * u, UI.RED)
	draw_string(f, Vector2(mr.position.x, mr.end.y - 10 * u), G.ui("map"), HORIZONTAL_ALIGNMENT_CENTER, mr.size.x, int(18 * u), Color("#f6e7c8"))


## 이 점(무대 좌표)이 운명 카드·지도 버튼 위인가
func hit(p: Vector2) -> bool:
	if big != null or (map != null and map.visible):
		return true
	if map_rect.grow(6).has_point(p):
		return true
	for c in cards:
		if c.rect.grow(6).has_point(p):
			return true
	return false


func tap(p: Vector2) -> void:
	if big != null:
		close_big()
		return
	if map != null and map.visible:
		return
	if map_rect.grow(6).has_point(p):
		open_map()
		return
	for c in cards:
		if c.rect.grow(6).has_point(p):
			show_big(str(c.uid))
			return


func _gui_input(_e: InputEvent) -> void:
	pass


## 운명 카드를 크게 (탭하면 닫힘)
func show_big(uid: String) -> void:
	var st: Dictionary = G.ctl.st
	big = Control.new()
	big.size = Vector2(1920, 1080)
	big.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0, 0.01, 0.72)
	dim.size = big.size
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	big.add_child(dim)
	var cv := CardView.new()
	big.add_child(cv)
	cv.setup_face(st, uid)
	var kk := 2.1
	cv.set_rect(Vector2(960 - CardView.W * kk / 2.0, 540 - CardView.H * kk / 2.0 - 20), kk, true)
	cv.smooth = false
	cv.taut = 1.0
	var hint := UI.label(G.ui("tapClose"), int(22 * _u()), Color("#bfa9ad"), "sans", HORIZONTAL_ALIGNMENT_CENTER)
	hint.position = Vector2(0, 1030)
	hint.size = Vector2(1920, 40)
	big.add_child(hint)
	big.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			big.accept_event()
			close_big())
	big.modulate.a = 0.0
	add_child(big)
	FX.anim(220, [{"a": 0.0}, {"a": 1.0}], func(v): if is_instance_valid(big): big.modulate.a = v.a, {"node": big})
	G.ctl.note("fate card big " + str(st.cards[uid].id))


func close_big() -> void:
	if big:
		big.queue_free()
	big = null


## 처음 지도가 열릴 때(갈림길): 지도 안내를 다 읽고 닫을 때까지 기다린다
func open_map_first() -> void:
	if map == null:
		map = MapView.new()
		map.z_index = 10
		add_child(map)
	# 지도 안내 대사는 지도 판(가운데)과 겹치지 않게 화면 왼쪽 위 대사창으로
	var dock := G.dialog.dock
	G.dialog.dock = ""
	G.dialog.relayout()
	map.open(true)
	await map.closed
	G.dialog.dock = dock
	G.dialog.relayout()


func open_map() -> void:
	if map == null:
		map = MapView.new()
		map.z_index = 10
		add_child(map)
	map.open(false)


func test_state() -> Dictionary:
	var st: Dictionary = G.ctl.st
	return {"cards": cards.map(func(c): return {"id": st.cards[c.uid].id if st.cards.has(c.uid) else "", "lv": Rules.level(st, c.uid),
		"rect": [c.rect.position.x, c.rect.position.y, c.rect.size.x, c.rect.size.y]}),
		"map": [map_rect.position.x, map_rect.position.y, map_rect.size.x, map_rect.size.y], "big": big != null, "mapOpen": map != null and map.visible}
