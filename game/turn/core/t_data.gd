class_name TData
extends RefCounted
## 턴제 전투 시제품의 표 — 마녀·마법·적·빗자루·물약·전투. 규칙과 수치 근거는 docs/eska-turn/battle_proto.md.
## 시간 단위는 "칸": 행동 게이지 한 칸. 기다림(wait)이 가장 적게 남은 쪽이 먼저 움직이고, 버프·재사용 대기도 같은 칸으로 센다.
## 버프 범주: 같은 범주끼리는 더하고 범주끼리는 곱한다. 범주마다 상한(CAPS).

const ELEM_SPACE := "space" ## 에스카의 "공간" — 상성 밖. 모든 적에게 SPACE_MULT
const ELEM_FIRE := "fire"
const SPACE_MULT := 1.2 ## 에스카 무상성 배율 [확정 2026-10-17]
const WEAK_MULT := 1.5
const RESIST_MULT := 0.5
const BASE_CRIT := 0.05 ## 기본 치명 확률
const BASE_CRIT_DMG := 1.5 ## 치명타 기본 배율 (치명 피해 버프는 여기에 더한다)
const GAUGE_MAX := 100.0
const WAIT_ACTION := 1.0 ## "기다리기"의 다음 차례까지 칸
const WAIT_ACTION_GAUGE := 10.0
const HIT_GAUGE := 4.0 ## 한 타 맞힐 때마다 게이지
const HURT_GAUGE := 8.0 ## 맞을 때마다
const INTERRUPT_REFUND := 0.6 ## 시전이 끊긴 대마법의 게이지 환급 비율
const INTERRUPT_RECOVER := 0.5 ## 끊긴 뒤 다음 차례까지 (기본 기다림 배수)
const ELEM_NAMES := {"space": "공간", "fire": "화염", "": "무속성"}

## 버프 범주 상한 (더한 값의 최대). def는 깎는 쪽 바닥(-0.8 = 방어 80%까지만 깎임)
const CAPS := {"atk": 3.0, "elem": 3.0, "crit_rate": 0.95, "crit_dmg": 3.0, "final": 2.0, "vuln": 2.0, "def": 1.0, "haste": 0.6}
const DEF_FLOOR := -0.8
const KIND_NAMES := {"atk": "공격", "elem": "속성", "crit_rate": "치명률", "crit_dmg": "치명피해", "final": "최종", "vuln": "취약", "def": "방어", "haste": "가속", "shield": "방벽", "burn": "화상"}

# ═══════════════════════════════════════════════════════════
# 마녀 (레벨 1 기준. 레벨당 GROWTH만큼 체력·공격 증가)
# ═══════════════════════════════════════════════════════════

const WITCHES := {
	"eska": {
		"name": "에스카", "title": "종언의 마녀", "elem": "space", "hp": 520, "atk": 130, "wait": 3.0,
		"gauge": "종언", "gauge_start": 40.0, "growth": {"hp": 0.0, "atk": 0.0}, ## 처음부터 완성된 마녀 — 레벨로 크지 않는다
		"spells": ["crack", "skytear", "rift", "stareyes", "seal", "blackstar"],
		"start": ["crack", "skytear", "rift", "stareyes", "seal", "blackstar"],
		"color": "#b9a2ff", "aggro": 1.2,
		"desc": "어두운 보랏빛 공간 마법. 상성이 없어 어떤 적에게도 1.2배. 딜러로도, 최종 피해·치명 증폭 서포터로도.",
	},
	"sera": {
		"name": "세라", "title": "화염의 마녀", "elem": "fire", "hp": 420, "atk": 110, "wait": 3.0,
		"gauge": "불씨", "gauge_start": 0.0, "growth": {"hp": 0.09, "atk": 0.08},
		"spells": ["firebolt", "pillar", "storm", "meteor", "ward", "embers"],
		"start": ["firebolt", "pillar", "storm"],
		"color": "#ff7a52", "aggro": 1.0,
		"desc": "불을 던지는 딜러형. 공격 4 · 지원 2. 화염에 약한 적에게 1.5배, 화염 버프를 받으면 에스카를 넘어선다.",
	},
	"ashe": {
		"name": "아셰", "title": "잿불의 마녀", "elem": "fire", "hp": 380, "atk": 85, "wait": 2.6,
		"gauge": "", "gauge_start": 0.0, "growth": {"hp": 0.09, "atk": 0.07},
		"spells": ["flick", "sparks", "bellows", "oil", "warmth", "festival"],
		"start": ["flick", "bellows", "oil"],
		"color": "#f0c050", "aggro": 1.0,
		"desc": "빠르고 가벼운 보조형. 공격 2 · 지원 4. 풀무로 화염을 키우고, 기름으로 적을 약하게 만든다.",
	},
}

