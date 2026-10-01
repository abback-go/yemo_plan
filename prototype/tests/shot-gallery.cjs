const { chromium } = require('/opt/node22/lib/node_modules/playwright');
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 830, height: 900 }, deviceScaleFactor: 1 });
  const errs = [];
  p.on('pageerror', e => errs.push(e.message)); p.on('console', m => { if (m.type()==='error') errs.push(m.text()); });
  await p.goto('file://' + __dirname + '/gallery.html');
  await p.waitForTimeout(300);
  await p.screenshot({ path: __dirname + '/out/gallery.png', fullPage: true });
  console.log('errors:', errs);
  await b.close();
})();
