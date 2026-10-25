"""에스카 사이드뷰 대기 스프라이트 (오른쪽을 봄) → docs/art/eska-sprite-side.png (+ _preview.png 확대본)
기준: docs/gdd/assets/eska-sheet-v3.png, 앵커 tools/make_eska_prompts.py.
행마다 (뒤 x, 앞 x) 폭을 정해 채우는 방식. 빛: 뒤(왼쪽)에서 오는 차가운 역광 → 뒤쪽 가장자리가 밝다.
몸: 정수리 y18 ~ 발바닥 y69 (52px), 허리 폭 4px. 머리·모자·뒷머리·베일은 DY=-2로 그린다."""
import pathlib
import sys
from PIL import Image

OX, OY = 8, 6
W, H = 56, 80
img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
P = img.load()
DY = 0


def hx(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


C = {
    "out": hx("#070912"),
    "hat_d": hx("#0e1328"), "hat": hx("#19213e"), "hat_l": hx("#28345e"), "hat_r": hx("#4f67a6"),
    "band": hx("#05060c"), "silver": hx("#d6deec"), "silver_d": hx("#7b86a0"),
    "hair_dd": hx("#141b2f"), "hair_d": hx("#223050"), "hair": hx("#344a72"), "hair_l": hx("#50699a"), "hair_h": hx("#8aa6d4"),
    "skin_d": hx("#76829c"), "skin_s": hx("#a3afc6"), "skin": hx("#cdd6e6"), "skin_h": hx("#eef3fb"),
    "eye": hx("#9fdcff"), "eye2": hx("#4f95c8"), "glow": hx("#b9d9ef"), "lash": hx("#0b0f1c"),
    "bl_d": hx("#0f1530"), "bl": hx("#1c2546"), "bl_l": hx("#2d3a68"), "bl_r": hx("#45569a"),
    "shawl_d": hx("#3c4864", 200), "shawl": hx("#56647f", 185), "shawl_l": hx("#8292b0", 210),
    "cor": hx("#0a0d19"), "cor_l": hx("#262e48"),
    "sk_d": hx("#0e1327"), "sk": hx("#1a2242"), "sk_l": hx("#2b3764"), "sk_r": hx("#43559a"),
    "boot": hx("#0a0c15"), "boot_l": hx("#2b3249"),
    "sc_d": hx("#151c2f"), "sc": hx("#273450"), "sc_l": hx("#46597f"),
    "tw_d": hx("#0f0c13"), "tw": hx("#221d29"), "tw_l": hx("#3d3548"), "cord": hx("#556080"),
    "grip": hx("#131724"), "grip_l": hx("#2d3448"), "gem": hx("#9fd8ff"),
    "ink": hx("#020308"),
    "sheer": hx("#2a3a72", 100), "sheer2": hx("#3a4d8e", 125), "sheer_e": hx("#7487bc", 175), "emb": hx("#c4d2ee", 215),
    "veil": hx("#1c2858", 90), "veil_e": hx("#3f4f8c", 120),
}


def px(x, y, c):
    x += OX
    y += OY + DY
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


def poly(pts, c):
    ys = [p[1] for p in pts]
    for y in range(int(min(ys)), int(max(ys)) + 1):
        cy = y + 0.5
        xs = []
        n = len(pts)
        for i in range(n):
            (x0, y0), (x1, y1) = pts[i], pts[(i + 1) % n]
            if (y0 <= cy < y1) or (y1 <= cy < y0):
                xs.append(x0 + (cy - y0) * (x1 - x0) / (y1 - y0))
        xs.sort()
        for i in range(0, len(xs) - 1, 2):
            for x in range(int(xs[i] + 0.5), int(xs[i + 1] + 0.5)):
                px(x, y, c)


def spans(rows, c, back=None, front=None):
    """rows: {y: (x뒤, x앞)} 양끝 포함. back/front: 그 가장자리 1px 색."""
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


def lifted(fn):
    """머리 쪽 부품은 2px 위로 (목을 확보)."""
    def wrap():
        global DY
        DY = -2
        fn()
        DY = 0
    return wrap


# ================================================================ 맨 뒤
@lifted
def veil():
    poly([(11, 21), (16, 21), (16, 30), (15, 38), (12, 44), (9, 38), (9, 28)], "veil")
    line(9, 28, 9, 38, "veil_e"); line(9, 38, 12, 44, "veil_e")


def overskirt():
    # 시폰 겉치마: 허리 뒤에서 발목까지, 뒤로 흩날림. 앞트임이라 다리 뒤로 지나간다.
    poly([(19, 41), (25, 41), (24, 50), (23, 60), (23, 67), (16, 68), (10, 66), (13, 57), (16, 48)], "sheer")
    poly([(18, 44), (21, 44), (19, 56), (17, 66), (13, 67), (14, 57)], "sheer2")
    line(16, 48, 13, 57, "sheer_e"); line(13, 57, 10, 66, "sheer_e")
    line(10, 66, 16, 68, "sheer_e"); line(16, 68, 23, 67, "sheer_e")
    for x in range(11, 23, 2):
        px(x, 66 + (1 if x > 15 else 0), "emb")  # 밑단 글자 자수


def shawl_back():
    # 숄의 등 쪽: 뒷머리 밑으로 지나간다 (머리카락 밖으로 삐져나오지 않게 해서 등 실루엣을 가늘게)
    spans({37: (15, 19), 38: (15, 19), 39: (15, 19)}, "shawl")


@lifted
def hair_back():
    # 등 뒤로 가늘게 떨어지다가, 등 중간부터 바람 없이 뒤로 떠오르며 몸에서 떨어진다. 끝은 갈래로 나뉨.
    def drift(y):
        return 0 if y < 40 else -((y - 40) * 4 // 18)
    base = {}
    for y in range(20, 58):
        a, b = (15, 18) if y < 24 else (14, 18) if y < 34 else (15, 18)
        if y >= 52:
            a, b = a - (y - 52) // 2, b - (y - 51)
        d = drift(y)
        base[y] = (a + d, b + d)
    spans(base, "hair", back="hair_l")
    for (x, y) in ((9, 58), (10, 58), (9, 59), (8, 60), (12, 58), (12, 59), (13, 60)):
        px(x, y, "hair")   # 갈래 끝
    px(8, 59, "hair_l"); px(7, 60, "hair_l")
    # 결: 끊어진 어두운 가닥 + 몸 쪽 그늘
    for (x, y0, y1) in ((16, 24, 33), (16, 36, 41)):
        line(x, y0, x, y1, "hair_d")
    for y in range(42, 57):
        d = drift(y)
        if y % 7 != 3:
            px(16 + d, y, "hair_d")
        px(18 + d if y < 51 else 17 + d - (y - 51) // 2, y, "hair_dd")
    line(18, 31, 18, 41, "hair_dd")
    # 역광: 어깨 뒤가 가장 밝다
    line(14, 28, 14, 33, "hair_h"); line(15, 34, 15, 41, "hair_h")
    for y in range(44, 52):
        px(15 + drift(y), y, "hair_h" if y % 3 else "hair_l")
    for x in (15, 16, 17):
        px(x, 25, "hair_l")  # 머리 위쪽 윤기


def far_leg():
    # 뒤로 비스듬히 뻗은 먼 쪽 다리 (어둡게)
    rows = R(49, [(20, 22), (20, 22), (19, 22), (19, 22), (19, 21), (18, 21), (18, 21), (18, 20), (17, 20), (17, 20),
                  (16, 19), (16, 19), (16, 18), (16, 18), (16, 17)])
    spans(rows, "skin_d", back="skin_s")
    stamp(14, 64, ["ooo.....",
                   "ooooo...",
                   "oooooo..",
                   "ooooooo.",
                   "ooooooo.",
                   "oo...oo."], {"o": "boot"})
    line(14, 65, 14, 67, "boot_l")
    line(17, 66, 19, 67, "boot_l")  # 발등 반사광


# ================================================================ 몸
def inner_skirt():
    rows = R(42, [(19, 25), (18, 25), (18, 26), (18, 26), (17, 26), (17, 27), (17, 27)])
    spans(rows, "sk", back="sk_r", front="sk_d")
    for x0, x1 in ((20, 19), (22, 22), (24, 25)):
        line(x0, 43, x1, 48, "sk_d")
    line(17, 48, 27, 48, "sk_d")
    px(18, 49, "sk_d"); px(26, 49, "sk_d")  # 고르지 않은 밑단


def near_leg():
    # 허벅지 4 → 무릎 3 → 종아리 4(뒤로 불룩) → 발목 2
    rows = R(49, [(21, 24)] * 5 + [(22, 24)] * 4 + [(21, 24), (21, 24), (21, 23), (22, 23), (22, 23), (22, 23)])
    spans(rows, "skin", back="skin_h", front="skin_s")
    for x in range(22, 25):
        px(x, 49, "skin_s")  # 치마 밑 그늘
    px(23, 55, "skin_h")  # 무릎
    # 발목 부츠: 발목 바로 위, 낮은 굽, 앞코가 오른쪽
    stamp(21, 63, ["ooo.....",
                   "oLoo....",
                   "oLooo...",
                   "oLoooo..",
                   "oooooooo",
                   "ooooooooo",
                   "oo...ooo."], {"o": "boot", "L": "boot_l"})
    line(24, 67, 28, 67, "boot_l")
    px(29, 68, "boot_l"); px(22, 69, "boot_l")  # 앞코·굽


def torso():
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


@lifted
def head():
    # 오른쪽을 보는 옆얼굴. 뒷머리는 매끈하게 뒤로 흘러 둥근 덩어리를 피하고,
    # 옆머리가 뒤쪽 볼을 가려 얼굴은 좁고 길게, 턱은 뾰족하게. 눈은 끝이 처진 긴 속눈썹 + 빛나는 눈동자.
    HEAD = [
        # x: 14          27
        "KHHHHHHHHDD...",  # 22 챙 아래
        "THHHHHHHDDSS__",  # 23 이마 (챙 그늘)
        "THHDHHHDHDSS__",  # 24 뾰족한 앞머리 가닥
        "THHDHHDHSkkkk_",  # 25 긴 속눈썹 (끝이 앞으로 뻗음)
        "THHDHHDHSeEs__",  # 26 빛나는 눈
        "THHDHHDHSsssv_",  # 27 작은 코끝
        "THHDHHDHSssl__",  # 28 입술
        ".THDHHDH_sS___",  # 29 작은 턱끝 — 턱선은 실루엣 경계가 귀 쪽으로 대각선
        ".THDHHDH______",  # 30
        "..THDHDH......",  # 31 (목은 그대로 둠)
    ]
    stamp(14, 22, HEAD, {"H": "hair", "D": "hair_d", "K": "hair_dd", "T": "hair_l", "S": "skin_s", "s": "skin",
                         "v": "skin_h", "z": "skin_d", "l": "skin_s", "k": "lash", "E": "eye", "e": "eye2", "_": "clear"})
    # 옆머리: 귀 앞에서 가슴까지, 끝이 뾰족
    line(21, 27, 21, 35, "hair"); line(22, 32, 22, 34, "hair_d"); px(21, 36, "hair_d")
    line(20, 33, 20, 37, "hair_d")
    for x, y in ((16, 23), (17, 23), (18, 24)):
        px(x, y, "hair_l")  # 윤기


def tube(center, width):
    """중심선(점 목록)을 따라 폭 width(t)(t=0~1, 길이 비율)로 채운 픽셀 집합 (로컬 좌표)."""
    import math
    seg = [math.dist(center[i], center[i + 1]) for i in range(len(center) - 1)]
    total = sum(seg)
    samples = []
    acc = 0.0
    for i, L in enumerate(seg):
        (x0, y0), (x1, y1) = center[i], center[i + 1]
        n = max(2, int(L * 4))
        for k in range(n):
            u = k / n
            samples.append((x0 + (x1 - x0) * u, y0 + (y1 - y0) * u, (acc + L * u) / total, (x1 - x0) / L, (y1 - y0) / L))
        acc += L
    samples.append((*center[-1], 1.0, samples[-1][3], samples[-1][4]))
    cells = set()
    for (x, y, t, dx, dy) in samples:
        w = width(t) / 2
        nx, ny = -dy, dx
        steps = max(1, int(w * 3))
        for k in range(-steps, steps + 1):
            q = k / steps * w
            cells.add((int(math.floor(x + nx * q)), int(math.floor(y + ny * q))))
    return cells


@lifted
def hat():
    # 밑동이 넓게 벌어지고 옆선은 오목하게 좁아지며 곧게 솟다가, 위에서 한 번 각지게 꺾여 바늘처럼 가는 끝이 뒤를 향한다
    TB = 0.58  # 꺾이는 자리 (길이 비율)

    def width(t):
        if t < TB:
            return 2.8 + 7.7 * (1 - t / TB) ** 2.2
        return 2.8 * (1 - (t - TB) / (1 - TB)) ** 1.1

    center = [(20.0, 20.5), (19.6, 15), (19.0, 10), (18.4, 5.0), (14.5, 4.2), (10.0, 5.4), (6.0, 7.2), (3.0, 9.0)]
    cells = tube(center, width)
    for (x, y) in cells:
        px(x, y, "hat")
    for (x, y) in cells:
        up = x >= 16  # 세운 부분
        if up and (x - 1, y) not in cells:
            px(x, y, "hat_r")                      # 세운 부분 뒤쪽 가장자리: 역광
        elif not up and (x, y - 1) not in cells:
            px(x, y, "hat_r")                      # 꺾여 처진 부분 윗면: 역광
        elif (x, y - 1) not in cells:
            px(x, y, "hat_l")                      # 꺾인 모서리 윗면
        elif up and (x + 1, y) not in cells:
            px(x, y, "hat_d")                      # 앞쪽 그늘
        elif not up and (x, y + 1) not in cells:
            px(x, y, "hat_d")                      # 처진 부분 아랫면 그늘
    # 꺾인 자리의 날카로운 주름 + 원뿔 둥근 면의 은은한 빛
    line(16, 6, 18, 5, "hat_d")
    line(18, 9, 18, 16, "hat_l")
    # 띠 + 버클
    spans({18: (15, 24), 19: (15, 24)}, "band")
    stamp(21, 17, ["ss", "sd", "dd"], {"s": "silver", "d": "silver_d"})
    # 챙: 얇고 넓게, 뒤 끝은 살짝 들리고 앞 끝은 살짝 숙임
    def poly_line(pts, c):
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            line(x0, y0, x1, y1, c)
    poly_line([(5, 19), (10, 20), (15, 21), (26, 22), (32, 23), (36, 24)], "hat")
    poly_line([(8, 20), (12, 21), (16, 22), (26, 23), (31, 24), (34, 25)], "hat_d")
    poly_line([(7, 18), (11, 19), (15, 20), (25, 21), (31, 22), (34, 23)], "hat_l")
    line(7, 18, 11, 19, "hat_r")  # 챙 윗면 뒤쪽 역광
    px(4, 18, "hat_r"); px(3, 18, "hat_r")     # 뒤 끝이 가늘게 들림
    px(37, 24, "hat"); px(38, 25, "hat_d")     # 앞 끝이 가늘게 숙임


def weapon():
    # 칼집: 왼쪽 허리에서 뒤로 비스듬히
    line(25, 44, 10, 56, "sc"); line(25, 45, 11, 57, "sc_d"); line(24, 44, 10, 55, "sc_l")
    stamp(24, 43, ["ss", "sd"], {"s": "silver", "d": "silver_d"})  # 입구 장식
    px(21, 47, "silver_d"); px(22, 47, "silver_d"); px(18, 49, "silver_d"); px(19, 49, "silver_d")  # 버클 끈
    # 빗자루 끝: 끈으로 묶은 검은 나뭇가지 다발
    stamp(8, 55, [".cc", "cc.", "c.."], {"c": "cord"})
    for (a, b, c) in [((8, 57), (0, 63), "tw"), ((8, 58), (2, 65), "tw_d"), ((7, 56), (0, 60), "tw"),
                      ((9, 58), (5, 66), "tw"), ((7, 56), (1, 57), "tw_d"), ((8, 57), (2, 62), "tw_l"),
                      ((8, 58), (4, 64), "tw_l")]:
        line(*a, *b, c)
    px(-1, 61, "tw_d"); px(1, 66, "tw_d"); px(-1, 58, "tw_d"); px(6, 67, "tw_d")
    # 손잡이 + 뾰족한 은 폼멜
    line(27, 41, 30, 38, "grip"); line(27, 42, 30, 39, "grip_l")
    px(31, 37, "silver"); px(32, 36, "silver_d")
    # 가시 가지 십자 가드 + 하늘색 보석 (칼날 축에 수직, 양끝이 가시처럼 말림)
    for (x, y, c) in ((23, 40, "silver_d"), (24, 40, "silver"), (25, 41, "silver"), (26, 42, "gem"),
                      (27, 43, "silver"), (28, 44, "silver"), (28, 45, "silver_d"), (23, 39, "silver_d")):
        px(x, y, c)


def near_arm():
    # 위팔 (슬림한 소매)
    spans(R(32, [(19, 21)] * 8), "bl", back="bl_d", front="bl_l")
    # 숄의 팔 쪽: 팔꿈치 높이에서 위팔을 감쌈 (반투명 니트)
    spans({37: (18, 22), 38: (18, 22), 39: (19, 22)}, "shawl")
    line(18, 37, 22, 37, "shawl_l")
    px(20, 38, "shawl_d")
    for x, ln in ((18, 3), (19, 4), (21, 2), (22, 3)):
        for k in range(ln):
            px(x, 40 + k, "shawl_d" if k % 2 else "shawl")
    # 아래팔 소매: 손목 쪽으로 넓게 퍼지고 손을 손가락 중간까지 덮음
    rows = R(40, [(19, 21), (19, 22), (18, 22), (18, 23), (18, 23), (17, 23), (17, 24), (17, 24)])
    spans(rows, "bl", back="bl_d", front="bl_l")
    line(17, 47, 24, 47, "bl_r")
    # 손가락 끝: 검게 물들고 잉크가 길게 떨어짐
    px(21, 48, "skin_s"); px(22, 48, "ink"); px(21, 49, "ink"); px(22, 49, "ink"); px(22, 50, "ink")


def outline():
    # 셀아웃: 외곽선 색 = 맞닿은 안쪽 색을 어둡게 (밝은 살·은 옆은 덜 검게, 옷 옆은 거의 검게)
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
            lum = (r + g + b) / 3
            k = 0.55 if lum > 150 else 0.22
            P[x, y] = (int(r * k) + 4, int(g * k) + 5, int(b * k) + 12, 255)


def polish():
    # 소매 주름 (종 모양 소매에 세로 결)
    for (x, y0, y1) in ((20, 43, 46), (22, 44, 46)):
        line(x, y0, x, y1, "bl_d")
    px(21, 45, "bl_l")
    # 안치마 뒤쪽 역광 한 줄 더
    px(18, 45, "sk_r"); px(17, 47, "sk_r")


for part in (veil, overskirt, shawl_back, hair_back, far_leg, inner_skirt, near_leg, torso, weapon, head, hat, near_arm, polish, outline):
    part()

ROOT = pathlib.Path(__file__).resolve().parent.parent
out = sys.argv[1] if len(sys.argv) > 1 else str(ROOT / "docs/art/eska-sprite-side.png")
img.save(out)
# 확대 미리보기: 8배 + 2배 + 실제 크기, 어두운 배경
bg = hx("#1a1f2e")
s = 8
big = img.resize((W * s, H * s), Image.NEAREST)
mid = img.resize((W * 2, H * 2), Image.NEAREST)
prev = Image.new("RGBA", (W * s + W * 2 + 30, H * s + 20), bg)
prev.alpha_composite(big, (10, 10))
prev.alpha_composite(mid, (W * s + 20, 10))
prev.alpha_composite(img, (W * s + 20, H * 2 + 30))
prev.save(out.replace(".png", "_preview.png"))
