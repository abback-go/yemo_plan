extends EnemyAttackArea
## 떨어지는 기와: 바닥에 붉은 그림자(warn초 전부터) → 천장에서 떨어져 부서짐 (피해 1, 대시로 스치면 퍼펙트 회피)
## 해태(haetae.gd)가 포효로 떨어뜨리는 기와.

const FALL_TIME := 0.38
const TILE_COL := Color("#33364f")
const TILE_LIGHT := Color("#5d6390")
const TILE_END := Color("#454a6e")

var floor_y := 0.0
var top_y := 0.0
var warn := 0.7
var _t := 0.0
var _done := false
var _spin := 0.0


func setup(floor_pos: Vector2, p_top_y: float, p_warn: float) -> void:
	global_position = Vector2(floor_pos.x, p_top_y)
	floor_y = floor_pos.y
	top_y = p_top_y
	warn = p_warn


func _ready() -> void:
	cause = &"haetae_tile"
	damage = 1
	dodgeable = true
	active = false
	z_index = 4
	_spin = randf_range(-1.0, 1.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(18, 10)
	shape.shape = rect
	add_child(shape)
	# 천장에서 먼지가 조금 떨어지며 시작
	Fx.burst(Vector2(global_position.x, top_y + 2.0), 4, {
		direction = Vector2.DOWN, spread = 20.0, speed_min = 10.0, speed_max = 30.0, lifetime = 0.5,
		gradient = Palette.fade_gradient(Color("#8a86a8")), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 200),
	})


func _physics_process(delta: float) -> void:
	if _done:
		return
	var d := delta * Fx.enemy_time # 위치 타임 중엔 기와도 느려진다
	_t += d
	var k := clampf((_t - (warn - FALL_TIME)) / FALL_TIME, 0.0, 1.0)
	global_position.y = lerpf(top_y, floor_y - 5.0, k * k)
	active = _t >= warn - FALL_TIME
	if _t >= warn:
		_shatter()
	queue_redraw()


func _shatter() -> void:
	_done = true
	global_position.y = floor_y - 5.0
	Fx.burst(Vector2(global_position.x, floor_y - 3.0), 14, {
		direction = Vector2.UP, spread = 70.0, speed_min = 40.0, speed_max = 130.0, lifetime = 0.45,
		gradient = Palette.fade_gradient(TILE_LIGHT), size_min = 1.5, size_max = 3.0, gravity = Vector2(0, 500),
	})
	Fx.shake(0.08, 0.12)
	Sfx.play(&"crumble", -9.0, 0.15)
	# 바닥에 닿는 순간을 놓치지 않게 잠깐 더 켜 두었다가 지운다
	var tw := create_tween()
	tw.tween_interval(0.05)
	tw.tween_callback(queue_free)
	queue_redraw()


func _draw() -> void:
	if _done:
		return
	var fy := floor_y - global_position.y
	var ty := top_y - global_position.y
	# 붉은 그림자: 처음엔 작고 흐리다가, 떨어질수록 커지고 진해진다 + 떨어질 줄기를 옅은 붉은 빛으로
	var k := clampf(_t / warn, 0.0, 1.0)
	var w := 12.0 + 14.0 * k
	var pulse := 0.6 + 0.4 * sin(_t * 30.0)
	var col := Color(Palette.DANGER, (0.35 + 0.55 * k) * pulse)
	draw_rect(Rect2(-1.0, ty, 2.0, fy - ty), Color(Palette.DANGER, 0.06 + 0.12 * k))
	draw_rect(Rect2(-w * 0.5, fy - 3.0, w, 4.0), col)
	draw_rect(Rect2(-w * 0.5 - 2.0, fy - 6.0, 2.0, 6.0), col)
	draw_rect(Rect2(w * 0.5, fy - 6.0, 2.0, 6.0), col)
	draw_rect(Rect2(-w * 0.5 + 3.0, fy - 5.0, w - 6.0, 1.0), Color(Palette.DANGER, 0.25 + 0.35 * k))
	if not active:
		return
	# 기와 한 장 (암키와 + 막새)
	draw_set_transform(Vector2.ZERO, _spin * _t * 2.0, Vector2.ONE)
	draw_rect(Rect2(-11, -6, 22, 12), Color(Palette.DANGER, 0.35)) # 어두운 배경에서도 보이게 붉은 테
	draw_rect(Rect2(-10, -5, 20, 10), Palette.OUTLINE)
	draw_rect(Rect2(-9, -4, 18, 8), TILE_COL)
	draw_rect(Rect2(-9, -4, 18, 2), TILE_LIGHT)
	draw_line(Vector2(-3, -2), Vector2(-3, 4), Palette.OUTLINE, 1.0)
	draw_line(Vector2(3, -2), Vector2(3, 4), Palette.OUTLINE, 1.0)
	draw_circle(Vector2(9, 0), 4.0, Palette.OUTLINE)
	draw_circle(Vector2(9, 0), 3.0, TILE_END)
	draw_rect(Rect2(8, -1, 2, 2), Color("#b8322a"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
