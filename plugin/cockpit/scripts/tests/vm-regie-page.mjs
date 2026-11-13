// vm-regie-page.mjs <dossier ui> <scénario.json> : la page Équipe (régie) hors navigateur (Phase 73, plan 73-05). Rend UNE ligne JSON { out } ou { erreur }.
// Charge, dans l'ordre donné (défaut : l'ordre de nom du moteur), les fichiers ui/ du scénario dans le DOM réduit de vm-dom.mjs.
// Scénario : { onglet, source: 'etat'|'live', coquille: null|{ onglet0 }, surcouches: null|'pile'|'terminal', ouverteForcee, onglets, fichiers, who, lock, hash, sessionStorage, transcript, serveur, etapes }.
// Étapes (résultat rangé sous `nom` s'il est donné) : poser {who,lock} · avancer ms · clic sel [indice] · focus sel · touche key [sur] [prevenu] · saisie sel valeur · evenement type detail [annulable]
//   · hash h · onglet nom · vfOnglet nom hash · declarerVue {id,libelle} · annuler [déclencheurs] · marquer sel · raz · appel chemin args · reexecuter · obs {mode,sel,…}.
// Formes simulées des objets des phases 79 et 80 (VF_ETAT, VF_COQUILLE, VF_SURCOUCHES) : une seule fonction chacune, à aligner sur le code livré.
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { creerDom } from './vm-dom.mjs';
const [, , ui, scPath] = process.argv;
const dire = (o) => { console.log(JSON.stringify(o)); process.exit(0); };
const S = JSON.parse(fs.readFileSync(scPath, 'utf8'));
const FICHIERS = S.fichiers || ['71-vf-equipe-rendu.js', '72-vf-regie-modele.js', '72-vf-regie-pied.js', '72-vf-regie-rendu.js', '72-vf-regie-source.js'];
for (const f of FICHIERS) if (!fs.existsSync(path.join(ui, f))) dire({ erreur: 'fichier absent : ' + f });
const JETON = 'tok-vm', horloge = { now: 1_700_000_000_000 };
const dom = creerDom(horloge), { window: W, document: D, Evt } = dom;
W.window = W; W.self = W;
const etat = { who: null, lock: null, connexion: 'ouvert' }, abos = new Map(), journal = { sc: [], fetchs: [], evts: [], surcouches: [], vues: [], toasts: [], stockage: [], reveals: [] };
const compteurs = { ouverteLue: 0, panneauLu: 0 };
const el = (tag, id, parent = D.body) => { const e = D.createElement(tag); if (id) e.id = id; parent.appendChild(e); return e; };
const stage = el('div', 'stage'), zoom = el('div', 'zoom'), resultats = el('div', 'results'), panneau = el('div', 'panel'); el('div', 'hdr-ext'); const recherche = el('input', 'search');
const ong0 = S.coquille ? S.coquille.onglet0 || S.onglet || 'equipe' : S.onglet || 'equipe';
D.body.className = 'vf-tab-' + ong0;
const loc = { hash: S.hash || '', pathname: '/equipe.html', reload() { journal.rechargements = (journal.rechargements || 0) + 1; } };
const mem = (init) => { const m = new Map(Object.entries(init || {})); return { getItem: (k) => (m.has(k) ? m.get(k) : null), setItem: (k, v) => { journal.stockage.push(k); m.set(k, String(v)); }, removeItem: (k) => m.delete(k), _m: m }; };
const session = mem(S.sessionStorage), local = mem({});
const h = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const hand = {}, noeuds = [];
const appelSC = (n, f) => (...a) => { journal.sc.push(n); return f ? f(...a) : undefined; };
const SC = { selected: null, graph: { meta: { vfTab: ong0, vf: {} }, nodes: noeuds, project: { name: 'p' } }, h, setOverview: appelSC('setOverview'), addPanelSection() {}, rerender: appelSC('rerender', async () => {}),
  on: (e, f) => { (hand[e] ||= []).push(f); }, exists: (id) => noeuds.includes(id), reveal: (id) => journal.reveals.push(id), toast: (m) => journal.toasts.push(m), closePanel() { journal.sc.push('closePanel'); panneau.replaceChildren(); },
  showPanel(html, bind) { journal.sc.push('showPanel'); journal.panneauHtml = html; panneau.replaceChildren(); if (bind) bind(panneau); } };
