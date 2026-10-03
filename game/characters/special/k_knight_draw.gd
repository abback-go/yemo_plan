extends RefCounted
## 은사자 기사 몸 그림 (부단장 카엘 + 일반 기사). CharacterVisual이 draw_body(v)를 부른다.
## info 키: helm(true면 깃털 달린 투구), weapon(spear·sword), hair·skin·eye, height.
## 은 판금(3단 명암) 위에 진홍 겉옷과 은사자 문장. 자세: idle · walk(v.walking) · attack(찌르기·내려베기) · guard · kneel · happy(만세)
## 카엘처럼 투구가 없으면 말할 때 손짓이 크다(수다스러움).

const KArt := preload("res://world/entities/ch2/k_art.gd")
const OUT := Color("#07060c")
const ARMOR := Color("#9aa1b4")
const ARMOR_L := Color("#dfe3ec")
const ARMOR_D := Color("#545a70")
const TABARD := Color("#9a1e2a")
const TABARD_D := Color("#5c0e18")
const UNDER := Color("#22263a")
const WOOD := Color("#6a4a30")
const PLUME := Color("#c8303a")


static func _seg(v: CanvasItem, a: Vector2, b: Vector2, w: float, col: Color) -> void:
	v.draw_line(a, b, OUT, w + 2.0)
	v.draw_line(a, b, col, w)


