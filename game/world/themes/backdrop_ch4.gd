extends RefCounted
## 4장 지역 배경 (RoomBackdrop가 부름) — docs/archive/sera/chapter4.md 7.1절.
## INARI풍: 어두운 저채도 실루엣 + 금빛 강조 하나, 화면을 압도하는 거대 구조물(루멘 석상·황금 돔·거대한 종·첨탑).
##   holymount   새벽의 설산: 먼 성산 꼭대기의 희미한 신전 빛(깜빡임 = 루멘의 침묵), 기도 깃발, 순례자 등불, 내리는 눈
##   temple_out  구름바다 위 황혼: 거대한 해(빛살이 천천히 돎), 황금 돔·종탑·첨탑, 얼굴 없는 루멘 석상, 흔들리는 큰 종
##   temple      대신전 안: 거대한 아치 창 너머 구름바다, 장미창, 비스듬한 빛줄기, 매달린 종·긴 깃발
##   temple_dark 기록실·지하: 끝없는 두루마리 서가, 촛불(일렁임), 기도하는 성인상, 무덤 감실
##   spire       밤의 첨탑: 달, 별, 오를수록 아래로 가라앉는 구름바다, 종틀·비계·톱니 승강기, 아래 심연의 금빛
##   spire_top   꼭대기: 거대한 달, 소용돌이 구름, 종루 아치와 거대한 종, 떠 있는 대리석 조각

const ART := preload("res://world/entities/ch4/art.gd")
##   icecave     얼음 동굴: 푸른 얼음 결정 무리, 얼어붙은 폭포, 고드름 커튼, 바위 틈으로 새는 옅은 빛
const THEMES := ["holymount", "temple_out", "temple", "temple_dark", "spire", "spire_top", "icecave"]
const ICE := Color("#9ad0ff")

const GOLD := Color("#ffe08a")
const GOLD_DIM := Color("#b08a48")
const GOLD_DEEP := Color("#6a4e2a")
const MARBLE := Color("#d8d2e4")
const Kit := preload("res://world/themes/backdrop_kit.gd")


## 움직이는 층(예전 is_animated): 모든 테마의 중간 층 + spire_top 가까운 층. 그 밖의 층에서 t는 0으로 멈춘 그림.
## 그리기 계약(l = Pen, 움직이는 것만 l.anim)은 backdrop_kit.gd 머리말
static func has_theme(theme: String) -> bool:
	return theme in THEMES


static func has_sky(theme: String) -> bool:
	return theme in THEMES


# ═══════════════════════════════════════════════════════════
# 공용 도우미
# ═══════════════════════════════════════════════════════════

static func _stars(c, n: int, seed: int, t: float, area: Rect2, alpha := 0.7) -> void:
	for i in n:
		var p := area.position + Vector2(ART.hf(i, seed) * area.size.x, ART.hf(i, seed + 1) * area.size.y)
		var fade := 1.0 - (p.y - area.position.y) / maxf(area.size.y, 1.0) * 0.7
		var tw := 0.45 + 0.55 * absf(sin(t * (0.4 + ART.hf(i, seed + 2) * 1.6) + i))
		var s := 2.0 if i % 11 == 0 else 1.0
		c.draw_rect(Rect2(p, Vector2(s, s)), Color(1.0, 0.97, 0.88, alpha * tw * fade))
		if i % 23 == 0:
			c.draw_rect(Rect2(p + Vector2(-1, 0.5), Vector2(4, 1)), Color(1.0, 0.95, 0.8, 0.25 * tw))
			c.draw_rect(Rect2(p + Vector2(0.5, -1), Vector2(1, 4)), Color(1.0, 0.95, 0.8, 0.25 * tw))


## 구름 띠: 둥근 덩어리들이 speed px/s로 흘러간다. 위쪽이 빛을 받는다
static func _cloud_band(c, y: float, t: float, speed: float, seed: int, lit: Color, shade: Color, body: Color, size: float, w := 640.0) -> void:
	c.draw_rect(Rect2(0, y + size * 0.35, w, 600.0), body)
	var sp := size * 1.1
	var shift := fmod(t * speed, sp)
	var base := int(floor(t * speed / sp))
	var n := int(w / sp) + 4
	for k in n:
		var j := k - base
		var x := (k - 2) * sp + shift
		var rr := size * (0.65 + 0.55 * ART.hf(j, seed))
		var yy := y + (ART.hf(j, seed + 3) - 0.5) * size * 0.5
		c.draw_circle(Vector2(x, yy), rr, shade)
	for k in n:
		var j := k - base
		var x := (k - 2) * sp + shift
		var rr := size * (0.65 + 0.55 * ART.hf(j, seed))
		var yy := y + (ART.hf(j, seed + 3) - 0.5) * size * 0.5
		c.draw_circle(Vector2(x - rr * 0.12, yy - rr * 0.22), rr * 0.8, lit)


static func _snow(c, t: float, n: int, seed: int, speed: float, size: float, alpha: float, w := 640.0, h := 360.0) -> void:
	for i in n:
		var sp := speed * (0.6 + 0.8 * ART.hf(i, seed + 1))
		var y := fmod(ART.hf(i, seed + 2) * (h + 20.0) + t * sp, h + 20.0) - 10.0
		var x := fmod(ART.hf(i, seed) * w + sin(t * 0.7 + i * 1.3) * 6.0 + t * sp * 0.35, w + 10.0) - 5.0
		c.draw_rect(Rect2(x, y, size, size), Color(0.95, 0.97, 1.0, alpha))


## 길게 늘어진 깃발 (흰 바탕 + 금 해 문양), sway로 끝이 흔들림
static func _banner(c, x: float, top: float, w: float, h: float, cloth: Color, trim: Color, sway: float) -> void:
	c.draw_rect(Rect2(x - w * 0.62, top, w * 1.24, maxf(2.0, w * 0.1)), trim.darkened(0.2))
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(x - w * 0.5, top + 2), Vector2(x + w * 0.5, top + 2), Vector2(x + w * 0.5 + sway, top + h),
		Vector2(x + sway, top + h - w * 0.45), Vector2(x - w * 0.5 + sway, top + h),
	]), cloth)
	c.draw_line(Vector2(x - w * 0.36, top + 4), Vector2(x - w * 0.36 + sway * 0.8, top + h - w * 0.3), Color(trim, 0.6), 1.0)
	c.draw_line(Vector2(x + w * 0.36, top + 4), Vector2(x + w * 0.36 + sway * 0.8, top + h - w * 0.3), Color(trim, 0.6), 1.0)
	var sc := Vector2(x + sway * 0.3, top + h * 0.3)
	c.draw_circle(sc, w * 0.2, trim)
	c.draw_circle(sc, w * 0.12, cloth)
	for i in 8:
		var a := TAU * i / 8.0
		c.draw_line(sc + Vector2(cos(a), sin(a)) * w * 0.22, sc + Vector2(cos(a), sin(a)) * w * 0.32, trim, 1.0)


## 비스듬한 빛줄기 (반투명 사다리꼴)
static func _shaft(c, top: Vector2, w_top: float, w_bot: float, length: float, slope: float, col: Color) -> void:
	var bot := top + Vector2(slope * length, length)
	c.draw_colored_polygon(PackedVector2Array([
		top + Vector2(-w_top * 0.5, 0), top + Vector2(w_top * 0.5, 0), bot + Vector2(w_bot * 0.5, 0), bot + Vector2(-w_bot * 0.5, 0),
	]), col)


## 비계: 가로·세로 들보와 X자 버팀대
static func _scaffold(c, x0: float, x1: float, y0: float, y1: float, col: Color, lit: Color, cell := 40.0) -> void:
	var x := x0
	while x <= x1 + 0.1:
		c.draw_rect(Rect2(x - 2, y0, 4, y1 - y0), col)
		c.draw_rect(Rect2(x - 2, y0, 1, y1 - y0), lit)
		x += cell
	var y := y0
	while y <= y1 + 0.1:
		c.draw_rect(Rect2(x0 - 4, y - 2, x1 - x0 + 8, 4), col)
		c.draw_rect(Rect2(x0 - 4, y - 2, x1 - x0 + 8, 1), lit)
		y += cell
	var yy := y0
	while yy + cell <= y1 + 0.1:
		var xx := x0
		while xx + cell <= x1 + 0.1:
			c.draw_line(Vector2(xx, yy), Vector2(xx + cell, yy + cell), col, 2.0)
			c.draw_line(Vector2(xx + cell, yy), Vector2(xx, yy + cell), col, 2.0)
			xx += cell
		yy += cell


## 기도 깃발 줄: a → b로 처진 줄에 작은 삼각 깃발들이 흔들림
static func _prayer_flags(c, a: Vector2, b: Vector2, sag: float, t: float, alpha: float, seed: int, size := 6.0) -> void:
	var cols: Array[Color] = [Color("#e8ecf4"), Color("#e8c060"), Color("#6a9ad8"), Color("#d87a7a"), Color("#7ab88a")]
	var n := maxi(int(a.distance_to(b) / (size * 1.6)), 2)
	var prev := a
	for i in n + 1:
		var k := float(i) / n
		var p := a.lerp(b, k) + Vector2(0, sin(k * PI) * sag)
		if i > 0:
			c.draw_line(prev, p, Color(0.15, 0.13, 0.2, alpha), 1.0)
		prev = p
		if i == 0 or i == n:
			continue
		var sw := sin(t * 2.2 + i * 0.9 + seed) * size * 0.35
		var col: Color = cols[(i + seed) % cols.size()]
		c.draw_colored_polygon(PackedVector2Array([p + Vector2(-size * 0.45, 0), p + Vector2(size * 0.45, 0), p + Vector2(sw, size * 1.1)]), Color(col, alpha))


