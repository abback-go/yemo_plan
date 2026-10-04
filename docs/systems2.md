# 공통 시스템과 장별 모듈 규칙 (전체판)

> 2~5장을 여러 작업자(서브에이전트)가 **동시에** 만들 수 있게 정한 규칙. 장별 작업은 **자기 파일만** 만들고 고친다. 공용 파일을 고쳐야 할 것 같으면 고치지 말고 보고서에 "요청"으로 적는다(통합 담당이 반영).
> 정본: [`bible/`](bible/README.md) · 마법: [`magic.md`](magic.md) · 장 기획: `chapter2.md`~`chapter5.md`.

## 1. 장별 모듈 (ChapterRegistry — `game/core/chapter_registry.gd`)
확장 ID: `sys`(공통 시스템·학교 수업), `ch2`, `ch3`, `ch4`, `ch5`. 장 N 작업자가 소유하는 파일(`<ext>` = `chN`):

| 파일 | 내용 |
|---|---|
| `tools/rooms/<ext>.py` | 방 생성기 모듈. `from roomgen import Room, room, overlay` → `@room def k_market(): ...` (1장 `tools/roomgen.py`와 같은 문법). 학교 등 **다른 장의 방에 개체를 덧붙일 때** `overlay("s_hall", "npc", who="...", x=..., y=..., cond="...")` |
| `game/world/rooms/<방ID>.gd` | 생성 결과 (`python3 tools/roomgen.py` 또는 `python3 tools/roomgen.py <방ID>`) — 직접 고치지 말 것 |
| `game/story/data_<ext>.gd` | 장 데이터: `CHAPTER`(장 정보)·`SCRIPTS`(대본 파일 목록)·`CHARACTERS`·`OBJECTIVES`·`QUESTS` — 형식은 [`dev/story.md`](dev/story.md) 5절 (2026-10-04 리팩터로 바뀜; 방 목록은 생성된 `world/rooms/_index.gd`가 대신함) |
| `game/story/<ext>/*.gd` | 대본(장면·지역마다 한 파일, `extends RefCounted`, 메서드 이름 = 실행 ID, `func id(c: Cut) -> void`). `data_<ext>.gd`의 `SCRIPTS`에 적어야 읽힌다. 장 공용 도우미 `<ext>/common.gd`, 시험용 `story/dev/` |
| `game/enemies/<ext>/registry.gd` + `game/enemies/<ext>/*.gd` | `const KINDS := {"star_lizard": "res://enemies/ch2/star_lizard.gd"}` + 적 스크립트 |
| `game/world/entities/<ext>/entities.gd` + 장치 스크립트 | `const KINDS := {"gear_clock": "res://world/entities/ch2/gear_clock.gd"}` — 방 데이터의 `t`로 생성, 스크립트는 `setup(room: Room, e: Dictionary, eid: String)` |
| `game/world/entities/<ext>/props.gd` | 소품: `const PROPS`(kind → `{anim, glow, split}`) + `static func draw(p: Prop, kind: String)` — [`dev/world.md`](dev/world.md) |
| `game/world/themes/themes_<ext>.gd` | `const THEMES := {"kingdom": {...}}` (`room_theme.gd`와 같은 키 전부. `particles`: embers·foxfire·drips·petals·dust·motes·fireflies·stars·light·spores·ash·blight·leaves) |
| `game/world/themes/backdrop_<ext>.gd` | 배경: `has_theme`·`has_sky`·`draw_layer`(정적, 움직이는 요소는 `l.anim`에 기록)·`draw_sky` — [`dev/backdrop.md`](dev/backdrop.md) |
| `game/characters/special/<who>_draw.gd` · `<who>_portrait.gd` | 강자 전용 그림(2절) |
| `game/allies/<ext>_allies.gd` | (필요하면) 새 동료 종류 `const KINDS := {}` — 기본 동료는 공통 시스템이 제공(5절) |
| `tools/test/scenarios/<ext>_*.json` | 시험 시나리오 |
| `docs/chapterN.md` 7절 이후 | 세부 설계·구현 메모 |

