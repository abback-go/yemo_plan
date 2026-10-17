class_name TBackArt
extends PDraw.Canvas
## 마녀 셋의 뒷모습 (2.5D 전투: 카메라가 파티 뒤에 있다). 원점 = 발밑 가운데, 설계 키 약 40px — 장면이 ×3으로 키운다.
## 색은 옆모습 그림(EArt·SeraArt·TAsheArt)의 상수를 그대로 써서 같은 사람으로 읽히게 한다.
## pose: idle · cast(오른팔을 들어 올림) · hurt · down. cast_k는 step()에서 따라온다.

var who := "eska"
var pose := "idle"
var t := 0.0
var cast_k := 0.0
var flash := 0.0
var fade := 1.0
var _hair := 0.0
var _hair_v := 0.0
var _ko_k := 0.0


func step(delta: float) -> void:
	t += delta
	flash = maxf(flash - delta * 5.0, 0.0)
	cast_k = move_toward(cast_k, 1.0 if pose == "cast" else 0.0, delta * 6.0)
	_ko_k = move_toward(_ko_k, 1.0 if pose == "down" else 0.0, delta * 3.0)
	var want := sin(t * 1.7) * 0.8 + (sin(t * 9.0) * 1.5 if pose == "cast" else 0.0)
	_hair_v += ((want - _hair) * 60.0 - _hair_v * 8.0) * delta
	_hair += _hair_v * delta
	queue_redraw()


func _paint() -> void:
	modulate = Color(1.0, 1.0 - 0.5 * flash, 1.0 - 0.45 * flash, fade)
	var bob := sin(t * 2.4) * 0.5
	var lean := 0.0
	var sq := Vector2.ONE
	if pose == "hurt":
		lean = 0.22
		sq = Vector2(1.06, 0.95)
	if _ko_k > 0.0:
		sq = Vector2(1.0 + 0.1 * _ko_k, 1.0 - 0.42 * _ko_k)
		lean = 0.35 * _ko_k
	pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.26))
	pd.glow(Vector2.ZERO, 11.0, Color(0, 0, 0, 0.5), 0.0)
	pd.draw_set_transform(Vector2(0, bob * 0.3), lean, sq)
	match who:
		"eska":
			_eska(bob)
		"sera":
			_sera(bob)
		_:
			_ashe(bob)


## 팔 하나(뒤에서 봄). side = -1 왼팔 · 1 오른팔. 오른팔은 cast_k만큼 위로 들린다. 소매 색·손 색을 받는다
func _arm(side: int, sh: Vector2, down: Vector2, up: Vector2, sleeve: Color, skin: Color, w := 2.6) -> Vector2:
	var k := cast_k if side == 1 else 0.0
	var hand := down.lerp(up, k)
	var el := sh.lerp(hand, 0.5) + Vector2(float(side) * 1.2 * (1.0 - k), 1.4 * (1.0 - k))
	pd.draw_line(sh, el, Color("#0a090e"), w + 1.2)
	pd.draw_line(el, hand, Color("#0a090e"), w + 1.0)
	pd.draw_line(sh, el, sleeve, w)
	pd.draw_line(el, hand, sleeve, w - 0.4)
	pd.draw_circle(hand, 1.3, skin)
	return hand


# ═══════════════════════════════════════════════════════════
# 에스카 — 흑백 + 보라 포인트: 챙 넓은 검은 모자, 허리까지 흰 머리, 자락 끝이 갈라져 흰 공허가 비치는 검은 드레스, 시스루 소매
# ═══════════════════════════════════════════════════════════

