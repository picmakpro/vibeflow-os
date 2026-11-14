// vm-regie-questions.mjs <dossier ui> <scénario.json> : les questions en attente des cadrages hors navigateur (Phase 73, plan 73-11, REGI-17). Rend UNE ligne JSON { out, final } ou { erreur }.
// Mode « pur » : les fichiers ui/ (71, modèle, lecture, source) dans un contexte vm sans DOM, avec un `document` qui n'enregistre que les événements émis ; sources simulées par le scénario.
//   Scénario : { mode: 'pur', enveloppe: null|{ vfTab, vf }, etat: bool (VF_ETAT), coquille: bool (VF_COQUILLE), route: valeur rendue par lireJson, pilote: bool (la promesse se règle à la main), etapes: [...] }
//   Étapes (résultat rangé sous `nom`) : { fn, args } sur __vfRegieQuestions · { mod: 'modele', fn, args } sur __vfRegieModele · { src: 'etat'|'compte'|'relire'|'journal' } · { reponse: 'resoudre', valeur } ou 'rejeter'
//   · { abo: 'planning' } (rappels de VF_ETAT.abonner) · { champ: valeur } (champ de l'enveloppe) · { coq: 'rappel', onglet } · { coq: 'nettoyer' }. Un argument { "$norm": X } vaut normaliser(X).
// Mode « page » : la page Équipe dans vm-regie-page.mjs (DOM réduit) ; le scénario `page` lui est passé tel quel, avec en plus `questions` (valeur de meta.vf.questions de l'enveloppe de la page),
//   `route` (réponse de la route du graphe Projet, source « etat ») et l'aide `__ouvrir(sélecteur, ouvert)` (ouvre ou ferme un repli en émettant `toggle`) posée avant les fichiers ui.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import vm from 'node:vm';
import { execFileSync } from 'node:child_process';
const [, , ui, scPath] = process.argv;
const dire = (o) => { console.log(JSON.stringify(o)); process.exit(0); };
const S = JSON.parse(fs.readFileSync(scPath, 'utf8'));
const ici = path.dirname(new URL(import.meta.url).pathname);
const EXISTE = (f) => fs.existsSync(path.join(ui, f));

if (S.mode === 'page') {
  const tmp = fs.mkdtempSync(path.join(process.env.TMPDIR || os.tmpdir(), 'vmq-'));
  const setup = path.join(tmp, 'setup.js');
  fs.writeFileSync(setup, `(() => { const G = window.Floorplan.graph; G.meta.vf = G.meta.vf || {}; ${S.questions === undefined ? '' : `G.meta.vf.questions = ${JSON.stringify(S.questions)};`}
    ${S.lu ? "window.__vfRegieLu = { lus: () => new Set(window.__lus || []), marquer() {}, toutMarquer(ids) { window.__lus = [...(window.__lus || []), ...ids]; window.__tm = ids; } }; window.__tmCompte = () => (window.__tm || []).length;" : ''}
    window.__poserQuestions = (v) => { window.Floorplan.graph.meta.vf.questions = v; window.__vfRegieQuestions.relire(); };
    window.__ouvrir = (sel, ouvert) => { const d = document.querySelector(sel); d.open = !!ouvert; if (ouvert) d.setAttribute('open', ''); else d.removeAttribute('open'); d.dispatchEvent(new window.Event('toggle')); }; })();`);
  const ordre = fs.readdirSync(ui).filter((f) => /^(71-vf-equipe-rendu|72-vf-regie-(modele|pied|questions-[a-z]+|rendu|source))\.js$/.test(f)).sort();
  const page = { ...(S.page || {}), fichiers: [path.relative(ui, setup), ...ordre] };
  if (S.route !== undefined) page.transcript = S.route;
  const sc = path.join(tmp, 'sc.json'); fs.writeFileSync(sc, JSON.stringify(page));
  let sortie; try { sortie = execFileSync('node', [path.join(ici, 'vm-regie-page.mjs'), ui, sc], { encoding: 'utf8', timeout: 60000 }); } catch (e) { sortie = JSON.stringify({ erreur: 'page : ' + String(e.message).slice(0, 120) }); }
  fs.rmSync(tmp, { recursive: true, force: true });
  process.stdout.write(sortie); process.exit(0);
}

