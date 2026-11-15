## game_data.gd — 수치·카드·적·화면 배치·연출 시간을 모두 모아 둔 파일.
## 대사·안내 상자·선택지·장면 문구는 data/script_data.gd (대본) 에 따로 있다.
## 두 파일만 고쳐도(에디터의 스크립트 편집기에서) 코드 수정 없이 조정할 수 있다.
## HTML 프로토타입 prototype/js/data.js 를 옮기고, 탐색(갈림길·이벤트·지도)·2층 전투·빈 캠프를 더했다.
##
## 표기: 수치는 combat-system.md / tutorial-flow.md 의 임시값. [제안] 표시는 문서의 [제안] 항목을 문서대로 넣은 것.
## 주의: 사전 키는 모두 "문자열" 로 쓴다(코드가 문자열로 찾는다).
class_name GameData
extends Object

const D := {
	# ───────────── 기본 규칙 (combat-system.md 2장) ─────────────
	"rules": {
		"energyPerTurn": 3,
		"drawPerTurn": 5,          # 죽음 카드(보존)가 손에 있으면 그 장수만큼 덜 뽑는다 (튜토리얼은 1층부터 4장)
		"retainPos": "right",      # 보존 카드(죽음 카드) 자리: right(맨 오른쪽, 대본 v0.5) | middle(HTML 판)
		"deathLockRuns": 1,        # 이 회차까지는 죽음 카드의 잠금(lockedUntil)이 걸린다. 2회차부터 미리 낼 수 있게 하려면 1 그대로, 잠그려면 99
		"maxHand": 10,             # 손패 상한 (넘치면 더 뽑지 않음)
		"guardRound": "floor",     # 감싸기 '절반' 반올림: floor | ceil
		"downedReviveHp": 1,       # 전투 후 쓰러진 동료가 복귀하는 HP
		# 적이 대상을 고를 때 가중치 (스크립트 예고가 없는 턴)
		"targetWeights": {"witch": 1, "hero": 1, "warrior": 1, "archer": 1},
	},

	# ───────────── 캐릭터 (3장) ─────────────
	"party": {
		"witch": {"hp": 15},     # 이름은 대본(script_data.gd "names")
		"order": ["archer", "hero", "warrior"],   # 화면 왼쪽 → 오른쪽
		"allies": {
			"hero": {"hp": 30},      # 용사 세라피나
			"warrior": {"hp": 24},   # 전사 브룬힐드
			"archer": {"hp": 12},    # 궁수 엘리안
		},
	},

	# ───────────── 카드 (6장) ─────────────
	# kind: witch | ally | death | inherit | relic | wound
	# target: enemy(적 1명) | intent(예고 1개) | none(대상 없음)
	# text 안의 {dmg} {all} {draw} {self} {weaken} {div} 는 effects 수치로 자동 치환된다.
	"cards": {
		"curse_flame": {"name": "저주의 불꽃", "kind": "witch", "owner": "witch", "cost": 1, "target": "enemy", "art": "flame",
			"effects": [{"type": "damage", "amount": 6}], "text": "적 1명에게 {dmg} 피해"},
		"fate_shift": {"name": "운명 전가", "kind": "witch", "owner": "witch", "cost": 1, "target": "intent", "art": "fate",
			"effects": [{"type": "redirect", "to": "choose"}], "text": "예고된 공격 1개의 대상을 다른 아군으로 바꾼다"},
		"take_hit": {"name": "대신 받기", "kind": "witch", "owner": "witch", "cost": 0, "target": "intent", "art": "hand",
			"effects": [{"type": "redirect", "to": "witch"}], "text": "예고된 공격 1개를 노엘이 대신 받는다"},
		"foresight": {"name": "죽음의 예지", "kind": "witch", "owner": "witch", "cost": 1, "target": "none", "art": "eye",
			"effects": [{"type": "draw", "count": 2}], "text": "카드 {draw}장을 뽑는다"},

		"holy_slash": {"name": "성검 베기", "kind": "ally", "owner": "hero", "cost": 1, "target": "enemy", "art": "sword",
			"effects": [{"type": "damage", "amount": 14}], "text": "적 1명에게 {dmg} 피해"},
		"vanguard": {"name": "선봉", "kind": "ally", "owner": "hero", "cost": 1, "target": "none", "art": "charge",
			"effects": [{"type": "damageAll", "amount": 6}], "text": "모든 적에게 {all} 피해"},

		"cover": {"name": "감싸기", "kind": "ally", "owner": "warrior", "cost": 1, "target": "intent", "art": "shield",
			"effects": [{"type": "redirect", "to": "warrior", "div": 2}], "text": "예고된 공격 1개를 브룬힐드가 받되 피해 {div}"},
		"shield_bash": {"name": "방패 강타", "kind": "ally", "owner": "warrior", "cost": 1, "target": "enemy", "art": "bash",
			"effects": [{"type": "damage", "amount": 6}], "text": "적 1명에게 {dmg} 피해"},

		"snipe": {"name": "저격", "kind": "ally", "owner": "archer", "cost": 1, "target": "enemy", "art": "arrow",
			"effects": [{"type": "damage", "amount": 8}], "text": "적 1명에게 {dmg} 피해"},
		"suppress": {"name": "견제 사격", "kind": "ally", "owner": "archer", "cost": 1, "target": "enemy", "art": "arrows",
			"effects": [{"type": "damage", "amount": 3}, {"type": "weaken", "amount": 4}], "text": "적 1명에게 {dmg} 피해 + 그 적의 이번 공격 피해 -{weaken}"},

		# 죽음 카드 (6.3) — 비용 0, 손패 보존, 사용 시 용사 사망 → 유품 변환 → 짓밟힘 획득
		"hero_death": {"name": "용사의 죽음", "kind": "death", "ally": "hero", "owner": "witch", "cost": 0, "target": "none", "art": "deathface",
			"retain": true, "exhaust": true,
			# 1회차에는 거대 존재 전투(전투 종류 "giant") 1턴 시작까지 잠겨 낼 수 없다 (대본 v0.5 1.1)
			"lockedUntil": "giant",
			"effects": [
				{"type": "killAlly", "ally": "hero"},
				{"type": "relicize", "ally": "hero"},
				{"type": "addCard", "card": "trample", "permanent": true, "freeThisTurn": true, "at": "source"},
			],
			"text": "세라피나는 이곳에서 짓밟혀 죽는다.\n내면, 지금 일어난다.",
			"tags": ["보존", "사용 시 짓밟힘 획득"]},

		# 상속 카드
		"trample": {"name": "짓밟힘", "kind": "inherit", "owner": "witch", "from": "hero", "cost": 2, "target": "none", "art": "foot",
			"effects": [{"type": "damageAll", "amount": 15}], "text": "모든 적에게 {all} 피해\n획득한 턴에는 비용 0",
			"tags": ["상속"]},

		# 유품 카드 (용사)
		"broken_sword": {"name": "부러진 성검", "kind": "relic", "owner": "hero", "cost": 1, "target": "enemy", "art": "brokensword",
			"effects": [{"type": "damage", "amount": 20}, {"type": "selfDamage", "amount": 3}], "text": "적 1명에게 {dmg} 피해\n노엘 HP -{self}"},
		"last_charge": {"name": "용사의 마지막 돌격", "kind": "relic", "owner": "hero", "cost": 1, "target": "none", "art": "lastcharge",
			"effects": [{"type": "damageAll", "amount": 9}, {"type": "selfDamage", "amount": 2}], "text": "모든 적에게 {all} 피해\n노엘 HP -{self}"},
		# 유품 카드 (궁수, 참고용 — 튜토리얼에서는 나오지 않음)
		"archer_arrow": {"name": "궁수의 화살", "kind": "relic", "owner": "archer", "cost": 1, "target": "enemy", "art": "arrow",
			"effects": [{"type": "damage", "amount": 12}, {"type": "selfDamage", "amount": 2}], "text": "적 1명에게 {dmg} 피해\n노엘 HP -{self}"},
		"archer_last_suppress": {"name": "궁수의 마지막 견제", "kind": "relic", "owner": "archer", "cost": 1, "target": "enemy", "art": "arrows",
			"effects": [{"type": "damage", "amount": 4}, {"type": "weaken", "amount": 6}, {"type": "selfDamage", "amount": 1}],
			"text": "적 1명에게 {dmg} 피해 + 이번 공격 피해 -{weaken}\n노엘 HP -{self}"},

		# 상처 카드 (5장)
		"wound": {"name": "상처", "kind": "wound", "owner": "", "cost": 0, "target": "none", "art": "wound", "unplayable": true,
			"effects": [], "text": "낼 수 없다. 손패만 차지한다."},
	},

	# 동료가 죽으면 그 동료의 카드가 이것으로 바뀐다 (강화 표시는 사라진다)
	"relicMap": {
		"holy_slash": "broken_sword",
		"vanguard": "last_charge",
		"snipe": "archer_arrow",
		"suppress": "archer_last_suppress",
	},

	# 튜토리얼 시작 덱 15장 (6.2)
	"startingDeck": [
		["curse_flame", 2], ["fate_shift", 2], ["take_hit", 1], ["foresight", 1],
		["holy_slash", 2], ["vanguard", 1],
		["cover", 2], ["shield_bash", 1],
		["snipe", 2], ["suppress", 1],
	],

	# 노엘이 처음부터 쥐고 있는 죽음 카드 (사흘 전부터 비친 세라피나의 죽음 — 대본 1장)
	"startingDeathCards": ["hero_death"],

	# ───────────── 훈련: 카드 강화 (tutorial-flow.md 2.3) [제안] ─────────────
	# 후보 4종 중 무작위 3장을 보여 주고 1장 선택. 덱에서 그 카드 1장만 강화된다(이름 옆 +).
	"upgrades": {
		"holy_slash": {"effects": [{"type": "damage", "amount": 18}], "summary": "피해 14 → 18"},
		"snipe": {"effects": [{"type": "damage", "amount": 11}], "summary": "피해 8 → 11"},
		"cover": {"effects": [{"type": "redirect", "to": "warrior", "div": 3}], "summary": "받는 피해 1/2 → 1/3"},
		"curse_flame": {"effects": [{"type": "damage", "amount": 9}], "summary": "피해 6 → 9"},
	},
	"trainChoices": 3,

	# ───────────── 휴식 (tutorial-flow.md 2.2) [제안 수치] ─────────────
	"rest": {"allyMaxHp": 3, "witchMaxHp": 2, "healAll": true},

	# ───────────── 적 ─────────────
	"enemies": {
		"cultist": {"name": "광신도", "hp": 14, "sprite": "spr_cultist.png"},
		"giant": {"name": "거대한 존재", "hp": null, "immune": true, "retreatOn": "trample", "sprite": "spr_giant_foot.png"},
	},

	# ───────────── 전투 (7장 + tutorial-flow.md) ─────────────
	"encounters": {
		# 1층 일반 전투: 광신도 3명. 완전히 끝나는 전투(거대 존재 없음) [tutorial-flow 2]
		"normal": {
			"kind": "normal", "floor": 1,
			"enemies": [{"id": "c1", "type": "cultist", "slot": 0}, {"id": "c2", "type": "cultist", "slot": 1}, {"id": "c3", "type": "cultist", "slot": 2}],
			"attackRange": [5, 6],            # 광신도 공격 5~6
			"giantTriggerAlive": null,        # null = 거대 존재가 나오지 않는다
			# 튜토리얼 각 턴의 예고 (없으면 무작위)
			"scriptedIntents": {
				1: {"c1": {"value": 5, "target": "warrior"}, "c2": {"value": 6, "target": "hero"}, "c3": {"value": 5, "target": "archer"}},
				2: {"c1": {"value": 6, "target": "archer"}, "c2": {"value": 6, "target": "archer"}, "c3": {"value": 6, "target": "archer"}},
			},
			# 튜토리얼 각 턴의 손패 (덱에 있으면 그 카드를 뽑는다. 없으면 무작위)
			"scriptedHands": {
				# 죽음 카드 1장 + 새로 뽑는 4장 (대본 v0.5 2장)
				1: ["holy_slash", "curse_flame", "shield_bash", "take_hit"],
				2: ["fate_shift", "cover", "snipe", "holy_slash"],
			},
		},
		# 2층 전투: 광신도 2 → 1명 남으면 발이 내려와 짓밟음 → 거대 존재 전투
		"floor2": {
			"kind": "normal", "floor": 2,
			"enemies": [{"id": "c1", "type": "cultist", "slot": 0}, {"id": "c3", "type": "cultist", "slot": 2}],
			"attackRange": [5, 6],
			"giantTriggerAlive": 1,
			"scriptedIntents": {
				1: {"c1": {"value": 6, "target": "archer"}, "c3": {"value": 5, "target": "warrior"}},
			},
			"scriptedHands": {},
		},
		"giant": {
			"kind": "giant", "floor": 2,
			"enemies": [{"id": "giant", "type": "giant", "slot": "giant"}],
			# 3턴 카운트다운 (마지막 항목이 계속 반복)
			"countdown": [
				{"kind": "shadow", "label": "그림자", "detail": "행동 없음"},
				{"kind": "aoe", "label": "기둥 붕괴", "value": 5, "hitsWitch": true, "detail": "아군 전원"},
				{"kind": "stomp", "label": "짓밟기", "detail": "전원 사망", "lethal": true},
			],
			# 죽음 카드는 1층부터 손패에 있다(startingDeathCards). 이 전투 1턴 시작에 잠금이 풀린다(lockedUntil)
		},
	},

	# ───────────── 비주얼노벨 장면(캠프·이벤트·빈 캠프)의 배경 ─────────────
	# 대사는 script_data.gd. bgZoom: 배경 그림의 한 곳(focus)을 scale 배로 확대해 보여 준다(같은 그림 재사용)
	# emptyBedroll: 빈 캠프에서 비어 있는 침낭 자리(1920×1080 기준) — 코드로 차가운 빛·그늘을 얹는다
	"vnScenes": {
		"camp": {"bg": "bg_camp.png", "fire": true},
		"corpse": {"bg": "ev_corpse_witch.png"},
		"rest": {"bg": "bg_fork_crypt.png", "bgZoom": {"scale": 1.6, "focus": [960, 430]}, "fire": true},
		"train": {"bg": "bg_fork_crypt.png", "bgZoom": {"scale": 1.55, "focus": [1560, 470]}},
		"stairs": {"bg": "bg_stairs_descent.png"},
		"emptycamp": {"bg": "bg_camp.png", "fire": true, "fireLow": true, "emptyBedroll": [1680, 690]},
	},
	# VN 캠프 등에서의 스탠딩 자리(가로 위치) / 높이 / 위쪽 y
	"vn": {"slots": {"FL": 250, "L": 600, "C": 960, "R": 1320, "FR": 1670}, "standH": 1010, "standTop": 120},

	# ───────────── 죽음 카드 암시 (캠프·계단·빈 캠프) ─────────────
	# 1인칭 오른손(ui_witch_hand_raise.png)이 아래에서 올라와 반투명한 카드를 쥐고, 동료 쪽 붉은 실이 잠깐 팽팽해진다.
	# clarity: 0(누군지 알아볼 수 없음) ~ 1(또렷함) — 대본: 캠프 흐릿, 계단 더 선명, 거대 존재 1턴 완전히 또렷(실제 카드)
	"omen": {"scale": 0.9, "x": 470, "y": 330, "from": [260, 560], "rise": 520, "fade": 600, "alpha": 0.75,
		"anchors": {"hero": [0.5, 0.33], "warrior": [0.5, 0.3], "archer": [0.5, 0.3], "noel": [0.5, 0.3]}},

	# ───────────── 탐색: 이동·갈림길 (tutorial-flow.md 2장, 목업 11) ─────────────
	"explore": {
		# 갈림길: 왼쪽=핏자국 통로(물음표) / 가운데=촛불 예배당(불꽃) / 오른쪽=무너진 훈련장(교차한 칼 = 훈련)
		# x,y: 아이콘 위치 / vp: 걸어 들어갈 때 다가가는 통로 안쪽 점 (1920×1080 기준)
		"fork": {
			"bg": "bg_fork_crypt.png", "floor": 1, "room": "fork",
			"paths": [
				{"id": "corpse", "icon": "question", "x": 360, "y": 330, "vp": [330, 450]},
				{"id": "rest", "icon": "flame", "x": 960, "y": 300, "vp": [960, 470]},
				{"id": "train", "icon": "swords", "x": 1560, "y": 330, "vp": [1560, 460]},
			],
		},
		# 계단 아래: 2층 전투로 (칼 = 전투, 대본 3.1)
		"stairs": {
			"bg": "bg_stairs_descent.png", "floor": 2, "room": "f2hall",
			"paths": [
				{"id": "battle", "icon": "sword", "x": 1290, "y": 560, "vp": [1330, 760]},
			],
		},
		# 동료 뒷모습(전투보다 작게, 앞서 걷는 자리): x(가운데), top(머리 위), h(그림 높이)
		"allies": {
			"archer": {"x": 420, "top": 560, "h": 640},
			"hero": {"x": 980, "top": 540, "h": 600},
			"warrior": {"x": 1480, "top": 560, "h": 680},
		},
		# 랜턴을 든 왼손 (ui_witch_hand_lantern.png 1672×941, 손잡이 고리 근처 pivot을 중심으로 흔들림)
		"lantern": {"img": "ui_witch_hand_lantern.png", "x": -60, "y": 340, "scale": 0.86, "pivot": [530, 300]},
		# 걸어 들어가는 연출
		"walk": {"duration": 2600, "zoom": 2.1, "steps": 5, "bob": 12, "sway": 5.0, "fadeAt": 0.72, "allyShrink": 0.32},
	},

	# ───────────── 지도 ─────────────
	# 왼쪽 가장자리의 세로 층 표시 + 열면 크게 보이는 층·방 지도. deathMark: 마녀만 보는 죽음 표식(장소 기한)
	"map": {
		# 층 이름·방 이름은 대본(script_data.gd "map")에 있다
		"floors": [
			{"n": 1},
			{"n": 2, "deathMark": true},   # 붉은 실 표식(누구의 것인지는 밝히지 않는다 — 대본 3.1)
			{"n": 3, "locked": true},
			{"n": 4, "locked": true},
		],
		# 방: floor, col(가로 칸), row(세로 칸, 갈림길 3갈래), icon
		"rooms": {
			"camp": {"floor": 1, "col": 0, "row": 1, "icon": "camp"},
			"hall": {"floor": 1, "col": 1, "row": 1, "icon": "sword"},
			"fork": {"floor": 1, "col": 2, "row": 1, "icon": "fork"},
			"corpse": {"floor": 1, "col": 3, "row": 0, "icon": "question"},
			"rest": {"floor": 1, "col": 3, "row": 1, "icon": "flame"},
			"train": {"floor": 1, "col": 3, "row": 2, "icon": "swords"},
			"stairs": {"floor": 1, "col": 4, "row": 1, "icon": "stairs"},
			"f2hall": {"floor": 2, "col": 0, "row": 1, "icon": "sword"},
			"f2deep": {"floor": 2, "col": 1, "row": 1, "icon": "question", "deathMark": true},
		},
		"links": [["camp", "hall"], ["hall", "fork"], ["fork", "corpse"], ["fork", "rest"], ["fork", "train"],
			["corpse", "stairs"], ["rest", "stairs"], ["train", "stairs"], ["stairs", "f2hall"], ["f2hall", "f2deep"]],
	},

	# ───────────── 용사 사망 컷신 (C1~C8) ─────────────
	# duration: 자동 진행까지의 시간(ms). 클릭하면 바로 다음 컷.
	"cutscene": {
		"cuts": [
			# 컷의 자막(대사)은 대본(script_data.gd "cutLines")에 있다
			{"id": "C1", "image": "cut_hero_reverse.png", "duration": 7400, "zoom": [1.0, 1.06]},   # 대사 3줄
			{"id": "C2", "image": "cut_hero_reach.png", "duration": 2600, "zoom": [1.04, 1.12]},
			{"id": "C3", "code": "impact", "duration": 3200},          # 흰 섬광 → 암전 → 강한 흔들림 → 피 튐(화면 위)
			{"id": "C4", "image": "cut_hero_crushed.png", "duration": 1600},
			# C5: C4 그림 자체를 움직인다 — 살짝 들렸다가(위로) 세게 내리찍기 + 확대 펄스 + 강한 흔들림 × slams, 마지막에 비트는 회전 흔들림.
			{"id": "C5", "code": "grind", "image": "cut_hero_crushed.png", "duration": 4400, "slams": 2, "lift": 46, "twistDeg": 2.2},
			{"id": "C6", "image": "cut_hero_aftermath.png", "duration": 3600, "zoom": [1.08, 1.0]},
		],
		# C5에서 피가 번지는 자리(화면 아래쪽 돌 틈, 1920×1080 기준) — 건틀릿 손 주변
		"pool": {"x0": 560, "x1": 1380, "y": 880},
		"returnDelay": 600,
		"ashDuration": 1600,
		# C8 동료 반응 대사는 대본(script_data.gd "reactions")
		"reactionTremble": 2600,
		"bloodRemain": 0.6,        # C7 피 자국이 옅어진 뒤 남는 진하기
	},

	# 대사창 작은 얼굴: 스탠딩 그림에서 얼굴 부분 (원본 픽셀 좌표 중심, 한 변 크기)
	"faces": {
		"hero": {"img": "stand_hero.png", "cx": 322, "cy": 125, "size": 190},
		"warrior": {"img": "stand_warrior.png", "cx": 255, "cy": 112, "size": 190},
		"archer": {"img": "stand_archer.png", "cx": 335, "cy": 112, "size": 190},
		"noel": {"img": "stand_witch.png", "cx": 250, "cy": 118, "size": 190},
	},
	# 표정 그림 (대사의 face: "hero_smile" → face_hero_smile.png). 정면 상반신(약 435×887)에서 얼굴 부분
	"expressions": {
		"file": "face_{name}.png",
		"crop": {
			"hero": {"cx": 220, "cy": 270, "size": 360},
			"archer": {"cx": 215, "cy": 280, "size": 360},
			"warrior": {"cx": 220, "cy": 270, "size": 360},
		},
		# 대화창의 큰 얼굴(어깨까지 조금 더 넓게)
		"cropLarge": {
			"hero": {"cx": 220, "cy": 300, "size": 470},
			"archer": {"cx": 215, "cy": 310, "size": 470},
			"warrior": {"cx": 220, "cy": 300, "size": 470},
		},
	},
	"standing": {"hero": "stand_hero.png", "warrior": "stand_warrior.png", "archer": "stand_archer.png", "noel": "stand_witch.png"},

	# ───────────── 화면 배치 (1920×1080 기준 좌표) ─────────────
	"layout": {
		"W": 1920, "H": 1080,
		"bg": "bg_cathedral.png",
		# 마녀의 손 그림: 원본 1672×941. scale 배로 줄여 (x, y)에 둔다. 왼손/오른손은 ui_witch_hands.png 를 x=836에서 나눈 것
		"hand": {
			"imgL": "ui_witch_hand_left.png", "imgR": "ui_witch_hand_right.png", "splitX": 836, "imgW": 1672, "imgH": 941,
			"scale": 0.9, "x": 212, "y": 370,
			# 원본 그림 속 다섯 장 카드 자리 (투명 영역, 원본 좌표). [왼위, 오위, 오아래, 왼아래]
			"slots": [
				[[351.3, 287.5], [579.6, 171.7], [726.7, 603.8], [566.2, 685.2]],
				[[521.8, 184.0], [771.7, 128.6], [809.8, 582.9], [634.1, 621.9]],
				[[706.2, 130.1], [961.6, 130.4], [918.0, 581.3], [738.2, 580.9]],
				[[900.2, 132.7], [1151.0, 184.1], [1009.3, 613.3], [833.0, 577.1]],
				[[1089.7, 173.3], [1318.9, 287.4], [1092.8, 678.8], [931.7, 598.6]],
			],
			"cardFrac": 0.685,     # 카드 자리 아래에서부터 이 비율만큼만 카드(2:3)로 채운다
			"hoverScale": 1.12,    # 마우스를 올렸을 때 카드 배율 (카드 원본 240×360 기준)
			"hoverBottom": 1060,   # 확대된 카드의 아랫변 y
			"dragScale": 0.85,
			"backs": true,         # 비는 카드 자리에는 마녀가 쥔 덱(뒷면 카드)이 보인다(손 그림이 잘려 보이지 않게)
			"dropY": 70,           # 카드를 낼 때 부채꼴 손(왼손 쪽)이 내려가는 거리
			# 카드를 낼 때 오른손이 손패에서 빠지는 동안: 손패를 왼손 쪽으로 모으는 비율(카드 자리 s → s × gather)
			"gather": 0.5,
			# 오른손이 빠질 때 함께 가져가는 덱 덮개(뒷면 카드) 자리 — 오른손 그림의 잘린 자리를 가린다
			"rightBacks": [2, 3, 4],
			"rightOut": [140, 560],   # 오른손이 빠져 내려가는 거리(x, y)
		},
		# 카드를 낼 때 오른손이 카드 한 장을 세워 드는 그림 (ui_witch_hand_raise.png, 원본 1672×941)
		# quad: 그 카드 자리의 네 모서리 [왼위, 오위, 오아래, 왼아래] — assets/ui_witch_hand_raise.json 값과 같아야 한다(테스트로 확인)
		"raise": {
			"img": "ui_witch_hand_raise.png", "imgW": 1672, "imgH": 941,
			"scale": 0.9, "x": 420, "y": 320,
			"from": [300, 520],
			"quad": [[866, 64], [1186, 32], [1221, 480], [914, 507]],
		},
		# 동료 행동 자세(뒷모습). 기본 자세와 같은 배율로, 발끝(그림 아래 가운데)을 맞춰 겹친다. dx·dy: 미세 조정(화면 px)
		"poses": {
			"hero": {"attack": {"img": "spr_hero_back_attack.png", "dx": 30, "dy": 0}},
			"archer": {"attack": {"img": "spr_archer_back_attack.png", "dx": 20, "dy": 0}},
			"warrior": {"guard": {"img": "spr_warrior_back_guard.png", "dx": -30, "dy": 0}},
		},
		"card": {"w": 240, "h": 360},
		"playZoneY": 610,        # 대상 없는 카드: 이 선보다 위에서 놓으면 사용
		# 동료 뒷모습: x(가운데), top(머리 위), h(그림 높이), anchor(붉은 실이 나오는 등 위치, 그림 비율)
		"allies": {
			"archer": {"img": "spr_archer_back.png", "x": 290, "top": 440, "h": 960, "anchor": [0.50, 0.24]},
			"hero": {"img": "spr_hero_back.png", "x": 960, "top": 392, "h": 820, "anchor": [0.50, 0.165]},
			"warrior": {"img": "spr_warrior_back.png", "x": 1640, "top": 428, "h": 990, "anchor": [0.55, 0.22]},
		},
		"allyHpOffset": 34,
		# 적: x(가운데), feet(발 y), h(그림 높이). 광신도 그림은 2:3
		"enemySlots": [
			{"x": 700, "feet": 352, "h": 232},
			{"x": 960, "feet": 316, "h": 232},
			{"x": 1220, "feet": 352, "h": 232},
		],
		# 거대 존재의 발: 그림 비율을 지킨 채 너비 w, 아랫변 bottom(화면 위쪽에서 잘림). feetY: ??? 표시, intentY: 예고
		"giant": {"cx": 960, "w": 900, "bottom": 560, "feetY": 322, "intentY": 214},
		"witchPanel": {"x": 24, "y": 952, "w": 320, "h": 104},
		"energy": {"x": 1716, "y": 930, "r": 56},
		"endTurn": {"x": 1640, "y": 1004, "w": 260, "h": 60},
		"drawPile": {"x": 400, "y": 1034},
		"discardPile": {"x": 1574, "y": 1034},
		"dialog": {"x": 24, "y": 20, "w": 580, "h": 132},
	},

	# 대화·연출 속도 (ms)
	"timing": {
		"typeCharsPerSec": 38,
		"guideBase": 1800, "guidePerChar": 70,
		"enemyAttack": 520, "drawGap": 90, "banner": 900,
		"footDrop": 520,
		# 카드 내기: 오른손이 손패에서 빠지고(handOut) → 오른손이 카드를 세워 든 뒤(raiseUp) 카드가 날아간다 → 세운 손이 내려가고(raiseDown) 오른손이 손패로(handIn)
		"handOut": 120, "raiseUp": 150, "raiseHold": 60, "cardFly": 240, "raiseDown": 150, "handIn": 160,
		# 죽음 카드: 천천히 들어 올려 떨며 붉은 실이 최대로 팽팽해진 뒤 컷신으로
		"deathRaiseUp": 420, "deathHold": 1700, "deathTremble": 4,
	},

	# ───────────── 컷인 (대표 카드를 낼 때마다) ─────────────
	"cutin": {
		"duration": 820,
		"heavyDuration": 1350,
		"band": {"y": 300, "h": 420, "slant": 70},
		"imgH": 820,
		"cards": {
			"holy_slash": {"img": "cutin_hero.png", "focus": [0.50, 0.40], "at": 1000, "from": 1, "color": "#e8f4ff"},
			"snipe": {"img": "cutin_archer.png", "focus": [0.55, 0.30], "at": 940, "from": 1, "color": "#d8ffb8"},
			"cover": {"img": "cutin_warrior.png", "focus": [0.45, 0.40], "at": 1140, "from": -1, "color": "#ffd36b"},
			"curse_flame": {"img": "cutin_witch_cast.png", "focus": [0.45, 0.30], "at": 1000, "from": 1, "color": "#ff7a3a"},
			"trample": {"img": "cutin_witch_inherit.png", "focus": [0.40, 0.28], "at": 980, "from": 1, "color": "#ff2a3c", "heavy": true},
		},
	},

	# ───────────── 동료·적 움직임 ─────────────
	"motion": {
		"windup": 150, "blend": 100, "strike": 110, "hitstop": 80, "recover": 260,
		"crouch": 10,
		"cards": {
			"holy_slash": ["hero", "attack"], "vanguard": ["hero", "attack"],
			"snipe": ["archer", "attack"], "suppress": ["archer", "attack"],
			"cover": ["warrior", "guard"], "shield_bash": ["warrior", "guard"],
		},
		"lunge": {
			"hero": {"toward": 0.18, "max": 110, "dy": -70, "scale": 1.07},
			"archer": {"toward": 0.04, "max": 30, "dy": -16, "scale": 1.03},
			"warrior": {"toward": 0.12, "max": 90, "dy": -46, "scale": 1.06},
		},
		"breathe": {"amp": 1.5, "period": 3800},
		"enemy": {"windup": 130, "rush": 150, "back": 300, "dy": 46, "scale": 1.28},
		"hurt": {"power": 9, "dur": 300},
	},

	# 휴대폰 등 작은 화면: 실제 화면에서 무대(1920×1080)가 이 배율보다 작으면 글씨·대사창·카드 확대를 키운다
	"mobile": {
		"smallScale": 0.6,      # 무대 배율(CSS px 기준)이 이보다 작으면 '작은 화면'
		"minTextPx": 13,        # 대사 글씨가 실제 화면에서 최소 이 크기(CSS px)가 되게
		"minCardTextPx": 11,    # 카드 확대 보기의 설명 글씨 최소 크기(CSS px)
		"maxUi": 1.9,           # 대사창·안내 배율 상한
		"maxCard": 2.6,         # 카드 확대 배율 상한
	},

	# 카드 그림 파일 (카드 id → 파일). 있으면 코드로 그린 그림 대신 쓴다
	"cardArtImg": {"hero_death": "card_art_hero_death.png", "trample": "card_art_trample.png"},
}
