extends "res://characters/special/leonie_palette.gd"
## 레오니 발렌하르트 전용 몸 그림 (docs/archive/sera/bible/characters.md 3절, art.md 3절). CharacterVisual이 draw_body(v)를 부른다.
## 키 40px. 짙은 남색 단발 + 귀 뒤로 가는 땋은 머리, 금빛 눈, 콧등을 가로지르는 흉터, 은빛 흉갑·어깨갑,
## 진홍 망토(은사자 문장), 가늘고 긴 장검(손잡이에 붉은 끈). 서 있을 땐 검을 땅에 짚는다.
##
## 3단 명암(바탕·그림자·빛), 망토·머리카락은 실제 움직임(전역 위치 변화)에 반응하는 스프링으로 흔들린다(v의 meta에 상태 저장).
## 숨쉬기 1px, 눈 깜빡임, 7초마다 검을 고쳐 잡는 대기 동작, 검날 위로 빛 반사 점이 지나간다.
## 자세(v.pose): idle · run · windup · attack · attack2 · guard · charge · special(일섬 발도 자세: 검을 칼집에, 깊게 웅크림)
##              · hurt · kneel · down. aim·cast·모르는 자세 = idle. 걸을 때(v.walking)는 검을 칼집에 넣고 걷는다.
## v.info["sword"] == "wood" 이면 목검(대련). v의 meta "warn"(0~1)을 적이 넣으면 검날에 붉은 예고 빛.

## 그릴 때 meta에 스프링 상태를 쌓는다 → 화면 밖에서도 매 프레임 그려야 다시 보일 때 같은 모습 (CharacterVisual)
const KEEP_DRAWING := true
const HAIR_L := Color("#3a4a7e")
const HAIR_D := Color("#0d1122")
const SKIN_D := Color("#d4a894")
const BROW_C := Color("#141a30")
const EYE := Color("#ffc23a")
const SCAR := Color("#e8a8a0")
const UNDER := Color("#1f2338")
const UNDER_L := Color("#30365a")
const LEATHER := Color("#4a2c20")
const BLADE := Color("#d6dbe8")
const BLADE_D := Color("#868ca2")
const GRIP := Color("#b0202c")
const GOLD := Color("#d8b050")
const WOOD := Color("#a87448")
const WOOD_D := Color("#6a4428")
const DANGER := Color("#ff3b3b")
const BLADE_LEN := 22.0
const THIGH := 8.0
const SHIN := 8.6
const UPPER_ARM := 5.8
const FOREARM := 5.6


static func draw_body(v: CharacterVisual) -> void:
	var t := v.time()
	var pose := v.pose
	if pose in ["", "aim", "cast"]:
		pose = "idle"
	if pose == "idle" and v.walking:
		pose = "walk"
	var rig := _rig(v, pose, t)
	_physics(v, rig, t)
	if pose == "down":
		# 누운 모습: 선 자세를 옆으로 눕혀 그린다 (머리가 뒤쪽, 얼굴이 위)
		v.draw_set_transform(Vector2(19, -4), -PI * 0.5, Vector2.ONE)
		_render(v, rig, t)
		v.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		_render(v, rig, t)


# ─── 자세 → 뼈대 ────────────────────────────────────────

static func _ease(x: float) -> float:
	var k := clampf(x, 0.0, 1.0)
	return k * k * (3.0 - 2.0 * k)


