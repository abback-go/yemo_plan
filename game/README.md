# Yemo Prototype (Godot 4.7.2)

조작·전투 검증용 프로토타입. 기획: [`docs/prototype.md`](../docs/prototype.md) · 단계별 설명: [`docs/devlog/`](../docs/devlog/)

## 사지방 PC에서 실행하기 (Git 없이)

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
