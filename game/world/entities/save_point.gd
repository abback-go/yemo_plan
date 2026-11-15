class_name SavePoint
extends Interactable
## 기록 지점: ↑로 기록하면 체력·물약 회복 + 저장 + 쓰러졌을 때 돌아올 곳으로 지정.
## style: candle(촛대 마법진) · lantern(신계 여우 석등) · bed(침대) · statue(창립자 동상)

var save_id := ""
var style := "candle"
var _t := 0.0
var _flash := 0.0
var _glow: LightGlow


func setup(p_room: Room, e: Dictionary, eid: String) -> void:
	room = p_room
	save_id = eid
	style = String(e.get("style", "candle"))
	position = room.tile_pos(e) + Vector2(8, 0)
	prompt = "쉬기" if style == "bed" else "기록하기"
	area_size = Vector2(34, 40)
	z_index = -1
	var col := Color(0.55, 0.8, 1.0) if style == "lantern" else Color(1.0, 0.8, 0.45)
	_glow = LightGlow.make(Vector2(0, -18), 52.0, col, 0.35)
	_glow.z_index = -1
	add_child(_glow)


func interact() -> void:
	_flash = 1.0
	GameState.heal_full()
	var w := World.get_world()
	if w:
		w.player.restore_from_state()
		w.player.overload = 0.0
	GameState.record_at(room.data.id, save_id)
	Sfx.play(&"checkpoint", 0.0, 0.0)
	Music.jingle("jingle_save")
	Fx.ring(global_position + Vector2(0, -16), 6.0, 46.0, Color(1.0, 0.85, 0.5), 0.5, 2.0)
	Fx.burst(global_position + Vector2(0, -10), 24, {
		direction = Vector2.UP, spread = 60.0, speed_min = 20.0, speed_max = 70.0, lifetime = 1.0,
		gradient = Palette.fade_gradient(Color(1.0, 0.85, 0.5)), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, -20),
		add = true,
	})
	Story.toast("기록했다. 체력과 물약이 회복되었다." if GameState.potions_max > 0 else "기록했다. 체력이 회복되었다.")


func _process(delta: float) -> void:
	_t += delta
	_flash = maxf(_flash - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	var glow := 0.6 + 0.4 * sin(_t * 2.0) + _flash
	match style:
		"candle", "statue":
			# 바닥 마법진
			var c := Color(1.0, 0.8, 0.45, 0.25 + 0.15 * glow)
			draw_arc(Vector2(0, -1), 14.0, 0, TAU, 28, c, 1.0)
			for i in 6:
				var a := _t * 0.4 + TAU * i / 6.0
				draw_line(Vector2(cos(a), sin(a) * 0.3) * 14.0 + Vector2(0, -1), Vector2(cos(a + 2.1), sin(a + 2.1) * 0.3) * 14.0 + Vector2(0, -1), c, 1.0)
			if style == "statue":
				draw_rect(Rect2(-9, -8, 18, 8), Color("#3a3650"))
				var body := PackedVector2Array([Vector2(-6, -8), Vector2(6, -8), Vector2(4, -30), Vector2(0, -36), Vector2(-4, -30)])
				draw_colored_polygon(body, Color("#4a4666"))
				draw_colored_polygon(PackedVector2Array([Vector2(-7, -34), Vector2(7, -34), Vector2(1, -48)]), Color("#3a3650"))
				draw_circle(Vector2(5, -26), 2.0 + glow, Color(1.0, 0.85, 0.5, 0.8))
			else:
				# 촛대 세 개
				for i in 3:
					var x := -8.0 + i * 8.0
					var h := 10.0 + (4.0 if i == 1 else 0.0)
					draw_rect(Rect2(x - 1.5, -h - 2, 3, h), Color("#e8dcc0"))
					draw_rect(Rect2(x - 3, -2, 6, 2), Color("#8a6a3a"))
					var fl := sin(_t * 9.0 + i) * 0.8
					draw_colored_polygon(PackedVector2Array([Vector2(x - 2, -h - 2), Vector2(x + fl, -h - 8 - glow * 1.5), Vector2(x + 2, -h - 2)]), Color(1.0, 0.75, 0.35))
					draw_circle(Vector2(x, -h - 4), 1.2, Color(1, 0.95, 0.8))
		"lantern":
			# 여우 석등
			var stone := Color("#4a4a5e")
			draw_rect(Rect2(-6, -4, 12, 4), stone)
			draw_rect(Rect2(-2, -16, 4, 12), stone)
			draw_rect(Rect2(-8, -26, 16, 10), stone.lightened(0.1))
			draw_rect(Rect2(-5, -24, 10, 6), Color(0.45, 0.75, 1.0, 0.5 + 0.3 * glow))
			draw_colored_polygon(PackedVector2Array([Vector2(-11, -26), Vector2(11, -26), Vector2(0, -34)]), stone)
			draw_colored_polygon(PackedVector2Array([Vector2(-3, -33), Vector2(-1, -38), Vector2(0, -33)]), stone)
			draw_colored_polygon(PackedVector2Array([Vector2(3, -33), Vector2(1, -38), Vector2(0, -33)]), stone)
		"bed":
			draw_rect(Rect2(-18, -10, 36, 8), Color("#6a3a3a"))
			draw_rect(Rect2(-18, -12, 36, 3), Color("#e8dcc8"))
			draw_rect(Rect2(-18, -16, 8, 6), Color("#f0e8d8"))
			draw_rect(Rect2(-20, -18, 3, 18), Color("#4a2e22"))
			draw_rect(Rect2(17, -12, 3, 12), Color("#4a2e22"))
			draw_rect(Rect2(-6, -11, 22, 2), Color("#8a3a4a"))
