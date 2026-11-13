#!/usr/bin/env node
// mise-en-page-propriete.mjs — preuves GÉNÉRATIVES de la mise en page en worker (79-18, SOCL-22). Graine imprimée (`graine=N`, rejouable par VF_GRAINE).
// Usage : node mise-en-page-propriete.mjs <mode> <chrome> <racine> [graine]   (mode `temoin` : aucun navigateur)
//   graphes    40 graphes ELK de classes nommées : le worker (construit par la page sous la CSP réelle) et le paquet ELK du module appelé directement dans la
//              même page (l'oracle) rendent le même résultat, erreurs comprises message pour message
//   sequences  4 suites de 1 à 6 opérations (changer d'onglet, redessiner, changer d'onglet PENDANT un calcul) : un seul worker vivant, aucune erreur ni texte
//              d'échec, mise en page égale à celle d'un chargement à froid du même onglet
//   temoin <graphes|sequences>   un générateur à classe unique est REFUSÉ par la vérification de couverture
// Première ligne `graine=N` ; dernière ligne JSON { plantage, echecs, couverture, ... } ; sortie 0 (le verdict se lit dans le JSON).
import { executer, pause, stabiliser } from './chrome-session.mjs';
import { sonde, charger, VUE_POSEE, LIRE } from './mise-en-page-sonde.mjs';

