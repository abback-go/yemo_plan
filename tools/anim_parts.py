"""움직임 시험 C(?anim=c): 세라피나 부위 분리 시트 → 게임 부위 그림 + 뼈대 배치(json).

- 원본: art/raw/vs/04_seraphina_parts.webp (1536×1024, 초록 크로마 배경)
- 배경 제거: tools/vs_import.py 와 같은 방식(remove_bg.py --soft 100 + 테두리 번짐 정리). remove_bg.py 기본 동작은 그대로.
- 부위: 알파로 이어진 덩어리(9px 넓혀서 이음)마다 하나. 시트에서 쓰는 것만 이름을 붙인다
  (오른쪽 위팔·아래팔 한 쌍은 성검 든 팔(한 장)과 겹쳐 쓰지 않는다).
- 조립: 시트 좌표에서 몸통을 기준으로 부위를 옮겨(OFFSET) 뒷모습(spr_hero_back.png, 높이 1100)과 같은 틀에 맞춘다.
  발끝 = 1100, 몸 가운데(등뼈) x = 222(뒷모습 그림의 머리 가운데). 망토만 0.8 배로 줄였다(시트의 망토가 몸에 비해 길고 넓다).
- 결과: game/assets/anim/sera_<부위>.png + game/data/anim_rig.gd(AnimRig.SERA — 웹 내보내기에 .json 이 빠지지 않게 GDScript 상수로)
  {"frame": [w, h], "parts": [{"name", "file", "parent", "z", "pos": 그림 왼쪽 위, "size", "pivot": 관절}]} — 좌표는 모두 뒷모습 틀(높이 1100) 기준
사용법: python3 tools/anim_parts.py
"""
import json
import os
import sys
from collections import deque

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np  # noqa: E402
from PIL import Image, ImageFilter  # noqa: E402
import vs_import  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'game', 'assets', 'anim')
FRAME = (507, 1100)       # spr_hero_back.png 크기
SPINE_X = 222             # 뒷모습 그림에서 몸 가운데 x
TORSO_SPINE = 853         # 시트에서 몸통 가운데 x

# 부위: 덩어리 안의 점(시트 좌표) → 이름, 옮김(dx, dy), 배율, 부모, z, 관절(시트 좌표, 옮긴 뒤)
PARTS = {
    'leg_l':    {'at': (809, 700), 'off': (-27, -45), 'parent': 'root', 'z': 0, 'pivot': (782, 470)},
    'leg_r':    {'at': (951, 700), 'off': (-27, -45), 'parent': 'root', 'z': 0, 'pivot': (924, 470)},
    'torso':    {'at': (853, 200), 'off': (0, 0), 'parent': 'root', 'z': 1, 'pivot': (853, 420)},
    'cape':     {'at': (543, 500), 'off': (310, 0), 'scale': 0.8, 'parent': 'torso', 'z': 4, 'pivot': (853, 70)},
    'arm_l_up': {'at': (1064, 250), 'off': (-329, -62), 'parent': 'torso', 'z': 5, 'pivot': (735, 118)},
    'arm_l_lo': {'at': (1051, 450), 'off': (-326, -75), 'parent': 'arm_l_up', 'z': 5, 'pivot': (725, 258)},
    'sword':    {'at': (1420, 700), 'off': (-405, 10), 'parent': 'torso', 'z': 5, 'pivot': (970, 120)},
    'pauld_l':  {'at': (1054, 90), 'off': (-290, -6), 'parent': 'torso', 'z': 6, 'pivot': (764, 100)},
    'pauld_r':  {'at': (1240, 90), 'off': (-298, -6), 'parent': 'torso', 'z': 6, 'pivot': (942, 100)},
    'hair':     {'at': (138, 150), 'off': (715, -170), 'parent': 'torso', 'z': 7, 'pivot': (853, 40)},
    'braid':    {'at': (296, 400), 'off': (557, -88), 'parent': 'hair', 'z': 8, 'pivot': (853, -36)},
}


