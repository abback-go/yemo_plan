class_name Pickup
extends Area2D
## 줍는 물건. 닿으면 얻는다(영구). kind:
##   feather    수호의 깃털 (최대 체력 +1)
##   moonherb   월광초 (피피의 부탁)
##   key        열쇠·이야기 물건 (flag 키로 플래그를 세움, name으로 이름 표시)
##   page       기록 조각 (text를 읽음)
##   stone      마도석 (마법 레벨을 올리는 재료, docs/magic.md 2절)
##   note       쪽지 (page와 같음)

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
	if kind == "stone":
		col = Color(0.75, 0.5, 1.0)
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
			Rewards.add_max_hp(1)
			GameState.add("secrets")
			Story.item_get("수호의 깃털", "최대 체력이 1 늘었다.", "feather")
		"moonherb":
			Story.item_get("월광초", "달빛을 머금은 약초. 피피가 찾던 것이다.", "herb")
		"key":
			Story.item_get(item_name, String(text), "key")
		"page", "note":
			GameState.add("secrets")
			Story.read(([item_name] if item_name != "" else []) + Array(text.split("|")))
		"stone":
			Spells.add_stones(1)
			GameState.add("secrets")
			Story.toast("마도석을 얻었다. (가진 마도석 %d개 — 마법서에서 마법 레벨을 올릴 수 있다)" % Spells.stones(), 2.6)
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
		"stone":
			# 보라 결정: 마름모 + 빛나는 면
			var g := 0.6 + 0.4 * sin(_t * 4.0)
			draw_colored_polygon(PackedVector2Array([Vector2(0, -8 + y), Vector2(5, -1 + y), Vector2(0, 7 + y), Vector2(-5, -1 + y)]), Color("#7a4ad8"))
			draw_colored_polygon(PackedVector2Array([Vector2(0, -8 + y), Vector2(5, -1 + y), Vector2(0, 1 + y)]), Color("#c8a0ff"))
			draw_circle(Vector2(-1, -3 + y), 1.2, Color(1, 1, 1, g))
		"page", "note":
			draw_rect(Rect2(-5, -6 + y, 10, 12), Color("#e8dcc0"))
			for i in 3:
				draw_rect(Rect2(-3, -3 + i * 3 + y, 6, 1), Color("#8a7a6a"))
