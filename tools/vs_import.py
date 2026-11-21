"""버티컬 슬라이스 승인 그림(art/raw/vs/*.webp)을 게임 그림(game/assets/)으로 옮긴다.

- 크로마 배경(초록 #00FF00 · 엘리안은 마젠타 #FF00FF)은 tools/remove_bg.py 로 지운다(디스필 포함).
- 그 뒤 가장자리 몇 px 의 얇은 초록/마젠타 번짐을 한 번 더 뺀다(edge_despill) — 어두운 배경 위에서 테두리가 비치지 않게.
- 크기는 화면에 그려지는 크기에 맞춰 줄인다(웹 빌드 크기·메모리). 배경(16:9)은 원본(약 1672×941) 그대로 webp 로 복사.
- 표정이 여러 장인 스탠딩은 같은 캔버스(아래 가운데 기준)로 맞춰 자른다 → 표정을 바꿔도 몸이 흔들리지 않는다.
대응표는 MAP 아래 · game/DECISIONS.md. 확인 그림(어두운 배경 위): --check 폴더
사용법: python3 tools/vs_import.py [--only 이름,…] [--check 폴더]
"""
import argparse
import os
import shutil
import sys
import tempfile

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
RAW = os.path.join(ROOT, 'art', 'raw', 'vs')
OUT = os.path.join(ROOT, 'game', 'assets')
sys.path.insert(0, HERE)
import remove_bg  # noqa: E402

# 스프라이트: 원본 → (게임 파일, 최대 높이 px | None, 캔버스 유지)
SPRITES = {
    '01_seraphina_back_base': ('spr_hero_back.png', 1100, False),
    '05_brunhild_back_base': ('spr_warrior_back.png', 1100, False),
    '06_elian_back_base': ('spr_archer_back.png', 1100, False),
    '08_cultist': ('spr_cultist.png', 640, False),
    '40_gravekeeper': ('spr_gravekeeper.png', 900, False),
    '41_giant_foot': ('spr_giant_foot.png', None, False),
    '43_buried_child': ('stand_child.png', 1100, False),
    '09_noel_hand_raise': ('ui_witch_hand_raise.png', None, True),
    '09_noel_hands': ('ui_witch_hands.png', None, True),
    '11_card_back': ('card_back.png', 540, False),
}
# 표정 스탠딩: 캐릭터 → [(원본, 게임 파일)] — 같은 캔버스로 맞춘다
STANDS = {
    'hero': [('28_stand_seraphina_calm', 'stand_hero_calm.png'), ('29_stand_seraphina_smile', 'stand_hero_smile.png'),
             ('30_stand_seraphina_determined', 'stand_hero_determined.png'), ('31_stand_seraphina_shocked', 'stand_hero_shocked.png')],
    'warrior': [('32_stand_brunhild_smirk', 'stand_warrior_smirk.png'), ('33_stand_brunhild_stern', 'stand_warrior_stern.png'),
                ('34_stand_brunhild_shocked', 'stand_warrior_shocked.png'), ('35_stand_brunhild_grief', 'stand_warrior_grief.png')],
    'archer': [('36_stand_elian_cold', 'stand_archer_cold.png'), ('37_stand_elian_shocked', 'stand_archer_shocked.png'),
               ('38_stand_elian_grief', 'stand_archer_grief.png')],
}
STAND_H = 1100
# 배경·CG (16:9): 원본 → 게임 파일 (그대로 복사)
BGS = {
    '07_bg_funeral_gallery': 'bg_vs_funeral_gallery.webp',
    '15_bg_camp': 'bg_vs_camp.webp',
    '16_bg_camp_empty': 'bg_vs_camp_empty.webp',
    '17_bg_ossuary_hall': 'bg_vs_ossuary_hall.webp',
    '18_bg_stair_landing': 'bg_vs_stair_landing.webp',
    '19_bg_deepest_hall': 'bg_vs_deepest_hall.webp',
    '20_bg_cult_prayer_room': 'bg_vs_cult_prayer_room.webp',
    '21_bg_gravekeeper_vault': 'bg_vs_gravekeeper_vault.webp',
    '22_bg_buried_coffin_room': 'bg_vs_buried_coffin_room.webp',
    '23_cg_dead_witch': 'cg_vs_dead_witch.webp',
    '24_bg_candle_chapel': 'bg_vs_candle_chapel.webp',
    '25_bg_training_hall': 'bg_vs_training_hall.webp',
    '26_cg_grave_merchant': 'cg_vs_grave_merchant.webp',
    '27_bg_footprint_room': 'bg_vs_footprint_room.webp',
}
# 예고 아이콘 3종(한 줄에 셋: 공격 · 운명 공격 · 가려짐)
ICONS = ('12_intent_icons', ['intent_attack.png', 'intent_fate.png', 'intent_hidden.png'], 160)


