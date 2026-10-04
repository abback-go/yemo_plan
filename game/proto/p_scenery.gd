class_name PScenery
extends RefCounted
## 훈련장 배경 (마녀학교 밤의 훈련장 회랑). 정적인 층은 처음 한 번만 그리고(층마다 그리기 호출 1번),
## 움직이는 것(깃발·횃불 불꽃·불빛 떨림·떠다니는 불티·석등)만 매 프레임 그린다.
## 층(뒤 → 앞): 하늘(화면 고정) → 먼 산·학교(시차 0.25) → 가까운 지붕·탑(시차 0.55) → 회랑 벽(아치 창 너머로 뒤가 보임)
##             → 벽의 불빛(가산) → 깃발·횃불 → 지형(바닥·발판·굴뚝·석등·표지판) → [세라·허수아비·마법] → 떠다니는 불티 → 화면 가장자리 어둡게

const SKY_TOP := Color("#0b0719")
const SKY_MID := Color("#251538")
const SKY_LOW := Color("#57294c")
const WALL := Color("#2a2040")
const WALL_D := Color("#1d1530")
const WALL_L := Color("#3b2f56")
const JOINT := Color("#191226")
const STONE := Color("#3d3450")
const STONE_L := Color("#6e6286")
const STONE_D := Color("#262036")
const GOLD := Color("#c99a4a")
const BANNER := Color("#7a1f33")
const FLAME := Color("#ffb347")

const BAY := 240.0 ## 기둥 간격
const SPRING := 196.0 ## 아치 창 반원이 시작하는 높이
const ARCH_R := 60.0 ## 아치 창 반지름(= 반폭)
const SILL := 318.0 ## 창턱
const WAINSCOT := 334.0 ## 아래 판벽 시작
const TORCH_Y := 238.0


static func build(arena: Node2D, solids: Array[Rect2], lantern: Vector2) -> Dictionary:
	var W: float = arena.W
	var FLOOR: float = arena.FLOOR
	var CEIL: float = arena.CEIL
	# 하늘 (화면 고정)
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -10
	arena.add_child(sky_layer)
	sky_layer.add_child(SkyPaint.new())
	var tw := Twinkle.new()
	sky_layer.add_child(tw)
	# 먼 산·학교 / 가까운 지붕·탑
	for spec: Array in [[Vector2(0.25, 0.5), -9, Far.new()], [Vector2(0.55, 0.8), -8, Near.new()]]:
		var px := Parallax2D.new()
		px.scroll_scale = spec[0]
		px.z_index = spec[1]
		arena.add_child(px)
		px.add_child(spec[2])
	# 회랑 벽 (정적)
	var hall := Hall.new()
	hall.W = W
	hall.FLOOR = FLOOR
	hall.CEIL = CEIL
	hall.z_index = -7
	arena.add_child(hall)
	# 벽의 불빛 (가산, 동적)
	var glow := HallGlow.new()
	glow.W = W
	glow.FLOOR = FLOOR
	glow.lantern = lantern
	glow.z_index = -6
	glow.material = Fx.add_material
	arena.add_child(glow)
	# 창에서 떨어지는 달빛 줄기 (가산, 정적)
	var rays := MoonRays.new()
	rays.W = W
	rays.FLOOR = FLOOR
	rays.z_index = -6
	rays.material = Fx.add_material
	arena.add_child(rays)
	# 깃발·횃불 불꽃 (동적)
	var live := HallLive.new()
	live.W = W
	live.CEIL = CEIL
	live.lantern = lantern
	live.z_index = -5
	arena.add_child(live)
	# 지형 (정적)
	var ground := Ground.new()
	ground.solids = solids
	ground.W = W
	ground.FLOOR = FLOOR
	ground.CEIL = CEIL
	ground.lantern = lantern
	ground.z_index = -4
	arena.add_child(ground)
	# 떠다니는 불티 (가산, 동적, 앞)
	var motes := Motes.new()
	motes.W = W
	motes.FLOOR = FLOOR
	motes.z_index = 4
	motes.material = Fx.add_material
	arena.add_child(motes)
	# 화면 가장자리 어둡게
	var vl := CanvasLayer.new()
	vl.layer = 5
	arena.add_child(vl)
	var vg := Vignette.new()
	vl.add_child(vg)
	return {"live": live, "glow": glow, "motes": motes, "twinkle": tw, "vignette": vg}


static func torch_xs(W: float) -> Array[float]:
	var out: Array[float] = []
	var x := BAY
	while x < W - 10.0:
		out.append(x)
		x += BAY
	return out


# ═══════════════════════════════════════════════════════════
# 하늘 · 먼 층
# ═══════════════════════════════════════════════════════════

