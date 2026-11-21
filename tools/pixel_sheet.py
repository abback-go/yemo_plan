"""GPT로 뽑은 픽셀아트 스프라이트 시트(초록 #00FF00 배경)를 실제 픽셀 크기로 정리한다.

1) 픽셀 블록 크기·격자 위치를 자동으로 찾아 블록마다 가운데 색(중앙값)으로 줄인다.
2) 초록 배경을 투명하게, 가장자리에 번진 초록을 뺀다(디스필).
3) 색을 --colors 개로 정리한다(디더링 없음).
4) cols×rows 칸으로 나눠, 칸마다 발끝을 같은 높이에 맞춰 --cell 크기 칸에 다시 담는다.
사용법: python3 tools/pixel_sheet.py 입력.png 출력.png [--chroma green|magenta] [--cols 3] [--rows 4] [--cell 64] [--colors 32] [--preview 미리보기.png]
맵·배경처럼 한 장 그림: --no-key(초록 배경 제거 안 함) --whole(칸 나누기 없이 줄인 그림 그대로)
  격자가 고르지 않은 그림은 --block 2.5 처럼 블록 크기를 직접 정한다(격자 찾기 생략, 시작점은 --offset 0,0).
  예: python3 tools/pixel_sheet.py art/raw/map_f1_fork_raw.png game/assets/td_f1_fork.png --no-key --whole --block 2.5 --colors 64
"""
import argparse
from collections import deque
import numpy as np
from PIL import Image


def find_grid(im):
    """블록 크기 p와 격자 시작점. 먼저 색 경계 간격으로 p 후보를 좁힌 뒤, 블록 안 분산이 가장 작은 격자를 고른다."""
    H, W, _ = im.shape
    d = (np.abs(np.diff(im, axis=1)).sum(2) > 40).sum(0).astype(float)
    cand = []
    for p in np.arange(3.0, 12.01, 0.05):
        sc = max(d[np.round(np.arange(o, W - 2, p)).astype(int)].mean() for o in np.arange(0, p, 0.5))
        cand.append((sc / d.mean(), p))
    cand.sort(reverse=True)
    ps = sorted({round(p, 2) for _, p in cand[:4]})
    # 큰 후보가 작은 후보의 배수면 작은 쪽이 진짜 블록일 가능성이 높아 둘 다 정밀 탐색
    best = None
    for p0 in ps:
        for p in np.arange(p0 - 0.15, p0 + 0.151, 0.03):
            for ox in np.arange(0, p, 0.6):
                for oy in np.arange(0, p, 0.6):
                    tot = n = 0
                    for y in np.arange(oy, H - p, p)[::4]:
                        for x in np.arange(ox, W - p, p)[::4]:
                            b = im[int(y) + 1:int(y + p) - 1, int(x) + 1:int(x + p) - 1]
                            if b.size:
                                tot += b.var(axis=(0, 1)).sum(); n += 1
                    s = tot / max(n, 1)
                    if best is None or s < best[0]:
                        best = (s, p, ox, oy)
    return best[1:]


