extends EnemyBase
## 불 속의 나 (불사조 수업 4단계): 세라 자신의 그림자. "폐급"이라는 말을 먹고 자란 두려움.
## 세라처럼 움직인다: 검은 화염탄(1.5초마다 묵직한 한 발 — 방벽으로 되쏘기 가능), 대시로 거리 좁히기·벌리기,
## 세라 발밑 검은 불기둥(예고), 가까우면 검은 화염 폭풍. 체력 절반 아래: 검은 폭주(넓은 폭발, 0.9초 예고).
## 체력 0 → 무릎 꿇고 빛으로 바뀜 (defeated → 대본).

enum S { IDLE, SHOOT, DASH, PILLAR, STORM, BURST, REST }

var state: S = S.IDLE
var _timer := 0.0
var _phase := 1
var _cycle := 0
var _body: PlayerVisual
var _flip: Node2D
var _t2 := 0.0
var _pillar_x := 0.0
var _burst_r := 0.0
var _burst_area: EnemyAttackArea
var _contact: EnemyAttackArea


func _build() -> void:
	max_hp = 3000
	body_size = Vector2(12, 30)
	knock_mult = 0.4
	launch_mult = 0.3
	is_boss = true
	display_name = "불 속의 나"
	subtitle = "폐급이라는 그림자"
	kind_id = "shadow_sera"
	respawns = true
	_flip = Node2D.new()
	add_child(_flip)
	_body = PlayerVisual.new()
	_body.ghost = true
	_body.ghost_color = Color(0.12, 0.06, 0.16, 0.95)
	_flip.add_child(_body)
	_visual = _flip
	_contact = add_attack_area(Vector2(12, 26), Vector2(0, -14), &"shadow")
	_burst_area = add_attack_area(Vector2(150, 110), Vector2(0, -30), &"shadow")
	_burst_area.active = false
	_go(S.IDLE, 1.2)


func _go(s: S, t: float) -> void:
	state = s
	_timer = t


func _ai(delta: float) -> void:
	_t2 += delta
	_flip.scale.x = facing
	_body.update_pose(delta)
	_body.speed_x = absf(velocity.x)
	_body.modulate = Color(3, 3, 3) if flash_amount() > 0.0 else Color.WHITE
	if not engaged:
		velocity.x = 0.0
		return
	if _phase == 1 and hp < max_hp * 0.5:
		_phase = 2
		phase_changed.emit(2)
	_timer -= delta
	var p := player()
	if p == null:
		return
	if state != S.DASH:
		face_player()
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	else:
		velocity.x = facing * 340.0
	if _timer > 0.0:
		return
	var d := dist_to_player()
	match state:
		S.IDLE, S.REST:
			_cycle += 1
			if _phase == 2 and _cycle % 5 == 0:
				_go(S.BURST, Difficulty.telegraph(0.9))
				Sfx.play(&"overload_warn", -2.0, 0.0)
			elif d < 4.0 * GameConst.TILE:
				_go(S.STORM, Difficulty.telegraph(0.45))
			elif _cycle % 3 == 0:
				_pillar_x = p.global_position.x
				_go(S.PILLAR, Difficulty.telegraph(0.55))
			elif d > 12.0 * GameConst.TILE or randf() < 0.3:
				_go(S.DASH, 0.18)
				Sfx.play(&"dash", -6.0, 0.1)
			else:
				_go(S.SHOOT, Difficulty.telegraph(0.35))
		S.SHOOT:
			shoot(global_position + Vector2(facing * 10, -18), Vector2(facing, 0), 230.0, "dark", {"radius": 6.0})
			Sfx.play(&"shoot_heavy", -6.0, 0.1)
			_go(S.REST, Difficulty.rest(1.1))
		S.DASH:
			velocity.x = 0.0
			_go(S.SHOOT, Difficulty.telegraph(0.3))
		S.PILLAR:
			var sp := _ShadowPillar.new()
			sp.global_position = Vector2(_pillar_x, global_position.y)
			Fx.effect_parent().add_child(sp)
			_go(S.REST, Difficulty.rest(0.9))
		S.STORM:
			for i in 5:
				var a := -0.5 + i * 0.25
				shoot(global_position + Vector2(facing * 6, -16), Vector2(facing * cos(a), sin(a)), 170.0, "dark", {"radius": 4.0, "life": 0.9})
			Sfx.play(&"storm", -6.0, 0.1)
			_go(S.REST, Difficulty.rest(1.0))
		S.BURST:
			_burst_area.active = true
			Fx.ring(global_position + Vector2(0, -16), 6.0, 80.0, Color(0.5, 0.2, 0.7), 0.4, 4.0)
			Fx.shake(0.4)
			Sfx.play(&"blast", -2.0, 0.0)
			_go(S.REST, Difficulty.rest(1.6))
			get_tree().create_timer(0.2).timeout.connect(func() -> void: _burst_area.active = false)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	queue_redraw()