class SkyPaint extends PDraw.Canvas:
	func _paint() -> void:
		pd.rect_grad(Rect2(0, 0, 640, 150), SKY_TOP, SKY_MID)
		pd.rect_grad(Rect2(0, 150, 640, 130), SKY_MID, SKY_LOW)
		pd.rect_grad(Rect2(0, 280, 640, 80), SKY_LOW, Color("#2a1630"))
		# 은하수: 비스듬한 옅은 띠 + 잔별
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		for i in 140:
			var f := rng.randf()
			var p := Vector2(lerpf(-20, 660, f), lerpf(210, -10, f) + rng.randfn(0.0, 22.0))
			pd.draw_rect(Rect2(p, Vector2.ONE), Color(0.85, 0.8, 1.0, rng.randf_range(0.08, 0.35)))
		pd.draw_set_transform(Vector2(320, 100), -0.32, Vector2(1.0, 0.18))
		pd.glow(Vector2.ZERO, 360.0, Color(0.55, 0.42, 0.85, 0.16))
		pd.draw_set_transform(Vector2.ZERO)
		# 별
		for i in 90:
			var p := Vector2(rng.randf() * 640, rng.randf() * 230)
			var a := rng.randf_range(0.25, 0.9)
			pd.draw_rect(Rect2(p.floor(), Vector2.ONE), Color(1, 0.97, 0.9, a))
		# 달: 큰 빛무리 → 원반 → 무늬
		var m := Vector2(508, 74)
		pd.glow(m, 120.0, Color(1.0, 0.85, 0.75, 0.16))
		pd.glow(m, 44.0, Color(1.0, 0.92, 0.82, 0.22))
		pd.draw_circle(m, 21.0, Color("#f7ead0"))
		pd.draw_circle(m + Vector2(5, -3), 18.0, Color("#fff6e4"))
		for cr: Array in [[Vector2(-7, 4), 4.0], [Vector2(6, 9), 2.6], [Vector2(-2, -9), 2.2], [Vector2(9, -2), 1.6]]:
			pd.draw_circle(m + cr[0], cr[1], Color("#e3cfaa"))
		# 달 앞 얇은 구름
		for cl: Array in [[Vector2(470, 88), 70.0, 0.5], [Vector2(560, 64), 54.0, 0.4], [Vector2(150, 120), 110.0, 0.35], [Vector2(300, 60), 80.0, 0.25]]:
			pd.draw_set_transform(cl[0], 0.0, Vector2(1.0, 0.13))
			pd.glow(Vector2.ZERO, cl[1], Color(0.36, 0.22, 0.42, cl[2]), 0.0)
			pd.draw_set_transform(Vector2.ZERO)


## 반짝이는 큰 별 몇 개 (15번/초로만 다시 그림)
class Twinkle extends PDraw.Canvas:
	var t := 0.0
	var _acc := 0.0
	const STARS := [Vector2(60, 40), Vector2(170, 22), Vector2(262, 70), Vector2(390, 30), Vector2(610, 28), Vector2(110, 150), Vector2(430, 120)]

	func _process(delta: float) -> void:
		t += delta
		_acc += delta
		if _acc >= 1.0 / 15.0:
			_acc = 0.0
			queue_redraw()

	func _paint() -> void:
		for i in STARS.size():
			var p: Vector2 = STARS[i]
			var k := 0.5 + 0.5 * sin(t * (1.3 + i * 0.37) + i * 2.1)
			var a := 0.35 + 0.65 * k
			var l := 1.0 + 2.0 * k
			pd.draw_rect(Rect2(p - Vector2(l, 0), Vector2(l * 2 + 1, 1)), Color(1, 0.95, 0.85, a * 0.7))
			pd.draw_rect(Rect2(p - Vector2(0, l), Vector2(1, l * 2 + 1)), Color(1, 0.95, 0.85, a * 0.7))
			pd.draw_rect(Rect2(p, Vector2.ONE), Color(1, 1, 1, a))


## 먼 산맥과 마녀학교 본관 실루엣 (불 켜진 창, 첨탑 끝의 마법 등불)
class Far extends PDraw.Canvas:
	func _paint() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		# 산맥 두 겹
		for layer in 2:
			var col: Color = [Color("#35204a"), Color("#2a1840")][layer]
			var base_y: float = [176.0, 196.0][layer]
			var pts := PackedVector2Array([Vector2(-400, 400)])
			var x := -400.0
			while x < 1700.0:
				pts.append(Vector2(x, base_y - rng.randf_range(10, 60) * (1.0 - layer * 0.3)))
				x += rng.randf_range(40, 90)
			pts.append(Vector2(1700, 400))
			pd.draw_colored_polygon(pts, col)
			if layer == 0:
				for i in range(1, pts.size() - 1):
					pd.draw_line(pts[i], pts[i] + Vector2(6, 5), Color(0.75, 0.6, 0.9, 0.25), 1.0)
		# 학교 본관: 성벽 + 탑들
		var body := Color("#1f1232")
		var roof := Color("#170c27")
		pd.draw_rect(Rect2(160, 150, 760, 260), body)
		for i in 22:
			pd.draw_rect(Rect2(160 + i * 35, 144, 18, 8), body) # 성가퀴
		var towers := [[200.0, 34.0, 120.0], [330.0, 26.0, 84.0], [450.0, 46.0, 158.0], [560.0, 30.0, 104.0], [690.0, 40.0, 140.0], [820.0, 28.0, 92.0], [900.0, 22.0, 70.0]]
		for tw: Array in towers:
			var cx: float = tw[0]
			var w: float = tw[1]
			var h: float = tw[2]
			var top := 150.0 - h
			pd.draw_rect(Rect2(cx - w / 2, top, w, h + 10), body)
			var spire := top - w * 1.5
			pd.draw_colored_polygon(PackedVector2Array([Vector2(cx - w / 2 - 4, top), Vector2(cx, spire), Vector2(cx + w / 2 + 4, top)]), roof)
			pd.draw_line(Vector2(cx, spire), Vector2(cx, spire - 8), roof, 1.0)
			# 불 켜진 창
			var rows := int(h / 22.0)
			for r in rows:
				for k in 2:
					if rng.randf() < 0.55:
						var wx := cx - w * 0.25 + k * w * 0.5 - 2
						var wy := top + 12 + r * 22
						pd.draw_rect(Rect2(wx, wy, 4, 7), Color(1.0, 0.78, 0.42, 0.7))
						pd.glow(Vector2(wx + 2, wy + 3), 9.0, Color(1.0, 0.7, 0.35, 0.18))
		# 가장 높은 탑 끝의 푸른 여우불 등
		pd.glow(Vector2(450, 150 - 158 - 69 - 8), 26.0, Color(0.4, 0.7, 1.0, 0.35))
		pd.draw_circle(Vector2(450, 150 - 158 - 69 - 8), 2.5, Color(0.75, 0.92, 1.0))
		# 성벽 창 줄
		for i in 30:
			if rng.randf() < 0.5:
				pd.draw_rect(Rect2(176 + i * 25, 178 + (i % 3) * 30, 3, 5), Color(1.0, 0.78, 0.42, 0.5))
		# 아래 안개
		pd.rect_grad(Rect2(-400, 190, 2100, 40), Color(0.45, 0.25, 0.5, 0.0), Color(0.45, 0.25, 0.5, 0.35))
		pd.draw_rect(Rect2(-400, 230, 2100, 200), Color(0.27, 0.15, 0.33, 0.9))


