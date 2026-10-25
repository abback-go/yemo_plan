class_name EVfx
extends RefCounted
## 에스카 이펙트 v2 (전부 코드 그림, 수명이 끝나면 스스로 사라짐).
## 색 언어(다크 참격, 스컬 '다크팔라딘' 참고): 검보라 테두리 → 짙은 자두빛 → 보라·마젠타 몸통(결 따라 가는 줄무늬) → 분홍빛 흰 앞날.
## 한두 프레임 꽉 찼다가 꼬리부터 걷히며 가늘어지고 옅어진다. 맞은 자리엔 빨강·흰 바늘 X자, 큰 타격엔 어둠 폭발.
## 파랑은 쓰지 않는다. 참격은 보통 섞기(검은 테두리가 보이게), 빛·불티만 가산 섞기.
## 참격 레퍼런스 = 던전슬래셔 기본공격(캐릭터보다 몇 배 큰 초승달, 들쭉날쭉한 가장자리, 얇은 궤적선, 네모 픽셀 불티, 맞은 자리의 흰 금),
## 천열 = 앞으로 크고 긴 다크 참격 열 번, 단공 = 머리 위를 납작한 다크 회오리가 연달아 휘감음 + 어둠 폭발,
## 2026-10-11 "공간을 찢는" 말투로 바꿈 (design.md 3-1·3-4): 참격·마법은 찢긴 틈(rift — 흰 금 → 벌어짐, 안은 검은 무 + 별빛,
## 보랏빛·분홍빛 흰 테) → 유리 파편과 까마귀 깃털(Feathers) → 꿰매듯 다시 닫힘. 시전엔 마녀 문장(sigil). 어둠 폭발도 잠깐 뚫렸다 닫히는 구멍.
## 성능: 이펙트 하나 = 노드 하나 = 그리기 호출 하나(PDraw 묶음). 입자는 PParticles 한 노드, 유리 파편은 Shards 한 노드, 깃털은 Feathers 한 노드.

const WHITE := Color(1, 1, 1)
const PALE := Color("#d9ccff")
const VIOLET := Color("#a98bff")
const DEEP := Color("#5b3fc0")
const CLEAR := Color(0.66, 0.55, 1.0, 0.0)
const INK := Color("#14081f") ## 참격 바깥 검보라 테두리
const PLUM := Color("#3b1268")
const BODY := Color("#9b3cff")
const MAGENTA := Color("#e352ff")
const STREAK := Color("#f293ff") ## 몸통 안 결무늬
const EDGE := Color("#ffe4fb") ## 앞날 분홍빛 흰색
const HIT_RED := Color("#ff2f58")


static func add(n: Node2D, pos: Vector2, additive := false) -> Node2D:
	return PVfx.add(n, pos, additive)


## 호 띠: 바깥 반지름 r, 가장 굵은 곳 w, a0(꼬리) → a1(머리), 꼬리색 → 머리색. jag = 바깥 가장자리 들쭉날쭉(찢긴 공간)
static func band(pd: PDraw, r: float, a0: float, a1: float, w: float, c_tail: Color, c_head: Color, seg := 22, jag := 0.0, jseed := 0) -> void:
	if absf(a1 - a0) < 0.03 or w < 0.3:
		return
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in seg + 1:
		var f := float(i) / float(seg)
		var a := lerpf(a0, a1, f)
		var thick := w * sin(pow(f, 0.72) * PI)
		var jr := 0.0
		if jag > 0.0 and i > 0 and i < seg:
			jr = (fposmod(sin(float(i * 37 + jseed) * 12.9898) * 43758.5453, 1.0) - 0.35) * jag * (thick / w)
		var d := Vector2(cos(a), sin(a))
		outer.append(d * (r + jr))
		inner.append(d * (r - thick))
	pd.strip_grad(outer, inner, c_tail, c_head)


## 휘어진 칼날 위의 한 점: p0에서 dir로 len만큼 나아가며 옆(dir의 수직)으로 bend×len×f² 만큼 휜다
static func curve_point(p0: Vector2, dir: Vector2, len: float, bend: float, f: float) -> Vector2:
	return p0 + dir * len * f + dir.orthogonal() * bend * len * f * f


## 휘어진 칼날(초승달 깃): 양 끝이 뾰족하고 가운데가 굵다. f0~f1 구간만 그린다(자라나기·걷히기). 뿌리색 → 끝색
static func curve_blade(pd: PDraw, p0: Vector2, dir: Vector2, len: float, bend: float, w: float, c_tail: Color, c_head: Color, f0 := 0.0, f1 := 1.0, seg := 12) -> void:
	if f1 - f0 < 0.02 or w < 0.3:
		return
	var nrm := dir.orthogonal()
	var l := PackedVector2Array()
	var r := PackedVector2Array()
	for i in seg + 1:
		var f := lerpf(f0, f1, float(i) / float(seg))
		var c := p0 + dir * len * f + nrm * bend * len * f * f
		var tan := (dir + nrm * bend * 2.0 * f).normalized()
		var n := tan.orthogonal()
		var ww := w * pow(sin(f * PI), 0.75) * 0.5
		l.append(c + n * ww)
		r.append(c - n * ww)
	pd.strip_grad(l, r, c_tail, c_head)


## 휘어진 칼날 한 자루 (다크 질감: 검보라 테두리 → 자두빛 → 보라·마젠타 → 분홍빛 흰 심) — 종언참·봉공 X자가 같이 쓴다
static func feather(pd: PDraw, p0: Vector2, dir: Vector2, len: float, bend: float, w: float, a: float, f0 := 0.0, f1 := 1.0, seg := 12) -> void:
	curve_blade(pd, p0, dir, len, bend, w * 3.2, Color(MAGENTA, 0.0), Color(MAGENTA, 0.15 * a), f0, f1, maxi(seg - 4, 6))
	curve_blade(pd, p0, dir, len, bend, w * 2.1, Color(INK, 0.0), Color(INK, 0.9 * a), f0, f1, seg)
	curve_blade(pd, p0, dir, len, bend, w, Color(PLUM, 0.3 * a), Color(MAGENTA, a), f0, f1, seg)
	curve_blade(pd, p0, dir, len, bend, w * 0.35, Color(STREAK, 0.0), Color(EDGE, a), f0, f1, seg)


