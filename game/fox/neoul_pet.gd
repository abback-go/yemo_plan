class_name NeoulPet
extends Node2D
## 작은 여우 너울 (docs/chapter1.md 4.7절): 몸 약 14px, 흰 털에 푸른 여우불 끝, 꼬리 1개.
## 세라 뒤를 따라다니고(공중에서는 떠서), 멈추면 앉아 하품·꼬리 흔들기. 머리 위 말풍선으로 혼잣말.
## 여우 모드 동안에는 세라에게 깃들어 사라진다. "ab_neoul" 플래그가 서야 보인다.

var player: Player
var facing := 1
var _vel := Vector2.ZERO
var _t := 0.0
var _hop := 0.0
var _idle := 0.0
var _yawn := 0.0
var _bubble := ""
var _bubble_t := 0.0
var _merged := false
var _talking := false
var _scripted := false ## 컷신에서 직접 움직이는 중
var _font: Font
var _glow: LightGlow


func _ready() -> void:
	z_index = 2
	_font = ThemeDB.fallback_font
	_glow = LightGlow.make(Vector2(0, -8), 26.0, Color(0.55, 0.85, 1.0), 0.25)
	_glow.z_index = -1
	add_child(_glow)


func attach(p: Player) -> void:
	player = p


func active() -> bool:
	return GameState.has_ability("neoul") and not _merged


func snap_to_player() -> void:
	if player:
		global_position = player.global_position + Vector2(-player.facing * 18, 0)
		_vel = Vector2.ZERO


func merge_into_player() -> void:
	_merged = true
	Fx.burst(global_position + Vector2(0, -6), 14, {spread = 180.0, speed_min = 30.0, speed_max = 80.0, lifetime = 0.4,
		gradient = Palette.fade_gradient(Color(0.6, 0.85, 1.0)), add = true})


func leave_player() -> void:
	_merged = false
	snap_to_player()
	Fx.burst(global_position + Vector2(0, -6), 14, {spread = 180.0, speed_min = 30.0, speed_max = 80.0, lifetime = 0.4,
		gradient = Palette.fade_gradient(Color(0.6, 0.85, 1.0)), add = true})
	if randf() < 0.6:
		var lines := ["…후우. 꼬리 하나로는 이 정도니라.", "다음엔 좀 더 아껴 쓰거라.", "배고프다. 기운을 썼더니.", "흥, 이 정도야 껌이니라."]
		bubble(lines[randi() % lines.size()], 2.6)


## 머리 위 말풍선 (게임을 멈추지 않음)
func bubble(text: String, time := 2.5) -> void:
	_bubble = text
	_bubble_t = time


func set_talking(on: bool) -> void:
	_talking = on


func face(dir: int) -> void:
	if dir != 0:
		facing = dir


func emote(kind: String, _time := 1.2) -> void:
	bubble({"!": "!", "?": "?", "...": "…", "heart": "♥", "note": "♪", "anger": "#"}.get(kind, kind), 1.2)


## 컷신: 특정 x로 걸어가기
func walk_to(x: float, speed := 70.0) -> void:
	_scripted = true
	face(1 if x > global_position.x else -1)
	var t := create_tween()
	t.tween_property(self, "global_position:x", x, absf(x - global_position.x) / speed)
	await t.finished


func release_script() -> void:
	_scripted = false