## 자세별 뼈대 값. 손 위치는 어깨 기준 오프셋(hand_f_rel·hand_b_rel)이나 절대 위치(hand_f·hand_b)로 준다.
static func _rig(v: CharacterVisual, pose: String, t: float) -> Dictionary:
	var pt := v.pose_t
	var br := sin(t * 2.0) * 0.5 # 숨쉬기
	var r := {
		"hip": Vector2(0, -17), "lean": 0.0, "foot_f": Vector2(3, 0), "foot_b": Vector2(-3, 0),
		"sword": "hand", "sword_a": PI * 0.5, "hilt": Vector2.ZERO, "grip": "f",
		"cape": Vector2.ZERO, "head_tilt": 0.0, "head_off": Vector2.ZERO, "eye_glow": 0.0, "arc": [], "aura": 0.0,
		"knee_b": Vector2.INF, "knee_f": Vector2.INF, "hair_flow": 0.0,
	}
	match pose:
		"idle":
			# 검을 땅에 짚고 두 손을 자루 끝에. 7초마다 검을 살짝 들었다 고쳐 짚는다
			var rg := fmod(t + 3.0, 7.0)
			var lift := sin(clampf(rg / 0.8, 0.0, 1.0) * PI) if rg < 0.8 else 0.0
			r.hip = Vector2(0, -17 + br * 0.4)
			r.lean = 0.03
			r.foot_f = Vector2(3.5, 0)
			r.foot_b = Vector2(-3, 0)
			r.sword = "planted"
			r.hilt = Vector2(8, -21.5 - lift * 2.5)
			r.sword_a = PI * 0.5
			r.hand_f = Vector2(8, -24.5 + br * 0.5 - lift * 2.5)
			r.hand_b = Vector2(7, -24 + br * 0.5 - lift * 2.5)
			r.grip = "both"
		"walk":
			var c := v.walk_phase() if v.walking else t * 8.0
			r.hip = Vector2(0, -17 - absf(sin(c)) * 0.8)
			r.lean = 0.08
			r.foot_f = Vector2(sin(c) * 4.5 + 1, -maxf(cos(c), 0.0) * 2.0)
			r.foot_b = Vector2(-sin(c) * 4.5 + 1, -maxf(-cos(c), 0.0) * 2.0)
			r.sword = "sheathed"
			r.hand_f_rel = Vector2(sin(c + PI) * 2.5, 9.5)
			r.hand_b_rel = Vector2(sin(c) * 2.5, 9.5)
			r.cape = Vector2(-3, -1)
		"run":
			var c2 := t * 13.0
			r.hip = Vector2(1, -16.5 - absf(sin(c2)) * 1.2)
			r.lean = 0.3
			r.foot_f = Vector2(sin(c2) * 6.5 + 2, -maxf(cos(c2), 0.0) * 3.5)
			r.foot_b = Vector2(-sin(c2) * 6.5 + 2, -maxf(-cos(c2), 0.0) * 3.5)
			r.hand_f_rel = Vector2(-1 + sin(c2 + PI) * 2.0, 8.5)
			r.hand_b_rel = Vector2(sin(c2) * 3.5, 8.0)
			r.sword_a = 2.75 # 칼끝이 뒤쪽 아래로
			r.cape = Vector2(-10, -7)
			r.hair_flow = 1.0
		"windup":
			var k := _ease(pt / 0.16)
			r.hip = Vector2(-1.5 * k, -17 + 2.2 * k)
			r.lean = 0.03 - 0.16 * k
			r.foot_f = Vector2(5.5, 0)
			r.foot_b = Vector2(-5, 0)
			r.hand_f_rel = Vector2(1.5, 7).lerp(Vector2(-3.5, -6.5), k)
			r.hand_b_rel = Vector2(1, 8).lerp(Vector2(-1.5, -5.5), k)
			r.grip = "both"
			r.sword_a = lerpf(1.2, -2.35, k) # 칼끝이 등 뒤 위로
			r.cape = Vector2(-2, -2)
			r.eye_glow = 0.3 * k
		"attack":
			var k2 := _ease(pt / 0.07)
			r.hip = Vector2(3.5 * k2, -17 + 1.8 * k2)
			r.lean = 0.32 * k2
			r.foot_f = Vector2(5.5 + 3.5 * k2, 0)
			r.foot_b = Vector2(-5 - 2 * k2, 0)
			r.hand_f_rel = Vector2(-3.5, -6.5).lerp(Vector2(8.5, 3.5), k2)
			r.hand_b_rel = Vector2(-1.5, -5.5).lerp(Vector2(4.5, 6.0), k2)
			r.sword_a = lerpf(-2.35, 0.38, k2)
			r.cape = Vector2(-9, -4)
			r.hair_flow = 0.6
			r.arc = [-2.35, 0.38, pt]
		"attack2":
			var k3 := _ease(pt / 0.08)
			r.hip = Vector2(2, -16.5 - 1.5 * k3)
			r.lean = lerpf(0.22, -0.06, k3)
			r.foot_f = Vector2(6.5, 0)
			r.foot_b = Vector2(-5, 0)
			r.hand_f_rel = Vector2(6, 6).lerp(Vector2(5.5, -6.5), k3)
			r.hand_b_rel = Vector2(3, 7).lerp(Vector2(2, -4), k3)
			r.sword_a = lerpf(0.95, -1.35, k3)
			r.cape = Vector2(-7, -8)
			r.hair_flow = 0.6
			r.arc = [0.95, -1.35, pt]
		"guard":
			var k4 := _ease(pt / 0.12)
			r.hip = Vector2(-1, -17 + 1.8 * k4)
			r.lean = -0.05
			r.foot_f = Vector2(6.5, 0)
			r.foot_b = Vector2(-5.5, 0)
			r.hand_f_rel = Vector2(4.5, 4.0)
			r.hand_b_rel = Vector2(3.0, 5.5)
			r.grip = "both"
			r.sword_a = lerpf(0.6, -1.12, k4) # 칼날을 비스듬히 세워 정면을 막는다
			r.cape = Vector2(-3, -1)
			r.eye_glow = 0.25
		"charge":
			r.hip = Vector2(2, -12.5)
			r.lean = 0.62
			r.foot_f = Vector2(9.5, 0)
			r.foot_b = Vector2(-12, -1.5)
			r.knee_b = Vector2(-4, -6)
			r.hand_f_rel = Vector2(-1.5, 8.0)
			r.hand_b_rel = Vector2(-7, 3)
			r.sword_a = 2.95
			r.cape = Vector2(-20, -11)
			r.hair_flow = 1.6
		"special":
			# 일섬: 검을 칼집에 넣고 깊게 웅크림. 시간이 갈수록 기운이 모인다(눈빛·바람)
			var k5 := _ease(pt / 0.3)
			r.hip = Vector2(-1, -17 + 6.5 * k5)
			r.lean = 0.42 * k5
			r.foot_f = Vector2(7.5, 0)
			r.foot_b = Vector2(-9, 0)
			r.knee_b = Vector2(-3.5, -1.5).lerp(Vector2(-3, -8), 1.0 - k5)
			r.sword = "drawready"
			r.cape = Vector2(-5, 1.5 - 3.0 * clampf(pt / 1.5, 0.0, 1.0))
			r.eye_glow = 0.4 + 0.6 * clampf(pt / 1.2, 0.0, 1.0)
			r.aura = clampf((pt - 0.2) / 1.3, 0.0, 1.0)
		"hurt":
			var k6 := _ease(pt / 0.08)
			r.hip = Vector2(-2 * k6, -16.5)
			r.lean = -0.32 * k6
			r.foot_f = Vector2(4.5, -1)
			r.foot_b = Vector2(-4, 0)
			r.hand_f_rel = Vector2(6, -3)
			r.hand_b_rel = Vector2(-5, 2)
			r.sword_a = -0.6
			r.head_tilt = -0.25 * k6
			r.cape = Vector2(4, -3)
		"kneel":
			r.hip = Vector2(-1, -9.5 + br * 0.3)
			r.lean = 0.14
			r.foot_f = Vector2(5, 0)
			r.foot_b = Vector2(-8, 0)
			r.knee_f = Vector2(6, -8)
			r.knee_b = Vector2(-2, -1)
			r.sword = "planted"
			r.hilt = Vector2(10, -13)
			r.sword_a = PI * 0.5
			r.hand_f = Vector2(10, -16 + br * 0.4)
			r.hand_b = Vector2(9, -15.5 + br * 0.4)
			r.grip = "both"
			r.head_off = Vector2(0.8, 1.5)
			r.head_tilt = 0.25
			r.cape = Vector2(-4, 6)
		"down":
			r.hip = Vector2(0, -17)
			r.foot_f = Vector2(1.5, 0)
			r.foot_b = Vector2(-1.5, 0)
			r.hand_f_rel = Vector2(1, 10)
			r.hand_b_rel = Vector2(-1, 10)
			r.sword = "none"
			r.cape = Vector2(-4, 0)
		_:
			pass
	return r


