# 대본·진행 데이터 개발 안내 (story / core 진행 시스템)

다음 사람이 이 문서만 보고 대본·장·퀘스트·목표를 고칠 수 있게 쓴 안내. 코드 식별자·경로는 원문 그대로.
검사 도구: `python3 tools/story_lint.py` (7절). 방 데이터 흐름은 `docs/dev/world.md`.

## 1. 구조 지도

```
game/core/chapter_registry.gd   ChapterRegistry — EXTS(ch1, sys, ch2…ch5) 순서로 data_<ext>.gd 상수를 합친다
game/story/data_<ext>.gd        장 데이터: CHAPTER · SCRIPTS · CHARACTERS · ROOMS · OBJECTIVES · QUESTS
game/story/<ext>/*.gd           대본(장면·지역마다 한 파일). <ext>/common.gd = 장 공용 상수·도우미
game/story/dev/<ext>.gd         시험용 대본 dev_* (시나리오가 부름)
game/story/story.gd             Story 오토로드 — 대본 로드·ID 색인·실행(run)·읽기(read)
game/story/cut.gd               Cut — 대본이 받는 연출 명령 모음 (3절)
game/story/objectives.gd        Objectives — HUD 현재 목표 (지금 장 OBJECTIVES + sys)
game/story/characters.gd        Characters.info(who) — 장별 CHARACTERS를 키 단위로 합침
game/core/cond.gd               Cond.ok(expr) — 조건식 하나 (5절)
game/core/quests.gd             Quests — 퀘스트 상태(q_<id>), 수업 판정(class_status…), talk 훅
game/core/rewards.gd            Rewards.grant(dict) — 보상 숫자 올리기 한 곳
game/core/spells.gd             Spells — 마법 7종 표, 능력 습득 문구 ABILITY_TEXT
game/core/chapter_flow.gd       ChapterFlow.finish(c, n) — 장 끝 → 꼬리 → 저장 → 다음 장 카드 → ch<n+1>_start
game/core/warp_db.gd · credits.gd   전이진 목적지·엔딩 크레디트 (CHAPTER.warps·credits에서 읽기만)
```

흐름: 방 개체(트리거·인물·표지판…) 또는 코드가 `Story.run(id)` → 색인에서 그 메서드를 가진 대본 객체를 찾아
`Cut`을 만들고(`begin` = 조작 잠금) `await 메서드(c)` → 끝나면 `c.finish()`.

**쓰인 패턴과 이유**
- 대본 = GDScript 메서드 (`await c.say(...)`): 분기·반복·적 생성까지 한 곳에서. 메서드 이름이 곧 실행 ID.
- 장 = 확장(EXTS): 장을 더해도 공용 파일을 고치지 않는다. 1장도 `ch1` 확장이다(특례 없음).
- 장면 파일 + `common.gd` 상속(한 단계): 파일이 짧아지고, 도우미는 장 안에서만 공유.
- 대본 로드는 `Story._compile_together`가 preload 묶음 하나로 한 번에 컴파일한다 — 파일마다 따로 load하면
  Cut·World·Player 같은 의존 분석을 파일 수만큼 되풀이해 시작 CPU가 +1.5초였다(대본 36개, 리눅스 측정).

## 2. 대본 쓰기

**파일 위치**: 장면(지역)마다 `game/story/<ext>/<장면>.gd`(200~500줄 목표), 첫 줄
`extends "res://story/<ext>/common.gd"`(공용이 없는 장은 `extends RefCounted`). 새 파일은 반드시
`data_<ext>.gd`의 `SCRIPTS`에 적는다 — 웹 내보내기에서 폴더 나열을 믿을 수 없어서 명시 목록이다.

**대본 ID 규칙**: 공개 메서드 `func <id>(c: Cut) -> void` = 실행 ID. `_`로 시작하면 도우미(ID 아님).
- 전체 게임에서 ID는 하나뿐이어야 한다. 두 파일에 있으면 Story가 앞 파일(SCRIPTS 순서)을 쓰고 `push_error`.
- `common.gd`에는 공개 메서드를 두지 않는다(장면 파일마다 중복 ID가 된다).
- 다른 파일의 대본을 같은 컷으로 이어 부를 때: `await c.call_script("k_spar")` (같은 파일이면 `await k_spar(c)`).

