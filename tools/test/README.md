# 시험 도구 (tools/test)

Godot 4.7.2 리눅스 실행 파일(아래 `$G`)로 헤드리스·가상 화면 시험을 돌린다. 모든 명령은 `game/` 폴더에서 실행한다.

```bash
# Godot 내려받기 (클라우드 세션은 매번 새 컴퓨터라 다시 받아야 함)
curl -sSLo godot.zip https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip
unzip godot.zip && G=$PWD/Godot_v4.7.2-stable_linux.x86_64

cd game
$G --headless --import                                   # 처음 한 번 (클래스 목록 갱신)
$G --headless --script ../tools/test/check_scripts.gd    # 모든 스크립트 불러오기 → "CHECKED N scripts, failures: 0"
$G --headless --quit-after 200 res://world/world.tscn    # 실행 중 오류 빠른 확인 (SCRIPT ERROR가 없어야 함)
```

## 시나리오 실행기 `runner.gd`

```bash
xvfb-run -a -s "-screen 0 1280x720x24" $G --rendering-driver opengl3 --fixed-fps 60 --resolution 640x360 \
  --script ../tools/test/runner.gd -- ../tools/test/scenarios/full_playthrough.json /tmp/out
```

시나리오 JSON: `{"scene": "res://world/world.tscn", "room": 방ID, "spawn": 등장 위치, "flags": [미리 세울 플래그], "steps": [[프레임, 명령, 인자...], ...]}`
턴제 저장 `"turn_save"`: `off`(기본 — 턴제 저장을 읽지도 쓰지도 않고 첫 실행 안내도 타이틀(R6)도 없음 — 곧장 편성) · `fresh`(시험 폴더 `user://test_turn/`을 비우고 시작 = 첫 실행 — 타이틀부터, 누르면 안내 전투) · `keep`(그 폴더 그대로).

| 명령 | 뜻 |
|---|---|
| `press`/`release`/`tap` 동작 | 입력 (`tap`은 `_input`까지 전달됨) |
| `tp` x y | 세라 순간이동 (타일) |
| `go` 방 등장위치 | 방 이동 (문 대신) |
| `auto` true/false | 대사·멈춤 안내·습득 팝업·끝 화면 자동 넘김 |
| `waitidle` [한도] | 대본이 끝날 때까지 단계 시계를 멈춤 (보스전 중엔 한도까지 기다림 → `WAIT TIMEOUT`) |
| `attach` 스크립트 | 시험용 노드(자동 플레이 봇 등)를 지금 장면에 붙임 (game/ 기준 상대 경로) |
| `godmode` | 세라 무적 + 체력 3 미만이면 5로 |
| `kill` / `ehp` 값 / `ehpf` 비율 | 적 처치(붉은 불 999 피해라 해태·골렘 정면·아귀는 여러 번 필요) / 체력 설정 / 체력 비율로 |
| `spawn_enemy` 종류 x y {속성} | 적 생성 (종류는 `enemies/enemy_registry.gd`) |
| `flagset` 키 · `abil` 이름 · `run` 대본ID | 플래그·능력·대본 실행 |
| `record` 방 위치 · `continue` | 기록 → 이어하기 시험 |
| `status` / `worldinfo` / `logv` / `enemies` / `flags` 표시 | 상태 출력 |
| `shot` 이름 | 스크린샷 PNG |
| `touch`/`untouch` 번호 x y · `drag` 번호 x y | 손가락 누름·뗌·끌기 (화면 좌표 640×360, 번호 = 손가락 index) |
| `dtouch`/`duntouch` 번호 x y | 턴제 설계 좌표(640×360 화면 기준) 누름·뗌 — 넓은 화면(`--resolution 780x360` 등)이면 `TTheme.ofs`를 더해 같은 자리를 누른다 |
| `touchinfo` | 터치 조작 상태 (터치 모드·표시 여부·눌린 동작·조이스틱 방향) |
| `setting` 키 값 · `potions` 개수 | 설정 값 지정(저장된 설정이 시험에 끼어들지 않게) · 물약 수 |
| `perf` 이름 | 프레임 시간·그리기 호출·물체·노드 (월드가 아닌 장면이면 `room=` 생략 — 턴제에서 쓸 수 있음) |
| `quit` | 종료 |