## 눈 덮인 산맥: 바닥 y에서 봉우리들, 꼭대기에 눈
static func _range(c, rng: RandomNumberGenerator, x0: float, x1: float, base_y: float, hmin: float, hmax: float, col: Color, snow: Color, bottom: float) -> void:
	var x := x0
	while x < x1:
		var w := rng.randf_range(hmin * 1.2, hmax * 1.6)
		var h := rng.randf_range(hmin, hmax)
		var peak := Vector2(x + w * rng.randf_range(0.35, 0.65), base_y - h)
		c.draw_colored_polygon(PackedVector2Array([Vector2(x - w * 0.2, bottom), Vector2(x, base_y), peak, Vector2(x + w, base_y), Vector2(x + w * 1.2, bottom)]), col)
		# 눈 모자 (봉우리 아래 30%)
		var k := 0.3
		var l := peak.lerp(Vector2(x, base_y), k)
		var r := peak.lerp(Vector2(x + w, base_y), k)
		c.draw_colored_polygon(PackedVector2Array([peak, r, r.lerp(l, 0.35) + Vector2(0, h * 0.06), r.lerp(l, 0.65) - Vector2(0, h * 0.02), l]), snow)
		x += w * rng.randf_range(0.55, 0.85)


static func _pine(c, x: float, base_y: float, h: float, col: Color, snow: Color) -> void:
	c.draw_rect(Rect2(x - h * 0.03, base_y - h * 0.25, h * 0.06, h * 0.25), col)
	for j in 4:
		var w := h * (0.34 - j * 0.07)
		var yy := base_y - h * 0.18 - j * h * 0.2
		c.draw_colored_polygon(PackedVector2Array([Vector2(x - w, yy), Vector2(x, yy - h * 0.3), Vector2(x + w, yy)]), col)
		c.draw_colored_polygon(PackedVector2Array([Vector2(x - w * 0.55, yy - h * 0.12), Vector2(x, yy - h * 0.3), Vector2(x + w * 0.35, yy - h * 0.15)]), snow)


static func _cairn(c, x: float, base_y: float, s: float, col: Color, snow: Color) -> void:
	var y := base_y
	for i in 5:
		var w := s * (1.0 - i * 0.16)
		var hh := s * 0.32
		c.draw_rect(Rect2(x - w * 0.5 + (i % 2) * s * 0.06, y - hh, w, hh), col.lightened(0.03 * i))
		y -= hh
	c.draw_rect(Rect2(x - s * 0.22, y - 1, s * 0.44, 2), snow)


# ═══════════════════════════════════════════════════════════
# 하늘 (화면 고정 640×360)
# ═══════════════════════════════════════════════════════════

static func draw_sky(c, theme: String, _pal: Dictionary, _t: float) -> void:
	match theme:
		"holymount": _sky_mount(c)
		"temple_out": _sky_gold(c, false)
		"temple": _sky_gold(c, true)
		"temple_dark": _sky_dark(c)
		"spire": _sky_spire(c)
		"spire_top": _sky_top(c)
		"icecave": _sky_ice(c)


## 방 안 카메라 높이 비율 (0 = 맨 아래, 1 = 맨 위). 세로로 긴 첨탑에서 하늘이 오를수록 바뀌게.
## w = 하늘을 기록할 때 잡아 둔 World (틱마다 그룹 검색을 하지 않게). 없으면 그때 찾는다
static func _climb_k(w: World) -> float:
	if w == null or not is_instance_valid(w):
		w = World.get_world()
	if w == null or w.room == null or w.player == null:
		return 0.0
	var h := w.room.size_px.y
	if h <= 400.0:
		return 0.5
	var y := w.player.global_position.y
	return clampf(1.0 - (y - 180.0) / maxf(h - 360.0, 1.0), 0.0, 1.0)


static func _sky_mount(c) -> void:
	Kit.grad_even(c, [Color("#0a0e28"), Color("#1a2150"), Color("#3a3c76"), Color("#7a6a9e"), Color("#d49aa0"), Color("#f2c49c")], 0, 360, 640)
	c.anim(Rect2(-4, -4, 648, 180), func(cv: CanvasItem, t: float) -> void: _stars(cv, 70, 401, t, Rect2(0, 0, 640, 170), 0.8))
	# 먼 산맥 (옅은 청보라)
	var far := Color("#5a5a92")
	var snow := Color("#b8b4dc")
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	_range(c, rng, -40, 640, 268, 40, 90, far, snow, 380)
	# 성산: 오른쪽에 높이 솟은 봉우리, 꼭대기에 희미한 신전의 빛 (깜빡이며 약해짐 — 루멘의 침묵)
	var peak := Vector2(476, 86)
	var mtn := Color("#46467e")
	c.draw_colored_polygon(PackedVector2Array([Vector2(300, 380), Vector2(372, 200), Vector2(430, 140), peak, Vector2(520, 130), Vector2(596, 214), Vector2(680, 380)]), mtn)
	c.draw_colored_polygon(PackedVector2Array([peak, Vector2(520, 130), Vector2(546, 162), Vector2(510, 152), Vector2(492, 176), Vector2(462, 150), Vector2(430, 140)]), Color("#c8c4e8"))
	c.draw_line(peak, Vector2(596, 214), Color(1.0, 0.85, 0.75, 0.35), 1.0)
	# 깜빡임 _flick(t) (루멘의 침묵)
	c.anim(Kit.bb_circle(peak + Vector2(0, -6), 26.0), func(cv: CanvasItem, t: float) -> void:
		var flick := _flick(t)
		for i in 5:
			cv.draw_circle(peak + Vector2(0, -6), 26.0 - i * 4.5, Color(1.0, 0.85, 0.5, (0.03 + i * 0.03) * flick)))
	# 신전 실루엣 (작은 돔·첨탑)
	var tc := Color("#2e2a52")
	c.draw_rect(Rect2(peak.x - 14, peak.y - 8, 28, 8), tc)
	c.draw_circle(Vector2(peak.x - 6, peak.y - 8), 5, tc)
	c.draw_circle(Vector2(peak.x + 7, peak.y - 7), 4, tc)
	c.draw_rect(Rect2(peak.x - 1, peak.y - 26, 2, 18), tc)
	c.anim(Rect2(peak.x - 4, 0, 8, peak.y - 3), func(cv: CanvasItem, t: float) -> void:
		var flick := _flick(t)
		cv.draw_rect(Rect2(peak.x - 4, peak.y - 5, 8, 2), Color(1.0, 0.85, 0.5, 0.8 * flick))
		# 꺼질 듯한 빛기둥
		cv.draw_rect(Rect2(peak.x - 2, 0, 4, peak.y - 26), Color(1.0, 0.9, 0.6, 0.06 * flick))
		cv.draw_rect(Rect2(peak.x - 0.5, 0, 1, peak.y - 26), Color(1.0, 0.95, 0.75, 0.12 * flick)))
	# 아래 구름 띠 + 눈 (두 겹)
	c.anim(Kit.ALL, func(cv: CanvasItem, t: float) -> void:
		_cloud_band(cv, 300, t, 3.0, 11, Color("#e8b8b8"), Color("#9a86ac"), Color("#7e6c98"), 18)
		_cloud_band(cv, 330, t, 6.0, 12, Color("#c8a0b0"), Color("#6a5a88"), Color("#5a4c78"), 24)
		_snow(cv, t, 70, 71, 18.0, 1.0, 0.55)
		_snow(cv, t, 26, 72, 30.0, 2.0, 0.7))


static func _flick(t: float) -> float:
	return 0.55 + 0.45 * (0.5 + 0.5 * sin(t * 1.7)) * (0.6 + 0.4 * sin(t * 0.37 + 1.0))


## 황금빛 하늘 + 구름바다 (대신전 바깥·안 창 너머)
static func _sky_gold(c, interior: bool) -> void:
	Kit.grad_even(c, [Color("#141838"), Color("#2c2a5a"), Color("#66487c"), Color("#c06e80"), Color("#eea072"), Color("#ffd690")], 0, 360, 640)
	c.anim(Rect2(-4, -4, 648, 100), func(cv: CanvasItem, t: float) -> void: _stars(cv, 30, 403, t, Rect2(0, 0, 640, 90), 0.45))
	# 높은 새털구름
	c.anim(Kit.ALL, func(cv: CanvasItem, t: float) -> void:
		for i in 7:
			var y := 70.0 + i * 22.0 + ART.hf(i, 5) * 10.0
			var x := fmod(ART.hf(i, 6) * 900.0 + t * (2.0 + i * 0.5), 900.0) - 160.0
			var w := 120.0 + ART.hf(i, 7) * 160.0
			cv.draw_rect(Rect2(x, y, w, 2), Color(1.0, 0.8, 0.75, 0.12))
			cv.draw_rect(Rect2(x + w * 0.2, y + 3, w * 0.6, 1), Color(1.0, 0.85, 0.8, 0.08)))
	# 루멘의 해: 크고 희미하게 깜빡임 (침묵)
	c.anim(Kit.bb_circle(Vector2(452, 212), 30.0 * 4.2 + 2.0), func(cv: CanvasItem, t: float) -> void: ART.sun(cv, Vector2(452, 212), 30.0, t, Color("#fff4dc"), Color("#ffd890"), 0.25))
	# 구름 위로 솟은 먼 봉우리
	var pk := Color("#7a5a8a")
	c.draw_colored_polygon(PackedVector2Array([Vector2(20, 300), Vector2(70, 238), Vector2(96, 252), Vector2(130, 222), Vector2(200, 300)]), pk)
	c.draw_colored_polygon(PackedVector2Array([Vector2(540, 300), Vector2(584, 250), Vector2(610, 262), Vector2(660, 300)]), pk)
	c.draw_line(Vector2(130, 222), Vector2(200, 300), Color(1.0, 0.8, 0.6, 0.4), 1.0)
	# 구름바다 세 겹 (금빛 윗면)
	c.anim(Kit.ALL, func(cv: CanvasItem, t: float) -> void:
		_cloud_band(cv, 268, t, 2.0, 21, Color("#ffd8a8"), Color("#d8988c"), Color("#c88884"), 14)
		_cloud_band(cv, 296, t, 4.0, 22, Color("#f8c8a0"), Color("#b87888"), Color("#a86c80"), 20)
		_cloud_band(cv, 330, t, 7.0, 23, Color("#e8b098"), Color("#8a5a78"), Color("#7a5070"), 28))
	if interior:
		# 안쪽에서 보는 창 너머: 조금 더 짙게
		c.draw_rect(Rect2(0, 0, 640, 360), Color(0.1, 0.06, 0.2, 0.12))


