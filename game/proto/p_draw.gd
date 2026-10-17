class_name PDraw
extends RefCounted
## 묶음 그리기: 한 노드의 그림(다각형·원·선·호·사각형)을 삼각형 묶음 하나로 모아 그리기 호출 1번으로 보낸다.
## 엔진은 draw_colored_polygon·draw_circle·두꺼운 선을 하나마다 그리기 호출 1번으로 보내서, 세라 그림 하나에 ~100번,
## 큰 마법이 겹치면 프레임마다 수백 번이 된다(웹에서 렉의 주원인). CanvasItem과 같은 이름의 함수를 그대로 갖춰
## 그림 코드에서 draw_xxx( 를 g.draw_xxx( 로만 바꾸면 된다. _draw 끝에 g.flush(self) 한 번.
## 글자(draw_string)는 지원하지 않는다 — 노드에 직접 그린다(flush 뒤에 그리면 위에 보임).
## 꼬인 다각형(삼각분할 실패)은 조용히 건너뛴다 (예전 PVfx.safe_poly와 같음).

var v := PackedVector2Array()
var c := PackedColorArray()
var idx := PackedInt32Array()
var xf := Transform2D.IDENTITY
var _id := true
var _sc := PackedColorArray() ## 색 채우기용 임시

static var _unit := {} ## 꼭짓점 수 → 단위 원 점들
static var _fan := {} ## 꼭짓점 수 → 부채꼴 삼각형 번호
static var _grown := {} ## 다각형 해시 → 윤곽용으로 넓힌 다각형 (모양이 같으면 다시 계산하지 않음)


func clear() -> void:
	v.clear()
	c.clear()
	idx.clear()
	xf = Transform2D.IDENTITY
	_id = true


func is_empty() -> bool:
	return idx.is_empty()


## 모은 그림을 ci에 한 번에 보낸다 (ci의 _draw 안에서)
func flush(ci: CanvasItem) -> void:
	if not idx.is_empty():
		RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), idx, v, c)
	clear()


func draw_set_transform(pos: Vector2, rot := 0.0, sc := Vector2.ONE) -> void:
	xf = Transform2D(rot, sc, 0.0, pos)
	_id = pos == Vector2.ZERO and rot == 0.0 and sc == Vector2.ONE


func draw_set_transform_matrix(m: Transform2D) -> void:
	xf = m
	_id = m == Transform2D.IDENTITY


func _colors(col: Color, n: int) -> void:
	_sc.resize(n)
	_sc.fill(col)
	c.append_array(_sc)


## 다각형 (꼬여서 삼각분할이 안 되면 false)
func draw_colored_polygon(pts: PackedVector2Array, col: Color, _uvs := PackedVector2Array(), _tex: Texture2D = null) -> bool:
	if pts.size() < 3:
		return false
	var tri := Geometry2D.triangulate_polygon(pts)
	if tri.is_empty():
		return false
	if col.a <= 0.003:
		return true
	var base := v.size()
	v.append_array(pts if _id else xf * pts)
	_colors(col, pts.size())
	for k in tri:
		idx.append(base + k)
	return true


## 띠: 왼쪽 점들과 오른쪽 점들(같은 수, 같은 방향) 사이를 사각형으로 이어 채운다 — 꼬리·리본처럼 길쭉한 모양을 삼각분할 없이
func strip(left: PackedVector2Array, right: PackedVector2Array, col: Color) -> void:
	var n := mini(left.size(), right.size())
	if n < 2 or col.a <= 0.003:
		return
	var base := v.size()
	var pts := PackedVector2Array()
	pts.resize(n * 2)
	for i in n:
		pts[i * 2] = left[i]
		pts[i * 2 + 1] = right[i]
	v.append_array(pts if _id else xf * pts)
	_colors(col, n * 2)
	for i in n - 1:
		var q := base + i * 2
		idx.append(q)
		idx.append(q + 2)
		idx.append(q + 1)
		idx.append(q + 1)
		idx.append(q + 2)
		idx.append(q + 3)


## 띠 + 길이 방향 그라데이션 (처음 색 → 끝 색)
func strip_grad(left: PackedVector2Array, right: PackedVector2Array, c_from: Color, c_to: Color) -> void:
	var n := mini(left.size(), right.size())
	if n < 2:
		return
	var base := v.size()
	var pts := PackedVector2Array()
	pts.resize(n * 2)
	for i in n:
		pts[i * 2] = left[i]
		pts[i * 2 + 1] = right[i]
		var cc := c_from.lerp(c_to, float(i) / float(n - 1))
		c.append(cc)
		c.append(cc)
	v.append_array(pts if _id else xf * pts)
	for i in n - 1:
		var q := base + i * 2
		idx.append(q)
		idx.append(q + 2)
		idx.append(q + 1)
		idx.append(q + 1)
		idx.append(q + 2)
		idx.append(q + 3)


