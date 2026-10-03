class_name Characters
extends RefCounted
## 등장인물 정보 (docs/chapter1.md 6절): 이름, 이름 색, 목소리(대화 삑삑음 높이), 작은 몸 그림 값, 초상화 값.
##
## 몸 그림 값 (CharacterVisual): robe 옷색, robe2 옷 강조색, skin, hair, hair_style(long·bun·twin·short·tied·bob·none),
## hat(witch·witch_small·nurse·none·hood·veil), hat_col, eye, height(몸 높이 px), extra(glasses·goggles·ribbon·owl·apron·feather·gloves·stars·ladle)

const DB := {
	"sera": {
		"name": "세라", "color": Color("#ff8a6a"), "voice": 1.15,
		"robe": Color("#2b2140"), "robe2": Color("#8e2b3a"), "skin": Color("#f2d3c0"), "hair": Color("#1d1a2e"),
		"hair_style": "long", "hat": "witch", "hat_col": Color("#231a33"), "eye": Color("#c84a3a"), "height": 32, "extra": [],
	},
	"neoul": {
		"name": "너울", "color": Color("#8ad0ff"), "voice": 0.85,
	},
	"neoul_god": {
		"name": "너울", "color": Color("#8ad0ff"), "voice": 0.7,
	},
	"emberlyn": {
		"name": "엠버린 교수", "color": Color("#ff9a5a"), "voice": 0.95,
		"robe": Color("#3a1e1c"), "robe2": Color("#c8643a"), "skin": Color("#f0cdb8"), "hair": Color("#c8402a"),
		"hair_style": "bun", "hat": "witch", "hat_col": Color("#2a1614"), "eye": Color("#6a3a2a"), "height": 36, "extra": ["glasses"],
	},
	"pippa": {
		"name": "피피", "color": Color("#8ae07a"), "voice": 1.35,
		"robe": Color("#2a3a2c"), "robe2": Color("#d8b040"), "skin": Color("#f4d8c4"), "hair": Color("#4aa858"),
		"hair_style": "twin", "hat": "witch_small", "hat_col": Color("#24301e"), "eye": Color("#3a6a3a"), "height": 28, "extra": ["goggles"],
	},
	"mirabel": {
		"name": "미라벨", "color": Color("#ffa8c8"), "voice": 1.25,
		"robe": Color("#e8e0ea"), "robe2": Color("#c85a7a"), "skin": Color("#f6dccc"), "hair": Color("#8a5a3a"),
		"hair_style": "short", "hat": "nurse", "hat_col": Color("#f4f0f4"), "eye": Color("#6a4a3a"), "height": 33, "extra": ["apron"],
	},
	"isolde": {
		"name": "이졸데", "color": Color("#a8c8ff"), "voice": 1.05,
		"robe": Color("#1e2440"), "robe2": Color("#4a6ad8"), "skin": Color("#f4e0d6"), "hair": Color("#d8d8e8"),
		"hair_style": "tied", "hat": "witch_small", "hat_col": Color("#161a30"), "eye": Color("#4a6ad8"), "height": 33, "extra": ["ribbon"],
	},
	"ophelia": {
		"name": "오필리아 교수", "color": Color("#c8a8ff"), "voice": 0.9,
		"robe": Color("#3a3050"), "robe2": Color("#a890d8"), "skin": Color("#f2dcd0"), "hair": Color("#e8d0f0"),
		"hair_style": "long", "hat": "witch", "hat_col": Color("#2c2440"), "eye": Color("#8a6ab8"), "height": 36, "extra": ["feather"],
	},
	"greta": {
		"name": "그레타", "color": Color("#9ac8a0"), "voice": 0.8,
		"robe": Color("#1e3028"), "robe2": Color("#4a7a5a"), "skin": Color("#ead0c0"), "hair": Color("#3a3028"),
		"hair_style": "bun", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#3a4a3a"), "height": 34, "extra": ["glasses", "owl"],
	},
	"hodu": {
		"name": "호두", "color": Color("#c8a070"), "voice": 0.6,
	},
	"veronica": {
		"name": "베로니카 교수", "color": Color("#d0d0e0"), "voice": 0.85,
		"robe": Color("#141418"), "robe2": Color("#6a2a4a"), "skin": Color("#eed6ca"), "hair": Color("#1a1a20"),
		"hair_style": "bob", "hat": "witch", "hat_col": Color("#0c0c10"), "eye": Color("#8a3a5a"), "height": 37, "extra": ["gloves"],
	},
	"astrid": {
		"name": "아스트리드 교장", "color": Color("#e8e0ff"), "voice": 0.75,
		"robe": Color("#20203a"), "robe2": Color("#c8c0ff"), "skin": Color("#f0dcd4"), "hair": Color("#b8b8c8"),
		"hair_style": "long", "hat": "witch", "hat_col": Color("#181830"), "eye": Color("#a0a0e8"), "height": 38, "extra": ["stars"],
	},
	"butterworth": {
		"name": "버터워스 아주머니", "color": Color("#f0c070"), "voice": 0.8,
		"robe": Color("#5a4038"), "robe2": Color("#f0e8d8"), "skin": Color("#f0c8b0"), "hair": Color("#c89858"),
		"hair_style": "bun", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#5a3a2a"), "height": 33, "extra": ["apron", "ladle"],
	},
	"student_a": {
		"name": "학생", "color": Color("#c8c0d8"), "voice": 1.2,
		"robe": Color("#2a2a44"), "robe2": Color("#8a6ac8"), "skin": Color("#f2d6c6"), "hair": Color("#6a4a2a"),
		"hair_style": "short", "hat": "witch_small", "hat_col": Color("#222238"), "eye": Color("#4a3a2a"), "height": 30, "extra": [],
	},
	"student_b": {
		"name": "학생", "color": Color("#c8c0d8"), "voice": 1.3,
		"robe": Color("#2a3444"), "robe2": Color("#5aa8c8"), "skin": Color("#e8c8b0"), "hair": Color("#e8c060"),
		"hair_style": "twin", "hat": "witch_small", "hat_col": Color("#1e2838"), "eye": Color("#3a5a7a"), "height": 29, "extra": [],
	},
	"student_c": {
		"name": "학생", "color": Color("#c8c0d8"), "voice": 1.1,
		"robe": Color("#3a2a34"), "robe2": Color("#c86a8a"), "skin": Color("#f4dccc"), "hair": Color("#2a2a34"),
		"hair_style": "bob", "hat": "witch_small", "hat_col": Color("#2a1e28"), "eye": Color("#4a2a3a"), "height": 31, "extra": ["glasses"],
	},
	"narration": {
		"name": "", "color": Color("#c8c0d8"), "voice": 0.0,
	},
}


static func info(who: String) -> Dictionary:
	return DB.get(who, DB["student_a"])


static func display_name(who: String) -> String:
	return String(info(who).get("name", who))
