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
	"warden_a": {
		"name": "파수꾼 리엔", "color": Color("#9ac870"), "voice": 0.85,
		"robe": Color("#34552c"), "robe2": Color("#b8c070"), "skin": Color("#ecd2bc"), "hair": Color("#b8c880"),
		"hair_style": "short", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#3a8a4a"), "height": 33,
		"extra": ["warden"],
		"draw": SP + "elf_folk_draw.gd", "portrait": SP + "elf_folk_portrait.gd",
	},
	"warden_b": {
		"name": "파수꾼 소르", "color": Color("#88c0a8"), "voice": 0.78,
		"robe": Color("#2e4a44"), "robe2": Color("#98b890"), "skin": Color("#e6caae"), "hair": Color("#90b098"),
		"hair_style": "tied", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#2a7a6a"), "height": 34,
		"extra": ["warden"],
		"draw": SP + "elf_folk_draw.gd", "portrait": SP + "elf_folk_portrait.gd",
	},
	"fio_mom": {
		"name": "피오 엄마", "color": Color("#c8e098"), "voice": 1.05,
		"robe": Color("#5a6a3a"), "robe2": Color("#e8c860"), "skin": Color("#f4dcc8"), "hair": Color("#b8d870"),
		"hair_style": "bun", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#3a9a4a"), "height": 32,
		"extra": ["apron", "flower"],
		"draw": SP + "elf_folk_draw.gd", "portrait": SP + "elf_folk_portrait.gd",
	},
}

## 이 장의 방 ID (지도·검사용) — docs/chapter3.md 8절 지도
const ROOMS := [
	"e_gate", "e_border_1", "e_border_2", "e_border_3", "e_border_4",
	"e_roots", "e_elder_hall", "e_roots_homes",
	"e_cave_1", "e_cave_2", "e_hollow", "e_cave_3",
	"e_trunk_market", "e_workshop", "e_trunk_lift",
	"e_wind_1", "e_wind_2", "e_wind_3",
	"e_branch_homes", "e_archery", "e_moonwell", "e_secret_grove",
	"e_blight_1", "e_blight_2", "e_blight_3",
	"e_canopy_1", "e_canopy_2", "e_canopy_3", "e_hunt_arena",
	"e_crown_1", "e_crown_2", "e_crown_nest",
]

## 메인 목표 줄: [완료 플래그, 표시 문구, 필요 플래그] — docs/chapter3.md 10절
const OBJECTIVES := [
	["e_letter", "교장실로 가자 (중앙 홀 2층 오른쪽 → 시계탑 꼭대기)", "e_start"],
	["e_arrived", "앞마당 전이진으로 엘프의 숲에 가자", "e_letter"],
	["e_border_passed", "숲 경계를 지나 세계수로 — 붉은 예고선이 보이면 바위·쓰러진 나무 뒤로", "e_arrived"],
	["e_met_ortia", "뿌리 마을 장로의 집에서 편지를 전하자", "e_border_passed"],
	["e_met_tiel", "뿌리 동굴을 지나 줄기 시장의 티엘에게 (승강기 고장)", "e_met_ortia"],
	["e_wind_done", "바람길을 올라 가지 마을로 — 밸브를 불로 돌리면 바람이 바뀐다", "e_met_tiel"],
	["e_moon_lesson", "가지 마을 위쪽 가지 끝, 달샘으로", "e_wind_done"],
	["e_grove_purified", "흰 역병의 숲 깊은 곳 — 굳은 숲의 심장을 잠재우자", "e_moon_lesson"],
	["e_meteor_hint", "가지 마을 위층 계단으로 수관에 오르자 (선택: 학교 수업 게시판에 유성 낙화 수업이 열렸다)", "e_grove_purified"],
	["e_hunt_done", "수관 경기장에서 엘라리엔의 사냥 시험 — 세 번 닿아라", "e_grove_purified"],
	["e_herald_done", "세계수 꼭대기로 — 아이들이 위험하다", "e_hunt_done"],
	["ch3_done", "학교로 돌아가 쉬자", "e_herald_done"],
]

