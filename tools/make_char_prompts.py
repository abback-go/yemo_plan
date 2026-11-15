# 캐릭터 시트·단일 뷰·표정 프롬프트 생성기 (docs/prompts/01~04_*.txt 생성). 사용법: python3 tools/make_char_prompts.py docs/prompts
# 생성 후 각 파일 3번째 줄은 sed로 안내 문구로 바꿔 왔음(커밋 기록 참고). 앵커를 바꿀 땐 이 파일의 anchor를 고친 뒤 다시 생성.
import os, sys
OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)

STYLE_SHEET = ("Anime illustration style, dark fantasy. Detailed cel-shaded rendering with soft painterly lighting "
"and fine, clean linework, matching a gloomy ruined gothic cathedral world. Cold blue-gray palette with a single "
"deep red accent. Dark desaturated blue-gray studio background with a subtle floor reflection, cool rim lighting.")

STYLE_SINGLE = ("Anime illustration style, dark fantasy. Detailed cel-shaded rendering with soft painterly lighting "
"and fine, clean linework. Cold blue-gray palette with a single deep red accent. Soft cool key light from the front, "
"gentle blue-gray rim light.")

COMMON_AVOID = ("extra fingers, fused or missing fingers, asymmetric face, inconsistent outfit or colors between views, "
"misspelled text, cropped or missing views, extra characters, watermark, signature, chibi, pixel art, 3D render, "
"photorealistic photo, bright saturated colors on the character")

