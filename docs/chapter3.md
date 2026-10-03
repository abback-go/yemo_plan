# 3장 기획서 — 세계수의 눈 (목표 약 1시간 50분)

> 정본: [`bible/`](bible/README.md). 공통 시스템: [`systems2.md`](systems2.md). 마법: [`magic.md`](magic.md).
> 1~6절은 **뼈대(바꾸지 않음)**, 7절 이후는 제작하며 채우는 세부.

## 1. 연결 규칙
| 항목 | 값 |
|---|---|
| 방 ID 접두사 · 플래그 접두사 | `e_` |
| 지도 영역 | `elf` |
| 시작 대본 | `ch3_start` — 2장 끝 다음 날 아침(학교). `ChapterFlow.begin(3)` 뒤 |
| 끝 | 기숙사의 밤 → `await ChapterFlow.finish(c, 3)` (꼬리 3개 → 4장 카드) |
| 지역 전이진 방 | `e_gate` (숲 입구 야영지), 등장 위치 `warp` |
| 이 장의 마법 | 유성 낙화 수업 해금(`e_grove_purified` 이후, 공통 시스템 `q_cls_meteor`) — **선택**이지만 목표 문구로 권함 |
| 동료 | `elarien` (백색 사도전: 먼 가지에서 엄호 사격 모드) |
| 강자 | `elarien` — 사냥 시험(`elarien_hunt`) |
| 반드시 쓸 2장 이전 능력 | 불꽃 날개(바람길·상승 기류), 여우창문(숨은 길), 불꽃 방벽(화살 되쏘기 — 엘라리엔 시험에서 유용) |

## 2. 줄거리 비트
1. **학교 아침**: 온실(`s_greenhouse`)의 세계수 묘목이 하얗게 굳음. 피피 울상. 오필리아의 별 관측 이야기(유성 낙화 예고). 학교 **결투 대회** 공고(이졸데, 서브).
2. **교장의 편지**: 아스트리드가 엘프 장로 오르티아에게 보내는 편지 + 숲 결계를 풀어 줌(교장이 돕는 장면 3). 손이 미세하게 떨림(복선). 앞마당 전이진 → `warp_elf` 해금.
3. **경계의 숲**: 들어서자마자 화살이 모자를 꿰뚫음 — "돌아가라, 마녀." **저격 구간**: 숲을 지나는 동안 화살 예고선(가늘고 하얀 선 → 0.8초 뒤 화살)이 세라를 따라옴. 쓰러진 나무·바위 뒤에 숨으며 전진. 엘프 파수꾼들과의 비살상 싸움.
4. **뿌리 마을**: 장로 오르티아가 편지를 읽고 "아스트리드라… 그 꼬마가 교장이라니." 마을 체류 허락. 엘라리엔 첫 대면(무뚝뚝). 아이 피오가 졸졸.
5. **세계수 마을 탐험**: 뿌리 동굴 → 줄기 시장 → 바람길(엘프 바람 마법의 상승 기류, 방향 바꾸는 바람 밸브 퍼즐) → 가지 위 집들.
6. **흰 역병**: 숲 곳곳이 하얗게 굳음. 달샘에서 너울이 가르침 — "태우는 불이 아니라, 잠재우는 불로." 세라의 불로 역병 덩굴 정화(`e_grove_purified`) → 엘프들의 태도가 바뀜. (유성 낙화 수업 해금)
7. **사냥 시험**: 엘라리엔 "숲에 들일지는 내가 정한다." 수관 경기장(`e_hunt_arena`)에서 **사냥 시험**(강자 보스). 끝나고 "맞히는 건 쉽다. 안 맞히는 게 어렵지." — 일부러 안 맞혔다는 걸 밝힘.
8. **절정**: 세계수 꼭대기의 **백색 사도**(바깥 신들의 첫 사도). 아이들을 감싸다 다친 엘라리엔이 먼 가지에서 **엄호 사격**(동료). 사도가 세라를 "별의… 그릇…"이라 부름(복선).
9. **끝**: 세계수가 되살아남(꽃가루 비). 엘라리엔 "네 불은 숲을 태우지 않는구나." 장로가 창립자의 두 제자 이야기를 살짝("한 아이는 남고, 한 아이는 별을 보러 떠났지"). 귀환 → 기숙사의 밤 → **꼬리 3개** → 달 위에 앉은 그림자(리라)가 내려다보는 짧은 장면 → 4장.

## 3. 방 목록 (약 35개)
| 구역 | 방 | 내용 |
|---|---|---|
| 입구 | `e_gate` | 전이진, 야영지, 기록 |
| 경계의 숲 | `e_border_1`~`e_border_4` | 저격 구간, 엘프 파수꾼 |
| 뿌리 마을 | `e_roots`, `e_elder_hall`, `e_roots_homes` | 거점, 장로, 아이들 |
| 뿌리 동굴 | `e_cave_1`~`e_cave_3` | 버섯 빛 퍼즐, 포자, 이끼 사슴 |
| 줄기 | `e_trunk_market`, `e_trunk_lift`, `e_workshop` | 시장, 승강 장치, 티엘 |
| 바람길 | `e_wind_1`~`e_wind_3` | 상승 기류·바람 밸브 퍼즐 |
| 가지 | `e_branch_homes`, `e_archery`, `e_moonwell` | 집들, 활터(서브), 달샘(정화) |
| 흰 역병 숲 | `e_blight_1`~`e_blight_3` | 역병 덩굴 정화, 백색 진드기 |
| 수관 | `e_canopy_1`~`e_canopy_3`, `e_hunt_arena` | 높은 가지, 사냥 시험 |
| 꼭대기 | `e_crown_1`, `e_crown_2`, `e_crown_nest` | 백색 사도 |
| 숨은 곳 | `e_secret_grove`, `e_hollow` | 여우창문·활공으로만 |
| 학교 덧붙임 | `s_greenhouse`·`s_headmaster`·`s_courtyard` 등 | 3장 아침·편지·결투 대회 |

