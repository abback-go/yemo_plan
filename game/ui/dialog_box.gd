## dialog_box.gd — 전투 중 대사창(화면 왼쪽 위 + 작은 얼굴)과 안내 상자(화면 위쪽 가운데).
##  · 캐릭터 대사: 글자가 다 나오면 잠시 머문 뒤 저절로 넘어간다(탭하면 바로).
##  · 안내 상자(who = system): 탭해야 넘어가고, 떠 있는 동안 진행이 멈춘다(대본 8장). 같은 안내는 한 번만.
##    (본 안내 목록은 user://guides.cfg 에 남겨 다시 하기 후에도 다시 나오지 않는다. 주소 ?guides=reset 으로 초기화)
## HTML 판 dialog.js 를 옮긴 것.
class_name DialogBox
extends Node2D

class Waiter extends RefCounted:
	signal done
	var finished := false
	func finish() -> void:
		if finished:
			return
		finished = true
		done.emit()

const SEEN_FILE := "user://guides.cfg"

var dlg: Control
var dlg_face: TextureRect
var dlg_name: Label
var dlg_text: RichTextLabel
var guide: Control
var guide_title: Label
var guide_text: RichTextLabel
var guide_hint: Label
var queue: Array = []
var cur = null            # {"line", "waiter", "typing", "full", "n", "hold", "t", "guide"}
var seen := {}            # 본 안내 (글 → true)
var log: Array = []       # 시험용: 보여 준 줄 기록 (최근 300)
var dock := ""            # "" = 화면 왼쪽 위(기본) / "bottom" = 화면 아래, dock_x 부터 오른쪽 끝까지 (탑뷰 시험판: 옆에 스탠딩, 얼굴 칸 없음)
var dock_x := 470.0       # dock = "bottom" 일 때 왼쪽 x
var dock_w := 0.0         # dock = "bottom" 일 때 너비(무대 px). 0 = 오른쪽 끝까지
var _type_acc := 0.0


func _ready() -> void:
	_load_seen()
	if G.params.get("guides", "") == "reset":
		seen = {}
		_save_seen()
	# 대사창
	dlg = Control.new()
	dlg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dlg.visible = false
	add_child(dlg)
	dlg_face = TextureRect.new()
	dlg_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dlg_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dlg_face.stretch_mode = TextureRect.STRETCH_SCALE
	dlg.add_child(dlg_face)
	dlg_name = UI.label("", 26, Color("#ff9aa4"), "serif_bold")
	dlg.add_child(dlg_name)
	dlg_text = UI.rich(28, Color("#f0e8e8"))
	dlg.add_child(dlg_text)
	dlg.draw.connect(_draw_dlg)
	# 안내 상자
	guide = Control.new()
	guide.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guide.visible = false
	add_child(guide)
	guide_title = UI.label(G.ui("systemName"), 24, Color("#c9a24a"), "serif_bold")
	guide.add_child(guide_title)
	guide_text = UI.rich(32, Color("#f6ead0"))
	guide_text.add_theme_constant_override("line_separation", 6)
	guide.add_child(guide_text)
	guide_hint = UI.label(G.ui("tapNext"), 22, Color("#e0a8ae"), "sans_bold", HORIZONTAL_ALIGNMENT_RIGHT)
	guide.add_child(guide_hint)
	guide.draw.connect(_draw_guide)


func _load_seen() -> void:
	var cf := ConfigFile.new()
	if cf.load(SEEN_FILE) == OK and cf.has_section("seen"):
		for k in cf.get_section_keys("seen"):
			seen[str(cf.get_value("seen", k, ""))] = true


func _save_seen() -> void:
	var cf := ConfigFile.new()
	var i := 0
	for t in seen:
		cf.set_value("seen", "g%d" % i, t)
		i += 1
	cf.save(SEEN_FILE)


func reset_seen() -> void:
	seen = {}
	_save_seen()


