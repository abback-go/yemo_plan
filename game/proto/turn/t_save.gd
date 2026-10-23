class_name TSave
extends RefCounted
## 턴제 저장 (combat_proto.md §28.4 · review_F_gaps.md F07 · review_G_firstplay.md §5.2). 파일 셋, 모두 user:// 아래:
##   turn_setup.json  편성 {ver, party, witch: {id: {equipped, equip, equip_lv, skill_lv}}, battle_pick, cleared, intro_done, big_text, full_screen}
##                    — 이 파일이 없으면 "첫 실행"(안내 A부부터). 안내를 끝내거나 끄면 처음 쓴다(안내 중에는 hold로 쓰지 않음)
##   turn_tips.json   본 안내 {ver, seen: {id: true}, off}
##   turn_battle.var  끊긴 전투 — TBattle.to_dict()를 var_to_str로 (JSON은 정수를 실수로 바꿔 규칙 엔진의 int 비교가 틀어짐)
## 웹: user://는 /userfs(IndexedDB)에 있고, 쓰기용 파일을 닫으면 다음 프레임에 IndexedDB로 동기화된다(엔진 platform/web/os_web.cpp).
##   사생활 보호 창·IndexedDB 막힘이면 OS.is_userfs_persistent()가 거짓 → 편성 화면에 "이 브라우저에서는 저장되지 않습니다".
##   끊긴 전투는 웹이면 localStorage(LS_KEY)에도 바로(동기로) 쓴다 (review_I I-01): 탭이 가려지면 브라우저가 requestAnimationFrame을 멈춰
##   "다음 프레임"의 IndexedDB 동기화가 안 올 수 있다 → 가려진 탭이 죽어도 남게. 읽을 때는 localStorage를 먼저(늘 파일보다 새것), 지울 때는 둘 다.
## 시험: tools/test/runner.gd가 시나리오의 "turn_save"(off 기본 · fresh · keep)로 enabled·dir를 바꾼다 — off면 읽지도 쓰지도 않고 첫 실행도 아님(옛 시나리오가 그대로).

const VER := 1
const SETUP_FILE := "turn_setup.json"
const TIPS_FILE := "turn_tips.json"
const BATTLE_FILE := "turn_battle.var"
const DEBOUNCE := 0.5 ## 편성이 바뀐 뒤 이만큼 모아서 쓴다
const LS_KEY := "eska_turn_battle" ## 웹 localStorage 키 (끊긴 전투 사본, 약 5 KB)

static var enabled := true
static var dir := "user://"
static var hold := false ## 첫 실행 안내(A·B부) 중엔 편성을 쓰지 않는다 (안내 중 새로고침하면 안내 처음부터)
static var cleared: Array = [] ## 깬 전투 id
static var intro_done := false ## 안내 전투를 이겼거나 안내를 껐다
static var big_text := false ## 큰 글자 (설정)
static var full_screen := true ## 폰 웹 전체 화면 (설정, R3 review_N N-02 — 첫 탭에 전체 화면 + 가로 고정)
static var tips := {} ## 본 안내 id → true
static var tips_off := false ## "안내 끄기"
static var terms_seen := {} ## 도움말에서 연 용어 → true (상세·설명 상자의 용어 풀이 한 줄이 건너뜀 — 이번 실행 동안만, review_I I-14)
static var _dirty := -1.0
static var _loaded := false
## 지금 편성을 주는 함수 () -> {state, pick} — TStage가 넣는다 (TSave는 TSetup을 직접 부르지 않는다: 헤드리스 규칙 시험엔 자동 로드가 없어 편성 화면 스크립트가 안 불림)
static var source: Callable
static var loaded := {} ## load_all이 읽은 편성 {state, pick} (없으면 {})


static func _path(f: String) -> String:
	return dir.path_join(f)


## 첫 실행인가 (편성 파일이 없음). 저장이 꺼져 있으면(시험) 첫 실행이 아니다
static func first_run() -> bool:
	return enabled and not FileAccess.file_exists(_path(SETUP_FILE))


## 이 브라우저(기기)에서 user://가 남는가
static func persistent() -> bool:
	return not enabled or OS.is_userfs_persistent()


## 처음 한 번: 편성·안내 기록을 읽는다 (편성은 loaded에 — TStage가 TSetup에 넣음. 모르는 id는 버리고 기본값으로)
static func load_all() -> void:
	if _loaded:
		return
	_loaded = true
	loaded = {}
	if not enabled:
		tips_off = true
		intro_done = true
		return
	var d = _read_json(SETUP_FILE)
	if d is Dictionary:
		loaded = parse_setup(d)
	var t = _read_json(TIPS_FILE)
	if t is Dictionary:
		tips = (t.get("seen", {}) as Dictionary).duplicate() if t.get("seen", {}) is Dictionary else {}
		tips_off = bool(t.get("off", false))
		if bool(t.get("big_text", false)) and loaded.is_empty():
			big_text = true # 편성 파일이 아직 없음(안내 중 새로고침) — 큰 글자는 안내 기록에서 (I-17)
			TTheme.big = true
		if loaded.is_empty():
			full_screen = bool(t.get("full_screen", true))


