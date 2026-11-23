"""웹 배포본 만들기: prototype/를 복사하면서 그림(PNG)을 WebP로 압축한다.

휴대폰 회선에서 처음 로딩을 줄이기 위한 것. 저장소의 원본 PNG는 그대로 둔다.
사용법: python3 tools/build_web.py 출력폴더 [--quality 82]
"""
import argparse
import os
import shutil
from PIL import Image

SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'prototype')


def build(out, quality):
    if os.path.exists(out):
        shutil.rmtree(out)
    os.makedirs(out)
    for d in ('css', 'js'):
        shutil.copytree(os.path.join(SRC, d), os.path.join(out, d))
    html = open(os.path.join(SRC, 'index.html'), encoding='utf-8').read()
    tag = '<script src="js/data.js"></script>'
    assert tag in html
    html = html.replace(tag, "<script>window.GAME_ASSET_EXT = 'webp';</script>\n" + tag)
    open(os.path.join(out, 'index.html'), 'w', encoding='utf-8').write(html)
    src_a, out_a = os.path.join(SRC, 'assets'), os.path.join(out, 'assets')
    os.makedirs(out_a)
    before = after = 0
    for f in sorted(os.listdir(src_a)):
        p = os.path.join(src_a, f)
        before += os.path.getsize(p)
        if f.endswith('.png'):
            q = os.path.join(out_a, f[:-4] + '.webp')
            im = Image.open(p)
            im.save(q, 'WEBP', quality=quality, method=6)
        else:
            q = os.path.join(out_a, f)
            shutil.copy(p, q)
        after += os.path.getsize(q)
    print(f'assets: {before / 1e6:.1f}MB -> {after / 1e6:.1f}MB')


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('out')
    ap.add_argument('--quality', type=int, default=82)
    a = ap.parse_args()
    build(a.out, a.quality)
