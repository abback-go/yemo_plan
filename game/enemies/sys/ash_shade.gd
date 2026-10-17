extends EnemyBase
## 재 그림자 (불사조 수업 3단계 — 불사조의 알 지키기): 금서를 노리다 재가 된 자들의 그림자.
## 세라가 아니라 **알**을 향해 기어간다(알이 없으면 세라). 알에 닿으면 들러붙어 불을 갉아먹는다(phoenix_egg가 줄임).
## fly = true면 재 나방: 위에서 너울너울 내려온다. 약하다(일반 90 / 나방 70) — 수로 밀어붙이는 적.
## 세라가 가까이(2.5T) 오면 짧게 할퀴기(0.5초 붉은 예고).

enum S { CREEP, GNAW, WINDUP, SWIPE }

var fly := false
var state: S = S.CREEP
var _timer := 0.0
var _swipe: EnemyAttackArea
var _egg: Node2D
var _bob := 0.0


func _build() -> void:
	max_hp = 70 if fly else 90
	body_size = Vector2(12, 12) if fly else Vector2(14, 18)
	flying = fly
	knock_mult = 0.8
	launch_mult = 0.6 if not fly else 0.0
	kind_id = "ash_moth" if fly else "ash_shade"
	display_name = "재 나방" if fly else "재 그림자"
	subtitle = "꺼진 불을 찾아 헤매는 것" if fly else "금서를 노리다 재가 된 자"
	is_elite = false
	_visual = ShadeVisual.new()
	_visual.enemy = self
	add_child(_visual)
	_swipe = add_attack_area(Vector2(18, 14), Vector2(10, -9), &"ash")
	_swipe.active = false
	var touch := add_attack_area(Vector2(8, 8), Vector2(0, -6), &"ash")
	touch.dodgeable = false
	_bob = randf() * TAU


func _ready() -> void:
	super()
	if fly:
		collision_mask = GameConst.L_WORLD


func _target() -> Vector2:
	if _egg == null or not is_instance_valid(_egg):
		_egg = get_tree().get_first_node_in_group(&"phoenix_egg") as Node2D
	if _egg:
		return _egg.global_position + Vector2(0, -14)
	var p := player()
	return p.center() if p else global_position


func _ai(delta: float) -> void:
	_bob += delta * 3.0
	_timer -= delta
	var p := player()
	var to := _target()
	var dx := to.x - global_position.x
	match state:
		S.CREEP, S.GNAW:
			if p and p.global_position.distance_to(global_position) < 2.5 * GameConst.TILE and _timer <= 0.0:
				facing = dir_to_player()
				state = S.WINDUP
				_timer = Difficulty.telegraph(0.5)
				velocity = Vector2.ZERO
				return
			var near := absf(dx) < 12.0 and (not fly or absf(to.y - (global_position.y - 6.0)) < 14.0)
			state = S.GNAW if near else S.CREEP
			if absf(dx) > 2.0:
				facing = 1 if dx > 0.0 else -1
			if fly:
				var want := (to + Vector2(-facing * 4.0, sin(_bob) * 6.0) - global_position + Vector2(0, 6)).limit_length(1.0)
				velocity = velocity.move_toward(want * 42.0 * (0.0 if near else 1.0), 160.0 * delta)
			else:
				velocity.x = move_toward(velocity.x, 0.0 if near else facing * 38.0, 300.0 * delta)
		S.WINDUP:
			velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
			if _timer <= 0.0:
				state = S.SWIPE
				_timer = 0.18
				_swipe.position.x = 10.0 * facing
				_swipe.active = true
				Sfx.play(&"whoosh", -10.0, 0.15)
		S.SWIPE:
			if _timer <= 0.0:
				_swipe.active = false
				state = S.CREEP
				_timer = Difficulty.rest(1.4)


class ShadeVisual extends Node2D:
	var enemy: Node

	func _draw() -> void:
		var e = enemy
		var k: float = e._bob
		var flash: bool = e.flash_amount() > 0.0
		var body := Color(0.16, 0.13, 0.17) if not flash else Color(1, 1, 1)
		var ember := Color(1.0, 0.5, 0.25)
		var f := float(e.facing)
		if e.fly:
			# 재 나방: 잿빛 날개 두 쌍, 가운데 불씨 하나
			var flap := sin(k * 4.0) * 5.0
			for s in [-1.0, 1.0]:
				draw_colored_polygon(PackedVector2Array([Vector2(0, -7), Vector2(s * 9, -12 - flap), Vector2(s * 11, -5), Vector2(s * 3, -4)]), Color(body, 0.9))
				draw_colored_polygon(PackedVector2Array([Vector2(0, -6), Vector2(s * 7, -1 + flap * 0.4), Vector2(s * 2, -3)]), Color(0.3, 0.26, 0.28, 0.9))
			draw_rect(Rect2(-1, -10, 2, 7), body)
			draw_circle(Vector2(0, -7), 1.5, ember)
			return
		# 재 그림자: 웅크린 사람 꼴, 아래가 재로 흩어진다. 눈 둘(불씨색), 긴 팔
		var sway := sin(k) * 1.0
		var pts := PackedVector2Array([
			Vector2(-7, 0), Vector2(-6, -9), Vector2(-4 + sway, -15), Vector2(0 + sway, -18),
			Vector2(4 + sway, -15), Vector2(6, -9), Vector2(7, 0),
		])
		draw_colored_polygon(pts, body)
		for i in 4:
			var ph := fmod(k * 0.4 + i * 0.25, 1.0)
			draw_rect(Rect2(-5 + i * 3, -1 - ph * 8.0, 1, 1), Color(0.5, 0.45, 0.5, 0.8 * (1.0 - ph)))
		var windup: bool = e.state == e.S.WINDUP
		var arm_y := -12.0 if windup else -6.0
		draw_line(Vector2(f * 3, -10), Vector2(f * (9 if windup else 7), arm_y), body, 2.0)
		draw_rect(Rect2(f * 2 - 1 + sway, -15, 2, 1), ember)
		draw_rect(Rect2(f * 2 + f * 3 - 1 + sway, -15, 2, 1), ember)
		if windup:
			draw_arc(Vector2(f * 9, -9), 9.0, -1.2, 1.2, 10, Color(1.0, 0.25, 0.2, 0.7), 1.0)
		if e.state == e.S.GNAW:
			draw_circle(Vector2(f * 8, -8), 2.0 + sin(k * 8.0), Color(ember, 0.6))
