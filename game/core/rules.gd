## rules.gd — 전투 규칙 (화면과 분리 → 헤드리스 테스트 가능). prototype/js/rules.js 를 옮긴 것.
##
## 상태(st) 구조 (Dictionary)
##   st.rng          난수 상태(정수, mulberry32 — HTML 판과 같은 수열)
##   st.cards        { uid: { uid, id, up?, woundOf? } }  — 모든 카드 인스턴스 (up: 훈련으로 강화됨)
##   st.party        { witch:{hp,maxHp}, allies:{id:{id,hp,maxHp,status}}, order:[], deck:[uid] }
##                   status: ok | down(쓰러짐) | dead(사망)
##   st.battle       전투 중일 때만. draw/hand/discard/exhaust 는 uid 배열
##   st.flags        갈림길·이벤트 선택 { path, sera, upgraded }
##   st.run          회차(1부터). 죽음 카드의 잠금(lockedUntil)은 rules.deathLockRuns 회차까지만 걸린다
##   st.party.deathCards  노엘이 쥔 죽음 카드 uid (덱과 따로. 전투마다 처음부터 손패에 보존된다)
##   st.progress     지도: { floor, room, visited:[] }
##   st.fates        운명 [{id, who, method, floor, level, alive, result, triedFloor, card, defied}] (fate-design.md, prototype-v2-spec.md 4.1)
##                   alive: 아직 정해지지 않은 운명(그 동료가 살아 있고 바치지도 구하지도 않음). result: "" | offered(바침) | saved(구함)
##                   triedFloor: 운명의 시도가 온 층(층마다 운명 하나당 한 번). card: 노엘이 쥔 죽음 카드 uid (카드 인스턴스의 lv = 운명 레벨)
##   st.fateLog      운명 기록 [{fate, who, level, floor, result: offered|defied, scars}] — 결과 요약 화면
##   카드 인스턴스 lv: 레벨(Lv1·Lv2…). 카드 정의 "levels" 의 같은 키(text·effects·target·cost)를 덮어쓴다. 훈련 강화(up)는 Lv2 로 보인다
##
## 규칙 함수는 상태를 바꾸고, 화면이 연출할 이벤트 배열을 돌려준다.
class_name Rules
extends RefCounted

const M32 := 0xFFFFFFFF


static func D() -> Dictionary:
	return GameData.D


# ───────── 난수 (mulberry32, 상태를 정수로 저장 → 스냅샷 가능) ─────────
static func _imul(a: int, b: int) -> int:
	var ah := (a >> 16) & 0xFFFF
	var al := a & 0xFFFF
	var bh := (b >> 16) & 0xFFFF
	var bl := b & 0xFFFF
	return ((al * bl) + ((((ah * bl) + (al * bh)) & 0xFFFF) << 16)) & M32


static func rnd(st: Dictionary) -> float:
	st.rng = (int(st.rng) + 0x6D2B79F5) & M32
	var t: int = st.rng
	t = _imul(t ^ (t >> 15), t | 1)
	t = (t ^ ((t + _imul(t ^ (t >> 7), t | 61)) & M32)) & M32
	return float((t ^ (t >> 14)) & M32) / 4294967296.0


static func rint(st: Dictionary, n: int) -> int:
	return int(floor(rnd(st) * n))


static func shuffle(st: Dictionary, arr: Array) -> Array:
	var i := arr.size() - 1
	while i > 0:
		var j := rint(st, i + 1)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t
		i -= 1
	return arr


# ───────── 카드 ─────────
static func new_card(st: Dictionary, id: String, extra := {}) -> String:
	assert(D().cards.has(id), "알 수 없는 카드: " + id)
	var c := {"uid": "k" + str(st.nextUid), "id": id}
	st.nextUid = int(st.nextUid) + 1
	for k in extra:
		c[k] = extra[k]
	st.cards[c.uid] = c
	return c.uid


static var _lvcache := {}


## 레벨이 반영된 카드 정의 (lv 2 이상이면 "levels" 의 같은 키를 덮어쓴 사본)
static func def_lv(id: String, lv := 1) -> Dictionary:
	var base: Dictionary = D().cards[id]
	if lv <= 1 or not base.has("levels") or not base.levels.has(str(lv)):
		return base
	var k := id + "@" + str(lv)
	if _lvcache.has(k):
		return _lvcache[k]
	var m := base.duplicate()
	var o: Dictionary = base.levels[str(lv)]
	for key in o:
		m[key] = o[key]
	_lvcache[k] = m
	return m


static func def(st: Dictionary, uid: String) -> Dictionary:
	var c: Dictionary = st.cards[uid]
	return def_lv(c.id, int(c.get("lv", 1)))


static func is_up(st: Dictionary, uid: String) -> bool:
	return st.cards.has(uid) and bool(st.cards[uid].get("up", false)) and D().upgrades.has(st.cards[uid].id)


## 카드 인스턴스의 레벨 (lv 가 있으면 그것, 훈련으로 강화된 카드는 2, 그 밖은 1)
static func level(st: Dictionary, uid: String) -> int:
	if not st.cards.has(uid):
		return 1
	var c: Dictionary = st.cards[uid]
	if c.has("lv"):
		return int(c.lv)
	return 2 if is_up(st, uid) else 1


## 카드 인스턴스의 효과(훈련으로 강화된 카드는 강화 효과, 레벨이 있는 카드는 그 레벨의 효과)
static func effects_of(st: Dictionary, uid: String) -> Array:
	var id: String = st.cards[uid].id
	if is_up(st, uid):
		return D().upgrades[id].effects
	return def(st, uid).effects


static func effects_for(id: String, up := false, lv := 1) -> Array:
	if up and D().upgrades.has(id):
		return D().upgrades[id].effects
	return def_lv(id, lv).effects


## 레벨 표시가 붙는 카드인가 (죽음·상속 카드는 늘, 그 밖은 Lv2 이상일 때만)
static func shows_level(id: String, lv: int) -> bool:
	return lv >= 2 or str(D().cards[id].kind) in ["death", "inherit"]


## 카드 이름 (강화·레벨이 있으면 이름 옆 Lv — 카드 강화는 + 대신 Lv 로 표기한다)
static func card_name(id: String, up := false, lv := 1) -> String:
	if up and D().upgrades.has(id):
		lv = maxi(lv, 2)
	return str(D().cards[id].name) + (" Lv%d" % lv if shows_level(id, lv) else "")


## 카드 설명문: {dmg} {all} {draw} {self} {weaken} {div} → 효과 수치
static func card_values(id: String, up := false, lv := 1) -> Dictionary:
	var v := {}
	for e in effects_for(id, up, lv):
		match e.type:
			"damage": v.dmg = e.amount
			"damageAll": v.all = e.amount
			"draw": v.draw = e.count
			"selfDamage": v.self = e.amount
			"weaken": v.weaken = e.amount
			"redirect":
				if e.has("div"):
					v.div = "절반" if int(e.div) == 2 else "1/" + str(e.div)
	return v


