extends RefCounted
## 3장 엘프 인물 공용 몸 그림 (피오·티엘·마을 엘프·파수꾼). 1장 CharacterVisual과 같은 값(robe·robe2·skin·hair·eye·
## hair_style·height·extra)을 읽고, 엘프다운 것 — 긴 귀(뒤·위로), 잎 모양 옷깃, 나무색 장화 — 을 더한다.
## hair_style: short · long · tied(낮게 묶음) · mop(덥수룩한 아이 머리) · bun
## extra: leafcap(잎 모자) · satchel(가방) · goggles · tools(공구 허리띠) · apron · basket · flower(머리 꽃) · freckles
##        warden(파수꾼: 두건·가리개·잎 방패·잎날 창 — 아래 자세를 씀)
## 자세(v.pose, 파수꾼): idle · run · windup(창을 뒤로 — 창끝 붉은 예고) · attack(찌르기) · guard(잎 방패) · hurt · kneel(물러남)
## 원점 발밑, +x가 바라보는 쪽.

const BOOT := Color("#4a3420")
const LEAF := Color("#3a6a2a")
const LEAF_L := Color("#7ab450")
const WOOD := Color("#6a4a2a")
const METAL := Color("#c8d0c0")


static func draw_body(v: CharacterVisual) -> void:
	var info := v.info
	var t := v.time()
	var h := float(info.get("height", 30))
	var s := h / 32.0
	var robe: Color = info.get("robe", Color("#3a5a2e"))
	var robe2: Color = info.get("robe2", Color("#c8b060"))
	var skin: Color = info.get("skin", Color("#f2dcc8"))
	var hair: Color = info.get("hair", Color("#c8d890"))
	var eye: Color = info.get("eye", Color("#3a8a4a"))
	var extra: Array = info.get("extra", [])
	var warden := "warden" in extra
	var pose := v.pose if v.pose != "" else "idle"
	var pt := v.pose_t
	var walking := v.walking or pose == "run"
	var ph := v.walk_phase()
	var bob := sin(t * 2.2) * 0.5 if not walking else -absf(sin(ph)) * 1.0
	if v.talking:
		bob += sin(t * 14.0) * 0.4
	var crouch := 0.0
	var lean := 0.0
	var tilt := 0.0
	var hand_f := Vector2(4.5 * s, -h * 0.42)
	var hand_b := Vector2(-3.5 * s, -h * 0.42)
	var spear_dir := Vector2(0, -1) # 창 방향 (파수꾼)
	var spear_pull := 0.0
	var shield_up := false
	var eyes_closed := false
	match pose:
		"run":
			lean = 2.0 * s
			hand_f = Vector2(6 * s, -h * 0.45)
			hand_b = Vector2(-4 * s - sin(ph) * 2.0, -h * 0.42)
			spear_dir = Vector2(0.85, -0.5).normalized()
		"windup":
			lean = -1.0
			crouch = 1.5
			var k := clampf(pt / 0.25, 0.0, 1.0)
			hand_f = Vector2(1 * s, -h * 0.5)
			spear_dir = Vector2(1, -0.1).normalized()
			spear_pull = 7.0 * k
			shield_up = true
		"attack":
			lean = 2.5
			crouch = 1.0
			hand_f = Vector2(9 * s, -h * 0.5)
			spear_dir = Vector2(1, 0.05).normalized()
			spear_pull = -4.0
		"guard":
			crouch = 2.0
			lean = 1.0
			shield_up = true
			spear_dir = Vector2(0.3, -1).normalized()
		"hurt":
			lean = -2.0
			tilt = -0.3
			eyes_closed = true
			spear_dir = Vector2(-0.4, -1).normalized()
		"kneel":
			crouch = 6.0 * s
			tilt = 0.35
			eyes_closed = true
			hand_f = Vector2(6 * s, -h * 0.25)
			spear_dir = Vector2(1, 0.05).normalized()
	var top_y := -h + 13 * s + bob + crouch
	var hc := Vector2(1 + lean + tilt * 2.0, -h + 7 * s + bob + crouch)
	var head_r := 6.0 * s

	# 윤곽 빛
	v.draw_circle(Vector2(0, -h * 0.55), h * 0.5, Color(robe2, 0.05))
	# 파수꾼: 등의 잎 망토
	if warden:
		var sw := sin(t * 2.4) * 0.6 - (1.5 if walking else 0.0)
		v.draw_colored_polygon(PackedVector2Array([Vector2(-1 + lean, top_y - 1), Vector2(-6 * s + sw, -4 * s), Vector2(-2 * s + sw, -2 * s), Vector2(2 * s, -6 * s), Vector2(3 + lean, top_y)]), robe.darkened(0.3))
	# 다리
	var leg := sin(ph) * 2.5 if walking else 0.0
	var leg_y := -5 * s
	if pose == "kneel":
		v.draw_line(Vector2(-1, -5 * s + crouch * 0.5), Vector2(-5 * s, -1), Color("#2a2418"), 2.0)
		v.draw_line(Vector2(1, -5 * s + crouch * 0.5), Vector2(4 * s, -4 * s), Color("#2a2418"), 2.0)
		v.draw_line(Vector2(4 * s, -4 * s), Vector2(4 * s, 0), BOOT, 2.0)
	else:
		v.draw_rect(Rect2(-3 + leg, leg_y + crouch * 0.3, 2, -leg_y - crouch * 0.3), Color("#2a2418"))
		v.draw_rect(Rect2(1 - leg, leg_y + crouch * 0.3, 2, -leg_y - crouch * 0.3), Color("#2a2418"))
		v.draw_rect(Rect2(-3.5 + leg, -2, 3, 2), BOOT)
		v.draw_rect(Rect2(0.5 - leg, -2, 3, 2), BOOT)
	# 뒷팔
	v.draw_line(Vector2(-3 * s + lean, top_y + 2), hand_b + Vector2(lean, crouch), robe.darkened(0.15), 2.0)
	# 몸 (짧은 튜닉, 잎 모양 아랫단)
	var hem := -4 * s + crouch * 0.7
	var body := PackedVector2Array([Vector2(-3.5 * s + lean, top_y), Vector2(4 * s + lean, top_y), Vector2(5.5 * s, hem), Vector2(-5.5 * s, hem)])
	v.draw_colored_polygon(body, robe)
	for i in 4:
		var x := -5.0 * s + i * 3.4 * s
		v.draw_colored_polygon(PackedVector2Array([Vector2(x, hem - 0.5), Vector2(x + 1.7 * s, hem + 2.0 * s), Vector2(x + 3.4 * s, hem - 0.5)]), robe.darkened(0.12))
	v.draw_line(Vector2(0.5 + lean, top_y + 1), Vector2(0.5, hem), robe.lightened(0.12), 1.0)
	# 허리띠
	var belt_y := top_y + (h - 13 * s) * 0.45
	v.draw_line(Vector2(-4.5 * s, belt_y), Vector2(5 * s, belt_y), Color("#4a3420"), 2.0)
	v.draw_rect(Rect2(0, belt_y - 1, 2, 2), robe2)
	if "apron" in extra:
		v.draw_rect(Rect2(-2.5 * s, top_y + 4 * s, 6 * s, hem - top_y - 4 * s), Color("#c8b890"))
	if "tools" in extra:
		v.draw_rect(Rect2(2 * s, belt_y, 2, 4), METAL)
		v.draw_rect(Rect2(-4 * s, belt_y, 2, 3), Color("#b08a4a"))
		v.draw_line(Vector2(4 * s, belt_y), Vector2(5 * s, belt_y + 5), METAL, 1.0)
	if "satchel" in extra:
		v.draw_line(Vector2(3 * s + lean, top_y), Vector2(-3 * s, belt_y + 2), Color("#8a5a2a"), 1.0)
		v.draw_rect(Rect2(-6 * s, belt_y, 4 * s, 4 * s), Color("#8a5a2a"))
		v.draw_rect(Rect2(-6 * s, belt_y, 4 * s, 1), Color("#a87a4a"))
	# 잎 모양 옷깃
	v.draw_colored_polygon(PackedVector2Array([Vector2(-3.5 * s + lean, top_y), Vector2(0.5 + lean, top_y + 3 * s), Vector2(4 * s + lean, top_y), Vector2(0.5 + lean, top_y - 1)]), robe2)
	# 파수꾼 방패 (뒷손, 잎 모양)
	if warden and not shield_up:
		_leaf_shield(v, Vector2(-5 * s + lean, top_y + 6 * s), 0.0, s)
	# 머리
	_head(v, t, hc, head_r, s, hair, skin, eye, info, extra, eyes_closed, pose)
	# 앞팔 + 창
	var sh := Vector2(3 * s + lean, top_y + 2)
	var hf := hand_f + Vector2(lean, crouch)
	if warden:
		_spear(v, t, hf - spear_dir * spear_pull, spear_dir, s, pose, pt)
	v.draw_line(sh, hf - spear_dir * spear_pull * 0.6, robe.lightened(0.08), 2.0)
	v.draw_circle(hf - spear_dir * spear_pull * 0.6, 1.2, skin)
	if "basket" in extra:
		v.draw_rect(Rect2(hf.x - 3, hf.y, 6, 4), Color("#a8844a"))
		v.draw_circle(hf + Vector2(-1, 0), 1.2, Color("#d8603a"))
		v.draw_circle(hf + Vector2(1.5, -0.5), 1.2, Color("#c8ff7a"))
	if warden and shield_up:
		_leaf_shield(v, Vector2(6 * s + lean, top_y + 6 * s), 0.0, s * 1.1)


