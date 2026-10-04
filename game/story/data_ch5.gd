extends RefCounted
## 5장 데이터 — ChapterRegistry가 합친다 (docs/systems2.md 1절).
## 인물 그림 · 방 목록 · 메인 목표 줄 · 퀘스트 (설계와 실제: docs/chapter5.md 7절 이후).

## 장 정보 (ChapterRegistry 머리 주석의 CHAPTER 설명)
const CHAPTER := {
	"n": 5,
	"title": ["5장", "별의 마녀"],
	"last": true,
	"areas": {"star": "별의 탑", "vision": "같은 시각"},
	"credits": [
		"# 별의 마녀",
		"리라",
		"",
	],
}

## 대본 파일 (Story가 이 순서로 읽는다)
const SCRIPTS := [
	"res://story/scripts_ch5.gd",
]

## 인물: data_ch1.gd CHARACTERS와 같은 키 (+ 전용 그림 "draw"·"portrait"). 같은 ID면 키를 덮어씀.
##   lyra       별의 마녀 (새 인물). 일반 그림 키는 전용 그림이 없을 때를 위한 대비값.
##   astrid     1장 DB 항목(이름·색·목소리)은 그대로 두고 전용 그림만 덧붙임 → 1장부터 새 그림으로 보인다.
##   neoul_god  너울 본모습의 초상화만 새로 (몸은 컷신 actor·5장 각성 장치가 그림)
const CHARACTERS := {
	"lyra": {
		"name": "리라", "color": Color("#ffe7a0"), "voice": 0.95,
		"robe": Color("#1c2256"), "robe2": Color("#ecd28a"), "skin": Color("#f8e8e2"), "hair": Color("#e7eaf8"),
		"hair_style": "long", "hat": "witch", "hat_col": Color("#181c4a"), "eye": Color("#a070e8"), "height": 40, "extra": ["stars"],
		"draw": "res://characters/special/lyra_draw.gd",
		"portrait": "res://characters/special/lyra_portrait.gd",
	},
	"astrid": {
		"draw": "res://characters/special/astrid_draw.gd",
		"portrait": "res://characters/special/astrid_portrait.gd",
	},
	"neoul_god": {
		"portrait": "res://characters/special/neoul_portrait.gd",
	},
}

## 이 장의 방 ID (지도·검사용). st_ = 별의 탑 영역 + 학교 영역의 축제 광장·다시 세우는 안뜰, r5_ = 침공으로 무너진 학교,
## r5_vision_* = 통신이 울릴 때 잠깐 보여 주는 같은 시각의 제국·세계수·대신전 (영역 "vision", 장면 전용)
const ROOMS := [
	"st_festival", "st_rebuild",
	"st_crossroads", "st_trial_k1", "st_trial_k", "st_trial_e1", "st_trial_e", "st_trial_tp1", "st_trial_tp", "st_trial_s1", "st_trial_s",
	"st_tower_1", "st_tower_2", "st_tower_3", "st_tower_4", "st_tower_4r", "st_tower_5", "st_tower_top",
	"r5_clock", "r5_hall", "r5_westcorr", "r5_library", "r5_dorm", "r5_courtyard",
	"r5_vision_k", "r5_vision_e", "r5_vision_tp",
	"st_void", "r5_courtyard_rise", "st_colossus_1", "st_colossus_2", "st_colossus_3", "st_sky_1", "st_skygate",
]