static func _sky_dark(c) -> void:
	Kit.grad_even(c, [Color("#03040a"), Color("#0a0c16"), Color("#121624"), Color("#0c0e18")], 0, 360, 640, 18)
	# 아주 높은 곳의 채광창에서 내려오는 옅은 빛
	c.anim(Kit.ALL, func(cv: CanvasItem, t: float) -> void:
		for i in 3:
			var x := 120.0 + i * 200.0
			_shaft(cv, Vector2(x, -10), 20, 70, 380, 0.25, Color(0.85, 0.8, 1.0, 0.025 + 0.01 * sin(t * 0.5 + i))))


static func _sky_ice(c) -> void:
	Kit.grad_even(c, [Color("#03050c"), Color("#081022"), Color("#0e1a34"), Color("#0a1226")], 0, 360, 640, 18)
	# 바위 틈으로 새는 옅은 푸른 빛 + 얼음 가루 반짝임
	c.anim(Kit.ALL, func(cv: CanvasItem, t: float) -> void:
		for i in 3:
			var x := 90.0 + i * 230.0
			_shaft(cv, Vector2(x, -10), 14, 60, 380, -0.2 + i * 0.15, Color(0.6, 0.85, 1.0, 0.03 + 0.012 * sin(t * 0.6 + i)))
		for i in 40:
			var p := Vector2(ART.hf(i, 61) * 640.0, ART.hf(i, 62) * 340.0)
			var tw := absf(sin(t * (0.6 + ART.hf(i, 63)) + i))
			cv.draw_rect(Rect2(p, Vector2(1, 1)), Color(0.75, 0.9, 1.0, 0.35 * tw)))


## 얼음 결정 무리 하나 (육각 기둥이 끝으로 뾰족)
## ART(CanvasItem 타입만 받는 도우미)를 Pen에 정적으로 기록한다. bbox는 그림 전체를 덮게
static func _art_column(l, x: float, top: float, bottom: float, w: float, body: Color, light: Color, gold: Color) -> void:
	l.fn(Rect2(x - w * 0.78, top - w * 0.42, w * 1.56, bottom - top + w * 0.42), func(cv: CanvasItem) -> void: ART.column(cv, x, top, bottom, w, body, light, gold))


static func _art_dome(l, cx: float, base_y: float, r: float, body: Color, gold: Color, window: Color) -> void:
	l.fn(Rect2(cx - r - 2.0, base_y - r * 2.5 - 2.0, r * 2.0 + 4.0, r * 2.5 + 4.0), func(cv: CanvasItem) -> void: ART.dome(cv, cx, base_y, r, body, gold, window))


static func _art_lumen_statue(l, base: Vector2, h: float, body: Color, rim: Color, gold: Color, pose := 0, rim_side := 1.0) -> void:
	l.fn(Rect2(base.x - h * 0.36, base.y - h * 1.2, h * 0.72, h * 1.2 + 2.0), func(cv: CanvasItem) -> void: ART.lumen_statue(cv, base, h, body, rim, gold, pose, rim_side))


static func _art_arch(l, x0: float, x1: float, spring_y: float, col: Color, width: float) -> void:
	var r := (x1 - x0) * 0.5
	l.fn(Rect2(x0 - width, spring_y - r - width, x1 - x0 + width * 2.0, r + width * 2.0), func(cv: CanvasItem) -> void: ART.arch(cv, x0, x1, spring_y, col, width))


static func _art_glow(l, p: Vector2, r: float, col: Color, a: float) -> void:
	l.fn(Kit.bb_circle(p, r), func(cv: CanvasItem) -> void: ART.glow(cv, p, r, col, a))


static func _art_lantern_dot(l, p: Vector2, r: float, a: float) -> void:
	l.fn(Kit.bb_circle(p, r * 3.2), func(cv: CanvasItem) -> void: ART.lantern_dot(cv, p, r, a))


static func _art_bell(l, pivot: Vector2, length: float, size: float, ang: float, metal: Color, dim: float, light := 0.0) -> void:
	l.fn(_bb_bell(pivot, length, size), func(cv: CanvasItem) -> void: ART.bell(cv, pivot, length, size, ang, metal, dim, light))


## 흔들리는 종(기울기 0.12rad 이하)의 bbox
static func _bb_bell(pivot: Vector2, length: float, size: float) -> Rect2:
	var reach := length + size * 1.1
	var half := size * 0.6 + reach * 0.12 + 2.0
	return Rect2(pivot.x - half, pivot.y - 2.0, half * 2.0, reach + 4.0)


## _banner(x, top, w, h, sway 최대)의 bbox
static func _bb_banner(x: float, top: float, w: float, h: float, sway: float) -> Rect2:
	return Rect2(x - w * 0.62 - sway - 2.0, top - 2.0, w * 1.24 + sway * 2.0 + 4.0, h + 4.0)


static func _crystal(l, base: Vector2, h: float, w: float, lean: float, body: Color, rim: Color) -> void:
	var tip := base + Vector2(lean * h, -h)
	var pts := PackedVector2Array([base + Vector2(-w * 0.5, 0), base + Vector2(-w * 0.5, -h * 0.75) + Vector2(lean * h * 0.75, 0),
		tip, base + Vector2(w * 0.5, -h * 0.75) + Vector2(lean * h * 0.75, 0), base + Vector2(w * 0.5, 0)])
	l.draw_colored_polygon(pts, body)
	l.draw_line(base + Vector2(-w * 0.5, 0), base + Vector2(-w * 0.5, -h * 0.75) + Vector2(lean * h * 0.75, 0), rim, 1.0)
	l.draw_line(base + Vector2(-w * 0.5, -h * 0.75) + Vector2(lean * h * 0.75, 0), tip, rim, 1.0)
	l.draw_line(base + Vector2(lean * h * 0.4, -h * 0.4), tip, Color(rim, rim.a * 0.6), 1.0)


static func _layer_ice(l, th: Dictionary, depth: int, span: Vector2, rng: RandomNumberGenerator, t: float) -> void:
	var col := _col(th, depth)
	match depth:
		0:
			# 동굴 안쪽 벽: 바위 결 + 큰 얼음 결정 무리 (어둡게)
			l.draw_rect(Rect2(-50, -50, span.x + 100, span.y + 100), col)
			var y := 20.0
			while y < span.y:
				var pts := PackedVector2Array()
				var x := -20.0
				while x < span.x + 40:
					pts.append(Vector2(x, y + sin(x * 0.02 + y) * 6.0))
					x += 30.0
				l.draw_polyline(pts, col.lightened(0.05), 2.0)
				y += rng.randf_range(26, 44)
			var cx := rng.randf_range(20, 120)
			while cx < span.x:
				var by := span.y - rng.randf_range(40, 120)
				for k in 4:
					var h := rng.randf_range(40, 110)
					_crystal(l, Vector2(cx + k * 14.0 - 20.0, by), h, rng.randf_range(10, 18), rng.randf_range(-0.25, 0.25),
						Color(0.35, 0.5, 0.75, 0.22), Color(0.7, 0.88, 1.0, 0.3))
				cx += rng.randf_range(160, 300)
		1:
			# 얼어붙은 폭포 + 숨 쉬듯 빛나는 결정 + 고드름 커튼
			var x := rng.randf_range(40, 200)
			var k := 0
			while x < span.x:
				if k % 2 == 0:
					var w := rng.randf_range(40, 70)
					for i in 6:
						var sx := x + i * w / 6.0
						l.draw_rect(Rect2(sx, -20, w / 6.0 - 1.0, span.y + 40), Color(0.55, 0.72, 0.95, 0.07 + 0.02 * (i % 2)))
						l.draw_rect(Rect2(sx, -20, 1, span.y + 40), Color(0.85, 0.95, 1.0, 0.12))
					var fx := x
					var sh := span.y
					l.anim(Rect2(x, 0, w, sh + 2), func(cv: CanvasItem, tt: float) -> void:
						var fy := fmod(tt * 20.0 + fx, sh)
						cv.draw_rect(Rect2(fx, fy, w, 2), Color(0.9, 0.97, 1.0, 0.08)))
				else:
					var by := span.y - rng.randf_range(30, 90)
					var hs := PackedFloat64Array()
					var ws := PackedFloat64Array()
					for j in 3:
						hs.append(rng.randf_range(30, 60))
						ws.append(rng.randf_range(8, 14))
					var gx := x
					# 빛 무리와 결정 셋이 모두 맥동(pulse)해서 한 묶음으로 움직인다
					l.anim(Rect2(x - 52, by - 82, 104, 104), func(cv: CanvasItem, tt: float) -> void:
						var pulse := 0.6 + 0.4 * sin(tt * 1.3 + gx * 0.01)
						ART.glow(cv, Vector2(gx, by - 30), 50.0, ICE, 0.18 * pulse)
						for j in 3:
							_crystal(cv, Vector2(gx + (j - 1) * 12.0, by), hs[j], ws[j], (j - 1) * 0.18,
								Color(0.45, 0.65, 0.95, 0.55), Color(0.85, 0.95, 1.0, 0.7 * pulse)))
				x += rng.randf_range(180, 320)
				k += 1
			# 고드름 커튼 (위)
			var ix := 0.0
			while ix < span.x:
				var ln := rng.randf_range(8, 34)
				l.draw_colored_polygon(PackedVector2Array([Vector2(ix, -4), Vector2(ix + 6, -4), Vector2(ix + 3, ln)]), Color(0.6, 0.78, 1.0, 0.35))
				ix += rng.randf_range(6, 22)
		2:
			# 가까운 종유석·석순 실루엣 (끝이 얼음)
			var x := rng.randf_range(30, 160)
			while x < span.x:
				var w := rng.randf_range(18, 40)
				var h := rng.randf_range(50, 140)
				if rng.randf() < 0.5:
					l.draw_colored_polygon(PackedVector2Array([Vector2(x - w * 0.5, -10), Vector2(x + w * 0.5, -10), Vector2(x, h)]), col)
					l.draw_colored_polygon(PackedVector2Array([Vector2(x - 3, h - 14), Vector2(x + 3, h - 14), Vector2(x, h)]), Color(0.7, 0.88, 1.0, 0.5))
				else:
					var by := span.y + 10
					l.draw_colored_polygon(PackedVector2Array([Vector2(x - w * 0.5, by), Vector2(x + w * 0.5, by), Vector2(x, by - h)]), col)
					l.draw_line(Vector2(x, by - h), Vector2(x - w * 0.2, by - h * 0.6), Color(0.7, 0.88, 1.0, 0.35), 1.0)
				x += rng.randf_range(120, 260)
		3:
			_front(l, "icecave", span, rng)


