class_name EnemyProjectile
extends EnemyAttackArea
## 적의 탄 공용 (저격탄을 일반화). 직선·포물선(gravity)·약한 유도(homing) 지원.
## style: fireball(붉은 불덩이) · foxwisp(도깨비불의 초록 불) · page(책장) · rock(돌탄) · dark(검은 불덩이) · seed(씨앗) · beam(광선탄)
## 위치 타임 중엔 느려지고, 대시 무적으로 스치면 퍼펙트 회피가 된다.

var dir := Vector2.LEFT
var speed := 200.0
var style := "fireball"
var grav := 0.0
var homing := 0.0 ## 초당 회전 각(라디안). 0이면 직선
var life := 4.0
var radius := 4.0
var hits_world := true
var _vel := Vector2.ZERO
var _t := 0.0
var _trail: Array[Vector2] = []
var _spin := 0.0


func setup(pos: Vector2, p_dir: Vector2, p_speed: float, p_style := "fireball", opts := {}) -> void:
	global_position = pos
	dir = p_dir.normalized() if p_dir != Vector2.ZERO else Vector2.LEFT
	speed = p_speed
	style = p_style
	grav = float(opts.get("gravity", 0.0))
	homing = float(opts.get("homing", 0.0))
	life = float(opts.get("life", 4.0))
	radius = float(opts.get("radius", 4.0))
	damage = int(opts.get("damage", 1))
	cause = StringName(opts.get("cause", "enemy"))
	hits_world = bool(opts.get("hits_world", true))
	_vel = dir * speed


func _ready() -> void:
	collision_mask = GameConst.L_WORLD if hits_world else 0
	monitoring = hits_world
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)
	if hits_world:
		body_entered.connect(func(_b: Node) -> void: pop())
	hit_player.connect(func(_p: Node) -> void: pop())
	z_index = 4
	if style in ["fireball", "foxwisp", "dark", "beam"]:
		material = Fx.add_material


func _physics_process(delta: float) -> void:
	var d := delta * Fx.enemy_time
	_t += d
	_spin += d * 10.0
	if homing > 0.0:
		var p := get_tree().get_first_node_in_group(GameConst.GROUP_PLAYER) as Player
		if p:
			var want := (p.center() - global_position).angle()
			var cur := _vel.angle()
			var diff := wrapf(want - cur, -PI, PI)
			_vel = _vel.rotated(clampf(diff, -homing * d, homing * d))
	_vel.y += grav * d
	_trail.push_front(global_position)
	if _trail.size() > 6:
		_trail.pop_back()
	global_position += _vel * d
	life -= d
	if life <= 0.0:
		pop(true)
	queue_redraw()


func pop(quiet := false) -> void:
	if not active:
		return
	active = false
	set_deferred("monitoring", false)
	if not quiet:
		Fx.burst(global_position, 6, {
			spread = 180.0, speed_min = 20.0, speed_max = 70.0, lifetime = 0.25,
			gradient = Palette.fade_gradient(_color()), size_min = 1.0, size_max = 2.0,
		})
	queue_free()


func _color() -> Color:
	match style:
		"foxwisp": return Color(0.55, 1.0, 0.7)
		"page": return Color("#e8dcc0")
		"rock": return Color("#8a8a9a")
		"dark": return Color(0.55, 0.3, 0.9)
		"seed": return Color("#a8c84a")
		"beam": return Palette.SHOT
	return Palette.FIRE_OUT


func _draw() -> void:
	var c := _color()
	var prev := Vector2.ZERO
	for i in _trail.size():
		var p := to_local(_trail[i])
		var k := 1.0 - float(i) / _trail.size()
		draw_line(prev, p, Color(c, 0.45 * k), radius * 1.2 * k + 0.5)
		prev = p
	match style:
		"page":
			var pts := PackedVector2Array()
			for i in 4:
				var a := _spin + TAU * i / 4.0
				pts.append(Vector2(cos(a) * 5.0, sin(a) * 3.0))
			draw_colored_polygon(pts, c)
			draw_line(pts[0], pts[2], Color("#8a7a6a"), 1.0)
		"rock":
			draw_circle(Vector2.ZERO, radius, c)
			draw_rect(Rect2(-1, -2, 2, 2), c.lightened(0.3))
		"seed":
			draw_circle(Vector2.ZERO, radius, c)
			draw_circle(Vector2(-1, -1), 1.0, c.lightened(0.4))
		"dark":
			draw_circle(Vector2.ZERO, radius + 2.0, Color(0.2, 0.05, 0.3, 0.8))
			draw_circle(Vector2.ZERO, radius, c)
			draw_circle(Vector2.ZERO, radius * 0.4, Color(0.95, 0.85, 1.0))
		"beam":
			var d := _vel.normalized()
			draw_line(-d * 4.0, d * 3.0, c, 3.0)
			draw_line(-d * 2.0, d * 3.0, Color.WHITE, 1.0)
		_:
			draw_circle(Vector2.ZERO, radius + 1.5, Color(c, 0.5))
			draw_circle(Vector2.ZERO, radius, c)
			draw_circle(Vector2.ZERO, radius * 0.45, Color(1, 1, 0.9))
