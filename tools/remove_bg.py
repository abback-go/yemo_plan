"""단색 배경으로 생성한 GPT 이미지의 배경을 투명하게 만든다.

일반 단색 배경: 가장자리와 이어진 배경색 영역만 지우므로, 캐릭터 안쪽의 비슷한 색은 남는다.
크로마 배경: 그 색은 캐릭터에 없다고 보고 이미지 전체에서 지운다(머리카락 사이 틈 포함).
크로마 배경(순수 초록·마젠타)이면 문턱값을 자동으로 넓히고, 가장자리에 번진 배경색을 뺀다(디스필).
사용법: python3 tools/remove_bg.py 입력파일 출력.png [--hard N] [--soft N]
"""
import argparse
from collections import deque
from PIL import Image


def estimate_bg(px, w, h):
    pts = []
    for x in range(0, w, 4):
        pts += [px[x, 0], px[x, h - 1]]
    for y in range(0, h, 4):
        pts += [px[0, y], px[w - 1, y]]
    pts.sort(key=sum)
    mid = pts[len(pts) // 4: len(pts) * 3 // 4]  # 극단값을 뺀 가운데 절반 평균
    return tuple(sum(c[i] for c in mid) / len(mid) for i in range(3))


def is_chroma(bg):
    return max(bg) - min(bg) > 120


def despill(c, bg):
    r, g, b, a = c
    if bg[1] > bg[0] and bg[1] > bg[2]:  # 초록 배경: 초록이 나머지보다 크면 깎는다
        g = min(g, max(r, b))
    elif bg[0] > bg[1] and bg[2] > bg[1]:  # 마젠타 배경: 빨강·파랑이 함께 초록보다 큰 만큼 깎는다
        s = min(r, b) - g
        if s > 0:
            r -= s; b -= s
    return (r, g, b, a)


def remove_bg(src, dst, hard, soft):
    im = Image.open(src).convert("RGBA")
    w, h = im.size
    px = im.load()
    bg = estimate_bg(px, w, h)
    chroma = is_chroma(bg)
    if hard is None:
        hard = 60 if chroma else 12
    if soft is None:
        soft = 150 if chroma else 28

    def dist(c):
        return max(abs(c[0] - bg[0]), abs(c[1] - bg[1]), abs(c[2] - bg[2]))

    if chroma:
        # 크로마 배경색은 캐릭터에 없는 색이므로, 머리카락 사이 같은 닫힌 틈까지 전체를 검사한다
        for y in range(h):
            for x in range(w):
                r, g, b, a = px[x, y]
                d = dist((r, g, b))
                if d < soft:
                    px[x, y] = (r, g, b, 0 if d <= hard else int(255 * (d - hard) / (soft - hard)))
    seen = bytearray(w * h) if not chroma else bytearray(b"\x01" * (w * h))
    q = deque()
    for x in range(w):
        q.append((x, 0)); q.append((x, h - 1))
    for y in range(h):
        q.append((0, y)); q.append((w - 1, y))
    while q:
        x, y = q.popleft()
        i = y * w + x
        if seen[i]:
            continue
        seen[i] = 1
        r, g, b, a = px[x, y]
        d = dist((r, g, b))
        if d >= soft:
            continue  # 캐릭터 경계: 여기서 멈춤
        alpha = 0 if d <= hard else int(255 * (d - hard) / (soft - hard))
        px[x, y] = (r, g, b, min(a, alpha))
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not seen[ny * w + nx]:
                q.append((nx, ny))
    if chroma:  # 반투명 가장자리와 그 바로 안쪽 2px의 번진 배경색 제거
        alpha = [[px[x, y][3] for x in range(w)] for y in range(h)]
        for y in range(h):
            for x in range(w):
                if alpha[y][x] == 0:
                    continue
                edge = alpha[y][x] < 255
                if not edge:
                    for dy in (-2, -1, 0, 1, 2):
                        yy = y + dy
                        if 0 <= yy < h and (alpha[yy][max(x - 2, 0)] < 255 or alpha[yy][min(x + 2, w - 1)] < 255):
                            edge = True
                            break
                if edge:
                    px[x, y] = despill(px[x, y], bg)
    bbox = im.getbbox()
    if bbox:
        im = im.crop(bbox)  # 투명 여백 제거
    im.save(dst)
    print(f"{dst}: bg={tuple(round(v) for v in bg)} size={im.size}")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("src"); ap.add_argument("dst")
    ap.add_argument("--hard", type=int, default=None)
    ap.add_argument("--soft", type=int, default=None)
    a = ap.parse_args()
    remove_bg(a.src, a.dst, a.hard, a.soft)
