## vn.gd — 비주얼노벨 장면: 캠프(파티 소개) · 갈림길 이벤트(시체·휴식·훈련) · 계단(세라피나와의 대화) · 빈 캠프.
## 대사는 script_data.gd (camp / events), 배경·배치는 game_data.gd (vnScenes / vn / omen). HTML 판 scenes.js 의 캠프 대화를 넓힌 것.
## 안내 상자 줄(system)은 화면 위쪽 안내 상자로 띄우고 탭을 기다린다.
class_name VnScene
extends Control

signal tapped

var scene_name := ""
var lines: Array = []
var bg: TextureRect
var bg2: TextureRect
var fire: TextureRect
var bedroll: Control
var stands := {}
var tags := {}
var box: Control
var face: TextureRect
var name_plate: Control
var name_l: Label
var text_l: RichTextLabel
var next_l: Label
var skip_btn: Btn
var title_l: Label
var omen: OmenView
var typing := false
var full_len := 0
var shown := 0.0
var skip := false
var line_index := -1
var choice_btns: Array = []
var _t := 0.0
var _fire_low := false
var _waiting := false
var overlay := false


## o.overlay: 탑뷰 맵 위에 띄운다(배경 그림 없이, 아래쪽만 어둡게) — 캠프·빈 캠프
func setup(name: String, o := {}) -> void:
	scene_name = name
	overlay = bool(o.get("overlay", false))
	lines = G.S.camp if name == "camp" else G.S.events.get(name, [])
	mouse_filter = Control.MOUSE_FILTER_STOP
	size = Vector2(1920, 1080)
	var conf: Dictionary = GameData.D.vnScenes.get(name, {"bg": "bg_camp.png"})
	if overlay:
		conf = {"bg": ""}
		bg = UI.tex_rect(UI.grad([[0, Color(0, 0, 0, 0.0)], [0.45, Color(0, 0, 0, 0.12)], [1, Color(0, 0, 0, 0.72)]], "v", 4, 128), Rect2(0, 0, 1920, 1080))
	else:
		bg = _bg_rect(conf.bg, conf.get("bgZoom"))
	add_child(bg)
	bg2 = TextureRect.new()
	bg2.visible = false
	add_child(bg2)
	if conf.get("fire", false):
		fire = UI.tex_rect(UI.grad([[0, Color(1, 0.55, 0.16, 0.24)], [1, Color(0, 0, 0, 0)]], "radial", 128, 128, Vector2(0.5, 0.85), 0.55), Rect2(0, 0, 1920, 1080))
		add_child(fire)
		_fire_low = conf.get("fireLow", false)
	if conf.has("emptyBedroll"):
		bedroll = Control.new()
		bedroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bedroll.size = size
		var bp: Array = conf.emptyBedroll
		bedroll.draw.connect(_draw_bedroll.bind(Vector2(bp[0], bp[1])))
		add_child(bedroll)
	# 스탠딩
	var vn: Dictionary = GameData.D.vn
	for k in GameData.D.standing:
		var file: String = GameData.D.standing[k]
		var sz := Assets.size(file)
		var h: float = vn.standH
		var w := h * sz.x / sz.y if sz.y > 0 else 430.0
		var tr := UI.tex_rect(Assets.tex(file), Rect2(960 - w / 2, float(vn.standTop), w, h))
		tr.modulate.a = 0.0
		tr.visible = false
		tr.set_meta("on", false)
		add_child(tr)
		stands[k] = tr
	# 이벤트 제목 (위쪽 작게)
	var tt: String = G.S.eventTitles.get(name, "")
	title_l = UI.label(tt, 26, Color("#d9c9b8"), "serif_bold", HORIZONTAL_ALIGNMENT_CENTER, 6)
	title_l.position = Vector2(560, 34)
	title_l.size = Vector2(800, 40)
	title_l.visible = tt != "" and name != "camp" and not overlay
	add_child(title_l)
	omen = OmenView.new()
	omen.vn = self
	add_child(omen)
	# 대사 상자
	box = Control.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.draw.connect(_draw_box)
	add_child(box)
	face = TextureRect.new()
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(face)
	text_l = UI.rich(34, Color("#f2ebe6"), "serif", "serif_bold")
	text_l.add_theme_constant_override("line_separation", 10)
	box.add_child(text_l)
	name_plate = Control.new()
	name_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_plate.draw.connect(func(): name_plate.draw_style_box(UI.box(Color("#1a0a0e"), Color("#8c1a26"), 8, 1), Rect2(Vector2.ZERO, name_plate.size)))
	box.add_child(name_plate)
	name_l = UI.label("", 30, Color("#ffb6bd"), "serif_bold", HORIZONTAL_ALIGNMENT_CENTER)
	name_plate.add_child(name_l)
	next_l = UI.label("▼", 24, UI.RED, "sans_bold")
	box.add_child(next_l)
	if name == "camp" or name == "emptycamp":
		skip_btn = UI.button(G.ui("skip"), 22, func(): _on_skip(), "sans_bold")
		skip_btn.style_kind = "small"
		skip_btn.fit(Vector2(22, 8))
		skip_btn.position = Vector2(1920 - 130 - skip_btn.size.x, 30)
		add_child(skip_btn)
	relayout()
	box.visible = false