## wrap: 수치를 감쌀 함수(선택, 화면에서 강조용) — Callable(String) -> String
static func card_text(id: String, up := false, wrap := Callable(), lv := 1) -> String:
	var v := card_values(id, up, lv)
	var s: String = def_lv(id, lv).get("text", "")
	var re := RegEx.new()
	re.compile("\\{(\\w+)\\}")
	var out := ""
	var last := 0
	for m in re.search_all(s):
		out += s.substr(last, m.get_start() - last)
		var k := m.get_string(1)
		if v.has(k):
			var val := str(v[k])
			out += wrap.call(val) if wrap.is_valid() else val
		else:
			out += m.get_string()
		last = m.get_end()
	out += s.substr(last)
	return out


# ───────── 새 게임 / 파티 ─────────
static func new_game(seed = null) -> Dictionary:
	var d := D()
	var sd: int
	if seed == null:
		sd = randi() % 1000000000
	else:
		sd = int(seed) & M32
	var st := {"seed": sd, "rng": sd if sd != 0 else 1, "nextUid": 1, "cards": {}, "party": {}, "battle": null, "run": 1,
		"flags": {}, "progress": {"floor": 1, "room": "camp", "visited": ["camp"]}, "fates": [], "fateLog": []}
	var p := {
		"witch": {"hp": d.party.witch.hp, "maxHp": d.party.witch.hp},
		"allies": {}, "order": d.party.order.duplicate(), "deck": [], "deathCards": []}
	st.party = p
	for id in p.order:
		var a: Dictionary = d.party.allies[id]
		p.allies[id] = {"id": id, "hp": a.hp, "maxHp": a.hp, "status": "ok"}
	for e in d.startingDeck:
		for i in int(e[1]):
			p.deck.append(new_card(st, e[0]))
	# 노엘이 이미 보고 있는 죽음 카드 (대본 1장: 사흘 전부터)
	for id in d.get("startingDeathCards", []):
		p.deathCards.append(new_card(st, id))
	return st


static func snapshot(st: Dictionary) -> Dictionary:
	return st.duplicate(true)


## 스냅샷 복원. 난수는 이어서 진행하고 뽑을 더미는 다시 섞는다(같은 손패 반복 방지).
static func restore(snap: Dictionary, rng_now = null) -> Dictionary:
	var st: Dictionary = snap.duplicate(true)
	if rng_now != null:
		st.rng = int(rng_now) & M32
	if st.battle != null:
		shuffle(st, st.battle.draw)
	return st


static func ally(st: Dictionary, id: String):
	return st.party.allies.get(id)


static func is_ok(st: Dictionary, who: String) -> bool:
	if who == "witch":
		return int(st.party.witch.hp) > 0
	var a = ally(st, who)
	return a != null and a.status == "ok"


## 공격받을 수 있는 아군 (마녀 + 서 있는 동료)
static func hittable(st: Dictionary) -> Array:
	var list := []
	if int(st.party.witch.hp) > 0:
		list.append("witch")
	for id in st.party.order:
		if is_ok(st, id):
			list.append(id)
	return list


## 패배: 노엘 HP 0, 또는 살아 있는 동료가 있는데 모두 쓰러짐 (동료를 모두 바쳐 노엘 혼자 남으면 노엘 HP 만 본다)
static func is_defeat(st: Dictionary) -> bool:
	if int(st.party.witch.hp) <= 0:
		return true
	var living := 0
	for id in st.party.order:
		var a = ally(st, id)
		if a == null or a.status == "dead":
			continue
		living += 1
		if a.status == "ok":
			return false
	return living > 0


# ───────── 전투 시작 ─────────
static func start_battle(st: Dictionary, enc_id: String) -> Array:
	var d := D()
	var enc: Dictionary = d.encounters[enc_id]
	var b := {
		"enc": enc_id, "kind": enc.kind, "turn": 0, "phase": "start", "energy": 0,
		"draw": shuffle(st, st.party.deck.duplicate()), "hand": [], "discard": [], "exhaust": [],
		"free": {}, "enemies": [], "result": null, "shadow": 0, "giantTriggered": false, "lastPlayedIndex": -1, "unlocked": {},
		"actQueue": [], "awaitFate": null, "fateQueue": []}
	st.battle = b
	# 죽음 카드는 전투 처음부터 손패에 있다(보존 — 버려지지 않고 한 칸을 차지한다)
	for u in st.party.get("deathCards", []):
		var dc: Dictionary = d.cards[st.cards[u].id]
		var da = ally(st, dc.get("ally", ""))
		if da != null and da.status != "dead":
			b.hand.append(u)
	_arrange_hand(st)
	for e in enc.enemies:
		var t: Dictionary = d.enemies[e.type]
		b.enemies.append({
			"id": e.id, "type": e.type, "name": t.name, "hp": t.hp, "maxHp": t.hp,
			"immune": bool(t.get("immune", false)), "retreatOn": t.get("retreatOn"), "alive": true, "slot": e.slot, "intent": null})
	return [{"t": "battleStart", "enc": enc_id, "kind": enc.kind}]


static func enemy(st: Dictionary, id: String):
	if st.battle == null:
		return null
	for e in st.battle.enemies:
		if e.id == id:
			return e
	return null


static func alive_enemies(st: Dictionary) -> Array:
	var out := []
	for e in st.battle.enemies:
		if e.alive:
			out.append(e)
	return out


## 손패: 보존(죽음) 카드의 자리 — rules.retainPos: "right"(맨 오른쪽, 대본 v0.5 2장) | "middle"(HTML 판)
static func _arrange_hand(st: Dictionary) -> void:
	var b: Dictionary = st.battle
	var keep := []
	var normal := []
	for u in b.hand:
		(keep if def(st, u).get("retain", false) else normal).append(u)
	if keep.is_empty():
		return
	if str(D().rules.get("retainPos", "right")) == "middle":
		var mid := normal.size() / 2
		b.hand = normal.slice(0, mid) + keep + normal.slice(mid)
	else:
		b.hand = normal + keep


static func draw_cards(st: Dictionary, n: int, scripted, ev: Array) -> void:
	var b: Dictionary = st.battle
	var d := D()
	for i in n:
		if b.hand.size() >= int(d.rules.maxHand):
			ev.append({"t": "handFull"})
			break
		if b.draw.is_empty():
			if b.discard.is_empty():
				break
			b.draw = shuffle(st, b.discard.duplicate())
			b.discard = []
			ev.append({"t": "reshuffle", "draw": b.draw.size()})
		var uid := ""
		if scripted != null and i < scripted.size():
			var j: int = b.draw.size() - 1
			while j >= 0:
				if st.cards[b.draw[j]].id == scripted[i]:
					uid = b.draw[j]
					b.draw.remove_at(j)
					break
				j -= 1
		if uid == "":
			uid = b.draw.pop_back()
		b.hand.append(uid)
		_arrange_hand(st)
		ev.append({"t": "draw", "uid": uid, "hand": b.hand.duplicate(), "drawLeft": b.draw.size()})


