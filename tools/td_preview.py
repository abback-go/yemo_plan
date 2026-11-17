"""탑뷰 맵 미리보기: 맵 그림 위에 좌표 격자와 game/data/maps_data.gd 의 다각형(걷는 곳·막힌 곳·가림·앞벽·물건·출구·트리거·인물)을 그려
맵 데이터를 눈으로 확인한다. 노엘 걷기 그림 한 장을 시작 자리에 놓아 사람 키와 맵 밀도도 비교한다.
사용법: python3 tools/td_preview.py 맵id 출력.png [--scale 2] [--grid 20] [--crop x0,y0,x1,y1]
  맵id: maps_data.gd 의 키 (예: camp). 데이터가 없으면 --map td_camp.png 로 그림만 격자와 함께.
"""
import argparse
import json
import re
import sys
from PIL import Image, ImageDraw

ROOT = __file__.rsplit('/tools/', 1)[0]


def strip_comments(src):
    out = []
    for line in src.split('\n'):
        res, q = '', False
        for ch in line:
            if ch == '"':
                q = not q
            if ch == '#' and not q:
                break
            res += ch
        out.append(res)
    return '\n'.join(out)


def load_maps():
    src = open(ROOT + '/game/data/maps_data.gd', encoding='utf-8').read()
    body = src[src.index('const M := {') + len('const M := '):]
    body = strip_comments(body)
    body = re.sub(r',(\s*[}\]])', r'\1', body)
    body = body.replace('true', 'true').replace('false', 'false')
    dec = json.JSONDecoder()
    obj, _ = dec.raw_decode(body.strip())
    return obj


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('map_id')
    ap.add_argument('dst')
    ap.add_argument('--scale', type=int, default=2)
    ap.add_argument('--grid', type=int, default=20)
    ap.add_argument('--map')
    ap.add_argument('--crop')
    o = ap.parse_args()
    conf = {}
    if not o.map:
        conf = load_maps()[o.map_id]
    fn = o.map or conf['map']
    im = Image.open(ROOT + '/game/assets/' + fn).convert('RGBA')
    k = o.scale
    W, H = im.size
    big = im.resize((W * k, H * k), Image.NEAREST)
    ov = Image.new('RGBA', big.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    for x in range(0, W, o.grid):
        c = (255, 255, 255, 90 if x % (o.grid * 5) == 0 else 35)
        d.line([(x * k, 0), (x * k, H * k)], fill=c)
        if x % (o.grid * 5) == 0:
            d.text((x * k + 2, 2), str(x), fill=(255, 255, 0, 255))
    for y in range(0, H, o.grid):
        c = (255, 255, 255, 90 if y % (o.grid * 5) == 0 else 35)
        d.line([(0, y * k), (W * k, y * k)], fill=c)
        if y % (o.grid * 5) == 0:
            d.text((2, y * k + 2), str(y), fill=(255, 255, 0, 255))

    def P(pts):
        return [(p[0] * k, p[1] * k) for p in pts]

    if conf:
        if conf.get('walk'):
            d.polygon(P(conf['walk']), outline=(0, 255, 0, 255), fill=(0, 255, 0, 40))
        for b in conf.get('blocks', []):
            d.polygon(P(b), outline=(255, 40, 40, 255), fill=(255, 0, 0, 60))
        for oc in conf.get('occluders', []):
            d.polygon(P(oc['poly']), outline=(60, 140, 255, 255))
            d.line([(oc['poly'][0][0] * k - 10, oc['base'] * k), (oc['poly'][0][0] * k + 40, oc['base'] * k)], fill=(60, 140, 255, 255), width=2)
        for fr in conf.get('front', []):
            d.polygon(P(fr), outline=(255, 230, 0, 255), fill=(255, 230, 0, 40))
        for it in conf.get('items', []):
            x, y = it['at']
            d.ellipse([(x - 3) * k, (y - 3) * k, (x + 3) * k, (y + 3) * k], fill=(0, 255, 255, 255))
            sx, sy = it['spot']
            r = it['r']
            d.ellipse([(sx - r) * k, (sy - r) * k, (sx + r) * k, (sy + r) * k], outline=(0, 255, 255, 200))
            d.text((x * k + 6, y * k), it['id'], fill=(0, 255, 255, 255))
        for e in conf.get('exits', []):
            x, y = e['at']
            r = e['r']
            d.ellipse([(x - r) * k, (y - r) * k, (x + r) * k, (y + r) * k], outline=(255, 0, 255, 255), width=2)
            d.text((x * k + 6, y * k), 'EXIT ' + e['id'], fill=(255, 0, 255, 255))
        for t in conf.get('triggers', []):
            r = t['rect']
            d.rectangle([r[0] * k, r[1] * k, (r[0] + r[2]) * k, (r[1] + r[3]) * k], outline=(255, 140, 0, 255), width=2)
            d.text((r[0] * k + 4, r[1] * k + 4), 'TRG ' + t['id'], fill=(255, 140, 0, 255))
    big = Image.alpha_composite(big, ov)
    # 사람 키 비교: 노엘 그림(아래 방향 서기)을 시작·서는 자리에
    noel = Image.open(ROOT + '/game/assets/td_noel_walk.png').convert('RGBA').crop((64, 0, 128, 64))
    noel = noel.resize((64 * k, 64 * k), Image.NEAREST)
    spots = []
    if conf:
        spots = [conf.get('entry')] + [n.get('at') for n in conf.get('npcs', [])]
    else:
        spots = [[W // 2, H // 2]]
    for s in spots:
        if s:
            big.alpha_composite(noel, (int(s[0] * k - 32 * k), int(s[1] * k - 62 * k)))
    if o.crop:
        x0, y0, x1, y1 = (int(v) for v in o.crop.split(','))
        big = big.crop((x0 * k, y0 * k, x1 * k, y1 * k))
    big.convert('RGB').save(o.dst)
    print('저장', o.dst, big.size)


if __name__ == '__main__':
    main()
