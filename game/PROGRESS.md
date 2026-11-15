# Godot 이식 진행 상황 (이어받기용)

- 작업 브랜치: `cc/amazing-darwin-nesbwh` / Godot 4.7.2, `game/` 폴더 / 판단 기록: `game/DECISIONS.md`
- CI: `.github/workflows/witch-web-build.yml` → gh-pages `godot/`(웹 빌드), `godot-ci/`(스크린샷·로그)

## 구조
- `data/game_data.gd`(수치·배치·연출 시간) · `data/script_data.gd`(대본 v0.6: 대사·안내·선택지·문구 전부)
- `core/`: `rules.gd`(전투 규칙, 잠긴 죽음 카드) · `ctl.gd`(장면 흐름) · `guide.gd`(안내 트리거) · `fx.gd`(애니메이션·입자) · `assets.gd` · `ui.gd` · `test_api.gd`(?test=1 웹 훅) · `autoplay.gd`(자동 진행) · `check_scripts.gd`
- `ui/`: `battle_view.gd`(전투 화면·연출·HUD) · `hand.gd`(두 손·세운 손) · `card_view.gd`(원근 카드) · `battle_input.gd` · `dialog_box.gd`(대사창·안내 상자) · `cutin.gd` · `blood.gd` · `icons.gd` · `btn.gd` · `card_art.gd` · `shaders/`
- `scenes/`: `scenes.gd`(타이틀·컷신·탈출·종료·전멸·되감기) · `vn.gd`(캠프·이벤트·계단·빈 캠프) · `omen.gd`(죽음 카드 떠오름) · `explore.gd`(탐색·걷기) · `map_view.gd`(지도)
- 시험: `tests/test_rules.gd`(규칙 37개) · `tests/web/smoke.js`(Playwright 경로 A~E)

## 로컬 검증 방법
- `godot --headless --path game --import` 두 번 → `godot --headless --path game -- --check-scripts` → `godot --headless --path game --script res://tests/test_rules.gd`
- 헤드리스 자동 진행: `godot --headless --path game -- --scene=camp --speed=10 --autoguide --autoplay --path=rest --choice=smile --trace --quit-on-end`
- 웹: export "Web" → `python3 -m http.server` → `node game/tests/web/smoke.js http://localhost:8000/ shots`

## 완료
- [x] 골격 가져옴 + 대본 v0.6 + 잠긴 죽음 카드 규칙(1층부터 손패 맨 오른쪽, 4장 드로우, 거대 존재 1턴 해제) + 규칙 테스트 37개
- [x] 전투 화면 전체(원근 카드, 손 둘만, 예고, 붉은 실, 컷인, 타격 모션, 피, 거대 존재 등장·z-order, 죽음 카드·컷신·C7·C8, 짓밟힘)
- [x] VN(캠프 파티 소개·이름표·죽음 카드 떠오름, 시체·휴식·훈련, 계단 선택, 빈 캠프 흐린 카드), 탐색(걷기·지도·갈림길), 탈출·종료, 전멸 되감기
- [x] 헤드리스 자동 진행 끝까지(일반·전멸 재시작) 에러 없음, 로컬 웹 스모크 진행 중

## 다음 할 일
1. CI 첫 성공 확인 → main 에 알림
2. 스모크 실패 항목 고치기, 스크린샷 점검(휴대폰 글씨·세로 안내·컷인)

## 알려진 문제
- 로컬 swiftshader 에서 스모크 테스트가 느림(경로 A 10분 이상)
