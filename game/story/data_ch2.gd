extends RefCounted
## 2장 데이터 — ChapterRegistry가 합친다 (docs/systems2.md 1절).
## 형식 (모든 data_<장>.gd 공통 — 자세히: docs/dev/story.md "데이터 형식"):
##   CHAPTER    장 정보 {n, title, tails_at_end, last, areas, warps, credits} (ChapterRegistry 머리 주석)
##   SCRIPTS    대본 파일 경로 — Story가 이 순서로 읽는다
##   CHARACTERS 인물 ID → {name, color, voice, 몸 그림 값(robe·hair…), draw·portrait(전용 그림 경로)}
##   ROOMS      이 장의 방 ID (지도·검사용)
##   OBJECTIVES [완료 플래그, HUD 문구, 필요 조건(Cond 식, ""=항상)] — 위에서부터 "조건 참·완료 아직"인 첫 줄이 현재 목표
##   QUESTS     ID → {title, giver, kind(side·class·main), chapter, need(Cond 식), desc, steps[문구…],
##              talk[[단계, 인물, 대본 ID]…], reward{stones, potion_slot, heart, feather, text}}
##              수업(kind = "class")은 + spell(마법 ID), unlock(Cond 식), unlock_text

## 장 정보 (ChapterRegistry 머리 주석의 CHAPTER 설명)
const CHAPTER := {
	"n": 2,
	"title": ["2장", "제국의 검"],
	"tails_at_end": 2,
	"areas": {"kingdom": "황도 아르덴"},
	"warps": [["kingdom", "k_embassy", "warp", "아르덴 제국 — 공관", "warp_kingdom"]],
	"credits": [
		"# 아르덴 제국",
		"제국제일검 레오니 발렌하르트",
		"은사자 기사단 카엘 · 빵집의 미아 · 대장장이 브론",
		"",
	],
}

## 대본 파일 (Story가 이 순서로 읽는다). 장면(지역)마다 한 파일, 장 공용 도우미는 story/ch2/common.gd(목록에 넣지 않음),
## 시험용 dev_ 대본은 story/dev/. 웹 내보내기에서 폴더 나열을 믿을 수 없어 하나하나 적는다
const SCRIPTS := [
	"res://story/ch2/school.gd",
	"res://story/ch2/market.gd",
	"res://story/ch2/city.gd",
	"res://story/ch2/duel.gd",
	"res://story/ch2/people.gd",
	"res://story/ch2/school_npc.gd",
	"res://story/dev/ch2.gd",
]

## 인물: data_ch1.gd CHARACTERS와 같은 키 (+ 전용 그림 "draw"·"portrait")
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
	"k_clockmaker": {
		"name": "시계공 오토", "color": Color("#e8c890"), "voice": 0.8,
		"robe": Color("#4a3a2a"), "robe2": Color("#c8a040"), "skin": Color("#ecc8b0"), "hair": Color("#c8c0b8"),
		"hair_style": "short", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#3a3020"), "height": 33, "extra": ["glasses", "apron"],
	},
	"k_cultist": {
		"name": "별 신도", "color": Color("#b090e8"), "voice": 0.92,
		"robe": Color("#1e1838"), "robe2": Color("#c89aff"), "skin": Color("#d8c8d0"), "hair": Color("#1e1838"),
		"hair_style": "long", "hat": "none", "hat_col": Color("#000000"), "eye": Color("#c89aff"), "height": 34, "extra": ["stars"],
	},
}

## 이 장의 방 ID (지도·검사용) — tools/rooms/ch2.py (docs/chapter2.md 7.1절)
const ROOMS := [
	"k_embassy", "k_gate_street", "k_market", "k_bakery", "k_smithy", "k_market_alley",
	"k_knights_yard", "k_barracks", "k_walls",
	"k_roof_1", "k_roof_2", "k_roof_3", "k_roof_4",
	"k_clock_street", "k_gearworks", "k_clocktower",
	"k_cathedral", "k_crypt",
	"k_sewer_1", "k_sewer_2", "k_sewer_3", "k_sewer_4", "k_sewer_5", "k_cult_den",
	"k_colosseum", "k_arena",
	"k_noble", "k_palace_gate", "k_palace_plaza",
	"k_oldquarter_1", "k_oldquarter_2", "k_oldquarter_3", "k_crater",
]