| 접두어 / 이름 | 누가 부르나 | 비고 |
|---|---|---|
| `enter_<방ID>` | 방에 들어올 때 `Story.on_room_entered` | 잠그지 않고(soft) 시작 — 컷신이면 `c.lock()`부터 |
| `npc_<who>` | 인물에게 말 걸기 (`Npc.talk` 기본값) | 방 데이터 `talk=`로 다른 ID 지정 가능 |
| `npc_<who>_ch<N>` | 위와 같음, 지금 장 N 이하에서 가장 높은 장 것이 이김 | 장별 덮어쓰기 |
| 퀘스트 `talk` 훅 | 진행 중 퀘스트의 지금 단계·인물과 맞으면 `npc_` 대신 | `[[단계, 인물, 대본ID]]` |
| `ch<N>_start` | `ChapterFlow.finish(c, N-1)` 끝 | 장 카드 뒤 |
| `cls_<마법>_begin` | 수업 게시판 "수업 신청" | 수업 퀘스트(kind = class) |
| `teach_<이름>` | 트리거·world.gd | 멈춤 안내 — 세라를 멈춰 세우지 않음(soft) |
| 방 `run=` | `trigger`(StoryTrigger) · `event`(flag_event) · 표지판(Readable) | 아래 함정 참고 |
| `dev_*` | 시험 시나리오 `["run", id]` | `game/story/dev/` |
| 코드 고정 ID | world.gd: `sys_chapter1_resume`·`teach_overload`·`teach_dodge` | 이름 바꾸면 코드도 |

**첫 줄 가드 관용구** (트리거는 대부분 once=False — 쓰러져도 다시 걸리게):
```gdscript
func k_spar(c: Cut) -> void:
	if c.has("k_spar_done") or not c.has("k_met_leonie"):
		return
	c.lock()
	…
	c.flag("k_spar_done")
	c.save()
```

**방 개체 트리거 표**

| 방 데이터 `t` | 동작 | 자동 플래그 |
|---|---|---|
| `trigger` | 영역에 들어가면 `run` (once 기본 true) | `trig_<방>_<id>` (once일 때) |
| `event` | `flag`가 서면 `run` 한 번 | `done` 기본 `evt_<방>_<id>` |
| `npc` | 말 걸기 → `talk`(기본 `npc_<who>`) | — |
| `sign` 등 Readable | `run`이 있으면 대본, 없으면 `text`를 읽기 | — |
| `blight_vine` | `first`·`hint` 대본(있을 때만) | `seen_<first>` |

## 3. Cut 명령 사전 (`game/story/cut.gd`)

`await`가 붙은 것은 끝날 때까지 기다린다. 좌표 `x_t`/`y_t`는 타일(16px), `who`는 인물 ID(`"sera"`·`"neoul"` 특수).

