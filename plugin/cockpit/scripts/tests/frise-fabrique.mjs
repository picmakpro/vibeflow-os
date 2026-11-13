// frise-fabrique.mjs : fabrique de fixtures SYNTHETIQUES en mémoire pour la frise (Phase 74, plan 74-01), utilisée par les suites 74-04 à 74-07.
// Formes : `vibeflow/cockpit-frise@1` (C3 et ses amendements A43, A45, A48 de 79-CONTEXT), `signal.missions[]`, fil réduit de `cockpit-transcript@2`
// (74-02), `vibeflow/cockpit-git@1` réduit aux champs lus. Aucune horloge réelle, aucun Math.random : tout est dérivé de NOW.
// Usage module : import { fabrique, voie, quiMissions, quiPhases, fil, git, rangee } ; usage ligne de commande :
//   node frise-fabrique.mjs frise|missions|phases|fil|git [options JSON] -> JSON sur stdout.
// A REVALIDER sur la forme réellement écrite par 79-13 (champs de voie, `cibles.tronque`, `voiesOmises`, queue `attend-humain`).
import { pathToFileURL } from 'node:url';

export const SCHEMA = 'vibeflow/cockpit-frise@1';
export const NOW = Date.UTC(2026, 10, 13, 14, 0, 0);
export const MIN = 60000;
export const FENETRE = 86400000;

const ZERO = { appels: 0, erreurs: 0, refus: 0, questions: 0, compactions: 0, tours: 0, reponsesApi: 0 };

// Une voie à la forme C3 : segments `[debutMs, finMs, genre]`, événements `[tMs, genre]`. `attend: true` pose la queue `attend-humain` de `fin` à `jusqua` (A43).
export function voie(o = {}) {
  const debut = o.debut ?? NOW - 30 * MIN;
  const fin = o.fin ?? NOW;
  const v = {
    id: 'ag-0001', kind: 'subagent', session: 'sess-1', parent: null, depth: 1, role: 'vf-coder', arbre: null, background: false,
    debut, fin, dispatchA: null, fini: false, arrete: false, etatOfficiel: null, modeles: ['sonnet'],
    compteurs: { ...ZERO }, jetons: { entree: 1000, sortie: 200, cacheLu: 5000, cacheCree: 300, contexteMax: 40000, contexteDernier: 30000 },
    durees: { travailS: 600, attenteHumainS: 0, attenteAgentsS: 0, reposS: 0, silenceS: 0 },
    segments: [[debut, fin, 'travail']], evenements: [], enCours: null, rattachement: null,
    cibles: { etat: 'ok', tronque: false, ecritures: [], lectures: [] },
    ...o,
  };
  if (o.attend) v.segments = [...v.segments, [v.fin, o.jusqua ?? NOW, 'attend-humain']];
  delete v.attend; delete v.jusqua;
  return v;
}

export const entree = (cible, dernierMs, extra = {}) => ({ arbre: null, cible, n: 1, dernierMs, ...extra });

// Une tête, un manager `enfants`, deux workers rattachés, un worker en attente de l'humain, un hors `who` (id inconnu de la régie), un tronqué à gauche.
export function voiesParDefaut(now = NOW) {
  const d = (m) => now - m * MIN;
  return [
    voie({ id: 'sess-1', kind: 'session', role: null, depth: null, debut: d(80), fin: now, segments: [[d(80), d(60), 'travail'], [d(60), now, 'repos']] }),
    voie({ id: 'mg-1', parent: 'sess-1', dispatchA: d(70), debut: d(70), fin: now, segments: [[d(70), now, 'attend-agents']],
      rattachement: { dag: 'm1.md', noeud: null, source: 'enfants' } }),
    voie({ id: 'wk-1', parent: 'mg-1', depth: 2, dispatchA: d(65), debut: d(65), fin: d(30), fini: true, segments: [[d(65), d(30), 'travail']],
      rattachement: { dag: 'm1.md', noeud: 'n1', source: 'registre' }, cibles: { etat: 'ok', tronque: false, ecritures: [entree('a.js', d(40))], lectures: [] } }),
    voie({ id: 'wk-2', parent: 'mg-1', depth: 2, dispatchA: d(50), debut: d(50), fin: d(20), attend: true, segments: [[d(50), d(20), 'travail']],
      rattachement: { dag: 'm1.md', noeud: 'n2', source: 'mandat' } }),
    voie({ id: 'hw-1', parent: 'sess-1', dispatchA: d(45), debut: d(45), fin: d(44), fini: true, segments: [[d(45), d(44), 'travail']], cibles: null }),
    voie({ id: 'lf-1', parent: 'sess-1', dispatchA: d(95), debut: d(95), fin: d(85), fini: true, segments: [[d(95), d(85), 'travail']], arbre: 'wt-a' }),
  ];
}