func _bg_rect(file: String, zoom) -> TextureRect:
	var t := UI.cover_rect(Assets.tex(file), Rect2(0, 0, 1920, 1080))
	if zoom != null:
		# 같은 그림의 한 곳(focus)을 확대해 보여 준다
		var sc: float = zoom.scale
		var f := Vector2(zoom.focus[0], zoom.focus[1])
		t.size = Vector2(1920, 1080) * sc
		t.position = Vector2(960, 540) - f * sc
		t.position.x = clampf(t.position.x, 1920 - t.size.x, 0)
		t.position.y = clampf(t.position.y, 1080 - t.size.y, 0)
	return t


func relayout() -> void:
	var u := minf(FX.ui, 1.6)
	var fs := int(34 * u)
	var h := 230.0 + (u - 1.0) * 160.0
	box.position = Vector2(160 if u < 1.2 else 60, 1080 - 30 - h)
	box.size = Vector2(1920 - box.position.x * 2, h)
	text_l.add_theme_font_size_override("normal_font_size", fs)
	text_l.add_theme_font_size_override("bold_font_size", fs)
	name_l.add_theme_font_size_override("font_size", int(30 * u))
	name_l.reset_size()
	var face_on := face.visible and face.texture != null
	var fw := 230.0 if face_on else 0.0
	face.position = Vector2(26, h - 18 - fw)
	face.size = Vector2(fw, fw)
	var left := (290.0 if face_on else 60.0)
	text_l.position = Vector2(left, 54 * u)
	text_l.size = Vector2(box.size.x - left - 70, 0)
	text_l.custom_minimum_size = Vector2(box.size.x - left - 70, 0)
	name_plate.size = name_l.get_combined_minimum_size() + Vector2(60, 16)
	name_plate.position = Vector2(left - 20, -name_plate.size.y / 2.0 - 4)
	name_l.size = name_plate.size
	name_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	next_l.position = Vector2(box.size.x - 50, h - 44)
	box.queue_redraw()


func _draw_box() -> void:
	var r := Rect2(Vector2.ZERO, box.size)
	box.draw_style_box(UI.box(Color(0.03, 0.015, 0.025, 0.93), Color("#5a2a32"), 12, 1), r)
	box.draw_rect(Rect2(6, 0, r.size.x - 12, 3), Color("#8c1a26"))
	if face.visible and face.texture != null:
		box.draw_style_box(UI.box(Color(0, 0, 0, 0), Color("#8c1a26"), 10, 2), Rect2(face.position - Vector2(2, 2), face.size + Vector2(4, 4)))


func _draw_bedroll(p: Vector2) -> void:
	# 비어 있는 침낭: 차갑게 가라앉은 담요 자락과 그 위의 그늘 (코드 연출)
	var c := Color(0.1, 0.12, 0.16, 0.55)
	var pts := PackedVector2Array()
	for i in 24:
		var t := float(i) / 23.0 * TAU
		pts.append(p + Vector2(cos(t) * 190, sin(t) * 46) + Vector2(sin(t * 3) * 8, 0))
	bedroll.draw_colored_polygon(pts, c)
	for i in 3:
		bedroll.draw_arc(p + Vector2(-60 + i * 60, -6), 40, PI * 1.1, PI * 1.9, 12, Color(0.4, 0.45, 0.55, 0.18), 3.0, true)
	for i in 4:
		bedroll.draw_circle(p + Vector2(0, -30), 160.0 + i * 40, Color(0.35, 0.45, 0.65, 0.035))


func _process(delta: float) -> void:
	_t += delta
	if fire:
		var base := 0.55 if _fire_low else 1.0
		fire.modulate.a = base * (0.7 + 0.3 * (0.5 + 0.5 * sin(_t * TAU / 4.8)) + randf_range(-0.04, 0.04))
	if typing:
		shown += delta * float(GameData.D.timing.typeCharsPerSec) * FX.speed
		text_l.visible_characters = int(shown)
		if shown >= full_len:
			typing = false
			text_l.visible_characters = -1
	next_l.visible = not typing and _waiting and box.visible
	next_l.modulate.a = 0.55 + 0.45 * sin(_t * TAU)


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
		accept_event()
		tap()


