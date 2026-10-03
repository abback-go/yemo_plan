extends RoomData
## 자동 생성: tools/roomgen.py — 직접 고치지 말고 생성기를 고친 뒤 다시 만들 것


func _init() -> void:
	id = "s_observatory"
	title = "마녀학교 · 시계탑 지붕"
	area = "school"
	theme = "observatory"
	music = "school"
	cell = Vector2i(6, -1)
	cells = Vector2i(1, 1)
	map = """
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
#...............................======.#
#......................................#
#..=====........=======................#
#......................................#
#..........................###.........#
#.........###..............###.........#
#.........###..............###.........#
#.........###..............###.........#
#.........###..............###.........#
########################################
########################################
########################################
########################################
"""
	entities = [
		{t = "door", id = "down", x = 4, y = 19, to = "s_clock", to_id = "roof", style = "stair_down", label = "시계탑"},
		{t = "star_point", id = "st0", group = "lyra", x = 5, y = 6, order = 0, count = 7, done_flag = "stars_done", cond = "q_cls_meteor"},
		{t = "star_point", id = "st1", group = "lyra", x = 13, y = 4, order = 1, count = 7, done_flag = "stars_done", cond = "q_cls_meteor"},
		{t = "star_point", id = "st2", group = "lyra", x = 19, y = 7, order = 2, count = 7, done_flag = "stars_done", cond = "q_cls_meteor"},
		{t = "star_point", id = "st3", group = "lyra", x = 24, y = 3, order = 3, count = 7, done_flag = "stars_done", cond = "q_cls_meteor"},
		{t = "star_point", id = "st4", group = "lyra", x = 30, y = 5, order = 4, count = 7, done_flag = "stars_done", cond = "q_cls_meteor"},
		{t = "star_point", id = "st5", group = "lyra", x = 35, y = 2, order = 5, count = 7, done_flag = "stars_done", cond = "q_cls_meteor"},
		{t = "star_point", id = "st6", group = "lyra", x = 36, y = 13, order = 6, count = 7, done_flag = "stars_done", cond = "q_cls_meteor"},
		{t = "event", id = "ev", flag = "stars_done", run = "cls_meteor_stars_done", done = "cls_meteor_stars_seen"},
		{t = "npc", id = "ophelia", who = "ophelia", x = 20, y = 19, face = "left", cond = "cls_meteor_roof,!stars_done"},
		{t = "prop", kind = "globe", x = 22, y = 19},
		{t = "prop", kind = "magic_circle", x = 20, y = 19, w = 8, col = Color("#ffe39a")},
		{t = "prop", kind = "candles", x = 8, y = 19},
		{t = "sign", x = 34, y = 19, look = "board", text = "별 관측대|별자리는 정해진 순서로 이어야 빛난다.|가장 밝은 별에서 시작할 것. — 시계탑 관리인"},
	]