## 첨탑 하늘은 세라의 높이(_climb_k)에 따라 그라데이션·달·구름바다가 바뀌어 통째로 움직이는 요소
static func _sky_spire(c) -> void:
	var w := World.get_world()
	c.anim(Kit.ALL, func(cv: CanvasItem, t: float) -> void:
		var k := _climb_k(w)
		Kit.grad_even(cv, [Color("#02031a"), Color("#080a2c"), Color("#14143e"), Color("#24204e").lerp(Color("#121236"), k)], 0, 360, 640, 24)
		_stars(cv, 110, 405, t, Rect2(0, 0, 640, 300), 0.9)
		# 달 (오를수록 조금 더 커 보임)
		ART.moon(cv, Vector2(116, 80 - k * 10.0), 30.0 + k * 6.0, Color("#f2ead2"))
		# 옅은 구름 자락
		for i in 5:
			var y := 120.0 + i * 30.0
			var x := fmod(ART.hf(i, 9) * 800.0 + t * (3.0 + i), 800.0) - 120.0
			cv.draw_rect(Rect2(x, y, 140 + i * 20, 3), Color(0.6, 0.6, 0.85, 0.07))
		# 오를수록 아래로 가라앉는 구름바다
		var cy := 286.0 + k * 140.0
		_cloud_band(cv, cy, t, 3.0, 31, Color("#6a6aa0"), Color("#30305a"), Color("#20204a"), 22)
		# 아래에서 차오르는 금빛 (심연의 빛)
		for i in 6:
			cv.draw_rect(Rect2(0, 360 - (i + 1) * 14, 640, 14), Color(1.0, 0.8, 0.4, (0.012 + 0.004 * sin(t * 2.0)) * (6 - i))))


static func _sky_top(c) -> void:
	Kit.grad_even(c, [Color("#02031a"), Color("#0a0a30"), Color("#1c1a4c"), Color("#34306a"), Color("#4a3a6e")], 0, 360, 640, 26)
	c.anim(Rect2(-4, -4, 648, 330), func(cv: CanvasItem, t: float) -> void: _stars(cv, 140, 407, t, Rect2(0, 0, 640, 320), 1.0))
	# 거대한 달
	c.fn(Kit.bb_circle(Vector2(470, 110), 58.0 * 2.6), func(cv: CanvasItem) -> void: ART.moon(cv, Vector2(470, 110), 58.0, Color("#f4ecd6")))
	# 금빛 띠(천천히 일렁임) · 소용돌이 구름(달 둘레) · 아래 멀리 구름바다
	c.anim(Kit.ALL, func(cv: CanvasItem, t: float) -> void:
		for j in 3:
			var pts := PackedVector2Array()
			for i in 33:
				var x := -20.0 + i * 21.0
				var y := 60.0 + j * 34.0 + sin(x * 0.012 + t * 0.3 + j) * 18.0 + sin(x * 0.03 + j * 2.0) * 6.0
				pts.append(Vector2(x, y))
			cv.draw_polyline(pts, Color(1.0, 0.85, 0.5, 0.07), 6.0 - j)
			cv.draw_polyline(pts, Color(1.0, 0.92, 0.7, 0.1), 1.0)
		for i in 4:
			var r := 90.0 + i * 26.0
			cv.draw_arc(Vector2(470, 110), r, -2.6 + t * 0.02 * (i + 1), -0.6 + t * 0.02 * (i + 1), 24, Color(0.7, 0.68, 0.95, 0.05), 8.0 - i)
		_cloud_band(cv, 300, t, 2.5, 41, Color("#8a84c0"), Color("#3e3a6e"), Color("#2c2a5a"), 18)
		_cloud_band(cv, 330, t, 5.0, 42, Color("#6c66a8"), Color("#2a2852"), Color("#1e1c44"), 26))


# ═══════════════════════════════════════════════════════════
# 시차 층
# ═══════════════════════════════════════════════════════════

static func draw_layer(l, theme: String, depth: int, span: Vector2, rng: RandomNumberGenerator, t: float) -> bool:
	if not (theme in THEMES):
		return false
	var th: Dictionary = l.theme
	match theme:
		"holymount": _layer_mount(l, th, depth, span, rng, t)
		"temple_out": _layer_temple_out(l, th, depth, span, rng, t)
		"temple": _layer_temple(l, th, depth, span, rng, t)
		"temple_dark": _layer_dark(l, th, depth, span, rng, t)
		"spire": _layer_spire(l, th, depth, span, rng, t)
		"spire_top": _layer_top(l, th, depth, span, rng, t)
		"icecave": _layer_ice(l, th, depth, span, rng, t)
	return true


static func _col(th: Dictionary, depth: int) -> Color:
	var key := "far" if depth == 0 else ("mid" if depth == 1 else "near")
	var v: Variant = th.get(key, Color(0.1, 0.1, 0.15))
	return v as Color


## 전경: 화면 아래를 스치는 검은 덩어리 (테마별 모양)
static func _front(l, theme: String, span: Vector2, rng: RandomNumberGenerator) -> void:
	var dark := Color(0.015, 0.012, 0.03, 0.93)
	var x := rng.randf_range(0, 260)
	while x < span.x:
		var w := rng.randf_range(70, 170)
		var h := rng.randf_range(18, 44)
		var bottom := span.y + 30
		match theme:
			"holymount", "icecave":
				l.draw_circle(Vector2(x + w * 0.3, bottom - h * 0.3), h, dark)
				l.draw_circle(Vector2(x + w * 0.7, bottom - h * 0.1), h * 0.8, dark)
				l.draw_rect(Rect2(x + w * 0.3 - h * 0.6, bottom - h * 1.3, h * 1.2, 3), Color(0.75, 0.78, 0.9, 0.5))
			"temple", "temple_out", "spire_top":
				# 난간 기둥 줄
				l.draw_rect(Rect2(x, bottom - h, w, h + 10), dark)
				var bx := x + 6.0
				while bx < x + w - 6.0:
					l.draw_rect(Rect2(bx, bottom - h - 16, 6, 16), dark)
					l.draw_circle(Vector2(bx + 3, bottom - h - 10), 4.0, dark)
					bx += 12.0
				l.draw_rect(Rect2(x - 4, bottom - h - 20, w + 8, 5), dark)
			"spire":
				# 가로지르는 들보
				l.draw_colored_polygon(PackedVector2Array([Vector2(x, bottom), Vector2(x + w * 0.4, bottom - h * 2.2), Vector2(x + w * 0.4 + 10, bottom - h * 2.2), Vector2(x + 10, bottom)]), dark)
				l.draw_rect(Rect2(x - 20, bottom - h, w + 40, 10), dark)
			_:
				l.draw_rect(Rect2(x, bottom - h, w, h + 10), dark)
				l.draw_rect(Rect2(x + 8, bottom - h - 10, w - 16, 10), dark)
		x += w + rng.randf_range(280, 560)
	# 얼음 동굴: 위쪽 가장자리의 검은 고드름
	if theme == "icecave":
		var ix := rng.randf_range(0, 60)
		while ix < span.x:
			var ln := rng.randf_range(20, 70)
			l.draw_colored_polygon(PackedVector2Array([Vector2(ix - 8, -20), Vector2(ix + 8, -20), Vector2(ix, ln)]), dark)
			ix += rng.randf_range(40, 160)
	# 위쪽 가장자리: 늘어진 사슬·향로
	if theme in ["temple", "temple_dark", "spire"]:
		var cx := rng.randf_range(80, 360)
		while cx < span.x:
			var ln := rng.randf_range(30, 100)
			var y := -20.0
			while y < ln:
				l.draw_rect(Rect2(cx - 3, y, 6, 7), dark)
				y += 8.0
			if theme != "spire":
				l.draw_colored_polygon(PackedVector2Array([Vector2(cx - 9, ln), Vector2(cx + 9, ln), Vector2(cx + 5, ln + 12), Vector2(cx - 5, ln + 12)]), dark)
			cx += rng.randf_range(380, 720)


