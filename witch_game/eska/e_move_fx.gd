class_name EMoveFx
extends RefCounted
## 에스카 이동 연출: 활주 자취·출발 돌풍 · 이단점프 발판 · 순간이동(찢어진 틈·경로 참격·늘어나며 사라짐).
## 그림만 — 피해 없음. 색·그리기 도구는 EVfx를 쓴다.

const WHITE := EVfx.WHITE
const PALE := EVfx.PALE
const VIOLET := EVfx.VIOLET
const DEEP := EVfx.DEEP
const INK := EVfx.INK
const PLUM := EVfx.PLUM
const BODY := EVfx.BODY
const MAGENTA := EVfx.MAGENTA
const STREAK := EVfx.STREAK
const EDGE := EVfx.EDGE


## 활주 자취: 발밑에 낮게 깔리는 보랏빛 바람(보통 섞기) + 몸 높이에서 뒤로 흐르는 가는 속도선(가산). k = 속도 비율
static func glide_wake(pos: Vector2, dir: float, k: float) -> void:
	var pp := PParticles.get_layer(false)
	pp.spawn(pos + Vector2(-dir * randf_range(2.0, 8.0), -randf_range(1.0, 4.0)), Vector2(-dir * randf_range(30.0, 70.0), -randf_range(4.0, 16.0)),
		Vector2.ZERO, randf_range(0.28, 0.42), randf_range(3.0, 5.0), Color(PLUM, 0.45 * k), Color(INK, 0.0), 2, 3.0)
	if randf() < 0.6 * k:
		var lines := PParticles.get_layer(true)
		lines.spawn(pos + Vector2(-dir * randf_range(6.0, 16.0), -randf_range(4.0, 36.0)), Vector2(-dir * randf_range(220.0, 320.0), 0.0),
			Vector2.ZERO, randf_range(0.08, 0.14), randf_range(0.6, 1.0), Color(EDGE, 0.7), Color(MAGENTA, 0.0), 1, 0.0)


## 활주 출발: 발 뒤로 짧게 터지는 보랏빛 돌풍 (멈춰 있다가 확 미끄러져 나갈 때)
static func glide_burst(pos: Vector2, dir: float) -> void:
	Sfx.play(&"es_glide", -10.0)
	EVfx.dark_bits(pos + Vector2(-dir * 4.0, -3.0), 5, 140.0, Vector2(-dir, -0.2), 35.0, 0.26, 2)
	var lines := PParticles.get_layer(true)
	for i in 4:
		lines.spawn(pos + Vector2(-dir * randf_range(4.0, 10.0), -randf_range(6.0, 30.0)), Vector2(-dir * randf_range(300.0, 420.0), 0.0),
			Vector2.ZERO, randf_range(0.1, 0.16), 1.0, Color(EDGE, 0.85), Color(MAGENTA, 0.0), 1, 0.0)


## 이단점프 발판: 발밑 공중에 납작한 다크 회오리 고리가 휘감기며 생겨 밟히고 퍼지며 사라진다
static func air_step(pos: Vector2) -> void:
	EVfx.add(AirStep.new(), pos, false)
	EVfx.dark_bits(pos, 6, 120.0, Vector2.DOWN, 70.0, 0.3, 2)


class AirStep extends PVfx.Base:
	func _ready() -> void:
		life = 0.34
		z_index = 4

	func _paint() -> void:
		var e := k()
		var grow := 1.0 - pow(1.0 - clampf(t / 0.08, 0.0, 1.0), 2.0)
		var r := lerpf(10.0, 30.0, 1.0 - pow(1.0 - e, 2.0))
		var a0 := -PI * 0.85
		pd.draw_set_transform(Vector2(0, 1.0), -0.08, Vector2(1.0, 0.28))
		EVfx.dark_band(pd, r, a0, a0 + TAU * 1.02 * grow, 9.0 * (1.0 - 0.6 * e), 1.0 - e * e, 5, 36)
		pd.draw_set_transform(Vector2.ZERO)
		if t < 0.1:
			pd.glow(Vector2.ZERO, 10.0, Color(EDGE, 0.8 * (1.0 - t / 0.1)), 0.0)


## 순간이동(이동기 — 피해 없음): 몸이 진행 방향으로 가늘고 길게 늘어나며 빨려 들어가듯 사라지고,
## 떠난 자리엔 검은 틈(마젠타 테두리)이 잠깐 남았다 닫히며, 출발점→도착점에 다크 참격 한 줄이 그어지고 잔상이 남는다
static func blink_out(art: EArt, pos: Vector2, dir: int) -> void:
	var tear := Tear.new()
	EVfx.add(tear, pos, false)
	EVfx.dark_bits(pos, 6, 110.0, Vector2(-dir, 0), 60.0, 0.28, 1)
	if art.snap_i.is_empty():
		return
	var g := EVfx.Afterimage.new()
	g.v = art.snap_v
	g.idx = art.snap_i
	g.life = 0.12
	g.tint = EDGE
	g.stretch_dir = dir
	g.stretch_c = pos
	g.z_index = 1
	g.material = Fx.add_material
	Fx.effect_parent().add_child(g)
	g.base_xf = art.snap_xf
	g.global_transform = art.snap_xf