## 다크 참격 띠 (호): 바깥 반지름 r, 굵기 w, a0(꼬리) → a1(머리). tail_a = 꼬리 쪽 진하기(0이면 투명하게 사라짐)
## 겹: 검보라 테두리(바깥으로 삐져나옴) · 자두빛 · 보라→마젠타 몸통 · 결무늬 3줄 · 분홍빛 흰 앞날
static func dark_band(pd: PDraw, r: float, a0: float, a1: float, w: float, a: float, jseed := 0, seg := 26, tail_a := 0.0, lite := false) -> void:
	if a <= 0.01 or absf(a1 - a0) < 0.03:
		return
	var span := a1 - a0
	# 큰 호도 각지지 않게 호 길이(약 9px)마다 한 마디
	var sg := clampi(maxi(seg, int(absf(span) * r / 9.0)), 6, 48)
	if not lite:
		band(pd, r + w * 0.45, a0 + span * 0.1, a1, w * 2.3, Color(MAGENTA, 0.0), Color(MAGENTA, 0.16 * a), maxi(sg - 8, 6)) # 번짐
	band(pd, r + w * 0.18, a0, a1, w * 1.42, Color(INK, 0.92 * a * tail_a), Color(INK, 0.92 * a), sg, w * 0.16, jseed)
	band(pd, r + w * 0.06, a0 + span * 0.03, a1, w * 1.14, Color(PLUM, a * tail_a), Color(PLUM, a), sg, w * 0.08, jseed + 5)
	band(pd, r, a0 + span * 0.07, a1, w, Color(BODY, a * tail_a), Color(MAGENTA, a), sg)
	for k in (1 if lite else 3):
		var fk := float(k)
		band(pd, r - w * (0.2 + 0.19 * fk), a0 + span * (0.16 + 0.12 * fk), a1 - span * 0.03 * fk, w * (0.1 - 0.018 * fk),
			Color(STREAK, 0.4 * a * tail_a), Color(STREAK, (0.75 - 0.15 * fk) * a), maxi(sg - 6, 6))
	band(pd, r + 0.5, a0 + span * 0.2, a1, w * 0.3, Color(EDGE, a * tail_a), Color(EDGE, a), maxi(sg - 4, 6))


## 마녀 문장(紋章): 원 두 겹 + 일곱 갈래 별(오각별은 피함) + 작은 룬이 번쩍이며 돌다가 사라진다 (design.md 3-4, 약 0.25초).
## size 1 = 손끝 크기(반지름 10px), 2.5 = 등 뒤의 의식 고리. 소리(es_sigil)도 여기서 낸다 — 부르는 쪽은 따로 틀지 않는다
static func sigil(pos: Vector2, size := 1.0) -> void:
	var s := Sigil.new()
	s.size = size
	add(s, pos, true)
	Sfx.play_pitch(&"es_sigil", randf_range(0.95, 1.08) * (1.0 if size < 1.8 else 0.8), -14.0 if size < 1.8 else -7.0)


## 불티·조각 층마다 살아 있는 입자 상한 (loop3_plan 5장: 큰 마법이 겹쳐도 200을 넘지 않게 — 넘으면 새 입자를 덜 만든다)
const PARTICLE_CAP := 130 ## (상한 200 안에서 여유 — 다른 이펙트가 직접 넣는 입자 몫)


## 큰 화면 섬광: 하얗게 번쩍이면 화면이 지워져 보여서, 보랏빛(기본)이나 뼈흰빛으로 물들이고 2프레임만 (loop2_plan 6장)
const FLASH_VIOLET := Color("#8a5ce0")
const FLASH_BONE := Color("#e9dfcc")
const FLASH_T := 2.0 / 60.0


static func big_flash(strength := 0.35, bone := false) -> void:
	Fx.flash(Color(FLASH_BONE if bone else FLASH_VIOLET, strength), FLASH_T)


## 튕겨냄(단공이 발사체를 지움): 짧게 번쩍이는 네 갈래 별 + 작은 고리 + 유리 파편 — 한 노드.
## strong = "딱 맞춤"(몸 가까이서 지움): 별·고리가 두 배 크고 오래, 파편·불티도 많음 (이르면 작은 불꽃만 — 보상이 눈에 구분되게)
static func deflect_spark(pos: Vector2, strong := false) -> void:
	var sp := DeflectSpark.new()
	sp.strong = strong
	add(sp, pos, true)
	shards(pos, 8 if strong else 2, 200.0 if strong else 120.0, Vector2(2, 2), 60.0)
	pixels(pos, 12 if strong else 4, 260.0 if strong else 160.0, Vector2.ZERO, 180.0, 0.26)


class DeflectSpark extends PVfx.Base:
	var strong := false

	func _ready() -> void:
		life = 0.3 if strong else 0.16
		z_index = 8

	func _paint() -> void:
		var x := k()
		var f := 1.0 - x
		var s := 2.0 if strong else 1.0
		var grow := 1.0 - pow(1.0 - minf(x * 3.0, 1.0), 2.0)
		pd.glow(Vector2.ZERO, (12.0 * f + 4.0) * s, Color(EDGE, 0.8 * f), 0.0)
		EVfx.star4(pd, Vector2.ZERO, (14.0 * (0.5 + 0.5 * grow) * f + 2.0) * s, 0.785, Color(WHITE, f), Color(MAGENTA, 0.3 * f))
		pd.draw_arc(Vector2.ZERO, (4.0 + 14.0 * grow) * s, 0.0, TAU, 18, Color(MAGENTA, 0.9 * f), 1.5 * s)
		if strong: # 딱 맞춤: 바깥으로 한 겹 더 퍼지는 분홍빛 흰 고리
			pd.draw_arc(Vector2.ZERO, 10.0 + 40.0 * grow, 0.0, TAU, 24, Color(EDGE, 0.8 * f), 1.0)


# ═══════════════════════════════════════════════════════════
# 찢긴 틈 (모든 마법이 같이 쓰는 "공간이 찢어지는" 그림)
# ═══════════════════════════════════════════════════════════

const VOID := Color("#06020d") ## 찢긴 틈 안의 무(無) — INK보다 한 단계 더 깊은 밤
const RIFT_STAR_GAP := 13.0 ## 틈 안 별빛 간격(px, 틈 길이 기준) (루프3: 10 → 13, 도형 수)
const RIFT_STAR_MAX := 24 ## (루프3: 34 → 24, 도형 수)
## 틈의 겹(뒤→앞): [테 굵기 px, 반폭에 비례한 테, 색, 벌어진 곳만] — 마젠타 번짐 → 보랏빛 → 마젠타 테 → 분홍빛 흰 테 → 검은 무
const RIFT_LAYERS := [[5.5, 0.6, Color(MAGENTA, 0.17), false], [2.6, 0.15, Color(BODY, 0.55), false],
	[1.7, 0.0, Color(MAGENTA, 0.95), false], [0.8, 0.0, EDGE, false], [0.0, 0.0, VOID, true]]
const RIFT_RIBBONS := 7 ## 겹 다섯 + 안쪽으로 새어 드는 빛 두 줄
const RIFT_RING_EXTRA := 2 ## 테만 그리는 모드(void_a < 1)에서 늘어나는 띠 (번짐을 뺀 테 겹 셋이 위·아래 둘로: 4 → 6)