## 레벨 상한과 레벨당 필요한 경험치 (전투마다 xp)
const LEVEL_MAX := 6

# ═══════════════════════════════════════════════════════════
# 마법. power = 공격력 100 기준 피해(총합, hits로 나눔). weight = 쓴 뒤 다음 차례까지 기본 기다림 배수.
# cd = 재사용 대기(칸). cast = 시전(칸, 끊길 수 있음). gauge = 쓰면 차는 게이지 (ult는 100 소모).
# buff = {kind, amt, dur, stack, elem?}. kind: attack / support / ult
# ═══════════════════════════════════════════════════════════

const SPELLS := {
	# ── 에스카 (공격 3 · 지원 3)
	"crack": {"name": "금", "who": "eska", "kind": "attack", "target": "enemy", "elem": "space",
		"power": 100, "hits": 1, "weight": 0.7, "cd": 0.0, "gauge": 15.0,
		"desc": "손끝으로 가리킨 자리에 가는 금이 간다. 가볍고 빠르다."},
	"skytear": {"name": "천열", "who": "eska", "kind": "attack", "target": "enemy", "elem": "space",
		"power": 260, "hits": 4, "weight": 1.0, "cd": 4.0, "gauge": 20.0, "interrupt": true,
		"desc": "공간을 네 번 찢는다. 시전 중인 적을 끊는다(굳센 시전은 못 끊음)."},
	"rift": {"name": "틈 열기", "who": "eska", "kind": "support", "target": "ally",
		"buffs": [{"kind": "final", "amt": 0.45, "dur": 5.0, "stack": 2}], "weight": 0.8, "cd": 2.0, "gauge": 15.0,
		"desc": "아군 곁에 틈을 연다. 틈을 지나는 마법은 최종 피해 +45%. 두 겹까지."},
	"stareyes": {"name": "별빛 눈", "who": "eska", "kind": "support", "target": "ally",
		"buffs": [{"kind": "crit_rate", "amt": 0.3, "dur": 5.0, "stack": 2}, {"kind": "crit_dmg", "amt": 0.6, "dur": 5.0, "stack": 2}],
		"weight": 0.8, "cd": 2.0, "gauge": 15.0,
		"desc": "별빛이 눈에 맺힌다. 치명 확률 +30%, 치명 피해 +60%. 두 겹까지."},
	"seal": {"name": "봉공", "who": "eska", "kind": "support", "target": "enemy",
		"interrupt": true, "heavy": true, "push": 2.0, "buffs": [{"kind": "vuln", "amt": 0.25, "dur": 4.0, "stack": 1}],
		"weight": 1.0, "cd": 5.0, "gauge": 15.0,
		"desc": "적의 공간을 굳힌다. 어떤 시전이든 끊고 차례를 2칸 미루며, 받는 피해 +25%."},
	"blackstar": {"name": "흑성", "who": "eska", "kind": "ult", "target": "all", "elem": "space",
		"power": 480, "hits": 1, "weight": 1.2, "cd": 0.0, "cast": 2.0, "gauge": 0.0,
		"desc": "대마법. 검은 별이 모든 것을 끌어모아 무너뜨린다. 시전 2칸."},
	# ── 세라 (공격 4 · 지원 2)
	"firebolt": {"name": "불꽃탄", "who": "sera", "kind": "attack", "target": "enemy", "elem": "fire",
		"power": 80, "hits": 1, "weight": 0.7, "cd": 0.0, "gauge": 15.0,
		"desc": "손에 감긴 불을 던진다. 가볍고 빠르다."},
	"pillar": {"name": "불기둥", "who": "sera", "kind": "attack", "target": "enemy", "elem": "fire",
		"power": 200, "hits": 1, "weight": 1.0, "cd": 3.0, "gauge": 20.0, "burn": 0.12,
		"desc": "발밑에서 불기둥이 솟는다. 맞은 적은 세 차례 동안 불탄다(피해의 12%씩)."},
	"storm": {"name": "화염 폭풍", "who": "sera", "kind": "attack", "target": "all", "elem": "fire",
		"power": 140, "hits": 1, "weight": 1.2, "cd": 4.0, "gauge": 20.0,
		"desc": "넓은 부채꼴 불길. 적 전체."},
	"meteor": {"name": "유성 낙화", "who": "sera", "kind": "ult", "target": "all", "elem": "fire",
		"power": 450, "hits": 3, "weight": 1.2, "cd": 0.0, "cast": 2.0, "gauge": 0.0, "cost": 2,
		"desc": "대마법. 하늘이 붉게 물들고 유성이 세 번 쏟아진다. 시전 2칸."},
	"ward": {"name": "불꽃 방벽", "who": "sera", "kind": "support", "target": "ally",
		"buffs": [{"kind": "shield", "amt": 180.0, "dur": 5.0, "stack": 1}], "weight": 0.8, "cd": 4.0, "gauge": 15.0, "cost": 1,
		"desc": "불의 원을 두른다. 180만큼의 피해를 막는다."},
	"embers": {"name": "잉걸불", "who": "sera", "kind": "support", "target": "ally",
		"pull": 1.5, "buffs": [{"kind": "haste", "amt": 0.25, "dur": 5.0, "stack": 1}], "weight": 0.6, "cd": 4.0, "gauge": 15.0, "cost": 1,
		"desc": "아군의 발밑에 불씨를 지핀다. 차례를 1.5칸 당기고, 5칸 동안 가속 25%."},
	# ── 아셰 (공격 2 · 지원 4)
	"flick": {"name": "잿불", "who": "ashe", "kind": "attack", "target": "enemy", "elem": "fire",
		"power": 70, "hits": 1, "weight": 0.7, "cd": 0.0, "gauge": 0.0,
		"desc": "잿불을 튕긴다. 가볍다."},
	"sparks": {"name": "불씨 흩기", "who": "ashe", "kind": "attack", "target": "all", "elem": "fire",
		"power": 60, "hits": 1, "weight": 1.0, "cd": 2.0, "gauge": 0.0, "buffs": [{"kind": "def", "amt": -0.2, "dur": 4.0, "stack": 1}], "cost": 1,
		"desc": "불씨를 흩뿌린다. 적 전체에 작은 피해, 그을음으로 방어 -20%."},
	"bellows": {"name": "풀무", "who": "ashe", "kind": "support", "target": "ally",
		"buffs": [{"kind": "elem", "elem": "fire", "amt": 0.5, "dur": 5.0, "stack": 2}], "weight": 0.8, "cd": 2.0, "gauge": 0.0,
		"desc": "풀무로 불을 키운다. 아군의 화염 피해 +50%. 두 겹까지. (공간 마법에는 효과 없음)"},
	"oil": {"name": "기름 붓기", "who": "ashe", "kind": "support", "target": "enemy",
		"buffs": [{"kind": "vuln", "amt": 0.3, "dur": 5.0, "stack": 2}], "weight": 0.8, "cd": 2.0, "gauge": 0.0,
		"desc": "적에게 기름을 붓는다. 받는 피해 +30%. 두 겹까지."},
	"warmth": {"name": "온기", "who": "ashe", "kind": "support", "target": "ally",
		"heal": 0.3, "weight": 0.8, "cd": 3.0, "gauge": 0.0, "cost": 1,
		"desc": "따뜻한 잿불. 아군 체력 30% 회복."},
	"festival": {"name": "불꽃 축제", "who": "ashe", "kind": "support", "target": "allies",
		"buffs": [{"kind": "atk", "amt": 0.35, "dur": 5.0, "stack": 1}], "gauge_give": 20.0, "weight": 1.3, "cd": 6.0, "gauge": 0.0, "cost": 2,
		"desc": "아군 모두의 공격 +35%, 게이지 +20."},
}

