#!/usr/bin/env python3
"""스크린샷 폴더 두 개를 같은 파일 이름끼리 비교한다 (리팩터 전후 그림이 같은지).

    python3 tools/test/imgdiff.py <전 폴더> <후 폴더> [--tol 0]

파일마다 다른 픽셀 수와 최대 채널 차이를 출력한다. tol(채널 차이 허용치)을 넘는 픽셀이
하나라도 있으면 DIFF, 아니면 SAME. 한쪽에만 있는 파일은 ONLY로 표시한다.
DIFF가 있으면 <후 폴더>/_diff_<이름>.png 에 다른 곳을 빨갛게 칠한 그림을 남긴다.
"""
import sys
from pathlib import Path

from PIL import Image, ImageChops


def main() -> int:
    args = sys.argv[1:]
    tol = 0
    if "--tol" in args:
        i = args.index("--tol")
        tol = int(args[i + 1])
        del args[i:i + 2]
    a_dir, b_dir = Path(args[0]), Path(args[1])
    names = sorted({p.name for p in a_dir.glob("*.png")} | {p.name for p in b_dir.glob("*.png")})
    names = [n for n in names if not n.startswith("_diff_")]
    bad = 0
    for n in names:
        a, b = a_dir / n, b_dir / n
        if not a.exists() or not b.exists():
            print(f"ONLY {'before' if a.exists() else 'after'} {n}")
            bad += 1
            continue
        ia, ib = Image.open(a).convert("RGB"), Image.open(b).convert("RGB")
        if ia.size != ib.size:
            print(f"SIZE {n} {ia.size} {ib.size}")
            bad += 1
            continue
        d = ImageChops.difference(ia, ib)
        px = list(d.get_flattened_data() if hasattr(d, "get_flattened_data") else d.getdata())
        over = [i for i, p in enumerate(px) if max(p) > tol]
        mx = max((max(p) for p in px), default=0)
        if over:
            bad += 1
            print(f"DIFF {n} pixels={len(over)} max={mx}")
            mark = ib.copy()
            w = ib.size[0]
            for i in over:
                mark.putpixel((i % w, i // w), (255, 0, 0))
            mark.save(b_dir / f"_diff_{n}")
        else:
            print(f"SAME {n} max={mx}")
    print(f"TOTAL {len(names)} files, {bad} different")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
