extends Node2D
## 진짜 종 (docs/chapter4.md 4절·5절·7.5절): 천장에 매달린 청동 종. **불기둥**(아래에서 솟는 큰 불)으로 울린다.
## 울리면: 크게 흔들리며 금빛 소리 고리가 퍼지고, 근처(13칸)의 종지기 망령(bell_wraith)이 3초 동안 귀를 막고 주저앉는다(빈틈).
## 화염탄은 "팅" 소리만 나고 울리지 않는다. 종 퍼즐(박자·순서)을 위해 rung 신호와 note·group·order를 둔다.
## 방 데이터: {t:"temple_bell", x, y(종 아래 바닥 행), top(매다는 천장 행), size("big"|"small"), hang(종 아래끝이 바닥에서 몇 칸 위, 기본 big 3·small 3.5),
##            note(음 0~6), group, order, id}
## 불기둥 표적이 되도록 pillar_target 무리에 들고, 위치(원점)는 종 아래 바닥 — 불기둥이 그 자리에서 솟아 종까지 닿는다(기둥 높이 7칸 안).

signal rung(bell: Node)

const ART := preload("res://world/entities/ch4/art.gd")
const H := preload("res://enemies/ch4/holy.gd")
const RING_KINDS: Array[StringName] = [&"pillar", &"fox_pillar", &"blast", &"storm_final", &"meteor", &"phoenix", &"reflect", &"ally"]
const STUN_RADIUS := 13.0 * 16.0
const STUN_TIME := 3.0
const PITCH := [0.8, 0.9, 1.0, 1.12, 1.26, 1.34, 1.5]

var bell_id := ""
var size := 28.0
var top_y := 0.0 ## 매단 곳 (지역 y, 음수)
var bell_top := 0.0 ## 종 머리 (지역 y)
var note := 0
var group := ""
var order := 0
var _swing := 0.0
var _swing_v := 0.0
var _t := 0.0
var _cool := 0.0
var _glow := 0.0
var _hurt: Area2D


func setup(room: Room, e: Dictionary, eid: String) -> void:
	bell_id = eid
	position = room.tile_pos(e) + Vector2(8, 0)
	var big := String(e.get("size", "big")) == "big"
	size = 28.0 if big else 16.0
	var hang := float(e.get("hang", 3.0 if big else 3.5)) * 16.0
	bell_top = -hang - size
	var top_row := float(e.get("top", float(e.get("y", 0)) - 10.0))
	top_y = top_row * 16.0 - position.y
	note = int(e.get("note", 2))
	group = String(e.get("group", ""))
	order = int(e.get("order", 0))
	z_index = -1
	_t = randf() * 4.0


func _ready() -> void:
	add_to_group(&"temple_bell")
	add_to_group(&"pillar_target")
	_hurt = Area2D.new()
	_hurt.collision_layer = GameConst.L_ENEMY_HURT
	_hurt.collision_mask = 0
	_hurt.monitoring = false
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(size, size)
	cs.shape = rs
	cs.position = Vector2(0, bell_top + size * 0.5)
	_hurt.add_child(cs)
	add_child(_hurt)


func is_alive() -> bool:
	return _cool <= 0.0


func is_on_floor() -> bool:
	return true


func bell_center() -> Vector2:
	return global_position + Vector2(0, bell_top + size * 0.6)


func take_hit(hit: Hit) -> void:
	if hit.kind in RING_KINDS or EnemyBase.is_fox_hit(hit) and hit.kind != &"foxfire" and hit.kind != &"foxfire_heavy":
		ring()
	else:
		# 화염탄: "팅" — 살짝 흔들릴 뿐
		_swing_v += 0.6 * (1.0 if hit.source_pos.x < global_position.x else -1.0)
		H.snd_pitch(&"bell_small", &"block", 1.6 + note * 0.05, -10.0)


func ring() -> void:
	if _cool > 0.0:
		return
	_cool = 0.5
	_glow = 1.0
	_swing_v += 3.5 * (1.0 if randf() < 0.5 else -1.0)
	var c := bell_center()
	var pitch: float = PITCH[clampi(note, 0, PITCH.size() - 1)] * (0.75 if size > 20.0 else 1.25)
	H.snd_pitch(&"bell", &"checkpoint", pitch, 2.0)
	Fx.shake(0.12, 0.3)
	for i in 3:
		var tw := create_tween()
		tw.tween_interval(i * 0.18)
		tw.tween_callback(func() -> void: Fx.ring(c, 6.0, 90.0 + i * 30.0, Color(1.0, 0.88, 0.5, 0.8 - i * 0.2), 0.7, 3.0 - i))
	H.sparkle(c, 16, 10.0, 10.0, 0.8)
	# 근처 종지기 망령을 멈춤
	for w in get_tree().get_nodes_in_group(&"bell_wraith"):
		var n := w as Node2D
		if n and n.global_position.distance_to(c) <= STUN_RADIUS and n.has_method("bell_stun"):
			n.call("bell_stun", STUN_TIME)
	rung.emit(self)


func _process(delta: float) -> void:
	_t += delta
	_cool = maxf(_cool - delta, 0.0)
	_glow = maxf(_glow - delta * 0.6, 0.0)
	# 진자: 되돌아오는 힘 + 감쇠
	_swing_v += -_swing * 18.0 * delta
	_swing_v *= pow(0.4, delta)
	_swing += _swing_v * delta
	queue_redraw()


func _draw() -> void:
	var pivot := Vector2(0, top_y)
	var rope := bell_top - top_y
	draw_rect(Rect2(-size * 0.45, top_y - 2, size * 0.9, 4), Color("#3a281c"))
	draw_rect(Rect2(-size * 0.45, top_y - 2, size * 0.9, 1), Color("#8a6440"))
	var ang := _swing * 0.25 + sin(_t * 1.1) * 0.02
	if _glow > 0.0:
		ART.glow(self, Vector2(0, bell_top + size * 0.6), size * 1.6, Color(1.0, 0.85, 0.45), 0.6 * _glow)
	ART.bell(self, pivot, rope, size, ang, ART.BELL_METAL, 0.0, 0.5 + _glow * 0.5)
