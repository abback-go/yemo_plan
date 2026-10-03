extends Node2D
## 배경 (docs/prototype.md 13.1절): 밤하늘·달·별(화면 고정) + 마녀학교 첨탑 / 숲 / 가까운 나무 3겹 시차 스크롤 + 떠다니는 불씨.
## 모두 코드로 그린다. 레벨 높이가 화면 높이와 같아 세로 시차는 없다.

const W := 1280.0 ## 한 겹 그림의 반복 폭
const GROUND_Y := 320.0 ## 바닥 윗면 y (레벨 기준)


func _ready() -> void:
	z_index = -100
	var sky := CanvasLayer.new()
	sky.layer = -20
	sky.follow_viewport_enabled = false
	add_child(sky)
	var sky_draw := SkyDraw.new()
	sky.add_child(sky_draw)

	_add_layer(0.12, LayerDraw.Kind.SCHOOL)
	_add_layer(0.3, LayerDraw.Kind.FOREST_FAR)
	_add_layer(0.55, LayerDraw.Kind.FOREST_NEAR)

	var embers_layer := CanvasLayer.new()
	embers_layer.layer = -1
	add_child(embers_layer)
	var embers := CPUParticles2D.new()
	embers.position = Vector2(320, 372)
	embers.amount = 26
	embers.lifetime = 7.0
	embers.preprocess = 7.0
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(340, 4)
	embers.direction = Vector2(0.3, -1)
	embers.spread = 20.0
	embers.initial_velocity_min = 8.0
	embers.initial_velocity_max = 22.0
	embers.gravity = Vector2(4, -2)
	embers.scale_amount_min = 1.0
	embers.scale_amount_max = 1.5
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	g.colors = PackedColorArray([Color(Palette.FIRE_OUT, 0.0), Color(Palette.FIRE_MID, 0.55), Color(Palette.FIRE_OUT, 0.35), Color(Palette.FIRE_DARK, 0.0)])
	embers.color_ramp = g
	embers_layer.add_child(embers)


func _add_layer(scroll: float, kind: int) -> void:
	var p := Parallax2D.new()
	p.scroll_scale = Vector2(scroll, 1.0)
	p.repeat_size = Vector2(W, 0)
	p.repeat_times = 4
	add_child(p)
	var d := LayerDraw.new()
	d.kind = kind
	p.add_child(d)


class SkyDraw extends Node2D:
	func _draw() -> void:
		var top := Palette.SKY_TOP
		var bottom := Palette.SKY_BOTTOM
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(640, 0), Vector2(640, 360), Vector2(0, 360)]),
			PackedColorArray([top, top, bottom, bottom]))
		# 별
		for i in 70:
			var x := fmod(i * 97.13, 640.0)
			var y := fmod(i * 53.71 + i * i * 0.37, 230.0)
			var a := 0.25 + fmod(i * 0.618, 0.6)
			draw_rect(Rect2(x, y, 1, 1), Color(1, 0.95, 0.9, a))
		# 달과 달무리
		var m := Vector2(500, 70)
		draw_circle(m, 34.0, Color(Palette.MOON, 0.05))
		draw_circle(m, 24.0, Color(Palette.MOON, 0.08))
		draw_circle(m, 15.0, Palette.MOON)
		draw_circle(m + Vector2(-4, -3), 3.0, Color(0.85, 0.78, 0.68))
		draw_circle(m + Vector2(5, 4), 2.0, Color(0.85, 0.78, 0.68))


class LayerDraw extends Node2D:
	enum Kind { SCHOOL, FOREST_FAR, FOREST_NEAR }
	var kind := 0

	func _h(i: float) -> float:
		var x := sin(i * 12.9898 + kind * 78.233) * 43758.5453
		return x - floorf(x)

	func _draw() -> void:
		match kind:
			Kind.SCHOOL: _draw_school()
			Kind.FOREST_FAR: _draw_forest(Palette.MID, 250.0, 70.0, 26, 0.0)
			Kind.FOREST_NEAR: _draw_forest(Palette.NEAR, 280.0, 110.0, 16, 0.4)

	func _draw_school() -> void:
		var col := Palette.FAR
		# 먼 산
		var hills := PackedVector2Array([Vector2(0, 360)])
		for i in 33:
			var x := i * W / 32.0
			hills.append(Vector2(x, 250.0 - sin(i * 0.7) * 18.0 - _h(i) * 14.0))
		hills.append(Vector2(W, 360))
		draw_colored_polygon(hills, col.darkened(0.15))
		# 마녀학교: 성벽과 첨탑들
		var base_x := 380.0
		draw_rect(Rect2(base_x, 196, 240, 80), col)
		var towers := [[base_x - 10, 150, 26], [base_x + 50, 120, 22], [base_x + 110, 90, 30], [base_x + 175, 130, 22], [base_x + 230, 160, 18]]
		for t in towers:
			var tx: float = t[0]
			var ty: float = t[1]
			var tw: float = t[2]
			draw_rect(Rect2(tx, ty, tw, 280 - ty), col)
			draw_colored_polygon(PackedVector2Array([
				Vector2(tx - 3, ty), Vector2(tx + tw * 0.5 - 2, ty - tw * 1.4), Vector2(tx + tw * 0.5, ty - tw * 1.55), Vector2(tx + tw + 3, ty),
			]), col)
			# 불 켜진 창
			for wy in range(int(ty) + 10, 230, 16):
				if _h(tx + wy) > 0.45:
					draw_rect(Rect2(tx + tw * 0.5 - 1.5, wy, 3, 5), Color(Palette.FIRE_MID, 0.55))
		# 깃발
		draw_line(Vector2(base_x + 125, 47), Vector2(base_x + 125, 30), col, 1.0)
		draw_colored_polygon(PackedVector2Array([Vector2(base_x + 125, 30), Vector2(base_x + 135, 33), Vector2(base_x + 125, 36)]), Color(Palette.HAT_BAND, 0.6))

	func _draw_forest(col: Color, base: float, height: float, count: int, jitter: float) -> void:
		var ground := PackedVector2Array([Vector2(0, 360)])
		for i in 17:
			var x := i * W / 16.0
			ground.append(Vector2(x, base + 10.0 + _h(i + 50) * 8.0))
		ground.append(Vector2(W, 360))
		draw_colored_polygon(ground, col)
		for i in count:
			var x := (i + _h(i) * jitter) * W / count
			var h := height * (0.6 + _h(i + 10) * 0.5)
			var w := 10.0 + _h(i + 20) * 12.0
			var top := base - h
			# 뾰족한 침엽수: 층층이 쌓인 삼각형
			for layer in 4:
				var ly := top + layer * h * 0.22
				var lw := w * (0.5 + layer * 0.35)
				draw_colored_polygon(PackedVector2Array([
					Vector2(x, ly), Vector2(x + lw, ly + h * 0.32), Vector2(x - lw, ly + h * 0.32),
				]), col)
			draw_rect(Rect2(x - 1.5, base - h * 0.2, 3, h * 0.2 + 20), col)
