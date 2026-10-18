extends SceneTree
## 전투 규칙 자동 시험 — docs/eska-turn/combat_proto.md §25.1~§25.4의 기대값을 규칙 엔진(TBattle)으로 그대로 확인한다.
##   cd game && godot --headless --script ../tools/test/turn_rules_test.gd
## 공통 입력(§25.1): 난수 1.000 고정(fix_rand) · 크리는 적힌 경우만(fix_crit) · 패시브는 적힌 경우만(D21) · 장비 없음 · 강화 Lv1.
## 출력: 케이스마다 PASS/FAIL/SKIP, 마지막 줄 "RULES 통과 n/m" (실패가 있으면 종료 코드 1).

var _done := false
var _pass := 0
var _fail := 0


func _process(_d: float) -> bool:
	if _done:
		return true
	_done = true
	_damage_tests()
	_enemy_tests()
	_order_tests()
	_credit_tests()
	_scenario_tests()
	_edge_tests()
	_number_tests()
	print("RULES 통과 %d/%d%s" % [_pass, _pass + _fail, "" if _fail == 0 else " — 실패 %d" % _fail])
	quit(1 if _fail > 0 else 0)
	return true


func _ok(id: String, got, want) -> void:
	if str(got) == str(want):
		_pass += 1
		print("PASS %s  %s" % [id, str(got)])
	else:
		_fail += 1
		print("FAIL %s  got %s  want %s" % [id, str(got), str(want)])


func _skip(id: String, why: String) -> void:
	print("SKIP %s  %s" % [id, why])


## 시험용 전투: 난수 1.0 · 크리 아님 · 패시브 끔 · 적 체력 넉넉히
func _b(party: Array, foes, state := {}) -> TBattle:
	var b := TBattle.new()
	b.setup(party, foes, state, 1)
	b.fix_rand = 1.0
	b.fix_crit = 0
	for w in b.witches:
		w.passive = []
		w.gauge = 0.0
	for e in b.enemies:
		if e.bars.is_empty():
			e.max_hp = 1000000000
			e.hp = e.max_hp
	return b


func _w(b: TBattle, wid: String) -> TUnit:
	for w in b.witches:
		if w.id == wid:
			return w
	return null


func _e(b: TBattle, eid: String) -> TUnit:
	for e in b.enemies:
		if e.id == eid:
			return e
	return null


## 마녀 체력을 넉넉히 (적의 공격으로 쓰러지지 않게)
func _tough(b: TBattle) -> void:
	for w in b.witches:
		w.max_hp = 1000000000
		w.hp = w.max_hp


## 시험 표적: 체력 무한 · 방어율 0 · 속성 el (약점은 순환표)
func _dummy(b: TBattle, el: String) -> TUnit:
	var d := TUnit.make_enemy("straw_golem", 0)
	d.name = "시험 표적"
	d.element = el
	d.weak = []
	if String(TData.WEAK_TO.get(el, "")) != "":
		d.weak = [String(TData.WEAK_TO[el])]
	d.def_rate = 0.0
	d.max_hp = 1000000000
	d.hp = d.max_hp
	b.enemies.clear()
	b.enemies.append(d)
	return d


func _hits(ev: Array) -> Array:
	var out: Array = []
	for e in ev:
		if e.t == "hit":
			out.append(int(e.dmg))
	return out


func _first(ev: Array) -> int:
	var h := _hits(ev)
	return h[0] if not h.is_empty() else -1


func _kinds(ev: Array) -> Array:
	var out: Array = []
	for e in ev:
		out.append(String(e.t))
	return out


## 그 유닛의 차례가 올 때까지 돌린다 (다른 유닛은 행동 없이 차례만 넘김)
func _until(b: TBattle, u: TUnit) -> void:
	for i in 50:
		var a := b.next_actor()
		if a == u:
			return
		b.end_action(a)


# ═══════════════════════════════════════════════════════════
# §25.1 피해 단위 시험
# ═══════════════════════════════════════════════════════════

