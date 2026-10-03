class_name RoomBackdrop
extends RefCounted
## 방 배경: 화면 고정 하늘 → 먼 실루엣(0.15) → 중간 거대 구조물(0.45) → 가까운 구조물(0.75) → (지형) → 전경 검은 실루엣(1.2).
## INARI 스크린샷처럼 "작은 캐릭터 + 화면을 압도하는 거대한 배경 구조물 + 어두운 저채도 + 강조색 빛".
## 각 층은 Parallax2D 안의 BackdropLayer가 방 크기에 맞춰 시드 고정 난수로 그린다(방마다 같은 모습).


static func build(room: Room, holder: Node2D) -> void:
	var th := room.theme
	var sky := CanvasLayer.new()
	sky.layer = -30
	sky.follow_viewport_enabled = false
	var sky_draw := SkyDraw.new()
	sky_draw.pal = th
	sky_draw.theme_name = room.data.theme
	sky_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky.add_child(sky_draw)
	holder.add_child(sky)

	var seed := hash(room.data.id)
	for spec in [[0.15, BackdropLayer.FAR], [0.45, BackdropLayer.MID], [0.75, BackdropLayer.NEAR]]:
		var px := Parallax2D.new()
		px.scroll_scale = Vector2(spec[0], spec[0] * 0.6 + 0.4)
		px.ignore_camera_scroll = false
		var layer := BackdropLayer.new()
		layer.depth = spec[1]
		layer.theme = th
		layer.theme_name = room.data.theme
		layer.room_size = room.size_px
		layer.scroll = spec[0]
		layer.rng_seed = seed + spec[1] * 101
		px.add_child(layer)
		holder.add_child(px)

	# 안개 띠와 떠다니는 입자
	var fog := FogDraw.new()
	fog.color = th.fog
	fog.room_size = room.size_px
	fog.z_index = 1
	holder.add_child(fog)
	holder.add_child(_particles(room))
	if room.data.dark > 0.0:
		var dark := CanvasModulate.new()
		dark.color = Color(1, 1, 1).darkened(room.data.dark)
		holder.add_child(dark)


static func build_foreground(room: Room, holder: Node2D) -> void:
	var px := Parallax2D.new()
	px.scroll_scale = Vector2(1.18, 1.05)
	var layer := BackdropLayer.new()
	layer.depth = BackdropLayer.FRONT
	layer.theme = room.theme
	layer.theme_name = room.data.theme
	layer.room_size = room.size_px
	layer.scroll = 1.18
	layer.rng_seed = hash(room.data.id) + 999
	px.add_child(layer)
	holder.add_child(px)


