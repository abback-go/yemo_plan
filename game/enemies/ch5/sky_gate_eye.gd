extends EnemyBase
## 고리에 박힌 눈 (맞히면 감김, 9초 뒤 다시 뜸)
## 하늘 문(sky_gate.gd)의 눈 하나.

const T := GameConst.TILE

var gate: Node
var index := 0
var state := "open"
var _timer := 2.0
var _aim: StStrike
var _closed_t := 0.0
var _charge := 0.0


func _build() -> void:
	max_hp = 500
	body_size = Vector2(20, 14)
	display_name = ""
	kind_id = "sky_gate_eye"
	is_elite = true
	flying = true
	knock_mult = 0.0
	launch_mult = 0.0
	collision_mask = 0
	engaged = false
	_timer = 2.0 + index * 0.7


func is_open() -> bool:
	return state != "closed"


func charge() -> float:
	return _charge


func close_eye(sec: float) -> void:
	if state == "closed":
		_closed_t = maxf(_closed_t, sec)
		return
	state = "closed"
	_closed_t = sec
	_charge = 0.0
	if is_instance_valid(_aim):
		_aim.queue_free()
	_hurtbox.set_deferred("monitorable", false)
	if gate:
		gate.on_eye_closed(self)


func _ai(delta: float) -> void:
	velocity = Vector2.ZERO
	if not engaged:
		return
	var p := player()
	var slow := 1.6 if gate and float(gate.frost_t) > 0.0 else 1.0
	match state:
		"closed":
			_closed_t -= delta
			if _closed_t <= 0.0:
				state = "open"
				hp = max_hp
				_hurtbox.set_deferred("monitorable", true)
				_timer = randf_range(1.5, 3.0)
		"open":
			_timer -= delta
			if _timer <= 0.0 and p and p.is_alive():
				state = "aim"
				_timer = Difficulty.telegraph(1.1) * slow
				_charge = 0.0
				_aim = StStrike.spawn(global_position, "beam", Vector2(0, 10), _timer, {"to": p.center(), "style": "white", "damage": 1, "cause": "sky_gate", "hold": 0.2, "fade": 0.3})
				if gate:
					gate._need("eye", global_position)
		"aim":
			_timer -= delta
			_charge = 1.0 - _timer / maxf(Difficulty.telegraph(1.1) * slow, 0.01)
			if is_instance_valid(_aim) and p and _timer > 0.3:
				_aim.to = global_position + (p.center() - global_position).normalized() * 40.0 * T
			if _timer <= 0.0:
				state = "open"
				_charge = 0.0
				_timer = Difficulty.rest(randf_range(3.5, 5.5)) + (2.0 if gate and gate.phase == 1 else 0.0)


func _die(_dir: int) -> void:
	close_eye(9.0)


func take_hit(hit: Hit) -> void:
	if state == "closed":
		return
	super.take_hit(hit)
