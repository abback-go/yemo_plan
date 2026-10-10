class_name EScenery
extends RefCounted
## 에스카 시제품 배경: 마녀 분위기의 일자형 마당.
## 보랏빛 안개 하늘 · 떠 있는 고딕 첨탑들(대표 일러스트 배경) · 무너진 아치 기둥 · 보라 촛불 · 떠다니는 흰 빛 입자.
## 멀리 있는 층은 Parallax2D로 느리게 움직인다. 정적인 층은 한 번만 그린다(움직이는 것은 촛불·빛 입자·안개 덩이뿐).
## 깊이: 하늘(화면 고정) → 먼 첨탑 → 가까운 첨탑 → 빛줄기 → 안개 → 기둥·바닥 → [캐릭터] → 빛 입자 → 전경 실루엣(빠르게 지나감)

const SKY_TOP := Color("#07050c")
const SKY_BOT := Color("#1d1430")
const FAR := Color("#160f22")
const MID := Color("#100b19")
const NEAR := Color("#0b0811")
const MIST := Color("#5a4290")
const STONE := Color("#141019")
const STONE_TOP := Color("#2c2438")
const CRACK := Color("#8a74c4")


static func build(root: Node2D, width: float, floor_y: float) -> void:
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -10
	root.add_child(sky_layer)
	var sky := SkyBack.new()
	sky_layer.add_child(sky)
	for spec: Array in [[0.12, FAR, 0.55, 1], [0.3, MID, 0.8, 2]]:
		var px := Parallax2D.new()
		px.scroll_scale = Vector2(float(spec[0]), float(spec[0]) * 0.5)
		px.z_index = -8 + int(spec[3])
		root.add_child(px)
		var sp := Spires.new()
		sp.col = spec[1]
		sp.scale_k = float(spec[2])
		sp.seed_n = int(spec[3])
		sp.width = width
		sp.floor_y = floor_y
		px.add_child(sp)
	var shaft_px := Parallax2D.new()
	shaft_px.scroll_scale = Vector2(0.2, 0.1)
	shaft_px.z_index = -6
	root.add_child(shaft_px)
	var shafts := Shafts.new()
	shafts.floor_y = floor_y
	shafts.width = width
	shafts.material = Fx.add_material
	shaft_px.add_child(shafts)
	var mist_px := Parallax2D.new()
	mist_px.scroll_scale = Vector2(0.5, 0.3)
	mist_px.z_index = -5
	root.add_child(mist_px)
	var mist := Mist.new()
	mist.width = width
	mist.floor_y = floor_y
	mist_px.add_child(mist)
	var ground := Ground.new()
	ground.width = width
	ground.floor_y = floor_y
	ground.z_index = -2
	root.add_child(ground)
	var candles := Candles.new()
	candles.floor_y = floor_y
	candles.z_index = -1
	root.add_child(candles)
	var fog := Fog.new()
	fog.width = width
	fog.floor_y = floor_y
	fog.z_index = 2
	root.add_child(fog)
	var front_px := Parallax2D.new()
	front_px.scroll_scale = Vector2(1.35, 1.0)
	front_px.z_index = 12
	root.add_child(front_px)
	var front := Foreground.new()
	front.width = width
	front.floor_y = floor_y
	front_px.add_child(front)
	var motes := Motes.new()
	motes.width = width
	motes.floor_y = floor_y
	motes.z_index = 9
	motes.material = Fx.add_material
	root.add_child(motes)


## 화면 고정 하늘: 위는 거의 검정, 아래로 보랏빛 + 멀리 희미한 공허의 빛
class SkyBack extends PDraw.Canvas:
	func _paint() -> void:
		pd.rect_grad(Rect2(0, 0, 640, 360), SKY_TOP, SKY_BOT)
		pd.glow(Vector2(470, 120), 150.0, Color(0.55, 0.42, 0.85, 0.16), 0.0)
		pd.glow(Vector2(470, 120), 40.0, Color(0.92, 0.88, 1.0, 0.18), 0.0)
		pd.glow(Vector2(140, 300), 220.0, Color(0.35, 0.22, 0.6, 0.18), 0.0)