C = [
 dict(key="seraphina", ko="용사 세라피나", name="SERAPHINA", role="THE HERO",
  bg="plain flat solid pure green background (#00FF00, one even color, no gradient, no floor, no cast shadow) for easy background removal; no green light or green reflections on the character",
  face_side="straight",
  anchor=("Seraphina, the hero and leader of an adventuring party: an adult woman in her late twenties, tall and athletic, "
  "with a calm, confident face and steel-blue eyes. Her presence feels overwhelmingly strong and reliable. Long silver hair "
  "gathered into a high ponytail that falls as one thick braid down her back, tied at the crown with a deep red ribbon bow, "
  "a few loose strands framing her face. Polished "
  "silver plate armor with engraved gold trim over a dark gray gambeson, layered pauldrons, plated gauntlets and armored "
  "boots with low heels. A long deep red cape, slightly tattered at the hem, fastened at both shoulders. A sacred longsword with a "
  "cross-shaped silver guard and a faint pale-white glow along the blade, carried in a scabbard on her left hip."),
  callouts=[("RED RIBBON","deep red ribbon bow on the single braided silver ponytail"),
            ("PLATE ARMOR","silver plate with engraved gold trim"),
            ("SACRED SWORD","longsword with a cross guard and a faint pale glow")],
  avoid_extra="cape on one shoulder only, sword on the right hip, heavy magical effects or aura around her, helmet covering her hair",
  front_expr="a calm, confident expression with a slight closed-mouth smile",
  exprs=("calm","gentle smile","determined","shocked"),
  edits=[
   ("뷰마다 망토·리본·칼 위치가 다를 때",
    "Edit this sheet: make the side and back views match the front view exactly — the same deep red ribbon bow on the braided silver ponytail, the same long deep red cape fastened at both shoulders, and the sword scabbard on her left hip. Change nothing else."),
   ("이름 글자가 깨졌을 때",
    "Edit only the large name text at the top left so it reads exactly \"SERAPHINA\" with the subtitle \"THE HERO\". Change nothing else."),
   ("칼이 너무 마법처럼 빛날 때",
    "Make the sword glow much subtler: only a faint pale-white glow along the blade edge, with no aura, sparks or light effects around her. Change nothing else."),
  ]),
 dict(key="brunhild", ko="전사 브룬힐드", name="BRUNHILD", role="THE SHIELD",
  bg="plain flat solid pure green background (#00FF00, one even color, no gradient, no floor, no cast shadow) for easy background removal; no green light or green reflections on the character",
  face_side="straight",
  anchor=("Brunhild, the shield-bearer and protector of an adventuring party: a tall, broad-shouldered, muscular adult woman "
  "in her thirties, the largest member of the party. Short, shaggy ash-white hair, a stern weathered face with a pale scar "
  "running down her right cheek from just below the eye, gray eyes. Heavy dark iron plate armor, dented and scratched, over "
  "chain mail, with a tattered deep red scarf around her neck and a faded deep red tabard bearing a gold cross emblem. "
  "A massive iron tower shield almost as tall as her shoulders, its face scarred with claw marks and an engraved cross "
  "crest, strapped to her left arm, a short flanged mace hanging at her left hip beside the shield, and armored boots "
  "with low heels."),
  callouts=[("TOWER SHIELD","huge iron shield with claw marks and a worn crest"),
            ("SCAR","pale scar down her right cheek"),
            ("MACE","short flanged iron mace")],
  avoid_extra="small round shield, shield on the right arm, long hair, scar on the left cheek, slim or petite body, shiny new armor",
  front_expr="a stern but kind expression, mouth closed",
  exprs=("stern","faint smile","pained","grief"),
  edits=[
   ("방패가 작거나 위치가 바뀔 때",
    "Edit this sheet: make the tower shield much larger in every view — its top reaches her shoulders and it covers most of her body — and keep it strapped to her left arm. Change nothing else."),
   ("이름 글자가 깨졌을 때",
    "Edit only the large name text at the top left so it reads exactly \"BRUNHILD\" with the subtitle \"THE SHIELD\". Change nothing else."),
   ("체격이 가냘프게 나올 때",
    "Make her clearly taller and more muscular than an average woman, with broad shoulders and thick arms, while keeping the same face, scar, hair and armor. Change nothing else."),
  ]),
 dict(key="elian", ko="궁수 엘리안", name="ELIAN", role="THE ARCHER",
  bg="plain flat solid pure magenta background (#FF00FF, one even color, no gradient, no floor, no cast shadow) for easy background removal; no magenta light or magenta reflections on the character",
  face_side="straight",
  anchor=("Elian, the archer of an adventuring party: an adult female elf with long pointed ears, a slender build, green eyes "
  "and a soft, gentle face. Blonde hair worn in a crown braid, with the rest falling long, loose and wavy down to her hips, "
  "tied at the back of the head with a dark green ribbon bow. A dark green hooded cloak with gold leaf embroidery along its "
  "edges, fastened with a small gold leaf-shaped brooch, worn over brown leather armor with buckled straps, a cream "
  "undershirt and a deep red sash at the waist, with brown leather bracers and tall brown lace-up leather boots with low "
  "heels. A quiver of white-feathered arrows on her back over her right shoulder and a recurve longbow of dark wood in "
  "her left hand."),
  callouts=[("GREEN RIBBON","dark green ribbon bow at the back of the crown braid"),
            ("CLOAK","dark green hooded cloak with gold leaf embroidery"),
            ("BOW & QUIVER","dark wood recurve bow, white-feathered arrows")],
  avoid_extra="short hair, round human ears, bow drawn and aiming, modern clothing, hood pulled up over her head",
  front_expr="a soft, gentle closed-mouth smile",
  exprs=("gentle smile","focused","shocked","sorrow"),
  edits=[
   ("귀·리본이 빠질 때",
    "Edit this sheet: make sure every view shows her long pointed elf ears and the dark green ribbon bow on her blonde crown braid. Change nothing else."),
   ("이름 글자가 깨졌을 때",
    "Edit only the large name text at the top left so it reads exactly \"ELIAN\" with the subtitle \"THE ARCHER\". Change nothing else."),
   ("후드를 뒤집어썼을 때",
    "Lower the hood so it rests on her shoulders and her blonde braided hair is fully visible in every view. Change nothing else."),
  ]),
 dict(key="noel", ko="마녀 노엘", name="NOEL", role="THE WITCH",
  bg="plain flat solid pure green background (#00FF00, one even color, no gradient, no floor, no cast shadow) for easy background removal; no green light or green reflections on the character",
  face_side=None,
  anchor=("Noel, the witch of an adventuring party, who secretly foresees how each of her companions will die: an adult woman "
  "in her mid-twenties, slight and thin, with pale skin and tired, half-lidded deep red eyes with faint dark circles beneath "
  "them. Long straight black hair falling past her waist, with messy bangs falling over her eyes. A worn, hooded black robe "
  "with the hood down, layered tattered hems and very wide ragged sleeves, a simple brown leather belt with a long hanging "
  "strap, plain brown boots, no jewelry. Around her neck hangs a small bundle of old cards tied together with a faded red "
  "string. Her expression is quiet and withdrawn; she looks more like a mourner than a mage."),
  callouts=[("CARD BUNDLE","small bundle of old cards tied with a faded red string"),
            ("TIRED EYES","deep red eyes with faint dark circles"),
            ("BLACK ROBE","worn hooded black robe with tattered hems")],
  avoid_extra="pointed witch hat, colorful or decorated robe, glowing magic effects, staff or wand, cheerful smile",
  front_expr="a quiet, withdrawn expression, mouth closed",
  exprs=("blank","quiet unease","suppressed guilt","tearful"),
  edits=[
   ("마법사처럼 화려하게 나올 때",
    "Edit this sheet: remove any hat, staff, jewelry or glowing magic effects. She wears only the worn plain black robe with a simple leather belt and the small card bundle on a faded red string around her neck. Change nothing else."),
   ("이름 글자가 깨졌을 때",
    "Edit only the large name text at the top left so it reads exactly \"NOEL\" with the subtitle \"THE WITCH\". Change nothing else."),
   ("너무 생기 있어 보일 때",
    "Make her look more exhausted and haunted: deeper shadows under her eyes, paler skin, slightly hunched shoulders, no smile. Keep the same face, hair and outfit. Change nothing else."),
  ]),
]

