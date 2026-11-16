## 규칙 단위 테스트 (헤드리스) — prototype/tests/rules.test.js 를 옮기고, 이번에 더한 규칙(1층 완전 종료·2층·휴식·훈련)과
## 데이터 검사(글꼴에 대사 글자가 모두 있는지, 손 들기 카드 자리 = json)를 더했다.
##   cd game && godot --headless --import   (처음 한 번)
##   godot --headless --path game --script res://tests/test_rules.gd
## 마지막 줄 "rules: N passed, failures: M" — M 이 0 이어야 통과(종료 코드도 0).
extends SceneTree

var passes := 0
var fails := 0
var D: Dictionary = GameData.D


func check(name: String, ok: bool, detail := "") -> void:
	if ok:
		passes += 1
		print("  ✔ " + name)
	else:
		fails += 1
		print("  ✘ " + name + (" — " + detail if detail != "" else ""))


func ids(st: Dictionary, uids: Array) -> Array:
	return uids.map(func(u): return st.cards[u].id)


func hand_ids(st: Dictionary) -> Array:
	return ids(st, st.battle.hand)


func find_in_hand(st: Dictionary, id: String) -> String:
	for u in st.battle.hand:
		if st.cards[u].id == id:
			return u
	return ""


func give_card(st: Dictionary, id: String) -> String:
	Rules.debug_add_card(st, id)
	return find_in_hand(st, id)


func normal_battle(seed := 7, enc := "normal") -> Dictionary:
	var st := Rules.new_game(seed)
	Rules.start_battle(st, enc)
	Rules.start_turn(st)
	return st


func giant_battle(seed := 7) -> Dictionary:
	var st := Rules.new_game(seed)
	Rules.start_battle(st, "giant")
	Rules.start_turn(st)
	return st


func count_of(arr: Array) -> Dictionary:
	var c := {}
	for x in arr:
		c[x] = c.get(x, 0) + 1
	return c


func has_ev(evs: Array, t: String) -> bool:
	for e in evs:
		if e.t == t:
			return true
	return false


func _init() -> void:
	print("규칙 테스트")
	t_rng()
	t_deck()
	t_text()
	t_turn1()
	t_sword()
	t_energy()
	t_fate()
	t_fate_bad()
	t_cover()
	t_take_hit()
	t_suppress()
	t_down()
	t_wound()
	t_normal_complete()
	t_floor2_giant()
	t_floor2_all()
	t_endturn()
	t_giant_hand()
	t_locked_floor1()
	t_locked_persist()
	t_unlock_giant()
	t_run2_unlocked()
	t_immune()
	t_countdown()
	t_death()
	t_trample_cost()
	t_relic()
	t_defeat()
	t_snapshot()
	t_rest()
	t_train()
	t_cover_up()
	t_relic_clears_up()
	t_data()
	t_topdown()
	print("rules: %d passed, failures: %d" % [passes, fails])
	quit(1 if fails > 0 else 0)


# HTML 판과 같은 난수열(mulberry32) — 같은 시드면 같은 덱 순서
func t_rng() -> void:
	var st := {"rng": 7}
	var got := []
	for i in 5:
		got.append("%.10f" % Rules.rnd(st))
	check("난수열이 HTML 판(mulberry32)과 같다", ",".join(got) == "0.0117047532,0.0619582576,0.9769076328,0.6990287057,0.5214452685", ",".join(got))
	var g := Rules.new_game(7)
	Rules.start_battle(g, "normal")
	check("시드 7 의 1층 덱 순서가 HTML 판과 같다", ",".join(ids(g, g.battle.draw)) == "holy_slash,cover,fate_shift,snipe,holy_slash,shield_bash,fate_shift,curse_flame,cover,take_hit,foresight,vanguard,snipe,suppress,curse_flame", str(g.rng))


