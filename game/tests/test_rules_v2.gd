## 전투 시험판 v2 「맡기기」 + v2.1 「3D 탁자」 규칙 시험 (core/rules_v2.gd · docs/battle-v2-spec.md). tests/test_rules.gd 가 t_v2() 에서 부른다:
##   godot --headless --path game --script res://tests/test_rules.gd
## 특성 넷(용사·버팀·조준·노엘은 칸 없음) · 카드 열하나(공용·전용·노엘) · 계산 순서 · 하수인(부르기·막기·저격으로 넘기·본체와 함께 사라짐)
## · 운명 전가(옮기기·되돌리기) · 승패 · 자동 진행이 끝까지 가는지 · 문구 글자가 글꼴에 있는지
## · v2.1: 적의 죽음 카드(막을 수 없음·무덤지기를 쓰러뜨림·운명 전가·운명 찢기·벤치에서 기다림·운명이 미뤄짐) · 출전 배치·자리 바꾸기(에너지 1) · 빈칸 공격은 노엘
## · 밤샘 계획 2 C: 2·3층 운명(집행자의 죽음 카드 → 운명의 시도 받아들인다/거스른다 · 집행자를 먼저 쓰러뜨려도 운명은 남음 · 벤치에서 미뤄짐 · 두 죽음 ·
##   상속·유품·흉터 · 꿰뚫린 방패 · 게임 상태에 돌려 적기 · 자동 진행이 끝까지)
class_name TestRulesV2
extends RefCounted

var t   # test_rules.gd (check)


func check(name: String, ok: bool, detail := "") -> void:
	t.check("전투 v2: " + name, ok, detail)


static func run(tester) -> void:
	var r := TestRulesV2.new()
	r.t = tester
	# 시험 함수마다 끝에서 true 를 돌려준다 — 도중에 스크립트 에러로 멈추면 실패로 센다(에러만 찍히고 통과로 보이지 않게)
	for m in ["t_setup", "t_turn", "t_owner", "t_hero", "t_brace", "t_aim", "t_noel", "t_order", "t_minion", "t_shift", "t_win_lose", "t_forecast", "t_auto", "t_auto_human", "t_text",
			"t_formation", "t_noel_hp", "t_death", "t_death_escape", "t_death_bench",
			"t_game_setup", "t_game_tutorial", "t_game_cards", "t_game_gravekeeper", "t_game_deep_giant", "t_game_darkness", "t_game_apply", "t_game_auto",
			"t_fate_setup", "t_fate_trial_defy", "t_fate_trial_accept", "t_fate_executor", "t_fate_bench", "t_fate_pyre_two", "t_fate_cards", "t_fate_alone", "t_fate_auto"]:
		if r.call(m) != true:
			r.check(m + " 이 끝까지 돌았다", false, "스크립트 에러로 멈춤")
	tester.v2_done = true


# ───────── 도움 ─────────
## 시험용 전투: 1턴을 시작하고 손패를 ids 로 바꾼다(덱에서 그 카드를 찾아 손패로 — 없으면 새로 만든다). 적 행동은 intents 로 덮어쓴다
func battle(ids: Array, intents := {}) -> Dictionary:
	var st := RulesV2.new_battle(7)
	RulesV2.start_turn(st)
	st.discard.append_array(st.hand)
	st.hand = []
	for id in ids:
		var u := ""
		for k in st.discard + st.draw:
			if st.cards[k].id == id and not st.hand.has(k):
				u = k
				break
		if u == "":
			u = "x" + str(st.nextUid)
			st.nextUid = int(st.nextUid) + 1
			st.cards[u] = {"uid": u, "id": id}
		st.discard.erase(u)
		st.draw.erase(u)
		st.hand.append(u)
	for e in st.enemies:
		if intents.has(e.id):
			e.intent = intents[e.id]
		elif e.alive:
			e.intent = null
	return st


func D_reason(r: String) -> String:
	return str(BattleV2Data.D.reasons.get(r, ""))


func uid_of(st: Dictionary, id: String, nth := 0) -> String:
	var n := 0
	for u in st.hand:
		if st.cards[u].id == id:
			if n == nth:
				return u
			n += 1
	return ""


## 한 명 공격: slot 은 칸 번호 또는 동료 id(기본 배치의 그 동료 칸 — 세라피나 0 · 브룬힐드 1 · 엘리안 2)
func hit(v: int, slot) -> Dictionary:
	var c: int = slot if slot is int else int({"hero": 0, "warrior": 1, "archer": 2}[str(slot)])
	return {"kind": "hit", "label": "찌르기", "value": v, "minus": 0, "slot": c}


func summon_minion(st: Dictionary) -> void:
	var s = RulesV2.enemy(st, "S")
	s.alive = true
	s.hp = int(s.maxHp)


func ev_of(ev: Array, t_name: String) -> Array:
	return ev.filter(func(e): return e.t == t_name)


# ───────── 시험 ─────────
func t_setup() -> bool:
	var st := RulesV2.new_battle(7)
	var cnt := {}
	for u in st.draw:
		cnt[st.cards[u].id] = int(cnt.get(st.cards[u].id, 0)) + 1
	var want := {}
	for p in BattleV2Data.D.deck:
		want[p[0]] = int(p[1])
	check("덱 15장: 지시서 5장 표(베기 2·막기 2·성검 베기 2·되돌리기 1·겨누기 2·저격 1·운명 전가·축복·저주·취약 1) + 운명 찢기 1", cnt == want and st.draw.size() == 15 and int(cnt.get("tear", 0)) == 1, str(cnt))
	var hp: Array = st.order.map(func(id): return st.allies[id].hp)
	check("동료: 왼쪽부터 세라피나 30 · 브룬힐드 24 · 엘리안 12, 배율 ×1 · 버팀 0", st.order == ["hero", "warrior", "archer"] and hp == [30, 24, 12]
		and st.allies.archer.mult == 1 and st.allies.warrior.brace == 0, str(hp))
	check("v2.1: 출전 배치부터(기본 세라피나·브룬힐드·엘리안, 벤치 없음) · 노엘 HP 15", st.phase == "formation" and st.slots == ["hero", "warrior", "archer"] and st.bench.is_empty()
		and st.noelHp == 15 and st.noelMax == 15, str([st.phase, st.slots, st.noelHp]))
	var en: Array = st.enemies.map(func(e): return "%s:%s:%d:%s" % [e.id, e.type, e.maxHp, e.alive])
	check("적: 광신도 A(14) · 무덤지기(30) · 해골 병사(8, 처음에는 없음) · 광신도 B(14)", en == ["A:cultist:14:true", "G:gravekeeper:30:true", "S:skeleton:8:false", "B:cultist:14:true"], str(en))
	return true



func t_turn() -> bool:
	var st := RulesV2.new_battle(11)
	RulesV2.start_turn(st)
	var st2 := RulesV2.new_battle(11)
	RulesV2.start_turn(st2)
	check("내 턴 시작: 5장 · 행동 에너지 3", st.hand.size() == 5 and st.energy == 3)
	check("같은 시드면 같은 손패·같은 적 행동", var_to_str(st.hand.map(func(u): return st.cards[u].id)) == var_to_str(st2.hand.map(func(u): return st2.cards[u].id))
		and var_to_str(st.enemies) == var_to_str(st2.enemies))
	var a = RulesV2.enemy(st, "A")
	var g = RulesV2.enemy(st, "G")
	check("광신도: 찌르기 5~6 → 칸 하나(0~2) · 무덤지기: 하수인이 없으면 「해골 병사 부르기」",
		a.intent.kind == "hit" and int(a.intent.value) >= 5 and int(a.intent.value) <= 6 and a.intent.slot is int and int(a.intent.slot) >= 0 and int(a.intent.slot) <= 2
		and g.intent.kind == "summon" and RulesV2.enemy(st, "S").intent == null, str([a.intent, g.intent]))
	var ev := RulesV2.end_turn(st)
	var s = RulesV2.enemy(st, "S")
	check("적 턴에 부르기 → 해골 병사(HP 8)가 무덤지기 앞에", not ev_of(ev, "summon").is_empty() and s.alive and s.hp == 8)
	RulesV2.start_turn(st)
	check("하수인이 있으면 무덤지기는 「삽 내려치기 8」, 해골 병사도 자기 공격(녹슨 칼 4)을 ② 에", g.intent.kind == "hit" and g.intent.value == 8 and g.intent.label == "삽 내려치기"
		and s.intent != null and s.intent.kind == "hit" and s.intent.value == 4, str([g.intent, s.intent]))
	check("턴 끝: 손패·놓은 카드는 버린 더미로(덱은 늘 15장)", st.draw.size() + st.hand.size() + st.discard.size() == 15)
	# 3턴마다 광신도 하나가 휩쓸기 3 → 모두
	RulesV2.end_turn(st)
	RulesV2.start_turn(st)
	var sw = RulesV2.sweep_enemy(st)
	check("3턴: 광신도 하나가 「휩쓸기 3 → 모두」(무덤지기·하수인은 아님), 모두 노려져 붉은 테두리", st.turn == 3 and sw != null and sw.type == "cultist" and sw.intent.value == 3
		and st.order.all(func(id): return st.allies[id].down or RulesV2.is_targeted(st, id)), str(sw))
	check("3턴: 무덤지기의 3번째 행동 = 「세라피나의 죽음」(세라피나 칸 ②)", g.intent.kind == "death" and str(g.intent.label) == "세라피나의 죽음"
		and st.deaths.size() == 1 and st.deaths[0].ally == "hero" and RulesV2.col_of(st, "hero") == 0, str([g.intent, st.deaths]))
	return true