static func _add_to_hand(st: Dictionary, uid: String, at = null) -> void:
	var b: Dictionary = st.battle
	if at != null and int(at) >= 0 and int(at) <= b.hand.size():
		b.hand.insert(int(at), uid)
	else:
		b.hand.append(uid)
	_arrange_hand(st)


# ───────── 예고 ─────────
static func _pick_target(st: Dictionary) -> String:
	var w: Dictionary = D().rules.targetWeights
	var list := hittable(st)
	var total := 0.0
	for id in list:
		total += float(w.get(id, 1))
	var r := rnd(st) * total
	for id in list:
		r -= float(w.get(id, 1))
		if r < 0:
			return id
	return list[list.size() - 1]


static func _roll_intents(st: Dictionary) -> void:
	var b: Dictionary = st.battle
	var enc: Dictionary = D().encounters[b.enc]
	var fx = enc.get("fateIntents", {}).get(str(b.turn))
	for e in b.enemies:
		if not e.alive:
			e.intent = null
			continue
		# 운명의 시도: 그 운명이 살아 있고 이 층에서 아직 오지 않았으면 이 적의 예고가 운명이 된다(치명, 옮기기 불가)
		if fx != null and str(fx.enemy) == str(e.id):
			var f = fate_by_id(st, str(fx.fate))
			if f != null and f.alive and int(f.get("triedFloor", 0)) != floor_now(st):
				e.intent = {"kind": "fate", "label": str(fx.label), "fate": f.id, "target": f.who, "value": 0, "lethal": true,
					"redirectable": false, "by": [], "level": int(f.level)}
				continue
		var tdef: Dictionary = D().enemies[e.type]
		if tdef.has("pattern"):
			var pat: Array = tdef.pattern
			var p: Dictionary = pat[(maxi(1, int(b.turn)) - 1) % pat.size()]
			if p.kind == "aoe":
				e.intent = {"kind": "aoe", "label": str(p.label), "value": int(p.value), "hitsWitch": bool(p.get("hitsWitch", true)),
					"target": "all", "detail": "", "redirectable": false, "by": []}
			else:
				e.intent = {"kind": "attack", "label": str(p.get("label", "")), "value": int(p.value), "reduce": 0, "halve": false, "div": 1,
					"target": _target_by(st, str(p.get("target", "random"))), "by": [], "redirectable": true}
			continue
		if b.kind == "giant":
			var cd: Array = enc.countdown
			var idx: int = mini(int(b.turn), cd.size()) - 1
			var step: Dictionary = cd[idx]
			e.intent = {
				"kind": step.kind, "label": step.label, "detail": step.get("detail", ""), "value": int(step.get("value", 0)),
				"hitsWitch": bool(step.get("hitsWitch", false)), "lethal": bool(step.get("lethal", false)), "target": "all",
				"step": b.turn, "total": cd.size(), "redirectable": false}
			continue
		var sc = null
		var si: Dictionary = enc.get("scriptedIntents", {})
		if si.has(int(b.turn)) and si[int(b.turn)].has(e.id):
			sc = si[int(b.turn)][e.id]
		var value: int
		var target: String
		if sc != null and is_ok(st, sc.target):
			value = int(sc.value)
			target = sc.target
		else:
			var r: Array = enc.attackRange
			value = int(r[0]) + rint(st, int(r[1]) - int(r[0]) + 1)
			target = _pick_target(st)
		e.intent = {"kind": "attack", "value": value, "reduce": 0, "halve": false, "div": 1, "target": target, "by": [], "redirectable": true}


## 예고 대상 고르기: random(가중치) | highest(HP 가 가장 높은 서 있는 동료, 없으면 노엘)
static func _target_by(st: Dictionary, how: String) -> String:
	if how == "highest":
		var best := ""
		var bh := -1
		for id in st.party.order:
			if is_ok(st, id) and int(ally(st, id).hp) > bh:
				bh = int(ally(st, id).hp)
				best = id
		return best if best != "" else "witch"
	return _pick_target(st)


static func _intents_event(st: Dictionary) -> Dictionary:
	var arr := []
	for e in st.battle.enemies:
		arr.append({"enemy": e.id, "intent": e.intent.duplicate(true) if e.intent != null else null})
	return {"t": "intents", "intents": arr}


## 예고된 공격의 최종 피해
static func intent_damage(intent) -> int:
	if intent == null or intent.get("blocked", false):
		return 0
	if intent.kind != "attack":
		return int(intent.get("value", 0))
	var v: int = maxi(0, int(intent.value) - int(intent.get("reduce", 0)))
	var dv: int = int(intent.get("div", 1))
	if dv > 1:
		v = int(ceil(v / float(dv))) if D().rules.guardRound == "ceil" else int(floor(v / float(dv)))
	return v


# ───────── 턴 시작 ─────────
static func start_turn(st: Dictionary) -> Array:
	var b: Dictionary = st.battle
	var d := D()
	var enc: Dictionary = d.encounters[b.enc]
	var ev := []
	b.turn = int(b.turn) + 1
	b.phase = "player"
	b.energy = int(d.rules.energyPerTurn)
	b.lastPlayedIndex = -1
	ev.append({"t": "turnStart", "turn": b.turn, "energy": b.energy})
	# 잠긴 죽음 카드: 정해진 전투(lockedUntil = 전투 종류)의 1턴 시작에 자물쇠가 부서진다
	if int(b.turn) == 1:
		for u in b.hand:
			var lu := str(def(st, u).get("lockedUntil", ""))
			if lu != "" and (lu == str(b.kind) or lu == str(b.enc)) and not b.unlocked.has(u):
				b.unlocked[u] = true
				ev.append({"t": "unlock", "uid": u, "id": st.cards[u].id})
	var tsc: Dictionary = enc.get("turnStartCards", {})
	if tsc.has(int(b.turn)):
		for id in tsc[int(b.turn)]:
			var cdef: Dictionary = d.cards[id]
			# 같은 동료의 죽음 카드가 이미 손에 있거나 그 동료가 이미 죽었으면 넣지 않는다
			if cdef.kind == "death":
				var a = ally(st, cdef.ally)
				if a == null or a.status == "dead":
					continue
				var dup := false
				for u in b.hand:
					if st.cards[u].id == id:
						dup = true
				if dup:
					continue
			var uid := new_card(st, id)
			_add_to_hand(st, uid)
			ev.append({"t": "addCard", "uid": uid, "reason": "turnStart", "hand": b.hand.duplicate()})
	var retained := 0
	for u in b.hand:
		if def(st, u).get("retain", false) and (def(st, u).kind != "death" or bool(d.get("fateRules", {}).get("deathCardTakesSlot", true))):
			retained += 1
	var n: int = maxi(0, int(d.rules.drawPerTurn) - retained)
	var sh: Dictionary = enc.get("scriptedHands", {})
	draw_cards(st, n, sh.get(int(b.turn)), ev)
	_roll_intents(st)
	ev.append(_intents_event(st))
	ev.append({"t": "energy", "energy": b.energy})
	return ev