## 메인 목표 줄: [완료 플래그, 표시 문구, 필요 플래그] — 위에서부터 "필요는 섰고 완료는 아직"인 첫 줄
const OBJECTIVES := [
	["st_fest_seen", "축제 날이다! 앞마당 오른쪽 끝의 축제 광장에 가 보자", "st_fest"],
	["st_fest_ready", "교장 선생님께 축제 초대장을 전하자 (시계탑 꼭대기 교장실)", "st_fest_seen"],
	["st_lyra_came", "축제를 즐기자 — 준비가 되면 광장 무대로 (불사조 금서: 도서관의 그레타)", "st_fest_ready"],
	["st_tower_open", "별의 열쇠 넷을 모으자 — 앞마당의 별의 문 (제국·세계수·대신전·별의 정원)", "st_lyra_came"],
	["st_lyra_beaten", "별의 탑 꼭대기로 — 별의 문간 가운데 계단", "st_tower_open"],
	["st_escort", "무너진 학교: 아래로 내려가 사람들을 찾자", "st_invaded"],
	["st_dorm_seen", "학생들을 데리고 기숙사 대피소로 (서관 → 도서관)", "st_escort"],
	["st_fallen", "앞마당으로 — 교장 선생님이 결계를 친다", "st_dorm_seen"],
	["st_launch", "거신 위를 달려 올라라 — 가장 큰 거신의 머리로", "st_void_done"],
	["st_gate_done", "하늘의 문 — 리라를 되찾아라", "st_launch"],
	["st_tea_done", "다시 세우는 안뜰: 차 탁자의 리라와 교장 선생님에게", "st_epilogue"],
	["ch5_after", "모든 이야기가 끝났다 — 학교를 다시 세우는 일을 돕자 (엠버린 교수)", "ch5_done"],
]

## 퀘스트 (docs/systems2.md 4절, docs/chapter5.md 6절). need = 받을 수 있는 때(인물 머리 위 "!")
const QUESTS := {
	"st_pippa_stall": {
		"title": "피피의 축제 물약 가게", "giver": "pippa", "kind": "side", "chapter": 5, "need": "st_fest,!st_lyra_came",
		"desc": "축제 한정 '별사탕 물약'을 만들 재료가 모자란다. 학교 곳곳에서 재료 셋을 모아 피피에게.",
		"steps": ["재료 셋을 모아 축제 광장의 피피에게 (식당 · 유리 온실 · 시계탑 톱니 사이)"],
		"reward": {"potion_slot": 1},
	},
	"st_cook_off": {
		"title": "버터워스의 요리 대회", "giver": "butterworth", "kind": "side", "chapter": 5, "need": "st_fest,!st_lyra_came",
		"desc": "축제 요리 대회 심사위원. 제국 소시지, 엘프 꿀빵, 신전 성찬 빵을 맛보고 버터워스에게 결과를 전하자.",
		"steps": ["축제 가게 셋 맛보기 (레오니 · 엘라리엔 · 아우렐리아)", "버터워스에게 심사 결과 전하기"],
		"reward": {"heart": 1},
	},
	"st_isolde_dance": {
		"title": "이졸데의 무도회 연습", "giver": "isolde", "kind": "side", "chapter": 5, "need": "st_fest,!st_lyra_came",
		"desc": "저녁 무도회의 연습 상대. 박자는 셋.",
		"steps": ["이졸데와 춤 연습"],
		"reward": {"stones": 1},
	},
	"st_ophelia_stars": {
		"title": "오필리아의 별 관측", "giver": "ophelia", "kind": "side", "chapter": 5, "need": "st_fest,!st_lyra_came",
		"desc": "축제 광장 오른쪽 비계 위 별 관측대. 오필리아 교수와 너울과 함께 별을 본다.",
		"steps": ["별 관측대에서 오필리아 교수와 별 보기"],
		"reward": {"stones": 1},
	},
	"st_hodu_letters": {
		"title": "호두의 축제 초대장", "giver": "hodu", "kind": "side", "chapter": 5, "need": "st_fest,!st_lyra_came",
		"desc": "부엉이 호두가 맡은 초대장 여섯 장. 학교 사람들에게 전하자.",
		"steps": ["초대장 여섯 장 전하기 (미라벨 · 그레타 · 베로니카 · 오필리아 · 엠버린 · 버터워스)", "호두에게 돌아가기"],
		"reward": {"stones": 1},
	},
	"st_rebuild": {
		"title": "다시 세우는 학교", "giver": "emberlyn", "kind": "side", "chapter": 5, "need": "st_epilogue",
		"desc": "무너진 학교를 다 같이 다시 세운다. 일손이 필요한 여섯 사람을 돕자.",
		"steps": ["다시 세우는 안뜰의 여섯 사람 돕기 (피피 · 버터워스 · 호두 · 이졸데 · 레오니 · 엘라리엔)", "엠버린 교수에게 돌아가기"],
		"reward": {"text": "엔딩 사진"},
	},
}
