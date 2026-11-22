## rules_v2.gd — 전투 시험판 v2 「맡기기」 + v2.1 「3D 탁자」 규칙 (docs/battle-v2-spec.md 3~6장 · 9-2). 화면과 따로 → 헤드리스 시험(tests/test_rules_v2.gd).
## 노엘이 손패의 카드를 동료 칸(③)에 놓아 일을 맡긴다. 노엘 자신의 카드는 칸이 없어 ② 적 행동 카드·① 적·④ 동료에 직접 놓는다.
## 적의 다음 행동 카드(②)는 노리는 **칸**에 놓인다(v2.1: 칸 기준 — 빈칸도 노린다. 빈칸 공격은 노엘이 맞는다). 같은 카드라도 맡은 동료의 특성(용사·버팀·조준)이 붙는다.
## 턴 끝에 한꺼번에: 왼쪽 칸부터 ③ 의 카드대로 동료가 행동 → 살아 있는 적·하수인의 ② 가 그 칸에(동료 또는 노엘) → 죽음 카드 처리 → 막기·축복·취약은 사라지고 손패는 버린다.
## v2.1: 출전 배치(phase "formation" — 칸 3개·벤치에 공짜로) → 전투 중 내 턴에 행동 에너지 1 로 자리 바꾸기·빼기·넣기.
##       무덤지기의 3번째 행동 = 「세라피나의 죽음」(막기·저주로 줄지 않음, 그 동료가 칸에 있으면 죽음). 노엘 「운명 찢기」(에너지 3)로 없앤다.
## 수치·카드는 data/battle_v2_data.gd. 난수는 지금 규칙과 같은 mulberry32(Rules.rnd)를 이 상태의 st.rng 로 돌린다 → 같은 시드면 같은 전투.
## 밤샘 계획 2 A·B(게임 연결): 전투 구성(encounters — 시험 전투 test · 1층 normal/prayer/gravekeeper/deep/giant)을 st.enc 로 고른다.
##   게임(Ctl)은 battle_opts() 로 파티(HP·죽음)·덱(st.party.deck2)·직전 출전 배치·이어 가는 난수·어둠을 넘기고, 끝나면 apply_result() 로 돌려 적는다.
##   카드 레벨(Lv2) · 낼 수 없는 카드(상처) · 노엘 HP 대가(유품·이름 없는 마녀의 카드) · 턴 끝에 노엘 카드(짓밟힘·부적) · 어둠(적 행동 카드 몇 장을 뒷면으로)
##   · 거대한 발(세 칸을 덮는 큰 적, 흠집만, 턴마다 정해진 행동, 3턴 「세라피나의 죽음」 — 옮길 수 없음·찢을 수 없음·벤치에 있어도 맞음 → 물러남)
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
##   st.enc · st.darkness · st.victims   전투 구성 id · 어둠 단계 · 발이 짓밟은 적(giant)
##   st.cards {uid: {uid, id, lv, src}}  lv: 카드 레벨(Lv2) · src: 게임 덱(deck2)의 몇 번째 카드 · st.exhaust [uid] 이 전투에서 사라진 카드(전투마다 한 번)
##   st.allies {id: {id, trait, hp, maxHp, block, down, dead, placed: [{uid, target}], brace, mult, blessed, counter}}
##       placed: ③ 줄에 맡긴 카드(놓은 순서) · target: 놓을 때의 앞 적 id(보여 주기용 — 턴 끝에 그 열의 앞 적으로 다시 셈, 9-6) · dead: 죽음 카드로 죽음(down 도 true)
##       brace: 브룬힐드 버팀(전투 내내) · mult: 엘리안 배율(×1~×4, 전투 내내) · blessed: 이번 턴 축복 · counter: 이번 적 턴에 반격(세라피나가 막기를 맡음)
##   st.enemies [{id, type, tag, of, col, hp, maxHp, alive, vuln, intent, acts}]   (BattleV2Data.lineup 순서 = 행동 순서)
##       of: 하수인이면 그 강적 id (하수인은 처음에 alive=false — 강적이 부르면 나온다) · col: ① 줄의 칸 · vuln: 이번 턴 취약 · acts: 지금까지 정한 행동 수
##       intent: 다음 적 턴의 행동(②) {kind: "hit"|"sweep"|"summon"|"death"|"none", label, value, minus(저주), slot: 노리는 칸 0~2 | "all" | "", death: 죽음 카드 id,
##               hidden(어둠 — 뒷면), erased(이름 없는 마녀의 카드로 없앰)}
##   st.deaths [{id, ally, src, bound, label, fixed}]   죽음 카드. bound: 아직 낸 적의 ② 행동(그 적이 쓰러지면 사라짐) — 한 번 기다리면 false(동료를 따라감)
##       fixed: 옮길 수 없음·찢을 수 없음, 그 동료가 벤치에 있어도 맞는다(1층 거대한 발 — 튜토리얼이라 피할 수 없다)
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
## seed: 시험 전투의 시드. opts(게임 연결 — battle_opts): enc(전투 구성 id) · rng(이어 가는 난수) · allies {id: {hp, maxHp, dead}} · noelHp · noelMax
##   · deck [{id, lv}](게임 덱 deck2) · formation [동료 id | ""] × 3(직전 출전 배치) · darkness(어둠 단계). opts 가 없으면 시험 전투(지금과 같음)
static func new_battle(seed = null, opts := {}) -> Dictionary:
	var d := D()
	var enc_id := str(opts.get("enc", "test"))
	var E: Dictionary = d.encounters.get(enc_id, d.encounters.test)
	var sd: int = (randi() % 1000000000) if seed == null else (int(seed) & Rules.M32)
	var rng: int = (int(opts.rng) & Rules.M32) if opts.has("rng") else sd
	var noel_max := int(opts.get("noelMax", d.rules.noelHp))
	var st := {"seed": sd, "rng": rng if rng != 0 else 1, "nextUid": 1, "turn": 0, "energy": 0, "result": null, "loseBy": "", "phase": "formation",
		"enc": enc_id, "darkness": int(opts.get("darkness", 0)), "victims": [],
		"cards": {}, "draw": [], "hand": [], "discard": [], "exhaust": [], "order": d.order.duplicate(), "slots": [], "bench": [],
		"noelHp": int(opts.get("noelHp", noel_max)), "noelMax": noel_max, "allies": {}, "enemies": [], "noel": [], "deaths": [], "nextDeath": 1}
	var party: Dictionary = opts.get("allies", {})
	for id in st.order:
		var a: Dictionary = d.allies[id]
		var pa: Dictionary = party.get(id, {})
		var dead := bool(pa.get("dead", false))
		var mx := int(pa.get("maxHp", a.hp))
		var hp := 0 if dead else maxi(1, mini(mx, int(pa.get("hp", mx))))
		st.allies[id] = {"id": id, "trait": a.trait, "hp": hp, "maxHp": mx, "block": 0, "down": dead, "dead": dead, "placed": [],
			"brace": 0, "mult": 1, "blessed": false, "counter": false}
	# 출전 배치: 넘겨받은 배치(직전 전투) → 없으면 기본. 죽은 동료는 칸에 서지 못한다(벤치)
	var form: Array = opts.get("formation", d.formation)
	for c in ncols():
		var fid := str(form[c]) if c < form.size() else ""
		st.slots.append(fid if fid != "" and st.allies.has(fid) and not st.allies[fid].dead and not st.slots.has(fid) else "")
	if living_allies(st).is_empty():
		st.slots = []
		for fid in d.formation:
			st.slots.append(fid if not st.allies[fid].dead else "")
	for id in st.order:
		if not st.slots.has(id):
			st.bench.append(id)
	for l in E.get("lineup", d.lineup):
		var t: Dictionary = d.enemies[l.type]
		var minion := str(l.get("of", "")) != ""
		var mhp := int(l.get("hp", t.hp))
		st.enemies.append({"id": l.id, "type": l.type, "tag": str(l.get("tag", "")), "of": str(l.get("of", "")), "col": int(l.get("col", 0)),
			"hp": 0 if minion else mhp, "maxHp": mhp, "alive": not minion, "vuln": false, "intent": null, "acts": 0, "pn": 0})
	var specs: Array = opts.get("deck", [])
	if not opts.has("deck"):
		for pair in d.deck:
			for i in int(pair[1]):
				specs.append({"id": str(pair[0]), "lv": 1})
	for i in specs.size():
		var uid := "v" + str(st.nextUid)
		st.nextUid = int(st.nextUid) + 1
		st.cards[uid] = {"uid": uid, "id": str(specs[i].id), "lv": int(specs[i].get("lv", 1)), "src": i}
		st.draw.append(uid)
	Rules.shuffle(st, st.draw)
	return st


