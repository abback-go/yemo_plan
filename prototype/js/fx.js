/*
 * fx.js — 연출 도구: 대기, 애니메이션, 화면 흔들림, 피해 숫자, 섬광, 입자(먼지·파편·불꽃·재)
 * FX.speed 를 올리면 모든 연출이 빨라진다(자동 테스트용).
 */
(function (root) {
  'use strict';
  var Game = root.Game = root.Game || {};
  var FX = Game.FX = { speed: 1, particles: [], overlays: [] };

  FX.ms = function (ms) { return Math.max(0, ms / FX.speed); };
  FX.wait = function (ms) { return new Promise(function (r) { setTimeout(r, FX.ms(ms)); }); };
  FX.$ = function (id) { return document.getElementById(id); };

  // Web Animations API (속도 반영)
  FX.anim = function (el, frames, opts) {
    if (!el || !el.animate) return Promise.resolve();
    var o = {};
    for (var k in (opts || {})) o[k] = opts[k];
    o.duration = FX.ms(o.duration || 300);
    if (o.delay) o.delay = FX.ms(o.delay);
    var a = el.animate(frames, o);
    return new Promise(function (res) { a.onfinish = res; a.oncancel = res; });
  };

  // 화면 흔들림
  FX.shake = function (power, dur) {
    power = power || 10; dur = dur || 380;
    var w = FX.$('world'), frames = [], n = 10;
    for (var i = 0; i < n; i++) {
      var k = 1 - i / n;
      frames.push({ transform: 'translate(' + ((Math.random() * 2 - 1) * power * k).toFixed(1) + 'px,' + ((Math.random() * 2 - 1) * power * k).toFixed(1) + 'px)' });
    }
    frames.push({ transform: 'translate(0,0)' });
    return FX.anim(w, frames, { duration: dur, easing: 'linear' });
  };
  // 임의 요소 흔들림 (컷신용)
  FX.shakeEl = function (el, power, dur, rot) {
    var frames = [], n = 12;
    for (var i = 0; i < n; i++) {
      var k = 1 - i / n;
      var r = rot ? ((Math.random() * 2 - 1) * rot * k).toFixed(2) : 0;
      frames.push({ transform: 'translate(' + ((Math.random() * 2 - 1) * power * k).toFixed(1) + 'px,' + ((Math.random() * 2 - 1) * power * k).toFixed(1) + 'px) rotate(' + r + 'deg)' });
    }
    frames.push({ transform: 'translate(0,0) rotate(0deg)' });
    return FX.anim(el, frames, { duration: dur || 400, easing: 'linear' });
  };

  FX.flash = function (color, dur, peak) {
    var f = FX.$('flash');
    f.style.background = color || '#fff';
    return FX.anim(f, [{ opacity: peak == null ? 0.9 : peak }, { opacity: 0 }], { duration: dur || 260, easing: 'ease-out' });
  };

  // 피해 숫자 등 떠오르는 글자
  FX.floatText = function (x, y, text, cls) {
    var d = document.createElement('div');
    d.className = 'float ' + (cls || '');
    d.textContent = text;
    d.style.left = x + 'px'; d.style.top = y + 'px';
    FX.$('floatLayer').appendChild(d);
    return FX.anim(d, [
      { transform: 'translate(-50%,-50%) scale(.6)', opacity: 0 },
      { transform: 'translate(-50%,-90%) scale(1.15)', opacity: 1, offset: 0.18 },
      { transform: 'translate(-50%,-140%) scale(1)', opacity: 1, offset: 0.7 },
      { transform: 'translate(-50%,-190%) scale(.95)', opacity: 0 }
    ], { duration: 1100, easing: 'ease-out' }).then(function () { d.remove(); });
  };

  var toastTimer = null;
  FX.toast = function (text, ms) {
    var t = FX.$('toast');
    t.textContent = text;
    t.classList.remove('hidden');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () { t.classList.add('hidden'); }, ms || 1400);
  };

  FX.banner = function (text, ms) {
    var b = FX.$('banner');
    b.textContent = text;
    b.classList.remove('hidden');
    return FX.anim(b, [
      { opacity: 0, transform: 'scale(1.2)', letterSpacing: '.5em' },
      { opacity: 1, transform: 'scale(1)', letterSpacing: '.2em', offset: 0.25 },
      { opacity: 1, offset: 0.75 },
      { opacity: 0 }
    ], { duration: ms || Game.DATA.timing.banner }).then(function () { b.classList.add('hidden'); });
  };

  FX.fade = function (to, ms) {
    var f = FX.$('fade');
    f.style.transition = 'opacity ' + (FX.ms(ms || 400) / 1000) + 's';
    f.style.opacity = to;
    return FX.wait(ms || 400);
  };

  // ───────── 입자 ─────────
  // opts: count, color(s), speed, spread(각도 범위), angle, gravity, life, size, shape(dot|rock|flake|line), drag
  FX.burst = function (x, y, opts) {
    opts = opts || {};
    var n = opts.count || 20;
    for (var i = 0; i < n; i++) {
      var ang = (opts.angle != null ? opts.angle : -Math.PI / 2) + (Math.random() - 0.5) * (opts.spread != null ? opts.spread : Math.PI * 2);
      var sp = (opts.speed || 300) * (0.35 + Math.random() * 0.75);
      var colors = opts.colors || [opts.color || '#ccc'];
      FX.particles.push({
        x: x + (Math.random() - 0.5) * (opts.jitterX || 0), y: y + (Math.random() - 0.5) * (opts.jitterY || 0),
        vx: Math.cos(ang) * sp, vy: Math.sin(ang) * sp,
        g: opts.gravity != null ? opts.gravity : 600, drag: opts.drag != null ? opts.drag : 0.6,
        life: (opts.life || 900) * (0.6 + Math.random() * 0.6), age: 0,
        size: (opts.size || 4) * (0.5 + Math.random()), rot: Math.random() * 6, vr: (Math.random() - 0.5) * 8,
        color: colors[Math.floor(Math.random() * colors.length)], shape: opts.shape || 'dot', alpha: opts.alpha || 1
      });
    }
  };
  // 위에서 떨어지는 먼지·돌
  FX.rain = function (x0, x1, y, opts) {
    opts = opts || {};
    var n = opts.count || 30;
    for (var i = 0; i < n; i++) {
      FX.particles.push({
        x: x0 + Math.random() * (x1 - x0), y: y - Math.random() * 120,
        vx: (Math.random() - 0.5) * 40, vy: 60 + Math.random() * 160,
        g: opts.gravity != null ? opts.gravity : 500, drag: 0.1,
        life: (opts.life || 1600) * (0.6 + Math.random() * 0.6), age: -Math.random() * (opts.stagger || 400),
        size: (opts.size || 4) * (0.5 + Math.random()), rot: Math.random() * 6, vr: (Math.random() - 0.5) * 4,
        color: (opts.colors || ['#888'])[Math.floor(Math.random() * (opts.colors || ['#888']).length)],
        shape: opts.shape || 'dot', alpha: opts.alpha || 0.9
      });
    }
  };

  FX.updateParticles = function (dt) {
    var ps = FX.particles, s = dt * FX.speed / 1000;
    for (var i = ps.length - 1; i >= 0; i--) {
      var p = ps[i];
      p.age += dt * FX.speed;
      if (p.age < 0) continue;
      if (p.age > p.life) { ps.splice(i, 1); continue; }
      p.vy += p.g * s;
      p.vx *= (1 - p.drag * s); p.vy *= (1 - p.drag * s * 0.3);
      p.x += p.vx * s; p.y += p.vy * s; p.rot += p.vr * s;
    }
  };
  FX.drawParticles = function (ctx) {
    var ps = FX.particles;
    for (var i = 0; i < ps.length; i++) {
      var p = ps[i];
      if (p.age < 0) continue;
      var k = 1 - p.age / p.life;
      ctx.globalAlpha = Math.max(0, Math.min(1, k * 1.4)) * p.alpha;
      ctx.fillStyle = p.color; ctx.strokeStyle = p.color;
      if (p.shape === 'rock') {
        ctx.save(); ctx.translate(p.x, p.y); ctx.rotate(p.rot);
        var r = p.size;
        ctx.beginPath(); ctx.moveTo(-r, -r * 0.6); ctx.lineTo(r * 0.7, -r); ctx.lineTo(r, r * 0.5); ctx.lineTo(-r * 0.4, r); ctx.closePath(); ctx.fill();
        ctx.restore();
      } else if (p.shape === 'flake') {
        ctx.save(); ctx.translate(p.x, p.y); ctx.rotate(p.rot);
        ctx.fillRect(-p.size, -p.size * 0.35, p.size * 2, p.size * 0.7);
        ctx.restore();
      } else if (p.shape === 'line') {
        ctx.lineWidth = p.size * 0.5;
        ctx.beginPath(); ctx.moveTo(p.x, p.y); ctx.lineTo(p.x - p.vx * 0.04, p.y - p.vy * 0.04); ctx.stroke();
      } else {
        ctx.beginPath(); ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2); ctx.fill();
      }
    }
    ctx.globalAlpha = 1;
  };

  // 칼날 베기 선 (캔버스 오버레이, 짧게 표시)
  FX.slash = function (x, y, opts) {
    opts = opts || {};
    var o = { t0: performance.now(), dur: FX.ms(opts.dur || 320), x: x, y: y, len: opts.len || 160, ang: opts.ang != null ? opts.ang : -0.7, color: opts.color || '#fff', width: opts.width || 8, count: opts.count || 1 };
    o.draw = function (ctx, now) {
      var k = (now - o.t0) / o.dur;
      if (k >= 1) return false;
      for (var i = 0; i < o.count; i++) {
        var off = (i - (o.count - 1) / 2) * 26;
        var dx = Math.cos(o.ang) * o.len / 2, dy = Math.sin(o.ang) * o.len / 2;
        var px = -Math.sin(o.ang) * off, py = Math.cos(o.ang) * off;
        var grow = Math.min(1, k * 3);
        ctx.globalAlpha = 1 - k;
        ctx.strokeStyle = o.color; ctx.lineWidth = o.width * (1 - k * 0.6); ctx.lineCap = 'round';
        ctx.shadowColor = o.color; ctx.shadowBlur = 18;
        ctx.beginPath();
        ctx.moveTo(o.x + px - dx, o.y + py - dy);
        ctx.lineTo(o.x + px - dx + dx * 2 * grow, o.y + py - dy + dy * 2 * grow);
        ctx.stroke();
      }
      ctx.shadowBlur = 0; ctx.globalAlpha = 1;
      return true;
    };
    FX.overlays.push(o);
    return FX.wait(opts.dur || 320);
  };
  // 두 점 사이를 빠르게 지나가는 선(화살 등)
  FX.streak = function (x0, y0, x1, y1, opts) {
    opts = opts || {};
    var o = { t0: performance.now(), dur: FX.ms(opts.dur || 240) };
    o.draw = function (ctx, now) {
      var k = (now - o.t0) / o.dur;
      if (k >= 1) return false;
      var hx = x0 + (x1 - x0) * k, hy = y0 + (y1 - y0) * k;
      var tx = x0 + (x1 - x0) * Math.max(0, k - 0.25), ty = y0 + (y1 - y0) * Math.max(0, k - 0.25);
      ctx.strokeStyle = opts.color || '#fff'; ctx.lineWidth = opts.width || 4; ctx.lineCap = 'round';
      ctx.shadowColor = opts.color || '#fff'; ctx.shadowBlur = 12;
      ctx.beginPath(); ctx.moveTo(tx, ty); ctx.lineTo(hx, hy); ctx.stroke();
      ctx.shadowBlur = 0;
      return true;
    };
    FX.overlays.push(o);
    return FX.wait(opts.dur || 240);
  };
  FX.drawOverlays = function (ctx, now) {
    FX.overlays = FX.overlays.filter(function (o) { return o.draw(ctx, now); });
  };

  // 2차 베지어 위의 점
  FX.qpt = function (a, c, b, t) {
    var u = 1 - t;
    return { x: u * u * a.x + 2 * u * t * c.x + t * t * b.x, y: u * u * a.y + 2 * u * t * c.y + t * t * b.y };
  };
})(window);