## 시나리오 (scenarios/)
| 파일 | 확인하는 것 |
|---|---|
| `full_playthrough.json` | 여우고개 → 1장 끝 화면까지 (대사 자동, 순간이동·처치로 진행). 끝에 `STATUS end2 ... room=s_dorm ... obj=` 이면 통과 |
| `school_flow.json` | 의무실 → 끝 (학교만) |
| `haetae_demo_fight.json` | 해태 시범전: 10초 뒤 첫 빙의, 철창, 승리 → 학교 |
| `training_targets.json` | 실습장 과녁 셋을 1.2초 간격으로 맞혀 합격 → 골렘 |
| `shot_single_vs_fox_pierce.json` | 기본 공격 단일 대상(6초 5발 = 1000), 여우불 관통(두 적 모두 피해) |
| `save_continue.json` | 기록 → 이어하기 복원 |
| `drop_through.json` | 통과 발판 ↓+Z |
| `room_bounds_haetae.json` | 보스전 중 방 밖으로 못 나감 |
| `agwi_pace.json` | 아귀를 제자리 사격으로 깎는 속도 |
| `touch_controls.json` | 터치: 조이스틱(대각선 아래로 달려도 ↓ 아님), ↓+점프 발판 내려가기, 공격 누르고 있기, 지도·일시정지·설정(버튼 크기), 멈춤 안내 버튼, 대화 탭 넘기기. 끝에 `after_dialogue ... busy=false paused=false` 이면 통과 |
| `eska_moves.json` | 에스카 시제품: 대기·달리기·베기·순간이동·천열·단공·봉공·공중 베기·터치(공격 버튼, 고정 방향키·대각선 끌기, ↑+스킬) · 이단점프 · 활주 스크린샷 |
| `eska_hits.json` | 에스카 시제품 피해 확인 (사양: `docs/eska/combat_spec.md`)(측정마다 체력을 다시 채움): 베기(한방 70, 0.32초마다 — 10프레임 간격 4번 누르면 2번 나감) 140 · 천열 896(앞쪽 한 점을 감싸는 회오리 10번: 80×9+176) · 단공 124(머리 위 한 점을 감싸는 회오리 5번: 22×4+36) · 공중 베기 140 · 공중 첫 베기에 떠 있음 · 순간이동 거리(150 + 이동 관성: 501 → 658.67) |
| `eska_foes.json` | 에스카 시제품 적: 돌진형(웅크림·돌진 맞으면 체력 6→5) · 원거리(조준선·구슬) · 거구(들기·내려찍기 충격파 → 4) · 9 피해로 쓰러짐(0) → 1.5초 뒤 부활(6, 400,300). 모든 에스카 시나리오는 첫 프레임에 적 물결을 끈다(`waves.set('enabled', false)`) |
| `eska_still.json` | 에스카 봉공(공간 고정): 돌진형·원거리가 5초 굳었다(still>0) 풀리면 다시 움직임 · 쿨다운 30초 · T 키로 진화 켜기 → 굳은 동안 베기 피해의 50%가 깨질 때 추가(예: 베기 3번 210 → 105 추가, 허수아비 1200→1095) · 시험 구역의 굳은 돌 위에 서고(`put_on_rock()`, is_on_floor true) 풀리면 바닥으로 떨어짐 · 스크린샷 s01~s06 |
| `eska_tutorial.json` | 에스카 튜토리얼 "종언의 문턱"(루프 4 개편: 단공 딱 맞춤 · 낙성 · 가마솥에서 속박 달이기 · 사냥개 속박 던지기 · 거상 틈 달이기 → 실제 피해로 게이지 → 대마법)을 처음부터 끝 화면까지 eval로 건너뛰며 각 단계 `step_name()` 확인. 3340프레임에 `end sub=1` 이면 통과(루프 5 — 앞부분 압축, 단공 다리, 틈 달이기 두 번 · 루프 6 — 기본 허리띠의 속박은 방향 없는 F칸, 해낸 연습 과제를 `EStage.practice_done`에 정수 키로 적음) · 단계 설명은 `docs/eska/tutorial.md` |
| `eska_core_ult.json` | 종언 게이지(가득 7600 — 베기 피해로 참, 대마법 피해는 안 참) · 모자랄 때 막힘 · D 고르기 순환 · 대마법 4종 의식(의식 중 무적, 공중 의식) · 봉공 · 낙성 지상/공중 · 메아리 · 쿨다운 배수 · 피해 배수 · 포식 · 범위 배수 |
| `eska_core_items.json` | F 방향별 칸 · 마시기 느림/맞으면 끊김 · 공중 던지기 · 부활 시 허리띠 가득 · 터치 배치/물약 칸/고르기/대마법 버튼 |
| `eska_core_practice.json` | 훈련장 연습(루프 4): `waves.enabled` false(기본 꺼짐) · `set_practice(true)`로 공중 모래주머니·연습용 망령 켬(시험 실행기에선 기본 끔) · 망령이 280px 안에서 느린 구슬을 쏨(es_projectile > 0) · ↓A 낙성이 공중 표적을 맞히면 과제 0 체크 · S 대마법 → 과제 4 · 구슬을 ↑A로 딱 맞춤 → 과제 1, 지운 뒤 Z로 시전 끊기(st 0, 위로 뜀, deflected 1) · 터치를 만지면 안내판·과제 글이 터치 이름으로, 장면 안내 `{es_up}+{es_skill}`이 보스바 자리 아래 가운데에 · 부활하면 `_ctx_t` 10으로 다시(루프 8) · 루프 5: 체크되면 연습 과제가 펼쳐짐(`is_open` true), 접힌 줄을 터치하면 펼침 · 에스카가 가마솥 쪽이면 틈 달이기 안내판 진하기 1, 봉공 안내판 0.3 · 허수아비를 공격 버튼 밑으로 옮기면 `touch.cover_alpha('attack')` 0.6, 점프는 1 · 오른쪽에 거상을 두면 `cam_bias.bias` 약 130 · 루프 7: 장면 안내는 한 줄씩(p04·p08에 두 줄이 번갈아) · 루프 8: `hud.hold_hints(1.0, 문구)` → `_hold_t` > 0, 1초 뒤 `_next_t` > 0·`_next_line` 그 문구 · 루프 6: 허수아비를 물약 버튼 밑에 두면 `cover_outline('potion')` true(진하기는 1 그대로) · 장면을 다시 열어도 해낸 과제가 체크된 채(`EStage.practice_done`) · 키보드에서 `cam_bias.bias` 0 → `force_bias(2.0)` 뒤 약 215. 스크린샷 p00~p09 |
| `eska_core_title.json` | 타이틀의 마녀가 게임 속 에스카 그림(SubViewport 3배, 1px 외곽선 셰이더) + 큰 보름달 가운데 먹빛 실루엣(라벤더 아트 픽셀 1칸 외곽선) + 등 뒤 도는 문장 고리, 달은 숲 앞 — 스크린샷 tt01·tt02 |
| `eska_core_input.json` | 에스카 조작감(루프 2): X 누르고 있기 55프레임 = 베기 3번(1200→990) · 터치 공격 버튼 누르고 있기도 3번(990) · 천열 시전 중 ↑A → 끝나자마자 단공(`cast_kind` dangong) · 시전 중 S → 의식(st 5, blackstar) · 의식 중 F → 마시기(st 6, drink) · 피격 경직 중 C → 순간이동(st 1) · 순간이동 10프레임 뒤에도 무적(`hurt` false) · 맞힌 뒤 순간이동 경로 찢기(`tears` +1, 1200→1080 = 70+50, `rift_at` true) · 1초 안 다시는 안 찢김(1010) · 맞힌 뒤 0.7초면 안 찢김(940) · 다시 찢김(820) · 루프 3: 천열 시전 시작 2프레임 뒤 F → 시전이 끝나면 마시기(st 6) · 대마법 의식 시작 3프레임 뒤 C → 의식이 끝나면 순간이동(x 300 → 약 140) · 터치 카메라 여유 `limit_right` 1520(1280+240) · 오른쪽 끝 스크린샷 c06. 피격 중 순간이동 시험은 멈춤(실제 시간 기준)을 `Fx.reset_time()`으로 지워 기계 속도와 상관없게 함 |
| `eska_tutorial_bot.json` | 튜토리얼을 **실제 입력만으로** 끝까지 (자동 플레이 봇 `tools/test/eska_tut_bot.gd`를 `attach`로 붙임 — 딱 맞춤·낙성·달이기·속박 던지기·틈 달이기(갓 찢긴 틈 두 번)·대마법까지). 4200프레임에 `end sub=1` 이면 통과(루프 5) |
| `eska_magic_*.json` | 마법(시험용 노드 `tools/test/eska_magic_cast.gd`를 `attach` — `cast(이름)`·`big_hp()`·`orb(...)`): `slash`(베기 찢김 프레임) · `flurry_read`(천열 찢김 최대 3장) · `dangong`(구슬·비검 튕겨내기) · `nakseong`·`nak_range`(낙성 6×75, 30~240px 겨눔) · `meteor`·`meteor_single`(유성우 무리/단일 약 1620) · `blackstar`·`absorb`(흑성·물약 흡수) · `left`(왼쪽 보고 시전) · `perf`·`perf_crowd`(도형·입자 수) |
| `eska_potion_*.json` | 물약(사양 `docs/eska/potions.md`): `drink`(마시기·버프) · `throw`(던지기·깨짐) · `rift`(틈 달이기 — 틈 등록 뒤 던져 스며듦) · `cauldron`(가마솥·달이기 화면) |
| `eska_boss_*.json` | 검성 보스장(`eska_boss.tscn`): `flow`(입구 → 등장 → 싸움) · `moves`·`art`(기술별 스크린샷, `skip_intro`·`move(이름)`) · `majesty`(등장 연출) · `still`(봉공에 굳음) · `bot`·`bot_shots`(자동 플레이 봇 `tools/test/eska_boss_bot.gd` — 걸린 시간·밸런스) |
| `eska_perf.json` | 에스카 시제품 성능: 대기·연격·스킬 겹침·연격 중 `perf()` (그리기 호출·도형·노드·처리 시간·입자). 그림 코드별 비용은 eval `bench(400)` (µs) |
| `title_touch.json` | 터치: 타이틀 탭 → 설정 → 돌아가기 → 구버전 (세라 데모) → 새로 시작 → 확인 (저장 기록이 있을 때 기준 좌표). 끝에 `STATUS title_end ... room=t_pass` 이면 통과 |
| `turn_touch.json` | 턴제(`?turn`) 터치 흐름: 편성 1단계(카드 → 명단 → 장비 ▶) → 마법 장착(타일 설명 · **길게 눌러 강화 Lv2** · 장비 길게 눌러 Lv2 · 대마법 줄) → 편성 → 전투 고르기(S-03) → 출격 → 자동 전투. 스크린샷 c00~c13, 끝 `status()` |
| `turn_ui_ally.json` | 단계 C2 (review_C2 H1·H2): 앞자리 엠버 풀무질 → **가운데 마녀 몸을 터치**해 대상(`["idle", 2, 0]`) · 다시 시작해 **아군 패널 터치**로 대상 · 에스카 세계의 끝에서 적 카드 체력이 피해 숫자가 뜨는 프레임(m90)에 바뀌는지 (`hud.vhp` 출력) |
| `turn_ui_wheel.json` | 턴제 화면(단계 C): 뒤·중·앞 마녀 바퀴(w0_back·w5·w6·w7_front) · 칸 고름 · 대상 고르기 · **적·마녀 상세(0.4초 누름)** · 대마법 칸 · 피해 숫자(n0~n3) · 철수 확인 판(x0) · 승리 → 편성(x1·x2) |
| `turn_ui_boss.json` | 보스 전투: 웨이브 1(같은 적 A/B·번호 배지) · 웨이브 배너 · 웨이브 2(앞·뒤 자리) · 재의 왕 보스 카드(차지 가득·줄 2/3·징표 겹) · 기절 별·도발 아이콘 · 보스 상세 · 패배 배너 → 편성으로 (k00~k10) |
| `turn_ui_trial.json` | 전투 고르기에서 시련 → 시련의 거상 필살기 무적 관통 표시 · 상세 (t00~t04) |
| `turn_ui_setup.json` | 전투 고르기 카드 3장 · 편성의 고른 전투 줄 · 마법 장착 탭 3 · 장착 최대 안내 · 장비 목록(아이콘 · 효과 줄)·설명 (s00~s10). 누름은 설계 좌표 `dtouch`라 `--resolution 800x360`에서도 같은 화면 (R6) |
| `turn_firstplay.json` | 단계 F-1: 저장 없는 첫 실행(`"turn_save": "fresh"`)에서 **터치만으로** 타이틀(R6 `f00_title`) → 곧장 안내 전투 B1~B7 → 편성 A1 → C1~C3 → 일반 전투 시작. 봇 `turn_touch_bot.gd`(안내 판 누름·강조 칸 누름·바퀴는 `TAuto.pick` 칸 → 다시 → 대상). 판마다 스크린샷 `g_<id>`, 끝 "FIRSTPLAY done …" |
| `turn_enemies.json` | 단계 F-2: 새 일반 전투 다섯 첫 화면 + 적마다 상세(길게 누름) · 세 빛의 인형 줄 1~3 · 둥지어미 줄 1~2 · 새 의도 알약 9 · 방어 태세·막아서기·봉인·약화 표시 · 봉인 바퀴 · 막아서기 대상 · 의도 연출 `ev_*`(시험 훅 `TStage.demo_enemy`·`demo_basic`·`demo_down`) |
| `turn_big.json` | 단계 F-3: 큰 글자를 켠 채(첫 프레임 `guide._settings_press`) 바퀴·설명 띠·적/마녀 상세·도움말(33칸)·전투 중 설정·패배 배너·S-02 탭·설명 상자 (review_I I-10) |
| `turn_backdrops.json` | 단계 F-3: 전투·웨이브 배경 테마 10(들판·불길·호수·뇌운·회랑·서고·시련·인형·둥지·재의 왕) + 웨이브가 바뀌는 순간 덮개 (`combat_proto.md` §22.7) |
| `turn_save.json` | 단계 F-1: 타이틀(R6) → 첫 실행 안내 전투에서 안내 끄기 → 철수 → 편성 바꿈·장비 목록·명단 상세 → 출격 → 창 가려짐(멈춤) → 다시 켬(`test_relaunch`) → 끊긴 전투 판 → 이어 하기 → 다시 켬 → 버리기 → 설정·도움말. `test_files()`로 파일·편성 출력 |
| `turn_auto.json` · `turn_auto2.json` · `turn_boss.json` · `turn_trial.json` · `turn_fx.json` | 자동 전투(일반·보스·시련)와 마법 연출 35종. 편성 → 전투 고르기 → 출격은 "전투 시작" 자리를 두 번 누른다 |
| `turn_ult.json` | 대마법 12개 연출 — 마녀마다 컷인(a)·문장 고리(b)·효과(c)·맞음(d) 4장 + 연쇄 3단계 2개 + `perf()`(그리기 호출·입자·연출 노드)와 기존 큰 마법 4개 비교 (단계 D) |
| `turn_events.json` | 웨이브 전환(걸어 들어옴·보스 착지) · 재의 왕 줄 1~3 모습 · 크리 · 브레이크 · 기절 · 해제 · 근성 · 도발 · 저항/면역 · 관통 필살기 · 시련의 거상 줄 1~3 (단계 D, `demo_wave`·`demo_event`) |

