class_name GameCamera
extends Camera2D
## 세라를 따라가는 카메라 (docs/prototype.md 5.9절, v0.3 조정).
## 바라보는 방향 + 달리는 속도만큼 앞을 더 보여 주고(시선 앞당김), 흔들림은 offset, 큰 타격은 순간 확대(punch).

var tuning: Tuning
var _look := 0.0
var _shake_amp := 0.0
var _shake_time := 0.0
var _shake_left := 0.0
var _punch := 0.0
var pan_offset := Vector2.ZERO ## 컷신 카메라 이동 (세라 기준)
var _pan_tween: Tween


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 9.0
	Fx.camera = self


func _exit_tree() -> void:
	if Fx.camera == self:
		Fx.camera = null


func _process(delta: float) -> void:
	var real := delta / maxf(Engine.time_scale, 0.0001) # 히트스톱 중에도 실제 시간으로
	var player := get_parent() as Player
	if player and tuning:
		# 빠르게 달릴수록 앞을 조금 더 보여 줌
		var speed_k := clampf(absf(player.velocity.x) / (tuning.max_speed_t * GameConst.TILE), 0.0, 1.5)
		var target := player.facing * tuning.look_ahead_t * GameConst.TILE * (0.7 + 0.3 * speed_k)
		var k := 1.0 - exp(-delta * 3.0 / maxf(tuning.look_ahead_time, 0.01))
		_look = lerpf(_look, target, k)
		position = Vector2(_look, -16) + pan_offset

	if _shake_left > 0.0:
		_shake_left -= real
		var fall := clampf(_shake_left / _shake_time, 0.0, 1.0)
		var amp := _shake_amp * fall * fall
		offset = Vector2(randf_range(-amp, amp), randf_range(-amp, amp)).round()
	else:
		offset = Vector2.ZERO

	_punch = move_toward(_punch, 0.0, real * 0.6)
	zoom = Vector2.ONE * (1.0 + _punch)


func shake(amplitude_px: float, duration: float) -> void:
	if amplitude_px >= _shake_amp * clampf(_shake_left / maxf(_shake_time, 0.001), 0.0, 1.0):
		_shake_amp = amplitude_px
		_shake_time = duration
		_shake_left = duration


func punch(amount: float) -> void:
	_punch = maxf(_punch, amount)


## 컷신: 전역 좌표 pos가 화면 가운데 오도록 이동
func pan_to(pos: Vector2, time := 0.8) -> void:
	var player := get_parent() as Node2D
	if player == null:
		return
	var want := pos - player.global_position - Vector2(_look, -16)
	if _pan_tween:
		_pan_tween.kill()
	_pan_tween = create_tween().set_ignore_time_scale(true)
	_pan_tween.tween_property(self, "pan_offset", want, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _pan_tween.finished


func pan_back(time := 0.6) -> void:
	if _pan_tween:
		_pan_tween.kill()
	_pan_tween = create_tween().set_ignore_time_scale(true)
	_pan_tween.tween_property(self, "pan_offset", Vector2.ZERO, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _pan_tween.finished
