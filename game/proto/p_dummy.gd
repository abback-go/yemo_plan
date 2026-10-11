class_name PDummy
extends PDraw.Canvas
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
var _bind_fox := true ## 붙잡은 사슬 색 (변신 중 바인드 = 푸른 여우불, 평소 = 붉은 불)
var _bind_style := "" ## "" = 불 사슬을 그림 · "void" = 그리지 않음(에스카의 봉공이 공간 틀을 따로 그린다)
var _t := 0.0
var _shoot_t := 1.5
var _hits_total := 0
var _sq := 0.0 ## 맞을 때 눌림(용수철)
var _sq_v := 0.0
var _hp_trail := 600.0 ## 체력바의 막 깎인 부분(밝게 남았다가 따라 내려감)
var _bit_t := 0.0 ## 재질 조각 튀기 간격
var _dirty := true


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
	_hp_trail = max_hp


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
	_dirty = true
	var dir := signf(global_position.x - from.x)
	if dir == 0.0:
		dir = 1.0
	if _bound <= 0.0:
		_wobble_v += dir * (2.2 + float(opts.get("launch", 0.0))) * (0.35 if kind == "big" else 1.0)
	_sq_v += 7.0 if bool(opts.get("heavy", false)) else 4.0
	if _bit_t <= 0.0 or bool(opts.get("heavy", false)):
		_bit_t = 0.07
		_bits(dir, bool(opts.get("heavy", false)))
	if PState.damage_numbers:
		PVfx.number(self, center() + Vector2(0, -10), d, bool(opts.get("heavy", false)), bool(opts.get("fox", false)))
	if hp <= 0:
		hp = max_hp # 허수아비는 쓰러지지 않음 — 한 바퀴 돌면 다시 가득
		_hp_trail = max_hp
		Fx.ring(center(), 6, 30, Color(1, 0.95, 0.7, 0.8), 0.3)


func bind(sec: float, awake: bool, fox := true, style := "") -> void:
	_bound = sec
	_bind_awake = awake
	_bind_fox = fox
	_bind_style = style


func unbind() -> void:
	_bound = 0.0


func _process(delta: float) -> void:
	_t += delta
	_since_hit += delta
	_bit_t -= delta
	_flash = maxf(_flash - delta * 7.0, 0.0)
	_bar = maxf(_bar - delta, 0.0)
	_bound = maxf(_bound - delta, 0.0)
	if _since_hit > 3.0 and hp < max_hp:
		hp = mini(hp + int(max_hp * delta * 0.8), max_hp)
		_dirty = true
	if _hp_trail > hp:
		_hp_trail = maxf(float(hp), _hp_trail - float(max_hp) * delta * (0.9 if _since_hit > 0.35 else 0.0))
	else:
		_hp_trail = hp
	if _bound <= 0.0:
		# 용수철처럼 흔들리다 멈춤
		_wobble_v += (-_wobble * 60.0 - _wobble_v * 7.0) * delta
		_wobble += _wobble_v * delta
	_sq_v += (-_sq * 260.0 - _sq_v * 16.0) * delta
	_sq += _sq_v * delta
	if kind == "launcher" and PState.launcher_on and _bound <= 0.0:
		_shoot_t -= delta
		if _shoot_t <= 0.0:
			_shoot_t = 2.1
			_fire()
	# 가만히 있을 때는 다시 그리지 않는다 (훈련장에 허수아비가 여럿이라)
	var moving := absf(_wobble) > 0.002 or absf(_wobble_v) > 0.01 or absf(_sq) > 0.002 or absf(_sq_v) > 0.01
	if _dirty or moving or _flash > 0.0 or _bar > 0.0 or _bound > 0.0 or (kind == "launcher" and PState.launcher_on):
		_dirty = moving or _flash > 0.0 or _bar > 0.0 or _bound > 0.0
		queue_redraw()
	elif kind == "launcher":
		_dirty = true


