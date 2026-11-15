/*
 * blood.js — 코드로 그리는 피 튄 자국(화면 위)과 피 번짐(돌 틈). 천천히 흘러내린다.
 * 모양은 하나의 경로로 합쳐 칠한다(겹친 곳에 테두리·고리가 생기지 않게).
 */
(function (root) {
  'use strict';
  var Game = root.Game = root.Game || {};
  var B = Game.Blood = { layers: [] };

  function rng(seed) {
    var s = seed >>> 0;
    return function () {
      s = (s + 0x6D2B79F5) >>> 0;
      var t = s; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }
  // 울퉁불퉁한 덩어리 (시계 방향 다각형)
  function blobPoly(r, cx, cy, rad, n, rough, sx, sy) {
    var pts = [], ph = r() * 6.28, ph2 = r() * 6.28;
    for (var i = 0; i < n; i++) {
      var a = i / n * Math.PI * 2;
      var k = 1 + rough * (0.55 * Math.sin(a * 3 + ph) + 0.3 * Math.sin(a * 7 + ph2) + (r() - 0.5) * 0.5);
      pts.push([cx + Math.cos(a) * rad * k * (sx || 1), cy + Math.sin(a) * rad * k * (sy || 1)]);
    }
    return pts;
  }
  function polyPath(ctx, pts, s) {
    ctx.moveTo(pts[0][0] * s.k + s.ox, pts[0][1] * s.k + s.oy);
    for (var i = 1; i < pts.length; i++) ctx.lineTo(pts[i][0] * s.k + s.ox, pts[i][1] * s.k + s.oy);
    ctx.closePath();
  }

  // 튄 자국 하나. cx, cy: 중심 / size: 크기 / dir: 튄 방향(라디안, 없으면 사방)
  B.splat = function (cx, cy, size, seed, dir) {
    var r = rng(seed || 1), s = { cx: cx, cy: cy, size: size, polys: [], drops: [], drips: [], t0: performance.now() };
    // 몸통: 겹친 울퉁불퉁한 덩어리
    var n = 3 + Math.floor(r() * 4);
    for (var i = 0; i < n; i++) {
      var a = r() * Math.PI * 2, d = r() * size * 0.38;
      s.polys.push(blobPoly(r, cx + Math.cos(a) * d, cy + Math.sin(a) * d, size * (0.22 + r() * 0.26), 22, 0.28));
    }
    // 가늘어지는 줄기(바깥으로 튄 자국) + 끝의 방울
    var k = 6 + Math.floor(r() * 7);
    for (var q = 0; q < k; q++) {
      var a3 = dir != null ? dir + (r() - 0.5) * 1.5 : r() * Math.PI * 2;
      var len = size * (0.42 + Math.pow(r(), 1.6) * 0.85), w = size * (0.035 + r() * 0.05);
      var ux = Math.cos(a3), uy = Math.sin(a3), px = -uy, py = ux;
      var bx = cx + ux * size * 0.2, by = cy + uy * size * 0.2, tx = cx + ux * len, ty = cy + uy * len;
      var tip = w * (0.15 + r() * 0.25);
      s.polys.push([[bx + px * w, by + py * w], [tx + px * tip, ty + py * tip], [tx - px * tip, ty - py * tip], [bx - px * w, by - py * w]]);
      if (r() < 0.75) s.drops.push({ x: tx + ux * w * 1.4, y: ty + uy * w * 1.4, r: w * (0.5 + r() * 0.6) });
    }
    // 흩뿌려진 방울
    var m = 26 + Math.floor(r() * 30);
    for (var j = 0; j < m; j++) {
      var a2 = dir != null ? dir + (r() - 0.5) * 1.8 : r() * Math.PI * 2;
      var d2 = size * (0.5 + Math.pow(r(), 0.8) * 1.9);
      s.drops.push({ x: cx + Math.cos(a2) * d2, y: cy + Math.sin(a2) * d2, r: Math.max(1.2, size * (0.012 + r() * 0.05) * (1.5 - d2 / (size * 2.6))) });
    }
    // 아래로 흘러내림
    var dn = 2 + Math.floor(r() * 4);
    for (var t = 0; t < dn; t++) {
      s.drips.push({ x: cx + (r() - 0.5) * size * 0.7, y: cy + size * (0.1 + r() * 0.2), w: size * (0.04 + r() * 0.05), max: size * (0.7 + r() * 2.4), speed: 8 + r() * 22, delay: 200 + r() * 1200 });
    }
    // 방향 정리: 모든 다각형을 같은 감김 방향으로 (nonzero 합집합)
    s.polys.forEach(function (p) {
      var area = 0;
      for (var i2 = 0; i2 < p.length; i2++) { var a4 = p[i2], b4 = p[(i2 + 1) % p.length]; area += a4[0] * b4[1] - b4[0] * a4[1]; }
      if (area < 0) p.reverse();
    });
    return s;
  };

  // 돌 틈으로 번지는 피 (C5). level 이 오를수록 넓어진다.
  B.pool = function (x0, x1, y, seed) {
    var r = rng(seed || 7), p = { pool: true, polys: [], level: 0, shown: 0, cracks: [], cx: (x0 + x1) / 2, cy: y };
    for (var i = 0; i < 9; i++) {
      var bx = x0 + (i + 0.5) / 9 * (x1 - x0) + (r() - 0.5) * 60;
      p.polys.push({ x: bx, y: y + (r() - 0.4) * 30, rad: 44 + r() * 50, pts: blobPoly(r, 0, 0, 1, 26, 0.32, 1.7, 0.5) });
    }
    for (var c = 0; c < 12; c++) {
      var pts = [], px = x0 + r() * (x1 - x0), py = y + (r() - 0.5) * 20, ang = (r() < 0.5 ? -1 : 1) * (0.2 + r() * 0.5);
      pts.push([px, py]);
      for (var s2 = 0; s2 < 7; s2++) { px += Math.cos(ang) * (30 + r() * 50) * (r() < 0.5 ? -1 : 1); py += 8 + r() * 26; ang += (r() - 0.5) * 0.8; pts.push([px, py]); }
      p.cracks.push({ pts: pts, w: 1.5 + r() * 3 });
    }
    return p;
  };

  var ID = { k: 1, ox: 0, oy: 0 };
  B.drawSplat = function (ctx, s, now) {
    var age = now - s.t0;
    var grow = Math.min(1, age / 120);
    var sc = { k: grow, ox: s.cx * (1 - grow), oy: s.cy * (1 - grow) };
    ctx.save();
    ctx.shadowColor = 'rgba(10,0,0,0.8)'; ctx.shadowBlur = 6; ctx.shadowOffsetY = 2;
    var g = ctx.createRadialGradient(s.cx - s.size * 0.15, s.cy - s.size * 0.2, s.size * 0.05, s.cx, s.cy, s.size * 1.4);
    g.addColorStop(0, 'rgba(150,10,24,0.97)'); g.addColorStop(0.45, 'rgba(112,3,16,0.96)'); g.addColorStop(1, 'rgba(66,0,8,0.96)');
    ctx.fillStyle = g;
    ctx.beginPath();
    s.polys.forEach(function (p) { polyPath(ctx, p, sc); });
    s.drops.forEach(function (d) { var x = d.x * sc.k + sc.ox, y = d.y * sc.k + sc.oy; ctx.moveTo(x + d.r, y); ctx.arc(x, y, d.r, 0, Math.PI * 2); });
    s.drips.forEach(function (d) {
      var t = Math.max(0, age - d.delay) / 1000;
      var len = Math.min(d.max, d.speed * t * (1 + t * 0.2)) * grow;
      if (len <= 1) return;
      ctx.moveTo(d.x - d.w / 2, d.y); ctx.lineTo(d.x + d.w / 2, d.y); ctx.lineTo(d.x + d.w * 0.32, d.y + len); ctx.lineTo(d.x - d.w * 0.32, d.y + len); ctx.closePath();
      ctx.moveTo(d.x + d.w * 0.55, d.y + len); ctx.arc(d.x, d.y + len, d.w * 0.55, 0, Math.PI * 2);
    });
    ctx.fill();
    ctx.restore();
    // 젖은 윤기 (아주 약하게)
    ctx.save();
    var gl = ctx.createRadialGradient(s.cx - s.size * 0.25, s.cy - s.size * 0.25, 0, s.cx - s.size * 0.25, s.cy - s.size * 0.25, s.size * 0.45 * grow);
    gl.addColorStop(0, 'rgba(255,150,150,0.16)'); gl.addColorStop(1, 'rgba(255,150,150,0)');
    ctx.globalCompositeOperation = 'source-atop';
    ctx.fillStyle = gl; ctx.fillRect(s.cx - s.size, s.cy - s.size, s.size * 2, s.size * 2);
    ctx.restore();
  };

  B.drawPool = function (ctx, p, now, dt) {
    p.shown += (p.level - p.shown) * Math.min(1, (dt || 16) / 240);
    var L = p.shown;
    if (L <= 0.01) return;
    ctx.save();
    // 돌 틈(금)을 따라 스며든다
    ctx.strokeStyle = 'rgba(80,0,10,0.9)'; ctx.lineCap = 'round'; ctx.lineJoin = 'round';
    p.cracks.forEach(function (c) {
      var n = Math.min(c.pts.length, 1 + Math.floor(L * 2.4));
      if (n < 2) return;
      ctx.lineWidth = c.w * Math.min(1.8, 0.6 + L * 0.4);
      ctx.beginPath(); ctx.moveTo(c.pts[0][0], c.pts[0][1]);
      for (var i = 1; i < n; i++) ctx.lineTo(c.pts[i][0], c.pts[i][1]);
      ctx.stroke();
    });
    ctx.shadowColor = 'rgba(0,0,0,0.85)'; ctx.shadowBlur = 10;
    var g = ctx.createRadialGradient(p.cx, p.cy - 20, 10, p.cx, p.cy, 300 * (0.5 + Math.min(3, L) * 0.4));
    g.addColorStop(0, 'rgba(128,6,20,0.95)'); g.addColorStop(0.6, 'rgba(96,2,14,0.94)'); g.addColorStop(1, 'rgba(58,0,8,0.94)');
    ctx.fillStyle = g;
    ctx.beginPath();
    p.polys.forEach(function (b) {
      var k = b.rad * (0.45 + Math.min(3, L) * 0.42);
      polyPath(ctx, b.pts, { k: k, ox: b.x, oy: b.y });
    });
    ctx.fill();
    ctx.restore();
  };

  // 레이어: 캔버스 하나에 여러 자국. alpha 로 전체 투명도
  B.layer = function (canvas) {
    var L = { canvas: canvas, ctx: canvas.getContext('2d'), items: [], alpha: 1, last: performance.now() };
    B.layers.push(L);
    return L;
  };
  B.remove = function (L) {
    var i = B.layers.indexOf(L);
    if (i >= 0) B.layers.splice(i, 1);
    if (L && L.ctx) L.ctx.clearRect(0, 0, L.canvas.width, L.canvas.height);
  };
  // 여러 자국을 한 번에: 영역(x0~x1, y0~y1) 안에 count 개
  B.spray = function (L, opts) {
    opts = opts || {};
    var W = L.canvas.width, H = L.canvas.height, seed = opts.seed || Math.floor(Math.random() * 1e6);
    var r = rng(seed), n = opts.count || 5;
    var x0 = opts.x0 != null ? opts.x0 : 0, x1 = opts.x1 != null ? opts.x1 : W, y0 = opts.y0 != null ? opts.y0 : 0, y1 = opts.y1 != null ? opts.y1 : H;
    for (var i = 0; i < n; i++) {
      var s = B.splat(x0 + r() * (x1 - x0), y0 + r() * (y1 - y0), (opts.min || 50) + r() * ((opts.max || 180) - (opts.min || 50)), seed + i * 97, opts.dir);
      s.t0 = performance.now() + (opts.stagger ? i * opts.stagger : 0);
      L.items.push(s);
    }
  };

  B.render = function (now) {
    B.layers.forEach(function (L) {
      var dt = now - L.last; L.last = now;
      var ctx = L.ctx;
      ctx.clearRect(0, 0, L.canvas.width, L.canvas.height);
      if (L.alpha <= 0 || !L.items.length) return;
      ctx.save();
      ctx.globalAlpha = L.alpha;
      L.items.forEach(function (it) {
        if (it.pool) B.drawPool(ctx, it, now, dt);
        else if (now >= it.t0) B.drawSplat(ctx, it, now);
      });
      ctx.restore();
    });
  };
})(window);