func tap() -> void:
	if G.dialog.guide_open():
		G.dialog.advance()
		return
	if typing:
		typing = false
		text_l.visible_characters = -1
		return
	tapped.emit()


func _on_skip() -> void:
	skip = true
	tapped.emit()
	if G.dialog.guide_open():
		G.dialog.clear()


func _cond(ln: Dictionary) -> bool:
	if not ln.has("if"):
		return true
	var f: Dictionary = G.ctl.st.get("flags", {})
	for k in ln["if"]:
		if str(f.get(k, "")) != str(ln["if"][k]):
			return false
	return true


func apply_show(show: Dictionary) -> void:
	var slots: Dictionary = GameData.D.vn.slots
	for k in stands:
		var tr: TextureRect = stands[k]
		var on := show.has(k)
		var was: bool = tr.get_meta("on")
		tr.set_meta("on", on)
		if on:
			var tx := float(slots[show[k]]) - tr.size.x / 2.0
			if not was:
				tr.position.x = tx
				tr.visible = true
			var x0 := tr.position.x
			FX.anim(450, [{"x": x0, "a": tr.modulate.a}, {"x": tx, "a": 1.0}], func(v): tr.position.x = v.x; tr.modulate.a = v.a, {"node": tr, "key": "stand_" + k, "easing": "ease"})
		elif was:
			var a0 := tr.modulate.a
			var an := FX.anim(400, [{"a": a0}, {"a": 0.0}], func(v): tr.modulate.a = v.a, {"node": tr, "key": "stand_" + k})
			an.finished.connect(func(): if not tr.get_meta("on"): tr.visible = false)


func set_tag(who: String) -> void:
	for k in tags:
		tags[k].queue_free()
	tags = {}
	if who == "" or not stands.has(who):
		return
	var t := UI.label(str(G.S.tags.get(who, G.name_of(who))), 34, Color("#f6e7c8"), "serif_bold", HORIZONTAL_ALIGNMENT_CENTER, 6)
	var pnl := Control.new()
	pnl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sz := Assets.font("serif_bold").get_string_size(t.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 34) + Vector2(60, 22)
	pnl.size = sz
	pnl.position = Vector2(960 - sz.x / 2.0, 690)
	pnl.draw.connect(func():
		pnl.draw_style_box(UI.box(Color(0.06, 0.03, 0.03, 0.9), UI.GOLD, 6, 2), Rect2(Vector2.ZERO, pnl.size))
		pnl.draw_rect(Rect2(10, pnl.size.y - 5, pnl.size.x - 20, 2), UI.RED))
	t.size = sz
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pnl.add_child(t)
	pnl.modulate.a = 0.0
	add_child(pnl)
	move_child(pnl, box.get_index())
	FX.anim(500, [{"a": 0.0, "y": 710.0}, {"a": 1.0, "y": 690.0}], func(v): if is_instance_valid(pnl): pnl.modulate.a = v.a; pnl.position.y = v.y, {"node": pnl, "easing": "ease-out"})
	tags[who] = pnl


func set_cg(file: String) -> void:
	var nb := UI.cover_rect(Assets.tex(file), Rect2(0, 0, 1920, 1080))
	nb.modulate.a = 0.0
	add_child(nb)
	move_child(nb, bg.get_index() + 1)
	var old := bg
	bg = nb
	var a := FX.anim(900, [{"a": 0.0}, {"a": 1.0}], func(v): if is_instance_valid(nb): nb.modulate.a = v.a, {"node": nb})
	a.finished.connect(func(): if is_instance_valid(old): old.queue_free())
	if fire:
		fire.visible = false


func _dim_speakers(sp: String) -> void:
	var who := "noel" if sp == "inner" else sp
	var any: bool = stands.has(who) and bool(stands[who].get_meta("on"))
	for k in stands:
		var tr: TextureRect = stands[k]
		var lit: bool = (k == who) or not any or sp == "narr"
		tr.self_modulate = Color.WHITE if lit else Color(0.5, 0.48, 0.5)


