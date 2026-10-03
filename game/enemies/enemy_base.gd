class_name EnemyBase
extends CharacterBody2D
## 적 공통 기반 (docs/prototype.md 10절): 체력, 피격(흰색 깜빡임·넉백·띄우기·피해 숫자), 중력, 사망 연출.
## 원점은 발밑. 자식 클래스가 _build()에서 몸 크기를 정하고 _ai(delta)에서 행동을 결정한다.

signal defeated(enemy: EnemyBase)

const TUNING: Tuning = preload("res://core/tuning.tres")

var tuning: Tuning = TUNING
var max_hp := 50
var hp := 50
var facing := -1
var body_size := Vector2(20, 16) ## 충돌·피격 판정 크기 (px)

var _alive := true
var _flash := 0.0
var _knock_vel := 0.0
var _knock_timer := 0.0
var _airborne_spin := 0.0 ## 띄워졌을 때 회전 연출
var _t := 0.0
var _gravity := 1500.0
var _hurtbox: Area2D
var _visual: Node2D


func _ready() -> void:
	add_to_group(GameConst.GROUP_ENEMY)
	collision_layer = GameConst.L_ENEMY
	collision_mask = GameConst.L_WORLD | GameConst.L_PLATFORM
	floor_snap_length = 4.0
	_build()
	hp = max_hp

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = body_size
	col.shape = rect
	col.position = Vector2(0, -body_size.y / 2.0)
	add_child(col)

	_hurtbox = Area2D.new()
	_hurtbox.name = "Hurtbox"
	_hurtbox.collision_layer = GameConst.L_ENEMY_HURT
	_hurtbox.collision_mask = 0
	_hurtbox.monitoring = false
	var hcol := CollisionShape2D.new()
	var hrect := RectangleShape2D.new()
	hrect.size = body_size + Vector2(4, 4)
	hcol.shape = hrect
	hcol.position = Vector2(0, -body_size.y / 2.0)
	_hurtbox.add_child(hcol)
	add_child(_hurtbox)


## 자식 클래스: max_hp, body_size, 시각 노드 등을 정한다
func _build() -> void:
	pass


## 자식 클래스: 매 물리 프레임 행동 (넉백·띄우기 중엔 호출되지 않음)
func _ai(_delta: float) -> void:
	pass


func is_alive() -> bool:
	return _alive


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_t += delta
	_flash = maxf(_flash - delta, 0.0)
	if not is_on_floor():
		velocity.y = minf(velocity.y + _gravity * delta, 600.0)
	if _knock_timer > 0.0:
		_knock_timer -= delta
		velocity.x = _knock_vel * clampf(_knock_timer / 0.14, 0.0, 1.0)
	elif not is_on_floor() and _airborne_spin != 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
	else:
		_ai(delta)
	move_and_slide()
	if is_on_floor() and _airborne_spin != 0.0:
		_airborne_spin = 0.0
		_on_landed_from_launch()
	if _visual:
		_visual.queue_redraw()


func _on_landed_from_launch() -> void:
	Fx.burst(global_position, 6, {
		direction = Vector2.UP, spread = 80.0, speed_min = 20.0, speed_max = 60.0, lifetime = 0.3,
		gradient = Palette.fade_gradient(Palette.GROUND_TOP), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 80),
	})


## 넉백을 버티는가 (돌진 중인 돌진형 등)
func _resists_knockback(_hit: Hit) -> bool:
	return false


func take_hit(hit: Hit) -> void:
	if not _alive:
		return
	hp -= hit.damage
	_flash = tuning.enemy_flash_time + 0.03
	var heavy := hit.damage >= 25
	Fx.damage_number(global_position + Vector2(0, -body_size.y - 4), hit.damage, heavy)
	Fx.hitstop(hit.hitstop)
	Fx.shake(hit.shake_t)
	if hit.kind == &"bolt" or hit.kind == &"bolt_heavy":
		Sfx.play(&"hit_heavy" if heavy else &"hit", -2.0 if heavy else -4.0)
	var dir := hit.dir_from(global_position)
	_on_hit(hit, dir)
	if hit.knockback_t > 0.0 and (hit.ignores_knock_resist or not _resists_knockback(hit)):
		_knock_vel = dir * 2.0 * hit.knockback_t * GameConst.TILE / 0.14
		_knock_timer = 0.14
	if hit.launch_t > 0.0:
		velocity.y = -sqrt(2.0 * _gravity * hit.launch_t * GameConst.TILE)
		_airborne_spin = float(dir)
	if hp <= 0:
		_die(dir)


## 자식 클래스: 맞았을 때 반응 (돌진 끊기, 맞은 쪽 돌아보기 등)
func _on_hit(_hit: Hit, _dir: int) -> void:
	pass


func _die(dir: int) -> void:
	_alive = false
	GameState.add("kills")
	defeated.emit(self)
	Sfx.play(&"enemy_die")
	var c := global_position + Vector2(0, -body_size.y / 2.0)
	Fx.burst(c, 26, {
		spread = 180.0, speed_min = 40.0, speed_max = 160.0, damping = 60.0, lifetime = 0.7,
		gradient = Palette.soul_gradient(), size_min = 1.5, size_max = 3.0, gravity = Vector2(0, -40),
		direction = Vector2(dir, -0.5),
	})
	Fx.burst(c, 12, {
		spread = 180.0, speed_min = 30.0, speed_max = 90.0, lifetime = 0.5,
		size_min = 1.0, size_max = 2.5, gravity = Vector2(0, 100),
	})
	Fx.ring(c, 4.0, 22.0, Palette.ENEMY_SOUL, 0.3, 2.0)
	collision_layer = 0
	_hurtbox.set_deferred("monitorable", false)
	for c2 in get_children():
		if c2 is EnemyAttackArea:
			c2.active = false
	# 하얗게 번쩍인 뒤 위로 흩어지며 사라짐
	if _visual:
		_flash = 1.0
		var t := create_tween()
		t.tween_property(_visual, "scale", Vector2(1.3, 0.2), 0.18).set_trans(Tween.TRANS_QUAD)
		t.parallel().tween_property(_visual, "modulate:a", 0.0, 0.18)
		t.tween_callback(queue_free)
	else:
		queue_free()


## 시각 노드가 그릴 때 쓰는 흰색 깜빡임 양 (0~1)
func flash_amount() -> float:
	return 1.0 if _flash > 0.0 else 0.0


func player() -> Player:
	return get_tree().get_first_node_in_group(GameConst.GROUP_PLAYER) as Player
