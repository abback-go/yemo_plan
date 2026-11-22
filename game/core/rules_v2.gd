## rules_v2.gd — 전투 시험판 v2 「맡기기」 + v2.1 「3D 탁자」 규칙 (docs/battle-v2-spec.md 3~6장 · 9-2). 화면과 따로 → 헤드리스 시험(tests/test_rules_v2.gd).
## 노엘이 손패의 카드를 동료 칸(③)에 놓아 일을 맡긴다. 노엘 자신의 카드는 칸이 없어 ② 적 행동 카드·① 적·④ 동료에 직접 놓는다.
## 적의 다음 행동 카드(②)는 노리는 **칸**에 놓인다(v2.1: 칸 기준 — 빈칸도 노린다. 빈칸 공격은 노엘이 맞는다). 같은 카드라도 맡은 동료의 특성(용사·버팀·조준)이 붙는다.
## 턴 끝에 한꺼번에: 왼쪽 칸부터 ③ 의 카드대로 동료가 행동 → 살아 있는 적·하수인의 ② 가 그 칸에(동료 또는 노엘) → 죽음 카드 처리 → 막기·축복·취약은 사라지고 손패는 버린다.
## v2.1: 출전 배치(phase "formation" — 칸 3개·벤치에 공짜로) → 전투 중 내 턴에 행동 에너지 1 로 자리 바꾸기·빼기·넣기.
##       무덤지기의 3번째 행동 = 「세라피나의 죽음」(막기·저주로 줄지 않음, 그 동료가 칸에 있으면 죽음). 노엘 「운명 찢기」(에너지 3)로 없앤다.
## 수치·카드는 data/battle_v2_data.gd. 난수는 지금 규칙과 같은 mulberry32(Rules.rnd)를 이 상태의 st.rng 로 돌린다 → 같은 시드면 같은 전투.
##
## 상태(st) 구조 (Dictionary)
##   st.seed · st.rng          시드 · 난수 상태
##   st.phase                  "formation"(출전 배치) | "battle"
##   st.turn · st.energy        턴(1부터) · 이번 턴에 남은 행동 에너지
##   st.result · st.loseBy     null | "win" | "lose" · 패배 까닭 "noel" | "allies"
##   st.cards {uid: {uid, id}} · st.draw / st.hand / st.discard [uid]   덱 (뽑을 더미 · 손패 · 버린 더미)
##   st.order [동료 id]         동료 목록(고정 — 결과 판·시험의 순서)
##   st.slots [동료 id | ""] × 3   칸(열) 왼쪽 → 오른쪽. "" = 빈칸. 턴 끝에 이 순서로 행동한다
##   st.bench [동료 id]          대기 동료(벤치)
##   st.noelHp · st.noelMax     노엘 HP (빈칸 공격을 맞는다 · 막기 없음)
##   st.allies {id: {id, trait, hp, maxHp, block, down, dead, placed: [{uid, target}], brace, mult, blessed, counter}}
##       placed: ③ 줄에 맡긴 카드(놓은 순서) · target: 공격 카드로 누른 적 id · dead: 죽음 카드로 죽음(down 도 true)
##       brace: 브룬힐드 버팀(전투 내내) · mult: 엘리안 배율(×1~×4, 전투 내내) · blessed: 이번 턴 축복 · counter: 이번 적 턴에 반격(세라피나가 막기를 맡음)
##   st.enemies [{id, type, tag, of, col, hp, maxHp, alive, vuln, intent, acts}]   (BattleV2Data.lineup 순서 = 행동 순서)
##       of: 하수인이면 그 강적 id (하수인은 처음에 alive=false — 강적이 부르면 나온다) · col: ① 줄의 칸 · vuln: 이번 턴 취약 · acts: 지금까지 정한 행동 수
##       intent: 다음 적 턴의 행동(②) {kind: "hit"|"sweep"|"summon"|"death", label, value, minus(저주), slot: 노리는 칸 0~2 | "all" | "", death: 죽음 카드 id}
##   st.deaths [{id, ally, src, bound, label}]   죽음 카드. bound: 아직 낸 적의 ② 행동(그 적이 쓰러지면 사라짐) — 한 번 기다리면 false(동료를 따라감)
##   st.noel [{uid, kind, target, move, torn}]   노엘이 이번 턴에 직접 놓은 카드(운명 전가·축복·저주·취약·운명 찢기).
##       move: {enemy, from, to}(칸) 또는 {death, from, to}(동료 id) · torn: 운명 찢기로 없앤 죽음 카드(되돌리기용)
##
## 계산 순서(지시서 5장): 피해 = 기본 → 동료 특성(배율) → 축복 +50% → 취약 +50%, 단계마다 소수점 내림. 막기 = 기본 → 버팀 1.5배 → 축복(내림)
## [판단] 지시서에 없는 세부는 game/DECISIONS.md 「전투 시험판 v2」·「v2.1」
class_name RulesV2
extends RefCounted


static func D() -> Dictionary:
	return BattleV2Data.D


static func _no(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason}


static func _pct(v: int, pct: int) -> int:
	return int(floor(v * (100 + pct) / 100.0))


# ───────── 새 전투 ─────────
static func new_battle(seed = null) -> Dictionary:
	var d := D()
	var sd: int = (randi() % 1000000000) if seed == null else (int(seed) & Rules.M32)
	var st := {"seed": sd, "rng": sd if sd != 0 else 1, "nextUid": 1, "turn": 0, "energy": 0, "result": null, "loseBy": "", "phase": "formation",
		"cards": {}, "draw": [], "hand": [], "discard": [], "order": d.order.duplicate(), "slots": d.formation.duplicate(), "bench": [],
		"noelHp": int(d.rules.noelHp), "noelMax": int(d.rules.noelHp), "allies": {}, "enemies": [], "noel": [], "deaths": [], "nextDeath": 1}
	for id in st.order:
		var a: Dictionary = d.allies[id]
		st.allies[id] = {"id": id, "trait": a.trait, "hp": int(a.hp), "maxHp": int(a.hp), "block": 0, "down": false, "dead": false, "placed": [],
			"brace": 0, "mult": 1, "blessed": false, "counter": false}
		if not st.slots.has(id):
			st.bench.append(id)
	for l in d.lineup:
		var t: Dictionary = d.enemies[l.type]
		var minion := str(l.get("of", "")) != ""
		st.enemies.append({"id": l.id, "type": l.type, "tag": str(l.get("tag", "")), "of": str(l.get("of", "")), "col": int(l.get("col", 0)),
			"hp": 0 if minion else int(t.hp), "maxHp": int(t.hp), "alive": not minion, "vuln": false, "intent": null, "acts": 0})
	for pair in d.deck:
		for i in int(pair[1]):
			var uid := "v" + str(st.nextUid)
			st.nextUid = int(st.nextUid) + 1
			st.cards[uid] = {"uid": uid, "id": str(pair[0])}
			st.draw.append(uid)
	Rules.shuffle(st, st.draw)
	return st


