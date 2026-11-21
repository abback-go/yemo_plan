## 움직임 시험 C(?anim=c): 세라피나 부위 뼈대 — 부위 그림(assets/anim/sera_*.png)을 관절 계층(data/anim_rig.gd AnimRig.SERA)대로
## 매 프레임 계산해 그린다(순운동학). Skeleton2D 대신 Node2D 하나 + 부위 Sprite2D: 부위가 단단한 판이라 가중치 변형이 필요 없고,
## 그리는 순서(z)를 관절 계층과 따로 정할 수 있다(망토는 몸통의 자식이지만 팔보다 뒤).
## 움직임 값(공격·피격)은 FX.anim 으로, 땋은 머리·망토의 늦게 따라오는 흔들림은 FX 연출 시계로 적분 → 일시정지하면 함께 멈춘다.
## 좌표: 뒷모습 spr_hero_back.png 틀(507×1100). BattleView 의 body 안에서 뒷모습 그림과 같은 자리·크기로 놓인다(build).
class_name SeraRig
extends Node2D

const HIT_SHADER := preload("res://ui/shaders/hit_ink.gdshader")
const SHADE_SHADER := preload("res://ui/shaders/shade.gdshader")

var parts := {}        # 이름 → {"d": 데이터, "spr", "rot", "off", "sc", "skew", "t": 계산된 변환}
var order: Array = []  # 계산 순서 (부모 먼저 — 데이터 순서)
var hit_mats: Array = []
var shade_mats: Array = []
# 움직임 값: breath 0~1 (BattleAnim 이 넘김), lean −0.4(젖힘)~1(쏠림), arm 성검 팔 각, hurt 0~1, step 위로 디딤(px), dir 대상 쪽(−1~1)
var drive := {"lean": 0.0, "arm": 0.0, "hurt": 0.0, "step": 0.0, "dir": 0.0, "side": 1.0}
# 늦게 따라오는 부위(용수철): 각도·속도
var spring := {"braid": [0.0, 0.0], "cape": [0.0, 0.0]}
var _last := -1.0


## size: 뒷모습 그림이 그려지는 크기(BattleView ally_box), base_y: 그림 위 끝의 화면 y(그림자 셰이더용)
func build(size: Vector2, base_y: float) -> void:
	var rig: Dictionary = AnimRig.SERA
	var fr := Vector2(rig.frame[0], rig.frame[1])
	var k := size.y / fr.y
	position = Vector2(-size.x / 2.0, 0)
	scale = Vector2(k, k)
	var list: Array = rig.parts
	for d in list:
		order.append(d.name)
		parts[d.name] = {"d": d, "rot": 0.0, "off": Vector2.ZERO, "sc": Vector2.ONE, "skew": 0.0, "t": Transform2D.IDENTITY}
	# 그리는 순서: z (같으면 데이터 순서)
	var drawn := list.duplicate()
	drawn.sort_custom(func(a, b): return int(a.z) < int(b.z) or (int(a.z) == int(b.z) and list.find(a) < list.find(b)))
	for d in drawn:
		var tex := Assets.tex(str(d.file))
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.centered = false
		var ts := Vector2(tex.get_size()) if tex else Vector2.ONE
		var want := Vector2(d.size[0], d.size[1])
		var m := ShaderMaterial.new()
		m.shader = HIT_SHADER
		m.set_shader_parameter("v0", float(d.pos[1]) / fr.y)
		m.set_shader_parameter("v1", (float(d.pos[1]) + want.y) / fr.y)
		spr.material = m
		hit_mats.append(m)
		add_child(spr)
		# 거대 존재 그림자(뒷모습의 _shade_of 와 같은 셰이더): 부위마다 같은 모양의 검은 덮개
		var sh := Sprite2D.new()
		sh.texture = tex
		sh.centered = false
		var sm := ShaderMaterial.new()
		sm.shader = SHADE_SHADER
		var y0 := base_y + float(d.pos[1]) * k
		sm.set_shader_parameter("y0", y0)
		sm.set_shader_parameter("y1", y0 + want.y * k)
		sh.material = sm
		shade_mats.append(sm)
		add_child(sh)
		parts[d.name].spr = spr
		parts[d.name].shade = sh
		parts[d.name].tsc = want / ts
	_solve()


func _v(a) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))


## 관절 계층대로 변환 계산 → 부위 그림에 적용
func _solve() -> void:
	for n in order:
		var p: Dictionary = parts[n]
		var d: Dictionary = p.d
		var piv := _v(d.pivot)
		var parent_t := Transform2D.IDENTITY
		var parent_piv := Vector2.ZERO
		if parts.has(str(d.parent)):
			parent_t = parts[d.parent].t
			parent_piv = _v(parts[d.parent].d.pivot)
		var origin: Vector2 = piv - parent_piv + p.off
		if str(d.parent) == "root":
			origin += Vector2(0, -float(drive.step))
		p.t = parent_t * Transform2D(float(p.rot), p.sc, float(p.skew), origin)
		var xf: Transform2D = p.t * Transform2D(0.0, _v(d.pos) - piv)
		xf = xf * Transform2D(0.0, p.tsc, 0.0, Vector2.ZERO)
		p.spr.transform = xf
		p.shade.transform = xf


func _pose(n: String, rot := 0.0, off := Vector2.ZERO, sc := Vector2.ONE, skew := 0.0) -> void:
	var p: Dictionary = parts[n]
	p.rot = rot
	p.off = off
	p.sc = sc
	p.skew = skew


