class_name SniperCoverArrows
extends Node2D
## 저격 구간 (docs/chapter3.md 7.3절 — 경계의 숲). 방의 한 영역(x, y, w, h)에 세라가 들어오면, 먼 가지 위의 저격수(엘라리엔)가
## 예고선으로 세라를 따라온다: 가는 붉은 선이 점점 진해짐(aim초) → 흰 선이 깜빡임(lock초, 이때 선이 고정 — 피할 틈) → 화살.
## 지형(바위·쓰러진 나무 = 지도 '#')이 시야를 가리면 선이 그 앞에서 끊기고 조준이 천천히 풀린다 → 엄폐하며 전진.
## 화살은 ElfArrow(불꽃 방벽으로 되쏠 수 있음). 저격수 자리(ox, oy — 방 안, 보통 오른쪽 위 가지)에는 작은 실루엣과 활 빛.
## 저격수가 화면 밖이면 화면 가장자리에 방향 표시(화살촉 모양 + 조준 중이면 붉은 고리).
## 방 데이터: {t = "sniper_cover_arrows", x, y, w, h, ox, oy, aim = 1.25, lock = 0.45, rest = 1.4, speed = 30, damage = 1,
##            on_if = "", done = ""(이 플래그가 서면 멈춤), first = ""(처음 조준할 때 세울 플래그 — 안내 대본용)}

var rect := Rect2()
var origin := Vector2.ZERO
var aim_time := 1.25
var lock_time := 0.45
var rest_time := 1.4
var speed := 30.0
var damage := 1
var on_if := ""
var done := ""
var first := ""
var _k := 0.0 ## 조준 진행도 0~1
var _lock := -1.0 ## 0 이상이면 고정 후 지난 시간
var _rest := 0.8
var _dir := Vector2.LEFT
var _line: AimLine
var _t := 0.0
var _seen := false
var _shots := 0


func setup(room: Room, e: Dictionary, _eid: String) -> void:
	var T := GameConst.TILE
	rect = Rect2(float(e.get("x", 0)) * T, float(e.get("y", 0)) * T, float(e.get("w", 10)) * T, float(e.get("h", 10)) * T)
	origin = Vector2(float(e.get("ox", room.data.cols() - 3)) * T + 8.0, float(e.get("oy", 2)) * T)
	aim_time = float(e.get("aim", 1.25))
	lock_time = float(e.get("lock", 0.45))
	rest_time = float(e.get("rest", 1.4))
	speed = float(e.get("speed", 30.0))
	damage = int(e.get("damage", 1))
	on_if = String(e.get("on_if", ""))
	done = String(e.get("done", ""))
	first = String(e.get("first", ""))
	z_index = 5


func _active() -> bool:
	if done != "" and GameState.has_flag(done):
		return false
	return RoomData.cond_ok(on_if)


func _physics_process(delta: float) -> void:
	_t += delta
	var p := get_tree().get_first_node_in_group(GameConst.GROUP_PLAYER) as Player
	var story_busy := Story.busy() and p != null and not p.controls_enabled
	if p == null or not p.is_alive() or not _active() or story_busy or not rect.has_point(p.center()):
		_k = maxf(_k - delta * 1.5, 0.0)
		_lock = -1.0
		if _k <= 0.0:
			_clear()
		queue_redraw()
		return
	if not _seen and first != "":
		_seen = true
		GameState.set_flag(first)
	if _rest > 0.0:
		_rest -= delta * Fx.enemy_time
		queue_redraw()
		return
	if _line == null:
		_line = AimLine.new()
		_line.max_len = 60.0 * GameConst.TILE
		Fx.effect_parent().add_child(_line)
		Ch3Sfx.play(&"bow_draw", -8.0, 0.05)
	if _lock >= 0.0:
		_lock += delta * Fx.enemy_time
		_line.aim(origin, _dir)
		_line.lock()
		if _lock >= Difficulty.telegraph(lock_time):
			_fire()
		queue_redraw()
		return
	_dir = (p.center() - origin).normalized()
	_line.aim(origin, _dir)
	var blocked := _line.blocked and _line.end.distance_to(origin) < origin.distance_to(p.center()) - 6.0
	if blocked:
		# 엄폐: 조준이 천천히 풀린다
		_k = maxf(_k - delta * 0.8, 0.0)
	else:
		_k = minf(_k + delta / Difficulty.telegraph(aim_time), 1.0)
		if _k >= 1.0:
			_lock = 0.0
			Sfx.play(&"sniper_lock", -6.0, 0.0)
	_line.k = _k
	queue_redraw()


func _fire() -> void:
	var a := ElfArrow.new()
	a.setup(origin + _dir * 8.0, _dir, speed * GameConst.TILE, {"style": "arrow", "damage": damage, "cause": "elarien_snipe", "life": 3.0})
	Fx.effect_parent().add_child(a)
	Ch3Sfx.play(&"arrow_shot", -2.0, 0.05)
	_shots += 1
	_lock = -1.0
	_k = 0.0
	_rest = Difficulty.rest(rest_time)
	_clear()


func _clear() -> void:
	if _line and is_instance_valid(_line):
		_line.queue_free()
	_line = null


func _exit_tree() -> void:
	_clear()


func _draw() -> void:
	if not _active():
		return
	# 저격수 실루엣 (먼 가지 위의 작은 그림자 + 흰 활 + 빛 반사)
	var o := origin
	var c := Color(0.02, 0.05, 0.03, 0.9)
	draw_rect(Rect2(o.x - 2, o.y - 1, 4, 9), c)
	draw_circle(o + Vector2(0, -3), 2.5, c)
	draw_line(o + Vector2(-4, -7), o + Vector2(-9, -9), c, 1.0) # 귀
	draw_line(o + Vector2(-5, -10), o + Vector2(-5, 10), Color(0.95, 0.93, 0.85, 0.85), 1.0)
	var g := fmod(_t, 2.2)
	if g < 0.25 or _k > 0.6:
		draw_rect(Rect2(o.x - 6, o.y - 8 + g * 40.0, 2, 2), Color(1, 1, 1, 0.9))
		draw_circle(o + Vector2(-5, 0), 5.0 + _k * 4.0, Color(1, 1, 1, 0.08 + 0.1 * _k))
	_offscreen_marker()


func _offscreen_marker() -> void:
	var xf := get_viewport().get_canvas_transform()
	var sp: Vector2 = xf * origin
	var size := get_viewport().get_visible_rect().size
	var r := Rect2(Vector2(18, 26), size - Vector2(36, 60))
	if r.has_point(sp) or _k <= 0.0:
		return
	var cp := Vector2(clampf(sp.x, r.position.x, r.end.x), clampf(sp.y, r.position.y, r.end.y))
	var d := (sp - cp).normalized()
	var lp := to_local(xf.affine_inverse() * cp)
	var n := Vector2(-d.y, d.x)
	var pulse := 0.7 + 0.3 * sin(_t * 8.0)
	draw_circle(lp, 9.0, Color(0.05, 0.1, 0.05, 0.6))
	draw_colored_polygon(PackedVector2Array([lp + d * 8.0, lp - d * 3.0 + n * 5.0, lp - d * 1.0, lp - d * 3.0 - n * 5.0]), Color(0.85, 1.0, 0.6, pulse))
	draw_arc(lp, 11.0, -PI * 0.5, -PI * 0.5 + TAU * _k, 16, Color(Palette.DANGER if _lock < 0.0 else Color.WHITE, pulse), 1.5)
