extends EnemyBase
## 거신 (docs/chapter5.md 4절, 8.6절 절망 구간): 바깥 신들의 하얀 얼굴 없는 거인. **무적** — 맞혀도 흠집 하나 나지 않는다("…").
## 화면보다 크다: 다리·엉덩이와 무릎까지 늘어진 손만 보이고 몸통과 머리는 화면 위로 넘친다.
## mode
##   walk  천천히 걷는다(facing 쪽). 한 걸음마다 발이 높이 들리고, 내딛을 자리에 그림자 + 붉은 예고(걸음 시간 전체) →
##         쿵: 발 아래 피해 + 양옆으로 바닥을 달리는 충격파(점프로 넘기) + 화면 흔들림. 다리 사이로 빠져나가면 안전.
##   hand  화면 위에서 거대한 손이 내려온다: 세라 자리에 그림자·붉은 예고(1.3초) → 내려찍기 → 0.8초 머문 뒤 들어 올림.
## 대본용: walking(걷기 켜기/끄기), stomp_now(), sleep(0~1, 반격 장면의 푸른 불), signal stomped(pos)
## 방 데이터 키: mode, height(px), stride(칸), step_time(초), interval(손 간격 초), walking, sleep

signal stomped(pos: Vector2)

const T := GameConst.TILE

var mode := "walk"
var height := 560.0
var stride := 7.0
var step_time := 2.4
var interval := 3.6
var walking := true
var sleep := 0.0
var state := "plant"
var foot_f := Vector2.ZERO ## 앞발 (전역)
var foot_b := Vector2.ZERO ## 뒷발
var moving_front := false ## 지금 움직이는 발이 앞발인가
var step_from := Vector2.ZERO
var step_to := Vector2.ZERO
var hand_pos := Vector2.ZERO ## 손바닥 아래 끝 (전역)
var hand_x := 0.0
var ground := 0.0
var _timer := 0.0
var _state_len := 1.0
var _foot_area: EnemyAttackArea
var _hand_area: EnemyAttackArea
var _say_cd := 0.0
var _init_done := false


func _build() -> void:
	max_hp = 99999
	body_size = Vector2(80, 200)
	cull_offscreen = false # 화면 밖 생략 안 함: 거대한 몸·손·발이 원점에서 멀리 그려짐
	display_name = "거신"
	subtitle = "바깥 신들의 행진"
	kind_id = "colossus"
	is_elite = false
	is_boss = false
	flying = true
	knock_mult = 0.0
	launch_mult = 0.0
	respawns = true
	collision_mask = 0
	var v := ColossusVisual.new()
	v.enemy = self
	_visual = v
	add_child(v)
	_foot_area = add_attack_area(Vector2(70, 40), Vector2.ZERO, &"colossus", 1)
	_foot_area.active = false
	_hand_area = add_attack_area(Vector2(80, 64), Vector2.ZERO, &"colossus", 1)
	_hand_area.active = false


func set_state(s: String, time := 0.0) -> void:
	state = s
	_timer = time
	_state_len = maxf(time, 0.001)


func progress() -> float:
	return clampf(1.0 - _timer / _state_len, 0.0, 1.0)


func _setup_feet() -> void:
	_init_done = true
	ground = global_position.y
	var half := stride * T * 0.5
	foot_f = Vector2(global_position.x + facing * half * 0.5, ground)
	foot_b = Vector2(global_position.x - facing * half * 0.5, ground)
	hand_x = global_position.x
	set_state("plant", 0.6 if mode == "walk" else interval * 0.5)


func hip() -> Vector2:
	var mid := (foot_f.x + foot_b.x) * 0.5
	var lift := 0.0
	if state == "step":
		lift = sin(progress() * PI) * height * 0.015
	return Vector2(mid + facing * height * 0.02, ground - height * 0.48 - lift)


func moving_foot() -> Vector2:
	return foot_f if moving_front else foot_b


func _ai(delta: float) -> void:
	if not _init_done:
		_setup_feet()
	_timer -= delta
	_say_cd -= delta
	if mode == "hand":
		_ai_hand(delta)
	else:
		_ai_walk(delta)
	# 몸(피격 상자)이 엉덩이 아래를 따라감
	global_position = Vector2(hip().x if mode == "walk" else hand_x, ground)