static var _jag_cache := {} ## (jseed, 점 수) → [위 들쭉날쭉, 아래 들쭉날쭉, 테 들쭉날쭉×끝 뾰족함, 끝 뾰족함]
static var _idx_cache := {} ## (시작 번호, 점 수) → 띠 일곱 줄의 삼각형 번호 (같은 노드는 프레임마다 같은 자리에 그려서 거의 늘 재사용)
static var _star_cache := {} ## (jseed, 점 수, 개수) → 별 자리 [마디 위치, 가로 비율]


## 0~1 고정 난수 (같은 i면 늘 같은 값 — 들쭉날쭉한 가장자리가 프레임마다 떨리지 않게)
static func hash01(i: int) -> float:
	return fposmod(sin(float(i) * 12.9898 + 78.233) * 43758.5453, 1.0)


## 찢긴 결: 대부분 잘게 흔들리고, 가끔 길게 삐져나온 조각(가시). 양 끝은 뾰족하게
static func _jag_of(jseed: int, n: int) -> Array:
	var key := jseed * 4096 + n
	var got: Variant = _jag_cache.get(key)
	if got != null:
		return got
	var ju := PackedFloat32Array()
	var jl := PackedFloat32Array()
	var rt := PackedFloat32Array()
	var tip := PackedFloat32Array()
	ju.resize(n)
	jl.resize(n)
	rt.resize(n)
	tip.resize(n)
	for i in n:
		var su := 0.55 if hash01(i * 29 + jseed * 13 + 1) > 0.82 else 0.0
		var sl := 0.5 if hash01(i * 37 + jseed * 5 + 4) > 0.84 else 0.0
		ju[i] = 1.0 + (hash01(i * 7 + jseed) - 0.5) * 0.36 + su
		jl[i] = 1.0 + (hash01(i * 13 + jseed * 3 + 5) - 0.5) * 0.36 + sl
		var f := float(i) / float(n - 1)
		tip[i] = maxf(pow(sin(f * PI), 0.6), 0.12)
		rt[i] = (0.5 + 1.0 * hash01(i * 5 + jseed * 7 + 2)) * tip[i]
	if _jag_cache.size() > 512:
		_jag_cache.clear()
	var out := [ju, jl, rt, tip]
	_jag_cache[key] = out
	return out


## 찢긴 틈: 가운데 선 pts를 따라 점마다 바깥 방향 nrm으로 반폭 hw만큼 공간이 벌어진다 (al = 점마다 진하기).
## 겹(뒤→앞): 마젠타 번짐 → 보랏빛 가장자리 → 분홍빛 흰 테 → 검은 무(밤하늘) → 가장자리에서 새어 드는 보랏빛 → 별빛.
## 반폭이 0인 곳(꿰매어 닫힌 곳)은 테만 남아 가는 빛 줄(꿰맨 자국)이 된다. 가장자리는 찢긴 종이처럼 들쭉날쭉(jseed).
## nrm은 단위 벡터가 아니어도 된다(납작하게 누른 호는 누른 만큼 짧은 벡터). ghost 0~1 = 메아리(무가 비치고 옅음)
## void_a = 검은 무의 진하기 (천열처럼 큰 틈이 겹쳐도 뒤의 표적이 비쳐 보이게 낮춤). 1보다 작으면 테 겹들을 틈 안까지 채우지 않고
## 위·아래 테로만 그린다 (안을 채우면 흰 테가 비쳐 틈이 허옇게 보임 — 띠가 넷 늘어남)
## 성능: 겹 일곱 줄을 꼭짓점 묶음 하나로 한 번에 넣는다 (삼각형 번호는 기억해 두고 다시 씀)
static func rift(pd: PDraw, pts: PackedVector2Array, nrm: PackedVector2Array, hw: PackedFloat32Array, al: PackedFloat32Array,
		jseed := 0, t := 0.0, ghost := 0.0, star_k := 1.0, void_a := 1.0) -> void:
	var n := pts.size()
	if n < 2:
		return
	var jg: Array = _jag_of(jseed, n)
	var ju: PackedFloat32Array = jg[0]
	var jl: PackedFloat32Array = jg[1]
	var rt: PackedFloat32Array = jg[2]
	var tip: PackedFloat32Array = jg[3]
	var n2 := n * 2
	var ring := void_a < 0.99
	var strips := RIFT_RIBBONS + (RIFT_RING_EXTRA if ring else 0) - (2 if ring else 0) # 테만 모드는 안으로 새어 드는 빛 두 줄도 뺌 (무가 옅어 안 보임)
	var lite := false # (원본: 큰 마법이 겹친 때는 가장 넓은 마젠타 번짐을 뺀다 — 이 프로토타입엔 큰 마법이 없음)
	if lite:
		strips -= 1
	var vs := PackedVector2Array()
	var cs := PackedColorArray()
	vs.resize(n2 * strips)
	cs.resize(n2 * strips)
	var ga := 1.0 - 0.6 * ghost
	var o := 0
	for ly: Array in RIFT_LAYERS:
		var ex: float = ly[0]
		var exh: float = ly[1]
		var col: Color = ly[2]
		var open_only: bool = ly[3]
		if open_only:
			col.a = (1.0 - 0.3 * ghost) * void_a
		elif ex < 1.0:
			col = Color(col.lerp(PALE, ghost), ga)
		else:
			col.a *= ga
		if lite and exh > 0.3:
			continue
		if ring and not open_only:
			if exh > 0.3: # 가장 넓은 마젠타 번짐은 테만 모드에서 뺀다 (도형 수 — 무가 옅어 번짐 없이도 테가 읽힘)
				continue
			# 테만: 위 (바깥 → 틈 가장자리) · 아래 (틈 가장자리 → 바깥)
			for side in 2:
				var sg := 1.0 if side == 0 else -1.0
				var jj := ju if side == 0 else jl
				for i in n:
					var h := hw[i]
					var nm := nrm[i] * sg
					var e := ex * rt[i] + h * exh * tip[i]
					vs[o] = pts[i] + nm * (h * jj[i] + e)
					vs[o + 1] = pts[i] + nm * (h * jj[i])
					var cc := Color(col.r, col.g, col.b, col.a * al[i])
					cs[o] = cc
					cs[o + 1] = cc
					o += 2
			continue
		for i in n:
			var h := hw[i]
			var nm := nrm[i]
			var e := ex * rt[i] + h * exh * tip[i]
			var a := col.a * al[i]
			if open_only and h < 0.4:
				e = 0.0
				a = 0.0
			vs[o] = pts[i] + nm * (h * ju[i] + e)
			vs[o + 1] = pts[i] - nm * (h * jl[i] + e)
			var cc := Color(col.r, col.g, col.b, a)
			cs[o] = cc
			cs[o + 1] = cc
			o += 2
	# 가장자리에서 무 쪽으로 새어 드는 보랏빛 (테 → 안쪽으로 투명해짐) — 루미너스 같은 빛 번짐
	var rl := Color(BODY, 0.75 * ga)
	var clear := Color(BODY, 0.0)
	for side in (0 if ring else 2):
		var sg := 1.0 if side == 0 else -1.0
		var jj := ju if side == 0 else jl
		for i in n:
			var off := nrm[i] * (hw[i] * jj[i] * sg)
			vs[o] = pts[i] + off
			vs[o + 1] = pts[i] + off * 0.45
			cs[o] = Color(rl.r, rl.g, rl.b, rl.a * al[i] * minf(hw[i] * 0.4, 1.0))
			cs[o + 1] = clear
			o += 2
	var base := pd.v.size()
	pd.v.append_array(vs if pd._id else pd.xf * vs)
	pd.c.append_array(cs)
	pd.idx.append_array(_ribbon_idx(base, n, strips))
	if star_k > 0.0:
		_rift_stars(pd, pts, nrm, hw, al, jseed, t, star_k * ga)


