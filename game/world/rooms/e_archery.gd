extends RoomData
## 자동 생성: tools/roomgen.py — 직접 고치지 말고 생성기를 고친 뒤 다시 만들 것


func _init() -> void:
	id = "e_archery"
	title = "세계수 · 활터"
	area = "elf"
	theme = "elf"
	music = "elf"
	cell = Vector2i(21, 3)
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
#...........................=======....#
#......................................#
#......................................#
#......................................#
#......................................#
................=======................#
.......................................#
.......................................#
.......................................#
.......................................#
########################################
########################################
########################################
########################################
"""
	entities = [
		{t = "exit", id = "west", x = 0, y = 14, w = 1, h = 5, to = "e_branch_homes", to_id = "east_low"},
		{t = "archery_mark", id = "am1", x = 14, y = 19, group = "archery", active_if = "e_archery_on"},
		{t = "archery_mark", id = "am2", x = 25, y = 8, group = "archery", hang = true, dy = 2, period = 2.6, active_if = "e_archery_on"},
		{t = "archery_mark", id = "am3", x = 31, y = 19, group = "archery", dx = 3, period = 3.0, active_if = "e_archery_on"},
		{t = "archery_mark", id = "am4", x = 36, y = 4, group = "archery", hang = true, dx = 1, dy = 1, period = 2.2, phase = 1.0, active_if = "e_archery_on"},
		{t = "npc", id = "elarien", who = "elarien", x = 6, y = 19, face = "right", cond = "e_hunt_done"},
		{t = "npc", id = "warden_b", who = "warden_b", x = 6, y = 19, face = "right", cond = "!e_hunt_done"},
		{t = "prop", kind = "bow_rack", x = 3, y = 19},
		{t = "prop", kind = "bench_log", x = 9, y = 19, w = 2},
		{t = "prop", kind = "archery_target", x = 38, y = 19},
		{t = "prop", kind = "elf_banner", x = 20, y = 1, h = 4},
		{t = "prop", kind = "wind_vane", x = 33, y = 9},
		{t = "prop", kind = "elf_lantern", x = 10, y = 1, len = 2},
		{t = "prop", kind = "elf_lantern", x = 30, y = 1, len = 3},
		{t = "sign", x = 11, y = 19, look = "board", text = "활터|과녁에 박힌 화살은 뽑아서 제자리에.|바람을 읽지 못하는 자, 활을 들지 말 것. — 엘라리엔"},
	]
