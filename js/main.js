/*
 * main.js — 시작: 화면 맞춤(1920×1080 비율 유지), 그림 확인, 그리기 루프
 * 주소 뒤 옵션: ?seed=숫자 (난수 고정) · ?speed=2 (연출 속도) · ?scene=giant (바로 시작: camp|normal|giant|cutscene|ending)
 */
(function (root) {
  'use strict';
  var Game = root.Game = root.Game || {};

  function fit() {
    var st = document.getElementById('stage');
    var s = Math.min(window.innerWidth / 1920, window.innerHeight / 1080);
    var x = (window.innerWidth - 1920 * s) / 2, y = (window.innerHeight - 1080 * s) / 2;
    st.style.transform = 'translate(' + x + 'px,' + y + 'px) scale(' + s + ')';
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
    var tc = document.getElementById('threadCanvas').getContext('2d');
    tc.clearRect(0, 0, 1920, 1080);
    Game.View.drawThreads(tc, now);
    Game.FX.updateParticles(dt);
    var fc = document.getElementById('fxCanvas').getContext('2d');
    fc.clearRect(0, 0, 1920, 1080);
    Game.FX.drawParticles(fc);
    Game.FX.drawOverlays(fc, now);
    Game.View.drawBroken(fc, now);
    Game.Input.drawOverlay(fc, now);
    Game.Blood.render(now);
    requestAnimationFrame(frame);
  }

  function boot() {
    fit();
    window.addEventListener('resize', fit);
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
