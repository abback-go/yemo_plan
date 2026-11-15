class_name H3Art
extends RefCounted
## 2.5D 헥스 지도 시안 — 마녀성 (2026-10-23 사용자가 준 성 그림의 느낌: 보라 밤하늘 · 큰 달 · 고딕 첨탑 · 불 켜진 창 ·
## 떠 있는 섬 · 구름 바다로 떨어지는 폭포 · 횃불 난간 · 보라 깃발). 모든 그림은 코드 픽셀 그림 — 나중에 AI 그림으로 바꿔 끼울 자리.
## 밀도: 지형·벽 그림 32px = 1.0 (H3Map.PX).

const STONE := [Color("#2e2a38"), Color("#4a4458"), Color("#5c566a"), Color("#6e687c"), Color("#827c90"), Color("#9a94a8")] ## 다듬은 돌 (보랏빛 회색)
const MOSS := [Color("#16241e"), Color("#1f3128"), Color("#2a4032"), Color("#38533e"), Color("#4a6a4c"), Color("#62845e")]
const ROCK := [Color("#1c1824"), Color("#2a2434"), Color("#3a3346"), Color("#4c4458"), Color("#62596e"), Color("#7a7088")] ## 절벽 바위
const CWALL := [Color("#17131f"), Color("#211b2c"), Color("#2a2338"), Color("#342b44"), Color("#40354f")] ## 성벽 (어두운 보라 돌)
const LEAF := [Color("#0c1610"), Color("#14241a"), Color("#1d3424"), Color("#284630"), Color("#365a3a"), Color("#4a7048")]

static var _cache := {}


static func _tex(img: Image, mip := true) -> ImageTexture:
	if mip:
		img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _noise(seed_v: int, freq: float, size_x: int, size_y := -1) -> Image:
	var n := FastNoiseLite.new()
	n.seed = seed_v
	n.frequency = freq
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	return n.get_seamless_image(size_x, size_x if size_y < 0 else size_y)


static func _pick(pal: Array, v: float) -> Color:
	return pal[clampi(int(v * float(pal.size())), 0, pal.size() - 1)]


static func _hash(x: int, y: int, s := 0) -> float:
	return fposmod(sin(float(x) * 12.9898 + float(y) * 78.233 + float(s) * 37.719) * 43758.5453, 1.0)


# ─── 바닥 ───────────────────────────────────────────

## 이끼 낀 땅 (섬 윗면, 64×64)
static func moss() -> ImageTexture:
	if _cache.has("moss"):
		return _cache.moss
	var a := _noise(11, 0.05, 64)
	var b := _noise(12, 0.17, 64)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var v := a.get_pixel(x, y).r * 0.7 + b.get_pixel(x, y).r * 0.3
			img.set_pixel(x, y, _pick(MOSS.slice(1, 5), clampf((v - 0.25) * 1.6, 0.0, 0.999)))
	for i in 70:
		var x := rng.randi_range(0, 63)
		var y := rng.randi_range(1, 63)
		img.set_pixel(x, y, MOSS[5])
		img.set_pixel(x, y - 1, MOSS[4])
	for i in 14: # 보라 들꽃
		img.set_pixel(rng.randi_range(0, 63), rng.randi_range(0, 63), Color("#a57ad8") if rng.randf() < 0.6 else Color("#d8c0f0"))
	_cache.moss = _tex(img)
	return _cache.moss


## 판석 (난간 테라스·다리·광장, 64×64 = 2칸). 엇갈린 돌 + 어두운 줄눈 + 이끼 낀 틈
static func flags() -> ImageTexture:
	if _cache.has("flags"):
		return _cache.flags
	var a := _noise(21, 0.12, 64)
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		var row := y / 16
		for x in 64:
			var off := 0 if row % 2 == 0 else 11
			var col := ((x + off) % 64) / 21
			var lx := (x + off) % 64 - col * 21
			var ly := y % 16
			var c: Color
			if ly == 0 or lx == 0:
				c = STONE[0]
			else:
				var hv := _hash(col, row, 3)
				var v := 0.35 + hv * 0.35 + (a.get_pixel(x, y).r - 0.5) * 0.3
				if ly == 1 or lx == 1:
					v += 0.18 # 돌 모서리 빛
				elif ly == 15 or lx == 20:
					v -= 0.15
				c = _pick(STONE.slice(1, 6), clampf(v, 0.0, 0.999))
				if a.get_pixel(x, y).r > 0.78 and (ly < 3 or lx < 3):
					c = MOSS[3]
			img.set_pixel(x, y, c)
	_cache.flags = _tex(img)
	return _cache.flags


