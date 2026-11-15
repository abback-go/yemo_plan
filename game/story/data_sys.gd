extends RefCounted
## 공통 시스템 데이터 — 마법 수업 4종 (docs/archive/sera/magic.md 4절). ChapterRegistry가 합친다.
## 수업 퀘스트(kind = "class")는 수업 게시판(class_board)의 "마법 배우기" 창에 나온다:
##   spell(배울 마법) · unlock(잠김 해제 조건: 플래그 식 + "mana>=N") · unlock_text(잠김일 때 보이는 문구)
## 단계마다 그 인물에게 말을 걸면 talk의 대본이 먼저 실행된다(Quests.talk_hook).
## 형식 (모든 data_<장>.gd 공통 — 자세히: docs/dev/story.md "데이터 형식"):
##   CHAPTER    장 정보 {n, title, tails_at_end, last, areas, warps, credits} (ChapterRegistry 머리 주석)
##   SCRIPTS    대본 파일 경로 — Story가 이 순서로 읽는다
##   CHARACTERS 인물 ID → {name, color, voice, 몸 그림 값(robe·hair…), draw·portrait(전용 그림 경로)}
##   OBJECTIVES [완료 플래그, HUD 문구, 필요 조건(Cond 식, ""=항상)] — 위에서부터 "조건 참·완료 아직"인 첫 줄이 현재 목표
##   QUESTS     ID → {title, giver, kind(side·class·main), chapter, need(Cond 식), desc, steps[문구…],
##              talk[[단계, 인물, 대본 ID]…], reward{stones, potion_slot, heart, feather, text}}
##              수업(kind = "class")은 + spell(마법 ID), unlock(Cond 식), unlock_text

## 대본 파일 (Story가 이 순서로 읽는다). sys는 장이 아니라 CHAPTER가 없다
const SCRIPTS := [
	"res://story/sys/board_wings.gd",
	"res://story/sys/ward.gd",
	"res://story/sys/meteor.gd",
	"res://story/sys/phoenix.gd",
]

const CHARACTERS := {
	"shadow_sera": {
		"name": "불 속의 나", "color": Color("#c84a6a"), "voice": 0.9,
		"robe": Color("#120a18"), "robe2": Color("#3a1030"), "skin": Color("#3a2a3a"), "hair": Color("#060408"),
		"hair_style": "long", "hat": "witch", "hat_col": Color("#0a060e"), "eye": Color("#ff3a3a"), "height": 32, "extra": [],
		"portrait": "res://characters/special/shadow_sera_portrait.gd",
	},
}

const OBJECTIVES := []

const QUESTS := {
	"cls_wings": {
		"title": "불꽃 날개 수업", "giver": "ophelia", "kind": "class", "spell": "wings", "chapter": 2,
		"unlock": "ch1_done", "unlock_text": "2장이 시작되면 들을 수 있다.",
		"desc": "떨어지는 몸에 불꽃 날개를 달아 바람을 타는 법. 담당: 오필리아 교수(비속성마법반).",
		"steps": [
			"비속성마법반의 오필리아 교수 찾아가기",
			"바람의 탑(부양 실습실 왼쪽 끝): 등불 다섯 개 밝히기",
		],
		"talk": [[0, "ophelia", "cls_wings_lesson"]],
		"reward": {"stones": 1},
	},
	"cls_ward": {
		"title": "불꽃 방벽 수업", "giver": "emberlyn", "kind": "class", "spell": "ward", "chapter": 2,
		"unlock": "k_spar_done", "unlock_text": "제국에서 레오니와 대련한 뒤에 들을 수 있다.",
		"desc": "불을 쏘는 게 아니라 두르는 법. 막고, 되돌려 주고, 데게 한다. 담당: 엠버린 교수(실습장).",
		"steps": [
			"실습장의 엠버린 교수 찾아가기",
			"발사대의 마력탄을 방벽으로 되쳐 과녁 셋 밝히기",
			"엠버린 교수의 화염구 열 발 막아내기",
		],
		"talk": [[0, "emberlyn", "cls_ward_lesson"], [2, "emberlyn", "cls_ward_duel"]],
		"reward": {"stones": 1},
	},
	"cls_meteor": {
		"title": "유성 낙화 수업 (고급)", "giver": "veronica", "kind": "class", "spell": "meteor", "chapter": 3,
		"unlock": "e_grove_purified,mana>=6", "unlock_text": "엘프의 숲 세계수를 정화하고, 마도석을 지금까지 6개 이상 얻은 뒤.",
		"desc": "모든 마력을 하늘에 바쳐 별을 떨어뜨리는 고급 마법. 별을 읽는 눈과, 넘치는 힘을 붙드는 손이 필요하다. 담당: 베로니카 교수.",
		"steps": [
			"비속성마법반의 오필리아 교수에게 별 관측 수업 듣기",
			"시계탑 꼭대기 → 지붕: 거문고자리를 순서대로 잇기",
			"고급마법반의 베로니카 교수 찾아가기",
			"결투장: 폭주 제어 시험 (게이지 70~95%를 20초)",
			"결투장: 베로니카 교수와 결투",
		],
		"talk": [[0, "ophelia", "cls_meteor_lesson"], [2, "veronica", "cls_meteor_veronica"]],
		"reward": {"stones": 2},
	},
	"cls_phoenix": {
		"title": "불사조 (금서)", "giver": "greta", "kind": "class", "spell": "phoenix", "chapter": 5,
		"unlock": "tp_archive_read", "unlock_text": "성산 대신전의 기록실을 읽은 뒤에 열람할 수 있다. (금서)",
		"desc": "창립자가 금서로 묶은 마지막 불. 불사조는 제 재 속에서 자기 자신을 이겨야 다시 날아오른다. 담당: 그레타(사서) · 교장 서명.",
		"steps": [
			"도서관의 그레타에게 금서 열람 부탁하기",
			"교장실의 아스트리드 교장에게 서명 받기",
			"재의 서고(금서 구역 안쪽): 촛불을 이어 밝히며 끝까지",
			"불사조의 둥지: 알의 불 지키기",
			"불 속의 나",
		],
		"talk": [[0, "greta", "cls_phoenix_lesson"], [1, "astrid", "cls_phoenix_sign"]],
		"reward": {"stones": 2},
	},
}
