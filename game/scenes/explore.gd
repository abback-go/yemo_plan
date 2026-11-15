## explore.gd — 탐색 화면(마녀 1인칭): 배경 위 동료 뒷모습 3명, 왼쪽 아래 랜턴 든 왼손, 길 위의 아이콘(코드로 그림),
## 왼쪽 가장자리 세로 층 표시(돌판), 지도. 길을 누르면 설명, 한 번 더 누르면 걸어 들어간다(카메라 접근·발걸음 흔들림·랜턴 흔들림·
## 동료가 앞서 걸어 들어가며 작아짐·암전). 배치는 game_data.gd "explore" / "map", 문구는 script_data.gd "explore" / "map".
class_name ExploreScene
extends Control

signal tapped

var place := ""
var conf := {}
var world: Node2D
var bg: Sprite2D
var paths_node: Node2D
var allies_node: Node2D
var ally_spr := {}
var lantern: Node2D
var lantern_spr: Sprite2D
var hud: Control
var floor_ind: Control
var party_hud: Control
var desc: Control
var desc_title: Label
var desc_text: Label
var desc_hint: Label
var map: MapView
var selected := ""
var chosen := ""
var walking := false
var cam_c := Vector2(960, 540)
var cam_z := 1.0
var bob := 0.0
var sway := 0.0
var _t := 0.0
var _wait: DialogBox.Waiter
var accept_input := false


func setup(p: String) -> void:
	place = p
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = Vector2(1920, 1080)
	var ex: Dictionary = GameData.D.explore
	conf = ex.get(p, {"bg": "bg_cathedral.png", "paths": []})
	world = Node2D.new()
	add_child(world)
	bg = Sprite2D.new()
	bg.texture = Assets.tex(conf.bg)
	bg.centered = false
	bg.scale = Vector2(1920, 1080) / Assets.size(conf.bg)
	world.add_child(bg)
	paths_node = Node2D.new()
	world.add_child(paths_node)
	paths_node.draw.connect(_draw_paths)
	# 동료 뒷모습 (살아 있는 동료만)
	allies_node = Node2D.new()
	add_child(allies_node)
	var st: Dictionary = G.ctl.st
	for id in GameData.D.party.order:
		if st.party.allies[id].status == "dead":
			continue
		var a: Dictionary = ex.allies[id]
		var file: String = GameData.D.layout.allies[id].img
		var sz := Assets.size(file)
		var h: float = a.h
		var w := h * sz.x / sz.y
		var spr := Sprite2D.new()
		spr.texture = Assets.tex(file)
		spr.centered = false
		spr.offset = Vector2(-sz.x / 2.0, 0)
		spr.scale = Vector2(h / sz.y, h / sz.y)
		spr.position = Vector2(a.x, a.top)
		spr.set_meta("base", spr.position)
		spr.set_meta("w", w)
		spr.set_meta("s0", h / sz.y)
		spr.set_meta("h", h)
		allies_node.add_child(spr)
		ally_spr[id] = spr
	# 랜턴 든 왼손
	var lc: Dictionary = ex.lantern
	lantern = Node2D.new()
	var pv := Vector2(lc.pivot[0], lc.pivot[1]) * float(lc.scale)
	lantern.position = Vector2(lc.x, lc.y) + pv
	add_child(lantern)
	lantern_spr = Sprite2D.new()
	lantern_spr.texture = Assets.tex(lc.img)
	lantern_spr.centered = false
	lantern_spr.scale = Vector2.ONE * float(lc.scale)
	lantern_spr.position = -pv
	lantern.add_child(lantern_spr)
	# 랜턴 불빛
	var glow := UI.tex_rect(UI.grad([[0, Color(1, 0.7, 0.3, 0.22)], [1, Color(0, 0, 0, 0)]], "radial", 128, 128, Vector2(0.5, 0.5), 0.5), Rect2(-200, -120, 700, 700))
	glow.name = "glow"
	lantern.add_child(glow)
	lantern.move_child(glow, 0)
	# HUD: 층 표시·동료 HP
	hud = Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.size = size
	add_child(hud)
	floor_ind = Control.new()
	floor_ind.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floor_ind.position = Vector2(18, 70)
	floor_ind.size = Vector2(110, 520)
	floor_ind.draw.connect(_draw_floor_ind)
	hud.add_child(floor_ind)
	var fl := UI.label(G.ui("map"), 22, Color("#f0e2c8"), "serif_bold", HORIZONTAL_ALIGNMENT_CENTER, 4)
	fl.position = Vector2(0, 470)
	fl.size = Vector2(110, 30)
	floor_ind.add_child(fl)
	party_hud = PartyHud.new()
	party_hud.position = Vector2(1920 - 24 - 560, 1080 - 24 - 120)
	party_hud.size = Vector2(560, 120)
	hud.add_child(party_hud)
	# 길 설명
	desc = Control.new()
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc.visible = false
	desc.draw.connect(func(): desc.draw_style_box(UI.box(Color(0.05, 0.03, 0.03, 0.92), UI.GOLD, 12, 2), Rect2(Vector2.ZERO, desc.size)))
	hud.add_child(desc)
	desc_title = UI.label("", 34, Color("#f6e7c8"), "serif_bold")
	desc.add_child(desc_title)
	desc_text = UI.label("", 28, Color("#e8ddd2"), "sans")
	desc_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_child(desc_text)
	desc_hint = UI.label(G.ui("pathTapAgain"), 22, Color("#ff9aa4"), "sans_bold", HORIZONTAL_ALIGNMENT_RIGHT)
	desc.add_child(desc_hint)
	map = MapView.new()
	map.visible = false
	add_child(map)
	_apply_cam()