## 띠 일곱 줄(줄마다 점 n개, 꼭짓점 2n개)의 삼각형 번호 — 시작 번호 base부터
static func _ribbon_idx(base: int, n: int, strips := RIFT_RIBBONS) -> PackedInt32Array:
	var key := (base * 256 + n) * 16 + strips
	var got: Variant = _idx_cache.get(key)
	if got != null:
		return got
	var idx := PackedInt32Array()
	idx.resize(strips * (n - 1) * 6)
	var k := 0
	for r in strips:
		var b0 := base + r * n * 2
		for i in n - 1:
			var q := b0 + i * 2
			idx[k] = q
			idx[k + 1] = q + 2
			idx[k + 2] = q + 1
			idx[k + 3] = q + 1
			idx[k + 4] = q + 2
			idx[k + 5] = q + 3
			k += 6
	if _idx_cache.size() > 160:
		_idx_cache.clear()
	_idx_cache[key] = idx
	return idx


## 틈 안의 별빛: 몇 개는 십자로 반짝이고 나머지는 한 점. 틈이 벌어진 만큼만 보인다
static func _rift_stars(pd: PDraw, pts: PackedVector2Array, nrm: PackedVector2Array, hw: PackedFloat32Array, al: PackedFloat32Array,
		jseed: int, t: float, k: float) -> void:
	var n := pts.size()
	var total := pts[0].distance_to(pts[n / 2]) + pts[n / 2].distance_to(pts[n - 1])
	var cnt := mini(int(total / RIFT_STAR_GAP * minf(k, 2.0)), RIFT_STAR_MAX)
	var key := (jseed * 4096 + n) * 64 + cnt
	var st: Variant = _star_cache.get(key)
	if st == null:
		var sfi := PackedFloat32Array()
		var su := PackedFloat32Array()
		for s in cnt:
			sfi.append(hash01(s * 31 + jseed * 17 + 3) * float(n - 1))
			su.append((hash01(s * 23 + jseed * 11 + 9) - 0.5) * 1.3)
		if _star_cache.size() > 256:
			_star_cache.clear()
		st = [sfi, su]
		_star_cache[key] = st
	var fis: PackedFloat32Array = st[0]
	var us: PackedFloat32Array = st[1]
	var kk := minf(k, 1.0)
	for s in cnt:
		var fi := fis[s]
		var i0 := mini(int(fi), n - 2)
		var fr := fi - float(i0)
		var h := lerpf(hw[i0], hw[i0 + 1], fr)
		if h < 2.0:
			continue
		var p := pts[i0].lerp(pts[i0 + 1], fr) + nrm[i0] * (h * us[s])
		var tw := 0.5 + 0.5 * sin(t * (7.0 + float(s % 5)) + float(s) * 2.3)
		var a := al[i0] * minf((h - 2.0) * 0.35, 1.0) * kk
		var col := WHITE if s % 3 == 0 else (PALE if s % 3 == 1 else STREAK)
		if s % 7 == 0:
			var c := Color(col, a * (0.5 + 0.5 * tw))
			pd.draw_rect(Rect2(p.x - 1.5, p.y - 0.5, 3.0, 1.0), c)
			pd.draw_rect(Rect2(p.x - 0.5, p.y - 1.5, 1.0, 3.0), c)
		else:
			pd.draw_rect(Rect2(p.x - 0.5, p.y - 0.5, 1.0, 1.0), Color(col, a * (0.35 + 0.65 * tw)))


## 곧은(살짝 휜) 틈의 모양: a → b 선을 seg 마디로 나눠 가운데 선·바깥 방향·반폭을 만든다.
## 반폭 = width × 눈 모양(sin) × 들쭉날쭉. zip 0~1 = 그 앞까지 꿰매어 닫힘(a 쪽부터), kink = 가운데 선이 꺾이는 정도(px)
static func rift_line(a: Vector2, b: Vector2, width: float, seg: int, kseed: int, kink := 0.0, bend := 0.0) -> Array:
	var pts := PackedVector2Array()
	var nrm := PackedVector2Array()
	var hw := PackedFloat32Array()
	var d := b - a
	var ln := d.length()
	var dn := d / maxf(ln, 0.001)
	var on := dn.orthogonal()
	for i in seg + 1:
		var f := float(i) / float(seg)
		var kk := 0.0
		if i > 0 and i < seg:
			kk = (hash01(i * 19 + kseed) - 0.5) * 2.0 * kink
		pts.append(a + d * f + on * (kk + bend * ln * sin(f * PI)))
		nrm.append(on)
		hw.append(width * pow(sin(f * PI), 0.7) * (0.75 + 0.5 * hash01(i * 3 + kseed * 5)))
	return [pts, nrm, hw]


## 틈의 열림·닫힘을 점마다 정한다: open 0~1 = 벌어진 정도, zip 0~1 = 처음 쪽부터 꿰매어 닫힌 위치, seam = 꿰맨 자국의 진하기
static func rift_open(hw: PackedFloat32Array, open: float, zip: float, seam: float, fade := 1.0) -> Array:
	var n := hw.size()
	var h2 := PackedFloat32Array()
	var al := PackedFloat32Array()
	h2.resize(n)
	al.resize(n)
	for i in n:
		var f := float(i) / float(maxi(n - 1, 1))
		var z := 1.0
		if zip > 0.0:
			z = clampf((f - zip) / 0.18, 0.0, 1.0) # 지퍼 바로 앞은 렌즈처럼 좁아짐
			z = z * z * (3.0 - 2.0 * z)
		h2[i] = hw[i] * open * z
		al[i] = fade * (1.0 if f >= zip else seam * clampf(1.0 - (zip - f) * 3.0, 0.0, 1.0))
	return [h2, al]


