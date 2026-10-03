class_name GameCamera
extends Camera2D
## 세라를 따라가는 카메라 (docs/prototype.md 5.9절).
## 바라보는 방향으로 2T 더 앞을 보여 주고(시선 앞당김), 화면 흔들림은 offset으로 처리한다.

var tuning: Tuning
var _look := 0.0
var _shake_amp := 0.0
var _shake_time := 0.0
var _shake_left := 0.0


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 7.0
	Fx.camera = self


func _exit_tree() -> void:
	if Fx.camera == self:
		Fx.camera = null


func _process(delta: float) -> void:
	var player := get_parent() as Player
	if player and tuning:
		var target := player.facing * tuning.look_ahead_t * GameConst.TILE
		# 0.3초에 걸쳐 대부분 따라가도록 지수 감쇠
		var k := 1.0 - exp(-delta * 3.0 / maxf(tuning.look_ahead_time, 0.01))
		_look = lerpf(_look, target, k)
		position.x = _look

	if _shake_left > 0.0:
		_shake_left -= delta / maxf(Engine.time_scale, 0.0001) # 히트스톱 중에도 실제 시간으로 흔들림
		var fall := clampf(_shake_left / _shake_time, 0.0, 1.0)
		var amp := _shake_amp * fall * fall
		offset = Vector2(randf_range(-amp, amp), randf_range(-amp, amp)).round()
	else:
		offset = Vector2.ZERO


func shake(amplitude_px: float, duration: float) -> void:
	if amplitude_px >= _shake_amp * clampf(_shake_left / maxf(_shake_time, 0.001), 0.0, 1.0):
		_shake_amp = amplitude_px
		_shake_time = duration
		_shake_left = duration
