class_name WindValve
extends Node2D
## 바람 밸브 (docs/archive/sera/chapter3.md 7.3절 — 바람길 퍼즐). 엘프 바람길의 놋쇠·나무 밸브. 불(아무 불 공격)에 맞으면 데워져
## 한 칸 돌아가며 플래그(flag)를 켜고 끈다. 바람길 개체가 그 플래그를 읽는다:
##   상승 기류(공용 updraft)  on_if = "valve_a"   → 밸브가 "위"일 때 켜짐
##   옆바람(crosswind)        on_if = "!valve_a"  → 밸브가 "옆"일 때 켜짐
## 고장 난 밸브(broken = true): 녹슨 톱니가 끼어 있다 — 불로 세 번 데우면 풀린다(fix_flag) → 곧장 "켜짐". 티엘의 부탁(e_tiel_valve).
## 방 데이터: {t = "wind_valve", x, y, flag, start = false(처음 값), broken = false, fix_flag = "", up = true(켜짐 = 위 화살표)}

const BRASS := Color("#c8a050")
const BRASS_D := Color("#7a5a2a")
const WOOD := Color("#5a3e24")
const WIND := Color(0.82, 1.0, 0.85)

var flag := ""
var broken := false
var fix_flag := ""
var on_is_up := true
var _ang := 0.0
var _target_ang := 0.0
var _cool := 0.0
var _heat := 0
var _t := 0.0
var _hurt: Area2D
var _spark := 0.0


func setup(room: Room, e: Dictionary, _eid: String) -> void:
	position = room.tile_pos(e) + Vector2(8, 0)
	flag = String(e.get("flag", "valve"))
	fix_flag = String(e.get("fix_flag", ""))
	broken = bool(e.get("broken", false)) and not (fix_flag != "" and GameState.has_flag(fix_flag))
	on_is_up = bool(e.get("up", true))
	if not GameState.flags.has(flag):
		GameState.set_flag(flag, bool(e.get("start", false)))
	_ang = PI * 0.5 if GameState.has_flag(flag) else 0.0
	_target_ang = _ang
	add_to_group(&"wind_valve")
	add_to_group(&"pillar_target")
	_hurt = Area2D.new()
	_hurt.collision_layer = GameConst.L_ENEMY_HURT
	_hurt.collision_mask = 0
	_hurt.monitoring = false
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(22, 26)
	cs.shape = rs
	cs.position = Vector2(0, -20)
	_hurt.add_child(cs)
	add_child(_hurt)
	z_index = -1


func is_alive() -> bool:
	return true


func is_on_floor() -> bool:
	return true


func is_on() -> bool:
	return GameState.has_flag(flag)


func take_hit(hit: Hit) -> void:
	if _cool > 0.0 or hit.kind == &"ally":
		return
	_cool = 0.6
	if broken:
		_heat += 1
		_spark = 0.4
		Sfx.play(&"block", -4.0, 0.1)
		Fx.burst(global_position + Vector2(0, -22), 8, {spread = 120.0, direction = Vector2.UP, speed_min = 30.0, speed_max = 90.0, lifetime = 0.4})
		if _heat >= 3:
			broken = false
			if fix_flag != "":
				GameState.set_flag(fix_flag)
			# 풀리면 바로 "켜짐"으로 한 칸 돈다 (고친 보람 — 바람이 곧장 살아남)
			GameState.set_flag(flag, true)
			_target_ang = PI * 0.5
			Sfx.play(&"ignite", 0.0, 0.0)
			Ch3Sfx.play(&"wind", -2.0, 0.0)
			Fx.ring(global_position + Vector2(0, -22), 4.0, 26.0, WIND, 0.4, 2.0)
			Story.toast("녹슨 톱니가 풀렸다! 밸브가 다시 돈다.")
		else:
			Story.toast("톱니가 꽉 끼어 있다… 조금 더 데우면 풀릴 것 같다. (%d/3)" % _heat, 1.6)
		return
	var v := not GameState.has_flag(flag)
	GameState.set_flag(flag, v)
	_target_ang = PI * 0.5 if v else 0.0
	Sfx.play(&"chain", -2.0, 0.05)
	Ch3Sfx.play(&"wind", -6.0, 0.05)
	Fx.burst(global_position + Vector2(0, -22), 10, {spread = 180.0, speed_min = 20.0, speed_max = 60.0, lifetime = 0.5,
		gradient = Palette.fade_gradient(WIND), size_min = 1.0, size_max = 2.0, gravity = Vector2.ZERO, add = true})