func _damage_tests() -> void:
	print("── §25.1 피해 (마녀 → 적)")
	var b := _b(["ignis"], ["straw_golem"])
	var ig := _w(b, "ignis")
	var g := _e(b, "straw_golem")
	_ok("D01 기본 공격 → 짚 골렘", _first(b.basic_attack(ig, g)), 18000)
	b.fix_rand = 0.95
	_ok("D02 난수 0.95", _first(b.basic_attack(ig, g)), 17100)
	b.fix_rand = 1.05
	_ok("D03 난수 1.05", _first(b.basic_attack(ig, g)), 18900)

	b = _b(["ignis"], ["straw_golem"])
	_ok("D04 태양의 창", _first(b.use_skill(_w(b, "ignis"), "sun_spear", _e(b, "straw_golem"))), 108000)

	for c in [["D05 + 풀무질, 화상 1겹", 1, 162000], ["D06 화상 3겹", 3, 270000], ["D07 화상 5겹 (상한 200%)", 5, 324000]]:
		b = _b(["ignis", "ember"], ["straw_golem"])
		b.use_skill(_w(b, "ember"), "bellows", _w(b, "ignis"))
		_e(b, "straw_golem").add_mark("burn", 3, int(c[1]))
		_ok(String(c[0]), _first(b.use_skill(_w(b, "ignis"), "sun_spear", _e(b, "straw_golem"))), int(c[2]))

	for c in [["D08 + 불의 축복 + 열기 응축", 0, 486000], ["D09 D08이 크리 (×2.0)", 1, 972000]]:
		b = _b(["ignis", "ember"], ["straw_golem"])
		ig = _w(b, "ignis")
		b.use_skill(_w(b, "ember"), "bellows", ig)
		b.use_skill(_w(b, "ember"), "blessing", null)
		b.actor = ig
		b.use_skill(ig, "focus", ig)
		_e(b, "straw_golem").add_mark("burn", 3, 3)
		b.fix_crit = int(c[1])
		_ok(String(c[0]), _first(b.use_skill(ig, "sun_spear", _e(b, "straw_golem"))), int(c[2]))

	b = _b(["eska"], ["ash_knight"])
	_ok("D10 에스카 종언 → 재의 기사", _first(b.use_skill(_w(b, "eska"), "doom", _e(b, "ash_knight"))), 91728)
	b = _b(["ignis"], ["ash_knight"])
	_e(b, "ash_knight").add_buff({"cat": "def_down", "v": 0.60, "dur": 3, "clock": "own"})
	_ok("D11 방어 다운 60% (상한 50%)", _first(b.basic_attack(_w(b, "ignis"), _e(b, "ash_knight"))), 14400)
	b = _b(["eska"], ["ash_knight"])
	_ok("D12 공간 압축 (방어 무시)", _first(b.use_skill(_w(b, "eska"), "compress", _e(b, "ash_knight"))), 46800)
	for c in [["D13 화염 부여 종언 → 짚 골렘", "straw_golem", 163800], ["D14 화염 부여 종언 → 늪 두꺼비", "swamp_toad", 87360]]:
		b = _b(["eska", "ember"], [String(c[1])])
		b.use_skill(_w(b, "ember"), "kindling", _w(b, "eska"))
		_ok(String(c[0]), _first(b.use_skill(_w(b, "eska"), "doom", b.enemies[0])), int(c[2]))
	b = _b(["ignis"], ["straw_golem"])
	_w(b, "ignis").add_buff({"cat": "final", "v": 1.20, "dur": 3, "clock": "own"})
	_ok("D15 최종 데미지 120% (상한 100%)", _first(b.basic_attack(_w(b, "ignis"), _e(b, "straw_golem"))), 36000)
	b = _b(["ignis"], ["straw_golem"])
	b.fix_crit = 1
	_w(b, "ignis").add_buff({"cat": "crit_dmg", "v": 3.50, "dur": 3, "clock": "own"})
	_ok("D16 크리 데미지 350% (상한 → ×4.5)", _first(b.basic_attack(_w(b, "ignis"), _e(b, "straw_golem"))), 81000)
	b = _b(["harpe"], ["straw_golem"])
	var t := _dummy(b, "none")
	_ok("D17 흑백 참격 2히트 (히트 하나 · 합)", str(_hits(b.use_skill(_w(b, "harpe"), "bw_slash", t))), "[16800, 16800]")
	b = _b(["undine"], ["straw_golem"])
	t = _dummy(b, "fire")
	t.add_mark("frost", 3, 3)
	var un := _w(b, "undine")
	var ev := b.use_skill(un, "ice_break", t)
	_ok("D18 쇄빙 일격 터뜨리기, 빙결 3겹", _first(ev), 225000)
	_ok("T07 터뜨린 뒤 빙결 없음 → 다음 빙결 특공 0", "%d / %d" % [t.mark_n("frost"), b.estimate(un, t, "ice_break")], "0 / 63000")
	b = _b(["ignis"], ["straw_golem"])
	_e(b, "straw_golem").add_mark("burn", 3, 2)
	_ok("D19 대마법 태양 붕괴, 화상 2겹", _first(b.use_skill(_w(b, "ignis"), "ult_ignis", _e(b, "straw_golem"))), 396000)
	b = _b(["ignis"], ["straw_golem"], {"ignis": {"skill_lv": {"sun_spear": 3}}})
	_ok("D20 태양의 창 강화 Lv3 (7.8배)", _first(b.use_skill(_w(b, "ignis"), "sun_spear", _e(b, "straw_golem"))), 140400)
	b = _b(["ignis"], ["straw_golem"])
	_w(b, "ignis").passive = TData.WITCHES.ignis.passive.effects
	_e(b, "straw_golem").add_mark("burn", 3, 1)
	b.fix_crit = 1
	_ok("D21 이그니스 패시브 (화상 적 크리 데미지 +20%)", _first(b.basic_attack(_w(b, "ignis"), _e(b, "straw_golem"))), 30600)