# ═══════════════════════════════════════════════════════════
# 적. pattern = 행동 순서(돌아가며). 적 행동: {name, kind: attack/buff/cast, target: ally/allies/self/weakest, power, cast, buffs}
# bars = 보스의 체력 줄 (한 줄이 0이 되면 다음 줄로 — 넘친 피해는 버림, 규칙이 바뀐다)
# ═══════════════════════════════════════════════════════════

const ENEMIES := {
	"hound": {
		"name": "그림자 들개", "short": "들", "hp": 430, "atk": 72, "def": 15, "wait": 2.4, "weak": "fire", "resist": "", "aggro_weighted": true,
		"pattern": ["bite", "bite", "howl"], "size": 1.0, "color": "#2a1f33",
		"actions": {
			"bite": {"name": "물어뜯기", "kind": "attack", "target": "ally", "power": 105, "weight": 1.0},
			"howl": {"name": "울부짖음", "kind": "buff", "target": "self", "buffs": [{"kind": "atk", "amt": 0.3, "dur": 4.0, "stack": 1}], "weight": 0.8},
		},
	},
	"monk": {
		"name": "재의 수도사", "short": "수", "hp": 680, "atk": 88, "def": 25, "wait": 3.2, "weak": "", "resist": "",
		"pattern": ["ash", "chant", "ash"], "size": 1.1, "color": "#3a2d2a",
		"actions": {
			"ash": {"name": "잿가루", "kind": "attack", "target": "ally", "power": 95, "weight": 1.0},
			"chant": {"name": "암송 · 재의 비", "kind": "cast", "target": "allies", "power": 170, "cast": 2.0, "weight": 1.1},
		},
	},
	"king": {
		"name": "재의 기사왕", "short": "왕", "hp": 2600, "atk": 110, "def": 60, "wait": 3.0, "weak": "", "resist": "fire", "boss": true,
		"pattern": ["swing", "guard", "roar", "swing"], "size": 1.7, "color": "#1c1418",
		"bars": [
			{"hp": 2600, "def": 60, "weak": "", "resist": "fire", "pattern": ["swing", "guard", "roar", "swing"], "label": "잿빛 갑옷"},
			{"hp": 3000, "def": 25, "weak": "fire", "resist": "", "pattern": ["swing", "swing", "doom", "swing", "roar"], "label": "드러난 불씨",
				"enter_buffs": [{"kind": "atk", "amt": 0.3, "dur": 99.0, "stack": 1}]},
		],
		"actions": {
			"swing": {"name": "대검 휘두르기", "kind": "attack", "target": "ally", "power": 130, "weight": 1.0},
			"guard": {"name": "방패 들기", "kind": "buff", "target": "self", "buffs": [{"kind": "def", "amt": 0.5, "dur": 3.0, "stack": 1}], "weight": 0.7},
			"roar": {"name": "재의 포효", "kind": "cast", "target": "allies", "power": 170, "cast": 2.0, "weight": 1.1},
			"doom": {"name": "멸화", "kind": "cast", "target": "weakest", "power": 400, "cast": 3.0, "weight": 1.2, "heavy": true},
		},
	},
}

