extends "res://characters/special/elarien_palette.gd"
## 엘라리엔 전용 몸 그림 (docs/archive/sera/bible/characters.md 3절 · art.md 3절) — 키 36px, 일반 인물보다 세부 2배.
## 낮게 묶은 긴 연금빛-초록 머리(가닥 셋이 따로 흔들림), 긴 귀, 초록 눈, 주근깨, 잎새 무늬 두건 망토(잎 모양 밑단이 물결),
## 붕대 감은 손가락, 키만 한 흰 장궁(금 잎 장식, 빛 반사 점이 지나감), 흰 깃 화살통.
## 3단 명암(바탕·그림자·빛), 숨쉬기 1px, 눈 깜빡임, 대기 동작 2종(활을 고쳐 잡기 / 머리카락을 귀 뒤로 넘기기).
##
## 자세(v.pose): idle · walk(걷기) · run · aim(끝까지 당김 — 오래 당길수록 화살 끝에 바람이 모인다) · attack(놓기)
##   attack2(세 발 부채) · windup(화살통에서 화살 뽑기) · guard(낮게 웅크려 활로 막기) · hurt · kneel · down(누움)
##   special(하늘로 겨눔 — 화살비) · charge(바람 화살) · leap(가지 사이 도약) · cast(= special)
## 조준 각도: v.set_meta("aim_ang", 라디안) — 0 = 앞, 음수 = 위. 보스·동료가 정한다.
## 원점 발밑, +x가 바라보는 쪽 (부모가 scale.x로 뒤집음).

const HAIR_HI := Color("#f4fcd2")
const SKIN_SH := Color("#d4ad96")
const FRECKLE := Color("#c48e70")
const CLOAK := Color("#2f5230")
const CLOAK_SH := Color("#1b3320")
const CLOAK_HI := Color("#74a052")
const LEAF_PAT := Color("#5e8f44")
const TRIM := Color("#a8924c")
const TUNIC_SH := Color("#99946f")
const LEATHER_SH := Color("#43301b")
const LEGS := Color("#37321f")
const BOOT := Color("#5a3d22")
const BOOT_HI := Color("#7d5a36")
const BOW_HI := Color("#ffffff")
const SHAFT := Color("#c8a878")
const FLETCH := Color("#ffffff")
const TIP := Color("#c8d4dc")
const WIND := Color(0.86, 1.0, 0.82)
const BOW_HALF := 17.5


