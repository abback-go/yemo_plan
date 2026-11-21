# 기본 / A′ / C 비교 그림·영상 만들기 → scratchpad/vs_shots/anim_compare_*
import glob, json, os, subprocess
from PIL import Image, ImageDraw, ImageFont
OUT = '/tmp/claude-0/-home-user-yemo-plan/c9580547-3e2b-5444-b985-f8d79472150f/scratchpad/vs_shots'
FONT = '/home/user/yemo_plan/.claude/worktrees/agent-abf0228873c2e506a/game/assets/fonts/NotoSerifKR-KS-Bold.ttf'
MODES = [('base', '기본'), ('a', "A' (?anim=a)"), ('c', 'C (?anim=c)')]
font = ImageFont.truetype(FONT, 22)
CROP = (300, 110, 980, 720)


def pick(files, n, lo=0.0, hi=1.0):
    if not files:
        return []
    a, b = int(len(files) * lo), max(int(len(files) * hi) - 1, int(len(files) * lo))
    return [files[round(a + (b - a) * i / (n - 1))] for i in range(n)]


def moving(fs, kind, box=(440, 250, 840, 720)):
    """세라피나 둘레가 마지막 프레임(쉬는 자세)과 얼마나 다른지로 장면을 고른다.
    attack: 앞쪽 컷인 프레임(차이 큼)을 건너뛴 뒤 차이가 가장 큰 곳 ±6 / hit: 차이가 가장 크게 뛰는 곳 −2 ~ +12"""
    from PIL import ImageChops, ImageStat
    if len(fs) < 5:
        return fs
    last = Image.open(fs[-1]).convert('L').crop(box)
    d = [ImageStat.Stat(ImageChops.difference(Image.open(f).convert('L').crop(box), last)).mean[0] for f in fs]
    if kind == 'attack':
        i = 0
        while i < len(d) and d[i] > 20:
            i += 1
        rest = d[i:]
        if not rest:
            return fs
        pk = i + rest.index(max(rest))
        return fs[max(i, pk - 6): pk + 7]
    jumps = [d[k] - d[k - 1] for k in range(1, len(d))]
    j = 1 + jumps.index(max(jumps))
    return fs[max(0, j - 2): j + 13]


def sheet(kind, variant, n=8, lo=0.0, hi=1.0, scale=0.5):
    rows = []
    for m, label in MODES:
        d = os.path.join(OUT, 'anim_' + m + variant)
        fs = sorted(glob.glob(os.path.join(d, 'f_' + kind, '*.png')))
        if kind != 'idle':
            fs = moving(fs, kind)
        rows.append((label, pick(fs, n, lo, hi)))
    w, h = int((CROP[2] - CROP[0]) * scale), int((CROP[3] - CROP[1]) * scale)
    LW = 170
    S = Image.new('RGB', (LW + w * n, h * len(rows) + 30), (18, 16, 20))
    dr = ImageDraw.Draw(S)
    for c in range(n):
        dr.text((LW + c * w + 6, 4), '%d' % (c + 1), font=font, fill=(230, 220, 160))
    for r, (label, fs) in enumerate(rows):
        dr.text((8, 30 + r * h + h // 2 - 12), label, font=font, fill=(240, 235, 225))
        for c, f in enumerate(fs):
            im = Image.open(f).convert('RGB').crop(CROP).resize((w, h))
            S.paste(im, (LW + c * w, 30 + r * h))
    name = os.path.join(OUT, 'anim_compare_%s%s.jpg' % (kind, variant))
    S.save(name, quality=88)
    print(name, S.size)


def video(variant):
    ins, filt, durs = [], [], []
    for i, (m, label) in enumerate(MODES):
        d = os.path.join(OUT, 'anim_' + m + variant)
        t = json.load(open(os.path.join(d, 'state.json')))['times']
        v = glob.glob(os.path.join(d, 'video', '*.webm'))[0]
        t0, t1 = t['strike'] - 1.2, t.get('heroHit', t['turn2']) + 6.0
        durs.append(t1 - t0)
        ins += ['-ss', '%.2f' % t0, '-t', '%.2f' % (t1 - t0), '-i', v]
        filt.append('[%d:v]scale=640:360,setpts=PTS-STARTPTS,tpad=stop_mode=clone:stop_duration=20,'
                    "drawtext=fontfile=%s:text='%s':x=12:y=10:fontsize=26:fontcolor=white:box=1:boxcolor=black@0.55:boxborderw=6[v%d]" % (i, FONT, label.replace("'", "’").replace(':', '\\:'), i))
    D = max(durs)
    fc = ';'.join(filt) + ';[v0][v1][v2]vstack=inputs=3,trim=duration=%.2f[out]' % D
    name = os.path.join(OUT, 'anim_compare%s.webm' % variant)
    subprocess.run(['ffmpeg', '-v', 'error', '-y'] + ins + ['-filter_complex', fc, '-map', '[out]', '-c:v', 'libvpx-vp9', '-b:v', '1500k', '-deadline', 'realtime', '-cpu-used', '8', name], check=True)
    print(name, os.path.getsize(name), 'dur %.1f' % D)


for variant in ['_nohand', '']:
    sheet('attack', variant, 8)
    sheet('hit', variant, 8)
    sheet('idle', variant, 4)
    video(variant)
