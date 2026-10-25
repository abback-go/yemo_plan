extends Node2D
## 참격 그림: 기울인(rot) 납작한(sq) 타원의 호. 휘두름 시간(sw) 동안 칼끝부터 펼쳐지고, 그 뒤 FADE초 동안 사라진다.
## 각도는 오른쪽을 보는 기준(아래가 +), 왼쪽을 볼 때는 좌우를 뒤집는다.

const FADE := 0.1
const SEGMENTS := 14

var swing: Dictionary = {}
var facing := 1
var _t := 0.0


func setup(data: Dictionary) -> void:
	swing = data["swing"]
	facing = int(data["facing"])
	global_position = data["at"]


func _process(delta: float) -> void:
	_t += delta
	if _t >= float(swing["sw"]) + FADE:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	if swing.is_empty():
		return
	var sw := float(swing["sw"])
	var reveal := clampf(_t / sw, 0.0, 1.0)
	var alpha := 1.0 if _t <= sw else clampf(1.0 - (_t - sw) / FADE, 0.0, 1.0)
	var r := float(swing["r"])
	var w := float(swing["w"])
	var a0 := deg_to_rad(float(swing["a0"]))
	var a1 := deg_to_rad(float(swing["a1"]))
	var sq := float(swing["sq"])
	var rot := deg_to_rad(float(swing["rot"]))
	var heavy: bool = swing.get("heavy", false)
	var color := Color(1.0, 0.95, 0.9, alpha) if not heavy else Color(1.0, 0.82, 0.86, alpha)
	var n := maxi(1, int(ceil(SEGMENTS * reveal)))
	var prev_o := _point(a0, r, sq, rot)
	var prev_i := prev_o
	for i in range(1, n + 1):
		var k := float(i) / float(SEGMENTS)
		var ang := lerpf(a0, a1, k)
		# 가운데가 가장 두껍고 양 끝은 1px — 초승달
		var thick := maxf(1.0, w * sin(PI * k))
		var o := _point(ang, r, sq, rot)
		var inn := _point(ang, r - thick, sq, rot)
		draw_primitive(PackedVector2Array([prev_o, o, inn, prev_i]), PackedColorArray([color, color, color, color]), PackedVector2Array())
		prev_o = o
		prev_i = inn


func _point(ang: float, radius: float, sq: float, rot: float) -> Vector2:
	var p := Vector2(cos(ang) * radius, sin(ang) * radius * sq).rotated(rot)
	p.x *= facing
	return p