## 가까운 지붕·탑·나무 (더 어둡고 크게)
class Near extends PDraw.Canvas:
	func _paint() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 23
		var col := Color("#140b20")
		var x := -300.0
		while x < 1500.0:
			var kind := rng.randi() % 3
			if kind == 0:
				# 뾰족 지붕 건물
				var w := rng.randf_range(60, 110)
				var h := rng.randf_range(30, 70)
				var top := 250.0 - h
				pd.draw_rect(Rect2(x, top, w, 200), col)
				pd.draw_colored_polygon(PackedVector2Array([Vector2(x - 6, top), Vector2(x + w * 0.5, top - w * 0.45), Vector2(x + w + 6, top)]), col)
				if rng.randf() < 0.7:
					pd.draw_rect(Rect2(x + w * 0.5 - 3, top + 12, 6, 9), Color(1.0, 0.7, 0.35, 0.55))
				x += w + rng.randf_range(10, 40)
			elif kind == 1:
				# 둥근 나무 무리
				var r := rng.randf_range(18, 30)
				for k in 3:
					pd.draw_circle(Vector2(x + k * r * 0.8, 236 - rng.randf_range(0, 18)), r, col)
				pd.draw_rect(Rect2(x - r, 236, r * 3.6, 200), col)
				x += r * 3.0 + rng.randf_range(10, 30)
			else:
				# 가는 탑
				var w := rng.randf_range(16, 24)
				var h := rng.randf_range(80, 120)
				pd.draw_rect(Rect2(x, 250 - h, w, 200), col)
				pd.draw_colored_polygon(PackedVector2Array([Vector2(x - 3, 250 - h), Vector2(x + w / 2, 250 - h - w * 1.6), Vector2(x + w + 3, 250 - h)]), col)
				pd.draw_rect(Rect2(x + w / 2 - 1.5, 250 - h + 14, 3, 5), Color(0.6, 0.85, 1.0, 0.6))
				x += w + rng.randf_range(30, 60)
		pd.rect_grad(Rect2(-300, 236, 1800, 30), Color(0.5, 0.28, 0.55, 0.0), Color(0.5, 0.28, 0.55, 0.28))


# ═══════════════════════════════════════════════════════════
# 회랑 벽 (아치 창 · 기둥 · 판벽 · 띠 장식)
# ═══════════════════════════════════════════════════════════

