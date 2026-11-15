# 튜토리얼 전투 프로토타입 — 죽음을 보는 마녀 (가제)

캠프 대화 → 일반 전투(광신도 3) → 거대 존재 등장 → 거대 존재 전투(3턴 카운트다운) → 죽음 카드 → 사망 컷신 → 짓밟힘 → 탈출 → 종료.
카드를 끝까지 안 쓰면 3턴째 짓밟기로 전멸 → 거대 존재 등장 직후부터 다시.

## 실행
- `index.html`을 Chrome/Edge로 열면 된다(더블클릭, `file://`로 열어도 동작). 설치·빌드 없음.
- 1920×1080 기준 화면을 창 크기에 맞춰 비율 유지로 확대·축소한다(남는 곳은 검은 여백).
- 마우스: 카드를 끌어서 적 위에 놓기 / 대상 없는 카드는 손패 위쪽으로 끌어올려 놓기 / 운명 전가는 ① 적의 예고에 놓고 ② 새로 맞을 아군 클릭(우클릭·Esc: 취소).
- 주소 뒤 옵션(선택): `?seed=7`(난수 고정) · `?speed=2`(연출 속도) · `?scene=giant`(바로 시작: `camp` `normal` `giant` `cutscene` `ending`)

## 디버그 패널
- `` ` ``(백틱, 숫자 1 왼쪽 키) 또는 `F9`로 열고 닫는다.
- 장면 바로 가기(타이틀·캠프·일반 전투·거대 존재·컷신·종료), 전투 즉시 승리, 턴 종료, 에너지·HP 수정, 특정 카드 손패에 추가, 연출 속도, 그림 파일 상태, 현재 상태.
- 일반 전투에서 "즉시 승리" = 광신도 1명만 남기고 처치 → 거대 존재가 등장한다.

## 그림 교체
- `assets/`에 아래 파일명으로 넣고 새로고침하면 바로 바뀐다. 없으면 같은 자리에 회색 박스 + 파일명이 보인다.
- `bg_cathedral.png` `bg_camp.png`(1920×1080) · `spr_cultist.png`(투명, 2:3) · `spr_giant_foot.png`(투명, 16:9, 위쪽 60%가 발)
- `card_frame.png`(2:3, 그림 창·글 영역 투명) — 없으면 코드로 그린 테두리를 쓴다(회색 박스 대신).
- 컷신: `cut_hero_reverse.png`(없으면 `reference/images/07_...APPROVED.png` 임시) · `cut_hero_reach.png` · `cut_hero_crushed.png` · `cut_hero_aftermath.png`(모두 16:9)
- 브라우저는 없는 파일을 콘솔에 `Failed to load resource`로 기록한다. 그림이 없을 때 나는 정상적인 기록이다.

## 수치·대사 조정
- 카드·HP·적·예고·튜토리얼 손패·대사·캠프 대본·컷신 길이·화면 배치는 모두 `js/data.js`에 있다. 코드를 고치지 않아도 된다.
- 손 그림 위치/크기: `layout.hand`(scale·x·y), 카드 자리: `layout.hand.slots`(원본 그림 좌표), 동료·적 위치: `layout.allies`·`layout.enemySlots`.

## 테스트
- 규칙(브라우저 없이): `node --test prototype/tests/rules.test.js`
- 스모크(Playwright + Chromium): `node prototype/tests/smoke.js [스크린샷 폴더]` — 전체 진행 1회, 전멸 → 재시작 1회, 다른 창 크기·일반 전투 전멸 1회.

## 파일
| 파일 | 내용 |
|---|---|
| `js/data.js` | 모든 수치·카드·적·대사·배치 |
| `js/rules.js` | 전투 규칙(화면과 분리, Node에서 테스트) |
| `js/hand.js` · `js/cardart.js` | 마녀의 손과 손패(원근 카드), 코드로 그린 카드 그림 |
| `js/battleview.js` | 전투 화면, 붉은 실, 이벤트 연출 |
| `js/input.js` | 드래그 조작 |
| `js/scenes.js` · `js/controller.js` | 타이틀·캠프·컷신·탈출·종료, 장면 흐름 |
| `js/fx.js` · `js/blood.js` | 흔들림·피해 숫자·입자, 코드로 그린 피 |
| `js/dialog.js` · `js/debug.js` · `js/assets.js` · `js/main.js` | 대사창·안내, 디버그, 그림 확인, 시작 |