- 잠금: `ok()` 대본이 아직 유효한가(쓰러졌으면 false) · `begin()`/`finish()`(Story가 부름) · `soft()` · `release()` 조작 먼저 돌려줌 · `lock()` 다시 잠금 · `freeze_enemies(on)`
- 대사: `await say(who, text, expr)` · `await narrate(text)` · `await choose(who, text, options) -> int` · `close_box()` · `bubble(text, time)` 너울 말풍선
- 시간·화면: `await wait(sec)` · `shake(amp, dur)` · `flash(color, dur)` · `sfx(name, vol)` · `music(name, fade)` · `await fade_out(t, color)` · `await fade_in(t)` · `hud(on)` · `vignette(s)` · `weather(kind)` fox_rain·dust
- 연출 도구: `await title_card(title, sub, sec)` · `await chapter_card(n)` · `letterbox(on)` · `tint(color, time)` · `zoom(z, time)` · `burst(pos, n, col, opts)` 가산 빛 입자(`Fx.burst` 옵션)
- 인물: `actor(who)` · `npc(who) -> Npc` · `actor_pos(who)` · `await walk(who, x_t, speed)` · `await approach(who, dist)` · `face(who, dir)` · `emote(who, kind, time)` · `pose(who, p)` Npc 그림 자세 · `await move(who, x_t, y_t, time, trans)` · `hide_actor(who)` · `spawn_npc(who, x_t, y_t, dir) -> Npc` · `beside(who, dx) -> Npc` 세라 곁에 세움
- 세라·카메라: `await player_walk(x_t)` · `player_face(dir)` · `player_tile() -> Vector2` · `await camera_to(pos, time)` · `await camera_back()` · `marker(id)` 방 표식 위치
- 진행: `flag(key, value)` · `has(key)` · `Cut.count(flags) -> int`(정적) · `await learn(ability)` 1장 능력 습득 · `await spell_learned(id)` 수업 마법 습득 · `await teach(title, text, keys, wait_for)` → 플래그 `teach_<title>` · `warp_unlock(area)` → `warp_<area>` · `await tails(n)` 너울 꼬리
- 퀘스트·보상: `quest_start(id)` · `quest_step(id, n)` · `await quest_done(id)`(보상 지급 + 알림) · `await give_stones(n)` · `await give_feather()` · `await give_heart()` · `await give_potion_slot()` · `give_potions(n)` 물약 칸을 n으로 · `await item(title, desc)` 얻음 알림
- 방·저장: `await goto_room(room, spawn)` · `save_here(spawn)` · `save()` 이 방 기록 지점으로 자동 저장
- 적·동료: `enemy(kind)` · `spawn_enemy(kind, x_t, y_t, eid, props)` · `await wait_enemy(e, hp_frac, timeout)` · `await wait_until(callable, timeout)` · `await wait_for_threat(radius, timeout)` · `ally_join(kind, x_t, y_t)` 항상 세라 곁에 다시 놓음 · `ensure_ally(kind, x_t, y_t)` 없을 때만 합류 · `ally_leave(kind)` · `ally(kind)`
- 대본 잇기·기타: `await call_script(id)` · `await credits(lines, sec)` (기본 `Credits.lines()`)

## 4. 플래그 이름 규칙

플래그는 `GameState`의 평평한 사전 하나(bool·int·string). 이름이 곧 저장 키다.

| 접두어 | 뜻 | 접두어 | 뜻 |
|---|---|---|---|
| `t_`·`p_` | 1장 프롤로그(신계) | `ab_<능력>` | 능력 배움 (`unlock_ability`) |
| `s_` | 1장 학교 | `lv_<마법>`·`eq_<칸>` | 마법 레벨·장착 |
| `k_` | 2장 제국 | `mana_stones`·`mana_total` | 마도석 |
| `e_` | 3장 엘프 | `q_<id>`·`q_<id>_step`·`q_last` | 퀘스트 상태 |
| `tp_` | 4장 대신전 | `warp_<지역>` | 전이진 해금 |
| `st_`·`r5_` | 5장 | `temp_<능력>` | 수업 시험 중 임시 능력 |
| (없음) | 1장 옛 이름 `met_emberlyn`·`key_stolen`·`chapter_end`… | `ch<N>_done`·`chapter`·`tails` | 장 흐름 |
| `trig_<방>_<id>`·`evt_<방>_<id>` | 트리거·이벤트 자동 | `teach_<한글 제목>` | 멈춤 안내 자동 |

## 5. 데이터 형식 (`game/story/data_<ext>.gd`)

```gdscript
const CHAPTER := {"n": 2, "title": ["2장", "제국의 검"], "tails_at_end": 2,      # last: true면 마지막 장
	"areas": {"kingdom": "황도 아르덴"},                                          # 지도 제목
	"warps": [["kingdom", "k_embassy", "warp", "아르덴 제국 — 공관", "warp_kingdom"]],
	"credits": ["# 아르덴 제국", "제국제일검 레오니 발렌하르트", ""]}
const SCRIPTS := ["res://story/ch2/school.gd", …, "res://story/dev/ch2.gd"]
const OBJECTIVES := [["k_spar_done", "기사단 연무장에서 레오니와 대련하자", "k_met_leonie"], …]
const QUESTS := {"k_mia_bread": {"title": "미아의 빵 배달", "giver": "mia", "kind": "side", "chapter": 2, "need": "k_met_leonie",
	"desc": …, "steps": ["빵 배달 (0/3) …", …, "빵집의 미아에게 돌아가기"], "reward": {"stones": 1, "text": "레오니의 옛이야기"}}}
# talk 훅 예: "talk": [[1, "luca", "tp_luca_return"]] — 1단계에서 루카에게 말 걸면 npc_luca 대신 tp_luca_return
```
- **OBJECTIVES** `[완료 플래그, HUD 문구, 필요 조건]`: 지금 장 줄 + sys 줄 중 "필요 조건이 참이고 완료 플래그가 아직"인 첫 줄이 현재 목표.
- **QUESTS**: `kind` side(서브)·class(수업)·main. `need`(Cond 식) = 받을 수 있는 때(인물 머리 "!"). 단계는 `c.quest_step`.
  `talk`의 `[단계, 인물, 대본]`은 그 단계에서 그 인물과의 대화를 대신한다. `reward` = `Rewards.grant` 키(stones·potion_slot·heart·feather·text).
