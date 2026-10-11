extends Node
## 시험용: 낙성·대마법·메아리 천열·마녀 문장을 실행기 eval로 바로 띄운다 (에스카 입력 연결과 상관없이 연출·피해를 본다).
## 시나리오에서 [2, "attach", "../tools/test/eska_magic_cast.gd"] 로 붙이고
## [f, "eval", "get_node('MagicCast').cast('blackstar', 1.0, 1.0)"] 처럼 부른다 (종류: nakseong · blackstar · meteor · doom · flurry · sigil).


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
