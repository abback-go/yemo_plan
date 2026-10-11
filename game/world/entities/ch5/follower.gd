extends Node2D
## 따라오는 학생들 (docs/archive/sera/chapter5.md 8.6절 절망): 무너지는 학교에서 세라 뒤를 줄지어 따라온다. 싸우지 않고 맞지도 않는다.
## 방 데이터: {t = "st_follow", id, who = ["pippa", "student_a"], cond = "..."}
## 방에 들어오면 세라 뒤에 나타나고, 세라가 서 있는 바닥 높이를 따라 걷거나 뛰어오른다(막히면 순간이동).
## 대본: actor_id() = "followers" — c.actor("followers").scatter() 겁먹어 웅크림 · gather() 다시 따라옴 · say(i, 글, 초)

const T := 16.0
const GAP := 18.0

var who: Array[String] = []
var _kids: Array[Dictionary] = [] ## {node, visual, pos, vy, bubble, bubble_t}
var _scared := false
var _font: Font
var _t := 0.0


func setup(_room: Room, e: Dictionary, _eid: String) -> void:
	for w in e.get("who", ["student_a", "student_b"]):
		who.append(String(w))
	z_index = 1
	_font = ThemeDB.fallback_font


func actor_id() -> String:
	return "followers"


func _ready() -> void:
	var p := _player()
	var base := p.global_position if p else global_position
	var dir := float(p.facing) if p else 1.0
	for i in who.size():
		var flip := Node2D.new()
		add_child(flip)
		var v := CharacterVisual.new()
		v.setup(who[i])
		flip.add_child(v)
		var pos := base + Vector2(-dir * GAP * (i + 1), 0)
		flip.global_position = pos
		_kids.append({"node": flip, "visual": v, "pos": pos, "vy": 0.0, "bubble": "", "bubble_t": 0.0})


func _player() -> Player:
	return get_tree().get_first_node_in_group(GameConst.GROUP_PLAYER) as Player


## 겁먹어 웅크림 (거신의 발소리 등)
func scatter() -> void:
	_scared = true
	for k in _kids:
		(k.visual as CharacterVisual).set_pose("hurt")


func gather() -> void:
	_scared = false
	for k in _kids:
		(k.visual as CharacterVisual).set_pose("idle")


func say(i: int, text: String, sec := 2.4) -> void:
	if i < 0 or i >= _kids.size():
		return
	_kids[i].bubble = text
	_kids[i].bubble_t = sec


func _physics_process(delta: float) -> void:
	_t += delta
	var p := _player()
	if p == null:
		return
	var lead := p.global_position
	for i in _kids.size():
		var k: Dictionary = _kids[i]
		var node: Node2D = k.node
		var v: CharacterVisual = k.visual
		var pos: Vector2 = k.pos
		k.bubble_t = maxf(float(k.bubble_t) - delta, 0.0)
		if _scared:
			v.walking = false
		else:
			var want := lead.x - float(p.facing) * GAP * (i + 1)
			var dx := want - pos.x
			if absf(dx) > 3.0:
				var sp := 150.0 if absf(dx) > 60.0 else 100.0
				pos.x += clampf(dx, -sp * delta, sp * delta)
				node.scale.x = signf(dx)
				v.walking = true
			else:
				v.walking = false
				node.scale.x = 1.0 if p.global_position.x > pos.x else -1.0
		# 바닥 높이 따라가기 (간단한 낙하 + 오르기)
		var gy := _ground(pos)
		if gy < pos.y - 40.0 or (lead.distance_to(pos) > 26.0 * T):
			# 너무 높은 턱이나 너무 멀어짐 → 세라 곁으로 순간이동
			pos = lead + Vector2(-float(p.facing) * GAP * (i + 1), 0)
			k.vy = 0.0
			Fx.burst(pos + Vector2(0, -14), 8, {spread = 180.0, speed_min = 20.0, speed_max = 60.0, lifetime = 0.3,
				gradient = Palette.fade_gradient(Color(1, 1, 1, 0.7)), add = true})
		elif gy < pos.y - 1.0:
			pos.y = move_toward(pos.y, gy, 220.0 * delta)
			k.vy = 0.0
		elif gy > pos.y + 1.0:
			k.vy = minf(float(k.vy) + 900.0 * delta, 420.0)
			pos.y = minf(pos.y + float(k.vy) * delta, gy)
		else:
			k.vy = 0.0
		k.pos = pos
		node.global_position = pos
	queue_redraw()


func _ground(pos: Vector2) -> float:
	var q := PhysicsRayQueryParameters2D.create(pos + Vector2(0, -36), pos + Vector2(0, 14.0 * T), GameConst.L_WORLD | GameConst.L_PLATFORM)
	var r := get_world_2d().direct_space_state.intersect_ray(q)
	if r.is_empty():
		return pos.y
	return float((r.position as Vector2).y)


func _draw() -> void:
	for k in _kids:
		if float(k.bubble_t) <= 0.0 or String(k.bubble) == "":
			continue
		var p: Vector2 = (k.pos as Vector2) - global_position + Vector2(0, -50)
		var txt := String(k.bubble)
		var w := _font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 10.0
		draw_rect(Rect2(p + Vector2(-w * 0.5, -12), Vector2(w, 16)), Color(0.04, 0.03, 0.08, 0.85))
		draw_string(_font, p + Vector2(-w * 0.5 + 5, 0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_TEXT)
