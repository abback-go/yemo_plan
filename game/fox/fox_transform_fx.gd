class_name FoxTransformFx
extends Node2D
## 빙의 순간 연출 (docs/chapter1.md 4.8절): 시간이 멈추고 세라 뒤로 거대한 구미호 환영 → 푸른 번쩍임·고리 →
## "빙의 — 여우 모드". 주변 적은 푸른 불길에 밀려난다(의태하며 깃드는 힘).

var player: Player
var _t := 0.0
const LIFE := 1.2


func setup(p: Player) -> void:
	player = p
	global_position = p.global_position


func _ready() -> void:
	z_index = -4
	material = Fx.add_material
	Fx.hitstop(0.35)
	Fx.flash(Color(0.5, 0.8, 1.0, 0.6), 0.5)
	Fx.zoom_punch(0.1)
	Fx.shake(0.3, 0.5)
	Sfx.play(&"fox_transform", 2.0, 0.0)
	Fx.ring(player.center(), 6.0, 90.0, Color(0.55, 0.85, 1.0), 0.6, 3.0)
	Fx.ring(player.center(), 6.0, 60.0, Color(0.9, 0.97, 1.0), 0.45, 2.0)
	Fx.burst(player.center(), 70, {spread = 180.0, speed_min = 60.0, speed_max = 240.0, damping = 140.0, lifetime = 0.8,
		gradient = Palette.fade_gradient(Color(0.55, 0.85, 1.0)), add = true, size_min = 1.5, size_max = 3.5})
	for e in get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
		if e.is_alive() and e.global_position.distance_to(player.global_position) < 5.0 * GameConst.TILE:
			var h := Hit.make(30, &"fox_burst", player.center())
			h.knockback_t = 3.0
			h.ignores_knock_resist = true
			h.breaks_charge = true
			e.take_hit(h)
	var hud := get_tree().get_first_node_in_group(&"hud")
	if hud and hud.has_method("banner"):
		hud.banner("빙의 — 여우 모드", 1.4)


func _process(delta: float) -> void:
	_t += delta / maxf(Engine.time_scale, 0.05)
	if is_instance_valid(player):
		global_position = player.global_position
	if _t >= LIFE:
		queue_free()
	queue_redraw()


func _draw() -> void:
	# 거대한 구미호 환영: 머리 실루엣 + 아홉 꼬리
	var k := clampf(_t / 0.25, 0.0, 1.0)
	var fade := clampf((LIFE - _t) / 0.5, 0.0, 1.0)
	var a := 0.45 * k * fade
	var c := Vector2(0, -60)
	for i in 9:
		var ang := -PI * 0.5 + (i - 4) * 0.3 + sin(_t * 3.0 + i) * 0.05
		var tip := c + Vector2(cos(ang), sin(ang)) * 130.0 * k
		draw_line(c + Vector2(0, 30), tip, Color(0.35, 0.65, 1.0, a * 0.6), 16.0)
		draw_circle(tip, 9.0, Color(0.55, 0.85, 1.0, a))
	var head := PackedVector2Array([
		c + Vector2(-40, 10), c + Vector2(-54, -50), c + Vector2(-22, -24), c + Vector2(22, -24),
		c + Vector2(54, -50), c + Vector2(40, 10), c + Vector2(0, 46),
	])
	draw_colored_polygon(head, Color(0.4, 0.7, 1.0, a))
	draw_rect(Rect2(c + Vector2(-22, -6), Vector2(12, 4)), Color(0.9, 0.97, 1.0, a * 2.0))
	draw_rect(Rect2(c + Vector2(10, -6), Vector2(12, 4)), Color(0.9, 0.97, 1.0, a * 2.0))
