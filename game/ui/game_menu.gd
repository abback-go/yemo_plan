## game_menu.gd — 메뉴 단추(화면 오른쪽 위 — 휴대폰은 이것으로 연다) · 일시정지(Esc): 계속 / 설정 / 타이틀로 · 설정 · 확인 창.
## 설정은 타이틀과 일시정지에서 같은 화면을 연다. 판은 VN 대화창과 같은 양피지(ui_dialog_box.png 9조각) 위에 먹색·진홍 글씨.
## 일시정지: get_tree().paused + FX 연출 시계 멈춤(FX.set_paused). 타이머도 멈추므로(create_timer(…, false)) 전투 연출·데스신 도중에도
##   그 자리에서 멈췄다가 「계속」하면 이어진다. 이 노드는 일시정지 중에도 돈다(PROCESS_MODE_ALWAYS).
## 타이틀로: 확인 뒤 게임 화면을 새로 만든다(main.gd restart_to_title) — 진행은 마지막 자동 저장까지만 남는다.
class_name GameMenu
extends Control

var corner: Btn               # 메뉴 단추 (일시정지 기호)
var layer: Control            # 지금 열린 판
var panel := ""               # "" | pause | settings | confirm
var paused := false
var buttons := {}             # 이름 → Btn (시험: geom)
var _back := []               # 판을 닫으면 돌아갈 판
var _confirm: DialogBox.Waiter = null
var _confirm_yes := false
var _sample: RichTextLabel
var _sample_t := 0.0
var _fs_note: Label
var _fs_wait := -1.0
var _fs_wanted := false
var _opts := {}               # 설정 단추 묶음: "display" | "speed" → {값: Btn}

const INK := Color("#2b1a12")
const CRIMSON := Color("#78141e")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer = Control.new()
	layer.size = size
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	corner = UI.button("", 20, open_pause, "sans_bold")
	corner.style_kind = "small"
	corner.name = "menu"
	var icon := Control.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.draw.connect(func():
		var s := corner.size
		var bw := s.x * 0.12
		var bh := s.y * 0.42
		for dx in [-0.11, 0.11]:
			icon.draw_rect(Rect2(s.x * (0.5 + dx) - bw / 2.0, (s.y - bh) / 2.0, bw, bh), Color("#f7e9eb")))
	corner.add_child(icon)
	corner.set_meta("icon", icon)
	add_child(corner)
	_place_corner()


## 화면 오른쪽 위 구석. 휴대폰(작은 화면)이면 글씨 배율만큼 키운다(누르는 영역은 Btn 이 실제 화면 44px 이상으로 넓힌다).
## 지도에서는 오른쪽 칸(층 이름 줄)의 오른쪽 끝에 넣는다 — 구석에 두면 칸의 테두리 모서리를 덮는다
func _place_corner() -> void:
	var r := _corner_rect(G.scenes != null and G.scenes.current is FloorMap)
	corner.size = r.size
	corner.pivot_offset = r.size / 2.0
	corner.position = r.position
	var icon: Control = corner.get_meta("icon")
	icon.size = corner.size
	icon.queue_redraw()


func _corner_rect(on_map: bool) -> Rect2:
	var u := clampf(FX.ui, 1.0, 1.4 if on_map else 1.6)
	var sz := Vector2(60, 52) * u
	if on_map:
		var pr: Rect2 = FloorMap.PANEL
		return Rect2(Vector2(pr.end.x - 14 - sz.x, pr.position.y + maxf(4.0, (84.0 - sz.y) / 2.0)), sz)
	return Rect2(Vector2(1920 - 12 - sz.x, 16), sz)


## 메뉴 단추가 누르는 영역의 왼쪽 끝(무대 x, 지도 밖) — 오른쪽 위에 놓는 다른 단추(VN 건너뛰기)는 이보다 왼쪽에
func corner_left() -> float:
	var r := _corner_rect(false)
	var need := 44.0 / maxf(0.05, FX.css_scale)
	return r.position.x - maxf(0.0, (need - r.size.x) / 2.0)