# ─── 벽 ─────────────────────────────────────────────

## 돌 쌓은 벽 (난간·다리·테라스 옆면, 64×64 = 2×2칸)
static func masonry() -> ImageTexture:
	if _cache.has("masonry"):
		return _cache.masonry
	_cache.masonry = _tex(_masonry_img())
	return _cache.masonry


static func _masonry_img() -> Image:
	var a := _noise(31, 0.1, 64)
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		var row := y / 8
		for x in 64:
			var off := 0 if row % 2 == 0 else 8
			var col := ((x + off) % 64) / 16
			var lx := (x + off) % 16
			var ly := y % 8
			var c: Color
			if ly == 7 or lx == 15:
				c = STONE[0]
			else:
				var v := 0.25 + _hash(col, row, 5) * 0.3 + (a.get_pixel(x, y).r - 0.5) * 0.25
				if ly == 0:
					v += 0.15
				c = _pick(STONE.slice(1, 5), clampf(v, 0.0, 0.999))
			img.set_pixel(x, y, c)
	for i in 8: # 담쟁이
		var x := rng.randi_range(0, 63)
		for y in rng.randi_range(4, 20):
			img.set_pixel((x + (y / 5) % 2) % 64, y, MOSS[2 + (y % 2)])
	return img


## 섬 절벽 (64×64 = 2×2칸): 층진 어두운 바위 + 세로 금 + 위 이끼
static func cliff() -> ImageTexture:
	if _cache.has("cliff"):
		return _cache.cliff
	var a := _noise(41, 0.09, 64)
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var band := y + int(2.0 * sin(TAU * float(x) / 64.0 * 2.0) + 3.0 * a.get_pixel(x, 0).r)
			var k := band % 12
			var c: Color = ROCK[2] if (band / 12) % 2 == 0 else ROCK[3]
			if k == 0:
				c = ROCK[4]
			elif k == 11:
				c = ROCK[0]
			elif k >= 9:
				c = ROCK[1]
			if a.get_pixel(x, y).r > 0.72:
				c = c.lightened(0.06)
			img.set_pixel(x, y, c)
	for i in 12:
		var x := rng.randi_range(0, 63)
		var y0 := rng.randi_range(4, 50)
		for y in range(y0, mini(63, y0 + rng.randi_range(6, 14))):
			img.set_pixel(x, y, ROCK[0])
			img.set_pixel((x + 1) % 64, y, ROCK[4])
	for x in 64:
		var depth := 4 + int(3.0 * (0.5 + 0.5 * sin(float(x) * 0.7))) + (2 if rng.randf() < 0.15 else 0)
		for y in depth:
			img.set_pixel(x, y, MOSS[4] if y < 2 else (MOSS[3] if y < depth - 2 else MOSS[1]))
		if rng.randf() < 0.14:
			for y in range(depth, depth + rng.randi_range(3, 10)):
				img.set_pixel(x, y, MOSS[2])
	_cache.cliff = _tex(img)
	return _cache.cliff


## 성벽 (256×384 = 8×12칸): 어두운 보라 돌 + 띠돌 + 드문드문 뾰족 아치 창(주황 불 · 보라 불 · 꺼진 창). [albedo, emission]
## 창은 64×96 칸마다 하나 있을까 말까 (짝창도 있음) — 빽빽한 격자로 보이지 않게
static func castle_wall() -> Array:
	if _cache.has("cwall"):
		return _cache.cwall
	var W := 256
	var H := 384
	var a := _noise(51, 0.06, W, H)
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var em := Image.create(W, H, false, Image.FORMAT_RGBA8)
	em.fill(Color(0, 0, 0, 1))
	for y in H:
		var row := y / 6
		for x in W:
			var off := 0 if row % 2 == 0 else 6
			var lx := (x + off) % 12
			var ly := y % 6
			var c: Color
			if y % 96 >= 90: # 띠돌 (한 층마다 밝은 가로 띠)
				c = STONE[1] if y % 96 == 90 else (CWALL[4] if y % 96 < 95 else CWALL[0])
			elif ly == 5 or lx == 11:
				c = CWALL[0]
			else:
				var v := 0.3 + _hash(((x + off) % W) / 12, row, 9) * 0.35 + (a.get_pixel(x, y).r - 0.5) * 0.3
				if ly == 0:
					v += 0.12
				c = _pick(CWALL.slice(1, 5), clampf(v, 0.0, 0.999))
			img.set_pixel(x, y, c)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for cy_i in 4:
		for cx_i in 4:
			if rng.randf() > 0.75:
				continue
			var roll := rng.randf()
			var lit := Color("#ffb45a") if roll < 0.55 else (Color("#b77aff") if roll < 0.7 else Color(0, 0, 0))
			var cx := cx_i * 64 + 32 + rng.randi_range(-8, 8)
			var cy := cy_i * 96 + 46
			var pair := rng.randf() < 0.3
			for k in (2 if pair else 1):
				_lancet(img, em, cx + (k * 2 - 1) * 9 if pair else cx, cy, lit)
	_cache.cwall = [_tex(img), _tex(em)]
	return _cache.cwall


