class_name EBrewUI
extends CanvasLayer
## 가마솥 달이기 화면 (열려 있는 동안 게임은 멈춤). 기준서: docs/eska/design.md 4-2, 수치: docs/eska/potions.md
## 재료 2개(+ 세 번째 칸 달이슬 = 진한 물약)와 담을 허리띠 칸을 고르고 달인다 → 결과 공개(처음 만든 물약은 "새 물약!") → 마녀 수첩에 기록.
## 키보드: ←→↑↓ 고르기 · Z 넣기/정하기 · X 빼기(비었으면 닫기) · Esc 닫기 / 터치·마우스: 눌러서 고르기, 가마솥 칸을 누르면 뺌.
## 640×360 가로 화면 기준 패널(560×320) — 더 좁으면 통째로 줄인다. 모양은 EHud와 같은 먹빛 바탕 + 보랏빛.

signal closed

const PANEL := Vector2(560, 320)
const LAYER := 45 ## 터치 조작(40) 위 — 패널이 버튼을 가린다
const BREW_TIME := 0.9 ## 달이는 연출 시간 (실제 시간)
const REVEAL_MIN := 0.35 ## 결과 화면을 넘길 수 있기까지
const UNPAUSE_FRAMES := 2 ## 닫은 뒤 몇 프레임 뒤에 게임을 다시 움직임 (닫은 키가 게임에 새지 않게)
const TAP_PAD := 4.0
const BOOK_X := 16.0 ## 마녀 수첩 첫 칸 (패널 좌표)
const BOOK_Y := 228.0
const BOOK_GAP := 48.0
const BOOK_W := 44.0
const BOOK_H := 76.0
const MEMO_CYCLE := 4.0 ## 수첩 머리에 보이는 메모가 바뀌는 간격 (초)

# 색 (EHud·EVfx와 같은 계열, 파랑 없음)
const INK := Color("#14081f")
const PARCH_TOP := Color("#211629")
const PARCH_BOT := Color("#120b19")
const TILE := Color("#1b1124")
const TILE_EDGE := Color("#3d3450")
const PALE := Color("#d9ccff")
const VIOLET := Color("#a98bff")
const MAGENTA := Color("#e352ff")
const GOLD := Color("#ffd77a")
const DIM := Color(0.85, 0.8, 0.95, 0.45)

var eska: EEska
var sel: Array[String] = [] ## 가마솥에 넣은 재료 (최대 2)
var strong := false ## 세 번째 칸 달이슬
var target := 0 ## 담을 허리띠 칸
var focus := "ing:0"
var phase := "pick" ## pick · brewing · reveal
var phase_t := 0.0
var result := {}
var brews := 0 ## 이번에 달인 횟수 (시험용)
var t := 0.0
var _view: View
var _items := {} ## 고를 수 있는 것 id → 사각형 (패널 좌표)
var _closing := -1 ## 닫는 중이면 남은 프레임
var _shake := 0.0 ## 재료가 모자랄 때 가마솥 칸 흔들림
var _sig := ""


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_view = View.new()
	_view.ui = self
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_view)
	_build_items()
	_release_touch()
	get_tree().paused = true
	Sfx.play(&"es_brew_bubble", -8.0)


func _release_touch() -> void:
	var sc := get_tree().current_scene
	var tc: Variant = sc.get("touch") if sc else null
	if tc != null and is_instance_valid(tc) and tc.has_method("release_all"):
		tc.release_all()


## 고를 수 있는 것들의 자리 (패널 좌표)
func _build_items() -> void:
	_items.clear()
	for i in 6:
		_items["ing:%d" % i] = Rect2(16 + (i % 3) * 60, 52 + (i / 3) * 62, 56, 58)
	_items["sock:0"] = Rect2(224, 54, 32, 32)
	_items["sock:1"] = Rect2(276, 54, 32, 32)
	_items["sock:2"] = Rect2(328, 54, 32, 32)
	_items["brew"] = Rect2(236, 156, 112, 26)
	for i in 3:
		_items["slot:%d" % i] = Rect2(392, 52 + i * 40, 152, 34)
	_items["close"] = Rect2(PANEL.x - 30, 6, 24, 22)
	for i in EPotions.NOTEBOOK_ORDER.size(): # 마녀 수첩 칸 (고르면 아래 줄에 설명·메모)
		_items["book:%d" % i] = book_rect(i)


## 마녀 수첩 칸 i의 자리 (패널 좌표)
static func book_rect(i: int) -> Rect2:
	return Rect2(BOOK_X + BOOK_GAP * float(i), BOOK_Y, BOOK_W, BOOK_H)


func is_open() -> bool:
	return _closing < 0