## 4. 적
| 종류 ID | 이름 | 개성·공략 |
|---|---|---|
| `moss_stag` | 이끼 사슴 | 원래 순함(먼저 공격하지 않음). 역병이 번진 개체는 뿔 돌진·뿔 휘두르기. 쓰러뜨리면 죽지 않고 정화되어 숲으로 돌아감 |
| `blight_spore` | 역병 포자 덩어리 | 붙박이. 주기적으로 포자를 터뜨려 하얀 바닥(밟으면 느려지고 조금씩 피해). 불로 태우면 바닥도 사라짐 |
| `vine_stalker` | 덩굴 사냥꾼 | 덤불에 숨은 포식 식물. 가까이 오거나 여우창문에 비치면 드러남 → 덩굴 채찍 2연타 |
| `lantern_moth` | 등불 나방 | 큰 나방. 나선 비행하며 반짝이는 가루(떠다니는 위험 지대). 등불에 내려앉아 쉴 때가 빈틈 |
| `elf_warden` | 엘프 파수꾼 | 창 + 잎 방패. 비살상 — 체력이 다하면 "물러난다"(무릎 꿇고 사라짐) |
| `white_mite` | 백색 진드기 | 바깥 신들의 하수인(흰 기하학 몸). 정예: 쓰러지면 한 번 둘로 갈라짐(작은 둘) |
| `elarien_hunt` | 엘라리엔 (사냥 시험) | **강자 보스**: 체력 대신 **세 번 닿기**. 그녀는 가지 사이를 뛰어다니며 예고선 화살(1발 → 3발 부채 → 화살비 → 바람 화살(밀어냄)). 세라가 가까이 가서 맞히면 "하나." 하고 다른 가지로. 방벽으로 화살을 되쏘면 그녀가 휘청(맞힌 것으로 침). 단계마다 경기장 가지가 바뀜 |
| `white_herald` | 백색 사도 | 절정 7000: 얼굴 없는 흰 존재. 하얀 빛창, 기하학 감옥, 역병 소환, 피오의 꼬투리를 붙잡는 장면. 엘라리엔이 사도의 수정 눈을 저격해 무방비 상태로 만듦(동료 지원) |

## 5. 퍼즐·탐험
- 바람길: 바람 밸브를 불로 돌려 기류 방향(위/옆) 바꾸기, 활공으로 기류 갈아타기.
- 뿌리 동굴: 버섯 등을 정해진 순서로 밝혀 어둠 속 발판 드러내기(빛이 닿는 동안만 보임).
- 달샘: 달빛 반사(방벽으로 빛을 튕겨 수정 셋에 닿게) → 정화의 불.
- 흰 역병 덩굴: 불기둥·화염 폭풍으로 태워 길 엶(정화).
- 숨은 것: 마도석 10, 수호의 깃털 2, 엘프 노래 가사 3장(세계수의 옛이야기, 창립자 언급).

## 6. 서브 퀘스트
| ID | 주는 이 | 내용 | 보상 |
|---|---|---|---|
| `e_fio_seeds` | 피오 | 반짝이 씨앗 5개 찾기(마을 곳곳) | 마도석 1 |
| `e_tiel_valve` | 티엘 | 고장 난 바람 밸브 3개 고치기(바람길) | 마도석 2 |
| `e_ortia_tea` | 오르티아 | 달잎 차 재료(달샘·수관) | 물약 최대 +1 |
| `e_archery` | 엘라리엔 | 활터 과녁을 화염탄으로 제한 시간 안에 | 마도석 2 |
| `e_pippa_moss` | 피피(학교) | 빛이끼 표본 3개 | 마도석 1 |
| `e_honey` | 버터워스(학교) | 숲 꿀 | 최대 체력 +1 (요리) |
| `s_duel_cup` | 이졸데(학교) | 학교 결투 대회 결승(이졸데와 1:1, 서리 마법) | 수호의 깃털 |

## 7. 세부 — 구현 메모 (실제 동작 기준)