CUT_S = "- - - 여기부터 복사 - - -"
CUT_E = "- - - 여기까지 복사 - - -"

def avoid(c, extra=""):
    s = f"AVOID: {COMMON_AVOID}, {c['avoid_extra']}"
    if extra: s += ", " + extra
    return s + "."

def sheet(c):
    cl = "; ".join(f'{i+1}) "{l}" — {d}' for i,(l,d) in enumerate(c["callouts"]))
    return f"""Character design reference sheet for a dark fantasy card RPG, single landscape page (16:9).
{STYLE_SHEET}

{c['anchor']}

LAYOUT (strict):
- TOP LEFT: the name "{c['name']}" in large serif display type, with the small subtitle "{c['role']}".
- LEFT COLUMN: one large close-up bust portrait of her face, {c['front_expr']}.
- CENTER (dominant, about half of the page): full-body turnaround, 3 large views standing on the reflective floor — front, side profile, back. Identical outfit, colors and proportions in all three views, neutral standing pose with arms slightly away from the body. In the back view her face is NOT visible.
- RIGHT COLUMN, headline "DETAILS": 3 stacked panels, each a zoomed render of one element with a short bold label: {cl}.
- BOTTOM RIGHT: a row of 5 flat color swatches of her main colors, no labels.
All text in clean English, as short as written above. The character must be IDENTICAL in all views and panels.

{avoid(c, "face visible in the back view")}"""

def single_front(c):
    return f"""{STYLE_SINGLE}

{c['anchor']}

Single full-body front view of this character, vertical 2:3 portrait composition, centered, full figure from head to feet with a small even margin, relaxed natural standing pose facing the viewer, {c['front_expr']}, looking at the viewer. {c['bg']}.
No text, no labels, no sheet layout, no other views, no cropping.

{avoid(c)}"""

def single_rear(c):
    side = c["face_side"]
    if side == "straight":
        facing = "we see her straight from behind as she faces directly away from the viewer, her body turned only very slightly"
    else:
        facing = f"we see her back and part of one side as she faces away, turned slightly toward the {side} side of the frame"
    view = "rear view (seen directly from behind)" if side == "straight" else "three-quarter rear view (over-the-shoulder view from behind)"
    return f"""{STYLE_SINGLE}

{c['anchor']}

Single full-body {view} of this character, vertical 2:3 portrait composition, centered, full figure from head to feet with a small even margin. The camera stands just behind her and slightly above her head height, looking a little downward: {facing}, standing ready for battle and looking into the distance ahead. Her face is NOT visible, head faces away; at most the edge of her cheek and ear can be seen. {c['bg']}.
No text, no labels, no sheet layout, no other views, no cropping.

{avoid(c, "face visible from behind, head turned toward camera, looking back over the shoulder")}"""

