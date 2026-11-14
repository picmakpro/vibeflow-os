#!/usr/bin/env node
// mise-en-page-chrome.mjs — mesures navigateur de la suite de la mise en page (79-18, SOCL-22). Socle : chrome-session.mjs ; la sonde est posée avant tout script.
// Usage : node mise-en-page-chrome.mjs <chrome> <racine-du-serveur> <mode> [argument] ; MEP_LAB = chemin du lab (valeur de test qui ne doit jamais voyager).
//   tracer                niveau « lots » (au moins 90 cartes), en mode en ligne (Worker retiré) puis en mode worker : fenêtre de calcul, pouls, tâche longue, clic, API (A4)
//   equivalence           trois niveaux, mode en ligne et mode worker : positions des cartes et sections des arêtes
//   repli <sans|serveur>  `sans` : Worker retiré ; `serveur` : le serveur lancé décide (fichier du worker introuvable) : le canevas, le compte de workers, les avertissements
//   export <fichier>      l'export autonome ouvert en `file:` : le canevas, aucun Worker
//   erreur                une requête altérée en vol fait échouer ELK : l'élément d'erreur affiche un TEXTE, la page reste vivante
// Chaque mode rend UNE ligne JSON ({ erreur } sur échec nommé).
import { executer, stabiliser } from './chrome-session.mjs';
import { sonde, charger, VUE_POSEE, LIRE } from './mise-en-page-sonde.mjs';

const [, , chrome, racine, mode, arg] = process.argv;
const SECRETS = [process.env.MEP_LAB || '', 'MQ18-LAB'].filter(Boolean);
const LOTS = "VibeFlow.reveal('f:lots/m05.js')";
const POSITIONS = "(() => { const l = VibeFlow.state.layout || { children: [], edges: [] }; return { cartes: l.children.map((n) => [n.id, n.x, n.y, n.width, n.height]).sort(), "
  + "aretes: (l.edges || []).map((e) => [e.id, JSON.stringify(e.sections || [])]).sort() }; })()";

// une page neuve sous la sonde : la fenêtre est posée AVANT la navigation (la coquille attend le démarrage du moteur, qui lit innerWidth)
async function sous(s, options, url, corps) {
  await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
  await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
  const { identifier } = await s.send('Page.addScriptToEvaluateOnNewDocument', { source: sonde({ secrets: SECRETS, ...options }) });
  try { await charger(s, url); return await corps(); } finally { await s.send('Page.removeScriptToEvaluateOnNewDocument', { identifier }); }
}
const resume = async (s) => JSON.parse(await s.ev('window.__mep.resume()'));
const attendrePose = async (s) => { await s.attendre(VUE_POSEE, 'vue posée'); await stabiliser(() => s.ev(LIRE), { pas: 120, max: 8000 }); };

// niveau lourd : au lancement de la navigation, la fenêtre de calcul s'ouvre ; un clic réel est envoyé PENDANT cette fenêtre
async function niveauLourd(s, options) {
  return sous(s, options, `${racine}/index.html?lang=en`, async () => {
    await s.ev("(() => { const e = document.createElement('div'); e.id = 'mep-cible'; e.setAttribute('style', 'position:fixed;right:4px;bottom:4px;width:40px;height:40px;"
      + "z-index:2147483647;background:#888'); document.body.appendChild(e); window.__mep.surRender(); })()");
    const t0 = await s.ev('performance.now()'), lourde = `(window.__mep.fenetres.find((f) => f.cartes >= 24 && f.debut > ${t0}) || null)`;
    await s.ev(`setTimeout(() => ${LOTS}, 0)`);
    let ouverte = null; const fin = Date.now() + 60000;
    while (!ouverte && Date.now() < fin) ouverte = await s.ev(`(() => { const f = ${lourde}; return f ? true : false; })()`);
    const envoye = await s.ev('performance.now()');
    const [x, y] = JSON.parse(await s.ev("JSON.stringify((() => { const r = document.querySelector('#mep-cible').getBoundingClientRect(); return [r.x + r.width / 2, r.y + r.height / 2]; })())"));
    for (const type of ['mousePressed', 'mouseReleased']) await s.send('Input.dispatchMouseEvent', { type, x, y, button: 'left', clickCount: 1 });
    await s.attendre(`!!${lourde} && ${lourde}.fin !== null`, 'fenêtre de calcul close'); await attendrePose(s);
    const mes = JSON.parse(await s.ev(`JSON.stringify((() => { const S = window.__mep, f = ${lourde}; return { debut: f.debut, fin: f.fin, duree: f.fin - f.debut, mode: f.mode, cartes: f.cartes,
      ecart: S.ecart(f.debut, f.fin), tache: S.tache(f.debut, f.fin), clics: S.clics, avant: S.avant, vivante: S.pouls.length > 0 && typeof S.balayer === 'function',
      noeuds: document.querySelectorAll('#viewport .node').length, vus: VibeFlow.state.view.visible.length, rendus: S.rendus.length ? S.rendus[S.rendus.length - 1] : null,
      gele: Object.isFrozen(window.VibeFlow), cles: Object.keys(window.VibeFlow).sort(), temoinFuite: S.balayer({ id: 0, graphe: { x: 'MQ18-LAB' } }, 'req', true),
      temoinCle: S.balayer({ id: 0, graphe: { mandat: 1 } }, 'req', true) }; })())`));
    return { ...mes, envoye, resume: await resume(s), violations: [...s.violations] };
  });
}