# ───────── 조회 ─────────
static func card_def(st: Dictionary, uid: String) -> Dictionary:
	return D().cards[st.cards[uid].id]


static func is_noel(st: Dictionary, uid: String) -> bool:
	return str(card_def(st, uid).owner) == "noel"


static func enemy(st: Dictionary, id: String):
	for e in st.enemies:
		if e.id == id:
			return e
	return null


static func alive_enemies(st: Dictionary) -> Array:
	return st.enemies.filter(func(e): return e.alive)


## 이기려면 쓰러뜨려야 하는 적(하수인 말고) 가운데 살아 있는 것
static func alive_main(st: Dictionary) -> Array:
	return st.enemies.filter(func(e): return e.alive and str(e.of) == "")


static func is_minion(e: Dictionary) -> bool:
	return str(e.of) != ""


## 그 강적 앞에 살아 있는 하수인 (없으면 null)
static func guard_of(st: Dictionary, id: String):
	for e in st.enemies:
		if e.alive and str(e.of) == id:
			return e
	return null


static func ncols() -> int:
	return int(D().rules.cols)


## 그 동료가 선 칸 (벤치면 -1)
static func col_of(st: Dictionary, ally_id: String) -> int:
	return st.slots.find(ally_id)


## 그 칸의 동료 ("" = 빈칸)
static func ally_at(st: Dictionary, col: int) -> String:
	return str(st.slots[col]) if col >= 0 and col < st.slots.size() else ""


## 칸에 선 동료(왼쪽 → 오른쪽 — 턴 끝에 행동하는 순서)
static func field(st: Dictionary) -> Array:
	return st.slots.filter(func(id): return str(id) != "")


## 칸에 선 살아 있는 동료 (왼쪽 → 오른쪽)
static func living_allies(st: Dictionary) -> Array:
	return field(st).filter(func(id): return not st.allies[id].down)


## 칸·벤치 어디든 살아 있는 동료
static func any_living(st: Dictionary) -> bool:
	return st.order.any(func(id): return not st.allies[id].down)


## 그 칸을 노린 공격을 받는 쪽: 살아 있는 동료가 서 있으면 그 동료, 아니면 "noel"(빈칸 · 쓰러진 동료의 칸)
static func receiver(st: Dictionary, col: int) -> String:
	var id := ally_at(st, col)
	return id if id != "" and not st.allies[id].down else "noel"


## 공격이 실제로 들어가는 적. 하수인이 앞에 있는 강적이면 하수인이 먼저 받는다(pierce = 저격: 하수인을 넘어 본체).
## 누른 적이 이미 쓰러졌으면: 하수인은 그 강적에게, 그 밖은 살아 있는 가장 왼쪽 적에게(그 적도 하수인이 막으면 하수인). id "" 도 가장 왼쪽. 없으면 null
static func hit_target(st: Dictionary, id: String, pierce := false):
	var e = enemy(st, id)
	if e == null or not e.alive:
		var nxt = null
		if e != null and is_minion(e):
			var m = enemy(st, str(e.of))
			if m != null and m.alive:
				nxt = m
		if nxt == null:
			var al := alive_main(st)
			if al.is_empty():
				return null
			nxt = al[0]
		e = nxt
	if pierce:
		return e
	var g = guard_of(st, e.id)
	return g if g != null else e


## 9-6(사용자 결정): 그 칸(열)의 동료가 치는 앞 적 — 같은 열의 살아 있는 적. 하수인이 있으면 하수인이 먼저(pierce = 저격: 넘어 그 열 본체). 없으면 null
static func front(st: Dictionary, col: int, pierce := false):
	var main = null
	var guard = null
	for e in st.enemies:
		if e.alive and int(e.col) == col:
			if is_minion(e):
				guard = e
			else:
				main = e
	if pierce and main != null:
		return main
	return guard if guard != null else main


## 그 동료(칸)의 공격 카드가 칠 적 (벤치·앞 적 없음 = null)
static func front_of(st: Dictionary, ally_id: String, uid := ""):
	var pierce := uid != "" and bool(card_def(st, uid).get("pierce", false))
	return front(st, col_of(st, ally_id), pierce)


## 적 행동 카드의 피해(저주 반영)
static func act_value(it: Dictionary) -> int:
	return maxi(0, int(it.value) - int(it.get("minus", 0)))


## 이 칸(②)의 한 명 공격 — 적 id 목록 (적 순서)
static func intents_at(st: Dictionary, col: int) -> Array:
	var out := []
	for e in st.enemies:
		if e.alive and e.intent != null and e.intent.kind == "hit" and int(e.intent.slot) == col:
			out.append(e.id)
	return out


static func sweep_enemy(st: Dictionary):
	for e in st.enemies:
		if e.alive and e.intent != null and e.intent.kind == "sweep":
			return e
	return null


static func death(st: Dictionary, did: String):
	for d in st.deaths:
		if d.id == did:
			return d
	return null


## 그 동료를 노리는 죽음 카드
static func deaths_of(st: Dictionary, ally_id: String) -> Array:
	return st.deaths.filter(func(d): return d.ally == ally_id)


## 이 칸에 다음 적 턴에 들어올 피해(한 명 공격 + 모두)
static func incoming(st: Dictionary, col: int) -> int:
	var v := 0
	for eid in intents_at(st, col):
		v += act_value(enemy(st, eid).intent)
	var sw = sweep_enemy(st)
	if sw != null:
		v += act_value(sw.intent)
	return v


## 노려지는가 (그 칸에 ② 카드가 있거나 '모두' 공격 · 죽음 카드) — 초상이 붉은 테두리·흔들림
static func is_targeted(st: Dictionary, ally_id: String) -> bool:
	if st.allies[ally_id].down:
		return false
	var c := col_of(st, ally_id)
	if c < 0:
		return false
	return not intents_at(st, c).is_empty() or sweep_enemy(st) != null or not deaths_of(st, ally_id).is_empty()


static func affordable(st: Dictionary, uid: String) -> bool:
	return st.result == null and st.phase == "battle" and st.hand.has(uid) and int(card_def(st, uid).cost) <= int(st.energy)


static func death_label(ally_id: String) -> String:
	return str(D().death.label).replace("{name}", str(D().owners.get(ally_id, ally_id)))


