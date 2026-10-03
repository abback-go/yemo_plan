class_name Player
extends CharacterBody2D
## 세라 — 1단계: 이동, 가변 점프, 대시.
## 원점(0, 0)은 발밑. 그래서 늘림·찌그러짐 연출이 발을 기준으로 일어난다.

enum State { IDLE, RUN, JUMP, FALL, DASH }

@export var tuning: PlayerTuning

var state: State = State.IDLE
var facing := 1 ## 1 = 오른쪽, -1 = 왼쪽
var is_invincible := false ## 대시 무적. 피격 판정이 생기는 단계부터 사용
var last_jump_height_t := 0.0 ## 직전 점프의 실제 높이 (T). 디버그 표시용

# 남은 시간을 초 단위로 세는 타이머들 (매 프레임 delta만큼 줄어듦)
var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _dash_timer := 0.0
var _dash_cooldown_timer := 0.0
var _invincible_timer := 0.0
var _afterimage_timer := 0.0

var air_dashes_left := 0 ## 남은 공중 대시 횟수
var _dash_dir := 1
var _was_on_floor := false
var _squash_tween: Tween
var _jump_start_y := 0.0
var _jump_peak_y := 0.0

# tuning(T 단위)에서 계산한 실제 물리 값(px 단위)
var _max_speed := 0.0
var _accel := 0.0
var _decel := 0.0
var _gravity := 0.0
var _jump_velocity := 0.0
var _jump_cut_velocity := 0.0
var _max_fall_speed := 0.0
var _dash_speed := 0.0

@onready var _visual: Node2D = $Visual
@onready var _flip: Node2D = $Visual/Flip
@onready var _body: ColorRect = $Visual/Flip/Body


func _ready() -> void:
	recalculate()


## tuning 값을 픽셀 단위 물리 값으로 바꾼다. 수치를 바꾼 뒤 다시 호출하면 즉시 반영된다.
func recalculate() -> void:
	var t := GameConst.TILE
	_max_speed = tuning.max_speed_t * t
	_accel = _max_speed / tuning.accel_time
	_decel = _max_speed / tuning.decel_time

	# 점프 공식: 높이 h를 시간 t_apex 만에 오르려면
	#   중력 g = 2h / t_apex²,  점프 초속 v = 2h / t_apex
	var h_max := tuning.jump_height_max_t * t
	_gravity = 2.0 * h_max / pow(tuning.time_to_apex, 2)
	_jump_velocity = -2.0 * h_max / tuning.time_to_apex # 화면 위쪽이 -y
	# 낮은 점프: 버튼을 떼는 순간 속도를 이 값으로 줄이면 남은 상승 높이가 최소 높이가 된다
	_jump_cut_velocity = -sqrt(2.0 * _gravity * tuning.jump_height_min_t * t)

	_max_fall_speed = tuning.max_fall_speed_t * t
	_dash_speed = tuning.dash_distance_t * t / tuning.dash_duration


func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	var input_x := Input.get_axis("move_left", "move_right")

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = tuning.jump_buffer_time
	if Input.is_action_just_pressed("dash") and _can_dash():
		_start_dash(input_x)

	if state == State.DASH:
		_process_dash(delta)
	else:
		if input_x != 0.0:
			facing = 1 if input_x > 0.0 else -1
		_process_run(input_x, delta)
		_process_jump()
		_apply_gravity(delta)

	move_and_slide()
	_after_move()
	_update_state()
	_update_visual()


func _tick_timers(delta: float) -> void:
	_coyote_timer -= delta
	_jump_buffer_timer -= delta
	_dash_cooldown_timer -= delta
	_invincible_timer -= delta
	is_invincible = _invincible_timer > 0.0


# ─── 이동 ───────────────────────────────────────────────

func _process_run(input_x: float, delta: float) -> void:
	# 목표 속도를 향해 가속도만큼 다가간다. 입력이 없으면 감속도로 멈춘다.
	var target := input_x * _max_speed
	var rate := _accel if input_x != 0.0 else _decel
	velocity.x = move_toward(velocity.x, target, rate * delta)


# ─── 점프 ───────────────────────────────────────────────

