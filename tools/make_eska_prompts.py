"""에스카 디자인 이미지 생성 프롬프트 모음을 만든다 → docs/art/eska-design-prompts.txt
앵커·스타일·AVOID를 한곳에서 고치면 모든 프롬프트에 똑같이 들어간다 (캐릭터 일관성)."""
import pathlib

STYLE = ("Korean webtoon-style character concept art, clean cel shading with bold black ink linework and crisp "
"high-contrast shadows, dark fantasy, mysterious and otherworldly mood. Dramatic cool backlight and ice-blue rim light; "
"the hat brim casts a soft shadow over her upper face so her glowing ice-blue eyes are the brightest point. "
"Dark desaturated slate-navy (#1A1F2E) background with a faint darker vignette.")
ANCHOR = ("ESKA, the Witch of Endings: a tall, slender woman in her late twenties, about 7.5 heads tall with long legs (not exaggerated), "
"carrying a cold, detached, otherworldly and melancholic presence. Slender oval face, long narrow eyes with slightly downturned outer corners, "
"heavy tired upper lids, thin pale lips, cool porcelain skin, always expressionless. Her irises are pale ice-blue and softly glowing. "
"Very long straight hair in dark desaturated steel blue (#3E5068) with lighter steel-blue highlights (#7F93AD), falling to mid-thigh, "
"its ends gently lifting and drifting as if weightless, with no wind; long uneven bangs cover most of her right eye, side locks reach her chest. "
"A wide-brimmed pointed witch hat in deep navy (#1B2340), the brim as wide as her shoulders, the tall cone tip bending back toward her left, "
"with a plain dark band and one small silver buckle; a thin semi-transparent navy veil hangs from the back of the brim down to her waist. "
"An off-the-shoulder fitted navy long-sleeved blouse with a straight neckline that bares her collarbones and shoulder line; the sleeves are slim on the upper arm and flare gently wide at the wrists, no puffed shoulders; the neckline is edged "
"with faint silver-thread embroidery of tiny handwritten script. A thin semi-sheer ash-blue knit shawl draped low across her back and upper arms, "
"resting at elbow height so both shoulders stay bare, its frayed fringe hanging to her hips and drifting softly. A high-waisted fitted dark navy leather corset belt with thin silver lacing, cinching her waist just below the bust. "
"A two-layer skirt: a short dark-navy inner skirt at mid-thigh, and a long sheer outer overskirt of layered navy chiffon with a faint cool silver metallic sheen, "
"split open at the front so her bare legs and the short inner skirt stay visible, flowing down at the sides and back to her ankles, "
"its hem embroidered with the same faint silver script and floating slightly. "
"Bare legs, short black leather ankle boots ending just above the ankle with low block heels. "
"Signature weapon on her LEFT hip, hung from her belt by two dark cords with the edge facing down, angled backward so the scabbard end trails behind her: a slender, slightly curved single-edged Japanese-style sword (katana-like) with a long, narrow blade whose surface is etched with faint lines of tiny handwritten script, silver at rest and glowing ice-blue when she attacks, instead of a temper line; a round guard (tsuba) forged from black iron shaped like tightly woven twisted twigs; a long grip wrapped in dark navy cord with a plain silver end cap; a long narrow scabbard in dark navy lacquer with a few silver fittings; the lower third of the scabbard flares into a bundle of twisted black twigs bound with dark cord, so the sheathed sword reads as a witch's broom. A few faint lavender motes of light drift around her. "
"Strictly cool palette: navy, steel blue, pale skin, ice-blue glow (#9FD8FF), soft lavender accents (#B9A2FF). No warm colors.")
AV_COMMON = ("extra fingers, fused fingers, inconsistent outfit or colors between views, inconsistent face between views, "
"asymmetric face, text typos, misspelled labels, cropped or missing views, watermark, signature")
AV_CHAR = ("warm colors (red, orange, gold, brown), star or constellation patterns, star-shaped brooch, glowing cracks or rift effects, "
"gray-white hair, black hair without blue tint, weapon on her right hip, western cross-guard, rapier or cup guard, straight double-edged blade, gem on the sword hilt, broad or heavy blade, crescent moon ornament, ribbon or tassel on the hilt, kimono or samurai armor, "
"school uniform look, puffed sleeves, ballgown, fully closed long skirt hiding the legs, thigh-high or knee-high boots, hair blown sideways by strong wind, lingerie, explicit nudity, "
"suggestive or sexualized pose, cleavage-focused framing")
SWORD_TXT = ("a slender, slightly curved single-edged Japanese-style sword (katana-like) with a long, narrow blade whose surface is etched with faint lines of tiny handwritten script, silver at rest and glowing ice-blue when she attacks, instead of a temper line; a round guard (tsuba) forged from black iron shaped like tightly woven twisted twigs; a long grip wrapped in dark navy cord with a plain silver end cap; a long narrow scabbard in dark navy lacquer with a few silver fittings")
def avoid(extra=""):
    return "AVOID: " + AV_COMMON + ", " + AV_CHAR + (", " + extra if extra else "") + "."