# ─── 망토·머리 스프링 ────────────────────────────────────

static func _physics(v: CharacterVisual, rig: Dictionary, t: float) -> void:
	var last_t: float = v.get_meta("k_lt", t)
	var dt := clampf(t - last_t, 0.0, 0.1)
	var gp := v.global_position
	var last_p: Vector2 = v.get_meta("k_lp", gp)
	var face := signf(v.get_global_transform().x.x)
	if face == 0.0:
		face = 1.0
	var vel := (gp - last_p) / dt if dt > 0.0001 else Vector2.ZERO
	var local_vx := vel.x * face
	var target: Vector2 = rig.cape + Vector2(clampf(-local_vx * 0.045, -12.0, 8.0), clampf(-absf(local_vx) * 0.02 - vel.y * 0.015, -8.0, 6.0))
	target += Vector2(sin(t * 1.7) * 1.2, sin(t * 2.3) * 0.6)
	var cape: Vector2 = v.get_meta("k_cape", target)
	var cv: Vector2 = v.get_meta("k_cape_v", Vector2.ZERO)
	# 감쇠 스프링 (출렁임이 한 번 남음)
	cv += (target - cape) * 60.0 * dt
	cv *= exp(-dt * 7.0)
	cape += cv * dt * 6.0
	var hair: float = v.get_meta("k_hair", 0.0)
	var hair_target: float = rig.hair_flow + clampf(absf(local_vx) * 0.006, 0.0, 1.2)
	hair = lerpf(hair, hair_target, 1.0 - exp(-dt * 8.0))
	v.set_meta("k_lt", t)
	v.set_meta("k_lp", gp)
	v.set_meta("k_cape", cape)
	v.set_meta("k_cape_v", cv)
	v.set_meta("k_hair", hair)
	rig.cape_now = cape
	rig.hair_now = hair


# ─── 그리기 ─────────────────────────────────────────────

static func _ik(a: Vector2, b: Vector2, l1: float, l2: float, bend: float) -> Vector2:
	var d := clampf(a.distance_to(b), 0.01, l1 + l2 - 0.05)
	var cos_a := (l1 * l1 + d * d - l2 * l2) / (2.0 * l1 * d)
	var ang := acos(clampf(cos_a, -1.0, 1.0))
	return a + Vector2.from_angle((b - a).angle() - ang * bend) * l1


static func _seg(v: CanvasItem, a: Vector2, b: Vector2, w: float, col: Color) -> void:
	DrawKit.seg(v, a, b, w, col, OUT)


