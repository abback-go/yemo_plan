## scenes.gd — 타이틀 / 비주얼노벨(캠프·이벤트·계단·빈 캠프) / 탐색 / 용사 사망 컷신(C1~C6) / 탈출 / 종료 / 전멸 / 카드를 내지 않은 미래.
## HTML 판 scenes.js 를 옮기고 탐색·이벤트·빈 캠프·되감기 연출을 더했다. 장면은 하나씩만 열린다(current).
class_name Scenes
extends Node2D

signal cutscene_done

var current: Node = null
var current_name := ""
var cut := {}
var cut_root: Control = null   # 컷신(데스신)은 지금 장면(탑뷰 등)을 지우지 않고 그 위에 덮는다
var cut_key := "hero"
var cut_level := 1
var overlays: Array = []        # 운명 선택·카드 획득 등 지금 장면 위에 뜬 화면
var cut_log: Array = []
var _waiters: Array = []


func is_open() -> bool:
	return current != null and is_instance_valid(current)


func clear() -> void:
	if is_open():
		current.queue_free()
	current = null
	current_name = ""
	if cut_root != null and is_instance_valid(cut_root):
		cut_root.queue_free()
	cut_root = null
	for o in overlays:
		if is_instance_valid(o):
			o.queue_free()
	overlays = []
	for w in _waiters:
		w.finish()
	_waiters = []
	cut = {}


## 컷신·운명 선택 등 지금 장면 위에 덮인 화면이 있는가 (탑뷰 입력을 멈춘다)
func overlay_open() -> bool:
	for o in overlays:
		if is_instance_valid(o) and o.is_inside_tree():
			return true
	return cut_root != null and is_instance_valid(cut_root)


func mount(node: Node, name: String) -> void:
	clear()
	add_child(node)
	current = node
	current_name = name
	G.ctl.note("scene " + name)


func _wait_or_tap(ms: float) -> void:
	var w := DialogBox.Waiter.new()
	_waiters.append(w)
	if not cut.is_empty():
		cut.waiter = w
	get_tree().create_timer(FX.ms(ms) / 1000.0).timeout.connect(w.finish)
	if not w.finished:
		await w.done
	_waiters.erase(w)


# ───────── 타이틀 ─────────
func title() -> void:
	G.ctl.in_battle = false
	G.view.clear()
	G.dialog.clear()
	var root := Control.new()
	root.size = Vector2(1920, 1080)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := UI.tex_rect(UI.grad([[0, Color("#2a0a10")], [0.55, Color("#0b0507")], [1, Color("#000000")]], "radial", 256, 256, Vector2(0.5, 0.6), 0.75), Rect2(0, 0, 1920, 1080))
	root.add_child(bg)
	var line := UI.tex_rect(UI.grad([[0, Color(1, 0.16, 0.24, 0)], [0.5, Color(1, 0.16, 0.24, 0.55)], [1, Color(1, 0.16, 0.24, 0)]], "h", 256, 2), Rect2(0, 539, 1920, 2))
	root.add_child(line)
	var m: Dictionary = G.S.meta
	var t := UI.label(m.title, 110, Color("#efe3e5"), "serif_wide", HORIZONTAL_ALIGNMENT_CENTER, 12)
	t.add_theme_color_override("font_outline_color", Color(0.45, 0.04, 0.08, 0.45))
	t.position = Vector2(0, 330)
	t.size = Vector2(1920, 150)
	root.add_child(t)
	var sub := UI.label(m.subtitle, 30, Color("#b9a3a7"), "serif", HORIZONTAL_ALIGNMENT_CENTER)
	sub.position = Vector2(0, 500)
	sub.size = Vector2(1920, 50)
	root.add_child(sub)
	var b := UI.button(m.startButton, 36, func(): G.ctl.start_tutorial())
	b.fit(Vector2(80, 18))
	b.position = Vector2(960 - b.size.x / 2.0, 640)
	b.name = "start"
	root.add_child(b)
	# 시험판: 2층·3층부터 바로 (사용자가 운명 흐름만 다시 해 볼 수 있게)
	var jx := 960.0
	var jbs := []
	for j in [["floor2", m.get("fromFloor2", "2층부터")], ["floor3", m.get("fromFloor3", "3층부터")]]:
		var sc: String = j[0]
		var jb := UI.button(str(j[1]), 24, func(): G.ctl.jump(sc), "sans_bold")
		jb.style_kind = "small"
		jb.fit(Vector2(36, 10))
		jb.name = "from_" + sc
		root.add_child(jb)
		jbs.append(jb)
	var tw := 0.0
	for jb in jbs:
		tw += jb.size.x
	tw += 24.0 * (jbs.size() - 1)
	jx = 960.0 - tw / 2.0
	for jb in jbs:
		jb.position = Vector2(jx, 640 + b.size.y + 40)
		jx += jb.size.x + 24.0
	var note := UI.label(m.note, 22, Color("#7d6f72"), "sans", HORIZONTAL_ALIGNMENT_CENTER)
	note.position = Vector2(0, 1000)
	note.size = Vector2(1920, 40)
	root.add_child(note)
	mount(root, "title")
	FX.fade(0, 300)


# ───────── 비주얼노벨 ─────────
func camp() -> void:
	await vn("camp")


func vn(name: String) -> void:
	G.ctl.in_battle = false
	G.view.clear()
	var v := VnScene.new()
	v.setup(name)
	mount(v, "vn:" + name)
	await FX.fade(0, 500)
	await v.run()
	if current != v:
		return
	await FX.fade(1, 600)
	if current == v:
		clear()


# ───────── 탐색 ─────────
## 1층 전투 뒤: 걸어 들어가는 연출만 (고를 길 없음)
func walk_in(place: String) -> void:
	var e := ExploreScene.new()
	e.setup(place)
	mount(e, "explore:" + place)
	await FX.fade(0, 500)
	await FX.wait(700)
	if current != e:
		return
	var to: Array = e.conf.get("walkTo", [960, 470])
	await e.walk(Vector2(to[0], to[1]))
	if current == e:
		clear()


## 길을 고르고 걸어 들어갈 때까지. 반환: 고른 길
func explore(place: String) -> String:
	var e := ExploreScene.new()
	e.setup(place)
	mount(e, "explore:" + place)
	await FX.fade(0, 500)
	if current != e:
		return ""
	# 처음 지도가 열릴 때 (대본 3.1)
	if not G.ctl.st.flags.get("mapSeen", false):
		G.ctl.st.flags.mapSeen = true
		await FX.wait(300)
		await e.open_map(true)
		if current != e:
			return ""
	await G.guide.fire("exploreShown", {"explore": place})
	if current != e:
		return ""
	var id: String = await e.choose()
	G.ctl.note("path " + id)
	if current == e:
		clear()
	return id