## 매 프레임 (BattleAnim.tick): now = FX 연출 시계(ms), b = 숨쉬기 0~1, red = 움직임 줄이기 배율
func tick(now: float, b: float, red: float) -> void:
	var dt := 0.0 if _last < 0.0 else clampf((now - _last) / 1000.0, 0.0, 0.05)
	_last = now
	var lean: float = drive.lean * red
	var arm: float = drive.arm * red
	var hurt: float = drive.hurt * red
	var dir: float = drive.dir
	var side: float = drive.side
	var fwd := maxf(lean, 0.0)
	# 몸통: 허리를 축으로 숨쉬기(세로 1.2%) · 대상 쪽으로 기울기 · 맞으면 뒤로 젖힘
	var torso_rot := 0.07 * lean * dir - 0.06 * hurt * side
	_pose("torso", torso_rot, Vector2(0, 8.0 * hurt), Vector2(1.0 - 0.004 * b, 1.0 + 0.012 * b * red - 0.03 * fwd + 0.02 * hurt))
	# 머리: 숨에 살짝 끄덕, 맞으면 젖혀짐
	var hair_rot := -0.015 * b * red - 0.03 * lean * dir + 0.09 * hurt * side
	_pose("hair", hair_rot)
	# 왼팔: 숨에 아주 조금, 휘두를 때 균형(바깥으로), 맞으면 움찔
	_pose("arm_l_up", 0.012 * b * red + 0.22 * fwd + 0.2 * hurt)
	_pose("arm_l_lo", 0.02 * b * red + 0.18 * fwd + 0.15 * hurt)
	# 성검 든 팔: 들어 올렸다(arm < 0) 앞으로 내리침(arm > 0)
	_pose("sword", -0.01 * b * red + arm - 0.16 * hurt)
	# 어깨받이: 숨에 따라 조금 올라감
	_pose("pauld_l", 0.0, Vector2(0, -2.0 * b * red))
	_pose("pauld_r", 0.0, Vector2(0, -2.0 * b * red))
	# 늦게 따라오는 부위: 몸통·머리가 기운 만큼 반대로 끌려가다 흔들리며 제자리로
	var sway := sin(now / 1900.0 * TAU) * 0.015 * red
	_spring("braid", -(torso_rot + hair_rot) * 0.9 + sway, dt, 70.0, 7.0)
	_spring("cape", -torso_rot * 0.8 + sway * 0.5, dt, 50.0, 6.0)
	_pose("braid", spring.braid[0])
	_pose("cape", 0.0, Vector2.ZERO, Vector2(1.0, 1.0 + 0.006 * b * red), spring.cape[0] * 0.6)
	_solve()


func _spring(n: String, target: float, dt: float, k: float, damp: float) -> void:
	var s: Array = spring[n]
	if dt <= 0.0:
		return
	# 작은 단계로 나눠 적분 (프레임이 길어도 튀지 않게)
	var steps := maxi(1, ceili(dt / 0.008))
	var h := dt / steps
	for i in steps:
		var acc: float = -k * (float(s[0]) - target) - damp * float(s[1])
		s[1] += acc * h
		s[0] += s[1] * h


## 공격: 성검 든 팔을 들어 올리며 몸을 젖혔다가(준비) → 대상 쪽으로 몸을 기울이며 내리침 → 잠깐 멈춤 → 제자리
## 반환: {"hit": 내리치는 순간 끝나는 Anim, "done": 다 끝나는 Anim} (BattleView.ally_strike 와 같은 모양)
func strike(dir: float) -> Dictionary:
	drive.dir = dir
	var T := 640.0
	var main := FX.anim(T, [
		{"o": 0.0, "lean": 0.0, "arm": 0.0, "step": 0.0, "e": "ease-out"},
		{"o": 200.0 / T, "lean": -0.4, "arm": -1.9, "step": 0.0, "e": "cubic-bezier(.55,0,.9,.45)"},   # 성검을 머리 위 오른쪽으로 들어 올림
		{"o": 300.0 / T, "lean": 1.0, "arm": 0.35, "step": 14.0, "e": "linear"},                        # 앞으로 내리침
		{"o": 380.0 / T, "lean": 1.0, "arm": 0.3, "step": 14.0, "e": "cubic-bezier(.2,.7,.3,1)"},
		{"o": 1.0, "lean": 0.0, "arm": 0.0, "step": 0.0}], func(v):
			drive.lean = v.lean
			drive.arm = v.arm
			drive.step = v.step, {"node": self, "key": "rig_strike_%d" % get_instance_id()})
	var hit := FX.anim(300, [{"x": 0.0}, {"x": 1.0}], Callable())
	return {"hit": hit, "done": main}


## 맞음: 몸이 뒤로 젖혀지고 머리·팔이 움찔 → 땋은 머리·망토가 따라 흔들림. side: 맞은 쪽(1 = 오른쪽에서)
func hurt(side := 1.0) -> void:
	drive.side = side
	FX.anim(460, [{"o": 0.0, "h": 0.0, "e": "ease-out"}, {"o": 0.13, "h": 1.0, "e": "ease-in-out"}, {"o": 1.0, "h": 0.0}], func(v):
		drive.hurt = v.h, {"node": self, "key": "rig_hurt_%d" % get_instance_id()})
