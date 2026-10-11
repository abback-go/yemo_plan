extends RefCounted
## 4장 소품 그림 (Prop이 아래 PROPS 표로 kind를 찾아 draw(p, kind)를 부름). 모든 이름은 tp_ 로 시작한다.
## 원점: 서 있는 것은 발밑(바닥 행), 매달린 것(tp_bell·tp_bell_small·tp_censer·tp_chain·tp_banner·tp_flags)은 천장 행.
##
##   tp_column (h)        대리석 기둥 — 금빛 머리·받침
##   tp_broken_column (h) 부러진 기둥 (꼭대기 들쭉날쭉, 금 간 자국)
##   tp_brazier           금 화로 + 흰금 성화 (일렁임, 빛)
##   tp_mirror (angle)    빛의 거울 (금 고리에 끼운 거울판, angle도만큼 돌아간 모습)
##   tp_bell (len, size)  매달린 큰 종 (천천히 흔들림)
##   tp_bell_small (len)  작은 종
##   tp_candles           기도 촛불 단 (계단식, 촛농)
##   tp_candelabra        일곱 갈래 큰 촛대
##   tp_pew (w)           나무 신도석
##   tp_lectern           독경대 + 펼친 경전 (책장이 가끔 넘어감)
##   tp_scrolls (w, h)    두루마리 서가
##   tp_books             쌓인 책 + 촛불
##   tp_statue (h, pose)  얼굴 없는 루멘 석상 (해의 관)
##   tp_wing_statue       무릎 꿇은 날개 석상 (장식용 — 움직이는 적은 seraph_statue)
##   tp_banner (h)        흰 깃발 + 금 해 문양 (흔들림)
##   tp_glass (w, h)      스테인드글라스 해 창 (빛이 일렁임)
##   tp_sun_relief (w)    벽의 해 원반 부조
##   tp_altar             흰 제단 + 금 천
##   tp_font              성수반 (물결 반짝임)
##   tp_censer (len)      매달린 향로 (흔들림 + 연기)
##   tp_chain (h)         금 사슬
##   tp_scaffold (w, h)   나무 비계
##   tp_stairs_broken (w) 무너진 계단 조각
##   tp_rubble (w)        대리석 잔해
##   tp_cairn             순례자의 돌무지 (눈 모자, 리본)
##   tp_flags (w, h)      기도 깃발 줄 (오른쪽으로 w칸, h칸 처짐)
##   tp_lantern           순례길 장대 등불
##   tp_pine (h)          눈 덮인 소나무
##   tp_shrine            길가 작은 사당 (해 성상 + 촛불)
##   tp_seal              금빛 봉인석 (장식판 — 부서지는 진짜는 seal_stone 개체)
##   tp_great_gate (w, h, open_if)  대신전 황금 정문 — 대리석 기둥·금 아치·해 문양 쐐기돌, 닫힌 금 문짝(가운데 쪽문은 door 개체).
##                        open_if 플래그가 서면 문짝이 안으로 열리고 따뜻한 빛이 새어 나온다

const ART := preload("res://world/entities/ch4/art.gd")

const MARBLE := Color("#9a94b4")
const MARBLE_LIGHT := Color("#d4cee6")
const MARBLE_DARK := Color("#5c5676")
const GOLD := Color("#e0b048")
const GOLD_LIGHT := Color("#ffe8a0")
const GOLD_DARK := Color("#8a6428")
const WOOD := Color("#5a3e2a")
const WOOD_LIGHT := Color("#8a6440")
const WOOD_DARK := Color("#3a281c")
const CLOTH := Color("#e8e2f0")
const CLOTH_SHADE := Color("#a8a0c0")
const WAX := Color("#efe4c8")
const SNOW := Color("#e4eaf6")
const STONE := Color("#5a5e74")
const STONE_LIGHT := Color("#8a8ea6")


## 소품 표 (Prop이 합침): kind → {anim, glow, split} — 뜻은 world/entities/base_props.gd 머리 참고.
const WARM := Color(1.0, 0.8, 0.45)
const HOLY := Color(1.0, 0.88, 0.55)
const PROPS := {
	"tp_column": {},
	"tp_broken_column": {},
	"tp_brazier": {"anim": true, "glow": [Vector2(0, -30), 72.0, HOLY]},
	"tp_mirror": {"anim": true, "glow": [Vector2(0, -28), 28.0, Color(1.0, 0.95, 0.85)]},
	"tp_bell": {"anim": true},
	"tp_bell_small": {"anim": true},
	"tp_candles": {"anim": true, "glow": [Vector2(0, -16), 52.0, WARM]},
	"tp_candelabra": {"anim": true, "glow": [Vector2(0, -46), 64.0, WARM]},
	"tp_pew": {},
	"tp_lectern": {"anim": true},
	"tp_scrolls": {},
	"tp_books": {"anim": true, "glow": [Vector2(8, -18), 34.0, WARM]},
	"tp_statue": {"anim": true, "split": true, "glow": &"_glow_statue"},
	"tp_wing_statue": {"anim": true},
	"tp_banner": {"anim": true},
	"tp_glass": {"anim": true, "glow": &"_glow_glass"},
	"tp_sun_relief": {"anim": true, "glow": &"_glow_sun_relief"},
	"tp_altar": {"anim": true, "glow": [Vector2(0, -24), 44.0, HOLY]},
	"tp_font": {"anim": true, "glow": [Vector2(0, -16), 40.0, Color(0.75, 0.88, 1.0)]},
	"tp_censer": {"anim": true, "glow": &"_glow_censer"},
	"tp_chain": {},
	"tp_scaffold": {},
	"tp_stairs_broken": {},
	"tp_rubble": {},
	"tp_cairn": {},
	"tp_flags": {"anim": true},
	"tp_lantern": {"anim": true, "glow": [Vector2(10, -38), 52.0, WARM]},
	"tp_pine": {},
	"tp_shrine": {"anim": true, "glow": [Vector2(0, -22), 34.0, WARM]},
	"tp_seal": {"anim": true, "glow": [Vector2(0, -16), 40.0, HOLY]},
	"tp_great_gate": {},
}


# ─── 크기·값에 따라 달라지는 빛 (PROPS의 glow = &"함수") ──────

static func _glow_statue(p: Prop) -> Array:
	return [Vector2(0, -p.h * 16.0 * 0.86), 30.0 + p.h * 2.0, HOLY]


static func _glow_glass(p: Prop) -> Array:
	return [Vector2(0, -p.h * 8.0), 26.0 * p.w, HOLY]


