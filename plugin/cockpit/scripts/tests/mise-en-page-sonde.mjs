// mise-en-page-sonde.mjs — la sonde et les aides de chargement de la suite de la mise en page (79-18, SOCL-22 ; R6). Aide autonome, sans dépendance.
// La sonde se pose AVANT tout script de la page (Page.addScriptToEvaluateOnNewDocument). Elle enveloppe la construction de `Worker`, ses envois, ses réponses et
// sa terminaison, les appels de calcul en ligne (ELK.prototype.layout), le pouls du fil principal, les tâches longues, les clics ; elle balaie chaque message
// (clés seulement, jamais de copie du contenu : seuls un condensé des positions et des comptes sont gardés). Retirer `Worker` (mode en ligne) est un réglage
// du harnais (`sansWorker`), jamais du code livré. Exports : sonde(options), PRET, VUE_POSEE, LIRE, charger(s, url), INTERDITES.
//   options : { sansWorker, secrets: [chaînes qui ne doivent jamais voyager], longueur: taille de l'identifiant d'une arête altérée }
// API de la page : window.__mep.{ construits, termines, urls, enLigne, fenetres, clics, avert, erreurs, vides, derniere, alterer, surRender, ecart, tache,
//   balayer(message, sens, essai), resume() }.
import { pause, stabiliser } from './chrome-session.mjs';

export const INTERDITES = ['doing', 'mandat', 'messages', 'outils', 'fil'];
export const PRET = "document.readyState === 'complete' && !!window.VibeFlow && !!window.VibeFlow.state && !!window.VibeFlow.state.layout";
export const VUE_POSEE = "(() => { const v = document.querySelector('#viewport'); return !!v && v.style.opacity !== '0' && !v.classList.contains('anim'); })()";
// l'état lu pour juger qu'une page est posée : onglet, conteneur, positions des cartes
export const LIRE = "JSON.stringify([window.VF_COQUILLE && window.VF_COQUILLE.onglet(), window.VibeFlow && window.VibeFlow.state && window.VibeFlow.state.container, "
  + "document.documentElement.dataset.vfPret, ((window.VibeFlow && window.VibeFlow.state.layout && window.VibeFlow.state.layout.children) || []).length])";

