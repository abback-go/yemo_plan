extends RefCounted
## 배경 그리기 공용 틀 — RoomBackdrop(층·하늘)와 backdrop_<장>.gd가 함께 쓴다. 자세한 설명: docs/dev/backdrop.md
##
## 정적/동적 분리 계약 (성능 핵심, 웹·태블릿 대비):
##   층·하늘의 그리기 함수(draw_layer/draw_sky)는 방에 들어갈 때 **한 번만** 불린다. 이때 받는 `l`(또는 `c`)은
##   진짜 캔버스가 아니라 Pen(기록기)이다.
##   - l.draw_rect/draw_circle/draw_line/draw_colored_polygon/draw_polyline/draw_arc/draw_set_transform
##       → 정적 그림. 기록했다가 StaticPart가 한 번만 그린다(다시 그리지 않음).
##   - l.anim(bbox, func(c: CanvasItem, t: float))
##       → 움직이는 요소. AnimPart가 틱마다(Ticker.hz, 기본 30Hz) t로 다시 그린다. c는 진짜 CanvasItem.
##         bbox = 움직임 전체를 덮는 사각형(층 좌표). 화면 밖이면 그리지 않고, 그리는 순서 계산에도 쓴다 → 넉넉하게.
##   - l.fn(bbox, func(c: CanvasItem)) → 정적인데 CanvasItem 타입만 받는 도우미(KArt·ART)를 부를 때.
##   - l.on_process(func(node: Node2D, t: float)) → 그리기가 아닌 매 프레임 일(층 흔들기 등). _draw 안에서 하지 말 것.
##   rng는 기록할 때만 쓴다: 움직이는 요소의 난수(연기 seed 등)는 람다 **밖에서** 미리 뽑아 둔다(호출 순서 = 배치).
##
## 순서 보존: 겹치는 그림끼리는 원래 순서 그대로, 겹치지 않는 것만 같은 노드로 모은다(격자 칸 단위로 보수적으로 판단).
## 그래서 정적 그림 사이에 끼어 있던 움직이는 요소도 원래와 같은 위·아래 관계로 그려진다(그림이 바뀌지 않음).

const KArt := preload("res://world/entities/ch2/k_art.gd")

## 그리기 영역 전체 (bbox를 모를 때 — 순서 계산에서 모든 것과 겹친다고 본다)
const ALL := Rect2(-100000, -100000, 200000, 200000)
## 동적 요소 화면 밖 판단 여유(px). 틱 사이 스크롤보다 커야 가장자리에서 늦게 나타나지 않는다
const CULL_MARGIN := 64.0

## 다시 그리기 박자: step(delta)가 true인 프레임에만 다시 그린다 (Ticker.hz)
class Ticker extends RefCounted:
	## 움직이는 그림의 다시 그리기 상한(Hz). 시간(t)은 매 프레임 흐르고 queue_redraw만 이 주기로 한다.
	## 0 이하 = 매 프레임(상한 끔). 시험 실행기는 픽셀 비교를 위해 0으로 둔다(시나리오 "bg_hz", 단계 "bghz").
	static var hz := 30.0
	var _acc := 0.0

	func step(delta: float) -> bool:
		if hz <= 0.0:
			return true
		var period := 1.0 / hz
		_acc += delta
		if _acc + 0.000001 < period:
			return false
		_acc -= period
		if _acc > period:
			_acc = 0.0
		return true


# ═══════════════════════════════════════════════════════════
# Pen: 기록기
# ═══════════════════════════════════════════════════════════

