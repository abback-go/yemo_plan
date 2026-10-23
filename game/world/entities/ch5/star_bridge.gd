extends Node2D
## 별자리 다리 (docs/archive/sera/chapter5.md 5절 · 8.3절): 별을 순서대로 밝히면(on_if) 별자리 선이 한쪽 통과 발판이 된다.
## 방 데이터: {t = "st_bridge", id, pts = [[x, y], ...], on_if = "플래그"}
##   pts: 타일 좌표. 선이 지나는 점(= 발판 윗면, 개체의 y와 같은 기준). 이웃한 두 점마다 발판 하나.
## 꺼져 있을 땐 희미한 점선만 보이고 밟을 수 없다. 켜지는 순간 별빛이 점에서 점으로 달려가며 이어진다.
## 도달 검사기(roomgen check)는 이 다리를 모르므로, 방에는 같은 on_if의 별빛 상승 기류(updraft style=star)를 함께 둔다.

const T := 16.0
const RUN_TIME := 0.9 ## 처음부터 끝까지 이어지는 시간

var pts: Array[Vector2] = []
var on_if := ""
var _on := false
var _k := 0.0 ## 0~1: 이어진 정도
var _t := 0.0
var _body: StaticBody2D
var _shapes: Array[CollisionShape2D] = []
var _lens: Array[float] = []
var _total := 0.0


func setup(_room: Room, e: Dictionary, _eid: String) -> void:
	for p in e.get("pts", []):
		var a: Array = p
		pts.append(Vector2(float(a[0]) * T, float(a[1]) * T))
	on_if = String(e.get("on_if", ""))
	z_index = -1
	_body = StaticBody2D.new()
	_body.collision_layer = GameConst.L_PLATFORM
	_body.collision_mask = 0
	add_child(_body)
	for i in range(pts.size() - 1):
		var a := pts[i]
		var b := pts[i + 1]
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(a.distance_to(b) + 4.0, 4.0)
		cs.shape = rs
		cs.position = (a + b) * 0.5 + Vector2(0, 2)
		cs.rotation = (b - a).angle()
		cs.one_way_collision = true
		cs.disabled = true
		_body.add_child(cs)
		_shapes.append(cs)
		_lens.append(a.distance_to(b))
		_total += a.distance_to(b)
	if RoomData.cond_ok(on_if):
		_on = true
		_k = 1.0
		_apply()


func is_on() -> bool:
	return _on


func _physics_process(delta: float) -> void:
	_t += delta
	var want := RoomData.cond_ok(on_if)
	if want and not _on:
		_on = true
		StArt.sfx(&"star_twinkle", &"reveal", 2.0)
		for p in pts:
			Fx.ring(p, 2.0, 18.0, StArt.STAR, 0.5, 1.5)
	elif not want and _on:
		_on = false
		_k = 0.0
	if _on and _k < 1.0:
		_k = minf(_k + delta / RUN_TIME, 1.0)
	_apply()
	queue_redraw()


## 이어진 만큼만 발판을 켠다
func _apply() -> void:
	var done := _k * _total
	var acc := 0.0
	for i in _shapes.size():
		acc += _lens[i]
		_shapes[i].disabled = not _on or acc > done + 2.0


func _draw() -> void:
	if pts.size() < 2:
		return
	var done := _k * _total
	var acc := 0.0
	for i in range(pts.size() - 1):
		var a := pts[i]
		var b := pts[i + 1]
		var seg := _lens[i]
		# 꺼진 선: 희미한 점선
		var n := int(seg / 7.0)
		for j in n:
			var q := a.lerp(b, (j + 0.5) / n)
			draw_rect(Rect2(q - Vector2(1, 1), Vector2(2, 2)), Color(StArt.STAR, 0.3 + 0.15 * sin(_t * 2.0 + j * 0.7)))
		# 켜진 선
		var lit := clampf((done - acc) / maxf(seg, 1.0), 0.0, 1.0)
		if lit > 0.0:
			var e := a.lerp(b, lit)
			draw_line(a, e, Color(StArt.STAR_GOLD, 0.35), 5.0)
			draw_line(a, e, Color(StArt.STAR, 0.85), 2.0)
			draw_line(a + Vector2(0, -1), e + Vector2(0, -1), Color(1, 1, 1, 0.7), 1.0)
			# 선 위를 흐르는 반짝임
			var f := fmod(_t * 0.6 + i * 0.37, 1.0)
			if f < lit:
				StArt.sparkle(self, a.lerp(b, f) + Vector2(0, -2), 3.0, Color(1, 1, 1), 0.8)
		acc += seg
	# 별 (점)
	for i in pts.size():
		var reached := _on and (i == 0 or done >= _cum(i) - 1.0)
		var k := 0.6 + 0.4 * StArt.twinkle(_t, i * 1.7)
		if reached:
			StArt.glow(self, pts[i], 12.0, StArt.STAR, 0.3 * k)
			StArt.star(self, pts[i], 4.0, Color(StArt.STAR, k), -PI * 0.5)
		else:
			StArt.star(self, pts[i], 3.5, Color(StArt.STAR, 0.45 * k), -PI * 0.5)


func _cum(i: int) -> float:
	var s := 0.0
	for j in i:
		s += _lens[j]
	return s