## 지금 메뉴 단추가 누르는 영역(무대 좌표, 지도면 지도 자리 — Btn._has_point 와 같게 실제 화면 44px 이상으로 넓힌 것).
## 화면 위 전체 폭 안내 상자(dialog_box.gd)가 이 자리를 피한다 — 휴대폰에서 겹치면 안내를 넘기려던 탭이 일시정지를 열었다
func corner_hit_rect() -> Rect2:
	var r := _corner_rect(G.scenes != null and G.scenes.current is FloorMap)
	var need := 44.0 / maxf(0.05, FX.css_scale)
	var pad := Vector2(maxf(0.0, (need - r.size.x) / 2.0), maxf(0.0, (need - r.size.y) / 2.0))
	return Rect2(r.position - pad, r.size + pad * 2.0)


func can_pause() -> bool:
	if G.scenes == null or G.ctl == null or G.main == null:
		return false
	if G.main.rotate_hint != null and G.main.rotate_hint.visible:
		return false
	return G.scenes.current_name != "title"


func _process(delta: float) -> void:
	_place_corner()
	corner.visible = panel == "" and can_pause()
	if _sample != null and is_instance_valid(_sample):
		_sample_t += delta
		var n := int(_sample_t * GameSettings.chars_per_sec())
		var full := _sample.get_parsed_text().length()
		_sample.visible_characters = mini(n, full)
		if n > full + int(1.4 * GameSettings.chars_per_sec()) or (GameSettings.text_speed == "instant" and _sample_t > 1.4):
			_sample_t = 0.0
	if _fs_wait >= 0.0:
		_fs_wait -= delta
		if _fs_wait < 0.0:
			_refresh_opts()
			if _fs_note != null and is_instance_valid(_fs_note):
				_fs_note.visible = not GameSettings.is_fullscreen() and _fs_wanted


func _input(e: InputEvent) -> void:
	if not (e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_ESCAPE):
		return
	if G.main != null and G.main.rotate_hint != null and G.main.rotate_hint.visible:
		return
	match panel:
		"confirm":
			_answer(false)
		"settings":
			close_settings()
		"pause":
			resume()
		_:
			if G.input != null and G.input.mode in ["drag", "pick"]:
				return   # 끌던 카드 취소가 먼저 (battle_input.gd)
			if not can_pause():
				return
			open_pause()
	get_viewport().set_input_as_handled()


# ───────── 일시정지 ─────────
func open_pause() -> void:
	if paused or not can_pause():
		return
	if G.input != null and G.input.mode in ["drag", "pick"]:
		G.input.cancel_drag()
	paused = true
	get_tree().paused = true
	FX.set_paused(true)
	G.ctl.note("pause")
	_show_pause()


func resume() -> void:
	_close_layer()
	panel = ""
	_back = []
	if paused:
		paused = false
		get_tree().paused = false
		FX.set_paused(false)
		G.ctl.note("resume")


func _show_pause() -> void:
	var box := _panel(720, 560)
	_title(box, G.menu_text("pauseTitle"), 720)
	var y := 150.0
	for it in [["resume", resume], ["settings", open_settings], ["toTitle", _to_title]]:
		var b := _button(box, str(it[0]), G.menu_text(it[0]), it[1], 34)
		b.size.x = 380
		b.lbl.size = b.size
		b.position = Vector2(360 - 190, y)
		y += b.size.y + 30
	var sv: Dictionary = G.ctl.load_save()
	var t := G.menu_text("savedAt", {"place": place_of(sv)}) if not sv.is_empty() else G.menu_text("noSave")
	var l := UI.label(t, 24, INK, "serif", HORIZONTAL_ALIGNMENT_CENTER)
	l.position = Vector2(60, y + 6)
	l.size = Vector2(600, 40)
	box.add_child(l)
	panel = "pause"


func _to_title() -> void:
	var yes := await confirm(G.menu_text("toTitleTitle"), G.menu_text("toTitleText"), G.menu_text("toTitle"), G.menu_text("cancel"))
	if yes:
		G.main.restart_to_title()


# ───────── 새로 시작 (타이틀의 시작·2층부터·3층부터) ─────────
## 저장이 있으면 "처음부터 시작하면 저장이 지워진다"를 한 번 묻는다
func new_run(start: Callable) -> void:
	if panel != "":
		return
	if not G.ctl.load_save().is_empty():
		var yes := await confirm(G.menu_text("newTitle"), G.menu_text("newText"), G.menu_text("newYes"), G.menu_text("cancel"))
		if not yes:
			return
		G.ctl.clear_save()
	start.call()