## 윤곽선 있는 다각형: 바깥으로 w만큼 넓힌 같은 모양을 out 색으로 먼저 깔고 채운다.
## 넓힌 모양은 다각형 해시로 기억해 두어, 매 프레임 같은 모양(허수아비·얼굴)은 다시 계산하지 않는다
func outlined(pts: PackedVector2Array, col: Color, out: Color, w := 0.6) -> bool:
	if pts.size() < 3:
		return false
	var key := hash(pts) ^ int(w * 1000.0)
	var g: Variant = _grown.get(key)
	if g == null:
		var res := Geometry2D.offset_polygon(pts, w, Geometry2D.JOIN_MITER)
		g = res[0] if res.size() == 1 else PackedVector2Array()
		if _grown.size() > 2048:
			_grown.clear()
		_grown[key] = g
	if (g as PackedVector2Array).size() >= 3:
		draw_colored_polygon(g, out)
	return draw_colored_polygon(pts, col)


## 볼록 다각형 (삼각분할 없이 부채꼴로 — 원·타원·사각처럼 확실히 볼록한 것만)
func convex(pts: PackedVector2Array, col: Color) -> void:
	var n := pts.size()
	if n < 3 or col.a <= 0.003:
		return
	var base := v.size()
	v.append_array(pts if _id else xf * pts)
	_colors(col, n)
	for k in _fan_of(n):
		idx.append(base + k)


## 꼭짓점마다 색이 다른 볼록 다각형 (그라데이션)
func convex_colors(pts: PackedVector2Array, cols: PackedColorArray) -> void:
	var n := pts.size()
	if n < 3:
		return
	var base := v.size()
	v.append_array(pts if _id else xf * pts)
	c.append_array(cols)
	for k in _fan_of(n):
		idx.append(base + k)


static func _fan_of(n: int) -> PackedInt32Array:
	var f: PackedInt32Array = _fan.get(n, PackedInt32Array())
	if f.is_empty():
		for i in range(1, n - 1):
			f.append(0)
			f.append(i)
			f.append(i + 1)
		_fan[n] = f
	return f


static func unit_circle(n: int) -> PackedVector2Array:
	var u: PackedVector2Array = _unit.get(n, PackedVector2Array())
	if u.is_empty():
		for i in n:
			var a := float(i) / float(n) * TAU
			u.append(Vector2(cos(a), sin(a)))
		_unit[n] = u
	return u


static func segs(r: float) -> int:
	return clampi(int(r * 0.9) + 6, 6, 40)


func draw_circle(center: Vector2, radius: float, col: Color, filled := true, width := -1.0, _aa := false) -> void:
	if radius <= 0.05 or col.a <= 0.003:
		return
	if not filled:
		draw_arc(center, radius, 0.0, TAU, segs(radius) + 1, col, width)
		return
	var n := segs(radius)
	var m := Transform2D(0.0, Vector2(radius, radius), 0.0, center)
	if not _id:
		m = xf * m
	var base := v.size()
	v.append_array(m * unit_circle(n))
	_colors(col, n)
	for k in _fan_of(n):
		idx.append(base + k)


## 가운데가 진하고 가장자리로 갈수록 투명해지는 원 (빛무리) — 그리기 한 번에 부드러운 빛
func glow(center: Vector2, radius: float, col: Color, edge_a := 0.0) -> void:
	if radius <= 0.05 or col.a <= 0.003:
		return
	var n := segs(radius)
	var m := Transform2D(0.0, Vector2(radius, radius), 0.0, center)
	if not _id:
		m = xf * m
	var base := v.size()
	v.append(xf * center if not _id else center)
	v.append_array(m * unit_circle(n))
	c.append(col)
	_colors(Color(col, col.a * edge_a), n)
	for i in n:
		idx.append(base)
		idx.append(base + 1 + i)
		idx.append(base + 1 + (i + 1) % n)


func _quad(a: Vector2, b: Vector2, cc: Vector2, d: Vector2, col: Color) -> void:
	var base := v.size()
	if _id:
		v.append(a)
		v.append(b)
		v.append(cc)
		v.append(d)
	else:
		v.append(xf * a)
		v.append(xf * b)
		v.append(xf * cc)
		v.append(xf * d)
	_colors(col, 4)
	idx.append(base)
	idx.append(base + 1)
	idx.append(base + 2)
	idx.append(base)
	idx.append(base + 2)
	idx.append(base + 3)


func draw_line(from: Vector2, to: Vector2, col: Color, width := -1.0, _aa := false) -> void:
	if col.a <= 0.003:
		return
	var d := to - from
	if d.length_squared() < 0.0001:
		return
	var n := d.normalized().orthogonal() * (maxf(width, 1.0) * 0.5)
	_quad(from + n, to + n, to - n, from - n, col)


