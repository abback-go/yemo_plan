extends RoomData
## 자동 생성: tools/roomgen.py — 직접 고치지 말고 생성기를 고친 뒤 다시 만들 것


func _init() -> void:
	id = "e_moonwell"
	title = "세계수 · 달샘"
	area = "elf"
	theme = "elf"
	music = "elf"
	cell = Vector2i(21, 2)
	cells = Vector2i(1, 1)
	map = """
########################################
#.................................##...#
#.................................##...#
#.................................##...#
#.................................##...#
#.................................##...#
#.................................##...#
#.................................##...#
#.................................##...#
#.................................##...#
#.................................##...#
#.................................##...#
#.................................##...#
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
		{t = "exit", id = "west", x = 0, y = 14, w = 1, h = 5, to = "e_branch_homes", to_id = "east_high"},
		{t = "exit", id = "east", x = 39, y = 14, w = 1, h = 5, to = "e_blight_1", to_id = "west"},
		{t = "moon_crystal", id = "mc0", x = 10, y = 1, group = "moon", done_flag = "e_moon_puzzle"},
		{t = "moon_drop", id = "md0", x = 10, y = 4, period = 2.4, phase = 0.0, on_if = "e_moon_talk"},
		{t = "moon_crystal", id = "mc1", x = 18, y = 1, group = "moon", done_flag = "e_moon_puzzle"},
		{t = "moon_drop", id = "md1", x = 18, y = 4, period = 2.4, phase = 0.8, on_if = "e_moon_talk"},
		{t = "moon_crystal", id = "mc2", x = 26, y = 1, group = "moon", done_flag = "e_moon_puzzle"},
		{t = "moon_drop", id = "md2", x = 26, y = 4, period = 2.4, phase = 1.6, on_if = "e_moon_talk"},
		{t = "puzzle", id = "pz", group = "moon", mode = "all", done_flag = "e_moon_puzzle"},
		{t = "event", id = "ev", flag = "e_moon_puzzle", run = "e_moon_lesson", done = "e_moon_lesson_run"},
		{t = "trigger", id = "t_moon", x = 4, y = 11, w = 2, h = 8, run = "e_moon_arrive", cond = "e_wind_done,!e_moon_talk"},
		{t = "root_gate", id = "rg", x = 34, y = 13, w = 2, h = 6, open_if = "e_moon_lesson"},
		{t = "pickup", id = "moonleaf", kind = "key", x = 30, y = 19, name = "달샘의 달잎", flag = "e_tea_leaf", text = "달빛을 머금어 은빛으로 빛나는 잎. 장로님 차에 들어간다고 했다."},
		{t = "prop", kind = "moonwell", x = 18, y = 19, w = 8},
		{t = "prop", kind = "fern", x = 3, y = 19},
		{t = "prop", kind = "fern", x = 31, y = 19},
		{t = "prop", kind = "vine_curtain", x = 2, y = 1, w = 3, h = 6},
		{t = "prop", kind = "spirit_statue", x = 7, y = 19},
		{t = "light", x = 18, y = 2, r = 6, color = Color("#b8c8ff")},
		{t = "prop", kind = "blight_crystal", x = 37, y = 19, h = 1},
		{t = "prop", kind = "blight_growth", x = 38, y = 19, w = 1},
	]
