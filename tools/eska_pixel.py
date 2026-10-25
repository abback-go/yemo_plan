"""에스카 대기 스프라이트 — 오른쪽을 향한 3/4 시점, 머리~발 약 48px (모자 포함 약 62px), 320×180 화면 기준.
부위(블록)를 뒤→앞 순서로 겹쳐 찍고, 부위마다 바깥 1px 외곽선을 먼저 깐다(sel-out).
글자 한 칸 = 도트 한 칸. 색 글자는 PAL 참고, '.'은 비움.
출력: docs/art/eska/idle48.png (1배), idle48_preview.png (8배 3종 배경 + 1·2·3배), idle48_scene.png (320×180 화면 4배)."""
import pathlib
import sys
from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parent.parent
W, H = 48, 64
G = [['.'] * W for _ in range(H)]
HAIR = '12345'


def hx(h, a=255):
    h = h.lstrip('#')
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


PAL = {
    'k': hx('#0d0f1c'), 'K': hx('#2e2a4a'),
    # 모자
    'a': hx('#151a3c'), 'b': hx('#232d62'), 'c': hx('#36468a'), 'd': hx('#5a72bc'),
    # 은
    'v': hx('#8390ad'), 'w': hx('#d6deec'), 'W': hx('#f7faff'),
    # 머리카락
    '1': hx('#1c2747'), '2': hx('#2d4170'), '3': hx('#46639c'), '4': hx('#6b8cc4'), '5': hx('#a9c4ec'),
    # 피부
    'f': hx('#f3eff6'), 'g': hx('#cfc7de'), 'G': hx('#9b90b6'), 'p': hx('#e8bfd2'),
    # 눈
    'i': hx('#1d3f78'), 'j': hx('#3f8fd6'), 'J': hx('#8fdcff'), 'y': hx('#e8eef8'), 'm': hx('#7a5a78'),
    # 옷
    'n': hx('#121935'), 'N': hx('#212c5c'), 'Q': hx('#34448a'), 'R': hx('#536ab8'),
    's': hx('#5a6890'), 't': hx('#8b9bc0'), 'T': hx('#c0cde6'),
    'u': hx('#24306a', 205), 'U': hx('#4a5ea8', 225),
    'B': hx('#10142a'), 'C': hx('#262e50'), 'D': hx('#4b5888'),
    # 무기
    '6': hx('#161d33'), '7': hx('#2c3a5e'), '8': hx('#51658f'),
    '9': hx('#1a1520'), '0': hx('#33293d'), '+': hx('#54475f'), '*': hx('#9fe0ff'),
    '#': hx('#05060c'),
}


def part(rows, outline='k', skip=''):
    """rows: {y: (x0, "...")}. 부위 바깥 둘레에 outline 색을 먼저 깔고(skip 색 위에는 안 깖) 부위를 칠한다."""
    cells = {}
    for y, (x0, s) in rows.items():
        for i, ch in enumerate(s):
            if ch != '.':
                cells[(x0 + i, y)] = ch
    if outline:
        for (x, y) in cells:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                q = (x + dx, y + dy)
                if q not in cells and 0 <= q[0] < W and 0 <= q[1] < H and G[q[1]][q[0]] not in skip:
                    G[q[1]][q[0]] = outline
    for (x, y), ch in cells.items():
        if 0 <= x < W and 0 <= y < H:
            G[y][x] = ch


def dots(lst):
    for x, y, c in lst:
        G[y][x] = c

# 1 검집 끝 + 빗자루 가지 (맨 뒤)
sc = {}
for x in range(12, 31):
    y = round(38 + (30 - x) * 7 / 19)
    sc.setdefault(y, {})[x] = '8'
    sc.setdefault(y + 1, {})[x] = '7'
sc.setdefault(44, {})[11] = 't'; sc.setdefault(45, {})[11] = 's'; sc.setdefault(46, {})[11] = 's'; sc[45][12] = 't'
rows = {}
for y, d in sc.items():
    x0 = min(d); rows[y] = (x0, "".join(d.get(x, '.') for x in range(x0, max(d) + 1)))
part(rows)
tw = []
for pts, c in (([(10, 46), (9, 45), (8, 45), (7, 44), (6, 44), (5, 43), (4, 43)], '+'),
               ([(10, 46), (9, 46), (8, 46), (7, 45), (6, 45), (5, 45), (4, 45), (3, 44)], '0'),
               ([(10, 47), (9, 47), (8, 47), (7, 47), (6, 47), (5, 47), (4, 47), (3, 47), (2, 47)], '+'),
               ([(10, 47), (9, 48), (8, 48), (7, 48), (6, 49), (5, 49), (4, 49), (3, 50)], '0'),
               ([(10, 48), (9, 49), (8, 49), (8, 50), (7, 51), (6, 51), (5, 52)], '+'),
               ([(11, 48), (10, 49), (10, 50), (9, 51), (9, 52), (8, 53)], '9'),
               ([(11, 48), (11, 49), (11, 50), (11, 51), (10, 52), (10, 53)], '0'),
               ([(9, 47), (8, 46), (7, 46), (6, 46)], '9'), ([(9, 48), (8, 48), (7, 49), (6, 50)], '9')):
    tw += [(x, y - 1, c) for x, y in pts]
