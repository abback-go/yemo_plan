class_name SeraArt
extends Node2D
## 세라 그림 (시제품 v2 — 사용자 참고 그림 기준). 원점 = 발밑 가운데, 오른쪽을 보는 기준으로 그리고 부모가 scale.x로 뒤집는다.
## 비율: 작은 머리·긴 다리의 날씬한 5등신 (키 약 39px, 모자 끝까지 약 49px). 어두운 화면에서 실루엣이 또렷하게.
## 의상: 붉은 머리(옆으로 내린 땋은 머리 + 초록 잎 장식)·보라 눈·금 단추 두 줄의 남색 군복풍 롱코트(뒤로 길게 날리는 꼬리 자락)·
## 붉은 프릴 치마(검은 레이스 단)·붉은 커프스 검은 장갑(손 둘레에 작은 불꽃)·짙은 타이츠·붉은 장미 검은 구두·남색 마녀 모자(금 띠·장미).
## 변신(fox = true): 모자를 벗고 흰 여우 귀·꼬리(PState.tails개)·푸른 불 발톱·여우 발이 나오고 푸른 불꽃이 감돈다.
## 몸 흔들림(머리카락·코트 자락·꼬리)은 간단한 용수철로 — 속도(vel)에 따라 뒤로 날린다.

# ─── 색 ───
const OUT := Color("#140b16") ## 윤곽
const SKIN := Color("#ffe6d6")
const SKIN_SH := Color("#e9b19f")
const HAIR := Color("#d8352c")
const HAIR_HI := Color("#ff7a52")
const HAIR_SH := Color("#8e1d27")
const LEAF := Color("#63c46b")
const LEAF_D := Color("#2c7a3c")
const EYE := Color("#a46cf0")
const COAT := Color("#1f2a52")
const COAT_HI := Color("#34457e")
const COAT_SH := Color("#121a36")
const COAT_IN := Color("#6b1628") ## 코트 안감
const GOLD := Color("#f0c050")
const GOLD_D := Color("#a8782a")
const SKIRT := Color("#d22a3a")
const SKIRT_HI := Color("#f25560")
const SKIRT_SH := Color("#8e1526")
const LACE := Color("#241520")
const GLOVE := Color("#2a2030")
const CUFF := Color("#d02a3a")
const TIGHTS := Color("#2c2440")
const SHOE := Color("#120d16")
const ROSE := Color("#e3303f")
const HAT := Color("#1f2a52")
const HAT_HI := Color("#34457e")
const FUR := Color("#f6f8ff")
const FUR_SH := Color("#c9d6f0")

const HIP_Y := -16.5 ## 발밑 기준 엉덩이 높이
const HEAD := Vector2(0.6, -17.2) ## 엉덩이 기준 머리 가운데
const THIGH := 8.4
const SHIN := 8.0

# ─── 세라가 매 프레임 넣는 값 ───
var pose := "idle" ## idle run jump fall dash throw throw_up throw_down focus cast shield hurt wall glide drink charge
var vel := Vector2.ZERO
var t := 0.0 ## 누적 시간
var run_phase := 0.0
var atk_step := 0 ## 기본공격 0 오른손 · 1 왼손 · 2 두 손
var atk_k := 1.0 ## 던지기 진행 0→1
var fox := false ## 변신
var tails := 1
var flash := 0.0 ## 피격 흰빛 (modulate로 처리)
var blink_hidden := false ## 무적 깜빡임
var focus_k := 0.0 ## 집중 세기 0~1
var charge_k := 0.0 ## 열선 압축 0~1
var od := 0.0 ## 폭주 게이지 0~1 (70%부터 몸에 불티, 가득 차면 손의 불꽃이 커짐)
var land_k := 0.0 ## 착지 눌림 1→0
var shadow_y := 0.0 ## 발밑에서 바닥까지 거리 (그림자 위치, 멀수록 작고 옅게)

var _hair := Vector2.ZERO ## 머리카락 끝 흔들림(용수철)
var _hair_v := Vector2.ZERO
var _cape := Vector2.ZERO ## 코트 꼬리 자락 흔들림
var _cape_v := Vector2.ZERO
var _blink := 0.0
var _next_blink := 2.0
var pd := PDraw.new() ## 묶음 그리기 (그림 전체가 그리기 호출 1번)
static var _face := PackedVector2Array() ## 얼굴 윤곽 (늘 같아서 한 번만 계산)


func step(delta: float) -> void:
	t += delta
	# 속도 반대쪽으로 날림 (부모가 뒤집으니 x는 오른쪽 기준으로 바꿔 넣음)
	var face := signf(get_parent().scale.x) if get_parent() else 1.0
	var want_h := Vector2(-vel.x * face * 0.035, -vel.y * 0.02 + 1.0)
	want_h.x = clampf(want_h.x, -9.0, 3.0)
	want_h.y = clampf(want_h.y, -5.0, 6.0)
	_hair_v += ((want_h - _hair) * 120.0 - _hair_v * 12.0) * delta
	_hair += _hair_v * delta
	var want_c := Vector2(-vel.x * face * 0.05 - 1.0, -vel.y * 0.03 + 1.0)
	want_c.x = clampf(want_c.x, -12.0, 2.0)
	want_c.y = clampf(want_c.y, -8.0, 6.0)
	_cape_v += ((want_c - _cape) * 90.0 - _cape_v * 10.0) * delta
	_cape += _cape_v * delta
	_next_blink -= delta
	if _next_blink <= 0.0:
		_blink = 0.12
		_next_blink = randf_range(2.2, 4.2)
	_blink = maxf(_blink - delta, 0.0)
	land_k = maxf(land_k - delta * 6.0, 0.0)
	queue_redraw()