export const sonde = ({ sansWorker = false, secrets = [], longueur = 260 } = {}) => `(() => {
  const INT = ${JSON.stringify(INTERDITES)}, SEC = ${JSON.stringify(secrets)}, now = () => performance.now();
  const S = window.__mep = { avant: typeof window.VibeFlow, construits: 0, termines: 0, urls: [], enLigne: 0, fenetres: [], clics: [], avert: [], erreurs: [], vides: 0, derniere: null, alterer: false,
    pouls: [], longues: [], req: 0, rep: 0, reqTop: new Set(), repTop: new Set(), interdites: 0, fuites: 0, erreurMax: 0, rendus: [], ouv: new Map() };
  setInterval(() => S.pouls.push(now()), 10);
  try { new PerformanceObserver((l) => { for (const e of l.getEntries()) S.longues.push([e.startTime, e.duration]); }).observe({ type: 'longtask', buffered: true }); } catch {}
  document.addEventListener('mousedown', (e) => S.clics.push({ traite: now(), retard: now() - e.timeStamp }), true);
  for (const n of ['warn', 'error']) { const o = console[n].bind(console); console[n] = (...a) => { (n === 'warn' ? S.avert : S.erreurs).push(String(a[0]).slice(0, 200)); o(...a); }; }
  window.addEventListener('error', (e) => S.erreurs.push('page : ' + String(e.message).slice(0, 160)));
  window.addEventListener('unhandledrejection', (e) => S.erreurs.push('promesse : ' + String(e.reason && e.reason.message || e.reason).slice(0, 160)));
  new MutationObserver(() => { const e = document.querySelector('#empty'); if (e && /Layout failed/.test(e.textContent)) S.vides++; })
    .observe(document, { childList: true, subtree: true, characterData: true });
  S.balayer = (m, sens, essai) => {
    const interdites = []; const top = m && typeof m === 'object' ? Object.keys(m) : [];
    const marche = (v) => { if (v && typeof v === 'object') for (const k of Object.keys(v)) { if (INT.includes(k)) interdites.push(k); marche(v[k]); } };
    marche(m); const texte = JSON.stringify(m) || '', jetons = Object.values((window.VF_COCKPIT_SERVER && window.VF_COCKPIT_SERVER.jetons) || {});
    const fuites = [...SEC, ...jetons].filter((x) => x && texte.includes(x)).length;
    if (essai) return { interdites: interdites.length, fuites };
    const T = sens === 'req' ? S.reqTop : S.repTop; top.forEach((k) => T.add(k)); S[sens]++; S.interdites += interdites.length; S.fuites += fuites;
    if (typeof (m && m.erreur) === 'string') S.erreurMax = Math.max(S.erreurMax, m.erreur.length);
    return null;
  };
  const ouvrir = (id, mode, cartes) => { const f = { debut: now(), fin: null, mode, cartes }; S.fenetres.push(f); if (id !== null) S.ouv.set(id, f); return f; };
  const fermer = (d) => { const f = d && S.ouv.get(d.id); if (f) { f.fin = now(); S.ouv.delete(d.id); } };
  ${sansWorker ? "Object.defineProperty(window, 'Worker', { value: undefined, configurable: true, writable: true });" : `const W0 = window.Worker;
  if (W0) window.Worker = function (...a) {
    const w = new W0(...a), env = w.postMessage.bind(w), fin = w.terminate.bind(w); let clos = false; S.construits++; S.urls.push(String(a[0]));
    w.postMessage = (m, ...r) => {
      if (S.alterer && m && m.graphe) { const x = '<b>MQ18-ECHEC</b>' + 'z'.repeat(${longueur}); m = { ...m, graphe: { ...m.graphe, edges: [...m.graphe.edges, { id: 'eMQ18', sources: [x], targets: [x] }] } }; }
      S.balayer(m, 'req'); ouvrir(m.id, 'worker', ((m.graphe && m.graphe.children) || []).length); return env(m, ...r);
    };
    w.terminate = () => { if (!clos) { clos = true; S.termines++; } return fin(); };
    w.addEventListener('message', (e) => { S.balayer(e.data, 'rep'); fermer(e.data);
      const c = e.data && e.data.resultat && e.data.resultat.children; if (Array.isArray(c)) S.derniere = c.map((n) => [n.id, n.x, n.y, n.width, n.height]); });
    return w;
  };`}
  let E; Object.defineProperty(window, 'ELK', { configurable: true, get() { return E; }, set(v) { E = v; if (!v || !v.prototype || v.prototype.__mep) return; v.prototype.__mep = true;
    const orig = v.prototype.layout; v.prototype.layout = function (...a) { S.enLigne++; const f = ouvrir(null, 'ligne', ((a[0] && a[0].children) || []).length);
      const p = orig.apply(this, a); p.then(() => { f.fin = now(); }, () => { f.fin = now(); }); return p; }; } });
  S.surRender = () => window.VibeFlow.on('render', (d) => { const V = window.VibeFlow, l = V.state.layout, fa = V.freeArea();
    S.rendus.push({ ids: ((l && l.children) || []).map((n) => n.id).sort(), pos: ((l && l.children) || []).map((n) => [n.id, n.x, n.y, n.width, n.height]),
      vus: [...d.view.visible, ...(d.view.connectors || []).map((c) => c.id)].sort(), fa, derniere: S.derniere }); });
  S.ecart = (a, b) => { let m = 0; const p = S.pouls; for (let i = 1; i < p.length; i++) if (p[i] >= a && p[i - 1] <= b) m = Math.max(m, p[i] - p[i - 1]); return m; };
  S.tache = (a, b) => S.longues.reduce((m, [d, l]) => (d + l >= a && d <= b ? Math.max(m, l) : m), 0);
  S.resume = () => JSON.stringify({ construits: S.construits, termines: S.termines, enLigne: S.enLigne, urls: S.urls, req: S.req, rep: S.rep, reqTop: [...S.reqTop].sort(),
    repTop: [...S.repTop].sort(), interdites: S.interdites, fuites: S.fuites, avert: S.avert, erreurs: S.erreurs, vides: S.vides, erreurMax: S.erreurMax });
})()`;

// charge une adresse, attend la page posée (cartes, vue, état stable), ferme la visite guidée (Échap) ; la taille de fenêtre est posée AVANT par l'appelant
export async function charger(s, url) {
  await s.naviguer(url); await s.attendre(PRET, 'page prête'); await s.attendre("!!document.querySelector('#viewport .node')", 'cartes');
  await s.attendre(VUE_POSEE, 'vue posée'); await stabiliser(() => s.ev(LIRE), { pas: 120, max: 8000 });
  for (const type of ['keyDown', 'keyUp']) await s.send('Input.dispatchKeyEvent', { type, key: 'Escape', code: 'Escape', windowsVirtualKeyCode: 27, nativeVirtualKeyCode: 27 });
  await pause(200);
}
