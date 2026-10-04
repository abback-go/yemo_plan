class_name StColossusArt
extends RefCounted
## 거신(巨神) — 바깥 신들의 하얀 얼굴 없는 거인 그림. 배경(행진)·적(colossus)·반격 발판(colossus_ride)이 같이 쓴다.
## 매끈한 흰 몸 + 기하학 금(이음선), 얼굴 자리에 세로로 갈라진 틈, 머리 뒤의 가는 기하학 고리(docs/bible/art.md 4절).
## 진격의 거인 "땅울림"처럼: 긴 다리, 앞으로 굽은 상체, 무릎까지 늘어진 긴 팔, 느리고 무거운 걸음.
##
## draw_giant(c, foot, h, ph, dir, pal): foot = 두 발 사이 바닥 점, h = 키(px), ph = 걸음 위상(0~1이 두 걸음),
## dir = 걷는 쪽(1 오른쪽), pal = palette() 결과(색·투명도). 돌려주는 사전에 머리·손·발 위치(그 밖의 연출용).

const FOG := Color("#6c6a7c") ## 기본 안개색 (무채색 — 거신이 분홍·주황으로 물들지 않게)


## 거리감에 맞춘 색 (haze 0 = 가까움·선명, 1 = 아주 멀리·안개에 묻힘). sleep 0~1 = 푸른 불에 잠드는 정도
static func palette(haze := 0.0, alpha := 1.0, fog := FOG, sleep := 0.0) -> Dictionary:
	var body := StArt.GOD_WHITE.lerp(fog, haze * 0.62)
	var shade := StArt.GOD_SHADE.lerp(fog.darkened(0.1), haze * 0.62)
	var deep := StArt.GOD_DEEP.lerp(fog.darkened(0.25), haze * 0.62)
	var line := StArt.GOD_LINE.lerp(body, 0.25 + haze * 0.5)
	if sleep > 0.0:
		var b := Color(0.35, 0.55, 0.95)
		body = body.lerp(b.lerp(Color.WHITE, 0.4), sleep * 0.5)
		shade = shade.lerp(b.darkened(0.15), sleep * 0.55)
		deep = deep.lerp(b.darkened(0.45), sleep * 0.55)
		line = line.lerp(StArt.FOX_BLUE, sleep * 0.7)
	return {
		"body": Color(body, alpha), "shade": Color(shade, alpha), "deep": Color(deep, alpha),
		"line": Color(line, alpha * (1.0 - haze * 0.45)), "slit": Color(StArt.GOD_GLOW, alpha * (0.95 - haze * 0.35)),
		"haze": haze, "alpha": alpha, "sleep": sleep,
	}


static func _limb(c: CanvasItem, a: Vector2, b: Vector2, w1: float, w2: float, col: Color) -> void:
	var d := (b - a)
	if d.length() < 0.5:
		return
	var n := d.orthogonal().normalized()
	c.draw_colored_polygon(PackedVector2Array([a + n * w1, b + n * w2, b - n * w2, a - n * w1]), col)
	c.draw_circle(b, w2, col)


## 다리 하나: 엉덩이에서 각도 ang(0 = 아래), 무릎 굽힘 bend. 돌려줌: [무릎, 발목]
static func _leg(hip: Vector2, ang: float, bend: float, thigh: float, shin: float, dir: float) -> Array:
	var knee := hip + Vector2(sin(ang) * dir, cos(ang)) * thigh
	var a2 := ang - bend
	var ankle := knee + Vector2(sin(a2) * dir, cos(a2)) * shin
	return [knee, ankle]


## 걸음 위상 ph에서 엉덩이 높이 (발에서 엉덩이까지, px) — 발판 등이 몸의 오르내림을 알 때
static func hip_height(h: float, ph: float) -> float:
	var w := TAU * ph
	var swing := sin(w) * 0.34
	var bend_f := maxf(0.0, -cos(w)) * 0.75
	var bend_b := maxf(0.0, cos(w)) * 0.75
	var thigh := h * 0.26
	var shin := h * 0.26
	return maxf(thigh * cos(swing) + shin * cos(swing - bend_f), thigh * cos(-swing) + shin * cos(-swing - bend_b))


