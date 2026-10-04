class_name TilePainter
extends RefCounted
## 방의 타일을 이미지 한 장으로 굽는다 (방에 들어갈 때 한 번). 매 프레임 수천 개의 사각형을 그리는 대신
## 텍스처 한 장만 그리므로 웹에서도 가볍다. 굵은 덩어리 픽셀(2·4px 단위)로 INARI풍 질감을 낸다.

const T := 16


static func _h(x: int, y: int, s: int = 0) -> int:
	var n := x * 374761393 + y * 668265263 + s * 2147483647
	n = (n ^ (n >> 13)) * 1274126177
	return absi(n ^ (n >> 16))


static func is_solid_char(c: String) -> bool:
	return c == "#" or c == "I" or c == "W"


## cells: 그릴 칸 문자 집합 (예: "#" 본 지형, "I" 환영 벽만)
## region: 이미지로 만들 범위(타일). 비우면 방 전체
static func paint(data: RoomData, theme: Dictionary, cells := "#", region := Rect2i()) -> Image:
	var cols := data.cols()
	var rows := data.row_count()
	if region.size == Vector2i.ZERO:
		region = Rect2i(0, 0, cols, rows)
	var img := Image.create(region.size.x * T, region.size.y * T, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var c := data.char_at(x, y)
			if not cells.contains(c):
				continue
			var ox := (x - region.position.x) * T
			var oy := (y - region.position.y) * T
			match c:
				"#", "I":
					_paint_solid(img, data, theme, x, y, ox, oy)
				"=":
					_paint_platform(img, data, theme, x, y, ox, oy)
				"^":
					_paint_spike(img, data, theme, x, y, ox, oy)
				"W":
					_paint_breakable(img, theme, x, y, ox, oy)
	return img


static func _open(data: RoomData, x: int, y: int) -> bool:
	return not is_solid_char(data.char_at(x, y))


## 가장 가까운 빈칸까지 거리 (깊을수록 어둡게)
static func _depth(data: RoomData, x: int, y: int) -> int:
	for d in range(1, 5):
		if _open(data, x - d, y) or _open(data, x + d, y) or _open(data, x, y - d) or _open(data, x, y + d) \
				or _open(data, x - d, y - d) or _open(data, x + d, y - d) or _open(data, x - d, y + d) or _open(data, x + d, y + d):
			return d - 1
	return 4


static func _paint_solid(img: Image, data: RoomData, th: Dictionary, x: int, y: int, ox: int, oy: int) -> void:
	var depth := _depth(data, x, y)
	var base: Color = th.base
	var deep: Color = th.deep
	var col := base.lerp(deep, clampf(depth / 3.0, 0.0, 1.0))
	img.fill_rect(Rect2i(ox, oy, T, T), col)
	var seam: Color = (th.seam as Color).lerp(deep, clampf(depth / 3.0, 0.0, 1.0))
	if depth <= 2:
		_pattern(img, th, x, y, ox, oy, seam, col)
	# 질감 얼룩 (2px 덩어리)
	var hh := _h(x, y, 3)
	if depth <= 1 and hh % 3 == 0:
		var px := ox + (hh >> 4) % 6 * 2
		var py := oy + (hh >> 8) % 6 * 2
		img.fill_rect(Rect2i(px, py, 2, 2), col.lightened(0.08))
	if depth <= 1 and hh % 5 == 1:
		img.fill_rect(Rect2i(ox + (hh >> 6) % 7 * 2, oy + (hh >> 10) % 7 * 2, 2, 2), col.darkened(0.25))

	var up := _open(data, x, y - 1)
	var down := _open(data, x, y + 1)
	var left := _open(data, x - 1, y)
	var right := _open(data, x + 1, y)
	var edge: Color = th.edge
	if left:
		img.fill_rect(Rect2i(ox, oy, 2, T), edge)
		img.fill_rect(Rect2i(ox + 2, oy, 1, T), col.lightened(0.06))
	if right:
		img.fill_rect(Rect2i(ox + T - 2, oy, 2, T), edge)
	if down:
		img.fill_rect(Rect2i(ox, oy + T - 3, T, 3), edge)
	if up:
		var top: Color = th.top
		var hi: Color = th.top_hi
		img.fill_rect(Rect2i(ox, oy, T, 4), top)
		img.fill_rect(Rect2i(ox, oy, T, 1), hi)
		img.fill_rect(Rect2i(ox, oy + 4, T, 1), top.darkened(0.35))
		if left:
			img.fill_rect(Rect2i(ox, oy, 2, 4), hi.darkened(0.2))
		if right:
			img.fill_rect(Rect2i(ox + T - 2, oy, 2, 4), top.darkened(0.2))
		_cap(img, th, x, y, ox, oy)


static func _pattern(img: Image, th: Dictionary, x: int, y: int, ox: int, oy: int, seam: Color, col: Color) -> void:
	match th.pattern:
		"brick":
			# 16×8 벽돌, 줄마다 반 칸 어긋남
			img.fill_rect(Rect2i(ox, oy + 7, T, 1), seam)
			img.fill_rect(Rect2i(ox, oy + 15, T, 1), seam)
			var off := 8 if y % 2 == 0 else 0
			img.fill_rect(Rect2i(ox + off, oy, 1, 7), seam)
			img.fill_rect(Rect2i(ox + (8 - off), oy + 8, 1, 7), seam)
			img.fill_rect(Rect2i(ox + off + 1, oy, 6, 1), col.lightened(0.05))
		"stone":
			# 32×16 큰 돌, 2칸마다 이음새
			img.fill_rect(Rect2i(ox, oy + 15, T, 1), seam)
			if (x + (y % 2)) % 2 == 0:
				img.fill_rect(Rect2i(ox, oy, 1, T), seam)
				img.fill_rect(Rect2i(ox + 1, oy, 6, 1), col.lightened(0.06))
			var hh := _h(x, y, 11)
			if hh % 4 == 0:
				img.fill_rect(Rect2i(ox + 4 + hh % 6, oy + 6, 4, 1), seam) # 금
		"plank":
			# 나무 판자: 세로 판 4px
			for i in 4:
				img.fill_rect(Rect2i(ox + i * 4, oy, 1, T), seam)
			if _h(x, y, 5) % 3 == 0:
				img.fill_rect(Rect2i(ox + 5, oy + 6, 2, 2), seam)
		"tile":
			# 기와·타일: 8×8 격자
			img.fill_rect(Rect2i(ox, oy + 7, T, 1), seam)
			img.fill_rect(Rect2i(ox, oy + 15, T, 1), seam)
			img.fill_rect(Rect2i(ox + 7, oy, 1, T), seam)
			img.fill_rect(Rect2i(ox + 15, oy, 1, T), seam)


static func _cap(img: Image, th: Dictionary, x: int, y: int, ox: int, oy: int) -> void:
	var cc: Color = th.cap_col
	var hh := _h(x, y, 7)
	match th.cap:
		"moss":
			# 윗면에서 아래로 늘어진 이끼 몇 가닥
			img.fill_rect(Rect2i(ox, oy, T, 2), cc.lightened(0.15))
			for i in 3:
				var px := ox + (hh >> (i * 3)) % 7 * 2
				var ln := 2 + (hh >> (i * 5)) % 4 * 2
				img.fill_rect(Rect2i(px, oy + 2, 2, ln), cc)
		"carpet":
			img.fill_rect(Rect2i(ox, oy + 1, T, 3), cc)
			img.fill_rect(Rect2i(ox, oy + 1, T, 1), cc.lightened(0.25))
			if x % 4 == 0:
				img.fill_rect(Rect2i(ox + 6, oy + 2, 2, 1), Color("#d8a84a"))
		"gold":
			img.fill_rect(Rect2i(ox, oy + 3, T, 1), cc)
			if x % 3 == 0:
				img.fill_rect(Rect2i(ox + 7, oy + 2, 2, 2), cc.lightened(0.3))
		"snow":
			img.fill_rect(Rect2i(ox, oy, T, 2), Color(0.8, 0.8, 0.9))


static func _paint_platform(img: Image, data: RoomData, th: Dictionary, x: int, y: int, ox: int, oy: int) -> void:
	var p: Color = th.plat
	var hi: Color = th.plat_hi
	img.fill_rect(Rect2i(ox, oy, T, 5), p)
	img.fill_rect(Rect2i(ox, oy, T, 1), hi)
	img.fill_rect(Rect2i(ox, oy + 5, T, 1), p.darkened(0.5))
	if x % 2 == 0:
		img.fill_rect(Rect2i(ox + 15, oy + 1, 1, 4), p.darkened(0.3))
	# 받침대: 발판 끝 또는 3칸마다
	var left_end := data.char_at(x - 1, y) != "="
	var right_end := data.char_at(x + 1, y) != "="
	if left_end or right_end or x % 4 == 0:
		var bx := ox + (2 if left_end else (11 if right_end else 6))
		img.fill_rect(Rect2i(bx, oy + 6, 3, 2), p.darkened(0.4))
		img.fill_rect(Rect2i(bx + 1, oy + 8, 1, 3), p.darkened(0.45))


static func _paint_spike(img: Image, data: RoomData, th: Dictionary, x: int, y: int, ox: int, oy: int) -> void:
	var s: Color = th.spike
	var tip: Color = th.accent
	var from_top := is_solid_char(data.char_at(x, y - 1)) and not is_solid_char(data.char_at(x, y + 1))
	for i in 3:
		var bx := ox + 1 + i * 5
		for step in 6:
			var w := 5 - step * 5 / 6
			var yy := oy + T - 1 - step * 2 if not from_top else oy + step * 2
			img.fill_rect(Rect2i(bx + (5 - w) / 2, yy - (1 if not from_top else 0), maxi(w, 1), 2), s.lightened(step * 0.04))
		var ty := oy + 4 if not from_top else oy + T - 6
		img.fill_rect(Rect2i(bx + 2, ty, 1, 2), tip)


static func _paint_breakable(img: Image, th: Dictionary, x: int, y: int, ox: int, oy: int) -> void:
	var wood := Color("#5a3a26")
	img.fill_rect(Rect2i(ox, oy, T, T), wood.darkened(0.3))
	for i in 3:
		img.fill_rect(Rect2i(ox, oy + 1 + i * 5, T, 4), wood.lightened(0.05 * i))
		img.fill_rect(Rect2i(ox, oy + 1 + i * 5, T, 1), wood.lightened(0.25))
	img.fill_rect(Rect2i(ox + 3 + (x + y) % 2 * 8, oy, 2, T), wood.darkened(0.45))
	img.fill_rect(Rect2i(ox + 7, oy + 7, 2, 2), Color("#2a1a12"))
