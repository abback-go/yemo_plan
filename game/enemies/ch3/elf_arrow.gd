class_name ElfArrow
extends EnemyAttackArea
## 엘프 화살 (엘라리엔·저격 구간·파수꾼 공용). 빠르게 곧게 날아가 지형에 박힌다(잠깐 꽂혀 있다가 사라짐).
## style: arrow(흰 깃 화살) · wind(바람 화살: 연둣빛, 맞으면 크게 밀려남) · rain(하늘에서 떨어지는 화살)
## 불꽃 방벽으로 되쏠 수 있다(docs/systems2.md 3절): enemy_projectile 그룹 + reflect(dir, damage) → 불붙은 화살이 되어
## 적을 맞히면 Hit.kind = &"reflect".

const SHAFT := Color("#d8c098")
const FLETCH := Color("#ffffff")
const WIND := Color(0.82, 1.0, 0.7)

var dir := Vector2.RIGHT
var speed := 520.0
var style := "arrow"
var grav := 0.0
var life := 3.0
var push := 0.0 ## 맞았을 때 밀어내는 세기 (px/s)
var reflected := false
var _vel := Vector2.ZERO
var _t := 0.0
var _stuck := -1.0 ## 0 이상이면 박힌 뒤 지난 시간
var _trail: Array[Vector2] = []
var _hit_once := {}


func setup(pos: Vector2, p_dir: Vector2, p_speed: float, opts := {}) -> void:
	global_position = pos
	dir = p_dir.normalized() if p_dir != Vector2.ZERO else Vector2.RIGHT
	speed = p_speed
	style = String(opts.get("style", "arrow"))
	grav = float(opts.get("gravity", 0.0))
	life = float(opts.get("life", 3.0))
	damage = int(opts.get("damage", 1))
	push = float(opts.get("push", 0.0))
	cause = StringName(opts.get("cause", "arrow"))
	_vel = dir * speed


func _ready() -> void:
	add_to_group(&"enemy_projectile")
	collision_mask = GameConst.L_WORLD
	monitoring = true
	var shape := CollisionShape2D.new()
	var c := CapsuleShape2D.new()
	c.radius = 2.5 if style != "wind" else 4.0
	c.height = 12.0
	shape.shape = c
	shape.rotation = PI * 0.5
	add_child(shape)
	body_entered.connect(_on_world)
	area_entered.connect(_on_area)
	hit_player.connect(_on_player)
	z_index = 5
	rotation = _vel.angle()
	if style == "wind":
		material = Fx.add_material


func _physics_process(delta: float) -> void:
	var d := delta * (Fx.enemy_time if not reflected else 1.0)
	_t += d
	if _stuck >= 0.0:
		_stuck += delta
		if _stuck > 1.6:
			queue_free()
		queue_redraw()
		return
	_vel.y += grav * d
	_trail.push_front(global_position)
	if _trail.size() > 7:
		_trail.pop_back()
	global_position += _vel * d
	rotation = _vel.angle()
	life -= d
	if life <= 0.0:
		queue_free()
	if style == "wind" and Engine.get_physics_frames() % 2 == 0:
		Fx.burst(global_position, 1, {direction = -_vel.normalized(), spread = 30.0, speed_min = 10.0, speed_max = 30.0,
			lifetime = 0.35, gradient = Palette.fade_gradient(WIND), size_min = 1.0, size_max = 2.0, gravity = Vector2.ZERO, add = true})
	queue_redraw()


func _on_world(_b: Node) -> void:
	if _stuck >= 0.0:
		return
	_stick()


## 지형에 박힘: 판정 끄고 잠깐 꽂혀 떨림
func _stick() -> void:
	active = false
	_stuck = 0.0
	set_deferred("monitoring", false)
	Ch3Sfx.play(&"arrow_hit", -8.0, 0.1)
	Fx.burst(global_position, 5, {spread = 70.0, direction = -_vel.normalized(), speed_min = 20.0, speed_max = 60.0, lifetime = 0.25,
		gradient = Palette.fade_gradient(Color("#c8b890")), size_min = 1.0, size_max = 2.0})
	if style == "wind":
		_gust(global_position)


func _on_player(p: Node) -> void:
	if push > 0.0 and p is Player:
		var pl := p as Player
		pl.velocity = Vector2(signf(_vel.x) * push, -minf(push * 0.45, 220.0))
	if style == "wind":
		_gust(global_position)
	Ch3Sfx.play(&"arrow_hit", -4.0, 0.1)
	queue_free()


