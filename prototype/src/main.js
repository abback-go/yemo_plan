/* 저주 매입합니다 — 시작점. 아티팩트 뷰어의 갱신(hot reload) 시 진행 상태를 넘겨받는다. */
(function () {
  'use strict';
  const W = globalThis.W;
  let started = false;
  function start(data) {
    if (started) return;
    started = true;
    W.ui.boot(data && data.save);
  }
  try {
    const hot = window.claude && window.claude.hot;
    if (hot && typeof hot.snapshot === 'function') {
      hot.snapshot(() => ({ save: W.game.state ? W.rules.serialize(W.game.state) : null }));
    }
    if (hot && typeof hot.ready === 'function') hot.ready(start);
    else start((hot && hot.data) || {});
  } catch (e) {
    start({});
  }
})();