# ───────── 확인 창 ─────────
## 반환: 예(true) / 아니요·Esc(false)
func confirm(title: String, text: String, yes: String, no: String) -> bool:
	_back.append(panel)
	_close_layer()
	var box := _panel(900, 400)
	_title(box, title, 900)
	var l := UI.label(text, 30, INK, "serif", HORIZONTAL_ALIGNMENT_CENTER)
	l.position = Vector2(80, 140)
	l.size = Vector2(740, 50)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(l)
	var by := _button(box, "yes", yes, func(): _answer(true), 32)
	var bn := _button(box, "no", no, func(): _answer(false), 32)
	var w := maxf(maxf(by.size.x, bn.size.x), 220.0)
	for b in [by, bn]:
		b.size.x = w
		b.lbl.size = b.size
	by.position = Vector2(450 - 24 - w, 240)
	bn.position = Vector2(450 + 24, 240)
	panel = "confirm"
	_confirm = DialogBox.Waiter.new()
	_confirm_yes = false
	G.ctl.note("confirm " + title)
	await _confirm.done
	_confirm = null
	var prev: String = _back.pop_back() if not _back.is_empty() else ""
	_close_layer()
	panel = ""
	if not _confirm_yes:
		_reopen(prev)
	return _confirm_yes


func _answer(yes: bool) -> void:
	if _confirm == null:
		return
	_confirm_yes = yes
	_confirm.finish()


func _reopen(p: String) -> void:
	match p:
		"pause":
			_show_pause()
		"settings":
			_show_settings()
		_:
			panel = ""


# ───────── 설정 ─────────
func open_settings() -> void:
	_back.append(panel)
	_close_layer()
	_show_settings()


func close_settings() -> void:
	_close_layer()
	panel = ""
	_reopen(_back.pop_back() if not _back.is_empty() else "")


func _show_settings() -> void:
	var W := 1120.0
	var box := _panel(W, 620)
	_title(box, G.menu_text("settingsTitle"), W)
	_opts = {"display": {}, "speed": {}}
	var lx := 120.0
	var ox := 400.0
	var y := 150.0
	box.add_child(_row_label(G.menu_text("display"), lx, y))
	var x := ox
	for v in ["windowed", "fullscreen"]:
		var on: bool = v == "fullscreen"
		var b := _button(box, "display_" + v, G.menu_text(v), func(): _set_display(on), 28, "sans_bold")
		b.position = Vector2(x, y)
		x += b.size.x + 18
		_opts.display[v] = b
	_fs_note = UI.label(G.menu_text("fullscreenFail"), 22, CRIMSON, "sans_bold")
	_fs_note.position = Vector2(ox, y + 70)
	_fs_note.size = Vector2(640, 30)
	_fs_note.visible = false
	box.add_child(_fs_note)
	if not GameSettings.fullscreen_available():
		_opts.display.fullscreen.disabled = true
		_fs_note.visible = true
	y = 280.0
	box.add_child(_row_label(G.menu_text("textSpeed"), lx, y))
	x = ox
	for v in GameSettings.SPEEDS:
		var sp: String = v
		var b := _button(box, "speed_" + sp, G.menu_text(sp), func(): _set_speed(sp), 28, "sans_bold")
		b.position = Vector2(x, y)
		x += b.size.x + 18
		_opts.speed[sp] = b
	_sample = UI.rich(30, INK, "serif", "serif_bold")
	_sample.position = Vector2(ox + 4, y + 86)
	_sample.size = Vector2(620, 0)
	_sample.custom_minimum_size = Vector2(620, 0)
	_sample.text = G.menu_text("sample")
	_sample.visible_characters = 0
	_sample_t = 0.0
	box.add_child(_sample)
	var c := _button(box, "close", G.menu_text("close"), close_settings, 32)
	c.size.x = maxf(c.size.x, 260)
	c.lbl.size = c.size
	c.position = Vector2(W / 2.0 - c.size.x / 2.0, 480)
	panel = "settings"
	_refresh_opts()


func _row_label(t: String, x: float, y: float) -> Label:
	var l := UI.label(t, 32, INK, "serif_bold")
	l.position = Vector2(x, y + 6)
	l.size = Vector2(260, 50)
	return l