class Hall extends PDraw.Canvas:
	var W := 1440.0
	var FLOOR := 400.0
	var CEIL := 96.0

	func _paint() -> void:
		var x0 := 16.0
		var x1 := W - 16.0
		# 창마다: 창 사이 벽(피어) + 아치 위 벽(스팬드럴) + 창 아래 벽
		var bays := int(W / BAY)
		for b in bays:
			var cx := b * BAY + BAY * 0.5
			var l := cx - ARCH_R
			var r := cx + ARCH_R
			var bl := maxf(b * BAY, x0)
			var br := minf((b + 1) * BAY, x1)
			# 피어
			_wall(Rect2(bl, CEIL, l - bl, FLOOR - CEIL))
			_wall(Rect2(r, CEIL, br - r, FLOOR - CEIL))
			# 아치 위
			var sp := PackedVector2Array([Vector2(l, CEIL), Vector2(r, CEIL), Vector2(r, SPRING)])
			for i in 17:
				var a := float(i) / 16.0 * PI
				sp.append(Vector2(cx + cos(a) * ARCH_R, SPRING - sin(a) * ARCH_R))
			sp.append(Vector2(l, SPRING))
			pd.draw_colored_polygon(sp, WALL)
			_bricks(Rect2(l, CEIL, r - l, SPRING - CEIL), cx, true)
			# 창 아래
			_wall(Rect2(l, SILL, r - l, FLOOR - SILL))
			# 창: 옅은 유리 + 테두리 + 창살 + 쐐기돌
			var glass := PackedVector2Array([Vector2(l, SILL), Vector2(r, SILL), Vector2(r, SPRING)])
			for i in 17:
				var a := float(i) / 16.0 * PI
				glass.append(Vector2(cx + cos(a) * ARCH_R, SPRING - sin(a) * ARCH_R))
			glass.append(Vector2(l, SPRING))
			pd.draw_colored_polygon(glass, Color(0.55, 0.6, 1.0, 0.05))
			pd.draw_arc(Vector2(cx, SPRING), ARCH_R + 2.0, PI, TAU, 24, JOINT, 4.0)
			pd.draw_arc(Vector2(cx, SPRING), ARCH_R + 5.0, PI, TAU, 24, WALL_L, 2.0)
			pd.draw_rect(Rect2(l - 2, SPRING, 4, SILL - SPRING), JOINT)
			pd.draw_rect(Rect2(r - 2, SPRING, 4, SILL - SPRING), JOINT)
			pd.draw_rect(Rect2(cx - 1.5, SPRING - ARCH_R, 3, SILL - SPRING + ARCH_R), Color(JOINT, 0.9))
			pd.draw_rect(Rect2(l, SPRING + 30, r - l, 2), Color(JOINT, 0.9))
			pd.draw_arc(Vector2(cx, SPRING), ARCH_R * 0.5, PI, TAU, 12, Color(JOINT, 0.9), 2.0)
			pd.draw_colored_polygon(PackedVector2Array([Vector2(cx - 7, SPRING - ARCH_R - 8), Vector2(cx + 7, SPRING - ARCH_R - 8), Vector2(cx + 5, SPRING - ARCH_R + 4), Vector2(cx - 5, SPRING - ARCH_R + 4)]), WALL_L)
			# 창턱
			pd.draw_rect(Rect2(l - 6, SILL - 2, r - l + 12, 6), STONE)
			pd.draw_rect(Rect2(l - 6, SILL - 2, r - l + 12, 1), STONE_L)
			pd.draw_rect(Rect2(l - 6, SILL + 4, r - l + 12, 2), JOINT)
		# 위쪽 띠 장식 (천장 아래): 어두운 띠 + 금줄 + 여우 문양 점
		pd.draw_rect(Rect2(x0, CEIL, x1 - x0, 14), WALL_D)
		pd.draw_rect(Rect2(x0, CEIL + 14, x1 - x0, 1), Color(GOLD, 0.7))
		pd.draw_rect(Rect2(x0, CEIL + 16, x1 - x0, 1), Color(GOLD, 0.3))
		var x := x0 + 20.0
		while x < x1:
			pd.draw_colored_polygon(PackedVector2Array([Vector2(x, CEIL + 4), Vector2(x + 3, CEIL + 7), Vector2(x, CEIL + 10), Vector2(x - 3, CEIL + 7)]), Color(GOLD, 0.55))
			x += 40.0
		# 아래 판벽: 어두운 판 + 금 테 + 판 무늬
		pd.rect_grad(Rect2(x0, WAINSCOT, x1 - x0, FLOOR - WAINSCOT), Color("#21182f"), Color("#171021"))
		pd.draw_rect(Rect2(x0, WAINSCOT, x1 - x0, 2), Color(GOLD, 0.55))
		pd.draw_rect(Rect2(x0, WAINSCOT + 3, x1 - x0, 1), JOINT)
		x = x0 + 8.0
		while x < x1 - 40:
			pd.draw_rect(Rect2(x, WAINSCOT + 10, 52, FLOOR - WAINSCOT - 18), Color("#1a1226"))
			pd.draw_rect(Rect2(x, WAINSCOT + 10, 52, 1), Color(1, 1, 1, 0.05))
			x += 60.0
		# 기둥 (창 사이): 주춧돌 + 몸통(빛·그늘) + 머리 장식
		for px in PScenery.torch_xs(W):
			pd.draw_rect(Rect2(px - 13, CEIL + 14, 26, FLOOR - CEIL - 14), STONE_D)
			pd.rect_hgrad(Rect2(px - 11, CEIL + 22, 22, FLOOR - CEIL - 40), Color("#4a3f62"), Color("#2b2440"))
			pd.draw_rect(Rect2(px - 11, CEIL + 22, 2, FLOOR - CEIL - 40), Color(1, 1, 1, 0.08))
			for k in 4:
				pd.draw_rect(Rect2(px - 6 + k * 4, CEIL + 30, 1, FLOOR - CEIL - 60), Color(0, 0, 0, 0.18))
			pd.draw_rect(Rect2(px - 16, CEIL + 14, 32, 8), STONE)
			pd.draw_rect(Rect2(px - 16, CEIL + 14, 32, 1), STONE_L)
			pd.draw_rect(Rect2(px - 16, FLOOR - 18, 32, 18), STONE)
			pd.draw_rect(Rect2(px - 16, FLOOR - 18, 32, 1), STONE_L)
			# 횃불 받침 (쇠)
			pd.draw_rect(Rect2(px - 5, TORCH_Y + 4, 10, 3), Color("#2a2430"))
			pd.draw_colored_polygon(PackedVector2Array([Vector2(px - 6, TORCH_Y - 2), Vector2(px + 6, TORCH_Y - 2), Vector2(px + 3, TORCH_Y + 5), Vector2(px - 3, TORCH_Y + 5)]), Color("#3a3240"))
			pd.draw_line(Vector2(px, TORCH_Y + 7), Vector2(px, TORCH_Y + 16), Color("#2a2430"), 2.0)
		# 무기 걸이 (허수아비 마당 왼쪽 벽): 나무 막대 + 지팡이·목검
		var rx := 196.0
		pd.draw_rect(Rect2(rx, FLOOR - 52, 46, 3), Color("#4a3020"))
		pd.draw_rect(Rect2(rx, FLOOR - 30, 46, 3), Color("#4a3020"))
		for k in 4:
			var sx := rx + 6 + k * 11
			pd.draw_line(Vector2(sx, FLOOR - 62), Vector2(sx + 1, FLOOR - 6), Color("#7a5530") if k % 2 == 0 else Color("#8a8a96"), 2.0)
			if k % 2 == 1:
				pd.draw_rect(Rect2(sx - 2, FLOOR - 40, 6, 2), Color("#5a4630"))
			else:
				pd.draw_circle(Vector2(sx, FLOOR - 63), 2.4, Color("#a35adf"))

	func _wall(r: Rect2) -> void:
		if r.size.x <= 0.0 or r.size.y <= 0.0:
			return
		pd.rect_grad(r, WALL_D, WALL)
		_bricks(r, r.get_center().x, false)

	## 벽돌 줄눈 (가로 줄 + 엇갈린 세로 줄 + 군데군데 밝은 돌)
	func _bricks(r: Rect2, seed_x: float, under_arch: bool) -> void:
		var y := r.position.y + 8.0
		var row := 0
		while y < r.end.y - 2.0:
			pd.draw_rect(Rect2(r.position.x, y, r.size.x, 1), JOINT)
			var off := 0.0 if row % 2 == 0 else 9.0
			var x := r.position.x + off
			while x < r.end.x - 2.0:
				var ok := true
				if under_arch:
					var d := Vector2(x - seed_x, y - SPRING)
					ok = d.length() > ARCH_R + 6.0
				if ok:
					pd.draw_rect(Rect2(x, y - 8, 1, 8), JOINT)
					if int(x * 7.0 + y * 13.0) % 11 == 0:
						pd.draw_rect(Rect2(x + 1, y - 7, 16, 6), Color(1, 1, 1, 0.035))
				x += 18.0
			y += 9.0
			row += 1