## 한 줄을 보여 주고 탭을 기다린다
func show_line(ln: Dictionary) -> void:
	var sp: String = ln.get("speaker", "narr")
	_dim_speakers(sp)
	var nm := ""
	if sp == "inner":
		nm = G.name_of("noel")
	elif sp != "narr":
		nm = G.name_of(sp)
	name_plate.visible = nm != ""
	name_l.text = nm
	var has_face: bool = ln.has("face") and Assets.ok(Assets.expression_file(ln.face))
	face.visible = has_face
	if has_face:
		var who := "noel" if sp == "inner" else sp
		face.texture = Assets.face_tex(who, ln.face, true)
	var t := str(ln.text)
	var col := Color("#f2ebe6")
	if sp == "narr":
		col = Color("#cfc6c0")
	elif sp == "inner":
		col = Color("#d8c0ce")
		t = "(" + t + ")"
	text_l.add_theme_color_override("default_color", col)
	text_l.text = UI.esc(t)
	full_len = text_l.get_parsed_text().length()
	shown = 0.0
	text_l.visible_characters = 0
	typing = true
	box.visible = true
	relayout()
	G.ctl.note("vn %s %d" % [scene_name, line_index])
	G.dialog.log.append(("" if nm == "" else nm + ": ") + str(ln.text))
	await _wait_tap()


func _wait_tap() -> void:
	if skip:
		return
	_waiting = true
	if G.autoguide:
		# 자동 시험: 글자가 다 나온 뒤 잠시 머물고 넘어간다
		while typing and not skip:
			await get_tree().process_frame
		var t0 := FX.now_ms()
		while FX.now_ms() - t0 < FX.ms(600) and not skip:
			await get_tree().process_frame
		_waiting = false
		return
	await tapped
	_waiting = false


## 대본을 처음부터 끝까지
func run() -> void:
	await play_lines(lines)


func play_lines(list: Array) -> void:
	for i in list.size():
		var ln: Dictionary = list[i]
		if list == lines:
			line_index = i
		if not is_inside_tree():
			return
		if skip and not ln.has("choice") and not ln.has("call"):
			continue
		if not _cond(ln):
			continue
		if ln.has("omen"):
			box.visible = false
			await omen.show_omen(ln.omen)
			continue
		if ln.has("omen_sharpen"):
			box.visible = false
			await omen.sharpen(ln.omen_sharpen)
			continue
		if ln.has("omen_levelup"):
			box.visible = false
			await omen.level_up()
			continue
		if ln.has("omen_end"):
			await omen.hide_omen()
			continue
		if ln.has("choice"):
			box.visible = false
			var picked: Dictionary = await choose(ln.choice)
			G.ctl.st.flags[ln.get("key", "choice")] = picked.value
			G.ctl.note("choice %s=%s" % [ln.get("key", "choice"), picked.value])
			await play_lines(picked.get("lines", []))
			continue
		if ln.has("call"):
			box.visible = false
			await do_call(str(ln.call))
			continue
		if ln.has("show"):
			apply_show(ln.show)
		if ln.has("cg"):
			set_cg(ln.cg)
		if ln.has("tag"):
			set_tag(str(ln.tag))
		if not ln.has("text"):
			continue
		if ln.get("speaker", "") == "system":
			box.visible = false
			await G.dialog.say([{"who": "system", "text": ln.text}])
			continue
		await show_line(ln)


## 선택지: 버튼을 띄우고 고른 것을 돌려준다
func choose(opts: Array) -> Dictionary:
	var w := DialogBox.Waiter.new()
	var picked := [opts[0]]
	choice_btns = []
	var y := 600.0 - opts.size() * 60.0
	for o in opts:
		var b := UI.button(str(o.text), int(36 * minf(FX.ui, 1.4)), func():
			picked[0] = o
			w.finish(), "serif_bold")
		b.style_kind = "choice"
		b.set_meta("value", o.value)
		b.fit(Vector2(80, 22))
		b.size.x = maxf(b.size.x, 560)
		b.lbl.size = b.size
		b.position = Vector2(960 - b.size.x / 2.0, y)
		y += b.size.y + 34
		add_child(b)
		choice_btns.append(b)
	if G.autoguide and G.params.has("choice"):
		get_tree().create_timer(0.3).timeout.connect(func():
			for o in opts:
				if str(o.value) == str(G.params.choice):
					picked[0] = o
			w.finish())
	await w.done
	for b in choice_btns:
		b.queue_free()
	choice_btns = []
	return picked[0]


## 테스트·바로 가기: 선택지를 값으로 고른다
func pick_choice(value: String) -> bool:
	for b in choice_btns:
		if b.lbl.text == value or str(value) == str(b.get_meta("value", "")):
			b.pressed.emit()
			return true
	return false