# ─── 성산 순례길 ───────────────────────────────────────

static func _layer_mount(l, th: Dictionary, depth: int, span: Vector2, rng: RandomNumberGenerator, t: float) -> void:
	if depth == 3:
		_front(l, "holymount", span, rng)
		return
	var col := _col(th, depth)
	match depth:
		0:
			var snow := col.lerp(Color("#c8cce8"), 0.45)
			# 1칸 높이 방에서 바닥(약 304px) 위로 보이게 아래 기준으로 놓는다
			_range(l, rng, -100, span.x + 100, span.y - 150, 50, 120, col, snow, span.y + 60)
			# 먼 능선의 순례자 등불 행렬 (아주 작게)
			for i in 14:
				var x := rng.randf_range(0, span.x)
				var y := span.y - 150 + rng.randf_range(-40, 0)
				l.draw_rect(Rect2(x, y, 1, 1), Color(1.0, 0.85, 0.5, 0.6))
		1:
			var snow := col.lerp(Color("#d8dcf0"), 0.55)
			var base_y := span.y - 172
			var pts := PackedVector2Array([Vector2(-100, span.y + 60)])
			var x := -100.0
			var heights: Array[Vector2] = []
			while x < span.x + 120:
				var h := rng.randf_range(30, 80)
				pts.append(Vector2(x, base_y - h))
				heights.append(Vector2(x, base_y - h))
				x += rng.randf_range(80, 160)
			pts.append(Vector2(span.x + 120, span.y + 60))
			l.draw_colored_polygon(pts, col)
			# 능선을 따라 쌓인 눈
			for i in heights.size() - 1:
				var a := heights[i]
				var b := heights[i + 1]
				l.draw_line(a, b, snow, 3.0)
			# 눈 덮인 소나무
			for i in int(span.x / 90.0) + 2:
				var tx := i * 90.0 + rng.randf_range(-30, 30)
				_pine(l, tx, base_y + rng.randf_range(-20, 20), rng.randf_range(50, 80), col.darkened(0.15), snow)
			# 기도 깃발 줄 + 장대 + 등불 (깃발이 바람에 흔들림)
			var px := rng.randf_range(40, 160)
			while px < span.x:
				var gy := base_y - rng.randf_range(10, 40)
				var p2 := px + rng.randf_range(140, 220)
				var gy2 := base_y - rng.randf_range(10, 40)
				l.draw_rect(Rect2(px - 1, gy - 46, 2, 46), col.darkened(0.3))
				l.draw_rect(Rect2(p2 - 1, gy2 - 46, 2, 46), col.darkened(0.3))
				var fa := Vector2(px, gy - 44)
				var fb := Vector2(p2, gy2 - 44)
				var fseed := int(px) % 7
				l.anim(Rect2(fa, Vector2.ZERO).expand(fb).grow_individual(4, 4, 4, 24), func(cv: CanvasItem, tt: float) -> void: _prayer_flags(cv, fa, fb, 14.0, tt, 0.55, fseed, 5.0))
				var dp := Vector2(px, gy - 50)
				var dph := px
				l.anim(Kit.bb_circle(dp, 1.5 * 3.2), func(cv: CanvasItem, tt: float) -> void: ART.lantern_dot(cv, dp, 1.5, 0.7 + 0.3 * sin(tt * 3.0 + dph)))
				px = p2 + rng.randf_range(80, 200)
		2:
			var snow := Color("#cdd2e6")
			var base_y := span.y - 176
			# 큰 바위
			for i in int(span.x / 260.0) + 2:
				var bx := i * 260.0 + rng.randf_range(-60, 60)
				var bw := rng.randf_range(60, 120)
				var bh := rng.randf_range(40, 90)
				l.draw_colored_polygon(PackedVector2Array([Vector2(bx - bw * 0.6, span.y + 40), Vector2(bx - bw * 0.4, base_y - bh * 0.6), Vector2(bx - bw * 0.1, base_y - bh), Vector2(bx + bw * 0.35, base_y - bh * 0.8), Vector2(bx + bw * 0.6, span.y + 40)]), col)
				l.draw_colored_polygon(PackedVector2Array([Vector2(bx - bw * 0.42, base_y - bh * 0.58), Vector2(bx - bw * 0.1, base_y - bh), Vector2(bx + bw * 0.35, base_y - bh * 0.8), Vector2(bx + bw * 0.1, base_y - bh * 0.78), Vector2(bx - bw * 0.15, base_y - bh * 0.86)]), Color(snow, 0.55))
			# 순례자의 돌무지
			for i in int(span.x / 300.0) + 1:
				_cairn(l, i * 300.0 + rng.randf_range(80, 220), base_y - 4, rng.randf_range(16, 24), col.lightened(0.05), snow)
			for i in int(span.x / 200.0) + 1:
				_pine(l, i * 200.0 + rng.randf_range(0, 120), base_y + 8, rng.randf_range(90, 130), col.darkened(0.1), Color(snow, 0.6))


# ─── 대신전 바깥 (정문·회랑 정원) ──────────────────────

static func _layer_temple_out(l, th: Dictionary, depth: int, span: Vector2, rng: RandomNumberGenerator, t: float) -> void:
	if depth == 3:
		_front(l, "temple_out", span, rng)
		return
	var col := _col(th, depth)
	match depth:
		0:
			# 신전 전경: 가운데 첨탑, 양옆 황금 돔·종탑, 돔 사이 거대한 루멘 석상
			var base := span.y - 168
			var gold := Color("#a07840").lerp(col, 0.25)
			var win := Color(1.0, 0.82, 0.5, 0.6)
			l.draw_rect(Rect2(-50, base, span.x + 100, span.y), col)
			var cx := span.x * 0.5
			# 첨탑 (추격의 무대 — 가장 높음)
			l.draw_colored_polygon(PackedVector2Array([Vector2(cx - 34, base), Vector2(cx - 22, base - span.y * 0.55), Vector2(cx - 8, base - span.y * 0.72), Vector2(cx, base - span.y * 0.9), Vector2(cx + 8, base - span.y * 0.72), Vector2(cx + 22, base - span.y * 0.55), Vector2(cx + 34, base)]), col)
			for i in 8:
				var wy := base - span.y * (0.08 + i * 0.075)
				l.draw_rect(Rect2(cx - 3, wy, 6, 8), win)
			l.draw_line(Vector2(cx + 22, base - span.y * 0.55), Vector2(cx + 34, base), Color(1.0, 0.8, 0.55, 0.35), 1.0)
			l.draw_circle(Vector2(cx, base - span.y * 0.9), 3.0, Color(1.0, 0.9, 0.6, 0.9))
			# 돔과 종탑
			for i in 4:
				var dx: float = [-0.32, -0.16, 0.16, 0.32][i]
				var r := span.y * (0.09 if i % 3 == 0 else 0.12)
				_art_dome(l, cx + dx * span.x * 0.9, base, r, col.lightened(0.03), gold, win)
			for side: float in [-1.0, 1.0]:
				var bx: float = cx + side * span.x * 0.24
				var bh := span.y * 0.42
				l.draw_rect(Rect2(bx - 14, base - bh, 28, bh), col.lightened(0.02))
				l.draw_rect(Rect2(bx - 9, base - bh + 10, 18, 22), Color(1.0, 0.8, 0.5, 0.18))
				_art_bell(l, Vector2(bx, base - bh + 10), 2, 14, 0.0, ART.BELL_METAL, 0.55)
				l.draw_colored_polygon(PackedVector2Array([Vector2(bx - 18, base - bh), Vector2(bx, base - bh - 34), Vector2(bx + 18, base - bh)]), gold.darkened(0.15))
			# 거대한 루멘 석상 둘 (신전 양옆)
			_art_lumen_statue(l, Vector2(span.x * 0.1, base + 4), span.y * 0.62, col.lightened(0.05), Color("#ffd8a0"), gold, 1, 1.0)
			_art_lumen_statue(l, Vector2(span.x * 0.9, base + 4), span.y * 0.62, col.lightened(0.05), Color("#ffd8a0"), gold, 1, -1.0)
		1:
			# 회랑: 아치 기둥 줄 + 종루의 큰 종(흔들림) + 깃발
			var top := span.y * 0.22
			var bot := span.y + 40
			var gap := 150.0
			var x := rng.randf_range(0, 60)
			var body := col.lightened(0.04)
			var light := col.lightened(0.14)
			var gold := Color("#c8a050").lerp(col, 0.35)
			var i := 0
			while x < span.x + gap:
				_art_column(l, x, top, bot, 22, body, light, gold)
				var bx := x
				if i % 3 == 1:
					var pv := Vector2(x - gap * 0.5, top + 4)
					l.anim(_bb_bell(pv, 12, 42), func(cv: CanvasItem, tt: float) -> void: ART.bell(cv, pv, 12, 42, sin(tt * 0.9 + bx) * 0.08, ART.BELL_METAL, 0.4, 0.2))
				elif i % 3 == 2:
					var bh := span.y * 0.34
					var bcl := Color("#d8d0e0").lerp(col, 0.45)
					l.anim(_bb_banner(x - gap * 0.5, top + 6, 22, bh, 4.0), func(cv: CanvasItem, tt: float) -> void: _banner(cv, bx - gap * 0.5, top + 6, 22, bh, bcl, gold, sin(tt * 1.1 + bx) * 4.0))
				_art_arch(l, x - gap, x, top + 16, body, 10)
				x += gap
				i += 1
			l.draw_rect(Rect2(-50, top - 30, span.x + 100, 22), body)
			l.draw_rect(Rect2(-50, top - 10, span.x + 100, 2), gold)
		2:
			# 가까운 굵은 기둥 + 해 원반을 든 석상의 손 + 흰 꽃 정원
			var gold := Color("#d8b060").lerp(col, 0.4)
			var x := rng.randf_range(60, 200)
			while x < span.x:
				_art_column(l, x, span.y * 0.08, span.y + 40, 34, col.lightened(0.03), col.lightened(0.1), gold)
				x += rng.randf_range(360, 520)
			var by := span.y - 182
			l.draw_rect(Rect2(-40, by, span.x + 80, span.y), col)
			for i in int(span.x / 14.0):
				var fx := i * 14.0 + rng.randf_range(-4, 4)
				var fy := by - rng.randf_range(2, 14)
				l.draw_line(Vector2(fx, by), Vector2(fx, fy), col.lightened(0.08), 1.0)
				l.draw_rect(Rect2(fx - 1, fy - 1, 3, 2), Color(0.92, 0.9, 1.0, 0.55))