static func _glow_sun_relief(p: Prop) -> Array:
	return [Vector2(0, -p.w * 8.0), p.w * 12.0, HOLY]


static func _glow_censer(p: Prop) -> Array:
	return [Vector2(0, float(p.params.get("len", 3)) * 16.0 + 10.0), 26.0, WARM]


## 그렸으면 true
static func draw(p: Prop, kind: String) -> bool:
	var t := p.time()
	match kind:
		"tp_column": _column(p, p.h if p.h > 1.0 else 10.0, false)
		"tp_broken_column": _column(p, p.h if p.h > 1.0 else 5.0, true)
		"tp_brazier": _brazier(p, t)
		"tp_mirror": ART.mirror(p, Vector2(0, -28), deg_to_rad(float(p.params.get("angle", 45.0))), t, 0.0)
		"tp_bell": _hanging_bell(p, t, float(p.params.get("len", 2)) * 16.0, 30.0 * float(p.params.get("size", 1.0)), 0.04)
		"tp_bell_small": _hanging_bell(p, t, float(p.params.get("len", 2)) * 16.0, 13.0, 0.12)
		"tp_candles": _candles(p, t)
		"tp_candelabra": _candelabra(p, t)
		"tp_pew": _pew(p, maxf(p.w, 2.0))
		"tp_lectern": _lectern(p, t)
		"tp_scrolls": _scrolls(p, maxf(p.w, 2.0), maxf(p.h, 3.0))
		"tp_books": _books(p, t)
		"tp_statue": _statue(p, p.h if p.h > 1.0 else 7.0, int(p.params.get("pose", 0)), t)
		"tp_wing_statue": _wing_statue(p, t)
		"tp_banner": _banner(p, t, p.h if p.h > 1.0 else 5.0)
		"tp_glass": _glass(p, t, maxf(p.w, 2.0), maxf(p.h, 3.0))
		"tp_sun_relief": _sun_relief(p, t, maxf(p.w, 2.0))
		"tp_altar": _altar(p, t)
		"tp_font": _font(p, t)
		"tp_censer": _censer(p, t, float(p.params.get("len", 3)) * 16.0)
		"tp_chain": _chain(p, p.h * 16.0)
		"tp_scaffold": _scaffold(p, maxf(p.w, 2.0), maxf(p.h, 3.0))
		"tp_stairs_broken": _stairs_broken(p, maxf(p.w, 3.0))
		"tp_rubble": _rubble(p, maxf(p.w, 1.0))
		"tp_cairn": _cairn(p)
		"tp_flags": _flags(p, t, maxf(p.w, 3.0), p.h)
		"tp_lantern": _lantern(p, t)
		"tp_pine": _pine(p, p.h if p.h > 1.0 else 7.0)
		"tp_shrine": _shrine(p, t)
		"tp_seal": ART.seal_stone(p, Vector2.ZERO, t, 1.0, 0.0)
		"tp_great_gate": _great_gate(p, t, maxf(p.w, 7.0), maxf(p.h, 10.0))
		_:
			return false
	return true


# ─── 작은 도우미 ───────────────────────────────────────

## 촛불 하나 (base = 심지 위치)
static func _flame(c: CanvasItem, base: Vector2, h: float, t: float, seed: float) -> void:
	var f := sin(t * 9.0 + seed) * 0.6 + sin(t * 23.0 + seed * 2.0) * 0.3
	c.draw_colored_polygon(PackedVector2Array([base + Vector2(-1.6, 0), base + Vector2(f, -h), base + Vector2(1.6, 0)]), Color(1.0, 0.72, 0.3))
	c.draw_colored_polygon(PackedVector2Array([base + Vector2(-0.8, 0), base + Vector2(f * 0.6, -h * 0.6), base + Vector2(0.8, 0)]), Color(1.0, 0.95, 0.75))


static func _candle(c: CanvasItem, x: float, base_y: float, h: float, t: float, seed: float) -> void:
	c.draw_rect(Rect2(x - 1.5, base_y - h, 3, h), WAX)
	c.draw_rect(Rect2(x + 0.5, base_y - h, 1, h), WAX.darkened(0.15))
	c.draw_rect(Rect2(x - 1.5, base_y - h + 1, 1, 2), Color(1, 1, 1, 0.6))
	_flame(c, Vector2(x, base_y - h), 4.0, t, seed)


# ─── 기둥 ───────────────────────────────────────────────

static func _column(c: Prop, h_t: float, broken: bool) -> void:
	var H := h_t * 16.0
	c.draw_rect(Rect2(-13, -6, 26, 6), MARBLE_DARK)
	c.draw_rect(Rect2(-13, -6, 26, 1), MARBLE)
	c.draw_rect(Rect2(-11, -9, 22, 3), MARBLE)
	c.draw_rect(Rect2(-11, -9, 22, 1), GOLD)
	var top := -H + 8.0
	if broken:
		top = -H
	var shaft_h := -9.0 - top
	c.draw_rect(Rect2(-9, top, 18, shaft_h), MARBLE)
	c.draw_rect(Rect2(-9, top, 4, shaft_h), MARBLE_LIGHT)
	c.draw_rect(Rect2(5, top, 4, shaft_h), MARBLE_DARK)
	for fx: float in [-3.0, 0.0, 3.0]:
		c.draw_rect(Rect2(fx, top, 1, shaft_h), MARBLE.darkened(0.15))
	if broken:
		# 들쭉날쭉한 꼭대기 + 금 간 자국
		c.draw_colored_polygon(PackedVector2Array([Vector2(-9, top), Vector2(-6, top - 5), Vector2(-2, top - 1), Vector2(2, top - 7), Vector2(6, top - 2), Vector2(9, top - 4), Vector2(9, top + 2), Vector2(-9, top + 2)]), MARBLE)
		c.draw_colored_polygon(PackedVector2Array([Vector2(-9, top), Vector2(-6, top - 5), Vector2(-5, top - 1)]), MARBLE_LIGHT)
		c.draw_polyline(PackedVector2Array([Vector2(1, top + 4), Vector2(-2, top + 12), Vector2(1, top + 18), Vector2(-1, top + 26)]), MARBLE_DARK.darkened(0.2), 1.0)
		c.draw_rect(Rect2(10, -4, 5, 4), MARBLE)
		c.draw_rect(Rect2(-17, -3, 4, 3), MARBLE_DARK)
		return
	c.draw_rect(Rect2(-14, -H, 28, 5), MARBLE)
	c.draw_rect(Rect2(-14, -H, 28, 1), GOLD_LIGHT)
	c.draw_rect(Rect2(-12, -H + 5, 24, 3), GOLD)
	c.draw_rect(Rect2(-12, -H + 7, 24, 1), GOLD_DARK)
	for sx: float in [-13.0, 13.0]:
		c.draw_circle(Vector2(sx, -H + 6), 2.5, GOLD)
		c.draw_circle(Vector2(sx, -H + 6), 1.0, GOLD_DARK)