func _physics_process(delta: float) -> void:
	_t += delta
	_bubble_t = maxf(_bubble_t - delta, 0.0)
	visible = active() or _scripted
	if not visible or player == null:
		return
	if _scripted:
		queue_redraw()
		return
	var target := player.global_position + Vector2(-player.facing * 20, 0)
	var airborne := not player.is_on_floor()
	if airborne or absf(player.velocity.y) > 1.0:
		target.y -= 14.0 + sin(_t * 3.0) * 3.0
	var to := target - global_position
	if to.length() > 260.0:
		global_position = target # 너무 멀어지면 순간이동 (여우니까)
		Fx.burst(global_position + Vector2(0, -6), 8, {spread = 180.0, speed_min = 20.0, speed_max = 60.0, lifetime = 0.3,
			gradient = Palette.fade_gradient(Color(0.6, 0.85, 1.0)), add = true})
	_vel = _vel.lerp(to * 7.0, minf(delta * 8.0, 1.0))
	global_position += _vel * delta
	if absf(_vel.x) > 8.0:
		facing = 1 if _vel.x > 0 else -1
		_idle = 0.0
		_hop += delta * 14.0
	else:
		facing = 1 if player.global_position.x > global_position.x else -1
		_idle += delta
	if _idle > 6.0 and _yawn <= 0.0 and randf() < 0.004:
		_yawn = 1.2
	_yawn = maxf(_yawn - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	var moving := absf(_vel.x) > 8.0 and not _scripted
	var floating := not _scripted and player and not player.is_on_floor()
	var hop := -absf(sin(_hop)) * 3.0 if moving and not floating else 0.0
	var sit := _idle > 1.5 and not moving
	var f := float(facing)
	var base := Vector2(0, hop)
	var fur := Color("#f4f0ea")
	var shade := Color("#d8d2cc")
	var blue := Color(0.55, 0.82, 1.0)
	var core := Color(0.88, 0.97, 1.0)
	# 꼬리 (하나, 끝에 여우불)
	var tw := sin(_t * (4.0 if not sit else 2.0)) * 3.0
	var tail_base := base + Vector2(-5 * f, -5)
	var tail_tip := base + Vector2(-13 * f, -13 + tw)
	draw_colored_polygon(PackedVector2Array([tail_base + Vector2(0, -2), tail_base.lerp(tail_tip, 0.5) + Vector2(-2 * f, -3), tail_tip, tail_base.lerp(tail_tip, 0.5) + Vector2(2 * f, 2), tail_base + Vector2(0, 2)]), fur)
	draw_circle(tail_tip, 3.0, blue)
	draw_circle(tail_tip + Vector2(0, -1), 1.5, core)
	draw_rect(Rect2(tail_tip + Vector2(sin(_t * 9.0), -4.0 - fmod(_t * 6.0, 3.0)), Vector2(1, 1)), Color(core, 0.8))
	# 몸
	if sit:
		draw_colored_polygon(PackedVector2Array([base + Vector2(-5 * f, 0), base + Vector2(4 * f, 0), base + Vector2(3 * f, -8), base + Vector2(-3 * f, -9)]), fur)
	else:
		draw_colored_polygon(PackedVector2Array([base + Vector2(-6 * f, -2), base + Vector2(5 * f, -2), base + Vector2(6 * f, -7), base + Vector2(-5 * f, -8)]), fur)
		var leg := sin(_hop) * 1.5 if moving else 0.0
		draw_rect(Rect2(base + Vector2(-5 * f + leg, -2), Vector2(1.5, 2)), shade)
		draw_rect(Rect2(base + Vector2(3 * f - leg, -2), Vector2(1.5, 2)), shade)
	# 머리
	var hc := base + Vector2(5 * f, -10 if not sit else -11)
	draw_colored_polygon(PackedVector2Array([hc + Vector2(-3 * f, 3), hc + Vector2(-3 * f, -2), hc + Vector2(1 * f, -4), hc + Vector2(5 * f, -1), hc + Vector2(7 * f, 1), hc + Vector2(2 * f, 4)]), fur)
	# 귀
	var ear := sin(_t * 2.5) * 0.6
	draw_colored_polygon(PackedVector2Array([hc + Vector2(-2 * f, -2), hc + Vector2(-3 * f + ear, -8), hc + Vector2(1 * f, -3)]), fur)
	draw_colored_polygon(PackedVector2Array([hc + Vector2(1 * f, -3), hc + Vector2(2 * f - ear, -9), hc + Vector2(3 * f, -2)]), fur)
	draw_rect(Rect2(hc + Vector2(-3 * f + ear - (1 if f < 0 else 0), -8), Vector2(1, 2)), blue)
	draw_rect(Rect2(hc + Vector2(2 * f - ear - (1 if f < 0 else 0), -9), Vector2(1, 2)), blue)
	# 눈·코
	if _yawn > 0.0:
		draw_line(hc + Vector2(1 * f, -1), hc + Vector2(3 * f, -1), Color("#2a1a2a"), 1.0)
		draw_rect(Rect2(hc + Vector2(4 * f - (2 if f < 0 else 0), 1), Vector2(2, 2)), Color("#c86a7a"))
	else:
		var blink := fmod(_t, 4.1) < 0.12
		if blink:
			draw_line(hc + Vector2(1 * f, -1), hc + Vector2(3 * f, -1), Color("#2a1a2a"), 1.0)
		else:
			draw_rect(Rect2(hc + Vector2(2 * f - (1 if f < 0 else 0), -2), Vector2(1, 2)), Color("#2a5ab0"))
	draw_rect(Rect2(hc + Vector2(6 * f - (1 if f < 0 else 0), 0), Vector2(1, 1)), Color("#2a1a2a"))
	if _talking and int(_t * 10.0) % 2 == 0:
		draw_rect(Rect2(hc + Vector2(4 * f - (1 if f < 0 else 0), 2), Vector2(2, 1)), Color("#8a3a4a"))
	# 말풍선
	if _bubble_t > 0.0 and _bubble != "":
		var a := clampf(_bubble_t * 4.0, 0.0, 1.0)
		var w := _font.get_string_size(_bubble, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 10
		var p := Vector2(-w * 0.5, -40)
		draw_rect(Rect2(p, Vector2(w, 16)), Color(0.02, 0.05, 0.1, 0.85 * a))
		draw_rect(Rect2(p, Vector2(w, 1)), Color(blue, 0.9 * a))
		draw_colored_polygon(PackedVector2Array([Vector2(-3, -24), Vector2(3, -24), Vector2(0, -20)]), Color(0.02, 0.05, 0.1, 0.85 * a))
		draw_string(_font, p + Vector2(5, 12), _bubble, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.75, 0.9, 1.0, a))