# ───────── 탑뷰 이동 시험판 (?scene=topdown, 튜토리얼 흐름과 따로) ─────────
func topdown() -> void:
	G.ctl.in_battle = false
	G.view.clear()
	var t := TopdownScene.new()
	t.setup("fork", {"trial": true})
	mount(t, "topdown")
	await t.run()


# ───────── 용사 사망 컷신 C1~C6 ─────────
func _cut_lines(c: Dictionary) -> Array:
	var out := []
	if cut_key != "hero":
		var dl: Dictionary = G.S.deathScenes.get(cut_key, {})
		var lv_lines: Dictionary = dl.get("lv%d" % cut_level, {})
		return lv_lines.get(c.id, dl.get("lines", {}).get(c.id, []))
	for ln in G.S.cutLines.get(c.id, []):
		if ln.get("sera", false):
			var key := str(G.ctl.st.flags.get("sera", "none"))
			for t in G.S.seraLast.get(key, G.S.seraLast.none):
				out.append({"who": "hero", "text": t})
		else:
			out.append(ln)
	return out


## 데스신. key: hero(세라피나 C1~C6) | warrior_pierce | archer_burn (game_data.gd deathScenes), level: 그 죽음 카드의 Lv (2 이상이면 더 어둡게·창/불 덧그림)
func cutscene(key := "hero", level := 1) -> void:
	cut_key = key
	cut_level = level
	var cs: Dictionary = GameData.D.cutscene if key == "hero" else GameData.D.deathScenes[key]
	var root := Control.new()
	root.size = Vector2(1920, 1080)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			root.accept_event()
			if not cut.is_empty() and cut.get("waiter") != null:
				cut.waiter.finish())
	var black_bg := ColorRect.new()
	black_bg.color = Color.BLACK
	black_bg.size = root.size
	black_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(black_bg)
	var holder := Node2D.new()     # 흔들림
	root.add_child(holder)
	var box := Node2D.new()        # 확대·움직임 (가운데 기준)
	box.position = Vector2(960, 540)
	holder.add_child(box)
	var img := Sprite2D.new()
	img.centered = true
	box.add_child(img)
	var pool := BloodLayer.new()
	pool.position = Vector2(-960, -540)
	var mul := CanvasItemMaterial.new()
	mul.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	pool.material = mul
	box.add_child(pool)
	var shade := UI.tex_rect(UI.grad([[0, Color(0, 0, 0, 0.95)], [0.35, Color(0, 0, 0, 0.75)], [0.6, Color(0, 0, 0, 0.2)], [0.75, Color(0, 0, 0, 0)], [1, Color(0, 0, 0, 0)]], "v", 4, 256), Rect2(0, 0, 1920, 1080))
	shade.modulate.a = 0.0
	root.add_child(shade)
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.size = root.size
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(black)
	var lens := BloodLayer.new()
	root.add_child(lens)
	var sub := UI.rich(int(38 * minf(FX.ui, 1.5)), Color("#f6eeee"), "serif_bold", "serif_bold")
	sub.position = Vector2(160, 800)
	sub.size = Vector2(1600, 0)
	sub.custom_minimum_size = Vector2(1600, 0)
	sub.add_theme_constant_override("outline_size", 10)
	sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	root.add_child(sub)
	var hint := UI.label(G.ui("cutHint"), 20, Color("#666666"), "sans", HORIZONTAL_ALIGNMENT_RIGHT)
	hint.position = Vector2(1620, 1030)
	hint.size = Vector2(270, 30)
	root.add_child(hint)
	# 2단계 이상의 죽음: 같은 그림을 더 어둡게 + 창(관통) / 불(화형) 덧그림 + 불씨
	var extra := DeathOverlay.new()
	extra.kind = str(cs.get("overlay", ""))
	extra.level = level
	extra.visible = level >= 2 and extra.kind != ""
	box.add_child(extra)
	if level >= 2:
		img.modulate = Color(0.68, 0.6, 0.62)
	if cut_root != null and is_instance_valid(cut_root):
		cut_root.queue_free()
	root.z_index = 30   # 탑뷰(붉은 덮개·운명 표시)보다 위
	add_child(root)
	cut_root = root
	current_name = "cutscene" if current == null else current_name
	G.ctl.note("scene cutscene " + key + " lv" + str(level))
	cut = {"root": root, "holder": holder, "box": box, "img": img, "shade": shade, "black": black, "lens": lens, "pool": pool, "sub": sub, "waiter": null, "image": ""}
	var pd: Dictionary = cs.get("pool", GameData.D.cutscene.pool)
	var pi := pool.pool(float(pd.x0), float(pd.x1), float(pd.y), 5)
	cut_log = []
	for c in cs.cuts:
		if cut_root != root:
			return
		cut_log.append(c.id)
		G.ctl.note("cut " + str(c.id))
		if c.id == "C4":
			FX.anim(1200, [{"a": lens.modulate.a}, {"a": 0.85}], func(v): lens.modulate.a = v.a, {"node": lens})
		match str(c.get("code", "")):
			"impact":
				await _impact_cut(c)
			"grind":
				await _grind_cut(c, pi)
			_:
				if c.id == "C6":
					pool.items = []
					FX.anim(float(c.duration), [{"a": lens.modulate.a}, {"a": 0.45}], func(v): lens.modulate.a = v.a, {"node": lens})
				await _image_cut(c)
	G.ctl.note("cut end " + str(cut_root == root))
	if cut_root != root:
		return
	_subtitle({})
	FX.anim(400, [{"a": lens.modulate.a}, {"a": 0.0}], func(v): lens.modulate.a = v.a, {"node": lens})
	await _black(1.0, 500)
	G.ctl.note("cut done")
	cutscene_done.emit()


func _set_image(name: String) -> void:
	var img: Sprite2D = cut.img
	img.texture = Assets.tex(name)
	var sz := Assets.size(name)
	if sz.x > 0:
		var k := maxf(1920.0 / sz.x, 1080.0 / sz.y)
		img.scale = Vector2(k, k)
	cut.image = name


func _zoom(from: float, to: float, ms: float) -> void:
	var box: Node2D = cut.box
	FX.anim(ms, [{"s": from}, {"s": to}], func(v): if is_instance_valid(box): box.scale = Vector2(v.s, v.s), {"node": box, "key": "cut_zoom"})


func _shade(v: float, ms: float) -> void:
	var s: TextureRect = cut.shade
	FX.anim(maxf(1.0, ms), [{"a": s.modulate.a}, {"a": v}], func(x): if is_instance_valid(s): s.modulate.a = x.a, {"node": s, "key": "cut_shade"})


func _black(v: float, ms: float) -> void:
	var b: ColorRect = cut.black
	if ms <= 0:
		b.color.a = v
		return
	var a := FX.anim(ms, [{"a": b.color.a}, {"a": v}], func(x): if is_instance_valid(b): b.color.a = x.a, {"node": b, "key": "cut_black"})
	await FX.until(a)


