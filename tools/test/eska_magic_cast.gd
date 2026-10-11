extends Node
## 시험용: 낙성·대마법·메아리 천열·마녀 문장을 실행기 eval로 바로 띄운다 (에스카 입력 연결과 상관없이 연출·피해를 본다).
## 시나리오에서 [2, "attach", "../tools/test/eska_magic_cast.gd"] 로 붙이고
## [f, "eval", "get_node('MagicCast').cast('blackstar', 1.0, 1.0)"] 처럼 부른다 (종류: nakseong · blackstar · meteor · doom · flurry · sigil).
## 루프2: 시험용 발사체(TestOrb — 그룹 es_projectile, deflect(by) -> bool) · 틈 등록부(ERifts) 조회·스며들기 · 흑성 물약 빨아들이기.

var absorbed_hits := 0 ## absorb_test의 apply가 불린 수 (흑성은 빨아들일 때 + 붕괴 직전 두 번 부름)


func _ready() -> void:
	name = "MagicCast"


## kind를 에스카 발 위치에 띄운다. power = 피해 배수, size = eska.mods.size (확장 물약)
func cast(kind: String, power := 1.0, size := 1.0) -> String:
	var eska: EEska = get_parent().get("eska")
	eska.mods["size"] = size
	var n: Node2D
	match kind:
		"nakseong":
			n = EMagicFx.Nakseong.new()
		"blackstar":
			n = EMagicFx.BlackStar.new()
		"meteor":
			n = EMagicFx.MeteorShower.new()
		"doom":
			n = EMagicFx.DoomMeteor.new()
		"flurry":
			n = ESkillFx.Flurry.new()
		"sigil":
			EVfx.sigil(eska.global_position + Vector2(eska.facing * 8.0, -26.0), size)
			EVfx.sigil(eska.global_position + Vector2(-eska.facing * 4.0, -20.0) + Vector2(0, -40), 2.5)
			return "sigil"
		_:
			return "unknown " + kind
	n.set("eska", eska)
	n.set("dir", eska.facing)
	n.set("power", power)
	EVfx.add(n, eska.global_position, false)
	return "%s power=%.2f size=%.2f" % [kind, power, size]


## 찢긴 틈 그림 비용(µs): 44마디 긴 틈(별 있음/없음) · 기본 참격 하나가 꽉 벌어진 순간
func rift_bench(n := 200) -> String:
	var pd := PDraw.new()
	var r: Array = EVfx.rift_line(Vector2.ZERO, Vector2(400, 0), 14.0, 44, 3, 4.0)
	var oz: Array = EVfx.rift_open(r[2], 1.0, 0.0, 1.0, 1.0)
	var out := ""
	var t0 := Time.get_ticks_usec()
	for i in n:
		EVfx.rift(pd, r[0], r[1], oz[0], oz[1], 3, 0.5, 0.0, 1.0)
		pd.clear()
	out += "rift44=%.1f " % (float(Time.get_ticks_usec() - t0) / n)
	t0 = Time.get_ticks_usec()
	for i in n:
		EVfx.rift(pd, r[0], r[1], oz[0], oz[1], 3, 0.5, 0.0, 0.0)
		pd.clear()
	out += "rift44_nostars=%.1f " % (float(Time.get_ticks_usec() - t0) / n)
	var sl := ESkillFx.Slash.new()
	sl.setup(EEska.SLASH, 1, true)
	sl.t = 0.08
	t0 = Time.get_ticks_usec()
	for i in n:
		sl._paint()
		sl.pd.clear()
	out += "slash=%.1f " % (float(Time.get_ticks_usec() - t0) / n)
	sl.free()
	t0 = Time.get_ticks_usec()
	for i in n:
		EVfx.dark_band(pd, 140.0, -3.49, 2.79, 44.0, 1.0, 3, 30) # 예전 참격 몸통 (비교용)
		pd.clear()
	out += "old_dark_band=%.1f " % (float(Time.get_ticks_usec() - t0) / n)
	return out