# ───────── 카드 사용 가능 여부·대상 ─────────
static func cost(st: Dictionary, uid: String) -> int:
	var b = st.battle
	if b != null and b.free.has(uid) and int(b.free[uid]) == int(b.turn):
		return 0
	return int(def(st, uid).cost)


static func _no(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason}


static func owner_blocked(st: Dictionary, uid: String) -> String:
	var c := def(st, uid)
	if c.kind == "ally":
		var a = ally(st, c.owner)
		if a == null or a.status == "dead":
			return "죽은 동료의 카드"
		if a.status == "down":
			return "쓰러진 동료의 카드"
	if c.kind == "death":
		var a2 = ally(st, c.ally)
		if a2 == null or a2.status == "dead":
			return "이미 죽었다"
	return ""


## 잠긴 죽음 카드인가 (1회차: 정해진 전투 전까지 낼 수 없다. 2회차 이후는 rules.deathLockRuns 로 푼다)
static func is_locked(st: Dictionary, uid: String) -> bool:
	if not st.cards.has(uid):
		return false
	var lu := str(def(st, uid).get("lockedUntil", ""))
	if lu == "":
		return false
	if int(st.get("run", 1)) > int(D().rules.get("deathLockRuns", 1)):
		return false
	var b = st.battle
	if b != null and b.get("unlocked", {}).has(uid):
		return false
	return true


static func can_play(st: Dictionary, uid: String) -> Dictionary:
	var b = st.battle
	if b == null or b.phase != "player" or b.result != null:
		return _no("지금은 낼 수 없다")
	if not b.hand.has(uid):
		return _no("손패에 없는 카드")
	var c := def(st, uid)
	if is_locked(st, uid):
		return {"ok": false, "reason": "아직 낼 수 없다", "locked": true}
	if c.get("unplayable", false):
		return _no("낼 수 없는 카드")
	var blocked := owner_blocked(st, uid)
	if blocked != "":
		return _no(blocked)
	if cost(st, uid) > int(b.energy):
		return _no("에너지가 부족하다")
	if c.target != "none" and valid_targets(st, uid).is_empty():
		return _no("대상이 없다")
	if c.target == "none" and _has_effect(effects_of(st, uid), "reflect") and reflectable_enemies(st).is_empty():
		return _no("대상이 없다")
	return {"ok": true}


static func _has_effect(effs: Array, t: String) -> bool:
	for e in effs:
		if e.type == t:
			return true
	return false


## 「꿰뚫린 방패」로 막을 수 있는 예고인가 (옮길 수 있는 공격 · 운명이 아닌 광역. 이미 막은 것 제외)
static func reflectable(it) -> bool:
	if it == null or it.get("blocked", false):
		return false
	return (it.kind == "attack" and bool(it.get("redirectable", true))) or (it.kind == "aoe" and not bool(it.get("lethal", false)))


static func reflectable_enemies(st: Dictionary) -> Array:
	var out := []
	if st.battle == null:
		return out
	for e in alive_enemies(st):
		if not e.immune and reflectable(e.intent):
			out.append(e.id)
	return out


static func _redirect_effect(effs: Array):
	for e in effs:
		if e.type == "redirect":
			return e
	return null


## 대상 후보: 적 id 배열
static func valid_targets(st: Dictionary, uid: String) -> Array:
	var b = st.battle
	var c := def(st, uid)
	if b == null:
		return []
	var out := []
	if c.target == "enemy":
		for e in alive_enemies(st):
			out.append(e.id)
		return out
	if c.target == "intent":
		if _has_effect(effects_of(st, uid), "reflect"):
			return reflectable_enemies(st)
		var rd = _redirect_effect(effects_of(st, uid))
		for e in alive_enemies(st):
			var it = e.intent
			if it == null or it.kind != "attack" or not it.redirectable:
				continue
			if rd == null:
				out.append(e.id)
			elif rd.to == "choose":
				if not redirect_choices(st, e.id).is_empty():
					out.append(e.id)
			elif not is_ok(st, rd.to):
				continue
			elif rd.has("div"):
				if not (it.target == rd.to and int(it.get("div", 1)) >= int(rd.div)):
					out.append(e.id)
			elif it.target != rd.to:
				out.append(e.id)
	return out


## 운명 전가 ②단계: 새로 맞을 아군 후보
static func redirect_choices(st: Dictionary, enemy_id: String) -> Array:
	var e = enemy(st, enemy_id)
	if e == null or e.intent == null:
		return []
	var out := []
	for w in hittable(st):
		if w != e.intent.target:
			out.append(w)
	return out


static func needs_second_target(st: Dictionary, uid: String) -> bool:
	var rd = _redirect_effect(effects_of(st, uid))
	return rd != null and rd.to == "choose"


# ───────── 피해 처리 ─────────
static func _hit_enemy(st: Dictionary, e: Dictionary, amount: int, src_uid: String, ev: Array) -> void:
	if not e.alive:
		return
	var src_id = st.cards[src_uid].id if src_uid != "" else null
	if e.immune:
		if e.retreatOn != null and src_id == e.retreatOn:
			e.alive = false
			e.retreated = true
			e.intent = null
			st.battle.result = "retreat"
			ev.append({"t": "retreat", "enemy": e.id})
			return
		ev.append({"t": "damage", "who": {"enemy": e.id}, "amount": 0, "immune": true, "hp": null, "src": src_id})
		return
	e.hp = maxi(0, int(e.hp) - amount)
	ev.append({"t": "damage", "who": {"enemy": e.id}, "amount": amount, "hp": e.hp, "src": src_id})
	if int(e.hp) <= 0:
		e.alive = false
		e.intent = null
		ev.append({"t": "enemyDie", "enemy": e.id})
		# 운명을 집행할 적(encounters.fateIntents)이 그 전에 쓰러지면: 쓰러지는 그 순간 운명의 시도가 온다 (디버그 승리는 제외)
		if src_uid != "":
			for fid in _fates_pending_for(st, str(e.id)):
				st.battle.fateQueue.append({"fate": fid, "enemy": str(e.id)})