# ───────── 출전 배치 · 자리 바꾸기 (v2.1) ─────────
## 동료를 to(칸 0~2 · "bench")로. 출전 배치에서는 공짜, 전투 중에는 내 턴에 행동 에너지 moveCost.
##   칸 → 다른 칸: 자리 바꾸기(그 칸이 비었으면 옮기기) · 칸 → 벤치: 빼기(③ 카드·축복은 손패로, 에너지 돌려받음) · 벤치 → 빈칸: 넣기
##   출전 배치에서는 벤치 → 동료가 있는 칸도 된다(그 동료가 벤치로)
static func can_move(st: Dictionary, ally_id: String, to) -> Dictionary:
	if st.result != null:
		return _no("over")
	if not st.allies.has(ally_id):
		return _no("noAlly")
	var from := col_of(st, ally_id)
	var to_bench := str(to) == "bench"
	var tc := -1 if to_bench else int(to)
	if not to_bench and (tc < 0 or tc >= ncols()):
		return _no("badMove")
	if (to_bench and from < 0) or (not to_bench and from == tc):
		return _no("same")
	var free: bool = st.phase == "formation"
	if not free and int(st.energy) < int(D().rules.moveCost):
		return _no("noEnergy")
	if from < 0 and not to_bench:
		if st.allies[ally_id].dead:
			return _no("deadAlly")
		if st.allies[ally_id].down:
			return _no("down")
		if ally_at(st, tc) != "" and not free:
			return _no("occupied")
	return {"ok": true, "cost": 0 if free else int(D().rules.moveCost)}


## 반환 {ok, returned: [손패로 돌아온 uid]}
static func move_ally(st: Dictionary, ally_id: String, to) -> Dictionary:
	var chk := can_move(st, ally_id, to)
	if not chk.ok:
		return chk
	var from := col_of(st, ally_id)
	var returned := []
	if str(to) == "bench":
		returned = _recall(st, ally_id)
		st.slots[from] = ""
		st.bench.append(ally_id)
	else:
		var tc := int(to)
		var other := ally_at(st, tc)
		if from >= 0:
			st.slots[from] = other
			st.slots[tc] = ally_id
		else:
			st.bench.erase(ally_id)
			if other != "":
				returned = _recall(st, other)
				st.bench.append(other)
			st.slots[tc] = ally_id
	st.energy = int(st.energy) - int(chk.cost)
	return {"ok": true, "returned": returned, "cost": chk.cost}


## 벤치로 가는 동료: 맡긴 카드와 그 동료에게 건 축복을 손패로(에너지 돌려받음)
static func _recall(st: Dictionary, ally_id: String) -> Array:
	var out := []
	var a: Dictionary = st.allies[ally_id]
	while not a.placed.is_empty():
		out.append(unplace(st, ally_id, a.placed.size() - 1).uid)
	for i in range(st.noel.size() - 1, -1, -1):
		var n: Dictionary = st.noel[i]
		if n.kind == "bless" and n.target == ally_id:
			out.append(uncast(st, i).uid)
	return out


## 출전 배치를 끝내고 첫 턴을 시작한다 (칸에 살아 있는 동료가 하나는 있어야 한다)
static func start_battle(st: Dictionary) -> Dictionary:
	if st.phase != "formation":
		return _no("same")
	if living_allies(st).is_empty():
		return _no("noneFielded")
	return {"ok": true, "events": start_turn(st)}


# ───────── 내 턴 시작 ─────────
## 5장 뽑기 · 행동 에너지 3 · 살아 있는 적(하수인 포함)마다 다음 적 턴의 행동을 정한다(②)
static func start_turn(st: Dictionary) -> Array:
	var ev := []
	if st.result != null:
		return ev
	st.phase = "battle"
	st.turn = int(st.turn) + 1
	st.energy = int(D().rules.energy)
	ev.append({"t": "turnStart", "turn": st.turn})
	_draw(st, int(D().rules.draw), ev)
	roll_intents(st, ev)
	ev.append({"t": "intents"})
	return ev


static func _draw(st: Dictionary, n: int, ev: Array) -> void:
	var got := []
	for i in n:
		if st.draw.is_empty():
			if st.discard.is_empty():
				break
			st.draw = st.discard.duplicate()
			st.discard = []
			Rules.shuffle(st, st.draw)
			if not got.is_empty():
				ev.append({"t": "draw", "uids": got})
				got = []
			ev.append({"t": "reshuffle"})
		var u: String = st.draw.pop_front()
		st.hand.append(u)
		got.append(u)
	if not got.is_empty():
		ev.append({"t": "draw", "uids": got})


## 적 행동: 광신도 찌르기 min~max · 무덤지기 하수인이 없으면 부르기, 있으면 삽 내려치기 · 해골 병사 녹슨 칼 — 한 명 공격은 칸 하나(무작위, 빈칸 포함).
## sweepEvery 턴마다 살아 있는 광신도 하나는 휩쓸기 → 모든 칸. 무덤지기의 death.at 번째 행동은 죽음 카드(그 동료가 살아 있으면)
static func roll_intents(st: Dictionary, ev := []) -> void:
	var live := any_living(st)
	var DT: Dictionary = D().death
	for e in st.enemies:
		e.intent = null
		if not e.alive or not live:
			continue
		e.acts = int(e.get("acts", 0)) + 1
		if e.type == str(DT.enemy) and int(e.acts) == int(DT.at) and not st.allies[str(DT.ally)].down and deaths_of(st, str(DT.ally)).is_empty():
			var did := "death" + str(st.nextDeath)
			st.nextDeath = int(st.nextDeath) + 1
			var lab := death_label(str(DT.ally))
			st.deaths.append({"id": did, "ally": str(DT.ally), "src": e.id, "bound": true, "label": lab})
			e.intent = {"kind": "death", "label": lab, "value": 0, "minus": 0, "slot": "", "death": did}
			ev.append({"t": "deathCard", "id": did, "ally": str(DT.ally), "enemy": e.id})
			continue
		var acts: Dictionary = D().enemies[e.type].acts
		if acts.has("summon") and guard_of(st, e.id) == null:
			e.intent = {"kind": "summon", "label": acts.summon.label, "value": 0, "minus": 0, "slot": ""}
			continue
		var h: Dictionary = acts.hit
		var v := int(h.get("value", 0))
		if h.has("min"):
			v = int(h.min) + Rules.rint(st, int(h.max) - int(h.min) + 1)
		e.intent = {"kind": "hit", "label": h.label, "value": v, "minus": 0, "slot": Rules.rint(st, ncols())}
	if int(st.turn) % int(D().rules.sweepEvery) == 0 and live:
		var sw: Array = st.enemies.filter(func(e): return e.alive and e.intent != null and e.intent.kind == "hit" and D().enemies[e.type].acts.has("sweep"))
		if not sw.is_empty():
			var se: Dictionary = sw[Rules.rint(st, sw.size())]
			var s: Dictionary = D().enemies[se.type].acts.sweep
			se.intent = {"kind": "sweep", "label": s.label, "value": int(s.value), "minus": 0, "slot": "all"}


