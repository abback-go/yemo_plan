## card_view.gd — 카드 한 장. 카드 앞면은 SubViewport(240×360 의 K배)에 글자·그림으로 그려 두고,
## 그 그림을 네 모서리(원근 사각형)에 맞춰 격자 메시로 그린다 → HTML 판 matrix3d 와 같은 원근 카드.
## 손패 자리 사이를 옮겨 갈 때는 모서리가 부드럽게 따라간다(CSS transition .22s ease-out 과 비슷하게).
class_name CardView
extends Node2D

const K := 2.0          # 카드 앞면 해상도 배율
const W := 240.0
const H := 360.0
const GRID := 8         # 원근 사각형을 나누는 칸 수

var uid := ""
var card_id := ""
var vp: SubViewport
var face: Control
var tex: Texture2D       # 앞면(뷰포트) 또는 뒷면 그림
var corners := PackedVector2Array()
var target := PackedVector2Array()
var smooth := true
var alpha := 1.0
var bright := 1.0
var glow := 0.0          # 낼 수 있음(금빛 테두리)
var taut := 0.0          # 죽음 카드가 팽팽(붉은 빛)
var shadow := 0.0        # 확대했을 때 그림자
var omen_blur := 0.0     # 0 = 또렷, 1 = 누구인지 알아볼 수 없음 (빈 캠프의 다음 죽음 카드)
var _parts := {}
var _state_key := ""
var _blur_mat: ShaderMaterial


static func rect_corners(pos: Vector2, k: float) -> PackedVector2Array:
	return PackedVector2Array([pos, pos + Vector2(W * k, 0), pos + Vector2(W * k, H * k), pos + Vector2(0, H * k)])


func _init() -> void:
	corners = rect_corners(Vector2.ZERO, 1.0)
	target = corners.duplicate()


## 뒷면 카드 (마녀가 쥔 덱)
func setup_back() -> void:
	tex = Assets.svg("card_back", CardArt.SVG.__back, 2.0)


## 앞면 카드
func setup_face(st: Dictionary, p_uid: String) -> void:
	uid = p_uid
	vp = SubViewport.new()
	vp.size = Vector2i(int(W * K), int(H * K))
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(vp)
	face = Control.new()
	face.size = Vector2(vp.size)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vp.add_child(face)
	tex = vp.get_texture()
	build(st)


## 흐린 죽음 카드 (누구인지 알아볼 수 없다 — 빈 캠프)
func setup_unknown() -> void:
	vp = SubViewport.new()
	vp.size = Vector2i(int(W * K), int(H * K))
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)
	face = Control.new()
	face.size = Vector2(vp.size)
	vp.add_child(face)
	tex = vp.get_texture()
	var bg := UI.panel(UI.box(Color("#0a0405"), Color("#3a0a10"), int(14 * K), int(2 * K)))
	bg.size = face.size
	face.add_child(bg)
	var fog := UI.tex_rect(UI.grad([[0, Color(0.85, 0.2, 0.25, 0.95)], [0.4, Color(0.5, 0.08, 0.12, 0.8)], [1, Color(0.1, 0.02, 0.04, 0)]], "radial", 128, 128, Vector2(0.5, 0.42), 0.55), Rect2(Vector2(10, 10) * K, Vector2(220, 300) * K))
	face.add_child(fog)
	if Assets.ok("card_frame.png"):
		var fr := UI.tex_rect(Assets.tex("card_frame.png"), Rect2(Vector2.ZERO, face.size))
		fr.modulate = Color(1.3, 1.1, 1.1)
		face.add_child(fr)
	# 사람 모양의 흐린 윤곽 (누구인지는 알아볼 수 없다)
	var sil := Control.new()
	sil.size = face.size
	sil.draw.connect(func():
		sil.draw_circle(Vector2(120, 120) * K, 34 * K, Color(0.05, 0.0, 0.02, 0.55))
		sil.draw_colored_polygon(PackedVector2Array([Vector2(60, 230) * K, Vector2(180, 230) * K, Vector2(150, 150) * K, Vector2(90, 150) * K]), Color(0.05, 0.0, 0.02, 0.5)))
	face.add_child(sil)
	omen_blur = 1.0


