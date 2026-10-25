"""에스카 동작 프레임 정의 + 내보내기 (tools/eska_sprite.py 리그 사용).
내보내기: docs/art/eska/ 에 동작별 시트 PNG(가로 한 줄), 전체 시트, 미리보기 GIF(4배, 배경 포함)."""
import math
import pathlib
import sys
from PIL import Image

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import eska_sprite as S  # noqa: E402

OUT = S.ROOT / "docs/art/eska"


def lerp(a, b, t):
    if isinstance(a, tuple):
        return tuple(lerp(x, y, t) for x, y in zip(a, b))
    return a + (b - a) * t


# ---------------------------------------------------------------- 달리기 (8프레임, 질주)
# 상체를 26° 숙이고 낮게. 다리 역할: 앞다리 F0 착지 → F1 체중 실음(가장 낮음) → F2 밀어냄 → F3 발끝으로 차고 나감(뒤로 길게)
# / 뒷다리 B0 발꿈치를 차올림 → B1 엉덩이까지 접음 → B2 무릎을 높이 듦 → B3 앞으로 뻗음
F = [((6.0, 7.5), (7.0, 16.2), -12), ((5.5, 7.0), (1.0, 15.5), 5), ((2.0, 8.8), (-4.0, 16.3), 25), ((-3.0, 8.6), (-11.5, 13.0), 65)]
B = [((-3.5, 8.3), (-12.0, 8.0), 88), ((1.0, 8.5), (-7.0, 6.0), 92), ((8.5, 3.5), (3.0, 9.5), 45), ((8.5, 4.3), (12.0, 12.0), -8)]
BOB = [3, 4, 3, 2]
# 팔: 팔꿈치를 굽혀 크게 흔듦 (가까운 다리가 앞에 닿을 때 가까운 팔은 뒤로)
ARM = [((-6.0, 4.0), (-5.5, 10.5)), ((-4.0, 6.0), (-1.5, 11.5)), ((-1.0, 7.0), (3.0, 11.0)), ((2.0, 6.5), (6.5, 8.0)),
       ((3.5, 5.5), (7.5, 2.5)), ((2.0, 6.5), (6.5, 8.0)), ((-1.0, 7.0), (3.0, 11.0)), ((-4.0, 6.0), (-1.5, 11.5))]


def run_frames():
    fr = []
    for i in range(8):
        ph = i % 4
        w = math.sin(i / 8 * 2 * math.pi)
        w2 = math.sin(i / 4 * 2 * math.pi)
        near, far = (F[ph], B[ph]) if i < 4 else (B[ph], F[ph])
        elbow, wrist = ARM[i]
        fr.append(S.pose(
            by=BOB[ph], lean_deg=26 + (1 if ph == 1 else 0), near=near, far=far, elbow=elbow, wrist=wrist,
            hair=(-8 + w, -6, -17 + 2 * w, -14 + 1.5 * w2), skirt=(0.5, -1.0 + 0.5 * w2, -3.5, -3 - 0.8 * w),
            over=(-15 + 2 * w, -10 + 1.5 * w2), veil=(-10 + w, -5 + w2), sword=20 + 5 * w2, fringe=-5, drip=False))
    return fr


