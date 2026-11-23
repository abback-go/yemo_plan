"""그림체 F 원본(art/raw/vs_f/*.webp)을 전투 시험판 v2.1 「3D 탁자」(?battle=v2) 그림(game/assets/)으로 옮긴다.

- 배경 제거는 tools/vs_import.py 와 같은 방식(keyed: remove_bg.py --soft 100 + 남은 테두리 번짐 빼기)을 그대로 불러 쓴다.
  vs_import.py·remove_bg.py 는 고치지 않는다(원본 폴더만 art/raw/vs_f 로 바꿔 부른다).
- 같은 경로의 원본을 새 판으로 바꾸면 이 도구를 다시 돌리기만 하면 된다(카드 틀은 셋을 자동으로 찾아 자른다).
  · 동료 초상: 28·32·36 스탠딩(초록 바탕) → 배경 제거 → 얼굴~가슴(BUSTS 의 비율 상자) → f_bust_<id>.png (가로 BUST_W)
  · 탁자: 75_bg_battle_table → bg_f_battle_table.webp (그대로 복사, 3D 탁자 바닥 판)
  · 카드 틀: 76_card_frames(초록 바탕, 틀 셋이 가로로) → 배경 제거 → 왼쪽부터 card_frame_f_ally.png(동료·노엘 카드) ·
    card_frame_f_enemy.png(적·적 행동) · card_frame_f_minion.png(하수인). 틀 안쪽 그림 자리가 투명해져 카드 그림을 뒤에 깐다
  · 적: 08 광신도 · 40 무덤지기 · 77 해골 병사(있는 것만) → 배경 제거 → f_spr_<적>.png (높이 900)
  · 노엘의 손: 78 왼손(손패를 띄우는 편 손) · 79 오른손 평소 · 80 오른손 집기 · 81 오른손 가리키기(있는 것만) → f_hand_*.png (캔버스 유지, 가로 HAND_W)
  · 카드 뒷면(밤샘 계획 2 D): 82_card_back(초록 바탕) → 배경 제거 → 카드만 잘라 2:3(BACK_SIZE, 카드 틀처럼 가로를 조금 늘림) → f_card_back.png
    (새 전투의 덱 · 적 덱 · 뒤집힌 카드 · 어둠의 뒷면. 옛 전투의 card_back.png 는 그대로)
  · 예전 전투 양손 그림(game/assets/ui_witch_hand_left·right.png, 그림체 D — 옛 전투와 새 전투의 손패 당겨 보기가 쓴다) → 소매 초록 물듦 지우기
    (G > max(R,B)+CLEAN_MARGIN(20) 이면 G = (R+B)/2, 원본은 덮지 않음) → ui_witch_hand_left·right_clean.png (캔버스 836×941 유지)
    (v2.3 에는 여기에 어둡게·채도 낮게를 더한 ui_witch_hands_open_l·r.png 를 만들었다가 v2.4 에서 지웠다)
사용법: python3 tools/vs_f_import.py [--only busts,enemies,hands,table,frames,back,cleanhands] [--check 폴더]
"""
import argparse
import os
import shutil
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import vs_import  # noqa: E402

RAW_F = os.path.join(vs_import.ROOT, 'art', 'raw', 'vs_f')
OUT = vs_import.OUT