## 바람 화살이 터질 때: 연둣빛 고리
func _gust(at: Vector2) -> void:
	Ch3Sfx.play(&"wind", -4.0, 0.1)
	Fx.ring(at, 4.0, 40.0, WIND, 0.35, 2.0)
	Fx.burst(at, 14, {spread = 180.0, speed_min = 40.0, speed_max = 120.0, lifetime = 0.4,
		gradient = Palette.fade_gradient(WIND), size_min = 1.0, size_max = 2.0, gravity = Vector2.ZERO, add = true})


## 불꽃 방벽으로 되쏘임 → 세라의 공격(불붙은 화살)으로 바뀜
func reflect(p_dir: Vector2, p_damage: int) -> void:
	if reflected or _stuck >= 0.0:
		return
	reflected = true
	active = false
	damage = p_damage
	dir = p_dir.normalized() if p_dir != Vector2.ZERO else -dir
	_vel = dir * speed * 1.15
	grav = 0.0
	life = 2.0
	collision_layer = GameConst.L_PLAYER_ATTACK
	collision_mask = GameConst.L_WORLD | GameConst.L_ENEMY_HURT
	remove_from_group(&"enemy_attack")
	remove_from_group(&"enemy_projectile")
	material = Fx.add_material
	Ch3Sfx.play(&"arrow_shot", -2.0, 0.1)
	if Sfx.has_sound(&"reflect"):
		Sfx.play(&"reflect", -2.0)
	Fx.ring(global_position, 3.0, 22.0, Palette.FIRE_HOT, 0.25, 2.0)


func _on_area(a: Area2D) -> void:
	if not reflected:
		return
	var target := a.get_parent()
	if target and target.has_method("take_hit") and target.is_alive() and not _hit_once.has(target.get_instance_id()):
		_hit_once[target.get_instance_id()] = true
		var h := Hit.make(damage, &"reflect", global_position, 1 if _vel.x >= 0.0 else -1)
		h.knockback_t = 1.0
		h.hitstop = 0.08
		h.shake_t = 0.15
		target.take_hit(h)
		Fx.burst(global_position, 16, {spread = 180.0, speed_min = 60.0, speed_max = 180.0, lifetime = 0.35})
		queue_free()


func _draw() -> void:
	var a := 1.0
	if _stuck >= 0.0:
		a = clampf((1.6 - _stuck) / 0.4, 0.0, 1.0)
		var wob := sin(_stuck * 50.0) * maxf(0.3 - _stuck, 0.0) * 6.0
		draw_set_transform(Vector2.ZERO, wob * 0.05, Vector2.ONE)
	# 꼬리 (지나온 자리)
	if _stuck < 0.0:
		var prev := Vector2.ZERO
		for i in _trail.size():
			var p := to_local(_trail[i])
			var k := 1.0 - float(i) / _trail.size()
			var tc := WIND if style == "wind" else (Palette.FIRE_OUT if reflected else Color(1, 1, 1))
			draw_line(prev, p, Color(tc, 0.35 * k), 2.0 * k + 0.5)
			prev = p
	var shaft := Palette.FIRE_HOT if reflected else SHAFT
	if style == "wind":
		draw_line(Vector2(-12, 0), Vector2(6, 0), Color(WIND, 0.4 * a), 5.0)
		draw_line(Vector2(-12, 0), Vector2(6, 0), Color(WIND, a), 1.5)
		for i in 3:
			var ph := fmod(_t * 4.0 + i * 0.33, 1.0)
			var x := lerpf(4.0, -14.0, ph)
			draw_arc(Vector2(x, 0), 3.0 + ph * 3.0, -1.2, 1.2, 6, Color(WIND, 0.6 * (1.0 - ph) * a), 1.0)
	else:
		draw_line(Vector2(-11, 0), Vector2(5, 0), Color(shaft, a), 1.0)
	# 깃
	var fc := Palette.FIRE_MID if reflected else FLETCH
	draw_line(Vector2(-11, 0), Vector2(-8, -2), Color(fc, a), 1.0)
	draw_line(Vector2(-11, 0), Vector2(-8, 2), Color(fc, a * 0.85), 1.0)
	draw_line(Vector2(-9, 0), Vector2(-6, -2), Color(fc, a * 0.7), 1.0)
	# 촉
	var tip := Color("#d8e0e8") if style != "wind" else Color(0.95, 1.0, 0.9)
	if reflected:
		tip = Palette.FIRE_CORE
		draw_circle(Vector2(5, 0), 4.0, Color(Palette.FIRE_OUT, 0.5))
	draw_colored_polygon(PackedVector2Array([Vector2(8, 0), Vector2(4, -2), Vector2(4, 2)]), Color(tip, a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
