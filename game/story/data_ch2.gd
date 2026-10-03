extends RefCounted
## 2장 데이터 — ChapterRegistry가 합친다 (docs/systems2.md 1절).

## 인물: 1장 Characters.DB와 같은 키 (+ 전용 그림 "draw"·"portrait")
## 강자·주요 인물은 전용 그림, 시민은 CharacterVisual 기본 값. 이름 표기는 docs/bible/characters.md.
const CHARACTERS := {
	# 2장 강자 — 은사자 기사단장 (전용 몸·초상화, 키 40)
	"leonie": {
		"name": "레오니", "color": Color("#f0606a"), "voice": 0.78,
		"draw": "res://characters/special/leonie_draw.gd", "portrait": "res://characters/special/leonie_portrait.gd",
		"robe": Color("#a6adc0"), "robe2": Color("#a01e2c"), "skin": Color("#f2d2be"), "hair": Color("#1e2748"),
		"hair_style": "short", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#ffc23a"), "height": 40, "extra": [],
	},
	# 부단장 카엘 — 수다스럽고 허당, 레오니 바라기 (투구 없는 기사)
	"kael": {
		"name": "카엘", "color": Color("#ffb070"), "voice": 1.0,
		"draw": "res://characters/special/k_knight_draw.gd",
		"robe": Color("#8e94a8"), "robe2": Color("#a01e2c"), "skin": Color("#f0cbb0"), "hair": Color("#b8582e"),
		"hair_style": "short", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#5a8a3a"), "height": 37, "extra": [],
		"helm": false, "weapon": "sword",
	},
	# 시장 빵집 소녀 미아(10살) — 레오니의 열성 팬
	"mia": {
		"name": "미아", "color": Color("#ffc48a"), "voice": 1.5,
		"robe": Color("#c8705a"), "robe2": Color("#f0e8dc"), "skin": Color("#f6dcc8"), "hair": Color("#8a5430"),
		"hair_style": "twin", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#6a3a2a"), "height": 24, "extra": ["apron"],
	},
	# 대장장이 브론 — 무뚝뚝
	"bron": {
		"name": "브론", "color": Color("#d8a070"), "voice": 0.62,
		"robe": Color("#4a3428"), "robe2": Color("#8a5a3a"), "skin": Color("#d8a888"), "hair": Color("#3a3434"),
		"hair_style": "none", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#2a2020"), "height": 38, "extra": ["apron", "gloves"],
	},
	# 별 신도 대사제 녹시스 — 별 가면, 별자리 로브 (전용 몸·초상화)
	"noxis": {
		"name": "녹시스", "color": Color("#c89aff"), "voice": 0.72,
		"draw": "res://characters/special/noxis_draw.gd", "portrait": "res://characters/special/noxis_portrait.gd",
		"robe": Color("#241c44"), "robe2": Color("#c89aff"), "skin": Color("#e0d0d8"), "hair": Color("#d8d0e8"),
		"hair_style": "long", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#c89aff"), "height": 39, "extra": [],
	},
	# 투기장 챔피언 가론 (대화용 — 싸울 때는 적 그림)
	"garon": {
		"name": "가론", "color": Color("#e8b060"), "voice": 0.66,
		"robe": Color("#6a3a24"), "robe2": Color("#c8a040"), "skin": Color("#c88a68"), "hair": Color("#2a1a14"),
		"hair_style": "tied", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#3a2a18"), "height": 40, "extra": ["gloves"],
	},
	# ─ 은사자 기사 (투구 쓴 일반 기사) ─
	"k_knight": {
		"name": "은사자 기사", "color": Color("#c8ccd8"), "voice": 0.9,
		"draw": "res://characters/special/k_knight_draw.gd",
		"robe": Color("#8e94a8"), "robe2": Color("#a01e2c"), "skin": Color("#eecab0"), "hair": Color("#4a3a2a"),
		"hair_style": "short", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#3a3a4a"), "height": 37, "extra": [],
		"helm": true, "weapon": "spear",
	},
	"k_knight_b": {
		"name": "은사자 기사", "color": Color("#c8ccd8"), "voice": 1.05,
		"draw": "res://characters/special/k_knight_draw.gd",
		"robe": Color("#8e94a8"), "robe2": Color("#a01e2c"), "skin": Color("#f2d4bc"), "hair": Color("#d8b060"),
		"hair_style": "short", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#3a5a8a"), "height": 35, "extra": [],
		"helm": false, "weapon": "sword",
	},
	# ─ 시민 ─
	"k_citizen_a": {
		"name": "아주머니", "color": Color("#e8c8a8"), "voice": 1.1,
		"robe": Color("#5a3a4a"), "robe2": Color("#e8dcc8"), "skin": Color("#f0d0b8"), "hair": Color("#6a3a2a"),
		"hair_style": "bun", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#4a2a2a"), "height": 33, "extra": ["apron"],
	},
	"k_citizen_b": {
		"name": "할아버지", "color": Color("#c8c0b0"), "voice": 0.72,
		"robe": Color("#3a4a3a"), "robe2": Color("#8a7a5a"), "skin": Color("#e8c8b0"), "hair": Color("#d8d8d8"),
		"hair_style": "short", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#3a3a3a"), "height": 32, "extra": ["glasses"],
	},
	"k_citizen_c": {
		"name": "청년", "color": Color("#b8c8e0"), "voice": 0.95,
		"robe": Color("#2e3a5a"), "robe2": Color("#c8a040"), "skin": Color("#f0d0b8"), "hair": Color("#2a2420"),
		"hair_style": "short", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#3a2a20"), "height": 35, "extra": [],
	},
	"k_child": {
		"name": "아이", "color": Color("#ffd8a8"), "voice": 1.55,
		"robe": Color("#3a6a8a"), "robe2": Color("#e8c040"), "skin": Color("#f6dcc8"), "hair": Color("#c8883a"),
		"hair_style": "short", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#4a6a3a"), "height": 22, "extra": [],
	},
	"k_merchant": {
		"name": "상인", "color": Color("#e0c070"), "voice": 0.85,
		"robe": Color("#6a4a2a"), "robe2": Color("#c8a040"), "skin": Color("#eec4a4"), "hair": Color("#5a3a20"),
		"hair_style": "short", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#3a2a1a"), "height": 34, "extra": ["apron"],
	},
	"k_priest": {
		"name": "사제", "color": Color("#ffe8a0"), "voice": 0.82,
		"robe": Color("#d8d4c8"), "robe2": Color("#c8a040"), "skin": Color("#f0d8c8"), "hair": Color("#a8a8a8"),
		"hair_style": "short", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#4a4a3a"), "height": 34, "extra": [],
	},
	"k_arena_master": {
		"name": "투기장 지배인", "color": Color("#ffb4d0"), "voice": 1.0,
		"robe": Color("#5a1a3a"), "robe2": Color("#e8c040"), "skin": Color("#f0d0b8"), "hair": Color("#e8e0d0"),
		"hair_style": "short", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#5a2a4a"), "height": 34, "extra": ["feather"],
	},
	"k_envoy": {
		"name": "제국 사자", "color": Color("#d8c0a0"), "voice": 0.9,
		"robe": Color("#2a2440"), "robe2": Color("#a01e2c"), "skin": Color("#f0d4c0"), "hair": Color("#3a3028"),
		"hair_style": "tied", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#3a2a20"), "height": 35, "extra": [],
	},
	"k_cultist": {
		"name": "별 신도", "color": Color("#b090e8"), "voice": 0.92,
		"robe": Color("#1e1838"), "robe2": Color("#c89aff"), "skin": Color("#d8c8d0"), "hair": Color("#1e1838"),
		"hair_style": "long", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#c89aff"), "height": 34, "extra": ["stars"],
	},
}

## 이 장의 방 ID (지도·검사용) — 2단계에서 채운다 (docs/chapter2.md 7절)
const ROOMS := []

## 메인 목표 줄: [완료 플래그, 표시 문구, 필요 플래그] — 2단계에서 채운다 (docs/chapter2.md 7.3절)
const OBJECTIVES := []

## 퀘스트 (docs/systems2.md 4절) — 2단계에서 채운다 (docs/chapter2.md 7.4절)
const QUESTS := {}
