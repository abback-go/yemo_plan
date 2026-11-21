"""버티컬 슬라이스 승인 그림(art/raw/vs/*.webp)을 게임 그림(game/assets/)으로 옮긴다.

- 크로마 배경(초록 #00FF00 · 엘리안은 마젠타 #FF00FF)은 tools/remove_bg.py 로 지운다(디스필 포함) — **--soft 100**(SOFT).
  remove_bg.py 기본값(soft 150)은 크로마 모드에서 키 색과 거리 150 안의 중간색(회색 갑옷·갈색 얼룩·피부 그늘)을 몸 안쪽에서도
  반투명으로 만든다(2026-11-22 측정: 안쪽 반투명 12~35%). remove_bg.py 는 고치지 않고(사용자 결정 전) 여기서 soft 를 낮춘다.
- 그 뒤 투명한 곳에서 3px 안쪽의 남은 번짐을 뺀다(edge_fringe): 초록 키 — G > max(R,B)+40 이면 G = max(R,B),
  마젠타 키(엘리안) — min(R,B) > G+40 이면 R·B 를 G+40 쪽으로(엘리안 망토의 초록은 건드리지 않는다).
- 확인(interior_partial): 알파>0 영역을 9px MinFilter 로 깎은 안쪽에서 반투명(0<알파<255) 픽셀 비율 — 약 0% 여야 한다.
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
from PIL import Image, ImageFilter

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
# 세라피나 데스신 6컷(그림체 D, 승인 — reference/deathscene, 불투명 16:9 1672×941): 그대로 복사 → game_data cutscene.cuts
DEATH_DIR = os.path.join(ROOT, 'reference', 'deathscene')
DEATH = {
    'seraphina_C1_last_words': 'cut_hero_c1.webp', 'seraphina_C2_reach': 'cut_hero_c2.webp',
    'seraphina_C3a_first_stomp': 'cut_hero_c3a.webp', 'seraphina_C3b_go': 'cut_hero_c3b.webp',
    'seraphina_C4_last_stomp': 'cut_hero_c4.webp', 'seraphina_C6_aftermath': 'cut_hero_c6.webp',
}
# 예고 아이콘 3종(한 줄에 셋: 공격 · 운명 공격 · 가려짐)
ICONS = ('12_intent_icons', ['intent_attack.png', 'intent_fate.png', 'intent_hidden.png'], 160)
# VN 대화창(9조각): 내용 상자로 잘라 높이 DIALOG_H 로 (목업 vs_dialog_mock: 1600×230, 모서리 여백 좌우 95·위아래 62 — game_data vnBox)
DIALOG = ('66_ui_dialog_box', 'ui_dialog_box.png')
DIALOG_H = 230
# 카드 그림(불투명 정사각형 1254, 크로마 없음): 카드 틀의 그림 창(약 402×408)에 맞춰 512 로 줄인다. 이름은 카드 id 그대로(다음 판은 파일만 바꾸면 된다)
CARD_ART = 512
CARDS = {
    '44_card_holy_slash': 'holy_slash', '45_card_vanguard_v1': 'vanguard', '46_card_cover_v1': 'cover',
    '47_card_shield_bash_v1': 'shield_bash', '48_card_snipe_v1': 'snipe', '49_card_suppressing_fire_v1': 'suppress',
    '50_card_curse_flame_v1': 'curse_flame', '51_card_fate_shift_v1': 'fate_shift', '52_card_take_hit_v1': 'take_hit',
    '53_card_foresight_v1': 'foresight', '54_card_wound': 'wound', '55_card_trampled_v1': 'trample',
    '56_card_broken_holy_sword': 'broken_sword', '57_card_last_charge': 'last_charge', '58_card_nameless_witch': 'nameless_card',
    '59_card_small_hand_charm': 'small_charm', '60_card_hero_death_v1': 'hero_death',
}


SOFT = 100   # remove_bg.py --soft (기본 150 은 몸 안쪽 중간색까지 반투명으로 만든다)
REPORT = {}  # 파일 → 안쪽 반투명 비율(%)


def keyed(name, keep_canvas):
    """remove_bg.py(--soft SOFT)로 배경을 지운 RGBA 그림 + 남은 테두리 번짐 제거"""
    tmp = os.path.join(tempfile.mkdtemp(), name + '.png')
    remove_bg.remove_bg(os.path.join(RAW, name + '.webp'), tmp, None, SOFT, 0, keep_canvas, 0)
    im = Image.open(tmp).convert('RGBA')
    bg = remove_bg.estimate_bg(Image.open(os.path.join(RAW, name + '.webp')).convert('RGB').load(), *Image.open(os.path.join(RAW, name + '.webp')).size)
    return edge_fringe(im, bg)


def edge_fringe(im, bg, radius=3, over=40):
    """투명한 곳에서 radius px 안쪽의 남은 크로마 번짐: 초록 키 — G > max(R,B)+over 이면 G = max(R,B) /
    마젠타 키 — min(R,B) > G+over 이면 R·B 를 G+over 까지 내린다 (엘리안 망토 같은 그림 속 초록은 마젠타 키라 건드리지 않음)"""
    a = np.asarray(im).astype(np.int32).copy()
    alpha = a[..., 3]
    m = alpha == 0
    for _ in range(radius):  # 투명한 곳을 radius 만큼 넓힌 테두리 띠
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
        hit = m & (gg > cap + over)
        gg[hit] = cap[hit]
    else:  # 마젠타
        s = np.minimum(r, b) - (gg + over)
        s = np.where(m & (s > 0), s, 0)
        r -= s
        b -= s
    a[..., 0], a[..., 1], a[..., 2] = r, gg, b
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), 'RGBA')


def interior_partial(im):
    """알파>0 영역을 9px MinFilter 로 깎은 안쪽에서 반투명 픽셀 비율(%)과 가장 낮은 알파"""
    al = im.getchannel('A')
    inner = al.point(lambda v: 255 if v > 0 else 0).filter(ImageFilter.MinFilter(9))
    A = np.asarray(al)
    I = np.asarray(inner) > 0
    n = int(I.sum())
    if n == 0:
        return 0.0, 255
    part = I & (A < 255)
    return 100.0 * int(part.sum()) / n, int(A[I].min())


def save(im, out):
    im.save(os.path.join(OUT, out))
    REPORT[out] = interior_partial(im)


def fit_h(im, max_h):
    if max_h and im.height > max_h:
        im = im.resize((round(im.width * max_h / im.height), max_h), Image.LANCZOS)
    return im


def do_sprite(name):
    out, max_h, keep = SPRITES[name]
    im = fit_h(keyed(name, keep), max_h)
    save(im, out)
    if name == '09_noel_hands':
        # 코드는 왼손·오른손을 x=836 에서 나눈 두 장을 쓴다 (layout.hand.splitX)
        w, h = im.size
        save(im.crop((0, 0, 836, h)), 'ui_witch_hand_left.png')
        save(im.crop((836, 0, w, h)), 'ui_witch_hand_right.png')
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
        save(fit_h(im.crop(box), STAND_H), out)
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
        save(sq.resize((size, size), Image.LANCZOS), out)
        res.append(out)
    return res


def do_dialog():
    name, out = DIALOG
    im = keyed(name, False)
    im = im.resize((round(im.width * DIALOG_H / im.height), DIALOG_H), Image.LANCZOS)
    save(im, out)
    return [out]


def do_cards():
    outs = []
    for src, cid in CARDS.items():
        im = Image.open(os.path.join(RAW, src + '.webp')).convert('RGB').resize((CARD_ART, CARD_ART), Image.LANCZOS)
        out = 'card_art_%s.jpg' % cid
        im.save(os.path.join(OUT, out), quality=90)
        outs.append(out)
    return outs


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
    if not only or 'dialog' in only:
        done += do_dialog()
    if not only or 'cards' in only:
        done += do_cards()
    if not only or 'death' in only:
        for n, out in DEATH.items():
            shutil.copyfile(os.path.join(DEATH_DIR, n + '.webp'), os.path.join(OUT, out))
            done.append(out)
    if not only or 'bg' in only:
        for n, out in BGS.items():
            shutil.copyfile(os.path.join(RAW, n + '.webp'), os.path.join(OUT, out))
    if a.check:
        check([f for f in done if f.endswith('.png')], a.check)
    for f, (pct, mn) in REPORT.items():
        print('안쪽 반투명 %-28s %6.2f%%  최소 알파 %d' % (f, pct, mn))
    print('done', len(done), done)
