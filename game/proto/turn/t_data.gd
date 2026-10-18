class_name TData
extends RefCounted
## 턴제 전투 프로토타입 데이터 (docs/eska-turn/combat_proto.md). 숫자는 전부 여기에만 둔다 — 코드는 이 표를 읽기만 한다.
##
## 마녀 3명(에스카·이그니스·엠버) · 마법 30개 · 장비 3개 · 적 3종.
## 마법 효과(effects)는 작은 사전들의 목록이다. "t"가 종류:
##   buff      who(target|self|allies) cat(atk|crit_dmg|crit_rate|special|final|dmg_taken|element) v dur [mark] [el] [pre]
##             — pre: 공격 마법에서 피해를 주기 "직전" 자신에게 거는 버프 (그 행동으로 소모)
##   debuff    who(target|enemies) cat(def_down|atk_down) v dur        — dur는 "그 적의 행동 N번"
##   mark      kind(burn|frost|shock) dur                              — 징표 (특공의 조건, 그 자체 효과 없음)
##   this_special mark v                                               — 이 공격만 징표 특공
##   ignore_def                                                         — 이 공격만 적 방어율을 0으로
##   credits   who v  ·  gauge who v(0~1)  ·  heal who pct  ·  revive who pct(살아 있으면 회복)
##   invincible who dur (적 행동 N번)  ·  demerit_zero who (그 행동이 끝나면 크레딧 0)
##   on_crit   effects (크리티컬이 났을 때만)
## 버프 지속 "dur"은 대상이 행동을 N번 마칠 때까지(clock own). invincible·dmg_taken은 적 행동 N번(clock enemy).

const GAUGE_MAX := 1000.0
const CREDIT_MAX := 7
const BASIC_BONUS := 1 ## 기본 공격을 쓰면 더 주는 크레딧
const EQUIP_MAX := 5 ## 전투에 장착하는 마법 수

const CRIT_BASE := 0.10
const CRIT_MULT := 1.5
const WEAK := 1.5
const SPECIAL := 1.2
const CAP := {"atk": 3.0, "crit_dmg": 3.0, "special": 2.0, "final": 1.0, "def_down": 0.5, "atk_down": 0.5, "dmg_taken": 1.0, "crit_rate": 0.9}
const DEF_MIN := 0.3
const DEF_MAX := 1.5
const RAND_LO := 0.95
const RAND_HI := 1.05

const ELEMENT_NAME := {"fire": "불", "water": "물", "bolt": "번개", "space": "공간", "sword": "검술", "time": "시간", "none": "무"}
const MARK_NAME := {"burn": "화상", "frost": "빙결", "shock": "감전"}
const CAT_NAME := {"atk": "공격력", "crit_dmg": "크리 데미지", "crit_rate": "크리 확률", "special": "특공", "final": "최종 데미지",
	"dmg_taken": "받는 피해", "element": "속성 부여", "def_down": "방어 다운", "atk_down": "공격력 다운", "invincible": "무적"}

## 약점표: 적의 속성 → 약점인 공격 속성
const WEAK_TO := {"straw": "fire", "water": "bolt", "fire": "water", "bolt": "water", "ash": "", "none": ""}

const WITCHES := {
	"eska": {
		"name": "에스카", "title": "공간의 마녀", "atk": 13000, "hp": 90000, "speed": 110, "def": 0.10,
		"element": "space", "special": true,
		"basic": {"name": "작은 균열", "mult": 1.0, "desc": "단일 1.0배. 차례를 넘기며 크레딧 +1"},
		"skills": ["crack", "void_gate", "leap", "seal", "gap", "compress", "doom", "stigma", "blackstar", "cradle"],
		"default": ["crack", "void_gate", "seal", "doom", "blackstar"],
		"color": Color("#b9a2ff"), "accent": Color("#f2eff7"),
	},
	"ignis": {
		"name": "이그니스", "title": "불의 마녀 · 딜러", "atk": 12000, "hp": 80000, "speed": 95, "def": 0.05,
		"element": "fire", "special": false,
		"basic": {"name": "불씨 튀기기", "mult": 1.0, "mark": "burn", "mark_dur": 2, "desc": "단일 1.0배 + 화상(적 행동 2번). 크레딧 +1"},
		"skills": ["spark", "whip", "focus", "pillar", "meteor", "breath_of_fire", "ash_storm", "blaze", "sun_spear", "conflagration"],
		"default": ["spark", "focus", "pillar", "ash_storm", "sun_spear"],
		"color": Color("#ff6a3d"), "accent": Color("#ffd27a"),
	},
	"ember": {
		"name": "엠버", "title": "불의 마녀 · 버퍼", "atk": 8000, "hp": 100000, "speed": 120, "def": 0.15,
		"element": "fire", "special": false,
		"basic": {"name": "불똥", "mult": 0.8, "desc": "단일 0.8배. 크레딧 +1"},
		"skills": ["flame_breath", "kindling", "bellows", "warmth", "blessing", "fire_wall", "stake", "god_descent", "share_ember", "sun_blessing"],
		"default": ["flame_breath", "kindling", "bellows", "blessing", "god_descent"],
		"color": Color("#ffb347"), "accent": Color("#fff2dc"),
	},
}

