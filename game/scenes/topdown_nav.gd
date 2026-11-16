## topdown_nav.gd — 탑뷰 시험판의 충돌·경로찾기. 걸을 수 있는 바닥 다각형(walk)에서 막힌 곳(blocks)을 뺀 영역에
## 발 자리(가로·세로 반지름 footR)가 다 들어가야 설 수 있다. 탭 이동은 격자(AStarGrid2D) 경로를 구한 뒤 직선으로 펴서 걷는다.
## 좌표는 맵 그림의 실제 픽셀. 수치는 game_data.gd "topdown".
class_name TopdownNav
extends RefCounted

var walk := PackedVector2Array()
var blocks: Array = []   # [{"poly": PackedVector2Array, "rect": Rect2}]
var cell := 6
var rx := 7.0
var ry := 3.0
var grid := AStarGrid2D.new()


static func poly(a: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in a:
		out.append(Vector2(float(p[0]), float(p[1])))
	return out


func _init(conf: Dictionary, map_size: Vector2i) -> void:
	walk = poly(conf.walk)
	for b in conf.blocks:
		var pp := poly(b)
		var r := Rect2(pp[0], Vector2.ZERO)
		for q in pp:
			r = r.expand(q)
		blocks.append({"poly": pp, "rect": r.grow(1.0)})
	cell = int(conf.get("navCell", 6))
	var fr: Array = conf.get("footR", [7, 3])
	rx = float(fr[0])
	ry = float(fr[1])
	grid.region = Rect2i(0, 0, ceili(map_size.x / float(cell)), ceili(map_size.y / float(cell)))
	grid.cell_size = Vector2(cell, cell)
	grid.offset = Vector2(cell / 2.0, cell / 2.0)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	grid.update()
	for y in grid.region.size.y:
		for x in grid.region.size.x:
			var c := Vector2i(x, y)
			if not can_stand(center(c)):
				grid.set_point_solid(c, true)


func _free(p: Vector2) -> bool:
	if not Geometry2D.is_point_in_polygon(p, walk):
		return false
	for b in blocks:
		if b.rect.has_point(p) and Geometry2D.is_point_in_polygon(p, b.poly):
			return false
	return true


## 발끝 p 에 설 수 있는가 (발 자리 다섯 점이 모두 바닥 안, 막힌 곳 밖)
func can_stand(p: Vector2) -> bool:
	return _free(p) and _free(p + Vector2(-rx, 0)) and _free(p + Vector2(rx, 0)) and _free(p + Vector2(0, -ry)) and _free(p + Vector2(0, ry))


func center(c: Vector2i) -> Vector2:
	return Vector2(c) * cell + Vector2(cell / 2.0, cell / 2.0)


func _cell_of(p: Vector2) -> Vector2i:
	var r := grid.region
	return Vector2i(clampi(int(floor(p.x / cell)), 0, r.size.x - 1), clampi(int(floor(p.y / cell)), 0, r.size.y - 1))


## p 에서 가장 가까운 설 수 있는 칸 (없으면 Vector2i(-1, -1))
func nearest_open(p: Vector2) -> Vector2i:
	var c0 := _cell_of(p)
	var r := grid.region
	for ring in range(0, maxi(r.size.x, r.size.y)):
		var best := Vector2i(-1, -1)
		var bd := INF
		for dy in range(-ring, ring + 1):
			for dx in range(-ring, ring + 1):
				if maxi(absi(dx), absi(dy)) != ring:
					continue
				var c := c0 + Vector2i(dx, dy)
				if not r.has_point(c) or grid.is_point_solid(c):
					continue
				var d := center(c).distance_squared_to(p)
				if d < bd:
					bd = d
					best = c
		if best.x >= 0:
			return best
	return Vector2i(-1, -1)


## a → b 직선 위를 걸어도 되는가
func line_ok(a: Vector2, b: Vector2) -> bool:
	var n := ceili(a.distance_to(b) / 2.0)
	for i in range(1, n + 1):
		if not can_stand(a.lerp(b, float(i) / n)):
			return false
	return true


## from(지금 발끝) → to 로 가는 꺾은 점들 (from 은 빼고). to 에 설 수 없으면 가장 가까운 설 수 있는 곳까지
func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	var a := nearest_open(from)
	var b := nearest_open(to)
	if a.x < 0 or b.x < 0:
		return out
	var ids := grid.get_id_path(a, b)
	if ids.is_empty():
		return out
	var pts: Array = [from]
	for id in ids:
		pts.append(center(id))
	if can_stand(to):
		pts.append(to)
	# 직선으로 갈 수 있는 데까지 건너뛴다 (격자 모양으로 꺾이지 않게)
	var cur: Vector2 = from
	var i := 1
	while i < pts.size():
		var j := i
		while j + 1 < pts.size() and line_ok(cur, pts[j + 1]):
			j += 1
		out.append(pts[j])
		cur = pts[j]
		i = j + 1
	return out


## p 에서 d 만큼 움직인다. 막히면 가로·세로 한쪽으로만 미끄러진다. 반환: 새 발끝
func move(p: Vector2, d: Vector2) -> Vector2:
	var n := p + d
	if can_stand(n):
		return n
	if d.x != 0.0 and can_stand(p + Vector2(d.x, 0)):
		return p + Vector2(d.x, 0)
	if d.y != 0.0 and can_stand(p + Vector2(0, d.y)):
		return p + Vector2(0, d.y)
	# 비스듬한 벽: 45도 돌린 쪽으로 미끄러진다
	for a in [PI / 4.0, -PI / 4.0]:
		var r := d.rotated(a) * 0.7
		if can_stand(p + r):
			return p + r
	return p
