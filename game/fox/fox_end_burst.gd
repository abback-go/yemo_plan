class_name FoxEndBurst
extends Node2D
## 여우 모드가 끝날 때 "제어된 방출": 주변에 작은 푸른 폭발(자기 피해 없음).

var _t := 0.0
const LIFE := 0.5
const RADIUS_T := 3.5


func setup(pos: Vector2, _tuning: Tuning) -> void:
	global_position = pos


func _ready() -> void:
	z_index = 6
	material = Fx.add_material
	Sfx.play(&"fox_end", 0.0, 0.0)
	var r := RADIUS_T * GameConst.TILE
	var c := global_position
	var in_reach := func(e: EnemyBase) -> bool: return EnemyBase.dist_to_body(e, c) <= r
	var push := func(e: EnemyBase) -> void:
		var h := Hit.make(25, &"fox_burst", c)
		h.knockback_t = 2.0
		e.take_hit(h)
	EnemyQuery.within(get_tree(), in_reach, push)
	Fx.ring(global_position, 4.0, r, FoxPalette.GLOW, 0.4, 2.0)
	Fx.burst(global_position, 30, {spread = 180.0, speed_min = 40.0, speed_max = 140.0, damping = 100.0, lifetime = 0.5,
		gradient = Palette.fade_gradient(FoxPalette.GLOW), add = true})


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var k := _t / LIFE
	draw_circle(Vector2.ZERO, RADIUS_T * 16.0 * k, Color(0.45, 0.75, 1.0, 0.25 * (1.0 - k)))