# ═══════════════════════════════════════════════════════════
# 움직이는 것: 벽의 불빛(가산) · 깃발·횃불 · 불티
# ═══════════════════════════════════════════════════════════

## 아치 창마다 바닥으로 비스듬히 떨어지는 옅은 달빛 (한 번만 그림)
class MoonRays extends PDraw.Canvas:
	var W := 1440.0
	var FLOOR := 400.0

	func _paint() -> void:
		var moon := Color(0.62, 0.6, 1.0)
		var bays := int(W / BAY)
		for b in bays:
			var cx := b * BAY + BAY * 0.5
			var top_l := Vector2(cx - ARCH_R * 0.8, SPRING - 20)
			var top_r := Vector2(cx + ARCH_R * 0.8, SPRING - 20)
			var slant := 70.0
			var bot_l := Vector2(cx - ARCH_R * 0.8 + slant, FLOOR)
			var bot_r := Vector2(cx + ARCH_R * 1.2 + slant, FLOOR)
			pd.convex_colors(PackedVector2Array([top_l, top_r, bot_r, bot_l]), PackedColorArray([Color(moon, 0.07), Color(moon, 0.07), Color(moon, 0.0), Color(moon, 0.0)]))
			# 바닥에 고인 달빛
			pd.draw_set_transform(Vector2(cx + slant + ARCH_R * 0.2, FLOOR + 1), 0.0, Vector2(1.0, 0.12))
			pd.glow(Vector2.ZERO, ARCH_R * 1.2, Color(moon, 0.1))
			pd.draw_set_transform(Vector2.ZERO)


## 횃불·석등이 벽에 비추는 따뜻한 빛 (떨림)
class HallGlow extends PDraw.Canvas:
	var W := 1440.0
	var FLOOR := 400.0
	var lantern := Vector2.ZERO
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _paint() -> void:
		var view := PScenery.view_of(self)
		for px in PScenery.torch_xs(W):
			if px < view.position.x - 120 or px > view.end.x + 120:
				continue
			var f := PScenery.flicker(t, px)
			pd.glow(Vector2(px, TORCH_Y - 8), 90.0 + 8.0 * f, Color(1.0, 0.55, 0.22, 0.13 + 0.04 * f))
			pd.glow(Vector2(px, TORCH_Y - 8), 30.0, Color(1.0, 0.7, 0.35, 0.18 + 0.06 * f))
			pd.glow(Vector2(px, FLOOR), 60.0, Color(1.0, 0.5, 0.2, 0.06 + 0.02 * f))
		var g := 0.7 + 0.3 * sin(t * 5.0)
		pd.glow(lantern + Vector2(0, -28), 46.0, Color(PData.FOX_MID, 0.16 * g))
		pd.glow(lantern + Vector2(0, -28), 14.0, Color(PData.FOX_HOT, 0.35 * g))