func _eska(bob: float) -> void:
	var OUT := EArt.OUT
	var shimmer := 0.78 + 0.22 * sin(t * 7.0)
	# 드레스 (뒤에서 본 긴 치마, 자락 갈라짐 + 보라 안감)
	var waist := -16.0
	var hem := PackedVector2Array([Vector2(-3.6, waist), Vector2(3.6, waist), Vector2(9.0 + _hair * 0.2, -1.2), Vector2(6.0, -2.6), Vector2(3.0, -0.4),
		Vector2(0.0, -2.8), Vector2(-3.0, -0.4), Vector2(-6.0, -2.6), Vector2(-9.0 - _hair * 0.2, -1.2)])
	pd.outlined(hem, EArt.CLOTH, EArt.RIM, 0.8)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-1.2, waist + 2), Vector2(1.6, waist + 2), Vector2(2.4, -3.0), Vector2(-2.0, -3.0)]), EArt.CLOTH_HI)
	for x in [-6.0, 0.0, 6.0]:
		pd.draw_colored_polygon(PackedVector2Array([Vector2(x - 1.6, -1.0), Vector2(x + 1.6, -1.0), Vector2(x, -4.6)]), EArt.LINING)
		pd.glow(Vector2(x, -2.4), 3.2, Color(EArt.GLOW_PALE, 0.3 * shimmer), 0.0)
		pd.draw_colored_polygon(PackedVector2Array([Vector2(x - 1.0, -1.2), Vector2(x + 1.0, -1.2), Vector2(x, -3.4)]), Color(1, 1, 1, shimmer))
	pd.draw_line(Vector2(-2.2, waist + 2.5), Vector2(-4.4, -4.0), EArt.CLOTH_SH, 1.0)
	pd.draw_line(Vector2(2.2, waist + 2.5), Vector2(4.6, -4.0), EArt.CLOTH_SH, 1.0)
	# 몸통 + 드러난 어깨·목
	pd.outlined(PackedVector2Array([Vector2(-3.2, waist), Vector2(3.4, waist), Vector2(3.8, waist - 7.4), Vector2(-3.6, waist - 7.4)]), EArt.CLOTH, EArt.RIM, 0.8)
	pd.draw_line(Vector2(-2.8, waist - 0.6), Vector2(3.0, waist - 0.6), EArt.LINING, 1.0)
	pd.draw_rect(Rect2(Vector2(-4.0, waist - 9.2), Vector2(8.0, 2.0)), EArt.SKIN)
	pd.draw_rect(Rect2(Vector2(-1.0, waist - 11.0), Vector2(2.0, 2.0)), EArt.SKIN_SH)
	# 팔 (시스루 소매는 반투명 띠)
	var hl := _arm(-1, Vector2(-4.0, -24.0), Vector2(-6.0, -13.0), Vector2(-6.0, -13.0), Color(EArt.SLEEVE, 0.75), EArt.SKIN, 2.4)
	var hr := _arm(1, Vector2(4.0, -24.0), Vector2(6.0, -13.0), Vector2(10.5, -37.0), Color(EArt.SLEEVE, 0.75), EArt.SKIN, 2.4)
	pd.draw_line(hl + Vector2(-1.5, 0), hl + Vector2(-3.0, 4.0), Color(EArt.SLEEVE, 0.4), 3.0)
	if cast_k > 0.05:
		pd.glow(hr, 6.0 * cast_k, Color(EArt.GLOW, 0.5 * cast_k), 0.0)
		pd.draw_circle(hr, 1.4, Color(1, 1, 1, 0.9 * cast_k))
	else:
		pd.draw_line(hr + Vector2(1.5, 0), hr + Vector2(3.0, 4.0), Color(EArt.SLEEVE, 0.4), 3.0)
	# 긴 백발 (뒤통수에서 허리까지, 끝이 갈라짐)
	var h := _hair
	var hair := PackedVector2Array([Vector2(-4.2, -31.0), Vector2(4.2, -31.0), Vector2(5.4 + h * 0.3, -24.0), Vector2(6.2 + h * 0.7, -16.0), Vector2(4.6 + h, -12.0),
		Vector2(2.0 + h * 0.8, -13.5), Vector2(0.0 + h * 0.9, -11.0), Vector2(-2.2 + h * 0.8, -13.5), Vector2(-4.8 + h, -12.0), Vector2(-6.2 + h * 0.7, -16.0), Vector2(-5.4 + h * 0.3, -24.0)])
	pd.outlined(hair, EArt.HAIR_MID, OUT, 0.7)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-2.6, -30.0), Vector2(2.0, -30.0), Vector2(2.6 + h * 0.6, -18.0), Vector2(-1.0 + h * 0.8, -14.0), Vector2(-3.4 + h * 0.5, -20.0)]), EArt.HAIR)
	pd.draw_line(Vector2(3.6, -28.0), Vector2(4.4 + h * 0.6, -16.0), EArt.HAIR_SH, 0.8)
	pd.draw_line(Vector2(-3.8, -28.0), Vector2(-4.6 + h * 0.6, -16.0), EArt.HAIR_SH, 0.8)
	pd.draw_circle(Vector2(0.2, -30.8), 3.8, EArt.HAIR_MID)
	pd.draw_circle(Vector2(-0.4, -31.6), 2.4, EArt.HAIR)
	# 모자: 챙 + 꺾인 뾰족 머리 (끝은 왼쪽으로)
	var bc := Vector2(0.0, -33.6 + bob * 0.2)
	var brim := PackedVector2Array()
	var brim_top := PackedVector2Array()
	for i in 24:
		var a := float(i) / 24.0 * TAU
		brim.append(bc + Vector2(cos(a) * 14.4, sin(a) * 2.6))
		brim_top.append(bc + Vector2(cos(a) * 13.2, sin(a) * 1.6 - 0.5))
	pd.outlined(brim, EArt.CLOTH_SH, EArt.RIM, 0.8)
	pd.convex(brim_top, EArt.CLOTH)
	for x in [12.0, -11.6]:
		var sgn := signf(x)
		pd.glow(bc + Vector2(x + sgn * 1.2, 0.3), 2.8, Color(EArt.GLOW_PALE, 0.3 * shimmer), 0.0)
		pd.draw_colored_polygon(PackedVector2Array([bc + Vector2(x + sgn * 2.6, -0.6), bc + Vector2(x - sgn * 0.6, 0.1), bc + Vector2(x + sgn * 2.2, 1.5)]), Color(1, 1, 1, shimmer))
	var tip := Vector2(-5.0 + _hair * 0.4, -46.0)
	var crown := PackedVector2Array([bc + Vector2(-5.4, -0.6), bc + Vector2(5.4, -0.6), bc + Vector2(3.2, -5.4), bc + Vector2(0.4, -8.8), tip + bc - Vector2(0, -33.6) * 0 - Vector2(0, 0) + Vector2(0, 33.6) * 0,
		Vector2(tip.x - 1.6, tip.y + 0.9), bc + Vector2(-3.6, -8.0), bc + Vector2(-5.0, -4.4)])
	pd.outlined(crown, EArt.CLOTH, EArt.RIM, 0.8)
	pd.draw_colored_polygon(PackedVector2Array([bc + Vector2(1.4, -0.8), bc + Vector2(5.2, -0.8), bc + Vector2(3.0, -5.2), bc + Vector2(0.6, -7.0)]), EArt.CLOTH_HI)
	pd.draw_line(bc + Vector2(-4.8, -1.6), bc + Vector2(4.8, -1.6), EArt.LINING, 1.4)


