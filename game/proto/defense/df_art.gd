class_name DfArt
## 성 방어 시안의 코드 임시 픽셀 그림 (2026-11-15) — AI 그림으로 바꿔 끼울 자리. 그리기 도구(_rect·_ellipse·_outline·_shadow·_bayer)는 PtArt 것을 쓴다.
## 소품·인물의 원점 = 발밑 가운데 → 텍스처 안 BASE/FEET 좌표를 함께 둔다. 빛은 왼쪽 위.

const OUT := Color("#17121c")
const WALL := [Color("#2a2533"), Color("#3a3446"), Color("#4b4558"), Color("#5e576b"), Color("#746c80")] ## 성벽 돌 (해 질 녘 보랏빛 회색)
const MORTAR := Color("#201b28")
const MOSS := [Color("#2c3a24"), Color("#3e5230"), Color("#56703c")]
const NAVY := [Color("#141c44"), Color("#1f2c66"), Color("#2e4090")] ## 성 깃발·옷
const GOLD := [Color("#6a4614"), Color("#b0802a"), Color("#e2b44c"), Color("#fbe08a")]
const IRON := [Color("#1d1a22"), Color("#36313e"), Color("#5a5262"), Color("#8a8294")]
const WOOD := [Color("#2e1e14"), Color("#4a3020"), Color("#6a4630"), Color("#8c6444")]
const STEEL := [Color("#4a5060"), Color("#7a8292"), Color("#b6bcc8"), Color("#e6eaf2")]
const BLOOD := [Color("#3a0e16"), Color("#6a1a24"), Color("#9a2a34")] ## 적 깃발
const VIOLET := [Color("#2a1236"), Color("#4a2060"), Color("#7a3a9a"), Color("#c070ff"), Color("#f0c8ff")]

const WALL_W := 768 ## 성벽 그림 = 맵 폭
const WALL_H := 176
const GATE_X := 384 ## 성문 가운데 (px)
const TOWER_L := Rect2i(318, 0, 46, 176) ## 문 옆 탑 (앞으로 8px 더 나옴)
const TOWER_R := Rect2i(404, 0, 46, 176)
const GATE := Rect2i(366, 96, 36, 72) ## 문 구멍 (아치 포함)
const WALL_FACE_TOP := 34 ## 성벽 앞면 시작 y (위는 성벽 위 통로·여장)
const WALL_BOTTOM := 168 ## 성벽 앞면 끝 y (탑은 176) — 사람(28px)의 다섯 배쯤

const PERSON_CELL := Vector2i(20, 28) ## 궁수·병사 칸, 발 (10, 26)
const PERSON_FEET := Vector2(10, 26)
const GHOUL_CELL := Vector2i(22, 22) ## 발 (11, 20)
const GHOUL_FEET := Vector2(11, 20)
const MAGE_CELL := Vector2i(22, 30) ## 발 (11, 28)
const MAGE_FEET := Vector2(11, 28)
const BRAZIER_BASE := Vector2(8, 22)
const BANNER_BASE := Vector2(9, 46)
const BARRICADE_BASE := Vector2(22, 18)
const CRYSTAL_BASE := Vector2(9, 20)

static var _cache := {}


static func _done(key: String, img: Image) -> ImageTexture:
	_cache[key] = H3Art._tex(img, false)
	return _cache[key]


# ─── 성벽 ───────────────────────────────────────────