def components(im):
    """알파로 이어진 덩어리 라벨 (9px 넓혀서 이음)"""
    al = im.getchannel('A').point(lambda v: 255 if v > 8 else 0).filter(ImageFilter.MaxFilter(9))
    A = np.asarray(al) > 0
    h, w = A.shape
    lab = np.zeros((h, w), np.int32)
    n = 0
    for y in range(0, h, 3):
        for x in range(0, w, 3):
            if A[y, x] and lab[y, x] == 0:
                n += 1
                q = deque([(y, x)])
                lab[y, x] = n
                while q:
                    cy, cx = q.popleft()
                    for ny, nx in ((cy + 1, cx), (cy - 1, cx), (cy, cx + 1), (cy, cx - 1)):
                        if 0 <= ny < h and 0 <= nx < w and A[ny, nx] and lab[ny, nx] == 0:
                            lab[ny, nx] = n
                            q.append((ny, nx))
    return lab


def main():
    sheet = vs_import.keyed('04_seraphina_parts', True)
    lab = components(sheet)
    arr = np.asarray(sheet)
    cut = {}
    for name, p in PARTS.items():
        k = lab[p['at'][1], p['at'][0]]
        assert k > 0, name
        mask = lab == k
        ys, xs = np.nonzero(mask)
        x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
        a = arr[y0:y1, x0:x1].copy()
        a[..., 3] = np.where(mask[y0:y1, x0:x1], a[..., 3], 0)
        img = Image.fromarray(a, 'RGBA')
        sc = p.get('scale', 1.0)
        w, h = img.size
        # 배율이 있으면 위 가운데를 기준으로 줄인다
        pos = (x0 + p['off'][0] + (w - w * sc) / 2.0, y0 + p['off'][1])
        cut[name] = (img, pos, sc)
    # 전체 높이: 머리 위 ~ 발끝 → 1100
    top = min(c[1][1] for c in cut.values())
    bottom = max(c[1][1] + c[0].size[1] * c[2] for c in cut.values())
    s = FRAME[1] / (bottom - top)

    def tf(x, y):
        return [round((x - TORSO_SPINE) * s + SPINE_X, 1), round((y - top) * s, 1)]

    os.makedirs(OUT, exist_ok=True)
    rig = {'frame': list(FRAME), 'source': 'art/raw/vs/04_seraphina_parts.webp', 'scale': round(s, 4), 'parts': []}
    for name, p in PARTS.items():
        img, pos, sc = cut[name]
        k = s * sc
        img = img.resize((max(1, round(img.size[0] * k)), max(1, round(img.size[1] * k))), Image.LANCZOS)
        f = 'sera_%s.png' % name
        img.save(os.path.join(OUT, f), optimize=True)
        rig['parts'].append({'name': name, 'file': 'anim/' + f, 'parent': p['parent'], 'z': p['z'],
                             'pos': tf(*pos), 'size': list(img.size), 'pivot': tf(*p['pivot'])})
    with open(os.path.join(ROOT, 'game', 'data', 'anim_rig.gd'), 'w') as fp:
        fp.write('## 자동 생성 — tools/anim_parts.py (움직임 시험 C ?anim=c: 세라피나 부위 배치). 손으로 고치지 말고 도구를 다시 돌린다.\n')
        fp.write('## 좌표는 뒷모습 spr_hero_back.png 틀(507×1100) 기준: pos = 그림 왼쪽 위, pivot = 관절(부모 기준 회전 중심)\n')
        fp.write('class_name AnimRig\nextends RefCounted\n\nconst SERA := ')
        fp.write(json.dumps(rig, ensure_ascii=False, indent='\t').replace('\n', '\n'))
        fp.write('\n')
    print('scale %.4f, parts %d -> %s' % (s, len(rig['parts']), OUT))


if __name__ == '__main__':
    main()
