// vf-cockpit-activite-gardes — lentille « Gardes » (ACTV-07, P75-D-16, P75-D-17) : quels fichiers de code une suite ou un gate nomme, lesquels
// n'ont aucun témoin, lesquels sont eux-mêmes une garde. Lecture seule, confinée au lab : le module ne lance que `git ls-files` (lecture bornée du
// socle) et n'exécute JAMAIS un script du lab (P68-D-34). Il détecte les gardes de test (règle de citation de la CI) ; ce n'est pas une garde de sécurité.
// Exports : CLASSES_GARDE, estGarde, estSuite, globLineaire, decouvrirSuites, gatesDeCi, contexteGardes, suitesQuiNomment, calculerGardes.
// Règle de citation = scripts/ci-suites-perimetre.sh sans sa part « module » (sur-sélection voulue en CI, hors témoin) :
//   1. une suite cite m quand son texte CONTIENT m (grep -lF : sous-chaîne, pas un mot) ;
//   2. un nom est ambigu quand au moins deux fichiers suivis le portent (+1 si le chemin n'est plus suivi) ;
//   3. f est nommé par les suites qui citent son chemin, ou son nom si non ambigu ; ambigu : le nom ET (le dossier OU le module plugin/<m>) ;
//   4. un motif de chemin écrit dans une suite (jeton avec « * » visant plugin/) nomme tout fichier qu'il couvre (`case` : * traverse /).
// Le motif d'une suite n'est JAMAIS compilé en RegExp (ReDoS) : correspondance itérative à un point de reprise, jetons coupés à la main.
// « Suites » = corpus : suites découvertes (même motif que `ci-shard-suites.sh --all`) + gates de `.github/workflows/ci.yml` (D-16).
import fs from 'node:fs';
import path from 'node:path';
import { lireConfine, read, lister } from './vf-cockpit-planning.mjs';
import { lancerGitAsync, finDans } from './vf-cockpit-paths.mjs';

const BUDGET_MS = 8; // tranche de calcul avant de rendre la main à la boucle d'événements du serveur (calculerGardes cède entre deux fichiers)
const PLAFOND_TRAVAIL = 30e6; // motifs x fichiers ; au-delà : `tronque`, jamais une liste partielle présentée comme complète
const MAX_ENTREES = 20000; // entrées parcourues sous plugin/ et scripts/ ; au-delà : indisponible, jamais une liste partielle
const IGNORES = new Set(['.git', 'node_modules']);
const comparer = (a, b) => Buffer.compare(Buffer.from(a), Buffer.from(b)); // LC_ALL=C : l'ordre des octets UTF-8 = celui des points de code
const trier = (l) => l.sort(comparer);

// Les six classes de scripts/check-gate-touche.sh (classify), UN tableau, confronté au script par la suite (P1). `seg` : un seul segment, reste > `min`.
export const CLASSES_GARDE = [
  { classe: 'gate-conductor', pre: 'plugin/conductor/scripts/', deb: 'check-', fin: '.sh', seg: true, min: 9 },
  { classe: 'gate-scripts', pre: 'scripts/', deb: 'check-', fin: '.sh', seg: true, min: 9 },
  { classe: 'suite', pre: 'plugin/conductor/scripts/tests/', deb: 'test-', fin: '.sh', seg: true, min: 8 },
  { classe: 'suite', pre: 'scripts/tests/', deb: 'test-', fin: '.sh', seg: true, min: 8 },
  { classe: 'ci', exact: '.github/workflows/ci.yml' },
  { classe: 'hooks', pre: 'scripts/hooks/' },
  { classe: 'fixtures', pre: 'plugin/conductor/scripts/tests/fixtures/' },
  { classe: 'fixtures', pre: 'scripts/tests/fixtures/' },
];
const dans = (e, p) => {
  if (e.exact) return p === e.exact;
  if (!p.startsWith(e.pre)) return false;
  if (e.deb === undefined) return true;
  const r = p.slice(e.pre.length);
  return r.startsWith(e.deb) && r.endsWith(e.fin) && r.length >= e.deb.length + e.fin.length && !r.includes('/') && r.length > e.min;
};
export const estGarde = (p) => CLASSES_GARDE.some((e) => dans(e, p));