func t_owner() -> bool:
	var st := battle(["holy", "revert", "snipe", "slash", "bless"])
	check("전용 카드는 그 동료 칸에만: 성검 베기 → 브룬힐드 칸 안 됨, 세라피나 칸 됨", RulesV2.can_place(st, uid_of(st, "holy"), "warrior").reason == "notOwner"
		and RulesV2.can_place(st, uid_of(st, "holy"), "hero").ok)
	check("되돌리기는 브룬힐드만 · 저격은 엘리안만 · 베기(공용)는 누구에게나", RulesV2.can_place(st, uid_of(st, "revert"), "hero").reason == "notOwner"
		and RulesV2.can_place(st, uid_of(st, "snipe"), "hero").reason == "notOwner" and RulesV2.can_place(st, uid_of(st, "snipe"), "archer").ok
		and RulesV2.can_place(st, uid_of(st, "slash"), "warrior").ok)
	check("노엘의 카드는 칸에 놓지 않는다(② ① ④ 에 직접)", RulesV2.can_place(st, uid_of(st, "bless"), "hero").reason == "noelCard")
	var pr := RulesV2.place(st, uid_of(st, "slash"), "hero")
	check("9-6: 공격은 대상을 고르지 않고 앞(같은 열) 적에게 — 세라피나(칸 0) → 광신도 A", pr.ok and str(pr.placed.target) == "A")
	var st9 := battle(["slash", "guard", "bless"])
	RulesV2.enemy(st9, "A").alive = false
	check("9-6: 앞 열에 적이 없으면 공격 카드는 못 놓는다(「앞에 적이 없습니다」) — 막기·노엘 카드는 된다",
		RulesV2.can_place(st9, uid_of(st9, "slash"), "hero").reason == "noFront" and RulesV2.can_place(st9, uid_of(st9, "guard"), "hero").ok
		and RulesV2.can_cast(st9, uid_of(st9, "bless"), "hero").ok and str(D_reason("noFront")) == "앞에 적이 없습니다")
	var st8 := battle(["slash"])
	RulesV2.place(st8, uid_of(st8, "slash"), "hero")
	RulesV2.move_ally(st8, "hero", 2)
	RulesV2.end_turn(st8)
	check("9-6: 자리를 바꾸면 그 열의 적을 친다(세라피나 칸 0 → 2: 광신도 B 14 → 8)", RulesV2.enemy(st8, "B").hp == 8 and RulesV2.enemy(st8, "A").hp == 14)
	var st2 := battle(["slash", "guard", "guard", "slash"])
	RulesV2.place(st2, uid_of(st2, "slash"), "hero")
	RulesV2.place(st2, uid_of(st2, "guard"), "hero")
	check("v2.2: 한 칸 카드 수 제한 없음 — 세 번째 카드도 같은 동료에게(에너지가 있으면)", RulesV2.can_place(st2, uid_of(st2, "guard"), "hero").ok)
	RulesV2.place(st2, uid_of(st2, "guard"), "warrior")
	check("행동 에너지 3 을 다 쓰면 더 못 놓는다", st2.energy == 0 and RulesV2.can_place(st2, uid_of(st2, "slash"), "archer").reason == "noEnergy")
	var r := RulesV2.unplace(st2, "hero", 0)
	check("놓은 카드를 손패로 되돌리면 에너지도 돌려받는다", r.ok and st2.energy == 1 and st2.hand.has(r.uid) and st2.allies.hero.placed.size() == 1)
	st2.allies.archer.down = true
	check("쓰러진 동료의 칸에는 놓을 수 없다", RulesV2.can_place(st2, uid_of(st2, "slash"), "archer").reason == "down")
	# v2.2: 한 동료에게 4장 이상(에너지만큼) — 겨누기 2 + 저격 → 7 × 배율 3 = 21
	var st3 := battle(["aim", "aim", "snipe", "guard", "slash"])
	st3.energy = 5
	var ok3: bool = RulesV2.place(st3, uid_of(st3, "aim"), "archer").ok and RulesV2.place(st3, uid_of(st3, "aim"), "archer").ok
	ok3 = ok3 and RulesV2.place(st3, uid_of(st3, "snipe"), "archer").ok and RulesV2.place(st3, uid_of(st3, "guard"), "archer").ok
	ok3 = ok3 and RulesV2.place(st3, uid_of(st3, "slash"), "archer").ok
	var snipe_dmg := 0
	var fc3 := RulesV2.forecast(st3)
	for p in st3.allies.archer.placed:
		if st3.cards[p.uid].id == "snipe":
			snipe_dmg = int(fc3[p.uid].get("dmg", 0))
	check("v2.2: 한 동료 칸에 5장(에너지 5) · 겨누기 둘 뒤 저격 21", ok3 and st3.allies.archer.placed.size() == 5 and st3.energy == 0 and snipe_dmg == 21,
		str([st3.allies.archer.placed.size(), st3.energy, snipe_dmg]))
	return true



func t_hero() -> bool:
	var st := battle(["holy", "slash"], {"A": hit(6, "hero")})
	RulesV2.place(st, uid_of(st, "holy"), "hero")
	var ev := RulesV2.end_turn(st)
	var hits := ev_of(ev, "allyHit")
	check("용사: 성검 베기 8 + 막기 3 → 광신도 A HP 6, 찌르기 6 중 3 을 막음", RulesV2.enemy(st, "A").hp == 6 and hits.size() == 1 and hits[0].blocked == 3 and st.allies.hero.hp == 27,
		str(hits))
	var st2 := battle(["guard"], {"A": hit(6, "hero"), "B": hit(5, "hero")})
	RulesV2.place(st2, uid_of(st2, "guard"), "hero")
	var ev2 := RulesV2.end_turn(st2)
	check("용사: 막기를 맡으면 막은 뒤 자기를 친 적마다 반격 3 (A 14→11, B 14→11)", ev_of(ev2, "counter").size() == 2 and RulesV2.enemy(st2, "A").hp == 11
		and RulesV2.enemy(st2, "B").hp == 11 and st2.allies.hero.hp == 24, str(ev_of(ev2, "counter")))
	var st3 := battle(["guard"], {"A": hit(6, "warrior")})
	RulesV2.place(st3, uid_of(st3, "guard"), "warrior")
	RulesV2.end_turn(st3)
	check("반격은 세라피나만 (브룬힐드 막기에는 반격 없음)", RulesV2.enemy(st3, "A").hp == 14)
	return true



func t_brace() -> bool:
	var st := battle(["guard"], {"A": hit(6, "warrior"), "B": hit(5, "warrior")})
	RulesV2.place(st, uid_of(st, "guard"), "warrior")
	var fc := RulesV2.forecast(st)
	RulesV2.end_turn(st)
	check("버팀: 막기 5 × 1.5 = 7(내림), 막아낸 7 만큼 버팀이 쌓인다", int(fc.values()[0].block) == 7 and st.allies.warrior.brace == 7 and st.allies.warrior.hp == 24 - 4,
		str([fc, st.allies.warrior]))
	RulesV2.start_turn(st)
	check("버팀은 전투 내내 남는다(턴이 지나도)", st.allies.warrior.brace == 7)
	st.allies.warrior.brace = 19
	st.allies.warrior.block = 5
	var ev := []
	RulesV2._hit_ally(st, "warrior", 5, "A", ev)
	check("버팀은 최대 20", st.allies.warrior.brace == 20)
	var st2 := battle(["revert"])
	st2.allies.warrior.brace = 12
	RulesV2.place(st2, uid_of(st2, "revert"), "warrior")
	RulesV2.end_turn(st2)
	check("되돌리기: 쌓인 버팀 12 만큼 앞 적(무덤지기 30 → 18)에게 피해, 버팀 0", RulesV2.enemy(st2, "G").hp == 18 and st2.allies.warrior.brace == 0)
	return true



func t_aim() -> bool:
	var st := battle(["aim", "snipe"])
	RulesV2.place(st, uid_of(st, "aim"), "archer")
	RulesV2.place(st, uid_of(st, "snipe"), "archer")
	st.allies.archer.mult = 2
	RulesV2.enemy(st, "B").hp = 30
	RulesV2.end_turn(st)
	check("조준: 겨누기 → 배율 ×3, 저격 7 × 3 = 21(앞 적 광신도 B 30 → 9), 쏜 뒤 ×1", RulesV2.enemy(st, "B").hp == 9 and st.allies.archer.mult == 1, str(RulesV2.enemy(st, "B")))
	var st2 := battle(["aim", "aim"])
	st2.allies.archer.mult = 3
	RulesV2.place(st2, uid_of(st2, "aim"), "archer")
	RulesV2.place(st2, uid_of(st2, "aim", 0), "archer")
	RulesV2.end_turn(st2)
	check("배율은 최대 ×4, 공격하지 않으면 다음 턴에도 남는다", st2.allies.archer.mult == 4)
	var st3 := battle(["slash"], {"A": hit(5, "archer")})
	st3.allies.archer.mult = 3
	RulesV2.end_turn(st3)
	check("엘리안이 피해를 받으면 배율 -1", st3.allies.archer.mult == 2 and st3.allies.archer.hp == 7)
	var st4 := battle(["guard"], {"A": hit(5, "archer")})
	st4.allies.archer.mult = 3
	RulesV2.place(st4, uid_of(st4, "guard"), "archer")
	RulesV2.end_turn(st4)
	check("다 막아 피해가 없으면 배율은 그대로", st4.allies.archer.mult == 3 and st4.allies.archer.hp == 12)
	var st5 := battle(["slash"])
	st5.allies.archer.mult = 2
	RulesV2.place(st5, uid_of(st5, "slash"), "archer")
	RulesV2.end_turn(st5)
	check("엘리안의 베기(공용)에도 배율이 붙는다 (6 × 2 = 12)", RulesV2.enemy(st5, "B").hp == 2 and st5.allies.archer.mult == 1)
	return true



func t_noel() -> bool:
	var st := battle(["bless", "holy", "guard"])
	check("축복은 ④ 동료에 놓는다(적에는 안 됨)", RulesV2.can_cast(st, uid_of(st, "bless"), "A").reason == "badAlly" and RulesV2.can_cast(st, uid_of(st, "bless"), "hero").ok)
	RulesV2.cast(st, uid_of(st, "bless"), "hero")
	RulesV2.place(st, uid_of(st, "holy"), "hero")
	RulesV2.place(st, uid_of(st, "guard"), "hero")
	var fc := RulesV2.forecast(st)
	RulesV2.end_turn(st)
	var hv := 0
	var bv := 0
	for u in fc:
		hv += int(fc[u].get("dmg", 0))
		bv += int(fc[u].get("block", 0))
	check("축복: 성검 베기 8 → 12 · 용사 막기 3 → 4 · 막기 5 → 7 (+50%, 내림)", RulesV2.enemy(st, "A").hp == 2 and hv == 12 and bv == 11, str(fc))
	var st2 := battle(["curse", "curse"], {"A": hit(6, "hero"), "B": {"kind": "sweep", "label": "휩쓸기", "value": 3, "minus": 0, "slot": "all"}})
	check("저주는 ② 적 행동 카드에 놓는다(부르기에는 안 됨)", RulesV2.can_cast(st2, uid_of(st2, "curse"), "G").reason == "badAct")
	RulesV2.cast(st2, uid_of(st2, "curse"), "A")
	RulesV2.cast(st2, uid_of(st2, "curse"), "B")
	RulesV2.end_turn(st2)
	check("저주: 찌르기 6 → 3 · 휩쓸기 3 → 0", st2.allies.hero.hp == 27 and st2.allies.warrior.hp == 24 and st2.allies.archer.hp == 12,
		str(st2.order.map(func(id): return st2.allies[id].hp)))
	var st3 := battle(["vuln", "slash"])
	RulesV2.cast(st3, uid_of(st3, "vuln"), "B")
	RulesV2.place(st3, uid_of(st3, "slash"), "archer")
	RulesV2.end_turn(st3)
	check("취약: ① 적에 놓으면 이번 턴에 받는 피해 +50% (베기 6 → 9), 턴이 끝나면 사라짐", RulesV2.enemy(st3, "B").hp == 5 and not RulesV2.enemy(st3, "B").vuln)
	var st4 := battle(["vuln", "bless"])
	RulesV2.cast(st4, uid_of(st4, "vuln"), "A")
	var r := RulesV2.uncast(st4, 0)
	check("노엘의 카드도 턴 끝 전에는 되돌린다(효과·에너지)", r.ok and not RulesV2.enemy(st4, "A").vuln and st4.energy == 3 and st4.hand.size() == 2)
	return true



