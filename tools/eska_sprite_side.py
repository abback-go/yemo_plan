"""에스카 사이드뷰 대기 스프라이트 (오른쪽을 봄) → docs/art/eska-sprite-side.png (+ _preview.png 확대본)
기준: docs/gdd/assets/eska-sheet-v3.png, 앵커 tools/make_eska_prompts.py.
행마다 (뒤 x, 앞 x) 폭을 정해 채우는 방식. 빛: 뒤(왼쪽)에서 오는 차가운 역광 → 뒤쪽 가장자리가 밝다.
몸: 정수리 y18 ~ 발바닥 y69 (52px). 머리·모자·뒷머리·베일은 DY=-2로 그린다."""
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
    poly([(10, 21), (16, 21), (15, 30), (14, 38), (11, 44), (8, 38), (8, 28)], "veil")
    line(8, 28, 8, 38, "veil_e"); line(8, 38, 11, 44, "veil_e")


def overskirt():
    # 시폰 겉치마: 허리 뒤에서 발목까지, 뒤로 흩날림. 앞트임이라 다리 뒤로 지나간다.
    poly([(17, 41), (26, 41), (24, 51), (22, 60), (22, 67), (14, 68), (7, 66), (10, 58), (14, 49)], "sheer")
    poly([(17, 44), (21, 44), (18, 56), (16, 66), (12, 67), (13, 57)], "sheer2")
    line(14, 49, 10, 58, "sheer_e"); line(10, 58, 7, 66, "sheer_e")
    line(7, 66, 14, 68, "sheer_e"); line(14, 68, 22, 67, "sheer_e")
    for x in range(8, 22, 2):
        px(x, 66 + (1 if x > 12 else 0), "emb")  # 밑단 글자 자수


def shawl_back():
    # 숄의 등 쪽: 뒷머리 밑으로 지나가 술만 머리카락 아래로 비친다
    spans({37: (10, 18), 38: (9, 18), 39: (9, 18), 40: (10, 18)}, "shawl")
    line(10, 37, 18, 37, "shawl_l")
    for x, ln in ((9, 3), (10, 5), (11, 2)):
        for k in range(ln):
            px(x, 41 + k, "shawl_d" if k % 2 else "shawl")