func _subtitle(ln: Dictionary) -> void:
	var sub: RichTextLabel = cut.sub
	if ln.is_empty():
		sub.visible = false
		return
	var who := "" if ln.get("who", "") == "system" else G.name_of(ln.get("who", ""))
	var fs := int(26 * minf(FX.ui, 1.5))
	sub.text = "[center]" + ("[font_size=%d][color=#ffb6bd]%s[/color][/font_size]\n" % [fs, who] if who != "" else "") + UI.esc(str(ln.text)) + "[/center]"
	sub.visible = true
	G.dialog.log.append(who + ": " + str(ln.text))


func _image_cut(c: Dictionary) -> void:
	_set_image(c.image)
	var z: Array = c.get("zoom", [1.0, 1.03])
	_zoom(z[0], z[1], float(c.duration))
	if c.id == "C1":
		cut.shade.modulate.a = 0.0
		_shade(0.35, float(c.duration))
	elif c.id == "C2":
		cut.shade.modulate.a = 0.35
		_shade(0.62, float(c.duration) * 0.8)
		FX.shake_node(cut.holder, 3, float(c.duration), 0.2)
	else:
		_shade(0, 300)
	# 데스신 첫 컷: 흰 섬광 → 강한 흔들림 → 화면(마녀의 눈)에 피가 튄다
	if c.get("impact", false):
		FX.flash("#ffffff", 240, 1)
		FX.shake_node(cut.holder, 34, 700)
		var lens0: BloodLayer = cut.lens
		if not c.get("blood", true):
			# 화형: 피 대신 화면 가득 불티
			FX.burst(960, 760, {"count": 120, "colors": ["#ff3a1e", "#ff9a2a", "#ffe08a", "#2a2a2a"], "speed": 520, "angle": -PI / 2, "spread": 2.4, "life": 1600, "size": 5, "gravity": -120})
		else:
			lens0.modulate.a = 1.0
			lens0.spray({"count": 3, "min": 140, "max": 260, "x0": 300, "x1": 1500, "y0": 150, "y1": 700, "seed": 17 + cut_level, "stagger": 40})
			lens0.spray({"count": 6, "min": 40, "max": 100, "seed": 29, "stagger": 25})
			FX.anim(float(c.duration), [{"a": 1.0}, {"a": 0.55}], func(v): if is_instance_valid(lens0): lens0.modulate.a = v.a, {"node": lens0})
	await _black(0.0, 700.0 if c.id == "C1" else 250.0)
	var lines := _cut_lines(c)
	if lines.is_empty():
		_subtitle({})
		await _wait_or_tap(float(c.duration))
		return
	for ln in lines:
		if cut.is_empty():
			return
		_subtitle(ln)
		await _wait_or_tap(float(c.duration) / lines.size())
	_subtitle({})


func _impact_cut(c: Dictionary) -> void:
	_subtitle({})
	FX.flash("#ffffff", 260, 1)
	await FX.wait(90)
	_black(1.0, 0)
	cut.shade.modulate.a = 0.0
	FX.shake_node(cut.holder, 44, 750)
	var lens: BloodLayer = cut.lens
	lens.modulate.a = 1.0
	lens.spray({"count": 4, "min": 160, "max": 300, "x0": 300, "x1": 1500, "y0": 150, "y1": 700, "seed": 13, "stagger": 40})
	lens.spray({"count": 7, "min": 40, "max": 110, "seed": 31, "stagger": 25})
	await _wait_or_tap(float(c.duration))


func _grind_cut(c: Dictionary, pi: Dictionary) -> void:
	if cut.image != c.image:
		_set_image(c.image)
	FX.cancel_key("cut_zoom")
	_black(0.0, 0)
	var box: Node2D = cut.box
	var lift: float = c.get("lift", 40)
	var tw: float = c.get("twistDeg", 2)
	var t0 := FX.now_ms()
	var skipped := [false]
	var w := DialogBox.Waiter.new()
	cut.waiter = w
	_waiters.append(w)
	w.done.connect(func(): skipped[0] = true)
	get_tree().create_timer(FX.ms(float(c.duration)) / 1000.0).timeout.connect(w.finish)
	var base := Vector2(960, 540)
	for i in int(c.get("slams", 2)):
		if skipped[0] or cut.is_empty():
			break
		# 발이 살짝 들린다(그림 전체가 위로)
		var a1 := FX.anim(460, [{"y": 0.0, "s": 1.08}, {"y": -lift, "s": 1.1}], func(v): box.position = base + Vector2(0, v.y); box.scale = Vector2(v.s, v.s), {"node": box, "easing": "ease-out", "key": "grind"})
		await FX.until(a1)
		if skipped[0]:
			break
		await FX.wait(120)
		# 세게 내리찍는다
		var a2 := FX.anim(220, [{"y": -lift, "s": 1.1}, {"o": 0.55, "y": 14.0, "s": 1.14}, {"y": 0.0, "s": 1.08}], func(v): box.position = base + Vector2(0, v.y); box.scale = Vector2(v.s, v.s), {"node": box, "easing": "ease-in", "key": "grind"})
		await FX.until(a2)
		FX.shake_node(cut.holder, 40, 480)
		FX.flash("#3a0006", 240, 0.45)
		pi.level += 1.1
		await FX.wait(380)
	if not skipped[0] and not cut.is_empty():
		# 비틀기: 좌우 회전 흔들림
		FX.shake_node(cut.holder, 12, 760)
		pi.level += 0.9
		var a3 := FX.anim(760, [{"y": 0.0, "s": 1.08, "r": 0.0}, {"o": 0.2, "y": 4.0, "s": 1.1, "r": -tw}, {"o": 0.45, "y": 2.0, "s": 1.1, "r": tw}, {"o": 0.7, "y": 4.0, "s": 1.1, "r": -tw * 0.6}, {"o": 0.88, "y": 0.0, "s": 1.08, "r": tw * 0.25}, {"o": 1.0, "y": 0.0, "s": 1.08, "r": 0.0}], func(v):
			box.position = base + Vector2(0, v.y)
			box.scale = Vector2(v.s, v.s)
			box.rotation_degrees = v.r, {"node": box, "easing": "ease-in-out", "key": "grind"})
		await FX.until(a3)
	var left := float(c.duration) - (FX.now_ms() - t0) * FX.speed
	if not skipped[0] and left > 0:
		await w.done
	_waiters.erase(w)
	box.rotation = 0
	box.position = base


## 컷신을 걷고 전투 화면으로 (C7)
func close_cutscene(delay := 0.0) -> void:
	if cut.is_empty():
		return
	await FX.wait(delay)
	var root: Control = cut.root
	var a := FX.anim(700, [{"a": 1.0}, {"a": 0.0}], func(v): if is_instance_valid(root): root.modulate.a = v.a, {"node": root})
	await FX.until(a)
	if cut_root == root:
		root.queue_free()
		cut_root = null
		cut = {}
		if current == null:
			current_name = ""


