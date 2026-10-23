extends RefCounted
## 1장(신계·마녀학교) 소품 그림. Prop이 kind 표(PROPS)로 이 모듈을 찾아 draw(p, kind)를 부른다.
## 원점은 바닥(발밑) 기준이고, 매달린 것(샹들리에·등롱·사슬·현수막·커튼)은 천장 기준. 공통 키: w, h(타일), flip, front, col(색).
## 1장 kind 이름은 접두사가 없다(다른 장은 k_·tp_·st_ 등 — docs/dev/world.md "kind 이름 규칙").

const T := 16.0

## 소품 표: kind → {anim: 매 프레임 다시 그림, glow: 빛 [위치, 반지름, 색(null = 테마 강조색)] 또는 &"함수"(p → 같은 배열, 빈 배열 = 빛 없음),
## split: 정적 부분은 한 번, 움직이는 부분만 다시 그림(그림 함수가 p.static_part()/p.anim_part()로 나눠 그림)}
## anim이 아닌 소품은 처음 한 번만 그린다 — 그림이 시간(t)을 써도 멈춘 채로 보인다(torch처럼 일부러 그런 것도 있음).
const PROPS := {
	"window": {"anim": true, "glow": &"_glow_window"},
	"bookshelf": {},
	"chandelier": {"anim": true, "glow": [Vector2(0, 26), 90.0, null]},
	"lantern_red": {"anim": true, "glow": [Vector2(0, 22), 60.0, Color(1.0, 0.5, 0.3)]},
	"candles": {"anim": true, "glow": [Vector2(0, -16), 44.0, null]},
	"torch": {"glow": [Vector2(0, -26), 56.0, Color(1.0, 0.6, 0.3)]},
	"lamp_green": {"glow": [Vector2(0, -20), 40.0, Color(0.6, 1.0, 0.7)]},
	"desk": {},
	"blackboard": {"anim": true},
	"cauldron": {"anim": true, "glow": [Vector2(0, -20), 50.0, Color(0.5, 1.0, 0.6)]},
	"potion_shelf": {},
	"bed_prop": {},
	"statue": {},
	"fox_statue": {"anim": true},
	"throne": {"anim": true},
	"altar": {},
	"bead": {"anim": true, "glow": [Vector2(0, -40), 90.0, Color(0.5, 0.8, 1.0)]},
	"bell": {},
	"clock_face": {"anim": true},
	"chain": {},
	"banner": {"anim": true},
	"plant": {},
	"crate": {},
	"barrel": {},
	"rug": {},
	"painting": {},
	"globe": {},
	"magic_circle": {"anim": true, "glow": [Vector2(0, -4), 60.0, Color(0.7, 0.55, 1.0)]},
	"fountain": {"anim": true},
	"pillar": {},
	"curtain": {},
	"target_board": {},
	"rock": {},
	"pine": {},
	"hongsal": {},
	"debris": {},
}


static func _glow_window(p: Prop) -> Array:
	return [Vector2(0, -p.h * 8.0), 70.0 * p.w / 3.0, Color(0.7, 0.75, 1.0)]


## 그렸으면 true
static func draw(p: Prop, kind: String) -> bool:
	match kind:
		"window": _window(p)
		"bookshelf": _bookshelf(p)
		"chandelier": _chandelier(p)
		"lantern_red": _lantern_red(p)
		"candles": _candles(p)
		"torch": _torch(p)
		"lamp_green": _lamp_green(p)
		"desk": _desk(p)
		"blackboard": _blackboard(p)
		"cauldron": _cauldron(p)
		"potion_shelf": _potion_shelf(p)
		"bed_prop": _bed_prop(p)
		"statue": _statue(p)
		"fox_statue": _fox_statue(p)
		"throne": _throne(p)
		"altar": _altar(p)
		"bead": _bead(p)
		"bell": _bell(p)
		"clock_face": _clock_face(p)
		"chain": _chain(p)
		"banner": _banner(p)
		"plant": _plant(p)
		"crate": _crate(p)
		"barrel": _barrel(p)
		"rug": _rug(p)
		"painting": _painting(p)
		"globe": _globe(p)
		"magic_circle": _magic_circle(p)
		"fountain": _fountain(p)
		"pillar": _pillar(p)
		"curtain": _curtain(p)
		"target_board": _target_board(p)
		"rock": _rock(p)
		"pine": _pine(p)
		"hongsal": _hongsal(p)
		"debris": _debris(p)
		_:
			return false
	return true


