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
	_stage_b_tests()
	_stage_e_tests()
	_stage_f_tests()
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
	_ok("D04 태양의 창", _first(b.use_skill(_w(b, "ignis"), "sun_spear", _e(b, "straw_golem"))), 126000)

	for c in [["D05 + 풀무질 (화상 특공 25%/겹), 화상 1겹", 1, 157500], ["D06 화상 3겹 (75%)", 3, 220500], ["D07 화상 5겹 (125%)", 5, 283500]]:
		b = _b(["ignis", "ember"], ["straw_golem"])
		b.use_skill(_w(b, "ember"), "bellows", _w(b, "ignis"))
		_e(b, "straw_golem").add_mark("burn", 3, int(c[1]))
		_ok(String(c[0]), _first(b.use_skill(_w(b, "ignis"), "sun_spear", _e(b, "straw_golem"))), int(c[2]))

	for c in [["D08 D06 + 불의 축복 30% + 열기 응축 80% (다음 공격 마법)", 0, 463050], ["D09 D08이 크리 (×1.5)", 1, 694575]]:
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
	_ok("D10 에스카 종언 (6.0배, 선버프 +15%) → 재의 기사", _first(b.use_skill(_w(b, "eska"), "doom", _e(b, "ash_knight"))), 75348)
	b = _b(["ignis"], ["ash_knight"])
	_e(b, "ash_knight").add_buff({"cat": "def_down", "v": 0.60, "dur": 3, "clock": "own"})
	_ok("D11 방어 다운 60% (상한 50%)", _first(b.basic_attack(_w(b, "ignis"), _e(b, "ash_knight"))), 14400)
	b = _b(["eska"], ["ash_knight"])
	_ok("D12 공간 압축 (방어 무시)", _first(b.use_skill(_w(b, "eska"), "compress", _e(b, "ash_knight"))), 67080)
	for c in [["D13 화염 부여 종언 → 짚 골렘 (134,549.99…)", "straw_golem", 134550], ["D14 화염 부여 종언 → 늪 두꺼비", "swamp_toad", 71760]]:
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
	b = _b(["ignis"], ["straw_golem"])
	g = _e(b, "straw_golem")
	g.add_mark("burn", 3, 3)
	var ev := b.use_skill(_w(b, "ignis"), "burst_fire", g)
	_ok("D18 불씨 터뜨리기, 화상 3겹 (3.5 + 0.6×3)", _first(ev), 95400)
	_ok("T07 터뜨린 뒤 화상 없음 → 다음은 3.5배 그대로", "%d / %d" % [g.mark_n("burn"), b.estimate(_w(b, "ignis"), g, "burst_fire")], "0 / 63000")
	b = _b(["ignis"], ["straw_golem"])
	_e(b, "straw_golem").add_mark("burn", 3, 2)
	ev = b.use_skill(_w(b, "ignis"), "ult_ignis", _e(b, "straw_golem"))
	_ok("D19 대마법 태양 붕괴, 화상 2겹 터뜨리기 (9 + 1.0×2) → 뒤에 화상 1겹", "%d %d" % [_first(ev), _e(b, "straw_golem").mark_n("burn")], "198000 1")
	b = _b(["ignis"], ["straw_golem"], {"ignis": {"skill_lv": {"sun_spear": 3}}})
	_ok("D20 태양의 창 강화 Lv3 (9.1배)", _first(b.use_skill(_w(b, "ignis"), "sun_spear", _e(b, "straw_golem"))), 163800)
	b = _b(["ignis"], ["straw_golem"])
	_w(b, "ignis").passive = TData.WITCHES.ignis.passive.effects
	_e(b, "straw_golem").add_mark("burn", 3, 1)
	b.fix_crit = 1
	_ok("D21 이그니스 패시브 (화상 1겹당 크리 데미지 +8%) — 1겹 크리", _first(b.basic_attack(_w(b, "ignis"), _e(b, "straw_golem"))), 28440)
	_e(b, "straw_golem").marks["burn"] = {"n": 5, "dur": 3}
	var p5 := _first(b.basic_attack(_w(b, "ignis"), _e(b, "straw_golem")))
	b = _b(["ignis"], ["straw_golem"], {"ignis": {"equip": "tide_ring"}})
	_w(b, "ignis").passive = TData.WITCHES.ignis.passive.effects
	_e(b, "straw_golem").add_mark("burn", 3, 5)
	b.fix_crit = 1
	_ok("D22 5겹 (상한 +40%) / 물 부여(조류 반지)면 자기 속성이 아니라 안 붙음", "%d %d" % [p5, _first(b.basic_attack(_w(b, "ignis"), _e(b, "straw_golem")))], "34200 18000")


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
	# T03 자기 차례에 자기에게 "행동 3번" (검기 두르기) → 다음 2행동
	b = _b(["harpe"], ["straw_golem"])
	var hpu := _w(b, "harpe")
	_until(b, hpu)
	b.use_skill(hpu, "sword_ki", hpu)
	b.end_action(hpu)
	var t3: Array = []
	for i in 3:
		_until(b, hpu)
		t3.append(snappedf(hpu.cat_sum("atk"), 0.01))
		b.end_action(hpu)
	_ok("T03 자기에게 건 공격력 +40% (행동 3번): 다음 2행동에만", str(t3), "[0.4, 0.4, 0.0]")
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
	b.use_skill(_w(b, "nerei"), "wave_hold", null)
	hp = _w(b, "nerei")
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
	b.end_action(g)
	b.end_action(g)
	_ok("T14 파도 버티기 → 네레이 자신 도발 (적 행동 3번)", "%s 전체 %d %s" % [",".join(tg), aoe_n, str(hp.has_buff("taunt"))], "네레이,네레이,네레이 전체 3 false")
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
	# T20 차지 5 → 필살기 (D2·E2: 재의 기사 차지 4 → 5, 필살기 2.0 → 1.5배)
	b = _b(["ignis"], ["ash_knight"])
	_tough(b)
	k = _e(b, "ash_knight")
	for i in 5:
		b.enemy_action(k)
		b.end_action(k)
	var it4 := "%s %d" % [String(k.intent().get("name", k.intent().k)), k.charge]
	ev = b.enemy_action(k)
	b.end_action(k)
	_ok("T20 재의 기사 행동 5번 → 필살기 보임 → 전체 1.5배 (3,000 × 1.5 × 0.95) → 차지 0", "%s | %d %d %s" % [it4, _first(ev), k.charge, String(k.intent().k)], "잿불 베기 5 | 4275 0 buff")
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
	_ok("T22 첫 줄 100,000에 500,000 → 넘친 400,000 버림 · 둘째 줄 · 다음 의도 해제", "%s %d %d %s" % [str(rr.broke), kg.bar_i, kg.hp, String(kg.intent().k)], "true 1 1500000 dispel")
	# T23 종막의 검 2번째 히트에 줄이 깨짐
	b = _b(["harpe"], ["ash_king"])
	kg = _e(b, "ash_king")
	kg.hp = 50000
	ev = b.use_skill(_w(b, "harpe"), "ult_harpe", kg)
	_ok("T23 종막의 검 (6.8배 6히트) 2번째에 브레이크 → 남은 4히트는 0", "%s %d %d" % [str(_hits(ev)), kg.bar_i, kg.hp], "[28560, 28560] 1 1500000")
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
	# 짚 골렘: (4.0 + 0.4×2) × 12,000 × 1.5 = 86,400 / 늪 두꺼비(물, 방어 20%): (4.0 + 0.4) × 12,000 × 1.0 × 0.8 = 42,240
	_ok("X24 광역 터뜨리기 → 대상마다 자기 겹, 대상마다 지움", "%s %s %d" % [str(_hits(ev)), ",".join(bn), _e(b, "straw_golem").mark_n("burn")], "[86400, 42240] 짚 골렘 2,늪 두꺼비 1 0")
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


