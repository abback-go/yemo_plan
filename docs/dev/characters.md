# 인물 그림·NPC·동료 구조 — 고치는 사람용 안내

대상 코드: `game/characters/`(special 포함), `game/allies/`, `game/fox/neoul_pet.gd`. 세라 본체는 [player.md](player.md).

## 1. 구조 지도

| 파일 | 하는 일 |
|---|---|
| `characters/character_visual.gd` (`CharacterVisual`, Node2D) | 작은 몸 그림. 기본 그림(옷·머리·모자·장식) 또는 전용 그림 스크립트 `draw_body(v)`. 숨쉬기·깜빡임·걷기·말하기 |
| `characters/portrait.gd` (`Portrait`, Control) | 대화창 72×72 초상화. 기본 사람 그림 + 표정 5종, 또는 전용 초상화 `draw_portrait(...)` |
| `characters/npc.gd` (`Npc`, Interactable) | 방에 서 있는 인물. 말 걸기 → `Story.run(talk)`, 퀘스트 표시(! …), 감정 말풍선 |
| `characters/emote_bubble.gd` (`EmoteBubble`) | 세라·대본 인물 머리 위 감정 기호 |
| `characters/bubble_draw.gd` (`BubbleDraw`) | 감정 기호표 + 둥근 감정 말풍선·네모 혼잣말 말풍선 그리기 공용 |
| `characters/draw_kit.gd` (`DrawKit`) | 전용 그림 공용 도형: `seg`, `outlined_poly`, `grow_poly`, `ellipse` |
| `characters/special/<인물>_draw.gd` / `_portrait.gd` | 전용 몸 그림·초상화 (모두 `RefCounted` + static 함수) |
| `characters/special/<인물>_palette.gd` | 그 인물의 draw·portrait가 같이 쓰는 색. 두 파일이 이 파일을 `extends` 한다 |
| `allies/ally.gd` (`Ally`, CharacterBody2D) | 동료 AI(따라다님·대상 고르기·공격), 대본용 큰 지원기 `special()` |
| `fox/neoul_pet.gd` (`NeoulPet`) | 작은 여우 너울(따라다님·말풍선·여우 모드 때 사라짐) |

### 인물 데이터 흐름
- 인물 값: `story/characters.gd`의 `Characters.DB`(1장) + 각 장 `story/data_<장>.gd`의 `CHARACTERS`를 `ChapterRegistry.characters()`가 합친다(같은 ID면 키를 덮어씀). `Characters.info(who)`가 합친 결과를 캐시한다.
- 키: 이름·색·목소리 + 몸 그림 값(`robe`, `robe2`, `skin`, `hair`, `hair_style`, `hat`, `hat_col`, `eye`, `height`, `extra`) + 전용 그림 경로 `"draw"`, `"portrait"`.
- `CharacterVisual.setup(who)`가 `info.draw`를, `Portrait`가 `info.portrait`를 `ResourceLoader.exists` → `load`로 읽는다. **경로가 틀려도 오류가 없고 기본 그림으로 바뀐다**(3절).
- 전용 그림이 읽는 것: `v.pose`/`v.pose_t`(자세·자세 시간), `v.time()`, `v.blinking()`, `v.walk_phase()`, `v.walking`, `v.talking`, `v.info`, 메타(`halo`, `berserk`, `aim_ang`, `warn` …).

## 2. 이럴 때는 여기를 고친다

### 새 인물 추가 (기본 그림)
1. 그 장의 `story/data_<장>.gd` `CHARACTERS`에 ID 항목 추가(1장 인물이면 `Characters.DB`). 몸 그림 키를 모두 채운다.
2. 방 데이터에 `{t = "npc", who = "<ID>", talk = "...", face = "left"}` (말 걸기 대본은 `npc_<ID>`가 기본).
3. 끝. 그림·초상화는 기본 그림으로 나온다.