static func _window(p: Prop) -> void:
	var t := p.time()
	var mid := Color(p.theme.mid).lightened(0.12)
	# 스테인드글라스 아치 창 (w×h 타일), 바닥에서 위로
	var ww := p.w * T
	var hh := p.h * T
	var arch := PackedVector2Array()
	for i in 11:
		var a := PI + PI * i / 10.0
		arch.append(Vector2(cos(a) * ww * 0.5, -hh + ww * 0.5 + sin(a) * ww * 0.5))
	arch.append(Vector2(ww * 0.5, 0))
	arch.append(Vector2(-ww * 0.5, 0))
	p.draw_colored_polygon(arch, Color("#141026"))
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
			var k := 0.55 + 0.15 * sin(t * 0.7 + r + c)
			p.draw_rect(Rect2(px, py, (ww - 6) / cols - 2, 8), Color(gc, k))
	p.draw_polyline(arch, Color("#2a2440"), 3.0)
	p.draw_rect(Rect2(-ww * 0.5 - 4, -4, ww + 8, 6), mid)


static func _bookshelf(p: Prop) -> void:
	var ww := p.w * T
	var hh := p.h * T
	p.draw_rect(Rect2(-ww * 0.5, -hh, ww, hh), Color("#2e2018"))
	p.draw_rect(Rect2(-ww * 0.5, -hh, ww, 3), Color("#4a3426"))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(p.anchor.x * 7 + p.anchor.y)
	var y := -hh + 4.0
	var books := [Color("#6a2a2a"), Color("#2a3a6a"), Color("#5a5a2a"), Color("#2a5a3a"), Color("#6a4a3a"), Color("#4a2a5a")]
	while y < -10:
		var bx := -ww * 0.5 + 3
		while bx < ww * 0.5 - 5:
			var bw := rng.randf_range(2, 5)
			var bh := rng.randf_range(9, 13)
			p.draw_rect(Rect2(bx, y + 14 - bh, bw, bh), books[rng.randi() % books.size()])
			bx += bw + 1
		p.draw_rect(Rect2(-ww * 0.5, y + 14, ww, 2), Color("#4a3426"))
		y += 16


static func _chandelier(p: Prop) -> void:
	var t := p.time()
	var len := float(p.params.get("len", 3)) * T
	p.draw_line(Vector2(0, 0), Vector2(0, len), Color("#5a4a3a"), 1.0)
	var c := Vector2(0, len)
	p.draw_rect(Rect2(-22, c.y, 44, 4), Color("#8a6a3a"))
	p.draw_rect(Rect2(-14, c.y + 4, 28, 3), Color("#6a5030"))
	for i in 5:
		var x := -20.0 + i * 10.0
		p.draw_rect(Rect2(x - 1, c.y - 6, 2, 6), Color("#f0e8d0"))
		var f := sin(t * 9.0 + i) * 0.7
		p.draw_colored_polygon(PackedVector2Array([Vector2(x - 1.5, c.y - 6), Vector2(x + f, c.y - 11), Vector2(x + 1.5, c.y - 6)]), Color(1.0, 0.8, 0.4))


static func _lantern_red(p: Prop) -> void:
	var t := p.time()
	var len2 := float(p.params.get("len", 2)) * T
	p.draw_line(Vector2.ZERO, Vector2(0, len2), Color("#3a2a2a"), 1.0)
	var sway := sin(t * 1.5) * 1.5
	var lc := Vector2(sway, len2 + 10)
	p.draw_rect(Rect2(lc.x - 7, lc.y - 10, 14, 20), Color("#b8322a"))
	p.draw_rect(Rect2(lc.x - 5, lc.y - 7, 10, 14), Color("#f08a4a"))
	p.draw_rect(Rect2(lc.x - 8, lc.y - 12, 16, 3), Color("#3a2020"))
	p.draw_rect(Rect2(lc.x - 8, lc.y + 9, 16, 3), Color("#3a2020"))
	p.draw_line(lc + Vector2(0, 12), lc + Vector2(0, 18), Color("#c8a040"), 1.0)