# ═══════════════════════════════════════════════════════════
# 한 프레임 · 입력
# ═══════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if _closing >= 0:
		_closing -= 1
		if _closing < 0:
			get_tree().paused = false
			_release_touch()
			queue_free()
		return
	t += delta
	phase_t += delta
	_shake = maxf(_shake - delta * 3.0, 0.0)
	if phase == "brewing" and phase_t >= BREW_TIME:
		_reveal()
	# 크기 맞추기 + 바뀐 것이 있을 때만 다시 그림 (거품·반짝임은 초당 15번)
	var vs := _view.get_viewport_rect().size
	var sc := minf(1.0, minf((vs.x - 12.0) / PANEL.x, (vs.y - 8.0) / PANEL.y))
	_view.scale = Vector2(sc, sc)
	_view.position = ((vs - PANEL * sc) * 0.5).round()
	_view.size = PANEL
	var sig := "%s|%s|%s|%d|%s|%s|%d|%.2f|%s" % [str(sel), str(strong), focus, target, phase, str(vs), int(t * 15.0), _shake, str(eska.belt.slots) if is_instance_valid(eska) else ""]
	if sig != _sig:
		_sig = sig
		_view.queue_redraw()


func _input(event: InputEvent) -> void:
	if _closing >= 0:
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		get_viewport().set_input_as_handled() # 열려 있는 동안 터치는 모두 이 화면이 받음
		if event is InputEventScreenTouch and event.pressed:
			_tap(event.position)
		return
	if event is InputEventMouseButton:
		get_viewport().set_input_as_handled()
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION:
			_tap(event.position)
		return
	# 키보드 키 · 동작 이벤트(시험 실행기 tap) · 패드 버튼
	if not (event is InputEventKey or event is InputEventAction or event is InputEventJoypadButton) or not event.is_pressed():
		return
	get_viewport().set_input_as_handled()
	var echo: bool = event is InputEventKey and event.echo
	if phase == "brewing":
		return
	if phase == "reveal":
		if not echo and phase_t >= REVEAL_MIN and (event.is_action("es_jump") or event.is_action("es_attack") or event.is_action("es_exit") or event.is_action("ui_accept")):
			_back_to_pick()
		return
	if event.is_action("es_exit") or event.is_action("ui_cancel"):
		if not echo:
			close()
	elif event.is_action("es_left"):
		_move(Vector2.LEFT)
	elif event.is_action("es_right"):
		_move(Vector2.RIGHT)
	elif event.is_action("es_up"):
		_move(Vector2.UP)
	elif event.is_action("es_down"):
		_move(Vector2.DOWN)
	elif not echo and (event.is_action("es_jump") or event.is_action("ui_accept")):
		activate(focus)
	elif not echo and event.is_action("es_attack"):
		_back()


## 화면 좌표를 눌렀다
func _tap(screen_pos: Vector2) -> void:
	if phase == "brewing":
		return
	if phase == "reveal":
		if phase_t >= REVEAL_MIN:
			_back_to_pick()
		return
	var p := (screen_pos - _view.position) / _view.scale.x
	for id: String in _items:
		if (_items[id] as Rect2).grow(TAP_PAD).has_point(p):
			focus = id
			activate(id)
			return


## 방향으로 가장 가까운 것에 초점을 옮김 (주 방향 거리 + 옆 거리 × 2)
func _move(dir: Vector2) -> void:
	var from: Vector2 = (_items[focus] as Rect2).get_center()
	var best := ""
	var best_s := INF
	for id: String in _items:
		if id == focus:
			continue
		var d: Vector2 = (_items[id] as Rect2).get_center() - from
		var along := d.dot(dir)
		if along <= 4.0:
			continue
		var side := absf(d.dot(dir.orthogonal()))
		var s := along + side * 2.0
		if s < best_s:
			best_s = s
			best = id
	if best != "":
		focus = best
		Sfx.play_pitch(&"blip", 1.9, -16.0)


## 고른 것을 실행 (Z 또는 누름)
func activate(id: String) -> void:
	var parts := id.split(":")
	match parts[0]:
		"ing":
			var ing: String = EPotions.ING_ORDER[int(parts[1])]
			if sel.size() < 2:
				sel.append(ing)
			else:
				sel[1] = ing
			Sfx.play_pitch(&"es_brew_plop", randf_range(0.9, 1.1), -6.0)
			if sel.size() == 2 and focus.begins_with("ing"):
				focus = "brew" # 두 개 넣으면 바로 달이기로
		"sock":
			var k := int(parts[1])
			if k == 2:
				strong = not strong
				Sfx.play_pitch(&"es_brew_plop", 1.25 if strong else 0.8, -6.0)
			elif k < sel.size():
				sel.remove_at(k)
				Sfx.play_pitch(&"blip", 1.2, -12.0)
		"slot":
			target = int(parts[1])
			Sfx.play_pitch(&"blip", 1.5, -12.0)
		"brew":
			brew()
		"close":
			close()
		_:
			pass # 수첩 칸: 고르기만 (아래 줄에 설명·메모)


