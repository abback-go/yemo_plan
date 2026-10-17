extends RoomData
## 자동 생성: tools/roomgen.py — 직접 고치지 말고 생성기를 고친 뒤 다시 만들 것
## 정의: tools/roomgen.py s_courtyard()


func _init() -> void:
	id = "s_courtyard"
	title = "마녀학교 · 앞마당"
	area = "school"
	theme = "exterior"
	music = "school"
	cell = Vector2i(4, 3)
	cells = Vector2i(2, 1)
	map = """
#..............................................................................#
#..............................................................................#
#..............................................................................#
#..............................................................................#
#..............................................................................#
#..............................................................................#
#..............................................................................#
#..............................................................................#
#..............................................................................#
#..............................................................................#
#..............................................................................#
#..............................................................................#
#..............................................................................#
#..............................................................................#
#..............................................................................#
#..............................................................................#
#...................................#########..................................#
#.................................#############................................#
#.................................#############................................#
################################################################################
################################################################################
################################################################################
################################################################################
"""
	entities = [
		{t = "door", id = "gate", x = 40, y = 16, to = "s_hall", to_id = "gate", style = "grand", label = "학교 정문"},
		{t = "door", id = "greenhouse", x = 10, y = 19, to = "s_greenhouse", to_id = "up", style = "stair_down", label = "유리 온실"},
		{t = "door", id = "cellar", x = 68, y = 19, to = "s_cellar", to_id = "up", style = "iron", label = "지하 저장고", lock = "key_basement", lock_msg = "지하 철문. 굳게 잠겨 있다. 교장의 허락 없이는 열 수 없다."},
		{t = "save", id = "yard", x = 28, y = 19, style = "candle"},
		{t = "prop", kind = "fountain", x = 54, y = 19},
		{t = "prop", kind = "pine", x = 4, y = 19, h = 9},
		{t = "prop", kind = "pine", x = 20, y = 19, h = 11},
		{t = "prop", kind = "pine", x = 60, y = 19, h = 10},
		{t = "prop", kind = "pine", x = 76, y = 19, h = 9},
		{t = "prop", kind = "torch", x = 16, y = 19},
		{t = "prop", kind = "torch", x = 32, y = 19},
		{t = "prop", kind = "torch", x = 48, y = 19},
		{t = "prop", kind = "torch", x = 64, y = 19},
		{t = "npc", id = "stu", who = "student_b", x = 50, y = 19, face = "left", talk = "npc_courtyard"},
		{t = "sign", x = 72, y = 19, look = "board", text = "지하 저장고|교장의 명으로 출입을 금함.|…밤마다 안에서 무언가 씹는 소리가 난다는 소문은 사실무근. — 관리인"},
		# 덧붙임(overlay): tools/rooms/ch2.py
		{t = "npc", id = "k_emb_go", who = "emberlyn", x = 20, y = 19, face = "right", cond = "k_envoy_seen,!k_departed"},
		{t = "npc", id = "k_pip_go", who = "pippa", x = 17, y = 19, face = "right", cond = "k_envoy_seen,!k_departed"},
		{t = "npc", id = "k_iso_go", who = "isolde", x = 31, y = 19, face = "left", cond = "k_envoy_seen,!k_departed"},
		{t = "trigger", id = "k_depart_tg", x = 26, y = 13, w = 6, h = 6, run = "k_depart", cond = "k_envoy_seen,!k_departed", once = false},
		# 덧붙임(overlay): tools/rooms/ch3.py
		{t = "npc", id = "isolde_ch3", who = "isolde", x = 60, y = 19, face = "left", cond = "e_start,!s_duel_won"},
		# 덧붙임(overlay): tools/rooms/ch5.py
		{t = "prop", kind = "st_flower_arch", x = 76, y = 19, cond = "st_fest"},
		{t = "door", id = "festival", x = 76, y = 19, to = "st_festival", to_id = "yard", style = "grand", label = "축제 광장", cond = "st_fest"},
		{t = "door", id = "star", x = 62, y = 19, to = "st_crossroads", to_id = "yard", style = "st", label = "별의 문 — 별의 탑", cond = "st_lyra_came,!st_invaded"},
		{t = "prop", kind = "st_star_door", x = 62, y = 19, col = "tower", open_if = "st_lyra_came", cond = "st_lyra_came,!st_invaded"},
		{t = "door", id = "rebuild", x = 4, y = 19, to = "st_rebuild", to_id = "yard", style = "wood", label = "공사 중인 안뜰", cond = "st_epilogue"},
		{t = "prop", kind = "st_lantern_string", x = 2, y = 3, w = 14, sag = 2, cond = "st_fest,!st_invaded"},
		{t = "prop", kind = "st_lantern_string", x = 18, y = 2, w = 14, sag = 3, cond = "st_fest,!st_invaded"},
		{t = "prop", kind = "st_lantern_string", x = 48, y = 2, w = 14, sag = 3, cond = "st_fest,!st_invaded"},
		{t = "prop", kind = "st_lantern_string", x = 64, y = 3, w = 14, sag = 2, cond = "st_fest,!st_invaded"},
		{t = "prop", kind = "st_garland", x = 33, y = 11, w = 15, cond = "st_fest,!st_invaded"},
		{t = "prop", kind = "st_festival_banner", x = 14, y = 19, h = 6, cond = "st_fest,!st_invaded"},
		{t = "prop", kind = "st_festival_banner", x = 66, y = 19, h = 6, cond = "st_fest,!st_invaded"},
		{t = "prop", kind = "st_balloon_cluster", x = 57, y = 19, cond = "st_fest,!st_invaded"},
		{t = "npc", id = "stu5", who = "student_a", x = 22, y = 19, face = "right", talk = "npc_st_yard_a", cond = "st_fest,!st_lyra_came"},
		{t = "npc", id = "hodu5", who = "hodu", x = 46, y = 19, face = "left", cond = "st_fest,!st_lyra_came"},
		{t = "trigger", id = "st_yard", x = 36, y = 12, w = 10, h = 8, run = "st_yard_first", cond = "st_fest,!st_lyra_came"},
		{t = "prop", kind = "st_scaffold", x = 36, y = 16, w = 10, h = 8, cond = "st_epilogue"},
		# 덧붙임(overlay): tools/rooms/sys.py
		{t = "warp", id = "warp_circle", x = 24, y = 19, area = "school", cond = "ch1_done"},
		{t = "spawn", id = "warp", x = 24, y = 19, face = "right"},
	]
