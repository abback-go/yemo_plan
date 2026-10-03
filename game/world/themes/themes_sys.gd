extends RefCounted
## 공통 시스템(학교 수업 시험 방) 테마 — ChapterRegistry가 합친다. 키는 room_theme.gd와 같다.

const THEMES := {
	# 바람의 탑: 하늘로 뚫린 하얀 석탑. 창마다 낮 하늘, 강조색 = 오필리아의 연보라
	"windtower": {
		"base": Color("#3a3e52"), "deep": Color("#11121c"), "top": Color("#5a6078"), "top_hi": Color("#c8d0f0"),
		"seam": Color("#262838"), "edge": Color("#1a1c28"), "pattern": "stone", "cap": "none", "cap_col": Color("#000000"),
		"plat": Color("#5a4a66"), "plat_hi": Color("#b8a8ff"), "spike": Color("#3a3e52"), "accent": Color("#b8a8ff"),
		"sky_top": Color("#4a6aa8"), "sky_bottom": Color("#c8d8f0"), "far": Color("#8aa0c8"), "mid": Color("#4a5470"),
		"near": Color("#1a1c28"), "fog": Color(0.85, 0.9, 1.0, 0.06), "particles": "leaves",
	},
	# 시계탑 지붕 별 관측대: 깊은 남색 밤하늘, 별빛 입자, 강조색 = 별의 금빛
	"observatory": {
		"base": Color("#262a40"), "deep": Color("#08091a"), "top": Color("#3e4466"), "top_hi": Color("#8ea0e0"),
		"seam": Color("#181a2c"), "edge": Color("#10111e"), "pattern": "tile", "cap": "gold", "cap_col": Color("#a89050"),
		"plat": Color("#3a3a58"), "plat_hi": Color("#9aa0d0"), "spike": Color("#2a2c44"), "accent": Color("#ffe39a"),
		"sky_top": Color("#03040e"), "sky_bottom": Color("#18244a"), "far": Color("#0e1430"), "mid": Color("#0a0e22"),
		"near": Color("#05060f"), "fog": Color(0.6, 0.7, 1.0, 0.05), "particles": "stars",
	},
	# 결투장: 검은 대리석과 금테, 보라 마법진 (베로니카의 그림자 마법)
	"duel": {
		"base": Color("#241e30"), "deep": Color("#09070e"), "top": Color("#3e3450"), "top_hi": Color("#c8a85a"),
		"seam": Color("#17121f"), "edge": Color("#100c16"), "pattern": "tile", "cap": "gold", "cap_col": Color("#b8903a"),
		"plat": Color("#3a2e48"), "plat_hi": Color("#9a7ac8"), "spike": Color("#2e2640"), "accent": Color("#b67aff"),
		"sky_top": Color("#08060e"), "sky_bottom": Color("#1e1430"), "far": Color("#1a1228"), "mid": Color("#120c1e"),
		"near": Color("#07050c"), "fog": Color(0.7, 0.45, 1.0, 0.05), "particles": "motes",
	},
	# 재의 서고·불사조의 둥지: 타고 남은 책장, 잿빛, 꺼지지 않은 불씨
	"ash": {
		"base": Color("#2a2524"), "deep": Color("#0a0808"), "top": Color("#4a403c"), "top_hi": Color("#a08070"),
		"seam": Color("#1a1615"), "edge": Color("#120f0e"), "pattern": "plank", "cap": "snow", "cap_col": Color("#6a625e"),
		"plat": Color("#3e322c"), "plat_hi": Color("#8a6a58"), "spike": Color("#3a302c"), "accent": Color("#ff8a3a"),
		"sky_top": Color("#060404"), "sky_bottom": Color("#1e1210"), "far": Color("#1a1412"), "mid": Color("#120e0c"),
		"near": Color("#070505"), "fog": Color(1.0, 0.5, 0.3, 0.05), "particles": "ash",
	},
}