# 동료 초상(카드 그림 창 비율 약 0.78 — 얼굴~가슴): 원본 → (게임 파일, 원본 1024×1536 에서 [x0, y0, x1, y1] 픽셀 상자)
BUSTS = {
    '28_stand_seraphina_calm': ('f_bust_hero.png', [330, 0, 650, 410]),
    '32_stand_brunhild_smirk': ('f_bust_warrior.png', [318, 0, 638, 410]),
    '36_stand_elian_cold': ('f_bust_archer.png', [333, 10, 673, 446]),
}
BUST_W = 320
TABLE = ('75_bg_battle_table', 'bg_f_battle_table.webp')
# 노엘의 손(그림체 F, 초록 바탕, 캔버스 유지 1536×1024 → 가로 HAND_W): 원본 → (게임 파일, 떨어진 조각을 지울 면적 px).
# 79 는 손끝 아래 옅은 그림자 빗금이 초록 위에 있어 배경을 지우면 떠 있는 선이 남는다 → 면적이 작은 떨어진 조각을 지운다. 원본이 없으면 건너뛴다
HANDS = {
    '78_hand_left_hold': ('f_hand_left_hold.png', 600),
    '79_hand_right_idle': ('f_hand_right_idle.png', 600),
    '80_hand_right_pinch_point': ('f_hand_right_pinch.png', 600),
    '81_hand_right_point': ('f_hand_right_point.png', 600),
}
# 그림 가장자리에서 잘린 소매를 옅게 지우는 띠(가로·세로 몫): 가리키는 손(81)은 탁자 가운데까지 옮겨 가 그림의 오른쪽·아래 끝이 화면 안에 들어온다
# → 잘린 소매 끝이 곧은 선으로 보이지 않게 오른쪽·아래 띠를 투명 쪽으로 옅게(밤샘 계획 2 D). 평소 손(79)은 화면 구석이라 필요 없다
HAND_FADE = {'81_hand_right_point': (0.3, 0.3)}
HAND_W = 1152
# 적 그림(그림체 F, 초록 바탕): 원본 → (게임 파일, 최대 높이). 원본이 아직 없으면 건너뛴다 — 게임은 파일이 있으면 F 그림, 없으면 예전 그림(battle_v2_data.gd enemies.art)
ENEMIES = {
    '08_cultist': ('f_spr_cultist.png', 900),
    '40_gravekeeper': ('f_spr_gravekeeper.png', 900),
    '77_skeleton_soldier': ('f_spr_skeleton.png', 900),
}
FRAMES = ('76_card_frames', ['card_frame_f_ally.png', 'card_frame_f_enemy.png', 'card_frame_f_minion.png'])
BACK = ('82_card_back', 'f_card_back.png')
BACK_SIZE = (480, 720)   # 카드 2:3(탁자 카드·손패 카드와 같은 비율)


def keyed_f(name, keep_canvas):
    """vs_import.keyed 를 원본 폴더만 vs_f 로 바꿔 부른다"""
    old = vs_import.RAW
    vs_import.RAW = RAW_F
    try:
        return vs_import.keyed(name, keep_canvas)
    finally:
        vs_import.RAW = old


def do_busts():
    outs = []
    for src, (out, box) in BUSTS.items():
        im = keyed_f(src, True)
        w, h = im.size
        x0, y0, x1, y1 = box
        crop = Image.new('RGBA', (x1 - x0, y1 - y0), (0, 0, 0, 0))
        crop.paste(im.crop((max(0, x0), max(0, y0), min(w, x1), min(h, y1))), (max(0, -x0), max(0, -y0)))
        crop = crop.resize((BUST_W, round(BUST_W * crop.height / crop.width)), Image.LANCZOS)
        vs_import.save(crop, out)
        outs.append(out)
    return outs


def do_enemies():
    outs = []
    for src, (out, max_h) in ENEMIES.items():
        if not os.path.exists(os.path.join(RAW_F, src + '.webp')):
            print('없음(건너뜀):', src)
            continue
        im = vs_import.fit_h(keyed_f(src, False), max_h)
        vs_import.save(im, out)
        outs.append(out)
    return outs


def do_hands():
    outs = []
    for src, (out, min_area) in HANDS.items():
        if not os.path.exists(os.path.join(RAW_F, src + '.webp')):
            print('없음(건너뜀):', src)
            continue
        im = keyed_f(src, True)
        # 손 그림에는 초록이 없다 → 초록 위 옅은 그림자 빗금처럼 남은 초록빛 픽셀은 지운다(G 가 R·B 보다 25 넘게 크면 투명)
        a = np.asarray(im).astype(np.int32).copy()
        green = (a[..., 1] > a[..., 0] + 25) & (a[..., 1] > a[..., 2] + 25)
        a[..., 3] = np.where(green, 0, a[..., 3])
        im = Image.fromarray(a.astype(np.uint8), 'RGBA').copy()
        if min_area:
            vs_import.remove_bg.remove_small_islands(im, min_area)
        im = im.resize((HAND_W, round(HAND_W * im.height / im.width)), Image.LANCZOS)
        if src in HAND_FADE:
            fx, fy = HAND_FADE[src]
            a = np.asarray(im).astype(np.float32).copy()
            h, w = a.shape[:2]
            rx = np.clip((w - 1 - np.arange(w)) / max(1.0, fx * w), 0, 1)
            ry = np.clip((h - 1 - np.arange(h)) / max(1.0, fy * h), 0, 1)
            ramp = np.minimum(ry[:, None], rx[None, :])
            a[..., 3] *= ramp * ramp * (3 - 2 * ramp)   # smoothstep
            im = Image.fromarray(np.clip(np.round(a), 0, 255).astype(np.uint8), 'RGBA')
        vs_import.save(im, out)
        outs.append(out)
    return outs


