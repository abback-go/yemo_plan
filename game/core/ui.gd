## ui.gd — 화면 부품을 만드는 작은 도구 모음 (글자·상자·그라데이션·안내 강조 표시).
## 노드는 모두 코드로 만든다(장면 파일 없이). 글자 상자는 기본으로 마우스를 통과시킨다.
class_name UI
extends Object

const RED := Color("#b3121f")
const GOLD := Color("#c9a24a")
const KEY := Color("#ffcf6a")      # 안내 상자의 강조(**…**)
const CARDNAME := Color("#ff9aa4") # 안내 상자의 카드 이름·키워드(「…」)


static func label(text: String, size: int, color := Color.WHITE, font := "sans", align := HORIZONTAL_ALIGNMENT_LEFT, outline := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", Assets.font(font))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	return l


## BBCode 글 상자 (크기 고정, 자동 줄바꿈)
static func rich(size: int, color := Color.WHITE, font := "sans", bold_font := "sans_bold") -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.add_theme_font_override("normal_font", Assets.font(font))
	r.add_theme_font_override("bold_font", Assets.font(bold_font))
	r.add_theme_font_override("italics_font", Assets.font(font))
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_font_size_override("italics_font_size", size)
	r.add_theme_color_override("default_color", color)
	return r


static func esc(s: String) -> String:
	return s.replace("[", "[lb]")


## 안내 상자 글 → BBCode: **강조** 는 금색 굵게, 「카드 이름·키워드」 는 붉은 분홍으로
static func markup(text: String) -> String:
	var s := esc(text)
	var out := ""
	var bold := false
	var i := 0
	while i < s.length():
		if s.substr(i, 2) == "**":
			out += ("[/color][/b]" if bold else "[b][color=#%s]" % KEY.to_html(false))
			bold = not bold
			i += 2
			continue
		var ch := s[i]
		if ch == "「":
			out += "[color=#%s]「" % CARDNAME.to_html(false)
		elif ch == "」":
			out += "」[/color]"
		else:
			out += ch
		i += 1
	if bold:
		out += "[/color][/b]"
	return out


static func box(bg: Color, border := Color.TRANSPARENT, radius := 10, bw := 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw if border.a > 0 else 0)
	s.set_corner_radius_all(radius)
	s.anti_aliasing = true
	return s


static func panel(style: StyleBox) -> Panel:
	var p := Panel.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", style)
	return p


## 그라데이션 그림. stops: [[0, Color], [1, Color]] / dir: "v"(위→아래) | "h" | "radial"
static func grad(stops: Array, dir := "v", w := 64, h := 64, center := Vector2(0.5, 0.5), radius := 0.5) -> GradientTexture2D:
	var g := Gradient.new()
	var offs := PackedFloat32Array()
	var cols := PackedColorArray()
	for s in stops:
		offs.append(float(s[0]))
		cols.append(s[1] if s[1] is Color else Color(s[1]))
	g.offsets = offs
	g.colors = cols
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = w
	t.height = h
	if dir == "v":
		t.fill_from = Vector2(0, 0)
		t.fill_to = Vector2(0, 1)
	elif dir == "h":
		t.fill_from = Vector2(0, 0)
		t.fill_to = Vector2(1, 0)
	else:
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = center
		t.fill_to = center + Vector2(radius, 0)
	return t


static func tex_rect(t: Texture2D, r: Rect2) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = t
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.position = r.position
	tr.size = r.size
	return tr


## 그림을 상자에 꽉 채워(넘치는 쪽은 잘라) 보여 준다 (CSS object-fit: cover)
static func cover_rect(t: Texture2D, r: Rect2) -> TextureRect:
	var tr := tex_rect(t, r)
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.clip_contents = true
	return tr


## 2차 베지어 곡선 점들
static func quad_curve(a: Vector2, c: Vector2, b: Vector2, n := 24) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var t := float(i) / n
		pts.append(a * (1 - t) * (1 - t) + c * 2.0 * (1 - t) * t + b * t * t)
	return pts


## 빛나는 곡선(붉은 실): 넓고 옅은 선 위에 가는 선
static func glow_curve(ci: CanvasItem, a: Vector2, c: Vector2, b: Vector2, width: float, col: Color, glow: float) -> void:
	var pts := quad_curve(a, c, b, 28)
	if glow > 0:
		ci.draw_polyline(pts, Color(1, 0.12, 0.2, col.a * 0.22), width + glow, true)
		ci.draw_polyline(pts, Color(1, 0.12, 0.2, col.a * 0.3), width + glow * 0.45, true)
	ci.draw_polyline(pts, col, width, true)


## 점선 화살표 (드래그·예고 선). lift: 곡선이 위로 휘는 정도(null = 손에서 위로 쏘는 큰 곡선)
static func arrow(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, width: float, dash := Vector2(18, 10), lift = null) -> void:
	var m := Vector2((a.x + b.x) / 2.0, (minf(a.y, b.y) - 80.0) if lift == null else ((a.y + b.y) / 2.0 - float(lift)))
	var pts := quad_curve(a, m, b, 48)
	# 점선
	var acc := 0.0
	var on := true
	var seg := PackedVector2Array([pts[0]])
	for i in range(1, pts.size()):
		var p0 := pts[i - 1]
		var p1 := pts[i]
		var d := p0.distance_to(p1)
		var t := 0.0
		while d - t > 0.001:
			var lim := dash.x if on else dash.y
			var step := minf(lim - acc, d - t)
			t += step
			acc += step
			var p := p0.lerp(p1, t / d)
			if on:
				seg.append(p)
			if acc >= lim - 0.001:
				if on and seg.size() > 1:
					ci.draw_polyline(seg, Color(col.r, col.g, col.b, col.a * 0.25), width * 2.4, true)
					ci.draw_polyline(seg, col, width, true)
				on = not on
				acc = 0.0
				seg = PackedVector2Array([p])
	if on and seg.size() > 1:
		ci.draw_polyline(seg, col, width, true)
	var ang := (b - m).angle()
	var s := width * 3.2
	ci.draw_colored_polygon(PackedVector2Array([b, b - Vector2.from_angle(ang - 0.45) * s, b - Vector2.from_angle(ang + 0.45) * s]), col)


## 버튼 (붉은 테두리 둥근 상자). 누르면 cb 호출. 휴대폰에서도 누르기 쉽게 실제 화면 44px 이상으로 누르는 영역을 넓힌다(Btn 참고)
static func button(text: String, size: int, cb: Callable, font := "serif_bold") -> Btn:
	var b := Btn.new()
	b.setup(text, size, font)
	b.pressed.connect(cb)
	return b