# ═══════════════════════════════════════════════════════════

func _draw() -> void:
	if blink_hidden:
		return
	var lean := 0.0 ## 상체 기울기 (+ = 앞으로)
	var bob := 0.0
	var squash := Vector2.ONE
	match pose:
		"idle":
			bob = sin(t * 2.6) * 0.5
		"run":
			lean = 0.26 # 할로우 나이트처럼 앞으로 쏠려 달림
			bob = -absf(sin(run_phase)) * 1.4
		"dash":
			lean = 0.55
			squash = Vector2(1.15, 0.9)
		"jump":
			lean = 0.08
			squash = Vector2(0.94, 1.06)
		"fall":
			lean = -0.05
		"throw":
			# 내던지며 앞으로 몸을 실음 (두 손 큰 덩이는 더 깊게 + 살짝 눌림)
			var kk := sin(minf(atk_k * 1.6, 1.0) * PI)
			lean = 0.1 + (0.3 if atk_step == 2 else 0.16) * kk
			if atk_step == 2:
				squash = Vector2(1.0 + 0.06 * kk, 1.0 - 0.06 * kk)
		"throw_up":
			lean = -0.14
		"throw_down":
			lean = 0.18
		"focus":
			bob = 2.0 + sin(t * 6.0) * 0.3
		"cast", "charge":
			lean = 0.1
		"shield":
			lean = 0.05
		"hurt":
			lean = -0.35
		"wall":
			lean = -0.08
		"glide":
			lean = 0.2
	if land_k > 0.0:
		var e := sin(land_k * PI * 0.5)
		squash *= Vector2(1.0 + 0.16 * e, 1.0 - 0.16 * e)
	var hip := Vector2(0, (HIP_Y + bob) * squash.y)
	# 바닥 그림자
	if shadow_y < 90.0:
		var sk := 1.0 - shadow_y / 90.0
		pd.draw_set_transform(Vector2(0, shadow_y), 0.0, Vector2(1.0, 0.25))
		pd.glow(Vector2.ZERO, 9.0 + 3.0 * sk, Color(0, 0, 0, 0.5 * sk), 0.0)
		pd.draw_set_transform(Vector2.ZERO)
	# 뒤쪽부터: 긴 뒷머리·코트 꼬리 자락 → 여우 꼬리 → 활공 날개 → 다리 → 몸
	pd.draw_set_transform(hip, lean, squash)
	_draw_hair_back()
	_draw_coat_tail()
	pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if fox:
		_draw_tails(lean)
	if pose == "glide":
		_draw_wings()
	pd.draw_set_transform(Vector2(0, bob), 0.0, squash)
	_draw_legs(lean)
	pd.draw_set_transform(hip, lean, squash)
	_draw_arm(false) # 뒤쪽 팔
	_draw_torso()
	_draw_head()
	_draw_arm(true) # 앞쪽 팔
	pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if fox:
		_draw_aura()
	elif od >= 0.7:
		_draw_overdrive()
	if focus_k > 0.0:
		_draw_focus_glow(hip)
	pd.flush(self)


# ─── 다리 ───────────────────────────────────────────────

func _draw_legs(lean: float) -> void:
	var hipL := Vector2(-1.4, HIP_Y)
	var hipR := Vector2(1.6, HIP_Y)
	var a1 := 0.0
	var a2 := 0.0
	var k1 := 0.0
	var k2 := 0.0
	match pose:
		"run":
			a1 = sin(run_phase) * 0.95 + lean * 0.4
			a2 = sin(run_phase + PI) * 0.95 + lean * 0.4
			k1 = maxf(0.0, -cos(run_phase)) * 1.3
			k2 = maxf(0.0, -cos(run_phase + PI)) * 1.3
		"dash":
			a1 = -0.9
			a2 = 0.6
			k1 = 1.4
			k2 = 0.5
		"jump", "glide":
			a1 = 0.5
			a2 = -0.25
			k1 = 1.1
			k2 = 0.6
		"fall":
			a1 = 0.2
			a2 = -0.3
			k1 = 0.4
			k2 = 0.7
		"focus":
			a1 = 0.9
			a2 = -0.3
			k1 = 2.0
			k2 = 1.6
		"throw", "cast", "charge":
			a1 = 0.35
			a2 = -0.35
			k1 = 0.2
		"throw_down":
			a1 = 0.6
			a2 = 0.2
			k1 = 1.4
			k2 = 1.2
		"wall":
			a1 = 0.3
			a2 = 0.6
			k1 = 1.0
			k2 = 0.8
		"hurt":
			a1 = -0.4
			a2 = 0.3
		_:
			a1 = 0.08
			a2 = -0.08
	_leg(hipL, a2, k2, false)
	_leg(hipR, a1, k1, true)