### 7.1 파일
| 무엇 | 파일 |
|---|---|
| 방 생성 (본편 32 + 시험 방 7 + 학교 덧붙임) | `tools/rooms/ch3.py` → `game/world/rooms/e_*.gd`, `dev_e_*.gd` |
| 인물·방 목록·목표·퀘스트 | `game/story/data_ch3.gd` |
| 대본 (본편·인물 대화·퀘스트·개발용) | `game/story/scripts_ch3.gd` |
| 적 9종 + 공용 조각 | `game/enemies/ch3/` (`registry.gd`, `aim_line.gd` 예고선, `elf_arrow.gd` 화살, `ch3_sfx.gd` 효과음) |
| 장치 11종 + 끝 장면 + 소품 33종 | `game/world/entities/ch3/` (`entities.gd`, `props.gd`, `moon_scene.gd`) |
| 테마·배경 | `game/world/themes/themes_ch3.gd` (`elf`·`elf_deep`·`blight`), `backdrop_ch3.gd` |
| 인물 전용 그림 | `game/characters/special/elarien_draw.gd`·`elarien_portrait.gd`, `ortia_*`, `elf_folk_draw.gd`·`elf_folk_portrait.gd`(피오·티엘·파수꾼·주민) |
| 시나리오 | `tools/test/scenarios/ch3_*.json` (13절) |

### 7.2 테마 (`themes_ch3.gd`)
- `elf` — 세계수 마을. 연두 강조색 `#c8ff7a`, 나무판 타일, 이끼, 반딧불. 배경: 별·달·먼 나무 → 세계수 줄기(껍질 홈·수액 줄기·가지 위 등불 길·꼬투리 집) → 가지·다리·바람 리본 → 앞 잎·덩굴.
- `elf_deep` — 뿌리 동굴. 청록 `#5affd0`, 돌 타일, 포자. 배경: 뿌리 아치·큰 버섯·빛 웅덩이·실.
- `blight` — 흰 역병. 어둡게(가독성): 바닥 `#2c2c34`, 윗면 `#c4c4d4`. 배경: 천천히 도는 육각·삼각 문양과 세로 틈(바깥 신들의 눈), 곧은 금, 굳은 나무, 육각 결정 조각.
- 움직이는 부분은 배경 위 `Anim` 자식 노드만 다시 그린다(정적 그림은 한 번). 세로로 긴 방은 `_cover()`로 배경 범위를 맞춘다(15절 요청 1).

### 7.3 장치 (`game/world/entities/ch3/entities.gd`)
| `t` | 키 | 동작 |
|---|---|---|
| `sniper_cover_arrows` | x,y,w,h, ox,oy(사수 자리), aim 1.25·lock 0.45·rest 1.4, speed, damage, on_if, done, first | 영역 안 세라를 붉은 예고선이 따라옴 → 흰 선 고정 → 화살. 지형 `#`가 가리면 선이 끊기고 조준이 풀림. 컷신(조작 잠김) 중엔 멈춤. 화면 밖 사수는 가장자리 표시 |
| `wind_valve` | flag, start, broken, fix_flag, up | 불에 맞으면 한 칸 돌며 flag를 켜고 끔. 고장 밸브는 세 번 데우면 풀리고 곧장 켜짐 |
| `crosswind` | x,y,w,h, dir, power, on_if | 공중의 세라를 옆으로 밂(활공 중 1.6배) |
| `blight_vine` | w,h,hp, done_flag, first, need, hint | 불 종류 공격 hp번 → 정화(타는 불꽃 → 새순). need가 서기 전엔 불이 튕겨 나가고 hint 대본 |
| `glow_mushroom` | group, order, size, done_flag | 봉화 규칙(퍼즐 처리기 `puzzle` mode=order). 켜지면 넓은 청록 빛 |
| `moon_drop` / `moon_crystal` | period·phase·on_if / group·done_flag | 달빛 방울을 방벽으로 되쏘면 위로 → 수정은 `reflect`에만 켜짐 |
| `archery_mark` | group, dx,dy,period,phase, hang, active_if | 움직이는 과녁. 대본이 `ArcheryMark.reset_group/count_hit/count_all` |
| `root_gate` | open_if | FlagGate + 뿌리가 물러나는 그림 |
| `white_pod` | who | 피오가 갇힌 흰 꼬투리. 대본 `struggle()`·`await crack()` (actor id `pod`) |
| `quest_counter` | quest, flags, step, label | 모으는 물건 플래그가 설 때 "이름 n/총" 알림, 다 모이면 퀘스트 단계 |
| (대본 전용) `Ch3MoonScene` | — | 끝 장면: 달 위의 그림자 (`await Ch3MoonScene.play(world, 6.5)`) |

