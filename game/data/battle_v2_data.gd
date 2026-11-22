## battle_v2_data.gd — 전투 시험판 v2.1 「3D 탁자」(docs/battle-v2-spec.md 1~6장 v2 + 8·9장 v2.1)의 수치·카드·동료 특성·적·화면 배치·문구.
## 주소 ?battle=v2(헤드리스 --battle=v2)일 때만 쓴다. 지금 게임의 data/game_data.gd·script_data.gd 와 따로 둔다(옵션이 없으면 게임은 그대로).
## 수치·카드·특성·문구는 모두 [임시] — 해 보면서 고친다. 규칙: core/rules_v2.gd · 화면: scenes/board_battle.gd(2D) + ui/board_table.gd(3D 탁자)
## 주의: 사전 키는 모두 "문자열" 로 쓴다(코드가 문자열로 찾는다).
class_name BattleV2Data
extends Object

const D := {
	# ───────────── 규칙 (지시서 3장 · 9-2) ─────────────
	"rules": {
		"draw": 5,          # 내 턴마다 공용 덱에서 뽑는 장수
		"energy": 3,        # 내 턴마다 받는 행동 에너지 (남은 것은 넘어가지 않는다)
		"maxPlaced": 0,     # 동료 한 명에게 맡길 수 있는 카드(③ 줄). 0 = 제한 없음(v2.2 — 에너지가 허락하는 만큼)
		"sweepEvery": 3,    # 이 턴마다(3·6·9…) 살아 있는 광신도 하나가 찌르기 대신 휩쓸기
		"noelHp": 15,       # v2.1: 빈칸 공격은 노엘이 맞는다(막기 없음). 0 이면 패배
		"moveCost": 1,      # v2.1: 전투 중 자리 바꾸기·빼기·넣기 한 번에 드는 행동 에너지 (출전 배치 화면에서는 공짜)
		"cols": 3,          # 칸(열) 수
	},

	# ───────────── 동료와 특성 (지시서 4장, 2026-11-22 사용자 결정 — 역할) ─────────────
	# order: 동료 목록(결과 판·시험의 순서). formation: 출전 배치 기본값 — 칸 0·1·2 (왼쪽 → 오른쪽 = 턴 끝에 행동하는 순서). 노엘은 칸이 없다
	"order": ["hero", "warrior", "archer"],
	"formation": ["hero", "warrior", "archer"],
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
	# 동료 초상 카드(v2.1): 그림체 F 스탠딩에서 얼굴~가슴을 잘라 둔 그림(tools/vs_f_import.py → f_bust_*.png). 놀란 표정 그림은 아직 없어
	# 노려지면 붉은 테두리·흔들림으로 대신한다(지시서 9-1)
	# 카드 뒷면(밤샘 계획 2 D — 그림체 F 82, tools/vs_f_import.py --only back): 덱 · 적 덱 · 뒤집힌 카드(쓰러진 적 · 적 덱에서 나오는 행동 카드) · 어둠의 뒷면.
	# 후보 가운데 파일이 있는 것(없으면 옛 전투의 뒷면 card_back.png). 옛 전투(?battle=v1)는 그대로 card_back.png
	"cardBack": ["f_card_back.png", "card_back.png"],
	"portraits": {
		"hero": {"img": "f_bust_hero.png", "color": "#cfd3dd"},
		"warrior": {"img": "f_bust_warrior.png", "color": "#c9a985"},
		"archer": {"img": "f_bust_archer.png", "color": "#9fc38f"},
	},

	# ───────────── 덱 (지시서 5장 · 9-2) ─────────────
	# owner: "" 공용(누구에게나) · 동료 id 전용(그 동료 칸에만) · "noel" 노엘(칸이 없다 — on: act ② 적 행동 카드 / enemy ① 적 / ally ④ 동료 위에 직접)
	# kind: attack(적 하나 — 놓은 뒤 적 카드를 눌러 고른다, pierce: 하수인을 넘어 본체도) | block(이 동료 막기) | release(되돌리기: 버팀만큼 피해, 버팀 0)
	#       | aim(겨누기: 배율 +1) | shift(운명 전가: ② 하나를 다른 칸으로) | bless(축복: 동료 행동 +pct%) | curse(저주: ② 하나의 피해 -minus) | vuln(취약: 적이 받는 피해 +pct%)
	#       | tear(운명 찢기 v2.1: 죽음 카드 하나를 없앤다)
	# cost: 행동 에너지. text 의 {n} 은 카드 수치(손패에서는 특성 없이). 놓을 때·놓은 뒤에는 특성·버프가 붙은 결과 숫자를 따로 보여 준다
	# art: 있는 카드 그림 재사용(dark: 어둡게, 2026-11-22 사용자 결정 — 행동 카드 그림은 당분간 예전 그림체 D 카드 그림) — 44 성검 베기 · 52 대신 받기 · 47 방패 강타 ·
	#      49 견제 사격 · 48 저격 · 51 운명 전가 · 50 저주의 불꽃 · 53 죽음의 예지 · 58 이름 없는 마녀의 카드(운명 찢기). 축복은 그림이 없어 코드 도형(art "")
	"cards": {
		"slash": {"name": "베기", "owner": "", "cost": 1, "kind": "attack", "damage": 6, "text": "적 하나에게\n피해 {n}", "art": "card_art_holy_slash.jpg", "dark": true},
		"guard": {"name": "막기", "owner": "", "cost": 1, "kind": "block", "block": 5, "text": "이 동료\n막기 {n}", "art": "card_art_take_hit.jpg"},
		"holy": {"name": "성검 베기", "owner": "hero", "cost": 1, "kind": "attack", "damage": 8, "text": "적 하나에게\n피해 {n}", "art": "card_art_holy_slash.jpg"},
		"revert": {"name": "되돌리기", "owner": "warrior", "cost": 1, "kind": "release", "text": "쌓인 버팀만큼\n적 하나에게 피해", "art": "card_art_shield_bash.jpg"},
		"aim": {"name": "겨누기", "owner": "archer", "cost": 1, "kind": "aim", "text": "배율 +1\n(최대 ×4)", "art": "card_art_suppress.jpg"},
		"snipe": {"name": "저격", "owner": "archer", "cost": 1, "kind": "attack", "damage": 7, "pierce": true, "text": "피해 {n} × 배율\n하수인을 넘어 본체도", "art": "card_art_snipe.jpg"},
		"shift": {"name": "운명 전가", "owner": "noel", "cost": 2, "kind": "shift", "on": "act", "text": "적 행동 하나를\n다른 칸으로 옮긴다", "art": "card_art_fate_shift.jpg"},
		"bless": {"name": "축복", "owner": "noel", "cost": 1, "kind": "bless", "on": "ally", "pct": 50, "text": "동료 하나의 이번 턴\n행동 효과 +50%", "art": ""},
		"curse": {"name": "저주", "owner": "noel", "cost": 1, "kind": "curse", "on": "act", "minus": 3, "text": "적 행동 하나의\n피해 -{n}", "art": "card_art_curse_flame.jpg", "dark": true},
		"vuln": {"name": "취약", "owner": "noel", "cost": 1, "kind": "vuln", "on": "enemy", "pct": 50, "text": "적 하나가 이번 턴에\n받는 피해 +50%", "art": "card_art_foresight.jpg"},
		"tear": {"name": "운명 찢기", "owner": "noel", "cost": 3, "kind": "tear", "on": "act", "text": "죽음 카드 하나를\n없앤다", "art": "card_art_nameless_card.jpg"},
		# ── 게임(1층)에서 덱에 들어오는 카드 (밤샘 계획 2 A·B — 옛 카드를 이 규칙으로 옮김, 수치 [임시]) ──
		# unplayable: 낼 수 없다(손패만 차지) · noelCost: 그 카드가 처리될 때 노엘 HP 가 준다 · exhaust: 전투마다 한 번(낸 뒤 이 전투에서 사라짐)
		# kind stomp(짓밟힘: 모든 적에게 피해 — 턴 끝에 동료보다 먼저) · erase(적 행동 하나를 없앤다 — 죽음 카드는 못 없앰) · heal(동료 HP 회복 — 턴 끝에)
		"wound": {"name": "상처", "owner": "", "cost": 0, "kind": "wound", "unplayable": true, "text": "낼 수 없다\n손패만 차지한다", "art": "card_art_wound.jpg", "dark": true},
		"relic_sword": {"name": "부러진 성검", "owner": "", "cost": 1, "kind": "attack", "damage": 12, "noelCost": 2, "relic": true,
			"text": "적 하나에게 피해 {n}\n낼 때마다 노엘 HP -2", "art": "card_art_broken_sword.jpg"},
		"trample": {"name": "짓밟힘", "owner": "noel", "cost": 2, "kind": "stomp", "on": "enemy", "damage": 9, "text": "모든 적에게\n피해 {n}", "art": "card_art_trample.jpg"},
		"nameless": {"name": "이름 없는 마녀의 카드", "owner": "noel", "cost": 0, "kind": "erase", "on": "act", "noelCost": 3, "exhaust": true,
			"text": "적 행동 하나를 없앤다\n노엘 HP -3 · 전투마다 한 번", "art": "card_art_nameless_card.jpg"},
		"charm": {"name": "작은 손의 부적", "owner": "noel", "cost": 1, "kind": "heal", "on": "ally", "heal": 4, "text": "동료 하나\nHP {n} 회복", "art": "card_art_small_charm.jpg"},
	},
	# Lv2(무덤지기를 이기고 얻는 카드 · 무너진 훈련장 강화) [임시]: 바뀌는 값 · 훈련 화면의 요약. 이름 뒤에 「Lv2」
	"up": {
		"holy": {"damage": 11, "summary": "피해 8 → 11"},
		"snipe": {"damage": 10, "summary": "피해 7 → 10"},
		"guard": {"block": 7, "summary": "막기 5 → 7"},
		"curse": {"minus": 5, "summary": "피해 -3 → -5"},
		"slash": {"damage": 8, "summary": "피해 6 → 8"},
	},
	# 장수: 지시서 5장 표 14장 + 9-2 「운명 찢기」 1장 = 15장
	"deck": [["slash", 2], ["guard", 2], ["holy", 2], ["revert", 1], ["aim", 2], ["snipe", 1], ["shift", 1], ["bless", 1], ["curse", 1], ["vuln", 1], ["tear", 1]],
	"owners": {"": "공용", "hero": "세라피나", "warrior": "브룬힐드", "archer": "엘리안", "noel": "노엘"},

	# ───────────── 게임 연결 (밤샘 계획 2 A — 1층 전투 네 곳을 이 규칙으로) ─────────────
	# gameDeck: 게임(기본 흐름)의 시작 덱 = 시험판 덱에서 「운명 찢기」를 뺀 14장 [임시·판단 — 1층의 죽음 카드(거대한 발)는 찢을 수 없어 쓸 데가 없다]
	#   이 덱은 st.party.deck2([{id, lv}])로 전투 사이에 이어진다(상처·유품·방에서 얻은 카드·강화). 옛 덱 st.party.deck 은 옛 규칙(2·3층·?battle=v1)이 그대로 쓴다
	"gameDeck": [["slash", 2], ["guard", 2], ["holy", 2], ["revert", 1], ["aim", 2], ["snipe", 1], ["shift", 1], ["bless", 1], ["curse", 1], ["vuln", 1]],
	# 옛 카드 → 이 규칙의 카드: 지도의 방(좌판·순장된 자의 방·핏자국 통로 끝·무덤지기·훈련장)은 옛 카드 id 로 정하고, deck2 에는 짝 카드가 들어간다
	"fromV1": {"holy_slash": "holy", "vanguard": "slash", "cover": "guard", "take_hit": "guard", "shield_bash": "revert", "snipe": "snipe", "suppress": "aim",
		"fate_shift": "shift", "curse_flame": "curse", "foresight": "vuln", "nameless_card": "nameless", "small_charm": "charm", "trample": "trample",
		"wound": "wound", "broken_sword": "relic_sword", "last_charge": "relic_sword"},
	# 동료가 죽으면 그 동료의 전용 카드가 유품으로(옛 relicMap 과 같은 규칙 — 더 강하지만 낼 때마다 노엘 HP 가 준다). 상처는 그대로
	"relicMap": {"holy": "relic_sword"},
	# 동료가 죽음 카드에 맞으면 나오는 데스신(scenes.gd cutscene 의 key). 없으면 짧은 「죽음」 뒤집기만
	"deathScenes": {"hero": "hero", "warrior": "warrior_pierce", "archer": "archer_burn"},

	# ───────────── 전투 구성 (encounters) ─────────────
	# test: 시험 전투(?battle=v2) — 아래 lineup·death 그대로. 그 밖은 1층(게임 기본 흐름) — 옛 encounters(game_data.gd)의 적 수·HP·공격 범위를 옮김 [임시]
	# lineup: 적(왼쪽 → 오른쪽 = 행동 순서, col = ① 줄의 칸, hp 가 있으면 그 값) · hit: 종류별 한 명 공격 피해(min~max 또는 value) · sweepEvery: 이 턴마다 광신도 하나 휩쓸기(0 = 없음)
	# script: {턴: {적 id: {value, slot}}} 그 턴의 적 행동(튜토리얼 — 매번 같은 흐름) · hands: {턴: [카드 id…]} 그 턴에 먼저 뽑는 카드
	# pattern: {종류: [{label, value, target: random|highest}]} 강적이 하수인이 있을 때 차례로 하는 공격(highest = HP 가 가장 많은 동료의 칸)
	# giantAt: 살아 있는 적이 이 수만큼 남으면 발이 내려와 짓밟는다(남은 적이 사라지고 거대한 발 전투로 — 옛 giantTriggerAlive)
	# turns: 거대한 발의 턴별 행동(마지막이 되풀이) — none(행동 없음) · sweep(모두) · death(그 동료의 죽음 카드. fixed: 옮길 수 없음·찢을 수 없음·벤치에 있어도 따라가 맞는다)
	# noLose: 지지 않는다(동료가 모두 쓰러져도, 노엘 HP 는 1 아래로 안 감) · deathEnds: 죽음 카드가 처리되면 전투가 끝나는 결과
	# bg: 탁자 너머(어둡게)에 까는 그 방의 VN 배경 · v1: 옛 전투 id(어둠 단계 — MapRules.darkness_level)
	"encounters": {
		"test": {"bg": "", "sweepEvery": 3, "death": true},
		"normal": {"bg": "bg_vs_funeral_gallery.webp", "v1": "normal",
			"lineup": [{"id": "c1", "type": "cultist", "tag": "A", "col": 0}, {"id": "c2", "type": "cultist", "tag": "B", "col": 1}, {"id": "c3", "type": "cultist", "tag": "C", "col": 2}],
			"hit": {"cultist": {"min": 5, "max": 6}},
			"script": {"1": {"c1": {"value": 5, "slot": 1}, "c2": {"value": 6, "slot": 0}, "c3": {"value": 5, "slot": 2}},
				"2": {"c1": {"value": 6, "slot": 2}, "c2": {"value": 6, "slot": 2}, "c3": {"value": 6, "slot": 2}}},
			"hands": {"1": ["holy", "guard", "slash", "aim", "snipe"], "2": ["shift", "guard", "holy", "slash", "bless"]}},
		"prayer": {"bg": "bg_vs_cult_prayer_room.webp", "v1": "prayer",
			"lineup": [{"id": "c1", "type": "cultist", "tag": "A", "col": 0}, {"id": "c3", "type": "cultist", "tag": "B", "col": 2}],
			"hit": {"cultist": {"min": 4, "max": 6}}},
		# 무덤지기(강적): 밤샘 계획 2 D2 난이도 [임시·판단] — 옛 수치 HP 34 · 해골 병사 8/녹슨 칼 4 · 짓누르기 10 → 40 · 10/5 · 12 (DECISIONS.md 「D2」 전후 표)
		"gravekeeper": {"bg": "bg_vs_gravekeeper_vault.webp", "v1": "gravekeeper",
			"lineup": [{"id": "G", "type": "gravekeeper", "col": 1, "hp": 40}, {"id": "S", "type": "skeleton", "of": "G", "col": 1, "hp": 10}],
			"hit": {"skeleton": {"value": 5}},
			"pattern": {"gravekeeper": [{"label": "관 뚜껑 내려치기", "value": 8, "target": "random"}, {"label": "짓누르기", "value": 12, "target": "highest"}]}},
		"deep": {"bg": "bg_vs_deepest_hall.webp", "v1": "deep", "giantAt": 1,
			"lineup": [{"id": "c1", "type": "cultist", "tag": "A", "col": 0}, {"id": "c3", "type": "cultist", "tag": "B", "col": 2}],
			"hit": {"cultist": {"min": 5, "max": 6}},
			"script": {"1": {"c1": {"value": 6, "slot": 2}, "c3": {"value": 5, "slot": 1}}}},
		"giant": {"bg": "bg_vs_deepest_hall.webp", "v1": "giant", "noLose": true, "deathEnds": "retreat",
			"lineup": [{"id": "giant", "type": "giant", "col": 1}],
			"turns": [{"kind": "none"}, {"kind": "sweep", "value": 5}, {"kind": "death", "ally": "hero", "fixed": true}]},
	},

	# ───────────── 적 (지시서 6장 — 시험 전투: 광신도 2 + 무덤지기 강적 + 해골 병사 하수인) ─────────────
	# acts: 행동. hit = 칸 하나(무작위 — v2.1 부터 빈칸도 노린다)에 value(또는 min~max) / sweep = 모든 칸에 / summon = 하수인을 부른다(다음 적 턴에 자기 앞에 놓인다)
	# 무덤지기: 하수인이 없으면 summon, 있으면 hit. 하수인은 그 강적 카드 앞에 겹쳐 놓이고, 그 강적을 노린 공격을 먼저 받는다
	# art: 카드 그림 후보(앞에서부터 파일이 있는 것) — crop: 카드 그림 창, face: ②·③ 카드의 작은 얼굴 (그림 크기에 대한 비율 [x, y, w, h])
	#      그림체 F(f_spr_*, tools/vs_f_import.py)가 있으면 그것, 없으면 예전 그림. 해골 병사는 그림이 없으면 코드로 그린 해골(ui/icons.gd)
	"enemies": {
		"cultist": {"name": "광신도", "hp": 14,
			"art": [{"file": "f_spr_cultist.png", "crop": [0.0, 0.0, 1.0, 0.6], "face": [0.3, 0.02, 0.4, 0.18]},
				{"file": "spr_cultist.png", "crop": [0.0, 0.0, 1.0, 0.52], "face": [0.3, 0.01, 0.39, 0.19]}],
			"acts": {"hit": {"label": "찌르기", "min": 5, "max": 6}, "sweep": {"label": "휩쓸기", "value": 3}}},
		"gravekeeper": {"name": "무덤지기", "hp": 30, "elite": true, "minion": "skeleton",
			"art": [{"file": "f_spr_gravekeeper.png", "crop": [0.05, 0.0, 0.9, 0.7], "face": [0.37, 0.0, 0.28, 0.15]},
				{"file": "spr_gravekeeper.png", "crop": [0.0, 0.0, 1.0, 0.667], "face": [0.36, 0.0, 0.26, 0.173]}],
			"acts": {"summon": {"label": "해골 병사 부르기"}, "hit": {"label": "삽 내려치기", "value": 8}}},
		# 거대한 발(1층 끝, 대본 v3 5.2): 세 칸을 덮는 큰 카드(wide — 모든 칸의 앞 적). HP 「???」, 공격은 흠집만(immune). 행동은 encounters.giant.turns
		"giant": {"name": "거대한 발", "hp": 0, "immune": true, "wide": true,
			"art": [{"file": "spr_giant_foot.png", "crop": [0.0, 0.5, 1.0, 0.36], "face": [0.25, 0.3, 0.5, 0.36]}],
			"acts": {"none": {"label": "그림자", "sub": "행동 없음"}, "sweep": {"label": "기둥 붕괴"}, "death": {"label": "짓밟기"}}},
		"skeleton": {"name": "해골 병사", "hp": 8, "isMinion": true,
			"art": [{"file": "f_spr_skeleton.png", "crop": [0.0, 0.0, 1.0, 0.62], "face": [0.32, 0.0, 0.33, 0.17]}],
			"acts": {"hit": {"label": "녹슨 칼", "value": 4}}},
	},
	# 시험 전투의 적 (화면 왼쪽 → 오른쪽, 이 순서로 행동). of: 이 하수인의 강적. 하수인은 처음에는 없다(강적이 부르면 나온다)
	# col: ① 적 줄에서 놓이는 칸(v2.1 — 같은 크기 카드 3열). 하수인은 강적과 같은 칸에 겹친다
	"lineup": [
		{"id": "A", "type": "cultist", "tag": "A", "col": 0},
		{"id": "G", "type": "gravekeeper", "col": 1},
		{"id": "S", "type": "skeleton", "of": "G", "col": 1},
		{"id": "B", "type": "cultist", "tag": "B", "col": 2},
	],

	# ───────────── 적의 죽음 카드 (지시서 9-2, v2.1) ─────────────
	# enemy 의 at 번째 행동으로 ally 의 「○○의 죽음」을 그 동료 칸 ② 에 낸다. 막기·저주로 줄지 않는다. 적 턴에 그 동료가 칸에 있으면 죽는다(이 전투에서 돌아오지 않음).
	# 그 동료가 벤치에 있으면 처리되지 않고 기다린다(그 뒤로는 그 동료를 따라간다 — 낸 적이 쓰러져도 남음). 전투가 끝날 때까지 남으면 결과 판에 「운명이 미뤄졌다」
	"death": {"enemy": "gravekeeper", "at": 3, "ally": "hero", "label": "{name}의 죽음",
		"art": {"hero": "card_art_hero_death.jpg", "warrior": "card_art_warrior_death.png", "archer": "card_art_archer_death.png"}},

	# ───────────── 2D 화면 (1920×1080 위에 겹침) ─────────────
	"layout": {
		# 노엘의 손(지시서 9-4 사용자 결정): 왼손은 왼쪽 아래에 펴고(그림은 손패 뒤) 그 위로 손패가 부채꼴로 떠서 흔들린다. 오른손은 오른쪽 아래(평소)·끄는 카드를 집음·가리킴.
		# 그림 후보는 앞에서부터 파일이 있는 것 — 그림체 F(78·79·80) → 없으면 지금 손 그림. pos: 그림 왼위(화면) · tips: 붉은 실이 나오는 손끝(그림 px) ·
		# tip: 오른손 손끝(그림 px) · rest: 평소 손끝 자리(화면) · pinch.quad: 세운 손 그림의 카드 자리(그림 px, cardScale 일 때 끄는 카드 크기에 맞춘 scale)
		"hands": {
			"left": [
				{"file": "f_hand_left_hold.png", "scale": 0.62, "pos": [-30, 872], "tips": [[652, 171], [751, 253], [790, 321]]},
				{"file": "ui_witch_hand_left_clean.png", "scale": 0.55, "pos": [-80, 700], "tips": [[716, 493], [763, 599]]},
			],
			"right": [
				{"file": "f_hand_right_idle.png", "scale": 0.6, "tip": [316, 536], "rest": [1470, 975]},
				{"file": "ui_witch_hand_right_clean.png", "scale": 0.55, "tip": [62, 600], "rest": [1520, 960]},
			],
			# 오른손 가리키기(그림체 F 81, 밤샘 계획 2 D): 탁자 카드를 끌 때(자리 바꾸기 · 운명 전가로 옮기기) 평소 손 대신 이 그림이 그 자리를 가리킨다.
			# tip: 집게손가락 끝(그림 px — f_hand_right_point.png 1152×768). 없으면 평소 손(right)이 그대로 옮겨 가리킨다
			"point": [
				{"file": "f_hand_right_point.png", "scale": 0.6, "tip": [502, 146]},
			],
			"pinch": [
				{"file": "f_hand_right_pinch.png", "scale": 0.41, "cardScale": 0.55, "quad": [[866, 64], [1186, 32], [1221, 480], [914, 507]]},
				{"file": "ui_witch_hand_raise.png", "scale": 0.41, "cardScale": 0.55, "quad": [[866, 64], [1186, 32], [1221, 480], [914, 507]]},
			],
			# 손패 부채꼴: 카드 가운데 = pivot + r·(sin a, −cos a), a = center ± step(장수가 많으면 maxSpread 안으로 좁힘) · scale: 카드 배율 · sway: 흔들림(px)
			# v2.2: 손패를 0.56 → 0.78 배로 키우고(읽을 수 있게) 왼쪽 아래에 맞춤. 마우스를 올리면 hoverScale(카드 240×360 기준)로 크게
			"fan": {"pivot": [290, 1660], "r": 780, "center": -0.05, "step": 0.1, "maxSpread": 0.44, "scale": 0.78, "sway": 6},
			"hoverScale": 1.25, "dragScale": 0.62,
			# v2.4 손패 당겨 보기(9-5 바꿈): 손패를 탭(PC 는 마우스를 올려도)하면 왼손 대신 예전 전투의 두 손(GameData layout.hand 의 imgL·imgR·splitX·slots 그대로)이
			# 가운데 아래로 올라와 카드를 예전 부채꼴·엄지 겹침으로 쥔다. scale: 손 그림 배율(예전 0.72 → 키움, 가운데 카드 높이 약 380) · x,y: 합친 그림의 왼위(화면, 가운데 x 964 · 손목 아래 초록 물듦은 화면 밖으로) ·
			# rise: 올라오는 거리 · dim: 탁자 어둡게(검은 반투명) · lift: 마우스를 올린 카드가 뜨는 높이
			"open": {"scale": 1.18, "x": -22, "y": 110, "rise": 420, "dim": 0.62, "lift": 26},
		},
		"deck": {"x": 586, "y": 900, "w": 84, "h": 126},
		"noel": {"x": 772, "y": 978},           # 노엘 HP 봉인(가운데)
		"energy": {"x": 890, "y": 902},
		"endTurn": {"x": 1166, "y": 950},
		"start": {"x": 1166, "y": 950},          # 출전 배치 화면의 「출전」
		"zoom": {"w": 300, "y": 150, "margin": 40},  # 크게 보기(카드 240×360 기준 배율 300/240)
	},

	# ───────────── 3D 탁자 (ui/board_table.gd, 지시서 9-1) ─────────────
	# 단위: 카드 가로 1. 탁자 평면 y=0, x 오른쪽, z 앞(카메라 쪽). 카메라는 pitch 도로 내려다보고, 격자 맨 뒤 끝·맨 앞 끝이 화면 fitY 에 오도록 거리·위치를 계산한다
	"table3d": {
		"pitch": 50.0,                 # 카메라가 내려다보는 각도(도). 사용자 미정(55° · 40° 비교 중) — 이 값 하나만 바꾸면 된다
		"fov": 32.0,                   # 세로 시야각(도)
		"fitY": [34, 772],             # 격자(① 맨 뒤 끝 · ④ 맨 앞 끝)가 들어갈 화면 y (1080 기준) — 아래는 노엘의 손 (v2.2: 커진 손패가 동료 줄을 가리지 않게 852 → 772)
		"card": [1.0, 1.5],            # 카드 크기(2:3 — 손패 카드와 같은 비율)
		"cols": [-2.35, 0.0, 2.35], "cellW": 2.05,
		"fitX": [12, 1908],            # 격자·벤치·적 덱이 들어갈 화면 x — 넘치면 카메라를 물린다(낮은 각도에서)
		"rows": [-2.43, -0.81, 0.81, 2.43],   # ① 적 · ② 적 행동 · ③ 맡긴 카드 · ④ 동료 (z)
		"pileDx": 0.4,                 # 한 칸에 여러 장: 옆으로 이만큼씩 밀어 겹친다(A안) — 칸 너비를 넘으면 좁힌다
		"spreadDx": 1.04,              # 마우스를 올리거나 누르면 이 간격으로 펼친다
		"bench": {"x": 4.0, "z": 1.85, "dz": -0.6},    # 오른쪽 아래: 대기 동료(벤치, 지시서 9-4) — 맨 앞 카드 자리, 다음 카드는 dz 만큼 뒤로
		"enemyDeck": {"x": 4.0, "z": -2.43},          # 오른쪽 위: 적 덱(행동 카드가 여기서 나온다)
		"note": {"x": 4.0, "z": -0.81},               # 오른쪽 위: 설명 카드
		"table": {"img": "bg_f_battle_table.webp", "w": 14.6},
		"lift": 0.55,                  # 집은 카드가 들리는 높이
		"faceScale": 1.25,             # 탁자 카드 앞면 해상도(240×360 의 배)
	},

	# ───────────── 화면 문구 ─────────────
	"text": {
		"endTurn": "턴 끝", "energy": "행동 에너지", "deck": "덱 {n}", "turn": "{n}턴", "enemyTurn": "적 턴",
		"hint": "카드를 동료 칸에 끌어 놓는다 — 노엘의 카드는 적 행동·적·동료 위에\n동료 카드를 끌면 자리 바꾸기·빼기·넣기(에너지 1)",
		"hintTouch": "카드를 동료 칸에 끌어 놓는다 · 길게 누르면 크게 보기\n동료 카드를 끌면 자리 바꾸기·빼기·넣기(에너지 1)",
		"formation": "출전 배치", "formationHint": "동료 카드를 끌어 칸이나 왼쪽 대기로 옮긴다 · 빈칸을 노린 공격은 노엘이 맞는다",
		"start": "출전", "bench": "대기", "enemyDeck": "적 덱", "emptySlot": "빈칸\n노엘이 맞는다",
		"note": "적 행동 카드는\n노리는 칸 위에 놓인다\n\n빈칸이면\n노엘이 맞는다\n\n죽음 카드는\n막을 수 없다",
		"noel": "노엘", "total": "합계 {n}", "toNoel": "노엘", "moved": "자리 이동 · 에너지 {n}",
		"pickEnemy": "공격할 적을 누르세요 · 빈 곳: 취소",
		"shiftTo": "옮길 칸을 누르거나 그 칸으로 끄세요 · 빈 곳: 취소",
		"dropAct": "적 행동 카드 위에 놓는다", "dropEnemy": "적 위에 놓는다", "dropAlly": "동료 위에 놓는다", "dropDeath": "죽음 카드 위에 놓는다",
		"all": "모두", "summonNext": "다음 적 턴에 나온다",
		"down": "쓰러짐", "dead": "죽음", "block": "막기 {n}", "blocked": "막음 {n}", "counter": "반격 {n}", "damage": "피해 {n}", "multTo": "배율 ×{n}",
		"brace": "버팀", "mult": "배율", "noEffect": "—", "deathMark": "막을 수 없다",
		"tagBless": "축복 +50%", "tagCurse": "저주 -{n}", "tagVuln": "취약 +50%", "tagShift": "운명 전가", "tagTear": "운명 찢기",
		"tagErase": "적 행동을 없앤다", "tagStomp": "모든 적에게 {n}", "tagHeal": "HP +{n}",
		# 게임 연결(1층): 죽음 카드 고정 · 거대한 발 · 어둠(뒷면) · 결과 판 「계속」
		"deathFixed": "옮길 수 없음\n찢을 수 없음", "immune": "흠집", "unknownHp": "???", "hiddenValue": "?", "erased": "없앴다",
		"heal": "HP +{n}", "noelPay": "노엘 -{n}", "continue": "계속", "giantCome": "발이 내려온다", "retreat": "물러났다",
		"gained": "{list} — 덱에 들어왔다",
		"summoned": "{name} 등장", "reshuffle": "버린 카드를 섞어 덱으로",
		"deathWait": "{name} 대기 중 — 죽음 카드가 기다린다", "deathGone": "죽음 카드가 사라졌다", "died": "{name}의 죽음",
		"win": "승리", "lose": "패배", "winText": "적이 모두 쓰러졌다 · {n}턴", "loseText": "동료가 모두 쓰러졌다 · {n}턴", "loseNoel": "노엘이 쓰러졌다 · {n}턴",
		"postponed": "운명이 미뤄졌다 — {list}", "bench_state": "대기",
		"again": "다시 하기",
	},
	# 놓을 수 없을 때 짧은 알림 (rules_v2.gd 의 이유 → 문구)
	"reasons": {
		"over": "전투가 끝났다", "notInHand": "손패에 없는 카드", "noAlly": "동료 칸에 놓아야 한다", "down": "쓰러진 동료에게는 맡길 수 없다",
		"full": "그 동료 칸이 가득 찼다", "noEnergy": "행동 에너지가 모자란다", "noEnemy": "공격할 적이 없다", "notOwner": "그 동료의 카드가 아니다",
		"noelCard": "노엘의 카드는 적 행동·적·동료 위에 놓는다", "notNoel": "동료 칸에 놓는 카드", "badAct": "옮기거나 줄일 수 있는 적 행동이 아니다",
		"badEnemy": "적 위에 놓아야 한다", "badAlly": "동료 위에 놓아야 한다", "already": "이미 걸려 있다", "noDest": "옮길 칸이 없다",
		"needTarget": "공격할 적을 골라야 한다", "noFront": "앞에 적이 없습니다", "badMove": "그 칸으로는 옮길 수 없다", "movedAgain": "나중에 옮긴 카드를 먼저 되돌린다",
		"noPlaced": "놓은 카드가 없다",
		"bench": "대기 중인 동료에게는 맡길 수 없다", "empty": "빈칸에는 동료가 없다", "death": "죽음은 막거나 줄일 수 없다",
		"notDeath": "죽음 카드 위에 놓는다", "occupied": "벤치의 동료는 빈칸에만 넣는다", "same": "같은 자리", "noneFielded": "칸에 동료가 하나는 있어야 한다",
		"formation": "출전 배치를 먼저 끝낸다", "deadAlly": "죽은 동료는 돌아오지 않는다",
		"unplayable": "낼 수 없는 카드", "fixed": "이 죽음은 옮길 수도 찢을 수도 없다", "erased": "이미 없앤 행동이다",
	},
}
