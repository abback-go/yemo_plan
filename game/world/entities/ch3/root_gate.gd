class_name RootGate
extends FlagGate
## 뿌리 문 (엘프 마을의 길목): 1장 FlagGate와 같은 규칙(open_if 플래그 식이 서면 열림)이지만,
## 굵은 뿌리가 얽혀 막고 있다가 열릴 때 스르르 땅속·양옆으로 물러난다. 장로·파수꾼이 길을 열어 줄 때 쓴다.
## 방 데이터: {t = "root_gate", x, y, w, h, open_if}

func open() -> void:
	super()
	Ch3Sfx.play(&"ch3_rustle", 0.0, 0.0)


func _draw() -> void:
	if _anim >= 1.0:
		return
	var a := 1.0 - _anim
	var n := maxi(int(size_px.x / 5.0), 2)
	for i in n:
		var x := (i + 0.5) * size_px.x / n
		var top := size_px.y * (1.0 - a)
		var pts := PackedVector2Array()
		for k in 8:
			var y := lerpf(size_px.y, top, k / 7.0)
			pts.append(Vector2(x + sin(k * 1.3 + i * 2.0 + _t * 0.6) * 2.0, y))
		draw_polyline(pts, Color("#3e2c1c"), 5.0)
		draw_polyline(pts, Color("#5e4430"), 2.0)
	# 가로로 얽힌 뿌리
	for j in int(size_px.y / 12.0):
		var y2 := size_px.y - j * 12.0 - 6.0
		if y2 < size_px.y * (1.0 - a):
			continue
		draw_line(Vector2(0, y2), Vector2(size_px.x, y2 - 4.0 + (j % 2) * 8.0), Color("#4a3622"), 3.0)
	# 이끼와 작은 빛
	for j in 3:
		var p := Vector2(size_px.x * 0.5, size_px.y * (0.3 + j * 0.25))
		if p.y > size_px.y * (1.0 - a):
			draw_rect(Rect2(p + Vector2(-3, 0), Vector2(6, 2)), Color("#4e8a36"))
			draw_rect(Rect2(p, Vector2(1, 1)), Color(0.85, 1.0, 0.5, 0.6 + 0.4 * sin(_t * 2.0 + j)))