// ---------- mode pur ----------
const evts = [], journal = { requetes: [], abonnements: [], stockage: 0, fetchs: 0, evts }, rappels = new Map(), attente = [];
const enveloppe = S.enveloppe === undefined || S.enveloppe === null ? null : S.enveloppe;
const refus = { getItem() { return null; }, setItem() { journal.stockage++; }, removeItem() { journal.stockage++; } };
const document = { addEventListener() {}, removeEventListener() {}, dispatchEvent(e) { evts.push(e.type); return true; } };
const window = { document, console, CustomEvent: class { constructor(type, o) { this.type = type; this.detail = o && o.detail; } }, sessionStorage: refus, localStorage: refus,
  fetch() { journal.fetchs++; return Promise.reject(new Error('aucune requête attendue')); } };
if (enveloppe) window.Floorplan = { graph: enveloppe };
if (S.etat) {
  window.VF_ETAT = { lire: () => null, jeton: () => 'tok', abonnes: () => ({}),
    abonner: (cle, f) => { journal.abonnements.push(cle); (rappels.get(cle) || rappels.set(cle, new Set()).get(cle)).add(f); return () => rappels.get(cle).delete(f); },
    lireJson: (chemin) => { journal.requetes.push(chemin);
      if (!S.pilote) return S.route === 'rejet' ? Promise.reject(new Error('refus')) : Promise.resolve(S.route);
      return new Promise((ok, ko) => attente.push({ ok, ko })); } };
}
const inscrits = [];
if (S.coquille) window.VF_COQUILLE = { onglet: () => null, surOnglet(rappel, o) { const i = { rappel, cle: o && o.cle, nettoyage: null }; inscrits.push(i); return () => { if (i.nettoyage) i.nettoyage(); }; } };
window.window = window;
const ctx = vm.createContext(window);
const FICHIERS = ['71-vf-equipe-rendu.js', '72-vf-regie-modele.js', '72-vf-regie-questions-lecture.js', '72-vf-regie-questions-source.js'].filter(EXISTE);
const tick = () => new Promise((r) => setImmediate(r));
const resoudre = (a) => (Array.isArray(a) ? a.map(resoudre) : a && typeof a === 'object' && '$norm' in a ? window.__vfRegieQuestions.normaliser(a.$norm)
  : a && typeof a === 'object' ? Object.fromEntries(Object.entries(a).map(([k, v]) => [k, resoudre(v)])) : a);
const sortie = {};
try {
  for (const f of FICHIERS) vm.runInContext(fs.readFileSync(path.join(ui, f), 'utf8'), ctx, { filename: f, timeout: 5000 });
  for (const e of S.etapes || []) {
    let r;
    try {
      if (e.fn) { const cible = e.mod === 'modele' ? window.__vfRegieModele : window.__vfRegieQuestions; const f = cible && cible[e.fn];
        r = typeof f === 'function' ? f(...resoudre(e.args || [])) : { erreur: 'fonction absente : ' + e.fn }; }
      else if (e.src) { const Q = window.__vfRegieQuestions || {}; r = e.src === 'journal' ? JSON.parse(JSON.stringify(journal)) : typeof Q[e.src] === 'function' ? Q[e.src]() : { erreur: 'absent : ' + e.src }; }
      else if (e.reponse) { const p = attente.shift(); if (e.reponse === 'resoudre') p.ok(e.valeur); else p.ko(new Error('refus')); }
      else if (e.abo) for (const f of [...(rappels.get(e.abo) || [])]) f();
      else if (e.champ !== undefined) { window.Floorplan.graph.meta = window.Floorplan.graph.meta || {}; window.Floorplan.graph.meta.vf = { ...(window.Floorplan.graph.meta.vf || {}), questions: e.champ }; }
      else if (e.coq === 'rappel') for (const i of inscrits) { const n = i.rappel({ onglet: e.onglet || 'equipe' }); i.nettoyage = typeof n === 'function' ? n : null; }
      else if (e.coq === 'nettoyer') for (const i of inscrits) { if (i.nettoyage) i.nettoyage(); i.nettoyage = null; }
    } catch (x) { r = { erreur: String((x && x.message) || x).slice(0, 160) }; }
    await tick(); await tick();
    if (e.nom) sortie[e.nom] = r === undefined ? null : JSON.parse(JSON.stringify(r));
  }
  dire({ out: sortie, final: JSON.parse(JSON.stringify({ ...journal, inscrits: inscrits.map((i) => i.cle), ouverts: attente.length, abonnes: Object.fromEntries([...rappels].map(([k, v]) => [k, v.size])) })) });
} catch (e) { dire({ erreur: String((e && e.message) || e).slice(0, 200) }); }