class Pen extends RefCounted:
	const OP_RECT := 0
	const OP_CIRCLE := 1
	const OP_LINE := 2
	const OP_POLY := 3
	const OP_POLYLINE := 4
	const OP_ARC := 5
	const OP_FN := 6
	const OP_XF := 7
	const CELL := 64.0 ## 겹침 판단 격자 칸(px)
	const CHUNK := 320.0 ## 정적 부분을 가로로 나누는 폭(px) — 화면 밖 조각은 렌더러가 건너뛴다
	const KEYS := 4096 ## 정적 자리 key = level * KEYS + 조각 번호
	const PAD := 2.0 ## bbox 여유(안티에일리어싱·반올림)

	## 층 정보 — 테마 함수가 l.theme / l.room_size / l.scroll / l.depth / l.room_id로 읽는다 (BackdropLayer와 같은 이름)
	var theme := {}
	var theme_name := ""
	var room_size := Vector2(640, 368)
	var scroll := 0.5
	var depth := 0
	var room_id := ""

	## levels[i]: 짝수 i = 정적 {조각 번호: 명령 목록}, 홀수 i = 동적 항목 목록 [bbox, Callable, Transform2D]
	var levels: Array = []
	var post: Array[Node] = [] ## 모든 부분 위에 붙일 노드 (3장 Anim)
	var procs: Array[Callable] = [] ## 매 프레임 부를 것 (node, t)
	var commands := 0 ## 기록한 정적 명령 수 (계측용)
	var anims := 0 ## 기록한 동적 항목 수 (계측용)

	var _xf := Transform2D.IDENTITY
	var _last_xf := {} ## 정적 자리 key → 그 목록의 마지막 변환
	var _org := Vector2(-256, -256)
	var _cw := 1
	var _ch := 1
	var _gs := PackedInt32Array() ## 칸별 가장 높은 정적 자리 key (-1 = 없음)
	var _ga := PackedInt32Array() ## 칸별 가장 높은 동적 level (-1 = 없음)

	func _init(area: Vector2) -> void:
		_cw = int(ceil((area.x + 512.0) / CELL)) + 1
		_ch = int(ceil((area.y + 512.0) / CELL)) + 1
		_gs.resize(_cw * _ch)
		_gs.fill(-1)
		_ga.resize(_cw * _ch)
		_ga.fill(-1)

	# ── 정적 그리기 (CanvasItem과 같은 이름·기본값) ──

	func draw_rect(rect: Rect2, color: Color, filled := true, width := -1.0, antialiased := false) -> void:
		var b := rect.abs()
		if not filled:
			b = b.grow(maxf(width, 1.0) * 0.5)
		_put([OP_RECT, rect, color, filled, width, antialiased], b)

	func draw_circle(position: Vector2, radius: float, color: Color, filled := true, width := -1.0, antialiased := false) -> void:
		var r := absf(radius) + (maxf(width, 1.0) * 0.5 if not filled else 0.0)
		_put([OP_CIRCLE, position, radius, color, filled, width, antialiased], Rect2(position - Vector2(r, r), Vector2(r, r) * 2.0))

	func draw_line(from: Vector2, to: Vector2, color: Color, width := -1.0, antialiased := false) -> void:
		var b := Rect2(from, Vector2.ZERO).expand(to).grow(maxf(width, 1.0) * 0.5)
		_put([OP_LINE, from, to, color, width, antialiased], b)

	func draw_colored_polygon(points: PackedVector2Array, color: Color, uvs := PackedVector2Array(), texture: Texture2D = null) -> void:
		_put([OP_POLY, points, color, uvs, texture], _bounds(points, 0.0))

	func draw_polyline(points: PackedVector2Array, color: Color, width := -1.0, antialiased := false) -> void:
		_put([OP_POLYLINE, points, color, width, antialiased], _bounds(points, maxf(width, 1.0) * 0.5))

	func draw_arc(center: Vector2, radius: float, start_angle: float, end_angle: float, point_count: int, color: Color, width := -1.0, antialiased := false) -> void:
		var r := absf(radius) + maxf(width, 1.0) * 0.5
		_put([OP_ARC, center, radius, start_angle, end_angle, point_count, color, width, antialiased], Rect2(center - Vector2(r, r), Vector2(r, r) * 2.0))

	func draw_set_transform(position: Vector2, rotation := 0.0, scale := Vector2(1, 1)) -> void:
		_xf = Transform2D(rotation, scale, 0.0, position)

	func draw_set_transform_matrix(xform: Transform2D) -> void:
		_xf = xform

	# ── 정적/동적 확장 ──

	## 움직이는 요소: f(c: CanvasItem, t: float). bbox는 움직임 전체를 덮게 (층 좌표, 변환 전)
	func anim(bbox: Rect2, f: Callable) -> void:
		anims += 1
		var b := _world(bbox)
		var r := _cells(b)
		var m := _scan(r)
		# 겹치는 정적보다 위, 겹치는 동적과 같거나 위 (동적은 홀수 level)
		var lv := maxi(maxi(m.x / KEYS + 1 if m.x >= 0 else 0, m.y), 1)
		if lv % 2 == 0:
			lv += 1
		_mark(_ga, r, lv)
		_level_slot(lv).append([b, f, _xf])

	## 정적이지만 CanvasItem 타입 도우미를 부르는 그림: f(c: CanvasItem)
	func fn(bbox: Rect2, f: Callable) -> void:
		_put([OP_FN, f], bbox)

	## 그리기가 아닌 매 프레임 일: f(node: Node2D, t: float)
	func on_process(f: Callable) -> void:
		procs.append(f)

	## 모든 정적·동적 부분 위에 붙일 노드
	func add_post(n: Node) -> void:
		post.append(n)

	# ── 내부 ──

	## 정적 명령 하나: 겹치는 정적과 같거나 위, 겹치는 동적보다 위 level(짝수)에.
	## 같은 level 안에서는 왼쪽 끝 x로 조각을 고르되, 겹치는 앞 명령의 조각보다 앞이 되지 않게 한다 (순서 보존)
	func _put(cmd: Array, bbox: Rect2) -> void:
		commands += 1
		var b := _world(bbox)
		var r := _cells(b)
		var m := _scan(r)
		var lv := maxi(maxi(m.x / KEYS if m.x >= 0 else 0, m.y + 1), 0)
		if lv % 2 == 1:
			lv += 1
		var chunk := clampi(int(floor((b.position.x - _org.x) / CHUNK)), 0, KEYS - 1)
		var key := maxi(lv * KEYS + chunk, m.x)
		_mark(_gs, r, key)
		var chunks: Dictionary = _level_slot(lv)
		var c := key - lv * KEYS
		if not chunks.has(c):
			chunks[c] = []
		var list: Array = chunks[c]
		if _last_xf.get(key, Transform2D.IDENTITY) != _xf:
			_last_xf[key] = _xf
			list.append([OP_XF, _xf])
		list.append(cmd)

	func _level_slot(lv: int) -> Variant:
		while levels.size() <= lv:
			levels.append({} if levels.size() % 2 == 0 else [])
		return levels[lv]

	func _world(b: Rect2) -> Rect2:
		var g := b.grow(PAD)
		return _xf * g if _xf != Transform2D.IDENTITY else g

	static func _bounds(points: PackedVector2Array, pad: float) -> Rect2:
		if points.is_empty():
			return Rect2()
		var b := Rect2(points[0], Vector2.ZERO)
		for p in points:
			b = b.expand(p)
		return b.grow(pad)

	## bbox가 걸치는 칸 범위 (밖은 가장자리 칸으로 — 보수적)
	func _cells(b: Rect2) -> Array[int]:
		var x0 := clampi(int(floor((b.position.x - _org.x) / CELL)), 0, _cw - 1)
		var y0 := clampi(int(floor((b.position.y - _org.y) / CELL)), 0, _ch - 1)
		var x1 := clampi(int(floor((b.end.x - _org.x) / CELL)), 0, _cw - 1)
		var y1 := clampi(int(floor((b.end.y - _org.y) / CELL)), 0, _ch - 1)
		return [x0, y0, x1, y1]

	## 칸 범위 안의 (가장 높은 정적 key, 가장 높은 동적 level)
	func _scan(r: Array[int]) -> Vector2i:
		var ms := -1
		var ma := -1
		for y in range(r[1], r[3] + 1):
			var row := y * _cw
			for x in range(r[0], r[2] + 1):
				ms = maxi(ms, _gs[row + x])
				ma = maxi(ma, _ga[row + x])
		return Vector2i(ms, ma)

	func _mark(g: PackedInt32Array, r: Array[int], v: int) -> void:
		for y in range(r[1], r[3] + 1):
			var row := y * _cw
			for x in range(r[0], r[2] + 1):
				if g[row + x] < v:
					g[row + x] = v


