class_name PDummy
extends Node2D
## 훈련장 허수아비. 맞으면 흔들리고 흰빛으로 번쩍이며 피해 숫자·체력바를 띄운다. 잠시 안 맞으면 체력이 다시 찬다.
## kind: "small"(짚 허수아비) · "big"(갑옷 허수아비 — 보스 크기, 대마법·바인드 시험) · "hang"(매달린 모래주머니 — 공중 공격)
##       · "launcher"(여우 석상 발사대 — 시험 패널에서 켜면 느린 연습탄을 쏨: 피격·대시 무적 연습)
## 피해 판정은 물리 없이 사각형으로 한다(hit_rect) — 공격 쪽이 PDummy.all()을 돌며 겹치는지 본다.

const GROUP := &"p_target"

var kind := "small"
var max_hp := 600
var hp := 600
var _flash := 0.0
var _wobble := 0.0 ## 흔들림 각도(라디안)
var _wobble_v := 0.0
var _since_hit := 99.0
var _bar := 0.0 ## 체력바 보이는 남은 시간
var _bound := 0.0 ## 바인드 남은 시간
var _bind_awake := false
var _t := 0.0
var _shoot_t := 1.5
var _hits_total := 0


static func all(tree: SceneTree) -> Array:
	return tree.get_nodes_in_group(GROUP)


func setup(k: String) -> void:
	kind = k
	match k:
		"big":
			max_hp = 6000
		"hang":
			max_hp = 900
		"launcher":
			max_hp = 1200
		_:
			max_hp = 1200
	hp = max_hp


func _ready() -> void:
	add_to_group(GROUP)
	_t = randf() * 3.0


## 피격 판정 사각형 (전역 좌표). 원점 = 발밑 가운데
func hit_rect() -> Rect2:
	match kind:
		"big":
			return Rect2(global_position + Vector2(-20, -78), Vector2(40, 78))
		"hang":
			return Rect2(global_position + Vector2(-11, -2), Vector2(22, 30))
		"launcher":
			return Rect2(global_position + Vector2(-14, -34), Vector2(28, 34))
	return Rect2(global_position + Vector2(-10, -40), Vector2(20, 40))


func center() -> Vector2:
	return hit_rect().get_center()


func is_bound() -> bool:
	return _bound > 0.0


## dmg 피해, from 때린 쪽 위치(흔들림 방향). opts: fox(푸른 숫자), heavy(큰 숫자), launch(위로 흔들림 세기)
func take_hit(dmg: int, from: Vector2, opts := {}) -> void:
	var d := dmg
	if PState.difficulty == 2:
		d = int(round(float(d) / 1.3)) # 어려움: 적 체력 +30% 와 같음
	if _bound > 0.0 and _bind_awake:
		d = int(round(float(d) * 1.3))
	hp -= d
	_hits_total += 1
	_since_hit = 0.0
	_bar = 2.2
	_flash = 0.7
	if _bound <= 0.0:
		var dir := signf(global_position.x - from.x)
		if dir == 0.0:
			dir = 1.0
		_wobble_v += dir * (2.2 + float(opts.get("launch", 0.0))) * (0.35 if kind == "big" else 1.0)
	if PState.damage_numbers:
		Fx.damage_number(center() + Vector2(0, -10), d, bool(opts.get("heavy", false)), bool(opts.get("fox", false)))
	if hp <= 0:
		hp = max_hp # 허수아비는 쓰러지지 않음 — 한 바퀴 돌면 다시 가득
		Fx.ring(center(), 6, 30, Color(1, 0.95, 0.7, 0.8), 0.3)


func bind(sec: float, awake: bool) -> void:
	_bound = sec
	_bind_awake = awake


func _process(delta: float) -> void:
	_t += delta
	_since_hit += delta
	_flash = maxf(_flash - delta * 7.0, 0.0)
	_bar = maxf(_bar - delta, 0.0)
	_bound = maxf(_bound - delta, 0.0)
	if _since_hit > 3.0 and hp < max_hp:
		hp = mini(hp + int(max_hp * delta * 0.8), max_hp)
	if _bound <= 0.0:
		# 용수철처럼 흔들리다 멈춤
		_wobble_v += (-_wobble * 60.0 - _wobble_v * 7.0) * delta
		_wobble += _wobble_v * delta
	if kind == "launcher" and PState.launcher_on and _bound <= 0.0:
		_shoot_t -= delta
		if _shoot_t <= 0.0:
			_shoot_t = 2.1
			_fire()
	queue_redraw()


