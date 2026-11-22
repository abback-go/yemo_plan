## battle_v2_data.gd — 전투 시험판 v2 「맡기기」(docs/battle-v2-spec.md)의 수치·카드·동료 특성·적·화면 배치·문구.
## 주소 ?battle=v2(헤드리스 --battle=v2)일 때만 쓴다. 지금 게임의 data/game_data.gd·script_data.gd 와 따로 둔다(옵션이 없으면 게임은 그대로).
## 수치·카드·특성·문구는 모두 [임시] — 해 보면서 고친다. 규칙: core/rules_v2.gd · 화면: scenes/board_battle.gd
## 주의: 사전 키는 모두 "문자열" 로 쓴다(코드가 문자열로 찾는다).
class_name BattleV2Data
extends Object

const D := {
	# ───────────── 규칙 (지시서 3장) ─────────────
	"rules": {
		"draw": 5,          # 내 턴마다 공용 덱에서 뽑는 장수
		"energy": 3,        # 내 턴마다 받는 행동 에너지 (남은 것은 넘어가지 않는다)
		"maxPlaced": 2,     # 동료 한 명에게 맡길 수 있는 카드(③ 줄)
		"sweepEvery": 3,    # 이 턴마다(3·6·9…) 살아 있는 광신도 하나가 찌르기 대신 휩쓸기
	},

	# ───────────── 동료와 특성 (지시서 4장, 2026-11-22 사용자 결정 — 역할) ─────────────
	# order: 화면 왼쪽 → 오른쪽 = 턴 끝에 행동하는 순서 (지시서 2장 그림: 세라피나 · 브룬힐드 · 엘리안). 노엘은 칸이 없다
	"order": ["hero", "warrior", "archer"],
	"allies": {
		"hero": {"hp": 30, "trait": "hero"},
		"warrior": {"hp": 24, "trait": "brace"},
		"archer": {"hp": 12, "trait": "aim"},
	},
	# hero(용사): 공격 카드를 맡으면 막기 attackBlock 도 얻는다 · 막기 카드를 맡으면 그 적 턴에 자기를 친 적에게 반격 counter
	# brace(버팀): 막기 × blockMult(내림) · 막아낸 피해만큼 버팀이 쌓인다(최대 max, 전투 내내 유지) — 「되돌리기」가 쓴다
	# aim(조준): 「겨누기」마다 배율 +1(×1 에서 시작, 최대 max). 엘리안의 다음 공격에 곱하고 ×1 로. 엘리안이 피해를 받으면 배율 -1
	"traits": {
		"hero": {"name": "용사", "text": "공격을 맡으면 막기 3도\n막기를 맡으면 막은 뒤 반격 3", "attackBlock": 3, "counter": 3},
		"brace": {"name": "버팀", "text": "막기 1.5배 · 막아낸 피해만큼\n버팀이 쌓인다(최대 20)", "blockMult": 1.5, "max": 20},
		"aim": {"name": "조준", "text": "겨누기마다 배율 +1(최대 ×4)\n맞으면 배율 -1", "max": 4},
	},
	# 동료 초상 카드: 스탠딩(표정마다 같은 캔버스)에서 얼굴~가슴을 잘라 쓴다. 노려지면(② 칸에 적 행동 카드가 있으면) shocked
	# crop: 그림 픽셀 [x, y, w, h] — 표정 그림이 같은 캔버스라 두 표정에 같은 자리
	"portraits": {
		"hero": {"calm": "stand_hero_calm.png", "shocked": "stand_hero_shocked.png", "crop": [113, 12, 310, 298], "color": "#cfd3dd"},
		"warrior": {"calm": "stand_warrior_smirk.png", "shocked": "stand_warrior_shocked.png", "crop": [135, 0, 310, 298], "color": "#c9a985"},
		"archer": {"calm": "stand_archer_cold.png", "shocked": "stand_archer_shocked.png", "crop": [127, 12, 310, 298], "color": "#9fc38f"},
	},

	# ───────────── 덱 (지시서 5장) ─────────────
	# owner: "" 공용(누구에게나) · 동료 id 전용(그 동료 칸에만) · "noel" 노엘(칸이 없다 — on: act ② 적 행동 카드 / enemy ① 적 / ally ④ 동료 위에 직접)
	# kind: attack(적 하나 — 놓은 뒤 적 카드를 눌러 고른다, pierce: 하수인을 넘어 본체도) | block(이 동료 막기) | release(되돌리기: 버팀만큼 피해, 버팀 0)
	#       | aim(겨누기: 배율 +1) | shift(운명 전가: ② 하나를 다른 칸으로) | bless(축복: 동료 행동 +pct%) | curse(저주: ② 하나의 피해 -minus) | vuln(취약: 적이 받는 피해 +pct%)
	# cost: 행동 에너지. text 의 {n} 은 카드 수치(손패에서는 특성 없이). 놓을 때·놓은 뒤에는 특성·버프가 붙은 결과 숫자를 따로 보여 준다
	# art: 있는 카드 그림 재사용(dark: 어둡게) — 44 성검 베기 · 52 대신 받기 · 47 방패 강타 · 49 견제 사격 · 48 저격 · 51 운명 전가 · 50 저주의 불꽃 · 53 죽음의 예지.
	#      축복은 그림이 없어 코드 도형(art "")
	"cards": {
		"slash": {"name": "베기", "owner": "", "cost": 1, "kind": "attack", "damage": 6, "text": "적 하나에게\n피해 {n}", "art": "card_art_holy_slash.jpg", "dark": true},
		"guard": {"name": "막기", "owner": "", "cost": 1, "kind": "block", "block": 5, "text": "이 동료\n막기 {n}", "art": "card_art_take_hit.jpg"},
		"holy": {"name": "성검 베기", "owner": "hero", "cost": 1, "kind": "attack", "damage": 8, "text": "적 하나에게\n피해 {n}", "art": "card_art_holy_slash.jpg"},
		"revert": {"name": "되돌리기", "owner": "warrior", "cost": 1, "kind": "release", "text": "쌓인 버팀만큼 적 하나에게\n피해 · 버팀 0", "art": "card_art_shield_bash.jpg"},
		"aim": {"name": "겨누기", "owner": "archer", "cost": 1, "kind": "aim", "text": "배율 +1\n(최대 ×4)", "art": "card_art_suppress.jpg"},
		"snipe": {"name": "저격", "owner": "archer", "cost": 1, "kind": "attack", "damage": 7, "pierce": true, "text": "적 하나에게 피해 {n} × 배율\n하수인을 넘어 본체도", "art": "card_art_snipe.jpg"},
		"shift": {"name": "운명 전가", "owner": "noel", "cost": 2, "kind": "shift", "on": "act", "text": "적 행동 하나를\n다른 칸으로 옮긴다", "art": "card_art_fate_shift.jpg"},
		"bless": {"name": "축복", "owner": "noel", "cost": 1, "kind": "bless", "on": "ally", "pct": 50, "text": "동료 하나의 이번 턴\n행동 효과 +50%", "art": ""},
		"curse": {"name": "저주", "owner": "noel", "cost": 1, "kind": "curse", "on": "act", "minus": 3, "text": "적 행동 하나의\n피해 -3", "art": "card_art_curse_flame.jpg", "dark": true},
		"vuln": {"name": "취약", "owner": "noel", "cost": 1, "kind": "vuln", "on": "enemy", "pct": 50, "text": "적 하나가 이번 턴에\n받는 피해 +50%", "art": "card_art_foresight.jpg"},
	},
	# 장수: 지시서 5장 표대로 14장(표 제목은 "덱 15장" — 표의 장수를 따랐다, DECISIONS.md)
	"deck": [["slash", 2], ["guard", 2], ["holy", 2], ["revert", 1], ["aim", 2], ["snipe", 1], ["shift", 1], ["bless", 1], ["curse", 1], ["vuln", 1]],
	"owners": {"": "공용", "hero": "세라피나", "warrior": "브룬힐드", "archer": "엘리안", "noel": "노엘"},

	# ───────────── 적 (지시서 6장 — 시험 전투: 광신도 2 + 무덤지기 강적 + 해골 병사 하수인) ─────────────
	# acts: 행동. hit = 살아 있는 동료 하나(무작위)에게 value(또는 min~max) / sweep = 모두에게 / summon = 하수인을 부른다(다음 적 턴에 자기 앞에 놓인다)
	# 무덤지기: 하수인이 없으면 summon, 있으면 hit. 하수인은 그 강적 카드 앞(아래쪽)에 겹쳐 놓이고, 그 강적을 노린 공격을 먼저 받는다
	# sprite·crop: 카드 그림(그림 픽셀 [x, y, w, h]) · face: ②·③ 카드의 작은 얼굴. 해골 병사는 그림이 없어 코드로 그린 해골(ui/icons.gd) + 이름
	"enemies": {
		"cultist": {"name": "광신도", "hp": 14, "sprite": "spr_cultist.png", "crop": [0, 0, 317, 330], "face": [96, 6, 124, 124],
			"acts": {"hit": {"label": "찌르기", "min": 5, "max": 6}, "sweep": {"label": "휩쓸기", "value": 3}}},
		"gravekeeper": {"name": "무덤지기", "hp": 30, "elite": true, "minion": "skeleton", "sprite": "spr_gravekeeper.png", "crop": [0, 0, 597, 600], "face": [214, 0, 156, 156],
			"acts": {"summon": {"label": "해골 병사 부르기"}, "hit": {"label": "삽 내려치기", "value": 8}}},
		"skeleton": {"name": "해골 병사", "hp": 8, "isMinion": true, "sprite": "",
			"acts": {"hit": {"label": "녹슨 칼", "value": 4}}},
	},
	# 시험 전투의 적 (화면 왼쪽 → 오른쪽, 이 순서로 행동). of: 이 하수인의 강적. 하수인은 처음에는 없다(강적이 부르면 나온다)
	"lineup": [
		{"id": "A", "type": "cultist", "tag": "A"},
		{"id": "G", "type": "gravekeeper"},
		{"id": "S", "type": "skeleton", "of": "G"},
		{"id": "B", "type": "cultist", "tag": "B"},
	],

	# ───────────── 화면 배치 (1920×1080, 지시서 2장 네 줄) ─────────────
	"layout": {
		"bg": "bg_vs_funeral_gallery.webp", "bgDim": 0.3,
		"cols": [420, 960, 1500], "colW": 470,     # 동료 셋의 칸(열) 가운데 x (order 순서) — ②·③·④ 줄이 같은 칸
		# ① 적 줄: 칸에 맞추지 않고 가운데로 모음. 하수인은 강적 카드 앞(아래쪽)에 겹침(dy: 강적 카드 위에서부터)
		"enemy": {"y": 8, "w": 170, "h": 216, "x": {"A": 724, "G": 960, "B": 1196}},
		"minion": {"w": 140, "h": 150, "dy": 112},
		# ② 적 행동 줄: 노리는 동료 바로 위 칸. 한 칸에 둘 이상이면 겹쳐 쌓는다(dx·dy — 칸 너비를 넘으면 dx 를 줄임, 얼굴·피해는 늘 보이게). '모두' 공격은 세 칸을 가로지르는 긴 카드(sweep 띠)
		"act": {"y": 318, "w": 226, "h": 56, "dx": 120, "dy": 10},
		"sweep": {"y": 278, "h": 36, "x0": 196, "x1": 1724},
		# ③ 내 행동 줄: 맡긴 카드(동료마다 2장, 나란히)
		"placed": {"y": 418, "w": 228, "h": 54, "gap": 10},
		# ④ 동료 줄: 초상 카드 · 옆에 버팀/배율
		"ally": {"y": 480, "w": 250, "h": 238},
		"status": {"dx": 258, "y": 520, "w": 96, "h": 74},
		"drop": {"y0": 268, "y1": 742},             # 손패 카드를 이 높이 안에서 놓으면 가까운 칸의 동료에게
		# 노엘의 손: 지금 전투의 손 그림·손패(layout.hand) 그대로(위치도 같다). 끄는 카드만 작게
		"hand": {"dragScale": 0.55},
		"deck": {"x": 196, "y": 880, "w": 96, "h": 144},
		"energy": {"x": 1596, "y": 872},
		"endTurn": {"x": 1626, "y": 986},
		"rowLabels": {"x": 18, "act": 330, "placed": 432},
		"slab": [[600, 2, 720, 274], [160, 272, 1600, 456]],               # 카드가 놓이는 돌판(코드로 그린 어두운 판) [x, y, w, h]
	},

	# ───────────── 화면 문구 ─────────────
	"text": {
		"endTurn": "턴 끝", "energy": "행동 에너지", "deck": "덱 {n}", "turn": "{n}턴", "enemyTurn": "적 턴",
		"hint": "카드를 동료 칸에 끌어 놓는다 — 노엘의 카드는 적 행동·적·동료 위에\n놓은 카드를 누르면 손패로 돌아온다",
		"rowAct": "적 행동", "rowPlaced": "맡긴 카드",
		"pickEnemy": "공격할 적을 누르세요 · 빈 곳: 취소",
		"shiftTo": "옮길 칸을 누르거나 그 칸으로 끄세요 · 빈 곳: 취소",
		"dropAct": "적 행동 카드 위에 놓는다", "dropEnemy": "적 위에 놓는다", "dropAlly": "동료 위에 놓는다", "dropCol": "{name} 칸에 놓는다",
		"all": "모두", "summonNext": "다음 적 턴에 나온다",
		"down": "쓰러짐", "block": "막기 {n}", "blocked": "막음 {n}", "counter": "반격 {n}", "damage": "피해 {n}", "multTo": "배율 ×{n}",
		"brace": "버팀", "mult": "배율", "noEffect": "—",
		"tagBless": "축복 +50%", "tagCurse": "저주 -3", "tagVuln": "취약 +50%", "tagShift": "운명 전가",
		"summoned": "{name} 등장", "reshuffle": "버린 카드를 섞어 덱으로",
		"win": "승리", "lose": "패배", "winText": "적이 모두 쓰러졌다 · {n}턴", "loseText": "동료가 모두 쓰러졌다 · {n}턴",
		"again": "다시 하기",
	},
	# 놓을 수 없을 때 짧은 알림 (rules_v2.gd 의 이유 → 문구)
	"reasons": {
		"over": "전투가 끝났다", "notInHand": "손패에 없는 카드", "noAlly": "동료 칸에 놓아야 한다", "down": "쓰러진 동료의 칸에는 놓을 수 없다",
		"full": "한 동료에게는 2장까지", "noEnergy": "행동 에너지가 모자란다", "noEnemy": "공격할 적이 없다", "notOwner": "그 동료의 카드가 아니다",
		"noelCard": "노엘의 카드는 적 행동·적·동료 위에 놓는다", "notNoel": "동료 칸에 놓는 카드", "badAct": "옮기거나 줄일 수 있는 적 행동이 아니다",
		"badEnemy": "적 위에 놓아야 한다", "badAlly": "동료 위에 놓아야 한다", "already": "이미 걸려 있다", "noDest": "옮길 칸이 없다",
		"needTarget": "공격할 적을 골라야 한다", "badMove": "그 칸으로는 옮길 수 없다", "movedAgain": "나중에 옮긴 카드를 먼저 되돌린다",
		"noPlaced": "놓은 카드가 없다",
	},
}
