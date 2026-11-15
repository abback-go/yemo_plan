class_name PtArt
## 용사 파티 탐험 틀 시안의 코드 임시 픽셀 그림 (2026-11-15). AI 그림으로 바꿔 끼울 자리 — 함수 하나가 텍스처 하나를 돌려준다.
## 소품은 원점 = 밑동 가운데(발밑)이고, 그 자리를 텍스처 안 BASE 좌표로 알려 준다(Sprite2D offset = −BASE). 그림자는 그림 안에. 빛은 왼쪽 위.
## 외곽선은 그린 뒤 _outline이 한 번에 두른다 (이웃 색을 어둡게 — 나무는 짙은 초록, 돌은 짙은 회색).

const OUT := Color("#1a1420")
const LEAF := [Color("#16281c"), Color("#1f3d27"), Color("#2b5532"), Color("#3d723e"), Color("#5a9049"), Color("#83b25b")]
const BARK := [Color("#2a1a12"), Color("#45291b"), Color("#634029"), Color("#82583a")]
const STONE := [Color("#3b3a40"), Color("#5c5a5e"), Color("#7e7a76"), Color("#a29c8e"), Color("#c6bea8")]
const MOSS := [Color("#2f4a28"), Color("#4a6e32"), Color("#6f9440")]
const GOLD := [Color("#4a2c0c"), Color("#86581a"), Color("#c08a2a"), Color("#e8c050"), Color("#fff0a0")]
const RUNE := Color("#7ee8d8") ## 기둥 띠의 빛나는 문양
const SHADOW := Color(0.03, 0.06, 0.05, 0.38)
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

## 소품 텍스처 안의 밑동 자리
const TREE_BASE := Vector2(26, 60)
const PILLAR_BASE := Vector2(11, 52)
const STATUE_BASE := Vector2(22, 76)
const ROCK_BASE := Vector2(10, 13)
const BUSH_BASE := Vector2(12, 15)
## 캐릭터 시트: 칸 20×28, 발 (10, 26). 줄 = 아래 · 위 · 오른쪽(왼쪽은 뒤집기), 칸 = 대기 2 + 걷기 4
const HERO_CELL := Vector2i(20, 28)
const HERO_FEET := Vector2(10, 26)

static var _cache := {}


# ─── 도구 ───────────────────────────────────────────

static func _bayer(x: int, y: int) -> float:
	return (float(BAYER[(y & 3) * 4 + (x & 3)]) + 0.5) / 16.0