static func _candles(p: Prop) -> void:
	var t := p.time()
	for i in 3:
		var x := -6.0 + i * 6.0
		var ch := 6.0 + (i % 2) * 4.0
		p.draw_rect(Rect2(x - 1.5, -ch, 3, ch), Color("#efe4c8"))
		var f2 := sin(t * 8.0 + i * 1.7) * 0.8
		p.draw_colored_polygon(PackedVector2Array([Vector2(x - 1.5, -ch), Vector2(x + f2, -ch - 5), Vector2(x + 1.5, -ch)]), Color(1.0, 0.75, 0.35))


static func _torch(p: Prop) -> void:
	var t := p.time()
	p.draw_rect(Rect2(-2, -22, 4, 14), Color("#4a3426"))
	p.draw_rect(Rect2(-4, -24, 8, 3), Color("#6a6a78"))
	for i in 3:
		var f3 := sin(t * 10.0 + i * 2.0)
		p.draw_colored_polygon(PackedVector2Array([Vector2(-4 + i * 3, -24), Vector2(-2 + i * 3 + f3, -34 - i * 2), Vector2(i * 3, -24)]), Color(1.0, 0.55 + i * 0.1, 0.25))


static func _lamp_green(p: Prop) -> void:
	p.draw_rect(Rect2(-1, -14, 2, 14), Color("#3a3a2a"))
	p.draw_colored_polygon(PackedVector2Array([Vector2(-7, -14), Vector2(7, -14), Vector2(4, -22), Vector2(-4, -22)]), Color("#3a8a5a"))
	p.draw_rect(Rect2(-4, -14, 8, 2), Color(0.8, 1.0, 0.8, 0.8))


static func _desk(p: Prop) -> void:
	var ww2 := p.w * T
	p.draw_rect(Rect2(-ww2 * 0.5, -14, ww2, 4), Color("#5a3e2a"))
	p.draw_rect(Rect2(-ww2 * 0.5 + 2, -10, 3, 10), Color("#3e2a1c"))
	p.draw_rect(Rect2(ww2 * 0.5 - 5, -10, 3, 10), Color("#3e2a1c"))
	if bool(p.params.get("books", true)):
		p.draw_rect(Rect2(-6, -19, 10, 5), Color("#6a2a2a"))
		p.draw_rect(Rect2(-4, -22, 8, 3), Color("#2a3a6a"))
		p.draw_rect(Rect2(6, -17, 6, 3), Color("#e8dcc0"))


static func _blackboard(p: Prop) -> void:
	var ww3 := p.w * T
	p.draw_rect(Rect2(-ww3 * 0.5 - 3, -p.h * T - 3, ww3 + 6, p.h * T + 3), Color("#5a3e2a"))
	p.draw_rect(Rect2(-ww3 * 0.5, -p.h * T, ww3, p.h * T - 2), Color("#1e3a2e"))
	# 분필 마법진·글씨
	p.draw_arc(Vector2(-ww3 * 0.2, -p.h * T * 0.5), 10, 0, TAU, 16, Color(1, 1, 1, 0.6), 1.0)
	p.draw_line(Vector2(-ww3 * 0.2 - 10, -p.h * T * 0.5), Vector2(-ww3 * 0.2 + 10, -p.h * T * 0.5), Color(1, 1, 1, 0.5), 1.0)
	for i in 3:
		p.draw_line(Vector2(ww3 * 0.02, -p.h * T + 8 + i * 7), Vector2(ww3 * 0.38, -p.h * T + 8 + i * 7), Color(1, 1, 1, 0.4), 1.0)


