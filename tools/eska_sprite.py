"""에스카 사이드뷰 스프라이트 리그 (오른쪽을 봄) — 대기·달리기·점프·이단점프·대시 프레임을 그린다.
기준: docs/gdd/assets/eska-sheet-v3.png, 앵커 tools/make_eska_prompts.py.

구조
- 상체·머리·모자는 손으로 찍은 픽셀(행 폭·스탬프)을 그대로 쓰고, 프레임마다 통째로 옮기거나 앞으로 기울인다(LEAN, 엉덩이 높이 기준 전단).
- 다리·팔·뒷머리·치마·겉치마·베일·검집은 자세 값(관절 위치, 휘날림)으로 프레임마다 계산해 그린다.
- 빛: 뒤(왼쪽)에서 오는 차가운 역광 → 뒤쪽 가장자리가 밝다. 외곽선은 셀아웃(맞닿은 색을 어둡게).
좌표: 로컬 (x 오른쪽, y 아래). 대기 자세에서 정수리 y18, 발바닥 y69."""
import math
import pathlib
import sys
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
W, H = 80, 88          # 프레임 한 칸
OX, OY = 22, 8         # 로컬 → 칸 좌표
PIV = 44               # 상체를 기울일 때 기준 높이 (엉덩이)


def hx(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


C = {
    "hat_d": hx("#0e1328"), "hat": hx("#19213e"), "hat_l": hx("#28345e"), "hat_r": hx("#4f67a6"),
    "band": hx("#05060c"), "silver": hx("#d6deec"), "silver_d": hx("#7b86a0"),
    "hair_dd": hx("#141b2f"), "hair_d": hx("#223050"), "hair": hx("#344a72"), "hair_l": hx("#50699a"), "hair_h": hx("#8aa6d4"),
    "skin_d": hx("#76829c"), "skin_s": hx("#a3afc6"), "skin": hx("#cdd6e6"), "skin_h": hx("#eef3fb"),
    "eye": hx("#9fdcff"), "eye2": hx("#4f95c8"), "lash": hx("#0b0f1c"),
    "bl_d": hx("#0f1530"), "bl": hx("#1c2546"), "bl_l": hx("#2d3a68"), "bl_r": hx("#45569a"),
    "shawl_d": hx("#3c4864", 200), "shawl": hx("#56647f", 185), "shawl_l": hx("#8292b0", 210),
    "cor": hx("#0a0d19"), "cor_l": hx("#262e48"),
    "sk_d": hx("#0e1327"), "sk": hx("#1a2242"), "sk_r": hx("#43559a"),
    "boot": hx("#0a0c15"), "boot_l": hx("#2b3249"),
    "sc_d": hx("#151c2f"), "sc": hx("#273450"), "sc_l": hx("#46597f"),
    "tw_d": hx("#0f0c13"), "tw": hx("#221d29"), "tw_l": hx("#3d3548"), "cord": hx("#556080"),
    "grip": hx("#131724"), "grip_l": hx("#2d3448"), "gem": hx("#9fd8ff"),
    "ink": hx("#020308"),
    "sheer": hx("#2a3a72", 100), "sheer2": hx("#3a4d8e", 125), "sheer_e": hx("#7487bc", 175), "emb": hx("#c4d2ee", 215),
    "veil": hx("#1c2858", 90), "veil_e": hx("#3f4f8c", 120),
}

# ---------------------------------------------------------------- 그리기 상태
img = None
P = None
BX = BY = 0      # 몸 전체 이동
LEAN = 0.0       # 상체 기울기 (y 1px 위로 갈 때 x 이동량)
U = False        # True면 상체 변환(기울기) 적용
DY = 0           # 머리 쪽 부품은 2px 위로


def ub(x, y):
    """상체에 붙은 점의 실제 위치 (기울기 반영)."""
    return (x + (PIV - y) * LEAN, y)


def px(x, y, c):
    y = y + DY
    if U:
        x = x + round((PIV - y) * LEAN)
    x = int(x) + BX + OX
    y = int(y) + BY + OY
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


def line(x0, y0, x1, y1, c):
    x0, y0, x1, y1 = round(x0), round(y0), round(x1), round(y1)
    dx, dy = abs(x1 - x0), -abs(y1 - y0)
    sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
    err = dx + dy
    while True:
        px(x0, y0, c)
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
        px(x, y, c)


def spans(rows, c, back=None, front=None):
    for y, (a, b) in rows.items():
        for x in range(a, b + 1):
            px(x, y, c)
        if back:
            px(a, y, back)
        if front:
            px(b, y, front)


def stamp(x0, y0, rows, key):
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            if ch in key:
                px(x0 + i, y0 + j, key[ch])


def R(y0, pairs):
    return {y0 + i: p for i, p in enumerate(pairs)}


def tube(center, width):
    """중심선(점 목록)을 따라 폭 width(t)로 채운 칸 → {칸: t}."""
    seg = [math.dist(center[i], center[i + 1]) for i in range(len(center) - 1)]
    total = sum(seg) or 1.0
    samples = []
    acc = 0.0
    for i, L in enumerate(seg):
        (x0, y0), (x1, y1) = center[i], center[i + 1]
        if L == 0:
            continue
        n = max(2, int(L * 4))
        for k in range(n):
            u = k / n
            samples.append((x0 + (x1 - x0) * u, y0 + (y1 - y0) * u, (acc + L * u) / total, (x1 - x0) / L, (y1 - y0) / L))
        acc += L
    samples.append((*center[-1], 1.0, samples[-1][3], samples[-1][4]))
    cells = {}
    for (x, y, t, dx, dy) in samples:
        w = width(t) / 2
        nx, ny = -dy, dx
        steps = max(1, int(w * 3))
        for k in range(-steps, steps + 1):
            q = k / steps * w
            c = (math.floor(x + nx * q), math.floor(y + ny * q))
            cells[c] = max(cells.get(c, 0), t)
    return cells


def paint(cells, base, left=None, right=None, top=None, bottom=None):
    for c in cells:
        px(*c, base)
    for (x, y) in cells:
        if left and (x - 1, y) not in cells:
            px(x, y, left)
        elif right and (x + 1, y) not in cells:
            px(x, y, right)
        elif top and (x, y - 1) not in cells:
            px(x, y, top)
        elif bottom and (x, y + 1) not in cells:
            px(x, y, bottom)


def bezier(p0, p1, p2, n=12):
    out = []
    for i in range(n + 1):
        t = i / n
        a, b, c = (1 - t) ** 2, 2 * (1 - t) * t, t * t
        out.append((a * p0[0] + b * p1[0] + c * p2[0], a * p0[1] + b * p1[1] + c * p2[1]))
    return out


def lifted(fn):
    """머리 쪽 부품은 2px 위로 그린다 (목을 확보)."""
    def wrap(*a):
        global DY
        DY = -2
        fn(*a)
        DY = 0
    return wrap


def upper(fn):
    """상체에 붙은 손그림 부품 — 기울기를 적용해 그린다."""
    def wrap(*a):
        global U
        U = True
        fn(*a)
        U = False
    return wrap


def add(p, q, k=1.0):
    return (p[0] + q[0] * k, p[1] + q[1] * k)


# ================================================================ 손그림 상체 (기울기 적용)
@upper
def torso(_):
    spans({29: (20, 22)}, "skin_d")  # 턱 밑 그늘 (턱선이 목과 분리되어 보이게)
    spans({30: (20, 22)}, "skin_s")
    spans({31: (19, 24)}, "skin", back="skin_s")  # 드러난 어깨·쇄골
    px(23, 31, "skin_h"); px(24, 31, "skin_h")
    spans(R(32, [(19, 25), (19, 26), (19, 26), (19, 25)]), "bl", back="bl_d", front="bl_l")
    line(20, 32, 25, 32, "bl_l")
    for x in (21, 23):
        px(x, 32, "silver_d")  # 목선 은실 글자 자수
    px(26, 33, "bl_r")
    spans(R(36, [(19, 24), (20, 23), (20, 23), (20, 23), (20, 24), (19, 24)]), "cor", front="cor_l")
    line(20, 36, 24, 36, "cor_l")
    for y in (37, 39, 41):
        px(23, y, "silver")
    for y in (38, 40):
        px(22, y, "silver_d")


@upper
def shawl_back(_):
    # 숄의 등 쪽: 뒷머리 밑으로 지나간다
    spans({37: (15, 19), 38: (15, 19), 39: (15, 19)}, "shawl")


@upper
@lifted
def head(_):
    # 오른쪽을 보는 옆얼굴. 옆머리가 뒤쪽 볼을 가려 얼굴은 작고, 턱선은 실루엣 경계가 귀 쪽으로 대각선.
    HEAD = [
        # x: 14          27
        "KHHHHHHHHDD...",  # 22 챙 아래
        "THHHHHHHDDSS__",  # 23 이마 (챙 그늘)
        "THHDHHHDHDSS__",  # 24 뾰족한 앞머리 가닥
        "THHDHHDHSkkkk_",  # 25 긴 속눈썹 (끝이 앞으로 뻗음)
        "THHDHHDHSeEs__",  # 26 빛나는 눈
        "THHDHHDHSsssv_",  # 27 작은 코끝
        "THHDHHDHSssl__",  # 28 입술
        ".THDHHDH_sS___",  # 29 작은 턱끝
        ".THDHHDH______",  # 30
        "..THDHDH......",  # 31
    ]
    stamp(14, 22, HEAD, {"H": "hair", "D": "hair_d", "K": "hair_dd", "T": "hair_l", "S": "skin_s", "s": "skin",
                         "v": "skin_h", "z": "skin_d", "l": "skin_s", "k": "lash", "E": "eye", "e": "eye2", "_": "clear"})
    line(21, 27, 21, 35, "hair"); line(22, 32, 22, 34, "hair_d"); px(21, 36, "hair_d")  # 옆머리 (끝이 뾰족)
    line(20, 33, 20, 37, "hair_d")
    for x, y in ((16, 23), (17, 23), (18, 24)):
        px(x, y, "hair_l")  # 윤기


@upper
@lifted
def hat(_):
    # 밑동이 넓게 벌어지고 옆선은 오목하게 좁아지며 곧게 솟다가, 위에서 각지게 꺾여 바늘처럼 가는 끝이 뒤로 처진다
    TB = 0.58

    def width(t):
        if t < TB:
            return 2.8 + 7.7 * (1 - t / TB) ** 2.2
        return 2.8 * (1 - (t - TB) / (1 - TB)) ** 1.1

    center = [(20.0, 20.5), (19.6, 15), (19.0, 10), (18.4, 5.0), (14.5, 4.2), (10.0, 5.4), (6.0, 7.2), (3.0, 9.0)]
    cells = tube(center, width)
    for c in cells:
        px(*c, "hat")
    for (x, y) in cells:
        up = x >= 16
        if up and (x - 1, y) not in cells:
            px(x, y, "hat_r")
        elif not up and (x, y - 1) not in cells:
            px(x, y, "hat_r")
        elif (x, y - 1) not in cells:
            px(x, y, "hat_l")
        elif up and (x + 1, y) not in cells:
            px(x, y, "hat_d")
        elif not up and (x, y + 1) not in cells:
            px(x, y, "hat_d")
    line(16, 6, 18, 5, "hat_d")
    line(18, 9, 18, 16, "hat_l")
    spans({18: (15, 24), 19: (15, 24)}, "band")
    stamp(21, 17, ["ss", "sd", "dd"], {"s": "silver", "d": "silver_d"})

    def poly_line(pts, c):
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            line(x0, y0, x1, y1, c)
    poly_line([(5, 19), (10, 20), (15, 21), (26, 22), (32, 23), (36, 24)], "hat")
    poly_line([(8, 20), (12, 21), (16, 22), (26, 23), (31, 24), (34, 25)], "hat_d")
    poly_line([(7, 18), (11, 19), (15, 20), (25, 21), (31, 22), (34, 23)], "hat_l")
    line(7, 18, 11, 19, "hat_r")
    px(4, 18, "hat_r"); px(3, 18, "hat_r")
    px(37, 24, "hat"); px(38, 25, "hat_d")


# ================================================================ 계산으로 그리는 부품
def trail_pts(pts, y0, y1, t, power=1.3):
    """아래로 갈수록 휘날림 t(dx, dy)를 더 받는다."""
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


def overskirt(p):
    # 시폰 겉치마: 허리 뒤에서 발목까지, 앞트임이라 다리 뒤로 지나간다
    t = p["over"]
    outer = trail_pts([(19, 41), (25, 41), (24, 50), (23, 60), (23, 67), (16, 68), (10, 66), (13, 57), (16, 48)], 41, 68, t)
    inner = trail_pts([(18, 44), (21, 44), (19, 56), (17, 66), (13, 67), (14, 57)], 41, 68, t)
    poly(outer, "sheer")
    poly(inner, "sheer2")
    for a, b in ((8, 7), (7, 6), (6, 5), (5, 4), (2, 3), (3, 4)):
        line(*outer[a], *outer[b], "sheer_e")
    hem = [outer[6], outer[5], outer[4]]
    for i in range(7):
        u = i / 6
        seg = 0 if u < 0.5 else 1
        v = (u - 0.5 * seg) * 2
        q = add(hem[seg], ((hem[seg + 1][0] - hem[seg][0]) * v, (hem[seg + 1][1] - hem[seg][1]) * v))
        px(round(q[0]), round(q[1]) - 1, "emb")  # 밑단 글자 자수


def hair(p):
    # 뒷머리: 머리 뒤에서 등을 따라 내려와 끝은 갈래로 나뉜다. p["hair"] = (중간점 dx, dy, 끝점 dx, dy)
    d = p["hair"]
    p0 = ub(16.5, 22)
    p1 = add(ub(16.0, 42), (d[0], d[1]))
    p2 = (8.5 + d[2], 56 + d[3])
    pts = bezier(p0, p1, p2)
    cut = int(len(pts) * 0.82)
    cells = tube(pts[:cut + 1], lambda t: 5.0 - 1.2 * t)
    end = pts[cut]
    dirx, diry = pts[-1][0] - end[0], pts[-1][1] - end[1]
    nl = math.hypot(dirx, diry) or 1
    nx, ny = -diry / nl, dirx / nl
    for s in (-1.3, 1.3):  # 두 갈래 끝
        a = add(end, (nx * s, ny * s))
        b = add(pts[-1], (nx * s * 2.2 + dirx * 0.25, ny * s * 2.2 + diry * 0.25))
        cells.update(tube([a, b], lambda t: 2.4 * (1 - t) + 0.6))
    paint(cells, "hair", left="hair_l")
    # 결: 이어진 어두운 가닥 2줄(중간에 한 번 끊김) + 몸 쪽 그늘 + 어깨 뒤 역광
    for i in range(1, cut):
        (x0, y0), (x1, y1) = pts[i], pts[i + 1]
        if i != cut // 2:
            line(x0 - 0.4, y0, x1 - 0.4, y1, "hair_d")
        line(x0 + 1.6, y0, x1 + 1.6, y1, "hair_dd")
    for i in range(1, max(2, cut // 2)):
        (x0, y0), (x1, y1) = pts[i], pts[i + 1]
        line(x0 - 2.0, y0, x1 - 2.0, y1, "hair_h")


def leg(hip, rel_knee, rel_ankle, foot_deg, far):
    knee, ankle = add(hip, rel_knee), add(hip, rel_ankle)
    thigh = tube([hip, knee], lambda t: 3.1 - 0.6 * t)
    shin = tube([knee, ankle], lambda t: 2.4 + 0.7 * math.sin(min(1.0, t / 0.6) * math.pi) * (t < 0.6) - 0.7 * t)
    cells = dict(thigh)
    cells.update(shin)
    if far:
        paint(cells, "skin_d", left="skin_s")
    else:
        paint(cells, "skin", left="skin_h", right="skin_s")
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
    foot = [(-1.3, -0.6), (1.3, -0.6), (4.0, 0.8), (6.0, 1.6), (6.6, 2.4), (6.4, 3.2), (2.0, 3.2), (1.5, 2.7),
            (-0.5, 2.7), (-0.7, 3.2), (-2.0, 3.2), (-2.0, 0.9)]
    foot = [(ankle[0] + (fx * k) * ca - fy * sa, ankle[1] + (fx * k) * sa + fy * ca) for fx, fy in foot]
    cells = set(shaft) | poly_cells(foot)
    paint(cells, "boot")
    for (x, y) in cells:
        if (x, y - 1) not in cells and not far:
            px(x, y, "boot_l")
    if not far:
        q0 = (ankle[0] + 1.5 * ca - 0.2 * sa, ankle[1] + 1.5 * sa + 0.2 * ca)
        q1 = (ankle[0] + 5.5 * ca - 1.6 * sa, ankle[1] + 5.5 * sa + 1.6 * ca)
        line(*q0, *q1, "boot_l")  # 발등 반사광
    else:
        line(ankle[0] - 2, ankle[1] - 1, ankle[0] - 2, ankle[1] + 1, "boot_l")


def inner_skirt(p):
    f, b = p["skirt"][:2], p["skirt"][2:]
    pts = [(19, 42), (25.5, 42), (27.5 + f[0], 48.8 + f[1]), (22, 49.2 + (f[1] + b[1]) / 2), (16.5 + b[0], 48.8 + b[1])]
    cells = poly_cells(pts)
    paint(cells, "sk", left="sk_r", right="sk_d", bottom="sk_d")
    for u in (0.25, 0.5, 0.78):  # 주름
        top = (19 + 6.5 * u, 43)
        hem = (pts[4][0] + (pts[2][0] - pts[4][0]) * u, pts[4][1] + (pts[2][1] - pts[4][1]) * u - 1)
        line(*top, *hem, "sk_d")


def weapon(p):
    # 칼집: 왼쪽 허리에서 뒤로 비스듬히, 끝 1/3이 나뭇가지 빗자루. p["sword"] = 대기 각도에서 더한 각도(도)
    m = (25.0, 44.0)
    ang = math.radians(141.3 + p["sword"])
    d = (math.cos(ang), math.sin(ang))
    n = (-d[1], d[0])
    e = add(m, d, 18.5)
    sc = tube([m, e], lambda t: 2.7)
    for (x, y) in sc:
        px(x, y, "sc")
    for (x, y) in sc:
        if (x, y - 1) not in sc:
            px(x, y, "sc_l")
        elif (x, y + 1) not in sc:
            px(x, y, "sc_d")
    for (x, y) in tube([m, add(m, d, 1.4)], lambda t: 2.8):
        px(x, y, "silver")  # 입구 장식
    for k in (4.0, 7.0):  # 버클 끈
        q = add(m, d, k)
        px(round(q[0] + n[0] * 0.6), round(q[1] + n[1] * 0.6), "silver_d")
        px(round(q[0] - n[0] * 0.6), round(q[1] - n[1] * 0.6), "silver_d")
    for (x, y) in tube([add(e, d, -1.5), add(e, d, 0.5)], lambda t: 3.0):
        px(x, y, "cord")  # 빗자루 묶은 끈
    for i, (spread, ln, c) in enumerate(((-30, 9, "tw_d"), (-19, 10.5, "tw"), (-9, 10, "tw_l"), (1, 11, "tw"),
                                          (11, 10, "tw_l"), (21, 9.5, "tw"), (32, 8, "tw_d"))):
        a2 = ang + math.radians(spread)
        q = add(e, (math.cos(a2), math.sin(a2)), ln)
        line(*e, *q, c)
        px(round(q[0]), round(q[1]), "tw_d")
    # 손잡이 + 뾰족한 은 폼멜 + 가시 가지 십자 가드 + 하늘색 보석
    g = add(m, d, -1.6)
    line(*add(g, d, -1.2), *add(g, d, -4.6), "grip")
    line(*add(add(g, d, -1.2), n, 0.8), *add(add(g, d, -4.6), n, 0.8), "grip_l")
    q = add(g, d, -5.8); px(round(q[0]), round(q[1]), "silver")
    q = add(g, d, -7.0); px(round(q[0]), round(q[1]), "silver_d")
    for s in (1, -1):
        for k, c in ((1.2, "silver"), (2.4, "silver")):
            q = add(g, n, s * k)
            px(round(q[0]), round(q[1]), c)
        q = add(add(g, n, s * 3.2), d, s * 0.9)  # 말린 가시 끝
        px(round(q[0]), round(q[1]), "silver_d")
    px(round(g[0]), round(g[1]), "gem")


def near_arm(p):
    sh = ub(20.5, 32.5)
    el = add(sh, p["elbow"])
    wr = add(sh, p["wrist"])
    up = tube([sh, el], lambda t: 3.3)
    paint(up, "bl", left="bl_d", right="bl_l")
    # 숄의 팔 쪽: 팔꿈치 위에서 팔을 가로질러 감는 반투명 니트 띠 + 아래로 늘어진 술
    ux, uy = el[0] - sh[0], el[1] - sh[1]
    ul = math.hypot(ux, uy) or 1
    ud = (ux / ul, uy / ul)
    un = (-ud[1], ud[0])
    c0 = add(sh, ud, ul * 0.72)
    band = tube([add(c0, un, -3.2), add(c0, un, 2.6)], lambda t: 3.0)
    for c in band:
        px(*c, "shawl")
    for (x, y) in band:
        if (x, y - 1) not in band:
            px(x, y, "shawl_l")
    low = {}
    for (x, y) in band:
        low[x] = max(low.get(x, -99), y)
    for i, x in enumerate(sorted(low)):
        ln = (3, 2, 4, 2, 3, 2)[i % 6]
        for k in range(ln):
            px(x + round(p["fringe"] * (k + 1) / 4), low[x] + 1 + k, "shawl_d" if k % 2 else "shawl")
    # 아래팔 소매: 손목 쪽으로 넓게 퍼지는 종 모양, 손을 손가락 중간까지 덮음
    fx, fy = wr[0] - el[0], wr[1] - el[1]
    fl = math.hypot(fx, fy) or 1
    fd = (fx / fl, fy / fl)
    cuff = add(wr, fd, 0.8)
    bell = tube([el, cuff], lambda t: 3.3 + 4.4 * t ** 1.6)
    paint(bell, "bl", left="bl_d", right="bl_l")
    for c, t in bell.items():
        if t > 0.93:
            px(*c, "bl_r")
    nn = (-fd[1], fd[0])
    for s in (-1.0, 1.0):  # 소매 주름
        line(*add(add(el, fd, fl * 0.5), nn, s), *add(add(el, fd, fl * 0.92), nn, s * 1.8), "bl_d")
    # 손가락 끝: 검게 물들고 잉크가 떨어짐
    f1 = add(cuff, fd, 1.4)
    f2 = add(cuff, fd, 2.4)
    px(round(f1[0]), round(f1[1]), "skin_s")
    px(round(f2[0]), round(f2[1]), "ink")
    px(round(f2[0]), round(f2[1]) + 1, "ink")
    if p.get("drip", True):
        px(round(f2[0]), round(f2[1]) + 2, "ink")


def outline():
    # 셀아웃: 외곽선 색 = 맞닿은 안쪽 색을 어둡게 (밝은 살 옆은 중간 톤, 옷 옆은 거의 검게)
    src = img.copy()
    S = src.load()
    for y in range(H):
        for x in range(W):
            if S[x, y][3] != 0:
                continue
            nb = [S[x + dx, y + dy] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)) if 0 <= x + dx < W and 0 <= y + dy < H]
            solid = [c for c in nb if c[3] >= 200]
            if not solid:
                continue
            r = sum(c[0] for c in solid) / len(solid)
            g = sum(c[1] for c in solid) / len(solid)
            b = sum(c[2] for c in solid) / len(solid)
            k = 0.55 if (r + g + b) / 3 > 150 else 0.22
            P[x, y] = (int(r * k) + 4, int(g * k) + 5, int(b * k) + 12, 255)


# ================================================================ 자세
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


def render(p):
    global img, P, BX, BY, LEAN
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    P = img.load()
    BX, BY, LEAN = p["bx"], p["by"], p["lean"]
    veil(p)
    overskirt(p)
    shawl_back(p)
    hair(p)
    nh, fh = NEAR_HIP, FAR_HIP
    if p.get("near_behind"):
        leg(nh, *p["near"], False)
        leg(fh, *p["far"], True)
    else:
        leg(fh, *p["far"], True)
        leg(nh, *p["near"], False)
    inner_skirt(p)
    torso(p)
    weapon(p)
    head(p)
    hat(p)
    near_arm(p)
    outline()
    return img


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else str(ROOT / "docs/art/eska/idle.png")
    render(IDLE).save(out)