# ─── 불·빛 ─────────────────────────────────────────────

static func _brazier(c: Prop, t: float) -> void:
	for lx: float in [-10.0, 0.0, 10.0]:
		c.draw_line(Vector2(lx * 0.6, -17), Vector2(lx, 0), GOLD_DARK, 2.0)
	c.draw_rect(Rect2(-12, -2, 24, 2), GOLD_DARK)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-12, -24), Vector2(12, -24), Vector2(8, -16), Vector2(-8, -16)]), GOLD)
	c.draw_rect(Rect2(-12, -24, 24, 1), GOLD_LIGHT)
	c.draw_rect(Rect2(-9, -21, 18, 1), GOLD_DARK)
	for i in 3:
		c.draw_circle(Vector2(-6 + i * 6, -20), 1.0, GOLD_LIGHT)
	# 흰금 성화: 겹친 불꽃 혀
	for i in 5:
		var x := -8.0 + i * 4.0
		var hh := 10.0 + 5.0 * sin(t * 7.0 + i * 1.9) + (4.0 if i == 2 else 0.0)
		var sw := sin(t * 5.0 + i) * 1.5
		c.draw_colored_polygon(PackedVector2Array([Vector2(x - 3, -24), Vector2(x + sw, -24 - hh), Vector2(x + 3, -24)]), Color(1.0, 0.78, 0.32))
	for i in 3:
		var x := -4.0 + i * 4.0
		var hh := 7.0 + 3.0 * sin(t * 9.0 + i * 2.3)
		c.draw_colored_polygon(PackedVector2Array([Vector2(x - 2, -24), Vector2(x + sin(t * 6.0 + i), -24 - hh), Vector2(x + 2, -24)]), Color(1.0, 0.97, 0.85))
	for i in 4:
		var k := fmod(t * 0.9 + i * 0.27, 1.0)
		c.draw_rect(Rect2(-6 + i * 4 + sin(t * 3.0 + i) * 2.0, -30 - k * 22.0, 1, 1), Color(1.0, 0.9, 0.6, 1.0 - k))


static func _candles(c: Prop, t: float) -> void:
	c.draw_rect(Rect2(-15, -4, 30, 4), GOLD_DARK)
	c.draw_rect(Rect2(-15, -4, 30, 1), GOLD)
	c.draw_rect(Rect2(-11, -8, 22, 4), GOLD_DARK.lightened(0.05))
	c.draw_rect(Rect2(-11, -8, 22, 1), GOLD)
	c.draw_rect(Rect2(-6, -12, 12, 4), GOLD_DARK.lightened(0.1))
	c.draw_rect(Rect2(-6, -12, 12, 1), GOLD_LIGHT)
	var rows := [[-4.0, [-13.0, -9.0, 9.0, 13.0]], [-8.0, [-8.0, -4.0, 4.0, 8.0]], [-12.0, [-3.0, 1.0, 4.0]]]
	var n := 0
	for row in rows:
		var by: float = row[0]
		for x in row[1]:
			var hh := 4.0 + float((n * 7) % 5)
			_candle(c, float(x), by, hh, t, n * 1.7)
			n += 1
	# 녹아 흐른 촛농
	c.draw_rect(Rect2(-12, -4, 1, 2), WAX)
	c.draw_rect(Rect2(10, -8, 1, 3), WAX)


static func _candelabra(c: Prop, t: float) -> void:
	c.draw_colored_polygon(PackedVector2Array([Vector2(-8, 0), Vector2(8, 0), Vector2(3, -6), Vector2(-3, -6)]), GOLD_DARK)
	c.draw_rect(Rect2(-1.5, -40, 3, 34), GOLD)
	c.draw_rect(Rect2(-1.5, -40, 1, 34), GOLD_LIGHT)
	for i in 3:
		c.draw_circle(Vector2(0, -12 - i * 10), 2.0, GOLD_DARK)
	# 일곱 갈래
	var cups: Array[Vector2] = []
	for i in 7:
		var dx := (i - 3) * 5.0
		var cy := -40.0 - (3 - absi(i - 3)) * 2.0
		if i != 3:
			c.draw_line(Vector2(0, -34), Vector2(dx, cy), GOLD, 1.5)
		cups.append(Vector2(dx, cy))
	for i in cups.size():
		var cp := cups[i]
		c.draw_rect(Rect2(cp.x - 2, cp.y - 1, 4, 2), GOLD_LIGHT)
		_candle(c, cp.x, cp.y - 1, 5.0, t, i * 1.3)


static func _books(c: Prop, t: float) -> void:
	var cols: Array[Color] = [Color("#6a2a34"), Color("#2a3a6a"), Color("#6a5a2a"), Color("#3a5a3a")]
	for i in 4:
		var w := 14.0 - i * 2.0
		var x := -9.0 + (i % 2) * 2.0
		var y := -3.0 - i * 3.0
		c.draw_rect(Rect2(x, y, w, 3), cols[i])
		c.draw_rect(Rect2(x + w - 2, y, 2, 3), Color("#e8dcc0"))
		c.draw_rect(Rect2(x, y, w, 1), cols[i].lightened(0.2))
	# 펼친 책
	c.draw_colored_polygon(PackedVector2Array([Vector2(-10, -15), Vector2(-2, -17), Vector2(-2, -14), Vector2(-10, -13)]), Color("#efe6d0"))
	c.draw_colored_polygon(PackedVector2Array([Vector2(-2, -17), Vector2(6, -15), Vector2(6, -13), Vector2(-2, -14)]), Color("#e4d8bc"))
	for i in 3:
		c.draw_line(Vector2(-9, -15 + i), Vector2(-3, -16.5 + i), Color(0.4, 0.35, 0.3, 0.6), 1.0)
	# 촛불
	c.draw_rect(Rect2(6, -4, 6, 2), GOLD_DARK)
	_candle(c, 9.0, -4.0, 7.0, t, 3.3)


# ─── 종·향로·사슬 (매달림) ─────────────────────────────

static func _hanging_bell(c: Prop, t: float, length: float, size: float, swing: float) -> void:
	c.draw_rect(Rect2(-size * 0.4, -2, size * 0.8, 3), WOOD_DARK)
	ART.bell(c, Vector2(0, 0), length, size, sin(t * 1.1 + c.anchor.x * 0.01) * swing, ART.BELL_METAL, 0.0, 0.5)


