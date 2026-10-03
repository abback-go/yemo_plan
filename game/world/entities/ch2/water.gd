extends Node2D
## 하수도의 별빛 물 (수위 퍼즐). low_if 조건이 맞으면 물이 low_y까지 빠지고, 아니면 y(수면)까지 찬다(2초에 걸쳐 오르내림).
## 물이 차 있을 때 수면 아래로 빠지면 거센 물살에 떠밀려 나온다(가시처럼 1 피해 + 직전 땅).
## 물이 빠지면 바닥을 걸어 아래 통로로 갈 수 있다. 수면에 뜬 뗏목은 k_raft.
## {t = "k_water", x, y, w, h, low_y, low_if = "k_sw3_low", safe_x, safe_y}  (x·y = 높은 수면의 왼쪽 위 칸, h = 바닥까지 칸 수)
## safe_x·safe_y: 떠밀려 나올 자리(칸). 수면 아래 바닥이 "직전 안전한 땅"으로 기억돼 다시 빠지는 일이 없게.

const TEAL := Color("#6af0e0")

var rect := Rect2()
var low_y := 0.0
var low_if := ""
var surface := 0.0 ## 지금 수면 (방 좌표 px)
var _target := 0.0
var _t := 0.0
var _hz: Area2D
var _safe := Vector2.INF
var _cool := 0.0


func setup(room: Room, e: Dictionary, _eid: String) -> void:
	var T := GameConst.TILE
	rect = Rect2(float(e.get("x", 0)) * T, float(e.get("y", 0)) * T, float(e.get("w", 4)) * T, float(e.get("h", 4)) * T)
	low_y = float(e.get("low_y", e.get("y", 0) + e.get("h", 4) - 1)) * T
	low_if = String(e.get("low_if", ""))
	if e.has("safe_x"):
		_safe = Vector2(float(e.get("safe_x")) * T + 8.0, float(e.get("safe_y", 0)) * T)
	z_index = 3
	add_to_group(&"k_water")
	_target = low_y if RoomData.cond_ok(low_if) else rect.position.y
	surface = _target
	_hz = Area2D.new()
	_hz.collision_layer = 0
	_hz.collision_mask = GameConst.L_PLAYER
	_hz.monitoring = true
	var cs := CollisionShape2D.new()
	cs.shape = RectangleShape2D.new()
	_hz.add_child(cs)
	add_child(_hz)
	_update_hazard()
	GameState.flag_changed.connect(func(_k: String) -> void:
		var want := low_y if RoomData.cond_ok(low_if) else rect.position.y
		if want != _target:
			_target = want
			Sfx.play(&"whoosh", -4.0, 0.1))


func _update_hazard() -> void:
	var cs := _hz.get_child(0) as CollisionShape2D
	var bottom := rect.end.y
	var top := surface + 10.0 # 수면에서 조금 아래부터 (뗏목 위·수면에 발끝이 닿는 건 괜찮다)
	var hgt := maxf(bottom - top, 0.0)
	(cs.shape as RectangleShape2D).size = Vector2(rect.size.x - 4.0, maxf(hgt, 1.0))
	cs.position = Vector2(rect.position.x + rect.size.x * 0.5, top + hgt * 0.5)
	cs.disabled = hgt < 12.0


func _physics_process(delta: float) -> void:
	_t += delta
	if absf(surface - _target) > 0.5:
		surface = move_toward(surface, _target, 60.0 * delta)
		_update_hazard()
	_cool -= delta
	if not (_hz.get_child(0) as CollisionShape2D).disabled and _cool <= 0.0:
		for b in _hz.get_overlapping_bodies():
			if b is Player:
				_wash_out(b as Player)
	queue_redraw()


## 물살에 떠밀려 나옴: 정해 둔 자리로 + 1 피해
func _wash_out(p: Player) -> void:
	_cool = 0.8
	if _safe == Vector2.INF:
		p.hazard_hit()
		return
	Fx.burst(p.center(), 16, {spread = 180.0, speed_min = 40.0, speed_max = 120.0, lifetime = 0.4,
		gradient = Palette.fade_gradient(TEAL), add = true})
	Sfx.play(&"squish", 0.0, 0.1)
	if p.take_damage(1, &"water", p.global_position.x, true) and p.is_alive():
		p.global_position = _safe
		p.velocity = Vector2.ZERO
		p.camera.reset_smoothing()
		Story.toast("거센 물살에 떠밀려 나왔다.", 1.6)


func _draw() -> void:
	var top := surface
	var bottom := rect.end.y
	if bottom - top < 2.0:
		return
	var x0 := rect.position.x
	var w := rect.size.x
	# 깊이에 따라 짙어지는 청록 + 빛 일렁임
	var steps := 6
	for i in steps:
		var k := float(i) / steps
		var y := lerpf(top, bottom, k)
		draw_rect(Rect2(x0, y, w, (bottom - top) / steps + 1.0), Color(TEAL.darkened(0.5 + k * 0.35), 0.55 + k * 0.25))
	draw_rect(Rect2(x0, top, w, 2), Color(TEAL, 0.9))
	for i in int(w / 12.0):
		var wx := x0 + fmod(i * 23.0 + _t * (10.0 + (i % 3) * 5.0), w)
		draw_rect(Rect2(wx, top + 3 + (i % 4) * 4, 6.0 + (i % 3) * 4.0, 1), Color(1, 1, 1, 0.35))
	for i in 5:
		var ph := fmod(_t * 0.6 + i * 0.2, 1.0)
		draw_circle(Vector2(x0 + fmod(i * 61.0, w), bottom - ph * (bottom - top)), 1.5, Color(TEAL.lightened(0.4), 0.5 * (1.0 - ph)))
