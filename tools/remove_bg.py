"""단색 배경으로 생성한 GPT 이미지의 배경을 투명하게 만든다.

가장자리와 이어진 배경색 영역만 지우므로, 캐릭터 안쪽의 비슷한 색은 남는다.
사용법: python3 tools/remove_bg.py 입력파일 출력.png [--hard 12] [--soft 28]
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


def remove_bg(src, dst, hard, soft):
    im = Image.open(src).convert("RGBA")
    w, h = im.size
    px = im.load()
    bg = estimate_bg(px, w, h)

    def dist(c):
        return max(abs(c[0] - bg[0]), abs(c[1] - bg[1]), abs(c[2] - bg[2]))

    seen = bytearray(w * h)
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
    bbox = im.getbbox()
    if bbox:
        im = im.crop(bbox)  # 투명 여백 제거
    im.save(dst)
    print(f"{dst}: bg={tuple(round(v) for v in bg)} size={im.size}")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("src"); ap.add_argument("dst")
    ap.add_argument("--hard", type=int, default=12)
    ap.add_argument("--soft", type=int, default=28)
    a = ap.parse_args()
    remove_bg(a.src, a.dst, a.hard, a.soft)
