extends EnemyBase
## 베로니카 교수 (유성 낙화 수업 3단계 — 고급반 결투장): 냉철한 고급마법반 교수의 그림자 마법 결투.
## 패턴: 그림자 걸음(순간이동) → 그림자 구슬 3발(방벽으로 되쏠 수 있음) / 바닥 가시(붉은 선 예고) /
##       흑염 고리(1.2초 모은 뒤 사방 12발). 체력 절반 아래: 검은 손이 세라 쪽으로 차례로 솟음.
## 쓰러뜨리면(체력 0) 죽지 않고 무릎 — defeated 신호로 대본이 이어 받는다.

enum S { IDLE, STEP, ORBS, SPIKES, RING, HANDS, REST }

var state: S = S.IDLE
var _timer := 0.0
var _phase := 1
var _cycle := 0
var _visual_body: CharacterVisual
var _flip: Node2D
var _aura := 0.0
var _spike_x := 0.0


func _build() -> void:
	max_hp = 2500
	body_size = Vector2(16, 36)
	knock_mult = 0.2
	launch_mult = 0.0
	is_boss = true
	display_name = "베로니카 손 교수"
	subtitle = "고급마법반 — 그림자의 시험"
	kind_id = "veronica_duel"
	respawns = true
	_flip = Node2D.new()
	add_child(_flip)
	_visual_body = CharacterVisual.new()
	_visual_body.setup("veronica")
	_flip.add_child(_visual_body)
	_visual = _flip
	_go(S.IDLE, 1.0)


func _go(s: S, t: float) -> void:
	state = s
	_timer = t


func _ai(delta: float) -> void:
	_aura += delta
	_flip.scale.x = facing
	_visual_body.modulate = Color(2, 2, 2) if flash_amount() > 0.0 else Color.WHITE
	velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
	if not engaged:
		return
	if _phase == 1 and hp < max_hp * 0.5:
		_phase = 2
		phase_changed.emit(2)
		Sfx.play(&"roar", -6.0, 0.0)
	_timer -= delta
	face_player()
	if _timer > 0.0:
		return
	match state:
		S.IDLE, S.REST:
			_cycle += 1
			_shadow_step()
			_go(S.STEP, 0.35)
		S.STEP:
			var pick := _cycle % (4 if _phase == 2 else 3)
			match pick:
				0:
					_go(S.ORBS, Difficulty.telegraph(0.5))
				1:
					_go(S.SPIKES, Difficulty.telegraph(0.7))
					_spike_x = player().global_position.x if player() else global_position.x
				2:
					_go(S.RING, Difficulty.telegraph(1.2))
				3:
					_go(S.HANDS, Difficulty.telegraph(0.6))
		S.ORBS:
			_cast_orbs()
			_go(S.REST, Difficulty.rest(1.0))
		S.SPIKES:
			_cast_spikes()
			_go(S.REST, Difficulty.rest(1.0))
		S.RING:
			_cast_ring()
			_go(S.REST, Difficulty.rest(1.4))
		S.HANDS:
			_cast_hands()
			_go(S.REST, Difficulty.rest(1.6))


func _shadow_step() -> void:
	var p := player()
	if p == null:
		return
	var side := -1.0 if randf() < 0.5 else 1.0
	var x := p.global_position.x + side * randf_range(6.0, 9.0) * GameConst.TILE
	Fx.burst(global_position + Vector2(0, -18), 14, {spread = 180.0, speed_min = 20.0, speed_max = 80.0, lifetime = 0.4,
		gradient = Palette.fade_gradient(Color(0.45, 0.2, 0.6))})
	global_position.x = clampf(x, 3.0 * GameConst.TILE, _room_w() - 3.0 * GameConst.TILE)
	Sfx.play(&"whoosh", -6.0, 0.1)


func _room_w() -> float:
	var w := World.get_world()
	return w.room.size_px.x if w and w.room else 640.0


func _cast_orbs() -> void:
	var p := player()
	if p == null:
		return
	var base := (p.center() - (global_position + Vector2(0, -22))).angle()
	for i in 3:
		var a := base + (i - 1) * 0.22
		shoot(global_position + Vector2(facing * 8, -22), Vector2.from_angle(a), 150.0, "dark", {"radius": 5.0})
	Sfx.play(&"shoot", -4.0, 0.1)


func _cast_spikes() -> void:
	var sp := ShadowSpikes.new()
	sp.global_position = Vector2(_spike_x, global_position.y)
	Fx.effect_parent().add_child(sp)


