// chrome-tracabilite.mjs — la section « Traçabilité » d'une phase dans le vrai panneau de Projet (76-06, TRAC-01 à TRAC-04), dans un vrai Chrome headless.
// Usage : node chrome-tracabilite.mjs <chrome> <racine-du-serveur> <sections>   Rend UNE ligne JSON { c10, c11, … } ou { erreur }. Chaque section est isolée.
import { executer, pause, stabiliser, attendreValeur } from './chrome-session.mjs';
const [, , chrome, racine, liste] = process.argv;
const SEL = new Set((liste || 'c10,c11').split(','));
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!VibeFlow.state && !!VibeFlow.state.layout";
const SANS_VISITE = "(() => { const g = Storage.prototype.getItem; Storage.prototype.getItem = function (k) {"
  + " const vue = typeof k === 'string' && (k.indexOf('floorplan:tour-seen:') === 0 || k.indexOf('vibeflow-cockpit:visite:') === 0);"
  + " return vue ? 'true' : g.call(this, k); }; })()";
const SEC = '#vf-trace-phase';
const LIGNES = `(() => { const s = document.querySelector('${SEC}'); if (!s) return null;
  return [...s.querySelectorAll('.vf-trace-ligne')].map((b) => ({ tag: b.tagName, id: (b.querySelector('.vf-trace-id') || {}).textContent || '',
    mot: ((b.querySelector('.vf-trace-mot') || {}).textContent || '').replace(/\\u00a0/g, ' ') })); })()`;

await executer(chrome, async (s) => {
  const o = { erreurs: {} }, reqs = [];
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: SANS_VISITE });
  await s.send('Network.enable');
  s.ecouter('Network.requestWillBeSent', (p) => { reqs.push(`${p.request.method} ${p.request.url.replace(/^https?:\/\/[^/]+/, '')}`); });
  const sec = async (nom, f) => { if (!SEL.has(nom)) return; try { await f(); } catch (e) { o.erreurs[nom] = String(e.message).slice(0, 200); } };
  const lire = async (expr) => { const v = await s.ev(`(async () => JSON.stringify(await (${expr})))()`); return v === undefined ? null : JSON.parse(v); };
  const charger = async (w = 1440, h = 900) => {
    await s.send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: false });
    await s.naviguer(`${racine}/project.html?vue=couloirs`, { brut: true }); await s.attendre(PRET, 'page prête');
    await s.attendre("document.querySelectorAll('.vp-carte').length > 0", 'couloirs'); await pause(300);
  };
  // une fois posé : le panneau d'une phase sélectionnée porte des lignes (jamais lues dans la foulée du geste) ; false à l'échéance courte
  const phase = async (n) => {
    await s.ev(`VibeFlow.select('n:ph-${n}')`);
    const ok = await attendreValeur(() => s.ev(`!!document.querySelector('${SEC} .vf-trace-ligne, ${SEC} .vf-trace-etat')`), (v) => v === true, { max: 6000 });
    await stabiliser(() => lire(LIGNES), { pas: 150, max: 4000 });
    return ok === true;
  };

  await sec('c10', async () => { // C1.0 : le fichier neuf est servi (A48) ; la première ligne porte le marqueur
    await charger();
    o.c10 = await lire(`(async () => { const e = performance.getEntriesByType('resource').map((x) => x.name).find((n) => /\\/74-vf-trace\\.js$/.test(n));
      if (!e) return 'non demandé'; const r = await fetch(e, { headers: { 'x-vf-cockpit-token': VF_ETAT.jeton() } });
      return r.status + '|' + (await r.text()).split("\\n")[0].slice(0, 13); })()`);
    o.c10intrus = await lire(`(async () => { const e = performance.getEntriesByType('resource').map((x) => x.name).find((n) => /\\/74-vf-trace\\.js$/.test(n));
      if (!e) return 'non demandé'; const r = await fetch(e.replace('74-vf-trace.js', '74-vf-trace-intrus.js'), { headers: { 'x-vf-cockpit-token': VF_ETAT.jeton() } }); return r.status; })()`);
  });
  await sec('c11', async () => { // C1.1 et C1.2 : la ligne de REQ-01 (manque : VERIFICATION), puis le témoin REQ-02 (chaîne complète)
    await charger(); reqs.length = 0;
    o.c11pose = await phase(2); o.c11 = await lire(`(() => { const t = document.querySelector('${SEC} h3'); return { h3: t ? t.firstChild.textContent.trim() : null, lignes: ${LIGNES} }; })()`);
    o.c11req = reqs.filter((r) => r.includes('/api/vf/tracabilite')).map((r) => r.replace(/[?&]ts=\d+/, ''));
    o.c12pose = await phase(3); o.c12 = await lire(LIGNES);
  });
  return o;
}, { csp: true });