static func _cauldron(p: Prop) -> void:
	var t := p.time()
	p.draw_circle(Vector2(0, -10), 12.0, Color("#26262e"))
	p.draw_rect(Rect2(-13, -20, 26, 4), Color("#3a3a46"))
	p.draw_rect(Rect2(-11, -21, 22, 2), Color(0.4, 0.9, 0.5))
	for i in 3:
		var by := fmod(t * 14.0 + i * 9.0, 20.0)
		p.draw_circle(Vector2(-6 + i * 6, -22 - by), 1.5 + (1.0 - by / 20.0), Color(0.5, 1.0, 0.6, 1.0 - by / 20.0))
	p.draw_rect(Rect2(-14, -2, 4, 2), Color("#3a3a46"))
	p.draw_rect(Rect2(10, -2, 4, 2), Color("#3a3a46"))


static func _potion_shelf(p: Prop) -> void:
	var ww4 := p.w * T
	p.draw_rect(Rect2(-ww4 * 0.5, -p.h * T, ww4, p.h * T), Color("#2e2018"))
	var pcols := [Color("#e84a4a"), Color("#4ae8a0"), Color("#4a8ae8"), Color("#e8c84a"), Color("#c84ae8")]
	for r in int(p.h):
		p.draw_rect(Rect2(-ww4 * 0.5, -p.h * T + r * T + 14, ww4, 2), Color("#4a3426"))
		for c in int(ww4 / 6.0) - 1:
			var pc: Color = pcols[(r * 5 + c * 3) % pcols.size()]
			p.draw_rect(Rect2(-ww4 * 0.5 + 3 + c * 6, -p.h * T + r * T + 7, 4, 7), Color(pc, 0.85))
			p.draw_rect(Rect2(-ww4 * 0.5 + 4 + c * 6, -p.h * T + r * T + 5, 2, 2), Color("#c8b8a0"))


static func _bed_prop(p: Prop) -> void:
	p.draw_rect(Rect2(-20, -10, 40, 8), Color("#5a3a4a"))
	p.draw_rect(Rect2(-20, -12, 40, 3), Color("#e8dcc8"))
	p.draw_rect(Rect2(-20, -16, 9, 6), Color("#f0e8d8"))
	p.draw_rect(Rect2(-22, -20, 3, 20), Color("#4a2e22"))
	p.draw_rect(Rect2(19, -14, 3, 14), Color("#4a2e22"))


static func _statue(p: Prop) -> void:
	p.draw_rect(Rect2(-12, -10, 24, 10), Color("#3a3650"))
	p.draw_rect(Rect2(-10, -12, 20, 2), Color("#5a5670"))
	var s := PackedVector2Array([Vector2(-8, -12), Vector2(8, -12), Vector2(5, -44), Vector2(0, -50), Vector2(-5, -44)])
	p.draw_colored_polygon(s, Color("#4a4666"))
	p.draw_colored_polygon(PackedVector2Array([Vector2(-10, -48), Vector2(10, -48), Vector2(2, -66)]), Color("#3a3650"))
	p.draw_line(Vector2(6, -36), Vector2(14, -54), Color("#5a5670"), 2.0)


static func _fox_statue(p: Prop) -> void:
	var t := p.time()
	# 신계의 여우 석상 (앉은 모습)
	var st := Color("#4a4a5e")
	p.draw_rect(Rect2(-10, -6, 20, 6), st.darkened(0.2))
	p.draw_colored_polygon(PackedVector2Array([Vector2(-8, -6), Vector2(8, -6), Vector2(6, -22), Vector2(-4, -26)]), st)
	p.draw_colored_polygon(PackedVector2Array([Vector2(-4, -26), Vector2(6, -22), Vector2(8, -32), Vector2(-2, -34)]), st.lightened(0.05))
	p.draw_colored_polygon(PackedVector2Array([Vector2(-2, -34), Vector2(0, -42), Vector2(2, -33)]), st)
	p.draw_colored_polygon(PackedVector2Array([Vector2(4, -33), Vector2(7, -41), Vector2(8, -31)]), st)
	p.draw_colored_polygon(PackedVector2Array([Vector2(-8, -8), Vector2(-16, -16), Vector2(-14, -26), Vector2(-8, -14)]), st.darkened(0.1))
	p.draw_rect(Rect2(3, -29, 2, 1), Color(1.0, 0.4, 0.3, 0.6 + 0.4 * sin(t * 2.0)))
	p.draw_rect(Rect2(-2, -12, 8, 2), Color("#b8322a"))