## 편성 사전을 검증한다 → {state, pick} (review_F F07 규칙 1 — 데이터에서 빠진 마녀·마법·장비·전투는 버리고 기본값). 깬 전투·안내·큰 글자는 여기 static에
static func parse_setup(d: Dictionary) -> Dictionary:
	var state := {}
	var party: Array = []
	for w in d.get("party", []):
		if TData.WITCHES.has(String(w)) and not party.has(String(w)):
			party.append(String(w))
	if party.size() == 3:
		state["party"] = party
	var wd: Dictionary = d.get("witch", {}) if d.get("witch", {}) is Dictionary else {}
	for wid in TData.ROSTER:
		if not wd.has(wid) or not (wd[wid] is Dictionary):
			continue
		var src: Dictionary = wd[wid]
		var skills: Array = TData.WITCHES[wid].skills
		var eq: Array[String] = []
		for s in src.get("equipped", []):
			if skills.has(String(s)) and not eq.has(String(s)) and eq.size() < TData.EQUIP_MAX:
				eq.append(String(s))
		if eq.is_empty():
			for s in TData.WITCHES[wid].default:
				eq.append(String(s))
		var lv := {}
		var sl = src.get("skill_lv", {})
		if sl is Dictionary:
			for k in sl:
				if skills.has(String(k)) and int(sl[k]) >= 2:
					lv[String(k)] = clampi(int(sl[k]), 1, 3)
		var e := String(src.get("equip", ""))
		if not TData.EQUIPS.has(e):
			e = ""
		state[wid] = {"equipped": eq, "equip": e, "equip_lv": clampi(int(src.get("equip_lv", 1)), 1, 3), "skill_lv": lv}
	TData.fill_state(state)
	for wid in state.party:
		TData.fix_equip(state, String(wid))
	var bp := String(d.get("battle_pick", ""))
	cleared = []
	for c in d.get("cleared", []):
		if TData.BATTLES.has(String(c)) and not cleared.has(String(c)):
			cleared.append(String(c))
	intro_done = bool(d.get("intro_done", false))
	big_text = bool(d.get("big_text", false))
	TTheme.big = big_text
	full_screen = bool(d.get("full_screen", true))
	return {"state": state, "pick": bp if TData.BATTLES.has(bp) else String(TData.BATTLE.battle)}


## 지금 편성을 사전으로
static func setup_dict() -> Dictionary:
	var cur: Dictionary = source.call() if source.is_valid() else {"state": {}, "pick": TData.BATTLE.battle}
	var st: Dictionary = cur.state
	TData.fill_state(st)
	var wd := {}
	for wid in TData.ROSTER:
		var s: Dictionary = st[wid]
		wd[wid] = {"equipped": (s.equipped as Array).duplicate(), "equip": String(s.equip), "equip_lv": int(s.get("equip_lv", 1)), "skill_lv": (s.get("skill_lv", {}) as Dictionary).duplicate()}
	return {"ver": VER, "party": (st.party as Array).duplicate(), "witch": wd, "battle_pick": String(cur.pick),
		"cleared": cleared.duplicate(), "intro_done": intro_done, "big_text": big_text, "full_screen": full_screen}


static func save_setup() -> void:
	_dirty = -1.0
	if not enabled or hold:
		return
	_write(SETUP_FILE, JSON.stringify(setup_dict(), " "))


## 편성이 바뀜 — 0.5초 모아서 쓴다 (tick이 센다)
static func save_soon() -> void:
	if enabled and not hold:
		_dirty = DEBOUNCE


static func tick(delta: float) -> void:
	if _dirty < 0.0:
		return
	_dirty -= delta
	if _dirty <= 0.0:
		save_setup()


## 깬 전투로 적는다. 처음 깼으면 true
static func mark_cleared(bid: String) -> bool:
	if cleared.has(bid):
		return false
	cleared.append(bid)
	save_setup()
	return true


# ── 안내 기록 (combat_proto.md §28)

static func seen(id: String) -> bool:
	return tips_off or tips.has(id)


static func mark(id: String) -> void:
	if tips.has(id):
		return
	tips[id] = true
	_save_tips()


## 안내 끄기: 모두 본 것으로 · 안내 전투도 끝난 것으로
static func turn_off() -> void:
	tips_off = true
	intro_done = true
	hold = false
	_save_tips()
	save_setup()


## 안내 다시 보기 (설정·도움말): 기록을 지우고 안내 전투부터
static func reset_tips() -> void:
	tips = {}
	tips_off = false
	intro_done = false
	_save_tips()
	save_setup()


