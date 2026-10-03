extends RoomData
## 자동 생성: tools/roomgen.py — 직접 고치지 말고 생성기를 고친 뒤 다시 만들 것


func _init() -> void:
	id = "st_festival"
	title = "마녀학교 · 축제 광장"
	area = "school"
	theme = "festival"
	music = "festival"
	cell = Vector2i(8, 3)
	cells = Vector2i(3, 1)
	map = """
#......................................................................................................................#
#......................................................................................................................#
#......................................................................................................................#
#......................................................................................................................#
#......................................................................................................................#
#......................................................................................................................#
#......................................................................................................................#
#......................................................................................................................#
#......................................................................................................................#
#......................................................................................................................#
#......................................................................................................................#
#.......................................................................................................===========....#
#......................................................................................................................#
#......................................................................................................................#
#......................................................................................................................#
#.................................................................................................======...............#
#.....................................................#################................................................#
#.................................................====#################................................................#
#.....................................................#################................................................#
########################################################################################################################
########################################################################################################################
########################################################################################################################
########################################################################################################################
"""
	entities = [
		{t = "door", id = "yard", x = 4, y = 19, to = "s_courtyard", to_id = "festival", style = "grand", label = "앞마당"},
		{t = "save", id = "fest", x = 9, y = 19, style = "candle"},
		{t = "spawn", id = "stage", x = 62, y = 16, face = "left"},
		{t = "spawn", id = "evening", x = 44, y = 19, face = "right"},
		{t = "spawn", id = "deck", x = 106, y = 11, face = "right"},
		{t = "prop", kind = "st_festival_stall", x = 16, y = 19, style = "potion"},
		{t = "prop", kind = "st_festival_stall", x = 28, y = 19, style = "kingdom"},
		{t = "prop", kind = "st_festival_stall", x = 40, y = 19, style = "elf"},
		{t = "prop", kind = "st_festival_stall", x = 46, y = 19, style = "mask"},
		{t = "prop", kind = "st_festival_stall", x = 80, y = 19, style = "temple"},
		{t = "prop", kind = "st_festival_stall", x = 91, y = 19, style = "food"},
		{t = "npc", id = "pippa", who = "pippa", x = 19, y = 19, face = "left", cond = "st_fest,!st_lyra_came"},
		{t = "npc", id = "leonie", who = "leonie", x = 31, y = 19, face = "left", cond = "st_fest,!st_lyra_came"},
		{t = "npc", id = "elarien", who = "elarien", x = 43, y = 19, face = "left", cond = "st_fest,!st_lyra_came"},
		{t = "npc", id = "aurelia", who = "aurelia", x = 83, y = 19, face = "left", cond = "st_fest,!st_lyra_came"},
		{t = "npc", id = "butterworth", who = "butterworth", x = 94, y = 19, face = "left", cond = "st_fest,!st_lyra_came"},
		{t = "npc", id = "isolde", who = "isolde", x = 60, y = 16, face = "right", cond = "st_fest,!st_lyra_came"},
		{t = "npc", id = "emberlyn", who = "emberlyn", x = 68, y = 16, face = "left", cond = "st_fest,!st_lyra_came"},
		{t = "npc", id = "mirabel", who = "mirabel", x = 100, y = 19, face = "left", cond = "st_fest,!st_lyra_came"},
		{t = "npc", id = "ophelia", who = "ophelia", x = 110, y = 11, face = "right", cond = "st_fest,!st_lyra_came"},
		{t = "npc", id = "stu_a", who = "student_a", x = 34, y = 19, face = "right", talk = "npc_st_fest_a", cond = "st_fest,!st_lyra_came"},
		{t = "npc", id = "stu_b", who = "student_b", x = 52, y = 19, face = "right", talk = "npc_st_fest_b", cond = "st_fest,!st_lyra_came"},
		{t = "npc", id = "stu_c", who = "student_c", x = 75, y = 19, face = "left", talk = "npc_st_fest_c", cond = "st_fest,!st_lyra_came"},
		{t = "npc", id = "mirabel_after", who = "mirabel", x = 100, y = 19, face = "left", cond = "st_lyra_came,!st_invaded"},
		{t = "npc", id = "pippa_epi", who = "pippa", x = 19, y = 19, face = "left", cond = "ch5_done"},
		{t = "npc", id = "butterworth_epi", who = "butterworth", x = 94, y = 19, face = "left", cond = "ch5_done"},
		{t = "npc", id = "isolde_epi", who = "isolde", x = 60, y = 16, face = "left", cond = "ch5_done"},
		{t = "npc", id = "student_a_epi", who = "student_a", x = 34, y = 19, face = "left", cond = "ch5_done"},
		{t = "npc", id = "student_c_epi", who = "student_c", x = 75, y = 19, face = "left", cond = "ch5_done"},
		{t = "trigger", id = "st_evening", x = 55, y = 10, w = 15, h = 6, run = "st_evening_ask", once = false, cond = "st_fest_ready,!st_lyra_came"},
		{t = "prop", kind = "st_flower_arch", x = 6, y = 19},
		{t = "prop", kind = "st_lantern_string", x = 2, y = 3, w = 18, sag = 3},
		{t = "prop", kind = "st_lantern_string", x = 20, y = 2, w = 16, sag = 2},
		{t = "prop", kind = "st_lantern_string", x = 36, y = 3, w = 18, sag = 3},
		{t = "prop", kind = "st_lantern_string", x = 72, y = 2, w = 18, sag = 3},
		{t = "prop", kind = "st_lantern_string", x = 90, y = 3, w = 16, sag = 2},
		{t = "prop", kind = "st_garland", x = 54, y = 6, w = 17},
		{t = "prop", kind = "st_festival_banner", x = 53, y = 16, h = 7},
		{t = "prop", kind = "st_festival_banner", x = 71, y = 16, h = 7},
		{t = "prop", kind = "st_balloon_cluster", x = 24, y = 19},
		{t = "prop", kind = "st_balloon_cluster", x = 97, y = 19},
		{t = "prop", kind = "st_tea_table", x = 86, y = 19},
		{t = "prop", kind = "st_telescope", x = 112, y = 11},
		{t = "prop", kind = "st_star_chart", x = 107, y = 11, w = 2, h = 2},
		{t = "prop", kind = "torch", x = 12, y = 19},
		{t = "prop", kind = "torch", x = 50, y = 19},
		{t = "prop", kind = "torch", x = 74, y = 19},
		{t = "prop", kind = "torch", x = 96, y = 19},
		{t = "prop", kind = "magic_circle", x = 62, y = 16, w = 12, col = Color("#ffc870")},
		{t = "sign", x = 11, y = 19, look = "board", text = "마녀학교 축제|낮: 가게와 요리 대회 / 해 질 녘: 무도회와 불꽃놀이|별 관측대는 오른쪽 비계 위. 오필리아 교수님이 (아마) 깨어 계십니다."},
		{t = "light", x = 62, y = 13, r = 7, color = Color("#ffc870")},
	]
