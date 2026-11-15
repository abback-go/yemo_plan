// 예전에 이 주소(루트)에 있던 에스카 웹앱의 오프라인 캐시(서비스 워커)를 해제한다.
// 에스카는 /eska/ 로 옮겨졌고, 루트는 '죽음을 보는 마녀'가 쓴다.
self.addEventListener('install', function () { self.skipWaiting(); });
self.addEventListener('activate', function (e) {
  e.waitUntil(self.registration.unregister().then(function () {
    return self.clients.matchAll({ type: 'window' });
  }).then(function (cs) { cs.forEach(function (c) { c.navigate(c.url); }); }));
});
