extends RefCounted
## 2장 지역 테마 색 (RoomTheme와 같은 키) — docs/bible/art.md 2절
##   kingdom        황도 아르덴 거리·지붕 (해 질 녘): 차가운 회청 석재 + 붉은 지붕, 등불 호박색
##   kingdom_night  같은 거리의 밤 (황궁 광장 결투·밤 지붕): 더 깊은 남색, 달, 불 켜진 창
##   kingdom_in     성·대성당·투기장 실내: 회백 대리석 + 진홍 깃발, 금빛
##   sewer          하수도·지하 묘지: 짙은 청록, 별빛 청록 물
##   starfall       옛 성곽 지구(운석): 잿빛 + 보라 별빛

const THEMES := {
	"kingdom": {
		"base": Color("#2c3142"), "deep": Color("#0a0b11"), "top": Color("#4c5368"), "top_hi": Color("#9aa2b8"),
		"seam": Color("#1b1e2a"), "edge": Color("#13151d"), "pattern": "stone", "cap": "none", "cap_col": Color("#000000"),
		"plat": Color("#5e3a2a"), "plat_hi": Color("#b07a4c"), "spike": Color("#3a3d4e"), "accent": Color("#ffb45a"),
		"sky_top": Color("#0c0f22"), "sky_bottom": Color("#4a2c3e"), "far": Color("#232840"), "mid": Color("#181c2c"),
		"near": Color("#0b0d16"), "fog": Color(1.0, 0.72, 0.5, 0.045), "particles": "embers",
	},
	"kingdom_night": {
		"base": Color("#252a3c"), "deep": Color("#07080e"), "top": Color("#414860"), "top_hi": Color("#8a96c0"),
		"seam": Color("#171a26"), "edge": Color("#10121a"), "pattern": "stone", "cap": "none", "cap_col": Color("#000000"),
		"plat": Color("#4e3426"), "plat_hi": Color("#9a6c46"), "spike": Color("#33364a"), "accent": Color("#ffb45a"),
		"sky_top": Color("#04050d"), "sky_bottom": Color("#18203e"), "far": Color("#161b32"), "mid": Color("#0f1324"),
		"near": Color("#06070e"), "fog": Color(0.55, 0.65, 1.0, 0.05), "particles": "motes",
	},
	"kingdom_in": {
		"base": Color("#3c3a44"), "deep": Color("#0f0e13"), "top": Color("#6e6a74"), "top_hi": Color("#d8d0c4"),
		"seam": Color("#2a2832"), "edge": Color("#18171d"), "pattern": "tile", "cap": "carpet", "cap_col": Color("#7a1a26"),
		"plat": Color("#5a4030"), "plat_hi": Color("#c09858"), "spike": Color("#4a4652"), "accent": Color("#ffd27a"),
		"sky_top": Color("#0d0b10"), "sky_bottom": Color("#2c2530"), "far": Color("#26222c"), "mid": Color("#1b1820"),
		"near": Color("#0c0b0f"), "fog": Color(1.0, 0.85, 0.55, 0.045), "particles": "motes",
	},
	"sewer": {
		"base": Color("#173230"), "deep": Color("#030909"), "top": Color("#264a4a"), "top_hi": Color("#56a49a"),
		"seam": Color("#0c1f1f"), "edge": Color("#081414"), "pattern": "brick", "cap": "moss", "cap_col": Color("#1f4c3c"),
		"plat": Color("#34403c"), "plat_hi": Color("#7a9a88"), "spike": Color("#1e3a3a"), "accent": Color("#6af0e0"),
		"sky_top": Color("#020707"), "sky_bottom": Color("#0a2020"), "far": Color("#0c1e1e"), "mid": Color("#081616"),
		"near": Color("#030a0a"), "fog": Color(0.4, 1.0, 0.9, 0.05), "particles": "spores",
	},
	"starfall": {
		"base": Color("#2a2832"), "deep": Color("#09080d"), "top": Color("#46404f"), "top_hi": Color("#9a88c4"),
		"seam": Color("#1a1820"), "edge": Color("#121016"), "pattern": "stone", "cap": "moss", "cap_col": Color("#4e3c78"),
		"plat": Color("#3e3646"), "plat_hi": Color("#9078c0"), "spike": Color("#3a3048"), "accent": Color("#c89aff"),
		"sky_top": Color("#06040e"), "sky_bottom": Color("#2a1c46"), "far": Color("#1e1834"), "mid": Color("#151026"),
		"near": Color("#08060e"), "fog": Color(0.75, 0.55, 1.0, 0.065), "particles": "stars",
	},
}