# ═══════════════════════════════════════════════════════════
# §25.1 적 → 마녀 (재의 기사 공격력 9,000 — 문서의 옛 값으로 덮어써 시험)
# ═══════════════════════════════════════════════════════════

func _enemy_tests() -> void:
	print("── §25.1 피해 (적 → 마녀)")
	var cases := [["E01 강공격 2.0배", "", 0, 17100], ["E02 + 받는 피해 −40%", "wall", 0, 10260], ["E03 + 적 공격력 다운 15%", "down", 0, 14535],
		["E04 적 크리 (×1.5)", "", 1, 25650], ["E05 무적", "inv", 0, 0], ["E06 받는 피해 −90% (하한 −70%)", "low", 0, 5130]]
	for c in cases:
		var b := _b(["ignis"], ["ash_knight"])
		_tough(b)
		var ig := _w(b, "ignis")
		var k := _e(b, "ash_knight")
		k.atk = 9000
		k.intent_now = {"k": "heavy", "mult": 2.0}
		match String(c[1]):
			"wall": ig.add_buff({"cat": "dmg_taken", "v": -0.40, "dur": 2, "clock": "enemy"})
			"down": k.add_buff({"cat": "atk_down", "v": 0.15, "dur": 2, "clock": "own"})
			"inv": ig.add_buff({"cat": "invincible", "v": 1.0, "dur": 1, "clock": "enemy"})
			"low": ig.add_buff({"cat": "dmg_taken", "v": -0.90, "dur": 2, "clock": "enemy"})
		b.fix_crit = int(c[2])
		_ok(String(c[0]), _first(b.enemy_action(k)), int(c[3]))


# ═══════════════════════════════════════════════════════════
# §25.2 차례 순서
# ═══════════════════════════════════════════════════════════

func _order_tests() -> void:
	print("── §25.2 차례 순서")
	var b := _b(["ember", "eska", "ignis"], ["straw_golem", "swamp_toad", "ash_knight"])
	var names: Array = []
	for i in 12:
		var u := b.next_actor()
		names.append(u.name)
		b.end_action(u)
	_ok("Q01 12차례", " → ".join(names), "엠버 → 에스카 → 늪 두꺼비 → 이그니스 → 재의 기사 → 짚 골렘 → 엠버 → 에스카 → 늪 두꺼비 → 이그니스 → 재의 기사 → 짚 골렘")
	_ok("Q02 4·5번째 (같은 속도 → 마녀 먼저)", "%s, %s" % [names[3], names[4]], "이그니스, 재의 기사")
	_ok("Q03 12번째 (흘리기 전 게이지가 많은 쪽)", names[11], "짚 골렘")

	b = _b(["ember", "eska", "ignis"], ["straw_golem", "swamp_toad", "ash_knight"])
	var em := b.next_actor()
	b.end_action(em)
	_w(b, "ignis").gauge += 500.0 # 틈새 도약을 받은 셈
	var pv := b.preview(3)
	var seq: Array = []
	for i in 3:
		var u := b.next_actor()
		seq.append(u.name)
		b.end_action(u)
	_ok("Q04 이그니스 게이지 +50% → 늪 두꺼비보다 먼저 (차례 줄도)", "%s | %s" % [" → ".join(seq), pv[0].name], "이그니스 → 에스카 → 늪 두꺼비 | 이그니스")

	b = _b(["fulgur"], ["straw_golem"])
	var fu := _w(b, "fulgur")
	_until(b, fu)
	b.use_skill(fu, "flash", b.enemies[0])
	b.end_action(fu)
	_ok("Q05 자기 게이지 +30% (행동 뒤 0 → 300)", int(fu.gauge), 300)


# ═══════════════════════════════════════════════════════════
# §25.3 크레딧
# ═══════════════════════════════════════════════════════════