## 뾰족 아치 창 하나 (폭 13 · 높이 40). lit 검정 = 꺼진 창
static func _lancet(img: Image, em: Image, cx: int, cy: int, lit: Color) -> void:
	var top := cy - 20
	for y in range(top, cy + 20):
		for x in range(cx - 6, cx + 7):
			var dx := absi(x - cx)
			var half := 6
			if y < top + 8:
				half = int(6.0 * sqrt(clampf(float(y - top) / 8.0, 0.0, 1.0)))
			if dx > half:
				continue
			if dx >= half - 1 or y >= cy + 18:
				img.set_pixel(x, y, STONE[2]) # 창틀
				continue
			if lit.r + lit.g + lit.b == 0.0:
				img.set_pixel(x, y, Color("#120e1a"))
				continue
			var core := 1.0 - clampf(float(dx) / 4.0, 0.0, 1.0)
			var gc := lit.lerp(Color("#fff0d0"), core * 0.55)
			if dx == 0 or (y - top) % 12 == 0:
				gc = gc.darkened(0.55) # 창살
			img.set_pixel(x, y, gc)
			em.set_pixel(x, y, gc)


## 첨탑 지붕 (32×64): 어두운 슬레이트 비늘
static func slate() -> ImageTexture:
	if _cache.has("slate"):
		return _cache.slate
	var img := Image.create(32, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 32:
			var row := y / 5
			var off := 0 if row % 2 == 0 else 2
			var c := Color("#221c34") if (x + off) % 4 != 0 else Color("#141022")
			if y % 5 == 4:
				c = Color("#100c1a")
			elif y % 5 == 0:
				c = Color("#342a4c")
			img.set_pixel(x, y, c)
	_cache.slate = _tex(img)
	return _cache.slate


## 큰 스테인드글라스 (64×160): 뾰족 아치 · 창살 · 장미창 · 보라·자홍·남색·금 조각. [albedo, emission]
static func stained() -> Array:
	if _cache.has("stained"):
		return _cache.stained
	var img := Image.create(64, 160, false, Image.FORMAT_RGBA8)
	var em := Image.create(64, 160, false, Image.FORMAT_RGBA8)
	em.fill(Color(0, 0, 0, 1))
	var pal := [Color("#8a4cff"), Color("#c060ff"), Color("#5a3ad8"), Color("#e080ff"), Color("#ffc870"), Color("#6aa0ff")]
	for y in 160:
		for x in 64:
			var dx := absf(float(x) - 31.5)
			var half := 31.5
			if y < 40:
				half = 31.5 * sqrt(clampf(float(y) / 40.0, 0.0, 1.0))
			if dx > half:
				continue
			var rose := Vector2(float(x) - 31.5, float(y) - 44.0).length()
			if dx > half - 3.0:
				img.set_pixel(x, y, Color("#3a3050"))
				continue
			if x % 16 == 7 or x % 16 == 8 or y % 22 == 0 or (y < 60 and absf(rose - 14.0) < 1.2):
				img.set_pixel(x, y, Color("#1a1428"))
				continue
			var c: Color = pal[int(_hash(x / 5, y / 6, 2) * 6.0) % 6]
			if rose < 13.0:
				c = c.lightened(0.25)
			img.set_pixel(x, y, c)
			em.set_pixel(x, y, c)
	_cache.stained = [_tex(img), _tex(em)]
	return _cache.stained


## 성문 (32×48 뾰족 아치): bars = 쇠창살과 문틀만 (사이는 투명) · 아니면 = 안쪽 불빛 (창살 없음). 둘을 겹치면 닫힌 문, 창살이 올라가면 열린 문
static func gate(bars: bool) -> ImageTexture:
	var key := "gate_bars" if bars else "gate_light"
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(32, 48, false, Image.FORMAT_RGBA8)
	for y in 48:
		for x in 32:
			var dx := absf(float(x) - 15.5)
			var half := 15.5
			if y < 14:
				half = 15.5 * sqrt(clampf(float(y) / 14.0, 0.0, 1.0))
			if dx > half:
				continue
			var k := 1.0 - clampf(dx / 15.5, 0.0, 1.0)
			var c := Color("#ff8a2a").lerp(Color("#ffe0a0"), k * 0.8)
			var bar := (x % 6 == 0 and y > 10) or (y % 12 == 6 and y > 10)
			if dx > half - 2.0:
				c = Color("#3a3050") # 문틀
			elif bar:
				c = Color("#5a2a14") # 창살
			elif bars:
				continue
			img.set_pixel(x, y, c)
	_cache[key] = _tex(img, false)
	return _cache[key]


## 다리 아치 띠 (64×32 = 4×2칸): 위는 돌, 아래는 반원 아치 구멍(투명)
static func arch_band() -> ImageTexture:
	if _cache.has("arch"):
		return _cache.arch
	var base := _masonry_img()
	var img := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		for x in 64:
			var c := base.get_pixel(x, y)
			var d := Vector2(float(x) - 31.5, float(y) - 32.0).length()
			if d < 22.0:
				c = Color(0, 0, 0, 0)
			elif d < 25.0:
				c = STONE[4] # 아치 돌테
			img.set_pixel(x, y, c)
	_cache.arch = _tex(img)
	return _cache.arch


# ─── 세운 그림 ───────────────────────────────────────

## 구름 덩어리 (96×48, 네 겹 명암 — 위가 달빛에 밝음)
static func cloud(v: int) -> ImageTexture:
	var key := "cloud%d" % v
	if _cache.has(key):
		return _cache[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = 500 + v
	var w := 96
	var h := 48
	var bl: Array = []
	for i in 9:
		bl.append(Vector3(rng.randf_range(18, 78), rng.randf_range(20, 34), rng.randf_range(9, 17)))
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var best := -1.0
			var bn := Vector2.ZERO
			for b: Vector3 in bl:
				var d := Vector2(float(x) - b.x, (float(y) - b.y) * 1.3)
				var f := 1.0 - d.length() / b.z
				if f > best:
					best = f
					bn = d / b.z
			if best <= 0.0 or y > 40:
				continue
			var lit := -(bn.x * 0.35 + bn.y * 0.9)
			var c := Color("#5a4888")
			if lit > 0.35:
				c = Color("#f2d6ee")
			elif lit > -0.05:
				c = Color("#c99ad6")
			elif lit > -0.45:
				c = Color("#8c6ab4")
			img.set_pixel(x, y, c)
	_cache[key] = _tex(img)
	return _cache[key]


## 불꽃 3장 가로 시트 (각 10×16). purple = 마녀 등불
static func flame(purple: bool) -> ImageTexture:
	var key := "flame%d" % int(purple)
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(30, 16, false, Image.FORMAT_RGBA8)
	var outer := Color("#8a3cff") if purple else Color("#ff6a1a")
	var mid := Color("#c890ff") if purple else Color("#ffaa3a")
	var core := Color("#f4e8ff") if purple else Color("#fff0b0")
	for f in 3:
		for y in 16:
			for x in 10:
				var t := float(y) / 15.0 # 0 위 · 1 아래
				var sway := sin(float(f) * 2.1 + t * 4.0) * (1.0 - t) * 1.6
				var half := 4.5 * sqrt(t) * (1.0 - t * 0.25)
				var dx := absf(float(x) - 4.5 - sway)
				if dx > half or y < 1:
					continue
				var k := dx / maxf(half, 0.01)
				var c := outer
				if k < 0.35 and t > 0.45:
					c = core
				elif k < 0.7:
					c = mid
				img.set_pixel(f * 10 + x, y, c)
	_cache[key] = _tex(img, false)
	return _cache[key]


## 보라 깃발 (20×48): 금 테 · 원 안 일곱 갈래 별 · 아래 제비꼬리
static func banner() -> ImageTexture:
	if _cache.has("banner"):
		return _cache.banner
	var img := Image.create(20, 48, false, Image.FORMAT_RGBA8)
	for y in 48:
		for x in 20:
			if y > 40 and absi(x * 2 - 19) < (y - 40) * 4 - 4:
				continue # 제비꼬리
			var c := Color("#4a2280").lerp(Color("#2a1248"), float(y) / 48.0)
			if x < 2 or x > 17 or y < 2:
				c = Color("#c8a04a")
			elif x == 2 or x == 17:
				c = Color("#7a5a2a")
			img.set_pixel(x, y, c)
	var cc := Vector2(9.5, 18.0)
	for y in 48:
		for x in 20:
			var d := Vector2(float(x), float(y)) - cc
			var r := d.length()
			if absf(r - 6.0) < 0.7:
				img.set_pixel(x, y, Color("#d8c0f0"))
			var ang := atan2(d.y, d.x) + PI / 2.0
			var spoke := absf(fposmod(ang * 7.0 / TAU, 1.0) - 0.5) * 2.0 # 1 = 갈래 끝
			if r < 5.2 and r < 1.5 + 3.7 * spoke:
				img.set_pixel(x, y, Color("#e8d8ff"))
	_cache.banner = _tex(img, false)
	return _cache.banner


## 날개 짓 2장 (각 28×14) — 먼 하늘의 비룡 그림자
static func dragon() -> ImageTexture:
	if _cache.has("dragon"):
		return _cache.dragon
	var img := Image.create(56, 14, false, Image.FORMAT_RGBA8)
	var c := Color("#1a1028")
	for f in 2:
		var ox := f * 28
		for x in range(9, 20): # 몸통
			img.set_pixel(ox + x, 8, c)
			if x > 11 and x < 17:
				img.set_pixel(ox + x, 9, c)
		for x in range(19, 24): # 목·머리
			img.set_pixel(ox + x, 7 if x < 22 else 6, c)
		for x in range(3, 10): # 꼬리
			img.set_pixel(ox + x, 9 + (10 - x) / 3, c)
		for k in 10: # 날개 (위로 펼침 / 아래로 내림)
			var wy := (7 - k) if f == 0 else (9 + k / 2)
			for t in 3:
				img.set_pixel(ox + 11 + k / 2 + t, clampi(wy, 0, 13), c)
	_cache.dragon = _tex(img, false)
	return _cache.dragon


## 어두운 바늘잎나무 (28×64)
static func pine(v: int) -> ImageTexture:
	var key := "pine%d" % v
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(28, 64, false, Image.FORMAT_RGBA8)
	for y in range(56, 64):
		for x in range(12, 16):
			img.set_pixel(x, y, Color("#2a1e1a") if x > 12 else Color("#3e2c24"))
	for l in 5:
		var top := 4 + l * 10
		var bot := top + 16
		for y in range(top, mini(bot, 58)):
			var half := float(y - top) / 16.0 * (6.0 + float(l) * 1.6)
			for x in 28:
				var dx := float(x) - 13.5
				if absf(dx) > half:
					continue
				var lit := -dx / maxf(half, 1.0) * 0.6 - float(y - top) / 16.0 * 0.4
				var hv := _hash(x, y, v)
				var c: Color = LEAF[clampi(2 + int((lit + (hv - 0.5) * 0.5) * 2.5), 1, 5)]
				if absf(dx) > half - 1.0 or y == bot - 1:
					c = LEAF[0]
				img.set_pixel(x, y, c)
	_cache[key] = _tex(img, false)
	return _cache[key]


## 에스카 움직임 시트 — 사용자 AI 그림(45×107)을 줄마다 1~2px 밀어 만든 8장 (eska_idle.png · eska_walk.png, 각 51×107)
static func eska_sheet(name: String) -> Texture2D:
	var key := "eska_" + name
	if _cache.has(key):
		return _cache[key]
	var img := (load("res://proto/hex3d/eska_%s.png" % name) as Texture2D).get_image()
	img.decompress()
	_cache[key] = _tex(img)
	return _cache[key]


## 물보라 한 점 (둥근 픽셀 덩어리)
static func puff() -> ImageTexture:
	if _cache.has("puff"):
		return _cache.puff
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y in 8:
		for x in 8:
			var d := Vector2(float(x) - 3.5, float(y) - 3.5).length()
			if d < 3.6:
				img.set_pixel(x, y, Color(1, 1, 1, 1.0 if d < 2.4 else 0.6))
	_cache.puff = _tex(img, false)
	return _cache.puff


## 발밑 그림자 (둥근 그러데이션)
static func shadow() -> ImageTexture:
	if _cache.has("shadow"):
		return _cache.shadow
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		for x in 32:
			var d := Vector2(float(x) - 15.5, float(y) - 15.5).length() / 16.0
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = floorf(a * 4.0) / 4.0 * 0.55
			img.set_pixel(x, y, Color(0.04, 0.03, 0.06, a))
	_cache.shadow = _tex(img, false)
	return _cache.shadow