# ═══════════════════════════════════════════════════════════
# 세라 — 남색 군복풍 롱코트(금 단추·뒤로 길게 날리는 꼬리 자락), 허리까지 붉은 머리 + 오른쪽 어깨 땋은 머리, 남색 모자(금 띠)
# ═══════════════════════════════════════════════════════════

func _sera(bob: float) -> void:
	var OUT := SeraArt.OUT
	var h := _hair
	# 다리 (짙은 타이츠 + 검은 구두)
	for side in [-1, 1]:
		var hip := Vector2(side * 1.6, -15.0)
		var foot := Vector2(side * 2.4, -0.6)
		pd.draw_line(hip, foot, OUT, 3.4)
		pd.draw_line(hip, foot, SeraArt.TIGHTS, 2.2)
		pd.draw_colored_polygon(PackedVector2Array([foot + Vector2(-2.0, -1.6), foot + Vector2(2.0, -1.6), foot + Vector2(2.2, 1.0), foot + Vector2(-2.2, 1.0)]), OUT)
		pd.draw_colored_polygon(PackedVector2Array([foot + Vector2(-1.4, -1.0), foot + Vector2(1.4, -1.0), foot + Vector2(1.6, 0.4), foot + Vector2(-1.6, 0.4)]), SeraArt.SHOE)
	# 붉은 프릴 치마 (코트 꼬리 양옆으로 비침)
	pd.outlined(PackedVector2Array([Vector2(-5.0, -12.0), Vector2(5.0, -12.0), Vector2(7.4, -5.0), Vector2(5.6, -4.0), Vector2(3.8, -5.2), Vector2(2.0, -4.0), Vector2(0.0, -5.4),
		Vector2(-2.0, -4.0), Vector2(-3.8, -5.2), Vector2(-5.6, -4.0), Vector2(-7.4, -5.0)]), SeraArt.SKIRT, OUT, 0.6)
	# 코트 몸판 + 꼬리 자락 (뒤에서 보면 등판 전체가 남색, 가운데 솔기에 금줄)
	var tail := PackedVector2Array([Vector2(-5.2, -24.0), Vector2(5.4, -24.0), Vector2(6.4, -14.0), Vector2(8.6 + h * 0.6, -3.0), Vector2(5.0 + h * 0.4, -5.0), Vector2(2.2 + h * 0.2, -1.4),
		Vector2(-0.6, -5.6), Vector2(-3.4 + h * 0.2, -1.6), Vector2(-6.0 + h * 0.4, -5.4), Vector2(-8.4 + h * 0.6, -3.4), Vector2(-6.4, -14.0)])
	pd.outlined(tail, SeraArt.COAT, OUT, 0.7)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-5.0, -23.4), Vector2(-1.2, -23.4), Vector2(-1.6, -8.0), Vector2(-6.0, -12.0)]), SeraArt.COAT_HI)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(1.2, -23.4), Vector2(5.0, -23.4), Vector2(5.8, -12.0), Vector2(1.4, -8.0)]), SeraArt.COAT_SH)
	pd.draw_line(Vector2(0.0, -23.0), Vector2(0.2 + h * 0.2, -3.0), SeraArt.GOLD_D, 0.8)
	pd.draw_polyline(PackedVector2Array([Vector2(-8.4 + h * 0.6, -3.4), Vector2(-6.0 + h * 0.4, -5.4), Vector2(-3.4 + h * 0.2, -1.6), Vector2(-0.6, -5.6), Vector2(2.2 + h * 0.2, -1.4), Vector2(5.0 + h * 0.4, -5.0), Vector2(8.6 + h * 0.6, -3.0)]), SeraArt.GOLD, 0.7)
	pd.draw_line(Vector2(-5.4, -17.0), Vector2(5.6, -17.0), SeraArt.GOLD_D, 0.9) # 허리띠
	# 높은 깃
	pd.outlined(PackedVector2Array([Vector2(-3.0, -27.4), Vector2(3.0, -27.4), Vector2(3.6, -24.2), Vector2(-3.6, -24.2)]), SeraArt.COAT, OUT, 0.6)
	pd.draw_line(Vector2(-2.8, -27.2), Vector2(2.8, -27.2), SeraArt.GOLD, 0.7)
	# 팔 (남색 소매 · 금 소맷단 · 검은 장갑에 작은 불꽃)
	var hl := _arm(-1, Vector2(-4.6, -23.0), Vector2(-6.2, -12.5), Vector2(-6.2, -12.5), SeraArt.COAT_HI, SeraArt.GLOVE, 2.8)
	var hr := _arm(1, Vector2(4.6, -23.0), Vector2(6.2, -12.5), Vector2(10.0, -36.0), SeraArt.COAT_HI, SeraArt.GLOVE, 2.8)
	for hp in [hl, hr]:
		pd.draw_circle(hp + Vector2(0, -2.2), 1.3, SeraArt.GOLD)
	var fl := 0.6 + 0.4 * sin(t * 11.0)
	pd.glow(hr, 4.0 + 6.0 * cast_k, Color(PData.FIRE_MID, (0.35 + 0.5 * cast_k) * fl), 0.0)
	pd.draw_circle(hr + Vector2(0, -1.0), 1.0 + 2.0 * cast_k, Color(PData.FIRE_HOT, 0.9))
	pd.draw_circle(hr + Vector2(0, -1.0), 0.5 + 1.0 * cast_k, PData.FIRE_CORE)
	pd.glow(hl, 3.5, Color(PData.FIRE_MID, 0.3 * fl), 0.0)
	# 긴 붉은 머리 (등 위쪽) + 오른쪽 어깨 땋은 머리 끝
	var hair := PackedVector2Array([Vector2(-4.4, -31.0), Vector2(4.4, -31.0), Vector2(5.6 + h * 0.3, -24.0), Vector2(5.0 + h * 0.8, -17.0), Vector2(2.4 + h * 0.9, -14.5),
		Vector2(0.0 + h * 0.9, -16.5), Vector2(-2.6 + h * 0.9, -14.5), Vector2(-5.2 + h * 0.8, -17.0), Vector2(-5.6 + h * 0.3, -24.0)])
	pd.outlined(hair, SeraArt.HAIR, OUT, 0.7)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-3.0, -30.0), Vector2(0.6, -30.0), Vector2(1.0 + h * 0.5, -20.0), Vector2(-2.4 + h * 0.6, -18.0)]), SeraArt.HAIR_HI.darkened(0.2))
	pd.draw_line(Vector2(3.4, -29.0), Vector2(4.0 + h * 0.6, -18.0), SeraArt.HAIR_SH, 0.8)
	pd.draw_circle(Vector2(0.4, -31.0), 3.8, SeraArt.HAIR)
	pd.draw_circle(Vector2(0.0, -31.8), 2.2, SeraArt.HAIR_HI.darkened(0.1))
	for i in 3: # 땋은 머리 (오른쪽 어깨 뒤로 살짝 보임)
		var p := Vector2(5.6, -26.0 + float(i) * 2.4)
		pd.draw_circle(p, 1.3, OUT)
		pd.draw_circle(p, 0.9, SeraArt.HAIR if i % 2 == 0 else SeraArt.HAIR_SH.lightened(0.2))
	# 모자 (남색, 금 띠, 뒤로 꺾인 끝)
	var bc := Vector2(-0.2, -34.6 + bob * 0.2)
	var brim := PackedVector2Array()
	for i in 20:
		var a := float(i) / 20.0 * TAU
		brim.append(bc + Vector2(cos(a) * 8.2, sin(a) * 1.9))
	pd.outlined(brim, SeraArt.HAT, OUT, 0.7)
	var sway := sin(t * 2.2) * 0.6 + h * 0.2
	var cone := PackedVector2Array([bc + Vector2(-3.8, -0.4), bc + Vector2(3.8, -0.4), bc + Vector2(2.4, -4.8), bc + Vector2(0.6, -8.2), bc + Vector2(-2.0 + sway * 0.5, -10.4),
		bc + Vector2(-5.4 + sway, -11.0), bc + Vector2(-7.6 + sway * 1.3, -9.2), bc + Vector2(-4.0 + sway * 0.6, -8.6), bc + Vector2(-2.4, -6.6), bc + Vector2(-3.0, -3.4)])
	pd.outlined(cone, SeraArt.HAT, OUT, 0.7)
	pd.draw_colored_polygon(PackedVector2Array([bc + Vector2(-3.2, -0.6), bc + Vector2(-0.6, -0.6), bc + Vector2(-1.4, -4.0), bc + Vector2(-2.6, -3.2)]), SeraArt.HAT_HI)
	pd.draw_colored_polygon(PackedVector2Array([bc + Vector2(-3.6, -0.6), bc + Vector2(3.6, -0.6), bc + Vector2(3.2, -1.9), bc + Vector2(-3.3, -1.9)]), SeraArt.GOLD)
	pd.draw_circle(bc + Vector2(-7.6 + sway * 1.3, -8.8), 0.9, SeraArt.GOLD)