static func _censer(c: Prop, t: float, length: float) -> void:
	var ang := sin(t * 1.3) * 0.12
	var dir := Vector2(sin(ang), cos(ang))
	var end := dir * length
	var y := 0.0
	while y < length:
		var p := dir * y
		c.draw_rect(Rect2(p.x - 1, p.y, 2, 4), GOLD_DARK)
		y += 5.0
	var cen := end + Vector2(0, 8)
	c.draw_colored_polygon(PackedVector2Array([cen + Vector2(-7, -6), cen + Vector2(7, -6), cen + Vector2(5, 4), cen + Vector2(-5, 4)]), GOLD)
	c.draw_colored_polygon(PackedVector2Array([cen + Vector2(-5, -6), cen + Vector2(0, -12), cen + Vector2(5, -6)]), GOLD_DARK)
	c.draw_rect(Rect2(cen.x - 7, cen.y - 6, 14, 1), GOLD_LIGHT)
	for i in 3:
		c.draw_rect(Rect2(cen.x - 4 + i * 3, cen.y - 3, 1, 3), Color(1.0, 0.75, 0.35, 0.8 + 0.2 * sin(t * 5.0 + i)))
	# 향 연기
	for i in 6:
		var k := fmod(t * 0.35 + i / 6.0, 1.0)
		var sp := cen + Vector2(sin(k * 6.0 + i) * 4.0 * k, -12 - k * 30.0)
		c.draw_circle(sp, 2.0 + k * 4.0, Color(0.85, 0.82, 0.9, 0.18 * (1.0 - k)))


static func _chain(c: Prop, length: float) -> void:
	var y := 0.0
	var i := 0
	while y < length:
		if i % 2 == 0:
			c.draw_rect(Rect2(-2, y, 4, 6), GOLD_DARK)
			c.draw_rect(Rect2(-1, y + 1, 2, 4), Color(0.05, 0.04, 0.06))
			c.draw_rect(Rect2(-2, y, 1, 6), GOLD)
		else:
			c.draw_rect(Rect2(-1, y, 2, 6), GOLD)
		y += 5.0
		i += 1


# ─── 가구·서가 ─────────────────────────────────────────

static func _pew(c: Prop, w_t: float) -> void:
	var W := w_t * 16.0
	var x0 := -W * 0.5
	c.draw_rect(Rect2(x0, -18, W, 6), WOOD)
	c.draw_rect(Rect2(x0, -18, W, 1), WOOD_LIGHT)
	c.draw_rect(Rect2(x0, -13, W, 1), WOOD_DARK)
	c.draw_rect(Rect2(x0, -9, W, 3), WOOD_LIGHT)
	c.draw_rect(Rect2(x0, -6, W, 1), WOOD_DARK)
	for ex: float in [x0, x0 + W - 4.0]:
		c.draw_rect(Rect2(ex, -20, 4, 20), WOOD_DARK)
		c.draw_circle(Vector2(ex + 2, -20), 2.0, WOOD)
		c.draw_rect(Rect2(ex + 1, -18, 1, 16), WOOD_LIGHT)
	var lx := x0 + 12.0
	while lx < x0 + W - 8.0:
		c.draw_rect(Rect2(lx, -6, 2, 6), WOOD_DARK)
		lx += 14.0
	# 방석
	c.draw_rect(Rect2(x0 + 6, -11, minf(10.0, W - 12.0), 2), Color("#6a2a3a"))


static func _lectern(c: Prop, t: float) -> void:
	c.draw_rect(Rect2(-7, -2, 14, 2), WOOD_DARK)
	c.draw_rect(Rect2(-2, -20, 4, 18), WOOD)
	c.draw_rect(Rect2(-2, -20, 1, 18), WOOD_LIGHT)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-11, -24), Vector2(11, -28), Vector2(11, -24), Vector2(-11, -20)]), WOOD)
	c.draw_line(Vector2(-11, -24), Vector2(11, -28), GOLD, 1.0)
	# 펼친 경전 (금 테두리) + 책갈피 리본
	c.draw_colored_polygon(PackedVector2Array([Vector2(-10, -26), Vector2(0, -29), Vector2(0, -26), Vector2(-10, -23)]), Color("#f2ead6"))
	var flip := clampf(fmod(t, 7.0) - 6.0, 0.0, 1.0)
	var lift := sin(flip * PI) * 4.0
	c.draw_colored_polygon(PackedVector2Array([Vector2(0, -29), Vector2(10, -31 - lift), Vector2(10, -28 - lift * 0.6), Vector2(0, -26)]), Color("#e6dcc4"))
	for i in 3:
		c.draw_line(Vector2(-8, -25.5 + i * 0.8 - i * 0.5), Vector2(-2, -27.5 + i * 0.8 - i * 0.5), Color(0.35, 0.3, 0.3, 0.5), 1.0)
	c.draw_circle(Vector2(5, -28.5), 1.2, GOLD)
	c.draw_line(Vector2(0, -26), Vector2(1, -18), Color("#a83040"), 1.0)


static func _scrolls(c: Prop, w_t: float, h_t: float) -> void:
	var W := w_t * 16.0
	var H := h_t * 16.0
	var x0 := -W * 0.5
	c.draw_rect(Rect2(x0, -H, W, H), WOOD_DARK)
	c.draw_rect(Rect2(x0, -H, W, 3), WOOD)
	c.draw_rect(Rect2(x0, -H, 2, H), WOOD)
	c.draw_rect(Rect2(x0 + W - 2, -H, 2, H), WOOD)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(c.anchor.x * 13.0 + c.anchor.y)
	var tags: Array[Color] = [Color("#a83040"), Color("#3a5aa8"), Color("#c8a040"), Color("#4a8a5a")]
	var y := -H + 15.0
	while y < -2.0:
		c.draw_rect(Rect2(x0, y, W, 2), WOOD)
		var bx := x0 + 4.0
		while bx < x0 + W - 5.0:
			var r := rng.randf_range(2.5, 3.6)
			var cy := y - r - 0.5
			c.draw_circle(Vector2(bx + r, cy), r, Color("#e8dcc0"))
			c.draw_circle(Vector2(bx + r, cy), r * 0.45, Color("#a8987a"))
			if rng.randf() < 0.35:
				c.draw_rect(Rect2(bx + r - 1, cy + r - 1, 2, 3), tags[rng.randi() % tags.size()])
			bx += r * 2.0 + 0.5
		y += 13.0
	c.draw_rect(Rect2(x0 - 1, -H - 2, W + 2, 2), GOLD_DARK)