## 깃발(흔들림) · 횃불 불꽃 · 석등 불 · "↑ 쉬기" 안내
class HallLive extends PDraw.Canvas:
	var W := 1440.0
	var CEIL := 96.0
	var lantern := Vector2.ZERO
	var sera: Node2D
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _paint() -> void:
		var view := PScenery.view_of(self)
		for px in PScenery.torch_xs(W):
			if px < view.position.x - 60 or px > view.end.x + 60:
				continue
			# 깃발: 기둥 머리 아래로 길게, 끝이 제비꼬리
			var sway := sin(t * 1.4 + px * 0.01) * 2.0
			var top := CEIL + 24.0
			var h := 74.0
			var bw := 9.0
			var pts := PackedVector2Array([Vector2(px - bw, top), Vector2(px + bw, top), Vector2(px + bw + sway, top + h),
				Vector2(px + sway, top + h - 9), Vector2(px - bw + sway, top + h)])
			pd.draw_colored_polygon(pts, BANNER)
			pd.draw_colored_polygon(PackedVector2Array([Vector2(px - bw, top), Vector2(px - bw + 3, top), Vector2(px - bw + 3 + sway, top + h - 2), Vector2(px - bw + sway, top + h)]), Color("#5a1424"))
			pd.draw_rect(Rect2(px - bw - 2, top - 2, bw * 2 + 4, 3), Color("#4a3020"))
			pd.draw_line(Vector2(px - bw + 2, top + 4), Vector2(px - bw + 2 + sway * 0.9, top + h - 4), Color(GOLD, 0.7), 1.0)
			pd.draw_line(Vector2(px + bw - 2, top + 4), Vector2(px + bw - 2 + sway * 0.9, top + h - 4), Color(GOLD, 0.7), 1.0)
			# 여우 머리 문장
			var e := Vector2(px + sway * 0.4, top + 30)
			pd.draw_colored_polygon(PackedVector2Array([e + Vector2(-5, -3), e + Vector2(-4, -9), e + Vector2(-1, -4), e + Vector2(1, -4), e + Vector2(4, -9), e + Vector2(5, -3), e + Vector2(0, 5)]), Color("#f3d79a"))
			pd.draw_rect(Rect2(e + Vector2(-3, -2), Vector2(1, 1)), BANNER)
			pd.draw_rect(Rect2(e + Vector2(2, -2), Vector2(1, 1)), BANNER)
			# 횃불 불꽃 (세 겹 혀)
			var f := PScenery.flicker(t, px)
			var fb := Vector2(px, TORCH_Y - 2)
			for layer in 3:
				var hh: float = [13.0, 9.0, 5.0][layer] * (0.85 + 0.25 * f)
				var ww: float = [5.0, 3.6, 2.0][layer]
				var col: Color = [Color("#c8401a"), FLAME, Color("#fff1c0")][layer]
				var lean := sin(t * 9.0 + px + layer) * 1.5
				pd.draw_colored_polygon(PackedVector2Array([fb + Vector2(-ww, 0), fb + Vector2(-ww * 0.6 + lean * 0.5, -hh * 0.5), fb + Vector2(lean, -hh),
					fb + Vector2(ww * 0.6 + lean * 0.5, -hh * 0.5), fb + Vector2(ww, 0), fb + Vector2(0, 2)]), col)
		# 석등 불 (푸른 여우불)
		var g := 0.7 + 0.3 * sin(t * 5.0)
		var lp := lantern + Vector2(0, -28)
		pd.draw_circle(lp, 3.0 + g, Color(PData.FOX_MID, 0.8))
		pd.draw_circle(lp + Vector2(0, -1), 1.8 + g * 0.6, PData.FOX_CORE)

	func _draw() -> void:
		super()
		if sera and sera.global_position.distance_to(lantern) < 26.0:
			PScenery.label(self, lantern + Vector2(-16, -52), "↑ 쉬기", 1.0)


## 떠다니는 불티와 먼지 (상태 없이 시간만으로 위치를 계산)
class Motes extends PDraw.Canvas:
	var W := 1440.0
	var FLOOR := 400.0
	var t := 0.0
	const N := 44

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _paint() -> void:
		var view := PScenery.view_of(self).grow(10)
		for i in N:
			var bx := fmod(float(i) * 197.3, W)
			var speed := 6.0 + float(i % 5) * 3.0
			var y := FLOOR - fmod(t * speed + float(i) * 53.0, 290.0)
			var x := bx + sin(t * 0.6 + i) * 14.0 + sin(t * 1.7 + i * 0.3) * 4.0
			var p := Vector2(x, y)
			if not view.has_point(p):
				continue
			var life := 1.0 - (FLOOR - y) / 290.0
			var ember := i % 3 == 0
			var a := sin(life * PI) * (0.55 if ember else 0.22)
			var col := Color(1.0, 0.6, 0.25, a) if ember else Color(0.8, 0.75, 1.0, a)
			pd.draw_rect(Rect2(p, Vector2.ONE), col)
			if ember:
				pd.glow(p + Vector2(0.5, 0.5), 3.5, Color(1.0, 0.5, 0.2, a * 0.4))


# ═══════════════════════════════════════════════════════════
# 지형 (바닥·천장·옆벽·발판·굴뚝) · 석등 · 표지판
# ═══════════════════════════════════════════════════════════

