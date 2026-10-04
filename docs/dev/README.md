# 개발 안내 — 구조 한눈에 보기 (여기부터 읽는다)

> 게임 코드를 고치기 전에 이 문서를 먼저 읽는다. 영역마다 자세한 안내가 따로 있다.
> 설정(세계관·인물·줄거리)의 정본은 [`../bible/`](../bible/README.md), 작업 현황·인수인계는 [`../status.md`](../status.md).
> 이 구조는 2026-10-04 리팩터 결과다(개발 기록 [`../devlog/07-refactor.md`](../devlog/07-refactor.md)).

## 1. 문서 지도
| 문서 | 다루는 것 | 이럴 때 읽는다 |
|---|---|---|
| [story.md](story.md) | 대본(Cut 명령 사전)·장 정보·목표·퀘스트·수업·조건식·플래그 이름 규칙·story_lint | 대사·장면 순서·장 추가·퀘스트 |
| [world.md](world.md) | 방 생성기(tools/rooms → world/rooms)·방 개체·소품 kind 표·방 색인 | 방·지형·배치·문·소품 |
| [backdrop.md](backdrop.md) | 배경(하늘·시차 층·안개·입자), 정적/동적 그리기 계약 | 배경·테마 추가, 배경이 무거울 때 |
| [enemies.md](enemies.md) | EnemyBase·도우미·상태 시계·보스 도구·예고 위험 지대·효과(Fx)·공격 종류 | 적·보스·탄·효과 |
| [player.md](player.md) | 세라(파사드 + 컴포넌트)·마법 시전·수치(tuning)·문구 | 조작감·마법·능력·수치 |
| [characters.md](characters.md) | 인물 그림·초상화·NPC·동료·말풍선 | 인물 추가·동료 추가 |
| [proto.md](proto.md) | 전투 시제품(새 조작 훈련장, `game/proto/`) 파일 구성 | 새 조작·마법 이펙트 시험 |
| [../../tools/test/README.md](../../tools/test/README.md) | 시나리오 실행기 명령·시나리오 목록·웹 시험 | 시험을 돌리거나 새로 만들 때 |

## 2. 전체 구조
```
오토로드(언제나 있음)   GameState(플래그·저장·설정) · Story(대본 실행) · Fx(효과·히트스톱) · Sfx · Music · StyleRank · TouchControls
                           │
world/world.tscn ── World ─┬─ Room (방 하나: 배경 RoomBackdrop · 타일 TilePainter · 충돌 · 개체들)
   (게임 화면)             ├─ Player(세라) ─ Motor · Caster · Gauge(폭주·여우) · Health · PlayerVisual
                           ├─ NeoulPet(너울) · Ally(동료)
                           └─ UI: HUD(미니맵) · 대화창 · 안내 · Cinema(레터박스·장 카드) · 지도 · 일시정지 · 수업 게시판 …
콘텐츠 모듈(장마다)     ChapterRegistry.EXTS = ch1 · sys · ch2 · ch3 · ch4 · ch5
   ├─ story/data_<ext>.gd          CHAPTER · SCRIPTS · CHARACTERS · OBJECTIVES · QUESTS (순수 데이터)
   ├─ story/<ext>/*.gd             대본 (장면·지역마다 한 파일, 메서드 이름 = 대본 ID)
   ├─ enemies/<ext>/ · world/entities/<ext>/ (PROPS 표 + draw) · world/themes/{themes,backdrop}_<ext>.gd
   └─ tools/rooms/<ext>.py         방 정의 → python3 tools/roomgen.py → game/world/rooms/*.gd + _index.gd (생성물, 손대지 않음)
```
- **흐름**: 방 개체(트리거·NPC·게시판)가 `Story.run("대본ID")` → 대본 메서드가 `Cut`(c)으로 대사·이동·연출·플래그를 순서대로 `await` → 플래그가 바뀌면 HUD 목표·방 개체(`flag_changed` 신호)가 따라 바뀜.
- **장 경계**: 장 끝 대본의 마지막 줄 `await ChapterFlow.finish(c, N)` → 꼬리·저장·다음 장 카드 → `ch<N+1>_start`.
- **저장**: GameState의 플래그 사전 + 체력·물약·방·기록 지점 → JSON(`user://`), 저장 코드(`YEMO1-…`)로 옮길 수 있음.

