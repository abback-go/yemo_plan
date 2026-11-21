"""game/assets 의 .import 설정을 그림 종류에 맞춘다 (가져오기 기본값은 손실 압축 + 밉맵).
- 픽셀 그림(td_*.png: 탑뷰 맵·걷기 시트·장치·함정): 무손실, 밉맵 없음 (Nearest 로 정수 배율 확대)
- 카드 그림(card_art_*.png, 800×800): 카드 앞면(약 400px)에 쓰므로 512 로 줄여 가져온다 (process/size_limit)
- 1차 시험판 v2 적 그림(spr_cult_knight·spr_pyre_priest, 약 1000×1500): 전투에서 높이 약 280px 로 그려지므로 768 로
- 전체 화면 그림은 기본값(손실 압축 + 밉맵: 휴대폰에서 줄여 그릴 때 깨끗하게) 그대로
사용법: python3 tools/fix_imports.py  (그 뒤 godot --headless --import 를 한 번 더)
"""
import glob
import os
import re

ROOT = os.path.join(os.path.dirname(__file__), '..', 'game', 'assets')


def setp(txt, key, val):
    pat = re.compile('^' + re.escape(key) + '=.*$', re.M)
    if pat.search(txt):
        return pat.sub(key + '=' + val, txt)
    return txt.replace('[params]\n', '[params]\n\n' + key + '=' + val + '\n', 1)


changed = 0
for f in sorted(glob.glob(os.path.join(ROOT, '*.png.import'))):
    name = os.path.basename(f)[:-7]
    t = open(f, encoding='utf-8').read()
    o = t
    if name.startswith('td_'):
        t = setp(t, 'compress/mode', '0')
        t = setp(t, 'mipmaps/generate', 'false')
    elif name.startswith('card_art_'):
        t = setp(t, 'process/size_limit', '512')
    elif name in ('spr_cult_knight.png', 'spr_pyre_priest.png'):
        t = setp(t, 'process/size_limit', '768')
    if t != o:
        open(f, 'w', encoding='utf-8').write(t)
        changed += 1
        print('고침', name)
print('바뀐 파일', changed)