static func _render(v: CharacterVisual, rig: Dictionary, t: float) -> void:
	var hip: Vector2 = rig.hip
	var lean: float = rig.lean
	var u := Vector2(sin(lean), -cos(lean)) # 몸통 위쪽
	var rt := Vector2(cos(lean), sin(lean)) # 몸통 앞쪽
	var chest := hip + u * 13.0
	var sh_f := chest + rt * 1.5 + u * -0.5
	var sh_b := chest + rt * -2.0 + u * -0.5
	var head: Vector2 = chest + u * 5.2 + rt * 0.8 + rig.head_off
	var warn: float = v.get_meta("warn", 0.0)
	var wood := String(v.info.get("sword", "")) == "wood"

	# 손 위치
	var hand_f: Vector2 = rig.hand_f if rig.has("hand_f") else sh_f + (rig.get("hand_f_rel", Vector2(1, 9)) as Vector2)
	var hand_b: Vector2 = rig.hand_b if rig.has("hand_b") else sh_b + (rig.get("hand_b_rel", Vector2(-1, 9)) as Vector2)
	# 검 위치: 손에 쥔 경우 칼자루가 손에 있다
	var sword_mode: String = rig.sword
	var sa: float = rig.sword_a
	var sdir := Vector2.from_angle(sa)
	var guard: Vector2 = rig.hilt
	if sword_mode == "hand":
		guard = hand_f + sdir * 2.0
		if String(rig.grip) == "both":
			hand_b = hand_f - sdir * 2.6
	elif sword_mode == "drawready":
		# 칼집에 든 검: 칼집은 허리 뒤로 거의 수평, 자루는 앞으로 비스듬히
		guard = hip + rt * 2.5 + u * 1.5
		hand_f = guard + Vector2.from_angle(lean - 0.5) * 3.2
		hand_b = hip + rt * 0.5 + u * 0.8

	# 0) 등 뒤 은은한 윤곽 빛
	v.draw_circle(chest + u * -2.0, 20.0, Color(CAPE_L, 0.05))
	# 1) 망토 (몸 뒤)
	_cape(v, sh_b, sh_f, rig.cape_now, t, u, rt)
	# 2) 칼집 (허리 뒤)
	_scabbard(v, hip, u, rt, sword_mode, lean, wood)
	# 3) 뒷팔
	var elbow_b := _ik(sh_b, hand_b, UPPER_ARM, FOREARM, -1.0)
	_seg(v, sh_b, elbow_b, 2.6, ARMOR_D.darkened(0.15))
	_seg(v, elbow_b, hand_b, 2.4, UNDER)
	v.draw_rect(Rect2(hand_b - Vector2(1.5, 1.5), Vector2(3, 3)), ARMOR_D)
	# 4) 다리
	var hip_f := hip + rt * 1.6
	var hip_b := hip + rt * -1.6
	var knee_b: Vector2 = rig.knee_b if rig.knee_b != Vector2.INF else _ik(hip_b, rig.foot_b, THIGH, SHIN, 1.0)
	var knee_f: Vector2 = rig.knee_f if rig.knee_f != Vector2.INF else _ik(hip_f, rig.foot_f, THIGH, SHIN, 1.0)
	_leg(v, hip_b, knee_b, rig.foot_b, true)
	# 5) 뒤 어깨갑
	_pauldron(v, sh_b + u * 0.5, u, rt, true)
	# 6) 몸통
	_torso(v, hip, u, rt, t)
	# 7) 앞다리
	_leg(v, hip_f, knee_f, rig.foot_f, false)
	# 8) 머리
	_head(v, head, u, rt, rig, t)
	# 9) 목깃 (망토 여밈) + 앞 어깨갑
	var clasp := chest + u * 0.6 + rt * 2.6
	v.draw_line(sh_b + u * 0.8, clasp, CAPE_D, 2.0)
	v.draw_circle(clasp, 1.3, ARMOR_L)
	_pauldron(v, sh_f + u * 0.4, u, rt, false)
	# 10) 검과 앞팔 (손에 쥔 검은 팔 아래에)
	if sword_mode == "hand" or sword_mode == "planted":
		_sword(v, guard, Vector2.from_angle(sa), t, warn, wood, rig)
	elif sword_mode == "drawready":
		_drawready_hilt(v, guard, Vector2.from_angle(lean - 0.5), wood, warn, rig.aura)
	var elbow_f := _ik(sh_f, hand_f, UPPER_ARM, FOREARM, -1.0)
	_seg(v, sh_f, elbow_f, 2.8, ARMOR)
	v.draw_line(sh_f, elbow_f, ARMOR_L, 1.0)
	_seg(v, elbow_f, hand_f, 2.6, ARMOR_D)
	v.draw_rect(Rect2(hand_f - Vector2(1.6, 1.6), Vector2(3.2, 3.2)), OUT)
	v.draw_rect(Rect2(hand_f - Vector2(1.2, 1.2), Vector2(2.6, 2.6)), ARMOR)
	# 11) 효과: 베기 궤적, 일섬 기운
	var arc: Array = rig.arc
	if arc.size() == 3:
		_slash_arc(v, sh_f, float(arc[0]), float(arc[1]), float(arc[2]), wood)
	if float(rig.aura) > 0.0:
		_aura(v, hip, float(rig.aura), t)


static func _leg(v: CharacterVisual, hip_p: Vector2, knee: Vector2, foot: Vector2, back: bool) -> void:
	var cloth := UNDER.darkened(0.2) if back else UNDER
	var plate := ARMOR_D if back else ARMOR
	_seg(v, hip_p, knee, 3.0, cloth)
	_seg(v, knee, foot + Vector2(0, -1.5), 2.8, plate)
	if not back:
		v.draw_line(knee + Vector2(0.6, 0.5), foot + Vector2(0.6, -2.5), ARMOR_L, 1.0)
	# 무릎 보호대
	v.draw_circle(knee, 1.7, plate.lightened(0.1))
	# 쇠장화 (발끝이 앞)
	var boot := Rect2(foot + Vector2(-1.8, -2.4), Vector2(4.6, 2.4))
	v.draw_rect(boot.grow(1.0), OUT)
	v.draw_rect(boot, plate.darkened(0.15))
	v.draw_rect(Rect2(boot.position, Vector2(4.6, 0.8)), plate.lightened(0.15))


static func _pauldron(v: CharacterVisual, at: Vector2, u: Vector2, rt: Vector2, back: bool) -> void:
	var base := ARMOR_D if back else ARMOR
	var pts := PackedVector2Array([
		at + rt * -3.2 + u * -1.6, at + rt * -2.6 + u * 1.6, at + rt * 0.0 + u * 2.6,
		at + rt * 2.8 + u * 1.4, at + rt * 3.4 + u * -1.8,
	])
	KArt.poly(v, DrawKit.grow_poly(pts, 1.0), OUT)
	KArt.poly(v, pts, base)
	if not back:
		v.draw_line(at + rt * -2.0 + u * 1.4, at + rt * 2.2 + u * 1.2, ARMOR_L, 1.0)
		v.draw_line(at + rt * -2.6 + u * -0.6, at + rt * 3.0 + u * -0.8, ARMOR_D, 1.0)


