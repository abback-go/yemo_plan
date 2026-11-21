## 규칙 단위 테스트 (헤드리스) — prototype/tests/rules.test.js 를 옮기고, 이번에 더한 규칙(1층 완전 종료·2층·휴식·훈련)과
## 데이터 검사(글꼴에 대사 글자가 모두 있는지, 손 들기 카드 자리 = json)를 더했다.
## 버티컬 슬라이스(2026-11-21): 뒤집힌 죽음 카드·운명(받아들인다/거스른다)·지도·촛불·어둠·방 보상 시험을 더했다.
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
	t_face_down_floor1()
	t_face_down_persist()
	t_giant_stomp_fate()
	t_death_unplayable()
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
	t_fate_v2()
	t_map()
	t_candles()
	t_darkness()
	t_lantern_carry()
	t_rewards()
	t_trade_event()
	t_nameless()
	t_charm()
	t_retry_hp()
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
	var st := normal_battle(7, "deep")
	var two: bool = st.battle.enemies.size() == 2
	var r := Rules.play(st, find_in_hand(st, "holy_slash") if find_in_hand(st, "holy_slash") != "" else give_card(st, "holy_slash"), {"enemy": "c1"})
	var trig := {}
	for e in r.events:
		if e.t == "giantTrigger":
			trig = e
	check("2층: 광신도 2명 중 1명 남으면 거대 존재가 짓밟는다", two and not trig.is_empty() and trig.victims == ["c3"] and st.battle.result == "giant" and Rules.alive_enemies(st).is_empty())


func t_floor2_all() -> void:
	var st := normal_battle(7, "deep")
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


# ───────── 뒤집힌 죽음 카드 (대본 v3 1장, 2026-11-21 죽음 카드 컨셉 변경) ─────────
func t_face_down_floor1() -> void:
	var st := normal_battle()
	var death := find_in_hand(st, "hero_death")
	var chk := Rules.can_play(st, death)
	var r := Rules.play(st, death, {})
	var still: bool = st.battle.hand.has(death) and st.party.allies.hero.status == "ok" and st.battle.energy == 3
	Rules.end_turn(st)
	var kept: bool = hand_ids(st) == ["hero_death"]
	Rules.start_turn(st)
	var t2 := hand_ids(st)
	check("1층: 세라피나의 죽음 카드는 뒤집힌 채 손패 맨 오른쪽(낼 수 없음·에너지 그대로), 턴이 끝나도 보존, 2턴도 4장 + 뒤집힘",
		Rules.is_face_down(st, death) and not chk.ok and chk.reason == "낼 수 없는 카드" and not r.ok and still and kept and t2.size() == 5 and t2[4] == "hero_death"
		and Rules.is_face_down(st, death), str(t2))

func t_face_down_persist() -> void:
	var st := normal_battle()
	var death := find_in_hand(st, "hero_death")
	Rules.debug_win(st)
	var win: bool = st.battle.result == "win"
	Rules.finish_battle(st)
	var kept: bool = st.cards.has(death) and st.party.deathCards == [death] and st.party.deck.size() == 15 and not st.party.deck.has(death)
	Rules.start_battle(st, "deep")
	var in_hand: bool = st.battle.hand == [death]
	Rules.start_turn(st)
	var h := hand_ids(st)
	check("1층 승리 후에도 죽음 카드는 덱과 따로 남고, 깊은 곳 전투도 처음부터 손패(뒤집힘) + 4장",
		win and kept and in_hand and h.size() == 5 and h[4] == "hero_death" and Rules.is_face_down(st, death) and not Rules.can_play(st, death).ok, str(h))

## 거대한 발 3턴 「짓밟기」 = 세라피나의 운명(거스를 수 없음): 운명의 시도 → 뒤집힘 → 받아들임(사망·유품·짓밟힘) → 전투가 끝남(물러남)
func t_giant_stomp_fate() -> void:
	var st := giant_battle()
	var death := find_in_hand(st, "hero_death")
	Rules.end_turn(st)
	Rules.start_turn(st)
	Rules.end_turn(st)
	Rules.start_turn(st)
	var it = Rules.enemy(st, "giant").intent
	var ok_it: bool = it.kind == "stomp" and str(it.get("fate", "")) == "hero_stomp" and it.target == "all" and not Rules.hideable(it)
	var ev := Rules.end_turn(st)
	var trial: bool = has_ev(ev, "fateTrial") and st.battle.awaitFate != null and st.battle.awaitFate.who == "hero" and st.battle.result == null
	var others_ok: bool = st.party.allies.warrior.hp > 0 and st.party.allies.archer.hp > 0 and st.party.witch.hp > 0
	var no_defy: bool = Rules.defy_fate(st, "hero_stomp").is_empty() and not Rules.can_defy("hero_stomp")
	var fl := Rules.flip_card(st, death)
	var flipped: bool = has_ev(fl, "flip") and not Rules.is_face_down(st, death)
	var ev2 := Rules.fate_trial_choice(st, "defy")   # 튜토리얼은 거스를 수 없다 → 늘 받아들인다
	var all_ids := ids(st, st.cards.keys())
	var tr := find_in_hand(st, "trample")
	var dead: bool = st.party.allies.hero.status == "dead" and has_ev(ev2, "allyDeath") and all_ids.count("holy_slash") + all_ids.count("vanguard") == 0 \
		and all_ids.count("broken_sword") == 2 and all_ids.count("last_charge") == 1 and tr != "" and st.party.deck.has(tr) and st.party.deathCards.is_empty() \
		and Rules.fate_by_id(st, "hero_stomp").result == "offered" and Rules.scar_count(st) == 0
	var ev3 := Rules.fate_end_battle(st, "hero_stomp")
	check("거대한 발 3턴 「짓밟기」: 운명의 시도(세라피나, 다른 동료는 멀쩡) → 카드가 뒤집힘 → 거스를 수 없어 받아들임 → 사망·유품 3장·「짓밟힘」 → 물러남",
		ok_it and trial and others_ok and no_defy and flipped and dead and has_ev(ev3, "retreat") and st.battle.result == "retreat", str(it))