## 위쪽 성벽 한 장 (768×176): 성 안 지붕 · 성벽 위 통로와 여장 · 앞면 돌(이끼·덩굴) · 문 옆 탑 둘 · 쇠창살 성문 · 걸린 깃발 넷
static func wall() -> ImageTexture:
	if _cache.has("wall"):
		return _cache.wall
	var img := Image.create(WALL_W, WALL_H, false, Image.FORMAT_RGBA8)
	# 성 안 (멀리): 어두운 지붕 줄
	for y in 16:
		for x in WALL_W:
			var k := 0 if (x / 6 + y / 4) % 3 == 0 else 1
			img.set_pixel(x, y, NAVY[k].darkened(0.35) if (y % 4) != 3 else Color("#0c0e1e"))
	# 성벽 위 통로 (윗면)
	for y in range(16, 26):
		for x in WALL_W:
			var v := 0.55 + (H3Art._hash(x / 8, y / 5, 3) - 0.5) * 0.3
			img.set_pixel(x, y, WALL[clampi(int(floor(v * 4.0 + PtArt._bayer(x, y))), 1, 4)] if (x % 16) != 0 else MORTAR)
	# 여장(톱니) — 윗면 + 앞면
	for i in range(0, WALL_W / 16):
		var x0 := i * 16 + 3
		PtArt._rect(img, x0, 22, x0 + 9, 25, WALL[4])
		PtArt._rect(img, x0, 26, x0 + 9, WALL_FACE_TOP - 1, WALL[2])
		PtArt._rect(img, x0 + 8, 26, x0 + 9, WALL_FACE_TOP - 1, WALL[1])
	# 앞면 돌 (16×10 엇갈림)
	for y in range(WALL_FACE_TOP, WALL_BOTTOM):
		var row := (y - WALL_FACE_TOP) / 10
		for x in WALL_W:
			var lx := (x + (8 if row % 2 == 1 else 0)) % 16
			var ly := (y - WALL_FACE_TOP) % 10
			var c: Color
			if lx == 0 or ly == 0:
				c = MORTAR
			else:
				var v := 0.45 + (H3Art._hash((x + (8 if row % 2 == 1 else 0)) / 16, row, 7) - 0.5) * 0.35 - float(y - WALL_FACE_TOP) / 300.0
				if ly == 1:
					v += 0.12
				c = WALL[clampi(int(floor(v * 4.0 + PtArt._bayer(x, y))), 0, 4)]
			img.set_pixel(x, y, c)
	_vines(img, Rect2i(0, WALL_FACE_TOP, WALL_W, WALL_BOTTOM - WALL_FACE_TOP), 11)
	# 문 옆 탑 둘 (앞으로 나오고 더 높음 — 밝은 돌 · 둥근 꼭대기 여장)
	for t: Rect2i in [TOWER_L, TOWER_R]:
		for y in range(4, t.end.y):
			for x in range(t.position.x, t.end.x):
				var lx := x - t.position.x
				var row := y / 9
				var bx := (lx + (6 if row % 2 == 1 else 0)) % 12
				var c: Color
				if bx == 0 or y % 9 == 0:
					c = MORTAR
				else:
					var side := 0.18 if lx < 6 else (-0.2 if lx > t.size.x - 8 else 0.0)
					var v := 0.58 + side + (H3Art._hash(x / 12, row, 5) - 0.5) * 0.3
					c = WALL[clampi(int(floor(v * 4.0 + PtArt._bayer(x, y))), 0, 4)]
				img.set_pixel(x, y, c)
		for i in 4: # 탑 꼭대기 여장
			var x0 := t.position.x + 1 + i * 12
			PtArt._rect(img, x0, 0, x0 + 7, 3, WALL[4])
			PtArt._rect(img, x0, 4, x0 + 7, 7, WALL[3])
		for wy: int in [30, 70]: # 탑 창 (불 켜짐)
			PtArt._rect(img, t.position.x + 16, wy, t.position.x + 29, wy + 14, Color("#120e18"))
			PtArt._rect(img, t.position.x + 18, wy + 2, t.position.x + 27, wy + 12, Color("#e8a040"))
			PtArt._rect(img, t.position.x + 22, wy + 2, t.position.x + 23, wy + 12, Color("#120e18"))
	_vines(img, TOWER_L, 21)
	_vines(img, TOWER_R, 23)
	# 성문: 돌 아치 테 · 어두운 안 · 쇠창살
	for y in range(GATE.position.y - 6, GATE.end.y):
		for x in range(GATE.position.x - 6, GATE.end.x + 6):
			var cx := float(GATE_X) - 0.5
			var top := float(GATE.position.y) + 14.0
			var r_out := float(GATE.size.x) * 0.5 + 6.0
			var r_in := float(GATE.size.x) * 0.5
			var dx := float(x) - cx
			var in_out := y >= int(top) or Vector2(dx, (float(y) - top) * 1.0).length() <= r_out
			var in_in := (y >= int(top) and absf(dx) <= r_in) or Vector2(dx, float(y) - top).length() <= r_in
			if not in_out or x < GATE.position.x - 6 or x >= GATE.end.x + 6:
				continue
			if in_in:
				var c := Color("#100c16") if (y - GATE.position.y) > 4 else Color("#1a1422")
				var bar_x := (x - GATE.position.x) % 6 == 2
				var bar_y := (y - GATE.position.y) % 9 == 4
				if bar_x or bar_y:
					c = IRON[2] if bar_x and bar_y else IRON[1]
					if bar_x and (x - GATE.position.x) % 12 == 2:
						c = IRON[3]
				if y >= GATE.end.y - 3 and bar_x:
					c = IRON[3] # 창살 끝
				img.set_pixel(x, y, c)
			elif absf(dx) <= r_out:
				img.set_pixel(x, y, WALL[4] if dx < 0.0 else WALL[3])
	# 걸린 깃발 넷 (막대 + 남색 천 + 금 테 + 금빛 해 문장 + 제비꼬리)
	for bx: int in [120, 232, 536, 648]:
		_hang_banner(img, bx, 48)
	PtArt._outline(img, Color(0, 0, 0, 0), 0, 0, WALL_W, WALL_H)
	return _done("wall", img)