static func draw_body(v: CharacterVisual) -> void:
	var info := v.info
	var h := float(info.get("height", 37))
	var s := h / 37.0
	var t := v.time()
	var pose := v.pose
	var helm := bool(info.get("helm", true))
	var weapon := String(info.get("weapon", "spear"))
	var skin: Color = info.get("skin", Color("#eecab0"))
	var hair: Color = info.get("hair", Color("#4a3a2a"))
	var eye: Color = info.get("eye", Color("#3a3a4a"))
	var pt := v.pose_t
	var bob := sin(t * 2.2) * 0.4
	var lean := 0.0
	var leg := 0.0
	var crouch := 0.0
	var arm_f := Vector2(4, -14) # 앞손 (발밑 기준)
	var arm_b := Vector2(-4, -14)
	var w_ang := -PI * 0.5 # 무기 방향 (창: 위로 세움)
	var w_at := arm_f
	if v.walking:
		leg = sin(v.walk_phase()) * 3.0
		bob = -absf(sin(v.walk_phase())) * 1.0
	if v.talking and not helm:
		arm_b = Vector2(-2 + sin(t * 7.0) * 2.0, -20 + sin(t * 9.0) * 2.0) # 손짓
	match pose:
		"attack":
			var k := clampf(pt / 0.08, 0.0, 1.0)
			lean = 0.2 * k
			arm_f = Vector2(4, -14).lerp(Vector2(11, -17), k)
			w_ang = lerpf(-PI * 0.5, 0.0, k) if weapon == "spear" else lerpf(-2.4, 0.4, k)
		"guard":
			crouch = 2.0
			arm_f = Vector2(6, -18)
			w_ang = -1.2
		"kneel":
			crouch = 7.0
			arm_f = Vector2(6, -11)
			w_ang = -PI * 0.5
		"happy":
			arm_f = Vector2(5, -30)
			arm_b = Vector2(-4, -29)
			bob = -absf(sin(t * 8.0)) * 2.0
	var hip := Vector2(0, -15 * s + crouch + bob)
	var chest := hip + Vector2(sin(lean) * 12.0 * s, -12.0 * s)
	var head := chest + Vector2(1.0 + sin(lean) * 3.0, -6.0 * s)
	w_at = arm_f + Vector2(0, crouch + bob)
	arm_b += Vector2(0, crouch + bob)

	v.draw_circle(chest, h * 0.45, Color(TABARD, 0.05))
	# 망토 자락 (짧은 진홍)
	var cf := sin(t * 2.0) * 1.0
	KArt.poly(v, PackedVector2Array([chest + Vector2(-4, 0), chest + Vector2(1, 0), hip + Vector2(-3 + cf, 9), hip + Vector2(-8 + cf, 8)]), TABARD_D)
	# 뒷팔
	_seg(v, chest + Vector2(-2.5, 1), arm_b, 2.4, ARMOR_D)
	# 다리
	var kneel := pose == "kneel"
	var foot_b := Vector2(-3 - leg, 0) if not kneel else Vector2(-7, 0)
	var foot_f := Vector2(3 + leg, 0) if not kneel else Vector2(5, 0)
	var knee_b := (hip + foot_b) * 0.5 + Vector2(1, 0) if not kneel else Vector2(-2, -1)
	var knee_f := (hip + foot_f) * 0.5 + Vector2(1.5, 0) if not kneel else Vector2(6, -7)
	_seg(v, hip + Vector2(-1.5, 0), knee_b, 2.8, UNDER.darkened(0.2))
	_seg(v, knee_b, foot_b + Vector2(0, -1), 2.6, ARMOR_D)
	v.draw_rect(Rect2(foot_b + Vector2(-1.5, -2), Vector2(4, 2)), ARMOR_D.darkened(0.2))
	# 몸통: 사슬 갑옷 + 흉갑 + 진홍 겉옷(문장)
	var torso := PackedVector2Array([hip + Vector2(-4.5, 2), hip + Vector2(4.5, 2), chest + Vector2(4.5, 0), chest + Vector2(-4, 0)])
	KArt.poly(v, PackedVector2Array([torso[0] + Vector2(-1, 1), torso[1] + Vector2(1, 1), torso[2] + Vector2(1, -1), torso[3] + Vector2(-1, -1)]), OUT)
	KArt.poly(v, torso, ARMOR)
	KArt.poly(v, PackedVector2Array([hip + Vector2(-4.5, 2), hip + Vector2(-1, 2), chest + Vector2(-1, 0), chest + Vector2(-4, 0)]), ARMOR_D)
	var tab := PackedVector2Array([hip + Vector2(-2.5, 5), hip + Vector2(3.5, 5), chest + Vector2(3, 3), chest + Vector2(-2, 3)])
	KArt.poly(v, tab, TABARD)
	v.draw_line(hip + Vector2(3.5, 5), chest + Vector2(3, 3), TABARD.lightened(0.2), 1.0)
	v.draw_circle((hip + chest) * 0.5 + Vector2(0.5, 1), 1.6, ARMOR_L) # 은사자
	v.draw_line(hip + Vector2(-4.5, 1.5), hip + Vector2(4.5, 1.5), Color("#4a2c20"), 1.5)
	# 앞다리
	_seg(v, hip + Vector2(1.5, 0), knee_f, 2.8, UNDER)
	_seg(v, knee_f, foot_f + Vector2(0, -1), 2.6, ARMOR)
	v.draw_rect(Rect2(foot_f + Vector2(-1.5, -2), Vector2(4.5, 2)), ARMOR_D)
	# 머리
	if helm:
		var hr := Rect2(head + Vector2(-4, -5), Vector2(8.5, 9))
		v.draw_rect(hr.grow(1.0), OUT)
		v.draw_rect(hr, ARMOR)
		v.draw_rect(Rect2(hr.position, Vector2(8.5, 2)), ARMOR_L)
		v.draw_rect(Rect2(hr.position + Vector2(0, 7), Vector2(8.5, 2)), ARMOR_D)
		v.draw_rect(Rect2(head + Vector2(0.5, -1.5), Vector2(4, 1.4)), Color("#101018"))
		var sw := sin(t * 3.0) * 1.2
		v.draw_polyline(PackedVector2Array([head + Vector2(0, -5), head + Vector2(-3, -9), head + Vector2(-8, -9 + sw), head + Vector2(-11, -6 + sw)]), OUT, 4.0)
		v.draw_polyline(PackedVector2Array([head + Vector2(0, -5), head + Vector2(-3, -9), head + Vector2(-8, -9 + sw), head + Vector2(-11, -6 + sw)]), PLUME, 2.4)
	else:
		v.draw_line(head + Vector2(0, 3), head + Vector2(0, 6), skin.darkened(0.15), 2.0)
		v.draw_circle(head, 4.6, OUT)
		v.draw_circle(head, 4.0, skin)
		# 부스스한 머리 (뾰족뾰족)
		var hp := PackedVector2Array([head + Vector2(-5, 1), head + Vector2(-5.5, -3), head + Vector2(-3, -6.5), head + Vector2(-1, -5),
			head + Vector2(1, -7), head + Vector2(3, -5), head + Vector2(5, -5.5), head + Vector2(4.5, -2), head + Vector2(2, -3), head + Vector2(-2, -2), head + Vector2(-3.5, 0)])
		KArt.poly(v, hp, hair)
		v.draw_line(head + Vector2(-3, -5), head + Vector2(1, -6), hair.lightened(0.3), 1.0)
		if v.blinking():
			v.draw_line(head + Vector2(1.5, 0), head + Vector2(3.5, 0), Color("#2a1a1a"), 1.0)
		else:
			v.draw_rect(Rect2(head.x + 1.8, head.y - 1.0, 1.5, 2.2), eye)
		v.draw_rect(Rect2(head.x + 0.5, head.y + 1.2, 1, 1), Color(0.8, 0.45, 0.35, 0.5)) # 주근깨
		if v.talking and int(t * 10.0) % 2 == 0:
			v.draw_rect(Rect2(head.x + 2, head.y + 2.4, 2, 1), Color("#8a3a3a"))
	# 어깨갑
	v.draw_circle(chest + Vector2(2, 1), 3.2, OUT)
	v.draw_circle(chest + Vector2(2, 1), 2.6, ARMOR)
	v.draw_line(chest + Vector2(0, 0), chest + Vector2(4, 0), ARMOR_L, 1.0)
	# 무기 + 앞팔
	var dir := Vector2.from_angle(w_ang)
	if weapon == "spear":
		var butt := w_at - dir * 10.0
		var tip := w_at + dir * 20.0
		v.draw_line(butt, tip, OUT, 3.0)
		v.draw_line(butt, tip, WOOD, 1.4)
		KArt.poly(v, PackedVector2Array([tip + dir.orthogonal() * 2.0, tip + dir * 6.0, tip - dir.orthogonal() * 2.0]), ARMOR_L)
		v.draw_line(tip, tip - dir * 1.5 + dir.orthogonal() * 3.0, TABARD, 1.0) # 창 깃발 술
	else:
		var stip := w_at + dir * 16.0
		v.draw_line(w_at, stip, OUT, 3.4)
		v.draw_line(w_at, stip, ARMOR_L, 1.6)
		var side := dir.orthogonal()
		v.draw_line(w_at - side * 2.5, w_at + side * 2.5, Color("#c8a040"), 1.4)
	_seg(v, chest + Vector2(2, 1), w_at, 2.6, ARMOR)
	v.draw_rect(Rect2(w_at - Vector2(1.4, 1.4), Vector2(2.8, 2.8)), ARMOR_D)