### 7.4 적 (보통 난이도 체력, 쉬움은 EnemyBase가 자동 배율)
| 종류 | 체력 | 핵심 | 확인 시나리오 |
|---|---|---|---|
| `moss_stag` | 700 | 순한 개체(blighted=false)는 먼저 공격 안 함. 역병 개체: 뿔 돌진·휘두르기. 0이 되면 죽지 않고 정화되어 떠남 | `ch3_moss_stag` |
| `blight_spore` | 560 | 붙박이. 포자 → 하얀 바닥(1.6초 뒤 1 피해, 속도 ×0.55). 불로 바닥도 태움 | `ch3_blight_spore` |
| `vine_stalker` | 820 | 숨어 있음(이름표 숨김). 가까이 오거나 여우창문 → 드러나며 1.6초 멍(피해 ×1.5). 채찍 2연타·땅속 이동 | `ch3_vine_stalker` |
| `lantern_moth` | 640 | 나선 비행·가루 구름(0.85초 간격)·예고선 급강하, 등불 소품에 앉아 쉼(피해 ×1.6) | `ch3_lantern_moth` |
| `elf_warden` | 900 | 잎 방패(정면 화염탄 막음)·찌르기·도약 찌르기(착지 표시)·뒷걸음. 0이면 "…물러나겠다." | `ch3_elf_warden` |
| `white_mite` | 1800 / 작은 450 | 흰 띠 예고 돌진(거리 맞춤)·찌르기, 쓰러지면 작은 둘로 갈라짐 | `ch3_white_mite` |
| `elarien_hunt` | 닿기 3 | 강자 보스. 횃대(perch_1~6) 사이를 뛰며 단계별 1발 → 부채 → 화살비·바람 화살. 몸 닿기·4.5칸 안 공격·되쏜 화살 = 닿기. 멀리서 쏘면 피함("멀다. 와서 닿아 봐.") | `ch3_elarien_hunt`, `ch3_hunt_room` |
| `white_herald` | 7000 | 절정 보스. 빛창(흰 띠)·육각 감옥·역병 소환(최대 3). 수정 눈 셋: 평소 피해 50%, 동료 `snipe_eye()` → 4초 무방비(175%), 깨진 눈마다 평소 피해 +15%. 66%·33% 페이즈 | `ch3_white_herald`, `ch3_herald_room` |
| `isolde_duel` | 2000 | 서브 결투. 서리 조각 3갈래(되쏠 수 있음)·얼음 창(예고선)·얼음 가시·(절반 아래) 빙판 질주·눈꽃 고리. 4칸 안이면 뒤로 물러남. 0이면 무릎 | `ch3_isolde_duel` |

### 7.5 인물 그림
- 엘라리엔 36px: 자세 idle(시위 고쳐 잡기·머리 넘기기)·walk·run·aim(`aim_ang` 메타)·attack·attack2·special·charge·windup·guard·hurt·kneel·down·leap·cast. 망토 잎무늬, 흰 장궁 금 잎, 활 반짝임. 초상화 표정 normal·happy·angry·sad·surprised·smirk·focus·hurt·tired.
- 오르티아(지팡이·씨앗·이끼 참새), 엘프 공용 그림(긴 귀·잎 옷깃·나무색 장화 + extra: leafcap·satchel·goggles·tools·apron·basket·flower·freckles·warden(두건·눈가리개·창끝 붉은 예고)).
- 인물 ID: `elarien`, `ortia`, `fio`, `tiel`, `elf_warden`, `warden_a`(파수꾼 리엔), `warden_b`(파수꾼 소르), `fio_mom`, `elf_a`·`elf_b`(주민), `elf_c`(아이).

## 8. 지도 (영역 `elf`, 32방 — 칸 좌표 (x, y))
```
 -4 .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. 31 32 32
 -3 .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. 30 30 31 .. ..
 -2 .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. 29 .. .. .. .. ..
 -1 .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. 29 .. .. .. .. ..
  0 .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. 27 28 28 29 .. .. .. .. ..
  1 .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. 26 26 27 .. .. .. .. 24 24 .. ..
  2 .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. 25 19 19 19 21 22 22 23 23 24 24 .. ..
  3 .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. 17 18 18 19 19 19 20 .. .. .. .. .. .. .. ..
  4 .. .. .. .. .. .. .. .. .. .. 15 .. .. .. .. 17 .. .. .. .. .. .. .. .. .. .. .. .. .. ..
  5 .. .. .. .. .. .. .. .. .. .. 15 .. .. 16 16 17 .. .. .. .. .. .. .. .. .. .. .. .. .. ..
  6 .. .. .. .. .. .. .. .. .. .. 15 .. .. 16 16 .. .. .. .. .. .. .. .. .. .. .. .. .. .. ..
  7 .. .. .. .. .. .. .. .. 06 06 06 08 12 13 13 13 14 .. .. .. .. .. .. .. .. .. .. .. .. ..
  8 01 02 02 03 03 04 04 05 06 06 06 07 12 .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. ..
  9 .. .. .. .. .. .. .. .. 09 09 10 10 12 .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. ..
 10 .. .. .. .. .. .. .. .. .. .. 11 .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. ..
```
01 `e_gate` · 02 `e_border_1` · 03 `e_border_2` · 04 `e_border_3` · 05 `e_border_4` · 06 `e_roots` · 07 `e_elder_hall` · 08 `e_roots_homes` · 09 `e_cave_1` · 10 `e_cave_2` · 11 `e_hollow` · 12 `e_cave_3` · 13 `e_trunk_market` · 14 `e_workshop` · 15 `e_trunk_lift` · 16 `e_wind_1` · 17 `e_wind_2` · 18 `e_wind_3` · 19 `e_branch_homes` · 20 `e_archery` · 21 `e_moonwell` · 22~24 `e_blight_1~3` · 25 `e_secret_grove` · 26~28 `e_canopy_1~3` · 29 `e_hunt_arena` · 30·31 `e_crown_1·2` · 32 `e_crown_nest`

