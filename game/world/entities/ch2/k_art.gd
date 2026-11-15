extends RefCounted
## 2장(아르덴 제국) 그림 공용 도우미 — 배경(backdrop_ch2)·소품(props)·인물(leonie_draw)·적(enemies/ch2)이 함께 쓴다.
## 모두 static: `const KArt := preload("res://world/entities/ch2/k_art.gd")` 뒤 `KArt.glow(c, ...)`.
## c는 그릴 대상(CanvasItem: Node2D·Control 모두 됨).

const SILVER := Color("#c8ccd8")
const SILVER_MID := Color("#8e94a8")
const SILVER_DARK := Color("#555b70")
const CRIMSON := Color("#9a1e2a")
const CRIMSON_DARK := Color("#5e1018")
const CRIMSON_LIGHT := Color("#c83a40")
const AMBER := Color("#ffb45a")
const GOLD := Color("#ffd27a")
const STAR_TEAL := Color("#6af0e0")
const STAR_VIOLET := Color("#c89aff")


static var _bad_poly := {}


## 안전한 다각형 채우기: 움직이는 꼭짓점(망토·머리)이 꼬여 삼각분할이 안 되면 볼록 껍질로 대신 그린다
## (엔진 오류 "triangulation failed"를 내지 않음). 처음 실패한 자리는 한 번만 경고로 남긴다.
static func poly(c: CanvasItem, pts: PackedVector2Array, col: Color) -> void:
	if pts.size() < 3:
		return
	if Geometry2D.triangulate_polygon(pts).is_empty():
		var st := get_stack()
		var key := str(st[1]) if st.size() > 1 else "?"
		if not _bad_poly.has(key):
			_bad_poly[key] = true
			push_warning("KArt.poly: 꼬인 다각형 → 볼록 껍질 %s %s" % [key, str(pts)])
		var hull := Geometry2D.convex_hull(pts)
		if hull.size() >= 4:
			hull.remove_at(hull.size() - 1)
			c.draw_colored_polygon(hull, col)
		return
	c.draw_colored_polygon(pts, col)


## 은은한 빛: 바깥에서 안으로 겹치는 원 (가산 합성 없이도 어두운 배경에서 빛나 보이게)
static func glow(c: CanvasItem, pos: Vector2, r: float, col: Color, rings := 4) -> void:
	for i in rings:
		var k := 1.0 - float(i) / rings
		c.draw_circle(pos, r * k, Color(col, col.a * 0.10 * (1.0 + i * 0.6)))


## 계단식 세로 그라데이션 (픽셀 느낌)
static func stepped_grad(c: CanvasItem, rect: Rect2, top: Color, bot: Color, steps := 20, curve := 1.0) -> void:
	var h := rect.size.y / steps
	for i in steps:
		var k := float(i) / maxf(steps - 1, 1)
		c.draw_rect(Rect2(rect.position.x, rect.position.y + i * h, rect.size.x, h + 1.0), top.lerp(bot, pow(k, curve)))


## 네 갈래 반짝임 (별)
static func star4(c: CanvasItem, pos: Vector2, s: float, col: Color) -> void:
	c.draw_colored_polygon(PackedVector2Array([
		pos + Vector2(0, -s), pos + Vector2(s * 0.22, -s * 0.22), pos + Vector2(s, 0), pos + Vector2(s * 0.22, s * 0.22),
		pos + Vector2(0, s), pos + Vector2(-s * 0.22, s * 0.22), pos + Vector2(-s, 0), pos + Vector2(-s * 0.22, -s * 0.22),
	]), col)


## 별 다섯 꼭지 (별 신도 문양)
static func star5(c: CanvasItem, pos: Vector2, r: float, col: Color, rot := 0.0) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := rot - PI * 0.5 + TAU * i / 10.0
		var rr := r if i % 2 == 0 else r * 0.42
		pts.append(pos + Vector2(cos(a), sin(a)) * rr)
	c.draw_colored_polygon(pts, col)


