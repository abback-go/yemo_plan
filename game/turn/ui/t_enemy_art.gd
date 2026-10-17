class_name TEnemyArt
extends PDraw.Canvas
## 적 코드 그림 3종 — v2: 카메라가 파티 뒤에 있으므로 적은 **정면**(카메라 쪽)을 본다. 원점 = 발밑 가운데.
## 설정이 보류라 "그림자·재" 실루엣 — 검정·잿빛·뼈흰·잉걸불 주황.
## hound 그림자 들개(~24px) · monk 재의 수도사(떠 있는 로브, ~44px) · king 재의 기사왕(큰 갑옷, ~70px; phase 1이면 갑옷이 깨져 불씨가 드러남)
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
var phase := 0
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


## 정면의 들개: 낮게 웅크린 그림자 덩이, 어깨 둘, 앞발 둘, 가운데 머리와 잉걸불 두 눈. 공격 땐 앞으로(카메라 쪽) 덮침
func _hound() -> void:
	var breathe := sin(t * 2.6) * 0.4
	var lunge := sin(minf(atk_k * 1.3, 1.0) * PI) if pose == "attack" else 0.0
	pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.28))
	pd.glow(Vector2(0, 0), 13.0 + 3.0 * lunge, Color(0, 0, 0, 0.5), 0.0)
	pd.draw_set_transform(Vector2(0, lunge * 4.0), 0.0, Vector2(1.0 + 0.18 * lunge, 1.0 + 0.1 * lunge + breathe * 0.02))
	# 연기 (몸 가장자리에서 피어오름)
	for i in 5:
		var ph := t * 1.8 + float(i) * 1.3
		var p := Vector2(sin(ph) * 9.0 + (float(i) - 2.0) * 3.0, -16.0 - fmod(ph * 4.0, 9.0))
		pd.draw_circle(p, 2.2 - fmod(ph * 4.0, 9.0) * 0.15, Color(SHADE, 0.5 - fmod(ph * 4.0, 9.0) * 0.05))
	# 앞발 둘
	for sx in [-6.0, 6.0]:
		pd.draw_line(Vector2(sx, -8.0), Vector2(sx * 1.15, 0.0), BLACK, 3.0)
		pd.draw_line(Vector2(sx, -8.0), Vector2(sx * 1.15, 0.0), SHADE, 1.4)
		for c in 3:
			pd.draw_line(Vector2(sx * 1.15 + (float(c) - 1.0) * 1.4, 0.0), Vector2(sx * 1.15 + (float(c) - 1.0) * 1.8, 1.6), BONE_DIM, 0.8)
	# 몸통 (어깨가 솟은 둥근 그림자)
	var body := PackedVector2Array()
	var pts := [Vector2(-13, -6), Vector2(-12, -14), Vector2(-7, -19), Vector2(0, -17), Vector2(7, -19), Vector2(12, -14), Vector2(13, -6), Vector2(8, -2), Vector2(-8, -2)]
	for i in pts.size():
		var p: Vector2 = pts[i]
		var jag := sin(t * 5.0 + float(i) * 2.1 + float(seed_n)) * 0.7
		body.append(p + Vector2(jag, jag * 0.5))
	pd.outlined(body, BLACK, RIM, 0.8)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-6, -16), Vector2(0, -15), Vector2(5, -16), Vector2(3, -10), Vector2(-3, -10)]), SHADE)
	# 머리 (가운데, 카메라 쪽으로 숙임) + 귀 + 눈
	var hd := Vector2(0.0, -11.0 + lunge * 3.0)
	pd.outlined(PackedVector2Array([hd + Vector2(-6, -5), hd + Vector2(6, -5), hd + Vector2(5, 3), hd + Vector2(2, 5.5), hd + Vector2(-2, 5.5), hd + Vector2(-5, 3)]), BLACK, RIM, 0.8)
	for sx in [-1.0, 1.0]:
		pd.draw_colored_polygon(PackedVector2Array([hd + Vector2(sx * 3.0, -4.5), hd + Vector2(sx * 6.5, -11.0), hd + Vector2(sx * 7.0, -4.0)]), BLACK)
		pd.draw_colored_polygon(PackedVector2Array([hd + Vector2(sx * 4.0, -5.0), hd + Vector2(sx * 6.0, -9.0), hd + Vector2(sx * 6.2, -5.0)]), SHADE)
	var ek := 0.8 + 0.2 * sin(t * 7.0)
	for sx in [-2.6, 2.6]:
		var eye := hd + Vector2(sx, -1.0)
		pd.glow(eye, 3.6, Color(EMBER, 0.5 * ek), 0.0)
		pd.draw_rect(Rect2(eye - Vector2(1.3, 0.5), Vector2(2.6, 1.0)), Color(EMBER_HOT, ek))
		pd.draw_rect(Rect2(eye - Vector2(0.5, 0.3), Vector2(1.0, 0.6)), EMBER_CORE)
	if lunge > 0.3:
		for i in 5:
			pd.draw_colored_polygon(PackedVector2Array([hd + Vector2(-3.2 + float(i) * 1.6, 3.0), hd + Vector2(-2.6 + float(i) * 1.6, 5.4), hd + Vector2(-2.0 + float(i) * 1.6, 3.0)]), BONE)