## 다각형을 무게중심에서 조금 키운다 (외곽선용)
static func _tp(hip: Vector2, u: Vector2, rt: Vector2, x: float, y: float) -> Vector2:
	return hip + rt * x + u * y


static func _torso(v: CharacterVisual, hip: Vector2, u: Vector2, rt: Vector2, t: float) -> void:
	# 아랫단 (남색 웃옷 자락) + 은 판금 허리 갑옷
	var skirt := PackedVector2Array([_tp(hip, u, rt, -4.5, 2.5), _tp(hip, u, rt, 4.5, 2.5), _tp(hip, u, rt, 5.6, -4.2), _tp(hip, u, rt, -5.4, -4.2)])
	KArt.poly(v, DrawKit.grow_poly(skirt, 1.0), OUT)
	KArt.poly(v, skirt, UNDER_L)
	v.draw_line(_tp(hip, u, rt, -1, 2), _tp(hip, u, rt, -1.4, -3.8), UNDER, 1.0)
	v.draw_line(_tp(hip, u, rt, 2.5, 2), _tp(hip, u, rt, 3.2, -3.8), UNDER, 1.0)
	var tasset := PackedVector2Array([_tp(hip, u, rt, -4.4, 2.6), _tp(hip, u, rt, 4.6, 2.6), _tp(hip, u, rt, 5.0, -0.6), _tp(hip, u, rt, -4.8, -0.6)])
	KArt.poly(v, tasset, ARMOR_D)
	v.draw_line(_tp(hip, u, rt, -4.4, 1.0), _tp(hip, u, rt, 4.8, 1.0), ARMOR, 1.0)
	# 흉갑 (3단 명암)
	var chest := PackedVector2Array([
		_tp(hip, u, rt, -4.2, 2.4), _tp(hip, u, rt, 4.4, 2.4), _tp(hip, u, rt, 5.2, 8.0),
		_tp(hip, u, rt, 4.2, 12.6), _tp(hip, u, rt, -3.6, 13.0), _tp(hip, u, rt, -4.8, 8.2),
	])
	KArt.poly(v, DrawKit.grow_poly(chest, 1.0), OUT)
	KArt.poly(v, chest, ARMOR)
	var shade := PackedVector2Array([_tp(hip, u, rt, -4.2, 2.4), _tp(hip, u, rt, -1.2, 2.4), _tp(hip, u, rt, -1.6, 12.9), _tp(hip, u, rt, -3.6, 13.0), _tp(hip, u, rt, -4.8, 8.2)])
	KArt.poly(v, shade, ARMOR_D)
	# 가슴 능선과 빛
	v.draw_line(_tp(hip, u, rt, 2.6, 3.6), _tp(hip, u, rt, 3.6, 10.8), ARMOR_L, 1.0)
	v.draw_line(_tp(hip, u, rt, 0.8, 3.0), _tp(hip, u, rt, 1.0, 12.0), ARMOR.darkened(0.12), 1.0)
	# 지나가는 빛 반사 (5초마다)
	var g := fmod(t, 5.0)
	if g < 0.5:
		var gy := lerpf(3.0, 12.0, g / 0.5)
		v.draw_rect(Rect2(_tp(hip, u, rt, 3.0, gy) - Vector2(0.5, 0.5), Vector2(1.5, 1.5)), Color(1, 1, 1, 0.9))
	# 허리띠 + 은 버클
	v.draw_line(_tp(hip, u, rt, -4.6, 2.6), _tp(hip, u, rt, 4.8, 2.6), LEATHER, 1.6)
	v.draw_rect(Rect2(_tp(hip, u, rt, 1.2, 2.6) - Vector2(0.8, 0.8), Vector2(1.8, 1.6)), ARMOR_L)