| `turn_wide.json` | 넓은 화면(review_K K-01): 편성 S-01·S-02·S-03 · 바퀴 · 대상 · 적 상세 · 자동 전투 · 철수 확인 · 웨이브 배너 · 도움말 · 승리 · (R3) 폰 웹 흉내(`guide.test_phone`)에서 전체 화면이 풀렸을 때 다시 들어가는 버튼 `wd12_fs_button`(오른쪽 끝 · 640 화면엔 자리가 없어 안 보임) · 설정 "전체 화면" 줄 `wd13_settings_fs`. `--resolution 780x360`(19.5:9) · `800x360`(20:9) · `640x360`으로 같은 시나리오를 돌린다 (`dtouch` 사용) |
| `turn_r2.json` | R2(review_L): 편성 설명 상자 17장(불의 고리·잉걸불·장송의 불·잔잔한 수면·쇄빙 일격·얼음 벽·겨울의 맹세·뇌격·과전류·박차·번개 나눔·불쏘시개·불의 숨결·태양의 창·샘물 붓기·서리 숨결·검기 두르기 — 효과 점 목록·"어울림"·용어 풀이 줄) · 도움말 새 용어 · 큰 글자 설명 상자·도움말 · 전투 큰 글자 연쇄 칩 + 받는 크리 데미지/확률 아이콘 + 지속 회복 숫자(기본 공격 뒤 다음 바퀴가 열려도 또렷한지) · 가장 긴 위 띠 글의 연쇄 칩 · 보통 글자 연쇄 칩 1·3단계 (r00~r30) |