# ─── 석상·성물 ─────────────────────────────────────────

## 루멘 석상. split: 금빛 관(알파가 일렁임)과 그 뒤에 겹쳐 그리는 것만 움직임 층 (ART.lumen_statue의 part)
static func _statue(c: Prop, h_t: float, pose: int, t: float) -> void:
	var H := h_t * 16.0
	if c.static_part():
		c.draw_rect(Rect2(-H * 0.2, -10, H * 0.4, 10), MARBLE_DARK)
		c.draw_rect(Rect2(-H * 0.2, -10, H * 0.4, 1), GOLD)
		c.draw_rect(Rect2(-H * 0.17, -8, H * 0.34, 1), MARBLE_DARK.darkened(0.2))
	var crown := Color(GOLD, 0.85 + 0.15 * sin(t * 1.5))
	ART.lumen_statue(c, Vector2(0, -8), H - 8.0, MARBLE, MARBLE_LIGHT, crown, pose, -1.0, c.layer)


static func _wing_statue(c: Prop, t: float) -> void:
	# 무릎 꿇고 검을 짚은 날개 석상 (얼굴 없음)
	c.draw_rect(Rect2(-14, -6, 28, 6), MARBLE_DARK)
	c.draw_rect(Rect2(-14, -6, 28, 1), MARBLE)
	# 날개 (뒤쪽 큰 깃털 부채)
	for side: float in [-1.0, 1.0]:
		for i in 5:
			var a := -PI * 0.5 + side * (0.25 + i * 0.22)
			var ln := 26.0 - i * 3.0
			var root := Vector2(side * 3.0, -30)
			c.draw_colored_polygon(PackedVector2Array([root, root + Vector2(cos(a - 0.12), sin(a - 0.12)) * ln, root + Vector2(cos(a + 0.12), sin(a + 0.12)) * ln]), MARBLE_LIGHT if side < 0 else MARBLE)
	# 몸 (무릎 꿇음)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-7, -32), Vector2(7, -32), Vector2(9, -14), Vector2(12, -6), Vector2(-10, -6), Vector2(-8, -14)]), MARBLE)
	c.draw_rect(Rect2(-7, -32, 3, 18), MARBLE_LIGHT)
	c.draw_circle(Vector2(0, -36), 5.0, MARBLE)
	c.draw_circle(Vector2(-1.5, -37), 2.0, MARBLE_LIGHT)
	c.draw_arc(Vector2(0, -36), 7.0, PI * 1.05, PI * 1.95, 10, Color(GOLD, 0.7 + 0.3 * sin(t)), 1.0)
	# 짚은 검
	c.draw_line(Vector2(0, -22), Vector2(0, -6), MARBLE_LIGHT, 2.0)
	c.draw_line(Vector2(-4, -22), Vector2(4, -22), GOLD, 2.0)
	c.draw_circle(Vector2(0, -25), 1.5, GOLD)


static func _banner(c: Prop, t: float, h_t: float) -> void:
	var H := h_t * 16.0
	var sw := sin(t * 1.2 + c.anchor.x * 0.02) * 2.0
	c.draw_rect(Rect2(-14, 0, 28, 3), GOLD_DARK)
	c.draw_rect(Rect2(-14, 0, 28, 1), GOLD_LIGHT)
	c.draw_circle(Vector2(-14, 1.5), 2.0, GOLD)
	c.draw_circle(Vector2(14, 1.5), 2.0, GOLD)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-11, 3), Vector2(11, 3), Vector2(11 + sw, H), Vector2(sw, H - 9), Vector2(-11 + sw, H)]), CLOTH)
	c.draw_colored_polygon(PackedVector2Array([Vector2(5, 3), Vector2(11, 3), Vector2(11 + sw, H), Vector2(6 + sw, H - 3)]), CLOTH_SHADE)
	c.draw_line(Vector2(-8, 4), Vector2(-8 + sw * 0.9, H - 6), Color(GOLD, 0.8), 1.0)
	c.draw_line(Vector2(8, 4), Vector2(8 + sw * 0.9, H - 6), Color(GOLD, 0.8), 1.0)
	var sc := Vector2(sw * 0.3, H * 0.32)
	for i in 12:
		var a := TAU * i / 12.0 + t * 0.2
		c.draw_line(sc + Vector2(cos(a), sin(a)) * 5.0, sc + Vector2(cos(a), sin(a)) * (7.5 if i % 2 == 0 else 6.5), GOLD, 1.0)
	c.draw_circle(sc, 4.0, GOLD)
	c.draw_circle(sc, 2.5, GOLD_LIGHT)
	c.draw_line(Vector2(sw, H - 9), Vector2(sw, H - 3), GOLD, 1.0)


static func _glass(c: Prop, t: float, w_t: float, h_t: float) -> void:
	var W := w_t * 16.0
	var H := h_t * 16.0
	var r := W * 0.5
	var arch := PackedVector2Array()
	for i in 13:
		var a := PI + PI * float(i) / 12.0
		arch.append(Vector2(cos(a) * r, -H + r + sin(a) * r))
	arch.append(Vector2(r, 0))
	arch.append(Vector2(-r, 0))
	c.draw_colored_polygon(arch, Color("#1a1430"))
	# 해 무늬 유리: 가운데 해(금), 빛살 칸이 파랑·장미·금으로 번갈아
	var sc := Vector2(0, -H + r)
	var cols: Array[Color] = [Color("#4a6ad0"), Color("#d06a8a"), Color("#e8b850"), Color("#5aa0b0")]
	var rays := 12
	for i in rays:
		var a0 := PI + PI * float(i) / rays
		var a1 := PI + PI * float(i + 1) / rays
		var k := 0.6 + 0.25 * sin(t * 0.8 + i * 0.7)
		c.draw_colored_polygon(PackedVector2Array([sc + Vector2(cos(a0), sin(a0)) * r * 0.32, sc + Vector2(cos(a0), sin(a0)) * (r - 2), sc + Vector2(cos(a1), sin(a1)) * (r - 2), sc + Vector2(cos(a1), sin(a1)) * r * 0.32]), Color(cols[i % cols.size()], k))
	# 아래 세로 칸
	var rows := int((H - r) / 9.0)
	for row in rows:
		for col in 3:
			var px := -r + 3.0 + col * (W - 6.0) / 3.0
			var py := sc.y + 3.0 + row * 9.0
			if py > -4.0:
				continue
			var k2 := 0.55 + 0.2 * sin(t * 0.7 + row + col * 2.0)
			c.draw_rect(Rect2(px, py, (W - 6.0) / 3.0 - 2.0, 7), Color(cols[(row + col * 3 + 2) % cols.size()], k2))
	c.draw_circle(sc, r * 0.3, Color("#ffe090"))
	c.draw_circle(sc, r * 0.18, Color("#fff8e0"))
	# 납 테 + 금 창틀
	for i in rays + 1:
		var a := PI + PI * float(i) / rays
		c.draw_line(sc + Vector2(cos(a), sin(a)) * r * 0.3, sc + Vector2(cos(a), sin(a)) * r, Color("#201830"), 1.0)
	arch.remove_at(arch.size() - 1)
	arch.remove_at(arch.size() - 1)
	c.draw_polyline(arch, GOLD_DARK, 3.0)
	c.draw_line(Vector2(-r, -H + r), Vector2(-r, 0), GOLD_DARK, 3.0)
	c.draw_line(Vector2(r, -H + r), Vector2(r, 0), GOLD_DARK, 3.0)
	c.draw_rect(Rect2(-r - 4, -3, W + 8, 4), MARBLE_DARK)
	c.draw_rect(Rect2(-r - 4, -3, W + 8, 1), GOLD)


