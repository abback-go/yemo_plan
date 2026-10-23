class_name H3Art
extends RefCounted
## 2.5D 헥스 지도 시안의 픽셀 그림 (코드로 그림 — 나중에 AI 그림으로 바꿔 끼울 자리).
## 밀도: 지형 그림 32px = 1칸(1.0) · 스프라이트도 32px = 1.0 (H3Map.PX).
## 빛은 왼쪽 위에서 (사진 참고: 밝은 풀 · 회갈색 층진 절벽 · 청록 물).

const GRASS := [Color("#22401f"), Color("#2e5528"), Color("#3c6b30"), Color("#52863a"), Color("#6b9c45"), Color("#8db558")]
const DIRT := [Color("#5e4630"), Color("#7e5f3c"), Color("#9a7a50"), Color("#b39468"), Color("#c9b28a")]
const ROCK := [Color("#3e3a35"), Color("#5c564d"), Color("#7a7366"), Color("#958d7b"), Color("#b3aa94"), Color("#cdc4ad")]
const LEAF := [Color("#0f2414"), Color("#1a361c"), Color("#284f24"), Color("#3c6c2e"), Color("#5a8c3a"), Color("#86b450")]
const BARK := [Color("#2e2014"), Color("#4a3322"), Color("#6a4a30"), Color("#8a6644")]

static var _cache := {}


static func _tex(img: Image, mip := true) -> ImageTexture:
	if mip:
		img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _noise(seed_v: int, freq: float, size: int) -> Image:
	var n := FastNoiseLite.new()
	n.seed = seed_v
	n.frequency = freq
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	return n.get_seamless_image(size, size)


static func _pick(pal: Array, v: float) -> Color:
	return pal[clampi(int(v * float(pal.size())), 0, pal.size() - 1)]


## 풀 (64×64 = 2칸, 이음매 없음)
static func grass() -> ImageTexture:
	if _cache.has("grass"):
		return _cache.grass
	var a := _noise(11, 0.045, 64)
	var b := _noise(12, 0.16, 64)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var v := a.get_pixel(x, y).r * 0.7 + b.get_pixel(x, y).r * 0.3
			img.set_pixel(x, y, _pick(GRASS.slice(1, 5), clampf((v - 0.25) * 1.6, 0.0, 0.999)))
	for i in 90: # 풀잎: 밝은 2px 세로 획 + 아래 그늘
		var x := rng.randi_range(0, 63)
		var y := rng.randi_range(1, 63)
		img.set_pixel(x, y, GRASS[5] if rng.randf() < 0.4 else GRASS[4])
		img.set_pixel(x, y - 1, GRASS[4])
		img.set_pixel(x, (y + 1) % 64, GRASS[1])
	for i in 60:
		img.set_pixel(rng.randi_range(0, 63), rng.randi_range(0, 63), GRASS[0])
	_cache.grass = _tex(img)
	return _cache.grass


## 흙길 (64×64)
static func dirt() -> ImageTexture:
	if _cache.has("dirt"):
		return _cache.dirt
	var a := _noise(21, 0.07, 64)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			img.set_pixel(x, y, _pick(DIRT.slice(1, 4), clampf((a.get_pixel(x, y).r - 0.2) * 1.7, 0.0, 0.999)))
	for i in 40: # 자갈
		var x := rng.randi_range(0, 62)
		var y := rng.randi_range(0, 62)
		img.set_pixel(x, y, DIRT[4])
		img.set_pixel(x + 1, y, DIRT[3])
		img.set_pixel(x, y + 1, DIRT[0])
		img.set_pixel(x + 1, y + 1, DIRT[0])
	_cache.dirt = _tex(img)
	return _cache.dirt


## 절벽 옆면 (64×64 = 가로 2칸 · 세로 2칸). 위 6~9px는 이끼(풀 입술), 아래로 층진 바위
static func cliff() -> ImageTexture:
	if _cache.has("cliff"):
		return _cache.cliff
	var a := _noise(31, 0.09, 64)
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var band := y + int(2.0 * sin(TAU * float(x) / 64.0 * 2.0) + 2.0 * a.get_pixel(x, 0).r)
			var k := band % 11
			var base := 2 if (band / 11) % 2 == 0 else 3
			var c: Color = ROCK[base]
			if k == 0:
				c = ROCK[4] # 층 윗면 빛
			elif k == 10:
				c = ROCK[0] # 층 아래 그늘
			elif k >= 8:
				c = ROCK[1]
			if a.get_pixel(x, y).r > 0.72:
				c = c.lightened(0.08)
			img.set_pixel(x, y, c)
	for i in 10: # 세로 금
		var x := rng.randi_range(0, 63)
		var y0 := rng.randi_range(10, 50)
		for y in range(y0, mini(63, y0 + rng.randi_range(5, 12))):
			img.set_pixel(x, y, ROCK[0])
			img.set_pixel((x + 1) % 64, y, ROCK[4])
	for x in 64: # 위 이끼 입술 + 늘어진 이끼
		var depth := 5 + int(3.0 * (0.5 + 0.5 * sin(float(x) * 0.7))) + (2 if rng.randf() < 0.15 else 0)
		for y in depth:
			img.set_pixel(x, y, GRASS[4] if y < 2 else (GRASS[3] if y < depth - 2 else GRASS[1]))
		if rng.randf() < 0.12:
			for y in range(depth, depth + rng.randi_range(3, 9)):
				img.set_pixel(x, y, GRASS[2])
	_cache.cliff = _tex(img)
	return _cache.cliff