## X: 마지막 재료를 뺌 (진하게 → 둘째 → 첫째), 다 비었으면 닫기
func _back() -> void:
	if strong:
		strong = false
	elif not sel.is_empty():
		sel.pop_back()
	else:
		close()
		return
	Sfx.play_pitch(&"blip", 1.2, -12.0)


## 달이기 시작 (재료가 모자라면 칸이 흔들림)
func brew() -> bool:
	if sel.size() < 2 or phase != "pick":
		_shake = 1.0
		Sfx.play(&"es_pot_no", -6.0)
		return false
	phase = "brewing"
	phase_t = 0.0
	Sfx.play(&"es_brew_bubble", -2.0)
	return true


func _reveal() -> void:
	result = EPotions.brew(sel[0], sel[1], strong)
	brews += 1
	if is_instance_valid(eska):
		eska.belt.set_slot(target, String(result.id), bool(result.strong))
	phase = "reveal"
	phase_t = 0.0
	var good := EPotions.is_good(String(result.id))
	if bool(result.new_kind) and good:
		Sfx.play(&"es_pot_discover", -2.0)
	elif good:
		Sfx.play(&"es_brew_done", -3.0)
	else:
		Sfx.play_pitch(&"es_brew_done", 0.6, -6.0)


func _back_to_pick() -> void:
	phase = "pick"
	phase_t = 0.0
	sel.clear()
	strong = false
	focus = "ing:0"


func close() -> void:
	if _closing >= 0:
		return
	_closing = UNPAUSE_FRAMES
	Sfx.play_pitch(&"blip", 0.9, -12.0)
	closed.emit()
	_view.visible = false


## 지금 미리 보이는 결과 id ("" = 재료 부족, "?" = 모르는 조합)
func preview() -> String:
	if sel.size() < 2:
		return ""
	if not EPotions.known(sel[0], sel[1]):
		return "?"
	return EPotions.recipe_of(sel[0], sel[1])


## 아래 안내 줄: 초점에 있는 것의 설명
func info_line() -> String:
	var parts := focus.split(":")
	match parts[0]:
		"ing":
			var ing: String = EPotions.ING_ORDER[int(parts[1])]
			return "%s — %s" % [EPotions.ing_name(ing), EPotions.INGREDIENTS[ing]["mean"]]
		"sock":
			if int(parts[1]) == 2:
				return "달이슬을 하나 더: 진한 물약 (한 번에 강하게 · 병 하나 적게)"
			return "넣은 재료 — 누르면 뺀다"
		"slot":
			var s: Dictionary = eska.belt.slot(int(parts[1])) if is_instance_valid(eska) else {}
			var id := String(s.get("id", ""))
			if id == "":
				return "빈 칸 — 여기에 담는다"
			return "%s %s · %s" % [EPotions.SLOT_KEYS[int(parts[1])], _pname(id, bool(s.get("strong", false))), EPotions.desc_of(id, bool(s.get("strong", false)))]
		"brew":
			var pv := preview()
			if pv == "":
				return "재료 두 가지를 넣어야 달일 수 있다"
			if pv == "?":
				return "모르는 조합 — 달여 보면 안다"
			return "%s · %s" % [_pname(pv, strong), EPotions.desc_of(pv, strong)]
		"close":
			return "가마솥을 떠난다"
		"book":
			var bid: String = EPotions.NOTEBOOK_ORDER[int(parts[1])]
			if EPotions.discovered(bid):
				return "%s — %s" % [EPotions.display_name(bid), EPotions.desc(bid)]
			return "마녀의 메모: 「%s」" % EPotions.hint(bid)
	return ""


static func _pname(id: String, strong_: bool) -> String:
	return ("진한 " if strong_ else "") + EPotions.display_name(id)


static func kind_label(id: String) -> String:
	return "마심" if EPotions.kind(id) == "drink" else "던짐"


# ═══════════════════════════════════════════════════════════
# 그림
# ═══════════════════════════════════════════════════════════

