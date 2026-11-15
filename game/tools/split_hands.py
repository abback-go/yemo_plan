"""부채꼴 손패를 쥔 두 손 그림(ui_witch_hands.png)을 왼손/오른손 두 장으로 나눈다.

카드를 낼 때 오른손만 손패에서 빠지게 하려고 쓴다(손이 세 개로 보이던 문제 해결).
두 손은 화면(캔버스) 가운데 x=836을 기준으로 떨어져 있다: 왼손 불투명 영역 x≤765, 오른손 x≥884.
원본(prototype/assets/ui_witch_hands.png)은 건드리지 않고 game/assets/ 에 결과를 만든다.

사용법(저장소 루트에서): python3 game/tools/split_hands.py
"""
import os
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
SRC = os.path.join(ROOT, 'prototype', 'assets', 'ui_witch_hands.png')
OUT = os.path.join(ROOT, 'game', 'assets')
SPLIT_X = 836  # 캔버스 1672×941 의 가운데


def main():
    im = Image.open(SRC).convert('RGBA')
    w, h = im.size
    a = im.split()[3]
    # 나누는 선 위에 불투명한 픽셀이 없어야 한다(손이 잘리면 안 됨)
    col = a.crop((SPLIT_X - 2, 0, SPLIT_X + 2, h))
    assert col.getextrema()[1] == 0, '가운데 선에 손 그림이 걸쳐 있다'
    im.crop((0, 0, SPLIT_X, h)).save(os.path.join(OUT, 'ui_witch_hand_left.png'))
    im.crop((SPLIT_X, 0, w, h)).save(os.path.join(OUT, 'ui_witch_hand_right.png'))
    print('ok', (w, h), '-> left', (SPLIT_X, h), 'right', (w - SPLIT_X, h), 'offset', SPLIT_X)


if __name__ == '__main__':
    main()
