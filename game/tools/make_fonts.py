"""게임에 넣는 한글 글꼴(Noto Sans KR / Noto Serif KR, OFL)을 만든다.

웹 다운로드 크기를 줄이려고 자주 쓰는 한글 2,350자(KS X 1001) + 영문·문장부호만 남긴다.
대사에 이 목록에 없는 드문 글자(예: 똠, 쀍)를 쓰면 네모로 보인다 → 헤드리스 테스트(test_rules.gd)가
data/game_data.gd 의 모든 글자가 글꼴에 있는지 검사하므로, 실패하면 EXTRA 에 글자를 넣고 다시 만든다.

필요: pip install fonttools
사용법: python3 game/tools/make_fonts.py <NotoSansKR[wght].ttf> <NotoSerifKR[wght].ttf>
(원본: https://github.com/google/fonts/tree/main/ofl/notosanskr , notoserifkr)
"""
import os
import subprocess
import sys
import tempfile

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'fonts')
EXTRA = ''  # KS X 1001 밖의 글자가 필요하면 여기에 넣는다
RANGES = ('U+0020-007E,U+00A0-00FF,U+2000-206F,U+2190-21FF,U+2460-24FF,U+25A0-25FF,'
          'U+2600-26FF,U+2700-27BF,U+3000-303F,U+3130-318F,U+FF00-FFEF')


def ks_syllables():
    cs = []
    for cp in range(0xAC00, 0xD7A4):
        try:
            if len(chr(cp).encode('euc-kr')) == 2:
                cs.append(cp)
        except UnicodeEncodeError:
            pass
    cs += [ord(c) for c in EXTRA]
    return ','.join('U+%04X' % c for c in cs)


def subset(src, out, uni):
    subprocess.check_call(['pyftsubset', src, '--unicodes=' + uni, '--output-file=' + out,
                           '--layout-features=*', '--no-hinting'])


def main():
    sans, serif = sys.argv[1], sys.argv[2]
    uni = RANGES + ',' + ks_syllables()
    subset(sans, os.path.join(OUT, 'NotoSansKR-KS.ttf'), uni)   # 굵기 축(wght)이 남는 가변 글꼴
    with tempfile.TemporaryDirectory() as tmp:
        for w, name in ((400, 'Regular'), (700, 'Bold')):
            inst = os.path.join(tmp, 'serif%d.ttf' % w)
            subprocess.check_call([sys.executable, '-m', 'fontTools.varLib.instancer', serif, 'wght=%d' % w, '-o', inst])
            subset(inst, os.path.join(OUT, 'NotoSerifKR-KS-%s.ttf' % name), uni)
    print('ok')


if __name__ == '__main__':
    main()
