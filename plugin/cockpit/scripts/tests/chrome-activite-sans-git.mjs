// chrome-activite-sans-git.mjs — témoin navigateur de test-cockpit-activite-sans-git.sh (Phase 75, plan 75-10), dans un vrai Chrome headless sans affichage.
// Usage : node chrome-activite-sans-git.mjs <chrome> <racine-du-serveur>
// Rend UNE ligne JSON { niveaux: { <id de vue>: [[id, x, y, largeur, hauteur, hauteur-du-pied] ...] }, menu: [{ id, desactive, texte }], marques (liste d'identifiants de cartes), lentille (null = Aucune) } ou { erreur }.
// Les mesures sont prises une fois la mise en page posée (géométrie stable) ; la route /api/vf/activite est lue pour de vrai.
import { executer, stabiliser, pause } from './chrome-session.mjs';
const [, , chrome, racine] = process.argv;
const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!window.VibeFlow.state && !!window.VibeFlow.state.layout && document.documentElement.dataset.vfPret === 'oui'";
// la visite du premier passage prend Échap : ses clés sont lues comme posées
const SANS_VISITE = "(() => { const g = Storage.prototype.getItem; Storage.prototype.getItem = function (k) {"
  + " const vue = typeof k === 'string' && (k.indexOf('floorplan:tour-seen:') === 0 || k.indexOf('vibeflow-cockpit:visite:') === 0);"
  + " return vue ? 'true' : g.call(this, k); }; })()";
const SNAP = `JSON.stringify([...VibeFlow.state.chipEls].map(([id, g]) => { const r = g.getBoundingClientRect(), f = g.querySelector('.card .foot'), fr = f ? f.getBoundingClientRect() : null;
  return [id, Math.round(r.x * 10), Math.round(r.y * 10), Math.round(r.width * 10), Math.round(r.height * 10), fr ? Math.round(fr.height * 10) : -1]; }).sort((a, b) => (a[0] < b[0] ? -1 : 1)))`;
await executer(chrome, async (s) => {
  await s.send('Page.addScriptToEvaluateOnNewDocument', { source: SANS_VISITE });
  await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
  const poser = async () => { await s.attendre("!!document.querySelector('#viewport .node') && document.querySelector('#viewport').style.opacity !== '0'", 'cartes dessinées'); return stabiliser(() => s.ev(SNAP), { pas: 150, max: 12000 }); };
  await s.naviguer(`${racine}/index.html?lang=fr`); await s.attendre(PRET, 'page prête');
  await s.ev("(() => { const t = document.querySelector('#tour'); if (t && !t.hidden) document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' })); })()");
  await s.attendre("!!document.getElementById('btn-lentilles')", 'sélecteur posé');
  await pause(2500); // la route est lue et la ligne de chaque lentille posée
  const niveaux = {};
  // niveaux : le nœud qui porte les fichiers (n:unassigned sur un lab VibeFlow de la suite, n:d-src sur un lab brut), puis son premier dossier virtuel
  const ids = JSON.parse(await s.ev("JSON.stringify([...VibeFlow.state.chipEls.keys()].filter((k) => k.startsWith('n:')))"));
  const noeud = ids.find((k) => k === 'n:unassigned' || k === 'n:d-src') || ids[0];
  for (const id of [noeud, null]) {
    const cible = id || JSON.parse(await s.ev("JSON.stringify([...VibeFlow.state.chipEls.keys()].filter((k) => k.startsWith('d:')).sort()[0] || null)"));
    if (!cible) continue;
    await s.ev(`VibeFlow.go(${JSON.stringify(cible)})`);
    await s.attendre(`VibeFlow.state.container === ${JSON.stringify(cible)} && !!document.querySelector('#viewport .node')`, `vue ${cible}`);
    niveaux[cible] = JSON.parse(await poser());
  }
  await pause(800);
  await s.ev("document.getElementById('btn-lentilles').click()"); await pause(250);
  const menu = JSON.parse(await s.ev(`JSON.stringify([...document.querySelectorAll('#lens-menu .lr')].filter((r) => !String(r.dataset.id).startsWith('ag:')).map((r) => ({ id: r.dataset.id, desactive: r.getAttribute('aria-disabled') === 'true', texte: r.textContent })))`));
  const lentille = await s.ev('VF_MARQUES.active()');
  // les cartes qui portent une marque (la carte prévue en porte une sans lentille : c'est le canal du plan, pas une lentille)
  const marques = JSON.parse(await s.ev("JSON.stringify([...VibeFlow.state.chipEls].filter(([, g]) => g.querySelector('.lm')).map(([id]) => id).sort())"));
  return { niveaux, menu, lentille, marques };
});