- 이어짐: 01→02→03→04→05→06(왼쪽 아래) / 06의 문: 07 장로 · 08 피오네(위 선반) · 09 동굴(계단) · 15 승강기(잠김) / 09→10→12(굴 아래)→13 / 10 환영 벽 감실 문 → 11 / 13의 문: 14 공방 · 15 승강기(잠김) · 16 바람길(티엘을 만나야) / 16→17→18→19(아래 가지) / 19: 아래 동쪽 20, 위 동쪽 21→22→23→24, 위층 계단(정화 뒤) 26→27→28→29(문, 시험 제안 뒤)→30(문, 시험 뒤)→31→32, 왼쪽 위 환영 벽 → 25, 아래 문 15 승강기.
- 지름길: 바람길을 지나 가지 마을에 닿으면 `e_lift_fixed` — 승강기 굴(15)의 바람 기둥으로 뿌리 마을·줄기 시장·가지 마을 사이를 오간다(불꽃 날개). 전이진은 01 하나(학교 앞마당과 오감).
- 도달 검사: `python3 tools/roomgen.py check all e_` → 0. (2단 점프만으로는 바람길 16~18·승강기 15가 막힘 — 불꽃 날개 필수 구간, 숨은 문 11·25는 여우창문 필수 — 의도)

## 9. 방별 설계
| 방 | 내용 | 적 | 줍는 것 | 게이트·대본 |
|---|---|---|---|---|
| `e_gate` | 야영지, 전이진(`warp` area elf, 등장 `warp`), 기록, 안내 비석 | — | — | `enter_e_gate`(첫 도착: `warp_unlock("elf")`, `e_arrived`) |
| `e_border_1` | 저격 구간 1: 엄폐 바위 5, 높은 가지 | — | 마도석 `stone_border1`(노출된 가지) | 트리거 `e_warning_shot`(모자), 사건 `e_snipe_teach`(멈춤 안내 "엄폐") |
| `e_border_2` | 저격 구간 2(가운데 높은 사수) → 둔덕 | 파수꾼 | — | `e_warden_seen` |
| `e_border_3` | 첫 흰 역병, 높은 턱 감실(환영 벽) | 포자 2, 파수꾼, 순한 사슴 | 마도석 `stone_border3`, 노래 가사 1 | `e_blight_first` |
| `e_border_4` | 뿌리 문(거목 뿌리) | — | — | `e_border_gate` → 엘라리엔 등장·편지 확인 → `e_border_passed`(저격 멈춤) |
| `e_roots` | 거점: 아래층 길·뿌리 둔덕(승강기)·위 선반(집) | — | 씨앗 1 | `enter_e_roots`(피오) · 기록 |
| `e_elder_hall` | 장로의 집 | — | — | `enter_e_elder_hall`: 편지, "그 꼬마가 교장이라니", 엘라리엔 첫 대면, 티엘·달샘 안내 → `e_met_ortia` |
| `e_roots_homes` | 피오네 집 | — | 씨앗 2 | — |
| `e_cave_1` | 어둠(0.45) 속 빛버섯 셋(크기 순 order) → 뿌리 문 | 순한 사슴 | 빛이끼 1 | `e_cave_dark`, 사건 `e_cave_mush_done` |
| `e_cave_2` | 역병 사슴, 왼쪽 위 환영 벽 감실 문 | 역병 사슴, 포자 | — | `e_stag_teach` |
| `e_hollow` | 숨은 빈터(달빛 샘) | — | 마도석 `stone_hollow`, 노래 가사 2, 빛이끼 3 | — |
| `e_cave_3` | 세로 3칸 굴, 4행 간격 지그재그, 오른쪽 감실(환영 벽) | 덩굴 사냥꾼 2 | 깃털 `feather_cave`, 마도석 `stone_cave3`, 빛이끼 2 | — |
| `e_trunk_market` | 장터(위층 지붕 길), 기록 | — | 씨앗 3 | `e_market_arrive`. 바람길 문 잠금 `e_met_tiel` |
| `e_workshop` | 티엘, 시범 밸브 | — | — | `enter_e_workshop` → `e_met_tiel`, 퀘스트 `e_tiel_valve` 시작, 멈춤 안내 "바람 밸브" |
| `e_trunk_lift` | 승강기 굴(세로 3칸), 바람 기둥 on_if `e_lift_fixed` | — | — | 문 셋(뿌리 마을·시장·가지 마을) |
| `e_wind_1` | 밸브 A(옆바람↔상승), 밸브 B(역풍↔상승), 고장 밸브 1 → 둥지 | 등불 나방 | 마도석 `stone_wind1` | `e_wind_teach` |
| `e_wind_2` | 밸브 C(기둥 오른쪽↔왼쪽), 밸브 D(꼭대기 역풍↔상승), 고장 밸브 2 → 둥지 | 등불 나방 | 마도석 `stone_wind2` | 메모 표지판(순서 힌트) |
| `e_wind_3` | 넓은 틈(가시덤불) — 밸브 E로 역풍 끄고 쉼 기둥, 섬 발판 활공. 고장 밸브 3 → 둥지 | 덩굴 사냥꾼 | 씨앗 5 | — |
| `e_branch_homes` | 아래 가지(승강기·기록) → 지그재그 → 위층 큰 가지(집·수관 계단) | — | 씨앗 4, 마도석 `stone_branch` | `enter_e_branch_homes` → `e_wind_done`·`e_lift_fixed`. 수관 계단 잠금 `e_grove_purified`, 왼쪽 위 환영 벽 → 숨은 숲 |
| `e_archery` | 활터: 과녁 4(고정·매달림·좌우·대각) | — | — | 엘라리엔(시험 뒤)·퀘스트 `e_archery` |
| `e_moonwell` | 달빛 방울 셋·매달린 수정 셋(되쏘기 퍼즐), 오른쪽 뿌리 문 | — | 달잎(차) | `e_moon_arrive` → `e_moon_talk`, 사건 `e_moon_lesson` → `e_moon_lesson`(잠재우는 불) |
| `e_blight_1` | 덩굴(need `e_moon_lesson`, 첫 정화 대사) | 포자, 백색 진드기 | — | `e_blight_arrive` |
| `e_blight_2` | 덩굴 2, 굳은 가지 위 | 역병 사슴, 포자 2 | 마도석 `stone_blight2` | — |
| `e_blight_3` | 굳은 숲의 심장(덩굴 4×6, hp 6), 기록 | 백색 진드기, 포자 | — | `e_heart_arrive`, 사건 `e_grove_purify` → `e_grove_purified`(꽃가루, 엘라리엔 "시험이다") |
| `e_secret_grove` | 숨은 숲(벌집) | — | 깃털 `feather_grove`, 마도석 `stone_grove`, 노래 가사 3, 숲 꿀 | — |
| `e_canopy_1` | 잎 사이 가지길 | 등불 나방 2 | — | `enter_e_canopy_1` → `e_meteor_hint` |
| `e_canopy_2` | 세로 2칸, 위쪽 옆바람 | 포자, 덩굴 사냥꾼 | 마도석 `stone_canopy2`, 이슬(차) | — |
| `e_canopy_3` | 경기장 앞, 기록, 엘라리엔 | — | — | `e_hunt_offer` → 경기장 문 열림 |
| `e_hunt_arena` | 세로 3칸 경기장(12층 가지, 횃대 6), 꼭대기 턱 계단 | 엘라리엔(사냥 시험) | — | `e_hunt_begin`(once=False) → `e_hunt_done`, 전령 → `e_fio_gone` |
| `e_crown_1` | 하얗게 굳은 꼭대기, 기록, 덩굴 | 작은 진드기 2, 포자 | — | `e_crown_arrive` |
| `e_crown_2` | 세로 2칸, 위 턱 덩굴 | 큰 진드기 | — | — |
| `e_crown_nest` | 사도의 둥지: 엄호 가지(ally 27,8), 피오의 꼬투리, 출구 결계(`!e_herald_fight`) | 백색 사도 | — | `e_herald_begin`(once=False) |
| 학교 덧붙임 | 온실: 묘목(하양 0.6 → 사도 뒤 0)·피피·등장 `ch3` / 교장실 트리거 `e_headmaster` / 앞마당 이졸데 / 기숙사 등장 `ch3_night` | | | |

