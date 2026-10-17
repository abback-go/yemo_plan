extends RoomData
## 자동 생성: tools/roomgen.py — 직접 고치지 말고 생성기를 고친 뒤 다시 만들 것
## 정의: tools/roomgen.py s_cafeteria()


func _init() -> void:
	id = "s_cafeteria"
	title = "마녀학교 · 식당"
	area = "school"
	theme = "room"
	music = "school"
	cell = Vector2i(6, 3)
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
#......................................#
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
		{t = "door", id = "up", x = 4, y = 19, to = "s_eastcorr", to_id = "down", style = "stair_up", label = "동관 복도"},
		{t = "exit", id = "east", x = 39, y = 14, w = 1, h = 5, to = "s_alchemy", to_id = "west"},
		{t = "npc", id = "butter", who = "butterworth", x = 26, y = 19, face = "left"},
		{t = "npc", id = "stu", who = "student_a", x = 13, y = 19, face = "right", talk = "npc_cafe"},
		{t = "prop", kind = "cauldron", x = 30, y = 19},
		{t = "prop", kind = "desk", x = 10, y = 19, w = 3, books = false},
		{t = "prop", kind = "desk", x = 17, y = 19, w = 3, books = false},
		{t = "prop", kind = "potion_shelf", x = 35, y = 19, w = 3, h = 4},
		{t = "prop", kind = "chandelier", x = 14, y = 2, len = 3},
		{t = "prop", kind = "window", x = 20, y = 10, w = 3, h = 5},
		# 덧붙임(overlay): tools/rooms/ch2.py
		{t = "npc", id = "k_pippa_am", who = "pippa", x = 18, y = 19, face = "left", cond = "ch1_done,!k_breakfast"},
		{t = "npc", id = "k_isolde_am", who = "isolde", x = 21, y = 19, face = "left", cond = "ch1_done,!k_breakfast"},
		{t = "trigger", id = "k_morning", x = 7, y = 13, w = 4, h = 6, run = "k_cafe_morning", cond = "ch1_done,!k_breakfast", once = false},
		# 덧붙임(overlay): tools/rooms/ch5.py
		{t = "prop", kind = "st_garland", x = 4, y = 6, w = 30, cond = "st_fest,!st_invaded"},
		{t = "pickup", id = "st_ing_honey", kind = "key", x = 36, y = 19, name = "별사탕 꿀", flag = "st_ing_honey", text = "축제용 별사탕 꿀 한 병. 피피의 물약 재료다.", cond = "q_st_pippa_stall"},
	]
