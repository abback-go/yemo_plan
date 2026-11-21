## icons.gd — 지도에 쓰는 아이콘을 코드로 그린다 (전투=교차한 칼, 강적=해골, 사건=물음표, 휴식=불꽃, 훈련=교차한 창, 거래=관과 동전, 전조=눈,
## 계단, 캠프, 홀(갈림길), 층의 끝=발)
## 돌판(층 표시)·둥근 테두리·죽음 표식(붉은 실 매듭)도 여기서 그린다.
class_name Icons
extends Object


## 아이콘 하나. c: 가운데, r: 반지름(아이콘 크기), col: 선 색
static func draw(ci: CanvasItem, kind: String, c: Vector2, r: float, col := Color("#f0e6d8"), a := 1.0) -> void:
	var w := maxf(1.5, r * 0.14)
	var cc := Color(col.r, col.g, col.b, col.a * a)
	match kind:
		"flame":
			# 물방울 모양 불꽃: 아래는 둥글고 위는 살짝 휘어진 뾰족한 끝 + 안쪽 밝은 불꽃
			for layer in 2:
				var k := 1.0 if layer == 0 else 0.55
				var off := Vector2(0, r * 0.22) if layer == 0 else Vector2(0, r * 0.42)
				var rr := r * 0.5 * k
				var pts := PackedVector2Array()
				var tip := c + off + Vector2(r * 0.12 * k, -r * 1.25 * k)
				pts.append(tip)
				for i in 21:
					var ang := deg_to_rad(-25.0 + i * (230.0 / 20.0))
					pts.append(c + off + Vector2(cos(ang), sin(ang)) * rr)
				pts.append(c + off + Vector2(-rr * 0.7, -rr * 1.1))
				var col2 := Color(1, 0.42, 0.12, 0.95 * a) if layer == 0 else Color(1, 0.9, 0.6, 0.95 * a)
				ci.draw_colored_polygon(pts, col2)
		"question":
			ci.draw_arc(c + Vector2(0, -r * 0.28), r * 0.42, PI * 1.05, PI * 2.35, 20, cc, w * 1.3, true)
			ci.draw_line(c + Vector2(r * 0.12, r * 0.06), c + Vector2(0, r * 0.3), cc, w * 1.3, true)
			ci.draw_circle(c + Vector2(0, r * 0.62), w * 0.9, cc)
		"sword":
			_sword(ci, c, r, -PI / 4, cc, w)
		"swords":
			_sword(ci, c, r, -PI / 4, cc, w)
			_sword(ci, c, r, -3 * PI / 4, cc, w)
		"stairs":
			var s := r * 0.36
			var o := c + Vector2(-r * 0.6, r * 0.55)
			var pts2 := PackedVector2Array([o])
			for i in 3:
				pts2.append(o + Vector2(i * s, -(i + 1) * s))
				pts2.append(o + Vector2((i + 1) * s, -(i + 1) * s))
			ci.draw_polyline(pts2, cc, w, true)
			ci.draw_line(o, o + Vector2(3 * s, 0), Color(cc.r, cc.g, cc.b, cc.a * 0.5), w * 0.6, true)
		"camp":
			ci.draw_line(c + Vector2(-r * 0.6, r * 0.55), c + Vector2(r * 0.6, r * 0.3), Color("#8a6a4a"), w * 1.3, true)
			ci.draw_line(c + Vector2(-r * 0.6, r * 0.3), c + Vector2(r * 0.6, r * 0.55), Color("#8a6a4a"), w * 1.3, true)
			draw(ci, "flame", c + Vector2(0, -r * 0.15), r * 0.7, col, a)
		"fork":
			ci.draw_line(c + Vector2(0, r * 0.7), c + Vector2(0, 0), cc, w, true)
			ci.draw_line(c, c + Vector2(-r * 0.6, -r * 0.6), cc, w, true)
			ci.draw_line(c, c + Vector2(0, -r * 0.75), cc, w, true)
			ci.draw_line(c, c + Vector2(r * 0.6, -r * 0.6), cc, w, true)
		# ── 버티컬 슬라이스 지도 아이콘 (vs_assets.md 69 — 그림이 오기 전 코드로 그린 임시) ──
		"skull":
			# 강적: 해골 (둥근 머리 + 턱 + 눈구멍)
			ci.draw_circle(c + Vector2(0, -r * 0.12), r * 0.52, cc)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.3, r * 0.2), Vector2(r * 0.6, r * 0.38)), cc)
			var hole := Color(0.1, 0.02, 0.03, a)
			ci.draw_circle(c + Vector2(-r * 0.2, -r * 0.12), r * 0.14, hole)
			ci.draw_circle(c + Vector2(r * 0.2, -r * 0.12), r * 0.14, hole)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, r * 0.04), c + Vector2(-r * 0.07, r * 0.18), c + Vector2(r * 0.07, r * 0.18)]), hole)
			for k in 3:
				ci.draw_line(c + Vector2(-r * 0.18 + k * r * 0.18, r * 0.36), c + Vector2(-r * 0.18 + k * r * 0.18, r * 0.58), hole, maxf(1.0, w * 0.5), true)
		"spears":
			# 훈련: 교차한 창 두 자루
			for sgn in [-1.0, 1.0]:
				var d := Vector2.from_angle(-PI / 2 + sgn * PI / 4.6)
				var tip := c + d * r * 0.9
				var butt := c - d * r * 0.8
				ci.draw_line(butt, tip - d * r * 0.25, Color(0.62, 0.45, 0.3, a), w, true)
				var nn := Vector2(-d.y, d.x)
				ci.draw_colored_polygon(PackedVector2Array([tip, tip - d * r * 0.32 + nn * r * 0.13, tip - d * r * 0.32 - nn * r * 0.13]), cc)
		"coffin":
			# 거래: 관 + 동전
			var cp := PackedVector2Array([c + Vector2(-r * 0.22, -r * 0.75), c + Vector2(r * 0.22, -r * 0.75), c + Vector2(r * 0.4, -r * 0.35),
				c + Vector2(r * 0.26, r * 0.7), c + Vector2(-r * 0.26, r * 0.7), c + Vector2(-r * 0.4, -r * 0.35)])
			var loop := cp.duplicate()
			loop.append(cp[0])
			ci.draw_polyline(loop, cc, w, true)
			ci.draw_line(c + Vector2(0, -r * 0.45), c + Vector2(0, r * 0.2), cc, w * 0.8, true)
			ci.draw_line(c + Vector2(-r * 0.18, -r * 0.22), c + Vector2(r * 0.18, -r * 0.22), cc, w * 0.8, true)
			for k in 2:
				var cc2 := c + Vector2(r * 0.55, r * 0.35 + k * r * 0.22)
				ci.draw_circle(cc2, r * 0.2, Color(0.85, 0.68, 0.3, a))
				ci.draw_arc(cc2, r * 0.2, 0, TAU, 16, Color(0.4, 0.28, 0.1, a), 1.2, true)
		"eye":
			# 전조: 눈
			var up := PackedVector2Array()
			var dn := PackedVector2Array()
			for i in 17:
				var t := float(i) / 16.0
				var x := lerpf(-r * 0.85, r * 0.85, t)
				var yy := sin(t * PI) * r * 0.45
				up.append(c + Vector2(x, -yy))
				dn.append(c + Vector2(x, yy))
			ci.draw_polyline(up, cc, w, true)
			ci.draw_polyline(dn, cc, w, true)
			ci.draw_circle(c, r * 0.26, Color(0.85, 0.12, 0.18, a))
			ci.draw_circle(c, r * 0.1, Color(0.05, 0.0, 0.01, a))
		"foot":
			# 층의 끝(거대한 발): 발바닥 + 발가락
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.32, -r * 0.2), c + Vector2(r * 0.36, -r * 0.22), c + Vector2(r * 0.3, r * 0.5),
				c + Vector2(0, r * 0.78), c + Vector2(-r * 0.3, r * 0.5)]), cc)
			for k in 4:
				ci.draw_circle(c + Vector2(-r * 0.32 + k * r * 0.22, -r * 0.48 + absf(k - 1.5) * r * 0.08), r * (0.13 - k * 0.012), cc)
		_:
			ci.draw_circle(c, r * 0.3, cc)