## 도착: 작은 틈에서 튀어나오듯 (몸은 길게 늘어났다 탁 돌아오는 건 EArt.squash가)
static func blink_in(pos: Vector2, dir: int) -> void:
	var tear := Tear.new()
	tear.small = true
	EVfx.add(tear, pos, false)
	EVfx.dark_bits(pos, 4, 90.0, Vector2(dir, 0), 60.0, 0.22)
	Sfx.play(&"es_tear", -9.0)


## 출발점 → 도착점: 다크 참격 한 줄(살짝 휨, 공중이면 더 휨) + 경로 위 잔상 셋. 그림만 — 피해 없음
static func blink_trail(art: EArt, from: Vector2, to: Vector2, air: bool) -> void:
	var s := TrailSlash.new()
	s.to = to - from
	s.bend = (0.14 if air else 0.06) * (-1.0 if randf() < 0.5 else 1.0)
	EVfx.add(s, from, false)
	for i in 3:
		var f := (float(i) + 1.0) / 4.0
		EVfx.afterimage(art, 0.16 + 0.05 * float(i), VIOLET, (to - from) * f, 0.45)


# ═══════════════════════════════════════════════════════════
# 순간이동
# ═══════════════════════════════════════════════════════════

## 찢어진 공간의 틈: 들쭉날쭉한 세로 틈(검은 속 + 마젠타 테두리 + 가운데 흰 금)이 빠르게 벌어졌다 천천히 닫힌다 (보통 섞기)
class Tear extends PVfx.Base:
	var small := false
	var _jl := PackedFloat32Array()
	var _jr := PackedFloat32Array()

	func _ready() -> void:
		life = 0.16 if small else 0.3
		z_index = 4
		for i in 9:
			_jl.append(randf_range(0.55, 1.0))
			_jr.append(randf_range(0.55, 1.0))

	func _shape(h: float, w: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		var n := _jl.size()
		for i in n:
			var f := float(i) / float(n - 1)
			pts.append(Vector2(w * pow(sin(f * PI), 0.8) * _jr[i], lerpf(-h, h, f)))
		for i in range(n - 1, -1, -1):
			var f := float(i) / float(n - 1)
			pts.append(Vector2(-w * pow(sin(f * PI), 0.8) * _jl[i], lerpf(-h, h, f)))
		return pts

	func _paint() -> void:
		var x := k()
		var open := minf(x / 0.18, 1.0) * (1.0 - pow(clampf((x - 0.18) / 0.82, 0.0, 1.0), 1.5)) # 빠르게 열리고 천천히 닫힘
		if open <= 0.01:
			return
		var h := (15.0 if small else 22.0) * (0.8 + 0.2 * open)
		var w := (4.0 if small else 7.0) * open
		pd.glow(Vector2.ZERO, h * 1.1, Color(MAGENTA, 0.25 * open), 0.0)
		pd.draw_colored_polygon(_shape(h + 2.0, w + 2.2), Color(MAGENTA, 0.9 * open))
		pd.draw_colored_polygon(_shape(h, w), Color(INK, 0.95))
		pd.draw_line(Vector2(0, -h * 0.75), Vector2(0, h * 0.75), Color(EDGE, 0.8 * open), 1.0)


## 순간이동 경로의 다크 참격 한 줄 (그림만, 피해 없음): 출발점에서 도착점으로 순식간에 그어지고 꼬리부터 걷힌다
class TrailSlash extends PVfx.Base:
	var to := Vector2.ZERO
	var bend := 0.06

	func _ready() -> void:
		life = 0.34
		z_index = 5

	func _paint() -> void:
		var len := to.length()
		if len < 4.0:
			return
		var dv := to / len
		var grow := 1.0 - pow(1.0 - clampf(t / 0.05, 0.0, 1.0), 2.0)
		var e := clampf((t - 0.1) / (life - 0.1), 0.0, 1.0)
		var se := e * e * (3.0 - 2.0 * e)
		var f0 := 0.9 * se
		EVfx.feather(pd, Vector2.ZERO, dv, len, bend, 13.0 * (1.0 - 0.5 * se), 1.0 - e * e, f0, maxf(grow, f0 + 0.02))