dots(tw)

# 2 긴 뒷머리 (등 뒤로 흘러 허벅지까지, 끝이 갈라짐) + 목 뒤
part({19: (12, "2222"), 20: (11, "23432"), 21: (11, "34432"), 22: (10, "234432"), 23: (10, "344321"), 24: (10, "343321"),
      25: (10, "343221"), 26: (10, "342221"), 27: (10, "332121"), 28: (10, "322121"), 29: (10, "2321212222"), 30: (10, "2321212222"),
      31: (10, "2321212222"), 32: (10, "343212"), 33: (10, "343212"), 34: (9, "2343212"), 35: (9, "2343212"),
      36: (9, "234212"), 37: (9, "334212"), 38: (9, "33212"), 39: (9, "33212"), 40: (8, "233212"),
      41: (8, "232121"), 42: (8, "23212"), 43: (8, "2321.2"), 44: (7, "2.32.1"), 45: (7, "1..2.."), 46: (10, "1")})

# 3 겉치마 (시폰 뒷자락, 뒤=왼쪽으로 날림)
OS = {41: (18, 29), 42: (17, 30), 43: (16, 30), 44: (16, 30), 45: (15, 30), 46: (15, 30), 47: (14, 30), 48: (14, 30),
      49: (14, 30), 50: (13, 30), 51: (13, 30), 52: (13, 29), 53: (13, 29), 54: (14, 28), 55: (14, 27), 56: (15, 25)}
rows = {}
for y, (a, b) in OS.items():
    s = ['u'] * (b - a + 1)
    s[0] = 'U'
    if y >= 46 and 0 <= 16 - a < len(s):
        s[16 - a] = 'U'
    if y == 56:
        s = ['w' if (a + i) % 2 else 'U' for i in range(len(s))]
    rows[y] = (a, "".join(s))
part(rows)

# 4 먼 다리 + 부츠 (오른쪽으로 벌림, 한 줄 위 = 뒤쪽)
part({45: (25, "fffg"), 46: (25, "fffg"), 47: (26, "fffg"), 48: (26, "fffg"), 49: (27, "ffg"), 50: (27, "ffg"), 51: (28, "ffg"),
      52: (28, "ffg"),
      53: (27, "CDDC"), 54: (27, "BDBB"), 55: (27, "BDBB"), 56: (27, "BDBB"), 57: (27, "BDBBB"), 58: (27, "BDBBBB"),
      59: (27, "BCBBBBB"), 60: (27, "CCCCCCC")})
# 5 가까운 다리 + 부츠 (왼쪽으로 벌림, 체중)
part({45: (20, "fffg"), 46: (20, "fffg"), 47: (19, "fffg"), 48: (19, "fffg"), 49: (19, "ffg"), 50: (18, "ffg"), 51: (18, "ffg"),
      52: (18, "ffg"), 53: (17, "ffg"),
      54: (16, "CDDC"), 55: (16, "BDBB"), 56: (16, "BDBB"), 57: (16, "BDBB"), 58: (16, "BDBBB"), 59: (16, "BDBBBB"),
      60: (16, "BCBBBBB"), 61: (16, "CCCCCCC")})

# 6 치마 (짧은 플리츠)
part({40: (20, "RQQNQNNNn"), 41: (19, "QQNQNQNNnnn"), 42: (19, "QNQNQNQNNnn"), 43: (18, "QNQNnQNQNnNnn"),
      44: (17, "RQnRQnRQnRQnnQn")})

# 7 먼 팔 (몸 뒤로 늘어뜨림, 소매 끝에서 잉크가 떨어짐)
part({34: (29, "NNn"), 35: (30, "NNn"), 36: (30, "tts"), 37: (30, "sss"), 38: (30, "NNn"), 39: (29, "NNNn"),
      40: (29, "NNNNn"), 41: (29, "RRRRR"), 42: (31, "ff")})
dots([(31, 43, '#'), (32, 43, '#'), (32, 44, '#'), (32, 46, '#')])

# 8 몸통 (목·드러난 어깨·블라우스·코르셋)
part({30: (21, "GGG"), 31: (21, "fggg"), 32: (19, "fffffffffgg"), 33: (19, "fgfffffgfgg"),
      34: (19, "wwwwwwwwwww"), 35: (19, "QRRNNnNQRNnn"), 36: (19, "QQNNNnNNQNnn"),
      37: (19, "QnnNnnnwnNN"), 38: (20, "QnNnnnvnN"), 39: (20, "QnNnnnwnN")}, skip=HAIR)

# 9 손잡이 (가시 가드 + 하늘색 보석, 손잡이는 허리 앞으로 솟음)
part({37: (30, "w.C"), 38: (31, "*"), 39: (32, "w"), 36: (33, "D"), 35: (34, "C"), 34: (35, "w")})