# ───────── 맡기기 (동료 칸 ③) ─────────
## 그 카드를 그 동료 칸에 놓을 수 있는가 (공격 대상은 아직 고르지 않아도 된다). 노엘의 카드는 칸에 놓지 않는다(can_cast)
static func can_place(st: Dictionary, uid: String, ally_id: String) -> Dictionary:
	if st.result != null:
		return _no("over")
	if st.phase != "battle":
		return _no("formation")
	if not st.hand.has(uid):
		return _no("notInHand")
	var c := card_def(st, uid)
	if str(c.owner) == "noel":
		return _no("noelCard")
	if not st.allies.has(ally_id):
		return _no("noAlly")
	var a: Dictionary = st.allies[ally_id]
	if col_of(st, ally_id) < 0:
		return _no("bench")
	if a.down:
		return _no("down")
	if str(c.owner) != "" and str(c.owner) != ally_id:
		return _no("notOwner")
	if room(st, ally_id) <= 0:
		return _no("full")
	if int(c.cost) > int(st.energy):
		return _no("noEnergy")
	if str(c.kind) in ["attack", "release"]:
		if alive_enemies(st).is_empty():
			return _no("noEnemy")
		if front_of(st, ally_id, uid) == null:
			return _no("noFront")   # 9-6: 앞(같은 열)에 살아 있는 적이 없으면 공격 카드를 놓을 수 없다
	return {"ok": true}


## 그 동료 칸에 더 놓을 수 있는 장수 (rules.maxPlaced 0 = 제한 없음 → 아주 큰 수. 에너지는 따로 본다)
static func room(st: Dictionary, ally_id: String) -> int:
	var mx := int(D().rules.maxPlaced)
	if mx <= 0:
		return 1 << 20
	return mx - st.allies[ally_id].placed.size()


## 그 칸에 놓을 수 있는가 (칸 → 그 칸의 동료)
static func can_place_col(st: Dictionary, uid: String, col: int) -> Dictionary:
	var id := ally_at(st, col)
	if id == "":
		return _no("empty")
	return can_place(st, uid, id)


## 9-6: 공격은 앞(같은 열) 적에게 자동 — 대상을 고르지 않는다(자리를 바꾸면 그 열의 적으로)
static func needs_target(_st: Dictionary, _uid: String) -> bool:
	return false


## 동료 칸에 놓는다. opts 는 쓰지 않는다(9-6 — 예전 {target} 은 무시). target: 놓을 때의 앞 적(보여 주기용, 턴 끝에 다시 셈). 반환 {ok, placed} / {ok: false, reason}
static func place(st: Dictionary, uid: String, ally_id: String, _opts := {}) -> Dictionary:
	var chk := can_place(st, uid, ally_id)
	if not chk.ok:
		return chk
	var p := {"uid": uid, "target": ""}
	if str(card_def(st, uid).kind) in ["attack", "release"]:
		p.target = str(front_of(st, ally_id, uid).id)
	st.hand.erase(uid)
	st.energy = int(st.energy) - int(card_def(st, uid).cost)
	st.allies[ally_id].placed.append(p)
	return {"ok": true, "placed": p}


## 놓은 카드를 손패로 되돌린다(행동 에너지 돌려받음)
static func unplace(st: Dictionary, ally_id: String, index: int) -> Dictionary:
	if st.result != null:
		return _no("over")
	if not st.allies.has(ally_id):
		return _no("noAlly")
	var a: Dictionary = st.allies[ally_id]
	if index < 0 or index >= a.placed.size():
		return _no("noPlaced")
	var p: Dictionary = a.placed[index]
	a.placed.remove_at(index)
	st.hand.append(p.uid)
	st.energy = int(st.energy) + int(card_def(st, p.uid).cost)
	return {"ok": true, "uid": p.uid}


# ───────── 노엘의 카드 (② 적 행동 · ① 적 · ④ 동료에 직접) ─────────
## target: 운명 전가·저주 = 그 행동을 보낸 적 id(② 카드) 또는 죽음 카드 id(운명 전가) · 운명 찢기 = 죽음 카드 id · 취약 = 적 id(①) · 축복 = 동료 id(④)
static func can_cast(st: Dictionary, uid: String, target: String) -> Dictionary:
	if st.result != null:
		return _no("over")
	if st.phase != "battle":
		return _no("formation")
	if not st.hand.has(uid):
		return _no("notInHand")
	var c := card_def(st, uid)
	if str(c.owner) != "noel":
		return _no("notNoel")
	if int(c.cost) > int(st.energy):
		return _no("noEnergy")
	match str(c.kind):
		"shift":
			var dd = death(st, target)
			if dd == null:
				var e = enemy(st, target)
				if e == null or not e.alive or e.intent == null or e.intent.kind != "hit":
					return _no("badAct")
			if shift_dests(st, target).is_empty():
				return _no("noDest")
		"curse":
			if death(st, target) != null:
				return _no("death")
			var e2 = enemy(st, target)
			if e2 == null or not e2.alive or e2.intent == null or not e2.intent.kind in ["hit", "sweep"]:
				return _no("death" if e2 != null and e2.intent != null and e2.intent.kind == "death" else "badAct")
			if int(e2.intent.minus) > 0:
				return _no("already")
		"tear":
			if death(st, target) == null:
				return _no("notDeath")
		"vuln":
			var e3 = enemy(st, target)
			if e3 == null or not e3.alive:
				return _no("badEnemy")
			if e3.vuln:
				return _no("already")
		"bless":
			if not st.allies.has(target) or st.allies[target].down or col_of(st, target) < 0:
				return _no("badAlly")
			if st.allies[target].blessed:
				return _no("already")
	return {"ok": true}