static func draw_giant(c: CanvasItem, foot: Vector2, h: float, ph: float, dir: float, pal: Dictionary, detail := 1) -> Dictionary:
	var body: Color = pal.body
	var shade: Color = pal.shade
	var deep: Color = pal.deep
	var line: Color = pal.line
	var slit: Color = pal.slit
	var w := TAU * ph
	var swing := sin(w) * 0.34
	var bend_f := maxf(0.0, -cos(w)) * 0.75 ## 앞으로 나가는 다리가 굽는다
	var bend_b := maxf(0.0, cos(w)) * 0.75
	var thigh := h * 0.26
	var shin := h * 0.26
	var hip := foot + Vector2(0, -hip_height(h, ph))
	var lean := 0.14 + 0.02 * sin(w * 2.0)
	var torso_len := h * 0.26
	var sh := hip + Vector2(sin(lean) * dir, -cos(lean)) * torso_len
	var head := sh + Vector2(dir * h * 0.04, -h * 0.065)
	var hw := h * 0.058 # 엉덩이 반폭
	var sw := h * 0.118 # 어깨 반폭
	var lw := maxf(1.0, h * 0.0035)
	var out := {"hip": hip, "shoulder": sh, "head": head}

	# 머리 뒤의 기하학 고리 (바깥 신의 표식)
	if detail >= 1:
		var hc := head + Vector2(-dir * h * 0.012, -h * 0.004)
		var rr := h * 0.075
		c.draw_arc(hc, rr, 0, TAU, 32, Color(line, line.a * 0.8), lw)
		c.draw_arc(hc, rr * 0.78, 0, TAU, 24, Color(line, line.a * 0.45), lw)
		for i in 8:
			var a := TAU * i / 8.0 + 0.2
			c.draw_line(hc + Vector2(cos(a), sin(a)) * rr * 0.78, hc + Vector2(cos(a), sin(a)) * rr * 1.12, Color(line, line.a * 0.8), lw)

	# 뒷다리·뒷팔 (몸 뒤, 어둡게)
	var lb := _leg(hip + Vector2(-dir * hw * 0.3, 0), -swing, bend_b, thigh, shin, dir)
	_limb(c, hip + Vector2(-dir * hw * 0.3, 0), lb[0], h * 0.046, h * 0.036, deep)
	_limb(c, lb[0], lb[1], h * 0.036, h * 0.022, deep)
	_foot(c, lb[1], h, dir, deep)
	var arm_a := -swing * 0.7 + 0.08
	var sb := sh + Vector2(-dir * sw * 0.6, h * 0.01)
	var eb := sb + Vector2(sin(-arm_a) * dir, cos(-arm_a)) * h * 0.21
	var hb := eb + Vector2(sin(-arm_a + 0.25) * dir, cos(-arm_a + 0.25)) * h * 0.2
	_limb(c, sb, eb, h * 0.032, h * 0.024, deep)
	_limb(c, eb, hb, h * 0.024, h * 0.018, deep)
	_hand(c, hb, h, dir, deep, deep.darkened(0.2))

	# 몸통: 엉덩이 → 허리(잘록) → 가슴 → 어깨
	var up := (sh - hip).normalized()
	var side := Vector2(-up.y, up.x) * dir
	var waist := hip.lerp(sh, 0.38)
	var chest := hip.lerp(sh, 0.78)
	var torso := PackedVector2Array([
		hip - side * hw, waist - side * hw * 0.78, chest - side * sw * 0.86, sh - side * sw,
		sh + up * h * 0.014 - side * sw * 0.4, sh + up * h * 0.014 + side * sw * 0.4,
		sh + side * sw, chest + side * sw * 0.92, waist + side * hw * 0.9, hip + side * hw,
		hip - up * h * 0.03,
	])
	c.draw_colored_polygon(torso, body)
	# 등 쪽 그림자 띠
	c.draw_colored_polygon(PackedVector2Array([
		hip - side * hw, waist - side * hw * 0.78, chest - side * sw * 0.86, sh - side * sw,
		sh - side * sw * 0.5, chest - side * sw * 0.42, waist - side * hw * 0.35, hip - side * hw * 0.45,
	]), shade)
	# 목·머리 (매끈한 알 모양, 세로 틈)
	_limb(c, sh + up * h * 0.005, head + Vector2(0, h * 0.03), h * 0.026, h * 0.024, shade)
	var hr := Vector2(h * 0.032, h * 0.05)
	var hp := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		var stretch := 1.0 + (0.12 if sin(a) < 0.0 else 0.0) # 위가 조금 길쭉
		hp.append(head + Vector2(cos(a) * hr.x, sin(a) * hr.y * stretch))
	c.draw_colored_polygon(hp, body)
	c.draw_colored_polygon(PackedVector2Array([
		head + Vector2(-dir * hr.x, -hr.y * 0.3), head + Vector2(-dir * hr.x * 0.35, -hr.y * 1.05),
		head + Vector2(-dir * hr.x * 0.2, hr.y * 0.9), head + Vector2(-dir * hr.x * 0.9, hr.y * 0.4),
	]), shade)
	var slit_x := head.x + dir * hr.x * 0.4
	var sw2 := maxf(1.0, h * 0.007)
	c.draw_line(Vector2(slit_x, head.y - hr.y * 0.8), Vector2(slit_x, head.y + hr.y * 0.6), Color(0.02, 0.02, 0.05, pal.alpha), sw2)
	if detail >= 1:
		c.draw_line(Vector2(slit_x, head.y - hr.y * 0.45), Vector2(slit_x, head.y + hr.y * 0.3), slit, maxf(1.0, sw2 * 0.4))
	out["slit"] = Vector2(slit_x, head.y)

	# 기하학 금 (이음선)
	if detail >= 1 and h > 50.0:
		c.draw_line(hip.lerp(sh, 0.12), sh + up * h * 0.006, line, lw) # 가슴 한가운데
		var hex_c := hip.lerp(sh, 0.66)
		var hex := PackedVector2Array()
		for i in 7:
			var a := TAU * i / 6.0 + PI / 6.0
			hex.append(hex_c + (side * cos(a) + up * sin(a)) * h * 0.042)
		c.draw_polyline(hex, line, lw)
		c.draw_line(chest - side * sw * 0.8, hex_c - side * h * 0.036, line, lw)
		c.draw_line(chest + side * sw * 0.86, hex_c + side * h * 0.036, line, lw)
		c.draw_line(waist - side * hw * 0.7, waist + side * hw * 0.8, line, lw)
		c.draw_line(hip - side * hw * 0.2 + up * h * 0.03, hip.lerp(sh, 0.12), line, lw)

	# 앞다리
	var lf := _leg(hip + Vector2(dir * hw * 0.3, 0), swing, bend_f, thigh, shin, dir)
	_limb(c, hip + Vector2(dir * hw * 0.3, 0), lf[0], h * 0.05, h * 0.038, body)
	_limb(c, lf[0], lf[1], h * 0.038, h * 0.024, body)
	_limb(c, lf[0] + Vector2(-dir * h * 0.018, 0), lf[1] + Vector2(-dir * h * 0.011, -h * 0.01), h * 0.016, h * 0.011, shade)
	_foot(c, lf[1], h, dir, body)
	if detail >= 1 and h > 50.0:
		c.draw_arc(lf[0], h * 0.028, 0, TAU, 12, line, lw)
		var mid_t: Vector2 = (hip + lf[0]) * 0.5
		c.draw_line(mid_t + Vector2(-dir * h * 0.02, 0), lf[0] + Vector2(dir * h * 0.01, -h * 0.02), line, lw)
		var mid_s: Vector2 = (lf[0] + lf[1]) * 0.5
		c.draw_line(mid_s + Vector2(dir * h * 0.016, -h * 0.03), mid_s + Vector2(-dir * h * 0.01, h * 0.04), line, lw)
	out["foot_front"] = lf[1]
	out["foot_back"] = lb[1]
	out["knee"] = lf[0]

	# 앞팔 (무릎까지 늘어짐) + 어깨 삼각 판
	var sf := sh + Vector2(dir * sw * 0.75, h * 0.015)
	var arm_f := swing * 0.7 + 0.1
	var ef := sf + Vector2(sin(arm_f) * dir, cos(arm_f)) * h * 0.21
	var hf := ef + Vector2(sin(arm_f + 0.28) * dir, cos(arm_f + 0.28)) * h * 0.2
	_limb(c, sf, ef, h * 0.034, h * 0.026, body)
	_limb(c, ef, hf, h * 0.026, h * 0.02, body)
	_limb(c, sf + Vector2(-dir * h * 0.011, h * 0.01), ef + Vector2(-dir * h * 0.011, 0), h * 0.012, h * 0.009, shade)
	_hand(c, hf, h, dir, body, shade)
	var plate := PackedVector2Array([sf + Vector2(-dir * h * 0.04, -h * 0.022), sf + Vector2(dir * h * 0.04, -h * 0.016), sf + Vector2(dir * h * 0.006, h * 0.045)])
	c.draw_colored_polygon(plate, body.lightened(0.04))
	if detail >= 1 and h > 50.0:
		c.draw_arc(ef, h * 0.022, 0, TAU, 10, line, lw)
		c.draw_polyline(plate + PackedVector2Array([plate[0]]), line, lw)
	out["hand"] = hf
	out["elbow"] = ef
	out["shoulder_front"] = sf
	return out