def exprs(c):
    e = c["exprs"]
    return f"""{STYLE_SINGLE}

{c['anchor']}

A single horizontal row of exactly 4 large bust close-ups of this character, evenly spaced edge to edge, filling the full width and height of the frame, plain dark blue-gray background, expressions left to right: {e[0]} / {e[1]} / {e[2]} / {e[3]}.
Identical face shape, eye size, hair, and lighting in all four.
One short English label under each: "{e[0].upper()}", "{e[1].upper()}", "{e[2].upper()}", "{e[3].upper()}". No other views, no turnaround, no color swatches.

{avoid(c)}"""

def hands(c):
    return f"""Anime illustration style, dark fantasy. Detailed cel-shaded rendering with soft painterly lighting and fine, clean linework. Cold blue-gray palette with a single deep red accent. Soft cool light from above.

First-person point of view of Noel, a slight, thin witch with very pale skin, wearing a worn black robe with very wide ragged sleeves. Only her own two hands and the ends of her sleeves are visible, entering from the bottom edge of a landscape 16:9 frame, as if the viewer is the witch looking down at her hands.
Her thin, pale, slender hands hold a fanned hand of exactly five cards up in front of her at the bottom center of the frame, the same pose as holding playing cards: the left hand grips the lower left of the fan and the right hand the lower right, with both thumbs resting on the front of the cards and the other fingers behind them. The fan spans about the middle third of the frame width and reaches up to about the middle of the frame height.
IMPORTANT: the five cards are completely flat, solid pure green (#00FF00) — no frame, no border, no texture, no shading, no symbols — exactly the same color as the background.
Plain flat solid pure green background (#00FF00, one even color, no gradient, no floor, no shadow) for easy background removal; no green light or green reflections on the hands or sleeves.
No other body parts, no face, no text, no letters.

AVOID: extra fingers, fused or missing fingers, six fingers, deformed hands, rings, jewelry, nail polish, gloves, bright saturated colors on the hands, card designs or card borders, cards that are not green, watermark, signature."""


def block(title, body):
    return f"{title}\n{CUT_S}\n{body}\n{CUT_E}\n"

CHECK = """① 모든 뷰의 키·비율이 같은가
② 얼굴이 모든 뷰에서 같은 사람인가
③ 오른쪽 아래 색 견본과 실제 의상 색이 일치하는가
④ 시그니처 요소({sig})가 모든 뷰에 있는가  → 실패 시 편집 프롬프트 1
⑤ 이름·라벨 글자에 오타가 없는가  → 실패 시 편집 프롬프트 2
⑥ 정면·측면·뒷면 3뷰와 세부 3칸이 빠짐없이 있는가  → 빠졌으면 시트 재생성
⑦ 잘라낸 뷰 하나의 세로가 800px 이상인가  → 미만이면 2단계(2:3 세로 단일 뷰)로 재생성
⑧ 짙은 붉은색 외에 채도 높은 색이 끼어들지 않았는가 (기존 04·05·07과 톤 비교)
⑨ 뒷면 뷰에서 얼굴이 보이지 않는가"""