## 이 전투의 구성(BattleV2Data.encounters) — 시험 전투는 "test"
static func enc_def(st: Dictionary) -> Dictionary:
	return D().encounters.get(str(st.get("enc", "test")), D().encounters.test)


## 카드 정의(레벨 반영): Lv2 면 up 의 값으로 덮고 이름 뒤에 「Lv2」
static func def_of(id: String, lv := 1) -> Dictionary:
	var d: Dictionary = D().cards[id]
	if lv < 2 or not D().up.has(id):
		return d
	var o := d.duplicate()
	for k in D().up[id]:
		if k != "summary":
			o[k] = D().up[id][k]
	o.name = str(d.name) + " Lv2"
	return o


## 카드 글의 {n}: 피해 · 막기 · 저주 · 회복 중 그 카드에 있는 값
static func card_n(d: Dictionary) -> int:
	for k in ["damage", "block", "minus", "heal"]:
		if d.has(k):
			return int(d[k])
	return 0


## 손패·카드 고르기·카드 획득 화면의 앞면(BoardPieces.draw_face kind mine) — 특성·버프 없이 카드 그대로
static func mine_face(d: Dictionary) -> Dictionary:
	return {"kind": "mine", "name": str(d.name), "cost": int(d.cost), "owner": str(d.owner), "art": str(d.art), "dark": bool(d.get("dark", false)),
		"text": str(d.text).replace("{n}", str(card_n(d)))}


## 이길 수 없는 큰 적인가(거대한 발 — 흠집만)
static func immune(e: Dictionary) -> bool:
	return bool(D().enemies[e.type].get("immune", false))


## 세 칸을 덮는 큰 적(모든 칸의 앞 적)
static func wide(e: Dictionary) -> bool:
	return bool(D().enemies[e.type].get("wide", false))


static func _no_lose(st: Dictionary) -> bool:
	return bool(enc_def(st).get("noLose", false))

# ───────── 조회 ─────────
static func card_def(st: Dictionary, uid: String) -> Dictionary:
	var c: Dictionary = st.cards[uid]
	return def_of(str(c.id), int(c.get("lv", 1)))


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


## 9-6(사용자 결정): 그 칸(열)의 동료가 치는 앞 적 — 같은 열의 살아 있는 적. 하수인이 있으면 하수인이 먼저(pierce = 저격: 넘어 그 열 본체). 없으면 null
static func front(st: Dictionary, col: int, pierce := false):
	var main = null
	var guard = null
	for e in st.enemies:
		if e.alive and (int(e.col) == col or wide(e)):
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
	if bool(it.get("erased", false)):
		return 0
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
	return st.result == null and st.phase == "battle" and st.hand.has(uid) and int(card_def(st, uid).cost) <= int(st.energy) \
		and not bool(card_def(st, uid).get("unplayable", false))


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
	# 튜토리얼: 그 턴에 먼저 뽑는 카드(encounters.hands) — 뽑을 더미에 있으면 맨 위로
	var want: Array = enc_def(st).get("hands", {}).get(str(st.turn), [])
	if not want.is_empty():
		var picked := []
		for id in want:
			for u in st.draw:
				if not picked.has(u) and str(st.cards[u].id) == str(id):
					picked.append(u)
					break
		for u in picked:
			st.draw.erase(u)
		st.draw = picked + st.draw
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