static func _foot(c: CanvasItem, ankle: Vector2, h: float, dir: float, col: Color) -> void:
	var fl := h * 0.058
	c.draw_colored_polygon(PackedVector2Array([
		ankle + Vector2(-dir * fl * 0.35, -h * 0.02), ankle + Vector2(dir * fl * 0.3, -h * 0.022),
		ankle + Vector2(dir * fl, h * 0.012), ankle + Vector2(dir * fl * 0.9, h * 0.02), ankle + Vector2(-dir * fl * 0.45, h * 0.02),
	]), col)


## 손: 길고 가는 손가락 넷이 늘어진다
static func _hand(c: CanvasItem, wrist: Vector2, h: float, dir: float, col: Color, shade: Color) -> void:
	var s := h * 0.03
	c.draw_colored_polygon(PackedVector2Array([
		wrist + Vector2(-s * 0.7, -s * 0.2), wrist + Vector2(s * 0.7, -s * 0.2),
		wrist + Vector2(s * 0.8, s * 1.0), wrist + Vector2(-s * 0.8, s * 1.0),
	]), col)
	for i in 4:
		var fx := (-0.6 + i * 0.4) * s
		var ln := s * (1.9 if i in [1, 2] else 1.5)
		_limb(c, wrist + Vector2(fx, s * 0.9), wrist + Vector2(fx + dir * s * 0.15, s * 0.9 + ln), maxf(s * 0.18, 0.6), maxf(s * 0.12, 0.5), col)
	c.draw_line(wrist + Vector2(-dir * s * 0.7, s * 0.3), wrist + Vector2(-dir * s * 1.2, s * 1.4), shade, maxf(1.0, s * 0.3))


