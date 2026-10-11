class_name EMagicFx
extends RefCounted
## 에스카 낙성(↓+고급) · 대마법 4종 중 셋(흑성·유성우·종말의 운석)의 연출과 판정. 봉공은 EStill (e_still.gd).
## 기준서: docs/eska/design.md 3장. 만드는 쪽(EEska)은 노드를 만들어 eska·dir를 넣고 EVfx.add(노드, 에스카 발 위치, false)로 붙이기만 한다.
## 노드는 스스로 판정(eska.deal)·소리·화면 효과를 처리하고 끝나면 사라진다.
## 대마법 피해는 종언 게이지를 채우지 않게 eska.deal(..., {"ult": true})로 준다.
## 범위는 eska.mods.size(확장 물약)를 곱한다. 피해는 power(메아리 물약 등)를 곱한다.
## 그림 원칙(design.md 3-4): 모든 마법은 공간이 찢어진 틈(EVfx.rift — 안은 밤하늘)에서 나오고, 끝나면 틈은 꿰매듯 다시 닫힌다.
## 노드 하나가 틈·별·운석·충격을 모두 그린다(PDraw 묶음 = 그리기 호출 1번). 불티·파편·깃털은 기존 공용 층으로.

const WHITE := EVfx.WHITE
const PALE := EVfx.PALE
const VIOLET := EVfx.VIOLET
const INK := EVfx.INK
const PLUM := EVfx.PLUM
const BODY := EVfx.BODY
const MAGENTA := EVfx.MAGENTA
const STREAK := EVfx.STREAK
const EDGE := EVfx.EDGE
const VOID := EVfx.VOID
const ULT := {"ult": true}


## 반지름 rad 안에 몸(hit_rect)이 걸치는 살아 있는 표적들 (c = 전역)
static func targets_in(tree: SceneTree, c: Vector2, rad: float) -> Array:
	var out := []
	for d: Node2D in ETarget.alive(tree):
		var r: Rect2 = d.hit_rect()
		var q := Vector2(clampf(c.x, r.position.x, r.end.x), clampf(c.y, r.position.y, r.end.y))
		if q.distance_squared_to(c) <= rad * rad:
			out.append(d)
	return out


# ═══════════════════════════════════════════════════════════
# 공통 바탕: 시간·범위·피해·충격 자국
# ═══════════════════════════════════════════════════════════

## 마법 노드 공통: t초 흐름 · life가 되면 사라짐 · 충격 자국(빛·고리)을 같이 그림 · 범위 배수 sz · 피해 배수 power
class Spell extends PDraw.Canvas:
	var eska: EEska
	var dir := 1
	var power := 1.0 ## 피해 배수 (메아리 물약 = 0.5)
	var t := 0.0
	var life := 1.0
	var sz := 1.0 ## eska.mods.size (시작할 때 한 번 읽음)
	var _seed := 0
	var _booms: Array = [] ## 충격 자국: [위치(로컬), 나이, 반지름, 땅 위인가]

	func _ready() -> void:
		z_index = 6
		_seed = randi() % 9973
		if is_instance_valid(eska):
			sz = float(eska.mods.get("size", 1.0))
		_begin()

	func _begin() -> void:
		pass

	func _process(delta: float) -> void:
		t += delta
		var i := 0
		while i < _booms.size():
			_booms[i][1] += delta
			if float(_booms[i][1]) > 0.5:
				_booms.remove_at(i)
				continue
			i += 1
		_step(delta)
		if t >= life:
			queue_free()
			return
		queue_redraw()

	func _step(_delta: float) -> void:
		pass

	func _paint() -> void:
		_draw_fx()
		_paint_booms()

	func _draw_fx() -> void:
		pass

	## 로컬 → 전역
	func g(p: Vector2) -> Vector2:
		return position + p

	## 땅 찾기: from(전역)에서 to(전역)까지 광선 — 닿은 자리(전역), 없으면 null
	func _ray(from: Vector2, to: Vector2) -> Variant:
		var q := PhysicsRayQueryParameters2D.create(from, to, 1)
		var r := get_world_2d().direct_space_state.intersect_ray(q)
		return r.position if not r.is_empty() else null

	## 피해 (c = 전역 중심, rad 반지름). 맞힌 수를 돌려준다
	func _hurt(c: Vector2, rad: float, dmg: int, heavy: bool, ult: bool) -> int:
		if not is_instance_valid(eska):
			return 0
		var n := 0
		for d: Node2D in EMagicFx.targets_in(get_tree(), c, rad):
			eska.deal(d, int(round(float(dmg) * power)), heavy, c, EMagicFx.ULT if ult else {})
			n += 1
		return n

	## 충격 자국 하나 (p = 로컬): 빛 + 퍼지는 고리 (+ 땅 위면 납작한 고리)
	func _boom(p: Vector2, rad: float, ground: bool) -> void:
		_booms.append([p, 0.0, rad, ground])

	func _paint_booms() -> void:
		for b: Array in _booms:
			var p: Vector2 = b[0]
			var k := float(b[1]) / 0.5
			var rad: float = b[2]
			var f := 1.0 - k
			var e := 1.0 - pow(1.0 - minf(k * 2.2, 1.0), 3.0)
			if k < 0.25:
				pd.glow(p, rad * (0.7 + 0.5 * e), Color(EDGE, 0.85 * (1.0 - k / 0.25)), 0.0)
			pd.glow(p, rad * 1.3, Color(MAGENTA, 0.3 * f * f), 0.0)
			pd.draw_arc(p, rad * (0.3 + 0.9 * e), 0.0, TAU, 24, Color(MAGENTA, 0.9 * f), maxf(3.0 * f, 1.0))
			pd.draw_arc(p, rad * (0.3 + 0.9 * e) + 1.5, 0.0, TAU, 24, Color(EDGE, 0.6 * f), 1.0)
			if b[3]:
				pd.draw_set_transform(p, 0.0, Vector2(1.0, 0.24))
				pd.draw_arc(Vector2.ZERO, rad * (0.5 + 1.6 * e), 0.0, TAU, 28, Color(STREAK, 0.8 * f), maxf(4.0 * f, 1.0))
				pd.draw_set_transform(Vector2.ZERO)
			EVfx.star4(pd, p, rad * 0.9 * (1.0 - k) + 2.0, 0.3 + k * 2.0, Color(WHITE, f), Color(0, 0, 0, 0))

	## 유성·별 조각 하나 (p 머리, v 날아가는 방향(단위), r 머리 크기, tail 꼬리 길이, a 진하기). rock = 머리가 달아오른 검은 돌(유성)
	func _comet(p: Vector2, v: Vector2, r: float, tail: float, a: float, spin: float, rock := false) -> void:
		var back := p - v * tail
		var o := v.orthogonal()
		pd.convex_colors(PackedVector2Array([p + o * r * 1.6, p - o * r * 1.6, back]),
			PackedColorArray([Color(MAGENTA, 0.5 * a), Color(MAGENTA, 0.5 * a), Color(BODY, 0.0)]))
		pd.convex_colors(PackedVector2Array([p + o * r * 0.8, p - o * r * 0.8, p - v * tail * 0.7]),
			PackedColorArray([Color(STREAK, 0.95 * a), Color(STREAK, 0.95 * a), Color(MAGENTA, 0.0)]))
		pd.line2(p - v * tail * 0.45, p, Color(EDGE, 0.0), Color(EDGE, a), 1.0, r * 0.7)
		pd.glow(p, r * 2.6, Color(MAGENTA, 0.3 * a), 0.0)
		if rock:
			# 달아오른 앞쪽 테 + 검보라 돌 + 금
			pd.draw_circle(p, r * 1.15, Color(MAGENTA, 0.8 * a))
			pd.draw_circle(p + v * r * 0.3, r * 1.02, Color(EDGE, a))
			pd.draw_circle(p - v * r * 0.06, r, Color(INK, a))
			pd.draw_line(p - v.orthogonal() * r * 0.5, p + v * r * 0.4, Color(MAGENTA, a), 1.0)
			pd.glow(p + v * r * 0.5, r * 0.8, Color(STREAK, 0.7 * a), 0.0)
			EVfx.star4(pd, p + v * r, r * 1.2, spin, Color(WHITE, 0.8 * a), Color(0, 0, 0, 0))
			return
		EVfx.star4(pd, p, r * 1.9, spin, Color(EDGE, a), Color(0, 0, 0, 0))
		pd.glow(p, r * 0.9, Color(WHITE, a), 0.0)