## 퀘스트 (docs/systems2.md 4절) — docs/chapter3.md 11절. 모으는 물건은 퀘스트를 받기 전에 주워도 센다.
const QUESTS := {
	"e_fio_seeds": {
		"title": "피오의 반짝이 씨앗", "giver": "fio", "kind": "side", "chapter": 3, "need": "e_met_ortia",
		"desc": "피오가 \"별이 될 씨앗\"이라며 모으던 반짝이 씨앗을 마을 곳곳에 흘렸다. 뿌리 마을·피오네 집·줄기 시장·바람길·가지 마을 어딘가에 다섯 개.",
		"steps": ["반짝이 씨앗 다섯 개 찾기", "뿌리 마을의 피오에게 돌려주기"],
		"reward": {"stones": 1, "text": "피오의 비밀: 가지 마을 왼쪽 위 끝의 반짝이는 벽"},
	},
	"e_tiel_valve": {
		"title": "티엘의 바람 밸브", "giver": "tiel", "kind": "side", "chapter": 3, "need": "e_met_tiel",
		"desc": "바람길 세 굴에 하나씩, 톱니가 녹슬어 멈춘 밸브가 있다. 불로 세 번 데우면 풀린다. 풀린 밸브는 숨은 바람을 되살린다.",
		"steps": ["바람길의 고장 난 밸브 세 개 고치기", "줄기 시장 공방의 티엘에게 알리기"],
		"reward": {"stones": 2},
	},
	"e_ortia_tea": {
		"title": "장로의 달잎 차", "giver": "ortia", "kind": "side", "chapter": 3, "need": "e_met_ortia",
		"desc": "오르티아 장로가 즐겨 마시던 달잎 차. 달샘의 달잎과 수관 높은 잎의 이슬이 있어야 끓일 수 있다.",
		"steps": ["달샘의 달잎과 수관의 이슬 구하기", "장로의 집으로 가져가기"],
		"reward": {"potion_slot": 1},
	},
	"e_archery": {
		"title": "엘라리엔의 활터", "giver": "elarien", "kind": "side", "chapter": 3, "need": "e_hunt_done",
		"desc": "\"바람을 읽어 봐라.\" 가지 마을 아래 활터의 과녁 넷을 20초 안에 불로 맞히자. 움직이는 과녁은 앞을 보고 쏠 것.",
		"steps": ["활터의 과녁 넷을 20초 안에 맞히기"],
		"reward": {"stones": 2},
	},
	"e_pippa_moss": {
		"title": "피피의 빛이끼 표본", "giver": "pippa", "kind": "side", "chapter": 3, "need": "e_start",
		"desc": "피피가 하얗게 굳은 묘목을 살릴 약을 연구하려면 세계수 뿌리에서 자라는 빛이끼가 필요하다. 표본 세 개.",
		"steps": ["세계수 뿌리 동굴에서 빛이끼 표본 세 개 모으기", "학교 온실의 피피에게 가져가기"],
		"reward": {"stones": 1},
	},
	"e_honey": {
		"title": "버터워스의 숲 꿀", "giver": "butterworth", "kind": "side", "chapter": 3, "need": "e_start",
		"desc": "\"엘프 숲 꿀은 한 숟갈이면 사흘을 버틴단다.\" 세계수 어딘가 오래된 벌집의 꿀을 구해 식당으로.",
		"steps": ["세계수에서 숲 꿀 구하기", "학교 식당의 버터워스 아주머니에게 가져가기"],
		"reward": {"heart": 1, "text": "꿀 바른 숲빵"},
	},
	"s_duel_cup": {
		"title": "학교 결투 대회", "giver": "isolde", "kind": "side", "chapter": 3, "need": "e_letter",
		"desc": "학교 결투 대회 결승. 이졸데가 결투장에서 기다린다. 서리 마법 — 얼음 창은 붉은 선을 따라, 서리 바닥은 밟지 말 것.",
		"steps": ["이졸데와 결투 (앞마당의 이졸데에게 말 걸면 결투장으로)"],
		"reward": {"feather": 1},
	},
}