## 내려오는 거대한 손바닥 (손가락을 아래로 편 채). p = 손바닥 아래 끝 중심, s = 손 폭(px), curl = 움켜쥠 0~1
static func draw_slam_hand(c: CanvasItem, p: Vector2, s: float, pal: Dictionary, curl := 0.0) -> void:
	var body: Color = pal.body
	var shade: Color = pal.shade
	var line: Color = pal.line
	var lw := maxf(1.0, s * 0.018)
	# 팔뚝 (화면 위로 이어짐)
	c.draw_colored_polygon(PackedVector2Array([
		p + Vector2(-s * 0.3, -s * 0.9), p + Vector2(s * 0.3, -s * 0.9), p + Vector2(s * 0.4, -s * 5.0), p + Vector2(-s * 0.4, -s * 5.0),
	]), body)
	c.draw_colored_polygon(PackedVector2Array([
		p + Vector2(s * 0.1, -s * 0.9), p + Vector2(s * 0.3, -s * 0.9), p + Vector2(s * 0.4, -s * 5.0), p + Vector2(s * 0.18, -s * 5.0),
	]), shade)
	c.draw_arc(p + Vector2(0, -s * 1.3), s * 0.36, PI * 0.1, PI * 0.9, 10, line, lw)
	# 손바닥
	c.draw_colored_polygon(PackedVector2Array([
		p + Vector2(-s * 0.42, -s * 1.0), p + Vector2(s * 0.42, -s * 1.0), p + Vector2(s * 0.5, -s * 0.35), p + Vector2(-s * 0.5, -s * 0.35),
	]), body)
	# 손가락 (curl = 움켜쥠)
	for i in 5:
		var fx := (-0.44 + i * 0.22) * s
		var ln := s * (0.45 if i in [0, 4] else 0.62) * (1.0 - curl * 0.5)
		var tip := p + Vector2(fx * (1.0 + 0.2 * (1.0 - curl)), -s * 0.35 + ln)
		_limb(c, p + Vector2(fx, -s * 0.38), tip, s * 0.07, s * 0.05, body)
		c.draw_line(p + Vector2(fx, -s * 0.38) + (tip - p - Vector2(fx, -s * 0.38)) * 0.55 + Vector2(-s * 0.05, 0),
			p + Vector2(fx, -s * 0.38) + (tip - p - Vector2(fx, -s * 0.38)) * 0.55 + Vector2(s * 0.05, 0), line, lw)
	c.draw_line(p + Vector2(-s * 0.3, -s * 0.7), p + Vector2(s * 0.3, -s * 0.62), line, lw)
	c.draw_line(p + Vector2(0, -s * 1.0), p + Vector2(0, -s * 4.6), line, lw)