static func _hit_ally(st: Dictionary, who: String, amount: int, ev: Array, cause := "attack") -> void:
	if who == "witch":
		var w: Dictionary = st.party.witch
		w.hp = maxi(0, int(w.hp) - amount)
		ev.append({"t": "damage", "who": {"ally": "witch"}, "amount": amount, "hp": w.hp, "cause": cause})
		return
	var a = ally(st, who)
	if a == null or a.status != "ok":
		return
	a.hp = maxi(0, int(a.hp) - amount)
	ev.append({"t": "damage", "who": {"ally": who}, "amount": amount, "hp": a.hp, "cause": cause})
	if int(a.hp) <= 0:
		a.status = "down"
		ev.append({"t": "allyDown", "ally": who})


## 이 적이 집행할 운명 중 아직 오지 않은 것 (encounters.fateIntents, 턴 순서)
static func _fates_pending_for(st: Dictionary, enemy_id: String) -> Array:
	var out := []
	var b = st.battle
	if b == null:
		return out
	var fi: Dictionary = D().encounters[b.enc].get("fateIntents", {})
	var turns := fi.keys().map(func(k): return int(k))
	turns.sort()
	for t in turns:
		var x: Dictionary = fi[str(t)]
		if str(x.enemy) != enemy_id:
			continue
		var f = fate_by_id(st, str(x.fate))
		if f != null and f.alive and int(f.get("triedFloor", 0)) != floor_now(st):
			out.append(f.id)
	return out


## 줄 선 운명의 시도(집행자가 쓰러져 온 것)를 하나 꺼내 시작한다: b.awaitFate
static func _start_next_fate(st: Dictionary, ev: Array) -> void:
	var b = st.battle
	if b == null or b.awaitFate != null or b.result != null:
		return
	while not b.fateQueue.is_empty():
		var q: Dictionary = b.fateQueue.pop_front()
		var f = fate_by_id(st, str(q.fate))
		if f == null or not f.alive or int(f.get("triedFloor", 0)) == floor_now(st):
			continue
		f.triedFloor = floor_now(st)
		b.awaitFate = {"fate": f.id, "enemy": str(q.enemy), "who": f.who, "level": int(f.level), "byDeath": true}
		ev.append({"t": "enemyAct", "enemy": str(q.enemy), "kind": "fate", "target": f.who, "fate": f.id, "dying": true})
		ev.append({"t": "fateTrial", "fate": f.id, "enemy": str(q.enemy), "who": f.who, "level": int(f.level), "byDeath": true})
		return


static func _check_defeat(st: Dictionary, ev: Array) -> bool:
	var b: Dictionary = st.battle
	if b.result == null and is_defeat(st):
		b.result = "lose"
		ev.append({"t": "battleEnd", "result": "lose", "reason": "witch" if int(st.party.witch.hp) <= 0 else "allies"})
		return true
	return false


static func _check_enemies(st: Dictionary, ev: Array) -> void:
	var b: Dictionary = st.battle
	var enc: Dictionary = D().encounters[b.enc]
	if b.result != null or b.awaitFate != null or not b.fateQueue.is_empty():
		return
	var alive := alive_enemies(st)
	# 광신도가 giantTriggerAlive 명 이하로 남으면(한 번에 모두 쓰러져도) 거대 존재가 짓밟는다
	var trig = enc.get("giantTriggerAlive")
	if b.kind == "normal" and trig != null and not b.giantTriggered and alive.size() <= int(trig):
		b.giantTriggered = true
		b.result = "giant"
		var victims := []
		for e in alive:
			victims.append(e.id)
			e.alive = false
			e.hp = 0
			e.intent = null
			e.stomped = true
		ev.append({"t": "giantTrigger", "victims": victims})
		return
	if alive.is_empty():
		b.result = "win"
		ev.append({"t": "battleEnd", "result": "win"})


# ───────── 카드 사용 ─────────
## target: { enemy: id, to: "warrior" (운명 전가 ②단계) }
static func play(st: Dictionary, uid: String, target := {}) -> Dictionary:
	var chk := can_play(st, uid)
	if not chk.ok:
		return {"ok": false, "reason": chk.reason, "events": []}
	var b: Dictionary = st.battle
	var c := def(st, uid)
	var ev := []
	if c.target != "none":
		if not valid_targets(st, uid).has(target.get("enemy", "")):
			return {"ok": false, "reason": "대상이 올바르지 않다", "events": []}
		if needs_second_target(st, uid) and not redirect_choices(st, target.enemy).has(target.get("to", "")):
			return {"ok": false, "reason": "새로 맞을 아군이 올바르지 않다", "events": []}
	var cst := cost(st, uid)
	b.energy = int(b.energy) - cst
	b.lastPlayedIndex = b.hand.find(uid)
	b.hand.remove_at(b.lastPlayedIndex)
	ev.append({"t": "play", "uid": uid, "id": st.cards[uid].id, "up": is_up(st, uid), "lv": level(st, uid), "target": target.duplicate(true), "cost": cst,
		"energy": b.energy, "hand": b.hand.duplicate(), "handIndex": b.lastPlayedIndex})
	for eff in effects_of(st, uid):
		_apply_effect(st, uid, c, eff, target, ev)
		if b.result == "lose":
			break
	if c.get("exhaust", false):
		b.exhaust.append(uid)
	else:
		b.discard.append(uid)
	if b.result == null:
		_check_defeat(st, ev)
	_start_next_fate(st, ev)
	if b.result == null:
		_check_enemies(st, ev)
	if b.result == null and int(b.energy) <= 0:
		ev.append({"t": "energyOut"})
	return {"ok": true, "events": ev}