## 떠 있는 고딕 첨탑 실루엣 (창에 희미한 보라 불빛, 아래로 매달린 바위)
class Spires extends PDraw.Canvas:
	var col := FAR
	var scale_k := 0.6
	var seed_n := 1
	var width := 1280.0
	var floor_y := 300.0

	func _paint() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7700 + seed_n
		var x := -120.0
		while x < width * 0.6 + 640.0:
			var s := scale_k * rng.randf_range(0.7, 1.25)
			var base_y := floor_y - rng.randf_range(90.0, 170.0) * (1.6 - scale_k)
			_spire(Vector2(x, base_y), s, rng)
			x += rng.randf_range(110.0, 190.0) * scale_k
		# 땅에 닿은 먼 성채 띠
		var band := PackedVector2Array([Vector2(-200, floor_y + 10)])
		var bx := -200.0
		while bx < width + 400.0:
			var h := rng.randf_range(30.0, 70.0) * scale_k
			band.append(Vector2(bx, floor_y - h))
			band.append(Vector2(bx + 14.0, floor_y - h - rng.randf_range(8.0, 30.0) * scale_k))
			band.append(Vector2(bx + 28.0, floor_y - h))
			bx += rng.randf_range(40.0, 90.0)
		band.append(Vector2(bx, floor_y + 10))
		pd.draw_colored_polygon(band, col.darkened(0.15))

	func _spire(p: Vector2, s: float, rng: RandomNumberGenerator) -> void:
		var w := 26.0 * s
		var h := 90.0 * s
		# 떠 있는 바위 덩이
		var rock := PackedVector2Array([p + Vector2(-w * 1.1, 0), p + Vector2(w * 1.1, 0), p + Vector2(w * 0.6, 18 * s),
			p + Vector2(w * 0.15, 40 * s), p + Vector2(-w * 0.3, 26 * s), p + Vector2(-w * 0.8, 12 * s)])
		pd.draw_colored_polygon(rock, col)
		# 몸체 + 뾰족 지붕 + 작은 곁탑
		pd.draw_rect(Rect2(p + Vector2(-w * 0.5, -h), Vector2(w, h)), col)
		pd.draw_colored_polygon(PackedVector2Array([p + Vector2(-w * 0.62, -h), p + Vector2(w * 0.62, -h), p + Vector2(0, -h - 46 * s)]), col)
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var sw := w * 0.45
		var sx := p.x + side * w * 0.72
		pd.draw_rect(Rect2(Vector2(sx - sw * 0.5, p.y - h * 0.62), Vector2(sw, h * 0.62)), col)
		pd.draw_colored_polygon(PackedVector2Array([Vector2(sx - sw * 0.7, p.y - h * 0.62), Vector2(sx + sw * 0.7, p.y - h * 0.62), Vector2(sx, p.y - h * 0.62 - 26 * s)]), col)
		# 창 불빛
		for i in 3:
			if rng.randf() < 0.6:
				var wy := p.y - h * (0.25 + 0.22 * float(i))
				pd.draw_rect(Rect2(Vector2(p.x - 1.5 * s, wy), Vector2(3.0 * s, 5.0 * s)), Color(0.66, 0.55, 1.0, 0.35 + 0.2 * scale_k))


## 보랏빛 안개 띠
class Mist extends PDraw.Canvas:
	var width := 1280.0
	var floor_y := 300.0

	func _paint() -> void:
		for i in 3:
			var y := floor_y - 30.0 - float(i) * 34.0
			pd.rect_grad(Rect2(-400, y - 26, width + 1200, 26), Color(MIST, 0.0), Color(MIST, 0.12 - 0.03 * float(i)))
			pd.rect_grad(Rect2(-400, y, width + 1200, 22), Color(MIST, 0.12 - 0.03 * float(i)), Color(MIST, 0.0))