# ───────── 탈출 → (빈 캠프) ─────────
func escape() -> void:
	await FX.fade(1, 900)
	G.ctl.in_battle = false
	G.dialog.clear()
	var root := Control.new()
	root.size = Vector2(1920, 1080)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var bk := ColorRect.new()
	bk.color = Color.BLACK
	bk.size = root.size
	root.add_child(bk)
	var t := UI.label(G.S.escape.title, 96, Color("#e9dcde"), "serif_wide", HORIZONTAL_ALIGNMENT_CENTER)
	t.add_theme_constant_override("outline_size", 0)
	t.position = Vector2(0, 470)
	t.size = Vector2(1920, 140)
	t.modulate.a = 0.0
	root.add_child(t)
	mount(root, "escape")
	G.view.clear()
	await FX.fade(0, 200)
	var a := FX.anim(800, [{"a": 0.0}, {"a": 1.0}], func(v): t.modulate.a = v.a, {"node": t})
	await FX.until(a)
	await FX.wait(1900)
	var b := FX.anim(800, [{"a": 1.0}, {"a": 0.0}], func(v): t.modulate.a = v.a, {"node": t})
	await FX.until(b)
	await FX.fade(1, 300)


# ───────── 종료 ─────────
func ending() -> void:
	G.ctl.in_battle = false
	G.view.clear()
	var e: Dictionary = G.S.ending
	var root := Control.new()
	root.size = Vector2(1920, 1080)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var bk := ColorRect.new()
	bk.color = Color.BLACK
	bk.size = root.size
	root.add_child(bk)
	var u := minf(FX.ui, 1.4)
	var h := UI.label(e.title, int(76 * u), Color("#e9dcde"), "serif_wide", HORIZONTAL_ALIGNMENT_CENTER)
	h.position = Vector2(0, 250)
	h.size = Vector2(1920, 110)
	root.add_child(h)
	var y := 400.0
	var ps := []
	for ln in e.lines:
		var p := UI.label(ln, int(34 * u), Color("#bfb2b4"), "serif", HORIZONTAL_ALIGNMENT_CENTER)
		p.position = Vector2(0, y)
		p.size = Vector2(1920, 60)
		p.modulate.a = 0.0
		root.add_child(p)
		ps.append(p)
		y += 64 * u
	var inner := UI.label(e.inner, int(34 * u), Color("#d8a9b4"), "serif", HORIZONTAL_ALIGNMENT_CENTER)
	inner.position = Vector2(0, y + 30)
	inner.size = Vector2(1920, 60)
	inner.modulate.a = 0.0
	root.add_child(inner)
	ps.append(inner)
	var b := UI.button(e.button, int(32 * u), func(): G.ctl.start_tutorial())
	b.fit(Vector2(64, 16))
	b.position = Vector2(960 - b.size.x / 2.0, y + 150)
	b.modulate.a = 0.0
	b.name = "again"
	root.add_child(b)
	mount(root, "ending")
	G.ctl.stage = "ending"
	G.ctl.note("ending")
	if G.params.has("quit-on-end"):
		get_tree().create_timer(1.0).timeout.connect(func(): get_tree().quit(0))
	FX.fade(0, 400)
	for i in ps.size():
		var p: Control = ps[i]
		FX.anim(1200, [{"a": 0.0}, {"a": 1.0}], func(v): if is_instance_valid(p): p.modulate.a = v.a, {"node": p, "delay": 500 + i * 1400})
	FX.anim(1000, [{"a": 0.0}, {"a": 1.0}], func(v): if is_instance_valid(b): b.modulate.a = v.a, {"node": b, "delay": 500 + ps.size() * 1400})


# ───────── 전멸 (1층·2층 광신도 전투) ─────────
func wipe(kind: String) -> void:
	var w: Dictionary = G.S.wipe.get(kind, G.S.wipe.normal)
	var root := Control.new()
	root.size = Vector2(1920, 1080)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := UI.tex_rect(UI.grad([[0, Color(0.24, 0, 0.03, 0.94)], [1, Color(0, 0, 0, 0.98)]], "radial", 128, 128, Vector2(0.5, 0.5), 0.7), Rect2(0, 0, 1920, 1080))
	root.add_child(bg)
	var h := UI.label(w.title, 80, Color("#ff5a68"), "serif_wide", HORIZONTAL_ALIGNMENT_CENTER)
	h.position = Vector2(0, 360)
	h.size = Vector2(1920, 110)
	root.add_child(h)
	var p := UI.label(w.text, 30, Color("#cdb7ba"), "serif", HORIZONTAL_ALIGNMENT_CENTER)
	p.position = Vector2(0, 490)
	p.size = Vector2(1920, 50)
	root.add_child(p)
	var done := DialogBox.Waiter.new()
	var b := UI.button(w.button, 30, func(): done.finish())
	b.fit(Vector2(50, 14))
	b.position = Vector2(960 - b.size.x / 2.0, 600)
	b.name = "retry"
	root.add_child(b)
	mount(root, "wipe")
	_waiters.append(done)   # mount 가 앞 장면의 기다림을 모두 끝내므로 그 뒤에 넣는다
	FX.fade(0, 500)
	if G.autoguide:
		get_tree().create_timer(1.0).timeout.connect(done.finish)
	if not done.finished:
		await done.done
	if current == root:
		clear()


# ───────── 카드를 내지 않은 미래 (대본 5.7) ─────────
## 짓밟기로 전멸 → 화면이 피처럼 붉게 번지다가 유리처럼 깨지며 거대 존재 전투 1턴 직전으로 돌아간다
func rewind() -> void:
	G.ctl.note("rewind")
	G.dialog.clear()
	var root := Control.new()
	root.size = Vector2(1920, 1080)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	mount(root, "rewind")
	var red := RedBleed.new()
	root.add_child(red)
	var a := FX.anim(1300, [{"k": 0.0}, {"k": 1.0}], func(v): red.k = v.k; red.queue_redraw(), {"node": red, "easing": "ease-in"})
	await FX.until(a)
	await FX.wait(300)
	if current != root:
		return
	# 지금 화면을 찍어 유리 조각으로 깨뜨린다
	var img: Image = null
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		img = get_viewport().get_texture().get_image()
	var tex := ImageTexture.create_from_image(img) if img else null
	var glass := GlassShatter.new()
	glass.tex = tex
	glass.vp_size = Vector2(img.get_size()) if img else Vector2(1920, 1080)
	# 무대(1920×1080) → 찍은 그림 픽셀: 비율 유지(검은 여백) 배치와 같게
	var vs := glass.vp_size
	var sk := minf(vs.x / 1920.0, vs.y / 1080.0)
	glass.stage_xf = Transform2D(0.0, Vector2(sk, sk), 0.0, (vs - Vector2(1920, 1080) * sk) / 2.0)
	root.add_child(glass)
	red.visible = false
	var bk := ColorRect.new()
	bk.color = Color.BLACK
	bk.size = root.size
	root.add_child(bk)
	root.move_child(bk, 0)
	FX.flash("#ffffff", 200, 0.5)
	FX.shake(10, 300)
	G.ctl.note("rewind glass")
	var b := FX.anim(1400, [{"k": 0.0}, {"k": 1.0}], func(v): glass.k = v.k; glass.queue_redraw(), {"node": glass, "easing": "ease-in"})
	await FX.until(b)
	FX.set_fade(1)
	if current == root:
		clear()