static func _vines(img: Image, r: Rect2i, seed_v: int) -> void:
	for i in r.size.x / 22:
		var x := r.position.x + 6 + i * 22 + int(H3Art._hash(i, seed_v) * 10.0)
		var len := 10 + int(H3Art._hash(i, seed_v + 1) * 30.0)
		for j in len:
			var y := r.position.y + j
			if y >= r.end.y:
				break
			var xx := x + int(sin(float(j) * 0.4 + float(i)) * 2.0)
			PtArt._px(img, xx, y, MOSS[1 + (j / 4) % 2])
			if j % 5 == 0:
				PtArt._px(img, xx + 1, y, MOSS[2])
				PtArt._px(img, xx - 1, y + 1, MOSS[0])


static func _hang_banner(img: Image, cx: int, top: int) -> void:
	PtArt._rect(img, cx - 10, top - 2, cx + 10, top - 1, WOOD[2])
	for y in range(top, top + 60):
		var tail := y - (top + 52) # 제비꼬리: 아래 8줄 가운데가 파임
		for x in range(cx - 8, cx + 9):
			if tail > 0 and absi(x - cx) < tail:
				continue
			var edge := absi(x - cx) >= 7 or y == top
			var c: Color = GOLD[2] if edge else (NAVY[2] if x < cx - 3 else NAVY[1])
			if not edge and (y - top) % 12 == 11:
				c = NAVY[0] # 천 주름
			img.set_pixel(x, y, c)
	PtArt._ellipse(img, cx, top + 20, 4.5, 4.5, GOLD[2]) # 해 문장
	PtArt._ellipse(img, cx, top + 20, 2.5, 2.5, GOLD[3])
	for k in 8:
		var a := TAU * float(k) / 8.0
		PtArt._px(img, cx + int(round(cos(a) * 6.5)), top + 20 + int(round(sin(a) * 6.5)), GOLD[2])


# ─── 소품 ───────────────────────────────────────────

## 화로 (16×24): 돌 받침 + 쇠 그릇 (불꽃은 flame 시트를 위에 따로)
static func brazier() -> ImageTexture:
	if _cache.has("brazier"):
		return _cache.brazier
	var img := Image.create(16, 24, false, Image.FORMAT_RGBA8)
	PtArt._rect(img, 2, 8, 13, 10, IRON[2])
	PtArt._rect(img, 3, 11, 12, 12, IRON[1])
	PtArt._rect(img, 4, 7, 11, 7, Color("#ff9a3a"))
	for y in range(13, 22):
		for x in range(4, 12):
			img.set_pixel(x, y, WALL[4] if x < 6 else (WALL[3] if x < 10 else WALL[2]))
	PtArt._rect(img, 3, 21, 12, 22, WALL[3])
	PtArt._outline(img)
	PtArt._shadow(img, 8, 23, 7, 2)
	return _done("brazier", img)


## 불꽃 3장 가로 시트 (각 12×14)
static func flame() -> ImageTexture:
	if _cache.has("flame"):
		return _cache.flame
	var img := Image.create(36, 14, false, Image.FORMAT_RGBA8)
	for f in 3:
		for y in 14:
			for x in 12:
				var h := 13.0 - float(y)
				var w := 5.0 * (1.0 - h / 14.0) * (0.8 + 0.2 * sin(float(f) * 2.1 + h * 0.7))
				var dx := float(x) - 5.5 - sin(h * 0.5 + float(f) * 1.7) * 1.2
				if absf(dx) > w:
					continue
				var k := absf(dx) / maxf(w, 0.1)
				var c := Color("#c83a14")
				if k < 0.75:
					c = Color("#ff8a2a")
				if k < 0.4 and h < 9.0:
					c = Color("#ffd86a")
				if k < 0.2 and h < 5.0:
					c = Color("#fff6d0")
				img.set_pixel(f * 12 + x, y, c)
	return _done("flame", img)


