class_name Player
extends CharacterBody2D
## 종언의 마녀 (임시 도형). 이동 · 가변 점프 · 땅 위 3연격 · 공중 2연격.
## 원점 = 발. 수치는 Tuning (docs/gdd/05-mechanics.md).

enum Act { NONE, WINDUP, SWING, RECOVER }

const SIZE := Vector2(12, 26)
const BODY_COLOR := Color(0.36, 0.16, 0.24)
const HAT_COLOR := Color(0.12, 0.08, 0.12)
const BLADE_COLOR := Color(0.85, 0.85, 0.92)

signal swung(fx_data: Dictionary)

var facing := 1
var act := Act.NONE
var act_t := 0.0
var swing: Dictionary = {}
var combo_i := 0
var air_n := 0
var combo_gap_t := 0.0
var attack_buf := 0.0
var jump_buf := 0.0
var coyote := 0.0
var jump_cut_done := true
var hit_done := false
var lunge_v := 0.0
var spawn := Vector2.ZERO
var _g_up := 0.0
var _jump_v := 0.0


func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = SIZE
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(0, -SIZE.y * 0.5)
	add_child(col)
	collision_layer = 2
	collision_mask = 1
	_g_up = 2.0 * Tuning.JUMP_HEIGHT / (Tuning.JUMP_APEX_TIME * Tuning.JUMP_APEX_TIME)
	_jump_v = 2.0 * Tuning.JUMP_HEIGHT / Tuning.JUMP_APEX_TIME
	spawn = global_position


func center() -> Vector2:
	return global_position + Vector2(0, -SIZE.y * 0.5)


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("reset"):
		global_position = spawn
		velocity = Vector2.ZERO
		_end_attack()
	var dir := Input.get_axis("move_left", "move_right")

	jump_buf = maxf(jump_buf - delta, 0.0)
	attack_buf = maxf(attack_buf - delta, 0.0)
	combo_gap_t = maxf(combo_gap_t - delta, 0.0)
	if Input.is_action_just_pressed("jump"):
		jump_buf = Tuning.JUMP_BUFFER
	if Input.is_action_just_pressed("attack"):
		attack_buf = Tuning.ATTACK_BUFFER
	if is_on_floor():
		coyote = Tuning.COYOTE_TIME
		if act == Act.NONE:
			air_n = 0
	else:
		coyote = maxf(coyote - delta, 0.0)

	_update_attack(delta, dir)
	_move_horizontal(dir, delta)
	_jump_and_gravity(delta)
	move_and_slide()
	queue_redraw()


# ═══ 이동 ═══

func _move_horizontal(dir: float, delta: float) -> void:
	if act != Act.NONE:
		if swing.get("air", false):
			# 공중 휘두름: 하던 움직임을 조금씩 잃는다
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
		else:
			# 땅 위 휘두름: 방향을 못 바꾸고, 앞으로 미끄러지는 힘만 받는다
			lunge_v = move_toward(lunge_v, 0.0, Tuning.LUNGE_DECEL * delta)
			if _blocked_ahead():
				lunge_v = 0.0
			velocity.x = lunge_v * facing
		return
	if dir != 0.0:
		facing = 1 if dir > 0.0 else -1
	var target := dir * Tuning.RUN_SPEED
	var speeding_up := absf(target) > absf(velocity.x) and signf(target) == signf(velocity.x)
	var t := Tuning.ACCEL_TIME if speeding_up or velocity.x == 0.0 else Tuning.DECEL_TIME
	var rate := Tuning.RUN_SPEED / t
	if not is_on_floor():
		rate *= Tuning.AIR_CONTROL
	velocity.x = move_toward(velocity.x, target, rate * delta)


func _jump_and_gravity(delta: float) -> void:
	var can_jump := act == Act.NONE or (act == Act.RECOVER and act_t >= Tuning.CHAIN_AFTER)
	if jump_buf > 0.0 and coyote > 0.0 and can_jump:
		_end_attack()
		velocity.y = -_jump_v
		jump_buf = 0.0
		coyote = 0.0
		jump_cut_done = false
	# 가변 점프: 오르는 중에 버튼을 떼면 한 번 끊는다
	if velocity.y < 0.0 and not jump_cut_done and not Input.is_action_pressed("jump"):
		velocity.y *= Tuning.JUMP_CUT
		jump_cut_done = true
	var g := _g_up if velocity.y < 0.0 else _g_up * Tuning.FALL_GRAVITY_MULT
	velocity.y = minf(velocity.y + g * delta, Tuning.MAX_FALL_SPEED)
	if act != Act.NONE and swing.get("air", false):
		velocity.y = minf(velocity.y, Tuning.AIR_SWING_FALL)


# ═══ 검술 ═══