class RedBleed extends Control:
	var k := 0.0
	var blobs := []

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(1920, 1080)
		for i in 26:
			blobs.append({"p": Vector2(randf() * 1920, randf() * 1080), "r": 120 + randf() * 260, "d": randf() * 0.5})

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.45, 0.0, 0.04, 0.55 * k))
		for b in blobs:
			var kk := clampf((k - float(b.d)) / 0.5, 0.0, 1.0)
			if kk <= 0:
				continue
			for i in 4:
				draw_circle(b.p, float(b.r) * kk * (1.0 - i * 0.18), Color(0.5, 0.0, 0.05, 0.16))
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.3, 0.0, 0.02, 0.4 * k * k))


class GlassShatter extends Control:
	var tex: Texture2D
	var vp_size := Vector2(1920, 1080)
	var stage_xf := Transform2D.IDENTITY
	var k := 0.0
	var shards := []

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(1920, 1080)
		# 깨지는 점(가운데 약간 위)에서 퍼지는 금 → 조각
		var c := Vector2(960, 470)
		var rings := [0.0, 140.0, 360.0, 700.0, 1300.0]
		var spokes := 14
		var pts := []
		for ri in rings.size():
			var row := []
			for s in spokes:
				var ang := s * TAU / spokes + (randf() - 0.5) * 0.25
				var rr: float = rings[ri] * (0.85 + randf() * 0.3)
				row.append(c + Vector2.from_angle(ang) * rr)
			pts.append(row)
		for ri in range(1, rings.size()):
			for s in spokes:
				var s2 := (s + 1) % spokes
				var poly := PackedVector2Array([pts[ri - 1][s], pts[ri][s], pts[ri][s2], pts[ri - 1][s2]])
				if ri == 1:
					poly = PackedVector2Array([c, pts[1][s], pts[1][s2]])
				var ctr := Vector2.ZERO
				for p in poly:
					ctr += p
				ctr /= poly.size()
				shards.append({"poly": poly, "c": ctr, "v": (ctr - c).normalized() * (200 + randf() * 600) + Vector2(0, -100 - randf() * 200), "rot": (randf() - 0.5) * 3.0, "d": randf() * 0.25})

	func _draw() -> void:
		if tex == null:
			return
		var inv := stage_xf
		for sh in shards:
			var kk := clampf((k - float(sh.d)) / (1.0 - float(sh.d)), 0.0, 1.0)
			var off: Vector2 = sh.v * kk + Vector2(0, 900) * kk * kk
			var rot: float = sh.rot * kk
			var pts := PackedVector2Array()
			var uvs := PackedVector2Array()
			for p in sh.poly:
				var q: Vector2 = (p - sh.c).rotated(rot) + sh.c + off
				pts.append(q)
				var sp: Vector2 = inv * p
				uvs.append(Vector2(sp.x / vp_size.x, sp.y / vp_size.y))
			var col := Color(1, 1, 1, 1.0 - kk * 0.8)
			draw_polygon(pts, PackedColorArray([col, col, col, col].slice(0, pts.size())), uvs, tex)
			var loop := pts.duplicate()
			loop.append(pts[0])
			draw_polyline(loop, Color(1, 0.85, 0.85, 0.5 * (1.0 - kk)), 1.5, true)


# ───────── 1차 시험판 v2: 운명의 시도 · 카드 획득 · 층 끝 · 결과 요약 ─────────
## 지금 장면 위에 덮는 화면을 단다 (탑뷰·전투를 지우지 않는다)
func _overlay(root: Control, name: String) -> void:
	root.z_index = 20   # 지금 장면(탑뷰의 운명 표시·지도 버튼 z 6)보다 위, 컷신(30)보다 아래
	add_child(root)
	overlays.append(root)
	G.ctl.note("overlay " + name)


func _overlay_close(root: Control, ms := 300.0) -> void:
	if not is_instance_valid(root):
		return
	var a := FX.anim(ms, [{"a": root.modulate.a}, {"a": 0.0}], func(v): if is_instance_valid(root): root.modulate.a = v.a, {"node": root})
	await FX.until(a)
	overlays.erase(root)
	if is_instance_valid(root):
		root.queue_free()


## 자동 진행·시험: 운명의 시도에서 고를 것 (?fates=offer,defy,… 차례대로 / 없으면 defy)
var fate_auto: Array = []
var fate_auto_i := 0
var fate_picker: Dictionary = {}


func _auto_fate() -> String:
	if fate_auto.is_empty() and G.params.has("fates"):
		fate_auto = str(G.params.fates).split(",", false)
	if fate_auto_i < fate_auto.size():
		fate_auto_i += 1
		return str(fate_auto[fate_auto_i - 1])
	return "defy"