## 부드러운 빛 (32×32, 더하기 섞기용)
static func glow() -> ImageTexture:
	if _cache.has("glow"):
		return _cache.glow
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		for x in 32:
			var d := Vector2(float(x) - 15.5, float(y) - 15.5).length() / 16.0
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = floor(a * a * 6.0) / 6.0 # 계단 빛 (픽셀 느낌)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return _done("glow", img)


## 적 진지의 붉은 깃발 (18×48): 막대 + 검붉은 천 + 뿔 문장
static func enemy_banner() -> ImageTexture:
	if _cache.has("ebanner"):
		return _cache.ebanner
	var img := Image.create(18, 48, false, Image.FORMAT_RGBA8)
	PtArt._rect(img, 8, 0, 9, 46, WOOD[2])
	PtArt._rect(img, 2, 3, 15, 4, WOOD[1])
	for y in range(5, 34):
		for x in range(3, 15):
			if y > 28 and (x * 7 + y) % 5 == 0:
				continue # 찢긴 끝
			img.set_pixel(x, y, BLOOD[1] if x < 9 else BLOOD[0])
	for i in 6: # 뿔 문장
		PtArt._px(img, 5 + i / 2, 10 + i, Color("#d8c8b0"))
		PtArt._px(img, 12 - i / 2, 10 + i, Color("#d8c8b0"))
	PtArt._ellipse(img, 8.5, 19, 2.5, 2.5, Color("#d8c8b0"))
	PtArt._px(img, 7, 19, BLOOD[0])
	PtArt._px(img, 10, 19, BLOOD[0])
	PtArt._outline(img)
	PtArt._shadow(img, 9, 47, 5, 1.5)
	return _done("ebanner", img)


## 말뚝 바리케이드 (44×20): 엇갈린 통나무 끝을 깎음
static func barricade(v: int) -> ImageTexture:
	var key := "barricade%d" % v
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(44, 20, false, Image.FORMAT_RGBA8)
	PtArt._rect(img, 2, 13, 41, 15, WOOD[1]) # 가로 받침
	PtArt._rect(img, 2, 13, 41, 13, WOOD[3])
	for i in 5:
		var bx := 5 + i * 8 + (1 if v == 1 else 0)
		var lean := 1 if i % 2 == 0 else -1
		for y in range(2, 18):
			var x := bx + lean * (17 - y) / 4
			PtArt._rect(img, x, y, x + 2, y, WOOD[2] if y > 4 else Color("#d8c0a0"))
			PtArt._px(img, x, y, WOOD[3])
	PtArt._outline(img)
	PtArt._shadow(img, 22, 18, 20, 2)
	return _done(key, img)


## 보라 수정 덩어리 (18×22)
static func crystal() -> ImageTexture:
	if _cache.has("crystal"):
		return _cache.crystal
	var img := Image.create(18, 22, false, Image.FORMAT_RGBA8)
	var shards := [[9, 2, 3], [5, 8, 2], [13, 7, 2], [7, 11, 2]] # 꼭대기 x, y, 반폭
	for s: Array in shards:
		var tx: int = s[0]
		var ty: int = s[1]
		var hw: int = s[2]
		for y in range(ty, 20):
			var w := mini(hw, (y - ty) / 2 + 1)
			for x in range(tx - w, tx + w + 1):
				img.set_pixel(x, y, VIOLET[4] if x == tx - w + 1 and y < ty + 6 else (VIOLET[3] if x <= tx else VIOLET[2]))
	PtArt._outline(img)
	PtArt._shadow(img, 9, 21, 7, 1.5)
	return _done("crystal", img)


## 화살 (16×3, 오른쪽을 향함 — 돌려서 씀). 밝은 꼬리빛을 달아 해 질 녘에도 보이게
static func arrow() -> ImageTexture:
	if _cache.has("arrow"):
		return _cache.arrow
	var img := Image.create(16, 3, false, Image.FORMAT_RGBA8)
	PtArt._rect(img, 0, 1, 4, 1, Color(1.0, 0.9, 0.6, 0.45))
	PtArt._rect(img, 5, 1, 12, 1, Color("#e0b878"))
	PtArt._rect(img, 12, 0, 14, 2, STEEL[3])
	PtArt._px(img, 15, 1, Color.WHITE)
	PtArt._rect(img, 4, 0, 6, 0, Color("#fff4e0"))
	PtArt._rect(img, 4, 2, 6, 2, Color("#fff4e0"))
	return _done("arrow", img)


