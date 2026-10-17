class_name WhitePod
extends Node2D
## 흰 꼬투리 (사도의 둥지, docs/archive/sera/chapter3.md 9.10절): 백색 사도가 피오를 가둔 하얀 육각 고치. 천장에서 흰 실로 매달려
## 천천히 흔들린다. 안에 피오가 웅크린 그림자가 비친다(가끔 꿈틀). 직선·60도 마디만 있는 바깥 신들의 모양.
## 대본: c.actor("pod") → struggle()(꿈틀) · await crack()(금이 가며 깨지고 실이 끊김 → 사라짐, 피오는 대본이 따로 세움)
## 방 데이터: {t = "white_pod", x, y(꼬투리 아래 끝 행), who = "fio"}

const WHITE := Color("#eeeef8")
const SHADE := Color("#a8a8bc")
const LINE := Color("#c8c8dc")

var who := "fio"
var _t := 0.0
var _crack := -1.0 ## 0 이상이면 깨지는 중 (0 → 1)
var _wiggle := 0.0
var _thread := 120.0 ## 꼬투리 위 끝에서 천장까지(px)
var _cv: CharacterVisual
var _shell: Shell


func setup(room: Room, e: Dictionary, _eid: String) -> void:
	who = String(e.get("who", "fio"))
	position = room.tile_pos(e) + Vector2(8, 0)
	var tx := int(e.get("x", 0))
	var ty := int(e.get("y", 0))
	var k := ty - 3
	while k > 0 and room.data.char_at(tx, k) != "#":
		k -= 1
	_thread = maxf((ty - 3 - k) * 16.0 - 8.0, 16.0)
	z_index = 2
	_cv = CharacterVisual.new()
	_cv.setup(who)
	_cv.position = Vector2(0, -6)
	_cv.scale = Vector2(0.8, 0.8)
	_cv.modulate = Color(0.78, 0.82, 0.98, 0.95)
	add_child(_cv)
	_cv.set_pose("hurt")
	_shell = Shell.new()
	_shell.pod = self
	add_child(_shell)


func actor_id() -> String:
	return "pod"


## 안에서 꿈틀 (대사 연출용)
func struggle() -> void:
	_wiggle = 0.8
	Ch3Sfx.play(&"ch3_glass_low", -8.0, 0.1)


## 금이 가며 깨진다 → 실이 끊기고 조각이 흩어진 뒤 사라짐
func crack() -> void:
	if _crack >= 0.0:
		return
	_crack = 0.0
	Ch3Sfx.play(&"ch3_glass", -2.0, 0.0)
	var tw := create_tween()
	tw.tween_property(self, "_crack", 1.0, 0.9)
	await tw.finished
	Ch3Sfx.play(&"ch3_crystal_break", 0.0, 0.0)
	Fx.burst(global_position + Vector2(0, -22), 34, {spread = 180.0, speed_min = 40.0, speed_max = 170.0, lifetime = 0.8,
		gradient = Palette.fade_gradient(WHITE), size_min = 1.5, size_max = 3.0, gravity = Vector2(0, 220)})
	Fx.ring(global_position + Vector2(0, -22), 6.0, 40.0, WHITE, 0.4, 2.0)
	visible = false


func _process(delta: float) -> void:
	_t += delta
	_wiggle = maxf(_wiggle - delta, 0.0)
	var sway := sin(_t * 0.9) * 0.05 + sin(_t * 23.0) * 0.06 * _wiggle
	rotation = sway
	_cv.position.x = sin(_t * 1.7) * 0.6
	_shell.queue_redraw()


## 바깥 껍질 (인물 위에 그림)
class Shell extends Node2D:
	var pod: WhitePod

	func _draw() -> void:
		var t := pod._t
		var k := clampf(pod._crack, 0.0, 1.0) if pod._crack >= 0.0 else 0.0
		var top := Vector2(0, -44)
		# 실 (위 끝에서 천장까지) — 깨지는 중엔 끊김
		if k < 0.6:
			draw_line(top, top + Vector2(0, -pod._thread), Color(LINE, 0.8), 1.0)
			draw_line(top + Vector2(-3, 0), top + Vector2(0, -10), Color(LINE, 0.6), 1.0)
			draw_line(top + Vector2(3, 0), top + Vector2(0, -10), Color(LINE, 0.6), 1.0)
		# 육각 고치: 세로로 긴 육각형 두 겹 (반투명 — 안의 피오가 비침)
		var hx := PackedVector2Array([Vector2(0, -46), Vector2(15, -36), Vector2(15, -10), Vector2(0, 0), Vector2(-15, -10), Vector2(-15, -36)])
		var a := 0.42 * (1.0 - k)
		draw_colored_polygon(hx, Color(WHITE, a))
		var inner := PackedVector2Array()
		for p in hx:
			inner.append(p * 0.78 + Vector2(0, -5))
		draw_colored_polygon(inner, Color(0.85, 0.85, 0.95, a * 0.35))
		hx.append(hx[0])
		draw_polyline(hx, Color(SHADE, 1.0 - k), 2.0)
		draw_polyline(hx, Color(WHITE, 1.0 - k), 1.0)
		# 직선 무늬 (바깥 신들의 결)
		for i in 3:
			var y := -36.0 + i * 12.0
			draw_line(Vector2(-12, y), Vector2(12, y + 6.0), Color(LINE, 0.7 * (1.0 - k)), 1.0)
		# 맥동하는 흰빛
		var pulse := 0.5 + 0.5 * sin(t * 2.2)
		draw_circle(Vector2(0, -23), 20.0 + pulse * 3.0, Color(1, 1, 1, 0.05 * (1.0 - k)))
		# 금 (깨지는 중)
		if k > 0.0:
			var rng := RandomNumberGenerator.new()
			rng.seed = 7
			for i in int(4 + k * 10):
				var p0 := Vector2(rng.randf_range(-12, 12), rng.randf_range(-40, -6))
				var p1 := p0 + Vector2(rng.randf_range(-8, 8), rng.randf_range(-8, 8)) * (0.5 + k)
				draw_line(p0, p1, Color(0.25, 0.25, 0.35, 0.9), 1.0)
			draw_circle(Vector2(0, -23), 26.0 * k, Color(1, 1, 1, 0.25 * (1.0 - k)))