## 하얀 금: 공간이 찢어지기 직전 가는 흰 금이 번쩍인다 (꺾인 선 + 잔가지). a = 진하기
static func crack(pd: PDraw, pts: PackedVector2Array, nrm: PackedVector2Array, a: float, cseed := 0) -> void:
	if a <= 0.01 or pts.size() < 2:
		return
	var n := pts.size()
	var prev := pts[0]
	for i in range(1, n):
		var nl := nrm[i].normalized()
		var p := pts[i] + nl * (hash01(i * 11 + cseed) - 0.5) * 3.0
		pd.draw_line(prev, p, Color(WHITE, a), 1.0)
		if i % 4 == 2:
			var br := nl * (5.0 + 6.0 * hash01(i + cseed)) * (1.0 if i % 8 == 2 else -1.0)
			pd.draw_line(p, p + br + (pts[i] - pts[i - 1]) * 0.4, Color(EDGE, a * 0.7), 1.0)
		prev = p
	pd.glow(pts[n / 2], 10.0, Color(EDGE, 0.35 * a), 0.0)


## 네 갈래 별빛 (반짝이는 별 조각·불티): 가로·세로 마름모 두 개 + 빛무리
static func star4(pd: PDraw, p: Vector2, r: float, rot: float, core: Color, glow_col: Color) -> void:
	if glow_col.a > 0.0:
		pd.glow(p, r * 1.6, glow_col, 0.0)
	for q in 2:
		var d := Vector2.from_angle(rot + float(q) * PI * 0.5) * r
		var o := d.orthogonal() * 0.2
		pd.convex(PackedVector2Array([p + d, p + o, p - d, p - o]), core)


## 까마귀 깃털: 깨진 파편 일부가 검은 깃털로 흩날린다 (design.md 3-4) — Feathers 한 노드가 모두 그린다
static func feathers(pos: Vector2, n: int, speed: float, area := Vector2.ZERO, dir := Vector2.ZERO) -> void:
	var f := Feathers.get_layer()
	for i in n:
		var p := pos + Vector2(randf_range(-area.x, area.x), randf_range(-area.y, area.y))
		var d := dir if dir != Vector2.ZERO else Vector2.from_angle(randf() * TAU)
		d = d.rotated(randf_range(-0.7, 0.7))
		f.spawn(p, d * randf_range(speed * 0.4, speed) + Vector2(0, -randf_range(20.0, 60.0)), randf_range(Feathers.LEN_MIN, Feathers.LEN_MAX))


## 흩날리는 검은 깃털 — 장면에 한 노드 (보통 섞기: 검은색이 보이게, 보랏빛 테로 어둠 속에서도 읽힘)
class Feathers extends PDraw.Canvas:
	const MAX := 28 ## (루프3: 90 → 28, 도형 수)
	const LEN_MIN := 6.5 ## 깃털 길이(px) — 너무 작으면 보라 조각으로 읽혀 마녀 신호가 안 읽힘 (loop4_plan 6장: 7px)
	const LEN_MAX := 7.5
	const RIM := 1.0 ## 옅은 보랏빛 테 두께(px): 어두운 배경에서도 깃털 모양이 보이게
	static var _inst: Feathers
	var pos := PackedVector2Array()
	var vel := PackedVector2Array()
	var age := PackedFloat32Array()
	var life := PackedFloat32Array()
	var sz := PackedFloat32Array()
	var ph := PackedFloat32Array() ## 흔들림 위상

	static func get_layer() -> Feathers:
		if is_instance_valid(_inst) and _inst.is_inside_tree():
			return _inst
		_inst = Feathers.new()
		_inst.z_index = 4
		Fx.effect_parent().add_child(_inst)
		return _inst

	func spawn(p: Vector2, v: Vector2, s: float) -> void:
		if pos.size() >= MAX:
			return
		pos.append(p)
		vel.append(v)
		age.append(0.0)
		life.append(randf_range(0.9, 1.5))
		sz.append(s)
		ph.append(randf() * TAU)

	func _process(delta: float) -> void:
		var i := 0
		while i < pos.size():
			age[i] += delta
			if age[i] >= life[i]:
				pos.remove_at(i)
				vel.remove_at(i)
				age.remove_at(i)
				life.remove_at(i)
				sz.remove_at(i)
				ph.remove_at(i)
				continue
			var v := vel[i]
			v *= maxf(1.0 - 3.2 * delta, 0.0) # 공기에 금방 멎고
			v.y = minf(v.y + 120.0 * delta, 38.0) # 천천히 내려앉는다
			vel[i] = v
			pos[i] += v * delta
			i += 1
		if not pos.is_empty() or not pd.is_empty():
			queue_redraw()

	func _paint() -> void:
		for i in pos.size():
			var k := age[i] / life[i]
			var a := minf(k * 8.0, 1.0) * (1.0 - pow(k, 3.0))
			var sw := sin(age[i] * 5.0 + ph[i])
			var p := pos[i] + Vector2(sw * 4.0 * minf(age[i] * 2.0, 1.0), 0.0) # 이리저리 흔들리며
			var rot := ph[i] + sw * 0.7 + age[i] * 0.5
			var L := sz[i]
			var d := Vector2.from_angle(rot)
			var o := d.orthogonal()
			var w := L * 0.26
			var shape := PackedVector2Array([p + d * L * 0.5, p + d * L * 0.12 + o * w, p - d * L * 0.36 + o * w * 0.7, p - d * L * 0.5,
				p - d * L * 0.36 - o * w * 0.55, p + d * L * 0.12 - o * w * 0.85])
			var rim := PackedVector2Array()
			for q in shape:
				rim.append(q + (q - p).normalized() * RIM)
			pd.convex(rim, Color(VIOLET, 0.5 * a))
			pd.convex(shape, Color(INK, 0.95 * a))
			pd.draw_line(p - d * L * 0.7, p + d * L * 0.45, Color(WHITE, 0.9 * a), 1.0) # 흰 깃대 1px (몸보다 조금 길게 — 깃털로 읽히게)


