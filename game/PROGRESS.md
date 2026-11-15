# Godot 이식 진행 상황 (이어받기용)

- 작업 브랜치: `cc/amazing-darwin-nesbwh` / Godot 4.7.2, `game/` 폴더
- 판단 기록: `game/DECISIONS.md`

## 완료
- [x] 골격 가져옴(`dd55a8f` cherry-pick): 그림 복사(손실 압축 import), 손 그림 왼손/오른손 분리, 한글 글꼴(KS 2,350자), `data/game_data.gd`·`data/script_data.gd`, `core/rules.gd`·`core/fx.gd`, 규칙 테스트 33개 통과(로컬 헤드리스)

## 다음 할 일
1. 대본 v0.5 반영(`script_data.gd`), 잠긴 죽음 카드 규칙(1층부터 손패, 4장 드로우), 테스트 갱신
2. 화면: 타이틀 → 캠프(VN) → 전투(손·카드·예고·실·연출) → 탐색(걷기·지도·갈림길) → 이벤트 → 2층 → 거대 존재 → 컷신 → 탈출 → 빈 캠프 → 종료
3. 테스트 훅(`?test=1` JavaScriptBridge), Playwright 스모크, CI 워크플로(`.github/workflows/witch-web-build.yml`)

## 알려진 문제
- (없음)