## 죽음 카드는 어느 층에서도 낼 수 없다 (미리 보여 주는 카드 — 카드를 내서 죽이는 방식은 없앴다)
func t_death_unplayable() -> void:
	var st := Rules.state_floor3(7, "alive")
	Rules.start_battle(st, "pyre")
	Rules.start_turn(st)
	var bad := []
	for u in st.battle.hand:
		if Rules.def(st, u).kind == "death" and (Rules.can_play(st, u).ok or Rules.play(st, u, {}).ok):
			bad.append(st.cards[u].id)
	check("죽음 카드(2·3층 포함)는 낼 수 없다 — 손패 한 칸만 차지", bad.is_empty() and hand_ids(st).count("warrior_death") == 1 and hand_ids(st).count("archer_death") == 1, str(bad))

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
	# 세라피나의 운명이 이미 끝났다면(바로 가기 등) 짓밟기는 예전처럼 모두를 덮친다
	var st2 := st.duplicate(true)
	Rules.fate_by_id(st2, "hero_stomp").alive = false
	Rules.enemy(st2, "giant").intent.erase("fate")
	var ev := Rules.end_turn(st2)
	var stomp := false
	for e in ev:
		if e.t == "battleEnd" and e.reason == "stomp":
			stomp = true
	check("거대한 발: 3턴 카운트다운 — 그림자 → 기둥 붕괴(전원 5) → 짓밟기 (운명이 없으면 전멸)", k1 and s1 and k2 and hp and k3 and st2.battle.result == "lose" and stomp)

func t_death() -> void:
	var st := giant_battle()
	var death := find_in_hand(st, "hero_death")
	var idx: int = st.battle.hand.find(death)
	var ev := Rules.offer_fate(st, "hero_stomp")
	var tr := find_in_hand(st, "trample")
	check("운명을 받아들임(전투 중): 세라피나 사망 → 죽음 카드 자리에 「짓밟힘」(비용 2), 덱에도 1장",
		has_ev(ev, "allyDeath") and st.party.allies.hero.status == "dead" and tr != "" and st.battle.hand.find(tr) == idx and Rules.cost(st, tr) == 2
		and st.party.deck.has(tr) and st.party.deck.size() == 16 and not st.battle.hand.has(death))

func t_trample_cost() -> void:
	var st := giant_battle()
	Rules.offer_fate(st, "hero_stomp")
	var tr := find_in_hand(st, "trample")
	var c0 := Rules.cost(st, tr)
	Rules.end_turn(st)
	Rules.start_turn(st)
	check("짓밟힘: 비용 2 (얻은 턴에도 공짜가 아니다 — 튜토리얼에서 내는 장면이 없어졌다)", c0 == 2 and Rules.cost(st, tr) == 2 and Rules.card_text("trample") == "모든 적에게 15 피해")

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
	check("훈련: 후보 3장(서로 다름) → 1장만 강화(Lv2), 피해 14 → 18", c.size() == 3 and uniq and in_table and u != "" and ups.size() == 1
		and Rules.card_name("holy_slash", true) == "성검 베기 Lv2" and Rules.card_text("holy_slash", true) == "적 1명에게 18 피해" and r.ok and not Rules.enemy(st, "c1").alive and st.flags.upgraded == "holy_slash", str(c))


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
	Rules.offer_fate(st, "hero_stomp")
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
			# 적 「화형 사제」(3층)는 파티의 사제가 아니다
			if s.replace("화형 사제", "").replace("불을 든 사제", "").contains(w):
				no_extra = false
	check("대본에 사제·도적이 나오지 않는다", no_extra)


# ───────── 1차 시험판 v2: 운명 (prototype-v2-spec.md 0장·4장) ─────────
func _deck_ids(st: Dictionary) -> Array:
	return st.party.deck.map(func(u): return st.cards[u].id)


func _deck_lv(st: Dictionary, id: String) -> int:
	for u in st.party.deck:
		if st.cards[u].id == id:
			return Rules.level(st, u)
	return 0