func t_order() -> bool:
	# 기본 7 → 배율 ×2 = 14 → 축복 21 → 취약 31 (단계마다 내림)
	var st := battle(["snipe", "bless", "vuln"])
	st.allies.archer.mult = 2
	RulesV2.place(st, uid_of(st, "snipe"), "archer")
	RulesV2.cast(st, uid_of(st, "bless"), "archer")
	RulesV2.cast(st, uid_of(st, "vuln"), "B")
	var fc := RulesV2.forecast(st)
	RulesV2.end_turn(st)
	check("계산 순서: 저격 7 × 배율 2 = 14 → 축복 21 → 취약 31 (미리 보기도 같다)", RulesV2.enemy(st, "B").hp == 0 and int(fc.values()[0].dmg) == 31, str(fc))
	# 기본 5 → 버팀 7 → 축복 10
	var st2 := battle(["guard", "bless"])
	RulesV2.place(st2, uid_of(st2, "guard"), "warrior")
	RulesV2.cast(st2, uid_of(st2, "bless"), "warrior")
	check("막기 계산 순서: 5 → 버팀 1.5배 7 → 축복 10", int(RulesV2.forecast(st2).values()[0].block) == 10)
	# 단계마다 내림: 베기 6 → 축복 9 → 취약 13 (한 번에 곱하면 13.5 → 13 으로 같음) / 성검 베기 8 → 12 → 18
	var st3 := battle(["slash", "bless", "vuln"])
	RulesV2.place(st3, uid_of(st3, "slash"), "hero")
	RulesV2.cast(st3, uid_of(st3, "bless"), "hero")
	RulesV2.cast(st3, uid_of(st3, "vuln"), "A")
	check("베기 6 → 축복 9 → 취약 13 (내림)", int(RulesV2.forecast(st3).values().filter(func(r): return r.has("dmg"))[0].dmg) == 13)
	return true



func t_minion() -> bool:
	# 9-6: 무덤지기·해골 병사는 칸 1 의 앞 적 — 칸 1 에 선 동료의 공격만 들어간다
	var st := battle(["slash"])
	summon_minion(st)
	RulesV2.place(st, uid_of(st, "slash"), "warrior")
	RulesV2.end_turn(st)
	var stp := battle(["snipe"])
	summon_minion(stp)
	stp.slots = ["hero", "archer", "warrior"]
	RulesV2.place(stp, uid_of(stp, "snipe"), "archer")
	RulesV2.end_turn(stp)
	check("하수인: 앞 열(칸 1)의 베기는 해골 병사가 먼저 받는다(8 → 2), 저격은 넘어 그 열 본체로(30 → 23)",
		RulesV2.enemy(st, "S").hp == 2 and RulesV2.enemy(st, "G").hp == 30 and RulesV2.enemy(stp, "G").hp == 23 and RulesV2.enemy(stp, "S").hp == 8,
		str([RulesV2.enemy(st, "S").hp, RulesV2.enemy(st, "G").hp, RulesV2.enemy(stp, "G").hp]))
	var st2 := battle(["slash", "slash"])
	summon_minion(st2)
	RulesV2.enemy(st2, "S").hp = 4
	RulesV2.place(st2, uid_of(st2, "slash"), "warrior")
	RulesV2.place(st2, uid_of(st2, "slash", 0), "warrior")
	RulesV2.end_turn(st2)
	check("하수인을 쓰러뜨리면 다음 공격은 본체로 (넘친 피해는 넘어가지 않음)", not RulesV2.enemy(st2, "S").alive and RulesV2.enemy(st2, "G").hp == 24)
	var st3 := battle(["snipe"])
	summon_minion(st3)
	st3.allies.archer.mult = 4
	RulesV2.enemy(st3, "G").hp = 20
	RulesV2.enemy(st3, "S").intent = hit(4, "hero")
	st3.slots = ["hero", "archer", "warrior"]
	RulesV2.place(st3, uid_of(st3, "snipe"), "archer")
	var ev := RulesV2.end_turn(st3)
	check("본체가 쓰러지면 하수인도 사라지고, 쓰러진 적이 보낸 ② 는 들어가지 않는다", not RulesV2.enemy(st3, "G").alive and not RulesV2.enemy(st3, "S").alive
		and st3.allies.hero.hp == 30 and ev_of(ev, "enemyDie").size() == 2)
	return true



func t_shift() -> bool:
	var st := battle(["shift", "shift"], {"A": hit(6, "archer"), "B": hit(5, "hero")})
	check("운명 전가는 ② 의 한 명 공격에 (부르기·없는 행동에는 안 됨)", RulesV2.can_cast(st, uid_of(st, "shift"), "G").reason == "badAct")
	RulesV2.cast(st, uid_of(st, "shift"), "A", {"to": "warrior"})
	check("운명 전가: 엘리안 칸의 찌르기를 브룬힐드 칸으로 — 놓는 즉시 옮긴다(에너지 2)", int(RulesV2.enemy(st, "A").intent.slot) == 1 and st.energy == 1
		and RulesV2.intents_at(st, 2).is_empty())
	st.energy = 3
	RulesV2.cast(st, uid_of(st, "shift"), "A", {"to": "hero"})
	check("다시 옮긴 뒤 앞의 운명 전가를 되돌리려 하면 나중 것을 먼저", RulesV2.uncast(st, 0).reason == "movedAgain")
	RulesV2.uncast(st, 1)
	RulesV2.uncast(st, 0)
	check("되돌리면 옮긴 행동도 제자리(엘리안 칸)", int(RulesV2.enemy(st, "A").intent.slot) == 2 and st.noel.is_empty())
	return true



func t_win_lose() -> bool:
	var st := battle(["snipe", "slash", "slash"])
	RulesV2.enemy(st, "A").hp = 6
	RulesV2.enemy(st, "B").hp = 6
	RulesV2.enemy(st, "G").hp = 7
	summon_minion(st)
	st.slots = ["hero", "archer", "warrior"]
	RulesV2.place(st, uid_of(st, "slash"), "hero")
	RulesV2.place(st, uid_of(st, "slash", 0), "warrior")
	RulesV2.place(st, uid_of(st, "snipe"), "archer")
	var ev := RulesV2.end_turn(st)
	check("승리: 광신도 둘과 무덤지기가 쓰러지면(하수인은 함께 사라짐) 그 자리에서 — 적 턴 없음", st.result == "win" and ev_of(ev, "enemyAct").is_empty())
	check("전투가 끝나면 더 놓을 수 없다", RulesV2.can_place(st, "v1", "hero").reason == "over")
	var st2 := battle([], {"A": {"kind": "sweep", "label": "휩쓸기", "value": 40, "minus": 0, "slot": "all"}})
	var ev2 := RulesV2.end_turn(st2)
	check("패배: 동료가 모두 쓰러지면", st2.result == "lose" and st2.loseBy == "allies" and ev_of(ev2, "allyDown").size() == 3)
	return true



func t_forecast() -> bool:
	var st := battle(["aim", "snipe", "guard"], {"A": hit(6, "warrior")})
	RulesV2.place(st, uid_of(st, "aim"), "archer")
	RulesV2.place(st, uid_of(st, "snipe"), "archer")
	RulesV2.place(st, uid_of(st, "guard"), "warrior")
	var fc := RulesV2.forecast(st)
	var before := var_to_str(st)
	var u_snipe := ""
	for p in st.allies.archer.placed:
		if st.cards[p.uid].id == "snipe":
			u_snipe = p.uid
	check("미리 보기는 상태를 바꾸지 않는다", var_to_str(st) == before)
	RulesV2.end_turn(st)
	check("미리 보기 = 실제 결과 (겨누기 → 저격 14, 막기 7)", int(fc[u_snipe].dmg) == 14 and RulesV2.enemy(st, "B").hp == 0, str(fc))
	var st2 := battle(["guard"])
	check("끄는 동안 미리 보기(놓기 전): 브룬힐드 막기 7 · 세라피나 막기 5 + 반격 3", int(RulesV2.forecast_place(st2, uid_of(st2, "guard"), "warrior").block) == 7
		and int(RulesV2.forecast_place(st2, uid_of(st2, "guard"), "hero").get("counter", 0)) == 3)
	return true



func t_auto() -> bool:
	var results := {}
	var ok := true
	var bad := ""
	for sd in range(1, 31):
		var st := RulesV2.new_battle(sd)
		RulesV2.start_turn(st)
		var steps := 0
		while st.result == null and st.turn < 60 and steps < 2000:
			steps += 1
			var a := RulesV2.auto_step(st)
			if a.kind == "end":
				RulesV2.end_turn(st)
				RulesV2.start_turn(st)
			else:
				var r: Dictionary = {}
				match str(a.kind):
					"place":
						r = RulesV2.place(st, a.uid, a.ally, a.opts)
					"cast":
						r = RulesV2.cast(st, a.uid, a.target, a.opts)
					"move":
						r = RulesV2.move_ally(st, a.ally, a.to)
				if not r.ok:
					ok = false
					bad = "seed %d: %s %s" % [sd, str(a), str(r)]
					break
		if st.result == null:
			ok = false
			bad = "seed %d: 끝나지 않음 turn %d" % [sd, st.turn]
		results[str(st.result)] = int(results.get(str(st.result), 0)) + 1
	check("자동 진행: 시드 1~30 모두 결과까지(규칙이 거절한 수 0, 자리 바꾸기·운명 찢기 포함)", ok, bad + " " + str(results))
	# D1(사람답게 — 이번 턴을 내다봄): 예전 판단은 30판 2승. 잣대가 다시 약해지지 않게
	check("자동 진행: 시험 전투 30판 중 20판 넘게 이긴다(예전 판단 2승)", int(results.get("win", 0)) >= 20, str(results))
	print("    v2 자동 진행 30판: ", results)
	return true


## D1 「사람답게」: 이번 턴을 내다보는 자동 진행이 하는 일 넷 — 수 목록(auto_plan)으로 본다
func _plan_has(plan: Array, kind: String, key: String, val) -> bool:
	for a in plan:
		if str(a.kind) == kind and str(a.get(key, "")) == str(val):
			return true
	return false