# ═══════════════════════════════════════════════════════════
# 기록을 그리는 노드
# ═══════════════════════════════════════════════════════════

## 정적 부분: 기록한 명령을 한 번 그린다 (다시 그리지 않음)
class StaticPart extends Node2D:
	var cmds: Array = []

	func _draw() -> void:
		var t0 := Time.get_ticks_usec()
		for c: Array in cmds:
			match int(c[0]):
				Pen.OP_RECT: draw_rect(c[1], c[2], c[3], c[4], c[5])
				Pen.OP_CIRCLE: draw_circle(c[1], c[2], c[3], c[4], c[5], c[6])
				Pen.OP_LINE: draw_line(c[1], c[2], c[3], c[4], c[5])
				Pen.OP_POLY: draw_colored_polygon(c[1], c[2], c[3], c[4])
				Pen.OP_POLYLINE: draw_polyline(c[1], c[2], c[3], c[4])
				Pen.OP_ARC: draw_arc(c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8])
				Pen.OP_FN: (c[1] as Callable).call(self)
				Pen.OP_XF: draw_set_transform_matrix(c[1])
		Stats.add_static(Time.get_ticks_usec() - t0, cmds.size())


## 동적 부분: 틱마다 t로 다시 그린다. cull이면 화면(+여유) 밖 항목은 건너뛴다
class AnimPart extends Node2D:
	var items: Array = [] ## [bbox, Callable, Transform2D]
	var bounds := Rect2()
	var cull := true
	var t := 0.0
	var _drew := true

	func tick(time: float) -> void:
		t = time
		if cull and not _drew and not _view().intersects(bounds):
			return # 화면 밖이고 이미 비워 둠
		queue_redraw()

	func _view() -> Rect2:
		return (get_global_transform_with_canvas().affine_inverse() * get_viewport_rect()).grow(CULL_MARGIN)

	func _draw() -> void:
		var t0 := Time.get_ticks_usec()
		var vis := _view() if cull else ALL
		var n := 0
		for it: Array in items:
			if not vis.intersects(it[0]):
				continue
			var xf: Transform2D = it[2]
			if xf != Transform2D.IDENTITY:
				draw_set_transform_matrix(xf)
			(it[1] as Callable).call(self, t)
			if xf != Transform2D.IDENTITY:
				draw_set_transform_matrix(Transform2D.IDENTITY)
			n += 1
		_drew = n > 0
		Stats.add_anim(Time.get_ticks_usec() - t0, n)


