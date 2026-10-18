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
	_stage_f2_tests()
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
	_ok("D04 태양의 창 (가득 찬 적 → 체력 비례 +50%, F-4)", _first(b.use_skill(_w(b, "ignis"), "sun_spear", _e(b, "straw_golem"))), 189000)

	for c in [["D05 + 풀무질 (화상 특공 25%/겹), 화상 1겹", 1, 236250], ["D06 화상 3겹 (75%)", 3, 330750], ["D07 화상 5겹 (125%)", 5, 425250]]:
		b = _b(["ignis", "ember"], ["straw_golem"])
		b.use_skill(_w(b, "ember"), "bellows", _w(b, "ignis"))
		_e(b, "straw_golem").add_mark("burn", 3, int(c[1]))
		_ok(String(c[0]), _first(b.use_skill(_w(b, "ignis"), "sun_spear", _e(b, "straw_golem"))), int(c[2]))

	for c in [["D08 D06 + 불의 축복 30% + 열기 응축 80% (다음 공격 마법)", 0, 694575], ["D09 D08이 크리 (×1.5)", 1, 1041863]]:
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
	_ok("D20 태양의 창 강화 Lv3 (9.1배 · 체력 비례 +65%)", _first(b.use_skill(_w(b, "ignis"), "sun_spear", _e(b, "straw_golem"))), 270270)
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
	# F-4 대화재(겹을 남김): 짚 골렘 (4.0 + 0.5×2) × 12,000 × 1.5 = 90,000 / 늪 두꺼비(물, 방어 20%): (4.0 + 0.5) × 12,000 × 1.0 × 0.8 = 43,200 — 터뜨림 사건 없음, 겹 그대로
	_ok("X24 광역 겹 비례 → 대상마다 자기 겹, 징표는 남음 (F-4 대화재)", "%s [%s] %d" % [str(_hits(ev)), ",".join(bn), _e(b, "straw_golem").mark_n("burn")], "[90000, 43200] [] 2")
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
	_ok("N02 열기 응축 → 기본 공격 18,000(그대로) → 태양의 창 126,000 × 1.8 (× 체력 비례 — 기본 공격 뒤 99.998%) → 사라짐", "%d %d %s" % [nb, ns, str(ig.has_skill_buff("focus"))], "18000 340196 false")
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
	_ok("N03 심연 붕괴 연쇄 2단계: 빙결 특공 +15% → +18.75% · 배율 ×1.15 (F-4 P2) · 기본 공격 뒤 끊김", "%d %d | %d" % [st, d2, b.chain_stage], "2 221231 | 0")
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
	_ok("N13 빙하 붕괴 → 빙결 3겹이어도 이 공격만 특공 +30% 그대로 (F-4: 쇄빙 일격은 겹 비례로 바뀌어 V69)", _first(b.use_skill(_w(b, "undine"), "glacier", t)), 107640)
	_ok("V69 쇄빙 일격 → 빙결 3겹: 배율 4.3 + 0.6 × 3, 겹 남음 (F-4)", "%d %d" % [_first(b.use_skill(_w(b, "undine"), "ice_break", t)), t.mark_n("frost")], "109800 3")
	# N14 번개: 크리 히트 1번마다 자신 게이지 +5% (벼락 내리꽂기 4히트 모두 크리)
	b = _b(["fulgur"], ["straw_golem"])
	fu = _w(b, "fulgur")
	_until(b, fu)
	fu.credits = 7
	b.fix_crit = 1
	b.use_skill(fu, "thunderbolt", b.enemies[0])
	b.end_action(fu)
	_ok("N14 벼락 내리꽂기 4크리 → 행동 뒤 게이지 200", int(fu.gauge), 200)
	# N15 겹 비례 버프 (F-4 불의 숨결: 자신 다음 공격 마법 1번 크리 확정 + 화상 1겹마다 크리 데미지 +15%) · 토난 패시브 (감전 적 크리 데미지 +30%, 아군 전체)
	#   화상 3겹 + 기본 공격(불씨 튀김) 1겹 = 4겹 → 불씨 찌르기 2.0배 × 12,000 × 1.5 = 36,000 × 크리 (1.5 + 0.6) = 75,600 — 기본 공격엔 닳지 않고(크리 아님 18,000) 공격 마법 뒤 사라짐
	b = _b(["ignis", "ember"], ["straw_golem"])
	g = _e(b, "straw_golem")
	var ign := _w(b, "ignis")
	_until(b, ign)
	b.use_skill(ign, "breath_of_fire", ign)
	b.end_action(ign)
	g.add_mark("burn", 3, 3)
	_until(b, ign)
	var bb0 := _first(b.basic_attack(ign, g))
	b.end_action(ign)
	_until(b, ign)
	ign.credits = 7
	b.fix_crit = -1
	var bf3 := _first(b.use_skill(ign, "spark", g))
	b.end_action(ign)
	bf3 = bf3 if bb0 == 18000 and not ign.has_skill_buff("breath_of_fire") else -bf3
	b = _b(["tonan", "ignis"], ["straw_golem"])
	_w(b, "tonan").passive = TData.WITCHES.tonan.passive.effects
	_e(b, "straw_golem").add_mark("shock", 3, 1)
	b.fix_crit = 1
	_ok("N15 불의 숨결 4겹 → 불씨 찌르기 확정 크리 36,000 × 2.1 · 토난 피뢰 표식 크리 18,000 × 1.8", "%d %d" % [bf3, _first(b.basic_attack(_w(b, "ignis"), _e(b, "straw_golem")))], "75600 32400")
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
	_ok("G07 멎는 서리 방어 다운 20% · 멈춘 시계 받는 최종 데미지 +20% (F-4 15 → 20)", "%s %s" % [str(snappedf(t.cat_sum("def_down"), 0.01)), str(snappedf(t.cat_sum("final_taken"), 0.01))], "0.2 0.2")
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
	# V22 크리 확률 표시값 = 기본 10% + 태양의 창 선버프 30% (F-4 40 → 30) (예상을 구해도 버프는 남지 않음, F06 b)
	b = _b(["ignis"], ["straw_golem"])
	var ig2 := _w(b, "ignis")
	var t := _dummy(b, "none")
	var info := b.est_info(ig2, t, "sun_spear")
	_ok("V22 태양의 창 크리 확률 표시 0.4 · 버프 0개", "%s %d" % [str(snappedf(float(info.rate), 0.001)), ig2.buffs.size()], "0.4 0")
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
	_ok("V28 용어 풀이 첫 용어 (화상 → 징표 별칭 · 도움말에서 연 징표는 건너뜀 → 겹, review_I I-14)", "%s %s" % [TData.gloss_for("화상 겹마다 특공").get_slice(" — ", 0), TData.gloss_for("화상 겹마다 특공", {"징표": true}).get_slice(" — ", 0)], "징표 겹")