## 어둠 마법사의 보라 구슬 (10×10)
static func orb() -> ImageTexture:
	if _cache.has("orb"):
		return _cache.orb
	var img := Image.create(10, 10, false, Image.FORMAT_RGBA8)
	PtArt._ellipse(img, 5, 5, 4.6, 4.6, VIOLET[2])
	PtArt._ellipse(img, 5, 5, 3.2, 3.2, VIOLET[3])
	PtArt._ellipse(img, 4.5, 4.5, 1.6, 1.6, VIOLET[4])
	return _done("orb", img)


# ─── 인물 ───────────────────────────────────────────

const SKIN := Color("#f6d6bc")
const SKIN_D := Color("#d8aa90")
const BLOND := Color("#f0dc9c")
const BLOND_D := Color("#c8a85e")
const BLOND_L := Color("#fff4cc")
const ELF_EYE := Color("#2a4a6a")
const CLOTH_W := Color("#e2e0ec")
const CLOTH_WD := Color("#aaa6c0")


## 엘프 궁수 시트 (140×84): 줄 0 아래 · 1 위 · 2 오른쪽, 칸 0~1 대기 · 2~5 걷기 · 6 쏘기(활을 당김)
static func archer_sheet() -> ImageTexture:
	if _cache.has("archer"):
		return _cache.archer
	var img := Image.create(PERSON_CELL.x * 7, PERSON_CELL.y * 3, false, Image.FORMAT_RGBA8)
	for d in 3:
		for f in 7:
			_archer(img, f * PERSON_CELL.x, d * PERSON_CELL.y, d, f)
			PtArt._outline(img, OUT, f * PERSON_CELL.x, d * PERSON_CELL.y, PERSON_CELL.x, PERSON_CELL.y)
	return _done("archer", img)


