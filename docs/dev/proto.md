# 전투 시제품 (새 조작 훈련장) — `game/proto/`

타이틀 → **전투 시제품 (새 조작)**. 본편과 따로 도는 훈련장(허수아비만, 능력 전부 해금, Tab 시험 패널)이다.
조작·마법 결정 기록은 [../design/controls_skills.md](../design/controls_skills.md). 본편 코드(`player/`·`world/`)는 건드리지 않는다.

| 파일 | 하는 일 |
|---|---|
| `p_data.gd` (PData) | 수치 상수(이동·발톱·대시·방패·폭주 게이지·변신), 마법 7종 표(`SPELLS`: 키·쿨·최대 레벨), 불/여우불 색 |
| `p_state.gd` (PState) | 시험 패널 값(키 방식·회피술·꼬리 수·폭주 배율·쿨 감소 물약·쿨 없음·난이도·마법 레벨), 키 등록(`pr_` 접두사), 등급 키 → 마법 고르기(`spell_pressed`) |
| `p_sera.gd` (PSera) | 세라 조작·상태(보통·대시·의태 돌진·시전·압축·난무·마시기·피격·쓰러짐), 자원(체력 반 칸·폭주 게이지(시간·마법·발톱·피격 → 가득이면 변신)·물약·부활), 마나 없음 |
| `sera_art.gd` (SeraArt) | 세라 그림(코드 그리기). 날씬한 5등신, 붉은 땋은 머리·남색 금장 롱코트·붉은 프릴 치마·마녀 모자. 변신 = 모자 벗고 여우 귀·꼬리·발 |
| `p_spells.gd` (PSpells) | 마법 7종 + 여우방패(정령 + 할퀴기 반격) + 불사조 부활. `try_cast`가 마나·쿨 확인 후 시작 |
| `p_vfx.gd` (PVfx) | 발톱 참격·여우손·대시 빛살·의태 돌진 정령·여우 발 도장 등 효과, 안전한 다각형 그리기(`safe_poly`) |
| `p_dummy.gd` (PDummy) | 허수아비(작은·보스 크기·매달린·발사대) |
| `p_hud.gd` · `p_panel.gd` · `p_arena.gd` | HUD(하트·마나·게이지·마법 칸·H 조작 안내), Tab 시험 패널, 훈련장 지형·카메라 |

- 가산 합성(빛) 효과 안에서 어두운 것(붉은 화면·바위·결정·불꽃 리본)은 `PSpells.NormalLayer` 자식에 그린다(`z_index = -1`이면 빛 뒤).
- 시험: `tools/test/scenarios/proto_*.json` (moves·claw·spells·extra·revive·dbg·fx2·v3·grade·od). 전용 키로 마법을 누르는 시나리오는 첫 줄에 `dbg('key_mode', 1)` — 실행기 사용법은 tools/test/README.md.
