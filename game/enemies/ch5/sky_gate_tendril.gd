extends EnemyBase
## 고리 옆에서 뻗는 촉수 (들어 올림 → 내리침, 잘리면 움츠림)
## 하늘 문(sky_gate.gd)의 촉수 하나.

const T := GameConst.TILE

var gate: Node
var index := 0
var side := 1.0
var state := "idle"
var out := 1.0 ## 0 = 움츠림, 1 = 뻗음
var _timer := 3.0
var _retract_t := 0.0
var _target := Vector2.ZERO
var _slam: EnemyAttackArea


func _build() -> void:
	max_hp = 700
	body_size = Vector2(26, 26)
	display_name = ""
	kind_id = "sky_gate_tendril"
	is_elite = true
	flying = true
	knock_mult = 0.0
	launch_mult = 0.0
	collision_mask = 0
	engaged = false
	_timer = 3.0 + index * 1.3
	_slam = add_attack_area(Vector2(3.5 * T, 2.0 * T), Vector2.ZERO, &"sky_gate", 1)
	_slam.active = false


func is_out() -> bool:
	return out > 0.5 and state != "retracted"


func danger() -> float:
	return 2.0 if state == "raise" else (1.0 if state == "idle" else 0.0)


## 촉수 끝 (전역)
func tip() -> Vector2:
	var base := global_position
	match state:
		"raise":
			return base + Vector2(-side * 70.0, -90.0).lerp(Vector2(-side * 60.0, -110.0), 0.5)
		"slam", "rest":
			return _target
	var t := _t
	return base + Vector2(-side * (60.0 + sin(t * 1.3 + index) * 12.0), 40.0 + cos(t * 1.1 + index) * 16.0) * out


func retract(sec: float) -> void:
	state = "retracted"
	_retract_t = sec
	_slam.active = false
	_hurtbox.set_deferred("monitorable", false)


func _ai(delta: float) -> void:
	velocity = Vector2.ZERO
	if not engaged:
		return
	var frozen := gate != null and float(gate.frost_t) > 0.0
	var p := player()
	match state:
		"retracted":
			out = move_toward(out, 0.0, delta * 3.0)
			_retract_t -= delta
			if _retract_t <= 0.0:
				state = "idle"
				hp = max_hp
				_hurtbox.set_deferred("monitorable", true)
				_timer = 2.0
		"idle":
			out = move_toward(out, 1.0, delta * 1.5)
			if not frozen:
				_timer -= delta
			if _timer <= 0.0 and p and p.is_alive() and out > 0.9:
				state = "raise"
				_timer = Difficulty.telegraph(1.1)
				var gy := _ground(p.global_position.x, p.global_position.y - 3.0 * T)
				_target = Vector2(p.global_position.x, gy)
				StStrike.spawn(_target + Vector2(0, -T), "band", Vector2(3.5 * T, 2.0 * T), _timer, {"style": "white", "damage": 0, "hold": 0.0, "fade": 0.05})
				if gate:
					gate._need("tendril", _target)
		"raise":
			if not frozen:
				_timer -= delta
			if _timer <= 0.0:
				state = "slam"
				_timer = 0.12
		"slam":
			_timer -= delta
			if _timer <= 0.0:
				_slam.global_position = _target + Vector2(0, -T)
				_slam.active = true
				Fx.shake(0.35, 0.25)
				StArt.sfx(&"slam", &"slam", 0.0)
				Fx.burst(_target, 14, {direction = Vector2.UP, spread = 70.0, speed_min = 40.0, speed_max = 150.0, lifetime = 0.5,
					gradient = Palette.fade_gradient(StArt.GOD_WHITE), add = false})
				state = "rest"
				_timer = 0.7
		"rest":
			_timer -= delta
			if _timer < 0.55:
				_slam.active = false
			if _timer <= 0.0:
				state = "idle"
				_timer = Difficulty.rest(randf_range(3.0, 4.5))


func _ground(x: float, from_y: float) -> float:
	return floor_y_at(x, from_y, from_y + 20.0 * T, from_y + 4.0 * T)


func _die(_dir: int) -> void:
	retract(10.0)
	Fx.burst(tip(), 20, {spread = 180.0, speed_min = 40.0, speed_max = 140.0, lifetime = 0.6, gradient = Palette.fade_gradient(StArt.GOD_WHITE), add = false})


func take_hit(hit: Hit) -> void:
	if state == "retracted":
		return
	super.take_hit(hit)
