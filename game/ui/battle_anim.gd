## 움직임 시험 (밤샘 계획 4) — 주소 옵션 ?anim=a | ?anim=c (헤드리스·데스크톱 --anim=a | --anim=c).
## 옵션이 없으면 만들지 않는다(BattleView.anim = null) → 기본 화면은 그대로.
## A′(a): 동료 뒷모습·적에 코드 효과만(그림은 그대로)
##   - 공격: 발을 디딘 채 대상 쪽으로 몸이 기울었다(앞으로 쏠림 — 뒷모습은 화면 위쪽이 앞) 돌아옴. 적은 반대로 아래·앞(화면 쪽)으로 쏠림
##   - 맞음: 짧은 흔들림 + 붉은 잉크 번짐(셰이더 hit_ink: 위에서부터 진홍이 스며 내려갔다 빠짐)
##   - 대기: 숨쉬기 — 발을 축으로 세로 크기 1~1.5%, 인물마다 주기·위상이 다르다
## C(c): 세라피나만 부위 뼈대(SeraRig) — 대기·공격·피격. 다른 동료·적은 기본 움직임 그대로.
## 시간은 모두 FX 연출 시계(FX.anim·FX.now_ms) → 일시정지하면 함께 멈춘다. 쓰러짐·죽음·데스신·짓밟기 연출은 건드리지 않는다
## (그 연출들이 움직이는 node·pose 와 따로, 이 파일은 body(동료)·안쪽 노드(적)만 움직인다).
class_name BattleAnim
extends RefCounted

const HIT_SHADER := preload("res://ui/shaders/hit_ink.gdshader")
const BREATH := 0.013        # 숨쉬기 세로 크기 (1.3%)
const PERIODS := [3900.0, 3400.0, 4400.0]   # 숨 주기(ms) — 인물마다 다르게
const LEAN := {"hero": 0.11, "warrior": 0.085, "archer": 0.06}   # 공격 때 기우는 정도(skew, rad)

var mode := ""
var view: BattleView
var al := {}   # 동료 id → {"body", "h", "skew", "sy", "dy", "p", "mats", "i", ("rig")}
var en := {}   # 적 id → {"lean": Node2D, "h", "skew", "sy", "dy", "p", "mats", "i"}


static func mode_of(params: Dictionary) -> String:
	var m := str(params.get("anim", "")).to_lower()
	return m if m == "a" or m == "c" else ""


static func create(v: BattleView) -> BattleAnim:
	var m := mode_of(G.params)
	if m == "":
		return null
	var b := BattleAnim.new()
	b.mode = m
	b.view = v
	return b


func has_ally(id: String) -> bool:
	return al.has(id)


func has_enemy(id: String) -> bool:
	return en.has(id)


func _red() -> float:
	return 0.3 if FX.reduced else 1.0


# ───────── 만들기 (BattleView._make_ally · make_enemy 끝에서) ─────────
## a: 모든 동료 / c: 세라피나만 (뒷모습 그림을 숨기고 같은 자리·크기에 부위 뼈대)
func setup_ally(id: String, a: Dictionary, base_y: float) -> void:
	if mode == "c" and id != "hero":
		return
	var body: Node2D = a.body
	var box: Rect2 = a.box
	var spr := body.get_child(0) as Sprite2D
	if spr == null:
		return
	var s := {"body": body, "h": box.size.y, "skew": 0.0, "sy": 1.0, "dy": 0.0, "p": Vector2.ZERO, "mats": [], "i": GameData.D.party.order.find(id)}
	if mode == "c":
		spr.visible = false
		for sh in a.shades:
			sh.visible = false
		var rig := SeraRig.new()
		rig.name = "rig"
		rig.build(box.size, base_y)
		body.add_child(rig)
		view.shade_mats.append_array(rig.shade_mats)
		for m in rig.shade_mats:
			m.set_shader_parameter("opacity", view.shadow_v)
		s.rig = rig
		s.mats = rig.hit_mats
	else:
		var m := ShaderMaterial.new()
		m.shader = HIT_SHADER
		spr.material = m
		s.mats = [m]
	al[id] = s


