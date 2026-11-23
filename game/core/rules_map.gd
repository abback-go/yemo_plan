## rules_map.gd — 지도·랜턴·어둠, 방에서 얻는 카드, 휴식·훈련 규칙. 전투 밖에서 지도·방이 쓰는 정적 함수.
## rules.gd 에서 주제별로 나눈 것(2026-11-22 밤샘 계획 5 — 내용은 그대로). 상태(st) 구조와 공통 도움 함수(D·floor_now·ally·shuffle·new_card 등)는 Rules.
class_name MapRules
extends RefCounted


# ───────── 지도·랜턴·어둠 (vertical-slice.md 5장, game_data.gd lantern·darkness·floorMaps) ─────────
## 다음 층: 촛불을 새로 받고(남은 것은 이월, 최대 lantern.max), 어둠·전조·지나간 방은 그 층마다 새로
static func lantern_next_floor(st: Dictionary) -> void:
	var L: Dictionary = Rules.D().lantern
	var p: Dictionary = st.progress
	p.candles = mini(int(L.max), int(p.get("candles", 0)) + int(L.perFloor))
	p.candlesStart = p.candles
	p.darkness = 0
	p.omen = false
	p.visited = []


## 지금 층의 지도 데이터 ({} = 지도가 없는 층)
static func map_def(st: Dictionary) -> Dictionary:
	return Rules.D().floorMaps.get(str(Rules.floor_now(st)), {})


static func room_def(st: Dictionary, id: String) -> Dictionary:
	return map_def(st).get("rooms", {}).get(id, {})


## 방의 상태: visited(지나간 방 — 공짜로 지나간다) | open(지나간 방과 이어져 들어갈 수 있음) | locked
static func room_state(st: Dictionary, id: String) -> String:
	var m := map_def(st)
	if not m.get("rooms", {}).has(id):
		return "locked"
	var vis: Array = st.progress.get("visited", [])
	if vis.has(id):
		return "visited"
	for ln in m.get("links", []):
		if (ln[0] == id and vis.has(ln[1])) or (ln[1] == id and vis.has(ln[0])):
			return "open"
	return "locked"


## 방에 들어간다. 처음이면 촛불 1개가 탄다 — 촛불이 없으면 어둠이 한 단계 깊어진다(지나간 방은 공짜, candle: false 인 방은 타지 않음)
## 반환: {ok, first, burned, dark(이번에 깊어진 단계), candles, darkness}
static func enter_room(st: Dictionary, id: String) -> Dictionary:
	var stt := room_state(st, id)
	if stt == "locked":
		return {"ok": false}
	var p: Dictionary = st.progress
	p.room = id
	var out := {"ok": true, "first": stt == "open", "burned": false, "dark": 0}
	if stt == "open":
		p.visited.append(id)
		if bool(room_def(st, id).get("candle", true)):
			if int(p.candles) > 0:
				p.candles = int(p.candles) - 1
				out.burned = true
			else:
				out.dark = int(Rules.D().darkness.perRoom)
				p.darkness = int(p.darkness) + out.dark
	out.candles = p.candles
	out.darkness = p.darkness
	return out


## 이 전투에서 가려질 예고 수 (어둠 단계). darkness 전투(층 끝·강적)만, 층 끝 전투는 그 층의 전조를 보았으면 0
static func darkness_level(st: Dictionary, enc_id: String) -> int:
	var enc: Dictionary = Rules.D().encounters.get(enc_id, {})
	if not bool(enc.get("darkness", false)):
		return 0
	var p: Dictionary = st.get("progress", {})
	if bool(enc.get("floorEnd", false)) and bool(p.get("omen", false)):
		return 0
	return int(p.get("darkness", 0))


## 랜턴에 촛불을 더한다 (거래). 최대 lantern.max
static func add_candles(st: Dictionary, n: int) -> int:
	st.progress.candles = mini(int(Rules.D().lantern.max), int(st.progress.candles) + n)
	return int(st.progress.candles)