static func _particles(room: Room) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	var kind := String(room.theme.particles)
	var area := room.size_px
	p.position = area * 0.5
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = area * 0.5
	p.amount = clampi(int(area.x * area.y / 9000.0), 20, 90)
	p.lifetime = 6.0
	p.preprocess = 6.0
	p.local_coords = false
	p.z_index = 2
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.spread = 180.0
	var col := Color(1, 1, 1, 0.3)
	match kind:
		"embers":
			p.direction = Vector2.UP
			p.gravity = Vector2(4, -10)
			p.initial_velocity_min = 4.0
			p.initial_velocity_max = 14.0
			col = Color(1.0, 0.55, 0.25, 0.7)
			p.material = Fx.add_material
		"foxfire":
			p.direction = Vector2.UP
			p.gravity = Vector2(0, -6)
			p.initial_velocity_min = 2.0
			p.initial_velocity_max = 10.0
			col = Color(0.5, 0.8, 1.0, 0.6)
			p.material = Fx.add_material
		"drips":
			p.direction = Vector2.DOWN
			p.spread = 2.0
			p.gravity = Vector2(0, 60)
			p.initial_velocity_min = 10.0
			p.initial_velocity_max = 20.0
			p.amount = maxi(p.amount / 3, 10)
			col = Color(0.55, 0.5, 0.9, 0.5)
		"fireflies":
			p.direction = Vector2(0.3, -1)
			p.gravity = Vector2(2, -3)
			p.initial_velocity_min = 2.0
			p.initial_velocity_max = 8.0
			col = Color(0.85, 1.0, 0.45, 0.8)
			p.material = Fx.add_material
		"stars":
			p.direction = Vector2(0.2, -1)
			p.gravity = Vector2(0, -2)
			p.initial_velocity_min = 1.0
			p.initial_velocity_max = 4.0
			col = Color(1.0, 0.95, 0.75, 0.75)
			p.material = Fx.add_material
		"light":
			p.direction = Vector2.UP
			p.gravity = Vector2(0, -8)
			p.initial_velocity_min = 3.0
			p.initial_velocity_max = 10.0
			col = Color(1.0, 0.88, 0.5, 0.6)
			p.material = Fx.add_material
		"spores":
			p.direction = Vector2(0.4, -1)
			p.gravity = Vector2(1, -4)
			p.initial_velocity_min = 2.0
			p.initial_velocity_max = 7.0
			col = Color(0.4, 1.0, 0.85, 0.55)
			p.material = Fx.add_material
		"ash":
			p.direction = Vector2(0.6, 1)
			p.gravity = Vector2(6, 10)
			p.initial_velocity_min = 4.0
			p.initial_velocity_max = 14.0
			col = Color(0.75, 0.7, 0.68, 0.55)
		"blight":
			p.direction = Vector2(0.2, 1)
			p.gravity = Vector2(2, 6)
			p.initial_velocity_min = 2.0
			p.initial_velocity_max = 8.0
			col = Color(0.95, 0.95, 1.0, 0.6)
		"leaves":
			p.direction = Vector2(1, 0.5)
			p.gravity = Vector2(5, 9)
			p.initial_velocity_min = 5.0
			p.initial_velocity_max = 14.0
			col = Color(0.55, 0.85, 0.35, 0.65)
		"petals":
			p.direction = Vector2(1, 0.3)
			p.gravity = Vector2(6, 8)
			p.initial_velocity_min = 6.0
			p.initial_velocity_max = 16.0
			col = Color(1.0, 0.75, 0.85, 0.6)
		_:
			# 먼지·빛 알갱이
			p.direction = Vector2(1, -0.2)
			p.gravity = Vector2(1, -2)
			p.initial_velocity_min = 1.0
			p.initial_velocity_max = 5.0
			col = Color(1.0, 0.9, 0.7, 0.35) if kind == "motes" else Color(0.8, 0.95, 0.85, 0.3)
			p.material = Fx.add_material
	var g := Gradient.new()
	g.set_color(0, Color(col, 0.0))
	g.set_color(1, Color(col, 0.0))
	g.add_point(0.2, col)
	g.add_point(0.8, col)
	p.color_ramp = g
	p.emitting = true
	return p


# ─── 화면 고정 하늘 ─────────────────────────────────────

class SkyDraw extends Control:
	var pal := {}
	var theme_name := ""
	var _t := 0.0

	var _ext: GDScript = null ## 이 하늘을 그리는 장별 배경 스크립트

	func _ready() -> void:
		for s in ChapterRegistry.backdrop_scripts():
			if s.has_sky(theme_name):
				_ext = s
				break

	func _process(delta: float) -> void:
		_t += delta
		if theme_name in ["shingye", "exterior"] or _ext != null:
			queue_redraw()

	func _draw() -> void:
		if _ext != null:
			_ext.draw_sky(self, theme_name, pal, _t)
			return
		var top: Color = pal.sky_top
		var bot: Color = pal.sky_bottom
		var steps := 24
		for i in steps:
			var k := float(i) / (steps - 1)
			# 계단식 그라데이션 (픽셀 느낌)
			draw_rect(Rect2(0, i * 15, 640, 16), top.lerp(bot, pow(k, 1.3)))
		if theme_name in ["shingye", "exterior"]:
			var rng := RandomNumberGenerator.new()
			rng.seed = 42
			for i in 70:
				var p := Vector2(rng.randf() * 640, rng.randf() * 220)
				var tw := 0.4 + 0.6 * absf(sin(_t * rng.randf_range(0.5, 2.0) + i))
				draw_rect(Rect2(p, Vector2.ONE * (2 if i % 9 == 0 else 1)), Color(1, 1, 1, 0.5 * tw))
			# 달 + 달무리
			var mc := Vector2(500, 74) if theme_name == "shingye" else Vector2(120, 60)
			for r in [70, 52, 40]:
				draw_circle(mc, r, Color(1, 0.95, 0.85, 0.035))
			draw_circle(mc, 26, Color("#f3e6d0"))
			draw_circle(mc + Vector2(-7, -5), 6, Color("#e2d2b8"))
			draw_circle(mc + Vector2(8, 7), 4, Color("#e2d2b8"))


