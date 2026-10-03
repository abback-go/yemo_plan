extends RefCounted
## 5장 지역 테마 색 (RoomTheme와 같은 키) — docs/bible/art.md 2절
##   star         별의 탑: 깊은 남색 + 별빛 #fff3c0 (금테 윗면, 빛나는 별 발판)
##   void         절망 뒤 어둠: 검정 + 푸른 여우불
##   sky          하늘의 문: 흰 빛이 새는 균열(눈)로 갈라진 검은 하늘, 구름 바다 위 떠다니는 부서진 땅
##   festival     축제 저녁의 학교 앞마당: 보랏빛 노을, 등불, 불꽃놀이
##   ruin_school  무너진 학교 (원래 학교 팔레트 + 잿빛·불길 #ff6a3a + 하늘의 흰빛)
##   ruin_kingdom 무너진 황도 아르덴 (회청 석재 + 붉은 지붕 → 그을림)
##   ruin_elf     불타는 세계수 마을 (이끼·나무 → 숯·마른 잎)
##   ruin_temple  금 간 대신전 (흰 대리석·금 → 그을린 대리석)
##   rise         반격의 새벽: 무너진 학교 위로 번지는 푸른 여우불 (거신들이 잠든다)
## 입자: stars · foxfire · blight(흰 가루) · ash · light (room_backdrop.gd _particles)

