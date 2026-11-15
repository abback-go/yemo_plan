## script_data.gd — 대본: 대사·안내 상자·선택지·장면 문구를 모두 모아 둔 파일.
## 기준: docs/tutorial-script.md v0.6 (사용자 확정). "v0.1 대사 그대로" 구간은 prototype/js/data.js 에서 그대로 옮겼다.
## 수치·배치는 data/game_data.gd. 대본이 바뀌면 이 파일만 바꾸면 된다.
##
## ── 줄(대사) 형식 ──────────────────────────────────────────────
##  비주얼노벨 장면(캠프·이벤트·빈 캠프): {"speaker", "text", "face"?, "show"?, "tag"?}
##    speaker: hero | warrior | archer | noel | inner(노엘 속마음) | narr(내레이션) | system(안내 상자)
##    face: 표정 그림 이름(예: "hero_smile" → face_hero_smile.png). 없으면 스탠딩에서 잘라 쓴 얼굴
##    show: 등장 인물과 자리 {"hero": "C", ...} (자리: FL L C R FR). {} = 모두 퇴장
##    tag: 그 인물 스탠딩에 이름표를 붙인다(파티 소개). "" = 이름표를 뗀다
##  그 밖의 줄(명령):
##    {"choice": [{"text", "value", "lines": [...]}], "key": 플래그 이름}  선택지 (고른 값이 st.flags[key])
##    {"if": {플래그: 값}, ...}   그 플래그일 때만 나오는 줄 (예: {"sera": "smile"} = 계단에서 웃어 줬을 때)
##    {"result": "보상 문구"}     가운데 결과 상자 ({upgrade} = 강화한 카드)
##    {"call": "train"}          훈련(카드 강화) 화면
##    {"cg": "그림"}             그 줄부터 배경을 이 그림으로 (예: 휴식의 밤 CG)
##    {"omen": {...}}            죽음 카드가 손 위로 떠오르는 연출 (game_data.gd "omen" 참고)
##        card: 카드 id("" = 아직 누구인지 모르는 흐린 카드) / clarity: 0(알아볼 수 없음)~1(문구까지 또렷)
##        taut: 팽팽해지는 실의 동료 / faint: 아주 희미하게 떨리기만 하는 실의 동료들 / dim: 화면을 어둡게
##    {"omen_end": true}         떠오른 카드가 손 안으로 가라앉듯 사라진다
##  전투 중 대사(guide): {"who", "text", "face"?, "faces"?} — who 는 위 speaker 와 같고 system = 안내 상자
##  안내 상자 글: 「카드 이름」·**강조** 는 색을 달리해 보여 준다. 줄바꿈 \n, 목록은 "· "
##  안내 상자는 화면 위쪽에 뜨고 탭해야 넘어가며(떠 있는 동안 진행이 멈춘다), 같은 안내는 한 번만 나온다
##  (다시 하기 후에도 다시 나오지 않음 — 본 안내는 브라우저 저장소에 기록. 주소 ?guides=reset 으로 초기화).
## ───────────────────────────────────────────────────────────
class_name ScriptData
extends Object