static func draw_body(v: CharacterVisual) -> void:
	var t := v.time()
	var pose := v.pose
	if pose == "" or pose == "cast":
		pose = "special" if v.pose == "cast" else "idle"
	if pose == "idle" and v.walking:
		pose = "walk"
	if pose == "down":
		_draw_down(v, t)
		return
	var pt := v.pose_t
	var aim: float = v.get_meta("aim_ang", 0.0)
	# ── 자세별 뼈대 ──
	var crouch := 0.0 # 엉덩이를 낮춤(+)
	var lean := 0.0 # 윗몸을 앞으로(+)
	var head_tilt := 0.0 # +면 숙임
	var stream := 0.0 # 바람에 날림(+ 뒤로, - 위·앞으로 들림)
	var hand_f := Vector2(10, -17.5)
	var hand_b := Vector2(-3, -15)
	var foot_f := Vector2(2.5, 0)
	var foot_b := Vector2(-2.5, 0)
	var knee_f := Vector2(2.5, -6)
	var knee_b := Vector2(-2.5, -6)
	var bow_dir := Vector2(1, 0) # 활이 겨누는 쪽 (활의 축은 이에 수직)
	var bow_bend := 2.0 # 활 휨 (당기면 커짐)
	var bow_grip := Vector2.INF # 활 손잡이 위치 (INF면 앞손)
	var pull := Vector2.INF # 시위를 당긴 점 (INF면 시위가 곧음)
	var arrows := 0 # 시위에 건 화살 수
	var arrow_glow := 0.0 # 바람 화살 빛
	var wind_gather := 0.0 # 화살 끝에 모이는 바람
	var string_twang := 0.0
	var eyes := "open" # open · closed · squint · sharp
	var mouth := "none"
	var breath := sin(t * 2.2) * 0.5
	var fidget := ""
	var held_arrow := false # 뒤손에 화살을 쥠 (windup)
	match pose:
		"idle":
			# 대기 동작: 7초마다 번갈아 — 활 고쳐 잡기 / 머리카락 넘기기
			var cyc := fmod(t, 7.0)
			var which := int(t / 7.0) % 2
			if cyc > 5.6 and cyc < 6.7:
				var k := sin((cyc - 5.6) / 1.1 * PI)
				if which == 0:
					fidget = "regrip"
					hand_f += Vector2(0.5, -2.0) * k
					hand_b = hand_b.lerp(Vector2(3, -24), k)
				else:
					fidget = "tuck"
					hand_b = hand_b.lerp(Vector2(-1, -31), k)
					head_tilt = -0.1 * k
		"walk":
			var ph := v.walk_phase() * 0.8
			foot_f = Vector2(sin(ph) * 3.0, -maxf(cos(ph), 0.0) * 1.2)
			foot_b = Vector2(-sin(ph) * 3.0, -maxf(-cos(ph), 0.0) * 1.2)
			knee_f = Vector2(foot_f.x * 0.5 + 0.8, -6)
			knee_b = Vector2(foot_b.x * 0.5 + 0.8, -6)
			hand_b = Vector2(-3 - sin(ph) * 1.5, -15)
			breath = -absf(sin(ph)) * 0.6
			stream = 0.25
		"run":
			var ph2 := v.walk_phase()
			lean = 2.5
			crouch = 1.0
			foot_f = Vector2(sin(ph2) * 5.5, -maxf(cos(ph2), 0.0) * 3.0)
			foot_b = Vector2(-sin(ph2) * 5.5, -maxf(-cos(ph2), 0.0) * 3.0)
			knee_f = Vector2(foot_f.x * 0.4 + 2.5, -6.5 + maxf(cos(ph2), 0.0) * -1.5)
			knee_b = Vector2(foot_b.x * 0.4 + 2.5, -6.5 + maxf(-cos(ph2), 0.0) * -1.5)
			hand_f = Vector2(9, -17)
			hand_b = Vector2(-4 - sin(ph2) * 2.5, -17)
			bow_dir = Vector2(0.95, 0.32).normalized()
			breath = -absf(sin(ph2)) * 0.8
			stream = 1.0
		"aim", "attack2", "special", "charge":
			if pose == "special":
				aim = -1.05
			var draw := clampf(pt / 0.35, 0.0, 1.0)
			lean = -0.5
			crouch = 0.6
			foot_f = Vector2(4.5, 0)
			foot_b = Vector2(-3.5, 0)
			knee_f = Vector2(4.0, -6)
			knee_b = Vector2(-2.5, -6.2)
			bow_dir = Vector2(cos(aim), sin(aim))
			hand_f = Vector2(1.5, -27.0) + bow_dir * 9.5
			pull = hand_f - bow_dir * (6.0 + 8.5 * draw)
			hand_b = pull
			bow_bend = 2.0 + 4.0 * draw
			arrows = 3 if pose == "attack2" else 1
			eyes = "sharp"
			wind_gather = clampf((pt - 0.5) / 1.2, 0.0, 1.0)
			stream = -0.3 * wind_gather
			if pose == "charge":
				arrow_glow = draw
				stream = -0.8
			elif pose == "special":
				stream = -0.4
				head_tilt = -0.25
		"attack":
			var k2 := clampf(pt / 0.25, 0.0, 1.0)
			lean = -0.5 + k2 * 0.5
			crouch = 0.6
			foot_f = Vector2(4.5, 0)
			foot_b = Vector2(-3.5, 0)
			knee_f = Vector2(4.0, -6)
			knee_b = Vector2(-2.5, -6.2)
			bow_dir = Vector2(cos(aim), sin(aim))
			hand_f = Vector2(1.5, -27.0) + bow_dir * 9.5
			hand_b = Vector2(-4.5, -29.5) - bow_dir * 1.5 * (1.0 - k2)
			string_twang = clampf(1.0 - pt / 0.3, 0.0, 1.0)
			eyes = "sharp"
			stream = 0.4 * (1.0 - k2)
		"windup":
			lean = 0.5
			hand_f = Vector2(6, -15)
			var k3 := clampf(pt / 0.3, 0.0, 1.0)
			hand_b = Vector2(-3, -15).lerp(Vector2(-2, -36), k3)
			held_arrow = k3 > 0.6
			bow_dir = Vector2(0.95, 0.3).normalized()
			eyes = "sharp"
		"guard":
			crouch = 4.0
			lean = 1.5
			foot_f = Vector2(5, 0)
			foot_b = Vector2(-5, 0)
			knee_f = Vector2(6, -5)
			knee_b = Vector2(-3, -4)
			hand_f = Vector2(8, -18)
			hand_b = Vector2(3, -17)
			bow_dir = Vector2(0, -1)
			eyes = "sharp"
			stream = -0.2
		"hurt":
			lean = -2.5
			crouch = 1.0
			head_tilt = -0.35
			foot_f = Vector2(3.5, 0)
			foot_b = Vector2(-2.5, 0)
			knee_f = Vector2(4, -6)
			knee_b = Vector2(-2, -6)
			hand_f = Vector2(5, -21)
			hand_b = Vector2(-7, -23)
			bow_dir = Vector2(0.9, -0.45).normalized()
			eyes = "squint"
			mouth = "open"
			stream = -1.0
		"kneel":
			crouch = 7.0
			lean = 1.5
			head_tilt = 0.35
			foot_f = Vector2(5, 0)
			knee_f = Vector2(6, -7)
			knee_b = Vector2(-3, -1)
			foot_b = Vector2(-9, -0.5)
			bow_grip = Vector2(9, -16)
			hand_f = Vector2(9, -16)
			hand_b = Vector2(4, -9)
			eyes = "closed" if fmod(t, 5.0) < 3.0 else "open"
			breath = sin(t * 3.2) * 0.8
		"leap":
			crouch = 2.0
			lean = 1.0
			foot_f = Vector2(4, -4)
			foot_b = Vector2(-3, -2)
			knee_f = Vector2(6, -10)
			knee_b = Vector2(2, -8)
			hand_f = Vector2(8, -21)
			hand_b = Vector2(-6, -20)
			bow_dir = Vector2(1.0, -0.12).normalized()
			stream = -1.0
	if v.talking:
		mouth = "talk" if int(t * 10.0) % 2 == 0 else "none"
		breath += sin(t * 14.0) * 0.3
	if bow_grip == Vector2.INF:
		bow_grip = hand_f

	var hip := Vector2(lean * 0.3, -14.5 + crouch)
	var neck := Vector2(lean + 0.5, -27.0 + crouch + breath)
	var sh_f := neck + Vector2(1.5, 1.5)
	var sh_b := neck + Vector2(-1.8, 1.4)
	var hc := neck + Vector2(0.8 + head_tilt * 2.0, -4.6 + absf(head_tilt) * 1.0)

	# 등 뒤 은은한 윤곽 빛 (어두운 배경과 분리)
	v.draw_circle(Vector2(lean * 0.5, -19 + crouch * 0.5), 17.0, Color(0.85, 1.0, 0.7, 0.05))
	v.draw_circle(Vector2(lean * 0.5, -19 + crouch * 0.5), 11.0, Color(0.85, 1.0, 0.7, 0.05))

	_cloak_back(v, t, neck, hip, stream, crouch)
	_quiver(v, neck, lean)
	_hair_tail(v, t, hc, neck, stream)
	# 뒷다리·뒷팔
	_leg(v, hip + Vector2(-1.2, 0), knee_b + Vector2(0, crouch * 0.5), foot_b, true)
	_arm(v, sh_b, hand_b, true, pose)
	if held_arrow:
		_arrow(v, hand_b + Vector2(0, 4), hand_b + Vector2(3, -9), 1.0, 0.0)
	# 몸통
	_torso(v, neck, hip, sh_f, sh_b)
	_leg(v, hip + Vector2(1.2, 0), knee_f + Vector2(0, crouch * 0.4), foot_f, false)
	_hood(v, neck, stream)
	_head(v, t, hc, head_tilt, eyes, mouth, v.blinking(), stream, fidget)
	# 활 + 시위 + 화살 (앞손이 손잡이를 덮게 활 먼저)
	_bow(v, t, bow_grip, bow_dir, bow_bend, pull, string_twang)
	if arrows > 0 and pull != Vector2.INF:
		for i in arrows:
			var spread := (i - (arrows - 1) * 0.5) * 0.2
			var d := bow_dir.rotated(spread)
			_arrow(v, pull, bow_grip + d * 6.0, 1.0, arrow_glow)
		if wind_gather > 0.0 or arrow_glow > 0.0:
			_wind_at(v, t, bow_grip + bow_dir * 6.0, bow_dir, maxf(wind_gather, arrow_glow))
	_arm(v, sh_f, hand_f, false, pose)
	# 망토 앞자락 (앞 어깨 위)
	_cloak_front(v, t, neck, sh_f, stream)