func t_fate_v2() -> void:
	# 튜토리얼 끝: 세라피나 사망, 브룬힐드 관통 Lv1 (2층)
	var st := Rules.state_after_tutorial(7)
	var f = Rules.fate_of(st, "warrior")
	check("v2 튜토리얼 끝: 브룬힐드 운명 Lv1·2층, 죽음 카드 1장, 세라피나 사망(운명 받아들임)·짓밟힘",
		f != null and f.level == 1 and f.floor == 2 and Rules.floor_now(st) == 2 and st.party.deathCards.size() == 1
		and st.cards[st.party.deathCards[0]].id == "warrior_death" and st.party.allies.hero.status == "dead" and _deck_ids(st).has("trample")
		and not _deck_ids(st).has("holy_slash") and _deck_ids(st).has("broken_sword") and Rules.fate_by_id(st, "hero_stomp").result == "offered")
	check("v2 카드 레벨 표기: 죽음 카드 Lv1, 훈련 강화는 Lv2 (+ 아님)",
		Rules.card_name("warrior_death", false, 1) == "전사의 죽음 Lv1" and Rules.card_name("holy_slash", true) == "성검 베기 Lv2"
		and Rules.card_name("snipe") == "저격" and Rules.card_text("warrior_death", false, Callable(), 1) == "브룬힐드는 2층에서 관통당해 죽는다.")
	# ① 바친다 (탐사 중): 죽음 → 유품 → 상속 카드(같은 Lv)
	var a := st.duplicate(true)
	var ev := Rules.offer_fate(a, "warrior_pierce")
	var fa = Rules.fate_by_id(a, "warrior_pierce")
	check("v2 받아들임(전투 밖): 브룬힐드 사망, 감싸기·방패 강타 → 유품, 「꿰뚫린 방패」 Lv1 덱에, 운명 끝(offered)",
		a.party.allies.warrior.status == "dead" and not _deck_ids(a).has("cover") and _deck_ids(a).has("warrior_shard") and _deck_ids(a).has("warrior_last_bash")
		and _deck_lv(a, "pierced_shield") == 1 and a.party.deathCards.is_empty() and not fa.alive and fa.result == "offered" and has_ev(ev, "allyDeath") and has_ev(ev, "gainCard")
		and Rules.scar_count(a) == 0)
	# ② 거스른다: 살고, 흉터 1장이 그 순간 덱에
	var b := st.duplicate(true)
	var ev2 := Rules.defy_fate(b, "warrior_pierce")
	var fb = Rules.fate_by_id(b, "warrior_pierce")
	check("v2 거스름: 브룬힐드 생존, 흉터 1장(그 순간 덱에), 운명은 살아 있음(이 층 시도 끝)",
		b.party.allies.warrior.status == "ok" and Rules.scar_count(b) == 1 and fb.alive and int(fb.triedFloor) == 2 and has_ev(ev2, "fateDefied")
		and b.party.deathCards.size() == 1)
	# ③ 살아서 내려가면 Lv2 · 문구 교체 · 3층
	var add := Rules.add_fate(b, "archer_burn", 3)
	var ev3 := Rules.descend(b)
	var wc: String = fb.card
	check("v2 층 내려감: 브룬힐드 운명 Lv2·3층, 카드 Lv2·문구 교체 / 새 운명 엘리안 화형 Lv1 그대로",
		fb.level == 2 and fb.floor == 3 and Rules.level(b, wc) == 2 and Rules.def(b, wc).text == "브룬힐드는 3층에서 꼬챙이에 꿰여 매달려 죽는다."
		and Rules.fate_of(b, "archer").level == 1 and Rules.fate_of(b, "archer").floor == 3 and add != "" and has_ev(ev3, "fateLevelUp") and Rules.floor_now(b) == 3
		and b.party.deathCards.size() == 2)
	# 흉터 장수: 1단계 1 / 2단계 1 / 3단계 2
	var c3 := b.duplicate(true)
	Rules.defy_fate(c3, "warrior_pierce")
	var n2 := Rules.scar_count(c3)
	Rules.descend(c3)
	Rules.defy_fate(c3, "warrior_pierce")
	check("v2 흉터 장수: 1단계 1 · 2단계 1 · 3단계 2", n2 == 2 and Rules.scar_count(c3) == 4, "%d %d" % [n2, Rules.scar_count(c3)])
	# ④ 브룬힐드가 살아 있으면 두 죽음 카드가 모두 손에 (드로우 5 − 2)
	var s3 := Rules.state_floor3(7, "alive")
	Rules.start_battle(s3, "pyre")
	Rules.start_turn(s3)
	var hd := hand_ids(s3)
	check("v2 3층(브룬힐드 생존): 첫 턴 손패에 두 죽음 카드 + 새로 3장, 비용 0",
		hd.has("warrior_death") and hd.has("archer_death") and hd.size() == 5 and Rules.cost(s3, find_in_hand(s3, "archer_death")) == 0, str(hd))
	var s3d := Rules.state_floor3(7, "dead")
	Rules.start_battle(s3d, "pyre")
	Rules.start_turn(s3d)
	var hd2 := hand_ids(s3d)
	check("v2 3층(브룬힐드 사망): 엘리안 죽음 카드 1장 + 새로 4장, 「꿰뚫린 방패」 Lv1 덱에",
		hd2.has("archer_death") and not hd2.has("warrior_death") and hd2.size() == 5 and _deck_lv(s3d, "pierced_shield") == 1, str(hd2))
	# ⑤ 전투 중 운명의 시도: 2턴 화형 사제 「운명의 불길 → 엘리안」(옮기기 불가) → 멈춤 → 거스름
	var p := s3.duplicate(true)
	Rules.end_turn(p)
	Rules.start_turn(p)
	var pi = Rules.enemy(p, "p1").intent
	var ok_int: bool = pi.kind == "fate" and pi.target == "archer" and not pi.redirectable and pi.lethal
	var vt := Rules.valid_targets(p, give_card(p, "fate_shift"))
	var evt := Rules.end_turn(p)
	check("v2 운명의 불길: 2턴 예고(엘리안, 치명, 옮기기 불가) → 적 차례에 멈춤(awaitFate)",
		ok_int and not vt.has("p1") and has_ev(evt, "fateTrial") and p.battle.awaitFate != null, str(pi))
	var hp_a: int = p.party.allies.archer.hp
	var evd := Rules.fate_trial_choice(p, "defy")
	var evr := Rules.resume_enemy_phase(p)
	check("v2 운명의 불길 거스름: 엘리안 생존(피해 0) · 흉터 +1 · 남은 적 행동 이어짐",
		p.party.allies.archer.status != "dead" and p.party.allies.archer.hp == hp_a and Rules.scar_count(p) == Rules.scar_count(s3) + 1
		and has_ev(evd, "fateDefied") and p.battle.awaitFate == null and Rules.fate_of(p, "archer").triedFloor == 3)
	# 바침: 상속 「타버린 활」 Lv1 → 덱 영구 + 손패에 바로
	var q := s3.duplicate(true)
	Rules.end_turn(q)
	Rules.start_turn(q)
	Rules.end_turn(q)
	var evo := Rules.fate_trial_choice(q, "accept")
	check("v2 운명의 불길 받아들임: 엘리안 사망 · 「타버린 활」 Lv1 덱 + 손패 · 저격 → 유품",
		q.party.allies.archer.status == "dead" and hand_ids(q).has("burnt_bow") and _deck_lv(q, "burnt_bow") == 1 and _deck_ids(q).has("archer_arrow")
		and has_ev(evo, "allyDeath") and not hand_ids(q).has("archer_death"))
	# 죽음 카드는 낼 수 없다. 브룬힐드 Lv2 운명을 받아들이면 → 「꿰뚫린 방패」 Lv2 (예고 모두 막기)
	var r := s3.duplicate(true)
	var wu := find_in_hand(r, "warrior_death")
	var rr := Rules.play(r, wu, {})
	Rules.offer_fate(r, "warrior_pierce")
	var ps := find_in_hand(r, "pierced_shield")
	check("v2 죽음 카드 Lv2: 낼 수 없음 → 운명을 받아들이면 브룬힐드 사망 · 「꿰뚫린 방패」 Lv2 손패(대상 없음)",
		not rr.ok and r.party.allies.warrior.status == "dead" and ps != "" and Rules.level(r, ps) == 2 and Rules.def(r, ps).target == "none"
		and Rules.fate_by_id(r, "warrior_pierce").result == "offered")
	var e_before := {}
	for e in Rules.alive_enemies(r):
		e_before[e.id] = e.hp
	var rp := Rules.play(r, ps, {})
	var all_blocked := true
	for e in Rules.alive_enemies(r):
		if not e.intent.get("blocked", false):
			all_blocked = false
	check("v2 「꿰뚫린 방패」 Lv2: 예고된 공격 모두 막고 각 피해만큼 되돌림", rp.ok and all_blocked and Rules.enemy(r, "c1").hp < int(e_before.c1), str(e_before))
	# Lv1: 공격 1개만
	var r1 := s3d.duplicate(true)
	r1.party.witch.hp = 99
	r1.party.allies.archer.hp = 99
	Rules.end_turn(r1)
	Rules.start_turn(r1)
	Rules.end_turn(r1)
	Rules.fate_trial_choice(r1, "defy")
	Rules.resume_enemy_phase(r1)
	Rules.start_turn(r1)
	var sh2 := give_card(r1, "pierced_shield")
	var c1hp: int = Rules.enemy(r1, "c1").hp
	var dmg: int = Rules.intent_damage(Rules.enemy(r1, "c1").intent)
	var rp1 := Rules.play(r1, sh2, {"enemy": "c1"})
	check("v2 「꿰뚫린 방패」 Lv1: 공격 1개 막음(피해 0) + 그만큼 되돌림",
		rp1.ok and Rules.intent_damage(Rules.enemy(r1, "c1").intent) == 0 and Rules.enemy(r1, "c1").hp == maxi(0, c1hp - dmg) and dmg > 0, "%d %d" % [c1hp, dmg])
	# 흉터: 손에 든 채 턴이 끝나면 노엘 HP -1, 낼 수 없음
	var sc := Rules.state_after_tutorial(3)
	Rules.defy_fate(sc, "warrior_pierce")
	Rules.start_battle(sc, "ossuary")
	Rules.start_turn(sc)
	var su := give_card(sc, "scar")
	var whp: int = sc.party.witch.hp
	var cp := Rules.can_play(sc, su)
	var evs := Rules.end_turn(sc)
	var scar_hits := 0
	for e in evs:
		if e.t == "damage" and e.get("cause", "") == "scar":
			scar_hits += 1
	check("v2 흉터: 낼 수 없음 · 손에 든 채 턴 끝 → 노엘 HP -1", not cp.ok and scar_hits >= 1 and has_ev(evs, "scarBurn"))
	# 운명의 시도는 전투 안에서만 (2026-11-18): 2층 납골당 2턴 창 기사 「운명의 관통 → 브룬힐드」
	var o := Rules.state_after_tutorial(7)
	Rules.start_battle(o, "ossuary")
	Rules.start_turn(o)
	var o1 = Rules.enemy(o, "k1").intent
	Rules.end_turn(o)
	Rules.start_turn(o)
	var o2 = Rules.enemy(o, "k1").intent
	check("v2 2층 납골당: 1턴은 보통 예고, 2턴 창 기사 「운명의 관통 → 브룬힐드」(치명·옮기기 불가)",
		o1.kind != "fate" and o2.kind == "fate" and o2.target == "warrior" and o2.label == "운명의 관통" and not o2.redirectable, str(o2))
	# 집행자를 먼저 쓰러뜨리면 쓰러지는 그 순간 운명의 시도가 온다 — 다른 적이 다 쓰러져도 승리는 그 뒤
	var g := Rules.state_after_tutorial(7)
	Rules.start_battle(g, "ossuary")
	Rules.start_turn(g)
	Rules.enemy(g, "c1").alive = false
	Rules.enemy(g, "k1").hp = 5
	var rg := Rules.play(g, give_card(g, "broken_sword"), {"enemy": "k1"})
	var trial_now: bool = has_ev(rg.events, "fateTrial") and g.battle.awaitFate != null and g.battle.awaitFate.get("byDeath", false) and g.battle.result == null
	Rules.fate_trial_choice(g, "defy")
	var rres := Rules.resume_enemy_phase(g)
	check("v2 집행자(창 기사)를 먼저 쓰러뜨림: 그 순간 운명의 시도(거스름 → 흉터), 승리는 시도 뒤",
		trial_now and Rules.scar_count(g) == 1 and g.battle.result == "win" and has_ev(rres, "battleEnd") and Rules.fate_of(g, "warrior").triedFloor == 2)
	# 3층(브룬힐드 생존): 화형 사제가 2턴 엘리안, 3턴 브룬힐드 Lv2 — 사제를 1턴에 쓰러뜨리면 둘이 차례로
	var qq := Rules.state_floor3(7, "alive")
	Rules.start_battle(qq, "pyre")
	Rules.start_turn(qq)
	Rules.enemy(qq, "p1").hp = 5
	Rules.play(qq, give_card(qq, "broken_sword"), {"enemy": "p1"})
	var first := str(qq.battle.awaitFate.fate) if qq.battle.awaitFate != null else ""
	Rules.fate_trial_choice(qq, "defy")
	var second := str(qq.battle.awaitFate.fate) if qq.battle.awaitFate != null else ""
	var lv2 := int(qq.battle.awaitFate.level) if qq.battle.awaitFate != null else 0
	Rules.fate_trial_choice(qq, "offer")
	Rules.resume_enemy_phase(qq)
	check("v2 3층 화형 사제를 1턴에 쓰러뜨림: 엘리안 → 브룬힐드 Lv2 차례로 운명의 시도, 끝나면 전투 계속",
		first == "archer_burn" and second == "warrior_pierce" and lv2 == 2 and qq.party.allies.warrior.status == "dead" and qq.party.allies.archer.status != "dead"
		and qq.battle.awaitFate == null and qq.battle.result == null and Rules.scar_count(qq) == Rules.scar_count(s3) + 1, "%s %s %d" % [first, second, lv2])
	# 3층 3턴: 브룬힐드 Lv2 「운명의 꼬챙이」 (2턴 엘리안 시도 뒤)
	var r3 := p.duplicate(true)
	if r3.battle.result == null and r3.battle.phase == "player":
		Rules.end_turn(r3)
	Rules.start_turn(r3)
	var t3 = Rules.enemy(r3, "p1").intent
	check("v2 3층 3턴: 화형 사제 「운명의 꼬챙이 → 브룬힐드」 Lv2", t3 != null and t3.kind == "fate" and t3.target == "warrior" and int(t3.level) == 2, str(t3))
	# 동료를 모두 바쳐 노엘 혼자 남아도 노엘 HP 가 남으면 패배가 아니다
	var lone := Rules.state_floor3(7, "dead")
	lone.party.allies.archer.status = "dead"
	check("v2 패배 조건: 동료가 모두 죽고 노엘 혼자면 노엘 HP 로만 판단", not Rules.is_defeat(lone))
	# 데이터: 운명 표, 카드 그림 등록
	var okd := true
	for fid in D.fates:
		var fd: Dictionary = D.fates[fid]
		if not (D.cards.has(fd.card) and D.cards.has(fd.inherit) and D.cards[fd.card].kind == "death" and fd.scars.size() == 3):
			okd = false
	check("v2 데이터: 운명 표의 죽음·상속 카드, 흉터 장수", okd)