class Ground extends PDraw.Canvas:
	var solids: Array[Rect2] = []
	var W := 1440.0
	var FLOOR := 400.0
	var CEIL := 96.0
	var lantern := Vector2.ZERO

	func _paint() -> void:
		for r in solids:
			if r.size.x > W:
				if r.position.y >= FLOOR - 1.0:
					_floor(r)
				else:
					_ceiling(r)
			elif r.size.y > 200.0 and (r.position.x < 20.0 or r.position.x > W - 20.0):
				_side_wall(r)
			else:
				_block(r)
		_lantern()
		_sign(Vector2(296, FLOOR - 92), "허수아비 마당")
		_sign(Vector2(786, 350), "벽 점프 굴뚝 →")

	func _draw() -> void:
		super()
		PScenery.label(self, Vector2(296, FLOOR - 92) + Vector2(-34, 4), "허수아비 마당", 0.85)
		PScenery.label(self, Vector2(786, 350) + Vector2(-36, 4), "벽 점프 굴뚝 →", 0.85)

	func _floor(r: Rect2) -> void:
		pd.rect_grad(Rect2(r.position.x, FLOOR, r.size.x, 90), Color("#3a3150"), Color("#120c1c"))
		pd.draw_rect(Rect2(r.position.x, FLOOR, r.size.x, 3), Color("#8a7ca8"))
		pd.draw_rect(Rect2(r.position.x, FLOOR + 3, r.size.x, 2), Color("#4f4468"))
		# 바닥 판석: 두 줄, 엇갈림 + 깨진 금
		for row in 2:
			var y := FLOOR + 5.0 + row * 14.0
			pd.draw_rect(Rect2(r.position.x, y + 13, r.size.x, 1), Color(0, 0, 0, 0.35))
			var x := r.position.x + (0.0 if row == 0 else 24.0)
			var i := 0
			while x < r.end.x:
				pd.draw_rect(Rect2(x, y, 1, 13), Color(0, 0, 0, 0.3))
				pd.draw_rect(Rect2(x + 1, y, 46, 1), Color(1, 1, 1, 0.05))
				if (i * 7 + row * 3) % 9 == 0:
					pd.draw_line(Vector2(x + 14, y + 2), Vector2(x + 20, y + 8), Color(0, 0, 0, 0.3), 1.0)
					pd.draw_line(Vector2(x + 20, y + 8), Vector2(x + 18, y + 12), Color(0, 0, 0, 0.3), 1.0)
				x += 48.0
				i += 1
		# 이끼·풀 조금
		var x2 := r.position.x + 30.0
		while x2 < r.end.x:
			if int(x2) % 7 < 3:
				for k in 3:
					pd.draw_line(Vector2(x2 + k * 2, FLOOR), Vector2(x2 + k * 2 + 1, FLOOR - 2 - k % 2), Color(0.35, 0.55, 0.4, 0.6), 1.0)
			x2 += 83.0

	func _ceiling(r: Rect2) -> void:
		pd.rect_grad(r, Color("#0c0814"), Color("#1d1428"))
		# 들보
		var x := r.position.x
		while x < r.end.x:
			pd.draw_rect(Rect2(x, r.position.y, 16, r.size.y), Color("#241a30"))
			pd.draw_rect(Rect2(x, r.end.y - 6, 16, 6), Color("#33264a"))
			pd.draw_rect(Rect2(x, r.end.y - 6, 16, 1), Color(1, 1, 1, 0.08))
			x += 120.0
		pd.draw_rect(Rect2(r.position.x, r.end.y - 2, r.size.x, 2), Color("#3b2f56"))

	func _side_wall(r: Rect2) -> void:
		pd.rect_grad(r, Color("#2e2640"), Color("#1a1426"))
		var y := r.position.y + 6.0
		var row := 0
		while y < r.end.y:
			pd.draw_rect(Rect2(r.position.x, y, r.size.x, 1), JOINT)
			var x := r.position.x + (0.0 if row % 2 == 0 else 10.0)
			while x < r.end.x:
				pd.draw_rect(Rect2(x, y - 12, 1, 12), JOINT)
				x += 20.0
			y += 12.0
			row += 1
		var inner_x := r.end.x - 2.0 if r.position.x < 20.0 else r.position.x
		pd.draw_rect(Rect2(inner_x, r.position.y, 2, r.size.y), Color("#4a3f62"))

	## 발판·굴뚝 벽: 돌 블록 (위 밝은 면 + 아래 그늘 + 줄눈)
	func _block(r: Rect2) -> void:
		pd.draw_rect(r.grow(1), Color("#120c1a"))
		pd.rect_grad(r, Color("#4a4062"), Color("#2a2340"))
		pd.draw_rect(Rect2(r.position, Vector2(r.size.x, 3)), Color("#8a7ca8"))
		pd.draw_rect(Rect2(r.position + Vector2(0, 3), Vector2(r.size.x, 1)), Color("#5a4f78"))
		pd.draw_rect(Rect2(r.position.x, r.end.y - 2, r.size.x, 2), Color(0, 0, 0, 0.35))
		if r.size.y > 20.0:
			var y := r.position.y + 12.0
			var row := 0
			while y < r.end.y - 2:
				pd.draw_rect(Rect2(r.position.x, y, r.size.x, 1), JOINT)
				var x := r.position.x + (4.0 if row % 2 == 0 else 10.0)
				while x < r.end.x - 1:
					pd.draw_rect(Rect2(x, y - 11, 1, 11), JOINT)
					x += 12.0
				y += 12.0
				row += 1
		else:
			var x := r.position.x + 18.0
			while x < r.end.x - 4:
				pd.draw_rect(Rect2(x, r.position.y + 4, 1, r.size.y - 5), JOINT)
				x += 24.0

	func _lantern() -> void:
		var l := lantern
		var st := Color("#7d8191")
		var st_d := Color("#5b5f6b")
		var st_l := Color("#a3a8b8")
		pd.draw_rect(Rect2(l + Vector2(-10, -6), Vector2(20, 6)), st_d)
		pd.draw_rect(Rect2(l + Vector2(-10, -6), Vector2(20, 1)), st_l)
		pd.draw_rect(Rect2(l + Vector2(-3, -22), Vector2(6, 16)), st)
		pd.draw_rect(Rect2(l + Vector2(-3, -22), Vector2(1, 16)), st_l)
		pd.draw_colored_polygon(PackedVector2Array([l + Vector2(-10, -22), l + Vector2(10, -22), l + Vector2(7, -35), l + Vector2(-7, -35)]), st)
		pd.draw_rect(Rect2(l + Vector2(-4, -32), Vector2(8, 8)), Color("#141826"))
		pd.draw_colored_polygon(PackedVector2Array([l + Vector2(-14, -35), l + Vector2(14, -35), l + Vector2(0, -45)]), st_d)
		pd.draw_line(l + Vector2(-14, -35), l + Vector2(0, -45), st_l, 1.0)
		# 여우 귀 장식 + 붉은 줄
		pd.draw_colored_polygon(PackedVector2Array([l + Vector2(-5, -44), l + Vector2(-3, -50), l + Vector2(-1, -45)]), st)
		pd.draw_colored_polygon(PackedVector2Array([l + Vector2(5, -44), l + Vector2(3, -50), l + Vector2(1, -45)]), st)
		pd.draw_rect(Rect2(l + Vector2(-8, -20), Vector2(16, 2)), Color("#b8323a"))
		pd.draw_rect(Rect2(l + Vector2(-2, -18), Vector2(1, 6)), Color("#b8323a"))
		pd.draw_rect(Rect2(l + Vector2(2, -18), Vector2(1, 5)), Color("#b8323a"))

	## 벽에 박은 나무 표지판 (글자는 _draw에서)
	func _sign(c: Vector2, _s: String) -> void:
		var r := Rect2(c + Vector2(-40, -6), Vector2(80, 14))
		pd.draw_line(c + Vector2(-26, -12), c + Vector2(-30, -6), Color("#3a2a20"), 1.0)
		pd.draw_line(c + Vector2(26, -12), c + Vector2(30, -6), Color("#3a2a20"), 1.0)
		pd.draw_rect(r.grow(1), Color("#1e140e"))
		pd.draw_rect(r, Color("#6a4a30"))
		pd.draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), Color("#8a6a48"))
		pd.draw_rect(Rect2(r.position.x, r.end.y - 2, r.size.x, 2), Color("#4a3020"))