func do_call(what: String) -> void:
	var st: Dictionary = G.ctl.st
	# 새 운명: "fate:운명id" → 그 동료의 죽음 카드(Lv1)가 노엘 손에 (game_data.gd fatePlan)
	if what.begins_with("fate:"):
		var fid := what.substr(5)
		for p in GameData.D.fatePlan:
			if p.fate == fid:
				Rules.add_fate(st, fid, int(p.floor))
		G.ctl.note("fate add " + fid)
		return
	match what:
		"descend":
			G.ctl.descend_events = Rules.descend(st)
			G.ctl.note("descend → %d층" % Rules.floor_now(st))
		"heal":
			if bool(GameData.D.fateRules.get("healOnFloor", true)):
				Rules.heal_all(st)
		"rest":
			Rules.apply_rest(st)
			G.ctl.note("rest")
		"train":
			var picker := TrainPicker.new()
			add_child(picker)
			var id: String = await picker.run()
			picker.queue_free()
			var u := Rules.upgrade_card(st, id)
			G.ctl.note("train " + id + " " + u)
			var up: Dictionary = GameData.D.upgrades.get(id, {})
			FX.toast(str(G.S.trainResult).replace("{card}", Rules.card_name(id, true)).replace("{summary}", str(up.get("summary", ""))), 2200)


## 스탠딩 그림에서 붉은 실이 나오는 곳 (가슴께)
func anchor_of(who: String):
	if not stands.has(who) or not stands[who].get_meta("on"):
		return null
	var tr: TextureRect = stands[who]
	var an: Array = GameData.D.omen.anchors.get(who, [0.5, 0.3])
	return tr.position + tr.size * Vector2(an[0], an[1])


# ───────── 훈련: 강화할 카드 고르기 ─────────
class TrainPicker extends Control:
	signal chosen(id)
	var cards := []

	func run() -> String:
		mouse_filter = Control.MOUSE_FILTER_STOP
		size = Vector2(1920, 1080)
		var st: Dictionary = G.ctl.st
		var ids := Rules.train_candidates(st)
		var dim := ColorRect.new()
		dim.color = Color(0, 0, 0, 0.6)
		dim.size = size
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dim)
		var title := UI.label(G.ui("trainTitle"), 44, Color("#f6e7c8"), "serif_bold", HORIZONTAL_ALIGNMENT_CENTER, 6)
		title.position = Vector2(0, 150)
		title.size = Vector2(1920, 60)
		add_child(title)
		var hint := UI.label(G.ui("trainHint"), 26, Color("#c9b9bc"), "sans", HORIZONTAL_ALIGNMENT_CENTER)
		hint.position = Vector2(0, 215)
		hint.size = Vector2(1920, 40)
		add_child(hint)
		var k := 1.25
		var gap := 80.0
		var total := ids.size() * CardView.W * k + (ids.size() - 1) * gap
		var x0 := 960 - total / 2.0
		var picked := [""]
		var w := DialogBox.Waiter.new()
		for i in ids.size():
			var id: String = ids[i]
			var tmp := "tmp_train_%d" % i
			st.cards[tmp] = {"uid": tmp, "id": id, "up": true}
			var holder := Node2D.new()
			add_child(holder)
			var cv := CardView.new()
			holder.add_child(cv)
			cv.setup_face(st, tmp)
			var pos := Vector2(x0 + i * (CardView.W * k + gap), 300)
			cv.set_rect(pos, k, true)
			cv.glow = 1.0
			st.cards.erase(tmp)
			var summary: String = GameData.D.upgrades[id].summary
			var sl := UI.label(summary, 28, Color("#ffcf6a"), "sans_bold", HORIZONTAL_ALIGNMENT_CENTER, 4)
			sl.position = Vector2(pos.x - 40, pos.y + CardView.H * k + 20)
			sl.size = Vector2(CardView.W * k + 80, 40)
			add_child(sl)
			var hit := Btn.new()
			hit.setup("", 10)
			hit.position = pos
			hit.size = Vector2(CardView.W, CardView.H) * k + Vector2(0, 70)
			hit.self_modulate.a = 0.0
			hit.set_meta("value", id)
			hit.pressed.connect(func():
				picked[0] = id
				w.finish())
			add_child(hit)
			cards.append(hit)
		if G.autoguide and G.params.has("train"):
			get_tree().create_timer(0.3).timeout.connect(func():
				picked[0] = G.params.train if ids.has(G.params.train) else ids[0]
				w.finish())
		await w.done
		return picked[0]

	func pick(id: String) -> bool:
		for h in cards:
			if h.get_meta("value") == id:
				h.pressed.emit()
				return true
		return false
