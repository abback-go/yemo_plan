"""웹 빌드 뒤처리: 서비스 워커가 새 버전을 바로 쓰게 고친다 (.github/workflows/web-build.yml이 내보내기 직후 부른다).

Godot 기본 서비스 워커의 문제:
1. 설치할 때 index.wasm·index.pck를 저장하지 않는다 → 첫 접속 뒤 오프라인으로 열면 게임이 안 뜬다.
2. 저장해 둔 파일을 먼저 꺼내 쓰는데, 새 버전 워커는 열린 탭·앱이 전부 닫힐 때까지 기다린다
   → 배포해도, 브라우저 캐시를 비워도 이전 버전이 계속 뜬다.

고치는 것:
- 설치할 때 전부 저장 + 브라우저 HTTP 캐시를 건너뛰고 서버에서 새로 받는다 (cache: 'reload')
- 설치가 끝나면 기다리지 않고 바로 교체(skipWaiting) + 열린 페이지를 바로 넘겨받음(clients.claim)
- 페이지: 이미 워커가 있던 상태에서 워커가 바뀌면 한 번 새로고침 → 새 버전으로 열림

하나라도 바뀌지 않으면(엔진이 바뀌어 원문이 달라지면) 실패해서 빌드를 멈춘다.
사용: python3 tools/web_sw_patch.py build/web
"""
import sys
from pathlib import Path

INSTALL_OLD = "cache.addAll(CACHED_FILES)"
INSTALL_NEW = "cache.addAll(FULL_CACHE.map((f) => new Request(f, { cache: 'reload' })))"

SW_TAIL = """
// ── 배포 뒤처리(tools/web_sw_patch.py): 새 버전 워커는 기다리지 않고 바로 교체하고 열린 페이지를 넘겨받는다
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()));
"""

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


def main() -> None:
	web = Path(sys.argv[1] if len(sys.argv) > 1 else "build/web")
	sw = web / "index.service.worker.js"
	page = web / "index.html"
	s = sw.read_text(encoding="utf-8")
	if s.count(INSTALL_OLD) != 1:
		sys.exit(f"web_sw_patch: '{INSTALL_OLD}' not found exactly once in {sw}")
	s = s.replace(INSTALL_OLD, INSTALL_NEW) + SW_TAIL
	sw.write_text(s, encoding="utf-8")
	h = page.read_text(encoding="utf-8")
	if h.count(PAGE_MARK) != 1:
		sys.exit(f"web_sw_patch: '{PAGE_MARK}' not found exactly once in {page}")
	page.write_text(h.replace(PAGE_MARK, PAGE_SCRIPT), encoding="utf-8")
	print(f"web_sw_patch: patched {sw.name}, {page.name}")


if __name__ == "__main__":
	main()