static func _save_tips() -> void:
	if enabled:
		_write(TIPS_FILE, JSON.stringify({"ver": VER, "seen": tips, "off": tips_off, "big_text": big_text, "full_screen": full_screen}))


## 설정(큰 글자)이 바뀜 — 안내 중(hold)엔 편성 파일을 안 쓰므로 안내 기록에도 적는다 (review_I I-17)
static func save_tips() -> void:
	_save_tips()


# ── 끊긴 전투 (F07 규칙 2)

static func has_battle() -> bool:
	return enabled and (FileAccess.file_exists(_path(BATTLE_FILE)) or _ls_get() != "")


static func save_battle(d: Dictionary) -> void:
	if enabled:
		var text := var_to_str(d)
		_ls_set(text) # 웹: 동기로 먼저 (I-01)
		_write(BATTLE_FILE, text)


static func load_battle() -> Dictionary:
	if not has_battle():
		return {}
	var text := _ls_get()
	if text == "":
		var f := FileAccess.open(_path(BATTLE_FILE), FileAccess.READ)
		if f == null:
			return {}
		text = f.get_as_text()
		f.close()
	var v = str_to_var(text)
	if v is Dictionary and battle_ok(v):
		return v
	return {} # 판이 다르거나 모르는 id — 부른 쪽이 파일을 지우고, 편성(turn_setup.json)은 parse_setup이 따로 고쳐 살린다


## 끊긴 전투 사본을 이 데이터로 이어 할 수 있나 (review_I I-03): 파일 판 · 데이터 판(TData.DATA_VER — 1.7 파일엔 없음 = 1) · 전투·마녀·적·장착 마법·장비 id
static func battle_ok(v: Dictionary) -> bool:
	if int(v.get("ver", 0)) != VER or int(v.get("data", 1)) != TData.DATA_VER or not TData.BATTLES.has(String(v.get("battle_id", ""))):
		return false
	for wd in v.get("witches", []):
		if not (wd is Dictionary) or not TData.WITCHES.has(String(wd.get("id", ""))):
			return false
		var st: Dictionary = wd.get("setup", {})
		for sid in st.get("equipped", []):
			if not TData.SKILLS.has(String(sid)):
				return false
		if not TData.EQUIPS.has(String(st.get("equip", ""))):
			return false
	for ed in v.get("enemies", []):
		if not (ed is Dictionary) or not TData.ENEMIES.has(String(ed.get("id", ""))):
			return false
	return true


static func clear_battle() -> void:
	if not enabled:
		return
	if FileAccess.file_exists(_path(BATTLE_FILE)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_path(BATTLE_FILE)))
	if _web():
		JavaScriptBridge.eval("try{localStorage.removeItem('%s')}catch(e){}" % LS_KEY)


## 웹 localStorage (시험 폴더를 쓰는 시나리오·규칙 시험은 웹이 아니라 늘 빈 값)
static func _web() -> bool:
	return enabled and OS.has_feature("web") and dir == "user://"


static func _ls_set(text: String) -> void:
	if _web():
		JavaScriptBridge.eval("try{localStorage.setItem('%s', %s)}catch(e){}" % [LS_KEY, JSON.stringify(text)])


static func _ls_get() -> String:
	if not _web():
		return ""
	var v: Variant = JavaScriptBridge.eval("(function(){try{return localStorage.getItem('%s')||''}catch(e){return ''}})()" % LS_KEY, true)
	return String(v) if v is String else ""


## 시험용: 새로 켠 것처럼 기록을 잊는다 (다음 load_all이 파일에서 다시 읽음 — TStage.test_relaunch가 편성도 비움)
static func forget() -> void:
	_loaded = false
	loaded = {}
	tips = {}
	tips_off = false
	intro_done = false
	cleared = []
	hold = false


## 시험용: 이 저장 폴더의 턴제 파일을 모두 지운다 (runner "turn_save": "fresh")
static func wipe() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	for f in [SETUP_FILE, TIPS_FILE, BATTLE_FILE]:
		var p := ProjectSettings.globalize_path(_path(f))
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
	_loaded = false
	tips = {}
	tips_off = false
	intro_done = false
	cleared = []
	big_text = false
	full_screen = true


static func _read_json(file: String):
	if not FileAccess.file_exists(_path(file)):
		return null
	var f := FileAccess.open(_path(file), FileAccess.READ)
	if f == null:
		return null
	var v = JSON.parse_string(f.get_as_text())
	f.close()
	return v


## 쓰고 바로 닫는다 (웹은 닫을 때 IndexedDB 동기화 표시가 선다)
static func _write(file: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var f := FileAccess.open(_path(file), FileAccess.WRITE)
	if f == null:
		return
	f.store_string(text)
	f.close()
