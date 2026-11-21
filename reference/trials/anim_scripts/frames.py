# 녹화 영상에서 구간별 프레임을 뽑아 한 장으로: python3 frames.py <anim_X 폴더> [fps_attack] [fps_hit]
import json, os, subprocess, sys, glob, shutil
from PIL import Image, ImageDraw
d = sys.argv[1]
fa = float(sys.argv[2]) if len(sys.argv) > 2 else 8
fh = float(sys.argv[3]) if len(sys.argv) > 3 else 5
st = json.load(open(os.path.join(d, 'state.json')))
t = st['times']
vid = glob.glob(os.path.join(d, 'video', '*.webm'))[0]
CROP = (150, 90, 1130, 720)


def grab(name, t0, t1, fps):
    out = os.path.join(d, 'f_' + name)
    shutil.rmtree(out, ignore_errors=True)
    os.makedirs(out)
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-ss', '%.2f' % t0, '-to', '%.2f' % t1, '-i', vid, '-vf', 'fps=%g' % fps, os.path.join(out, '%03d.png')], check=True)
    return sorted(glob.glob(os.path.join(out, '*.png')))


def sheet(files, name, cols=6, scale=0.5):
    ims = [Image.open(f).convert('RGB').crop(CROP) for f in files]
    if not ims:
        return
    w, h = ims[0].size
    w2, h2 = int(w * scale), int(h * scale)
    rows = (len(ims) + cols - 1) // cols
    S = Image.new('RGB', (w2 * cols, h2 * rows), (20, 20, 20))
    dr = ImageDraw.Draw(S)
    for i, im in enumerate(ims):
        x, y = (i % cols) * w2, (i // cols) * h2
        S.paste(im.resize((w2, h2)), (x, y))
        dr.text((x + 6, y + 4), str(i), fill=(255, 255, 0))
    S.save(os.path.join(d, name), quality=85)
    print(name, len(ims), S.size)


a = grab('attack', t['strike'] - 0.3, t['attackEnd'], fa)
sheet(a, 'sheet_attack.jpg')
if 'heroHit' in t:
    h = grab('hit', t['heroHit'] + 0.5, t['heroHit'] + 6.0, 10)
else:
    h = grab('hit', t['endTurn'], t['turn2'], fh)
sheet(h, 'sheet_hit.jpg')
i = grab('idle', t['idle0'], t['idle1'], 2)
sheet(i, 'sheet_idle.jpg')