## a 만: 적 그림을 안쪽 노드로 감싼다(바깥 node 는 기존 연출 — 쓰러짐·짓밟힘 — 이 그대로 움직인다). 기준점 = 발
func setup_enemy(id: String, node: Node2D) -> void:
	if mode != "a" or node.get_child_count() == 0:
		return
	var spr := node.get_child(0) as Sprite2D
	if spr == null:
		return
	var lean := Node2D.new()
	lean.name = "lean"
	node.remove_child(spr)
	lean.add_child(spr)
	node.add_child(lean)
	var m := ShaderMaterial.new()
	m.shader = HIT_SHADER
	spr.material = m
	en[id] = {"lean": lean, "h": -spr.position.y, "skew": 0.0, "sy": 1.0, "dy": 0.0, "p": Vector2.ZERO, "mats": [m], "i": en.size()}


# ───────── 매 프레임 (BattleView._process) ─────────
func tick() -> void:
	var now := FX.now_ms()
	var red := _red()
	for id in al:
		var s: Dictionary = al[id]
		if not is_instance_valid(s.body):
			continue
		var i: int = maxi(0, int(s.i))
		var b := 0.5 - 0.5 * cos((now / float(PERIODS[i % 3]) + i * 0.29 + 0.07) * TAU)
		if s.has("rig"):
			s.rig.tick(now, b, red)
			_feet(s.body, s.h, 1.0, 1.0, 0.0, s.p)
		else:
			_feet(s.body, s.h, 1.0 - BREATH * 0.3 * b * red, s.sy * (1.0 + BREATH * b * red), s.skew, s.p + Vector2(0, s.dy))
	for id in en:
		var e: Dictionary = en[id]
		if not is_instance_valid(e.lean):
			continue
		var i: int = int(e.i)
		var b := 0.5 - 0.5 * cos((now / (3100.0 + 370.0 * i) + i * 0.41) * TAU)
		var sy: float = e.sy * (1.0 + 0.009 * b * red)
		var xf := Transform2D(0.0, Vector2(e.sy * (1.0 - 0.003 * b * red), sy), float(e.skew), e.p + Vector2(0, e.dy))
		e.lean.transform = xf


## 발(그림 아래 가운데)을 축으로 크기·기울기를 준다. body 의 원점은 머리 위 가운데라 발 = (0, h)
func _feet(n: Node2D, h: float, sx: float, sy: float, skew: float, off: Vector2) -> void:
	var f := Vector2(0, h)
	var bs := Transform2D(0.0, Vector2(sx, sy), skew, Vector2.ZERO)
	n.transform = Transform2D(bs.x, bs.y, f - bs.basis_xform(f) + off)


func _dir(from: Vector2, to: Vector2) -> float:
	if not to.is_finite():
		return 0.0
	return clampf((to.x - from.x) / 520.0, -1.0, 1.0)


# ───────── 공격 ─────────
## 동료: 반환 {"hit": 타격 순간에 끝나는 Anim, "done": 다 끝나는 Anim} — BattleView.ally_strike 와 같은 모양
func strike(id: String, to: Vector2) -> Dictionary:
	var s: Dictionary = al[id]
	var dir := _dir(view.ally_anchor(id), to)
	if s.has("rig"):
		return s.rig.strike(dir)
	var red := _red()
	var k: float = float(LEAN.get(id, 0.08)) * red
	var sk := k * dir
	var up := -16.0 * red
	var T := 600.0
	var main := FX.anim(T, [
		{"o": 0.0, "k": 0.0, "sy": 1.0, "dy": 0.0, "e": "ease-out"},
		{"o": 140.0 / T, "k": -0.35 * sk, "sy": 1.0 + 0.02 * red, "dy": 3.0 * red, "e": "cubic-bezier(.5,0,.9,.5)"},   # 젖힘(준비)
		{"o": 250.0 / T, "k": sk + 0.25 * k * signf(dir), "sy": 1.0 - 0.035 * red, "dy": up, "e": "linear"},           # 앞으로 쏠림
		{"o": 320.0 / T, "k": sk + 0.25 * k * signf(dir), "sy": 1.0 - 0.035 * red, "dy": up, "e": "cubic-bezier(.2,.7,.3,1)"},
		{"o": 1.0, "k": 0.0, "sy": 1.0, "dy": 0.0}], func(v):
			s.skew = v.k
			s.sy = v.sy
			s.dy = v.dy, {"node": s.body, "key": "animA_strike_" + id})
	var hit := FX.anim(250, [{"x": 0.0}, {"x": 1.0}], Callable())
	return {"hit": hit, "done": main}