func _credit_tests() -> void:
	print("── §25.3 크레딧")
	var b := _b(["ignis"], ["straw_golem"])
	var ig := _w(b, "ignis")
	ig.credits = 0
	var got: Array = []
	var last_v := -1
	for turn in 5:
		_until(b, ig)
		if turn == 0:
			b.use_skill(ig, "spark", b.enemies[0])
		else:
			for e in b.basic_attack(ig, b.enemies[0]):
				if e.t == "credits":
					last_v = int(e.v)
		b.end_action(ig)
		got.append(ig.credits)
	_ok("C01 불씨 찌르기 → 기본 공격 ×4", str(got), "[0, 2, 4, 6, 7]")
	_ok("X02 상한에서 기본 공격의 크레딧 글 = 실제 증가분", last_v, 0)

	b = _b(["ignis"], ["straw_golem"], {"ignis": {"equip": "kaleido"}})
	ig = _w(b, "ignis")
	_until(b, ig)
	var c0 := ig.credits
	var can := b.can_use(ig, "ult_ignis")
	b.use_skill(ig, "ult_ignis", b.enemies[0])
	_ok("C02 만화경: 첫 차례 7 → 대마법 → 0", "%d %s %d" % [c0, str(can), ig.credits], "7 true 0")

	b = _b(["ignis"], ["straw_golem"], {"ignis": {"equip": "mana_spring"}})
	ig = _w(b, "ignis")
	var before := ig.credits
	_until(b, ig)
	_ok("C03 마력 샘: 차례 시작 +2", ig.credits - before, 2)

	b = _b(["ignis", "ember"], ["straw_golem"])
	ig = _w(b, "ignis")
	var em := _w(b, "ember")
	ig.credits = 5
	_until(b, em)
	b.use_skill(em, "god_descent", ig)
	b.end_action(em)
	var nx := b.next_actor()
	var s: Array = [nx.name, ig.credits]
	b.use_skill(ig, "sun_spear", b.enemies[0])
	s.append(ig.credits)
	b.end_action(ig)
	s.append(ig.credits)
	_ok("C04 불의 신 강림 → 바로 차례 6 → 태양의 창 1 → 대가 0", str(s), "[\"이그니스\", 6, 1, 0]")

	b = _b(["ignis", "eska"], ["straw_golem"])
	ig = _w(b, "ignis")
	ig.credits = 4
	b.deal(ig, 9999999999)
	var dead := not ig.alive
	ig.revive(0.5)
	_ok("C05 쓰러질 때 크레딧 4 → 되살림 뒤 4", "%s %s %d" % [str(dead), str(ig.alive), ig.credits], "true true 4")


# ═══════════════════════════════════════════════════════════
# §25.4 동작 시나리오
# ═══════════════════════════════════════════════════════════

