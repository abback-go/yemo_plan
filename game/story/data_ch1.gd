extends RefCounted
## 1장 데이터 — 신계(프롤로그)·마녀학교 (docs/chapter1.md). ChapterRegistry가 다른 장과 똑같이 합친다.
## 형식은 다른 data_<장>.gd와 같다 (docs/dev/story.md "데이터 형식").

## 장 정보 (ChapterRegistry 머리 주석의 CHAPTER 설명)
const CHAPTER := {
	"n": 1,
	"title": ["1장", "폐급 마녀와 여우신"],
	"areas": {"shingye": "신계", "school": "마녀학교"},
	"warps": [["school", "s_courtyard", "warp", "마녀학교 — 앞마당", ""]],
	"credits": [
		"# 세라피나",
		"폐급이라 불리던 불의 마녀",
		"",
		"# 너울",
		"동방 신계의 여우신 · 아홉 꼬리",
		"",
		"# 마녀학교",
		"아스트리드 녹턴 교장 · 엠버린 애시그로브 교수",
		"오필리아 페더웰 교수 · 베로니카 손 교수",
		"피피 시슬윅 · 이졸데 폰 크레스트",
		"그레타 잉크웰과 호두 · 미라벨 · 버터워스 아주머니",
		"",
	],
}

## 대본 파일 (Story가 이 순서로 읽는다. 같은 대본 ID가 두 파일에 있으면 앞 파일이 이기고 오류를 남김)
const SCRIPTS := [
	"res://story/ch1/prologue.gd",
	"res://story/ch1/school_morning.gd",
	"res://story/ch1/school_library.gd",
	"res://story/ch1/school_seal.gd",
	"res://story/ch1/npc.gd",
]

## 등장인물: 이름, 이름 색, 목소리(대화 삑삑음 높이), 작은 몸 그림 값, 초상화 값 (docs/chapter1.md 6절).
## 몸 그림 값 (CharacterVisual): robe 옷색, robe2 옷 강조색, skin, hair, hair_style(long·bun·twin·short·tied·bob·none),
## hat(witch·witch_small·nurse·none·hood·veil), hat_col, eye, height(몸 높이 px), extra(glasses·goggles·ribbon·owl·apron·feather·gloves·stars·ladle)
## 전용 그림: "draw"·"portrait" (스크립트 경로). 뒤 장에 같은 ID가 있으면 키 단위로 덮어씀 (Characters.info).
const CHARACTERS := {
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

## 이 장의 방 ID (지도·검사용)
const ROOMS := [
	# 신계 (프롤로그)
	"t_pass", "t_forest", "t_stairs", "t_trial", "t_throne", "t_collapse", "t_gate",
	# 마녀학교
	"s_infirmary", "s_dorm", "s_eastcorr", "s_hall", "s_westcorr", "s_class", "s_training",
	"s_nonelem", "s_levcourse", "s_library", "s_stacks", "s_archive", "s_gallery", "s_advclass",
	"s_clock", "s_headmaster", "s_courtyard", "s_greenhouse", "s_cafeteria", "s_alchemy",
	"s_cellar", "s_sealcorr", "s_sealroom",
]

## 메인 목표 줄: [완료 플래그, 표시 문구, 필요 조건(Cond 식, 비우면 항상)]
## 위에서부터 "필요 조건은 참이고 완료 플래그는 아직인" 첫 줄이 HUD 현재 목표 (Objectives.current)
const OBJECTIVES := [
	["t_trial_done", "신계 깊은 곳의 보물을 찾아라", ""],
	["t_escaped", "무너지는 신계에서 빠져나가라", "t_trial_done"],
	["met_emberlyn", "마법반 실습에 가자 (서관 1층)", "s_woke"],
	["ab_storm", "실습장에서 과제를 마치자", "met_emberlyn"],
	["key_stolen", "도서관에서 봉인 기록을 찾자 (중앙 홀 2층)", "ab_storm"],
	["ab_double_jump", "비속성마법반에서 부양을 배우자 (서관 복도 아래층)", "key_stolen"],
	["key_recovered", "서가 미로에서 마도서를 쫓아라", "ab_double_jump"],
	["ab_fox_window", "금서 구역에서 봉인 기록을 읽자", "key_recovered"],
	["adv_done", "서가 미로 꼭대기 오른쪽 벽에 여우창문(D) → 고급마법반으로", "ab_fox_window"],
	["met_astrid", "시계탑 꼭대기의 교장실로", "adv_done"],
	["s_cellar_seen", "앞마당의 지하 철문으로 내려가자", "met_astrid"],
	["seal_open", "봉인 회랑의 촛대를 순서대로 밝히자", "s_cellar_seen"],
	["agwi_defeated", "봉인의 방으로", "seal_open"],
	["chapter_end", "기숙사로 돌아가 쉬자", "agwi_defeated"],
]