# ═══════════════════════════════════════════════════════════
# 단계 F-2 — 적 엔진 (review_F F01·F02 V01~V16 · review_H §10.2 V38~V45 · 새 규칙 V46~)
# ═══════════════════════════════════════════════════════════

## 적 u에게 의도 it를 정해 두고 실행 → end_action. 돌려준 사건
func _act(b: TBattle, u: TUnit, it: Dictionary) -> Array:
	u.intent_now = it
	u.intent_src = "insert"
	b.actor = u
	var ev := b.enemy_action(u)
	b.end_action(u)
	return ev


func _stage_f2_tests() -> void:
	print("── 단계 F-2 적 엔진")
	# V01 봉인(피해 0) → 이그니스 크레딧 5: 다음 차례 크레딧 6 · 장착 4개·대마법 못 씀 · 기본 공격 → 7 · 그 차례 끝 봉인 풀림 + 봉인 내성
	var b := _b(["ignis"], ["thunder_crow"])
	_tough(b)
	var ig := _w(b, "ignis")
	var crow := b.enemies[0]
	ig.credits = 5
	_act(b, crow, {"k": "seal", "mult": 0.0})
	_until(b, ig)
	var any_ok := false
	for sid in ig.equipped:
		any_ok = any_ok or b.can_use(ig, sid)
	var c6 := ig.credits
	ig.credits = 7
	var ult_ok := b.can_use(ig, "ult_ignis")
	ig.credits = c6
	b.basic_attack(ig, crow)
	var c7 := ig.credits
	b.end_action(ig)
	_ok("V01 봉인 → 크레딧 6 · 장착 마법·대마법 못 씀 · 기본 공격 7 · 풀림 + 봉인 내성", "%d %s %s %d %d %s" % [c6, str(any_ok), str(ult_ok), c7, ig.sealed, str(ig.seal_guard)], "6 false false 7 0 true")
	# 봉인 내성 중엔 봉인되지 않고 ("seal_resist"), 그다음 자기 차례가 끝나면 내성도 풀림
	var ev := _act(b, crow, {"k": "seal", "mult": 0.0})
	var resisted := _kinds(ev).has("seal_resist") and ig.sealed == 0
	_until(b, ig)
	b.basic_attack(ig, crow)
	b.end_action(ig)
	_ok("V01b 봉인 내성 중 봉인 → 막힘 · 다음 차례 끝에 내성 풀림", "%s %s" % [str(resisted), str(ig.seal_guard)], "true false")
	# V02 대마법 봉인 → 크레딧 7 운디네: 장착 마법은 됨 · 대마법만 못 씀
	b = _b(["undine"], ["thunder_crow"])
	_tough(b)
	var un := _w(b, "undine")
	_act(b, b.enemies[0], {"k": "seal", "mult": 0.0, "ult": true})
	un.credits = 7
	_ok("V02 대마법 봉인: 물의 창 됨 · 심연 붕괴 못 씀", "%s %s" % [str(b.can_use(un, "water_lance")), str(b.can_use(un, "ult_undine"))], "true false")
	# V03 무적 마녀에게 봉인 공격(피해 있음) → 피해 0 · 봉인 없음
	b = _b(["ignis"], ["thunder_crow"])
	_tough(b)
	ig = _w(b, "ignis")
	ig.add_buff({"cat": "invincible", "v": 1.0, "dur": 2, "clock": "enemy"})
	ev = _act(b, b.enemies[0], {"k": "seal", "mult": 0.6})
	_ok("V03 무적 → 봉인 공격 피해 0 · 봉인 없음", "%d %d" % [_first(ev), ig.sealed], "0 0")
	# V04 약화(공격력 −20%, 행동 2번) 뒤 이그니스 기본 공격 → 짚 골렘 = 18,000 × 0.8
	b = _b(["ignis"], ["straw_golem"])
	_tough(b)
	ig = _w(b, "ignis")
	var g := b.enemies[0]
	_act(b, g, {"k": "weaken", "cat": "atk_down", "v": 0.20, "dur": 2})
	var d4 := _first(b.basic_attack(ig, g))
	_ok("V04 약화 공격력 −20% → 기본 공격 14,400 (나쁜 효과 bad)", "%d %s" % [d4, str(bool(ig.buffs[0].get("bad", false)))], "14400 true")
	# V05 방어 태세 −50% 짚 골렘에게 태양의 창 = 126,000 × 0.5 · 방어 무시 마법(공간 압축 → 빈 갑주)도 같이 반
	b = _b(["ignis", "eska"], ["straw_golem", "hollow_armor"])
	ig = _w(b, "ignis")
	var es := _w(b, "eska")
	g = b.enemies[0]
	var ha := b.enemies[1]
	var plain := b.estimate(es, ha, "compress")
	g.add_buff({"cat": "dmg_cut", "v": 0.5, "dur": 3, "clock": "own"})
	ha.add_buff({"cat": "dmg_cut", "v": 0.5, "dur": 3, "clock": "own"})
	_ok("V05 방어 태세 −50%: 태양의 창 94,500 (체력 비례 포함) · 공간 압축(방어 무시) 67,080 → 33,540", "%d %d %d" % [b.estimate(ig, g, "sun_spear"), plain, b.estimate(es, ha, "compress")], "94500 67080 33540")
	# V06 방어 태세 −50% 둘 → −70% 상한
	g.add_buff({"cat": "dmg_cut", "v": 0.5, "dur": 3, "clock": "own"})
	_ok("V06 방어 태세 둘 → 상한 70% (189,000 × 0.3)", b.estimate(ig, g, "sun_spear"), 56700)
	# V07 막아서기 중 단일 대상 후보 = 막아서는 적만 · 광역은 전원 · 기본 공격 후보도
	b = _b(["fulgur"], ["mist_jelly", "swamp_toad", "frost_knight"])
	var fu := _w(b, "fulgur")
	fu.credits = 7
	var fk := b.enemies[2]
	_act(b, fk, {"k": "cover", "dur": 2})
	var vt := b.valid_targets(fu, "thunderbolt")
	_ok("V07 막아서기: 단일 후보 서리 기사 1 · 기본 공격 후보 1 · 광역 맞는 적 3", "%d %s %d %d" % [vt.size(), vt[0].id, b.foe_targets().size(), b._resolve_targets(fu, TData.skill("chain_lightning"), null).size()], "1 frost_knight 1 3")
	# V08 재촉: 재의 기사 차지 2 → 3 · 4 → 5(가득)면 의도가 필살기로
	b = _b(["ignis"], ["will_o", "ash_knight"])
	_tough(b)
	var kn := b.enemies[1]
	kn.charge = 2
	_act(b, b.enemies[0], {"k": "rally", "charge": 1})
	var c3 := kn.charge
	kn.charge = 4
	b.decide_intent(kn)
	_act(b, b.enemies[0], {"k": "rally", "charge": 1})
	_ok("V08 재촉 차지 2 → 3 · 4 → 5 → 의도 필살기", "%d %d %s" % [c3, kn.charge, String(kn.intent().get("k", ""))], "3 5 finisher")
	# V09 부르기: 빈 칸 없음 → 안 고름 · 빈 칸 1 → 부르기, 그 칸에 새 적(게이지 0) · summon_cap에 닿으면 안 고름
	b = _b(["ignis"], ["ash_servant", "lantern_keeper", "ash_servant"])
	_tough(b)
	var lk := b.enemies[1]
	b.decide_intent(lk)
	var k0 := String(lk.intent().get("k", ""))
	b.deal(b.enemies[0], b.enemies[0].hp)
	b.decide_intent(lk)
	var k1 := String(lk.intent().get("k", ""))
	ev = _act(b, lk, lk.intent())
	var sm: Dictionary = {}
	for e in ev:
		if e.t == "summon":
			sm = e
	var nu: TUnit = b.enemies[0]
	var k2s := "%s %s %d %d" % [k0, k1, int(sm.get("slot", -1)), int(nu.gauge)]
	b.deal(b.enemies[0], b.enemies[0].hp)
	b.summoned = 4
	b.decide_intent(lk)
	_ok("V09 부르기: 빈 칸 없음 → 공격 · 빈 칸 → 부르기 · 칸 0에 새 시종 게이지 0 · 4번 부르면 안 부름", "%s %s %s" % [k2s, str(nu.id == "ash_servant"), String(lk.intent().get("k", ""))],
		"attack summon 0 0 true attack")
	# V10 자폭: 시종 차지 3 → 필살기(자폭) → 마녀 피해 뒤 시종 쓰러짐 · 마지막 적이면 승리
	b = _b(["ignis", "ember"], ["ash_servant"])
	_tough(b)
	var sv := b.enemies[0]
	sv.charge = 3
	b.decide_intent(sv)
	b.actor = sv
	ev = b.enemy_action(sv)
	_ok("V10 자폭: 히트 2 · 시종 쓰러짐 · 승리", "%d %s %s %s" % [_hits(ev).size(), str(sv.alive), str(_kinds(ev).has("self_ko")), b.outcome()], "2 false true win")
	# V11 징표 털기: 화상 4겹·방어 다운 → 화상 0 · 방어 다운 남음
	b = _b(["ignis"], ["ash_king"])
	_tough(b)
	var kg := b.enemies[0]
	kg.add_mark("burn", 3, 4)
	kg.add_buff({"cat": "def_down", "v": 0.2, "dur": 3, "clock": "own"})
	ev = _act(b, kg, {"k": "purge"})
	_ok("V11 징표 털기: 화상 0 · 방어 다운 남음 · 사건 n 4", "%d %s %d" % [kg.mark_n("burn"), str(kg.has_buff("def_down")), int(ev[0].n)], "0 true 4")
	# V12 보스 해제: 공격력 +50%(이로움) · 공격력 다운 20%(나쁨) → 공격력 다운만 남음
	b = _b(["ignis"], ["ash_king"])
	_tough(b)
	ig = _w(b, "ignis")
	ig.add_buff({"cat": "atk", "v": 0.5, "dur": 3, "clock": "own"})
	_act(b, b.enemies[0], {"k": "weaken", "cat": "atk_down", "v": 0.20, "dur": 3})
	_act(b, b.enemies[0], {"k": "dispel"})
	_ok("V12 해제가 나쁜 효과를 남김 (공격력 다운만)", "%d %s" % [ig.buffs.size(), String(ig.buffs[0].cat) if not ig.buffs.is_empty() else ""], "1 atk_down")
	# V14 화상 최대 3겹 적(화로 거북)에게 화상 5번 → 3겹
	b = _b(["cinder"], ["hearth_turtle"])
	var tt := b.enemies[0]
	for k in 5:
		b._add_mark(_w(b, "cinder"), tt, "burn", 3, 1)
	_ok("V14 달군 몸: 화상 5번 → 3겹", tt.mark_n("burn"), 3)
	# V16 적 크리 15% − 크리 다운 20% → 0% (200번 맞혀 크리 0) · 크리 다운 없으면 15%
	b = _b(["nerei"], ["thunder_crow"])
	_tough(b)
	b.fix_crit = -1
	crow = b.enemies[0]
	crow.add_buff({"cat": "crit_down", "v": 0.2, "dur": 999, "clock": "own"})
	var nc := 0
	for k in 200:
		if bool(b._enemy_hit(crow, b.witches[0], 1.0).crit):
			nc += 1
	_ok("V16 까마귀 크리 15% · 크리 다운 20% → 200번 중 크리 0", "%s %d" % [str(snappedf(crow.ecrit, 0.01)), nc], "0.15 0")
	# V38 세 빛의 인형 줄 1 브레이크 → 약점 불 · 속성 번개 · 패턴 [공격, 방어 태세, 강공격 2.2, 전체] · 줄 3 → 약점 물
	b = _b(["ignis"], ["prism_doll"])
	var pd := b.enemies[0]
	var w0 := str(pd.weak)
	b.deal(pd, 2000000)
	var pk: Array = []
	for it in pd.pattern:
		pk.append("%s%s" % [String(it.k), (str(float(it.mult)) if it.has("mult") and String(it.k) == "heavy" else "")])
	var mid := "%s %s %s" % [str(pd.weak), pd.element, " ".join(pk)]
	b.deal(pd, 2000000)
	_ok("V38 세 빛의 인형 줄마다 약점 (번개 → 불 → 물)", "%s | %s | %s" % [w0, mid, str(pd.weak)], "[\"bolt\"] | [\"fire\"] bolt attack guard heavy2.2 aoe | [\"water\"]")
	# V39 봉인 공격 → 아스트라: 대마법·장착 마법 못 씀 · 기본 공격 됨
	b = _b(["astra"], ["thunder_crow"])
	_tough(b)
	var asr := _w(b, "astra")
	_act(b, b.enemies[0], {"k": "seal", "mult": 0.6})
	asr.credits = 7
	var eq_ok := false
	for sid in asr.equipped:
		eq_ok = eq_ok or b.can_use(asr, sid)
	_ok("V39 봉인 → 아스트라 대마법·장착 못 씀 · 기본 공격 피해 > 0", "%s %s %s" % [str(b.can_use(asr, "ult_astra")), str(eq_ok), str(_first(b.basic_attack(asr, b.enemies[0])) > 0)], "false false true")
	# V40 등불지기 + 시종 살아 있음 → 태양의 창 × 0.7 · 시종이 쓰러지면 × 1.0 (12,000 × 7.0 × 방어 0.8 = 67,200)
	b = _b(["ignis"], ["ash_servant", "lantern_keeper"])
	ig = _w(b, "ignis")
	lk = b.enemies[1]
	var with_s := b.estimate(ig, lk, "sun_spear")
	b.deal(b.enemies[0], b.enemies[0].hp)
	_ok("V40 등불 가림 −30% (시종 살아 있음) → 쓰러진 뒤 그대로 (태양의 창 체력 비례 +50% 포함)", "%d %d" % [with_s, b.estimate(ig, lk, "sun_spear")], "70560 100800")
	# V41 둥지어미가 쓰러짐(시종 2 살아 있음) → 나머지도 사라짐 · 마지막 웨이브면 승리
	b = _b(["ignis"], ["ash_servant", "ash_brood", "ash_servant"])
	var br := b.enemies[1]
	b.deal(br, 2800000)
	var res := b.deal(br, 2800000)
	_ok("V41 우두머리 쓰러짐 → 졸개 2 사라짐 · 승리", "%d %s" % [(res.get("fall", []) as Array).size(), b.outcome()], "2 win")
	# V42 화로 거북에 신더 화상 2겹 × 3번 → 3겹
	b = _b(["cinder"], ["hearth_turtle"])
	tt = b.enemies[0]
	for k in 3:
		b._add_mark(_w(b, "cinder"), tt, "burn", 3, 2)
	_ok("V42 달군 몸: 화상 2겹 × 3 → 3겹", tt.mark_n("burn"), 3)
	# V43 시종 차지 3 → 자폭: 마녀 전원 피해 뒤 시종 쓰러짐 · 빈 칸 1 → 둥지어미 다음 의도 = 부르기 (부른 수 0 < 3)
	b = _b(["ignis", "ember", "eska"], ["ash_servant", "ash_brood", "ash_servant"])
	_tough(b)
	sv = b.enemies[0]
	sv.charge = 3
	b.decide_intent(sv)
	b.actor = sv
	ev = b.enemy_action(sv)
	b.end_action(sv)
	b.decide_intent(b.enemies[1])
	_ok("V43 자폭 → 히트 3 · 시종 쓰러짐 · 둥지어미 부르기", "%d %s %s" % [_hits(ev).size(), str(sv.alive), String(b.enemies[1].intent().get("k", ""))], "3 false summon")
	# V44 그림자 서기: 운디네 크레딧 6 → 의도 = 크레딧 흩기 · 실행 뒤 전원 −2 (0 아래 안 감)
	b = _b(["undine", "ignis"], ["shade_scribe"])
	_tough(b)
	un = _w(b, "undine")
	ig = _w(b, "ignis")
	un.credits = 6
	ig.credits = 1
	var sc := b.enemies[0]
	b.decide_intent(sc)
	var k44 := String(sc.intent().get("k", ""))
	b.actor = sc
	b.enemy_action(sc)
	_ok("V44 크레딧 흩기: 의도 scatter · 운디네 6 → 4 · 이그니스 1 → 0", "%s %d %d" % [k44, un.credits, ig.credits], "scatter 4 0")
	# V45 보스 해제: 공격력 +50%(이로움) · 받는 피해 +20%(불꽃 사제, bad) → 받는 피해 +20%만 남음
	b = _b(["ignis"], ["flame_priest", "ash_king"])
	_tough(b)
	ig = _w(b, "ignis")
	ig.add_buff({"cat": "atk", "v": 0.5, "dur": 3, "clock": "own"})
	b.enemies[0].intent_now = {"k": "weaken", "cat": "dmg_taken", "v": 0.20, "dur": 3, "aoe": true}
	b.actor = b.enemies[0]
	b.enemy_action(b.enemies[0]) # (end_action 없이 — 받는 피해가 적 행동마다 닳으므로)
	b.enemies[1].intent_now = {"k": "dispel"}
	b.enemy_action(b.enemies[1])
	_ok("V45 해제 뒤 받는 피해 +20%만 남음", "%d %s %s" % [ig.buffs.size(), String(ig.buffs[0].cat) if not ig.buffs.is_empty() else "", str(snappedf(ig.cat_sum("dmg_taken"), 0.01))], "1 dmg_taken 0.2")
	# V46 받는 피해 +20% 약화 = 적 행동 2번 (적 버프 §18.8처럼 건 행동부터 셈 → 다음 적 행동 하나를 맞음)
	b = _b(["ignis"], ["flame_priest", "straw_golem"])
	_tough(b)
	ig = _w(b, "ignis")
	_act(b, b.enemies[0], b.enemies[0].data.pattern[0])
	var n1 := ig.buffs.size()
	_act(b, b.enemies[1], {"k": "attack", "mult": 1.0})
	var n2 := ig.buffs.size()
	_act(b, b.enemies[1], {"k": "attack", "mult": 1.0})
	_ok("V46 받는 피해 약화(적 행동 2번 — 건 행동부터 셈): 건 뒤 1 · 적 행동 1번 뒤 0", "%d %d %d" % [n1, n2, ig.buffs.size()], "1 0 0")
	# V47 방어 태세(2) = 그 적의 행동 2번 (건 행동부터 셈): 태세 → 있음 · 다음 자기 행동이 끝나면 없음
	b = _b(["ignis"], ["volt_golem"])
	_tough(b)
	var vg := b.enemies[0]
	_act(b, vg, {"k": "guard", "v": 0.5, "dur": 2})
	var g1 := vg.has_buff("dmg_cut")
	_act(b, vg, {"k": "attack", "mult": 1.0})
	var g2 := vg.has_buff("dmg_cut")
	_act(b, vg, {"k": "attack", "mult": 1.0})
	_ok("V47 방어 태세 지속: 건 뒤 있음 · 다음 행동 뒤 없음", "%s %s %s" % [str(g1), str(g2), str(vg.has_buff("dmg_cut"))], "true false false")
	# V48 먼저 날아듦: 뇌운 고개 시작 게이지 까마귀 500 · 골렘 0
	b = TBattle.new()
	b.setup(["ignis"], "normal_bolt", {}, 1)
	_ok("V48 먼저 날아듦 게이지 +50%", "%d %d %d" % [int(b.enemies[0].gauge), int(b.enemies[1].gauge), int(b.enemies[2].gauge)], "500 500 0")
	# V49 조건 self_buff (+not) · allies_alive (틀만 — 데이터에 규칙을 넣어 확인)
	b = _b(["ignis"], ["straw_golem", "swamp_toad"])
	g = b.enemies[0]
	g.data = g.data.duplicate(true)
	g.data["rules"] = [{"when": {"self_buff": "dmg_cut", "not": true, "allies_alive": 1}, "insert": {"k": "guard", "v": 0.5, "dur": 2}}]
	b.decide_intent(g)
	var ka := String(g.intent().get("k", ""))
	g.add_buff({"cat": "dmg_cut", "v": 0.5, "dur": 3, "clock": "own"})
	b.decide_intent(g)
	var kb := String(g.intent().get("k", ""))
	g.buffs.clear()
	b.deal(b.enemies[1], b.enemies[1].hp)
	b.decide_intent(g)
	_ok("V49 조건 self_buff not · allies_alive: 태세 없음 → guard · 태세 있음 → 패턴 · 동료 없음 → 패턴", "%s %s %s" % [ka, kb, String(g.intent().get("k", ""))], "guard attack attack")
	# V50 웨이브 구성 규칙 (F04): 새 보스 전투 통과 · boss_01은 ①② 43%(1.6 그대로 — 규칙은 새 보스 전투부터) · 일반 전투 모두 통과
	var bad_n := 0
	for bid in TData.BATTLE_ORDER:
		if String(bid) != "boss_01":
			bad_n += TBattle.wave_rules(String(bid)).size()
	_ok("V50 웨이브 규칙: 새 전투 어긋남 0 · boss_01 ①②", "%d %s" % [bad_n, str(TBattle.wave_rules("boss_01"))], "0 [\"웨이브 ①② 체력 43% (> 35%)\"]")
	# V51 저장·불러오기: 봉인·부른 수가 남음
	b = TBattle.new()
	b.setup(["ignis", "ember"], "normal_swarm", {}, 5)
	b.witches[0].sealed = 1
	b.summoned = 2
	var b2 := TBattle.from_dict(str_to_var(var_to_str(b.to_dict())))
	_ok("V51 저장: 봉인 · 부른 수 · 고유 효과 (등불 가림 · 흩날리는 재)", "%d %d %d" % [b2.witches[0].sealed, b2.summoned, b2.enemies[1].passive.size()], "1 2 2")
	# V52 데이터 판 (review_I I-03): 지금 판 사본은 읽힘 · 판이 다르거나(1.7 파일 = 판 없음) 모르는 적·마법 id면 버림 → 파일 지움 (편성은 parse_setup이 따로 고침, V26)
	TSave.enabled = true
	TSave.dir = "user://test_rules/"
	var cur := b.to_dict()
	var old := cur.duplicate(true)
	old.erase("data")
	var bad_e := cur.duplicate(true)
	bad_e.enemies[0]["id"] = "old_enemy"
	var bad_s := cur.duplicate(true)
	bad_s.witches[0].setup["equipped"] = ["crack_old"]
	var got: Array = []
	for d in [cur, old, bad_e, bad_s]:
		TSave.save_battle(d)
		got.append(str(not TSave.load_battle().is_empty()))
	TSave.clear_battle()
	_ok("V52 데이터 판: 지금 판 읽힘 · 판 없음/모르는 적/모르는 마법 버림", " ".join(got), "true false false false")
	_f3_tests()
	_f4_tests()