# ═══════════════════════════════════════════════════════════
# 아셰 — 잿빛 숄(주황 테), 적갈색 드레스 + 뒤로 묶은 크림 앞치마 끈, 잿빛 단발(끝이 잉걸불), 오른손 사슬에 향로
# ═══════════════════════════════════════════════════════════

func _ashe(bob: float) -> void:
	var OUT := TAsheArt.OUT
	var h := _hair
	for side in [-1, 1]:
		var hip := Vector2(side * 1.6, -15.0)
		var foot := Vector2(side * 2.2, -0.6)
		pd.draw_line(hip, foot, OUT, 3.2)
		pd.draw_line(hip, foot, Color("#3a2c30"), 2.0)
		pd.draw_colored_polygon(PackedVector2Array([foot + Vector2(-1.8, -1.4), foot + Vector2(1.8, -1.4), foot + Vector2(2.0, 1.0), foot + Vector2(-2.0, 1.0)]), OUT)
		pd.draw_colored_polygon(PackedVector2Array([foot + Vector2(-1.2, -0.9), foot + Vector2(1.2, -0.9), foot + Vector2(1.4, 0.4), foot + Vector2(-1.4, 0.4)]), TAsheArt.SHOE)
	# 드레스
	pd.outlined(PackedVector2Array([Vector2(-3.6, -16.5), Vector2(3.6, -16.5), Vector2(7.8 + h * 0.3, -2.0), Vector2(5.2, -1.0), Vector2(-5.2, -1.0), Vector2(-7.8 - h * 0.3, -2.0)]), TAsheArt.DRESS, OUT, 0.7)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-3.4, -16.0), Vector2(-0.6, -16.0), Vector2(-1.4, -2.4), Vector2(-6.8, -2.4)]), TAsheArt.DRESS_HI)
	# 앞치마 끈 (허리 뒤 리본)
	pd.draw_line(Vector2(-3.4, -14.5), Vector2(3.4, -14.5), TAsheArt.APRON, 1.2)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(0.0, -14.5), Vector2(-3.2, -16.2), Vector2(-3.6, -13.0)]), TAsheArt.APRON)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(0.0, -14.5), Vector2(3.2, -16.2), Vector2(3.6, -13.0)]), TAsheArt.APRON_SH)
	pd.draw_line(Vector2(-1.0, -14.0), Vector2(-2.4 + h * 0.3, -7.0), TAsheArt.APRON, 1.0)
	pd.draw_line(Vector2(1.0, -14.0), Vector2(2.2 + h * 0.3, -7.5), TAsheArt.APRON_SH, 1.0)
	pd.draw_circle(Vector2(0.0, -14.5), 1.0, TAsheArt.TRIM)
	# 몸통 + 숄 (등 뒤로 뾰족하게 내려옴)
	pd.outlined(PackedVector2Array([Vector2(-3.4, -25.0), Vector2(3.6, -25.0), Vector2(3.8, -16.0), Vector2(-3.6, -16.0)]), TAsheArt.DRESS, OUT, 0.6)
	var sh := PackedVector2Array([Vector2(-7.0, -24.6), Vector2(7.2, -24.6), Vector2(4.8, -19.0), Vector2(0.2, -12.0), Vector2(-4.6, -19.0)])
	pd.outlined(sh, TAsheArt.SHAWL, OUT, 0.7)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-6.6, -24.2), Vector2(-1.0, -24.2), Vector2(-1.6, -15.6), Vector2(-4.4, -19.2)]), TAsheArt.SHAWL_SH.lerp(TAsheArt.SHAWL, 0.4))
	pd.draw_polyline(PackedVector2Array([Vector2(-6.6, -24.2), Vector2(-4.4, -19.0), Vector2(0.2, -12.6), Vector2(4.6, -19.0), Vector2(6.8, -24.2)]), TAsheArt.TRIM, 0.8)
	pd.draw_rect(Rect2(Vector2(-1.0, -27.6), Vector2(2.0, 2.8)), TAsheArt.SKIN_SH)
	# 팔 + 향로
	_arm(-1, Vector2(-4.4, -23.2), Vector2(-5.8, -13.0), Vector2(-5.8, -13.0), TAsheArt.SHAWL_SH, TAsheArt.SKIN_SH, 2.6)
	var hr := _arm(1, Vector2(4.4, -23.2), Vector2(6.6, -13.0), Vector2(10.0, -36.0), TAsheArt.SHAWL, TAsheArt.SKIN, 2.6)
	_censer(hr)
	# 잿빛 단발 (뒤통수, 끝이 타오름)
	pd.draw_circle(Vector2(0.2, -31.0), 4.6, TAsheArt.HAIR_SH)
	pd.draw_circle(Vector2(0.0, -31.6), 3.8, TAsheArt.HAIR)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-2.6, -34.6), Vector2(1.4, -35.2), Vector2(2.6, -33.0), Vector2(-1.0, -32.6)]), TAsheArt.HAIR_HI)
	for side in [-1, 1]:
		var top := Vector2(side * 4.2, -30.0)
		var tip := Vector2(side * 4.8 + h * 0.3 * side, -25.6)
		pd.draw_line(top, tip, OUT, 2.6)
		pd.draw_line(top, tip, TAsheArt.HAIR, 1.6)
		var f := 0.6 + 0.4 * sin(t * 9.0 + float(side))
		pd.glow(tip, 3.0, Color(TAsheArt.EMBER, 0.45 * f), 0.0)
		pd.draw_line(tip + Vector2(0, -2.0), tip + Vector2(0, 0.8), TAsheArt.EMBER, 1.4)
		pd.draw_rect(Rect2(tip + Vector2(-0.5, -0.4), Vector2(1.0, 1.0)), Color(TAsheArt.EMBER_HOT, f))
	pd.draw_line(Vector2(-4.4, -29.0), Vector2(4.6, -29.0), TAsheArt.HAIR_SH, 0.8) # 머리 끝단 그늘