- 시나리오 파일이 없으면 실행기는 `SCENARIO not found`를 찍고 바로 끝난다(종료 코드 1).
- 턴제는 창 화면비를 넓히는 배율(높이 360 기준 소수 배율 + 화면비 확장)을 쓴다 — `--resolution 800x360`이면 스크린샷도 800×360이고 640×360 설계 화면은 가운데(`TTheme.ofs` = (80, 0))에 있다.
- 출력 폴더는 실행기가 만들지 않는다 — 먼저 `mkdir -p /tmp/out`을 해 두지 않으면 `Can't save PNG` 오류가 난다.

## 턴제 밸런스 기준선 (R2 — review_M F15)
```bash
$G --headless --script ../tools/test/turn_sim.gd -- 20 builds compare   # 기준선 baseline_turn.json과 비교 — 10% 넘게 바뀐 칸만
$G --headless --script ../tools/test/turn_sim.gd -- 20 builds save      # 바뀐 것을 받아들이면 기준선을 옮김 (원형 8 × 전투 11)
```
- 칸 = 승 · 승리 평균 마녀 행동 · 분 · 마법 사용률 · 대마법률, 전투마다 원형 속도 비. 판정: 승률 ±10%p · 행동 ±10% · 마법 사용률 ±10%p · 속도 비 ±10% (`combat_proto.md` §25.5).