# ─── 부분 ───────────────────────────────────────────────

static func _cloak_back(v: CharacterVisual, t: float, neck: Vector2, hip: Vector2, stream: float, crouch: float) -> void:
	# 어깨에서 뒤로 넓게 떨어지는 망토. 밑단은 잎 모양으로 톱니지고, 시간에 따라 물결친다.
	var top_f := neck + Vector2(1.5, 0.5)
	var top_b := neck + Vector2(-2.5, 0.0)
	var hem_y := -5.0 + crouch * 0.6
	var pts := PackedVector2Array([top_f, neck + Vector2(2.5, 6.0)])
	var n := 7
	var hem: Array[Vector2] = []
	for i in n:
		var k := float(i) / (n - 1) # 0 앞 → 1 뒤
		var x := lerpf(2.5, -8.5, k) - stream * 7.0 * k
		var y := hem_y - (1.5 if i % 2 == 1 else 0.0) - maxf(-stream, 0.0) * 6.0 * k
		y += sin(t * 3.1 + k * 3.0) * (0.8 + 0.6 * k) + stream * 2.5 * k
		x += sin(t * 2.3 + k * 2.0) * 0.6 * k
		hem.append(Vector2(x + hip.x * 0.5, y))
	for h in hem:
		pts.append(h)
	pts.append(top_b + Vector2(-3.5 - stream * 2.0, 6.0))
	pts.append(top_b)
	v.draw_colored_polygon(pts, CLOAK_SH)
	# 안쪽 밝은 면 (몸 쪽)
	var inner := PackedVector2Array([neck + Vector2(0.5, 2), neck + Vector2(1.5, 6)])
	for i in range(0, n - 2):
		inner.append(hem[i] + Vector2(-1.0, -2.0))
	inner.append(neck + Vector2(-2.5, 7))
	v.draw_colored_polygon(inner, CLOAK)
	# 잎 무늬
	for i in 4:
		var k2 := 0.2 + i * 0.2
		var c := neck.lerp(hem[mini(i + 2, n - 1)], k2 + 0.15) + Vector2(-1.0, 0)
		_leaf_mark(v, c, -PI * 0.5 - 0.5 + i * 0.3, 2.6, LEAF_PAT)
	# 밑단 금빛 테두리 + 뒤쪽 가장자리 빛
	var edge := PackedVector2Array()
	for h in hem:
		edge.append(h + Vector2(0, -0.5))
	v.draw_polyline(edge, TRIM, 1.0)
	v.draw_line(top_b + Vector2(-0.5, 0.5), top_b + Vector2(-3.5 - stream * 2.0, 6.0), CLOAK_HI, 1.0)
	v.draw_line(top_b + Vector2(-3.5 - stream * 2.0, 6.0), hem[n - 1], CLOAK_HI.darkened(0.2), 1.0)


