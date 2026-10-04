class_name Objectives
extends RefCounted
## 현재 목표 (docs/chapter1.md 4.5절): 위에서부터 "필요 조건은 참이고 완료 플래그는 아직인" 첫 항목.
## 데이터는 장마다 story/data_<장>.gd 의 OBJECTIVES: [완료 플래그, 표시 문구, 필요 조건(Cond 식, 비우면 항상)]


## 모든 장의 목표 줄 (장 순서)
static func all() -> Array:
	return ChapterRegistry.objectives()


## 지금 장(플래그 chapter)의 목표 줄 (+ 공통 sys). 앞 장의 선택 목표가 남아 HUD를 가리지 않게
static func for_chapter(n: int) -> Array:
	# 장별 OBJECTIVES는 상수(읽기 전용)라 반드시 복사해서 이어 붙인다
	var out: Array = ChapterRegistry.objectives_of("ch%d" % maxi(n, 1)).duplicate()
	out.append_array(ChapterRegistry.objectives_of("sys"))
	return out


## HUD가 매 프레임 부른다 — for_chapter처럼 배열을 만들지 않고 지금 장 줄 → sys 줄 차례로 본다
static func current() -> String:
	var n := maxi(int(GameState.flag("chapter", 1)), 1)
	for rows: Array in [ChapterRegistry.objectives_of("ch%d" % n), ChapterRegistry.objectives_of("sys")]:
		for row in rows:
			if not Cond.ok(String(row[2])):
				continue
			if GameState.has_flag(row[0]):
				continue
			return row[1]
	return ""


static func done_list() -> Array:
	var out := []
	for row in all():
		if GameState.has_flag(row[0]):
			out.append(row[1])
	return out