const SKILLS := {
	# ── 에스카: 공간 · 무상성 · 범용 (공격 4 + 보조 6)
	"crack": {"name": "균열", "cost": 1, "kind": "attack", "target": "enemy", "mult": 2.0, "fx": "rift_small",
		"effects": [{"t": "debuff", "cat": "def_down", "v": 0.10, "dur": 2}],
		"desc": "2.0배 피해 + 방어 다운 10% (적 행동 2번)", "ref": "싼 단일기 + 가벼운 디버프"},
	"void_gate": {"name": "공허의 문", "cost": 2, "kind": "support", "target": "ally", "fx": "void_gate",
		"effects": [{"t": "buff", "cat": "final", "v": 0.30, "dur": 3}, {"t": "gauge", "v": 0.30}],
		"desc": "아군 1: 최종 데미지 +30% (행동 3번) + 행동 게이지 +30%", "ref": "공명·멀린의 단일 몰아주기 + 차례 당기기"},
	"leap": {"name": "공간 도약", "cost": 2, "kind": "support", "target": "ally", "fx": "leap",
		"effects": [{"t": "gauge", "v": 0.50}, {"t": "credits", "v": 1}],
		"desc": "아군 1: 행동 게이지 +50% + 크레딧 +1", "ref": "스카디의 보구 충전 50% (자원을 한 명에게 넘김)"},
	"seal": {"name": "봉공", "cost": 3, "kind": "support", "target": "allies", "fx": "seal",
		"effects": [{"t": "invincible", "who": "allies", "dur": 1}, {"t": "credits", "who": "allies", "v": 1}],
		"desc": "아군 전체: 무적 (다음 적 행동 1번) + 크레딧 +1", "ref": "캐스토리아의 지키면서 채우기"},
	"gap": {"name": "틈", "cost": 3, "kind": "support", "target": "enemies", "fx": "gap",
		"effects": [{"t": "debuff", "who": "enemies", "cat": "def_down", "v": 0.20, "dur": 3}, {"t": "debuff", "who": "enemies", "cat": "atk_down", "v": 0.20, "dur": 2}],
		"desc": "적 전체: 방어 다운 20% (적 행동 3번) + 공격력 다운 20% (적 행동 2번)", "ref": "스카디·모르간의 광역 방어 다운"},
	"compress": {"name": "압축", "cost": 3, "kind": "attack", "target": "enemy", "mult": 3.0, "fx": "compress",
		"effects": [{"t": "ignore_def"}],
		"desc": "3.0배 피해, 이 공격만 적 방어율 무시", "ref": "방어 무시 단일기 (단단한 적 전용)"},
	"doom": {"name": "종언", "cost": 4, "kind": "attack", "target": "enemy", "mult": 6.0, "fx": "doom",
		"effects": [{"t": "buff", "who": "self", "cat": "atk", "v": 0.40, "dur": 1, "pre": true}],
		"desc": "공격 직전 자신 공격력 +40% (행동 1번) → 6.0배 피해", "ref": "초인 오리온의 자가 버프 → 강타"},
	"stigma": {"name": "성흔", "cost": 4, "kind": "support", "target": "ally", "fx": "stigma",
		"effects": [{"t": "buff", "cat": "crit_dmg", "v": 0.80, "dur": 3}, {"t": "buff", "cat": "crit_rate", "v": 0.50, "dur": 3}],
		"desc": "아군 1: 크리 데미지 +80% + 크리 확률 +50% (행동 3번)", "ref": "공명의 크리 데미지 · 멀린의 크리 위력"},
	"blackstar": {"name": "흑성", "cost": 5, "kind": "attack", "target": "enemies", "mult": 4.5, "fx": "blackstar",
		"effects": [{"t": "debuff", "who": "enemies", "cat": "def_down", "v": 0.20, "dur": 3}],
		"desc": "적 전체 4.5배 피해 + 방어 다운 20% (적 행동 3번)", "ref": "아르주나 얼터의 광역 보구 + 광역 디버프"},
	"cradle": {"name": "공허의 요람", "cost": 5, "kind": "support", "target": "ally_any", "fx": "cradle",
		"effects": [{"t": "revive", "pct": 0.50}, {"t": "credits", "v": 2}],
		"desc": "아군 1: 쓰러진 아군을 체력 50%로 되살림 (살아 있으면 50% 회복) + 크레딧 +2", "ref": "부활 (사용자 목록) — 속성을 타지 않는 특수 마녀의 보조"},

	# ── 이그니스: 불 · 공격 특화 (공격 8 + 보조 2)
	"spark": {"name": "불씨", "cost": 1, "kind": "attack", "target": "enemy", "mult": 2.0, "fx": "fireball",
		"effects": [{"t": "mark", "kind": "burn", "dur": 3}],
		"desc": "2.0배 피해 + 화상 (적 행동 3번)", "ref": "징표 심기"},
	"whip": {"name": "불꽃 채찍", "cost": 2, "kind": "attack", "target": "enemy", "mult": 2.5, "fx": "whip",
		"effects": [{"t": "debuff", "cat": "atk_down", "v": 0.15, "dur": 2}],
		"desc": "2.5배 피해 + 적 공격력 다운 15% (적 행동 2번)", "ref": "모르간의 공격력 다운"},
	"focus": {"name": "화염 집중", "cost": 2, "kind": "support", "target": "self", "fx": "focus",
		"effects": [{"t": "buff", "who": "self", "cat": "atk", "v": 0.50, "dur": 2}, {"t": "buff", "who": "self", "cat": "crit_rate", "v": 0.30, "dur": 2}],
		"desc": "자신: 공격력 +50% + 크리 확률 +30% (행동 2번)", "ref": "딜러의 자가 버프 (초인 오리온 S3)"},
	"pillar": {"name": "불기둥", "cost": 3, "kind": "attack", "target": "enemy", "mult": 3.5, "fx": "pillar",
		"effects": [{"t": "this_special", "mark": "burn", "v": 0.50}],
		"desc": "3.5배 피해, 이 공격만 화상 특공 +50%", "ref": "아르주나 얼터의 디버프 적 특공"},
	"meteor": {"name": "유성 낙하", "cost": 3, "kind": "attack", "target": "enemy", "mult": 3.0, "fx": "meteor",
		"effects": [{"t": "debuff", "cat": "def_down", "v": 0.15, "dur": 2}, {"t": "mark", "kind": "burn", "dur": 2}],
		"desc": "3.0배 피해 + 방어 다운 15% (적 행동 2번) + 화상 (적 행동 2번)", "ref": "모르간의 방어 다운 + 징표"},
	"breath_of_fire": {"name": "불의 호흡", "cost": 3, "kind": "support", "target": "ally", "fx": "breath",
		"effects": [{"t": "buff", "cat": "crit_dmg", "v": 0.60, "dur": 2}, {"t": "buff", "cat": "crit_rate", "v": 0.30, "dur": 2}],
		"desc": "아군 1: 크리 데미지 +60% + 크리 확률 +30% (행동 2번)", "ref": "공명의 단일 크리 버프 (딜러도 남을 밀어 줄 수 있게)"},
	"ash_storm": {"name": "재의 폭풍", "cost": 4, "kind": "attack", "target": "enemies", "mult": 3.0, "fx": "ash_storm",
		"effects": [{"t": "mark", "who": "enemies", "kind": "burn", "dur": 3}],
		"desc": "적 전체 3.0배 피해 + 전체 화상 (적 행동 3번)", "ref": "모르간의 광역 보구 + 광역 징표"},
	"blaze": {"name": "폭염", "cost": 4, "kind": "attack", "target": "enemy", "mult": 4.0, "fx": "blaze",
		"effects": [{"t": "buff", "who": "self", "cat": "special", "mark": "burn", "v": 0.30, "dur": 2, "pre": true}],
		"desc": "공격 직전 자신 화상 특공 +30% (행동 2번) → 4.0배 피해", "ref": "초인 오리온의 특공 1턴 → 다음 공격까지 남김"},
	"sun_spear": {"name": "태양의 창", "cost": 5, "kind": "attack", "target": "enemy", "mult": 6.0, "fx": "sun_spear",
		"effects": [{"t": "buff", "who": "self", "cat": "crit_dmg", "v": 0.50, "dur": 1, "pre": true},
			{"t": "on_crit", "effects": [{"t": "debuff", "cat": "def_down", "v": 0.20, "dur": 2}]}],
		"desc": "공격 직전 자신 크리 데미지 +50% (행동 1번) → 6.0배 피해. 크리면 방어 다운 20% (적 행동 2번)", "ref": "한 방 + 크리 조건 보너스"},
	"conflagration": {"name": "대화재", "cost": 5, "kind": "attack", "target": "enemies", "mult": 4.0, "fx": "conflagration",
		"effects": [{"t": "this_special", "mark": "burn", "v": 0.80}],
		"desc": "적 전체 4.0배 피해, 이 공격만 화상 특공 +80%", "ref": "징표를 모두 터뜨리는 광역 마무리"},

	# ── 엠버: 불 · 버프 특화 (보조 8 + 공격 2)
	"flame_breath": {"name": "불꽃 입김", "cost": 1, "kind": "attack", "target": "enemy", "mult": 1.5, "fx": "fireball_small",
		"effects": [{"t": "mark", "kind": "burn", "dur": 3}],
		"desc": "1.5배 피해 + 화상 (적 행동 3번)", "ref": "버퍼도 징표를 심을 수 있게"},
	"kindling": {"name": "장작", "cost": 2, "kind": "support", "target": "ally", "fx": "kindling",
		"effects": [{"t": "buff", "cat": "element", "el": "fire", "dur": 3}, {"t": "buff", "cat": "crit_dmg", "v": 0.50, "dur": 3, "el": "fire"}],
		"desc": "아군 1: 공격에 화염 속성 부여 + 화염 공격 크리 데미지 +50% (행동 3번)", "ref": "사용자 예시 그대로 (무상성 딜러를 화염 딜러로)"},
	"bellows": {"name": "풀무", "cost": 2, "kind": "support", "target": "ally", "fx": "bellows",
		"effects": [{"t": "buff", "cat": "special", "mark": "burn", "v": 0.50, "dur": 3}, {"t": "buff", "cat": "crit_rate", "v": 0.30, "dur": 3}],
		"desc": "아군 1: 화상 특공 +50% + 크리 확률 +30% (행동 3번)", "ref": "사용자 예시 그대로"},
	"warmth": {"name": "온기", "cost": 2, "kind": "support", "target": "allies", "fx": "warmth",
		"effects": [{"t": "heal", "who": "allies", "pct": 0.30}, {"t": "gauge", "who": "allies", "v": 0.20}],
		"desc": "아군 전체: 체력 30% 회복 + 행동 게이지 +20%", "ref": "멀린의 회복 + 보구 충전"},
	"blessing": {"name": "불의 축복", "cost": 3, "kind": "support", "target": "allies", "fx": "blessing",
		"effects": [{"t": "buff", "who": "allies", "cat": "atk", "v": 0.30, "dur": 3}, {"t": "credits", "who": "allies", "v": 1}],
		"desc": "아군 전체: 공격력 +30% (행동 3번) + 크레딧 +1", "ref": "캐스토리아·멀린의 전체 공격 버프 + 자원"},
	"fire_wall": {"name": "불막이", "cost": 3, "kind": "support", "target": "allies", "fx": "fire_wall",
		"effects": [{"t": "buff", "who": "allies", "cat": "dmg_taken", "v": -0.40, "dur": 2}, {"t": "debuff", "who": "enemies", "cat": "atk_down", "v": 0.20, "dur": 2}],
		"desc": "아군 전체: 받는 피해 −40% (적 행동 2번) + 적 전체 공격력 다운 20% (적 행동 2번)", "ref": "멀린의 전체 보호 + 적 약화"},
	"stake": {"name": "화형대", "cost": 3, "kind": "attack", "target": "enemy", "mult": 2.5, "fx": "stake",
		"effects": [{"t": "debuff", "cat": "def_down", "v": 0.20, "dur": 3}, {"t": "mark", "kind": "burn", "dur": 3}],
		"desc": "2.5배 피해 + 방어 다운 20% (적 행동 3번) + 화상 (적 행동 3번)", "ref": "모르간의 방어 다운을 버퍼의 디버프 공격으로"},
	"god_descent": {"name": "불의 신 강림", "cost": 4, "kind": "support", "target": "ally", "fx": "god_descent",
		"effects": [{"t": "buff", "cat": "atk", "v": 1.00, "dur": 1}, {"t": "gauge", "v": 1.00}, {"t": "demerit_zero"}],
		"desc": "아군 1: 공격력 +100% (행동 1번) + 게이지 100% (바로 다음 차례). 대가: 그 행동이 끝나면 크레딧 0", "ref": "오베론·코얀스카야의 한 번 크게, 대가는 나중에"},
	"share_ember": {"name": "불씨 나눔", "cost": 4, "kind": "support", "target": "ally", "fx": "share_ember",
		"effects": [{"t": "credits", "v": 3}, {"t": "buff", "cat": "final", "v": 0.20, "dur": 2}],
		"desc": "아군 1: 크레딧 +3 + 최종 데미지 +20% (행동 2번)", "ref": "스카디·캐스토리아의 보구 충전 (자원을 딜러에게 몰아줌)"},
	"sun_blessing": {"name": "태양의 축복", "cost": 5, "kind": "support", "target": "allies", "fx": "sun_blessing",
		"effects": [{"t": "buff", "who": "allies", "cat": "crit_dmg", "v": 0.50, "dur": 3}, {"t": "buff", "who": "allies", "cat": "final", "v": 0.30, "dur": 3},
			{"t": "credits", "who": "allies", "v": 1}],
		"desc": "아군 전체: 크리 데미지 +50% + 최종 데미지 +30% (행동 3번) + 크레딧 +1", "ref": "캐스토리아 S1의 전체 버프 겹치기"},
}