## 넓적다리 각도 a(앞 +), 무릎 굽힘 kn
func _leg(hip: Vector2, a: float, kn: float, front: bool) -> void:
	var knee := hip + Vector2(sin(a), cos(a)) * THIGH
	var sa := a - kn
	var foot := knee + Vector2(sin(sa), cos(sa)) * SHIN
	var col := TIGHTS if front else TIGHTS.darkened(0.35)
	pd.draw_line(hip, knee, OUT, 3.6)
	pd.draw_line(knee, foot, OUT, 3.2)
	pd.draw_line(hip, knee, col, 2.3)
	pd.draw_line(knee, foot, col, 1.9)
	if fox:
		# 여우 발: 흰 털 + 발톱
		var fur := FUR if front else FUR_SH
		pd.draw_colored_polygon(PackedVector2Array([foot + Vector2(-2.0, -2.6), foot + Vector2(1.8, -2.8), foot + Vector2(3.8, -0.5), foot + Vector2(3.4, 0.8), foot + Vector2(-2.2, 0.8)]), OUT)
		pd.draw_colored_polygon(PackedVector2Array([foot + Vector2(-1.4, -2.0), foot + Vector2(1.6, -2.2), foot + Vector2(3.0, -0.3), foot + Vector2(2.6, 0.2), foot + Vector2(-1.5, 0.2)]), fur)
		for i in 3:
			pd.draw_line(foot + Vector2(1.0 + i * 1.0, 0.2), foot + Vector2(1.7 + i * 1.1, 1.4), PData.FOX_HOT, 0.9)
	else:
		# 앞코가 뾰족한 검은 구두 + 굽 + 발목의 붉은 장미
		pd.draw_colored_polygon(PackedVector2Array([foot + Vector2(-1.8, -2.0), foot + Vector2(1.2, -2.0), foot + Vector2(4.0, 0.0), foot + Vector2(3.6, 1.0), foot + Vector2(-1.9, 1.0)]), OUT)
		pd.draw_colored_polygon(PackedVector2Array([foot + Vector2(-1.2, -1.4), foot + Vector2(1.0, -1.4), foot + Vector2(3.0, -0.1), foot + Vector2(2.8, 0.3), foot + Vector2(-1.3, 0.3)]), SHOE)
		pd.draw_line(foot + Vector2(0.4, -1.1), foot + Vector2(2.2, -0.2), Color(1, 1, 1, 0.2), 0.7) # 구두 광택
		if front:
			pd.draw_circle(foot + Vector2(-0.3, -2.0), 1.05, OUT)
			pd.draw_circle(foot + Vector2(-0.3, -2.0), 0.75, ROSE)


# ─── 몸통 (엉덩이 기준) ─────────────────────────────────

func _draw_torso() -> void:
	var sway := clampf(_cape.x * 0.12, -1.2, 0.3)
	# 치마: 검은 레이스 단 → 아래 단 → 위 단 (층층이 프릴)
	_poly_outlined(_frill(Vector2(-2.8, -2.6), Vector2(3.0, -2.6), Vector2(-5.6 + sway, 5.6), Vector2(5.8 + sway, 5.8), 4, 1.0), LACE)
	_poly_outlined(_frill(Vector2(-2.8, -2.8), Vector2(3.0, -2.8), Vector2(-5.0 + sway, 4.6), Vector2(5.4 + sway, 4.8), 4, 0.9), SKIRT)
	PVfx.safe_poly(pd, PackedVector2Array([Vector2(-2.6, -2.6), Vector2(-1.2, -2.6), Vector2(-2.8 + sway, 4.6), Vector2(-4.8 + sway, 4.6)]), SKIRT_SH)
	_poly_outlined(_frill(Vector2(-2.6, -3.2), Vector2(2.8, -3.2), Vector2(-4.2 + sway * 0.6, 1.8), Vector2(4.6 + sway * 0.6, 2.0), 3, 0.8), SKIRT)
	PVfx.safe_poly(pd, PackedVector2Array([Vector2(1.0, -3.0), Vector2(2.6, -3.0), Vector2(4.4 + sway * 0.6, 1.8), Vector2(2.0 + sway * 0.6, 1.8)]), SKIRT_HI)
	# 코트 몸판 (몸에 붙는 재킷, 앞은 허리에서 끊김)
	_poly_outlined(PackedVector2Array([Vector2(-2.8, -13.0), Vector2(3.0, -13.0), Vector2(2.7, -8.6), Vector2(2.3, -4.6),
		Vector2(2.2, -2.6), Vector2(-2.5, -2.8), Vector2(-2.6, -8.6)]), COAT)
	PVfx.safe_poly(pd, PackedVector2Array([Vector2(0.0, -12.4), Vector2(2.6, -12.4), Vector2(2.4, -8.6), Vector2(2.0, -3.2), Vector2(0.2, -3.2)]), COAT_HI)
	PVfx.safe_poly(pd, PackedVector2Array([Vector2(-2.6, -12.4), Vector2(-1.6, -12.4), Vector2(-1.8, -3.2), Vector2(-2.3, -3.2)]), COAT_SH)
	# 금장: 앞섶 테두리 + 두 줄 단추 + 허리띠
	pd.draw_polyline(PackedVector2Array([Vector2(2.7, -12.6), Vector2(2.5, -8.6), Vector2(2.1, -3.2)]), GOLD, 0.8)
	for y: float in [-10.6, -8.4, -6.2]:
		pd.draw_circle(Vector2(0.7, y), 0.5, GOLD)
		pd.draw_circle(Vector2(1.9, y), 0.5, GOLD)
	pd.draw_line(Vector2(-2.5, -3.6), Vector2(2.3, -3.6), GOLD_D, 0.9)
	# 높은 깃(금 테) + 붉은 넥타이
	_poly_outlined(PackedVector2Array([Vector2(-1.8, -14.4), Vector2(1.8, -14.4), Vector2(2.8, -12.8), Vector2(-2.2, -12.8)]), COAT)
	pd.draw_line(Vector2(-1.7, -14.2), Vector2(1.9, -14.2), GOLD, 0.7)
	PVfx.safe_poly(pd, PackedVector2Array([Vector2(1.2, -12.9), Vector2(2.9, -12.9), Vector2(2.2, -11.2)]), CUFF)


