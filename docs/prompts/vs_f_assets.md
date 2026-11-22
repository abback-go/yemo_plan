# 그림체 F 그림 목록·프롬프트 — 1층 데모 (새 전투 포함)

- 작성: 2026-11-23 새벽(밤샘 계획 2 E). 근거: 그림체 F [`../art-direction.md`](../art-direction.md) 1-0장 · 캐릭터 3장 · 데스신 수위 4장 · 요령 5장 · 검수 5-1 · 대본 [`../tutorial-script-vs.md`](../tutorial-script-vs.md) v3 · 새 전투 [`../battle-v2-spec.md`](../battle-v2-spec.md) · 옛 D 프롬프트 [`vs_assets.md`](vs_assets.md)·[`vs_assets_rest.md`](vs_assets_rest.md)(장면·구도는 여기서 살림).
- **받는 순서는 [`../art-todo.md`](../art-todo.md) 맨 위 표.** 이 문서는 목록(1장)과 번호별 프롬프트(2~8장)만 둔다.
- 주는 방식·받은 뒤 절차(검수 → 저장 → 반영)는 `art-todo.md` 「참고(그림체 D)」 0장과 같다. 저장 폴더만 `art/raw/vs_f/`.
- 카드 목록은 2026-11-22 밤 기준 새 전투 덱(`game/data/battle_v2_data.gd`) + 1층 방에서 얻는 카드로 잡았다. 1층 통합(밤샘 A·B)이 끝난 뒤 안 쓰는 카드가 생기면 그 줄만 '나중'으로 옮긴다.

## 0. 공통

### 첨부 파일
링크 앞부분 `https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/` (로그인 필요). 블록마다 다시 적는다.
- 그림체 기준: [`reference/style/style_F_seraphina_stand.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/reference/style/style_F_seraphina_stand.webp) (= 세라피나 F)
- F 통과본: [`28`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs_f/28_stand_seraphina_calm.webp) · [`32`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs_f/32_stand_brunhild_smirk.webp) · [`36`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs_f/36_stand_elian_cold.webp) · [`39`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs_f/39_stand_noel.webp) · [`76 카드 틀`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs_f/76_card_frames.webp) · [`79 오른손`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs_f/79_hand_right_idle.webp) · [`81 가리키기`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs_f/81_hand_right_point.webp)
- 옛 D 원본(구도·장소): `art/raw/vs/<번호>_*.webp` · 데스신 `reference/deathscene/seraphina_*.webp` · 손 자리 `art/raw/vs/ref/09_ref_*_green.png`

### 첨부 규칙
| 종류 | 첫째 | 둘째 | 이유 |
|---|---|---|---|
| 동료·노엘이 나오는 새 그림(컷인·아이) | 그림체 기준 | 그 인물의 F 통과본(세라피나는 30 F, 아이는 D 43) | 한 장만 쓰면 얼굴이 달라진다. F 기본 그림을 만들 때는 둘째가 D 스탠딩이었다 — 이제 F 통과본이 있어 그것을 쓴다(얼굴이 어긋나면 D 스탠딩을 셋째로) |
| 데스신 C1·C2·C3b | 그림체 기준(= 세라피나 F) | 옛 D 컷(구도) | 나머지 컷은 직전 F 컷을 고친다(5장) |
| 표정·수정·손짓 | 고칠 F 그림 한 장 | — | "Edit this image" 형식. 표정은 **늘 기본 그림에서** 고친다(33→34처럼 이어 고치면 얼굴이 무너진다) |
| 배경·CG·카드 다시 뽑기 | 그림체 기준 | 옛 D 그림(장소·구도) | D의 수채·세피아는 따르지 말라고 프롬프트에 적었다 |
| 노엘의 손 80·89 | 옛 손 자리 그림(손 위치·카드 틈) | F 손(81) | 게임 코드가 손 그림 속 카드 자리를 쓴다 |
| UI | 76 카드 틀(재료) | 옛 D UI(배치, 있으면) | 탁자·틀과 같은 재료(뼈·녹·가시·마른 피) |

### 대화창
| 이름 | 무엇을 | 시작 |
|---|---|---|
| A 브룬힐드 | 32 수정 → 33~35 → 63 | 32를 뽑던 대화창(없으면 새 대화창) |
| B 세라피나 | 29·30 → 61 → 31 | 28을 뽑던 대화창(없으면 새) |
| C 엘리안 | 37·38 → 62 | 36을 뽑던 대화창(없으면 새) |
| D 손 | 80 → 89 → 91~94 | 78~81을 뽑던 대화창(없으면 새) |
| E 배경 | 15·16·07·17·18·20~27 | 새 |
| F 가장 깊은 곳 | 19 → 90 → 83~88 | 새 (피 있는 컷이 뒤에 오게) |
| G 카드 | 60 → 44~59 · 95 | 새 |
| H UI | 66 → 72·73·69~71 · 68·96·67 | 새 |
| I 아이 · J 노엘 · K 타이틀 | 43 · 64·65 · 74 | 새 · 39를 뽑던 대화창(없으면 새) · 새 |
- 거절되면 새 대화창에서 같은 첨부·같은 프롬프트. 같은 그림을 2번 고쳐도 어긋나면 새 대화창에서 처음부터(`art-direction.md` 5장).

### 검수 — 5-1 체크리스트 + 그림체 F에서 더 볼 것
1. 블랙소울즈2 느낌 4가지(검붉은 바탕에 잉크 얼룩·흘러내림 / 파스텔·분홍 홍조 / 디지털 연필 겹선 / 처진 눈 모에)가 **함께** 나오지 않았는지.
2. 색: 흑연 회색·진홍·크림 + 인물 강조색 하나(엘리안 짙은 초록, 노엘 와인빛 머리, 작은 갈색). 그라데이션·광택·세피아 수채가 남지 않았는지.
3. 세라피나: 왼쪽 눈 밑 점 **하나**, 가슴 붕대가 흉갑 아래로 살짝. 브룬힐드: 무기는 **방패 하나**, 흉터는 **회색 가는 선**. 붉은 실은 **노엘의 오른손에만**(동료 손목에 새로 생기지 않았는지).
4. 어둡고 잔혹한 톤이 탁자(75)·카드 틀(76)과 맞는지(마른 피·녹·가시는 겉 디테일로만).
5. 초록 바탕은 고른지, 레이스·소매에 초록이 비치지 않는지(밝은 바탕에 얹어 확인).

### 반영 메모 (개발 — 그림을 받은 뒤)
- 배경·CG·스탠딩·데스신: `tools/vs_import.py` 원본 폴더를 `art/raw/vs_f/`로(이름은 D와 같게 저장한다). VN 스탠딩은 **한 인물의 표정이 모두 F로 모였을 때** 그 인물을 한꺼번에 바꾸고 `faces`·`expressions.crop` 얼굴 자리를 다시 잰다. 데스신 83~88 → `cut_hero_c*.webp` 대응 새로.
- 카드 그림은 F부터 **세로 2:3**(D는 1:1) → `card_art_*` 만드는 곳을 2:3에 맞춘다. 90 거대한 발은 `battle_v2_data.gd` `enemies` 에 `art`·`face` 상자 새로.
- 손: 80 은 `vs_f_import.py` 가 찾는 이름 그대로. 캔버스를 16:9(1672×941)로 받으면 `HAND_W` 로 줄일 때 `pinch.quad`·`omen` 값도 같은 배율로. 89 는 `layout.hand`(imgL·imgR·splitX·slots) 그대로 쓰려고 옛 손 자리를 지켰다. 91~94 손짓·72·73·96·69~71 UI는 반영 코드를 새로 짠다.

---

## 1. 목록
우선순위: **꼭** = 데모에 꼭(정해진 길·자주 보임·1층 VN은 D와 섞이면 튐) · **좋음** = 있으면 좋음 · **나중**.

### (a) 이미 있는 것 — F 통과본 (13)
| 번호 | 이름 | 쓰는 곳 | 게임 반영 |
|---|---|---|---|
| 08 | 광신도 | 새 전투 적 카드 | `f_spr_cultist` 반영됨 |
| 28 | 세라피나 기본 | 전투 초상 · VN | 전투 초상만(`f_bust_hero`). VN은 아직 D |
| 32 | 브룬힐드 기본 | 전투 초상 · VN | 전투 초상만. **임시 통과 — 흉터 빨강 → (c) 32 수정** |
| 36 | 엘리안 기본 | 전투 초상 · VN | 전투 초상만 |
| 39 | 노엘 기본 | VN | 아직 반영 안 됨(VN은 D 1차본 `stand_witch`) |
| 40 | 무덤지기 | 새 전투 강적 | `f_spr_gravekeeper` 반영됨 |
| 75 | 전투 돌판 탁자 v2 | 새 전투 탁자 | 반영됨 |
| 76 | 카드 틀 3종 v2 | 모든 카드 | 반영됨 |
| 77 | 해골 병사 | 무덤지기 하수인 | 반영됨 |
| 78 | 왼손(편 손) | 손패 뒤 | 반영됨 |
| 79 | 오른손 평소 | 전투 오른쪽 아래 | 반영됨 |
| 81 | 오른손 가리키기 | 대상 가리키기 | 넣는 중(밤샘 D-2) |
| 82 | 카드 뒷면 | 덱·뒤집힌 카드 | 넣는 중(밤샘 D-2) |

### (b) 옛 그림체 D를 F로 다시 뽑을 것 (60)
| 번호 | 이름 | 쓰는 곳 | 우선 | 지금 대신 |
|---|---|---|---|---|
| [07](#07-장례-회랑) | 장례 회랑 | VN 회랑 · 전투 ① 탁자 너머 | 꼭 | D 07 |
| [15](#15-곁방) | 곁방(캠프) | 첫 VN 장면 | 꼭 | D 15 |
| [16](#16-빈-곁방) | 빈 곁방 | 층의 끝 | 꼭 | D 16 |
| [17](#17-안치-홀) | 안치 홀 | 지도를 여는 곳 | 꼭 | D 17 |
| [18](#18-계단-앞-홀) | 계단 앞 홀 | 정해진 길 | 꼭 | D 18(계단이 위로 보이는 문제도 함께 고침) |
| [19](#19-가장-깊은-곳) | 가장 깊은 곳 | VN · 층 끝 전투 · **타이틀 배경** | 꼭 | D 19 |
| [20](#20-광신도-기도실) | 광신도 기도실 | VN · 전투 | 꼭 | D 20 |
| [21](#21-무덤지기의-방) | 무덤지기의 방 | VN · 강적 전투 | 꼭 | D 21 |
| [22](#22-순장된-자의-방) | 순장된 자의 방 | 사건 | 꼭 | D 22 |
| [23](#23-핏자국-통로-끝-cg) | 핏자국 통로 끝(죽은 마녀 CG) | 사건 | 꼭 | D 23 |
| [24](#24-촛불-예배당) | 촛불 예배당 | 휴식 | 꼭 | D 24 |
| [25](#25-무너진-훈련장) | 무너진 훈련장 | 훈련 | 꼭 | D 25 |
| [26](#26-묘지기의-좌판-cg) | 묘지기의 좌판(CG) | 거래 | 꼭 | D 26 |
| [27](#27-발자국-방) | 발자국 방 | 전조 | 꼭 | D 27(발가락 수 어긋남) |
| [29](#29-세라피나-smile) | 세라피나 smile | VN | 꼭 | D 29 |
| [30](#30-세라피나-determined) | 세라피나 determined | VN · 61 컷인 얼굴 | 꼭 | D 30 |
| [31](#31-세라피나-shocked) | 세라피나 shocked | VN에서 안 씀 → 전투 초상 놀람만 | 좋음(선택) | 붉은 테두리·흔들림 |
| [33](#33-브룬힐드-stern) | 브룬힐드 stern | VN | 꼭 | D 33 |
| [34](#34-브룬힐드-shocked) | 브룬힐드 shocked | VN(5.1·5.2) · 전투 초상 놀람 | 꼭 | D 34 |
| [35](#35-브룬힐드-grief) | 브룬힐드 grief | VN(5.4·6) | 꼭 | D 35 |
| [37](#37-엘리안-shocked) | 엘리안 shocked | VN(3.3·3.4·5) · 전투 초상 놀람 | 꼭 | D 37 |
| [38](#38-엘리안-grief) | 엘리안 grief | VN(5.4·6) | 꼭 | D 38 |
| [43](#43-아이) | 아이(순장된 자) | 사건 스탠딩 | 꼭 | D 43 |
| [83](#83-데스신-c1-마지막-말) | 데스신 C1 마지막 말 | 세라피나 데스신 | 꼭 | D `cut_hero_c1` |
| [84](#84-데스신-c2-손을-뻗음) | 데스신 C2 손을 뻗음 | 〃 | 꼭 | D c2 |
| [85](#85-데스신-c3a-첫-번째-밟힘) | 데스신 C3a 첫 번째 밟힘 | 〃 | 꼭 | D c3a |
| [86](#86-데스신-c3b-가) | 데스신 C3b "가." | 〃 | 꼭 | D c3b |
| [87](#87-데스신-c4-마지막-밟힘) | 데스신 C4 마지막 밟힘 | 〃 | 꼭 | D c4 |
| [88](#88-데스신-c6-발이-들린-뒤) | 데스신 C6 발이 들린 뒤 | 〃 | 꼭 | D c6 |
| [44](#44-성검-베기) | 성검 베기 | 카드 「성검 베기」·「베기」(어둡게) | 좋음 | D 44 (사용자 결정: 행동 카드는 당분간 D) |
| [45](#45-선봉) | 선봉 | 옛 전투만(새 덱에 없음) | 나중 | D 45 1차 |
| [46](#46-감싸기) | 감싸기 | 옛 전투만(새 덱에서 뺌) | 나중 | D 46 1차 |
| [47](#47-방패-강타) | 방패 강타 | 「되돌리기」 | 좋음 | D 47 1차 |
| [48](#48-저격) | 저격 | 「저격」 | 좋음 | D 48 1차 |
| [49](#49-견제-사격) | 견제 사격 | 「겨누기」 | 좋음 | D 49 1차 |
| [50](#50-저주의-불꽃) | 저주의 불꽃 | 「저주」(어둡게) | 좋음 | D 50 1차 |
| [51](#51-운명-전가) | 운명 전가 | 「운명 전가」 | 좋음 | D 51 1차 |
| [52](#52-대신-받기) | 대신 받기 | 「막기」 | 좋음 | D 52 1차 |
| [53](#53-죽음의-예지) | 죽음의 예지 | 「취약」 | 좋음 | D 53 1차 |
| [54](#54-상처) | 상처 | 쓰러진 동료의 상처 카드(새 전투에서 쓸지 미정) | 좋음 | D 54 |
| [55](#55-짓밟힘) | 짓밟힘 | 상속 카드(데스신 뒤) | 좋음 | D 55 1차(발가락 6개) |
| [56](#56-부러진-성검) | 부러진 성검 | 세라피나 유품 | 좋음 | D 56 |
| [57](#57-용사의-마지막-돌격) | 용사의 마지막 돌격 | 세라피나 유품 | 좋음 | D 57 |
| [58](#58-이름-없는-마녀의-카드) | 이름 없는 마녀의 카드 | 시체 방 보상 · 「운명 찢기」 | 좋음 | D 58 |
| [59](#59-작은-손의-부적) | 작은 손의 부적 | 사건 보상 | 좋음 | D 59 |
| [60](#60-용사의-죽음) | 용사의 죽음 | 「세라피나의 죽음」 죽음 카드(핵심 장면) | 꼭 | D 60 1차(그림자가 발로 안 읽힘) |
| [61](#61-컷인-성검-베기) | 컷인 성검 베기 | 대표 카드 컷인 | 좋음 | 새 전투엔 컷인 없음(옛 전투는 D 이전 그림) |
| [62](#62-컷인-저격) | 컷인 저격 | 〃 | 좋음 | 〃 |
| [63](#63-컷인-감싸기) | 컷인 감싸기 | 〃(브룬힐드 막기·되돌리기) | 좋음 | 〃 |
| [64](#64-컷인-저주의-불꽃) | 컷인 저주의 불꽃 | 〃 | 좋음 | 〃 |
| [65](#65-컷인-짓밟힘) | 컷인 짓밟힘 | 〃 | 좋음 | 〃 |
| [66](#66-대화창) | 대화창 | VN 모든 대사 · 타이틀 단추 띠 | 꼭 | D 66 |
| [67](#67-이름표) | 이름표 | VN | 나중(사용자 결정 대기 — 생략 추천) | 대화창 안 붉은 글자 |
| [68](#68-선택지-버튼) | 선택지 버튼 | VN 선택(사건·거래) | 좋음 | 코드 도형 |
| [69](#69-지도-바탕) | 지도 바탕 | 지도(방 사이마다) | 꼭 | 코드 어두운 판 |
| [70](#70-지도-아이콘) | 지도 아이콘 11종 | 지도 | 꼭 | 코드 아이콘 |
| [71](#71-랜턴-촛불) | 랜턴 촛불 | 지도 오른쪽 칸 | 꼭 | 코드 촛불 |
| [72](#72-턴-끝) | 턴 끝 | 새 전투 늘 보임 | 꼭 | 코드 「턴 끝」 |
| [73](#73-행동-에너지) | 행동 에너지(켜짐·꺼짐) | 새 전투 늘 보임 | 꼭 | 코드 붉은 보석 |
| [74](#74-타이틀) | 타이틀 | 첫 화면 | 나중(이야기·로고 뒤) | 19 D 어둡게 + 글자 |

### (c) 새로 필요한 것 (10)
| 번호 | 이름 | 쓰는 곳 | 우선 | 지금 대신 |
|---|---|---|---|---|
| [32](#32-브룬힐드-흉터-수정) | 브룬힐드 흉터 수정 | 전투 초상(늘 보임) · 33~35의 바탕 | 꼭 | 32 F(빨간 흉터) |
| [80](#80-오른손-카드-집기) | 오른손 카드 집기 | 카드를 끌 때마다 · VN 죽음 카드 암시(곁방·계단·빈 곁방) | 꼭 | D 세운 손(`ui_witch_hand_raise`) |
| [89](#89-두-손-손패) | 두 손이 다섯 장을 쥔 손패 | 손패 당겨 보기(탭할 때마다) | 꼭 | D 두 손(`ui_witch_hand_left/right`, 초록 물듦 지움) |
| [90](#90-거대한-발-카드) | 거대한 발 카드 | 가장 깊은 곳 보스 적 카드 · 작은 얼굴 | 꼭 | 없음(D 41 스프라이트를 잘라 쓰거나 코드) |
| [91](#91-손짓-축복) | 손짓 — 축복(손바닥 펴기) | 「축복」 낼 때 | 좋음 | 없음(81 가리키기) |
| [92](#92-손짓-저주) | 손짓 — 저주·취약(갈퀴 손) | 「저주」·「취약」 | 좋음 | 〃 |
| [93](#93-손짓-실-당기기) | 손짓 — 실 당기기 | 「운명 전가」 | 좋음 | 〃 |
| [94](#94-손짓-손가락-튕기기) | 손짓 — 손가락 튕기기 | 「턴 끝」 | 좋음 | 〃 |
| [95](#95-축복-카드) | 축복 카드 그림 | 「축복」 | 좋음 | 코드 빛살 |
| [96](#96-hp-봉인) | HP 봉인(동료 진홍·적 검정) | 모든 동료·적 카드, 노엘 HP | 좋음 | 코드 봉인 |
| — | 전투 초상 놀란 얼굴 | 노려진 동료 | 좋음(선택 — 사용자가 일단 뺌) | 새 그림 없이 31·34·37 F에서 잘라 씀 |

### 새 전투에서 안 쓰는 D 그림 (다시 뽑지 않음)
01·04·05·06 뒷모습·부위(옛 전투 `?battle=v1`만) · 09 손(→ 78·79·80·81·89) · 10 카드 틀(→ 76) · 11 카드 뒷면(→ 82) · 12 예고 아이콘(옛 전투만) · 41 거대한 발 스프라이트(→ 90) · 42 묘지기(26 CG 안에).

### 나중 — 2·3층 (목록만)
- 브룬힐드 데스신(관통 — 통과 구도는 `art-direction.md` 4장, 시안 `reference/deathscene/brunhild_*`) · 엘리안 데스신 · 죽음 카드 「전사의 죽음」(1층 빈 곁방 끝에 흐리게 잠깐 보임)·「궁수의 죽음」.
- 상속 「꿰뚫린 방패」·「타버린 활」, 유품(브룬힐드·엘리안), 「흉터」 카드 · 적 창 기사·화형 사제 · 2·3층 배경(`bg_cathedral`·`bg_ossuary`·`bg_stairs_descent`·`bg_fork_crypt`·`bg_pyre_court`) — 모두 지금은 D 이전 옛 그림.

### 개수
- (a) 13 · (b) 60 · (c) 10(+ 그림 없는 1줄).
- 우선순위(b·c 70장): **꼭 39** · 좋음 27 · 나중 4.

---

## 2. 스탠딩 수정·표정
표정은 모두 **기본 그림 한 장을 고친다**(이어 고치지 않는다).

### 32 브룬힐드 흉터 수정
- 첨부: [`32_stand_brunhild_smirk.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs_f/32_stand_brunhild_smirk.webp)(F 임시 통과본) 한 장 · 대화창 A
```
Edit this image. Keep everything exactly the same — her face, expression, hair, armor, shield, the dried flowers, the crimson ribbons, her pose, the colors, the line style and the plain flat pure green (#00FF00) background. Change only the scar under her right eye: keep its shape as one thin straight line, but draw it in pale light-gray ink instead of red. There is no red anywhere on her face.
```
- 저장: `art/raw/vs_f/32_stand_brunhild_smirk.webp` (지금 파일은 `32_stand_brunhild_smirk_v1.webp` 로 이름을 바꿔 남긴다)
- 검수: 흉터가 오른쪽 눈 밑(화면 왼쪽)에 회색 가는 선 하나 · 1차본과 나란히 놓고 얼굴·표정이 그대로인지.