# ───────── 방에서 얻는 카드 (대본 v3 3장, game_data.gd rewards·trade·buried·corpse) ─────────
# 전투 승리 뒤 '카드 3장 중 1장' 보상은 2026-11-21 사용자 지시로 뺐다. 3장 중 1장 고르기는 묘지기의 좌판(거래)에만 남았다.
## 목록(rewards.<pool>)에서 서로 다른 카드 id 를 섞어 돌려준다. 죽은 동료의 카드는 빠진다
static func _card_pool(st: Dictionary, pool: String) -> Array:
	var ids := []
	for id in Rules.D().rewards.get(pool, []):
		var o := str(Rules.D().cards[id].owner)
		var a = Rules.ally(st, o)
		if a != null and a.status == "dead":
			continue
		if not ids.has(id):
			ids.append(id)
	Rules.shuffle(st, ids)
	return ids


## 묘지기의 좌판(거래 trade:card)의 카드 후보: [{id, up}] — 서로 다른 카드, 죽은 동료의 카드는 빠진다
static func trade_choices(st: Dictionary, pool := "common", n := -1) -> Array:
	if n < 0:
		n = int(Rules.D().rewards.choices)
	var ids := _card_pool(st, pool)
	var out := []
	for id in ids.slice(0, mini(n, ids.size())):
		out.append({"id": id, "up": false})
	return out


## 강적을 이기면 얻는 카드 [기본안 2026-11-21]: 목록(rewards.elite)에서 무작위 1장이 강화된 채(강화표에 있으면 Lv2) 바로 덱에 들어온다.
## 고르는 화면은 없다. 죽은 동료의 카드는 빠진다. 반환: 새 카드 uid ("" = 얻을 카드 없음)
static func win_card(st: Dictionary, pool := "elite") -> String:
	var ids := _card_pool(st, pool)
	if ids.is_empty():
		return ""
	var id: String = ids[0]
	return gain_card(st, id, Rules.D().upgrades.has(id))


## 덱에 카드 1장을 더한다. 반환: uid
static func gain_card(st: Dictionary, id: String, up := false) -> String:
	var u := Rules.new_card(st, id, {"up": true} if up else {})
	st.party.deck.append(u)
	RulesV2.gain_from_v1(st, id, up)   # 새 전투(기본 흐름)의 덱 deck2 에도 짝 카드 (밤샘 계획 2 A)
	return u


## 노엘이 HP 를 대가로 낸다(전투 밖). HP 가 대가 이하이면 낼 수 없다(false)
static func pay_hp(st: Dictionary, n: int) -> bool:
	var w: Dictionary = st.party.witch
	if int(w.hp) <= n:
		return false
	w.hp = int(w.hp) - n
	return true


## 전투 밖에서 노엘이 다친다 (1 아래로는 줄지 않는다)
static func hurt_witch(st: Dictionary, n: int) -> void:
	st.party.witch.hp = maxi(1, int(st.party.witch.hp) - n)


## 거래: card(HP cardHp → 고른 카드) | candle(HP candleHp → 촛불 +candles). 반환: 거래했는가
static func trade(st: Dictionary, what: String, card := {}) -> bool:
	var T: Dictionary = Rules.D().trade
	if what == "candle":
		if int(st.progress.candles) >= int(Rules.D().lantern.max) or not pay_hp(st, int(T.candleHp)):
			return false
		add_candles(st, int(T.candles))
		return true
	if what == "card" and not card.is_empty():
		if not pay_hp(st, int(T.cardHp)):
			return false
		gain_card(st, str(card.id), bool(card.get("up", false)))
		return true
	return false


## 살아 있는 모두 HP 회복 (쓰러진 동료도 일어난다). [임시] 새 층에 들어설 때
static func heal_all(st: Dictionary) -> void:
	st.party.witch.hp = st.party.witch.maxHp
	for id in st.party.order:
		var a: Dictionary = st.party.allies[id]
		if a.status == "dead":
			continue
		a.status = "ok"
		a.hp = a.maxHp


# ───────── 갈림길: 휴식 / 훈련 (docs/archive/tutorial-flow.md 2장) ─────────
## 휴식: 살아 있는 동료 최대 HP +allyMaxHp, 마녀 +witchMaxHp, 전원 회복
static func apply_rest(st: Dictionary) -> Dictionary:
	var r: Dictionary = Rules.D().rest
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
		n = int(Rules.D().trainChoices)
	var pool := []
	for id in Rules.D().upgrades:
		if _first_unupgraded(st, id) != "":
			pool.append(id)
	Rules.shuffle(st, pool)
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
	RulesV2.upgrade_from_v1(st, id)   # 새 전투의 덱 deck2 의 짝 카드도 Lv2 (밤샘 계획 2 A)
	return u