static func _head(v: CharacterVisual, t: float, hc: Vector2, r: float, s: float, hair: Color, skin: Color, eye: Color, info: Dictionary, extra: Array, closed: bool, pose: String) -> void:
	var style := String(info.get("hair_style", "short"))
	var warden := "warden" in extra
	# 뒷머리
	match style:
		"long":
			v.draw_colored_polygon(PackedVector2Array([hc + Vector2(-6 * s, -2 * s), hc + Vector2(4 * s, -3 * s), hc + Vector2(2 * s, 12 * s), hc + Vector2(-7 * s, 13 * s)]), hair.darkened(0.15))
		"tied":
			var sw := sin(t * 2.0) * 0.8
			v.draw_colored_polygon(PackedVector2Array([hc + Vector2(-5 * s, 2 * s), hc + Vector2(-8 * s + sw, 9 * s), hc + Vector2(-6 * s + sw, 13 * s), hc + Vector2(-3 * s, 4 * s)]), hair.darkened(0.15))
		"bun":
			v.draw_circle(hc + Vector2(-3 * s, -5 * s), 3.0 * s, hair.darkened(0.1))
		"mop":
			for i in 5:
				v.draw_circle(hc + Vector2(-4 * s + i * 2.0 * s, -4.5 * s + (i % 2) * 1.0), 2.6 * s, hair.darkened(0.1))
	# 긴 귀 (뒤·위로)
	var ear_droop := 1.5 * s if pose in ["kneel", "hurt"] else 0.0
	var etip := hc + Vector2(-9.5 * s, -5.5 * s + ear_droop + sin(t * 0.7) * 0.3)
	v.draw_colored_polygon(PackedVector2Array([hc + Vector2(-2 * s, -1.5 * s), etip, hc + Vector2(-1.5 * s, 2 * s)]), skin)
	v.draw_line(hc + Vector2(-2.5 * s, 0.2), etip + Vector2(2 * s, 1.5 * s), skin.darkened(0.2), 1.0)
	# 얼굴
	v.draw_circle(hc, r, skin)
	if "freckles" in extra:
		v.draw_rect(Rect2(hc.x + 1.5 * s, hc.y + 2 * s, 1, 1), skin.darkened(0.25))
		v.draw_rect(Rect2(hc.x + 3.5 * s, hc.y + 2 * s, 1, 1), skin.darkened(0.25))
	# 눈
	if v.blinking() or closed:
		v.draw_line(hc + Vector2(2 * s, 1 * s), hc + Vector2(4 * s, 1 * s), Color("#2a1a14"), 1.0)
	else:
		v.draw_rect(Rect2(hc.x + 2.5 * s, hc.y - 0.5 * s, 1.5, 2.5), eye)
		v.draw_rect(Rect2(hc.x + 2.5 * s, hc.y - 0.5 * s, 1, 1), Color(1, 1, 1, 0.8))
	if v.talking and int(t * 10.0) % 2 == 0:
		v.draw_rect(Rect2(hc.x + 3 * s, hc.y + 3 * s, 2, 1), Color("#8a3a3a"))
	if warden:
		# 두건이 머리 전체를 덮고 눈가만 트임, 아래 얼굴은 가리개. 긴 귀는 두건 옆 틈으로 나온다
		var hood_c := Color("#2e4a24")
		v.draw_circle(hc + Vector2(-0.5 * s, -0.5 * s), r + 1.0 * s, hood_c)
		v.draw_colored_polygon(PackedVector2Array([hc + Vector2(-6.5 * s, -2 * s), hc + Vector2(-8 * s, 5 * s), hc + Vector2(-3 * s, 6 * s)]), hood_c.darkened(0.15))
		v.draw_rect(Rect2(hc.x + 0.5 * s, hc.y - 2.0 * s, 5.5 * s, 3.2 * s), skin)
		if v.blinking() or closed:
			v.draw_line(hc + Vector2(2 * s, -0.5 * s), hc + Vector2(4.5 * s, -0.5 * s), Color("#2a1a14"), 1.0)
		else:
			v.draw_rect(Rect2(hc.x + 2.5 * s, hc.y - 1.5 * s, 1.5, 2.0), eye)
			v.draw_rect(Rect2(hc.x + 2.5 * s, hc.y - 1.5 * s, 1, 1), Color(1, 1, 1, 0.8))
		v.draw_colored_polygon(PackedVector2Array([hc + Vector2(0.5 * s, 1.2 * s), hc + Vector2(6.5 * s, 1.0 * s), hc + Vector2(5 * s, 5 * s), hc + Vector2(0, 5.5 * s)]), Color("#5a6a4a"))
		v.draw_line(hc + Vector2(-4 * s, -5.5 * s), hc + Vector2(3 * s, -6.5 * s), Color("#4a6e36"), 1.0)
		v.draw_colored_polygon(PackedVector2Array([etip, hc + Vector2(-3.5 * s, -2.5 * s), hc + Vector2(-3 * s, 0.5 * s)]), skin)
		return
	# 앞머리
	var bangs := PackedVector2Array([hc + Vector2(-6.5 * s, 0), hc + Vector2(-5 * s, -5.5 * s), hc + Vector2(1 * s, -7 * s),
		hc + Vector2(6.5 * s, -3 * s), hc + Vector2(6 * s, 0), hc + Vector2(3 * s, -2.5 * s), hc + Vector2(-1 * s, -1.5 * s)])
	v.draw_colored_polygon(bangs, hair)
	v.draw_line(hc + Vector2(-5 * s, -5 * s), hc + Vector2(1 * s, -6.5 * s), hair.lightened(0.3), 1.0)
	if style == "mop":
		for i in 3:
			v.draw_line(hc + Vector2(-2 * s + i * 2.5 * s, -6 * s), hc + Vector2(-1 * s + i * 2.5 * s + sin(t * 2.0 + i) * 0.5, -8.5 * s), hair, 1.0)
	if "leafcap" in extra:
		# 큰 잎 모자 (아이가 쓰기엔 큰)
		var sway := sin(t * 1.6) * 0.8
		v.draw_colored_polygon(PackedVector2Array([hc + Vector2(-8 * s, -3.5 * s), hc + Vector2(-3 * s, -9 * s), hc + Vector2(4 * s, -9.5 * s + sway), hc + Vector2(9 * s, -4 * s + sway), hc + Vector2(2 * s, -5 * s)]), LEAF)
		v.draw_line(hc + Vector2(-7 * s, -4 * s), hc + Vector2(8 * s, -4.5 * s + sway), LEAF_L, 1.0)
		v.draw_line(hc + Vector2(-2 * s, -8.5 * s), hc + Vector2(-3 * s, -11 * s), Color("#5a3a20"), 1.0)
	if "goggles" in extra:
		v.draw_rect(Rect2(hc.x - 6 * s, hc.y - 5 * s, 12 * s, 2.5 * s), Color("#6a4a2a"))
		v.draw_circle(hc + Vector2(2 * s, -4 * s), 2.2 * s, Color("#c8e0a0"))
		v.draw_circle(hc + Vector2(1.5 * s, -4.5 * s), 0.8 * s, Color.WHITE)
	if "flower" in extra:
		var fc := hc + Vector2(-4 * s, -5 * s)
		for i in 5:
			var a := TAU * i / 5.0 + t * 0.2
			v.draw_circle(fc + Vector2(cos(a), sin(a)) * 1.5 * s, 1.0 * s, Color("#f0e0f8"))
		v.draw_circle(fc, 0.8 * s, Color("#ffe08a"))