func t_auto_human() -> bool:
	# ① 자리 바꾸기로 앞 적 고르기: 세라피나 앞(칸 0)의 광신도 A 가 쓰러져 있으면 성검 베기를 칠 수 있는 칸으로 옮긴 뒤 낸다
	var st := battle(["holy"])
	var a = RulesV2.enemy(st, "A")
	a.alive = false
	a.hp = 0
	var p := RulesV2.auto_plan(st)
	check("자동 진행: 앞 적이 없으면 자리를 바꿔(에너지 1) 앞 적을 고른 뒤 공격", p.size() == 2 and str(p[0].kind) == "move" and str(p[0].ally) == "hero"
		and str(p[1].kind) == "place" and str(p[1].ally) == "hero", str(p))
	# ② 노려진 칸에 막기: 광신도 A 가 칸 2(엘리안)에 6 → 그 칸에 서는 동료에게 막기(브룬힐드를 넣고 막기 7 을 주기도 한다)
	var st2 := battle(["guard"], {"A": hit(6, "archer")})
	var p2 := RulesV2.auto_plan(st2)
	for a2 in p2:
		RulesV2._auto_apply(st2, a2)
	var in2 := RulesV2.ally_at(st2, 2)
	check("자동 진행: 노려진 칸에 선 동료에게 막기", in2 != "" and st2.allies[in2].placed.any(func(pp): return st2.cards[pp.uid].id == "guard"), str(p2))
	# ③ 겨누기 → 저격: 엘리안 앞 광신도 B(14)에게 겨누기 다음 저격(7 × 2 = 14 — 쓰러뜨림). 놓는 순서도 겨누기가 먼저
	var st3 := battle(["aim", "snipe"])
	var p3 := RulesV2.auto_plan(st3)
	check("자동 진행: 겨누기 → 저격으로 이어 간다", p3.size() == 2 and str(st3.cards[p3[0].uid].id) == "aim" and str(st3.cards[p3[1].uid].id) == "snipe"
		and str(p3[0].ally) == "archer" and str(p3[1].ally) == "archer", str(p3))
	# ④ 빈칸이 노려지면 동료를 넣어 노엘을 지킨다: 칸 1 이 비고 브룬힐드가 벤치 — 무덤지기가 칸 1 에 8
	var st4 := battle([], {"G": hit(8, 1)})
	st4.slots[1] = ""
	st4.bench = ["warrior"]
	var p4 := RulesV2.auto_plan(st4)
	check("자동 진행: 빈칸이 노려지면 벤치 동료를 넣는다(노엘 대신 맞게)", _plan_has(p4, "move", "ally", "warrior") and str(p4[0].to) == "1", str(p4))
	# 출전 배치: 무덤지기(가운데 한 칸)면 세라피나를 가운데로
	var gs := Rules.new_game(5)
	RulesV2.init_party(gs)
	var st5 := RulesV2.new_battle(null, RulesV2.battle_opts(gs, "gravekeeper"))
	var guard := 0
	while st5.phase == "formation" and guard < 6:
		guard += 1
		var f := RulesV2.auto_step(st5)
		if f.kind != "move":
			break
		RulesV2.move_ally(st5, f.ally, f.to)
	check("자동 진행 출전 배치: 앞 적이 있는 가운데 칸에 세라피나", RulesV2.ally_at(st5, 1) == "hero" and st5.bench.is_empty(), str(st5.slots))
	# 미리 보는 동안 실제 상태는 바뀌지 않는다
	var st6 := battle(["holy", "guard", "aim"], {"A": hit(6, "hero"), "B": hit(5, "archer")})
	var before := var_to_str(st6)
	RulesV2.auto_plan(st6)
	check("자동 진행: 내다보는 동안 실제 상태는 그대로", var_to_str(st6) == before)
	return true



func t_text() -> bool:
	var texts := []
	var D: Dictionary = BattleV2Data.D
	for k in D.text:
		texts.append(str(D.text[k]))
	for k in D.reasons:
		texts.append(str(D.reasons[k]))
	for k in D.cards:
		texts.append(str(D.cards[k].name))
		texts.append(str(D.cards[k].text))
	for k in D.traits:
		texts.append(str(D.traits[k].name))
		texts.append(str(D.traits[k].text))
	for k in D.enemies:
		texts.append(str(D.enemies[k].name))
		for a in D.enemies[k].acts:
			texts.append(str(D.enemies[k].acts[a].label))
	for k in D.owners:
		texts.append(str(D.owners[k]))
	var fonts := [load("res://assets/fonts/NotoSansKR-KS.ttf"), load("res://assets/fonts/NotoSerifKR-KS-Regular.ttf"), load("res://assets/fonts/NotoSerifKR-KS-Bold.ttf")]
	var missing := {}
	for s0 in texts:
		var s: String = s0
		for i in s.length():
			var ch := s.unicode_at(i)
			if ch < 32:
				continue
			for f in fonts:
				if not f.has_char(ch):
					missing[char(ch)] = true
	check("v2 문구의 모든 글자가 글꼴에 있다", missing.is_empty(), str(missing.keys()))
	var all_txt := " ".join(texts)
	check("자원 이름은 '행동 에너지' — '예지'를 쓰지 않는다", not all_txt.contains("예지") and all_txt.contains("행동 에너지"))
	return true




# ───────── v2.1 「3D 탁자」 (지시서 9-2) ─────────
func t_formation() -> bool:
	var st := RulesV2.new_battle(5)
	var r := RulesV2.move_ally(st, "archer", "bench")
	var r2 := RulesV2.move_ally(st, "hero", 2)
	check("출전 배치: 벤치로 빼기·빈칸으로 옮기기는 공짜", r.ok and r2.ok and st.slots == ["", "warrior", "hero"] and st.bench == ["archer"] and int(r.cost) == 0, str([st.slots, st.bench]))
	var r3 := RulesV2.move_ally(st, "archer", 1)
	check("출전 배치: 벤치 → 동료가 있는 칸이면 자리를 맞바꾼다", r3.ok and st.slots == ["", "archer", "hero"] and st.bench == ["warrior"], str([st.slots, st.bench]))
	var st0 := RulesV2.new_battle(5)
	for id in ["hero", "warrior", "archer"]:
		RulesV2.move_ally(st0, id, "bench")
	check("출전: 칸에 동료가 하나도 없으면 시작할 수 없다", RulesV2.start_battle(st0).reason == "noneFielded")
	var sb := RulesV2.start_battle(st)
	check("출전 → 1턴(5장·에너지 3)", sb.ok and st.phase == "battle" and st.turn == 1 and st.hand.size() == 5 and st.energy == 3)
	# 전투 중: 에너지 1
	var st2 := battle(["slash", "guard"])
	RulesV2.place(st2, uid_of(st2, "slash"), "hero")
	var m1 := RulesV2.move_ally(st2, "hero", 2)
	check("전투 중 자리 바꾸기: 에너지 1, 맡긴 카드는 동료를 따라간다", m1.ok and st2.energy == 1 and st2.slots == ["archer", "warrior", "hero"] and st2.allies.hero.placed.size() == 1, str(st2.slots))
	var m2 := RulesV2.move_ally(st2, "hero", "bench")
	check("벤치로 빼기: 에너지 1, 그 동료의 ③ 카드는 손패로(에너지 돌려받음)", m2.ok and st2.slots[2] == "" and st2.bench == ["hero"] and st2.allies.hero.placed.is_empty()
		and st2.hand.size() == 2 and st2.energy == 1, str([st2.slots, st2.energy, st2.hand.size()]))
	check("벤치의 동료에게는 맡길 수 없다", RulesV2.can_place(st2, uid_of(st2, "guard"), "hero").reason == "bench")
	check("전투 중 벤치 → 동료가 있는 칸은 안 된다(빈칸에만)", RulesV2.can_move(st2, "hero", 0).reason == "occupied")
	var m3 := RulesV2.move_ally(st2, "hero", 2)
	check("벤치 → 빈칸에 넣기: 에너지 1", m3.ok and st2.slots[2] == "hero" and st2.bench.is_empty() and st2.energy == 0)
	check("에너지가 없으면 자리를 못 바꾼다", RulesV2.can_move(st2, "warrior", 0).reason == "noEnergy")
	return true


func t_noel_hp() -> bool:
	var st := battle([], {"A": hit(6, 0), "B": {"kind": "sweep", "label": "휩쓸기", "value": 3, "minus": 0, "slot": "all"}})
	st.slots[0] = ""
	st.bench.append("hero")
	var ev := RulesV2.end_turn(st)
	check("빈칸 공격은 노엘이 맞는다(찌르기 6 + 휩쓸기 3 = 9, 막기 없음) · 다른 칸은 동료가", st.noelHp == 6 and st.allies.hero.hp == 30 and st.allies.warrior.hp == 21
		and ev_of(ev, "noelHit").size() == 2, str([st.noelHp, ev_of(ev, "noelHit")]))
	var st2 := battle([], {"A": hit(9, 1), "B": hit(9, 1)})
	st2.slots[1] = ""
	st2.bench.append("warrior")
	st2.noelHp = 12
	var ev2 := RulesV2.end_turn(st2)
	check("노엘 HP 0 → 그 자리에서 패배(「노엘이 쓰러졌다」)", st2.result == "lose" and st2.loseBy == "noel" and st2.noelHp == 0 and ev_of(ev2, "noelHit").size() == 2)
	var st3 := battle(["shift"], {"A": hit(6, 0)})
	st3.slots[2] = ""
	st3.bench.append("archer")
	check("운명 전가: 한 명 공격은 빈칸으로도 옮긴다(노엘이 대신 맞음)", RulesV2.shift_dests(st3, "A") == [1, 2])
	RulesV2.cast(st3, uid_of(st3, "shift"), "A", {"to": 2})
	RulesV2.end_turn(st3)
	check("빈칸으로 옮긴 찌르기 6 은 노엘이", st3.noelHp == 9 and st3.allies.hero.hp == 30)
	var st4 := battle([], {"A": hit(6, 0)})
	st4.allies.hero.hp = 0
	st4.allies.hero.down = true
	RulesV2.end_turn(st4)
	check("쓰러진 동료의 칸을 노린 공격도 노엘이", st4.noelHp == 9)
	return true


## 3턴(무덤지기 3번째 행동)까지 진행한 전투 — 죽음 카드가 ② 에. 1·2턴 적 공격은 0 으로
func death_battle(seed := 7) -> Dictionary:
	var st := RulesV2.new_battle(seed)
	for i in 3:
		RulesV2.start_turn(st)
		if i < 2:
			_zero_hits(st)
			RulesV2.end_turn(st)
	return st


func _zero_hits(st: Dictionary) -> void:
	for e in st.enemies:
		if e.intent != null and e.intent.kind in ["hit", "sweep"]:
			e.intent.value = 0


func _give(st: Dictionary, ids: Array) -> Array:
	var out := []
	for id in ids:
		var u := "x" + str(st.nextUid)
		st.nextUid = int(st.nextUid) + 1
		st.cards[u] = {"uid": u, "id": id}
		out.append(u)
	return out