static func _sun_relief(c: Prop, t: float, w_t: float) -> void:
	var R := w_t * 8.0
	var cen := Vector2(0, -R)
	c.draw_circle(cen, R, MARBLE_DARK)
	c.draw_arc(cen, R - 1.0, 0, TAU, 32, MARBLE, 2.0)
	for i in 16:
		var a := TAU * i / 16.0 + t * 0.05
		var l0 := R * 0.42
		var l1 := R * (0.88 if i % 2 == 0 else 0.7)
		c.draw_colored_polygon(PackedVector2Array([cen + Vector2(cos(a - 0.1), sin(a - 0.1)) * l0, cen + Vector2(cos(a), sin(a)) * l1, cen + Vector2(cos(a + 0.1), sin(a + 0.1)) * l0]), GOLD if i % 2 == 0 else GOLD_DARK)
	c.draw_circle(cen, R * 0.38, GOLD)
	c.draw_circle(cen, R * 0.28, GOLD_LIGHT.lerp(GOLD, 0.5 + 0.5 * sin(t * 1.3)))


static func _altar(c: Prop, t: float) -> void:
	c.draw_rect(Rect2(-20, -16, 40, 16), MARBLE)
	c.draw_rect(Rect2(-20, -16, 40, 2), MARBLE_LIGHT)
	c.draw_rect(Rect2(14, -14, 6, 14), MARBLE_DARK)
	c.draw_rect(Rect2(-22, -18, 44, 3), MARBLE_LIGHT)
	# 금 천 (가운데로 늘어짐)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-8, -18), Vector2(8, -18), Vector2(8, -5), Vector2(0, -2), Vector2(-8, -5)]), GOLD)
	c.draw_line(Vector2(-6, -16), Vector2(-6, -5), GOLD_DARK, 1.0)
	c.draw_line(Vector2(6, -16), Vector2(6, -5), GOLD_DARK, 1.0)
	c.draw_circle(Vector2(0, -11), 3.0, GOLD_LIGHT)
	c.draw_circle(Vector2(0, -11), 1.5, GOLD)
	# 제단 위: 촛대 둘 + 성반
	for cx: float in [-15.0, 15.0]:
		c.draw_rect(Rect2(cx - 2, -20, 4, 2), GOLD_DARK)
		_candle(c, cx, -20.0, 7.0, t, cx)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-5, -20), Vector2(5, -20), Vector2(3, -23), Vector2(-3, -23)]), GOLD)


static func _font(c: Prop, t: float) -> void:
	c.draw_colored_polygon(PackedVector2Array([Vector2(-7, 0), Vector2(7, 0), Vector2(4, -8), Vector2(-4, -8)]), MARBLE_DARK)
	c.draw_rect(Rect2(-3, -14, 6, 6), MARBLE)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-14, -22), Vector2(14, -22), Vector2(9, -14), Vector2(-9, -14)]), MARBLE)
	c.draw_rect(Rect2(-14, -22, 28, 2), MARBLE_LIGHT)
	c.draw_rect(Rect2(-13, -21, 26, 1), GOLD)
	# 물: 일렁이는 빛
	c.draw_rect(Rect2(-12, -23, 24, 2), Color(0.6, 0.8, 1.0, 0.85))
	for i in 4:
		var x := -10.0 + fmod(t * 6.0 + i * 6.0, 20.0)
		c.draw_rect(Rect2(x, -23, 3, 1), Color(1, 1, 1, 0.8))
	for i in 3:
		var k := fmod(t * 0.7 + i * 0.33, 1.0)
		c.draw_rect(Rect2(-6 + i * 6, -26 - k * 10.0, 1, 1), Color(0.8, 0.9, 1.0, 1.0 - k))


# ─── 비계·잔해 ─────────────────────────────────────────

static func _scaffold(c: Prop, w_t: float, h_t: float) -> void:
	var W := w_t * 16.0
	var H := h_t * 16.0
	var x0 := -W * 0.5
	var x := x0
	while x <= x0 + W + 0.1:
		c.draw_rect(Rect2(x - 1.5, -H, 3, H), WOOD)
		c.draw_rect(Rect2(x - 1.5, -H, 1, H), WOOD_LIGHT)
		x += 32.0
	var y := -H
	while y < 0.0:
		c.draw_rect(Rect2(x0 - 3, y, W + 6, 3), WOOD)
		c.draw_rect(Rect2(x0 - 3, y, W + 6, 1), WOOD_LIGHT)
		y += 48.0
	var yy := -H
	while yy + 48.0 <= 0.1:
		var xx := x0
		while xx + 32.0 <= x0 + W + 0.1:
			c.draw_line(Vector2(xx, yy + 3), Vector2(xx + 32, yy + 48), WOOD_DARK, 1.5)
			xx += 32.0
		yy += 48.0
	# 밧줄 묶음
	c.draw_rect(Rect2(x0 - 2, -H + 6, 4, 3), Color("#a8885a"))