@lifted
def hair_back():
    # 어깨 뒤에서 부풀었다가, 등 중간부터 바람 없이 뒤로 떠오르며 몸에서 떨어진다. 끝은 갈래로 나뉨.
    def drift(y):
        return 0 if y < 40 else -((y - 40) * 4 // 18)
    base = {}
    for y in range(20, 58):
        a, b = (14, 17) if y < 24 else (13, 17) if y < 30 else (12, 17)
        if y >= 52:
            a, b = a - (y - 52) // 2, b - (y - 51)
        d = drift(y)
        base[y] = (a + d, b + d)
    spans(base, "hair", back="hair_l")
    for (x, y) in ((7, 58), (8, 58), (7, 59), (6, 60), (10, 58), (10, 59), (11, 60)):
        px(x, y, "hair")   # 갈래 끝
    px(6, 59, "hair_l"); px(5, 60, "hair_l")
    # 결: 끊어진 어두운 가닥 + 몸 쪽 그늘
    for (x, y0, y1) in ((15, 24, 33), (15, 36, 41), (13, 30, 38)):
        line(x, y0, x, y1, "hair_d")
    for y in range(42, 57):
        d = drift(y)
        if y % 7 != 3:
            px(14 + d, y, "hair_d")
        px(17 + d if y < 51 else 16 + d - (y - 51) // 2, y, "hair_dd")
    line(17, 31, 17, 41, "hair_dd")
    # 역광: 어깨 뒤가 가장 밝다
    line(12, 31, 12, 41, "hair_h")
    for y in range(44, 52):
        px(12 + drift(y), y, "hair_h" if y % 3 else "hair_l")
    for x in (14, 15, 16):
        px(x, 25, "hair_l")  # 머리 위쪽 윤기


def far_leg():
    # 뒤로 비스듬히 뻗은 먼 쪽 다리 (어둡게)
    rows = R(49, [(19, 22), (19, 22), (18, 22), (18, 21), (18, 21), (17, 21), (17, 21), (17, 20), (16, 20), (16, 20),
                  (15, 19), (15, 19), (15, 18), (15, 18), (15, 17)])
    spans(rows, "skin_d", back="skin_s")
    stamp(13, 64, ["oooo....",
                   "oooooo..",
                   "ooooooo.",
                   "oooooooo",
                   "oooooooo",
                   "oo...ooo"], {"o": "boot"})
    line(13, 65, 13, 67, "boot_l")
    line(16, 66, 19, 67, "boot_l")  # 발등 반사광


# ================================================================ 몸
def inner_skirt():
    rows = R(42, [(18, 26), (17, 26), (17, 27), (16, 27), (16, 28), (16, 28), (15, 28)])
    spans(rows, "sk", back="sk_r", front="sk_d")
    for x0 in (19, 22, 25):
        line(x0, 43, x0 - (1 if x0 < 22 else 0), 48, "sk_d")
    line(15, 48, 28, 48, "sk_d")
    px(16, 49, "sk_d"); px(27, 49, "sk_d")  # 고르지 않은 밑단


def near_leg():
    rows = R(49, [(21, 25), (21, 25), (21, 25), (21, 25), (21, 25), (22, 25), (22, 25), (22, 25), (22, 24), (21, 24),
                  (21, 24), (21, 24), (22, 24), (22, 24), (22, 23)])
    spans(rows, "skin", back="skin_h", front="skin_s")
    for x in range(22, 26):
        px(x, 49, "skin_s")  # 치마 밑 그늘
    line(24, 51, 24, 54, "skin_s")
    px(25, 56, "skin_s"); px(24, 55, "skin_h")  # 무릎
    line(23, 59, 23, 61, "skin_s")
    # 발목 부츠: 발목 바로 위, 낮은 굽, 앞코가 오른쪽
    stamp(21, 63, ["oooo.....",
                   "oLooo....",
                   "oLoooo...",
                   "oLooooo..",
                   "ooooooooo",
                   "oooooooooo",
                   "oo....oooo"], {"o": "boot", "L": "boot_l"})
    line(25, 67, 29, 67, "boot_l")
    px(30, 68, "boot_l"); px(22, 69, "boot_l")  # 앞코·굽


def torso():
    spans(R(29, [(20, 23), (20, 23)]), "skin", back="skin_s")
    px(22, 29, "skin_s"); px(23, 29, "skin_s")  # 턱 그늘
    spans({31: (18, 24)}, "skin", back="skin_s")  # 드러난 어깨·쇄골
    px(23, 31, "skin_h"); px(24, 31, "skin_h")
    spans(R(32, [(18, 26), (18, 27), (18, 27), (18, 26)]), "bl", back="bl_d", front="bl_l")
    line(19, 32, 26, 32, "bl_l")
    for x in (20, 22, 24):
        px(x, 32, "silver_d")  # 목선 은실 글자 자수
    px(27, 33, "bl_r")
    spans(R(36, [(18, 25), (19, 24), (19, 24), (19, 24), (19, 25), (18, 25)]), "cor", front="cor_l")
    line(19, 36, 25, 36, "cor_l")
    for y in (37, 39, 41):
        px(24, y, "silver")
    for y in (38, 40):
        px(25, y, "silver_d")


@lifted
def head():
    # 머리 실루엣 (머리카락), 오른쪽을 봄
    spans(R(20, [(15, 24), (14, 25), (14, 25), (14, 26), (14, 26), (14, 26), (14, 26), (15, 26), (15, 25), (15, 24), (16, 23)]),
          "hair", back="hair_l")
    # 옆얼굴: 이마(챙 그늘) → 속눈썹 → 빛나는 눈 → 코끝 → 입 → 턱
    FACE = ["HHHHHHDD_",
            "HHHHHDS__",
            "HHHHDLLS_",
            "HHHDgEeS_",
            "HHHSssssv",
            "HHHSssss_",
            "HH.SsssS_",
            "HH..Sss__",
            "H...SS___",
            ]
    stamp(19, 23, FACE, {"H": "hair", "D": "hair_d", "S": "skin_s", "s": "skin", "v": "skin_h",
                         "L": "lash", "E": "eye", "e": "eye2", "g": "glow", "_": "clear"})
    line(21, 27, 21, 30, "hair_d")  # 얼굴로 흘러내린 잔머리
    for x, y in ((16, 24), (17, 24), (18, 25), (15, 25)):
        px(x, y, "hair_l")  # 윤기
    # 옆머리 (귀 앞에서 가슴까지)
    line(19, 26, 19, 35, "hair"); line(20, 30, 20, 36, "hair_d"); px(19, 36, "hair_d")


@lifted
def hat():
    cone = R(4, [(7, 11), (8, 14), (10, 16), (12, 17), (13, 18), (14, 19), (15, 20), (15, 21), (16, 22), (16, 22),
                 (16, 23), (16, 23), (16, 24), (16, 24), (15, 25)])
    spans(cone, "hat", back="hat_r", front="hat_d")
    px(6, 5, "hat"); px(6, 6, "hat_d")
    line(18, 9, 20, 15, "hat_l")  # 원뿔 접힌 자리의 빛
    spans({19: (15, 25), 20: (15, 25)}, "band")
    stamp(21, 18, ["ss", "sd", "dd"], {"s": "silver", "d": "silver_d"})
    # 챙: 넓게, 앞으로 살짝 숙임
    line(5, 20, 35, 22, "hat_l")
    line(4, 21, 36, 23, "hat")
    line(6, 22, 34, 24, "hat_d")
    px(3, 21, "hat_r"); px(4, 20, "hat_r"); px(37, 24, "hat"); px(36, 24, "hat_d")
    px(3, 22, "hat"); px(2, 22, "hat_r"); px(2, 23, "hat_d")  # 챙 끝이 살짝 처짐
    px(38, 24, "hat_d"); px(38, 25, "hat_d"); px(37, 25, "hat_d")


def weapon():
    # 칼집: 왼쪽 허리에서 뒤로 비스듬히
    line(27, 44, 10, 57, "sc"); line(27, 45, 11, 58, "sc_d"); line(26, 44, 10, 56, "sc_l")
    stamp(26, 43, ["ss", "sd"], {"s": "silver", "d": "silver_d"})  # 입구 장식
    px(22, 47, "silver_d"); px(23, 47, "silver_d"); px(19, 49, "silver_d"); px(20, 49, "silver_d")  # 버클 끈
    # 빗자루 끝: 끈으로 묶은 검은 나뭇가지 다발
    stamp(8, 56, [".cc", "cc.", "c.."], {"c": "cord"})
    for (a, b, c) in [((8, 58), (0, 64), "tw"), ((8, 59), (2, 66), "tw_d"), ((7, 57), (0, 61), "tw"),
                      ((9, 59), (5, 67), "tw"), ((7, 57), (1, 58), "tw_d"), ((8, 58), (2, 63), "tw_l"),
                      ((8, 59), (4, 65), "tw_l")]:
        line(*a, *b, c)
    px(-1, 62, "tw_d"); px(1, 67, "tw_d"); px(-1, 59, "tw_d"); px(6, 68, "tw_d")
    # 손잡이 + 뾰족한 은 폼멜
    line(29, 41, 32, 38, "grip"); line(29, 42, 32, 39, "grip_l")
    px(33, 37, "silver"); px(34, 36, "silver_d")
    # 가시 가지 십자 가드 + 하늘색 보석 (칼날 축에 수직, 양끝이 가시처럼 말림)
    for (x, y, c) in ((25, 40, "silver_d"), (26, 40, "silver"), (27, 41, "silver"), (28, 42, "gem"),
                      (29, 43, "silver"), (30, 44, "silver"), (30, 45, "silver_d"), (25, 39, "silver_d")):
        px(x, y, c)


def near_arm():
    # 위팔 (슬림한 소매)
    spans(R(32, [(19, 22)] * 8), "bl", back="bl_d", front="bl_l")
    # 숄의 팔 쪽: 팔꿈치 높이에서 위팔을 감쌈 (반투명 니트)
    spans({37: (17, 22), 38: (17, 23), 39: (17, 23), 40: (18, 22)}, "shawl")
    line(17, 37, 22, 37, "shawl_l")
    px(19, 39, "shawl_d"); px(22, 39, "shawl_d")
    for x, ln in ((17, 3), (18, 5), (20, 2), (21, 4), (23, 2)):
        for k in range(ln):
            px(x, 41 + k, "shawl_d" if k % 2 else "shawl")
    # 아래팔 소매: 손목 쪽으로 넓게 퍼지고 손을 손가락 중간까지 덮음
    rows = R(41, [(19, 22), (18, 23), (18, 24), (18, 24), (17, 25), (17, 25), (17, 26), (17, 26)])
    spans(rows, "bl", back="bl_d", front="bl_l")
    line(17, 48, 26, 48, "bl_r")
    # 손가락 끝: 검게 물들고 잉크가 길게 떨어짐
    px(22, 49, "skin_s"); px(23, 49, "ink"); px(22, 50, "ink"); px(23, 50, "ink"); px(23, 51, "ink")


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
            k = 0.22
            P[x, y] = (int(r * k) + 4, int(g * k) + 5, int(b * k) + 12, 255)


def polish():
    # 소매 주름 (종 모양 소매에 세로 결)
    for (x, y0, y1) in ((20, 44, 47), (23, 45, 47)):
        line(x, y0, x, y1, "bl_d")
    px(21, 46, "bl_l")
    # 챙 윗면 뒤쪽에 역광
    line(5, 20, 12, 20, "hat_r")
    # 안치마 뒤쪽 역광 한 줄 더
    px(16, 45, "sk_r"); px(15, 47, "sk_r")


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