func _update_attack(delta: float, dir: float) -> void:
	if act == Act.NONE:
		if attack_buf > 0.0:
			_start_swing(dir)
		return
	act_t += delta
	match act:
		Act.WINDUP:
			if act_t >= float(swing["wu"]):
				act = Act.SWING
				act_t = 0.0
				lunge_v = float(swing["lunge"]) if is_on_floor() else 0.0
				swung.emit({"swing": swing, "facing": facing, "at": center()})
		Act.SWING:
			if not hit_done and act_t >= float(swing["sw"]) * 0.5:
				hit_done = true
				_check_hits()
			if act_t >= float(swing["sw"]):
				act = Act.RECOVER
				act_t = 0.0
		Act.RECOVER:
			if attack_buf > 0.0 and act_t >= Tuning.CHAIN_AFTER and _has_next():
				_start_swing(dir)
			elif act_t >= float(swing["rec"]):
				act = Act.NONE
				combo_gap_t = Tuning.COMBO_GAP


func _has_next() -> bool:
	if is_on_floor():
		return combo_i < Tuning.COMBO.size()
	return air_n < Tuning.AIR_COMBO.size()


func _start_swing(dir: float) -> void:
	var id := ""
	if is_on_floor():
		var chaining := act == Act.RECOVER or combo_gap_t > 0.0
		if not chaining or combo_i >= Tuning.COMBO.size():
			combo_i = 0
		id = Tuning.COMBO[combo_i]
		combo_i += 1
	else:
		if air_n >= Tuning.AIR_COMBO.size():
			attack_buf = 0.0
			return
		id = Tuning.AIR_COMBO[air_n]
		air_n += 1
	attack_buf = 0.0
	combo_gap_t = 0.0
	if dir != 0.0:
		facing = 1 if dir > 0.0 else -1
	swing = Tuning.SWINGS[id]
	act = Act.WINDUP
	act_t = 0.0
	hit_done = false


func _end_attack() -> void:
	act = Act.NONE
	act_t = 0.0
	lunge_v = 0.0
	combo_i = 0
	combo_gap_t = 0.0


func _hit_rect() -> Rect2:
	var reach := float(swing["reach"])
	var h := float(swing["height"])
	var x0 := global_position.x + 2.0 if facing > 0 else global_position.x - 2.0 - reach
	return Rect2(x0, center().y - h * 0.5, reach, h)


func _check_hits() -> void:
	var r := _hit_rect()
	var any := false
	for node in get_tree().get_nodes_in_group("hittable"):
		var d := node as Dummy
		if d != null and r.intersects(d.hurt_rect()):
			d.take_hit(int(swing["dmg"]), facing, swing)
			any = true
	if any:
		var heavy: bool = swing.get("heavy", false)
		Feel.hitstop(float(swing["hs"]))
		Feel.shake(float(swing["shake"]), 0.22 if heavy else 0.14)


## 미끄러질 때 바로 앞에 표적이 있으면 멈춘다 (몸이 겹쳐 보이지 않게)
func _blocked_ahead() -> bool:
	for node in get_tree().get_nodes_in_group("hittable"):
		var d := node as Dummy
		if d == null:
			continue
		var dx := (d.global_position.x - global_position.x) * facing
		if dx > 0.0 and dx < Tuning.SPACING and absf(d.global_position.y - global_position.y) < 24.0:
			return true
	return false


# ═══ 그림 (임시 도형) ═══

func _draw() -> void:
	var w := SIZE.x
	var h := SIZE.y
	draw_rect(Rect2(-w * 0.5, -h, w, h), BODY_COLOR)
	# 마녀 모자: 챙 + 뾰족한 꼭대기 (바라보는 반대쪽으로 꺾임)
	draw_rect(Rect2(-w * 0.5 - 3.0, -h - 2.0, w + 6.0, 2.0), HAT_COLOR)
	var tip := Vector2(-4.0 * facing, -h - 14.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-w * 0.5 + 1.0, -h - 2.0), Vector2(w * 0.5 - 1.0, -h - 2.0), tip]), HAT_COLOR)
	# 눈 (바라보는 쪽)
	draw_rect(Rect2(2.0 * facing - 1.0, -h + 6.0, 2.0, 2.0), Color(0.95, 0.85, 0.6))
	# 무기: 평소엔 허리의 칼집(빗자루), 준비 동작엔 뒤로 치켜든 칼
	var hand := Vector2(3.0 * facing, -h * 0.55)
	if act == Act.WINDUP:
		draw_line(hand, hand + Vector2(-14.0 * facing, -12.0), BLADE_COLOR, 2.0)
	elif act == Act.NONE:
		draw_line(Vector2(-4.0 * facing, -10.0), Vector2(-12.0 * facing, -2.0), Color(0.3, 0.2, 0.15), 2.0)
	else:
		draw_line(hand, hand + Vector2(16.0 * facing, 6.0), BLADE_COLOR, 2.0)