func t_deck() -> void:
	var st := Rules.new_game(1)
	var c := count_of(ids(st, st.party.deck))
	check("시작 덱 15장, 구성이 문서와 같다", st.party.deck.size() == 15 and c == {"curse_flame": 2, "fate_shift": 2, "take_hit": 1, "foresight": 1, "holy_slash": 2, "vanguard": 1, "cover": 2, "shield_bash": 1, "snipe": 2, "suppress": 1}
		and st.party.witch.hp == 15 and st.party.allies.hero.hp == 30 and st.party.allies.warrior.hp == 24 and st.party.allies.archer.hp == 12, str(c))


func t_text() -> void:
	check("카드 설명문 수치 치환", Rules.card_text("holy_slash") == "적 1명에게 14 피해" and Rules.card_text("suppress") == "적 1명에게 3 피해 + 그 적의 이번 공격 피해 -4"
		and Rules.card_text("foresight") == "카드 2장을 뽑는다" and Rules.card_text("cover") == "예고된 공격 1개를 브룬힐드가 받되 피해 절반", Rules.card_text("cover"))


func t_turn1() -> void:
	var st := normal_battle()
	var h := hand_ids(st)
	var last: String = h[h.size() - 1]
	h.remove_at(h.size() - 1)
	h.sort()
	var want: Array = D.encounters.normal.scriptedHands[1].duplicate()
	want.sort()
	var all14 := true
	for e in st.battle.enemies:
		if e.hp != 14 or e.intent.kind != "attack":
			all14 = false
	check("1층 1턴: 에너지 3, 죽음 카드(맨 오른쪽) + 4장 드로우(튜토리얼 손패), 광신도 3명 예고",
		st.battle.energy == 3 and last == "hero_death" and h == want and st.battle.enemies.size() == 3 and all14 and st.battle.enemies[0].intent.target == "warrior", str(hand_ids(st)))


func t_sword() -> void:
	var st := normal_battle()
	var uid := find_in_hand(st, "holy_slash")
	var r := Rules.play(st, uid, {"enemy": "c2"})
	check("성검 베기는 광신도를 일격에 쓰러뜨리고 에너지 1을 쓴다", r.ok and not Rules.enemy(st, "c2").alive and st.battle.energy == 2 and st.battle.discard.has(uid))


func t_energy() -> void:
	var st := normal_battle()
	st.battle.energy = 0
	var r := Rules.play(st, find_in_hand(st, "holy_slash"), {"enemy": "c1"})
	check("에너지 부족이면 낼 수 없다", not r.ok and r.reason == "에너지가 부족하다")


func t_fate() -> void:
	var st := normal_battle()
	var uid := give_card(st, "fate_shift")
	var e = Rules.enemy(st, "c3")
	var ok1: bool = e.intent.target == "archer" and Rules.redirect_choices(st, "c3").has("warrior") and not Rules.redirect_choices(st, "c3").has("archer")
	var r := Rules.play(st, uid, {"enemy": "c3", "to": "warrior"})
	var ok2: bool = r.ok and e.intent.target == "warrior"
	var before: int = st.party.allies.warrior.hp
	var ab: int = st.party.allies.archer.hp
	Rules.end_turn(st)
	check("운명 전가: 예고 대상을 다른 아군으로 바꾼다", ok1 and ok2 and st.party.allies.archer.hp == ab and st.party.allies.warrior.hp == before - 5 - 5)


func t_fate_bad() -> void:
	var st := normal_battle()
	var uid := give_card(st, "fate_shift")
	check("운명 전가 ②단계 대상이 잘못되면 실패", not Rules.play(st, uid, {"enemy": "c3", "to": "archer"}).ok)


func t_cover() -> void:
	var st := normal_battle()
	Rules.enemy(st, "c2").intent.value = 8
	var uid := give_card(st, "cover")
	var ok: bool = Rules.play(st, uid, {"enemy": "c2"}).ok
	var it = Rules.enemy(st, "c2").intent
	check("감싸기: 전사가 받되 피해 절반 (8 → 4)", ok and it.target == "warrior" and it.halve and Rules.intent_damage(it) == 4)