static func _sword(ci: CanvasItem, c: Vector2, r: float, ang: float, col: Color, w: float) -> void:
	var d := Vector2.from_angle(ang)
	var n := Vector2(-d.y, d.x)
	var tip := c + d * r * 0.85
	var hilt := c - d * r * 0.45
	ci.draw_colored_polygon(PackedVector2Array([tip, hilt + n * w * 0.8, hilt - n * w * 0.8]), col)
	ci.draw_line(hilt + n * r * 0.32, hilt - n * r * 0.32, col, w, true)
	ci.draw_line(hilt, hilt - d * r * 0.32, Color(0.55, 0.38, 0.25, col.a), w * 1.2, true)
	ci.draw_circle(hilt - d * r * 0.36, w * 0.8, col)


## 길 위의 둥근 아이콘 테두리 (목업 11: 어두운 원 + 금 테두리 + 위아래 작은 마름모)
static func medallion(ci: CanvasItem, c: Vector2, r: float, kind: String, hot := 0.0, a := 1.0) -> void:
	var red := kind in ["swords", "sword", "skull", "foot"]
	var rim := Color("#c9a24a") if not red else Color("#c94a4a")
	if hot > 0:
		for i in 4:
			ci.draw_circle(c, r + 8 + i * 6, Color(1, 0.75, 0.4, 0.08 * hot * a))
	ci.draw_circle(c, r + 4, Color(0, 0, 0, 0.55 * a))
	ci.draw_circle(c, r, Color(0.08, 0.05, 0.05, 0.9 * a) if not red else Color(0.22, 0.03, 0.05, 0.9 * a))
	ci.draw_arc(c, r, 0, TAU, 48, Color(rim.r, rim.g, rim.b, a), 3.0, true)
	ci.draw_arc(c, r - 6, 0, TAU, 48, Color(rim.r, rim.g, rim.b, 0.35 * a), 1.5, true)
	for k in 4:
		var dir := Vector2.from_angle(k * PI / 2.0)
		var p := c + dir * (r + 2)
		var nn := Vector2(-dir.y, dir.x)
		ci.draw_colored_polygon(PackedVector2Array([p + dir * 9, p + nn * 5, p - dir * 4, p - nn * 5]), Color(rim.r, rim.g, rim.b, a))
		ci.draw_circle(p + dir * 2, 2.2, Color(0.8, 0.1, 0.15, a))
	var icol := Color("#ffd9b0") if kind == "flame" else (Color("#ffb0b0") if red else Color("#f0e6d8"))
	draw(ci, kind, c, r * (0.8 if red else 0.62), icol, a)