## 기록을 owner의 자식 노드로 붙인다 (level 순서 = 그리는 순서). 동적 부분 목록을 돌려준다
static func mount(owner: CanvasItem, pen: Pen, cull: bool) -> Array[AnimPart]:
	var out: Array[AnimPart] = []
	for i in pen.levels.size():
		if i % 2 == 0:
			var chunks: Dictionary = pen.levels[i]
			var keys := chunks.keys()
			keys.sort()
			for c: int in keys:
				var sp := StaticPart.new()
				sp.name = "Static%d_%d" % [i, c]
				sp.cmds = chunks[c]
				owner.add_child(sp)
		else:
			var lv: Array = pen.levels[i]
			if lv.is_empty():
				continue
			var ap := AnimPart.new()
			ap.name = "Anim%d" % i
			ap.items = lv
			ap.cull = cull
			ap.bounds = lv[0][0]
			for it: Array in lv:
				ap.bounds = ap.bounds.merge(it[0])
			owner.add_child(ap)
			out.append(ap)
	for n in pen.post:
		# 예전(3장 Anim)처럼 미뤄서 붙인다 — _ready의 전역 randf() 순서가 그대로여야 다른 개체의 무늬가 같다
		owner.add_child.call_deferred(n)
	Stats.static_cmds += pen.commands
	Stats.anim_items += pen.anims
	return out