func t_take_hit() -> void:
	var st := normal_battle()
	var uid := find_in_hand(st, "take_hit")
	var c0 := Rules.cost(st, uid)
	var ok: bool = Rules.play(st, uid, {"enemy": "c2"}).ok
	var en: int = st.battle.energy
	Rules.end_turn(st)
	check("대신 받기: 비용 0, 마녀가 받는다", c0 == 0 and ok and en == 3 and st.party.witch.hp == 15 - 6 and st.party.allies.hero.hp == 30)


func t_suppress() -> void:
	var st := normal_battle()
	var uid := give_card(st, "suppress")
	var ok: bool = Rules.play(st, uid, {"enemy": "c2"}).ok
	check("견제 사격: 3 피해 + 그 적의 이번 공격 -4", ok and Rules.enemy(st, "c2").hp == 11 and Rules.intent_damage(Rules.enemy(st, "c2").intent) == 2)


func t_down() -> void:
	var st := normal_battle()
	Rules.debug_set_hp(st, "archer", 0)
	var uid := give_card(st, "snipe")
	var r := Rules.can_play(st, uid)
	var ev := Rules.finish_battle(st)
	var wounds: Array = st.party.deck.filter(func(u): return st.cards[u].id == "wound")
	check("쓰러진 동료의 카드는 낼 수 없고, 전투 후 HP 1 + 상처 카드", not r.ok and r.reason == "쓰러진 동료의 카드" and st.party.allies.archer.status == "ok"
		and st.party.allies.archer.hp == 1 and wounds.size() == 1 and st.cards[wounds[0]].woundOf == "archer" and st.party.deck.size() == 15 and has_ev(ev, "wound"))


func t_wound() -> void:
	var st := normal_battle()
	var uid := give_card(st, "wound")
	check("상처 카드는 낼 수 없다", not Rules.can_play(st, uid).ok)


# 1층 일반 전투는 거대 존재 없이 완전히 끝난다 [tutorial-flow 2]
func t_normal_complete() -> void:
	var st := normal_battle()
	Rules.play(st, find_in_hand(st, "holy_slash"), {"enemy": "c1"})
	Rules.debug_set_hp(st, "c2", 1)
	var r := Rules.play(st, find_in_hand(st, "curse_flame"), {"enemy": "c2"})
	var mid_ok: bool = not has_ev(r.events, "giantTrigger") and st.battle.result == null and Rules.alive_enemies(st).size() == 1
	Rules.debug_set_hp(st, "c3", 1)
	var r2 := Rules.play(st, give_card(st, "snipe"), {"enemy": "c3"})
	check("1층 전투: 1명 남아도 거대 존재가 나오지 않고, 모두 쓰러뜨리면 승리", mid_ok and st.battle.result == "win" and has_ev(r2.events, "battleEnd"))


# 2층: 광신도 2 → 1명 남으면 발이 내려와 짓밟음
func t_floor2_giant() -> void:
	var st := normal_battle(7, "floor2")
	var two: bool = st.battle.enemies.size() == 2
	var r := Rules.play(st, find_in_hand(st, "holy_slash") if find_in_hand(st, "holy_slash") != "" else give_card(st, "holy_slash"), {"enemy": "c1"})
	var trig := {}
	for e in r.events:
		if e.t == "giantTrigger":
			trig = e
	check("2층: 광신도 2명 중 1명 남으면 거대 존재가 짓밟는다", two and not trig.is_empty() and trig.victims == ["c3"] and st.battle.result == "giant" and Rules.alive_enemies(st).is_empty())


func t_floor2_all() -> void:
	var st := normal_battle(7, "floor2")
	Rules.debug_set_hp(st, "c1", 3)
	Rules.debug_set_hp(st, "c3", 3)
	var r := Rules.play(st, give_card(st, "vanguard"), {})
	check("2층: 남은 광신도가 한 번에 모두 쓰러져도 거대 존재가 등장한다", has_ev(r.events, "giantTrigger") and st.battle.result == "giant")