## 적 행동: 광신도 찌르기 min~max · 무덤지기 하수인이 없으면 부르기, 있으면 공격 · 해골 병사 녹슨 칼 — 한 명 공격은 칸 하나(무작위, 빈칸 포함).
## sweepEvery 턴마다 살아 있는 광신도 하나는 휩쓸기 → 모든 칸. 시험 전투: 무덤지기의 death.at 번째 행동은 죽음 카드(그 동료가 살아 있으면)
## 전투 구성(encounters)마다: hit(피해 범위) · script(튜토리얼 — 그 턴의 정해진 행동) · pattern(강적의 차례 공격) · turns(거대한 발) · 어둠(뒷면)
static func roll_intents(st: Dictionary, ev := []) -> void:
	var E := enc_def(st)
	var live := any_living(st) or _no_lose(st)
	var DT: Dictionary = D().death
	var sc: Dictionary = E.get("script", {}).get(str(st.turn), {})
	for e in st.enemies:
		e.intent = null
		if not e.alive or not live:
			continue
		e.acts = int(e.get("acts", 0)) + 1
		var acts: Dictionary = D().enemies[e.type].acts
		# 거대한 발: 턴마다 정해진 행동(encounters.turns — 마지막이 되풀이)
		if E.has("turns") and wide(e):
			var tl: Array = E.turns
			var step: Dictionary = tl[clampi(int(st.turn), 1, tl.size()) - 1]
			var k := str(step.kind)
			if k == "death" and not st.allies[str(step.ally)].dead and deaths_of(st, str(step.ally)).is_empty():
				_new_death(st, e, str(step.ally), bool(step.get("fixed", false)), ev, str(acts.get("death", {}).get("label", "")))
				continue
			if k == "sweep":
				e.intent = {"kind": "sweep", "label": str(acts.sweep.label), "value": int(step.get("value", 0)), "minus": 0, "slot": "all"}
			else:
				e.intent = {"kind": "none", "label": str(acts.none.label), "sub": str(acts.none.get("sub", "")), "value": 0, "minus": 0, "slot": 1}
			continue
		if bool(E.get("death", false)) and e.type == str(DT.enemy) and int(e.acts) == int(DT.at) and not st.allies[str(DT.ally)].down and deaths_of(st, str(DT.ally)).is_empty():
			_new_death(st, e, str(DT.ally), false, ev)
			continue
		if acts.has("summon") and guard_of(st, e.id) == null:
			e.intent = {"kind": "summon", "label": acts.summon.label, "value": 0, "minus": 0, "slot": ""}
			continue
		var pat: Array = E.get("pattern", {}).get(e.type, [])
		if not pat.is_empty():
			var p: Dictionary = pat[int(e.get("pn", 0)) % pat.size()]
			e.pn = int(e.get("pn", 0)) + 1
			var ps := _highest_col(st) if str(p.get("target", "")) == "highest" else -1
			if ps < 0:
				ps = Rules.rint(st, ncols())
			e.intent = {"kind": "hit", "label": str(p.label), "value": int(p.value), "minus": 0, "slot": ps}
			continue
		var h: Dictionary = acts.hit
		var hv: Dictionary = E.get("hit", {}).get(e.type, h)
		var v := int(hv.get("value", 0))
		if hv.has("min"):
			v = int(hv.min) + Rules.rint(st, int(hv.max) - int(hv.min) + 1)
		var slot := Rules.rint(st, ncols())
		if sc.has(e.id):   # 튜토리얼: 그 턴의 정해진 행동(매번 같은 흐름)
			v = int(sc[e.id].get("value", v))
			slot = int(sc[e.id].get("slot", slot))
		e.intent = {"kind": "hit", "label": h.label, "value": v, "minus": 0, "slot": slot}
	var every := int(E.get("sweepEvery", 0))
	if every > 0 and int(st.turn) % every == 0 and live:
		var sw: Array = st.enemies.filter(func(e): return e.alive and e.intent != null and e.intent.kind == "hit" and D().enemies[e.type].acts.has("sweep"))
		if not sw.is_empty():
			var se: Dictionary = sw[Rules.rint(st, sw.size())]
			var s: Dictionary = D().enemies[se.type].acts.sweep
			se.intent = {"kind": "sweep", "label": s.label, "value": int(s.value), "minus": 0, "slot": "all"}
	_apply_darkness(st)


## 죽음 카드를 낸다(그 동료 칸 ②). fixed: 옮길 수 없음·찢을 수 없음·벤치에 있어도 맞음(낸 적이 쓰러져도 남는다)
static func _new_death(st: Dictionary, e: Dictionary, who: String, fixed: bool, ev: Array, sub := "") -> void:
	var did := "death" + str(st.nextDeath)
	st.nextDeath = int(st.nextDeath) + 1
	var lab := death_label(who)
	st.deaths.append({"id": did, "ally": who, "src": e.id, "bound": not fixed, "label": lab, "fixed": fixed})
	e.intent = {"kind": "death", "label": lab, "value": 0, "minus": 0, "slot": "", "death": did, "sub": sub}
	ev.append({"t": "deathCard", "id": did, "ally": who, "enemy": e.id})


## HP 가 가장 많은(칸에 선, 살아 있는) 동료의 칸 (-1 = 없음) — 강적의 「짓누르기」(옛 target highest)
static func _highest_col(st: Dictionary) -> int:
	var best := -1
	var bh := -1
	for c in ncols():
		var id := ally_at(st, c)
		if id != "" and not st.allies[id].down and int(st.allies[id].hp) > bh:
			bh = int(st.allies[id].hp)
			best = c
	return best


## 어둠(촛불이 다 탄 뒤 — 옛 규칙의 '예고를 ?로 가림'): 어둠 단계만큼 적 행동 카드(한 명 공격·휩쓸기)를 뒷면으로. 규칙은 그대로 적용된다
static func _apply_darkness(st: Dictionary) -> void:
	var n := int(st.get("darkness", 0))
	if n <= 0:
		return
	var cands := []
	for e in st.enemies:
		if e.alive and e.intent != null and str(e.intent.kind) in ["hit", "sweep"]:
			cands.append(e)
	Rules.shuffle(st, cands)
	for i in mini(n, cands.size()):
		cands[i].intent.hidden = true

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
	if bool(c.get("unplayable", false)):
		return _no("unplayable")
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
	if bool(c.get("unplayable", false)):
		return _no("unplayable")
	if str(c.owner) != "noel":
		return _no("notNoel")
	if int(c.cost) > int(st.energy):
		return _no("noEnergy")
	match str(c.kind):
		"shift":
			var dd = death(st, target)
			if dd != null and bool(dd.get("fixed", false)):
				return _no("fixed")
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
			var dt = death(st, target)
			if dt == null:
				return _no("notDeath")
			if bool(dt.get("fixed", false)):
				return _no("fixed")
		"erase":
			if death(st, target) != null:
				return _no("death")
			var e4 = enemy(st, target)
			if e4 == null or not e4.alive or e4.intent == null or not e4.intent.kind in ["hit", "sweep"]:
				return _no("badAct")
			if bool(e4.intent.get("erased", false)):
				return _no("erased")
		"stomp":
			var e5 = enemy(st, target)
			if e5 == null or not e5.alive:
				return _no("badEnemy")
		"heal":
			if not st.allies.has(target) or st.allies[target].down:
				return _no("badAlly")
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
		if bool(dd.get("fixed", false)):
			return out
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
		"erase":
			enemy(st, target).intent.erased = true
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
		"erase":
			var e6 = enemy(st, str(n.target))
			if e6 != null and e6.intent != null:
				e6.intent.erase("erased")
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
	_noel_phase(st, ev)
	if st.result == null:
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
	if _no_lose(st):
		return   # 거대한 발(튜토리얼 사건): 지지 않는다 — 3턴에 끝난다
	st.result = "lose"
	st.loseBy = by
	ev.append({"t": "lose", "by": by})