## 위 변은 곧게, 아래 변은 n번 물결치는 프릴 다각형
func _frill(top_l: Vector2, top_r: Vector2, bot_l: Vector2, bot_r: Vector2, n: int, amp: float) -> PackedVector2Array:
	var pts := PackedVector2Array([top_l, top_r])
	for i in 2 * n + 1:
		pts.append(bot_r.lerp(bot_l, float(i) / float(2 * n)) + Vector2(0, amp if i % 2 == 1 else 0.0))
	return pts


## 허리 뒤에서 무릎까지 길게 날리는 코트 꼬리 자락 (안감 진홍, 끝단 금장)
func _draw_coat_tail() -> void:
	var c := _cape
	var flap := sin(t * 9.0 + c.x * 0.2) * 1.2 * clampf(absf(vel.x) / 150.0, 0.2, 1.0)
	c.x *= 0.75
	var e := Vector2(-1.4 + c.x * 0.3, 6.2 + c.y * 0.3)
	var f := Vector2(-3.8 + c.x * 0.8, 9.6 + c.y + flap)
	var g := Vector2(-6.4 + c.x, 6.8 + c.y * 0.8 - flap)
	_poly_outlined(PackedVector2Array([Vector2(-2.4, -6.0), Vector2(1.2, -3.4), e, f, g, Vector2(-4.6 + c.x * 0.5, 0.6 + c.y * 0.3), Vector2(-3.0, -3.6)]), COAT)
	PVfx.safe_poly(pd, PackedVector2Array([Vector2(-2.0, -2.0), e + Vector2(-0.4, -1.0), f + Vector2(0.1, -1.4), Vector2(-3.4 + c.x * 0.6, 4.0 + c.y * 0.5)]), COAT_IN)
	pd.draw_polyline(PackedVector2Array([e, f, g]), GOLD, 0.8)


# ─── 팔 ─────────────────────────────────────────────────

func _draw_arm(front: bool) -> void:
	var sh := Vector2(2.0 if front else -1.8, -12.2)
	var ang := 0.2 # 각도: 0 = 아래로 곧게, -π/2 = 앞으로 수평(오른쪽), -π = 위로
	var bend := 0.4
	match pose:
		"idle":
			ang = 0.12 + sin(t * 2.6) * 0.05 if front else -0.1
			bend = 0.45
		"run":
			ang = (-0.9 if front else 0.7) * sin(run_phase) * 0.7 - 0.5
			bend = 1.1
		"dash":
			ang = -1.9 if front else -1.6
			bend = 0.2
		"jump", "fall":
			ang = -2.2 if front else 1.0
			bend = 0.6
		"glide":
			ang = -1.4
			bend = 0.2
		"throw":
			# 1타 앞팔 · 2타 뒷팔 · 3타 두 팔: 머리 뒤에서 앞으로 내던지고(빠르게) 팔이 따라 내려감. 쉬는 팔은 뒤로 당김
			var k := clampf(atk_k * 2.4, 0.0, 1.0)
			var e := 1.0 - (1.0 - k) * (1.0 - k)
			if _throwing(front):
				var follow := clampf((atk_k - 0.42) / 0.58, 0.0, 1.0)
				if atk_step == 2:
					ang = lerpf(lerpf(-3.2, -1.45, e), -1.0, follow)
					bend = lerpf(1.2, 0.0, e)
				else:
					ang = lerpf(lerpf(-3.5, -1.15, e), -0.7, follow)
					bend = lerpf(1.6, 0.05, e)
			else:
				ang = 0.75 if front else -0.5
				bend = 0.9
		"throw_up":
			ang = (lerpf(-0.8, -3.0, clampf(atk_k * 2.2, 0.0, 1.0)) if _throwing(front) else 0.5)
			bend = 0.1
		"throw_down":
			ang = (lerpf(-2.6, -0.3, clampf(atk_k * 2.2, 0.0, 1.0)) if _throwing(front) else -1.2)
			bend = 0.1
		"focus":
			ang = -1.2 if front else -1.0
			bend = 1.6
		"cast":
			ang = -1.4 if front else 0.4
			bend = 0.05
		"charge":
			ang = -1.4
			bend = 0.05
		"shield":
			ang = -1.4 if front else -1.2
			bend = 1.2
		"hurt":
			ang = 0.9 if front else -0.8
		"wall":
			ang = 1.4 if front else -0.6
			bend = 0.5
		"drink":
			ang = -2.4 if front else 0.2
			bend = 2.2
	var d1 := Vector2(-sin(ang), cos(ang))
	var elbow := sh + d1 * 5.0
	var a2 := ang - bend
	var d2 := Vector2(-sin(a2), cos(a2))
	var hand := elbow + d2 * 4.6
	var sleeve := COAT_HI if front else COAT_SH
	# 소매(남색) → 금 소맷단 → 붉은 커프스 → 검은 장갑
	pd.draw_line(sh, elbow, OUT, 3.2)
	pd.draw_line(elbow, hand, OUT, 3.0)
	pd.draw_line(sh, elbow, sleeve, 2.0)
	pd.draw_line(elbow, hand - d2 * 2.0, sleeve, 1.8)
	pd.draw_line(hand - d2 * 2.1, hand - d2 * 1.3, GOLD if front else GOLD_D, 1.9)
	pd.draw_line(hand - d2 * 1.3, hand - d2 * 0.6, CUFF if front else CUFF.darkened(0.3), 1.8)
	pd.draw_circle(hand, 1.5, OUT)
	pd.draw_circle(hand, 1.0, GLOVE if front else GLOVE.darkened(0.3))
	if pose in ["throw", "throw_up", "throw_down"] and _throwing(front) and atk_k < 0.4:
		_draw_hand_flare(hand, d2)
	elif pose not in ["drink", "cast", "charge"]:
		_draw_hand_fire(hand, front)
	if front and pose in ["cast", "charge"]:
		var r := 2.5 + 7.0 * charge_k
		pd.draw_circle(hand + d2 * 2.0, r + 1.5, Color(PData.FIRE_MID, 0.35))
		pd.draw_circle(hand + d2 * 2.0, r, Color(PData.FIRE_HOT, 0.8))
		pd.draw_circle(hand + d2 * 2.0, r * 0.5, PData.FIRE_CORE)
	if front and pose == "drink":
		pd.draw_rect(Rect2(hand + Vector2(-1.3, -3.6), Vector2(2.6, 4.0)), OUT)
		pd.draw_rect(Rect2(hand + Vector2(-0.8, -3.1), Vector2(1.6, 3.0)), Color("#e0405a"))


