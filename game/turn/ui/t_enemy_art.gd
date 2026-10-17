class_name TEnemyArt
extends PDraw.Canvas
## 적 코드 그림 3종 (왼쪽을 본다, 원점 = 발밑 가운데). 설정이 보류라 "그림자·재" 실루엣으로 — 검정·잿빛·뼈흰·잉걸불 주황.
## hound 그림자 들개 (키 ~22px) · monk 재의 수도사 (떠 있는 잿빛 로브, ~44px) · king 재의 기사왕 (큰 갑옷, ~70px, phase 1이면 갑옷이 깨져 불씨가 드러남)
## pose: idle · attack · cast · hurt · die. atk_k = 공격 동작 진행 0→1 (장면이 넣는다)

const BLACK := Color("#0c090f")
const SHADE := Color("#251b29")
const RIM := Color("#4a3a52")
const ASH := Color("#6a5c58")
const ASH_D := Color("#3a2d2a")
const ASH_L := Color("#9c8c86")
const BONE := Color("#ece4d6")
const BONE_DIM := Color("#a3978a")
const EMBER := Color("#ff6a2a")
const EMBER_HOT := Color("#ffd27a")
const EMBER_CORE := Color("#fff4d6")
const ARMOR := Color("#1c1418")
const ARMOR_HI := Color("#3a2d33")
const ARMOR_EDGE := Color("#5a4a52")
const STEEL := Color("#8d8a90")
const STEEL_D := Color("#4a474e")
const RED := Color("#ff2f58")

var kind := "hound"
var pose := "idle"
var t := 0.0
var atk_k := 0.0
var cast_k := 0.0
var flash := 0.0
var phase := 0 ## 보스의 체력 줄 번호
var fade := 1.0
var seed_n := 0


func step(delta: float) -> void:
	t += delta
	flash = maxf(flash - delta * 5.0, 0.0)
	cast_k = move_toward(cast_k, 1.0 if pose == "cast" else 0.0, delta * 4.0)
	if pose == "die":
		fade = maxf(fade - delta * 1.6, 0.0)
	queue_redraw()


func _paint() -> void:
	modulate = Color(1.0, 1.0 - 0.5 * flash, 1.0 - 0.45 * flash, fade)
	match kind:
		"hound":
			_hound()
		"monk":
			_monk()
		"king":
			_king()


