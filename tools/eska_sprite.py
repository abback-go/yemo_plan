"""에스카 사이드뷰 스프라이트 리그 (오른쪽을 봄, 2배 해상도) — 대기·달리기·점프·이단점프·대시 프레임을 그린다.
기준: docs/gdd/assets/eska-sheet-v3.png, 앵커 tools/make_eska_prompts.py.

구조
- 몸의 치수·관절·자세 값은 1배 단위(대기 자세에서 정수리 y18, 발바닥 y69)로 적고, 그릴 때 K배 격자에 찍는다.
  그래서 실루엣 비례는 1배 때와 같고, 선·장식·머릿결은 K배 격자에서 1px로 더 가늘고 촘촘하게 들어간다.
- 얼굴은 K배 격자에 손으로 찍은 스탬프, 상체·모자 띠·챙은 다각형, 모자 원뿔·다리·팔·머리 가닥·검집은 중심선 굵기로 계산.
- 상체·머리·모자는 엉덩이를 축으로 숙인다. RotSprite 방식 (Scale2x 세 번으로 8배 키워 경계를 살린 뒤 회전하고, 칸 가운데 색을 골라 다시 줄임).
- 빛: 뒤(왼쪽)에서 오는 차가운 역광 → 뒤쪽 가장자리가 밝다. 외곽선은 셀아웃(맞닿은 색을 어둡게).
"""
import math
import pathlib
import sys
import numpy as np
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
K = 2                       # 해상도 배율 (1배 단위 → 칸 픽셀)
W, H = 80 * K, 88 * K       # 프레임 한 칸
OX, OY = 22 * K, 8 * K      # 1배 로컬 원점의 칸 좌표
PIV, PIV_X = 44, 22.0       # 상체를 숙일 때 축 (엉덩이, 1배 단위)