func _tint_mat(mode: int) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = preload("res://ui/shaders/tint.gdshader")
	m.set_shader_parameter("mode", mode)
	return m


func _owner_name(who) -> String:
	return G.name_of(str(who)) if who != null and str(who) != "" else ""


## 앞면을 만든다 (그림·글자). 카드 id 가 바뀌면(유품 등) 다시 부른다
func build(st: Dictionary) -> void:
	for c in face.get_children():
		c.queue_free()
	_parts = {}
	_state_key = ""
	var card: Dictionary = st.cards[uid]
	card_id = card.id
	var d: Dictionary = GameData.D.cards[card.id]
	var up: bool = Rules.is_up(st, uid)
	var kind: String = d.kind
	var tone: String = d.owner if kind in ["witch", "ally"] else kind
	var bgc := {"witch": Color("#170e18"), "hero": Color("#181a22"), "warrior": Color("#1b1510"), "archer": Color("#121b13"),
		"death": Color("#040304"), "inherit": Color("#1c0305"), "relic": Color("#161616"), "wound": Color("#140a0b")}
	if kind == "wound":
		tone = "wound"
	var s := K
	var bg := UI.panel(UI.box(bgc.get(tone, Color("#15161b")), Color.TRANSPARENT, int(14 * s)))
	bg.size = face.size
	face.add_child(bg)
	_parts.bg = bg
	# 그림 창
	var art_rect := Rect2(Vector2(22, 24) * s, Vector2(201, 204) * s)
	var art_file: String = GameData.D.cardArtImg.get(card.id, "")
	var at: Texture2D = Assets.tex(art_file) if art_file != "" and Assets.ok(art_file) else Assets.svg("art_" + card.id, CardArt.SVG.get(card.id, CardArt.SVG.curse_flame), 2.0)
	var art := UI.cover_rect(at, art_rect)
	if kind == "relic":
		art.material = _tint_mat(1)
	face.add_child(art)
	_parts.art = art
	# 프레임
	if Assets.ok("card_frame.png"):
		var fr := UI.tex_rect(Assets.tex("card_frame.png"), Rect2(Vector2.ZERO, face.size))
		var mode: int = {"relic": 1, "death": 2, "inherit": 3}.get(kind, 0)
		if mode > 0:
			fr.material = _tint_mat(mode)
		face.add_child(fr)
	# 태그 (보존·상속 등)
	var tags: Array = d.get("tags", [])
	var tx := 26.0
	for t in tags:
		var tl := UI.label(str(t), int(12 * s), Color("#ff9aa4"), "sans_bold")
		var tp := UI.panel(UI.box(Color(0, 0, 0, 0.7), Color("#7a2232"), int(6 * s), int(1 * s)))
		var ts := tl.get_combined_minimum_size()
		tp.position = Vector2(tx, 204) * s
		tp.size = ts + Vector2(12, 2) * s
		tl.position = Vector2(6, 1) * s
		tp.add_child(tl)
		face.add_child(tp)
		tx += tp.size.x / s + 4
	# 이름
	var name_col: Color = {"death": Color("#ff6b76"), "inherit": Color("#ffb0b6"), "relic": Color("#d8d8d8"), "wound": Color("#c98a90")}.get(kind, Color("#f4ead6"))
	var nm := UI.label(Rules.card_name(card.id, up), int(20 * s), name_col, "serif_bold", HORIZONTAL_ALIGNMENT_CENTER, int(3 * s))
	nm.position = Vector2(10, 241) * s
	nm.size = Vector2(220, 30) * s
	nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if up:
		nm.add_theme_color_override("font_color", Color("#ffe28a"))
	face.add_child(nm)
	# 설명
	var small: bool = kind in ["death", "inherit"]
	var fs := 13.5 if small else 15.0
	var cc := CenterContainer.new()
	cc.position = Vector2(24, 270) * s
	cc.size = Vector2(192, 60) * s
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rt := UI.rich(int(fs * s), Color("#e7dfd2"))
	rt.add_theme_font_size_override("bold_font_size", int((fs + 2) * s))
	rt.custom_minimum_size = Vector2(192, 0) * s
	rt.add_theme_constant_override("line_separation", int(-1 * s))
	var txt := Rules.card_text(card.id, up, func(v): return "[b][color=#ffcf6a]" + v + "[/color][/b]")
	rt.text = "[center]" + txt + "[/center]"
	cc.add_child(rt)
	face.add_child(cc)
	# 주인
	var owner := ""
	match kind:
		"death": owner = "죽음 · " + _owner_name(d.get("ally"))
		"relic": owner = "유품 · " + _owner_name(d.owner)
		"inherit": owner = "상속 · " + _owner_name(d.get("from"))
		"wound": owner = "상처 · " + _owner_name(card.get("woundOf", ""))
		_: owner = _owner_name(d.owner)
	var ocol: Color = {"hero": Color("#cfd3dd"), "warrior": Color("#c9a985"), "archer": Color("#9fc38f"), "witch": Color("#c79ab0")}.get(str(d.owner), Color("#a8a2a0"))
	var ow := UI.label(owner, int(11 * s), ocol, "sans_bold", HORIZONTAL_ALIGNMENT_CENTER)
	ow.position = Vector2(0, 360 - 16 - 16) * s
	ow.size = Vector2(240, 16) * s
	face.add_child(ow)
	# 비용
	if kind != "wound":
		var cost := Panel.new()
		cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cost.position = Vector2(15, 16) * s
		cost.size = Vector2(37, 37) * s
		face.add_child(cost)
		var cl := UI.label(str(d.cost), int(22 * s), Color.WHITE, "serif_black", HORIZONTAL_ALIGNMENT_CENTER, int(3 * s))
		cl.size = cost.size
		cl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cost.add_child(cl)
		_parts.cost = cost
		_parts.cost_l = cl
	# 쓰러짐·사용 불가 표시
	var blk := UI.label("", int(26 * s), Color("#ff6b76"), "serif_black", HORIZONTAL_ALIGNMENT_CENTER, int(6 * s))
	blk.size = Vector2(240, 40) * s
	blk.position = Vector2(0, 110) * s
	blk.pivot_offset = blk.size / 2.0
	blk.rotation_degrees = -12
	blk.visible = false
	face.add_child(blk)
	_parts.block = blk
	# 잠금(죽음 카드, 1회차): 어둡게 가라앉히고 붉은 실을 감고 자물쇠
	if d.has("lockedUntil"):
		var lock := Control.new()
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock.size = face.size
		lock.draw.connect(_draw_lock.bind(lock))
		lock.visible = false
		face.add_child(lock)
		_parts.lock = lock
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE


## 잠금 덮개: 어둠 + 카드를 감은 붉은 실 + 자물쇠
func _draw_lock(c: Control) -> void:
	var s := K
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0, 0, 0, 0.5))
	var red := Color(0.86, 0.08, 0.16, 0.95)
	# 대각선으로 감긴 실 세 가닥 (카드 가장자리를 넘어 감긴 느낌으로 끝에 매듭)
	var lines := [[Vector2(-4, 70), Vector2(244, 150)], [Vector2(-4, 230), Vector2(244, 120)], [Vector2(-4, 300), Vector2(244, 320)]]
	for ln in lines:
		var a: Vector2 = ln[0] * s
		var b: Vector2 = ln[1] * s
		c.draw_line(a, b, Color(0.3, 0, 0.04, 0.8), 6 * s, true)
		c.draw_line(a, b, red, 3 * s, true)
	# 자물쇠
	var ctr := Vector2(120, 168) * s
	var body := Rect2(ctr + Vector2(-30, -8) * s, Vector2(60, 46) * s)
	c.draw_arc(ctr + Vector2(0, -10) * s, 20 * s, PI, TAU, 24, Color("#8a6a3a"), 8 * s, true)
	c.draw_arc(ctr + Vector2(0, -10) * s, 20 * s, PI, TAU, 24, Color("#d9b46a"), 4 * s, true)
	var sb := UI.box(Color("#3a2410"), Color("#d9b46a"), int(6 * s), int(3 * s))
	c.draw_style_box(sb, body)
	c.draw_circle(ctr + Vector2(0, 10) * s, 6 * s, Color("#0a0405"))
	c.draw_rect(Rect2(ctr + Vector2(-2.5, 12) * s, Vector2(5, 14) * s), Color("#0a0405"))


