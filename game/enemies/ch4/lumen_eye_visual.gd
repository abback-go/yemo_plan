extends Node2D
## 빛의 감시안 그림: 흰 눈알 + 금빛 홍채 + 둘레를 천천히 도는 여섯 갈래 빛 날개 + 금속 눈꺼풀.
## 평소엔 반쯤 감은 눈, 조준할 때 크게 뜨고 눈동자가 바늘처럼 좁아지며 붉은 조준선을 긋는다. 쏜 뒤엔 홍채가 붉게 달아오른다.
## 빛줄기는 가산 합성 자식 노드(_beam)가 그린다.

const H := preload("res://enemies/ch4/holy.gd")
const OUTL := Color("#16101f")
const METAL := Color("#e8e2f0")
const METAL_S := Color("#9a94b8")
const GOLD := Color("#e9b949")
const DANGER := Color("#ff3b3b")

var enemy: LumenEye
var _beam: BeamDraw
var _open := 0.5


class BeamDraw extends Node2D:
	var eye: LumenEye

	func _ready() -> void:
		material = Fx.add_material
		z_index = 6
		top_level = true

	func _process(_d: float) -> void:
		global_position = Vector2.ZERO
		queue_redraw()

	func _draw() -> void:
		if eye == null or not is_instance_valid(eye):
			return
		if eye.beam_pts.size() >= 2:
			var fl := 0.85 + 0.15 * sin(eye._t * 40.0)
			var src := eye.state == LumenEye.S.SOURCE
			H.draw_beam(self, eye.beam_pts, LumenEye.BEAM_W if not src else 5.0, Color(1.0, 0.82, 0.4), Color(1.0, 0.98, 0.85), fl)
			var endp := eye.beam_pts[eye.beam_pts.size() - 1]
			draw_circle(endp, 6.0 + 2.0 * sin(eye._t * 30.0), Color(1.0, 0.9, 0.6, 0.6))
		for line in eye.aim_lines():
			var pts: PackedVector2Array = line
			if pts.size() < 2:
				continue
			var k := eye.progress()
			var pulse := 0.5 + 0.5 * sin(eye._t * 30.0)
			draw_polyline(pts, Color(DANGER, 0.12 + 0.2 * k), 5.0)
			draw_polyline(pts, Color(DANGER, (0.45 + 0.4 * k) * (0.6 + 0.4 * pulse)), 1.0)


func _ready() -> void:
	_beam = BeamDraw.new()
	_beam.eye = enemy
	add_child(_beam)


func _process(delta: float) -> void:
	if enemy == null:
		return
	var want := 0.45
	match enemy.state:
		LumenEye.S.AIM, LumenEye.S.SWEEP, LumenEye.S.SOURCE:
			want = 1.0
		LumenEye.S.HOT:
			want = 0.75
	_open = move_toward(_open, want, delta * 3.0)


func _draw() -> void:
	if enemy == null:
		return
	var white := enemy.flash_amount() > 0.0
	var t := enemy._t
	var c := Vector2(0, -11)
	var st := enemy.state
	# 빛 무리
	draw_circle(c, 18.0, Color(1.0, 0.86, 0.45, 0.06))
	# 여섯 갈래 빛 날개 (천천히 돌고 숨쉬듯 길어졌다 짧아짐)
	for i in 6:
		var a := t * 0.4 + TAU * i / 6.0
		var ln := 13.0 + 2.0 * sin(t * 2.0 + i)
		var d := Vector2(cos(a), sin(a))
		var n := Vector2(-d.y, d.x)
		var root := c + d * 8.0
		var tip := c + d * ln
		draw_colored_polygon(PackedVector2Array([root + n * 2.5, tip, root - n * 2.5]), Color.WHITE if white else Color(1.0, 0.88, 0.5, 0.85))
		draw_line(root, tip, Color(1.0, 0.98, 0.85, 0.9), 1.0)
	# 금 테
	draw_circle(c, 9.5, OUTL)
	draw_circle(c, 8.5, GOLD if not white else Color.WHITE)
	# 눈알
	draw_circle(c, 7.0, Color("#fbf7ee") if not white else Color.WHITE)
	var look := enemy.look_dir.normalized() if enemy.look_dir.length() > 0.1 else Vector2.LEFT
	var ic := c + look * 2.2
	var iris := Color(1.0, 0.75, 0.25)
	if st == LumenEye.S.HOT:
		iris = Color(1.0, 0.45, 0.2).lerp(Color(1.0, 0.75, 0.25), enemy.progress())
	elif st == LumenEye.S.AIM:
		iris = iris.lerp(DANGER, enemy.progress() * 0.6)
	draw_circle(ic, 4.0, iris)
	draw_circle(ic, 2.6, iris.darkened(0.25))
	var pupil_w := 1.6
	if st == LumenEye.S.AIM:
		pupil_w = lerpf(1.6, 0.6, enemy.progress())
	draw_rect(Rect2(ic.x - pupil_w * 0.5, ic.y - 2.4, pupil_w, 4.8), Color("#1a1020"))
	draw_rect(Rect2(ic + Vector2(-2.0, -2.2), Vector2(1, 1)), Color(1, 1, 1, 0.9))
	# 눈꺼풀 (금속): _open이 작을수록 덮임
	var lid := (1.0 - _open) * 7.0
	if lid > 0.3:
		draw_rect(Rect2(c + Vector2(-8, -8), Vector2(16, lid + 1.0)), METAL if not white else Color.WHITE)
		draw_rect(Rect2(c + Vector2(-8, -8 + lid), Vector2(16, 1)), OUTL)
		draw_rect(Rect2(c + Vector2(-8, 7 - lid * 0.6), Vector2(16, lid * 0.6 + 1.0)), METAL_S if not white else Color.WHITE)
	# 달아오름: 김
	if st == LumenEye.S.HOT and not white:
		for i in 3:
			var k := fmod(t * 1.5 + i * 0.33, 1.0)
			draw_circle(c + Vector2(-4 + i * 4, -9 - k * 10.0), 1.5 + k * 2.0, Color(1.0, 0.7, 0.5, 0.3 * (1.0 - k)))