## 웹: 브라우저가 사용자 입력 안에서만 전체 화면을 허락하므로 이 단추 처리 안에서 바로 바꾼다. 바뀌었는지는 잠시 뒤 다시 본다
func _set_display(full: bool) -> void:
	_fs_wanted = full
	GameSettings.set_fullscreen(full)
	G.ctl.note("display " + ("fullscreen" if full else "windowed"))
	_fs_wait = 0.6 if full else 0.2
	if _fs_note != null:
		_fs_note.visible = false
	_refresh_opts()


func _set_speed(sp: String) -> void:
	GameSettings.set_text_speed(sp)
	G.ctl.note("text speed " + sp)
	_sample_t = 0.0
	_refresh_opts()


## 고른 값은 진홍 테두리 + 흰 글씨, 나머지는 흐린 단추
func _refresh_opts() -> void:
	if _opts.is_empty():
		return
	var cur := {"display": "fullscreen" if GameSettings.is_fullscreen() else "windowed", "speed": GameSettings.text_speed}
	for g in _opts:
		for v in _opts[g]:
			var b: Btn = _opts[g][v]
			if not is_instance_valid(b):
				continue
			var on: bool = v == cur[g]
			b.style_kind = "main" if on else "small"
			b.lbl.add_theme_color_override("font_color", Color("#fff4f5") if on else Color("#bda7aa"))
			b.modulate.a = 1.0 if on else 0.62
			b.set_meta("selected", on)
			b.queue_redraw()


# ───────── 판 만들기 ─────────
## 어둡게 덮고(뒤를 누를 수 없게) 가운데 양피지 판. 반환: 판 안쪽 좌표의 상자(작은 화면이면 통째로 키운다)
func _panel(w: float, h: float) -> Control:
	_close_layer()
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.0, 0.01, 0.72)
	dim.size = size
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(dim)
	var k := clampf(FX.ui * 0.85, 1.0, 1.5)
	var box := Control.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.size = Vector2(w, h)
	box.scale = Vector2(k, k)
	box.position = Vector2(960 - w * k / 2.0, 540 - h * k / 2.0)
	layer.add_child(box)
	var VB: Dictionary = GameData.D.vnBox
	if Assets.ok(str(VB.img)):
		var fr := NinePatchRect.new()
		fr.texture = Assets.tex(str(VB.img))
		var mg: Array = VB.margin
		fr.patch_margin_left = int(mg[0])
		fr.patch_margin_top = int(mg[1])
		fr.patch_margin_right = int(mg[2])
		fr.patch_margin_bottom = int(mg[3])
		fr.size = box.size
		fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(fr)
	else:
		box.add_child(UI.panel(UI.box(Color("#c8a982"), CRIMSON, 12, 2)))
		box.get_child(0).size = box.size
	buttons = {}
	return box


func _title(box: Control, t: String, w: float) -> void:
	var l := UI.label(t, 44, CRIMSON, "serif_bold", HORIZONTAL_ALIGNMENT_CENTER)
	l.position = Vector2(0, 46)
	l.size = Vector2(w, 64)
	box.add_child(l)


func _button(box: Control, id: String, text: String, cb: Callable, fs := 32, font := "serif_bold") -> Btn:
	var b := UI.button(text, fs, cb, font)
	b.name = id
	b.fit(Vector2(40, 14))
	box.add_child(b)
	buttons[id] = b
	return b


func _close_layer() -> void:
	for c in layer.get_children():
		c.queue_free()
		layer.remove_child(c)
	_sample = null
	_fs_note = null
	_opts = {}
	buttons = {}


## 저장한 곳 이름: "장례 탑 1층 · 광신도 기도실" / "2층 · 창 함정 회랑" / "장례 탑 1층 끝"
static func place_of(sv: Dictionary) -> String:
	if sv.is_empty():
		return ""
	var st: Dictionary = sv.st
	var fl := int(st.progress.floor)
	var M: Dictionary = G.S.map
	var fname := str(M.floors.get(fl, "%d층" % fl))
	var step := str(sv.step)
	if step == "chapter1":
		return G.menu_text("floorEnd", {"floor": fname})
	var id := str(sv.room) if step == "map" else step
	if M.rooms.has(id):
		return fname + " · " + str(M.rooms[id].name)
	return fname + " · " + str(G.S.eventTitles.get(id, id))