### 새 인물 추가 (전용 그림)
1. `characters/special/<id>_draw.gd`: `extends RefCounted`(또는 팔레트), `static func draw_body(v: CharacterVisual) -> void` — 원점 발밑, +x가 바라보는 쪽.
2. `characters/special/<id>_portrait.gd`: `static func draw_portrait(p: Portrait, info: Dictionary, expr: String, t: float, talking: bool, blinking: bool) -> void` — 72×72 안. 기본 얼굴을 바탕으로 쓰려면 `p.draw_person(info)`, 눈·입만 쓰려면 `p.draw_eyes(fc, eye)`·`p.draw_mouth(fc)`.
3. 두 파일이 같은 색을 쓰면 `<id>_palette.gd`(`extends RefCounted` + `const`)를 만들고 두 파일 첫 줄을 `extends "res://characters/special/<id>_palette.gd"`로. **값이 다른 같은 이름은 팔레트에 넣지 말 것**(부모 상수와 같은 이름을 다시 정의하면 오류).
4. 도형은 `DrawKit`(윤곽선·부풀리기·타원)과 2장 공용 `KArt`(`world/entities/ch2/k_art.gd`: 꼬여도 안전한 `poly`, `glow`, 별 등)를 쓴다.
5. 그릴 때 상태를 쌓는다면(스프링·메타에 이전 값 저장) 파일에 `const KEEP_DRAWING := true`를 둔다(4절).
6. data 파일 항목에 `"draw"`·`"portrait"` 경로를 넣고, **경로를 grep으로 다시 확인**한다.
7. 회귀: `ch2_portraits`, `ch3_portrait`, `ch5_portrait`, `ch3_visuals`, `ch4_aurelia_art`, `ch2_leonie_duel`, `ch5_lyra_boss` 스크린샷 비교.

### 동료 추가
1. `allies/ally.gd` `SPECS`에 종류 추가: `who`(그림 ID), `attack`(slash·spear·arrow·star·frost·fireball), `range`(T), `cd`, `dmg`, `speed`(T/s), `keep`(원거리 거리 T, 0이면 근접), `float`.
2. 큰 지원기가 따로 있으면 `SPECIAL`에 `line`·`delay`·`mult`·`stagger`·`iframes` 값, `special()`의 `match kind`에 분기. 없으면 기본(기본 공격 × `SPECIAL_DEFAULT_MULT` 원거리).
3. 장 전용 동료 스크립트가 필요하면 `allies/<장>_allies.gd`에 `KINDS = {종류: "res://...gd"}`(`ChapterRegistry.ally_kinds()`), 스크립트는 `extends Ally`.
4. 대본: `w.ally_join(kind, x, y)`, `ally.say(...)`, `ally.special(en)`, `ally.move_to(x, y)`, `down()`/`up()`.

### 감정 기호·말풍선
- 기호표는 `BubbleDraw.GLYPHS`. **"sweat"(땀)은 출처마다 다르게 보인다**(지금 모습 보존):

  | 출처 | sweat 기호 |
  |---|---|
  | 세라·대본 인물 `EmoteBubble` (`"bubble"`) | `~` |
  | 방 NPC `Npc` (`"npc"`) | `💧` |
  | 너울 `NeoulPet` (`"pet"`) | 표에 없어 `sweat` 글자 그대로 |

  통일하려면 `BubbleDraw.SWEAT`만 고치면 된다.
- 말풍선 모양 차이: EmoteBubble은 기호 가운데 정렬·커지는 속도 `_t × 6`, Npc는 기호 왼쪽 −4px·`(1.2 − 남은 시간) × 8`. 혼잣말: 동료는 인물 색 테두리(y −66), 너울은 위쪽 파란 줄 + 꼬리(y −40).

## 3. 함정 (조용히 깨지는 것)

