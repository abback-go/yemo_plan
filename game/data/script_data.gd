## script_data.gd — 대본: 대사·안내 상자·선택지·장면 문구를 모두 모아 둔 파일.
## 기준: docs/tutorial-script-vs.md v3 (버티컬 슬라이스 — 장례 탑 1층, 2026-11-21). 2·3층은 1차 시험판 v2 대사([임시]) 그대로.
## 수치·배치는 data/game_data.gd. 대본이 바뀌면 이 파일만 바꾸면 된다. 표정 이름·새 카드 이름·수치는 모두 [임시](대본 v3).
##
## ── 줄(대사) 형식 ──────────────────────────────────────────────
##  비주얼노벨 장면(캠프·방·빈 캠프): {"speaker", "text", "face"?, "show"?, "tag"?}
##    speaker: hero | warrior | archer | noel | inner(노엘 속마음) | narr(내레이션) | system(안내 상자) | 그 밖(names 의 이름: cultist·gravekeeper·keeper·child)
##    face: 표정 이름(예: "hero_smile" → 스탠딩이 stand_hero_smile.png 로 바뀌고 얼굴도 거기서). 그림이 없으면 스탠딩은 그대로(대사창은 기본 스탠딩의 얼굴)
##    show: 등장 인물과 자리 {"hero": "C", ...} (자리: FL L C R FR). {} = 모두 퇴장
##    tag: 그 인물 스탠딩에 이름표를 붙인다(파티 소개). "" = 이름표를 뗀다
##    text 가 없는 줄은 show·tag 만 바꾸고 넘어간다(대본의 [연출] — 인물이 움직이는 순간)
##  그 밖의 줄(명령):
##    {"choice": [{"text", "value", "lines": [...], "hpCost"?}], "key": 플래그 이름}  선택지 (고른 값이 st.flags[key]).
##        hpCost: 노엘 HP 가 이 값 이하이면 고를 수 없다(거래)
##    {"if": {플래그: 값}, ...}   그 플래그일 때만 나오는 줄 (예: {"brun": "alive"})
##    {"call": "..."}            게임 결과: rest(휴식) · train(훈련) · gain:카드(덱에) · buried(꺼낸다: HP−·부적) · trade:card | trade:candle(거래)
##                               · omen(전조를 봄) · fate:운명id(새 운명) · descend(층 내려감) · heal(모두 회복)
##    {"cg": "그림"}             그 줄부터 배경을 이 그림으로
##    {"omen": {...}}            죽음 카드가 손 위로 떠오르는 연출 (game_data.gd "omen" 참고)
##        card: 카드 id("" = 아직 누구인지 모르는 흐린 카드) / clarity: 0(알아볼 수 없음)~1(또렷) / mask: 문구 대신 카드의 maskText(방식이 아직 안 보임)
##        taut: 팽팽해지는 실의 동료 / faint: 아주 희미하게 떨리기만 하는 실의 동료들 / dim: 화면을 어둡게
##    {"omen_end": true}         떠오른 카드가 손 안으로 가라앉듯 사라진다
##  전투 중 대사(guide)·지도 위 대사: {"who", "text", "face"?, "faces"?} — who 는 위 speaker 와 같고 system = 안내 상자
##  안내 상자 글: 「카드 이름」·**강조** 는 색을 달리해 보여 준다. 줄바꿈 \n, 목록은 "· "
##  안내 상자는 탭해야 넘어가며(떠 있는 동안 진행이 멈춘다), 같은 안내는 한 번만 나온다
##  (다시 하기 후에도 다시 나오지 않음 — 본 안내는 브라우저 저장소에 기록. 주소 ?guides=reset 으로 초기화).
## ───────────────────────────────────────────────────────────
class_name ScriptData
extends Object