## 곧은 틈 하나의 모양을 들고 다니며 열고 닫는 도구 (rip = 처음 쪽에서 끝 쪽으로 찢어 나가는 비율)
class RiftShape extends RefCounted:
	var pts := PackedVector2Array()
	var nrm := PackedVector2Array()
	var hw := PackedFloat32Array()
	var jseed := 0

	func _init(a: Vector2, b: Vector2, width: float, seg: int, s: int, kink := 0.0, bend := 0.0) -> void:
		jseed = s
		var r: Array = EVfx.rift_line(a, b, width, seg, s, kink, bend)
		pts = r[0]
		nrm = r[1]
		hw = r[2]

	## 점마다 반폭·진하기: rip 0~1 찢어 나간 정도, open 벌어짐, zip 꿰맨 위치, fade 진하기
	func draw(pd: PDraw, t: float, rip: float, open: float, zip: float, fade: float, ghost := 0.0, star_k := 1.0) -> void:
		var n := pts.size()
		var h2 := PackedFloat32Array()
		var al := PackedFloat32Array()
		h2.resize(n)
		al.resize(n)
		var any := false
		for i in n:
			var f := float(i) / float(n - 1)
			var r := clampf((rip - f) / 0.12, 0.0, 1.0) # 찢어 나가는 머리 바로 뒤는 아직 덜 벌어짐
			var z := 1.0
			if zip > 0.0:
				z = clampf((f - zip) / 0.18, 0.0, 1.0)
				z = z * z * (3.0 - 2.0 * z)
			h2[i] = hw[i] * open * r * z
			var seam := clampf(1.0 - (zip - f) * 3.0, 0.0, 1.0) if f < zip else 1.0
			al[i] = fade * (1.0 if f <= rip else 0.0) * seam
			any = any or al[i] > 0.01
		if any:
			EVfx.rift(pd, pts, nrm, h2, al, jseed, t, ghost, star_k)

	## 찢어 나가는 머리 앞의 흰 금 (rip까지 + 조금 앞)
	func crack(pd: PDraw, rip: float, a: float) -> void:
		var n := pts.size()
		var m := clampi(int(ceil(minf(rip + 0.15, 1.0) * float(n - 1))) + 1, 2, n)
		EVfx.crack(pd, pts.slice(0, m), nrm.slice(0, m), a, jseed)

	## 틈 위 비율 f 자리 (로컬)
	func at(f: float) -> Vector2:
		var fi := clampf(f, 0.0, 1.0) * float(pts.size() - 1)
		var i0 := mini(int(fi), pts.size() - 2)
		return pts[i0].lerp(pts[i0 + 1], fi - float(i0))


## 0 → 1 (부드럽게)
static func smooth01(x: float) -> float:
	var c := clampf(x, 0.0, 1.0)
	return c * c * (3.0 - 2.0 * c)


# ═══════════════════════════════════════════════════════════
# 낙성 (↓ + 고급 마법)
# ═══════════════════════════════════════════════════════════