if (mode === 'tracer') {
  await executer(chrome, async (s) => ({ ligne: await niveauLourd(s, { sansWorker: true }), worker: await niveauLourd(s, {}) }), { csp: true });
} else if (mode === 'equivalence') {
  await executer(chrome, async (s) => {
    const niveaux = {};
    for (const [nom, page, aller] of [['code', 'index.html', null], ['lots', 'index.html', LOTS], ['equipe', 'equipe.html', null]]) {
      niveaux[nom] = {};
      for (const [m, sansWorker] of [['ligne', true], ['worker', false]]) {
        niveaux[nom][m] = await sous(s, { sansWorker }, `${racine}/${page}?lang=en`, async () => {
          if (aller) { await s.ev(aller); await s.attendre("VibeFlow.state.container !== 'root'", 'niveau atteint'); await attendrePose(s); }
          const p = JSON.parse(await s.ev(`JSON.stringify(${POSITIONS})`));
          return { ...p, construits: (await resume(s)).construits };
        });
      }
    }
    // la sortie d'un processus qui se termine par process.exit est tronquée à 64 Kio sur un tube : seuls des condensés sortent
    const egal = (v, k) => JSON.stringify(v.ligne[k]) === JSON.stringify(v.worker[k]);
    return { niveaux: Object.fromEntries(Object.entries(niveaux).map(([k, v]) => [k, { cartes: v.ligne.cartes.length, egalCartes: egal(v, 'cartes'), egalAretes: egal(v, 'aretes'),
      nbAretes: v.ligne.aretes.length, construitsWorker: v.worker.construits, construitsLigne: v.ligne.construits }])) };
  }, { csp: true });
} else if (mode === 'repli') {
  await executer(chrome, async (s) => sous(s, { sansWorker: arg === 'sans' }, `${racine}/index.html?lang=en`, async () => ({
    resume: await resume(s), noeuds: await s.ev("document.querySelectorAll('#viewport .node').length"),
    layout: await s.ev('VibeFlow.state.layout.children.length') })), { csp: true });
} else if (mode === 'export') {
  await executer(chrome, async (s) => sous(s, {}, `file://${arg}?lang=en`, async () => ({
    resume: await resume(s), protocole: await s.ev('location.protocol'), noeuds: await s.ev("document.querySelectorAll('#viewport .node').length"),
    layout: await s.ev('VibeFlow.state.layout.children.length'), violations: [...s.violations] })), { csp: true });
} else if (mode === 'erreur') {
  await executer(chrome, async (s) => sous(s, {}, `${racine}/index.html?lang=en`, async () => {
    await s.ev('window.__mep.alterer = true; VibeFlow.render()'); await s.attendre("/Layout failed/.test(document.querySelector('#empty').textContent)", 'échec affiché');
    const echec = JSON.parse(await s.ev("JSON.stringify({ texte: document.querySelector('#empty').textContent, enfants: document.querySelector('#empty').children.length, balises: document.querySelectorAll('#empty b').length })"));
    await s.ev('window.__mep.alterer = false'); await s.ev('VibeFlow.render()'); await s.attendre("document.querySelector('#empty').hidden === true", 'redessin réussi');
    return { echec, vivante: await s.ev('VibeFlow.state.layout.children.length > 0 && document.readyState === "complete"'), resume: await resume(s) };
  }), { csp: true });
} else { console.log(JSON.stringify({ erreur: `mode inconnu : ${mode}` })); process.exit(2); }