# ───────── 버티컬 슬라이스: 지도·촛불·어둠 (vertical-slice.md 5장 튜토리얼 지도 초안) ─────────
func _map_state(seed := 7) -> Dictionary:
	var st := Rules.new_game(seed)
	Rules.enter_room(st, "corridor")
	Rules.enter_room(st, "hall")
	return st


func t_map() -> void:
	var st := Rules.new_game(7)
	var M := Rules.map_def(st)
	var spine_ok: bool = M.rooms.has("camp") and M.rooms.has("corridor") and M.rooms.has("hall") and M.rooms.has("stairs") and M.rooms.has("deep") and str(M.end) == "deep"
	var opt := 0
	for id in M.rooms:
		if not M.rooms[id].get("spine", false):
			opt += 1
	check("지도: 정해진 길(곁방·장례 회랑·안치 홀·계단 앞 홀·가장 깊은 곳) + 골라 들어가는 방 8개", spine_ok and opt == 8, str(opt))
	var c0: int = st.progress.candles
	Rules.enter_room(st, "corridor")
	Rules.enter_room(st, "hall")
	check("지도: 랜턴을 받기 전에 지나온 방(장례 회랑·안치 홀)은 촛불이 타지 않는다", c0 == 4 and st.progress.candles == 4 and st.progress.visited.has("hall"))
	var lk := {}
	for id in ["prayer", "buried", "corpse", "stall", "stairs", "gravekeeper", "chapel", "training", "footprints", "deep"]:
		lk[id] = Rules.room_state(st, id)
	check("지도: 안치 홀에 붙은 방만 열림 — 무덤지기는 기도실 안쪽, 예배당·훈련장·발자국 방·가장 깊은 곳은 계단 앞 홀 뒤",
		lk.prayer == "open" and lk.buried == "open" and lk.corpse == "open" and lk.stall == "open" and lk.stairs == "open"
		and lk.gravekeeper == "locked" and lk.chapel == "locked" and lk.training == "locked" and lk.footprints == "locked" and lk.deep == "locked"
		and not Rules.enter_room(st, "deep").ok, str(lk))
	Rules.enter_room(st, "prayer")
	var g_open := Rules.room_state(st, "gravekeeper") == "open"
	Rules.enter_room(st, "stairs")
	var d_open := Rules.room_state(st, "deep") == "open" and Rules.room_state(st, "chapel") == "open"
	var c1: int = st.progress.candles
	var back := Rules.enter_room(st, "hall")
	check("지도: 지나간 방은 공짜로 지나간다(촛불 그대로), 기도실을 지나면 무덤지기·계단 앞 홀을 지나면 깊은 곳이 열린다",
		g_open and d_open and back.ok and not back.first and st.progress.candles == c1 and c1 == 2 and st.progress.room == "hall")