def downsample(im, p, ox, oy, key=True, chroma='green'):
    H, W, _ = im.shape
    nx, ny = int((W - ox) // p), int((H - oy) // p)
    out = np.zeros((ny, nx, 4), np.uint8)
    for j in range(ny):
        for i in range(nx):
            x0, y0 = ox + i * p, oy + j * p
            b = im[int(y0 + p * .3):int(y0 + p * .7) + 1, int(x0 + p * .3):int(x0 + p * .7) + 1].reshape(-1, 3)
            r, g, bb = np.median(b, axis=0)
            if chroma == 'magenta':
                bg = key and r > 90 and bb > 90 and min(r, bb) - g > 35
                s = min(r, bb) - g  # 가장자리에 번진 마젠타 빼기(빨강·파랑이 함께 초록보다 큰 만큼)
                if not bg and s > 0 and abs(r - bb) < 40:
                    r, bb = r - s * .6, bb - s * .6
                out[j, i, :3] = (r, g, bb)
            else:
                bg = key and g > 90 and g - max(r, bb) > 35
                out[j, i, :3] = (r, min(g, max(r, bb)), bb)
            out[j, i, 3] = 0 if bg else 255
    return out


def quantize(arr, colors):
    a = arr[:, :, 3]
    op = arr[a > 0][:, :3]
    pal = Image.fromarray(op.reshape(1, -1, 3), 'RGB').quantize(colors=colors, method=Image.Quantize.MAXCOVERAGE, dither=Image.Dither.NONE)
    q = Image.fromarray(arr[:, :, :3], 'RGB').quantize(palette=pal, dither=Image.Dither.NONE).convert('RGB')
    return np.dstack([np.asarray(q), a]).astype(np.uint8)


def drop_specks(cell, min_area=6):
    m = cell[:, :, 3] > 0
    h, w = m.shape
    seen = np.zeros_like(m)
    for y in range(h):
        for x in range(w):
            if m[y, x] and not seen[y, x]:
                comp = []; q = deque([(y, x)]); seen[y, x] = True
                while q:
                    cy, cx = q.popleft(); comp.append((cy, cx))
                    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        yy, xx = cy + dy, cx + dx
                        if 0 <= yy < h and 0 <= xx < w and m[yy, xx] and not seen[yy, xx]:
                            seen[yy, xx] = True; q.append((yy, xx))
                if len(comp) < min_area:
                    for cy, cx in comp:
                        cell[cy, cx, 3] = 0


def pack(a, cols, rows, C):
    H, W = a.shape[:2]
    cw, ch = W / cols, H / rows
    sheet = Image.new('RGBA', (C * cols, C * rows), (0, 0, 0, 0))
    for r in range(rows):
        for c in range(cols):
            x0, y0 = int(round(c * cw)), int(round(r * ch))
            x1, y1 = int(round((c + 1) * cw)), int(round((r + 1) * ch))
            cell = a[y0:y1, x0:x1].copy()
            drop_specks(cell)
            ys, _ = np.where(cell[:, :, 3] > 0)
            if not len(ys):
                continue
            fr = Image.fromarray(cell, 'RGBA')
            px = int(round(C / 2 - (x1 - x0) / 2)); py = (C - 2) - ys.max()
            tmp = Image.new('RGBA', (C, C), (0, 0, 0, 0)); tmp.paste(fr, (px, py), fr)
            sheet.alpha_composite(tmp, (c * C, r * C))
    return sheet


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('src'); ap.add_argument('dst')
    ap.add_argument('--cols', type=int, default=3); ap.add_argument('--rows', type=int, default=4)
    ap.add_argument('--cell', type=int, default=64); ap.add_argument('--colors', type=int, default=32)
    ap.add_argument('--preview')
    ap.add_argument('--no-key', action='store_true', help='초록 배경을 빼지 않는다(맵·배경 그림)')
    ap.add_argument('--chroma', default='green', choices=['green', 'magenta'], help='배경색(기본 초록 #00FF00)')
    ap.add_argument('--whole', action='store_true', help='칸으로 나누지 않고 줄인 그림 한 장으로 저장')
    ap.add_argument('--block', type=float, help='픽셀 블록 크기를 직접 지정(격자 찾기 생략)')
    ap.add_argument('--offset', default='0,0', help='--block 과 함께: 격자 시작점 x,y')
    o = ap.parse_args()
    im = np.asarray(Image.open(o.src).convert('RGB')).astype(float)
    if o.block:
        p = o.block
        ox, oy = (float(v) for v in o.offset.split(','))
    else:
        p, ox, oy = find_grid(im)
    print(f'픽셀 블록 {p:.2f}px, 격자 시작 ({ox:.1f},{oy:.1f})')
    a = quantize(downsample(im, p, ox, oy, key=not o.no_key, chroma=o.chroma), o.colors)
    sheet = Image.fromarray(a, 'RGBA') if o.whole else pack(a, o.cols, o.rows, o.cell)
    sheet.save(o.dst)
    print('저장', o.dst, sheet.size)
    if o.preview:
        bg = Image.new('RGBA', sheet.size, (40, 36, 44, 255)); bg.alpha_composite(sheet)
        bg.resize((sheet.width * 4, sheet.height * 4), Image.NEAREST).save(o.preview)


if __name__ == '__main__':
    main()