# ───────── 배치 (작은 화면이면 글씨·상자를 키운다) ─────────
func relayout() -> void:
	var u := FX.ui
	var w := 560.0
	var fs := 26
	dlg_face.position = Vector2(14, 14)
	dlg_face.size = Vector2(104, 104)
	dlg_name.position = Vector2(134, 12)
	dlg_text.position = Vector2(134, 50)
	dlg_text.size = Vector2(w - 134 - 20, 0)
	dlg_text.custom_minimum_size = Vector2(w - 134 - 20, 0)
	dlg_text.add_theme_font_size_override("normal_font_size", fs)
	dlg.position = Vector2(24, 20)
	dlg.scale = Vector2(u, u)
	dlg.size = Vector2(w, 132)
	if dock == "bottom":
		w = (dock_w if dock_w > 0.0 else 1920.0 - dock_x - 30.0) / u
		fs = 30
		dlg_text.position = Vector2(24, 50)
		dlg_name.position = Vector2(24, 12)
		dlg_text.size = Vector2(w - 48, 0)
		dlg_text.custom_minimum_size = Vector2(w - 48, 0)
		dlg_text.add_theme_font_size_override("normal_font_size", fs)
		dlg.size = Vector2(w, 132)
		dlg.position = Vector2(dock_x, 1080 - 26 - 132 * u)
	var gw := minf(1180.0, 1840.0 / u)
	# 전투 중에는 적·예고를 가리지 않게 적 줄 바로 아래(화면 위쪽 절반)에, 그 밖에는 화면 맨 위에 띄운다
	var gy := 18.0
	if G.ctl and G.ctl.in_battle and not G.scenes.is_open():
		gy = float(G.view.LY().get("guideBattleY", 396))   # 배경마다 (battleLayouts)
	var gx := 960 - gw * u / 2.0
	# 오른쪽 위 메뉴 단추(누르는 영역)와 겹치면 상자 오른쪽 끝을 그 왼쪽까지 줄인다(휴대폰처럼 상자가 화면 폭을 거의 다 쓸 때)
	if G.menu != null and G.menu.can_pause():
		var cr: Rect2 = G.menu.corner_hit_rect()
		if gy < cr.end.y and gx + gw * u > cr.position.x - 12.0:
			gw = (cr.position.x - 12.0 - gx) / u
	guide.size = Vector2(gw, 150)
	guide.scale = Vector2(u, u)
	guide.position = Vector2(gx, gy)
	guide_title.position = Vector2(30, 14)
	guide_text.position = Vector2(30, 52)
	guide_text.size = Vector2(gw - 60, 0)
	guide_text.custom_minimum_size = Vector2(gw - 60, 0)
	_fit()


func _fit() -> void:
	# 글 높이에 맞춰 상자 높이
	if dlg.visible:
		var th: float = dlg_text.get_content_height()
		dlg.size.y = maxf(132.0, 50.0 + th + 18.0)
		if dock == "bottom":
			dlg.position.y = 1080 - 26 - dlg.size.y * dlg.scale.y
		dlg.queue_redraw()
	if guide.visible:
		var gh: float = guide_text.get_content_height()
		guide.size.y = 52.0 + gh + 58.0
		guide_hint.position = Vector2(guide.size.x - 330, guide.size.y - 40)
		guide_hint.size = Vector2(300, 30)
		guide.queue_redraw()


func _draw_dlg() -> void:
	var r := Rect2(Vector2.ZERO, dlg.size)
	dlg.draw_style_box(UI.box(Color(0.06, 0.035, 0.05, 0.93), Color("#6e2a31"), 10, 1), r)
	var left := Color("#c9a24a") if cur != null and cur.line.who == "system" else UI.RED
	dlg.draw_rect(Rect2(0, 6, 5, r.size.y - 12), left)
	if dlg_face.visible:
		dlg.draw_style_box(UI.box(Color(0, 0, 0, 0), Color("#5a2a32"), 8, 2), Rect2(dlg_face.position - Vector2(2, 2), dlg_face.size + Vector2(4, 4)))


func _draw_guide() -> void:
	var r := Rect2(Vector2.ZERO, guide.size)
	for i in 3:
		guide.draw_style_box(UI.box(Color(0, 0, 0, 0.18), Color.TRANSPARENT, 18 + i * 4), r.grow(4 + i * 5))
	guide.draw_style_box(UI.box(Color(0.07, 0.045, 0.03, 0.95), Color("#c9a24a"), 14, 2), r)
	guide.draw_rect(Rect2(14, 46, r.size.x - 28, 1), Color(0.79, 0.64, 0.29, 0.35))


# ───────── 대사 ─────────
## lines: [{who, text, face?, faces?, pause?}] → 모두 보여 준 뒤 끝난다 (await)
func say(lines: Array) -> void:
	var out := []
	for ln in lines:
		if ln.get("who", "") == "system" and seen.has(str(ln.text)):
			continue
		out.append(ln)
	if out.is_empty():
		return
	var w := Waiter.new()
	for i in out.size():
		queue.append({"line": out[i], "waiter": w if i == out.size() - 1 else null})
	if cur == null:
		_pump()
	if not w.finished:
		await w.done


func clear() -> void:
	var q := queue
	queue = []
	if cur != null and cur.waiter:
		cur.waiter.finish()
	cur = null
	for x in q:
		if x.waiter:
			x.waiter.finish()
	dlg.visible = false
	guide.visible = false


func is_busy() -> bool:
	return cur != null or not queue.is_empty()


## 안내 상자가 떠 있는가 (떠 있는 동안 카드를 낼 수 없다)
func guide_open() -> bool:
	return cur != null and cur.guide


