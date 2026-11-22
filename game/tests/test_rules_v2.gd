## 전투 시험판 v2 「맡기기」 + v2.1 「3D 탁자」 규칙 시험 (core/rules_v2.gd · docs/battle-v2-spec.md). tests/test_rules.gd 가 t_v2() 에서 부른다:
##   godot --headless --path game --script res://tests/test_rules.gd
## 특성 넷(용사·버팀·조준·노엘은 칸 없음) · 카드 열하나(공용·전용·노엘) · 계산 순서 · 하수인(부르기·막기·저격으로 넘기·본체와 함께 사라짐)
## · 운명 전가(옮기기·되돌리기) · 승패 · 자동 진행이 끝까지 가는지 · 문구 글자가 글꼴에 있는지
## · v2.1: 적의 죽음 카드(막을 수 없음·무덤지기를 쓰러뜨림·운명 전가·운명 찢기·벤치에서 기다림·운명이 미뤄짐) · 출전 배치·자리 바꾸기(에너지 1) · 빈칸 공격은 노엘
class_name TestRulesV2
extends RefCounted

var t   # test_rules.gd (check)


func check(name: String, ok: bool, detail := "") -> void:
	t.check("전투 v2: " + name, ok, detail)


static func run(tester) -> void:
	var r := TestRulesV2.new()
	r.t = tester
	# 시험 함수마다 끝에서 true 를 돌려준다 — 도중에 스크립트 에러로 멈추면 실패로 센다(에러만 찍히고 통과로 보이지 않게)
	for m in ["t_setup", "t_turn", "t_owner", "t_hero", "t_brace", "t_aim", "t_noel", "t_order", "t_minion", "t_shift", "t_win_lose", "t_forecast", "t_auto", "t_text",
			"t_formation", "t_noel_hp", "t_death", "t_death_escape", "t_death_bench"]:
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
	check("공격 카드는 대상이 있어야 놓인다", RulesV2.place(st, uid_of(st, "slash"), "hero", {}).reason == "needTarget")
	var st2 := battle(["slash", "guard", "guard", "slash"])
	RulesV2.place(st2, uid_of(st2, "slash"), "hero", {"target": "A"})
	RulesV2.place(st2, uid_of(st2, "guard"), "hero")
	check("동료마다 2장까지", RulesV2.can_place(st2, uid_of(st2, "guard"), "hero").reason == "full")
	RulesV2.place(st2, uid_of(st2, "guard"), "warrior")
	check("행동 에너지 3 을 다 쓰면 더 못 놓는다", st2.energy == 0 and RulesV2.can_place(st2, uid_of(st2, "slash"), "archer").reason == "noEnergy")
	var r := RulesV2.unplace(st2, "hero", 0)
	check("놓은 카드를 손패로 되돌리면 에너지도 돌려받는다", r.ok and st2.energy == 1 and st2.hand.has(r.uid) and st2.allies.hero.placed.size() == 1)
	st2.allies.archer.down = true
	check("쓰러진 동료의 칸에는 놓을 수 없다", RulesV2.can_place(st2, uid_of(st2, "slash"), "archer").reason == "down")
	return true



func t_hero() -> bool:
	var st := battle(["holy", "slash"], {"A": hit(6, "hero")})
	RulesV2.place(st, uid_of(st, "holy"), "hero", {"target": "A"})
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
	RulesV2.place(st2, uid_of(st2, "revert"), "warrior", {"target": "B"})
	RulesV2.end_turn(st2)
	check("되돌리기: 쌓인 버팀 12 만큼 피해, 버팀 0", RulesV2.enemy(st2, "B").hp == 2 and st2.allies.warrior.brace == 0)
	return true



func t_aim() -> bool:
	var st := battle(["aim", "snipe"])
	RulesV2.place(st, uid_of(st, "aim"), "archer")
	RulesV2.place(st, uid_of(st, "snipe"), "archer", {"target": "G"})
	st.allies.archer.mult = 2
	RulesV2.end_turn(st)
	check("조준: 겨누기 → 배율 ×3, 저격 7 × 3 = 21, 쏜 뒤 ×1", RulesV2.enemy(st, "G").hp == 9 and st.allies.archer.mult == 1, str(RulesV2.enemy(st, "G")))
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
	RulesV2.place(st5, uid_of(st5, "slash"), "archer", {"target": "A"})
	RulesV2.end_turn(st5)
	check("엘리안의 베기(공용)에도 배율이 붙는다 (6 × 2 = 12)", RulesV2.enemy(st5, "A").hp == 2 and st5.allies.archer.mult == 1)
	return true



