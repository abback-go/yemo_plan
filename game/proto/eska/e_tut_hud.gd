class_name ETutHud
extends Control
## 튜토리얼 화면 연출 (가장 위 층):
## - 검은 화면 밝아짐/어두워짐(fade_to) · 위아래 영화 띠(bars_to) · 장 이름(chapter)
## - 집중(focus_to): 시간이 느려진 동안 화면 가장자리가 먹빛으로 어두워지고 안쪽에 마젠타 테 (틈 달이기 순간)
## - 혼잣말 자막(say): 화면 위 가운데, 한 글자씩
## - 안내 칸(prompt): 화면 아래 가운데, 키 모양 그림 + 짧은 설명. done()이면 체크가 그려지며 접힘, nudge()면 흔들리며 다시 눈길을 끎
##   키 그림의 글은 입력 방식에 맞춰 바뀐다(EKeys.label — 키보드 "A" / 터치 "스킬"). 터치 중이면 실제 화면 버튼 둘레에도 맥박 치는 고리 (ETouch.spot)
## - 글 속의 {es_skill} 같은 자리표는 그릴 때마다 지금 입력 방식의 이름으로 바뀐다 (fmt)
## - 달이기 화면 위 아래 띠(BrewTip): 가마솥 화면이 열려 게임이 멈춘 동안에도 다음 할 일을 한 줄로
## 값이 바뀌는 동안만 다시 그린다.

const PALE := EVfx.PALE
const VIOLET := EVfx.VIOLET
const MAGENTA := EVfx.MAGENTA
const INK := EVfx.INK
const EDGE := EVfx.EDGE
const SAY_CPS := 28.0 ## 자막 글자/초
const SAY_HOLD := 2.6

var touch: ETouch
var boss_bar := false ## 화면 위 보스 체력바가 떠 있음 — 좁은(세로) 화면에서 자막을 그 아래로
const BOSS_BAR_DROP := 24.0

var _black := 1.0
var _black_to := 1.0
var _black_v := 1.0
var _bars := 0.0
var _bars_to := 0.0
var _focus := 0.0
var _focus_to := 0.0
const FOCUS_EDGE := 56.0 ## 집중: 가장자리에서 안쪽으로 어두워지는 폭
const FOCUS_V := 3.0 ## 집중이 켜지고 꺼지는 빠르기 (초당)
var _chap := ""
var _chap_sub := ""
var _chap_t := 99.0
const CHAP_LIFE := 3.4
var _say := ""
var _say_t := 99.0
var _keys: Array = []
var _ptext := ""
var _p_in := 0.0 ## 0 → 1 나타남
var _p_done := -1.0 ## 체크 그려진 뒤 시간 (-1 = 아직)
var _nudge := 0.0
var _t := 0.0
var _font: Font
var _cap := StyleBoxFlat.new()
var _panel := StyleBoxFlat.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = get_theme_default_font()
	_cap.bg_color = Color(INK, 0.92)
	_cap.border_color = Color(PALE, 0.9)
	_cap.set_border_width_all(1)
	_cap.border_width_bottom = 3
	_cap.set_corner_radius_all(3)
	_panel.bg_color = Color(INK, 0.72)
	_panel.border_color = Color(MAGENTA, 0.45)
	_panel.set_border_width_all(1)
	_panel.set_corner_radius_all(4)


# ═══════════════════════════════════════════════════════════
# 부르는 쪽
# ═══════════════════════════════════════════════════════════

func fade_to(a: float, sec: float) -> void:
	_black_to = a
	_black_v = absf(a - _black) / maxf(sec, 0.01)


func bars_to(a: float) -> void:
	_bars_to = a


## 집중 연출 켜기/끄기 (1 = 켬)
func focus_to(a: float) -> void:
	_focus_to = a


func chapter(title: String, sub := "") -> void:
	queue_redraw()
	_chap = title
	_chap_sub = sub
	_chap_t = 0.0


