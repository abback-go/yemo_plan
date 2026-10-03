extends Node2D
## 별빛 발판 (docs/chapter4.md 2절 7·7.6절): 교장(아스트리드)의 별 마법으로 허공에 놓이는 발판. flag가 서면 아래에서부터 하나씩 반짝이며 생긴다.
## 방 데이터: {t:"star_steps", flag, steps:[[x, y(발판 행), w(칸)], ...], gap(하나씩 생기는 간격 초, 기본 0.14), id}
## 위에서만 밟히는 통과 발판(L_PLATFORM). 플래그가 이미 서 있으면 방에 들어올 때부터 있다.

const T := 16.0

var flag := ""
var gap := 0.14
var steps: Array = [] ## [Rect2(전역 px), 나타난 정도 0~1, 몸체]
var _on := false
var _t := 0.0


func setup(room: Room, e: Dictionary, _eid: String) -> void:
	position = Vector2.ZERO
	flag = String(e.get("flag", ""))
	gap = float(e.get("gap", 0.14))
	for s in e.get("steps", []):
		var a: Array = s
		var r := Rect2(float(a[0]) * T, float(a[1]) * T, float(a[2] if a.size() > 2 else 3) * T, 6.0)
		steps.append([r, 0.0, null])
	z_index = 3
	material = Fx.add_material


func _ready() -> void:
	for st in steps:
		var r: Rect2 = st[0]
		var body := StaticBody2D.new()
		body.collision_layer = GameConst.L_PLATFORM
		body.collision_mask = 0
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = r.size
		cs.shape = rs
		cs.one_way_collision = true
		cs.position = r.position + r.size * 0.5
		cs.disabled = true
		body.add_child(cs)
		add_child(body)
		st[2] = cs
	if flag == "" or GameState.has_flag(flag):
		_appear(true)


func _appear(instant: bool) -> void:
	if _on:
		return
	_on = true
	# 아래(행이 큰 것)부터 차례로
	var order: Array = steps.duplicate()
	order.sort_custom(func(a: Array, b: Array) -> bool: return (a[0] as Rect2).position.y > (b[0] as Rect2).position.y)
	for i in order.size():
		var st: Array = order[i]
		if instant:
			st[1] = 1.0
			(st[2] as CollisionShape2D).disabled = false
			continue
		var tw := create_tween()
		tw.tween_interval(i * gap)
		tw.tween_callback(_pop.bind(st))


func _pop(st: Array) -> void:
	var r: Rect2 = st[0]
	(st[2] as CollisionShape2D).set_deferred("disabled", false)
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: st[1] = v, 0.0, 1.0, 0.35)
	var c := r.position + Vector2(r.size.x * 0.5, 2)
	Sfx.play(&"star_twinkle", -8.0, 0.15)
	Fx.burst(c, 10, {spread = 180.0, speed_min = 20.0, speed_max = 70.0, lifetime = 0.6,
		gradient = Palette.fade_gradient(Color(0.75, 0.85, 1.0)), add = true, size_min = 1.0, size_max = 2.5})


func _process(delta: float) -> void:
	_t += delta
	if not _on and flag != "" and GameState.has_flag(flag):
		_appear(false)
	queue_redraw()


func _draw() -> void:
	for i in steps.size():
		var st: Array = steps[i]
		var k: float = st[1]
		if k <= 0.0:
			continue
		var r: Rect2 = st[0]
		var pulse := 0.8 + 0.2 * sin(_t * 3.0 + i)
		# 은은한 빛 + 별빛 판
		draw_rect(Rect2(r.position + Vector2(-4, -6), r.size + Vector2(8, 14)), Color(0.45, 0.55, 1.0, 0.10 * k))
		draw_rect(r, Color(0.65, 0.72, 1.0, 0.45 * k * pulse))
		draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), Color(0.95, 0.97, 1.0, 0.9 * k))
		draw_rect(Rect2(r.position + Vector2(0, r.size.y - 1), Vector2(r.size.x, 1)), Color(0.5, 0.6, 1.0, 0.5 * k))
		# 판 위·아래를 흐르는 작은 별
		var n := int(r.size.x / 10.0) + 1
		for j in n:
			var ph := fmod(_t * 0.6 + j * 0.37 + i * 0.21, 1.0)
			var x := r.position.x + fmod(j * 10.0 + _t * 6.0, r.size.x)
			var y := r.position.y + 3.0 + ph * 10.0
			var a := (1.0 - ph) * k
			draw_rect(Rect2(x, y, 1, 1), Color(0.9, 0.95, 1.0, a))
		for j in 2:
			var sx := r.position.x + r.size.x * (0.25 + 0.5 * j)
			var tw := 0.5 + 0.5 * sin(_t * 5.0 + j * 2.0 + i)
			var sc := Vector2(sx, r.position.y - 1)
			draw_line(sc + Vector2(-3, 0), sc + Vector2(3, 0), Color(1, 1, 1, 0.7 * tw * k), 1.0)
			draw_line(sc + Vector2(0, -3), sc + Vector2(0, 3), Color(1, 1, 1, 0.7 * tw * k), 1.0)
