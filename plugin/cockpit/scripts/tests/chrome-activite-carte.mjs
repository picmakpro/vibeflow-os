// chrome-activite-carte.mjs — témoins navigateur de test-cockpit-activite-carte.sh (Phase 75, plan 75-07), dans un vrai Chrome headless sans affichage.
// Usage : node chrome-activite-carte.mjs <chrome> <racine-du-serveur> <sections> [<identifiant-de-session-équipe>]
//   <sections> : liste séparée par des virgules, parmi d3 d4 (tâche 1), d6 d8 d9 d10 d11 d17 (tâche 2), d13 d14 d15 d16 (tâche 3).
//   Rend UNE ligne JSON { <section>: valeur } ou { erreur }. Chaque mesure est interrogée dans la page, une fois la mise en page posée (worker : A4).
import { executer, stabiliser, attendreValeur } from './chrome-session.mjs';
import { sections } from './fixtures/test-cockpit-activite-carte/mesures.mjs';
const [, , chrome, racine, liste, sid] = process.argv;
const voulues = new Set((liste || '').split(','));
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!window.VibeFlow.state && !!window.VibeFlow.state.layout";

await executer(chrome, async (s) => {
  const vue = (w, h, tactile = false) => s.send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: tactile });
  // la page est posée quand la mise en page (worker) a rendu, que des cartes sont dessinées et que leur géométrie ne bouge plus
  const SNAP = `JSON.stringify({ L: VibeFlow.state.layout.children.map((c) => [c.id, c.x, c.y, c.width, c.height]), F: [...document.querySelectorAll('#viewport .node')].map((g) => { const f = g.querySelector('.card .foot'), c = g.querySelector('.card'); return [f ? f.offsetHeight : null, c ? c.offsetWidth : null, c ? c.offsetHeight : null]; }) })`;
  const poser = async () => { await s.attendre("!!document.querySelector('#viewport .node') && document.querySelector('#viewport').style.opacity !== '0'", 'cartes dessinées'); return stabiliser(() => s.ev(SNAP), { pas: 150, max: 12000 }); };
  const charger = async (page, lang = 'fr') => {
    await s.naviguer(`${racine}/${page}?lang=${lang}`); await s.attendre(PRET, `page prête (${page})`);
    await s.attendre("!document.querySelector('#tour') || document.querySelector('#tour').hidden || !!document.querySelector('#tour').hidden", 'visite', 3000).catch(() => {});
    await s.ev("(() => { const t = document.querySelector('#tour'); if (t && !t.hidden) document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' })); })()");
    return poser();
  };
  const aller = async (id) => {
    await s.ev(`VibeFlow.go(${JSON.stringify(id)})`);
    await s.attendre(`VibeFlow.state.container === ${JSON.stringify(id)} && !!document.querySelector('#viewport .node')`, `vue ${id}`);
    return poser();
  };
  // niveau de zoom : les classes que applyTransform pose sur le svg, et l'échelle réelle du plan (le CSS lod se juge à l'échelle voulue)
  const zoom = (niveau) => s.ev(`(() => { const k = ${JSON.stringify({ ouverture: 1, mid: 0.5, bas: 0.42 })[niveau] ?? 1}; const svg = document.querySelector('#svg'); svg.classList.toggle('lod-mid', ${niveau === 'mid'}); svg.classList.toggle('lod-low', ${niveau === 'bas'}); document.querySelector('#viewport').style.transform = 'translate(0px,0px) scale(' + k + ')'; return true; })()`);
  const ctx = { s, vue, charger, aller, poser, zoom, SNAP, racine, sid, stabiliser, attendreValeur };
  const o = {};
  for (const [nom, mesure] of Object.entries(sections)) if (voulues.has(nom)) o[nom] = await mesure(ctx);
  return o;
});