func t_death() -> bool:
	var st := death_battle()
	var dd: Dictionary = st.deaths[0] if not st.deaths.is_empty() else {}
	check("죽음 카드: 3턴에 「세라피나의 죽음」(세라피나를 노림, 무덤지기가 낸 것)", not dd.is_empty() and dd.ally == "hero" and dd.src == "G" and dd.bound, str(st.deaths))
	st.hand.append_array(_give(st, ["curse", "guard", "guard"]))
	st.energy = 3
	check("저주로 줄일 수 없다", RulesV2.can_cast(st, uid_of(st, "curse"), dd.id).reason == "death")
	RulesV2.place(st, uid_of(st, "guard"), "hero")
	RulesV2.place(st, uid_of(st, "guard"), "hero")
	_zero_hits(st)
	var ev := RulesV2.end_turn(st)
	var a: Dictionary = st.allies.hero
	check("막기로 막을 수 없다: 적 턴에 세라피나는 죽는다(이 전투에서 돌아오지 않음)", a.dead and a.down and a.hp == 0 and ev_of(ev, "death").size() == 1 and st.deaths.is_empty(), str(a))
	RulesV2.start_turn(st)
	st.slots[0] = ""
	st.bench.append("hero")
	check("죽은 동료는 다시 칸에 설 수 없다", RulesV2.can_move(st, "hero", 0).reason == "deadAlly")
	return true


func t_death_escape() -> bool:
	# ① 무덤지기를 먼저 쓰러뜨림
	var st := death_battle()
	st.hand.append_array(_give(st, ["snipe"]))
	st.energy = 3
	RulesV2.enemy(st, "G").hp = 5
	st.slots = ["hero", "archer", "warrior"]   # 9-6: 무덤지기는 칸 1 의 앞 적
	RulesV2.place(st, uid_of(st, "snipe"), "archer")
	_zero_hits(st)
	var ev := RulesV2.end_turn(st)
	check("막는 법 ①: 무덤지기를 먼저 쓰러뜨리면 죽음 카드도 사라진다", not RulesV2.enemy(st, "G").alive and st.deaths.is_empty() and not st.allies.hero.dead
		and ev_of(ev, "deathGone").size() == 1)
	# ② 운명 전가: 동료가 있는 다른 칸으로(그 동료가 대신 죽음, 빈칸으로는 못 옮김)
	var st2 := death_battle()
	var did: String = st2.deaths[0].id
	st2.hand.append_array(_give(st2, ["shift"]))
	st2.energy = 3
	st2.slots[2] = ""
	st2.bench.append("archer")
	check("막는 법 ②: 운명 전가는 동료가 있는 다른 칸으로만(빈칸 안 됨)", RulesV2.shift_dests(st2, did) == [1], str(RulesV2.shift_dests(st2, did)))
	var cr := RulesV2.cast(st2, uid_of(st2, "shift"), did, {"to": 1})
	check("죽음 카드가 브룬힐드에게로(「브룬힐드의 죽음」)", cr.ok and st2.deaths[0].ally == "warrior" and str(st2.deaths[0].label) == "브룬힐드의 죽음")
	RulesV2.uncast(st2, 0)
	check("운명 전가를 되돌리면 다시 세라피나", st2.deaths[0].ally == "hero" and st2.energy == 3)
	RulesV2.cast(st2, uid_of(st2, "shift"), did, {"to": 1})
	_zero_hits(st2)
	RulesV2.end_turn(st2)
	check("옮긴 죽음: 브룬힐드가 대신 죽고 세라피나는 산다", st2.allies.warrior.dead and not st2.allies.hero.dead)
	# ③ 운명 찢기(에너지 3)
	var st3 := death_battle()
	var did3: String = st3.deaths[0].id
	st3.hand.append_array(_give(st3, ["tear"]))
	st3.energy = 2
	check("운명 찢기는 에너지 3", RulesV2.can_cast(st3, uid_of(st3, "tear"), did3).reason == "noEnergy")
	st3.energy = 3
	check("운명 찢기는 죽음 카드에만", RulesV2.can_cast(st3, uid_of(st3, "tear"), "A").reason == "notDeath")
	RulesV2.cast(st3, uid_of(st3, "tear"), did3)
	check("막는 법 ③: 운명 찢기로 죽음 카드를 없앤다", st3.deaths.is_empty() and st3.energy == 0)
	RulesV2.uncast(st3, 0)
	check("운명 찢기를 되돌리면 죽음 카드가 돌아온다", st3.deaths.size() == 1 and st3.energy == 3)
	RulesV2.cast(st3, uid_of(st3, "tear"), did3)
	_zero_hits(st3)
	RulesV2.end_turn(st3)
	check("찢은 뒤 적 턴: 세라피나는 살아 있다", not st3.allies.hero.dead)
	return true


func t_death_bench() -> bool:
	var st := death_battle()
	st.energy = 3
	var m := RulesV2.move_ally(st, "hero", "bench")
	_zero_hits(st)
	var ev := RulesV2.end_turn(st)
	check("죽음 카드는 그 동료를 따라간다: 벤치에 있으면 처리되지 않고 기다린다", m.ok and not st.allies.hero.dead and st.deaths.size() == 1 and not st.deaths[0].bound
		and ev_of(ev, "deathWait").size() == 1)
	RulesV2.start_turn(st)
	var snipe := _give(st, ["snipe"])
	st.hand.append_array(snipe)
	RulesV2.enemy(st, "G").hp = 3
	st.slots = ["", "archer", "warrior"]   # 9-6: 무덤지기는 칸 1 의 앞 적
	RulesV2.place(st, snipe[0], "archer")
	_zero_hits(st)
	RulesV2.end_turn(st)
	check("한 번 기다린 죽음 카드는 무덤지기가 쓰러져도 남는다", not RulesV2.enemy(st, "G").alive and st.deaths.size() == 1)
	RulesV2.start_turn(st)
	RulesV2.move_ally(st, "hero", 0)
	check("벤치에서 다시 칸에 서면 죽음 카드가 그 칸 ② 로 따라온다", RulesV2.col_of(st, "hero") == 0 and RulesV2.is_targeted(st, "hero"))
	RulesV2.move_ally(st, "hero", "bench")
	st.result = "win"
	check("전투가 끝날 때까지 남으면 「운명이 미뤄졌다」", RulesV2.postponed(st) == ["세라피나의 죽음"], str(RulesV2.postponed(st)))
	return true


# ───────── 게임 연결: 1층 전투 (밤샘 계획 2 A·B) ─────────
## 게임 상태(Rules) + 이 전투의 덱 → 그 전투(enc)를 연다
func game_battle(enc: String, gs := {}, rng := 7) -> Dictionary:
	if gs.is_empty():
		gs = Rules.new_game(rng)
		RulesV2.init_party(gs)
	return RulesV2.new_battle(null, RulesV2.battle_opts(gs, enc))


## 자동 진행으로 끝까지(규칙만). 반환: 끝난 상태
func auto_run(st: Dictionary) -> Dictionary:
	if st.phase == "formation":
		RulesV2.start_battle(st)
	var steps := 0
	while st.result == null and st.turn < 40 and steps < 3000:
		steps += 1
		var a := RulesV2.auto_step(st)
		var r := {"ok": true}
		match str(a.kind):
			"place":
				r = RulesV2.place(st, a.uid, a.ally, a.opts)
			"cast":
				r = RulesV2.cast(st, a.uid, a.target, a.opts)
			"move":
				r = RulesV2.move_ally(st, a.ally, a.to)
			_:
				RulesV2.end_turn(st)
				# 2·3층 운명의 시도: 시험에서는 fate_choice 메타 키(없으면 거스름)로 고른다
				var picks: Array = st.get("autoPicks", [])
				while st.get("awaitFate") != null:
					RulesV2.fate_choice(st, str(picks.pop_front()) if not picks.is_empty() else "defy")
				if st.result == null:
					RulesV2.start_turn(st)
		if not r.ok:
			st.bad = str(a) + " " + str(r)
			break
	return st


func t_game_setup() -> bool:
	var gs := Rules.new_game(3)
	RulesV2.init_party(gs)
	var ids: Array = gs.party.deck2.map(func(s): return str(s.id))
	check("게임 덱(deck2): 시험판 덱에서 운명 찢기를 뺀 14장", ids.size() == 14 and not ids.has("tear") and ids.count("holy") == 2, str(ids))
	gs.party.allies.archer.hp = 5
	gs.party.witch.hp = 11
	var st := RulesV2.new_battle(null, RulesV2.battle_opts(gs, "normal"))
	var cul: Array = st.enemies.filter(func(e): return e.type == "cultist")
	check("장례 회랑: 광신도 셋(칸 0·1·2, HP 14)", cul.size() == 3 and cul.map(func(e): return int(e.col)) == [0, 1, 2] and cul.all(func(e): return int(e.hp) == 14))
	check("동료 HP·노엘 HP 가 게임 상태에서 이어진다", int(st.allies.archer.hp) == 5 and int(st.allies.archer.maxHp) == 12 and int(st.noelHp) == 11 and st.draw.size() == 14)
	gs.party.allies.hero.status = "dead"
	gs.party.allies.hero.hp = 0
	gs.party.formation2 = ["archer", "", "hero"]
	var st2 := RulesV2.new_battle(null, RulesV2.battle_opts(gs, "prayer"))
	check("직전 출전 배치가 기본값 · 죽은 동료는 칸에 서지 못한다(벤치)", st2.slots == ["archer", "", ""] and st2.bench.has("hero") and st2.bench.has("warrior")
		and st2.allies.hero.dead, str(st2.slots) + str(st2.bench))
	check("죽은 동료는 벤치에서 다시 넣을 수 없다", RulesV2.can_move(st2, "hero", 1).reason == "deadAlly")
	return true


func t_game_tutorial() -> bool:
	var hands := []
	for rng in [7, 99]:
		var st := game_battle("normal", {}, rng)
		RulesV2.start_battle(st)
		var h1: Array = st.hand.map(func(u): return str(st.cards[u].id))
		var it1 := {}
		for e in st.enemies:
			it1[e.id] = [int(e.intent.slot), int(e.intent.value)]
		_zero_hits(st)
		RulesV2.end_turn(st)
		RulesV2.start_turn(st)
		var h2: Array = st.hand.map(func(u): return str(st.cards[u].id))
		var it2: Array = st.enemies.map(func(e): return [int(e.intent.slot), int(e.intent.value)])
		hands.append([h1, it1, h2, it2])
	var a: Array = hands[0]
	check("튜토리얼 1턴 손패: 성검 베기·막기·베기·겨누기·저격", a[0] == ["holy", "guard", "slash", "aim", "snipe"], str(a[0]))
	check("튜토리얼 1턴 적 행동: 광신도 A→칸1 5 · B→칸0 6 · C→칸2 5", a[1] == {"c1": [1, 5], "c2": [0, 6], "c3": [2, 5]}, str(a[1]))
	check("튜토리얼 2턴: 셋 다 엘리안 칸(2)에 6 · 손패 운명 전가·막기·성검 베기·베기·축복", a[3] == [[2, 6], [2, 6], [2, 6]] and a[2] == ["shift", "guard", "holy", "slash", "bless"], str(a[2]) + str(a[3]))
	check("튜토리얼은 난수가 달라도 매번 같은 흐름(1·2턴)", hands[0] == hands[1])
	return true


