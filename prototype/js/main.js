/*
 * main.js — 시작: 화면 맞춤(1920×1080 비율 유지), 그림 확인, 그리기 루프
 * 주소 뒤 옵션: ?seed=숫자 (난수 고정) · ?speed=2 (연출 속도) · ?scene=giant (바로 시작: camp|normal|giant|cutscene|ending)
 */
(function (root) {
  'use strict';
  var Game = root.Game = root.Game || {};

  // 1920×1080 비율 유지 확대·축소. 휴대폰 가로 화면에서는 노치·둥근 모서리(안전 영역)를 피한다
  function safeArea() {
    var p = document.getElementById('safeProbe');
    if (!p) return { l: 0, r: 0, t: 0, b: 0 };
    var cs = getComputedStyle(p);
    return { l: parseFloat(cs.paddingLeft) || 0, r: parseFloat(cs.paddingRight) || 0, t: parseFloat(cs.paddingTop) || 0, b: parseFloat(cs.paddingBottom) || 0 };
  }
  function fit() {
    var st = document.getElementById('stage'), sa = safeArea();
    var W = window.innerWidth - sa.l - sa.r, H = window.innerHeight - sa.t - sa.b;
    var s = Math.min(W / 1920, H / 1080);
    var x = sa.l + (W - 1920 * s) / 2, y = sa.t + (H - 1080 * s) / 2;
    st.style.transform = 'translate(' + x + 'px,' + y + 'px) scale(' + s + ')';
    Game.stageScale = s;
    // 손가락으로 누르기 충분한 크기(실제 화면 44px)를 무대 좌표로 — 버튼의 누르는 영역을 이만큼 넓힌다(style.css .tt)
    st.style.setProperty('--t44', Math.ceil(44 / s) + 'px');
    document.body.classList.toggle('portrait', window.innerHeight > window.innerWidth);
    // 터치 기기: 캔버스 해상도를 실제로 보이는 크기에 맞춰 낮춘다(기기 픽셀 비율 상한 2)
    var FX = Game.FX;
    FX.canvasK = FX.low ? Math.max(0.5, Math.min(1, s * Math.min(window.devicePixelRatio || 1, 2))) : 1;
    ['threadCanvas', 'fxCanvas'].forEach(function (id) { FX.prepCanvas(document.getElementById(id)); });
    if (Game.Blood) Game.Blood.rescale();
  }

  function params() {
    var o = {};
    (location.search || '').replace(/^\?/, '').split('&').forEach(function (kv) {
      if (!kv) return;
      var p = kv.split('=');
      o[decodeURIComponent(p[0])] = decodeURIComponent(p[1] || '');
    });
    return o;
  }

  var last = 0;
  function frame(now) {
    var dt = last ? Math.min(100, now - last) : 16;
    last = now;
    var tc = Game.FX.ctx(document.getElementById('threadCanvas'));
    tc.clearRect(0, 0, 1920, 1080);
    Game.View.drawThreads(tc, now);
    Game.FX.updateParticles(dt);
    var fc = Game.FX.ctx(document.getElementById('fxCanvas'));
    fc.clearRect(0, 0, 1920, 1080);
    Game.FX.drawParticles(fc);
    Game.FX.drawOverlays(fc, now);
    Game.View.drawBroken(fc, now);
    Game.View.drawRaisedThread(fc, now);
    Game.Input.drawOverlay(fc, now);
    Game.Blood.render(now);
    requestAnimationFrame(frame);
  }

  function boot() {
    document.body.classList.toggle('touch', !!Game.FX.touch);
    document.body.classList.toggle('reduced', !!Game.FX.reduced);
    fit();
    window.addEventListener('resize', fit);
    window.addEventListener('orientationchange', function () { setTimeout(fit, 120); });
    // 휴대폰: 두 손가락 확대(iOS 제스처)·길게 누르기 메뉴·끌어서 새로고침을 막는다
    document.addEventListener('gesturestart', function (e) { e.preventDefault(); });
    document.addEventListener('touchmove', function (e) {
      if (e.target && e.target.closest && e.target.closest('#debugPanel')) return;   // 디버그 패널은 스크롤
      if (e.cancelable) e.preventDefault();
    }, { passive: false });
    window.addEventListener('contextmenu', function (e) { e.preventDefault(); });
    document.addEventListener('dragstart', function (e) { e.preventDefault(); });
    var q = params();
    if (q.speed) Game.FX.speed = Math.max(0.1, +q.speed || 1);
    if (q.seed) Game.Ctl.seed = (+q.seed) >>> 0;
    document.getElementById('fade').style.opacity = 1;
    var dl = Game.DATA.layout.dialog, dbox = document.getElementById('dialog');
    dbox.style.left = dl.x + 'px'; dbox.style.top = dl.y + 'px'; dbox.style.width = dl.w + 'px'; dbox.style.minHeight = dl.h + 'px';
    Game.Assets.load().then(function () {
      Game.Input.init();
      Game.debug.init();
      requestAnimationFrame(frame);
      Game.ready = true;
      if (q.scene) Game.debug.jump(q.scene);
      else Game.Scenes.title();
    });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();
})(window);
