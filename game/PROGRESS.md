# Godot 이식 진행 상황 (이어받기용)

- 작업 브랜치: `cc/amazing-darwin-nesbwh`(버티컬 슬라이스 1단계는 워크트리 브랜치 `worktree-agent-a2d4531c64d0b3cf1`) / Godot 4.7.2, `game/` 폴더 / 판단 기록: `game/DECISIONS.md`
- CI: `.github/workflows/witch-web-build.yml` → gh-pages `godot/`(웹 빌드), `godot-ci/`(스크린샷·로그)

## 구조 (버티컬 슬라이스, 2026-11-22)
- `data/game_data.gd`(수치·지도·랜턴·방에서 얻는 카드·배치·배경별 전투 배치 battleLayouts·VN 대화창 vnBox·그림 대응) · `data/script_data.gd`(대본 v3: 대사·안내·선택지·지도 문구)
- `core/`: `rules.gd`(전투·운명·지도·촛불·어둠·방에서 얻는 카드 규칙) · `ctl.gd`(장면 흐름: 곁방 → 회랑 → 안치 홀 → 지도 거점 → 방 → 가장 깊은 곳 → 빈 캠프 → 2·3층, 자동 저장·이어하기) · `save_game.gd`(user://save.json) · `game_settings.gd`(user://settings.cfg: 화면·글자 속도) · `guide.gd` · `fx.gd`(일시정지하면 멈추는 연출 시계) · `assets.gd` · `ui.gd` · `test_api.gd`(?test=1 웹 훅) · `autoplay.gd`(자동 진행) · `check_scripts.gd`
- `ui/`: `game_menu.gd`(메뉴 단추·일시정지·설정·확인 창) · `battle_view.gd`(전투 화면·연출·HUD, 배치는 `LY()`) · `hand.gd` · `card_view.gd`(뒤집힌 카드·뒤집기) · `card_pick.gd`(카드 고르기: 거래·훈련) · `battle_input.gd`(동료 대상 카드) · `dialog_box.gd` · `cutin.gd` · `blood.gd` · `icons.gd`(지도 아이콘) · `btn.gd` · `card_art.gd` · `shaders/`
- `scenes/`: `scenes.gd`(타이틀·컷신·전멸·운명 선택·카드 획득·층 끝·결과) · `vn.gd`(VN 장면·표정 스탠딩·양피지 대화창) · `floor_map.gd`(지도 거점) · `omen.gd`(죽음 카드 떠오름)
- 그림: `tools/vs_import.py`(art/raw/vs → game/assets: 크로마 배경 제거 soft 100 + 번짐 정리 + 크기 줄임), 대응표는 DECISIONS.md
- 시험: `tests/test_rules.gd`(규칙·데이터·저장 88개) · `tests/web/smoke.js`(Playwright 경로 A~F + S 기본 기능)

## 로컬 검증 방법
- `godot --headless --path game --import` 두 번 → `godot --headless --path game -- --check-scripts` → `godot --headless --path game --script res://tests/test_rules.gd`
- 헤드리스 자동 진행(CI 와 같은 5경로는 `.github/workflows/witch-web-build.yml`): `godot --headless --path game -- --scene=camp --speed=10 --autoguide --nosave --autoplay --rooms=prayer,gravekeeper,buried,corpse,stall,chapel,training,footprints --choice=open,card --fates=defy,defy,defy --trace --quit-on-end`
  - `--nosave`: 자동 저장·설정 파일을 쓰지도 읽지도 않는다(남은 저장이 시험을 바꾸지 않게). 저장이 있는 채로 이어하기를 헤드리스로 보려면 `--nosave` 없이 돌리다 끊고 `--continue` 로 다시(같은 `--rooms` 등)
- 웹: export "Web" → `python3 tools/web_sw_patch.py <빌드 폴더>` → `python3 -m http.server` → `node game/tests/web/smoke.js http://localhost:8000/ shots` (경로만: 뒤에 `AB` 등, 기본 ABCDEFS)
- 바로 가기: `?scene=camp|corridor|hall|map|room:<방>|giant|emptycamp|floor2|floor3|result`, 시험용 `&darkness=N&omen=1`, `?nosave=1`, `?continue=1`(타이틀 없이 이어하기)

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

## 버티컬 슬라이스 1단계 (2026-11-21~22) — 상태
- 끝남: 대본 v3 흐름 전체, 지도·촛불·어둠·방 보상, 죽음 카드 컨셉 변경(뒤집힌 카드 → 3턴 짓밟기에 뒤집힘 → 데스신), 2·3층 VN + 전투, 탑뷰·1인칭 탐색 정리,
  CI 인자, 배경별 전투 배치(5-9), 승인된 새 그림(뒷모습·광신도·무덤지기·발·손·카드 뒷면·예고 아이콘·배경 14·스탠딩 표정 11·아이·VN 대화창·카드 그림 17)
- **전투 승리 뒤 '카드 3장 중 1장' 보상 뺌**(2026-11-21 사용자 지시, 밤샘 계획 0-1): 장례 회랑·기도실은 이겨도 카드 없음. 무덤지기는 **기본안**(고르지 않고 희귀 목록 `rewards.elite` 에서 1장이 강화된 채 덱에). 묘지기의 좌판·무너진 훈련장은 그대로. 슬레이 더 스파이어와 비슷한 점·바꿀 제안은 `docs/originality-review.md`. 자세한 것은 DECISIONS.md 「전투 승리 보상 빼기」.
- 아직 옛 그림: 카드 틀, 컷인, 지도·랜턴·전투 HUD, 2·3층 배경·적·카드 그림. 세라피나 데스신은 기존 컷.
- 노엘 스탠딩: 39 v1 로 **임시** 교체(2026-11-21, 비치는 천의 초록 물듦을 몸 전체 디스필 G = min(G, (R+B)/2) 로 없앰 — DECISIONS.md). 고친 39 가 오면 `python3 tools/vs_import.py --only noel` 로 같은 이름에 다시 만들고 `faces.noel` 얼굴 자리를 다시 잰다.
- 손패와 세라피나 겹침: 배치 A(손패 +240 내림)·B(세라피나 top 430)는 사용자가 거절, **C 승인·적용**(손 무리 80%·카드 윗변 약 746·동료 셋 50 올림·회랑에서만 세라피나 HP 판 머리 오른쪽) — 값은 DECISIONS.md 열린 질문 항목.
- **기본 기능(밤샘 계획 1, 2026-11-22)**: 타이틀(시작 / 이어하기 / 설정 / 끝내기 — 웹은 끝내기 없음), 설정(창·전체 화면, 글자 속도 느림·보통·빠름·즉시 — `user://settings.cfg`), 일시정지(Esc·오른쪽 위 메뉴 단추: 계속 / 설정 / 타이틀로 — 연출·데스신 도중에도 멈춤), 자동 저장(방·단계에 들어갈 때 `user://save.json`, 버전 1) → 이어하기는 그 방의 처음부터, 결과 요약에서 지움. 자세한 것은 DECISIONS.md 「기본 기능」.
- 다음 할 일: 판단이 필요한 것(DECISIONS.md 열린 질문 — 촛불 소비 범위, 짓밟기 피해, 희귀 보상(무덤지기 기본안 확인)), 남은 그림 들여오기, 동작 그림(움직임 비교 시험 뒤)

## 문구 검수 (밤샘 계획 3, 2026-11-22)
- 1층 대사·안내 ↔ 대본 v3: 다른 줄 0(코드가 죽음·상속 카드 이름에 붙이는 'Lv1'만 다름 — 제안으로). 카드 설명 ↔ 효과 데이터 26장 같음. 이름 불일치·남은 승리 보상 언급 0. 글꼴에 빠진 글자 0.
- 고친 것(문구 데이터만, `data/script_data.gd`): 띄어쓰기 3곳 · 문장부호 17곳(따옴표 2·줄임표 1·속마음 괄호 9·「」 5) · 호칭·존댓말 5곳 · 맞춤법 1곳 — 모두 26곳. 전후는 DECISIONS.md 「문구 검수」.
- 제안(바꾸지 않음): `docs/text-review.md` — 2·3층 말투(브룬힐드 말끝·노엘 속마음), AI 같은 문장, 긴 안내 상자, UI 톤(「버티컬 슬라이스 시험판」→「체험판」 등), 슬레이 더 스파이어와 겹치는 이름(「상처」·「턴 종료」·에너지·강적) 대안, 판단 필요 항목.
- 시험(2026-11-22, 이 작업 끝): check-scripts 38 ok · test_rules 88 통과 · CI 와 같은 헤드리스 5경로 모두 결과 요약까지 에러 0(전멸 0/2/1/0/4, 시드 무작위) · 웹 내보내기(index.pck 23.0MB) + 스모크 A~F + S 106 통과·실패 0·브라우저 콘솔 에러 0(1280초).

## 움직임 시험 두 안 (밤샘 계획 4, 2026-11-22)
- 켜는 법: 웹 주소 뒤에 `?anim=a`(A′ 코드 효과 — 동료 뒷모습·적이 기울기·잉크 번짐·숨쉬기) 또는 `?anim=c`(C — 세라피나만 부위 뼈대). 다른 옵션과 함께 쓸 때는 `&anim=a`(예: `?scene=corridor&anim=c`). 헤드리스·데스크톱은 `-- --anim=a`·`-- --anim=c`. **옵션이 없으면 지금 화면 그대로**.
- 파일: `ui/battle_anim.gd`(두 안의 연결·A′) · `ui/sera_rig.gd`(C 뼈대) · `ui/shaders/hit_ink.gdshader`(잉크 번짐) · `data/anim_rig.gd`(C 관절 배치, 자동 생성) · `assets/anim/sera_*.png`(C 부위 11장) · `tools/anim_parts.py`(부위 시트 → 부위 그림·배치: `python3 tools/anim_parts.py` 뒤 `--import`)
- 방식·한계·비용, 사용자가 고를 것: DECISIONS.md 「움직임 시험 두 안」.
- 비교 자료(저장소 밖, 세션 scratchpad 의 `vs_shots/`): 장례 회랑 전투 1턴 — 대기 → 세라피나 성검 베기 → 턴 종료(세라피나·엘리안 피격)를 기본·A′·C 로 같은 시드(7)에서 0.3배 속도로 녹화
  - `anim_compare.webm`·`anim_compare_nohand.webm`: 세 안을 세로로 쌓은 15초 영상(손패 보임 / 손패 숨김 — 시험 훅 `hideHand`)
  - `anim_compare_{idle,attack,hit}[_nohand].jpg`: 같은 장면 프레임 표(줄 = 기본·A′·C), `anim_c_fit.jpg`: C 부위 조립 ↔ 지금 뒷모습(비율 차이)
  - `anim_{base,a,c}[_nohand]/`: 안마다 전체 녹화(`video/*.webm`)·스틸·구간 프레임. 만든 스크립트는 `scratchpad/verify_4/anim_shots.js`·`frames.py`·`compare.py`·`rig_fit.py`
- 시험: 스모크 경로 M 추가(기본 경로 목록 `ABCDEFSM`) — `anim=a`·`anim=c` 로 장례 회랑 전투 한 판(실제 드래그로 성검 베기 → 승리), 연출 도중 일시정지하면 화면이 그대로, 콘솔 에러 0. 경로 M 만: `node game/tests/web/smoke.js <주소> <폴더> M`
- 시험(2026-11-22, 이 작업 끝): check-scripts 42 ok · test_rules 88 통과 · CI 와 같은 헤드리스 5경로 모두 결과 요약까지 에러 0(전멸 1/0/4/3/1, 시드 무작위) · 헤드리스 경로 ①(처음부터, 방 8개)을 `--anim=a`·`--anim=c` 로 한 번씩 에러 0(전멸 0/1) · 웹 내보내기(index.pck 23.36MB) + 스모크 A~F + S + M 114항목 중 113 통과 — 실패 1건은 경로 C 도중 로컬 http 서버가 꺼졌다 다시 켜진 동안의 `net::ERR_FAILED` 2줄(브라우저 콘솔 에러 확인), 경로 C 만 다시 돌려 8 통과·콘솔 에러 0. 경로 M 9 통과.