# ---------------------------------------------------------------- 점프
# 이륙 → 상승(2) → 정점 → 하강(2) → 착지. 상승 땐 머리카락·치마가 아래로 끌리고, 정점부터 떠오른다.
P = S.pose
JUMP = {
    "takeoff": P(by=-1, lean=0.05, near=((0.5, 10.0), (1.0, 19.0), 65), far=((-1.0, 10.0), (-3.0, 18.5), 70),
                 elbow=(-2.0, 7.0), wrist=(-2.0, 14.0), hair=(0, 2, 2, 4), skirt=(0, 1, 0, 1), over=(-1, 3), veil=(0, 2), sword=-4),
    "rise_a": P(lean=0.05, near=((5.0, 7.0), (2.0, 14.5), 30), far=((-2.0, 9.5), (-5.0, 17.5), 60),
                elbow=(1.0, 6.5), wrist=(4.0, 11.0), hair=(1, 3, 3, 6), skirt=(0.5, 1, 0, 1.5), over=(-1, 4), veil=(0, 3), sword=-8),
    "rise_b": P(lean=0.05, near=((5.0, 7.5), (2.5, 15.0), 30), far=((-2.0, 9.5), (-5.5, 17.0), 62),
                elbow=(1.0, 6.5), wrist=(4.0, 11.5), hair=(1.5, 3, 4, 7), skirt=(0.5, 1.2, 0, 1.8), over=(-1.5, 5), veil=(0, 3.5), sword=-9),
    "apex": P(lean=0.03, near=((4.0, 8.0), (1.0, 15.5), 40), far=((0.0, 9.0), (-3.0, 16.5), 50),
              elbow=(2.0, 6.0), wrist=(5.0, 9.5), hair=(-1, -2, -2, -6), skirt=(0.5, -1, -1, -1.5), over=(-3, -4), veil=(-1, -2), sword=0,
              fringe=0),
    "fall_a": P(lean=0.02, near=((2.0, 9.5), (3.0, 18.5), 20), far=((-2.0, 9.5), (-4.0, 18.0), 35),
                elbow=(2.5, 5.0), wrist=(6.0, 7.5), hair=(-2, -5, -1, -14), skirt=(1, -2, -2, -3), over=(-2, -10), veil=(-1, -5),
                sword=8, drip=False),
    "fall_b": P(lean=0.02, near=((2.0, 9.5), (3.5, 18.5), 18), far=((-2.0, 9.5), (-4.5, 17.5), 38),
                elbow=(2.5, 4.5), wrist=(6.5, 7.0), hair=(-2.5, -6, -2, -16), skirt=(1.2, -2.4, -2.4, -3.4), over=(-3, -12),
                veil=(-1.5, -6), sword=10, drip=False),
    "land": P(by=4, lean=0.15, near=((6.0, 7.0), (1.5, 15.0), 0), far=((3.0, 8.0), (-3.0, 14.5), 0),
              elbow=(0.5, 6.0), wrist=(3.0, 11.0), hair=(1, 3, 3, 4), skirt=(1, 0, -1, 0), over=(-1, 2), veil=(0, 2), sword=4),
}

# ---------------------------------------------------------------- 이단점프: 공중의 마법진을 딛고 다시 도약
DJUMP = {
    "dj_tuck": P(by=-2, lean=-0.04, near=((6.0, 4.0), (1.0, 10.5), 40), far=((5.0, 5.0), (-1.0, 11.5), 45),
                 elbow=(-2.0, 6.0), wrist=(1.0, 10.0), hair=(-3, -4, -4, -10), skirt=(1.5, -2, -2, -2.5), over=(-4, -8),
                 veil=(-2, -4), sword=12, drip=False),
    "dj_kick": P(by=-3, lean=0.0, near=((1.0, 9.5), (0.0, 18.5), 70), far=((-1.0, 9.5), (-2.0, 18.5), 75),
                 elbow=(-3.0, 5.0), wrist=(-6.0, 8.0), hair=(0, 2, 2, 4), skirt=(2, 0, -2, 0), over=(-2, 3), veil=(0, 2), sword=-6),
    "dj_burst": P(by=-3, lean=0.02, near=((0.5, 10.0), (0.5, 19.0), 75), far=((-1.0, 10.0), (-1.5, 19.0), 80),
                  elbow=(-2.0, 6.5), wrist=(-4.5, 12.5), hair=(1, 4, 4, 8), skirt=(0, 1.5, 0, 2), over=(-1, 6), veil=(0, 4), sword=-12),
}

