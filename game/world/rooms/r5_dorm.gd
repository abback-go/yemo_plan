extends RoomData
## 자동 생성: tools/roomgen.py — 직접 고치지 말고 생성기를 고친 뒤 다시 만들 것
## 정의: tools/rooms/ch5.py r5_dorm()


func _init() -> void:
	id = "r5_dorm"
	title = "무너진 학교 · 기숙사 대피소"
	area = "school"
	theme = "ruin_school"
	music = "despair"
	cell = Vector2i(8, 1)
	cells = Vector2i(1, 1)
	dark = 0.1
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
........................................
........................................
........................................
........................................
........................................
########################################
########################################
########################################
########################################
"""
	entities = [
		{t = "exit", id = "east", x = 39, y = 14, w = 1, h = 5, to = "r5_library", to_id = "west"},
		{t = "exit", id = "west", x = 0, y = 14, w = 1, h = 5, to = "r5_courtyard", to_id = "east"},
		{t = "spawn", id = "start", x = 36, y = 19, face = "left"},
		{t = "save", id = "bed", x = 30, y = 19, style = "bed"},
		{t = "npc", id = "astrid", who = "astrid", x = 14, y = 19, face = "right", cond = "!st_dorm_seen"},
		{t = "npc", id = "mirabel", who = "mirabel", x = 8, y = 19, face = "right", cond = "!st_dorm_seen"},
		{t = "npc", id = "stu_c", who = "student_c", x = 20, y = 19, face = "left", talk = "npc_r5_stu", cond = "!st_dorm_seen"},
		{t = "st_follow", id = "followers", who = ["pippa", "student_a", "student_b"], cond = "st_escort"},
		{t = "prop", kind = "st_comm_crystal", x = 24, y = 19, on = true},
		{t = "spawn", id = "comm", x = 22, y = 19, face = "right"},
		{t = "prop", kind = "bed_prop", x = 12, y = 19},
		{t = "prop", kind = "bed_prop", x = 26, y = 19},
		{t = "prop", kind = "st_rubble", x = 34, y = 19, w = 3},
		{t = "prop", kind = "candles", x = 17, y = 19},
		{t = "st_quake", x = 0, y = 0, strength = 0.4},
	]
