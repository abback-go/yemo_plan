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
##   [신규 2026-10-18, witches_12.md §3]
##   enemy_gauge who v [frost_x2] [if_mark]   — 적 게이지 −1000×v (빙결이면 두 배 / if_mark가 있으면 그 징표가 있을 때만)
##   gauge_zero who [if_mark]                 — 적 게이지 0
##   extend_buffs who v                       — own 시계 버프 전부 dur +v
##   extend_mark who kind v                   — 그 징표가 있으면 남은 적 행동 수 +v
##   sure_crit                                — 이 공격은 크리 확정
##   multi n                                  — 이 공격을 n번으로 나눠 맞힘 (배율/n씩, 크리·난수는 회마다)
##   buff cat crit_rate + mark                — 대상에게 그 징표가 있을 때만 크리 확률 (모든 종류에 mark 조건을 쓸 수 있음)
##   debuff cat crit_taken                    — 이 적을 때리는 아군의 크리 확률 +v  ·  cat crit_down — 적의 크리 확률 −v (적 기본 크리 5%)
##   gauge who self                           — 자기 게이지: 행동이 끝나 0이 된 뒤 더해짐 (헛수고가 아님)
##   who "others"                             — 대상을 뺀 나머지 적 전체
## 버프 지속 "dur"은 대상이 행동을 N번 마칠 때까지(clock own). invincible·dmg_taken은 적 행동 N번(clock enemy).

const GAUGE_MAX := 1000.0
const CREDIT_MAX := 7
const BASIC_BONUS := 1 ## 기본 공격을 쓰면 더 주는 크레딧
const EQUIP_MAX := 4 ## 전투에 장착하는 마법 수 (2026-10-18 사용자: 4개)

const CRIT_BASE := 0.10
const CRIT_MULT := 1.5
const WEAK := 1.5
const SPECIAL := 1.2
const CAP := {"atk": 3.0, "crit_dmg": 3.0, "special": 2.0, "final": 1.0, "def_down": 0.5, "atk_down": 0.5, "dmg_taken": 1.0, "crit_rate": 0.9, "crit_taken": 0.5, "crit_down": 0.5}
const ENEMY_CRIT_BASE := 0.05 ## 적의 크리 확률 (크리 다운 디버프의 대상)
const DEF_MIN := 0.3
const DEF_MAX := 1.5
const RAND_LO := 0.95
const RAND_HI := 1.05

const ELEMENT_NAME := {"fire": "불", "water": "물", "bolt": "번개", "space": "공간", "sword": "검술", "time": "시간", "none": "무"}
const MARK_NAME := {"burn": "화상", "frost": "빙결", "shock": "감전"}
const CAT_NAME := {"atk": "공격력", "crit_dmg": "크리 데미지", "crit_rate": "크리 확률", "special": "특공", "final": "최종 데미지",
	"dmg_taken": "받는 피해", "element": "속성 부여", "def_down": "방어 다운", "atk_down": "공격력 다운", "invincible": "무적",
	"crit_taken": "받는 크리 확률", "crit_down": "크리 확률 다운"}
const ROLE_NAME := {"dealer": "딜러", "buffer": "버퍼", "caster": "술사", "special": "범용"}
const ELEMENT_COLOR := {"fire": Color("#ff8a3a"), "water": Color("#5ec8ff"), "bolt": Color("#ffe34a"), "space": Color("#b9a2ff"), "time": Color("#f2d27a"), "sword": Color("#f2eff7")}
## 편성 명단 순서 (속성별 딜러·버퍼·술사 → 무상성)
const ROSTER := ["ignis", "ember", "cinder", "undine", "nerei", "glacia", "fulgur", "astra", "tonan", "eska", "hora", "harpe"]

## 약점표: 적의 속성 → 약점인 공격 속성
const WEAK_TO := {"straw": "fire", "water": "bolt", "fire": "water", "bolt": "water", "ash": "", "none": ""}

const WITCHES := {
	"eska": {
		"name": "에스카", "title": "공간의 마녀 · 범용", "role": "special", "atk": 13000, "hp": 90000, "speed": 110, "def": 0.10,
		"element": "space", "special": true,
		"basic": {"name": "작은 균열", "mult": 1.0, "desc": "단일 1.0배. 차례를 넘기며 크레딧 +1"},
		"skills": ["crack", "void_gate", "leap", "seal", "gap", "compress", "doom", "stigma", "blackstar", "cradle"],
		"default": ["crack", "seal", "doom", "blackstar"],
		"color": Color("#b9a2ff"), "accent": Color("#f2eff7"),
	},
	"ignis": {
		"name": "이그니스", "title": "불의 마녀 · 딜러", "role": "dealer", "atk": 12000, "hp": 80000, "speed": 95, "def": 0.05,
		"element": "fire", "special": false,
		"basic": {"name": "불씨 튀김", "mult": 1.0, "mark": "burn", "mark_dur": 2, "desc": "단일 1.0배 + 화상(적 행동 2번). 크레딧 +1"},
		"skills": ["spark", "whip", "focus", "pillar", "meteor", "breath_of_fire", "ash_storm", "blaze", "sun_spear", "conflagration"],
		"default": ["spark", "focus", "pillar", "sun_spear"],
		"color": Color("#ff6a3d"), "accent": Color("#ffd27a"),
	},
	"ember": {
		"name": "엠버", "title": "불의 마녀 · 버퍼", "role": "buffer", "atk": 8000, "hp": 100000, "speed": 120, "def": 0.15,
		"element": "fire", "special": false,
		"basic": {"name": "불똥", "mult": 0.8, "desc": "단일 0.8배. 크레딧 +1"},
		"skills": ["flame_breath", "kindling", "bellows", "warmth", "blessing", "fire_wall", "stake", "god_descent", "share_ember", "sun_blessing"],
		"default": ["flame_breath", "bellows", "blessing", "god_descent"],
		"color": Color("#ffb347"), "accent": Color("#fff2dc"),
	},
	"cinder": {
		"name": "신더", "title": "불의 마녀 · 술사 (재)", "role": "caster", "atk": 10000, "hp": 90000, "speed": 105, "def": 0.10,
		"element": "fire", "special": false,
		"basic": {"name": "재 뿌리기", "mult": 0.9, "mark": "burn", "mark_dur": 2, "desc": "단일 0.9배 + 화상(적 행동 2번). 크레딧 +1"},
		"skills": ["ash_dust", "soot", "embers_left", "ember_wind", "black_smoke", "fire_ring", "ash_heap", "fire_brand", "cremation", "ash_oath"],
		"default": ["ash_dust", "ember_wind", "fire_brand", "ash_oath"],
		"color": Color("#c07a4a"), "accent": Color("#e8c9a0"),
	},
	"undine": {
		"name": "운디네", "title": "물의 마녀 · 딜러", "role": "dealer", "atk": 12000, "hp": 85000, "speed": 90, "def": 0.08,
		"element": "water", "special": false,
		"basic": {"name": "물살 치기", "mult": 1.0, "desc": "단일 1.0배. 크레딧 +1"},
		"skills": ["water_lance", "whirlpool", "deep_breath", "ice_break", "torrent", "still_water", "tidal_wave", "glacier", "abyss_lance", "deluge"],
		"default": ["water_lance", "deep_breath", "ice_break", "abyss_lance"],
		"color": Color("#3aa7ff"), "accent": Color("#dff6ff"),
	},
	"nerei": {
		"name": "네레이", "title": "물의 마녀 · 버퍼", "role": "buffer", "atk": 8000, "hp": 110000, "speed": 115, "def": 0.18,
		"element": "water", "special": false,
		"basic": {"name": "물방울", "mult": 0.8, "desc": "단일 0.8배. 크레딧 +1"},
		"skills": ["droplet", "water_cloak", "frost_breath", "spring", "current", "water_veil", "ice_nail", "high_tide", "sea_embrace", "ocean_blessing"],
		"default": ["droplet", "frost_breath", "current", "water_veil"],
		"color": Color("#8fd4ff"), "accent": Color("#f0fbff"),
	},
	"glacia": {
		"name": "글라시아", "title": "물의 마녀 · 술사 (서리)", "role": "caster", "atk": 10000, "hp": 95000, "speed": 100, "def": 0.12,
		"element": "water", "special": false,
		"basic": {"name": "서리 손끝", "mult": 0.9, "mark": "frost", "mark_dur": 2, "desc": "단일 0.9배 + 빙결(적 행동 2번). 크레딧 +1"},
		"skills": ["rime", "thin_ice", "icicle", "blizzard", "ice_wall", "freeze_over", "deep_freeze", "ice_coffin", "permafrost", "winter_oath"],
		"default": ["rime", "blizzard", "deep_freeze", "winter_oath"],
		"color": Color("#bfe9ff"), "accent": Color("#ffffff"),
	},
	"fulgur": {
		"name": "풀구르", "title": "번개의 마녀 · 딜러", "role": "dealer", "atk": 11500, "hp": 75000, "speed": 115, "def": 0.05,
		"element": "bolt", "special": false,
		"basic": {"name": "스파크 튕김", "mult": 1.0, "mark": "shock", "mark_dur": 2, "desc": "단일 1.0배 + 감전(적 행동 2번). 크레딧 +1"},
		"skills": ["spark_bolt", "chain_lightning", "charge_up", "thunderbolt", "flash", "haste", "thunderstorm", "lightning_strike", "thunder_lance", "storm_god"],
		"default": ["spark_bolt", "charge_up", "thunderbolt", "thunder_lance"],
		"color": Color("#ffe34a"), "accent": Color("#fffbe0"),
	},
	"astra": {
		"name": "아스트라", "title": "번개의 마녀 · 버퍼 (별)", "role": "buffer", "atk": 8000, "hp": 95000, "speed": 130, "def": 0.12,
		"element": "bolt", "special": false,
		"basic": {"name": "정전기", "mult": 0.8, "desc": "단일 0.8배. 크레딧 +1"},
		"skills": ["static", "lightning_cloak", "rod", "spur", "starlight", "gust", "bolt_nail", "overcharge", "lightning_share", "meteor_blessing"],
		"default": ["static", "rod", "starlight", "overcharge"],
		"color": Color("#c9a0ff"), "accent": Color("#fff6c8"),
	},
	"tonan": {
		"name": "토난", "title": "번개의 마녀 · 술사 (우레)", "role": "caster", "atk": 10500, "hp": 85000, "speed": 110, "def": 0.08,
		"element": "bolt", "special": false,
		"basic": {"name": "번개 바늘", "mult": 0.9, "mark": "shock", "mark_dur": 2, "desc": "단일 0.9배 + 감전(적 행동 2번). 크레딧 +1"},
		"skills": ["needle", "blackout", "volt", "thunder", "lightning_fence", "discharge", "shock_brand", "conduction", "thundercloud", "thunder_oath"],
		"default": ["needle", "thunder", "conduction", "thunder_oath"],
		"color": Color("#7a8cff"), "accent": Color("#ffe34a"),
	},
	"hora": {
		"name": "호라", "title": "시간의 마녀 · 버퍼", "role": "buffer", "atk": 9000, "hp": 95000, "speed": 125, "def": 0.12,
		"element": "time", "special": true,
		"basic": {"name": "초침 찌르기", "mult": 0.8, "desc": "단일 0.8배. 크레딧 +1"},
		"skills": ["second_hand", "stopped_clock", "rewind", "time_haste", "clock_hand", "hourglass", "once_more", "time_stop", "doomsday_clock", "turn_back"],
		"default": ["second_hand", "time_haste", "once_more", "turn_back"],
		"color": Color("#f2d27a"), "accent": Color("#fff8e0"),
	},
	"harpe": {
		"name": "하르페", "title": "검의 마녀 · 딜러", "role": "dealer", "atk": 14000, "hp": 75000, "speed": 100, "def": 0.05,
		"element": "sword", "special": true,
		"basic": {"name": "흑백 참격", "mult": 1.1, "desc": "단일 1.1배. 크레딧 +1"},
		"skills": ["bw_slash", "return_cut", "sword_dance", "flash_cut", "space_cut", "sword_ki", "heaven_split", "sword_wind", "doom_slash", "bw_dance"],
		"default": ["bw_slash", "sword_ki", "heaven_split", "doom_slash"],
		"color": Color("#f2eff7"), "accent": Color("#14081f"),
	},
}

