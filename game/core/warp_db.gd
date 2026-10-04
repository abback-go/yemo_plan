class_name WarpDB
extends RefCounted
## 전이진 목적지 (docs/systems2.md 6절). 목록은 각 story/data_<장>.gd 의 CHAPTER.warps (ChapterRegistry.warp_points):
##   [영역, 방 ID, 등장 위치 ID, 이름, 해금 플래그("" = 항상)]
## 각 지역 작업자는 이 방·등장 위치를 만들고 거기에 {t = "warp"} 개체를 둔다.


## 지금 갈 수 있는 목적지 (방 파일이 있는 것만)
static func unlocked() -> Array:
	var out: Array = []
	for p in ChapterRegistry.warp_points():
		var flag := String(p[4])
		if flag != "" and not GameState.has_flag(flag):
			continue
		if not ResourceLoader.exists("res://world/rooms/%s.gd" % String(p[1])):
			continue
		out.append(p)
	return out