static func _apply_effect(st: Dictionary, uid: String, c: Dictionary, eff: Dictionary, target: Dictionary, ev: Array) -> void:
	var b = st.battle
	var d := D()
	match eff.type:
		"damage":
			var e = enemy(st, target.get("enemy", ""))
			if e != null:
				_hit_enemy(st, e, int(eff.amount), uid, ev)
		"damageAll":
			ev.append({"t": "aoe", "src": st.cards[uid].id})
			for en in alive_enemies(st):
				_hit_enemy(st, en, int(eff.amount), uid, ev)
		"draw":
			draw_cards(st, int(eff.count), null, ev)
		"redirect":
			var en = enemy(st, target.get("enemy", ""))
			if en == null or en.intent == null:
				return
			var from: String = en.intent.target
			var to: String = target.get("to", "") if eff.to == "choose" else eff.to
			en.intent.target = to
			# 다른 아군으로 옮기면 감싸기 효과는 사라진다
			var dv := int(eff.get("div", 1))
			en.intent.div = dv
			en.intent.halve = dv > 1
			en.intent.by.append(card_name(st.cards[uid].id, is_up(st, uid)))
			ev.append({"t": "redirect", "enemy": en.id, "from": from, "to": to, "halve": dv > 1, "card": st.cards[uid].id})
			ev.append(_intents_event(st))
		"weaken":
			var ew = enemy(st, target.get("enemy", ""))
			if ew != null and ew.intent != null and ew.intent.kind == "attack":
				ew.intent.reduce = int(ew.intent.get("reduce", 0)) + int(eff.amount)
				ew.intent.by.append(c.name)
				ev.append({"t": "weaken", "enemy": ew.id, "amount": eff.amount})
				ev.append(_intents_event(st))
		"selfDamage":
			_hit_ally(st, "witch", int(eff.amount), ev, "relic")
		"killAlly":
			var a = ally(st, eff.ally)
			if a != null:
				a.status = "dead"
				a.hp = 0
				st.party.deathCards.erase(uid)
				var lv := level(st, uid)
				# 이 죽음 카드에 걸린 운명은 '바침'으로 끝난다
				for f in st.get("fates", []):
					if f.who == eff.ally and f.alive:
						f.alive = false
						f.result = "offered"
						f.offeredLevel = lv
						f.offeredFloor = floor_now(st)
						f.triedFloor = floor_now(st)
						st.fateLog.append({"fate": f.id, "who": f.who, "level": lv, "floor": floor_now(st), "result": "offered", "scars": 0})
				ev.append({"t": "allyDeath", "ally": eff.ally, "cause": "deathCard", "card": st.cards[uid].id, "lv": lv,
					"fate": str(c.get("fate", "")), "handIndex": b.lastPlayedIndex if b != null else -1})
		"relicize":
			var changes := []
			for u in st.cards:
				var card: Dictionary = st.cards[u]
				var df: Dictionary = d.cards[card.id]
				if df.kind == "ally" and df.owner == eff.ally and d.relicMap.has(card.id):
					changes.append({"uid": u, "from": card.id, "to": d.relicMap[card.id]})
					card.id = d.relicMap[card.id]
					card.erase("up")
			ev.append({"t": "relicize", "ally": eff.ally, "changes": changes})
		"addCard":
			var extra := {}
			if str(eff.get("lvFrom", "")) == "source":
				extra.lv = level(st, uid)
			var nu := new_card(st, eff.card, extra)
			if eff.get("permanent", false):
				st.party.deck.append(nu)
			if b == null:
				# 전투 밖(탐사 중 운명의 시도에서 바침): 덱에만 들어간다
				ev.append({"t": "gainCard", "uid": nu, "id": eff.card, "lv": int(extra.get("lv", 1))})
				return
			if eff.get("freeThisTurn", false):
				b.free[nu] = b.turn
			_add_to_hand(st, nu, b.lastPlayedIndex if eff.get("at", "") == "source" and int(b.lastPlayedIndex) >= 0 else null)
			ev.append({"t": "addCard", "uid": nu, "reason": "effect", "free": bool(eff.get("freeThisTurn", false)), "hand": b.hand.duplicate(),
				"lv": int(extra.get("lv", 1))})
		"reflect":
			# 「꿰뚫린 방패」: 예고된 공격을 막고(피해 0) 그 피해만큼 그 적에게 되돌린다
			var list := []
			if eff.get("all", false):
				list = reflectable_enemies(st)
			elif target.has("enemy") and reflectable_enemies(st).has(target.enemy):
				list = [target.enemy]
			for eid in list:
				var en = enemy(st, eid)
				var amt: int = int(en.intent.value) if en.intent.kind == "aoe" else intent_damage(en.intent)
				en.intent.blocked = true
				if en.intent.has("by"):
					en.intent.by.append(str(c.name))
				ev.append({"t": "reflect", "enemy": eid, "amount": amt})
				ev.append(_intents_event(st))
				_hit_enemy(st, en, amt, uid, ev)
		_:
			push_error("알 수 없는 효과: " + str(eff.type))


# ───────── 턴 종료 → 적 턴 ─────────
static func end_turn(st: Dictionary) -> Array:
	var b = st.battle
	var ev := []
	if b == null or b.phase != "player" or b.result != null:
		return ev
	b.phase = "enemy"
	# 흉터: 손에 든 채 턴이 끝나면 노엘 HP 가 준다
	for u in b.hand:
		var sd: Dictionary = def(st, u)
		if sd.has("endTurnSelf"):
			ev.append({"t": "scarBurn", "uid": u})
			_hit_ally(st, "witch", int(sd.endTurnSelf), ev, "scar")
	var keep := []
	var gone := []
	for u in b.hand:
		(keep if def(st, u).get("retain", false) else gone).append(u)
	b.hand = keep
	b.discard = b.discard + gone
	ev.append({"t": "discardHand", "uids": gone, "hand": keep.duplicate()})
	if _check_defeat(st, ev):
		return ev
	ev.append({"t": "enemyPhase"})
	b.actQueue = []
	for e in b.enemies:
		if e.alive and e.intent != null:
			b.actQueue.append(e.id)
	_run_queue(st, ev)
	return ev


## 적이 차례로 행동한다. 운명의 시도가 오면 거기서 멈춘다(b.awaitFate) → fate_trial_choice → resume_enemy_phase
static func _run_queue(st: Dictionary, ev: Array) -> void:
	var b: Dictionary = st.battle
	while not b.actQueue.is_empty():
		if b.result != null:
			return
		var e = enemy(st, str(b.actQueue.pop_front()))
		if e == null or not e.alive or e.intent == null:
			continue
		_perform_intent(st, e, ev)
		if b.awaitFate != null:
			return
	if b.result == null:
		_check_defeat(st, ev)


## 운명의 시도 뒤 남은 적의 행동을 잇는다
static func resume_enemy_phase(st: Dictionary) -> Array:
	var ev := []
	if st.battle == null or st.battle.result != null or st.battle.awaitFate != null:
		return ev
	if st.battle.phase == "player":
		_check_defeat(st, ev)
		_check_enemies(st, ev)
		return ev
	_run_queue(st, ev)
	return ev


static func _perform_intent(st: Dictionary, e: Dictionary, ev: Array) -> void:
	var b: Dictionary = st.battle
	var it: Dictionary = e.intent
	if it.get("blocked", false):
		ev.append({"t": "enemyAct", "enemy": e.id, "kind": "blocked"})
		return
	match it.kind:
		"fate":
			var f = fate_by_id(st, str(it.fate))
			if f == null or not f.alive:
				return
			f.triedFloor = floor_now(st)
			b.awaitFate = {"fate": f.id, "enemy": e.id, "who": f.who, "level": int(f.level)}
			ev.append({"t": "enemyAct", "enemy": e.id, "kind": "fate", "target": f.who, "fate": f.id})
			ev.append({"t": "fateTrial", "fate": f.id, "enemy": e.id, "who": f.who, "level": int(f.level)})
		"attack":
			var amount := intent_damage(it)
			var target: String = it.target
			if not is_ok(st, target):
				var list := hittable(st)
				if list.is_empty():
					return
				target = list[rint(st, list.size())]
			ev.append({"t": "enemyAct", "enemy": e.id, "kind": "attack", "target": target, "amount": amount})
			_hit_ally(st, target, amount, ev, "attack")
			_check_defeat(st, ev)
		"shadow":
			b.shadow = 1
			ev.append({"t": "enemyAct", "enemy": e.id, "kind": "shadow"})
		"aoe":
			ev.append({"t": "enemyAct", "enemy": e.id, "kind": "aoe", "amount": it.value})
			if it.hitsWitch:
				_hit_ally(st, "witch", int(it.value), ev, "aoe")
			for id in st.party.order:
				_hit_ally(st, id, int(it.value), ev, "aoe")
			_check_defeat(st, ev)
		"stomp":
			ev.append({"t": "enemyAct", "enemy": e.id, "kind": "stomp"})
			for id in st.party.order:
				var a = ally(st, id)
				if a.status == "ok":
					_hit_ally(st, id, int(a.hp), ev, "stomp")
			if int(st.party.witch.hp) > 0:
				_hit_ally(st, "witch", int(st.party.witch.hp), ev, "stomp")
			if b.result == null:
				b.result = "lose"
				ev.append({"t": "battleEnd", "result": "lose", "reason": "stomp"})