## 3. 쓰인 패턴과 이유
| 패턴 | 어디에 | 왜 |
|---|---|---|
| **레지스트리/플러그인** | `ChapterRegistry` + 장별 모듈 파일 | 장 하나를 넣고 빼는 일이 그 장 파일과 `EXTS` 한 줄로 끝나게. 여러 사람이 동시에 다른 장을 만들어도 충돌하지 않음 |
| **데이터 주도** | `data_<ext>.gd`(장·목표·퀘스트·인물), 소품 `PROPS` 표, `core/tuning.tres`, `PlayerText`, 적 kind 표 | 스토리·밸런스가 자주 바뀌니 코드가 아니라 표를 고치게 |
| **명령 + 코루틴(대본)** | `Story`·`Cut`, 대본 메서드 | 연출 순서를 위에서 아래로 읽히게(`await`). 대사·이동·카메라를 한곳에서 |
| **조건식 하나** | `core/cond.gd` (`Cond.ok`) | 목표·퀘스트·수업 해금·방 개체 조건이 같은 문법(쉼표=그리고, `!`=아님, `mana>=N`) |
| **파사드 + 컴포넌트** | `Player` → Motor·Caster·Gauge·Health | 바깥(대본·적·HUD 180곳 이상)은 Player 이름만 쓰고, 안은 책임별 파일로 |
| **상태(상태 시계)** | 적의 `enum S` + `StateClock`, 보스 `BossKit`(페이즈 문턱·공격 고르기) | 상태·타이머 보일러플레이트를 한 줄로 |
| **관찰자(신호)** | `GameState.flag_changed`, `defeated`·`phase_changed` 등 | 매 프레임 플래그 폴링 대신 바뀔 때만 |
| **객체 풀·플라이웨이트** | `Fx.burst` 입자 풀, 그라디언트 색별 캐시 | 단일 스레드 웹에서 노드·리소스 생성 비용 제거 |
| **더티 플래그(그리기 캐시)** | 배경 정적/동적 분리, 소품 `split`·화면 밖 생략, 인물·적 화면 밖 생략 | Godot는 화면 밖이어도 `_draw`를 실행 → 바뀐 것만, 보이는 것만 다시 그림 |
| **코드 생성** | `tools/roomgen.py` → `world/rooms/*.gd` + `_index.gd` | 방은 파이썬으로 짧게 쓰고, 게임은 미리 만든 데이터만 읽음 |

## 4. 자주 하는 수정 — 어디를 고치나
| 하고 싶은 것 | 고칠 곳 | 자세히 |
|---|---|---|
| 대사 고치기 | `game/story/<장>/<장면>.gd`에서 대사 문자열 검색 | story.md 2절 |
| 장면 순서 바꾸기 | 대본의 가드 플래그(`if c.has(...)`), 목표 줄(`OBJECTIVES`), 방 개체 `cond` → `python3 tools/story_lint.py --flags` | story.md 6절 체크리스트 |
| 장 추가·교체·삭제 | `data_<ext>.gd`(CHAPTER·SCRIPTS…) + `story/<ext>/` + `tools/rooms/<ext>.py` + `ChapterRegistry.EXTS` | story.md 6절 |
| 인물 추가 | `data_<ext>.gd` CHARACTERS (+ 전용 그림이면 `characters/special/`) | characters.md 2절 |
| 퀘스트·수업 추가 | `data_<ext>.gd` QUESTS (+ talk 훅 대본) | story.md 5절 |
| 방 추가·지형 수정 | `tools/rooms/<ext>.py` → `python3 tools/roomgen.py` → `check all`·`validate` | world.md 2절 |
| 소품 kind 추가 | `world/entities/<ext>/props.gd`의 `PROPS` 표 + `draw` | world.md 2절 |
| 배경·테마 추가 | `world/themes/themes_<ext>.gd`, `backdrop_<ext>.gd`(정적/`l.anim` 동적) | backdrop.md 3절 |
| 적·보스 추가 | `enemies/<ext>/` + `registry.gd` KINDS | enemies.md 3·4절 |
| 조작감·마법 수치 | `core/tuning.tres`(세라), `core/spells.gd`(마법 레벨·문구), 적은 각 파일 머리 상수 | player.md 2절 |
| 난이도 | `core/difficulty.gd`, `docs/bible/balance.md` | — |

