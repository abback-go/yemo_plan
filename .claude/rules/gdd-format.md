---
paths: ["docs/**/*.md"]
---

# docs/ 기획 문서 작성 규칙

docs/ 아래 문서를 읽거나 쓸 때 반드시 지킨다.

## 작성 전 필수 절차

1. **교재 원문(`reference/textbook.pdf`)에서 해당 문서와 관련된 Part/Chapter를 먼저 읽는다.**
   요약본(textbook_rules.md)만 읽고 쓰는 것은 금지다. 문서별 원문 위치:
   - 00_game_concept → Part 2 (Ch.9~16), Ch.19, Ch.100
   - 01_core_loop → Ch.20, Ch.101
   - 02_player_control → Part 4 (Ch.26~33), Ch.102
   - 03_combat_system → Part 5 (Ch.34~42), Ch.103
   - 04_ability_gate → Ch.25, Ch.81 (게이트·잠금 조건에 준용), Ch.39 (능력 정의 방식)
   - 05_map_progression → Part 8 (Ch.63~71), Ch.84 (세이브)
   - 06_item_reward → Part 6 (Ch.43~52), Ch.104
   - 07_ui_flow → Part 7 (Ch.53~62), Ch.105
   - 08_stage_design → Part 8 (Ch.63~71), Ch.106
   - 09_data_table → Part 9 (Ch.72~80), Ch.107
   - 모든 문서 공통 → Part 10 (예외 조건), Ch.91 (AI 프롬프트 절)
2. `reference/textbook_rules.md`를 읽는다.
3. 작성할 문서에 해당하는 `reference/templates/` 템플릿 파일을 읽는다.
   - 00_game_concept → `game_concept.md`
   - 01_core_loop → `core_loop.md`
   - 그 외 문서 → `gdd_base.md`의 해당 절
4. 템플릿 항목 중 **사용자가 아직 정하지 않은 항목을 질문 목록으로 제시**한다.
5. 답을 받은 뒤에만 파일을 만든다. 답이 없는 항목은 임의로 채우지 않는다.
6. Worker에게 위임할 때도 같은 원칙을 적용한다. 브리프에 원문 위치(줄 범위)를 담아
   Worker가 원문을 직접 읽고 쓰게 하라.

## 메트로배니아 필수 체크리스트

메트로배니아에서 놓치기 쉬운 항목이다. 관련 문서를 쓸 때 반드시 다뤘는지 확인하고,
빠져 있으면 사용자에게 질문한다.

- **능력 해금 게이트**: 어떤 능력이 어떤 길을 여는가. 능력별 해금 조건과 열리는 구역 목록.
- **역주행 동선**: 새 능력 획득 후 이전 지역으로 돌아갈 이유와 경로가 있는가.
- **맵 연결 구조**: 방(Room) ID, 출입구 ID, 출입구 간 연결 관계가 표로 정리되어 있는가.
- **세이브/체크포인트**: 저장 지점 위치, 저장되는 데이터, 사망 시 복귀 지점 규칙.
- **진행 잠금(soft lock)**: 능력 없이 진입한 구역에 갇히는 경우가 없는가. 탈출 수단 정의.
