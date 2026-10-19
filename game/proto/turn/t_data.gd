class_name TData
extends RefCounted
## 턴제 전투 프로토타입 데이터 (docs/eska-turn/combat_proto.md). 숫자는 전부 여기에만 둔다 — 코드는 이 표를 읽기만 한다.
##
## 마녀 12명 · 마법 120개 + 대마법 12 · 패시브 12 · 장비 15개 · 적 14 + 보스 3 + 시련 1 · 전투 10 + 안내 1 (단계 B: witches_12.md §0~§3 속성별 플레이스타일 · 단계 F-2: review_H_enemies.md).
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
##   [단계 A 2026-10-18, combat_proto.md 1.0]
##   mark ... [n]                             — n겹 (기본 1, 최대 MARK_MAX). 남은 수 = max(지금, dur + 장비 mark_extra)
##   burst mark per                           — 터뜨리기: 대상의 그 징표 겹 N만큼 배율 +per×N, 맞힌 뒤 그 징표 제거 (§17.1)
##   debuff·enemy_gauge·gauge_zero [rate]     — 성공률 rate(기본 1.0) − 적 내성 (§16.5). 실패 = "저항"
##   stun who [if_mark]                       — 기절: 다음 차례 1번을 쉼 (보스·stun_immune은 면역, §17.2)
##   taunt who dur                            — 도발 (적 행동 N번): 적의 단일 대상 행동을 끌어옴 (§17.3)
##   guts who dur pct                         — 근성 1회 (적 행동 N번 안): 쓰러질 피해를 체력 pct(0이면 1)로 버팀 (§17.4)
##   who "other_allies" · "dead_allies"       — 자신을 뺀 살아 있는 아군 전체 · 쓰러진 아군 전체(되살림용)
##   마법 "ultimate": true                    — 대마법 (비용 7 = 크레딧 전부, 장착하지 않음, §13)
##   [단계 B 2026-10-18, combat_proto.md 1.2 — 속성별 플레이스타일·빌드 원형]
##   buff ... count N on(basic|skill|attack) — 횟수제: 그 종류의 행동(기본 공격 | 공격 마법 | 둘 다)을 N번 마치면 사라짐 (dur와 함께면 먼저 닿는 쪽, 건 차례엔 닳지 않음, §16.8)
##   buff/debuff ... mark per_mark            — 대상의 그 징표 겹 수를 곱한다 (특공은 늘 곱함)
##   this_special mark v                      — 이 공격만 특공: 그 징표가 있으면 v (겹을 곱하지 않는 고정값, §11.4)
##   this_special trait v                     — 특성 특공 (F-3): 대상이 그 특성(TRAIT_NAME)을 가지면 v (TBattle.special_hits)
##   credits ... if_mark                      — 맞기 전 대상에게 그 징표가 있었을 때만 (물의 환급, §12.7)
##   crit_gauge v                             — 이 공격의 크리 히트 1번마다 자신 게이지 +v (번개, §17.10)
##   enemy_charge who v [rate]                — 적 차지 −v (성공 판정, 필살기가 보이던 중이면 거둬짐, §18.5)
##   hp_cost who pct                          — 대가: 체력 −최대 × pct (1 아래로 안 감, 불, §17.9)
##   spread kind                              — 대상의 그 징표 겹 수만큼 다른 적 전체에 (§17.1)
##   hit_stack who v max dur stack_dur to     — 맞으며 쌓기: 적 행동 dur번 동안 맞을 때마다 to(self|allies)에게 공격력 +v 한 겹 (§17.11)
##   기본 공격 "hits": N                      — 배율을 N번으로 나눠 맞힘 (히트마다 크리 판정)
##   마법 "fit": 글                          — "어울림" 한 줄 (S-02 설명 상자): 같은 속성 파티 측정에선 안 쓰이고 그 조건·파티에서만 사는 칸 (R2, §27.11)
##   [단계 F-4 2026-10-18, combat_proto.md 2.0 — review_J_skills.md]
##   특공(special + mark)은 공격 속성이 그 징표의 속성(MARK_EL)일 때만 겹을 곱한다 — 다른 속성이면 1겹 값 (P1, §11.4)
##   regen who pct dur                        — 지속 회복: 받은 아군이 행동을 마칠 때마다 최대 체력 × pct 회복 (행동 dur번, §17.6)
##   buff cat ult_dmg                         — 대마법 위력: 대마법 공격의 피해에만 따로 곱함 (배터리 마법의 몫, §13.3)
##   debuff cat crit_dmg_taken [mark per_mark] — 이 적을 때리는 아군 크리 데미지 +v (크리 데미지 상한과 따로, 과전류)
##   hp_bonus v at                            — 이 공격만: 적 체력(지금 줄)이 at 넘게 남았을수록 피해 × (1 + v × (비율 − at) / (1 − at)) (이그니스, §11.4)
##   burst ... keep                           — 터뜨리기 배율은 더하되 징표는 남김 (대화재)
##   multi n per_mark kind                    — 히트 수 = n + 대상의 그 징표 겹 (낙뢰 심판)
##   mark·enemy_charge ... if_mark            — 맞기 전 대상에게 그 징표가 있었을 때만
##   stun ... else_charge n                   — 기절 면역(보스)이면 대신 차지 −n
##   stun ... else_debuff {cat v dur}         — 기절 면역(보스)이면 대신 그 디버프 (성공 판정, 뇌격 — R2: 차지 감소는 물·시간 독점이라 번개 몫 크리로)
## 패시브(WITCHES[id].passive.effects, §15.6) — 버프가 아니라 해제되지 않는다:
##   stat cat v [mark]        — 상시 보정 (mark가 있으면 대상에게 그 징표가 있을 때만, 겹을 곱하지 않음)
##   aura cat v               — 이 마녀가 살아 있는 동안 아군 전체에 (지금은 dmg_taken만)
##   def_pierce v             — 내 공격은 적 방어율을 v만큼 덜 받음 (0 아래로 안 감)
##   mark_plus kind n         — 내가 거는 그 징표는 n겹 더
##   enemy_gauge_plus v       — 내가 거는 적 게이지 감소 +v (빙결 두 배보다 먼저)
##   gauge_plus v             — 내가 거는 아군 게이지 증가 +v
##   support_gauge v          — 내가 아군에게 보조 마법을 걸면 그 아군(자신 제외) 게이지 +v
##   start_gauge who v        — 전투 시작(첫 웨이브) 때 게이지 +v
##   on_crit effects          — 내 공격에 크리가 나면 (그 행동이 끝날 때 한 번) effects
##   [단계 B] stat ... per_mark · own_el · max — 겹 수를 곱함 · 자기 속성 공격일 때만 · 이 패시브의 상한
##   aura cat v [mark]        — dmg_taken(받는 피해) · crit_dmg(그 징표 적을 때리는 아군 전체)
##   buff_plus cat v          — 내가 거는 그 종류 버프 +v (엠버)
##   rate_plus v              — 내가 거는 디버프·게이지 감소·차지 감소 성공률 +v (글라시아)
##   taunt_guard v            — 도발 중 자신 받는 피해 +v (음수, 네레이)
##   on_hit_debuff cat v dur  — 내가 때린 적에게 판정 없이 (따로 쌓지 않고 남은 수만 새로, 에스카 "틈")
##   on_slow_debuff cat v dur — 내가 게이지·차지를 깎은 적에게 판정 없이 (같은 방식, 글라시아 — F-4)
## 버프 지속 "dur"은 대상이 행동을 N번 마칠 때까지(clock own). invincible·dmg_taken·taunt·guts는 적 행동 N번(clock enemy).

## 데이터 판: 적·마법·전투 데이터(id·패턴·의도 종류)를 바꿀 때 올린다. 끊긴 전투 파일에 적고, 판이 다르면 이어 하기를 버린다 (review_I I-03)
##   1 = 1.7까지 · 2 = 단계 F-2 (적 14·보스 3·전투 10, 의도 9종) · 3 = F-3 (특성 특공 마법 3 · 세 빛의 인형 태세·줄 · 흩날리는 재) · 4 = F-4 (마법·대마법·패시브 품질 — 새 효과 종류) · 5 = R1 (마법 7개 수치) · 6 = R2 (물 겹 특공·쇄빙 일격·속성 독점 셋·신더 기본 장착 — review_L)
const DATA_VER := 6
const GAUGE_MAX := 1000.0
const CREDIT_MAX := 7
const BASIC_BONUS := 1 ## 기본 공격을 쓰면 더 주는 크레딧
const EQUIP_MAX := 4 ## 전투에 장착하는 마법 수 (2026-10-18 사용자: 4개)

const CRIT_BASE := 0.10
const CRIT_MULT := 1.5
const WEAK := 1.5
const SPECIAL := 1.2
const CAP := {"atk": 3.0, "crit_dmg": 3.0, "special": 2.0, "final": 1.0, "def_down": 0.5, "atk_down": 0.5, "dmg_taken": 1.0, "crit_rate": 0.9, "crit_taken": 0.5, "crit_down": 0.5, "final_taken": 0.5, "dmg_cut": 0.7,
	"crit_dmg_taken": 0.6, "ult_dmg": 1.0, "regen": 0.5}
## 징표 → 그 징표의 속성 (특공이 겹을 곱하는 공격 속성, F-4 P1)
const MARK_EL := {"burn": "fire", "frost": "water", "shock": "bolt"}
const ENEMY_CRIT_BASE := 0.05 ## 적의 크리 확률 (크리 다운 디버프의 대상)
const ULT_COST := 7 ## 대마법 비용 (= 크레딧 상한, §13)
const MARK_MAX := 5 ## 징표 최대 겹 (§17.1)
const SKILL_LV := [1.00, 1.15, 1.30] ## 마법 강화 Lv1~3 수치 배수 (§4.4)
const RESIST := {"normal": 0.0, "elite": 0.1, "boss": 0.3} ## 적 등급별 디버프 내성 (§16.5)
const TIER_NAME := {"normal": "일반", "elite": "강적", "boss": "보스"}
## 강화로 오르는 효과 칸 (t → 키). 비용·지속·크레딧 +N·겹 수·히트 수·크리 확정·방어 무시·기절·도발·근성·터뜨리기는 그대로 (§4.4)
const LV_SCALE := {"buff": "v", "debuff": "v", "gauge": "v", "enemy_gauge": "v", "this_special": "v", "heal": "pct", "revive": "pct", "crit_gauge": "v", "hit_stack": "v", "regen": "pct", "hp_bonus": "v"}
## 대마법 연쇄 (§13.6): 단계 1·2·3의 부가 효과 배수 (크레딧·겹 수·지속은 그대로). 칸은 LV_SCALE + 터뜨리기 per
const CHAIN_MULT := [1.00, 1.25, 1.50]
## 공격 대마법의 배율(mult)은 단계 1·2·3에 ×1.15·×1.3 (F-4 P2 — 공격 대마법도 연쇄 끝에 둘 이유)
const CHAIN_DMG := [1.00, 1.15, 1.30]
const CHAIN_SCALE := {"buff": "v", "debuff": "v", "gauge": "v", "enemy_gauge": "v", "this_special": "v", "heal": "pct", "revive": "pct", "crit_gauge": "v", "hit_stack": "v", "burst": "per", "regen": "pct", "hp_bonus": "v"}
const DEF_MIN := 0.3
const DEF_MAX := 1.5
const RAND_LO := 0.95
const RAND_HI := 1.05

const ELEMENT_NAME := {"fire": "불", "water": "물", "bolt": "번개", "space": "공간", "sword": "검술", "time": "시간", "none": "무"}
const MARK_NAME := {"burn": "화상", "frost": "빙결", "shock": "감전"}
const CAT_NAME := {"atk": "공격력", "crit_dmg": "크리 데미지", "crit_rate": "크리 확률", "special": "특공", "final": "최종 데미지",
	"dmg_taken": "받는 피해", "element": "속성 부여", "def_down": "방어 다운", "atk_down": "공격력 다운", "invincible": "무적",
	"crit_taken": "받는 크리 확률", "crit_down": "크리 확률 다운", "taunt": "도발", "guts": "근성", "final_taken": "받는 최종 데미지", "hit_stack": "맞으며 쌓기",
	"dmg_cut": "방어 태세", "cover": "막아서기", "crit_dmg_taken": "받는 크리 데미지", "ult_dmg": "대마법 위력", "regen": "지속 회복"}
const ROLE_NAME := {"dealer": "딜러", "buffer": "버퍼", "caster": "술사", "special": "범용"}
const ELEMENT_COLOR := {"fire": Color("#ff8a3a"), "water": Color("#5ec8ff"), "bolt": Color("#ffe34a"), "space": Color("#b9a2ff"), "time": Color("#f2d27a"), "sword": Color("#f2eff7")}
## 편성 명단 순서 (속성별 딜러·버퍼·술사 → 무상성)
const ROSTER := ["ignis", "ember", "cinder", "undine", "nerei", "glacia", "fulgur", "astra", "tonan", "eska", "hora", "harpe"]

## 약점표: 적의 속성 → 약점인 공격 속성. 물 → 불 → 번개 → 물 순환 (§11.3). 특별한 적은 ENEMIES[id].weak가 우선한다
const WEAK_TO := {"water": "bolt", "fire": "water", "bolt": "fire", "straw": "fire", "ash": "", "none": ""}