# ═══════════════════════════════════════════════════════════
# 단계 B 새 규칙 (§13.6 연쇄 · §16.8 횟수제 · §12.7 물의 환급 · §17.10 번개의 차례 · §17.1 번짐 · §17.9 대가 · §17.11 쌓기 · §18.5 차지 감소 · §18.10 관통)
# ═══════════════════════════════════════════════════════════

func _stage_b_tests() -> void:
	print("── 단계 B 새 규칙")
	# N01 횟수제 (충전: 기본 공격 3번) — 마법에는 닳지 않고 기본 공격 3번에 사라짐
	var b := _b(["fulgur"], ["straw_golem"])
	var fu := _w(b, "fulgur")
	var g := _e(b, "straw_golem")
	var cnt := func() -> String:
		for bf in fu.buffs:
			if bf.has("count"):
				return str(int(bf.count))
		return "0"
	_until(b, fu)
	b.use_skill(fu, "charge_up", fu)
	b.end_action(fu)
	var seen: Array = [cnt.call()]
	_until(b, fu)
	fu.credits = 7
	b.use_skill(fu, "spark_bolt", g)
	b.end_action(fu)
	seen.append(cnt.call())
	for i in 3:
		_until(b, fu)
		b.basic_attack(fu, g)
		b.end_action(fu)
		seen.append(cnt.call())
	_ok("N01 충전 → 마법 1번(안 닳음) → 기본 공격 3번", ",".join(seen), "3,3,2,1,0")
	# N02 횟수제는 자기 종류의 공격에만 붙는다 — 열기 응축(공격 마법 1번 +80%)은 기본 공격을 키우지 않고 닳지도 않음
	b = _b(["ignis"], ["straw_golem"])
	var ig := _w(b, "ignis")
	g = _e(b, "straw_golem")
	_until(b, ig)
	b.use_skill(ig, "focus", ig)
	b.end_action(ig)
	_until(b, ig)
	var nb := _first(b.basic_attack(ig, g))
	b.end_action(ig)
	_until(b, ig)
	ig.credits = 7
	var ns := _first(b.use_skill(ig, "sun_spear", g))
	b.end_action(ig)
	_ok("N02 열기 응축 → 기본 공격 18,000(그대로) → 태양의 창 126,000 × 1.8 → 사라짐", "%d %d %s" % [nb, ns, str(ig.has_skill_buff("focus"))], "18000 226800 false")
	# N03 대마법 연쇄: 주인의 다음 행동 전에 다시 대마법 → 단계 2 (부가 효과 × 1.25), 기본 공격을 마치면 끊김
	b = _b(["undine"], ["straw_golem"])
	var un := _w(b, "undine")
	var t := _dummy(b, "fire")
	_until(b, un)
	un.credits = 7
	b.use_skill(un, "ult_undine", t)
	b.end_action(un)
	_until(b, un)
	un.credits = 7
	var ev := b.use_skill(un, "ult_undine", t)
	var st := 0
	for e in ev:
		if e.t == "chain":
			st = int(e.stage)
	var d2 := _first(ev)
	b.end_action(un)
	_until(b, un)
	b.basic_attack(un, t)
	b.end_action(un)
	_ok("N03 심연 붕괴 연쇄 2단계: 빙결 특공 +15% → +18.75% · 기본 공격 뒤 끊김", "%d %d | %d" % [st, d2, b.chain_stage], "2 192375 | 0")
	# N04 물의 환급: 맞기 전 빙결이 있었을 때만 크레딧 +1
	b = _b(["undine"], ["straw_golem"])
	un = _w(b, "undine")
	t = _dummy(b, "fire")
	un.credits = 5
	b.use_skill(un, "return_tide", t)
	var c1 := un.credits
	t.add_mark("frost", 3, 1)
	b.use_skill(un, "return_tide", t)
	_ok("N04 돌아오는 물살: 빙결 없음 5→3 · 빙결 있음 3→2", "%d %d" % [c1, un.credits], "3 2")
	# N05 적 차지 감소: 필살기가 보이던 재의 기사 → 차지 3, 의도는 패턴으로 / 재의 왕(내성 30%) 성공률 = 1.0 − 0.3 + 글라시아 0.15
	b = _b(["glacia"], ["ash_knight"])
	var k := _e(b, "ash_knight")
	k.charge = 5
	b.decide_intent(k)
	var before := String(k.intent().k)
	b.use_skill(_w(b, "glacia"), "still_frost", k)
	var r5 := "%s → %d %s" % [before, k.charge, String(k.intent().k)]
	var r6: Array = []
	for roll in [0.84, 0.86]:
		b = _b(["glacia"], ["ash_king"])
		var kg := _e(b, "ash_king")
		_w(b, "glacia").passive = TData.WITCHES.glacia.passive.effects
		kg.charge = 2
		b.fix_roll = roll
		b.use_skill(_w(b, "glacia"), "still_frost", kg)
		r6.append(kg.charge)
	_ok("N05 멎는 서리: 재의 기사 필살기 거둠 · 재의 왕 판정 0.84 성공 / 0.86 저항", "%s | %s" % [r5, str(r6)], "finisher → 4 attack | [1, 2]")
	# N06 무적 관통 필살기: 무적이어도 맞고, 받는 피해 감소는 통함 (시련의 일격 단일 3.0배)
	b = _b(["harpe"], ["trial_colossus"])
	var hp := _w(b, "harpe")
	_tough(b)
	var col := _e(b, "trial_colossus")
	hp.add_buff({"cat": "invincible", "v": 1.0, "dur": 3, "clock": "enemy"})
	hp.add_buff({"cat": "dmg_taken", "v": -0.30, "dur": 3, "clock": "enemy"})
	col.intent_now = TData.ENEMIES.trial_colossus.charge_act
	var fin := _first(b.enemy_action(col))
	col.intent_now = {"k": "attack", "mult": 1.0}
	_ok("N06 시련의 일격 → 무적 하르페: 36,000 × 3.0 × 0.95 × 0.7 / 일반 공격은 무적", "%d %d" % [fin, _first(b.enemy_action(col))], "71820 0")
	# N07 맞으며 쌓기: 파도 버티기 → 맞을 때마다 아군 전체 공격력 +8% (최대 5겹)
	b = _b(["nerei", "harpe"], ["straw_golem"])
	_tough(b)
	var ne := _w(b, "nerei")
	hp = _w(b, "harpe")
	g = _e(b, "straw_golem")
	b.use_skill(ne, "wave_hold", null)
	for i in 3:
		g.intent_now = {"k": "attack", "mult": 1.0}
		b.enemy_action(g)
	var a3 := snappedf(hp.cat_sum("atk"), 0.01)
	for i in 4:
		g.intent_now = {"k": "attack", "mult": 1.0}
		b.enemy_action(g)
	_ok("N07 3번 맞음 → 하르페 공격력 +24% · 7번 → +40% (5겹)", "%s %s" % [str(a3), str(snappedf(hp.cat_sum("atk"), 0.01))], "0.24 0.4")
	# N08 체력 대가: 피 끓는 일격 −10% · 쓰러지지 않음
	b = _b(["ignis"], ["straw_golem"])
	ig = _w(b, "ignis")
	b.use_skill(ig, "blood_strike", b.enemies[0])
	var h1 := ig.hp
	ig.hp = 5000
	ig.credits = 7
	b.use_skill(ig, "blaze", b.enemies[0])
	_ok("N08 80,000 → 72,000 · 체력 5,000에 −15% (12,000) → 1", "%d %d" % [h1, ig.hp], "72000 1")
	# N09 번짐: 대상의 화상 3겹(남은 4)을 다른 적에게 같은 겹·남은 수로
	b = _b(["cinder"], ["straw_golem", "swamp_toad"])
	g = _e(b, "straw_golem")
	var td := _e(b, "swamp_toad")
	g.add_mark("burn", 4, 3)
	b.use_skill(_w(b, "cinder"), "ash_spread", g)
	_ok("N09 재 번짐 → 늪 두꺼비 화상 3겹 · 남은 4", "%d %d" % [td.mark_n("burn"), td.mark_dur("burn")], "3 4")
	# N10 풀구르 기본 공격 1.2배 3히트
	b = _b(["fulgur"], ["straw_golem"])
	t = _dummy(b, "none")
	_ok("N10 풀구르 기본 공격 → 무속성 표적 (각 0.4배)", str(_hits(b.basic_attack(_w(b, "fulgur"), t))), "[4600, 4600, 4600]")
	# N11 에스카 패시브 "틈": 때린 적은 받는 최종 데미지 +10% (따로 쌓지 않음)
	b = _b(["eska", "ignis"], ["straw_golem"])
	var es := _w(b, "eska")
	es.passive = TData.WITCHES.eska.passive.effects
	t = _dummy(b, "none")
	b.use_skill(es, "crack", t)
	b.use_skill(es, "crack", t)
	var n_ft := 0
	for bf in t.buffs:
		if bf.cat == "final_taken":
			n_ft += 1
	_ok("N11 균열 2번 → 틈 1개 · 이그니스 기본 공격 12,000 × 1.1 (틈) × 1.2 (균열 방어 다운 10%×2)", "%d %d" % [n_ft, _first(b.basic_attack(_w(b, "ignis"), t))], "1 15840")
	# N12 엠버 패시브: 거는 공격력 버프 +10%p
	b = _b(["ember", "ignis"], ["straw_golem"])
	_w(b, "ember").passive = TData.WITCHES.ember.passive.effects
	b.use_skill(_w(b, "ember"), "blessing", null)
	_ok("N12 불의 축복 30% + 불씨 지기 10%p", snappedf(_w(b, "ignis").cat_sum("atk"), 0.01), 0.4)
	# N13 이 공격만 특공은 고정값 (겹을 곱하지 않음)
	b = _b(["undine"], ["straw_golem"])
	t = _dummy(b, "fire")
	t.add_mark("frost", 3, 3)
	_ok("N13 쇄빙 일격 → 빙결 3겹이어도 특공 +50% 그대로", _first(b.use_skill(_w(b, "undine"), "ice_break", t)), 116100)
	# N14 번개: 크리 히트 1번마다 자신 게이지 +5% (벼락 내리꽂기 4히트 모두 크리)
	b = _b(["fulgur"], ["straw_golem"])
	fu = _w(b, "fulgur")
	_until(b, fu)
	fu.credits = 7
	b.fix_crit = 1
	b.use_skill(fu, "thunderbolt", b.enemies[0])
	b.end_action(fu)
	_ok("N14 벼락 내리꽂기 4크리 → 행동 뒤 게이지 200", int(fu.gauge), 200)
	# N15 겹 비례 버프 (불의 숨결: 화상 1겹마다 크리 데미지 +15%) · 토난 패시브 (감전 적 크리 데미지 +15%, 아군 전체)
	b = _b(["ignis", "ember"], ["straw_golem"])
	g = _e(b, "straw_golem")
	b.use_skill(_w(b, "ignis"), "breath_of_fire", _w(b, "ignis"))
	g.add_mark("burn", 3, 3)
	b.fix_crit = 1
	var bf3 := _first(b.basic_attack(_w(b, "ignis"), g))
	b = _b(["tonan", "ignis"], ["straw_golem"])
	_w(b, "tonan").passive = TData.WITCHES.tonan.passive.effects
	_e(b, "straw_golem").add_mark("shock", 3, 1)
	b.fix_crit = 1
	_ok("N15 불의 숨결 3겹 크리 18,000 × 1.95 · 토난 피뢰 표식 크리 18,000 × 1.65", "%d %d" % [bf3, _first(b.basic_attack(_w(b, "ignis"), _e(b, "straw_golem")))], "35100 29700")
	# N16 네레이 패시브: 도발 중 받는 피해 −10% 더 (아군 전체 −10%와 합쳐 −20%)
	b = _b(["nerei"], ["straw_golem"])
	_tough(b)
	ne = _w(b, "nerei")
	ne.passive = TData.WITCHES.nerei.passive.effects
	b.use_skill(ne, "wave_hold", null)
	g = _e(b, "straw_golem")
	g.intent_now = {"k": "attack", "mult": 1.0}
	_ok("N16 짚 골렘 공격 3,000 × 0.82 × 0.8 (도발 중)", _first(b.enemy_action(g)), 1968)
	# N17 대가 몰빵 기준 한 방 (§15.9 B8): 타는 왕관 + 풀무질 + 별빛 역류, 화상 3겹 → 태양 붕괴 크리
	b = _b(["ignis", "ember", "astra"], ["straw_golem"])
	ig = _w(b, "ignis")
	ig.passive = TData.WITCHES.ignis.passive.effects
	_w(b, "ember").passive = TData.WITCHES.ember.passive.effects
	g = _e(b, "straw_golem")
	g.add_mark("burn", 3, 3)
	b.use_skill(_w(b, "ember"), "crown", ig)
	b.use_skill(_w(b, "ember"), "bellows", ig)
	b.use_skill(_w(b, "astra"), "overcharge", ig)
	b.fix_crit = 1
	_ok("N17 대가 몰빵: 12,000 × 12 × 1.5 × 1.7 × 2.2 × 2.74 (보스 한 줄 150만의 1.5배)", _first(b.use_skill(ig, "ult_ignis", g)), 2213482)