func t_game_cards() -> bool:
	check("Lv2: 성검 베기 Lv2 피해 11 · 저주 Lv2 -5", int(RulesV2.def_of("holy", 2).damage) == 11 and str(RulesV2.def_of("holy", 2).name) == "성검 베기 Lv2"
		and int(RulesV2.def_of("curse", 2).minus) == 5 and int(RulesV2.def_of("holy", 1).damage) == 8)
	var st := battle(["wound", "relic_sword", "trample", "nameless", "charm"], {"A": hit(5, 0), "B": hit(6, 2)})
	var u := uid_of(st, "wound")
	check("상처: 낼 수 없다(손패만 차지)", not RulesV2.affordable(st, u) and RulesV2.can_place(st, u, "hero").reason == "unplayable")
	st.energy = 10
	st.allies.hero.hp = 20
	var r1 := RulesV2.place(st, uid_of(st, "relic_sword"), "hero")
	var r2 := RulesV2.cast(st, uid_of(st, "trample"), "A")
	var nu := uid_of(st, "nameless")
	var r3 := RulesV2.cast(st, nu, "B")
	var r4 := RulesV2.cast(st, uid_of(st, "charm"), "hero")
	check("유품·짓밟힘·이름 없는 마녀의 카드·부적을 놓을 수 있다", r1.ok and r2.ok and r3.ok and r4.ok, str([r1, r2, r3, r4]))
	check("이름 없는 마녀의 카드: 그 행동의 피해가 0(없앰)", RulesV2.act_value(RulesV2.enemy(st, "B").intent) == 0)
	var ev := RulesV2.end_turn(st)
	var hp_a := 14 - 9 - 12
	check("턴 끝: 짓밟힘 모든 적 9 → 성검 유품 12(앞 적) · 노엘 HP -3(이름 없는) -2(유품)", int(RulesV2.enemy(st, "B").hp) == 5 and not RulesV2.enemy(st, "A").alive
		and int(st.noelHp) == 15 - 3 - 2, "A hp %d B hp %d noel %d (%d)" % [int(RulesV2.enemy(st, "A").hp), int(RulesV2.enemy(st, "B").hp), int(st.noelHp), hp_a])
	check("부적: 세라피나 HP +4", int(st.allies.hero.hp) == 24 and ev_of(ev, "heal").size() == 1)
	check("없앤 행동은 일어나지 않는다 · 이름 없는 마녀의 카드는 이 전투에서 사라진다(전투마다 한 번)", ev_of(ev, "noelHit").is_empty() and st.exhaust.has(nu) and not st.discard.has(nu))
	var d := RulesV2.def_from_v1("cover", true)
	check("옛 카드 → 짝 카드: 감싸기 Lv2 → 막기 Lv2(막기 7)", str(d.get("id", "")) == "guard" and int(d.block) == 7 and RulesV2.def_from_v1("hero_death").is_empty())
	return true


func t_game_gravekeeper() -> bool:
	var st := game_battle("gravekeeper")
	RulesV2.start_battle(st)
	var g = RulesV2.enemy(st, "G")
	check("무덤지기: HP 40(D2 — 옛 34) · 1턴은 해골 병사 부르기", int(g.hp) == 40 and g.intent.kind == "summon")
	_zero_hits(st)
	RulesV2.end_turn(st)
	RulesV2.start_turn(st)
	var s = RulesV2.enemy(st, "S")
	check("2턴: 해골 병사(HP 10 · 녹슨 칼 5 — D2)가 무덤지기 앞에(같은 칸) · 무덤지기는 「관 뚜껑 내려치기」 8", s.alive and int(s.col) == 1 and int(s.hp) == 10
		and s.intent != null and int(s.intent.value) == 5 and g.intent.kind == "hit" and int(g.intent.value) == 8)
	_zero_hits(st)
	RulesV2.end_turn(st)
	RulesV2.start_turn(st)
	var hc := RulesV2._highest_col(st)
	check("3턴: 「짓누르기」 12(D2 — 옛 10) → HP 가 가장 많은 동료의 칸", int(g.intent.value) == 12 and int(g.intent.slot) == hc, "%s → %d" % [str(g.intent), hc])
	return true


func t_game_deep_giant() -> bool:
	var st := game_battle("deep")
	RulesV2.start_battle(st)
	check("가장 깊은 곳 1턴: 광신도 A → 칸2 6 · B → 칸1 5", int(RulesV2.enemy(st, "c1").intent.slot) == 2 and int(RulesV2.enemy(st, "c3").intent.slot) == 1)
	RulesV2.enemy(st, "c1").hp = 2
	st.hand.append_array(_give(st, ["slash"]))
	RulesV2.place(st, uid_of(st, "slash"), "hero")
	var ev := RulesV2.end_turn(st)
	check("광신도가 하나 남으면 발이 내려와 남은 광신도를 짓밟는다 → 거대한 발 전투로(giant)", st.result == "giant" and st.victims == ["c3"] and not RulesV2.enemy(st, "c3").alive
		and ev_of(ev, "giant").size() == 1 and ev_of(ev, "enemyPhase").is_empty(), str(st.result) + str(st.victims))
	var gs := Rules.new_game(5)
	RulesV2.init_party(gs)
	var g := game_battle("giant", gs)
	RulesV2.start_battle(g)
	var ft = RulesV2.enemy(g, "giant")
	check("거대한 발: 세 칸을 덮는 큰 적(모든 칸의 앞 적) · 1턴 「그림자」(행동 없음)", RulesV2.front(g, 0) == ft and RulesV2.front(g, 2) == ft and ft.intent.kind == "none" and RulesV2.incoming(g, 1) == 0)
	g.hand.append_array(_give(g, ["holy"]))
	RulesV2.place(g, uid_of(g, "holy"), "hero")
	var ev1 := RulesV2.end_turn(g)
	check("거대한 발은 흠집만(HP 그대로, immune)", ev_of(ev1, "immune").size() == 1 and ft.alive and g.result == null)
	RulesV2.start_turn(g)
	check("2턴: 「기둥 붕괴」 모두 5", ft.intent.kind == "sweep" and int(ft.intent.value) == 5)
	for id in g.order:
		g.allies[id].hp = 1
	RulesV2.end_turn(g)
	check("지지 않는다(noLose): 동료가 모두 쓰러져도 전투가 이어진다", g.result == null and not RulesV2.any_living(g))
	RulesV2.start_turn(g)
	var dd: Dictionary = g.deaths[0] if not g.deaths.is_empty() else {}
	check("3턴: 「세라피나의 죽음」(옮길 수 없음·찢을 수 없음 — fixed)", dd.get("ally", "") == "hero" and bool(dd.get("fixed", false)) and RulesV2.shift_dests(g, dd.id).is_empty())
	g.hand.append_array(_give(g, ["shift", "tear"]))
	g.energy = 10
	check("운명 전가·운명 찢기를 놓을 수 없다(「이 죽음은 옮길 수도 찢을 수도 없다」)", RulesV2.can_cast(g, uid_of(g, "shift"), dd.id).reason == "fixed"
		and RulesV2.can_cast(g, uid_of(g, "tear"), dd.id).reason == "fixed")
	g.allies.hero.down = false
	g.allies.hero.hp = 5
	RulesV2.move_ally(g, "hero", "bench")
	var ev3 := RulesV2.end_turn(g)
	check("세라피나가 벤치에 있어도 따라가 맞는다 → 죽음 → 물러남(retreat)", g.allies.hero.dead and g.result == "retreat" and ev_of(ev3, "death").size() == 1
		and bool(ev_of(ev3, "death")[0].get("fixed", false)), str(g.result))
	return true


func t_game_darkness() -> bool:
	var gs := Rules.new_game(11)
	RulesV2.init_party(gs)
	var o := RulesV2.battle_opts(gs, "prayer", 1)
	var st := RulesV2.new_battle(null, o)
	RulesV2.start_battle(st)
	var hid: Array = st.enemies.filter(func(e): return e.intent != null and bool(e.intent.get("hidden", false)))
	check("어둠 1단계: 적 행동 카드 1장이 뒷면(규칙은 그대로)", hid.size() == 1)
	var st2 := RulesV2.new_battle(null, RulesV2.battle_opts(gs, "prayer", 5))
	RulesV2.start_battle(st2)
	check("어둠이 깊어도 뒷면은 있는 행동 수까지", st2.enemies.filter(func(e): return e.intent != null and bool(e.intent.get("hidden", false))).size() == 2)
	return true


func t_game_apply() -> bool:
	var gs := Rules.new_game(21)
	RulesV2.init_party(gs)
	var st := game_battle("normal", gs)
	RulesV2.start_battle(st)
	st.allies.archer.hp = 0
	st.allies.archer.down = true
	st.allies.hero.hp = 17
	st.slots = ["warrior", "hero", "archer"]
	st.noelHp = 9
	st.result = "win"
	var ev := RulesV2.apply_result(gs, st)
	var arch: Array = gs.party.deck2.filter(func(s): return str(BattleV2Data.D.cards[str(s.id)].owner) == "archer")
	check("전투 뒤: HP·노엘 HP·출전 배치가 게임 상태로(난수도 이어 감)", int(gs.party.allies.hero.hp) == 17 and int(gs.party.witch.hp) == 9 and gs.party.formation2 == ["warrior", "hero", "archer"]
		and int(gs.rng) != 0)
	check("쓰러진 동료: HP 1 로 일어나고 그 동료 카드 1장이 「상처」(새 덱·옛 덱 둘 다)", int(gs.party.allies.archer.hp) == 1 and gs.party.allies.archer.status == "ok"
		and arch.size() == 2 and gs.party.deck2.filter(func(s): return s.id == "wound").size() == 1 and ev_of(ev, "wound").size() == 1 and ev_of(ev, "wound2").size() == 1)
	var g := game_battle("giant", gs)
	g.allies.hero.dead = true
	g.allies.hero.down = true
	g.allies.hero.hp = 0
	g.result = "retreat"
	RulesV2.apply_result(gs, g)
	var ids: Array = gs.party.deck2.map(func(s): return str(s.id))
	check("세라피나의 죽음: 운명 받아들임(사망·운명 기록) · 성검 베기 → 유품 「부러진 성검」 · 「짓밟힘」이 새 덱에", gs.party.allies.hero.status == "dead"
		and not ids.has("holy") and ids.count("relic_sword") == 2 and ids.has("trample") and gs.fateLog.size() == 1
		and gs.party.deck.any(func(u): return gs.cards[u].id == "broken_sword"), str(ids))
	var gs2 := Rules.new_game(4)
	RulesV2.init_party(gs2)
	MapRules.gain_card(gs2, "nameless_card")
	MapRules.gain_card(gs2, "snipe", true)
	MapRules.upgrade_card(gs2, "holy_slash")
	var d2: Array = gs2.party.deck2
	check("방에서 얻은 카드·강화가 새 덱에도(이름 없는 마녀의 카드 · 저격 Lv2 · 성검 베기 Lv2)", d2.any(func(s): return s.id == "nameless")
		and d2.any(func(s): return s.id == "snipe" and int(s.lv) == 2) and d2.any(func(s): return s.id == "holy" and int(s.lv) == 2))
	var sv := SaveGame.unpack(SaveGame.pack(gs2, "map", "stall"))
	check("저장·이어하기: 새 덱이 그대로", not sv.is_empty() and sv.st.party.deck2 == gs2.party.deck2)
	var bad: Dictionary = gs2.duplicate(true)
	bad.party.deck2.append({"id": "없는카드", "lv": 1})
	check("새 덱에 없는 카드가 있으면 저장 없음", SaveGame.unpack(SaveGame.pack(bad, "map", "stall")).is_empty())
	return true