# ───────── 전투 종료 처리 (쓰러진 동료: HP 1 복귀 + 상처 카드) ─────────
static func finish_battle(st: Dictionary) -> Array:
	var ev := []
	var p: Dictionary = st.party
	var d := D()
	for id in p.order:
		var a: Dictionary = p.allies[id]
		if a.status != "down":
			continue
		a.status = "ok"
		a.hp = int(d.rules.downedReviveHp)
		var cands := []
		for u in p.deck:
			var df: Dictionary = d.cards[st.cards[u].id]
			if df.kind == "ally" and df.owner == id:
				cands.append(u)
		if not cands.is_empty():
			var u: String = cands[rint(st, cands.size())]
			var from: String = st.cards[u].id
			st.cards[u].id = "wound"
			st.cards[u].erase("up")
			st.cards[u].woundOf = id
			ev.append({"t": "wound", "ally": id, "uid": u, "from": from})
		ev.append({"t": "revive", "ally": id, "hp": a.hp})
	# 임시 카드는 버린다 (덱과 노엘이 쥔 죽음 카드는 남는다)
	var keep := {}
	for u in p.deck:
		keep[u] = true
	for u in p.get("deathCards", []):
		keep[u] = true
	for u in st.cards.keys():
		if not keep.has(u):
			st.cards.erase(u)
	st.battle = null
	return ev


# ───────── 운명 (fate-design.md · prototype-v2-spec.md 4.1) ─────────
static func floor_now(st: Dictionary) -> int:
	return int(st.get("progress", {}).get("floor", 1))


static func fate_by_id(st: Dictionary, id: String):
	for f in st.get("fates", []):
		if f.id == id:
			return f
	return null


static func fate_of(st: Dictionary, who: String):
	for f in st.get("fates", []):
		if f.who == who and f.alive:
			return f
	return null


## 아직 정해지지 않은 운명들 (운명 표시·전투 손패)
static func active_fates(st: Dictionary) -> Array:
	return st.get("fates", []).filter(func(f): return f.alive)


## 새 운명: 그 동료의 죽음 카드(Lv1)가 노엘 손에 들어온다. 반환: 죽음 카드 uid ("" = 이미 죽었거나 운명이 있음)
static func add_fate(st: Dictionary, fate_id: String, floor := -1) -> String:
	var fd: Dictionary = D().fates[fate_id]
	var a = ally(st, fd.who)
	if a == null or a.status == "dead" or fate_of(st, fd.who) != null or fate_by_id(st, fate_id) != null:
		return ""
	var uid := new_card(st, fd.card, {"lv": 1})
	st.party.deathCards.append(uid)
	st.fates.append({"id": fate_id, "who": fd.who, "method": fd.method, "floor": floor if floor > 0 else floor_now(st) + 1, "level": 1,
		"alive": true, "result": "", "triedFloor": 0, "card": uid, "defied": 0})
	return uid


## 바친다: 운명의 시도에서 노엘이 죽음 카드를 낸다 → 그 동료 사망 → 유품 → 상속 카드(같은 Lv).
## 전투 중이면 손패에서 낸 것과 같고(상속 카드는 손패로), 탐사 중이면 덱에만 들어간다
static func offer_fate(st: Dictionary, fate_id: String) -> Array:
	var ev := []
	var f = fate_by_id(st, fate_id)
	if f == null or not f.alive or not st.cards.has(f.card):
		return ev
	var uid: String = f.card
	var b = st.battle
	if b != null:
		b.lastPlayedIndex = b.hand.find(uid)
		if b.lastPlayedIndex >= 0:
			b.hand.remove_at(b.lastPlayedIndex)
		ev.append({"t": "play", "uid": uid, "id": st.cards[uid].id, "up": false, "lv": level(st, uid), "target": {}, "cost": 0,
			"energy": b.energy, "hand": b.hand.duplicate(), "handIndex": b.lastPlayedIndex, "byFate": true})
	var c := def(st, uid)
	for eff in c.effects:
		_apply_effect(st, uid, c, eff, {}, ev)
	if b != null:
		b.exhaust.append(uid)
		if b.result == null:
			_check_defeat(st, ev)
	ev.append({"t": "fateOffered", "fate": fate_id, "who": f.who, "level": int(f.get("offeredLevel", f.level))})
	return ev


## 거스른다: 카드를 내지 않는다 → 그 동료는 살고, 노엘 덱에 흉터가 들어온다(그 순간). 전투 중이면 뽑을 더미에도 섞는다
static func defy_fate(st: Dictionary, fate_id: String) -> Array:
	var f = fate_by_id(st, fate_id)
	if f == null or not f.alive:
		return []
	var fd: Dictionary = D().fates[fate_id]
	f.triedFloor = floor_now(st)
	f.defied = int(f.get("defied", 0)) + 1
	var scars: Array = fd.scars
	var n: int = int(scars[clampi(int(f.level) - 1, 0, scars.size() - 1)])
	var uids := []
	for i in n:
		var u := new_card(st, "scar")
		st.party.deck.append(u)
		if st.battle != null:
			st.battle.draw.insert(rint(st, st.battle.draw.size() + 1), u)
		uids.append(u)
	st.fateLog.append({"fate": fate_id, "who": f.who, "level": int(f.level), "floor": floor_now(st), "result": "defied", "scars": n})
	return [{"t": "fateDefied", "fate": fate_id, "who": f.who, "level": int(f.level), "scars": uids}]


## 전투 중 운명의 시도에서 고른 것 (offer | defy)
static func fate_trial_choice(st: Dictionary, choice: String) -> Array:
	var b = st.battle
	if b == null or b.awaitFate == null:
		return []
	var af: Dictionary = b.awaitFate
	b.awaitFate = null
	var e = enemy(st, str(af.enemy))
	if e != null:
		e.intent = null
	var ev: Array = offer_fate(st, str(af.fate)) if choice == "offer" else defy_fate(st, str(af.fate))
	ev.append(_intents_event(st))
	_start_next_fate(st, ev)
	return ev


