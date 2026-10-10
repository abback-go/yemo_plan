// 예모 웹 서비스 워커 — tools/web_sw_patch.py가 Godot 기본 워커 자리에 넣는다 (파일 목록 자리는 Godot 워커의 목록으로 채움).
// 온라인이면 게임 파일을 언제나 서버에 물어보고(바뀐 게 없으면 304라 금방) 받은 것을 저장, 오프라인일 때만 저장본을 쓴다.
// 그래서 배포하면 다음 접속에 바로 새 버전이 뜨고, 한 번 연 뒤에는 인터넷 없이도 열린다.

/** @type {string[]} */
const FILES = __FILES__;
const CACHE = 'yemo-game';
const OFFLINE_PAGE = 'index.offline.html';
const BASE = new URL('./', self.location.href).href;

// 새 워커는 기다리지 않고 바로 교체한다
self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', (event) => {
	event.waitUntil((async () => {
		// 이전 워커(Godot 기본)의 저장본은 지운다
		const keys = await caches.keys();
		const hadOld = keys.some((k) => k !== CACHE);
		await Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)));
		// 열린 페이지를 바로 넘겨받는다 (페이지가 한 번 새로고침해 새 버전을 연다)
		await self.clients.claim();
		// 처음 설치(이전 워커 없음)일 때만 게임 전체를 미리 저장 — 첫 접속 뒤 바로 오프라인으로 열 수 있게.
		// 이전 워커에서 넘어올 때는 미리 받지 않는다: 새로고침된 페이지가 받으면서 저장하므로 두 번 받지 않게.
		const cache = await caches.open(CACHE);
		const have = await Promise.all(FILES.map((f) => cache.match(f)));
		if (!hadOld && have.some((r) => r === undefined)) {
			await cache.addAll(FILES).catch(() => {});
		}
	})());
});

/** Godot 기본 워커와 같게 교차 출처 격리 헤더를 붙인다 */
function isolate(response) {
	if (response.headers.get('Cross-Origin-Embedder-Policy') === 'require-corp'
		&& response.headers.get('Cross-Origin-Opener-Policy') === 'same-origin') {
		return response;
	}
	const headers = new Headers(response.headers);
	headers.set('Cross-Origin-Embedder-Policy', 'require-corp');
	headers.set('Cross-Origin-Opener-Policy', 'same-origin');
	return new Response(response.body, { status: response.status, statusText: response.statusText, headers });
}

/** 저장본과 같은 파일이면(ETag·수정 시각) 다시 쓰지 않는다 — 60MB를 매번 디스크에 쓰지 않게 */
function same(a, b) {
	for (const h of ['ETag', 'Last-Modified', 'Content-Length']) {
		if ((a.headers.get(h) || '') !== (b.headers.get(h) || '')) {
			return false;
		}
	}
	return true;
}

self.addEventListener('fetch', (event) => {
	const req = event.request;
	if (req.method !== 'GET' || !req.url.startsWith(BASE)) {
		return;
	}
	const isNavigate = req.mode === 'navigate';
	const name = new URL(req.url).pathname.slice(new URL(BASE).pathname.length);
	// 페이지는 주소 뒤 ?eska 같은 것이 달라도 같은 index.html로 저장한다
	const key = isNavigate ? 'index.html' : name;
	if (!isNavigate && !FILES.includes(name)) {
		event.respondWith(fetch(req).then(isolate));
		return;
	}
	event.respondWith((async () => {
		const cache = await caches.open(CACHE);
		try {
			const res = await fetch(isNavigate ? req.url : req, { cache: 'no-cache' });
			if (res.ok) {
				// 저장은 뒤에서 (게임이 받는 진행 표시가 멈추지 않게)
				const copy = res.clone();
				event.waitUntil((async () => {
					const old = await cache.match(key);
					if (!old || !same(old, copy)) {
						await cache.put(key, copy);
					}
				})());
			}
			return isolate(res);
		} catch (err) {
			// 오프라인: 저장본
			const hit = await cache.match(key);
			if (hit) {
				return isolate(hit);
			}
			if (isNavigate) {
				const offline = await cache.match(OFFLINE_PAGE);
				if (offline) {
					return offline;
				}
			}
			throw err;
		}
	})());
});