static func _archer(img: Image, ox: int, oy: int, dir: int, f: int) -> void:
	var b := 1 if f == 1 else 0
	var lift_l := 0
	var lift_r := 0
	var stride := 0
	if f >= 2 and f <= 5:
		var k := f - 2
		b = -1 if k % 2 == 0 else 0
		if k == 1:
			lift_l = 1
			stride = 2
		elif k == 3:
			lift_r = 1
			stride = -2
	var shoot := f == 6
	var R := func(x0: int, y0: int, x1: int, y1: int, c: Color) -> void: PtArt._rect(img, ox + x0, oy + y0, ox + x1, oy + y1, c)
	var P := func(x: int, y: int, c: Color) -> void: PtArt._px(img, ox + x, oy + y, c)
	var E := func(cx: float, cy: float, rx: float, ry: float, c: Color) -> void: PtArt._ellipse(img, ox + cx, oy + cy, rx, ry, c)
	if dir == 2: # 옆 (오른쪽)
		R.call(4, 12 + b, 8, 23, NAVY[1]) # 망토
		R.call(4, 23, 8, 23, GOLD[2])
		E.call(8.0, 10.0 + b, 4.0, 6.5, BLOND_D) # 등 뒤 긴 머리
		var bx := 9 - stride / 2
		var fx := 10 + stride / 2
		R.call(bx, 20, bx + 1, 23, CLOTH_WD)
		R.call(bx - 1, 24, bx + 1, 26, WOOD[1])
		R.call(7, 13 + b, 12, 19 + b, CLOTH_W)
		R.call(11, 13 + b, 12, 19 + b, CLOTH_WD)
		R.call(7, 15 + b, 12, 15 + b, NAVY[2])
		R.call(7, 19 + b, 12, 19 + b, GOLD[1])
		R.call(fx, 20, fx + 1, 23, CLOTH_W)
		R.call(fx, 24, fx + 2, 26, WOOD[2])
		E.call(10.5, 8.0 + b, 4.6, 4.4, SKIN)
		E.call(9.0, 6.0 + b, 5.0, 3.6, BLOND)
		R.call(6, 7 + b, 8, 12 + b, BLOND)
		R.call(7, 3 + b, 10, 3 + b, BLOND_L)
		P.call(14, 8 + b, SKIN) # 뾰족 귀는 뒤쪽이라 앞머리 아래 점
		R.call(8, 6 + b, 9, 7 + b, SKIN_D)
		P.call(7, 5 + b, SKIN) # 귀 끝
		R.call(13, 8 + b, 13, 9 + b, ELF_EYE)
		if shoot: # 활을 앞으로 내밀고 시위를 당김
			R.call(11, 13 + b, 15, 14 + b, CLOTH_W)
			R.call(16, 7 + b, 16, 20 + b, GOLD[2])
			P.call(15, 6 + b, GOLD[2])
			P.call(15, 21 + b, GOLD[2])
			for y in range(7, 21):
				P.call(12 + absi(y - 13) / 3, y + b, Color("#f0f0f0"))
			R.call(12, 13 + b, 18, 13 + b, WOOD[3]) # 시위에 건 화살
			P.call(19, 13 + b, STEEL[3])
		else:
			R.call(9, 14 + b, 10, 18 + b, CLOTH_WD)
			R.call(13, 8 + b, 13, 21 + b, GOLD[1]) # 든 활 (세로)
			P.call(12, 7 + b, GOLD[1])
			P.call(12, 22 + b, GOLD[1])
		return
	if dir == 0:
		R.call(4, 13 + b, 15, 23, NAVY[1]) # 망토 (몸 뒤)
		R.call(4, 23, 15, 23, GOLD[2])
		E.call(10.0, 11.0 + b, 6.5, 7.0, BLOND_D) # 뒤로 늘어진 긴 머리
	for side in [0, 1]:
		var lx := 7 if side == 0 else 11
		var up: int = lift_l if side == 0 else lift_r
		R.call(lx, 20 - up, lx + 1, 23 - up, CLOTH_W)
		R.call(lx - (1 if side == 0 else 0), 24 - up, lx + 1 + (0 if side == 0 else 1), 26 - up, WOOD[2])
	R.call(6, 13 + b, 13, 19 + b, CLOTH_W)
	R.call(12, 13 + b, 13, 19 + b, CLOTH_WD)
	R.call(8, 13 + b, 11, 13 + b, NAVY[2])
	R.call(9, 14 + b, 10, 17 + b, NAVY[1] if dir == 0 else CLOTH_W)
	R.call(6, 19 + b, 13, 19 + b, GOLD[1])
	R.call(4, 14 + b, 5, 18 + b, CLOTH_WD)
	R.call(14, 14 + b, 15, 18 + b, CLOTH_WD)
	R.call(4, 19 + b, 5, 19 + b, SKIN)
	R.call(14, 19 + b, 15, 19 + b, SKIN)
	if dir == 0:
		E.call(10.0, 8.5 + b, 4.8, 4.6, SKIN)
		E.call(10.0, 6.0 + b, 5.6, 3.6, BLOND)
		for x in range(5, 15):
			R.call(x, 4 + b, x, 6 + b + (1 if x % 4 == 1 else 0), BLOND_D if x >= 12 else BLOND)
		R.call(4, 7 + b, 5, 16 + b, BLOND) # 얼굴 옆 긴 머리
		R.call(14, 7 + b, 15, 16 + b, BLOND_D)
		R.call(7, 3 + b, 10, 3 + b, BLOND_L)
		P.call(3, 8 + b, SKIN) # 뾰족 귀
		P.call(2, 7 + b, SKIN)
		P.call(16, 8 + b, SKIN)
		P.call(17, 7 + b, SKIN)
		R.call(8, 9 + b, 8, 10 + b, ELF_EYE)
		R.call(11, 9 + b, 11, 10 + b, ELF_EYE)
		R.call(9, 2 + b, 10, 2 + b, GOLD[3]) # 머리 장식
		if shoot: # 활을 앞(아래)으로 겨눔
			R.call(5, 21 + b, 14, 21 + b, GOLD[2])
			P.call(4, 20 + b, GOLD[2])
			P.call(15, 20 + b, GOLD[2])
			R.call(9, 16 + b, 10, 23 + b, WOOD[3])
			P.call(9, 24 + b, STEEL[3])
		else:
			R.call(2, 11 + b, 2, 22 + b, GOLD[1]) # 옆에 든 활
			P.call(3, 10 + b, GOLD[1])
			P.call(3, 23 + b, GOLD[1])
	else: # 등: 긴 머리가 망토를 덮음 · 등의 화살통
		R.call(5, 13 + b, 14, 22, NAVY[1])
		R.call(5, 22, 14, 22, GOLD[2])
		R.call(12, 9 + b, 14, 16 + b, WOOD[2]) # 화살통
		R.call(12, 8 + b, 14, 8 + b, Color("#f0e8d8"))
		E.call(10.0, 8.0 + b, 5.4, 5.0, BLOND)
		R.call(6, 10 + b, 13, 19 + b, BLOND)
		R.call(8, 12 + b, 8, 19 + b, BLOND_D)
		R.call(11, 12 + b, 11, 19 + b, BLOND_D)
		R.call(7, 3 + b, 10, 3 + b, BLOND_L)
		P.call(3, 7 + b, SKIN)
		P.call(16, 7 + b, SKIN)
		if shoot:
			R.call(5, 5 + b, 14, 5 + b, GOLD[2]) # 머리 위로 겨눈 활
			R.call(9, 3 + b, 10, 9 + b, WOOD[3])


