# 작업 현황·인수인계 (2026-10-03, 1장 데모 v0.4 + 모바일)

> 대화를 압축하거나 새 세션에서 이어 갈 때 **이 문서부터** 읽는다. 기획 근거는 [`chapter1.md`](chapter1.md)(12절 검토 반영, **13절 구현 메모 = 실제 동작**), 개발 기록은 [`devlog/04-chapter1-demo.md`](devlog/04-chapter1-demo.md).

## 1. 어디에 무엇이
| 항목 | 위치 |
|---|---|
| 저장소·브랜치 | `abback-go/yemo_plan`, 작업 브랜치 `cc/vigilant-dirac-751x7b` (PR #4, draft) |
| 웹 플레이 | https://abback-go.github.io/yemo_plan/ — 푸시하면 Actions(`web-build.yml`)가 `gh-pages`로 배포, 약 1~2분. 지금 올라간 커밋은 `version.txt` (게임 타이틀 오른쪽 아래 "빌드 ○○○○○○○"도 같은 커밋) |
| 모바일 | 같은 주소를 안드로이드 Chrome에서 홈 화면 웹앱으로 설치 → 인터넷 없이 실행. 터치 조작은 `game/autoload/touch_controls.gd` (설치·조작 안내: `game/README.md`) |
| 게임 프로젝트 | `game/` (Godot 4.7.2, GDScript, Compatibility 렌더러, 640×360) |
| 기획·기록 | `docs/concept.md` → `docs/prototype.md`(v0.3 전투) → `docs/chapter1.md`(1장) · `docs/devlog/01~04` |
| 방 생성기 | `tools/roomgen.py` → `game/world/rooms/*.gd` (**방 파일 직접 수정 금지**, 생성기 수정 후 `python3 tools/roomgen.py`) |
| 음악 생성기 | `tools/gen_music.py` → `game/assets/music/*.ogg` |
| 시험 도구 | `tools/test/` (실행기·시나리오·컴파일 검사·웹 연기 시험) — 사용법은 [`tools/test/README.md`](../tools/test/README.md) |

## 2. 사용자 작업 방식 (합의된 것)
- 사용자는 **사지방 PC**(Git 없음, 재부팅 시 초기화, Godot 4.7.2 설치)와 웹 빌드로 확인한다 → 변경 후 **ZIP 전달**(`git archive --prefix=yemo_game_v04/ HEAD game`) + 웹 반영 안내(Ctrl+F5, `version.txt` 커밋 확인, 타이틀 "이어하기").
- 진행 방향: **코드 그래픽으로 기능·흐름 먼저 → 재밌으면 아트**. 1장은 30~45분 분량의 완성형 데모.
- 모바일: 사용자가 **컴퓨터를 못 쓸 때 안드로이드 태블릿(가끔 휴대폰)으로 인터넷 없이** 시험하려고 요청 → 홈 화면 웹앱(PWA) + 떠 있는 조이스틱 + 오른쪽 버튼(공격 맨 오른쪽)으로 구현(2026-10-03). 아이폰·APK는 하지 않음.
- 난이도·흐름 문제는 사용자가 직접 플레이하고 알려 줌 → 원인 확인 → 선택지 질문 → 반영 → 시나리오로 확인 → 커밋·푸시·ZIP.

## 3. 현재 상태 (v0.4)
- 신계 7방 + 학교 23방, 대본(프롤로그·학교·인물 대화), 적 12종 + 해태·아귀, 마법 습득 3종, 여우 모드(의태+빙의), 저장·이어하기, 지도, 1장 끝 화면.
- **사용자가 1장을 끝까지 클리어함** (2026-10-03).
- 검증: 컴파일 160개 실패 0, `full_playthrough.json` 끝까지 도달(스크립트 오류 0), 저장·이어하기, ZIP 가져오기, 웹 빌드 콘솔 오류 0.

### 3.1 플레이 피드백 반영 이력 (전부 반영·푸시 완료)
| 피드백 | 반영 | 커밋 |
|---|---|---|
| ↓+Z 발판 내려가기가 안 됨 | 발판을 충돌 층으로 판정, 안내 중 입력도 처리, 신단 계단 안내 위치 조정 | `127005c`, `2d3efe4` |
| 해태가 왼쪽 출구 틈으로 나가고 세라도 못 돌아옴 | 모든 방 좌우 바깥에 보이지 않는 벽, 해태전 중 왼쪽 통로 철창 | `43b571d`, `8c709c6` |
| 해태 너무 어려움 / 언제 변신하는지 모름 | 해태 = 여우 모드 **시범전**: 체력 1000, 85% 또는 10초에 첫 빙의, 체력바 "빙의" 눈금, 템포 완화 | `05a9e3f`, `8c709c6` |
| 실습장 과녁, 점프가 낮아 못 올라감 | 발판 3칸 간격, 과녁 재배치(바닥 2 + 발판 1), 불 유지 5초 | `8c709c6`, `958acee` |
| 여우창문 배운 뒤 고급반 가는 길을 모름 | 목표 문구에 위치 표시, 중앙 홀 잠긴 계단 문구 보완 | `eb424a4` |
| 아귀 너무 어려움 | 체력 3000, 몸 피해 80%, 예고·쉬는 시간 1.3배, 탐식 피해 1 | `f8465fc` |
| 기본 공격을 연발 대신 묵직한 한 발로 | 화염탄 1.2초마다 200 단일 대상, 여우불 260 유도+관통 | `958acee` |
| 모바일로 인터넷 없이 시험하고 싶음 | 터치 조작(떠 있는 조이스틱·버튼·메뉴 탭), 홈 화면 웹앱(오프라인), 타이틀 "새 버전으로 업데이트"·빌드 표시 | (이번 커밋) |

### 3.2 바꾸기 쉬운 주요 수치
- 세라·스킬: `game/core/tuning.gd` (기본 공격 `shot_*`, 여우불 `fox_shot_*`)
- 해태: `game/enemies/haetae.gd` 상단 상수, 첫 빙의 지점 `FOX_MARK`(0.85)·10초는 `game/story/scripts_prologue.gd`
- 아귀: `game/enemies/agwi.gd` 상단 상수 + `max_hp`(3000), `_cadence()`
- 다른 적: 각 `game/enemies/<적>.gd` 상단 상수

## 4. 다음 후보 (사용자 결정 대기)
1. **기본 공격 손맛 확인** (1.2초 간격이 답답하지 않은지). 작은 적(도깨비불 110·석상 여우 160·빗자루 160·등롱 감시자 90)이 이제 한 발에 쓰러짐 → 원하면 2발 기준(300~400)으로 상향.
2. **아트 착수** (추천): 세라·너울 32px 스프라이트 → 적 → 지역 타일. 기존 결정: 캐릭터 32px(모자 제외), INARI풍(어두운 저채도 + 강한 강조색 + 거대한 배경 구조물).
3. 골렘·마도서·갑옷 기사 난이도 점검 (아직 피드백 없음).
4. ~~모바일 조작~~ → 완료. 사용자가 태블릿에서 해 본 뒤 버튼 위치·크기·조이스틱 감도 피드백 반영.
5. 2장 기획 (구슬 회수, 다음 지역).

## 5. 코드 구조 요약 (`game/`)
| 폴더 | 내용 |
|---|---|
| `autoload/` | GameState(플래그·저장·통계), Sfx, Fx(흔들림·섬광·입자·위치 타임), StyleRank, Music(교차 재생) · Story는 `story/story.gd` |
| `world/` | `world.gd`(방 교체·상호작용·부활·끝 화면), `room.gd`(타일 굽기·충돌·좌우 경계·개체), `room_data.gd`, `world_entities.gd`(특수 개체 목록), `entities/`(문·출구·기록·봉화·퍼즐·환영 벽·철창 등), `themes/`(배경) |
| `story/` | `cut.gd`(컷신 도우미), `scripts_prologue.gd`·`scripts_school.gd`·`scripts_npc.gd`(대본), `characters.gd`, `objectives.gd`(목표 순서표), `actor.gd`(너울 본모습·구슬·사슬 등) |
| `player/` | 세라(`player.gd`), 그림(`player_visual.gd`), 카메라 |
| `fox/` | 너울 동행, 여우 모드 기술(여우불·여우비·구미호 폭풍), 여우창문, 변신 연출 |
| `combat/` | 화염탄·불기둥·화염 폭풍·폭주 폭발, 적 탄 |
| `enemies/` | `enemy_base.gd` + 적 12종(각 `<적>.gd` + `<적>_visual.gd`), `enemy_registry.gd`(종류 이름 → 스크립트) |
| `ui/` | HUD(보스 체력바·빙의 눈금), 대화창, 멈춤 안내, 알림, 지도, 일시정지, 설정, 타이틀, 끝 화면 |

### 5.1 대본 작성 규칙 (구현에서 굳어진 것)
- 대본 = `story/scripts_*.gd`의 메서드, 이름이 실행 ID. `enter_<방ID>`는 방에 들어올 때 **잠그지 않고** 시작하므로 컷신이면 `c.lock()`부터. `teach_*`는 세라를 멈추지 않는 멈춤 안내.
- 컷신(잠금) 중에는 적과 적 탄이 멈춘다. 보스 등장 연출은 `c.freeze_enemies(false)`.
- 보스전처럼 오래 기다리는 대본은 `await c.wait_enemy(적, 체력비율, 시간제한)` 후 `if not c.ok(): return` (쓰러져 부활하면 대본 무효화).
- 보스전 대본은 적이 이미 처치되어 있으면 바로 뒷이야기로 넘어가게(진행 막힘 방지).
- 방을 옮기는 대본은 `await c.goto_room(방, 위치)` — 다음 방의 `enter_` 대본이 이어받는다.

### 5.2 터치 조작 규칙 (구현에서 굳어진 것)
- 터치 버튼은 키보드와 같은 `InputEventAction`을 `Input.parse_input_event`로 보낸다 → 새 기능도 동작 이름만 쓰면 터치에서 그대로 된다.
- 조이스틱 ▲▼는 수직에서 약 44도 안쪽만(`VERT_MIN`), ◀▶는 수평에서 약 67도 안쪽(`SIDE_MIN`). 내장 `VirtualJoystick`은 조금만 기울여도 ↓가 눌려 발판에서 떨어지므로 쓰지 않음.
- 새 대화형 UI를 만들면 `accepts_tap()`을 두어 화면 탭(=`ui_accept`)으로 넘길 수 있게, 메뉴는 `MenuList`(탭 지원)를 쓴다.
- 새 버튼이 필요하면 `touch_controls.gd`의 `BUTTONS`(위치는 모서리 기준 오프셋)와 `button_visible()`에 추가.

## 6. 환경 메모 (클라우드 세션)
- 컨테이너는 매번 새로 시작 → Godot 실행 파일, Pillow 등은 다시 받아야 함 (`tools/test/README.md`).
- 이 컨테이너에서는 `docs.godotengine.org`, `abback-go.github.io` 접속이 막혀 있음 → 공식 문서는 웹 검색 결과나 Godot 실행 파일의 `ClassDB`로 확인, 배포 확인은 GitHub Actions 실행 결과로.
- `.claude/worktrees/`(서브에이전트 임시 사본)는 `.gitignore`에 들어 있음. 커밋은 `git add game docs tools` 처럼 경로를 지정.
- 커밋 메시지·PR 본문은 한국어, 끝에 Co-Authored-By / Claude-Session 줄.
- 오프라인 웹앱: Godot 기본 서비스 워커는 설치 때 `index.wasm`·`index.pck`를 저장하지 않아 첫 접속 직후·새 버전 직후 오프라인 실행이 깨진다(Playwright로 확인) → `web-build.yml`이 내보낸 뒤 `cache.addAll(FULL_CACHE)`로 바꾼다. Godot 버전을 올리면 이 치환이 아직 맞는지(grep 실패 시 CI 실패) 확인.