static func _leaf_shield(v: CharacterVisual, c: Vector2, ang: float, s: float) -> void:
	# 커다란 잎 방패 (잎맥이 보이는 단단한 잎)
	var d := Vector2(sin(ang), -cos(ang))
	var n := Vector2(-d.y, d.x)
	var len := 15.0 * s
	var wid := 5.5 * s
	var pts := PackedVector2Array([c - d * len * 0.5, c - d * len * 0.15 + n * wid, c + d * len * 0.3 + n * wid * 0.7, c + d * len * 0.55, c + d * len * 0.3 - n * wid * 0.7, c - d * len * 0.15 - n * wid])
	v.draw_colored_polygon(pts, Color("#2e5a26"))
	v.draw_colored_polygon(PackedVector2Array([c - d * len * 0.45, c - d * len * 0.15 + n * wid * 0.8, c + d * len * 0.3 + n * wid * 0.55, c + d * len * 0.5]), Color("#4a8236"))
	v.draw_line(c - d * len * 0.5, c + d * len * 0.55, Color("#a8c878"), 1.0)
	for i in 3:
		var q := c - d * len * (0.25 - i * 0.22)
		v.draw_line(q, q + n * wid * 0.7 + d * 2.0, Color("#8ab060"), 1.0)
		v.draw_line(q, q - n * wid * 0.7 + d * 2.0, Color("#6a9a4a"), 1.0)
	v.draw_rect(Rect2(c.x - 1, c.y - 1, 2, 2), Color("#c8a040"))