## 서 있는 병사 시트 (40×28, 대기 2장): spear = 창병, 아니면 방패 든 기사
static func soldier_sheet(spear: bool) -> ImageTexture:
	var key := "soldier%d" % int(spear)
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(PERSON_CELL.x * 2, PERSON_CELL.y, false, Image.FORMAT_RGBA8)
	for f in 2:
		var ox := f * PERSON_CELL.x
		var b := f
		var R := func(x0: int, y0: int, x1: int, y1: int, c: Color) -> void: PtArt._rect(img, ox + x0, y0, ox + x1, y1, c)
		var E := func(cx: float, cy: float, rx: float, ry: float, c: Color) -> void: PtArt._ellipse(img, ox + cx, cy, rx, ry, c)
		R.call(5, 13 + b, 14, 23, NAVY[0]) # 망토
		for lx: int in [7, 11]:
			R.call(lx, 20, lx + 1, 23, STEEL[1])
			R.call(lx - (1 if lx == 7 else 0), 24, lx + 1 + (0 if lx == 7 else 1), 26, IRON[1])
		R.call(6, 13 + b, 13, 19 + b, STEEL[2])
		R.call(12, 13 + b, 13, 19 + b, STEEL[1])
		R.call(8, 14 + b, 11, 19 + b, NAVY[2]) # 겉옷
		PtArt._px(img, ox + 9, 16 + b, GOLD[2])
		PtArt._px(img, ox + 10, 16 + b, GOLD[2])
		R.call(4, 13 + b, 5, 18 + b, STEEL[1])
		R.call(14, 13 + b, 15, 18 + b, STEEL[1])
		E.call(10.0, 8.0 + b, 4.8, 4.8, STEEL[2]) # 투구
		E.call(9.0, 7.0 + b, 2.5, 2.5, STEEL[3])
		R.call(6, 9 + b, 14, 9 + b, IRON[0]) # 눈 틈
		R.call(9, 3 + b, 10, 3 + b, STEEL[3])
		if spear:
			R.call(16, 0, 16, 25, WOOD[2])
			R.call(15, 0, 17, 2, STEEL[3])
			PtArt._px(img, ox + 16, 0, STEEL[3])
		else:
			for y in range(14, 25): # 방패 (남색 + 금 테 + 해 문장)
				var hw := 4 if y < 21 else 4 - (y - 20)
				for x in range(3 - hw / 2, 3 + hw + 1):
					R.call(x, y + b, x, y + b, GOLD[2] if x == 3 - hw / 2 or x == 3 + hw or y == 14 else NAVY[2])
			PtArt._px(img, ox + 4, 18 + b, GOLD[3])
		PtArt._outline(img, OUT, ox, 0, PERSON_CELL.x, PERSON_CELL.y)
	return _done(key, img)


