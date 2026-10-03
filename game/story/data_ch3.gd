extends RefCounted
## 3장 데이터 — ChapterRegistry가 합친다 (docs/systems2.md 1절, docs/chapter3.md).

const SP := "res://characters/special/"

## 인물: 1장 Characters.DB와 같은 키 (+ 전용 그림 "draw"·"portrait").
## 전용 그림이 있어도 일반 값(robe·hair 등)을 함께 둔다 — 다른 곳(1장 기본 그림·초상화)이 읽어도 깨지지 않게.
const CHARACTERS := {
	"elarien": {
		"name": "엘라리엔", "color": Color("#c8e88a"), "voice": 0.95,
		"robe": Color("#3c5a2d"), "robe2": Color("#e6bf4e"), "skin": Color("#f3dac6"), "hair": Color("#d6e29e"),
		"hair_style": "tied", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#36b85a"), "height": 36, "extra": [],
		"draw": SP + "elarien_draw.gd", "portrait": SP + "elarien_portrait.gd",
	},
	"ortia": {
		"name": "오르티아 장로", "color": Color("#b8d890"), "voice": 0.7,
		"robe": Color("#5a4430"), "robe2": Color("#4a6a36"), "skin": Color("#e8ccb6"), "hair": Color("#e6e6da"),
		"hair_style": "long", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#b8c878"), "height": 34, "extra": [],
		"draw": SP + "ortia_draw.gd", "portrait": SP + "ortia_portrait.gd",
	},
	"fio": {
		"name": "피오", "color": Color("#a8e070"), "voice": 1.45,
		"robe": Color("#4a7a3a"), "robe2": Color("#e8c860"), "skin": Color("#f6dcc8"), "hair": Color("#b8d870"),
		"hair_style": "mop", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#3a9a4a"), "height": 24,
		"extra": ["leafcap", "satchel", "freckles"],
		"draw": SP + "elf_folk_draw.gd", "portrait": SP + "elf_folk_portrait.gd",
	},
	"tiel": {
		"name": "티엘", "color": Color("#8ad0c0"), "voice": 1.05,
		"robe": Color("#5a553a"), "robe2": Color("#c8a040"), "skin": Color("#f0d6c2"), "hair": Color("#6ab0a0"),
		"hair_style": "tied", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#2a8a7a"), "height": 31,
		"extra": ["goggles", "tools", "apron"],
		"draw": SP + "elf_folk_draw.gd", "portrait": SP + "elf_folk_portrait.gd",
	},
	"elf_warden": {
		"name": "엘프 파수꾼", "color": Color("#8ab870"), "voice": 0.9,
		"robe": Color("#3a5a2e"), "robe2": Color("#a8c060"), "skin": Color("#f0d6c2"), "hair": Color("#c8d890"),
		"hair_style": "short", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#3a8a4a"), "height": 33,
		"extra": ["warden"],
		"draw": SP + "elf_folk_draw.gd", "portrait": SP + "elf_folk_portrait.gd",
	},
	"elf_a": {
		"name": "엘프 주민", "color": Color("#c8d8a0"), "voice": 1.0,
		"robe": Color("#6a5a3a"), "robe2": Color("#c8b060"), "skin": Color("#f2dac6"), "hair": Color("#d8e0a0"),
		"hair_style": "long", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#4a8a4a"), "height": 32,
		"extra": ["basket"],
		"draw": SP + "elf_folk_draw.gd", "portrait": SP + "elf_folk_portrait.gd",
	},
	"elf_b": {
		"name": "엘프 주민", "color": Color("#a8d0c8"), "voice": 0.95,
		"robe": Color("#3a5a5a"), "robe2": Color("#d8c890"), "skin": Color("#f4e0cc"), "hair": Color("#a8c890"),
		"hair_style": "bun", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#3a7a6a"), "height": 33,
		"extra": ["flower"],
		"draw": SP + "elf_folk_draw.gd", "portrait": SP + "elf_folk_portrait.gd",
	},
	"elf_c": {
		"name": "엘프 아이", "color": Color("#e0e8b0"), "voice": 1.5,
		"robe": Color("#7a4a3a"), "robe2": Color("#e8d070"), "skin": Color("#f6dece"), "hair": Color("#e0e8b0"),
		"hair_style": "mop", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#4a9a5a"), "height": 22,
		"extra": ["freckles"],
		"draw": SP + "elf_folk_draw.gd", "portrait": SP + "elf_folk_portrait.gd",
	},
}

## 이 장의 방 ID (지도·검사용) — 2단계에서 채움 (docs/chapter3.md 8절 방 목록)
const ROOMS := []

## 메인 목표 줄: [완료 플래그, 표시 문구, 필요 플래그] — 2단계에서 채움 (docs/chapter3.md 10절)
const OBJECTIVES := []

## 퀘스트 (docs/systems2.md 4절) — 2단계에서 채움 (docs/chapter3.md 11절)
const QUESTS := {}
