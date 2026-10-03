class_name ChapterRegistry
extends RefCounted
## 장별 확장 모듈 모음 (docs/systems2.md 1절). 2~5장과 공통 시스템(sys)은 공용 파일을 고치지 않고
## 자기 파일에 상수만 적으면 여기서 합쳐진다 → 여러 사람이(서브에이전트가) 동시에 만들어도 충돌하지 않는다.
##
## 확장 ID(EXTS)마다 다음 파일이 있으면 읽는다 (없으면 건너뜀):
##   res://story/data_<ext>.gd            const CHARACTERS(인물), ROOMS(방 ID 목록), OBJECTIVES(메인 목표 줄), QUESTS(퀘스트)
##   res://story/scripts_<ext>.gd         대본 메서드 (Story가 읽음)
##   res://enemies/<ext>/registry.gd      const KINDS (적 종류 → 스크립트 경로)
##   res://world/entities/<ext>/entities.gd  const KINDS (방 개체 종류 → 스크립트 경로)
##   res://world/entities/<ext>/props.gd  static func setup_info(kind, prop) -> Dictionary, static func draw(prop, kind) -> bool
##   res://world/themes/themes_<ext>.gd   const THEMES (테마 ID → 색 사전, RoomTheme와 같은 키)
##   res://world/themes/backdrop_<ext>.gd static func draw_layer/draw_sky/draw_front/is_animated (RoomBackdrop 참고)
##   res://allies/<ext>_allies.gd         const KINDS (동료 종류 → 스크립트 경로)

const EXTS := ["sys", "ch2", "ch3", "ch4", "ch5"]

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


static func characters() -> Dictionary:
	return _merged_dict("characters", "res://story/data_%s.gd", "CHARACTERS")


static func quests() -> Dictionary:
	return _merged_dict("quests", "res://story/data_%s.gd", "QUESTS")


static func rooms() -> Array:
	return _merged_array("rooms", "res://story/data_%s.gd", "ROOMS")


static func objectives() -> Array:
	return _merged_array("objectives", "res://story/data_%s.gd", "OBJECTIVES")


static func script_paths() -> Array:
	var out := []
	for ext in EXTS:
		var p := "res://story/scripts_%s.gd" % ext
		if ResourceLoader.exists(p):
			out.append(p)
	return out


static func backdrop_scripts() -> Array:
	return _scripts("backdrops", "res://world/themes/backdrop_%s.gd")


static func prop_scripts() -> Array:
	return _scripts("props", "res://world/entities/%s/props.gd")