## 재질 조각: 짚 허수아비 = 짚 부스러기, 갑옷 = 쇠 불꽃, 모래주머니 = 모래 먼지, 석상 = 돌 부스러기
func _bits(dir: float, heavy: bool) -> void:
	var c := center()
	var n := 5 if heavy else 3
	match kind:
		"small":
			var pp := PParticles.get_layer(false)
			for i in n:
				var v := Vector2(dir * randf_range(40, 130), randf_range(-150, -50))
				pp.spawn(c + Vector2(randf_range(-6, 6), randf_range(-8, 4)), v, Vector2(0, 520), randf_range(0.45, 0.7), randf_range(1.0, 2.0), Color("#ecd08a"), Color("#a07830"), 0, 1.5)
		"big":
			PVfx.sparks(c + Vector2(-dir * 4, randf_range(-14, 8)), n + 1, Color(1, 0.85, 0.5), 170.0, 0.3, Vector2(dir, -0.4), 50.0, Vector2(0, 420))
			Sfx.play_pitch(&"sword_clash", randf_range(0.9, 1.15), -14.0) # 쇠 갑옷 울림
		"hang":
			var pp := PParticles.get_layer(false)
			for i in n:
				pp.spawn(c + Vector2(randf_range(-6, 6), randf_range(-4, 10)), Vector2(dir * randf_range(10, 50), randf_range(-30, 10)), Vector2(0, 60), 0.5, randf_range(2.0, 3.5), Color(0.85, 0.72, 0.5, 0.5), Color(0.6, 0.5, 0.38, 0.5), 2, 3.0)
		_:
			var pp := PParticles.get_layer(false)
			for i in n:
				pp.spawn(c, Vector2(dir * randf_range(40, 110), randf_range(-140, -40)), Vector2(0, 520), 0.5, randf_range(1.0, 2.0), Color("#a3a8b8"), Color("#5b5f6b"), 0, 1.0)


func _fire() -> void:
	var p := PSera.find(get_tree())
	if p == null:
		return
	var orb := POrb.new()
	orb.position = global_position + Vector2(0, -24)
	orb.vel = (p.center() - orb.position).normalized() * 120.0
	Fx.effect_parent().add_child(orb)
	Sfx.play(&"foxfire", -8.0)


const OUT := Color("#120b14")


func _paint() -> void:
	var f := _flash
	var w := _wobble
	var sq := Vector2(1.0 + _sq * 0.12, 1.0 - _sq * 0.12)
	# 바닥 그림자 (매달린 것은 바닥까지 내려 그림)
	var ground := 0.0 if kind != "hang" else 400.0 - global_position.y
	var sw: float = {"big": 26.0, "hang": 10.0, "launcher": 15.0}.get(kind, 11.0)
	pd.draw_set_transform(Vector2(0, ground), 0.0, Vector2(1.0, 0.22))
	pd.glow(Vector2.ZERO, sw * (1.4 if kind != "hang" else 1.0 + absf(w)), Color(0, 0, 0, 0.45), 0.0)
	pd.draw_set_transform(Vector2.ZERO)
	match kind:
		"big":
			_draw_big(w, f, sq)
		"hang":
			_draw_hang(w, f, sq)
		"launcher":
			_draw_launcher(f, sq)
		_:
			_draw_small(w, f, sq)
	if _bound > 0.0 and _bind_style == "":
		_draw_chains()
	if _bar > 0.0:
		var r := hit_rect()
		var top := r.position.y - global_position.y - 9.0
		var bw := 28.0 if kind != "big" else 44.0
		var a := clampf(_bar * 2.0, 0.0, 1.0)
		var k := float(hp) / float(max_hp)
		var kt := _hp_trail / float(max_hp)
		pd.draw_rect(Rect2(-bw / 2 - 1, top - 1, bw + 2, 5), Color(0.02, 0.0, 0.03, 0.8 * a))
		pd.draw_rect(Rect2(-bw / 2, top, bw * kt, 3), Color(1, 0.92, 0.75, 0.9 * a))
		pd.rect_hgrad(Rect2(-bw / 2, top, bw * k, 3), Color(0.7, 0.12, 0.15, a), Color(1.0, 0.4, 0.32, a))
		pd.draw_rect(Rect2(-bw / 2, top, bw * k, 1), Color(1, 1, 1, 0.3 * a))


func _mix(c: Color, f: float) -> Color:
	return c.lerp(Color.WHITE, clampf(f, 0.0, 1.0))


func _ol(pts: PackedVector2Array, col: Color, f: float) -> void:
	pd.outlined(pts, _mix(col, f), OUT, 1.0)