## 노엘의 카드 중 턴 끝에 처리되는 것(짓밟힘: 모든 적에게 · 부적: 회복)과 노엘 HP 대가(이름 없는 마녀의 카드) — 동료보다 먼저
static func _noel_phase(st: Dictionary, ev: Array) -> void:
	for n in st.noel:
		if st.result != null:
			return
		var c := card_def(st, n.uid)
		match str(c.kind):
			"stomp":
				ev.append({"t": "noelAct", "uid": n.uid, "card": st.cards[n.uid].id})
				for e in st.enemies.duplicate():
					if e.alive and st.result == null:
						_hit_enemy(st, e, int(c.damage), "noel", n.uid, ev)
						_check_end(st, ev)
			"heal":
				var a: Dictionary = st.allies[n.target]
				if not a.down:
					var amt := mini(int(c.heal), int(a.maxHp) - int(a.hp))
					a.hp = int(a.hp) + amt
					ev.append({"t": "heal", "ally": n.target, "amount": amt, "hp": a.hp, "uid": n.uid})
		if int(c.get("noelCost", 0)) > 0:
			_pay_noel(st, int(c.noelCost), n.uid, ev)


## 노엘 HP 를 대가로 낸다(유품·이름 없는 마녀의 카드). 0 이면 패배
static func _pay_noel(st: Dictionary, v: int, uid: String, ev: Array) -> void:
	st.noelHp = maxi(1 if _no_lose(st) else 0, int(st.noelHp) - v)
	ev.append({"t": "noelPay", "amount": v, "hp": st.noelHp, "uid": uid})
	if int(st.noelHp) <= 0:
		_lose(st, "noel", ev)


## 적이 쓰러진 뒤: 이기려면 쓰러뜨릴 적이 모두 쓰러졌으면 승리 · giantAt(가장 깊은 곳)이면 발이 내려온다 — 남은 적이 짓밟혀 사라지고 거대한 발 전투로
static func _check_end(st: Dictionary, ev: Array) -> void:
	if st.result != null:
		return
	var al := alive_main(st)
	if al.is_empty():
		st.result = "win"
		ev.append({"t": "win"})
		return
	var ga := int(enc_def(st).get("giantAt", 0))
	if ga > 0 and al.size() <= ga:
		var vs := []
		for e in al:
			vs.append(e.id)
			_kill(st, e, [], "giant")
		st.victims = vs
		st.result = "giant"
		ev.append({"t": "giant", "victims": vs})


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
	var c := card_def(st, p.uid)
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
			# 유품: 낼 때마다 노엘 HP
			if int(c.get("noelCost", 0)) > 0:
				_pay_noel(st, int(c.noelCost), p.uid, ev)
				if st.result != null:
					return
			# 용사: 공격을 맡으면 막기도
			if a.trait == "hero" and str(c.kind) == "attack":
				var hb := int(tr.attackBlock)
				if a.blessed:
					hb = _pct(hb, int(D().cards.bless.pct))
				a.block = int(a.block) + hb
				ev.append({"t": "block", "ally": ally_id, "amount": hb, "total": a.block, "uid": p.uid})
			_check_end(st, ev)
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
	if immune(e):
		ev.append({"t": "immune", "enemy": e.id, "ally": by, "uid": uid})   # 거대한 발: 흠집만
		return
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
	if bool(it.get("erased", false)):
		ev.append({"t": "enemyAct", "enemy": e.id, "kind": "erased", "slot": it.slot, "value": 0})
		return
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
	if it.kind == "death" or it.kind == "none":
		return   # 죽음 카드는 적 턴 끝에 한꺼번에(_resolve_deaths) · none = 행동 없음(거대한 발의 그림자)
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
			_check_end(st, ev)
			if st.result != null:
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
	st.noelHp = maxi(1 if _no_lose(st) else 0, int(st.noelHp) - v)
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
		if col_of(st, dd.ally) >= 0 or bool(dd.get("fixed", false)):
			st.deaths.erase(dd)
			a.hp = 0
			a.block = 0
			a.dead = true
			a.down = true
			ev.append({"t": "death", "id": dd.id, "ally": dd.ally, "label": dd.label, "fixed": bool(dd.get("fixed", false))})
			# 거대한 발: 세라피나의 죽음 뒤 일행이 물러난다(전투 끝 — 옛 endsBattle)
			var de := str(enc_def(st).get("deathEnds", ""))
			if de != "" and st.result == null:
				st.result = de
				ev.append({"t": de})
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
		if bool(card_def(st, n.uid).get("exhaust", false)):
			st.exhaust.append(n.uid)   # 전투마다 한 번(이름 없는 마녀의 카드)
		else:
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
	_noel_phase(s, ev)
	if s.result == null:
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