const SKILLS := {
	# ── 에스카: 공간 · 무상성 · 범용 (공격 4 + 보조 6)
	"crack": {"name": "공허의 균열", "cost": 1, "kind": "attack", "target": "enemy", "mult": 2.0, "fx": "rift_small",
		"effects": [{"t": "debuff", "cat": "def_down", "v": 0.10, "dur": 2}],
		"desc": "2.0배 피해 + 방어 다운 10% (적 행동 2번)", "ref": "싼 단일기 + 가벼운 디버프"},
	"void_gate": {"name": "공허의 문", "cost": 2, "kind": "support", "target": "ally", "fx": "void_gate",
		"effects": [{"t": "buff", "cat": "final", "v": 0.30, "dur": 3}, {"t": "gauge", "v": 0.30}],
		"desc": "아군 1: 최종 데미지 +30% (행동 3번) + 행동 게이지 +30%", "ref": "공명·멀린의 단일 몰아주기 + 차례 당기기"},
	"leap": {"name": "틈새 도약", "cost": 2, "kind": "support", "target": "ally", "fx": "leap",
		"effects": [{"t": "gauge", "v": 0.50}, {"t": "credits", "v": 1}],
		"desc": "아군 1: 행동 게이지 +50% + 크레딧 +1", "ref": "스카디의 보구 충전 50% (자원을 한 명에게 넘김)"},
	"seal": {"name": "봉공", "cost": 3, "kind": "support", "target": "allies", "fx": "seal",
		"effects": [{"t": "invincible", "who": "allies", "dur": 1}, {"t": "credits", "who": "allies", "v": 1}],
		"desc": "아군 전체: 무적 (다음 적 행동 1번) + 크레딧 +1", "ref": "캐스토리아의 지키면서 채우기"},
	"gap": {"name": "세계의 틈", "cost": 3, "kind": "support", "target": "enemies", "fx": "gap",
		"effects": [{"t": "debuff", "who": "enemies", "cat": "def_down", "v": 0.20, "dur": 3}, {"t": "debuff", "who": "enemies", "cat": "atk_down", "v": 0.20, "dur": 2}],
		"desc": "적 전체: 방어 다운 20% (적 행동 3번) + 공격력 다운 20% (적 행동 2번)", "ref": "스카디·모르간의 광역 방어 다운"},
	"compress": {"name": "공간 압축", "cost": 3, "kind": "attack", "target": "enemy", "mult": 3.0, "fx": "compress",
		"effects": [{"t": "ignore_def"}],
		"desc": "3.0배 피해, 이 공격만 적 방어율 무시", "ref": "방어 무시 단일기 (단단한 적 전용)"},
	"doom": {"name": "종언", "cost": 4, "kind": "attack", "target": "enemy", "mult": 6.0, "fx": "doom",
		"effects": [{"t": "buff", "who": "self", "cat": "atk", "v": 0.40, "dur": 1, "pre": true}],
		"desc": "공격 직전 자신 공격력 +40% (행동 1번) → 6.0배 피해", "ref": "초인 오리온의 자가 버프 → 강타"},
	"stigma": {"name": "별의 성흔", "cost": 4, "kind": "support", "target": "ally", "fx": "stigma",
		"effects": [{"t": "buff", "cat": "crit_dmg", "v": 0.80, "dur": 3}, {"t": "buff", "cat": "crit_rate", "v": 0.50, "dur": 3}],
		"desc": "아군 1: 크리 데미지 +80% + 크리 확률 +50% (행동 3번)", "ref": "공명의 크리 데미지 · 멀린의 크리 위력"},
	"blackstar": {"name": "흑성", "cost": 5, "kind": "attack", "target": "enemies", "mult": 4.5, "fx": "blackstar",
		"effects": [{"t": "debuff", "who": "enemies", "cat": "def_down", "v": 0.20, "dur": 3}],
		"desc": "적 전체 4.5배 피해 + 방어 다운 20% (적 행동 3번)", "ref": "아르주나 얼터의 광역 보구 + 광역 디버프"},
	"cradle": {"name": "공허의 요람", "cost": 5, "kind": "support", "target": "ally_any", "fx": "cradle",
		"effects": [{"t": "revive", "pct": 0.50}, {"t": "credits", "v": 2}],
		"desc": "아군 1: 쓰러진 아군을 체력 50%로 되살림 (살아 있으면 50% 회복) + 크레딧 +2", "ref": "부활 (사용자 목록) — 속성을 타지 않는 특수 마녀의 보조"},

	# ── 이그니스: 불 · 공격 특화 (공격 8 + 보조 2)
	"spark": {"name": "불씨 찌르기", "cost": 1, "kind": "attack", "target": "enemy", "mult": 2.0, "fx": "fireball",
		"effects": [{"t": "mark", "kind": "burn", "dur": 3}],
		"desc": "2.0배 피해 + 화상 (적 행동 3번)", "ref": "징표 심기"},
	"whip": {"name": "화염 채찍", "cost": 2, "kind": "attack", "target": "enemy", "mult": 2.5, "fx": "whip",
		"effects": [{"t": "debuff", "cat": "atk_down", "v": 0.15, "dur": 2}],
		"desc": "2.5배 피해 + 적 공격력 다운 15% (적 행동 2번)", "ref": "모르간의 공격력 다운"},
	"focus": {"name": "열기 응축", "cost": 2, "kind": "support", "target": "self", "fx": "focus",
		"effects": [{"t": "buff", "who": "self", "cat": "atk", "v": 0.50, "dur": 2}, {"t": "buff", "who": "self", "cat": "crit_rate", "v": 0.30, "dur": 2}],
		"desc": "자신: 공격력 +50% + 크리 확률 +30% (행동 2번)", "ref": "딜러의 자가 버프 (초인 오리온 S3)"},
	"pillar": {"name": "솟구치는 불기둥", "cost": 3, "kind": "attack", "target": "enemy", "mult": 3.5, "fx": "pillar",
		"effects": [{"t": "this_special", "mark": "burn", "v": 0.50}],
		"desc": "3.5배 피해, 이 공격만 화상 특공 +50%", "ref": "아르주나 얼터의 디버프 적 특공"},
	"meteor": {"name": "유성 낙하", "cost": 3, "kind": "attack", "target": "enemy", "mult": 3.0, "fx": "meteor",
		"effects": [{"t": "debuff", "cat": "def_down", "v": 0.15, "dur": 2}, {"t": "mark", "kind": "burn", "dur": 2}],
		"desc": "3.0배 피해 + 방어 다운 15% (적 행동 2번) + 화상 (적 행동 2번)", "ref": "모르간의 방어 다운 + 징표"},
	"breath_of_fire": {"name": "불의 숨결", "cost": 3, "kind": "support", "target": "ally", "fx": "breath",
		"effects": [{"t": "buff", "cat": "crit_dmg", "v": 0.60, "dur": 2}, {"t": "buff", "cat": "crit_rate", "v": 0.30, "dur": 2}],
		"desc": "아군 1: 크리 데미지 +60% + 크리 확률 +30% (행동 2번)", "ref": "공명의 단일 크리 버프 (딜러도 남을 밀어 줄 수 있게)"},
	"ash_storm": {"name": "재의 폭풍", "cost": 4, "kind": "attack", "target": "enemies", "mult": 3.0, "fx": "ash_storm",
		"effects": [{"t": "mark", "who": "enemies", "kind": "burn", "dur": 3}],
		"desc": "적 전체 3.0배 피해 + 전체 화상 (적 행동 3번)", "ref": "모르간의 광역 보구 + 광역 징표"},
	"blaze": {"name": "폭염 개화", "cost": 4, "kind": "attack", "target": "enemy", "mult": 4.0, "fx": "blaze",
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
	"flame_breath": {"name": "따뜻한 입김", "cost": 1, "kind": "attack", "target": "enemy", "mult": 1.6, "fx": "fireball_small",
		"effects": [{"t": "mark", "kind": "burn", "dur": 3}],
		"desc": "1.6배 피해 + 화상 (적 행동 3번)", "ref": "버퍼도 징표를 심을 수 있게"},
	"kindling": {"name": "장작 얹기", "cost": 2, "kind": "support", "target": "ally", "fx": "kindling",
		"effects": [{"t": "buff", "cat": "element", "el": "fire", "dur": 3}, {"t": "buff", "cat": "crit_dmg", "v": 0.50, "dur": 3, "el": "fire"}],
		"desc": "아군 1: 공격에 화염 속성 부여 + 화염 공격 크리 데미지 +50% (행동 3번)", "ref": "사용자 예시 그대로 (무상성 딜러를 화염 딜러로)"},
	"bellows": {"name": "풀무질", "cost": 2, "kind": "support", "target": "ally", "fx": "bellows",
		"effects": [{"t": "buff", "cat": "special", "mark": "burn", "v": 0.50, "dur": 3}, {"t": "buff", "cat": "crit_rate", "v": 0.30, "dur": 3}],
		"desc": "아군 1: 화상 특공 +50% + 크리 확률 +30% (행동 3번)", "ref": "사용자 예시 그대로"},
	"warmth": {"name": "난로의 온기", "cost": 2, "kind": "support", "target": "allies", "fx": "warmth",
		"effects": [{"t": "heal", "who": "allies", "pct": 0.30}, {"t": "gauge", "who": "allies", "v": 0.20}],
		"desc": "아군 전체: 체력 30% 회복 + 행동 게이지 +20%", "ref": "멀린의 회복 + 보구 충전"},
	"blessing": {"name": "불의 축복", "cost": 3, "kind": "support", "target": "allies", "fx": "blessing",
		"effects": [{"t": "buff", "who": "allies", "cat": "atk", "v": 0.30, "dur": 3}, {"t": "credits", "who": "allies", "v": 1}],
		"desc": "아군 전체: 공격력 +30% (행동 3번) + 크레딧 +1", "ref": "캐스토리아·멀린의 전체 공격 버프 + 자원"},
	"fire_wall": {"name": "불막이 벽", "cost": 3, "kind": "support", "target": "allies", "fx": "fire_wall",
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

	# ── 신더: 불 · 술사 (공격 4 + 디버프 4 + 보조 2) — 화상을 오래·넓게
	"ash_dust": {"name": "재 뿌리기", "cost": 1, "kind": "debuff", "target": "enemy", "fx": "hex",
		"effects": [{"t": "mark", "kind": "burn", "dur": 4}, {"t": "debuff", "cat": "def_down", "v": 0.10, "dur": 2}],
		"desc": "화상 (적 행동 4번) + 방어 다운 10% (적 행동 2번)", "ref": "징표를 오래 깔기"},
	"soot": {"name": "그을음 안개", "cost": 2, "kind": "debuff", "target": "enemies", "fx": "hex_all",
		"effects": [{"t": "debuff", "who": "enemies", "cat": "atk_down", "v": 0.15, "dur": 2}, {"t": "debuff", "who": "enemies", "cat": "crit_down", "v": 0.15, "dur": 2}],
		"desc": "적 전체: 공격력 다운 15% + 크리 확률 다운 15% (적 행동 2번)", "ref": "모르간의 적 공격력·크리 다운"},
	"embers_left": {"name": "잉걸불 찌르기", "cost": 2, "kind": "attack", "target": "enemy", "mult": 2.5, "fx": "fireball",
		"effects": [{"t": "extend_mark", "kind": "burn", "v": 2}],
		"desc": "2.5배 피해. 화상 적이면 화상 연장 +2", "ref": "징표 연장"},
	"ember_wind": {"name": "불씨 바람", "cost": 3, "kind": "debuff", "target": "enemies", "fx": "ash_storm",
		"effects": [{"t": "mark", "who": "enemies", "kind": "burn", "dur": 3}, {"t": "debuff", "who": "enemies", "cat": "def_down", "v": 0.15, "dur": 3}],
		"desc": "적 전체: 화상 (적 행동 3번) + 방어 다운 15% (적 행동 3번)", "ref": "광역 징표 + 광역 디버프"},
	"black_smoke": {"name": "검은 연기 장막", "cost": 3, "kind": "support", "target": "allies", "fx": "fire_wall",
		"effects": [{"t": "buff", "who": "allies", "cat": "dmg_taken", "v": -0.30, "dur": 2}, {"t": "debuff", "who": "enemies", "cat": "atk_down", "v": 0.10, "dur": 2}],
		"desc": "아군 전체: 받는 피해 −30% (적 행동 2번) + 적 전체 공격력 다운 10% (적 행동 2번)", "ref": "멀린의 전체 보호"},
	"fire_ring": {"name": "불의 고리", "cost": 3, "kind": "attack", "target": "enemies", "mult": 2.5, "fx": "conflagration",
		"effects": [{"t": "this_special", "mark": "burn", "v": 0.30}],
		"desc": "적 전체 2.5배 피해, 화상 적에게 이 공격만 특공 +30%", "ref": "징표 적 광역 특공"},
	"ash_heap": {"name": "잿더미", "cost": 4, "kind": "debuff", "target": "enemy", "fx": "hex",
		"effects": [{"t": "debuff", "cat": "def_down", "v": 0.30, "dur": 3}, {"t": "buff", "who": "allies", "cat": "special", "mark": "burn", "v": 0.30, "dur": 2}],
		"desc": "적 1: 방어 다운 30% (적 행동 3번) + 아군 전체 화상 특공 +30% (행동 2번)", "ref": "코얀스카야의 특공 부여 + 모르간의 방어 다운"},
	"fire_brand": {"name": "불의 낙인", "cost": 4, "kind": "attack", "target": "enemy", "mult": 3.5, "fx": "stake",
		"effects": [{"t": "mark", "kind": "burn", "dur": 4}, {"t": "debuff", "cat": "crit_taken", "v": 0.20, "dur": 3}],
		"desc": "3.5배 피해 + 화상 (적 행동 4번) + 이 적을 때리는 아군 크리 확률 +20% (적 행동 3번)", "ref": "대상 조건 크리 확률"},
	"cremation": {"name": "장송의 불", "cost": 5, "kind": "attack", "target": "enemies", "mult": 4.0, "fx": "conflagration",
		"effects": [{"t": "extend_mark", "who": "enemies", "kind": "burn", "v": 2}, {"t": "this_special", "mark": "burn", "v": 0.50}],
		"desc": "적 전체 4.0배 피해, 화상 적마다 화상 연장 +2, 이 공격만 화상 특공 +50%", "ref": "징표를 터뜨리되 남겨 두기"},
	"ash_oath": {"name": "재의 맹세", "cost": 5, "kind": "support", "target": "allies", "fx": "sun_blessing",
		"effects": [{"t": "buff", "who": "allies", "cat": "special", "mark": "burn", "v": 0.40, "dur": 3}, {"t": "buff", "who": "allies", "cat": "atk", "v": 0.20, "dur": 3}, {"t": "credits", "who": "allies", "v": 1}],
		"desc": "아군 전체: 화상 특공 +40% + 공격력 +20% (행동 3번) + 크레딧 +1", "ref": "캐스토리아의 전체 버프 겹치기"},

	# ── 운디네: 물 · 딜러 (공격 8 + 보조 2) — 큰 물결 한 방 + 빙결로 늦추기
	"water_lance": {"name": "물의 창", "cost": 1, "kind": "attack", "target": "enemy", "mult": 2.0, "fx": "fireball",
		"effects": [{"t": "mark", "kind": "frost", "dur": 3}], "desc": "2.0배 피해 + 빙결 (적 행동 3번)", "ref": "징표 심기"},
	"whirlpool": {"name": "소용돌이 끌기", "cost": 2, "kind": "attack", "target": "enemy", "mult": 2.5, "fx": "whip",
		"effects": [{"t": "enemy_gauge", "v": 0.15, "frost_x2": true}], "desc": "2.5배 피해 + 적 게이지 −15% (빙결이면 −30%)", "ref": "지연"},
	"deep_breath": {"name": "깊은 들숨", "cost": 2, "kind": "support", "target": "self", "fx": "focus",
		"effects": [{"t": "buff", "who": "self", "cat": "atk", "v": 0.50, "dur": 2}, {"t": "buff", "who": "self", "cat": "final", "v": 0.15, "dur": 2}],
		"desc": "자신: 공격력 +50% + 최종 데미지 +15% (행동 2번)", "ref": "딜러의 자가 버프"},
	"ice_break": {"name": "쇄빙 일격", "cost": 3, "kind": "attack", "target": "enemy", "mult": 3.5, "fx": "pillar",
		"effects": [{"t": "this_special", "mark": "frost", "v": 0.50}], "desc": "3.5배 피해, 이 공격만 빙결 특공 +50%", "ref": "징표 터뜨리기"},
	"torrent": {"name": "격류", "cost": 3, "kind": "attack", "target": "enemy", "mult": 3.0, "fx": "meteor",
		"effects": [{"t": "debuff", "cat": "def_down", "v": 0.15, "dur": 2}, {"t": "mark", "kind": "frost", "dur": 2}],
		"desc": "3.0배 피해 + 방어 다운 15% (적 행동 2번) + 빙결 (적 행동 2번)", "ref": "모르간의 방어 다운 + 징표"},
	"still_water": {"name": "잔잔한 수면", "cost": 3, "kind": "support", "target": "ally", "fx": "breath",
		"effects": [{"t": "buff", "cat": "crit_dmg", "v": 0.60, "dur": 2}, {"t": "buff", "cat": "dmg_taken", "v": -0.20, "dur": 2}],
		"desc": "아군 1: 크리 데미지 +60% (행동 2번) + 받는 피해 −20% (적 행동 2번)", "ref": "공명의 단일 크리 버프 + 보호"},
	"tidal_wave": {"name": "해일", "cost": 4, "kind": "attack", "target": "enemies", "mult": 3.0, "fx": "ash_storm",
		"effects": [{"t": "mark", "who": "enemies", "kind": "frost", "dur": 3}], "desc": "적 전체 3.0배 피해 + 전체 빙결 (적 행동 3번)", "ref": "광역 보구 + 광역 징표"},
	"glacier": {"name": "빙하 붕괴", "cost": 4, "kind": "attack", "target": "enemy", "mult": 4.0, "fx": "blaze",
		"effects": [{"t": "buff", "who": "self", "cat": "special", "mark": "frost", "v": 0.30, "dur": 2, "pre": true}],
		"desc": "공격 직전 자신 빙결 특공 +30% (행동 2번) → 4.0배 피해", "ref": "초인 오리온의 특공 1턴"},
	"abyss_lance": {"name": "심해의 창", "cost": 5, "kind": "attack", "target": "enemy", "mult": 6.0, "fx": "sun_spear",
		"effects": [{"t": "buff", "who": "self", "cat": "atk", "v": 0.40, "dur": 1, "pre": true}, {"t": "gauge_zero", "if_mark": "frost"}],
		"desc": "공격 직전 자신 공격력 +40% (행동 1번) → 6.0배 피해. 빙결 적이면 적 게이지 0", "ref": "한 방 + 조건 보너스"},
	"deluge": {"name": "대홍수", "cost": 5, "kind": "attack", "target": "enemies", "mult": 4.0, "fx": "conflagration",
		"effects": [{"t": "this_special", "mark": "frost", "v": 0.80}, {"t": "enemy_gauge", "who": "enemies", "v": 0.20}],
		"desc": "적 전체 4.0배 피해, 이 공격만 빙결 특공 +80% + 적 전체 게이지 −20%", "ref": "광역 마무리 + 지연"},

	# ── 네레이: 물 · 버퍼 (보조 8 + 공격 2) — 지키고 되살리는 바다
	"droplet": {"name": "물방울 튕기기", "cost": 1, "kind": "attack", "target": "enemy", "mult": 1.6, "fx": "fireball_small",
		"effects": [{"t": "mark", "kind": "frost", "dur": 3}], "desc": "1.6배 피해 + 빙결 (적 행동 3번)", "ref": "버퍼의 징표"},
	"water_cloak": {"name": "물의 옷", "cost": 2, "kind": "support", "target": "ally", "fx": "kindling",
		"effects": [{"t": "buff", "cat": "element", "el": "water", "dur": 3}, {"t": "buff", "cat": "crit_dmg", "v": 0.50, "dur": 3, "el": "water"}],
		"desc": "아군 1: 공격에 물 속성 부여 + 물 공격 크리 데미지 +50% (행동 3번)", "ref": "속성 부여"},
	"frost_breath": {"name": "서리 숨결", "cost": 2, "kind": "support", "target": "ally", "fx": "bellows",
		"effects": [{"t": "buff", "cat": "special", "mark": "frost", "v": 0.50, "dur": 3}, {"t": "buff", "cat": "crit_rate", "v": 0.30, "dur": 3}],
		"desc": "아군 1: 빙결 특공 +50% + 크리 확률 +30% (행동 3번)", "ref": "코얀스카야의 특공 부여"},
	"spring": {"name": "샘물 붓기", "cost": 2, "kind": "support", "target": "ally", "fx": "warmth_one",
		"effects": [{"t": "heal", "pct": 0.50}, {"t": "buff", "cat": "dmg_taken", "v": -0.20, "dur": 2}],
		"desc": "아군 1: 체력 50% 회복 + 받는 피해 −20% (적 행동 2번)", "ref": "멀린의 회복"},
	"current": {"name": "밀려오는 조류", "cost": 3, "kind": "support", "target": "allies", "fx": "blessing",
		"effects": [{"t": "buff", "who": "allies", "cat": "atk", "v": 0.30, "dur": 3}, {"t": "credits", "who": "allies", "v": 1}],
		"desc": "아군 전체: 공격력 +30% (행동 3번) + 크레딧 +1", "ref": "캐스토리아의 전체 공격 버프 + 자원"},
	"water_veil": {"name": "물의 장막", "cost": 3, "kind": "support", "target": "allies", "fx": "seal",
		"effects": [{"t": "invincible", "who": "allies", "dur": 1}, {"t": "heal", "who": "allies", "pct": 0.15}],
		"desc": "아군 전체: 무적 (다음 적 행동 1번) + 체력 15% 회복", "ref": "멀린의 전체 무적"},
	"ice_nail": {"name": "얼음 못", "cost": 3, "kind": "attack", "target": "enemy", "mult": 2.5, "fx": "stake",
		"effects": [{"t": "debuff", "cat": "def_down", "v": 0.20, "dur": 3}, {"t": "mark", "kind": "frost", "dur": 3}],
		"desc": "2.5배 피해 + 방어 다운 20% (적 행동 3번) + 빙결 (적 행동 3번)", "ref": "버퍼의 디버프 공격"},
	"high_tide": {"name": "밀물", "cost": 4, "kind": "support", "target": "allies", "fx": "blessing",
		"effects": [{"t": "gauge", "who": "allies", "v": 0.40}, {"t": "buff", "who": "allies", "cat": "final", "v": 0.20, "dur": 2}],
		"desc": "아군 전체: 행동 게이지 +40% + 최종 데미지 +20% (행동 2번)", "ref": "전체 배터리"},
	"sea_embrace": {"name": "바다의 품", "cost": 4, "kind": "support", "target": "ally_any", "fx": "cradle",
		"effects": [{"t": "revive", "pct": 0.40}, {"t": "credits", "v": 1}],
		"desc": "아군 1: 되살림 40% (살아 있으면 40% 회복) + 크레딧 +1", "ref": "부활"},
	"ocean_blessing": {"name": "대해의 축복", "cost": 5, "kind": "support", "target": "allies", "fx": "sun_blessing",
		"effects": [{"t": "buff", "who": "allies", "cat": "crit_dmg", "v": 0.50, "dur": 3}, {"t": "buff", "who": "allies", "cat": "dmg_taken", "v": -0.30, "dur": 3}, {"t": "credits", "who": "allies", "v": 1}],
		"desc": "아군 전체: 크리 데미지 +50% (행동 3번) + 받는 피해 −30% (적 행동 3번) + 크레딧 +1", "ref": "전체 버프 겹치기"},

	# ── 글라시아: 물 · 술사 (공격 4 + 디버프 4 + 보조 2) — 얼려서 늦추기
	"rime": {"name": "서리 내림", "cost": 1, "kind": "debuff", "target": "enemy", "fx": "hex",
		"effects": [{"t": "mark", "kind": "frost", "dur": 4}, {"t": "enemy_gauge", "v": 0.10}],
		"desc": "빙결 (적 행동 4번) + 적 게이지 −10%", "ref": "징표 + 지연"},
	"thin_ice": {"name": "살얼음 깔기", "cost": 2, "kind": "debuff", "target": "enemies", "fx": "hex_all",
		"effects": [{"t": "debuff", "who": "enemies", "cat": "atk_down", "v": 0.15, "dur": 2}, {"t": "enemy_gauge", "who": "enemies", "v": 0.10, "frost_x2": true}],
		"desc": "적 전체: 공격력 다운 15% (적 행동 2번) + 게이지 −10% (빙결이면 −20%)", "ref": "광역 약화 + 지연"},
	"icicle": {"name": "고드름 투척", "cost": 2, "kind": "attack", "target": "enemy", "mult": 2.5, "fx": "fireball",
		"effects": [{"t": "mark", "kind": "frost", "dur": 2}], "desc": "2.5배 피해 + 빙결 (적 행동 2번)", "ref": "징표 심기"},
	"blizzard": {"name": "눈보라", "cost": 3, "kind": "debuff", "target": "enemies", "fx": "ash_storm",
		"effects": [{"t": "mark", "who": "enemies", "kind": "frost", "dur": 3}, {"t": "debuff", "who": "enemies", "cat": "def_down", "v": 0.15, "dur": 3}],
		"desc": "적 전체: 빙결 (적 행동 3번) + 방어 다운 15% (적 행동 3번)", "ref": "광역 징표 + 광역 디버프"},
	"ice_wall": {"name": "얼음 벽", "cost": 3, "kind": "support", "target": "allies", "fx": "fire_wall",
		"effects": [{"t": "buff", "who": "allies", "cat": "dmg_taken", "v": -0.40, "dur": 2}, {"t": "enemy_gauge", "who": "enemies", "v": 0.10}],
		"desc": "아군 전체: 받는 피해 −40% (적 행동 2번) + 적 전체 게이지 −10%", "ref": "보호 + 지연"},
	"freeze_over": {"name": "결빙 파동", "cost": 3, "kind": "attack", "target": "enemies", "mult": 2.5, "fx": "conflagration",
		"effects": [{"t": "this_special", "mark": "frost", "v": 0.30}], "desc": "적 전체 2.5배 피해, 빙결 적에게 이 공격만 특공 +30%", "ref": "징표 적 광역 특공"},
	"deep_freeze": {"name": "완전 동결", "cost": 4, "kind": "debuff", "target": "enemy", "fx": "hex",
		"effects": [{"t": "gauge_zero"}, {"t": "debuff", "cat": "def_down", "v": 0.30, "dur": 2}, {"t": "mark", "kind": "frost", "dur": 3}],
		"desc": "적 1: 게이지 0 + 방어 다운 30% (적 행동 2번) + 빙결 (적 행동 3번)", "ref": "차례 되돌리기"},
	"ice_coffin": {"name": "얼음 관", "cost": 4, "kind": "attack", "target": "enemy", "mult": 3.5, "fx": "stake",
		"effects": [{"t": "enemy_gauge", "v": 0.50, "if_mark": "frost"}, {"t": "debuff", "cat": "def_down", "v": 0.20, "dur": 2}],
		"desc": "3.5배 피해 + 방어 다운 20% (적 행동 2번). 빙결 적이면 게이지 −50%", "ref": "조건 지연"},
	"permafrost": {"name": "영구 동토", "cost": 5, "kind": "attack", "target": "enemies", "mult": 4.0, "fx": "conflagration",
		"effects": [{"t": "this_special", "mark": "frost", "v": 0.50}, {"t": "enemy_gauge", "who": "enemies", "v": 0.30}],
		"desc": "적 전체 4.0배 피해, 이 공격만 빙결 특공 +50% + 적 전체 게이지 −30%", "ref": "광역 마무리 + 지연"},
	"winter_oath": {"name": "겨울의 맹세", "cost": 5, "kind": "support", "target": "allies", "fx": "sun_blessing",
		"effects": [{"t": "buff", "who": "allies", "cat": "special", "mark": "frost", "v": 0.40, "dur": 3}, {"t": "buff", "who": "allies", "cat": "dmg_taken", "v": -0.20, "dur": 3}, {"t": "credits", "who": "allies", "v": 1}],
		"desc": "아군 전체: 빙결 특공 +40% (행동 3번) + 받는 피해 −20% (적 행동 3번) + 크레딧 +1", "ref": "전체 버프 겹치기"},

	# ── 풀구르: 번개 · 딜러 (공격 8 + 보조 2) — 빠른 크리 한 방
	"spark_bolt": {"name": "전광 스파크", "cost": 1, "kind": "attack", "target": "enemy", "mult": 2.0, "fx": "fireball",
		"effects": [{"t": "mark", "kind": "shock", "dur": 3}], "desc": "2.0배 피해 + 감전 (적 행동 3번)", "ref": "징표 심기"},
	"chain_lightning": {"name": "연쇄 번개", "cost": 2, "kind": "attack", "target": "enemies", "mult": 1.4, "fx": "ash_storm",
		"effects": [{"t": "mark", "who": "enemies", "kind": "shock", "dur": 2}], "desc": "적 전체 1.4배 피해 + 전체 감전 (적 행동 2번)", "ref": "싼 광역 (배율 낮음)"},
	"charge_up": {"name": "충전", "cost": 2, "kind": "support", "target": "self", "fx": "focus",
		"effects": [{"t": "buff", "who": "self", "cat": "crit_rate", "v": 0.40, "dur": 2}, {"t": "buff", "who": "self", "cat": "crit_dmg", "v": 0.40, "dur": 2}],
		"desc": "자신: 크리 확률 +40% + 크리 데미지 +40% (행동 2번)", "ref": "딜러의 자가 크리 버프"},
	"thunderbolt": {"name": "벼락 내리꽂기", "cost": 3, "kind": "attack", "target": "enemy", "mult": 3.5, "fx": "pillar",
		"effects": [{"t": "this_special", "mark": "shock", "v": 0.50}], "desc": "3.5배 피해, 이 공격만 감전 특공 +50%", "ref": "징표 터뜨리기"},
	"flash": {"name": "섬광 질주", "cost": 3, "kind": "attack", "target": "enemy", "mult": 3.0, "fx": "whip",
		"effects": [{"t": "gauge", "who": "self", "v": 0.30}, {"t": "mark", "kind": "shock", "dur": 2}],
		"desc": "3.0배 피해 + 자신 게이지 +30% + 감전 (적 행동 2번)", "ref": "속도"},
	"haste": {"name": "가속 바람", "cost": 3, "kind": "support", "target": "ally", "fx": "leap",
		"effects": [{"t": "gauge", "v": 0.50}, {"t": "buff", "cat": "crit_rate", "v": 0.30, "dur": 2}],
		"desc": "아군 1: 행동 게이지 +50% + 크리 확률 +30% (행동 2번)", "ref": "스카디의 배터리 + 크리"},
	"thunderstorm": {"name": "뇌우", "cost": 4, "kind": "attack", "target": "enemies", "mult": 3.0, "fx": "ash_storm",
		"effects": [{"t": "mark", "who": "enemies", "kind": "shock", "dur": 3}], "desc": "적 전체 3.0배 피해 + 전체 감전 (적 행동 3번)", "ref": "광역 보구 + 광역 징표"},
	"lightning_strike": {"name": "낙뢰 심판", "cost": 4, "kind": "attack", "target": "enemy", "mult": 4.0, "fx": "meteor",
		"effects": [{"t": "buff", "who": "self", "cat": "crit_rate", "mark": "shock", "v": 0.50, "dur": 2, "pre": true}],
		"desc": "공격 직전 자신 감전 적 크리 확률 +50% (행동 2번) → 4.0배 피해", "ref": "조건 크리"},
	"thunder_lance": {"name": "천둥의 창", "cost": 5, "kind": "attack", "target": "enemy", "mult": 6.0, "fx": "sun_spear",
		"effects": [{"t": "buff", "who": "self", "cat": "crit_dmg", "v": 0.50, "dur": 1, "pre": true}, {"t": "on_crit", "effects": [{"t": "gauge", "who": "self", "v": 0.50}]}],
		"desc": "공격 직전 자신 크리 데미지 +50% (행동 1번) → 6.0배 피해. 크리면 자신 게이지 +50%", "ref": "한 방 + 크리 조건 보너스"},
	"storm_god": {"name": "뇌신 강림", "cost": 5, "kind": "attack", "target": "enemies", "mult": 4.0, "fx": "conflagration",
		"effects": [{"t": "multi", "n": 3}, {"t": "this_special", "mark": "shock", "v": 0.60}],
		"desc": "적 전체 4.0배 피해를 3번으로 나눠 (각 1.33배) + 이 공격만 감전 특공 +60%", "ref": "다단 히트 광역 마무리"},

	# ── 아스트라: 번개 · 버퍼 (보조 8 + 공격 2) — 차례 당기기
	"static": {"name": "정전기 튕기기", "cost": 1, "kind": "attack", "target": "enemy", "mult": 1.6, "fx": "fireball_small",
		"effects": [{"t": "mark", "kind": "shock", "dur": 3}], "desc": "1.6배 피해 + 감전 (적 행동 3번)", "ref": "버퍼의 징표"},
	"lightning_cloak": {"name": "번개 옷", "cost": 2, "kind": "support", "target": "ally", "fx": "kindling",
		"effects": [{"t": "buff", "cat": "element", "el": "bolt", "dur": 3}, {"t": "buff", "cat": "crit_dmg", "v": 0.50, "dur": 3, "el": "bolt"}],
		"desc": "아군 1: 공격에 번개 속성 부여 + 번개 공격 크리 데미지 +50% (행동 3번)", "ref": "속성 부여"},
	"rod": {"name": "피뢰침 세우기", "cost": 2, "kind": "support", "target": "ally", "fx": "bellows",
		"effects": [{"t": "buff", "cat": "special", "mark": "shock", "v": 0.50, "dur": 3}, {"t": "buff", "cat": "crit_rate", "v": 0.30, "dur": 3}],
		"desc": "아군 1: 감전 특공 +50% + 크리 확률 +30% (행동 3번)", "ref": "특공 부여"},
	"spur": {"name": "박차 가하기", "cost": 2, "kind": "support", "target": "ally", "fx": "leap",
		"effects": [{"t": "gauge", "v": 0.60}], "desc": "아군 1: 행동 게이지 +60%", "ref": "스카디의 배터리"},
	"starlight": {"name": "별빛 가루", "cost": 3, "kind": "support", "target": "allies", "fx": "blessing",
		"effects": [{"t": "buff", "who": "allies", "cat": "crit_rate", "v": 0.30, "dur": 3}, {"t": "buff", "who": "allies", "cat": "crit_dmg", "v": 0.30, "dur": 3}],
		"desc": "아군 전체: 크리 확률 +30% + 크리 데미지 +30% (행동 3번)", "ref": "전체 크리 버프"},
	"gust": {"name": "돌풍", "cost": 3, "kind": "support", "target": "allies", "fx": "blessing",
		"effects": [{"t": "gauge", "who": "allies", "v": 0.30}, {"t": "credits", "who": "allies", "v": 1}],
		"desc": "아군 전체: 행동 게이지 +30% + 크레딧 +1", "ref": "전체 배터리 + 자원"},
	"bolt_nail": {"name": "벼락 못", "cost": 3, "kind": "attack", "target": "enemy", "mult": 2.5, "fx": "stake",
		"effects": [{"t": "debuff", "cat": "def_down", "v": 0.20, "dur": 3}, {"t": "mark", "kind": "shock", "dur": 3}],
		"desc": "2.5배 피해 + 방어 다운 20% (적 행동 3번) + 감전 (적 행동 3번)", "ref": "버퍼의 디버프 공격"},
	"overcharge": {"name": "별빛 역류", "cost": 4, "kind": "support", "target": "ally", "fx": "god_descent",
		"effects": [{"t": "buff", "cat": "crit_dmg", "v": 1.00, "dur": 1}, {"t": "buff", "cat": "crit_rate", "v": 0.50, "dur": 1}, {"t": "gauge", "v": 1.00}, {"t": "demerit_zero"}],
		"desc": "아군 1: 크리 데미지 +100% + 크리 확률 +50% (행동 1번) + 게이지 100%. 대가: 그 행동 뒤 크레딧 0", "ref": "오베론의 한 번 크게"},
	"lightning_share": {"name": "번개 나눔", "cost": 4, "kind": "support", "target": "ally", "fx": "share_ember",
		"effects": [{"t": "credits", "v": 3}, {"t": "gauge", "v": 0.30}], "desc": "아군 1: 크레딧 +3 + 행동 게이지 +30%", "ref": "자원 몰아주기"},
	"meteor_blessing": {"name": "유성우의 축복", "cost": 5, "kind": "support", "target": "allies", "fx": "sun_blessing",
		"effects": [{"t": "buff", "who": "allies", "cat": "atk", "v": 0.30, "dur": 3}, {"t": "buff", "who": "allies", "cat": "crit_dmg", "v": 0.50, "dur": 3}, {"t": "gauge", "who": "allies", "v": 0.20}],
		"desc": "아군 전체: 공격력 +30% + 크리 데미지 +50% (행동 3번) + 행동 게이지 +20%", "ref": "전체 버프 겹치기"},

	# ── 토난: 번개 · 술사 (공격 4 + 디버프 4 + 보조 2) — 감전 깔고 크리 꽂기
	"needle": {"name": "번개 바늘", "cost": 1, "kind": "debuff", "target": "enemy", "fx": "hex",
		"effects": [{"t": "mark", "kind": "shock", "dur": 4}, {"t": "debuff", "cat": "def_down", "v": 0.10, "dur": 2}],
		"desc": "감전 (적 행동 4번) + 방어 다운 10% (적 행동 2번)", "ref": "징표를 오래 깔기"},
	"blackout": {"name": "정전 그물", "cost": 2, "kind": "debuff", "target": "enemies", "fx": "hex_all",
		"effects": [{"t": "debuff", "who": "enemies", "cat": "atk_down", "v": 0.15, "dur": 2}, {"t": "debuff", "who": "enemies", "cat": "crit_down", "v": 0.20, "dur": 2}],
		"desc": "적 전체: 공격력 다운 15% + 크리 확률 다운 20% (적 행동 2번)", "ref": "광역 약화"},
	"volt": {"name": "뇌격", "cost": 2, "kind": "attack", "target": "enemy", "mult": 2.5, "fx": "fireball",
		"effects": [{"t": "extend_mark", "kind": "shock", "v": 2}], "desc": "2.5배 피해. 감전 적이면 감전 연장 +2", "ref": "징표 연장"},
	"thunder": {"name": "우레 선포", "cost": 3, "kind": "debuff", "target": "enemies", "fx": "hex_all",
		"effects": [{"t": "mark", "who": "enemies", "kind": "shock", "dur": 3}, {"t": "debuff", "who": "enemies", "cat": "def_down", "v": 0.15, "dur": 3}],
		"desc": "적 전체: 감전 (적 행동 3번) + 방어 다운 15% (적 행동 3번)", "ref": "광역 징표 + 광역 디버프"},
	"lightning_fence": {"name": "번개 울타리", "cost": 3, "kind": "support", "target": "allies", "fx": "fire_wall",
		"effects": [{"t": "buff", "who": "allies", "cat": "dmg_taken", "v": -0.30, "dur": 2}, {"t": "gauge", "who": "allies", "v": 0.15}],
		"desc": "아군 전체: 받는 피해 −30% (적 행동 2번) + 행동 게이지 +15%", "ref": "보호 + 속도"},
	"discharge": {"name": "방전 파도", "cost": 3, "kind": "attack", "target": "enemies", "mult": 2.5, "fx": "conflagration",
		"effects": [{"t": "this_special", "mark": "shock", "v": 0.30}], "desc": "적 전체 2.5배 피해, 감전 적에게 이 공격만 특공 +30%", "ref": "징표 적 광역 특공"},
	"shock_brand": {"name": "감전 낙인", "cost": 4, "kind": "debuff", "target": "enemy", "fx": "hex",
		"effects": [{"t": "debuff", "cat": "def_down", "v": 0.30, "dur": 3}, {"t": "debuff", "cat": "crit_taken", "v": 0.30, "dur": 3}],
		"desc": "적 1: 방어 다운 30% + 이 적을 때리는 아군 크리 확률 +30% (적 행동 3번)", "ref": "대상 조건 크리"},
	"conduction": {"name": "전도 사슬", "cost": 4, "kind": "attack", "target": "enemy", "mult": 3.5, "fx": "meteor",
		"effects": [{"t": "mark", "kind": "shock", "dur": 4}, {"t": "mark", "who": "others", "kind": "shock", "dur": 2}],
		"desc": "3.5배 피해 + 감전 (적 행동 4번) + 다른 적 전체 감전 (적 행동 2번)", "ref": "징표 번지기"},
	"thundercloud": {"name": "뇌운", "cost": 5, "kind": "attack", "target": "enemies", "mult": 4.0, "fx": "ash_storm",
		"effects": [{"t": "extend_mark", "who": "enemies", "kind": "shock", "v": 2}, {"t": "this_special", "mark": "shock", "v": 0.50}],
		"desc": "적 전체 4.0배 피해, 감전 적마다 감전 연장 +2, 이 공격만 감전 특공 +50%", "ref": "징표를 터뜨리되 남겨 두기"},
	"thunder_oath": {"name": "우레의 맹세", "cost": 5, "kind": "support", "target": "allies", "fx": "sun_blessing",
		"effects": [{"t": "buff", "who": "allies", "cat": "special", "mark": "shock", "v": 0.40, "dur": 3}, {"t": "buff", "who": "allies", "cat": "crit_rate", "v": 0.20, "dur": 3}, {"t": "credits", "who": "allies", "v": 1}],
		"desc": "아군 전체: 감전 특공 +40% + 크리 확률 +20% (행동 3번) + 크레딧 +1", "ref": "전체 버프 겹치기"},

	# ── 호라: 시간 · 버퍼 (보조 7 + 공격 3) — 차례를 되감고 늘림
	"second_hand": {"name": "초침 밀기", "cost": 1, "kind": "support", "target": "ally", "fx": "leap",
		"effects": [{"t": "gauge", "v": 0.20}], "desc": "아군 1: 행동 게이지 +20%", "ref": "작은 배터리"},
	"stopped_clock": {"name": "멈춘 시계", "cost": 2, "kind": "debuff", "target": "enemy", "fx": "hex",
		"effects": [{"t": "enemy_gauge", "v": 0.40}, {"t": "debuff", "cat": "atk_down", "v": 0.10, "dur": 2}],
		"desc": "적 1: 게이지 −40% + 공격력 다운 10% (적 행동 2번)", "ref": "지연"},
	"rewind": {"name": "되감기", "cost": 2, "kind": "support", "target": "ally", "fx": "warmth_one",
		"effects": [{"t": "heal", "pct": 0.25}, {"t": "extend_buffs", "v": 1}], "desc": "아군 1: 체력 25% 회복 + 버프 지속 +1", "ref": "지속 연장"},
	"time_haste": {"name": "시간 가속", "cost": 3, "kind": "support", "target": "allies", "fx": "blessing",
		"effects": [{"t": "gauge", "who": "allies", "v": 0.25}, {"t": "credits", "who": "allies", "v": 1}],
		"desc": "아군 전체: 행동 게이지 +25% + 크레딧 +1", "ref": "전체 배터리 + 자원"},
	"clock_hand": {"name": "시계 바늘 찌르기", "cost": 3, "kind": "attack", "target": "enemy", "mult": 3.0, "fx": "compress",
		"effects": [{"t": "enemy_gauge", "v": 0.20}], "desc": "3.0배 피해 + 적 게이지 −20%", "ref": "공격 + 지연"},
	"hourglass": {"name": "모래시계 뒤집기", "cost": 3, "kind": "support", "target": "ally", "fx": "stigma",
		"effects": [{"t": "extend_buffs", "v": 2}, {"t": "buff", "cat": "final", "v": 0.20, "dur": 2}],
		"desc": "아군 1: 버프 지속 +2 + 최종 데미지 +20% (행동 2번)", "ref": "지속 연장"},
	"once_more": {"name": "한 번 더", "cost": 4, "kind": "support", "target": "ally", "fx": "void_gate",
		"effects": [{"t": "gauge", "v": 1.00}, {"t": "credits", "v": 1}], "desc": "아군 1: 행동 게이지 +100% + 크레딧 +1 (바로 다시 행동)", "ref": "차례 당기기"},
	"time_stop": {"name": "시간 정지", "cost": 4, "kind": "debuff", "target": "enemies", "fx": "gap",
		"effects": [{"t": "enemy_gauge", "who": "enemies", "v": 0.30}, {"t": "debuff", "who": "enemies", "cat": "def_down", "v": 0.20, "dur": 2}],
		"desc": "적 전체: 게이지 −30% + 방어 다운 20% (적 행동 2번)", "ref": "광역 지연 + 디버프"},
	"doomsday_clock": {"name": "종말의 시계", "cost": 5, "kind": "attack", "target": "enemies", "mult": 4.0, "fx": "blackstar",
		"effects": [{"t": "enemy_gauge", "who": "enemies", "v": 0.50}], "desc": "적 전체 4.0배 피해 + 적 전체 게이지 −50%", "ref": "광역 + 차례 되돌리기"},
	"turn_back": {"name": "시간 되돌림", "cost": 5, "kind": "support", "target": "ally_any", "fx": "cradle",
		"effects": [{"t": "revive", "pct": 0.70}, {"t": "extend_buffs", "v": 2}, {"t": "credits", "v": 1}],
		"desc": "아군 1: 되살림 70% (살아 있으면 70% 회복) + 버프 지속 +2 + 크레딧 +1", "ref": "부활 + 연장"},

	# ── 하르페: 검술 · 딜러 (공격 9 + 보조 1) — 흑백 참격 (실시간 데모 이펙트)
	"bw_slash": {"name": "흑백 참격", "cost": 1, "kind": "attack", "target": "enemy", "mult": 2.0, "fx": "slash",
		"effects": [{"t": "multi", "n": 2}], "desc": "2.0배 피해를 2번으로 나눠 (각 1.0배)", "ref": "다단 히트"},
	"return_cut": {"name": "되돌려 베기", "cost": 2, "kind": "attack", "target": "enemy", "mult": 2.5, "fx": "slash",
		"effects": [{"t": "buff", "who": "self", "cat": "crit_rate", "v": 0.30, "dur": 2}], "desc": "2.5배 피해 + 자신 크리 확률 +30% (행동 2번)", "ref": "공격 뒤 자가 버프"},
	"sword_dance": {"name": "검무", "cost": 2, "kind": "attack", "target": "enemies", "mult": 1.4, "fx": "slash_all",
		"effects": [{"t": "multi", "n": 2}], "desc": "적 전체 1.4배 피해를 2번으로 나눠 (각 0.7배)", "ref": "싼 광역 다단"},
	"flash_cut": {"name": "일섬", "cost": 3, "kind": "attack", "target": "enemy", "mult": 3.0, "fx": "slash_big",
		"effects": [{"t": "sure_crit"}], "desc": "3.0배 피해, 크리 확정", "ref": "크리 확정"},
	"space_cut": {"name": "공간참", "cost": 3, "kind": "attack", "target": "enemy", "mult": 3.0, "fx": "slash_big",
		"effects": [{"t": "ignore_def"}, {"t": "debuff", "cat": "def_down", "v": 0.15, "dur": 2}],
		"desc": "3.0배 피해, 이 공격만 적 방어율 무시 + 방어 다운 15% (적 행동 2번)", "ref": "방어 무시"},
	"sword_ki": {"name": "검기 두르기", "cost": 3, "kind": "support", "target": "self", "fx": "focus",
		"effects": [{"t": "buff", "who": "self", "cat": "atk", "v": 0.40, "dur": 2}, {"t": "buff", "who": "self", "cat": "crit_dmg", "v": 0.40, "dur": 2}],
		"desc": "자신: 공격력 +40% + 크리 데미지 +40% (행동 2번)", "ref": "딜러의 자가 버프"},
	"heaven_split": {"name": "천열", "cost": 4, "kind": "attack", "target": "enemy", "mult": 4.0, "fx": "slash_big",
		"effects": [{"t": "buff", "who": "self", "cat": "crit_dmg", "v": 0.50, "dur": 2, "pre": true}],
		"desc": "공격 직전 자신 크리 데미지 +50% (행동 2번) → 4.0배 피해", "ref": "선버프 강타"},
	"sword_wind": {"name": "검풍", "cost": 4, "kind": "attack", "target": "enemies", "mult": 3.0, "fx": "slash_all",
		"effects": [{"t": "multi", "n": 3}, {"t": "debuff", "who": "enemies", "cat": "def_down", "v": 0.15, "dur": 2}],
		"desc": "적 전체 3.0배 피해를 3번으로 나눠 + 방어 다운 15% (적 행동 2번)", "ref": "광역 다단 + 디버프"},
	"doom_slash": {"name": "종언참", "cost": 5, "kind": "attack", "target": "enemy", "mult": 6.0, "fx": "slash_doom",
		"effects": [{"t": "sure_crit"}, {"t": "buff", "who": "self", "cat": "atk", "v": 0.40, "dur": 1, "pre": true}],
		"desc": "크리 확정 + 공격 직전 자신 공격력 +40% (행동 1번) → 6.0배 피해", "ref": "한 방"},
	"bw_dance": {"name": "흑백 난무", "cost": 5, "kind": "attack", "target": "enemies", "mult": 4.5, "fx": "slash_all_big",
		"effects": [{"t": "multi", "n": 3}, {"t": "on_crit", "effects": [{"t": "gauge", "who": "self", "v": 0.30}]}],
		"desc": "적 전체 4.5배 피해를 3번으로 나눠 (각 1.5배). 크리면 자신 게이지 +30%", "ref": "광역 다단 마무리"},
}

## 장비 (캐릭터당 1개). 칸: skill_final(공격 마법 최종 데미지) · final(모든 공격 최종) · dmg_taken(받는 피해 ±) · start_credits · credits_per_turn(차례마다 더)
## atk(공격력 ±) · hp(체력 ±) · speed(+) · start_gauge(시작 게이지 0~1) · element(공격 속성 상시 부여) · crit_rate · crit_dmg
## special(징표가 있는 적에게 특공) · buff_extra(받는 버프 지속 +N) · mark_extra(내가 거는 징표 지속 +N)
const EQUIPS := {
	"": {"name": "없음", "desc": "장비 없음"},
	"black_cup": {"name": "검은 잔", "desc": "공격 마법 피해 +60% · 받는 피해 +30%", "skill_final": 0.60, "dmg_taken": 0.30},
	"kaleido": {"name": "만화경", "desc": "전투 시작 시 크레딧 7 (가득)", "start_credits": 7},
	"notebook": {"name": "마녀의 수첩", "desc": "시작 크레딧 +3 · 공격력 +20%", "start_credits": 3, "atk": 0.20},
	"swift_boots": {"name": "바람 신발", "desc": "시작 게이지 80% (첫 차례가 빨리) · 속도 +10", "start_gauge": 0.8, "speed": 10},
	"mana_spring": {"name": "마력 샘", "desc": "차례마다 크레딧 +2 (기본 +1에 +1) · 공격력 −20%", "credits_per_turn": 1, "atk": -0.20},
	"ember_ring": {"name": "불씨 반지", "desc": "공격에 화염 속성 상시 부여 (버퍼 없이 화염 딜러)", "element": "fire"},
	"tide_ring": {"name": "조류 반지", "desc": "공격에 물 속성 상시 부여", "element": "water"},
	"storm_ring": {"name": "뇌운 반지", "desc": "공격에 번개 속성 상시 부여", "element": "bolt"},
	"mirror_shard": {"name": "거울 조각", "desc": "크리 확률 +25%", "crit_rate": 0.25},
	"star_shard": {"name": "별 조각", "desc": "최종 데미지 +20% (기본 공격 포함) · 크리 데미지 +30%", "final": 0.20, "crit_dmg": 0.30},
	"iron_heart": {"name": "강철 심장", "desc": "체력 +30% · 받는 피해 −15%", "hp": 0.30, "dmg_taken": -0.15},
	"hourglass_charm": {"name": "모래시계 펜던트", "desc": "받는 버프의 지속 +1 행동", "buff_extra": 1},
	"ash_charm": {"name": "재의 부적", "desc": "내가 거는 징표 지속 +1 · 징표가 있는 적에게 특공 +20%", "mark_extra": 1, "special": 0.20},
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