def block(title, body):
    return f"■ {title}\n- - - 여기부터 복사 - - -\n{body}\n- - - 여기까지 복사 - - -\n"

LAYOUT = """LAYOUT (strict):
- HEADER LEFT: character name "ESKA" in large elegant display type, subtitle "// THE WITCH OF ENDINGS".
- LEFT COLUMN: "BASIC INFO" data block — ROLE: Witch of Endings / HEIGHT: 175 cm / WEAPON: Broom-Katana. Below it a short italic quote in lavender: "Every world ends. / I only close the book." Below that, one large close-up bust portrait of her face, expressionless, upper face in the shadow of the hat brim, glowing ice-blue eyes behind her bangs.
- CENTER (dominant, about half the page): full-body turnaround, 3 large views on a dark reflective floor — front, left side profile (facing screen-left so her LEFT hip and the broom-katana face the viewer), back. Identical outfit, proportions, and hair in all three views, calm standing pose, hair ends and veil drifting slightly, sword sheathed on her LEFT hip with the broom end trailing behind her. Keep the turnaround clearly readable despite the dramatic lighting.
- RIGHT COLUMN, headline "DETAILS": 4 stacked panels, each a zoomed render with a bold label and one short line:
  1) HAT & VEIL — wide navy brim, sheer veil;
  2) OVERSKIRT — open-front silver-sheen chiffon;
  3) BROOM SCABBARD — twisted black twigs bound with cord;
  4) BLADE & GUARD — script-etched blade, twig-iron guard.
- BOTTOM RIGHT, headline "MATERIALS": a row of 5 small labeled material spheres: Navy Wool (Cloth), Silver-Sheen Chiffon (Sheer), Navy Lacquer (Gloss), Etched Steel (Metal), Black Twig (Wood).

All labels in clean sans-serif English, short. The character must be IDENTICAL in all views and panels."""

sheet = f"Character concept art sheet, single landscape page, aspect ratio 3:2. {STYLE}\n\n{ANCHOR}\n\n{LAYOUT}\n\n{avoid('busy background, extra characters')}"
sheet_edit = ("Use the attached character sheet as the base. Redraw the same sheet with the same layout, the same character face, "
"the same colors and the same label style, but update the design and mood exactly as described below.\n\n"
f"{STYLE}\n\nUpdated character description:\n{ANCHOR}\n\n{LAYOUT}\n\n{avoid('busy background, extra characters')}")

def single(view, extra_desc, extra_avoid=""):
    return f"""Aspect ratio 2:3 vertical portrait. {STYLE}

{ANCHOR}

Single full-body {view} of this character, vertical 2:3 portrait composition, centered, full figure from the tip of the hat to the boots with a small even margin, calm standing pose, sword sheathed on her LEFT hip with the broom end trailing behind her. {extra_desc}
No text, no labels, no sheet layout, no other views, no cropping.

{avoid(extra_avoid)}"""

