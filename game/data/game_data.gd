## game_data.gd — 수치·카드·적·화면 배치·연출 시간을 모두 모아 둔 파일.
## 대사·안내 상자·선택지·장면 문구는 data/script_data.gd (대본) 에 따로 있다.
## 두 파일만 고쳐도(에디터의 스크립트 편집기에서) 코드 수정 없이 조정할 수 있다.
## HTML 프로토타입 prototype/js/data.js 를 옮기고, 지도·방·랜턴(버티컬 슬라이스)·2·3층 전투·운명을 더했다.
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

	# ───────────── 방에서 얻는 카드 (대본 v3 3장) [임시] ─────────────
	# 전투 승리 뒤 '카드 3장 중 1장' 보상 화면은 2026-11-21 사용자 지시로 뺐다(game/DECISIONS.md).
	# common: 묘지기의 좌판(거래 trade:card)의 후보 — choices 장 중 1장. 서로 다른 카드, 죽은 동료의 카드는 빠진다.
	# elite: 강적(무덤지기)을 이기면 얻는 카드 [기본안] — 이 목록에서 무작위 1장이 강화된 채(Lv2) 바로 덱에 들어온다(고르는 화면 없음).
	#        [임시] 희귀 카드가 아직 없어 강화표(upgrades)의 카드를 쓴다. 새 카드가 생기면 목록만 바꾼다(강화표에 없는 카드는 Lv1 로 들어온다).
	"rewards": {
		"choices": 3,
		"common": ["curse_flame", "fate_shift", "take_hit", "foresight", "holy_slash", "vanguard", "cover", "shield_bash", "snipe", "suppress"],
		"elite": ["holy_slash", "snipe", "cover", "curse_flame"],
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
		"giant": {"name": "거대한 존재", "hp": null, "immune": true, "retreatOn": "trample", "sprite": "spr_giant_foot.png", "tint": [0.92, 0.9, 0.9]},
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
		# 버티컬 슬라이스 1층 강적 (대본 v3 3.2) [임시 수치]. 그림 40번(무덤지기) — 크기는 battleLayouts.vault 의 자리 높이(약 440)
		"gravekeeper": {"name": "무덤지기", "hp": 34, "sprite": "spr_gravekeeper.png",
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
			"kind": "normal", "floor": 1, "bg": "bg_vs_funeral_gallery.webp", "layout": "gallery",
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
			"kind": "normal", "floor": 1, "bg": "bg_vs_cult_prayer_room.webp", "layout": "prayer",
			"enemies": [{"id": "c1", "type": "cultist", "slot": 0}, {"id": "c3", "type": "cultist", "slot": 2}],
			"attackRange": [4, 6],
		},
		# 1층 무덤지기(기도실 안쪽, 강적) — 어둠의 영향을 받는다
		"gravekeeper": {
			"kind": "normal", "floor": 1, "bg": "bg_vs_gravekeeper_vault.webp", "layout": "vault", "darkness": true, "elite": true,
			"enemies": [{"id": "g1", "type": "gravekeeper", "slot": 1}],
			"attackRange": [6, 8],
		},
		# 1층 가장 깊은 곳(층 끝): 광신도 2 → 1명 남으면 발이 내려와 짓밟음 → 거대한 발 보스 전투
		"deep": {
			"kind": "normal", "floor": 1, "bg": "bg_vs_deepest_hall.webp", "layout": "deepest", "darkness": true, "floorEnd": true,
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
			"kind": "giant", "floor": 1, "bg": "bg_vs_deepest_hall.webp", "layout": "deepest", "darkness": true, "floorEnd": true,
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
	# 버티컬 슬라이스 배경(art/raw/vs → game/assets/bg_vs_*·cg_vs_*, tools/vs_import.py). 2·3층은 아직 옛 그림.
	#   전투가 있는 방은 전투 배경(encounters.<전투>.bg)과 같은 그림을 써서 대화하던 배경 그대로 전투가 시작되게 한다(vertical-slice.md 3장)
	"vnScenes": {
		"camp": {"bg": "bg_vs_camp.webp", "fire": true},                                    # 곁방(캠프) — 15
		"corridor": {"bg": "bg_vs_funeral_gallery.webp"},                                   # 장례 회랑 — 07 (전투 ① 배경 겸용)
		"hall": {"bg": "bg_vs_ossuary_hall.webp"},                                          # 안치 홀(지도) — 17
		"prayer": {"bg": "bg_vs_cult_prayer_room.webp"},                                    # 광신도 기도실 — 20 (전투 배경 겸용)
		"gravekeeper": {"bg": "bg_vs_gravekeeper_vault.webp"},                              # 무덤지기의 방 — 21 (강적 전투 배경 겸용)
		"buried": {"bg": "bg_vs_buried_coffin_room.webp"},                                  # 순장된 자의 방 — 22 (아이: stand_child, 43)
		"corpse": {"bg": "cg_vs_dead_witch.webp"},                                          # 핏자국 통로 끝(죽은 마녀) — 23
		"chapel": {"bg": "bg_vs_candle_chapel.webp"},                                       # 촛불 예배당 — 24
		"training": {"bg": "bg_vs_training_hall.webp"},                                     # 무너진 훈련장 — 25
		"stall": {"bg": "cg_vs_grave_merchant.webp"},                                       # 묘지기의 좌판 — 26 (묘지기는 그림 안에)
		"footprints": {"bg": "bg_vs_footprint_room.webp"},                                  # 발자국 방 — 27
		"stairs": {"bg": "bg_vs_stair_landing.webp"},                                       # 계단 앞 홀 — 18
		"deep": {"bg": "bg_vs_deepest_hall.webp"},                                          # 가장 깊은 곳 — 19 (광신도·보스 전투 겸용)
		"emptycamp": {"bg": "bg_vs_camp_empty.webp", "fire": true, "fireLow": true},        # 빈 곁방 — 16 (빈 침낭은 그림에 있다)
		# 2·3층 (탑뷰를 없애고 VN 장면 + 전투로 — 이야기·그림은 아직 시험판 v2 그대로)
		"f2corridor": {"bg": "bg_cathedral.png", "bgZoom": {"scale": 1.3, "focus": [960, 600]}},
		"f2ossuary": {"bg": "bg_ossuary.png"},
		"f2stairs": {"bg": "bg_stairs_descent.png"},
		"f3chapel": {"bg": "bg_fork_crypt.png", "bgZoom": {"scale": 1.3, "focus": [960, 500]}},
		"f3pyre": {"bg": "bg_pyre_court.png"},
	},
	# VN 대화창 (art/raw/vs/66 → ui_dialog_box.png, 9조각 — 목업 reference/mockups/vs_dialog_mock.png)
	# 상자 x·w·h(1920×1080), 9조각 모서리 여백(그림 px = 화면 px), 이름(진홍)·본문(먹색) — 양피지(평균 RGB 186,151,117) 위 대비: 본문 6.2:1, 이름 4.1:1(굵은 큰 글씨)
	"vnBox": {"img": "ui_dialog_box.png", "x": 160, "w": 1600, "h": 230, "margin": [95, 62, 95, 62], "bottom": 30,
		"nameX": 112, "nameY": 40, "textY": 84, "textRight": 112,
		"nameColor": "#78141e", "textColor": "#2b1a12", "narrColor": "#3a2a22", "innerColor": "#4a2440", "nextColor": "#78141e"},
	# VN 캠프 등에서의 스탠딩 자리(가로 위치) / 높이 / 위쪽 y
	"vn": {"slots": {"FL": 250, "L": 600, "C": 960, "R": 1320, "FR": 1670}, "standH": 1010, "standTop": 120},

	# ───────────── 죽음 카드 암시 (캠프·계단·빈 캠프) ─────────────
	# 1인칭 오른손(ui_witch_hand_raise.png)이 아래에서 올라와 반투명한 카드를 쥐고, 동료 쪽 붉은 실이 잠깐 팽팽해진다.
	# clarity: 0(누군지 알아볼 수 없음) ~ 1(또렷함) — 대본 v0.6: 캠프·계단은 또렷(카드 문구까지), 빈 캠프의 다음 카드는 0
	# 손(ui_witch_hand_raise.png)은 x,y,scale / 떠오른 카드는 cardX,cardY(왼쪽 위), cardK(배율)
	"omen": {"scale": 0.9, "x": 175, "y": 250, "cardX": 1060, "cardY": 110, "cardK": 1.4, "from": [260, 560], "rise": 900, "fade": 700, "alpha": 0.75,
		"anchors": {"hero": [0.5, 0.33], "warrior": [0.5, 0.3], "archer": [0.5, 0.3], "noel": [0.5, 0.3]}},

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
	#        spine(정해진 길) · enc(전투) · winCard(이기면 얻는 카드: rewards 의 목록 이름 — 고르는 화면 없이 1장이 강화된 채 덱에) · end(이 방이 층의 끝)
	#        (전투 승리 뒤 '카드 3장 중 1장' 보상은 2026-11-21 사용자 지시로 뺐다 — 옛 reward 키)
	# links: 이어진 방. 지나간(들어간 적 있는) 방과 이어진 방만 들어갈 수 있다. 무덤지기는 기도실 안쪽(기도실에서만)
	# [제안] 골라 들어가는 방 8개를 안치 홀·계단 앞 홀에 나눠 붙였다(문서는 "안치 홀·계단 앞 홀에 붙음"까지만 정함 — DECISIONS.md)
	"floorMaps": {
		"1": {
			"start": "hall", "end": "deep",
			"rooms": {
				"camp": {"type": "camp", "pos": [760, 98], "candle": false, "spine": true},
				"corridor": {"type": "battle", "pos": [760, 238], "candle": false, "spine": true, "enc": "normal"},
				"hall": {"type": "hub", "pos": [760, 386], "candle": false, "spine": true},
				"prayer": {"type": "battle", "pos": [440, 300], "enc": "prayer"},
				"gravekeeper": {"type": "elite", "pos": [190, 205], "enc": "gravekeeper", "winCard": "elite"},
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

	# ───────────── 세라피나 데스신 — 세 번 밟힘 (대본 v3 5.3, 그림체 D 6컷: reference/deathscene → cut_hero_c*.webp) ─────────────
	# duration: 자동 진행까지의 시간(ms). 클릭하면 바로 다음 컷. 컷의 자막(대사)은 script_data.gd "cutLines"
	"cutscene": {
		"cuts": [
			{"id": "C1", "image": "cut_hero_c1.webp", "duration": 4200, "zoom": [1.0, 1.06]},     # 돌아봄, 머리 위로 발 — "어? 잠깐, 이거—"
			{"id": "C2", "image": "cut_hero_c2.webp", "duration": 2800, "zoom": [1.04, 1.12]},    # 손을 뻗음 — "노엘, 손—"
			# C3a 첫 번째 밟힘: 컷이 바뀌는 순간 흰 섬광 → 강한 흔들림 → 화면(노엘의 눈)에 피가 튐 (impact) — 대사 없음
			{"id": "C3a", "image": "cut_hero_c3a.webp", "duration": 2600, "zoom": [1.06, 1.0], "impact": true},
			{"id": "C3b", "image": "cut_hero_c3b.webp", "duration": 4200, "zoom": [1.0, 1.05]},   # 엎드린 채 남은 손을 뻗음 — "어, 팔이… 왜… …"
			# C4 마지막 밟힘: 그림 자체를 움직인다 — 살짝 들렸다가(위로) 세게 내리찍기 + 확대 펄스 + 강한 흔들림 × slams, 마지막에 비트는 회전 흔들림 — 대사 없음
			{"id": "C4", "code": "grind", "image": "cut_hero_c4.webp", "duration": 4400, "slams": 2, "lift": 46, "twistDeg": 2.2},
			{"id": "C6", "image": "cut_hero_c6.webp", "duration": 3600, "zoom": [1.08, 1.0]},     # 발이 들린 뒤 — 대사 없음(피 웅덩이는 그림에 있다)
		],
		# C4(내리찍기)에서 피가 번지는 자리(1920×1080 기준) — 발가락 아래, 뻗은 손 둘레. C6 에서는 그림의 피 웅덩이가 있어 지운다
		"pool": {"x0": 640, "x1": 1480, "y": 950},
		"returnDelay": 600,
		"ashDuration": 1600,
		# C8 동료 반응 대사는 대본(script_data.gd "reactions")
		"reactionTremble": 2600,
		"bloodRemain": 0.6,        # C7 피 자국이 옅어진 뒤 남는 진하기
	},

	# 대사창 작은 얼굴: 기본 스탠딩 그림에서 얼굴 부분 (그림 픽셀 좌표 중심, 한 변 크기) — 그 표정 그림이 없을 때
	# 세라피나·브룬힐드·엘리안은 새 스탠딩(그림체 D, 표정별 같은 캔버스 614·646·568×1100 — tools/vs_import.py)
	# 노엘은 [임시] 39 v1(500×1100, 모자 포함 — 고친 39 가 오면 같은 이름으로 바꾸고 얼굴 자리를 다시 잰다)
	"faces": {
		"hero": {"img": "stand_hero_calm.png", "cx": 268, "cy": 80, "size": 150},
		"warrior": {"img": "stand_warrior_smirk.png", "cx": 290, "cy": 64, "size": 150},
		"archer": {"img": "stand_archer_cold.png", "cx": 282, "cy": 80, "size": 140},
		"noel": {"img": "stand_witch.png", "cx": 234, "cy": 150, "size": 130},
	},
	# 표정 그림 (대사의 face: "hero_smile" → stand_hero_smile.png — 표정마다 전신 스탠딩). 얼굴은 crop 으로 잘라 쓴다.
	# 그림이 없는 표정(warrior_rage·archer_smile·archer_hollow 등)은 스탠딩을 바꾸지 않고, 얼굴은 faces(기본 스탠딩)에서
	"expressions": {
		"file": "stand_{name}.png",
		"crop": {
			"hero": {"cx": 268, "cy": 80, "size": 150},
			"archer": {"cx": 282, "cy": 80, "size": 140},
			"warrior": {"cx": 290, "cy": 64, "size": 150},
		},
		# VN 대화창의 큰 얼굴(어깨까지 조금 더 넓게)
		"cropLarge": {
			"hero": {"cx": 268, "cy": 104, "size": 220},
			"archer": {"cx": 282, "cy": 104, "size": 210},
			"warrior": {"cx": 290, "cy": 90, "size": 220},
		},
	},
	# VN 기본 스탠딩 (표정 줄이 오면 expressions.file 의 그림으로 바꾼다 — vn.gd). child: 순장된 자의 방의 아이
	"standing": {"hero": "stand_hero_calm.png", "warrior": "stand_warrior_smirk.png", "archer": "stand_archer_cold.png", "noel": "stand_witch.png",
		"child": "stand_child.png"},

	# ───────────── 화면 배치 (1920×1080 기준 좌표) ─────────────
	"layout": {
		"W": 1920, "H": 1080,
		"bg": "bg_cathedral.png",
		# 마녀의 손 그림: 원본 1672×941. scale 배로 줄여 (x, y)에 둔다. 왼손/오른손은 ui_witch_hands.png 를 x=836에서 나눈 것
		"hand": {
			"imgL": "ui_witch_hand_left.png", "imgR": "ui_witch_hand_right.png", "splitX": 836, "imgW": 1672, "imgH": 941,
			"scale": 0.72, "x": 362, "y": 550,   # 배치 C(2026-11-21 사용자 승인): 0.9·212·370 → 손 무리 80%, 가운데 x 964 유지, 카드 윗변 약 746 (세라피나 머리·어깨가 보이게)
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
			"aimLift": 48,         # 대상 카드를 끌기 시작하면 확대를 풀고 손패 자리에서 이만큼 떠 있다가 작은 오른손(layout.grip)이 쥐어 간다
			"backs": true,         # 비는 카드 자리에는 마녀가 쥔 덱(뒷면 카드)이 보인다(손 그림이 잘려 보이지 않게)
			"dropY": 56,           # 카드를 낼 때 부채꼴 손(왼손 쪽)이 내려가는 거리
			# 카드를 낼 때 오른손이 손패에서 빠지는 동안: 손패를 왼손 쪽으로 모으는 비율(카드 자리 s → s × gather)
			"gather": 0.4,
			# 오른손이 빠질 때 함께 가져가는 덱 덮개(뒷면 카드) 자리 — 오른손 그림의 잘린 자리를 가린다
			"rightBacks": [2, 3, 4],
			"rightOut": [140, 560],   # 오른손이 빠져 내려가는 거리(x, y)
			"lockSink": 14,           # 뒤집힌 죽음 카드가 손패에서 가라앉아 보이는 깊이(px)
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
		"grip": {"scale": 0.44, "x": 608, "y": 606, "from": [0, 240]},   # 배치 C: 0.55·520·440·300 → 손 무리와 같이 80%
		# 동료 행동 자세(뒷모습). 기본 자세와 같은 배율로, 발끝(그림 아래 가운데)을 맞춰 겹친다. dx·dy: 미세 조정(화면 px)
		# 동료 행동 자세 그림 — 새 뒷모습(그림체 D)에 맞는 동작 그림은 움직임 비교 시험(vertical-slice.md 6장) 뒤에 뽑는다.
		# 그때까지는 비워 둔다(옛 동작 그림을 새 뒷모습에 겹치면 그림체가 달라 보여서). 예: "hero": {"attack": {"img": …, "dx": 30, "dy": 0}}
		"poses": {},
		"card": {"w": 240, "h": 360},
		"playZoneY": 610,        # 대상 없는 카드: 이 선보다 위에서 놓으면 사용
		# 동료 뒷모습: x(가운데), top(머리 위), h(그림 높이), anchor(붉은 실이 나오는 등 위치, 그림 비율)
		# 새 뒷모습(그림체 D) 기준 — vertical-slice.md 5-9: top 600~640, 높이 740~800, x 520·960·1420 (배경마다 battleLayouts 로 바꿀 수 있다)
		# 배치 C: 5-9 값에서 셋 모두 top −50 (손패 위로 세라피나 머리가 보이게, 줄은 고르게)
		"allies": {
			"archer": {"img": "spr_archer_back.png", "x": 520, "top": 560, "h": 790, "anchor": [0.50, 0.22]},
			"hero": {"img": "spr_hero_back.png", "x": 960, "top": 586, "h": 770, "anchor": [0.50, 0.2]},
			"warrior": {"img": "spr_warrior_back.png", "x": 1420, "top": 554, "h": 800, "anchor": [0.55, 0.2]},
		},
		"allyHpOffset": 34,
		# hpPlate: {동료: [dx, dy]} — 그 동료의 HP 판만 옮긴다(조준 화살표·피해 숫자 자리는 그대로). battleLayouts 에서 배경마다
		"hpPlate": {},
		# 적 HP 막대 자리: feet(발밑) | above(머리 위 — 예고는 그 위). 새 배치는 동료 머리가 적 발 바로 아래라 above
		"enemyHp": "feet",
		# 적: x(가운데), feet(발 y), h(그림 높이). 옛 배경(2·3층 bg_ossuary·bg_pyre_court) 기준 — 새 배경은 battleLayouts
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

	# ───────────── 전투 배치 — 배경마다 (vertical-slice.md 5-9, 목업 reference/mockups/vs_battle_mock_*.png) ─────────────
	# 전투(encounters.<전투>.layout)가 이름을 고르면 layout 의 같은 키를 덮어쓴다(사전은 한 단계 합침: giant 처럼 일부 키만 줘도 된다).
	# 배경마다 단 윗면 높이가 달라 적 발 높이(feet)를 여기 둔다. 동료 자리는 layout.allies 기본값(5-9).
	# guideBattleY: 새 배치는 적이 화면 가운데(발 y 550~680)라 안내 상자를 화면 맨 위로 (적·예고를 가리지 않게)
	"battleLayouts": {
		# 장례 회랑(07): 단 윗면 ≈ 화면 높이 50% — 목업 v3
		"gallery": {"enemySlots": [{"x": 705, "feet": 556, "h": 270}, {"x": 960, "feet": 556, "h": 270}, {"x": 1215, "feet": 556, "h": 270}],
			# 배치 C: 동료를 50 올리면 세라피나 HP 판이 가운데 광신도 발 바로 아래 단 앞 가장자리를 덮어 머리 오른쪽으로
			"enemyHp": "above", "guideBattleY": 18, "hpPlate": {"hero": [180, 55]}},
		# 광신도 기도실(20): 둥근 단 앞 가장자리 ≈ 585
		"prayer": {"enemySlots": [{"x": 700, "feet": 588, "h": 270}, {"x": 960, "feet": 588, "h": 270}, {"x": 1220, "feet": 588, "h": 270}],
			"enemyHp": "above", "guideBattleY": 18},
		# 무덤지기의 방(21): 강적 약 440 px, 발 ≈ 640 — 목업 vault
		"vault": {"enemySlots": [{"x": 700, "feet": 640, "h": 300}, {"x": 948, "feet": 642, "h": 440}, {"x": 1220, "feet": 640, "h": 300}],
			"enemyHp": "above", "guideBattleY": 18},
		# 가장 깊은 곳(19): 단 윗면이 더 낮아 발 ≈ 675 — 목업 deepest. 거대한 발은 너비 약 1100, 아랫변 ≈ 640 — 목업 foot
		"deepest": {"enemySlots": [{"x": 765, "feet": 674, "h": 268}, {"x": 960, "feet": 674, "h": 268}, {"x": 1170, "feet": 674, "h": 268}],
			"giant": {"w": 1100, "bottom": 640, "feetY": 452, "intentY": 368}, "allies": {
				"archer": {"img": "spr_archer_back.png", "x": 520, "top": 590, "h": 790, "anchor": [0.50, 0.22]},
				"hero": {"img": "spr_hero_back.png", "x": 960, "top": 614, "h": 770, "anchor": [0.50, 0.2]},
				"warrior": {"img": "spr_warrior_back.png", "x": 1420, "top": 584, "h": 800, "anchor": [0.55, 0.2]}},
			"enemyHp": "above", "guideBattleY": 18},
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
	# 버티컬 슬라이스 카드 그림(art/raw/vs 44~60 → card_art_<카드 id>.jpg, 512 — tools/vs_import.py). 다음 판은 같은 이름으로 파일만 바꾼다
	"cardArtImg": {"hero_death": "card_art_hero_death.jpg", "trample": "card_art_trample.jpg",
		"holy_slash": "card_art_holy_slash.jpg", "vanguard": "card_art_vanguard.jpg", "cover": "card_art_cover.jpg",
		"shield_bash": "card_art_shield_bash.jpg", "snipe": "card_art_snipe.jpg", "suppress": "card_art_suppress.jpg",
		"curse_flame": "card_art_curse_flame.jpg", "fate_shift": "card_art_fate_shift.jpg", "take_hit": "card_art_take_hit.jpg",
		"foresight": "card_art_foresight.jpg", "wound": "card_art_wound.jpg", "broken_sword": "card_art_broken_sword.jpg",
		"last_charge": "card_art_last_charge.jpg", "nameless_card": "card_art_nameless_card.jpg", "small_charm": "card_art_small_charm.jpg",
		"warrior_death": "card_art_warrior_death.png", "archer_death": "card_art_archer_death.png",
		"pierced_shield": "card_art_pierced_shield.png", "burnt_bow": "card_art_burnt_bow.png", "scar": "card_art_scar.png"},
	# 카드 뒷면 그림 (손패의 뒤집힌 죽음 카드·손에 쥔 덱, vs_assets.md 11). 없으면 코드로 그린 뒷면
	"cardBackImg": "card_back.png",
	# 예고 아이콘 그림 (vs_assets.md 12: 공격 · 운명 공격 · 가려짐). 없는 종류(광역·그림자·짓밟기)는 코드로 그린 아이콘
	"intentIcons": {"attack": "intent_attack.png", "fate": "intent_fate.png", "fate_pierce": "intent_fate.png", "hidden": "intent_hidden.png"},
}