# ─── 시차 실루엣 층 ─────────────────────────────────────

class BackdropLayer extends Node2D:
	const FAR := 0
	const MID := 1
	const NEAR := 2
	const FRONT := 3
	var depth := FAR
	var theme := {}
	var theme_name := ""
	var room_size := Vector2(640, 368)
	var scroll := 0.5
	var rng_seed := 0
	var _rng := RandomNumberGenerator.new()
	var _t := 0.0
	var _animated := false

	func _ready() -> void:
		_animated = theme_name == "clock" and depth != FRONT
		for s in ChapterRegistry.backdrop_scripts():
			if s.is_animated(theme_name, depth):
				_animated = true
		z_index = -10 + depth * 2 if depth != FRONT else 0

	func _process(delta: float) -> void:
		if _animated:
			_t += delta
			queue_redraw()

	## 이 층이 덮어야 하는 너비 (시차만큼 덜 움직이므로 방보다 좁아도 됨)
	func _span() -> Vector2:
		# 세로 시차는 scroll * 0.6 + 0.4 (build의 scroll_scale.y)라 세로로 긴 방은 그만큼 더 덮어야 함
		return Vector2(640 + (room_size.x - 640) * scroll + 200, 368 + (room_size.y - 368) * (scroll * 0.6 + 0.4) + 120)

	func _col() -> Color:
		match depth:
			FAR: return theme.far
			MID: return theme.mid
			NEAR: return theme.near
		return Color(0.02, 0.015, 0.03)

	func _draw() -> void:
		_rng.seed = rng_seed
		var span := _span()
		# 2장부터의 지역: world/themes/backdrop_<장>.gd
		for s in ChapterRegistry.backdrop_scripts():
			if s.draw_layer(self, theme_name, depth, span, _rng, _t):
				return
		match theme_name:
			"shingye": _draw_shingye(span)
			"shrine": _draw_shrine(span)
			"library": _draw_library(span)
			"clock": _draw_clock(span)
			"basement": _draw_basement(span)
			"exterior", "greenhouse": _draw_exterior(span)
			_: _draw_school(span)

	# 신계 바깥: 겹겹의 산 → 소나무·기와지붕 → 가까운 바위
	func _draw_shingye(span: Vector2) -> void:
		var col := _col()
		var base_y := span.y * (0.62 if depth == FAR else (0.72 if depth == MID else 0.86))
		if depth == FRONT:
			_front_silhouettes(span, col)
			return
		var pts := PackedVector2Array([Vector2(-100, span.y + 50)])
		var x := -100.0
		while x < span.x + 100:
			var h := _rng.randf_range(40, 120) * (1.4 if depth == FAR else 0.8)
			pts.append(Vector2(x, base_y - h))
			x += _rng.randf_range(60, 140)
			pts.append(Vector2(x, base_y - h * _rng.randf_range(0.2, 0.6)))
			x += _rng.randf_range(40, 90)
		pts.append(Vector2(span.x + 100, span.y + 50))
		draw_colored_polygon(pts, col)
		if depth == MID:
			# 기와지붕 정자와 홍살문 실루엣
			for i in int(span.x / 360) + 1:
				var cx := 160 + i * 360 + _rng.randf_range(-60, 60)
				var cy := base_y - 30
				draw_rect(Rect2(cx - 30, cy, 60, 40), col.lightened(0.04))
				draw_colored_polygon(PackedVector2Array([Vector2(cx - 52, cy + 2), Vector2(cx - 40, cy - 14), Vector2(cx + 40, cy - 14), Vector2(cx + 52, cy + 2)]), col.lightened(0.07))
				draw_rect(Rect2(cx - 8, cy + 14, 16, 26), Color(1.0, 0.55, 0.3, 0.35))
		if depth == NEAR:
			# 소나무
			for i in int(span.x / 120) + 2:
				var tx := i * 120 + _rng.randf_range(-30, 30)
				var ty := base_y + _rng.randf_range(-10, 20)
				draw_rect(Rect2(tx - 3, ty - 80, 6, 90), col)
				for j in 3:
					var w := 46.0 - j * 10.0
					var yy := ty - 70 + j * 18
					draw_colored_polygon(PackedVector2Array([Vector2(tx - w, yy + 8), Vector2(tx, yy - 10), Vector2(tx + w, yy + 6)]), col.lightened(0.02))

	# 신계 실내: 붉은 단청 기둥, 매달린 등롱, 거대한 여우 문양
	func _draw_shrine(span: Vector2) -> void:
		var col := _col()
		if depth == FRONT:
			_front_silhouettes(span, col)
			return
		var gap := 150.0 if depth == FAR else (210.0 if depth == MID else 300.0)
		var red := Color("#5a1a1a") if depth == NEAR else Color("#3a1418").lerp(col, 0.5 if depth == FAR else 0.2)
		var x := _rng.randf_range(0, gap)
		while x < span.x:
			var w := 18.0 + depth * 10.0
			draw_rect(Rect2(x, -20, w, span.y + 40), red)
			draw_rect(Rect2(x - 4, 40, w + 8, 10), Color("#2a4a3a").lerp(col, 0.3))
			draw_rect(Rect2(x - 4, 52, w + 8, 4), Color("#b8883a").lerp(col, 0.4))
			if depth == MID:
				var ly := 80.0 + _rng.randf_range(0, 60)
				draw_line(Vector2(x + w * 0.5 + 40, -10), Vector2(x + w * 0.5 + 40, ly), col.lightened(0.1), 1.0)
				draw_rect(Rect2(x + w * 0.5 + 33, ly, 14, 20), Color(0.9, 0.35, 0.2, 0.9))
				draw_rect(Rect2(x + w * 0.5 + 35, ly + 4, 10, 12), Color(1.0, 0.7, 0.4, 0.9))
			x += gap + _rng.randf_range(-30, 30)
		if depth == FAR:
			# 아홉 꼬리 문양 (거대한 벽화)
			var c := Vector2(span.x * 0.5, span.y * 0.4)
			for i in 9:
				var a := -PI * 0.9 + i * PI * 0.2 / 1.0 * 0.9
				var tip := c + Vector2(cos(a), sin(a)) * 150
				draw_line(c, tip, Color(0.4, 0.6, 1.0, 0.06), 10.0)

	# 학교 실내: 거대한 아치 창(스테인드글라스 빛) + 기둥 + 깃발
	func _draw_school(span: Vector2) -> void:
		var col := _col()
		if depth == FRONT:
			_front_silhouettes(span, col)
			return
		draw_rect(Rect2(-100, -100, span.x + 200, span.y + 200), col)
		var gap := 260.0 if depth == FAR else (340.0 if depth == MID else 460.0)
		var x := _rng.randf_range(20, gap * 0.5)
		var glass := [Color("#3a4a8a"), Color("#8a3a5a"), Color("#c8a040"), Color("#3a7a6a")]
		while x < span.x:
			if depth == FAR:
				# 아치 창
				var w := 70.0
				var top := 40.0
				var h := span.y * 0.55
				var arch := PackedVector2Array()
				for i in 9:
					var a := PI + PI * i / 8.0
					arch.append(Vector2(x + w * 0.5 + cos(a) * w * 0.5, top + w * 0.5 + sin(a) * w * 0.5))
				arch.append(Vector2(x + w, top + h))
				arch.append(Vector2(x, top + h))
				draw_colored_polygon(arch, Color(theme.accent, 0.10))
				for row in 6:
					for c in 3:
						var gc: Color = glass[(row + c + int(x)) % glass.size()]
						draw_rect(Rect2(x + 6 + c * 20, top + 30 + row * 20, 17, 17), Color(gc, 0.22))
				draw_rect(Rect2(x - 6, top + h, w + 12, 8), col.lightened(0.05))
			elif depth == MID:
				# 굵은 기둥 + 깃발
				draw_rect(Rect2(x, -20, 34, span.y + 40), col.lightened(0.05))
				draw_rect(Rect2(x - 6, span.y * 0.15, 46, 8), col.lightened(0.09))
				var bcs: Array[Color] = [Color("#5a1e2e"), Color("#1e2e5a"), Color("#2e4a2a")]
				var bc: Color = bcs[int(x) % 3]
				draw_colored_polygon(PackedVector2Array([Vector2(x + 50, 60), Vector2(x + 86, 60), Vector2(x + 86, 150), Vector2(x + 68, 136), Vector2(x + 50, 150)]), bc)
				draw_rect(Rect2(x + 64, 90, 8, 8), Color("#c8a040"))
			else:
				# 가까운 아치 골조
				draw_rect(Rect2(x, -20, 22, span.y + 40), col)
				var arch2 := PackedVector2Array()
				for i in 9:
					var a := PI + PI * i / 8.0
					arch2.append(Vector2(x + 11 + 120 + cos(a) * 120, 30 + sin(a) * 50))
				draw_polyline(arch2, col, 10.0)
			x += gap + _rng.randf_range(-40, 40)

	# 도서관: 끝없이 솟은 책장 (책등은 짧은 사각형들)
	func _draw_library(span: Vector2) -> void:
		var col := _col()
		if depth == FRONT:
			_front_silhouettes(span, col)
			return
		draw_rect(Rect2(-100, -100, span.x + 200, span.y + 200), col)
		var shelf_w := 90.0 if depth == FAR else (120.0 if depth == MID else 150.0)
		var gap := 40.0 + depth * 60.0
		var x := _rng.randf_range(0, gap)
		var book_cols := [Color("#5a2a2a"), Color("#2a3a5a"), Color("#4a4a2a"), Color("#2a4a3a"), Color("#5a4a3a")]
		var dim := 0.55 if depth == FAR else (0.35 if depth == MID else 0.15)
		while x < span.x:
			draw_rect(Rect2(x, -20, shelf_w, span.y + 40), col.lightened(0.04))
			var y := 10.0
			while y < span.y:
				draw_rect(Rect2(x, y, shelf_w, 3), col.lightened(0.09))
				var bx := x + 3
				while bx < x + shelf_w - 6:
					var bw := _rng.randf_range(3, 7)
					var bh := _rng.randf_range(14, 22)
					var bc: Color = book_cols[_rng.randi() % book_cols.size()]
					draw_rect(Rect2(bx, y - bh, bw, bh), bc.lerp(col, dim))
					bx += bw + 1
				y += 30
			if depth == MID:
				draw_line(Vector2(x + shelf_w + 8, -20), Vector2(x + shelf_w - 10, span.y), Color("#4a3a28").lerp(col, 0.3), 3.0)
			x += shelf_w + gap + _rng.randf_range(0, 50)

	# 시계탑: 거대한 톱니바퀴(천천히 회전), 사슬, 철골 (INARI 스크린샷과 가장 가까운 장면)
	func _draw_clock(span: Vector2) -> void:
		var col := _col()
		if depth == FRONT:
			_front_silhouettes(span, col)
			return
		var count := 3 + depth
		for i in count:
			var c := Vector2(_rng.randf_range(0, span.x), _rng.randf_range(0, span.y))
			var r := _rng.randf_range(60, 130) * (1.4 if depth == FAR else (1.0 if depth == MID else 0.7))
			var dir := 1.0 if i % 2 == 0 else -1.0
			_gear(c, r, _t * 0.15 * dir * (80.0 / r), col.lightened(0.03 * depth))
		# 철골
		var x := _rng.randf_range(0, 200)
		while x < span.x:
			draw_rect(Rect2(x, -20, 14, span.y + 40), col.lightened(0.02))
			var y := 0.0
			while y < span.y:
				draw_line(Vector2(x, y), Vector2(x + 14, y + 20), col.lightened(0.06), 2.0)
				draw_line(Vector2(x + 14, y), Vector2(x, y + 20), col.lightened(0.06), 2.0)
				y += 20
			x += 260 + _rng.randf_range(0, 120)
		if depth >= MID:
			for i in 3:
				var cx := _rng.randf_range(0, span.x)
				var y2 := -10.0
				while y2 < span.y * _rng.randf_range(0.3, 0.8):
					draw_rect(Rect2(cx - 3, y2, 6, 8), col.lightened(0.08))
					draw_rect(Rect2(cx - 1, y2 + 2, 2, 4), col.darkened(0.3))
					y2 += 9

	func _gear(c: Vector2, r: float, rot: float, col: Color) -> void:
		var teeth := int(r / 9.0)
		var pts := PackedVector2Array()
		for i in teeth * 2:
			var a := rot + TAU * i / (teeth * 2)
			var rr := r if i % 2 == 0 else r * 0.86
			pts.append(c + Vector2(cos(a), sin(a)) * rr)
			var a2 := rot + TAU * (i + 0.5) / (teeth * 2)
			pts.append(c + Vector2(cos(a2), sin(a2)) * rr)
		draw_colored_polygon(pts, col)
		draw_circle(c, r * 0.62, col.darkened(0.25))
		draw_circle(c, r * 0.5, col)
		for i in 5:
			var a := rot + TAU * i / 5.0
			draw_line(c, c + Vector2(cos(a), sin(a)) * r * 0.62, col.lightened(0.05), r * 0.1)
		draw_circle(c, r * 0.14, col.lightened(0.08))

	# 지하: 낮은 아치, 늘어진 사슬, 보라빛 봉인 문양
	func _draw_basement(span: Vector2) -> void:
		var col := _col()
		if depth == FRONT:
			_front_silhouettes(span, col)
			return
		draw_rect(Rect2(-100, -100, span.x + 200, span.y + 200), col)
		var gap := 220.0 + depth * 80.0
		var x := _rng.randf_range(0, gap)
		while x < span.x:
			var arch := PackedVector2Array()
			for i in 11:
				var a := PI + PI * i / 10.0
				arch.append(Vector2(x + 100 + cos(a) * 100, span.y * 0.5 + sin(a) * 90))
			draw_polyline(arch, col.lightened(0.05), 14.0)
			draw_rect(Rect2(x - 7, span.y * 0.5, 14, span.y), col.lightened(0.05))
			if depth == FAR:
				draw_arc(Vector2(x + 100, span.y * 0.45), 34, 0, TAU, 24, Color(0.7, 0.45, 1.0, 0.10), 2.0)
				for i in 6:
					var a := TAU * i / 6.0
					draw_line(Vector2(x + 100, span.y * 0.45) + Vector2(cos(a), sin(a)) * 34, Vector2(x + 100, span.y * 0.45) + Vector2(cos(a + 2.1), sin(a + 2.1)) * 34, Color(0.7, 0.45, 1.0, 0.08), 1.0)
			if depth == NEAR:
				var y := -10.0
				var len := _rng.randf_range(0.2, 0.5) * span.y
				while y < len:
					draw_rect(Rect2(x + 60, y, 5, 7), col.lightened(0.07))
					y += 8
			x += gap + _rng.randf_range(-40, 40)

	# 바깥(앞마당·온실): 언덕 위 학교 실루엣, 나무
	func _draw_exterior(span: Vector2) -> void:
		var col := _col()
		if depth == FRONT:
			_front_silhouettes(span, col)
			return
		if depth == FAR:
			var cx := span.x * 0.55
			var by := span.y * 0.7
			draw_rect(Rect2(cx - 200, by - 110, 400, 160), col)
			for t in [[-160, 180, 26], [-60, 240, 34], [40, 300, 40], [140, 200, 28], [210, 150, 22]]:
				var tx: float = cx + t[0]
				var th: float = t[1]
				var tw: float = t[2]
				draw_rect(Rect2(tx - tw * 0.5, by - th, tw, th), col)
				draw_colored_polygon(PackedVector2Array([Vector2(tx - tw * 0.7, by - th), Vector2(tx, by - th - tw * 1.4), Vector2(tx + tw * 0.7, by - th)]), col)
				for w in 3:
					draw_rect(Rect2(tx - 3, by - th + 20 + w * 24, 6, 9), Color(1.0, 0.8, 0.45, 0.5))
		else:
			var base_y := span.y * (0.78 if depth == MID else 0.9)
			for i in int(span.x / 70) + 2:
				var tx := i * 70.0 + _rng.randf_range(-20, 20)
				var r := _rng.randf_range(26, 44) * (0.8 if depth == MID else 1.1)
				draw_rect(Rect2(tx - 3, base_y - r, 6, r + 40), col)
				draw_circle(Vector2(tx, base_y - r * 1.4), r, col)
				draw_circle(Vector2(tx - r * 0.6, base_y - r), r * 0.7, col)
			draw_rect(Rect2(-50, base_y, span.x + 100, span.y), col)

	# 전경: 화면 아래·위 가장자리를 스치는 검은 덩어리 (INARI의 어두운 전경)
	func _front_silhouettes(span: Vector2, _c: Color) -> void:
		var dark := Color(0.015, 0.012, 0.025, 0.92)
		var x := _rng.randf_range(0, 300)
		while x < span.x:
			var w := _rng.randf_range(60, 160)
			var h := _rng.randf_range(16, 46)
			var bottom := span.y + 30
			match theme_name:
				"shingye", "exterior", "greenhouse":
					# 풀숲·바위 덩어리
					draw_circle(Vector2(x + w * 0.3, bottom - h * 0.4), h, dark)
					draw_circle(Vector2(x + w * 0.7, bottom - h * 0.2), h * 0.8, dark)
				"clock":
					_gear(Vector2(x + w * 0.5, bottom), h * 1.6, _t * 0.2, dark)
				_:
					draw_rect(Rect2(x, bottom - h, w, h + 10), dark)
					draw_rect(Rect2(x + 10, bottom - h - 8, w - 20, 8), dark)
			x += w + _rng.randf_range(260, 520)
		# 위쪽 가장자리: 늘어진 사슬·덩굴·등롱 줄
		if theme_name in ["clock", "basement", "shrine"]:
			var cx := _rng.randf_range(100, 400)
			while cx < span.x:
				var len := _rng.randf_range(30, 90)
				var y := -20.0
				while y < len:
					draw_rect(Rect2(cx - 3, y, 6, 7), dark)
					y += 8
				cx += _rng.randf_range(350, 700)


# ─── 안개 띠 ────────────────────────────────────────────

class FogDraw extends Node2D:
	var color := Color(1, 1, 1, 0.05)
	var room_size := Vector2(640, 368)
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		for i in 3:
			var y := room_size.y * (0.55 + 0.15 * i) + sin(_t * 0.3 + i) * 6.0
			draw_rect(Rect2(-20, y, room_size.x + 40, 26), color)