## 정면의 수도사: 좌우 대칭 로브, 두건 속 공허에 잉걸불 두 점, 손을 모았다가 시전 땐 양옆으로 들어 올림
func _monk() -> void:
	var hover := sin(t * 1.8) * 1.5 - 3.0
	var raise := cast_k
	pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.25))
	pd.glow(Vector2(0, 0), 11.0, Color(0, 0, 0, 0.45), 0.0)
	pd.draw_set_transform(Vector2(0, hover))
	var n := 3 + int(6.0 * raise)
	for i in n:
		var ph := t * 0.9 + float(i) * 1.37
		var fall := fmod(ph * 9.0, 30.0)
		var x := sin(ph * 2.0 + float(i)) * 9.0
		pd.draw_rect(Rect2(Vector2(x - 0.5, -42.0 + fall), Vector2(1.0, 1.0)), Color(ASH_L, 0.6 * (1.0 - fall / 30.0)))
	var robe := PackedVector2Array([Vector2(-6.5, -33), Vector2(6.5, -33), Vector2(9.5, -12), Vector2(8, -4), Vector2(5, -8), Vector2(2, -2), Vector2(-1, -7), Vector2(-4, -1), Vector2(-7, -6), Vector2(-9.5, -12)])
	pd.outlined(robe, ASH_D, BLACK, 0.8)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-5.5, -32), Vector2(-1, -32), Vector2(0.5, -12), Vector2(-7, -12)]), ASH)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-1.2, -31), Vector2(1.2, -31), Vector2(1.6, -10), Vector2(-1.6, -10)]), ASH_D.darkened(0.3)) # 앞섶 그늘
	pd.draw_line(Vector2(-7, -20), Vector2(7, -20), BONE_DIM, 1.0)
	pd.draw_circle(Vector2(0.0, -19.5), 1.1, BONE_DIM)
	var hl := Vector2(-2.0, -21.5).lerp(Vector2(-10.0, -34.0), raise)
	var hr := Vector2(2.0, -21.5).lerp(Vector2(10.0, -34.0), raise)
	for h in [hl, hr]:
		pd.draw_circle(h, 1.9, BLACK)
		pd.draw_circle(h, 1.3, BONE_DIM)
	if raise > 0.2:
		pd.glow(hl, 5.0, Color(EMBER, 0.4 * raise), 0.0)
		pd.glow(hr, 5.0, Color(EMBER, 0.4 * raise), 0.0)
	var hood := PackedVector2Array([Vector2(-8, -33), Vector2(-4, -44), Vector2(4, -44), Vector2(8, -33), Vector2(6, -31), Vector2(-6, -31)])
	pd.outlined(hood, ASH, BLACK, 0.8)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-5.5, -33), Vector2(-2.5, -41), Vector2(2.5, -41), Vector2(5.5, -33)]), BLACK)
	var ek := 0.7 + 0.3 * sin(t * 5.0)
	for ex in [-2.4, 2.4]:
		var e := Vector2(ex, -36.5)
		pd.glow(e, 3.0, Color(EMBER, 0.45 * ek), 0.0)
		pd.draw_rect(Rect2(e - Vector2(0.9, 0.4), Vector2(1.8, 0.8)), Color(EMBER_HOT, ek))
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-4, -44), Vector2(-1, -44), Vector2(-6.5, -34), Vector2(-7.5, -34)]), ASH_L.lerp(ASH, 0.5))


