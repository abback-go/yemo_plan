class_name CollapseChaser
extends Node2D
## 무너지는 회랑 (docs/chapter1.md 12.1절): start_flag가 서면 왼쪽에서부터 천장이 무너지며 9.3 T/s로 쫓아온다.
## 잡히면 1 피해 + 회랑 입구에서 다시. 위치 타임은 이것을 늦추지 않는다.

const SPEED_T := 9.3

var start_flag := ""
var stop_x := 0.0
var x := -64.0
var running := false
var _t := 0.0
var _debris_t := 0.0
var _room_h := 368.0
var _caught := false


func setup(room: Room, e: Dictionary, _eid: String) -> void:
	start_flag = String(e.get("start_flag", ""))
	stop_x = float(e.get("stop_x", room.data.cols() - 6)) * 16.0
	x = float(e.get("x", -4)) * 16.0
	_room_h = room.size_px.y
	z_index = 25


func actor_id() -> String:
	return "chaser"


## 대본이 추격을 시작시킴
func start() -> void:
	if running:
		return
	running = true
	Sfx.play(&"crumble", 2.0, 0.0)
	Fx.shake(0.3, 0.5)


func _physics_process(delta: float) -> void:
	_t += delta
	if not running:
		if start_flag != "" and GameState.has_flag(start_flag):
			running = true
			Sfx.play(&"crumble", 2.0, 0.0)
		return
	if x < stop_x:
		x += SPEED_T * 16.0 * delta
	_debris_t -= delta
	if _debris_t <= 0.0:
		_debris_t = 0.08
		Fx.burst(Vector2(x + randf_range(0, 40), randf_range(0, 40)), 4, {direction = Vector2.DOWN, spread = 20.0,
			speed_min = 80.0, speed_max = 200.0, lifetime = 0.8, gravity = Vector2(0, 500),
			gradient = Palette.fade_gradient(Color("#4a4458")), size_min = 2.0, size_max = 4.0})
		Fx.shake(0.06, 0.1)
	var w := World.get_world()
	if w and not _caught and w.player.is_alive() and w.player.global_position.x < x + 10.0:
		_caught = true
		_catch(w)
	queue_redraw()


func _catch(w: World) -> void:
	w.player.take_damage(1, &"collapse", x, true)
	if w.player.is_alive():
		Story.toast("무너지는 돌더미에 휩쓸렸다!")
		w.go(w.room.data.id, "start")


func _draw() -> void:
	if not running:
		return
	var dark := Color(0.02, 0.015, 0.03)
	draw_rect(Rect2(-2000, -20, x + 2000, _room_h + 40), dark)
	# 무너지는 경계: 들쭉날쭉한 돌덩이
	for i in 12:
		var yy := i * _room_h / 12.0
		var off := sin(_t * 7.0 + i * 1.7) * 6.0 + 6.0
		draw_rect(Rect2(x - 4 + off, yy, 14, _room_h / 12.0 + 2), Color("#2a2636"))
		draw_rect(Rect2(x + 4 + off, yy + 4, 6, 6), Color("#4a4458"))
	draw_rect(Rect2(x + 18, 0, 3, _room_h), Color(1.0, 0.4, 0.3, 0.25 + 0.15 * sin(_t * 12.0)))