static func _stairs_broken(c: Prop, w_t: float) -> void:
	var n := int(w_t)
	for i in n:
		var x := -w_t * 8.0 + i * 16.0
		var hh := 4.0 + i * 4.0
		c.draw_rect(Rect2(x, -hh, 16, hh), MARBLE)
		c.draw_rect(Rect2(x, -hh, 16, 1), MARBLE_LIGHT)
		c.draw_rect(Rect2(x + 13, -hh, 3, hh), MARBLE_DARK)
	var ex := -w_t * 8.0 + n * 16.0
	c.draw_colored_polygon(PackedVector2Array([Vector2(ex, -n * 4.0 - 4.0), Vector2(ex + 6, -n * 4.0 + 2), Vector2(ex + 2, -n * 4.0 + 8), Vector2(ex + 7, 0), Vector2(ex, 0)]), MARBLE_DARK)


static func _rubble(c: Prop, w_t: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(c.anchor.x * 3.0 + 7.0)
	var W := w_t * 16.0
	for i in int(w_t * 3.0) + 2:
		var x := rng.randf_range(-W * 0.5, W * 0.5)
		var s := rng.randf_range(3.0, 7.0)
		var pts := PackedVector2Array([Vector2(x - s, 0), Vector2(x - s * 0.6, -s * rng.randf_range(0.6, 1.2)), Vector2(x + s * 0.5, -s * rng.randf_range(0.7, 1.3)), Vector2(x + s, 0)])
		c.draw_colored_polygon(pts, MARBLE if i % 2 == 0 else MARBLE_DARK)
		c.draw_line(pts[1], pts[2], MARBLE_LIGHT, 1.0)
	c.draw_rect(Rect2(W * 0.15, -3, 4, 2), GOLD)


# ─── 순례길 ─────────────────────────────────────────────

static func _cairn(c: Prop) -> void:
	var y := 0.0
	var ws: Array[float] = [16.0, 13.0, 11.0, 8.0, 6.0, 4.0]
	for i in ws.size():
		var w := ws[i]
		var hh := 5.0 if i < 2 else 4.0
		var off := (1.0 if i % 2 == 0 else -1.0) * 0.8
		c.draw_rect(Rect2(-w * 0.5 + off, y - hh, w, hh), STONE.lightened(0.04 * (i % 3)))
		c.draw_rect(Rect2(-w * 0.5 + off, y - hh, w, 1), STONE_LIGHT)
		y -= hh
	c.draw_rect(Rect2(-3, y - 2, 6, 2), SNOW)
	c.draw_rect(Rect2(-7, -10, 5, 1), SNOW)
	# 매어 둔 리본·작은 촛대
	c.draw_line(Vector2(4, -12), Vector2(8, -6), Color("#c84050"), 1.0)
	c.draw_line(Vector2(4, -12), Vector2(7, -4), Color("#4a6ad0"), 1.0)
	c.draw_rect(Rect2(-12, -3, 3, 3), WAX)


static func _flags(c: Prop, t: float, w_t: float, sag_t: float) -> void:
	var a := Vector2(-8, 0)
	var b := Vector2(-8 + w_t * 16.0, 0)
	var sag := maxf(sag_t, 0.6) * 16.0
	var cols: Array[Color] = [Color("#eef0f6"), Color("#e8c060"), Color("#5a8ad8"), Color("#d87070"), Color("#6ab07a")]
	var n := int(w_t * 2.0)
	var prev := a
	for i in n + 1:
		var k := float(i) / n
		var p := a.lerp(b, k) + Vector2(0, sin(k * PI) * sag)
		if i > 0:
			c.draw_line(prev, p, Color("#2a2430"), 1.0)
		prev = p
		if i == 0 or i == n:
			continue
		var sw := sin(t * 2.6 + i * 0.8) * 2.5
		var col := cols[i % cols.size()]
		c.draw_colored_polygon(PackedVector2Array([p + Vector2(-3, 0), p + Vector2(3, 0), p + Vector2(3 + sw, 8), p + Vector2(-3 + sw, 8)]), col)
		c.draw_rect(Rect2(p.x - 3, p.y, 6, 1), col.darkened(0.3))
		c.draw_rect(Rect2(p.x - 1 + sw * 0.5, p.y + 3, 2, 2), Color(col.darkened(0.35), 0.8))


static func _lantern(c: Prop, t: float) -> void:
	c.draw_rect(Rect2(-2, -48, 4, 48), WOOD)
	c.draw_rect(Rect2(-2, -48, 1, 48), WOOD_LIGHT)
	c.draw_rect(Rect2(-2, -48, 14, 2), WOOD)
	c.draw_line(Vector2(10, -46), Vector2(10, -42), Color("#3a3036"), 1.0)
	var sw := sin(t * 1.4) * 1.0
	var lc := Vector2(10 + sw, -36)
	c.draw_rect(Rect2(lc.x - 5, lc.y - 6, 10, 2), GOLD_DARK)
	c.draw_rect(Rect2(lc.x - 4, lc.y - 4, 8, 9), Color(1.0, 0.82, 0.45, 0.85 + 0.15 * sin(t * 7.0)))
	c.draw_rect(Rect2(lc.x - 4, lc.y - 4, 1, 9), GOLD_DARK)
	c.draw_rect(Rect2(lc.x + 3, lc.y - 4, 1, 9), GOLD_DARK)
	c.draw_rect(Rect2(lc.x - 5, lc.y + 5, 10, 2), GOLD_DARK)
	c.draw_rect(Rect2(lc.x - 5, lc.y - 7, 10, 1), SNOW)
	c.draw_rect(Rect2(-3, -49, 16, 1), SNOW)
	_flame(c, lc + Vector2(0, 3), 4.0, t, 1.0)


static func _pine(c: Prop, h_t: float) -> void:
	var H := h_t * 16.0
	_pine_tree(c, H)


static func _pine_tree(c: CanvasItem, H: float) -> void:
	c.draw_rect(Rect2(-3, -H * 0.3, 6, H * 0.3), WOOD_DARK)
	var green := Color("#1e2a34")
	for j in 4:
		var w := H * (0.32 - j * 0.065)
		var yy := -H * 0.22 - j * H * 0.19
		c.draw_colored_polygon(PackedVector2Array([Vector2(-w, yy), Vector2(0, yy - H * 0.3), Vector2(w, yy)]), green.lightened(0.03 * j))
		c.draw_colored_polygon(PackedVector2Array([Vector2(-w * 0.6, yy - H * 0.11), Vector2(0, yy - H * 0.3), Vector2(w * 0.3, yy - H * 0.14), Vector2(-w * 0.1, yy - H * 0.1)]), SNOW)
		c.draw_rect(Rect2(-w, yy - 2, w * 0.7, 2), SNOW)


static func _shrine(c: Prop, t: float) -> void:
	c.draw_rect(Rect2(-2, -14, 4, 14), STONE)
	c.draw_rect(Rect2(-9, -34, 18, 20), STONE)
	c.draw_rect(Rect2(-9, -34, 18, 1), STONE_LIGHT)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-12, -34), Vector2(0, -42), Vector2(12, -34)]), STONE.darkened(0.1))
	c.draw_line(Vector2(-12, -34), Vector2(0, -42), SNOW, 2.0)
	c.draw_line(Vector2(0, -42), Vector2(12, -34), SNOW, 2.0)
	# 아치 감실 + 해 성상 + 촛불
	var pts := PackedVector2Array()
	for i in 9:
		var a := PI + PI * float(i) / 8.0
		pts.append(Vector2(cos(a) * 5.0, -26 + sin(a) * 5.0))
	pts.append(Vector2(5, -16))
	pts.append(Vector2(-5, -16))
	c.draw_colored_polygon(pts, Color("#141220"))
	c.draw_circle(Vector2(0, -26), 2.5, GOLD)
	for i in 8:
		var a := TAU * i / 8.0
		c.draw_line(Vector2(0, -26) + Vector2(cos(a), sin(a)) * 3.0, Vector2(0, -26) + Vector2(cos(a), sin(a)) * 4.5, GOLD, 1.0)
	_candle(c, 0.0, -16.0, 3.0, t, 0.5)
	c.draw_line(Vector2(9, -32), Vector2(13, -22), Color("#c84050"), 1.0)