const EQUIPS := {
	"": {"name": "없음", "desc": "장비 없음"},
	"black_cup": {"name": "검은 잔", "desc": "공격 마법 피해 +60% · 받는 피해 +30%", "skill_final": 0.60, "dmg_taken": 0.30},
	"kaleido": {"name": "만화경", "desc": "전투 시작 시 크레딧 7 (가득)", "start_credits": 7},
	"notebook": {"name": "마녀의 수첩", "desc": "시작 크레딧 +3 · 공격력 +20%", "start_credits": 3, "atk": 0.20},
}

## 적. pattern = 의도 순서(돌아감). 종류: attack 1.0배 · heavy 배율 · aoe 전체 배율 · buff 자기 공격력
const ENEMIES := {
	"straw_golem": {"name": "짚 골렘", "hp": 200000, "atk": 6000, "speed": 80, "def": 0.0, "element": "straw",
		"pattern": [{"k": "attack", "mult": 1.0}, {"k": "heavy", "mult": 2.0}], "size": 1.0, "color": Color("#c9a85c")},
	"swamp_toad": {"name": "늪 두꺼비", "hp": 300000, "atk": 5000, "speed": 105, "def": 0.20, "element": "water",
		"pattern": [{"k": "attack", "mult": 1.0}, {"k": "attack", "mult": 1.0}, {"k": "aoe", "mult": 0.8}], "size": 1.0, "color": Color("#6f8a3a")},
	"ash_knight": {"name": "재의 기사", "hp": 700000, "atk": 9000, "speed": 95, "def": 0.30, "element": "ash", "boss": true,
		"pattern": [{"k": "attack", "mult": 1.0}, {"k": "buff", "v": 0.30, "dur": 3}, {"k": "heavy", "mult": 2.0}, {"k": "aoe", "mult": 1.0}], "size": 1.3, "color": Color("#6e6673")},
}
const INTENT_NAME := {"attack": "공격", "heavy": "강공격", "aoe": "전체 공격", "buff": "버프"}

## 프로토타입 전투 1판
const BATTLE := {"party": ["eska", "ignis", "ember"], "enemies": ["straw_golem", "swamp_toad", "ash_knight"]}


static func skill(id: String) -> Dictionary:
	return SKILLS.get(id, {})


static func cost_of(id: String) -> int:
	return int(SKILLS.get(id, {}).get("cost", 0))


## 숫자를 1,234,567 꼴로
static func fmt(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if n < 0 else "") + out


## 짧은 숫자 (12.3만 · 1.13M 대신 한국식 만 단위): 체력 표시용
static func fmt_short(n: int) -> String:
	if n >= 100000000:
		return "%.1f억" % (float(n) / 100000000.0)
	if n >= 10000:
		var m := float(n) / 10000.0
		return ("%.0f만" if m >= 100.0 else "%.1f만") % m
	return str(n)
