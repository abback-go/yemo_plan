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
		"name": "성가대원 엘사", "color": Color("#e8e0ff"), "voice": 1.25, "height": 30, "look": "choir",
		"draw": SPECIAL + "temple_folk_draw.gd", "portrait": SPECIAL + "temple_folk_portrait.gd",
		"robe": Color("#f2eef8"), "robe2": Color("#7a6ab8"), "skin": Color("#f4dccc"), "hair": Color("#2a2430"),
		"hair_style": "bob", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#3a3050"), "extra": [],
	},
	"tp_anselm": {
		"name": "쉼터지기 안셀름", "color": Color("#d8c8a8"), "voice": 0.8, "height": 34, "look": "monk",
		"draw": SPECIAL + "temple_folk_draw.gd", "portrait": SPECIAL + "temple_folk_portrait.gd",
		"robe": Color("#8a7a62"), "robe2": Color("#c8a040"), "skin": Color("#e2bea6"), "hair": Color("#6a5a4a"),
		"hair_style": "short", "hat": "none", "hat_col": Color("#8a7a62"), "eye": Color("#3a3028"), "extra": [],
	},
	## 바깥 신들의 겹친 메아리 (내전 폭주 장면) — 흰 기하학 초상화
	"tp_voice": {
		"name": "???", "color": Color("#f0f0ff"), "voice": 0.5, "portrait": SPECIAL + "outer_voice_portrait.gd",
		"robe": Color("#f0f0ff"), "robe2": Color("#ffffff"), "skin": Color("#ffffff"), "hair": Color("#ffffff"),
		"hair_style": "none", "hat": "none", "hat_col": Color("#ffffff"), "eye": Color("#ffffff"), "height": 30, "extra": [],
	},
	## 리라 — 5장 담당이 전용 그림으로 덮어쓴다(EXTS 순서상 ch5가 뒤). 4장 끝 등장 장면이 혼자서도 돌아가게 둔 기본값.
	"lyra": {
		"name": "리라", "color": Color("#c8c0ff"), "voice": 0.85, "height": 40,
		"robe": Color("#1a1e48"), "robe2": Color("#e8d8a0"), "skin": Color("#f4e2da"), "hair": Color("#e8e8f4"),
		"hair_style": "long", "hat": "witch", "hat_col": Color("#141838"), "eye": Color("#a88ae8"), "extra": ["stars"],
	},
}

## 이 장의 방 ID (지도·검사용) — tools/rooms/ch4.py, docs/chapter4.md 7.2절
const ROOMS := [
	"tp_road", "tp_road_1", "tp_road_2", "tp_cave", "tp_road_3", "tp_hut", "tp_road_4",
	"tp_gate", "tp_cloister", "tp_garden", "tp_choir", "tp_nave", "tp_monk_cells",
	"tp_mirror_1", "tp_mirror_2", "tp_mirror_3", "tp_bell_1", "tp_bell_2", "tp_bell_3",
	"tp_archive_1", "tp_scriptorium", "tp_archive_2", "tp_crypt_1", "tp_crypt_2",
	"tp_sanctum", "tp_spire_1", "tp_spire_2", "tp_spire_3", "tp_spire_4", "tp_spire_5", "tp_spire_top",
]

## 메인 목표 줄: [완료 플래그, 표시 문구, 필요 플래그] — 3장 끝(ch3_done)에서 이어짐 (docs/chapter4.md 7.3절)
const OBJECTIVES := [
	["tp_arrived", "앞마당에서 교장 선생님의 이야기를 듣자", "ch3_done"],
	["tp_gate_scene", "레오니와 함께 순례길을 올라 성산 대신전으로", "tp_arrived"],
	["tp_trials_done", "자격의 시련 셋 — 거울(회랑 왼쪽) · 종(정원 너머 종탑) · 기록(회랑 아래 기록실)", "tp_gate_scene"],
	["tp_aurelia_talk", "본당의 아우렐리아에게 시련을 마쳤다고 알리자 (회랑 → 본당)", "tp_trials_done"],
	["tp_sanctum_berserk", "본당 제단 옆 계단으로 — 내전에서 아우렐리아가 기도를 올린다", "tp_aurelia_talk"],
	["tp_spire_top_reached", "첨탑 위로 도망쳐라! 멈추면 금빛에 잡힌다", "tp_sanctum_berserk"],
	["tp_aurelia_defeated", "첨탑 꼭대기 — 아우렐리아를 멈춰라", "tp_spire_top_reached"],
]