static func _head(v: CharacterVisual, head: Vector2, u: Vector2, rt: Vector2, rig: Dictionary, t: float) -> void:
	var tilt: float = rig.head_tilt
	var hu := u.rotated(tilt)
	var hr := rt.rotated(tilt)
	var hair_now: float = rig.hair_now
	var sway := sin(t * 2.3) * 0.5 + hair_now * 1.4
	var hp := func(x: float, y: float) -> Vector2: return head + hr * x + hu * y
	# 목
	v.draw_line(hp.call(-0.5, -3.0), hp.call(-0.8, -5.6), SKIN_D, 2.4)
	# 땋은 머리: 귀 뒤에서 어깨까지 (마디마디 흔들림) — 얼굴·머리 뒤에 그림
	var bp: Vector2 = hp.call(-2.8, -1.2)
	for i in 5:
		var k := float(i)
		var nxt := bp + hu * -1.6 + hr * (-0.35 - sway * 0.2 - k * 0.1 * hair_now) + hr * sin(t * 2.0 + k * 0.6) * 0.25
		v.draw_line(bp, nxt, OUT, 2.8)
		v.draw_line(bp, nxt, HAIR_L if i % 2 == 0 else HAIR, 1.6)
		bp = nxt
	v.draw_rect(Rect2(bp - Vector2(0.9, 0.5), Vector2(1.8, 1.4)), CAPE_L) # 붉은 끈
	# 얼굴 (옆얼굴: 앞쪽이 조금 길다)
	var face := PackedVector2Array()
	for i in 14:
		var a := TAU * i / 14.0
		var rx := 4.1 if cos(a) > 0 else 3.6
		var ry := 4.5 if sin(a) > 0 else 4.2
		face.append(head + hr * cos(a) * rx + hu * -sin(a) * ry)
	KArt.poly(v, DrawKit.grow_poly(face, 1.0), OUT)
	KArt.poly(v, face, SKIN)
	v.draw_line(hp.call(-1.6, -2.6), hp.call(2.2, -3.9), SKIN_D, 1.0) # 턱 그늘
	v.draw_rect(Rect2(hp.call(4.1, -0.9) - Vector2(0.5, 0.5), Vector2(1, 1)), SKIN_D) # 콧날
	# 머리카락: 정수리·뒤통수를 덮고 옆머리는 턱선에서 뾰족하게, 앞머리는 눈썹 위까지
	var hair := PackedVector2Array([
		hp.call(4.2, 2.0), hp.call(2.6, 4.6), hp.call(-1.0, 5.4), hp.call(-4.4, 3.6), hp.call(-5.3 - sway * 0.5, 0.2),
		hp.call(-5.0 - sway, -3.4), hp.call(-3.0, -2.0), hp.call(-1.8, -3.8), hp.call(-0.8, 0.6), hp.call(1.6, 1.8),
	])
	KArt.poly(v, DrawKit.grow_poly(hair, 1.0), OUT)
	KArt.poly(v, hair, HAIR)
	# 앞머리 끝 두 가닥 + 윤기
	KArt.poly(v, PackedVector2Array([hp.call(2.4, 2.2), hp.call(4.3, 1.8), hp.call(3.6 + sway * 0.1, 0.8)]), HAIR)
	KArt.poly(v, PackedVector2Array([hp.call(0.4, 1.8), hp.call(2.0, 2.0), hp.call(1.4, 0.9)]), HAIR)
	v.draw_line(hp.call(-3.2, 3.6), hp.call(1.4, 4.8), HAIR_L, 1.0)
	v.draw_line(hp.call(-4.4, 1.4), hp.call(-3.6, 3.4), HAIR_L, 1.0)
	v.draw_line(hp.call(-4.6 - sway * 0.6, -1.0), hp.call(-5.2 - sway, -3.0), HAIR_D, 1.0)
	# 눈 (금빛) — 깜빡임
	var eye: Vector2 = hp.call(2.1, 0.0)
	var glow: float = rig.eye_glow
	if v.blinking() and glow < 0.5:
		v.draw_line(eye + hr * -0.6, eye + hr * 1.2, HAIR_D, 1.0)
	else:
		v.draw_rect(Rect2(eye - Vector2(0.5, 1.0), Vector2(1.6, 2.2)), EYE)
		v.draw_rect(Rect2(eye - Vector2(0.5, 1.0), Vector2(0.8, 0.8)), Color(1, 1, 0.9))
		if glow > 0.0:
			v.draw_circle(eye, 1.5 + glow * 1.6, Color(EYE, 0.25 * glow))
			if glow > 0.6:
				v.draw_line(eye + hr * -0.4, eye + hr * -(2.5 + glow * 3.5) + hu * 0.3, Color(EYE, 0.5 * (glow - 0.6) / 0.4), 1.0) # 눈빛 잔광 (뒤로 흐름)
	v.draw_line(eye + hu * 1.4 + hr * -0.6, eye + hu * 1.5 + hr * 1.8, BROW_C, 1.0) # 곧은 눈썹
	# 콧등을 가로지르는 흉터
	v.draw_line(hp.call(2.9, -0.4), hp.call(4.6, -1.5), SCAR, 1.0)
	# 입 (말할 때)
	if v.talking and int(t * 10.0) % 2 == 0:
		v.draw_rect(Rect2(hp.call(2.4, -2.6) - Vector2(0.5, 0.5), Vector2(1.6, 1.0)), Color("#8a3a3a"))