### 33 브룬힐드 stern
- 첨부: 32 수정본 한 장 · 대화창 A
```
Edit this image. Keep everything exactly the same — her face shape, hair, the thin pale-gray scar under her right eye, armor, shield, flowers, ribbons, pose, colors, line style and the plain flat pure green (#00FF00) background. Change only her facial expression to a stern, serious look: no smile, brows slightly lowered, mouth set in a straight line. No blush.
```
- 저장: `art/raw/vs_f/33_stand_brunhild_stern.webp` · 검수: 표정 말고 바뀐 곳이 없는지(흉터 색 포함).

### 34 브룬힐드 shocked
- 첨부: 32 수정본 한 장 · 대화창 A
```
Edit this image. Keep everything exactly the same — her face shape, hair, the thin pale-gray scar under her right eye, armor, shield, flowers, ribbons, pose, colors, line style and the plain flat pure green (#00FF00) background. Change only her facial expression to a shocked look: eyes wide open, brows raised, lips parted. No blush.
```
- 저장: `art/raw/vs_f/34_stand_brunhild_shocked.webp` · 검수: 눈이 모에처럼 커지거나 처지지 않았는지.

### 35 브룬힐드 grief
- 첨부: 32 수정본 한 장 · 대화창 A
```
Edit this image. Keep everything exactly the same — her face shape, hair, the thin pale-gray scar under her right eye, armor, shield, flowers, ribbons, pose, colors, line style and the plain flat pure green (#00FF00) background. Change only her facial expression to grief: eyes lowered, brows drawn together, jaw clenched, holding back tears without letting them fall. No blush.
```
- 저장: `art/raw/vs_f/35_stand_brunhild_grief.webp` · 검수: 눈물이 흉터 쪽에 붉게 번지지 않았는지.