class View extends Control:
	var ui: EBrewUI
	var pd := PDraw.new()

	func _draw() -> void:
		var font := get_theme_default_font()
		var u := ui
		var W := EBrewUI.PANEL.x
		var H := EBrewUI.PANEL.y
		var tt := u.t
		# 화면 어둡게 (패널 바깥까지)
		var vs := get_viewport_rect().size / scale.x
		pd.draw_rect(Rect2(-position / scale.x, vs + Vector2(4, 4)), Color(0.02, 0.0, 0.05, 0.55))
		# 패널: 먹빛 양피지 + 보랏빛 테두리 + 모서리 마름모
		pd.draw_rect(Rect2(-2, -2, W + 4, H + 4), Color(0, 0, 0, 0.6))
		pd.rect_grad(Rect2(0, 0, W, H), EBrewUI.PARCH_TOP, EBrewUI.PARCH_BOT)
		pd.draw_rect(Rect2(0, 0, W, H), Color(EBrewUI.VIOLET, 0.75), false, 1.0)
		pd.draw_rect(Rect2(3, 3, W - 6, H - 6), Color(EBrewUI.VIOLET, 0.18), false, 1.0)
		for c: Vector2 in [Vector2(0, 0), Vector2(W, 0), Vector2(0, H), Vector2(W, H)]:
			_diamond(c, 4.0, EBrewUI.MAGENTA)
		pd.rect_hgrad(Rect2(14, 30, (W - 28) * 0.5, 1), Color(EBrewUI.MAGENTA, 0.0), Color(EBrewUI.MAGENTA, 0.7))
		pd.rect_hgrad(Rect2(14 + (W - 28) * 0.5, 30, (W - 28) * 0.5, 1), Color(EBrewUI.MAGENTA, 0.7), Color(EBrewUI.MAGENTA, 0.0))
		pd.draw_rect(Rect2(14, 186, W - 28, 20), Color(0, 0, 0, 0.28))
		# 재료 칸
		for i in 6:
			var id := "ing:%d" % i
			var r: Rect2 = u._items[id]
			var ing: String = EPotions.ING_ORDER[i]
			var foc := u.focus == id and u.phase == "pick"
			_tile(r, foc, u.sel.has(ing))
			EPotionFx.draw_ingredient(pd, r.position + Vector2(r.size.x * 0.5, 24), ing, 1.45)
		# 가마솥 칸 (재료 둘 + 달이슬) 과 작은 가마솥
		_paint_pot(u, tt)
		var shake := sin(tt * 60.0) * 3.0 * u._shake
		for k in 3:
			var id := "sock:%d" % k
			var r: Rect2 = u._items[id]
			r.position.x += shake
			var c := r.get_center()
			var foc := u.focus == id and u.phase == "pick"
			var filled := (k < 2 and k < u.sel.size()) or (k == 2 and u.strong)
			pd.draw_circle(c, 16.5, Color(0, 0, 0, 0.6))
			pd.draw_circle(c, 15.0, EBrewUI.TILE if k < 2 else Color("#1d1430"))
			var ring := EBrewUI.MAGENTA if foc else (EBrewUI.VIOLET if filled else EBrewUI.TILE_EDGE)
			if k == 2 and not filled:
				for q in 12: # 점선: 넣지 않아도 되는 칸
					var a0 := float(q) / 12.0 * TAU
					pd.draw_arc(c, 15.0, a0, a0 + 0.3, 3, Color(ring, 0.8), 1.0)
			else:
				pd.draw_arc(c, 15.0, 0.0, TAU, 28, ring, 1.6 if foc else 1.0)
			if foc:
				pd.glow(c, 22.0, Color(EBrewUI.MAGENTA, 0.12 + 0.06 * sin(tt * 5.0)), 0.0)
			if k < 2 and k < u.sel.size():
				EPotionFx.draw_ingredient(pd, c, u.sel[k], 1.2)
			elif k == 2:
				EPotionFx.draw_ingredient(pd, c, EPotions.STRONG_ING, 1.0, 1.0 if u.strong else 0.28)
		for k in 2:
			var px := 266.0 + 52.0 * float(k) + shake
			pd.draw_rect(Rect2(px - 3, 69.5, 6, 1.4), Color(EBrewUI.VIOLET, 0.7))
			if k == 0:
				pd.draw_rect(Rect2(px - 0.7, 67, 1.4, 6), Color(EBrewUI.VIOLET, 0.7))
			else:
				pd.draw_rect(Rect2(px - 0.7, 67, 1.4, 6), Color(EBrewUI.VIOLET, 0.35))
		# 달이기 버튼
		var br: Rect2 = u._items["brew"]
		var ready := u.sel.size() == 2
		var bfoc := u.focus == "brew" and u.phase == "pick"
		pd.draw_rect(br.grow(1.0), Color(0, 0, 0, 0.6))
		pd.rect_grad(br, Color("#4a1f78") if ready else Color("#241a30"), Color("#2a0f48") if ready else Color("#17101f"))
		pd.draw_rect(br, EBrewUI.MAGENTA if bfoc else Color(EBrewUI.VIOLET, 0.8 if ready else 0.3), false, 1.6 if bfoc else 1.0)
		if bfoc:
			pd.glow(br.get_center(), 60.0, Color(EBrewUI.MAGENTA, 0.1 + 0.05 * sin(tt * 5.0)), 0.0)
		# 허리띠 칸
		for i in 3:
			var id := "slot:%d" % i
			var r: Rect2 = u._items[id]
			var foc := u.focus == id and u.phase == "pick"
			var chosen := u.target == i
			_tile(r, foc, chosen)
			var s: Dictionary = u.eska.belt.slot(i) if is_instance_valid(u.eska) else {}
			var pid := String(s.get("id", ""))
			EPotionFx.draw_bottle(pd, r.position + Vector2(40, 18), pid, 1.35, float(s.get("left", 0)) / maxf(float(s.get("max", 1)), 1.0) * 0.85, 1.0, 0.0, bool(s.get("strong", false)))
			if chosen:
				pd.draw_colored_polygon(PackedVector2Array([r.position + Vector2(-6, 12), r.position + Vector2(-1, 17), r.position + Vector2(-6, 22)]), EBrewUI.MAGENTA)
		# 닫기 ✕
		var cr: Rect2 = u._items["close"]
		var cfoc := u.focus == "close" and u.phase == "pick"
		pd.draw_rect(cr, Color(0, 0, 0, 0.35))
		pd.draw_rect(cr, EBrewUI.MAGENTA if cfoc else Color(EBrewUI.VIOLET, 0.4), false, 1.0)
		var cc := cr.get_center()
		pd.draw_line(cc + Vector2(-5, -5), cc + Vector2(5, 5), EBrewUI.PALE, 1.4)
		pd.draw_line(cc + Vector2(5, -5), cc + Vector2(-5, 5), EBrewUI.PALE, 1.4)
		# 마녀 수첩
		_paint_book_shapes(u)
		pd.flush(self)
		# ─── 글씨 ───
		_text(font, Vector2(16, 22), "마녀의 가마솥", 14, EBrewUI.PALE)
		var sub := "재료 둘을 넣고 담을 칸을 골라 달인다"
		_text(font, Vector2(W - 40 - _w(font, sub, 10), 21), sub, 10, EBrewUI.DIM)
		_text(font, Vector2(16, 47), "재료", 10, EBrewUI.VIOLET)
		_text(font, Vector2(224, 47), "가마솥", 10, EBrewUI.VIOLET)
		_text(font, Vector2(330, 47), "진하게", 9, Color(EBrewUI.GOLD, 0.8 if u.strong else 0.45))
		_text(font, Vector2(392, 47), "담을 칸", 10, EBrewUI.VIOLET)
		for i in 6:
			var r: Rect2 = u._items["ing:%d" % i]
			var nm := EPotions.ing_name(EPotions.ING_ORDER[i], true)
			_text(font, Vector2(r.get_center().x - _w(font, nm, 10) * 0.5, r.end.y - 6), nm, 10, Color(1, 1, 1, 0.85))
		var pv := u.preview()
		var pname := "재료를 넣으세요" if pv == "" else ("???" if pv == "?" else EBrewUI._pname(pv, u.strong))
		var pcol := EBrewUI.DIM if pv == "" or pv == "?" else EPotions.color(pv).lightened(0.25)
		_text(font, Vector2(292 - _w(font, pname, 12) * 0.5, 150), pname, 12, pcol)
		var bl := "달이기"
		_text(font, Vector2(br.get_center().x - _w(font, bl, 13) * 0.5, br.end.y - 8), bl, 13, Color(1, 1, 1, 0.95 if ready else 0.4))
		for i in 3:
			var r: Rect2 = u._items["slot:%d" % i]
			var s: Dictionary = u.eska.belt.slot(i) if is_instance_valid(u.eska) else {}
			var pid := String(s.get("id", ""))
			_text(font, r.position + Vector2(7, 21), EPotions.SLOT_KEYS[i], 11, EBrewUI.VIOLET)
			var nm := EBrewUI._pname(pid, bool(s.get("strong", false))) if pid != "" else "비어 있음"
			_text(font, r.position + Vector2(54, 15), nm, 11, Color(1, 1, 1, 0.9) if pid != "" else EBrewUI.DIM)
			if pid != "":
				_text(font, r.position + Vector2(54, 28), "%s · %d병" % [EBrewUI.kind_label(pid), int(s.get("max", 0))], 9, EBrewUI.DIM)
		_text(font, Vector2(20, 200), u.info_line(), 11, Color(EBrewUI.PALE, 0.9))
		_paint_book_text(u, font)
		var touch_on := _touch_on()
		var hint := "눌러서 고르기 · 가마솥 칸을 누르면 뺀다" if touch_on else "←→↑↓ 고르기 · Z 넣기/정하기 · X 빼기 · Esc 닫기"
		_text(font, Vector2(W * 0.5 - _w(font, hint, 9) * 0.5, H - 6), hint, 9, EBrewUI.DIM)
		# 결과 공개
		if u.phase == "reveal":
			_paint_reveal(u, font)

	func _touch_on() -> bool:
		var sc := get_tree().current_scene
		var tc: Variant = sc.get("touch") if sc else null
		return tc != null and is_instance_valid(tc) and bool(tc.get("active"))

	## 작은 가마솥: 재료를 넣으면 물빛이 바뀌고, 달이는 동안 크게 끓는다
	func _paint_pot(u: EBrewUI, tt: float) -> void:
		var c := Vector2(292, 108)
		var pv := u.preview()
		var brew_c := Color("#3b1d5c")
		if pv == "?":
			brew_c = Color("#7a2fd0")
		elif pv != "":
			brew_c = EPotions.color(pv).darkened(0.15)
		var boil := 1.0
		if u.phase == "brewing":
			boil = 2.6
			var f := u.phase_t / EBrewUI.BREW_TIME
			brew_c = Color("#7a2fd0").lerp(Color("#e352ff"), 0.5 + 0.5 * sin(tt * 18.0)) if f < 0.85 else Color.WHITE
		# 몸통
		var body := PackedVector2Array()
		for i in 20:
			var an := float(i) / 19.0 * PI
			body.append(c + Vector2(cos(an) * 44.0, sin(an) * 26.0))
		pd.convex(body, Color("#241f2c"))
		pd.draw_set_transform(c, 0.0, Vector2(1.0, 26.0 / 44.0))
		pd.draw_arc(Vector2.ZERO, 39.0, PI * 0.55, PI * 0.85, 8, Color("#4a4058", 0.8), 2.0) # 쇠빛
		pd.draw_set_transform(Vector2.ZERO)
		# 아가리 + 물약
		pd.draw_set_transform(c, 0.0, Vector2(1.0, 0.22))
		pd.draw_circle(Vector2.ZERO, 46.0, Color("#0a090e"))
		pd.draw_circle(Vector2.ZERO, 43.0, Color("#4a4058"))
		pd.draw_circle(Vector2.ZERO, 38.0, brew_c)
		pd.glow(Vector2.ZERO, 36.0, Color(brew_c.lightened(0.4), 0.6), 0.0)
		pd.draw_set_transform(Vector2.ZERO)
		for i in 5:
			var ph := fmod(tt * 0.9 * boil + float(i) * 0.27, 1.0)
			var bx := c.x + sin(float(i) * 2.1) * 26.0
			var by := c.y - 1.0 - ph * 6.0 * boil
			pd.draw_circle(Vector2(bx, by), 1.0 + 2.0 * ph, Color(brew_c.lightened(0.5), 0.9 * (1.0 - ph)))
		if u.phase == "brewing":
			for i in 6: # 김
				var ph := fmod(tt * 1.4 + float(i) * 0.19, 1.0)
				pd.draw_circle(c + Vector2(sin(float(i) * 3.3 + tt) * 20.0, -6.0 - ph * 40.0), 4.0 + ph * 6.0, Color(EBrewUI.PALE, 0.18 * (1.0 - ph)))
			# 넣은 재료가 소용돌이치며 가라앉음
			var f2 := clampf(u.phase_t / (EBrewUI.BREW_TIME * 0.6), 0.0, 1.0)
			for k in u.sel.size():
				var an := tt * 7.0 + float(k) * PI
				var p := c + Vector2(cos(an) * 22.0 * (1.0 - f2), -26.0 * (1.0 - f2) + sin(an) * 4.0)
				EPotionFx.draw_ingredient(pd, p, u.sel[k], 1.0 * (1.0 - f2 * 0.7), 1.0 - f2)

	func _paint_book_shapes(u: EBrewUI) -> void:
		var n := EPotions.NOTEBOOK_ORDER.size()
		for i in n:
			var bid: String = EPotions.NOTEBOOK_ORDER[i]
			var r := EBrewUI.book_rect(i)
			var x := r.position.x
			var found := EPotions.discovered(bid)
			var foc := u.focus == "book:%d" % i and u.phase == "pick"
			pd.draw_rect(r, Color(0, 0, 0, 0.25))
			pd.draw_rect(r, EBrewUI.MAGENTA if foc else Color(EBrewUI.VIOLET, 0.22 if found else 0.1), false, 1.6 if foc else 1.0)
			var shown := bid if EPotions.kind(bid) != "" else bid
			if found:
				pd.glow(Vector2(x + 22, 246), 16.0, Color(EPotions.color(bid), 0.18), 0.0)
				EPotionFx.draw_bottle(pd, Vector2(x + 22, 246), shown, 1.5, 0.8)
				var rec: Array = EPotions.known_recipes(bid)
				if rec.size() == 1 or EPotions.is_good(bid):
					var pr: Array = rec[0]
					EPotionFx.draw_ingredient(pd, Vector2(x + 12, 290), String(pr[0]), 0.62)
					EPotionFx.draw_ingredient(pd, Vector2(x + 32, 290), String(pr[1]), 0.62)
			else:
				EPotionFx.draw_bottle(pd, Vector2(x + 22, 246), "", 1.5, 0.0, 0.35)
				_quill(Vector2(x + 22, 292), Color(EBrewUI.PALE, 0.35)) # 메모가 적힌 칸

	func _paint_book_text(u: EBrewUI, font: Font) -> void:
		var n := EPotions.NOTEBOOK_ORDER.size()
		var found_n := 0
		for i in n:
			var bid: String = EPotions.NOTEBOOK_ORDER[i]
			var x := 16.0 + 48.0 * float(i)
			if EPotions.discovered(bid):
				found_n += 1
				var nm := EPotions.display_name(bid)
				_text(font, Vector2(x + 22 - _w(font, nm, 10) * 0.5, 276), nm, 10, EPotions.color(bid).lightened(0.3))
				var rec: Array = EPotions.known_recipes(bid)
				if rec.size() > 1 and not EPotions.is_good(bid):
					var cnt := "조합 %d" % rec.size()
					_text(font, Vector2(x + 22 - _w(font, cnt, 9) * 0.5, 294), cnt, 9, EBrewUI.DIM)
			else:
				_text(font, Vector2(x + 22 - _w(font, "메모", 9) * 0.5, 276), "메모", 9, EBrewUI.DIM)
		_text(font, Vector2(16, 222), "마녀 수첩", 10, EBrewUI.VIOLET)
		var cnt2 := "%d / %d" % [found_n, n]
		var cx := 16 + _w(font, "마녀 수첩", 10) + 8
		_text(font, Vector2(cx, 222), cnt2, 10, EBrewUI.DIM)
		# 아직 모르는 물약의 메모 하나 (MEMO_CYCLE초마다 바뀜)
		var unknown: Array[String] = []
		for bid: String in EPotions.NOTEBOOK_ORDER:
			if not EPotions.discovered(bid):
				unknown.append(bid)
		if not unknown.is_empty():
			var memo := "「%s」" % EPotions.hint(unknown[int(u.t / EBrewUI.MEMO_CYCLE) % unknown.size()])
			_text(font, Vector2(cx + _w(font, cnt2, 10) + 14, 222), memo, 9, Color(EBrewUI.GOLD, 0.6))

	## 결과 공개: 패널을 덮고 큰 병이 차오름 + 이름 · 설명 · 담은 칸. 처음 만든 물약이면 "새 물약!"
	func _paint_reveal(u: EBrewUI, font: Font) -> void:
		var W := EBrewUI.PANEL.x
		var H := EBrewUI.PANEL.y
		var id := String(u.result.get("id", "murky"))
		var st := bool(u.result.get("strong", false))
		var good := EPotions.is_good(id)
		var fresh := bool(u.result.get("new_kind", false))
		var f := clampf(u.phase_t / 0.45, 0.0, 1.0)
		var e := 1.0 - pow(1.0 - f, 3.0)
		var c := EPotions.color(id)
		var cen := Vector2(W * 0.5, 112)
		pd.draw_rect(Rect2(1, 1, W - 2, H - 2), Color(EBrewUI.PARCH_BOT, clampf(u.phase_t / 0.12, 0.0, 1.0)))
		if good:
			for i in 12: # 빛살
				var an := float(i) / 12.0 * TAU + u.t * 0.4
				var d := Vector2.from_angle(an)
				pd.draw_colored_polygon(PackedVector2Array([cen + d * 14.0, cen + d.rotated(0.09) * 90.0 * e, cen + d.rotated(-0.09) * 90.0 * e]), Color(c, 0.12 * e))
		pd.glow(cen, 60.0 * e, Color(c, 0.35 * e), 0.0)
		EPotionFx.draw_bottle(pd, cen, id, 4.2 * (0.7 + 0.3 * e), 0.9 * clampf((u.phase_t - 0.1) / 0.4, 0.0, 1.0), e, sin(u.t * 2.0) * 0.06, st)
		if fresh and good:
			var sp := clampf(u.phase_t / 0.3, 0.0, 1.0)
			for i in 10:
				var an := float(i) / 10.0 * TAU + u.t
				var p := cen + Vector2.from_angle(an) * (40.0 + 12.0 * sin(u.t * 3.0 + i)) * sp
				_diamond(p, 2.2 + sin(u.t * 6.0 + i), Color(EBrewUI.GOLD, sp))
		pd.flush(self)
		var a := e
		if fresh:
			var banner := "새 물약!" if good else "수첩에 적었다"
			var fs := 20 if good else 13
			var bc := EBrewUI.GOLD if good else EBrewUI.DIM
			var sc := 1.0 + 0.3 * (1.0 - clampf(u.phase_t / 0.25, 0.0, 1.0))
			draw_set_transform(Vector2(W * 0.5, 40), 0.0, Vector2(sc, sc))
			_text(font, Vector2(-_w(font, banner, fs) * 0.5, 0), banner, fs, Color(bc, a))
			draw_set_transform(Vector2.ZERO)
		var nm := EBrewUI._pname(id, st)
		_text(font, Vector2(W * 0.5 - _w(font, nm, 22) * 0.5, 196), nm, 22, Color(c.lightened(0.3), a))
		var line2 := "%s · %d병 · %s 칸에 담았다" % [EBrewUI.kind_label(id), EPotions.doses_of(id, st), EPotions.SLOT_KEYS[u.target]]
		_text(font, Vector2(W * 0.5 - _w(font, line2, 11) * 0.5, 216), line2, 11, Color(EBrewUI.VIOLET, a))
		var d := EPotions.desc_of(id, st)
		_text(font, Vector2(W * 0.5 - _w(font, d, 12) * 0.5, 238), d, 12, Color(EBrewUI.PALE, a))
		var rk := "%s + %s%s" % [EPotions.ing_name(u.sel[0]), EPotions.ing_name(u.sel[1]), " + 달이슬" if st else ""] if u.sel.size() == 2 else ""
		_text(font, Vector2(W * 0.5 - _w(font, rk, 10) * 0.5, 258), rk, 10, Color(EBrewUI.DIM, a))
		if u.phase_t >= EBrewUI.REVEAL_MIN:
			var go := "눌러서 계속" if _touch_on() else "Z 계속"
			_text(font, Vector2(W * 0.5 - _w(font, go, 10) * 0.5, H - 14), go, 10, Color(EBrewUI.PALE, 0.5 + 0.3 * sin(u.t * 4.0)))

	func _tile(r: Rect2, foc: bool, chosen: bool) -> void:
		pd.draw_rect(r.grow(1.0), Color(0, 0, 0, 0.5))
		pd.rect_grad(r, Color("#22172c") if not foc else Color("#2e1a40"), EBrewUI.TILE)
		var edge := EBrewUI.MAGENTA if foc else (Color(EBrewUI.VIOLET, 0.85) if chosen else EBrewUI.TILE_EDGE)
		pd.draw_rect(r, edge, false, 1.6 if foc else 1.0)
		if foc:
			pd.glow(r.get_center(), r.size.x * 0.75, Color(EBrewUI.MAGENTA, 0.08 + 0.04 * sin(ui.t * 5.0)), 0.0)
		if chosen:
			_diamond(r.position + Vector2(r.size.x - 6, 6), 2.4, EBrewUI.MAGENTA)

	## 작은 깃펜 (수첩에 메모가 적힌 칸)
	func _quill(p: Vector2, c: Color) -> void:
		pd.draw_line(p + Vector2(-6, 4), p + Vector2(5, -5), c, 1.0)
		pd.convex(PackedVector2Array([p + Vector2(5, -5), p + Vector2(1, -4), p + Vector2(-2, 0), p + Vector2(2, -1)]), c)
		pd.draw_line(p + Vector2(-8, 5), p + Vector2(-3, 5), c, 0.8)

	func _diamond(p: Vector2, r: float, c: Color) -> void:
		pd.convex(PackedVector2Array([p + Vector2(0, -r * 1.25), p + Vector2(r, 0), p + Vector2(0, r * 1.25), p + Vector2(-r, 0)]), c)

	func _w(font: Font, s: String, fs: int) -> float:
		return font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x

	func _text(font: Font, p: Vector2, s: String, fs: int, col: Color) -> void:
		draw_string_outline(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color(0, 0, 0, 0.7 * col.a))
		draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
