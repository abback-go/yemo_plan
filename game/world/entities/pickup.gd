class_name Pickup
extends Area2D
## 줍는 물건. 닿으면 얻는다(영구). kind:
##   feather    수호의 깃털 (최대 체력 +1)
##   moonherb   월광초 (피피의 부탁)
##   key        열쇠·이야기 물건 (flag 키로 플래그를 세움, name으로 이름 표시)
##   page       기록 조각 (text를 읽음)

var pick_id := ""
var kind := "feather"
var item_name := ""
var set_flag := ""
var text := ""
var _t := 0.0
var _taken := false


func setup(room: Room, e: Dictionary, eid: String) -> void:
	pick_id = eid
	kind = String(e.get("kind", "feather"))
	item_name = String(e.get("name", ""))
	set_flag = String(e.get("flag", ""))
	text = String(e.get("text", ""))
	position = room.tile_pos(e) + Vector2(8, -10)
	collision_layer = 0
	collision_mask = GameConst.L_PLAYER
	monitoring = true
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 10
	cs.shape = c
	add_child(cs)
	body_entered.connect(_on_body)
	var col := Color(1.0, 0.9, 0.5) if kind != "moonherb" else Color(0.7, 0.9, 1.0)
	add_child(LightGlow.make(Vector2.ZERO, 30.0, col, 0.4))


func _on_body(b: Node) -> void:
	if _taken or not b is Player:
		return
	_taken = true
	GameState.mark_collected(pick_id)
	Sfx.play(&"pickup", 0.0, 0.0)
	Fx.ring(global_position, 4.0, 30.0, Color(1.0, 0.9, 0.6), 0.4, 2.0)
	Fx.burst(global_position, 20, {spread = 180.0, speed_min = 30.0, speed_max = 90.0, lifetime = 0.6,
		gradient = Palette.fade_gradient(Color(1.0, 0.9, 0.6)), gravity = Vector2(0, -20), add = true})
	if set_flag != "":
		GameState.set_flag(set_flag)
	match kind:
		"feather":
			GameState.max_hp += 1
			GameState.hp = GameState.max_hp
			GameState.add("secrets")
			var w := World.get_world()
			if w:
				w.player.restore_from_state()
			Story.item_get("수호의 깃털", "최대 체력이 1 늘었다.", "feather")
		"moonherb":
			Story.item_get("월광초", "달빛을 머금은 약초. 피피가 찾던 것이다.", "herb")
		"key":
			Story.item_get(item_name, String(text), "key")
		"page":
			GameState.add("secrets")
			Story.read(([item_name] if item_name != "" else []) + Array(text.split("|")))
	queue_free()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var y := sin(_t * 2.5) * 2.0
	match kind:
		"feather":
			var pts := PackedVector2Array([Vector2(0, -8 + y), Vector2(4, -2 + y), Vector2(2, 6 + y), Vector2(-1, 7 + y), Vector2(-3, -1 + y)])
			draw_colored_polygon(pts, Color("#f4eaff"))
			draw_line(Vector2(0, -7 + y), Vector2(0, 8 + y), Color("#c8b0ff"), 1.0)
		"moonherb":
			draw_line(Vector2(0, 8), Vector2(0, -2 + y), Color("#4a8a5a"), 1.0)
			for i in 5:
				var a := TAU * i / 5.0 + _t * 0.5
				draw_circle(Vector2(cos(a), sin(a)) * 3.0 + Vector2(0, -4 + y), 2.0, Color("#bfe8ff"))
			draw_circle(Vector2(0, -4 + y), 1.5, Color("#ffffff"))
		"key":
			draw_circle(Vector2(-3, y), 3.0, Color("#e8c060"))
			draw_circle(Vector2(-3, y), 1.2, Color("#3a2a10"))
			draw_rect(Rect2(0, y - 1, 8, 2), Color("#e8c060"))
			draw_rect(Rect2(6, y + 1, 2, 3), Color("#e8c060"))
		"page":
			draw_rect(Rect2(-5, -6 + y, 10, 12), Color("#e8dcc0"))
			for i in 3:
				draw_rect(Rect2(-3, -3 + i * 3 + y, 6, 1), Color("#8a7a6a"))
