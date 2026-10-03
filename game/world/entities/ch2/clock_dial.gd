extends Node2D
## 톱니 시계 퍼즐의 시계판 (시계 구역 태엽 공방, docs/chapter2.md 5절).
## 불(화염탄·불기둥 등)을 맞히면 시침이 한 칸(한 시간) 돈다. 같은 group의 시계판이 모두 answer 시각을 가리키면 done_flag.
## 지금 시각은 플래그 "k_dial_<방>_<id>"에 저장된다(방을 나갔다 와도 그대로). 맞춘 뒤엔 금빛으로 굳는다.
## {t = "k_clock_dial", x, y, group = "gear", answer = 3, start = 9, label = "새벽", done_flag = "k_gears_done"}  (x·y = 중심 칸)

const KE := preload("res://enemies/ch2/k_enemy.gd")
const KArt := preload("res://world/entities/ch2/k_art.gd")
const R := 22.0

var group := ""
var answer := 12
var label := ""
var done_flag := ""
var key := ""
var hour := 12
var _t := 0.0
var _turn := 0.0
var _hurt: Area2D
var _font: Font


func setup(room: Room, e: Dictionary, eid: String) -> void:
	group = String(e.get("group", "gear"))
	answer = int(e.get("answer", 12))
	label = String(e.get("label", ""))
	done_flag = String(e.get("done_flag", ""))
	key = "k_dial_%s_%s" % [room.data.id, eid]
	hour = int(GameState.flag(key, int(e.get("start", 12))))
	position = room.tile_pos(e) + Vector2(8, 8)
	add_to_group(&"k_dial_" + group)
	z_index = -1
	_hurt = Area2D.new()
	_hurt.collision_layer = GameConst.L_ENEMY_HURT
	_hurt.collision_mask = 0
	_hurt.monitoring = false
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = R
	cs.shape = c
	_hurt.add_child(cs)
	add_child(_hurt)
	add_child(LightGlow.make(Vector2.ZERO, R * 2.2, Color("#ffc870"), 0.3))
	_font = ThemeDB.fallback_font


func solved() -> bool:
	return done_flag != "" and GameState.has_flag(done_flag)


func is_alive() -> bool:
	return not solved()


func take_hit(hit: Hit) -> void:
	if solved() or _turn > 0.0:
		return
	if hit.kind == &"ally":
		return
	hour = hour % 12 + 1
	GameState.set_flag(key, hour)
	_turn = 0.25
	KE.snd(&"chain", &"chain", -2.0, 0.1)
	KE.snd(&"bell_small", &"blip", -6.0)
	Fx.burst(global_position, 6, {spread = 180.0, speed_min = 20.0, speed_max = 80.0, lifetime = 0.3,
		gradient = Palette.fade_gradient(Color("#ffd27a")), add = true})
	_check()


func _check() -> void:
	for n in get_tree().get_nodes_in_group(&"k_dial_" + group):
		if int(n.get("hour")) != int(n.get("answer")):
			return
	if done_flag != "" and not GameState.has_flag(done_flag):
		GameState.set_flag(done_flag)
		KE.snd(&"bell", &"checkpoint", 2.0)
		Fx.shake(0.3, 0.6)


func _process(delta: float) -> void:
	_t += delta
	_turn = maxf(_turn - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	var ok := solved()
	var rim := Color("#c8a040") if ok else Color("#6a4e20")
	KArt.gear(self, Vector2.ZERO, R + 7.0, _t * 0.1 * (1.0 if ok else 0.3), Color("#4a3a28"), Color("#1a120c"), 6)
	draw_circle(Vector2.ZERO, R + 1.0, Color("#07060c"))
	draw_circle(Vector2.ZERO, R, Color("#e0cc9a") if not ok else Color("#fff0c0"))
	draw_arc(Vector2.ZERO, R - 2.0, 0, TAU, 32, rim, 1.0)
	for i in 12:
		var a := TAU * i / 12.0 - PI * 0.5
		var big := i % 3 == 0
		draw_line(Vector2(cos(a), sin(a)) * (R - (6.0 if big else 4.0)), Vector2(cos(a), sin(a)) * (R - 2.0), Color("#3a2a20"), 2.0 if big else 1.0)
	# 시침 (돌 때 살짝 튐)
	var shown := float(hour) - _turn * 4.0
	var ha := TAU * shown / 12.0 - PI * 0.5
	draw_line(Vector2.ZERO, Vector2(cos(ha), sin(ha)) * (R - 7.0), Color("#2a1a10"), 3.0)
	draw_circle(Vector2(cos(ha), sin(ha)) * (R - 7.0), 2.0, Color("#2a1a10"))
	draw_circle(Vector2.ZERO, 3.0, rim)
	# 이름표 (새벽·정오·저녁)
	if label != "":
		var lw := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		draw_rect(Rect2(-lw * 0.5 - 3, R + 8, lw + 6, 13), Color(0.05, 0.04, 0.06, 0.8))
		draw_string(_font, Vector2(-lw * 0.5, R + 18), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#ffd27a"))
	if ok:
		draw_circle(Vector2.ZERO, R + 4.0 + sin(_t * 3.0), Color(1.0, 0.85, 0.4, 0.15))