## 짚 허수아비: 말뚝(고정) + 삼베 몸통(흔들림) · 짚 팔 · 과녁 머리
func _draw_small(w: float, f: float, sq: Vector2) -> void:
	pd.draw_rect(Rect2(-8, -2, 16, 2), _mix(Color("#2a1c12"), f * 0.3))
	_ol(PackedVector2Array([Vector2(-2, -15), Vector2(2, -15), Vector2(2, 0), Vector2(-2, 0)]), Color("#6a4630"), f)
	pd.draw_rect(Rect2(-2, -15, 1, 15), _mix(Color("#8a6040"), f))
	pd.draw_set_transform(Vector2(0, -12), w, sq)
	var straw := Color("#d9b46a")
	var straw_d := Color("#9a7436")
	var sack := Color("#c8a26a")
	# 짚 팔 (가로 막대 + 양 끝 짚 다발)
	_ol(PackedVector2Array([Vector2(-14, -19), Vector2(14, -19), Vector2(14, -16), Vector2(-14, -16)]), Color("#7a5232"), f)
	for sx: float in [-1.0, 1.0]:
		_ol(PackedVector2Array([Vector2(sx * 12, -20), Vector2(sx * 17, -22), Vector2(sx * 18, -17), Vector2(sx * 17, -14), Vector2(sx * 12, -15)]), straw, f)
		pd.draw_line(Vector2(sx * 13, -18), Vector2(sx * 17, -19), _mix(straw_d, f), 1.0)
	# 몸통 (삼베 자루 + 짚 술)
	_ol(PackedVector2Array([Vector2(-8, 0), Vector2(8, 0), Vector2(10, -16), Vector2(6, -21), Vector2(-6, -21), Vector2(-10, -16)]), sack, f)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(2, -1), Vector2(8, -1), Vector2(9.5, -16), Vector2(6, -20), Vector2(3, -20)]), _mix(Color("#a8834c"), f))
	for i in 5:
		pd.draw_line(Vector2(-6 + i * 3, -3), Vector2(-5.5 + i * 3, -18), _mix(Color(0, 0, 0, 0.18), f), 1.0)
	for i in 6:
		var x := -7.0 + i * 2.8
		pd.draw_line(Vector2(x, 0), Vector2(x + sin(i * 2.0) * 1.5, 3.0 + (i % 2)), _mix(straw, f), 1.0)
	_ol(PackedVector2Array([Vector2(-9.5, -11), Vector2(9.5, -11), Vector2(9.2, -8.5), Vector2(-9.2, -8.5)]), Color("#7a2a2a"), f) # 허리끈
	pd.draw_rect(Rect2(-1, -11, 2, 4), _mix(Color("#5a1a1a"), f))
	# 머리: 자루 + 과녁
	pd.outlined(_circle(Vector2(0, -26), 6.4, 14), _mix(Color("#e8d2a0"), f), OUT, 1.0)
	pd.draw_circle(Vector2(1.5, -25), 5.0, _mix(Color("#d4b880"), f * 0.5))
	pd.draw_circle(Vector2(0, -26), 4.0, _mix(Color("#c0392b"), f))
	pd.draw_circle(Vector2(0, -26), 2.6, _mix(Color("#f5e6c8"), f))
	pd.draw_circle(Vector2(0, -26), 1.2, _mix(Color("#c0392b"), f))
	pd.draw_line(Vector2(-3, -32), Vector2(-5, -35), _mix(straw, f), 1.0)
	pd.draw_line(Vector2(0, -32.4), Vector2(1, -36), _mix(straw, f), 1.0)
	pd.draw_set_transform(Vector2.ZERO)