# ───────── 자동 진행 (헤드리스 시험 --battle=v2 --autoplay · 난이도 재기 tests/sim_v2.gd) ─────────
## 다음 한 수: {kind: "place", uid, ally, opts} · {kind: "cast", uid, target, opts} · {kind: "move", ally, to} · {kind: "start"}(출전) · {kind: "end"}(턴 끝)
## 밤샘 계획 2 D1 「사람답게」: 사람이 화면에서 보는 것(적 행동 카드가 노리는 칸과 피해 · 놓기 전 결과 미리 보기)만으로 **이번 턴을 내다보고** 고른다.
##   이번 턴에 할 수 있는 수(카드 놓기 · 노엘 카드 · 자리 바꾸기/빼기/넣기)를 몇 갈래로 이어 붙여(빔 탐색 AUTO_BEAM 갈래 · 자리 옮김은 늘 남김),
##   갈래마다 상태를 복사해 턴 끝(동료 행동 → 적 행동 → 죽음 카드)까지 돌려 본 결과를 점수로 매기고, 가장 좋은 갈래의 첫 수를 낸다(_auto_score).
##   → 앞 적이 없으면 자리를 바꿔 앞 적을 고르고 · 노려진 칸에 막기 · 겨누기 → 저격(배율은 점수에 남는다) · 빈칸이 노려지면 동료를 넣어 노엘을 지킨다 —
##     규칙 몇 줄로 정하지 않아도 점수가 그렇게 고르게 된다. 뒷면(어둠)의 피해는 모르는 것으로 쳐서 그 적의 보통 피해로 본다.
##   다음 턴(뽑을 카드·적의 다음 행동)은 보지 않는다(사람도 모른다). 출전 배치: 앞 적이 있는 칸에 센 공격을 쥔 동료(_auto_formation)
## 예전 판단(규칙 몇 줄 — 시험 전투 30판 2승)은 auto_simple 로 남겨 비교한다(서툰 사람 쪽 잣대)
const AUTO_BEAM := 6
const AUTO_DEPTH := 7
const AUTO_MOVES := 2          # 한 턴에 자리를 옮기는 수(에너지 1씩)의 탐색 한도
static var _auto_cache := {}   # 같은 턴의 다음 수: {sig: 다음 상태 sig, plan: 남은 수} — 한 턴에 한 번만 내다본다


static func auto_step(st: Dictionary) -> Dictionary:
	if st.result != null:
		return {"kind": "end"}
	if st.phase == "formation":
		return _auto_formation(st)
	var sig := _auto_sig(st)
	if str(_auto_cache.get("sig", "")) == sig and not (_auto_cache.plan as Array).is_empty():
		return _auto_next(st)
	_auto_cache = {"sig": "", "plan": auto_plan(st)}
	return _auto_next(st)


## 캐시한 갈래의 첫 수를 내고, 그 수를 둔 뒤의 상태 sig 를 적어 둔다(다음 부름에 그 상태면 다시 내다보지 않는다)
static func _auto_next(st: Dictionary) -> Dictionary:
	var plan: Array = _auto_cache.plan
	if plan.is_empty():
		_auto_cache = {}
		return {"kind": "end"}
	var a: Dictionary = plan.pop_front()
	var s2: Dictionary = st.duplicate(true)
	if not _auto_apply(s2, a).ok:
		_auto_cache = {}
		return {"kind": "end"}
	_auto_cache.sig = _auto_sig(s2) if not plan.is_empty() else ""
	return a


## 이번 턴의 가장 좋은 수 목록(빈 목록 = 바로 턴 끝이 가장 낫다)
static func auto_plan(st: Dictionary) -> Array:
	var s0: Dictionary = st.duplicate(true)
	_mask_hidden(s0)
	var best_v := _auto_value(s0)
	var best_path := []
	var beam := [{"s": s0, "path": [], "moved": []}]
	var seen := {_auto_sig(s0): true}
	for _depth in AUTO_DEPTH:
		var kids := []
		for n in beam:
			for a in _auto_actions(n.s, n.moved):
				var s2: Dictionary = n.s.duplicate(true)
				if not _auto_apply(s2, a).ok:
					continue
				var sg := _auto_sig(s2)
				if seen.has(sg):
					continue
				seen[sg] = true
				var path: Array = n.path + [a]
				var v := _auto_value(s2) - 0.05 * path.size()   # 같은 결과면 수가 적은 쪽
				var mv: Array = n.moved + ([str(a.ally)] if a.kind == "move" else [])
				kids.append({"s": s2, "path": path, "v": v, "moved": mv, "isMove": a.kind == "move"})
				if v > best_v + 0.01:
					best_v = v
					best_path = path
		if kids.is_empty():
			break
		kids.sort_custom(func(x, y): return x.v > y.v)
		# 위에서 AUTO_BEAM 갈래 + 자리를 옮긴 갈래는 늘 남긴다(옮기기만으로는 점수가 오르지 않고 다음 수와 함께 오른다)
		var nb := kids.slice(0, AUTO_BEAM)
		for k in kids.slice(AUTO_BEAM):
			if k.isMove:
				nb.append(k)
		beam = nb
	return best_path


## 이 상태에서 둘 수 있는 수(같은 카드 id·레벨은 한 번만). moved: 이번 갈래에서 이미 옮긴 동료(같은 동료를 두 번 옮기지 않는다)
static func _auto_actions(s: Dictionary, moved: Array) -> Array:
	var out := []
	var seen := {}
	for u in s.hand:
		if not affordable(s, u):
			continue
		var key := str(s.cards[u].id) + ":" + str(s.cards[u].get("lv", 1))
		if seen.has(key):
			continue
		seen[key] = true
		var c := card_def(s, u)
		if str(c.owner) != "noel":
			for id in living_allies(s):
				if can_place(s, u, id).ok:
					out.append({"kind": "place", "uid": u, "ally": id, "opts": {}})
			continue
		for tg in _auto_targets(s, u, str(c.kind)):
			if str(c.kind) == "shift":
				for to in shift_dests(s, tg):
					if can_cast(s, u, tg).ok:
						out.append({"kind": "cast", "uid": u, "target": tg, "opts": {"to": to}})
			elif can_cast(s, u, tg).ok:
				out.append({"kind": "cast", "uid": u, "target": tg, "opts": {}})
	if moved.size() < AUTO_MOVES and int(s.energy) >= int(D().rules.moveCost):
		for id in s.order:
			if moved.has(id) or s.allies[id].dead:
				continue
			for to in [0, 1, 2, "bench"]:
				if can_move(s, id, to).ok:
					out.append({"kind": "move", "ally": id, "to": to})
	return out


## 노엘 카드의 대상 후보
static func _auto_targets(s: Dictionary, uid: String, kind: String) -> Array:
	var out := []
	match kind:
		"shift", "curse", "erase":
			for e in s.enemies:
				if e.alive and e.intent != null and str(e.intent.kind) in ["hit", "sweep"]:
					out.append(str(e.id))
			if kind == "shift":
				for d in s.deaths:
					out.append(str(d.id))
		"tear":
			for d in s.deaths:
				out.append(str(d.id))
		"vuln", "stomp":
			for e in s.enemies:
				if e.alive and not immune(e):
					out.append(str(e.id))
					if kind == "stomp":
						break   # 모든 적에게 — 대상 하나로 충분
		"bless", "heal":
			for id in s.order:
				if not s.allies[id].down:
					out.append(str(id))
	return out


