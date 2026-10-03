# Yemo Prototype v0.2 (Godot 4.7.2)

조작·전투 검증용 프로토타입. 기획: [`docs/prototype.md`](../docs/prototype.md) · 단계별 설명: [`docs/devlog/`](../docs/devlog/)

## 브라우저에서 바로 플레이

**https://abback-go.github.io/yemo_plan/**

- 코드가 올라가면 GitHub Actions가 자동으로 웹 빌드를 만들어 위 주소에 올린다 (수 분 소요).
- 처음 한 번은 저장소 Settings → Pages → Source를 `gh-pages` 브랜치로 지정해야 주소가 열린다.
- 페이지가 열리면 게임 화면을 한 번 클릭한 뒤 키보드로 조작.
- 지금 올라간 빌드 정보: https://abback-go.github.io/yemo_plan/version.txt
- 최신 빌드가 안 보이면 Ctrl+F5(강력 새로고침).

## Godot 에디터로 열기 (Git 없이)

1. 전달받은 ZIP(또는 GitHub **Code → Download ZIP**)을 압축 풀기
2. Godot 4.7.2 → 프로젝트 관리자 **Import** → `project.godot` 선택 → **Import & Edit**
3. F5 = 타이틀부터 실행 / `levels/test_room.tscn`을 열고 F6 = 연습 방

## 조작

| 행동 | 키보드 | 게임패드 |
|---|---|---|
| 이동 | ← → | 왼쪽 스틱 / 방향 패드 |
| 점프 (길게 = 높이) | Z | A |
| 화염탄 (연타·누르기, 3타째 강함) | X | X |
| 대시 (짧은 무적) | C | B 또는 RT |
| 불기둥 | A | LB |
| 화염 폭풍 | S | RB |
| 일시정지 | Esc 또는 P | Start |
| 체크포인트에서 다시 | R | Back |
| 디버그 표시 | F1 | — |

## 수치 바꾸기

**`core/tuning.tres` 한 파일**에 이동·점프·대시·화염탄·스킬·폭주·체력·타격감·카메라·적 수치가 모두 있다.
FileSystem 패널에서 클릭 → Inspector에서 수정 → 다시 실행. 사지방 PC는 재부팅 시 초기화되므로, 마음에 드는 값은 메모해서 알려 주면 저장소에 반영한다.

## 폰트

`assets/fonts/Galmuri11.ttf` — 갈무리11, SIL Open Font License 1.1 (`assets/fonts/README.md`)