### 29 세라피나 smile
- 첨부: [`28_stand_seraphina_calm.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs_f/28_stand_seraphina_calm.webp) 한 장 · 대화창 B
```
Edit this image. Keep everything exactly the same — her face shape, the single small beauty mark under her left eye, her hair, braid and crimson ribbon, armor, bandages, cape, sword, pose, colors, line style and the plain flat pure green (#00FF00) background. Change only her facial expression to a warm, gentle smile with relaxed eyes. No blush.
```
- 저장: `art/raw/vs_f/29_stand_seraphina_smile.webp` · 검수: 점이 하나(왼쪽 눈 밑)인지.

### 30 세라피나 determined
- 첨부: 28 F 한 장 · 대화창 B
```
Edit this image. Keep everything exactly the same — her face shape, the single small beauty mark under her left eye, her hair, braid and crimson ribbon, armor, bandages, cape, sword, pose, colors, line style and the plain flat pure green (#00FF00) background. Change only her facial expression to a determined, focused look: brows lowered, eyes steady, lips pressed together. No blush.
```
- 저장: `art/raw/vs_f/30_stand_seraphina_determined.webp` · 검수: 점 하나 · 화난 얼굴이 아니라 결의.

### 31 세라피나 shocked
- 선택(VN 대본에서 안 씀 — 전투 초상 놀람용). 첨부: 28 F 한 장 · 대화창 B
```
Edit this image. Keep everything exactly the same — her face shape, the single small beauty mark under her left eye, her hair, braid and crimson ribbon, armor, bandages, cape, sword, pose, colors, line style and the plain flat pure green (#00FF00) background. Change only her facial expression to a shocked look: eyes wide, lips parted. No blush.
```
- 저장: `art/raw/vs_f/31_stand_seraphina_shocked.webp` · 검수: 점 하나 · 얼굴~가슴만 잘라도 놀람이 읽히는지.

### 37 엘리안 shocked
- 첨부: [`36_stand_elian_cold.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs_f/36_stand_elian_cold.webp) 한 장 · 대화창 C
```
Edit this image. Keep everything exactly the same — her face shape, hair, circlet, feathers and pearls, the lace, the cloak, the sash, the bow, her pose, colors, line style and the plain flat pure green (#00FF00) background. Change only her facial expression to a shocked look: eyes wide open, lips parted, still dignified. No blush.
```
- 저장: `art/raw/vs_f/37_stand_elian_shocked.webp` · 검수: 몸·옷이 36과 겹쳐 같은지(D 37은 몸이 3% 달랐다).

### 38 엘리안 grief
- 첨부: 36 F 한 장 · 대화창 C
```
Edit this image. Keep everything exactly the same — her face shape, hair, circlet, feathers and pearls, the lace, the cloak, the sash, the bow, her pose, colors, line style and the plain flat pure green (#00FF00) background. Change only her facial expression to grief: brows drawn together, eyes glistening with held-back tears, lips trembling. No blush.
```
- 저장: `art/raw/vs_f/38_stand_elian_grief.webp` · 검수: 볼 홍조·분홍이 생기지 않았는지.

---

## 3. 노엘의 손
붉은 실은 **오른손에만, 손가락 길이만큼 짧게**(동료로 이어지는 긴 실은 코드가 그린다).

### 80 오른손 카드 집기
- 첨부: ① [`09_ref_hand_raise_green.png`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/ref/09_ref_hand_raise_green.png)(손 자세·카드 틈을 지킬 그림) · ② [`81_hand_right_point.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs_f/81_hand_right_point.webp)(F 손) · 대화창 D
```
Redraw the first attached image in the art style and costume of the second attached image. This is the witch Noel's own right hand, seen in first person, raised to hold up a game card.

KEEP EXACTLY THE SAME AS THE FIRST IMAGE
The canvas size and 16:9 proportions, the position, size, angle and pose of the hand and every finger, and the empty gap between the thumb and the fingers where a game card will be inserted later. The hand holds nothing: leave the gap empty. Do not draw a card.

CHANGE
- The art style of the second image: rough pen-and-ink lines with small ink blots, light hatching only in the deepest shadows, flat colors — cream skin, charcoal-brown cloth, deep crimson. No gradients, no pink.
- The costume of the second image: a bare pale hand with short natural nails, a black lace cuff at the wrist, a torn, opaque, smoky charcoal-brown sleeve.
- A few thin crimson threads wound around the fingers and thumb, each ending in a short loose end about the length of a finger. Nothing in the upper part of the image.

BACKGROUND
Plain flat solid pure green (#00FF00), one even color, no shadow, no green reflections on the hand, no green showing through the sleeve.

AVOID
Moving or resizing the hand, a card or any object in the hand, extra fingers, a second hand, long threads across the image, text, watermark, signature.
```
- 저장: `art/raw/vs_f/80_hand_right_pinch_point.webp` (`tools/vs_f_import.py` 가 찾는 이름)
- 검수: ①과 겹쳐 손 위치·엄지 틈이 같은지(카드 자리 `[[866,64],[1186,32],[1221,480],[914,507]]`) · 손가락 5개.

### 89 두 손 손패
- 첨부: ① [`09_ref_hands_green.png`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/ref/09_ref_hands_green.png)(두 손 자리·카드 틈) · ② [`81_hand_right_point.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs_f/81_hand_right_point.webp) · 대화창 D
```
Redraw the first attached image in the art style and costume of the second attached image. This is a first-person view of the witch Noel's own two hands at the bottom of a card game screen, about to hold a fan of five cards.

KEEP EXACTLY THE SAME AS THE FIRST IMAGE
The canvas size and 16:9 proportions, the position, size, angle and pose of both hands, every finger, and the empty gap between each thumb and its fingers where game cards will be inserted later. The hands hold nothing: leave those gaps empty. Do not draw any cards.

CHANGE
- The art style of the second image: rough pen-and-ink lines with small ink blots, light hatching only in the deepest shadows, flat colors — cream skin, charcoal-brown cloth, deep crimson. No gradients, no pink.
- The costume of the second image on both arms: bare pale hands with short natural nails, a black lace cuff at each wrist, torn, opaque, smoky charcoal-brown bell sleeves over the wrists and forearms.
- A few thin crimson threads wound around the fingers and thumb of the right hand only (on the right side of the image), each ending in a short loose end about the length of a finger. The left hand has no thread. Nothing in the upper part of the image.

BACKGROUND
Plain flat solid pure green (#00FF00), one even color, no shadow, no green reflections on the hands, no green showing through the sleeves.

AVOID
Moving or resizing the hands, cards or any object in the hands, extra fingers, a third hand, a thread on the left hand, long threads across the image, text, watermark, signature.
```
- 저장: `art/raw/vs_f/89_hands_fan_hold.webp`
- 검수: ①과 겹쳐 엄지 틈 다섯 자리(`layout.hand.slots`)가 그대로인지 · 실은 화면 오른쪽 손에만.

### 91 손짓 축복
- 첨부: [`79_hand_right_idle.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs_f/79_hand_right_idle.webp) 한 장 · 대화창 D
```
Edit this image. Keep everything exactly the same — the canvas, the wrist and its position, the black lace cuff, the torn sleeve, the colors, the line style and the plain flat pure green (#00FF00) background. Change only the pose of the hand: she turns it palm up and opens it, the fingers gently spread and slightly curved, as if offering a blessing. The same crimson threads stay wound around the same fingers, with short loose ends.
```
- 저장: `art/raw/vs_f/91_hand_right_bless.webp` · 검수: 손목·소매 자리가 79와 같은지 · 손가락 5개.

### 92 손짓 저주
- 저주·취약 겸용. 첨부: 79 F 한 장 · 대화창 D
```
Edit this image. Keep everything exactly the same — the canvas, the wrist and its position, the black lace cuff, the torn sleeve, the colors, the line style and the plain flat pure green (#00FF00) background. Change only the pose of the hand: the fingers bend into a tense claw, knuckles raised and fingertips curled downward, as if gripping something unseen to curse it. The same crimson threads stay wound around the same fingers, with short loose ends.
```
- 저장: `art/raw/vs_f/92_hand_right_claw.webp` · 검수: 손톱이 짧고 둥근지(긴 손톱 금지 — D 50 문제).

### 93 손짓 실 당기기
- 운명 전가. 첨부: 79 F 한 장 · 대화창 D
```
Edit this image. Keep everything exactly the same — the canvas, the wrist and its position, the black lace cuff, the torn sleeve, the colors, the line style and the plain flat pure green (#00FF00) background. Change only the hand: she pinches the crimson threads between her thumb and index finger and pulls them back toward her wrist, the hand drawn back a little. The threads run taut from her fingers toward the upper left and end cleanly about a hand's length beyond the fingertips.
```
- 저장: `art/raw/vs_f/93_hand_right_pull.webp` · 검수: 실이 화면 끝까지 길게 뻗지 않았는지.

### 94 손짓 손가락 튕기기
- 턴 끝(딱 소리를 내는 손짓으로 해석 — 다르면 고친다). 첨부: 79 F 한 장 · 대화창 D
```
Edit this image. Keep everything exactly the same — the canvas, the wrist and its position, the black lace cuff, the torn sleeve, the colors, the line style and the plain flat pure green (#00FF00) background. Change only the pose of the hand, to the instant after a finger snap: the middle finger has just struck down against the base of the thumb, the thumb points up, the index finger is slightly extended, the ring and little fingers are curled. Three short ink motion marks next to the fingers. The same crimson threads stay wound around the same fingers, with short loose ends.
```
- 저장: `art/raw/vs_f/94_hand_right_snap.webp` · 검수: 손가락 관절이 꺾이지 않았는지.

---

## 4. 배경·CG
- 첨부: ① 그림체 [`style_F_seraphina_stand.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/reference/style/style_F_seraphina_stand.webp) · ② 그 번호의 옛 D 그림(블록마다 링크) · 대화창 E(16만 15 결과를 고침).
- 모든 탑 안 장소는 지하 — 하늘·달 없음. 아래 1/4은 대화창 자리, 가운데는 스탠딩 자리. 어두운 옷의 인물이 묻히지 않게 가운데 띠는 조금 밝게 둔다.
- 검수 공통: D의 세피아·수채·양피지 결이 남지 않았는지 · 사람·글자가 생기지 않았는지 · 스탠딩(28·32 F)을 얹어 인물이 읽히는지.

### 15 곁방
- 첨부: ① 그림체 · ② [`15_bg_camp.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/15_bg_camp.webp) · 대화창 E(새로 시작)
```
Redraw the second attached image in the art style of the first attached image. Keep the second image's place, camera, composition, architecture and objects; do not copy its soft watercolor, sepia wash or parchment grain. Use the first image only for the art style: ignore its character and its green background. Wide 16:9 landscape, full bleed, no border, no people, no text.

ART STYLE
The pen-and-ink look of the first image: rough, confident pen lines, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream, and a little rust brown on iron. Dark and grim, like a stone table stained with dried blood: rust, old bloodstains and thorny briars only as surface details, sparingly. Light and shadow as flat shapes, not soft gradients. Slightly simpler linework than the characters, and the middle band a little lighter so dark-clad characters standing there stay readable. No pastel, no pink, no painterly or 3D rendering.

SCENE
A small stone antechamber at the entrance of a funeral tower that grows down into the earth, once a resting room for funeral priests: stone benches along the walls, an old stone table for folding shrouds, a heavy wooden door on the left, crimson funeral cloths hanging from the arches. Four bedrolls lie around a small campfire in the middle of the floor. Warm firelight is the only light; the corners fall into deep shadow. No windows, no sky.

COMPOSITION
Eye-level camera, normal lens. Keep the center open (characters will stand there) and the lower quarter simple and dark (a dialogue box will cover it).

AVOID
People, sky, moon, windows to the outside, a dark red background with ink splatters and drips, pastel colors, pink, soft digital-pencil lines drawn over and over, text, watermark, signature.
```
- 저장: `art/raw/vs_f/15_bg_camp.webp` · 검수: 침낭 4개 · 불빛이 노랗게 번진 그라데이션이 아니라 평평한 면인지.

### 16 빈 곁방
- 첨부: 15 F 결과 한 장 · 대화창 E(15 바로 뒤)
```
Edit this image. Keep everything exactly the same — the room, the camera, the light direction, the colors and the line style. Change only this: the campfire is smaller and dimmer; one of the four bedrolls is still spread out but empty; the other three are rolled up and tied.
```
- 저장: `art/raw/vs_f/16_bg_camp_empty.webp` · 검수: 15와 겹쳐 방이 같은지 · 펼친 침낭 하나.

### 07 장례 회랑
- 첨부: ① 그림체 · ② [`07_bg_funeral_gallery.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/07_bg_funeral_gallery.webp) · 대화창 E
```
Redraw the second attached image in the art style of the first attached image. Keep the second image's place, camera, composition, architecture and objects; do not copy its soft watercolor, sepia wash or parchment grain. Use the first image only for the art style: ignore its character and its green background. Wide 16:9 landscape, full bleed, no border, no people, no text.

ART STYLE
The pen-and-ink look of the first image: rough, confident pen lines, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream, and a little rust brown on iron. Dark and grim, like a stone table stained with dried blood: rust, old bloodstains and thorny briars only as surface details, sparingly. Light and shadow as flat shapes, not soft gradients. Slightly simpler linework than the characters, and the middle band a little lighter so dark-clad characters standing there stay readable. No pastel, no pink, no painterly or 3D rendering.

SCENE
A wide funeral gallery deep underground, as wide as a chapel nave. Both walls rise in tall, crooked tiers of niches, each holding a stone coffin whose lid has been pushed open from the inside and hangs askew. Crimson funeral ribbons on the coffin handles, thorny briars creeping out of the coffins and up the walls, small dark crimson roses in the cracks, dripping candle stubs with dim flames on the ledges, dried funeral wreaths, a few crows on the coffins, a single small child's shoe on the floor. In the middle distance a broad flight of shallow steps rises across the gallery to a raised stone platform; beyond it the gallery recedes into darkness. No sky.

COMPOSITION
Eye-level camera looking straight down the gallery, normal lens, the vanishing point at the center. Keep the center open and the lower quarter simple and dark.

AVOID
People, monsters, corpses, sky, moon, a dark red background with ink splatters and drips, pastel colors, pink, soft digital-pencil lines drawn over and over, text, watermark, signature.
```
- 저장: `art/raw/vs_f/07_bg_funeral_gallery.webp` · 검수: 관 뚜껑이 안에서 열린 모양 · 새 전투 탁자 너머로 어둡게 깔아도 읽히는지.

### 17 안치 홀
- 첨부: ① 그림체 · ② [`17_bg_ossuary_hall.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/17_bg_ossuary_hall.webp) · 대화창 E
```
Redraw the second attached image in the art style of the first attached image. Keep the second image's place, camera, composition, architecture and objects; do not copy its soft watercolor, sepia wash or parchment grain. Use the first image only for the art style: ignore its character and its green background. Wide 16:9 landscape, full bleed, no border, no people, no text.

ART STYLE
The pen-and-ink look of the first image: rough, confident pen lines, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream, and a little rust brown on iron. Dark and grim, like a stone table stained with dried blood: rust, old bloodstains and thorny briars only as surface details, sparingly. Light and shadow as flat shapes, not soft gradients. Slightly simpler linework than the characters, and the middle band a little lighter so dark-clad characters standing there stay readable. No pastel, no pink, no painterly or 3D rendering.

SCENE
A great round hall deep underground inside the funeral tower: its curved walls are lined with stone coffins stacked in tiers up to a dark domed ceiling. Several dark archways lead off in different directions. Rusted iron lanterns hang on chains, tattered crimson cloths hang between the tiers, dried funeral wreaths lie at the foot of the walls. No sky.

COMPOSITION
Eye-level camera looking across the hall so that four or five archways are visible, normal lens. Keep the center open and the lower quarter simple and dark.

AVOID
People, sky, moon, a dark red background with ink splatters and drips, pastel colors, pink, soft digital-pencil lines drawn over and over, text, watermark, signature.
```
- 저장: `art/raw/vs_f/17_bg_ossuary_hall.webp` · 검수: 갈래 길(아치) 4~5개가 보이는지.

### 18 계단 앞 홀
- 첨부: ① 그림체 · ② [`18_bg_stair_landing.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/18_bg_stair_landing.webp) · 대화창 E
- 대본 4장("아래로 꺼지는 나선 계단")대로 **내려가는 계단**을 못 박았다 — D에서 위로 보이던 문제(`art-todo.md` 참고 D 4장)도 여기서 함께 풀린다.
```
Redraw the second attached image in the art style of the first attached image. Keep the second image's room, walls, candles and iron railing, but the staircase must go DOWN as described below. Do not copy its soft watercolor, sepia wash or parchment grain. Use the first image only for the art style: ignore its character and its green background. Wide 16:9 landscape, full bleed, no border, no people, no text.

ART STYLE
The pen-and-ink look of the first image: rough, confident pen lines, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream, and a little rust brown on iron. Dark and grim, like a stone table stained with dried blood: rust, old bloodstains and thorny briars only as surface details, sparingly. Light and shadow as flat shapes, not soft gradients. Slightly simpler linework than the characters, and the middle band a little lighter so dark-clad characters standing there stay readable. No pastel, no pink, no painterly or 3D rendering.

SCENE
A stone landing deep underground at the head of a wide spiral staircase that goes DOWN. The first steps start at the edge of the landing and wind downward around a dark open stairwell, toward a faint crimson glow far below. No steps go up anywhere. Candles stand along the inner wall of the stairwell, a rusted iron railing follows the steps down, worn carvings on the walls. No sky.

COMPOSITION
Eye-level camera, normal lens, the stairwell opening in the center-right. Keep the center open and the lower quarter simple and dark.

AVOID
Stairs going up, people, sky, moon, a dark red background with ink splatters and drips, pastel colors, pink, soft digital-pencil lines drawn over and over, letters, text, watermark, signature.
```
- 저장: `art/raw/vs_f/18_bg_stair_landing.webp` · 검수: 올라가는 계단이 한 칸도 없는지.

### 20 광신도 기도실
- 첨부: ① 그림체 · ② [`20_bg_cult_prayer_room.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/20_bg_cult_prayer_room.webp) · 대화창 E
```
Redraw the second attached image in the art style of the first attached image. Keep the second image's place, camera, composition, architecture and objects; do not copy its soft watercolor, sepia wash or parchment grain. Use the first image only for the art style: ignore its character and its green background. Wide 16:9 landscape, full bleed, no border, no people, no text.

ART STYLE
The pen-and-ink look of the first image: rough, confident pen lines, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream, and a little rust brown on iron. Dark and grim, like a stone table stained with dried blood: rust, old bloodstains and thorny briars only as surface details, sparingly. Light and shadow as flat shapes, not soft gradients. Slightly simpler linework than the characters, and the middle band a little lighter so dark-clad characters standing there stay readable. No pastel, no pink, no painterly or 3D rendering.

SCENE
A small underground prayer room of a death cult inside the funeral tower. In the middle distance a few wide stone steps rise to a raised round stone platform with a dark hole in its center that drops into blackness; worn prayer mats, bone charms on crimson cords and pools of candle wax surround the hole. A low vaulted ceiling, a few rusted iron lanterns. No sky.

COMPOSITION
Eye-level camera, normal lens, looking straight at the platform. Keep the center open and the lower quarter simple and dark.

AVOID
People, sky, moon, a dark red background with ink splatters and drips, pastel colors, pink, soft digital-pencil lines drawn over and over, text, watermark, signature.
```
- 저장: `art/raw/vs_f/20_bg_cult_prayer_room.webp` · 검수: 바닥 구멍이 가운데 단 위에 있는지(대본 3.1).

### 21 무덤지기의 방
- 첨부: ① 그림체 · ② [`21_bg_gravekeeper_vault.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/21_bg_gravekeeper_vault.webp) · 대화창 E
```
Redraw the second attached image in the art style of the first attached image. Keep the second image's place, camera, composition, architecture and objects; do not copy its soft watercolor, sepia wash or parchment grain. Use the first image only for the art style: ignore its character and its green background. Wide 16:9 landscape, full bleed, no border, no people, no text.

ART STYLE
The pen-and-ink look of the first image: rough, confident pen lines, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream, and a little rust brown on iron. Dark and grim, like a stone table stained with dried blood: rust, old bloodstains and thorny briars only as surface details, sparingly. Light and shadow as flat shapes, not soft gradients. Slightly simpler linework than the characters, and the middle band a little lighter so dark-clad characters standing there stay readable. No pastel, no pink, no painterly or 3D rendering.

SCENE
The grave keeper's vault deep underground: broken coffin lids leaning against the walls in heaps, a rack of rusted grave-digging shovels and picks, a heavy iron lantern hanging from a chain, an iron gate standing open at the back, a few wide stone steps rising to a raised stone floor in the middle distance. No sky.

COMPOSITION
Eye-level camera, normal lens. Keep the center open and the lower quarter simple and dark.

AVOID
People, sky, moon, a dark red background with ink splatters and drips, pastel colors, pink, soft digital-pencil lines drawn over and over, text, watermark, signature.
```
- 저장: `art/raw/vs_f/21_bg_gravekeeper_vault.webp` · 검수: 무덤지기(40 F, 관 뚜껑 갑옷)를 얹었을 때 묻히지 않는지.

### 22 순장된 자의 방
- 첨부: ① 그림체 · ② [`22_bg_buried_coffin_room.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/22_bg_buried_coffin_room.webp) · 대화창 E
```
Redraw the second attached image in the art style of the first attached image. Keep the second image's place, camera, composition, architecture and objects; do not copy its soft watercolor, sepia wash or parchment grain. Use the first image only for the art style: ignore its character and its green background. Wide 16:9 landscape, full bleed, no border, no people, no text.

ART STYLE
The pen-and-ink look of the first image: rough, confident pen lines, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream, and a little rust brown on iron. Dark and grim, like a stone table stained with dried blood: rust, old bloodstains and thorny briars only as surface details, sparingly. Light and shadow as flat shapes, not soft gradients. Slightly simpler linework than the characters, and the middle band a little lighter so dark-clad characters standing there stay readable. No pastel, no pink, no painterly or 3D rendering.

SCENE
A cramped burial chamber deep underground, lit by a single candle. One plain wooden coffin stands on a stone slab, its lid nailed shut with many long rusted iron nails. Dust and cobwebs, a narrow doorway behind. No sky.

COMPOSITION
Eye-level camera, normal lens, the coffin in the center-left so characters can stand on the right. Keep the lower quarter simple and dark.

AVOID
People, a body, blood, sky, moon, a dark red background with ink splatters and drips, pastel colors, pink, soft digital-pencil lines drawn over and over, text, watermark, signature.
```
- 저장: `art/raw/vs_f/22_bg_buried_coffin_room.webp` · 검수: 관에 못이 여러 개 박혀 있는지.

### 23 핏자국 통로 끝 CG
- 죽은 마녀의 머리색은 사용자 결정 대기(`art-todo.md` 참고 D 4장 — 추천: D처럼 은백 그대로, 얼굴은 모자로 가림).
- 첨부: ① 그림체 · ② [`23_cg_dead_witch.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/23_cg_dead_witch.webp) · 대화창 E
```
Redraw the second attached image in the art style of the first attached image: the same place, camera, composition and the same dead witch. Do not copy its soft watercolor, sepia wash or parchment grain. Use the first image only for the art style: ignore its character and its green background. Wide 16:9 landscape, full bleed, no border, no text.

ART STYLE
The pen-and-ink look of the first image: rough, confident pen lines, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream, and a little rust brown. Dark, quiet and sad. Light and shadow as flat shapes, not soft gradients. No pastel, no pink, no painterly or 3D rendering.

SCENE
A dead-end stone passage deep underground. A long trail of dried, dark crimson marks along the floor ends at the wall, where a dead witch sits slumped against it, long dead and dried. Her face is completely hidden under a wide-brimmed black witch hat. Her hands rest in her lap; crimson threads are wound around her fingers and their cut ends trail on the floor. Old playing cards are scattered around her; every card's picture is burnt black. A single candle stub, long burnt out. Quiet and sad, not gory. No sky.

AVOID
Her face, a skull, open wounds, gore, sky, moon, a dark red background with ink splatters and drips, pastel colors, pink, soft digital-pencil lines drawn over and over, text, watermark, signature.
```
- 저장: `art/raw/vs_f/23_cg_dead_witch.webp` · 검수: 얼굴이 보이지 않는지 · 카드 그림이 모두 탔는지.

### 24 촛불 예배당
- 첨부: ① 그림체 · ② [`24_bg_candle_chapel.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/24_bg_candle_chapel.webp) · 대화창 E
```
Redraw the second attached image in the art style of the first attached image. Keep the second image's place, camera, composition, architecture and objects; do not copy its soft watercolor, sepia wash or parchment grain. Use the first image only for the art style: ignore its character and its green background. Wide 16:9 landscape, full bleed, no border, no people, no text.

ART STYLE
The pen-and-ink look of the first image: rough, confident pen lines, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream, and a little rust brown on iron. Light and shadow as flat shapes, not soft gradients. Slightly simpler linework than the characters, and the middle band a little lighter so dark-clad characters standing there stay readable. No pastel, no pink, no painterly or 3D rendering.

SCENE
A tiny underground chapel where a few candles still burn on a small stone altar: the one warm, almost gentle room of the tower, still dark around the edges. A funeral wreath left on a wooden bench, a faded crimson altar cloth, worn floor stones. A quiet place to rest. No sky.

COMPOSITION
Eye-level camera, normal lens. Keep the center open and the lower quarter simple and dark.

AVOID
People, blood, sky, moon, a dark red background with ink splatters and drips, pastel colors, pink, soft digital-pencil lines drawn over and over, text, watermark, signature.
```
- 저장: `art/raw/vs_f/24_bg_candle_chapel.webp` · 검수: 다른 방보다 따뜻하되 F 세 가지 색 안인지.

### 25 무너진 훈련장
- 첨부: ① 그림체 · ② [`25_bg_training_hall.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/25_bg_training_hall.webp) · 대화창 E
```
Redraw the second attached image in the art style of the first attached image. Keep the second image's place, camera, composition, architecture and objects; do not copy its soft watercolor, sepia wash or parchment grain. Use the first image only for the art style: ignore its character and its green background. Wide 16:9 landscape, full bleed, no border, no people, no text.

ART STYLE
The pen-and-ink look of the first image: rough, confident pen lines, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream, and a little rust brown on iron. Dark and grim, like a stone table stained with dried blood: rust, old bloodstains and thorny briars only as surface details, sparingly. Light and shadow as flat shapes, not soft gradients. Slightly simpler linework than the characters, and the middle band a little lighter so dark-clad characters standing there stay readable. No pastel, no pink, no painterly or 3D rendering.

SCENE
A collapsed guard training hall deep underground inside the funeral tower: broken wooden practice dummies, a toppled rack of rusted spears and wooden swords, cracked flagstones, a heap of rubble where part of the vaulted ceiling has fallen. A torn crimson banner of the old tower guard hangs on one wall. No sky.

COMPOSITION
Eye-level camera, normal lens. Keep the center open and the lower quarter simple and dark.

AVOID
People, sky, moon, a dark red background with ink splatters and drips, pastel colors, pink, soft digital-pencil lines drawn over and over, letters, text, watermark, signature.
```
- 저장: `art/raw/vs_f/25_bg_training_hall.webp` · 검수: 천장 무너진 자리에 하늘이 보이지 않는지.

### 26 묘지기의 좌판 CG
- 첨부: ① 그림체 · ② [`26_cg_grave_merchant.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/26_cg_grave_merchant.webp) · 대화창 E
```
Redraw the second attached image in the art style of the first attached image: the same place, camera, composition and the same old merchant. Do not copy its soft watercolor, sepia wash or parchment grain. Use the first image only for the art style: ignore its character and its green background. Wide 16:9 landscape, full bleed, no border, no text.

ART STYLE
The pen-and-ink look of the first image: rough, confident pen lines, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream, and a little rust brown. Dark and a little eerie. Light and shadow as flat shapes, not soft gradients. No pastel, no pink, no painterly or 3D rendering.

SCENE
A dim underground passage where an old coffin is used as a market stall: candles, bundles of old cards, small corked bottles and crimson ribbons are laid out on its lid. Behind it sits a small, old grave-keeper merchant in a patched hooded coat, half in shadow, with a crooked, knowing smile, holding up a candle. A little eerie, not threatening. No sky.

COMPOSITION
Eye-level camera, normal lens, the stall and the merchant in the center-left. Keep the lower quarter simple and dark.

AVOID
Blood, sky, moon, a dark red background with ink splatters and drips, pastel colors, pink, soft digital-pencil lines drawn over and over, text, watermark, signature.
```
- 저장: `art/raw/vs_f/26_cg_grave_merchant.webp` · 검수: 묘지기 손가락 수 · 카드에 글자가 없는지.

### 27 발자국 방
- 첨부: ① 그림체 · ② [`27_bg_footprint_room.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/27_bg_footprint_room.webp) · 대화창 E
```
Redraw the second attached image in the art style of the first attached image. Keep the second image's place, camera and composition, but the footprint must have exactly five toes as described below. Do not copy its soft watercolor, sepia wash or parchment grain. Use the first image only for the art style: ignore its character and its green background. Wide 16:9 landscape, full bleed, no border, no people, no text.

ART STYLE
The pen-and-ink look of the first image: rough, confident pen lines, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream, and a little rust brown on iron. Dark and grim. Light and shadow as flat shapes, not soft gradients. No pastel, no pink, no painterly or 3D rendering.

SCENE
An underground hall whose stone floor has sunk in the exact shape of one colossal bare footprint, far larger than a person: one heel and exactly five toe prints — one big toe and four smaller toes, each smaller toward the outside. Inside the print lie several suits of armor of a lost expedition, flattened into the stone, and a torn crimson pennant. Cracks radiate from the print across the floor and up the walls. No bodies, no gore. No sky.

COMPOSITION
A slightly high eye-level camera so the whole footprint reads clearly. Keep the lower quarter simple and dark.

AVOID
Six toes, bodies, gore, blood pools, sky, moon, a dark red background with ink splatters and drips, pastel colors, pink, soft digital-pencil lines drawn over and over, text, watermark, signature.
```
- 저장: `art/raw/vs_f/27_bg_footprint_room.webp` · 검수: 발가락 자국이 정확히 5개.

---

## 5. 가장 깊은 곳·데스신
- 데스신 수위(`art-direction.md` 4장): 피는 "spilled red ink"로 보여 주되 단면·장기 없음, 감정 컷은 피를 줄임, **폭력과 노출을 섞지 않음** — 세라피나의 맨허리·붕대는 데스신에서 망토로 가린다.
- 순서: 19 → 90 → C1 → C2 → C3b → C3a → C4 → C6(피 있는 컷이 뒤로). 피투성이 옛 컷(C3a·C4·C6)은 첨부하지 않는다 — C3a는 F C3b를, C4는 F C3b를, C6는 F C4를 고쳐 만든다(D 때 맞았던 방법).
- 거절되면 새 대화창에서 같은 첨부·같은 프롬프트, 끝에 `No gore.` 를 한 번 더.

### 19 가장 깊은 곳
- 첨부: ① 그림체 · ② [`19_bg_deepest_hall.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/19_bg_deepest_hall.webp) · 대화창 F(새로 시작)
```
Redraw the second attached image in the art style of the first attached image. Keep the second image's place, camera, composition and architecture; do not copy its soft painterly rendering, gray haze or parchment grain. Use the first image only for the art style: ignore its character and its green background. Wide 16:9 landscape, full bleed, no border, no people, no creatures, no text.

ART STYLE
The pen-and-ink look of the first image: rough, confident pen lines, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream, and a little rust brown. Dark and grim. Light and shadow as flat shapes, not soft gradients. Slightly simpler linework than the characters, and the middle band a little lighter so dark-clad characters standing there stay readable. No pastel, no pink, no painterly or 3D rendering.

SCENE
The deepest hall of the floor, deep underground — the place where the holy knight will die: a vast ruined gothic hall with tall broken lancet arches along both sides, a large rose window glowing deep crimson at the far end, dust hanging in the air, a few falling stone fragments, a cracked stone floor. A broad flight of wide steps rises to a raised stone dais in front of the rose window. The high vault is lost in darkness. Empty. No sky, no moon.

COMPOSITION
Eye-level camera looking straight down the hall toward the rose window, normal lens. Keep the center open and the lower quarter simple and dark. The upper middle stays calm: the picture is also used, darkened, behind the title.

AVOID
People, the giant foot, blood pools, sky, moon, a dark red background with ink splatters and drips, pastel colors, pink, soft digital-pencil lines drawn over and over, text, watermark, signature.
```
- 저장: `art/raw/vs_f/19_bg_deepest_hall.webp` · 검수: 장미창이 진홍 하나로 빛나는지 · 타이틀처럼 어둡게(밝기 0.5) 해도 형태가 읽히는지.

### 90 거대한 발 카드
- 첨부: ① 그림체 · ② [`41_giant_foot.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/41_giant_foot.webp)(발 모양) · 대화창 F
```
Draw the colossal foot of the second attached image as a vertical 2:3 card illustration in the art style of the first attached image (ignore the first image's character and its green background). Full bleed, no border, no frame, no text.

ART STYLE
The pen-and-ink look of the first image: rough, confident pen lines, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream. Dark and grim, matching a rusted, blood-stained card frame. No gradients, no pastel, no pink, no painterly or 3D rendering.

SUBJECT
A colossal bare humanoid foot coming down out of the darkness above, cropped at the ankle by the top edge, the sole slightly toward the viewer and the toes pointing toward the viewer: gray, cracked, stone-like skin, exactly five natural toes with cracked toenails, thin streaks of dried dark crimson in the cracks. Far below it, the cracked stone floor of a ruined underground hall and the faint deep-crimson glow of a rose window; dust and small falling stones. Tiny broken arches at the bottom of the picture show how enormous it is.

FRAMING
Vertical 2:3. Keep the toes in the upper middle of the picture (a small crop of the toes will also be used as this enemy's face icon); the outer edges may be hidden by a card frame.

AVOID
A person, a body under the foot, gore, blood pools, extra toes, sky, moon, a dark red background with ink splatters and drips, text, letters, numbers, watermark, signature.
```
- 저장: `art/raw/vs_f/90_card_giant_foot.webp` · 검수: 발가락 5개 · 발가락만 잘라도(작은 얼굴) 발로 읽히는지.

### 83 데스신 C1 마지막 말
- 첨부: ① 그림체(= 세라피나 F) · ② [`seraphina_C1_last_words.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/reference/deathscene/seraphina_C1_last_words.webp) · 대화창 F
```
Redraw the second attached image in the art style of the first attached image: the same scene, camera, composition and moment. The knight is Seraphina from the first image — take her face, the single small beauty mark under her left eye, her silver hair and long braid with the crimson ribbon, her gray plate armor, crimson cape and sacred longsword from the first image. Do not copy the second image's soft painterly rendering, sepia haze or parchment look. Wide 16:9 landscape, full bleed, no border, no text.

ART STYLE
Rough pen-and-ink lines drawn in one or two confident strokes, sometimes broken, with small ink blots; light hatching only in the darkest shadows; flat colors — charcoal and graphite gray for the stone and her armor, deep crimson for the cape, the ribbon and the glow of the rose window, cream for her skin and highlights. Calm eyes with small highlights, not moe. No gradients, no pastel, no pink, no blush.

SCENE — the last words
The deepest hall of a funeral tower, deep underground: tall broken gothic arches, a large rose window glowing deep crimson far behind her, dust and small falling stones. Low angle, from about her waist up. Seraphina has turned back toward the viewer with a small, lonely smile, her gauntleted hands resting on the pommel of her sacred longsword held point-down in front of her. Above her head, filling the top of the frame, the sole and toes of a colossal bare foot are coming down, the toes toward the camera: gray, cracked, stone-like skin, exactly five natural toes. Her crimson cape is wrapped around her body so her waist is not visible.

AVOID
Blood, gore, bare skin below the neck, a sexualized pose, a second beauty mark, a crimson thread on her wrist, sky, moon, a dark red background with ink splatters and drips, soft digital-pencil lines drawn over and over, text, watermark, signature.
```
- 저장: `art/raw/vs_f/83_death_seraphina_c1_last_words.webp` · 검수: 점 하나(왼쪽 눈 밑) · 발가락 5개가 카메라 쪽 · 허리가 망토에 가려졌는지.

### 84 데스신 C2 손을 뻗음
- 첨부: ① 그림체 · ② [`seraphina_C2_reach.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/reference/deathscene/seraphina_C2_reach.webp) · 대화창 F
```
Redraw the second attached image in the art style of the first attached image, exactly like the previous cut you drew: the same scene, camera, composition and moment as the second image. The knight is Seraphina from the first image — her face, the single small beauty mark under her left eye, her silver hair and braid with the crimson ribbon, her gray plate armor and crimson cape. Do not copy the second image's soft painterly rendering, sepia haze or parchment look. Wide 16:9 landscape, full bleed, no border, no text.

ART STYLE
Rough pen-and-ink lines drawn in one or two confident strokes, sometimes broken, with small ink blots; light hatching only in the darkest shadows; flat colors — charcoal and graphite gray, deep crimson, cream. No gradients, no pastel, no pink, no blush.

SCENE — reaching out
The same hall a moment later. Her smile has frozen; the vast shadow of the descending foot falls across her eyes. She reaches one gauntleted hand toward the viewer, fingers spread, lips parted as if calling a name. The sole of the colossal foot fills the top of the frame, much closer now. Her crimson cape still wraps her body so her waist is not visible.

AVOID
Blood, gore, bare skin below the neck, a sexualized pose, a second beauty mark, a crimson thread on her wrist, extra fingers, sky, moon, a dark red background with ink splatters and drips, text, watermark, signature.
```
- 저장: `art/raw/vs_f/84_death_seraphina_c2_reach.webp` · 검수: 83과 같은 장소·갑옷 · 뻗은 손 손가락 5개.

### 86 데스신 C3b 가
- C4·C6의 바탕이라 C3a보다 먼저. 첨부: ① 그림체 · ② [`seraphina_C3b_go.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/reference/deathscene/seraphina_C3b_go.webp) · 대화창 F
```
Redraw the second attached image in the art style of the first attached image: the same scene, camera, composition and moment. The knight is Seraphina from the first image — her face, the single small beauty mark under her left eye, her silver hair and braid with the crimson ribbon, her gray plate armor and crimson cape. Do not copy the second image's soft painterly rendering, sepia haze or parchment look. Wide 16:9 landscape, full bleed, no border, no text.

ART STYLE
Rough pen-and-ink lines drawn in one or two confident strokes, sometimes broken, with small ink blots; light hatching only in the darkest shadows; flat colors — charcoal and graphite gray, deep crimson, cream. No gradients, no pastel, no pink, no blush.

SCENE — "go"
Camera low at floor level, close. Seraphina lies on her front on the cracked stone floor, her head turned toward the viewer, tears in her eyes, her face pale and dusty. Her right arm is not visible. She reaches her left hand toward the viewer across the floor. Her braid lies beside her; her torn crimson cape covers her body. The two halves of her broken sacred longsword lie in the foreground. The dark underside of the colossal foot hangs at the top of the frame. A little crimson like spilled red ink on the stones. No gore.

AVOID
Gore, wounds, bare skin below the neck, a sexualized pose, a second beauty mark, a crimson thread on her wrist, extra fingers, sky, moon, a dark red background with ink splatters and drips, text, watermark, signature.
```
- 저장: `art/raw/vs_f/86_death_seraphina_c3b_go.webp` · 검수: 뻗은 손이 왼손 · 피가 적고 슬픔이 중심인지.

### 85 데스신 C3a 첫 번째 밟힘
- 첨부: ① 그림체 · ② 86 F 결과(인물·장소) · 대화창 F
```
Using the first attached image for the art style and the second attached image for the character, her armor and the place, draw a new cut of the same scene, a moment earlier. Wide 16:9 landscape, full bleed, no border, no text.

ART STYLE
Rough pen-and-ink lines drawn in one or two confident strokes, sometimes broken, with small ink blots; light hatching only in the darkest shadows; flat colors — charcoal and graphite gray, deep crimson, cream. No gradients, no pastel, no pink.

SCENE — the first stomp
The colossal bare foot has just slammed down on the left side of the frame, its heel and side resting on the cracked floor, dust and stone chips bursting out. Seraphina lies on the floor right beside it, face down, her silver braid and torn crimson cape spread out; her right arm disappears under the edge of the foot. In front of her lies her sacred longsword, snapped in two, the crimson ribbon still on the guard. A little crimson like spilled red ink on the stones near the foot. Camera at a low angle, a few meters away. No gore: nothing cut or crushed is shown.

AVOID
Gore, wounds, bare skin below the neck, a sexualized pose, extra toes, sky, moon, a dark red background with ink splatters and drips, text, watermark, signature.
```
- 저장: `art/raw/vs_f/85_death_seraphina_c3a_first_stomp.webp` · 검수: 발 옆에 쓰러짐·오른팔이 발밑·부러진 성검(`art-direction.md` 4장 표).

### 87 데스신 C4 마지막 밟힘
- 첨부: 86 F 결과 한 장 · 대화창 F
```
Edit this image. Keep the same camera, place, light, art style, the broken sword in the foreground and her outstretched left hand exactly where they are. Change only this: the colossal bare foot has come down where she was lying. Its toes now fill the upper and middle part of the frame, pressed into the floor, cracked stone and dust around them; only her outstretched hand and the end of her braid remain visible in front of the toes. A thin line of crimson like spilled red ink seeps from under the toes. Nothing else of her body is visible. No gore.
```
- 저장: `art/raw/vs_f/87_death_seraphina_c4_last_stomp.webp` · 검수: 86과 같은 카메라(겹쳐서) · 발가락 5개 · 손만 남음.

### 88 데스신 C6 발이 들린 뒤
- 첨부: 87 F 결과 한 장 · 대화창 F(거절되면 새 대화창 + 같은 첨부)
```
Edit this image. Keep the same camera, place, light, art style, the broken sword in the foreground, her outstretched hand and the end of her braid exactly where they are. Change only this: the foot has lifted out of the frame. In its place a deep footprint has sunk into the stone floor, with exactly five toe prints; dark crimson like spilled red ink has pooled in the toe prints. Her torn crimson cape lies pressed flat inside the footprint. At the right edge of the print lie her legs in gray greaves, the rest of her hidden under the flattened cape. No other body parts, no wounds shown, no gore.
```
- 저장: `art/raw/vs_f/88_death_seraphina_c6_aftermath.webp` · 검수: 87과 같은 카메라 · 발가락 자국 5개 · 단면·장기 없음 · 붕대·맨살이 드러나지 않았는지.

---

## 6. 카드 그림
- 카드 틀(76) 위 창에 들어갈 그림 — **틀 없이 그림만, 세로 2:3**. 장면은 탑 안 지하(하늘·달·바깥 건물 없음). 적이 나오면 광신도 F(짙은 숯빛 갈색 너덜 후드 로브·붕대 감은 팔·붉은 끈 허리띠·뼈 장식).
- 첨부: ① 그림체 · ② 옛 D 카드(구도) · 대화창 G. 1차본에 문제가 있던 카드(47~53·55·60)는 고칠 점을 프롬프트에 넣었다.
- 사용자 결정(2026-11-22): 행동 카드 그림은 당분간 D 재활용 → 60 말고는 '좋음'.
- 검수 공통: 76 틀(가운데 창)에 얹어 주제가 가운데에 남는지 · 어두운 틀과 어울리는지.

### 60 용사의 죽음
- 그림자 모양 문제(1차)와 대본 221행("세라피나의 얼굴") 사이 결정은 대기 중(`art-todo.md` 참고 D 4장) — D 내용(땋은 머리 + 발 그림자)대로 쓴다.
- 첨부: 그림체 한 장(땋은 머리가 그 안에 있다) · 대화창 G(새로 시작)
```
Using the attached image for the art style and for the look of the knight's silver braid and crimson ribbon (ignore the rest of the character and the green background), draw a vertical 2:3 card illustration. Full bleed, no border, no frame, no text.

ART STYLE
Rough pen-and-ink lines drawn in one or two confident strokes, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream. Dark and grim, matching a rusted, blood-stained card frame. No gradients, no pastel, no pink, no painterly or 3D rendering.

SUBJECT
A long silver braid tied with a crimson ribbon lies alone on a cracked stone floor deep underground, with a few dry crimson petals. Over it and most of the floor falls the clear, vast shadow of a single colossal bare foot hovering high above, cast straight down as the shape of its sole — one heel and exactly five toes — its edge just reaching the braid. No body, no gore.

FRAMING
Vertical 2:3. The braid in the lower middle, the shadow filling the upper part; the outer edges may be hidden by a card frame.

AVOID
A body, a face, gore, sky, moon, outdoor buildings, a dark red background with ink splatters and drips, text, letters, numbers, a border or frame, watermark, signature.
```
- 저장: `art/raw/vs_f/60_card_hero_death.webp` · 검수: 그림자가 '위에서 내려오는 발바닥'으로 읽히는지(발가락 5개).

### 44 성검 베기
- 「성검 베기」·「베기」(어둡게) 겸용. 첨부: ① 그림체 · ② [`44_card_holy_slash.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/44_card_holy_slash.webp) · 대화창 G
```
Redraw the second attached image as a vertical 2:3 card illustration in the art style of the first attached image. Keep the second image's subject and idea, and extend the composition up and down to fill the taller frame. Use the first image for the art style and for the sword's design; ignore its character and green background. Full bleed, no border, no frame, no text.

ART STYLE
Rough pen-and-ink lines drawn in one or two confident strokes, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream. Dark and grim, matching a rusted, blood-stained card frame. No gradients, no pastel, no pink, no watercolor wash, no sepia, no parchment grain.

SUBJECT
Seraphina's sacred longsword — a winged pale-gold guard, a red gem, a crimson ribbon tied at the guard — cutting through the dark in a sweeping crimson arc, with a few rough ink motion lines. A dark underground crypt, barely visible behind.

FRAMING
Vertical 2:3. Keep the sword and the arc in the middle; the outer edges may be hidden by a card frame.

AVOID
A hand holding the sword in the wrong place, sky, moon, outdoor buildings, a dark red background with ink splatters and drips, text, letters, numbers, a border or frame, watermark, signature.
```
- 저장: `art/raw/vs_f/44_card_holy_slash.webp` · 검수: 날개 코등이·붉은 보석·리본.

### 52 대신 받기
- 「막기」. 첨부: ① 그림체 · ② [`52_card_take_hit_v1.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/52_card_take_hit_v1.webp) · 대화창 G
```
Redraw the second attached image as a vertical 2:3 card illustration in the art style of the first attached image. Keep the second image's subject and idea, and extend the composition up and down to fill the taller frame. Use the first image only for the art style; ignore its character and green background. Full bleed, no border, no frame, no text.

ART STYLE
Rough pen-and-ink lines drawn in one or two confident strokes, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream. Dark and grim, matching a rusted, blood-stained card frame. No gradients, no pastel, no pink, no watercolor wash, no sepia, no parchment grain.

SUBJECT
The witch Noel's right hand — bare pale skin, short natural rounded nails, a black lace cuff at the wrist, a torn smoky charcoal-brown sleeve, thin crimson threads wound around the fingers — stretched out to catch a falling blade meant for someone else; the blade stops at her palm, a thin line of crimson. Behind: a dark underground crypt with stone arches, bone-filled niches and a hanging iron lantern.

FRAMING
Vertical 2:3. Keep the hand and the blade in the middle; the outer edges may be hidden by a card frame.

AVOID
Long pointed nails, a glove over the whole hand, gore, sky, moon, outdoor buildings, a dark red background with ink splatters and drips, text, letters, numbers, a border or frame, watermark, signature.
```
- 저장: `art/raw/vs_f/52_card_take_hit.webp` · 검수: 손이 F 손(79·81)과 같은 옷차림 · 배경이 지하.

### 49 견제 사격
- 「겨누기」. 첨부: ① 그림체 · ② [`49_card_suppressing_fire_v1.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/49_card_suppressing_fire_v1.webp) · 대화창 G
```
Redraw the second attached image as a vertical 2:3 card illustration in the art style of the first attached image. Keep the second image's subject and idea, and extend the composition up and down to fill the taller frame. Use the first image only for the art style; ignore its character and green background. Full bleed, no border, no frame, no text.

ART STYLE
Rough pen-and-ink lines drawn in one or two confident strokes, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream. Dark and grim, matching a rusted, blood-stained card frame. No gradients, no pastel, no pink, no watercolor wash, no sepia, no parchment grain.

SUBJECT
Three white-fletched arrows in flight in a fan, striking the stone floor just in front of hooded cultists in tattered dark charcoal-brown robes with bandaged arms, driving them back; bursts of stone chips where the arrows strike. The setting is a dark underground crypt: massive stone arches, walls of bone-filled niches, a few hanging iron lanterns, torn crimson banners hanging from the arches.

FRAMING
Vertical 2:3. Keep the arrows in the middle; the outer edges may be hidden by a card frame.

AVOID
Sky, clouds, moon, a cathedral, outdoor ruins, pale robes, a dark red background with ink splatters and drips, text, letters, numbers, a border or frame, watermark, signature.
```
- 저장: `art/raw/vs_f/49_card_suppressing_fire.webp` · 검수: 하늘·성당이 없는지(1차 문제).

### 48 저격
- 첨부: ① 그림체 · ② [`48_card_snipe_v1.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/48_card_snipe_v1.webp) · 대화창 G
```
Redraw the second attached image as a vertical 2:3 card illustration in the art style of the first attached image. Keep the second image's subject and idea, and extend the composition up and down to fill the taller frame. Use the first image only for the art style; ignore its character and green background. Full bleed, no border, no frame, no text.

ART STYLE
Rough pen-and-ink lines drawn in one or two confident strokes, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream, plus a muted dark emerald. Dark and grim, matching a rusted, blood-stained card frame. No gradients, no pastel, no pink, no watercolor wash, no sepia, no parchment grain.

SUBJECT
The elf archer Elian's white longbow with pale gold inlay drawn to full draw, a single white-fletched arrow about to be released, her hands in long white lace gloves at the string, a glimpse of her dark emerald cloak and long golden hair. Behind: a dark underground crypt — massive stone arches, walls of bone-filled niches, a few hanging iron lanterns, torn crimson banners hanging from the arches.

FRAMING
Vertical 2:3. Keep the bow and arrow in the middle; the outer edges may be hidden by a card frame.

AVOID
Sky, clouds, moon, a cathedral, outdoor ruins, a crimson thread on the wrist, a dark red background with ink splatters and drips, text, letters, numbers, a border or frame, watermark, signature.
```
- 저장: `art/raw/vs_f/48_card_snipe.webp` · 검수: 배경이 지하(1차 문제) · 손가락 수.

### 47 방패 강타
- 「되돌리기」. 첨부: ① 그림체 · ② [`47_card_shield_bash_v1.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/47_card_shield_bash_v1.webp) · 대화창 G
```
Redraw the second attached image as a vertical 2:3 card illustration in the art style of the first attached image. Keep the second image's subject and idea, and extend the composition up and down to fill the taller frame. Use the first image only for the art style; ignore its character and green background. Full bleed, no border, no frame, no text.

ART STYLE
Rough pen-and-ink lines drawn in one or two confident strokes, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream. Dark and grim, matching a rusted, blood-stained card frame. No gradients, no pastel, no pink, no watercolor wash, no sepia, no parchment grain.

SUBJECT
The edge of a massive dark tower shield with pale thorn filigree and a bouquet of dried straw-colored wildflowers tied with a crimson ribbon, slamming forward into a hooded cultist in a tattered dark charcoal-brown robe with bandaged arms; rough ink impact lines. The arm behind the shield wears dark charcoal-black plate armor with pale wildflower-and-thorn filigree. A dark underground crypt behind.

FRAMING
Vertical 2:3. Keep the impact in the middle; the outer edges may be hidden by a card frame.

AVOID
Silver or brown armor, a pale robe, a sword or mace, sky, moon, outdoor buildings, a dark red background with ink splatters and drips, text, letters, numbers, a border or frame, watermark, signature.
```
- 저장: `art/raw/vs_f/47_card_shield_bash.webp` · 검수: 갑옷이 검정(1차 문제: 은갈색) · 맞는 적 로브가 어두운지 · 무기는 방패뿐.

### 51 운명 전가
- 첨부: ① 그림체 · ② [`51_card_fate_shift_v1.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/51_card_fate_shift_v1.webp) · 대화창 G
```
Redraw the second attached image as a vertical 2:3 card illustration in the art style of the first attached image. Keep the second image's subject and idea — the crimson thread and its path, the bending blade — and extend the composition up and down to fill the taller frame. Use the first image only for the art style; ignore its character and green background. Full bleed, no border, no frame, no text.

ART STYLE
Rough pen-and-ink lines drawn in one or two confident strokes, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream. Dark and grim, matching a rusted, blood-stained card frame. No gradients, no pastel, no pink, no watercolor wash, no sepia, no parchment grain.

SUBJECT
The witch Noel's right hand — bare pale skin, short natural rounded nails, a black lace cuff at the wrist, a torn smoky charcoal-brown sleeve — pulls a crimson thread with two fingers. The thread runs from one small dark figure to another; the path of an incoming blade bends along the thread toward the second figure. The two small figures stand on stone ledges in the darkness of a vast underground crypt with faint stone arches; the figure on the right is a woman with long hair and a cape.

FRAMING
Vertical 2:3. Keep the hand and the thread in the middle; the outer edges may be hidden by a card frame.

AVOID
Long pointed nails, crimson or white sleeves, sky, clouds, moon, a short-haired man, a dark red background with ink splatters and drips, text, letters, numbers, a border or frame, watermark, signature.
```
- 저장: `art/raw/vs_f/51_card_fate_shift.webp` · 검수: 1차 문제 셋(손·하늘·오른쪽 인물)이 풀렸는지.

### 50 저주의 불꽃
- 「저주」(어둡게). 첨부: ① 그림체 · ② [`50_card_curse_flame_v1.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/50_card_curse_flame_v1.webp) · 대화창 G
```
Redraw the second attached image as a vertical 2:3 card illustration in the art style of the first attached image. Keep the second image's subject and idea, and extend the composition up and down to fill the taller frame. Use the first image only for the art style; ignore its character and green background. Full bleed, no border, no frame, no text.

ART STYLE
Rough pen-and-ink lines drawn in one or two confident strokes, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream. Dark and grim, matching a rusted, blood-stained card frame. No gradients, no pastel, no pink, no watercolor wash, no sepia, no parchment grain.

SUBJECT
The witch Noel's right hand — bare pale skin, short natural rounded nails, a black lace cuff at the wrist, a torn smoky charcoal-brown sleeve, thin crimson threads wound around the fingers — thrust forward, releasing a curling crimson flame shaped like thorny vines. Darkness all around.

FRAMING
Vertical 2:3. Keep the hand and the flame in the middle; the outer edges may be hidden by a card frame.

AVOID
Long pointed nails or claws, sky, moon, outdoor buildings, a dark red background with ink splatters and drips, text, letters, numbers, a border or frame, watermark, signature.
```
- 저장: `art/raw/vs_f/50_card_curse_flame.webp` · 검수: 손톱이 짧고 둥근지(1차 문제).

### 53 죽음의 예지
- 「취약」. 첨부: ① 그림체 · ② [`53_card_foresight_v1.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/53_card_foresight_v1.webp)(구도) · ③ [`39_stand_noel.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs_f/39_stand_noel.webp)(노엘 눈·머리·모자) · 대화창 G
```
Redraw the second attached image as a vertical 2:3 card illustration in the art style of the first attached image. Keep the second image's subject and idea, and extend the composition up and down to fill the taller frame. The witch is Noel from the third attached image: her crimson eye, wine-red hair and black witch hat. Use the first image only for the art style. Full bleed, no border, no frame, no text.

ART STYLE
Rough pen-and-ink lines drawn in one or two confident strokes, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream, and Noel's wine-red hair. Dark and grim, matching a rusted, blood-stained card frame. No gradients, no pastel, no pink, no blush.

SUBJECT
Noel's crimson eye seen through the gap of a fan of old cards held in her hand, a few strands of wine-red hair and the brim of her witch hat. Reflected small in the eye: a dark underground hall of stone arches with a small lone figure and grave crosses.

FRAMING
Vertical 2:3. Keep the eye in the middle; the outer edges may be hidden by a card frame.

AVOID
A moon, spires, open sky, droopy moe eyes, a dark red background with ink splatters and drips, text, letters, numbers, a border or frame, watermark, signature.
```
- 저장: `art/raw/vs_f/53_card_foresight.webp` · 검수: 눈에 비친 장면이 지하(1차 문제: 달·첨탑).

### 58 이름 없는 마녀의 카드
- 시체 방 보상 · 「운명 찢기」 겸용. 첨부: ① 그림체 · ② [`58_card_nameless_witch.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/58_card_nameless_witch.webp) · 대화창 G
```
Redraw the second attached image as a vertical 2:3 card illustration in the art style of the first attached image. Keep the second image's subject and idea, and extend the composition up and down to fill the taller frame. Use the first image only for the art style; ignore its character and green background. Full bleed, no border, no frame, no text.

ART STYLE
Rough pen-and-ink lines drawn in one or two confident strokes, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream. Dark and grim, matching a rusted, blood-stained card frame. No gradients, no pastel, no pink, no watercolor wash, no sepia, no parchment grain.

SUBJECT
A single old playing card lies unburnt among a scatter of cards burnt black on a dark stone floor deep underground, a thin crimson thread lying across it. The picture on the unburnt card is too faded to read.

FRAMING
Vertical 2:3. Keep the unburnt card in the middle; the outer edges may be hidden by a card frame.

AVOID
Readable pictures or symbols on the cards, sky, moon, outdoor buildings, a dark red background with ink splatters and drips, text, letters, numbers, a border or frame, watermark, signature.
```
- 저장: `art/raw/vs_f/58_card_nameless_witch.webp` · 검수: 카드에 글자·숫자가 없는지.

### 95 축복 카드
- 새 카드 그림(지금 코드 빛살). 첨부: ① 그림체 · ② [`79_hand_right_idle.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs_f/79_hand_right_idle.webp)(노엘 손) · 대화창 G
```
Using the first attached image for the art style and the second attached image for the witch's hand and sleeve, draw a vertical 2:3 card illustration. Ignore the knight and the green background of the first image. Full bleed, no border, no frame, no text.

ART STYLE
Rough pen-and-ink lines drawn in one or two confident strokes, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream. Dark and grim, matching a rusted, blood-stained card frame. No gradients, no pastel, no pink.

SUBJECT
The witch Noel's right hand, as in the second image, held palm down above the bowed head of a small kneeling armored figure seen from behind. Pale cream light falls from her palm, drawn as a few fine straight ink rays. Thin crimson threads wound around her fingers. Darkness of an underground crypt around them.

FRAMING
Vertical 2:3. Keep the hand and the light in the middle; the outer edges may be hidden by a card frame.

AVOID
A halo, angels, glowing gradients, long pointed nails, sky, moon, a dark red background with ink splatters and drips, text, letters, numbers, a border or frame, watermark, signature.
```
- 저장: `art/raw/vs_f/95_card_bless.webp` · 검수: 빛이 그라데이션이 아니라 잉크 선인지.

### 55 짓밟힘
- 1차본(발가락 6개)은 첨부하지 않는다. 첨부: 그림체 한 장 · 대화창 G
```
Using the attached image only for the art style (ignore the character and the green background), draw a vertical 2:3 card illustration. Full bleed, no border, no frame, no text.

ART STYLE
Rough pen-and-ink lines drawn in one or two confident strokes, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream. Dark and grim, matching a rusted, blood-stained card frame. No gradients, no pastel, no pink.

SUBJECT
A colossal bare footprint pressed deep into a cracked stone floor deep underground, seen from above: one heel and exactly five toe prints — one big toe and four smaller toes, each smaller toward the outside. A torn crimson ribbon caught at its edge, dust settling. No body, no blood pool.

FRAMING
Vertical 2:3. The whole footprint in the middle; the outer edges may be hidden by a card frame.

AVOID
Six toes, a body, gore, sky, moon, outdoor buildings, a dark red background with ink splatters and drips, text, letters, numbers, a border or frame, watermark, signature.
```
- 저장: `art/raw/vs_f/55_card_trampled.webp` · 검수: 발가락 자국 정확히 5개(1차 문제).

### 56 부러진 성검
- 첨부: ① 그림체 · ② [`56_card_broken_holy_sword.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/56_card_broken_holy_sword.webp) · 대화창 G
```
Redraw the second attached image as a vertical 2:3 card illustration in the art style of the first attached image. Keep the second image's subject and idea, and extend the composition up and down to fill the taller frame. Use the first image for the art style and for the sword's design; ignore its character and green background. Full bleed, no border, no frame, no text.

ART STYLE
Rough pen-and-ink lines drawn in one or two confident strokes, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream. Dark and grim, matching a rusted, blood-stained card frame. No gradients, no pastel, no pink, no watercolor wash, no sepia, no parchment grain.

SUBJECT
Seraphina's sacred longsword — a winged pale-gold guard, a red gem — its blade snapped in two, lying on cracked stone deep underground, the crimson ribbon still tied at the guard.

FRAMING
Vertical 2:3. Both halves of the sword in the middle; the outer edges may be hidden by a card frame.

AVOID
A hand, a body, sky, moon, outdoor buildings, a dark red background with ink splatters and drips, text, letters, numbers, a border or frame, watermark, signature.
```
- 저장: `art/raw/vs_f/56_card_broken_holy_sword.webp` · 검수: 44와 같은 칼(코등이·보석·리본).

### 57 용사의 마지막 돌격
- 첨부: ① 그림체(= 세라피나 F) · ② [`57_card_last_charge.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/57_card_last_charge.webp) · 대화창 G
```
Redraw the second attached image as a vertical 2:3 card illustration in the art style of the first attached image. Keep the second image's subject and idea, and extend the composition up and down to fill the taller frame. The knight is Seraphina from the first image (silver braid with a crimson ribbon, gray plate armor, crimson cape, sacred longsword). Full bleed, no border, no frame, no text.

ART STYLE
Rough pen-and-ink lines drawn in one or two confident strokes, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream. Dark and grim, matching a rusted, blood-stained card frame. No gradients, no pastel, no pink, no watercolor wash, no sepia, no parchment grain.

SUBJECT
The faded, half-transparent silhouette of Seraphina charging forward one last time, sword raised, braid and cape flying, drawn in thin broken ink lines that fade into the darkness of an underground crypt like a memory.

FRAMING
Vertical 2:3. Keep the figure in the middle; the outer edges may be hidden by a card frame.

AVOID
Bare skin emphasis, a crimson thread on her wrist, sky, moon, outdoor buildings, a dark red background with ink splatters and drips, text, letters, numbers, a border or frame, watermark, signature.
```
- 저장: `art/raw/vs_f/57_card_last_charge.webp` · 검수: 망토·땋은 머리로 세라피나가 읽히는지.

### 59 작은 손의 부적
- 첨부: ① 그림체 · ② [`59_card_small_hand_charm.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/59_card_small_hand_charm.webp) · 대화창 G
```
Redraw the second attached image as a vertical 2:3 card illustration in the art style of the first attached image. Keep the second image's subject and idea, and extend the composition up and down to fill the taller frame. Use the first image only for the art style; ignore its character and green background. Full bleed, no border, no frame, no text.

ART STYLE
Rough pen-and-ink lines drawn in one or two confident strokes, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream. Dark, quiet and a little sad. No gradients, no pastel, no pink, no watercolor wash, no sepia, no parchment grain.

SUBJECT
A small child's dusty hand holding out a little wooden charm on a crimson cord, in the darkness of an underground crypt.

FRAMING
Vertical 2:3. Keep the hand and the charm in the middle; the outer edges may be hidden by a card frame.

AVOID
Injuries, blood, the cord wound around the fingers, sky, moon, outdoor buildings, a dark red background with ink splatters and drips, text, letters, numbers, a border or frame, watermark, signature.
```
- 저장: `art/raw/vs_f/59_card_small_hand_charm.webp` · 검수: 아이 손(작고 통통함) · 부적 끈이 손가락에 감기지 않았는지(붉은 실과 헷갈림).

### 54 상처
- 첨부: ① 그림체 · ② [`54_card_wound.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/54_card_wound.webp) · 대화창 G
```
Redraw the second attached image as a vertical 2:3 card illustration in the art style of the first attached image. Keep the second image's subject and idea, and extend the composition up and down to fill the taller frame. Use the first image only for the art style; ignore its character and green background. Full bleed, no border, no frame, no text.

ART STYLE
Rough pen-and-ink lines drawn in one or two confident strokes, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream. Dark and grim, matching a rusted, blood-stained card frame. No gradients, no pastel, no pink, no watercolor wash, no sepia, no parchment grain.

SUBJECT
A torn, loosely wound bandage stained with a single spot of dark crimson, lying on cold cracked stone deep underground.

FRAMING
Vertical 2:3. Keep the bandage in the middle; the outer edges may be hidden by a card frame.

AVOID
A body, gore, sky, moon, outdoor buildings, a dark red background with ink splatters and drips, text, letters, numbers, a border or frame, watermark, signature.
```
- 저장: `art/raw/vs_f/54_card_wound.webp` · 검수: 핏자국이 한 군데.

### 45 선봉
- 나중(새 전투 덱에 없음). 1차본(다른 인물)은 첨부하지 않는다. 첨부: ① 그림체(= 세라피나 F) · ② 32 F(수정본) · ③ 36 F · 대화창 G
```
Using the attached images as references — the first for the art style and for the holy knight, the second for the black knight, the third for the elf archer — draw a vertical 2:3 card illustration. Full bleed, no border, no frame, no text.

ART STYLE
Rough pen-and-ink lines drawn in one or two confident strokes, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream, and the archer's muted dark emerald. Dark and grim, matching a rusted, blood-stained card frame. No gradients, no pastel, no pink.

SUBJECT
Low angle from slightly behind: the holy knight from the first image (long silver braid with a crimson ribbon, gray plate armor, a torn crimson cape with no emblem) strides forward at the head of the party, raising her sword with the winged guard and red gem high in her right hand. A step behind her on the right, the black knight from the second image: long straight black hair with blunt bangs, dark plate armor with pale filigree, her tall dark tower shield with a bouquet tied with a crimson ribbon, no other weapon. A step behind on the left, the elf archer from the third image: long wavy golden hair with a braided crown and white feathers, pointed ears, a white fur collar on a dark emerald cloak, a white bow and a quiver. Deep underground in a vast crypt: massive stone arches, walls of bone-filled niches, hanging iron lanterns. Ahead in the gloom stand a few hooded cultists in tattered dark robes.

FRAMING
Vertical 2:3. The three figures in the middle; the outer edges may be hidden by a card frame.

AVOID
A man, short hair, a cross or emblem on the cape, crimson threads on their wrists, sky, moon, outdoor buildings, an army, a dark red background with ink splatters and drips, text, letters, numbers, a border or frame, watermark, signature.
```
- 저장: `art/raw/vs_f/45_card_vanguard.webp` · 검수: 세 동료가 맞는지(1차 문제: 짧은 금발 남자).

### 46 감싸기
- 나중(새 덱에서 뺌). 첨부: ① 그림체 · ② [`46_card_cover_v1.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/46_card_cover_v1.webp)(구도) · ③ 32 F 수정본(브룬힐드) · 대화창 G
```
Redraw the second attached image as a vertical 2:3 card illustration in the art style of the first attached image. Keep the second image's subject and idea — the shield taking a heavy blow, sparks and petals — and extend the composition up and down to fill the taller frame. The knight peeking over the shield is Brunhild from the third attached image: long straight black hair with blunt bangs, amber eyes, a thin pale-gray scar under her right eye, dark plate armor with pale filigree, a crimson scarf. Use the first image only for the art style. Full bleed, no border, no frame, no text.

ART STYLE
Rough pen-and-ink lines drawn in one or two confident strokes, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream. Dark and grim, matching a rusted, blood-stained card frame. No gradients, no pastel, no pink.

SUBJECT
Her massive dark tower shield with pale thorn filigree and a bouquet of dried straw-colored wildflowers tied with a crimson ribbon takes a heavy blow, sparks and dry petals scattering, protecting a smaller figure behind it. A dark underground crypt behind.

FRAMING
Vertical 2:3. Keep the shield in the middle; the outer edges may be hidden by a card frame.

AVOID
Short pale hair, silver armor, a red scar, a weapon other than the shield, sky, moon, a dark red background with ink splatters and drips, text, letters, numbers, a border or frame, watermark, signature.
```
- 저장: `art/raw/vs_f/46_card_cover.webp` · 검수: 방패 든 사람이 브룬힐드인지(1차 문제).

---

## 7. UI
- 첨부: ① [`76_card_frames.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs_f/76_card_frames.webp)(재료 — 뼈·녹슨 쇠·가시·마른 피) · 대화창 H. 모두 글자 없음. 늘여 쓰는 것(대화창·선택지·지도 바탕·이름표)은 테두리 두께를 고르게.
- 검수 공통: 76·75와 같은 재료로 보이는지 · 초록 바탕이 고른지 · 가운데가 비었는지.

### 66 대화창
- VN 대사 글씨가 **어두운 갈색**(`vnBox.textColor #2b1a12`)이라 안쪽은 밝은 양피지로 둔다. 첨부: ① 76 F · ② [`66_ui_dialog_box.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/66_ui_dialog_box.webp)(배치) · 대화창 H(새로 시작)
```
Redraw the second attached image, a dialogue box for a visual novel, in the style and materials of the left card frame in the first attached image.

KEEP EXACTLY THE SAME AS THE SECOND IMAGE
The canvas size and proportions, the size and position of the box, its rectangular shape, and a border of even thickness all the way around so the box can be stretched. Everything outside the box stays plain flat pure green (#00FF00).

CHANGE
- Inside: aged tan parchment, a little more stained than the second image but still light enough for dark-brown text, plain and even, with nothing drawn in the middle.
- Border: like the left frame of the first image — a pale bone-and-stone rim wound with thorny brown briars, a few dried crimson drips, a small rusted rivet and one small dark crimson rose at each corner only. The same thickness on all four sides; nothing reaching far into the inside.
- Rough pen-and-ink lines with small ink blots; flat colors — cream bone, rust brown, deep crimson, charcoal. No gradients, no glossy shine.

AVOID
Text, letters, a different layout, ornaments in the middle of the edges, drips running into the inside, a dark inside, watermark, signature.
```
- 저장: `art/raw/vs_f/66_ui_dialog_box.webp` · 검수: 9조각(여백 95·62)으로 늘였을 때 모서리 장식이 찌그러지지 않는지 · 글씨가 읽히는 밝기.

### 72 턴 끝
- 첨부: 76 F · 대화창 H
```
Using the attached image only as a style reference for its materials (rusted iron, bone, thorny briars, dried crimson drips), draw a game UI button: a round seal of dark crimson wax, front view, flat, its edge slightly irregular with a few hardened drips, pressed with a ring of thorns around a plain, flat center where a short word will be placed later. Rough pen-and-ink lines with small ink blots, flat colors; a little light on the wax edge drawn as a flat shape, not a gradient. No text, no letters. Background: plain flat solid pure green (#00FF00), one even color, no shadow.
```
- 저장: `art/raw/vs_f/72_ui_end_turn.webp` · 검수: 가운데에 「턴 끝」 두 글자가 들어갈 만큼 비었는지.

### 73 행동 에너지
- 새 전투는 보석 여러 개(●●○)라 **켜짐·꺼짐 두 상태**를 한 장에. 첨부: 76 F · 대화창 H
```
Using the attached image only as a style reference for its materials (rusted iron, bone, thorny briars, dried crimson drips), draw two small game UI elements side by side with clear space between them, front view, flat, the same size: 1) a round setting of dark rusted iron wrought into thorns, holding a round deep-crimson gem that seems to glow faintly (energy available); 2) the same setting holding the same gem gone dark, dull and cracked (energy spent). Each gem's face is plain so a number can be placed on it later. Rough pen-and-ink lines with small ink blots, flat colors, no gradients. No text, no numbers. Background: plain flat solid pure green (#00FF00), one even color, no shadow.
```
- 저장: `art/raw/vs_f/73_ui_energy.webp` · 검수: 두 개가 같은 크기·같은 틀 · 꺼진 쪽이 한눈에 구분되는지.

### 69 지도 바탕
- 지금 지도는 어두운 판 위에 밝은 선·아이콘(`floor_map.gd`) → **어두운 양피지**. 지도 칸은 약 1380×1020(4:3 가까움). 첨부: 76 F · 대화창 H
```
Using the attached image only as a style reference for its materials (rusted iron, bone, thorny briars, dried crimson drips), draw the blank background of a dungeon map: one sheet of dark, aged parchment — deep brown, stained, a little burnt at the edges — filling the whole landscape image edge to edge (about 4:3), with a rusted nail through each corner. Faint old bloodstains and ink stains, soft folds, and a thin border of thorny briars of even thickness along all four edges. Nothing drawn in the middle: no map lines, no symbols. It must stay dark enough that pale lines and icons drawn on it later read clearly. Rough pen-and-ink lines, flat colors, no gradients. No text, no letters.
```
- 저장: `art/raw/vs_f/69_ui_map_parchment.webp` · 검수: 밝은 선(#d9b46a)을 얹어 읽히는지 · 가운데가 비었는지.

### 70 지도 아이콘
- 지도가 쓰는 11종(`game_data.gd` `roomTypes` — D의 8종에 캠프·갈림길·층 끝(발)을 더함). 받으면 잘라 쓴다. 첨부: 76 F · 대화창 H
```
Using the attached image only as a style reference for its materials, draw eleven small round map icons in two rows with clear space between them — six in the top row, five in the bottom row — all the same size, front view, flat. Each icon sits on a small round disc of dark charcoal with a rusted iron rim and four tiny thorns; the symbol is drawn in pale bone-cream ink. Top row: 1) two crossed swords (battle), 2) a horned skull (elite enemy), 3) a question mark (event), 4) a single candle flame (rest), 5) two crossed spears (training), 6) a small coffin with a coin on it (trade). Bottom row: 7) an open eye (omen), 8) a stone stairway going down (stairs), 9) a small campfire (camp), 10) a path splitting into three (crossroads hall), 11) a colossal bare footprint with five toes (the end of the floor). The discs of 1, 2 and 11 are deep crimson instead of charcoal. Rough pen-and-ink lines with small ink blots, flat colors, no gradients. No text, no numbers. Background: plain flat solid pure green (#00FF00), one even color, no shadow.
```
- 저장: `art/raw/vs_f/70_ui_map_icons.webp` · 검수: 11개·순서 · 지름 80px로 줄여도 읽히는지.

### 71 랜턴 촛불
- 첨부: 76 F · 대화창 H
```
Using the attached image only as a style reference for its materials, draw two small game UI icons side by side with clear space between them, front view, flat, the same size: 1) a single bone-white candle with drips of wax, burning with a small pale, warm flame; 2) the same candle burnt down to a stub, the flame out, a thin curl of smoke. Rough pen-and-ink lines with small ink blots, flat colors, no gradients, no glow. No text. Background: plain flat solid pure green (#00FF00), one even color, no shadow.
```
- 저장: `art/raw/vs_f/71_ui_lantern_candle.webp` · 검수: 불꽃이 초록 바탕에 번지지 않았는지(빛 번짐은 지우기 어렵다).

### 68 선택지 버튼
- 첨부: 66 F 결과 한 장 · 대화창 H(66 뒤)
```
Using the attached dialogue box as the reference for materials and border, draw a game UI element: a horizontal button, about 6:1, front view, flat. The same aged tan parchment inside (light enough for dark-brown text) and the same thin border of thorny briars over a pale bone-and-stone rim, of even thickness all around, with a tiny dark crimson rose at the left and right ends only. The center is empty. Rough pen-and-ink lines, flat colors, no gradients. No text, no letters. Background: plain flat solid pure green (#00FF00), one even color, no shadow.
```
- 저장: `art/raw/vs_f/68_ui_choice_button.webp` · 검수: 66과 테두리가 같은지.

### 96 HP 봉인
- 새 전투 카드의 HP 표시(동료 진홍·적 검정 — `battle-v2-spec.md` 2장), 노엘 HP. 첨부: 76 F · 대화창 H
```
Using the attached image only as a style reference for its materials (rusted iron, bone, thorny briars, dried crimson drips), draw two round wax seals side by side with clear space between them, front view, flat, the same size: 1) deep crimson wax, 2) black wax. Each is pressed with a thin ring of thorns around a plain, flat center where a number will be placed later; slightly irregular edges with a few hardened drips. Rough pen-and-ink lines with small ink blots, flat colors, no gradients, no glossy shine. No text, no numbers. Background: plain flat solid pure green (#00FF00), one even color, no shadow.
```
- 저장: `art/raw/vs_f/96_ui_hp_seals.webp` · 검수: 지름 40px로 줄여도 숫자 자리가 남는지 · 72(턴 끝 봉인)와 구분되는지.

### 67 이름표
- 나중(사용자 결정 대기 — 생략 추천). 첨부: 66 F 결과 · 대화창 H
```
Using the attached dialogue box as the reference for materials and border, draw a game UI element: a small horizontal name plate, about 4:1, front view, flat: the same aged tan parchment with the same thin thorny border of even thickness, and a short crimson ribbon tied at the left end. The center is empty. Rough pen-and-ink lines, flat colors, no gradients. No text, no letters. Background: plain flat solid pure green (#00FF00), one even color, no shadow.
```
- 저장: `art/raw/vs_f/67_ui_name_plate.webp` · 검수: 66과 테두리가 같은지.

---

## 8. 인물·컷인·타이틀

### 43 아이
- 첨부: ① 그림체 · ② [`43_buried_child.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/43_buried_child.webp)(디자인) · 대화창 I(새)
```
Using the first attached image for the art style and the second attached image for the child's design, draw a visual novel standing sprite of a thin village child of about eight who was buried alive in a coffin and has just been pulled out: knee-up, front view, in a dusty white nightgown, barefoot, dust on the face and hair, frightened but alive, clutching a small wooden charm on a crimson cord to the chest. Ignore the knight in the first image. Vertical 2:3 composition with a small even margin above the head.

ART STYLE
Match the first image: rough pen-and-ink lines drawn in one or two confident strokes, sometimes broken, with small ink blots; very little hatching; flat colors in graphite gray, deep crimson and cream only. No pink, no pastel, no blush, no gradients. Calm, natural eyes, not moe. A child's natural proportions, not chibi.

BACKGROUND
Plain flat solid pure green (#00FF00), one even color, no floor, no cast shadow, no green light or reflections on the child; the nightgown is opaque so no green shows through.

AVOID
Injuries, blood, the cord wound around the fingers, a dark red background with ink splatters and drips, soft digital-pencil lines drawn over and over, droopy moe eyes, text, watermark, signature.
```
- 저장: `art/raw/vs_f/43_buried_child.webp` · 검수: 잠옷이 초록에 물들지 않았는지 · 다치지 않은 모습.

### 61 컷인 성검 베기
- 첨부: ① 그림체(= 세라피나 F) · ② 30 F(결의한 얼굴) · 대화창 B
```
Using the first attached image for the art style and for Seraphina's design, and the second attached image for her face, draw a dramatic action cut-in for a card game: a wide 16:9 landscape, full bleed, no border, no text. A close, dynamic three-quarter front view of Seraphina mid-swing, slashing her sacred longsword in her right hand in a sweeping crimson arc from upper right to lower left, her silver braid with its crimson ribbon and her crimson cape flying, eyes fierce. She has a single small beauty mark under her left eye, gray plate armor, and bandages around her chest peeking out below the breastplate.

ART STYLE
Rough pen-and-ink lines drawn in one or two confident strokes, sometimes broken, with small ink blots; a few rough ink speed lines; light hatching only in the darkest shadows; flat colors — graphite gray, deep crimson, cream — on a dark charcoal background. No gradients, no pastel, no pink, no blush. Natural adult proportions.

AVOID
A second beauty mark, a crimson thread on her wrist, the sword in her left hand, a dark red background with ink splatters and drips, soft digital-pencil lines drawn over and over, droopy moe eyes, text, watermark, signature.
```
- 저장: `art/raw/vs_f/61_cutin_holy_slash.webp` · 검수: 칼이 오른손 · 점 하나.

### 62 컷인 저격
- 첨부: ① 그림체 · ② 36 F · 대화창 C
```
Using the first attached image for the art style and the second attached image for the character, draw a dramatic action cut-in for a card game: a wide 16:9 landscape, full bleed, no border, no text. A close, dynamic three-quarter front view of Elian, the elf archer of the second image, at full draw with her white longbow held in her left hand, the arrow just released, her eye narrowed along the shaft, her long golden hair, white feathers and dark emerald cloak swept back. Ignore the knight in the first image.

ART STYLE
Rough pen-and-ink lines drawn in one or two confident strokes, sometimes broken, with small ink blots; a few rough ink speed lines; light hatching only in the darkest shadows; flat colors — graphite gray, deep crimson, cream, and muted dark emerald — on a dark charcoal background. No gradients, no pastel, no pink, no blush. Natural adult proportions.

AVOID
Silver hair, a crimson cape, a crimson thread on her wrist, the bow in her right hand, a dark red background with ink splatters and drips, soft digital-pencil lines drawn over and over, droopy moe eyes, text, watermark, signature.
```
- 저장: `art/raw/vs_f/62_cutin_snipe.webp` · 검수: 활이 왼손 · 세라피나 요소(은발·붉은 망토)가 섞이지 않았는지.

### 63 컷인 감싸기
- 새 전투에서는 브룬힐드의 막기·되돌리기에. 첨부: ① 그림체 · ② 32 F 수정본 · 대화창 A
```
Using the first attached image for the art style and the second attached image for the character, draw a dramatic action cut-in for a card game: a wide 16:9 landscape, full bleed, no border, no text. A close, dynamic three-quarter front view of Brunhild, the black knight of the second image, stepping in front with her massive dark tower shield on her left arm as a heavy blow crashes into it, dried straw-colored wildflowers and sparks scattering, her long black hair and crimson scarf whipping in the impact, a sly, fearless half-smile, a thin pale-gray scar under her right eye. The shield is her only weapon. Ignore the knight in the first image.

ART STYLE
Rough pen-and-ink lines drawn in one or two confident strokes, sometimes broken, with small ink blots; a few rough ink speed lines; light hatching only in the darkest shadows; flat colors — graphite gray, deep crimson, cream — on a dark charcoal background. No gradients, no pastel, no pink, no blush. Natural adult proportions.

AVOID
A sword, a mace, a red scar, silver hair, a crimson thread on her wrist, the shield on her right arm, a dark red background with ink splatters and drips, soft digital-pencil lines drawn over and over, droopy moe eyes, text, watermark, signature.
```
- 저장: `art/raw/vs_f/63_cutin_cover.webp` · 검수: 방패가 왼팔 · 무기 없음 · 흉터 회색.

### 64 컷인 저주의 불꽃
- 첨부: ① 그림체 · ② [`39_stand_noel.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs_f/39_stand_noel.webp) · 대화창 J
```
Using the first attached image for the art style and the second attached image for the character, draw a dramatic action cut-in for a card game: a wide 16:9 landscape, full bleed, no border, no text. A close, dynamic three-quarter front view of Noel, the witch of the second image, thrusting her right hand forward, thin crimson threads wound around its fingers, releasing a curling crimson flame shaped like thorny vines; her long wine-red hair and the brim of her black witch hat swept by the blast, crimson eyes cold and sad. Her clothes are opaque smoky charcoal-brown. Ignore the knight in the first image.

ART STYLE
Rough pen-and-ink lines drawn in one or two confident strokes, sometimes broken, with small ink blots; a few rough ink speed lines; light hatching only in the darkest shadows; flat colors — graphite gray, deep crimson, cream, and her wine-red hair — on a dark charcoal background. No gradients, no pastel, no pink, no blush. Natural adult proportions.

AVOID
Threads on her left hand, long pointed nails, a dark red background with ink splatters and drips, soft digital-pencil lines drawn over and over, droopy moe eyes, text, watermark, signature.
```
- 저장: `art/raw/vs_f/64_cutin_curse_flame.webp` · 검수: 실이 오른손에만 · 배경이 검붉은 얼룩 바탕이 아닌지.

### 65 컷인 짓밟힘
- 첨부: ① 그림체 · ② 39 F · 대화창 J
```
Using the first attached image for the art style and the second attached image for the character, draw a dramatic action cut-in for a card game: a wide 16:9 landscape, full bleed, no border, no text. Noel, the witch of the second image, seen from a low three-quarter front angle, slams her open right hand downward, thin crimson threads around its fingers; above her, the vast shadow of a colossal bare foot comes crashing down onto the enemies in front of her, cracked stone and dust bursting upward. Ignore the knight in the first image.

ART STYLE
Rough pen-and-ink lines drawn in one or two confident strokes, sometimes broken, with small ink blots; a few rough ink speed lines; light hatching only in the darkest shadows; flat colors — graphite gray, deep crimson, cream, and her wine-red hair — on a dark charcoal background. No gradients, no pastel, no pink, no blush.

AVOID
Gore, bodies, threads on her left hand, a dark red background with ink splatters and drips, soft digital-pencil lines drawn over and over, droopy moe eyes, text, watermark, signature.
```
- 저장: `art/raw/vs_f/65_cutin_trample.webp` · 검수: 발 그림자가 발로 읽히는지.

### 74 타이틀
- 나중 — 이야기·로고가 정해진 뒤(`vs_assets_rest.md` 74). 지금은 19를 어둡게 쓰므로 19 F가 오면 타이틀도 F가 된다. 아래는 **로고 없는 배경 [제안]** — 쓸지는 사용자가 정한다.
- 첨부: ① 그림체 · ② 39 F · ③ 19 F 결과(장소) · 대화창 K(새)
```
Using the first attached image for the art style, the second for the witch Noel and the third for the place, draw a title-screen background for a dark fantasy card game: a wide 16:9 landscape, full bleed, no border, no text, no logo. Noel stands small and alone in the middle distance of the ruined underground hall, facing the viewer, a fan of old cards in her left hand, thin crimson threads hanging from the fingers of her right hand and trailing off into the dark. Behind her the crimson rose window glows. The upper third of the picture is dark and calm (a title will be placed there), and the lower middle is calm (menu buttons). Ignore the knight in the first image.

ART STYLE
Rough pen-and-ink lines drawn in one or two confident strokes, sometimes broken, with small ink blots; light hatching only in the deepest shadows; flat colors — charcoal and graphite gray, deep crimson, cream, and her wine-red hair. Dark and grim. No gradients, no pastel, no pink.

AVOID
Text, letters, a logo, other characters, the giant foot, sky, moon, a dark red background with ink splatters and drips, soft digital-pencil lines drawn over and over, droopy moe eyes, watermark, signature.
```
- 저장: `art/raw/vs_f/74_title.webp` · 검수: 위 1/3이 비어 제목(y 190~420)이 읽히는지.