func _process_jump() -> void:
	# 점프 버퍼(최근에 눌렀음) + 코요테 타임(최근까지 땅에 있었음)이 둘 다 살아 있으면 점프
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = _jump_velocity
		_jump_start_y = position.y
		_jump_peak_y = position.y
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		_squash(Vector2(0.8, 1.2)) # 위로 늘어남
		# 버퍼로 실행된 점프인데 이미 버튼을 뗐다면 바로 낮은 점프로
		if not Input.is_action_pressed("jump"):
			velocity.y = maxf(velocity.y, _jump_cut_velocity)

	# 상승 중 버튼을 떼면 상승 속도를 잘라 낮은 점프
	if Input.is_action_just_released("jump") and velocity.y < _jump_cut_velocity:
		velocity.y = _jump_cut_velocity


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	var g := _gravity
	if velocity.y > 0.0:
		g *= tuning.fall_gravity_multiplier
	velocity.y = minf(velocity.y + g * delta, _max_fall_speed)


# ─── 대시 ───────────────────────────────────────────────

func _can_dash() -> bool:
	if state == State.DASH or _dash_cooldown_timer > 0.0:
		return false
	return is_on_floor() or air_dashes_left > 0


func _start_dash(input_x: float) -> void:
	if not is_on_floor():
		air_dashes_left -= 1
	# 방향 입력이 있으면 그쪽, 없으면 바라보는 쪽으로
	if input_x != 0.0:
		_dash_dir = 1 if input_x > 0.0 else -1
	else:
		_dash_dir = facing
	facing = _dash_dir
	_dash_timer = tuning.dash_duration
	_invincible_timer = tuning.dash_invincible_time
	is_invincible = true
	_afterimage_timer = 0.0
	state = State.DASH


func _process_dash(delta: float) -> void:
	_dash_timer -= delta
	if _dash_timer <= 0.0:
		_end_dash()
		return
	# 대시 중에는 중력을 무시하고 수평으로 일정 속도
	velocity = Vector2(_dash_dir * _dash_speed, 0.0)
	_afterimage_timer -= delta
	if _afterimage_timer <= 0.0:
		_spawn_afterimage()
		_afterimage_timer = tuning.dash_duration / 3.0 # 대시 1회에 잔상 약 3개


func _end_dash() -> void:
	state = State.FALL # 바로 아래 _update_state()에서 실제 상태로 다시 정해진다
	_dash_cooldown_timer = tuning.dash_cooldown
	# 대시 속도에서 최고 이동 속도로 낮춰 자연스럽게 이어 달리기
	velocity.x = _dash_dir * _max_speed


# ─── 이동 후 처리 ───────────────────────────────────────

func _after_move() -> void:
	var on_floor := is_on_floor()
	_jump_peak_y = minf(_jump_peak_y, position.y)
	if on_floor:
		_coyote_timer = tuning.coyote_time
		air_dashes_left = tuning.air_dash_count
		if not _was_on_floor:
			_squash(Vector2(1.25, 0.75)) # 착지: 옆으로 퍼짐
			last_jump_height_t = (_jump_start_y - _jump_peak_y) / GameConst.TILE
			_jump_start_y = position.y
			_jump_peak_y = position.y
	_was_on_floor = on_floor


func _update_state() -> void:
	if state == State.DASH:
		return
	if is_on_floor():
		state = State.RUN if absf(velocity.x) > 1.0 else State.IDLE
	else:
		state = State.JUMP if velocity.y < 0.0 else State.FALL


# ─── 연출 ───────────────────────────────────────────────

func _update_visual() -> void:
	_flip.scale.x = facing
	# 무적 중에는 밝게 (나중에 외곽선 연출로 교체)
	_visual.modulate = Color(1.8, 1.8, 1.8) if is_invincible else Color.WHITE


## 늘림·찌그러짐: 순간적으로 비율을 바꾼 뒤 0.12초에 걸쳐 원래대로
func _squash(amount: Vector2) -> void:
	if _squash_tween:
		_squash_tween.kill()
	_visual.scale = amount
	_squash_tween = create_tween()
	_squash_tween.tween_property(_visual, "scale", Vector2.ONE, 0.12) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## 대시 잔상: 몸통 사각형을 복제해 그 자리에 두고 서서히 사라지게 한다
func _spawn_afterimage() -> void:
	var ghost := ColorRect.new()
	ghost.size = _body.size
	ghost.color = Color(_body.color, 0.5)
	get_parent().add_child(ghost)
	ghost.global_position = _body.global_position
	if facing < 0:
		ghost.global_position.x -= _body.size.x # 좌우 반전된 몸통의 실제 왼쪽 위 좌표
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.2)
	tween.tween_callback(ghost.queue_free)
