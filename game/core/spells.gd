class_name Spells
extends RefCounted
## 마법 7종 (docs/archive/sera/magic.md): 등급·레벨·장착·마도석. 상태는 전부 GameState 플래그에 들어가 저장된다.
##   배움 ab_<능력>, 레벨 lv_<마법>(1~3), 장착 eq_a·eq_s·eq_f, 마도석 mana_stones(가진 수)·mana_total(모은 수)

const ORDER := ["pillar", "storm", "levitate", "wings", "ward", "meteor", "phoenix"]

## slot: as(A·S 칸) · f(고급 칸) · passive(상시). keys: 수업을 마쳐 배울 때 알림 창의 조작 안내 (Cut.spell_learned)
const DATA := {
	"pillar": {
		"name": "불기둥", "short": "불기둥", "grade": 0, "slot": "as", "ability": "", "teacher": "엠버린 교수",
		"desc": "앞쪽 가까운 적의 발밑에서 불기둥이 솟고 양옆으로 이어 솟는다. 맞은 적은 하늘로 뜬다.",
		"lv": ["중심 120 · 연쇄 60 (양옆 2개씩), 재사용 1.0초", "피해 +25%, 재사용 0.85초", "연쇄 3개씩(일곱 줄기), 피해 +50%, 재사용 0.75초"],
	},
	"storm": {
		"name": "화염 폭풍", "short": "폭풍", "grade": 0, "slot": "as", "ability": "storm", "teacher": "엠버린 교수",
		"desc": "앞으로 넓은 부채꼴의 불길을 내뿜는다. 돌진하는 적도 멈춰 세운다.",
		"lv": ["30 × 5 + 마지막 90, 재사용 1.4초", "피해 +25%, 재사용 1.2초", "지나간 자리에 2초 동안 불바다, 재사용 1.05초"],
	},
	"levitate": {
		"name": "부양", "short": "부양", "grade": 0, "slot": "passive", "ability": "double_jump", "teacher": "오필리아 교수",
		"desc": "공중에서 한 번 더 뛰어오른다.",
		"lv": ["2단 점프", "더 높이, 정점에서 잠깐 머묾", "3단 점프"],
	},
	"wings": {
		"name": "불꽃 날개", "short": "날개", "grade": 1, "slot": "passive", "ability": "wings", "teacher": "오필리아 교수",
		"keys": "공중에서 Z를 다시 누르고 있기",
		"desc": "공중에서 점프를 다시 누르고 있으면 불꽃 날개로 활공한다. 굴뚝 열기·바람길 같은 상승 기류를 타고 솟아오른다.",
		"lv": ["활공 · 상승 기류 타기", "활공이 빨라지고 기류를 더 세게 탄다", "활공 중 아래로 불씨가 떨어져 적을 태운다"],
	},
	"ward": {
		"name": "불꽃 방벽", "short": "방벽", "grade": 1, "slot": "as", "ability": "ward", "teacher": "엠버린 교수",
		"keys": "마법서에서 A·S 칸에 끼우기",
		"desc": "잠깐 불의 원을 두른다. 그 사이엔 다치지 않고, 날아온 탄은 되쏘며, 닿은 적은 불에 덴다.",
		"lv": ["0.5초, 되쏜 탄 150 · 화상 120, 재사용 2.5초", "0.65초, 되쏘기 +25%, 재사용 2.1초", "막는 순간 주위에 불꽃 폭발 200, 재사용 1.8초"],
	},
	"meteor": {
		"name": "유성 낙화", "short": "유성", "grade": 2, "slot": "f", "ability": "meteor", "teacher": "베로니카 교수",
		"keys": "F (패드 R3)",
		"desc": "하늘로 떠올라 모든 마력을 하늘에 바친다. 붉게 물든 하늘에서 유성이 쏟아진다.",
		"lv": ["유성 7개(220) + 큰 유성 600, 재사용 40초", "유성 10개, 재사용 34초", "유성 15개 + 땅에 불바다, 재사용 30초"],
	},
	"phoenix": {
		"name": "불사조", "short": "불사조", "grade": 2, "slot": "f", "ability": "phoenix", "teacher": "그레타 (금서)",
		"keys": "F (패드 R3)",
		"desc": "몸에서 거대한 불사조가 솟아 화면을 세 번 가른다. 불사조의 불은 세라를 치유한다.",
		"lv": ["세 번 가르기(각 400) + 체력 1 회복, 재사용 60초", "체력 2 회복, 재사용 50초", "부활의 불꽃: 준비된 채 쓰러지면 체력 3으로 되살아남, 재사용 45초"],
	},
}