# ═══════════════════════════════════════════════════════════
# 빗자루 (마녀마다 하나) · 물약 (전투당 3개, 차례를 쓰지 않음)
# ═══════════════════════════════════════════════════════════

const BROOMS := {
	"raven": {"name": "밤까마귀 빗자루", "wait": -0.4, "desc": "다음 차례까지 0.4칸 빠르다.", "color": "#5c5470"},
	"glass": {"name": "유리 빗자루", "crit_rate": 0.15, "crit_dmg": 0.3, "desc": "치명 확률 +15%, 치명 피해 +30%.", "color": "#d9ccff"},
	"cinder": {"name": "잿가루 빗자루", "elem": 0.25, "gauge_mult": 1.3, "desc": "자기 속성 피해 +25%, 게이지 획득 +30%.", "color": "#f0c050"},
}

const POTIONS := {
	"heal": {"name": "치유", "target": "ally", "heal": 0.35, "color": "#ff4d6d", "throw": false, "desc": "아군 체력 35% 회복."},
	"haste": {"name": "가속", "target": "ally", "pull": 2.0, "color": "#ff8ad8", "throw": false, "desc": "아군의 차례를 2칸 당긴다."},
	"bind": {"name": "속박", "target": "enemy", "push": 2.5, "interrupt": true, "heavy": true, "color": "#ffb347", "throw": true, "desc": "적의 시전을 끊고 차례를 2.5칸 미룬다."},
	"scream": {"name": "비명", "target": "enemies", "interrupt": true, "heavy": true, "buffs": [{"kind": "vuln", "amt": 0.15, "dur": 3.0, "stack": 1}], "color": "#e9e4f2", "throw": true, "desc": "적 모두의 시전을 끊고, 3칸 동안 받는 피해 +15%."},
	"rot": {"name": "부식", "target": "enemy", "buffs": [{"kind": "def", "amt": -0.3, "dur": 5.0, "stack": 1}], "color": "#8fe04a", "throw": true, "desc": "적의 방어 -30%, 5칸."},
}
const POUCH_START := {"heal": 2, "haste": 1, "bind": 1, "scream": 1, "rot": 1}
const BAG_SIZE := 3

# ═══════════════════════════════════════════════════════════
# 전투 (데모 3판)
# ═══════════════════════════════════════════════════════════

const BATTLES := [
	{"name": "뒷마당의 들개", "enemies": ["hound", "hound"], "points": 2, "xp": 1, "music": "basement",
		"intro": "학교 뒷마당. 그림자 들개 두 마리가 불을 싫어한다."},
	{"name": "잿가루 길", "enemies": ["hound", "monk", "hound"], "points": 3, "xp": 1, "music": "temple_dark",
		"intro": "재의 수도사가 암송을 시작하면 끊어라. 천열·봉공·속박이 끊는다."},
	{"name": "재의 기사왕", "enemies": ["king"], "points": 3, "xp": 1, "boss": true, "music": "boss",
		"intro": "잿빛 갑옷은 불을 먹지 않는다. 갑옷이 깨지면 불씨가 드러난다."},
]


static func spell(id: String) -> Dictionary:
	return SPELLS.get(id, {})


static func witch(id: String) -> Dictionary:
	return WITCHES.get(id, {})


static func enemy(id: String) -> Dictionary:
	return ENEMIES.get(id, {})


static func kind_name(kind: String) -> String:
	return KIND_NAMES.get(kind, kind)


static func elem_name(elem: String) -> String:
	return ELEM_NAMES.get(elem, elem)
