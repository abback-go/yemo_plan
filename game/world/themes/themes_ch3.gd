extends RefCounted
## 3장 지역 테마 색 (RoomTheme와 같은 키) — docs/bible/art.md 2절
##   elf       세계수 마을: 이끼 초록 + 따뜻한 나무, 강조 반딧불 연두 #c8ff7a, 입자 반딧불
##   elf_deep  숲 바닥·뿌리 동굴: 짙은 남록, 강조 버섯 청록 #5affd0, 입자 포자
##   blight    흰 역병: 회백·무채색, 강조 흰빛 #f0f0ff, 입자 흰 가루 (바깥 신들의 색 — 다른 색과 섞지 않는다)

const THEMES := {
	"elf": {
		"base": Color("#2b2a1f"), "deep": Color("#0a0a06"), "top": Color("#3c4a28"), "top_hi": Color("#a6d86a"),
		"seam": Color("#1b1a12"), "edge": Color("#12110b"), "pattern": "plank", "cap": "moss", "cap_col": Color("#4e8a36"),
		"plat": Color("#5e4128"), "plat_hi": Color("#c4995a"), "spike": Color("#3a4a26"), "accent": Color("#c8ff7a"),
		"sky_top": Color("#07120e"), "sky_bottom": Color("#1d3a2b"), "far": Color("#16291e"), "mid": Color("#101e16"),
		"near": Color("#070d09"), "fog": Color(0.75, 1.0, 0.6, 0.045), "particles": "fireflies",
	},
	"elf_deep": {
		"base": Color("#18272a"), "deep": Color("#040909"), "top": Color("#21403a"), "top_hi": Color("#4fc8a6"),
		"seam": Color("#0e1a1b"), "edge": Color("#091112"), "pattern": "stone", "cap": "moss", "cap_col": Color("#1f5a4a"),
		"plat": Color("#3e3222"), "plat_hi": Color("#86704a"), "spike": Color("#1e3a34"), "accent": Color("#5affd0"),
		"sky_top": Color("#020505"), "sky_bottom": Color("#0a1a1b"), "far": Color("#0b1819"), "mid": Color("#071113"),
		"near": Color("#030707"), "fog": Color(0.35, 1.0, 0.85, 0.05), "particles": "spores",
	},
	"blight": {
		"base": Color("#45454d"), "deep": Color("#121216"), "top": Color("#a9a9b6"), "top_hi": Color("#f0f0ff"),
		"seam": Color("#33333a"), "edge": Color("#24242a"), "pattern": "tile", "cap": "snow", "cap_col": Color("#e2e2ec"),
		"plat": Color("#7c7c88"), "plat_hi": Color("#e6e6f2"), "spike": Color("#c4c4d4"), "accent": Color("#f0f0ff"),
		"sky_top": Color("#0e0e12"), "sky_bottom": Color("#3c3c46"), "far": Color("#2a2a32"), "mid": Color("#1f1f26"),
		"near": Color("#0c0c10"), "fog": Color(1.0, 1.0, 1.0, 0.06), "particles": "blight",
	},
}
