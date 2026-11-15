/*
 * cutin.js — 대표 카드를 낼 때의 컷인.
 * 화면을 가로지르는 기울어진 띠(검붉은 바탕 + 코드로 그린 속도선·빛 궤적) 안으로 캐릭터가 미끄러져 들어왔다 빠진다.
 * 클릭/탭하면 건너뛴다. 설정은 data.js cutin.
 */
(function (root) {
  'use strict';
  var Game = root.Game = root.Game || {};
  var CI = Game.Cutin = { log: [], active: null };

  function D() { return Game.DATA; }
  function FX() { return Game.FX; }

  CI.has = function (cardId) {
    var c = D().cutin && D().cutin.cards[cardId];
    return !!(c && Game.Assets.ok(c.img));
  };

  // 띠 모양(기울어진 사각형). open: 0~1 (0이면 가운데 가는 선)
  function bandPoly(open) {
    var b = D().cutin.band, mid = b.y + b.h / 2, h = b.h * open / 2, s = b.slant / 2;
    return 'polygon(0px ' + (mid - h + s) + 'px, 1920px ' + (mid - h - s) + 'px, 1920px ' + (mid + h - s) + 'px, 0px ' + (mid + h + s) + 'px)';
  }

  // 반환: 컷인이 끝나면(또는 건너뛰면) 끝나는 Promise
  CI.play = function (cardId) {
    if (!CI.has(cardId)) return Promise.resolve();
    if (CI.active) CI.active.finish();
    var cfg = D().cutin, c = cfg.cards[cardId], heavy = !!c.heavy;
    var dur = FX().ms(heavy ? cfg.heavyDuration : cfg.duration);
    var reduced = FX().reduced;
    CI.log.push(cardId);

    var layer = document.getElementById('cutinLayer');
    var root = document.createElement('div');
    root.className = 'cutin' + (heavy ? ' heavy' : '');
    root.setAttribute('data-cutin', cardId);
    var band = document.createElement('div'); band.className = 'ci-band';
    var cv = document.createElement('canvas'); cv.width = 1920; cv.height = 1080; cv.className = 'ci-lines';
    var img = Game.Assets.el(c.img, null, null, { cls: 'ci-char' });
    var sz = Game.Assets.size(c.img), ih = cfg.imgH, iw = sz ? ih * sz.w / sz.h : ih * 16 / 9;
    img.style.width = iw + 'px'; img.style.height = ih + 'px';
    var b = cfg.band, cy = b.y + b.h / 2;
    var baseX = c.at - c.focus[0] * iw, baseY = cy - c.focus[1] * ih;
    img.style.left = baseX + 'px'; img.style.top = baseY + 'px';
    var edge = document.createElement('div'); edge.className = 'ci-edge';
    band.appendChild(cv); band.appendChild(img); band.appendChild(edge);
    root.appendChild(band);
    layer.appendChild(root);
    layer.classList.add('on');

    FX().prepCanvas(cv);
    var ctx = FX().ctx(cv), t0 = performance.now(), done = false, raf = 0;
    var lines = [];
    for (var i = 0; i < Math.round((heavy ? 70 : 54) * (FX().low ? 0.6 : 1)); i++) {
      lines.push({ y: b.y - 40 + Math.random() * (b.h + 80), x: Math.random() * 2400, len: 120 + Math.random() * 520, w: 1 + Math.random() * 3.5, sp: 2600 + Math.random() * 3200, a: 0.15 + Math.random() * 0.5 });
    }
    // 속도선 + 빛 궤적 (띠 안에서만 보인다: 띠에 clip-path)
    function draw(now) {
      if (done) return;
      var k = (now - t0) / dur;
      ctx.clearRect(0, 0, 1920, 1080);
      var dir = c.from || 1;
      lines.forEach(function (l) {
        var x = ((l.x - dir * l.sp * (now - t0) / 1000) % 2400 + 2400) % 2400 - 240;
        ctx.globalAlpha = l.a;
        ctx.fillStyle = heavy ? '#ff3a4a' : '#ffffff';
        ctx.fillRect(x, l.y, l.len, l.w);
      });
      // 빛 궤적: 캐릭터를 따라 지나가는 굵은 빛줄기
      var sweep = Math.min(1, k * 2.2);
      var gx = dir > 0 ? 1920 - sweep * 2300 : -380 + sweep * 2300;
      var g = ctx.createLinearGradient(gx - 380, 0, gx + 380, 0);
      g.addColorStop(0, 'rgba(255,255,255,0)'); g.addColorStop(0.5, c.color || '#fff'); g.addColorStop(1, 'rgba(255,255,255,0)');
      ctx.globalAlpha = 0.55 * (1 - Math.max(0, k - 0.6) / 0.4);
      ctx.fillStyle = g;
      ctx.fillRect(gx - 380, cy - 6, 760, 12);
      ctx.globalAlpha = 0.25 * (1 - k);
      ctx.fillRect(gx - 380, cy - 40, 760, 80);
      ctx.globalAlpha = 1;
      raf = requestAnimationFrame(draw);
    }
    raf = requestAnimationFrame(draw);

    // 타임라인(비율): 띠가 열림 → 캐릭터 들어옴 → 머묾(살짝 흐름) → 빠짐 + 띠 닫힘
    var dir = c.from || 1, inX = dir * 760, outX = -dir * 900;
    var tIn = heavy ? 0.22 : 0.24, tHold = heavy ? 0.78 : 0.74;
    var anims = [];
    anims.push(band.animate([
      { clipPath: bandPoly(0) }, { clipPath: bandPoly(1), offset: 0.1 }, { clipPath: bandPoly(1), offset: 0.86 }, { clipPath: bandPoly(0) }
    ], { duration: dur, easing: 'linear', fill: 'forwards' }));
    var drift = -dir * (heavy ? 30 : 50);
    anims.push(img.animate(reduced ? [
      { opacity: 0 }, { opacity: 1, offset: 0.2 }, { opacity: 1, offset: 0.8 }, { opacity: 0 }
    ] : [
      { transform: 'translateX(' + inX + 'px)', opacity: 0, easing: 'cubic-bezier(.15,.8,.3,1)' },
      { transform: 'translateX(0px)', opacity: 1, offset: tIn, easing: 'linear' },
      { transform: 'translateX(' + drift + 'px)', opacity: 1, offset: tHold, easing: 'cubic-bezier(.6,0,.9,.4)' },
      { transform: 'translateX(' + outX + 'px)', opacity: 0 }
    ], { duration: dur, fill: 'forwards' }));
    if (heavy) {
      // 무거운 컷인: 들어오는 순간 핏빛 섬광과 흔들림
      setTimeout(function () { if (!done) { FX().flash('#5a0010', 380, 0.55); FX().shake(14, 420); } }, dur * tIn * 0.8);
    }

    return new Promise(function (resolve) {
      var timer = setTimeout(finish, dur);
      function finish() {
        if (done) return;
        done = true;
        clearTimeout(timer);
        cancelAnimationFrame(raf);
        anims.forEach(function (a) { a.cancel(); });
        root.remove();
        if (CI.active === me) CI.active = null;
        if (!layer.querySelector('.cutin')) layer.classList.remove('on');
        resolve();
      }
      var me = { id: cardId, finish: finish };
      CI.active = me;
      root.addEventListener('pointerdown', function (e) { e.stopPropagation(); finish(); });
    });
  };
})(window);