- **수업**(kind = class, `data_sys.gd`): + `spell`, `unlock`(Cond 식), `unlock_text`. 신청하면 `cls_<spell>_begin`.
- **CHARACTERS**: 같은 ID가 여러 장에 있으면 뒤 장의 **키만** 덮어쓴다(5장이 교장에게 전용 그림만 덧붙임).

**조건식(Cond.ok)** — 목표·퀘스트 need/unlock·방 개체 `cond`/`on_if`/`open_if`/`lock`… 모두 같다:
`""` 항상 참 · `"a"` 플래그 a · `"!a"` a 아님 · `"a,b,!c"` 쉼표 = 그리고 · `"mana>=6"` 모은 마도석 6 이상. "또는"은 없다(필요하면 플래그를 하나 더 세움).

## 6. 체크리스트

**장면 순서 바꾸기** (예: `k_spar_done`을 앞당김) — 플래그 하나가 다섯 종류의 장소에 있다:
1. `grep -rn k_spar_done game tools/rooms tools/test/scenarios`
2. 대본 가드(`c.has`)·`c.flag` 위치 — `game/story/ch2/*.gd`
3. `data_ch2.gd` OBJECTIVES·QUESTS need, `data_sys.gd` 수업 unlock
4. 방 py(`tools/rooms/ch2.py`)의 `cond=` → `python3 tools/roomgen.py` 재생성
5. 시나리오 JSON의 `flags` 목록 → `python3 tools/story_lint.py --flags`

**장 추가** (N장): ① `data_chN.gd`(CHAPTER n·title·areas·warps·credits, SCRIPTS, CHARACTERS, ROOMS, OBJECTIVES, QUESTS)
② `game/story/chN/*.gd`(+ `common.gd`), 첫 대본 `chN_start`, 끝 `await ChapterFlow.finish(c, N)` ③ `tools/rooms/chN.py` → roomgen
④ `ChapterRegistry.EXTS`에 `"chN"` ⑤ 앞 장의 CHAPTER에서 `last` 옮기기 ⑥ 음악·적·소품 등은 각 확장 파일(선택) ⑦ story_lint.
**장 교체**: 같은 ext 이름으로 data·대본 폴더·rooms py를 바꾼다. 다른 장이 그 장의 플래그를 읽는지 `--flags`로 확인.
**장 삭제**: EXTS에서 빼면 data·대본·적·소품이 함께 빠진다. 다음 장 `chN_start`가 앞 장 플래그(`ch<N-1>_done`)를 읽는지 확인.

**인물 추가**: 장의 CHARACTERS에 항목(이름·색·목소리·몸 그림 값, 전용 그림이면 `draw`/`portrait` 경로) → 방 py에 `npc`
→ 대화 `npc_<who>`(또는 `talk=`) 대본. 이름 ID는 저장·대본·방에 퍼지므로 바꾸지 말 것.

**퀘스트 추가**: QUESTS에 항목 → 주는 인물의 `npc_` 대본에서 `c.quest_start(id)` → 단계 `c.quest_step` → 끝 `await c.quest_done(id)`
(보상은 reward에서 자동). 다른 인물과의 대화가 단계마다 바뀌면 `talk` 훅. 모으기는 `Cut.count([...])`·방 `quest_counter`.

**대본 파일 추가·나누기**: 새 파일 → SCRIPTS에 경로 → story_lint(목록 밖 파일·중복 ID를 잡음).

