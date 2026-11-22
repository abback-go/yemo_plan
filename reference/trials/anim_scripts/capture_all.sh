#!/bin/bash
# 그 전 기본(base = ?anim=off) / A′ 비교 자료(C 는 2026-11-22 지움): 영상 녹화 + 구간 프레임 (결과: scratchpad/vs_shots/anim_*)
V=/tmp/claude-0/-home-user-yemo-plan/c9580547-3e2b-5444-b985-f8d79472150f/scratchpad/verify_4
OUT=/tmp/claude-0/-home-user-yemo-plan/c9580547-3e2b-5444-b985-f8d79472150f/scratchpad/vs_shots
cd $V || exit 1
for m in base a; do
  for v in "" nohand; do
    d=$OUT/anim_$m${v:+_$v}
    rm -rf $d
    node anim_shots.js http://127.0.0.1:8140/ $OUT $m $v 2>&1 | tail -3
    python3 frames.py $d 10 5 2>&1 | tail -3
  done
done
echo CAPTURE_DONE
