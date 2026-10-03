class_name Objectives
extends RefCounted
## 현재 목표 (docs/chapter1.md 4.5절): 위에서부터 "필요 플래그는 섰고 완료 플래그는 아직인" 첫 항목.
## [완료 플래그, 표시 문구, 필요 플래그(비우면 항상)]

const LIST := [
	["t_trial_done", "신계 깊은 곳의 보물을 찾아라", ""],
	["t_escaped", "무너지는 신계에서 빠져나가라", "t_trial_done"],
	["met_emberlyn", "마법반 실습에 가자 (서관 1층)", "s_woke"],
	["ab_storm", "실습장에서 과제를 마치자", "met_emberlyn"],
	["key_stolen", "도서관에서 봉인 기록을 찾자 (중앙 홀 2층)", "ab_storm"],
	["ab_double_jump", "비속성마법반에서 부양을 배우자 (서관 복도 아래층)", "key_stolen"],
	["key_recovered", "서가 미로에서 마도서를 쫓아라", "ab_double_jump"],
	["ab_fox_window", "금서 구역에서 봉인 기록을 읽자", "key_recovered"],
	["adv_done", "서가 미로 꼭대기 오른쪽 벽에 여우창문(D) → 고급마법반으로", "ab_fox_window"],
	["met_astrid", "시계탑 꼭대기의 교장실로", "adv_done"],
	["s_cellar_seen", "앞마당의 지하 철문으로 내려가자", "met_astrid"],
	["seal_open", "봉인 회랑의 촛대를 순서대로 밝히자", "s_cellar_seen"],
	["agwi_defeated", "봉인의 방으로", "seal_open"],
	["chapter_end", "기숙사로 돌아가 쉬자", "agwi_defeated"],
]


static var _all: Array = []


## 1장 목록 + 장별 확장(story/data_<장>.gd 의 OBJECTIVES)을 장 순서대로
static func all() -> Array:
	if _all.is_empty():
		_all = LIST.duplicate()
		_all.append_array(ChapterRegistry.objectives())
	return _all


## 지금 장(플래그 chapter)의 목표 줄 (+ 공통 sys). 앞 장의 선택 목표가 남아 HUD를 가리지 않게
static func for_chapter(n: int) -> Array:
	var out: Array = LIST.duplicate() if n <= 1 else ChapterRegistry.objectives_of("ch%d" % n)
	out.append_array(ChapterRegistry.objectives_of("sys"))
	return out


static func current() -> String:
	for row in for_chapter(int(GameState.flag("chapter", 1))):
		var req: String = row[2]
		if req != "" and not GameState.has_flag(req):
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