// `find plugin scripts -type f -path '*/tests/test-*.sh'` : `*` traverse `/` et peut être vide ; test de chaîne, aucune RegExp construite
const PRE_SUITE = '/tests/test-';
export const estSuite = (p) => {
  const i = p.indexOf(PRE_SUITE);
  return (p.startsWith('plugin/') || p.startsWith('scripts/')) && i >= 0 && p.endsWith('.sh') && p.length >= i + PRE_SUITE.length + 3;
};

// Découverte : marche `lstat` (un lien symbolique n'est ni suivi ni compté, comme `find -type f`), `.git` et `node_modules` sautés.
export function decouvrirSuites(lab) {
  const suites = []; let vus = 0, tronque = false;
  const marche = (rel) => {
    for (const nom of lister(path.join(lab, rel))) {
      if (tronque) return;
      if (++vus > MAX_ENTREES) { tronque = true; return; }
      if (IGNORES.has(nom)) continue;
      const r = rel + '/' + nom; let st;
      try { st = fs.lstatSync(path.join(lab, r)); } catch { continue; }
      if (st.isDirectory()) marche(r); else if (st.isFile() && estSuite(r)) suites.push(r);
    }
  };
  for (const top of ['plugin', 'scripts']) { try { if (fs.lstatSync(path.join(lab, top)).isDirectory()) marche(top); } catch { /* absent */ } }
  return { suites: trier(suites), tronque };
}

// Gates : jetons `[\w./-]*check-[\w.-]+\.sh` de ci.yml (lus à la main : une RegExp à étoile en tête est quadratique),
// « ./ » retiré, gardés s'ils sont suivis.
export function gatesDeCi(lab, suivis) {
  const out = new Set();
  for (const run of read(path.join(lab, '.github/workflows/ci.yml')).split(/[^\w./-]+/)) {
    for (let p = run.lastIndexOf('check-'); p >= 0; p = p > 0 ? run.lastIndexOf('check-', p - 1) : -1) {
      const barre = run.indexOf('/', p + 6), seg = run.slice(p + 6, barre < 0 ? run.length : barre), k = seg.lastIndexOf('.sh');
      if (k < 1) continue;
      let j = run.slice(0, p + 6 + k + 3); if (j.startsWith('./')) j = j.slice(2);
      if (suivis.has(j)) out.add(j);
      break;
    }
  }
  return trier([...out]);
}

// --- correspondance glob de `case` : * (traverse /), ?, [..], \x ; UN point de reprise (la dernière étoile), jamais de retour arrière exponentiel ---
function unite(p, i, c) { // le jeton de motif en `i` accepte-t-il le caractère c ? → { ok, next }
  const k = p[i];
  if (k === '?') return { ok: true, next: i + 1 };
  if (k === '\\' && i + 1 < p.length) return { ok: p[i + 1] === c, next: i + 2 };
  if (k !== '[') return { ok: k === c, next: i + 1 };
  let j = i + 1; const neg = p[j] === '!' || p[j] === '^'; if (neg) j++;
  const d = j; let trouve = false;
  for (; j < p.length && (p[j] !== ']' || j === d); j++) {
    if (p[j + 1] === '-' && j + 2 < p.length && p[j + 2] !== ']') { if (c >= p[j] && c <= p[j + 2]) trouve = true; j += 2; } else if (p[j] === c) trouve = true;
  }
  if (j >= p.length) return { ok: c === '[', next: i + 1 }; // classe non fermée : « [ » littéral
  return { ok: trouve !== neg, next: j + 1 };
}
export function globLineaire(p, s) {
  let i = 0, j = 0, etoileP = -1, etoileS = 0;
  while (j < s.length) {
    if (p[i] === '*') { while (p[i] === '*') i++; etoileP = i; etoileS = j; continue; }
    const r = i < p.length ? unite(p, i, s[j]) : null;
    if (r && r.ok) { i = r.next; j++; continue; }
    if (etoileP < 0) return false;
    i = etoileP; j = ++etoileS;
  }
  while (p[i] === '*') i++;
  return i === p.length;
}

