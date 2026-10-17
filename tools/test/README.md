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
| `touchinfo` | 터치 조작 상태 (터치 모드·표시 여부·눌린 동작·조이스틱 방향) |
| `setting` 키 값 · `potions` 개수 | 설정 값 지정(저장된 설정이 시험에 끼어들지 않게) · 물약 수 |
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

## 웹 빌드 연기 시험
```bash
$G --headless --export-release "Web" /tmp/web/index.html
(cd /tmp/web && python3 -m http.server 8766 &)
node ../tools/test/web_smoke.mjs /tmp/out    # 타이틀 → 새로 시작 → 안내 → 지도 → 일시정지, 콘솔 로그 출력
```

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