static func _cloak_front(v: CharacterVisual, t: float, neck: Vector2, sh_f: Vector2, stream: float) -> void:
	# 앞 어깨를 덮는 짧은 망토 자락
	var sw := sin(t * 2.7) * 0.4 - stream * 0.8
	var pts := PackedVector2Array([neck + Vector2(-1.0, -0.5), sh_f + Vector2(2.0, 0.5), sh_f + Vector2(1.5 + sw, 4.5), sh_f + Vector2(-1.0 + sw, 5.5), neck + Vector2(-2.0, 4.0)])
	v.draw_colored_polygon(pts, CLOAK)
	v.draw_line(neck + Vector2(-0.5, -0.3), sh_f + Vector2(2.0, 0.5), CLOAK_HI, 1.0)
	_leaf_mark(v, sh_f + Vector2(-0.5 + sw * 0.5, 2.5), -PI * 0.5 + 0.4, 2.0, LEAF_PAT.lightened(0.1))
	# 금 잎 망토 고정쇠
	v.draw_rect(Rect2(neck.x + 0.5, neck.y + 0.5, 2, 2), GOLD)
	v.draw_rect(Rect2(neck.x + 0.5, neck.y + 0.5, 1, 1), GOLD_HI)


static func _hood(v: CharacterVisual, neck: Vector2, stream: float) -> void:
	# 내려 쓴 두건이 목 뒤에 접혀 있다
	var s := -stream * 0.8
	var pts := PackedVector2Array([neck + Vector2(-5.5, -1.5 + s), neck + Vector2(-2.5, -3.0 + s), neck + Vector2(0.5, -0.5), neck + Vector2(-1.0, 2.5), neck + Vector2(-5.0, 2.0)])
	v.draw_colored_polygon(pts, CLOAK)
	v.draw_line(neck + Vector2(-5.5, -1.5 + s), neck + Vector2(-2.5, -3.0 + s), CLOAK_HI, 1.0)
	v.draw_line(neck + Vector2(-4.5, 1.5), neck + Vector2(-1.0, 2.0), CLOAK_SH, 1.0)


static func _quiver(v: CharacterVisual, neck: Vector2, lean: float) -> void:
	# 등에 비스듬히 멘 화살통 + 흰 깃
	var top := neck + Vector2(-4.5, -1.0)
	var bot := neck + Vector2(-7.5 - lean * 0.3, 11.0)
	var d := (bot - top).normalized()
	var n := Vector2(-d.y, d.x)
	v.draw_colored_polygon(PackedVector2Array([top + n * 1.8, bot + n * 1.6, bot - n * 1.6, top - n * 1.8]), LEATHER_SH)
	v.draw_line(top + n * 1.0, bot + n * 1.0, LEATHER, 1.0)
	v.draw_line(top.lerp(bot, 0.3) - n * 1.8, top.lerp(bot, 0.3) + n * 1.8, GOLD, 1.0)
	for i in 3:
		var b := top + n * (1.2 - i * 1.2)
		var tip := b - d * (4.5 + (i % 2) * 1.0)
		v.draw_line(b, tip, SHAFT, 1.0)
		v.draw_line(tip, tip + Vector2(-1.0, -0.5) - d * 1.5, FLETCH, 1.0)
		v.draw_line(tip + Vector2(0.8, 0), tip + Vector2(0.8, -0.5) - d * 1.5, Color(0.85, 0.88, 0.9), 1.0)