const THEMES := {
	"star": {
		"base": Color("#1d2452"), "deep": Color("#060818"), "top": Color("#2c3878"), "top_hi": Color("#c8d0ff"),
		"seam": Color("#131a40"), "edge": Color("#0b0f2c"), "pattern": "tile", "cap": "gold", "cap_col": Color("#d8bc6a"),
		"plat": Color("#283272"), "plat_hi": Color("#fff3c0"), "spike": Color("#2a2e66"), "accent": Color("#fff3c0"),
		"sky_top": Color("#02041a"), "sky_bottom": Color("#18205a"), "far": Color("#101642"), "mid": Color("#0b1034"),
		"near": Color("#05081e"), "fog": Color(0.62, 0.7, 1.0, 0.05), "particles": "stars",
	},
	"void": {
		"base": Color("#0c0f1c"), "deep": Color("#020205"), "top": Color("#16203c"), "top_hi": Color("#6ab8ff"),
		"seam": Color("#070912"), "edge": Color("#04050b"), "pattern": "stone", "cap": "none", "cap_col": Color("#000000"),
		"plat": Color("#14223e"), "plat_hi": Color("#8ad0ff"), "spike": Color("#101830"), "accent": Color("#6ab8ff"),
		"sky_top": Color("#000003"), "sky_bottom": Color("#040a1c"), "far": Color("#040814"), "mid": Color("#03060e"),
		"near": Color("#010206"), "fog": Color(0.35, 0.6, 1.0, 0.045), "particles": "foxfire",
	},
	"sky": {
		"base": Color("#4a4858"), "deep": Color("#141320"), "top": Color("#8c8aa0"), "top_hi": Color("#f4f4ff"),
		"seam": Color("#34323f"), "edge": Color("#1c1b26"), "pattern": "stone", "cap": "snow", "cap_col": Color("#e8e8f4"),
		"plat": Color("#5e5c74"), "plat_hi": Color("#eceaff"), "spike": Color("#3c3a4c"), "accent": Color("#f0f4ff"),
		"sky_top": Color("#040309"), "sky_bottom": Color("#2c2a3e"), "far": Color("#cfcddc"), "mid": Color("#383648"),
		"near": Color("#1c1a28"), "fog": Color(1.0, 1.0, 1.0, 0.04), "particles": "blight",
	},
	"festival": {
		"base": Color("#2c2a3a"), "deep": Color("#0c0b12"), "top": Color("#3e4a3a"), "top_hi": Color("#9aba72"),
		"seam": Color("#1c1a26"), "edge": Color("#14121a"), "pattern": "stone", "cap": "moss", "cap_col": Color("#3a5a34"),
		"plat": Color("#6a4030"), "plat_hi": Color("#e8a860"), "spike": Color("#3c3650"), "accent": Color("#ffc870"),
		"sky_top": Color("#151230"), "sky_bottom": Color("#8a4a5a"), "far": Color("#3a2a4c"), "mid": Color("#24193c"),
		"near": Color("#0d0a16"), "fog": Color(1.0, 0.75, 0.55, 0.05), "particles": "light",
	},
	"ruin_school": {
		"base": Color("#2c2636"), "deep": Color("#0b090e"), "top": Color("#4a4048"), "top_hi": Color("#c8a090"),
		"seam": Color("#1a1620"), "edge": Color("#110e14"), "pattern": "brick", "cap": "snow", "cap_col": Color("#b8b0b0"),
		"plat": Color("#4a3428"), "plat_hi": Color("#c87a4a"), "spike": Color("#3a2a2a"), "accent": Color("#ff6a3a"),
		"sky_top": Color("#0e0a12"), "sky_bottom": Color("#7a2a1e"), "far": Color("#2e1a22"), "mid": Color("#1c1018"),
		"near": Color("#0a0608"), "fog": Color(1.0, 0.45, 0.3, 0.07), "particles": "ash",
	},
	"ruin_kingdom": {
		"base": Color("#343844"), "deep": Color("#0c0d12"), "top": Color("#5a4a46"), "top_hi": Color("#d89a6a"),
		"seam": Color("#20232c"), "edge": Color("#15171e"), "pattern": "stone", "cap": "snow", "cap_col": Color("#b0aaa8"),
		"plat": Color("#5a2e26"), "plat_hi": Color("#e0784a"), "spike": Color("#3a3036"), "accent": Color("#ff6a3a"),
		"sky_top": Color("#0e0a10"), "sky_bottom": Color("#82341e"), "far": Color("#301c20"), "mid": Color("#1e1216"),
		"near": Color("#0b0708"), "fog": Color(1.0, 0.5, 0.3, 0.07), "particles": "ash",
	},
	"ruin_elf": {
		"base": Color("#2a2a24"), "deep": Color("#0a0a08"), "top": Color("#3e3a2a"), "top_hi": Color("#c89a5a"),
		"seam": Color("#1a1a14"), "edge": Color("#12120e"), "pattern": "plank", "cap": "snow", "cap_col": Color("#a8a8a0"),
		"plat": Color("#3e2a1c"), "plat_hi": Color("#d88a4a"), "spike": Color("#2e2a20"), "accent": Color("#ff6a3a"),
		"sky_top": Color("#0c0a0a"), "sky_bottom": Color("#6e3218"), "far": Color("#2a1c16"), "mid": Color("#1a120e"),
		"near": Color("#090706"), "fog": Color(1.0, 0.55, 0.3, 0.07), "particles": "ash",
	},
	"ruin_temple": {
		"base": Color("#4a4652"), "deep": Color("#121016"), "top": Color("#7a7068"), "top_hi": Color("#e8d0a0"),
		"seam": Color("#302c36"), "edge": Color("#1e1b22"), "pattern": "stone", "cap": "snow", "cap_col": Color("#c8c4c0"),
		"plat": Color("#6a5a3a"), "plat_hi": Color("#e8c070"), "spike": Color("#44404a"), "accent": Color("#ff6a3a"),
		"sky_top": Color("#100c12"), "sky_bottom": Color("#7a3a26"), "far": Color("#34222a"), "mid": Color("#22161c"),
		"near": Color("#0c0809"), "fog": Color(1.0, 0.6, 0.4, 0.07), "particles": "ash",
	},
	"rise": {
		"base": Color("#262838"), "deep": Color("#08090f"), "top": Color("#3a4058"), "top_hi": Color("#8ad0ff"),
		"seam": Color("#181a26"), "edge": Color("#101118"), "pattern": "brick", "cap": "snow", "cap_col": Color("#b8c0d0"),
		"plat": Color("#2a3a5a"), "plat_hi": Color("#8ad0ff"), "spike": Color("#2a2e44"), "accent": Color("#6ab8ff"),
		"sky_top": Color("#050a1c"), "sky_bottom": Color("#2a4a8a"), "far": Color("#16203c"), "mid": Color("#0e1428"),
		"near": Color("#060810"), "fog": Color(0.45, 0.7, 1.0, 0.06), "particles": "foxfire",
	},
}