## 갑옷 허수아비 (보스 크기): 나무 받침 위 판금 갑옷 · 둥근 어깨 · 투구 눈구멍 · 붉은 깃
func _draw_big(w: float, f: float, sq: Vector2) -> void:
	_ol(PackedVector2Array([Vector2(-16, -5), Vector2(16, -5), Vector2(18, 0), Vector2(-18, 0)]), Color("#3a2a20"), f)
	pd.draw_set_transform(Vector2(0, -5), w * 0.5, sq)
	var steel := Color("#7a8396")
	var steel_d := Color("#454c5c")
	var steel_l := Color("#b4bdd0")
	# 다리
	for sx: float in [-1.0, 1.0]:
		_ol(PackedVector2Array([Vector2(sx * 2, -30), Vector2(sx * 9, -30), Vector2(sx * 9.5, -3), Vector2(sx * 11, 0), Vector2(sx * 1.5, 0), Vector2(sx * 2, -3)]), steel_d, f)
		pd.draw_rect(Rect2(minf(sx * 3, sx * 8), -18, 5, 3), _mix(steel, f))
	# 몸통 판금 (가운데 능선 + 빛)
	_ol(PackedVector2Array([Vector2(-18, -30), Vector2(18, -30), Vector2(22, -62), Vector2(-22, -62)]), steel, f)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(4, -31), Vector2(17, -31), Vector2(21, -61), Vector2(6, -61)]), _mix(steel_d.lerp(steel, 0.4), f))
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-15, -34), Vector2(-4, -36), Vector2(-5, -58), Vector2(-17, -58)]), _mix(steel_l, f))
	pd.draw_line(Vector2(0, -32), Vector2(0, -61), _mix(steel_d, f), 1.0)
	for y: float in [-40.0, -48.0, -56.0]:
		pd.draw_line(Vector2(-19, y), Vector2(19, y), _mix(Color(0, 0, 0, 0.25), f), 1.0)
	# 둥근 어깨 + 팔
	for sx: float in [-1.0, 1.0]:
		_ol(PackedVector2Array([Vector2(sx * 20, -32), Vector2(sx * 27, -32), Vector2(sx * 27, -52), Vector2(sx * 20, -52)]), steel, f)
		pd.outlined(_circle(Vector2(sx * 22, -59), 7.5, 14), _mix(steel_l if sx < 0 else steel, f), OUT, 1.0)
		for k in 3:
			pd.draw_circle(Vector2(sx * (17 + k * 3), -59 + absf(k - 1) * 2.0), 0.8, _mix(steel_d, f))
	# 과녁
	pd.draw_circle(Vector2(0, -46), 5.6, _mix(Color("#c0392b"), f))
	pd.draw_circle(Vector2(0, -46), 3.6, _mix(Color("#f5e6c8"), f))
	pd.draw_circle(Vector2(0, -46), 1.6, _mix(Color("#c0392b"), f))
	# 투구 + 눈구멍 + 깃
	_ol(PackedVector2Array([Vector2(-10, -62), Vector2(10, -62), Vector2(10, -76), Vector2(6, -82), Vector2(0, -84), Vector2(-6, -82), Vector2(-10, -76)]), steel_l, f)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(1, -63), Vector2(10, -63), Vector2(10, -76), Vector2(5, -81), Vector2(1, -82)]), _mix(steel, f))
	pd.draw_rect(Rect2(-8, -73, 16, 2.5), Color(0.06, 0.05, 0.1))
	pd.draw_rect(Rect2(-6, -72.5, 3, 1.5), _mix(Color(1, 0.45, 0.25, 0.25 + 0.6 * f), f))
	for k in 3:
		pd.draw_line(Vector2(-2 + k * 2, -68), Vector2(-2 + k * 2, -65), Color(0.1, 0.1, 0.14), 1.0)
	var pl := sin(_t * 3.0 + w * 4.0) * 1.5 - w * 10.0
	_ol(PackedVector2Array([Vector2(-2, -83), Vector2(2, -83), Vector2(-4 + pl, -96), Vector2(-9 + pl * 1.3, -92)]), Color("#b8323a"), f)
	pd.draw_set_transform(Vector2.ZERO)


## 매달린 모래주머니: 사슬 + 가죽 자루 · 바느질 · 과녁
func _draw_hang(w: float, f: float, sq: Vector2) -> void:
	# 원점 = 사슬 아래 끝. 사슬은 위로
	for i in 10:
		var y := -60.0 + i * 6.0
		pd.draw_rect(Rect2(-1.5, y, 3, 4), Color("#4a4a58"), false, 1.0)
	pd.draw_set_transform(Vector2.ZERO, w * 0.6, sq)
	pd.draw_rect(Rect2(-4, -2, 8, 3), _mix(Color("#3a3440"), f))
	var bag := Color("#8c6a4a")
	_ol(PackedVector2Array([Vector2(-6, 0), Vector2(6, 0), Vector2(11, 8), Vector2(11, 24), Vector2(6, 30), Vector2(-6, 30), Vector2(-11, 24), Vector2(-11, 8)]), bag, f)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(3, 1), Vector2(6, 1), Vector2(10.5, 8.5), Vector2(10.5, 23.5), Vector2(6, 29), Vector2(3, 29)]), _mix(Color("#6a4c34"), f))
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-8, 6), Vector2(-5, 3), Vector2(-5, 26), Vector2(-9, 22)]), _mix(Color("#a8845e"), f))
	pd.draw_rect(Rect2(-11, 11, 22, 3), _mix(Color("#4a3424"), f))
	pd.draw_rect(Rect2(-11, 23, 22, 2), _mix(Color("#4a3424"), f))
	for i in 5:
		pd.draw_rect(Rect2(-0.5, 2 + i * 6, 1, 3), _mix(Color("#d8c098"), f))
	pd.draw_circle(Vector2(0, 19), 4.4, _mix(Color("#c0392b"), f))
	pd.draw_circle(Vector2(0, 19), 2.6, _mix(Color("#f5e6c8"), f))
	pd.draw_circle(Vector2(0, 19), 1.1, _mix(Color("#c0392b"), f))
	pd.draw_set_transform(Vector2.ZERO)