static func _throne(p: Prop) -> void:
	var t := p.time()
	# 너울의 왕좌: 단 위 높은 등받이, 아홉 꼬리 문양
	p.draw_rect(Rect2(-50, -12, 100, 12), Color("#3a1e22"))
	p.draw_rect(Rect2(-56, -4, 112, 4), Color("#5a2a2a"))
	p.draw_rect(Rect2(-24, -64, 48, 52), Color("#2a1418"))
	p.draw_rect(Rect2(-28, -70, 56, 8), Color("#8a2a24"))
	p.draw_rect(Rect2(-28, -24, 56, 6), Color("#8a2a24"))
	for i in 9:
		var a := -PI * 0.5 + (i - 4) * 0.22
		var c2 := Vector2(0, -60)
		p.draw_line(c2, c2 + Vector2(cos(a), sin(a)) * 46, Color(0.5, 0.75, 1.0, 0.25 + 0.1 * sin(t * 2.0 + i)), 3.0)
	p.draw_circle(Vector2(0, -44), 6, Color("#c8a040"))


static func _altar(p: Prop) -> void:
	p.draw_rect(Rect2(-14, -16, 28, 16), Color("#3a2a30"))
	p.draw_rect(Rect2(-18, -20, 36, 4), Color("#8a2a24"))
	p.draw_rect(Rect2(-18, -20, 36, 1), Color("#c8a040"))


static func _bead(p: Prop) -> void:
	var t := p.time()
	# 여우구슬 (떠 있는 푸른 빛 구슬)
	var by2 := -42.0 + sin(t * 1.8) * 3.0
	for r in [16.0, 11.0, 7.0]:
		p.draw_circle(Vector2(0, by2), r, Color(0.5, 0.8, 1.0, 0.12 + (16.0 - r) * 0.04))
	p.draw_circle(Vector2(0, by2), 5.0, Color(0.85, 0.95, 1.0))
	p.draw_circle(Vector2(-1.5, by2 - 1.5), 1.5, Color.WHITE)


static func _bell(p: Prop) -> void:
	p.draw_line(Vector2.ZERO, Vector2(0, 14), Color("#3a2a2a"), 1.0)
	p.draw_colored_polygon(PackedVector2Array([Vector2(-8, 30), Vector2(-6, 18), Vector2(0, 14), Vector2(6, 18), Vector2(8, 30)]), Color("#8a6a3a"))
	p.draw_rect(Rect2(-9, 29, 18, 2), Color("#a8884a"))


static func _clock_face(p: Prop) -> void:
	var t := p.time()
	var r2 := p.w * T * 0.5
	p.draw_circle(Vector2(0, -r2), r2 + 3, Color("#3a2a20"))
	p.draw_circle(Vector2(0, -r2), r2, Color("#d8c8a0"))
	for i in 12:
		var a2 := TAU * i / 12.0
		p.draw_rect(Rect2(Vector2(0, -r2) + Vector2(cos(a2), sin(a2)) * (r2 - 4) - Vector2(1, 1), Vector2(2, 2)), Color("#3a2a20"))
	var hm := t * 0.05
	p.draw_line(Vector2(0, -r2), Vector2(0, -r2) + Vector2(cos(hm - PI * 0.5), sin(hm - PI * 0.5)) * r2 * 0.5, Color("#2a1a10"), 2.0)
	p.draw_line(Vector2(0, -r2), Vector2(0, -r2) + Vector2(cos(hm * 12.0 - PI * 0.5), sin(hm * 12.0 - PI * 0.5)) * r2 * 0.8, Color("#2a1a10"), 1.0)


static func _chain(p: Prop) -> void:
	var len3 := p.h * T
	var y2 := 0.0
	while y2 < len3:
		p.draw_rect(Rect2(-3, y2, 6, 7), Color("#4a4048"))
		p.draw_rect(Rect2(-1, y2 + 2, 2, 3), Color("#1a1418"))
		y2 += 8