## 단계 E (combat_proto.md §25.6): 예상 피해의 선버프 · 무적 내성 · 바뀐 수치 · 자동 선택의 대마법 모으기
func _stage_e_tests() -> void:
	# V20 종언 예상 = 실제 (선버프 공격력 +15%를 넣고 계산, review_F F06 a)
	var b := _b(["eska"], ["straw_golem"])
	var es := _w(b, "eska")
	var t := _dummy(b, "none")
	es.credits = 7
	var est := b.estimate(es, t, "doom")
	_ok("V20 종언 예상 = 실제 (선버프 포함)", "%d %d %d" % [est, _first(b.use_skill(es, "doom", t)), es.buffs.size()], "%d %d 1" % [est, est])
	# V21 천둥의 창 크리 예상 = 크리 고정 실제 (선버프 크리 데미지 +50%), 예상을 구해도 버프는 남지 않음
	b = _b(["fulgur"], ["straw_golem"])
	var fu := _w(b, "fulgur")
	t = _dummy(b, "none")
	fu.credits = 7
	var est_c := b.estimate(fu, t, "thunder_lance", true)
	var nb := fu.buffs.size()
	b.fix_crit = 1
	_ok("V21 천둥의 창 크리 예상 = 실제 · 예상 뒤 버프 0개", "%d %d %d" % [est_c, _first(b.use_skill(fu, "thunder_lance", t)), nb], "%d %d 0" % [est_c, est_c])
	# G01 무적 내성: 무적이 막은 마녀는 적 행동 2번 동안 무적이 다시 걸리지 않음 → 그 뒤 다시 걸림
	b = _b(["eska"], ["ash_knight"])
	_tough(b)
	es = _w(b, "eska")
	var k := _e(b, "ash_knight")
	es.credits = 7
	b.use_skill(es, "seal", null)
	k.intent_now = {"k": "attack", "mult": 1.0}
	var blocked := bool(b.enemy_action(k)[0].invincible)
	b.end_action(k)
	es.credits = 7
	var ev := b.use_skill(es, "seal", null)
	var guard1 := "inv_guard" in _kinds(ev)
	k.intent_now = {"k": "attack", "mult": 1.0}
	var hit2 := int(b.enemy_action(k)[0].dmg)
	b.end_action(k)
	k.intent_now = {"k": "buff", "v": 0.1, "dur": 1}
	b.enemy_action(k)
	b.end_action(k)
	es.credits = 7
	b.use_skill(es, "seal", null)
	_ok("G01 무적 내성: 막음 → 다시 봉공 '무적 내성' → 맞음 → 적 행동 2번 뒤 다시 무적", "%s %s %s %s" % [str(blocked), str(guard1), str(hit2 > 0), str(es.is_invincible())], "true true true true")
	# G02~G08 단계 E 수치
	_ok("G02 봉공 4비용 (전체 무적 = 4, §15.3)", TData.cost_of("seal"), 4)
	b = _b(["undine"], ["straw_golem"])
	var un := _w(b, "undine")
	t = _dummy(b, "fire")
	un.credits = 7
	b.use_skill(un, "ult_undine", t)
	_ok("G03 심연 붕괴: 크레딧 7 → 0 + 환급 2", un.credits, 2)
	b = _b(["ember", "ignis"], ["straw_golem"])
	var ig := _w(b, "ignis")
	ig.hp = 40000
	b.use_skill(_w(b, "ember"), "blessing", null)
	_ok("G04 불의 축복: 공격력 +30% · 체력 15% 회복 (40,000 → 52,000) · 크레딧 +0", "%s %d %d" % [str(snappedf(ig.cat_sum("atk"), 0.01)), ig.hp, ig.credits], "0.3 52000 0")
	b = _b(["nerei", "ignis"], ["straw_golem"])
	ig = _w(b, "ignis")
	b.use_skill(_w(b, "nerei"), "current", null)
	_ok("G05 밀려오는 조류: 받는 피해 −15% · 크레딧 +1 · 공격력 버프 없음", "%s %d %s" % [str(snappedf(ig.cat_sum("dmg_taken"), 0.01)), ig.credits, str(snappedf(ig.cat_sum("atk"), 0.01))], "-0.15 1 0.0")
	_ok("G06 세계의 틈은 디버프 (적 전체에 해로운 효과)", String(TData.skill("gap").kind), "debuff")
	b = _b(["glacia", "hora"], ["straw_golem"])
	t = _dummy(b, "none")
	b.use_skill(_w(b, "glacia"), "still_frost", t)
	b.use_skill(_w(b, "hora"), "stopped_clock", t)
	_ok("G07 멎는 서리 방어 다운 20% · 멈춘 시계 받는 최종 데미지 +15%", "%s %s" % [str(snappedf(t.cat_sum("def_down"), 0.01)), str(snappedf(t.cat_sum("final_taken"), 0.01))], "0.2 0.15")
	b = _b(["glacia"], ["straw_golem"])
	var gl := _w(b, "glacia")
	t = _dummy(b, "fire")
	gl.credits = 3
	b.use_skill(gl, "rime", t)
	var c1 := gl.credits
	b.use_skill(gl, "rime", t)
	_ok("G08 서리 내림: 빙결 없음 3→2 · 빙결 있음 2→2 (환급 +1)", "%d %d" % [c1, gl.credits], "2 2")
	# G09 자동 선택: 공격 대마법이 있는 딜러는 1비용 공격으로 크레딧을 흘리지 않고 모은다 (review_E E0)
	b = _b(["harpe"], ["straw_golem"])
	var hp := _w(b, "harpe")
	hp.equipped.assign(["bw_slash", "sword_ki", "heaven_split", "doom_slash"])
	_dummy(b, "none")
	hp.credits = 3
	var a := TAuto.pick(b, hp)
	hp.credits = 7
	var a7 := TAuto.pick(b, hp)
	_ok("G09 하르페 크레딧 3 → 기본 공격 (흑백 참격·검기 두르기 안 씀) · 7 → 종막의 검", "%s %s" % [String(a.kind), String(a7.skill)], "basic ult_harpe")


