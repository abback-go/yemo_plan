extends RefCounted
## 4장 지역 테마 색 (RoomTheme와 같은 키) — docs/bible/art.md 2절, docs/chapter4.md 7.1절
##
## 테마 ID
##   holymount   성산 순례길 (눈 덮인 산길, 기도 깃발, 순례자의 돌무지) — 입자: 눈(blight를 눈처럼 씀)
##   temple_out  대신전 바깥 (구름 위 정문·회랑 정원, 황금 돔, 거대한 루멘 석상) — 입자: 빛 알갱이
##   temple      대신전 안 (흰 대리석 + 금, 거대한 아치 창 너머 구름바다, 매달린 종) — 입자: 빛 알갱이
##   temple_dark 지하·기록실 (짙은 청회, 촛불, 서가) — 입자: 먼지
##   spire       첨탑 추격 (밤하늘, 금빛 비계, 아래로 끝없는 심연) — 입자: 빛
##   spire_top   첨탑 꼭대기 (종루 위 열린 하늘, 달) — 입자: 별
## INARI풍 규칙: 지형은 어둡고 낮은 채도(흰 대리석도 그늘진 회보라로), 빛나는 금색 하나를 강조색으로.

const THEMES := {
	"holymount": {
		"base": Color("#363a4e"), "deep": Color("#0b0d17"), "top": Color("#58607a"), "top_hi": Color("#eef2fa"),
		"seam": Color("#242838"), "edge": Color("#151722"), "pattern": "stone", "cap": "snow", "cap_col": Color("#dfe6f2"),
		"plat": Color("#5a4632"), "plat_hi": Color("#c8a46a"), "spike": Color("#4a5068"), "accent": Color("#ffd88a"),
		"sky_top": Color("#0c1230"), "sky_bottom": Color("#5e5a8a"), "far": Color("#2a2e50"), "mid": Color("#1b1f38"),
		"near": Color("#0d0f1c"), "fog": Color(0.85, 0.9, 1.0, 0.07), "particles": "blight",
	},
	"temple_out": {
		"base": Color("#46425a"), "deep": Color("#100e18"), "top": Color("#968fb0"), "top_hi": Color("#fff2d0"),
		"seam": Color("#2c283c"), "edge": Color("#1a1824"), "pattern": "stone", "cap": "gold", "cap_col": Color("#e8b84a"),
		"plat": Color("#8c7c5c"), "plat_hi": Color("#fff0c0"), "spike": Color("#5a5468"), "accent": Color("#ffe08a"),
		"sky_top": Color("#161a42"), "sky_bottom": Color("#e0a068"), "far": Color("#3a3052"), "mid": Color("#28223e"),
		"near": Color("#13101c"), "fog": Color(1.0, 0.88, 0.65, 0.06), "particles": "light",
	},
	"temple": {
		"base": Color("#3c3a50"), "deep": Color("#0d0c15"), "top": Color("#8a86a4"), "top_hi": Color("#fff0c8"),
		"seam": Color("#282636"), "edge": Color("#181722"), "pattern": "stone", "cap": "gold", "cap_col": Color("#d8a840"),
		"plat": Color("#9a8a68"), "plat_hi": Color("#f4dca0"), "spike": Color("#4a4658"), "accent": Color("#ffe08a"),
		"sky_top": Color("#10142e"), "sky_bottom": Color("#6a5a7a"), "far": Color("#2c2842"), "mid": Color("#211d33"),
		"near": Color("#100e19"), "fog": Color(1.0, 0.92, 0.7, 0.05), "particles": "light",
	},
	"temple_dark": {
		"base": Color("#23263a"), "deep": Color("#07080e"), "top": Color("#3e4258"), "top_hi": Color("#b8a888"),
		"seam": Color("#161828"), "edge": Color("#0e0f18"), "pattern": "stone", "cap": "none", "cap_col": Color("#000000"),
		"plat": Color("#4a3a2a"), "plat_hi": Color("#a07c4a"), "spike": Color("#2e3044"), "accent": Color("#ffc870"),
		"sky_top": Color("#05060c"), "sky_bottom": Color("#141828"), "far": Color("#121522"), "mid": Color("#0d0f1a"),
		"near": Color("#06070c"), "fog": Color(1.0, 0.8, 0.5, 0.04), "particles": "dust",
	},
	"spire": {
		"base": Color("#2c2a40"), "deep": Color("#08070e"), "top": Color("#5e5878"), "top_hi": Color("#ffe6a0"),
		"seam": Color("#1c1a2c"), "edge": Color("#121020"), "pattern": "stone", "cap": "gold", "cap_col": Color("#e0b048"),
		"plat": Color("#6a5236"), "plat_hi": Color("#e8c070"), "spike": Color("#3a3650"), "accent": Color("#ffe08a"),
		"sky_top": Color("#04051a"), "sky_bottom": Color("#1c1a44"), "far": Color("#16163a"), "mid": Color("#0e0d24"),
		"near": Color("#070612"), "fog": Color(1.0, 0.9, 0.6, 0.05), "particles": "light",
	},
	"spire_top": {
		"base": Color("#34324a"), "deep": Color("#0a0912"), "top": Color("#6e6a8c"), "top_hi": Color("#fff4d0"),
		"seam": Color("#222034"), "edge": Color("#15131f"), "pattern": "stone", "cap": "gold", "cap_col": Color("#e8c060"),
		"plat": Color("#8a7a5a"), "plat_hi": Color("#fff0b0"), "spike": Color("#3a3650"), "accent": Color("#fff0b0"),
		"sky_top": Color("#03041a"), "sky_bottom": Color("#2a2862"), "far": Color("#1a1a3c"), "mid": Color("#121232"),
		"near": Color("#08081a"), "fog": Color(0.9, 0.9, 1.0, 0.05), "particles": "stars",
	},
}