## 표적 체력을 넉넉하게 (허수아비는 0이 되면 다시 가득 차서 큰 피해를 셀 수 없음)
func big_hp() -> String:
	for d: Node in ETarget.all(get_tree()):
		d.set("max_hp", 99999)
		d.set("hp", 99999)
	return "ok"


## 표적들이 잃은 체력 (99999 기준)
func lost() -> String:
	var out := ""
	for d: Node in ETarget.all(get_tree()):
		out += "%s:%d " % [d.name, 99999 - int(d.get("hp"))]
	return out


## 시험용 발사체 하나: (x, y)에서 (vx, vy)로 날아감. 단공이 지우면 사라지고 deflected가 는다
func orb(x: float, y: float, vx: float, vy: float) -> String:
	var o := TestOrb.new()
	o.vel = Vector2(vx, vy)
	get_parent().add_child(o)
	o.global_position = Vector2(x, y)
	return "orb at %d,%d" % [int(x), int(y)]


## 발사체 상태: 남은 수 · 지워진 수 · 단공 쿨다운 · 종언 게이지
func orbs() -> String:
	var alive := get_tree().get_nodes_in_group("es_projectile").size()
	var eska: EEska = get_parent().get("eska")
	return "alive=%d deflected=%d dangong_cd=%.2f gauge=%.0f" % [alive, TestOrb.deflected, float(eska.cooldowns["dangong"]), eska.gauge]


## 틈 등록부: (x, y) 둘레 r 안에 열린 틈 (번호·남은 시간)
func rift_at(x: float, y: float, r: float) -> String:
	var rf := ERifts.at(Vector2(x, y), r)
	if rf.is_empty():
		return "none"
	return "id=%d left=%.2f pts=%d" % [int(rf.id), ERifts.left(int(rf.id)), (rf.pts as PackedVector2Array).size()]


## (x, y) 둘레 열린 틈에 물약을 스며들게 하고 1초 더 열어 둠 (흐린 물 흉내)
func infuse_test(x: float, y: float, r: float, extend := 0.0) -> String:
	var rf := ERifts.at(Vector2(x, y), r)
	if rf.is_empty():
		return "none"
	ERifts.infuse(rf, "bind", Color("#e8a33a"))
	if extend > 0.0:
		ERifts.extend(rf, extend)
	return "infused id=%d left=%.2f" % [int(rf.id), ERifts.left(int(rf.id))]


## 지금 흑성에 물약 빨아들이기 (apply가 불린 수는 absorbed_hits)
func absorb_test() -> String:
	var bs := EMagicFx.active_blackstar()
	if bs == null:
		return "no blackstar"
	var ok: bool = bs.call("absorb", "rot", Color("#7fd66b"), func() -> int:
		absorbed_hits += 1
		return EMagicFx.targets_in(get_tree(), bs.call("pull_center"), bs.call("pull_radius")).size())
	return "absorb=%s center=%s r=%.0f" % [ok, bs.call("pull_center"), bs.call("pull_radius")]


## 흑성 apply가 돌려준 걸린 적 수 합
func absorb_count() -> String:
	for n: Node in Fx.effect_parent().get_children():
		if n is EMagicFx.BlackStar:
			return "calls=%d applied=%d" % [absorbed_hits, int(n.get("applied_count"))]
	return "calls=%d" % absorbed_hits


## 낙성이 노린 자리 (마지막으로 만든 낙성)
func nak_aim() -> String:
	var out := "none"
	for n: Node in Fx.effect_parent().get_children():
		if n is EMagicFx.Nakseong:
			out = "aim=%s" % ((n as EMagicFx.Nakseong).aim + (n as Node2D).position)
	return out


