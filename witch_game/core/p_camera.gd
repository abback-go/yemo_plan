class_name PCamera
extends Camera2D
## 몸을 따라가는 카메라: 바라보는 쪽을 조금 앞서 보고, 흔들림(shake) · 방향 밀림(kick) · 확대 펀치(punch)를 처리한다.
## 에스카 프로젝트(game/proto/p_arena.gd의 PCamera)에서 옮겼다.

var target: CharacterBody2D ## 세라(PSera) 또는 에스카(EEska) — facing 값을 가진 몸
var _look := 0.0
var look_y := -30.0 ## 몸보다 이만큼 위를 화면 가운데로
var zoom_extra := 0.0 ## 연출용 추가 확대 (필살기 등)
var focus_w := 0.0 ## 0 = 몸을 따라감, 1 = focus_p를 화면 가운데로
var focus_p := Vector2.ZERO
var _shake_amp := 0.0
var _shake_left := 0.0
var _shake_time := 0.0
var _punch := 0.0
var _kick := Vector2.ZERO ## 타격 방향으로 밀렸다가 용수철처럼 돌아오는 화면
var _kick_v := Vector2.ZERO

func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 8.0
	Fx.camera = self
	make_current()

func _exit_tree() -> void:
	if Fx.camera == self:
		Fx.camera = null

func _process(delta: float) -> void:
	var real := delta / maxf(Engine.time_scale, 0.0001)
	if is_instance_valid(target):
		var want := float(target.get("facing")) * 46.0 * clampf(absf(target.velocity.x) / 150.0, 0.3, 1.0)
		_look = lerpf(_look, want, 1.0 - exp(-real * 2.5))
		global_position = (target.global_position + Vector2(_look, look_y)).lerp(focus_p, focus_w)
	# 멈춤(hitstop)으로 time_scale이 0에 가까우면 real이 튀므로 한 프레임 길이로 자름 (용수철이 폭주하지 않게)
	var kd := minf(real, 1.0 / 30.0)
	_kick_v += (-_kick * 900.0 - _kick_v * 34.0) * kd
	_kick += _kick_v * kd
	if _shake_left > 0.0:
		_shake_left -= real
		var fall := clampf(_shake_left / _shake_time, 0.0, 1.0)
		var amp := _shake_amp * fall * fall
		offset = (Vector2(randf_range(-amp, amp), randf_range(-amp, amp)) + _kick).round()
	else:
		offset = _kick.round()
	_punch = move_toward(_punch, 0.0, real * 0.6)
	zoom = Vector2.ONE * (1.0 + _punch + zoom_extra)

func shake(amplitude_px: float, duration: float) -> void:
	if amplitude_px >= _shake_amp * clampf(_shake_left / maxf(_shake_time, 0.001), 0.0, 1.0):
		_shake_amp = amplitude_px
		_shake_time = duration
		_shake_left = duration

## 화면을 v 방향으로 순간 밀었다가 되돌림 (던진·맞은 방향의 손맛)
func kick(v: Vector2) -> void:
	_kick = v
	_kick_v = v * 18.0

func punch(amount: float) -> void:
	_punch = maxf(_punch, amount)