const S := {
	"meta": {
		"title": "죽음을 보는 마녀",
		"subtitle": "(가제) · 버티컬 슬라이스 시험판",
		"fromFloor2": "2층부터", "fromFloor3": "3층부터",
		"startButton": "시작",
		"note": "마우스로 플레이 · PC 1920×1080 기준",
	},
	# 타이틀 메뉴 · 일시정지(Esc) · 설정 · 확인 창 (ui/game_menu.gd, scenes.gd title). {place} = 저장한 곳(층 · 방 이름)
	"menu": {
		"start": "시작", "continue": "이어하기", "settings": "설정", "quit": "끝내기",
		"savedAt": "자동 저장 · {place}", "floorEnd": "{floor} 끝",
		"newTitle": "처음부터 시작할까요?", "newText": "처음부터 시작하면 저장된 진행이 지워집니다.", "newYes": "처음부터", "cancel": "취소",
		"pauseTitle": "잠시 멈춤", "resume": "계속", "toTitle": "타이틀로",
		"toTitleTitle": "타이틀로 돌아갈까요?", "toTitleText": "진행은 마지막 자동 저장까지만 남습니다.", "noSave": "아직 자동 저장이 없습니다.",
		"settingsTitle": "설정", "display": "화면", "windowed": "창", "fullscreen": "전체 화면",
		"textSpeed": "글자 속도", "slow": "느림", "normal": "보통", "fast": "빠름", "instant": "즉시",
		"sample": "글자가 이 빠르기로 나옵니다.", "close": "닫기",
		"fullscreenFail": "이 브라우저에서는 전체 화면으로 바꿀 수 없습니다.",
	},
	"names": {"hero": "세라피나", "warrior": "브룬힐드", "archer": "엘리안", "noel": "노엘", "witch": "노엘", "inner": "노엘", "narr": "", "system": "",
		"cultist": "광신도", "gravekeeper": "무덤지기", "keeper": "묘지기", "child": "아이"},
	"roles": {"hero": "용사", "warrior": "전사", "archer": "궁수", "noel": "마녀", "witch": "마녀"},
	# 파티 소개 이름표 (대본 v3 0장)
	"tags": {"hero": "세라피나 · 용사", "warrior": "브룬힐드 · 전사", "archer": "엘리안 · 궁수", "noel": "노엘 · 마녀"},

	# 화면 곳곳의 짧은 문구
	"ui": {
		"endTurn": "턴 종료", "deck": "덱", "discard": "버림", "witchSub": "마녀 · 나", "down": "쓰러짐", "unusable": "사용 불가",
		"turn": "{n}턴", "giantTurn": "{n}턴 · 짓밟기까지 {left}", "enemyPhase": "적의 차례", "floorBattle": "{n}층",
		"innerName": "노엘 (속마음)", "systemName": "안내", "skip": "건너뛰기 ▶▶", "cutHint": "탭: 다음", "tapNext": "탭: 다음 ▼",
		"immune": "흠집만 난다", "reshuffle": "버림 더미를 섞어 새 덱으로", "handFull": "손패가 가득 찼다",
		"allyDown": "{name} 쓰러짐", "relic": "{name}의 카드 {n}장이 유품이 되었다", "wound": "{name}의 카드 1장이 「상처」가 되었다",
		"pickAlly": "새로 맞을 아군을 고르세요 · 빈 곳: 취소", "dropHere": "놓으면 사용", "dragUp": "위로 끌어올려 사용",
		"needIntent": "예고된 공격에 놓아야 한다", "needAlly": "동료 위에 놓아야 한다", "cantHere": "여기에는 낼 수 없다",
		"trainTitle": "강화할 카드를 고르세요", "trainHint": "고른 카드 1장이 강화된다 (Lv1 → Lv2)", "tapClose": "탭하면 닫힘", "ownerScar": "흉터 · 운명을 거스른 값",
		"blocked": "막힘", "canceled": "지워짐", "defied": "운명을 거슬렀다", "lethal": "치명", "noRedirect": "옮기기 불가", "allTargets": "모두",
		"hidden": "?", "faceDown": "뒤집힌 카드",
		"resultOk": "확인", "rotate": "가로로 돌려 주세요", "rotateSub": "이 게임은 가로 화면(16:9)으로 플레이합니다",
		"loading": "불러오는 중…",
		# 카드 아래쪽 주인 표시
		"ownerDeath": "죽음 · {name}", "ownerRelic": "유품 · {name}", "ownerInherit": "상속 · {name}", "ownerWound": "상처 · {name}",
		# 거래 고르기 (대본 v3 3.7) · 얻은 카드 알림. 전투 승리 뒤 카드 보상 문구(rewardTitle·rewardHint·rareTitle·rewardSkip)는 2026-11-21 사용자 지시로 보상과 함께 뺐다
		"tradeTitle": "카드 1장을 고르세요 — 노엘 HP {n}", "tradeSkip": "사지 않는다",
		"gainCard": "「{card}」 — 덱에 들어왔다", "candleGain": "촛불 +{n} (랜턴 {now}개)", "hpLoss": "노엘 HP -{n}",
	},
	# 카드를 낼 수 없을 때 짧은 알림 (rules.gd 의 이유 → 화면 문구)
	"reasons": {
		"지금은 낼 수 없다": "지금은 낼 수 없다", "에너지가 부족하다": "에너지가 부족하다", "쓰러진 동료의 카드": "쓰러진 동료의 카드",
		"죽은 동료의 카드": "죽은 동료의 카드", "낼 수 없는 카드": "낼 수 없는 카드", "대상이 없다": "대상이 없다",
	},

	# ───────────── 전투·지도 위 안내 (대본 v3 1·2·5장) ─────────────
	# on: battleStart | turnStart | cardPlayed | redirect | energyOut | enemyPhaseEnd | allyDown | immune | afterDeath | battleWin
	#     | darkness | mapFirst | lanternFirst | deathInHand | twoDeathCards | fateIntent | fateFirst | scarFirst
	# enc: normal(장례 회랑) | prayer | gravekeeper | deep(가장 깊은 곳) | giant(거대한 발) | ossuary | pyre / turn: 그 턴에만 / card: 그 카드를 냈을 때 / once: 한 번만
	"guide": [
		# ── 1. 장례 회랑 — 전투 ① ──
		{"id": "n_start", "on": "battleStart", "enc": "normal", "lines": [
			{"who": "system", "text": "**차례대로 진행됩니다.** 당신의 차례(카드를 낸다) → 적의 차례 → 다시 당신의 차례.\n적을 모두 쓰러뜨리면 승리, 노엘의 HP가 0이 되거나 동료 셋이 모두 쓰러지면 패배."}]},
		{"id": "n_t1", "on": "turnStart", "enc": "normal", "turn": 1, "lines": [
			{"who": "system", "text": "**매 턴 카드를 뽑고 에너지 3을 받습니다.**"},
			{"who": "system", "text": "**손패 맨 오른쪽의 뒤집힌 카드는 낼 수 없습니다.** 버려지지 않고 손패 한 칸을 차지해, 4장만 새로 뽑습니다."},
			{"who": "system", "text": "**카드 왼쪽 위 숫자가 비용**입니다. **테두리 색은 카드의 주인**(노엘·세라피나·브룬힐드·엘리안)입니다."},
			{"who": "system", "text": "**내는 법**: 공격 카드는 적 위로 끌어 놓고, 대상이 없는 카드는 위로 끌어올립니다. 다 냈으면 「턴 종료」 — 남은 손패는 버려집니다."}]},
		{"id": "n_intent", "on": "enemyPhaseEnd", "enc": "normal", "once": true, "lines": [
			{"who": "system", "text": "**적은 다음에 할 일을 머리 위에 미리 보여 줍니다(예고).**"}]},
		{"id": "n_t2", "on": "turnStart", "enc": "normal", "turn": 2, "lines": [
			{"who": "hero", "face": "hero_determined", "text": "셋 다 엘리안이야! 노엘!"},
			{"who": "warrior", "face": "warrior_smirk", "text": "아가씨, 내 뒤로. 반은 내가 먹어 줄게."},
			{"who": "archer", "face": "archer_cold", "text": "아가씨라고 하지 마세요."},
			{"who": "inner", "text": "셋 다 엘리안한테 가. 하나는 옮겨야 돼."},
			{"who": "system", "text": "**노엘의 싸움은 \"피해 옮기기\"입니다.**\n· 「운명 전가」: 예고 위에 놓고 새로 맞을 동료를 고른다.\n· 「대신 받기」: 노엘이 대신 맞는다.\n· 「감싸기」: 브룬힐드가 대신 맞되 피해는 절반."},
			{"who": "system", "text": "엘리안의 HP는 12. **공격 하나라도 다른 사람에게 옮기세요.**"}]},
		{"id": "n_redirect", "on": "redirect", "once": true, "lines": [
			{"who": "hero", "face": "hero_smile", "text": "좋아, 그거야."}]},
		{"id": "n_down", "on": "allyDown", "once": true, "lines": [
			{"who": "system", "text": "**쓰러진 동료는 이번 전투에서 행동할 수 없고, 그 동료의 카드도 낼 수 없습니다.** 전투가 끝나면 HP 1로 일어나지만 그 동료의 카드 1장이 「상처」로 바뀝니다."}]},
		{"id": "n_win", "on": "battleWin", "enc": "normal", "lines": [
			{"who": "hero", "face": "hero_calm", "text": "다친 사람? 엘리안, 너 팔. 숨기지 말고."},
			{"who": "archer", "face": "archer_cold", "text": "긁힌 거예요."}]},
		# (승리 뒤 카드 보상 안내 「전투에서 이기면 카드 3장 중 1장…」는 2026-11-21 사용자 지시로 보상과 함께 뺐다)

		# ── 3.2 무덤지기 (강적) — 방의 대사(events.gravekeeper) 뒤, 전투 시작에 ──
		{"id": "e_start", "on": "battleStart", "enc": "gravekeeper", "lines": [
			{"who": "system", "text": "**강적 — 더 강하지만 보상이 큽니다.**"}]},
		# ── 어둠 (층 끝 전투·강적 전투에서 예고가 가려졌을 때) ──
		{"id": "d_dark", "on": "darkness", "lines": [
			{"who": "system", "text": "**어둠 — 적의 예고 일부가 가려졌습니다.**"}]},

		# ── 2. 안치 홀 — 지도·촛불 (지도 위) ──
		{"id": "m_map", "on": "mapFirst", "lines": [
			{"who": "system", "text": "**방을 눌러 들어갑니다.** 아이콘은 그 방에서 일어날 일입니다(전투·강적·사건·휴식·훈련·거래·전조)."},
			{"who": "system", "text": "**모든 방에 들어갈 필요는 없습니다.** 계단 앞 홀을 지나 가장 깊은 곳에 닿으면 이 층의 끝입니다."}]},
		{"id": "m_lantern", "on": "lanternFirst", "lines": [
			{"who": "warrior", "face": "warrior_smirk", "text": "마녀님, 초는 넉넉해? 탑 안에서 불 꺼지면 그다음은 장례식이야."},
			{"who": "noel", "text": "네 개."},
			{"who": "warrior", "face": "warrior_smirk", "text": "넉넉하진 않네."},
			{"who": "system", "text": "**랜턴의 촛불** — 처음 들어가는 방마다 하나씩 탑니다. 다 타면 어둠이 내려 **층 끝 전투와 강적 전투에서 적의 예고 일부가 가려집니다.** 그 뒤로 방에 들어갈 때마다 어둠이 깊어집니다. 남은 촛불은 다음 층으로 이어집니다(최대 8개)."}]},

		# ── 5.1 가장 깊은 곳 — 광신도 전투 ──
		{"id": "f1_deep", "on": "battleStart", "enc": "deep", "lines": [
			{"who": "system", "text": "배운 대로 해 보세요. 위험한 공격은 옮기세요."}]},
		# ── 5.2 거대한 발 — 보스 전투 ──
		{"id": "g_start", "on": "battleStart", "enc": "giant", "lines": [
			{"who": "hero", "face": "hero_determined", "text": "저게 원인이야. 여기서 끊는다!"},
			{"who": "system", "text": "**거대한 존재.** 예고를 보고 버티세요. 3턴째에 「짓밟기」(모두에게 큰 피해)가 옵니다."}]},
		{"id": "g_immune", "on": "immune", "once": true, "lines": [
			{"who": "warrior", "face": "warrior_shocked", "text": "흠집밖에 안 나. 뭐 이런 게 다 있어."},
			{"who": "hero", "face": "hero_determined", "text": "계속 쳐! 어딘가 약한 데가 있을 거야."}]},
		{"id": "g_t2", "on": "turnStart", "enc": "giant", "turn": 2, "lines": [
			{"who": "archer", "face": "archer_shocked", "text": "다시 들려요! 다음엔 내려와요!"},
			{"who": "hero", "face": "hero_determined", "text": "내가 앞에서 받는다. 다들 내 뒤로."}]},
		# 5.4 사망 직후 (카드 문구가 보인 뒤)
		{"id": "g_after", "on": "afterDeath", "card": "hero_death", "lines": [
			{"who": "system", "text": "**죽음 카드 — 노엘만 보는 카드입니다.** 노엘은 동료가 어디서, 어떻게 죽을지 미리 봅니다. 그 죽음은 카드가 되어 손에 들어오고, 카드를 보면 언제 어디서 오는지 알 수 있습니다."},
			{"who": "system", "text": "**운명의 죽음이 일어나면** 그 죽음의 힘과 그 동료의 유품이 손에 들어옵니다.\n· 「짓밟힘」: 세라피나를 죽인 그 죽음이 노엘의 카드가 되었습니다.\n· 세라피나의 카드는 「유품」으로 바뀌었습니다. 더 강하지만, 낼 때마다 노엘의 HP가 줄어듭니다."}]},

		# ── 2·3층 (1차 시험판 v2, 2026-11-21 죽음 카드 컨셉 변경에 맞춰 고침) ──
		{"id": "v3_death_hand", "on": "deathInHand", "lines": [
			{"who": "system", "text": "**손패의 죽음 카드는 낼 수 없습니다.** 그 동료의 죽음을 미리 보여 주는 카드입니다 — 버려지지 않고 손패 한 칸을 차지해, 그만큼 덜 뽑습니다."}]},
		{"id": "v2_two_cards", "on": "twoDeathCards", "lines": [
			{"who": "system", "text": "**살아 있는 동료의 죽음 카드는 모두 손에 들어옵니다.** 두 장이면 두 장 모두 — 그만큼 덜 뽑습니다."}]},
		{"id": "v2_fate_fire", "on": "fateIntent", "lines": [
			{"who": "system", "text": "**운명의 시도가 예고되었습니다.** 운명 공격은 피해를 옮길 수 없고, 어둠에도 가려지지 않습니다. 적의 차례에 그 공격이 닿는 순간, 받아들일지 거스를지 고릅니다.\n· 예고한 적을 먼저 쓰러뜨려도, 쓰러지는 그 순간 운명이 옵니다."}]},
		{"id": "v2_fate_first", "on": "fateFirst", "lines": [
			{"who": "system", "text": "**운명의 시도** — 고르세요.\n· **받아들인다**: 그 동료는 그 방식으로 죽고, 그 죽음의 힘(「상속」 카드)과 그 동료의 유품이 들어옵니다.\n· **거스른다**: 그 동료는 살지만 노엘 덱에 「흉터」가 새겨지고, 운명은 다음 층으로 미뤄져 더 잔혹하게(Lv 이 올라) 다시 옵니다."}]},
		{"id": "v2_scar", "on": "scarFirst", "lines": [
			{"who": "system", "text": "**「흉터」**: 운명을 거스른 값. 낼 수 없고, 손에 든 채 턴이 끝나면 노엘 HP가 1 줄어듭니다. 이번 회차 내내 덱에 남습니다."}]},
		{"id": "v2_after_w", "on": "afterDeath", "card": "warrior_death", "lines": [
			{"who": "inner", "text": "그녀가 죽은 방식이, 내 손에 남았다."},
			{"who": "system", "text": "**「꿰뚫린 방패」**: 예고된 공격을 막고(피해 0) 그 피해만큼 되돌립니다. 브룬힐드의 카드는 「유품」이 되었습니다."}]},
		{"id": "v2_after_a", "on": "afterDeath", "card": "archer_death", "lines": [
			{"who": "inner", "text": "그녀가 타 죽은 불이, 내 손에 남았다."},
			{"who": "system", "text": "**「타버린 활」**: 모든 적에게 피해. 엘리안의 카드는 「유품」이 되었습니다."}]},
	],

	# 가장 깊은 곳: 광신도가 1명 남으면 구멍 위의 어둠이 내려온다 — 발. 광신도가 한 번에 사라진다 (대본 v3 5.1)
	"giantAppear": {
		"before": [],
		"after": [
			{"who": "archer", "face": "archer_shocked", "text": "방금 뭐였어요?"},
			{"who": "warrior", "face": "warrior_shocked", "text": "원정대 납작하게 만든 거, 저거네."}],
	},

	# ───────────── 0. 곁방 — 캠프 (층의 시작) ─────────────
	"camp": [
		{"speaker": "narr", "text": "왕국의 죽은 사람은 모두 이 탑에 묻힌다. 땅 밑으로 거꾸로 자라는 장례 탑이다."},
		{"speaker": "narr", "text": "지난겨울부터 무덤이 비기 시작했다. 잠든 채 깨어나지 않고 사라지는 사람도 늘었다."},
		{"show": {"warrior": "L", "hero": "C", "archer": "R"}, "speaker": "hero", "face": "hero_calm", "text": "정리하자. 원인은 탑 맨 아래. 내일 아침에 내려가서 그걸 끊고 온다."},
		{"speaker": "warrior", "face": "warrior_smirk", "text": "장례 탑 입구에서 야영이라니. 자다가 누가 관 뚜껑 덮어 주는 거 아냐?"},
		{"speaker": "archer", "face": "archer_cold", "text": "그런 말 하지 마세요. 진짜 있을 것 같잖아요."},
		{"speaker": "warrior", "face": "warrior_smirk", "text": "아가씨 무서워?"},
		{"speaker": "archer", "face": "archer_cold", "text": "아니요."},
		# [연출] 파티 소개 — 그 인물이 움직이는 순간에 이름표 → 안내 상자. 세라피나가 검을 들고 일어나 문 앞에 가서 앉는다
		{"show": {"warrior": "FL", "hero": "C", "archer": "FR"}, "tag": "hero"},
		{"speaker": "warrior", "face": "warrior_smirk", "text": "대장, 불침번 또 첫 번째야? 오늘은 내가 할게."},
		{"speaker": "hero", "face": "hero_smile", "text": "됐어. 너 내일 방패 들어야 하잖아. 자."},
		{"speaker": "system", "text": "**세라피나 — 용사.** 강한 공격으로 적을 쓰러뜨린다. 대표 카드 「성검 베기」."},
		{"tag": "", "speaker": "warrior", "face": "warrior_smirk", "text": "그럼 난 대장 몫까지 자야지."},
		# [연출] 브룬힐드가 방패를 베개 삼아 눕는다
		{"show": {"hero": "FL", "warrior": "C", "archer": "FR"}, "tag": "warrior"},
		{"speaker": "system", "text": "**브룬힐드 — 전사.** 동료 대신 공격을 받아 낸다. 대표 카드 「감싸기」."},
		{"show": {"warrior": "FL", "archer": "C", "noel": "FR"}, "tag": "archer", "speaker": "archer", "face": "archer_cold", "text": "노엘, 손 좀 보여 주세요. 또 늘었네요, 그 상처."},
		{"speaker": "noel", "text": "실이 엉켜서."},
		{"speaker": "archer", "face": "archer_cold", "text": "붕대 어디 있어요. 아니, 됐어요. 내일 제가 감을게요."},
		{"speaker": "system", "text": "**엘리안 — 궁수.** 체력은 약하지만 멀리서 정확히 맞힌다. 대표 카드 「저격」."},
		{"show": {"archer": "FL", "noel": "C"}, "tag": "noel"},
		{"speaker": "system", "text": "**노엘 — 마녀(당신).** 동료들의 카드까지 모두 손에 쥐고, 누가 언제 움직일지 정한다. 노엘의 싸움은 **누가 공격을 받을지 바꾸는 것**이다."},
		{"show": {"warrior": "FL", "hero": "L", "archer": "C", "noel": "FR"}, "tag": "", "speaker": "hero", "face": "hero_smile", "text": "노엘, 내일은 뭐 보여?"},
		{"speaker": "noel", "text": "늘 보이던 거."},
		{"speaker": "hero", "face": "hero_smile", "text": "그럼 됐어. 자, 다들 자. 해 뜨기 전에 내려간다."},
		{"show": {}, "speaker": "narr", "text": "다음 날 아침, 장례 탑 1층."},
	],

	# ───────────── 방마다의 장면 (대본 v3 1~6장) ─────────────
	"events": {
		# 1. 장례 회랑 — 전투 ① (정해진 길). 대사 뒤 같은 배경에서 전투(encounters.normal)
		"corridor": [
			{"speaker": "narr", "text": "회랑 양쪽 벽에 관이 박혀 있다. 뚜껑이 전부 안에서 밀려 열려 있다."},
			{"show": {"warrior": "L", "hero": "C", "archer": "R"}, "speaker": "warrior", "face": "warrior_stern", "text": "안에서 열었네. 누가 나왔다는 얘기지."},
			{"speaker": "cultist", "text": "바쳐라. 탑은 죽음을 받고, 죽음으로만 돌려준다."},
			{"speaker": "hero", "face": "hero_determined", "text": "셋. 내가 앞, 엘리안 뒤. 노엘, 순서 잡아 줘."},
		],
		# 2. 안치 홀 — 지도·촛불 (정해진 길). 이 장면 뒤 지도가 열리고 지도 위 안내(guide mapFirst·lanternFirst)
		"hall": [
			{"speaker": "narr", "text": "둥근 홀. 벽을 따라 관이 천장까지 쌓여 있고, 길이 여러 갈래로 나 있다."},
			{"show": {"hero": "C"}, "speaker": "hero", "face": "hero_calm", "text": "길 많네. 노엘, 지도."},
		],
		# 3.1 광신도 기도실 — 전투 (승리 뒤 카드 3장 중 1장 보상은 2026-11-21 사용자 지시로 뺐다)
		"prayer": [
			{"speaker": "narr", "text": "광신도 둘이 바닥의 구멍 쪽으로 엎드려 기도하고 있다."},
			{"speaker": "cultist", "text": "받으소서. 받으시고, 돌려주소서."},
			{"show": {"archer": "L", "warrior": "R"}, "speaker": "archer", "face": "archer_cold", "text": "뭘 돌려받겠다는 거예요?"},
			{"speaker": "warrior", "face": "warrior_smirk", "text": "묻지 마. 대답해 줄 것 같잖아."},
		],
		# 3.2 무덤지기 — 강적 (기도실 안쪽) → 이기면 희귀 목록의 카드 1장이 강화된 채 바로 덱에(고르지 않음, 기본안 — game_data.gd rewards.elite). 강적 안내는 전투 시작에(guide e_start)
		"gravekeeper": [
			{"speaker": "narr", "text": "관 뚜껑을 갑옷처럼 덧댄 거구가 길을 막고 있다."},
			{"speaker": "gravekeeper", "text": "산 사람은 내려가는 게 아니야. 실려 내려가는 거지."},
			{"show": {"warrior": "C"}, "speaker": "warrior", "face": "warrior_smirk", "text": "말 잘하네. 실려 나가는 건 네 쪽이 될 거야."},
		],
		# 3.3 순장된 자의 방 — 사건
		"buried": [
			{"speaker": "narr", "text": "못이 박힌 관 하나. 안에서 두드리는 소리가 난다."},
			{"show": {"archer": "L", "warrior": "R"}, "speaker": "archer", "face": "archer_shocked", "text": "안에 사람 있어요."},
			{"speaker": "warrior", "face": "warrior_stern", "text": "이 탑에서 '사람'이면 다행이고."},
			{"key": "buried", "choice": [
				{"text": "꺼낸다", "value": "open", "lines": [
					{"show": {"archer": "FL", "child": "C", "warrior": "FR"}, "speaker": "narr", "text": "못을 뽑다가 손이 찢어졌다. 안에는 잠옷 차림의 아이가 있다."},
					{"speaker": "child", "text": "자고 있었는데… 눈 떠 보니까 깜깜했어요."},
					{"speaker": "archer", "face": "archer_cold", "text": "위로 올라가요. 계단 보이죠. 뒤돌아보지 말고요."},
					{"call": "buried"}]},
				{"text": "둔다", "value": "leave", "lines": [
					{"speaker": "narr", "text": "두드리는 소리가 멎었다."},
					{"speaker": "archer", "face": "archer_cold", "text": "……가요."},
					{"speaker": "warrior", "face": "warrior_stern", "text": "잘했어. 여기선 안 여는 게 맞아."}]},
			]},
		],
		# 3.4 핏자국 통로 끝 — 시체 (죽은 마녀 = 이전 회차의 노엘 — 이야기 속 의미를 말하는 대사는 없다)
		"corpse": [
			{"speaker": "narr", "text": "핏자국은 막다른 벽 앞에서 끝난다. 마녀 하나가 벽에 기대앉아 있다. 넓은 모자에 얼굴이 가려져 있다."},
			{"speaker": "narr", "text": "주위에 카드가 흩어져 있다. 그림이 전부 타서 알아볼 수 없다."},
			{"show": {"archer": "L", "hero": "R"}, "speaker": "archer", "face": "archer_shocked", "text": "마녀예요. 노엘이랑 같은."},
			{"speaker": "hero", "face": "hero_calm", "text": "혼자 여기까지 내려왔구나."},
			{"speaker": "inner", "text": "이 카드 한 장은 안 탔네. 가져가자."},
			{"call": "gain:nameless_card"},
			{"speaker": "system", "text": "「이름 없는 마녀의 카드」 — 비용 0. **예고 하나를 지웁니다**(운명 공격은 지울 수 없음). 대가로 노엘 HP 3. 전투마다 한 번."},
			{"show": {"warrior": "C"}, "speaker": "warrior", "face": "warrior_stern", "text": "묻어 줄 시간은 없어. 가자, 마녀님."},
		],
		# 3.5 촛불 예배당 — 휴식. 수치는 game_data.gd "rest"
		"chapel": [
			{"speaker": "narr", "text": "꺼지지 않은 촛불 몇 개가 남은 작은 예배당."},
			{"show": {"hero": "L", "archer": "C", "noel": "FR"}, "speaker": "hero", "face": "hero_smile", "text": "여기서 좀 쉬자. 엘리안, 너 팔부터."},
			{"speaker": "archer", "face": "archer_cold", "text": "저 말고 노엘이요. 손 주세요."},
			# [연출] 엘리안이 노엘의 손가락에 붕대를 감는다
			{"show": {"hero": "FL", "archer": "R", "noel": "FR"}},
			{"speaker": "noel", "text": "아파."},
			{"speaker": "archer", "face": "archer_cold", "text": "참으세요. 다 됐어요."},
			{"show": {"warrior": "L", "archer": "R", "noel": "FR"}, "speaker": "warrior", "face": "warrior_smirk", "text": "둘이 그러고 있으니까 여기가 장례 탑인 걸 까먹겠네."},
			{"call": "rest"},
			{"speaker": "system", "text": "**쉬었습니다.** 모두 HP를 전부 회복하고 최대 HP가 올랐습니다. (동료 +3, 노엘 +2)"},
		],
		# 3.6 무너진 훈련장 — 훈련 (카드 1장 강화)
		"training": [
			{"show": {"warrior": "L", "hero": "C", "archer": "R"}, "speaker": "warrior", "face": "warrior_smirk", "text": "내려가기 전에 한 번 맞춰 보자. 마녀님 신호에 맞춰서 한 박자 먼저."},
			{"speaker": "system", "text": "**카드 1장을 강화합니다.** 3장 중 하나. 강화하면 레벨이 오릅니다(Lv1 → Lv2)."},
			{"call": "train"},
			{"if": {"upgraded": "holy_slash"}, "speaker": "hero", "face": "hero_calm", "text": "좋아. 한 번만 더."},
			{"if": {"upgraded": "snipe"}, "speaker": "archer", "face": "archer_cold", "text": "바람 봤어요. 다음엔 안 빗나가요."},
			{"if": {"upgraded": "cover"}, "speaker": "warrior", "face": "warrior_smirk", "text": "받는 각도 바꿨어. 이제 좀 덜 아프겠네."},
			{"if": {"upgraded": "curse_flame"}, "speaker": "inner", "text": "이 정도면 광신도 둘은 한 번에 돼."},
		],
		# 3.7 묘지기의 좌판 — 거래 [수치 임시: game_data.gd "trade"]
		"stall": [
			{"speaker": "narr", "text": "관 뚜껑 위에 초와 카드를 늘어놓은 늙은 묘지기."},
			{"speaker": "keeper", "text": "돈은 필요 없어. 여긴 장례 탑이라. 피를 조금 받지."},
			{"show": {"warrior": "R"}, "speaker": "warrior", "face": "warrior_smirk", "text": "장사 방식이 마음에 드네. 마녀님이 내."},
			{"speaker": "system", "text": "**거래 — 노엘의 HP를 대가로 카드나 촛불을 얻습니다.**"},
			{"key": "trade", "choice": [
				{"text": "카드 — HP 4", "value": "card", "hpCost": 4, "lines": [{"call": "trade:card"}]},
				{"text": "촛불 1개 — HP 2", "value": "candle", "hpCost": 2, "lines": [{"call": "trade:candle"}]},
				{"text": "그냥 간다", "value": "none", "lines": []},
			]},
			{"if": {"traded": "yes"}, "speaker": "keeper", "text": "아래로 갈수록 값은 올라. 기억해 둬."},
		],
		# 3.8 발자국 방 — 전조 (이 층 끝 전투는 어둠이 와도 가려지지 않는다)
		"footprints": [
			{"speaker": "narr", "text": "바닥이 발가락 모양으로 꺼져 있다. 그 안에 납작하게 눌린 갑옷이 여러 벌 있다. 먼저 내려간 원정대다."},
			{"show": {"warrior": "L", "archer": "C", "hero": "R"}, "speaker": "warrior", "face": "warrior_stern", "text": "이게 발자국이면, 발 주인은 얼마나 크다는 거야."},
			{"speaker": "archer", "face": "archer_cold", "text": "이 아래에 있다는 거네요. 이걸 만든 게."},
			{"speaker": "hero", "face": "hero_determined", "text": "그럼 잘 찾아온 거야."},
			{"call": "omen"},
			{"speaker": "system", "text": "**전조를 보았습니다.** 이 층 끝 전투에서는 어둠이 와도 예고가 가려지지 않습니다."},
		],
		# 4. 계단 앞 홀 (정해진 길)
		"stairs": [
			{"speaker": "narr", "text": "이 층 가장 깊은 곳으로 내려가는 계단. 아래에서 기도 소리가 올라온다."},
			{"show": {"warrior": "L", "hero": "C", "archer": "R"}, "speaker": "hero", "face": "hero_calm", "text": "광신도들이 저 아래 모여 있어. 거기만 정리하면 2층 계단이야."},
			{"speaker": "warrior", "face": "warrior_smirk", "text": "대장, 끝나면 뭐 먹을 거야?"},
			{"speaker": "hero", "face": "hero_smile", "text": "너 그거 물으면 꼭 일 생기더라."},
			{"speaker": "archer", "face": "archer_cold", "text": "그럼 묻지 마세요."},
			{"speaker": "hero", "face": "hero_determined", "text": "가자. 노엘, 뒤 부탁해."},
		],
		# 5.1 가장 깊은 곳 (층 끝) — 대사 뒤 광신도 전투 → 거대한 발 보스 전투
		"deep": [
			{"speaker": "narr", "text": "바닥 한가운데 끝이 안 보이는 구멍이 있다. 광신도 둘이 가장자리에 엎드려 있다."},
			{"speaker": "cultist", "text": "오신다. 오신다."},
			{"show": {"hero": "C"}, "speaker": "hero", "face": "hero_determined", "text": "둘. 빨리 끝내자."},
		],
		# 6. 빈 캠프 (층의 끝) — 다음 죽음: 얼굴은 브룬힐드, 문구는 번져 읽히지 않는다
		"emptycamp": [
			{"speaker": "narr", "text": "같은 곁방. 침낭 하나가 펼쳐진 채 비어 있다."},
			{"show": {"warrior": "L", "archer": "C", "noel": "FR"}, "speaker": "archer", "face": "archer_grief", "text": "대장 침낭, 제가 갤게요."},
			{"speaker": "warrior", "face": "warrior_stern", "text": "두고 가."},
			# [연출] 엘리안은 대답하지 않고 침낭을 갠다
			{"show": {"warrior": "L", "archer": "R", "noel": "FR"}},
			{"speaker": "warrior", "face": "warrior_stern", "text": "마녀님. 이것도 보였어?"},
			{"speaker": "noel", "text": "……"},
			{"speaker": "warrior", "face": "warrior_grief", "text": "됐어. 안 물을게."},
			# [연출] 다음 죽음 — 노엘의 손 위로 카드 한 장이 떠오른다. 얼굴은 브룬힐드. 문구는 번져 읽히지 않는다
			{"call": "fate:warrior_pierce"},
			{"omen": {"card": "warrior_death", "clarity": 1.0, "mask": true, "taut": ["warrior"], "dim": 0.3, "fireLow": true}},
			# [연출] 브룬힐드는 모닥불 앞에서 방패 끈을 고쳐 매고 있다
			{"show": {"warrior": "C", "noel": "FR"}},
			{"speaker": "inner", "text": "다음은 브룬힐드야. 어디서 어떻게 죽는지는 아직 안 보여."},
			{"omen_end": true},
			{"speaker": "system", "text": "**운명은 거스를 수 있습니다.** 죽음이 오는 순간 막으면 그 동료는 살지만, 대가가 따릅니다. (2층에서 처음)"},
			{"call": "heal"},
		],
		# ── 2층 (탑뷰 대신 VN 장면 — 대사는 시험판 v2 [임시] 그대로) ──
		"f2corridor": [
			{"show": {"warrior": "L", "archer": "R"}, "speaker": "warrior", "face": "warrior_stern", "text": "바닥이 수상하다. 내 뒤로 붙어."},
			{"speaker": "archer", "face": "archer_shocked", "text": "…저 해골들, 다 창에 꿰여 있어."},
			# 전조: 노엘 속마음 (운명의 시도는 전투 안에서만 — 2026-11-18)
			{"show": {}, "speaker": "inner", "text": "창이 박힌 바닥, 꿰인 기사들. …이 층이다."},
			{"speaker": "inner", "text": "브룬힐드의 죽음은 이 아래에서, 창을 들고 기다린다."},
		],
		"f2ossuary": [
			{"show": {"archer": "C"}, "speaker": "archer", "face": "archer_shocked", "text": "…석상들이 전부 창을 들고 있어요."},
			{"show": {}, "speaker": "narr", "text": "석상 사이에서, 창을 든 기사가 걸어 나온다."},
			{"show": {"warrior": "C"}, "speaker": "warrior", "face": "warrior_rage", "text": "기사단 갑옷…! 원정대다. 아니— 원정대였던 것."},
		],
		# 2층 → 3층 계단: 살아서 내려간 운명은 Lv2 로, 그리고 새 운명 (prototype-v2-spec.md 3.2 계단)
		"f2stairs": [
			{"speaker": "narr", "text": "계단은 더 깊이 이어진다. 아래에서 탄내가 올라온다."},
			{"if": {"brun": "alive"}, "show": {"warrior": "L", "archer": "C", "noel": "FR"}, "speaker": "warrior", "face": "warrior_stern", "text": "…아까 그 창. 한 뼘만 더 왔으면 끝이었다."},
			{"if": {"brun": "alive"}, "speaker": "archer", "face": "archer_smile", "text": "운이 좋았던 거예요. 그쵸, 노엘?"},
			{"if": {"brun": "alive"}, "omen": {"card": "warrior_death", "clarity": 1.0, "taut": ["warrior"], "dim": 0.3}},
			{"if": {"brun": "alive"}, "speaker": "inner", "text": "운이 아니다. 미뤘을 뿐이다."},
			{"call": "descend"},
			{"if": {"brun": "alive"}, "omen_levelup": true},
			{"if": {"brun": "alive"}, "speaker": "inner", "text": "…카드가 바뀌었다. 3층. 이번엔— 꼬챙이."},
			{"if": {"brun": "alive"}, "speaker": "system", "text": "**살아서 층을 내려가면 미뤄진 운명은 더 잔혹해집니다(Lv2).** 다음 층에서 다시 시도가 오고, 더 높은 Lv 에서 받아들이면 상속 카드도 같은 Lv 로 더 강해집니다."},
			{"if": {"brun": "alive"}, "omen_end": true},
			{"if": {"brun": "dead"}, "show": {"archer": "C", "noel": "FR"}, "speaker": "archer", "face": "archer_hollow", "text": "……"},
			{"if": {"brun": "dead"}, "speaker": "archer", "face": "archer_grief", "text": "브룬힐드는… 제 등을 맡긴다고 했었는데."},
			{"if": {"brun": "alive"}, "omen": {"card": "", "clarity": 0.0, "faint": ["warrior", "archer"], "dim": 0.3}},
			{"if": {"brun": "dead"}, "omen": {"card": "", "clarity": 0.0, "faint": ["archer"], "dim": 0.3}},
			{"speaker": "inner", "text": "…또, 비치기 시작했다."},
			{"call": "fate:archer_burn"},
			{"omen_sharpen": {"card": "archer_death", "taut": ["archer"]}},
			{"if": {"brun": "alive"}, "speaker": "inner", "text": "둘이다. 이제 둘의 죽음을, 쥐고 있다."},
			{"if": {"brun": "dead"}, "speaker": "inner", "text": "브룬힐드 다음은, 엘리안."},
			{"omen_end": true},
			{"call": "heal"},
			{"show": {}, "speaker": "narr", "text": "3층 — 불탄 예배당."},
		],
		# ── 3층 ──
		"f3chapel": [
			{"show": {"archer": "C"}, "speaker": "archer", "face": "archer_shocked", "text": "…탄내. 여기서 누가 태워졌어."},
			{"if": {"brun": "alive"}, "show": {}, "speaker": "inner", "text": "그을린 기둥마다 쇠꼬챙이. 미뤄 둔 그 죽음이, 이 층에서 다시 온다."},
			{"show": {}, "speaker": "inner", "text": "그리고 이 탄내. 엘리안의 불도, 이 층에 있다."},
		],
		"f3pyre": [
			{"show": {"archer": "C"}, "speaker": "archer", "face": "archer_shocked", "text": "…화형대."},
			{"show": {}, "speaker": "narr", "text": "화형대 뒤에서 불을 든 사제가 돌아선다."},
			{"speaker": "inner", "text": "저 불이다. 카드 속에서 엘리안을 삼키던 불."},
		],
	},

	# VN 장면 위쪽 작은 제목 (방 이름)
	"eventTitles": {"corridor": "장례 회랑", "hall": "안치 홀", "prayer": "광신도 기도실", "gravekeeper": "무덤지기", "buried": "순장된 자의 방",
		"corpse": "핏자국 통로 끝", "chapel": "촛불 예배당", "training": "무너진 훈련장", "stall": "묘지기의 좌판", "footprints": "발자국 방",
		"stairs": "계단 앞 홀", "deep": "가장 깊은 곳", "emptycamp": "곁방",
		"f2corridor": "창 함정 회랑", "f2ossuary": "기사단 납골당", "f2stairs": "3층으로 내려가는 계단", "f3chapel": "불탄 예배당 회랑", "f3pyre": "화형대 광장"},
	# 훈련 결과 한 줄 ({card} = 강화한 카드 이름, {summary} = 바뀐 수치)
	"trainResult": "{card} 강화 — {summary}",

	# ───────────── 지도 (대본 v3 2장 · vertical-slice.md 튜토리얼 지도 초안) ─────────────
	"map": {
		"title": "장례 탑 1층",
		"floors": {1: "장례 탑 1층", 2: "2층", 3: "3층"},
		# 방 종류 이름 (지도 아이콘 범례·설명)
		"types": {"battle": "전투", "elite": "강적", "event": "사건", "rest": "휴식", "train": "훈련", "trade": "거래", "omen": "전조",
			"camp": "캠프", "hub": "홀", "stairs": "계단", "boss": "층의 끝"},
		"legend": "교차한 칼: 전투 · 해골: 강적 · 물음표: 사건 · 촛불: 휴식 · 교차한 창: 훈련 · 관과 동전: 거래 · 눈: 전조",
		# 방 이름·설명 (설명은 들어가기 전에 보이는 정도만)
		"rooms": {
			"camp": {"name": "곁방", "desc": "탑 입구의 곁방. 지난밤 묵은 곳."},
			"corridor": {"name": "장례 회랑", "desc": "벽감마다 관이 박힌 긴 회랑."},
			"hall": {"name": "안치 홀", "desc": "관이 층층이 쌓인 둥근 홀. 길이 여러 갈래로 나 있다."},
			"prayer": {"name": "광신도 기도실", "desc": "기도 소리가 들린다."},
			"gravekeeper": {"name": "무덤지기", "desc": "기도실 안쪽을 무언가가 막고 있다. 더 강하지만 보상이 크다(희귀 카드)."},
			"buried": {"name": "순장된 자의 방", "desc": "못이 박힌 관에서 소리가 난다."},
			"corpse": {"name": "핏자국 통로 끝", "desc": "핏자국이 막다른 벽까지 이어져 있다."},
			"stall": {"name": "묘지기의 좌판", "desc": "노엘의 HP를 대가로 카드나 촛불을 얻는다."},
			"stairs": {"name": "계단 앞 홀", "desc": "이 층 가장 깊은 곳으로 내려가는 계단."},
			"chapel": {"name": "촛불 예배당", "desc": "쉬어 갈 수 있다. 모두 HP 회복, 최대 HP가 오른다."},
			"training": {"name": "무너진 훈련장", "desc": "합을 맞춘다. 카드 1장을 강화한다."},
			"footprints": {"name": "발자국 방", "desc": "바닥이 이상하게 꺼져 있다."},
			"deep": {"name": "가장 깊은 곳", "desc": "이 층의 끝. 들어가면 돌아올 수 없다."},
		},
		"burned": "촛불 하나가 탔다 — 남은 촛불 {n}개", "darker": "촛불이 없다 — 어둠이 깊어진다 ({n}단계)",
		"here": "지금 여기", "visited": "지나간 방 — 공짜로 지나간다", "cost": "처음 들어가면 촛불 1개가 탄다", "costDark": "촛불이 없다 — 들어가면 어둠이 깊어진다",
		"free": "촛불이 타지 않는다", "locked": "아직 갈 수 없다", "enter": "들어간다", "move": "이동", "lantern": "랜턴", "candles": "촛불 {n}개",
		"darkness": "어둠 {n}단계", "omen": "전조를 보았다 — 층 끝 전투는 가려지지 않는다", "tapAgain": "한 번 더 누르면 들어갑니다",
	},

	# ───────────── 5.3 데스신 자막 (세라피나 6컷: C1 돌아봄 · C2 손을 뻗음 · C3a 첫 번째 밟힘 · C3b 엎드린 채 손을 뻗음 · C4 마지막 밟힘 · C6 발이 들린 뒤) ─────────────
	# 세라피나는 자기가 죽는 걸 모른다 — 갑작스러운 죽음에 당혹스러워한다
	"cutLines": {
		"C1": [{"who": "hero", "text": "어? 잠깐, 이거—"}],
		"C2": [{"who": "hero", "text": "노엘, 손—"}],
		"C3b": [{"who": "hero", "text": "어, 팔이… 왜… 노엘, 이상해, 안 움직여…"}],
	},
	# 5.4 사망 직후 남은 동료의 반응 (안내 뒤). pause: 그 대사 뒤에 더 머무는 시간(ms) / faces: 글자가 다 나온 뒤 차례로 바뀌는 표정
	"reactions": [
		{"who": "archer", "faces": ["archer_shocked", "archer_grief"], "text": "대장! 대장!!", "pause": 900},
		{"who": "warrior", "face": "warrior_grief", "text": "엘리안, 일어나. 또 내려와. 뛰어!", "pause": 400},
	],
	# 5.4 노엘의 손에 남은 카드 — 이제야 문구가 보인다
	"deathCardShown": "「{card}」 — “{text}”",

	# 전투에서 전멸했을 때 (그 전투 처음부터)
	"wipe": {
		"normal": {"title": "전멸", "text": "노엘의 눈앞에서 파티가 쓰러졌다.", "button": "다시 — 이 전투 처음부터"},
	},

	# ═══════════════ 2·3층 — 1차 시험판 v2 (docs/prototype-v2-spec.md 3장) — 대사는 모두 [임시] ═══════════════
	# 운명의 시도 (2026-11-21 죽음 카드 컨셉 변경: 받아들인다 = 죽음이 일어남(상속 + 유품) / 거스른다 = 산다(흉터 — 붉은 실은 나중))
	"fate": {
		"choiceTitle": "운명의 시도",
		"choiceText": "{name}의 죽음이 왔다.",
		"offer": "받아들인다 — {name}의 죽음",
		"defy": "거스른다 — 운명을 비튼다 (흉터 {n})",
		"defyNote": "받아들이면 그 죽음의 힘과 {name}의 유품이 손에 들어온다. 거스르면 살지만, 운명은 다음 층으로 미뤄져 더 잔혹하게 온다. 흉터 {n}장이 노엘 덱에 새겨진다.",
		"gainInherit": "「{card}」 — 덱에 들어왔다",
		"gainScar": "흉터 {n}장이 노엘의 손등에 새겨졌다",
		"postponed": "운명이 미뤄졌다. 다음에는 더 잔혹하게 온다.",
		# 집행자를 먼저 쓰러뜨렸을 때: 쓰러지는 그 순간 운명이 온다
		"dying": [{"who": "inner", "text": "(쓰러지면서도— 운명은 멈추지 않는다.)"}],
		# 운명마다: trap(시도가 온 순간) / offered(받아들인 뒤) / defied(거스른 뒤). trap2 는 2단계일 때
		# 세라피나(튜토리얼, 거스를 수 없음): 「짓밟기」가 내려오는 순간 손패의 뒤집힌 카드가 저절로 뒤집힌다 → 속마음 → 데스신 (대본 v3 5.2)
		"hero_stomp": {
			"trap": [{"who": "inner", "text": "알고 있었는데."}],
		},
		"warrior_pierce": {
			"trap": [{"who": "inner", "text": "(지금이다. 이 창이, 그녀를 꿰뚫는다.)"}],
			"trap2": [{"who": "inner", "text": "(또 왔다. 미뤄 둔 그 죽음이— 이번엔 꼬챙이가 되어.)"}],
			"offered": [{"who": "archer", "face": "archer_shocked", "text": "브룬힐드!!"}, {"who": "inner", "text": "(…막지 않았다.)"}],
			"defied": [{"who": "inner", "text": "(손등이 찢어진다. 운명을 거스른 값이다.)"},
				{"who": "warrior", "face": "warrior_shocked", "text": "…방금, 뭐였지. 노엘, 네가 날 당겼나?"},
				{"who": "noel", "text": "……"}],
		},
		"archer_burn": {
			"trap": [{"who": "inner", "text": "(…불길이, 엘리안에게.)"}, {"who": "inner", "text": "(지금이다. 이 불이 그녀를 태운다.)"}],
			"offered": [{"who": "inner", "text": "(…막지 않았다.)"}],
			"defied": [{"who": "inner", "text": "(불길이 그녀 앞에서 갈라진다. 손등이 탄다.)"},
				{"who": "archer", "face": "archer_shocked", "text": "…뜨거, 워…? 아니, 안 뜨거워. 노엘, 지금…"},
				{"who": "noel", "text": "……"}],
		},
	},

	# 데스신 자막 (game_data.gd deathScenes). lv2 는 2단계 죽음일 때 이 줄로 바뀐다
	"deathScenes": {
		"warrior_pierce": {
			"lines": {"W1": [{"who": "warrior", "text": "…노엘, 물러—"}]},
			"lv2": {"W1": [{"who": "warrior", "text": "……."}], "W2": [{"who": "system", "text": "꼬챙이에 꿰인 채, 그녀는 내려오지 못했다."}]},
		},
		"archer_burn": {
			"lines": {"A1": [{"who": "archer", "text": "노엘—! 뜨거, 뜨거워…!"}]},
			"lv2": {"A1": [{"who": "archer", "text": "……!!"}]},
		},
	},

	# 전투 중 동료 사망 직후 남은 동료의 반응 (C8 처럼). 죽은 동료는 말하지 않는다
	"reactionsBy": {
		"warrior": [{"who": "archer", "faces": ["archer_shocked", "archer_grief"], "text": "브룬힐드!!", "pause": 1200}],
		"archer": [{"who": "warrior", "faces": ["warrior_shocked", "warrior_grief"], "text": "…엘리안.", "pause": 1000}],
	},

	# 1층 끝 (빈 캠프 뒤 → 2층) — 대본 v3 6장 「1층 — 끝」
	"chapter1": {
		"title": "1층 — 끝",
		"lines": [],
		"button": "아래로 — 2층",
	},

	# 시험판 끝 — 결과 요약
	"result": {
		"title": "시험판 끝",
		"hero": "1층 가장 깊은 곳에서 짓밟혀 죽었다. (용사의 죽음)",
		"offered": "{floor}층에서 운명대로 죽었다 — 죽음 카드 Lv{lv}",
		"alive": "살아 있다 — 운명은 미뤄졌다: {floor}층에서 Lv{lv}",
		"saved": "운명을 모두 거슬러, 구했다.",
		"noFate": "{name}에게는 아직 운명이 오지 않았다.",
		"scars": "흉터 {n}장",
		"inherits": "상속 카드: {list}",
		"next": "다음 층에서는: {list}",
		"nextItem": "{name} {lv}단계",
		"nextNone": "쥐고 있는 운명이 없다.",
		"again": "처음부터",
		"floor2": "2층부터 다시",
	},
}