func t_endturn() -> void:
	var st := normal_battle()
	Rules.end_turn(st)
	var a: bool = hand_ids(st) == ["hero_death"] and st.battle.discard.size() == 4
	Rules.start_turn(st)
	Rules.end_turn(st)
	Rules.start_turn(st)
	Rules.end_turn(st)
	var ev := Rules.start_turn(st)
	check("턴 종료: 손패 버림(죽음 카드는 보존), 덱 소진 시 버림 더미를 섞는다", a and has_ev(ev, "reshuffle") and st.battle.hand.size() == 5)


func t_giant_hand() -> void:
	var st := giant_battle()
	var h := hand_ids(st)
	var ok1: bool = h.size() == 5 and h.count("hero_death") == 1 and h[4] == "hero_death"
	Rules.end_turn(st)
	var ok2: bool = hand_ids(st) == ["hero_death"]
	Rules.start_turn(st)
	check("거대 존재: 1턴에 죽음 카드 + 4장, 맨 오른쪽, 손패에 보존", ok1 and ok2 and st.battle.hand.size() == 5 and hand_ids(st).count("hero_death") == 1, str(h))


# ───────── 잠긴 죽음 카드 (대본 v0.5 1.1) ─────────
func t_locked_floor1() -> void:
	var st := normal_battle()
	var death := find_in_hand(st, "hero_death")
	var chk := Rules.can_play(st, death)
	var r := Rules.play(st, death, {})
	var still: bool = st.battle.hand.has(death) and st.party.allies.hero.status == "ok" and st.battle.energy == 3
	Rules.end_turn(st)
	var kept: bool = hand_ids(st) == ["hero_death"]
	Rules.start_turn(st)
	var t2 := hand_ids(st)
	var chk2 := Rules.can_play(st, death)
	check("1층: 죽음 카드는 잠겨 낼 수 없다(손패에 남음·에너지 그대로), 턴이 끝나도 보존, 2턴도 4장 + 잠김",
		not chk.ok and chk.get("locked", false) and not r.ok and still and kept and t2.size() == 5 and t2[4] == "hero_death"
		and not chk2.ok and chk2.get("locked", false) and Rules.is_locked(st, death), str(t2))


func t_locked_persist() -> void:
	var st := normal_battle()
	var death := find_in_hand(st, "hero_death")
	Rules.debug_win(st)
	var win: bool = st.battle.result == "win"
	Rules.finish_battle(st)
	var kept: bool = st.cards.has(death) and st.party.deathCards == [death] and st.party.deck.size() == 15 and not st.party.deck.has(death)
	Rules.start_battle(st, "floor2")
	var in_hand: bool = st.battle.hand == [death]
	Rules.start_turn(st)
	var h := hand_ids(st)
	var locked: bool = Rules.is_locked(st, death) and not Rules.can_play(st, death).ok
	check("1층 승리 후에도 죽음 카드는 덱과 따로 남고, 2층 전투도 처음부터 손패(잠김) + 4장",
		win and kept and in_hand and h.size() == 5 and h[4] == "hero_death" and locked, str(h))


func t_unlock_giant() -> void:
	var st := Rules.new_game(7)
	Rules.start_battle(st, "giant")
	var death := find_in_hand(st, "hero_death")
	var before: bool = Rules.is_locked(st, death)
	var ev := Rules.start_turn(st)
	var unlock_ev := false
	for e in ev:
		if e.t == "unlock" and e.uid == death:
			unlock_ev = true
	check("거대 존재 전투 1턴 시작에 자물쇠가 풀린다(unlock 이벤트) → 낼 수 있다",
		before and unlock_ev and not Rules.is_locked(st, death) and Rules.can_play(st, death).ok)


func t_run2_unlocked() -> void:
	var st := Rules.new_game(7)
	st.run = 2
	Rules.start_battle(st, "normal")
	Rules.start_turn(st)
	var death := find_in_hand(st, "hero_death")
	check("2회차 이후(st.run > deathLockRuns)에는 잠금이 걸리지 않는다", not Rules.is_locked(st, death) and Rules.can_play(st, death).ok)