func _hound() -> void:
	var breathe := sin(t * 2.6) * 0.4
	var lunge := 0.0
	if pose == "attack":
		lunge = sin(minf(atk_k * 1.3, 1.0) * PI)
	var lean := -0.25 * lunge
	pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.25))
	pd.glow(Vector2(-2, 0), 12.0, Color(0, 0, 0, 0.5), 0.0)
	pd.draw_set_transform(Vector2(-lunge * 10.0, 0), lean, Vector2(1.0 + 0.1 * lunge, 1.0 - 0.06 * lunge + breathe * 0.02))
	# 연기 꼬리 (뒤쪽 = 오른쪽)
	for i in 4:
		var ph := t * 2.0 + float(i) * 0.9
		var p := Vector2(10.0 + float(i) * 3.2 + sin(ph) * 1.2, -12.0 - float(i) * 2.2 + cos(ph * 1.3) * 1.5)
		pd.draw_circle(p, 2.4 - float(i) * 0.35, Color(SHADE, 0.55 - float(i) * 0.1))
	# 뒷다리·앞다리
	for leg in [[Vector2(7.0, -9.0), Vector2(9.5, 0.0)], [Vector2(5.0, -9.0), Vector2(5.0, 0.0)], [Vector2(-5.0, -9.0), Vector2(-7.5 - lunge * 3.0, 0.0)], [Vector2(-7.0, -9.0), Vector2(-4.5, 0.0)]]:
		pd.draw_line(leg[0], leg[1], BLACK, 2.6)
		pd.draw_line(leg[0], leg[1], SHADE, 1.2)
	# 몸통 (들쭉날쭉한 그림자)
	var body := PackedVector2Array()
	var pts := [Vector2(-11, -11), Vector2(-7, -15), Vector2(0, -16.5), Vector2(8, -15), Vector2(12, -11), Vector2(10, -7), Vector2(0, -6), Vector2(-9, -7)]
	for i in pts.size():
		var p: Vector2 = pts[i]
		var jag := sin(t * 5.0 + float(i) * 2.1 + float(seed_n)) * 0.7
		body.append(p + Vector2(jag, jag * 0.5))
	pd.outlined(body, BLACK, RIM, 0.8)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-6, -14), Vector2(4, -15), Vector2(6, -12), Vector2(-3, -11)]), SHADE)
	# 머리 (왼쪽으로 쐐기) + 귀 + 잉걸불 눈
	var hd := Vector2(-13.0 - lunge * 2.0, -14.0 + lunge * 2.0)
	pd.outlined(PackedVector2Array([hd + Vector2(5, -4), hd + Vector2(-7, -1.5), hd + Vector2(-8, 1.5), hd + Vector2(-3, 3.5), hd + Vector2(5, 2)]), BLACK, RIM, 0.8)
	pd.draw_colored_polygon(PackedVector2Array([hd + Vector2(1, -4), hd + Vector2(3, -9), hd + Vector2(5, -4)]), BLACK)
	pd.draw_colored_polygon(PackedVector2Array([hd + Vector2(-2, -4.2), hd + Vector2(-1, -8.5), hd + Vector2(2, -4)]), SHADE)
	var eye := hd + Vector2(-3.0, -1.2)
	var ek := 0.8 + 0.2 * sin(t * 7.0)
	pd.glow(eye, 4.0, Color(EMBER, 0.5 * ek), 0.0)
	pd.draw_rect(Rect2(eye - Vector2(1.6, 0.5), Vector2(2.6, 1.0)), Color(EMBER_HOT, ek))
	pd.draw_rect(Rect2(eye - Vector2(0.8, 0.3), Vector2(1.0, 0.6)), EMBER_CORE)
	if lunge > 0.3: # 이빨
		for i in 3:
			pd.draw_colored_polygon(PackedVector2Array([hd + Vector2(-6.5 + float(i) * 1.6, 1.0), hd + Vector2(-5.9 + float(i) * 1.6, 3.0), hd + Vector2(-5.3 + float(i) * 1.6, 1.0)]), BONE)


func _monk() -> void:
	var hover := sin(t * 1.8) * 1.5 - 3.0
	var raise := cast_k
	pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.25))
	pd.glow(Vector2(0, 0), 11.0, Color(0, 0, 0, 0.45), 0.0)
	pd.draw_set_transform(Vector2(0, hover))
	# 떨어지는 재 (시전 때 많이)
	var n := 3 + int(6.0 * raise)
	for i in n:
		var ph := t * 0.9 + float(i) * 1.37
		var fall := fmod(ph * 9.0, 30.0)
		var x := sin(ph * 2.0 + float(i)) * 9.0
		pd.draw_rect(Rect2(Vector2(x - 0.5, -42.0 + fall), Vector2(1.0, 1.0)), Color(ASH_L, 0.6 * (1.0 - fall / 30.0)))
	# 로브 (아래가 찢어진 긴 삼각)
	var robe := PackedVector2Array([Vector2(-6.5, -33), Vector2(6.5, -33), Vector2(9.5, -12), Vector2(8, -4), Vector2(5, -8), Vector2(2, -2), Vector2(-1, -7), Vector2(-4, -1), Vector2(-7, -6), Vector2(-9.5, -12)])
	pd.outlined(robe, ASH_D, BLACK, 0.8)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-5.5, -32), Vector2(-1, -32), Vector2(0.5, -12), Vector2(-7, -12)]), ASH)
	pd.draw_line(Vector2(-7, -20), Vector2(7, -20), BONE_DIM, 1.0) # 허리끈
	pd.draw_circle(Vector2(-6.5, -19.5), 1.1, BONE_DIM)
	# 손 (모아 쥠 → 시전 땐 양옆으로 들어 올림)
	var hl := Vector2(-3.5, -22.0).lerp(Vector2(-10.0, -34.0), raise)
	var hr := Vector2(-1.5, -22.0).lerp(Vector2(8.0, -36.0), raise)
	for h in [hl, hr]:
		pd.draw_circle(h, 1.9, BLACK)
		pd.draw_circle(h, 1.3, BONE_DIM)
	if raise > 0.2:
		pd.glow(hl, 5.0, Color(EMBER, 0.4 * raise), 0.0)
		pd.glow(hr, 5.0, Color(EMBER, 0.4 * raise), 0.0)
	# 두건 (안은 공허 + 잉걸불 눈)
	var hood := PackedVector2Array([Vector2(-8, -33), Vector2(-3, -44), Vector2(4, -45), Vector2(8, -34), Vector2(6, -31), Vector2(-7, -31)])
	pd.outlined(hood, ASH, BLACK, 0.8)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-6.5, -33), Vector2(-3, -41), Vector2(1, -41.5), Vector2(3, -33.5)]), BLACK)
	var ek := 0.7 + 0.3 * sin(t * 5.0)
	for ex in [-4.0, -0.5]:
		var e := Vector2(ex, -37.0)
		pd.glow(e, 3.0, Color(EMBER, 0.45 * ek), 0.0)
		pd.draw_rect(Rect2(e - Vector2(0.9, 0.4), Vector2(1.8, 0.8)), Color(EMBER_HOT, ek))
	pd.draw_colored_polygon(PackedVector2Array([Vector2(1, -45), Vector2(4, -45), Vector2(7.5, -36), Vector2(4, -41)]), ASH_L.lerp(ASH, 0.5))