## 운명 전가로 옮길 수 있는 칸(0~2): 한 명 공격 = 지금 노리는 칸이 아닌 칸(빈칸도 — 노엘이 맞는다) ·
## 죽음 카드 = 살아 있는 다른 동료가 선 칸(빈칸으로는 못 옮김 — 그 동료가 대신 죽는다)
static func shift_dests(st: Dictionary, target: String) -> Array:
	var dd = death(st, target)
	var out := []
	if dd != null:
		for c in ncols():
			var id := ally_at(st, c)
			if id != "" and id != dd.ally and not st.allies[id].down:
				out.append(c)
		return out
	var e = enemy(st, target)
	if e == null or e.intent == null or e.intent.kind != "hit":
		return []
	for c in ncols():
		if c != int(e.intent.slot):
			out.append(c)
	return out


## 운명 전가의 to: 칸 번호(0~2) 또는 동료 id(그 동료의 칸)
static func _to_col(st: Dictionary, to) -> int:
	if to is int or to is float:
		return int(to)
	var s := str(to)
	if s.is_valid_int():
		return int(s)
	return col_of(st, s)


## 노엘의 카드를 놓는다. 운명 전가는 opts {to: 옮길 칸} — 놓는 즉시 ② 를 옮긴다
static func cast(st: Dictionary, uid: String, target: String, opts := {}) -> Dictionary:
	var chk := can_cast(st, uid, target)
	if not chk.ok:
		return chk
	var c := card_def(st, uid)
	var n := {"uid": uid, "kind": str(c.kind), "target": target, "move": null, "torn": null}
	match str(c.kind):
		"shift":
			var to := _to_col(st, opts.get("to", -1))
			if not shift_dests(st, target).has(to):
				return _no("badMove")
			var dd = death(st, target)
			if dd != null:
				n.move = {"death": target, "from": dd.ally, "to": ally_at(st, to)}
				dd.ally = ally_at(st, to)
				dd.label = death_label(dd.ally)
				var src = enemy(st, str(dd.src))
				if src != null and src.intent != null and src.intent.get("death", "") == target:
					src.intent.label = dd.label
			else:
				var e: Dictionary = enemy(st, target)
				n.move = {"enemy": target, "from": int(e.intent.slot), "to": to}
				e.intent.slot = to
		"curse":
			enemy(st, target).intent.minus = int(c.minus)
		"tear":
			var dd2 = death(st, target)
			n.torn = dd2.duplicate()
			st.deaths.erase(dd2)
			var src2 = enemy(st, str(dd2.src))
			if src2 != null and src2.intent != null and src2.intent.get("death", "") == target:
				src2.intent.torn = true
		"vuln":
			enemy(st, target).vuln = true
		"bless":
			st.allies[target].blessed = true
	st.hand.erase(uid)
	st.energy = int(st.energy) - int(c.cost)
	st.noel.append(n)
	return {"ok": true, "cast": n}


## 노엘의 카드를 손패로 되돌린다(효과도 없던 일로). 옮긴 행동을 그 뒤 다시 옮겼으면 그 카드를 먼저 되돌려야 한다(movedAgain)
static func uncast(st: Dictionary, index: int) -> Dictionary:
	if st.result != null:
		return _no("over")
	if index < 0 or index >= st.noel.size():
		return _no("noPlaced")
	var n: Dictionary = st.noel[index]
	match str(n.kind):
		"shift":
			if n.move.has("death"):
				var dd = death(st, str(n.move.death))
				if dd != null:
					if dd.ally != n.move.to:
						return _no("movedAgain")
					dd.ally = n.move.from
					dd.label = death_label(dd.ally)
					var src = enemy(st, str(dd.src))
					if src != null and src.intent != null and src.intent.get("death", "") == dd.id:
						src.intent.label = dd.label
			else:
				var e = enemy(st, str(n.move.enemy))
				if e != null and e.intent != null:
					if int(e.intent.slot) != int(n.move.to):
						return _no("movedAgain")
					e.intent.slot = int(n.move.from)
		"curse":
			var e2 = enemy(st, str(n.target))
			if e2 != null and e2.intent != null:
				e2.intent.minus = 0
		"tear":
			if n.torn != null:
				st.deaths.append(n.torn.duplicate())
				var src2 = enemy(st, str(n.torn.src))
				if src2 != null and src2.intent != null and src2.intent.get("death", "") == n.target:
					src2.intent.erase("torn")
		"vuln":
			var e3 = enemy(st, str(n.target))
			if e3 != null:
				e3.vuln = false
		"bless":
			st.allies[n.target].blessed = false
	st.noel.remove_at(index)
	st.hand.append(n.uid)
	st.energy = int(st.energy) + int(card_def(st, n.uid).cost)
	return {"ok": true, "uid": n.uid, "cast": n}


# ───────── 턴 끝 → 적 턴 (한꺼번에) ─────────
## 왼쪽 칸부터 ③ 의 카드대로 동료가 행동 → 살아 있는 적·하수인의 ② 가 그 칸에(동료 · 빈칸이면 노엘) → 죽음 카드 → 정리
## 이기려면 쓰러뜨려야 할 적이 모두 쓰러지면 그 자리에서 승리. 노엘 HP 0 이면 그 자리에서 패배, 적 턴 뒤 동료가 모두 쓰러졌으면 패배. 쓰러진 적이 보낸 ② 는 사라진다
static func end_turn(st: Dictionary) -> Array:
	var ev := []
	if st.result != null or st.phase != "battle":
		return ev
	_ally_phase(st, ev)
	if st.result == null:
		ev.append({"t": "enemyPhase"})
		for e in st.enemies:
			if st.result != null:
				break
			if e.alive and e.intent != null:
				_enemy_act(st, e, ev)
		if st.result == null:
			_resolve_deaths(st, ev)
		if st.result == null and not any_living(st):
			_lose(st, "allies", ev)
	_cleanup(st, ev)
	return ev


static func _lose(st: Dictionary, by: String, ev: Array) -> void:
	st.result = "lose"
	st.loseBy = by
	ev.append({"t": "lose", "by": by})


static func _ally_phase(st: Dictionary, ev: Array) -> void:
	ev.append({"t": "allyPhase"})
	for id in field(st):
		var a: Dictionary = st.allies[id]
		if a.down:
			continue
		for p in a.placed:
			if st.result != null:
				return
			_act(st, id, p, ev)


