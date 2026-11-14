#!/usr/bin/env node
// echec-onglet-sonde.mjs <dossier ui/ du moteur> — aide de test-cockpit-echec-onglet.sh, SANS Chrome (vm de Node, coquille et moteur factices).
// Évalue ui/00-vf-onglets.js et ui/07-vf-reessayer.js et imprime UN objet JSON, que la suite lit avec E :
//   reessayer : { temoin, rejet }  VF_ONGLETS.reessayer() se résout quand la relance réussit et REJETTE quand elle échoue encore
//   compteur  : { temoin, zero }   après un aller() rejeté, un popstate interne à l'onglet affiché est laissé au moteur (ni arrêté, ni chargement)
//   palette   : { source, sans, rangee, relance } la rangée « Réessayer » de la palette appelle VF_ONGLETS.reessayer une fois et ne rejette jamais
// Chaque cas a son témoin positif (même scénario sans échec, ou avant l'échec) : un vert n'est jamais à vide.
import fs from 'node:fs'; import path from 'node:path'; import vm from 'node:vm';
const ui = process.argv[2] || '';
const lire = (f) => fs.readFileSync(path.join(ui, f), 'utf8');
const tour = () => new Promise((r) => setImmediate(r));
const tours = async (n) => { for (let i = 0; i < n; i++) await tour(); };

function monde({ affiche = 'code', chemin = '/' } = {}) {
  const ecoutes = {}, appels = []; let etat = { onglet: affiche, phase: 'pret', motif: null }, courant = affiche, issue = 'ok';
  const location = { pathname: chemin, search: '', hash: '', origin: 'http://127.0.0.1:1' };
  const poser = (u) => { const x = new URL(u, 'http://127.0.0.1:1' + location.pathname); location.pathname = x.pathname; location.search = x.search; location.hash = x.hash; };
  const history = { pushState(_, __, u) { poser(u); }, replaceState(_, __, u) { poser(u); } };
  const C = {
    etat: () => ({ ...etat }), onglet: () => courant, surOnglet: () => () => {},
    chargerOnglet: (nom) => {
      appels.push(nom);
      if (issue === 'ok') { courant = nom; etat = { onglet: nom, phase: 'pret', motif: null }; return Promise.resolve(); }
      etat = { onglet: nom, phase: 'echec', motif: 'lecture' }; return Promise.reject(new Error('Lecture impossible'));
    },
  };
  const mk = () => ({ addEventListener: (t, f) => { (ecoutes[t] ||= []).push(f); }, removeEventListener() {} });
  const document = { ...mk(), baseURI: 'http://127.0.0.1:1/', getElementById: () => null, dispatchEvent: () => true };
  const window = { ...mk(), VF_COQUILLE: C, document, history, location, URL, console: { error() {} }, CustomEvent: class { constructor(t, o) { this.type = t; this.detail = o && o.detail; } } };
  Object.assign(window, { window, Promise, setTimeout, Map, Object, String, Number, Array });
  vm.createContext(window); vm.runInContext(lire('00-vf-onglets.js'), window, { filename: '00-vf-onglets.js' });
  return { window, C, appels, ecoutes, location, regler: (x) => { issue = x; } };
}
const issue = async (p) => { try { await p; return 'resolu'; } catch { return 'rejete'; } };
const popstate = (m) => { let arrete = false; const ev = { stopImmediatePropagation: () => { arrete = true; } }; for (const f of m.ecoutes.popstate || []) f(ev); return arrete; };
const o = {};

{ // reessayer : le rejet d'une relance qui échoue encore n'est pas avalé
  const t = monde(); t.regler('ko'); await issue(t.window.VF_ONGLETS.aller('projet')); await tour();
  t.regler('ok'); const rt = await issue(t.window.VF_ONGLETS.reessayer()); await tour();
  o.reessayer = { temoin: [rt, t.C.onglet()] };
  const m = monde(); m.regler('ko'); await issue(m.window.VF_ONGLETS.aller('projet')); await tour();
  const avant = m.appels.length, r = await issue(m.window.VF_ONGLETS.reessayer()); await tour();
  o.reessayer.rejet = [r, m.appels.length - avant];
}
{ // compteur : le chargement rejeté libère le compteur, un popstate interne à l'onglet affiché reste au moteur
  const m = monde(); m.location.hash = '#s=a'; const avant = popstate(m); await tour();
  o.compteur = { temoin: [avant, m.appels.length] };
  m.regler('ko'); const r = await issue(m.window.VF_ONGLETS.aller('projet')); await tours(5);
  const n0 = m.appels.length; m.location.pathname = '/'; m.location.hash = '#s=b';
  const apres = popstate(m); await tours(5);
  o.compteur.zero = [r, apres, m.appels.length - n0];
}
{ // palette : la rangée « Réessayer » relance vraiment (la suite de Chrome presse Entrée sur le bouton de la ligne d'état, pas sur cette rangée)
  const sources = [], relances = []; let ech = null;
  const w = { Floorplan: { ajouterSource: (f) => sources.push(f) }, VF_ONGLETS: { echec: () => ech, reessayer: () => { relances.push(1); return Promise.reject(new Error('encore en échec')); } }, String, Promise, console: { error() {} } };
  w.window = w; vm.createContext(w); vm.runInContext(lire('07-vf-reessayer.js'), w, { filename: '07-vf-reessayer.js' });
  o.palette = { source: sources.length };
  if (sources.length === 1) {
    o.palette.sans = sources[0]({ vide: true, termes: [] }).length;
    ech = Object.freeze({ onglet: 'projet', affiche: 'code' });
    const rangs = sources[0]({ vide: true, termes: [] });
    o.palette.rangee = rangs.map((r) => r.libelle + '|' + r.detail);
    let leve = null, rejet = false;
    try { const r = rangs[0] && rangs[0].executer(); if (r && typeof r.then === 'function') await r.then(() => {}, () => { rejet = true; }); } catch (e) { leve = e.message; }
    await tour(); o.palette.relance = [relances.length, leve, rejet];
  }
}
process.stdout.write(JSON.stringify(o));