const WITCHES := {
	"eska": {
		"name": "에스카", "title": "공간의 마녀 · 범용", "role": "special", "atk": 13000, "hp": 90000, "speed": 110, "def": 0.10,
		"element": "space", "special": true,
		"basic": {"name": "작은 균열", "mult": 1.0, "desc": "단일 1.0배. 차례를 넘기며 크레딧 +1"},
		"skills": ["crack", "void_gate", "leap", "seal", "gap", "compress", "doom", "stigma", "blackstar", "cradle"],
		"default": ["crack", "doom", "blackstar", "cradle"], # F-4 P6: 장착 210가지 측정 (combat_proto.md §27.9)
		"ultimate": "ult_eska",
		"passive": {"name": "틈", "desc": "에스카가 때린 적은 아군에게 받는 최종 데미지 +10% (적 행동 2번, 다시 때리면 남은 수만 새로)", "effects": [{"t": "on_hit_debuff", "cat": "final_taken", "v": 0.10, "dur": 2}]},
		"color": Color("#b9a2ff"), "accent": Color("#f2eff7"),
	},
	"ignis": {
		"name": "이그니스", "title": "불의 마녀 · 딜러", "role": "dealer", "atk": 12000, "hp": 80000, "speed": 95, "def": 0.05,
		"element": "fire", "special": false,
		"basic": {"name": "불씨 튀김", "mult": 1.0, "mark": "burn", "mark_dur": 2, "desc": "단일 1.0배 + 화상(적 행동 2번). 크레딧 +1"},
		"skills": ["spark", "blood_strike", "focus", "burst_fire", "pillar", "breath_of_fire", "ash_storm", "blaze", "sun_spear", "conflagration"],
		"default": ["spark", "ash_storm", "blaze", "sun_spear"], # F-4 P6: 장착 210가지 측정 (combat_proto.md §27.9)
		"ultimate": "ult_ignis",
		"passive": {"name": "불꽃 심장", "desc": "불 공격일 때 대상의 화상 1겹마다 크리 데미지 +8% (최대 +40%). 부여받은 속성 공격엔 붙지 않음", "effects": [{"t": "stat", "cat": "crit_dmg", "v": 0.08, "mark": "burn", "per_mark": true, "own_el": true, "max": 0.40}]},
		"color": Color("#ff6a3d"), "accent": Color("#ffd27a"),
	},
	"ember": {
		"name": "엠버", "title": "불의 마녀 · 버퍼", "role": "buffer", "atk": 8000, "hp": 100000, "speed": 120, "def": 0.15,
		"element": "fire", "special": false,
		"basic": {"name": "불똥", "mult": 0.8, "desc": "단일 0.8배. 크레딧 +1"},
		"skills": ["flame_breath", "kindling", "bellows", "tinder", "blessing", "crown", "stake", "god_descent", "share_ember", "sun_blessing"],
		"default": ["flame_breath", "bellows", "blessing", "god_descent"],
		"ultimate": "ult_ember",
		"passive": {"name": "불씨 지기", "desc": "엠버가 거는 공격력 버프 +10% 더 (덧셈)", "effects": [{"t": "buff_plus", "cat": "atk", "v": 0.10}]},
		"color": Color("#ffb347"), "accent": Color("#fff2dc"),
	},
	"cinder": {
		"name": "신더", "title": "불의 마녀 · 술사 (재)", "role": "caster", "atk": 10000, "hp": 90000, "speed": 105, "def": 0.10,
		"element": "fire", "special": false,
		"basic": {"name": "재 뿌리기", "mult": 0.9, "mark": "burn", "mark_dur": 2, "desc": "단일 0.9배 + 화상(적 행동 2번). 크레딧 +1"},
		"skills": ["ash_dust", "ash_spread", "embers_left", "kindle_up", "ember_wind", "fire_ring", "ash_heap", "fire_brand", "cremation", "ash_oath"],
		"default": ["ash_dust", "kindle_up", "ember_wind", "ash_heap"], # R2: 장착 210가지 측정 1위 (예전 재 번짐·재의 맹세는 199위, combat_proto.md §27.11)
		"ultimate": "ult_cinder",
		"passive": {"name": "잿빛 손", "desc": "신더가 거는 화상은 1겹 더 (한 번에 2겹)", "effects": [{"t": "mark_plus", "kind": "burn", "n": 1}]},
		"color": Color("#c07a4a"), "accent": Color("#e8c9a0"),
	},
	"undine": {
		"name": "운디네", "title": "물의 마녀 · 딜러", "role": "dealer", "atk": 12000, "hp": 85000, "speed": 90, "def": 0.08,
		"element": "water", "special": false,
		"basic": {"name": "물살 치기", "mult": 1.0, "desc": "단일 1.0배. 크레딧 +1"},
		"skills": ["water_lance", "whirlpool", "return_tide", "ice_break", "torrent", "still_water", "tidal_wave", "glacier", "abyss_lance", "deluge"],
		"default": ["water_lance", "return_tide", "glacier", "abyss_lance"],
		"ultimate": "ult_undine",
		"passive": {"name": "물길", "desc": "빙결 적을 물 공격으로 때릴 때 최종 데미지 +10%. 부여받은 속성 공격엔 붙지 않음", "effects": [{"t": "stat", "cat": "final", "v": 0.10, "mark": "frost", "own_el": true}]},
		"color": Color("#3aa7ff"), "accent": Color("#dff6ff"),
	},
	"nerei": {
		"name": "네레이", "title": "물의 마녀 · 버퍼", "role": "buffer", "atk": 8000, "hp": 110000, "speed": 115, "def": 0.18,
		"element": "water", "special": false,
		"basic": {"name": "물방울", "mult": 0.8, "desc": "단일 0.8배. 크레딧 +1"},
		"skills": ["droplet", "water_cloak", "frost_breath", "spring", "wave_hold", "current", "high_tide", "water_veil", "sea_embrace", "ocean_blessing"],
		"default": ["frost_breath", "spring", "high_tide", "water_veil"], # F-4 P6: 장착 210가지 측정 (combat_proto.md §27.9)
		"ultimate": "ult_nerei",
		"passive": {"name": "잔물결 보호", "desc": "네레이가 살아 있는 동안 아군 전체 받는 피해 −10% · 도발 중이면 자신 받는 피해 −10% 더", "effects": [{"t": "aura", "cat": "dmg_taken", "v": -0.10}, {"t": "taunt_guard", "v": -0.10}]},
		"color": Color("#8fd4ff"), "accent": Color("#f0fbff"),
	},
	"glacia": {
		"name": "글라시아", "title": "물의 마녀 · 술사 (서리)", "role": "caster", "atk": 10000, "hp": 95000, "speed": 100, "def": 0.12,
		"element": "water", "special": false,
		"basic": {"name": "서리 손끝", "mult": 0.9, "mark": "frost", "mark_dur": 2, "desc": "단일 0.9배 + 빙결(적 행동 2번). 크레딧 +1"},
		"skills": ["rime", "thin_ice", "icicle", "blizzard", "ice_wall", "still_frost", "deep_freeze", "ice_coffin", "permafrost", "winter_oath"],
		"default": ["still_frost", "deep_freeze", "ice_coffin", "permafrost"], # F-4 P6: 장착 210가지 측정 (combat_proto.md §27.9)
		"ultimate": "ult_glacia",
		"passive": {"name": "서리 장인", "desc": "글라시아가 거는 디버프·적 게이지 감소·적 차지 감소의 성공률 +15% 더 (덧셈) · 글라시아가 게이지·차지를 깎은 적은 방어 다운 15% (적 행동 2번, 다시 깎으면 남은 수만 새로)", "effects": [{"t": "rate_plus", "v": 0.15}, {"t": "on_slow_debuff", "cat": "def_down", "v": 0.15, "dur": 2}]},
		"color": Color("#bfe9ff"), "accent": Color("#ffffff"),
	},
	"fulgur": {
		"name": "풀구르", "title": "번개의 마녀 · 딜러", "role": "dealer", "atk": 11500, "hp": 75000, "speed": 115, "def": 0.05,
		"element": "bolt", "special": false,
		"basic": {"name": "스파크 튕김", "mult": 1.2, "hits": 3, "mark": "shock", "mark_dur": 2, "desc": "단일 1.2배를 3번으로 나눠 (각 0.4배, 히트마다 크리 판정) + 감전(적 행동 2번). 크레딧 +1"},
		"skills": ["spark_bolt", "chain_lightning", "charge_up", "thunderbolt", "flash", "current_share", "thunderstorm", "lightning_strike", "thunder_lance", "storm_god"],
		"default": ["spark_bolt", "thunderbolt", "flash", "lightning_strike"], # F-4 P6: 장착 210가지 측정 (combat_proto.md §27.9)
		"ultimate": "ult_fulgur",
		"passive": {"name": "번개 눈", "desc": "감전 적에게 크리 확률 +15% · 크리가 난 행동 뒤 자신 행동 게이지 +10%", "effects": [{"t": "stat", "cat": "crit_rate", "v": 0.15, "mark": "shock"}, {"t": "on_crit", "effects": [{"t": "gauge", "who": "self", "v": 0.10}]}]},
		"color": Color("#ffe34a"), "accent": Color("#fffbe0"),
	},
	"astra": {
		"name": "아스트라", "title": "번개의 마녀 · 버퍼 (별)", "role": "buffer", "atk": 8000, "hp": 95000, "speed": 130, "def": 0.12,
		"element": "bolt", "special": false,
		"basic": {"name": "정전기", "mult": 0.8, "desc": "단일 0.8배. 크레딧 +1"},
		"skills": ["static", "lightning_cloak", "rod", "spur", "star_touch", "starlight", "guide_bolt", "overcharge", "lightning_share", "meteor_blessing"],
		"default": ["star_touch", "rod", "starlight", "lightning_share"],
		"ultimate": "ult_astra",
		"passive": {"name": "별의 걸음", "desc": "아스트라가 거는 아군 게이지 증가 +10% 더 (덧셈) · 아군에게 보조 마법을 걸면 그 아군 게이지 +10%", "effects": [{"t": "gauge_plus", "v": 0.10}, {"t": "support_gauge", "v": 0.10}]},
		"color": Color("#c9a0ff"), "accent": Color("#fff6c8"),
	},
	"tonan": {
		"name": "토난", "title": "번개의 마녀 · 술사 (우레)", "role": "caster", "atk": 10500, "hp": 85000, "speed": 110, "def": 0.08,
		"element": "bolt", "special": false,
		"basic": {"name": "번개 바늘", "mult": 0.9, "mark": "shock", "mark_dur": 2, "desc": "단일 0.9배 + 감전(적 행동 2번). 크레딧 +1"},
		"skills": ["needle", "overcurrent", "volt", "thunder", "shock_spread", "discharge", "shock_brand", "conduction", "thundercloud", "thunder_oath"],
		"default": ["needle", "overcurrent", "conduction", "thunder_oath"],
		"ultimate": "ult_tonan",
		"passive": {"name": "피뢰 표식", "desc": "토난이 살아 있는 동안 감전 적을 때리는 아군 전체 크리 데미지 +30%", "effects": [{"t": "aura", "cat": "crit_dmg", "v": 0.30, "mark": "shock"}]},
		"color": Color("#7a8cff"), "accent": Color("#ffe34a"),
	},
	"hora": {
		"name": "호라", "title": "시간의 마녀 · 버퍼", "role": "buffer", "atk": 9000, "hp": 95000, "speed": 125, "def": 0.12,
		"element": "time", "special": true,
		"basic": {"name": "초침 찌르기", "mult": 0.8, "desc": "단일 0.8배. 크레딧 +1"},
		"skills": ["second_hand", "stopped_clock", "rewind", "time_haste", "clock_hand", "hourglass", "once_more", "time_stop", "doomsday_clock", "turn_back"],
		"default": ["rewind", "time_haste", "hourglass", "turn_back"], # F-4 P6: 장착 210가지 측정 (combat_proto.md §27.9)
		"ultimate": "ult_hora",
		"passive": {"name": "이른 시계", "desc": "전투 시작 때 아군 전체 행동 게이지 +20% · 아군에게 보조 마법을 걸면 그 아군 게이지 +10%", "effects": [{"t": "start_gauge", "who": "allies", "v": 0.20}, {"t": "support_gauge", "v": 0.10}]},
		"color": Color("#f2d27a"), "accent": Color("#fff8e0"),
	},
	"harpe": {
		"name": "하르페", "title": "검의 마녀 · 딜러", "role": "dealer", "atk": 14000, "hp": 75000, "speed": 100, "def": 0.05,
		"element": "sword", "special": true,
		"basic": {"name": "흑백 참격", "mult": 1.1, "desc": "단일 1.1배. 크레딧 +1"},
		"skills": ["bw_slash", "return_cut", "sword_dance", "flash_cut", "space_cut", "sword_ki", "heaven_split", "sword_wind", "doom_slash", "bw_dance"],
		"default": ["flash_cut", "heaven_split", "sword_wind", "doom_slash"], # F-4 P6: 장착 210가지 측정 (combat_proto.md §27.9)
		"ultimate": "ult_harpe",
		"passive": {"name": "검의 리듬", "desc": "크리 데미지 +10% (상시) · 크리가 나면 자신 크리 데미지 +20% (다음 행동 1번). 다단 히트는 그 행동이 끝날 때 한 번만", "effects": [{"t": "stat", "cat": "crit_dmg", "v": 0.10}, {"t": "on_crit", "effects": [{"t": "buff", "who": "self", "cat": "crit_dmg", "v": 0.20, "dur": 2}]}]},
		"color": Color("#f2eff7"), "accent": Color("#14081f"),
	},
}

