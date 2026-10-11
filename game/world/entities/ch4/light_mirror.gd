extends Interactable
## 빛의 거울 (docs/archive/sera/chapter4.md 5절·7.5절): 빛줄기(빛의 감시안·광원)를 꺾는다. 금 고리에 끼운 거울판.
## 방 데이터: {t:"light_mirror", x, y(바닥 행), angle(도, 기본 45 — '/'), angles([45,135] — 돌릴 때 차례로), fixed(true면 못 돌림), id}
## 돌리기: ↑(조사) 또는 불기둥을 맞히면 다음 각도로 (돌린 각도는 방을 나가도 기억: 플래그 "mir_<방>_<id>").
## 빛줄기 추적(holy.gd trace)이 segment()·reflect_dir()를 부른다.

const ART := preload("res://world/entities/ch4/art.gd")
const H := preload("res://enemies/ch4/holy.gd")
const CENTER := Vector2(0, -28)
const HALF := 11.0

var angles: Array = [45.0, 135.0]
var angle_deg := 45.0
var fixed := false
var mir_id := "" ## 방 데이터의 id (시험 실행기 hitg 거르기용)
var _key := ""
var _shown := 45.0
var _t := 0.0
var _lit := 0.0
var _hurt: Area2D


func setup(p_room: Room, e: Dictionary, eid: String) -> void:
	room = p_room
	position = room.tile_pos(e) + Vector2(8, 0)
	angle_deg = float(e.get("angle", 45.0))
	angles = e.get("angles", [angle_deg, angle_deg + 90.0])
	fixed = bool(e.get("fixed", false))
	mir_id = eid
	_key = "mir_%s_%s" % [room.data.id, eid]
	if GameState.flags.has(_key):
		angle_deg = float(GameState.flag(_key))
	_shown = angle_deg
	prompt = "거울 돌리기" if not fixed else "빛의 거울"
	area_size = Vector2(30, 40)
	z_index = 2


func _ready() -> void:
	super()
	add_to_group(&"light_mirror")
	if not fixed:
		add_to_group(&"pillar_target")
	_hurt = Area2D.new()
	_hurt.collision_layer = GameConst.L_ENEMY_HURT if not fixed else 0
	_hurt.collision_mask = 0
	_hurt.monitoring = false
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(16, 30)
	cs.shape = rs
	cs.position = Vector2(0, -16)
	_hurt.add_child(cs)
	add_child(_hurt)


func can_interact() -> bool:
	return not fixed and is_visible_in_tree()


func interact() -> void:
	rotate_next()


## 불기둥 표적 (FirePillar가 부름)
func is_alive() -> bool:
	return not fixed


func is_on_floor() -> bool:
	return true


func take_hit(hit: Hit) -> void:
	if fixed:
		return
	if hit.kind in [&"pillar", &"fox_pillar", &"blast", &"storm_final"]:
		rotate_next()


func rotate_next() -> void:
	var i := 0
	for k in angles.size():
		if absf(float(angles[k]) - angle_deg) < 1.0:
			i = k
	angle_deg = float(angles[(i + 1) % angles.size()])
	GameState.set_flag(_key, angle_deg)
	H.snd(&"chain", &"chain", -4.0)
	Sfx.play(&"block", -8.0, 0.1)
	H.sparkle(global_position + CENTER, 8, 8.0)


func segment() -> Array:
	var a := deg_to_rad(_shown)
	var d := Vector2(sin(a), -cos(a))
	var c := global_position + CENTER
	return [c - d * HALF, c + d * HALF]


func reflect_dir(v: Vector2) -> Vector2:
	_lit = 0.2
	var a := deg_to_rad(_shown)
	var d := Vector2(sin(a), -cos(a))
	var n := Vector2(-d.y, d.x)
	return (v - 2.0 * v.dot(n) * n).normalized()


func _process(delta: float) -> void:
	_t += delta
	_lit = maxf(_lit - delta, 0.0)
	_shown = move_toward(_shown, angle_deg, delta * 360.0)
	queue_redraw()


func _draw() -> void:
	ART.mirror(self, CENTER, deg_to_rad(_shown), _t, clampf(_lit * 5.0, 0.0, 1.0))
	if not fixed:
		# 돌릴 수 있다는 표시: 고리 둘레의 작은 화살표 점
		var a := _t * 1.5
		draw_circle(CENTER + Vector2(cos(a), sin(a)) * 15.0, 1.0, Color(1.0, 0.9, 0.6, 0.6))
