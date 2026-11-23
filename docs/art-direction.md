# 그림 방향 — 그림체·캐릭터·데스신 (버티컬 슬라이스)

- 기준: 2026-11-21 대화에서 사용자가 고르거나 승인한 것만 적는다. 제안만 된 것은 맨 아래 「미결·제안」에 따로 둔다.
- 그림은 ChatGPT(이미지 생성)로만 만든다. 손보정은 버티컬 슬라이스로 재미가 확인된 뒤 한참 후에.
- 시안 파일: `reference/style/`(그림체·캐릭터), `reference/deathscene/`(데스신)

## 1-0. 그림체 F 「펜 잉크 세 가지 색」 (2026-11-22 — D를 바꾸는 중, 에셋을 새로 뽑는 기준)
- 이유: D는 AI 티(고르게 정밀함·평균 미인형·세피아 필터)가 강하다는 사용자 판단. 여러 시안 끝에 이 그림체로 에셋을 뽑기 시작(사용자 지시 "이제 에셋 뽑아보자").
- **선**: 거친 펜 잉크 선. 힘 있게 한두 번에 긋고, 가끔 끊기며, 펜이 멈춘 곳에 작은 잉크 방울. 겹쳐 그은 선·빗금은 줄이고 가장 어두운 그림자에만 가볍게.
- **색**: 기본 세 가지 — 흑연 회색(갑옷·그림자) · 진홍(망토·리본·보석·실·피) · 크림(피부·붕대·밝은 부분). 인물마다 **강조색 하나**까지 허용(엘리안 짙은 초록, 노엘 와인빛 붉은 머리, 허리띠 같은 작은 갈색). 분홍·파스텔·홍조 없음, 그라데이션·광택 없음.
- **얼굴**: 차분한 눈, 작은 하이라이트, 홍조 없음. 애니풍이되 모에(처진 큰 눈·볼 홍조)는 피한다.
- **표절 주의**: 블랙소울즈2 느낌 금지 — 검붉은 바탕에 잉크 얼룩·흘러내림, 파스텔 채색+분홍 홍조, 디지털 연필 겹선, 처진 눈 모에 얼굴을 함께 쓰지 않는다.
- **양피지**는 인물 그림에 넣지 않고 화면 연출(카드 틀·대화창·데스신)에 쓴다.
- 기준 그림(첨부용): `reference/style/style_F_seraphina_stand.webp`(전신 스탠딩, 초록 바탕 — 통과본). 처음 시안 `style_F_seraphina_anchor.webp`(깨끗한 바탕)·`style_F_seraphina_parchment.webp`(양피지)는 **눈 밑 점이 양쪽에 있는 오류**가 있어 얼굴 참고로 쓰지 않는다.
- 새 그림체 원본은 `art/raw/vs_f/<번호>_<이름>.webp`(번호는 기존 `art/raw/vs/` 와 같게).
- 게임용 에셋은 **초록(#00FF00) 단색 바탕**으로 뽑는다(흰 바탕은 피부·붕대와 비슷해 잘라 내기 어렵다). 카메라는 눈높이.

## 1. 그림체 — D 「잔혹동화 그림책」 (확정 → 2026-11-22부터 F로 바꾸는 중)
- 섬세하고 살짝 거친 잉크 선 + 바랜 수채, 바랜 뼈색·회색·세피아. **선명한 색은 짙은 붉은색(crimson) 하나뿐.**
- 캐릭터 단독 그림(카드·스탠딩 시안)은 가시덤불과 작은 장미 테두리, 까마귀, 아래쪽 빈 리본 띠, 양피지 질감.
- 컷신·데스신은 테두리 없이 16:9 전체 화면.
- 기준 그림: `reference/style/style_D_seraphina_anchor.webp` — 새 그림을 뽑을 때마다 "그림체 참고용"으로 첨부한다.
- 비교했던 후보: A 예언서 필사본, B 동판화+붉은 잉크, C 아르누보 타로, E 잔혹동화×동판화×카드(`style_*`). D를 주 그림체로 골랐다.
- 얼굴은 애니메이션풍을 피한다. 비율은 자연스러운 성인 7.5등신(지나치게 가는 허리·큰 머리·인형 같은 얼굴 금지).

## 2. 공통 모티프
- **붉은 실**: 동료마다 손목에 붉은 실이 묶여 화면 밖으로 이어지고, 노엘은 손가락에 그 실들을 감아 쥔다(운명).
- 붉은색은 운명·피·각 캐릭터의 포인트(리본·망토·허리띠)에만.
- 세 동료는 머리색 명암으로 구분: 세라피나 은백 / 브룬힐드 칠흑 / 엘리안 금발. 노엘은 와인빛 붉은 머리.

## 3. 캐릭터 디자인 (확정 시안)
프롬프트에 그대로 넣을 수 있게 영어 묘사를 함께 둔다.

### 세라피나 — 용사 (기준 그림 `style_D_seraphina_anchor.webp`, 디자인 참고 `design_seraphina_v5_anime.webp`)
- 미녀 성기사. 은백색 판금 + 금 세공, 맨 허리(흉갑은 가슴 아래에서 끝남), **속옷 대신 붕대: 허리에서 엉덩이·사타구니를 지나 허벅지 맨 위까지(붕대 반바지처럼), 그 아래 허벅지는 맨살, 무릎 위부터 정강이 갑옷.** 목·팔·종아리에는 붕대 없음. **가슴에도 속옷처럼 붕대를 감았고, 흉갑 아래 가장자리로 살짝 보인다**(2026-11-22 사용자 결정).
- 긴 은발 땋은 머리 + 붉은 리본, 왼쪽 눈 밑 점, 쓸쓸한 미소. 붉은 망토·금 십자 앞자락, 날개 모양 금 코등이 + 붉은 보석 + 붉은 리본이 달린 성검.
- EN: Seraphina, a beautiful holy knight: silver-white plate armor with gold filigree, a bare waist (the breastplate ends below the chest), off-white bandages wrapped around her chest like an underwear wrap, peeking out just below the lower edge of the breastplate, off-white bandages wrapped from her waist over her hips to the very top of her thighs like short bandage shorts, bare mid-thighs, armored greaves from just above the knees; a long silver braid with a crimson ribbon bow, a small beauty mark under her left eye, a crimson cape and a crimson tabard with a gold cross, a sacred longsword with a winged gold guard, a red gem and a crimson ribbon.

### 브룬힐드 — 전사·방패 (`style_D_brunhild_v5.webp`)
- 흑기사 미녀, 파티에서 가장 큼. 칠흑 긴 생머리 + 일자 앞머리(히메컷), **여우상**(가늘게 올라간 눈, 호박색 눈동자, 능청스러운 반쯤 웃음), 오른쪽 눈 밑 가는 흉터.
- 검은 칠 판금 + 은색 들꽃·가시 세공(크고 매끈한 판, 장미 꽃잎 모양 견갑, 고딕 아치 흉갑, 드레스처럼 퍼지는 갑옷 치마), 붉은 견갑 안감·허리띠·스카프. 금 장식 없음.
- 거대한 검은 탑 방패에 **마른 들꽃 다발과 붉은 리본**을 묶고 다님(갑옷의 들꽃 세공과 같은 꽃). ~~허리에 메이스~~ → **무기는 방패 하나**(2026-11-22 사용자 결정 — 막고 되돌리는 역할, 공격도 방패로).
- EN: Brunhild, a tall black-knight beauty with long straight jet-black hair and blunt bangs (hime cut), narrow upturned fox-like amber eyes and a sly half-smile, a thin scar under her right eye; black lacquered plate armor with silver wildflower-and-thorn filigree, rose-petal pauldrons, a gothic arched breastplate, flaring armored skirt, crimson lining, sash and scarf; a massive black tower shield with a bouquet of dried wildflowers and a crimson ribbon tied to it; no other weapon (the shield is her only weapon).

### 엘리안 — 궁수 (`style_D_elian_v1.webp`)
- 엘프 귀족 궁수. **차갑고 기품 있는 무표정**(무례하거나 뚱한 얼굴이 아니라 왕비 초상화 같은 평온함).
- 금발 왕관 땋은 머리 + 흰 깃털·진주, 금 잎사귀 써클릿, 진주 귀걸이. 에메랄드 벨벳 망토 + 흰 털깃, 높은 레이스 깃, 아이보리 레이스 상의, 붉은 허리띠, 허벅지 중간까지 오는 짧은 레이스 치마, 무릎 위 부츠, 긴 장갑, 금박 상감 흰 활.
- ~~노래책에 파티 영웅담을 쓴다~~ → **설정 삭제**(사용자 결정).
- EN: Elian, an elven noble archer with a cold, dignified, serene expression; golden-blonde hair in a crown braid with white feathers and pearls, a gold leaf circlet, pearl earrings; a deep emerald velvet cloak with a white fur collar, a high lace collar, an ivory lace bodice, a crimson sash, a short layered lace skirt to mid-thigh, over-the-knee boots, long gloves; a white longbow with gold inlay.

### 노엘 — 마녀·주인공 (`style_D_noel_v1.webp`)
- **머리색을 흑발에서 와인빛 붉은 긴 머리로 바꿈**(브룬힐드와 겹치지 않게, 운명을 쥔 사람으로 읽히게). 붉은 눈, 눈물이 맺힌 참는 슬픔.
- 챙 넓은 마녀 모자 + 붉은 리본 띠 + 꽂힌 카드 석 장. 어깨가 드러나는 코르셋 + 레이스 초커와 카메오, 위팔에서 시작하는 찢어진 종 모양 소매, 앞은 무릎 길이에 옆트임 치마, 레이스 스타킹, 뒤로 퍼지는 아주 얇은 검은 시폰 망토(실루엣으로 위엄). 카드 묶음은 허리에.
- 한 손에 카드 부채, 다른 손 **손가락마다 붉은 실을 감아** 세 방향으로 뻗음.
- EN: Noel, a beautiful witch with long wine-red hair and crimson eyes glistening with held-back tears; a wide-brimmed black witch hat with a crimson ribbon band and three old cards tucked into it; an off-the-shoulder black corset with a lace choker and cameo, detached tattered bell sleeves, a knee-length skirt with a side slit, black lace stockings, a very thin sheer black chiffon cloak flowing behind her; a bundle of old cards at her hip; a fan of cards in one hand, crimson threads wound around the fingers of the other.

## 4. 데스신
### 수위 기준 — 잔혹동화 수준 (확정)
- 피는 보여 준다(흐름·튀김·웅덩이). 관통·상처는 방패·그림자·뒷모습·화면 밖으로 암시. 몸이 뚫린 단면·장기는 그리지 않는다.
- 감정 컷(얼굴·손·유품)은 피를 줄이고 슬픔에 집중.
- **폭력과 노출을 섞지 않는다**: 죽음 장면은 선정적 구도 금지(스팀 결제사 규정 위험 회피). 붕대·맨살 디자인은 평소 그림에서만 살리고 데스신에서 강조하지 않는다.
- 스팀: 콘텐츠 설문에 폭력·고어를 정직하게 표시하면 판매 가능(2025년 7월 결제사 규정은 성적 콘텐츠 대상). 국내 판매는 게임물관리위원회 등급분류를 따로 받아야 할 가능성이 큼(밸브는 최신 보도 기준 자체등급분류사업자 아님) — 출시 시점에 재확인.

### 세라피나 데스신 — 세 번 밟힘 (확정, `reference/deathscene/seraphina_*`)
| 컷 | 그림 | 게임 연출(코드) |
|---|---|---|
| C1 마지막 말 | 노엘을 돌아보며 웃음, 머리 위로 거대한 발(발가락이 카메라 쪽) | |
| C2 손을 뻗음 | 웃음이 굳고 그림자가 눈을 덮음, 노엘 쪽으로 손 | |
| — | 첫 번째 밟힘 | 흰 섬광·흔들림 |
| C3a 첫 번째 밟힘 | 발 옆에 쓰러짐, 오른팔이 발밑, 부러진 성검 | |
| C3b "가." | 엎드려 남은 손을 노엘에게 뻗음(대사 [임시] "노엘… 가.") | |
| — | 두 번째 밟힘 | 섬광·흔들림·화면에 피 튐 |
| C4 마지막 밟힘 | **C3b와 같은 카메라**, 발가락 밑에 남은 손 | 발이 비틀며 짓누름 |
| C6 발이 들린 뒤 | **C4와 같은 카메라**, 발자국 안 납작하게 찢긴 망토, 발가락 자국에 고인 피, 오른쪽에 남은 하체, 손 | 피 웅덩이 번짐 |
- 거대 존재는 발만 보인다(사람 모양 발, 갈라진 회색 돌 같은 피부, 자연스러운 발가락).
- 앞으로의 데스신도 "같은 카메라로 직전 → 순간 → 직후"를 이어 가는 구성이 효과적이었다.

### 브룬힐드 데스신 — 관통 (시안 단계, `reference/deathscene/brunhild_*`)
- 통과한 컷: 첫 일격(W2b), 방패를 뚫은 창 + 벽 그림자(W2), 여러 창 관통 + 그림자(W3), 무릎 꿇은 뒷모습 + 피 웅덩이의 들꽃(back_kneel), 마지막으로 돌아보는 얼굴(last_look), 거대한 창 그림자극(great_spear v1·v2).
- 막힌 것: 창이 몸을 직접 뚫고 나오는 모든 구도(얼굴 보임·뒷모습·실루엣·목 아래만 포함). 장소는 '지붕이 무너져 달빛이 드는 폐허 성당'으로 나오는 경향 → 그대로 쓰기로 함.

## 5. ChatGPT로 뽑는 요령 (이번 작업에서 확인된 것)
- 거절되면 **새 대화창**에서 다시. 거절이 쌓인 대화창은 더 엄격해진다. 같은 프롬프트도 새 대화창에서 통과한 적이 있다.
- 피투성이 컷은 참고 그림으로 첨부하지 않는다(판정이 엄격해짐).
- 구도를 유지하려면 새로 그리게 하지 말고 **직전 컷을 첨부해 "Edit this image"로 바꿀 부분만** 지시한다(C3b→C4→C6이 이 방법으로 맞음).
- 수정을 여러 번 거치면 얼굴·비율이 무너진다 → 2~3번 넘으면 처음부터 새로 뽑기.
- '도도함'은 반쯤 감은 눈·곁눈질로 그려져 무례해 보인다 → '맑게 뜬 눈, 평온함, 왕비 초상화'로 지시.
- '도자기 인형·큰 눈·작은 입술'은 얼굴을 어리게, 허리를 기괴하게 가늘게 만든다 → 쓰지 않는다.
- 피는 "crimson, like spilled red ink"로, 수위 낮출 때는 "No gore"를 붙인다.
- 프롬프트는 채팅에서 **코드 블록**으로 준다(복사 버튼으로 한 번에 복사).

## 5-1. 그림 검수 체크리스트 (2026-11-22 사용자 지시: 디테일까지 꼼꼼히)
결과 그림을 받을 때마다 기준 그림·캐릭터 시안과 **부위별로 나란히 비교**하고, 아래를 하나씩 확인해 결과를 보고한다.
1. **옷의 앞뒤 논리**: 앞면에만 있어야 할 것(앞자락 십자가·문장·단추·여밈)이 뒤에 그대로 붙지 않았는지. 뒤에서 보이면 안 되는 것·보여야 하는 것(뒤판·망토 안쪽·등 갑옷).
1-1. **뒷모습**: 무릎·발끝·손등이 향하는 방향(뒤에서는 무릎 덮개가 아니라 종아리·무릎 뒤), 겹침 순서(망토는 몸보다 카메라 쪽 — 다리·몸이 망토 위에 그려지면 틀림), 앞모습 기준 그림의 디테일이 뒤로 옮겨 그려지지 않았는지.
1-2. **프롬프트를 쓰기 전에도**: 시안에서 장식(매듭·리본·끈·꽃다발)이 몸 앞뒤 어디에 붙었는지, 옷 길이(치마·망토·스카프가 어디까지 내려오는지), 앞뒤가 같은 부분(방패 테두리 등)의 색을 먼저 확인하고 쓴다(2026-11-22: 브룬힐드 뒷모습 프롬프트에 허리띠 매듭을 등에, 치마를 무릎 위로 잘못 써서 그대로 그려짐). 초록 배경일 때 초록이 들어가는 소품(줄기·잎)은 시안 색으로 명시한다.
2. **좌우**: 무기를 든 손, 방패 팔, 흉터·점·장식의 좌우가 시안과 같은지(뒷모습은 화면 좌우가 몸 좌우와 같다).
3. **디자인 요소 빠짐·더함**: 리본·실·보석·꽃다발·장신구·붕대 범위(세라피나: 허리~허벅지 맨 위만)·갑옷 경계가 시안과 같은지. 시안에 없는 것이 생기지 않았는지.
4. **노출 범위**: 시안보다 넓거나 좁지 않은지, 데스신·전투에서 선정적 구도가 아닌지.
5. **비율·해부**: 머리 대 몸(약 7.5등신), 허리 굵기, 손가락 수·관절, 팔다리 길이, 무기 잡는 방향.
6. **프롬프트 지시 반영**: 카메라 높이·각도, 자세, 표정, 화면 비율, 여백.
7. **그림체**: 잉크 선 + 바랜 수채, 선명한 색은 붉은색뿐, 애니메이션풍으로 흐르지 않았는지.
7-1. **반투명 옷**: 초록·마젠타 배경 위의 시폰·레이스·소매가 배경색으로 물들지 않았는지(색이 섞이면 배경 제거로 안 지워짐 — 밝은 바탕에 얹어 확인).
8. **게임에 쓸 수 있는지**: 배경 단색이 고른지(`tools/remove_bg.py`로 지워 어두운 바탕에 얹어 확인), 잘린 곳·글자·워터마크.
- 하나라도 어긋나면 "통과"라고 하지 않고, 고칠 곳과 수정 프롬프트를 함께 준다.
- 같은 그림을 2번 넘게 고쳐도 어긋나면 수정을 멈추고, 프롬프트를 다시 써서 새 대화창에서 처음부터 뽑는다.

## 6. 미결·제안 (결정 아님)
- 죽음 카드만 E(붉은 잉크 동판화)로 그려 세계(D)와 구분하는 안.
- 엘리안의 성격을 '도도한 귀족'으로 대본에서 바꿀지(외형은 확정, 대본은 아직 밝은 분위기 메이커).
- 캐릭터 단독 그림의 배경을 캐릭터별로 바꿀지(지금은 셋 다 달·폐허·까마귀가 거의 같음).
- 세라피나 시안(D 기준 그림)은 허리가 지나치게 가늘어 정식으로 뽑을 때 다른 셋과 비율을 맞춰야 함.
- 전투 화면 뒷모습을 이 그림체로 시험하는 일. (탑뷰 도트 변환은 2026-11-21 탑뷰를 없애 해당 없음)
- 브룬힐드 데스신 컷 구성 확정, 창끝을 게임에서 겹쳐 그리는 방법.