const SKILLS := {
	# ── 에스카: 공간 · 무상성 · 범용 (공격 4 + 보조 6) — 어느 판에도: 방어 무시 · 파티 최종 데미지 · 무적 · 되살림
	"crack": {"name": "공허의 균열", "cost": 1, "kind": "attack", "target": "enemy", "mult": 2.0, "fx": "rift_small", "icon": "crack",
		"effects": [{"t": "debuff", "cat": "def_down", "v": 0.10, "dur": 2}],
		"desc": "2.0배 피해 + 방어 다운 10% (적 행동 2번)", "ref": "싼 단일기 + 가벼운 디버프"},
	"void_gate": {"name": "공허의 문", "cost": 2, "kind": "support", "target": "ally", "fx": "void_gate", "icon": "gate",
		"effects": [{"t": "buff", "cat": "final", "v": 0.30, "dur": 3}, {"t": "gauge", "v": 0.30}],
		"desc": "아군 1: 최종 데미지 +30% (행동 3번) + 행동 게이지 +30%", "ref": "공명·멀린의 단일 몰아주기 + 차례 당기기"},
	"leap": {"name": "틈새 도약", "cost": 2, "kind": "support", "target": "ally", "fx": "leap", "icon": "dash",
		"effects": [{"t": "gauge", "v": 0.30}, {"t": "credits", "v": 2}],
		"desc": "아군 1: 행동 게이지 +30% + 크레딧 +2", "ref": "스카디 S3의 단일 충전 (자원을 한 명에게 넘김, 교환비 1 — F-4: +1은 박차·공허의 문보다 낮았다)"},
	"seal": {"name": "봉공", "cost": 4, "kind": "support", "target": "allies", "fx": "seal", "icon": "shield",
		"effects": [{"t": "invincible", "who": "allies", "dur": 1}, {"t": "credits", "who": "other_allies", "v": 1}],
		"desc": "아군 전체: 무적 (다음 적 행동 1번) + 다른 아군 크레딧 +1", "ref": "캐스토리아의 지키면서 채우기 (자기 충전은 뺌 — 무한 순환 막기). 전체 무적은 4비용 (§15.3, 단계 E E3)"},
	"gap": {"name": "세계의 틈", "cost": 3, "kind": "debuff", "target": "enemies", "fx": "gap", "icon": "rift",
		"effects": [{"t": "debuff", "who": "enemies", "cat": "def_down", "v": 0.20, "dur": 3}, {"t": "debuff", "who": "enemies", "cat": "atk_down", "v": 0.20, "dur": 2}],
		"desc": "적 전체: 방어 다운 20% (적 행동 3번) + 공격력 다운 20% (적 행동 2번)", "ref": "스카디 S2·모르간의 광역 방어 다운"},
	"compress": {"name": "공간 압축", "cost": 3, "kind": "attack", "target": "enemy", "mult": 4.3, "fx": "compress", "icon": "converge",
		"effects": [{"t": "ignore_def"}, {"t": "this_special", "trait": "spirit", "v": 0.60}],
		"desc": "4.3배 피해, 이 공격만 적 방어율 무시. 영체 적에게 이 공격만 특공 +60%", "ref": "방어 무시 단일기 + 특성 특공 (F-3, review_F F02): 공간째 짓눌러 형체 없는 것도 잡음 (베기가 아님)"},
	"doom": {"name": "종언", "cost": 4, "kind": "attack", "target": "enemy", "mult": 6.0, "fx": "doom", "icon": "eclipse",
		"effects": [{"t": "buff", "who": "self", "cat": "atk", "v": 0.15, "dur": 1, "pre": true}],
		"desc": "공격 직전 자신 공격력 +15% (행동 1번) → 6.0배 피해", "ref": "초인 오리온 S1의 1행동 자기 강화 → 강타 (4비용 예산 6.0배 = 비용 + 2, D2·E2)"},
	"stigma": {"name": "별의 성흔", "cost": 4, "kind": "support", "target": "ally", "fx": "stigma", "icon": "eye",
		"effects": [{"t": "buff", "cat": "crit_dmg", "v": 0.80, "dur": 3}, {"t": "buff", "cat": "crit_rate", "v": 0.50, "dur": 3}],
		"desc": "아군 1: 크리 데미지 +80% + 크리 확률 +50% (행동 3번)", "ref": "공명 S1의 크리 위력 · 멀린 S3의 몰아주기"},
	"blackstar": {"name": "흑성", "cost": 5, "kind": "attack", "target": "enemies", "mult": 5.3, "fx": "blackstar", "icon": "blackstar",
		"effects": [{"t": "debuff", "who": "enemies", "cat": "def_down", "v": 0.20, "dur": 3}],
		"desc": "적 전체 5.3배 피해 + 방어 다운 20% (적 행동 3번)", "ref": "광역 보구 + 광역 디버프"},
	"cradle": {"name": "공허의 요람", "cost": 5, "kind": "support", "target": "ally_any", "fx": "cradle", "icon": "cradle",
		"effects": [{"t": "revive", "pct": 0.50}, {"t": "credits", "v": 2}],
		"desc": "아군 1: 쓰러진 아군을 체력 50%로 되살림 (살아 있으면 50% 회복) + 크레딧 +2", "ref": "부활 — 속성을 타지 않는 범용 보조"},

	# ── 이그니스: 불 · 딜러 (공격 8 + 보조 2) — 겹을 먹는 한 방: 화상 겹 비례 크리 · 터뜨리기 · 체력 대가
	"spark": {"name": "불씨 찌르기", "cost": 1, "kind": "attack", "target": "enemy", "mult": 2.0, "fx": "fireball", "icon": "spark",
		"effects": [{"t": "mark", "kind": "burn", "dur": 3}],
		"desc": "2.0배 피해 + 화상 1겹 (적 행동 3번)", "ref": "징표 심기"},
	"blood_strike": {"name": "피 끓는 일격", "cost": 2, "kind": "attack", "target": "enemy", "mult": 3.0, "fx": "meteor", "icon": "brand",
		"effects": [{"t": "hp_cost", "who": "self", "pct": 0.10}],
		"desc": "3.0배 피해. 대가: 자신 체력 −10% (쓰러지지 않음)", "ref": "버스터식 몰아치기 — 자원 대신 체력을 낸다 (코얀스카야 S1의 체력 대가)"},
	"focus": {"name": "열기 응축", "cost": 2, "kind": "support", "target": "self", "fx": "focus", "icon": "focus",
		"effects": [{"t": "buff", "who": "self", "cat": "atk", "v": 0.80, "dur": 4, "count": 1, "on": "skill"}],
		"desc": "자신: 다음 공격 마법 1번 공격력 +80% (기본 공격·보조 마법엔 닳지 않음, 행동 3번 안에)", "ref": "초인 오리온 S1의 1행동 거대 자기 강화 — 횟수제라 보조 마법에 닳지 않음"},
	"burst_fire": {"name": "불씨 터뜨리기", "cost": 3, "kind": "attack", "target": "enemy", "mult": 3.5, "fx": "blaze", "icon": "burst",
		"effects": [{"t": "burst", "mark": "burn", "per": 0.60}],
		"desc": "3.5배 피해 + 화상 터뜨리기 (겹마다 +0.6배, 맞힌 뒤 화상 제거)", "ref": "징표 소모 강타 — 쌓아 둘지 터뜨릴지 (§17.1). 겹마다 0.8 → 0.6 (단계 E: 보스전 가장 빠른 원형을 2배 안으로)"},
	"pillar": {"name": "솟구치는 불기둥", "cost": 3, "kind": "attack", "target": "enemy", "mult": 5.0, "fx": "pillar", "icon": "pillar",
		"effects": [{"t": "mark", "kind": "burn", "dur": 3}],
		"desc": "5.0배 피해 + 화상 1겹 (적 행동 3번)", "ref": "때리며 겹을 쌓는 쪽 (터뜨리기의 반대 선택)"},
	"breath_of_fire": {"name": "불의 숨결", "cost": 3, "kind": "support", "target": "self", "fx": "breath", "icon": "breath",
		"effects": [{"t": "buff", "who": "self", "cat": "crit_rate", "v": 0.50, "dur": 4, "count": 1, "on": "skill"}, {"t": "buff", "who": "self", "cat": "crit_dmg", "v": 0.15, "dur": 4, "mark": "burn", "per_mark": true, "count": 1, "on": "skill"}],
		"desc": "자신: 다음 공격 마법 1번 크리 확률 +50% + 화상 1겹마다 크리 데미지 +15% (기본 공격·보조 마법엔 닳지 않음, 행동 3번 안에)", "ref": "초인 오리온 S3의 횟수제 크리 위력 — 열기 응축(공격력)과 짝을 이루는 두 번째 '한 방 준비' (F-4: 남에게 거는 단일 버프는 딜러에게 죽은 칸이었다 · R2: 크리 확정은 검술 독점이라 +90% → +50%, review_L §5.3)"},
	"ash_storm": {"name": "재의 폭풍", "cost": 4, "kind": "attack", "target": "enemies", "mult": 4.0, "fx": "ash_storm", "icon": "storm",
		"effects": [{"t": "mark", "who": "enemies", "kind": "burn", "dur": 3}],
		"desc": "적 전체 4.0배 피해 + 전체 화상 1겹 (적 행동 3번)", "ref": "광역 보구 + 광역 징표"},
	"blaze": {"name": "폭염 개화", "cost": 4, "kind": "attack", "target": "enemy", "mult": 6.7, "fx": "blaze", "icon": "bloom",
		"effects": [{"t": "hp_bonus", "v": 0.40, "at": 0.5}, {"t": "hp_cost", "who": "self", "pct": 0.15}],
		"desc": "6.7배 피해. 적 체력이 가득이면 이 공격만 +40% (절반 이하면 0, 보스는 지금 줄 기준). 대가: 자신 체력 −15% (쓰러지지 않음)", "ref": "대가를 치르는 큰 한 방 (4비용 예산 6.0배 + 대가 몫) + 체력 비례 특공 (F-4: 첫 한 방은 체력이 많은 적에게)"},
	"sun_spear": {"name": "태양의 창", "cost": 5, "kind": "attack", "target": "enemy", "mult": 7.0, "fx": "sun_spear", "icon": "spear",
		"effects": [{"t": "buff", "who": "self", "cat": "crit_rate", "v": 0.30, "dur": 1, "pre": true}, {"t": "hp_bonus", "v": 0.50, "at": 0.5}],
		"desc": "공격 직전 자신 크리 확률 +30% → 7.0배 피해. 적 체력이 가득이면 이 공격만 +50% (절반 이하면 0, 보스는 지금 줄 기준)", "ref": "체력 비례 특공 보구(적 HP가 많을수록 위력)의 구조 — 가득 찬 줄·큰 적을 여는 한 방이라 넘친 피해가 적다 (F-4: '약화 적 특공'이라 적었던 것을 실제 효과대로 바로잡음)"},
	"conflagration": {"name": "대화재", "cost": 5, "kind": "attack", "target": "enemies", "mult": 4.0, "fx": "conflagration", "icon": "inferno",
		"effects": [{"t": "burst", "mark": "burn", "per": 0.50, "keep": true}],
		"desc": "적 전체 4.0배 피해 + 화상 1겹마다 +0.5배 (대상마다 자기 겹, 화상은 남음)", "ref": "징표 비례 광역 마무리 (F-4: 맞힌 뒤 화상을 지워 파티 특공을 날리던 것을 '남김'으로)"},

	# ── 엠버: 불 · 버퍼 (공격 2 + 보조 8) — 몰아주고 대가: 공격력·화상 특공 · 체력/크레딧 대가
	"flame_breath": {"name": "따뜻한 입김", "cost": 1, "kind": "attack", "target": "enemy", "mult": 1.6, "fx": "fireball_small", "icon": "flame",
		"effects": [{"t": "mark", "kind": "burn", "dur": 3}],
		"desc": "1.6배 피해 + 화상 1겹 (적 행동 3번)", "ref": "버퍼도 징표를 심을 수 있게"},
	"kindling": {"name": "장작 얹기", "cost": 2, "kind": "support", "target": "ally", "fx": "kindling", "icon": "kindle",
		"effects": [{"t": "buff", "cat": "element", "el": "fire", "dur": 3}, {"t": "buff", "cat": "crit_dmg", "v": 0.50, "dur": 3, "el": "fire"}],
		"desc": "아군 1: 공격에 화염 속성 부여 + 화염 공격 크리 데미지 +50% (행동 3번)", "ref": "사용자 예시 (무상성 딜러를 화염 딜러로) · 스페이스 이슈타르의 색 바꾸기"},
	"bellows": {"name": "풀무질", "cost": 2, "kind": "support", "target": "ally", "fx": "bellows", "icon": "bellows",
		"effects": [{"t": "buff", "cat": "special", "mark": "burn", "v": 0.25, "dur": 3}, {"t": "buff", "cat": "crit_rate", "v": 0.30, "dur": 3}],
		"desc": "아군 1: 화상 특공 1겹마다 +25% (불 공격만 겹을 곱함) + 크리 확률 +30% (행동 3번)", "ref": "코얀스카야 S3의 특공 부여 — 겹을 곱한다"},
	"tinder": {"name": "불쏘시개", "cost": 2, "kind": "support", "target": "ally", "fx": "share_ember", "icon": "spark",
		"effects": [{"t": "credits", "v": 2}, {"t": "buff", "cat": "ult_dmg", "v": 0.30, "dur": 3}, {"t": "hp_cost", "who": "allies", "pct": 0.08}],
		"desc": "아군 1: 크레딧 +2 + 대마법 위력 +30% (공격 대마법 피해에만, 행동 3번). 대가: 아군 전체 체력 −8% (쓰러지지 않음)", "ref": "빛의 코얀스카야 S1 — 배터리 + 파티 체력 대가 (교환비 1) · 오베론 S3의 보구 위력 몫 (F-4: 배터리가 버프와 겨룰 수 있게)"},
	"blessing": {"name": "불의 축복", "cost": 3, "kind": "support", "target": "allies", "fx": "blessing", "icon": "up",
		"effects": [{"t": "buff", "who": "allies", "cat": "atk", "v": 0.30, "dur": 3}, {"t": "heal", "who": "allies", "pct": 0.15}],
		"desc": "아군 전체: 공격력 +30% (행동 3번, 패시브로 +40%) + 체력 15% 회복", "ref": "캐스토리아 S1의 전체 공격 버프 + 작은 전체 회복 (네레이 없는 파티의 버팀, 단계 E E1). 전체 충전은 물(밀려오는 조류)의 몫으로 넘김 — 불은 배율 (단계 E E6)"},
	"crown": {"name": "타는 왕관", "cost": 3, "kind": "support", "target": "ally", "fx": "god_descent", "icon": "pillar",
		"effects": [{"t": "buff", "cat": "atk", "v": 0.60, "dur": 3}, {"t": "buff", "cat": "special", "mark": "burn", "v": 0.15, "dur": 3}],
		"desc": "아군 1: 공격력 +60% (패시브로 +70%) + 화상 특공 1겹마다 +15% (불 공격만 겹을 곱함, 행동 3번)", "ref": "오베론 S3의 단일 몰아주기 (대가 없이 작게)"},
	"stake": {"name": "화형대", "cost": 3, "kind": "attack", "target": "enemy", "mult": 3.6, "fx": "stake", "icon": "stake",
		"effects": [{"t": "debuff", "cat": "def_down", "v": 0.20, "dur": 3}, {"t": "mark", "kind": "burn", "dur": 3}],
		"desc": "3.6배 피해 + 방어 다운 20% (적 행동 3번) + 화상 1겹 (적 행동 3번)", "ref": "모르간의 방어 다운을 버퍼의 디버프 공격으로"},
	"god_descent": {"name": "불의 신 강림", "cost": 4, "kind": "support", "target": "ally", "fx": "god_descent", "icon": "descent",
		"effects": [{"t": "buff", "cat": "atk", "v": 1.00, "dur": 1}, {"t": "gauge", "v": 1.00}, {"t": "demerit_zero"}],
		"desc": "아군 1: 공격력 +100% (행동 1번, 패시브로 +110%) + 게이지 100% (바로 다음 차례). 대가: 그 행동이 끝나면 크레딧 0", "ref": "오베론 S3·코얀스카야 — 한 번 크게, 대가는 나중에"},
	"share_ember": {"name": "불씨 나눔", "cost": 4, "kind": "support", "target": "ally", "fx": "share_ember", "icon": "link",
		"effects": [{"t": "credits", "v": 3}, {"t": "buff", "cat": "ult_dmg", "v": 0.40, "dur": 3}],
		"desc": "아군 1: 크레딧 +3 + 대마법 위력 +40% (공격 대마법 피해에만, 행동 3번)", "ref": "스카디 S3·캐스토리아 S2의 단일 충전 (교환비 0.75) + 보구 위력 (F-4: 최종 데미지 +20%를 대마법 몫으로)"},
	"sun_blessing": {"name": "태양의 축복", "cost": 5, "kind": "support", "target": "allies", "fx": "sun_blessing", "icon": "sun",
		"effects": [{"t": "buff", "who": "allies", "cat": "crit_dmg", "v": 0.50, "dur": 3}, {"t": "buff", "who": "allies", "cat": "final", "v": 0.30, "dur": 3},
			{"t": "credits", "who": "allies", "v": 1}],
		"desc": "아군 전체: 크리 데미지 +50% + 최종 데미지 +30% (행동 3번) + 크레딧 +1", "ref": "캐스토리아 S1의 전체 버프 겹치기"},

	# ── 신더: 불 · 술사 (공격 4 + 디버프 4 + 보조 2) — 겹을 깐다: 화상을 오래·넓게·번지게
	"ash_dust": {"name": "재 뿌리기", "cost": 1, "kind": "debuff", "target": "enemy", "fx": "hex", "icon": "dust",
		"effects": [{"t": "mark", "kind": "burn", "dur": 4}, {"t": "debuff", "cat": "def_down", "v": 0.10, "dur": 2}],
		"desc": "화상 1겹 (적 행동 4번, 패시브로 2겹) + 방어 다운 10% (적 행동 2번)", "ref": "징표를 오래 깔기"},
	"ash_spread": {"name": "재 번짐", "cost": 2, "kind": "debuff", "target": "enemy", "fx": "hex_all", "icon": "smoke",
		"effects": [{"t": "spread", "kind": "burn"}],
		"desc": "적 1의 화상 겹 수만큼 다른 적 전체에 화상 (남은 수도 같게, 패시브로 1겹 더)", "ref": "아르주나 얼터 보구의 '먼저 약화' — 한 명에게 쌓은 것을 전체로"},
	"embers_left": {"name": "잉걸불 그을음", "cost": 2, "kind": "debuff", "target": "enemy", "fx": "hex", "icon": "smoke",
		"effects": [{"t": "debuff", "cat": "def_down", "v": 0.06, "dur": 3, "mark": "burn", "per_mark": true}, {"t": "extend_mark", "kind": "burn", "v": 1}],
		"desc": "적 1: 화상이 남아 있는 동안 1겹마다 방어 다운 6% (적 행동 3번, 5겹 30% · 터뜨리면 사라짐) + 화상 연장 +1", "ref": "모르간식 방어 다운을 겹 수에 묶음 — 어느 속성 딜러에게나 사는 신더의 둘째 축 (F-4: 2.5배 연장 공격은 공격력 10,000 술사에게 죽은 칸이었다)"},
	"kindle_up": {"name": "연소 촉진", "cost": 2, "kind": "debuff", "target": "enemy", "fx": "hex", "icon": "flame",
		"effects": [{"t": "mark", "kind": "burn", "dur": 5, "n": 2}],
		"desc": "적 1: 화상 2겹 (적 행동 5번, 패시브로 3겹)", "ref": "겹을 한 번에 — 터뜨리기의 재료"},
	"ember_wind": {"name": "불씨 바람", "cost": 3, "kind": "debuff", "target": "enemies", "fx": "ash_storm", "icon": "wind",
		"effects": [{"t": "mark", "who": "enemies", "kind": "burn", "dur": 3}, {"t": "debuff", "who": "enemies", "cat": "def_down", "v": 0.15, "dur": 3}],
		"desc": "적 전체: 화상 1겹 (적 행동 3번, 패시브로 2겹) + 방어 다운 15% (적 행동 3번)", "ref": "광역 징표 + 광역 디버프"},
	"fire_ring": {"name": "불의 고리", "cost": 3, "kind": "attack", "target": "enemies", "mult": 4.3, "fx": "conflagration", "icon": "ring",
		"effects": [{"t": "this_special", "mark": "burn", "v": 0.40}, {"t": "mark", "who": "enemies", "kind": "burn", "dur": 3, "if_mark": "burn"}],
		"desc": "적 전체 4.3배 피해, 화상 적에게 이 공격만 특공 +40% + 화상 적마다 화상 1겹 더 (적 행동 3번, 패시브로 2겹)", "ref": "징표 적 광역 특공 + 겹 다시 깔기 (F-4: 장송의 불과 합친 '광역으로 겹을 키우는' 칸)",
		"fit": "적이 셋 이상인 전투(등불 회랑) — 불씨 바람·재 번짐으로 화상을 먼저 깔고"},
	"ash_heap": {"name": "잿더미", "cost": 4, "kind": "debuff", "target": "enemy", "fx": "hex", "icon": "heap",
		"effects": [{"t": "debuff", "cat": "def_down", "v": 0.30, "dur": 3}, {"t": "buff", "who": "allies", "cat": "special", "mark": "burn", "v": 0.15, "dur": 3}],
		"desc": "적 1: 방어 다운 30% (적 행동 3번) + 아군 전체 화상 특공 1겹마다 +15% (불 공격만 겹을 곱함, 행동 3번)", "ref": "모르간 S1 — 적 약화와 파티 버프를 한 번에"},
	"fire_brand": {"name": "불의 낙인", "cost": 4, "kind": "attack", "target": "enemy", "mult": 5.4, "fx": "stake", "icon": "brand",
		"effects": [{"t": "mark", "kind": "burn", "dur": 4}, {"t": "debuff", "cat": "crit_taken", "v": 0.20, "dur": 3}],
		"desc": "5.4배 피해 + 화상 1겹 (적 행동 4번) + 이 적을 때리는 아군 크리 확률 +20% (적 행동 3번)", "ref": "대상 조건 크리 확률"},
	"cremation": {"name": "장송의 불", "cost": 5, "kind": "debuff", "target": "enemies", "fx": "conflagration", "icon": "inferno",
		"effects": [{"t": "debuff", "who": "enemies", "cat": "final_taken", "v": 0.06, "dur": 3, "mark": "burn", "per_mark": true}, {"t": "extend_mark", "who": "enemies", "kind": "burn", "v": 2}],
		"desc": "적 전체: 화상이 남아 있는 동안 1겹마다 받는 최종 데미지 +6% (적 행동 3번 · 터뜨리면 사라짐) + 화상 적마다 화상 연장 +2", "ref": "보구 뒤 약화(받는 피해 증가)를 겹에 묶음 — 속성을 가리지 않는 파티 증폭 (F-4: 술사의 4.7배 광역은 죽은 칸이었다)"},
	"ash_oath": {"name": "재의 맹세", "cost": 5, "kind": "support", "target": "allies", "fx": "sun_blessing", "icon": "oath",
		"effects": [{"t": "buff", "who": "allies", "cat": "special", "mark": "burn", "v": 0.20, "dur": 3}, {"t": "buff", "who": "allies", "cat": "atk", "v": 0.20, "dur": 3}, {"t": "credits", "who": "allies", "v": 1}],
		"desc": "아군 전체: 화상 특공 1겹마다 +20% (불 공격만 겹을 곱함) + 공격력 +20% (행동 3번) + 크레딧 +1", "ref": "캐스토리아 S1의 전체 버프 겹치기"},

	# ── 운디네: 물 · 딜러 (공격 9 + 보조 1) — 돌려서 자주: 빙결 적을 때리면 크레딧이 돌아온다 (배율은 같은 비용 −15%)
	"water_lance": {"name": "물의 창", "cost": 1, "kind": "attack", "target": "enemy", "mult": 1.7, "fx": "fireball", "icon": "spark",
		"effects": [{"t": "mark", "kind": "frost", "dur": 3}], "desc": "1.7배 피해 + 빙결 1겹 (적 행동 3번)", "ref": "징표 심기"},
	"whirlpool": {"name": "소용돌이 끌기", "cost": 2, "kind": "attack", "target": "enemy", "mult": 2.2, "fx": "whip", "icon": "whirl",
		"effects": [{"t": "enemy_gauge", "v": 0.15, "frost_x2": true}], "desc": "2.2배 피해 + 적 게이지 −15% (빙결이면 −30%)", "ref": "지연"},
	"return_tide": {"name": "돌아오는 물살", "cost": 2, "kind": "attack", "target": "enemy", "mult": 2.2, "fx": "whip", "icon": "cycle",
		"effects": [{"t": "credits", "who": "self", "v": 1, "if_mark": "frost"}],
		"desc": "2.2배 피해. 빙결 적이면 자신 크레딧 +1 (맞기 전 빙결 기준)", "ref": "아츠식 순환 — 피해 대신 자원을 벌어 온다"},
	"ice_break": {"name": "쇄빙 일격", "cost": 3, "kind": "attack", "target": "enemy", "mult": 4.3, "fx": "pillar", "icon": "crack",
		"effects": [{"t": "burst", "mark": "frost", "per": 0.30, "keep": true}],
		"desc": "4.3배 피해 + 빙결 1겹마다 +0.3배 (빙결은 남음 — 5겹 5.8배)", "ref": "징표 비례 강타 (물은 터뜨리지 않는다 — 겹을 남김). F-4: 빙하 붕괴(순환)와 갈리는 '겹을 쌓는 물' 칸 — 글라시아 절대 영도·눈보라와 짝. R2: 겹당 0.6 → 0.3 — 겹을 남기고도 불씨 터뜨리기보다 셌다 (review_L §5.3)",
		"fit": "글라시아가 빙결을 깔아 주는 파티 (빙결 3겹 이상)"},
	"torrent": {"name": "격류", "cost": 3, "kind": "attack", "target": "enemy", "mult": 3.7, "fx": "meteor", "icon": "wave",
		"effects": [{"t": "debuff", "cat": "def_down", "v": 0.15, "dur": 2}, {"t": "mark", "kind": "frost", "dur": 2}],
		"desc": "3.7배 피해 + 방어 다운 15% (적 행동 2번) + 빙결 1겹 (적 행동 2번)", "ref": "모르간의 방어 다운 + 징표"},
	"still_water": {"name": "잔잔한 수면", "cost": 2, "kind": "support", "target": "ally", "fx": "breath", "icon": "drop",
		"effects": [{"t": "buff", "cat": "dmg_taken", "v": -0.20, "dur": 3}, {"t": "regen", "pct": 0.08, "dur": 4}, {"t": "credits", "v": 2}],
		"desc": "아군 1: 받는 피해 −20% (적 행동 3번) + 지속 회복: 그 아군이 행동을 마칠 때마다 8% 회복 (4번) + 크레딧 +2", "ref": "멀린식 지속 회복을 물 딜러가 스스로 — 회복 버퍼 없이도 버티는 '혼자 도는 물' 장착 (F-4)",
		"fit": "네레이·엠버·아스트라처럼 회복을 주는 마녀가 없는 파티 — 운디네가 스스로 버팀"},
	"tidal_wave": {"name": "해일", "cost": 4, "kind": "attack", "target": "enemies", "mult": 3.5, "fx": "ash_storm", "icon": "tide",
		"effects": [{"t": "mark", "who": "enemies", "kind": "frost", "dur": 3}], "desc": "적 전체 3.5배 피해 + 전체 빙결 1겹 (적 행동 3번)", "ref": "광역 보구 + 광역 징표"},
	"glacier": {"name": "빙하 붕괴", "cost": 4, "kind": "attack", "target": "enemy", "mult": 4.6, "fx": "blaze", "icon": "shard",
		"effects": [{"t": "this_special", "mark": "frost", "v": 0.30}, {"t": "credits", "who": "self", "v": 2, "if_mark": "frost"}],
		"desc": "4.6배 피해, 빙결 적에게 이 공격만 특공 +30%. 빙결 적이면 자신 크레딧 +2 (맞기 전 빙결 기준)", "ref": "약속된 승리의 검의 NP 리차지 구조를 마법에"},
	"abyss_lance": {"name": "심해의 창", "cost": 5, "kind": "attack", "target": "enemy", "mult": 5.6, "fx": "sun_spear", "icon": "spear",
		"effects": [{"t": "this_special", "mark": "frost", "v": 0.30}, {"t": "credits", "who": "self", "v": 2, "if_mark": "frost"}, {"t": "enemy_charge", "v": 1, "if_mark": "frost"}],
		"desc": "5.6배 피해, 빙결 적에게 이 공격만 특공 +30%. 빙결 적이면 자신 크레딧 +2 + 적 차지 −1 (맞기 전 빙결 기준)", "ref": "한 방 + 순환 + 차지 감소 (F-4: 빙하 붕괴는 '피해', 심해의 창은 '필살기 미루기' — 물·시간의 독점 효과)"},
	"deluge": {"name": "대홍수", "cost": 5, "kind": "attack", "target": "enemies", "mult": 4.0, "fx": "conflagration", "icon": "storm",
		"effects": [{"t": "this_special", "mark": "frost", "v": 0.60}, {"t": "enemy_gauge", "who": "enemies", "v": 0.20}],
		"desc": "적 전체 4.0배 피해, 빙결 적에게 이 공격만 특공 +60% + 적 전체 게이지 −20%", "ref": "광역 마무리 + 지연"},

	# ── 네레이: 물 · 버퍼 (공격 1 + 보조 9) — 지키며 채운다 · 맞으며 쌓는다
	"droplet": {"name": "물방울 튕기기", "cost": 1, "kind": "attack", "target": "enemy", "mult": 1.4, "fx": "fireball_small", "icon": "drop",
		"effects": [{"t": "mark", "kind": "frost", "dur": 3}], "desc": "1.4배 피해 + 빙결 1겹 (적 행동 3번)", "ref": "버퍼의 징표"},
	"water_cloak": {"name": "물의 옷", "cost": 2, "kind": "support", "target": "ally", "fx": "kindling", "icon": "cloak",
		"effects": [{"t": "buff", "cat": "element", "el": "water", "dur": 3}, {"t": "buff", "cat": "crit_dmg", "v": 0.50, "dur": 3, "el": "water"}],
		"desc": "아군 1: 공격에 물 속성 부여 + 물 공격 크리 데미지 +50% (행동 3번)", "ref": "속성 부여"},
	"frost_breath": {"name": "서리 숨결", "cost": 2, "kind": "support", "target": "ally", "fx": "bellows", "icon": "breath",
		"effects": [{"t": "buff", "cat": "special", "mark": "frost", "v": 0.15, "dur": 3}, {"t": "buff", "cat": "crit_rate", "v": 0.10, "dur": 3}],
		"desc": "아군 1: 빙결 특공 1겹마다 +15% (물 공격만 겹을 곱함) + 크리 확률 +10% (행동 3번)", "ref": "특공 부여 (R2: 특공 25 → 15%/겹 · 크리 확률 30 → 10% — 서리 물레가 물 약점 없는 둥지어미에서 가장 빠른 원형보다 빨랐다, combat_proto.md §27.11)"},
	"spring": {"name": "샘물 붓기", "cost": 2, "kind": "support", "target": "ally", "fx": "warmth_one", "icon": "heart",
		"effects": [{"t": "heal", "pct": 0.35}, {"t": "regen", "pct": 0.08, "dur": 3}, {"t": "buff", "cat": "dmg_taken", "v": -0.20, "dur": 2}],
		"desc": "아군 1: 체력 35% 회복 + 지속 회복: 그 아군이 행동을 마칠 때마다 8% 회복 (3번) + 받는 피해 −20% (적 행동 2번)", "ref": "멀린식 단일 회복 + 보호 (도발은 파도 버티기로 옮김 — 약한 아군을 고치며 과녁으로 만들지 않게)"},
	"wave_hold": {"name": "파도 버티기", "cost": 2, "kind": "support", "target": "self", "fx": "seal", "icon": "wall",
		"effects": [{"t": "taunt", "who": "self", "dur": 3}, {"t": "hit_stack", "who": "self", "v": 0.08, "max": 5, "dur": 5, "stack_dur": 6, "to": "allies"}],
		"desc": "자신: 도발 (적 행동 3번) + 적 행동 5번 동안 맞을 때마다 아군 전체 공격력 +8% 한 겹 (최대 5겹, 겹마다 행동 6번)", "ref": "가레스 S2(맞을 때마다 쌓임) + 마슈 도발 — 버틴 시간이 파티 피해로"},
	"current": {"name": "밀려오는 조류", "cost": 3, "kind": "support", "target": "allies", "fx": "blessing", "icon": "up",
		"effects": [{"t": "buff", "who": "allies", "cat": "dmg_taken", "v": -0.15, "dur": 2}, {"t": "credits", "who": "allies", "v": 1}],
		"desc": "아군 전체: 받는 피해 −15% (적 행동 2번) + 크레딧 +1", "ref": "캐스토리아 S1의 전체 충전 — 물은 보호 + 크레딧 (불의 축복과 같던 공격력 +30%는 뺌, 단계 E E6)"},
	"high_tide": {"name": "밀물", "cost": 3, "kind": "support", "target": "ally", "fx": "share_ember", "icon": "tide",
		"effects": [{"t": "credits", "v": 2}, {"t": "buff", "cat": "atk", "v": 0.30, "dur": 3}, {"t": "buff", "cat": "ult_dmg", "v": 0.20, "dur": 3}],
		"desc": "아군 1: 크레딧 +2 + 공격력 +30% · 대마법 위력 +20% (대마법 위력은 공격 대마법 피해에만, 행동 3번)", "ref": "캐스토리아 S2 — 단일 충전 + 버프 (교환비 0.67) + 보구 위력 몫 (F-4)"},
	"water_veil": {"name": "물의 장막", "cost": 4, "kind": "support", "target": "allies", "fx": "seal", "icon": "shield",
		"effects": [{"t": "invincible", "who": "allies", "dur": 1}, {"t": "heal", "who": "allies", "pct": 0.15}],
		"desc": "아군 전체: 무적 (다음 적 행동 1번) + 체력 15% 회복", "ref": "멀린 S2의 전체 무적 (무적은 4비용 — 봉공과 맞춤)"},
	"sea_embrace": {"name": "바다의 품", "cost": 4, "kind": "support", "target": "ally_any", "fx": "cradle", "icon": "cradle",
		"effects": [{"t": "revive", "pct": 0.40}, {"t": "credits", "v": 1}],
		"desc": "아군 1: 되살림 40% (살아 있으면 40% 회복) + 크레딧 +1", "ref": "부활"},
	"ocean_blessing": {"name": "대해의 축복", "cost": 5, "kind": "support", "target": "allies", "fx": "sun_blessing", "icon": "sun",
		"effects": [{"t": "buff", "who": "allies", "cat": "crit_dmg", "v": 0.50, "dur": 3}, {"t": "buff", "who": "allies", "cat": "dmg_taken", "v": -0.30, "dur": 3}, {"t": "credits", "who": "allies", "v": 1}],
		"desc": "아군 전체: 크리 데미지 +50% (행동 3번) + 받는 피해 −30% (적 행동 3번) + 크레딧 +1", "ref": "전체 버프 겹치기"},

	# ── 글라시아: 물 · 술사 (공격 4 + 디버프 5 + 보조 1) — 늦추고 깎는다: 게이지 · 차지 · 기절
	"rime": {"name": "서리 내림", "cost": 1, "kind": "debuff", "target": "enemy", "fx": "hex", "icon": "snow",
		"effects": [{"t": "mark", "kind": "frost", "dur": 4}, {"t": "enemy_gauge", "v": 0.10}, {"t": "credits", "who": "self", "v": 1, "if_mark": "frost"}],
		"desc": "빙결 1겹 (적 행동 4번) + 적 게이지 −10%. 빙결 적이면 자신 크레딧 +1 (맞기 전 빙결 기준)", "ref": "징표 + 지연 + 물의 환급 (술사도 순환에 들어감, 단계 E E6)"},
	"thin_ice": {"name": "살얼음 깔기", "cost": 2, "kind": "debuff", "target": "enemies", "fx": "hex_all", "icon": "net",
		"effects": [{"t": "debuff", "who": "enemies", "cat": "final_taken", "v": 0.15, "dur": 2, "mark": "frost"}, {"t": "enemy_gauge", "who": "enemies", "v": 0.10, "frost_x2": true}],
		"desc": "적 전체: 빙결 적이면 받는 최종 데미지 +15% (적 행동 2번) + 게이지 −10% (빙결이면 −20%)", "ref": "광역 지연 + 얼어붙은 적이 깨지기 쉬워짐 (F-4: 늦춘 것이 피해로 돌아오게)"},
	"icicle": {"name": "고드름 투척", "cost": 2, "kind": "attack", "target": "enemy", "mult": 2.2, "fx": "fireball", "icon": "shard",
		"effects": [{"t": "multi", "n": 2}, {"t": "mark", "kind": "frost", "dur": 3}, {"t": "enemy_gauge", "v": 0.15, "if_mark": "frost"}],
		"desc": "2.2배 피해를 2번으로 나눠 + 빙결 1겹 (적 행동 3번). 빙결 적이면 게이지 −15% (맞기 전 빙결 기준)", "ref": "징표 심기 + 조건 지연 (F-4: 늦출 때마다 패시브가 붙는 싼 칸)"},
	"blizzard": {"name": "눈보라", "cost": 3, "kind": "debuff", "target": "enemies", "fx": "ash_storm", "icon": "storm",
		"effects": [{"t": "mark", "who": "enemies", "kind": "frost", "dur": 3}, {"t": "debuff", "who": "enemies", "cat": "def_down", "v": 0.15, "dur": 3}],
		"desc": "적 전체: 빙결 1겹 (적 행동 3번) + 방어 다운 15% (적 행동 3번)", "ref": "스카디 S2의 광역 방어 다운 + 징표"},
	"ice_wall": {"name": "얼음 벽", "cost": 3, "kind": "support", "target": "allies", "fx": "fire_wall", "icon": "wall",
		"effects": [{"t": "buff", "who": "allies", "cat": "dmg_taken", "v": -0.40, "dur": 2}, {"t": "enemy_gauge", "who": "enemies", "v": 0.20}],
		"desc": "아군 전체: 받는 피해 −40% (적 행동 2번) + 적 전체 게이지 −20%", "ref": "보호 + 지연 (R2: 게이지를 깎은 적 모두 패시브 방어 다운 — 무리에게 광역 방어 다운)",
		"fit": "아주 아픈 전투(시련)·적이 셋 이상인 전투 — 깎인 적 모두 패시브로 방어 다운 15%"},
	"still_frost": {"name": "멎는 서리", "cost": 3, "kind": "debuff", "target": "enemy", "fx": "hex", "icon": "ring",
		"effects": [{"t": "enemy_charge", "v": 1}, {"t": "mark", "kind": "frost", "dur": 3}, {"t": "debuff", "cat": "def_down", "v": 0.20, "dur": 3}],
		"desc": "적 1: 차지 −1 (가득 차 보이던 필살기는 거둬짐) + 빙결 1겹 (적 행동 3번) + 방어 다운 20% (적 행동 3번)", "ref": "제갈공명 보구의 방어 다운 + 차지 감소 — 보스는 성공률 70% (패시브로 85%), 단계 E E4"},
	"deep_freeze": {"name": "완전 동결", "cost": 4, "kind": "debuff", "target": "enemy", "fx": "hex", "icon": "lock",
		"effects": [{"t": "stun"}, {"t": "debuff", "cat": "def_down", "v": 0.30, "dur": 2}, {"t": "mark", "kind": "frost", "dur": 3}],
		"desc": "적 1: 기절 (다음 차례 쉼) + 방어 다운 30% (적 행동 2번) + 빙결 1겹 (적 행동 3번)", "ref": "얼려 멈춤 (보스는 기절 면역 — 방어 다운·빙결은 들어감)"},
	"ice_coffin": {"name": "얼음 관", "cost": 4, "kind": "attack", "target": "enemy", "mult": 5.1, "fx": "stake", "icon": "coffin",
		"effects": [{"t": "enemy_gauge", "v": 0.50, "if_mark": "frost"}, {"t": "debuff", "cat": "def_down", "v": 0.20, "dur": 2}],
		"desc": "5.1배 피해 + 방어 다운 20% (적 행동 2번). 빙결 적이면 게이지 −50%", "ref": "조건 지연"},
	"permafrost": {"name": "영구 동토", "cost": 5, "kind": "attack", "target": "enemies", "mult": 4.0, "fx": "conflagration", "icon": "burst",
		"effects": [{"t": "this_special", "mark": "frost", "v": 0.50}, {"t": "enemy_gauge", "who": "enemies", "v": 0.30}],
		"desc": "적 전체 4.0배 피해, 빙결 적에게 이 공격만 특공 +50% + 적 전체 게이지 −30%", "ref": "광역 마무리 + 지연"},
	"winter_oath": {"name": "겨울의 맹세", "cost": 5, "kind": "support", "target": "allies", "fx": "sun_blessing", "icon": "oath",
		"effects": [{"t": "buff", "who": "allies", "cat": "special", "mark": "frost", "v": 0.12, "dur": 3}, {"t": "buff", "who": "allies", "cat": "dmg_taken", "v": -0.20, "dur": 3}, {"t": "credits", "who": "allies", "v": 1}],
		"desc": "아군 전체: 빙결 특공 1겹마다 +12% (물 공격만 겹을 곱함, 행동 3번) + 받는 피해 −20% (적 행동 3번) + 크레딧 +1", "ref": "전체 버프 겹치기 (R2: 빙결 특공 20 → 12%/겹 — 물은 한 방 배율이 가장 낮다, review_L §5.2)"},

	# ── 풀구르: 번개 · 딜러 (공격 8 + 보조 2) — 평타 크리 · 다단: 기본 공격 3히트, 횟수제 크리 버프, 크리마다 게이지
	"spark_bolt": {"name": "전광 스파크", "cost": 1, "kind": "attack", "target": "enemy", "mult": 2.0, "fx": "fireball", "icon": "spark",
		"effects": [{"t": "multi", "n": 2}, {"t": "mark", "kind": "shock", "dur": 3}], "desc": "2.0배 피해를 2번으로 나눠 + 감전 1겹 (적 행동 3번)", "ref": "징표 심기 (다단)"},
	"chain_lightning": {"name": "연쇄 번개", "cost": 2, "kind": "attack", "target": "enemies", "mult": 1.4, "fx": "ash_storm", "icon": "chain",
		"effects": [{"t": "mark", "who": "enemies", "kind": "shock", "dur": 2}], "desc": "적 전체 1.4배 피해 + 전체 감전 1겹 (적 행동 2번)", "ref": "싼 광역 (배율 낮음)"},
	"charge_up": {"name": "충전", "cost": 1, "kind": "support", "target": "self", "fx": "focus", "icon": "focus",
		"effects": [{"t": "buff", "who": "self", "cat": "crit_rate", "v": 0.60, "dur": 7, "count": 3, "on": "basic"}, {"t": "buff", "who": "self", "cat": "crit_dmg", "v": 1.50, "dur": 7, "count": 3, "on": "basic"}],
		"desc": "자신: 기본 공격 3번 동안 크리 확률 +60% · 크리 데미지 +150% (마법에는 닳지 않음, 행동 6번 안에)", "ref": "초인 오리온 S3 '버스터 공격 시 크리 위력 3회' — 횟수제 (§16.8)"},
	"thunderbolt": {"name": "벼락 내리꽂기", "cost": 3, "kind": "attack", "target": "enemy", "mult": 5.0, "fx": "pillar", "icon": "bolt",
		"effects": [{"t": "multi", "n": 4}, {"t": "crit_gauge", "v": 0.05}],
		"desc": "5.0배 피해를 4번으로 나눠 맞힘. 크리 1번마다 자신 게이지 +5%", "ref": "퀵식 다단 — 크리가 다음 차례를 당긴다"},
	"flash": {"name": "섬광 질주", "cost": 3, "kind": "attack", "target": "enemy", "mult": 4.3, "fx": "whip", "icon": "dash",
		"effects": [{"t": "gauge", "who": "self", "v": 0.30}, {"t": "mark", "kind": "shock", "dur": 2}],
		"desc": "4.3배 피해 + 자신 게이지 +30% + 감전 1겹 (적 행동 2번)", "ref": "속도"},
	"current_share": {"name": "전류 나눔", "cost": 2, "kind": "support", "target": "ally", "fx": "breath", "icon": "link",
		"effects": [{"t": "buff", "cat": "crit_rate", "v": 0.40, "dur": 3, "mark": "shock"}, {"t": "buff", "cat": "crit_dmg", "v": 0.50, "dur": 3, "mark": "shock"}, {"t": "credits", "v": 1}],
		"desc": "아군 1: 감전 적에게 크리 확률 +40% · 크리 데미지 +50% (행동 3번) + 크레딧 +1", "ref": "딜러가 남을 밀어 주는 크리 버프 (게이지는 아스트라 몫)"},
	"thunderstorm": {"name": "뇌우", "cost": 4, "kind": "attack", "target": "enemies", "mult": 4.0, "fx": "ash_storm", "icon": "storm",
		"effects": [{"t": "multi", "n": 2}, {"t": "mark", "who": "enemies", "kind": "shock", "dur": 3}], "desc": "적 전체 4.0배 피해를 2번으로 나눠 + 전체 감전 1겹 (적 행동 3번)", "ref": "광역 보구 + 광역 징표"},
	"lightning_strike": {"name": "낙뢰 심판", "cost": 4, "kind": "attack", "target": "enemy", "mult": 6.0, "fx": "meteor", "icon": "bolt_big",
		"effects": [{"t": "multi", "n": 3, "per_mark": "shock"}, {"t": "buff", "who": "self", "cat": "crit_rate", "mark": "shock", "v": 0.40, "dur": 1, "pre": true}, {"t": "crit_gauge", "v": 0.04}],
		"desc": "공격 직전 감전 적에게 자신 크리 확률 +40% → 6.0배 피해를 (3 + 감전 겹)번으로 나눠 (최대 8번, 히트마다 크리 판정). 크리 1번마다 자신 게이지 +4%", "ref": "조건 크리 + 겹만큼 잦은 다단 (F-4: 천둥의 창과 턴당 같던 것을 '감전이 쌓이면 자주 친다'로)"},
	"thunder_lance": {"name": "천둥의 창", "cost": 5, "kind": "attack", "target": "enemy", "mult": 7.0, "fx": "sun_spear", "icon": "spear",
		"effects": [{"t": "buff", "who": "self", "cat": "crit_dmg", "v": 0.50, "dur": 1, "pre": true}, {"t": "on_crit", "effects": [{"t": "gauge", "who": "self", "v": 0.50}]}],
		"desc": "공격 직전 자신 크리 데미지 +50% (행동 1번) → 7.0배 피해. 크리면 자신 게이지 +50%", "ref": "한 방 + 크리 조건 보너스"},
	"storm_god": {"name": "뇌신 강림", "cost": 5, "kind": "attack", "target": "enemies", "mult": 4.7, "fx": "conflagration", "icon": "burst",
		"effects": [{"t": "multi", "n": 3}, {"t": "this_special", "mark": "shock", "v": 0.60}],
		"desc": "적 전체 4.7배 피해를 3번으로 나눠 (각 1.57배) + 감전 적에게 이 공격만 특공 +60%", "ref": "다단 히트 광역 마무리"},

	# ── 아스트라: 번개 · 버퍼 (공격 1 + 보조 9) — 크리를 맞춰 주고 차례를 당긴다
	"static": {"name": "정전기 튕기기", "cost": 1, "kind": "attack", "target": "enemy", "mult": 1.6, "fx": "fireball_small", "icon": "spark",
		"effects": [{"t": "multi", "n": 2}, {"t": "mark", "kind": "shock", "dur": 3}], "desc": "1.6배 피해를 2번으로 나눠 + 감전 1겹 (적 행동 3번)", "ref": "버퍼의 징표"},
	"lightning_cloak": {"name": "번개 옷", "cost": 2, "kind": "support", "target": "ally", "fx": "kindling", "icon": "cloak",
		"effects": [{"t": "buff", "cat": "element", "el": "bolt", "dur": 3}, {"t": "buff", "cat": "crit_dmg", "v": 0.50, "dur": 3, "el": "bolt"}],
		"desc": "아군 1: 공격에 번개 속성 부여 + 번개 공격 크리 데미지 +50% (행동 3번)", "ref": "속성 부여"},
	"rod": {"name": "피뢰침 세우기", "cost": 2, "kind": "support", "target": "ally", "fx": "bellows", "icon": "rod",
		"effects": [{"t": "buff", "cat": "special", "mark": "shock", "v": 0.25, "dur": 3}, {"t": "buff", "cat": "crit_rate", "v": 0.30, "dur": 3}],
		"desc": "아군 1: 감전 특공 1겹마다 +25% (번개 공격만 겹을 곱함) + 크리 확률 +30% (행동 3번)", "ref": "특공 부여"},
	"spur": {"name": "박차 가하기", "cost": 2, "kind": "support", "target": "ally", "fx": "leap", "icon": "clock_fwd",
		"effects": [{"t": "gauge", "v": 0.60}], "desc": "아군 1: 행동 게이지 +60% (패시브로 +80%)", "ref": "단일 차례 당기기"},
	"star_touch": {"name": "별의 손길", "cost": 2, "kind": "support", "target": "ally", "fx": "stigma", "icon": "eye",
		"effects": [{"t": "buff", "cat": "crit_dmg", "v": 1.00, "dur": 7, "count": 3, "on": "basic"}],
		"desc": "아군 1: 기본 공격 3번 동안 크리 데미지 +100% (마법에는 닳지 않음, 행동 7번 안에)", "ref": "초인 오리온 S3의 횟수제 크리 위력을 남에게"},
	"starlight": {"name": "별빛 가루", "cost": 3, "kind": "support", "target": "allies", "fx": "blessing", "icon": "sparkle",
		"effects": [{"t": "buff", "who": "allies", "cat": "crit_rate", "v": 0.30, "dur": 3}, {"t": "buff", "who": "allies", "cat": "crit_dmg", "v": 0.30, "dur": 3}, {"t": "heal", "who": "allies", "pct": 0.15}],
		"desc": "아군 전체: 크리 확률 +30% + 크리 데미지 +30% (행동 3번) + 체력 15% 회복", "ref": "전체 크리 버프 + 작은 전체 회복 (단계 E E1)"},
	"guide_bolt": {"name": "번개 길잡이", "cost": 3, "kind": "support", "target": "ally", "fx": "leap", "icon": "dash",
		"effects": [{"t": "buff", "cat": "crit_rate", "v": 0.40, "dur": 3}, {"t": "gauge", "v": 0.40}],
		"desc": "아군 1: 크리 확률 +40% (행동 3번) + 행동 게이지 +40% (패시브로 +60%)", "ref": "스카디 S1 — 단일 색 버프 + 차례"},
	"overcharge": {"name": "별빛 역류", "cost": 4, "kind": "support", "target": "ally", "fx": "god_descent", "icon": "ascend",
		"effects": [{"t": "buff", "cat": "crit_dmg", "v": 1.00, "dur": 1}, {"t": "buff", "cat": "crit_rate", "v": 0.50, "dur": 1}, {"t": "gauge", "v": 1.00}, {"t": "demerit_zero"}],
		"desc": "아군 1: 크리 데미지 +100% + 크리 확률 +50% (행동 1번) + 게이지 100%. 대가: 그 행동 뒤 크레딧 0", "ref": "오베론 S3의 한 번 크게"},
	"lightning_share": {"name": "번개 나눔", "cost": 4, "kind": "support", "target": "ally", "fx": "share_ember", "icon": "link",
		"effects": [{"t": "credits", "v": 3}, {"t": "gauge", "v": 0.30}, {"t": "buff", "cat": "ult_dmg", "v": 0.30, "dur": 3}],
		"desc": "아군 1: 크레딧 +3 + 행동 게이지 +30% (패시브로 +50%) + 대마법 위력 +30% (공격 대마법 피해에만, 행동 3번)", "ref": "스카디 S3의 단일 충전 (교환비 0.75) + 보구 위력 몫 (F-4: 배터리가 버프와 겨룰 수 있게)"},
	"meteor_blessing": {"name": "유성우의 축복", "cost": 5, "kind": "support", "target": "allies", "fx": "sun_blessing", "icon": "starfall",
		"effects": [{"t": "buff", "who": "allies", "cat": "atk", "v": 0.30, "dur": 3}, {"t": "buff", "who": "allies", "cat": "crit_dmg", "v": 0.50, "dur": 3}, {"t": "gauge", "who": "allies", "v": 0.20}],
		"desc": "아군 전체: 공격력 +30% + 크리 데미지 +50% (행동 3번) + 행동 게이지 +20%", "ref": "전체 버프 겹치기"},

	# ── 토난: 번개 · 술사 (공격 4 + 디버프 5 + 보조 1) — 감전 = 크리의 과녁
	"needle": {"name": "번개 바늘", "cost": 1, "kind": "debuff", "target": "enemy", "fx": "hex", "icon": "needle",
		"effects": [{"t": "mark", "kind": "shock", "dur": 4}, {"t": "debuff", "cat": "def_down", "v": 0.10, "dur": 2}],
		"desc": "감전 1겹 (적 행동 4번) + 방어 다운 10% (적 행동 2번)", "ref": "징표를 오래 깔기"},
	"overcurrent": {"name": "과전류", "cost": 2, "kind": "debuff", "target": "enemy", "fx": "hex", "icon": "net",
		"effects": [{"t": "debuff", "cat": "crit_dmg_taken", "v": 0.12, "dur": 3, "mark": "shock", "per_mark": true}],
		"desc": "적 1: 받는 크리 데미지 +12% × 감전 겹 (적 행동 3번 · 감전이 없으면 0 · 크리 데미지 상한과 따로)", "ref": "스카디 S2의 크리 약화를 '받는 크리 위력'으로 — 크리 확률이 100%에 닿은 파티에도 산다 (F-4 P3)"},
	"volt": {"name": "뇌격", "cost": 2, "kind": "attack", "target": "enemy", "mult": 3.2, "fx": "fireball", "icon": "spark",
		"effects": [{"t": "stun", "if_mark": "shock", "else_debuff": {"cat": "crit_taken", "v": 0.20, "dur": 2}}], "desc": "3.2배 피해. 감전 적이면 기절 (다음 차례 쉼) — 기절 면역(보스)이면 대신 이 적을 때리는 아군 크리 확률 +20% (적 행동 2번)", "ref": "번개의 마비 (F-4: 보스에게 죽은 칸이던 것을 차지 감소로 · R2: 차지 감소는 물·시간 독점이라 번개 몫인 크리로, review_L §5.3)"},
	"thunder": {"name": "우레 선포", "cost": 3, "kind": "debuff", "target": "enemies", "fx": "hex_all", "icon": "wave_out",
		"effects": [{"t": "mark", "who": "enemies", "kind": "shock", "dur": 3}, {"t": "debuff", "who": "enemies", "cat": "def_down", "v": 0.15, "dur": 3}],
		"desc": "적 전체: 감전 1겹 (적 행동 3번) + 방어 다운 15% (적 행동 3번)", "ref": "광역 징표 + 광역 디버프"},
	"shock_spread": {"name": "감전 번짐", "cost": 3, "kind": "debuff", "target": "enemy", "fx": "hex_all", "icon": "fan",
		"effects": [{"t": "mark", "kind": "shock", "dur": 3}, {"t": "spread", "kind": "shock"}],
		"desc": "적 1: 감전 1겹 (적 행동 3번) → 그 적의 감전 겹 수만큼 다른 적 전체에 감전", "ref": "신더 재 번짐과 같은 실행기"},
	"discharge": {"name": "방전 파도", "cost": 3, "kind": "attack", "target": "enemies", "mult": 4.3, "fx": "conflagration", "icon": "ring",
		"effects": [{"t": "multi", "n": 2}, {"t": "this_special", "mark": "shock", "v": 0.40}], "desc": "적 전체 4.3배 피해를 2번으로 나눠, 감전 적에게 이 공격만 특공 +40%", "ref": "징표 적 광역 특공"},
	"shock_brand": {"name": "감전 낙인", "cost": 4, "kind": "debuff", "target": "enemy", "fx": "hex", "icon": "brand",
		"effects": [{"t": "debuff", "cat": "def_down", "v": 0.30, "dur": 3}, {"t": "debuff", "cat": "crit_taken", "v": 0.30, "dur": 3}],
		"desc": "적 1: 방어 다운 30% + 이 적을 때리는 아군 크리 확률 +30% (적 행동 3번)", "ref": "대상 조건 크리"},
	"conduction": {"name": "전도 사슬", "cost": 4, "kind": "attack", "target": "enemy", "mult": 5.4, "fx": "meteor", "icon": "chain",
		"effects": [{"t": "mark", "kind": "shock", "dur": 4}, {"t": "mark", "who": "others", "kind": "shock", "dur": 2}],
		"desc": "5.4배 피해 + 감전 1겹 (적 행동 4번) + 다른 적 전체 감전 1겹 (적 행동 2번)", "ref": "징표 번지기"},
	"thundercloud": {"name": "뇌운", "cost": 5, "kind": "attack", "target": "enemies", "mult": 4.7, "fx": "ash_storm", "icon": "storm",
		"effects": [{"t": "extend_mark", "who": "enemies", "kind": "shock", "v": 2}, {"t": "this_special", "mark": "shock", "v": 0.50}],
		"desc": "적 전체 4.7배 피해, 감전 적마다 감전 연장 +2, 이 공격만 감전 특공 +50%", "ref": "징표를 남겨 두는 광역"},
	"thunder_oath": {"name": "우레의 맹세", "cost": 5, "kind": "support", "target": "allies", "fx": "sun_blessing", "icon": "oath",
		"effects": [{"t": "buff", "who": "allies", "cat": "special", "mark": "shock", "v": 0.20, "dur": 3}, {"t": "buff", "who": "allies", "cat": "crit_rate", "v": 0.20, "dur": 3}, {"t": "credits", "who": "allies", "v": 1}],
		"desc": "아군 전체: 감전 특공 1겹마다 +20% (번개 공격만 겹을 곱함) + 크리 확률 +20% (행동 3번) + 크레딧 +1", "ref": "전체 버프 겹치기"},

	# ── 호라: 시간 · 버퍼 (공격 2 + 보조 6 + 디버프 2) — 순서·지속·차지
	"second_hand": {"name": "초침 밀기", "cost": 1, "kind": "support", "target": "ally", "fx": "leap", "icon": "clock_fwd",
		"effects": [{"t": "gauge", "v": 0.20}], "desc": "아군 1: 행동 게이지 +20%", "ref": "작은 배터리"},
	"stopped_clock": {"name": "멈춘 시계", "cost": 2, "kind": "debuff", "target": "enemy", "fx": "hex", "icon": "clock",
		"effects": [{"t": "enemy_charge", "v": 1}, {"t": "enemy_gauge", "v": 0.20}, {"t": "debuff", "cat": "final_taken", "v": 0.20, "dur": 3}],
		"desc": "적 1: 차지 −1 (가득 차 보이던 필살기는 거둬짐) + 게이지 −20% + 받는 최종 데미지 +20% (적 행동 3번)", "ref": "제갈공명 보구의 차지 감소 + 피해 쪽 부품 (보스 성공률 70%, 단계 E E4)"},
	"rewind": {"name": "되감기", "cost": 2, "kind": "support", "target": "ally", "fx": "warmth_one", "icon": "rewind",
		"effects": [{"t": "heal", "pct": 0.25}, {"t": "extend_buffs", "v": 1}, {"t": "guts", "dur": 3, "pct": 0.0}],
		"desc": "아군 1: 체력 25% 회복 + 버프 지속 +1 + 근성 1회 (적 행동 3번 안, 체력 1로 버팀)", "ref": "지속 연장 + 되감아 버팀"},
	"time_haste": {"name": "시간 가속", "cost": 3, "kind": "support", "target": "allies", "fx": "blessing", "icon": "wind",
		"effects": [{"t": "gauge", "who": "allies", "v": 0.25}, {"t": "credits", "who": "allies", "v": 1}],
		"desc": "아군 전체: 행동 게이지 +25% + 크레딧 +1", "ref": "전체 배터리 + 자원"},
	"clock_hand": {"name": "시계 바늘 찌르기", "cost": 3, "kind": "attack", "target": "enemy", "mult": 4.3, "fx": "compress", "icon": "needle",
		"effects": [{"t": "enemy_gauge", "v": 0.20}, {"t": "this_special", "trait": "construct", "v": 0.60}], "desc": "4.3배 피해 + 적 게이지 −20%. 인형 적에게 이 공격만 특공 +60%", "ref": "공격 + 지연 + 특성 특공 (F-3, review_F F02): 태엽을 멈춤"},
	"hourglass": {"name": "모래시계 뒤집기", "cost": 3, "kind": "support", "target": "ally", "fx": "stigma", "icon": "hourglass",
		"effects": [{"t": "extend_buffs", "v": 2}, {"t": "buff", "cat": "final", "v": 0.20, "dur": 2}],
		"desc": "아군 1: 버프 지속 +2 + 최종 데미지 +20% (행동 2번)", "ref": "지속 연장"},
	"once_more": {"name": "한 번 더", "cost": 4, "kind": "support", "target": "ally", "fx": "void_gate", "icon": "cycle",
		"effects": [{"t": "gauge", "v": 1.00}], "desc": "아군 1: 행동 게이지 +100% (바로 다시 행동)", "ref": "차례 당기기 (크레딧 +1은 뺌 — 차례 시작 +1이 이미 붙는다)"},
	"time_stop": {"name": "시간 정지", "cost": 4, "kind": "debuff", "target": "enemies", "fx": "gap", "icon": "lock",
		"effects": [{"t": "enemy_gauge", "who": "enemies", "v": 0.30}, {"t": "debuff", "who": "enemies", "cat": "def_down", "v": 0.20, "dur": 2}],
		"desc": "적 전체: 게이지 −30% + 방어 다운 20% (적 행동 2번)", "ref": "광역 지연 + 디버프"},
	"doomsday_clock": {"name": "종말의 시계", "cost": 5, "kind": "attack", "target": "enemies", "mult": 4.7, "fx": "blackstar", "icon": "clock_doom",
		"effects": [{"t": "enemy_gauge", "who": "enemies", "v": 0.50}], "desc": "적 전체 4.7배 피해 + 적 전체 게이지 −50%", "ref": "광역 + 차례 되돌리기"},
	"turn_back": {"name": "시간 되돌림", "cost": 5, "kind": "support", "target": "ally_any", "fx": "cradle", "icon": "cradle",
		"effects": [{"t": "revive", "pct": 0.70}, {"t": "extend_buffs", "v": 2}, {"t": "credits", "v": 1}],
		"desc": "아군 1: 되살림 70% (살아 있으면 70% 회복) + 버프 지속 +2 + 크레딧 +1", "ref": "부활 + 연장"},

	# ── 하르페: 검술 · 딜러 (공격 9 + 보조 1) — 확정된 한 방 · 흑백 참격 (실시간 데모 이펙트)
	"bw_slash": {"name": "흑백 참격", "cost": 1, "kind": "attack", "target": "enemy", "mult": 2.0, "fx": "slash", "icon": "slash",
		"effects": [{"t": "multi", "n": 2}], "desc": "2.0배 피해를 2번으로 나눠 (각 1.0배)", "ref": "다단 히트"},
	"return_cut": {"name": "되돌려 베기", "cost": 2, "kind": "attack", "target": "enemy", "mult": 2.5, "fx": "slash", "icon": "cut_curve",
		"effects": [{"t": "buff", "who": "self", "cat": "crit_dmg", "v": 0.30, "dur": 3}], "desc": "2.5배 피해 + 자신 크리 데미지 +30% (다음 행동 2번)", "ref": "공격 뒤 자기 강화 (F-4: 크리 확률은 크리 확정 마법에 0이라 크리 데미지로 — 일섬·종언참·종막의 검 앞에)"},
	"sword_dance": {"name": "검무", "cost": 2, "kind": "attack", "target": "enemies", "mult": 1.4, "fx": "slash_all", "icon": "slash2",
		"effects": [{"t": "multi", "n": 2}, {"t": "buff", "who": "self", "cat": "crit_dmg", "v": 0.40, "dur": 4, "count": 1, "on": "skill"}],
		"desc": "적 전체 1.4배 피해를 2번으로 나눠 (각 0.7배) + 자신 다음 공격 마법 1번 크리 데미지 +40% (행동 3번 안에)", "ref": "싼 광역 다단 + 다음 한 방 준비 (F-4: 졸개를 쓸며 보스 한 방을 키우는 연결 칸)"},
	"flash_cut": {"name": "일섬", "cost": 3, "kind": "attack", "target": "enemy", "mult": 3.6, "fx": "slash_big", "icon": "cut_h",
		"effects": [{"t": "sure_crit"}], "desc": "3.6배 피해, 크리 확정", "ref": "크리 확정 (3비용 예산 5.0배: 확정 크리 ×1.4 → 3.6배)"},
	"space_cut": {"name": "갑주 가르기", "cost": 3, "kind": "attack", "target": "enemy", "mult": 4.3, "fx": "slash_big", "icon": "cut_h",
		"effects": [{"t": "this_special", "trait": "armored", "v": 0.60}, {"t": "debuff", "cat": "def_down", "v": 0.15, "dur": 2}],
		"desc": "4.3배 피해 + 방어 다운 15% (적 행동 2번). 갑각 적에게 이 공격만 특공 +60%", "ref": "특성 특공 (F-3, review_F F02): 검으로 껍질을 가름 — 옛 공간참(방어 무시)을 바꿈. 갑각 적(방어 25~35%)에게 4.3 × 1.6 × 0.7 ≈ 4.8배"},
	"sword_ki": {"name": "검기 두르기", "cost": 3, "kind": "support", "target": "self", "fx": "focus", "icon": "aura",
		"effects": [{"t": "buff", "who": "self", "cat": "atk", "v": 0.40, "dur": 3}, {"t": "buff", "who": "self", "cat": "crit_dmg", "v": 0.40, "dur": 3}],
		"desc": "자신: 공격력 +40% + 크리 데미지 +40% (다음 행동 2번)", "ref": "딜러의 자기 강화 (자기 차례에 걸어 행동 3번 = 다음 2행동)"},
	"heaven_split": {"name": "천열", "cost": 4, "kind": "attack", "target": "enemy", "mult": 6.0, "fx": "slash_big", "icon": "cut_v",
		"effects": [{"t": "buff", "who": "self", "cat": "crit_dmg", "v": 0.50, "dur": 2, "pre": true}],
		"desc": "공격 직전 자신 크리 데미지 +50% (이 행동과 다음 행동 1번) → 6.0배 피해", "ref": "선버프 강타 (4비용 예산 6.0배)"},
	"sword_wind": {"name": "검풍", "cost": 4, "kind": "attack", "target": "enemies", "mult": 4.0, "fx": "slash_all", "icon": "fan",
		"effects": [{"t": "multi", "n": 3}, {"t": "debuff", "who": "enemies", "cat": "def_down", "v": 0.15, "dur": 2}],
		"desc": "적 전체 4.0배 피해를 3번으로 나눠 + 방어 다운 15% (적 행동 2번)", "ref": "광역 다단 + 디버프"},
	"doom_slash": {"name": "종언참", "cost": 5, "kind": "attack", "target": "enemy", "mult": 5.3, "fx": "slash_doom", "icon": "slash_doom",
		"effects": [{"t": "sure_crit"}, {"t": "ignore_def"}],
		"desc": "5.3배 피해, 크리 확정, 이 공격만 적 방어율 무시", "ref": "한 방 (5비용 예산 7.0배: 확정 크리 ×1.4 → 5.3배)"},
	"bw_dance": {"name": "흑백 난무", "cost": 5, "kind": "attack", "target": "enemies", "mult": 5.3, "fx": "slash_all_big", "icon": "slash_x",
		"effects": [{"t": "multi", "n": 3}, {"t": "on_crit", "effects": [{"t": "gauge", "who": "self", "v": 0.30}]}],
		"desc": "적 전체 5.3배 피해를 3번으로 나눠 (각 1.77배). 크리면 자신 게이지 +30%", "ref": "광역 다단 마무리"},

	# ── 대마법 12 (combat_proto.md §13 · §24.4) — 비용 7 = 크레딧 전부, 바퀴 끝 칸. 연쇄 2·3단계면 부가 효과 ×1.25·×1.5 (§13.6)
	"ult_ignis": {"name": "태양 붕괴", "cost": 7, "ultimate": true, "kind": "attack", "target": "enemy", "mult": 9.0, "fx": "sun_spear", "icon": "sun",
		"effects": [{"t": "burst", "mark": "burn", "per": 1.00}, {"t": "mark", "who": "enemies", "kind": "burn", "dur": 3}],
		"desc": "9.0배 피해 + 화상 터뜨리기 (겹마다 +1.0배). 맞힌 뒤 적 전체 화상 1겹 (적 행동 3번)", "ref": "단일 한 방 + 특공 보구 (겹 비례), 뒤효과로 다음 아군의 특공 조건을 깐다"},
	"ult_ember": {"name": "불새의 축복", "cost": 7, "ultimate": true, "kind": "support", "target": "allies", "fx": "sun_blessing", "icon": "ascend",
		"effects": [{"t": "buff", "who": "allies", "cat": "atk", "v": 0.50, "dur": 2}, {"t": "buff", "who": "allies", "cat": "crit_dmg", "v": 0.50, "dur": 2}, {"t": "credits", "who": "other_allies", "v": 2}],
		"desc": "아군 전체: 공격력 +50% (패시브로 +60%) + 크리 데미지 +50% (행동 2번) + 다른 아군 크레딧 +2", "ref": "전체 2종 + 자원 (자기 충전은 뺌)"},
	"ult_cinder": {"name": "잿빛 장례", "cost": 7, "ultimate": true, "kind": "attack", "target": "enemies", "mult": 2.0, "fx": "conflagration", "icon": "bloom",
		"effects": [{"t": "mark", "who": "enemies", "kind": "burn", "dur": 4, "n": 3}, {"t": "debuff", "who": "enemies", "cat": "def_down", "v": 0.30, "dur": 3}],
		"desc": "적 전체 2.0배 피해 + 화상 3겹 (적 행동 4번, 패시브로 4겹) + 방어 다운 30% (적 행동 3번)", "ref": "보구 뒤 약화 — 다음 아군 공격을 키움"},
	"ult_undine": {"name": "심연 붕괴", "cost": 7, "ultimate": true, "kind": "attack", "target": "enemy", "mult": 9.0, "fx": "sun_spear", "icon": "converge",
		"effects": [{"t": "this_special", "mark": "frost", "v": 0.15}, {"t": "credits", "who": "self", "v": 2}, {"t": "mark", "kind": "frost", "dur": 3}],
		"desc": "9.0배 피해, 빙결 적에게 이 공격만 특공 +15% + 자신 크레딧 +2 + 빙결 1겹 (적 행동 3번)", "ref": "약속된 승리의 검 — 광역 대신 단일, NP 리차지 구조 (환급 2 — 배터리 둘의 유입이 7을 넘지 않게, 단계 E E2)"},
	"ult_nerei": {"name": "해류의 성소", "cost": 7, "ultimate": true, "kind": "support", "target": "allies", "fx": "seal", "icon": "ring",
		"effects": [{"t": "invincible", "who": "allies", "dur": 1}, {"t": "buff", "who": "allies", "cat": "dmg_taken", "v": -0.30, "dur": 3}, {"t": "heal", "who": "allies", "pct": 0.15},
			{"t": "regen", "who": "allies", "pct": 0.10, "dur": 4}, {"t": "revive", "who": "dead_allies", "pct": 0.30}],
		"desc": "아군 전체: 무적 (적 행동 1번) + 받는 피해 −30% (적 행동 3번) + 체력 15% 회복 + 지속 회복: 각자 행동을 마칠 때마다 10% 회복 (4번) + 쓰러진 아군을 체력 30%로 되살림", "ref": "멀린 보구 — 매 차례 회복(지속 회복)과 보호 (F-4: 엔진에 지속 회복을 넣어 구조대로. 무적 관통 필살기에도 피해 감소·회복은 남는다)"},
	"ult_glacia": {"name": "절대 영도", "cost": 7, "ultimate": true, "kind": "debuff", "target": "enemies", "fx": "hex_all", "icon": "eclipse",
		"effects": [{"t": "mark", "who": "enemies", "kind": "frost", "dur": 4, "n": 3}, {"t": "enemy_gauge", "who": "enemies", "v": 0.50},
			{"t": "debuff", "who": "enemies", "cat": "def_down", "v": 0.20, "dur": 3}, {"t": "enemy_charge", "who": "enemies", "v": 1}],
		"desc": "적 전체: 빙결 3겹 (적 행동 4번) + 게이지 −50% + 방어 다운 20% (적 행동 3번) + 차지 −1", "ref": "제갈공명 보구 — 방어 다운 + 차지 감소 (기절은 보스에게 무효라 뺌)"},
	"ult_fulgur": {"name": "뇌신의 철퇴", "cost": 7, "ultimate": true, "kind": "attack", "target": "enemy", "mult": 9.0, "fx": "meteor", "icon": "meteor",
		"effects": [{"t": "multi", "n": 5}, {"t": "buff", "who": "self", "cat": "crit_rate", "v": 0.30, "dur": 1, "pre": true},
			{"t": "buff", "who": "self", "cat": "crit_dmg", "v": 0.80, "dur": 7, "count": 3, "on": "basic"}],
		"desc": "공격 직전 자신 크리 확률 +30% → 9.0배 피해를 5번으로 나눠. 뒤에 자신: 기본 공격 3번 동안 크리 데미지 +80%", "ref": "초인 오리온 보구 — 피해 뒤 평타 크리를 키우는 자기 강화"},
	"ult_astra": {"name": "유성의 행진", "cost": 7, "ultimate": true, "kind": "support", "target": "allies", "fx": "sun_blessing", "icon": "sun",
		"effects": [{"t": "buff", "who": "allies", "cat": "crit_rate", "v": 0.50, "dur": 2}, {"t": "buff", "who": "allies", "cat": "crit_dmg", "v": 0.50, "dur": 2}, {"t": "gauge", "who": "other_allies", "v": 1.00}],
		"desc": "아군 전체: 크리 확률 +50% + 크리 데미지 +50% (행동 2번) + 다른 아군 행동 게이지 +100%", "ref": "전체 2종 + 차례"},
	"ult_tonan": {"name": "천둥 선고", "cost": 7, "ultimate": true, "kind": "attack", "target": "enemies", "mult": 2.0, "fx": "ash_storm", "icon": "bolt_big",
		"effects": [{"t": "mark", "who": "enemies", "kind": "shock", "dur": 4, "n": 3}, {"t": "debuff", "who": "enemies", "cat": "crit_taken", "v": 0.20, "dur": 3},
			{"t": "debuff", "who": "enemies", "cat": "crit_dmg_taken", "v": 0.08, "dur": 3, "mark": "shock", "per_mark": true}],
		"desc": "적 전체 2.0배 피해 + 감전 3겹 (적 행동 4번) + 이 적을 때리는 아군 크리 확률 +20% · 크리 데미지 감전 1겹마다 +8% (적 행동 3번)", "ref": "보구 뒤 약화 (F-4: 크리 확률만이면 100%에 막혀 넘쳤다 — 받는 크리 위력을 함께)"},
	"ult_eska": {"name": "세계의 끝", "cost": 7, "ultimate": true, "kind": "attack", "target": "enemies", "mult": 6.8, "fx": "blackstar", "icon": "burst",
		"effects": [{"t": "ignore_def"}, {"t": "debuff", "who": "enemies", "cat": "def_down", "v": 0.20, "dur": 3}],
		"desc": "적 전체 6.8배 피해, 이 공격만 적 방어율 무시 + 방어 다운 20% (적 행동 3번)", "ref": "광역 6.8배 (방어 무시 — 단일 종언 6.0배 + 선버프보다 한 대상에도 크다)"},
	"ult_hora": {"name": "시간의 정적", "cost": 7, "ultimate": true, "kind": "support", "target": "allies", "fx": "gap", "icon": "ring",
		"effects": [{"t": "enemy_charge", "who": "enemies", "v": 1}, {"t": "enemy_gauge", "who": "enemies", "v": 0.50}, {"t": "extend_buffs", "who": "allies", "v": 2}, {"t": "gauge", "who": "other_allies", "v": 0.40}],
		"desc": "적 전체 차지 −1 + 게이지 −50% + 아군 전체 버프 지속 +2 + 다른 아군 행동 게이지 +40%", "ref": "제갈공명 보구의 차지 감소 + 시간 연장 + 순서 당기기 (F-4: 연쇄로 커지는 칸 — 게이지가 ×1.25·×1.5)"},
	"ult_harpe": {"name": "종막의 검", "cost": 7, "ultimate": true, "kind": "attack", "target": "enemy", "mult": 6.8, "fx": "slash_doom", "icon": "eclipse",
		"effects": [{"t": "multi", "n": 6}, {"t": "sure_crit"}, {"t": "ignore_def"}],
		"desc": "6.8배 피해를 6번으로 나눠, 크리 확정, 이 공격만 적 방어율 무시", "ref": "단일 6.8배 확정 크리 + 방어 무시 (×1.4 = 9.5배 상당, 방어 30% 적에겐 13.6배 — D2·E2에서 8 → 6.8)"},
}

