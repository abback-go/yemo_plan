class_name Characters
extends RefCounted
## 등장인물 정보 찾기. 데이터는 장마다 story/data_<장>.gd 의 CHARACTERS (1장 학교 인물은 data_ch1.gd — 값 설명도 거기).


static var _merged := {}


## 인물 정보: 장별 CHARACTERS를 장 순서로 키 단위로 합침 — 같은 ID면 뒤 장의 키가 덮어씀
## (예: 5장이 교장에게 전용 그림만 덧붙임). 없는 ID는 이름 없는 학생(student_a)
static func info(who: String) -> Dictionary:
	if _merged.has(who):
		return _merged[who]
	var out := {}
	var n := 0
	for t: Dictionary in ChapterRegistry.character_tables():
		if not t.has(who):
			continue
		if n == 0:
			out = t[who] # 하나뿐이면 상수 그대로 (복사 안 함)
		else:
			if n == 1:
				out = out.duplicate()
			out.merge(t[who], true)
		n += 1
	if n == 0:
		return info("student_a")
	_merged[who] = out
	return out


static func display_name(who: String) -> String:
	return String(info(who).get("name", who))