func t_immune() -> void:
	var st := giant_battle()
	var uid := give_card(st, "holy_slash")
	var r := Rules.play(st, uid, {"enemy": "giant"})
	var imm := false
	for e in r.events:
		if e.t == "damage" and e.get("immune", false):
			imm = true
	check("거대 존재: 공격 무효(피해 0)", r.ok and imm and Rules.enemy(st, "giant").alive)


func t_countdown() -> void:
	var st := giant_battle()
	var k1: bool = Rules.enemy(st, "giant").intent.kind == "shadow"
	Rules.end_turn(st)
	var s1: bool = st.battle.shadow == 1 and st.battle.result == null
	Rules.start_turn(st)
	var k2: bool = Rules.enemy(st, "giant").intent.kind == "aoe"
	Rules.end_turn(st)
	var hp: bool = st.party.witch.hp == 10 and st.party.allies.hero.hp == 25 and st.party.allies.archer.hp == 7
	Rules.start_turn(st)
	var k3: bool = Rules.enemy(st, "giant").intent.kind == "stomp"
	var ev := Rules.end_turn(st)
	var stomp := false
	for e in ev:
		if e.t == "battleEnd" and e.reason == "stomp":
			stomp = true
	check("거대 존재: 3턴 카운트다운 — 그림자 → 기둥 붕괴(전원 5) → 짓밟기(전멸)", k1 and s1 and k2 and hp and k3 and st.battle.result == "lose" and stomp)


func t_death() -> void:
	var st := giant_battle()
	st.battle.energy = 0
	var death := find_in_hand(st, "hero_death")
	var idx: int = st.battle.hand.find(death)
	var r := Rules.play(st, death, {})
	var all_ids := ids(st, st.cards.keys())
	var tr := find_in_hand(st, "trample")
	var ok: bool = r.ok and st.party.allies.hero.status == "dead" and all_ids.count("holy_slash") + all_ids.count("vanguard") == 0 \
		and all_ids.count("broken_sword") == 2 and all_ids.count("last_charge") == 1 and tr != "" and st.battle.hand.find(tr) == idx \
		and Rules.cost(st, tr) == 0 and st.party.deck.has(tr) and st.party.deck.size() == 16
	var r2 := Rules.play(st, tr, {})
	check("죽음 카드: 비용 0 → 용사 사망, 유품 3장, 짓밟힘(이번 턴 0) → 존재가 물러남", ok and r2.ok and has_ev(r2.events, "retreat") and st.battle.result == "retreat")


func t_trample_cost() -> void:
	var st := giant_battle()
	Rules.play(st, find_in_hand(st, "hero_death"), {})
	var tr := find_in_hand(st, "trample")
	Rules.end_turn(st)
	Rules.start_turn(st)
	check("짓밟힘: 획득한 다음 턴부터는 비용 2", Rules.cost(st, tr) == 2)


func t_relic() -> void:
	var st := Rules.new_game(3)
	Rules.start_battle(st, "normal")
	Rules.start_turn(st)
	st.party.allies.hero.status = "dead"
	var uid := give_card(st, "broken_sword")
	var r := Rules.play(st, uid, {"enemy": "c1"})
	check("유품 카드: 원래보다 강하고 마녀 HP를 잃는다", r.ok and not Rules.enemy(st, "c1").alive and st.party.witch.hp == 12)


func t_defeat() -> void:
	var st := normal_battle()
	Rules.debug_set_hp(st, "witch", 0)
	var st2 := normal_battle()
	for a in ["hero", "warrior", "archer"]:
		Rules.debug_set_hp(st2, a, 0)
	check("패배 조건: 마녀 HP 0 또는 동료 전원 쓰러짐", Rules.is_defeat(st) and Rules.is_defeat(st2))


func t_snapshot() -> void:
	var st := Rules.new_game(11)
	Rules.start_battle(st, "giant")
	var snap := Rules.snapshot(st)
	Rules.start_turn(st)
	Rules.end_turn(st)
	Rules.start_turn(st)
	Rules.end_turn(st)
	var st2 := Rules.restore(snap, st.rng)
	var a: bool = st2.party.witch.hp == 15 and st2.battle.turn == 0
	Rules.start_turn(st2)
	check("스냅샷 복원: 거대 존재 등장 직후 상태로 돌아간다", a and hand_ids(st2).has("hero_death"))