## 2마디 다리 IK: 엉덩이 → 발. 무릎은 bend_dir 쪽(앞)으로 굽는다. 돌려줌: 무릎
static func ik_knee(hip: Vector2, foot: Vector2, l1: float, l2: float, bend_dir: float) -> Vector2:
	var d := foot - hip
	var dist := clampf(d.length(), absf(l1 - l2) + 0.01, (l1 + l2) * 0.999)
	var a := acos(clampf((l1 * l1 + dist * dist - l2 * l2) / (2.0 * l1 * dist), -1.0, 1.0))
	var base := d.angle()
	var k1 := hip + Vector2.from_angle(base + a) * l1
	var k2 := hip + Vector2.from_angle(base - a) * l1
	return k1 if (k1.x - hip.x) * bend_dir > (k2.x - hip.x) * bend_dir else k2


## 발 위치를 직접 받는 거신 (적 colossus·발판 colossus_ride가 씀). 머리·몸통은 화면 위로 넘쳐도 된다.
## arm_f/arm_b: 앞·뒷손의 목표 위치(같은 좌표계). Vector2.INF면 늘어진 팔
static func draw_walker(c: CanvasItem, hip: Vector2, foot_f: Vector2, foot_b: Vector2, h: float, dir: float, pal: Dictionary,
		arm_f := Vector2.INF, arm_b := Vector2.INF, lean := 0.14) -> Dictionary:
	var body: Color = pal.body
	var shade: Color = pal.shade
	var deep: Color = pal.deep
	var line: Color = pal.line
	var slit: Color = pal.slit
	var lw := maxf(1.0, h * 0.0035)
	var thigh := h * 0.26
	var shin := h * 0.26
	var sh := hip + Vector2(sin(lean) * dir, -cos(lean)) * h * 0.26
	var head := sh + Vector2(dir * h * 0.04, -h * 0.065)
	var hw := h * 0.058
	var sw := h * 0.118
	var out := {"hip": hip, "shoulder": sh, "head": head}
	# 머리 뒤 기하학 고리
	var hc := head + Vector2(-dir * h * 0.012, 0)
	c.draw_arc(hc, h * 0.075, 0, TAU, 32, Color(line, line.a * 0.8), lw)
	for i in 8:
		var a := TAU * i / 8.0 + 0.2
		c.draw_line(hc + Vector2.from_angle(a) * h * 0.058, hc + Vector2.from_angle(a) * h * 0.084, Color(line, line.a * 0.8), lw)
	# 뒷다리
	var hb := hip + Vector2(-dir * hw * 0.3, 0)
	var kb := ik_knee(hb, foot_b, thigh, shin, dir)
	_limb(c, hb, kb, h * 0.046, h * 0.036, deep)
	_limb(c, kb, foot_b, h * 0.036, h * 0.022, deep)
	_foot(c, foot_b + Vector2(0, -h * 0.02), h, dir, deep)
	# 뒷팔
	var sb := sh + Vector2(-dir * sw * 0.6, h * 0.01)
	var hand_b := arm_b if arm_b != Vector2.INF else sb + Vector2(dir * h * 0.02, h * 0.4)
	var eb := ik_knee(sb, hand_b, h * 0.21, h * 0.2, -dir)
	_limb(c, sb, eb, h * 0.032, h * 0.024, deep)
	_limb(c, eb, hand_b, h * 0.024, h * 0.018, deep)
	_hand(c, hand_b, h, dir, deep, deep.darkened(0.2))
	# 몸통
	var up := (sh - hip).normalized()
	var side := Vector2(-up.y, up.x) * dir
	var waist := hip.lerp(sh, 0.38)
	var chest := hip.lerp(sh, 0.78)
	var torso := PackedVector2Array([
		hip - side * hw, waist - side * hw * 0.78, chest - side * sw * 0.86, sh - side * sw,
		sh + up * h * 0.014 - side * sw * 0.4, sh + up * h * 0.014 + side * sw * 0.4,
		sh + side * sw, chest + side * sw * 0.92, waist + side * hw * 0.9, hip + side * hw, hip - up * h * 0.03,
	])
	c.draw_colored_polygon(torso, body)
	c.draw_colored_polygon(PackedVector2Array([hip - side * hw, waist - side * hw * 0.78, chest - side * sw * 0.86, sh - side * sw,
		sh - side * sw * 0.5, chest - side * sw * 0.42, waist - side * hw * 0.35, hip - side * hw * 0.45]), shade)
	c.draw_line(hip.lerp(sh, 0.12), sh, line, lw)
	var hex_c := hip.lerp(sh, 0.66)
	var hex := PackedVector2Array()
	for i in 7:
		var a2 := TAU * i / 6.0 + PI / 6.0
		hex.append(hex_c + (side * cos(a2) + up * sin(a2)) * h * 0.042)
	c.draw_polyline(hex, line, lw)
	c.draw_line(waist - side * hw * 0.7, waist + side * hw * 0.8, line, lw)
	# 목·머리
	_limb(c, sh, head + Vector2(0, h * 0.03), h * 0.026, h * 0.024, shade)
	var hp := PackedVector2Array()
	for i in 16:
		var a3 := TAU * i / 16.0
		hp.append(head + Vector2(cos(a3) * h * 0.032, sin(a3) * h * 0.05 * (1.12 if sin(a3) < 0.0 else 1.0)))
	c.draw_colored_polygon(hp, body)
	var slit_x := head.x + dir * h * 0.013
	c.draw_line(Vector2(slit_x, head.y - h * 0.04), Vector2(slit_x, head.y + h * 0.03), Color(0.02, 0.02, 0.05, pal.alpha), maxf(1.0, h * 0.007))
	c.draw_line(Vector2(slit_x, head.y - h * 0.022), Vector2(slit_x, head.y + h * 0.015), slit, maxf(1.0, h * 0.003))
	out["slit"] = Vector2(slit_x, head.y)
	# 앞다리
	var hf := hip + Vector2(dir * hw * 0.3, 0)
	var kf := ik_knee(hf, foot_f, thigh, shin, dir)
	_limb(c, hf, kf, h * 0.05, h * 0.038, body)
	_limb(c, kf, foot_f, h * 0.038, h * 0.024, body)
	_limb(c, kf + Vector2(-dir * h * 0.018, 0), foot_f + Vector2(-dir * h * 0.011, -h * 0.01), h * 0.016, h * 0.011, shade)
	_foot(c, foot_f + Vector2(0, -h * 0.02), h, dir, body)
	c.draw_arc(kf, h * 0.028, 0, TAU, 12, line, lw)
	c.draw_line((hf + kf) * 0.5 + Vector2(-dir * h * 0.02, 0), kf + Vector2(dir * h * 0.01, -h * 0.02), line, lw)
	out["knee_f"] = kf
	out["knee_b"] = kb
	# 앞팔
	var sf := sh + Vector2(dir * sw * 0.75, h * 0.015)
	var hand_f := arm_f if arm_f != Vector2.INF else sf + Vector2(dir * h * 0.06, h * 0.4)
	var ef := ik_knee(sf, hand_f, h * 0.21, h * 0.2, -dir)
	_limb(c, sf, ef, h * 0.034, h * 0.026, body)
	_limb(c, ef, hand_f, h * 0.026, h * 0.02, body)
	_limb(c, sf + Vector2(-dir * h * 0.011, h * 0.01), ef + Vector2(-dir * h * 0.011, 0), h * 0.012, h * 0.009, shade)
	_hand(c, hand_f, h, dir, body, shade)
	var plate := PackedVector2Array([sf + Vector2(-dir * h * 0.04, -h * 0.022), sf + Vector2(dir * h * 0.04, -h * 0.016), sf + Vector2(dir * h * 0.006, h * 0.045)])
	c.draw_colored_polygon(plate, body.lightened(0.04))
	c.draw_polyline(plate + PackedVector2Array([plate[0]]), line, lw)
	c.draw_arc(ef, h * 0.022, 0, TAU, 10, line, lw)
	out["elbow_f"] = ef
	out["hand_f"] = hand_f
	out["shoulder_f"] = sf
	return out
