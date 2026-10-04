#!/usr/bin/env bash
# 회귀 시험: 시나리오 여러 개를 병렬로 돌려 요약 한 파일로 모은다.
#   tools/test/regress.sh <Godot 실행 파일> <출력 폴더> [시나리오 이름 패턴...]
# 예) tools/test/regress.sh $G /tmp/reg_before            # 전부
#     tools/test/regress.sh $G /tmp/reg_after 'ch2_*' sys_classes
# 출력: <출력 폴더>/<시나리오>.log (전체 로그), <출력 폴더>/summary.txt (시나리오마다
#   종료 코드 · SCRIPT ERROR 수 · 엔진 ERROR 수 · STATUS/WORLD 줄)
# 리팩터 전후 비교: diff <(grep -v '^#' 전/summary.txt) <(grep -v '^#' 후/summary.txt)
# 병렬 수는 JOBS 환경 변수(기본 3). 시나리오당 제한 시간은 TIMEOUT(초, 기본 900).
set -u
G="$1"; OUT="$2"; shift 2
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SC="$ROOT/tools/test/scenarios"
JOBS="${JOBS:-3}"; TIMEOUT="${TIMEOUT:-900}"
mkdir -p "$OUT"
pats=("$@"); [ ${#pats[@]} -eq 0 ] && pats=('*')
list=()
for p in "${pats[@]}"; do for f in "$SC"/$p.json; do [ -f "$f" ] && list+=("$(basename "$f" .json)"); done; done
mapfile -t list < <(printf '%s\n' "${list[@]}" | sort -u)

run_one() {
	local name="$1"
	local shots="$OUT/shots_$name"; mkdir -p "$shots"
	( cd "$ROOT/game" && timeout "$TIMEOUT" xvfb-run -a -s "-screen 0 1280x720x24" "$G" --rendering-driver opengl3 \
		--fixed-fps 60 --resolution 640x360 --script ../tools/test/runner.gd -- "$SC/$name.json" "$shots" ) \
		> "$OUT/$name.log" 2>&1
	echo "$?" > "$OUT/$name.rc"
}
export -f run_one; export G OUT ROOT SC TIMEOUT
printf '%s\n' "${list[@]}" | xargs -P "$JOBS" -I{} bash -c 'run_one {}'

{
	echo "# regress $(date -Iseconds) $(cd "$ROOT" && git rev-parse --short HEAD 2>/dev/null)"
	for n in "${list[@]}"; do
		log="$OUT/$n.log"
		se=$(grep -c 'SCRIPT ERROR' "$log")
		# 오디오 장치 없음(가상 화면) 오류는 환경 탓이라 뺀다
		ee=$(grep '^ERROR' "$log" | grep -vc 'audio\|Audio\|ALSA\|PulseAudio')
		echo "== $n rc=$(cat "$OUT/$n.rc") script_err=$se engine_err=$ee"
		grep -E '^(STATUS|WORLD) ' "$log" | sed -E 's/ f=[0-9]+//'
	done
} > "$OUT/summary.txt"
grep '^==' "$OUT/summary.txt"