# ─── 대신전 안 ─────────────────────────────────────────

static func _layer_temple(l, th: Dictionary, depth: int, span: Vector2, rng: RandomNumberGenerator, t: float) -> void:
	if depth == 3:
		_front(l, "temple", span, rng)
		return
	var col := _col(th, depth)
	match depth:
		0:
			# 흰 대리석 벽 (그늘진 회보라)
			_temple_far_wall(l, col.lerp(Color("#5a547c"), 0.35), span, rng)
		1:
			# 거대한 기둥 + 매달린 종(흔들림) + 긴 깃발 + 빛줄기(일렁임)
			var top := span.y * 0.12
			var gap := 230.0
			var x := rng.randf_range(20, 120)
			var body := Color("#68628a").lerp(col, 0.4)
			var gold := Color("#d0a850").lerp(col, 0.25)
			var i := 0
			# 빛줄기 (창에서 비스듬히)
			var sx := rng.randf_range(0, 200)
			var sl := span.y + 60
			while sx < span.x + 200:
				var s0 := sx
				l.anim(Rect2(sx - 62, -22, 124 + 0.42 * sl, sl + 4), func(cv: CanvasItem, tt: float) -> void:
					var a := 0.05 + 0.025 * sin(tt * 0.6 + s0 * 0.01)
					_shaft(cv, Vector2(s0, -20), 40, 120, sl, 0.42, Color(1.0, 0.9, 0.6, a))
					_shaft(cv, Vector2(s0 + 10, -20), 14, 40, sl, 0.42, Color(1.0, 0.95, 0.75, a * 0.9)))
				sx += rng.randf_range(260, 420)
			while x < span.x + gap:
				_art_column(l, x, top, span.y + 40, 30, body, Color("#aaa4c8").lerp(col, 0.35), gold)
				var mid := x + gap * 0.5
				var bi := i
				if i % 2 == 0:
					l.draw_line(Vector2(mid, -20), Vector2(mid, top + 10), col.darkened(0.2), 2.0)
					var pv := Vector2(mid, top + 10)
					l.anim(_bb_bell(pv, 30, 58), func(cv: CanvasItem, tt: float) -> void: ART.bell(cv, pv, 30, 58, sin(tt * 0.7 + bi * 1.3) * 0.07, ART.BELL_METAL, 0.3, 0.3))
				else:
					var bh := span.y * 0.45
					var bcl := Color("#e0d8e8").lerp(col, 0.5)
					l.anim(_bb_banner(mid, top - 6, 26, bh, 3.0), func(cv: CanvasItem, tt: float) -> void: _banner(cv, mid, top - 6, 26, bh, bcl, gold, sin(tt * 0.9 + bi) * 3.0))
				x += gap
				i += 1
			l.draw_rect(Rect2(-50, top - 40, span.x + 100, 24), body)
			l.draw_rect(Rect2(-50, top - 18, span.x + 100, 2), gold)
		2:
			# 가까운 기둥(어둡게) + 거대한 루멘 석상(해의 관만 빛남) + 사슬에 매달린 향로
			var gold := Color("#b89048").lerp(col, 0.45)
			var x := rng.randf_range(80, 220)
			var k := 0
			while x < span.x:
				_art_column(l, x, span.y * 0.04, span.y + 40, 40, col.lightened(0.02), col.lightened(0.08), gold)
				var cx := x + rng.randf_range(150, 200)
				if k % 2 == 0:
					_art_lumen_statue(l, Vector2(cx, span.y - 140), span.y * 0.62, col.lightened(0.03), Color("#ffd8a0"), Color("#c89a48").lerp(col, 0.3), 0, -1.0)
				else:
					var ln := rng.randf_range(60, 140)
					var y := -20.0
					while y < ln:
						l.draw_rect(Rect2(cx - 2, y, 4, 6), col.lightened(0.06))
						y += 7.0
					l.draw_colored_polygon(PackedVector2Array([Vector2(cx - 10, ln), Vector2(cx + 10, ln), Vector2(cx + 6, ln + 14), Vector2(cx - 6, ln + 14)]), col.lightened(0.08))
					l.draw_rect(Rect2(cx - 10, ln, 20, 2), gold)
					_art_lantern_dot(l, Vector2(cx, ln + 10), 1.5, 0.6)
				x += rng.randf_range(400, 560)
				k += 1


## 대신전 안의 먼 벽: 아치 창(창 너머로 하늘이 보이게 벽을 조각조각 그림) + 장미창 + 금테
static func _temple_far_wall(l, col: Color, span: Vector2, rng: RandomNumberGenerator) -> void:
	var gold := Color("#9a7a44").lerp(col, 0.35)
	var top := span.y * 0.16
	var bot := span.y * 0.7
	var w := 64.0
	var gap := 170.0
	var xs: Array[float] = []
	var x := rng.randf_range(30, 120)
	while x < span.x:
		xs.append(x)
		x += gap
	# 창이 없는 곳: 위·아래 띠와 창 사이 벽
	l.draw_rect(Rect2(-50, -50, span.x + 100, top + 50), col)
	l.draw_rect(Rect2(-50, bot, span.x + 100, span.y - bot + 80), col)
	var prev := -50.0
	for wx in xs:
		l.draw_rect(Rect2(prev, top - 1, wx - prev, bot - top + 2), col)
		prev = wx + w
	l.draw_rect(Rect2(prev, top - 1, span.x + 60 - prev, bot - top + 2), col)
	for wx in xs:
		var cx := wx + w * 0.5
		var r := w * 0.5
		# 아치 위쪽 모서리 (창이 둥글게 보이게 벽을 채움)
		for side: float in [-1.0, 1.0]:
			var pts := PackedVector2Array()
			pts.append(Vector2(cx + side * r, top - 1))
			for i in 9:
				var a := -PI * 0.5 + side * PI * 0.5 * float(i) / 8.0
				pts.append(Vector2(cx + cos(a) * r, top + r + sin(a) * r))
			pts.append(Vector2(cx + side * r, top + r))
			l.draw_colored_polygon(pts, col)
		# 창살·창틀 (금빛 테)
		var arch := PackedVector2Array()
		for i in 17:
			var a := PI + PI * float(i) / 16.0
			arch.append(Vector2(cx + cos(a) * r, top + r + sin(a) * r))
		l.draw_polyline(arch, gold, 3.0)
		l.draw_line(Vector2(wx, top + r), Vector2(wx, bot), gold, 3.0)
		l.draw_line(Vector2(wx + w, top + r), Vector2(wx + w, bot), gold, 3.0)
		l.draw_line(Vector2(cx, top + 6), Vector2(cx, bot), Color(gold, 0.8), 2.0)
		for k in 3:
			var yy := top + r + 20 + k * (bot - top - r - 20) / 3.0
			l.draw_line(Vector2(wx, yy), Vector2(wx + w, yy), Color(gold, 0.55), 1.0)
		l.draw_arc(Vector2(cx, top + r * 0.9), r * 0.42, 0, TAU, 16, Color(gold, 0.8), 1.5)
		# 스테인드글라스 기운 (아주 옅게)
		l.draw_rect(Rect2(wx + 2, top + r, w * 0.5 - 3, bot - top - r), Color(0.4, 0.5, 1.0, 0.07))
		l.draw_rect(Rect2(cx + 1, top + r, w * 0.5 - 3, bot - top - r), Color(1.0, 0.7, 0.4, 0.06))
		# 창턱
		l.draw_rect(Rect2(wx - 6, bot, w + 12, 6), col.lightened(0.05))
		l.draw_rect(Rect2(wx - 6, bot, w + 12, 1), gold)
	# 위쪽 띠: 해 문양 원 장식
	l.draw_rect(Rect2(-50, top - 14, span.x + 100, 2), gold)
	var rx := 40.0
	while rx < span.x:
		l.draw_arc(Vector2(rx, top - 30), 7, 0, TAU, 12, Color(gold, 0.7), 1.0)
		l.draw_circle(Vector2(rx, top - 30), 2, Color(gold, 0.7))
		rx += 60.0
	# 장미창 (가운데 높이)
	var rc := Vector2(span.x * 0.5, top * 0.55)
	var rr := minf(top * 0.45, 44.0)
	if rr > 14.0:
		l.draw_circle(rc, rr, Color(0.95, 0.75, 0.45, 0.22))
		for i in 12:
			var a := TAU * i / 12.0
			l.draw_line(rc, rc + Vector2(cos(a), sin(a)) * rr, gold, 1.5)
		l.draw_arc(rc, rr, 0, TAU, 24, gold, 2.0)
		l.draw_arc(rc, rr * 0.5, 0, TAU, 16, gold, 1.5)
		l.draw_circle(rc, rr * 0.18, Color(1.0, 0.9, 0.6, 0.6))


