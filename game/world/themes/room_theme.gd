class_name RoomTheme
extends RefCounted
## 지역별 색과 타일 무늬 (docs/archive/sera/chapter1.md 8절). INARI 스크린샷 분석:
## 어두운 저채도 + 지역마다 강한 강조색 하나, 굵은 덩어리 픽셀, 깊은 안쪽은 거의 검게.
##
## 키
##   base/deep      벽 표면색 / 안쪽 깊은 곳(거의 검정)
##   top/top_hi     윗면 / 윗면 강조선
##   seam           돌·벽돌 이음새
##   edge           옆면 테두리
##   pattern        brick(학교 벽돌) · stone(큰 돌) · plank(나무) · tile(기와·타일)
##   cap            윗면 장식: none · moss(이끼) · carpet(카펫) · snow(먼지) · gold(금테)
##   plat / plat_hi 통과 발판
##   spike          가시 색 (끝 강조 accent)
##   accent         지역 강조색 (불빛)
##   sky_top/sky_bottom  배경 하늘 그라데이션
##   far/mid/near   배경 실루엣 층 색
##   fog            안개 색
##   particles      먼지·불씨 종류: embers · dust · foxfire · motes · drips · petals · rain

const THEMES := {
	"shingye": {
		"base": Color("#252338"), "deep": Color("#0b0a14"), "top": Color("#3f3a5c"), "top_hi": Color("#7e74a8"),
		"seam": Color("#17152a"), "edge": Color("#121020"), "pattern": "stone", "cap": "moss", "cap_col": Color("#2d4a48"),
		"plat": Color("#8c2a2a"), "plat_hi": Color("#d8544a"), "spike": Color("#3a3550"), "accent": Color("#ff8a4a"),
		"sky_top": Color("#070915"), "sky_bottom": Color("#1c2440"), "far": Color("#141a2e"), "mid": Color("#10142a"),
		"near": Color("#090a14"), "fog": Color(0.45, 0.6, 0.9, 0.08), "particles": "foxfire",
	},
	"shrine": {
		"base": Color("#2a1f2a"), "deep": Color("#0c080d"), "top": Color("#4a2e36"), "top_hi": Color("#c0644e"),
		"seam": Color("#1a1218"), "edge": Color("#140d12"), "pattern": "tile", "cap": "gold", "cap_col": Color("#b88a3a"),
		"plat": Color("#8c2a2a"), "plat_hi": Color("#e0a050"), "spike": Color("#3a2530"), "accent": Color("#ff9a4a"),
		"sky_top": Color("#0a060c"), "sky_bottom": Color("#2a1418"), "far": Color("#1e1016"), "mid": Color("#170c12"),
		"near": Color("#0a0608"), "fog": Color(0.9, 0.4, 0.3, 0.06), "particles": "embers",
	},
	"hall": {
		"base": Color("#2a2640"), "deep": Color("#0c0b16"), "top": Color("#4a4266"), "top_hi": Color("#9a8cc8"),
		"seam": Color("#1b1830"), "edge": Color("#14121f"), "pattern": "brick", "cap": "carpet", "cap_col": Color("#7a2338"),
		"plat": Color("#5a3e2e"), "plat_hi": Color("#a6764e"), "spike": Color("#3c3650"), "accent": Color("#ffcf7a"),
		"sky_top": Color("#0d0b1a"), "sky_bottom": Color("#221c38"), "far": Color("#1a1630"), "mid": Color("#141126"),
		"near": Color("#09080f"), "fog": Color(1.0, 0.85, 0.6, 0.04), "particles": "motes",
	},
	"room": {
		"base": Color("#2e2638"), "deep": Color("#0e0b12"), "top": Color("#5a4636"), "top_hi": Color("#b08a5e"),
		"seam": Color("#1e1826"), "edge": Color("#16121c"), "pattern": "brick", "cap": "none", "cap_col": Color("#000000"),
		"plat": Color("#5a3e2e"), "plat_hi": Color("#a6764e"), "spike": Color("#3c3650"), "accent": Color("#ffc46a"),
		"sky_top": Color("#140f16"), "sky_bottom": Color("#2a2030"), "far": Color("#201a28"), "mid": Color("#18131e"),
		"near": Color("#0b090e"), "fog": Color(1.0, 0.8, 0.55, 0.04), "particles": "motes",
	},
	"library": {
		"base": Color("#1f2a2c"), "deep": Color("#080d0e"), "top": Color("#3c4a46"), "top_hi": Color("#7fa08e"),
		"seam": Color("#131b1c"), "edge": Color("#0e1414"), "pattern": "plank", "cap": "none", "cap_col": Color("#000000"),
		"plat": Color("#4e3a28"), "plat_hi": Color("#9c7448"), "spike": Color("#2e3836"), "accent": Color("#ffb85a"),
		"sky_top": Color("#060b0c"), "sky_bottom": Color("#142024"), "far": Color("#101a1c"), "mid": Color("#0c1416"),
		"near": Color("#05090a"), "fog": Color(0.6, 0.9, 0.7, 0.04), "particles": "dust",
	},
	"clock": {
		"base": Color("#3a2220"), "deep": Color("#0f0707"), "top": Color("#5e3428"), "top_hi": Color("#c8704a"),
		"seam": Color("#241413"), "edge": Color("#180c0b"), "pattern": "stone", "cap": "gold", "cap_col": Color("#a8783a"),
		"plat": Color("#4a3a32"), "plat_hi": Color("#b89a5a"), "spike": Color("#4a2a24"), "accent": Color("#ff7a3a"),
		"sky_top": Color("#1a0606"), "sky_bottom": Color("#5a1614"), "far": Color("#3a1010"), "mid": Color("#240a0a"),
		"near": Color("#0c0404"), "fog": Color(1.0, 0.35, 0.25, 0.07), "particles": "embers",
	},
	"basement": {
		"base": Color("#1c1c28"), "deep": Color("#06060a"), "top": Color("#323244"), "top_hi": Color("#6a6a8a"),
		"seam": Color("#121219"), "edge": Color("#0b0b11"), "pattern": "stone", "cap": "moss", "cap_col": Color("#24302a"),
		"plat": Color("#3a3434"), "plat_hi": Color("#6a5e58"), "spike": Color("#2a2434"), "accent": Color("#b06aff"),
		"sky_top": Color("#040408"), "sky_bottom": Color("#12101e"), "far": Color("#0e0c18"), "mid": Color("#0a0912"),
		"near": Color("#030306"), "fog": Color(0.6, 0.4, 1.0, 0.06), "particles": "drips",
	},
	"exterior": {
		"base": Color("#2c2a3a"), "deep": Color("#0c0b12"), "top": Color("#3e4a3a"), "top_hi": Color("#7e9a62"),
		"seam": Color("#1c1a26"), "edge": Color("#14121a"), "pattern": "stone", "cap": "moss", "cap_col": Color("#3a5a34"),
		"plat": Color("#5a3e2e"), "plat_hi": Color("#a6764e"), "spike": Color("#3c3650"), "accent": Color("#ffcf7a"),
		"sky_top": Color("#1a1430"), "sky_bottom": Color("#7a4a5a"), "far": Color("#3a2a48"), "mid": Color("#22183a"),
		"near": Color("#0c0914"), "fog": Color(1.0, 0.7, 0.6, 0.05), "particles": "petals",
	},
	"greenhouse": {
		"base": Color("#22302a"), "deep": Color("#08100c"), "top": Color("#3a5a40"), "top_hi": Color("#86c07a"),
		"seam": Color("#16201a"), "edge": Color("#0e1610"), "pattern": "tile", "cap": "moss", "cap_col": Color("#4a7a3a"),
		"plat": Color("#4e3a28"), "plat_hi": Color("#9c7448"), "spike": Color("#3a4a2a"), "accent": Color("#b8ff8a"),
		"sky_top": Color("#0a1410"), "sky_bottom": Color("#1e3a2c"), "far": Color("#14261c"), "mid": Color("#0e1c14"),
		"near": Color("#050c08"), "fog": Color(0.6, 1.0, 0.7, 0.05), "particles": "motes",
	},
}


static func get_theme(name: String) -> Dictionary:
	if THEMES.has(name):
		return THEMES[name]
	return ChapterRegistry.themes().get(name, THEMES["hall"])
