class_name ETutHud
extends Control
## 튜토리얼 화면 연출 (가장 위 층):
## - 검은 화면 밝아짐/어두워짐(fade_to) · 위아래 영화 띠(bars_to) · 장 이름(chapter)
## - 혼잣말 자막(say): 화면 위 가운데, 한 글자씩
## - 안내 칸(prompt): 화면 아래 가운데, 키 모양 그림 + 짧은 설명. done()이면 체크가 그려지며 접힘, nudge()면 흔들리며 다시 눈길을 끎
##   터치 중이면 키 그림 대신 실제 화면 버튼 둘레에 맥박 치는 고리 (ETouch.spot)
## 값이 바뀌는 동안만 다시 그린다.

const PALE := EVfx.PALE
const VIOLET := EVfx.VIOLET
const MAGENTA := EVfx.MAGENTA
const INK := EVfx.INK
const EDGE := EVfx.EDGE
const KEY_LABEL := {"es_left": "←", "es_right": "→", "es_up": "↑", "es_down": "↓", "es_jump": "Z", "es_attack": "X",
	"es_blink": "C", "es_skill": "A", "es_bind": "S", "es_ult": "D"}
const SAY_CPS := 28.0 ## 자막 글자/초
const SAY_HOLD := 2.6

var touch: ETouch

var _black := 1.0
var _black_to := 1.0
var _black_v := 1.0
var _bars := 0.0
var _bars_to := 0.0
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


func chapter(title: String, sub := "") -> void:
	queue_redraw()
	_chap = title
	_chap_sub = sub
	_chap_t = 0.0


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


func done() -> void:
	if _ptext == "" or _p_done >= 0.0:
		return
	_p_done = 0.0
	Sfx.play_pitch(&"pickup", 1.2, -6.0)


func nudge() -> void:
	if _ptext != "" and _p_done < 0.0:
		_nudge = 1.0


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
	return _black > 0.0 or _bars > 0.0 or _chap_t < CHAP_LIFE or is_saying() or _ptext != ""


func _draw() -> void:
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
	var n := mini(int(_say_t * SAY_CPS), _say.length())
	var shown := _say.substr(0, n)
	var life := float(_say.length()) / SAY_CPS + SAY_HOLD
	var a := clampf((life - _say_t) / 0.5, 0.0, 1.0)
	var fs := 13
	var full_w := _font.get_string_size(_say, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var p := Vector2(size.x * 0.5 - full_w * 0.5, 44.0 + 34.0 * _bars)
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
	# 너비 재기
	var parts: Array = [] ## [종류, 글, 너비] — 종류 0 = 키, 1 = 글자
	var w := 0.0
	if not touching:
		for k: String in _keys:
			if KEY_LABEL.has(k):
				var kw := maxf(_font.get_string_size(KEY_LABEL[k], HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 10.0, 18.0)
				parts.append([0, KEY_LABEL[k], kw])
				w += kw + 3.0
			else:
				var lw := _font.get_string_size(k, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 4.0 # 글자 양옆 여백
				parts.append([1, k, lw])
				w += lw + 3.0
		w += 6.0
	var tw := _font.get_string_size(_ptext, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
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
	_text(Vector2(cx, y + 1), _ptext, fs, Color(PALE.lerp(Color.WHITE, 0.3), a))
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