## 장비 (캐릭터당 1개, 한 장비는 파티에 한 명만 — §4.3). 칸: skill_final(공격 마법 최종 데미지) · final(모든 공격 최종) · dmg_taken(받는 피해 ±)
## start_credits · credits_per_turn(차례마다 더) · atk(공격력 ±) · hp(체력 ±) · speed(+) · start_gauge(시작 게이지 0~1) · element(공격 속성 상시 부여)
## crit_rate · crit_dmg · special(징표가 있는 적에게 특공, 겹을 곱하지 않음) · buff_extra(받는 버프 지속 +N) · mark_extra(내가 거는 징표 지속 +N)
## el_final(장비 속성으로 때릴 때 최종 데미지) · taunt(상시 도발) · guts_once(전투당 근성 1번, 버티는 체력 비율)
## lv: 강화 Lv2·Lv3에서 덮어쓰는 칸 (§24.5 표). 대가(받는 피해 +30% 등)는 그대로 — equip_at(id, lv)가 합쳐 준다
const EQUIPS := {
	"": {"name": "없음", "desc": "장비 없음"},
	"black_cup": {"name": "검은 잔", "desc": "공격 마법 피해 +60% · 받는 피해 +30%", "skill_final": 0.60, "dmg_taken": 0.30,
		"lv": {2: {"skill_final": 0.75, "desc": "공격 마법 피해 +75% · 받는 피해 +30%"}, 3: {"skill_final": 0.90, "desc": "공격 마법 피해 +90% · 받는 피해 +30%"}}},
	"kaleido": {"name": "만화경", "desc": "전투 시작 시 크레딧 7 (가득)", "start_credits": 7,
		"lv": {2: {"start_gauge": 0.2, "desc": "전투 시작 시 크레딧 7 · 시작 게이지 20%"}, 3: {"start_gauge": 0.4, "desc": "전투 시작 시 크레딧 7 · 시작 게이지 40%"}}},
	"notebook": {"name": "마녀의 수첩", "desc": "시작 크레딧 +3 · 공격력 +20%", "start_credits": 3, "atk": 0.20,
		"lv": {2: {"atk": 0.25, "desc": "시작 크레딧 +3 · 공격력 +25%"}, 3: {"start_credits": 4, "atk": 0.30, "desc": "시작 크레딧 +4 · 공격력 +30%"}}},
	"swift_boots": {"name": "바람 신발", "desc": "시작 게이지 80% (첫 차례가 빨리) · 속도 +10", "start_gauge": 0.8, "speed": 10,
		"lv": {2: {"start_gauge": 0.9, "speed": 13, "desc": "시작 게이지 90% · 속도 +13"}, 3: {"start_gauge": 1.0, "speed": 15, "desc": "시작 게이지 100% · 속도 +15"}}},
	"mana_spring": {"name": "마력 샘", "desc": "차례마다 크레딧 +2 (기본 +1에 +1) · 공격력 −20%", "credits_per_turn": 1, "atk": -0.20,
		"lv": {2: {"atk": -0.15, "desc": "차례마다 크레딧 +2 · 공격력 −15%"}, 3: {"atk": -0.10, "desc": "차례마다 크레딧 +2 · 공격력 −10%"}}},
	"ember_ring": {"name": "불씨 반지", "desc": "공격에 화염 속성 상시 부여 (버퍼 없이 화염 딜러)", "element": "fire",
		"lv": {2: {"el_final": 0.10, "desc": "화염 속성 상시 부여 · 화염 공격 최종 데미지 +10%"}, 3: {"el_final": 0.20, "desc": "화염 속성 상시 부여 · 화염 공격 최종 데미지 +20%"}}},
	"tide_ring": {"name": "조류 반지", "desc": "공격에 물 속성 상시 부여", "element": "water",
		"lv": {2: {"el_final": 0.10, "desc": "물 속성 상시 부여 · 물 공격 최종 데미지 +10%"}, 3: {"el_final": 0.20, "desc": "물 속성 상시 부여 · 물 공격 최종 데미지 +20%"}}},
	"storm_ring": {"name": "뇌운 반지", "desc": "공격에 번개 속성 상시 부여", "element": "bolt",
		"lv": {2: {"el_final": 0.10, "desc": "번개 속성 상시 부여 · 번개 공격 최종 데미지 +10%"}, 3: {"el_final": 0.20, "desc": "번개 속성 상시 부여 · 번개 공격 최종 데미지 +20%"}}},
	"mirror_shard": {"name": "거울 조각", "desc": "크리 확률 +25%", "crit_rate": 0.25,
		"lv": {2: {"crit_rate": 0.31, "desc": "크리 확률 +31%"}, 3: {"crit_rate": 0.38, "desc": "크리 확률 +38%"}}},
	"star_shard": {"name": "별 조각", "desc": "최종 데미지 +20% (기본 공격 포함) · 크리 데미지 +30%", "final": 0.20, "crit_dmg": 0.30,
		"lv": {2: {"final": 0.25, "crit_dmg": 0.38, "desc": "최종 데미지 +25% · 크리 데미지 +38%"}, 3: {"final": 0.30, "crit_dmg": 0.45, "desc": "최종 데미지 +30% · 크리 데미지 +45%"}}},
	"iron_heart": {"name": "강철 심장", "desc": "체력 +30% · 받는 피해 −15% · 상시 도발", "hp": 0.30, "dmg_taken": -0.15, "taunt": true,
		"lv": {2: {"hp": 0.38, "dmg_taken": -0.19, "desc": "체력 +38% · 받는 피해 −19% · 상시 도발"}, 3: {"hp": 0.45, "dmg_taken": -0.23, "desc": "체력 +45% · 받는 피해 −23% · 상시 도발"}}},
	"hourglass_charm": {"name": "모래시계 펜던트", "desc": "받는 버프의 지속 +1 행동", "buff_extra": 1,
		"lv": {2: {"start_gauge": 0.2, "desc": "받는 버프 지속 +1 · 시작 게이지 20%"}, 3: {"buff_extra": 2, "desc": "받는 버프 지속 +2"}}},
	"ash_charm": {"name": "재의 부적", "desc": "내가 거는 징표 지속 +1 · 징표가 있는 적에게 특공 +20%", "mark_extra": 1, "special": 0.20,
		"lv": {2: {"special": 0.25, "desc": "거는 징표 지속 +1 · 징표가 있는 적에게 특공 +25%"}, 3: {"mark_extra": 2, "special": 0.30, "desc": "거는 징표 지속 +2 · 징표가 있는 적에게 특공 +30%"}}},
	"feather_charm": {"name": "깃털 부적", "desc": "전투당 근성 1번 (쓰러질 피해를 체력 10%로 버팀)", "guts_once": 0.10,
		"lv": {2: {"guts_once": 0.15, "desc": "전투당 근성 1번 (체력 15%로 버팀)"}, 3: {"guts_once": 0.20, "desc": "전투당 근성 1번 (체력 20%로 버팀)"}}},
}