# ═══════════════════════════════════════════════════════════
# 공용 그림 도우미 (c = Pen 또는 CanvasItem — 타입을 두지 않아 정적·동적 어디서나 쓴다)
# KArt(world/entities/ch2/k_art.gd)의 같은 이름 함수와 그림이 똑같다(그쪽이 원본이었음).
# ═══════════════════════════════════════════════════════════

## 계단식 세로 그라데이션 (픽셀 느낌). 1·3장·sys 하늘(24단, 15px)도 이것과 같다
static func stepped_grad(c, rect: Rect2, top: Color, bot: Color, steps := 20, curve := 1.0) -> void:
	var h := rect.size.y / steps
	for i in steps:
		var k := float(i) / maxf(steps - 1, 1)
		c.draw_rect(Rect2(rect.position.x, rect.position.y + i * h, rect.size.x, h + 1.0), top.lerp(bot, pow(k, curve)))


## 고르게 놓인 여러 색의 계단 그라데이션 (4장 하늘). cols는 위→아래
static func grad_even(c, cols: Array, y0: float, h: float, w: float, steps := 30) -> void:
	var n := cols.size()
	for i in steps:
		var k := float(i) / float(steps - 1)
		var seg := k * float(n - 1)
		var j := mini(int(seg), n - 2)
		var a: Color = cols[j]
		var b: Color = cols[j + 1]
		c.draw_rect(Rect2(0, y0 + i * h / steps, w, h / steps + 1.0), a.lerp(b, seg - float(j)))


## 지점별 색의 계단 그라데이션 (5장 하늘). cols = [[k 0~1, Color], ...], 24단 15px
static func grad_keyed(c, cols: Array, steps := 24) -> void:
	for i in steps:
		var k := float(i) / (steps - 1)
		var col: Color = cols[0][1]
		for j in range(1, cols.size()):
			var k0: float = cols[j - 1][0]
			var k1: float = cols[j][0]
			if k >= k0 and k <= k1:
				col = (cols[j - 1][1] as Color).lerp(cols[j][1], (k - k0) / maxf(k1 - k0, 0.001))
				break
			if k > k1:
				col = cols[j][1]
		c.draw_rect(Rect2(0, i * 15, 640, 16), col)


## 은은한 빛: 바깥에서 안으로 겹치는 원
static func glow(c, pos: Vector2, r: float, col: Color, rings := 4) -> void:
	for i in rings:
		var k := 1.0 - float(i) / rings
		c.draw_circle(pos, r * k, Color(col, col.a * 0.10 * (1.0 + i * 0.6)))


## 네 갈래 반짝임 (별)
static func star4(c, pos: Vector2, s: float, col: Color) -> void:
	c.draw_colored_polygon(PackedVector2Array([
		pos + Vector2(0, -s), pos + Vector2(s * 0.22, -s * 0.22), pos + Vector2(s, 0), pos + Vector2(s * 0.22, s * 0.22),
		pos + Vector2(0, s), pos + Vector2(-s * 0.22, s * 0.22), pos + Vector2(-s, 0), pos + Vector2(-s * 0.22, -s * 0.22),
	]), col)