## 단계 F-3 (combat_proto.md §25.9): 특성 특공 · 갈라지는 빛 · 흩날리는 재 · 진 이유 글
func _f3_tests() -> void:
	print("── 단계 F-3")
	# V53 특성 특공 (review_F F02 V13): 갑주 가르기 = 갑각 적에게만 +60% · 공간 압축 = 영체 적에게만 +60% (겹을 곱하지 않는 고정값)
	var b := _b(["harpe", "eska"], ["hollow_armor", "shade_scribe"])
	var ha := _w(b, "harpe")
	var es := _w(b, "eska")
	var arm := _e(b, "hollow_armor")
	var spi := _e(b, "shade_scribe")
	_ok("V53 특성 특공: 하르페 갑주 가르기 빈 갑주(갑각·검술 약점·방어 35%) / 그림자 서기 · 에스카 공간 압축 그림자 서기(영체·공간 약점) / 빈 갑주",
		"%d %d %d %d" % [b.estimate(ha, arm, "space_cut"), b.estimate(ha, spi, "space_cut"), b.estimate(es, spi, "compress"), b.estimate(es, arm, "compress")], "93912 65016 134160 67080")
	# V54 갈라지는 빛: 방어 태세 중인 세 빛의 인형(줄 1 = 약점 번개) — 불 기본 공격은 태세 그대로 · 번개 기본 공격은 맞힌 뒤 태세가 풀림
	b = _b(["fulgur", "ignis"], ["prism_doll"])
	var doll := b.enemies[0]
	doll.add_buff({"cat": "dmg_cut", "v": 0.6, "dur": 2, "clock": "own", "name": "방어 태세"})
	b.basic_attack(_w(b, "ignis"), doll)
	var kept := doll.has_buff("dmg_cut")
	var gb := false
	for e in b.basic_attack(_w(b, "fulgur"), doll):
		gb = gb or bool(e.get("guard_break", false))
	_ok("V54 갈라지는 빛: 불 → 태세 남음 · 번개(약점) → 깨짐 사건 · 태세 없음", "%s %s %s" % [str(kept), str(gb), str(doll.has_buff("dmg_cut"))], "true true false")
	# V55 흩날리는 재: 잿빛 시종은 광역 공격에 받는 피해 +50% (단일은 그대로) — 같은 방어·약점 없는 도깨비불과 견줌
	b = _b(["fulgur"], ["ash_servant", "will_o"])
	var fu := _w(b, "fulgur")
	var sv := _e(b, "ash_servant")
	var wo := _e(b, "will_o")
	_ok("V55 흩날리는 재: 연쇄 번개(광역) 시종 ÷ 도깨비불 · 전광 스파크(단일)", "%.2f %.2f" % [float(b.estimate(fu, sv, "chain_lightning")) / float(b.estimate(fu, wo, "chain_lightning")), float(b.estimate(fu, sv, "spark_bolt")) / float(b.estimate(fu, wo, "spark_bolt"))], "1.50 1.00")
	# V56 진 이유 (review_I I-02 · I-13): 관통 필살기로 2명 → 필살기를 쓴 적 이름 · 무적을 권하지 않음 · 받는 피해 감소 0번이면 앞에
	b = _b(["eska", "nerei", "harpe"], "trial_01")
	var why := {"fin_kills": 2, "pierce_kills": 2, "guard": 0, "fin_src": "시련의 거상", "big": {"src": "다른 적", "act": "강공격", "dmg": 1}}
	var ll := TData.lose_lines(why, b, "trial_01")
	_ok("V56 진 이유: 관통 패배 두 줄", "%s | %s | %s" % [String(ll[0][0]), String(ll[1][0]), str(String(ll[1][0]).contains("무적·"))],
		"시련의 거상 필살기(관통)에 2명 쓰러짐 | 받는 피해 감소를 한 번도 안 씀 · 관통은 무적을 뚫습니다 — 받는 피해 감소·도발·근성·차지 감소로 | false")