const tick = () => new Promise((r) => setImmediate(r));
// fetch factice : enregistre l'URL et les en-têtes, rend le transcript du scénario
const fetchF = async (url, opts = {}) => { journal.fetchs.push({ url: String(url), entetes: Object.values((opts && opts.headers) || {}) }); return { ok: true, status: 200, json: async () => S.transcript || { fil: [{ genre: 'message', texte: 'texte du transcript factice' }] } }; };
Object.assign(W, { Floorplan: SC, FLOORPLAN_SERVER: S.serveur === false ? undefined : { token: JETON }, location: loc, sessionStorage: session, localStorage: local, fetch: fetchF,
  EventSource: class { addEventListener() {} close() {} } });
// VF_ETAT simulé d'après ui/70-vf-etat.js (79-17) : lire(cle) (who = l'objet, lock = { seq, verrous: { liste } }, connexion = 'ouvert'|'perdu'|'reprise'), abonner(cle, rappel) rend
// le désabonnement, abonnes(), jeton(), lireJson(chemin) (GET avec l'en-tête x-vf-cockpit-token)
const notifier = (cle) => { for (const f of [...(abos.get(cle) || [])]) f(); };
if (S.source === 'etat') W.VF_ETAT = { lire: (k) => (k === 'who' ? etat.who : k === 'lock' ? { seq: 1, verrous: { etat: 'lue', plat: false, liste: etat.lock || [] } } : k === 'connexion' ? etat.connexion : null),
  abonner: (k, f) => { if (!abos.has(k)) abos.set(k, new Set()); abos.get(k).add(f); return () => abos.get(k).delete(f); }, jeton: () => JETON, abonnes: () => ({}),
  lireJson: async (url) => { const r = await fetchF(url, { headers: { 'x-vf-cockpit-token': JETON } }); return r.json(); } };
etat.who = S.who || null; etat.lock = S.lock || null;
if (S.source !== 'etat') W.__vfLive = { who: etat.who, whoAt: horloge.now, lock: etat.lock, connected: true };
if (S.onglets) W.VF_ONGLETS = { aller() {} };
Object.defineProperty(W, 'VF_PANNEAU', { get() { compteurs.panneauLu++; return undefined; }, configurable: true });
// VF_SURCOUCHES simulé (80-02) : 'pile' ferme la surcouche du dessus à Échap (capture sur window, preventDefault puis stopPropagation) ; 'terminal' : ouverte() vrai, l'appui passe intact
if (S.surcouches) {
  const pile = [];
  W.VF_SURCOUCHES = { ouvrir(e, o = {}) { journal.surcouches.push({ op: 'ouvrir', modale: o.modale, ouvreur: o.ouvreur && o.ouvreur.closest ? (o.ouvreur.closest('li[data-vf-cle]') || {}).dataset?.vfCle : null, tagOuvreur: o.ouvreur && o.ouvreur.tagName }); pile.push({ e, fermer: o.fermer }); },
    fermer(e) { const i = pile.findIndex((x) => x.e === e); if (i >= 0) pile.splice(i, 1); journal.surcouches.push({ op: 'fermer' }); },
    ouverte() { compteurs.ouverteLue++; return S.surcouches === 'terminal' ? true : S.ouverteForcee === true ? true : pile.some((x) => x.fermer); }, dessus: () => null, couverte: () => false };
  const pileEchap = (ev) => { if (ev.key !== 'Escape' || S.surcouches !== 'pile') return; const t = pile.filter((x) => x.fermer).pop(); if (t) { pile.splice(pile.indexOf(t), 1); journal.surcouches.push({ op: 'fermee-par-pile' }); t.fermer(); ev.preventDefault(); ev.stopPropagation(); } };
  pileEchap._h = true; W.addEventListener('keydown', pileEchap, true);
}
// VF_COQUILLE simulé (A30, A51) : surOnglet(rappel, { cle }) ; une cle déjà inscrite est remplacée (l'ancien nettoyage d'abord) ; rappel appelé tout de suite si la coquille est prête
const ins = []; let affiche = S.coquille ? ong0 : null;
const appeler = (i) => { const r = i.rappel({ onglet: affiche }); i.nettoyage = typeof r === 'function' ? r : null; };
const nettoyer = (i) => { const f = i.nettoyage; i.nettoyage = null; if (f) f(); };
if (S.coquille) { W.VF_COQUILLE = { onglet: () => affiche, surOnglet(rappel, o) { const cle = o && o.cle;
  const old = cle === undefined ? null : ins.find((x) => x.cle === cle); if (old) { nettoyer(old); ins.splice(ins.indexOf(old), 1); }
  const i = { rappel, cle, nettoyage: null }; ins.push(i); journal.inscriptions = ins.map((x) => x.cle); appeler(i); return () => { nettoyer(i); ins.splice(ins.indexOf(i), 1); }; } }; }
