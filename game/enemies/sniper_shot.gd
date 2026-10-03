class_name SniperShot
extends EnemyAttackArea
## 저격탄: 직선으로 날아가 지형이나 세라에 닿으면 사라진다. 대시 무적 중에는 통과한다.

var dir := Vector2.LEFT
var speed := 224.0
var _life := 3.0
var _trail: Array[Vector2] = []


func setup(pos: Vector2, p_dir: Vector2, p_speed: float) -> void:
	global_position = pos
	dir = p_dir
	speed = p_speed


func _ready() -> void:
	cause = &"sniper"
	collision_mask = GameConst.L_WORLD
	monitoring = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 2.5
	shape.shape = circle
	add_child(shape)
	body_entered.connect(func(_b: Node) -> void: _pop())
	hit_player.connect(func(_p: Node) -> void: _pop())
	z_index = 4


func _physics_process(delta: float) -> void:
	_trail.push_front(global_position)
	if _trail.size() > 6:
		_trail.pop_back()
	global_position += dir * speed * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()
	queue_redraw()


func _pop() -> void:
	if not active:
		return
	active = false
	set_deferred("monitoring", false)
	Fx.burst(global_position, 6, {
		spread = 180.0, speed_min = 20.0, speed_max = 70.0, lifetime = 0.2,
		gradient = Palette.fade_gradient(Palette.SHOT), size_min = 1.0, size_max = 2.0,
	})
	queue_free()


func _draw() -> void:
	var prev := Vector2.ZERO
	for i in _trail.size():
		var p := to_local(_trail[i])
		var k := 1.0 - float(i) / _trail.size()
		draw_line(prev, p, Color(Palette.SHOT, 0.6 * k), 2.0 * k + 0.5)
		prev = p
	draw_line(-dir * 4.0, dir * 3.0, Palette.SHOT, 3.0)
	draw_line(-dir * 2.0, dir * 3.0, Color.WHITE, 1.0)
