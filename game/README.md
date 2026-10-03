# Yemo Prototype (Godot 4.7.2)

조작·전투 검증용 프로토타입. 기획: [`docs/prototype.md`](../docs/prototype.md) · 단계별 설명: [`docs/devlog/`](../docs/devlog/)

## 브라우저에서 바로 플레이 (추천)

**https://abback-go.github.io/yemo_plan/**

- 코드가 올라가면 GitHub Actions가 자동으로 웹 빌드를 만들어 위 주소에 올린다 (수 분 소요).
- 페이지가 열리면 게임 화면을 한 번 클릭한 뒤 키보드로 조작.
- 지금 올라간 빌드 정보: https://abback-go.github.io/yemo_plan/version.txt (브랜치, 커밋, 빌드 시각)
- 최신 빌드가 안 보이면 Ctrl+F5(강력 새로고침).
- 웹 빌드는 PC 실행보다 입력 반응이 조금 다를 수 있다. 최종 손맛 확인은 아래 방법으로 PC에서 한 번씩.

## Godot 에디터로 열기 (Git 없이)

1. GitHub에 로그인 → `abback-go/yemo_plan` 저장소
2. 왼쪽 위 브랜치 선택 메뉴에서 작업 브랜치 선택 (PR 페이지에 적힌 브랜치)
3. 초록색 **Code** 버튼 → **Download ZIP** → 압축 풀기
4. Godot 4.7.2 실행 → 프로젝트 관리자에서 **Import(가져오기)** → 압축 푼 폴더의 `game/project.godot` 선택 → **Import & Edit**
5. 처음 열 때 리소스 가져오기(import)에 수십 초 걸릴 수 있음
6. 에디터 오른쪽 위 ▶ (또는 F5)로 실행

## 조작

| 행동 | 키보드 | 게임패드 |
|---|---|---|
| 이동 | ← → | 왼쪽 스틱 / 방향 패드 |
| 점프 (길게 = 높이) | Z | A |
| 대시 | C | B 또는 RT |
| 다시 시작 | R | Back |

공격(X)과 스킬(A, S)은 키만 등록되어 있고 아직 동작하지 않음.

## 수치 바꾸기

에디터 왼쪽 아래 **FileSystem** 패널 → `player/player_tuning.tres` 클릭 → 오른쪽 **Inspector**에서 수정 → 다시 실행.
사지방 PC는 재부팅 시 초기화되므로, 마음에 드는 값은 메모해서 대화로 알려 주면 저장소에 반영한다.