## 정면의 기사왕: 좌우 어깨 갑옷, 가슴의 갈라진 불씨, 부러진 왕관 투구, 오른손(화면 왼쪽)에 세운 대검. 휘두르면 검이 카메라 쪽으로 호를 그림
func _king() -> void:
	var broken := phase >= 1
	var sway := sin(t * 1.4) * 0.6
	var swing := sin(minf(atk_k * 1.2, 1.0) * PI) if pose == "attack" else 0.0
	var raise := cast_k
	pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.25))
	pd.glow(Vector2(0, 0), 28.0, Color(0, 0, 0, 0.55), 0.0)
	pd.draw_set_transform(Vector2(sway * 0.5, 0), 0.0, Vector2(1.0 + 0.04 * swing, 1.0 - 0.03 * swing))
	# 망토 (어깨 뒤로 양옆에 늘어짐)
	var cape := PackedVector2Array([Vector2(-20, -56), Vector2(20, -56), Vector2(24 + sway, -30), Vector2(22, -6), Vector2(17, -12), Vector2(13, -2), Vector2(-13, -2), Vector2(-17, -12), Vector2(-22, -6), Vector2(-24 - sway, -30)])
	pd.outlined(cape, ASH_D, BLACK, 0.9)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-18, -55), Vector2(-8, -55), Vector2(-12, -30), Vector2(-20, -14)]), ASH)
	# 다리 (각반)
	for lx in [-7.0, 7.0]:
		pd.outlined(PackedVector2Array([Vector2(lx - 5, -28), Vector2(lx + 5, -28), Vector2(lx + 4.5, -2), Vector2(lx + 6.5, 0), Vector2(lx - 6.5, 0), Vector2(lx - 4.5, -2)]), ARMOR, BLACK, 0.8)
		pd.draw_line(Vector2(lx - 3.5, -26), Vector2(lx - 3, -4), ARMOR_HI, 1.0)
	# 몸통 갑옷 (가슴판 + 허리)
	var torso := PackedVector2Array([Vector2(-14, -58), Vector2(14, -58), Vector2(16, -44), Vector2(12, -28), Vector2(-12, -28), Vector2(-16, -44)])
	pd.outlined(torso, ARMOR, BLACK, 1.0)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-13, -57), Vector2(-4, -57), Vector2(-5, -30), Vector2(-11, -30)]), ARMOR_HI)
	pd.draw_line(Vector2(-15, -46), Vector2(15, -46), ARMOR_EDGE, 1.2)
	pd.draw_line(Vector2(-12, -36), Vector2(12, -36), ARMOR_EDGE, 1.0)
	# 어깨 갑옷 둘
	for sx in [-17.0, 17.0]:
		pd.outlined(PackedVector2Array([Vector2(sx - 8, -60), Vector2(sx + 8, -60), Vector2(sx + 9, -49), Vector2(sx - 9, -49)]), ARMOR, BLACK, 0.9)
		pd.draw_line(Vector2(sx - 7, -58), Vector2(sx + 7, -58), ARMOR_EDGE, 1.0)
	# 가슴의 갈라진 틈 (깨지면 불씨가 드러남)
	var crack_a := (0.35 + 0.15 * sin(t * 3.0)) if not broken else (0.85 + 0.15 * sin(t * 8.0))
	for c in [[Vector2(-2, -55), Vector2(2, -47), Vector2(-1, -40)], [Vector2(7, -52), Vector2(5, -44), Vector2(8, -34)], [Vector2(-8, -44), Vector2(-4, -38), Vector2(-7, -31)]]:
		for i in range(1, c.size()):
			pd.draw_line(c[i - 1], c[i], Color(EMBER, crack_a), 1.6 if broken else 1.0)
			pd.draw_line(c[i - 1], c[i], Color(EMBER_HOT, crack_a * 0.8), 0.6)
	if broken:
		pd.glow(Vector2(0, -44), 15.0, Color(EMBER, 0.35 + 0.1 * sin(t * 6.0)), 0.0)
		pd.draw_circle(Vector2(0, -44), 3.2 + sin(t * 9.0) * 0.5, Color(EMBER_HOT, 0.9))
		pd.draw_circle(Vector2(0, -44), 1.6, EMBER_CORE)
		for i in 7:
			var ph := t * 3.0 + float(i) * 0.9
			var rise := fmod(ph * 11.0, 34.0)
			pd.draw_rect(Rect2(Vector2(sin(ph * 2.0) * 7.0 - 0.5, -45.0 - rise), Vector2(1.0, 1.0)), Color(EMBER_HOT, 0.8 * (1.0 - rise / 34.0)))
	# 왼팔(화면 오른쪽): 방패 손 — 가슴 앞 주먹 / 시전 땐 들어 올림
	var lsh := Vector2(16.0, -54.0)
	var lh := Vector2(20.0, -38.0).lerp(Vector2(24.0, -58.0), raise)
	pd.draw_line(lsh, lh, BLACK, 6.0)
	pd.draw_line(lsh, lh, ARMOR_HI, 4.0)
	pd.draw_circle(lh, 2.8, BLACK)
	pd.draw_circle(lh, 2.0, ARMOR_EDGE)
	# 오른팔(화면 왼쪽) + 대검: 평소엔 땅에 세움 → 휘두르면 위에서 아래로 카메라 쪽 호
	var hand := Vector2(-20.0, -34.0).lerp(Vector2(-10.0, -52.0), maxf(swing, raise * 0.8))
	var ang := lerpf(0.15, -2.0, swing) + raise * -1.2
	var tip := hand + Vector2(sin(ang), cos(ang)) * 44.0
	pd.draw_line(Vector2(-15.0, -54.0), hand, BLACK, 6.0)
	pd.draw_line(Vector2(-15.0, -54.0), hand, ARMOR_HI, 4.0)
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
	# 투구 + 면갑 틈의 눈 + 부러진 왕관
	var hc := Vector2(0.0, -66.0)
	pd.outlined(PackedVector2Array([hc + Vector2(-7.5, 6), hc + Vector2(7.5, 6), hc + Vector2(8.5, -3), hc + Vector2(5, -8), hc + Vector2(-5, -8), hc + Vector2(-8.5, -3)]), ARMOR, BLACK, 1.0)
	pd.draw_colored_polygon(PackedVector2Array([hc + Vector2(-7, 5), hc + Vector2(-3, 5), hc + Vector2(-3, -7), hc + Vector2(-7.5, -2)]), ARMOR_HI)
	pd.draw_rect(Rect2(hc + Vector2(-8, -1), Vector2(16, 3.5)), BLACK)
	var ek := 0.75 + 0.25 * sin(t * 4.0)
	for ex in [-3.2, 3.2]:
		var e := hc + Vector2(ex, 0.8)
		pd.glow(e, 3.5, Color(EMBER if not broken else RED, 0.5 * ek), 0.0)
		pd.draw_rect(Rect2(e - Vector2(1.3, 0.5), Vector2(2.6, 1.0)), Color(EMBER_HOT, ek))
	for i in 5:
		var x := -8.0 + float(i) * 4.0
		var h := 7.0 if i != 3 else 2.5
		pd.outlined(PackedVector2Array([hc + Vector2(x - 1.8, -7), hc + Vector2(x, -7 - h), hc + Vector2(x + 1.8, -7)]), BONE_DIM, BLACK, 0.6)