const S := {
	"meta": {
		"title": "죽음을 보는 마녀",
		"subtitle": "(가제) · 튜토리얼",
		"startButton": "시작",
		"note": "마우스·터치로 플레이 · 휴대폰은 가로 화면",
	},
	"names": {"hero": "세라피나", "warrior": "브룬힐드", "archer": "엘리안", "noel": "노엘", "witch": "노엘", "inner": "노엘", "narr": "", "system": ""},
	"roles": {"hero": "용사", "warrior": "전사", "archer": "궁수", "noel": "마녀", "witch": "마녀"},
	# 파티 소개 이름표 (대본 1장)
	"tags": {"hero": "세라피나 · 용사", "warrior": "브룬힐드 · 전사", "archer": "엘리안 · 궁수", "noel": "노엘 · 마녀"},

	# 화면 곳곳의 짧은 문구
	"ui": {
		"endTurn": "턴 종료", "deck": "덱", "discard": "버림", "witchSub": "마녀 · 나", "down": "쓰러짐", "unusable": "사용 불가", "locked": "잠김",
		"turn": "{n}턴", "giantTurn": "{n}턴 · 짓밟기까지 {left}", "enemyPhase": "적의 차례", "floorBattle": "{n}층",
		"innerName": "노엘 (속마음)", "systemName": "안내", "skip": "건너뛰기 ▶▶", "cutHint": "탭: 다음", "tapNext": "탭: 다음 ▼",
		"immune": "통하지 않는다", "reshuffle": "버림 더미를 섞어 새 덱으로", "handFull": "손패가 가득 찼다",
		"allyDown": "{name} 쓰러짐", "relic": "{name}의 카드 {n}장이 유품이 되었다", "wound": "{name}의 카드 1장이 「상처」가 되었다",
		"pickAlly": "새로 맞을 아군을 고르세요 · 빈 곳: 취소", "dropHere": "놓으면 사용", "dragUp": "위로 끌어올려 사용",
		"needIntent": "예고된 공격에 놓아야 한다", "cantHere": "여기에는 낼 수 없다",
		"map": "지도", "mapClose": "닫기", "mapTitle": "지도 — 잿빛 성당",
		"mapLegend": "칼: 전투 · 물음표: 모르는 방 · 불꽃: 휴식 · 교차한 칼: 훈련 · 계단: 다음 층",
		"mapHere": "지금 여기", "mapMarkHint": "붉은 실 표식",
		"pathTapAgain": "한 번 더 누르면 들어갑니다",
		"trainTitle": "강화할 카드를 고르세요", "trainHint": "고른 카드 1장이 강화된다 (이름 옆 +)",
		"resultOk": "확인", "rotate": "가로로 돌려 주세요", "rotateSub": "이 게임은 가로 화면(16:9)으로 플레이합니다",
		"loading": "불러오는 중…",
	},
	# 카드를 낼 수 없을 때 짧은 알림 (rules.gd 의 이유 → 화면 문구)
	"reasons": {
		"지금은 낼 수 없다": "지금은 낼 수 없다", "에너지가 부족하다": "에너지가 부족하다", "쓰러진 동료의 카드": "쓰러진 동료의 카드",
		"죽은 동료의 카드": "죽은 동료의 카드", "낼 수 없는 카드": "낼 수 없는 카드", "대상이 없다": "대상이 없다",
	},

	# 잠긴 죽음 카드를 끌거나 눌렀을 때 (매번) — 대본 2장
	"lockedTry": [{"who": "inner", "text": "…아직이다. 이 죽음이 오는 곳은, 여기가 아니다."}],

	# ───────────── 전투 중 안내 (대본 2·5장) ─────────────
	# on: battleStart | turnStart | cardPlayed | redirect | energyOut | enemyPhaseEnd | allyDown | immune | afterDeath | restart | battleWin
	#     | unlock | mapFirst | exploreShown
	# enc: normal(1층) | floor2(2층) | giant / turn: 그 턴에만 / card: 그 카드를 냈을 때 / once: 한 번만
	"guide": [
		# ── 1층 전투 시작 ──
		{"id": "n_start", "on": "battleStart", "enc": "normal", "lines": [
			{"who": "hero", "face": "hero_determined", "text": "광신도 셋. 평소대로 간다. 앞은 내가 연다. 노엘, 운명은 네 몫이야."},
			{"who": "system", "text": "**전투는 차례로 진행됩니다.**\n당신의 차례(카드를 낸다) → 적의 차례(적이 공격한다) → 다시 당신의 차례. 적을 모두 쓰러뜨리면 승리합니다."},
			{"who": "system", "text": "**패배 조건**: 노엘의 HP가 0이 되거나, 동료 셋이 모두 쓰러지면 패배합니다."}]},
		# ── 1턴 시작 ──
		{"id": "n_t1", "on": "turnStart", "enc": "normal", "turn": 1, "lines": [
			{"who": "hero", "face": "hero_calm", "text": "가운데부터 친다. 엘리안, 뒤는 맡겼어."},
			{"who": "system", "text": "**매 턴 카드 5장을 뽑고, 에너지 3을 받습니다.**\n화면 오른쪽 아래 숫자가 남은 에너지입니다."},
			{"who": "system", "text": "**손패의 「용사의 죽음」은 노엘만 볼 수 있는 죽음 카드입니다. 지금은 낼 수 없습니다.**\n· 이 카드는 버려지지 않고 손패에 남아 한 칸을 차지합니다. 그래서 이번 전투에서는 매 턴 **4장**만 새로 뽑습니다."},
			{"who": "system", "text": "**카드 왼쪽 위 숫자가 비용입니다.**\n비용만큼 에너지를 써서 카드를 냅니다."},
			{"who": "system", "text": "**카드 테두리 색은 그 카드의 주인입니다.**\n· 노엘의 카드: 마녀가 직접 행동\n· 동료의 카드: 그 동료가 행동 (세라피나·브룬힐드·엘리안)\n노엘은 동료들의 카드까지 모두 손에 쥐고, 누가 언제 움직일지 정합니다."},
			{"who": "system", "text": "**카드 내는 법**\n· 공격 카드: 끌어서 적 위에 놓습니다.\n· 대상이 없는 카드: 손패 위쪽으로 끌어올려 놓습니다."},
			{"who": "system", "text": "다 냈으면 오른쪽 아래 「턴 종료」. **남은 손패는 버려지고** 다음 턴에 새로 뽑습니다."}]},
		# ── 1턴 중 반응 ──
		{"id": "n_sword", "on": "cardPlayed", "enc": "normal", "card": "holy_slash", "once": true, "lines": [
			{"who": "hero", "face": "hero_smile", "text": "하나. 오늘은 칼이 잘 드네."}]},
		{"id": "n_energy", "on": "energyOut", "enc": "normal", "once": true, "lines": [
			{"who": "system", "text": "에너지를 다 썼습니다. 「턴 종료」를 누르면 적의 차례입니다."}]},
		# ── 첫 적 차례가 끝났을 때 ──
		{"id": "n_intent", "on": "enemyPhaseEnd", "enc": "normal", "once": true, "lines": [
			{"who": "system", "text": "적은 매 턴 시작할 때 **다음에 무엇을 할지 미리 보여 줍니다(「예고」).** 적 머리 위의 표시가 예고입니다."}]},
		# ── 2턴 시작 ──
		{"id": "n_t2", "on": "turnStart", "enc": "normal", "turn": 2, "lines": [
			{"who": "hero", "face": "hero_determined", "text": "셋 다 엘리안을 노린다. 브룬힐드, 엘리안 쪽 막아. 노엘, 누가 맞을지는 네가 정해."},
			{"who": "warrior", "face": "warrior_stern", "text": "맡겨라. 절반은 방패가 먹는다."},
			{"who": "system", "text": "**「예고」 읽기**: 칼 아이콘 = 공격, 숫자 = 피해, 선 = 맞을 대상.\n예고를 누르고 있으면 누구를 노리는지 선이 보입니다."},
			{"who": "system", "text": "**노엘의 싸움은 「피해 옮기기」입니다.** 공격을 막는 것이 아니라, **누가 맞을지를 바꿉니다.**\n· 「운명 전가」: 예고 위에 놓은 뒤, 새로 맞을 동료를 고릅니다.\n· 「대신 받기」: 노엘이 대신 맞습니다.\n· 「감싸기」: 브룬힐드가 대신 맞되, 피해는 절반입니다."},
			{"who": "system", "text": "엘리안의 HP는 12. 셋이 모두 엘리안을 때리면 엘리안이 쓰러집니다. **공격 하나라도 다른 사람에게 옮기세요.**"}]},
		# ── 2턴 중 반응 ──
		{"id": "n_redirect", "on": "redirect", "enc": "normal", "once": true, "lines": [
			{"who": "hero", "face": "hero_smile", "text": "좋아, 그 수야. 역시 우리 마녀지."}]},
		{"id": "n_cover", "on": "cardPlayed", "card": "cover", "once": true, "lines": [
			{"who": "warrior", "face": "warrior_stern", "text": "…이 정도는 아무것도 아니다."}]},
		{"id": "n_down", "on": "allyDown", "once": true, "lines": [
			{"who": "hero", "face": "hero_shocked", "text": "버텨! 금방 끝낸다!"},
			{"who": "system", "text": "**쓰러진 동료는 이번 전투에서 행동할 수 없습니다.** 그 동료의 카드도 낼 수 없습니다."},
			{"who": "system", "text": "전투가 끝나면 HP 1로 일어나지만, 그 동료의 카드 1장이 **「상처」**로 바뀝니다. 상처 카드는 낼 수 없고 손패만 차지합니다."}]},
		# ── 1층 승리 ──
		{"id": "n_win", "on": "battleWin", "enc": "normal", "lines": [
			{"who": "hero", "face": "hero_smile", "text": "정리 끝. 다친 사람?"},
			{"who": "archer", "face": "archer_smile", "text": "저 멀쩡해요. 노엘 덕분에요."},
			{"who": "warrior", "face": "warrior_stern", "text": "아래층에서 냄새가 더 짙어진다. 쉬지 말고 가자."}]},

		# ── 2층 광신도 (대본 5.1) ──
		{"id": "f2_start", "on": "battleStart", "enc": "floor2", "lines": [
			{"who": "hero", "face": "hero_determined", "text": "둘. 빨리 끝내고 내려가자."},
			{"who": "system", "text": "배운 대로 해 보세요. 「예고」를 보고, 위험한 공격은 옮기세요."}]},

		# ── 거대 존재 (대본 5.2~5.7) ──
		{"id": "g_start", "on": "battleStart", "enc": "giant", "lines": [
			{"who": "hero", "face": "hero_determined", "text": "진형 유지! 저건… 내가 막는다!"},
			{"who": "system", "text": "거대한 존재의 「예고」를 보세요. **3턴째에 「짓밟기」가 옵니다.** 짓밟기를 맞으면 모두 죽습니다."}]},
		# 5.3 1턴 — 죽음 카드가 풀린다 (자물쇠가 부서지는 연출 뒤)
		{"id": "g_t1", "on": "turnStart", "enc": "giant", "turn": 1, "lines": [
			{"who": "inner", "text": "…왔다. 사흘 동안 본, 그 장면이."},
			{"who": "inner", "text": "이 카드를 내면, 그 죽음은 지금 일어난다. 세라 한 사람으로 끝난다."},
			{"who": "inner", "text": "내지 않으면— 저 발은 우리 모두를 덮친다."},
			{"who": "system", "text": "**죽음 카드 — 노엘만이 볼 수 있는 카드입니다.**\n· 노엘은 동료가 어디서, 어떻게 죽을지를 미리 봅니다. 그 죽음이 카드가 되어 손에 들어옵니다.\n· 죽음 카드를 내면 **그 동료는 그 자리에서 죽습니다.** 그리고 노엘은 그 죽음의 힘을 얻습니다.\n· 내지 않고 버티면, 그 죽음이 정해진 자리에서 **위험이 모두에게 닥칩니다.**"},
			{"who": "system", "text": "「용사의 죽음」은 이제 낼 수 있습니다. **비용 0**이며, 턴이 끝나도 버려지지 않습니다. 낼지 말지는 당신이 정합니다."},
			{"who": "system", "text": "거대한 존재에게는 지금 어떤 공격도 통하지 않습니다."}]},
		{"id": "g_immune", "on": "immune", "once": true, "lines": [
			{"who": "warrior", "face": "warrior_shocked", "text": "…흠집 하나 안 난다. 우리 공격이, 전부."}]},
		{"id": "g_immune_sword", "on": "immune", "card": "holy_slash", "once": true, "lines": [
			{"who": "hero", "face": "hero_shocked", "text": "성검이… 들어가질 않아? 이런 건, 처음이야."}]},
		{"id": "g_t2", "on": "turnStart", "enc": "giant", "turn": 2, "lines": [
			{"who": "hero", "face": "hero_shocked", "text": "기둥이 무너진다! 다들 버텨!"}]},
		{"id": "g_t3", "on": "turnStart", "enc": "giant", "turn": 3, "lines": [
			{"who": "hero", "face": "hero_calm", "text": "노엘. 늘 하던 말이야. 카드는 아끼다간 죽는 거야."},
			{"who": "hero", "face": "hero_smile", "text": "…써야 할 땐, 망설이지 마."}]},
		# 5.6 사망 직후
		{"id": "g_after", "on": "afterDeath", "lines": [
			{"who": "inner", "text": "그녀가 죽은 방식이, 내 손에 남았다."},
			{"who": "system", "text": "**죽은 동료가 남기는 것**\n· **「짓밟힘」**: 동료를 죽인 그 죽음이 노엘의 카드가 되었습니다. 이번 턴에는 비용 0. 손패 위쪽으로 끌어올려 사용하세요.\n· **「유품」 카드**: 세라피나의 카드는 「유품」으로 바뀌었습니다. 더 강하지만, 낼 때마다 노엘의 HP가 줄어듭니다."}]},
		# 5.7 전멸 — 카드를 내지 않은 미래 (화면이 깨지고 되돌아간 뒤)
		{"id": "g_restart", "on": "restart", "lines": [
			{"who": "inner", "text": "…보였다. 내지 않으면, 이렇게 된다."},
			{"who": "inner", "text": "모두가. 세라도, 브룬힐드도, 엘리안도."},
			{"who": "system", "text": "카드를 내지 않은 미래를 보았습니다. 거대한 존재가 나타난 직후로 돌아갑니다."}]},

		# ── 이동·지도·갈림길 (대본 3장) — 탐색 화면에서 ──
		{"id": "x_map", "on": "mapFirst", "lines": [
			{"who": "hero", "face": "hero_calm", "text": "노엘, 지도 좀 펼쳐 줘. 길이 갈린다."},
			{"who": "system", "text": "**던전은 층을 내려가며 나아갑니다.** 한 층에는 여러 방이 있고, 계단에 닿으면 다음 층으로 내려갑니다."},
			{"who": "system", "text": "**갈림길에서는 한 곳만 고를 수 있습니다.** 고르지 않은 길로는 돌아갈 수 없습니다."},
			{"who": "system", "text": "**지도의 아이콘은 그 방에서 일어날 일입니다.**\n· 칼: 전투\n· 물음표: 무슨 일이 생길지 모르는 방\n· 불꽃: 휴식\n· 교차한 칼: 훈련"},
			{"who": "system", "text": "**붉은 실 표식**: 노엘이 그곳에서 무언가를 본 자리입니다. 지금은 아무 일도 없습니다."}]},
		{"id": "x_fork", "on": "exploreShown", "explore": "fork", "lines": [
			{"who": "archer", "face": "archer_smile", "text": "셋이네요. 어디로 가요?"},
			{"who": "hero", "face": "hero_calm", "text": "노엘이 골라. 네 눈이 우리 길잡이니까."},
			{"who": "system", "text": "**세 길 중 하나를 고르세요.** 길을 누르면 그 길에 대한 설명이 나옵니다. 한 번 더 누르면 들어갑니다."}]},
	],

	# 거대 존재 등장 연출 중 대사 (기존 + 대본 v0.6 5.1 추가)
	"giantAppear": {
		"before": [{"who": "hero", "face": "hero_determined", "text": "…잠깐. 이 그림자는 뭐지?"}],
		"after": [
			{"who": "archer", "face": "archer_shocked", "text": "광신도가… 한 번에…"},
			{"who": "warrior", "face": "warrior_shocked", "text": "원정대가 돌아오지 못한 이유가… 이거였나."}],
	},

	# ───────────── 1. 캠프 — 던전에 온 이유 · 파티 소개 ─────────────
	"camp": [
		{"speaker": "narr", "text": "잿빛 성당. 백 년 전에 무너진 뒤, 광신도들이 숨어든 곳."},
		{"speaker": "narr", "text": "그 깊은 곳에서 그들이 「무언가」를 불러내려 한다는 소식이 왕도에 닿은 건 한 달 전이었다."},
		{"speaker": "narr", "text": "먼저 들어간 기사단 원정대는 돌아오지 않았다. 왕도는 마지막으로, 이 넷을 불렀다."},
		{"speaker": "narr", "text": "무너진 성당의 곁방. 오늘 밤은 여기서 쉬기로 했다."},
		{"speaker": "narr", "text": "모닥불이 타닥거린다. 이 세계에서 따뜻한 건, 이런 불빛 정도뿐이다."},
		# 스튜 장면 (v0.1 그대로)
		{"show": {"warrior": "L", "hero": "C", "archer": "R"}, "speaker": "hero", "face": "hero_smile", "text": "자, 오늘 저녁. 세라피나 특제 스튜야."},
		{"speaker": "archer", "face": "archer_smile", "text": "…대장, 이거 어제랑 같은 거 아니에요?"},
		{"speaker": "hero", "face": "hero_smile", "text": "어제 건 「특제」가 아니었지. 오늘은 소금을 넣었거든."},
		{"speaker": "warrior", "face": "warrior_stern", "text": "소금 넣은 걸 특제라고 부르는 건 대장뿐이다."},
		{"speaker": "hero", "face": "hero_smile", "text": "불만 있으면 내일부터 브룬힐드가 해. 그 방패에다 끓이든가."},
		{"speaker": "warrior", "face": "warrior_stern", "text": "……먹겠다."},
		{"speaker": "archer", "face": "archer_smile", "text": "(웃음) 노엘도 먹어요. 하루 종일 아무것도 안 먹었잖아요."},
		{"show": {"warrior": "FL", "hero": "L", "archer": "C", "noel": "FR"}, "speaker": "noel", "text": "…괜찮아."},
		{"speaker": "hero", "face": "hero_calm", "text": "괜찮긴. 우리 마녀가 굶어서 예지가 흐려지면 큰일이지. 자, 받아."},
		{"speaker": "inner", "text": "그릇이 따뜻하다. 건네는 손도."},
		{"speaker": "hero", "face": "hero_smile", "text": "맛은 기대하지 마. 대신 뜨겁긴 할 거야."},
		{"speaker": "noel", "text": "……뜨거워."},
		{"speaker": "hero", "face": "hero_smile", "text": "거 봐. 살아 있다는 증거야."},
		{"speaker": "archer", "face": "archer_smile", "text": "내일이면 성당 제일 깊은 곳이죠. 이것만 끝내면 왕도에서 또 노래가 나오겠네요. 「잿빛 성당을 연 넷」."},
		{"speaker": "warrior", "face": "warrior_stern", "text": "노래보다 남은 광신도가 먼저다. 냄새가 난다."},
		{"speaker": "archer", "face": "archer_smile", "text": "밥 먹는데 그런 말 하지 마요…."},
		{"speaker": "warrior", "face": "warrior_stern", "text": "기사단 원정대도 돌아오지 못한 곳이다. 노래는 나가서 불러라."},
		{"speaker": "hero", "face": "hero_determined", "text": "그래서 우리가 온 거야. 의식은 내일 끝낸다."},
		# [연출] 파티 소개 — 속마음이 나오는 동안 그 인물이 가운데로 나오고 이름표가 붙은 뒤, 안내 상자
		{"show": {"hero": "C"}, "tag": "hero", "speaker": "inner", "text": "세라피나. 우리 파티의 용사이자 리더."},
		{"speaker": "inner", "text": "저 웃는 얼굴로 늘 맨 앞에 선다. 그녀가 칼을 뽑으면, 길이 열린다."},
		{"speaker": "system", "text": "**세라피나 — 용사 · 파티의 리더.**\n강한 공격으로 적을 쓰러뜨린다. 대표 카드 「성검 베기」."},
		{"show": {"warrior": "C"}, "tag": "warrior", "speaker": "inner", "text": "브룬힐드. 말수가 적은 전사. 저 방패 뒤에서 다친 동료는 없다."},
		{"speaker": "system", "text": "**브룬힐드 — 전사 · 파티의 방패.**\n동료 대신 공격을 받아 낸다. 대표 카드 「감싸기」."},
		{"show": {"archer": "C"}, "tag": "archer", "speaker": "inner", "text": "엘리안. 숲에서 온 엘프 궁수. 몸은 약해도, 그녀의 화살은 빗나가지 않는다."},
		{"speaker": "system", "text": "**엘리안 — 궁수 · 뒤에서 쏘는 엘프.**\n체력은 약하지만 멀리서 정확히 맞힌다. 대표 카드 「저격」."},
		{"show": {"noel": "C"}, "tag": "noel", "speaker": "inner", "text": "그리고 나, 노엘. 이 파티의 마녀."},
		{"speaker": "inner", "text": "모두는 내가 앞날을 읽는다고 믿는다. …틀린 말은 아니다."},
		{"speaker": "inner", "text": "이 의뢰를 받자고 한 것도, 나였다."},
		{"speaker": "inner", "text": "성당 깊은 곳에 나와 같은 마녀가 있었다는, 오래된 소문 하나 때문에."},
		{"speaker": "system", "text": "**노엘 — 마녀 · 당신.**\n동료들의 카드까지 모두 손에 쥐고, 누가 언제 움직일지 정한다. 직접 싸우기보다 **누가 공격을 받을지 바꾸는** 것이 노엘의 싸움이다."},
		# 작전 장면 (v0.1 그대로)
		{"show": {"warrior": "FL", "hero": "L", "archer": "C", "noel": "FR"}, "tag": "", "speaker": "hero", "face": "hero_determined", "text": "셋이든 서른이든, 평소대로야. 앞은 내가 연다."},
		{"speaker": "warrior", "face": "warrior_stern", "text": "열린 앞을 지키는 건 내 방패다."},
		{"speaker": "hero", "face": "hero_smile", "text": "그래. 나는 베고, 너는 막고. 몇 년째 그 순서지."},
		{"speaker": "archer", "face": "archer_smile", "text": "저는요?"},
		{"speaker": "hero", "face": "hero_smile", "text": "엘리안은 늘 하던 대로 뒤에서 우리 등을 봐 줘. 네 화살이 우리 목숨줄이야."},
		{"speaker": "archer", "face": "archer_smile", "text": "맡겨 주세요. 한 발도 안 놓칠게요."},
		{"speaker": "warrior", "face": "warrior_stern", "text": "지난번엔 세 발 놓쳤다."},
		{"speaker": "archer", "face": "archer_shocked", "text": "그건 바람이 불어서였어요!"},
		{"speaker": "hero", "face": "hero_smile", "text": "(웃음) 됐어, 됐어. 그 바람 덕에 내가 한 마리 더 벴으니까."},
		{"show": {"warrior": "FL", "hero": "C", "archer": "L", "noel": "FR"}, "speaker": "hero", "face": "hero_calm", "text": "노엘. 내일은 뭐가 보여? 네 예지가 틀린 적은 없잖아."},
		{"speaker": "noel", "text": "…늘 보이던 것."},
		{"speaker": "hero", "face": "hero_smile", "text": "그럼 됐어. 늘 하던 말이지만, 한 번 더."},
		{"speaker": "hero", "face": "hero_calm", "text": "카드는 아끼다간 죽는 거야. 써야 할 땐 망설이지 마."},
		{"speaker": "noel", "text": "…………"},
		{"speaker": "narr", "text": "노엘은 목에 건 낡은 카드 묶음을 쥐었다. 오늘따라 묶음이 무겁다."},
		{"speaker": "hero", "face": "hero_smile", "text": "걱정 마. 우리가 누구야. 이 넷이 함께한 뒤로, 아무도 안 죽었어."},
		# [연출] 이미 아는 죽음 — 화면이 아주 살짝 어두워지고(효과음 없이), 손 위에 카드가 또렷이 떠오른다. 세라피나 쪽 실이 팽팽하게
		{"omen": {"card": "hero_death", "clarity": 1.0, "taut": ["hero"], "dim": 0.22}},
		{"speaker": "inner", "text": "…알고 있다. 사흘 전, 이 카드가 처음 비친 날부터."},
		{"speaker": "inner", "text": "의뢰를 받아들인, 바로 다음 날이었다."},
		{"speaker": "inner", "text": "내일. 성당 가장 깊은 곳. 거대한 발 아래."},
		{"speaker": "inner", "text": "그리고 이 카드에 적힌 것은, 누구에게도 말할 수 없다."},
		{"speaker": "inner", "text": "말하는 순간, 들은 사람은 모두 죽는다."},
		# 카드가 손 안으로 가라앉듯 사라진다. 세라피나는 아무것도 모른 채 웃고 있다
		{"omen_end": true, "face": "hero_smile"},
		# 바다 약속 장면 (v0.1 그대로)
		{"speaker": "archer", "face": "archer_smile", "text": "대장, 이 일 끝나면 뭐 할 거예요?"},
		{"speaker": "hero", "face": "hero_smile", "text": "음… 바다. 남쪽 바다를 한 번 보고 싶어. 다 같이 가자."},
		{"speaker": "warrior", "face": "warrior_stern", "text": "바다는 짜다."},
		{"speaker": "hero", "face": "hero_smile", "text": "내 스튜보다는 덜 짜겠지."},
		{"speaker": "archer", "face": "archer_smile", "text": "그럼 저는 바닷가에서 노래할게요. 엘프 노래, 아직 한 번도 안 들려 드렸잖아요."},
		{"speaker": "hero", "face": "hero_smile", "text": "약속했다? 노엘, 너도 와야 해."},
		{"speaker": "noel", "text": "…응."},
		{"speaker": "inner", "text": "남쪽 바다. 기억해 둘게."},
		{"speaker": "warrior", "face": "warrior_stern", "text": "이제 자라. 불은 내가 본다."},
		{"speaker": "hero", "face": "hero_calm", "text": "교대는 나야. 새벽에 깨워."},
		{"speaker": "warrior", "face": "warrior_stern", "text": "대장은 자라. 내일 제일 많이 싸우는 건 대장이다."},
		{"speaker": "hero", "face": "hero_smile", "text": "…그럼 고맙게. 다들, 잘 자."},
		{"show": {}, "speaker": "narr", "text": "불씨가 하나둘 사그라든다."},
		{"speaker": "inner", "text": "모두가 잠든 뒤에도, 나는 오래 눈을 감지 못했다."},
		{"speaker": "narr", "text": "다음 날 — 성당의 가장 깊은 곳."},
	],

	# ───────────── 3. 갈림길 이벤트 / 4. 계단 / 7. 빈 캠프 ─────────────
	"events": {
		# 3.3 왼쪽: 시체 발견
		"corpse": [
			{"speaker": "narr", "text": "핏자국은 막다른 벽에서 끝났다."},
			{"speaker": "narr", "text": "벽에 기대 앉은 여자. 오래전에 죽었다. 검은 로브, 그리고 손에 쥔 카드 묶음."},
			{"speaker": "archer", "face": "archer_shocked", "text": "…마녀, 예요? 노엘처럼."},
			{"speaker": "narr", "text": "바닥에 카드 십수 장이 흩어져 있다. 모두 얼굴이 검게 타 있다."},
			{"speaker": "hero", "face": "hero_calm", "text": "가엾게도. 동료들은 다 어디 가고… 혼자 남았던 거야."},
			{"speaker": "inner", "text": "아니. 혼자 남은 게 아니다."},
			{"speaker": "inner", "text": "저 탄 얼굴들이 그녀의 동료다. 저 카드는 전부… 이미 쓴 거다."},
			{"speaker": "warrior", "face": "warrior_stern", "text": "벽에 눈금이 있다. 날을 센 건가."},
			{"speaker": "warrior", "face": "warrior_stern", "text": "원정대는 아니다. 훨씬 오래됐다."},
			{"speaker": "inner", "text": "소문은 사실이었다. 나보다 먼저, 여기까지 온 마녀."},
			{"speaker": "inner", "text": "…나도 언젠가, 이렇게 끝나는 걸까."},
			{"speaker": "hero", "face": "hero_determined", "text": "묻어 줄 시간은 없어. 대신 기억하자. 가자."},
			{"speaker": "system", "text": "이 길에서는 이야기를 얻었습니다. 이 마녀가 누구였는지는 언젠가 알게 됩니다."},
		],
		# 3.4 가운데: 휴식 (밤 CG). 수치는 game_data.gd "rest"
		"rest": [
			{"speaker": "narr", "text": "꺼지지 않은 촛불 몇 개. 누군가 이곳에서 기도하다 떠났다."},
			{"show": {"warrior": "L", "hero": "C", "archer": "R"}, "speaker": "hero", "face": "hero_smile", "text": "여기서 잠깐 눈 붙이자. 불침번은 순서대로."},
			{"show": {}, "cg": "ev_rest_night.png", "speaker": "narr", "text": "밤."},
			{"speaker": "narr", "text": "엘리안은 브룬힐드의 어깨에 기대 잠들었다. 브룬힐드는 움직이지 않는다."},
			{"speaker": "noel", "text": "…안 무거워?"},
			{"speaker": "warrior", "face": "warrior_stern", "text": "방패보다 가볍다."},
			{"speaker": "warrior", "face": "warrior_stern", "text": "이 녀석은 처음 왔을 때 활시위도 제대로 못 당겼다. 지금은 내 등을 맡긴다."},
			{"speaker": "warrior", "face": "warrior_stern", "text": "…너도 자라, 노엘. 네가 흐려지면 우리가 다 흐려진다."},
			{"speaker": "noel", "text": "…응."},
			{"call": "rest"},
			{"speaker": "system", "text": "**휴식했습니다.** 모두 HP를 전부 회복하고 최대 HP가 올랐습니다. (동료 +3, 노엘 +2)"},
		],
		# 3.5 오른쪽: 훈련 (갈림길 배경 + 스탠딩·표정 + 카드 강화)
		"train": [
			{"show": {"warrior": "L", "hero": "C", "archer": "R"}, "speaker": "warrior", "face": "warrior_stern", "text": "아래층에 내려가기 전에 한 번 맞춰 보자."},
			{"speaker": "hero", "face": "hero_smile", "text": "좋지. 노엘, 네 예지에 맞춰서 우리가 한 박자 빨리 들어갈게."},
			{"speaker": "system", "text": "**카드 1장을 강화합니다.** 3장 중 하나를 고르세요. 강화된 카드는 이름 옆에 「+」가 붙습니다."},
			{"call": "train"},
			{"if": {"upgraded": "holy_slash"}, "speaker": "hero", "face": "hero_determined", "text": "더 깊게. 다시."},
			{"if": {"upgraded": "snipe"}, "speaker": "archer", "face": "archer_smile", "text": "바람 계산, 이번엔 완벽해요."},
			{"if": {"upgraded": "cover"}, "speaker": "warrior", "face": "warrior_stern", "text": "받는 법을 바꿨다. 덜 아프다."},
			{"if": {"upgraded": "curse_flame"}, "speaker": "inner", "text": "불꽃이 손끝에서 더 오래 남는다."},
		],
		# 3.6 + 4. 계단 — 세라피나와의 대화. 선택은 C1 마지막 말·빈 캠프 대사에만 영향(수치 변화 없음)
		"stairs": [
			{"speaker": "system", "text": "**계단입니다.** 계단에 닿으면 다음 층으로 내려갑니다."},
			{"speaker": "narr", "text": "끝이 보이지 않는 계단. 앞서가던 세라피나가 걸음을 늦춰 노엘 옆에 선다."},
			{"show": {"hero": "L", "noel": "FR"}, "speaker": "hero", "face": "hero_calm", "text": "노엘. 아까부터 표정이 안 좋아."},
			{"speaker": "noel", "text": "…원래 이래."},
			{"speaker": "hero", "face": "hero_smile", "text": "원래 그렇긴 하지. 근데 오늘은 좀 더."},
			{"speaker": "hero", "face": "hero_calm", "text": "있잖아. 이 일 끝나면, 바다 말고 하나 더 하고 싶은 게 있어."},
			{"speaker": "hero", "face": "hero_smile", "text": "너 웃는 거. 한 번도 제대로 본 적이 없어서."},
			{"speaker": "hero", "face": "hero_smile", "text": "바닷가에서 엘리안이 노래하고, 브룬힐드는 짜다고 투덜대고… 그때 너도 웃어 줘."},
			# [연출] 말하지 못하는 것 — 손 위로 「용사의 죽음」이 다시 떠오른다. 세라피나 쪽 붉은 실이 팽팽하다
			{"omen": {"card": "hero_death", "clarity": 1.0, "taut": ["hero"], "dim": 0.28}},
			{"speaker": "inner", "text": "이 계단을 내려가지 말자고, 말할 수 있다면."},
			{"speaker": "inner", "text": "…말하는 순간, 들은 사람은 모두 죽는다. 세라도, 뒤에서 듣고 있을 둘도."},
			{"speaker": "inner", "text": "그렇다고 이 카드를 내지 않으면, 그 죽음은 세라 혼자에게 오지 않는다. 우리 모두에게 온다."},
			{"speaker": "inner", "text": "모두를 살리는 길은 하나뿐이다. 정해진 그 죽음을, 내 손으로 내는 것."},
			{"omen_end": true},
			{"key": "sera", "choice": [
				{"text": "웃어 준다", "value": "smile", "lines": [
					{"speaker": "narr", "text": "노엘이 서툴게 웃는다."},
					{"speaker": "hero", "face": "hero_smile", "text": "…뭐야, 할 줄 알잖아. 약속이다?"}]},
				{"text": "대답하지 못한다", "value": "silent", "lines": [
					{"speaker": "narr", "text": "노엘이 시선을 피한다."},
					{"speaker": "hero", "face": "hero_calm", "text": "…괜찮아. 대답은 나중에 들을게. 끝나고 나서."}]},
			]},
			{"show": {}, "speaker": "narr", "text": "계단 아래에서, 기도하는 목소리가 들려온다."},
			{"speaker": "system", "text": "여기서 고른 선택은 이후 대사에 영향을 줍니다."},
		],
		# 7. 빈 캠프 — 끝, 그리고 다음 죽음의 예고
		"emptycamp": [
			{"speaker": "narr", "text": "같은 곁방. 같은 모닥불."},
			{"speaker": "narr", "text": "침낭 하나가, 펼쳐진 채 비어 있다."},
			{"show": {"warrior": "L", "archer": "C", "noel": "FR"}, "speaker": "archer", "face": "archer_hollow", "text": "……스튜, 끓일 사람이 없네요."},
			{"speaker": "warrior", "face": "warrior_grief", "text": "……"},
			{"if": {"sera": "smile"}, "speaker": "archer", "face": "archer_grief", "text": "마지막에… 웃어 줘서 다행이야, 노엘. 대장, 그거 엄청 보고 싶어 했거든요."},
			{"if": {"sera": "silent"}, "speaker": "archer", "face": "archer_grief", "text": "대장은… 끝까지 노엘 대답을 기다렸어요."},
			{"speaker": "warrior", "face": "warrior_stern", "text": "노엘. 네 예지에… 이건 보였나."},
			{"speaker": "noel", "text": "……"},
			{"speaker": "warrior", "face": "warrior_grief", "text": "…아니. 묻지 않겠다. 보였어도, 못 막았겠지."},
			{"speaker": "inner", "text": "보였다. 그리고 내가, 냈다."},
			{"speaker": "inner", "text": "\"내가 없어도 잘 할 수 있지?\" — 그 말에, 나는 끝내 대답하지 못했다."},
			# [연출] 다음 죽음의 예고 — 불이 낮게 흔들리고, 누구인지 알아볼 수 없을 만큼 흐린 카드. 실은 특정 동료에게 걸리지 않고 남은 둘 쪽이 아주 희미하게 떨릴 뿐
			{"omen": {"card": "", "clarity": 0.0, "faint": ["warrior", "archer"], "dim": 0.3, "fireLow": true}},
			{"speaker": "inner", "text": "…다음 카드가, 비치기 시작했다."},
			{"omen_end": true},
		],
	},

	# 이벤트 장면 위쪽 작은 제목
	"eventTitles": {"corpse": "핏자국이 끌려간 통로", "rest": "촛불이 남은 작은 예배당", "train": "무너진 경비 훈련장", "stairs": "끝이 보이지 않는 계단", "emptycamp": "곁방"},
	# 훈련 결과 한 줄 ({card} = 강화한 카드 이름, {summary} = 바뀐 수치)
	"trainResult": "{card} 강화 — {summary}",

	# ───────────── 탐색 (대본 3.2) ─────────────
	"explore": {
		"fork": {"prompt": "길을 고르세요", "paths": {
			"corpse": {"title": "핏자국이 끌려간 통로", "desc": "무언가가 끌려간 자국이 있다. 무엇이 있을지 모른다."},
			"rest": {"title": "촛불이 남은 작은 예배당", "desc": "쉬어 갈 수 있을 것 같다. 모두의 HP를 회복하고, 최대 HP가 오른다."},
			"train": {"title": "무너진 경비 훈련장", "desc": "동료와 합을 맞출 수 있다. 카드 1장을 강화한다."}}},
		"stairs": {"prompt": "계단 아래로", "paths": {
			"battle": {"title": "2층 · 회랑", "desc": "기도하는 목소리가 들린다. 전투."}}},
	},
	"map": {
		"floors": {1: "1층 · 잿빛 성당", 2: "2층 · 깊은 회랑", 3: "3층", 4: "4층"},
		"rooms": {"camp": "곁방", "hall": "광신도의 회랑", "fork": "갈림길", "corpse": "핏자국 통로", "rest": "예배당", "train": "훈련장",
			"stairs": "계단", "f2hall": "기도 소리", "f2deep": "가장 깊은 곳"},
		"floorShort": "{n}층",
	},

	# ───────────── 5.5 사망 컷신 자막 ─────────────
	# "sera": true 인 자리에는 계단 선택에 따른 세라피나의 마지막 말(seraLast)이 들어간다. 세라피나는 자기가 죽는 걸 모른다.
	"cutLines": {
		"C1": [{"who": "hero", "text": "…노엘? 왜 그런 얼굴이야."}, {"sera": true}],
		"C2": [{"who": "hero", "text": "노엘—"}],
	},
	"seraLast": {
		"smile": ["내가 앞에서 저걸 붙잡아 둘게. 잠깐이면 돼.", "내가 없어도… 잘 할 수 있지? 아까처럼 웃으면서."],
		"silent": ["내가 앞에서 저걸 붙잡아 둘게. 그동안 둘을 부탁해.", "내가 없어도 잘 할 수 있지? …대답은, 돌아와서 들을게."],
		# 계단 대화 없이 시작했을 때(테스트 바로 가기 등)
		"none": ["내가 앞에서 저걸 붙잡아 둘게. 잠깐이면 돼."],
	},
	# C8: 남은 동료의 반응 (기존). pause: 그 대사 뒤에 더 머무는 시간(ms) / faces: 글자가 다 나온 뒤 차례로 바뀌는 표정
	"reactions": [
		{"who": "archer", "faces": ["archer_shocked", "archer_grief", "archer_hollow"], "text": "…세라?", "pause": 1600},
		{"who": "warrior", "faces": ["warrior_shocked", "warrior_grief"], "text": "……", "pause": 800},
	],

	# ───────────── 6. 탈출 (기존) ─────────────
	"escape": {
		"lines": [
			{"who": "system", "text": "거대한 발이 비틀거리며 물러난다."},
			{"who": "warrior", "face": "warrior_rage", "text": "물러난다…! 지금이다. 엘리안, 노엘. 뛰어!"},
			{"who": "archer", "face": "archer_grief", "text": "대장은요? 대장은—!"},
			{"who": "warrior", "face": "warrior_grief", "text": "…뛰라고!"},
		],
		"title": "탈출",
	},

	"ending": {
		"title": "튜토리얼 끝",
		"lines": ["세라피나는 돌아오지 않았다.", "남쪽 바다를 보자던 약속도."],
		"inner": "…이번엔, 구할 수 있을까.",
		"button": "다시 하기",
	},

	# 1층·2층 광신도 전투에서 전멸했을 때 (거대 존재 전멸은 "카드를 내지 않은 미래" 연출 — 대본 5.7)
	"wipe": {
		"normal": {"title": "전멸", "text": "노엘의 눈앞에서 파티가 쓰러졌다.", "button": "다시 — 이 전투 처음부터"},
	},
}