static func _banner(p: Prop) -> void:
	var t := p.time()
	var bc := Color(p.params.get("col", Color("#6a1e30")))
	var sway2 := sin(t * 1.2) * 1.5
	p.draw_rect(Rect2(-12, 0, 24, 2), Color("#8a6a3a"))
	p.draw_colored_polygon(PackedVector2Array([Vector2(-10, 2), Vector2(10, 2), Vector2(10 + sway2, p.h * T), Vector2(sway2, p.h * T - 8), Vector2(-10 + sway2, p.h * T)]), bc)
	p.draw_circle(Vector2(sway2 * 0.5, p.h * T * 0.4), 4, Color("#c8a040"))


static func _plant(p: Prop) -> void:
	p.draw_rect(Rect2(-6, -8, 12, 8), Color("#7a4a3a"))
	for i in 5:
		var a3 := -PI * 0.5 + (i - 2) * 0.35
		p.draw_line(Vector2(0, -8), Vector2(cos(a3), sin(a3)) * 14 + Vector2(0, -8), Color("#3a7a4a"), 2.0)


static func _crate(p: Prop) -> void:
	p.draw_rect(Rect2(-8, -16, 16, 16), Color("#5a3e2a"))
	p.draw_rect(Rect2(-8, -16, 16, 2), Color("#7a5a3a"))
	p.draw_line(Vector2(-8, -16), Vector2(8, 0), Color("#3e2a1c"), 1.0)


static func _barrel(p: Prop) -> void:
	p.draw_rect(Rect2(-7, -18, 14, 18), Color("#5a3a26"))
	p.draw_rect(Rect2(-7, -15, 14, 2), Color("#3a3a40"))
	p.draw_rect(Rect2(-7, -5, 14, 2), Color("#3a3a40"))


static func _rug(p: Prop) -> void:
	p.draw_rect(Rect2(-p.w * T * 0.5, -2, p.w * T, 2), Color("#7a2338"))
	p.draw_rect(Rect2(-p.w * T * 0.5 + 2, -2, p.w * T - 4, 1), Color("#c8a040"))


static func _painting(p: Prop) -> void:
	var pw := p.w * T
	var ph := p.h * T
	p.draw_rect(Rect2(-pw * 0.5 - 2, -ph - 2, pw + 4, ph + 4), Color("#8a6a3a"))
	p.draw_rect(Rect2(-pw * 0.5, -ph, pw, ph), Color(p.params.get("col", Color("#2a3a5a"))))
	p.draw_circle(Vector2(0, -ph * 0.55), ph * 0.22, Color("#e8d0c0").darkened(0.3))
	p.draw_rect(Rect2(-ph * 0.25, -ph * 0.35, ph * 0.5, ph * 0.35), Color("#3a2a4a"))


static func _globe(p: Prop) -> void:
	p.draw_rect(Rect2(-1, -10, 2, 10), Color("#8a6a3a"))
	p.draw_circle(Vector2(0, -16), 7, Color("#3a6a8a"))
	p.draw_rect(Rect2(-4, -19, 5, 4), Color("#5a8a4a"))
	p.draw_arc(Vector2(0, -16), 8, -1.2, 1.8, 10, Color("#c8a040"), 1.0)


static func _magic_circle(p: Prop) -> void:
	var t := p.time()
	var mc := Color(p.params.get("col", Color(0.7, 0.55, 1.0)))
	var rr := p.w * T * 0.5
	p.draw_arc(Vector2(0, -2), rr, 0, TAU, 32, Color(mc, 0.5), 1.0)
	p.draw_arc(Vector2(0, -2), rr * 0.7, 0, TAU, 24, Color(mc, 0.35), 1.0)
	for i in 6:
		var a4 := t * 0.3 + TAU * i / 6.0
		p.draw_line(Vector2(cos(a4), sin(a4) * 0.25) * rr + Vector2(0, -2), Vector2(cos(a4 + 2.1), sin(a4 + 2.1) * 0.25) * rr + Vector2(0, -2), Color(mc, 0.4), 1.0)