func _scenario_tests() -> void:
	print("── §25.4 동작 시나리오")
	_skip("T01", "바퀴를 연 채 기다림 — 화면 흐름 (구현됨, 시나리오 turn_touch.json)")
	# T02 남이 걸어 준 "행동 2번"
	var b := _b(["ignis", "ember"], ["straw_golem"])
	var ig := _w(b, "ignis")
	b._apply_buff(_w(b, "ember"), ig, {"cat": "atk", "v": 0.30, "dur": 2})
	var seen: Array = []
	for i in 3:
		_until(b, ig)
		seen.append(snappedf(ig.cat_sum("atk"), 0.01))
		b.end_action(ig)
	_ok("T02 남이 건 공격력 +30% (행동 2번): 행동 1·2·3", str(seen), "[0.3, 0.3, 0.0]")
	# T03 자기 차례에 자기에게 "행동 2번"
	b = _b(["ignis"], ["straw_golem"])
	ig = _w(b, "ignis")
	_until(b, ig)
	b.use_skill(ig, "focus", ig)
	b.end_action(ig)
	var d1 := snappedf(ig.cat_sum("atk"), 0.01)
	_until(b, ig)
	b.end_action(ig)
	_ok("T03 자기에게 건 공격력 +50% (행동 2번): 다음 1행동에만", "%s %s" % [str(d1), str(snappedf(ig.cat_sum("atk"), 0.01))], "0.5 0.0")
	# T04 무적은 공격이 없어도 적 행동 1번에 사라짐
	b = _b(["eska"], ["ash_knight"])
	var es := _w(b, "eska")
	var k := _e(b, "ash_knight")
	b.use_skill(es, "seal", null)
	var inv0 := es.is_invincible()
	k.intent_now = {"k": "buff", "v": 0.30, "dur": 3}
	b.enemy_action(k)
	b.end_action(k)
	_ok("T04 봉공 뒤 적 버프 의도 → 무적 사라짐", "%s %s" % [str(inv0), str(es.is_invincible())], "true false")
	# T05·T06 징표 겹
	b = _b(["ignis"], ["straw_golem"])
	ig = _w(b, "ignis")
	var g := _e(b, "straw_golem")
	for i in 3:
		b.use_skill(ig, "spark", g)
	_ok("T05 불씨 찌르기 ×3 → 화상 3겹 · 남은 3", "%d · %d" % [g.mark_n("burn"), g.mark_dur("burn")], "3 · 3")
	g.marks["burn"] = {"n": 5, "dur": 1}
	b.use_skill(ig, "spark", g)
	_ok("T06 화상 5겹에 한 번 더 → 5겹 그대로, 남은 수만 갱신", "%d · %d" % [g.mark_n("burn"), g.mark_dur("burn")], "5 · 3")
	# T08 화상 0겹에 대화재
	b = _b(["ignis"], ["straw_golem", "straw_golem"])
	var ev := b.use_skill(_w(b, "ignis"), "conflagration", null)
	_ok("T08 화상 0겹에 대화재 → 보너스 0, 터뜨림 없음", "%s %s" % [str(_hits(ev)), str(_kinds(ev).has("burst"))], "[72000, 72000] false")
	# T09 완전 동결 → 늪 두꺼비 (다음 의도 기절 공격)
	b = _b(["glacia", "eska"], ["swamp_toad"])
	_tough(b)
	var gl := _w(b, "glacia")
	var td := _e(b, "swamp_toad")
	td.intent_i = 1
	b.decide_intent(td)
	b.use_skill(gl, "deep_freeze", td)
	var st0 := td.stunned
	_until(b, td)
	var rested := td.stunned
	b.rest(td)
	b.end_action(td)
	var it_after := String(td.intent().k)
	_until(b, td)
	ev = b.enemy_action(td)
	b.end_action(td)
	_ok("T09 기절 → 다음 차례 쉼, 의도 그대로 → 그다음 차례에 기절 공격", "%s %s %s %s" % [str(st0), str(rested), it_after, str(_kinds(ev).has("stun"))], "true true stun_attack true")
	# T11 기절 내성
	b = _b(["glacia"], ["swamp_toad"])
	_tough(b)
	gl = _w(b, "glacia")
	td = _e(b, "swamp_toad")
	b.use_skill(gl, "deep_freeze", td)
	_until(b, td)
	b.rest(td)
	b.end_action(td)
	ev = b.use_skill(gl, "deep_freeze", td)
	var r1 := "%s %s" % [str(_kinds(ev).has("stun_resist")), str(td.stunned)]
	_until(b, td)
	b.enemy_action(td)
	b.end_action(td)
	b.use_skill(gl, "deep_freeze", td)
	_ok("T11 쉰 직후 다시 기절 → 기절 내성 / 다음 차례 뒤엔 다시 걸림", "%s | %s" % [r1, str(td.stunned)], "true false | true")
	# T10 완전 동결 → 재의 왕 (면역, 방어 다운은 성공 판정 70%)
	for c in [[0.5, "debuff"], [0.75, "resist"]]:
		b = _b(["glacia"], ["ash_king"])
		var kg := _e(b, "ash_king")
		b.fix_roll = float(c[0])
		ev = b.use_skill(_w(b, "glacia"), "deep_freeze", kg)
		var ks := _kinds(ev)
		_ok("T10 완전 동결 → 재의 왕, 판정 난수 %.2f" % float(c[0]), "%s %s %s %d" % [str(ks.has("immune")), str(kg.stunned), str(ks.has(String(c[1]))), kg.mark_n("frost")], "true false true 1")
	# T12 기절 공격 → 에스카, 다음 차례 쉼
	b = _b(["eska"], ["swamp_toad"])
	_tough(b)
	es = _w(b, "eska")
	td = _e(b, "swamp_toad")
	td.intent_now = {"k": "stun_attack", "mult": 0.6}
	ev = b.enemy_action(td)
	b.end_action(td)
	var dmg := _first(ev)
	es.credits = 3
	es.add_buff({"cat": "atk", "v": 0.3, "dur": 2, "clock": "own"})
	_until(b, es)
	var c_turn := es.credits
	b.rest(es)
	b.end_action(es)
	_ok("T12 기절 공격 → 에스카: 피해 + 쉼 (크레딧 +1 없음 · 게이지 0 · 버프 −1)", "%s %s %d %d %d" % [str(dmg > 0), str(es.stun_guard), c_turn, int(es.gauge), int(es.buffs[0].dur)], "true true 3 0 1")
	# T13 무적이면 기절 공격도 막힘
	b = _b(["eska"], ["swamp_toad"])
	_tough(b)
	es = _w(b, "eska")
	td = _e(b, "swamp_toad")
	es.add_buff({"cat": "invincible", "v": 1.0, "dur": 1, "clock": "enemy"})
	td.intent_now = {"k": "stun_attack", "mult": 0.6}
	ev = b.enemy_action(td)
	_ok("T13 무적 → 기절 공격: 피해 0, 기절 없음", "%d %s" % [_first(ev), str(es.stunned)], "0 false")
	# T14 도발
	b = _b(["nerei", "harpe", "ignis"], ["swamp_toad", "straw_golem"])
	_tough(b)
	var hp := _w(b, "harpe")
	td = _e(b, "swamp_toad")
	g = _e(b, "straw_golem")
	b.use_skill(_w(b, "nerei"), "spring", hp)
	var tg: Array = []
	for kk in ["attack", "stun_attack"]:
		td.intent_now = {"k": kk, "mult": 1.0}
		for e in b.enemy_action(td):
			if e.t == "hit":
				tg.append(e.tgt.name)
	td.intent_now = {"k": "aoe", "mult": 0.8}
	var aoe_n := _hits(b.enemy_action(td)).size()
	b.end_action(td)
	g.intent_now = {"k": "attack", "mult": 1.0}
	for e in b.enemy_action(g):
		if e.t == "hit":
			tg.append(e.tgt.name)
	b.end_action(g)
	_ok("T14 샘물 붓기 → 하르페 도발 (적 행동 2번)", "%s 전체 %d %s" % [",".join(tg), aoe_n, str(hp.has_buff("taunt"))], "하르페,하르페,하르페 전체 3 false")
	# T15 도발 둘 (마법 + 강철 심장)
	b = _b(["harpe", "ignis", "eska"], ["straw_golem"], {"ignis": {"equip": "iron_heart"}})
	_tough(b)
	_w(b, "harpe").add_buff({"cat": "taunt", "v": 1.0, "dur": 99, "clock": "enemy"})
	g = _e(b, "straw_golem")
	var cnt := {}
	for i in 80:
		g.intent_now = {"k": "attack", "mult": 1.0}
		for e in b.enemy_action(g):
			if e.t == "hit":
				cnt[e.tgt.name] = int(cnt.get(e.tgt.name, 0)) + 1
	_ok("T15 도발 둘 → 둘 중 균등 무작위 (80번)", "%s %s %s" % [str(cnt.has("하르페") and int(cnt["하르페"]) > 20), str(cnt.has("이그니스") and int(cnt["이그니스"]) > 20), str(cnt.has("에스카"))], "true true false")
	# T16 되감기 근성
	b = _b(["hora", "ignis"], ["ash_knight"])
	ig = _w(b, "ignis")
	k = _e(b, "ash_knight")
	b.use_skill(_w(b, "hora"), "rewind", ig)
	ig.hp = 5000
	k.atk = 9000
	k.intent_now = {"k": "heavy", "mult": 2.0}
	b.fix_rand = 1.0
	var h1: Dictionary = {}
	for i in 10: # 대상이 무작위라 이그니스가 맞을 때까지
		var e1 := b.enemy_action(k)
		if e1[0].tgt == ig:
			h1 = e1[0]
			break
	var after := "%d %s %s %d" % [ig.hp, str(h1.get("guts", false)), str(ig.has_buff("guts")), int(h1.get("dmg", 0))]
	var h2: Dictionary = {}
	for i in 10:
		var e2 := b.enemy_action(k)
		if e2[0].tgt == ig:
			h2 = e2[0]
			break
	_ok("T16 근성 (체력 5,000에 17,100) → 체력 1, 근성 소모 → 다음엔 쓰러짐", "%s | %s" % [after, str(h2.get("killed", false))], "1 true false 17100 | true")
	# T17 깃털 부적 Lv3 (전투당 1번, 웨이브가 바뀌어도)
	b = _b(["ignis"], "boss_01", {"ignis": {"equip": "feather_charm", "equip_lv": 3}})
	ig = _w(b, "ignis")
	var mh := ig.max_hp
	var rr := b.deal(ig, 9999999999)
	var hp1 := ig.hp
	for e in b.enemies:
		b.deal(e, 9999999999)
	var oc := b.outcome()
	b.next_wave()
	rr = b.deal(ig, 9999999999)
	_ok("T17 깃털 부적 Lv3: 최대 80,000 → 16,000 · 웨이브 뒤엔 다시 못 씀", "%d %d %s %s" % [mh, hp1, oc, str(rr.killed)], "80000 16000 wave true")
	# T18 디버프 성공 판정 (재의 기사 내성 10%)
	for c in [[0.89, "debuff"], [0.90, "resist"]]:
		b = _b(["eska"], ["ash_knight"])
		b.fix_roll = float(c[0])
		_ok("T18 재의 기사 방어 다운, 판정 난수 %.2f" % float(c[0]), str(_kinds(b.use_skill(_w(b, "eska"), "crack", _e(b, "ash_knight"))).has(String(c[1]))), "true")
	# T19 징표는 판정 없음
	b = _b(["ignis"], ["ash_king"])
	b.fix_roll = 0.99
	b.use_skill(_w(b, "ignis"), "spark", _e(b, "ash_king"))
	_ok("T19 재의 왕에게 화상 → 늘 걸림", _e(b, "ash_king").mark_n("burn"), 1)
	# T20 차지 4 → 필살기
	b = _b(["ignis"], ["ash_knight"])
	_tough(b)
	k = _e(b, "ash_knight")
	for i in 4:
		b.enemy_action(k)
		b.end_action(k)
	var it4 := "%s %d" % [String(k.intent().get("name", k.intent().k)), k.charge]
	ev = b.enemy_action(k)
	b.end_action(k)
	_ok("T20 재의 기사 행동 4번 → 필살기 보임 → 전체 2.0배 → 차지 0", "%s | %d %d %s" % [it4, _first(ev), k.charge, String(k.intent().k)], "잿불 베기 4 | 10260 0 attack")
	# T21 차지 3에서 기절
	b = _b(["glacia"], ["ash_knight"])
	_tough(b)
	k = _e(b, "ash_knight")
	k.charge = 3
	var it0 := String(k.intent().k)
	b.use_skill(_w(b, "glacia"), "deep_freeze", k)
	_until(b, k)
	b.rest(k)
	b.end_action(k)
	_ok("T21 차지 3인 재의 기사를 기절 → 쉰 차례에 차지·의도 그대로", "%d %s" % [k.charge, str(String(k.intent().k) == it0)], "3 true")
	# T22 줄 깨짐
	b = _b(["undine"], ["ash_king"])
	var kg := _e(b, "ash_king")
	kg.hp = 100000
	rr = b.deal(kg, 500000)
	_ok("T22 첫 줄 100,000에 500,000 → 넘친 400,000 버림 · 둘째 줄 · 다음 의도 해제", "%s %d %d %s" % [str(rr.broke), kg.bar_i, kg.hp, String(kg.intent().k)], "true 1 1200000 dispel")
	# T23 종막의 검 2번째 히트에 줄이 깨짐
	b = _b(["harpe"], ["ash_king"])
	kg = _e(b, "ash_king")
	kg.hp = 50000
	ev = b.use_skill(_w(b, "harpe"), "ult_harpe", kg)
	_ok("T23 종막의 검 (6히트) 2번째에 브레이크 → 남은 4히트는 0", "%s %d %d" % [str(_hits(ev)), kg.bar_i, kg.hp], "[37800, 37800] 1 1200000")
	# T24 해제
	b = _b(["ignis", "eska"], ["ash_king"], {"ignis": {"equip": "feather_charm"}})
	ig = _w(b, "ignis")
	ig.passive = TData.WITCHES.ignis.passive.effects
	for cat in ["invincible", "taunt", "guts", "atk", "element"]:
		ig.add_buff({"cat": cat, "v": 0.3, "dur": 3, "clock": "enemy" if cat in ["invincible", "taunt", "guts"] else "own", "el": "water"})
	ig.zero_after_turn = 5
	kg = _e(b, "ash_king")
	kg.intent_now = {"k": "dispel"}
	ev = b.enemy_action(kg)
	_ok("T24 재의 왕 해제 → 버프 전부 사라짐 · 깃털 부적·패시브·대가는 남음", "%d %s %s %d %s" % [ig.buffs.size(), str(ig.guts_used), str(float(ig.equip_data().get("guts_once", 0.0)) > 0.0), ig.zero_after_turn, str(not ig.passive.is_empty())], "0 false true 5 true")
	# T25 웨이브 전환
	b = _b(TData.BATTLE.party, "boss_01")
	ig = _w(b, "ignis")
	ig.credits = 4
	ig.hp = 50000
	ig.gauge = 321.0
	ig.add_buff({"cat": "atk", "v": 0.3, "dur": 3, "clock": "own"})
	for e in b.enemies:
		b.deal(e, 9999999999)
	oc = b.outcome()
	var w2 := b.next_wave()
	var names: Array = []
	var gsum := 0.0
	for e in w2:
		names.append(e.name)
		gsum += e.gauge
	_ok("T25 boss_01 웨이브 ① 전멸 → ② 등장 (게이지 0), 마녀 그대로", "%s %d/%d %s %d | %d %d %d %d" % [oc, b.wave_i + 1, b.wave_count(), ",".join(names), int(gsum), ig.credits, ig.hp, ig.buffs.size(), int(ig.gauge)],
		"wave 2/3 늪 두꺼비,재의 기사 0 | 4 50000 1 321")
	# T26 대마법 칸
	b = _b(["eska"], ["straw_golem"])
	es = _w(b, "eska")
	es.credits = 6
	var c6 := b.can_use(es, "ult_eska")
	es.credits = 7
	var c7 := b.can_use(es, "ult_eska")
	b.use_skill(es, "ult_eska", null)
	_ok("T26 대마법: 크레딧 6 못 씀 · 7 씀 → 0", "%s %s %d" % [str(c6), str(c7), es.credits], "false true 0")
	# T27 장비 한 명만 (편성 규칙 TData.step_equip · fix_equip = TSetup이 부르는 것)
	var st := {"party": ["eska", "ignis", "ember"], "eska": {"equip": "black_cup"}, "ignis": {"equip": ""}, "ember": {"equip": ""}, "harpe": {"equip": "black_cup"}}
	var nx := TData.step_equip(st, 1, 1)
	var back := TData.step_equip(st, 1, -1)
	st.party[2] = "harpe"
	TData.fix_equip(st, "harpe")
	_ok("T27 에스카가 검은 잔 → 이그니스 ▶ 건너뜀 · 들어온 마녀의 겹친 장비는 없음", "%s '%s' '%s'" % [nx, back, String(st.harpe.equip)], "kaleido '' ''")
	_skip("T28", "길게 눌러 상세 — 단계 C (화면)")
	_skip("T29·T30", "패배 배너·나가기 X — 화면 흐름 (구현됨)")