## 메인 목표 줄: [완료 플래그, 표시 문구, 필요 조건] (docs/chapter2.md 7.3절)
const OBJECTIVES := [
	["k_breakfast", "식당에서 아침을 먹자 (동관 복도 → 아래층)", "ch1_done"],
	["ab_wings", "중앙 홀 수업 게시판에서 '불꽃 날개' 수업을 듣자", "k_breakfast"],
	["k_envoy_seen", "교장 선생님이 부르신다 — 시계탑 꼭대기 교장실로", "ab_wings"],
	["k_departed", "앞마당 전이진 앞에서 모두와 만나자", "k_envoy_seen"],
	["k_met_leonie", "황도 아르덴 — 시장을 지나 동쪽 기사단 연무장으로", "k_departed"],
	["k_spar_done", "기사단 연무장에서 레오니와 대련하자", "k_met_leonie"],
	["k_walls_talk", "연무장 오른쪽 계단으로 성벽 위에 오르자", "k_spar_done"],
	["k_clock_arrived", "성벽 서쪽 끝에서 지붕을 건너 시계 구역으로 (굴뚝 열기는 날개로)", "k_walls_talk"],
	["k_gears_done", "태엽 공방의 톱니 시계 셋을 맞추자 (답은 대성당 종)", "k_clock_arrived"],
	["k_tower_top", "시계탑 꼭대기로 — 짐승의 흔적을 쫓자", "k_gears_done"],
	["k_crypt_seen", "대성당 지하 묘지로 (대성당 오른쪽 계단)", "k_tower_top"],
	["ab_ward", "학교 실습장의 엠버린 교수에게 '불꽃 방벽'을 배우자 (공관 전이진 → 수업 게시판)", "k_crypt_seen"],
	["k_crypt_open", "지하 묘지의 별 수정 장벽 — 날아오는 별 조각을 방벽으로 되쏘자", "ab_ward"],
	["k_noxis_fled", "하수도 깊은 곳 — 별 신도의 은신처를 찾자 (수문 밸브로 물길을 열며)", "k_crypt_open"],
	["k_duel_done", "밤 — 시계탑 꼭대기 다리를 건너 황궁 광장으로", "k_duel_called"],
	["k_beast_down", "레오니와 함께 옛 성곽 지구 — 별이 떨어진 자리로", "k_duel_done"],
]

## 퀘스트 (docs/systems2.md 4절 · docs/chapter2.md 6절·7.4절). 진행은 각 인물의 npc_ 대본이 직접 처리한다.
const QUESTS := {
	"k_mia_bread": {
		"title": "미아의 빵 배달", "giver": "mia", "kind": "side", "chapter": 2, "need": "k_met_leonie",
		"desc": "갓 구운 빵을 세 곳에 배달하자. 미아는 레오니 단장님의 열성 팬이다.",
		"steps": ["빵 배달 (0/3): 연무장의 카엘 · 대장간의 브론 · 대성당의 사제", "빵 배달 (1/3)", "빵 배달 (2/3)", "빵집의 미아에게 돌아가기"],
		"reward": {"stones": 1, "text": "레오니의 옛이야기"},
	},
	"k_bron_ore": {
		"title": "별철 조각", "giver": "bron", "kind": "side", "chapter": 2, "need": "k_spar_done",
		"desc": "브론이 별이 떨어진 밤의 쇠 — 별철을 찾는다. 하수도 수로 어딘가에 가라앉아 있다는 소문.",
		"steps": ["하수도 수로에서 별철 조각 찾기 (물을 빼야 할지도)", "대장간의 브론에게 가져가기"],
		"reward": {"potion_slot": 1, "text": "레오니의 새 검 (브론이 벼림)"},
	},
	"k_kael_helmet": {
		"title": "카엘의 투구", "giver": "kael", "kind": "side", "chapter": 2, "need": "k_walls_talk",
		"desc": "카엘이 지붕 순찰 중에 가고일에게 투구를 빼앗겼다. 풍향계 근처에 걸려 있다는데…",
		"steps": ["지붕 위(풍향계)에서 카엘의 투구 찾기 — 굴뚝 열기를 타고", "연무장의 카엘에게 돌려주기"],
		"reward": {"stones": 1},
	},
	"k_arena": {
		"title": "투기장 챔피언", "giver": "k_arena_master", "kind": "side", "chapter": 2, "need": "k_spar_done",
		"desc": "투기장 지배인이 새 도전자를 찾는다. 챔피언 '그물의 가론'을 이기면 수호의 깃털을 준다.",
		"steps": ["투기장 바닥에서 챔피언 가론과 겨루기", "지배인에게 보고하기"],
		"reward": {"feather": 1, "text": "수호의 깃털"},
	},
	"k_isolde_race": {
		"title": "지붕 경주", "giver": "isolde", "kind": "side", "chapter": 2, "need": "k_clock_arrived",
		"desc": "이졸데가 지붕 경주를 걸어왔다. 굴뚝 숲(지붕1)에서 출발해 시계 거리 지붕(지붕4)까지, 2분 안에.",
		"steps": ["지붕1(굴뚝 숲)에서 이졸데에게 말 걸어 출발", "2분 안에 지붕4(시계 거리)까지!"],
		"reward": {"stones": 2, "text": "이졸데가 처음으로 이름을 불렀다"},
	},
	"k_spice": {
		"title": "별향신료", "giver": "butterworth", "kind": "side", "chapter": 2, "need": "k_departed",
		"desc": "버터워스 아주머니가 제국 시장의 별향신료로 학교 저녁을 만들고 싶어 한다.",
		"steps": ["제국 시장의 향신료 상인에게서 별향신료 받기", "학교 식당의 버터워스 아주머니에게 가져가기"],
		"reward": {"heart": 1, "text": "별향신료 스튜 (최대 체력 +1)"},
	},
	"k_greta_books": {
		"title": "연체 도서 회수", "giver": "greta", "kind": "side", "chapter": 2, "need": "k_departed",
		"desc": "제국으로 빌려 간 학교 도서관 책 세 권이 몇 년째 돌아오지 않았다. 그레타는 화가 났다(겉으로는 모름).",
		"steps": ["제국에 흩어진 연체 도서 찾기 (0/3)", "연체 도서 찾기 (1/3)", "연체 도서 찾기 (2/3)", "도서관의 그레타에게 돌려주기"],
		"reward": {"stones": 2},
	},
}