func _names(q: Array) -> String:
	var out: Array = []
	for x in q:
		out.append((x as TUnit).name)
	return ",".join(out)


## 단계 F-4 (combat_proto.md §25.10 — review_J_skills.md P1~P5 · 총괄 결정 ①②③)
func _f4_tests() -> void:
	print("── 단계 F-4")
	# V57 P1 징표 특공 속성: 풀무질(화상 특공 25%/겹) · 화상 5겹 — 검술 하르페 1겹 값 0.25 · 불 이그니스 1.25 · 장작 얹기 받은 하르페 1.25
	var b := _b(["harpe", "ignis", "ember"], ["straw_golem"])
	var t := _dummy(b, "none")
	var hp := _w(b, "harpe")
	var ig := _w(b, "ignis")
	var em := _w(b, "ember")
	b.use_skill(em, "bellows", hp)
	b.use_skill(em, "bellows", ig)
	t.add_mark("burn", 3, 5)
	var s1 := hp.cat_sum("special", t, hp.attack_element())
	var s2 := ig.cat_sum("special", t, ig.attack_element())
	b.use_skill(em, "kindling", hp)
	_ok("V57 징표 특공은 그 속성 공격만 겹을 곱함: 하르페 · 이그니스 · 장작 얹기 하르페", "%.2f %.2f %.2f" % [s1, s2, hp.cat_sum("special", t, hp.attack_element())], "0.25 1.25 1.25")
	# V58 P2 연쇄 배율: 공격 대마법 배율 ×1.15 · ×1.3 (종막의 검 6.8 → 7.82 · 8.84) · 보조 대마법은 배율 없음
	var hu := TData.skill("ult_harpe")
	_ok("V58 연쇄 단계 배율 (종막의 검 1·2·3단계 · 불새 배율 칸)", "%.2f %.2f %.2f %s" % [float(TData.chain_scaled(hu, 1).mult), float(TData.chain_scaled(hu, 2).mult), float(TData.chain_scaled(hu, 3).mult), str(TData.chain_scaled(TData.skill("ult_ember"), 3).has("mult"))], "6.80 7.82 8.84 false")
	# V59 P3 과전류: 감전 3겹 → 받는 크리 데미지 +36% — 크리 데미지 상한(300%)과 따로 (풀구르 크리 데미지 +350% → ×4.5 → ×4.86)
	b = _b(["fulgur", "tonan"], ["straw_golem"])
	t = _dummy(b, "none")
	var fu := _w(b, "fulgur")
	t.add_mark("shock", 3, 3)
	fu.add_buff({"cat": "crit_dmg", "v": 3.5, "dur": 3, "clock": "own"})
	var m0 := float(b._terms(fu, t, 1.0, {}, false).crit_mult)
	b.use_skill(_w(b, "tonan"), "overcurrent", t)
	_ok("V59 과전류 감전 3겹: 크리 배율 상한 위로 +0.36", "%.2f %.2f" % [m0, float(b._terms(fu, t, 1.0, {}, false).crit_mult)], "4.50 4.86")
	# V60 지속 회복 (총괄 결정 ②): 샘물 붓기 → 이그니스가 행동을 마칠 때마다 최대 체력 8% (6,400) × 3번, 넷째엔 없음
	b = _b(["nerei", "ignis"], ["straw_golem"])
	ig = _w(b, "ignis")
	ig.hp = 10000
	b.use_skill(_w(b, "nerei"), "spring", ig)
	var heals: Array = []
	for k in 4:
		var hv := 0
		for e in b.end_action(ig):
			if e.t == "heal":
				hv += int(e.v)
		heals.append(str(hv))
	_ok("V60 지속 회복 8% × 행동 3번", " ".join(heals), "6400 6400 6400 0")
	# V61 대마법 위력 (총괄 결정 ③): 불쏘시개 → 운디네 심연 붕괴 ×1.3 · 빙하 붕괴(공격 마법)는 그대로
	b = _b(["undine", "ember"], ["straw_golem"])
	t = _dummy(b, "none")
	var un := _w(b, "undine")
	var u0 := b.estimate(un, t, "ult_undine")
	var g0 := b.estimate(un, t, "glacier")
	b.use_skill(_w(b, "ember"), "tinder", un)
	_ok("V61 대마법 위력 +30%: 대마법 · 공격 마법", "%.2f %.2f" % [float(b.estimate(un, t, "ult_undine")) / float(u0), float(b.estimate(un, t, "glacier")) / float(g0)], "1.30 1.00")
	# V62 체력 비례 (총괄 결정 ①): 태양의 창 — 적 체력 100% · 75% · 50% · 25% → ×1.5 · ×1.25 · ×1.0 · ×1.0
	b = _b(["ignis"], ["straw_golem"])
	t = _dummy(b, "none")
	ig = _w(b, "ignis")
	var hb: Array = []
	var base_half := 0
	for r in [1.0, 0.75, 0.5, 0.25]:
		t.hp = int(float(t.max_hp) * r)
		hb.append(b.estimate(ig, t, "sun_spear"))
		if r == 0.5:
			base_half = int(hb[-1])
	var hs: Array = []
	for v in hb:
		hs.append("%.2f" % (float(v) / float(base_half)))
	_ok("V62 태양의 창 체력 비례 (100 · 75 · 50 · 25%)", " ".join(hs), "1.50 1.25 1.00 1.00")
	# V63 낙뢰 심판: 히트 3 + 감전 겹 (3겹 → 6히트) · 대화재는 X24
	b = _b(["fulgur"], ["straw_golem"])
	t = _dummy(b, "none")
	t.add_mark("shock", 3, 3)
	_ok("V63 낙뢰 심판 감전 3겹 → 6히트", _hits(b.use_skill(_w(b, "fulgur"), "lightning_strike", t)).size(), 6)
	# V64 뇌격: 감전 보스(기절 면역)면 대신 차지 −1 · 감전 강적은 기절
	b = _b(["tonan"], ["ash_king"])
	b.fix_roll = 0.0
	var ak := b.enemies[0]
	ak.charge = 3
	ak.add_mark("shock", 3, 1)
	b.use_skill(_w(b, "tonan"), "volt", ak)
	var b2 := _b(["tonan"], ["ash_knight"])
	b2.enemies[0].add_mark("shock", 3, 1)
	b2.use_skill(_w(b2, "tonan"), "volt", b2.enemies[0])
	_ok("V64 뇌격: 보스 차지 3 → 2 · 강적 기절", "%d %s" % [ak.charge, str(b2.enemies[0].stunned)], "2 true")
	# V65 글라시아 패시브 (P4·정체성): 게이지를 깎은 적 → 받는 최종 데미지 +15% (적 행동 2번)
	b = _b(["glacia"], ["straw_golem"])
	_w(b, "glacia").passive = TData.WITCHES.glacia.passive.effects
	var gl := b.enemies[0]
	b.use_skill(_w(b, "glacia"), "rime", gl)
	_ok("V65 서리 장인: 서리 내림(게이지 −10%) → 받는 최종 데미지", "%.2f" % gl.cat_sum("final_taken", gl), "0.15")
	# V66 TAuto 큰 한 방 대상 (총괄 결정 ①): 체력 10만 짚 골렘 대신 가득 찬 짚 골렘에 태양의 창
	b = _b(["ignis"], ["straw_golem", "straw_golem"])
	b.enemies[0].hp = 100000
	b.enemies[0].name = "A"
	b.enemies[1].name = "B"
	ig = _w(b, "ignis")
	_ok("V66 큰 한 방은 넘치지 않는 적에게 (A 10만 · B 가득)", "%s %s" % [TAuto.enemy_for(b, ig).name, TAuto.big_target(b, ig, "sun_spear", TAuto.enemy_for(b, ig)).name], "A B")
	# V67 불의 고리: 맞기 전 화상이 있던 적에게만 화상 1겹 더 · V68 심해의 창: 빙결 보스만 차지 −1
	b = _b(["cinder"], ["straw_golem", "swamp_toad"])
	_e(b, "straw_golem").add_mark("burn", 3, 1)
	b.use_skill(_w(b, "cinder"), "fire_ring", null)
	_ok("V67 불의 고리: 화상 적만 겹 +1", "%d %d" % [_e(b, "straw_golem").mark_n("burn"), _e(b, "swamp_toad").mark_n("burn")], "2 0")
	var got: Array = []
	for fr in [true, false]:
		b = _b(["undine"], ["ash_king"])
		b.fix_roll = 0.0
		b.enemies[0].charge = 3
		if fr:
			b.enemies[0].add_mark("frost", 3, 1)
		b.use_skill(_w(b, "undine"), "abyss_lance", b.enemies[0])
		got.append(str(b.enemies[0].charge))
	_ok("V68 심해의 창: 빙결 재의 왕 차지 3 → 2 · 빙결 없으면 3", " ".join(got), "2 3")