## 편성 카드의 장비 ◀ ▶ 순서
const EQUIP_ORDER := ["", "black_cup", "kaleido", "notebook", "swift_boots", "mana_spring", "ember_ring", "tide_ring", "storm_ring", "mirror_shard", "star_shard", "iron_heart", "hourglass_charm", "ash_charm", "feather_charm"]

## 적 (combat_proto.md §18 · §24.6 [제안]). tier = normal(일반) · elite(강적) · boss(보스) → 내성 RESIST · 보스는 기절 면역
## weak = 약점 직접 지정 (빈 목록 = 약점 없음, 없으면 WEAK_TO 순환표) · bars = 여러 줄 체력 (hp 대신) · art = 그림 (없으면 id) · short = 차례 칸 글자
## pattern = 의도 순서(돌아감): attack·heavy(단일 × mult) · aoe(전체 × mult) · buff(자기 공격력 +v, 행동 dur번) · stun_attack(단일 × mult + 기절) · dispel(마녀 버프 해제 — 나쁜 효과는 남음)
##   [단계 F-2, review_H §2] seal(단일 × mult(0이면 피해 없음) + 봉인: 다음 자기 차례에 장착 마법·대마법 못 씀, ult면 대마법만) ·
##   weaken{cat atk_down|dmg_taken, v, dur, aoe?, mult?}(마녀에게 나쁜 효과 — 공격력 다운은 그 마녀 행동 dur번, 받는 피해는 적 행동 dur번) ·
##   guard{v, dur}(자신 받는 피해 −v, 그 적 행동 dur번, 방어 무시로 안 뚫림) · cover{dur}(마녀의 단일 대상이 이 적만) ·
##   rally{charge? | gauge?}(다른 적 전원 차지 +n · 또는 게이지가 가장 낮은 다른 적 게이지 +v) · summon{id, hp?}(쓰러진 칸에 그 적을 세움, 적 summon_cap까지) ·
##   purge(자신의 징표 전부 지움) · scatter{v}(마녀 전원 크레딧 −v)
## charge_max·charge_act = 차지 칸 수와 가득 찼을 때의 필살기(finisher, aoe면 전체, self_ko면 쓴 뒤 그 적이 쓰러짐 = 자폭) · on_break = 줄이 깨질 때 {intent?, pattern?, buff?}
## phases = 줄마다 덮어쓸 칸 [{}, {element?, weak?, def?, speed?}, …] (줄이 깨질 때 그 줄 번호의 것, §18.6) · leader = 쓰러지면 같은 웨이브의 나머지도 사라짐
## traits = 특성 (TRAIT_NAME) · passive = 고유 효과 [{t, name, …}]: mark_cap{kind, n}(그 징표 최대 n겹) · guard_allies{v}(다른 적이 살아 있으면 받는 피해 −v) · first_strike{v}(웨이브 시작 게이지 +v)
##   [F-3] guard_break(약점 속성 공격을 맞으면 그 공격 뒤 방어 태세가 풀림 — 속성 둘 이상 파티의 몫) · aoe_taken{v}(광역 공격에 받는 피해 +v — 무리 전투에서 광역의 몫)
## crit = 적 크리 확률 (없으면 ENEMY_CRIT_BASE) · summon_cap = 이 적이 한 웨이브에 부를 수 있는 수
## rules = 조건 규칙 (위에서부터 처음 맞는 것): when {hp_below · bar(0부터) · witch_buffs · allies_dead · acted · empty_slot · self_marks · witch_credits · self_buff(+not) · allies_alive}
##   (한 when 안의 조건은 모두 맞아야 함) → pattern(바꿈) 또는 insert(하나 끼움) (§18.2)
const ENEMIES := {
	"straw_golem": {"name": "짚 골렘", "short": "골", "tier": "normal", "hp": 480000, "atk": 3000, "speed": 80, "def": 0.0, "element": "straw", "weak": ["fire"], "traits": ["construct"],
		"pattern": [{"k": "attack", "mult": 1.0}, {"k": "heavy", "mult": 2.0}], "size": 1.0, "color": Color("#c9a85c")},
	"swamp_toad": {"name": "늪 두꺼비", "short": "두", "tier": "normal", "hp": 720000, "atk": 2600, "speed": 105, "def": 0.20, "element": "water", "traits": ["beast"],
		"pattern": [{"k": "attack", "mult": 1.0}, {"k": "stun_attack", "mult": 0.6}, {"k": "aoe", "mult": 0.8}], "size": 1.0, "color": Color("#6f8a3a")},
	"ash_knight": {"name": "재의 기사", "short": "기", "tier": "elite", "hp": 1200000, "atk": 3000, "speed": 95, "def": 0.30, "element": "ash", "weak": [], "traits": ["armored", "ash"],
		"pattern": [{"k": "attack", "mult": 1.0}, {"k": "buff", "v": 0.30, "dur": 3}, {"k": "heavy", "mult": 1.6}, {"k": "aoe", "mult": 0.7}],
		"charge_max": 5, "charge_act": {"k": "finisher", "name": "잿불 베기", "aoe": true, "mult": 1.5},
		"rules": [{"when": {"hp_below": 0.5}, "pattern": [{"k": "heavy", "mult": 1.6}, {"k": "aoe", "mult": 0.7}]}],
		"size": 1.3, "color": Color("#6e6673")},
	# ── 단계 F-2 새 적 11 (review_H §5.1) — 불 약점 3 · 물 약점 3 · 번개 약점 3 · 약점 없음 3 · 특수 약점 2 (기존 포함)
	"will_o": {"name": "도깨비불", "short": "깨", "tier": "normal", "hp": 420000, "atk": 2800, "speed": 125, "def": 0.0, "element": "fire", "traits": ["spirit"],
		"pattern": [{"k": "attack", "mult": 1.0}, {"k": "rally", "charge": 1}, {"k": "attack", "mult": 1.0}], "size": 0.9, "color": Color("#ff8a3a")},
	"hearth_turtle": {"name": "화로 거북", "short": "북", "tier": "normal", "hp": 960000, "atk": 2400, "speed": 75, "def": 0.25, "element": "fire", "traits": ["armored", "beast"],
		"passive": [{"t": "mark_cap", "kind": "burn", "n": 3, "name": "달군 몸"}],
		"pattern": [{"k": "attack", "mult": 1.0}, {"k": "guard", "v": 0.50, "dur": 2}, {"k": "heavy", "mult": 1.8}], "size": 1.1, "color": Color("#a8442a")},
	"flame_priest": {"name": "불꽃 사제", "short": "사", "tier": "elite", "hp": 1250000, "atk": 3000, "speed": 100, "def": 0.20, "element": "fire",
		"passive": [{"t": "mark_cap", "kind": "burn", "n": 3, "name": "달군 몸"}],
		"pattern": [{"k": "weaken", "cat": "dmg_taken", "v": 0.20, "dur": 2, "aoe": true}, {"k": "attack", "mult": 1.0}, {"k": "heavy", "mult": 1.8}],
		"charge_max": 4, "charge_act": {"k": "finisher", "name": "업화의 설교", "aoe": true, "mult": 1.5}, "size": 1.25, "color": Color("#c0402a")},
	"mist_jelly": {"name": "물안개 해파리", "short": "파", "tier": "normal", "hp": 480000, "atk": 2600, "speed": 100, "def": 0.10, "element": "water", "traits": ["spirit"],
		"pattern": [{"k": "attack", "mult": 1.0}, {"k": "weaken", "cat": "atk_down", "v": 0.15, "dur": 2, "aoe": true}, {"k": "aoe", "mult": 0.6}], "size": 0.95, "color": Color("#8fd8ff")},
	"frost_knight": {"name": "서리 기사", "short": "서", "tier": "elite", "hp": 1300000, "atk": 3200, "speed": 95, "def": 0.30, "element": "water", "traits": ["armored"],
		"pattern": [{"k": "attack", "mult": 1.0}, {"k": "cover", "dur": 2}, {"k": "heavy", "mult": 1.8}, {"k": "aoe", "mult": 0.7}],
		"charge_max": 5, "charge_act": {"k": "finisher", "name": "빙창 돌격", "aoe": true, "mult": 1.5}, "size": 1.2, "color": Color("#5a86b8")},
	"thunder_crow": {"name": "번개 까마귀", "short": "까", "tier": "normal", "hp": 340000, "atk": 3000, "speed": 140, "def": 0.0, "element": "bolt", "traits": ["beast"], "crit": 0.15,
		"passive": [{"t": "first_strike", "v": 0.50, "name": "먼저 날아듦"}],
		"pattern": [{"k": "attack", "mult": 1.0}, {"k": "attack", "mult": 1.0}, {"k": "seal", "mult": 0.6}], "size": 0.85, "color": Color("#ffe34a")},
	"volt_golem": {"name": "뇌석 골렘", "short": "뇌", "tier": "elite", "hp": 1850000, "atk": 3200, "speed": 85, "def": 0.30, "element": "bolt", "traits": ["construct"],
		"pattern": [{"k": "attack", "mult": 1.0}, {"k": "guard", "v": 0.50, "dur": 2}, {"k": "heavy", "mult": 2.0}, {"k": "aoe", "mult": 0.8}],
		"charge_max": 5, "charge_act": {"k": "finisher", "name": "과부하 방전", "aoe": true, "mult": 1.8}, "size": 1.15, "color": Color("#8a8070")},
	"ash_servant": {"name": "잿빛 시종", "short": "종", "tier": "normal", "hp": 240000, "atk": 2200, "speed": 110, "def": 0.0, "element": "ash", "weak": [], "traits": ["ash"],
		"passive": [{"t": "aoe_taken", "v": 0.50, "name": "흩날리는 재"}],
		"pattern": [{"k": "attack", "mult": 1.0}, {"k": "rally", "gauge": 0.30}],
		"charge_max": 3, "charge_act": {"k": "finisher", "name": "재 터짐", "aoe": true, "mult": 1.6, "self_ko": true}, "size": 0.75, "color": Color("#8a8090")},
	"lantern_keeper": {"name": "등불지기", "short": "등", "tier": "elite", "hp": 900000, "atk": 2800, "speed": 90, "def": 0.20, "element": "ash", "weak": [], "traits": ["ash", "spirit"],
		"passive": [{"t": "guard_allies", "v": 0.30, "name": "등불 가림"}, {"t": "aoe_taken", "v": 0.50, "name": "흩날리는 재"}], "summon_cap": 4,
		"pattern": [{"k": "attack", "mult": 1.0}, {"k": "aoe", "mult": 0.7}, {"k": "heavy", "mult": 1.6}],
		"rules": [{"when": {"empty_slot": 1}, "insert": {"k": "summon", "id": "ash_servant"}}], "size": 1.2, "color": Color("#7a6a58")},
	"shade_scribe": {"name": "그림자 서기", "short": "그", "tier": "normal", "hp": 520000, "atk": 2800, "speed": 120, "def": 0.10, "element": "none", "weak": ["space"], "traits": ["spirit"],
		"pattern": [{"k": "attack", "mult": 1.0}, {"k": "aoe", "mult": 0.6}, {"k": "attack", "mult": 1.0}],
		"rules": [{"when": {"witch_credits": 6}, "insert": {"k": "scatter", "v": 2}}], "size": 1.0, "color": Color("#5a4a78")},
	"hollow_armor": {"name": "빈 갑주", "short": "갑", "tier": "normal", "hp": 900000, "atk": 2600, "speed": 80, "def": 0.35, "element": "none", "weak": ["sword"], "traits": ["armored", "construct"],
		"pattern": [{"k": "attack", "mult": 1.0}, {"k": "guard", "v": 0.40, "dur": 2}, {"k": "heavy", "mult": 2.0}], "size": 1.15, "color": Color("#9a98a8")},
	# ── 보스
	"ash_king": {"name": "재의 왕", "short": "왕", "tier": "boss", "bars": [1500000, 1500000, 1500000], "atk": 6000, "speed": 100, "def": 0.30, "element": "ash", "weak": ["water"], "traits": ["ash"],
		"pattern": [{"k": "attack", "mult": 1.0}, {"k": "heavy", "mult": 2.0}, {"k": "buff", "v": 0.30, "dur": 3}, {"k": "aoe", "mult": 1.0}],
		"charge_max": 5, "charge_act": {"k": "finisher", "name": "잿빛 낙인", "aoe": true, "mult": 2.5},
		"rules": [{"when": {"bar": 2}, "pattern": [{"k": "heavy", "mult": 2.0}, {"k": "aoe", "mult": 1.2}, {"k": "dispel"}, {"k": "heavy", "mult": 2.5}]},
			{"when": {"witch_buffs": 8}, "insert": {"k": "dispel"}}],
		"on_break": {"intent": {"k": "dispel"}},
		"art": "ash_knight", "size": 1.5, "color": Color("#4e4653")},
	# 세 빛의 인형 (review_H §5.2 · §6): 줄마다 속성·약점이 돈다 — 줄 1 물(약점 번개) → 줄 2 번개(약점 불) → 줄 3 불(약점 물). 줄 2~3 방어 태세 · 줄 3 해제
	# F-3: "갈라지는 빛" — 그 줄의 약점 속성으로 맞으면 방어 태세(−60%)가 풀림 → 속성 둘 이상 파티가 태세를 깨며 빨라짐 (combat_proto.md §27.8). 줄 130만·100만·280만
	"prism_doll": {"name": "세 빛의 인형", "short": "인", "tier": "boss", "bars": [1300000, 1000000, 2800000], "atk": 6000, "speed": 100, "def": 0.25, "element": "water", "weak": ["bolt"], "traits": ["construct"],
		"passive": [{"t": "guard_break", "name": "갈라지는 빛"}],
		"pattern": [{"k": "attack", "mult": 1.0}, {"k": "aoe", "mult": 1.0}, {"k": "heavy", "mult": 2.0}, {"k": "buff", "v": 0.30, "dur": 3}],
		"charge_max": 5, "charge_act": {"k": "finisher", "name": "삼색 섬광", "aoe": true, "mult": 2.5},
		"phases": [{}, {"element": "bolt", "weak": ["fire"]}, {"element": "fire", "weak": ["water"]}],
		"rules": [{"when": {"bar": 1}, "pattern": [{"k": "attack", "mult": 1.0}, {"k": "guard", "v": 0.60, "dur": 2}, {"k": "heavy", "mult": 2.2}, {"k": "aoe", "mult": 1.0}]},
			{"when": {"bar": 2}, "pattern": [{"k": "heavy", "mult": 2.0}, {"k": "aoe", "mult": 1.2}, {"k": "dispel"}, {"k": "guard", "v": 0.60, "dur": 2}, {"k": "heavy", "mult": 2.5}]}],
		"size": 1.5, "color": Color("#c8c0e0")},
	# 잿빛 둥지어미 (review_H §5.2 · §6): 우두머리 · 둥지 보호 · 잿빛 시종 부르기(웨이브에 3) · 줄 2에서 징표 4겹 이상이면 징표 털기 (부르기보다 먼저)
	"ash_brood": {"name": "잿빛 둥지어미", "short": "둥", "tier": "boss", "bars": [2800000, 2800000], "atk": 6500, "speed": 95, "def": 0.30, "element": "ash", "weak": ["bolt"], "traits": ["ash", "beast"],
		"leader": true, "summon_cap": 2, "passive": [{"t": "guard_allies", "v": 0.20, "name": "둥지 보호"}],
		"pattern": [{"k": "attack", "mult": 1.0}, {"k": "aoe", "mult": 1.0}, {"k": "heavy", "mult": 2.0}],
		"charge_max": 4, "charge_act": {"k": "finisher", "name": "잿빛 산란", "aoe": true, "mult": 2.2},
		"rules": [{"when": {"bar": 1, "self_marks": 4}, "insert": {"k": "purge"}}, {"when": {"empty_slot": 1}, "insert": {"k": "summon", "id": "ash_servant"}}],
		"size": 1.5, "color": Color("#5a4048")},
	# 시련 보스 (§24.6 · 원형 B3 "버티며 쌓기"용 고난이도 1판): 공격력이 보스전의 6배, 필살기는 무적 관통 (받는 피해 감소·근성은 통함)
	"trial_colossus": {"name": "시련의 거상", "short": "거", "tier": "boss", "bars": [1200000, 1200000, 1200000], "atk": 36000, "speed": 100, "def": 0.30, "element": "ash", "weak": [], "traits": ["ash"],
		"pattern": [{"k": "attack", "mult": 1.0}, {"k": "aoe", "mult": 0.6}, {"k": "heavy", "mult": 1.6}, {"k": "aoe", "mult": 0.6}],
		"charge_max": 4, "charge_act": {"k": "finisher", "name": "시련의 일격", "aoe": false, "mult": 3.0, "pierce": true},
		"rules": [{"when": {"bar": 2}, "pattern": [{"k": "heavy", "mult": 1.6}, {"k": "aoe", "mult": 0.8}, {"k": "attack", "mult": 1.0}, {"k": "aoe", "mult": 0.8}]}],
		"on_break": {"buff": {"v": 0.20, "dur": 4}},
		"art": "ash_knight", "size": 1.6, "color": Color("#3a3240")},
}
const INTENT_NAME := {"attack": "공격", "heavy": "강공격", "aoe": "전체 공격", "buff": "버프", "stun_attack": "기절 공격", "dispel": "해제", "finisher": "필살기",
	"seal": "봉인", "weaken": "약화", "guard": "방어 태세", "cover": "막아서기", "rally": "재촉", "summon": "부르기", "purge": "징표 털기", "scatter": "크레딧 흩기"}