static func _hair_tail(v: CharacterVisual, t: float, hc: Vector2, neck: Vector2, stream: float) -> void:
	# 목덜미에서 낮게 묶어 허리 아래까지 늘어진 머리. 끝으로 갈수록 크게 흔들린다
	var root := neck + Vector2(-3.0, -1.5)
	var pts := PackedVector2Array([hc + Vector2(-3.5, 1.5), root])
	var seg := 6
	var p := root
	for i in seg:
		var k := float(i + 1) / seg
		var dx := -0.6 - stream * 2.2 * k + sin(t * 2.0 + k * 2.2) * 0.9 * k
		var dy := 3.2 - maxf(-stream, 0.0) * 2.4 * k - maxf(stream, 0.0) * 0.8 * k
		p += Vector2(dx, dy)
		pts.append(p)
	for i in range(pts.size() - 1):
		var k2 := float(i) / (pts.size() - 1)
		var w := lerpf(4.0, 1.5, k2)
		v.draw_line(pts[i], pts[i + 1], HAIR_SH, w)
		v.draw_line(pts[i] + Vector2(0.5, 0), pts[i + 1] + Vector2(0.5, 0), HAIR, maxf(w - 1.5, 1.0))
	v.draw_line(pts[2] + Vector2(0.8, 0), pts[4] + Vector2(0.8, 0), HAIR_HI, 1.0)
	# 끝 가닥 둘 (따로 흔들림)
	var end := pts[pts.size() - 1]
	v.draw_line(end, end + Vector2(-1.0 - stream * 1.5 + sin(t * 3.3) * 0.8, 2.0), HAIR_SH, 1.0)
	v.draw_line(end + Vector2(0.5, 0), end + Vector2(0.5 - stream + sin(t * 2.6 + 1.0) * 0.8, 1.6), HAIR, 1.0)
	# 금 잎 머리끈
	v.draw_rect(Rect2(root.x - 1.5, root.y - 0.5, 3, 2), GOLD)
	v.draw_rect(Rect2(root.x - 1.5, root.y - 0.5, 1, 1), GOLD_HI)
	v.draw_colored_polygon(PackedVector2Array([root + Vector2(1.5, 0), root + Vector2(3.5, -1.5), root + Vector2(2.5, 1.0)]), GOLD)


static func _torso(v: CharacterVisual, neck: Vector2, hip: Vector2, sh_f: Vector2, sh_b: Vector2) -> void:
	var pts := PackedVector2Array([sh_b + Vector2(0, 0), sh_f + Vector2(0.5, 0), hip + Vector2(2.6, 0), hip + Vector2(-2.6, 0)])
	v.draw_colored_polygon(pts, TUNIC_SH)
	v.draw_colored_polygon(PackedVector2Array([neck + Vector2(0, 1.5), sh_f + Vector2(0.5, 0), hip + Vector2(2.6, 0), hip + Vector2(0.2, 0)]), TUNIC)
	# 가죽 띠 (화살통 끈, 앞 어깨 → 뒤 허리)
	v.draw_line(sh_f + Vector2(0, 0.5), hip + Vector2(-2.2, -1.0), LEATHER, 1.5)
	# 허리띠 + 금 버클
	v.draw_line(hip + Vector2(-2.8, -1.0), hip + Vector2(2.8, -1.0), LEATHER_SH, 2.0)
	v.draw_rect(Rect2(hip.x + 0.5, hip.y - 2.0, 1.5, 1.5), GOLD)
	# 튜닉 아랫단 (허벅지 위로)
	v.draw_colored_polygon(PackedVector2Array([hip + Vector2(-3.0, 0), hip + Vector2(3.2, 0), hip + Vector2(3.6, 3.0), hip + Vector2(-3.2, 3.2)]), TUNIC_SH.darkened(0.1))
	v.draw_line(hip + Vector2(3.2, 0.2), hip + Vector2(3.6, 3.0), TUNIC, 1.0)


static func _leg(v: CharacterVisual, hip: Vector2, knee: Vector2, foot: Vector2, back: bool) -> void:
	var c := LEGS.darkened(0.25) if back else LEGS
	v.draw_line(hip, knee, c, 2.5)
	v.draw_line(knee, foot + Vector2(0, -2.5), c, 2.2)
	# 장화 (윗단 접힘)
	var b := BOOT.darkened(0.25) if back else BOOT
	v.draw_line(foot + Vector2(-0.2, -3.6), foot + Vector2(0, -0.5), b, 2.6)
	v.draw_line(foot + Vector2(-0.8, -0.5), foot + Vector2(2.2, -0.5), b, 1.6)
	v.draw_line(foot + Vector2(-1.2, -3.8), foot + Vector2(1.0, -3.8), BOOT_HI if not back else b, 1.0)