static func _act(st: Dictionary, ally_id: String, p: Dictionary, ev: Array) -> void:
	var a: Dictionary = st.allies[ally_id]
	var cid: String = st.cards[p.uid].id
	var c: Dictionary = D().cards[cid]
	var tr: Dictionary = D().traits[a.trait]
	ev.append({"t": "act", "ally": ally_id, "uid": p.uid, "card": cid})
	match str(c.kind):
		"attack", "release":
			var e = front(st, col_of(st, ally_id), bool(c.get("pierce", false)))   # 9-6: 지금 그 열의 앞 적(앞 적이 먼저 쓰러졌으면 헛침)
			var dmg := 0
			if str(c.kind) == "release":
				dmg = int(a.brace)
				a.brace = 0
				ev.append({"t": "brace", "ally": ally_id, "brace": 0, "uid": p.uid})
			else:
				dmg = int(c.damage)
				if a.trait == "aim":
					dmg *= int(a.mult)
					if int(a.mult) != 1:
						a.mult = 1
						ev.append({"t": "mult", "ally": ally_id, "mult": 1, "uid": p.uid})
			if a.blessed:
				dmg = _pct(dmg, int(D().cards.bless.pct))
			if e != null:
				if e.id != str(p.target):
					ev.append({"t": "retarget", "ally": ally_id, "uid": p.uid, "enemy": e.id, "from": p.target})
				_hit_enemy(st, e, dmg, ally_id, p.uid, ev)
			# 용사: 공격을 맡으면 막기도
			if a.trait == "hero" and str(c.kind) == "attack":
				var hb := int(tr.attackBlock)
				if a.blessed:
					hb = _pct(hb, int(D().cards.bless.pct))
				a.block = int(a.block) + hb
				ev.append({"t": "block", "ally": ally_id, "amount": hb, "total": a.block, "uid": p.uid})
			if alive_main(st).is_empty():
				st.result = "win"
				ev.append({"t": "win"})
		"block":
			var b := int(c.block)
			if a.trait == "brace":
				b = int(floor(b * float(tr.blockMult)))
			if a.blessed:
				b = _pct(b, int(D().cards.bless.pct))
			a.block = int(a.block) + b
			if a.trait == "hero":
				a.counter = true
			ev.append({"t": "block", "ally": ally_id, "amount": b, "total": a.block, "uid": p.uid, "counter": a.trait == "hero"})
		"aim":
			a.mult = mini(int(tr.max), int(a.mult) + 1)
			ev.append({"t": "mult", "ally": ally_id, "mult": a.mult, "uid": p.uid})


static func _hit_enemy(st: Dictionary, e: Dictionary, dmg: int, by: String, uid: String, ev: Array) -> void:
	var amt := dmg
	if e.vuln:
		amt = _pct(amt, int(D().cards.vuln.pct))
	e.hp = maxi(0, int(e.hp) - amt)
	ev.append({"t": "hit", "enemy": e.id, "ally": by, "uid": uid, "amount": amt, "vuln": e.vuln, "hp": e.hp})
	if int(e.hp) <= 0:
		_kill(st, e, ev)


static func _kill(st: Dictionary, e: Dictionary, ev: Array, with := "") -> void:
	e.alive = false
	e.intent = null
	e.vuln = false
	e.hp = 0
	ev.append({"t": "enemyDie", "enemy": e.id, "with": with})
	# 아직 이 적의 ② 행동인 죽음 카드는 함께 사라진다(먼저 쓰러뜨림). 한 번 기다린 죽음 카드는 동료를 따라가 남는다
	for dd in st.deaths.duplicate():
		if dd.src == e.id and dd.bound:
			st.deaths.erase(dd)
			ev.append({"t": "deathGone", "id": dd.id, "ally": dd.ally})
	# 강적이 쓰러지면 그 하수인도 사라진다
	var g = guard_of(st, e.id)
	if g != null:
		_kill(st, g, ev, e.id)


static func _enemy_act(st: Dictionary, e: Dictionary, ev: Array) -> void:
	var it: Dictionary = e.intent
	ev.append({"t": "enemyAct", "enemy": e.id, "kind": it.kind, "slot": it.slot, "value": act_value(it)})
	if it.kind == "summon":
		for m in st.enemies:
			if str(m.of) == e.id and not m.alive:
				m.alive = true
				m.hp = int(m.maxHp)
				m.vuln = false
				m.intent = null
				ev.append({"t": "summon", "enemy": e.id, "minion": m.id})
		return
	if it.kind == "death":
		return   # 죽음 카드는 적 턴 끝에 한꺼번에(_resolve_deaths)
	var cols := []
	if str(it.slot) == "all":
		for c in ncols():
			cols.append(c)
	else:
		cols = [int(it.slot)]
	for c in cols:
		var who := receiver(st, c)
		if who == "noel":
			_hit_noel(st, act_value(it), e.id, c, ev)
			if st.result != null:
				return
			continue
		_hit_ally(st, who, act_value(it), e.id, ev)
		# 용사: 막기를 맡았으면 막은 뒤 자기를 친 적에게 반격 (하수인이 막지 않는다 — 친 적에게 바로)
		var a: Dictionary = st.allies[who]
		if a.counter and not a.down and e.alive:
			var cv := int(D().traits.hero.counter)
			ev.append({"t": "counter", "ally": who, "enemy": e.id})
			_hit_enemy(st, e, cv, who, "", ev)
			if alive_main(st).is_empty():
				st.result = "win"
				ev.append({"t": "win"})
				return
			if not e.alive:
				return


static func _hit_ally(st: Dictionary, ally_id: String, v: int, by: String, ev: Array) -> void:
	var a: Dictionary = st.allies[ally_id]
	var blk := mini(int(a.block), v)
	a.block = int(a.block) - blk
	var dmg := v - blk
	a.hp = maxi(0, int(a.hp) - dmg)
	ev.append({"t": "allyHit", "ally": ally_id, "enemy": by, "amount": dmg, "blocked": blk, "hp": a.hp, "block": a.block})
	# 버팀: 막아낸 피해만큼 쌓인다(최대)
	if a.trait == "brace" and blk > 0:
		a.brace = mini(int(D().traits.brace.max), int(a.brace) + blk)
		ev.append({"t": "brace", "ally": ally_id, "brace": a.brace})
	# 조준: 엘리안이 피해를 받으면 배율 -1
	if a.trait == "aim" and dmg > 0 and int(a.mult) > 1:
		a.mult = int(a.mult) - 1
		ev.append({"t": "mult", "ally": ally_id, "mult": a.mult})
	if int(a.hp) <= 0 and not a.down:
		a.down = true
		ev.append({"t": "allyDown", "ally": ally_id})


## 빈칸 공격: 노엘이 맞는다(막기 없음). 0 이면 그 자리에서 패배
static func _hit_noel(st: Dictionary, v: int, by: String, col: int, ev: Array) -> void:
	st.noelHp = maxi(0, int(st.noelHp) - v)
	ev.append({"t": "noelHit", "enemy": by, "col": col, "amount": v, "hp": st.noelHp})
	if int(st.noelHp) <= 0:
		_lose(st, "noel", ev)