const ctx = vm.createContext(W);
const charger = () => { for (const f of FICHIERS) vm.runInContext(fs.readFileSync(path.join(ui, f), 'utf8'), ctx, { filename: f, timeout: 5000 }); };
// journal des événements de la page et annulation demandée
let annulees = new Set();
const consigner = (ev) => { journal.evts.push({ type: ev.type, id: ev.detail && ev.detail.id, kind: ev.detail && ev.detail.kind, declencheur: ev.detail && ev.detail.declencheur, cancelable: ev.cancelable }); };
const annuler = (ev) => { if (annulees.has(ev.detail && ev.detail.declencheur)) ev.preventDefault(); };
consigner._h = true; annuler._h = true;
for (const t of ['vf-agent:ouvrir', 'vf-agent:lu']) D.addEventListener(t, consigner);
D.addEventListener('vf-agent:ouvrir', annuler);
const q = (sel, i = 0) => D.querySelectorAll(sel)[i] || null;
const cacheDe = (e) => { for (let n = e; n && n.nodeType === 1; n = n.parentNode) if (n.hasAttribute('hidden') || (n.style && n.style.display === 'none')) return true; return false; };
const ser = (e) => (e.nodeType === 3 ? e.data : `<${e.localName}${e.attributs.sort((a, b) => (a[0] < b[0] ? -1 : 1)).map(([k, v]) => ` ${k}="${v}"`).join('')}>${e.childNodes.map(ser).join('')}</${e.localName}>`);
const ficheFocus = () => { const a = D.activeElement; const li = a.closest && a.closest('li[data-vf-cle]'), sec = a.closest && a.closest('section[data-vf-section]');
  return { tag: a.tagName, id: a.id, cle: li ? li.dataset.vfCle : null, section: sec ? sec.dataset.vfSection : null, texte: a.textContent.slice(0, 60) }; };