- 전용 그림·초상화·동료 스크립트 경로는 `ResourceLoader.exists`로 감싸져 있다: 파일을 옮기거나 이름을 바꾸면 **오류 없이 기본 그림/기본 동료**가 나온다 (`character_visual.gd` `setup`, `portrait.gd` `_draw`, `ally.gd` `create`).
- `Portrait`의 옛 이름 `_draw_person`·`_eyes`·`_mouth`는 남겨 두었다(옛 코드가 문자열로 부를 수 있음). 새 코드는 `draw_person`·`draw_eyes`·`draw_mouth`.
- 팔레트로 옮긴 상수를 draw/portrait 파일에서 다시 정의하면 스크립트 오류. 값이 다른 이름(예: astrid `SKIN_SH`, aurelia `SKIN_S`)은 팔레트 주석에 적혀 있다.
- `_ik`는 aurelia(코사인 법칙 + 수직)와 leonie(acos 각도)가 알고리즘이 달라 따로 둔다 — 합치면 팔 모양이 바뀐다.
- 자세 별칭 `_n`(astrid·lyra)은 매핑표가 다른 데이터라 공용화하지 않는다.
- `Npc`의 퀘스트 표시는 `GameState.flag_changed`로 "다시 조회할지"만 정한다. `GameState.flags`를 `set_flag` 없이 직접 바꾸는 코드는 (새 게임·불러오기처럼 사전을 통째로 바꾸는 경우 말고는) 표시가 갱신되지 않는다.

## 4. 성능 규칙

- 실측(120프레임 동안 CharacterVisual 다시 그리기 횟수, `drawcount`): `st_festival` 인물 12명 1440 → 579, `dev_e_tree` 8명 960 → 600, `s_courtyard` 3명(모두 화면 안) 360 → 360. 세 방 스크린샷 전후 픽셀 동일.
- **매 프레임 다시 그리기는 화면 안에서만.** `CharacterVisual`은 노드 원점이 화면(카메라) 밖으로 `CULL_MARGIN`(기본 96px, 전용 그림 192px, 노드 배율을 곱함)보다 멀면 `queue_redraw`를 건너뛴다. 화면 밖 그림은 보이지 않으므로 보이는 결과는 같다. 그림이 원점에서 이보다 멀리 뻗는 인물을 만들면 여백을 늘릴 것.
- 그릴 때 상태를 쌓는 전용 그림(`leonie_draw`, `lyra_draw`: 망토·머리 스프링을 메타에 저장)은 `KEEP_DRAWING`으로 늘 그린다 — 건너뛰면 다시 보일 때 스프링이 한 번에 0.1초만 움직여 모습이 달라진다.
- 화면 안에서는 매 프레임 그린다. 기본 그림도 숨쉬기(±0.5px)·옷자락·모자 끝이 소수 px로 움직이는데 이 게임은 꼭짓점을 픽셀에 맞추지 않으므로(`snap_2d_vertices_to_pixel` 꺼짐) 소수 px 변화도 칠해지는 픽셀을 바꾼다(확인: 얼굴 원·옷 사다리꼴을 0.3px 내리면 7픽셀, 0.45px면 11픽셀이 달라짐). "정수 px가 바뀔 때만"으로 줄이면 그림이 달라진다.
- `Portrait`는 전용 초상화 스크립트를 `who`가 바뀔 때만 찾는다(`_draw`마다 `exists`+`load` 하지 않음).
- `Ally`는 말풍선 글이 바뀔 때만 다시 그린다(그리는 것이 말풍선뿐). 세라 찾기는 캐시(나가면 다시 찾음).
- `Npc` 퀘스트 표시: 0.5초마다 확인하되 플래그가 바뀐 적이 있을 때만 `Quests.available_for`/`active_for`를 부른다.
- 새 전용 그림은 다각형 수를 줄인다: `DrawKit.outlined_poly`는 도형 하나에 다각형 5개(윤곽 4 + 채움)를 그린다. 많이 쓰면 `grow_poly`로 부풀린 윤곽 1장 + 채움 1장이 싸다(그림은 조금 다름).