# ═══════════════════════════════════════════════════════════
# §26 경계 사례 몇 개
# ═══════════════════════════════════════════════════════════

func _edge_tests() -> void:
	print("── §26 경계 사례")
	var b := _b(["glacia"], ["swamp_toad"])
	var td := _e(b, "swamp_toad")
	b.use_skill(_w(b, "glacia"), "deep_freeze", td)
	var ev := b.use_skill(_w(b, "glacia"), "deep_freeze", td)
	_ok("X12 기절 중에 다시 기절 → 아무 일 없음", "%s %s" % [str(td.stunned), str(_kinds(ev).has("stun"))], "true false")
	b = _b(["ignis", "hora"], ["ash_knight"])
	var ig := _w(b, "ignis")
	b.use_skill(_w(b, "hora"), "rewind", ig)
	ig.add_buff({"cat": "invincible", "v": 1.0, "dur": 1, "clock": "enemy"})
	ig.hp = 10
	var k := _e(b, "ash_knight")
	k.intent_now = {"k": "aoe", "mult": 5.0}
	b.enemy_action(k)
	_ok("X16 무적 + 근성 → 피해 0, 근성을 쓰지 않음", "%d %s" % [ig.hp, str(ig.has_buff("guts"))], "10 true")
	b = _b(["ignis"], ["ash_king"])
	var kg := _e(b, "ash_king")
	kg.intent_now = {"k": "dispel"}
	_ok("X20 마녀 버프 0개에 해제 → 사건 없음", str(_kinds(b.enemy_action(kg))), "[]")
	b = _b(["eska"], ["ash_king"])
	b.fix_roll = 0.0
	ev = b.use_skill(_w(b, "eska"), "crack", _e(b, "ash_king"))
	var e2: Dictionary = {"t": "debuff", "cat": "def_down", "v": 0.1, "dur": 2, "rate": 0.3}
	var r2 := b._resisted(_e(b, "ash_king"), e2)
	_ok("X21 성공률 ≤ 0 → 늘 실패 (rate 0.3 − 내성 0.3)", "%s %s" % [str(_kinds(ev).has("debuff")), str(r2)], "true true")
	b = _b(["ignis"], ["straw_golem", "swamp_toad"])
	_e(b, "straw_golem").add_mark("burn", 3, 2)
	_e(b, "swamp_toad").add_mark("burn", 3, 1)
	ev = b.use_skill(_w(b, "ignis"), "conflagration", null)
	var bn: Array = []
	for e in ev:
		if e.t == "burst":
			bn.append("%s %d" % [e.tgt.name, int(e.n)])
	# 짚 골렘: (4.0 + 0.3×2) × 12,000 × 1.5 × (1 + 0.8×2) = 215,280 / 늪 두꺼비(물, 방어 20%): (4.0 + 0.3) × 12,000 × 1.0 × 1.8 × 0.8 = 74,304
	_ok("X24 광역 터뜨리기 → 대상마다 자기 겹, 대상마다 지움", "%s %s %d" % [str(_hits(ev)), ",".join(bn), _e(b, "straw_golem").mark_n("burn")], "[215280, 74304] 짚 골렘 2,늪 두꺼비 1 0")
	b = _b(["undine"], ["ash_king"])
	kg = _e(b, "ash_king")
	kg.bar_i = 2
	kg.hp = 10
	var rr := b.deal(kg, 100)
	_ok("X19 마지막 줄이 깨짐 → 쓰러짐", "%s %s" % [str(rr.broke), str(rr.killed)], "false true")
	b = _b(["ignis"], ["straw_golem"])
	b.enemies[0].def_rate = 0.3
	b.enemies[0].weak = []
	_w(b, "ignis").atk = 1
	b.fix_rand = 0.95
	_ok("§11.1 피해 최소 1", _first(b.basic_attack(_w(b, "ignis"), b.enemies[0])), 1)
	# 순환 약점 (§11.3)
	_ok("§11.3 순환: 물 적 → 번개 · 불 적 → 물 · 번개 적 → 불", "%s %s %s" % [TData.WEAK_TO.water, TData.WEAK_TO.fire, TData.WEAK_TO.bolt], "bolt water fire")


# ═══════════════════════════════════════════════════════════
# 숫자 표기 (§21.13 · §25.4)
# ═══════════════════════════════════════════════════════════

func _number_tests() -> void:
	print("── 숫자 표기")
	for c in [[9999999, "9,999,999"], [12345678, "1,235만"], [99994999, "9,999만"], [99995000, "1.00억"], [123456789, "1.23억"], [12345678901, "123억"]]:
		_ok("N %s" % TData.fmt(int(c[0])), TData.fmt_short(int(c[0])), String(c[1]))