# 휴식: 동료 최대 HP +3, 마녀 +2, 모두 회복 [tutorial-flow 2.2]
func t_rest() -> void:
	var st := normal_battle()
	Rules.debug_set_hp(st, "archer", 4)
	Rules.debug_set_hp(st, "witch", 9)
	Rules.finish_battle(st)
	Rules.apply_rest(st)
	var p: Dictionary = st.party
	check("휴식: 최대 HP 동료 +3·마녀 +2, 전원 회복", p.witch.maxHp == 17 and p.witch.hp == 17 and p.allies.archer.maxHp == 15 and p.allies.archer.hp == 15
		and p.allies.hero.maxHp == 33 and p.allies.hero.hp == 33 and p.allies.warrior.hp == 27, JSON.stringify(p.allies))


# 훈련: 후보 3장(서로 다름) 중 1장 강화 → 그 카드 1장만 강화, 이름 옆 +, 강화 수치로 동작
func t_train() -> void:
	var st := Rules.new_game(7)
	var c := Rules.train_candidates(st)
	var uniq := count_of(c).size() == c.size()
	var in_table := c.all(func(x): return D.upgrades.has(x))
	var u := Rules.upgrade_card(st, "holy_slash")
	var ups: Array = st.party.deck.filter(func(x): return st.cards[x].get("up", false))
	Rules.start_battle(st, "normal")
	Rules.start_turn(st)
	# 강화된 성검 베기를 손에 넣고 써 본다
	var b: Dictionary = st.battle
	for zone in ["draw", "discard"]:
		if b[zone].has(u):
			b[zone].erase(u)
			b.hand.append(u)
	if not b.hand.has(u):
		b.hand.append(u)
	Rules.debug_set_hp(st, "c1", 18)
	var r := Rules.play(st, u, {"enemy": "c1"})
	check("훈련: 후보 3장(서로 다름) → 1장만 강화(+), 피해 14 → 18", c.size() == 3 and uniq and in_table and u != "" and ups.size() == 1
		and Rules.card_name("holy_slash", true) == "성검 베기+" and Rules.card_text("holy_slash", true) == "적 1명에게 18 피해" and r.ok and not Rules.enemy(st, "c1").alive and st.flags.upgraded == "holy_slash", str(c))


func t_cover_up() -> void:
	var st := normal_battle()
	var u := give_card(st, "cover")
	st.cards[u].up = true
	Rules.enemy(st, "c2").intent.value = 9
	var ok: bool = Rules.play(st, u, {"enemy": "c2"}).ok
	check("강화한 감싸기: 받는 피해 1/3 (9 → 3)", ok and Rules.intent_damage(Rules.enemy(st, "c2").intent) == 3 and Rules.card_text("cover", true).ends_with("피해 1/3"))


func t_relic_clears_up() -> void:
	var st := Rules.new_game(7)
	var u := Rules.upgrade_card(st, "holy_slash")
	Rules.start_battle(st, "giant")
	Rules.start_turn(st)
	Rules.play(st, find_in_hand(st, "hero_death"), {})
	check("용사 사망 시 강화한 성검 베기도 유품(부러진 성검)이 되고 + 는 사라진다", st.cards[u].id == "broken_sword" and not st.cards[u].has("up"))