## 손 둘레를 맴도는 작은 불꽃 (참고 그림: 손에 불이 감김)
func _draw_hand_fire(hand: Vector2, front: bool) -> void:
	var a := 0.9 if front else 0.4
	var big := 1.7 if od >= 1.0 else 1.0 # 폭주 가득: 손의 불꽃이 커짐
	var hot := PData.FOX_HOT if fox else PData.FIRE_HOT # 변신 중엔 푸른 여우불
	var mid := PData.FOX_MID if fox else PData.FIRE_MID
	for i in 3:
		var ang := t * 7.0 + i * TAU / 3.0 + (0.0 if front else 1.0)
		var p := hand + Vector2(cos(ang) * 2.4, sin(ang) * 1.1 - 0.6) * big
		var behind := sin(ang) < 0.0
		pd.draw_circle(p, 0.85 * big, Color(mid, a * (0.45 if behind else 0.85)))
		pd.draw_circle(p + Vector2(0, -0.5), 0.45 * big, Color(hot, a * (0.45 if behind else 1.0)))
	var lick := (1.4 + sin(t * 13.0 + (0.0 if front else 2.0)) * 0.5) * big
	PVfx.safe_poly(pd, PackedVector2Array([hand + Vector2(-0.9, -0.7), hand + Vector2(0.3, -2.0 - lick), hand + Vector2(1.0, -0.7)]), Color(hot, a * 0.8))


## 이번 던지기에서 이 팔이 던지는가 (1타 앞팔 · 2타 뒷팔 · 3타 두 팔, 위·아래 던지기는 앞팔)
func _throwing(front: bool) -> bool:
	if pose != "throw":
		return front
	return atk_step == 2 or (atk_step == 0) == front


## 던지는 순간 손에서 번쩍이는 불 (던진 방향 d로 늘어나며 사라짐)
func _draw_hand_flare(hand: Vector2, d: Vector2) -> void:
	var k := clampf(atk_k / 0.4, 0.0, 1.0)
	var a := 1.0 - k
	var hot := PData.FOX_HOT if fox else PData.FIRE_HOT
	var core := PData.FOX_CORE if fox else PData.FIRE_CORE
	var s := 1.4 if atk_step == 2 else 1.0
	pd.glow(hand, 7.0 * s, Color(hot, 0.7 * a))
	pd.draw_circle(hand + d * 1.5, 2.6 * s * a + 0.4, Color(hot, a))
	pd.draw_circle(hand + d * 1.5, 1.4 * s * a, Color(core, a))
	PVfx.spike(pd, hand, d, 6.0 * s * (0.5 + k), 2.4 * a + 0.4, Color(core, 0.85 * a))


# ─── 머리 ───────────────────────────────────────────────

## 뒤로 길게 내린 붉은 머리 (허리까지, 끝이 날림)
func _draw_hair_back() -> void:
	var h := _hair * 0.6
	var hc := HEAD
	var pts := PackedVector2Array([hc + Vector2(-3.4, -2.6), hc + Vector2(-0.6, -4.4), hc + Vector2(2.8, -3.2), hc + Vector2(1.0, 3.6),
		Vector2(-1.2 + h.x * 0.4, -6.4 + h.y * 0.4), Vector2(-2.8 + h.x * 0.9, -2.4 + h.y), Vector2(-4.2 + h.x, -4.0 + h.y * 0.9),
		Vector2(-4.8 + h.x * 0.7, -9.0 + h.y * 0.6), Vector2(-4.4 + h.x * 0.3, -14.0 + h.y * 0.2)])
	_poly_outlined(pts, HAIR)
	PVfx.safe_poly(pd, PackedVector2Array([Vector2(-3.8 + h.x * 0.3, -13.6), Vector2(-2.2 + h.x * 0.5, -9.0 + h.y * 0.4),
		Vector2(-2.9 + h.x * 0.9, -3.2 + h.y), Vector2(-4.0 + h.x, -4.4 + h.y * 0.9), Vector2(-4.4 + h.x * 0.7, -9.0 + h.y * 0.6)]), HAIR_SH)
	pd.draw_line(Vector2(-2.6 + h.x * 0.2, -15.0), Vector2(-3.0 + h.x * 0.7, -7.0 + h.y * 0.5), HAIR_HI.darkened(0.15), 0.7)