## 글 속 자리표 {동작 이름}을 지금 입력 방식의 이름으로 (예: "{es_down}+{es_potion}" → 키보드 "↓+F" / 터치 "↓+물약")
static func fmt(text: String) -> String:
	if not text.contains("{"):
		return text
	for a: String in EKeys.LABELS:
		text = text.replace("{%s}" % a, EKeys.label(a))
	return text


func say(text: String) -> void:
	_say = text
	_say_t = 0.0


func is_saying() -> bool:
	return _say_t < float(_say.length()) / SAY_CPS + SAY_HOLD


## 안내 칸: keys = ["es_left", "es_right"] 처럼 동작 이름(키 그림) 또는 "+" 같은 글자, text = 짧은 설명
func prompt(keys: Array, text: String) -> void:
	_keys = keys
	_ptext = text
	_p_in = 0.0
	_p_done = -1.0
	Sfx.play_pitch(&"blip", 1.3, -10.0)


## 떠 있는 안내 칸의 설명만 바꾼다 (다시 나타나는 연출 없이 — 게이지 % 같은 살아 있는 숫자)
func set_text(text: String) -> void:
	if _ptext != "" and _p_done < 0.0:
		_ptext = text


func done() -> void:
	if _ptext == "" or _p_done >= 0.0:
		return
	_p_done = 0.0
	Sfx.play_pitch(&"pickup", 1.2, -6.0)


func nudge() -> void:
	if _ptext != "" and _p_done < 0.0:
		_nudge = 1.0


## 안내 칸·자막을 바로 지움 (연출이 시작될 때 지난 단계 안내가 남지 않게)
func clear() -> void:
	_ptext = ""
	_keys = []
	_say = ""
	queue_redraw()


func has_prompt() -> bool:
	return _ptext != ""


# ═══════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	var vs := get_viewport_rect().size
	if size != vs:
		size = vs
	var real := delta / maxf(Engine.time_scale, 0.05) # 느려짐 중에도 글은 제 속도로
	_t += real
	_black = move_toward(_black, _black_to, _black_v * real)
	_bars = move_toward(_bars, _bars_to, real * 2.0)
	_focus = move_toward(_focus, _focus_to, real * FOCUS_V)
	_chap_t += real
	_say_t += real
	_nudge = maxf(_nudge - real * 1.6, 0.0)
	var was_busy := _busy()
	if _ptext != "":
		_p_in = minf(_p_in + real * 4.0, 1.0)
		if _p_done >= 0.0:
			_p_done += real
			if _p_done > 1.0:
				_ptext = ""
				_keys = []
	if was_busy or _busy():
		queue_redraw()


## 그릴 것이 있나 (없으면 다시 그리지 않음)
func _busy() -> bool:
	return _black > 0.0 or _bars > 0.0 or _focus > 0.0 or _chap_t < CHAP_LIFE or is_saying() or _ptext != ""


func _draw() -> void:
	_draw_focus()
	_draw_bars()
	_draw_prompt()
	_draw_touch_rings()
	_draw_say()
	_draw_chapter()
	if _black > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.0, 0.02, _black))


func _draw_bars() -> void:
	if _bars <= 0.0:
		return
	var h := 34.0 * (1.0 - pow(1.0 - _bars, 3.0))
	draw_rect(Rect2(0, 0, size.x, h), Color.BLACK)
	draw_rect(Rect2(0, size.y - h, size.x, h), Color.BLACK)


func _draw_focus() -> void:
	if _focus <= 0.0:
		return
	var e := _focus * _focus * (3.0 - 2.0 * _focus)
	var dark := Color(INK, 0.6 * e)
	var clear := Color(INK, 0.0)
	var w := size.x
	var h := size.y
	var d := FOCUS_EDGE
	# 네 가장자리: 바깥은 먹빛, 안쪽으로 투명 (사다리꼴 넷)
	for q: Array in [[Vector2(0, 0), Vector2(w, 0), Vector2(w - d, d), Vector2(d, d)],
			[Vector2(0, h), Vector2(d, h - d), Vector2(w - d, h - d), Vector2(w, h)],
			[Vector2(0, 0), Vector2(d, d), Vector2(d, h - d), Vector2(0, h)],
			[Vector2(w, 0), Vector2(w, h), Vector2(w - d, h - d), Vector2(w - d, d)]]:
		draw_polygon(PackedVector2Array(q), _edge_cols(q, dark, clear))
	var beat := 0.5 + 0.5 * sin(_t * 5.0)
	draw_rect(Rect2(6, 6, w - 12, h - 12), Color(MAGENTA, (0.25 + 0.2 * beat) * e), false, 1.0)