func _process(delta: float) -> void:
	_t += delta
	_cool = maxf(_cool - delta, 0.0)
	_spark = maxf(_spark - delta, 0.0)
	_target_ang = PI * 0.5 if GameState.has_flag(flag) else 0.0
	_ang = lerp_angle(_ang, _target_ang, clampf(delta * 6.0, 0.0, 1.0))
	queue_redraw()


func _draw() -> void:
	var c := Vector2(0, -22)
	# 받침 기둥 + 관
	draw_rect(Rect2(-3, -14, 6, 14), WOOD)
	draw_rect(Rect2(-3, -14, 1, 14), WOOD.lightened(0.2))
	draw_rect(Rect2(-6, -2, 12, 2), WOOD.darkened(0.3))
	draw_rect(Rect2(-10, -16, 20, 4), BRASS_D)
	draw_rect(Rect2(-10, -16, 20, 1), BRASS)
	# 바퀴 (잎 날개 넷 + 놋쇠 테)
	var spin := _ang + (sin(_t * 30.0) * 0.06 if _spark > 0.0 else 0.0)
	draw_arc(c, 9.0, 0, TAU, 20, BRASS_D, 3.0)
	draw_arc(c, 9.0, 0, TAU, 20, BRASS, 1.0)
	for i in 4:
		var a := spin + TAU * i / 4.0
		var d := Vector2(cos(a), sin(a))
		var n := Vector2(-d.y, d.x)
		draw_colored_polygon(PackedVector2Array([c + d * 2.0, c + d * 5.0 + n * 3.0, c + d * 8.5, c + d * 5.0 - n * 1.0]), Color("#5a9a48") if not broken else Color("#6a6a5a"))
	draw_circle(c, 2.5, BRASS)
	draw_circle(c, 1.2, BRASS_D)
	if broken:
		# 녹과 끼인 톱니
		draw_rect(Rect2(c.x + 5, c.y - 3, 5, 6), Color("#8a4a2a"))
		draw_rect(Rect2(c.x + 6, c.y - 2, 1, 1), Color("#c87a4a"))
		draw_line(c + Vector2(-8, 8), c + Vector2(8, -8), Color("#8a4a2a"), 1.0)
		if _heat > 0:
			draw_circle(c, 10.0, Color(1.0, 0.5, 0.2, 0.08 * _heat))
		return
	# 방향 표시 (켜짐 = 위/옆 — 지금 바람이 어디로 부는지)
	var up := GameState.has_flag(flag) == on_is_up
	var ic := c + Vector2(0, -15)
	var k := 0.7 + 0.3 * sin(_t * 4.0)
	draw_circle(ic, 5.0, Color(0.05, 0.1, 0.06, 0.7))
	if up:
		draw_colored_polygon(PackedVector2Array([ic + Vector2(0, -4), ic + Vector2(3.5, 0.5), ic + Vector2(-3.5, 0.5)]), Color(WIND, k))
		draw_rect(Rect2(ic.x - 1, ic.y, 2, 3.5), Color(WIND, k))
	else:
		draw_colored_polygon(PackedVector2Array([ic + Vector2(4, 0), ic + Vector2(-0.5, -3.5), ic + Vector2(-0.5, 3.5)]), Color(WIND, k))
		draw_rect(Rect2(ic.x - 3.5, ic.y - 1, 3.5, 2), Color(WIND, k))
	# 작은 바람 띠
	for i in 2:
		var ph := fmod(_t * 0.8 + i * 0.5, 1.0)
		var p := c + (Vector2(0, -10 - ph * 12.0) if up else Vector2(10 + ph * 12.0, -2 + i * 4))
		draw_line(p, p + (Vector2(0, -4) if up else Vector2(4, 0)), Color(WIND, 0.5 * (1.0 - ph)), 1.0)