func t_noel() -> bool:
	var st := battle(["bless", "holy", "guard"])
	check("축복은 ④ 동료에 놓는다(적에는 안 됨)", RulesV2.can_cast(st, uid_of(st, "bless"), "A").reason == "badAlly" and RulesV2.can_cast(st, uid_of(st, "bless"), "hero").ok)
	RulesV2.cast(st, uid_of(st, "bless"), "hero")
	RulesV2.place(st, uid_of(st, "holy"), "hero", {"target": "A"})
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
	RulesV2.place(st3, uid_of(st3, "slash"), "warrior", {"target": "B"})
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
	RulesV2.place(st, uid_of(st, "snipe"), "archer", {"target": "G"})
	RulesV2.cast(st, uid_of(st, "bless"), "archer")
	RulesV2.cast(st, uid_of(st, "vuln"), "G")
	var fc := RulesV2.forecast(st)
	RulesV2.end_turn(st)
	check("계산 순서: 저격 7 × 배율 2 = 14 → 축복 21 → 취약 31 (미리 보기도 같다)", RulesV2.enemy(st, "G").hp == 0 and int(fc.values()[0].dmg) == 31, str(fc))
	# 기본 5 → 버팀 7 → 축복 10
	var st2 := battle(["guard", "bless"])
	RulesV2.place(st2, uid_of(st2, "guard"), "warrior")
	RulesV2.cast(st2, uid_of(st2, "bless"), "warrior")
	check("막기 계산 순서: 5 → 버팀 1.5배 7 → 축복 10", int(RulesV2.forecast(st2).values()[0].block) == 10)
	# 단계마다 내림: 베기 6 → 축복 9 → 취약 13 (한 번에 곱하면 13.5 → 13 으로 같음) / 성검 베기 8 → 12 → 18
	var st3 := battle(["slash", "bless", "vuln"])
	RulesV2.place(st3, uid_of(st3, "slash"), "hero", {"target": "A"})
	RulesV2.cast(st3, uid_of(st3, "bless"), "hero")
	RulesV2.cast(st3, uid_of(st3, "vuln"), "A")
	check("베기 6 → 축복 9 → 취약 13 (내림)", int(RulesV2.forecast(st3).values().filter(func(r): return r.has("dmg"))[0].dmg) == 13)
	return true



func t_minion() -> bool:
	var st := battle(["slash", "snipe"])
	summon_minion(st)
	RulesV2.place(st, uid_of(st, "slash"), "hero", {"target": "G"})
	RulesV2.place(st, uid_of(st, "snipe"), "archer", {"target": "G"})
	RulesV2.end_turn(st)
	check("하수인: 무덤지기를 노린 베기는 해골 병사가 먼저 받는다(8 → 2), 저격은 넘어 본체로(30 → 23)",
		RulesV2.enemy(st, "S").hp == 2 and RulesV2.enemy(st, "G").hp == 23, str([RulesV2.enemy(st, "S").hp, RulesV2.enemy(st, "G").hp]))
	var st2 := battle(["slash", "slash"])
	summon_minion(st2)
	RulesV2.enemy(st2, "S").hp = 4
	RulesV2.place(st2, uid_of(st2, "slash"), "hero", {"target": "G"})
	RulesV2.place(st2, uid_of(st2, "slash", 0), "warrior", {"target": "G"})
	RulesV2.end_turn(st2)
	check("하수인을 쓰러뜨리면 다음 공격은 본체로 (넘친 피해는 넘어가지 않음)", not RulesV2.enemy(st2, "S").alive and RulesV2.enemy(st2, "G").hp == 24)
	var st3 := battle(["snipe"])
	summon_minion(st3)
	st3.allies.archer.mult = 4
	RulesV2.enemy(st3, "G").hp = 20
	RulesV2.enemy(st3, "S").intent = hit(4, "hero")
	RulesV2.place(st3, uid_of(st3, "snipe"), "archer", {"target": "G"})
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
	RulesV2.place(st, uid_of(st, "slash"), "hero", {"target": "A"})
	RulesV2.place(st, uid_of(st, "slash", 0), "warrior", {"target": "B"})
	RulesV2.place(st, uid_of(st, "snipe"), "archer", {"target": "G"})
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
	RulesV2.place(st, uid_of(st, "snipe"), "archer", {"target": "B"})
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
	print("    v2 자동 진행 30판: ", results)
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
	RulesV2.place(st2, uid_of(st2, "slash"), "hero", {"target": "A"})
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
	RulesV2.place(st, uid_of(st, "snipe"), "archer", {"target": "G"})
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
	RulesV2.place(st, snipe[0], "archer", {"target": "G"})
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