static func _rect(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	for y in range(maxi(y0, 0), mini(y1, img.get_height() - 1) + 1):
		for x in range(maxi(x0, 0), mini(x1, img.get_width() - 1) + 1):
			img.set_pixel(x, y, c)


static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


static func _ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx := (float(x) + 0.5 - cx) / rx
			var dy := (float(y) + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				_px(img, x, y, c)


## 반투명 타원 (그림자) — 이미 칠한 곳은 건드리지 않음
static func _shadow(img: Image, cx: float, cy: float, rx: float, ry: float) -> void:
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx := (float(x) + 0.5 - cx) / rx
			var dy := (float(y) + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0 and x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height() and img.get_pixel(x, y).a < 0.1:
				img.set_pixel(x, y, SHADOW)


## 불투명한 그림 둘레 1px 외곽선. col이 없으면 이웃 색을 어둡게
static func _outline(img: Image, col := Color(0, 0, 0, 0), x0 := 0, y0 := 0, w := -1, h := -1) -> void:
	if w < 0:
		w = img.get_width()
		h = img.get_height()
	var src := img.duplicate() as Image
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			if src.get_pixel(x, y).a > 0.5:
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx := x + d.x
				var ny := y + d.y
				if nx < x0 or ny < y0 or nx >= x0 + w or ny >= y0 + h:
					continue
				var n := src.get_pixel(nx, ny)
				if n.a > 0.5:
					img.set_pixel(x, y, col if col.a > 0.0 else n.darkened(0.62))
					break


static func _done(key: String, img: Image) -> ImageTexture:
	_cache[key] = H3Art._tex(img, false)
	return _cache[key]


# ─── 소품 ───────────────────────────────────────────

## 큰 나무 (52×66): 둥근 잎 덩어리 여러 개 + 줄기 + 뿌리 + 그림자. v = 모양 변형
static func tree(v: int) -> ImageTexture:
	var key := "tree%d" % v
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(52, 66, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 900 + v
	for y in range(34, 61): # 줄기 (아래로 갈수록 넓어지는 뿌리)
		var hw := 4 + (1 if y > 54 else 0) + (2 if y > 57 else 0)
		for x in range(26 - hw, 26 + hw + 1):
			var t := float(x - (26 - hw)) / float(2 * hw)
			var k := 3 if t < 0.28 else (2 if t < 0.62 else 1)
			if H3Art._hash(x, y / 3, v) > 0.8:
				k = maxi(k - 1, 0)
			if y < 42:
				k = maxi(k - 1, 0) # 잎 그늘
			img.set_pixel(x, y, BARK[k])
	var blobs: Array = [Vector3(26, 25, 15)]
	for i in 6:
		var a := TAU * float(i) / 6.0 + rng.randf_range(-0.35, 0.35)
		var d := rng.randf_range(8.0, 12.0)
		blobs.append(Vector3(26.0 + cos(a) * d * 1.15, 25.0 + sin(a) * d * 0.8, rng.randf_range(8.0, 11.5)))
	for y in 48:
		for x in 52:
			var best := -1.0
			var nrm := Vector2.ZERO
			for b: Vector3 in blobs:
				var dv := Vector2(float(x) - b.x, float(y) - b.y) / b.z
				var f := 1.0 - dv.length()
				if f > best:
					best = f
					nrm = dv
			if best <= 0.0:
				continue
			var lit := -(nrm.x * 0.55 + nrm.y * 0.85) * 0.5 + 0.5
			lit += (H3Art._hash(x / 3, y / 2, v + 7) - 0.5) * 0.3 # 잎 뭉치
			if best < 0.12:
				lit -= 0.2 # 덩어리 가장자리
			var k := clampi(int(floor(lit * 4.0 + _bayer(x, y))) + 1, 1, 5)
			img.set_pixel(x, y, LEAF[k])
	_outline(img)
	_shadow(img, 26, 61, 17, 4)
	return _done(key, img)


## 무너진 돌기둥 (22×56): 받침 · 몸통(이음 줄 · 빛나는 문양 띠 · 이끼) · 머리. broken = 위가 부러짐 · wet = 물에 선 기둥(그림자 대신 물거품)
static func pillar(broken: bool, wet: bool, v: int) -> ImageTexture:
	var key := "pillar%d%d%d" % [int(broken), int(wet), v]
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(22, 56, false, Image.FORMAT_RGBA8)
	var top := 10
	if broken:
		top = 18 + int(H3Art._hash(v, 3) * 8.0)
	# 받침: 윗면(밝게) + 앞면
	_rect(img, 1, 45, 20, 46, STONE[4])
	for y in range(47, 53):
		for x in range(1, 21):
			img.set_pixel(x, y, STONE[3] if x < 4 else (STONE[2] if x < 16 else STONE[1]))
	# 몸통
	for x in range(4, 18):
		var t := float(x - 4) / 13.0
		var col_top := top + (int(H3Art._hash(x, v, 5) * 3.0) if broken else 0)
		for y in range(col_top, 45):
			var k := 3 if t < 0.2 else (2 if t < 0.65 else 1)
			if (y - top) % 9 == 8:
				k = maxi(k - 1, 0) # 돌 이음 줄
			var c: Color = STONE[k]
			if y >= 22 and y <= 24 and top < 22:
				c = STONE[1] if (x + y) % 3 != 0 else RUNE # 문양 띠
			if y > 34 and H3Art._hash(x / 2, y / 2, v + 11) > 0.55 - float(y - 34) * 0.03:
				c = MOSS[clampi(int(H3Art._hash(x, y, 2) * 3.0), 0, 2)]
			img.set_pixel(x, y, c)
		if broken: # 부러진 윗면
			img.set_pixel(x, col_top, STONE[4])
	if not broken: # 머리: 앞면 + 윗면
		_rect(img, 2, 6, 19, 9, STONE[2])
		_rect(img, 2, 6, 4, 9, STONE[3])
		_rect(img, 16, 6, 19, 9, STONE[1])
		_rect(img, 3, 3, 18, 5, STONE[4])
	_outline(img)
	if wet:
		_ellipse(img, 11, 52, 12, 3, Color("#b6ead8"))
		_ellipse(img, 11, 52, 9, 2, Color("#4fb3aa"))
	else:
		_shadow(img, 11, 53, 12, 3)
	return _done(key, img)


## 섬의 금빛 석상 (44×80): 받침 위에서 두 팔로 빛 구슬을 든 인물 + 감아 오르는 뿌리
static func statue() -> ImageTexture:
	if _cache.has("statue"):
		return _cache.statue
	var img := Image.create(44, 80, false, Image.FORMAT_RGBA8)
	# 받침
	_rect(img, 6, 56, 37, 59, STONE[4])
	for y in range(60, 77):
		for x in range(6, 38):
			img.set_pixel(x, y, STONE[3] if x < 10 else (STONE[2] if x < 31 else STONE[1]))
	# 옷자락 (아래로 넓어짐)
	for y in range(27, 56):
		var hw := lerpf(7.0, 12.0, float(y - 27) / 28.0)
		for x in range(int(22.0 - hw), int(22.0 + hw) + 1):
			var t := (float(x) - (22.0 - hw)) / (2.0 * hw)
			var k := 3 if t < 0.3 else (2 if t < 0.7 else 1)
			if (x - 22) % 4 == 0 and y > 36:
				k = maxi(k - 1, 0) # 세로 옷 주름
			img.set_pixel(x, y, GOLD[k])
	_ellipse(img, 22, 28, 8.5, 3.0, GOLD[3]) # 어깨
	_ellipse(img, 25, 28.5, 4.0, 2.0, GOLD[2])
	# 팔 (어깨 → 머리 위 구슬)
	for i in 18:
		var f := float(i) / 17.0
		var l := Vector2(14, 27).lerp(Vector2(18, 9), f)
		var r := Vector2(29, 27).lerp(Vector2(25, 9), f)
		_rect(img, int(l.x), int(l.y), int(l.x) + 1, int(l.y), GOLD[3])
		_rect(img, int(r.x), int(r.y), int(r.x) + 1, int(r.y), GOLD[2])
	_ellipse(img, 22, 20, 4.5, 4.5, GOLD[3]) # 머리
	_ellipse(img, 23.5, 21, 2.5, 3.0, GOLD[2])
	_rect(img, 19, 16, 25, 17, GOLD[1]) # 머리띠
	_ellipse(img, 22, 6, 4.5, 4.5, GOLD[4]) # 빛 구슬
	_ellipse(img, 21, 5, 2.0, 2.0, Color.WHITE)
	# 받침과 옷자락 아래를 감는 뿌리
	for i in 34:
		var y := 76 - i
		var x := int(22.0 + sin(float(i) * 0.3) * 15.0)
		_rect(img, x, y, x + 1, y, BARK[1 + (i / 5) % 2])
	for i in 14:
		var x := 8 + i * 2
		_px(img, x, 58 + int(sin(float(i)) * 1.5), BARK[2])
	_outline(img)
	return _done("statue", img)


## 이끼 낀 바위 (20×16)
static func rock(v: int) -> ImageTexture:
	var key := "rock%d" % v
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(20, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		for x in 20:
			var dx := (float(x) + 0.5 - 10.0) / 8.5
			var dy := (float(y) + 0.5 - 9.0) / 5.5
			if dx * dx + dy * dy > 1.0:
				continue
			var lit := -(dx * 0.6 + dy * 0.8) * 0.5 + 0.5 + (H3Art._hash(x / 2, y / 2, v) - 0.5) * 0.25
			var c: Color = STONE[clampi(int(floor(lit * 3.0 + _bayer(x, y))) + 1, 1, 4)]
			if dy < -0.2 and H3Art._hash(x, y, v + 3) > 0.45:
				c = MOSS[clampi(int(lit * 3.0), 0, 2)]
			img.set_pixel(x, y, c)
	_outline(img)
	_shadow(img, 10, 14, 9, 2)
	return _done(key, img)


## 덤불 (24×18) — 막지 않는 장식
static func bush(v: int) -> ImageTexture:
	var key := "bush%d" % v
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(24, 18, false, Image.FORMAT_RGBA8)
	var blobs := [Vector3(8, 10, 6), Vector3(15, 9, 7), Vector3(12, 7, 5)]
	for y in 18:
		for x in 24:
			var best := -1.0
			var nrm := Vector2.ZERO
			for b: Vector3 in blobs:
				var dv := Vector2(float(x) - b.x, float(y) - b.y) / b.z
				if 1.0 - dv.length() > best:
					best = 1.0 - dv.length()
					nrm = dv
			if best <= 0.0:
				continue
			var lit := -(nrm.x * 0.55 + nrm.y * 0.85) * 0.5 + 0.5 + (H3Art._hash(x / 2, y, v + 5) - 0.5) * 0.3
			img.set_pixel(x, y, LEAF[clampi(int(floor(lit * 4.0 + _bayer(x, y))) + 1, 1, 5)])
	_outline(img)
	_shadow(img, 12, 16, 10, 2)
	return _done(key, img)


## 캐릭터 발밑 그림자 (14×6)
static func blob() -> ImageTexture:
	if _cache.has("blob"):
		return _cache.blob
	var img := Image.create(14, 6, false, Image.FORMAT_RGBA8)
	_shadow(img, 7, 3, 6.5, 2.6)
	return _done("blob", img)


# ─── 캐릭터: 검사 (임시) ─────────────────────────────

const SKIN := Color("#f4cfaa")
const SKIN_D := Color("#d9a080")
const HAIR := Color("#c4542e")
const HAIR_D := Color("#8a3420")
const HAIR_L := Color("#ee8a52")
const EYE := Color("#2a1c2a")
const ARMOR := Color("#c9d2de")
const ARMOR_L := Color("#eef3f8")
const ARMOR_D := Color("#8b96ab")
const CLOTH := Color("#3b6fd0")
const CLOTH_D := Color("#284c96")
const CAPE := Color("#b8323a")
const CAPE_D := Color("#7c1f2a")
const BELT := Color("#6a4028")
const BOOT := Color("#4a2e1e")
const BOOT_L := Color("#6e4630")
const BLADE := Color("#dfe6f2")
const BLUSH := Color("#f0a090")


## 검사 시트 (120×84): 줄 0 아래(정면) · 1 위(등) · 2 오른쪽(옆), 칸 0~1 대기(숨쉬기) · 2~5 걷기
static func hero_sheet() -> ImageTexture:
	if _cache.has("hero"):
		return _cache.hero
	var img := Image.create(HERO_CELL.x * 6, HERO_CELL.y * 3, false, Image.FORMAT_RGBA8)
	for d in 3:
		for f in 6:
			_hero_frame(img, f * HERO_CELL.x, d * HERO_CELL.y, d, f)
			_outline(img, OUT, f * HERO_CELL.x, d * HERO_CELL.y, HERO_CELL.x, HERO_CELL.y)
	return _done("hero", img)


static func _hero_frame(img: Image, ox: int, oy: int, dir: int, f: int) -> void:
	var b := 0 # 윗몸 위아래
	var lift_l := 0 # 다리 들림 (정면·등)
	var lift_r := 0
	var arm_l := 0 # 팔 흔들림
	var arm_r := 0
	var stride := 0 # 옆모습 보폭 (앞다리 +, 뒷다리 −)
	if f == 1:
		b = 1
	elif f >= 2:
		var k := f - 2
		b = -1 if k % 2 == 0 else 0
		if k == 1:
			lift_l = 1
			arm_l = 1
			arm_r = -1
			stride = 2
		elif k == 3:
			lift_r = 1
			arm_l = -1
			arm_r = 1
			stride = -2
	var R := func(x0: int, y0: int, x1: int, y1: int, c: Color) -> void: _rect(img, ox + x0, oy + y0, ox + x1, oy + y1, c)
	var P := func(x: int, y: int, c: Color) -> void: _px(img, ox + x, oy + y, c)
	var E := func(cx: float, cy: float, rx: float, ry: float, c: Color) -> void: _ellipse(img, ox + cx, oy + cy, rx, ry, c)
	if dir == 2:
		_hero_side(R, P, E, b, stride, arm_l, f >= 2)
		return
	if dir == 0: # 정면: 망토는 몸 뒤 (팔 밑·다리 사이로 보임)
		R.call(4, 14 + b, 15, 23, CAPE_D)
		R.call(5, 14 + b, 14, 22, CAPE)
	# 다리 + 장화
	for side in [0, 1]:
		var lx := 7 if side == 0 else 11
		var up: int = lift_l if side == 0 else lift_r
		R.call(lx, 21 - up, lx + 1, 23 - up, CLOTH_D)
		R.call(lx - (1 if side == 0 else 0), 24 - up, lx + 1 + (0 if side == 0 else 1), 26 - up, BOOT)
		P.call(lx, 24 - up, BOOT_L)
	# 치마 · 몸통 · 허리띠
	R.call(6, 19 + b, 13, 20 + b, CLOTH)
	R.call(5, 21 + b, 14, 21 + b, CLOTH_D)
	R.call(6, 13 + b, 13, 18 + b, ARMOR)
	R.call(12, 13 + b, 13, 18 + b, ARMOR_D)
	R.call(7, 14 + b, 8, 14 + b, ARMOR_L)
	R.call(6, 18 + b, 13, 18 + b, BELT)
	R.call(9, 18 + b, 10, 18 + b, GOLD[3])
	# 팔 (어깨 판 + 팔 + 손)
	R.call(4, 14 + b + arm_l, 5, 17 + b + arm_l, ARMOR_D)
	R.call(4, 18 + b + arm_l, 5, 18 + b + arm_l, SKIN)
	R.call(14, 14 + b + arm_r, 15, 17 + b + arm_r, ARMOR_D)
	R.call(14, 18 + b + arm_r, 15, 18 + b + arm_r, SKIN)
	R.call(4, 13 + b, 6, 14 + b, ARMOR)
	R.call(13, 13 + b, 15, 14 + b, ARMOR)
	P.call(4, 13 + b, ARMOR_L)
	R.call(9, 12 + b, 10, 12 + b, SKIN_D) # 목
	if dir == 0:
		E.call(10.0, 8.5 + b, 5.0, 4.6, SKIN) # 얼굴
		E.call(10.0, 6.0 + b, 6.0, 4.0, HAIR) # 머리카락 윗부분
		for x in range(5, 15): # 앞머리 (아래 끝이 들쭉날쭉)
			var by := 7 + b + (1 if x % 3 == 1 else 0)
			R.call(x, 4 + b, x, by, HAIR_D if x >= 12 else HAIR)
		R.call(4, 6 + b, 5, 11 + b, HAIR) # 옆머리
		R.call(14, 6 + b, 15, 11 + b, HAIR_D)
		R.call(7, 3 + b, 10, 3 + b, HAIR_L)
		P.call(6, 4 + b, HAIR_L)
		R.call(7, 9 + b, 7, 10 + b, EYE)
		R.call(12, 9 + b, 12, 10 + b, EYE)
		P.call(6, 11 + b, BLUSH)
		P.call(13, 11 + b, BLUSH)
		# 등의 검 손잡이 (오른 어깨 위)
		R.call(14, 12 + b, 17, 12 + b, GOLD[3])
		R.call(16, 9 + b, 16, 11 + b, BELT)
		P.call(16, 8 + b, GOLD[3])
	else: # 등: 머리카락 · 망토가 몸을 덮음 · 등에 멘 검
		E.call(10.0, 7.5 + b, 5.6, 5.0, HAIR)
		R.call(5, 10 + b, 14, 11 + b, HAIR_D)
		R.call(7, 3 + b, 9, 4 + b, HAIR_L)
		R.call(9, 12 + b, 10, 12 + b, SKIN_D)
		R.call(5, 13 + b, 14, 22, CAPE)
		R.call(5, 13 + b, 14, 13 + b, CAPE_D)
		R.call(7, 16 + b, 7, 22, CAPE_D)
		R.call(12, 16 + b, 12, 22, CAPE_D)
		for x in range(6, 14, 2):
			P.call(x, 23, CAPE_D)
		for i in 10: # 검날 (왼 아래 → 오른 위)
			P.call(6 + i * 8 / 10, 21 - i, BLADE)
			P.call(7 + i * 8 / 10, 21 - i, ARMOR_D)
		R.call(13, 11 + b, 16, 11 + b, GOLD[3])
		R.call(15, 9 + b, 15, 10 + b, BELT)
		P.call(16, 8 + b, GOLD[3])


## 옆모습 (오른쪽을 봄). walking = 망토 끝이 펄럭임
static func _hero_side(R: Callable, P: Callable, E: Callable, b: int, stride: int, swing: int, walking: bool) -> void:
	var flap := 1 if walking else 0
	R.call(4 - flap, 13 + b, 8, 22, CAPE_D) # 망토 (몸 뒤)
	R.call(5 - flap, 14 + b, 8, 21, CAPE)
	# 뒷다리 (어둡게) · 앞다리
	var back_x := 9 - stride / 2
	var front_x := 10 + stride / 2
	R.call(back_x, 21, back_x + 1, 23, CLOTH_D.darkened(0.3))
	R.call(back_x - 1, 24, back_x + 1, 26, BOOT.darkened(0.3))
	R.call(7, 13 + b, 12, 18 + b, ARMOR)
	R.call(12, 13 + b, 12, 18 + b, ARMOR_D)
	R.call(8, 14 + b, 9, 14 + b, ARMOR_L)
	R.call(7, 18 + b, 12, 18 + b, BELT)
	R.call(7, 19 + b, 12, 20 + b, CLOTH)
	R.call(6, 21 + b, 13, 21 + b, CLOTH_D)
	R.call(front_x, 21, front_x + 1, 23, CLOTH_D)
	R.call(front_x, 24, front_x + 2, 26, BOOT)
	P.call(front_x, 24, BOOT_L)
	# 앞팔
	R.call(9 + swing, 14 + b, 10 + swing, 17 + b, ARMOR_D)
	R.call(9 + swing, 18 + b, 10 + swing, 18 + b, SKIN)
	R.call(8, 13 + b, 11, 14 + b, ARMOR)
	R.call(9, 12 + b, 10, 12 + b, SKIN_D)
	# 머리: 얼굴은 오른쪽, 머리카락은 위·뒤
	E.call(10.5, 8.5 + b, 5.0, 4.6, SKIN)
	E.call(9.0, 6.5 + b, 5.6, 4.2, HAIR)
	R.call(5, 6 + b, 8, 11 + b, HAIR)
	R.call(5, 9 + b, 6, 13 + b, HAIR_D) # 뒤로 늘어진 머리
	for x in range(9, 15):
		R.call(x, 4 + b, x, 6 + b + (1 if x % 3 == 0 else 0), HAIR)
	R.call(7, 3 + b, 10, 3 + b, HAIR_L)
	R.call(13, 9 + b, 13, 10 + b, EYE)
	P.call(14, 11 + b, BLUSH)
	# 등의 검 손잡이
	R.call(5, 12 + b, 7, 12 + b, GOLD[3])
	R.call(6, 9 + b, 6, 11 + b, BELT)
	P.call(6, 8 + b, GOLD[3])