static func _auto_apply(s: Dictionary, a: Dictionary) -> Dictionary:
	match str(a.kind):
		"place":
			return place(s, str(a.uid), str(a.ally), a.get("opts", {}))
		"cast":
			return cast(s, str(a.uid), str(a.target), a.get("opts", {}))
		"move":
			return move_ally(s, str(a.ally), a.to)
	return _no("same")


## 상태를 가르는 글자(같은 상태에 다른 순서로 닿은 갈래를 하나로) — 칸 · 벤치 · 맡긴 카드(순서까지 — 겨누기 → 저격) · 노엘 카드 · 에너지
static func _auto_sig(s: Dictionary) -> String:
	var hids: Array = s.hand.map(func(u): return str(s.cards[u].id) + str(s.cards[u].get("lv", 1)))
	hids.sort()
	var parts := [s.seed, s.rng, s.enc, s.turn, s.energy, s.slots, s.bench, hids]
	for id in s.order:
		parts.append(s.allies[id].placed.map(func(p): return str(s.cards[p.uid].id) + str(s.cards[p.uid].get("lv", 1))))
	for n in s.noel:
		parts.append([str(s.cards[n.uid].id), n.target, n.move])
	return var_to_str(parts)


## 어둠: 뒷면 적 행동 카드의 피해는 모른다 → 그 적의 보통 피해로(노리는 칸은 보인다)
static func _mask_hidden(s: Dictionary) -> void:
	for e in s.enemies:
		if e.alive and e.intent != null and bool(e.intent.get("hidden", false)):
			e.intent.value = int(round(_threat(s, e)))


## 이 상태에서 턴을 끝내면(복사본에서 턴 끝까지 돌려) 얼마나 좋은가
static func _auto_value(s: Dictionary) -> float:
	var e: Dictionary = s.duplicate(true)
	end_turn(e)
	return _auto_score(e)


## 그 적이 한 턴에 보통 주는 피해(난이도 판단용 — 전투 구성의 hit·pattern, 없으면 적 행동 표)
static func _threat(s: Dictionary, e: Dictionary) -> float:
	if immune(e):
		return 0.0
	var E := enc_def(s)
	var pat: Array = E.get("pattern", {}).get(e.type, [])
	if not pat.is_empty():
		var t := 0.0
		for p in pat:
			t += float(p.value)
		return t / pat.size()
	var acts: Dictionary = D().enemies[e.type].acts
	var h: Dictionary = E.get("hit", {}).get(e.type, acts.get("hit", {}))
	if h.has("min"):
		return (float(h.min) + float(h.max)) / 2.0
	return float(h.get("value", 0))


## 턴을 끝낸 뒤 상태의 점수: 이김 · 적 HP 와 위협(쓰러뜨리면 다음 턴 피해가 사라짐) · 동료 HP(쓰러짐·죽음은 크게) · 노엘 HP(빈칸은 다음 턴에도 노엘이 맞는다)
##   · 엘리안 배율·브룬힐드 버팀(다음 턴에 쓰는 힘) · 죽음 카드가 기다리는 벤치 동료
static func _auto_score(e: Dictionary) -> float:
	if e.result == "lose":
		return -100000.0 + float(e.turn)
	var v := 0.0
	if str(e.result) in ["win", "giant"]:
		v += 5000.0
	var thr := 0.0
	for en in e.enemies:
		if immune(en) or not en.alive:
			continue
		var t := _threat(e, en)
		thr += t
		v -= float(en.hp) + t * 2.0
	for id in e.order:
		var a: Dictionary = e.allies[id]
		if a.dead:
			v -= 200.0
			continue
		if a.down:
			v -= 30.0 + float(a.maxHp)
			continue
		v += float(a.hp) * 1.5
		if int(a.hp) <= 5:
			v -= float(6 - int(a.hp)) * 2.0
		if a.trait == "aim":
			v += float(int(a.mult) - 1) * 5.0
		elif a.trait == "brace":
			v += float(a.brace) * 0.3
		if col_of(e, id) < 0 and not deaths_of(e, id).is_empty():
			v -= 40.0
	v += float(e.noelHp) * 3.0
	if int(e.noelHp) <= 6:
		v -= float(7 - int(e.noelHp)) * 6.0
	if e.result == null:
		for c in ncols():
			if receiver(e, c) == "noel":
				v -= thr / float(ncols()) * 3.0
	return v


## 출전 배치(사람답게): 앞(같은 열)에 칠 적이 있는 칸에 센 공격을 쥔 동료(세라피나 > 엘리안 > 브룬힐드), 앞 적이 없는 칸에는 브룬힐드.
## 지금 배치와 같은 점수면 그대로(옮기는 수를 줄인다). 다 맞으면 「출전」
static func _auto_formation(st: Dictionary) -> Dictionary:
	var w := {"hero": 3.0, "archer": 2.5, "warrior": 1.0}
	var cands: Array = st.order.filter(func(id): return not st.allies[id].dead)
	var best: Array = st.slots.duplicate()
	var bv := _form_score(st, best, w)
	for perm in _perms(cands, ncols()):
		var v := _form_score(st, perm, w) - 0.01 * _form_diff(st.slots, perm)
		if v > bv + 0.001:
			bv = v
			best = perm
	for c in ncols():
		var want := str(best[c])
		if want != "" and ally_at(st, c) != want and can_move(st, want, c).ok:
			return {"kind": "move", "ally": want, "to": c}
	return {"kind": "start"}


static func _form_score(st: Dictionary, slots: Array, w: Dictionary) -> float:
	var v := 0.0
	for c in ncols():
		var id := str(slots[c])
		if id == "":
			v -= 5.0   # 빈칸은 노엘이 맞는다
			continue
		var f = front(st, c)
		if f != null and not immune(f):
			v += float(w.get(id, 1.0))
	return v


static func _form_diff(a: Array, b: Array) -> int:
	var n := 0
	for i in a.size():
		if str(a[i]) != str(b[i]):
			n += 1
	return n


## ids 에서 n 칸 배치(모자라면 "")를 모두
static func _perms(ids: Array, n: int) -> Array:
	var pool: Array = ids.duplicate()
	while pool.size() < n:
		pool.append("")
	var out := []
	_perm_rec(pool, [], n, out)
	return out