export function fabrique({ now = NOW, voies, tronque = false, voiesOmises = 0, schema = SCHEMA, sourceEtat = 'ok' } = {}) {
  return {
    schema, at: now, depuis: now - FENETRE, jusqua: now, fenetreS: FENETRE / 1000,
    source: { etat: sourceEtat, ccVerifie: true, versionsVues: ['2.1.317'] },
    tronque, voiesOmises, voies: voies ?? voiesParDefaut(now),
  };
}

// `signal.missions[]` : `fichier` joint `rattachement.dag` (A8), `phaseKey` joint `phases[].key`, `noeuds` seulement pour les états qui en portent.
export function quiMissions(n = 8) {
  const noeuds = Array.from({ length: n }, (_, i) => ({ id: `n${i + 1}`, status: 'pending', step: '', stage: '', deps: [] }));
  return [
    { nom: 'Mission un', fichier: 'm1.md', phaseKey: '74', ws: null, etat: 'en-cours', libelle: 'en cours', vie: null, noeuds },
    { nom: 'Mission deux', fichier: 'm2.md', phaseKey: null, ws: null, etat: 'planifiee', libelle: 'planifiée', vie: null },
  ];
}
export const quiPhases = () => [{ key: '74', n: 74, ws: null, nom: "L'équipe dans le temps", fait: false }];

// Fil réduit (74-02) : éléments datés ; une entrée regroupée porte `n` > 1.
export const element = (t, o = {}) => ({ t, genre: 'outil', outil: 'Edit', verbe: 'modifie', cible: 'a.js', ...o });
export function fil(id = 'ag-0001', { elements, tronque = false, now = NOW } = {}) {
  return { id, fil: elements ?? [element(now - 20 * MIN, { n: 1 }), { t: now - 10 * MIN, genre: 'message', texte: 'rapport' }], tronque };
}

// `cockpit-git@1` réduit : `rangees[{h, p, at (SECONDES), s, refs[{type, nom}]}]`, `bornes.tronque`, `base.nom`.
export const rangee = (h, p, atSec, refs = [], s = `commit ${h}`) => ({ h, h7: h.slice(0, 7), p, at: atSec, s, refs });
export const tete = (type, nom) => ({ type, nom, courante: false, worktree: null, commande: null });
export function git({ rangees, tronque = false, base = 'main', now = NOW } = {}) {
  const s = Math.floor(now / 1000);
  return {
    schema: 'vibeflow/cockpit-git@1', etat: 'ok', base: { nom: base }, bornes: { base: 500, nonMergees: 500, tronque },
    rangees: rangees ?? [
      rangee('m3', ['m2'], s - 600, [tete('locale', 'main')]), rangee('f2', ['f1'], s - 700, [tete('locale', 'feat')]),
      rangee('m2', ['m1'], s - 900), rangee('f1', ['m2'], s - 1000), rangee('m1', [], s - 1200),
    ],
  };
}

const SORTIES = { frise: fabrique, missions: () => quiMissions(), phases: quiPhases, fil, git };
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const f = SORTIES[process.argv[2]];
  if (!f) { process.stderr.write('usage : frise-fabrique.mjs frise|missions|phases|fil|git [options JSON]\n'); process.exit(2); }
  const opts = process.argv[3] ? JSON.parse(process.argv[3]) : undefined;
  process.stdout.write(JSON.stringify(opts === undefined ? f() : f(opts)) + '\n');
}