const [, , mode, chrome, racine, graineArg] = process.argv;
const graine = Number(process.env.VF_GRAINE || graineArg) || 1;
const SECRETS = [process.env.MEP_LAB || '', 'MQ18-LAB'].filter(Boolean);
const prng = (a) => () => { a = (a + 0x6D2B79F5) | 0; let t = Math.imul(a ^ (a >>> 15), 1 | a); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
const tire = (r, a) => a[Math.floor(r() * a.length)];
const entier = (r, a, b) => a + Math.floor(r() * (b - a + 1));
const PAGES = { code: 'index.html', projet: 'project.html', equipe: 'equipe.html' };
const OPTIONS = { 'elk.algorithm': 'layered', 'elk.direction': 'RIGHT', 'elk.edgeRouting': 'ORTHOGONAL', 'elk.spacing.nodeNode': '32' };

// ---- classes de graphes ----
const noeud = (i, r, extra = {}) => ({ id: 'n' + i, width: entier(r, 60, 240), height: entier(r, 30, 90), ...extra });
const arete = (a, b, k) => ({ id: 'e' + k, sources: ['n' + a], targets: ['n' + b] });
const CLASSES = {
  vide: () => ({ children: [], edges: [] }),
  un: (r) => ({ children: [noeud(0, r)], edges: [] }),
  chaine: (r) => { const n = entier(r, 3, 8); return { children: [...Array(n).keys()].map((i) => noeud(i, r)), edges: [...Array(n - 1).keys()].map((i) => arete(i, i + 1, i)) }; },
  etoile: (r) => { const n = entier(r, 3, 8); return { children: [...Array(n + 1).keys()].map((i) => noeud(i, r)), edges: [...Array(n).keys()].map((i) => arete(0, i + 1, i)) }; },
  dense: (r) => { const n = entier(r, 5, 9), e = []; for (let k = 0; k < n * 2; k++) { const a = entier(r, 0, n - 1), b = entier(r, 0, n - 1); if (a !== b) e.push(arete(a, b, k)); }
    return { children: [...Array(n).keys()].map((i) => noeud(i, r)), edges: e }; },
  connecteurs: (r) => { const n = entier(r, 3, 6), c = [...Array(n).keys()].map((i) => noeud(i, r, i === 0 ? { layoutOptions: { 'elk.layered.layering.layerConstraint': 'FIRST_SEPARATE' } }
    : i === n - 1 ? { layoutOptions: { 'elk.layered.layering.layerConstraint': 'LAST_SEPARATE' } } : {})); return { children: c, edges: [...Array(n - 1).keys()].map((i) => arete(i, i + 1, i)) }; },
  inconnu: (r) => ({ children: [noeud(0, r), noeud(1, r)], edges: [arete(0, 1, 0), { id: 'e9', sources: ['n0'], targets: ['absent' + entier(r, 1, 99)] }] }),
};
export function genererGraphes(g, classes = Object.keys(CLASSES)) {
  const r = prng(g), couverture = Object.fromEntries(Object.keys(CLASSES).map((k) => [k, 0])), liste = [];
  const ordre = []; for (let i = 0; i < 40; i++) ordre.push(i < classes.length * 5 ? classes[i % classes.length] : tire(r, classes));
  for (const c of ordre) { couverture[c]++; const x = CLASSES[c](r); liste.push({ id: 'g', ...x, layoutOptions: OPTIONS }); }
  return { liste, couverture };
}
const manque = (couv, min) => Object.entries(couv).filter(([, n]) => n < min).map(([k]) => k);

// ---- suites d'opérations ----
export function genererSuites(g, avecPendant = true) {
  const r = prng(g + 1000), suites = [], couverture = { onglet: 0, redessin: 0, pendant: 0, vers_code: 0, vers_projet: 0, vers_equipe: 0 };
  for (let s = 0; s < 4; s++) {
    const ops = []; for (let i = entier(r, 1, 6); i > 0; i--) ops.push({ type: tire(r, avecPendant ? ['onglet', 'onglet', 'redessin', 'pendant'] : ['onglet', 'onglet', 'redessin']), vers: tire(r, Object.keys(PAGES)) });
    if (s === 0 && avecPendant) ops.splice(entier(r, 0, ops.length), 0, { type: 'pendant', vers: tire(r, Object.keys(PAGES)) });
    if (s === 1) ops.splice(entier(r, 0, ops.length), 0, { type: 'redessin', vers: 'code' });
    for (const o of ops) { couverture[o.type]++; if (o.type !== 'redessin') couverture['vers_' + o.vers]++; }
    suites.push({ depart: tire(r, Object.keys(PAGES)), ops });
  }
  return { suites, couverture };
}

if (mode === 'temoin') {
  const g = racine === 'sequences' ? genererSuites(graine, false).couverture : genererGraphes(graine, ['vide']).couverture;
  const min = racine === 'sequences' ? 3 : 5; console.log(`graine=${graine}`);
  console.log(JSON.stringify({ plantage: false, echecs: [], couverture: g, refuse: manque(g, 1).length > 0 && manque(Object.fromEntries(Object.entries(g).filter(([k]) => k !== 'pendant' || racine === 'sequences')), min).length > 0 }));
} else if (mode === 'graphes') {
  console.log(`graine=${graine}`);
  const { liste, couverture } = genererGraphes(graine);
  await executer(chrome, async (s) => {
    await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
    await charger(s, `${racine}/index.html?lang=en`);
    const duo = await s.ev(`(async () => { const w = new Worker('/_vf/elk-fil.js'), sortie = [];
      for (let i = 0; i < ${liste.length}; i++) { const g = ${JSON.stringify(liste)}[i]; let o;
        try { o = { ok: await new ELK().layout(JSON.parse(JSON.stringify(g))) }; } catch (e) { o = { err: String(e && e.message || e).slice(0, 200) }; }
        const w2 = await new Promise((ok, ko) => { const t = setTimeout(() => ko(new Error('worker muet')), 20000);
          w.onmessage = (m) => { clearTimeout(t); ok(m.data); }; w.onerror = () => ko(new Error('worker en échec')); w.postMessage({ id: i, graphe: JSON.parse(JSON.stringify(g)) }); });
        sortie.push([o, w2]); }
      w.terminate(); return JSON.stringify(sortie); })()`);
    const echecs = []; JSON.parse(duo).forEach(([o, w], i) => {
      const bon = o.ok ? w.id === i && w.resultat && JSON.stringify(w.resultat) === JSON.stringify(o.ok) : w.id === i && w.erreur === o.err && !w.resultat;
      if (!bon) echecs.push({ i, attendu: JSON.stringify(o).slice(0, 80), obtenu: JSON.stringify(w).slice(0, 80) });
    });
    return { plantage: false, echecs, couverture, refuse: manque(couverture, 5), nombre: liste.length };
  }, { csp: true });
} else if (mode === 'sequences') {
  console.log(`graine=${graine}`);
  const { suites, couverture } = genererSuites(graine), echecs = [], froids = new Map(), msgs = { req: 0, rep: 0, reqTop: new Set(), repTop: new Set(), interdites: 0, fuites: 0, erreurMax: 0 };
  const cumuler = (m) => { msgs.req += m.req; msgs.rep += m.rep; m.reqTop.forEach((k) => msgs.reqTop.add(k)); m.repTop.forEach((k) => msgs.repTop.add(k));
    msgs.interdites += m.interdites; msgs.fuites += m.fuites; msgs.erreurMax = Math.max(msgs.erreurMax, m.erreurMax); };
  await executer(chrome, async (s) => {
    await s.send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
    await s.send('Emulation.setFocusEmulationEnabled', { enabled: true });
    await s.send('Page.addScriptToEvaluateOnNewDocument', { source: sonde({ secrets: SECRETS }) });
    const pose = async () => { await s.attendre("document.documentElement.dataset.vfPret === 'oui'", 'onglet prêt'); await s.attendre(VUE_POSEE, 'vue posée'); await stabiliser(() => s.ev(LIRE), { pas: 150, max: 12000 }); };
    const etat = async () => JSON.parse(await s.ev(`JSON.stringify({ r: JSON.parse(window.__mep.resume()), onglet: VF_COQUILLE.onglet(), hash: location.hash,
      pos: VibeFlow.state.layout.children.map((n) => [n.id, n.x, n.y, n.width, n.height]).sort(), texte: document.querySelector('#empty').textContent })`));
    for (const [si, su] of suites.entries()) {
      const vus = []; await charger(s, `${racine}/${PAGES[su.depart]}?lang=en`);
      const verifier = async (op) => {
        const e = await etat(), cle = e.onglet + '|' + e.hash; vus.push({ op, cle, pos: e.pos, page: PAGES[e.onglet] });
        const ko = (classe, d) => echecs.push({ suite: si, op, classe, detail: String(d).slice(0, 100) });
        if (e.r.construits - e.r.termines !== 1) ko('vivants', `construits ${e.r.construits} - termines ${e.r.termines}`);
        if (e.r.erreurs.length || e.r.vides || /Layout failed/.test(e.texte) || e.r.avert.length) ko('erreur', JSON.stringify([e.r.erreurs, e.r.vides, e.texte, e.r.avert]));
        cumuler(e.r);
      };
      await verifier('depart:' + su.depart);
      for (const [oi, o] of su.ops.entries()) {
        const nom = `${oi}:${o.type}:${o.vers}`;
        if (o.type === 'onglet') { await s.ev(`VF_COQUILLE.chargerOnglet(${JSON.stringify(o.vers)})`); }
        else if (o.type === 'redessin') { await s.ev('VibeFlow.render()'); }
        else {
          await s.ev("VF_COQUILLE.chargerOnglet('code')"); await pose(); await s.ev('setTimeout(() => VibeFlow.reveal("f:lots/m05.js"), 0)');
          let ouverte = false; const fin = Date.now() + 20000; while (!ouverte && Date.now() < fin) ouverte = await s.ev('window.__mep.fenetres.some((f) => f.cartes >= 24 && f.fin === null)');
          couverture.pendantEffectif = (couverture.pendantEffectif || 0) + (ouverte ? 1 : 0);
          await s.ev(`setTimeout(() => { window.__pend = VF_COQUILLE.chargerOnglet(${JSON.stringify(o.vers)}); }, 0)`); await pause(50); await s.ev('window.__pend');
        }
        await pose(); await verifier(nom);
      }
      for (const v of vus) { // l'oracle : un chargement à froid du même onglet, à la même adresse (même fragment)
        if (!froids.has(v.cle)) { await charger(s, `${racine}/${v.page}?lang=en${v.cle.split('|')[1]}`); const e = await etat(); froids.set(v.cle, JSON.stringify(e.pos)); cumuler(e.r); }
        if (froids.get(v.cle) !== JSON.stringify(v.pos)) echecs.push({ suite: si, op: v.op, classe: 'froid', detail: v.cle });
      }
    }
    const parClasse = {}; for (const e of echecs) parClasse[e.classe] = (parClasse[e.classe] || 0) + 1;
    return { plantage: false, echecs: echecs.slice(0, 6), parClasse, couverture, msgs: { ...msgs, reqTop: [...msgs.reqTop].sort(), repTop: [...msgs.repTop].sort() } };
  }, { csp: true });
} else { console.log(JSON.stringify({ erreur: `mode inconnu : ${mode}` })); process.exit(2); }