func _draw_head() -> void:
	var hc := HEAD
	var h := _hair
	# 목 + 얼굴 (작고 갸름하게, 턱이 살짝 앞으로)
	pd.draw_rect(Rect2(hc + Vector2(-0.7, 2.6), Vector2(1.6, 2.0)), SKIN_SH)
	if _face.is_empty():
		for i in 16:
			var a := float(i) / 16.0 * TAU
			var s := sin(a)
			_face.append(hc + Vector2(cos(a) * 3.3 + (0.6 * s if s > 0 else 0.0), s * 3.4 + (0.6 * s * s if s > 0 else 0.0)))
	_poly_outlined(_face, SKIN)
	PVfx.safe_poly(pd, PackedVector2Array([hc + Vector2(-3.2, 0), hc + Vector2(-2.0, 3.2), hc + Vector2(-3.3, 1.4)]), SKIN_SH)
	# 눈 (오른쪽을 봄 — 앞눈 하나가 또렷하게, 뒷눈은 가늘게). 차분하고 자신 있는 눈매
	var hurt := pose == "hurt"
	var closed := _blink > 0.0 or pose == "focus"
	_eye(hc + Vector2(1.9, 0.6), closed, hurt)
	if not closed and not hurt:
		pd.draw_line(hc + Vector2(-0.9, -0.4), hc + Vector2(-0.9, 1.0), OUT, 0.9)
	# 입
	if pose in ["throw", "dash", "cast", "charge", "hurt"]:
		pd.draw_line(hc + Vector2(1.6, 2.8), hc + Vector2(2.8, 2.6), OUT, 0.8)
	# 앞머리 (옆으로 쓸어 넘긴 붉은 머리)
	var fr := PackedVector2Array([hc + Vector2(-3.8, 0.4), hc + Vector2(-3.6, -3.2), hc + Vector2(-1.2, -4.6), hc + Vector2(2.0, -4.4),
		hc + Vector2(4.0, -2.6), hc + Vector2(4.2, 0.6), hc + Vector2(3.2, -1.0), hc + Vector2(2.4, 0.0), hc + Vector2(1.8, -2.0),
		hc + Vector2(0.4, -0.8), hc + Vector2(-0.4, -2.4), hc + Vector2(-1.8, -0.8), hc + Vector2(-2.4, -2.2), hc + Vector2(-3.0, 0.8)])
	_poly_outlined(fr, HAIR)
	PVfx.safe_poly(pd, PackedVector2Array([hc + Vector2(-1.6, -3.8), hc + Vector2(1.6, -3.8), hc + Vector2(2.6, -3.0), hc + Vector2(-0.6, -3.0)]), HAIR_HI)
	_draw_braid(hc, h)
	_draw_leaf(hc + Vector2(3.0, -2.4), -0.9)
	_draw_leaf(hc + Vector2(3.0, -2.4), 0.3)
	if fox:
		_draw_ears(hc)
	else:
		_draw_hat(hc)


## 앞쪽 어깨 위로 내려오는 땋은 머리
func _draw_braid(hc: Vector2, h: Vector2) -> void:
	var a := hc + Vector2(3.0, 1.2)
	var b := Vector2(3.4 + h.x * 0.12, -8.0 + h.y * 0.15)
	var pts: Array = []
	for i in 5:
		pts.append(a.lerp(b, float(i) / 4.0) + Vector2(0.35 if i % 2 == 0 else -0.35, 0))
	for p: Vector2 in pts:
		pd.draw_circle(p, 1.3, OUT)
	for i in pts.size():
		var p: Vector2 = pts[i]
		pd.draw_circle(p, 0.9, HAIR if i % 2 == 0 else HAIR_SH.lightened(0.2))
	# 묶음 끈 + 머리끝 술
	pd.draw_line(b + Vector2(-0.9, 0.9), b + Vector2(0.9, 0.9), GOLD_D, 0.9)
	_poly_outlined(PackedVector2Array([b + Vector2(-0.9, 1.2), b + Vector2(1.0, 1.2), b + Vector2(0.7 + h.x * 0.05, 3.2), b + Vector2(-0.5 + h.x * 0.08, 2.8)]), HAIR)


## 초록 잎 머리 장식 한 장
func _draw_leaf(p: Vector2, ang: float) -> void:
	var d := Vector2(cos(ang), sin(ang))
	var n := d.orthogonal()
	_poly_outlined(PackedVector2Array([p, p + d * 1.4 + n * 0.9, p + d * 2.8, p + d * 1.4 - n * 0.9]), LEAF)