hero = single("three-quarter front view (turned slightly to her left)", "Her glowing ice-blue left eye is visible, the right eye mostly hidden by bangs. Hair ends, veil, shawl fringe and the long chiffon overskirt drift slightly as if weightless.")
front = single("straight front view", "Arms relaxed at her sides, both bare shoulders clearly visible, the broom-scabbard visible behind her left leg.")
side = single("left side profile view, facing screen-left so her LEFT hip and the broom-katana face the viewer", "The full length of the scabbard, the twig-iron guard and the twig-broom end are clearly visible; the long open-front overskirt flows down to her ankles behind her legs; the hat's bent tip points backward.")
back = single("back view", "Her face is NOT visible, head faces away. The very long steel-blue hair, the veil hanging from the hat brim, the shawl across her back, and the broom-scabbard angled behind her left hip are clearly visible.", "face visible from behind, head turned toward camera")
expr = f"""Aspect ratio 3:2 landscape. {STYLE}

{ANCHOR}

A single horizontal row of exactly 4 large bust close-ups of this character, evenly spaced edge to edge, filling the full width and height of the frame, wearing the hat, expressions left to right: expressionless and distant / the faintest cold smile / quiet sorrow with lowered eyes / cold focused glare with brighter glowing eyes. Identical face shape, eye size, hair, bangs covering her right eye, and lighting in all four. One short English label under each: NEUTRAL / FAINT SMILE / SORROW / COMBAT. No other views, no turnaround, no color swatches.

{avoid("different hairstyles between panels")}"""
weapon = f"""Aspect ratio 3:2 landscape. {STYLE}

Prop design study of ESKA's signature weapon, the Broom-Katana, on the same dark slate-navy background: a slender, slightly curved single-edged Japanese-style sword (katana-like) with a long, narrow blade whose surface is etched with faint lines of tiny handwritten script, silver at rest and glowing ice-blue when she attacks, instead of a temper line; a round guard (tsuba) forged from black iron shaped like tightly woven twisted twigs; a long grip wrapped in dark navy cord with a plain silver end cap; a long narrow scabbard in dark navy lacquer with a few silver fittings; the lower third of the scabbard flares into a bundle of twisted black twigs bound with dark cord, so the sheathed sword reads as a witch's broom. Strictly cool palette: navy, steel blue, black iron, silver, ice-blue glow (#9FD8FF), soft lavender accents (#B9A2FF). No warm colors.

LAYOUT: left — the sheathed broom-katana shown vertically at full length; center — the drawn sword shown vertically at full length beside its empty scabbard; right column — 3 zoomed panels: GUARD (woven twig-iron tsuba), BLADE (etched script, ice-blue glow), BROOM END (twig bundle and cord binding). One short English label per panel. No character, no other objects.

AVOID: warm colors (red, orange, gold, brown), western cross-guard, rapier or cup guard, crescent moon ornament, ribbon or tassel on the hilt, gem on the hilt, broad or heavy blade, extra blades, inconsistent design between panels, text typos, misspelled labels, watermark."""

edits = [
("무기가 오른쪽 허리에 있을 때", "Keep everything else exactly the same. In every view, move the broom-katana so it hangs on her LEFT hip, angled behind her. Do not change her face, hair, outfit, colors, or the layout."),
("라벨 오타가 있을 때 (따옴표 안을 실제 오타·정답으로 바꿔 쓰세요)", "Keep everything else exactly the same. Replace only the misspelled label text \"ESAK\" with exactly \"ESKA\". Do not change any image content."),
("따뜻한 색이 섞였거나 부츠가 길 때", "Keep everything else exactly the same. Remove every warm color (red, orange, gold, brown) and replace it with navy, steel blue, silver, or ice-blue. Shorten her boots to black leather ankle boots ending just above the ankle. Do not change her face, hair, pose, or the layout."),
("무기를 빗자루 일본도로 바꿀 때 (v2 시트 첨부)", "Keep everything else exactly the same: the same layout, face, hair, outfit, colors, lighting and labels. Replace the rapier in every view and panel with a new sword: " + SWORD_TXT + "; the lower third of the scabbard flares into a bundle of twisted black twigs bound with dark cord, so the sheathed sword reads as a witch's broom. In every view, including the back view, the sword hangs on her LEFT hip from her belt by two dark cords with the edge facing down, angled backward so the broom end trails behind her legs. Change the WEAPON label to \"Broom-Katana\", the fourth DETAILS panel to \"BLADE & GUARD\" with the line \"Script-etched blade, twig-iron guard.\", and the materials \"Worn Leather (Matte)\" and \"Antique Silver (Metal)\" to \"Navy Lacquer (Gloss)\" and \"Etched Steel (Metal)\". AVOID: rapier, cup guard, western cross-guard, crescent moon ornament, ribbon or tassel on the hilt, warm colors, weapon on her right hip, missing weapon in any view."),
("신비로운 느낌이 약할 때", "Keep the design and layout exactly the same. Make the mood more mysterious: stronger cool backlight, deeper shadow under the hat brim so her glowing ice-blue eyes stand out, hair ends and veil drifting as if weightless, and a few faint lavender motes of light around her. Do not change her face, outfit, colors, or labels."),
]

