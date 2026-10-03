extends RefCounted
## 바깥 신들의 목소리 초상화 (docs/bible/art.md 4절 — 흰색·무채색·기하학): 금 간 하늘에 열린 세로 눈, 겹친 고리, 지직거리는 흰 선.
## 4장 내전(폭주의 순간)에서 "겹친 메아리"가 말할 때 쓴다 (CHARACTERS["tp_voice"]).

static func draw_portrait(p: Portrait, _info: Dictionary, _expr: String, t: float, talking: bool, _blinking: bool) -> void:
	var c := Vector2(36, 36)
	# 금 간 하늘 (검정 → 아주 옅은 회색)
	for i in 6:
		p.draw_rect(Rect2(0, i * 12, 72, 12), Color(0.06 + i * 0.012, 0.06 + i * 0.012, 0.08 + i * 0.012))
	var jit := (sin(t * 37.0) * 1.2) if talking else 0.0
	# 겹친 고리 (서로 어긋나게 돈다 — 메아리)
	for k in 3:
		var r := 14.0 + k * 7.0
		var a0 := t * (0.6 + k * 0.35) * (1.0 if k % 2 == 0 else -1.0)
		var pts := PackedVector2Array()
		for j in 7:
			var a := a0 + TAU * j / 6.0
			pts.append(c + Vector2(cos(a), sin(a)) * r + Vector2(jit * (k - 1), 0))
		p.draw_polyline(pts, Color(0.95, 0.95, 1.0, 0.25 + 0.15 * (2 - k)), 1.0)
	# 세로로 갈라진 눈
	var open := 0.75 + 0.25 * sin(t * 1.3)
	var eye := PackedVector2Array([c + Vector2(0, -15), c + Vector2(7 * open, 0), c + Vector2(0, 15), c + Vector2(-7 * open, 0)])
	p.draw_colored_polygon(eye, Color(0.97, 0.97, 1.0))
	p.draw_rect(Rect2(c.x - 1, c.y - 11, 2, 22), Color(0.12, 0.12, 0.16))
	p.draw_circle(c, 2.5, Color(1, 1, 1))
	# 하늘의 금 (흰 선)
	p.draw_polyline(PackedVector2Array([Vector2(4, 6), Vector2(14, 18), Vector2(11, 27), Vector2(22, 34)]), Color(1, 1, 1, 0.5), 1.0)
	p.draw_polyline(PackedVector2Array([Vector2(68, 64), Vector2(57, 52), Vector2(61, 44), Vector2(50, 38)]), Color(1, 1, 1, 0.5), 1.0)
	# 지직거림 (말할 때 가로 띠가 밀림)
	if talking:
		for i in 3:
			var y := fmod(t * 90.0 + i * 23.0, 72.0)
			p.draw_rect(Rect2(0, y, 72, 1), Color(1, 1, 1, 0.18))