## 적 특성 (review_H §3) — 상세 표시 · 특성 특공 (this_special trait, F-3)
const TRAIT_NAME := {"armored": "갑각", "spirit": "영체", "beast": "짐승", "construct": "인형", "ash": "재"}

## 전투 (§5.6 · §24.6 · review_H §7). 웨이브 = 적 1~3 (앞·중·뒤 순). 항목이 {id, hp}면 그 적의 체력만 덮어쓴다
## start_credits = 전투를 시작할 때 마녀 모두의 크레딧 (안내 전투만 — 첫 차례부터 마법을 써 보게, combat_proto.md §28 [제안])
## ask = 전투 고르기(S-03)의 한 줄 "묻는 것" · stars = 난이도 1~3 · mins = 예상 시간(분, turn_sim.gd -- N h의 원형 평균 — §27.7)
## bg = 배경 테마 (TBackdrop.THEMES, 없으면 field) · bgs = 웨이브마다 배경 (bg보다 먼저 — review_F F20 · review_H §7.2 규칙 4, F-3)
const BATTLES := {
	"intro_01": {"name": "안내 전투", "kind": "intro", "start_credits": 3, "stars": 1, "mins": 2, "ask": "처음 한 번. 짚 골렘 두 마리와 짧게 싸우며 조작을 배웁니다",
		"waves": [[{"id": "straw_golem", "hp": 240000}, {"id": "straw_golem", "hp": 240000}]]},
	"normal_01": {"name": "들판", "kind": "normal", "stars": 1, "mins": 6, "ask": "적 3마리 한 웨이브 — 빌드를 시험하기 좋습니다",
		"waves": [["straw_golem", "swamp_toad", "ash_knight"]]},
	"normal_fire": {"name": "불길의 골짜기", "kind": "normal", "bg": "fire", "stars": 2, "mins": 6, "ask": "재촉·방어 태세·약화 — 물 파티와 차지 감소가 통합니다",
		"waves": [["will_o", "hearth_turtle", "flame_priest"]]},
	"normal_water": {"name": "안개 호수", "kind": "normal", "bg": "lake", "stars": 2, "mins": 6, "ask": "약화·막아서기 — 번개 파티가 통합니다",
		"waves": [["mist_jelly", "swamp_toad", "frost_knight"]]},
	"normal_bolt": {"name": "뇌운 고개", "kind": "normal", "bg": "storm", "stars": 2, "mins": 6, "ask": "봉인·빠른 적·단단한 골렘 — 불 파티의 한 방이 통합니다",
		"waves": [["thunder_crow", "thunder_crow", "volt_golem"]]},
	"normal_swarm": {"name": "등불 회랑", "kind": "normal", "bg": "corridor", "stars": 2, "mins": 5, "ask": "자폭하는 시종과 부르는 등불지기 · 재는 광역에 흩날림 — 광역이 통합니다",
		"waves": [["ash_servant", "lantern_keeper", "ash_servant"]]},
	"normal_rift": {"name": "틈새 서고", "kind": "normal", "bg": "library", "stars": 2, "mins": 7, "ask": "속성 약점이 없는 곳 · 크레딧 흩기 — 에스카·하르페가 통합니다",
		"waves": [["shade_scribe", "hollow_armor", "ash_knight"]]},
	"boss_01": {"name": "보스 전투 — 재의 왕", "kind": "boss", "bgs": ["field", "field", "ash_sky"], "stars": 2, "mins": 18, "ask": "버프 해제 — 해제 앞에 쏟아붓기 · 물 약점", "waves": [
		["straw_golem", "straw_golem", {"id": "swamp_toad", "hp": 480000}],
		["swamp_toad", "ash_knight"],
		["ash_king"]]},
	"boss_02": {"name": "보스 전투 — 세 빛의 인형", "kind": "boss", "bgs": ["lake", "storm", "prism"], "stars": 3, "mins": 17, "ask": "줄마다 약점이 바뀜 · 약점으로 치면 방어 태세가 깨짐 — 속성 둘 이상의 파티", "waves": [
		["will_o", "mist_jelly", "thunder_crow"],
		["hearth_turtle", "thunder_crow"],
		["prism_doll"]]},
	"boss_03": {"name": "보스 전투 — 잿빛 둥지어미", "kind": "boss", "bgs": ["corridor", "fire", "brood"], "stars": 3, "mins": 19, "ask": "시종을 부르는 우두머리 · 징표 털기 — 번개 파티와 광역", "waves": [
		["ash_servant", "ash_servant", "ash_servant"],
		["flame_priest", "will_o"],
		["ash_servant", "ash_brood", "ash_servant"]]},
	"trial_01": {"name": "시련 — 시련의 거상", "kind": "trial", "bg": "trial", "stars": 3, "mins": 10, "ask": "아주 아픈 한 판 · 필살기는 무적 관통. 추천: 버티며 쌓기 (네레이·호라·하르페)",
		"waves": [["trial_colossus"]]},
}
## 전투 고르기 순서 (S-03 탭 안 순서)
const BATTLE_ORDER := ["normal_01", "normal_fire", "normal_water", "normal_bolt", "normal_swarm", "normal_rift", "boss_01", "boss_02", "boss_03", "trial_01"]