## 둥근 덤불·나무 잎 덩어리를 그린다 (빛 왼쪽 위, 바깥 테두리 어둡게)
static func _canopy(img: Image, cx: float, cy: float, rx: float, ry: float, blobs: int, rng: RandomNumberGenerator) -> void:
	var bl: Array = []
	for i in blobs:
		var ang := rng.randf() * TAU
		var dd := sqrt(rng.randf())
		var r := lerpf(rx * 0.38, rx * 0.6, rng.randf())
		bl.append(Vector3(cx + cos(ang) * dd * (rx - r * 0.7), cy + sin(ang) * dd * (ry - r * 0.7), r))
	bl.append(Vector3(cx, cy, rx * 0.62))
	var w := img.get_width()
	var h := img.get_height()
	var mask := {}
	for y in h:
		for x in w:
			var best := -1.0
			var bn := Vector2.ZERO
			for b: Vector3 in bl:
				var d := Vector2(float(x) - b.x, float(y) - b.y)
				var f := 1.0 - d.length() / b.z
				if f > best:
					best = f
					bn = d / b.z
			if best <= 0.0:
				continue
			var lit := -(bn.x * 0.6 + bn.y * 0.8)
			var hsh := fposmod(sin(float(x) * 12.9898 + float(y) * 78.233) * 43758.5453, 1.0)
			var v := 0.36 + 0.42 * lit + 0.3 * best + (hsh - 0.5) * 0.26
			img.set_pixel(x, y, LEAF[clampi(1 + int(v * 4.0), 1, 5)])
			mask[Vector2i(x, y)] = true
	for p: Vector2i in mask: # 바깥 테두리
		for o: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q := p + o
			if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and not mask.has(q):
				img.set_pixel(p.x, p.y, LEAF[0])
				break


## 나무 (72×100 · 아래 가운데가 뿌리)
static func tree(v: int) -> ImageTexture:
	var key := "tree%d" % v
	if _cache.has(key):
		return _cache[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = 100 + v
	var img := Image.create(72, 100, false, Image.FORMAT_RGBA8)
	var tx := 34 + rng.randi_range(-2, 2)
	for y in range(52, 98): # 줄기
		var wd := 3 if y < 86 else (4 if y < 94 else 6)
		for x in range(tx - wd, tx + wd):
			var c: Color = BARK[2] if x < tx - wd + 2 else (BARK[0] if x >= tx + wd - 1 else BARK[1])
			img.set_pixel(x, y, c)
	for i in 2: # 가지
		var by := 58 + i * 8
		var dir := -1 if i == 0 else 1
		for k in 10:
			img.set_pixel(tx + dir * (2 + k), by - k / 2, BARK[1])
	_canopy(img, 36.0, 34.0 + float(rng.randi_range(-2, 2)), 33.0, 30.0, 16, rng)
	_cache[key] = _tex(img, false)
	return _cache[key]


static func bush(v: int) -> ImageTexture:
	var key := "bush%d" % v
	if _cache.has(key):
		return _cache[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = 200 + v
	var img := Image.create(44, 30, false, Image.FORMAT_RGBA8)
	_canopy(img, 22.0, 17.0, 20.0, 12.0, 6, rng)
	_cache[key] = _tex(img, false)
	return _cache[key]


static func rock(v: int) -> ImageTexture:
	var key := "rock%d" % v
	if _cache.has(key):
		return _cache[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = 300 + v
	var w := 26
	var h := 18
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var d := Vector2((float(x) - 12.5) / 12.0, (float(y) - 11.0) / 8.0)
			if d.length() > 1.0 or y < 3:
				continue
			var lit := -(d.x * 0.6 + d.y * 0.8)
			var c: Color = ROCK[clampi(2 + int(lit * 2.2), 0, 5)]
			if d.length() > 0.88:
				c = ROCK[0]
			if y < 6 and rng.randf() < 0.5:
				c = GRASS[3] # 이끼
			img.set_pixel(x, y, c)
	_cache[key] = _tex(img, false)
	return _cache[key]


static func tuft(v: int) -> ImageTexture:
	var key := "tuft%d" % v
	if _cache.has(key):
		return _cache[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = 400 + v
	var img := Image.create(14, 12, false, Image.FORMAT_RGBA8)
	for i in 6:
		var x := rng.randi_range(1, 12)
		var hh := rng.randi_range(4, 11)
		var lean := rng.randi_range(-1, 1)
		for k in hh:
			var px := clampi(x + (lean * k) / 4, 0, 13)
			img.set_pixel(px, 11 - k, GRASS[5] if k > hh - 3 else (GRASS[4] if k > 2 else GRASS[2]))
	_cache[key] = _tex(img, false)
	return _cache[key]


## 에스카 — 사용자가 준 AI 그림(2026-10-23)을 진짜 픽셀 격자로 다시 찍은 것 (45×107, 24색, 배경 투명).
## 원본 1024×1024 · 칸 8px → 배경 지움 · 칸마다 가운데 색 · 24색으로 줄임. 걷기 프레임은 아직 없음(한 장 + 걸음 흔들림)
static func eska(_frame: int) -> Texture2D:
	if _cache.has("eska"):
		return _cache.eska
	var img := (load("res://proto/hex3d/eska_witch.png") as Texture2D).get_image()
	img.decompress()
	_cache.eska = _tex(img) # 밉맵: 멀리서 작게 보일 때 지글거림 줄임
	return _cache.eska


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
			img.set_pixel(x, y, Color(0.04, 0.06, 0.04, a))
	_cache.shadow = _tex(img, false)
	return _cache.shadow