func _cast_ring() -> void:
	for i in 12:
		var a := TAU * i / 12.0 + _aura
		shoot(global_position + Vector2(0, -20), Vector2.from_angle(a), 120.0, "dark", {"radius": 4.0, "life": 3.5})
	Fx.ring(global_position + Vector2(0, -20), 6.0, 50.0, Color(0.6, 0.3, 0.9), 0.4, 3.0)
	Sfx.play(&"blast", -6.0, 0.0)
	Fx.shake(0.2)


func _cast_hands() -> void:
	var p := player()
	if p == null:
		return
	var dir := signf(p.global_position.x - global_position.x)
	for i in 5:
		var h := ShadowSpikes.new()
		h.global_position = Vector2(global_position.x + dir * (3 + i * 2.5) * GameConst.TILE, global_position.y)
		h.delay = Difficulty.telegraph(0.45) + i * 0.18
		h.hand = true
		Fx.effect_parent().add_child(h)


func _draw() -> void:
	# 모으는 동안 손끝에 그림자 구체
	if state in [S.ORBS, S.RING, S.HANDS, S.SPIKES] and _timer > 0.0:
		var k := 1.0 - clampf(_timer / 1.2, 0.0, 1.0)
		var c := Vector2(facing * 8, -24)
		draw_circle(c, 4.0 + k * 8.0, Color(0.45, 0.2, 0.7, 0.45))
		draw_circle(c, 2.0 + k * 3.0, Color(0.9, 0.7, 1.0, 0.8))
	if state == S.SPIKES and _timer > 0.0:
		var lx := to_local(Vector2(_spike_x, global_position.y)).x
		draw_rect(Rect2(lx - 20, -2, 40, 2), Color(1.0, 0.25, 0.2, 0.5 + 0.5 * sin(_aura * 20.0)))


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	queue_redraw()


## 바닥 가시 / 검은 손: 붉은 예고 뒤 솟아 세라를 맞힘


## 체력 0: 죽지 않고 무릎 꿇음 — 영혼 폭발 대신 조용히 사라지고 대본이 같은 자리에 인물을 세운다
func _die(_dir: int) -> void:
	_defeat_quiet("", false, false, 0.0) # 결투: 처치 표시·통계·등급을 남기지 않는다 (예전 동작 그대로)
	for pr in get_tree().get_nodes_in_group(&"enemy_projectile"):
		if pr.has_method("pop"):
			pr.pop(true)
	Fx.hitstop(0.12)
	Fx.ring(global_position + Vector2(0, -18), 6.0, 60.0, Color(0.7, 0.45, 1.0), 0.5, 3.0)
	Sfx.play(&"enemy_die", -4.0, 0.0)
	var t := create_tween()
	t.tween_property(_visual, "modulate:a", 0.0, 0.35)
	t.tween_callback(queue_free)


class ShadowSpikes extends TelegraphHazard:
	var hand := false

	func _init() -> void:
		delay = 0.55

	func _ready() -> void:
		z_index = 3
		hit_time = 0.35
		life = 0.6
		area = EnemyAttackArea.with_rect(Vector2(36 if not hand else 18, 36), Vector2(0, -18))
		area.active = false
		area.cause = &"veronica"
		add_child(area)

	func _on_fire() -> void:
		Sfx.play(&"slam", -8.0, 0.1)
		Fx.burst(global_position, 10, {direction = Vector2.UP, spread = 30.0, speed_min = 60.0, speed_max = 140.0, lifetime = 0.35,
			gradient = Palette.fade_gradient(Color(0.5, 0.25, 0.75))})

	func _draw() -> void:
		var w := 36.0 if not hand else 18.0
		if _t < delay:
			var a := 0.4 + 0.5 * sin(_t * 24.0)
			draw_rect(Rect2(-w * 0.5, -2, w, 2), Color(1.0, 0.25, 0.2, a))
			return
		var k := clampf((_t - delay) / 0.12, 0.0, 1.0) * clampf((delay + 0.6 - _t) / 0.25, 0.0, 1.0)
		var col := Color(0.25, 0.1, 0.35)
		if hand:
			draw_colored_polygon(PackedVector2Array([Vector2(-6, 0), Vector2(-7, -26 * k), Vector2(-2, -34 * k), Vector2(3, -30 * k), Vector2(7, -22 * k), Vector2(6, 0)]), col)
		else:
			for i in 5:
				var x := -w * 0.5 + i * w / 4.0
				draw_colored_polygon(PackedVector2Array([Vector2(x - 4, 0), Vector2(x, -30 * k * (0.7 + 0.3 * float(i % 2))), Vector2(x + 4, 0)]), col)
