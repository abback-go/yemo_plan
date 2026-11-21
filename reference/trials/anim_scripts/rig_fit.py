# C 부위 뼈대의 쉬는 자세(데이터 그대로 조립) vs 지금 뒷모습 그림 — 나란히 + 겹쳐 보기
import re, json, sys
from PIL import Image, ImageDraw
G = '/home/user/yemo_plan/.claude/worktrees/agent-abf0228873c2e506a/game/'
OUT = sys.argv[1]
src = open(G + 'data/anim_rig.gd').read()
rig = json.loads(src[src.index('const SERA := ') + len('const SERA := '):])
W, H = rig['frame']
canvas = Image.new('RGBA', (W, H), (0, 0, 0, 0))
for p in sorted(rig['parts'], key=lambda p: p['z']):
    im = Image.open(G + 'assets/' + p['file']).convert('RGBA').resize(tuple(p['size']))
    canvas.alpha_composite(im, (round(p['pos'][0]), round(p['pos'][1])))
back = Image.open(G + 'assets/spr_hero_back.png').convert('RGBA')
bg = (58, 54, 60, 255)
out = Image.new('RGBA', (W * 3 + 40, H + 40), bg)
out.alpha_composite(back, (0, 40))
out.alpha_composite(canvas, (W + 20, 40))
# 겹쳐 보기: 뒷모습 = 청록 윤곽, 부위 조립 = 붉은 윤곽
ov = Image.new('RGBA', (W, H), (0, 0, 0, 255))
a1 = back.getchannel('A').point(lambda v: 255 if v > 60 else 0)
a2 = canvas.getchannel('A').point(lambda v: 255 if v > 60 else 0)
ov.paste((40, 170, 190, 255), (0, 0), a1)
red = Image.new('RGBA', (W, H), (210, 30, 40, 150))
ov.alpha_composite(Image.composite(red, Image.new('RGBA', (W, H), (0, 0, 0, 0)), a2))
out.alpha_composite(ov, (W * 2 + 40, 40))
d = ImageDraw.Draw(out)
d.text((8, 8), 'now: spr_hero_back.png', fill=(255, 255, 200))
d.text((W + 28, 8), 'C rig rest pose (04 parts)', fill=(255, 255, 200))
d.text((W * 2 + 48, 8), 'overlay: cyan=now, red=rig', fill=(255, 255, 200))
for y in range(0, H, 100):
    d.line([(0, y + 40), (out.size[0], y + 40)], fill=(255, 255, 0, 60))
out.convert('RGB').save(OUT, quality=90)
print('saved', OUT, out.size)