static func _arm(v: CharacterVisual, sh: Vector2, hand: Vector2, back: bool, pose: String) -> void:
	# 팔꿈치는 어깨-손 중간에서 아래·뒤로 살짝 꺾임
	var mid := sh.lerp(hand, 0.5)
	var bend := Vector2(-0.8, 1.2)
	if pose in ["aim", "attack", "attack2", "special", "charge"] and back:
		bend = Vector2(-1.5, -1.8) # 시위 당기는 팔꿈치가 높이 들림
	var elbow := mid + bend
	var sleeve := TUNIC_SH if back else TUNIC
	v.draw_line(sh, elbow, sleeve, 2.2)
	# 아래팔: 앞팔엔 가죽 팔보호대
	v.draw_line(elbow, hand, LEATHER if not back else SKIN_SH, 2.0)
	if not back:
		v.draw_line(elbow.lerp(hand, 0.2), elbow.lerp(hand, 0.75), LEATHER_SH, 1.0)
	# 손 + 붕대 감은 손가락
	v.draw_rect(Rect2(hand.x - 1.2, hand.y - 1.2, 2.4, 2.4), SKIN if not back else SKIN_SH)
	v.draw_line(hand + Vector2(-1.2, 0.2), hand + Vector2(1.2, 0.2), WRAP, 1.0)


static func _head(v: CharacterVisual, t: float, hc: Vector2, tilt: float, eyes: String, mouth: String, blink: bool, stream: float, fidget: String) -> void:
	# 뒷머리 덩어리
	v.draw_circle(hc + Vector2(-1.2, -0.6), 5.0, HAIR_SH)
	v.draw_circle(hc + Vector2(-0.6, -1.2), 4.6, HAIR)
	# 긴 귀 (뒤·위로 길게) — 머리카락 위로 드러남
	var ear_lift := -0.6 if fidget == "tuck" else 0.0
	var e0 := hc + Vector2(-1.2, -0.3)
	var etip := hc + Vector2(-9.0 + stream * 0.5, -5.2 + ear_lift + sin(t * 0.6) * 0.2)
	v.draw_colored_polygon(PackedVector2Array([e0 + Vector2(0, -1.4), etip, e0 + Vector2(0.4, 1.8)]), SKIN)
	v.draw_line(e0 + Vector2(-0.6, 0.2), etip + Vector2(1.6, 1.4), SKIN_SH, 1.0)
	# 얼굴 (턱이 앞으로 살짝 뾰족)
	var face := PackedVector2Array([hc + Vector2(-2.5, -3.6), hc + Vector2(2.2, -4.0), hc + Vector2(4.2, -1.2), hc + Vector2(4.3, 1.8),
		hc + Vector2(3.0, 3.9), hc + Vector2(0.5, 4.4), hc + Vector2(-2.2, 2.6)])
	v.draw_colored_polygon(face, SKIN)
	v.draw_line(hc + Vector2(-1.8, 2.8), hc + Vector2(0.6, 4.2), SKIN_SH, 1.0)
	# 주근깨
	v.draw_rect(Rect2(hc.x + 1.4, hc.y + 1.6, 1, 1), FRECKLE)
	v.draw_rect(Rect2(hc.x + 3.0, hc.y + 1.9, 1, 1), FRECKLE)
	# 눈 (초록)
	var ep := hc + Vector2(2.2, -0.2)
	if blink or eyes == "closed":
		v.draw_line(ep + Vector2(-0.8, 0.8), ep + Vector2(1.4, 0.8), Color("#3a2a20"), 1.0)
	elif eyes == "squint":
		v.draw_line(ep + Vector2(-0.8, 0.0), ep + Vector2(1.2, 1.0), Color("#3a2a20"), 1.0)
		v.draw_line(ep + Vector2(-0.8, 1.6), ep + Vector2(1.2, 1.0), Color("#3a2a20"), 1.0)
	else:
		v.draw_rect(Rect2(ep.x, ep.y, 1.6, 2.0), EYE)
		v.draw_rect(Rect2(ep.x, ep.y, 1.0, 1.0), Color(1, 1, 1, 0.9))
		v.draw_line(ep + Vector2(-0.8, -0.8), ep + Vector2(2.0, -0.6 if eyes != "sharp" else 0.0), Color("#6a6a40"), 1.0)
	match mouth:
		"talk":
			v.draw_rect(Rect2(hc.x + 2.6, hc.y + 2.6, 1.4, 1.0), Color("#8a4a3a"))
		"open":
			v.draw_rect(Rect2(hc.x + 2.6, hc.y + 2.4, 1.4, 1.4), Color("#7a3a32"))
	# 앞머리 (이마를 덮고 가닥이 갈라짐)
	var bangs := PackedVector2Array([hc + Vector2(-3.0, -4.8), hc + Vector2(1.5, -5.6), hc + Vector2(4.6, -3.2), hc + Vector2(4.4, -1.2),
		hc + Vector2(3.2, -2.4), hc + Vector2(2.2, -0.9), hc + Vector2(1.0, -2.6), hc + Vector2(-0.6, -1.2), hc + Vector2(-1.6, -3.0)])
	v.draw_colored_polygon(bangs, HAIR)
	v.draw_line(hc + Vector2(-2.0, -4.6), hc + Vector2(2.5, -5.0), HAIR_HI, 1.0)
	v.draw_line(hc + Vector2(1.2, -2.4), hc + Vector2(2.0, -4.2), HAIR_SH, 1.0)
	# 정수리 빛
	v.draw_arc(hc + Vector2(-0.8, -1.0), 4.4, -2.6, -1.4, 6, HAIR_HI, 1.0)
	# 얼굴 옆 긴 가닥 (귀 앞) — 따로 흔들림
	var sw := sin(t * 1.9 + 0.7) * 0.7 - stream * 0.6
	if fidget == "tuck":
		sw -= 1.5
	v.draw_line(hc + Vector2(-0.5, -2.2), hc + Vector2(-0.3 + sw * 0.5, 2.0), HAIR, 1.6)
	v.draw_line(hc + Vector2(-0.3 + sw * 0.5, 2.0), hc + Vector2(0.2 + sw, 5.0), HAIR_SH, 1.0)
	# 앞이마에서 삐져나온 가닥
	var sw2 := sin(t * 2.4 + 2.1) * 0.6 - stream * 0.8
	v.draw_line(hc + Vector2(3.4, -4.6), hc + Vector2(5.2 + sw2, -5.8 + sw2 * 0.4), HAIR_HI, 1.0)