## 여우 석상 발사대 (켜면 눈이 푸르게 빛나고 입에서 여우불)
func _draw_launcher(f: float, sq: Vector2) -> void:
	var stone := Color("#8a8f9c")
	var stone_d := Color("#5b5f6b")
	var stone_l := Color("#b0b5c4")
	pd.draw_set_transform(Vector2.ZERO, 0.0, sq)
	_ol(PackedVector2Array([Vector2(-15, -8), Vector2(15, -8), Vector2(15, 0), Vector2(-15, 0)]), stone_d, f)
	pd.draw_rect(Rect2(-15, -8, 30, 1), _mix(stone_l, f))
	_ol(PackedVector2Array([Vector2(-10, -8), Vector2(10, -8), Vector2(8, -24), Vector2(-8, -24)]), stone, f)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(3, -9), Vector2(10, -9), Vector2(8, -23), Vector2(3, -23)]), _mix(stone_d, f * 0.5))
	# 여우 머리
	_ol(PackedVector2Array([Vector2(-9, -22), Vector2(9, -22), Vector2(7, -30), Vector2(4, -33), Vector2(-4, -33), Vector2(-7, -30)]), stone, f)
	for sx: float in [-1.0, 1.0]:
		_ol(PackedVector2Array([Vector2(sx * 8, -30), Vector2(sx * 4, -32), Vector2(sx * 7.5, -41)]), stone_l if sx < 0 else stone, f)
	_ol(PackedVector2Array([Vector2(-4, -24), Vector2(4, -24), Vector2(0, -19)]), stone_l, f)
	var on := PState.launcher_on
	var eye := PData.FOX_HOT if on else Color(0.25, 0.27, 0.35)
	pd.draw_rect(Rect2(-5, -29, 3, 2), eye)
	pd.draw_rect(Rect2(2, -29, 3, 2), eye)
	pd.draw_line(Vector2(-6, -12), Vector2(6, -12), _mix(Color("#b8323a"), f), 2.0) # 붉은 줄
	if on:
		var g := 0.5 + 0.5 * sin(_t * 4.0)
		pd.glow(Vector2(0, -21), 8.0 + g * 2.0, Color(PData.FOX_MID, 0.55))
		pd.draw_circle(Vector2(0, -21), 1.5 + g, PData.FOX_CORE)
	pd.draw_set_transform(Vector2.ZERO)


func _circle(c: Vector2, r: float, n: int) -> PackedVector2Array:
	var t := Transform2D(0.0, Vector2(r, r), 0.0, c)
	return t * PDraw.unit_circle(n)


func _draw_chains() -> void:
	var r := hit_rect()
	var c := r.get_center() - global_position
	var a := clampf(_bound, 0.0, 1.0)
	var pal := PSpells._pal(_bind_fox)
	var col := Color(pal[1], 0.85 * a)
	var h := r.size.y * 0.5 + 4.0
	var wd := r.size.x * 0.5 + 6.0
	for i in 3:
		var y := c.y - h * 0.6 + i * h * 0.6
		for k in 8:
			var x0 := -wd + k * wd * 2.0 / 8.0
			var x1 := x0 + wd * 2.0 / 8.0
			var p0 := Vector2(x0, y + sin(_t * 6.0 + k * 0.9 + i) * 1.5)
			var p1 := Vector2(x1, y + sin(_t * 6.0 + (k + 1) * 0.9 + i) * 1.5)
			pd.draw_line(p0, p1, col, 1.5)
			pd.draw_rect(Rect2(p0 - Vector2(1.5, 1.5), Vector2(3, 3)), Color(pal[0], 0.7 * a), false, 1.0)
	pd.draw_arc(c, wd + 4.0, 0, TAU, 24, Color(pal[2], 0.35 * a), 1.0)


## 발사대가 쏘는 느린 연습탄 (닿으면 세라 체력 1칸)
class POrb extends PDraw.Canvas:
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

	func _paint() -> void:
		var g := 0.5 + 0.5 * sin(_t * 12.0)
		pd.draw_circle(Vector2.ZERO, 7.0, Color(PData.FOX_DARK, 0.35))
		pd.draw_circle(Vector2.ZERO, 5.0, Color(PData.FOX_MID, 0.8))
		pd.draw_circle(Vector2.ZERO, 3.0 + g, PData.FOX_CORE)