## 죽음 카드: 그 동료가 칸에 있으면 죽는다(이 전투에서 돌아오지 않음). 벤치에 있으면 기다린다(그 뒤로는 낸 적이 쓰러져도 남는다)
static func _resolve_deaths(st: Dictionary, ev: Array) -> void:
	for dd in st.deaths.duplicate():
		var a: Dictionary = st.allies[dd.ally]
		if a.dead:
			st.deaths.erase(dd)
			continue
		if col_of(st, dd.ally) >= 0:
			st.deaths.erase(dd)
			a.hp = 0
			a.block = 0
			a.dead = true
			a.down = true
			ev.append({"t": "death", "id": dd.id, "ally": dd.ally, "label": dd.label})
		else:
			dd.bound = false
			ev.append({"t": "deathWait", "id": dd.id, "ally": dd.ally})


static func _cleanup(st: Dictionary, ev: Array) -> void:
	for id in st.order:
		var a: Dictionary = st.allies[id]
		a.block = 0
		a.blessed = false
		a.counter = false
		for p in a.placed:
			st.discard.append(p.uid)
		a.placed = []
	for n in st.noel:
		st.discard.append(n.uid)
	st.noel = []
	for u in st.hand:
		st.discard.append(u)
	st.hand = []
	for e in st.enemies:
		e.intent = null
		e.vuln = false
	ev.append({"t": "cleanup"})


## 전투가 끝날 때 남은 죽음 카드 → 결과 판 「운명이 미뤄졌다」
static func postponed(st: Dictionary) -> Array:
	return st.deaths.map(func(d): return d.label)


# ───────── 미리 보기 (놓을 때·놓은 뒤 결과 숫자) ─────────
## 이번 턴에 놓은 카드가 턴 끝에 낼 결과 — 상태를 복사해 동료 행동만 미리 돌린다(난수 없음).
## 반환 {uid: {dmg, target, block, counter, mult}} — 적이 먼저 다 쓰러져 하지 못하는 카드는 빠진다
static func forecast(st: Dictionary) -> Dictionary:
	var s: Dictionary = st.duplicate(true)
	var ev := []
	_ally_phase(s, ev)
	var out := {}
	for e in ev:
		var u := str(e.get("uid", ""))
		if u == "":
			continue
		var r: Dictionary = out.get(u, {})
		match str(e.t):
			"act":
				pass
			"hit":
				r.dmg = int(r.get("dmg", 0)) + int(e.amount)
				r.target = e.enemy
			"block":
				r.block = int(r.get("block", 0)) + int(e.amount)
				if e.get("counter", false):
					r.counter = int(D().traits.hero.counter)
			"mult":
				r.mult = int(e.mult)
		out[u] = r
	return out


## 그 카드를 그 동료 칸에 놓으면 나올 결과(끄는 동안 미리 보기). 공격은 그 열의 앞 적(9-6) — r.target
static func forecast_place(st: Dictionary, uid: String, ally_id: String) -> Dictionary:
	var s: Dictionary = st.duplicate(true)
	if not place(s, uid, ally_id).ok:
		return {}
	return forecast(s).get(uid, {})