## 상태 표시(비용·낼 수 있음·쓰러짐·잠김). 바뀐 것이 있을 때만 앞면을 다시 그린다
func refresh(st: Dictionary) -> void:
	if vp == null or not st.cards.has(uid):
		return
	if st.cards[uid].id != card_id:
		build(st)
	var d := Rules.def(st, uid)
	var b = st.battle
	var blocked := Rules.owner_blocked(st, uid) if b != null else ""
	var locked := Rules.is_locked(st, uid)
	var cost := Rules.cost(st, uid) if b != null else int(d.cost)
	var poor: bool = b != null and b.phase == "player" and cost > int(b.energy) and not d.get("unplayable", false)
	var key := "%s|%d|%s|%s|%s" % [blocked, cost, poor, locked, Rules.is_up(st, uid)]
	if key == _state_key:
		return
	_state_key = key
	if _parts.has("cost"):
		_parts.cost_l.text = str(cost)
		var free := cost < int(d.cost)
		var col := Color("#e0a020") if free else Color("#b3121f")
		if d.kind == "death":
			col = Color("#2a2a2a")
		var sb := UI.box(col, Color("#1b0b0e"), int(19 * K), int(2 * K))
		if poor:
			sb.bg_color = Color("#4a3a3c")
			_parts.cost_l.add_theme_color_override("font_color", Color("#ff9aa0"))
		else:
			_parts.cost_l.add_theme_color_override("font_color", Color.WHITE if not free else Color("#3a2000"))
		_parts.cost.add_theme_stylebox_override("panel", sb)
	var dark: bool = blocked != "" and d.kind != "death"
	_parts.art.modulate = Color(0.45, 0.45, 0.45) if dark else Color.WHITE
	_parts.bg.modulate = Color(0.5, 0.5, 0.5) if dark else Color.WHITE
	_parts.block.visible = dark
	_parts.block.text = (G.ui("down") if blocked.contains("쓰러진") else G.ui("unusable")) if dark else ""
	if _parts.has("lock"):
		_parts.lock.visible = locked
		_parts.lock.queue_redraw()
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE


func redraw_face() -> void:
	if vp:
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE


# ───────── 위치 ─────────
func set_quad(q: PackedVector2Array, instant := false) -> void:
	target = q.duplicate()
	if instant or corners.size() != 4:
		corners = q.duplicate()
	queue_redraw()


func set_rect(pos: Vector2, k: float, instant := false) -> void:
	set_quad(rect_corners(pos, k), instant)


func center() -> Vector2:
	return (corners[0] + corners[1] + corners[2] + corners[3]) / 4.0


func top_point() -> Vector2:
	return (corners[0] + corners[1]) / 2.0 + (corners[3] - corners[0]).normalized() * 4.0