## 적: 몸을 젖혔다가 아래·앞(화면 쪽)으로 쏠리며 대상 쪽으로 기움. 반환: 타격까지의 시간(ms) — 기본(enemy_lunge)과 같은 박자
func enemy_lunge(id: String, to: Vector2) -> float:
	var m: Dictionary = GameData.D.motion.enemy
	var e: Dictionary = en[id]
	var red := _red()
	var node: Node2D = e.lean.get_parent()
	var dir := _dir(node.position if node else Vector2.ZERO, to)
	var sk := 0.09 * dir * red
	var w := float(m.windup)
	var r := float(m.rush)
	var T := w + r + float(m.back)
	FX.anim(T, [
		{"o": 0.0, "k": 0.0, "s": 1.0, "dy": 0.0, "e": "ease-out"},
		{"o": w / T, "k": -0.3 * sk, "s": 1.0 - 0.015 * red, "dy": -6.0 * red, "e": "cubic-bezier(.5,0,.9,.5)"},
		{"o": (w + r) / T, "k": sk, "s": 1.0 + 0.09 * red, "dy": 22.0 * red, "e": "cubic-bezier(.2,.7,.3,1)"},
		{"o": 1.0, "k": 0.0, "s": 1.0, "dy": 0.0}], func(v):
			e.skew = v.k
			e.sy = v.s
			e.dy = v.dy, {"node": e.lean, "key": "animA_lunge_" + id})
	return w + r


# ───────── 맞음 ─────────
func hurt(id: String) -> void:
	var s: Dictionary = al[id]
	var red := _red()
	if s.has("rig"):
		s.rig.hurt(1.0)
	_shake(s, 7.0 * red, 260.0, s.body, "animA_hurt_" + id)
	_ink(s.mats, s.body, "animA_ink_" + id)


func hit_enemy(id: String) -> void:
	if not en.has(id):
		return
	var e: Dictionary = en[id]
	_shake(e, 6.0 * _red(), 240.0, e.lean, "animA_hurtE_" + id)
	_ink(e.mats, e.lean, "animA_inkE_" + id)


## 짧은 흔들림: 옆으로 줄어드는 떨림 + 처음에 살짝 밀림
func _shake(s: Dictionary, p: float, dur: float, nd: Node, key: String) -> void:
	var fr := [{"p": Vector2.ZERO}]
	var n := 6
	for i in n:
		var k := 1.0 - float(i) / n
		fr.append({"p": Vector2((-1.0 if i % 2 else 1.0) * p * k, (3.0 if i == 0 else 0.0) * k)})
	fr.append({"p": Vector2.ZERO})
	FX.anim(dur, fr, func(v): s.p = v.p, {"node": nd, "easing": "ease-out", "key": key})


## 붉은 잉크 번짐: 위에서부터 스며 내려가며 짙어졌다가 빠진다
func _ink(mats: Array, nd: Node, key: String) -> void:
	FX.anim(440, [
		{"o": 0.0, "a": 0.0, "f": -0.1, "e": "ease-out"},
		{"o": 0.18, "a": 0.62, "f": 0.55, "e": "linear"},
		{"o": 0.45, "a": 0.5, "f": 1.15, "e": "ease-in"},
		{"o": 1.0, "a": 0.0, "f": 1.2}], func(v):
			for m in mats:
				m.set_shader_parameter("amount", v.a)
				m.set_shader_parameter("front", v.f), {"node": nd, "key": key})