func _ai_walk(_delta: float) -> void:
	match state:
		"plant":
			if _timer <= 0.0 and walking:
				_begin_step()
		"step":
			var k := progress()
			var e := k * k * (3.0 - 2.0 * k)
			var p := step_from.lerp(step_to, e)
			p.y = ground - sin(k * PI) * height * 0.16
			if moving_front:
				foot_f = p
			else:
				foot_b = p
			if _timer <= 0.0:
				_land()


func _begin_step() -> void:
	# 뒤에 있는 발을 앞발 너머로 내딛는다
	var front_x := foot_f.x if (foot_f.x - foot_b.x) * facing >= 0.0 else foot_b.x
	moving_front = (foot_f.x - foot_b.x) * facing < 0.0
	step_from = moving_foot()
	var tx := front_x + facing * stride * T
	step_to = Vector2(tx, _ground_at(tx))
	var st := Difficulty.telegraph(step_time)
	set_state("step", st)
	StStrike.spawn(step_to + Vector2(0, -20), "band", Vector2(height * 0.13, 40), st, {"damage": 1, "cause": "colossus", "hold": 0.15, "fade": 0.4})
	StArt.sfx_pitch(&"colossus_step", &"growl", 0.5, -10.0)


func _land() -> void:
	if moving_front:
		foot_f = step_to
	else:
		foot_b = step_to
	set_state("plant", Difficulty.rest(0.5))
	StArt.sfx(&"colossus_step", &"slam", 4.0)
	StArt.sfx_pitch(&"colossus_step", &"explode", 0.45, -2.0)
	Fx.shake(0.7, 0.45)
	stomped.emit(step_to)
	Fx.burst(step_to + Vector2(0, -4), 30, {direction = Vector2.UP, spread = 75.0, speed_min = 60.0, speed_max = 220.0, lifetime = 0.8,
		gradient = Palette.fade_gradient(Color(0.45, 0.4, 0.42)), size_min = 2.0, size_max = 5.0, gravity = Vector2(0, 260), add = false})
	Fx.ring(step_to + Vector2(0, -6), 10.0, 6.0 * T, Color(1, 1, 1, 0.6), 0.4, 3.0, false)
	for dir: float in [-1.0, 1.0]:
		var s := StShot.fire(step_to + Vector2(dir * height * 0.07, -8), Vector2(dir, 0), 9.0 * T, "shock", {"radius": 7.0, "damage": 1, "cause": "colossus", "life": 0.75})
		s.z_index = 3


func _ground_at(x: float) -> float:
	return floor_y_at(x, ground - 6.0 * T, ground + 6.0 * T, ground)


# ─── 손 ─────────────────────────────────────────────────

func _ai_hand(_delta: float) -> void:
	var p := player()
	var top := ground - 26.0 * T
	match state:
		"plant":
			hand_pos = Vector2(hand_x, top)
			if _timer <= 0.0 and walking and p and p.is_alive():
				hand_x = p.global_position.x + clampf(p.velocity.x * 0.25, -3.0 * T, 3.0 * T)
				var gy := _ground_at(hand_x)
				var st := Difficulty.telegraph(1.3)
				set_state("hand_warn", st)
				StStrike.spawn(Vector2(hand_x, gy - 2.0 * T), "band", Vector2(5.5 * T, 4.0 * T), st, {"damage": 0, "hold": 0.0, "fade": 0.05})
				StArt.sfx_pitch(&"colossus_step", &"growl", 0.6, -6.0)
		"hand_warn":
			var k := progress()
			var gy2 := _ground_at(hand_x)
			hand_pos = Vector2(hand_x, lerpf(top, gy2 - 7.0 * T, k * k))
			if _timer <= 0.0:
				set_state("hand_slam", 0.1)
		"hand_slam":
			var gy3 := _ground_at(hand_x)
			hand_pos = Vector2(hand_x, lerpf(gy3 - 7.0 * T, gy3, progress()))
			if _timer <= 0.0:
				hand_pos.y = gy3
				_hand_area.global_position = hand_pos + Vector2(0, -32)
				_hand_area.active = true
				set_state("hand_rest", 0.8)
				Fx.shake(0.6, 0.35)
				StArt.sfx(&"colossus_step", &"slam", 3.0)
				stomped.emit(hand_pos)
				Fx.burst(hand_pos, 26, {direction = Vector2.UP, spread = 80.0, speed_min = 60.0, speed_max = 200.0, lifetime = 0.7,
					gradient = Palette.fade_gradient(Color(0.45, 0.4, 0.42)), size_min = 2.0, size_max = 4.0, gravity = Vector2(0, 260), add = false})
				for dir: float in [-1.0, 1.0]:
					StShot.fire(hand_pos + Vector2(dir * 2.6 * T, -8), Vector2(dir, 0), 8.0 * T, "shock", {"radius": 7.0, "damage": 1, "cause": "colossus", "life": 0.6})
		"hand_rest":
			if _timer < 0.65:
				_hand_area.active = false
			if _timer <= 0.0:
				set_state("hand_lift", 0.7)
		"hand_lift":
			var gy4 := _ground_at(hand_x)
			var k2 := progress()
			hand_pos = Vector2(hand_x, lerpf(gy4, top, k2 * k2))
			if _timer <= 0.0:
				set_state("plant", Difficulty.rest(interval - 2.9))