// --- motifs de chemin écrits dans un texte (glob.awk du script) ---
const lettre = (c) => c !== undefined && ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || c === '_');
// fin de la dernière occurrence de `${?[A-Za-z_]*PLUGIN[A-Za-z_]*}?/` (jamais de RegExp : sans borne, retour arrière quadratique)
function finVariablePlugin(t) {
  let fin = -1;
  for (let i = t.indexOf('$'); i >= 0; i = t.indexOf('$', i + 1)) {
    let k = i + 1; if (t[k] === '{') k++;
    const d = k; while (lettre(t[k])) k++;
    if (!t.slice(d, k).includes('PLUGIN')) continue;
    if (t[k] === '}') k++;
    if (t[k] === '/') fin = k + 1;
  }
  return fin;
}
function motifsDe(texte) {
  const out = new Set();
  for (let pos = texte.indexOf('*'); pos >= 0; pos = texte.indexOf('*', pos)) {
    const d = texte.lastIndexOf('\n', pos) + 1; let f = texte.indexOf('\n', pos); if (f < 0) f = texte.length;
    for (let t of texte.slice(d, f).split(/[ \t]+/)) {
      if (!t.includes('*') || !t.toLowerCase().includes('plugin')) continue;
      t = t.replace(/["'();|<>`,]/g, '');
      if (t.includes('plugin/')) t = 'plugin/' + t.slice(t.lastIndexOf('plugin/') + 7);
      else { const e = finVariablePlugin(t); if (e < 0) continue; t = 'plugin/' + t.slice(e); }
      if (t.startsWith('plugin/') && t.includes('*')) out.add(t);
    }
    pos = f + 1;
  }
  return out;
}

// --- contexte : lu une fois par calcul (suites, gates, fichiers suivis, motifs) ---
// `git ls-files -z` : refusé, hors délai, tronqué, git absent, hors dépôt → null (jamais une liste devinée)
async function suivisDe(lab, fin) {
  const r = await lancerGitAsync(lab, ['ls-files', '-z'], { fin, maxBuffer: 64 << 20 });
  return r.ok ? r.sortie.split('\0').filter(Boolean) : null;
}
export async function contexteGardes(lab, { fin } = {}) {
  const liste = await suivisDe(lab, fin ?? finDans(20000));
  if (!liste) return { etat: 'indisponible', motif: 'git ls-files' };
  try {
    return lireConfine(lab, () => {
      const d = decouvrirSuites(lab);
      if (d.tronque) return { etat: 'indisponible', motif: 'parcours' };
      const suivis = new Set(liste), gates = gatesDeCi(lab, suivis);
      const corpus = trier([...new Set([...d.suites, ...gates])]);
      const textes = new Map(corpus.map((s) => [s, read(path.join(lab, s))]));
      const noms = new Map(), globs = new Map();
      for (const f of liste) { const n = f.slice(f.lastIndexOf('/') + 1); noms.set(n, (noms.get(n) || 0) + 1); }
      for (const [s, t] of textes) for (const m of motifsDe(t)) { if (!globs.has(m)) globs.set(m, []); globs.get(m).push(s); }
      return { etat: 'ok', ctx: { suites: d.suites, gates, corpus, textes, suivis, noms, globs, cache: new Map() } };
    });
  } catch { return { etat: 'indisponible', motif: 'lecture' }; }
}

const citeNom = (ctx, nom) => {
  let r = ctx.cache.get(nom);
  if (!r) { r = ctx.corpus.filter((s) => ctx.textes.get(s).includes(nom)); ctx.cache.set(nom, r); }
  return r;
};
// Les suites (et gates) qui nomment le fichier `f` : la règle 1 à 4, sans la part « module ». Tout est dans citeNom(nom) :
// le chemin, le dossier et le module n'ajoutent rien hors des suites qui citent déjà le nom (le nom est une sous-chaîne du chemin).
export function suitesQuiNomment(f, ctx) {
  const nom = f.slice(f.lastIndexOf('/') + 1), dir = f.includes('/') ? f.slice(0, f.lastIndexOf('/')) : f;
  let res = citeNom(ctx, nom);
  if ((ctx.noms.get(nom) || 0) + (ctx.suivis.has(f) ? 0 : 1) >= 2) {
    const mod = f.startsWith('plugin/') && f.indexOf('/', 7) >= 0 ? f.slice(7, f.indexOf('/', 7)) : null;
    res = res.filter((s) => { const t = ctx.textes.get(s); return t.includes(f) || t.includes(dir) || (mod !== null && t.includes(mod)); });
  }
  const sel = new Set(res);
  for (const [m, suites] of ctx.globs) {
    const motif = m.endsWith('/') ? m + '*' : m;
    if (globLineaire(motif, f) || globLineaire(motif + '/*', f)) for (const s of suites) sel.add(s);
  }
  return trier([...sel]);
}

// carteCode : le graph.json du cockpit (`meta.vfCodeExtractor`, `files[].p` chemin, `l` langage ou « docs », `st` « prevu » pour une carte prévue).
// Le calcul est COOPÉRATIF : il cède la main toutes les `budgetMs` (8 ms) et, au-delà de `plafond` (motifs x fichiers), rend `tronque` sans rien calculer.
// → { etat: 'ok' | 'non-lues' | 'indisponible' | 'tronque',
//     gardes: [[chemin, nbSuites, estGarde 1|0]] (code seulement : ni doc, ni suite, ni fixture, ni prévu),
//     estGarde: [chemin] (fichiers de la carte appartenant aux six classes) }. Lab non VibeFlow : « non-lues », jamais « tout sans témoin » (P75-D-17).
export async function calculerGardes(lab, carteCode, opts = {}) {
  const vide = (etat) => ({ etat, gardes: [], estGarde: [] });
  if (!carteCode || !carteCode.meta || carteCode.meta.vfCodeExtractor !== 'vibeflow') return vide('non-lues');
  const r = opts.ctx ? { etat: 'ok', ctx: opts.ctx } : await contexteGardes(lab, opts);
  if (r.etat !== 'ok') return vide(r.etat);
  const fichiers = Array.isArray(carteCode.files) ? carteCode.files : [];
  if (r.ctx.globs.size * fichiers.length > (opts.plafond ?? PLAFOND_TRAVAIL)) return vide('tronque'); // garde:gardes-plafond
  const budget = opts.budgetMs ?? BUDGET_MS, gardes = [], garde = [];
  let debut = Date.now();
  for (const f of fichiers) {
    if (Date.now() - debut >= budget) { await new Promise((ok) => setImmediate(ok)); debut = Date.now(); } // garde:gardes-cession
    if (!f || typeof f.p !== 'string' || f.st === 'prevu') continue;
    const g = estGarde(f.p);
    if (g) garde.push(f.p);
    if (f.l === 'docs' || estSuite(f.p) || f.p.split('/').includes('fixtures')) continue;
    gardes.push([f.p, suitesQuiNomment(f.p, r.ctx).length, g ? 1 : 0]);
  }
  gardes.sort((a, b) => comparer(a[0], b[0]));
  return { etat: 'ok', gardes, estGarde: trier(garde) };
}