## 마녀 문장: 원 두 겹 + 일곱 갈래 별 {7/2} + 원 사이 작은 룬 일곱. 툭 커지며 번쩍 → 돌며 옅어짐 (가산)
class Sigil extends PVfx.Base:
	const RADIUS := 10.0 ## size 1의 반지름
	## 룬 일곱 (작은 획 두세 개 — 어느 글자도 아닌 마녀 글씨)
	const RUNES := [
		[Vector2(0, -1), Vector2(0, 1), Vector2(0, -0.2), Vector2(0.7, -0.9)],
		[Vector2(-0.6, -1), Vector2(0.6, 1), Vector2(0.6, -1), Vector2(-0.6, 1)],
		[Vector2(0, -1), Vector2(0, 1), Vector2(-0.7, 0), Vector2(0.7, 0)],
		[Vector2(-0.6, 1), Vector2(0, -1), Vector2(0, -1), Vector2(0.6, 1)],
		[Vector2(0, -1), Vector2(0, 1), Vector2(0, 0.2), Vector2(-0.7, -0.6)],
		[Vector2(-0.7, -0.8), Vector2(0.7, -0.8), Vector2(0, -0.8), Vector2(0, 1)],
		[Vector2(-0.6, 0.9), Vector2(0.6, -0.9), Vector2(-0.2, -0.3), Vector2(0.5, 0.4)],
	]
	const FINGER_MIN := 1.4 ## 손끝 문장 최소 크기 — 이보다 작으면 일곱 갈래 별이 뭉개져 안 읽힘 (loop2_plan 6장)
	const POP := 0.05 ## 툭 커지는 시간
	const HOLD := 2.0 / 60.0 ## 다 커진 뒤 돌지 않고 멈춰 보이는 시간 (2프레임 — 별 모양이 읽히게)
	var size := 1.0
	var _spin := 0.0

	func _ready() -> void:
		size = maxf(size, FINGER_MIN)
		life = lerpf(0.25, 0.42, clampf((size - 1.0) / 1.5, 0.0, 1.0)) + HOLD
		z_index = 7
		_spin = randf() * TAU

	func _paint() -> void:
		var x := k()
		var pop := 1.0 - pow(1.0 - clampf(t / POP, 0.0, 1.0), 3.0)
		var moving := maxf(t - POP - HOLD, 0.0) # 멈춤이 끝난 뒤부터 돌고 커지며 옅어짐
		var mx := clampf(moving / maxf(life - POP - HOLD, 0.01), 0.0, 1.0)
		var R := RADIUS * size * (0.55 + 0.45 * pop) * (1.0 + 0.12 * mx)
		var a := 1.0 if mx < 0.3 else pow(1.0 - (mx - 0.3) / 0.7, 1.4)
		var small := size < 1.8
		var lw := maxf(1.0, 0.55 * size)
		var sp := _spin + moving * 4.0
		if t < 0.07:
			pd.glow(Vector2.ZERO, R * 1.3, Color(EDGE, 0.6 * (1.0 - t / 0.07)), 0.0)
		if true: # (원본: 큰 마법이 겹친 때는 바깥 빛무리를 뺀다 — 이 프로토타입엔 큰 마법이 없음)
			pd.glow(Vector2.ZERO, R * 1.5, Color(MAGENTA, (0.12 if small else 0.22) * a), 0.0)
		var segs := 14 + int(size * 5.0)
		pd.draw_arc(Vector2.ZERO, R, 0.0, TAU, segs, Color(EDGE, 0.95 * a), lw)
		if not small: # 작은 문장은 안쪽 원을 빼서 별 끝과 겹쳐 뭉개지지 않게
			pd.draw_arc(Vector2.ZERO, R * 0.8, 0.0, TAU, segs, Color(MAGENTA, 0.8 * a), maxf(lw * 0.7, 1.0))
		# 일곱 갈래 별 {7/2}: 꼭짓점 k → k+2 (작은 문장은 별을 원에 닿게 크게)
		var st := PackedVector2Array()
		var sr := R * (0.9 if small else 0.78)
		for i in 7:
			st.append(Vector2.from_angle(sp + float(i) * TAU / 7.0) * sr)
		for i in 7:
			pd.draw_line(st[i], st[(i + 2) % 7], Color(STREAK.lerp(EDGE, 0.6 if small else 0.4), a), lw)
		# 원 사이 룬 (작으면 생략) — 별과 반대로 돈다
		if not small:
			var rr := R * 0.9
			for i in 7:
				var an := -sp * 0.6 + float(i) * TAU / 7.0 + TAU / 14.0
				var c := Vector2.from_angle(an) * rr
				var rn: Array = RUNES[i]
				var s := R * 0.07
				var rt := an + PI * 0.5
				for q in range(0, rn.size(), 2):
					pd.draw_line(c + (rn[q] as Vector2).rotated(rt) * s, c + (rn[q + 1] as Vector2).rotated(rt) * s, Color(EDGE, 0.9 * a), 1.0)
		pd.glow(Vector2.ZERO, R * (0.16 if small else 0.3), Color(WHITE, 0.7 * a), 0.0)


## 보랏빛 조각 + 연기 (보통 섞기 — 부서진 참격이 흩어지는 것)
static func dark_bits(pos: Vector2, n: int, speed: float, dir := Vector2.ZERO, spread := 180.0, life := 0.35, smoke := 0) -> void:
	var pp := PParticles.get_layer(false)
	var room := PARTICLE_CAP - pp.count()
	n = mini(n, room)
	smoke = mini(smoke, maxi(room - n, 0))
	var base := dir.angle() if dir != Vector2.ZERO else 0.0
	for i in n:
		var an := base + deg_to_rad(randf_range(-spread, spread))
		var v := Vector2(cos(an), sin(an)) * randf_range(speed * 0.3, speed)
		var col := MAGENTA if randf() < 0.6 else STREAK
		pp.spawn(pos, v, Vector2(0, 60), life * randf_range(0.6, 1.0), randf_range(1.6, 3.2), col, PLUM, 0, 3.5)
	for i in smoke:
		var v := Vector2(randf_range(-30, 30), randf_range(-36, -6)) + dir * randf_range(10, 40)
		pp.spawn(pos + Vector2(randf_range(-6, 6), randf_range(-6, 6)), v, Vector2.ZERO, randf_range(0.35, 0.6), randf_range(4.0, 7.0),
			Color(PLUM, 0.55), Color(INK, 0.0), 2, 3.0)


## 어둠 폭발 (큰 타격·마무리) → 「찢김 렌즈」: 작은 틈이 눈 모양으로 툭 벌어져 안에 밤하늘(검은 무 + 별빛)이 보이고,
## 한쪽 끝부터 꿰매듯 닫히며 깃털 몇 개가 흩날린다 (2026-10-11 루프2: 검은 원판 + 가시는 싸구려 표창처럼 보여 바꿈).
## 크기는 예전의 절반쯤 (rad = 예전 원판 반지름 — 부르는 쪽은 그대로). 장면의 Lenses 한 노드가 모두 그린다
static func dark_burst(pos: Vector2, rad: float) -> void:
	Lenses.get_layer().spawn(pos, rad)
	dark_bits(pos, int(3 + rad * 0.1), rad * 3.0, Vector2.ZERO, 180.0, 0.32, 0)
	feathers(pos, 3 if rad >= 40.0 else 2, 40.0 + rad * 1.5, Vector2(rad * 0.3, rad * 0.15))


