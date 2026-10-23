extends RoomData
## 자동 생성: tools/roomgen.py — 직접 고치지 말고 생성기를 고친 뒤 다시 만들 것
## 정의: tools/rooms/ch4.py tp_scriptorium()


func _init() -> void:
	id = "tp_scriptorium"
	title = "대신전 · 필사실"
	area = "temple"
	theme = "temple_dark"
	music = "temple_dark"
	cell = Vector2i(13, 6)
	cells = Vector2i(1, 1)
	dark = 0.1
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
#.............................======...#
#......................................#
#......................................#
#......................................#
#......................................#
..................=======..............#
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
		{t = "tp_ally", id = "ally"},
		{t = "exit", id = "west", x = 0, y = 14, w = 1, h = 5, to = "tp_archive_1", to_id = "east"},
		{t = "npc", id = "scribe", who = "tp_monk", x = 12, y = 19, face = "right", talk = "npc_tp_scribe"},
		{t = "brazier", id = "candle4", x = 30, y = 19, style = "seal", group = "tp_candle_4", done_flag = "tp_candle_4"},
		{t = "puzzle", id = "candle_pz4", group = "tp_candle_4", mode = "all", done_flag = "tp_candle_4"},
		{t = "event", id = "candle_ev4", flag = "tp_candle_4", run = "tp_candle_lit", done = "tp_candle_seen_4"},
		{t = "pickup", id = "scripture_2", kind = "page", x = 21, y = 14, name = "루멘 경전 조각 (2/3)", text = "「빛의 주재는 말하지 않는다. 다만 수호자에게 금빛을 맡기고, 짧은 계시로 길을 일러 줄 뿐.」|「계시가 끊기는 날이 오거든, 수호자여, 너의 창을 믿어라.」"},
		{t = "pickup", id = "stone_script", kind = "stone", x = 33, y = 9},
		{t = "prop", kind = "tp_lectern", x = 8, y = 19},
		{t = "prop", kind = "tp_lectern", x = 16, y = 19},
		{t = "prop", kind = "tp_books", x = 24, y = 19},
		{t = "prop", kind = "tp_scrolls", x = 34, y = 19, w = 4, h = 8},
		{t = "prop", kind = "tp_candles", x = 5, y = 19},
		{t = "prop", kind = "tp_candelabra", x = 27, y = 19},
		{t = "prop", kind = "tp_glass", x = 12, y = 3, w = 3, h = 5},
		{t = "prop", kind = "tp_censer", x = 22, y = 2, len = 3},
	]