# 데이터 검사: 대본·카드 글자가 모두 글꼴에 있는지(없으면 네모로 보임), 손 들기 카드 자리 = json
func t_data() -> void:
	var texts := []
	_collect(ScriptData.S, texts)
	for id in D.cards:
		texts.append(D.cards[id].name)
		texts.append(D.cards[id].text)
		for t in D.cards[id].get("tags", []):
			texts.append(t)
	for id in D.upgrades:
		texts.append(D.upgrades[id].summary)
	var fonts := {"sans": load("res://assets/fonts/NotoSansKR-KS.ttf"), "serif": load("res://assets/fonts/NotoSerifKR-KS-Regular.ttf"), "serif_bold": load("res://assets/fonts/NotoSerifKR-KS-Bold.ttf")}
	var missing := {}
	for s in texts:
		var str_s: String = s
		for i in str_s.length():
			var ch := str_s.unicode_at(i)
			if ch < 32:
				continue
			for k in fonts:
				if not fonts[k].has_char(ch):
					missing[char(ch)] = k
	check("대본·카드의 모든 글자가 글꼴(한글 2,350자 묶음)에 있다", missing.is_empty(), str(missing.keys()))
	var f := FileAccess.open("res://assets/ui_witch_hand_raise.json", FileAccess.READ)
	var j = JSON.parse_string(f.get_as_text()) if f else null
	var q: Array = D.layout.raise.quad
	var same := j != null
	if same:
		for i in 4:
			for k in 2:
				if int(j.card_quad_tl_tr_br_bl[i][k]) != int(q[i][k]):
					same = false
	check("손 들기 카드 자리 = ui_witch_hand_raise.json", same)
	var no_extra := true
	for w in ["사제", "도적"]:
		for s in texts:
			if s.contains(w):
				no_extra = false
	check("대본에 사제·도적이 나오지 않는다", no_extra)