## 네모 픽셀 불티 (흰색 → 보라로 사라짐)
static func pixels(pos: Vector2, n: int, speed: float, dir := Vector2.ZERO, spread := 180.0, life := 0.3, grav := Vector2.ZERO) -> void:
	var pp := PParticles.get_layer(true)
	n = mini(n, PARTICLE_CAP - pp.count())
	var base := dir.angle() if dir != Vector2.ZERO else 0.0
	for i in n:
		var a := base + deg_to_rad(randf_range(-spread, spread))
		var sp := randf_range(speed * 0.35, speed)
		pp.spawn(pos, Vector2(cos(a), sin(a)) * sp, grav, life * randf_range(0.6, 1.0), randf_range(1.0, 2.2), WHITE, VIOLET, 0, 3.0)


## 유리 파편 (돌며 떨어지는 작은 삼각형)
static func shards(pos: Vector2, n: int, speed: float, area := Vector2.ZERO, up := 60.0) -> void:
	var s := Shards.get_layer()
	for i in n:
		var p := pos + Vector2(randf_range(-area.x, area.x), randf_range(-area.y, area.y))
		var dir := (p - pos).normalized() if area != Vector2.ZERO else Vector2.from_angle(randf() * TAU)
		if dir == Vector2.ZERO:
			dir = Vector2.from_angle(randf() * TAU)
		s.spawn(p, dir * randf_range(speed * 0.4, speed) + Vector2(0, -up), randf_range(1.6, 3.4))


## 맞은 자리: 십자 섬광 + 흰 금 + 고리 + 파편 (모든 타격 섬광은 Impacts 한 노드가 그린다 — 다단히트 스킬에서 노드가 수십 개 생기지 않게)
static func hit_crack(pos: Vector2, heavy: bool, dir: float) -> void:
	var d := dir if dir != 0.0 else 1.0
	Impacts.get_layer().spawn(pos, heavy)
	pixels(pos, 5 if heavy else 3, 210.0 if heavy else 140.0, Vector2(d, -0.3), 70.0, 0.28, Vector2(0, 300))
	dark_bits(pos, 6 if heavy else 3, 190.0 if heavy else 120.0, Vector2(d, -0.2), 80.0, 0.34, 0)
	if heavy:
		dark_burst(pos, 26.0)
		shards(pos, 6, 150.0, Vector2(3, 3), 80.0)


static func land_dust(pos: Vector2) -> void:
	PVfx.dust(pos, 5, 1.4, 12.0)


## 잔상: 에스카의 마지막 그림을 그대로 보랏빛으로
static func afterimage(art: EArt, life := 0.25, tint := VIOLET, offset := Vector2.ZERO, strength := 1.0) -> void:
	if art.snap_i.is_empty():
		return
	var a := Afterimage.new()
	a.v = art.snap_v
	a.idx = art.snap_i
	a.life = life
	a.tint = tint
	a.strength = strength
	a.z_index = -6 # 이펙트 층(5) 기준 → 캐릭터 뒤
	a.material = Fx.add_material
	Fx.effect_parent().add_child(a)
	a.global_transform = art.snap_xf.translated(offset)


class Afterimage extends Node2D:
	var v := PackedVector2Array()
	var idx := PackedInt32Array()
	var life := 0.25
	var tint := VIOLET
	var strength := 1.0 ## 진하기 (1 = 기본)
	var t := 0.0
	var _cols := PackedColorArray()
	var stretch_dir := 0 ## 0이 아니면: 이 방향으로 가늘고 길게 늘어나며 빨려 들어감 (순간이동 출발)
	var stretch_c := Vector2.ZERO ## 늘어나는 축의 중심 (전역)
	var base_xf := Transform2D.IDENTITY

	func _process(delta: float) -> void:
		t += delta
		if t >= life:
			queue_free()
			return
		if stretch_dir != 0:
			var e := 1.0 - pow(1.0 - t / life, 2.0)
			var sx := lerpf(1.0, 3.2, e)
			var sy := lerpf(1.0, 0.12, e)
			var shift := float(stretch_dir) * 26.0 * e
			var c := stretch_c
			global_transform = Transform2D(Vector2(sx, 0), Vector2(0, sy), Vector2(c.x + shift - c.x * sx, c.y - c.y * sy)) * base_xf
		queue_redraw()

	func _draw() -> void:
		var a := (1.0 - t / life)
		_cols.resize(v.size())
		_cols.fill(Color(tint, 0.5 * strength * a * a))
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), idx, v, _cols)


## 돌며 떨어지는 유리 파편 — 장면에 한 노드
class Shards extends PDraw.Canvas:
	static var _inst: Shards
	var pos := PackedVector2Array()
	var vel := PackedVector2Array()
	var rot := PackedFloat32Array()
	var rv := PackedFloat32Array()
	var sz := PackedFloat32Array()
	var age := PackedFloat32Array()
	var life := PackedFloat32Array()

	static func get_layer() -> Shards:
		if is_instance_valid(_inst) and _inst.is_inside_tree():
			return _inst
		_inst = Shards.new()
		_inst.z_index = 3
		_inst.material = Fx.add_material
		Fx.effect_parent().add_child(_inst)
		return _inst

	func spawn(p: Vector2, v: Vector2, s: float) -> void:
		if pos.size() > 260:
			return
		pos.append(p)
		vel.append(v)
		rot.append(randf() * TAU)
		rv.append(randf_range(-18.0, 18.0))
		sz.append(s)
		age.append(0.0)
		life.append(randf_range(0.45, 0.8))

	func _process(delta: float) -> void:
		var i := 0
		while i < pos.size():
			age[i] += delta
			if age[i] >= life[i]:
				pos.remove_at(i)
				vel.remove_at(i)
				rot.remove_at(i)
				rv.remove_at(i)
				sz.remove_at(i)
				age.remove_at(i)
				life.remove_at(i)
				continue
			vel[i] += Vector2(0, 520) * delta
			vel[i] *= 1.0 - 1.5 * delta
			pos[i] += vel[i] * delta
			rot[i] += rv[i] * delta
			i += 1
		if not pos.is_empty() or not pd.is_empty():
			queue_redraw()

	func _paint() -> void:
		for i in pos.size():
			var f := 1.0 - age[i] / life[i]
			var d := Vector2.from_angle(rot[i]) * sz[i]
			var n := d.orthogonal() * 0.45
			var flick := 0.6 + 0.4 * absf(sin(rot[i] * 2.0)) # 돌면서 빛을 받았다 잃었다
			pd.draw_colored_polygon(PackedVector2Array([pos[i] + d, pos[i] + n - d * 0.6, pos[i] - n - d * 0.3]), Color(PALE.lerp(WHITE, flick), f * flick))