for i,c in enumerate(C,1):
    sig = ", ".join(l for l,_ in c["callouts"])
    parts = []
    parts.append(f"# {c['ko']} ({c['name']}) — GPT Image 캐릭터 시트 프롬프트\n# 사용 환경: ChatGPT 앱(유료 구독). 해상도 선택 없음 → 화면비와 분할로 해상도 확보\n# 생성: docs/prompts/make 스크립트. 앵커 문단은 모든 프롬프트에 그대로 들어가 있다. 고치지 말고 통째로 복사할 것.\n")
    parts.append("=== CHARACTER ANCHOR ===\n" + c["anchor"] + "\n")
    parts.append("=== SHEET PROMPT ===\n" + block("[1단계] 컨셉 시트 — 화면비: 16:9 가로 (선택지에 없으면 3:2 가로)", sheet(c)))
    parts.append("=== AVOID ===\n" + avoid(c) + "\n(위 프롬프트 끝에 이미 포함되어 있음. 별도 입력 불필요)\n")
    ed = "\n".join(block(f"[편집 {j}] {t} — 생성된 시트를 같은 대화창에서 이어서 입력", b) for j,(t,b) in enumerate(c["edits"],1))
    parts.append("=== EDIT PROMPTS ===\n" + ed)
    os_ = [ "=== OUTPUT SETTINGS (ChatGPT 앱 기준) ===",
      "사용 환경: ChatGPT 앱(유료) — 해상도 선택 불가, 화면비만 조절 가능. 프롬프트에 '4K'를 써도 픽셀 수는 바뀌지 않음",
      "1단계 컨셉 시트 : 16:9 가로 — 설계도 용도. 게임에 넣지 않음 → reference/sheets/" + c["key"] + "_sheet.png",
      "2단계 실사용 뷰 : 2:3 세로, 뷰당 1장 (약 1,380px). 한 번에 하나씩 입력할 것 — 여러 개를 한 번에 넣으면 한 장에 몰아 그려 해상도가 떨어짐",
    ]
    if c["face_side"]:
        os_.append(f"   ① 정면 전신 → 대화용 스탠딩: prototype/assets/stand_{'hero' if c['key']=='seraphina' else 'warrior' if c['key']=='brunhild' else 'archer'}.png (상반신 위주로 잘라 써도 됨)")
        os_.append(f"   ② 반측면 뒷모습 → 전투 스프라이트: prototype/assets/spr_{'hero' if c['key']=='seraphina' else 'warrior' if c['key']=='brunhild' else 'archer'}_back.png")
    else:
        os_.append("   ① 정면 전신 → 대화용 스탠딩: prototype/assets/stand_witch.png  (마녀는 전투 화면 밖이라 뒷모습 스프라이트 없음)")
    os_ += [
      "3단계 표정 시트 : 16:9 가로 1×4 한 줄 (얼굴당 약 700px) — 프로토타입 이후 작업",
      "배경 제거       : 2단계 결과물만. 단색 배경으로 뽑았으므로 배경 제거 도구로 투명 PNG로 만든다",
      "업스케일        : 필요하면 2단계 결과물만 2배까지 (Upscayl 등). 글자가 있는 1·3단계 시트는 업스케일 금지",
      "생성 순서       : 1단계 시트 → 앵커와 어긋난 곳 확인(소지품 좌우·장식 개수·머리 길이·액세서리) → 2단계 ① → ②",
      "참조 이미지 팁  : 같은 대화창에서 이어가고, 1단계 시트를 첨부한 채 2단계를 입력하면 일치도가 오른다. 화풍을 맞추려면 reference/images/04·05·07도 함께 첨부. 이미지를 첨부해도 프롬프트는 그대로 전부 넣는다",
      "",
      block("[2단계 ①] 정면 전신 — 화면비: 2:3 세로", single_front(c)),
    ]
    if c["face_side"]:
        os_.append(block("[2단계 ②] 반측면 뒷모습 (전투 스프라이트) — 화면비: 2:3 세로", single_rear(c)))
    if c["key"] == "noel":
        os_.append(block("[2단계 ②] 1인칭 손 (전투 화면 손패) → prototype/assets/ui_witch_hands.png — 화면비: 16:9 가로", hands(c)))
    os_.append(block("[3단계] 표정 1×4 (프로토타입 이후) — 화면비: 16:9 가로", exprs(c)))
    parts.append("\n".join(os_))
    parts.append("=== MODEL TIPS ===\n- ChatGPT 앱은 같은 대화창에서 '이 부분만 바꿔줘'식 편집이 잘 먹힌다. 글자 오타는 재생성하지 말고 편집 프롬프트 2로 그 글자만 고친다.\n- 결과가 앵커와 다르게 나왔는데 그 결과가 마음에 들면, 앵커 문장을 결과에 맞게 고친 뒤 2단계로 넘어간다(앵커와 그림이 어긋난 채 진행하면 뷰마다 결과가 튄다).\n")
    parts.append("=== QUALITY CHECKLIST ===\n" + CHECK.format(sig=sig) + "\n")
    fn = os.path.join(OUT, f"{i:02d}_{c['key']}.txt")
    open(fn,"w",encoding="utf-8").write("\n".join(parts))
    print(fn)