## 흉터 장수 (덱)
static func scar_count(st: Dictionary) -> int:
	var n := 0
	for u in st.party.deck:
		if st.cards.has(u) and st.cards[u].id == "scar":
			n += 1
	return n


## 층을 살아서 내려간다: 이 층(또는 지난 층)의 운명은 레벨 +1·다음 층으로 미뤄지고 문구가 바뀐다. 마지막 단계를 넘기면 구함
static func descend(st: Dictionary) -> Array:
	var ev := []
	var fl := floor_now(st)
	for f in st.get("fates", []):
		if not f.alive:
			continue
		var a = ally(st, f.who)
		if a == null or a.status == "dead":
			f.alive = false
			continue
		if int(f.floor) > fl:
			continue
		var mx := int(D().fates[f.id].get("maxLevel", 3))
		if int(f.level) >= mx:
			f.alive = false
			f.result = "saved"
			st.party.deathCards.erase(f.card)
			ev.append({"t": "fateSaved", "fate": f.id, "who": f.who})
			continue
		f.level = int(f.level) + 1
		f.floor = fl + 1
		if st.cards.has(f.card):
			st.cards[f.card].lv = f.level
		ev.append({"t": "fateLevelUp", "fate": f.id, "who": f.who, "level": f.level, "floor": f.floor, "uid": f.card})
	st.progress.floor = fl + 1
	return ev


## 살아 있는 모두 HP 회복 (쓰러진 동료도 일어난다). [임시] 새 층에 들어설 때
static func heal_all(st: Dictionary) -> void:
	st.party.witch.hp = st.party.witch.maxHp
	for id in st.party.order:
		var a: Dictionary = st.party.allies[id]
		if a.status == "dead":
			continue
		a.status = "ok"
		a.hp = a.maxHp


## 시험·바로 가기용: 튜토리얼(1층)을 끝낸 상태 — 세라피나 사망(유품·짓밟힘), 브룬힐드 관통 Lv1 (2층)
static func state_after_tutorial(seed = null, sera := "none") -> Dictionary:
	var st := new_game(seed)
	for u in st.party.deathCards.duplicate():
		var c := def(st, u)
		if c.get("ally", "") == "hero":
			var ev := []
			for eff in c.effects:
				_apply_effect(st, u, c, eff, {}, ev)
			st.cards.erase(u)
	st.flags.sera = sera
	st.progress.floor = 1
	add_fate(st, "warrior_pierce", 2)
	descend(st)
	st.progress.room = "f2corridor"
	return st


## 시험·바로 가기용: 2층을 끝낸 상태 (brun: alive = 거스름 → 3층에서 Lv2 / dead = 바침), 엘리안 화형 Lv1 (3층)
static func state_floor3(seed = null, brun := "alive") -> Dictionary:
	var st := state_after_tutorial(seed)
	if brun == "dead":
		offer_fate(st, "warrior_pierce")
	else:
		defy_fate(st, "warrior_pierce")
	add_fate(st, "archer_burn", 3)
	descend(st)
	st.progress.room = "f3chapel"
	return st


# ───────── 갈림길: 휴식 / 훈련 (tutorial-flow.md 2장) ─────────
## 휴식: 살아 있는 동료 최대 HP +allyMaxHp, 마녀 +witchMaxHp, 전원 회복
static func apply_rest(st: Dictionary) -> Dictionary:
	var r: Dictionary = D().rest
	var p: Dictionary = st.party
	p.witch.maxHp = int(p.witch.maxHp) + int(r.witchMaxHp)
	if r.healAll:
		p.witch.hp = p.witch.maxHp
	for id in p.order:
		var a: Dictionary = p.allies[id]
		if a.status == "dead":
			continue
		a.maxHp = int(a.maxHp) + int(r.allyMaxHp)
		if r.healAll:
			a.hp = a.maxHp
			a.status = "ok"
	st.flags.rested = true
	return {"witch": p.witch.maxHp}


## 훈련 후보: 강화표의 카드 중 덱에 아직 강화되지 않은 것이 있는 카드에서 무작위 n장
static func train_candidates(st: Dictionary, n := -1) -> Array:
	if n < 0:
		n = int(D().trainChoices)
	var pool := []
	for id in D().upgrades:
		if _first_unupgraded(st, id) != "":
			pool.append(id)
	shuffle(st, pool)
	return pool.slice(0, mini(n, pool.size()))


static func _first_unupgraded(st: Dictionary, id: String) -> String:
	for u in st.party.deck:
		if st.cards[u].id == id and not st.cards[u].get("up", false):
			return u
	return ""


## 덱의 그 카드 1장을 강화한다. 반환: 강화된 uid ("" = 실패)
static func upgrade_card(st: Dictionary, id: String) -> String:
	var u := _first_unupgraded(st, id)
	if u == "":
		return ""
	st.cards[u].up = true
	st.flags.upgraded = id
	return u


# ───────── 디버그 ─────────
static func debug_set_hp(st: Dictionary, who: String, hp: int) -> void:
	hp = maxi(0, hp)
	if who == "witch":
		st.party.witch.hp = mini(hp, 999)
		return
	var a = ally(st, who)
	if a != null:
		if a.status == "dead":
			return
		a.hp = hp
		a.status = "ok" if hp > 0 else "down"
		return
	if st.battle != null:
		var e = enemy(st, who)
		if e != null and e.maxHp != null:
			e.hp = hp
			e.alive = hp > 0
			if not e.alive:
				e.intent = null


static func debug_add_card(st: Dictionary, card_id: String) -> Array:
	var b = st.battle
	if b == null:
		return []
	var uid := new_card(st, card_id)
	_add_to_hand(st, uid)
	return [{"t": "addCard", "uid": uid, "reason": "debug", "hand": b.hand.duplicate()}]


## 전투 즉시 승리: 일반 전투(2층) → 거대 존재 등장 / 1층 → 승리 / 거대 존재 → 물러남
static func debug_win(st: Dictionary) -> Array:
	var b = st.battle
	var ev := []
	if b == null or b.result != null:
		return ev
	if b.kind == "giant":
		var al := alive_enemies(st)
		if not al.is_empty():
			var g: Dictionary = al[0]
			g.alive = false
			g.retreated = true
			g.intent = null
			b.result = "retreat"
			ev.append({"t": "retreat", "enemy": g.id})
		return ev
	var alive := alive_enemies(st)
	var enc: Dictionary = D().encounters[b.enc]
	var trig = enc.get("giantTriggerAlive")
	var leave: int = int(trig) if trig != null else 0
	for i in maxi(0, alive.size() - leave):
		_hit_enemy(st, alive[i], 999, "", ev)
	_check_enemies(st, ev)
	return ev