- 방 크기·좌표 규칙은 1장과 같다(화면 1칸 40×23타일, 개체 y = 발이 닿는 바닥 행). 지도 칸(`cell`)은 **자기 영역(area) 안에서만** 겹치지 않으면 된다.
- 방 도달 검사: `python3 tools/roomgen.py check all <접두사>` — 모든 능력(2단 점프+여우창문+불꽃 날개·상승 기류)으로 출구·문·기록·줍는 것 사이가 닿아야 한다. 장의 게이트는 지형이 아니라 **대본·개체**(문 잠금, `gate`, 역병 덩굴 장치 등)로 막는다. 상승 기류는 `updraft` 개체(6절).
- 1장 개체 종류(그대로 사용): `exit`, `door`(lock·lock_msg·style), `spawn`, `save`(style), `trigger`(run·once·cond), `sign`(look·text — `|`로 쪽 나눔), `light`, `prop`, `pickup`, `brazier`, `gate`(open_if), `npc`(who·talk·face·cond), `enemy`(kind + 속성), `actor`, `event`(flag·run·done), `switch`, `target`, `float_lantern`, `puzzle`, `chaser`, `hint_mural`, `calm`, `cracked`. 모든 개체에 `cond`(플래그 식 — 쉼표 = 그리고, `!` = 아님: `"k_met_leonie,!k_spar_done"`, 1장 `RoomData.cond_ok`) 가능.

## 2. 강자·인물 전용 그림
- `data_<ext>.gd`의 `CHARACTERS["leonie"]`에 `"draw": "res://characters/special/leonie_draw.gd"`, `"portrait": "res://characters/special/leonie_portrait.gd"`를 넣으면 NPC·컷신·동료·보스 어디서든 그 그림을 쓴다. 이름·색·목소리 키(`name`, `color`, `voice`)는 필수.
- `static func draw_body(v: CharacterVisual) -> void` — `v`에 직접 그린다(원점 발밑, +x가 바라보는 쪽, 부모가 좌우 뒤집음). 쓸 수 있는 값: `v.time()`, `v.blinking()`, `v.walking`, `v.walk_phase()`, `v.talking`, `v.pose`(문자열), `v.pose_t`(그 자세가 된 뒤 초), `v.info`. 자세 이름 약속: `idle`, `run`, `windup`, `attack`, `attack2`, `guard`, `cast`, `aim`, `hurt`, `kneel`, `down`, `charge`, `special`. 모르는 자세는 `idle`로.
- `static func draw_portrait(p: Portrait, info: Dictionary, expr: String, t: float, talking: bool, blinking: bool) -> void` — 72×72 상반신. expr: normal·happy·angry·sad·surprised(+ 각자 특수 표정 가능).
- 그림 기준: [`bible/art.md`](bible/art.md) 3절(일반 인물보다 세부 2배, 3단 명암, 망토·머리 물결, 무기 반짝임).
- 보스 적의 몸 그림도 같은 스크립트를 쓰면 된다: `var v := CharacterVisual.new(); v.setup("leonie"); add_child(v)` 후 `v.set_pose("windup")`. 좌우는 `v.scale.x = facing`. 흰색 깜빡임은 `v.modulate`로.

## 3. 적 작성 규칙
- `EnemyBase` 상속(1장 `enemies/*.gd` 참고): `_build()`에서 `max_hp`, `body_size`, `display_name`(처음 만날 때 이름표), `subtitle`, `kind_id`, `is_boss`, `is_elite`, 시각 노드(`_visual`) → `_ai(delta)`.
- 체력은 [`bible/balance.md`](bible/balance.md) 2절의 **보통 난이도 값**을 적는다. 쉬움 배율은 `EnemyBase`가 자동으로 곱함(일반 0.7, 보스 0.75).
- 공격 예고 시간은 `Difficulty.telegraph(초)`, 공격 사이 쉬는 시간은 `Difficulty.rest(초)`로 감싼다. 예고는 **붉은색**(위험) — 1장 규칙. 바깥 신들 계열만 흰색 예고 허용(대신 굵고 깜빡이게).
- 세라가 받는 피해는 쉬움에서 자동으로 최대 1칸. 보통에서도 강자 보스 큰 기술만 2칸.
- 피해 종류(`Hit.kind`): `bolt`·`bolt_heavy`(화염탄), `pillar`, `storm`·`storm_final`, `blast`(폭주), `fox*`(여우 모드), **`ward`**(방벽 근접 화상), **`reflect`**(되쏜 탄), **`meteor`**, **`phoenix`**, `ally`(동료). 장치(별 수정 장벽은 `reflect`만, 금빛 봉인석은 `meteor`만, 역병 덩굴은 불 종류 전부)가 종류로 거른다.
- **되쏘기**: 적 탄은 `EnemyProjectile`을 쓰면 방벽에 자동으로 되쏘아진다. 직접 만든 탄은 `add_to_group(&"enemy_projectile")` + `func reflect(dir: Vector2, damage: int) -> void`(세라 공격으로 바뀌어 `Hit.kind = &"reflect"`로 적을 맞힘)를 구현.
- 보스: `is_boss = true` → 화면 아래 체력바. 대본이 `engaged = false`로 두었다가 시작 신호. 페이즈 바뀔 때 `phase_changed.emit(n)`. 쓰러뜨리면 `defeated`.
- 동료가 때리는 피해는 `Hit.kind = &"ally"` — 강자 보스가 동료 공격에 "막기" 반응을 해도 된다(연출).