## 바닥 돌판 · 무너진 아치 기둥 (정적 — 한 번만 그림)
class Ground extends PDraw.Canvas:
	var width := 1280.0
	var floor_y := 300.0

	func _paint() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 4242
		# 기둥과 아치 (뒤) — 이웃한 기둥끼리 아치로 잇는다 (한쪽이 무너졌으면 잇지 않음)
		var xs: Array[float] = []
		var hs: Array[float] = []
		var broken: Array[bool] = []
		var x := 80.0
		while x < width:
			xs.append(x)
			hs.append(rng.randf_range(100.0, 150.0))
			broken.append(rng.randf() < 0.35)
			x += rng.randf_range(150.0, 220.0)
		for i in xs.size():
			var px: float = xs[i]
			var ph: float = hs[i]
			var top := floor_y - ph
			pd.draw_rect(Rect2(px - 7, top, 14, ph), NEAR)
			pd.draw_rect(Rect2(px - 10, top - 4, 20, 5), NEAR)
			pd.draw_rect(Rect2(px - 9, floor_y - 6, 18, 6), NEAR)
			pd.draw_line(Vector2(px - 3, top + 4), Vector2(px - 3, floor_y - 8), Color(STONE_TOP, 0.35), 1.0)
			if broken[i]:
				pd.draw_colored_polygon(PackedVector2Array([Vector2(px - 10, top - 4), Vector2(px + 10, top - 4), Vector2(px + 4, top - 14), Vector2(px - 2, top - 8)]), NEAR)
			elif i + 1 < xs.size() and not broken[i + 1]:
				var nx: float = xs[i + 1]
				var ny := floor_y - minf(ph, hs[i + 1])
				var rad := (nx - px) * 0.5
				pd.draw_arc(Vector2(px + rad, ny), rad, PI, TAU, 28, NEAR, 6.0)
		# 바닥
		pd.draw_rect(Rect2(-60, floor_y, width + 120, 80), STONE)
		pd.draw_rect(Rect2(-60, floor_y, width + 120, 2), STONE_TOP)
		var bx := -60.0
		while bx < width + 60.0:
			pd.draw_line(Vector2(bx, floor_y + 2), Vector2(bx, floor_y + 12), Color(0, 0, 0, 0.5), 1.0)
			bx += rng.randf_range(28.0, 52.0)
		# 바닥의 희미한 흰 금
		for i in 7:
			var cx := rng.randf_range(0, width)
			var pts := PackedVector2Array([Vector2(cx, floor_y + 1)])
			var p := Vector2(cx, floor_y + 1)
			for s in 4:
				p += Vector2(rng.randf_range(4, 12), rng.randf_range(1, 4))
				pts.append(p)
			pd.draw_polyline(pts, Color(CRACK, 0.3), 1.0)


## 떠다니는 흰 빛 입자 (천천히 위로)
class Motes extends PDraw.Canvas:
	var width := 1280.0
	var floor_y := 300.0
	var _p := PackedVector2Array()
	var _ph := PackedFloat32Array()

	func _ready() -> void:
		for i in 46:
			_p.append(Vector2(randf_range(0, width), randf_range(floor_y - 330, floor_y)))
			_ph.append(randf() * TAU)

	func _process(delta: float) -> void:
		for i in _p.size():
			var p := _p[i]
			p.y -= delta * (6.0 + float(i % 5) * 2.0)
			p.x += sin(_ph[i] + p.y * 0.03) * delta * 4.0
			if p.y < floor_y - 340.0:
				p.y = floor_y
				p.x = randf_range(0, width)
			_p[i] = p
		queue_redraw()

	func _paint() -> void:
		var t := Time.get_ticks_msec() * 0.001
		for i in _p.size():
			var a := 0.35 + 0.35 * sin(t * 2.0 + _ph[i])
			var s := 1.0 if i % 3 else 2.0
			pd.draw_rect(Rect2(_p[i].round(), Vector2(s, s)), Color(0.9, 0.86, 1.0, a))


## 보라 촛불 (깜빡이는 작은 노드 — 바닥과 따로 그려서 바닥은 다시 그리지 않는다)
class Candles extends PDraw.Canvas:
	const XS := [150.0, 410.0, 760.0, 1010.0, 1180.0]
	var floor_y := 300.0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _paint() -> void:
		for i in XS.size():
			var c := Vector2(float(XS[i]), floor_y)
			pd.draw_rect(Rect2(c + Vector2(-2, -9), Vector2(4, 9)), Color("#cfc6d8"))
			pd.draw_rect(Rect2(c + Vector2(-2, -9), Vector2(1, 9)), Color("#efe8f5"))
			pd.draw_rect(Rect2(c + Vector2(-4, -1), Vector2(8, 1)), Color("#3a3448"))
			var fl := 1.0 + 0.25 * sin(_t * 11.0 + float(i) * 2.1) + 0.1 * sin(_t * 23.0 + float(i))
			pd.glow(c + Vector2(0, -13), 16.0 * fl, Color(0.6, 0.45, 1.0, 0.2), 0.0)
			pd.glow(c + Vector2(0, -1), 12.0 * fl, Color(0.6, 0.45, 1.0, 0.12), 0.0) # 바닥에 번지는 빛
			pd.draw_colored_polygon(PackedVector2Array([c + Vector2(-1.7, -10), c + Vector2(1.7, -10), c + Vector2(sin(_t * 7.0 + float(i)) * 0.6, -10 - 5.5 * fl)]), Color("#b59cff"))
			pd.draw_rect(Rect2(c + Vector2(-0.5, -12), Vector2(1, 2)), Color(1, 1, 1, 0.9))