func t_candles() -> void:
	var st := _map_state()
	var seq := []
	for id in ["prayer", "buried", "corpse", "stall"]:
		var r := Rules.enter_room(st, id)
		seq.append(int(r.candles))
	var d0: int = st.progress.darkness
	var r5 := Rules.enter_room(st, "stairs")
	var r6 := Rules.enter_room(st, "gravekeeper")
	var r7 := Rules.enter_room(st, "prayer")
	check("촛불: 처음 들어가는 방마다 1개(4 → 0), 다 탄 뒤 처음 들어가는 방마다 어둠 +1, 지나간 방은 그대로",
		seq == [3, 2, 1, 0] and d0 == 0 and r5.dark == 1 and r6.dark == 1 and st.progress.darkness == 2 and r7.dark == 0 and not r7.first, str(seq))


func t_darkness() -> void:
	var st := _map_state()
	st.progress.darkness = 1
	var lv := {}
	for enc in ["normal", "prayer", "gravekeeper", "deep", "giant", "ossuary"]:
		lv[enc] = Rules.darkness_level(st, enc)
	check("어둠: 층 끝 전투(깊은 곳·거대한 발)·강적 전투에만 — 일반 전투·2층은 가려지지 않는다",
		lv.normal == 0 and lv.prayer == 0 and lv.gravekeeper == 1 and lv.deep == 1 and lv.giant == 1 and lv.ossuary == 0, str(lv))
	st.progress.omen = true
	check("전조를 보면 그 층 끝 전투는 어둠이 와도 가려지지 않는다(강적 전투는 그대로)",
		Rules.darkness_level(st, "deep") == 0 and Rules.darkness_level(st, "giant") == 0 and Rules.darkness_level(st, "gravekeeper") == 1)
	st.progress.omen = false
	# 어둠 단계만큼 예고가 '?'
	var counts := []
	for d in [0, 1, 2, 5]:
		var s2 := st.duplicate(true)
		s2.progress.darkness = d
		Rules.start_battle(s2, "deep")
		Rules.start_turn(s2)
		var n := 0
		for e in s2.battle.enemies:
			if e.intent != null and e.intent.get("hidden", false):
				n += 1
		counts.append(n)
	check("어둠 단계마다 예고 1개가 '?'로 가려진다 (광신도 2명: 0·1·2·2)", counts == [0, 1, 2, 2], str(counts))
	# 운명 공격 예고는 어둠에서도 보인다 — 거대한 발 3턴 「짓밟기」
	var g := st.duplicate(true)
	g.progress.darkness = 9
	Rules.start_battle(g, "giant")
	Rules.start_turn(g)
	var t1h: bool = Rules.enemy(g, "giant").intent.get("hidden", false)
	Rules.end_turn(g)
	Rules.start_turn(g)
	Rules.end_turn(g)
	Rules.start_turn(g)
	var t3 = Rules.enemy(g, "giant").intent
	check("운명 공격(「짓밟기」) 예고는 어둠에서도 가려지지 않는다 (1턴 그림자는 가려짐)", t1h and t3.kind == "stomp" and not t3.get("hidden", false), str(t3))
	# 가려진 예고도 규칙은 그대로: 피해가 그대로 들어온다
	var h := st.duplicate(true)
	h.progress.darkness = 2
	Rules.start_battle(h, "deep")
	Rules.start_turn(h)
	var aw: int = h.party.allies.archer.hp
	var wr: int = h.party.allies.warrior.hp
	Rules.end_turn(h)
	check("가려진 예고도 그대로 실행된다 (1턴: 엘리안 6·브룬힐드 5)", h.party.allies.archer.hp == aw - 6 and h.party.allies.warrior.hp == wr - 5)