func _apply_cam() -> void:
	world.scale = Vector2(cam_z, cam_z)
	world.position = Vector2(960, 540) - cam_c * cam_z + Vector2(0, bob)


func path_list() -> Array:
	return conf.get("paths", [])


func path_hit(p: Vector2) -> String:
	for pa in path_list():
		var c := Vector2(pa.x, pa.y)
		var r := Rect2(c.x - 170, c.y - 80, 340, 420)
		if p.distance_to(c) < 70 + 30 / maxf(0.3, FX.css_scale) or r.has_point(p):
			return pa.id
	return ""


func _draw_paths() -> void:
	if walking:
		return
	for pa in path_list():
		var c := Vector2(pa.x, pa.y)
		var hot := 1.0 if pa.id == selected else (0.35 + 0.25 * sin(_t * 2.4))
		Icons.medallion(paths_node, c, 52.0, pa.icon, hot)
		if pa.id == selected:
			paths_node.draw_arc(c, 70 + 4 * sin(_t * 5.0), 0, TAU, 48, Color(1, 0.8, 0.45, 0.8), 3.0, true)


func _draw_floor_ind() -> void:
	var ci := floor_ind
	var floors: Array = GameData.D.map.floors
	var cur: int = G.ctl.st.progress.floor
	var r := Rect2(Vector2(14, 0), Vector2(82, 460))
	ci.draw_style_box(UI.box(Color(0.04, 0.03, 0.035, 0.85), Color("#6a5a4a"), 10, 2), r)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(55, -12), Vector2(64, 0), Vector2(55, 12), Vector2(46, 0)]), Color("#b3121f"))
	var n := floors.size()
	for i in n:
		var f: Dictionary = floors[i]
		var y := 40.0 + i * (400.0 / maxf(1, n - 1)) * 0.9
		var on: bool = int(f.n) == cur
		if i > 0:
			ci.draw_line(Vector2(55, y - 70), Vector2(55, y - 14), Color(0.7, 0.08, 0.12, 0.6), 2.0)
		Icons.stone_tile(ci, Vector2(55, y), 56.0, on, f.get("locked", false))
		var lbl := str(G.S.map.floorShort).replace("{n}", str(f.n))
		var fnt := Assets.font("sans_bold")
		ci.draw_string(fnt, Vector2(26, y + 34), lbl, HORIZONTAL_ALIGNMENT_CENTER, 58, 15, Color("#f6e7c8") if on else Color(0.7, 0.66, 0.6, 0.6))
		if f.get("deathMark", false):
			Icons.death_mark(ci, Vector2(82, y - 8), 9.0, _t, 0.55)