static func _spear(v: CharacterVisual, t: float, hand: Vector2, d: Vector2, s: float, pose: String, pt: float) -> void:
	# 잎날 창: 나무 자루 + 잎 모양 날. 찌르기 예고(windup) 동안 창끝이 붉게 번쩍인다
	var back := hand - d * 10.0 * s
	var tip := hand + d * 16.0 * s
	v.draw_line(back, tip, WOOD, 1.5)
	v.draw_line(back, tip, WOOD.lightened(0.2), 1.0)
	var n := Vector2(-d.y, d.x)
	var blade := PackedVector2Array([tip - d * 1.0, tip + d * 3.0 + n * 2.0 * s, tip + d * 7.0 * s, tip + d * 3.0 - n * 2.0 * s])
	v.draw_colored_polygon(blade, METAL)
	v.draw_line(tip, tip + d * 6.5 * s, Color.WHITE, 1.0)
	v.draw_line(tip - d * 0.5 + n * 1.5, tip - d * 0.5 - n * 1.5, Color("#c8a040"), 1.0)
	if pose == "windup":
		var k := clampf(pt / 0.3, 0.0, 1.0)
		var flick := 0.6 + 0.4 * sin(t * 40.0)
		v.draw_circle(tip + d * 6.0 * s, 3.0 + 2.0 * k, Color(Palette.DANGER, 0.35 * k * flick))
		v.draw_rect(Rect2(tip.x + d.x * 6.0 * s - 1, tip.y + d.y * 6.0 * s - 1, 2, 2), Color(1.0, 0.6, 0.5, k))