func _eye(c: Vector2, closed: bool, hurt: bool) -> void:
	if closed:
		pd.draw_line(c + Vector2(-1.0, 0.3), c + Vector2(1.1, 0.1), OUT, 0.9)
		return
	if hurt:
		pd.draw_line(c + Vector2(-0.9, -0.9), c + Vector2(0.9, 0.9), OUT, 0.9)
		pd.draw_line(c + Vector2(-0.9, 0.9), c + Vector2(0.9, -0.9), OUT, 0.9)
		return
	var iris := PData.FOX_HOT if fox else EYE
	pd.draw_rect(Rect2(c + Vector2(-0.9, -1.1), Vector2(1.9, 2.4)), OUT)
	pd.draw_rect(Rect2(c + Vector2(-0.5, -0.5), Vector2(1.2, 1.6)), iris)
	pd.draw_rect(Rect2(c + Vector2(-0.5, -0.5), Vector2(0.5, 0.5)), Color(1, 1, 1, 0.9))
	# 윗눈꺼풀 선 + 바깥 속눈썹 (반쯤 내리깐 차분한 눈매)
	pd.draw_line(c + Vector2(-1.1, -1.1), c + Vector2(1.3, -1.3), OUT, 0.9)
	pd.draw_line(c + Vector2(1.1, -1.3), c + Vector2(1.7, -0.7), OUT, 0.8)


func _draw_hat(hc: Vector2) -> void:
	# 남색 마녀 모자: 뒤로 젖혀 쓴 챙 + 뒤로 꺾인 끝 + 금 띠 + 붉은 장미
	var tilt := -0.14 + _hair.x * 0.01
	var bc := hc + Vector2(-0.4, -4.3)
	var brim := PackedVector2Array()
	for i in 18:
		var a := float(i) / 18.0 * TAU
		brim.append(bc + Vector2(cos(a) * 7.4, sin(a) * 1.7).rotated(tilt))
	_poly_outlined(brim, HAT)
	var rim := PackedVector2Array()
	for i in 10:
		var a := float(i) / 9.0 * PI
		rim.append(bc + Vector2(cos(a) * 6.8, sin(a) * 1.3).rotated(tilt))
	pd.draw_polyline(rim, GOLD_D, 0.6)
	# 원뿔: 위로 가다 뒤(왼쪽)로 꺾임, 끝이 흔들림
	var sway := sin(t * 2.2) * 0.6 + _hair.x * 0.2
	var cone := PackedVector2Array([
		bc + Vector2(-3.6, -0.5).rotated(tilt), bc + Vector2(3.4, -0.8).rotated(tilt), bc + Vector2(2.2, -4.6),
		bc + Vector2(0.8, -7.6), bc + Vector2(-1.8 + sway * 0.5, -9.6), bc + Vector2(-5.0 + sway, -10.0),
		bc + Vector2(-7.4 + sway * 1.3, -8.4), bc + Vector2(-3.8 + sway * 0.6, -8.4), bc + Vector2(-1.8, -6.4), bc + Vector2(-2.4, -3.4)])
	_poly_outlined(cone, HAT)
	PVfx.safe_poly(pd, PackedVector2Array([bc + Vector2(1.2, -0.8), bc + Vector2(2.8, -1.0), bc + Vector2(1.8, -4.4), bc + Vector2(0.5, -6.8), bc + Vector2(0.3, -4.2)]), HAT_HI)
	# 금 띠 + 장미
	PVfx.safe_poly(pd, PackedVector2Array([bc + Vector2(-3.4, -0.6).rotated(tilt), bc + Vector2(3.3, -0.9).rotated(tilt), bc + Vector2(3.0, -2.1).rotated(tilt), bc + Vector2(-3.1, -1.8).rotated(tilt)]), GOLD)
	var rp := bc + Vector2(2.3, -1.5).rotated(tilt)
	pd.draw_circle(rp, 1.35, OUT)
	pd.draw_circle(rp, 1.0, ROSE)
	pd.draw_circle(bc + Vector2(-7.4 + sway * 1.3, -8.0), 0.9, GOLD)


func _draw_ears(hc: Vector2) -> void:
	# 흰 여우 귀 두 개 (끝은 푸른 불), 살짝 까딱임
	var tw := sin(t * 3.0) * 0.08
	for side in [-1, 1]:
		var base := hc + Vector2(side * 2.2 - 0.4, -3.6)
		var ang: float = side * 0.3 + tw * side
		var tip := base + Vector2(sin(ang), -cos(ang)) * 6.2
		var l := base + Vector2(-1.9, 0.5).rotated(ang)
		var r := base + Vector2(1.9, 0.5).rotated(ang)
		_poly_outlined(PackedVector2Array([l, tip, r]), FUR if side > 0 else FUR_SH)
		pd.draw_colored_polygon(PackedVector2Array([base + Vector2(-0.8, 0).rotated(ang), base + (tip - base) * 0.7, base + Vector2(0.8, 0).rotated(ang)]), Color("#f3b6c8"))
		pd.draw_colored_polygon(PackedVector2Array([base + (tip - base) * 0.68 + Vector2(-0.9, 0).rotated(ang), tip, base + (tip - base) * 0.68 + Vector2(0.9, 0).rotated(ang)]), PData.FOX_MID)
		pd.draw_circle(tip, 1.1 + sin(t * 9.0 + side) * 0.3, Color(PData.FOX_HOT, 0.6))


# ─── 변신: 꼬리·불꽃 ────────────────────────────────────