## 별가루 반짝임 (영역 안, 시간에 따라 깜빡임) — 움직이므로 Pen에는 anim_twinkles로
static func twinkles(c, rect: Rect2, n: int, t: float, col: Color, seed := 1) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for i in n:
		var p := rect.position + Vector2(rng.randf() * rect.size.x, rng.randf() * rect.size.y)
		var tw := 0.5 + 0.5 * sin(t * rng.randf_range(1.5, 4.0) + i * 1.7)
		if tw > 0.7:
			star4(c, p, 1.0 + 1.5 * (tw - 0.7) / 0.3, Color(col, col.a * tw))
		else:
			c.draw_rect(Rect2(p, Vector2.ONE), Color(col, col.a * tw))


## twinkles를 Pen에 동적 요소로 (별 위치·속도는 미리 뽑아 둠)
static func anim_twinkles(p: Pen, rect: Rect2, n: int, col: Color, seed := 1) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var pos := PackedVector2Array()
	var spd := PackedFloat64Array()
	for i in n:
		pos.append(rect.position + Vector2(rng.randf() * rect.size.x, rng.randf() * rect.size.y))
		spd.append(rng.randf_range(1.5, 4.0))
	p.anim(rect.grow(3.0), func(cv: CanvasItem, t: float) -> void:
		for i in n:
			var tw := 0.5 + 0.5 * sin(t * spd[i] + i * 1.7)
			if tw > 0.7:
				star4(cv, pos[i], 1.0 + 1.5 * (tw - 0.7) / 0.3, Color(col, col.a * tw))
			else:
				cv.draw_rect(Rect2(pos[i], Vector2.ONE), Color(col, col.a * tw)))


# ── 움직이는 KArt 그림의 bbox (움직임 전체를 덮게 넉넉히) ──

static func bb_circle(pos: Vector2, r: float) -> Rect2:
	return Rect2(pos - Vector2(r, r), Vector2(r, r) * 2.0)


## KArt.pennant(top, length, height)
static func bb_pennant(top: Vector2, length: float, height: float) -> Rect2:
	return Rect2(top.x - 2.0, top.y - height, length + 4.0, height * 4.5 + 2.0)


## KArt.hanging_banner(top_center, w, h)
static func bb_banner(top_center: Vector2, w: float, h: float) -> Rect2:
	return Rect2(top_center.x - w * 0.6 - 3.0, top_center.y - 3.0, w * 1.2 + 6.0, h + 6.0)


## KArt.smoke(base, scale)
static func bb_smoke(base: Vector2, scale: float) -> Rect2:
	return Rect2(base + Vector2(-16.0, -84.0) * scale, Vector2(60.0, 98.0) * scale)


## KArt.crystal(base, h)
static func bb_crystal(base: Vector2, h: float) -> Rect2:
	return Rect2(base.x - h, base.y - h * 1.45, h * 2.0, h * 1.5)


# ═══════════════════════════════════════════════════════════
# 계측 (시험 실행기 bgperf 명령이 읽음 — 비용 거의 없음)
# ═══════════════════════════════════════════════════════════

class Stats extends RefCounted:
	static var static_us := 0 ## 정적 부분 그리기 누적 시간
	static var static_n := 0 ## 정적 명령 그린 수 누적
	static var anim_us := 0 ## 동적 부분 그리기 누적 시간
	static var anim_n := 0 ## 동적 항목 그린 수 누적
	static var anim_draws := 0 ## 동적 부분 _draw 횟수 누적
	static var static_cmds := 0 ## 기록된 정적 명령 수 (방 진입 때)
	static var anim_items := 0 ## 기록된 동적 항목 수

	static func add_static(us: int, n: int) -> void:
		static_us += us
		static_n += n

	static func add_anim(us: int, n: int) -> void:
		anim_us += us
		anim_n += n
		anim_draws += 1

	static func reset() -> void:
		static_us = 0
		static_n = 0
		anim_us = 0
		anim_n = 0
		anim_draws = 0
