"""웹 빌드 뒤처리: Godot 기본 서비스 워커를 '온라인이면 언제나 새로, 오프라인일 때만 저장본' 워커로 바꾼다.
(.github/workflows/web-build.yml이 내보내기 직후 부른다)

Godot 기본 서비스 워커의 문제 (Playwright로 재현):
1. 설치할 때 index.wasm·index.pck를 저장하지 않는다 → 첫 접속 뒤 오프라인으로 열면 게임이 안 뜬다.
2. 저장본을 먼저 쓰고, 새 버전 워커는 탭이 다 닫힐 때까지 기다린다 → 배포해도, 캐시를 비워도 이전 버전이 계속 뜬다.
3. 새 워커로 바꾸려면 설치 때 게임 전체(약 60MB)를 다 받아야 해서, 휴대폰 데이터로는 한참 동안 이전 버전이 뜬다.

바꾼 워커 (tools/web_sw.js — 파일 목록만 Godot 워커에서 가져와 채운다):
- 온라인: 게임 파일은 언제나 서버에 바뀌었는지 물어보고 받는다(바뀐 게 없으면 304라 금방 끝남). 받은 것은 저장해 둔다.
- 오프라인: 저장해 둔 것을 쓴다. 처음 설치 때는 게임 전체를 미리 저장해 두어 첫 접속 뒤에도 오프라인으로 열린다.
- 새 워커는 기다리지 않고 바로 교체(skipWaiting) + 열린 페이지를 넘겨받음(clients.claim), 이전 워커의 저장본은 지운다.
- 페이지: 열 때마다 워커 갱신을 확인하고(브라우저는 새로고침만으로는 바로 확인하지 않는다),
  이미 워커가 있던 상태에서 워커가 바뀌면 한 번 새로고침한다 → 이전 워커가 붙어 있던 기기도 첫 접속에 새 버전으로 넘어간다.

원문에서 파일 목록·</body>를 못 찾으면 실패해서 빌드를 멈춘다(엔진 버전을 올렸을 때 확인용).
사용: python3 tools/web_sw_patch.py build/web
"""
import json
import re
import sys
from pathlib import Path

PAGE_MARK = "</body>"
PAGE_SCRIPT = """<script>
// 배포 뒤처리(tools/web_sw_patch.py): 열 때마다 새 버전 워커가 있는지 직접 확인하고
// (브라우저는 새로고침만으로는 바로 확인하지 않는다), 이미 워커가 있던 상태에서 워커가 바뀌면 한 번 새로고침해 새 버전을 연다
if ('serviceWorker' in navigator) {
	if (navigator.serviceWorker.controller) {
		let reloaded = false;
		navigator.serviceWorker.addEventListener('controllerchange', () => {
			if (!reloaded) {
				reloaded = true;
				window.location.reload();
			}
		});
	}
	navigator.serviceWorker.getRegistration().then((r) => r && r.update()).catch(() => {});
}
</script>
</body>"""


def _files(sw_text: str, name: str) -> list:
	m = re.search(r"const " + name + r" = (\[[^\]]*\]);", sw_text)
	if not m:
		sys.exit(f"web_sw_patch: '{name}' list not found in Godot service worker")
	return json.loads(m.group(1))


def main() -> None:
	web = Path(sys.argv[1] if len(sys.argv) > 1 else "build/web")
	sw = web / "index.service.worker.js"
	page = web / "index.html"
	godot_sw = sw.read_text(encoding="utf-8")
	files = _files(godot_sw, "CACHED_FILES") + _files(godot_sw, "CACHEABLE_FILES")
	for need in ("index.html", "index.wasm", "index.pck", "index.offline.html"):
		if need not in files:
			sys.exit(f"web_sw_patch: '{need}' missing from Godot cache lists")
	template = (Path(__file__).parent / "web_sw.js").read_text(encoding="utf-8")
	if template.count("__FILES__") != 1:
		sys.exit("web_sw_patch: __FILES__ placeholder missing in tools/web_sw.js")
	sw.write_text(template.replace("__FILES__", json.dumps(files)), encoding="utf-8")
	h = page.read_text(encoding="utf-8")
	if h.count(PAGE_MARK) != 1:
		sys.exit(f"web_sw_patch: '{PAGE_MARK}' not found exactly once in {page}")
	page.write_text(h.replace(PAGE_MARK, PAGE_SCRIPT), encoding="utf-8")
	print(f"web_sw_patch: replaced {sw.name} ({len(files)} files), patched {page.name}")


if __name__ == "__main__":
	main()