## 구울 시트 (110×22): 칸 0~3 걷기 · 4 내려치기. 앞모습(옆으로 갈 때는 뒤집기)
static func ghoul_sheet() -> ImageTexture:
	if _cache.has("ghoul"):
		return _cache.ghoul
	var img := Image.create(GHOUL_CELL.x * 5, GHOUL_CELL.y, false, Image.FORMAT_RGBA8)
	var G := [Color("#4a4f5c"), Color("#6c7384"), Color("#9198aa"), Color("#b8bfce")] # 잿빛 피부 (어두운 풀과 떨어지게 밝게)
	for f in 5:
		var ox := f * GHOUL_CELL.x
		var b := 1 if f % 2 == 1 else 0
		var step: int = [-1, 0, 1, 0, 0][f] # 다리 앞뒤
		var atk := f == 4
		var R := func(x0: int, y0: int, x1: int, y1: int, c: Color) -> void: PtArt._rect(img, ox + x0, y0, ox + x1, y1, c)
		var E := func(cx: float, cy: float, rx: float, ry: float, c: Color) -> void: PtArt._ellipse(img, ox + cx, cy, rx, ry, c)
		R.call(7 - step, 15, 8 - step, 20, G[0]) # 다리
		R.call(13 + step, 15, 14 + step, 20, G[1])
		E.call(11.0, 11.0 + b, 6.5, 5.5, G[2]) # 구부정한 몸
		E.call(10.0, 10.0 + b, 4.0, 3.5, G[3])
		R.call(13, 12 + b, 16, 14 + b, G[1])
		E.call(11.0, 6.0 + b, 4.0, 3.5, G[2]) # 머리 (앞으로 숙임)
		R.call(9, 6 + b, 9, 6 + b, Color("#ff3a3a"))
		R.call(12, 6 + b, 12, 6 + b, Color("#ff3a3a"))
		R.call(9, 8 + b, 13, 8 + b, G[0]) # 입
		R.call(10, 8 + b, 10, 8 + b, Color("#e8e0c8"))
		R.call(12, 8 + b, 12, 8 + b, Color("#e8e0c8"))
		R.call(3, 10 + b, 5, 15 + b, G[1]) # 왼팔 + 발톱
		R.call(3, 16 + b, 3, 17 + b, Color("#e8e0c8"))
		if atk: # 칼을 머리 위로
			R.call(16, 3, 17, 10, G[1])
			for i in 7:
				R.call(17 + i / 3, 2 - i / 3 + i, 18 + i / 3, 2 - i / 3 + i, STEEL[2 + (1 if i < 2 else 0)])
		else: # 휜 칼을 아래로 듦
			R.call(16, 11 + b, 17, 15 + b, G[1])
			for i in 6:
				R.call(18, 13 + b + i, 19, 13 + b + i, STEEL[2] if i < 5 else STEEL[3])
			PtArt._px(img, ox + 17, 18 + b, STEEL[1])
		PtArt._outline(img, OUT, ox, 0, GHOUL_CELL.x, GHOUL_CELL.y)
	return _done("ghoul", img)


## 어둠 마법사 시트 (66×30): 칸 0~1 걷기 · 2 시전(지팡이를 들고 구슬이 밝음). 두건 쓴 보라 로브
static func mage_sheet() -> ImageTexture:
	if _cache.has("mage"):
		return _cache.mage
	var img := Image.create(MAGE_CELL.x * 3, MAGE_CELL.y, false, Image.FORMAT_RGBA8)
	for f in 3:
		var ox := f * MAGE_CELL.x
		var b := 1 if f == 1 else 0
		var cast := f == 2
		var R := func(x0: int, y0: int, x1: int, y1: int, c: Color) -> void: PtArt._rect(img, ox + x0, y0, ox + x1, y1, c)
		var E := func(cx: float, cy: float, rx: float, ry: float, c: Color) -> void: PtArt._ellipse(img, ox + cx, cy, rx, ry, c)
		for y in range(12, 29): # 로브 (아래로 넓어짐)
			var hw := 3 + (y - 12) / 3
			for x in range(11 - hw, 11 + hw + 1):
				R.call(x, y + (b if y < 27 else 0), x, y + (b if y < 27 else 0), VIOLET[2] if x < 10 else VIOLET[1])
		R.call(9, 14 + b, 12, 26 + b, VIOLET[0]) # 앞섶
		E.call(11.0, 9.0 + b, 5.0, 5.5, VIOLET[2]) # 두건
		E.call(11.0, 10.0 + b, 3.2, 3.2, Color("#120a18")) # 그늘진 얼굴
		R.call(9, 10 + b, 9, 10 + b, VIOLET[4])
		R.call(12, 10 + b, 12, 10 + b, VIOLET[4])
		R.call(11, 3 + b, 11, 4 + b, VIOLET[2]) # 두건 끝
		var sy := 4 if cast else 8
		R.call(17, sy + b, 17, 27, WOOD[1]) # 지팡이
		R.call(15, 15 + b, 16, 16 + b, VIOLET[1]) # 지팡이 쥔 손
		var oc: Color = VIOLET[4] if cast else VIOLET[3]
		PtArt._ellipse(img, ox + 17.5, sy - 1 + b, 2.6 if cast else 2.0, 2.6 if cast else 2.0, oc)
		PtArt._outline(img, OUT, ox, 0, MAGE_CELL.x, MAGE_CELL.y)
	return _done("mage", img)
