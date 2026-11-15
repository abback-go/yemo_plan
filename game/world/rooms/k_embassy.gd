extends RoomData
## 자동 생성: tools/roomgen.py — 직접 고치지 말고 생성기를 고친 뒤 다시 만들 것
## 정의: tools/rooms/ch2.py k_embassy()


func _init() -> void:
	id = "k_embassy"
	title = "황도 아르덴 · 공관"
	area = "kingdom"
	theme = "kingdom_in"
	music = "kingdom"
	cell = Vector2i(0, 4)
	cells = Vector2i(1, 1)
	map = """
########################################
########################################
#......................................#
#......................................#
#......................................#
#......................................#
#......................................#
#......................................#
#......................................#
#......................................#
#......................................#
#......................................#
#......................................#
#.========.............................#
#.......................................
#.......................................
#.......................................
#.......................................
#.......................................
########################################
########################################
########################################
########################################
"""
	entities = [
		{t = "exit", id = "east", x = 39, y = 14, w = 1, h = 5, to = "k_gate_street", to_id = "west"},
		{t = "warp", id = "warp_circle", x = 20, y = 19, area = "kingdom"},
		{t = "spawn", id = "warp", x = 20, y = 19, face = "right"},
		{t = "save", id = "candle", x = 6, y = 19, style = "candle"},
		{t = "npc", id = "emberlyn", who = "emberlyn", x = 27, y = 19, face = "left", cond = "k_departed"},
		{t = "npc", id = "pippa", who = "pippa", x = 12, y = 19, face = "right", cond = "k_departed"},
		{t = "npc", id = "isolde", who = "isolde", x = 33, y = 19, face = "left", cond = "k_departed,!k_race_ready"},
		{t = "npc", id = "isolde2", who = "isolde", x = 33, y = 19, face = "left", cond = "k_race_won"},
		{t = "prop", kind = "magic_circle", x = 20, y = 19, w = 6, col = Color("#b8a8ff")},
		{t = "prop", kind = "cauldron", x = 15, y = 19},
		{t = "prop", kind = "bookshelf", x = 4, y = 13, w = 4, h = 5},
		{t = "prop", kind = "rug", x = 20, y = 19, w = 12},
		{t = "prop", kind = "chandelier", x = 20, y = 2, len = 3},
		{t = "prop", kind = "window", x = 12, y = 10, w = 3, h = 6},
		{t = "prop", kind = "window", x = 28, y = 10, w = 3, h = 6},
		{t = "prop", kind = "banner", x = 8, y = 3, h = 6, col = Color("#2a1e4a")},
		{t = "prop", kind = "k_banner", x = 32, y = 2, w = 2, h = 5},
		{t = "prop", kind = "desk", x = 30, y = 19, w = 3},
		{t = "prop", kind = "plant", x = 37, y = 19},
		{t = "sign", x = 24, y = 19, look = "board", text = "제국 주재 마녀학교 공관|전이진: ↑ — 학교 앞마당과 이어져 있다.|공관장 부재 중. 용무는 엠버린 교수에게.|[주의] 공관 밖에서는 제국 법을 따를 것. 거리에서 불 쓰지 말 것. (특히 세라)"},
	]