## 10. 메인 목표 줄 (`data_ch3.gd` OBJECTIVES)
| 완료 플래그 | 문구 | 필요 |
|---|---|---|
| `e_letter` | 교장실로 가자 (중앙 홀 2층 오른쪽 → 시계탑 꼭대기) | `e_start` |
| `e_arrived` | 앞마당 전이진으로 엘프의 숲에 가자 | `e_letter` |
| `e_border_passed` | 숲 경계를 지나 세계수로 — 붉은 예고선이 보이면 바위·쓰러진 나무 뒤로 | `e_arrived` |
| `e_met_ortia` | 뿌리 마을 장로의 집에서 편지를 전하자 | `e_border_passed` |
| `e_met_tiel` | 뿌리 동굴을 지나 줄기 시장의 티엘에게 (승강기 고장) | `e_met_ortia` |
| `e_wind_done` | 바람길을 올라 가지 마을로 — 밸브를 불로 돌리면 바람이 바뀐다 | `e_met_tiel` |
| `e_moon_lesson` | 가지 마을 위쪽 가지 끝, 달샘으로 | `e_wind_done` |
| `e_grove_purified` | 흰 역병의 숲 깊은 곳 — 굳은 숲의 심장을 잠재우자 | `e_moon_lesson` |
| `e_meteor_hint` | 가지 마을 위층 계단으로 수관에 오르자 (선택: 학교 수업 게시판에 유성 낙화 수업이 열렸다) | `e_grove_purified` |
| `e_hunt_done` | 수관 경기장에서 엘라리엔의 사냥 시험 — 세 번 닿아라 | `e_grove_purified` |
| `e_herald_done` | 세계수 꼭대기로 — 아이들이 위험하다 | `e_hunt_done` |
| `ch3_done` | 학교로 돌아가 쉬자 | `e_herald_done` |
- `e_meteor_hint`는 수관에 처음 들어갈 때(또는 경기장 앞 대화) 선다 — 유성 낙화 수업(`cls_meteor`, 해금 `e_grove_purified,mana>=6`)은 선택.