func _fire() -> void:
	var p := PSera.find(get_tree())
	if p == null:
		return
	var orb := POrb.new()
	orb.position = global_position + Vector2(0, -24)
	orb.vel = (p.center() - orb.position).normalized() * 120.0
	Fx.effect_parent().add_child(orb)
	Sfx.play(&"foxfire", -8.0)


func _draw() -> void:
	var flash := _flash
	var w := _wobble
	match kind:
		"big":
			_draw_big(w, flash)
		"hang":
			_draw_hang(w, flash)
		"launcher":
			_draw_launcher(flash)
		_:
			_draw_small(w, flash)
	if _bound > 0.0:
		_draw_chains()
	if _bar > 0.0:
		var r := hit_rect()
		var top := r.position.y - global_position.y - 8.0
		var bw := 28.0 if kind != "big" else 44.0
		var a := clampf(_bar * 2.0, 0.0, 1.0)
		draw_rect(Rect2(-bw / 2 - 1, top - 1, bw + 2, 5), Color(0, 0, 0, 0.7 * a))
		draw_rect(Rect2(-bw / 2, top, bw * float(hp) / float(max_hp), 3), Color(1.0, 0.35, 0.3, a))


func _mix(c: Color, f: float) -> Color:
	return c.lerp(Color.WHITE, clampf(f, 0.0, 1.0))


func _draw_small(w: float, f: float) -> void:
	# 기둥(고정) + 몸통(흔들림, 발밑 축)
	draw_rect(Rect2(-2, -14, 4, 14), Color("#5a3d28"))
	draw_rect(Rect2(-7, -2, 14, 2), Color("#3b2818"))
	draw_set_transform(Vector2(0, -12), w, Vector2.ONE)
	var straw := _mix(Color("#d9b46a"), f)
	var straw_d := _mix(Color("#a8823e"), f)
	draw_colored_polygon(PackedVector2Array([Vector2(-8, 0), Vector2(8, 0), Vector2(10, -18), Vector2(6, -22), Vector2(-6, -22), Vector2(-10, -18)]), straw_d)
	draw_colored_polygon(PackedVector2Array([Vector2(-7, -1), Vector2(7, -1), Vector2(8, -17), Vector2(-8, -17)]), straw)
	for i in 4:
		draw_line(Vector2(-6 + i * 4, -2), Vector2(-5 + i * 4, -16), straw_d, 1.0)
	draw_rect(Rect2(-9, -12, 18, 3), _mix(Color("#7a2a2a"), f)) # 허리끈
	draw_rect(Rect2(-12, -18, 24, 3), straw_d) # 팔(가로 막대)
	draw_circle(Vector2(0, -26), 6.0, _mix(Color("#e8d2a0"), f)) # 머리 자루
	draw_circle(Vector2(0, -26), 3.6, _mix(Color("#c0392b"), f)) # 과녁
	draw_circle(Vector2(0, -26), 2.0, _mix(Color("#f5e6c8"), f))
	draw_circle(Vector2(0, -26), 0.9, _mix(Color("#c0392b"), f))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_big(w: float, f: float) -> void:
	draw_rect(Rect2(-14, -4, 28, 4), Color("#2c2a33"))
	draw_set_transform(Vector2(0, -4), w * 0.5, Vector2.ONE)
	var steel := _mix(Color("#6f7787"), f)
	var steel_d := _mix(Color("#3f4552"), f)
	var steel_l := _mix(Color("#aab3c4"), f)
	draw_rect(Rect2(-9, -30, 7, 30), steel_d) # 다리
	draw_rect(Rect2(2, -30, 7, 30), steel_d)
	draw_colored_polygon(PackedVector2Array([Vector2(-18, -30), Vector2(18, -30), Vector2(22, -62), Vector2(-22, -62)]), steel)
	draw_colored_polygon(PackedVector2Array([Vector2(-14, -34), Vector2(0, -38), Vector2(14, -34), Vector2(16, -56), Vector2(-16, -56)]), steel_l.darkened(0.15))
	draw_rect(Rect2(-26, -62, 10, 9), steel_d) # 어깨
	draw_rect(Rect2(16, -62, 10, 9), steel_d)
	draw_rect(Rect2(-27, -53, 7, 24), steel) # 팔
	draw_rect(Rect2(20, -53, 7, 24), steel)
	draw_colored_polygon(PackedVector2Array([Vector2(-10, -62), Vector2(10, -62), Vector2(9, -78), Vector2(0, -82), Vector2(-9, -78)]), steel_l) # 투구
	draw_rect(Rect2(-7, -73, 14, 2), Color(0.1, 0.1, 0.14))
	draw_colored_polygon(PackedVector2Array([Vector2(-2, -82), Vector2(2, -82), Vector2(0, -92)]), _mix(Color("#b8323a"), f)) # 깃
	draw_circle(Vector2(0, -46), 5.0, _mix(Color("#c0392b"), f))
	draw_circle(Vector2(0, -46), 2.4, _mix(Color("#f5e6c8"), f))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_hang(w: float, f: float) -> void:
	# 원점 = 사슬이 달린 천장 아래 끝. 사슬은 위로 길게
	draw_line(Vector2(0, -60), Vector2(0, 0), Color("#4a4a55"), 1.0)
	draw_set_transform(Vector2.ZERO, w * 0.6, Vector2.ONE)
	var bag := _mix(Color("#8c6a4a"), f)
	draw_colored_polygon(PackedVector2Array([Vector2(-6, 0), Vector2(6, 0), Vector2(11, 8), Vector2(11, 24), Vector2(6, 30), Vector2(-6, 30), Vector2(-11, 24), Vector2(-11, 8)]), bag)
	draw_rect(Rect2(-11, 12, 22, 3), _mix(Color("#5c4330"), f))
	draw_circle(Vector2(0, 19), 4.0, _mix(Color("#c0392b"), f))
	draw_circle(Vector2(0, 19), 1.8, _mix(Color("#f5e6c8"), f))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_launcher(f: float) -> void:
	var stone := _mix(Color("#8a8f9c"), f)
	var stone_d := _mix(Color("#5b5f6b"), f)
	draw_rect(Rect2(-14, -8, 28, 8), stone_d) # 받침
	draw_colored_polygon(PackedVector2Array([Vector2(-10, -8), Vector2(10, -8), Vector2(8, -24), Vector2(-8, -24)]), stone)
	# 여우 머리 석상
	draw_colored_polygon(PackedVector2Array([Vector2(-9, -22), Vector2(9, -22), Vector2(6, -32), Vector2(-6, -32)]), stone)
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -30), Vector2(-4, -31), Vector2(-7, -40)]), stone_d)
	draw_colored_polygon(PackedVector2Array([Vector2(8, -30), Vector2(4, -31), Vector2(7, -40)]), stone_d)
	var on := PState.launcher_on
	var eye := PData.FOX_HOT if on else Color(0.3, 0.32, 0.4)
	draw_rect(Rect2(-5, -28, 3, 2), eye)
	draw_rect(Rect2(2, -28, 3, 2), eye)
	if on:
		var g := 0.5 + 0.5 * sin(_t * 4.0)
		draw_circle(Vector2(0, -24), 3.0 + g, Color(PData.FOX_MID, 0.6))