## 퀘스트 (docs/systems2.md 4절, docs/chapter4.md 6절·7.7절)
## 받는 법: 인물에게 말을 걸면 대본이 quest_start. 단계마다 talk의 [단계, 인물, 대본]이 그 인물과의 대화를 대신한다.
const QUESTS := {
	"tp_luca_clapper": {
		"title": "잃어버린 종 추", "giver": "luca", "kind": "side", "chapter": 4, "need": "tp_gate_scene",
		"desc": "견습 사제 루카가 종 추를 잃어버렸다. 종탑 청소를 하다 떨어뜨린 것 같다고.",
		"steps": ["종탑 아래층에서 루카의 종 추 찾기", "회랑 정원의 루카에게 돌려주기"],
		"talk": [[1, "luca", "tp_luca_return"]],
		"reward": {"stones": 1},
	},
	"tp_gregor_bells": {
		"title": "종 조율", "giver": "gregor", "kind": "side", "chapter": 4, "need": "tp_gate_scene",
		"desc": "귀가 어두운 종지기 그레고르가 작은 종 셋의 소리를 맞춰 달라고 한다. 그가 흥얼거린 차례: 높음 → 낮음 → 가운데 → 높음.",
		"steps": ["큰 종 다락의 작은 종 셋을 높음 → 낮음 → 가운데 → 높음 차례로 울리기", "그레고르에게 알리기"],
		"talk": [[1, "gregor", "tp_gregor_done"]],
		"reward": {"stones": 2},
	},
	"tp_choir_voice": {
		"title": "사라진 성가대원", "giver": "tp_choir", "kind": "side", "chapter": 4, "need": "tp_gate_scene",
		"desc": "성가대의 마리가 순례길의 얼음 사당에 기도하러 갔다가 돌아오지 않았다. 엘사는 마리가 그림자가 되었을까 봐 무섭다.",
		"steps": ["순례길 바람의 능선, 얼음 사당 근처에서 마리 찾기", "성가대석의 엘사에게 알리기"],
		"talk": [[1, "tp_choir", "tp_choir_done"]],
		"reward": {"potion_slot": 1},
	},
	"tp_candles": {
		"title": "기도 촛불", "giver": "benedicta", "kind": "side", "chapter": 4, "need": "tp_gate_scene",
		"desc": "베네딕타 대사제의 부탁: 루멘의 침묵 뒤로 꺼진 기도 촛불 다섯 개를 다시 밝혀 달라. (정원·거울 Ⅱ·종탑·필사실·수도사 숙소)",
		"steps": ["신전 곳곳의 기도 촛불 다섯 개 밝히기", "회랑의 베네딕타 대사제에게 알리기"],
		"talk": [[1, "benedicta", "tp_candles_done"]],
		"reward": {"stones": 2},
	},
	"tp_leonie_badge": {
		"title": "견습 기사의 배지", "giver": "leonie", "kind": "side", "chapter": 4, "need": "tp_arrived",
		"desc": "어린 레오니가 순례 중 눈보라를 피했던 동굴에 두고 온 견습 기사 배지. 벼랑길 꼭대기 어딘가, 바위 틈 너머라고 한다.",
		"steps": ["벼랑길 꼭대기 바위 틈 너머 동굴에서 배지 찾기", "레오니에게 돌려주기"],
		"talk": [[1, "leonie", "tp_badge_return"]],
		"reward": {"feather": 1, "text": "수호의 깃털"},
	},
	"tp_herbs": {
		"title": "산의 약초", "giver": "butterworth", "kind": "side", "chapter": 4, "need": "ch3_done",
		"desc": "버터워스 아주머니가 성산의 눈꽃 약초로 원기 수프를 끓이고 싶어 한다. 대신전 오르막 골짜기, 바람이 솟는 곳에 핀다고.",
		"steps": ["대신전 오르막 골짜기에서 눈꽃 약초 찾기", "학교 식당의 버터워스 아주머니에게 가져다주기"],
		"talk": [[1, "butterworth", "tp_herbs_done"]],
		"reward": {"heart": 1},
	},
	"tp_pippa_water": {
		"title": "성수 실험", "giver": "pippa", "kind": "side", "chapter": 4, "need": "ch3_done",
		"desc": "피피가 성산 대신전의 성수로 실험을 하고 싶어 한다. \"빛이 녹아 있는 물이라니, 이건 연금술사의 꿈이야!\"",
		"steps": ["대신전 회랑의 성수반에서 성수 뜨기", "학교 연금술실의 피피에게 가져다주기"],
		"talk": [[1, "pippa", "tp_pippa_done"]],
		"reward": {"stones": 1},
	},
}