## 두 끝 색이 다른 선 (꼬리처럼 사라지는 줄기)
func line2(from: Vector2, to: Vector2, c0: Color, c1: Color, w0: float, w1 := -1.0) -> void:
	var d := to - from
	if d.length_squared() < 0.0001:
		return
	var o := d.normalized().orthogonal()
	var n0 := o * (w0 * 0.5)
	var n1 := o * ((w0 if w1 < 0.0 else w1) * 0.5)
	var base := v.size()
	var pts := PackedVector2Array([from + n0, to + n1, to - n1, from - n0])
	v.append_array(pts if _id else xf * pts)
	c.append(c0)
	c.append(c1)
	c.append(c1)
	c.append(c0)
	idx.append(base)
	idx.append(base + 1)
	idx.append(base + 2)
	idx.append(base)
	idx.append(base + 2)
	idx.append(base + 3)


func draw_polyline(pts: PackedVector2Array, col: Color, width := -1.0, _aa := false) -> void:
	for i in range(1, pts.size()):
		draw_line(pts[i - 1], pts[i], col, width)


func draw_rect(rect: Rect2, col: Color, filled := true, width := -1.0, _aa := false) -> void:
	if col.a <= 0.003:
		return
	var p := rect.position
	var e := rect.end
	if filled:
		_quad(p, Vector2(e.x, p.y), e, Vector2(p.x, e.y), col)
		return
	var w := maxf(width, 1.0)
	_quad(p, Vector2(e.x, p.y), Vector2(e.x, p.y + w), Vector2(p.x, p.y + w), col)
	_quad(Vector2(p.x, e.y - w), Vector2(e.x, e.y - w), e, Vector2(p.x, e.y), col)
	_quad(Vector2(p.x, p.y + w), Vector2(p.x + w, p.y + w), Vector2(p.x + w, e.y - w), Vector2(p.x, e.y - w), col)
	_quad(Vector2(e.x - w, p.y + w), Vector2(e.x, p.y + w), Vector2(e.x, e.y - w), Vector2(e.x - w, e.y - w), col)


## 호 (선 굵기 width의 띠)
func draw_arc(center: Vector2, radius: float, a0: float, a1: float, point_count: int, col: Color, width := -1.0, _aa := false) -> void:
	if col.a <= 0.003 or point_count < 2 or radius <= 0.0:
		return
	var hw := maxf(width, 1.0) * 0.5
	var r0 := maxf(radius - hw, 0.0)
	var r1 := radius + hw
	var base := v.size()
	var pts := PackedVector2Array()
	pts.resize(point_count * 2)
	for i in point_count:
		var a := lerpf(a0, a1, float(i) / float(point_count - 1))
		var d := Vector2(cos(a), sin(a))
		pts[i * 2] = center + d * r1
		pts[i * 2 + 1] = center + d * r0
	v.append_array(pts if _id else xf * pts)
	_colors(col, point_count * 2)
	for i in point_count - 1:
		var q := base + i * 2
		idx.append(q)
		idx.append(q + 2)
		idx.append(q + 1)
		idx.append(q + 1)
		idx.append(q + 2)
		idx.append(q + 3)


## 세로 그라데이션 사각형 (위 색 → 아래 색)
func rect_grad(rect: Rect2, top: Color, bot: Color) -> void:
	var p := rect.position
	var e := rect.end
	var base := v.size()
	var pts := PackedVector2Array([p, Vector2(e.x, p.y), e, Vector2(p.x, e.y)])
	v.append_array(pts if _id else xf * pts)
	c.append(top)
	c.append(top)
	c.append(bot)
	c.append(bot)
	idx.append_array(PackedInt32Array([base, base + 1, base + 2, base, base + 2, base + 3]))


## 가로 그라데이션 사각형 (왼쪽 색 → 오른쪽 색)
func rect_hgrad(rect: Rect2, left: Color, right: Color) -> void:
	var p := rect.position
	var e := rect.end
	var base := v.size()
	var pts := PackedVector2Array([p, Vector2(e.x, p.y), e, Vector2(p.x, e.y)])
	v.append_array(pts if _id else xf * pts)
	c.append(left)
	c.append(right)
	c.append(right)
	c.append(left)
	idx.append_array(PackedInt32Array([base, base + 1, base + 2, base, base + 2, base + 3]))


## 두 타원 사이 띠 (안쪽 색 → 바깥 색): 화면 가장자리 어둡게(비네트)·빛 고리
func ring_grad(center: Vector2, r_in: Vector2, r_out: Vector2, c_in: Color, c_out: Color, n := 32) -> void:
	var u := unit_circle(n)
	var base := v.size()
	var pts := PackedVector2Array()
	pts.resize(n * 2)
	for i in n:
		pts[i * 2] = center + u[i] * r_in
		pts[i * 2 + 1] = center + u[i] * r_out
	v.append_array(pts if _id else xf * pts)
	for i in n:
		c.append(c_in)
		c.append(c_out)
	for i in n:
		var q := base + i * 2
		var nq := base + ((i + 1) % n) * 2
		idx.append_array(PackedInt32Array([q, nq, q + 1, q + 1, nq, nq + 1]))


## 묶음 그리기 노드: _paint()에서 pd.draw_xxx로 그리면 _draw가 끝에 한 번에 보낸다
class Canvas extends Node2D:
	var pd := PDraw.new()

	func _draw() -> void:
		_paint()
		pd.flush(self)

	func _paint() -> void:
		pass
