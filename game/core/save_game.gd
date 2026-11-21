## save_game.gd — 자동 저장 파일(user://save.json) 읽고 쓰기. 웹은 user:// 가 브라우저 IndexedDB 에 남는다.
## 저장하는 것: 진행 상태 st 전체(파티·덱·카드·흉터·운명·촛불·지난 방·플래그·층·난수) + 어디서 다시 시작할지(step·room) + 안내 한 번만 기록(guide).
##   step: ctl.gd STEPS 의 단계 이름. "map" 이면 room(지도의 방 id)에 막 들어간 상태 — 이어하기는 그 방의 처음부터.
## 파일이 없거나, 버전(VERSION)이 다르거나, 깨졌거나, 지금 데이터에 없는 카드·방을 가리키면 '저장 없음'으로 본다(에러를 내지 않는다).
## G·FX 같은 자동 로드를 쓰지 않는다(규칙 테스트 --script 에서도 부를 수 있게). --nosave 는 ctl.gd 가 본다.
class_name SaveGame
extends RefCounted

const VERSION := 1
const PATH := "user://save.json"
const STEPS := ["camp", "corridor", "hall", "map", "emptycamp", "chapter1", "f2corridor", "f2ossuary", "f2stairs", "f3chapel", "f3pyre"]


## 저장할 글(JSON). 전투 중 상태(st.battle)는 저장하지 않는다 — 저장은 늘 방·장면의 시작이다
static func pack(st: Dictionary, step: String, room := "", guide := {}) -> String:
	var s: Dictionary = st.duplicate(true)
	s.battle = null
	var data := {"version": VERSION, "step": step, "room": room, "guide": guide.duplicate(), "st": s,
		"time": Time.get_datetime_string_from_system()}
	return JSON.stringify(data, "", false, true)


## 저장 글 → {"step", "room", "guide", "st"} (잘못되었으면 {})
static func unpack(text: String) -> Dictionary:
	if text.strip_edges() == "":
		return {}
	var j := JSON.new()
	if j.parse(text) != OK or not j.data is Dictionary:
		return {}
	var d: Dictionary = _ints(j.data)
	if not d.has("version") or not d.version is int or int(d.version) != VERSION:
		return {}
	if not d.get("st") is Dictionary or not d.get("step") is String or not d.get("room", "") is String:
		return {}
	if not valid_state(d.st, str(d.step), str(d.get("room", ""))):
		return {}
	var g = d.get("guide", {})
	return {"step": str(d.step), "room": str(d.get("room", "")), "guide": g if g is Dictionary else {}, "st": d.st, "time": str(d.get("time", ""))}


## 지금 게임 데이터로 이어 갈 수 있는 상태인가 (빠진 키·없는 카드·없는 방이면 false)
static func valid_state(st: Dictionary, step: String, room: String) -> bool:
	if not step in STEPS:
		return false
	for k in ["seed", "rng", "nextUid", "cards", "party", "flags", "progress", "fates"]:
		if not st.has(k):
			return false
	if not st.rng is int or not st.cards is Dictionary or not st.party is Dictionary or not st.progress is Dictionary or not st.fates is Array:
		return false
	var cards: Dictionary = GameData.D.cards
	for u in st.cards:
		var c = st.cards[u]
		if not c is Dictionary or not cards.has(str(c.get("id", ""))):
			return false
	var p: Dictionary = st.party
	for k in ["witch", "allies", "order", "deck"]:
		if not p.has(k):
			return false
	for u in p.deck + p.get("deathCards", []):
		if not st.cards.has(u):
			return false
	for k in ["floor", "room", "visited", "candles", "darkness"]:
		if not st.progress.has(k):
			return false
	if step == "map":
		var m: Dictionary = GameData.D.floorMaps.get(str(st.progress.floor), {})
		if not m.get("rooms", {}).has(room):
			return false
	return true


## JSON 은 숫자를 모두 실수로 읽는다 → 정수였던 값(소수점 없는 값)은 정수로 되돌린다
static func _ints(v):
	if v is float and is_finite(v) and v == floorf(v) and absf(v) < 9.0e15:
		return int(v)
	if v is Dictionary:
		var out := {}
		for k in v:
			out[k] = _ints(v[k])
		return out
	if v is Array:
		var a := []
		for x in v:
			a.append(_ints(x))
		return a
	return v


static func write_text(text: String, path := PATH) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(text)
	f.close()
	return true


static func read(path := PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text := f.get_as_text()
	f.close()
	return unpack(text)


## 저장을 지운다. 웹은 파일을 닫을 때만 브라우저 저장소로 옮겨 적으므로(지우기만 하면 새로고침 뒤 되살아날 수 있다) 먼저 빈 글로 덮어쓴다
static func clear(path := PATH) -> void:
	if FileAccess.file_exists(path):
		write_text("", path)
		DirAccess.remove_absolute(path)
