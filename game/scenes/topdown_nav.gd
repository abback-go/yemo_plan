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
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER   # 4방향 이동만(대각선 없음)
	grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
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
		_add_axis(pts, center(id))
	if can_stand(to):
		_add_axis(pts, to)
	# 가로·세로 구간만 남기고, 같은 방향으로 이어지는 점은 합친다 (4방향 이동)
	for i in range(1, pts.size()):
		var q: Vector2 = pts[i]
		if out.size() >= 1:
			var pa: Vector2 = pts[i - 2] if i >= 2 else from
			var pb: Vector2 = pts[i - 1]
			if (is_equal_approx(pa.x, pb.x) and is_equal_approx(pb.x, q.x)) or (is_equal_approx(pa.y, pb.y) and is_equal_approx(pb.y, q.y)):
				out[out.size() - 1] = q
				continue
		out.append(q)
	return out


## 마지막 점에서 q 로 가로·세로로만 가도록, 둘 다 다르면 꺾이는 점을 끼운다(설 수 있는 쪽)
func _add_axis(pts: Array, q: Vector2) -> void:
	var a: Vector2 = pts[pts.size() - 1]
	if a.distance_squared_to(q) < 0.0001:
		return
	if not is_equal_approx(a.x, q.x) and not is_equal_approx(a.y, q.y):
		var c1 := Vector2(q.x, a.y)
		var c2 := Vector2(a.x, q.y)
		pts.append(c1 if line_ok(a, c1) and line_ok(c1, q) else c2)
	pts.append(q)


## p 에서 d 만큼 움직인다. 막히면 가로·세로 한쪽으로만 미끄러진다. 반환: 새 발끝
func move(p: Vector2, d: Vector2) -> Vector2:
	var n := p + d
	if can_stand(n):
		return n
	if d.x != 0.0 and can_stand(p + Vector2(d.x, 0)):
		return p + Vector2(d.x, 0)
	if d.y != 0.0 and can_stand(p + Vector2(0, d.y)):
		return p + Vector2(0, d.y)
	return p


## 움직임 d 에 맞는 4방향 행 (가장 가까운 쪽). 지금 보는 쪽이 이동 방향의 한쪽이면 조금 더 기울어질 때까지 그대로
## (대각선·조이스틱 45도 근처에서 그림이 깜빡이지 않게)
static func face_dir(cur: String, d: Vector2) -> String:
	if d == Vector2.ZERO:
		return cur
	var ax := absf(d.x)
	var ay := absf(d.y)
	var keep := (cur == "left" and d.x < 0) or (cur == "right" and d.x > 0) or (cur == "up" and d.y < 0) or (cur == "down" and d.y > 0)
	if keep:
		if (cur == "left" or cur == "right") and ay <= ax * 1.25:
			return cur
		if (cur == "up" or cur == "down") and ax <= ay * 1.25:
			return cur
	if ax >= ay:
		return "left" if d.x < 0 else "right"
	return "up" if d.y < 0 else "down"


## 움직임 d 를 가로 또는 세로 한쪽으로만 (대각선 이동 없음). 길이(빠르기)는 그대로
static func snap4(cur: String, d: Vector2) -> Vector2:
	if d == Vector2.ZERO:
		return d
	var f := face_dir(cur, d)
	var l := d.length()
	match f:
		"left": return Vector2(-l, 0)
		"right": return Vector2(l, 0)
		"up": return Vector2(0, -l)
	return Vector2(0, l)


## v: 받침 반지름을 1로 한 손가락 위치. 조금 기울이면 min 빠르기, 끝까지 기울이면 1
static func stick_to_vec(v: Vector2, dead: float, mn: float) -> Vector2:
	var l := v.length()
	if l <= dead:
		return Vector2.ZERO
	var t := clampf((l - dead) / maxf(0.001, 1.0 - dead), 0.0, 1.0)
	return v / l * lerpf(mn, 1.0, t)


## 노엘이 지나간 경로(발끝 기록). 동료는 이 경로를 따라 잰 거리만큼 뒤에 선다 → 노엘이 멈추면 간격을 둔 채 함께 멈추고 겹쳐 쌓이지 않는다.
## 점은 오래된 것 → 최근 것 순서. 충돌 검사는 하지 않는다(노엘이 이미 걸은 곳이므로).
class Trail:
	extends RefCounted
	var pts := PackedVector2Array()
	var keep := 120.0   # 이만큼(경로 길이)만 남기고 오래된 점은 버린다

	## 지금 발끝 head 를 기록한다 (마지막 점에서 1px 이상 움직였을 때만)
	func push(head: Vector2) -> void:
		if pts.is_empty() or pts[pts.size() - 1].distance_to(head) >= 1.0:
			pts.append(head)
		var total := 0.0
		for i in range(pts.size() - 1, 0, -1):
			total += pts[i].distance_to(pts[i - 1])
			if total > keep:
				pts = pts.slice(i - 1)
				return

	## head 뒤로 back 방향 일직선 줄로 다시 놓는다 (시작·되돌아올 때)
	func line_up(head: Vector2, back: Vector2) -> void:
		pts = PackedVector2Array([head + back.normalized() * keep, head])

	## head 에서 경로를 따라 dist 만큼 뒤의 점
	func at(head: Vector2, dist: float) -> Vector2:
		var prev := head
		for i in range(pts.size() - 1, -1, -1):
			var seg := prev.distance_to(pts[i])
			if seg < 0.0001:
				continue
			if dist <= seg:
				return prev.lerp(pts[i], dist / seg)
			dist -= seg
			prev = pts[i]
		return prev
