class_name Prop
extends Node2D
## 장식 소품 (코드 그래픽). 원점은 바닥(발밑) 기준이고, 매달린 것(샹들리에·등롱·사슬)은 천장 기준.
## kind 목록은 _draw()의 match 참고. 공통 키: w, h(타일), flip, front(전경), col(색).

var kind := ""
var w := 1.0
var h := 1.0
var params := {}
var theme := {}
var _t := 0.0
var _animated := false
var _glow: LightGlow


func setup(room: Room, e: Dictionary) -> void:
	kind = String(e.get("kind", ""))
	w = float(e.get("w", 1))
	h = float(e.get("h", 1))
	params = e
	theme = room.theme
	position = room.tile_pos(e) + Vector2(8, 0)
	z_index = 20 if bool(e.get("front", false)) else -3
	if bool(e.get("flip", false)):
		scale.x = -1
	_t = randf() * 6.0
	_animated = kind in ["chandelier", "lantern_red", "candles", "cauldron", "banner", "bead", "fox_statue", "throne", "clock_face", "fountain", "magic_circle", "blackboard", "window"]
	var glow_pos := Vector2.ZERO
	var glow_col := Color(theme.accent)
	var glow_r := 0.0
	match kind:
		"chandelier": glow_pos = Vector2(0, 26); glow_r = 90.0
		"lantern_red": glow_pos = Vector2(0, 22); glow_r = 60.0; glow_col = Color(1.0, 0.5, 0.3)
		"candles": glow_pos = Vector2(0, -16); glow_r = 44.0
		"cauldron": glow_pos = Vector2(0, -20); glow_r = 50.0; glow_col = Color(0.5, 1.0, 0.6)
		"bead": glow_pos = Vector2(0, -40); glow_r = 90.0; glow_col = Color(0.5, 0.8, 1.0)
		"window": glow_pos = Vector2(0, -h * 8.0); glow_r = 70.0 * w / 3.0; glow_col = Color(0.7, 0.75, 1.0)
		"torch": glow_pos = Vector2(0, -26); glow_r = 56.0; glow_col = Color(1.0, 0.6, 0.3)
		"lamp_green": glow_pos = Vector2(0, -20); glow_r = 40.0; glow_col = Color(0.6, 1.0, 0.7)
		"magic_circle": glow_pos = Vector2(0, -4); glow_r = 60.0; glow_col = Color(0.7, 0.55, 1.0)
	if glow_r <= 0.0 and not _animated:
		for s in ChapterRegistry.prop_scripts():
			var inf: Dictionary = s.setup_info(kind, self)
			if inf.is_empty():
				continue
			_animated = bool(inf.get("animated", false))
			glow_r = float(inf.get("glow_r", 0.0))
			glow_pos = inf.get("glow_pos", Vector2.ZERO)
			glow_col = inf.get("glow_col", glow_col)
			break
	if glow_r > 0.0:
		_glow = LightGlow.make(glow_pos, glow_r, glow_col, float(e.get("glow", 0.45)))
		_glow.z_index = 9
		add_child(_glow)


## 장별 소품 그림이 쓰는 시간 (초)
func time() -> float:
	return _t


func _process(delta: float) -> void:
	if _animated:
		_t += delta
		queue_redraw()