## 낙성: 앞쪽 하늘(약 110px 앞, 위 200px)에 마녀 문장이 번쩍 → 하늘이 비스듬히 찢어져 밤하늘이 보이고
## 별 조각 6개가 0.06초 간격으로 비스듬히 쏟아져 내린다 (조각마다 60, 작은 충격). 공중에서 써도 똑같다(내려찍기 없음).
## 조각은 지나가는 길에 몸에 닿으면 그 자리에서, 아니면 땅(없으면 정해진 거리)에서 터진다. 다 떨어지면 틈은 꿰매듯 닫힌다.
class Nakseong extends Spell:
	const SKY := Vector2(110, -200) ## 틈 가운데 (발 기준, 앞으로)
	const TEAR := 50.0 ## 틈 반 길이
	const COUNT := 6
	const FIRST := 0.11 ## 첫 조각이 나오는 시각
	const GAP := 0.06
	const FALL_T := 0.28 ## 떨어지는 데 걸리는 시간 (소리와 맞춤)
	const SLOPE := 0.26 ## 비스듬함 (앞으로 / 아래로)
	const DMG := 60
	const HIT_R := 26.0
	const CLOSE_AT := 0.52
	var _rift: RiftShape
	var _bits: Array = [] ## [나올 시각, 시작(로컬), 떨어질 자리(로컬), 끝났나, 땅인가]
	var _closed := false

	func _begin() -> void:
		life = 1.15
		var c := Vector2(SKY.x * dir * sz, SKY.y)
		_rift = RiftShape.new(c + Vector2(-TEAR * dir * sz, 9.0), c + Vector2(TEAR * dir * sz, -9.0), 9.0 * sz, 14, _seed, 2.0)
		var dv := Vector2(dir * SLOPE, 1.0).normalized()
		for i in COUNT:
			var f := (float(i) + 0.5 + randf_range(-0.25, 0.25)) / float(COUNT) # 뒤에서 앞으로 쏟아짐
			var s := _rift.at(lerpf(0.12, 0.88, f))
			var land: Variant = _ray(g(s), g(s + dv * 520.0))
			var ground := land != null
			var lp: Vector2 = (land as Vector2) - position if ground else s + dv * 240.0
			_bits.append([FIRST + GAP * float(i), s, lp, false, ground])
		EVfx.sigil(g(c), 2.0)
		Sfx.play(&"es_nakseong", -2.0)
		Sfx.play_pitch(&"es_tear", 0.8, -6.0)

	func _step(_delta: float) -> void:
		for b: Array in _bits:
			if b[3] or t < float(b[0]):
				continue
			var u := (t - float(b[0])) / FALL_T
			var s: Vector2 = b[1]
			var l: Vector2 = b[2]
			var p := s.lerp(l, pow(minf(u, 1.0), 1.35))
			if u < 0.02:
				EVfx.pixels(g(s), 4, 90.0, Vector2.DOWN, 80.0, 0.2) # 틈에서 튀어나오는 불티
			elif u < 1.0:
				EVfx.pixels(g(p), 1, 40.0, Vector2.UP, 120.0, 0.25)
			# 지나가는 길에 몸에 닿으면 그 자리에서 터진다
			var hit_body := false
			if u < 1.0:
				for d: Node2D in ETarget.alive(get_tree()):
					if (d.hit_rect() as Rect2).grow(4.0).has_point(g(p)):
						hit_body = true
						break
			if u >= 1.0 or hit_body:
				b[3] = true
				_land(p, bool(b[4]) and not hit_body)
		if not _closed and t >= CLOSE_AT:
			_closed = true
			Sfx.play_pitch(&"es_tear_close", 1.1, -8.0)

	func _land(p: Vector2, ground: bool) -> void:
		var gp := g(p)
		var n := _hurt(gp, HIT_R * sz, DMG, false, false)
		_boom(p, 16.0 * sz, ground)
		EVfx.pixels(gp, 7, 170.0, Vector2.UP, 75.0, 0.32, Vector2(0, 360))
		EVfx.dark_bits(gp, 4, 120.0, Vector2.UP, 70.0, 0.3, 1)
		EVfx.shards(gp, 3, 120.0, Vector2(4, 2), 70.0)
		if randf() < 0.4:
			EVfx.feathers(gp, 1, 60.0, Vector2(4, 2), Vector2.UP)
		Fx.shake(0.14, 0.1)
		if n > 0:
			Fx.hitstop(0.02)

	func _draw_fx() -> void:
		var rip := EMagicFx.smooth01(t / 0.09)
		var open := EMagicFx.smooth01((t - 0.03) / 0.08) * (1.0 + 0.12 * sin(clampf((t - 0.03) / 0.2, 0.0, 1.0) * PI))
		var zip := EMagicFx.smooth01((t - CLOSE_AT) / 0.2) * 1.02 if t > CLOSE_AT else 0.0
		var fade := 1.0 - clampf((t - CLOSE_AT - 0.2) / 0.25, 0.0, 1.0)
		_rift.draw(pd, t, rip, open, zip, fade)
		if t < 0.11:
			_rift.crack(pd, rip, 1.0 - t / 0.11)
		for b: Array in _bits:
			if b[3] or t < float(b[0]):
				continue
			var u := minf((t - float(b[0])) / FALL_T, 1.0)
			var s: Vector2 = b[1]
			var l: Vector2 = b[2]
			var p := s.lerp(l, pow(u, 1.35))
			var v := (l - s).normalized()
			if u < 0.15:
				pd.glow(s, 9.0, Color(EDGE, 0.8 * (1.0 - u / 0.15)), 0.0) # 틈에서 빠져나오는 섬광
			_comet(p, v, 4.2 * sz, 46.0 * minf(u * 4.0, 1.0) * sz, 1.0, t * 14.0 + float(b[0]) * 40.0)


# ═══════════════════════════════════════════════════════════
# 흑성 (대마법)
# ═══════════════════════════════════════════════════════════

## 흑성: 앞 150px에 세로로 틈이 열리고, 그 속에서 검은 별(블랙홀)이 나온다 — 납작하게 기운 강착 고리가 돌고(뒤쪽 반은 별 뒤, 앞쪽 반은 별 앞),
## 위로 휘어 보이는 빛 고리 · 둘레 공간이 휘는 렌즈(화면 셰이더) · 빨려 들며 소용돌이치는 불티. 2초 동안 끌어당기며 갈고(0.1초마다 30 × 20번),
## 한순간 쪼그라들었다가 붕괴 폭발(1500). 틈은 폭발 뒤 꿰매듯 닫힌다.
class BlackStar extends Spell:
	const CENTER := Vector2(150, -40) ## 발 기준 (앞으로 150 — 확장 물약은 앞 거리도 늘림)
	const HOLE_R := 26.0
	const EMERGE := 0.16 ## 검은 별이 나오기 시작
	const PULL_AT := 0.3
	const PULL_T := 2.0
	const COLLAPSE_T := 0.15 ## 끝에 쪼그라드는 시간
	const TICKS := 20
	const TICK_DMG := 30
	const TICK_R := 80.0
	const PULL_R := 240.0
	const PULL_SPEED := 170.0 ## 끌려가는 빠르기 (px/s)
	const BURST_DMG := 1500
	const BURST_R := 120.0
	const SPARKS := 46
	const LENS_SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float strength = 0.0; // 휘는 세기 (px²)