# ───────── 자동 진행 (헤드리스 시험 --battle=v2 --autoplay) ─────────
## 다음 한 수: {kind: "place", uid, ally, opts} · {kind: "cast", uid, target, opts} · {kind: "move", ally, to} · {kind: "end"}(턴 끝)
## 판단(지시서 7장 "가장 위험한 칸 막기 → 남은 에너지로 공격" + v2.1 간단한 판단):
##   ⓪ 죽음 카드가 칸에 선 동료를 노리면: 운명 찢기 → 없으면 그 동료를 벤치로(에너지 1). 빈칸을 노린 공격이 있고 벤치에 넣을 동료가 있으면 넣는다
##   ① 가장 위험한 동료(받을 피해 − 놓은 막기)에게 막기 → 막기가 없으면 저주(그 칸의 가장 센 행동) → 운명 전가(가장 버틸 동료에게)
##      노엘이 이번 적 턴에 쓰러질 만큼 맞으면 그 공격을 저주·운명 전가(살아 있는 동료 칸으로)
##   ② 공격: 성검 베기 세라피나 · 겨누기를 쌓고 저격 엘리안 · 버팀이 쌓였으면 되돌리기 브룬힐드 · 베기는 세라피나(용사 막기) → 아무나
##   ③ 취약: 가장 큰 공격이 들어갈 적 · 축복: 가장 큰 행동을 하는 동료 ④ 남은 막기·겨누기
static func auto_step(st: Dictionary) -> Dictionary:
	if st.result != null:
		return {"kind": "end"}
	var hb := {}
	for u in st.hand:
		if affordable(st, u):
			var cid: String = st.cards[u].id
			if not hb.has(cid):
				hb[cid] = u
	var mc := int(D().rules.moveCost)
	# ⓪ 죽음 카드
	for dd in st.deaths:
		if col_of(st, dd.ally) >= 0 and not st.allies[dd.ally].dead:
			if hb.has("tear"):
				return {"kind": "cast", "uid": hb.tear, "target": dd.id, "opts": {}}
			if int(st.energy) >= mc and can_move(st, dd.ally, "bench").ok:
				return {"kind": "move", "ally": dd.ally, "to": "bench"}
	if int(st.energy) >= mc:
		for c in ncols():
			if ally_at(st, c) == "" and incoming(st, c) > 0:
				for b in st.bench:
					if not st.allies[b].down and deaths_of(st, b).is_empty() and can_move(st, b, c).ok:
						return {"kind": "move", "ally": b, "to": c}
	if int(st.energy) <= 0 or st.hand.is_empty() or hb.is_empty():
		return {"kind": "end"}
	var free := living_allies(st).filter(func(id): return room(st, id) > 0)
	var fc := forecast(st)
	# ① 노엘이 쓰러질 만큼 맞으면
	var noel_in := 0
	var noel_hits := []
	for c in ncols():
		if receiver(st, c) == "noel":
			noel_in += incoming(st, c)
			noel_hits.append_array(intents_at(st, c))
	if noel_in >= int(st.noelHp) and not noel_hits.is_empty():
		var big := _biggest(st, noel_hits)
		if hb.has("shift"):
			var dests := shift_dests(st, big).filter(func(c): return receiver(st, c) != "noel")
			var to := _sturdiest(st, dests.map(func(c): return ally_at(st, c)), act_value(enemy(st, big).intent), fc)
			if to != "":
				return {"kind": "cast", "uid": hb.shift, "target": big, "opts": {"to": col_of(st, to)}}
		if hb.has("curse") and int(enemy(st, big).intent.minus) == 0:
			return {"kind": "cast", "uid": hb.curse, "target": big, "opts": {}}
	# ① 가장 위험한 동료
	var worst := ""
	var wk := 0.0
	for id in living_allies(st):
		var d := _danger(st, id, fc)
		if d <= 0:
			continue
		var k := float(d) / maxf(1.0, float(st.allies[id].hp)) + (10.0 if d >= int(st.allies[id].hp) else 0.0)
		if k > wk:
			wk = k
			worst = id
	if worst != "":
		if hb.has("guard") and free.has(worst):
			return {"kind": "place", "uid": hb.guard, "ally": worst, "opts": {}}
		var mine := intents_at(st, col_of(st, worst))
		if hb.has("curse"):
			var cands := mine.filter(func(eid): return int(enemy(st, eid).intent.minus) == 0)
			var sw = sweep_enemy(st)
			if cands.is_empty() and sw != null and int(sw.intent.minus) == 0:
				cands = [sw.id]
			if not cands.is_empty():
				return {"kind": "cast", "uid": hb.curse, "target": _biggest(st, cands), "opts": {}}
		if hb.has("shift") and not mine.is_empty():
			var eid := _biggest(st, mine)
			var dests2 := shift_dests(st, eid).filter(func(c): return receiver(st, c) != "noel")
			var to2 := _sturdiest(st, dests2.map(func(c): return ally_at(st, c)), act_value(enemy(st, eid).intent), fc)
			if to2 != "":
				return {"kind": "cast", "uid": hb.shift, "target": eid, "opts": {"to": col_of(st, to2)}}
	# ② 공격
	if hb.has("holy") and free.has("hero") and _front_ok(st, fc, "hero", hb.holy):
		return {"kind": "place", "uid": hb.holy, "ally": "hero", "opts": {}}
	if free.has("archer"):
		var slots: int = room(st, "archer")
		var aimed := _placed_ids(st, "archer").has("aim")
		var will_mult: int = int(st.allies.archer.mult) + _placed_ids(st, "archer").count("aim")
		if hb.has("aim") and hb.has("snipe") and slots >= 2 and int(st.energy) >= 2 and will_mult < int(D().traits.aim.max):
			return {"kind": "place", "uid": hb.aim, "ally": "archer", "opts": {}}
		if hb.has("snipe") and (aimed or int(st.allies.archer.mult) >= 2 or not hb.has("aim")) and _front_ok(st, fc, "archer", hb.snipe):
			return {"kind": "place", "uid": hb.snipe, "ally": "archer", "opts": {}}
	if hb.has("revert") and free.has("warrior") and int(st.allies.warrior.brace) >= 6 and _front_ok(st, fc, "warrior", hb.revert):
		return {"kind": "place", "uid": hb.revert, "ally": "warrior", "opts": {}}
	if hb.has("slash"):
		for id in ["hero", "warrior", "archer"]:
			if free.has(id) and _front_ok(st, fc, id, hb.slash):
				return {"kind": "place", "uid": hb.slash, "ally": id, "opts": {}}
	# ③ 취약 · 축복
	if hb.has("vuln"):
		var best := ""
		var bd := 0
		var per := {}
		for u in fc:
			if fc[u].has("target"):
				per[fc[u].target] = int(per.get(fc[u].target, 0)) + int(fc[u].get("dmg", 0))
		for eid in per:
			var e = enemy(st, eid)
			if e != null and e.alive and not e.vuln and int(per[eid]) > bd:
				bd = int(per[eid])
				best = eid
		if best != "" and bd >= 6:
			return {"kind": "cast", "uid": hb.vuln, "target": best, "opts": {}}
	if hb.has("bless"):
		var who := ""
		var bv := 0
		for id in living_allies(st):
			if st.allies[id].blessed:
				continue
			var v := 0
			for p in st.allies[id].placed:
				var r: Dictionary = fc.get(p.uid, {})
				v += int(r.get("dmg", 0)) + int(r.get("block", 0))
			if v > bv:
				bv = v
				who = id
		if who != "" and bv >= 6:
			return {"kind": "cast", "uid": hb.bless, "target": who, "opts": {}}
	# ④ 남은 막기 · 겨누기
	if hb.has("guard"):
		for id in free:
			if _danger(st, id, fc) > 0:
				return {"kind": "place", "uid": hb.guard, "ally": id, "opts": {}}
	if hb.has("aim") and free.has("archer") and int(st.allies.archer.mult) < int(D().traits.aim.max):
		return {"kind": "place", "uid": hb.aim, "ally": "archer", "opts": {}}
	return {"kind": "end"}


static func _placed_ids(st: Dictionary, ally_id: String) -> Array:
	return st.allies[ally_id].placed.map(func(p): return st.cards[p.uid].id)


## 이번 적 턴에 받을 피해 − 놓아 둔 막기(미리 보기 결과). 벤치의 동료는 0
static func _danger(st: Dictionary, ally_id: String, fc: Dictionary) -> int:
	var c := col_of(st, ally_id)
	if c < 0:
		return 0
	var inc := incoming(st, c)
	var blk := 0
	for p in st.allies[ally_id].placed:
		blk += int(fc.get(p.uid, {}).get("block", 0))
	return inc - blk


static func _biggest(st: Dictionary, eids: Array) -> String:
	var best := ""
	var bv := -1
	for eid in eids:
		var v := act_value(enemy(st, eid).intent)
		if v > bv:
			bv = v
			best = eid
	return best


## 그 피해를 더 맞고도 HP 가 가장 많이 남는 동료 ("" = 모두 쓰러짐)
static func _sturdiest(st: Dictionary, ids: Array, add: int, fc: Dictionary) -> String:
	var best := ""
	var bl := 0
	for id in ids:
		var left := int(st.allies[id].hp) - maxi(0, _danger(st, id, fc) + add)
		if left > bl:
			bl = left
			best = id
	return best


## 9-6: 그 동료의 앞 적이 있고, 이번 턴에 맡긴 공격을 빼고도 HP 가 남는가(놓을 수 있는가도 — 헛친 공격을 쌓지 않게). 자리 바꾸기로 앞 적 고르기는 하지 않는다
static func _front_ok(st: Dictionary, fc: Dictionary, ally_id: String, uid: String) -> bool:
	if not can_place(st, uid, ally_id).ok:
		return false
	var e = front_of(st, ally_id, uid)
	if e == null:
		return false
	var planned := 0
	for u in fc:
		if str(fc[u].get("target", "")) == str(e.id):
			planned += int(fc[u].get("dmg", 0))
	return int(e.hp) - planned > 0