## 은사자 문장: 방패 바탕 + 일어선 사자 옆모습 (s = 방패 반폭 px, 3 이상 권장)
static func lion_crest(c: CanvasItem, center: Vector2, s: float, fg: Color, bg: Color) -> void:
	var shield := PackedVector2Array([
		center + Vector2(-s, -s * 1.15), center + Vector2(s, -s * 1.15), center + Vector2(s, s * 0.2),
		center + Vector2(0, s * 1.35), center + Vector2(-s, s * 0.2),
	])
	c.draw_colored_polygon(shield, bg)
	if s < 3.5:
		# 아주 작을 때: 사자 머리(갈기 원) 한 점
		c.draw_circle(center + Vector2(0, -s * 0.2), s * 0.55, fg)
		return
	var u := s / 6.0
	# 갈기 + 머리
	c.draw_circle(center + Vector2(u * 0.6, -u * 3.4), u * 2.1, fg)
	c.draw_rect(Rect2(center + Vector2(u * 1.6, -u * 4.0), Vector2(u * 1.8, u * 1.6)), fg) # 주둥이
	# 몸 (일어선 자세)
	c.draw_colored_polygon(PackedVector2Array([
		center + Vector2(-u * 1.2, -u * 2.0), center + Vector2(u * 1.6, -u * 1.6), center + Vector2(u * 1.2, u * 2.4),
		center + Vector2(-u * 2.0, u * 3.2), center + Vector2(-u * 2.4, u * 1.0),
	]), fg)
	# 앞발 (들어 올림)
	c.draw_line(center + Vector2(u * 1.0, -u * 1.0), center + Vector2(u * 3.4, -u * 2.2), fg, maxf(u * 0.9, 1.0))
	# 뒷다리
	c.draw_line(center + Vector2(-u * 0.8, u * 2.6), center + Vector2(u * 0.4, u * 4.8), fg, maxf(u * 1.0, 1.0))
	# 꼬리 (말려 올라감)
	c.draw_line(center + Vector2(-u * 2.2, u * 1.6), center + Vector2(-u * 3.8, -u * 0.6), fg, maxf(u * 0.7, 1.0))
	c.draw_circle(center + Vector2(-u * 3.8, -u * 0.9), u * 0.8, fg)


## 톱니바퀴 (rot 라디안)
static func gear(c: CanvasItem, center: Vector2, r: float, rot: float, col: Color, hole: Color, spokes := 5) -> void:
	var teeth := maxi(int(r / 4.5), 6)
	var pts := PackedVector2Array()
	for i in teeth * 2:
		var a := rot + TAU * i / (teeth * 2)
		var rr := r if i % 2 == 0 else r * 0.84
		pts.append(center + Vector2(cos(a), sin(a)) * rr)
		var a2 := rot + TAU * (i + 0.5) / (teeth * 2)
		pts.append(center + Vector2(cos(a2), sin(a2)) * rr)
	c.draw_colored_polygon(pts, col)
	c.draw_circle(center, r * 0.66, hole)
	c.draw_arc(center, r * 0.62, 0, TAU, 24, col, maxf(r * 0.1, 1.0))
	for i in spokes:
		var a3 := rot + TAU * i / spokes
		c.draw_line(center, center + Vector2(cos(a3), sin(a3)) * r * 0.62, col, maxf(r * 0.12, 1.0))
	c.draw_circle(center, r * 0.18, col.lightened(0.1))
	c.draw_circle(center, r * 0.07, hole)


## 바람에 펄럭이는 삼각 깃발 (top = 깃대 꼭대기, 오른쪽으로 날림)
static func pennant(c: CanvasItem, top: Vector2, length: float, height: float, t: float, col: Color, pole: Color) -> void:
	c.draw_line(top, top + Vector2(0, height * 3.2), pole, 1.0)
	var pts := PackedVector2Array()
	var n := 6
	for i in n + 1:
		var k := float(i) / n
		var wave := sin(t * 5.0 - k * 4.0) * height * 0.35 * k
		pts.append(top + Vector2(length * k, height * 0.5 * k + wave))
	for i in range(n - 1, -1, -1):
		var k2 := float(i) / n
		var wave2 := sin(t * 5.0 - k2 * 4.0) * height * 0.35 * k2
		pts.append(top + Vector2(length * k2, height * (1.0 - 0.5 * k2) + wave2))
	c.draw_colored_polygon(pts, col)


## 매달린 제비꼬리 깃발 (top_center = 위 막대 가운데). crest면 은사자 문장
static func hanging_banner(c: CanvasItem, top_center: Vector2, w: float, h: float, t: float, col: Color, crest := true, trim := Color("#c8a040")) -> void:
	var sway := sin(t * 1.3 + top_center.x * 0.01) * w * 0.08
	var x0 := top_center.x - w * 0.5
	var y0 := top_center.y
	var pts := PackedVector2Array([
		Vector2(x0, y0), Vector2(x0 + w, y0),
		Vector2(x0 + w + sway, y0 + h), Vector2(x0 + w * 0.5 + sway, y0 + h - w * 0.4), Vector2(x0 + sway, y0 + h),
	])
	c.draw_colored_polygon(pts, col)
	# 접힌 주름 그림자
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(x0 + w * 0.62, y0), Vector2(x0 + w * 0.78, y0),
		Vector2(x0 + w * 0.78 + sway, y0 + h - w * 0.12), Vector2(x0 + w * 0.62 + sway, y0 + h - w * 0.3),
	]), col.darkened(0.25))
	c.draw_rect(Rect2(x0 - 2, y0 - 2, w + 4, 3), trim)
	c.draw_line(Vector2(x0 + 1, y0 + 2), Vector2(x0 + 1 + sway * 0.9, y0 + h - 3), col.lightened(0.15), 1.0)
	if crest and w >= 8.0:
		lion_crest(c, Vector2(top_center.x + sway * 0.45, y0 + h * 0.42), w * 0.3, SILVER, col.darkened(0.3))