static func _cape(v: CharacterVisual, sh_b: Vector2, sh_f: Vector2, flow: Vector2, t: float, u: Vector2, rt: Vector2) -> void:
	# 어깨에서 종아리까지 내려오는 진홍 망토. 서 있어도 등 뒤로 자락이 퍼져 보이고, flow만큼 뒤로 날리며 물결친다
	var top_b := sh_b + u * 1.2 + rt * -0.8
	var top_f := sh_f + u * 1.4 + rt * 0.4
	var down := -u * 25.0
	var back_hem := top_b + down + Vector2(-7.0, 0) + flow
	var front_hem := top_b + down * 0.95 + Vector2(1.0, 0) + flow * 0.78
	# 앞으로 휘말려도 자락이 꼬이지 않게: 뒤 자락은 늘 앞 자락보다 뒤에
	back_hem.x = minf(back_hem.x, front_hem.x - 4.0)
	back_hem.y = maxf(back_hem.y, top_b.y + 6.0)
	front_hem.y = maxf(front_hem.y, back_hem.y + 3.0) # 앞 자락이 늘 뒤 자락보다 아래 (빠르게 달려도 꼬이지 않게)
	var pts := PackedVector2Array([top_f, top_b])
	# 뒤쪽 가장자리 (위 → 아래, 바깥으로 불룩)
	for i in range(1, 5):
		var k := i / 5.0
		var bulge := sin(k * PI) * 2.0
		var p := top_b.lerp(back_hem, k) + Vector2(-bulge, 0) + rt * sin(t * 2.6 + k * 3.0) * 0.7 * k
		pts.append(p)
	# 자락 (뒤 → 앞), 물결
	for i in 7:
		var k2 := i / 6.0
		var edge_k := clampf(k2 * (1.0 - k2) * 4.0, 0.0, 1.0) # 양 끝에서는 물결 없음 (꼬임 방지)
		var p2 := back_hem.lerp(front_hem, k2) + Vector2(0, (sin(t * 3.2 + k2 * 5.0) * 0.9 + (1.0 if i % 2 == 0 else -0.3)) * edge_k)
		pts.append(p2)
	# 앞쪽 가장자리 (아래 → 위, 몸 뒤에 숨는 쪽)
	for i in range(4, 0, -1):
		var k3 := i / 5.0
		pts.append(top_f.lerp(front_hem, k3))
	KArt.poly(v, DrawKit.grow_poly(pts, 1.0), OUT)
	KArt.poly(v, pts, CAPE)
	# 안감(그늘): 몸 쪽 절반
	var inner := PackedVector2Array([top_f, top_f.lerp(front_hem, 0.55), front_hem, front_hem.lerp(back_hem, 0.28), top_b.lerp(back_hem, 0.35).lerp(top_f.lerp(front_hem, 0.35), 0.5)])
	KArt.poly(v, inner, CAPE_D)
	# 주름 (위에서 자락으로 퍼지는 선)
	for i in 3:
		var k4 := 0.2 + i * 0.25
		var a := top_b.lerp(top_f, k4 * 0.5)
		var b := back_hem.lerp(front_hem, k4) + Vector2(0, sin(t * 3.2 + k4 * 5.0))
		v.draw_line(a.lerp(b, 0.3), b, CAPE_D.lerp(CAPE, 0.35), 1.0)
	# 빛 받은 바깥 가장자리
	v.draw_line(top_b, top_b.lerp(back_hem, 0.6) + Vector2(-1.5, 0), CAPE_L, 1.0)
	v.draw_line(back_hem + Vector2(0, 1), back_hem.lerp(front_hem, 0.35) + Vector2(0, 1), CAPE_L.darkened(0.15), 1.0)
	# 은사자 문장 (망토 가운데, 바깥 쪽)
	var crest_at := top_b.lerp(back_hem, 0.42).lerp(top_f.lerp(front_hem, 0.42), 0.25)
	_mini_lion(v, crest_at)


## 망토의 작은 은사자 (5px 정도)
static func _mini_lion(v: CanvasItem, c: Vector2) -> void:
	v.draw_circle(c + Vector2(0.5, -1.2), 1.6, ARMOR_L)
	v.draw_rect(Rect2(c + Vector2(-1.5, -0.4), Vector2(2.6, 2.4)), ARMOR)
	v.draw_line(c + Vector2(-1.5, 1.8), c + Vector2(-2.6, 3.0), ARMOR, 1.0)
	v.draw_line(c + Vector2(1.0, 1.8), c + Vector2(1.6, 3.0), ARMOR, 1.0)
	v.draw_rect(Rect2(c + Vector2(1.6, -1.6), Vector2(1, 1)), ARMOR_L)


static func _scabbard(v: CharacterVisual, hip: Vector2, u: Vector2, rt: Vector2, mode: String, lean: float, wood: bool) -> void:
	if wood:
		return # 대련 때는 칼집 없이 목검만
	var mouth := hip + rt * 1.2 + u * 1.0
	var dir := Vector2.from_angle(PI * 0.74 + lean * 0.4) if mode != "drawready" else Vector2.from_angle(PI - 0.12 + lean * 0.3)
	var tip := mouth + dir * (15.0 if mode != "drawready" else 18.0)
	v.draw_line(mouth, tip, OUT, 3.6)
	v.draw_line(mouth, tip, Color("#2a1c18"), 2.0)
	v.draw_line(mouth + dir * 2.0, tip - dir * 2.0, LEATHER.lightened(0.15), 1.0)
	v.draw_line(tip - dir * 2.5, tip, ARMOR, 2.0) # 칼집 끝 장식
	v.draw_line(mouth, mouth + dir * 2.0, ARMOR, 2.4)
	if mode == "sheathed":
		# 칼집에 든 검의 자루 (앞으로 비스듬히)
		var hd := -dir
		_hilt(v, mouth, hd, false, 0.0)


static func _hilt(v: CanvasItem, guard: Vector2, back_dir: Vector2, wood: bool, warn: float) -> void:
	# guard에서 back_dir 방향으로 자루가 뻗는다
	var side := Vector2(-back_dir.y, back_dir.x)
	var g_col := WOOD_D if wood else ARMOR_L
	v.draw_line(guard - side * 3.0, guard + side * 3.0, OUT, 3.0)
	v.draw_line(guard - side * 2.6, guard + side * 2.6, g_col, 1.6)
	var end := guard + back_dir * 5.5
	v.draw_line(guard, end, OUT, 3.4)
	v.draw_line(guard, end, WOOD_D if wood else GRIP, 1.8)
	if not wood:
		for i in 2:
			var p := guard + back_dir * (1.8 + i * 1.8)
			v.draw_line(p - side * 0.9, p + side * 0.9, GRIP.lightened(0.3), 1.0)
	v.draw_circle(end + back_dir * 0.8, 1.5, OUT)
	v.draw_circle(end + back_dir * 0.8, 1.0, WOOD if wood else GOLD)