# 탑뷰 시험판: 걸을 수 있는 곳·막힌 곳·경로 (game_data.gd "topdown")
func t_topdown() -> void:
	var C: Dictionary = D.topdown
	var img := Image.load_from_file("res://assets/" + str(C.map))
	var msz := Vector2i(844, 664) if img == null else img.get_size()
	var nav := TopdownNav.new(C, msz)
	var entry := Vector2(C.entry[0], C.entry[1])
	check("탑뷰: 입구 자리에 설 수 있다", nav.can_stand(entry))
	var bad := []
	for p in [[424, 620], [424, 600], [10, 300], [50, 455], [120, 420], [128, 467], [300, 386], [780, 360], [424, 60], [600, 100], [835, 300]]:
		if nav.can_stand(Vector2(p[0], p[1])):
			bad.append(p)
	check("탑뷰: 벽·아래 입구 밖·기둥·돌무더기·물건 자리에는 설 수 없다", bad.is_empty(), str(bad))
	var miss := []
	for it in C.items:
		var sp := Vector2(it.spot[0], it.spot[1])
		var path := nav.find_path(entry, sp)
		if not nav.can_stand(sp) or path.is_empty() or path[path.size() - 1].distance_to(sp) > 0.5:
			miss.append(it.id)
	for e in C.exits:
		var at := Vector2(e.at[0], e.at[1])
		var path2 := nav.find_path(entry, at)
		if not nav.can_stand(at) or path2.is_empty() or path2[path2.size() - 1].distance_to(at) > float(e.r):
			miss.append(e.id)
	check("탑뷰: 입구에서 물건 4개·출구 3개까지 걸어갈 수 있다", miss.is_empty() and C.items.size() == 4 and C.exits.size() == 3, str(miss))
	# 경로의 모든 구간이 벽을 뚫지 않는다
	var through := false
	var cur := entry
	for q in nav.find_path(entry, Vector2(170, 420)):
		if not nav.line_ok(cur, q):
			through = true
		cur = q
	check("탑뷰: 탭 이동 경로가 장애물을 뚫지 않는다", not through)
	# 벽 쪽으로 계속 걸어도 바닥 안에 머문다
	var p2 := entry
	for i in 400:
		p2 = nav.move(p2, Vector2(0, 2))
	var p3 := entry
	for i in 400:
		p3 = nav.move(p3, Vector2(-2, -1))
	check("탑뷰: 벽으로 밀어도 바닥 밖으로 나가지 않는다", nav.can_stand(p2) and p2.y <= 581 and nav.can_stand(p3), "%s %s" % [p2, p3])
	for id in ["shield", "journal", "spade", "thread"]:
		check("탑뷰 대사: " + id, ScriptData.S.topdown.items.has(id) and ScriptData.S.topdown.items[id].size() > 0)
	# 동료 셋: 순서·시트(3열×4행, 72px 칸)·간격
	var ids := []
	var sheets_ok := true
	for f in C.followers:
		ids.append(f.id)
		var im := Image.load_from_file("res://assets/" + str(f.sheet))
		if im == null or im.get_size() != Vector2i(216, 288):
			sheets_ok = false
	check("탑뷰 동료: 세라피나 → 브룬힐드 → 엘리안, 시트 216×288", ids == ["seraphina", "brunhild", "elian"] and sheets_ok, str(ids))
	check("탑뷰 동료 간격 16~40 맵px, 속도 120", float(C.followGap) >= 16.0 and float(C.followGap) <= 40.0 and float(C.speed) == 120.0)
	var gap := float(C.followGap)
	var rest := []
	for i in 3:
		rest.append(entry + Vector2(0, gap * (i + 1)))
	var stand_bad := rest.filter(func(q): return q.y > 570.0)
	check("탑뷰: 입구에 섰을 때 동료 셋이 아치 위(방 안)에 선다", stand_bad.is_empty(), str(rest))
	# 경로 따라 걷기: 꺾어 걸어도 경로 길이로 간격, 멈추면 그대로
	var tr := TopdownNav.Trail.new()
	tr.keep = gap * 4 + 24
	var head := Vector2(100, 300)
	tr.line_up(head, Vector2.DOWN)
	var ok_line := tr.at(head, gap).distance_to(Vector2(100, 300 + gap)) < 0.01 and tr.at(head, gap * 3).distance_to(Vector2(100, 300 + gap * 3)) < 0.01
	for i in 30:
		head += Vector2(2, 0)
		tr.push(head)
	var a1 := tr.at(head, gap)
	var a3 := tr.at(head, 72.0)
	check("탑뷰 경로: 일직선 줄 → 오른쪽으로 꺾은 뒤 앞사람은 가로줄, 뒷사람은 모퉁이 뒤", ok_line and a1.distance_to(head - Vector2(gap, 0)) < 0.01 and a3.distance_to(Vector2(100, 312)) < 0.01, "%s %s" % [a1, a3])
	for i in 20:
		tr.push(head)
	check("탑뷰 경로: 노엘이 멈추면 동료도 간격을 둔 채 멈춘다", tr.at(head, gap).distance_to(a1) < 0.01 and tr.at(head, gap * 2).distance_to(tr.at(head, gap)) > gap - 0.5)
	# 방향 행·조이스틱
	check("탑뷰 방향: 가장 가까운 4방향, 대각선 근처는 지금 방향 유지",
		TopdownNav.face_dir("up", Vector2(1, 0)) == "right" and TopdownNav.face_dir("up", Vector2(-1, -1)) == "up"
		and TopdownNav.face_dir("down", Vector2(-1, -1)) == "left" and TopdownNav.face_dir("left", Vector2(-0.2, 1)) == "down"
		and TopdownNav.face_dir("right", Vector2.ZERO) == "right")
	var sc: Dictionary = C.stick
	var v0 := TopdownNav.stick_to_vec(Vector2(0.1, 0), sc.dead, sc.min)
	var v1 := TopdownNav.stick_to_vec(Vector2(0.3, 0), sc.dead, sc.min)
	var v2 := TopdownNav.stick_to_vec(Vector2(0, -2.0), sc.dead, sc.min)
	check("탑뷰 조이스틱: 가운데는 0, 조금 기울이면 느리게, 끝까지 기울이면 최대", v0 == Vector2.ZERO and v1.length() > 0.0 and v1.length() < 0.6 and v1.x > 0 and absf(v2.length() - 1.0) < 0.001 and v2.y < 0, "%s %s %s" % [v0, v1, v2])


func _collect(v, out: Array) -> void:
	if v is String:
		out.append(v)
	elif v is Dictionary:
		for k in v:
			_collect(v[k], out)
	elif v is Array:
		for x in v:
			_collect(x, out)