# 10 가까운 팔 (몸 앞, 소매가 손목에서 퍼지고 손끝만 보임)
part({33: (16, "ffg"), 34: (15, "QNNn"), 35: (15, "QNNn"), 36: (14, "tTTts"), 37: (14, "sssss"), 38: (15, "QNNn"),
      39: (15, "QNNn"), 40: (14, "QQNNn"), 41: (14, "QNNNNn"), 42: (13, "QQNNNNn"), 43: (13, "RRRRRRR"),
      44: (16, "ff")})

# 11 머리 (얼굴 + 앞머리 + 옆머리) — 얼굴이 오른쪽으로 돌아 먼 쪽 볼·턱이 좁음
part({19: (12, "122222222222222222221"),
      20: (12, "233432345432345432321"),
      21: (12, "2334323232f3323f23331"),
      22: (12, "2334322kkkk23fkkk2231"),
      23: (12, "233432kiiiyf2fyiikf31"),
      24: (12, "233432fjJJfffffJjff31"),
      25: (12, "233432ffggfffffggff31"),
      26: (12, "233432fppffffffffpf31"),
      27: (12, "233432ffffffffffffg31"),
      28: (12, "233432.fffffffGffg.31"),
      29: (12, "233432...ffffffgg..31"),
      30: (12, "233432......fffg...31"),
      31: (12, "..3432.............32"),
      32: (12, "...342............32."),
      33: (12, "...332............32."),
      34: (12, "....32............2.."),
      35: (12, "....32..............."),
      36: (12, ".....2...............")}, skip=HAIR + 'fgG')

# 12 모자
part({1: (11, "cccbb"), 2: (10, "cbb..cba"), 3: (9, "cb.....cba"), 4: (9, "c.......cba"), 5: (17, "cbba"), 6: (17, "dcba"),
      7: (18, "dcba"), 8: (18, "dcbba"), 9: (18, "dcbba"), 10: (17, "dccbbba"), 11: (17, "dccbbbba"),
      12: (16, "kkkkkwwwkk"), 13: (16, "kkkkkwkwkkk"),
      14: (13, "dcccbbbbbbbbbbbbbbbba"), 15: (10, "dccbbbbbbbbbbbbbbbbbbbbbbba"),
      16: (9, "dcbbbbbbbbbbbbbbbbbbbbbbbbbba"), 17: (9, "cbbbbbbbbbbbbbbbbbbbbbbbbbbba"),
      18: (11, "aaaaaaaaaaaaaaaaaaaaaaaaa")})


def to_image():
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    P = im.load()
    for y in range(H):
        for x in range(W):
            if G[y][x] != '.':
                P[x, y] = PAL[G[y][x]]
    return im


def preview(im):
    z = 8
    tiles = []
    for bg in ((180, 160, 200, 255), (24, 26, 40, 255), (255, 255, 255, 255)):
        b = Image.new('RGBA', im.size, bg)
        b.alpha_composite(im)
        tiles.append(b.resize((W * z, H * z), Image.NEAREST))
    sheet = Image.new('RGBA', (sum(t.width for t in tiles) + 60 + W * 6, H * z), (60, 60, 70, 255))
    x = 0
    for t in tiles:
        sheet.paste(t, (x, 0))
        x += t.width + 20
    for s in (1, 2, 3):
        b = Image.new('RGBA', im.size, (180, 160, 200, 255))
        b.alpha_composite(im)
        sheet.paste(b.resize((W * s, H * s), Image.NEAREST), (x, 0))
        x += W * s
    return sheet


def scene(im):
    """320×180 화면에 1배로 놓고 4배 확대 (카메라 거리 확인용, 배경은 임시)."""
    SW, SH, GY = 320, 180, 140
    sc = Image.new('RGBA', (SW, SH))
    d = ImageDraw.Draw(sc)
    for y in range(SH):
        t = y / SH
        d.line([(0, y), (SW, y)], fill=(int(40 + 30 * t), int(36 + 20 * t), int(60 + 30 * t), 255))
    for x in range(0, SW, 24):
        d.rectangle([x + 6, 30, x + 12, GY], fill=(52, 48, 72, 255))
    d.rectangle([0, GY, SW, SH], fill=(30, 26, 38, 255))
    for x in range(0, SW, 16):
        d.rectangle([x, GY, x + 15, GY + 7], outline=(58, 52, 70, 255), fill=(44, 40, 56, 255))
    sc.alpha_composite(im, (140, GY - H + 1))
    return sc.resize((SW * 4, SH * 4), Image.NEAREST)


if __name__ == '__main__':
    out = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / 'docs/art/eska'
    out.mkdir(parents=True, exist_ok=True)
    im = to_image()
    im.save(out / 'idle48.png')
    preview(im).save(out / 'idle48_preview.png')
    scene(im).save(out / 'idle48_scene.png')