func _censer(hand: Vector2) -> void:
	var ang := sin(t * 3.1) * 0.18 * (1.0 - cast_k)
	var c := hand + Vector2(sin(ang), cos(ang)) * 4.0 + Vector2(0, 1.6)
	pd.draw_line(hand, c + Vector2(0, -1.6), TAsheArt.BRONZE_HI, 0.7)
	var glow := 0.35 + 0.65 * cast_k + 0.1 * sin(t * 11.0)
	pd.glow(c, 5.0 + 3.0 * cast_k, Color(TAsheArt.EMBER, 0.35 * glow), 0.0)
	pd.outlined(PackedVector2Array([c + Vector2(-2.2, -1.6), c + Vector2(2.2, -1.6), c + Vector2(2.6, 0.6), c + Vector2(1.4, 2.4), c + Vector2(-1.4, 2.4), c + Vector2(-2.6, 0.6)]), TAsheArt.BRONZE, TAsheArt.OUT, 0.6)
	pd.draw_rect(Rect2(c + Vector2(-1.2, -1.0), Vector2(2.4, 1.0)), Color(TAsheArt.EMBER_HOT, 0.9 * glow))
	var n := 2 + int(3.0 * cast_k)
	for i in n:
		var ph := t * (2.4 + float(i) * 0.37) + float(i) * 1.7
		var rise := fmod(ph * 7.0, 11.0 + 7.0 * cast_k)
		var x := sin(ph * 2.3) * (1.4 + cast_k)
		var a := (0.9 - rise / (11.0 + 7.0 * cast_k)) * (0.5 + 0.5 * cast_k)
		pd.draw_rect(Rect2(c + Vector2(x - 0.5, -1.8 - rise), Vector2(1.0, 1.0)), Color(TAsheArt.EMBER_HOT if i % 2 == 0 else TAsheArt.EMBER, a))