func t_game_auto() -> bool:
	var res := {}
	var bad := ""
	for enc in ["normal", "prayer", "gravekeeper", "deep", "giant"]:
		var n := {}
		for sd in range(1, 13):
			var st := auto_run(game_battle(enc, {}, sd))
			if st.has("bad") or st.result == null:
				bad += "%s %d: %s %s; " % [enc, sd, str(st.get("bad", "")), str(st.result)]
			n[str(st.result)] = int(n.get(str(st.result), 0)) + 1
		res[enc] = n
	check("1층 전투 다섯 곳: 자동 진행이 시드 1~12 모두 결과까지(거대한 발은 늘 물러남)", bad == "" and res.giant.get("retreat", 0) == 12, bad + str(res))
	print("    1층 자동 진행(12판씩, 새 파티): ", res)
	return true


# ───────── 2·3층 운명 (밤샘 계획 2 C) ─────────
## 2층 상태(1층을 끝냄 — 세라피나 사망, 브룬힐드 관통 Lv1)의 게임 상태
func fate_gs(sd := 7, brun := "") -> Dictionary:
	var gs := Rules.state_after_tutorial(sd) if brun == "" else Rules.state_floor3(sd, brun)
	RulesV2.init_party(gs)
	return gs


## 그 전투를 열고 n 턴째 내 턴까지(앞 턴들의 적 공격은 0, 운명의 시도는 거스름)
func fate_battle(enc: String, gs: Dictionary, turns: int) -> Dictionary:
	var st := RulesV2.new_battle(null, RulesV2.battle_opts(gs, enc))
	RulesV2.start_battle(st)
	for i in turns - 1:
		_zero_hits(st)
		RulesV2.end_turn(st)
		while st.awaitFate != null:
			RulesV2.fate_choice(st, "defy")
		RulesV2.start_turn(st)
	return st


func t_fate_setup() -> bool:
	var gs := fate_gs()
	var ids: Array = gs.party.deck2.map(func(x): return str(x.id))
	check("2층 바로 가기: 새 덱에도 지난 운명 — 성검 베기 → 유품 「부러진 성검」 2장 · 「짓밟힘」", not ids.has("holy") and ids.count("relic_sword") == 2 and ids.has("trample"), str(ids))
	var o := RulesV2.battle_opts(gs, "ossuary")
	check("전투에 넘기는 운명: 브룬힐드 관통 Lv1(흉터 1) — 세라피나(거스를 수 없음)는 빠짐", o.fates.size() == 1 and str(o.fates[0].id) == "warrior_pierce" and int(o.fates[0].level) == 1
		and int(o.fates[0].scars) == 1, str(o.fates))
	var st := RulesV2.new_battle(null, o)
	var k = RulesV2.enemy(st, "k1")
	check("기사단 납골당: 광신도(칸 0) + 창 기사(칸 1, HP 36) · 세라피나는 죽어 벤치", k != null and int(k.hp) == 36 and int(k.col) == 1 and int(RulesV2.enemy(st, "c1").col) == 0
		and st.allies.hero.dead and not st.slots.has("hero"))
	var gs3 := fate_gs(7, "alive")
	var o3 := RulesV2.battle_opts(gs3, "pyre")
	var lv := {}
	for f in o3.fates:
		lv[str(f.id)] = int(f.level)
	check("3층(브룬힐드가 살아 있음): 엘리안 화형 Lv1 · 브룬힐드 Lv2 두 운명 · 새 덱에 흉터 1(2층에서 거스름)", lv == {"warrior_pierce": 2, "archer_burn": 1}
		and gs3.party.deck2.filter(func(x): return x.id == "scar").size() == 1, str(lv))
	var gs3d := fate_gs(7, "dead")
	var ids3: Array = gs3d.party.deck2.map(func(x): return str(x.id))
	check("3층(2층에서 받아들임): 「꿰뚫린 방패」·「브룬힐드의 마지막 강타」(되돌리기 → 유품) · 운명은 엘리안만", ids3.has("pierced_shield") and ids3.has("relic_bash") and not ids3.has("revert")
		and RulesV2.battle_opts(gs3d, "pyre").fates.size() == 1, str(ids3))
	return true


func t_fate_trial_defy() -> bool:
	var gs := fate_gs()
	var st := fate_battle("ossuary", gs, 2)
	var dd: Dictionary = st.deaths[0] if not st.deaths.is_empty() else {}
	check("2턴: 창 기사가 「브룬힐드의 죽음」(운명의 관통)을 브룬힐드 칸 ② 에", str(dd.get("fate", "")) == "warrior_pierce" and str(dd.get("ally", "")) == "warrior"
		and str(dd.get("src", "")) == "k1" and str(dd.get("sub", "")) == "운명의 관통" and RulesV2.enemy(st, "k1").intent.kind == "death", str(st.deaths))
	st.hand.append_array(_give(st, ["shift", "curse", "guard"]))
	st.energy = 3
	check("운명의 죽음은 옮길 수 없다 · 저주로 줄지 않는다", RulesV2.can_cast(st, uid_of(st, "shift"), dd.id).reason == "fateFixed"
		and RulesV2.can_cast(st, uid_of(st, "curse"), dd.id).reason == "death" and RulesV2.shift_dests(st, dd.id).is_empty())
	RulesV2.place(st, uid_of(st, "guard"), "warrior")
	_zero_hits(st)
	var ev := RulesV2.end_turn(st)
	check("적 턴 끝에 닿으면 운명의 시도(멈춤 — 정리 전) · 그사이 다음 턴은 시작되지 않는다", st.awaitFate != null and ev_of(ev, "fateTrial").size() == 1 and ev_of(ev, "cleanup").is_empty()
		and RulesV2.start_turn(st).is_empty() and RulesV2.end_turn(st).is_empty())
	var nd: int = st.draw.size()
	var ev2 := RulesV2.fate_choice(st, "defy")
	var fd := ev_of(ev2, "fateDefied")
	check("거스른다: 브룬힐드는 살고 흉터 1장이 뽑을 더미에 · 이어서 정리", not st.allies.warrior.dead and fd.size() == 1 and fd[0].scars.size() == 1 and st.draw.size() == nd + 1
		and st.cards[fd[0].scars[0]].id == "scar" and ev_of(ev2, "cleanup").size() == 1 and st.deaths.is_empty() and st.awaitFate == null)
	st.result = "win"
	RulesV2.apply_result(gs, st)
	var f = Rules.fate_by_id(gs, "warrior_pierce")
	check("게임 상태: 운명은 살아 있고(다음 층으로) 이 층에서 시도함 · 흉터가 옛 덱·새 덱 모두에", f.alive and int(f.triedFloor) == 2 and Rules.scar_count(gs) == 1
		and gs.party.deck2.filter(func(x): return x.id == "scar").size() == 1 and gs.fateLog.back().result == "defied")
	check("다시 열면 이 층에서는 운명이 오지 않는다", RulesV2.battle_opts(gs, "ossuary").fates.is_empty())
	return true


func t_fate_trial_accept() -> bool:
	var gs := fate_gs()
	var st := fate_battle("ossuary", gs, 2)
	_zero_hits(st)
	RulesV2.end_turn(st)
	var ev := RulesV2.fate_choice(st, "accept")
	var de := ev_of(ev, "death")
	var fg := ev_of(ev, "fateGain")
	check("받아들인다: 브룬힐드가 죽는다(죽음 연출 · 운명 Lv)", st.allies.warrior.dead and de.size() == 1 and str(de[0].get("fate", "")) == "warrior_pierce" and int(de[0].level) == 1)
	var top: String = st.draw[0] if not st.draw.is_empty() else ""
	check("상속 「꿰뚫린 방패」가 뽑을 더미 맨 위(다음 턴에 손에) · 되돌리기 → 유품 「브룬힐드의 마지막 강타」", fg.size() == 1 and top != "" and st.cards[top].id == "pierced_shield"
		and st.cards.values().all(func(c): return c.id != "revert") and st.cards.values().any(func(c): return c.id == "relic_bash"))
	RulesV2.start_turn(st)
	check("다음 턴 손패에 꿰뚫린 방패", st.hand.any(func(u): return st.cards[u].id == "pierced_shield"))
	st.result = "win"
	RulesV2.apply_result(gs, st)
	var ids: Array = gs.party.deck2.map(func(x): return str(x.id))
	var f = Rules.fate_by_id(gs, "warrior_pierce")
	check("게임 상태: 브룬힐드 사망 · 운명 받아들임(Lv1) · 새 덱에 꿰뚫린 방패·유품 · 옛 덱에 꿰뚫린 방패", gs.party.allies.warrior.status == "dead" and not f.alive and f.result == "offered"
		and ids.has("pierced_shield") and ids.has("relic_bash") and not ids.has("revert") and gs.party.deck.any(func(u): return gs.cards[u].id == "pierced_shield"), str(ids))
	return true