## 용어 풀이 (combat_proto.md §2 · §28.6): 도움말 판(? 버튼)과 상세·설명 상자 맨 아래 한 줄이 같이 쓴다. 순서 = 도움말 목록 순서.
## [용어, 풀이, 화면에서 어디에 보이나] (review_I I-16 — 22 → 32개, 셋째 칸은 도움말 풀이 아래 한 줄)
const GLOSSARY := [
	["크레딧", "마녀마다 따로 모으는 마력(◆ 7칸). 차례마다 +1, 기본 공격은 +1 더. 마법을 쓰면 그 비용만큼 줄어든다", "아군 패널의 마름모 7칸 · 바퀴 칸의 숫자 배지(비용)"],
	["대마법", "크레딧 7을 모두 써서 쓰는 큰 마법. 바퀴 끝 금빛 칸. 쓰고 나면 0부터 다시 모은다. \"대마법 위력\" 버프(크레딧을 주는 마법에 붙음)는 대마법 피해에만 따로 곱해진다", "바퀴 끝 금빛 칸 · 진행 호 n/7"],
	["연쇄", "대마법을 쓴 마녀가 다시 움직이기 전에 다른 마녀가 대마법을 이으면 단계가 오른다(최대 3). 2단계 효과 ×1.25 · 공격 피해 ×1.15, 3단계 효과 ×1.5 · 피해 ×1.3", "위 띠 금빛 칩 \"연쇄 n → 다음 효과 ×…\""],
	["약점", "적 카드의 네모 속성 칸. 그 속성으로 치면 피해 1.5배", "적 카드 이름 줄 오른쪽 금테 네모 · 피해 숫자 위 \"약점\""],
	["무상성", "공간·시간·검술 마녀는 약점이 없는 대신 모든 적에게 1.2배 (속성을 받으면 그 속성으로 친다)", "편성 카드 \"공간·시간·검술\""],
	["특성", "적의 갈래(갑각·영체·짐승·인형·재). 그 특성에만 붙는 특공 마법이 있다", "적 상세 \"특성\" 줄 · 설명 띠 \"갑각 특공\""],
	["징표", "화상·빙결·감전. 그 자체로는 피해가 없다. 걸린 적에게 붙는 효과(특공 등)의 조건이 된다", "적 카드 체력 줄의 둥근 아이콘"],
	["겹", "같은 징표를 또 걸면 겹이 쌓인다(최대 5). 특공·터뜨리기는 겹 수만큼 세진다", "징표 아이콘 옆 숫자 알약"],
	["특공", "징표가 걸린 적(또는 그 특성의 적)에게만 붙는 피해 보너스. 징표 특공은 그 속성 공격(화상 = 불 · 빙결 = 물 · 감전 = 번개)일 때 겹마다 곱해지고, 다른 속성은 1겹 값 — 속성 부여로 맞춘다", "마법 설명 \"특공 +n%\""],
	["터뜨리기", "징표 겹을 모두 써서 한 번에 큰 피해. 겹마다 배율이 오른다", "마법 설명 \"터뜨리기\""],
	["번짐", "징표 겹 수만큼 다른 적 모두에게 같은 징표를 건다", "마법 설명 \"번짐\""],
	["차지", "강적·보스 카드의 꺾쇠 칸. 적이 행동할 때마다 한 칸씩 차고, 다 차면 다음 행동이 필살기", "적 카드 체력 숫자 줄 오른쪽 ›››› 칸"],
	["필살기", "차지가 다 찬 적의 큰 공격. 무적·도발·기절·차지 감소로 대비한다", "빨간 바탕 알약 · 차례 줄의 빨간 칸"],
	["관통", "무적을 뚫는 공격(→| 표시). 받는 피해 감소·도발·근성은 통한다", "필살기 알약 끝 →| 표시"],
	["무적", "적의 공격을 받지 않는다(적 행동 n번). 관통은 막지 못하고, 한 번 걸린 뒤엔 무적 내성이 붙는다", "아군 패널 방패 아이콘 · 피해 숫자 자리 \"무적\""],
	["도발", "적의 단일 대상 공격을 그 마녀가 받는다. 전체 공격은 그대로", "아군 패널 방패+눈 아이콘 · 머리 위 시선"],
	["근성", "쓰러질 피해를 한 번 버틴다(체력 1 또는 n%)", "아군 패널 깃털 아이콘 · \"근성\" 글"],
	["기절", "다음 차례 하나를 쉰다. 쉰 뒤 한 차례는 다시 기절하지 않는다(기절 내성). 보스는 면역", "머리 위 별 · 차례 줄 별"],
	["저항", "강적·보스가 디버프를 막음(내성). 성공률은 마법 칸을 고르면 설명 띠에 보인다", "피해 숫자 자리 \"저항\" · 설명 띠 \"성공률 n%\""],
	["줄", "보스의 체력은 여러 줄. 한 줄을 깨면(브레이크) 넘친 피해는 사라지고 보스의 행동이 바뀐다", "보스 카드 오른쪽 금빛 칸 \"줄 n/m\""],
	["브레이크", "보스의 줄 하나를 깸. 그 순간 보스 행동이 바뀌고, 줄마다 약점이 바뀌는 보스도 있다", "보스 몸 옆 큰 글 \"브레이크\""],
	["해제", "적이 마녀들의 버프를 모두 지운다. 패시브·장비는 남는다", "보라 알약 \"해제 · 버프 n\""],
	["대가", "강한 마법의 값: 그 행동 뒤 크레딧 0, 또는 체력을 깎는다", "마법 설명 \"대가\""],
	["봉인", "적에게 봉인되면 다음 자기 차례에 장착 마법·대마법을 못 쓴다(기본 공격만). 그 차례가 끝나면 풀리고, 한 차례는 다시 봉인되지 않는다", "청록 알약 · 바퀴 칸 자물쇠"],
	["약화", "적이 거는 나쁜 효과(공격력 다운·받는 피해 증가). 해제로 지워지지 않는다", "분홍 알약 · 아군 패널 빨간 아이콘"],
	["방어 태세", "적이 받는 피해를 줄인다(최대 70%). 방어 무시로도 안 뚫린다. 태세가 없는 차례에 몰아친다", "회청 알약 · 적 카드 방패"],
	["막아서기", "그 적이 막아서는 동안 단일 대상 공격·디버프는 그 적만 고를 수 있다. 전체 공격은 그대로", "연두노랑 알약 · 적 앞 방패벽"],
	["재촉", "다른 적의 차지나 게이지를 채운다. 재촉하는 적을 먼저 치거나 차지 감소로 막는다", "연두 알약"],
	["부르기", "쓰러진 자리에 새 적을 세운다. 부를 수 있는 수는 정해져 있다", "흰회 알약"],
	["자폭", "차지가 다 찬 졸개가 전체를 치고 스스로 쓰러진다. 차기 전에 처치하거나 무적으로 받는다", "필살기 알약 끝 작은 폭발"],
	["징표 털기", "적이 자기 징표를 모두 지운다. 보이면 그 전에 터뜨린다", "주황 알약"],
	["크레딧 흩기", "마녀 모두의 크레딧을 깎는다. 보이면 모은 크레딧을 먼저 쓴다", "갈색 알약"],
	["우두머리", "쓰러지면 같은 웨이브의 졸개도 함께 사라진다", "적 상세 \"우두머리\""],
	["지속 회복", "받은 마녀가 자기 행동을 마칠 때마다 최대 체력의 n%를 회복한다(정해진 횟수). 버프라 해제되면 사라진다", "아군 패널 초록 십자 아이콘 · 행동을 마친 뒤 초록 숫자"],
	["대마법 위력", "그 마녀의 공격 대마법 피해에만 따로 곱한다(행동 n번 안). 보조 대마법(회복·버프)에는 붙지 않는다", "아군 패널 금빛 마름모 아이콘"],
	["받는 크리 데미지", "그 적을 때리는 아군의 크리 피해 배수에 더한다. 크리 데미지 상한(+300%)과 따로 최대 +60%", "적 카드 빨간 별 + 아래 두 줄 아이콘 (두 줄 없는 별은 받는 크리 확률)"],
	["체력 비례", "적 체력이 가득일수록 세지는 공격. 절반 이하면 보너스 0. 보스는 지금 줄 기준이라 줄이 깨지면 다시 가득", "마법 설명 \"적 체력이 가득이면\""],
]
## 글 속 다른 말 → 용어 (화상·빙결·감전 → 징표 · 갑각 등 특성 이름 → 특성, review_I I-14)
const GLOSS_ALIAS := {"화상": "징표", "빙결": "징표", "감전": "징표", "갑각": "특성", "영체": "특성", "짐승": "특성", "인형": "특성", "체력 대가": "대가", "무적 관통": "관통", "체력이 가득": "체력 비례"}
## 풀이 줄에서 맨 나중에 고르는 기초 용어 (R2 — 늘 "크레딧"만 풀던 것, review_L §4.1)
const GLOSS_LAST := ["크레딧"]