## 11. 서브 퀘스트 (`data_ch3.gd` QUESTS) — 모으는 물건은 퀘스트를 받기 전에 주워도 센다
| ID | 주는 이 (곳) | 받는 조건 | 내용 | 보상 |
|---|---|---|---|---|
| `e_fio_seeds` | 피오 (뿌리 마을) | `e_met_ortia` | 반짝이 씨앗 5: 뿌리 마을 위 선반 · 피오네 집 선반 · 줄기 시장 지붕 길 · 바람길 3 둥지(고장 밸브 3) · 가지 마을 아래 | 마도석 1 + 비밀(숨은 숲 위치) |
| `e_tiel_valve` | 티엘 (공방, 만나면 자동 시작) | `e_met_tiel` | 바람길 굴마다 고장 밸브(세 번 데움) — 고치면 숨은 기류가 둥지로 | 마도석 2 |
| `e_ortia_tea` | 오르티아 (장로의 집) | `e_met_ortia` | 달샘의 달잎 + 수관의 이슬 | 물약 최대 +1 |
| `e_archery` | 엘라리엔 (활터, 사냥 시험 뒤) | `e_hunt_done` | 과녁 4를 20초 안에 (`e_archery_on` 동안만 맞음, 다시 하기 가능) | 마도석 2 |
| `e_pippa_moss` | 피피 (학교 온실·연금술실) | `e_start` | 빛이끼 3: 뿌리 동굴 1 · 뿌리 굴 오른쪽 턱 · 숨은 빈터 | 마도석 1 |
| `e_honey` | 버터워스 (식당) | `e_start` | 숨은 숲의 숲 꿀 | 최대 체력 +1(꿀 바른 숲빵) |
| `s_duel_cup` | 이졸데 (앞마당) | `e_letter` | 결투장에서 이졸데와 결투(`isolde_duel`, 다시 도전 가능). 유성 낙화 수업 시험 중엔 미룸 | 수호의 깃털 |

## 12. 대본 목록 (`scripts_ch3.gd`)
- 본편: `ch3_start` · `e_headmaster` · `enter_e_gate` · `e_warning_shot` · `e_snipe_teach` · `e_warden_seen` · `e_blight_first` · `e_border_gate` · `enter_e_roots` · `enter_e_elder_hall` · `e_cave_dark` · `e_cave_mush_done` · `e_stag_teach` · `e_market_arrive` · `enter_e_workshop` · `e_wind_teach` · `enter_e_branch_homes` · `e_moon_arrive` · `e_moon_lesson` · `e_vine_hint` · `e_vine_first` · `e_blight_arrive` · `e_heart_arrive` · `e_grove_purify` · `enter_e_canopy_1` · `e_hunt_offer` · `e_hunt_begin`(→`_hunt_after`) · `enter_e_crown_1/2`·`enter_e_crown_nest`(사도전에 지고 오면 동료·결계 초기화) · `e_crown_arrive` · `e_herald_begin`(→`_herald_after` → `_ending_elder` → `_ending_dorm` → `ChapterFlow.finish(c, 3)`)
- 인물: `npc_ortia` · `npc_fio` · `npc_fio_mom` · `npc_tiel` · `npc_elarien`(활터·경기장 앞) · `npc_warden_a` · `npc_warden_b`(방마다 다름) · `npc_e_roots_a/b/c` · `npc_e_roots_warden` · `npc_e_market_a`(꿀떡: 물약 채움)·`npc_e_market_c` · `npc_e_branch_a/b/c` · `npc_elf_c`
- 학교 3장 덮어쓰기: `npc_pippa_ch3` · `npc_butterworth_ch3` · `npc_astrid_ch3` · `npc_isolde_ch3`(→`_isolde_duel`)
- 보스전 대본 규칙: `defeated` 신호로 이겼는지 따로 잡아, 쓰러지거나 방을 나가면(사냥 시험은 문으로 나갈 수 있음) 뒷이야기로 넘어가지 않는다. 다시 들어오면 "다시."
- 사도전: 동료 `elarien`(hold, 엄호 가지 27,8). 13초마다 `special(사도)` → `snipe_eye()`(눈 깨짐 → 4초 무방비). 66%에서 "눈 하나 더. 버텨라!", 33%에서 잠깐 멈추고 「별의…… 그릇……」 / 너울 "……감히."
- 끝: 사도가 흩어지면 꼬투리가 깨져 피오가 내려옴 → 꽃가루 비 → 엘라리엔 "네 불은 숲을 태우지 않는구나." → 장로의 집("한 아이는 남고, 한 아이는 별을 보러 떠났지") → 기숙사의 밤(너울이 처음으로 "세라"라고 부름) → 꼬리 3개 → 달 위의 그림자 → `ChapterFlow.finish(c, 3)` → 4장 카드.

### 12.1 수집품
- 마도석 10: border_1 · border_3 · hollow · cave_3 · wind_1(고장 밸브 둥지) · wind_2(고장 밸브 둥지) · branch_homes · blight_2 · canopy_2 · secret_grove (+ 퀘스트 6: 피오 1·티엘 2·활터 2·피피 1)
- 수호의 깃털 2(뿌리 굴 감실·숨은 숲) + 결투 대회 1, 최대 체력 +1(꿀), 물약 주머니 +1(차)
- 엘프 노래 가사 3장(세계수의 옛이야기 · 창립자의 잠재우는 불 · 두 제자 중 별을 세던 아이 — 리라 복선)

