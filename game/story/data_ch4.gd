extends RefCounted
## 4장 데이터 — ChapterRegistry가 합친다 (docs/systems2.md 1절, docs/chapter4.md 7절).

const SPECIAL := "res://characters/special/"

## 인물: 1장 Characters.DB와 같은 키 (+ 전용 그림 "draw"·"portrait")
## 아우렐리아는 전용 그림(aurelia_draw/portrait). 폭주 판은 "aurelia_berserk"(같은 그림, "berserk": true — 하얀 눈·금 간 광륜·흰금 불꽃).
## 신전 사람들(베네딕타·루카·그레고르·수도사·사제·순례자·성가대)은 temple_folk_draw/portrait가 "look" 값으로 그린다.
const CHARACTERS := {
	"aurelia": {
		"name": "아우렐리아", "color": Color("#ffe08a"), "voice": 0.92, "height": 42,
		"draw": SPECIAL + "aurelia_draw.gd", "portrait": SPECIAL + "aurelia_portrait.gd",
		"robe": Color("#ece8f4"), "robe2": Color("#e9b949"), "skin": Color("#f7dcc9"), "hair": Color("#f2c55a"),
		"hair_style": "long", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#d48a1a"), "extra": [],
	},
	"aurelia_berserk": {
		"name": "아우렐리아", "color": Color("#fff6dc"), "voice": 0.62, "height": 42, "berserk": true,
		"draw": SPECIAL + "aurelia_draw.gd", "portrait": SPECIAL + "aurelia_portrait.gd",
		"robe": Color("#ece8f4"), "robe2": Color("#fff6dc"), "skin": Color("#f7dcc9"), "hair": Color("#f8e0a0"),
		"hair_style": "long", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#ffffff"), "extra": [],
	},
	"benedicta": {
		"name": "베네딕타 대사제", "color": Color("#f0e0b8"), "voice": 0.78, "height": 34, "look": "benedicta",
		"draw": SPECIAL + "temple_folk_draw.gd", "portrait": SPECIAL + "temple_folk_portrait.gd",
		"robe": Color("#ece6f2"), "robe2": Color("#d8a840"), "skin": Color("#efd2c2"), "hair": Color("#c8c4cc"),
		"hair_style": "bun", "hat": "none", "hat_col": Color("#ece6f2"), "eye": Color("#6a5a7a"), "extra": [],
	},
	"luca": {
		"name": "루카", "color": Color("#b8e0a0"), "voice": 1.32, "height": 27, "look": "luca",
		"draw": SPECIAL + "temple_folk_draw.gd", "portrait": SPECIAL + "temple_folk_portrait.gd",
		"robe": Color("#e8e4ee"), "robe2": Color("#c89a3a"), "skin": Color("#f4d6c2"), "hair": Color("#8a5a32"),
		"hair_style": "short", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#4a6a3a"), "extra": [],
	},
	"gregor": {
		"name": "그레고르", "color": Color("#d8b088"), "voice": 0.66, "height": 31, "look": "gregor",
		"draw": SPECIAL + "temple_folk_draw.gd", "portrait": SPECIAL + "temple_folk_portrait.gd",
		"robe": Color("#6a5040"), "robe2": Color("#a8885a"), "skin": Color("#e8c4ac"), "hair": Color("#e8e4e0"),
		"hair_style": "none", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#4a3a2a"), "extra": [],
	},
	"tp_monk": {
		"name": "수도사", "color": Color("#e0dcea"), "voice": 0.86, "height": 33, "look": "monk",
		"draw": SPECIAL + "temple_folk_draw.gd", "portrait": SPECIAL + "temple_folk_portrait.gd",
		"robe": Color("#dcd8e6"), "robe2": Color("#c8a040"), "skin": Color("#e8c8b4"), "hair": Color("#4a3a30"),
		"hair_style": "short", "hat": "none", "hat_col": Color("#dcd8e6"), "eye": Color("#3a3040"), "extra": [],
	},
	"tp_priest": {
		"name": "사제", "color": Color("#f0e4c0"), "voice": 0.95, "height": 33, "look": "priest",
		"draw": SPECIAL + "temple_folk_draw.gd", "portrait": SPECIAL + "temple_folk_portrait.gd",
		"robe": Color("#f0ecf6"), "robe2": Color("#d8a840"), "skin": Color("#f2d6c4"), "hair": Color("#5a3e2a"),
		"hair_style": "short", "hat": "none", "hat_col": Color("#d8a840"), "eye": Color("#4a3a2a"), "extra": [],
	},
	"tp_pilgrim": {
		"name": "순례자", "color": Color("#c8c0b0"), "voice": 0.9, "height": 32, "look": "pilgrim",
		"draw": SPECIAL + "temple_folk_draw.gd", "portrait": SPECIAL + "temple_folk_portrait.gd",
		"robe": Color("#6a6458"), "robe2": Color("#a85a4a"), "skin": Color("#e6c4ac"), "hair": Color("#3a2e28"),
		"hair_style": "short", "hat": "none", "hat_col": Color("#5a5448"), "eye": Color("#3a3028"), "extra": [],
	},
	"tp_pilgrim_b": {
		"name": "순례자", "color": Color("#c8c0b0"), "voice": 1.1, "height": 30, "look": "pilgrim",
		"draw": SPECIAL + "temple_folk_draw.gd", "portrait": SPECIAL + "temple_folk_portrait.gd",
		"robe": Color("#4e5a6a"), "robe2": Color("#d8b860"), "skin": Color("#f2d4c0"), "hair": Color("#a86a3a"),
		"hair_style": "long", "hat": "none", "hat_col": Color("#46505e"), "eye": Color("#3a4a5a"), "extra": [],
	},
	"tp_choir": {
		"name": "성가대원", "color": Color("#e8e0ff"), "voice": 1.25, "height": 30, "look": "choir",
		"draw": SPECIAL + "temple_folk_draw.gd", "portrait": SPECIAL + "temple_folk_portrait.gd",
		"robe": Color("#f2eef8"), "robe2": Color("#7a6ab8"), "skin": Color("#f4dccc"), "hair": Color("#2a2430"),
		"hair_style": "bob", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#3a3050"), "extra": [],
	},
	"tp_voice": {
		"name": "???", "color": Color("#f0f0ff"), "voice": 0.5,
	},
}

## 이 장의 방 ID (지도·검사용) — 2단계에서 채움 (docs/chapter4.md 8절 방 목록)
const ROOMS := []

## 메인 목표 줄: [완료 플래그, 표시 문구, 필요 플래그] — 2단계에서 채움 (docs/chapter4.md 10절 초안)
const OBJECTIVES := []

## 퀘스트 (docs/systems2.md 4절) — 2단계에서 채움 (docs/chapter4.md 11절 초안)
const QUESTS := {}
