# 버티컬 슬라이스 그림 프롬프트 (ChatGPT, 그림체 D)

- 작성: 2026-11-21. 근거: [`../art-direction.md`](../art-direction.md)(그림체 D·캐릭터 묘사·ChatGPT 요령), [`../tutorial-script-vs.md`](../tutorial-script-vs.md) v3(장례 탑 1층), [`../vertical-slice.md`](../vertical-slice.md)(움직임 비교 시험).
- 순서: **1단계(움직임 비교 시험 + 전투 화면 목업)부터.** 1단계 결과로 전투 그림을 뽑는 방식이 정해진다.
- 공통 규칙
  - 첨부 [2026-11-22 고침]: **세라피나·배경·적·UI는 `reference/style/style_D_seraphina_anchor.webp` 한 장만**(기준 그림이 곧 그림체 D의 세라피나). **브룬힐드·엘리안·노엘은 각자의 그림체 D 시안 한 장만**(`style_D_brunhild_v5`·`style_D_elian_v1`·`style_D_noel_v1`) — 세라피나 기준 그림을 같이 붙이면 은발·붉은 망토가 섞일 수 있다. 애니메이션풍 `design_seraphina_v5_anime.webp`는 붙이지 않는다.
  - 캐릭터마다 **새 대화창**에서 시작한다. 같은 캐릭터의 포즈·표정 변형은 같은 대화창에서 결과 그림을 첨부해 "Edit this image"로.
  - 수정이 2~3번을 넘으면 얼굴·비율이 무너진다 → 새로 뽑는다.
  - 배경 제거용 단색: 초록(#00FF00). **엘리안은 초록 옷이라 마젠타(#FF00FF).** 받은 뒤 `tools/remove_bg.py`로 지운다.
  - 결과는 `art/raw/`에 원본, 검수 후 `game/assets/`로.

---

## 전체 목록 — 튜토리얼(장례 탑 1층) 기준, 번호 순서대로 뽑는다 [2026-11-22]
근거: 대본 v3에 나오는 장면·인물·카드·화면. 2·3층 그림은 튜토리얼이 끝난 뒤 따로 목록을 만든다. 세라피나 데스신 6컷은 이미 있다(`reference/deathscene/seraphina_*`).

| # | 그림 | 프롬프트 | 비고 |
|---|---|---|---|
| **1단계 — 움직임 비교 시험 (A·B·C 중 방식 결정)** ||||
| 1 | 세라피나 뒷모습 기본 | P01 | 시험 공통 바탕 |
| 2 | 세라피나 「성검 베기」 포즈 | P02 | 시험 A |
| 3 | 세라피나 「성검 베기」 6프레임 시트 | P03 | 시험 B |
| 4 | 세라피나 부위 분리 시트 | P04 | 시험 C |
| **2단계 — 전투 화면 목업 (1장을 완성본 품질로)** ||||
| 5 | 브룬힐드 뒷모습 기본 | P05 | |
| 6 | 엘리안 뒷모습 기본 | P06 | 마젠타 배경 |
| 7 | 전투 배경 — 장례 회랑 | P07 | |
| 8 | 광신도 | P08 | |
| 9 | 노엘의 손(1인칭) | P09 | |
| 10 | 카드 틀 | P10 | |
| 11 | 카드 뒷면(뒤집힌 카드) | P11 | 손패의 세라피나 죽음 카드 |
| 12 | 예고 아이콘 3종(공격·운명 공격·가려짐) | P12 | |
| **3단계 — 전투 동작 (1단계에서 고른 방식으로)** ||||
| 13 | 브룬힐드 「감싸기」 동작 | P05 아래 | |
| 14 | 엘리안 「저격」 동작 | P06 아래 | |
| **4단계 — 배경 (VN·전투)** ||||
| 15 | 곁방(캠프, 밤) | B01 | |
| 16 | 빈 곁방 | B02 | 15를 고쳐서 |
| 17 | 안치 홀(지도) | B03 | |
| 18 | 계단 앞 홀 | B04 | |
| 19 | 가장 깊은 곳 | B05 | 광신도·보스 전투 겸용 |
| 20 | 광신도 기도실 | B06 | 전투 배경 겸용 |
| 21 | 무덤지기의 방 | B07 | 강적 전투 배경 겸용 |
| 22 | 순장된 자의 방 | B08 | |
| 23 | 핏자국 통로 끝(죽은 마녀) | B09 | CG |
| 24 | 촛불 예배당 | B10 | |
| 25 | 무너진 훈련장 | B11 | |
| 26 | 묘지기의 좌판 | B12 | CG |
| 27 | 발자국 방 | B13 | |
| **5단계 — 스탠딩·표정** ||||
| 28~31 | 세라피나 기본(calm) + smile·determined·shocked | 스탠딩 | |
| 32~35 | 브룬힐드 기본(smirk) + stern·shocked·grief | 스탠딩 | |
| 36~38 | 엘리안 기본(cold) + shocked·grief | 스탠딩 | 마젠타 배경 |
| 39 | 노엘 기본 | 스탠딩 | |
| **6단계 — 적·인물** ||||
| 40 | 무덤지기(강적) | 적·인물 | |
| 41 | 거대한 발(보스) | 적·인물 | |
| 42 | 묘지기(상인) | 적·인물 | B12에 들어가면 생략 가능 |
| 43 | 아이(순장된 자) | 적·인물 | |
| **7단계 — 카드 그림 16장** ||||
| 44~59 | 성검 베기 · 선봉 · 감싸기 · 방패 강타 · 저격 · 견제 사격 · 저주의 불꽃 · 운명 전가 · 대신 받기 · 죽음의 예지 · 상처 · 짓밟힘 · 부러진 성검 · 이름 없는 마녀의 카드 · 작은 손의 부적 · 용사의 죽음 | 카드 그림 | 「전사의 죽음」(브룬힐드)은 2층 목록에서 |
| **8단계 — 컷인 5장** ||||
| 60~64 | 성검 베기 · 저격 · 감싸기 · 저주의 불꽃 · 짓밟힘 | 컷인 | |
| **9단계 — UI** ||||
| 65 | 대화창 | UI | |
| 66 | 이름표 | UI | |
| 67 | 선택지 버튼 | UI | |
| 68 | 지도 바탕(양피지) | UI | |
| 69 | 지도 아이콘 7종 | UI | |
| 70 | 랜턴 촛불 | UI | |
| 71 | 턴 종료 버튼 | UI | |
| 72 | 에너지 표시 | UI | |
| 73 | 타이틀 | — | 이야기·로고가 정해진 뒤 |

- 합계 72장(+ 타이틀). 1단계 결과에 따라 13·14번과 컷인의 방식이 바뀔 수 있다.

---

## 1단계 — 움직임 비교 시험 + 전투 화면 목업

### P01 세라피나 뒷모습 — 기본 (움직임 시험 A·B·C 공통 바탕)
- 첨부: `style_D_seraphina_anchor.webp` · 새 대화창
```
Using the attached image as the reference for both the art style and the character design, draw a single full-body rear view of Seraphina for a card game battle screen.

Art style: a dark fairy-tale picture book illustration — delicate, slightly rough hand-drawn ink linework with faded watercolor washes in bone white, ash gray and sepia; the only vivid color is deep crimson, used sparingly. Match the attached reference exactly in linework and palette. Natural adult proportions, about 7.5 heads tall. Not anime, not chibi.

Character: Seraphina, a beautiful holy knight: silver-white plate armor with gold filigree, a bare waist (the breastplate ends below the chest), off-white bandages wrapped from her waist over her hips to the very top of her thighs like short bandage shorts, bare mid-thighs, armored greaves from just above the knees; a long silver braid with a crimson ribbon bow, a crimson cape and a crimson tabard with a gold cross, a sacred longsword with a winged gold guard, a red gem and a crimson ribbon.

Pose and camera: seen directly from behind, the camera just behind her and slightly above head height, looking a little downward. She faces away from the viewer toward an enemy in the distance, in a ready battle stance, the sacred longsword held low in her right hand, the cape hanging down her back. Her face is not visible. Vertical 2:3 composition, full figure from head to feet with a small even margin.

Background: plain flat solid pure green (#00FF00), one even color, no paper texture, no gradient, no floor, no cast shadow; no green reflections on the figure.

Avoid: face visible, looking back over the shoulder, extra fingers, cape on one shoulder only, heavy magic effects, text, watermark, signature.
```

### P02 세라피나 뒷모습 — 「성검 베기」 공격 포즈 (시험 A: 포즈 2장 + 코드 연출)
- 첨부: P01 결과 · 같은 대화창
```
Edit this image: keep the same character, the same art style, the same camera angle, the same scale and the same position in the frame. Change only the pose: she lunges forward and swings the sacred longsword diagonally from upper right to lower left at the peak of the strike, her weight on the front foot, the braid and the crimson cape flaring behind her from the motion. Her face is still not visible. Keep the plain flat pure green (#00FF00) background.
```

### P03 세라피나 「성검 베기」 프레임 시트 (시험 B)
- 첨부: P01 결과 · 같은 대화창
```
Using this image as the exact character and style reference, create a horizontal sprite sheet of 6 animation frames of the same rear view performing one sword slash.

Layout: one row of 6 equal cells, the character at the same scale and on the same ground line in every cell, the camera identical in every cell, nothing crossing cell borders. Frames: 1 ready stance, 2 raising the sword over the right shoulder, 3 wind-up with weight shifting back, 4 the diagonal slash from upper right to lower left at full speed, 5 follow-through with the cape flaring, 6 returning to the ready stance.

Keep the face not visible in all frames. Identical armor, bandages, braid, ribbon, cape and sword in every frame. Background: plain flat solid pure green (#00FF00), no grid lines, no numbers, no text.
```

### P04 세라피나 부위 분리 시트 (시험 C: 뼈대 애니메이션)
- 첨부: P01 결과 · 같은 대화창
```
Using this image as the exact character and style reference, create a cutout-animation parts sheet of the same rear view, for rigging in a 2D game engine.

Draw each body part as a separate piece, laid out with clear empty space between the pieces (no piece touching another): head with the braid and ribbon; torso with the armor and tabard; the cape as one whole piece, including the part that is normally hidden behind the body; right upper arm; right forearm with the hand; left upper arm; left forearm with the hand; the sacred longsword alone; right thigh; right lower leg with the greave; left thigh; left lower leg with the greave. Paint the areas that would be hidden by overlap completely, so parts can rotate at the joints without gaps. All pieces at the same scale as each other, in the same style and colors.

Background: plain flat solid pure green (#00FF00), no labels, no text.
```

### P05 브룬힐드 뒷모습 — 기본
- 첨부: `style_D_brunhild_v5.webp` · 새 대화창
```
Using the attached image as the reference for both the art style and the character design, draw a single full-body rear view of Brunhild for a card game battle screen.

Art style: a dark fairy-tale picture book illustration — delicate, slightly rough hand-drawn ink linework with faded watercolor washes in bone white, ash gray and sepia; the only vivid color is deep crimson, used sparingly. Match the attached reference exactly in linework and palette. Natural adult proportions, about 7.5 heads tall. Not anime, not chibi.

Character: Brunhild, the tallest of the party, a black-knight beauty with long straight jet-black hair and blunt bangs (hime cut); black lacquered plate armor with silver wildflower-and-thorn filigree, rose-petal pauldrons, a flaring armored skirt, crimson lining, sash and scarf; a massive black tower shield with a bouquet of dried wildflowers and a crimson ribbon tied to it, on her left arm; a flanged mace in her right hand.

Pose and camera: seen directly from behind, the camera just behind her and slightly above head height, looking a little downward. She faces away toward an enemy in the distance, the tower shield raised in front of her in a guarding stance. Her face is not visible. Vertical 2:3 composition, full figure from head to feet with a small even margin.

Background: plain flat solid pure green (#00FF00), one even color, no paper texture, no gradient, no floor, no cast shadow; no green reflections on the figure.

Avoid: face visible, looking back, shield on the right arm, short hair, extra fingers, text, watermark, signature.
```
- 감싸기 동작(시험에서 A가 뽑히면): 같은 대화창에서 `Edit this image: same character, camera, scale and position; change only the pose: she steps sideways and plants the tower shield firmly in front of her with both hands, bracing against a heavy blow, the scarf and hair swept by the impact. Keep the pure green background.`

### P06 엘리안 뒷모습 — 기본
- 첨부: `style_D_elian_v1.webp` · 새 대화창
```
Using the attached image as the reference for both the art style and the character design, draw a single full-body rear view of Elian for a card game battle screen.

Art style: a dark fairy-tale picture book illustration — delicate, slightly rough hand-drawn ink linework with faded watercolor washes in bone white, ash gray and sepia; the only vivid color is deep crimson, used sparingly, plus the deep emerald of her cloak. Match the attached reference exactly in linework and palette. Natural adult proportions, about 7.5 heads tall. Not anime, not chibi.

Character: Elian, an elven noble archer: golden-blonde hair in a crown braid with white feathers and pearls, a gold leaf circlet, pointed elf ears; a deep emerald velvet cloak with a white fur collar, an ivory lace bodice, a crimson sash, a short layered lace skirt to mid-thigh, over-the-knee boots, long gloves; a white longbow with gold inlay.

Pose and camera: seen directly from behind, the camera just behind her and slightly above head height, looking a little downward. She faces away toward an enemy in the distance, holding the white longbow at her side with an arrow ready. Her face is not visible, only the tip of one elf ear. Vertical 2:3 composition, full figure from head to feet with a small even margin.

Background: plain flat solid pure magenta (#FF00FF), one even color, no paper texture, no gradient, no floor, no cast shadow; no magenta reflections on the figure.

Avoid: face visible, looking back, extra fingers, text, watermark, signature.
```
- 저격 동작: 같은 대화창에서 `Edit this image: same character, camera, scale and position; change only the pose: she draws the white longbow to full draw, aiming straight ahead and slightly upward, the cloak swinging from the turn of her body. Keep the pure magenta background.`

### P07 전투 배경 — 장례 회랑
- 첨부: `style_D_seraphina_anchor.webp` · 새 대화창
```
Using the attached image only as an art style reference, draw a background for a card game battle screen. 16:9 landscape, full bleed, no border, no people, no text.

Art style: a dark fairy-tale picture book illustration — delicate, slightly rough ink linework with faded watercolor washes in bone white, ash gray and sepia; the only vivid color is deep crimson, used sparingly; subtle parchment texture.

Scene: a long funeral corridor deep underground, inside a funeral tower that grows downward into the earth. Both walls are lined with niches, each holding a stone coffin, stacked several rows high; every coffin lid has been pushed open from the inside. Dripping candle stubs on the ledges, scattered dried funeral flowers, a few crows perched on the coffins. The corridor recedes into darkness at the center.

Composition for gameplay: the camera stands at about human eye height looking straight down the corridor. Keep the lower third of the image calm and dark (the player's hand of cards covers it) and leave open floor space in the middle distance where three enemies will stand.
```

### P08 광신도 (적)
- 첨부: `style_D_seraphina_anchor.webp` · 새 대화창
```
Using the attached image only as an art style reference, draw a single enemy for a card game: a cultist of a funeral tower. Vertical 2:3 composition, full figure from head to feet with a small even margin, front view, standing slightly hunched and facing the viewer, menacing but still.

Art style: a dark fairy-tale picture book illustration — delicate, slightly rough ink linework with faded watercolor washes in bone white, ash gray and sepia; the only vivid color is deep crimson.

Design: a gaunt figure in a long ash-gray funeral shroud, the hood pulled low so the face is lost in shadow except a thin mouth; strips of burial linen wrapped around the hands; a rusted grave-digger's sickle in one hand; a crimson cord tied around the waist with small bone charms hanging from it.

Background: plain flat solid pure green (#00FF00), one even color, no paper texture, no floor, no cast shadow; no green reflections on the figure.
```

### P09 노엘의 손 (1인칭, 전투 화면 아래)
- 첨부: `style_D_noel_v1.webp` · 새 대화창
```
Using the attached image as the reference for both the art style and the character, draw the first-person hands of Noel the witch for the bottom of a card game screen, as if the viewer is Noel looking down at her own hands.

Art style: a dark fairy-tale picture book illustration — delicate, slightly rough ink linework with faded watercolor washes; the only vivid color is deep crimson.

Content: two slender pale hands seen from the viewer's own point of view, entering from the bottom edge. The left hand holds a fanned spread of five old blank playing cards (blank faces, no symbols). The right hand is raised slightly, empty, ready to pick a card. Black lace fingerless gloves, the cuffs of torn black bell sleeves at the wrists, a few thin crimson threads wound around the fingers of the right hand and trailing off upward out of frame.

Composition: 16:9 landscape, the hands occupy only the lower half; the upper half is empty. Background: plain flat solid pure green (#00FF00), no shadow, no green reflections.
```

### P10 카드 틀
- 첨부: `style_D_seraphina_anchor.webp` · 새 대화창
```
Using the attached image only as an art style reference, design an empty card frame for a dark fantasy card game. Vertical card, 5:7 ratio, centered, front view, flat (no perspective, no shadow).

Art style: a dark fairy-tale picture book: delicate ink linework, faded watercolor, parchment; the only vivid color is deep crimson.

Frame: an aged parchment card with a thin inked border of thorny vines and small crimson roses; a round cost medallion at the top-left corner (empty, no number); an empty art window in the upper 55%; an empty ribbon banner below the window for the card name; an empty text area at the bottom. No text, no numbers, no letters anywhere.

Outside the card, the background is plain flat solid pure green (#00FF00).
```

### P11 카드 뒷면
- 첨부: `style_D_seraphina_anchor.webp` · P10과 같은 대화창
```
Using the attached image only as an art style reference, design the back side of a card for the same dark fantasy card game. Vertical card, 5:7 ratio, centered, front view, flat (no perspective, no shadow).

Art style: a dark fairy-tale picture book: delicate ink linework, faded watercolor, parchment; the only vivid color is deep crimson.

Design: aged dark parchment with a thin inked border of thorny vines; in the center a closed eye drawn in ink, with a single crimson thread wound around the card several times and tied in a small knot. No text, no numbers, no letters.

Outside the card, the background is plain flat solid pure green (#00FF00).
```

### P12 예고 아이콘 3종
- 첨부: `style_D_seraphina_anchor.webp` · 새 대화창(이후 UI도 이 대화창에서)
```
Using the attached image only as an art style reference, draw three small game UI icons in one row with clear space between them, each inside a small round parchment disc with a thin inked border: 1) a single dagger (a normal attack), 2) a spear wrapped in a crimson thread (a fated attack), 3) an ink blot hiding a symbol, with a question mark (a hidden intent). Delicate ink linework, faded watercolor, the only vivid color deep crimson. No text, no numbers. Background: plain flat solid pure green (#00FF00).
```

---

## 2단계 — 튜토리얼(장례 탑 1층) 나머지

배경은 모두 P07과 같은 방식(16:9, 사람 없음, 첨부는 기준 그림만, 같은 대화창에서 이어 뽑아도 됨). 아래 `Scene:` 문단만 바꿔 P07 프롬프트에 넣는다. 화면 아래 1/3은 어둡고 차분하게(대화창·손패 자리).

| 번호 | 장면 | Scene 문단 |
|---|---|---|
| B01 | 곁방(캠프, 밤) | `A small antechamber at the entrance of a funeral tower, once a resting room for funeral priests: stone benches, a cold altar for shrouds, four bedrolls laid around a small campfire in the middle of the floor, a heavy door at the left, crows on a ledge. Warm firelight is the only light.` |
| B02 | 빈 곁방 | B01 결과를 첨부해 `Edit this image: the same room; the fire is smaller and dimmer, one of the four bedrolls is still spread out but empty, the other three are rolled up. Change nothing else.` |
| B03 | 안치 홀(지도) | `A great round hall underground, its walls lined with coffins stacked up to the ceiling, several dark archways leading off in different directions, a single shaft of pale light from far above.` |
| B04 | 계단 앞 홀 | `A spiral staircase of worn stone descending into darkness, candles along the inner wall, faint red glow rising from far below.` |
| B05 | 가장 깊은 곳 | `The deepest hall of the floor: a vast circular chamber with a bottomless pit in the middle, its rim carved with funeral prayers, cultists' candles around the edge, a cracked dome high above lost in darkness.` (보스 전투도 같은 배경) |
| B06 | 광신도 기도실 | `A small prayer room around a hole in the floor that drops into darkness, prayer mats and bone charms around it, candle wax pooled on the stones.` |
| B07 | 무덤지기의 방 | `A narrow vault crowded with broken coffin lids leaning on the walls, a heavy iron grave-keeper's lantern hanging from a chain.` |
| B08 | 순장된 자의 방 | `A cramped burial chamber with a single wooden coffin in the center, its lid nailed shut with many long iron nails.` |
| B09 | 핏자국 통로 끝 | `A dead-end passage where a dried trail of blood ends at the wall; a dead witch sits against the wall, her face completely hidden under a wide-brimmed witch hat, crimson threads wound around her fingers with the cut ends trailing on the floor, burnt playing cards scattered around her.` (사람이 있는 CG — 피가 걸리면 "No gore" 추가) |
| B10 | 촛불 예배당 | `A tiny chapel where a few candles are still burning on a small altar, a funeral wreath left on a bench, a quiet and almost warm place.` |
| B11 | 무너진 훈련장 | `A collapsed guard training yard inside the tower: broken wooden practice dummies, a rack of rusted spears, cracked flagstones, rubble from a fallen ceiling.` |
| B12 | 묘지기의 좌판 | `A coffin used as a market stall, covered with candles, old cards and small bottles; an old grave-keeper merchant sits behind it in a hooded coat, half in shadow.` (사람이 있는 CG) |
| B13 | 발자국 방 | `A room whose stone floor has sunk in the exact shape of a colossal bare footprint with clear toe marks; inside the print lie flattened, crushed suits of armor of a lost expedition.` |

### 스탠딩 (VN 장면) — 캐릭터마다 기본 1장 + 표정
- 첨부: 세라피나는 기준 그림, 나머지는 각자의 그림체 D 시안 한 장 · 캐릭터마다 새 대화창
```
Using the attached image as the reference for both the art style and the character design, draw a visual novel standing sprite of [CHARACTER]. Knee-up view, facing three-quarters toward the viewer, relaxed neutral pose, [EXPRESSION]. Vertical 2:3 composition with a small even margin above the head.

Art style: a dark fairy-tale picture book illustration — delicate, slightly rough hand-drawn ink linework with faded watercolor washes in bone white, ash gray and sepia; the only vivid color is deep crimson. Natural adult proportions, about 7.5 heads tall. Not anime, not chibi.

Character: [ENGLISH DESCRIPTION FROM art-direction.md]

Background: plain flat solid pure green (#00FF00) (Elian: pure magenta #FF00FF), one even color, no border, no paper texture, no floor, no cast shadow.
```
- `[CHARACTER]`·`[ENGLISH DESCRIPTION]`은 [`../art-direction.md`](../art-direction.md) 3장 EN 문단을 그대로.
- 기본 표정(`[EXPRESSION]`): 세라피나 `a calm, confident expression` · 브룬힐드 `a sly half-smile` · 엘리안 `a cold, dignified, serene expression with clear open eyes` · 노엘 `a quiet, guarded expression`.
- 표정 변형: 기본 결과를 첨부해 같은 대화창에서 `Edit this image: change only the facial expression to [표정]. Keep everything else exactly the same.`
  - 세라피나: smile `a warm smile` · determined `a determined, focused look` · shocked `a shocked, wide-eyed look`
  - 브룬힐드: stern `a stern, serious look` · shocked `a shocked look` · grief `grief, eyes lowered, jaw clenched`
  - 엘리안: shocked `a shocked look` · grief `grief, tears held back`
  - 노엘: 추가 표정은 대본에 필요할 때.

### 적·인물
같은 방식(P08 틀, 초록 배경). `Design:` 문단만 바꾼다.
- 무덤지기(강적): `A towering grave-keeper whose body is armored with nailed-on coffin lids like plates, a huge iron shovel as a weapon, a lantern chained to the waist, the face hidden behind a coffin-wood mask with one crimson eye-slit.`
- 묘지기(상인): `An old, small grave-keeper in a patched hooded coat, a crooked smile, holding a candle and a fan of old cards, not threatening.` (정면, 무릎 위)
- 아이(순장된 자): `A thin village child in a nightgown, barefoot, dust on the face, clutching a small charm.` (정면, 무릎 위)
- 거대한 발(보스): `A colossal bare humanoid foot descending from above, cropped by the top edge, gray cracked stone-like skin, anatomically shaped toes; nothing else.` (가로 16:9, 초록 배경)

### 카드 그림 (P10 틀 안에 넣을 그림)
- 첨부: 기준 그림 · 같은 대화창에서 이어 뽑기
```
Using the attached image only as an art style reference, draw a small square card illustration (1:1), full bleed, no border, no text: [CARD SUBJECT]. Art style: a dark fairy-tale picture book — delicate ink linework, faded watercolor in bone white, gray and sepia, the only vivid color deep crimson.
```
- `[CARD SUBJECT]` 목록(1층): 성검 베기 `a sacred longsword with a winged gold guard cutting a crimson arc` · 선봉 `a silver-armored knight stepping forward with a sword raised` · 감싸기 `a black tower shield with dried wildflowers taking a blow` · 방패 강타 `a black tower shield slamming forward` · 저격 `a white longbow at full draw, a single arrow` · 견제 사격 `three arrows in flight` · 저주의 불꽃 `a pale hand releasing a crimson flame` · 운명 전가 `a crimson thread being pulled from one figure to another` · 대신 받기 `a witch's hand catching a blade` · 죽음의 예지 `a witch's eye reflected in a card` · 상처 `a torn bandage stained crimson` · 짓밟힘 `a colossal footprint pressed into stone` · 부러진 성검 `a broken sacred longsword with a crimson ribbon` · 이름 없는 마녀의 카드 `a single unburnt card among burnt ones` · 작은 손의 부적 `a small child's hand holding a charm` · 용사의 죽음 `a silver braid with a crimson ribbon lying under a vast shadow`

### 컷인 (대표 카드를 낼 때, 가로 띠)
- 첨부: 세라피나·짓밟힘은 기준 그림, 감싸기는 브룬힐드 시안, 저격은 엘리안 시안, 저주의 불꽃은 노엘 시안 · 같은 캐릭터는 스탠딩과 같은 대화창
```
Using the attached image as the reference for both the art style and the character, draw a dramatic action cut-in for a card game: a wide 21:9 horizontal strip, a close, dynamic shot of [ACTION]. Delicate, slightly rough ink linework with faded watercolor washes; strong ink speed lines; the only vivid color deep crimson. Full bleed, no border, no text.
```
- `[ACTION]`: 성검 베기 `Seraphina slashing her sacred longsword in a crimson arc, her braid and cape flying` · 저격 `Elian at full draw, the arrow released, her eye narrowed along the shaft` · 감싸기 `Brunhild stepping in front with her black tower shield as a blow crashes into it, dried wildflowers scattering` · 저주의 불꽃 `Noel's pale hand releasing a crimson flame, crimson threads around her fingers` · 짓밟힘 `the silhouette of a colossal foot slamming down, cracked stone and dust bursting upward` (짓밟힘은 배경을 비워 노엘 손만 넣어도 됨)

### UI (1장씩, 초록 배경, 글자 없음)
- 대화창 `a wide dark parchment dialogue box with a thin thorny-vine border and small crimson roses at the corners`
- 이름표 `a small parchment name plate with a crimson ribbon`
- 선택지 버튼 `a horizontal parchment button with a thin inked border`
- 지도 아이콘 7종(한 장에 한 줄로) `seven small round inked icons in one row: crossed swords, a skull, a question mark, a candle flame, two crossed spears, a coffin with coins, an eye`
- 지도 바탕 `a blank sheet of aged parchment, 16:9, faint ink stains and a thin thorny-vine border, nothing drawn in the middle` (배경은 초록 대신 종이 자체로 꽉 채움)
- 랜턴 촛불 `a small black iron lantern holding four white candles, front view`
- 턴 종료 버튼 `a round crimson wax seal with a thorn pattern, front view`
- 에너지 표시 `an empty round black iron frame with thorns, holding a crimson gem in the center, front view`
- 각 문장 앞에 `Using the attached image only as an art style reference, draw a game UI element: ` 를, 뒤에 `No text, no letters. Background: plain flat solid pure green (#00FF00).` 를 붙인다.

### 타이틀 (스팀 상점 그림 겸용) — 마지막에
- 이야기·로고가 정해진 뒤 따로 짠다.
