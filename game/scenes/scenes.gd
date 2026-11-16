## scenes.gd — 타이틀 / 비주얼노벨(캠프·이벤트·계단·빈 캠프) / 탐색 / 용사 사망 컷신(C1~C6) / 탈출 / 종료 / 전멸 / 카드를 내지 않은 미래.
## HTML 판 scenes.js 를 옮기고 탐색·이벤트·빈 캠프·되감기 연출을 더했다. 장면은 하나씩만 열린다(current).
class_name Scenes
extends Node2D

signal cutscene_done

var current: Node = null
var current_name := ""
var cut := {}
var cut_log: Array = []
var _waiters: Array = []


func is_open() -> bool:
	return current != null and is_instance_valid(current)


func clear() -> void:
	if is_open():
		current.queue_free()
	current = null
	current_name = ""
	for w in _waiters:
		w.finish()
	_waiters = []
	cut = {}


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
	t.setup()
	mount(t, "topdown")
	await t.run()


# ───────── 용사 사망 컷신 C1~C6 ─────────
func _cut_lines(c: Dictionary) -> Array:
	var out := []
	for ln in G.S.cutLines.get(c.id, []):
		if ln.get("sera", false):
			var key := str(G.ctl.st.flags.get("sera", "none"))
			for t in G.S.seraLast.get(key, G.S.seraLast.none):
				out.append({"who": "hero", "text": t})
		else:
			out.append(ln)
	return out


func cutscene() -> void:
	var cs: Dictionary = GameData.D.cutscene
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
	mount(root, "cutscene")
	cut = {"root": root, "holder": holder, "box": box, "img": img, "shade": shade, "black": black, "lens": lens, "pool": pool, "sub": sub, "waiter": null, "image": ""}
	var pi := pool.pool(float(cs.pool.x0), float(cs.pool.x1), float(cs.pool.y), 5)
	cut_log = []
	for c in cs.cuts:
		if current != root:
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
	G.ctl.note("cut end " + str(current == root))
	if current != root:
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
	if current == root:
		clear()


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
	_waiters.append(done)
	var b := UI.button(w.button, 30, func(): done.finish())
	b.fit(Vector2(50, 14))
	b.position = Vector2(960 - b.size.x / 2.0, 600)
	b.name = "retry"
	root.add_child(b)
	mount(root, "wipe")
	FX.fade(0, 500)
	if G.autoguide:
		get_tree().create_timer(1.0).timeout.connect(done.finish)
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