## 운명의 시도 선택 화면: 죽음 카드(Lv)와 두 버튼 [카드를 낸다 — {이름}을(를) 바친다] [거스른다 — 운명을 비튼다 (흉터 n)]. 반환: offer | defy
func fate_choice(fate: Dictionary) -> String:
	var st: Dictionary = G.ctl.st
	var F: Dictionary = G.S.fate
	var u := minf(FX.ui, 1.45)
	var root := Control.new()
	root.size = Vector2(1920, 1080)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := UI.tex_rect(UI.grad([[0, Color(0.25, 0.0, 0.03, 0.55)], [0.7, Color(0.08, 0.0, 0.01, 0.85)], [1, Color(0, 0, 0, 0.92)]], "radial", 128, 128, Vector2(0.4, 0.5), 0.75), Rect2(0, 0, 1920, 1080))
	root.add_child(dim)
	var cv := CardView.new()
	root.add_child(cv)
	cv.setup_face(st, str(fate.card))
	var ck := 1.75
	var cpos := Vector2(300, 540 - CardView.H * ck / 2.0)
	cv.set_rect(cpos + Vector2(0, 60), ck, true)
	cv.smooth = false
	cv.taut = 1.0
	var name: String = G.name_of(str(fate.who))
	var n_scar: int = int(GameData.D.fates[fate.id].scars[clampi(int(fate.level) - 1, 0, 2)])
	var t1 := UI.label(str(F.choiceTitle), int(30 * u), Color("#ff9aa4"), "serif_bold", HORIZONTAL_ALIGNMENT_LEFT, 6)
	t1.position = Vector2(860, 230)
	t1.size = Vector2(1000, 50)
	root.add_child(t1)
	var t2 := UI.label(str(F.choiceText).replace("{name}", name), int(36 * u), Color("#f6e7c8"), "serif_bold", HORIZONTAL_ALIGNMENT_LEFT, 6)
	t2.position = Vector2(860, 230 + 56 * u)
	t2.size = Vector2(1000, 60)
	t2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(t2)
	var w := DialogBox.Waiter.new()
	var picked := ["defy"]
	var y := 430.0 + 40.0 * (u - 1.0)
	var btns := []
	for opt in [["offer", str(F.offer).replace("{name}", name)], ["defy", str(F.defy).replace("{n}", str(n_scar))]]:
		var val: String = opt[0]
		var b := UI.button(opt[1], int(32 * u), func():
			picked[0] = val
			w.finish(), "serif_bold")
		b.style_kind = "choice"
		b.name = "fate_" + val
		b.set_meta("value", val)
		b.fit(Vector2(70, 24))
		b.size.x = maxf(b.size.x, 860)
		b.lbl.size = b.size
		b.position = Vector2(860, y)
		y += b.size.y + 36
		root.add_child(b)
		btns.append(b)
	var sub := UI.label(str(F.defyNote).replace("{n}", str(n_scar)), int(22 * u), Color("#c9a9ad"), "sans", HORIZONTAL_ALIGNMENT_LEFT)
	sub.position = Vector2(866, y + 4)
	sub.size = Vector2(980, 40)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(sub)
	root.modulate.a = 0.0
	_overlay(root, "fateChoice")
	fate_picker = {"root": root, "btns": btns, "waiter": w, "picked": picked}
	FX.anim(350, [{"a": 0.0}, {"a": 1.0}], func(v): if is_instance_valid(root): root.modulate.a = v.a, {"node": root})
	FX.anim(500, [{"y": 60.0}, {"y": 0.0}], func(v): if is_instance_valid(cv): cv.set_rect(cpos + Vector2(0, v.y), ck, true), {"node": cv, "easing": "ease-out"})
	G.ctl.note("fate choice " + str(fate.id) + " lv" + str(fate.level))
	if G.autoguide or G.params.has("fates"):
		var choice := _auto_fate()
		get_tree().create_timer(FX.ms(900) / 1000.0).timeout.connect(func():
			picked[0] = choice
			w.finish())
	if not w.finished:
		await w.done
	fate_picker = {}
	G.ctl.note("fate pick " + str(picked[0]))
	for b in btns:
		b.disabled = true
	if picked[0] == "offer":
		FX.flash("#ffffff", 200, 0.3)
		var a1 := FX.anim(420, [{"y": 0.0, "b": 1.0}, {"y": -60.0, "b": 2.2}], func(v):
			if is_instance_valid(cv):
				cv.set_rect(cpos + Vector2(0, v.y), ck, true)
				cv.bright = v.b, {"node": cv, "easing": "ease-out"})
		await FX.until(a1)
	else:
		# 노엘이 카드를 움켜쥔다: 카드가 구겨지듯 좁아지며 떨리고, 붉은 실이 튕긴다
		FX.flash("#ff2a3c", 220, 0.45)
		FX.shake(10, 380)
		var c0 := cpos + Vector2(CardView.W, CardView.H) * ck / 2.0
		var a2 := FX.anim(460, [{"k": 1.0}, {"o": 0.5, "k": 0.82}, {"k": 0.9}], func(v):
			if is_instance_valid(cv):
				var kk: float = ck * v.k
				cv.set_rect(c0 - Vector2(CardView.W, CardView.H) * kk / 2.0 + Vector2(randf_range(-6, 6), randf_range(-4, 4)), kk, true)
				cv.taut = 1.0 + (1.0 - v.k) * 4.0, {"node": cv})
		FX.burst(c0.x, c0.y - 120, {"count": 30, "colors": ["#ff2a3c", "#ff8a90"], "speed": 420, "life": 600, "size": 3, "gravity": 0, "shape": "line"})
		await FX.until(a2)
	await _overlay_close(root, 250)
	return picked[0]


## 시험: 운명 선택 화면에서 고른다
func pick_fate(value: String) -> bool:
	if fate_picker.is_empty():
		return false
	fate_picker.picked[0] = value
	fate_picker.waiter.finish()
	return true


## 카드 획득 연출(상속 카드·흉터): 카드가 떠오르며 커졌다가 덱(왼쪽 아래)으로 들어간다. kind: inherit | scar
func card_gain(uids: Array, kind := "inherit", caption := "", sub := "") -> void:
	var st: Dictionary = G.ctl.st
	if uids.is_empty():
		return
	var u := minf(FX.ui, 1.45)
	var root := Control.new()
	root.size = Vector2(1920, 1080)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.0, 0.01, 0.6)
	dim.size = root.size
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var views := []
	var ck := 1.25
	var gap := 50.0
	var total := uids.size() * CardView.W * ck + (uids.size() - 1) * gap
	for i in uids.size():
		if not st.cards.has(uids[i]):
			continue
		var cv := CardView.new()
		root.add_child(cv)
		cv.setup_face(st, str(uids[i]))
		cv.smooth = false
		cv.glow = 1.0 if kind == "inherit" else 0.0
		cv.taut = 0.8 if kind == "scar" else 0.0
		views.append({"cv": cv, "x": 960 - total / 2.0 + i * (CardView.W * ck + gap)})
	var id0: String = st.cards[uids[0]].id if st.cards.has(uids[0]) else ""
	var txt: String = str(G.S.fate.gainScar).replace("{n}", str(uids.size())) if kind == "scar" else \
		str(G.S.fate.gainInherit).replace("{card}", Rules.card_name(id0, false, Rules.level(st, str(uids[0]))))
	if caption != "":
		txt = caption
	var lab := UI.label(txt, int(34 * u), Color("#ffb6bd") if kind == "scar" else Color("#ffe2a8"), "serif_bold", HORIZONTAL_ALIGNMENT_CENTER, 8)
	lab.position = Vector2(0, 850)
	lab.size = Vector2(1920, 60)
	root.add_child(lab)
	if sub != "":
		var sl := UI.label(sub, int(26 * u), Color("#c9c9c9"), "sans_bold", HORIZONTAL_ALIGNMENT_CENTER, 6)
		sl.position = Vector2(0, 850 + 60 * u)
		sl.size = Vector2(1920, 44)
		root.add_child(sl)
	var w := DialogBox.Waiter.new()
	root.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			root.accept_event()
			w.finish())
	_overlay(root, "cardGain " + kind)
	G.ctl.note("card gain %s %s" % [kind, id0])
	var y0 := 540.0 - CardView.H * ck / 2.0 - 40.0
	var a := FX.anim(700, [{"k": 0.5, "y": 220.0, "a": 0.0}, {"o": 0.6, "k": 1.08, "y": -10.0, "a": 1.0}, {"k": 1.0, "y": 0.0, "a": 1.0}], func(v):
		for vv in views:
			if is_instance_valid(vv.cv):
				var kk: float = ck * v.k
				vv.cv.set_rect(Vector2(vv.x + CardView.W * (ck - kk) / 2.0, y0 + v.y + CardView.H * (ck - kk) / 2.0), kk, true)
				vv.cv.alpha = v.a, {"node": root, "easing": "ease-out"})
	FX.flash("#ffffff" if kind == "inherit" else "#7a0010", 300, 0.4)
	FX.burst(960, 520, {"count": 50, "colors": ["#ff2a3c", "#7a0010", "#ffb0b6"] if kind == "inherit" else ["#7a0010", "#3a0006"], "speed": 380, "life": 900, "size": 4, "gravity": 0})
	await FX.until(a)
	get_tree().create_timer(FX.ms(2200) / 1000.0).timeout.connect(w.finish)
	if not w.finished:
		await w.done
	if kind == "note":
		await _overlay_close(root, 350)
		return
	# 덱(왼쪽 아래)으로 날아 들어간다
	var b := FX.anim(450, [{"k": 0.0}, {"k": 1.0}], func(v):
		for vv in views:
			if is_instance_valid(vv.cv):
				var kk: float = lerpf(ck, 0.2, v.k)
				vv.cv.set_rect(Vector2(lerpf(vv.x, 120.0, v.k), lerpf(y0, 980.0, v.k)), kk, true)
				vv.cv.alpha = 1.0 - v.k * 0.6, {"node": root, "easing": "ease-in"})
	await FX.until(b)
	await _overlay_close(root, 200)