static func _sword(v: CharacterVisual, guard: Vector2, dir: Vector2, t: float, warn: float, wood: bool, rig: Dictionary) -> void:
	var side := Vector2(-dir.y, dir.x)
	var tip := guard + dir * BLADE_LEN
	if warn > 0.0:
		var pulse := 0.5 + 0.5 * sin(t * 40.0)
		v.draw_line(guard + dir * 2.0, tip, Color(DANGER, 0.22 + 0.4 * warn * pulse), 6.0)
		v.draw_line(guard + dir * 2.0, tip, Color(DANGER, 0.5 * warn), 3.0)
	if wood:
		v.draw_line(guard, tip, OUT, 4.4)
		v.draw_line(guard, tip - dir * 0.5, WOOD, 2.6)
		v.draw_line(guard + side * 0.6, tip - dir * 1.5 + side * 0.6, WOOD.lightened(0.2), 1.0)
		v.draw_line(guard + dir * 6.0, guard + dir * 7.0, WOOD_D, 2.0)
	else:
		# 가늘고 긴 칼날: 바탕 + 어두운 등 + 밝은 날 + 뾰족한 끝
		var blade := PackedVector2Array([guard + side * 1.1, tip - dir * 2.5 + side * 0.9, tip, tip - dir * 2.5 - side * 0.9, guard - side * 1.1])
		KArt.poly(v, DrawKit.grow_poly(blade, 0.9), OUT)
		KArt.poly(v, blade, BLADE)
		v.draw_line(guard - side * 0.6, tip - dir * 2.5 - side * 0.5, BLADE_D, 1.0)
		v.draw_line(guard + dir * 1.0, guard + dir * (BLADE_LEN - 4.0), Color(1, 1, 1, 0.75), 1.0) # 피 홈의 빛
		# 칼날 위를 지나가는 빛 반사 점
		var cyc := fmod(t + 1.3, 2.6)
		if cyc < 0.45:
			var gp := guard + dir * lerpf(2.0, BLADE_LEN - 1.0, cyc / 0.45)
			v.draw_rect(Rect2(gp - Vector2(1, 1), Vector2(2, 2)), Color.WHITE)
			v.draw_line(gp - side * 2.0, gp + side * 2.0, Color(1, 1, 1, 0.5), 1.0)
	_hilt(v, guard, -dir, wood, warn)


## 일섬 발도 자세의 칼자루 (칼집에 든 채 앞으로 비스듬히). 모일수록 코등이에 빛이 맺힌다
static func _drawready_hilt(v: CharacterVisual, guard: Vector2, out_dir: Vector2, wood: bool, warn: float, aura: float) -> void:
	_hilt(v, guard, out_dir, wood, warn)
	if aura > 0.0:
		var k := aura
		v.draw_circle(guard, 1.0 + k * 2.5, Color(1, 0.95, 0.8, 0.3 + 0.5 * k))
		if k > 0.85:
			# 터지기 직전: 칼집 입구에서 반짝
			KArt.star4(v, guard + Vector2(0, -1), 3.0 + (k - 0.85) * 30.0, Color(1, 1, 1, 0.9))
	if warn > 0.0:
		v.draw_circle(guard, 3.0 + warn * 2.0, Color(DANGER, 0.35 * warn))


## 베기 궤적: 어깨를 중심으로 a0 → a1 방향으로 쓸고 지나간 초승달 (pt초 동안 옅어짐)
static func _slash_arc(v: CharacterVisual, center: Vector2, a0: float, a1: float, pt: float, wood: bool) -> void:
	var life := 0.2
	if pt > life:
		return
	var k := 1.0 - pt / life
	var r_out := 27.0
	var r_in := 17.0 + (1.0 - k) * 6.0
	var n := 10
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		pts.append(center + Vector2.from_angle(a) * r_out)
	for i in range(n, -1, -1):
		var f := float(i) / n
		var a2 := lerpf(a0, a1, f)
		pts.append(center + Vector2.from_angle(a2) * lerpf(r_out - 1.0, r_in, f))
	var col := Color(0.95, 0.97, 1.0, 0.7 * k) if not wood else Color(0.95, 0.85, 0.7, 0.5 * k)
	KArt.poly(v, pts, col)
	var edge := PackedVector2Array()
	for i in n + 1:
		edge.append(center + Vector2.from_angle(lerpf(a0, a1, float(i) / n)) * (r_out + 0.5))
	v.draw_polyline(edge, Color(1, 1, 1, 0.9 * k), 1.0)


## 일섬을 모으는 기운: 발밑 먼지와 위로 솟는 가는 바람 줄
static func _aura(v: CharacterVisual, hip: Vector2, k: float, t: float) -> void:
	for i in 7:
		var x := -12.0 + i * 4.5 + sin(i * 2.1) * 2.0
		var ph := fmod(t * 1.6 + i * 0.37, 1.0)
		var y0 := -2.0 - ph * 30.0 * (0.5 + k)
		v.draw_line(Vector2(x, y0), Vector2(x, y0 - 4.0 - 6.0 * k), Color(1.0, 0.95, 0.85, 0.35 * k * (1.0 - ph)), 1.0)
	for i in 4:
		var ph2 := fmod(t * 2.2 + i * 0.25, 1.0)
		var dx := (ph2 * 10.0 + 4.0) * (1 if i % 2 == 0 else -1)
		v.draw_rect(Rect2(Vector2(dx, -1.0 - ph2 * 3.0), Vector2(1.5, 1.5)), Color(0.75, 0.72, 0.8, 0.6 * (1.0 - ph2) * k))