def keyed(name, keep_canvas):
    """remove_bg.py 로 배경을 지운 RGBA 그림"""
    tmp = os.path.join(tempfile.mkdtemp(), name + '.png')
    remove_bg.remove_bg(os.path.join(RAW, name + '.webp'), tmp, None, None, 0, keep_canvas, 0)
    im = Image.open(tmp).convert('RGBA')
    bg = remove_bg.estimate_bg(Image.open(os.path.join(RAW, name + '.webp')).convert('RGB').load(), *Image.open(os.path.join(RAW, name + '.webp')).size)
    return edge_despill(im, bg)


def edge_despill(im, bg, radius=4):
    """투명한 곳에서 radius px 안쪽 테두리의 크로마 번짐을 뺀다 (초록: G ≤ max(R,B) · 마젠타: R·B 를 G 쪽으로)"""
    a = np.asarray(im).astype(np.int32).copy()
    alpha = a[..., 3]
    near = alpha < 255
    m = near.copy()
    for _ in range(radius):  # radius 만큼 넓힌다(4방향)
        g = m.copy()
        g[1:, :] |= m[:-1, :]
        g[:-1, :] |= m[1:, :]
        g[:, 1:] |= m[:, :-1]
        g[:, :-1] |= m[:, 1:]
        m = g
    m &= alpha > 0
    r, gg, b = a[..., 0], a[..., 1], a[..., 2]
    if bg[1] > bg[0] and bg[1] > bg[2]:  # 초록
        cap = np.maximum(r, b)
        gg[m] = np.minimum(gg[m], cap[m])
    else:  # 마젠타
        s = np.minimum(r, b) - gg
        s = np.where(m & (s > 0), s, 0)
        r -= s
        b -= s
    a[..., 0], a[..., 1], a[..., 2] = r, gg, b
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), 'RGBA')


def fit_h(im, max_h):
    if max_h and im.height > max_h:
        im = im.resize((round(im.width * max_h / im.height), max_h), Image.LANCZOS)
    return im


def do_sprite(name):
    out, max_h, keep = SPRITES[name]
    im = fit_h(keyed(name, keep), max_h)
    im.save(os.path.join(OUT, out))
    if name == '09_noel_hands':
        # 코드는 왼손·오른손을 x=836 에서 나눈 두 장을 쓴다 (layout.hand.splitX)
        w, h = im.size
        im.crop((0, 0, 836, h)).save(os.path.join(OUT, 'ui_witch_hand_left.png'))
        im.crop((836, 0, w, h)).save(os.path.join(OUT, 'ui_witch_hand_right.png'))
    return [out]


def do_stands(who):
    ims = []
    for src, out in STANDS[who]:
        im = keyed(src, True)
        if im.height < 1536:  # 37 은 1535 — 아래 가운데 기준으로 같은 캔버스에
            pad = Image.new('RGBA', (im.width, 1536), (0, 0, 0, 0))
            pad.paste(im, (0, 1536 - im.height))
            im = pad
        ims.append((im, out))
    # 모든 표정을 덮는 상자로 함께 자른다 (아래 가운데가 같은 자리)
    box = None
    for im, _ in ims:
        bb = im.getbbox()
        box = bb if box is None else (min(box[0], bb[0]), min(box[1], bb[1]), max(box[2], bb[2]), max(box[3], bb[3]))
    outs = []
    for im, out in ims:
        fit_h(im.crop(box), STAND_H).save(os.path.join(OUT, out))
        outs.append(out)
    return outs


def do_icons():
    name, outs, size = ICONS
    im = keyed(name, True)
    w, h = im.size
    res = []
    for i, out in enumerate(outs):
        part = im.crop((w * i // 3, 0, w * (i + 1) // 3, h))
        bb = part.getbbox()
        part = part.crop(bb)
        s = max(part.size)
        sq = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        sq.paste(part, ((s - part.width) // 2, (s - part.height) // 2))
        sq.resize((size, size), Image.LANCZOS).save(os.path.join(OUT, out))
        res.append(out)
    return res


def check(files, folder):
    """어두운 배경 위에 얹어 테두리 번짐을 눈으로 확인하는 그림"""
    os.makedirs(folder, exist_ok=True)
    for f in files:
        im = Image.open(os.path.join(OUT, f)).convert('RGBA')
        bg = Image.new('RGBA', im.size, (24, 18, 22, 255))
        bg.alpha_composite(im)
        k = min(1.0, 900 / max(im.size))
        bg.convert('RGB').resize((max(1, round(im.width * k)), max(1, round(im.height * k)))).save(os.path.join(folder, 'check_' + f.replace('.png', '.jpg')), quality=88)


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--only', default='')
    ap.add_argument('--check', default='')
    a = ap.parse_args()
    only = set(x for x in a.only.split(',') if x)
    done = []
    for n in SPRITES:
        if not only or n in only:
            done += do_sprite(n)
    for who in STANDS:
        if not only or who in only:
            done += do_stands(who)
    if not only or 'icons' in only:
        done += do_icons()
    if not only or 'bg' in only:
        for n, out in BGS.items():
            shutil.copyfile(os.path.join(RAW, n + '.webp'), os.path.join(OUT, out))
    if a.check:
        check([f for f in done if f.endswith('.png')], a.check)
    print('done', len(done), done)