## 대본: 지금 바로 한 걸음 (walk) / 한 번 내려찍기 (hand)
func stomp_now() -> void:
	if mode == "hand":
		set_state("plant", 0.0)
	elif state == "plant":
		_begin_step()


# ─── 무적 ───────────────────────────────────────────────

func modify_damage(_hit: Hit) -> float:
	return 0.0


func _on_blocked(hit: Hit) -> void:
	var at := hit.source_pos if hit.source_pos != Vector2.ZERO else global_position + Vector2(0, -60)
	Fx.burst(at, 6, {spread = 180.0, speed_min = 30.0, speed_max = 90.0, lifetime = 0.25, gradient = Palette.fade_gradient(StArt.GOD_WHITE), add = false})
	if _say_cd <= 0.0:
		_say_cd = 2.5
		_float_text(at + Vector2(0, -10), "…")


func _float_text(pos: Vector2, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos + Vector2(-6, -10)
	l.z_index = 20
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color(0.92, 0.92, 1.0))
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.1))
	l.add_theme_constant_override("outline_size", 4)
	Fx.effect_parent().add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 14.0, 0.8)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.4).set_delay(0.5)
	tw.tween_callback(l.queue_free)


## 거신 그림 (적 원점과 무관하게 전역 발 위치로 그린다)
class ColossusVisual extends Node2D:
	var enemy: Node

	func _process(_d: float) -> void:
		z_index = -1
		queue_redraw()

	func _draw() -> void:
		if enemy == null:
			return
		var e: Node = enemy
		var h: float = e.height
		var dir := float(e.facing)
		var pal := StColossusArt.palette(0.08, 1.0, StColossusArt.FOG, float(e.sleep))
		if e.mode == "hand":
			var hp: Vector2 = to_local(e.hand_pos)
			StColossusArt.draw_slam_hand(self, hp, h * 0.16, pal, 0.0 if e.state != "hand_warn" else 0.3 * e.progress())
			return
		var hip: Vector2 = to_local(e.hip())
		var ff: Vector2 = to_local(e.foot_f)
		var fb: Vector2 = to_local(e.foot_b)
		# 내딛을 자리의 그림자 (점점 짙어짐)
		if e.state == "step":
			var tgt: Vector2 = to_local(e.step_to)
			var k: float = e.progress()
			draw_colored_polygon(_ellipse(tgt, h * 0.08 * (0.6 + 0.4 * k), 5.0), Color(0, 0, 0, 0.2 + 0.4 * k))
		var t: float = e._t
		var arm_sw := sin(t * 1.3) * h * 0.02
		var res: Dictionary = StColossusArt.draw_walker(self, hip, ff, fb, h, dir, pal,
			hip + Vector2(dir * h * 0.1 + arm_sw, h * 0.1), hip + Vector2(-dir * h * 0.02 - arm_sw, h * 0.12))
		# 발밑 그림자
		for f in [ff, fb]:
			var fv: Vector2 = f
			var lift := clampf((to_local(Vector2(0, e.ground)).y - fv.y) / (h * 0.16), 0.0, 1.0)
			draw_colored_polygon(_ellipse(Vector2(fv.x, to_local(Vector2(0, e.ground)).y), h * 0.07 * (1.0 - lift * 0.5), 3.0), Color(0, 0, 0, 0.35 * (1.0 - lift)))
		if float(e.sleep) > 0.0:
			for i in 6:
				var q: Vector2 = hip.lerp(res.knee_f, float(i) / 5.0) + Vector2(sin(t + i) * 8.0, 0)
				StArt.foxfire(self, q, 4.0, t + i, float(e.sleep))

	func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in 14:
			var a := TAU * i / 14.0
			pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
		return pts
