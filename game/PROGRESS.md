# Godot 이식 진행 상황 (이어받기용)

- 작업 브랜치: `cc/amazing-darwin-nesbwh` / Godot 4.7.2, `game/` 폴더 / 판단 기록: `game/DECISIONS.md`
- CI: `.github/workflows/witch-web-build.yml` → gh-pages `godot/`(웹 빌드), `godot-ci/`(스크린샷·로그)

## 구조
- `data/game_data.gd`(수치·배치·연출 시간) · `data/script_data.gd`(대본 v0.6: 대사·안내·선택지·문구 전부)
- `core/`: `rules.gd`(전투 규칙, 잠긴 죽음 카드) · `ctl.gd`(장면 흐름) · `guide.gd`(안내 트리거) · `fx.gd`(애니메이션·입자) · `assets.gd` · `ui.gd` · `test_api.gd`(?test=1 웹 훅) · `autoplay.gd`(자동 진행) · `check_scripts.gd`
- `ui/`: `battle_view.gd`(전투 화면·연출·HUD) · `hand.gd`(두 손·세운 손) · `card_view.gd`(원근 카드) · `battle_input.gd` · `dialog_box.gd`(대사창·안내 상자) · `cutin.gd` · `blood.gd` · `icons.gd` · `btn.gd` · `card_art.gd` · `shaders/`
- `scenes/`: `scenes.gd`(타이틀·컷신·탈출·종료·전멸·되감기) · `vn.gd`(캠프·이벤트·계단·빈 캠프) · `omen.gd`(죽음 카드 떠오름) · `explore.gd`(탐색·걷기) · `map_view.gd`(지도)
- 시험: `tests/test_rules.gd`(규칙·데이터 53개) · `tests/web/smoke.js`(Playwright 경로 A~E, T=탑뷰 시험판)

## 로컬 검증 방법
- `godot --headless --path game --import` 두 번 → `godot --headless --path game -- --check-scripts` → `godot --headless --path game --script res://tests/test_rules.gd`
- 헤드리스 자동 진행: `godot --headless --path game -- --scene=camp --speed=10 --autoguide --autoplay --path=rest --choice=smile --trace --quit-on-end`
- 웹: export "Web" → `python3 -m http.server` → `node game/tests/web/smoke.js http://localhost:8000/ shots`