## 하늘의 공허 빛에서 비스듬히 내려오는 빛줄기 (가산, 정적)
class Shafts extends PDraw.Canvas:
	var floor_y := 300.0
	var width := 1280.0

	func _paint() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 991
		var x := 120.0
		while x < width * 0.4 + 640.0:
			var w := rng.randf_range(14.0, 36.0)
			var top := Vector2(x, floor_y - 360.0)
			var slant := rng.randf_range(60.0, 110.0)
			var a := rng.randf_range(0.03, 0.07)
			var l := PackedVector2Array([top, top + Vector2(slant, 360.0)])
			var r := PackedVector2Array([top + Vector2(w, 0), top + Vector2(slant + w * 1.8, 360.0)])
			pd.strip_grad(l, r, Color(0.7, 0.6, 1.0, a), Color(0.7, 0.6, 1.0, 0.0))
			x += rng.randf_range(90.0, 180.0)


## 바닥 가까이 천천히 흐르는 안개 덩이 (보통 섞기)
class Fog extends PDraw.Canvas:
	var width := 1280.0
	var floor_y := 300.0
	var _x := PackedFloat32Array()
	var _s := PackedFloat32Array()

	func _ready() -> void:
		for i in 9:
			_x.append(randf_range(0.0, width))
			_s.append(randf_range(5.0, 12.0))

	func _process(delta: float) -> void:
		for i in _x.size():
			_x[i] = fposmod(_x[i] + _s[i] * delta, width + 200.0)
		queue_redraw()

	func _paint() -> void:
		for i in _x.size():
			var c := Vector2(_x[i] - 100.0, floor_y - 6.0 - float(i % 3) * 5.0)
			pd.draw_set_transform(c, 0.0, Vector2(1.0, 0.28))
			pd.glow(Vector2.ZERO, 60.0 + float(i % 4) * 14.0, Color(0.42, 0.33, 0.62, 0.1), 0.0)
		pd.draw_set_transform(Vector2.ZERO)


## 전경 실루엣: 카메라보다 빨리 지나가는 매달린 사슬·부서진 기둥 끝 (깊이감, 정적)
class Foreground extends PDraw.Canvas:
	var width := 1280.0
	var floor_y := 300.0

	func _paint() -> void:
		var col := Color("#040306")
		var rng := RandomNumberGenerator.new()
		rng.seed = 313
		var x := -100.0
		while x < width * 1.35 + 200.0:
			if rng.randf() < 0.5:
				# 위에서 늘어진 사슬
				var len := rng.randf_range(40.0, 110.0)
				var top := floor_y - 420.0
				var y := top
				while y < top + 120.0 + len:
					pd.draw_rect(Rect2(x - 1.5, y, 3, 5), col)
					pd.draw_rect(Rect2(x - 2.5, y + 5, 5, 2), col)
					y += 7.0
				pd.draw_colored_polygon(PackedVector2Array([Vector2(x - 6, y), Vector2(x + 6, y), Vector2(x, y + 9)]), col)
			else:
				# 바닥에서 솟은 부서진 기둥 끝
				var h := rng.randf_range(26.0, 54.0)
				var bw := rng.randf_range(16.0, 26.0)
				pd.draw_colored_polygon(PackedVector2Array([Vector2(x - bw * 0.5, floor_y + 60), Vector2(x + bw * 0.5, floor_y + 60),
					Vector2(x + bw * 0.5, floor_y + 40 - h * 0.6), Vector2(x + bw * 0.1, floor_y + 40 - h), Vector2(x - bw * 0.3, floor_y + 40 - h * 0.7), Vector2(x - bw * 0.5, floor_y + 40 - h * 0.8)]), col)
			x += rng.randf_range(260.0, 420.0)