static func _perm_rec(pool: Array, cur: Array, n: int, out: Array) -> void:
	if cur.size() == n:
		out.append(cur.duplicate())
		return
	var used := {}
	for i in pool.size():
		var x = pool[i]
		if used.has(x):
			continue
		used[x] = true
		var rest: Array = pool.duplicate()
		rest.remove_at(i)
		_perm_rec(rest, cur + [x], n, out)


## 예전 판단(규칙 몇 줄 — 2026-11-22 v2.1~밤샘 계획 2 A): 서툰 사람 쪽 비교용(tests/sim_v2.gd --ai=simple). 출전 배치만 _auto_formation 으로 같게
##   ⓪ 죽음 카드가 칸에 선 동료를 노리면: 운명 찢기 → 없으면 그 동료를 벤치로(에너지 1). 빈칸을 노린 공격이 있고 벤치에 넣을 동료가 있으면 넣는다
##   ① 가장 위험한 동료(받을 피해 − 놓은 막기)에게 막기 → 막기가 없으면 저주(그 칸의 가장 센 행동) → 운명 전가(가장 버틸 동료에게)
##      노엘이 이번 적 턴에 쓰러질 만큼 맞으면 그 공격을 저주·운명 전가(살아 있는 동료 칸으로)
##   ② 공격: 성검 베기 세라피나 · 겨누기를 쌓고 저격 엘리안 · 버팀이 쌓였으면 되돌리기 브룬힐드 · 베기는 세라피나(용사 막기) → 아무나
##   ③ 취약: 가장 큰 공격이 들어갈 적 · 축복: 가장 큰 행동을 하는 동료 ④ 남은 막기·겨누기
static func auto_simple(st: Dictionary) -> Dictionary:
	if st.result != null:
		return {"kind": "end"}
	if st.phase == "formation":
		return _auto_formation(st)   # 출전 배치는 같게(처음 하는 사람도 앞 적이 있는 칸에 센 동료를 세운다)
	var hb := {}
	for u in st.hand:
		if affordable(st, u):
			var cid: String = st.cards[u].id
			if not hb.has(cid):
				hb[cid] = u
	var mc := int(D().rules.moveCost)
	# ⓪ 죽음 카드 (피할 수 없는 죽음 — 거대한 발 — 은 그대로 둔다)
	for dd in st.deaths:
		if bool(dd.get("fixed", false)):
			continue
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
		if hb.has("nameless") and int(st.noelHp) > int(card_def(st, hb.nameless).noelCost) and can_cast(st, hb.nameless, big).ok:
			return {"kind": "cast", "uid": hb.nameless, "target": big, "opts": {}}
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
		if hb.has("nameless") and not mine.is_empty() and int(st.noelHp) > 8 and can_cast(st, hb.nameless, _biggest(st, mine)).ok:
			return {"kind": "cast", "uid": hb.nameless, "target": _biggest(st, mine), "opts": {}}
	# 자리 바꾸기로 앞 적 고르기 · 짓밟힘(모든 적)
	var mv := _auto_front_move(st, hb, fc)
	if not mv.is_empty():
		return mv
	if hb.has("trample"):
		var tg := alive_enemies(st).filter(func(e): return not immune(e))
		if not tg.is_empty():
			return {"kind": "cast", "uid": hb.trample, "target": str(tg[0].id), "opts": {}}
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
	for cid in ["slash", "relic_sword"]:
		if not hb.has(cid) or (cid == "relic_sword" and int(st.noelHp) <= 6):
			continue
		for id in ["hero", "warrior", "archer"]:
			if free.has(id) and _front_ok(st, fc, id, hb[cid]):
				return {"kind": "place", "uid": hb[cid], "ally": id, "opts": {}}
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
	# ④ 부적(가장 많이 다친 동료) · 남은 막기 · 겨누기
	if hb.has("charm"):
		var hurt := ""
		var miss := 3
		for id in st.order:
			var ha: Dictionary = st.allies[id]
			if not ha.down and int(ha.maxHp) - int(ha.hp) > miss:
				miss = int(ha.maxHp) - int(ha.hp)
				hurt = id
		if hurt != "":
			return {"kind": "cast", "uid": hb.charm, "target": hurt, "opts": {}}
	if hb.has("guard"):
		for id in free:
			if _danger(st, id, fc) > 0:
				return {"kind": "place", "uid": hb.guard, "ally": id, "opts": {}}
	if hb.has("aim") and free.has("archer") and int(st.allies.archer.mult) < int(D().traits.aim.max):
		return {"kind": "place", "uid": hb.aim, "ally": "archer", "opts": {}}
	return {"kind": "end"}


## 자리 바꾸기로 앞 적 고르기(밤샘 계획 2 — 1층 무덤지기처럼 한 칸에만 적이 있을 때 자동 진행이 막히지 않게, 한 턴에 한 번):
## 센 전용 공격(성검 베기·저격)을 쥔 동료 앞에 칠 적이 없고, 다른 칸에 앞 적이 있는데 그 칸 동료가 전용 공격 카드를 쥐지 않았으면 그 칸으로 옮긴다(에너지 1)
static func _auto_front_move(st: Dictionary, hb: Dictionary, fc: Dictionary) -> Dictionary:
	if int(st.energy) < int(D().rules.moveCost) + 1 or int(st.get("autoMoved", 0)) == int(st.turn):
		return {}
	for pair in [["hero", "holy"], ["archer", "snipe"]]:
		var x: String = pair[0]
		if not hb.has(pair[1]) or col_of(st, x) < 0 or st.allies[x].down or _front_ok(st, fc, x, hb[pair[1]]):
			continue
		for c in ncols():
			if c == col_of(st, x):
				continue
			var e = front(st, c, pair[1] == "snipe")
			if e == null or immune(e):
				continue
			var y := ally_at(st, c)
			if y != "" and not st.allies[y].down and ((y == "hero" and hb.has("holy")) or (y == "archer" and hb.has("snipe"))):
				continue
			if can_move(st, x, c).ok:
				st.autoMoved = int(st.turn)
				return {"kind": "move", "ally": x, "to": c}
	return {}


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