func t_lantern_carry() -> void:
	var st := _map_state()
	Rules.enter_room(st, "prayer")
	st.progress.darkness = 3
	st.progress.omen = true
	Rules.descend(st)
	var a: bool = st.progress.candles == 7 and st.progress.darkness == 0 and not st.progress.omen and st.progress.visited.is_empty() and Rules.floor_now(st) == 2
	st.progress.candles = 6
	Rules.descend(st)
	check("다음 층: 남은 촛불 + 4개(최대 8), 어둠·전조는 풀린다", a and st.progress.candles == 8, str(st.progress))


# ───────── 방에서 얻는 카드 (대본 v3 3장) — 전투 승리 뒤 '카드 3장 중 1장' 보상은 2026-11-21 사용자 지시로 뺐다 ─────────
func t_rewards() -> void:
	# 전투 승리 뒤 보상 화면이 없다: 옛 reward 키가 없고, 이기면 카드를 얻는 방은 강적(무덤지기)뿐
	var rooms: Dictionary = D.floorMaps["1"].rooms
	var no_reward := true
	var win_rooms := []
	for rid in rooms:
		if rooms[rid].has("reward"):
			no_reward = false
		if rooms[rid].has("winCard"):
			win_rooms.append(rid)
	var plain: bool = rooms.corridor.has("enc") and rooms.prayer.has("enc") and not rooms.corridor.has("winCard") and not rooms.prayer.has("winCard")
	check("전투 승리 뒤 카드 보상 없음: 장례 회랑·기도실은 이겨도 카드를 주지 않고, 이기면 카드를 얻는 방은 무덤지기(강적)뿐",
		no_reward and plain and win_rooms == ["gravekeeper"] and str(rooms.gravekeeper.type) == "elite" and not D.rewards.has("rare") and not D.rewards.has("rareUp"), str(win_rooms))
	# 묘지기의 좌판(거래) 후보: 3장, 서로 다른 카드, 강화되지 않은 카드. 죽은 동료의 카드는 빠진다
	var st := Rules.new_game(7)
	var c := Rules.reward_choices(st, "common")
	var ids_c := c.map(func(x): return x.id)
	var uniq := count_of(ids_c).size() == 3
	var in_pool: bool = ids_c.all(func(x): return D.rewards.common.has(x)) and c.all(func(x): return not x.up)
	var dead_ok := true
	for sd in range(1, 41):
		var g := Rules.new_game(sd)
		g.party.allies.warrior.status = "dead"
		var gc := Rules.reward_choices(g, "common")
		if gc.size() != 3:
			dead_ok = false
		for it in gc:
			if str(D.cards[it.id].owner) == "warrior":
				dead_ok = false
	check("묘지기의 좌판 후보: 3장(서로 다른 카드, 강화 안 됨), 죽은 동료의 카드는 빠진다", c.size() == 3 and uniq and in_pool and dead_ok, str(ids_c))
	# 무덤지기(강적)를 이기면 [기본안]: 고르지 않고 희귀 목록(rewards.elite)의 카드 1장이 강화된 채(Lv2) 바로 덱에
	var e := Rules.new_game(7)
	var n0: int = e.party.deck.size()
	var u := Rules.win_card(e, str(rooms.gravekeeper.winCard))
	var eid: String = str(e.cards[u].id) if e.cards.has(u) else ""
	var got_ok: bool = u != "" and e.party.deck.size() == n0 + 1 and e.party.deck.has(u) and D.rewards.elite.has(eid) and Rules.is_up(e, u) and Rules.level(e, u) == 2
	# 여러 시드: 언제나 희귀 목록·강화된 카드 1장, 죽은 동료(브룬힐드, 짝수 시드는 세라피나도)의 카드는 나오지 않는다
	var seen := {}
	var all_ok := true
	for sd in range(1, 61):
		var g := Rules.new_game(sd)
		g.party.allies.warrior.status = "dead"
		if sd % 2 == 0:
			g.party.allies.hero.status = "dead"
		var d0: int = g.party.deck.size()
		var gu := Rules.win_card(g)
		if gu == "" or g.party.deck.size() != d0 + 1:
			all_ok = false
			continue
		var gid: String = str(g.cards[gu].id)
		seen[gid] = true
		var ow := str(D.cards[gid].owner)
		if not D.rewards.elite.has(gid) or not Rules.is_up(g, gu) or ow == "warrior" or (sd % 2 == 0 and ow == "hero"):
			all_ok = false
	check("무덤지기(강적) 승리: 고르는 화면 없이 희귀 목록의 카드 1장이 강화된 채(Lv2) 덱에, 죽은 동료의 카드는 빠진다",
		got_ok and all_ok and seen.size() >= 2, "%s %s" % [eid, str(seen.keys())])