## 글에 나온 첫 용어의 풀이 한 줄 ("징표 — …"). skip에 든 용어(도움말에서 이미 연 것)는 건너뜀. 없으면 ""
static func gloss_for(text: String, skip: Dictionary = {}) -> String:
	var best := -1
	var best_len := 0
	var out := ""
	var names := {}
	for g in GLOSSARY:
		names[String(g[0])] = String(g[1])
	var found: Array = [] ## [글 속 자리, 찾은 글 길이, 용어]
	for g in GLOSSARY:
		found.append([text.find(String(g[0])), String(g[0]).length(), String(g[0])])
	for al in GLOSS_ALIAS:
		found.append([text.find(String(al)), String(al).length(), String(GLOSS_ALIAS[al])])
	for last in [false, true]: # 기초 용어(GLOSS_LAST)는 다른 용어가 없을 때만 (R2)
		for f in found:
			var key := String(f[2])
			if int(f[0]) < 0 or skip.has(key) or GLOSS_LAST.has(key) != last:
				continue
			if best < 0 or int(f[0]) < best or (int(f[0]) == best and int(f[1]) > best_len): # 같은 자리면 긴 용어 ("대마법 위력" > "대마법")
				best = int(f[0])
				best_len = int(f[1])
				out = "%s — %s" % [key, String(names[key])]
		if out != "":
			break
	return out


## 적 고유 효과 한 줄 ("달군 몸: 화상 최대 3겹") — 유닛 상세 (review_H §3)
static func enemy_passive_text(p: Dictionary) -> String:
	var body := ""
	match String(p.get("t", "")):
		"mark_cap": body = "%s 최대 %d겹" % [MARK_NAME.get(String(p.get("kind", "")), ""), int(p.get("n", 0))]
		"guard_allies": body = "다른 적이 살아 있으면 받는 피해 −%d%%" % int(round(float(p.get("v", 0.0)) * 100.0))
		"first_strike": body = "웨이브 시작 게이지 +%d%%" % int(round(float(p.get("v", 0.0)) * 100.0))
		"guard_break": body = "약점 속성 공격을 맞으면 방어 태세가 풀림"
		"aoe_taken": body = "광역 공격에 받는 피해 +%d%%" % int(round(float(p.get("v", 0.0)) * 100.0))
	return "%s: %s" % [String(p.get("name", "")), body]


## 진 이유 줄 [[글, 색]]: TStage 기록(why)·전투에서 (review_F F13 · review_G G03 · review_I I-02·I-13 — TStage는 자동 로드를 써서 헤드리스 규칙 시험이 못 부르므로 여기)
static func lose_lines(why: Dictionary, b: TBattle, bid: String) -> Array:
	var out: Array = []
	var fk := int(why.get("fin_kills", 0))
	var big: Dictionary = why.get("big", {})
	if fk >= 2:
		# 필살기로 진 판: 1줄 누가·몇 명 · 2줄 대비 — 관통이면 무적을 권하지 않는다 (D6 안내와 같은 말, review_I I-02)
		var pierce := int(why.get("pierce_kills", 0)) >= 2
		var src := String(why.get("fin_src", big.get("src", "적")))
		out.append(["%s 필살기%s에 %d명 쓰러짐" % [src, "(관통)" if pierce else "", fk], TTheme.TEXT])
		var tip := "관통은 무적을 뚫습니다 — 받는 피해 감소·도발·근성·차지 감소로" if pierce else "차지가 찬 적 앞에 무적·도발·기절·차지 감소"
		out.append([("받는 피해 감소를 한 번도 안 씀 · " if int(why.get("guard", 0)) == 0 else "") + tip, TTheme.TEXT])
	elif int(why.get("heals", 0)) == 0 and b.wave_i >= 1:
		out.append(["회복을 한 번도 안 쓰고 웨이브 %d까지 — 회복 마법이나 깃털 부적(근성)을 넣어 보세요" % (b.wave_i + 1), TTheme.TEXT])
	elif int(why.get("dispelled", 0)) >= 6:
		out.append(["버프 %d개가 해제로 지워짐 — \"해제\"가 보이면 그 전에 쏟아붓기" % int(why.dispelled), TTheme.TEXT])
	elif not big.is_empty():
		out.append(["가장 아팠던 공격: %s의 %s %s — 받는 피해 감소·회복으로 버티기" % [String(big.src), String(big.act), TData.fmt_short(int(big.dmg))], TTheme.TEXT])
	# 남은 적 체력
	var foes := b.alive_of(b.enemies)
	if foes.size() == 1 and foes[0].bars.size() > 1:
		var f := foes[0]
		out.append(["%s 남은 줄 %d/%d · %s" % [f.name, f.bar_i + 1, f.bars.size(), TData.fmt_short(f.hp)], TTheme.TEXT_SUB])
	elif not foes.is_empty():
		var hp := 0
		var mx := 0
		for f in foes:
			hp += f.hp
			mx += f.max_hp
		out.append(["남은 적 체력 %d%%%s" % [int(round(100.0 * float(hp) / float(maxi(mx, 1)))), (" · 웨이브 %d/%d" % [b.wave_i + 1, b.wave_count()]) if b.wave_count() > 1 else ""], TTheme.TEXT_SUB])
	if String(TData.BATTLES[bid].get("kind", "")) == "trial":
		out.append(["이 시련은 버티며 쌓는 빌드용 — 추천: 네레이·호라·하르페", TTheme.GOLD])
	return out


## 프로토타입 기본 파티와 전투
const BATTLE := {"party": ["eska", "ignis", "ember"], "battle": "normal_01"}


static func skill(id: String) -> Dictionary:
	return SKILLS.get(id, {})


static func cost_of(id: String) -> int:
	return int(SKILLS.get(id, {}).get("cost", 0))


## 강화 레벨을 반영한 마법 (Lv1이면 원본 그대로). 배율·LV_SCALE 칸만 × SKILL_LV (§4.4)
static func skill_at(id: String, lv: int) -> Dictionary:
	var s := skill(id)
	if lv <= 1 or s.is_empty():
		return s
	var k: float = SKILL_LV[clampi(lv, 1, SKILL_LV.size()) - 1]
	var o: Dictionary = s.duplicate(true)
	if o.has("mult"):
		o["mult"] = float(o.mult) * k
	o["effects"] = _scale_effects(o.get("effects", []), k)
	return o


static func _scale_effects(effects: Array, k: float, table: Dictionary = LV_SCALE) -> Array:
	for e in effects:
		var key := String(table.get(String(e.t), ""))
		if key != "" and e.has(key):
			e[key] = float(e[key]) * k
		if e.has("effects"):
			e["effects"] = _scale_effects(e.effects, k, table)
	return effects


## 대마법 연쇄 단계 stage(1~3)의 마법: 부가 효과 수치 × CHAIN_MULT · 공격 대마법 배율 × CHAIN_DMG (§13.6, F-4 P2)
static func chain_scaled(s: Dictionary, stage: int) -> Dictionary:
	if stage <= 1:
		return s
	var o: Dictionary = s.duplicate(true)
	var i := clampi(stage, 1, 3) - 1
	o["effects"] = _scale_effects(o.get("effects", []), float(CHAIN_MULT[i]), CHAIN_SCALE)
	if o.has("mult"):
		o["mult"] = float(o.mult) * float(CHAIN_DMG[i])
	return o


## 연쇄 칩 글 (위 띠 · 안내 강조 자리가 같이 씀): 다음 단계의 효과·피해 배수
static func chain_label(stage: int) -> String:
	if stage >= 3:
		return "연쇄 3 (최대) 효과 ×1.5 · 피해 ×1.3"
	var i := mini(stage, 2)
	return "연쇄 %d → 다음 효과 ×%s · 피해 ×%s" % [stage, str(CHAIN_MULT[i]), str(CHAIN_DMG[i])] # "→" = 다음 대마법에 붙는 값 (R2 — 큰 글자에서 테를 넘쳐 줄임, review_L §4.3)


## 강화 레벨을 반영한 장비 (lv 표의 칸으로 덮어씀)
static func equip_at(id: String, lv := 1) -> Dictionary:
	var base: Dictionary = EQUIPS.get(id, {})
	if lv <= 1 or not base.has("lv"):
		return base
	var o: Dictionary = base.duplicate()
	var over: Dictionary = base.lv.get(clampi(lv, 1, 3), {})
	for key in over:
		o[key] = over[key]
	return o


## 편성 상태의 빈 곳을 기본값으로 채운다 (파티 · 마녀마다 장착·장비·강화) — TSetup.ensure_state · TSave가 같이 씀
static func fill_state(state: Dictionary) -> void:
	if not state.has("party"):
		var p: Array = []
		for w in BATTLE.party:
			p.append(String(w))
		state["party"] = p
	for wid in ROSTER:
		if not state.has(wid):
			var d: Array[String] = []
			for s in WITCHES[wid].default:
				d.append(String(s))
			state[wid] = {"equipped": d, "equip": "", "equip_lv": 1, "skill_lv": {}}


## 장비는 파티에 한 명만 (§4.3). state = 편성 상태 {"party": [...], 마녀 id: {"equip": ...}} (TSetup.state)
## eid를 파티의 다른 마녀(except_wid 말고)가 끼고 있나
static func equip_taken(state: Dictionary, eid: String, except_wid: String) -> bool:
	if eid == "":
		return false
	for w in state.get("party", []):
		if String(w) != except_wid and String(state.get(String(w), {}).get("equip", "")) == eid:
			return true
	return false


## 자리 slot 마녀의 장비를 d 방향의 다음 것으로 — 다른 파티원이 낀 장비는 건너뛴다. 바뀐 장비 id
static func step_equip(state: Dictionary, slot: int, d: int) -> String:
	var wid := String(state.party[slot])
	var i := EQUIP_ORDER.find(String(state[wid].get("equip", "")))
	for k in EQUIP_ORDER.size():
		i = (i + d + EQUIP_ORDER.size()) % EQUIP_ORDER.size()
		if not equip_taken(state, String(EQUIP_ORDER[i]), wid):
			break
	state[wid].equip = EQUIP_ORDER[i]
	return String(EQUIP_ORDER[i])


## 파티에 새로 들어온 마녀의 장비가 이미 파티에 있으면 "없음"으로 [제안 §4.3]
static func fix_equip(state: Dictionary, wid: String) -> void:
	if equip_taken(state, String(state[wid].get("equip", "")), wid):
		state[wid].equip = ""


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


## 화면 숫자 표기 (§21.13): 1,000만 미만 쉼표 전부 · 1억 미만 "1,235만" · 100억 미만 "1.23억" · 그 위 "123억".
## 반올림이 다음 단위로 넘어가면 다음 단위로 다시 정한다 (99,995,000 → 1.00억, §26 X27)
static func fmt_short(n: int) -> String:
	var a := absi(n)
	var sign := "-" if n < 0 else ""
	if a < 10000000:
		return fmt(n)
	if a < 100000000:
		var man := int(round(float(a) / 10000.0))
		if man < 10000:
			return sign + fmt(man) + "만"
	var e2 := int(round(float(a) / 1000000.0)) # 억의 100분의 1
	if e2 < 10000:
		return sign + "%.2f억" % (float(e2) / 100.0)
	return sign + fmt(int(round(float(a) / 100000000.0))) + "억"