static func _bow_points(grip: Vector2, d: Vector2, bend: float) -> PackedVector2Array:
	# 장궁: 손잡이를 중심으로 축(d에 수직)을 따라 위아래로 BOW_HALF, 끝으로 갈수록 시위 쪽(뒤)으로 휨
	var ax := Vector2(d.y, -d.x) # d를 반시계 90도 → 위쪽
	var out := PackedVector2Array()
	for i in 11:
		var s := -1.0 + i * 0.2
		out.append(grip + ax * s * BOW_HALF * (1.0 - bend * 0.012) - d * bend * s * s)
	return out


static func _bow(v: CharacterVisual, t: float, grip: Vector2, d: Vector2, bend: float, pull: Vector2, twang: float) -> void:
	var pts := _bow_points(grip, d, bend)
	var top := pts[0]
	var bot := pts[pts.size() - 1]
	# 시위
	var sc := Color(0.86, 0.92, 0.96, 0.85)
	if pull != Vector2.INF:
		v.draw_line(top, pull, sc, 1.0)
		v.draw_line(pull, bot, sc, 1.0)
	else:
		var mid := top.lerp(bot, 0.5) + d * sin(t * 90.0) * 1.4 * twang
		v.draw_line(top, mid, sc, 1.0)
		v.draw_line(mid, bot, sc, 1.0)
	# 활대 (3단: 그림자·바탕·빛) — 손잡이 쪽이 두껍다
	for i in pts.size() - 1:
		var k := absf(float(i) + 0.5 - (pts.size() - 1) * 0.5) / ((pts.size() - 1) * 0.5)
		var w := lerpf(2.6, 1.4, k)
		v.draw_line(pts[i], pts[i + 1], BOW_SH, w + 0.6)
		v.draw_line(pts[i] + d * 0.3, pts[i + 1] + d * 0.3, BOW, w)
	v.draw_line(pts[2] + d * 0.8, pts[4] + d * 0.8, BOW_HI, 1.0)
	# 금 잎 장식: 손잡이 + 양끝 소용돌이
	var gm := pts[5]
	v.draw_line(pts[4], pts[6], GOLD, 2.6)
	v.draw_rect(Rect2(gm.x - 0.5, gm.y - 0.5, 1, 1), GOLD_HI)
	var ax := Vector2(d.y, -d.x)
	v.draw_colored_polygon(PackedVector2Array([gm + d * 1.2, gm + d * 3.6 + ax * 1.8, gm + d * 1.6 + ax * 2.8]), GOLD)
	v.draw_colored_polygon(PackedVector2Array([gm + d * 1.2, gm + d * 3.6 - ax * 1.8, gm + d * 1.6 - ax * 2.8]), GOLD)
	for tip in [top, bot]:
		var tp: Vector2 = tip
		v.draw_rect(Rect2(tp.x - 1.0, tp.y - 1.0, 2, 2), GOLD)
		v.draw_rect(Rect2(tp.x - 1.0, tp.y - 1.0, 1, 1), GOLD_HI)
	# 빛 반사 점: 활을 따라 위에서 아래로 지나감 (3.4초마다)
	var g := fmod(t, 3.4)
	if g < 0.55:
		var k2 := g / 0.55
		var idx := clampi(int(k2 * (pts.size() - 1)), 0, pts.size() - 2)
		var gp := pts[idx].lerp(pts[idx + 1], fmod(k2 * (pts.size() - 1), 1.0)) + d * 0.5
		v.draw_rect(Rect2(gp.x - 0.5, gp.y - 0.5, 1.5, 1.5), Color(1, 1, 1, 0.95))
		v.draw_circle(gp, 2.0, Color(1, 1, 1, 0.18))


