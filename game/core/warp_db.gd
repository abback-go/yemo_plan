class_name WarpDB
extends RefCounted
## 전이진 목적지 (docs/systems2.md 6절). [영역, 방 ID, 등장 위치 ID, 이름, 해금 플래그("" = 항상)]
## 각 지역 작업자는 이 방·등장 위치를 만들고 거기에 {t = "warp"} 개체를 둔다.

const POINTS := [
	["school", "s_courtyard", "warp", "마녀학교 — 앞마당", ""],
	["kingdom", "k_embassy", "warp", "아르덴 제국 — 공관", "warp_kingdom"],
	["elf", "e_gate", "warp", "엘프의 숲 — 입구", "warp_elf"],
	["temple", "tp_road", "warp", "성산 — 순례길", "warp_temple"],
]


## 지금 갈 수 있는 목적지 (방 파일이 있는 것만)
static func unlocked() -> Array:
	var out: Array = []
	for p in POINTS:
		var flag := String(p[4])
		if flag != "" and not GameState.has_flag(flag):
			continue
		if not ResourceLoader.exists("res://world/rooms/%s.gd" % String(p[1])):
			continue
		out.append(p)
	return out