## 완료
- [x] 골격 가져옴 + 대본 v0.6 + 잠긴 죽음 카드 규칙(1층부터 손패 맨 오른쪽, 4장 드로우, 거대 존재 1턴 해제) + 규칙 테스트 37개
- [x] 전투 화면 전체(원근 카드, 손 둘만, 예고, 붉은 실, 컷인, 타격 모션, 피, 거대 존재 등장·z-order, 죽음 카드·컷신·C7·C8, 짓밟힘)
- [x] VN(캠프 파티 소개·이름표·죽음 카드 떠오름, 시체·휴식·훈련, 계단 선택, 빈 캠프 흐린 카드), 탐색(걷기·지도·갈림길), 탈출·종료, 전멸 되감기(붉게 번짐 → 유리 깨짐)
- [x] CI 첫 성공(run #9): 검사·규칙 37·헤드리스 자동 진행 2경로·스모크 43항목, 콘솔 에러 0 → gh-pages godot/·godot-ci/
- [x] 코디네이터 검토 반영: 지도 패널 위치·방 이름 판, 세운 손이 카드 아래 가장자리를 쥠, HP 표시 한 곳(st.party)에서
- [x] 대상 카드 조준: 끌기 시작하면 오른손이 손패에서 그 카드를 뽑아 손패 높이에서 작게 쥠(세운 손 그림 0.55배, `layout.grip`), 화살표는 쥔 카드에서. 확정하면 그 손이 커지며 세운 손, 취소하면 손패로 돌려놓음. 스모크 A(PC 조준·취소)·D(휴대폰 조준)에 손 둘·쥔 카드 위치 확인 추가

- [x] 탑뷰 이동 시험판(`?scene=topdown`, 튜토리얼 흐름과 따로): 넓힌 갈림길 맵(2112×1662 → 블록 2.5px로 844×664)·노엘 4방향 걷기, WASD·방향키 + 탭 이동(격자 경로찾기), 충돌 다각형, 앞벽 덮기·기둥/돌무더기 y 정렬 가림, 물건 4개 조사(대화창 + 옆 스탠딩), 출구 3개(갈림길 설명 → 시험판 끝 → 입구로). `scenes/topdown.gd`·`topdown_nav.gd`, 수치 `game_data.gd "topdown"`, 대사 `script_data.gd "topdown"`. 규칙 테스트 +9(46개), 스모크 경로 T(25항목)
- [x] 탑뷰 시험판 개선: 동료 셋(세라피나·브룬힐드·엘리안, 72px 칸 시트)이 노엘이 지나간 경로를 따라 18맵px 간격으로 줄지어 걷기(방향 행·걷기 그림·그림자·y 정렬 가림, 시작·되돌아올 때 줄 섬), 속도 72→120·걷기 그림 7→10fps, 터치: 왼쪽 절반 조이스틱(지름 130 CSS px, 아날로그 0.3~1배)·오른쪽 아래 조사 버튼(78 CSS px), 터치 빈 바닥 탭 이동 끔. 입구 자리 y 556→510(동료 셋이 방 안에 서게). 규칙 테스트 +7(53개), 스모크 경로 T 39항목


## 1차 시험판 v2 (docs/prototype-v2-spec.md, 2026-11-17~18 작업 중)
- 흐름: `core/ctl.gd` STEPS = camp → cult → fork → deep → emptycamp → chapter1 → f2corridor → f2ossuary → f2stairs → f3chapel → f3pyre → result
- 탑뷰: `scenes/topdown.gd`(맵 일반화: 맵마다 걷는 곳·가림·출구·트리거·인물·불빛, next_event() 로 흐름에 사건을 넘김, 필드 운명 연출) · `data/maps_data.gd`(맵 7장 데이터) · `ui/fate_hud.gd`(운명 표시·지도 버튼)
- 맵 그림: `game/assets/td_*.png` (tools/pixel_sheet.py --block N, 맵마다 블록은 maps_data.gd 주석). 확인 그림: `python3 tools/td_preview.py 맵id 출력.png`. 가져오기 설정: `python3 tools/fix_imports.py`(픽셀 그림 무손실·밉맵 없음, 카드 그림 512)
- 규칙: `core/rules.gd` 운명(st.fates·add_fate·offer_fate·defy_fate·descend·fate_trial_choice·resume_enemy_phase), 카드 레벨(lv, def_lv), 흉터, 「꿰뚫린 방패」 되돌리기, 운명의 불길 예고, 화형 사제 fateGuard, 상태 만들기(state_after_tutorial·state_floor3)
- 화면: `scenes/scenes.gd` fate_choice(바친다/거스른다)·card_gain(상속·흉터·운명 문구)·chapter(1층 끝)·result(결과 요약)·데스신(cutscene(key, level), Lv2 덧그림) / `ui/battle_view.gd` 운명 정지(fate_freeze)·불길·막힘·두 죽음 카드 실·전투 배경·적 배율
- 바로 가기: `?scene=camp|cult|fork|deep|emptycamp|floor2|ossuary|f2stairs|floor3&brun=alive|dead|pyre|result|topdown|giant|normal`, 자동 선택 `?fates=offer,defy,…`(운명의 시도 순서대로)
- 헤드리스 3경로: `godot --headless --path game -- --scene=floor2 --speed=10 --autoguide --autoplay --fates=offer,offer --quit-on-end --trace` (② defy,defy,defy ③ defy,defy,offer — 3층은 2턴 엘리안 → 3턴 브룬힐드 순서), 처음부터: `--scene=camp --path=rest --choice=smile --fates=offer,offer`

### v2 완료
- [x] 규칙·데이터: 운명·레벨·흉터·상속 2종·유품(전사)·창 기사·화형 사제·전투 2개 + 규칙 테스트 v2 18개(전체 72)
- [x] 맵 7장 줄이기·데이터, 탑뷰 일반화, 필드 운명의 시도(함정·시간 정지·붉은 실·선택·창·데스신·상속/흉터), 전투 운명의 시도(2턴 운명의 불길)
- [x] 헤드리스: 처음부터 끝(결과 요약)까지, 2층부터 ①②③ 모두 끝까지 에러 0 (②는 자동 진행이 3층 전투에서 여러 번 전멸 후 승리 → 화형 사제 수치 낮춤)

- [x] 웹 빌드 스크린샷 둘러보기(캠프·회랑·갈림길·깊은 곳·빈 캠프·2층·납골당·계단·3층·화형대·결과·휴대폰)로 고침: 컷신·선택 화면이 탑뷰 붉은 덮개 아래 깔리던 것, 장면 위 입자 층, 운명 표시 이름표 겹침, 지도 안내 대사 위치, 화형대 인물 자리, 결과 화면 가운데, 화형 데스신 불티
- [x] 스모크 경로 F(휴대폰: 운명 표시·조이스틱·필드 운명 바침·납골당·계단·조사·전투 중 운명 거스름·결과 요약 → 2층부터 / PC: 3층 Lv2 바침·죽음 카드 직접 내기) 19/19, 경로 A~E 를 탑뷰 흐름에 맞게 고침(A 끝까지 통과)
- [x] CI 워크플로 전체 검증의 헤드리스 자동 진행을 v2 5경로(처음부터 2 + 2층부터 ①②③)로
- [x] 타이틀에 「2층부터」「3층부터」 버튼, `?followers=0`(동료 따라 걷기 끔 — 운명의 시도 때만 나타남), 바친 뒤 창 함정은 가라앉고 핏자국, 선택 직후 카드 연출(바침: 들려 올라감 / 거스름: 움켜쥠)

- [x] 다듬기 2: 캠프 시작 자리(모닥불 아래, 동료 줄 오른쪽), 2단계 데스신 창(굵은 창날·피), 조사 거리(깊은 곳 발자국·납골당 관·화형대 뼈), 전투 직전 적이 돌아서며 「!」,
  PC 키보드(스페이스·엔터·E 로 대화 장면·안내·컷신 넘기기, M 지도), 필드에서 바친 뒤 상속 카드 안내, 새 적 그림 가져오기 768 제한(빌드 index.pck 19.1MB, v1 16.1MB)
- [x] GitHub Actions 수동 실행(workflow_dispatch)은 이 세션 권한으로 부를 수 없음(403 Resource not accessible by integration) → 같은 전체 검증을 로컬에서 실행

- [x] 마지막 로컬 전체 검증(최신 커밋): 스크립트 39 · 규칙 72 통과, 헤드리스 자동 진행 5경로(처음부터 2 + 2층부터 ①②③) 모두 결과 요약까지 에러 0,
  스모크 ABCDEFT 107/107 · 브라우저 콘솔 에러 0, 웹 빌드 index.pck 19.1MB(v1 16.1MB). GitHub Actions 푸시 빌드(빠른 빌드·배포) 통과

### v2 다음 할 일 (사용자 확인 뒤)
- GitHub Actions 전체 검증(Run workflow → full)을 사람이 한 번 실행(이 세션에서는 workflow_dispatch 403)
- 사용자 플레이 소감에 따라: 전투 수치(창 기사·화형 사제), 흉터 장수·시점, 대사([임시]) 조정 — 모두 data/game_data.gd · data/script_data.gd
- 그림이 오면 이름만 맞추기: 흉터 카드 `card_art_scar.png`, 창 기사 걷기 시트(maps_data.gd ossuary npcs 의 sheet)
- (여유) 동료 줄이 세로로 걸을 때 겹쳐 보이는 것, 2층 이후 지도 방 아이콘 다듬기

## 다음 할 일
- 최종 CI 통과 확인 후 최종 보고

## 알려진 문제
- v2: 자동 진행(헤드리스)은 카드를 앞에서부터 내는 단순한 방식이라 모두 거스른 경로(흉터 3장 + 두 죽음 카드)에서 화형대 전투를 여러 번 전멸 후 이긴다(사람은 피해 옮기기로 충분히 이길 수 있는 수치로 맞춤 — 사용자 판단 필요)
- v2: 동료 간격 32맵px 는 걷기 그림 키(약 60px)보다 짧아 세로로 걸을 때 앞사람과 겹쳐 보인다(옆으로는 떨어져 보임)
- v2: 창 기사 필드 픽셀·흉터 카드 그림은 임시(광신도 그림을 어둡게·1.25배 / 코드로 그린 손등 흉터)
- 로컬 swiftshader 에서 스모크 테스트가 느림(전체 약 9~10분). 스크린샷 시점이 늦어 짧은 연출은 느린 속도(setSpeed)로 찍는다
- 탑뷰 시험판: 기둥 뒤에 서면 노엘이 완전히 가려진다(실루엣 표시 없음). 가림 윤곽은 손으로 딴 다각형이라 가장자리 몇 px 오차. 휴대폰(DPR 3)에서는 무대 배율이 정수가 아니라 도트 폭이 1px 들쭉날쭉할 수 있음. 원본(좁은) 맵 비교용 `?map=small` 은 만들지 않음
- 본 안내 기록이 브라우저 저장소에 남아 같은 브라우저에서는 다시 나오지 않음(의도). 다시 보려면 주소에 `?guides=reset`

## 중단 지점 (2026-11-21, 버티컬 슬라이스 1단계 — 사용량 때문에 코디네이터 지시로 멈춤)
- 작업 브랜치: `worktree-agent-a2d4531c64d0b3cf1` (`cc/amazing-darwin-nesbwh` 의 5b5932d 에서 빨리 감기로 시작). 푸시하지 않음.
- **끝난 것** (커밋 df14966 + 이 커밋)
  - 흐름: 곁방(VN) → 장례 회랑(VN → 전투 ① → 카드 보상) → 안치 홀(VN → 지도·촛불 안내) → 지도 거점(방 8개 + 계단 앞 홀) → 가장 깊은 곳(광신도 → 거대한 발) → 빈 캠프 → 1층 끝 → 2·3층(탑뷰 대신 VN + 전투) → 결과. `core/ctl.gd` 새로 씀
  - 지도 화면 `scenes/floor_map.gd`(코드로 그린 임시 모양), 카드 고르기 `ui/card_pick.gd`(보상·거래·훈련), 지도 아이콘 7종(`ui/icons.gd`)
  - 랜턴 촛불·어둠·전조·이월(최대 8), 방 보상(일반 3장 중 1장·강적 희귀=강화 Lv2[임시]·휴식·훈련·거래·사건·「이름 없는 마녀의 카드」·「작은 손의 부적」), 수치는 `data/game_data.gd`(lantern·darkness·floorMaps·rewards·trade·buried·corpse)
  - 죽음 카드 컨셉 변경: 낼 수 없음, 세라피나 카드는 뒤집힌 채(faceDown) → 3턴 「짓밟기」(운명 hero_stomp, noDefy)에 저절로 뒤집힘 → "알고 있었는데." → 데스신(기존 컷, 대본 v3 자막) → 카드 문구 → 안내 → 반응 → 물러남. 2·3층 받아들인다/거스른다(흉터 유지). 잠금·되감기·웃어 준다 선택지 없앰
  - 대본 v3 → `data/script_data.gd`, 전멸 뒤 다시 하기 노엘 HP 최소 6(`rules.retryWitchHp`, 막힘 방지 [임시]), 알림(toast)을 장면 위로(z 445)
- **마지막으로 본 시험 결과**
  - `--import` 2번 → `--check-scripts`: scripts 41 ok, failures 0 (tests 고친 뒤)
  - `res://tests/test_rules.gd`: rules 95 passed, failures 0
  - 헤드리스 자동 진행(에러 0, 모두 결과 요약까지): 처음부터(방 8개 모두, `--rooms=prayer,gravekeeper,buried,corpse,stall,chapel,training,footprints --choice=open,card --fates=defy,defy,defy`) · 처음부터(어둠 2단계, `--rooms=prayer,buried,corpse,stall,chapel --choice=leave,candle --reward=skip --fates=accept,accept`) · 처음부터 최소 길(`--rooms=none --fates=defy,defy,offer`, 거대한 발 전멸 1번 → 다시 하기로 통과) · `--scene=floor2 --fates=offer,offer` · `--scene=floor2 --fates=defy,defy,defy`
  - 스모크(`tests/web/smoke.js` 새로 씀, 경로 ABCDEF — T 는 뺌): A 36/37(실패 1개는 테스트 기대값 잘못 — 가장 깊은 곳에서도 촛불이 타서 1+4=5, 고쳐 둠·다시 돌리지 않음) · B 5/5 · C 5개 통과 후 기도실 전투에서 시간 초과(botStep 이 전투 앞 VN 을 넘기지 않음 — 고쳐 둠·다시 돌리지 않음) · D·E·F 는 아직 못 돌림. 브라우저 콘솔 에러 0
- **반쯤 된 것**: 지도 레이아웃 손봄(곁방·회랑·홀 간격, 「지금 여기」를 방 왼쪽으로, 오른쪽 칸 간격) — 웹 다시 내보내기·스크린샷 확인 안 함. 스모크 C~F 다시 돌리기
- **다음 할 일**
  1. 웹 내보내기 → 스모크 ABCDEF 전체 다시 돌리기(로컬: `python3 -m http.server`, `node game/tests/web/smoke.js http://localhost:8765/ <폴더>`), 지도 스크린샷 확인
  2. 탑뷰·1인칭 탐색 지우기: `scenes/topdown.gd`·`topdown_nav.gd`·`explore.gd`·`map_view.gd`, `ui/fate_hud.gd`, `data/maps_data.gd`, `assets/td_*.png`, `game_data.gd` topdown·explore, `script_data.gd` 끝의 [정리 예정] 묶음, `test_rules.gd` t_topdown → DECISIONS.md 에 기록
  3. CI(`.github/workflows/witch-web-build.yml`)의 헤드리스 자동 진행 인자를 새 흐름(--rooms 등)으로, 스모크 기본 경로 ABCDEF
  4. DECISIONS.md 에 판단 기록 정리(아래 '열린 질문' 포함), PROGRESS.md 구조 갱신
- **판단·열린 질문(DECISIONS.md 에 아직 안 옮김)**: 방 8개를 안치 홀(기도실→무덤지기·순장된 자의 방·핏자국 통로 끝·좌판)과 계단 앞 홀(예배당·훈련장·발자국 방)에 나눔 / 랜턴을 받기 전 방(곁방·회랑·안치 홀)은 촛불이 안 타고, 계단 앞 홀·가장 깊은 곳은 탐 / 어둠은 깊은 곳 광신도 전투와 거대한 발 전투 둘 다에 / 강적 희귀 보상 = 강화된 카드 / 짓밟기는 세라피나만 죽이고 다른 동료 피해 없음 / 거래 HP 가 대가 이하이면 못 고름 / 가려진 예고도 옮기기·지우기 가능 / 카드 문구가 보이는 장면은 데스신 뒤 재가 된 다음 큰 카드로 / 표정 그림이 없는 표정(warrior_smirk·archer_cold)은 얼굴 없이