## 시험용 발사체: 붉보라 구슬. 그룹 es_projectile에 들고 deflect(by)를 가진다 (검성·술사 발사체가 지킬 약속과 같은 모양)
class TestOrb extends Node2D:
	static var deflected := 0
	var vel := Vector2.ZERO
	var t := 0.0

	func _ready() -> void:
		add_to_group("es_projectile")
		z_index = 5

	func deflect(_by: Node2D) -> bool:
		deflected += 1
		queue_free()
		return true

	func _process(delta: float) -> void:
		t += delta
		position += vel * delta
		if t > 4.0:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		draw_circle(Vector2.ZERO, 7.0, Color(0.9, 0.2, 0.45, 0.35))
		draw_circle(Vector2.ZERO, 4.5, Color(1.0, 0.45, 0.6))
		draw_circle(Vector2.ZERO, 2.0, Color(1, 1, 1))


## 봉공(공간 고정)을 바로 건다 (흑성 렌즈가 꺼지는지 보기)
func still(sec := 3.0) -> String:
	EStill.cast(get_parent().get("eska"), sec, 0.0)
	return "still %.1f" % sec


## 흑성 렌즈가 지금 보이는지
func lens() -> String:
	for n: Node in Fx.effect_parent().get_children():
		if n is EMagicFx.BlackStar:
			var l: Node2D = n.get("_lens")
			return "lens_visible=%s still=%s" % [l.visible, EStill.active()]
	return "none"


## 찢김 렌즈(EVfx.dark_burst) 하나를 (x, y)에
func lens_test(x: float, y: float, rad: float) -> String:
	EVfx.dark_burst(Vector2(x, y), rad)
	return "lens"


## 이펙트 층의 노드들 (성능: 무엇이 노드·그리기 호출을 늘리는지)
func fx_nodes() -> String:
	var names := {}
	var kids := Fx.effect_parent().get_children()
	for n: Node in kids:
		var sc: Script = n.get_script()
		var nm := String(n.get_class())
		if sc != null:
			nm = sc.get_global_name() if sc.get_global_name() != "" else sc.resource_path.get_file() + ":" + str(n.get_class())
			var p := n as Node2D
			if p != null and p.get_script() != null and nm.ends_with(":Node2D"):
				nm = str(p.get("life")) + "/" + nm if p.get("life") != null else nm
		names[nm] = int(names.get(nm, 0)) + 1
	return "n=%d %s" % [kids.size(), names]


## 그림 노드별 삼각형 수 (PDraw를 쓰는 노드만, 큰 순) — 과부하 도형 수 원인 찾기
func prims(top := 12) -> String:
	var rows := []
	for node: Node in get_tree().current_scene.find_children("*", "", true, false):
		if node.has_method("_paint") and node.get("pd") is PDraw and (node as CanvasItem).is_visible_in_tree():
			var pd: PDraw = node.get("pd")
			pd.clear()
			node.call("_paint")
			var nm := _class_name(node)
			rows.append([pd.idx.size() / 3, nm])
			pd.clear()
	rows.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) > int(b[0]))
	var out := ""
	var total := 0
	for r: Array in rows:
		total += int(r[0])
	for i in mini(top, rows.size()):
		out += "%s=%d " % [rows[i][1], rows[i][0]]
	return "total=%d %s" % [total, out]



## 노드의 스크립트 이름 (안쪽 클래스면 "바깥.안쪽")
func _class_name(node: Node) -> String:
	var sc: Script = node.get_script()
	if sc == null:
		return node.get_class()
	if sc.get_global_name() != "":
		return sc.get_global_name()
	for outer: Script in [ESkillFx, EMagicFx, EVfx, EMoveFx, ERifts, EKenseiFx, EBossStage, EPotionFx, EScenery, EKensei, EFoeFx, PVfx]:
		var m: Dictionary = outer.get_script_constant_map()
		for k: String in m:
			if m[k] is Script and _inherits(sc, m[k]) and sc == m[k]:
				return "%s.%s" % [outer.get_global_name(), k]
	return "?" + node.name


func _inherits(a: Script, b: Script) -> bool:
	return a == b


## 피해 숫자 층 보이기/숨기기 (성능: 숫자 글자가 도형을 얼마나 쓰는지)
func nums(show: bool) -> String:
	var n: Node2D = PVfx.Numbers.inst
	if not is_instance_valid(n):
		return "none"
	n.visible = show
	return "items=%d" % (n.get("items") as Array).size()