out = []
out.append("에스카(ESKA) 캐릭터 디자인 — 이미지 생성 프롬프트 모음 (v3: 신비로운 연출 · 베일 · 앞트임 긴 겉치마 · 코르셋 벨트 · 글자 자수 · 빗자루 일본도)\n"
"만든 곳: tools/make_eska_prompts.py (앵커를 고치면 이 스크립트를 다시 실행) · 대상: ChatGPT 무료 (하루 2~3장 추정)\n기획서 연결: docs/gdd/10-art-direction.md\n")
out.append("=== CHARACTER ANCHOR ===\n이 문단은 모든 프롬프트에 한 글자도 바꾸지 않고 들어간다 (캐릭터 일관성의 핵심).\n\n" + ANCHOR + "\n")
out.append("=== SHEET (1단계 · 화면비 3:2 가로) ===\n"
 + block("1단계-수정: 기존 시트를 첨부하고 같은 대화창에서 (지금 쓸 것)", sheet_edit)
 + block("1단계-새로: 처음부터 새 대화창에서", sheet))
out.append("=== AVOID ===\n각 프롬프트 끝에 이미 들어 있다:\n" + avoid("") + "\n")
out.append("=== EDIT PROMPTS (생성된 이미지가 있는 같은 대화창에서) ===\n" + "".join(block(f"편집 {i+1}: {t}", b) for i,(t,b) in enumerate(edits)))
out.append("""=== OUTPUT SETTINGS (ChatGPT 무료) ===
크기·품질·개수는 고를 수 없다. 화면비는 프롬프트 첫 줄로 지정한다. 하루 2~3장(비공식 추정)이라 순서가 중요하다.
1순위: 1단계-수정 (지금 시트 첨부) → 디자인 확정
2순위: 2단계-1 히어로 → 2단계-2 정면 (같은 대화창, 앞 이미지 첨부)
3순위: 2단계-3 옆 · 2단계-4 뒤 → 3-B 무기 → 3단계 표정
프롬프트는 한 번에 하나씩. 같은 대화창에서 이어 가며 마음에 든 이미지를 첨부한다 (첨부해도 앵커는 그대로 넣는다).
업스케일: 글자 없는 2단계 단일 뷰만 Upscayl 2배까지.
"""
 + block("2단계-1 히어로 3/4 뷰 — 화면비: 2:3 세로", hero)
 + block("2단계-2 정면 — 화면비: 2:3 세로", front)
 + block("2단계-3 왼쪽 옆모습 — 화면비: 2:3 세로", side)
 + block("2단계-4 뒷모습 — 화면비: 2:3 세로", back)
 + block("3단계 표정 1×4 — 화면비: 3:2 가로", expr)
 + block("3-B 무기 디자인 — 화면비: 3:2 가로", weapon))
out.append("""=== MODEL TIPS ===
- 라벨 오타는 다시 생성하지 말고 편집 2번으로 그 글자만 바꾼다.
- 결과가 앵커와 다르지만 더 마음에 들면 앵커를 결과에 맞춰 고친 뒤 다음 단계로 간다.
""")
out.append("""=== QUALITY CHECKLIST ===
1. 모든 뷰의 비율·얼굴이 같은가
2. 따뜻한 색이 없는가 → 편집 3
3. 빗자루 일본도가 모든 뷰에서 LEFT 허리인가 → 편집 1
4. 라벨 오타가 없는가 → 편집 2
5. 요청한 뷰·패널이 빠짐없이 있는가
6. 잘라낸 전신 뷰 세로가 800px 이상인가 → 미만이면 2단계 단일 뷰로
7. 앞머리가 오른쪽 눈을 가리는가, 양쪽 어깨가 드러나는가
8. 눈이 화면에서 가장 밝은 점인가, 머리끝·베일이 떠오르는가 → 편집 5
9. 칼날이 가늘고 살짝 휜 외날인가, 코등이가 나뭇가지 엮은 검은 쇠인가, 칼날에 글자 문양이 있는가
""")
pathlib.Path(__file__).resolve().parent.parent.joinpath("docs/art/eska-design-prompts.txt").write_text("\n".join(out))
pathlib.Path("/tmp/claude-0/sheet_edit.txt").write_text(sheet_edit)