## 작은 돌판 한 칸 (왼쪽 가장자리 층 표시) — 마름모꼴 윗면 + 두께
static func stone_tile(ci: CanvasItem, c: Vector2, w: float, on: bool, locked: bool) -> void:
	var h := w * 0.42
	var top := PackedVector2Array([c + Vector2(-w / 2, 0), c + Vector2(0, -h / 2), c + Vector2(w / 2, 0), c + Vector2(0, h / 2)])
	var side := PackedVector2Array([c + Vector2(-w / 2, 0), c + Vector2(0, h / 2), c + Vector2(w / 2, 0), c + Vector2(w / 2, 6), c + Vector2(0, h / 2 + 6), c + Vector2(-w / 2, 6)])
	var base := Color("#5a5652") if not locked else Color("#2e2c2b")
	if on:
		base = Color("#b8b0a4")
		for i in 3:
			var g := PackedVector2Array()
			for p in top:
				g.append(c + (p - c) * (1.25 + i * 0.12))
			ci.draw_colored_polygon(g, Color(1, 0.85, 0.6, 0.1))
	ci.draw_colored_polygon(side, base.darkened(0.45))
	ci.draw_colored_polygon(top, base)
	var loop := top.duplicate()
	loop.append(top[0])
	ci.draw_polyline(loop, Color(0, 0, 0, 0.6) if not on else Color("#f6e7c8"), 1.5, true)
	ci.draw_line(c + Vector2(-w * 0.18, -h * 0.1), c + Vector2(w * 0.1, h * 0.12), Color(0, 0, 0, 0.25), 1.0, true)


## 죽음 표식: 붉은 실이 감긴 매듭. 마녀만 보는 표식 — 흐리게, 정체는 설명하지 않는다
static func death_mark(ci: CanvasItem, c: Vector2, r: float, t: float, a := 0.5) -> void:
	var k := 0.75 + 0.25 * sin(t * 1.7)
	for i in 3:
		ci.draw_circle(c, r * (1.2 + i * 0.35), Color(0.9, 0.05, 0.12, 0.06 * a * k))
	for j in 3:
		var ph := j * TAU / 3.0 + t * 0.4
		var pts := PackedVector2Array()
		for i in 25:
			var u := float(i) / 24.0 * TAU
			pts.append(c + Vector2(cos(u) * r, sin(u) * r * 0.42).rotated(ph))
		ci.draw_polyline(pts, Color(0.95, 0.12, 0.2, 0.7 * a * k), 2.0, true)
	ci.draw_circle(c, r * 0.18, Color(1, 0.2, 0.28, 0.85 * a * k))
	# 늘어진 실 끝
	var sw := sin(t * 1.3) * r * 0.2
	var tail := UI.quad_curve(c + Vector2(r * 0.15, r * 0.1), c + Vector2(r * 0.6 + sw, r * 0.8), c + Vector2(r * 0.3 + sw, r * 1.6), 12)
	ci.draw_polyline(tail, Color(0.9, 0.1, 0.18, 0.6 * a * k), 1.6, true)
