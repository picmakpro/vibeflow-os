// chrome-tracabilite-couverture.mjs — la couverture d'une exigence, lue dans deux panneaux (76-08, R76.3), vrai Chrome sans tête.
// Usage : node chrome-tracabilite-couverture.mjs <chrome> <racine-du-serveur>   Rend UNE ligne JSON { avant, apres, erreur? }.
//   avant : une ligne `<exigence><TAB><plan>` par plan de la section « Couverte par » du panneau d'une carte `req/…` du graphe (vide quand le graphe n'en a plus) ;
//   apres : une ligne `<exigence><TAB><plan>` par puce de plan de la « Chaîne » du panneau d'exigence de la traçabilité (ouvert depuis la ligne de la phase).
// Le plan est nommé par son identifiant (`01-01`) : c'est le seul point commun des deux panneaux.
import { executer, pause, attendreValeur } from './chrome-session.mjs';
const [, , chrome, racine] = process.argv;
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!VibeFlow.state && !!VibeFlow.state.layout";
const SANS_VISITE = "(() => { const g = Storage.prototype.getItem; Storage.prototype.getItem = function (k) {"
  + " const vue = typeof k === 'string' && (k.indexOf('floorplan:tour-seen:') === 0 || k.indexOf('vibeflow-cockpit:visite:') === 0);"
  + " return vue ? 'true' : g.call(this, k); }; })()";
const GRAPHE = '(window.Floorplan || window.VibeFlow).graph';

await executer(chrome, async (s) => {
  const o = { avant: [], apres: [] };
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: SANS_VISITE });
  await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
  await s.naviguer(`${racine}/project.html?vue=couloirs`, { brut: true }); await s.attendre(PRET, 'page prête');
  await s.attendre("document.querySelectorAll('.vp-carte').length > 0", 'couloirs'); await pause(300);
  const lire = async (expr) => { const v = await s.ev(`(async () => JSON.stringify(await (${expr})))()`); return typeof v === 'string' ? JSON.parse(v) : null; };
  const vrai = (expr, max = 8000) => attendreValeur(() => s.ev(expr), (v) => v === true, { max }).then((v) => v === true);
  const planDe = (t) => (/^(\d+(?:\.\d+)?-\d+)/.exec(String(t).trim()) || [])[1] || String(t).trim();

  // avant : la section « Couverte par » du panneau générique d'une carte d'exigence
  const cartes = await lire(`${GRAPHE}.files.filter((f) => f.p.startsWith('req/')).map((f) => ({ p: f.p, nom: f.name }))`) || [];
  for (const c of cartes) {
    await s.ev(`VibeFlow.select(${JSON.stringify('f:' + c.p)})`);
    if (!(await vrai(`(() => { const t = document.querySelector('#panel .pt'); return !!t && t.textContent.trim() === ${JSON.stringify(c.nom)}; })()`))) throw new Error(`panneau ${c.nom}`);
    const rangs = await lire(`(() => { const h = [...document.querySelectorAll('#panel .sec h3')].find((x) => /^Couverte par/.test(x.textContent.trim()));
      return h ? [...h.parentElement.querySelectorAll('.row, a, button')].map((r) => r.textContent.replace(/\\s+/g, ' ').trim()).filter(Boolean) : []; })()`) || [];
    for (const r of rangs) o.avant.push(`${c.nom}\t${planDe(r)}`);
  }

  // apres : le panneau d'exigence de la traçabilité, ouvert par l'ouvreur de la page depuis la phase qui porte l'exigence
  const lignes = await lire(`${GRAPHE}.meta.vf.trace.exigences.filter((e) => e.phase != null).map((e) => ({ id: e.id, ws: e.ws, phase: e.phase }))`) || [];
  for (const e of lignes) {
    const n = await lire(`(${GRAPHE}.nodes.find((x) => x.kind === 'phase' && String(x.num) === ${JSON.stringify(String(e.phase))}
      && ((x.ws || null) === ${JSON.stringify(e.ws || null)} || ${JSON.stringify(e.ws)} === '*')) || {}).id || null`);
    if (!n) continue;
    await s.ev(`VibeFlow.select('n:${n}')`);
    if (!(await vrai("!!document.querySelector('#vf-trace-phase .vf-trace-ligne')"))) continue;
    await s.ev(`VFTrace.lire('phase', '${n}').then((p) => VFTrace.ouvrirExigence(p.phase.exigences.find((l) => l.id === ${JSON.stringify(e.id)}), false, null))`);
    if (!(await vrai(`(() => { const t = document.querySelector('#panel [data-vf-trace-panneau] .pt'); return !!t && t.textContent === ${JSON.stringify(e.id)}; })()`))) continue;
    await pause(150);
    const puces = await lire("[...document.querySelectorAll('#panel [data-vf-trace-panneau] .vf-trace-puce')].map((b) => b.textContent.trim())") || [];
    for (const p of puces) o.apres.push(`${e.id}\t${p}`);
  }
  o.avant = [...new Set(o.avant)].sort(); o.apres = [...new Set(o.apres)].sort();
  return o;
}, { csp: true });