func contains(p: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(p, corners)


func _process(delta: float) -> void:
	if not smooth:
		if corners != target:
			corners = target.duplicate()
			queue_redraw()
		return
	var moving := false
	var k := 1.0 - exp(-delta * FX.speed / 0.055)
	for i in 4:
		var d := target[i] - corners[i]
		if d.length_squared() > 0.04:
			corners[i] += d * k
			moving = true
		else:
			corners[i] = target[i]
	if moving or glow > 0 or taut > 0:
		queue_redraw()


# 단위 정사각형 → 사각형 투영 (hand.js sq2q)
static func homography(q: PackedVector2Array) -> PackedFloat32Array:
	var x0 := q[0].x; var y0 := q[0].y; var x1 := q[1].x; var y1 := q[1].y
	var x2 := q[2].x; var y2 := q[2].y; var x3 := q[3].x; var y3 := q[3].y
	var dx1 := x1 - x2; var dx2 := x3 - x2; var dx3 := x0 - x1 + x2 - x3
	var dy1 := y1 - y2; var dy2 := y3 - y2; var dy3 := y0 - y1 + y2 - y3
	var g := 0.0
	var h := 0.0
	if absf(dx3) > 1e-9 or absf(dy3) > 1e-9:
		var det := dx1 * dy2 - dx2 * dy1
		if absf(det) > 1e-9:
			g = (dx3 * dy2 - dx2 * dy3) / det
			h = (dx1 * dy3 - dx3 * dy1) / det
	return PackedFloat32Array([x1 - x0 + g * x1, x3 - x0 + h * x3, x0, y1 - y0 + g * y1, y3 - y0 + h * y3, y0, g, h])


static func project(m: PackedFloat32Array, u: float, v: float) -> Vector2:
	var w := m[6] * u + m[7] * v + 1.0
	return Vector2((m[0] * u + m[1] * v + m[2]) / w, (m[3] * u + m[4] * v + m[5]) / w)


func _draw() -> void:
	if tex == null or corners.size() != 4 or alpha <= 0.001:
		return
	var q := corners
	# 확대 그림자
	if shadow > 0:
		var c := (q[0] + q[2]) / 2.0
		for i in 3:
			var grow := 1.0 + 0.04 * (i + 1)
			var poly := PackedVector2Array()
			for p in q:
				poly.append(c + (p - c) * grow + Vector2(0, 10))
			draw_colored_polygon(poly, Color(0, 0, 0, 0.22 * shadow * alpha))
	# 붉은 빛(죽음 카드가 팽팽할 때)
	if taut > 0:
		var cc := (q[0] + q[2]) / 2.0
		for i in 4:
			var grow2 := 1.0 + 0.03 * (i + 1)
			var poly2 := PackedVector2Array()
			for p in q:
				poly2.append(cc + (p - cc) * grow2)
			draw_colored_polygon(poly2, Color(1, 0.12, 0.2, 0.16 * taut * alpha))
	# 앞면 (원근 격자)
	var m := homography(q)
	var n := GRID if not _is_rect(q) else 1
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	var col := Color(bright, bright, bright, alpha)
	for j in n + 1:
		for i in n + 1:
			var u := float(i) / n
			var v := float(j) / n
			pts.append(project(m, u, v))
			uvs.append(Vector2(u, v))
			cols.append(col)
	var idx := PackedInt32Array()
	for j in n:
		for i in n:
			var a := j * (n + 1) + i
			idx.append_array([a, a + 1, a + n + 2, a, a + n + 2, a + n + 1])
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), idx, pts, cols, uvs, PackedInt32Array(), PackedFloat32Array(), tex.get_rid())
	# 낼 수 있음: 금빛 테두리
	if glow > 0:
		var loop := PackedVector2Array([q[0], q[1], q[2], q[3], q[0]])
		draw_polyline(loop, Color(1, 0.7, 0.3, 0.3 * glow * alpha), 9.0, true)
		draw_polyline(loop, Color(1, 0.82, 0.47, 0.6 * glow * alpha), 2.5, true)
	if taut > 0:
		var loop2 := PackedVector2Array([q[0], q[1], q[2], q[3], q[0]])
		draw_polyline(loop2, Color(1, 0.2, 0.28, 0.8 * taut * alpha), 3.0, true)


func _is_rect(q: PackedVector2Array) -> bool:
	return absf(q[0].y - q[1].y) < 0.5 and absf(q[3].y - q[2].y) < 0.5 and absf(q[0].x - q[3].x) < 0.5 and absf(q[1].x - q[2].x) < 0.5


## 흐린 카드: 블러 셰이더 (빈 캠프의 다음 죽음 카드)
func apply_blur(amount: float) -> void:
	omen_blur = amount
	if amount <= 0.0:
		material = null
		return
	if _blur_mat == null:
		_blur_mat = ShaderMaterial.new()
		_blur_mat.shader = preload("res://ui/shaders/blur.gdshader")
	_blur_mat.set_shader_parameter("amount", amount)
	material = _blur_mat