func _draw() -> void:
	# 붉은 눈 + 검은 불꽃 윤곽
	var eye := Vector2(facing * 3, -25)
	draw_rect(Rect2(eye, Vector2(2, 2)), Color(1.0, 0.2, 0.25))
	for i in 4:
		var a := _t2 * 4.0 + TAU * i / 4.0
		draw_circle(Vector2(cos(a) * 7.0, -16 + sin(a) * 10.0), 2.0, Color(0.4, 0.15, 0.55, 0.5))
	if state == S.BURST and _timer > 0.0:
		var k := 1.0 - _timer / 0.9
		draw_arc(Vector2(0, -16), 75.0 * k, 0.0, TAU, 32, Color(1.0, 0.2, 0.25, 0.6), 2.0)
	if state == S.PILLAR and _timer > 0.0:
		var lx := to_local(Vector2(_pillar_x, global_position.y)).x
		draw_rect(Rect2(lx - 14, -2, 28, 2), Color(1.0, 0.25, 0.2, 0.5 + 0.5 * sin(_t2 * 20.0)))


## 체력 0: 죽지 않고 무릎 꿇음 — 영혼 폭발 대신 조용히 사라지고 대본이 같은 자리에 인물을 세운다
func _die(_dir: int) -> void:
	_alive = false
	defeated.emit(self)
	collision_layer = 0
	_hurtbox.set_deferred("monitorable", false)
	for c2 in get_children():
		if c2 is EnemyAttackArea:
			c2.active = false
	for pr in get_tree().get_nodes_in_group(&"enemy_projectile"):
		if pr.has_method("pop"):
			pr.pop(true)
	Fx.hitstop(0.12)
	Fx.ring(global_position + Vector2(0, -18), 6.0, 60.0, Color(1.0, 0.85, 0.6), 0.5, 3.0)
	Sfx.play(&"enemy_die", -4.0, 0.0)
	var t := create_tween()
	t.tween_property(_visual, "modulate:a", 0.0, 0.35)
	t.tween_callback(queue_free)


class _ShadowPillar extends Node2D:
	var _t := 0.0
	var _area: EnemyAttackArea

	func _ready() -> void:
		z_index = 3
		_area = EnemyAttackArea.with_rect(Vector2(24, 90), Vector2(0, -45))
		_area.cause = &"shadow"
		add_child(_area)
		Sfx.play(&"pillar", -6.0, 0.1)
		Fx.burst(global_position, 16, {direction = Vector2.UP, spread = 20.0, speed_min = 100.0, speed_max = 240.0, lifetime = 0.5,
			gradient = Palette.fade_gradient(Color(0.45, 0.2, 0.65))})

	func _physics_process(delta: float) -> void:
		_t += delta
		if _t > 0.3:
			_area.active = false
		if _t > 0.5:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k := clampf(1.0 - _t / 0.5, 0.0, 1.0)
		draw_rect(Rect2(-10, -90 * minf(_t / 0.08, 1.0), 20, 90 * minf(_t / 0.08, 1.0)), Color(0.2, 0.08, 0.3, 0.85 * k))
		draw_rect(Rect2(-4, -90 * minf(_t / 0.08, 1.0), 8, 90 * minf(_t / 0.08, 1.0)), Color(0.6, 0.3, 0.85, 0.7 * k))
