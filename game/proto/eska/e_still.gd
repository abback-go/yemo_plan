class_name EStill
extends Node2D
## 봉공 = 공간 고정 (2026-10-11 재설계 — 기획 문서 "게임 구조 기획" 탭 성장 절).
## 맵 공간 전체를 굳힌다: 적·구슬·허수아비·떨어지는 돌(GROUP)이 멈추고 에스카만 움직인다. 굳은 동안 피해는 보통(보너스 없음).
## 강자는 완전히 멈추지 않고 EEnemy.still_resist 만큼의 빠르기로 움직인다 (지금 시제품엔 강자가 없어 모두 멈춤).
## 연출: 캐릭터 뒤 세상이 색을 잃고(화면 셰이더, z -1) 공간에 격자와 금이 간다 → 끝나기 직전 깜빡임 → 유리처럼 깨지며 풀림.
## 시간은 5초 고정(EEska.STILL_TIME), 재사용 30초. 진화하면(EEska.still_evolved) 굳은 동안 준 피해의 50%가 깨질 때 한꺼번에 터진다.

const GROUP := "es_still" ## 공간 고정에 멈추는 사물: still(sec)를 가진다 (sec 0 = 풀림)
const GRID := 48.0

const SHADER_CODE := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float amount = 0.0;
void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	vec3 g = vec3(l * 0.9, l * 0.88, l * 1.08);
	COLOR = vec4(mix(c, g, amount), 1.0);
}
"""

static var current: EStill ## 지금 굳어 있으면 그 노드 (없으면 null)
static var _shader: Shader

var dur := 5.0
var left := 5.0
var burst := 0.0 ## 깨질 때 터뜨릴 몫 (0 = 진화 전)
var eska: EEska
var _stored := {} ## 진화: 표적 instance_id → [표적, 굳은 동안 받은 피해 합]
var t := 0.0
var origin := Vector2.ZERO
var pd := PDraw.new()
var _desat: Node2D
var _mat: ShaderMaterial
var _cracks: Array[PackedVector2Array] = []


## by(에스카) 자리에서 sec초 동안 공간을 굳힌다. burst_ratio > 0 이면 굳은 동안 준 피해의 그 몫이 깨질 때 터짐
static func cast(by: EEska, sec: float, burst_ratio := 0.0) -> void:
	if is_instance_valid(current):
		current.queue_free()
	var s := EStill.new()
	s.dur = sec
	s.left = sec
	s.burst = burst_ratio
	s.eska = by
	s.origin = by.center()
	by.get_parent().add_child(s)


## 진화: 굳은 동안 표적이 받은 피해를 쌓는다 (EEska.deal이 부름)
func store(target: Node2D, dmg: int) -> void:
	if burst <= 0.0:
		return
	var id := target.get_instance_id()
	if _stored.has(id):
		_stored[id][1] += dmg
	else:
		_stored[id] = [target, dmg]


static func active() -> bool:
	return is_instance_valid(current)


func _ready() -> void:
	current = self
	z_as_relative = false
	z_index = 11 # 이펙트(5)·빛 입자(9) 위, 앞 장식(12) 아래
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER_CODE
	_mat = ShaderMaterial.new()
	_mat.shader = _shader
	_desat = Node2D.new()
	_desat.z_as_relative = false
	_desat.z_index = -1 # 배경·땅 위, 캐릭터(0)·적(2) 아래 → 세상만 색을 잃는다
	_desat.material = _mat
	_desat.draw.connect(_draw_desat)
	add_child(_desat)
	for i in 11:
		var a := TAU * float(i) / 11.0 + randf_range(-0.2, 0.2)
		var pts := PackedVector2Array([origin])
		var p := origin
		var d := Vector2.from_angle(a)
		for s in 7:
			d = d.rotated(randf_range(-0.45, 0.45))
			p += d * randf_range(30.0, 70.0)
			pts.append(p)
		_cracks.append(pts)
	_hold_all()
	Sfx.play(&"es_tear", -2.0)
	Sfx.play_pitch(&"block", 0.55, -6.0)
	Fx.shake(0.35, 0.12)
	EVfx.pixels(origin, 16, 220.0, Vector2.ZERO, 180.0, 0.35)


func _exit_tree() -> void:
	if current == self:
		current = null


func _physics_process(delta: float) -> void:
	t += delta
	left -= delta
	if left <= 0.0:
		_release()
		return
	_hold_all()
	queue_redraw()
	_desat.queue_redraw()


## 살아 있는 표적과 사물 모두 남은 시간만큼 굳힌다 (굳는 도중 새로 나타난 적도)
func _hold_all() -> void:
	for n: Node in ETarget.alive(get_tree()):
		if n.has_method("freeze"):
			n.freeze(left)
		else:
			n.bind(left, false, true, "void") # 허수아비: 사슬 그림 없이 멈춤
	for n: Node in get_tree().get_nodes_in_group(GROUP):
		n.still(left)


func _release() -> void:
	for n: Node in ETarget.alive(get_tree()):
		n.unbind()
	for n: Node in get_tree().get_nodes_in_group(GROUP):
		n.still(0.0)
	_burst_all()
	var r := _view_rect()
	for i in 7:
		var p := r.position + Vector2(randf() * r.size.x, randf() * r.size.y)
		EVfx.shards(p, 5, 170.0, Vector2(24, 24), 40.0)
	EVfx.pixels(r.get_center(), 14, 260.0, Vector2.ZERO, 180.0, 0.3)
	Sfx.play_pitch(&"block", 1.7, -3.0)
	Sfx.play(&"crumble", -8.0)
	Fx.shake(0.3, 0.12)
	queue_free()


## 진화: 쌓인 피해의 burst 몫을 표적마다 한꺼번에 터뜨린다
func _burst_all() -> void:
	var ratio := burst
	burst = 0.0 # 터뜨리는 피해는 다시 쌓지 않음
	var any := false
	for id: int in _stored:
		var tg: Node2D = _stored[id][0]
		if not is_instance_valid(tg) or (tg.has_method("is_dead") and tg.is_dead()):
			continue
		var amt := int(round(float(_stored[id][1]) * ratio))
		if amt <= 0:
			continue
		any = true
		if is_instance_valid(eska):
			eska.deal(tg, amt, true, tg.center() + Vector2(0, -10), {"ult": true}) # 대마법 피해 — 게이지를 채우지 않음
		else:
			tg.take_hit(amt, tg.center(), {"heavy": true})
		EVfx.dark_burst(tg.center(), 34.0)
		EVfx.shards(tg.center(), 14, 220.0, Vector2(14, 18), 70.0)
	_stored.clear()
	if any:
		Fx.hitstop(0.08)
		Fx.flash(Color(0.85, 0.75, 1.0, 0.2), 0.12)
		Sfx.play(&"es_slash_big", -2.0)


## 지금 화면에 보이는 월드 사각형
func _view_rect() -> Rect2:
	var inv := get_viewport().get_canvas_transform().affine_inverse()
	return (inv * Rect2(Vector2.ZERO, get_viewport_rect().size)).grow(8.0)


func _fade() -> float:
	return clampf(t / 0.12, 0.0, 1.0) * clampf(left / 0.08, 0.0, 1.0)


func _draw_desat() -> void:
	_mat.set_shader_parameter("amount", 0.85 * _fade())
	_desat.draw_rect(_view_rect(), Color.WHITE)


func _draw() -> void:
	var a := _fade()
	var r := _view_rect()
	var warn := 0.0
	if left < 0.4:
		warn = 0.5 + 0.5 * sin(t * 42.0)
	# 굳은 공간의 격자 (월드에 붙어 있음)
	var ga := (0.07 + 0.08 * warn) * a
	var x := floorf(r.position.x / GRID) * GRID
	while x < r.end.x:
		pd.draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), Color(EVfx.PALE, ga), 1.0)
		x += GRID
	var y := floorf(r.position.y / GRID) * GRID
	while y < r.end.y:
		pd.draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color(EVfx.PALE, ga), 1.0)
		y += GRID
	# 시전 자리에서 퍼져 나가는 금 (0.15초 동안 자람)
	var grow := clampf(t / 0.15, 0.0, 1.0)
	for pts in _cracks:
		var n := maxi(2, int(ceil(float(pts.size()) * grow)))
		pd.draw_polyline(pts.slice(0, n), Color(EVfx.WHITE, (0.45 + 0.3 * warn) * a), 1.0)
	# 시전 순간 퍼지는 고리
	if t < 0.3:
		var k := t / 0.3
		pd.draw_arc(origin, 30.0 + 420.0 * (1.0 - pow(1.0 - k, 3.0)), 0.0, TAU, 48, Color(EVfx.VIOLET, 0.6 * (1.0 - k)), 3.0)
	pd.flush(self)


# ═══════════════════════════════════════════════════════════
# 공간 고정으로 오르는 시험 지형: 떨어지는 돌 + 돌을 떨어뜨리는 곳
# ═══════════════════════════════════════════════════════════

## 떨어지는 돌. 평소엔 에스카와 부딪히지 않고 지나가고, 굳으면 위에서만 밟히는 발판이 된다
class Rock extends StaticBody2D:
	const SIZE := Vector2(34, 14)
	var speed := 170.0
	var floor_y := 300.0
	var _still := 0.0
	var pd := PDraw.new()

	func _ready() -> void:
		add_to_group(GROUP)
		collision_layer = 0
		collision_mask = 0
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = SIZE
		cs.shape = rs
		cs.one_way_collision = true
		add_child(cs)
		z_index = 1

	func still(sec: float) -> void:
		_still = sec
		collision_layer = 1 if sec > 0.0 else 0

	func _physics_process(delta: float) -> void:
		if _still <= 0.0:
			position.y += speed * delta
			if position.y > floor_y + SIZE.y:
				queue_free()
		queue_redraw()

	func _draw() -> void:
		var hs := SIZE * 0.5
		var stuck := _still > 0.0
		pd.draw_rect(Rect2(-hs, SIZE), Color("#2a2433"))
		pd.draw_rect(Rect2(-hs, Vector2(SIZE.x, 3)), Color("#5a5068"))
		pd.draw_line(Vector2(-hs.x + 6, 2), Vector2(-hs.x + 14, -2), Color("#14101a"), 1.0)
		if stuck:
			pd.draw_rect(Rect2(-hs - Vector2(2, 2), SIZE + Vector2(4, 4)), Color(EVfx.VIOLET, 0.9), false, 1.0)
			for sx: float in [-1.0, 1.0]:
				var c := Vector2((hs.x + 2) * sx, -hs.y - 2)
				pd.draw_line(c, c + Vector2(-sx * 6, 0), EVfx.WHITE, 1.0)
		pd.flush(self)


## 돌을 떨어뜨리는 곳: 기둥(xs)마다 period초 간격, 기둥끼리는 반 간격 어긋나게 → 굳히면 엇갈린 계단이 생긴다
class RockFall extends Node2D:
	var xs: Array[float] = []
	var top := -130.0
	var floor_y := 300.0
	var period := 0.5
	var speed := 170.0
	var _t: Array[float] = []

	func _ready() -> void:
		for i in xs.size():
			var phase := period * float(i) / float(xs.size())
			_t.append(phase)
			# 처음부터 기둥이 차 있게 미리 떨어뜨려 둔다
			var y := top + speed * phase
			while y < floor_y:
				_drop.call_deferred(xs[i], y) # 장면이 만들어지는 중이라 다음 프레임에 붙인다
				y += speed * period

	func _physics_process(delta: float) -> void:
		if EStill.active():
			return # 굳은 동안은 새 돌도 나오지 않는다
		for i in xs.size():
			_t[i] += delta
			if _t[i] >= period:
				_t[i] -= period
				_drop(xs[i], top)

	func _drop(x: float, y: float) -> void:
		var r := Rock.new()
		r.speed = speed
		r.floor_y = floor_y
		r.position = Vector2(x, y)
		get_parent().add_child(r)
