# 작업 현황·인수인계 (2026-10-04, 전체판 v1.0 — 1~5장, 구조 정리·최적화 뒤)

> 대화를 압축하거나 새 세션에서 이어 갈 때 **이 문서부터** 읽는다. 설정 정본은 [`bible/`](bible/README.md), 공통 시스템 규칙은 [`systems2.md`](systems2.md), 마법은 [`magic.md`](magic.md), 장별 실제 구현은 `chapterN.md`의 7절 이후, 이번 개발 기록은 [`devlog/06-full-version.md`](devlog/06-full-version.md).

## 1. 어디에 무엇이
| 항목 | 위치 |
|---|---|
| 저장소·브랜치 | `abback-go/yemo_plan`, 작업 브랜치 `cc/vigilant-dirac-751x7b` (PR #4, draft) |
| 웹 플레이 | https://abback-go.github.io/yemo_plan/ — 푸시하면 Actions(`web-build.yml`)가 `gh-pages`로 배포. 올라간 커밋은 `version.txt`(타이틀 오른쪽 아래 "빌드 ○○○○○○○") |
| 모바일 | 같은 주소를 안드로이드 Chrome에서 홈 화면 웹앱으로 설치 → 인터넷 없이 실행 (`game/README.md`) |
| 게임 프로젝트 | `game/` (Godot 4.7.2, GDScript, 640×360) |
| 기획 | `docs/bible/`(정본) · `concept.md` · `chapter1.md`~`chapter5.md` · `magic.md` · `systems2.md` |
| 방 생성기 | `tools/roomgen.py`(1장) + `tools/rooms/<sys·ch2~ch5>.py` → `game/world/rooms/*.gd` (**방 파일 직접 수정 금지**, 생성기 수정 후 `python3 tools/roomgen.py`, 검사 `python3 tools/roomgen.py check all <접두사>`) |
| 음악·효과음 | `tools/gen_music.py` → `game/assets/music/*.ogg`, 효과음은 `game/autoload/sfx.gd`에서 실행 시 합성 |
| 시험 도구 | `tools/test/` — 사용법 [`tools/test/README.md`](../tools/test/README.md), 시나리오 `tools/test/scenarios/` (`sys_*`, `chN_full` 등) |

## 2. 사용자 작업 방식 (합의된 것)
- 사용자는 **사지방 PC**(Git 없음, 재부팅 시 초기화)와 웹 빌드로 확인 → 변경 후 **ZIP 전달**(`git archive --prefix=yemo_game_v10/ HEAD game`) + 웹 반영 안내.
- 진행 방향: **코드 그래픽으로 기능·흐름 먼저 → 재밌으면 아트**.
- 모바일: 안드로이드 태블릿(가끔 휴대폰)에서 인터넷 없이(홈 화면 웹앱).
- 전체판(2~5장)은 사용자가 "이 프롬프트에 한해 결정권 위임, 중간에 묻지 말 것"으로 맡김 → 이름·세부 설계는 bible에 기록된 대로 정함.

## 3. 현재 상태 (v1.0)
- 1장(신계 7방 + 학교 23방) + 수업 방 5 + 2장 33방 + 3장 32방 + 4장 31방 + 5장 34방. 장마다 강자 보스·동료·서브 퀘스트 6~7종.
- 마법 7종(초급 3·중급 2·고급 2), 수업 게시판 → 수업 퀘스트 4종, 마도석으로 레벨 1~3, A·S·F 장착.
- 퀘스트창(메인·서브·수업)·마법서·미니맵·전이진·장 카드·크레디트, 난이도(기본 쉬움).
- 메인 분량 추정 약 8시간 20~30분(각 장 담당 추정 + 1장 실측), 서브·수업 포함 약 10시간 — **사람이 해 본 시간 아님**.
- 검증: 아래 3.1.

### 3.1 검증 기록
- 컴파일 `check_scripts.gd` 503개 실패 0, 방 도달 검사 `check all` 문제 0.
- 공통 시스템 시나리오: `sys_classes`(수업 4종 끝까지, 마법 7종 습득), `sys_ui`, `sys_allies`, `sys_glide` — SCRIPT ERROR 0.
- 장별 `chN_full`: 각 장 담당 브랜치에서 SCRIPT ERROR 0으로 다음 장 카드까지. 통합 빌드 재실행 결과: (아래 3.2에 기록)
- 웹 빌드 Playwright: 콘솔 오류 0.

### 3.2 통합 빌드 장별 전체 시나리오 결과 (2026-10-04, 커밋 28afdc0 기준, 4개 동시 실행)
| 시나리오 | SCRIPT ERROR | 끝 상태 (= 다음 장 시작까지 실제로 이어짐) |
|---|---|---|
| `ch2_full` | 0 | 3장 시작 — 온실(`s_greenhouse`), 목표 "교장실로 가자" |
| `ch3_full` | 0 (대기 초과 2 = 보스전 대기, 의도) | 4장 시작 — 순례길(`tp_road`), 목표 "레오니와 함께 순례길을…" |
| `ch4_full` | 0 | 5장 시작 — 앞마당 축제(`s_courtyard`), 목표 "축제 날이다!…" |
| `ch5_full` | 0 | 크레디트 → 에필로그(`st_rebuild`), 목표 "모든 이야기가 끝났다…" |
- 꼬리 다각형 엔진 오류(`Invalid polygon`) 0건(수정 뒤). 1장 끝 → 2장 시작은 별도 시나리오로 확인(공통 시스템).

### 3.2b 구조 정리·최적화 회귀 (2026-10-04, 리팩터 전 3972c3b ↔ 후, 난수·시간 고정)
- 시나리오 39개 전후 비교: 1~5장 전체 플레이(`full_playthrough`·`ch2~5_full`), 2장 전 시나리오 23개, 3장 일부, 수업·창·동료·활공·터치·이어하기·학교 흐름 —
  **STATUS 줄 전부 같음, 스크린샷 전부 픽셀 동일**(예외: `title_touch` 설정값 한 칸 — 두 사본이 같은 설정 파일을 써서 생긴 환경 차이). 엔진 오류 수도 전후 같음.
- 배경 텍스처 굽기(리팩터 뒤 추가): 그림은 다각형 가장자리 반올림 외 같음, 신전 기록실 그리기 호출 5,207 → 718.
- 실행 방법: `docs/dev/README.md` 5절 (`tools/test/regress.sh` + `imgdiff.py`).

### 3.3 알려진 한계·다음 후보
1. **사람이 직접 플레이**해서 난이도·길 찾기·시간 확인 (특히 2장 하수도, 3장 사냥 시험·사도, 4장 첨탑 추격, 5장 거신 타기·최종전).
2. 아트 착수 (기존 결정: 캐릭터 32px, INARI풍).
3. 그림 보완: 이졸데 결투 전용 그림, 엘프 집 실내 배경, 정화 뒤 세계수 배경, 5장 각성 꼬리 모양.
4. 2장 파견 중 학교에도 피피·이졸데·엠버린이 서 있음(공관과 동시) → 1장 생성기 NPC에 조건 추가.
5. 동료 레오니 2장 옛 성곽 구간 저장 안 됨(방마다 다시 부름).
6. 효과음 합성이 웹에서 실제로 소리 나는지 귀로 확인 필요.

## 4. 코드 구조 요약 (`game/`) — 2026-10-04 리팩터 뒤
**코드를 고치기 전에 [`dev/README.md`](dev/README.md)부터** (구조도·패턴·"무엇을 바꾸려면 어디를"·검증 절차·성능 규칙). 영역별: `dev/story.md`·`world.md`·`backdrop.md`·`enemies.md`·`player.md`·`characters.md`.
| 폴더 | 내용 |
|---|---|
| `autoload/` | GameState(플래그·저장·설정), Sfx, Fx(효과·입자 풀·`now_ms`), StyleRank, Music, TouchControls · Story는 `story/story.gd` |
| `core/` | `chapter_registry.gd`(장 모듈 ch1·sys·ch2~5), `chapter_flow.gd`, `cond.gd`(조건식), `rewards.gd`(보상), `quests.gd`, `spells.gd`, `warp_db.gd`, `tuning.gd/.tres`, `hit.gd`(공격 종류), `enemy_query.gd` |
| `story/` | `data_<ext>.gd`(CHAPTER·SCRIPTS·CHARACTERS·OBJECTIVES·QUESTS), `<ext>/*.gd`(장면별 대본), `dev/`(시험용 대본), `cut.gd`(대본 명령) |
| `world/` | 방(`room.gd`)·`rooms/`(생성물 + `_index.gd`)·`entities/<ext>/`(장치·소품 PROPS 표)·`themes/`(배경 — 정적은 텍스처로 구움, 움직임만 다시 그림) |
| `player/` | `player.gd`(파사드) + `player_motor/caster/gauge/health.gd`, `player_text.gd`(문구) |
| `enemies/`·`combat/`·`fx/` | `enemy_base.gd`(도우미·화면 밖 생략)·`state_clock`·보스 도구, 장별 적 |
| `characters/` | 인물 그림·초상화·`draw_kit.gd`·말풍선 |
| `ui/` | HUD·대화·퀘스트창·마법서·수업 게시판·지도·일시정지·Cinema |

## 5. 작업 규칙

### 5.1 대본 작성 규칙 (구현에서 굳어진 것)
- 대본 = `story/<장>/*.gd`의 메서드(파일은 `data_<장>.gd`의 `SCRIPTS`에 등록), 이름이 실행 ID. `enter_<방ID>`는 방에 들어올 때 **잠그지 않고** 시작하므로 컷신이면 `c.lock()`부터. `teach_*`는 세라를 멈추지 않는 멈춤 안내.
- 컷신(잠금) 중에는 적과 적 탄이 멈춘다. 보스 등장 연출은 `c.freeze_enemies(false)`.
- 보스전처럼 오래 기다리는 대본은 `await c.wait_enemy(적, 체력비율, 시간제한)` 후 `if not c.ok(): return` (쓰러져 부활하면 대본 무효화).
- 보스전 대본은 적이 이미 처치되어 있으면 바로 뒷이야기로 넘어가게(진행 막힘 방지).
- 방을 옮기는 대본은 `await c.goto_room(방, 위치)` — 다음 방의 `enter_` 대본이 이어받는다.

### 5.2 터치 조작 규칙 (구현에서 굳어진 것)
- 터치 버튼은 키보드와 같은 `InputEventAction`을 `Input.parse_input_event`로 보낸다 → 새 기능도 동작 이름만 쓰면 터치에서 그대로 된다.
- 조이스틱 ▲▼는 수직에서 약 44도 안쪽만(`VERT_MIN`), ◀▶는 수평에서 약 67도 안쪽(`SIDE_MIN`). 내장 `VirtualJoystick`은 조금만 기울여도 ↓가 눌려 발판에서 떨어지므로 쓰지 않음.
- 새 대화형 UI를 만들면 `accepts_tap()`을 두어 화면 탭(=`ui_accept`)으로 넘길 수 있게, 메뉴는 `MenuList`(탭 지원)를 쓴다.
- 새 버튼이 필요하면 `touch_controls.gd`의 `BUTTONS`(위치는 모서리 기준 오프셋)와 `button_visible()`에 추가.

### 5.3 장별 모듈 규칙
- 장 N은 자기 파일만 쓴다(목록은 `systems2.md` 1절). 학교 방에 더할 땐 `overlay(...)`. 조건식은 쉼표 = 그리고, `!` = 아님.
- 장 끝은 `await ChapterFlow.finish(c, N)`, 장 시작 `chN_start`는 검은 화면·HUD 꺼짐 상태에서 불린다(`c.hud(true)` → `goto_room` → `fade_in`).
- 여러 장이 같은 학교 방에 덧붙이면 생성 파일이 충돌한다 → 병합 후 `python3 tools/roomgen.py`로 전부 다시 생성.

## 6. 환경 메모 (클라우드 세션)
- 컨테이너는 매번 새로 시작 → Godot 실행 파일, Pillow 등은 다시 받아야 함 (`tools/test/README.md`).
- 이 컨테이너에서는 `docs.godotengine.org`, `abback-go.github.io` 접속이 막혀 있음 → 공식 문서는 웹 검색 결과나 Godot 실행 파일의 `ClassDB`로 확인, 배포 확인은 GitHub Actions 실행 결과로.
- `.claude/worktrees/`(서브에이전트 임시 사본)는 `.gitignore`에 들어 있음. 커밋은 `git add game docs tools` 처럼 경로를 지정.
- 커밋 메시지·PR 본문은 한국어, 끝에 Co-Authored-By / Claude-Session 줄.
- 오프라인 웹앱: Godot 기본 서비스 워커는 설치 때 `index.wasm`·`index.pck`를 저장하지 않아 첫 접속 직후·새 버전 직후 오프라인 실행이 깨진다(Playwright로 확인) → `web-build.yml`이 내보낸 뒤 `cache.addAll(FULL_CACHE)`로 바꾼다. Godot 버전을 올리면 이 치환이 아직 맞는지(grep 실패 시 CI 실패) 확인.