# ───────── 게임 연결 (밤샘 계획 2 A — 1층 전투를 이 규칙으로. core/ctl.gd · core/rules_map.gd 가 부른다) ─────────
## 게임 상태(Rules 의 st)에 이 전투의 덱(st.party.deck2: [{id, lv}])·직전 출전 배치(formation2)가 없으면 만든다
static func init_party(gs: Dictionary) -> void:
	var p: Dictionary = gs.party
	if not p.has("deck2"):
		var dk := []
		for pair in D().gameDeck:
			for i in int(pair[1]):
				dk.append({"id": str(pair[0]), "lv": 1})
		p.deck2 = dk
	if not p.has("formation2"):
		p.formation2 = D().formation.duplicate()


## 전투를 열 때 넘길 것(new_battle opts): 파티 HP·죽음 · 노엘 HP · 덱 · 직전 출전 배치 · 이어 가는 난수 · 어둠 단계
static func battle_opts(gs: Dictionary, enc: String, darkness := 0) -> Dictionary:
	init_party(gs)
	var al := {}
	for id in D().order:
		var a = gs.party.allies.get(id)
		if a != null:
			al[id] = {"hp": int(a.hp), "maxHp": int(a.maxHp), "dead": str(a.status) == "dead"}
	return {"enc": enc, "rng": int(gs.rng), "allies": al, "noelHp": int(gs.party.witch.hp), "noelMax": int(gs.party.witch.maxHp),
		"deck": gs.party.deck2.duplicate(true), "formation": gs.party.formation2.duplicate(), "darkness": darkness}


## 전투가 끝난 뒤(이김·물러남·발이 내려옴) 게임 상태에 돌려 적는다: 동료·노엘 HP, 난수, 출전 배치.
##  · 쓰러진 동료: 옛 규칙처럼 HP 1 로 일어나고 그 동료 카드 1장이 「상처」로 — deck2(이 전투의 덱)와 옛 덱(Rules.finish_battle) 둘 다
##  · 죽은 동료: 옛 운명 받아들임(Rules.offer_fate — 사망·옛 덱 유품·상속·운명 기록) + deck2 의 전용 카드 → 유품, 상속 카드의 짝을 deck2 에
## 반환: 이벤트(옛 규칙의 wound·revive·relicize·allyDeath… + wound2 {ally, from})
static func apply_result(gs: Dictionary, st: Dictionary) -> Array:
	init_party(gs)
	var ev := []
	gs.rng = int(st.rng)
	gs.party.witch.hp = int(st.noelHp)
	gs.party.formation2 = st.slots.duplicate()
	for id in st.order:
		var a2: Dictionary = st.allies[id]
		var pa = gs.party.allies.get(id)
		if pa == null or str(pa.status) == "dead":
			continue
		if a2.dead:
			ev.append_array(ally_died(gs, id))
		elif a2.down:
			pa.hp = 0
			pa.status = "down"
			var w := wound_v2(gs, id)
			if w != "":
				ev.append({"t": "wound2", "ally": id, "from": w})
		else:
			pa.hp = int(a2.hp)
	ev.append_array(Rules.finish_battle(gs))
	return ev


## 동료가 죽었다(1층 거대한 발 — 세라피나의 죽음): 그 동료의 운명이 있으면 옛 규칙대로 받아들임(사망·유품·상속·운명 기록), deck2 도 유품·상속
static func ally_died(gs: Dictionary, id: String) -> Array:
	var ev := []
	var f = Rules.fate_of(gs, id)
	if f != null and gs.cards.has(str(f.card)):
		var inh := str(GameData.D.fates.get(str(f.id), {}).get("inherit", ""))
		var lv := int(f.level)
		ev = Rules.offer_fate(gs, str(f.id))
		var m := str(D().fromV1.get(inh, ""))
		if m != "":
			gs.party.deck2.append({"id": m, "lv": lv})
	else:
		gs.party.allies[id].status = "dead"
		gs.party.allies[id].hp = 0
	relicize_v2(gs, id)
	return ev


## deck2: 죽은 동료의 전용 카드 → 유품(relicMap). 상처는 그대로
static func relicize_v2(gs: Dictionary, id: String) -> void:
	for sp in gs.party.deck2:
		var d: Dictionary = D().cards.get(str(sp.id), {})
		if str(d.get("owner", "")) == id and D().relicMap.has(str(sp.id)):
			sp.id = str(D().relicMap[str(sp.id)])
			sp.lv = 1


## deck2: 쓰러진 동료의 전용 카드 1장(무작위)을 「상처」로. 반환: 바뀐 카드 id ("" = 없음)
static func wound_v2(gs: Dictionary, id: String) -> String:
	var cands := []
	for i in gs.party.deck2.size():
		if str(D().cards.get(str(gs.party.deck2[i].id), {}).get("owner", "")) == id:
			cands.append(i)
	if cands.is_empty():
		return ""
	var k: int = cands[Rules.rint(gs, cands.size())]
	var from := str(gs.party.deck2[k].id)
	gs.party.deck2[k] = {"id": "wound", "lv": 1}
	return from


## 지도의 방에서 옛 카드를 얻었다(MapRules.gain_card): deck2 에 짝 카드(fromV1) — up 이면 Lv2. deck2 가 없는 상태(옛 전투 ?battle=v1)면 아무것도 안 한다
static func gain_from_v1(gs: Dictionary, v1id: String, up := false) -> void:
	var m := str(D().fromV1.get(v1id, ""))
	if m != "" and gs.get("party", {}).has("deck2"):
		gs.party.deck2.append({"id": m, "lv": 2 if up else 1})


## 훈련으로 옛 카드를 강화했다(MapRules.upgrade_card): deck2 의 짝 카드 1장을 Lv2 로
static func upgrade_from_v1(gs: Dictionary, v1id: String) -> void:
	var m := str(D().fromV1.get(v1id, ""))
	if m == "" or not gs.get("party", {}).has("deck2"):
		return
	for sp in gs.party.deck2:
		if str(sp.id) == m and int(sp.get("lv", 1)) < 2:
			sp.lv = 2
			return


## 옛 카드 id → 이 전투의 카드 정의(Lv 반영, id 포함) — 방 화면(카드 획득·좌판·훈련)이 이 전투의 앞면을 그릴 때. 짝이 없으면 {}
static func def_from_v1(v1id: String, up := false) -> Dictionary:
	var m := str(D().fromV1.get(v1id, ""))
	if m == "":
		return {}
	var d := def_of(m, 2 if up else 1).duplicate()
	d.id = m
	return d
