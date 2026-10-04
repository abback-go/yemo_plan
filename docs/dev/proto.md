# 전투 시제품 (새 조작 훈련장) — `game/proto/`

타이틀 → **전투 시제품 (새 조작)**, 또는 웹 주소 https://abback-go.github.io/yemo_plan/?proto 로 바로. 본편과 따로 도는 훈련장(허수아비만, 능력 전부 해금, Tab 시험 패널)이다.
조작·마법 결정 기록은 [../design/controls_skills.md](../design/controls_skills.md). 본편 코드(`player/`·`world/`)는 건드리지 않는다.

| 파일 | 하는 일 |
|---|---|
| `p_data.gd` (PData) | 수치 상수(이동·발톱·대시·방패·폭주 게이지·변신), 마법 7종 표(`SPELLS`: 키·쿨·최대 레벨), 불/여우불 색 |
| `p_state.gd` (PState) | 시험 패널 값(키 방식·회피술·꼬리 수·폭주 배율·쿨 감소 물약·쿨 없음·난이도·마법 레벨), 키 등록(`pr_` 접두사), 등급 키 → 마법 고르기(`spell_pressed`) |
| `p_sera.gd` (PSera) | 세라 조작·상태(보통·대시·의태 돌진·시전·압축·난무·마시기·피격·쓰러짐), 자원(체력 반 칸·폭주 게이지(마법·발톱 적중 → 가득이면 마법 봉인, Space로 변신)·물약·부활), 마나 없음 |
| `sera_art.gd` (SeraArt) | 세라 그림(코드 그리기). 날씬한 5등신, 붉은 땋은 머리·남색 금장 롱코트·붉은 프릴 치마·마녀 모자. 변신 = 모자 벗고 여우 귀·꼬리·발. 바닥 그림자·착지 눌림 |
| `p_spells.gd` (PSpells) | 마법 7종 + 여우방패(조작에서 빠짐) + 불사조 부활. `try_cast`가 봉인·쿨 확인 후 시작(시전 마법진) |
| `p_vfx.gd` (PVfx) | 발톱 참격·여우손·적중 섬광(베인 자국)·대시 빛살·의태 돌진 정령·변신 연출·시전 마법진·피해 숫자(한 노드), 불티·먼지·연기 보내기 |
| `p_dummy.gd` (PDummy) | 허수아비(짚·갑옷·매달린 모래주머니·여우 석상 발사대). 맞으면 눌림·흔들림·재질 조각(짚·쇠 불꽃·모래·돌), 체력바 깎인 부분 표시 |
| `p_hud.gd` (PHud) | 문장·하트(깨짐·두근거림)·폭주 게이지(부드럽게 참·봉인 불꽃)·물약·꼬리, 마법 7칸(등급 묶음·원형 쿨·준비 반짝임·레벨 점·봉인 사슬), H 조작 안내 |
| `p_panel.gd` · `p_arena.gd` | Tab 시험 패널, 훈련장 지형·허수아비 배치·카메라 |
| `p_scenery.gd` (PScenery) | 배경: 하늘·먼 산과 학교·가까운 지붕(시차) → 회랑 벽(아치 창) → 횃불 빛·깃발 → 지형·석등·표지판 → 떠다니는 불티 → 화면 가장자리(체력 1칸 이하면 붉게 맥동) |
| `p_draw.gd` (PDraw) | **묶음 그리기** — 아래 성능 절 |
| `p_particles.gd` (PParticles) | 불티·불꽃·먼지·연기를 한 노드(가산 1 + 보통 1)에서 움직이고 그림 |
| `p_bench.gd` (PBench) | 성능 측정(개발용) — 아래 |

- 가산 합성(빛) 효과 안에서 어두운 것(붉은 화면·바위·결정·불꽃 리본)은 `PSpells.NormalLayer` 자식에 그린다(`z_index = -1`이면 빛 뒤).
- 시험: `tools/test/scenarios/proto_*.json` (moves·claw·spells·extra·revive·dbg·fx2·v3·grade·od·odsum·scene·feel). 전용 키로 마법을 누르는 시나리오는 첫 줄에 `dbg('key_mode', 1)` — 실행기 사용법은 tools/test/README.md.

## 성능 규칙 (2026-10-04 최적화)

웹에서 렉의 원인은 두 가지였다.
1. **그리기 호출 수**: 엔진은 `draw_colored_polygon`·`draw_circle`·두꺼운 선 하나마다 그리기 호출을 1번 보낸다. 세라 그림 하나에 ~97번, 평상시 화면 289번, 큰 마법이 겹치면 552~790번.
2. **마법을 쓸 때마다 0.4~0.7초 멈춤**: 불티를 낼 때마다(때로는 입자 1개짜리) `CPUParticles2D` 노드를 새로 만들던 것. 웹에서 이 노드를 만들 때마다 크게 멈췄다.

그래서 시제품의 모든 그림은 이렇게 그린다.
- **`PDraw`**: 한 노드의 도형을 삼각형 묶음 하나로 모아 `flush` 때 그리기 호출 1번으로 보낸다. `CanvasItem`과 같은 이름(`draw_line`·`draw_circle`·`draw_colored_polygon`·`draw_arc`·`draw_rect`·`draw_set_transform`…)이라 `pd.draw_xxx(`로 쓰면 된다. 그라데이션(`rect_grad`·`strip_grad`·`line2`·`glow`), 띠(`strip`), 윤곽(`outlined` — 넓힌 모양을 해시로 기억) 도 있다. 글자는 지원하지 않는다 → `flush` 뒤에 노드에 직접 그린다.
- 효과 노드는 `PDraw.Canvas`를 상속하고 `_draw` 대신 `_paint`에 그린다. `PSpells.NormalLayer` 콜백은 `PDraw`를 받는다.
- 불티·먼지는 `PVfx.sparks`·`embers`·`dust`·`smoke`·`speed_line`·`mote_to`로만 낸다(→ `PParticles`, 최대 900개). **`Fx.burst`(CPUParticles2D)는 시제품에서 쓰지 않는다.**
- 피해 숫자는 `PVfx.number`(한 노드, 같은 대상이 0.3초 안에 또 맞으면 합쳐짐). `Fx.damage_number`(Label)는 쓰지 않는다.
- 움직이지 않는 그림(배경·벽·지형)은 한 번만 그리고 다시 그리지 않는다. 허수아비도 가만히 있으면 다시 그리지 않는다.

결과(Chromium 소프트웨어 렌더러, 같은 시나리오): 그리기 호출 평상시 289 → 21, 전부 겹침 552 → 31. 마법 사용 시 최악 프레임 683ms → 164ms(멈춤 사라짐).

### 측정 (`PBench`)
- 데스크톱/헤드리스: `PBENCH=1 godot --fixed-fps 60 res://proto/proto_arena.tscn` → `PBENCH 단계 frame=… p95=… max=… draws=…` 줄이 찍히고 끝나면 종료.
- 웹: https://abback-go.github.io/yemo_plan/?proto&pbench (시제품으로 바로 들어가 측정). 브라우저 콘솔에 같은 줄이 찍힌다.
- 단계: blank(아무것도 안 그림) · noscript(그림은 그대로, 스크립트 멈춤) · idle · claw · foxrain · asura · laser · meteor · phoenix · bind · fox_dash · all(전부 겹침).