def hx(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


C = {
    "hat_d": hx("#0e1328"), "hat": hx("#19213e"), "hat_m": hx("#212b4e"), "hat_l": hx("#2c3964"), "hat_r": hx("#5069a8"),
    "band": hx("#05060c"), "band_l": hx("#1a1e2c"), "silver": hx("#d6deec"), "silver_d": hx("#7b86a0"), "silver_h": hx("#f4f8ff"),
    "hair_dd": hx("#121a2d"), "hair_d": hx("#1f2c4b"), "hair_m": hx("#2a3b5f"), "hair": hx("#344a72"),
    "hair_l": hx("#4c6696"), "hair_h": hx("#7f9dcc"), "hair_s": hx("#a9c2e8"),
    "skin_d": hx("#76829c"), "skin_s": hx("#a3afc6"), "skin_m": hx("#bcc6da"), "skin": hx("#d2dae8"), "skin_h": hx("#eef3fb"),
    "under": hx("#8e9ab9"),
    "eye": hx("#a8e2ff"), "eye_m": hx("#6cb8e6"), "eye2": hx("#3f7fb3"), "lash": hx("#0a0e1a"), "lash_m": hx("#2a3550"),
    "lip": hx("#9aa3bd"),
    "bl_d": hx("#0f1530"), "bl": hx("#1c2546"), "bl_m": hx("#243058"), "bl_l": hx("#2f3c6c"), "bl_r": hx("#4a5c9e"),
    "shawl_d": hx("#3c4864", 205), "shawl": hx("#56647f", 190), "shawl_l": hx("#8494b2", 215),
    "cor": hx("#0a0d19"), "cor_m": hx("#151a2c"), "cor_l": hx("#2a3250"),
    "sk_d": hx("#0e1327"), "sk": hx("#1a2242"), "sk_m": hx("#212b50"), "sk_r": hx("#43559a"),
    "boot": hx("#0a0c15"), "boot_m": hx("#181c2a"), "boot_l": hx("#2e3550"),
    "sc_d": hx("#151c2f"), "sc": hx("#273450"), "sc_l": hx("#46597f"),
    "tw_d": hx("#0f0c13"), "tw": hx("#221d29"), "tw_l": hx("#3d3548"), "cord": hx("#556080"),
    "grip": hx("#131724"), "grip_l": hx("#2d3448"), "gem": hx("#9fd8ff"), "gem_d": hx("#4f8fc4"),
    "ink": hx("#020308"),
    "sheer": hx("#2a3a72", 100), "sheer2": hx("#3a4d8e", 125), "sheer_e": hx("#7487bc", 175), "emb": hx("#c4d2ee", 215),
    "veil": hx("#1c2858", 90), "veil_e": hx("#3f4f8c", 120),
}

# ---------------------------------------------------------------- 그리기 상태
img = None
P = None
BX = BY = 0      # 몸 전체 이동 (1배 단위)
LEAN = 0.0       # 상체를 앞으로 숙인 각도 (도)
DY = 0           # 머리 쪽 부품은 2(1배 단위) 위로


def cv(x, y):
    """1배 로컬 좌표 → 칸 좌표 (실수)."""
    return ((x + BX) * K + OX, (y + BY + DY) * K + OY)


def ub(x, y):
    """상체에 붙은 점의 실제 위치 (숙임 회전 반영, 1배 단위)."""
    a = math.radians(LEAN)
    dx, dy = x - PIV_X, y - PIV
    return (PIV_X + dx * math.cos(a) - dy * math.sin(a), PIV + dx * math.sin(a) + dy * math.cos(a))


def dot(x, y, c):
    """칸 좌표 한 픽셀 (반투명 색은 섞음)."""
    x, y = int(x), int(y)
    if not (0 <= x < W and 0 <= y < H):
        return
    if isinstance(c, str):
        if c == "clear":
            P[x, y] = (0, 0, 0, 0)
            return
        c = C[c]
    if c[3] >= 255:
        P[x, y] = c
        return
    r, g, b, a = P[x, y]
    if a == 0:
        P[x, y] = c
        return
    t = c[3] / 255
    P[x, y] = (round(r * (1 - t) + c[0] * t), round(g * (1 - t) + c[1] * t), round(b * (1 - t) + c[2] * t), max(a, c[3]))


def pt(x, y, c):
    """1배 좌표의 점 하나 → 칸 픽셀 하나 (가는 장식용)."""
    X, Y = cv(x, y)
    dot(math.floor(X), math.floor(Y), c)


def line(x0, y0, x1, y1, c):
    """1배 좌표 사이의 1px 선 (칸 해상도)."""
    (a, b), (e, f) = cv(x0, y0), cv(x1, y1)
    x0, y0, x1, y1 = math.floor(a), math.floor(b), math.floor(e), math.floor(f)
    dx, dy = abs(x1 - x0), -abs(y1 - y0)
    sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
    err = dx + dy
    while True:
        dot(x0, y0, c)
        if x0 == x1 and y0 == y1:
            break
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x0 += sx
        if e2 <= dx:
            err += dx
            y0 += sy


def poly_cells(pts):
    """1배 좌표 다각형 → 칸 픽셀 집합."""
    pts = [cv(*p) for p in pts]
    cells = set()
    ys = [p[1] for p in pts]
    for y in range(math.floor(min(ys)), math.ceil(max(ys)) + 1):
        cy = y + 0.5
        xs = []
        n = len(pts)
        for i in range(n):
            (x0, y0), (x1, y1) = pts[i], pts[(i + 1) % n]
            if (y0 <= cy < y1) or (y1 <= cy < y0):
                xs.append(x0 + (cy - y0) * (x1 - x0) / (y1 - y0))
        xs.sort()
        for i in range(0, len(xs) - 1, 2):
            for x in range(math.floor(xs[i] + 0.5), math.floor(xs[i + 1] + 0.5)):
                cells.add((x, y))
    return cells


def poly(pts, c):
    for (x, y) in poly_cells(pts):
        dot(x, y, c)


def tube(center, width):
    """1배 좌표 중심선을 따라 폭 width(t)(1배 단위)로 채운 칸 픽셀 → {칸: t}."""
    center = [cv(*q) for q in center]
    seg = [math.dist(center[i], center[i + 1]) for i in range(len(center) - 1)]
    total = sum(seg) or 1.0
    samples = []
    acc = 0.0
    for i, L in enumerate(seg):
        (x0, y0), (x1, y1) = center[i], center[i + 1]
        if L == 0:
            continue
        n = max(2, int(L * 3))
        for k in range(n):
            u = k / n
            samples.append((x0 + (x1 - x0) * u, y0 + (y1 - y0) * u, (acc + L * u) / total, (x1 - x0) / L, (y1 - y0) / L))
        acc += L
    if not samples:
        return {}
    samples.append((*center[-1], 1.0, samples[-1][3], samples[-1][4]))
    cells = {}
    for (x, y, t, dx, dy) in samples:
        w = width(t) * K / 2
        nx, ny = -dy, dx
        steps = max(1, int(w * 3))
        for k in range(-steps, steps + 1):
            q = k / steps * w
            c = (math.floor(x + nx * q), math.floor(y + ny * q))
            cells[c] = max(cells.get(c, 0), t)
    return cells


def paint(cells, base, left=None, right=None, top=None, bottom=None, left2=None, right2=None):
    """칸 픽셀 집합을 칠하고 가장자리에 빛·그늘. left2/right2 = 가장자리 바로 안쪽 한 줄 (둥근 면)."""
    for c in cells:
        dot(*c, base)
    for (x, y) in cells:
        if left2 and (x - 1, y) in cells and (x - 2, y) not in cells:
            dot(x, y, left2)
        if right2 and (x + 1, y) in cells and (x + 2, y) not in cells:
            dot(x, y, right2)
    for (x, y) in cells:
        if left and (x - 1, y) not in cells:
            dot(x, y, left)
        elif right and (x + 1, y) not in cells:
            dot(x, y, right)
        elif top and (x, y - 1) not in cells:
            dot(x, y, top)
        elif bottom and (x, y + 1) not in cells:
            dot(x, y, bottom)


def stamp(x0, y0, rows, key):
    """칸 해상도로 손으로 찍은 그림. (x0, y0) = 1배 좌표의 왼쪽 위."""
    X, Y = cv(x0, y0)
    X, Y = round(X), round(Y)
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            if ch in key:
                dot(X + i, Y + j, key[ch])


def bezier(p0, p1, p2, n=12):
    out = []
    for i in range(n + 1):
        t = i / n
        a, b, c = (1 - t) ** 2, 2 * (1 - t) * t, t * t
        out.append((a * p0[0] + b * p1[0] + c * p2[0], a * p0[1] + b * p1[1] + c * p2[1]))
    return out


def lifted(fn):
    """머리 쪽 부품은 2(1배 단위) 위로 그린다 (목을 확보)."""
    def wrap(*a):
        global DY
        DY = -2
        fn(*a)
        DY = 0
    return wrap


def add(p, q, k=1.0):
    return (p[0] + q[0] * k, p[1] + q[1] * k)


def scale2x(a):
    """EPX/Scale2x: 계단 경계를 살려 2배로."""
    pad = np.pad(a, ((1, 1), (1, 1), (0, 0)), mode="edge")
    Pm = pad[1:-1, 1:-1]
    A, B, Cc, D = pad[:-2, 1:-1], pad[1:-1, 2:], pad[1:-1, :-2], pad[2:, 1:-1]

    def eq(x, y):
        return np.all(x == y, axis=-1)[..., None]
    e0 = np.where(eq(Cc, A) & ~eq(Cc, D) & ~eq(A, B), A, Pm)
    e1 = np.where(eq(A, B) & ~eq(A, Cc) & ~eq(B, D), B, Pm)
    e2 = np.where(eq(D, Cc) & ~eq(D, B) & ~eq(Cc, A), Cc, Pm)
    e3 = np.where(eq(B, D) & ~eq(B, A) & ~eq(D, Cc), D, Pm)
    h, w = a.shape[:2]
    out = np.empty((h * 2, w * 2, 4), dtype=a.dtype)
    out[0::2, 0::2], out[0::2, 1::2], out[1::2, 0::2], out[1::2, 1::2] = e0, e1, e2, e3
    return out


def rotsprite(layer, deg, pivot):
    """도트를 깨지지 않게 돌린다. deg 양수 = 시계 방향(앞으로 숙임). pivot = 칸 좌표."""
    if abs(deg) < 0.01:
        return layer
    a = np.array(layer)
    for _ in range(3):
        a = scale2x(a)
    big = Image.fromarray(a).rotate(-deg, resample=Image.NEAREST, center=(pivot[0] * 8 + 4, pivot[1] * 8 + 4))
    return Image.fromarray(np.array(big)[4::8, 4::8])


# ================================================================ 상체 (숙임 회전 층)
def torso(_):
    # 목: 턱 밑은 그늘
    neck = poly_cells([(20.2, 28.2), (23.0, 28.2), (23.2, 31.2), (20.0, 31.2)])
    paint(neck, "skin_s", left="skin_d")
    for (x, y) in neck:
        if y <= cv(0, 28.9)[1]:
            dot(x, y, "skin_d")
    # 드러난 어깨·쇄골
    sh = poly_cells([(18.6, 30.7), (21.5, 30.3), (24.6, 30.6), (25.6, 31.9), (18.3, 32.3)])
    paint(sh, "skin", left="skin_s", top="skin_m")
    line(21.6, 31.2, 24.6, 31.0, "skin_h")   # 쇄골 빛
    line(21.0, 31.6, 23.4, 31.5, "skin_m")   # 쇄골 아래 그늘
    # 블라우스: 일자 목선, 가슴 둥근 면, 가슴 밑 그늘
    bl = poly_cells([(18.4, 32.0), (25.7, 31.8), (26.7, 32.6), (27.1, 33.8), (26.8, 35.0), (25.8, 35.9), (19.0, 36.1), (18.5, 34.0)])
    paint(bl, "bl", left="bl_d", right="bl_l", left2="bl_m", right2="bl_m")
    line(18.6, 32.0, 25.6, 31.8, "bl_l")       # 목선
    for i in range(7):                           # 목선 은실 글자 자수 (점선)
        pt(19.2 + i * 1.0, 32.25, "silver_d" if i % 2 else "silver")
    line(25.6, 33.1, 26.6, 33.6, "bl_r")        # 가슴 윗면 빛
    line(20.0, 35.8, 25.4, 35.7, "bl_d")        # 가슴 밑 그늘
    # 하이웨이스트 코르셋 + 은색 끈 (X자)
    cor = poly_cells([(19.0, 36.0), (25.3, 35.9), (24.5, 38.4), (24.3, 40.0), (24.9, 41.8), (19.0, 41.9), (19.7, 39.4), (19.4, 37.4)])
    paint(cor, "cor", right="cor_l", left2="cor_m")
    line(19.2, 36.1, 25.2, 36.0, "cor_l")
    for i in range(5):
        y = 36.6 + i * 1.05
        pt(23.6, y, "silver")
        pt(24.1, y + 0.5, "silver_d")
    line(19.2, 41.8, 24.8, 41.7, "cor_l")


def shawl_back(_):
    # 숄의 등 쪽: 등을 가로질러 아래로 처진 얇은 니트 (짜임 점 + 짧은 술)
    cells = poly_cells([(14.4, 37.2), (17.0, 36.7), (19.8, 36.6), (19.8, 39.0), (17.4, 39.8), (15.2, 40.2), (14.2, 39.2)])
    paint(cells, "shawl", top="shawl_l")
    for (x, y) in cells:
        if (x * 2 + y) % 5 == 0:
            dot(x, y, "shawl_d")
    low = {}
    for (x, y) in cells:
        low[x] = max(low.get(x, -99), y)
    for i, x in enumerate(sorted(low)):
        if i % 2 == 0:
            for k in range((3, 5, 2, 4)[(i // 2) % 4]):
                dot(x, low[x] + 1 + k, "shawl_d" if k % 2 else "shawl")


@lifted
def head(_):
    # 머리: 뒤쪽은 세로로 흐르는 머릿결(결 줄 + 뒤 가장자리 역광)을 자동으로 깔고, 얼굴은 칸 해상도로 손으로 찍는다.
    # 얼굴: 챙 그늘 아래 이마, 끝이 처진 긴 속눈썹, 하이라이트 없이 빛나는 눈, 눈 밑 그늘, 작은 코끝, 얇은 입술, 뾰족한 턱.
    FACE = [
        # c16 ~ c27
        "HDDDDDDD....",  # r0  챙 밑
        "HHDDDDDDD...",  # r1
        "HDHHDDSS_...",  # r2  이마 (챙 그늘)
        "HDHHHDSSS_..",  # r3
        "HHDHDHDSSS__",  # r4  뾰족한 앞머리 끝
        "HHmDDSkkkkk_",  # r5  긴 속눈썹 (끝이 앞으로 뻗음)
        "HHDDSkeiEEs_",  # r6  처진 눈꼬리 + 빛나는 눈
        "HHmDSuueEEs_",  # r7
        "HHHDSsuuuss_",  # r8  눈 밑 그늘
        "HHHDSssssssv",  # r9  코끝
        "HHHDSsssssS_",  # r10
        "HHHDSssssS__",  # r11
        "HHHDSssssss_",  # r12 윗입술
        "HHHDSssssl__",  # r13 입술 선
        "HHHDSSssss__",  # r14
        "HHHD_Ssss___",  # r15 턱
        "HHHD__SssS__",  # r16 뾰족한 턱끝
        "HHHD___zS___",  # r17 턱 밑 (턱선은 실루엣 경계로 귀 쪽 대각선)
        "HHHD........",  # r18
        "HHHD........",  # r19
    ]
    STRANDS = {3: "D", 6: "m", 9: "D", 12: "m", 15: "D"}
    rows = []
    for r, face in enumerate(FACE):
        if r == 0:
            back = "K" * 16
        else:
            rim = "T" if 5 <= r <= 9 else "L"
            back = rim + "".join(STRANDS.get(c, "H") for c in range(1, 16))
            if r >= 15:
                back = "." * (r - 14) + back[r - 14:]
        rows.append(back + face)
    stamp(14, 22, rows, {"K": "hair_dd", "D": "hair_d", "m": "hair_m", "H": "hair", "L": "hair_l", "T": "hair_h",
                         "S": "skin_s", "s": "skin", "v": "skin_h", "z": "skin_d", "u": "under",
                         "k": "lash", "e": "eye2", "i": "eye_m", "E": "eye", "l": "lip", "_": "clear"})
    # 얼굴에 흘러내린 잔머리 한 가닥
    line(22.6, 24.0, 22.2, 27.6, "hair_d")
    # 옆머리 (귀 앞에서 가슴까지, 끝이 뾰족) — 결 줄
    side = tube([(21.4, 25.5), (21.6, 30.0), (21.2, 34.0), (21.6, 36.6)], lambda t: 1.9 * (1 - t) ** 0.7 + 0.4)
    paint(side, "hair", left="hair_d", right="hair_l")
    line(21.4, 27.0, 21.5, 33.5, "hair_m")
    side2 = tube([(20.3, 30.0), (20.2, 34.0), (20.5, 37.6)], lambda t: 1.4 * (1 - t) + 0.4)
    paint(side2, "hair_d", left="hair_dd")


@lifted
def hat(_):
    # 원뿔: 밑동이 넓게 벌어지고 옆선은 오목하게 좁아지며 곧게 솟다가, 위에서 각지게 꺾여 바늘처럼 가는 끝이 뒤로 처진다
    TB = 0.58

    def width(t):
        if t < TB:
            return 2.8 + 7.7 * (1 - t / TB) ** 2.2
        return 2.8 * (1 - (t - TB) / (1 - TB)) ** 1.1

    center = [(20.0, 20.5), (19.6, 15), (19.0, 10), (18.4, 5.0), (14.5, 4.2), (10.0, 5.4), (6.0, 7.2), (3.0, 9.0)]
    cells = tube(center, width)
    cut = cv(16, 0)[0]
    paint(cells, "hat")
    for (x, y) in cells:   # 원뿔 둥근 면: 가운데 은은한 빛, 가장자리 안쪽 한 줄
        up = x >= cut
        if up and (x - 1, y) in cells and (x - 2, y) not in cells:
            dot(x, y, "hat_m")
    for (x, y) in cells:
        up = x >= cut
        if up and (x - 1, y) not in cells:
            dot(x, y, "hat_r")
        elif not up and (x, y - 1) not in cells:
            dot(x, y, "hat_r")
        elif (x, y - 1) not in cells:
            dot(x, y, "hat_l")
        elif up and (x + 1, y) not in cells:
            dot(x, y, "hat_d")
        elif not up and (x, y + 1) not in cells:
            dot(x, y, "hat_d")
    line(16.2, 6.2, 18.2, 4.9, "hat_d")   # 꺾인 자리 주름
    line(16.6, 6.8, 18.6, 5.6, "hat_l")
    line(18.3, 9.0, 18.0, 16.5, "hat_l")  # 둥근 면 빛
    line(18.9, 11.0, 18.8, 15.0, "hat_m")
    # 띠 + 버클
    band = poly_cells([(15.0, 17.7), (24.9, 17.7), (24.9, 19.9), (15.0, 19.9)])
    paint(band, "band", top="band_l")
    stamp(21.2, 17.6, ["SSS", "SdS", "SSs"], {"S": "silver_d", "s": "silver", "d": "band"})  # 작은 은 버클
    # 챙: 얇고 넓게, 윗면이 살짝 보이고 양 끝이 가늘어짐 (뒤 끝은 들리고 앞 끝은 숙임)
    up_ = [(2.6, 17.6), (6.0, 18.6), (10.0, 19.3), (15.0, 20.0), (25.0, 20.9), (31.0, 21.9), (35.5, 23.2), (38.6, 24.6)]
    lo_ = [(38.6, 24.8), (35.0, 24.9), (31.0, 24.1), (26.0, 23.2), (16.0, 22.2), (11.0, 21.4), (6.5, 20.4), (3.2, 18.4)]
    brim = poly_cells(up_ + lo_)
    paint(brim, "hat", top="hat_l", bottom="hat_d")
    for (x, y) in brim:
        if (x, y - 1) not in brim and x < cv(12, 0)[0]:
            dot(x, y, "hat_r")     # 챙 윗면 뒤쪽 역광
        if (x, y + 1) in brim and (x, y + 2) not in brim:
            dot(x, y, "hat_d")     # 챙 아랫면 두께
    line(15.5, 20.6, 25.0, 21.5, "hat_m")


# ================================================================ 계산으로 그리는 부품
def trail_pts(pts, y0, y1, t, power=1.3):
    out = []
    for (x, y) in pts:
        f = max(0.0, min(1.0, (y - y0) / (y1 - y0))) ** power
        out.append((x + t[0] * f, y + t[1] * f))
    return out


def veil(p):
    pts = [(11, 19), (16, 19), (16, 28), (15, 36), (12, 42), (9, 36), (9, 26)]
    pts = [ub(*q) for q in pts]
    pts = trail_pts(pts, 19, 42, p["veil"])
    poly(pts, "veil")
    line(*pts[6], *pts[5], "veil_e"); line(*pts[5], *pts[4], "veil_e")
    for u in (0.3, 0.6):  # 베일의 얇은 주름
        a = add(pts[1], (pts[4][0] - pts[1][0], pts[4][1] - pts[1][1]), u)
        b = add(pts[0], (pts[5][0] - pts[0][0], pts[5][1] - pts[0][1]), u)
        line(*a, *b, "veil_e")


def overskirt(p):
    # 시폰 겉치마: 허리 뒤에서 발목까지, 앞트임이라 다리 뒤로 지나간다
    t = p["over"]
    outer = trail_pts([(19, 41), (25, 41), (24, 50), (23, 60), (23, 67), (16, 68), (10, 66), (13, 57), (16, 48)], 41, 68, t)
    inner = trail_pts([(18, 44), (21, 44), (19, 56), (17, 66), (13, 67), (14, 57)], 41, 68, t)
    poly(outer, "sheer")
    poly(inner, "sheer2")
    for a, b in ((8, 7), (7, 6), (6, 5), (5, 4), (2, 3), (3, 4)):
        line(*outer[a], *outer[b], "sheer_e")
    for u in (0.35, 0.65):  # 시폰 결
        a = add(outer[1], (outer[8][0] - outer[1][0], outer[8][1] - outer[1][1]), u)
        b = add(outer[4], (outer[6][0] - outer[4][0], outer[6][1] - outer[4][1]), u)
        line(*a, *b, "sheer_e")
    hem = [outer[6], outer[5], outer[4]]
    for i in range(15):  # 밑단 글자 자수 (촘촘한 점)
        u = i / 14
        seg = 0 if u < 0.5 else 1
        v = (u - 0.5 * seg) * 2
        q = add(hem[seg], ((hem[seg + 1][0] - hem[seg][0]) * v, (hem[seg + 1][1] - hem[seg][1]) * v))
        pt(q[0], q[1] - 0.6 - (0.5 if i % 3 == 1 else 0), "emb")


def hair(p):
    """뒷머리: 가는 가닥 여러 개. 기본 곡선(뿌리→끝)을 따라 가닥마다 퍼짐·길이가 다르고,
    박자가 다른 물결 두 개가 뿌리에서 끝으로 시간차를 두고 흘러 불규칙하게 찰랑인다.
    가닥마다 안쪽 결(어두운 1px 선)과 윗면 윤기(밝은 1px 선)를 넣어 머릿결을 묘사한다.
    p["hair"] = (중간점 dx, dy, 끝점 dx, dy), p["hwave"] = (진폭, 위상 rad)."""
    d = p["hair"]
    amp, phase = p.get("hwave", (0.6, 0.0))
    root = ub(16.8, 23.5)
    p1 = add(ub(16.0, 42), (d[0], d[1]))
    p2 = (8.5 + d[2], 56 + d[3])
    base = bezier(root, p1, p2, 28)
    segs = [math.dist(base[i], base[i + 1]) for i in range(len(base) - 1)]
    tot = sum(segs)
    acc = [0.0]
    for L in segs:
        acc.append(acc[-1] + L)

    def at(u):
        u = max(0.0, min(1.0, u)) * tot
        i = max(0, min(len(segs) - 1, next((k for k in range(len(segs)) if acc[k + 1] >= u), len(segs) - 1)))
        f = (u - acc[i]) / (segs[i] or 1)
        x = base[i][0] + (base[i + 1][0] - base[i][0]) * f
        y = base[i][1] + (base[i + 1][1] - base[i][1]) * f
        tx, ty = base[i + 1][0] - base[i][0], base[i + 1][1] - base[i][1]
        tl = math.hypot(tx, ty) or 1
        return (x, y), (ty / tl, -tx / tl)

    def strand(off, ln, w0, dph, fq):
        pts = []
        n = 26
        for k in range(n + 1):
            u = k / n * ln
            (x, y), (nx, ny) = at(u)
            spread = off * (0.3 + 1.5 * u)
            wave = amp * (u ** 1.3) * (0.75 * math.sin(phase - 2 * math.pi * 1.15 * fq * u + dph)
                                       + 0.35 * math.sin(0.5 * phase - 2 * math.pi * 2.0 * u + 2 * dph))
            pts.append((x + nx * (spread + wave), y + ny * (spread + wave)))
        return pts

    # (퍼짐, 길이, 뿌리 폭, 위상 차, 물결 빠르기, 색, 윗면 빛, 결 색, 윤기 구간) — 뒤 가닥부터
    STRANDS = [
        (-3.0, 0.84, 1.5, 0.9, 1.0, "hair_d", "hair_m", "hair_dd", None),
        (2.6, 0.92, 1.6, 0.3, 1.1, "hair_d", "hair_m", "hair_dd", None),
        (-1.9, 0.96, 1.7, 2.6, 1.2, "hair_m", "hair", "hair_d", None),
        (1.6, 0.88, 1.6, 1.6, 0.9, "hair_m", "hair", "hair_d", None),
        (-0.5, 1.00, 2.0, 0.0, 1.0, "hair", "hair_l", "hair_m", (0.15, 0.45)),
        (0.9, 0.95, 1.7, 1.1, 1.05, "hair", "hair_l", "hair_m", (0.2, 0.4)),
        (-3.9, 0.74, 1.2, 2.1, 1.3, "hair", "hair_l", "hair_m", None),
        (-1.2, 0.80, 1.3, 3.0, 1.15, "hair_l", "hair_h", "hair", (0.1, 0.35)),
        (0.3, 0.86, 1.2, 3.6, 1.1, "hair", "hair_l", "hair_m", None),
        (3.3, 0.70, 1.1, 4.0, 1.2, "hair", "hair_l", "hair_m", None),
    ]
    for (off, ln, w0, dph, fq, col, rim, grain, sheen) in STRANDS:
        pts = strand(off, ln, w0, dph, fq)
        cells = tube(pts, lambda t, w0=w0: max(0.45, w0 * (1 - t) ** 1.1 + 0.35))  # 끝은 1px로 가늘게
        paint(cells, col, top=rim)
        for i in range(2, len(pts) - 3):  # 안쪽 결
            if i % 7 != 0:
                line(*pts[i], *pts[i + 1], grain)
        if sheen:  # 윗면 윤기 (빛을 받는 구간)
            a, b = int(sheen[0] * len(pts)), int(sheen[1] * len(pts))
            for i in range(a, b):
                (x0, y0), (x1, y1) = pts[i], pts[i + 1]
                (_, _), (nx, ny) = at(i / len(pts))
                line(x0 + nx * 0.45, y0 + ny * 0.45, x1 + nx * 0.45, y1 + ny * 0.45, "hair_s" if i % 5 == 0 else "hair_h")
    # 머리 뒤 뿌리 덩어리 (가닥들이 시작되는 곳을 메움) + 결
    rc = tube([root, at(0.16)[0]], lambda t: 5.0 - 1.4 * t)
    paint(rc, "hair", left="hair_l", left2="hair_h")
    for k in (-1.2, 0.0, 1.2):
        (x0, y0), (nx, ny) = at(0.02)
        (x1, y1), _ = at(0.17)
        line(x0 + nx * k, y0 + ny * k, x1 + nx * k * 1.2, y1 + ny * k * 1.2, "hair_m")


def leg(hip, rel_knee, rel_ankle, foot_deg, far):
    knee, ankle = add(hip, rel_knee), add(hip, rel_ankle)
    thigh = tube([hip, knee], lambda t: 3.1 - 0.6 * t)
    shin = tube([knee, ankle], lambda t: 2.4 + 0.7 * math.sin(min(1.0, t / 0.6) * math.pi) * (t < 0.6) - 0.7 * t)
    cells = dict(thigh)
    cells.update(shin)
    if far:
        paint(cells, "skin_s", left="skin", right="skin_d", right2="skin_d")
    else:
        paint(cells, "skin", left="skin_h", right="skin_s", right2="skin_m")
        kx, ky = cv(*knee)       # 무릎뼈의 작은 빛과 그늘
        dot(round(kx) + 1, round(ky) - 1, "skin_h")
        dot(round(kx) + 2, round(ky) + 1, "skin_m")
    boot(knee, ankle, foot_deg, far)


def boot(knee, ankle, foot_deg, far):
    # 발목 부츠: 발목 바로 위까지, 낮은 굽. 발 방향 foot_deg (0 = 앞, 양수 = 앞코가 아래로)
    sx, sy = ankle[0] - knee[0], ankle[1] - knee[1]
    sl = math.hypot(sx, sy) or 1
    sx, sy = sx / sl, sy / sl
    shaft = tube([add(ankle, (sx, sy), -2.2), add(ankle, (sx, sy), 0.4)], lambda t: 2.8)
    a = math.radians(foot_deg)
    ca, sa = math.cos(a), math.sin(a)
    k = 0.8 if far else 0.9

    def fp(fx, fy):
        return (ankle[0] + (fx * k) * ca - fy * sa, ankle[1] + (fx * k) * sa + fy * ca)
    foot = [fp(fx, fy) for fx, fy in [(-1.3, -0.6), (1.3, -0.6), (4.0, 0.8), (6.0, 1.6), (6.6, 2.4), (6.4, 3.2), (2.0, 3.2),
                                      (1.5, 2.7), (-0.5, 2.7), (-0.7, 3.2), (-2.0, 3.2), (-2.0, 0.9)]]
    cells = set(shaft) | poly_cells(foot)
    paint(cells, "boot", left2=None if far else "boot_m")
    if not far:
        for (x, y) in cells:
            if (x, y - 1) not in cells:
                dot(x, y, "boot_l")
        line(*fp(1.5, 0.2), *fp(5.6, 1.6), "boot_l")   # 발등 반사광
        line(*fp(-1.8, 2.9), *fp(-0.9, 2.9), "boot_m")  # 굽
        top = add(ankle, (sx, sy), -2.2)
        line(top[0] - 1.3, top[1], top[0] + 1.3, top[1], "boot_m")  # 부츠 입구
    else:
        line(*fp(-1.6, 0.0), *fp(-1.6, 2.0), "boot_l")


def inner_skirt(p):
    f, b = p["skirt"][:2], p["skirt"][2:]
    pts = [(19, 42), (25.5, 42), (27.5 + f[0], 48.8 + f[1]), (22, 49.2 + (f[1] + b[1]) / 2), (16.5 + b[0], 48.8 + b[1])]
    cells = poly_cells(pts)
    paint(cells, "sk", left="sk_r", right="sk_d", bottom="sk_d", left2="sk_m")
    for u in (0.15, 0.32, 0.5, 0.68, 0.85):  # 주름
        top = (19.3 + 6.0 * u, 42.6)
        hem = (pts[4][0] + (pts[2][0] - pts[4][0]) * u, pts[4][1] + (pts[2][1] - pts[4][1]) * u - 0.6)
        line(*top, *hem, "sk_d")
        line(top[0] + 0.5, top[1] + 0.5, hem[0] + 0.5, hem[1] - 0.5, "sk_m")


def weapon(p):
    # 칼집: 왼쪽 허리에서 뒤로 비스듬히, 끝 1/3이 나뭇가지 빗자루. p["sword"] = 대기 각도에서 더한 각도(도)
    m = (25.0, 44.0)
    ang = math.radians(141.3 + p["sword"])
    d = (math.cos(ang), math.sin(ang))
    n = (-d[1], d[0])
    e = add(m, d, 18.5)
    sc = tube([m, e], lambda t: 2.7)
    paint(sc, "sc", top="sc_l", bottom="sc_d")
    line(*add(m, n, 0.4), *add(e, n, 0.4), "sc_l")     # 가죽 윤기
    paint(tube([m, add(m, d, 1.4)], lambda t: 2.9), "silver", bottom="silver_d")  # 입구 장식
    for k in (4.0, 7.0):  # 버클 끈
        a, b = add(add(m, d, k), n, 1.6), add(add(m, d, k), n, -1.6)
        line(*a, *b, "silver_d")
        pt(*add(m, d, k), "silver")
    paint(tube([add(e, d, -1.5), add(e, d, 0.5)], lambda t: 3.0), "cord", top="silver_d")  # 빗자루 묶은 끈
    for i in range(11):  # 나뭇가지 다발
        spread = -32 + i * 6.4
        a2 = ang + math.radians(spread)
        ln = 9.5 + 1.5 * math.sin(i * 1.7)
        q = add(e, (math.cos(a2), math.sin(a2)), ln)
        c = ("tw_d", "tw", "tw_l")[i % 3]
        line(*e, *q, c)
        mid = add(e, (math.cos(a2), math.sin(a2)), ln * 0.6)   # 잔가지
        twig = add(mid, (math.cos(a2 + 0.6), math.sin(a2 + 0.6)), 1.6)
        line(*mid, *twig, "tw_d")
    # 손잡이 + 뾰족한 은 폼멜 + 가시 가지 십자 가드 + 하늘색 보석
    g = add(m, d, -1.6)
    paint(tube([add(g, d, -1.2), add(g, d, -4.6)], lambda t: 1.3), "grip", top="grip_l")
    for k in (2.0, 3.2, 4.2):  # 손잡이 감은 가죽 결
        pt(*add(g, d, -k), "grip_l")
    paint(tube([add(g, d, -5.0), add(g, d, -7.2)], lambda t: 1.4 * (1 - t) + 0.3), "silver", bottom="silver_d")
    for s in (1, -1):
        arm = [g, add(g, n, s * 1.4), add(add(g, n, s * 2.6), d, s * 0.3), add(add(g, n, s * 3.3), d, s * 1.2)]
        paint(tube(arm, lambda t: 0.9 * (1 - t) + 0.35), "silver", bottom="silver_d")
        thorn = add(g, n, s * 2.0)
        pt(*add(thorn, d, -0.8 * s), "silver_d")   # 가시
    gx, gy = cv(*g)
    for (dx, dy, c) in ((0, 0, "gem"), (1, 0, "gem_d"), (0, 1, "gem_d"), (1, 1, "gem_d"), (0, -1, "silver_h")):
        dot(math.floor(gx) + dx, math.floor(gy) + dy, c)


def near_arm(p):
    sh = ub(20.5, 32.5)
    el = add(sh, p["elbow"])
    wr = add(sh, p["wrist"])
    up = tube([sh, el], lambda t: 3.3)
    paint(up, "bl", left="bl_d", right="bl_l", right2="bl_m")
    # 숄의 팔 쪽: 팔꿈치 위에서 팔을 가로질러 감는 반투명 니트 띠 + 아래로 늘어진 술
    ux, uy = el[0] - sh[0], el[1] - sh[1]
    ul = math.hypot(ux, uy) or 1
    ud = (ux / ul, uy / ul)
    un = (-ud[1], ud[0])
    c0 = add(sh, ud, ul * 0.72)
    band = tube([add(c0, un, -3.2), add(c0, un, 2.6)], lambda t: 3.0)
    for c in band:
        dot(*c, "shawl")
    for (x, y) in band:
        if (x, y - 1) not in band:
            dot(x, y, "shawl_l")
        elif (x + y) % 3 == 0:
            dot(x, y, "shawl_d")   # 니트 짜임
    low = {}
    for (x, y) in band:
        low[x] = max(low.get(x, -99), y)
    for i, x in enumerate(sorted(low)):
        if i % 2:
            continue
        ln = (6, 4, 8, 5, 7, 4)[(i // 2) % 6]
        for k in range(ln):
            dot(x + round(p["fringe"] * K * (k + 1) / 8), low[x] + 1 + k, "shawl_d" if k % 3 == 2 else "shawl")
    # 아래팔 소매: 손목 쪽으로 넓게 퍼지는 종 모양, 손을 손가락 중간까지 덮음
    fx, fy = wr[0] - el[0], wr[1] - el[1]
    fl = math.hypot(fx, fy) or 1
    fd = (fx / fl, fy / fl)
    cuff = add(wr, fd, 0.8)
    bell = tube([el, cuff], lambda t: 3.3 + 4.4 * t ** 1.6)
    paint(bell, "bl", left="bl_d", right="bl_l", left2="bl_m")
    for c, t in bell.items():
        if t > 0.95:
            dot(*c, "bl_r")
    nn = (-fd[1], fd[0])
    for s in (-1.4, -0.3, 0.9):  # 소매 주름
        line(*add(add(el, fd, fl * 0.45), nn, s * 0.6), *add(add(el, fd, fl * 0.94), nn, s * 1.6), "bl_d")
    line(*add(add(el, fd, fl * 0.5), nn, 0.3), *add(add(el, fd, fl * 0.9), nn, 0.7), "bl_m")
    # 손가락 끝: 검게 물들고 잉크가 떨어짐
    f1 = add(cuff, fd, 1.0)
    f2 = add(cuff, fd, 2.0)
    for q, c in ((f1, "skin_s"), (add(f1, nn, 0.5), "skin_m"), (f2, "ink"), (add(f2, nn, 0.5), "ink"), (add(f2, fd, 0.5), "ink")):
        pt(*q, c)
    if p.get("drip", True):
        for k in (1.0, 1.5, 2.6):
            pt(f2[0], f2[1] + k, "ink")


def outline():
    # 셀아웃: 외곽선 색 = 맞닿은 안쪽 색을 어둡게 (밝은 살 옆은 중간 톤, 옷 옆은 거의 검게)
    src = np.array(img)
    a = src[..., 3]
    out = src.copy()
    solid = a >= 200
    acc = np.zeros(src.shape[:2] + (3,), dtype=np.float64)
    cnt = np.zeros(src.shape[:2], dtype=np.float64)
    for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
        sh_s = np.roll(np.roll(solid, dy, 0), dx, 1)
        sh_c = np.roll(np.roll(src[..., :3].astype(np.float64), dy, 0), dx, 1)
        acc += sh_c * sh_s[..., None]
        cnt += sh_s
    m = (a == 0) & (cnt > 0)
    avg = acc[m] / cnt[m][:, None]
    k = np.where(avg.mean(axis=1) > 150, 0.55, 0.22)[:, None]
    col = avg * k + np.array([4, 5, 12])
    out[m, :3] = col.astype(np.uint8)
    out[m, 3] = 255
    img.paste(Image.fromarray(out))


# ================================================================ 자세 (1배 단위)
NEAR_HIP = (22.5, 46.0)
FAR_HIP = (21.0, 46.0)

IDLE = {
    "bx": 0, "by": 0, "lean": 0.0,
    "near": ((0.5, 10.0), (0.0, 19.0), 0), "far": ((-2.5, 10.5), (-4.5, 18.5), 0),
    "elbow": (-0.5, 7.5), "wrist": (0.5, 14.0),
    "hair": (0, 0, 0, 0), "skirt": (0, 0, 0, 0), "over": (0, 0), "veil": (0, 0), "sword": 0, "fringe": 0,
}


def pose(**kw):
    p = dict(IDLE)
    p.update(kw)
    return p


def layer(fn, p):
    """손그림 부품을 빈 층에 그려 숙임 각도만큼 돌린 뒤 현재 그림 위에 붙인다."""
    global img, P
    base, bp = img, P
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    P = img.load()
    fn(p)
    lay = rotsprite(img, LEAN, cv(PIV_X, PIV))
    img, P = base, bp
    img.alpha_composite(lay)


def render(p):
    global img, P, BX, BY, LEAN
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    P = img.load()
    BX, BY = p["bx"], p["by"]
    LEAN = math.degrees(math.atan(p["lean"])) if p.get("lean_deg") is None else p["lean_deg"]
    veil(p)
    overskirt(p)
    layer(shawl_back, p)
    hair(p)
    nh, fh = NEAR_HIP, FAR_HIP
    if p.get("near_behind"):
        leg(nh, *p["near"], False)
        leg(fh, *p["far"], True)
    else:
        leg(fh, *p["far"], True)
        leg(nh, *p["near"], False)
    inner_skirt(p)
    layer(torso, p)
    weapon(p)

    def headhat(q):
        head(q)
        hat(q)
    layer(headhat, p)
    near_arm(p)
    outline()
    return img


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else str(ROOT / "docs/art/eska/idle.png")
    render(IDLE).save(out)
