class_name ChapterRegistry
extends RefCounted
## 장별 확장 모듈 모음 (docs/dev/story.md "장 매니페스트"). 1~5장과 공통 시스템(sys)은 공용 파일을 고치지 않고
## 자기 파일에 상수만 적으면 여기서 합쳐진다 → 장을 더하거나 바꿀 때 고칠 곳은 data·대본·방(py) 세 곳.
##
## 확장 ID(EXTS)마다 다음 파일이 있으면 읽는다 (없으면 건너뜀). 순서 = EXTS 순서 (뒤가 같은 키를 덮어씀):
##   res://story/data_<ext>.gd            CHAPTER(장 정보, 아래), SCRIPTS(대본 파일 목록), CHARACTERS(인물),
##                                        ROOMS(방 ID 목록), OBJECTIVES(메인 목표 줄), QUESTS(퀘스트)
##   res://enemies/<ext>/registry.gd      const KINDS (적 종류 → 스크립트 경로)
##   res://world/entities/<ext>/entities.gd  const KINDS (방 개체 종류 → 스크립트 경로)
##   res://world/entities/<ext>/props.gd  static func setup_info(kind, prop) -> Dictionary, static func draw(prop, kind) -> bool
##   res://world/themes/themes_<ext>.gd   const THEMES (테마 ID → 색 사전, RoomTheme와 같은 키)
##   res://world/themes/backdrop_<ext>.gd static func draw_layer/draw_sky/is_animated (RoomBackdrop 참고)
##   res://allies/<ext>_allies.gd         const KINDS (동료 종류 → 스크립트 경로)
##
## CHAPTER (장마다 하나, sys에는 없음):
##   n             장 번호 (플래그 chapter, ch<n>_start·ch<n>_done, npc_<who>_ch<n>)
##   title         [장 표시, 부제] — 장 카드("2장 — 제국의 검")
##   tails_at_end  장이 끝날 때 너울의 꼬리 수 (없으면 그대로)
##   last          true면 마지막 장: 끝나도 다음 장으로 넘기지 않음
##   areas         {지역 ID: 지도 제목} — 방 데이터의 area
##   warps         [[지역, 방 ID, 등장 위치 ID, 이름, 해금 플래그("" = 항상)], ...] — 전이진 목적지
##   credits       엔딩 크레디트에 들어갈 이 장의 줄 ("# "으로 시작하면 제목 줄)
## 동적 경로(위 %s 패턴)라 파일을 옮기거나 이름을 바꾸면 조용히 빠진다 — tools/story_lint.py로 확인.

const EXTS := ["ch1", "sys", "ch2", "ch3", "ch4", "ch5"]
const DATA := "res://story/data_%s.gd"

static var _cache := {}


static func _script(path: String) -> GDScript:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as GDScript


static func _const(path: String, name: String) -> Variant:
	var s := _script(path)
	if s == null:
		return null
	return s.get_script_constant_map().get(name, null)


static func _merged_dict(key: String, pattern: String, const_name: String) -> Dictionary:
	if _cache.has(key):
		return _cache[key]
	var out := {}
	for ext in EXTS:
		var d: Variant = _const(pattern % ext, const_name)
		if typeof(d) == TYPE_DICTIONARY:
			out.merge(d, true)
	_cache[key] = out
	return out


static func _merged_array(key: String, pattern: String, const_name: String) -> Array:
	if _cache.has(key):
		return _cache[key]
	var out := []
	for ext in EXTS:
		var a: Variant = _const(pattern % ext, const_name)
		if typeof(a) == TYPE_ARRAY:
			out.append_array(a)
	_cache[key] = out
	return out


static func _scripts(key: String, pattern: String) -> Array:
	if _cache.has(key):
		return _cache[key]
	var out := []
	for ext in EXTS:
		var s := _script(pattern % ext)
		if s:
			out.append(s)
	_cache[key] = out
	return out


static func enemy_kinds() -> Dictionary:
	return _merged_dict("enemies", "res://enemies/%s/registry.gd", "KINDS")


static func entity_kinds() -> Dictionary:
	return _merged_dict("entities", "res://world/entities/%s/entities.gd", "KINDS")


static func ally_kinds() -> Dictionary:
	return _merged_dict("allies", "res://allies/%s_allies.gd", "KINDS")


static func themes() -> Dictionary:
	return _merged_dict("themes", "res://world/themes/themes_%s.gd", "THEMES")


## 인물 (같은 ID가 여러 장에 있으면 뒤 장 항목이 통째로 이김 — 키 단위 합치기는 Characters.info)
static func characters() -> Dictionary:
	return _merged_dict("characters", DATA, "CHARACTERS")


## 장마다의 CHARACTERS 사전 (EXTS 순서) — Characters.info가 키 단위로 합친다
static func character_tables() -> Array:
	if _cache.has("character_tables"):
		return _cache["character_tables"]
	var out := []
	for ext in EXTS:
		var d: Variant = _const(DATA % ext, "CHARACTERS")
		if typeof(d) == TYPE_DICTIONARY:
			out.append(d)
	_cache["character_tables"] = out
	return out


static func quests() -> Dictionary:
	return _merged_dict("quests", DATA, "QUESTS")


static func rooms() -> Array:
	return _merged_array("rooms", DATA, "ROOMS")


static func objectives() -> Array:
	return _merged_array("objectives", DATA, "OBJECTIVES")


## 한 확장(장)의 목표 줄만 (HUD 현재 목표는 지금 장 것만 본다)
static func objectives_of(ext: String) -> Array:
	var a: Variant = _const(DATA % ext, "OBJECTIVES")
	return a if typeof(a) == TYPE_ARRAY else []


## 대본 파일 경로 (data의 SCRIPTS를 EXTS 순서로). 웹 내보내기에서 폴더 나열을 믿을 수 없어서 명시 목록
static func script_paths() -> Array:
	return _merged_array("scripts", DATA, "SCRIPTS")


# ─── 장 정보 (CHAPTER) ───────────────────────────────────

## 장 정보를 EXTS 순서로 (CHAPTER가 있는 확장만)
static func chapters() -> Array:
	if _cache.has("chapters"):
		return _cache["chapters"]
	var out := []
	for ext in EXTS:
		var d: Variant = _const(DATA % ext, "CHAPTER")
		if typeof(d) == TYPE_DICTIONARY:
			out.append(d)
	_cache["chapters"] = out
	return out


## n장 정보 ({} = 없음)
static func chapter(n: int) -> Dictionary:
	for d: Dictionary in chapters():
		if int(d.get("n", 0)) == n:
			return d
	return {}


## 지역 ID → 지도 제목 (모든 장의 areas)
static func area_names() -> Dictionary:
	if _cache.has("areas"):
		return _cache["areas"]
	var out := {}
	for d: Dictionary in chapters():
		out.merge(d.get("areas", {}), true)
	_cache["areas"] = out
	return out


## 전이진 목적지 (모든 장의 warps, 장 순서)
static func warp_points() -> Array:
	if _cache.has("warps"):
		return _cache["warps"]
	var out := []
	for d: Dictionary in chapters():
		out.append_array(d.get("warps", []))
	_cache["warps"] = out
	return out


static func backdrop_scripts() -> Array:
	return _scripts("backdrops", "res://world/themes/backdrop_%s.gd")


static func prop_scripts() -> Array:
	return _scripts("props", "res://world/entities/%s/props.gd")
