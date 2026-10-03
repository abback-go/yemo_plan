extends RoomData
## 자동 생성: tools/roomgen.py — 직접 고치지 말고 생성기를 고친 뒤 다시 만들 것


func _init() -> void:
	id = "st_trial_s1"
	title = "별의 정원 · 첫째 뜰"
	area = "star"
	theme = "st_garden"
	music = "school_day"
	cell = Vector2i(1, 1)
	cells = Vector2i(1, 1)
	map = """
#......................................#
#......................................#
#......................................#
#......................................#
#......................................#
#......................................#
#......................................#
#...=====..............................#
#.......................................
#.......................................
#.......................................
#........=====..........................
#.......................................
#...........................############
#...........................############
#..======...................############
#...........................############
#...........................############
#...........................############
###############.............############
###############.............############
###############^^^^^^^^^^^^^############
########################################
"""
	entities = [
		{t = "door", id = "in", x = 3, y = 19, to = "st_crossroads", to_id = "s", style = "st", label = "별의 문간"},
		{t = "prop", kind = "st_star_door", x = 3, y = 19, col = "s", open_if = "st_lyra_came"},
		{t = "spawn", id = "start", x = 6, y = 19, face = "right"},
		{t = "exit", id = "east", x = 39, y = 8, w = 1, h = 5, to = "st_trial_s", to_id = "west"},
		{t = "star_point", id = "sg10", group = "sg1", x = 13, y = 18, order = 0, count = 5, done_flag = "st_s1_stars"},
		{t = "star_point", id = "sg11", group = "sg1", x = 2, y = 14, order = 1, count = 5, done_flag = "st_s1_stars"},
		{t = "star_point", id = "sg12", group = "sg1", x = 14, y = 14, order = 2, count = 5, done_flag = "st_s1_stars"},
		{t = "star_point", id = "sg13", group = "sg1", x = 5, y = 10, order = 3, count = 5, done_flag = "st_s1_stars"},
		{t = "star_point", id = "sg14", group = "sg1", x = 12, y = 6, order = 4, count = 5, done_flag = "st_s1_stars"},
		{t = "st_bridge", id = "bridge", pts = [[14, 19], [18, 17], [23, 15], [27, 13]], on_if = "st_s1_stars"},
		{t = "updraft", id = "sd", x = 21, y = 6, w = 3, h = 13, style = "star", on_if = "st_s1_stars"},
		{t = "prop", kind = "st_star_chart", x = 34, y = 13, w = 3, h = 2},
		{t = "event", id = "ev", flag = "st_s1_stars", run = "st_s1_done"},
		{t = "prop", kind = "plant", x = 2, y = 19},
		{t = "prop", kind = "plant", x = 36, y = 13},
		{t = "sign", x = 10, y = 19, look = "board", text = "별의 정원 · 첫째 뜰|별은 아래에서 위로, 가까운 것부터 먼 것으로 잇는다.|틀리면 별이 꺼지니 처음부터. — 오필리아 (별 관측반)"},
	]