func t_fate_executor() -> bool:
	var gs := fate_gs()
	var st := RulesV2.new_battle(null, RulesV2.battle_opts(gs, "ossuary"))
	RulesV2.start_battle(st)
	RulesV2.enemy(st, "k1").hp = 3
	st.slots = ["warrior", "archer", ""]
	st.bench = ["hero"]
	st.hand.append_array(_give(st, ["slash"]))
	st.energy = 3
	RulesV2.place(st, uid_of(st, "slash"), "archer")
	_zero_hits(st)
	var ev := RulesV2.end_turn(st)
	var rl := ev_of(ev, "fateRelease")
	check("1턴에 창 기사를 먼저 쓰러뜨려도 운명은 그 순간 나온다(fate-design 4장) → 이번 적 턴 끝에 운명의 시도", not RulesV2.enemy(st, "k1").alive and rl.size() == 1
		and st.deaths.size() == 1 and not st.deaths[0].bound and st.awaitFate != null and ev_of(ev, "deathGone").is_empty(), str(st.deaths))
	RulesV2.fate_choice(st, "defy")
	# 이겨도 운명은 온다
	var gs2 := fate_gs(9)
	var st2 := RulesV2.new_battle(null, RulesV2.battle_opts(gs2, "ossuary"))
	RulesV2.start_battle(st2)
	RulesV2.enemy(st2, "k1").hp = 3
	RulesV2.enemy(st2, "c1").hp = 3
	st2.slots = ["warrior", "archer", ""]
	st2.bench = ["hero"]
	var two := _give(st2, ["slash", "slash"])
	st2.hand.append_array(two)
	st2.energy = 3
	RulesV2.place(st2, two[0], "archer")
	RulesV2.place(st2, two[1], "warrior")
	var ev2 := RulesV2.end_turn(st2)
	check("마지막 적(집행자)을 쓰러뜨려 이겨도 운명의 시도가 먼저(승리는 그 뒤)", st2.result == "win" and st2.awaitFate != null and ev_of(ev2, "enemyPhase").is_empty() and ev_of(ev2, "cleanup").is_empty(),
		"%s %s %s %s" % [str(st2.result), str(st2.awaitFate), str(st2.deaths), str(ev2.map(func(x): return x.t))])
	var ev3 := RulesV2.fate_choice(st2, "accept")
	check("받아들인 뒤 정리 · 결과는 승리 그대로", st2.result == "win" and st2.allies.warrior.dead and ev_of(ev3, "cleanup").size() == 1)
	return true


func t_fate_bench() -> bool:
	var gs := fate_gs()
	var st := fate_battle("ossuary", gs, 2)
	st.energy = 3
	RulesV2.move_ally(st, "warrior", "bench")
	_zero_hits(st)
	var ev := RulesV2.end_turn(st)
	check("벤치의 동료: 운명의 죽음 카드는 따라가 기다린다(시도 없음)", st.awaitFate == null and ev_of(ev, "deathWait").size() == 1 and st.deaths.size() == 1 and ev_of(ev, "cleanup").size() == 1)
	st.result = "win"
	check("끝날 때까지 벤치면 「운명이 미뤄졌다」", RulesV2.postponed(st) == ["브룬힐드의 죽음"], str(RulesV2.postponed(st)))
	RulesV2.apply_result(gs, st)
	var f = Rules.fate_by_id(gs, "warrior_pierce")
	check("게임 상태: 운명은 시도되지 않은 채 살아 있다(흉터 없음 — 내려가면 Lv2)", f.alive and int(f.get("triedFloor", 0)) != 2 and Rules.scar_count(gs) == 0)
	return true


func t_fate_pyre_two() -> bool:
	var gs := fate_gs(7, "alive")
	var st := RulesV2.new_battle(null, RulesV2.battle_opts(gs, "pyre"))
	RulesV2.start_battle(st)
	var p = RulesV2.enemy(st, "p1")
	check("화형대 광장: 화형 사제(칸 1, HP 46) 1턴 「불길」 모든 칸 3 + 광신도(칸 2)", int(p.hp) == 46 and int(p.col) == 1 and p.intent.kind == "sweep" and int(p.intent.value) == 3
		and int(RulesV2.enemy(st, "c1").col) == 2)
	_zero_hits(st)
	RulesV2.end_turn(st)
	RulesV2.start_turn(st)
	check("2턴: 「엘리안의 죽음」(운명의 불길)", st.deaths.size() == 1 and st.deaths[0].fate == "archer_burn" and st.deaths[0].label == "엘리안의 죽음")
	_zero_hits(st)
	RulesV2.end_turn(st)
	RulesV2.fate_choice(st, "defy")
	RulesV2.start_turn(st)
	check("3턴: 「브룬힐드의 죽음 Lv2」(운명의 꼬챙이)", st.deaths.size() == 1 and st.deaths[0].fate == "warrior_pierce" and st.deaths[0].label == "브룬힐드의 죽음 Lv2"
		and int(st.deaths[0].level) == 2 and st.deaths[0].sub == "운명의 꼬챙이")
	# 1턴에 사제를 쓰러뜨리면 두 운명이 한꺼번에(엘리안 → 브룬힐드 차례)
	var gs2 := fate_gs(8, "alive")
	var s2 := RulesV2.new_battle(null, RulesV2.battle_opts(gs2, "pyre"))
	RulesV2.start_battle(s2)
	RulesV2.enemy(s2, "p1").hp = 2
	s2.slots = ["", "warrior", "archer"]
	s2.bench = ["hero"]
	s2.hand.append_array(_give(s2, ["slash"]))
	s2.energy = 3
	RulesV2.place(s2, uid_of(s2, "slash"), "warrior")
	_zero_hits(s2)
	var ev := RulesV2.end_turn(s2)
	var rl := ev_of(ev, "fateRelease")
	check("사제를 먼저 쓰러뜨리면 남은 두 운명이 그 순간 나온다", rl.size() == 1 and rl[0].ids.size() == 2 and s2.deaths.size() == 2)
	check("첫 시도는 엘리안(옛 순서)", s2.awaitFate != null and str(s2.awaitFate.ally) == "archer")
	var ev2 := RulesV2.fate_choice(s2, "defy")
	check("엘리안을 거스르면 이어서 브룬힐드 Lv2 의 시도", ev_of(ev2, "fateTrial").size() == 1 and s2.awaitFate != null and str(s2.awaitFate.ally) == "warrior" and int(s2.awaitFate.level) == 2
		and ev_of(ev2, "cleanup").is_empty())
	RulesV2.fate_choice(s2, "accept")
	var top: String = s2.draw[0]
	check("브룬힐드 Lv2 를 받아들이면 상속 「꿰뚫린 방패 Lv2」(모두 막고 되돌림)", s2.allies.warrior.dead and s2.cards[top].id == "pierced_shield" and int(s2.cards[top].lv) == 2
		and bool(RulesV2.card_def(s2, top).get("all", false)) and str(RulesV2.card_def(s2, top).name) == "꿰뚫린 방패 Lv2")
	s2.result = "win"
	RulesV2.apply_result(gs2, s2)
	var fw = Rules.fate_by_id(gs2, "warrior_pierce")
	var fa = Rules.fate_by_id(gs2, "archer_burn")
	check("게임 상태: 브룬힐드 Lv2 받아들임 · 엘리안 거스름(흉터 — 2층 1 + 1)", not fw.alive and int(fw.offeredLevel) == 2 and fa.alive and int(fa.triedFloor) == 3 and Rules.scar_count(gs2) == 2
		and gs2.party.deck2.any(func(x): return x.id == "pierced_shield" and int(x.lv) == 2))
	return true


func t_fate_cards() -> bool:
	var st := battle(["pierced_shield", "scar", "burnt_bow"], {"A": hit(6, 0), "B": hit(5, 2)})
	st.energy = 5
	var ps := uid_of(st, "pierced_shield")
	check("흉터: 낼 수 없다", not RulesV2.affordable(st, uid_of(st, "scar")))
	var r := RulesV2.cast(st, ps, "A")
	check("꿰뚫린 방패: 적 행동 카드 위에 — 그 행동의 피해 0", r.ok and RulesV2.act_value(RulesV2.enemy(st, "A").intent) == 0 and RulesV2.incoming(st, 0) == 0)
	RulesV2.uncast(st, 0)
	check("되돌리면 다시 6", RulesV2.act_value(RulesV2.enemy(st, "A").intent) == 6)
	RulesV2.cast(st, ps, "A")
	RulesV2.cast(st, uid_of(st, "burnt_bow"), "B")
	var ev := RulesV2.end_turn(st)
	check("턴 끝: 타버린 활 모든 적 10 · 꿰뚫린 방패 — 광신도 A 가 자기 찌르기 6 을 되돌려 받음 · 흉터를 든 채 → 노엘 HP -1", int(RulesV2.enemy(st, "A").hp) == 14 - 10 - 6
		or not RulesV2.enemy(st, "A").alive, "A hp %d" % int(RulesV2.enemy(st, "A").hp))
	check("흉터 · 막은 공격은 아무도 맞지 않음", int(st.noelHp) == 15 - 1 and ev_of(ev, "reflect").size() == 1 and st.allies.hero.hp == 30, "noel %d" % int(st.noelHp))
	var st2 := battle(["pierced_shield"], {"A": hit(6, 0), "B": hit(5, 2)})
	st2.cards[uid_of(st2, "pierced_shield")].lv = 2
	RulesV2.cast(st2, uid_of(st2, "pierced_shield"), "B")
	check("꿰뚫린 방패 Lv2: 막을 수 있는 행동 모두", RulesV2.incoming(st2, 0) == 0 and RulesV2.incoming(st2, 2) == 0)
	return true


func t_fate_alone() -> bool:
	var gs := fate_gs(7, "dead")
	var st := fate_battle("pyre", gs, 2)
	_zero_hits(st)
	RulesV2.end_turn(st)
	var ev := RulesV2.fate_choice(st, "accept")
	check("마지막 동료(엘리안)의 운명을 받아들이면 노엘 혼자 물러난다(지는 판이 되풀이되지 않게)", st.result == "retreat" and ev_of(ev, "retreat").size() == 1
		and bool(ev_of(ev, "retreat")[0].get("alone", false)))
	return true


func t_fate_auto() -> bool:
	var res := {}
	var bad := ""
	for key in ["ossuary", "pyre:alive", "pyre:dead"]:
		var n := {}
		for sd in range(1, 13):
			var kk: PackedStringArray = key.split(":")
			var gs := fate_gs(sd, kk[1] if kk.size() > 1 else "")
			var st := RulesV2.new_battle(null, RulesV2.battle_opts(gs, kk[0]))
			st.autoPicks = ["accept"] if sd % 2 == 0 else ["defy", "accept"]
			st = auto_run(st)
			if st.has("bad") or st.result == null:
				bad += "%s %d: %s %s; " % [key, sd, str(st.get("bad", "")), str(st.result)]
			n[str(st.result)] = int(n.get(str(st.result), 0)) + 1
			if st.get("fateResults", []).is_empty() and st.result != "lose":
				bad += "%s %d: 운명의 시도 없음; " % [key, sd]
		res[key] = n
	check("2·3층 전투: 자동 진행이 시드 1~12 모두 결과까지 · 판마다 운명의 시도가 온다(자동 진행은 시도를 피하지 않는다)", bad == "", bad + str(res))
	print("    2·3층 자동 진행(12판씩): ", res)
	return true