# ---------------------------------------------------------------- 돌진 대시: 몸을 깊이 숙이고 머리·치마·베일이 뒤로 길게 날림
DASH = {
    "dash_start": P(by=2, lean_deg=20, near=((6.0, 6.0), (3.0, 14.0), 10), far=((-3.0, 9.0), (-9.0, 15.0), 40),
                    elbow=(-4.0, 4.0), wrist=(-8.0, 7.0), hair=(-6, -3, -12, -8), skirt=(0, -1, -3, -2), over=(-10, -6),
                    veil=(-6, -2), sword=15, fringe=-4),
    "dash": P(by=4, lean_deg=30, near=((7.0, 5.0), (5.0, 13.0), 0), far=((-5.0, 8.0), (-12.0, 12.0), 60),
              elbow=(-5.0, 3.0), wrist=(-10.0, 5.0), hair=(-8, -6, -18, -14), skirt=(0, -1.5, -4, -3), over=(-16, -12),
              veil=(-9, -4), sword=25, fringe=-5, drip=False),
    "dash_end": P(by=1, lean_deg=12, near=((4.0, 8.0), (2.0, 16.5), 0), far=((-2.0, 9.0), (-6.0, 16.0), 30),
                  elbow=(-1.0, 6.5), wrist=(1.5, 12.5), hair=(-4, -2, -8, -6), skirt=(0, -0.5, -1.5, -1), over=(-6, -3),
                  veil=(-3, -1), sword=8, fringe=-2),
}

WAVE_AMP = {"idle": 0.8, "run": 2.6, "jump": 1.4, "double_jump": 1.8, "dash": 2.8}


def with_wave(name, frames):
    """머리 물결: 동작별 진폭, 프레임마다 위상이 π/2씩 흘러 4프레임에 물결 하나가 지나간다."""
    out = []
    for i, f in enumerate(frames):
        q = dict(f)
        q.setdefault("hwave", (WAVE_AMP[name], i * math.pi / 2))
        out.append(q)
    return out


ANIMS = {
    "idle": [S.IDLE],
    "run": run_frames(),
    "jump": [JUMP[k] for k in ("takeoff", "rise_a", "rise_b", "apex", "fall_a", "fall_b", "land")],
    "double_jump": [DJUMP[k] for k in ("dj_tuck", "dj_kick", "dj_burst")],
    "dash": [DASH[k] for k in ("dash_start", "dash", "dash_end")],
}
ANIMS = {k: with_wave(k, v) for k, v in ANIMS.items()}


def frames_of(name):
    return [S.render(p).copy() for p in ANIMS[name]]


# ---------------------------------------------------------------- 효과 (게임에서는 따로 그리는 층)
LAV, ICE, WHITE = (185, 162, 255), (159, 216, 255), (232, 246, 255)


def magic_circle(rx, ry, alpha, runes=True, sparks=0):
    """공중에 옆에서 본 마법진 (납작한 타원 두 겹 + 룬 눈금). 중심 = 이미지 가운데."""
    im = Image.new("RGBA", (40, 16), (0, 0, 0, 0))
    cx, cy = 20, 8
    P = im.load()

    def put(x, y, c, a):
        x, y = round(x), round(y)
        if 0 <= x < 40 and 0 <= y < 16:
            r, g, b, a0 = P[x, y]
            if a > a0:
                P[x, y] = (*c, a)
    for i in range(160):
        t = i / 160 * 2 * math.pi
        put(cx + rx * math.cos(t), cy + ry * math.sin(t), LAV, int(255 * alpha))
        put(cx + rx * 0.6 * math.cos(t), cy + ry * 0.6 * math.sin(t), ICE, int(200 * alpha))
    if runes:
        for k in range(10):
            t = k / 10 * 2 * math.pi + 0.3
            put(cx + rx * math.cos(t), cy + ry * math.sin(t) - (1 if math.sin(t) < 0 else 0), WHITE, int(255 * alpha))
    for k in range(sparks):  # 위로 튀는 빛 알갱이
        t = k * 2.39
        put(cx + math.cos(t) * rx * 0.8, cy - 2 - (k % 3) * 2, ICE if k % 2 else LAV, int(230 * alpha))
    return im


def speed_lines(i, w, h):
    """몸 뒤로 빠르게 지나가는 가는 빛줄기 (게임에서는 효과 층)."""
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    P = im.load()
    for j in range(7):
        y = 30 + (j * 13 + 7) % 60
        ln = 6 + (j * 5) % 9
        x0 = (w - ((i * 22 + j * 37) % (w + 40))) + 10
        for x in range(x0, x0 + ln):
            if 0 <= x < w and 0 <= y < h:
                a = int(110 * (1 - (x - x0) / ln))
                P[x, y] = (150, 175, 220, a)
    return im