func _draw() -> void:
	var T := 16.0
	var dark := Color(theme.near).darkened(0.2)
	var mid := Color(theme.mid).lightened(0.12)
	var acc := Color(theme.accent)
	match kind:
		"window":
			# 스테인드글라스 아치 창 (w×h 타일), 바닥에서 위로
			var ww := w * T
			var hh := h * T
			var arch := PackedVector2Array()
			for i in 11:
				var a := PI + PI * i / 10.0
				arch.append(Vector2(cos(a) * ww * 0.5, -hh + ww * 0.5 + sin(a) * ww * 0.5))
			arch.append(Vector2(ww * 0.5, 0))
			arch.append(Vector2(-ww * 0.5, 0))
			draw_colored_polygon(arch, Color("#141026"))
			var glass := [Color("#4a5ab0"), Color("#b04a6a"), Color("#d8b050"), Color("#4a9a8a"), Color("#7a5ab8")]
			var rows := int(hh / 10.0)
			var cols := maxi(int(ww / 10.0), 2)
			for r in rows:
				for c in cols:
					var px := -ww * 0.5 + 3 + c * (ww - 6) / cols
					var py := -hh + ww * 0.35 + r * 10.0
					if py > -4:
						continue
					var gc: Color = glass[(r * 3 + c * 7) % glass.size()]
					var k := 0.55 + 0.15 * sin(_t * 0.7 + r + c)
					draw_rect(Rect2(px, py, (ww - 6) / cols - 2, 8), Color(gc, k))
			draw_polyline(arch, Color("#2a2440"), 3.0)
			draw_rect(Rect2(-ww * 0.5 - 4, -4, ww + 8, 6), mid)
		"bookshelf":
			var ww := w * T
			var hh := h * T
			draw_rect(Rect2(-ww * 0.5, -hh, ww, hh), Color("#2e2018"))
			draw_rect(Rect2(-ww * 0.5, -hh, ww, 3), Color("#4a3426"))
			var rng := RandomNumberGenerator.new()
			rng.seed = int(position.x * 7 + position.y)
			var y := -hh + 4.0
			var books := [Color("#6a2a2a"), Color("#2a3a6a"), Color("#5a5a2a"), Color("#2a5a3a"), Color("#6a4a3a"), Color("#4a2a5a")]
			while y < -10:
				var bx := -ww * 0.5 + 3
				while bx < ww * 0.5 - 5:
					var bw := rng.randf_range(2, 5)
					var bh := rng.randf_range(9, 13)
					draw_rect(Rect2(bx, y + 14 - bh, bw, bh), books[rng.randi() % books.size()])
					bx += bw + 1
				draw_rect(Rect2(-ww * 0.5, y + 14, ww, 2), Color("#4a3426"))
				y += 16
		"chandelier":
			var len := float(params.get("len", 3)) * T
			draw_line(Vector2(0, 0), Vector2(0, len), Color("#5a4a3a"), 1.0)
			var c := Vector2(0, len)
			draw_rect(Rect2(-22, c.y, 44, 4), Color("#8a6a3a"))
			draw_rect(Rect2(-14, c.y + 4, 28, 3), Color("#6a5030"))
			for i in 5:
				var x := -20.0 + i * 10.0
				draw_rect(Rect2(x - 1, c.y - 6, 2, 6), Color("#f0e8d0"))
				var f := sin(_t * 9.0 + i) * 0.7
				draw_colored_polygon(PackedVector2Array([Vector2(x - 1.5, c.y - 6), Vector2(x + f, c.y - 11), Vector2(x + 1.5, c.y - 6)]), Color(1.0, 0.8, 0.4))
		"lantern_red":
			var len2 := float(params.get("len", 2)) * T
			draw_line(Vector2.ZERO, Vector2(0, len2), Color("#3a2a2a"), 1.0)
			var sway := sin(_t * 1.5) * 1.5
			var lc := Vector2(sway, len2 + 10)
			draw_rect(Rect2(lc.x - 7, lc.y - 10, 14, 20), Color("#b8322a"))
			draw_rect(Rect2(lc.x - 5, lc.y - 7, 10, 14), Color("#f08a4a"))
			draw_rect(Rect2(lc.x - 8, lc.y - 12, 16, 3), Color("#3a2020"))
			draw_rect(Rect2(lc.x - 8, lc.y + 9, 16, 3), Color("#3a2020"))
			draw_line(lc + Vector2(0, 12), lc + Vector2(0, 18), Color("#c8a040"), 1.0)
		"candles":
			for i in 3:
				var x := -6.0 + i * 6.0
				var ch := 6.0 + (i % 2) * 4.0
				draw_rect(Rect2(x - 1.5, -ch, 3, ch), Color("#efe4c8"))
				var f2 := sin(_t * 8.0 + i * 1.7) * 0.8
				draw_colored_polygon(PackedVector2Array([Vector2(x - 1.5, -ch), Vector2(x + f2, -ch - 5), Vector2(x + 1.5, -ch)]), Color(1.0, 0.75, 0.35))
		"torch":
			draw_rect(Rect2(-2, -22, 4, 14), Color("#4a3426"))
			draw_rect(Rect2(-4, -24, 8, 3), Color("#6a6a78"))
			for i in 3:
				var f3 := sin(_t * 10.0 + i * 2.0)
				draw_colored_polygon(PackedVector2Array([Vector2(-4 + i * 3, -24), Vector2(-2 + i * 3 + f3, -34 - i * 2), Vector2(i * 3, -24)]), Color(1.0, 0.55 + i * 0.1, 0.25))
		"lamp_green":
			draw_rect(Rect2(-1, -14, 2, 14), Color("#3a3a2a"))
			draw_colored_polygon(PackedVector2Array([Vector2(-7, -14), Vector2(7, -14), Vector2(4, -22), Vector2(-4, -22)]), Color("#3a8a5a"))
			draw_rect(Rect2(-4, -14, 8, 2), Color(0.8, 1.0, 0.8, 0.8))
		"desk":
			var ww2 := w * T
			draw_rect(Rect2(-ww2 * 0.5, -14, ww2, 4), Color("#5a3e2a"))
			draw_rect(Rect2(-ww2 * 0.5 + 2, -10, 3, 10), Color("#3e2a1c"))
			draw_rect(Rect2(ww2 * 0.5 - 5, -10, 3, 10), Color("#3e2a1c"))
			if bool(params.get("books", true)):
				draw_rect(Rect2(-6, -19, 10, 5), Color("#6a2a2a"))
				draw_rect(Rect2(-4, -22, 8, 3), Color("#2a3a6a"))
				draw_rect(Rect2(6, -17, 6, 3), Color("#e8dcc0"))
		"blackboard":
			var ww3 := w * T
			draw_rect(Rect2(-ww3 * 0.5 - 3, -h * T - 3, ww3 + 6, h * T + 3), Color("#5a3e2a"))
			draw_rect(Rect2(-ww3 * 0.5, -h * T, ww3, h * T - 2), Color("#1e3a2e"))
			# 분필 마법진·글씨
			draw_arc(Vector2(-ww3 * 0.2, -h * T * 0.5), 10, 0, TAU, 16, Color(1, 1, 1, 0.6), 1.0)
			draw_line(Vector2(-ww3 * 0.2 - 10, -h * T * 0.5), Vector2(-ww3 * 0.2 + 10, -h * T * 0.5), Color(1, 1, 1, 0.5), 1.0)
			for i in 3:
				draw_line(Vector2(ww3 * 0.02, -h * T + 8 + i * 7), Vector2(ww3 * 0.38, -h * T + 8 + i * 7), Color(1, 1, 1, 0.4), 1.0)
		"cauldron":
			draw_circle(Vector2(0, -10), 12.0, Color("#26262e"))
			draw_rect(Rect2(-13, -20, 26, 4), Color("#3a3a46"))
			draw_rect(Rect2(-11, -21, 22, 2), Color(0.4, 0.9, 0.5))
			for i in 3:
				var by := fmod(_t * 14.0 + i * 9.0, 20.0)
				draw_circle(Vector2(-6 + i * 6, -22 - by), 1.5 + (1.0 - by / 20.0), Color(0.5, 1.0, 0.6, 1.0 - by / 20.0))
			draw_rect(Rect2(-14, -2, 4, 2), Color("#3a3a46"))
			draw_rect(Rect2(10, -2, 4, 2), Color("#3a3a46"))
		"potion_shelf":
			var ww4 := w * T
			draw_rect(Rect2(-ww4 * 0.5, -h * T, ww4, h * T), Color("#2e2018"))
			var pcols := [Color("#e84a4a"), Color("#4ae8a0"), Color("#4a8ae8"), Color("#e8c84a"), Color("#c84ae8")]
			for r in int(h):
				draw_rect(Rect2(-ww4 * 0.5, -h * T + r * T + 14, ww4, 2), Color("#4a3426"))
				for c in int(ww4 / 6.0) - 1:
					var pc: Color = pcols[(r * 5 + c * 3) % pcols.size()]
					draw_rect(Rect2(-ww4 * 0.5 + 3 + c * 6, -h * T + r * T + 7, 4, 7), Color(pc, 0.85))
					draw_rect(Rect2(-ww4 * 0.5 + 4 + c * 6, -h * T + r * T + 5, 2, 2), Color("#c8b8a0"))
		"bed_prop":
			draw_rect(Rect2(-20, -10, 40, 8), Color("#5a3a4a"))
			draw_rect(Rect2(-20, -12, 40, 3), Color("#e8dcc8"))
			draw_rect(Rect2(-20, -16, 9, 6), Color("#f0e8d8"))
			draw_rect(Rect2(-22, -20, 3, 20), Color("#4a2e22"))
			draw_rect(Rect2(19, -14, 3, 14), Color("#4a2e22"))
		"statue":
			draw_rect(Rect2(-12, -10, 24, 10), Color("#3a3650"))
			draw_rect(Rect2(-10, -12, 20, 2), Color("#5a5670"))
			var s := PackedVector2Array([Vector2(-8, -12), Vector2(8, -12), Vector2(5, -44), Vector2(0, -50), Vector2(-5, -44)])
			draw_colored_polygon(s, Color("#4a4666"))
			draw_colored_polygon(PackedVector2Array([Vector2(-10, -48), Vector2(10, -48), Vector2(2, -66)]), Color("#3a3650"))
			draw_line(Vector2(6, -36), Vector2(14, -54), Color("#5a5670"), 2.0)
		"fox_statue":
			# 신계의 여우 석상 (앉은 모습)
			var st := Color("#4a4a5e")
			draw_rect(Rect2(-10, -6, 20, 6), st.darkened(0.2))
			draw_colored_polygon(PackedVector2Array([Vector2(-8, -6), Vector2(8, -6), Vector2(6, -22), Vector2(-4, -26)]), st)
			draw_colored_polygon(PackedVector2Array([Vector2(-4, -26), Vector2(6, -22), Vector2(8, -32), Vector2(-2, -34)]), st.lightened(0.05))
			draw_colored_polygon(PackedVector2Array([Vector2(-2, -34), Vector2(0, -42), Vector2(2, -33)]), st)
			draw_colored_polygon(PackedVector2Array([Vector2(4, -33), Vector2(7, -41), Vector2(8, -31)]), st)
			draw_colored_polygon(PackedVector2Array([Vector2(-8, -8), Vector2(-16, -16), Vector2(-14, -26), Vector2(-8, -14)]), st.darkened(0.1))
			draw_rect(Rect2(3, -29, 2, 1), Color(1.0, 0.4, 0.3, 0.6 + 0.4 * sin(_t * 2.0)))
			draw_rect(Rect2(-2, -12, 8, 2), Color("#b8322a"))
		"throne":
			# 너울의 왕좌: 단 위 높은 등받이, 아홉 꼬리 문양
			draw_rect(Rect2(-50, -12, 100, 12), Color("#3a1e22"))
			draw_rect(Rect2(-56, -4, 112, 4), Color("#5a2a2a"))
			draw_rect(Rect2(-24, -64, 48, 52), Color("#2a1418"))
			draw_rect(Rect2(-28, -70, 56, 8), Color("#8a2a24"))
			draw_rect(Rect2(-28, -24, 56, 6), Color("#8a2a24"))
			for i in 9:
				var a := -PI * 0.5 + (i - 4) * 0.22
				var c2 := Vector2(0, -60)
				draw_line(c2, c2 + Vector2(cos(a), sin(a)) * 46, Color(0.5, 0.75, 1.0, 0.25 + 0.1 * sin(_t * 2.0 + i)), 3.0)
			draw_circle(Vector2(0, -44), 6, Color("#c8a040"))
		"altar":
			draw_rect(Rect2(-14, -16, 28, 16), Color("#3a2a30"))
			draw_rect(Rect2(-18, -20, 36, 4), Color("#8a2a24"))
			draw_rect(Rect2(-18, -20, 36, 1), Color("#c8a040"))
		"bead":
			# 여우구슬 (떠 있는 푸른 빛 구슬)
			var by2 := -42.0 + sin(_t * 1.8) * 3.0
			for r in [16.0, 11.0, 7.0]:
				draw_circle(Vector2(0, by2), r, Color(0.5, 0.8, 1.0, 0.12 + (16.0 - r) * 0.04))
			draw_circle(Vector2(0, by2), 5.0, Color(0.85, 0.95, 1.0))
			draw_circle(Vector2(-1.5, by2 - 1.5), 1.5, Color.WHITE)
		"bell":
			draw_line(Vector2.ZERO, Vector2(0, 14), Color("#3a2a2a"), 1.0)
			draw_colored_polygon(PackedVector2Array([Vector2(-8, 30), Vector2(-6, 18), Vector2(0, 14), Vector2(6, 18), Vector2(8, 30)]), Color("#8a6a3a"))
			draw_rect(Rect2(-9, 29, 18, 2), Color("#a8884a"))
		"clock_face":
			var r2 := w * T * 0.5
			draw_circle(Vector2(0, -r2), r2 + 3, Color("#3a2a20"))
			draw_circle(Vector2(0, -r2), r2, Color("#d8c8a0"))
			for i in 12:
				var a2 := TAU * i / 12.0
				draw_rect(Rect2(Vector2(0, -r2) + Vector2(cos(a2), sin(a2)) * (r2 - 4) - Vector2(1, 1), Vector2(2, 2)), Color("#3a2a20"))
			var hm := _t * 0.05
			draw_line(Vector2(0, -r2), Vector2(0, -r2) + Vector2(cos(hm - PI * 0.5), sin(hm - PI * 0.5)) * r2 * 0.5, Color("#2a1a10"), 2.0)
			draw_line(Vector2(0, -r2), Vector2(0, -r2) + Vector2(cos(hm * 12.0 - PI * 0.5), sin(hm * 12.0 - PI * 0.5)) * r2 * 0.8, Color("#2a1a10"), 1.0)
		"chain":
			var len3 := h * T
			var y2 := 0.0
			while y2 < len3:
				draw_rect(Rect2(-3, y2, 6, 7), Color("#4a4048"))
				draw_rect(Rect2(-1, y2 + 2, 2, 3), Color("#1a1418"))
				y2 += 8
		"banner":
			var bc := Color(params.get("col", Color("#6a1e30")))
			var sway2 := sin(_t * 1.2) * 1.5
			draw_rect(Rect2(-12, 0, 24, 2), Color("#8a6a3a"))
			draw_colored_polygon(PackedVector2Array([Vector2(-10, 2), Vector2(10, 2), Vector2(10 + sway2, h * T), Vector2(sway2, h * T - 8), Vector2(-10 + sway2, h * T)]), bc)
			draw_circle(Vector2(sway2 * 0.5, h * T * 0.4), 4, Color("#c8a040"))
		"plant":
			draw_rect(Rect2(-6, -8, 12, 8), Color("#7a4a3a"))
			for i in 5:
				var a3 := -PI * 0.5 + (i - 2) * 0.35
				draw_line(Vector2(0, -8), Vector2(cos(a3), sin(a3)) * 14 + Vector2(0, -8), Color("#3a7a4a"), 2.0)
		"crate":
			draw_rect(Rect2(-8, -16, 16, 16), Color("#5a3e2a"))
			draw_rect(Rect2(-8, -16, 16, 2), Color("#7a5a3a"))
			draw_line(Vector2(-8, -16), Vector2(8, 0), Color("#3e2a1c"), 1.0)
		"barrel":
			draw_rect(Rect2(-7, -18, 14, 18), Color("#5a3a26"))
			draw_rect(Rect2(-7, -15, 14, 2), Color("#3a3a40"))
			draw_rect(Rect2(-7, -5, 14, 2), Color("#3a3a40"))
		"rug":
			draw_rect(Rect2(-w * T * 0.5, -2, w * T, 2), Color("#7a2338"))
			draw_rect(Rect2(-w * T * 0.5 + 2, -2, w * T - 4, 1), Color("#c8a040"))
		"painting":
			var pw := w * T
			var ph := h * T
			draw_rect(Rect2(-pw * 0.5 - 2, -ph - 2, pw + 4, ph + 4), Color("#8a6a3a"))
			draw_rect(Rect2(-pw * 0.5, -ph, pw, ph), Color(params.get("col", Color("#2a3a5a"))))
			draw_circle(Vector2(0, -ph * 0.55), ph * 0.22, Color("#e8d0c0").darkened(0.3))
			draw_rect(Rect2(-ph * 0.25, -ph * 0.35, ph * 0.5, ph * 0.35), Color("#3a2a4a"))
		"globe":
			draw_rect(Rect2(-1, -10, 2, 10), Color("#8a6a3a"))
			draw_circle(Vector2(0, -16), 7, Color("#3a6a8a"))
			draw_rect(Rect2(-4, -19, 5, 4), Color("#5a8a4a"))
			draw_arc(Vector2(0, -16), 8, -1.2, 1.8, 10, Color("#c8a040"), 1.0)
		"magic_circle":
			var mc := Color(params.get("col", Color(0.7, 0.55, 1.0)))
			var rr := w * T * 0.5
			draw_arc(Vector2(0, -2), rr, 0, TAU, 32, Color(mc, 0.5), 1.0)
			draw_arc(Vector2(0, -2), rr * 0.7, 0, TAU, 24, Color(mc, 0.35), 1.0)
			for i in 6:
				var a4 := _t * 0.3 + TAU * i / 6.0
				draw_line(Vector2(cos(a4), sin(a4) * 0.25) * rr + Vector2(0, -2), Vector2(cos(a4 + 2.1), sin(a4 + 2.1) * 0.25) * rr + Vector2(0, -2), Color(mc, 0.4), 1.0)
		"fountain":
			draw_rect(Rect2(-24, -8, 48, 8), Color("#4a4a5a"))
			draw_rect(Rect2(-20, -10, 40, 3), Color(0.5, 0.7, 0.9, 0.7))
			draw_rect(Rect2(-3, -30, 6, 22), Color("#5a5a6a"))
			for i in 4:
				var py2 := fmod(_t * 30.0 + i * 8.0, 30.0)
				draw_rect(Rect2(-1 + (i - 2) * 3, -30 + py2, 1, 3), Color(0.6, 0.8, 1.0, 0.7))
		"pillar":
			var ph2 := h * T
			draw_rect(Rect2(-10, -ph2, 20, ph2), mid)
			draw_rect(Rect2(-13, -ph2, 26, 6), mid.lightened(0.1))
			draw_rect(Rect2(-13, -6, 26, 6), mid.lightened(0.1))
			draw_rect(Rect2(-4, -ph2 + 6, 2, ph2 - 12), mid.darkened(0.2))
		"curtain":
			var cw := w * T
			var ch2 := h * T
			for i in int(cw / 6.0):
				var sw := sin(_t + i) * 0.5
				draw_rect(Rect2(-cw * 0.5 + i * 6 + sw, 0, 5, ch2 - (i % 2) * 3), Color("#5a1e2e").lightened((i % 2) * 0.06))
			draw_rect(Rect2(-cw * 0.5 - 2, -2, cw + 4, 4), Color("#c8a040"))
		"target_board":
			draw_rect(Rect2(-1, -10, 2, 10), Color("#4a3426"))
			draw_circle(Vector2(0, -18), 9, Color("#e8dcc0"))
			draw_circle(Vector2(0, -18), 6, Color("#c03030"))
			draw_circle(Vector2(0, -18), 3, Color("#e8dcc0"))
		"rock":
			draw_colored_polygon(PackedVector2Array([Vector2(-w * T * 0.5, 0), Vector2(-w * T * 0.3, -h * T), Vector2(w * T * 0.2, -h * T * 0.9), Vector2(w * T * 0.5, 0)]), dark)
		"pine":
			var ph3 := h * T
			draw_rect(Rect2(-3, -ph3 * 0.5, 6, ph3 * 0.5), Color("#2a2028"))
			for j in 4:
				var ww5 := 30.0 - j * 6.0
				var yy := -ph3 * 0.4 - j * ph3 * 0.15
				draw_colored_polygon(PackedVector2Array([Vector2(-ww5, yy), Vector2(0, yy - ph3 * 0.25), Vector2(ww5, yy)]), Color("#16202a"))
		"hongsal":
			# 홍살문: 붉은 기둥 둘, 위의 살대와 가운데 태극 문양
			var red := Color("#9a2a24")
			draw_rect(Rect2(-26, -64, 5, 64), red)
			draw_rect(Rect2(21, -64, 5, 64), red)
			draw_rect(Rect2(-32, -68, 64, 5), red.lightened(0.1))
			draw_rect(Rect2(-30, -56, 60, 3), red)
			for i in 12:
				draw_rect(Rect2(-24 + i * 4, -68, 1, 12), red.darkened(0.25))
			draw_circle(Vector2(0, -64), 4.0, Color("#3a5ab0"))
			draw_circle(Vector2(1, -65), 2.0, Color("#c8322a"))
		"debris":
			for i in 4:
				draw_rect(Rect2(-12 + i * 6, -4 - (i % 2) * 3, 5, 4 + (i % 2) * 3), Color("#4a4458").darkened(i * 0.05))
		_:
			# 2장부터의 소품: world/entities/<장>/props.gd 의 draw(prop, kind)
			for s in ChapterRegistry.prop_scripts():
				if s.draw(self, kind):
					break