## 굴뚝 연기 (base = 굴뚝 입구, 위로 피어오름)
static func smoke(c: CanvasItem, base: Vector2, t: float, seed: float, col: Color, scale := 1.0, puffs := 6) -> void:
	for i in puffs:
		var ph := fmod(t * 0.22 + seed + float(i) / puffs, 1.0)
		var rise := ph * 70.0 * scale
		var drift := ph * 26.0 * scale + sin(t * 0.8 + i + seed * 7.0) * 3.0 * scale
		var r := (2.5 + ph * 9.0) * scale
		c.draw_circle(base + Vector2(drift, -rise), r, Color(col, col.a * (1.0 - ph) * (0.6 if ph < 0.1 else 1.0)))


## 아치 외곽선 점 (pointed=고딕 첨두아치, 아니면 반원)
static func arch_points(cx: float, base_y: float, w: float, h: float, pointed := false, n := 10) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var r := w * 0.5
	pts.append(Vector2(cx - r, base_y))
	if pointed:
		# 양쪽 원호(중심이 반대편으로 d만큼 비켜 있음)가 꼭대기에서 만남
		var d := r * 0.3
		var rr := r + d
		var th := acos(d / rr)
		var spring := base_y - h + sin(th) * rr
		for i in n + 1:
			var a := PI + th * float(i) / n
			pts.append(Vector2(cx + d + cos(a) * rr, spring + sin(a) * rr))
		for i in range(1, n + 1):
			var a2 := TAU - th + th * float(i) / n
			pts.append(Vector2(cx - d + cos(a2) * rr, spring + sin(a2) * rr))
	else:
		var spring2 := base_y - h + r
		for i in n + 1:
			var a3 := PI + PI * float(i) / n
			pts.append(Vector2(cx + cos(a3) * r, spring2 + sin(a3) * r))
	pts.append(Vector2(cx + r, base_y))
	return pts


## 별 수정 덩어리 (base = 바닥 가운데). k = 빛 세기 0~1
static func crystal(c: CanvasItem, base: Vector2, h: float, col: Color, k := 1.0, seed := 0) -> void:
	var shards := [[-0.32, 0.62, -0.35], [0.0, 1.0, 0.0], [0.3, 0.72, 0.3], [-0.12, 0.45, -0.6], [0.18, 0.4, 0.65]]
	var dark := col.darkened(0.55)
	glow(c, base + Vector2(0, -h * 0.5), h * 0.9, Color(col, 0.5 * k), 3)
	for i in shards.size():
		var s: Array = shards[(i + seed) % shards.size()]
		var bx := base.x + float(s[0]) * h
		var sh := h * float(s[1])
		var lean := float(s[2]) * h * 0.25
		var w := maxf(h * 0.13, 1.5)
		var tip := Vector2(bx + lean, base.y - sh)
		c.draw_colored_polygon(PackedVector2Array([Vector2(bx - w, base.y), tip, Vector2(bx + w, base.y)]), dark.lerp(col, 0.35))
		c.draw_colored_polygon(PackedVector2Array([Vector2(bx, base.y), tip, Vector2(bx + w, base.y)]), col.lerp(Color.WHITE, 0.15 * k))
		c.draw_line(Vector2(bx, base.y - 1), tip.lerp(Vector2(bx, base.y), 0.25), Color(1, 1, 1, 0.35 * k), 1.0)


## 별가루 반짝임 몇 개 (영역 안, 시간에 따라 깜빡임)
static func twinkles(c: CanvasItem, rect: Rect2, n: int, t: float, col: Color, seed := 1) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for i in n:
		var p := rect.position + Vector2(rng.randf() * rect.size.x, rng.randf() * rect.size.y)
		var tw := 0.5 + 0.5 * sin(t * rng.randf_range(1.5, 4.0) + i * 1.7)
		if tw > 0.7:
			star4(c, p, 1.0 + 1.5 * (tw - 0.7) / 0.3, Color(col, col.a * tw))
		else:
			c.draw_rect(Rect2(p, Vector2.ONE), Color(col, col.a * tw))