func _process(delta: float) -> void:
	_t += delta
	paths_node.queue_redraw()
	floor_ind.queue_redraw()
	if not walking:
		var sw := sin(_t * 1.3) * 1.4
		lantern.rotation_degrees = sw
		var gl: Control = lantern.get_node("glow")
		gl.modulate.a = 0.85 + 0.15 * sin(_t * 7.0) + randf_range(-0.05, 0.05)
		# 동료 숨쉬기
		var i := 0
		for id in ally_spr:
			var s: Sprite2D = ally_spr[id]
			s.position = s.get_meta("base") + Vector2(0, -1.5 * (0.5 - 0.5 * cos(_t * TAU / 3.8 + i * 1.3)))
			i += 1


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
		accept_event()
		tap(get_local_mouse_position())


func tap(p: Vector2) -> void:
	if G.dialog.guide_open():
		G.dialog.advance()
		return
	if G.dialog.is_busy():
		G.dialog.advance()
	if map.visible:
		return
	if not accept_input or walking:
		return
	if Rect2(floor_ind.position, floor_ind.size).has_point(p):
		open_map()
		return
	var id := path_hit(p)
	if id == "":
		select("")
		return
	if id == selected:
		chosen = id
		if _wait:
			_wait.finish()
	else:
		select(id)


## 길을 누르면 그 길에 대한 설명이 나온다
func select(id: String) -> void:
	selected = id
	if id == "":
		desc.visible = false
		return
	var txt: Dictionary = G.S.explore.get(place, {}).get("paths", {}).get(id, {})
	desc_title.text = str(txt.get("title", id))
	desc_text.text = str(txt.get("desc", ""))
	var u := minf(FX.ui, 1.5)
	var w := 720.0
	desc.scale = Vector2(u, u)
	desc_title.position = Vector2(26, 18)
	desc_text.position = Vector2(26, 70)
	desc_text.size = Vector2(w - 52, 0)
	desc_text.custom_minimum_size = Vector2(w - 52, 0)
	var th := desc_text.get_combined_minimum_size().y
	desc.size = Vector2(w, 70 + th + 56)
	desc_hint.position = Vector2(w - 400, desc.size.y - 40)
	desc_hint.size = Vector2(374, 30)
	var pa := {}
	for x in path_list():
		if x.id == id:
			pa = x
	var px: float = pa.get("x", 960)
	desc.position = Vector2(clampf(px - w * u / 2.0, 140, 1920 - 20 - w * u), 640 - (desc.size.y * u - desc.size.y))
	desc.visible = true
	desc.queue_redraw()
	G.ctl.note("path select " + id)


func open_map(first := false) -> void:
	map.open(first)
	await map.closed


## 길을 고를 때까지 기다린 뒤 그 길로 걸어 들어간다. 반환: 고른 길 id
func choose() -> String:
	accept_input = true
	_wait = DialogBox.Waiter.new()
	if path_list().size() == 1 and G.autoguide:
		get_tree().create_timer(0.4).timeout.connect(func(): chosen = path_list()[0].id; _wait.finish())
	elif G.autoguide and G.params.has("path"):
		get_tree().create_timer(0.4).timeout.connect(func(): chosen = G.params.path; _wait.finish())
	await _wait.done
	accept_input = false
	desc.visible = false
	var vp := Vector2(960, 470)
	for pa in path_list():
		if pa.id == chosen:
			vp = Vector2(pa.vp[0], pa.vp[1])
	await walk(vp)
	return chosen


## 시험·바로 가기: 길을 고른다 (두 번 누른 것과 같다)
func pick(id: String) -> void:
	select(id)
	chosen = id
	if _wait:
		_wait.finish()