## 층 끝 화면 (1층 끝 → 2층): 제목·문구, 버튼을 누르면 끝난다
func chapter(conf: Dictionary) -> void:
	G.view.clear()
	var u := minf(FX.ui, 1.4)
	var root := Control.new()
	root.size = Vector2(1920, 1080)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var bk := ColorRect.new()
	bk.color = Color.BLACK
	bk.size = root.size
	root.add_child(bk)
	var h := UI.label(str(conf.title), int(76 * u), Color("#e9dcde"), "serif_wide", HORIZONTAL_ALIGNMENT_CENTER)
	h.position = Vector2(0, 250)
	h.size = Vector2(1920, 110)
	root.add_child(h)
	var y := 400.0
	var ps := []
	for ln in conf.get("lines", []):
		var p := UI.label(str(ln), int(34 * u), Color("#bfb2b4"), "serif", HORIZONTAL_ALIGNMENT_CENTER)
		p.position = Vector2(0, y)
		p.size = Vector2(1920, 60)
		p.modulate.a = 0.0
		root.add_child(p)
		ps.append(p)
		y += 64 * u
	if conf.has("inner"):
		var inner := UI.label(str(conf.inner), int(34 * u), Color("#d8a9b4"), "serif", HORIZONTAL_ALIGNMENT_CENTER)
		inner.position = Vector2(0, y + 30)
		inner.size = Vector2(1920, 60)
		inner.modulate.a = 0.0
		root.add_child(inner)
		ps.append(inner)
	var w := DialogBox.Waiter.new()
	var b := UI.button(str(conf.button), int(32 * u), func(): w.finish())
	b.fit(Vector2(64, 16))
	b.position = Vector2(960 - b.size.x / 2.0, y + 150)
	b.modulate.a = 0.0
	b.name = "next"
	root.add_child(b)
	mount(root, "chapter")
	G.ctl.stage = "chapter"
	FX.fade(0, 400)
	for i in ps.size():
		var p: Control = ps[i]
		FX.anim(1000, [{"a": 0.0}, {"a": 1.0}], func(v): if is_instance_valid(p): p.modulate.a = v.a, {"node": p, "delay": 400 + i * 1000})
	FX.anim(800, [{"a": 0.0}, {"a": 1.0}], func(v): if is_instance_valid(b): b.modulate.a = v.a, {"node": b, "delay": 400 + ps.size() * 1000})
	if G.autoguide:
		get_tree().create_timer(FX.ms(1500) / 1000.0).timeout.connect(w.finish)
	await w.done
	await FX.fade(1, 500)
	if current == root:
		clear()


