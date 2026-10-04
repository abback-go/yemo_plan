extends RoomData
## 자동 생성: tools/roomgen.py — 직접 고치지 말고 생성기를 고친 뒤 다시 만들 것
## 정의: tools/roomgen.py t_throne()


func _init() -> void:
	id = "t_throne"
	title = "신계 · 왕좌의 전당"
	area = "shingye"
	theme = "shrine"
	music = "shingye_tension"
	cell = Vector2i(6, 0)
	cells = Vector2i(1, 1)
	map = """
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
#......................................#
#......................................#
#.......................................
#.......................................
#.......................................
#........................############...
#......................##############...
########################################
########################################
########################################
########################################
"""
	entities = [
		{t = "exit", id = "east", x = 39, y = 14, w = 1, h = 5, to = "t_collapse", to_id = "west"},
		{t = "spawn", id = "chained", x = 10, y = 19, face = "right"},
		{t = "spawn", id = "after", x = 14, y = 19, face = "right"},
		{t = "prop", kind = "throne", x = 31, y = 17},
		{t = "prop", kind = "altar", x = 19, y = 19},
		{t = "actor", id = "bead", who = "bead", kind = "bead", x = 19, y = 16, cond = "!p_bead_done"},
		{t = "actor", id = "god", who = "neoul_god", kind = "neoul_god", x = 30, y = 17, face = "left", hidden = true, cond = "!p_bead_done"},
		{t = "actor", id = "chains", who = "chains", kind = "chains", x = 10, y = 19, cond = "!p_bead_done"},
		{t = "prop", kind = "curtain", x = 3, y = 1, w = 2, h = 12},
		{t = "prop", kind = "curtain", x = 37, y = 1, w = 2, h = 12},
		{t = "prop", kind = "fox_statue", x = 22, y = 19, flip = false},
		{t = "prop", kind = "fox_statue", x = 38, y = 19, flip = true},
		{t = "prop", kind = "chain", x = 8, y = 1, h = 3},
		{t = "prop", kind = "chain", x = 16, y = 1, h = 3},
		{t = "prop", kind = "chain", x = 24, y = 1, h = 3},
		{t = "prop", kind = "banner", x = 31, y = 1, h = 7, col = Color("#2a3a7a")},
		{t = "light", x = 26, y = 13, r = 4, color = Color("#6ab0ff")},
		{t = "light", x = 36, y = 13, r = 4, color = Color("#6ab0ff")},
	]