func t_trade_event() -> void:
	var st := Rules.new_game(7)
	var w0: int = st.party.witch.hp
	var ok_c := Rules.trade(st, "card", {"id": "snipe"})
	var w1: int = st.party.witch.hp
	var ok_k := Rules.trade(st, "candle")
	check("거래: 카드 — 노엘 HP 4, 촛불 1개 — HP 2 (촛불 +1)", ok_c and w1 == w0 - 4 and ok_k and st.party.witch.hp == w1 - 2 and st.progress.candles == 5
		and _deck_ids(st).count("snipe") == 3)
	st.party.witch.hp = 4
	var no_c := Rules.trade(st, "card", {"id": "snipe"})
	st.party.witch.hp = 2
	var no_k := Rules.trade(st, "candle")
	st.party.witch.hp = 15
	st.progress.candles = 8
	var full := Rules.trade(st, "candle")
	check("거래: HP 가 대가 이하이면 못 산다, 촛불은 최대 8개", not no_c and not no_k and not full and st.party.witch.hp == 15)
	var b := Rules.new_game(7)
	b.party.witch.hp = 2
	Rules.hurt_witch(b, int(D.buried.hp))
	check("사건(꺼낸다): 노엘 HP −2 (1 아래로는 줄지 않음)", b.party.witch.hp == 1 and D.buried.card == "small_charm" and D.corpse.card == "nameless_card")