## 13. 시험
- `python3 tools/roomgen.py check all e_` → 출력 없음(문제 0).
- 컴파일: `check_scripts.gd` → 실패 0.
- 시나리오(`tools/test/scenarios/`):
  - `ch3_full` — ch3_start(온실) → 편지 → 숲 → … → 사도 → 장로의 집 → 기숙사의 밤 → 꼬리 3 → 달 장면 → 4장 카드. 끝에 `STATUS end … room=s_dorm busy=false … obj=` 이면 통과(SCRIPT ERROR 0).
  - 실제 방 보스전: `ch3_hunt_room`(피격 → 경기장 나갔다 들어오면 "다시." → 몸 닿기·되쏘기 닿기 → 전령), `ch3_herald_room`(피격 → 엘라리엔 저격으로 체력 감소 → 33% 「별의…… 그릇……」 → 처치 → 끝까지), `ch3_isolde_duel`(앞마당 → 결투장 → 피격 → 절반 → 처치 → 깃털).
  - 서브 퀘스트 6종 전달: `ch3_quests`(피오·오르티아·티엘·활터 과녁·피피·버터워스, 마도석·물약 주머니·최대 체력 확인).
  - 방 32개 둘러보기 스크린샷: `ch3_rooms_tour` / 끝 장면·꼬투리: `ch3_moon`.
  - 적 단독: `ch3_moss_stag`·`ch3_blight_spore`·`ch3_vine_stalker`·`ch3_lantern_moth`·`ch3_elf_warden`·`ch3_white_mite`·`ch3_elarien_hunt`·`ch3_white_herald`, 장치 `ch3_devices`, 그림 `ch3_visuals`·`ch3_portrait`.
- 실행: `game/`에서 `xvfb-run -a -s "-screen 0 1280x720x24" $G --rendering-driver opengl3 --fixed-fps 60 --resolution 640x360 --script ../tools/test/runner.gd -- ../tools/test/scenarios/ch3_full.json /tmp/out`

## 14. 플레이 시간 추정 (근거)
| 구간 | 방 | 분 |
|---|---|---|
| 학교 아침·교장실(시계탑 오르기) | 온실·홀·시계탑·교장실 | 5 |
| 경계의 숲(저격 2구간·파수꾼 2·포자) | 01~05 | 10 |
| 뿌리 마을·장로(대화 약 30줄) | 06~08 | 6 |
| 뿌리 동굴(버섯 퍼즐·사슴·세로 굴) | 09~12 | 10 |
| 줄기 시장·공방 | 13·14 | 4 |
| 바람길(밸브 퍼즐 3굴) | 16~18 | 12 |
| 가지 마을·달샘 퍼즐 | 19·21 | 8 |
| 흰 역병의 숲·심장 | 22~24 | 10 |
| 수관 | 26~28 | 7 |
| 사냥 시험(재도전 1회 포함) | 29 | 6 |
| 꼭대기·백색 사도(재도전 1회 포함) | 30~32 | 10 |
| 끝 장면들 | | 5 |
| **본편 합계** | | **약 93분** |
| 서브(씨앗 +5 · 밸브 +6 · 차 +3 · 활터 +4 · 이끼·숨은 빈터 +3 · 꿀·숨은 숲 +4 · 결투 +5) | | +30 |
- 근거: 본편 대사 약 200줄(한 줄 약 3.5초 ≈ 12분), 1칸 방 이동·전투 평균 2~3분(1장 실측 45분/30방과 비슷한 밀도), 퍼즐 방은 +2~3분. 본편 + 서브 일부 ≈ **1시간 40분~2시간**.

## 15. 공용 파일 요청 (고치지 않음 — 통합 담당)
1. `game/world/themes/room_backdrop.gd` `_span()`: 세로로 긴 방에서 배경이 아래쪽을 덮지 못함 → y 범위를 `size.y * (scroll * 0.6 + 0.4)` 기준으로. (3장은 `backdrop_ch3.gd`의 `_cover()`로 우회 중)
2. `game/enemies/enemy_base.gd` `_physics_process`: 죽은 뒤에도 `_flash`를 줄일 것(지금은 죽는 순간 흰 채로 남음 — 3장은 `moss_stag`·`white_herald`에서 덮어써서 우회).
3. `game/fox/neoul_pet.gd` 152행: 꼬리가 2개 이상이면 꼬리 다각형이 꼬여 `Invalid polygon data, triangulation failed`가 매 프레임 쏟아짐(2장 끝부터 해당). 중간 점 오프셋도 같이 돌리거나 `Geometry2D.convex_hull()`로 감쌀 것.
4. `game/characters/special/elf_folk_portrait.gd`가 `Portrait._draw_person(info)`(1장 초상화의 사람 그리기)를 부른다 — 이름을 바꾸면 함께 바꿀 것.
5. `Ch3Sfx`(`game/enemies/ch3/ch3_sfx.gd`)는 `arrow_shot`·`arrow_hit`·`bow_draw`·`wind`가 없으면 `Sfx._add`로 직접 만들어 넣는다 — 오디오 담당이 같은 이름을 만들면 그쪽이 우선(이미 있으면 건드리지 않음).
