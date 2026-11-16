# Godot 이식 진행 상황 (이어받기용)

- 작업 브랜치: `cc/amazing-darwin-nesbwh` / Godot 4.7.2, `game/` 폴더 / 판단 기록: `game/DECISIONS.md`
- CI: `.github/workflows/witch-web-build.yml` → gh-pages `godot/`(웹 빌드), `godot-ci/`(스크린샷·로그)

## 구조
- `data/game_data.gd`(수치·배치·연출 시간) · `data/script_data.gd`(대본 v0.6: 대사·안내·선택지·문구 전부)
- `core/`: `rules.gd`(전투 규칙, 잠긴 죽음 카드) · `ctl.gd`(장면 흐름) · `guide.gd`(안내 트리거) · `fx.gd`(애니메이션·입자) · `assets.gd` · `ui.gd` · `test_api.gd`(?test=1 웹 훅) · `autoplay.gd`(자동 진행) · `check_scripts.gd`
- `ui/`: `battle_view.gd`(전투 화면·연출·HUD) · `hand.gd`(두 손·세운 손) · `card_view.gd`(원근 카드) · `battle_input.gd` · `dialog_box.gd`(대사창·안내 상자) · `cutin.gd` · `blood.gd` · `icons.gd` · `btn.gd` · `card_art.gd` · `shaders/`
- `scenes/`: `scenes.gd`(타이틀·컷신·탈출·종료·전멸·되감기) · `vn.gd`(캠프·이벤트·계단·빈 캠프) · `omen.gd`(죽음 카드 떠오름) · `explore.gd`(탐색·걷기) · `map_view.gd`(지도)
- 시험: `tests/test_rules.gd`(규칙·데이터 53개) · `tests/web/smoke.js`(Playwright 경로 A~E, T=탑뷰 시험판)

## 로컬 검증 방법
- `godot --headless --path game --import` 두 번 → `godot --headless --path game -- --check-scripts` → `godot --headless --path game --script res://tests/test_rules.gd`
- 헤드리스 자동 진행: `godot --headless --path game -- --scene=camp --speed=10 --autoguide --autoplay --path=rest --choice=smile --trace --quit-on-end`
- 웹: export "Web" → `python3 -m http.server` → `node game/tests/web/smoke.js http://localhost:8000/ shots`

## 완료
- [x] 골격 가져옴 + 대본 v0.6 + 잠긴 죽음 카드 규칙(1층부터 손패 맨 오른쪽, 4장 드로우, 거대 존재 1턴 해제) + 규칙 테스트 37개
- [x] 전투 화면 전체(원근 카드, 손 둘만, 예고, 붉은 실, 컷인, 타격 모션, 피, 거대 존재 등장·z-order, 죽음 카드·컷신·C7·C8, 짓밟힘)
- [x] VN(캠프 파티 소개·이름표·죽음 카드 떠오름, 시체·휴식·훈련, 계단 선택, 빈 캠프 흐린 카드), 탐색(걷기·지도·갈림길), 탈출·종료, 전멸 되감기(붉게 번짐 → 유리 깨짐)
- [x] CI 첫 성공(run #9): 검사·규칙 37·헤드리스 자동 진행 2경로·스모크 43항목, 콘솔 에러 0 → gh-pages godot/·godot-ci/
- [x] 코디네이터 검토 반영: 지도 패널 위치·방 이름 판, 세운 손이 카드 아래 가장자리를 쥠, HP 표시 한 곳(st.party)에서
- [x] 대상 카드 조준: 끌기 시작하면 오른손이 손패에서 그 카드를 뽑아 손패 높이에서 작게 쥠(세운 손 그림 0.55배, `layout.grip`), 화살표는 쥔 카드에서. 확정하면 그 손이 커지며 세운 손, 취소하면 손패로 돌려놓음. 스모크 A(PC 조준·취소)·D(휴대폰 조준)에 손 둘·쥔 카드 위치 확인 추가

- [x] 탑뷰 이동 시험판(`?scene=topdown`, 튜토리얼 흐름과 따로): 넓힌 갈림길 맵(2112×1662 → 블록 2.5px로 844×664)·노엘 4방향 걷기, WASD·방향키 + 탭 이동(격자 경로찾기), 충돌 다각형, 앞벽 덮기·기둥/돌무더기 y 정렬 가림, 물건 4개 조사(대화창 + 옆 스탠딩), 출구 3개(갈림길 설명 → 시험판 끝 → 입구로). `scenes/topdown.gd`·`topdown_nav.gd`, 수치 `game_data.gd "topdown"`, 대사 `script_data.gd "topdown"`. 규칙 테스트 +9(46개), 스모크 경로 T(25항목)
- [x] 탑뷰 시험판 개선: 동료 셋(세라피나·브룬힐드·엘리안, 72px 칸 시트)이 노엘이 지나간 경로를 따라 18맵px 간격으로 줄지어 걷기(방향 행·걷기 그림·그림자·y 정렬 가림, 시작·되돌아올 때 줄 섬), 속도 72→120·걷기 그림 7→10fps, 터치: 왼쪽 절반 조이스틱(지름 130 CSS px, 아날로그 0.3~1배)·오른쪽 아래 조사 버튼(78 CSS px), 터치 빈 바닥 탭 이동 끔. 입구 자리 y 556→510(동료 셋이 방 안에 서게). 규칙 테스트 +7(53개), 스모크 경로 T 39항목

## 다음 할 일
- 최종 CI 통과 확인 후 최종 보고

## 알려진 문제
- 로컬 swiftshader 에서 스모크 테스트가 느림(전체 약 9~10분). 스크린샷 시점이 늦어 짧은 연출은 느린 속도(setSpeed)로 찍는다
- 탑뷰 시험판: 기둥 뒤에 서면 노엘이 완전히 가려진다(실루엣 표시 없음). 가림 윤곽은 손으로 딴 다각형이라 가장자리 몇 px 오차. 휴대폰(DPR 3)에서는 무대 배율이 정수가 아니라 도트 폭이 1px 들쭉날쭉할 수 있음. 원본(좁은) 맵 비교용 `?map=small` 은 만들지 않음
- 본 안내 기록이 브라우저 저장소에 남아 같은 브라우저에서는 다시 나오지 않음(의도). 다시 보려면 주소에 `?guides=reset`
