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
		"retainPos": "right",      # 보존 카드(죽음 카드) 자리: right(맨 오른쪽, 대본 v3 "손패 맨 오른쪽") | middle(HTML 판)
		"maxHand": 10,             # 손패 상한 (넘치면 더 뽑지 않음)
		"guardRound": "floor",     # 감싸기 '절반' 반올림: floor | ceil
		"downedReviveHp": 1,       # 전투 후 쓰러진 동료가 복귀하는 HP
		"retryWitchHp": 6,         # [임시] 전멸 뒤 그 전투를 처음부터 다시 할 때 노엘 HP 가 이보다 낮으면 이만큼으로 (HP 가 낮은 채 시작해 계속 지는 막힘 방지 — DECISIONS.md)
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

		# 죽음 카드 — 2026-11-21 컨셉 변경(vertical-slice.md 5장): 동료의 죽음을 **미리 보여 주는** 카드. 낼 수 없다(unplayable).
		# 손패에 보존되어 한 칸을 차지한다. 운명의 죽음이 실제로 일어나면(받아들임) effects 가 실행된다:
		# 그 동료 사망 → 그 동료 카드는 유품으로 → 상속 카드(그 죽음의 힘)가 덱에. 카드를 내서 죽이는 방식은 없앴다.
		# 튜토리얼의 세라피나 카드는 뒤집힌 채(카드 인스턴스 faceDown) 손패에 있다가 3턴 「짓밟기」 순간 저절로 뒤집힌다(대본 v3 5.2)
		"hero_death": {"name": "용사의 죽음", "kind": "death", "ally": "hero", "owner": "witch", "cost": 0, "target": "none", "art": "deathface",
			"retain": true, "exhaust": true, "unplayable": true, "fate": "hero_stomp",
			"effects": [
				{"type": "killAlly", "ally": "hero"},
				{"type": "relicize", "ally": "hero"},
				{"type": "addCard", "card": "trample", "permanent": true, "at": "source"},
			],
			"text": "세라피나는 1층 가장 깊은 곳에서 짓밟혀 죽는다.",   # 대본 v3 5.4
			"tags": ["예지"]},

		# 상속 카드
		"trample": {"name": "짓밟힘", "kind": "inherit", "owner": "witch", "from": "hero", "cost": 2, "target": "none", "art": "foot",
			"effects": [{"type": "damageAll", "amount": 15}], "text": "모든 적에게 {all} 피해",
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

		# ───── 1차 시험판 v2: 운명(prototype-v2-spec.md 4.3) [임시 수치] ─────
		# 카드 인스턴스의 lv(레벨)에 따라 "levels" 의 같은 키를 덮어쓴다 (text·effects·target·cost·tags). 레벨 키는 문자열 "2", "3".
		# 죽음 카드(낼 수 없음): 운명을 받아들이면 그 동료가 사망 → 그 동료 카드는 유품으로 → 상속 카드(같은 Lv)를 덱에 영구 1장 + 이번 전투 손패에 바로 1장
		# maskText: 아직 방식이 보이지 않을 때(빈 캠프의 다음 죽음 예고, 대본 v3 6장) 카드에 대신 보이는 번진 문구
		"warrior_death": {"name": "전사의 죽음", "kind": "death", "ally": "warrior", "owner": "witch", "cost": 0, "target": "none", "art": "deathface",
			"retain": true, "exhaust": true, "unplayable": true, "fate": "warrior_pierce",
			"maskText": "브룬힐드는 ……에서 …… 죽는다.",
			"effects": [
				{"type": "killAlly", "ally": "warrior"},
				{"type": "relicize", "ally": "warrior"},
				{"type": "addCard", "card": "pierced_shield", "permanent": true, "lvFrom": "source", "at": "source"},
			],
			"text": "브룬힐드는 2층에서 관통당해 죽는다.",
			"levels": {
				"2": {"text": "브룬힐드는 3층에서 꼬챙이에 꿰여 매달려 죽는다."},
				"3": {"text": "브룬힐드는 4층에서 수십 개의 창에 꿰여 죽는다."},
			},
			"tags": ["예지", "죽으면 「꿰뚫린 방패」"]},
		"archer_death": {"name": "궁수의 죽음", "kind": "death", "ally": "archer", "owner": "witch", "cost": 0, "target": "none", "art": "deathface",
			"retain": true, "exhaust": true, "unplayable": true, "fate": "archer_burn",
			"effects": [
				{"type": "killAlly", "ally": "archer"},
				{"type": "relicize", "ally": "archer"},
				{"type": "addCard", "card": "burnt_bow", "permanent": true, "lvFrom": "source", "at": "source"},
			],
			"text": "엘리안은 3층에서 불에 타 죽는다.",
			"levels": {
				"2": {"text": "엘리안은 4층에서 산 채로 불길에 휩싸여 죽는다."},
				"3": {"text": "엘리안은 5층에서 재가 될 때까지 타 죽는다."},
			},
			"tags": ["예지", "죽으면 「타버린 활」"]},
		# 상속 카드 (죽음 카드와 같은 Lv)
		"pierced_shield": {"name": "꿰뚫린 방패", "kind": "inherit", "owner": "witch", "from": "warrior", "cost": 1, "target": "intent", "art": "shield",
			"effects": [{"type": "reflect", "all": false}], "text": "예고된 공격 1개를 막고(피해 0)\n그 피해만큼 되돌린다",
			"levels": {"2": {"target": "none", "effects": [{"type": "reflect", "all": true}], "text": "예고된 공격을 모두 막고(피해 0)\n각 피해만큼 되돌린다"}},
			"tags": ["상속"]},
		"burnt_bow": {"name": "타버린 활", "kind": "inherit", "owner": "witch", "from": "archer", "cost": 1, "target": "none", "art": "arrows",
			"effects": [{"type": "damageAll", "amount": 10}], "text": "모든 적에게 {all} 피해",
			"levels": {"2": {"effects": [{"type": "damageAll", "amount": 16}]}},
			"tags": ["상속"]},
		# 흉터: 운명을 거스른 값. 낼 수 없고, 손에 든 채 턴이 끝나면 노엘 HP -1. 그 회차 내내 덱에 남는다(전투 안에서 못 지움)
		"scar": {"name": "흉터", "kind": "scar", "owner": "witch", "cost": 0, "target": "none", "art": "scar", "unplayable": true,
			"endTurnSelf": 1, "effects": [], "text": "낼 수 없다.\n손에 든 채 턴이 끝나면\n노엘 HP -1"},
		# 유품 카드 (전사) [임시]
		"warrior_shard": {"name": "브룬힐드의 방패 조각", "kind": "relic", "owner": "warrior", "cost": 1, "target": "enemy", "art": "shield",
			"effects": [{"type": "weaken", "amount": 8}, {"type": "selfDamage", "amount": 1}], "text": "적 1명의 이번 공격 피해 -{weaken}\n노엘 HP -{self}"},
		"warrior_last_bash": {"name": "브룬힐드의 마지막 강타", "kind": "relic", "owner": "warrior", "cost": 1, "target": "enemy", "art": "bash",
			"effects": [{"type": "damage", "amount": 12}, {"type": "selfDamage", "amount": 2}], "text": "적 1명에게 {dmg} 피해\n노엘 HP -{self}"},

		# ───── 버티컬 슬라이스 1층 방 보상 (대본 v3 3장) [임시 수치] ─────
		# 핏자국 통로 끝(시체)의 카드: 예고 하나를 지운다(그 공격은 일어나지 않는다). 운명 공격은 지울 수 없다. 대가 노엘 HP. 전투마다 한 번(낸 뒤 그 전투에서 사라짐 = exhaust)
		"nameless_card": {"name": "이름 없는 마녀의 카드", "kind": "witch", "owner": "witch", "cost": 0, "target": "intent", "art": "nameless",
			"exhaust": true, "effects": [{"type": "cancelIntent"}, {"type": "selfDamage", "amount": 3}],
			"text": "예고 하나를 지운다\n(운명 공격은 못 지움)\n노엘 HP -{self}", "tags": ["전투마다 한 번"]},
		# 순장된 자의 방(사건, 꺼낸다): 아이가 쥐고 있던 부적. target ally: 동료 위로 끌어 놓는다
		"small_charm": {"name": "작은 손의 부적", "kind": "witch", "owner": "witch", "cost": 1, "target": "ally", "art": "charm",
			"effects": [{"type": "heal", "amount": 4}], "text": "동료 하나 HP {heal} 회복"},
	},

	# 동료가 죽으면 그 동료의 카드가 이것으로 바뀐다 (강화 표시는 사라진다)
	"relicMap": {
		"holy_slash": "broken_sword",
		"vanguard": "last_charge",
		"snipe": "archer_arrow",
		"suppress": "archer_last_suppress",
		"cover": "warrior_shard",
		"shield_bash": "warrior_last_bash",
	},

	# 튜토리얼 시작 덱 15장 (6.2)
	"startingDeck": [
		["curse_flame", 2], ["fate_shift", 2], ["take_hit", 1], ["foresight", 1],
		["holy_slash", 2], ["vanguard", 1],
		["cover", 2], ["shield_bash", 1],
		["snipe", 2], ["suppress", 1],
	],

	# 처음부터 걸려 있는 운명 (대본 v3: 세라피나의 죽음 카드는 손패에 뒤집힌 채로만 — 무엇인지는 죽기 직전까지 보여 주지 않는다)
	# faceDown: 그 죽음 카드를 뒤집힌 채로 든다(낼 수 없음, 손패 한 칸 차지). 운명의 순간 저절로 뒤집힌다
	"startingFates": [{"fate": "hero_stomp", "floor": 1, "faceDown": true}],

	# ───────────── 전투 보상 (대본 v3 1·3장, vertical-slice.md 5장 방 종류) [임시] ─────────────
	# common: 일반 전투 — 3장 중 1장(넘길 수 있음). rare: 강적 — 희귀 3장 중 1장.
	# [임시] 희귀 카드가 아직 없어 강화표(upgrades)의 카드를 Lv2(강화된 채)로 준다(rareUp). 새 카드가 생기면 목록만 바꾼다.
	"rewards": {
		"choices": 3,
		"common": ["curse_flame", "fate_shift", "take_hit", "foresight", "holy_slash", "vanguard", "cover", "shield_bash", "snipe", "suppress"],
		"rare": ["holy_slash", "snipe", "cover", "curse_flame"],
		"rareUp": true,
	},
	# 묘지기의 좌판(거래, 대본 v3 3.7) [수치 임시]: 노엘의 HP를 대가로 카드(3장 중 1장) 또는 촛불. HP 가 대가 이하이면 고를 수 없다
	"trade": {"cardHp": 4, "candleHp": 2, "candles": 1},
	# 순장된 자의 방(사건, 대본 v3 3.3) [임시]: 꺼내면 노엘 HP −2(1 아래로는 줄지 않음) + 「작은 손의 부적」
	"buried": {"hp": 2, "card": "small_charm"},
	# 핏자국 통로 끝(시체, 대본 v3 3.4): 「이름 없는 마녀의 카드」
	"corpse": {"card": "nameless_card"},

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
		# 1차 시험판 v2 [임시 수치 — 2명(노엘+엘리안)으로도 이길 수 있게, 3명이면 조금 여유]
		# pattern: 턴마다 차례로 도는 예고 (kind attack: target random | highest(HP 가장 높은 동료) / kind aoe: 모두에게)
		# scale: 전투 화면에서 적 자리 높이의 배율
		"spear_knight": {"name": "창 기사", "hp": 36, "sprite": "spr_cult_knight.png", "scale": 1.22,
			"pattern": [
				{"kind": "attack", "label": "찌르기", "value": 7, "target": "random"},
				{"kind": "attack", "label": "관통 돌진", "value": 10, "target": "highest"},
			]},
		"pyre_priest": {"name": "화형 사제", "hp": 46, "sprite": "spr_pyre_priest.png", "scale": 1.22,
			"pattern": [
				{"kind": "aoe", "label": "불길", "value": 3, "hitsWitch": true},
				{"kind": "attack", "label": "화염", "value": 6, "target": "random"},
			]},
		# 버티컬 슬라이스 1층 강적 (대본 v3 3.2) [임시 수치·그림: 무덤지기 그림이 아직 없어 창 기사 그림을 어둡게(tint) 쓴다]
		"gravekeeper": {"name": "무덤지기", "hp": 34, "sprite": "spr_cult_knight.png", "scale": 1.32, "tint": [0.62, 0.58, 0.56],
			"pattern": [
				{"kind": "attack", "label": "관 뚜껑 내려치기", "value": 8, "target": "random"},
				{"kind": "attack", "label": "짓누르기", "value": 10, "target": "highest"},
			]},
	},

	# ───────────── 전투 (7장 + tutorial-flow.md) ─────────────
	"encounters": {
		# darkness: true 면 어둠(촛불이 다 탄 뒤 방마다 깊어짐)에 예고 일부가 '?'로 가려진다 — 층 끝 전투·강적 전투 (vertical-slice.md 5장)
		# floorEnd: true 면 층 끝 전투 — 그 층에서 전조를 보았으면 어둠이 와도 가려지지 않는다. 운명 공격 예고는 언제나 보인다
		# 1층 장례 회랑 전투 ①: 광신도 3명. 완전히 끝나는 전투(거대 존재 없음). 배경은 직전 VN 장면과 같게(bg)
		"normal": {
			"kind": "normal", "floor": 1, "bg": "bg_cathedral.png",
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
		# 1층 광신도 기도실(골라 들어가는 방, 전투): 광신도 2명 [임시 수치]
		"prayer": {
			"kind": "normal", "floor": 1, "bg": "bg_fork_crypt.png",
			"enemies": [{"id": "c1", "type": "cultist", "slot": 0}, {"id": "c3", "type": "cultist", "slot": 2}],
			"attackRange": [4, 6],
		},
		# 1층 무덤지기(기도실 안쪽, 강적) — 어둠의 영향을 받는다
		"gravekeeper": {
			"kind": "normal", "floor": 1, "bg": "bg_ossuary.png", "darkness": true, "elite": true,
			"enemies": [{"id": "g1", "type": "gravekeeper", "slot": 1}],
			"attackRange": [6, 8],
		},
		# 1층 가장 깊은 곳(층 끝): 광신도 2 → 1명 남으면 발이 내려와 짓밟음 → 거대한 발 보스 전투
		"deep": {
			"kind": "normal", "floor": 1, "dim": true, "darkness": true, "floorEnd": true,
			"enemies": [{"id": "c1", "type": "cultist", "slot": 0}, {"id": "c3", "type": "cultist", "slot": 2}],
			"attackRange": [5, 6],
			"giantTriggerAlive": 1,
			"scriptedIntents": {
				1: {"c1": {"value": 6, "target": "archer"}, "c3": {"value": 5, "target": "warrior"}},
			},
			"scriptedHands": {},
		},
		# 거대한 발 — 보스 전투(대본 v3 5.2). HP 는 「???」, 공격은 흠집만 낸다(immune).
		# 3턴 「짓밟기」 = 세라피나의 운명(hero_stomp): 손패의 뒤집힌 카드가 저절로 뒤집히고 → 데스신 → 받아들임(튜토리얼은 거스를 수 없음)
		"giant": {
			"kind": "giant", "floor": 1, "darkness": true, "floorEnd": true,
			"enemies": [{"id": "giant", "type": "giant", "slot": "giant"}],
			# 3턴 카운트다운 (마지막 항목이 계속 반복). fate: 그 운명이 살아 있으면 이 행동이 운명의 시도가 된다(어둠에서도 늘 보임)
			"countdown": [
				{"kind": "shadow", "label": "그림자", "detail": "행동 없음"},
				{"kind": "aoe", "label": "기둥 붕괴", "value": 5, "hitsWitch": true, "detail": "아군 전원"},
				{"kind": "stomp", "label": "짓밟기", "detail": "모두에게 큰 피해", "lethal": true, "fate": "hero_stomp"},
			],
		},
		# ───── 1차 시험판 v2 ─────
		# bg: 전투 배경 / fateIntents: {턴: {enemy, fate, label}} — 그 운명이 살아 있고 이 층에서 아직 시도되지 않았으면 그 턴 예고가 운명의 시도가 된다.
		#   그 적(집행자)이 그 전에 쓰러지면 쓰러지는 순간 운명의 시도가 온다 (2026-11-18 결정: 운명의 시도는 전투 안에서만)
		"ossuary": {
			"kind": "normal", "floor": 2, "bg": "bg_ossuary.png",
			"enemies": [{"id": "c1", "type": "cultist", "slot": 0}, {"id": "k1", "type": "spear_knight", "slot": 1}],
			"attackRange": [3, 5],
			"fateIntents": {"2": {"enemy": "k1", "fate": "warrior_pierce", "label": "운명의 관통"}},
		},
		"pyre": {
			"kind": "normal", "floor": 3, "bg": "bg_pyre_court.png",
			"enemies": [{"id": "p1", "type": "pyre_priest", "slot": 1}, {"id": "c1", "type": "cultist", "slot": 2}],
			"attackRange": [3, 5],
			"fateIntents": {"2": {"enemy": "p1", "fate": "archer_burn", "label": "운명의 불길"}, "3": {"enemy": "p1", "fate": "warrior_pierce", "label": "운명의 꼬챙이"}},
		},
	},

	# ───────────── 운명 (fate-design.md, prototype-v2-spec.md 4.1) ─────────────
	# 운명 = {누가, 방식, 층, 레벨}. 런 상태 st.fates 에 [{id, who, method, floor, level, alive, result, triedFloor, card}] 로 들어간다.
	# scars: 거스를 때 들어오는 흉터 장수 [1단계, 2단계, 3단계] / maxLevel 단계를 다 넘기면 구함
	# 시험판에서는 대상·방식·층을 아래 fatePlan 으로 고정한다(원래는 무작위 — 나중에 이 표를 무작위로 만들면 된다)
	# noDefy: 거스를 수 없다(튜토리얼 — 선택 없이 받아들임) / endsBattle: 받아들인 뒤 전투가 끝난다(일행이 물러남)
	"fates": {
		"hero_stomp": {"who": "hero", "method": "stomp", "card": "hero_death", "inherit": "trample", "scars": [1, 1, 2], "maxLevel": 1,
			"noDefy": true, "endsBattle": true},
		"warrior_pierce": {"who": "warrior", "method": "pierce", "card": "warrior_death", "inherit": "pierced_shield", "scars": [1, 1, 2], "maxLevel": 3},
		"archer_burn": {"who": "archer", "method": "burn", "card": "archer_death", "inherit": "burnt_bow", "scars": [1, 1, 2], "maxLevel": 3},
	},
	# 새 운명이 비치는 때: at(장면) → 그 운명이 floor 층에서 온다
	"fatePlan": [
		{"at": "emptycamp", "fate": "warrior_pierce", "floor": 2},
		{"at": "f2stairs", "fate": "archer_burn", "floor": 3},
	],
	"fateRules": {
		"deathCardTakesSlot": true,   # 손에 든 죽음 카드 수만큼 덜 뽑는다 (드로우 = 5 − 죽음 카드 수)
		"healOnFloor": true,          # [임시] 새 층에 들어설 때(빈 캠프·2층 계단) 살아 있는 모두 HP 회복
	},

	# ───────────── 비주얼노벨 장면(방마다)의 배경 ─────────────
	# 대사는 script_data.gd (camp / events.<장면>). bgZoom: 배경 그림의 한 곳(focus)을 scale 배로 확대해 보여 준다(같은 그림 재사용)
	# emptyBedroll: 빈 캠프에서 비어 있는 침낭 자리(1920×1080 기준) — 코드로 차가운 빛·그늘을 얹는다
	# [임시] 버티컬 슬라이스 배경(docs/prompts/vs_assets.md B01~B13)이 아직 없어 기존 그림을 대신 쓴다. 그림이 오면 bg 파일 이름만 바꾼다.
	#   전투가 있는 방은 전투 배경(encounters.<전투>.bg)과 같은 그림을 써서 대화하던 배경 그대로 전투가 시작되게 한다(vertical-slice.md 3장)
	"vnScenes": {
		"camp": {"bg": "bg_camp.png", "fire": true},                                        # 곁방(캠프) — B01
		"corridor": {"bg": "bg_cathedral.png"},                                             # 장례 회랑 — 전투 ① (P07)
		"hall": {"bg": "bg_fork_crypt.png"},                                                # 안치 홀(지도) — B03
		"prayer": {"bg": "bg_fork_crypt.png"},                                              # 광신도 기도실 — B06 (전투 배경 겸용)
		"gravekeeper": {"bg": "bg_ossuary.png"},                                            # 무덤지기의 방 — B07 (강적 전투 배경 겸용)
		"buried": {"bg": "bg_ossuary.png", "bgZoom": {"scale": 1.5, "focus": [700, 560]}},  # 순장된 자의 방 — B08
		"corpse": {"bg": "ev_corpse_witch.png"},                                            # 핏자국 통로 끝(죽은 마녀) — B09
		"chapel": {"bg": "bg_fork_crypt.png", "bgZoom": {"scale": 1.6, "focus": [960, 430]}, "fire": true},   # 촛불 예배당 — B10
		"training": {"bg": "bg_fork_crypt.png", "bgZoom": {"scale": 1.55, "focus": [1560, 470]}},             # 무너진 훈련장 — B11
		"stall": {"bg": "bg_ossuary.png", "bgZoom": {"scale": 1.45, "focus": [1300, 520]}},                  # 묘지기의 좌판 — B12
		"footprints": {"bg": "bg_cathedral.png", "bgZoom": {"scale": 1.5, "focus": [960, 700]}},             # 발자국 방 — B13
		"stairs": {"bg": "bg_stairs_descent.png"},                                          # 계단 앞 홀 — B04
		"deep": {"bg": "bg_cathedral.png"},                                                 # 가장 깊은 곳 — B05 (광신도·보스 전투 겸용)
		"emptycamp": {"bg": "bg_camp.png", "fire": true, "fireLow": true, "emptyBedroll": [1350, 640]},     # 빈 곁방 — B02
		# 2·3층 (탑뷰를 없애고 VN 장면 + 전투로 — 이야기·그림은 아직 시험판 v2 그대로)
		"f2corridor": {"bg": "bg_cathedral.png", "bgZoom": {"scale": 1.3, "focus": [960, 600]}},
		"f2ossuary": {"bg": "bg_ossuary.png"},
		"f2stairs": {"bg": "bg_stairs_descent.png"},
		"f3chapel": {"bg": "bg_fork_crypt.png", "bgZoom": {"scale": 1.3, "focus": [960, 500]}},
		"f3pyre": {"bg": "bg_pyre_court.png"},
	},
	# VN 캠프 등에서의 스탠딩 자리(가로 위치) / 높이 / 위쪽 y
	"vn": {"slots": {"FL": 250, "L": 600, "C": 960, "R": 1320, "FR": 1670}, "standH": 1010, "standTop": 120},

	# ───────────── 죽음 카드 암시 (캠프·계단·빈 캠프) ─────────────
	# 1인칭 오른손(ui_witch_hand_raise.png)이 아래에서 올라와 반투명한 카드를 쥐고, 동료 쪽 붉은 실이 잠깐 팽팽해진다.
	# clarity: 0(누군지 알아볼 수 없음) ~ 1(또렷함) — 대본 v0.6: 캠프·계단은 또렷(카드 문구까지), 빈 캠프의 다음 카드는 0
	# 손(ui_witch_hand_raise.png)은 x,y,scale / 떠오른 카드는 cardX,cardY(왼쪽 위), cardK(배율)
	"omen": {"scale": 0.9, "x": 175, "y": 250, "cardX": 1060, "cardY": 110, "cardK": 1.4, "from": [260, 560], "rise": 900, "fade": 700, "alpha": 0.75,
		"anchors": {"hero": [0.5, 0.33], "warrior": [0.5, 0.3], "archer": [0.5, 0.3], "noel": [0.5, 0.3]}},

	# ───────────── 탐색: 이동·갈림길 (tutorial-flow.md 2장, 목업 11) ─────────────
	"explore": {
		# 1층 전투 뒤: 회랑을 지나 갈림길로 (고를 길 없이 걸어 들어가는 연출만, 대본 3.1)
		"hall": {"bg": "bg_cathedral.png", "floor": 1, "room": "hall", "paths": [], "walkTo": [960, 470]},
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
			"archer": {"x": 600, "top": 570, "h": 620},
			"hero": {"x": 1000, "top": 540, "h": 600},
			"warrior": {"x": 1460, "top": 560, "h": 680},
		},
		# 랜턴을 든 왼손 (ui_witch_hand_lantern.png 1672×941, 손잡이 고리 근처 pivot을 중심으로 흔들림)
		"lantern": {"img": "ui_witch_hand_lantern.png", "x": -70, "y": 430, "scale": 0.74, "pivot": [530, 300]},
		# 걸어 들어가는 연출
		"walk": {"duration": 2600, "zoom": 2.1, "steps": 5, "bob": 12, "sway": 5.0, "fadeAt": 0.72, "allyShrink": 0.32},
	},

	# ───────────── 지도·랜턴 (vertical-slice.md 5장 '층 구조'·'튜토리얼 지도 초안', 대본 v3 2장) [제안·시험 수치] ─────────────
	# 지도 화면이 거점: 방을 눌러 들어간다. 처음 들어가는 방마다 랜턴의 촛불이 하나 탄다(지나간 방은 공짜).
	# 촛불이 0개일 때 처음 들어가는 방마다 어둠이 한 단계 깊어진다 → 어둠 단계만큼 층 끝 전투·강적 전투의 예고가 '?'로 가려진다(운명 공격은 늘 보임).
	# 층마다 새로 perFloor 개를 받고 남은 촛불은 다음 층으로 넘긴다(최대 max 개). 어둠은 층이 바뀌면 풀린다.
	"lantern": {"perFloor": 4, "max": 8},
	"darkness": {"perRoom": 1},
	# 방 종류 → 지도 아이콘 (docs/prompts/vs_assets.md 69: 교차한 칼·해골·물음표·촛불·교차한 창·관과 동전·눈)
	"roomTypes": {
		"battle": {"icon": "swords"}, "elite": {"icon": "skull"}, "event": {"icon": "question"}, "rest": {"icon": "flame"},
		"train": {"icon": "spears"}, "trade": {"icon": "coffin"}, "omen": {"icon": "eye"},
		"camp": {"icon": "camp"}, "hub": {"icon": "fork"}, "stairs": {"icon": "stairs"}, "boss": {"icon": "foot"},
	},
	# 층 지도 (튜토리얼 1층은 고정 지도. 2층부터는 규칙 있는 무작위 — 아직 없음, 2·3층은 정해진 장면 순서)
	# rooms: type(방 종류) · pos(지도 위 자리, 1920×1080 — 오른쪽 x 1440~ 은 랜턴·방 설명 칸) · candle(false 면 촛불이 타지 않음: 랜턴을 받기 전에 지나온 방)
	#        spine(정해진 길) · enc(전투) · reward(전투 뒤 보상: common | rare) · end(이 방이 층의 끝)
	# links: 이어진 방. 지나간(들어간 적 있는) 방과 이어진 방만 들어갈 수 있다. 무덤지기는 기도실 안쪽(기도실에서만)
	# [제안] 골라 들어가는 방 8개를 안치 홀·계단 앞 홀에 나눠 붙였다(문서는 "안치 홀·계단 앞 홀에 붙음"까지만 정함 — DECISIONS.md)
	"floorMaps": {
		"1": {
			"start": "hall", "end": "deep",
			"rooms": {
				"camp": {"type": "camp", "pos": [760, 98], "candle": false, "spine": true},
				"corridor": {"type": "battle", "pos": [760, 238], "candle": false, "spine": true, "enc": "normal", "reward": "common"},
				"hall": {"type": "hub", "pos": [760, 386], "candle": false, "spine": true},
				"prayer": {"type": "battle", "pos": [440, 300], "enc": "prayer", "reward": "common"},
				"gravekeeper": {"type": "elite", "pos": [190, 205], "enc": "gravekeeper", "reward": "rare"},
				"buried": {"type": "event", "pos": [1085, 282]},
				"corpse": {"type": "event", "pos": [395, 488]},
				"stall": {"type": "trade", "pos": [1160, 452]},
				"stairs": {"type": "stairs", "pos": [760, 622], "spine": true},
				"chapel": {"type": "rest", "pos": [430, 735]},
				"training": {"type": "train", "pos": [1095, 735]},
				"footprints": {"type": "omen", "pos": [1290, 590]},
				"deep": {"type": "boss", "pos": [760, 885], "spine": true, "end": true},
			},
			"links": [["camp", "corridor"], ["corridor", "hall"], ["hall", "prayer"], ["prayer", "gravekeeper"], ["hall", "buried"],
				["hall", "corpse"], ["hall", "stall"], ["hall", "stairs"], ["stairs", "chapel"], ["stairs", "training"],
				["stairs", "footprints"], ["stairs", "deep"]],
		},
	},

	# ───────────── 데스신 (1차 시험판 v2) — 자막은 script_data.gd deathScenes ─────────────
	# cuts: 컷 목록(그림·시간·확대). impact: 그 컷 시작에 흰 섬광·흔들림·피. overlay: 2단계 이상이면 덧그리는 것(spears 창 / fire 불)
	"deathScenes": {
		"warrior_pierce": {"overlay": "spears", "pool": {"x0": 600, "x1": 1320, "y": 900},
			"cuts": [
				{"id": "W1", "image": "cut_warrior_pierced.png", "duration": 4200, "zoom": [1.0, 1.08], "impact": true},
				{"id": "W2", "image": "cut_warrior_aftermath.png", "duration": 3800, "zoom": [1.07, 1.0]},
			]},
		"archer_burn": {"overlay": "fire", "pool": {"x0": 600, "x1": 1320, "y": 900},
			"cuts": [
				{"id": "A1", "image": "cut_archer_burning.png", "duration": 4400, "zoom": [1.0, 1.08], "impact": true, "blood": false},
				{"id": "A2", "image": "cut_archer_aftermath.png", "duration": 3800, "zoom": [1.07, 1.0]},
			]},
	},

	# ───────────── 용사 사망 컷신 (C1~C8) ─────────────
	# duration: 자동 진행까지의 시간(ms). 클릭하면 바로 다음 컷.
	"cutscene": {
		"cuts": [
			# 컷의 자막(대사)은 대본(script_data.gd "cutLines")에 있다
			{"id": "C1", "image": "cut_hero_reverse.png", "duration": 4600, "zoom": [1.0, 1.06]},   # 대사 1줄 (대본 v3 5.3 — 그림은 아직 기존 컷)
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
			"aimLift": 60,         # 대상 카드를 끌기 시작하면 확대를 풀고 손패 자리에서 이만큼 떠 있다가 작은 오른손(layout.grip)이 쥐어 간다
			"backs": true,         # 비는 카드 자리에는 마녀가 쥔 덱(뒷면 카드)이 보인다(손 그림이 잘려 보이지 않게)
			"dropY": 70,           # 카드를 낼 때 부채꼴 손(왼손 쪽)이 내려가는 거리
			# 카드를 낼 때 오른손이 손패에서 빠지는 동안: 손패를 왼손 쪽으로 모으는 비율(카드 자리 s → s × gather)
			"gather": 0.4,
			# 오른손이 빠질 때 함께 가져가는 덱 덮개(뒷면 카드) 자리 — 오른손 그림의 잘린 자리를 가린다
			"rightBacks": [2, 3, 4],
			"rightOut": [140, 560],   # 오른손이 빠져 내려가는 거리(x, y)
			"lockSink": 18,           # 뒤집힌 죽음 카드가 손패에서 가라앉아 보이는 깊이(px)
		},
		# 카드를 낼 때 오른손이 카드 한 장을 세워 드는 그림 (ui_witch_hand_raise.png, 원본 1672×941)
		# quad: 그 카드 자리의 네 모서리 [왼위, 오위, 오아래, 왼아래] — assets/ui_witch_hand_raise.json 값과 같아야 한다(테스트로 확인)
		"raise": {
			"img": "ui_witch_hand_raise.png", "imgW": 1672, "imgH": 941,
			"scale": 0.9, "x": 420, "y": 320,
			"from": [300, 520],
			"quad": [[866, 64], [1186, 32], [1221, 480], [914, 507]],
			# 카드를 그림의 카드 자리보다 이만큼(원본 픽셀) 옮겨 쥔다 — 엄지가 카드 아래 가장자리만 잡고 본문은 보이게
			"cardLift": [-6, -96],
		},
		# 대상을 고르는 동안(화살표) 오른손이 손패에서 그 카드를 뽑아 작게 쥐고 있는 모습 — 세운 손(raise)의 그림·카드 자리를 그대로 scale 배로 줄여 쓴다.
		# 손(rig)의 자리 x, y(화면 px, 세운 손 기준 좌표의 원점이 가는 곳). 쥔 카드와 손은 손패가 차지하는 화면 아래쪽 안에 머문다(동료·적·예고를 가리지 않게).
		# from: 쥘 때 아래에서 올라오는 거리, 취소하면 이만큼 내려가며 사라진다. 확정하면 이 손이 그대로 커지며 세운 손(raise)이 된다.
		"grip": {"scale": 0.55, "x": 520, "y": 440, "from": [0, 300]},
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
		"guideBattleY": 396,     # 전투 중 안내 상자의 위쪽 y (적·예고 줄 바로 아래)
	},

	# 대화·연출 속도 (ms)
	"timing": {
		"typeCharsPerSec": 38,
		"guideBase": 1800, "guidePerChar": 70,
		"enemyAttack": 520, "drawGap": 90, "banner": 900,
		"footDrop": 520,
		# 카드 내기: 오른손이 손패에서 빠지고(handOut) → 오른손이 카드를 세워 든 뒤(raiseUp) 카드가 날아간다 → 세운 손이 내려가고(raiseDown) 오른손이 손패로(handIn)
		"handOut": 120, "raiseUp": 150, "raiseHold": 60, "cardFly": 240, "raiseDown": 150, "handIn": 160,
		# 대상 카드를 끌기 시작하면: 오른손이 빠지고(gripOut) → 작은 오른손이 그 카드를 쥐고 올라온다(gripUp). 취소하면 작은 손이 내려가고(gripBack) 오른손이 손패로(handIn)
		"gripOut": 90, "gripUp": 110, "gripBack": 110,
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
	# 아직 없는 그림(흉터)도 미리 등록해 둔다 — 파일이 생기면 이름만 맞추면 바로 바뀐다(없으면 코드로 그린 그림)
	"cardArtImg": {"hero_death": "card_art_hero_death.png", "trample": "card_art_trample.png",
		"warrior_death": "card_art_warrior_death.png", "archer_death": "card_art_archer_death.png",
		"pierced_shield": "card_art_pierced_shield.png", "burnt_bow": "card_art_burnt_bow.png", "scar": "card_art_scar.png",
		"nameless_card": "card_art_nameless_card.png", "small_charm": "card_art_small_charm.png"},
	# 카드 뒷면 그림 (손패의 뒤집힌 죽음 카드, vs_assets.md 11). 없으면 코드로 그린 뒷면
	"cardBackImg": "card_back.png",

	# ───────────── 탑뷰 이동 시험판 (?scene=topdown, 기존 튜토리얼 흐름과 따로) ─────────────
	# 좌표는 모두 맵 그림의 실제 픽셀(td_f1_fork.png 844×664). 화면에는 zoom 배(정수)로 확대해 Nearest 로 그린다.
	# 맵: art/raw/map_f1_fork_wide_raw.png 를 tools/pixel_sheet.py --no-key --whole --block 2.5 --colors 64 로 줄인 것
	#     (블록 2.5px → 문 높이의 절반 ≈ 56px 로 노엘 걷기 시트(키 약 58px)와 픽셀 밀도를 맞춤)
	# walk: 걸을 수 있는 바닥(발끝 기준) / blocks: 그 안에서 못 들어가는 곳(기둥·돌무더기·물건)
	# occluders: 노엘보다 뒤(위쪽)에 있으면 노엘을 가리는 물건의 윤곽. base 보다 발끝이 위면 가려진다(y 기준 정렬)
	# front: 언제나 노엘보다 앞에 그리는 아래쪽 앞벽(입구 아치 양옆, 아치 안쪽 통로는 비움)
	# items: at(반짝임·! 자리) / hit(누르는 상자 x,y,w,h) / spot(걸어가 설 자리) / r(spot 에서 이 거리 안이면 조사 가능)
	# exits: at(출구 앞 자리) / r(이 거리 안에 들어서면 설명) / hit(누르는 상자) — 문구는 script_data.gd explore.fork 를 그대로 쓴다
	"topdown": {
		"map": "td_f1_fork.png", "sheet": "td_noel_walk.png", "cols": 3, "rows": 4, "foot": [32, 62],
		"zoom": 3,                 # 맵·노엘 모두 이 정수 배율 (픽셀 한 칸 = 무대 3px)
		"speed": 180,              # 걷는 속도 (맵 px/초). 조이스틱은 기울인 만큼 이 값의 일부
		"fps": 15,                 # 걷기 그림 속도 (왼발-서기-오른발-서기, 최대 속도일 때)
		"camLerp": 6.0,            # 카메라가 노엘을 따라가는 빠르기 (클수록 바짝)
		"navCell": 6,              # 탭 이동 경로찾기 격자 크기 (맵 px)
		"footR": [7, 3],           # 발 자리 반지름(가로·세로) — 벽에 이만큼 떨어져 선다
		"start": [424, 662],       # 시작: 아래 입구 아치 통로
		"entry": [424, 468],       # 걸어 들어와 서는 곳 (시험판 출구에서 되돌아오는 곳) — 뒤에 선 동료 셋이 아치 안쪽(방 안)에 들어오는 자리
		# 노엘 뒤를 줄지어 따라 걷는 동료 (순서대로). 시트는 노엘과 같은 3열×4행, 칸 72px, 발끝 [x, y]
		"followers": [
			{"id": "seraphina", "sheet": "td_seraphina_walk.png", "foot": [36, 70]},
			{"id": "brunhild", "sheet": "td_brunhild_walk.png", "foot": [36, 70]},
			{"id": "elian", "sheet": "td_elian_walk.png", "foot": [36, 70]},
		],
		"followGap": 32,           # 앞사람 발끝과의 거리 (노엘이 지나간 경로를 따라 잰 맵 px)
		# 터치 화면 이동 패드: 왼쪽 절반을 누른 자리에 조이스틱, 오른쪽 아래 조사 버튼 (크기·여백은 실제 화면 CSS px)
		"stick": {"d": 130, "knob": 0.42, "dead": 0.16, "min": 0.3, "slop": 10, "btn": 78, "margin": 22},
		"walk": [[40, 150], [78, 150], [80, 124], [90, 104], [126, 104], [132, 124], [136, 150], [392, 150], [392, 112], [456, 112], [456, 150],
			[712, 150], [712, 112], [768, 112], [768, 150], [805, 150], [805, 556], [780, 568], [745, 578], [350, 580], [95, 580], [70, 572], [52, 566], [40, 566]],
		"blocks": [
			[[20, 436], [78, 436], [98, 448], [98, 478], [20, 480]],                                        # 카드 무늬 기둥 + 촛불
			[[66, 400], [100, 392], [140, 398], [154, 418], [154, 438], [132, 450], [98, 452], [66, 446]],  # 붉은 실이 걸린 돌무더기
			[[102, 452], [152, 452], [154, 484], [102, 484]],                                               # 가죽 일지
			[[286, 378], [318, 376], [320, 394], [286, 395]],                                               # 바닥 가운데 돌 조각
			[[672, 352], [700, 344], [745, 346], [760, 322], [790, 292], [822, 262], [822, 398], [760, 396], [700, 392], [672, 374]],  # 무너진 기둥·방패
		],
		"occluders": [
			{"id": "pillar", "base": 452, "poly": [[24, 332], [38, 322], [58, 322], [72, 332], [72, 362], [68, 368], [68, 436], [76, 440], [78, 470], [24, 474], [20, 440], [26, 362]]},
			{"id": "rubble", "base": 430, "poly": [[70, 380], [82, 368], [98, 366], [100, 392], [108, 394], [130, 392], [138, 396], [150, 416], [150, 432], [140, 440], [120, 448], [100, 448], [86, 444], [70, 430]]},
			{"id": "stone", "base": 386, "poly": [[288, 368], [302, 362], [316, 366], [318, 392], [288, 393]]},
			{"id": "pile", "base": 362, "poly": [[674, 345], [680, 330], [695, 328], [710, 305], [725, 293], [745, 300], [750, 292], [785, 252], [805, 250], [822, 255], [822, 395], [790, 392], [760, 390], [745, 388], [715, 388], [700, 385], [690, 372], [676, 360]]},
		],
		"front": [
			[[0, 664], [0, 548], [24, 548], [24, 560], [50, 561], [52, 572], [75, 575], [95, 584], [130, 586], [345, 584], [350, 573], [372, 572], [378, 562], [388, 559], [398, 555], [408, 549], [424, 546], [424, 572], [415, 570], [400, 575], [392, 585], [390, 600], [390, 664]],
			[[424, 546], [432, 547], [447, 556], [460, 569], [468, 567], [477, 573], [497, 574], [500, 586], [700, 586], [730, 588], [750, 578], [790, 563], [822, 562], [822, 545], [844, 545], [844, 664], [458, 664], [458, 600], [452, 585], [445, 572], [430, 573], [424, 572]],
		],
		"items": [
			{"id": "shield", "at": [765, 352], "hit": [740, 322, 54, 72], "spot": [732, 408], "r": 30},
			{"id": "journal", "at": [128, 464], "hit": [100, 448, 58, 38], "spot": [128, 497], "r": 30},
			{"id": "spade", "at": [54, 394], "hit": [28, 366, 46, 52], "spot": [96, 372], "r": 28},
			{"id": "thread", "at": [104, 404], "hit": [76, 386, 62, 34], "spot": [170, 420], "r": 28},
		],
		"exits": [
			{"id": "corpse", "at": [108, 118], "r": 18, "hit": [70, 40, 76, 106]},
			{"id": "rest", "at": [424, 124], "r": 18, "hit": [388, 40, 72, 106]},
			{"id": "train", "at": [740, 124], "r": 18, "hit": [704, 40, 72, 106]},
		],
		# 대화창 옆 스탠딩 (무대 1920×1080 기준: 가운데 x, 위쪽 y, 높이) — 아래는 화면 밖으로 잘린다
		"stand": {"files": {"noel": "stand_witch.png", "inner": "stand_witch.png", "hero": "stand_hero.png", "warrior": "stand_warrior.png", "archer": "stand_archer.png"},
			"x": 250, "top": 300, "h": 1000},
		"dialogX": 470,            # 탑뷰에서 대화창(G.dialog)을 화면 아래, 스탠딩 오른쪽에 둔다
	},
}