## 1장 능력 습득 알림 (Cut.learn): 능력 ID → [이름, 조작, 설명]. 마법서 설명(DATA.desc)과 문구가 다르다 — 습득 순간용
const ABILITY_TEXT := {
	"storm": ["화염 폭풍", "S (패드 RB)", "앞쪽으로 몰아치는 불길. 가까운 적을 날려 보내고\n돌진하는 적을 끊어 낸다."],
	"double_jump": ["부양", "공중에서 Z (패드 A)", "공중에서 한 번 더 뛰어오른다.\n높은 곳에 닿을 수 있다."],
	"fox_window": ["여우창문", "D (패드 Y)", "손으로 여우 모양 창을 만들어 들여다본다.\n둔갑한 것의 참모습 — 환영 벽과 숨은 발판이 드러난다."],
	"fox_mode": ["빙의 — 여우 모드", "폭주 게이지가 가득 차면 자동", "너울이 폭주를 받아 다스린다. 12초 동안 푸른 여우불의 기술.\n쓰고 나면 너울의 기운이 다시 차오를 때까지 기다려야 한다."],
}

const GRADE_NAMES := ["초급", "중급", "고급"]
## [Lv2 비용, Lv3 비용] — 등급별 (docs/archive/sera/magic.md 2절)
const COSTS := [[3, 5], [3, 5], [5, 8]]
## 레벨별 피해 배율·재사용 배율
const DMG_MULT := [1.0, 1.25, 1.5]
const CD_MULT := [1.0, 0.85, 0.75]
## 고급 마법 재사용 (초)
const ULT_CD := {"meteor": [40.0, 34.0, 30.0], "phoenix": [60.0, 50.0, 45.0]}
const WARD_CD := [2.5, 2.1, 1.8]


static func info(id: String) -> Dictionary:
	return DATA.get(id, {})


## 능력 습득 알림 문구 [이름, 조작, 설명] (표에 없으면 [ID, "", ""])
static func ability_text(ability: String) -> Array:
	return ABILITY_TEXT.get(ability, [ability, "", ""])


static func learned(id: String) -> bool:
	var ab := String(info(id).get("ability", ""))
	if id == "pillar":
		return true
	# 수업 시험 중엔 임시로 쓸 수 있다 (temp_wings 등) — 습득은 수업을 마칠 때
	return ab != "" and (GameState.has_ability(ab) or GameState.has_flag("temp_" + ab))


static func level(id: String) -> int:
	return clampi(int(GameState.flag("lv_" + id, 1)), 1, 3)


static func grade(id: String) -> int:
	return int(info(id).get("grade", 0))


static func grade_name(id: String) -> String:
	return GRADE_NAMES[grade(id)]


## 다음 레벨 비용 (최대면 0)
static func next_cost(id: String) -> int:
	var lv := level(id)
	if lv >= 3:
		return 0
	return int(COSTS[grade(id)][lv - 1])


static func can_level(id: String) -> bool:
	return learned(id) and level(id) < 3 and stones() >= next_cost(id)


static func level_up(id: String) -> bool:
	if not can_level(id):
		return false
	var cost := next_cost(id)
	GameState.set_flag("mana_stones", stones() - cost)
	GameState.set_flag("lv_" + id, level(id) + 1)
	return true


static func stones() -> int:
	return int(GameState.flag("mana_stones", 0))


static func add_stones(n: int) -> void:
	GameState.set_flag("mana_stones", stones() + n)
	GameState.set_flag("mana_total", int(GameState.flag("mana_total", 0)) + n)


## 피해 배율 (레벨)
static func dmg_mult(id: String) -> float:
	return DMG_MULT[level(id) - 1]


static func cd_mult(id: String) -> float:
	return CD_MULT[level(id) - 1]


## 칸에 끼운 마법 (a·s·f). 배우지 않았으면 ""
static func equipped(slot: String) -> String:
	var def := {"a": "pillar", "s": "storm", "f": ""}
	var id := String(GameState.flag("eq_" + slot, def.get(slot, "")))
	if id == "" or not learned(id):
		return ""
	return id


## 이 칸에 낄 수 있는 마법인가
static func fits(slot: String, id: String) -> bool:
	var s := String(info(id).get("slot", ""))
	return (s == "as" and (slot == "a" or slot == "s")) or (s == "f" and slot == "f")


## 칸에 끼우기. A·S에 같은 마법이 있으면 서로 바꾼다
static func equip(slot: String, id: String) -> void:
	if not fits(slot, id) or not learned(id):
		return
	if slot == "a" or slot == "s":
		var other := "s" if slot == "a" else "a"
		if equipped(other) == id:
			GameState.set_flag("eq_" + other, equipped(slot))
	GameState.set_flag("eq_" + slot, id)


## 고급 마법을 배우면 F 칸이 비어 있을 때 자동으로 끼움
static func auto_equip(id: String) -> void:
	var s := String(info(id).get("slot", ""))
	if s == "f" and equipped("f") == "":
		GameState.set_flag("eq_f", id)
	elif s == "as":
		if equipped("a") == "":
			GameState.set_flag("eq_a", id)
		elif equipped("s") == "":
			GameState.set_flag("eq_s", id)


## 재사용 대기 기본값 (레벨 반영, 여우 모드 전)
static func cooldown_for(id: String, t: Tuning) -> float:
	match id:
		"pillar":
			return t.pillar_cooldown * cd_mult(id)
		"storm":
			return t.storm_cooldown * cd_mult(id)
		"ward":
			return WARD_CD[level(id) - 1]
		"meteor", "phoenix":
			return ULT_CD[id][level(id) - 1]
	return 1.0
