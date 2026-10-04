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


# ─── 장별 스크립트 찾기 (테마 → 스크립트, 한 번 찾으면 기억) ─────

const Kit := preload("res://world/themes/backdrop_kit.gd")
const Ch1 := preload("res://world/themes/backdrop_ch1.gd")

static var _layer_owner := {} ## 테마 → 층을 그리는 장별 스크립트 (없으면 null = 1장 기본)
static var _sky_owner := {} ## 테마 → 하늘을 그리는 장별 스크립트 (없으면 null = 1장 기본)


static func layer_script(theme_name: String) -> GDScript:
	if not _layer_owner.has(theme_name):
		_layer_owner[theme_name] = null
		for s in ChapterRegistry.backdrop_scripts():
			if s.has_theme(theme_name):
				_layer_owner[theme_name] = s
				break
	return _layer_owner[theme_name]


static func sky_script(theme_name: String) -> GDScript:
	if not _sky_owner.has(theme_name):
		_sky_owner[theme_name] = null
		for s in ChapterRegistry.backdrop_scripts():
			if s.has_sky(theme_name):
				_sky_owner[theme_name] = s
				break
	return _sky_owner[theme_name]


## 그림이 붙은 노드의 조상 Room ID (상징물 순서 등 방마다 다른 그림용)
static func _room_id_of(n: Node) -> String:
	var p := n.get_parent()
	while p != null:
		if p is Room:
			var r := p as Room
			return r.data.id if r.data else ""
		p = p.get_parent()
	return ""


# ─── 화면 고정 하늘 ─────────────────────────────────────

## 장별 하늘(draw_sky) 또는 1장 기본 하늘을 Pen에 한 번 기록 → 정적은 한 번, 별·구름 같은 움직임만 틱마다
class SkyDraw extends Control:
	var pal := {}
	var theme_name := ""
	var _t := 0.0
	var _parts: Array = []
	var _tick := Kit.Ticker.new()

	func _ready() -> void:
		var pen := Kit.Pen.new(Vector2(640, 360))
		pen.theme = pal
		pen.theme_name = theme_name
		var ext := RoomBackdrop.sky_script(theme_name)
		if ext != null:
			ext.draw_sky(pen, theme_name, pal, 0.0)
		else:
			Ch1.draw_sky(pen, theme_name, pal)
		_parts = Kit.mount(self, pen, false)
		set_process(not _parts.is_empty())

	func _process(delta: float) -> void:
		_t += delta
		if _tick.step(delta):
			for p in _parts:
				p.tick(_t)


# ─── 시차 실루엣 층 ─────────────────────────────────────

## 층 하나(먼·중간·가까운·전경). 방에 들어갈 때 테마 그림을 Pen에 한 번 기록하고 자식 노드(StaticPart·AnimPart)로 붙인다.
## 테마 스크립트가 읽는 필드 이름(theme·room_size·scroll·depth)은 Pen에도 같은 이름으로 있다.
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
	var _parts: Array = []
	var _procs: Array[Callable] = []
	var _tick := Kit.Ticker.new()

	func _ready() -> void:
		z_index = -10 + depth * 2 if depth != FRONT else 0
		var span := _span()
		var pen := Kit.Pen.new(span)
		pen.theme = theme
		pen.theme_name = theme_name
		pen.room_size = room_size
		pen.scroll = scroll
		pen.depth = depth
		pen.room_id = RoomBackdrop._room_id_of(self)
		_rng.seed = rng_seed
		# 2장부터의 지역: world/themes/backdrop_<장>.gd, 나머지는 1장(backdrop_ch1.gd)
		var ext := RoomBackdrop.layer_script(theme_name)
		if ext == null or not ext.draw_layer(pen, theme_name, depth, span, _rng, 0.0):
			Ch1.draw_layer(pen, theme_name, span, _rng)
		_parts = Kit.mount(self, pen, true)
		_procs = pen.procs
		set_process(not _parts.is_empty() or not _procs.is_empty())

	func _process(delta: float) -> void:
		_t += delta
		for f in _procs:
			f.call(self, _t)
		if _tick.step(delta):
			for p in _parts:
				p.tick(_t)

	## 이 층이 덮어야 하는 너비 (시차만큼 덜 움직이므로 방보다 좁아도 됨)
	func _span() -> Vector2:
		# 세로 시차는 scroll * 0.6 + 0.4 (build의 scroll_scale.y)라 세로로 긴 방은 그만큼 더 덮어야 함
		return Vector2(640 + (room_size.x - 640) * scroll + 200, 368 + (room_size.y - 368) * (scroll * 0.6 + 0.4) + 120)


# ─── 안개 띠 ────────────────────────────────────────────

class FogDraw extends Node2D:
	var color := Color(1, 1, 1, 0.05)
	var room_size := Vector2(640, 368)
	var _t := 0.0
	var _tick := Kit.Ticker.new()

	func _process(delta: float) -> void:
		_t += delta
		if _tick.step(delta):
			queue_redraw()

	func _draw() -> void:
		for i in 3:
			var y := room_size.y * (0.55 + 0.15 * i) + sin(_t * 0.3 + i) * 6.0
			draw_rect(Rect2(-20, y, room_size.x + 40, 26), color)