## 걸어 들어가는 연출: 카메라가 그 통로 쪽으로 다가가며 확대 + 발걸음 흔들림 + 랜턴 흔들림 + 동료가 앞서 걸어 들어가며 작아짐 → 암전
func walk(vp: Vector2) -> void:
	walking = true
	G.ctl.note("walk %s" % str(vp))
	var w: Dictionary = GameData.D.explore.walk
	var dur: float = w.duration
	var z1: float = w.zoom
	var steps: float = w.steps
	var bobh: float = w.bob
	var swy: float = w.sway
	var fade_at: float = w.fadeAt
	var shrink: float = w.allyShrink
	var lbase := lantern.position
	var faded := [false]
	var a := FX.anim(dur, [{"k": 0.0}, {"k": 1.0}], func(v):
		var k: float = v.k
		var e := k * k * (3.0 - 2.0 * k)
		cam_c = Vector2(960, 540).lerp(vp, e)
		cam_z = lerpf(1.0, z1, e * e)
		var ph := k * steps * PI
		bob = -absf(sin(ph)) * bobh
		_apply_cam()
		lantern.rotation_degrees = sin(ph) * swy
		lantern.position = lbase + Vector2(sin(ph * 0.5) * 6.0, absf(sin(ph)) * bobh * 1.6)
		# 동료가 앞서 걸어 들어가며 작아진다
		for id in ally_spr:
			var s: Sprite2D = ally_spr[id]
			var b: Vector2 = s.get_meta("base")
			var target := cam_to_screen(vp)
			var kk := clampf(k * 1.25, 0.0, 1.0)
			var sc := lerpf(1.0, shrink, kk)
			s.position = b.lerp(target + Vector2((b.x - 960) * 0.12, -float(s.get_meta("h")) * sc * 0.25), kk * kk) + Vector2(0, -absf(sin(ph + 0.6)) * bobh * 0.6)
			s.scale = Vector2.ONE * float(s.get_meta("s0")) * sc
			s.modulate.a = 1.0 - smoothstep(0.7, 1.0, kk)
		if k >= fade_at and not faded[0]:
			faded[0] = true
			FX.fade(1, dur * (1.0 - fade_at) * 0.9), {"node": self})
	await FX.until(a)
	await FX.fade(1, 120)
	walking = false


func cam_to_screen(p: Vector2) -> Vector2:
	return Vector2(960, 540) + (p - cam_c) * cam_z + Vector2(0, bob)


# ───────── 아래 오른쪽: 파티 HP ─────────
class PartyHud extends Control:
	var faces := {}

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var st: Dictionary = G.ctl.st
		var ids := ["noel"]
		for id in GameData.D.party.order:
			if st.party.allies[id].status != "dead":
				ids.append(id)
		var x := 0.0
		for id in ids:
			var t := TextureRect.new()
			t.texture = Assets.face_tex(id)
			t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			t.position = Vector2(x + 14, 4)
			t.size = Vector2(84, 84)
			t.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var m := ShaderMaterial.new()
			m.shader = preload("res://ui/shaders/circle.gdshader")
			t.material = m
			add_child(t)
			faces[id] = x
			x += 140
		size.x = x

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var st: Dictionary = G.ctl.st
		for id in faces:
			var x: float = faces[id]
			var c := Vector2(x + 56, 46)
			draw_circle(c, 46, Color("#2a1418"))
			draw_arc(c, 45, 0, TAU, 40, Color("#c9a24a"), 2.0, true)
			var hp: int
			var mx: int
			if id == "noel":
				hp = st.party.witch.hp
				mx = st.party.witch.maxHp
			else:
				hp = st.party.allies[id].hp
				mx = st.party.allies[id].maxHp
			var bar := Rect2(x + 6, 98, 100, 12)
			draw_style_box(UI.box(Color("#2a0b10"), Color.BLACK, 5, 1), bar)
			var k := clampf(float(hp) / maxf(1.0, mx), 0, 1)
			draw_style_box(UI.box(Color("#d02a3a"), Color.TRANSPARENT, 4), Rect2(bar.position + Vector2(1, 1), Vector2((bar.size.x - 2) * k, 10)))
			var f := Assets.font("sans_bold")
			draw_string(f, Vector2(x + 6, 94), "%d/%d" % [hp, mx], HORIZONTAL_ALIGNMENT_RIGHT, 100, 15, Color("#ffd0d4"))