## 대신전 황금 정문: 원점 = 문턱 가운데. 가운데 아래의 작은 쪽문은 방의 door 개체가 그린다(소품은 그 뒤 z=-3).
static func _great_gate(c: Prop, t: float, w_t: float, h_t: float) -> void:
	var W := w_t * 16.0
	var Ht := h_t * 16.0
	var pw := 14.0
	var inner := W - pw * 2.0
	var spring := -Ht + inner * 0.5 # 아치가 시작되는 높이
	var flag := String(c.params.get("open_if", ""))
	var opened := flag != "" and GameState.has_flag(flag)
	# 문 안쪽 (어둠 또는 따뜻한 빛)
	var recess := PackedVector2Array()
	recess.append(Vector2(-inner * 0.5, 0))
	for i in 17:
		var a := PI + PI * float(i) / 16.0
		recess.append(Vector2(cos(a) * inner * 0.5, spring + sin(a) * inner * 0.5))
	recess.append(Vector2(inner * 0.5, 0))
	c.draw_colored_polygon(recess, Color("#140e1e") if not opened else Color("#6a4a2a"))
	if opened:
		for i in 6:
			var k := float(i) / 5.0
			c.draw_rect(Rect2(-inner * 0.5 * (1.0 - k * 0.5), spring + 10 + k * (-spring - 20), inner * (1.0 - k * 0.5), 8),
				Color(1.0, 0.85, 0.55, 0.06 + 0.02 * sin(t * 1.5 + i)))
		# 안으로 열린 문짝 (양옆으로 얇게)
		for sd: float in [-1.0, 1.0]:
			var x0 := sd * inner * 0.5
			c.draw_colored_polygon(PackedVector2Array([Vector2(x0, 0), Vector2(x0, spring), Vector2(x0 - sd * 14.0, spring + 14.0), Vector2(x0 - sd * 14.0, -4.0)]), GOLD_DARK)
			c.draw_line(Vector2(x0 - sd * 14.0, spring + 14.0), Vector2(x0 - sd * 14.0, -4.0), GOLD, 1.0)
	else:
		# 닫힌 금 문짝 둘: 세로 판·징·가운데 해 문양 반쪽씩
		for sd: float in [-1.0, 1.0]:
			var x0 := 0.0 if sd > 0.0 else -inner * 0.5
			c.draw_rect(Rect2(x0 + 1.0, spring - inner * 0.35, inner * 0.5 - 2.0, -spring + inner * 0.35), GOLD_DARK)
			var px := x0 + 5.0
			while px < x0 + inner * 0.5 - 4.0:
				c.draw_rect(Rect2(px, spring - inner * 0.3, 2, -spring + inner * 0.3 - 2.0), GOLD.darkened(0.25))
				px += 9.0
			var sy := spring - inner * 0.2
			while sy < -6.0:
				c.draw_circle(Vector2(x0 + 4.0, sy), 1.2, GOLD_LIGHT)
				c.draw_circle(Vector2(x0 + inner * 0.5 - 4.0, sy), 1.2, GOLD_LIGHT)
				sy += 14.0
		c.draw_line(Vector2(0, spring - inner * 0.35), Vector2(0, 0), Color("#3a2a14"), 2.0)
		var em := Vector2(0, spring + 18.0)
		c.draw_circle(em, 14.0, GOLD)
		c.draw_circle(em, 10.0, GOLD_LIGHT.lerp(GOLD, 0.5 + 0.5 * sin(t * 1.2)))
		c.draw_line(em + Vector2(0, -14), em + Vector2(0, 14), Color("#3a2a14"), 2.0)
	# 대리석 기둥 둘 + 금 머리
	for sd: float in [-1.0, 1.0]:
		var px2 := sd * (W * 0.5 - pw * 0.5)
		c.draw_rect(Rect2(px2 - pw * 0.5, -Ht + 6.0, pw, Ht - 6.0), MARBLE)
		c.draw_rect(Rect2(px2 - pw * 0.5, -Ht + 6.0, 3, Ht - 6.0), MARBLE_LIGHT)
		c.draw_rect(Rect2(px2 + pw * 0.5 - 3.0, -Ht + 6.0, 3, Ht - 6.0), MARBLE_DARK)
		c.draw_rect(Rect2(px2 - pw * 0.5 - 2.0, spring - 6.0, pw + 4.0, 6), GOLD)
		c.draw_rect(Rect2(px2 - pw * 0.5 - 2.0, -6.0, pw + 4.0, 6), GOLD_DARK)
	# 금 아치 띠 + 쐐기돌의 해
	c.draw_arc(Vector2(0, spring), inner * 0.5 + 3.0, PI, TAU, 24, GOLD, 5.0)
	c.draw_arc(Vector2(0, spring), inner * 0.5 + 7.0, PI, TAU, 24, GOLD_DARK, 2.0)
	c.draw_rect(Rect2(-W * 0.5 - 4.0, -Ht, W + 8.0, 7), MARBLE_LIGHT)
	c.draw_rect(Rect2(-W * 0.5 - 4.0, -Ht + 7.0, W + 8.0, 2), GOLD)
	ART.sun(c, Vector2(0, -Ht + 4.0), 7.0, t, GOLD_LIGHT, Color(1.0, 0.85, 0.5), 0.3)
