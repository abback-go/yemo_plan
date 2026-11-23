#!/bin/bash
# 웹 내보내기 + 서비스 워커 패치(CI 와 같은 방식). 결과: verify_4/web
S=/tmp/claude-0/-home-user-yemo-plan/c9580547-3e2b-5444-b985-f8d79472150f/scratchpad
V=$S/verify_4
GD=$S/godot/godot
WT=/home/user/yemo_plan/.claude/worktrees/agent-abf0228873c2e506a
rm -rf $V/web && mkdir -p $V/web
cd $WT/game || exit 1
timeout 300 $GD --headless --path . --import > $V/import_web.log 2>&1
grep -E "SCRIPT ERROR|Parse Error" -A1 $V/import_web.log | head -20
timeout 600 $GD --headless --path . --export-release "Web" $V/web/index.html > $V/export.log 2>&1
grep -iE "error" $V/export.log | head
cd $WT && python3 tools/web_sw_patch.py $V/web | tail -3
ls -la $V/web/index.pck | awk '{print "pck", $5}'