## 4. 퀘스트 (`Quests` — `game/core/quests.gd`)
- 정의(`data_<ext>.gd`의 `QUESTS`):
  ```gdscript
  "k_mia_bread": {
      "title": "미아의 빵 배달", "giver": "mia", "kind": "side",  # side · class · main
      "chapter": 2, "need": "k_met_leonie",                        # need: 이 플래그가 서야 받을 수 있음("!" 표시)
      "desc": "갓 구운 빵을 세 곳에 배달하자.",
      "steps": ["기사단 연무장의 카엘", "대장간의 브론", "대성당의 사제"],
      "reward": {"stones": 1, "potion_slot": 0, "heart": 0, "feather": 0, "text": "레오니의 옛이야기"},
  }
  ```
- 대본에서: `c.quest_start("k_mia_bread")`, `c.quest_step("k_mia_bread", 1)`(0부터, 퀘스트창에 현재 단계 표시), `await c.quest_done("k_mia_bread")`(보상 지급 + 알림). 상태 읽기: `Quests.state(id)`(0 없음·1 진행·2 완료), `Quests.step(id)`.
- 인물 머리 위 표시: 그 인물이 `giver`인 퀘스트 중 받을 수 있는 것이 있으면 **"!"**, 진행 중이면 **"…"**. 퀘스트를 주는 대화는 그 인물의 `npc_<who>` 대본 안에서 `Quests.state`를 보고 분기.
- 퀘스트창: 일시정지 → "퀘스트"(메인 목표 / 서브 / 수업). HUD에는 메인 목표 한 줄 + 가장 최근 서브 퀘스트 단계 한 줄.

## 5. 동료 (`Ally` — `game/allies/ally.gd`)
- 종류: `leonie`(검: 잔상 돌진 베기), `elarien`(활: 먼 거리 저격, `hold` 모드면 제자리에서), `aurelia`(창: 찌르기·짧은 신성 돌진), `astrid`(별 마법 탄), `isolde`(서리 조각), `emberlyn`(화염구). 그림은 그 인물의 `CharacterVisual`(전용 그림 포함)을 쓴다.
- 대본: `var a := c.ally_join("leonie")`(세라 옆에 나타남, 방을 옮겨도 따라옴), `c.ally_leave("leonie")`, `c.ally("leonie")`.
  - `a.mode = "follow" | "hold" | "script"` (`hold`: 지금 자리에서 원거리 지원, `script`: AI 끔 — 대본이 움직임)
  - `await a.move_to(x_t, y_t)`, `a.say("말풍선")`, `a.special(target)`(큰 지원기 — 레오니 "다리를 벤다!": 대상 경직 2초 등), `a.down()`/`a.up()`(쓰러짐/일어섬 연출), `a.set_pose("...")`
- 동료는 죽지 않는다(체력 없음). 피해는 보조 수준(초당 약 60~100), 강자 보스전에서 틈을 만드는 것이 역할.

## 6. 이동·장치 (공통 시스템 제공)
| 개체 `t` | 키 | 설명 |
|---|---|---|
| `updraft` | x, y, w, h, style(`heat`·`wind`·`star`), power(기본 1.0), on_if(플래그 식) | 상승 기류. **불꽃 날개로 활공 중**일 때 위로 솟게 함. 보이는 그림(열기 아지랑이·바람줄·별가루) |
| `warp` | area | 전이진. ↑로 열면 해금된 지역 목록(학교·제국·엘프·신전). 지역 해금은 대본 `c.warp_unlock("kingdom")` |
| `pickup` kind=`stone` | id | 마도석(+1). kind=`feather`(최대 체력 +1, 1장), kind=`note`(읽을거리) |
| `class_board` | — | 수업 게시판(학교 중앙 홀) — 마법 배우기 창 |

- 세라 상태 읽기: `player.is_gliding()`, `player.is_warding()`, `player.ward_center()`.
- 학교에 이미 놓인 것(공통 시스템): 중앙 홀 수업 게시판(`ch1_done`), 앞마당 전이진·등장 위치 `warp`(`ch1_done`), 수업 방 5개(`s_windtower`·`s_observatory`·`s_duel`·`s_ashstacks`·`s_phoenix`)와 그 문. 학교 지도 칸 중 (0,3)~(0,5)·(1,4)~(2,5)·(3,4)·(3,5)~(4,5)·(6,-1)은 이미 씀.