func _king() -> void:
	var broken := phase >= 1
	var sway := sin(t * 1.4) * 0.6
	var swing := 0.0
	if pose == "attack":
		swing = sin(minf(atk_k * 1.2, 1.0) * PI)
	var raise := cast_k
	pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.25))
	pd.glow(Vector2(0, 0), 26.0, Color(0, 0, 0, 0.55), 0.0)
	pd.draw_set_transform(Vector2(sway * 0.5, 0), -0.05 * swing + 0.03 * raise)
	# 망토 (뒤 = 오른쪽), 찢긴 끝
	var cape := PackedVector2Array([Vector2(4, -58), Vector2(16, -56), Vector2(24 + sway, -30), Vector2(22, -6), Vector2(18, -12), Vector2(14, -2), Vector2(10, -10), Vector2(6, -4)])
	pd.outlined(cape, ASH_D, BLACK, 0.9)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(8, -56), Vector2(15, -55), Vector2(20 + sway, -30), Vector2(13, -14)]), ASH)
	# 다리 (갑옷 각반)
	for lx in [-6.0, 6.0]:
		pd.outlined(PackedVector2Array([Vector2(lx - 4.5, -26), Vector2(lx + 4.5, -26), Vector2(lx + 4.0, -2), Vector2(lx + 6.0, 0), Vector2(lx - 6.0, 0), Vector2(lx - 4.0, -2)]), ARMOR, BLACK, 0.8)
		pd.draw_line(Vector2(lx - 3, -24), Vector2(lx - 2.5, -4), ARMOR_HI, 1.0)
	# 대검 (왼손, 평소엔 땅에 세움 → 휘두를 때 호를 그림)
	var hand := Vector2(-16.0, -30.0)
	var ang := lerpf(0.25, -2.4, swing) + raise * -1.4
	var tip := hand + Vector2(sin(ang), cos(ang)) * 42.0
	pd.draw_line(hand, tip, BLACK, 6.0)
	pd.draw_line(hand, tip, STEEL_D, 4.0)
	pd.draw_line(hand, tip, STEEL, 1.6)
	pd.draw_line(hand + Vector2(-5, 0), hand + Vector2(5, 0), BLACK, 3.5)
	pd.draw_line(hand + Vector2(-5, 0), hand + Vector2(5, 0), ARMOR_EDGE, 2.0)
	if pose == "cast" and raise > 0.3:
		pd.glow(tip, 10.0, Color(RED, 0.5 * raise), 0.0)
		pd.draw_line(hand, tip, Color(RED, 0.7 * raise), 2.0)
	if swing > 0.2:
		pd.glow(tip, 8.0, Color(BONE, 0.5 * swing), 0.0)
	# 몸통 갑옷
	var torso := PackedVector2Array([Vector2(-13, -58), Vector2(13, -58), Vector2(15, -44), Vector2(12, -28), Vector2(-12, -28), Vector2(-15, -44)])
	pd.outlined(torso, ARMOR, BLACK, 1.0)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-12, -57), Vector2(-2, -57), Vector2(-1, -30), Vector2(-11, -30)]), ARMOR_HI)
	pd.draw_line(Vector2(-14, -46), Vector2(14, -46), ARMOR_EDGE, 1.2)
	pd.draw_line(Vector2(-12, -36), Vector2(12, -36), ARMOR_EDGE, 1.0)
	# 어깨 갑옷
	for sx in [-15.0, 15.0]:
		pd.outlined(PackedVector2Array([Vector2(sx - 7, -60), Vector2(sx + 7, -60), Vector2(sx + 8, -50), Vector2(sx - 8, -50)]), ARMOR, BLACK, 0.9)
		pd.draw_line(Vector2(sx - 6, -58), Vector2(sx + 6, -58), ARMOR_EDGE, 1.0)
	# 갑옷 틈의 불씨 (깨진 뒤엔 크게 벌어져 타오름)
	var crack_a := (0.35 + 0.15 * sin(t * 3.0)) if not broken else (0.85 + 0.15 * sin(t * 8.0))
	var cracks := [[Vector2(-4, -54), Vector2(2, -46), Vector2(-1, -40)], [Vector2(8, -50), Vector2(5, -42), Vector2(9, -34)], [Vector2(-9, -42), Vector2(-4, -36), Vector2(-7, -30)]]
	for c in cracks:
		for i in range(1, c.size()):
			pd.draw_line(c[i - 1], c[i], Color(EMBER, crack_a), 1.6 if broken else 1.0)
			pd.draw_line(c[i - 1], c[i], Color(EMBER_HOT, crack_a * 0.8), 0.6)
	if broken:
		pd.glow(Vector2(0, -43), 14.0, Color(EMBER, 0.35 + 0.1 * sin(t * 6.0)), 0.0)
		pd.draw_circle(Vector2(0, -43), 3.0 + sin(t * 9.0) * 0.5, Color(EMBER_HOT, 0.9))
		pd.draw_circle(Vector2(0, -43), 1.5, EMBER_CORE)
		for i in 7:
			var ph := t * 3.0 + float(i) * 0.9
			var rise := fmod(ph * 11.0, 34.0)
			pd.draw_rect(Rect2(Vector2(sin(ph * 2.0) * 7.0 - 0.5, -44.0 - rise), Vector2(1.0, 1.0)), Color(EMBER_HOT, 0.8 * (1.0 - rise / 34.0)))
	# 오른팔(앞) — 가슴 앞에 주먹
	var fsh := Vector2(-13.0, -54.0)
	var fh := Vector2(-20.0, -40.0).lerp(Vector2(-24.0, -56.0), raise)
	pd.draw_line(fsh, fh, BLACK, 6.0)
	pd.draw_line(fsh, fh, ARMOR_HI, 4.0)
	pd.draw_circle(fh, 2.8, BLACK)
	pd.draw_circle(fh, 2.0, ARMOR_EDGE)
	# 투구 + 부러진 왕관
	var hc := Vector2(-1.0, -66.0)
	pd.outlined(PackedVector2Array([hc + Vector2(-7, 6), hc + Vector2(7, 6), hc + Vector2(8, -3), hc + Vector2(4, -8), hc + Vector2(-5, -8), hc + Vector2(-8, -3)]), ARMOR, BLACK, 1.0)
	pd.draw_colored_polygon(PackedVector2Array([hc + Vector2(-7, 5), hc + Vector2(-3, 5), hc + Vector2(-3, -7), hc + Vector2(-7, -2)]), ARMOR_HI)
	pd.draw_rect(Rect2(hc + Vector2(-8, -1), Vector2(16, 3.5)), BLACK) # 면갑 틈
	var ek := 0.75 + 0.25 * sin(t * 4.0)
	for ex in [-5.0, -1.0]:
		var e := hc + Vector2(ex, 0.8)
		pd.glow(e, 3.5, Color(EMBER if not broken else RED, 0.5 * ek), 0.0)
		pd.draw_rect(Rect2(e - Vector2(1.2, 0.5), Vector2(2.4, 1.0)), Color(EMBER_HOT, ek))
	for i in 4: # 왕관 — 한 뿔은 부러짐
		var x := -6.0 + float(i) * 4.0
		var h := 7.0 if i != 2 else 2.5
		pd.outlined(PackedVector2Array([hc + Vector2(x - 1.8, -7), hc + Vector2(x, -7 - h), hc + Vector2(x + 1.8, -7)]), BONE_DIM, BLACK, 0.6)