func _draw_tails(lean: float) -> void:
	var n := clampi(tails, 1, 9)
	var root := Vector2(-2.4, HIP_Y + 0.5)
	for i in n:
		var spread := 0.0 if n == 1 else lerpf(-1.0, 1.0, float(i) / float(n - 1))
		var sway := sin(t * 3.0 + i * 0.7) * 0.12
		# 뒤(왼쪽)로 뻗다가 끝이 위로 말려 올라가는 풍성한 꼬리. 여러 개면 부채꼴로
		var base_ang := PI + 0.35 - spread * 0.85 + sway - lean * 0.6 + _cape.x * 0.02
		var length := 18.0 - absf(spread) * 3.0
		var left := PackedVector2Array()
		var right := PackedVector2Array()
		var ol := PackedVector2Array()
		var orr := PackedVector2Array()
		var segs := 6
		var tip := root
		for s in segs + 1:
			var f := float(s) / float(segs)
			var ang := base_ang + f * f * 1.1 + sin(t * 4.0 + f * 3.0 + i) * 0.12 * f
			var p := root + Vector2(cos(base_ang), sin(base_ang)) * length * f * 0.6 + Vector2(cos(ang), sin(ang)) * length * f * 0.5
			var w := sin(minf(f * 1.25, 1.0) * PI * 0.92 + 0.12) * (4.6 if f < 0.95 else 1.8)
			var nrm := Vector2(-sin(ang), cos(ang))
			left.append(p + nrm * w)
			right.append(p - nrm * w)
			ol.append(p + nrm * (w + 0.7))
			orr.append(p - nrm * (w + 0.7))
			tip = p
		# 윤곽(조금 넓은 띠) → 흰 털(뿌리) → 끝으로 갈수록 푸른 여우불
		pd.strip(ol, orr, OUT)
		var fur := FUR if i % 2 == 0 else FUR_SH
		pd.strip_grad(left, right, fur, fur.lerp(PData.FOX_HOT, 0.55))
		# 끝: 푸른 불 털 끝
		pd.glow(tip, 4.0 + sin(t * 10.0 + i) * 0.5, Color(PData.FOX_HOT, 0.95), 0.25)
		pd.draw_rect(Rect2(tip + Vector2(0, -2.6), Vector2(1, 1)), PData.FOX_CORE)


func _draw_aura() -> void:
	for i in 5:
		var ph := t * 3.2 + i * 1.3
		var x := sin(ph * 1.7 + i) * 7.0
		var y := -6.0 - fmod(ph * 10.0, 36.0)
		var a := 0.5 * (1.0 - fmod(ph * 10.0, 36.0) / 36.0)
		pd.draw_circle(Vector2(x, y), 1.3, Color(PData.FOX_HOT, a))


## 폭주 70% 이상: 몸에서 붉은 불티가 피어오름 (가득 차면 더 많이 + 손의 불꽃이 커짐)
func _draw_overdrive() -> void:
	var n := 9 if od >= 1.0 else 4
	for i in n:
		var ph := t * 2.6 + i * 0.9
		var rise := fmod(ph * 14.0, 40.0)
		var x := sin(ph * 1.9 + i) * 7.0
		var a := (0.75 if od >= 1.0 else 0.5) * (1.0 - rise / 40.0)
		pd.draw_circle(Vector2(x, -4.0 - rise), 1.2, Color(PData.FIRE_HOT, a))
		pd.draw_circle(Vector2(x, -4.0 - rise), 0.6, Color(PData.FIRE_CORE, a))


func _draw_wings() -> void:
	# 활공: 등에서 펼쳐지는 불꽃 날개 둘
	var hip := Vector2(-2, -27)
	for side in [0, 1]:
		var flap := sin(t * 8.0 + side) * 2.0
		var col := Color(PData.FIRE_MID, 0.55 if side == 0 else 0.8)
		var pts := PackedVector2Array([hip, hip + Vector2(-16, -8 + flap - side * 3), hip + Vector2(-22, -2 + flap), hip + Vector2(-15, 1 + flap * 0.5), hip + Vector2(-19, 5 + flap * 0.3), hip + Vector2(-6, 3)])
		PVfx.safe_poly(pd, pts, col)
		pd.draw_polyline(PackedVector2Array([hip, hip + Vector2(-16, -8 + flap - side * 3), hip + Vector2(-22, -2 + flap)]), Color(PData.FIRE_HOT, 0.9), 1.0)


func _draw_focus_glow(hip: Vector2) -> void:
	var c := hip + Vector2(2.5, -9)
	var r := 3.0 + focus_k * 3.0 + sin(t * 14.0) * 0.6
	pd.draw_circle(c, r + 3, Color(PData.FIRE_MID, 0.25 * focus_k))
	pd.draw_circle(c, r, Color(PData.FIRE_HOT, 0.6 * focus_k))
	pd.draw_circle(c, r * 0.45, Color(PData.FIRE_CORE, 0.9 * focus_k))
	pd.draw_arc(Vector2(0, -20), 18.0 + sin(t * 5.0) * 1.5, 0, TAU, 30, Color(PData.FIRE_HOT, 0.25 * focus_k), 1.0)


# ─── 도움 함수 ──────────────────────────────────────────

## 윤곽: 바깥으로 0.6px 넓힌 같은 모양을 먼저 검게 깔고 그 위에 채움 (PDraw.outlined — 같은 모양은 기억해 둠)
func _poly_outlined(pts: PackedVector2Array, col: Color) -> void:
	pd.outlined(pts, col, OUT, 0.6)