# ─── 기록실·지하 ───────────────────────────────────────

static func _layer_dark(l, th: Dictionary, depth: int, span: Vector2, rng: RandomNumberGenerator, t: float) -> void:
	if depth == 3:
		_front(l, "temple_dark", span, rng)
		return
	var col := _col(th, depth)
	var warm := Color(1.0, 0.72, 0.38)
	match depth:
		0:
			# 끝없이 솟은 두루마리 서가 + 높은 궁륭 + 매달린 등잔의 빛
			l.draw_rect(Rect2(-50, -50, span.x + 100, span.y + 100), col)
			var x := rng.randf_range(0, 60)
			while x < span.x:
				var sw := 70.0
				l.draw_rect(Rect2(x, -20, sw, span.y + 40), col.lightened(0.035))
				l.draw_rect(Rect2(x, -20, 1, span.y + 40), Color(warm, 0.08))
				var y := 6.0
				while y < span.y:
					l.draw_rect(Rect2(x, y, sw, 2), col.lightened(0.07))
					var bx := x + 4.0
					while bx < x + sw - 4.0:
						l.draw_circle(Vector2(bx + 2, y - 4), 2.2, col.lightened(0.1))
						bx += 6.0
					y += 18.0
				x += sw + rng.randf_range(40, 90)
			var ax := rng.randf_range(0, 100)
			while ax < span.x:
				_art_arch(l, ax, ax + 220, span.y * 0.3, col.lightened(0.06), 6.0)
				ax += 220.0
			for i in int(span.x / 160.0) + 1:
				var lp := Vector2(rng.randf_range(0, span.x), rng.randf_range(40, span.y * 0.5))
				l.draw_line(Vector2(lp.x, -20), lp, col.lightened(0.08), 1.0)
				_art_glow(l, lp, 26.0, warm, 0.25)
				l.draw_rect(Rect2(lp.x - 2, lp.y - 1, 4, 3), Color(1.0, 0.85, 0.55, 0.8))
			for i in int(span.x / 30.0):
				l.draw_rect(Rect2(rng.randf_range(0, span.x), rng.randf_range(20, span.y * 0.8), 1, 1), Color(1.0, 0.75, 0.4, 0.45))
		1:
			# 아치 + 서가(두루마리 끝) + 촛불 선반(일렁이는 빛 무리) + 사다리
			var x := rng.randf_range(0, 120)
			var gold := Color("#8a6a3a")
			while x < span.x:
				var sw := 110.0
				var shelf_top := span.y * 0.1
				l.draw_rect(Rect2(x, shelf_top, sw, span.y), col.lightened(0.04))
				var y := shelf_top + 16
				while y < span.y:
					l.draw_rect(Rect2(x, y, sw, 3), col.lightened(0.1))
					var bx := x + 4.0
					while bx < x + sw - 6.0:
						var rr := rng.randf_range(2.5, 3.5)
						l.draw_circle(Vector2(bx + rr, y - rr - 1), rr, Color("#6a563c").lerp(col, 0.45))
						l.draw_circle(Vector2(bx + rr, y - rr - 1), rr * 0.4, col)
						bx += rr * 2.0 + 1.0
					y += 22.0
				# 사다리
				var lc := Color("#4a3a28").lerp(col, 0.3)
				l.draw_line(Vector2(x + sw + 10, shelf_top - 8), Vector2(x + sw - 14, span.y), lc, 3.0)
				l.draw_line(Vector2(x + sw + 22, shelf_top - 8), Vector2(x + sw - 2, span.y), lc, 3.0)
				var ly := shelf_top
				while ly < span.y:
					var off := (ly - shelf_top) / maxf(span.y - shelf_top, 1.0) * 24.0
					l.draw_line(Vector2(x + sw + 10 - off, ly), Vector2(x + sw + 22 - off, ly), lc, 2.0)
					ly += 14.0
				# 촛불 선반 (일렁이는 빛)
				var cy := shelf_top - 4
				l.draw_rect(Rect2(x - 4, cy, sw + 8, 4), col.lightened(0.12))
				l.draw_rect(Rect2(x - 4, cy, sw + 8, 1), gold)
				var shx := x
				for c in 5:
					var cx := x + 10 + c * (sw - 20) / 4.0
					l.anim(Kit.bb_circle(Vector2(cx, cy - 8), 18.0), func(cv: CanvasItem, tt: float) -> void:
						var fl := 0.75 + 0.25 * sin(tt * (6.0 + c) + shx) * sin(tt * 2.3 + c)
						ART.glow(cv, Vector2(cx, cy - 8), 18.0, warm, 0.22 * fl))
					l.draw_rect(Rect2(cx - 1, cy - 6, 2, 6), Color("#d8c8a0").lerp(col, 0.25))
					l.anim(Kit.bb_circle(Vector2(cx, cy - 8), 3.2), func(cv: CanvasItem, tt: float) -> void:
						var fl := 0.75 + 0.25 * sin(tt * (6.0 + c) + shx) * sin(tt * 2.3 + c)
						ART.lantern_dot(cv, Vector2(cx, cy - 8), 1.0, fl))
				x += sw + rng.randf_range(90, 180)
		2:
			# 가까운 무덤 감실·기도하는 성인상 + 큰 촛대
			var x := rng.randf_range(60, 200)
			var k := 0
			while x < span.x:
				var by := span.y - 150
				if k % 2 == 0:
					var w := 70.0
					l.draw_rect(Rect2(x - w * 0.5, by - 90, w, span.y), col.lightened(0.03))
					var pts := PackedVector2Array()
					for i in 9:
						var a := PI + PI * float(i) / 8.0
						pts.append(Vector2(x + cos(a) * w * 0.32, by - 60 + sin(a) * w * 0.32))
					pts.append(Vector2(x + w * 0.32, by))
					pts.append(Vector2(x - w * 0.32, by))
					l.draw_colored_polygon(pts, col.darkened(0.3))
					l.draw_colored_polygon(PackedVector2Array([Vector2(x - 9, by - 50), Vector2(x + 9, by - 50), Vector2(x + 12, by), Vector2(x - 12, by)]), col.lightened(0.07))
					l.draw_circle(Vector2(x, by - 56), 6, col.lightened(0.08))
					l.draw_colored_polygon(PackedVector2Array([Vector2(x - 2, by - 44), Vector2(x + 2, by - 44), Vector2(x, by - 52)]), col.lightened(0.14))
					l.draw_arc(Vector2(x, by - 58), 9, PI * 1.1, PI * 1.9, 8, Color(1.0, 0.8, 0.45, 0.35), 1.0)
				else:
					# 큰 촛대 (세 갈래)
					l.draw_rect(Rect2(x - 2, by - 70, 4, 80), col.lightened(0.06))
					l.draw_rect(Rect2(x - 10, by + 6, 20, 4), col.lightened(0.06))
					for j in 3:
						var cx := x + (j - 1) * 12.0
						l.draw_line(Vector2(x, by - 60), Vector2(cx, by - 72), col.lightened(0.06), 2.0)
						l.draw_rect(Rect2(cx - 1.5, by - 80, 3, 8), Color("#d8c8a0").lerp(col, 0.3))
						_art_lantern_dot(l, Vector2(cx, by - 83), 1.2, 0.85)
					_art_glow(l, Vector2(x, by - 82), 34.0, warm, 0.2)
				x += rng.randf_range(260, 420)
				k += 1


# ─── 밤의 첨탑 (추격) ──────────────────────────────────