# 예전 전투 양손 그림의 소매 초록 물듦 지우기(밤샘 계획 2 D): 원본(게임 폴더 안 예전 그림 — 덮지 않음) → 결과
CLEAN_HANDS = {'ui_witch_hand_left.png': 'ui_witch_hand_left_clean.png', 'ui_witch_hand_right.png': 'ui_witch_hand_right_clean.png'}
# 초록으로 보는 기준: G 가 max(R, B) 보다 이만큼 넘게 크면(지시 +20). +20 이면 옅은 올리브빛(G 가 1~20 큼)은 남는다 — 0 으로 하면 그것까지 지운다
CLEAN_MARGIN = 20


def do_clean_hands():
    outs = []
    for src, out in CLEAN_HANDS.items():
        a = np.asarray(Image.open(os.path.join(OUT, src)).convert('RGBA')).astype(np.float32)
        r, g, b = a[..., 0], a[..., 1], a[..., 2]
        green = (g > np.maximum(r, b) + CLEAN_MARGIN) & (a[..., 3] > 0)
        a[..., 1] = np.where(green, (r + b) / 2.0, g)
        im = Image.fromarray(np.clip(np.round(a), 0, 255).astype(np.uint8), 'RGBA')
        vs_import.save(im, out)
        print('양손 %s: 초록 물듦 %d px 지움' % (out, int(green.sum())))
        outs.append(out)
    return outs


def do_back():
    src, out = BACK
    if not os.path.exists(os.path.join(RAW_F, src + '.webp')):
        print('없음(건너뜀):', src)
        return []
    im = keyed_f(src, True)
    im = im.crop(im.getbbox())
    print('카드 뒷면: 잘라 낸 크기 %s 비율 %.3f → %s' % (im.size, im.width / im.height, BACK_SIZE))
    im = im.resize(BACK_SIZE, Image.LANCZOS)
    vs_import.save(im, out)
    return [out]


def do_table():
    src, out = TABLE
    shutil.copyfile(os.path.join(RAW_F, src + '.webp'), os.path.join(OUT, out))
    return [out]


def do_frames():
    """배경을 지운 한 장에서 불투명한 열이 이어진 덩어리 셋(틀)을 찾아 각각 잘라 낸다"""
    src, outs = FRAMES
    im = keyed_f(src, True)
    a = np.asarray(im.getchannel('A')) > 8
    cols = a.sum(axis=0) > 6
    runs = []
    x = 0
    w = len(cols)
    while x < w:
        if cols[x]:
            s = x
            while x < w and cols[x]:
                x += 1
            runs.append((s, x))
        else:
            x += 1
    runs = sorted(runs, key=lambda r: r[1] - r[0], reverse=True)[:3]
    runs.sort()
    if len(runs) != 3:
        raise SystemExit('카드 틀 셋을 찾지 못함: %s' % runs)
    res = []
    for (x0, x1), out in zip(runs, outs):
        part = im.crop((x0, 0, x1, im.height))
        part = part.crop(part.getbbox())
        vs_import.save(part, out)
        print('틀 %s: x %d–%d 크기 %s 비율 %.3f' % (out, x0, x1, part.size, part.width / part.height))
        res.append(out)
    return res


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--only', default='')
    ap.add_argument('--check', default='')
    a = ap.parse_args()
    only = set(x for x in a.only.split(',') if x)
    done = []
    if not only or 'busts' in only:
        done += do_busts()
    if not only or 'enemies' in only:
        done += do_enemies()
    if not only or 'hands' in only:
        done += do_hands()
    if not only or 'table' in only:
        done += do_table()
    if not only or 'frames' in only:
        done += do_frames()
    if not only or 'back' in only:
        done += do_back()
    if not only or 'cleanhands' in only:
        done += do_clean_hands()
    if a.check:
        vs_import.check([f for f in done if f.endswith('.png')], a.check)
    for f, (pct, mn) in vs_import.REPORT.items():
        print('안쪽 반투명 %-28s %6.2f%%  최소 알파 %d' % (f, pct, mn))
    print('done', len(done), done)