## 사다리꼴 네 점 중 화면 가장자리에 있는 점은 먹빛, 안쪽 점은 투명
func _edge_cols(q: Array, dark: Color, clear: Color) -> PackedColorArray:
	var out := PackedColorArray()
	for p: Vector2 in q:
		var on_edge := p.x <= 0.0 or p.y <= 0.0 or p.x >= size.x or p.y >= size.y
		out.append(dark if on_edge else clear)
	return out


func _draw_chapter() -> void:
	if _chap_t >= CHAP_LIFE:
		return
	var inn := clampf((_chap_t - 0.3) / 0.8, 0.0, 1.0)
	var out := clampf((CHAP_LIFE - _chap_t) / 0.8, 0.0, 1.0)
	var a := minf(inn, out)
	var c := Vector2(size.x * 0.5, size.y * 0.42)
	var fs := 30
	var tw := _font.get_string_size(_chap, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var sc := 1.08 - 0.08 * (1.0 - pow(1.0 - inn, 3.0))
	var lw := (tw * 0.5 + 70.0) * inn
	draw_line(c + Vector2(-lw, 14), c + Vector2(lw, 14), Color(MAGENTA, 0.6 * a), 1.0)
	draw_circle(c + Vector2(0, 14), 2.0, Color(EDGE, a))
	draw_set_transform(c, 0.0, Vector2(sc, sc))
	draw_string_outline(_font, Vector2(-tw * 0.5, 0), _chap, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, Color(INK, 0.85 * a))
	draw_string(_font, Vector2(-tw * 0.5, 0), _chap, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(EDGE, a))
	draw_set_transform(Vector2.ZERO)
	if _chap_sub != "":
		var sw := _font.get_string_size(_chap_sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		_text(c + Vector2(-sw * 0.5, 34), _chap_sub, 12, Color(VIOLET, a))


func _draw_say() -> void:
	if not is_saying() or _say == "":
		return
	var line := fmt(_say)
	var n := mini(int(_say_t * SAY_CPS), line.length())
	var shown := line.substr(0, n)
	var life := float(_say.length()) / SAY_CPS + SAY_HOLD
	var a := clampf((life - _say_t) / 0.5, 0.0, 1.0)
	var fs := 13
	var full_w := _font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var p := Vector2(size.x * 0.5 - full_w * 0.5, 44.0 + 34.0 * _bars + (46.0 + (BOSS_BAR_DROP if boss_bar else 0.0) if size.x < 520.0 else 0.0)) # 좁은(세로) 화면은 왼쪽 위 이름과 겹치지 않게 아래로
	# 글 뒤 옅은 띠
	var band := Rect2(p.x - 26, p.y - 15, full_w + 52, 22)
	draw_rect(band, Color(0, 0, 0, 0.35 * a))
	draw_rect(Rect2(band.position.x, band.position.y, band.size.x, 1), Color(MAGENTA, 0.25 * a))
	_text(p, shown, fs, Color(PALE.lerp(Color.WHITE, 0.4), a))


func _draw_prompt() -> void:
	if _ptext == "":
		return
	var e := 1.0 - pow(1.0 - _p_in, 3.0)
	var fold := 0.0 if _p_done < 0.5 else clampf((_p_done - 0.5) / 0.5, 0.0, 1.0)
	var a := e * (1.0 - fold)
	if a <= 0.0:
		return
	var touching := touch != null and touch.active
	var fs := 13
	var ptext := fmt(_ptext)
	# 너비 재기 (키 그림의 글은 입력 방식에 맞춰 — 터치면 버튼 이름 "스킬"·"물약", 그 버튼에는 고리도)
	var parts: Array = [] ## [종류, 글, 너비] — 종류 0 = 키, 1 = 글자
	var w := 0.0
	for k: String in _keys:
		if EKeys.LABELS.has(k):
			var kl := EKeys.label(k)
			var kw := maxf(_font.get_string_size(kl, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 10.0, 18.0)
			parts.append([0, kl, kw])
			w += kw + 3.0
		else:
			var lw := _font.get_string_size(k, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 4.0 # 글자 양옆 여백
			parts.append([1, k, lw])
			w += lw + 3.0
	if not parts.is_empty():
		w += 6.0
	var tw := _font.get_string_size(ptext, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	w += tw
	var shake := sin(_t * 40.0) * 3.0 * _nudge
	var y := size.y - 34.0 - 34.0 * _bars + 10.0 * (1.0 - e) + 8.0 * fold
	var x := size.x * 0.5 - w * 0.5 + shake
	if touching:
		y = size.y * 0.24 + 34.0 * _bars # 터치: 버튼과 겹치지 않게 위쪽
	var box := Rect2(x - 12, y - 17, w + 24 + (18.0 if _p_done >= 0.0 else 0.0), 26)
	var pb := _panel # 같은 상자를 색만 바꿔 쓴다 (그리는 순간의 색이 기록됨)
	pb.bg_color = Color(INK, 0.72 * a)
	pb.border_color = Color(MAGENTA.lerp(EDGE, _nudge), (0.45 + 0.5 * _nudge) * a)
	if _p_done >= 0.0:
		pb.border_color = Color(EDGE, a * (1.0 - minf(_p_done * 2.0, 0.6)))
	draw_style_box(pb, box)
	var cx := x
	for p: Array in parts:
		if int(p[0]) == 0:
			var r := Rect2(cx, y - 13, float(p[2]), 18)
			var cb := _cap
			cb.bg_color = Color(INK, 0.92 * a)
			cb.border_color = Color(PALE.lerp(EDGE, _nudge), a)
			if _p_done >= 0.0:
				cb.bg_color = Color(MAGENTA, a * maxf(0.0, 1.0 - _p_done * 3.0)).lerp(cb.bg_color, minf(_p_done * 3.0, 1.0))
			draw_style_box(cb, r)
			var lw := _font.get_string_size(String(p[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			draw_string(_font, Vector2(cx + (float(p[2]) - lw) * 0.5, y + 1), String(p[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, a))
		else:
			_text(Vector2(cx + 2.0, y + 1), String(p[1]), 12, Color(VIOLET, a))
		cx += float(p[2]) + 3.0
	if not parts.is_empty():
		cx += 6.0
	_text(Vector2(cx, y + 1), ptext, fs, Color(PALE.lerp(Color.WHITE, 0.3), a))
	if _p_done >= 0.0:
		# 체크 표시가 그어짐
		var k := clampf(_p_done / 0.25, 0.0, 1.0)
		var c0 := Vector2(cx + tw + 8, y - 4)
		var c1 := c0 + Vector2(4, 4)
		var c2 := c1 + Vector2(8, -10)
		var m := Color(MAGENTA.lerp(EDGE, 0.5), a)
		draw_line(c0, c0.lerp(c1, minf(k * 2.0, 1.0)), m, 2.0)
		if k > 0.5:
			draw_line(c1, c1.lerp(c2, (k - 0.5) * 2.0), m, 2.0)


## 터치: 안내 칸의 동작에 해당하는 실제 화면 버튼 둘레에 맥박 고리 + 버튼 이름
func _draw_touch_rings() -> void:
	if _ptext == "" or _p_done >= 0.0 or touch == null or not touch.active:
		return
	var a := _p_in
	var beat := 0.5 + 0.5 * sin(_t * 6.0)
	for k: String in _keys:
		var sp := touch.spot(k)
		if sp.is_empty():
			continue
		var c: Vector2 = sp[0]
		var r: float = sp[1]
		draw_arc(c, r + 4.0 + 3.0 * beat, 0.0, TAU, 32, Color(MAGENTA, (0.5 + 0.4 * beat) * a), 2.0)
		draw_arc(c, r + 9.0 + 6.0 * beat, 0.0, TAU, 32, Color(EDGE, 0.25 * (1.0 - beat) * a), 1.0)


func _text(p: Vector2, s: String, fs: int, col: Color) -> void:
	draw_string_outline(_font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color(0, 0, 0, 0.7 * col.a))
	draw_string(_font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


## 달이기 화면 아래 띠: 가마솥 화면이 열려 게임이 멈춘 동안 다음 할 일을 한 줄로 알려 준다 (CanvasLayer 46 — 달이기 화면 45 위, 멈춤 중에도 돈다).
## 화면이 처음 열리면 담을 칸을 ↓칸으로, 초점을 거미줄로 맞춰 둔다 (튜토리얼은 속박 하나만 가르친다 — 다른 칸·재료도 자유롭게 고를 수 있음).
class BrewTip extends Control:
	const WANT_ING := "web"
	const WANT_SLOT := 2
	const BAND_H := 18.0
	const FS := 12
	var cauldron: ECauldron
	var want := "bind"
	var opened := 0 ## 달이기 화면이 열린 횟수 (장면은 멈춰 있어 못 보므로 여기서 센다)
	var _ui: EBrewUI
	var _line := ""
	var _font: Font

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_font = get_theme_default_font()

	func _process(_delta: float) -> void:
		var vs := get_viewport_rect().size
		if size != vs:
			size = vs
		var ui: EBrewUI = cauldron.ui if is_instance_valid(cauldron) else null
		if ui != _ui:
			_ui = ui
			if ui != null:
				opened += 1
				ui.target = WANT_SLOT
				ui.focus = "ing:%d" % EPotions.ING_ORDER.find(WANT_ING)
		var line := ETutHud.fmt(_text_for(ui)) if ui != null and ui.is_open() else ""
		if line != _line:
			_line = line
			queue_redraw()

	## 지금 달이기 화면 상태에 맞는 할 일 한 줄 (키 이름은 달이기 화면 아래 줄이 이미 보여 주므로 여기선 할 일만 — 두 줄 중복 없게)
	func _text_for(ui: EBrewUI) -> String:
		if ui.phase != "pick": # 달이는 중·결과 화면은 달이기 화면이 스스로 안내
			return ""
		var slot: Dictionary = ui.eska.belt.slot(WANT_SLOT) if is_instance_valid(ui.eska) else {}
		if String(slot.get("id", "")) == want:
			return "할 일 ③ 다 됐다 — 닫고 나간다"
		var only_web := ui.sel.all(func(i: String) -> bool: return i == WANT_ING)
		if not only_web:
			return "거미줄 둘이어야 한다 — 빼고 다시"
		if ui.sel.size() < 2:
			return "할 일 ① 거미줄을 두 번 넣는다"
		if ui.target != WANT_SLOT:
			return "할 일 ② 오른쪽 ↓칸을 골라 담는다"
		return "할 일 ② 달이기 — ↓칸에 담긴다"

	func _draw() -> void:
		if _line == "":
			return
		var tw := _font.get_string_size(_line, HORIZONTAL_ALIGNMENT_LEFT, -1, FS).x
		var band := Rect2(0, size.y - BAND_H, size.x, BAND_H)
		draw_rect(band, Color(INK, 0.9))
		draw_rect(Rect2(band.position, Vector2(size.x, 1)), Color(MAGENTA, 0.5))
		var p := Vector2(size.x * 0.5 - tw * 0.5, size.y - 5.0)
		draw_circle(p + Vector2(-9, -4), 2.5, EDGE)
		draw_string_outline(_font, p, _line, HORIZONTAL_ALIGNMENT_LEFT, -1, FS, 3, Color(0, 0, 0, 0.7))
		draw_string(_font, p, _line, HORIZONTAL_ALIGNMENT_LEFT, -1, FS, PALE.lerp(Color.WHITE, 0.3))