## 아직 못 읽은 지난 줄은 버린다(새 턴이 시작될 때 밀려서 늦게 나오지 않게). 안내 상자는 버리지 않는다
func drop_pending() -> void:
	var keep := []
	for x in queue:
		if x.line.get("who", "") == "system":
			keep.append(x)
		elif x.waiter:
			x.waiter.finish()
	queue = keep
	if cur != null and not cur.guide:
		_next()


func _pump() -> void:
	if queue.is_empty():
		cur = null
		dlg.visible = false
		guide.visible = false
		return
	var item: Dictionary = queue.pop_front()
	var ln: Dictionary = item.line
	var who: String = ln.get("who", "")
	var is_guide := who == "system"
	cur = {"line": ln, "waiter": item.waiter, "typing": true, "full": "", "n": 0, "hold": 0.0, "t": 0.0, "guide": is_guide, "faces": [], "fi": 0}
	log.append(("[안내] " if is_guide else (G.name_of(who) + ": ")) + str(ln.text))
	if log.size() > 300:
		log.pop_front()
	if is_guide:
		seen[str(ln.text)] = true
		_save_seen()
		dlg.visible = false
		guide.visible = true
		guide_text.text = UI.markup(str(ln.text))
		guide_text.visible_characters = 0
		cur.full = guide_text.get_parsed_text()
		guide_hint.visible = false
	else:
		guide.visible = false
		dlg.visible = true
		var face_who := "noel" if who == "inner" else who
		var faces: Array = ln.get("faces", [ln.get("face")] if ln.has("face") else [null])
		cur.faces = faces
		_set_face(face_who, faces[0])
		dlg_name.text = G.ui("innerName") if who == "inner" else G.name_of(who)
		var t := str(ln.text)
		if who == "inner":
			dlg_text.add_theme_color_override("default_color", Color("#d7c3cf"))
			dlg_text.add_theme_font_override("normal_font", Assets.font("serif"))
		else:
			dlg_text.add_theme_color_override("default_color", Color("#f0e8e8"))
			dlg_text.add_theme_font_override("normal_font", Assets.font("sans"))
		dlg_text.text = UI.esc(t)
		dlg_text.visible_characters = 0
		cur.full = dlg_text.get_parsed_text()
		var T: Dictionary = GameData.D.timing
		cur.hold = float(ln.get("pause", 0)) + float(T.guideBase) + float(T.guidePerChar) * cur.full.length()
	relayout()


func _set_face(who: String, face) -> void:
	var ft := Assets.face_tex(who, face, false) if dock == "" else null
	if ft == null:
		dlg_face.visible = false
		dlg_text.position.x = 24
		dlg_name.position.x = 24
		return
	dlg_face.visible = true
	dlg_face.texture = ft
	dlg_text.position.x = 134
	dlg_name.position.x = 134


func _finish_typing() -> void:
	if cur == null or not cur.typing:
		return
	cur.typing = false
	cur.t = 0.0
	if cur.guide:
		guide_text.visible_characters = -1
		guide_hint.visible = true
	else:
		dlg_text.visible_characters = -1


func _next() -> void:
	if cur == null:
		return
	var w = cur.waiter
	cur = null
	_pump()
	# 기다리던 쪽은 다음 줄을 띄운 뒤에 깨운다(깨어난 쪽이 바로 새 줄을 넣어도 꼬이지 않게)
	if w:
		w.finish()


## 탭: 글자가 나오는 중이면 끝까지, 다 나왔으면 다음
func advance() -> void:
	if cur == null:
		return
	if cur.typing:
		_finish_typing()
	else:
		_next()


func _process(delta: float) -> void:
	if cur == null:
		return
	var ms := delta * 1000.0 * FX.speed
	if cur.typing:
		_type_acc += ms * GameSettings.chars_per_sec() / 1000.0
		var add := int(_type_acc)
		if add > 0:
			_type_acc -= add
			cur.n = mini(cur.full.length(), int(cur.n) + add)
			if cur.guide:
				guide_text.visible_characters = cur.n
			else:
				dlg_text.visible_characters = cur.n
			if cur.n >= cur.full.length():
				_finish_typing()
		_fit()
		return
	cur.t += ms
	if cur.guide:
		# 안내 상자는 탭해야 넘어간다 (자동 시험용 ?autoguide 이면 잠시 뒤 저절로)
		if G.autoguide and cur.t > 900.0:
			_next()
		return
	# 표정이 여러 개면 머무는 동안 차례로 바꾼다 (예: 놀람 → 슬픔 → 텅 빔)
	var faces: Array = cur.faces
	if faces.size() > 1:
		var idx := mini(faces.size() - 1, int(cur.t / (cur.hold / faces.size())))
		if idx != cur.fi:
			cur.fi = idx
			_set_face("noel" if cur.line.who == "inner" else cur.line.who, faces[idx])
	if cur.t >= cur.hold:
		_next()