static func _layer_spire(l, th: Dictionary, depth: int, span: Vector2, rng: RandomNumberGenerator, t: float) -> void:
	if depth == 3:
		_front(l, "spire", span, rng)
		return
	var col := _col(th, depth)
	var warm := Color(1.0, 0.78, 0.4)
	var moon := Color(0.75, 0.78, 1.0)
	match depth:
		0:
			# 뼈대만 남은 거대한 탑: 기둥 사이로 밤하늘이 보이고, 층마다 고리 들보, 버팀대. 맨 아래는 금빛 심연
			var pier_gap := 190.0
			var x := rng.randf_range(-20, 60)
			while x < span.x + 60:
				var w := 46.0
				l.draw_rect(Rect2(x - w * 0.5, -40, w, span.y + 80), col)
				l.draw_rect(Rect2(x - w * 0.5, -40, 2, span.y + 80), Color(moon, 0.18))
				l.draw_rect(Rect2(x + w * 0.5 - 3, -40, 3, span.y + 80), col.darkened(0.3))
				var wy := rng.randf_range(20, 120)
				while wy < span.y:
					l.draw_rect(Rect2(x - 3, wy, 6, 9), Color(warm, 0.55))
					l.draw_rect(Rect2(x - 3, wy, 6, 3), Color(1.0, 0.95, 0.8, 0.5))
					wy += rng.randf_range(90, 170)
				x += pier_gap
			var ring := 250.0
			var y := span.y - 40
			var gold := Color("#7a5a30").lerp(col, 0.35)
			while y > -ring:
				l.draw_rect(Rect2(-50, y - 16, span.x + 100, 16), col.lightened(0.03))
				l.draw_rect(Rect2(-50, y - 16, span.x + 100, 1), gold)
				# 고리 들보 아래 늘어진 장식(아치 모양 버팀대)
				var bx := rng.randf_range(-40, 40)
				while bx < span.x:
					_art_arch(l, bx, bx + pier_gap, y + 70, col, 6.0)
					bx += pier_gap
				y -= ring
			for i in 12:
				l.draw_rect(Rect2(-50, span.y - 30 - i * 18, span.x + 100, 18), Color(1.0, 0.75, 0.35, 0.055 * (12 - i) / 12.0))
		1:
			# 종틀의 거대한 종(흔들림) + 등불 줄 + 비계 + 톱니 승강기(회전)
			var gold := Color("#b08a48").lerp(col, 0.3)
			var lit := Color("#e8c070").lerp(col, 0.4)
			var y := span.y - rng.randf_range(80, 160)
			var k := 0
			while y > -100:
				var x := rng.randf_range(60, span.x - 60)
				match k % 4:
					0:
						l.draw_rect(Rect2(x - 70, y - 96, 140, 8), col.lightened(0.1))
						l.draw_rect(Rect2(x - 70, y - 96, 140, 1), lit)
						l.draw_rect(Rect2(x - 66, y - 96, 6, 130), col.lightened(0.06))
						l.draw_rect(Rect2(x + 60, y - 96, 6, 130), col.lightened(0.06))
						l.draw_rect(Rect2(x - 66, y - 96, 1, 130), Color(lit, 0.6))
						_art_glow(l, Vector2(x, y - 50), 70.0, warm, 0.08)
						var pv := Vector2(x, y - 88)
						var bk := k
						l.anim(_bb_bell(pv, 6, 68), func(cv: CanvasItem, tt: float) -> void: ART.bell(cv, pv, 6, 68, sin(tt * 0.8 + bk) * 0.1, ART.BELL_METAL, 0.3, 0.4))
					1:
						_scaffold(l, x - 80, x + 80, y - 120, y, col.lightened(0.07), lit, 40.0)
						for j in 3:
							var lp := Vector2(x - 60 + j * 60, y - 114)
							var lk := k
							l.anim(Kit.bb_circle(lp, 16.0), func(cv: CanvasItem, tt: float) -> void:
								var fl := 0.7 + 0.3 * sin(tt * 4.0 + j + lk)
								ART.glow(cv, lp, 16.0, warm, 0.25 * fl)
								ART.lantern_dot(cv, lp, 1.8, fl))
					2:
						var gc := Vector2(x, y - 60)
						var r := 52.0
						# 도는 톱니 승강기 (톱니·바큇살이 돌고 그 사이의 테·원판은 원래 순서대로 함께)
						l.anim(Kit.bb_circle(gc, r + 2.0), func(cv: CanvasItem, tt: float) -> void:
							var rot := tt * 0.25
							var pts := PackedVector2Array()
							for i in 32:
								var a := rot + TAU * i / 32.0
								var rr := r if i % 2 == 0 else r * 0.86
								pts.append(gc + Vector2(cos(a), sin(a)) * rr)
							cv.draw_colored_polygon(pts, col.lightened(0.08))
							cv.draw_arc(gc, r * 0.86, PI * 1.1, PI * 1.6, 10, Color(lit, 0.5), 2.0)
							cv.draw_circle(gc, r * 0.6, col.darkened(0.2))
							for i in 6:
								var a := rot + TAU * i / 6.0
								cv.draw_line(gc, gc + Vector2(cos(a), sin(a)) * r * 0.62, col.lightened(0.08), 5.0)
							cv.draw_circle(gc, r * 0.14, gold))
						l.draw_line(gc + Vector2(r, 0), gc + Vector2(r, 220), col.lightened(0.12), 2.0)
						l.draw_line(gc + Vector2(-r, 0), gc + Vector2(-r, 160), col.lightened(0.12), 2.0)
					3:
						# 등불 줄 (축 늘어진 줄에 매달린 등)
						var a := Vector2(x - 150, y - 110)
						var b := Vector2(x + 150, y - 90)
						var prev := a
						for i in 11:
							var kk := float(i) / 10.0
							var p := a.lerp(b, kk) + Vector2(0, sin(kk * PI) * 34.0)
							if i > 0:
								l.draw_line(prev, p, col.lightened(0.15), 1.0)
							if i % 2 == 1:
								var lk := k
								l.anim(Kit.bb_circle(p + Vector2(0, 6), 12.0), func(cv: CanvasItem, tt: float) -> void:
									var fl := 0.7 + 0.3 * sin(tt * 3.0 + i + lk)
									ART.glow(cv, p + Vector2(0, 6), 12.0, warm, 0.3 * fl)
									cv.draw_rect(Rect2(p.x - 2, p.y + 2, 4, 6), Color(1.0, 0.82, 0.5, 0.9 * fl)))
							prev = p
				y -= rng.randf_range(170, 250)
				k += 1
		2:
			# 가까운 비계 기둥·대각 들보 (금빛 테두리)
			var x := rng.randf_range(0, 160)
			var lit := Color("#e8c070").lerp(col, 0.55)
			while x < span.x:
				l.draw_rect(Rect2(x, -40, 14, span.y + 80), col.lightened(0.05))
				l.draw_rect(Rect2(x, -40, 2, span.y + 80), lit)
				var y := rng.randf_range(0, 120)
				while y < span.y:
					var dx := rng.randf_range(-90, 90)
					l.draw_line(Vector2(x + 7, y), Vector2(x + 7 + dx, y + 120), col.lightened(0.04), 6.0)
					l.draw_line(Vector2(x + 7, y - 2), Vector2(x + 7 + dx, y + 118), Color(lit, 0.5), 1.0)
					y += rng.randf_range(180, 280)
				x += rng.randf_range(320, 480)
			for i in int(span.y / 320.0) + 1:
				var ry := i * 320.0 + rng.randf_range(0, 120)
				l.draw_line(Vector2(rng.randf_range(0, span.x * 0.3), ry), Vector2(rng.randf_range(span.x * 0.6, span.x), ry + 40), Color(0.25, 0.2, 0.14, 0.7), 1.0)


# ─── 첨탑 꼭대기 ───────────────────────────────────────

static func _layer_top(l, th: Dictionary, depth: int, span: Vector2, rng: RandomNumberGenerator, t: float) -> void:
	if depth == 3:
		_front(l, "spire_top", span, rng)
		return
	var col := _col(th, depth)
	match depth:
		0:
			# 구름 아래로 내려다보이는 신전의 다른 탑들과 돔 (작게)
			var by := span.y - 130
			var gold := Color("#8a6a3a").lerp(col, 0.4)
			for i in 9:
				var x := rng.randf_range(0, span.x)
				var h := rng.randf_range(40, 110)
				l.draw_colored_polygon(PackedVector2Array([Vector2(x - 10, by), Vector2(x - 6, by - h), Vector2(x, by - h - 26), Vector2(x + 6, by - h), Vector2(x + 10, by)]), col)
				l.draw_rect(Rect2(x - 1, by - h * 0.6, 2, 3), Color(1.0, 0.85, 0.5, 0.7))
			for i in 4:
				_art_dome(l, rng.randf_range(0, span.x), by, rng.randf_range(14, 24), col, gold, Color(1, 0.85, 0.5, 0.5))
		1:
			# 종루의 거대한 아치와 대종 (아주 크게, 천천히 흔들림)
			var gold := Color("#b8904c").lerp(col, 0.3)
			var cx := span.x * 0.5
			var top := 30.0
			var body := col.lightened(0.06)
			var half := minf(span.x * 0.36, 300.0)
			for side: float in [-1.0, 1.0]:
				_art_column(l, cx + side * half, top + 70, span.y + 40, 40, body, col.lightened(0.15), gold)
			l.draw_rect(Rect2(cx - half - 30, top + 40, half * 2.0 + 60, 18), body)
			l.draw_rect(Rect2(cx - half - 30, top + 40, half * 2.0 + 60, 2), gold)
			l.draw_line(Vector2(cx, top + 56), Vector2(cx, top + 76), gold, 4.0)
			_art_glow(l, Vector2(cx, top + 170), 160.0, Color(1.0, 0.85, 0.5), 0.06)
			var pv := Vector2(cx, top + 56)
			l.anim(_bb_bell(pv, 20, 150), func(cv: CanvasItem, tt: float) -> void: ART.bell(cv, pv, 20, 150, sin(tt * 0.35) * 0.04, ART.BELL_METAL, 0.3, 0.5))
			for i in 4:
				var bx := rng.randf_range(0, span.x)
				var bw := rng.randf_range(30, 60)
				l.draw_rect(Rect2(bx, span.y * 0.55 + rng.randf_range(0, 60), bw, 10), body)
		2:
			# 떠 있는 대리석 조각 (천천히 떠오르내림)
			var gold := Color("#d8b060").lerp(col, 0.5)
			for i in 8:
				var x := rng.randf_range(0, span.x)
				var y := rng.randf_range(span.y * 0.15, span.y * 0.6)
				var s := rng.randf_range(6, 16)
				l.anim(Rect2(x - s * 1.25, y - s * 1.25 - 4.0, s * 2.5, s * 2.5 + 8.0), func(cv: CanvasItem, tt: float) -> void:
					var bob := sin(tt * (0.6 + i * 0.13) + i) * 4.0
					var rot := tt * 0.1 * (1.0 if i % 2 == 0 else -1.0) + i
					var pts := PackedVector2Array()
					for k in 5:
						var a := rot + TAU * k / 5.0 + ART.hf(k, i) * 0.6
						pts.append(Vector2(x, y + bob) + Vector2(cos(a), sin(a)) * s * (0.7 + ART.hf(k, i + 9) * 0.5))
					cv.draw_colored_polygon(pts, col.lightened(0.1))
					cv.draw_line(pts[0], pts[1], gold, 1.0))