def dust_puff(k):
    """착지 먼지: 작은 회청색 알갱이 덩어리가 뒤로 퍼지며 옅어진다."""
    im = Image.new("RGBA", (40, 16), (0, 0, 0, 0))
    P = im.load()
    a = int(200 * (1 - k / 3))
    for j, (x, y) in enumerate(((16, 12), (18, 11), (20, 12), (15, 10), (19, 9), (22, 11), (17, 13), (21, 10))):
        if j < 4 + 2 * k:
            xx, yy = x - k * (1 + j % 2), y - k * (j % 3 == 0)
            if 0 <= xx < 40 and 0 <= yy < 16:
                P[xx, yy] = (120, 132, 160, a if j % 2 else a // 2)
    return im


def ghost(frame, color, k):
    """잔상: 실루엣만 남긴 색 그림자."""
    g = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    src, dst = frame.load(), g.load()
    for y in range(frame.height):
        for x in range(frame.width):
            a = src[x, y][3]
            if a:
                dst[x, y] = (*color, int(a * k))
    return g


def compose(name, seq, size, ms, ground_y, scroll=0):
    """seq: [(프레임 그림, dx, dy, [(효과 그림, x, y), ...]), ...] → 4배 GIF. 바닥선 ground_y (칸 좌표)."""
    bw, bh = size
    out = []
    for i, (f, dx, dy, fx) in enumerate(seq):
        bg = Image.new("RGBA", (bw, bh), (16, 19, 31, 255))
        for x in range(bw):
            bg.putpixel((x, ground_y), (34, 39, 58, 255))
            for y in range(ground_y + 1, bh):
                bg.putpixel((x, y), (20, 23, 36, 255))
        if scroll:
            for k in range(-1, bw // 16 + 2):
                x = (k * 16 - i * scroll) % (bw + 16) - 8
                for xx in range(x, x + 6):
                    if 0 <= xx < bw:
                        bg.putpixel((xx, ground_y + 3), (40, 46, 68, 255))
        for (e, ex, ey) in fx:
            if e.width > 40:  # 잔상 (몸 뒤)
                bg.alpha_composite(e, (ex, ey))
        bg.alpha_composite(f, (dx, dy))
        for (e, ex, ey) in fx:
            if e.width <= 40:  # 마법진 (몸 앞)
                bg.alpha_composite(e, (ex, ey))
        out.append(bg.resize((bw * 4, bh * 4), Image.NEAREST).convert("P", palette=Image.ADAPTIVE, colors=255))
    durs = ms if isinstance(ms, list) else [ms] * len(out)
    out[0].save(OUT / f"{name}.gif", save_all=True, append_images=out[1:], duration=durs, loop=0, disposal=2)


def build_gifs():
    fr = {k: S.render(v).copy() for k, v in {**JUMP, **DJUMP, **DASH, "idle": S.IDLE}.items()}
    run = frames_of("run")
    gy = 30 + S.OY + 69 + 1  # 바닥선 (위 여백 30)
    top = 30
    # 달리기: 제자리 + 바닥 무늬가 흐름
    dust = [dust_puff(k) for k in range(3)]
    seq = []
    for i, f in enumerate(run):
        fx = []
        for c in (0, 4):  # 발이 닿는 프레임부터 3프레임 동안 먼지가 뒤로 흩어진다
            k = (i - c) % 8
            if k < 3:
                fx.append((dust[k], 20 + S.OX + 22 - 8 - 4 * k, gy - 9))
        fx.append((speed_lines(i, S.W + 40, S.H + top + 8), 0, 0))
        seq.append((f, 20, top, fx))
    compose("run", seq, (S.W + 40, S.H + top + 8), 40, gy, scroll=14)
    # 점프
    J = [("takeoff", 0), ("rise_a", -10), ("rise_b", -18), ("rise_a", -24), ("apex", -27), ("apex", -28), ("fall_a", -26),
         ("fall_b", -20), ("fall_a", -12), ("fall_b", -3), ("land", 0), ("land", 0), ("idle", 0), ("idle", 0)]
    compose("jump", [(fr[k], 20, top + dy, []) for k, dy in J], (S.W + 40, S.H + top + 8), 80, gy)
    # 이단점프: 정점 근처에서 몸을 웅크렸다가 마법진을 딛고 다시 솟는다
    top2 = 62
    gy2 = top2 + S.OY + 69 + 1
    D = [("takeoff", 0), ("rise_a", -10), ("rise_b", -18), ("apex", -24), ("dj_tuck", -26), ("dj_kick", -26),
         ("dj_burst", -33), ("rise_a", -41), ("rise_b", -47), ("apex", -50), ("apex", -51), ("fall_a", -47),
         ("fall_b", -39), ("fall_a", -28), ("fall_b", -15), ("fall_a", -4), ("land", 0), ("land", 0), ("idle", 0), ("idle", 0)]
    cx, cy = 20 + S.OX + 22 - 20, top2 + S.OY + 65 - 26 - 3 - 8   # 마법진 그림의 왼쪽 위 (딛는 발밑)
    circles = {5: [magic_circle(7, 1.8, 0.85, runes=False)], 6: [magic_circle(13, 3.2, 1.0, sparks=7)],
               7: [magic_circle(15, 3.8, 0.55, sparks=5)], 8: [magic_circle(17, 4.2, 0.25, runes=False)]}
    seq = []
    for i, (k, dy) in enumerate(D):
        seq.append((fr[k], 20, top2 + dy, [(c, cx, cy) for c in circles.get(i, [])]))
    compose("double_jump", seq, (S.W + 40, S.H + top2 + 8), 80, gy2)
    # 대시: 앞으로 미끄러지며 잔상을 남김
    X = [("idle", 0), ("dash_start", 2), ("dash", 12), ("dash", 26), ("dash", 40), ("dash_end", 48), ("dash_end", 50),
         ("idle", 51), ("idle", 51)]
    seq = []
    for i, (k, x) in enumerate(X):
        ghosts = []
        if k == "dash":
            for j, (gx, a) in enumerate(((x - 13, 0.3), (x - 26, 0.14))):
                ghosts.append((ghost(fr["dash"], ICE if j % 2 == 0 else LAV, a), 4 + gx, top))
        seq.append((fr[k], 4 + x, top, ghosts))
    compose("dash", seq, (S.W + 70, S.H + top + 8), [200, 60, 50, 50, 50, 70, 90, 200, 300], gy)


def sheet(name, frames):
    sh = Image.new("RGBA", (S.W * len(frames), S.H), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sh.alpha_composite(f, (S.W * i, 0))
    sh.save(OUT / f"{name}.png")
    return sh


def full_sheet():
    """모든 동작을 줄별로: 대기 / 달리기 8 / 점프 7 / 이단점프 3 / 대시 3. 1배 시트 + 3배 미리보기(이름표)."""
    from PIL import ImageDraw
    rows = [(n, frames_of(n)) for n in ANIMS]
    cols = max(len(f) for _, f in rows)
    sh = Image.new("RGBA", (S.W * cols, S.H * len(rows)), (0, 0, 0, 0))
    for r, (_, fr) in enumerate(rows):
        for i, f in enumerate(fr):
            sh.alpha_composite(f, (S.W * i, S.H * r))
    sh.save(OUT / "sheet.png")
    pv = Image.new("RGBA", sh.size, (26, 31, 46, 255))
    pv.alpha_composite(sh)
    pv = pv.resize((sh.width * 3, sh.height * 3), Image.NEAREST)
    d = ImageDraw.Draw(pv)
    for r, (n, fr) in enumerate(rows):
        d.text((6, S.H * 3 * r + 4), f"{n} ({len(fr)})", fill=(200, 210, 235, 255))
    pv.save(OUT / "sheet_preview.png")


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for name in ANIMS:
        sheet(name, frames_of(name))
    full_sheet()
    build_gifs()