static func _arrow(v: CharacterVisual, from: Vector2, to: Vector2, alpha: float, glow: float) -> void:
	var d := (to - from).normalized()
	var n := Vector2(-d.y, d.x)
	if glow > 0.0:
		v.draw_line(from, to + d * 2.0, Color(WIND, 0.35 * glow), 3.0)
	v.draw_line(from, to, Color(SHAFT, alpha), 1.0)
	# 흰 깃
	v.draw_line(from + d * 0.5, from + d * 3.0 + n * 1.3, Color(FLETCH, alpha), 1.0)
	v.draw_line(from + d * 0.5, from + d * 3.0 - n * 1.3, Color(FLETCH, alpha * 0.85), 1.0)
	# 화살촉
	v.draw_colored_polygon(PackedVector2Array([to + d * 2.5, to + n * 1.2, to - n * 1.2]), Color(TIP, alpha) if glow <= 0.0 else Color(WIND, alpha))


static func _wind_at(v: CharacterVisual, t: float, tip: Vector2, d: Vector2, k: float) -> void:
	# 화살 끝으로 모여드는 바람 (바람을 읽는 눈)
	var n := Vector2(-d.y, d.x)
	for i in 4:
		var ph := fmod(t * 1.6 + i * 0.25, 1.0)
		var r := lerpf(9.0, 1.5, ph)
		var a := i * 1.7 + t * 0.8
		var p := tip + d * cos(a) * r + n * sin(a) * r * 0.7
		var q := p.lerp(tip, 0.35)
		v.draw_line(p, q, Color(WIND, 0.55 * k * (1.0 - ph)), 1.0)
	v.draw_circle(tip, 2.5 + k, Color(WIND, 0.12 * k))


static func _leaf_mark(v: CharacterVisual, c: Vector2, ang: float, len: float, col: Color) -> void:
	var d := Vector2(cos(ang), sin(ang))
	var n := Vector2(-d.y, d.x)
	v.draw_colored_polygon(PackedVector2Array([c - d * len * 0.5, c + n * len * 0.35, c + d * len * 0.5, c - n * len * 0.35]), col)


## 쓰러짐: 등을 대고 누워 있다 (머리가 뒤쪽). 활은 옆에 떨어져 있다
static func _draw_down(v: CharacterVisual, t: float) -> void:
	# 바닥의 활
	_bow(v, t, Vector2(8, -2), Vector2(0, -1), 1.5, Vector2.INF, 0.0)
	# 망토가 바닥에 펼쳐짐
	v.draw_colored_polygon(PackedVector2Array([Vector2(-18, 0), Vector2(-14, -4), Vector2(8, -4), Vector2(14, 0)]), CLOAK_SH)
	v.draw_colored_polygon(PackedVector2Array([Vector2(-12, -1), Vector2(-10, -4), Vector2(6, -4), Vector2(9, -1)]), CLOAK)
	# 머리카락 (바닥으로 흘러내림)
	v.draw_line(Vector2(-15, -3), Vector2(-21, -1), HAIR_SH, 3.0)
	v.draw_line(Vector2(-15, -3.5), Vector2(-20, -2), HAIR, 1.5)
	# 몸 (튜닉·다리)
	v.draw_line(Vector2(-9, -5), Vector2(2, -5), TUNIC, 4.0)
	v.draw_line(Vector2(2, -4), Vector2(12, -3), LEGS, 3.0)
	v.draw_line(Vector2(12, -3.5), Vector2(15, -5), BOOT, 2.5)
	# 얼굴 (옆으로, 눈 감음) + 귀
	var hc := Vector2(-13, -6 + sin(t * 1.8) * 0.3)
	v.draw_colored_polygon(PackedVector2Array([hc + Vector2(-2, 2), hc + Vector2(-6, -4), hc + Vector2(0, 0)]), SKIN)
	v.draw_circle(hc, 3.8, SKIN)
	v.draw_circle(hc + Vector2(-1.5, 0.5), 3.5, HAIR)
	v.draw_line(hc + Vector2(0.2, -2.0), hc + Vector2(1.8, -2.0), Color("#3a2a20"), 1.0)
	v.draw_rect(Rect2(hc.x + 1.5, hc.y - 0.5, 1, 1), FRECKLE)
	# 팔 (가슴 위로)
	v.draw_line(Vector2(-6, -6), Vector2(-2, -8), TUNIC_SH, 2.0)
	v.draw_rect(Rect2(-2.5, -9.5, 2.4, 2.4), SKIN)
	v.draw_line(Vector2(-2.5, -8.2), Vector2(-0.1, -8.2), WRAP, 1.0)