## 5. 검증 (고친 뒤 반드시)
저장소 루트에서. `G`는 Godot 4.7.2 실행 파일 (내려받기: tools/test/README.md).
1. `python3 tools/roomgen.py && git diff --stat game/world/rooms` — 방 생성물이 생성기와 같은지(방을 고쳤으면 바뀐 방만 나와야 함)
2. `python3 tools/roomgen.py check all` (도달 문제 0) · `python3 tools/roomgen.py validate` (ERR 0)
3. `python3 tools/story_lint.py` (오류 0 — 없는 대본 ID·중복 ID) · 장면 순서를 바꿨으면 `--flags`
4. `cd game && $G --headless --script ../tools/test/check_scripts.gd` → `failures: 0`
5. 시나리오 회귀: `tools/test/regress.sh $G /tmp/before <시나리오…>`를 **고치기 전에**, 고친 뒤 `/tmp/after`로 같은 것을 돌려
   `diff <(grep -v '^#' /tmp/before/summary.txt) <(grep -v '^#' /tmp/after/summary.txt)` 와 `python3 tools/test/imgdiff.py /tmp/before/shots_<이름> /tmp/after/shots_<이름>`.
   시나리오는 난수를 고정(`seed`)하고, `FRAME_CLOCK=1`(regress.sh가 켬)이면 히트스톱 등 시간 효과도 프레임 기준이라 **같은 코드면 결과·스크린샷이 픽셀까지 같다**.
6. CI(`.github/workflows/web-build.yml`)가 푸시마다 1·2·4를 다시 확인한 뒤 웹 빌드를 배포한다.

## 6. 성능 규칙 (웹 단일 스레드·태블릿 기준)
- **매 프레임 통째로 다시 그리지 않는다.** 움직이지 않는 그림은 한 번 그리고, 움직이는 부분만 따로(배경 `l.anim`, 소품 `split`). 화면 밖이면 `queue_redraw`를 건너뛴다(배경·소품·적·인물에 이미 있음).
- `_process`/`_physics_process`에서 `get_nodes_in_group`·`load`·`Gradient.new()`·노드 생성을 반복하지 않는다 — 캐시·신호·`Fx.burst` 풀을 쓴다.
- 플래그는 폴링하지 말고 `GameState.flag_changed`를 듣는다.
- 성능 확인: `tools/test/scenarios/perf_*.json`(시장·축제·안뜰·시계탑) + runner `perf`/`bgperf` 명령.

## 7. 조용히 깨지는 것 (이름을 바꾸지 말 것)
플래그 이름 · 방 ID · 개체 ID(자동 플래그 `trig_<방>_<개체>`·`evt_…`) · 대본 ID(=메서드 이름, 방 데이터·퀘스트 talk·시나리오가 문자열로 부름) ·
적/개체/소품 kind · 인물 ID · 방 데이터가 `set()`으로 넣는 속성 이름 · `teach_` + 안내 제목(한글 제목이 곧 플래그) · 음악·효과음 이름.
없는 이름은 대부분 **오류 없이 무시**된다 — 그래서 story_lint·validate·회귀 시험이 있다. 바꿔야 하면 전부 grep해서 함께 바꾼다.