## 찢김 렌즈 (dark_burst) — 장면에 한 노드, 여러 렌즈를 함께 그린다 (보통 섞기, 찢긴 틈과 같은 그림 EVfx.rift)
class Lenses extends PDraw.Canvas:
	const MAX := 4 ## 동시에 보이는 렌즈 (넘으면 가장 오래된 것을 지움 — 도형 수)
	const OPEN := 0.05 ## 툭 벌어지는 시간
	const HOLD := 0.06
	const ZIP := 0.14 ## 꿰매어 닫히는 시간
	const SEAM := 0.1 ## 꿰맨 자국이 사라지는 시간
	const LEN_K := 0.75 ## 렌즈 반 길이 = rad × 이 값
	const WIDE_K := 0.3 ## 렌즈 반 폭 = rad × 이 값
	const SEG := 6
	static var _inst: Lenses
	var items: Array = [] ## [나이, 가운데 선, 바깥 방향, 반폭, 번호, 위치, rad]

	static func get_layer() -> Lenses:
		if is_instance_valid(_inst) and _inst.is_inside_tree():
			return _inst
		_inst = Lenses.new()
		_inst.z_index = 6
		Fx.effect_parent().add_child(_inst)
		return _inst

	func spawn(pos: Vector2, rad: float) -> void:
		if items.size() >= MAX:
			items.pop_front()
		var sd := randi() % 997
		var an := randf_range(0.25, 0.8) * (-1.0 if randf() < 0.5 else 1.0)
		var d := Vector2.from_angle(an) * rad * LEN_K
		var r: Array = EVfx.rift_line(pos - d, pos + d, rad * WIDE_K, SEG, sd, rad * 0.04)
		items.append([0.0, r[0], r[1], r[2], sd, pos, rad])

	func _process(delta: float) -> void:
		if items.is_empty():
			return
		queue_redraw() # 마지막 렌즈가 사라지는 프레임에도 한 번 더 그려 지운다
		var i := 0
		while i < items.size():
			items[i][0] = float(items[i][0]) + delta
			if float(items[i][0]) >= OPEN + HOLD + ZIP + SEAM:
				items.remove_at(i)
				continue
			i += 1

	func _paint() -> void:
		for it: Array in items:
			var t: float = it[0]
			var o := clampf(t / OPEN, 0.0, 1.0)
			var open := o * o * (3.0 - 2.0 * o) * (1.0 + 0.25 * sin(clampf(t / (OPEN + HOLD), 0.0, 1.0) * PI))
			var z := clampf((t - OPEN - HOLD) / ZIP, 0.0, 1.0)
			var zip := z * z * (3.0 - 2.0 * z) * 1.02
			var fade := 1.0 - clampf((t - OPEN - HOLD - ZIP) / SEAM, 0.0, 1.0)
			var pos: Vector2 = it[5]
			var rad: float = it[6]
			var oz: Array = EVfx.rift_open(it[3], open, zip, 0.9, fade)
			EVfx.rift(pd, it[1], it[2], oz[0], oz[1], int(it[4]), t, 0.0, 0.7)
			if t < OPEN:
				pd.glow(pos, rad * 0.45, Color(EDGE, 0.85 * (1.0 - t / OPEN)), 0.0) # 뚫리는 순간의 분홍빛 흰 심
			elif zip > 0.0 and zip < 1.0:
				var pts: PackedVector2Array = it[1]
				var zi := clampi(int(zip * float(SEG)), 0, SEG)
				EVfx.star4(pd, pts[zi], 2.5 + rad * 0.04, t * 9.0, Color(EDGE, 0.9 * fade), Color(MAGENTA, 0.4 * fade)) # 꿰매는 바늘 끝


## 맞은 자리: 가늘고 긴 빨강·흰 바늘이 X자로 교차 + 작은 섬광 + 마젠타 고리 — 장면에 한 노드, 여러 타격을 함께 그린다 (가산)
class Impacts extends PDraw.Canvas:
	const IMPACT_MAX := 10 ## 동시에 그리는 타격 섬광 (루프3: 40 → 10, 도형 수)
	static var _inst: Impacts
	var items: Array = [] ## [위치, 나이, 수명, 큼, 바늘 각도들]

	static func get_layer() -> Impacts:
		if is_instance_valid(_inst) and _inst.is_inside_tree():
			return _inst
		_inst = Impacts.new()
		_inst.z_index = 7
		_inst.material = Fx.add_material
		Fx.effect_parent().add_child(_inst)
		return _inst

	func spawn(pos: Vector2, heavy: bool) -> void:
		if items.size() >= IMPACT_MAX:
			items.pop_front()
		var base := randf_range(0.5, 1.1) * (-1.0 if randf() < 0.5 else 1.0)
		var angs := PackedFloat32Array([base, base + randf_range(1.2, 1.9)])
		if heavy:
			angs.append(base + randf_range(0.5, 0.9))
		items.append([pos, 0.0, 0.24 if heavy else 0.16, heavy, angs])

	func _process(delta: float) -> void:
		var i := 0
		while i < items.size():
			items[i][1] += delta
			if float(items[i][1]) >= float(items[i][2]):
				items.remove_at(i)
				continue
			i += 1
		if not items.is_empty() or not pd.is_empty():
			queue_redraw()

	func _paint() -> void:
		for it: Array in items:
			var pos: Vector2 = it[0]
			var heavy: bool = it[3]
			var k := float(it[1]) / float(it[2])
			var f := 1.0 - k
			var reach := (46.0 if heavy else 30.0) * (1.0 - pow(1.0 - minf(k * 4.0, 1.0), 2.0)) # 순식간에 뻗는다
			pd.glow(pos, (16.0 if heavy else 10.0) * (0.6 + 0.4 * f), Color(EDGE, 0.7 * f), 0.0)
			for an: float in it[4]:
				var d := Vector2.from_angle(an)
				var n := d.orthogonal()
				var hw := (2.4 if heavy else 1.7) * f
				pd.draw_colored_polygon(PackedVector2Array([pos - d * reach, pos + n * hw, pos + d * reach, pos - n * hw]), Color(HIT_RED, 0.95 * f))
				pd.draw_colored_polygon(PackedVector2Array([pos - d * reach * 0.8, pos + n * hw * 0.35, pos + d * reach * 0.8, pos - n * hw * 0.35]), Color(WHITE, f))
			pd.draw_arc(pos, lerpf(4.0, 24.0 if heavy else 14.0, k), 0.0, TAU, 12, Color(MAGENTA, 0.85 * f), 1.6 if heavy else 1.2)