## 웹 빌드 연기 시험
```bash
$G --headless --export-release "Web" /tmp/web/index.html
(cd /tmp/web && python3 -m http.server 8766 &)
node ../tools/test/web_smoke.mjs /tmp/out    # 타이틀 → 새로 시작 → 안내 → 지도 → 일시정지, 콘솔 로그 출력
```

## 턴제 웹 연기 시험 (폰 흉내)
```bash
$G --headless --export-release "Web" /tmp/web/index.html
(cd /tmp/web && python3 -m http.server 8766 &)
node ../tools/test/web_turn.mjs /tmp/out                                   # 20:9 (CSS 915×412, 비율 2.625)
node ../tools/test/web_turn.mjs /tmp/out "" 844x390@3                       # 19.5:9
node ../tools/test/web_turn.mjs /tmp/out "" 915x412@2.625 3                 # CPU 3배 느리게 (느린 프레임에서 짧은 탭)
node ../tools/test/web_turn.mjs /tmp/out "" 915x356@2.625                   # 주소 막대가 보이는 가로 (R3)
node ../tools/test/web_turn.mjs /tmp/out "" 412x915@2.625                   # 세로로 시작 (R3) — 세로 안내 판만 보고 끝
```
주소 기본 `index.html?turn&probe` — `probe`가 있으면 게임이 `window.eskaProbe()`를 열어 화면 상태와 누를 자리(설계 좌표)를 `window.eskaState`(JSON)로 알려 준다(`TStage._on_probe`). 시험은 그것을 CSS 좌표로 바꿔 누른다.
흐름: 타이틀(R6) → 첫 탭(**이 탭을 뗄 때 전체 화면 요청** — R3 review_N N-02 · 첫 실행이라 곧장 안내 전투) → 안내 끄기 → X → 철수 → 전투 고르기 → 출격 → 마녀 차례마다 기본 공격 칸 두 번 + **적 카드를 80~150 ms 탭**(먹혔는지 셈) → 적 카드 길게 누름(상세) → X → 철수 확인 → 취소 → **세로로 돌림(창 크기를 W↔H) → 가로로 되돌림 → 멈춤 판 탭** → 창 가려짐 → `localStorage` 저장 → 새로고침 → 끊긴 전투 판.
통과: `SCREEN … used 100.0%` · `FS web true` · `TITLE mode 'title' → '' in_battle true phase 'B1'` · `FS after-first-tap tried true` · `INTRO off → setup true` · `TAPS ok n/n` · `CONFIRM open true` · `ROTATE portrait true pause true … → back false mode 'pause'` · `SAVED localStorage bytes` > 0 · `RESUME panel resume` · `CONSOLE errors 0`.
- 헤드리스 Chromium은 요청을 받아 주어 `doc-fullscreen true`가 된다(폰 실기와 다를 수 있음). 전체 화면이 아니고 오른쪽에 640 바깥 자리가 40px 이상이면 다시 들어가는 버튼(`fs_btn`)을 눌러 본다(`FS button tap`).
- 세로로 시작(`412x915`): `PORTRAIT start true after-tap true setup_step 1→1`(세로 안내 판이 누름을 먹음) · 스크린샷 `p1_portrait`.

## 모바일(터치·오프라인) 웹 시험
```bash
$G --headless --export-release "Web" /tmp/web/index.html
python3 ../tools/web_sw_patch.py /tmp/web   # 배포(web-build.yml)와 같게 서비스 워커 바꾸기
(cd /tmp/web && python3 -m http.server 8766 &)
node ../tools/test/web_mobile.mjs /tmp/out
```
가로 태블릿(CSS 1280×800, 픽셀 비율 1.5, 터치)으로 타이틀 탭 → 새로 시작 → 대화 탭 → 조이스틱+점프 두 손가락 → 일시정지 → **인터넷을 끊고 다시 열기**. 출력의 `SW ... files`에 `index.wasm`·`index.pck`가 있고 `OFFLINE title`이 게임 제목이면 통과(오프라인 안내 페이지면 제목이 "YEMO — 오프라인").

## 웹앱 아이콘
`$G --headless --script ../tools/make_icons.gd` (game/ 에서) → `game/assets/icon/icon_{144,180,512}.png`

## 방 도달 검사
```bash
python3 tools/roomgen.py check   # 저장소 루트에서. 출구·문·기록 지점·수집품이 서로 닿는지 (한 번 점프 / 2단 점프 / 여우창문)
```