static func _fountain(p: Prop) -> void:
	var t := p.time()
	p.draw_rect(Rect2(-24, -8, 48, 8), Color("#4a4a5a"))
	p.draw_rect(Rect2(-20, -10, 40, 3), Color(0.5, 0.7, 0.9, 0.7))
	p.draw_rect(Rect2(-3, -30, 6, 22), Color("#5a5a6a"))
	for i in 4:
		var py2 := fmod(t * 30.0 + i * 8.0, 30.0)
		p.draw_rect(Rect2(-1 + (i - 2) * 3, -30 + py2, 1, 3), Color(0.6, 0.8, 1.0, 0.7))


static func _pillar(p: Prop) -> void:
	var mid := Color(p.theme.mid).lightened(0.12)
	var ph2 := p.h * T
	p.draw_rect(Rect2(-10, -ph2, 20, ph2), mid)
	p.draw_rect(Rect2(-13, -ph2, 26, 6), mid.lightened(0.1))
	p.draw_rect(Rect2(-13, -6, 26, 6), mid.lightened(0.1))
	p.draw_rect(Rect2(-4, -ph2 + 6, 2, ph2 - 12), mid.darkened(0.2))


static func _curtain(p: Prop) -> void:
	var t := p.time()
	var cw := p.w * T
	var ch2 := p.h * T
	for i in int(cw / 6.0):
		var sw := sin(t + i) * 0.5
		p.draw_rect(Rect2(-cw * 0.5 + i * 6 + sw, 0, 5, ch2 - (i % 2) * 3), Color("#5a1e2e").lightened((i % 2) * 0.06))
	p.draw_rect(Rect2(-cw * 0.5 - 2, -2, cw + 4, 4), Color("#c8a040"))


static func _target_board(p: Prop) -> void:
	p.draw_rect(Rect2(-1, -10, 2, 10), Color("#4a3426"))
	p.draw_circle(Vector2(0, -18), 9, Color("#e8dcc0"))
	p.draw_circle(Vector2(0, -18), 6, Color("#c03030"))
	p.draw_circle(Vector2(0, -18), 3, Color("#e8dcc0"))


static func _rock(p: Prop) -> void:
	var dark := Color(p.theme.near).darkened(0.2)
	p.draw_colored_polygon(PackedVector2Array([Vector2(-p.w * T * 0.5, 0), Vector2(-p.w * T * 0.3, -p.h * T), Vector2(p.w * T * 0.2, -p.h * T * 0.9), Vector2(p.w * T * 0.5, 0)]), dark)


static func _pine(p: Prop) -> void:
	var ph3 := p.h * T
	p.draw_rect(Rect2(-3, -ph3 * 0.5, 6, ph3 * 0.5), Color("#2a2028"))
	for j in 4:
		var ww5 := 30.0 - j * 6.0
		var yy := -ph3 * 0.4 - j * ph3 * 0.15
		p.draw_colored_polygon(PackedVector2Array([Vector2(-ww5, yy), Vector2(0, yy - ph3 * 0.25), Vector2(ww5, yy)]), Color("#16202a"))


static func _hongsal(p: Prop) -> void:
	# 홍살문: 붉은 기둥 둘, 위의 살대와 가운데 태극 문양
	var red := Color("#9a2a24")
	p.draw_rect(Rect2(-26, -64, 5, 64), red)
	p.draw_rect(Rect2(21, -64, 5, 64), red)
	p.draw_rect(Rect2(-32, -68, 64, 5), red.lightened(0.1))
	p.draw_rect(Rect2(-30, -56, 60, 3), red)
	for i in 12:
		p.draw_rect(Rect2(-24 + i * 4, -68, 1, 12), red.darkened(0.25))
	p.draw_circle(Vector2(0, -64), 4.0, Color("#3a5ab0"))
	p.draw_circle(Vector2(1, -65), 2.0, Color("#c8322a"))


static func _debris(p: Prop) -> void:
	for i in 4:
		p.draw_rect(Rect2(-12 + i * 6, -4 - (i % 2) * 3, 5, 4 + (i % 2) * 3), Color("#4a4458").darkened(i * 0.05))