func _draw_chains() -> void:
	var r := hit_rect()
	var c := r.get_center() - global_position
	var a := clampf(_bound, 0.0, 1.0)
	var col := Color(PData.FOX_HOT, 0.85 * a)
	var h := r.size.y * 0.5 + 4.0
	var wd := r.size.x * 0.5 + 6.0
	for i in 3:
		var y := c.y - h * 0.6 + i * h * 0.6
		var pts := PackedVector2Array()
		for k in 9:
			var x := -wd + k * wd * 2.0 / 8.0
			pts.append(Vector2(x, y + sin(_t * 6.0 + k * 0.9 + i) * 1.5))
		draw_polyline(pts, col, 1.5)
	draw_arc(c, wd + 4.0, 0, TAU, 24, Color(PData.FOX_MID, 0.35 * a), 1.0)


## 발사대가 쏘는 느린 연습탄 (닿으면 세라 체력 1칸)
class POrb extends Node2D:
	var vel := Vector2.ZERO
	var life := 6.0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		life -= delta
		position += vel * delta
		var p := PSera.find(get_tree())
		if p and p.hurt_rect().has_point(global_position):
			if p.take_damage(1, global_position):
				PVfx.sparks(global_position, 10, PData.FOX_HOT, 70.0, 0.3)
				queue_free()
				return
		if life <= 0.0:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var g := 0.5 + 0.5 * sin(_t * 12.0)
		draw_circle(Vector2.ZERO, 7.0, Color(PData.FOX_DARK, 0.35))
		draw_circle(Vector2.ZERO, 5.0, Color(PData.FOX_MID, 0.8))
		draw_circle(Vector2.ZERO, 3.0 + g, PData.FOX_CORE)