const obs = (o) => {
  const n = o.sel ? D.querySelectorAll(o.sel) : [];
  switch (o.mode) {
    case 'compte': return n.length; case 'existe': return n.length > 0;
    case 'textes': return n.map((x) => x.textContent); case 'attr': return n.map((x) => x.getAttribute(o.attr));
    case 'visibles': return n.filter((x) => !cacheDe(x)).map((x) => x.textContent);
    case 'visiblesAttr': return n.filter((x) => !cacheDe(x)).map((x) => x.getAttribute(o.attr)); case 'ser': return n.length ? ser(n[0]) : null;
    case 'focus': return ficheFocus(); case 'marques': return n.filter((x) => x._m).length;
    case 'trouve': return { textes: n.reduce((c, x) => c + x.querySelectorAll('*').concat([x]).filter((y) => y.childNodes.some((k) => k.nodeType === 3 && k.data.includes(o.contient))).length, 0),
      attrs: n.reduce((c, x) => c + x.querySelectorAll('*').concat([x]).reduce((d, y) => d + y.attributs.filter(([, v]) => v.includes(o.contient)).length, 0), 0) };
    case 'classes': return n.map((x) => x.className); case 'sansAttr': return n.filter((x) => !x.hasAttribute(o.attr)).length;
    default: return JSON.parse(JSON.stringify({ ...journal, ...compteurs, ecouteurs: dom.ecouteurs(), types: dom.types(), minuteries: dom.minuteries(), violations: dom.violations, defilements: dom.defilements.map((d) => (d.el.closest('li[data-vf-cle]') || { dataset: {} }).dataset.vfCle || d.el.localName),
      appels: dom.appels, ecritures: dom.ecritures(), corps: D.body.className, abonnes: Object.fromEntries([...abos].map(([k, v]) => [k, v.size])), panneau: panneau.textContent, recherche: recherche.value,
      selection: SC.selected, monte: W.__vfRegie && W.__vfRegie.monte ? W.__vfRegie.monte() : null, fiche: ficheFocus() }));
  }
};
const sortie = {};
try {
  charger();
  for (const e of S.etapes || []) {
    let r;
    try {
      if (e.poser) { etat.who = e.poser.who; if (e.poser.lock !== undefined) etat.lock = e.poser.lock;
        if (S.source === 'etat') { notifier('who'); notifier('lock'); } else { W.__vfLive.who = etat.who; W.__vfLive.whoAt = horloge.now; W.__vfLive.lock = etat.lock; D.dispatchEvent(new Evt('vf-who')); } }
      else if (e.conn) { if (S.source === 'etat') { etat.connexion = e.conn; notifier('connexion'); } else { W.__vfLive.connected = e.conn === 'ouvert'; D.dispatchEvent(new Evt('vf-who')); } }
      else if (e.avancer !== undefined) dom.avancer(e.avancer);
      else if (e.clic) q(e.clic, e.indice || 0).click();
      else if (e.focus) q(e.focus, e.indice || 0).focus();
      else if (e.touche) { const cible = e.sur ? q(e.sur) : D.activeElement; const ev = new Evt('keydown', { bubbles: true, cancelable: true, key: e.touche }); if (e.prevenu) ev.preventDefault(); if (e.sur && !e.prevenu) cible.focus(); cible.dispatchEvent(ev); r = { prevenu: ev.defaultPrevented }; }
      else if (e.saisie) { const c = q(e.saisie); c.value = e.valeur; c.dispatchEvent(new Evt('input', { bubbles: true })); }
      else if (e.evenement) { const ev = new Evt(e.evenement, { bubbles: true, cancelable: !!e.annulable, detail: e.detail }); (e.sur === 'window' ? W : D).dispatchEvent(ev); r = { prevenu: ev.defaultPrevented }; }
      else if (e.vfOnglet) { if (e.hash !== undefined) loc.hash = e.hash; D.dispatchEvent(new Evt('vf:onglet', { detail: { onglet: e.vfOnglet } })); }
      else if (e.hash !== undefined) { loc.hash = e.hash; W.dispatchEvent(new Evt('hashchange')); }
      else if (e.onglet) { affiche = e.onglet; SC.graph.meta.vfTab = e.onglet; D.body.className = D.body.className.replace(/vf-tab-\w+/, 'vf-tab-' + e.onglet); for (const i of ins.slice()) nettoyer(i); for (const i of ins.slice()) appeler(i); }
      else if (e.declarerVue) { const v = e.declarerVue; W.__vfEquipeVues.declarer({ id: v.id, libelle: v.libelle, monter(c) { journal.vues.push('monter:' + v.id); c.textContent = 'vue ' + v.id; }, demonter() { journal.vues.push('demonter:' + v.id); } }); }
      else if (e.selectionner) SC.selected = e.selectionner;
      else if (e.annuler) annulees = new Set(e.annuler);
      else if (e.marquer) for (const x of D.querySelectorAll(e.marquer)) x._m = true;
      else if (e.raz) { dom.razEcritures(); journal.fetchs.length = 0; journal.evts.length = 0; journal.surcouches.length = 0; dom.defilements.length = 0; }
      else if (e.appel) { const [o, f] = [e.appel.split('.').slice(0, -1).reduce((a, k) => a[k], W), e.appel.split('.').pop()]; r = o[f](...(e.args || [])); }
      else if (e.reexecuter) { for (const k of ['__vfRegie', '__vfEquipeVues', '__vfRegiePied', '__vfRegieModele', '__vfEquipeRendu']) delete W[k]; charger(); }
      else if (e.obs) r = obs(e.obs);
    } catch (x) { r = { erreur: String((x && x.message) || x).slice(0, 160) }; }
    await tick(); await tick();
    if (e.nom) sortie[e.nom] = r === undefined ? obs({}) : r;
  }
  dire({ out: sortie, final: obs({}) });
} catch (e) { dire({ erreur: String((e && e.message) || e).slice(0, 200) }); }