## 단계 F-1 (combat_proto.md §25.7): 차례 줄 미리보기(사용 뒤 · 다가오는 필살기) · 크리 확률·성공률 표시값 · 저장·불러오기 결정론 · 편성 파일 검증
func _stage_f_tests() -> void:
	# V17 박차 가하기(아군 게이지 +60%)를 고른 "사용 뒤" 줄 = 실제로 쓴 뒤의 줄 (review_F F05 규칙 B)
	var b := TBattle.new()
	b.setup(["astra", "ignis", "ember"], ["straw_golem", "ash_knight"], {}, 7)
	b.fix_rand = 1.0
	b.fix_crit = 0
	b.fix_roll = 0.0
	var u := b.next_actor()
	while not u.is_witch() or u.id != "astra":
		if u.is_witch():
			b.basic_attack(u, b.enemies[0])
		else:
			b.enemy_action(u)
		b.end_action(u)
		u = b.next_actor()
	u.credits = 7
	var ig := _w(b, "ignis")
	var q1 := b.preview_if(u, "spur", ig)
	b.use_skill(u, "spur", ig)
	b.end_action(u)
	var q2: Array[TUnit] = [u]
	q2.append_array(b.preview(7))
	_ok("V17 사용 뒤 줄 = 쓴 뒤 줄 (박차 가하기 → 이그니스)", _names(q1), _names(q2))
	# V18 성질: 시드 30개 × TAuto 행동 40번 — 마녀가 고를 때마다 preview_if == 실행 뒤 [그 마녀] + preview(7) (판정 성공 고정)
	var bad := 0
	var checks := 0
	for sd in 30:
		b = TBattle.new()
		b.setup(["astra", "glacia", "hora"] if sd % 2 == 0 else ["tonan", "ember", "eska"], "normal_01", {}, 100 + sd)
		b.fix_rand = 1.0
		b.fix_crit = 0
		b.fix_roll = 0.0
		for k in 40:
			if b.outcome() != "":
				break
			u = b.next_actor()
			if u.stunned:
				b.rest(u)
			elif u.is_witch():
				var a := TAuto.pick(b, u)
				var sid := "basic" if String(a.kind) == "basic" else String(a.skill)
				var qa := b.preview_if(u, sid, a.get("target"))
				if sid == "basic":
					b.basic_attack(u, a.get("target"))
				else:
					b.use_skill(u, sid, a.get("target"))
				b.end_action(u)
				var qb: Array[TUnit] = [u]
				qb.append_array(b.preview(7))
				checks += 1
				if _names(qa) != _names(qb):
					bad += 1
				continue
			else:
				b.enemy_action(u)
			b.end_action(u)
	_ok("V18 사용 뒤 줄 성질 시험 (%d번 비교) — 어긋남" % checks, bad, 0)
	# V19 재의 기사 차지 2/5 → 그 적의 앞으로 4번째 행동이 필살기 칸 · 실제로도 4번째 행동이 필살기 (F05 규칙 A)
	b = _b(["ignis", "ember", "eska"], ["ash_knight"])
	_tough(b)
	var kn := b.enemies[0]
	kn.max_hp = 1000000000
	kn.hp = kn.max_hp
	kn.charge = 2
	b.decide_intent(kn)
	var q := b.preview(24)
	var fin := b.finisher_slots(q)
	var nth := 0
	var fin_nth := -1
	for i in q.size():
		if q[i] == kn:
			nth += 1
			if fin.has(i) and fin_nth < 0:
				fin_nth = nth
	var acts := 0
	var real_nth := -1
	for k in 60:
		u = b.next_actor()
		if u.is_witch():
			b.basic_attack(u, kn)
		else:
			acts += 1
			if String(u.intent().get("k", "")) == "finisher" and real_nth < 0:
				real_nth = acts
			b.enemy_action(u)
		b.end_action(u)
	_ok("V19 차지 2/5 → 필살기 칸 = 앞으로 4번째 행동 = 실제 필살기", "%d %d" % [fin_nth, real_nth], "4 4")
	# V22 크리 확률 표시값 = 기본 10% + 태양의 창 선버프 40% (예상을 구해도 버프는 남지 않음, F06 b)
	b = _b(["ignis"], ["straw_golem"])
	var ig2 := _w(b, "ignis")
	var t := _dummy(b, "none")
	var info := b.est_info(ig2, t, "sun_spear")
	_ok("V22 태양의 창 크리 확률 표시 0.5 · 버프 0개", "%s %d" % [str(snappedf(float(info.rate), 0.001)), ig2.buffs.size()], "0.5 0")
	# V23 성공률 표시: 재의 왕(내성 30%)에 확률 100% 디버프 → 70% · 글라시아(패시브 +15%) → 85% (F06 c)
	b = TBattle.new()
	b.setup(["ignis", "glacia"], "boss_01", {}, 3)
	var king := TUnit.make_enemy("ash_king", 0)
	_ok("V23 성공률 재의 왕 70% · 글라시아 85%", "%d %d" % [int(round(b.success_rate(b.witches[0], king, {"rate": 1.0}) * 100.0)), int(round(b.success_rate(b.witches[1], king, {"rate": 1.0}) * 100.0))], "70 85")
	# V25 저장·불러오기 결정론: 40번 행동한 뒤 마녀 차례 시작에서 저장 → 끊지 않은 전투의 다음 20번 = 불러온 전투의 20번 (F07)
	var seq := func(bb: TBattle, n: int, from_saved: bool) -> String:
		var lines: Array = []
		for k in n:
			if bb.outcome() != "":
				break
			var uu := bb.next_actor()
			if uu.stunned:
				bb.rest(uu)
			elif uu.is_witch():
				var aa := TAuto.pick(bb, uu)
				if String(aa.kind) == "basic":
					bb.basic_attack(uu, aa.get("target"))
				else:
					bb.use_skill(uu, String(aa.skill), aa.get("target"))
			else:
				bb.enemy_action(uu)
			bb.end_action(uu)
			if bb.outcome() == "wave":
				bb.next_wave()
		for w in bb.all_units():
			lines.append("%s:%d:%d" % [w.id, w.hp, w.credits])
		return "%s|%s" % [" ".join(lines), str(bb.log.slice(maxi(bb.log.size() - 12, 0)))]
	b = TBattle.new()
	b.setup(["harpe", "nerei", "astra"], "boss_01", {}, 4242)
	var snap := {}
	var done := 0
	while done < 400:
		u = b.next_actor()
		if u.is_witch() and done >= 40 and snap.is_empty() and not u.stunned:
			snap = b.to_dict()
			# 저장한 차례를 이 전투에서도 이어서: 아래 seq가 next_actor를 다시 부르므로 resume 표시
			b.resume = true
			break
		if u.stunned:
			b.rest(u)
		elif u.is_witch():
			var a := TAuto.pick(b, u)
			if String(a.kind) == "basic":
				b.basic_attack(u, a.get("target"))
			else:
				b.use_skill(u, String(a.skill), a.get("target"))
		else:
			b.enemy_action(u)
		b.end_action(u)
		if b.outcome() == "wave":
			b.next_wave()
		done += 1
	var text := var_to_str(snap)
	var b2 := TBattle.from_dict(str_to_var(text))
	var r1: String = seq.call(b, 20, false)
	var r2: String = seq.call(b2, 20, true)
	_ok("V25 저장 → 글 → 불러와 20번 = 끊지 않은 20번 (체력·크레딧·기록)", r1 == r2 and not snap.is_empty(), true)
	# V26 데이터에서 빠진 id가 든 편성 파일 → 기본값으로 채움
	var ps := TSave.parse_setup({"party": ["eska", "nope", "ignis"], "witch": {"eska": {"equipped": ["crack", "zzz", "crack"], "equip": "nothing", "equip_lv": 9, "skill_lv": {"crack": 3, "zzz": 2}}}, "battle_pick": "nope", "cleared": ["normal_01", "x"]})
	var es: Dictionary = ps.state.eska
	_ok("V26 모르는 마녀·마법·장비·전투를 버림 (파티 기본 · 장착 crack · 장비 없음 · Lv3 · 전투 기본 · 깸 normal_01)", "%s %s %s %d %s %s %s" % [str(ps.state.party), str(es.equipped), String(es.equip), int(es.equip_lv), str(es.skill_lv), String(ps.pick), str(TSave.cleared)],
		"%s [\"crack\"]  3 { \"crack\": 3 } %s [\"normal_01\"]" % [str(TData.BATTLE.party), TData.BATTLE.battle])
	TSave.cleared = []
	# V27 끊긴 전투 파일: 쓰기 → 있음 → 읽기(같은 차례) → 지우기 → 없음
	TSave.enabled = true
	TSave.dir = "user://test_rules/"
	TSave.save_battle(snap)
	var had := TSave.has_battle()
	var back := TSave.load_battle()
	TSave.clear_battle()
	_ok("V27 끊긴 전투 파일 쓰기·읽기·지우기", "%s %d %s" % [str(had), int(back.get("turn_no", -1)), str(TSave.has_battle())], "true %d false" % int(snap.turn_no))
	# V28 용어 풀이: 글에 나온 첫 용어
	_ok("V28 용어 풀이 첫 용어 (겹·특공 글 → 겹)", TData.gloss_for("화상 겹마다 특공").get_slice(" — ", 0), "겹")


func _names(q: Array) -> String:
	var out: Array = []
	for x in q:
		out.append((x as TUnit).name)
	return ",".join(out)