func t_nameless() -> void:
	var st := normal_battle()
	var u := give_card(st, "nameless_card")
	var c0 := Rules.cost(st, u)
	var vt := Rules.valid_targets(st, u)
	var whp: int = st.party.witch.hp
	var ahp: int = st.party.allies.archer.hp
	var r := Rules.play(st, u, {"enemy": "c3"})
	var it = Rules.enemy(st, "c3").intent
	var gone: bool = st.battle.exhaust.has(u) and not st.battle.discard.has(u) and not st.battle.hand.has(u)
	Rules.end_turn(st)
	check("「이름 없는 마녀의 카드」: 비용 0, 예고 하나를 지운다(그 공격은 일어나지 않음), 노엘 HP −3, 이 전투에서 사라짐",
		c0 == 0 and vt.size() == 3 and r.ok and it.blocked and Rules.intent_damage(it) == 0 and st.party.witch.hp == whp - 3 and st.party.allies.archer.hp == ahp and gone)
	# 운명 공격은 지울 수 없다 (2층 2턴 「운명의 관통」)
	var o := Rules.state_after_tutorial(7)
	Rules.start_battle(o, "ossuary")
	Rules.start_turn(o)
	Rules.end_turn(o)
	Rules.start_turn(o)
	var nu := give_card(o, "nameless_card")
	var vto := Rules.valid_targets(o, nu)
	check("「이름 없는 마녀의 카드」: 운명 공격 예고는 지울 수 없다", not vto.has("k1") and not Rules.play(o, nu, {"enemy": "k1"}).ok, str(vto))
	# 거대한 발의 「기둥 붕괴」(운명이 아닌 광역)는 지울 수 있고, 「짓밟기」(운명)는 못 지운다
	var g := giant_battle()
	Rules.end_turn(g)
	Rules.start_turn(g)
	var gu := give_card(g, "nameless_card")
	var can2: bool = Rules.valid_targets(g, gu).has("giant")
	Rules.play(g, gu, {"enemy": "giant"})
	var w2: int = g.party.witch.hp
	Rules.end_turn(g)
	var no_hit: bool = g.party.witch.hp == w2 and g.party.allies.hero.hp == 30
	Rules.start_turn(g)
	var gu2 := give_card(g, "nameless_card")
	check("「이름 없는 마녀의 카드」: 「기둥 붕괴」는 지워진다, 「짓밟기」(운명)는 못 지운다", can2 and no_hit and not Rules.valid_targets(g, gu2).has("giant"))


func t_charm() -> void:
	var st := normal_battle()
	st.party.allies.archer.hp = 5
	st.party.allies.warrior.hp = 23
	var u := give_card(st, "small_charm")
	var r := Rules.play(st, u, {"ally": "archer"})
	var u2 := give_card(st, "small_charm")
	Rules.play(st, u2, {"ally": "warrior"})
	Rules.debug_set_hp(st, "hero", 0)
	var u3 := give_card(st, "small_charm")
	var vt := Rules.valid_targets(st, u3)
	check("「작은 손의 부적」: 비용 1, 동료 하나 HP 4 회복(최대 HP 까지), 쓰러진 동료·노엘은 대상이 아니다",
		r.ok and st.party.allies.archer.hp == 9 and st.party.allies.warrior.hp == 24 and st.battle.energy == 1 and not vt.has("hero") and not vt.has("witch")
		and not Rules.play(st, u3, {"ally": "witch"}).ok and Rules.card_text("small_charm") == "동료 하나 HP 4 회복", str(vt))


func t_retry_hp() -> void:
	var st := Rules.new_game(7)
	st.party.witch.hp = 2
	Rules.start_battle(st, "giant")
	var snap := Rules.snapshot(st)
	var st2 := Rules.restore(snap, st.rng)
	check("전멸 뒤 다시 하기: 노엘 HP 가 낮으면 retryWitchHp(6)로 — 계속 지는 막힘 방지", st2.party.witch.hp == int(D.rules.retryWitchHp))


func _collect(v, out: Array) -> void:
	if v is String:
		out.append(v)
	elif v is Dictionary:
		for k in v:
			_collect(v[k], out)
	elif v is Array:
		for x in v:
			_collect(x, out)