## 화면 가장자리를 어둡게 (시선을 가운데로)
## 체력이 1칸 이하면 가장자리가 붉게 맥동한다 (그때만 매 프레임 다시 그림)
class Vignette extends PDraw.Canvas:
	var sera: PSera
	var t := 0.0
	var _was := false

	func _process(delta: float) -> void:
		t += delta
		var danger := is_instance_valid(sera) and sera.hp2 <= 2 and sera.hp2 > 0
		if danger or _was:
			queue_redraw()
		_was = danger

	func _paint() -> void:
		pd.ring_grad(Vector2(320, 186), Vector2(250, 140), Vector2(470, 300), Color(0.02, 0.0, 0.05, 0.0), Color(0.02, 0.0, 0.05, 0.55), 40)
		if is_instance_valid(sera) and sera.hp2 <= 2 and sera.hp2 > 0:
			var beat := pow(maxf(sin(t * 5.5), 0.0), 3.0)
			pd.ring_grad(Vector2(320, 180), Vector2(230, 120), Vector2(420, 260), Color(0.6, 0.0, 0.05, 0.0), Color(0.6, 0.02, 0.06, 0.25 + 0.25 * beat), 40)


# ═══════════════════════════════════════════════════════════

static func flicker(t: float, seed_x: float) -> float:
	return 0.5 + 0.3 * sin(t * 11.0 + seed_x) + 0.2 * sin(t * 23.0 + seed_x * 1.7)


## 지금 화면에 보이는 영역 (월드 좌표)
static func view_of(ci: CanvasItem) -> Rect2:
	var xf := ci.get_viewport().get_canvas_transform().affine_inverse()
	return Rect2(xf * Vector2.ZERO, ci.get_viewport().get_visible_rect().size)


static func label(ci: CanvasItem, p: Vector2, s: String, a: float) -> void:
	var f := ThemeDB.fallback_font
	ci.draw_string(f, p + Vector2(1, 1), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0, 0, 0, 0.7 * a))
	ci.draw_string(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 0.9, 0.7, 0.9 * a))