## 시험판 끝 — 결과 요약: 누가 죽고 누가 살았는지, 죽음 카드 Lv, 흉터 장수, 얻은 상속 카드, 다음 층에서 올 운명. [처음부터] [2층부터 다시]
func result() -> void:
	G.ctl.in_battle = false
	G.view.clear()
	G.dialog.clear()
	var st: Dictionary = G.ctl.st
	var R: Dictionary = G.S.result
	var u := minf(FX.ui, 1.35)
	var root := Control.new()
	root.size = Vector2(1920, 1080)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := UI.tex_rect(UI.grad([[0, Color("#1d0609")], [0.6, Color("#080304")], [1, Color("#000000")]], "radial", 256, 256, Vector2(0.5, 0.35), 0.8), Rect2(0, 0, 1920, 1080))
	root.add_child(bg)
	var h := UI.label(str(R.title), int(64 * u), Color("#efe3e5"), "serif_wide", HORIZONTAL_ALIGNMENT_CENTER, 10)
	h.position = Vector2(0, 60)
	h.size = Vector2(1920, 90)
	root.add_child(h)
	var x := 960.0 - 560.0 * u
	var y := 190.0
	# 동료마다 한 줄
	var rows := []
	for who in ["hero", "warrior", "archer"]:
		var a: Dictionary = st.party.allies[who]
		var f = null
		for ff in st.fates:
			if ff.who == who:
				f = ff
		var line := ""
		if who == "hero":
			line = str(R.hero)
		elif f == null:
			line = str(R.noFate).replace("{name}", G.name_of(who))
		elif f.result == "offered":
			line = str(R.offered).replace("{name}", G.name_of(who)).replace("{lv}", str(f.get("offeredLevel", f.level))).replace("{floor}", str(f.get("offeredFloor", f.floor)))
		elif f.result == "saved":
			line = str(R.saved).replace("{name}", G.name_of(who))
		else:
			line = str(R.alive).replace("{name}", G.name_of(who)).replace("{lv}", str(f.level)).replace("{floor}", str(f.floor))
		rows.append({"who": who, "dead": a.status == "dead", "text": line})
	for r in rows:
		var face := TextureRect.new()
		face.texture = Assets.face_tex(r.who, null, true)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.position = Vector2(x, y)
		face.size = Vector2(96, 96) * u
		face.modulate = Color(0.35, 0.3, 0.3) if r.dead else Color.WHITE
		root.add_child(face)
		var nm := UI.label(G.name_of(r.who) + ("  †" if r.dead else ""), int(30 * u), Color("#c9a0a6") if r.dead else Color("#f6e7c8"), "serif_bold")
		nm.position = Vector2(x + 120 * u, y + 4)
		nm.size = Vector2(1500, 44)
		root.add_child(nm)
		var tl := UI.label(str(r.text), int(25 * u), Color("#d8c9cb"), "sans")
		tl.position = Vector2(x + 120 * u, y + 46 * u)
		tl.size = Vector2(1560 - 120 * u, 40)
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		root.add_child(tl)
		y += 118 * u
	# 흉터 · 상속 카드
	var inh := []
	for uid in st.party.deck:
		if st.cards.has(uid) and GameData.D.cards[st.cards[uid].id].kind == "inherit":
			inh.append(Rules.card_name(st.cards[uid].id, false, Rules.level(st, uid)))
	var summary := str(R.scars).replace("{n}", str(Rules.scar_count(st))) + "     " + str(R.inherits).replace("{list}", ", ".join(inh) if not inh.is_empty() else "—")
	var sl := UI.label(summary, int(27 * u), Color("#ffcf8a"), "sans_bold")
	sl.position = Vector2(x, y + 6)
	sl.size = Vector2(1720, 44)
	root.add_child(sl)
	y += 60 * u
	# 다음 층에서 올 운명
	var nxt := []
	for f in Rules.active_fates(st):
		nxt.append(str(R.nextItem).replace("{name}", G.name_of(f.who)).replace("{lv}", str(int(f.level) + 1)))
	var nl := UI.label(str(R.next).replace("{list}", " / ".join(nxt) if not nxt.is_empty() else str(R.nextNone)), int(27 * u), Color("#ff9aa4"), "serif_bold")
	nl.position = Vector2(x, y + 6)
	nl.size = Vector2(1720, 44)
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(nl)
	y += 80 * u
	var b1 := UI.button(str(R.again), int(30 * u), func(): G.ctl.start_tutorial())
	b1.fit(Vector2(56, 14))
	b1.name = "again"
	var b2 := UI.button(str(R.floor2), int(30 * u), func(): G.ctl.jump("floor2"))
	b2.fit(Vector2(56, 14))
	b2.name = "floor2"
	var by := minf(y + 10, 1080 - 30 - b1.size.y)
	b1.position = Vector2(960 - b1.size.x - 30, by)
	b2.position = Vector2(960 + 30, by)
	root.add_child(b1)
	root.add_child(b2)
	mount(root, "result")
	G.ctl.stage = "result"
	G.ctl.note("result")
	if G.params.has("quit-on-end"):
		get_tree().create_timer(1.0).timeout.connect(func(): get_tree().quit(0))
	FX.fade(0, 500)


## 2단계 이상의 죽음 덧그림 (데스신 그림 위): 창(관통) 여러 자루 / 불길, 그리고 떠오르는 불씨
class DeathOverlay extends Node2D:
	var kind := ""
	var level := 2
	var _t := 0.0
	var embers := []

	func _ready() -> void:
		position = Vector2(-960, -540)
		for i in 60:
			embers.append({"x": randf() * 1920.0, "y": randf() * 1080.0, "s": 2.0 + randf() * 4.0, "v": 40.0 + randf() * 120.0, "ph": randf() * TAU})

	func _process(d: float) -> void:
		_t += d
		queue_redraw()

	func _draw() -> void:
		if kind == "spears":
			# 바닥에서 비스듬히 솟은 굵은 창 (나무 자루 + 잎 모양 쇠 날 + 날에 묻은 피)
			var spears := [[380, 1080, 640, 290], [720, 1080, 770, 150], [1520, 1080, 1270, 230], [1180, 1080, 1090, 400], [180, 1080, 460, 520]]
			for sp in spears:
				var a := Vector2(sp[0], sp[1])
				var b := Vector2(sp[2], sp[3])
				var dv := (b - a).normalized()
				var nv := Vector2(-dv.y, dv.x)
				draw_line(a, b, Color(0.04, 0.02, 0.02, 0.92), 24.0, true)
				draw_line(a, b, Color(0.3, 0.22, 0.17, 1.0), 15.0, true)
				draw_line(a + nv * 3.0, b + nv * 3.0, Color(0.5, 0.4, 0.32, 0.8), 4.0, true)
				var tip := PackedVector2Array([b + dv * 150.0, b + nv * 30.0 + dv * 20.0, b - dv * 14.0, b - nv * 30.0 + dv * 20.0])
				var out := PackedVector2Array([b + dv * 160.0, b + nv * 36.0 + dv * 20.0, b - dv * 20.0, b - nv * 36.0 + dv * 20.0])
				draw_colored_polygon(out, Color(0.05, 0.03, 0.03, 0.95))
				draw_colored_polygon(tip, Color(0.62, 0.62, 0.66, 1.0))
				draw_line(b - dv * 8.0, b + dv * 140.0, Color(0.85, 0.85, 0.9, 0.9), 3.0, true)
				# 날 아래쪽 절반에 피가 흘러내린다
				var blood := PackedVector2Array([b + dv * 70.0 + nv * 18.0, b + nv * 30.0 + dv * 20.0, b - dv * 14.0, b - nv * 24.0 + dv * 18.0, b + dv * 60.0 - nv * 12.0])
				draw_colored_polygon(blood, Color(0.5, 0.0, 0.04, 0.85))
				for k in 3:
					var d0 := b - dv * (20.0 + k * 40.0) + nv * (8.0 - k * 6.0)
					draw_line(d0, d0 + Vector2(0, 30.0 + 20.0 * sin(_t * 2.0 + k)), Color(0.45, 0.0, 0.03, 0.8), 5.0, true)
		elif kind == "fire":
			for i in 14:
				var x := 60.0 + i * 140.0
				var hgt := 240.0 + 120.0 * sin(_t * 5.0 + i * 1.7)
				var pts := PackedVector2Array([Vector2(x - 90, 1080), Vector2(x - 30 + 20 * sin(_t * 7 + i), 1080 - hgt), Vector2(x + 20, 1080 - hgt * 0.6), Vector2(x + 90, 1080)])
				draw_colored_polygon(pts, Color(1.0, 0.35, 0.05, 0.33))
			draw_rect(Rect2(0, 0, 1920, 1080), Color(0.6, 0.12, 0.0, 0.18))
		# 불씨
		for e in embers:
			var y := fposmod(float(e.y) - _t * float(e.v), 1080.0)
			var x2 := float(e.x) + sin(_t * 1.3 + float(e.ph)) * 20.0
			draw_circle(Vector2(x2, y), float(e.s), Color(1, 0.55 + 0.3 * sin(_t * 9 + float(e.ph)), 0.15, 0.75))