## 7. 장 흐름 (`ChapterFlow` — `game/core/chapter_flow.gd`)
- `ChapterFlow.current()` = 지금 장(플래그 `chapter`, 없으면 1).
- 장의 시작 대본 `chN_start`는 `ChapterFlow`가 장 카드 뒤에 부른다. 장 끝 대본은 마지막에 `await ChapterFlow.finish(c, N)` — `chN_done` 저장, 너울 꼬리 연출, 다음 장 카드, 다음 장 `ch(N+1)_start` 실행. 5장은 엔딩 크레디트를 5장 대본이 직접(`c.credits()`), 그 뒤 `await ChapterFlow.finish(c, 5)`.
- 장 카드 제목: 2 "제국의 검", 3 "세계수의 눈", 4 "황금창의 수호자", 5 "별의 마녀".

## 8. 대본 도구 추가분 (`Cut`)
| 함수 | 설명 |
|---|---|
| `await c.title_card(title, sub := "", sec := 2.5)` | 화면 가운데 큰 글씨 카드(레터박스) |
| `c.letterbox(on: bool)` | 위아래 검은 띠 |
| `c.tint(color: Color, time := 0.5)` | 화면 전체 색 덮기(투명색이면 걷힘) |
| `c.zoom(z: float, time := 0.6)` | 카메라 확대(1.0 원래) |
| `c.ally_join/ally_leave/ally` | 5절 |
| `c.quest_start/quest_step/quest_done` | 4절 |
| `c.give_stones(n)`, `c.give_feather()`, `c.give_potion_slot()`, `c.give_heart()` | 보상(알림 포함) |
| `await c.tails(n)` | 너울 꼬리가 n개로 — 짧은 연출 |
| `c.warp_unlock(area)` | 전이진 목적지 해금 |
| `await c.spell_learned(id)` | 마법 습득 연출(수업 담당이 씀) |
| `await c.credits()` | 엔딩 크레디트(5장) |
- 1장 도구(그대로): `say`, `narrate`, `choose`, `bubble`, `wait`, `shake`, `flash`, `sfx`, `music`, `fade_out/in`, `hud`, `vignette`, `weather`, `actor`, `walk`, `approach`, `face`, `emote`, `player_walk/face`, `camera_to/back`, `marker`, `flag`, `has`, `learn`, `teach`, `goto_room`, `save_here`, `wait_for_threat`, `wait_until`, `wait_enemy`, `enemy`, `spawn_enemy`, `spawn_npc`, `move`, `hide_actor`, `item`, `save`, `give_potions`, `lock`, `freeze_enemies`. 규칙은 `docs/status.md` 5.1절(대본 작성 규칙).

## 9. 소리 이름 (오디오 담당이 만듦 — 없을 때도 안전하게 무시됨)
- 음악: `school_day`, `kingdom`, `kingdom_night`, `knight_duel`, `starbeast`, `elf`, `elf_hunt`, `herald`, `temple`, `temple_dark`, `chase`, `aurelia`, `star_tower`, `lyra`, `despair`, `nine_tails`, `final`, `ending2`, `festival` + 1장 곡. 징글 `jingle_spell`, `jingle_levelup`, `jingle_chapter`.
- 효과음: `sword_slash`, `sword_clash`, `parry`, `sword_wave`, `arrow_shot`, `arrow_hit`, `bow_draw`, `holy_charge`, `holy_hit`, `bell`, `bell_small`, `star_twinkle`, `star_burst`, `glide`, `updraft`, `ward`, `reflect`, `meteor_fall`, `meteor_impact`, `phoenix_cry`, `colossus_step`, `sky_crack`, `crowd`, `wind`, `spear`, `warp`, `quest`, `quest_done`, `levelup`, `heartbeat`, `menu_open`, `menu_close`, `magic_learn` + 1장 소리.

## 10. 시험 (각 장 작업자가 반드시)
1. `cd game && $G --headless --import` 후 `$G --headless --script ../tools/test/check_scripts.gd` → 실패 0.
2. `python3 tools/roomgen.py check all <접두사>` → 문제 없음(의도한 게이트는 대본으로).
3. 시나리오(`tools/test/README.md`): 적·보스마다 한 번(무적 없이 피격·처치 확인), 장 처음부터 끝까지 한 번(순간이동·처치로 진행, 끝에 다음 장 시작 확인), SCRIPT ERROR 0.
4. 스크린샷으로 배경·인물·보스 그림을 직접 보고 다듬는다.