## 7. story_lint

`python3 tools/story_lint.py` — 오류가 있으면 종료 코드 1. `--flags`로 플래그 검사, `--quiet`는 경고 숨김.
- 오류: 대본 ID 중복, SCRIPTS 파일 없음·목록 밖 대본 파일, 없는 대본 ID 호출(방 run/talk, 퀘스트 talk, ch<N>_start, 코드 문자열, 시나리오 run)
- 경고: 기본 대화 없는 인물, 없는 방의 enter_, cls_<마법>_begin 없음, 읽기만/세우기만 하는 플래그
- 정규식 추정이라 오탐이 있다. 확인한 것은 파일 위 `ALLOW_UNSET`/`ALLOW_UNREAD`에 이유와 함께.
- 지금 알려진 것: `s_advclass`의 `run="s_adv_after"`(함수 없음 — 방 정리 담당), 이벤트 플래그 `adv_fight_won`(세우는 곳 없음),
  `student_a/b/c` 기본 대화 없음(5장 방), 세우기만 하는 기록 플래그 5개(`e_end`·`k_brooch`·`st_truth`·`tp_holy_water`·`tp_lyra_seen`).

## 8. 함정 (조용히 깨지는 것)

- **대본 ID = 메서드 이름**: 바꾸면 경고 한 줄만 남고 아무 일도 안 일어난다. 방 py·퀘스트·시나리오(run 단계 95회, 대부분 dev_)를 함께 → story_lint.
- **`teach_` + 한글 제목**: `c.teach("폭주 게이지", …)`가 `teach_폭주 게이지`를 세우고 world.gd·시나리오 40여 곳이 그 이름을 읽는다. 안내 제목을 고치면 진행이 깨진다.
- **`trig_`/`evt_` 자동 플래그**: 방 ID·개체 ID를 바꾸면 이미 본 장면이 다시 나온다.
- **동적 경로**: `ChapterRegistry`의 `res://story/data_%s.gd` 등 패턴, SCRIPTS 경로, 인물 `draw`/`portrait`. 파일을 옮기면 `ResourceLoader.exists`가 false가 되어 조용히 빠진다(SCRIPTS 누락은 Story가 push_error).
- **시험 실행기 의존**: `tools/test/runner.gd`가 `load("res://story/objectives.gd").current()`, `ClassBoardUI.status`, `Story.busy/run`,
  `res://core/spells.gd`를 쓴다 — 경로·이름 유지.
- **쓰러진 뒤에도 도는 대본**: Cut 메서드는 스스로 `ok()`를 보지 않는다. 오래 기다리는 대본(`wait_until`·전투 루프)은 `if not c.ok(): return`을 넣을 것.
- **common.gd의 var**: 장면 파일마다 객체가 따로라 `var`는 파일끼리 공유되지 않는다. 상태는 플래그나 한 파일 안에 둔다.
- **`ChapterFlow.TITLES`**는 옛 이름 호환용 getter(ui/cinema.gd). 새 코드는 `ChapterFlow.title(n)`.
- 옛 문서(docs/archive/sera/chapterN.md·magic.md)의 `scripts_chN.gd`·`ch4/talk.gd`·`ch4/base.gd`는 지금 `story/chN/*.gd`(장면 파일)·`story/ch4/people.gd`·`story/ch4/common.gd`+`story/dev/ch4.gd`다.

## 9. 성능 규칙

- 대본 파일은 시작할 때 한 번에 컴파일(`Story._compile_together`). 파일을 늘려도 SCRIPTS에만 적으면 된다 — 개별 `load()`를 따로 추가하지 말 것.
- `Story.has_script`·`run`은 사전 조회(O(1)). 대본 객체 목록을 직접 훑지 말 것.
- 매 프레임 `Objectives.current()`·`Quests.class_status()`·`Cond.ok()`를 부르지 말 것 — 플래그가 바뀔 때(`GameState.flag_changed`)만 다시 계산.
- 대본의 `wait_until` 조건은 매 물리 프레임 불린다 — 그룹 탐색·문자열 조립을 넣지 말 것.
- `ChapterRegistry`의 합친 결과는 캐시된다(`_cache`). 데이터 상수는 읽기 전용 — 고치려면 `duplicate()`.