uniform float rad = 100.0; // 렌즈 반지름 (px)
uniform float hole = 20.0;
varying vec2 lp;
void vertex() { lp = VERTEX; }
void fragment() {
	float r = length(lp);
	vec2 d = lp / max(r, 0.001);
	float edge = smoothstep(rad, rad * 0.45, r);
	float shift = strength / max(r, hole) * edge;
	vec2 k = vec2(max(abs(dFdx(lp.x)), 0.0001), max(abs(dFdy(lp.y)), 0.0001));
	vec2 uv = SCREEN_UV + d * shift / k * SCREEN_PIXEL_SIZE;
	vec3 c = texture(screen_tex, uv).rgb;
	c *= 1.0 - 0.45 * edge * smoothstep(rad * 0.9, hole, r);
	c = mix(c, c * vec3(0.85, 0.6, 1.0), 0.5 * edge);
	COLOR = vec4(c, 1.0);
}
"""
	static var _lens_shader: Shader
	var c := Vector2.ZERO
	var _rift: RiftShape
	var _ticks := 0
	var _burst := false
	var _closed := false
	var _shake_t := 0.0
	var _sp := PackedVector3Array() ## 빨려 드는 불티: (각, 거리, 납작함 0/1)
	var _lens: Node2D
	var _lens_mat: ShaderMaterial

	func _begin() -> void:
		life = 3.35
		c = Vector2(CENTER.x * dir * sz, CENTER.y)
		_rift = RiftShape.new(c + Vector2(4.0 * dir, -54.0 * sz), c + Vector2(-4.0 * dir, 54.0 * sz), 15.0 * sz, 18, _seed, 3.0)
		for i in SPARKS:
			_sp.append(Vector3(randf() * TAU, randf_range(HOLE_R * 1.5, HOLE_R * 6.0) * sz, float(i % 2)))
		if _lens_shader == null:
			_lens_shader = Shader.new()
			_lens_shader.code = LENS_SHADER
		_lens_mat = ShaderMaterial.new()
		_lens_mat.shader = _lens_shader
		_lens = LensQuad.new()
		_lens.rad = 110.0 * sz
		_lens.position = c
		_lens.material = _lens_mat
		_lens.show_behind_parent = true
		add_child(_lens)
		_lens_mat.set_shader_parameter("rad", 110.0 * sz)
		_lens_mat.set_shader_parameter("hole", HOLE_R * sz)
		_lens_mat.set_shader_parameter("strength", 0.0)
		EVfx.sigil(g(c), 2.6)
		Sfx.play(&"es_blackstar", 0.0)
		Sfx.play_pitch(&"es_tear", 0.6, -2.0)
		Fx.zoom_punch(0.04)

	## 검은 별 반지름 (나옴 → 유지(살짝 맥박) → 쪼그라듦 → 0)
	func _hole_r() -> float:
		var end := PULL_AT + PULL_T
		if t < EMERGE:
			return 0.0
		var r := HOLE_R * sz * (1.0 - pow(1.0 - clampf((t - EMERGE) / 0.3, 0.0, 1.0), 3.0))
		r *= 1.0 + 0.05 * sin(t * 11.0)
		if t > end:
			r *= lerpf(1.0, 0.15, clampf((t - end) / COLLAPSE_T, 0.0, 1.0))
		return r if t < end + COLLAPSE_T else 0.0

	func _step(delta: float) -> void:
		var end := PULL_AT + PULL_T
		var gc := g(c)
		# 끌어당김 (끌 수 있는 것만 — 허수아비는 제자리에서 갈린다)
		if t >= PULL_AT and t < end and is_instance_valid(eska):
			for d: Node2D in EMagicFx.targets_in(get_tree(), gc, PULL_R * sz):
				if d.has_method("pull"):
					d.pull(gc, PULL_SPEED * sz, delta)
			while _ticks < TICKS and t >= PULL_AT + 0.05 + float(_ticks) * (PULL_T / float(TICKS)):
				_ticks += 1
				_hurt(gc, TICK_R * sz, TICK_DMG, false, true)
			_shake_t -= delta
			if _shake_t <= 0.0:
				_shake_t = 0.28
				Fx.shake(0.1 + 0.1 * (t - PULL_AT) / PULL_T, 0.3)
			# 둘레의 먼지·조각이 빨려 든다
			if randf() < 0.5:
				var a := randf() * TAU
				var from := gc + Vector2.from_angle(a) * randf_range(90.0, 150.0) * sz
				EVfx.dark_bits(from, 1, 10.0, Vector2.ZERO, 180.0, 0.4, 0)
		# 빨려 드는 불티: 가까울수록 빨리 돈다
		var hr := maxf(_hole_r(), 4.0)
		for i in _sp.size():
			var s := _sp[i]
			var rr := s.y - (30.0 + 1400.0 / maxf(s.y, 8.0)) * delta * (2.0 if t > end else 1.0)
			var aa := s.x + (1.6 + 90.0 / maxf(s.y, 8.0)) * delta * float(dir)
			if rr < hr * 1.05:
				rr = randf_range(HOLE_R * 4.0, HOLE_R * 6.5) * sz if t < end else 0.0
				aa = randf() * TAU
			_sp[i] = Vector3(aa, rr, s.z)
		# 렌즈 세기
		var lens := EMagicFx.smooth01((t - EMERGE) / 0.4) * (1.0 - EMagicFx.smooth01((t - end) / COLLAPSE_T))
		_lens_mat.set_shader_parameter("strength", 420.0 * sz * sz * lens)
		_lens.visible = lens > 0.01
		if not _burst and t >= end + COLLAPSE_T:
			_burst = true
			_explode()
		if not _closed and t >= end + COLLAPSE_T + 0.12:
			_closed = true
			Sfx.play_pitch(&"es_tear_close", 0.8, -4.0)

	func _explode() -> void:
		var gc := g(c)
		var n := _hurt(gc, BURST_R * sz, BURST_DMG, true, true)
		_boom(c, 46.0 * sz, false)
		EVfx.dark_burst(gc, 54.0 * sz)
		EVfx.shards(gc, 26, 300.0, Vector2(10, 10), 80.0)
		EVfx.pixels(gc, 30, 340.0, Vector2.ZERO, 180.0, 0.5)
		EVfx.feathers(gc, 7, 160.0, Vector2(12, 12))
		Fx.flash(Color(EDGE, 0.5), 0.3)
		Fx.shake(1.3, 0.5)
		Fx.zoom_punch(0.09)
		Fx.hitstop(0.12 if n > 0 else 0.06)
		PVfx.kick(Vector2(dir * 6.0, 0))

	func _disk(R: float, front: bool, a: float, spin: float) -> void:
		# 납작하게 기운 강착 고리: 뒤쪽 반(위)은 별 뒤에, 앞쪽 반(아래)은 별 앞에 그린다
		var tilt := -0.22 * float(dir)
		pd.draw_set_transform(c, tilt, Vector2(1.0, 0.3))
		var a0 := 0.0 if front else PI
		for k in 4:
			var rr := R * (1.35 + 0.32 * float(k))
			var col := [EDGE, STREAK, MAGENTA, BODY][k] as Color
			var w := maxf(R * (0.22 - 0.035 * float(k)), 1.0) / 0.3 * 0.42
			pd.draw_arc(Vector2.ZERO, rr, a0, a0 + PI, 22, Color(col, (0.85 - 0.15 * float(k)) * a), w)
			# 고리 위를 도는 밝은 줄무늬
			for q in 3:
				var s0 := fposmod(spin * (1.6 - 0.25 * float(k)) + float(q) * TAU / 3.0 + float(k), TAU)
				if (s0 > a0 and s0 < a0 + PI - 0.5):
					pd.draw_arc(Vector2.ZERO, rr, s0, s0 + 0.5, 6, Color(WHITE, 0.6 * a), w * 0.5)
		pd.draw_set_transform(Vector2.ZERO)

	func _draw_fx() -> void:
		var end := PULL_AT + PULL_T
		var R := _hole_r()
		var a := 1.0
		# 틈: 열리고 → 검은 별 뒤에서 버팀 → 폭발 뒤 꿰매어 닫힘
		var rip := EMagicFx.smooth01(t / 0.12)
		var open := EMagicFx.smooth01((t - 0.04) / 0.12) * (1.0 + 0.35 * clampf((t - PULL_AT) / PULL_T, 0.0, 1.0))
		var close_at := end + COLLAPSE_T + 0.08
		var zip := EMagicFx.smooth01((t - close_at) / 0.3) * 1.02 if t > close_at else 0.0
		var fade := 1.0 - clampf((t - close_at - 0.3) / 0.35, 0.0, 1.0)
		_rift.draw(pd, t, rip, open, zip, fade, 0.0, 1.4)
		if t < 0.13:
			_rift.crack(pd, rip, 1.0 - t / 0.13)
		if R > 0.5:
			# 둘레가 어두워지고, 안으로 조여 드는 고리
			pd.glow(c, R * 5.0, Color(INK, 0.5), 0.0)
			var ph := fposmod(t * 2.2, 1.0)
			var rr := lerpf(R * 5.0, R * 1.2, ph * ph)
			pd.draw_arc(c, rr, 0.0, TAU, 40, Color(BODY, 0.5 * ph), 1.5)
			pd.glow(c, R * 2.4, Color(MAGENTA, 0.28), 0.0)
			_disk(R, false, a, t * 3.0)
			# 위로 휘어 보이는 고리의 뒷면 (렌즈) + 빛 고리 (사건의 지평선 둘레)
			pd.draw_arc(c, R * 1.28, PI * 1.08, PI * 1.92, 20, Color(STREAK, 0.85), maxf(R * 0.14, 1.5))
			pd.draw_arc(c, R * 1.28, PI * 1.15, PI * 1.85, 16, Color(EDGE, 0.9), 1.0)
			pd.draw_circle(c, R * 1.1, Color(EDGE, 0.95))
			pd.draw_circle(c, R * 1.03, Color(MAGENTA, 1.0))
			pd.draw_circle(c, R, VOID)
			_disk(R, true, a, t * 3.0)
			# 빨려 드는 불티 (소용돌이)
			for s in _sp:
				if s.y <= R:
					continue
				var flat := 0.38 if s.z > 0.5 else 1.0
				var p := c + Vector2(cos(s.x) * s.y, sin(s.x) * s.y * flat).rotated(-0.22 * float(dir) * (1.0 if s.z > 0.5 else 0.0))
				var tang := Vector2(-sin(s.x), cos(s.x) * flat) * float(dir)
				var vv := tang * (6.0 + 300.0 / maxf(s.y, 8.0)) - (p - c).normalized() * 3.0
				var near := clampf(1.0 - s.y / (HOLE_R * 6.0 * sz), 0.0, 1.0)
				pd.line2(p - vv, p, Color(MAGENTA, 0.0), Color(EDGE.lerp(STREAK, s.z), 0.4 + 0.6 * near), 1.0, 1.0 + near)
		# 붕괴: 한 점으로 쪼그라드는 빛
		if t > end and t < end + COLLAPSE_T + 0.05:
			var k := clampf((t - end) / COLLAPSE_T, 0.0, 1.0)
			pd.glow(c, 10.0 + 30.0 * k * sz, Color(EDGE, 0.5 + 0.5 * k), 0.0)
			EVfx.star4(pd, c, (14.0 + 50.0 * k) * sz, t * 6.0, Color(WHITE, 0.9), Color(0, 0, 0, 0))
		# 폭발: 빛기둥 살 + 커지는 고리
		if _burst:
			var bt := t - (end + COLLAPSE_T)
			var e := 1.0 - pow(1.0 - clampf(bt / 0.4, 0.0, 1.0), 3.0)
			var f := 1.0 - clampf(bt / 0.55, 0.0, 1.0)
			if f > 0.0:
				pd.glow(c, BURST_R * sz * (0.6 + 0.8 * e), Color(MAGENTA, 0.35 * f), 0.0)
				for i in 14:
					var an := float(i) * TAU / 14.0 + float(_seed % 7)
					var d := Vector2.from_angle(an)
					var L := BURST_R * sz * (0.5 + 0.9 * e) * (0.7 + 0.5 * EVfx.hash01(i + _seed))
					pd.convex_colors(PackedVector2Array([c + d.orthogonal() * 4.0 * f, c + d * L, c - d.orthogonal() * 4.0 * f]),
						PackedColorArray([Color(EDGE, f), Color(MAGENTA, 0.0), Color(EDGE, f)]))
				pd.draw_arc(c, BURST_R * sz * 1.3 * e, 0.0, TAU, 48, Color(MAGENTA, f), 6.0 * f + 1.0)
				pd.draw_arc(c, BURST_R * sz * 1.3 * e - 3.0, 0.0, TAU, 48, Color(EDGE, f), 2.0 * f + 1.0)
				pd.draw_arc(c, BURST_R * sz * 0.8 * e, 0.0, TAU, 40, Color(BODY, 0.7 * f), 3.0 * f + 1.0)


## 흑성 렌즈: 둘레 화면을 안쪽으로 휘게 보이는 사각형 하나 (셰이더가 화면을 다시 읽어 그린다 — 흑성 노드 뒤에)
class LensQuad extends Node2D:
	var rad := 110.0

	func _draw() -> void:
		draw_rect(Rect2(-rad, -rad, rad * 2.0, rad * 2.0), Color.WHITE)


# ═══════════════════════════════════════════════════════════
# 유성우 (대마법)
# ═══════════════════════════════════════════════════════════

## 유성우: 화면 위쪽 하늘이 뒤에서 앞으로 길게 찢어져(꺾인 금) 밤하늘이 드러나고, 보랏빛 유성 12개가 1.6초 동안
## 앞쪽 400px 안으로 비스듬히 떨어진다 (하나 180, 반경 40). 떨어질수록 화면이 점점 크게 흔들린다. 끝나면 틈이 꿰매어 닫힌다.
class MeteorShower extends Spell:
	const SKY_Y := -236.0 ## 틈 높이 (발 기준)
	const FROM_X := -100.0
	const TO_X := 450.0
	const COUNT := 12
	const FIRST := 0.26
	const SPAN := 1.6 ## 유성이 나오는 시간 폭
	const FALL_T := 0.36 ## 떨어지는 데 걸리는 시간 (소리와 맞춤)
	const SLOPE := 0.45
	const LAND_MIN := 30.0
	const LAND_MAX := 410.0
	const DMG := 180
	const HIT_R := 40.0
	const RIP_T := 0.24
	const ORDER := [3, 9, 1, 6, 11, 4, 0, 8, 2, 10, 5, 7] ## 떨어지는 순서 (앞뒤로 흩어지게)
	var _rift: RiftShape
	var _rocks: Array = [] ## [나올 시각, 시작(로컬), 떨어질 자리(로컬), 끝났나, 땅인가, 번호]
	var _closed := false
	var _close_at := 0.0

	func _begin() -> void:
		life = 2.75
		var a := Vector2(FROM_X * dir, SKY_Y - 8.0)
		var b := Vector2(TO_X * dir * sz, SKY_Y + 14.0)
		_rift = RiftShape.new(a, b, 17.0, 36, _seed, 6.0)
		var dv := Vector2(dir * SLOPE, 1.0).normalized()
		for i in COUNT:
			var k: int = ORDER[i]
			var lx := lerpf(LAND_MIN, LAND_MAX, (float(k) + randf_range(0.15, 0.85)) / float(COUNT)) * sz
			# 떨어질 자리에서 거꾸로 올라가 틈 위의 시작점을 찾는다
			var sx := lx * dir - dv.x / dv.y * (0.0 - SKY_Y)
			var f := clampf((sx - a.x) / (b.x - a.x), 0.02, 0.98)
			var s := _rift.at(f)
			var land: Variant = _ray(g(s), g(s + dv * 700.0))
			var ground := land != null
			var lp: Vector2 = (land as Vector2) - position if ground else s + dv * (absf(SKY_Y) / dv.y)
			_rocks.append([FIRST + SPAN * float(i) / float(COUNT - 1) * 0.92 + randf_range(-0.03, 0.03), s, lp, false, ground, i, false])
		_close_at = FIRST + SPAN + FALL_T * 0.4
		Sfx.play_pitch(&"es_tear", 0.5, 0.0)
		Sfx.play_pitch(&"es_nakseong", 0.7, -6.0)
		Fx.shake(0.2, 0.3)

	func _step(_delta: float) -> void:
		for m: Array in _rocks:
			if m[3] or t < float(m[0]):
				continue
			var u := (t - float(m[0])) / FALL_T
			if not m[6]:
				m[6] = true
				Sfx.play_pitch(&"es_meteor", randf_range(0.92, 1.08), -5.0)
				EVfx.pixels(g(m[1]), 5, 110.0, Vector2.DOWN, 70.0, 0.22)
			var p := (m[1] as Vector2).lerp(m[2], pow(minf(u, 1.0), 1.5))
			if u < 1.0 and randf() < 0.7:
				EVfx.pixels(g(p), 1, 50.0, Vector2.UP, 100.0, 0.3)
			if u >= 1.0:
				m[3] = true
				_land(m[2], bool(m[4]), int(m[5]))
		if not _closed and t >= _close_at:
			_closed = true
			Sfx.play_pitch(&"es_tear_close", 0.7, -3.0)

	func _land(p: Vector2, ground: bool, i: int) -> void:
		var gp := g(p)
		var n := _hurt(gp, HIT_R * sz, DMG, true, true)
		_boom(p, 26.0 * sz, ground)
		EVfx.pixels(gp, 10, 220.0, Vector2.UP, 70.0, 0.4, Vector2(0, 420))
		EVfx.dark_bits(gp, 6, 160.0, Vector2.UP, 75.0, 0.4, 2)
		EVfx.shards(gp, 4, 170.0, Vector2(6, 2), 110.0)
		if i % 3 == 0:
			EVfx.feathers(gp, 1, 80.0, Vector2(6, 2), Vector2.UP)
		if ground:
			PVfx.dust(gp, 4, 1.4, 16.0)
		var last := i == COUNT - 1
		Fx.shake(0.18 + 0.05 * float(i) + (0.4 if last else 0.0), 0.24 if not last else 0.45)
		if n > 0:
			Fx.hitstop(0.03 if not last else 0.08)
		if last:
			Fx.zoom_punch(0.06)
			Fx.flash(Color(EDGE, 0.25), 0.2)

	func _draw_fx() -> void:
		var rip := EMagicFx.smooth01(t / RIP_T)
		var open := EMagicFx.smooth01((t - 0.05) / 0.2) * (1.0 + 0.1 * sin(t * 4.0))
		var zip := EMagicFx.smooth01((t - _close_at) / 0.4) * 1.02 if t > _close_at else 0.0
		var fade := 1.0 - clampf((t - _close_at - 0.4) / 0.3, 0.0, 1.0)
		_rift.draw(pd, t, rip, open, zip, fade, 0.0, 1.6)
		if t < RIP_T + 0.08:
			_rift.crack(pd, rip, 1.0 - clampf((t - RIP_T) / 0.08, 0.0, 1.0))
		for m: Array in _rocks:
			if m[3] or t < float(m[0]):
				continue
			var u := minf((t - float(m[0])) / FALL_T, 1.0)
			var s: Vector2 = m[1]
			var l: Vector2 = m[2]
			var p := s.lerp(l, pow(u, 1.5))
			var v := (l - s).normalized()
			if u < 0.18:
				pd.glow(s, 14.0, Color(EDGE, 0.8 * (1.0 - u / 0.18)), 0.0)
			_comet(p, v, 5.5, (60.0 + 80.0 * u) * minf(u * 5.0, 1.0), 1.0, t * 10.0 + float(m[5]), true)


# ═══════════════════════════════════════════════════════════
# 종말의 운석 (대마법)
# ═══════════════════════════════════════════════════════════

## 종말의 운석: 가장 가까운 적(없으면 앞 200px) 발밑에 마녀 문장 모양 예고 원(반경 120) → 그 위 하늘이 크게 찢어져
## 밤하늘과 그믐달이 보이고, 거대한 운석이 1.1초 걸려(처음엔 느리게, 끝엔 빠르게) 떨어진다.
## 부딪히면 3600 — 번쩍임·충격파 고리·파편·긴 흔들림, 땅엔 한동안 보랏빛 구덩이가 남는다. 느리니 속박·봉공과 연계.
class DoomMeteor extends Spell:
	const NO_TARGET := 200.0 ## 적이 없으면 앞으로 이만큼
	const REACH := 480.0 ## 이 거리 안의 가장 가까운 적을 노린다
	const RAD := 120.0
	const DMG := 3600
	const SKY := Vector2(-70, -252) ## 틈 가운데 (떨어질 자리 기준, 뒤로·위로)
	const TEAR_W := 92.0
	const OUT_T := 0.3 ## 운석이 틈에서 나오는 시각
	const FALL_T := 1.1
	const ROCK_R := 42.0
	var land := Vector2.ZERO ## 떨어질 자리 (로컬)
	var _rift: RiftShape
	var _sky := Vector2.ZERO
	var _hit := false
	var _closed := false
	var _rock := PackedVector2Array() ## 운석 모양 (단위)
	var _cracks: Array = [] ## 운석 표면의 빛나는 금 (단위 좌표 선분들)

	func _begin() -> void:
		life = OUT_T + FALL_T + 1.9
		var best: Node2D = null
		var bd := REACH
		if is_instance_valid(eska):
			for d: Node2D in ETarget.alive(get_tree()):
				var dd := (d.center() as Vector2).distance_to(eska.center())
				if dd < bd:
					bd = dd
					best = d
		var at := g(Vector2(NO_TARGET * dir * sz, -10.0))
		if best != null:
			at = Vector2((best.center() as Vector2).x, (best.hit_rect() as Rect2).end.y - 8.0)
		var hitp: Variant = _ray(at, at + Vector2(0, 600))
		land = ((hitp as Vector2) if hitp != null else at + Vector2(0, 10)) - position
		_sky = land + Vector2(SKY.x * dir, SKY.y)
		_rift = RiftShape.new(_sky + Vector2(-TEAR_W * dir, 10.0), _sky + Vector2(TEAR_W * dir, -10.0), 30.0, 26, _seed, 4.0, 0.02)
		for i in 13:
			var an := float(i) / 13.0 * TAU
			_rock.append(Vector2.from_angle(an) * (0.82 + 0.3 * EVfx.hash01(i * 3 + _seed)))
		for i in 5:
			var p0 := Vector2.from_angle(float(i) * 1.3 + 0.4) * 0.15
			var p1 := p0 + Vector2.from_angle(float(i) * 1.3 + 0.9) * 0.6
			var p2 := p1 + Vector2.from_angle(float(i) * 1.3 + 0.2) * 0.25
			_cracks.append([p0, p1, p2])
		EVfx.sigil(g(land + Vector2(0, -6)), 2.4)
		EVfx.sigil(g(_sky), 3.0)
		Sfx.play(&"es_doom", 0.0)
		Sfx.play_pitch(&"es_tear", 0.45, 0.0)
		Fx.shake(0.25, 0.4)

	func _fall_u() -> float:
		return clampf((t - OUT_T) / FALL_T, 0.0, 1.0)

	func _rock_pos(u: float) -> Vector2:
		var e := pow(u, 2.3) # 처음엔 느리게, 끝엔 빠르게
		return _sky.lerp(land + Vector2(0, -ROCK_R * sz * 0.5), e)

	func _step(_delta: float) -> void:
		var u := _fall_u()
		if t > OUT_T and not _hit:
			var p := g(_rock_pos(u))
			if randf() < 0.9:
				EVfx.pixels(p + Vector2(randf_range(-10, 10), randf_range(-10, 10)) * sz, 2, 90.0, (g(_sky) - p).normalized(), 50.0, 0.35)
			if u > 0.5 and randf() < 0.5:
				EVfx.dark_bits(p, 1, 40.0, (g(_sky) - p).normalized(), 40.0, 0.5, 1)
			Fx.shake(0.04 + 0.22 * u * u, 0.1)
		if not _hit and u >= 1.0:
			_hit = true
			_impact()
		# 구덩이에서 피어오르는 불씨
		if _hit and t < life - 0.4 and randf() < 0.5:
			EVfx.pixels(g(land + Vector2(randf_range(-0.7, 0.7) * RAD * sz, -2.0)), 1, 50.0, Vector2.UP, 25.0, 0.6, Vector2(0, -30))
		if not _closed and t >= OUT_T + FALL_T * 0.72:
			_closed = true
			Sfx.play_pitch(&"es_tear_close", 0.6, -2.0)

	func _impact() -> void:
		var gl := g(land)
		var n := _hurt(gl + Vector2(0, -6), RAD * sz, DMG, true, true)
		_boom(land + Vector2(0, -4), 60.0 * sz, true)
		EVfx.dark_burst(gl + Vector2(0, -16), 64.0 * sz)
		EVfx.shards(gl + Vector2(0, -8), 36, 360.0, Vector2(30, 6), 220.0)
		EVfx.pixels(gl, 36, 420.0, Vector2.UP, 80.0, 0.6, Vector2(0, 420))
		EVfx.dark_bits(gl, 22, 300.0, Vector2.UP, 85.0, 0.6, 8)
		EVfx.feathers(gl + Vector2(0, -20), 9, 190.0, Vector2(30, 8), Vector2.UP)
		PVfx.dust(gl, 10, 2.2, 60.0)
		Fx.flash(Color(EDGE, 0.5), 0.3)
		Fx.hitstop(0.16 if n > 0 else 0.08)
		Fx.shake(1.8, 0.8)
		Fx.zoom_punch(0.12)
		PVfx.kick(Vector2(0, 7))

	func _draw_fx() -> void:
		var u := _fall_u()
		var R := RAD * sz
		var impact_t := OUT_T + FALL_T
		# 땅의 예고 원: 마녀 문장(원 + 일곱 갈래 별)이 납작하게 깔리고, 안쪽 원이 차오르면 떨어진다
		if t < impact_t + 0.1:
			var wa := EMagicFx.smooth01(t / 0.15) * (1.0 - clampf((t - impact_t) / 0.1, 0.0, 1.0))
			var pulse := 0.75 + 0.25 * sin(t * (10.0 + 14.0 * u))
			pd.draw_set_transform(land, 0.0, Vector2(1.0, 0.26))
			pd.glow(Vector2.ZERO, R, Color(MAGENTA, 0.16 * wa), 0.1)
			pd.draw_circle(Vector2.ZERO, R * EMagicFx.smooth01(t / impact_t), Color(PLUM, 0.32 * wa))
			pd.draw_arc(Vector2.ZERO, R, 0.0, TAU, 48, Color(MAGENTA, 0.95 * wa * pulse), 3.0)
			pd.draw_arc(Vector2.ZERO, R * 0.86, 0.0, TAU, 44, Color(STREAK, 0.6 * wa), 2.0)
			var sp := t * 0.9
			for i in 7:
				var p0 := Vector2.from_angle(sp + float(i) * TAU / 7.0) * R * 0.84
				var p1 := Vector2.from_angle(sp + float(i + 2) * TAU / 7.0) * R * 0.84
				pd.draw_line(p0, p1, Color(EDGE, 0.55 * wa * pulse), 2.4)
			pd.draw_set_transform(Vector2.ZERO)
		# 하늘의 큰 틈 (안에 그믐달)
		var rip := EMagicFx.smooth01(t / 0.22)
		var open := EMagicFx.smooth01((t - 0.06) / 0.24)
		var close_at := OUT_T + FALL_T * 0.72
		var zip := EMagicFx.smooth01((t - close_at) / 0.45) * 1.02 if t > close_at else 0.0
		var fade := 1.0 - clampf((t - close_at - 0.45) / 0.35, 0.0, 1.0)
		_rift.draw(pd, t, rip, open, zip, fade, 0.0, 2.0)
		if t < 0.24:
			_rift.crack(pd, rip, 1.0 - t / 0.24)
		var moon_a := EMagicFx.smooth01((t - 0.15) / 0.2) * (1.0 - EMagicFx.smooth01((t - close_at) / 0.25))
		if moon_a > 0.01:
			var mc := _rift.at(0.68) + Vector2(0, -3)
			pd.glow(mc, 16.0, Color(PALE, 0.3 * moon_a), 0.0)
			pd.draw_circle(mc, 8.0, Color(PALE.lerp(WHITE, 0.4), 0.95 * moon_a))
			pd.draw_circle(mc + Vector2(-3.4 * dir, -2.2), 7.4, Color(VOID, moon_a))
		# 운석
		if t > OUT_T and not _hit:
			var p := _rock_pos(u)
			var prev := _rock_pos(maxf(u - 0.05, 0.0))
			var v := (p - prev).normalized() if p.distance_to(prev) > 0.01 else Vector2.DOWN
			var rr := ROCK_R * sz * (0.55 + 0.45 * EMagicFx.smooth01(u * 3.0))
			var tail := (50.0 + 260.0 * u * u) * sz
			var o := v.orthogonal()
			pd.glow(p, rr * 3.2, Color(MAGENTA, 0.3), 0.0)
			pd.convex_colors(PackedVector2Array([p + o * rr * 1.25, p - o * rr * 1.25, p - v * tail]),
				PackedColorArray([Color(BODY, 0.75), Color(BODY, 0.75), Color(PLUM, 0.0)]))
			pd.convex_colors(PackedVector2Array([p + o * rr * 0.85, p - o * rr * 0.85, p - v * tail * 0.75]),
				PackedColorArray([Color(MAGENTA, 0.9), Color(MAGENTA, 0.9), Color(MAGENTA, 0.0)]))
			pd.convex_colors(PackedVector2Array([p + o * rr * 0.45, p - o * rr * 0.45, p - v * tail * 0.45]),
				PackedColorArray([Color(EDGE, 0.95), Color(EDGE, 0.95), Color(STREAK, 0.0)]))
			# 바위: 검보라 몸 + 앞쪽(떨어지는 쪽)이 달아오른 테 + 빛나는 금
			var rot := t * 1.6 * float(dir)
			var rim := PackedVector2Array()
			var body := PackedVector2Array()
			var back := PackedVector2Array()
			for q in _rock:
				back.append(p + q.rotated(rot) * rr * 1.1)
				rim.append(p + q.rotated(rot) * rr * 1.04 + v * rr * 0.16)
				body.append(p + q.rotated(rot) * rr - v * rr * 0.04)
			pd.draw_colored_polygon(back, Color(MAGENTA, 0.75)) # 뒤쪽은 보랏빛 테
			pd.draw_colored_polygon(rim, Color(EDGE, 0.95)) # 떨어지는 쪽(앞)은 달아오른 흰 테
			pd.draw_colored_polygon(body, INK)
			pd.glow(p + v * rr * 0.35, rr * 0.9, Color(MAGENTA, 0.5), 0.0)
			for cr: Array in _cracks:
				var a0: Vector2 = p + (cr[0] as Vector2).rotated(rot) * rr
				var a1: Vector2 = p + (cr[1] as Vector2).rotated(rot) * rr
				var a2: Vector2 = p + (cr[2] as Vector2).rotated(rot) * rr
				pd.draw_line(a0, a1, Color(STREAK, 0.95), 1.5)
				pd.draw_line(a1, a2, Color(MAGENTA, 0.9), 1.0)
			pd.glow(p - v * rr * 0.2, rr * 0.35, Color(PLUM, 0.6), 0.0)
		# 충돌: 빛기둥 · 퍼지는 충격파 · 구덩이 빛
		if _hit:
			var bt := t - impact_t
			var e := 1.0 - pow(1.0 - clampf(bt / 0.7, 0.0, 1.0), 3.0)
			var f := 1.0 - clampf(bt / 0.8, 0.0, 1.0)
			if f > 0.0:
				var bw := (36.0 * sz) * f
				pd.convex_colors(PackedVector2Array([land + Vector2(-bw, 0), land + Vector2(bw, 0), land + Vector2(bw * 0.2, -300.0), land + Vector2(-bw * 0.2, -300.0)]),
					PackedColorArray([Color(EDGE, f), Color(EDGE, f), Color(MAGENTA, 0.0), Color(MAGENTA, 0.0)]))
				pd.glow(land + Vector2(0, -20), R * (0.6 + e), Color(MAGENTA, 0.45 * f), 0.0)
				pd.draw_arc(land + Vector2(0, -30), R * 1.5 * e, PI, TAU, 40, Color(MAGENTA, f), 5.0 * f + 1.0)
				pd.draw_arc(land + Vector2(0, -30), R * 1.5 * e - 3.0, PI, TAU, 40, Color(EDGE, f), 2.0 * f + 1.0)
				pd.draw_set_transform(land, 0.0, Vector2(1.0, 0.22))
				pd.draw_arc(Vector2.ZERO, R * 2.2 * e, 0.0, TAU, 48, Color(STREAK, f), 9.0 * f + 1.0)
				pd.draw_arc(Vector2.ZERO, R * 1.4 * e, 0.0, TAU, 44, Color(EDGE, 0.8 * f), 4.0 * f + 1.0)
				pd.draw_set_transform(Vector2.ZERO)
				# 땅에 방사로 갈라지는 금
				for i in 9:
					var an := PI + float(i) / 8.0 * PI
					var d := Vector2(cos(an), sin(an) * 0.22)
					pd.line2(land, land + d * R * (0.6 + 0.6 * EVfx.hash01(i + _seed)) * e, Color(WHITE, f), Color(MAGENTA, 0.0), 2.0, 1.0)
			var ca := 1.0 - clampf((bt - 0.3) / (life - impact_t - 0.4), 0.0, 1.0)
			if ca > 0.0:
				var fl := 0.8 + 0.2 * sin(t * 13.0)
				pd.draw_set_transform(land, 0.0, Vector2(1.0, 0.24))
				pd.glow(Vector2.ZERO, R * 0.9, Color(MAGENTA, 0.45 * ca * fl), 0.0)
				pd.draw_circle(Vector2.ZERO, R * 0.42, Color(INK, 0.8 * ca))
				pd.draw_arc(Vector2.ZERO, R * 0.44, 0.0, TAU, 36, Color(STREAK, 0.8 * ca * fl), 3.0)
				pd.draw_set_transform(Vector2.ZERO)
