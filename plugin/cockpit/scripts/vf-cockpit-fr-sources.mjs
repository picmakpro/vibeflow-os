#!/usr/bin/env node
// vf-cockpit-fr-sources — porte de FICHIER du traducteur du cockpit (79-10, SOCL-14, P79-D-16, P79-D-24).
// Là où l'inventaire du rendu servi (vf-cockpit-fr-inventaire.mjs) dit « il reste de l'anglais quelque part », cet outil dit OÙ :
// un fichier du moteur (viewer.html, ui/*.js, serve.mjs), avant tout assemblage, rend la liste des sites fautifs avec fichier et ligne.
// Boucle de l'exécutant : l'enveloppe de chaque libellé dans `t('…')`, puis la table de traduction.
// Il n'est pas copié dans le lab (le nom commence par vf-cockpit-fr-).
// Genres de constat :
//   `libre` (littéral anglais qui ne passe pas par t, hors exclusion motivée) · `cle-sans-entree` (clé de t sans entrée de table ni exclusion) ·
//   `cle-non-litterale` (premier argument de t qui n'est pas un littéral : jamais une donnée du lab, S9) ·
//   `ombre` (déclaration locale de `t`, hors l'alias `const t = window.__vfFrT;`) ·
//   `squelette-sans-entree` (texte statique d'un .html sans entrée de table ni exclusion).
// Exports : chargerTable(dossierUi), constatsDe(src, { table, exclusions, fichier }).
// CLI : node vf-cockpit-fr-sources.mjs [--sans-entrees] [--table <fichier.js>] [--exclusions <fichier.json>] <fichier>…
//   sortie `fichier:ligne<TAB>genre<TAB>texte` ; code 0 sans constat, 1 sinon, 2 usage. `--sans-entrees` omet `cle-sans-entree` et `squelette-sans-entree`
//   (la table se complète après l'enveloppement). Table et exclusions du module par défaut.
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { litteraux, estAnglais, textesHtml } from './vf-cockpit-fr-inventaire.mjs';
import { renommerTexte } from './vf-cockpit-rename.mjs';

const ICI = path.dirname(fileURLToPath(import.meta.url));
const UI = path.resolve(ICI, '..', 'skills', 'cockpit-moteur', 'assets', 'ui');
const norm = (s) => s.replace(/\s+/g, ' ').trim();
const ligneDe = (src, pos) => { let n = 1; for (let k = src.indexOf('\n'); k >= 0 && k < pos; k = src.indexOf('\n', k + 1)) n++; return n; };

// la table : les blocs « // vibeflow:fr » qui posent window.__vfFrDict (le moteur de traduction lui-même est écarté), exécutés sans DOM
const tableDe = (...sources) => {
  const ctx = vm.createContext({}); ctx.window = ctx;
  for (const s of sources) vm.runInContext(s, ctx);
  return { ...(ctx.__vfFrDict || {}) };
};
export function chargerTable(dossierUi = UI) {
  const blocs = fs.readdirSync(dossierUi).filter((n) => n.endsWith('.js')).sort().map((f) => fs.readFileSync(path.join(dossierUi, f), 'utf8'));
  return tableDe(...blocs.filter((b) => b.split('\n', 1)[0] === '// vibeflow:fr' && /__vfFrDict/.test(b) && !/__vfFrTraduire\s*=/.test(b)));
}

// un littéral qui n'est pas une clé : ses textes anglais (un gabarit HTML est éclaté en nœuds de texte)
function libresDe(brut, texte) {
  if (/<[a-z!/][^>]*>/i.test(brut)) return textesHtml(brut).map(norm).filter((x) => x && estAnglais(x, true));
  const x = norm(brut); return x && estAnglais(x, texte) ? [x] : [];
}
const MARQUES = new RegExp('^\\s*(?:/\\* ui/[\\w.-]+ \\*/\\s*)?// (?:vibeflow:fr|vibeflow:allow-large-file|VibeFlow \\()|^\\s*// [\\w-]+ graph queries, shared by the viewer');
// mêmes lignes, jamais un journal
const sansJournal = (src) => src.split('\n').map((l) => (/console\.(log|error|warn|info)\(/.test(l) ? '' : l)).join('\n');
const LIGNE_MESSAGE = /\b(message|error|text|title|label)\s*:|new Error\(|\bplain\b/;

// les constats d'un script : décalage = position du script dans son fichier (une page .html en porte plusieurs)
function constatsScript(src, { decalage = 0, tout, table, exclus, hors }) {
  const L = litteraux(src), r = [], at = (pos) => ligneDe(tout, decalage + pos);
  L.forEach((v, k) => {
    if (L.cle[k]) {
      const c = L.cle[k];
      const entree = Object.prototype.hasOwnProperty.call(table, c) || exclus.has(c) || exclus.has(c.split('@')[0]);
      if (!entree) r.push({ ligne: at(L.pos[k]), genre: 'cle-sans-entree', texte: c });
    } else for (const x of libresDe(v, L.cles.has(v))) if (!exclus.has(x)) r.push({ ligne: at(L.pos[k]), genre: 'libre', texte: x });
  });
  for (const a of L.appels) r.push({ ligne: at(a.pos), genre: 'cle-non-litterale', texte: a.texte });
  for (const a of L.ombres) if (L.alias && !hors) r.push({ ligne: at(a.pos), genre: 'ombre', texte: a.texte });
  return r;
}

export function constatsDe(source, { table = {}, exclusions = [], fichier = '' } = {}) {
  const src = renommerTexte(source); // le rendu servi est renommé à l'assemblage : les textes, les clés et les exclusions se jugent sous leur forme servie (mêmes lignes)
  const exclus = new Set(exclusions.map((e) => (typeof e === 'string' ? e : e.texte)));
  const r = [], o = { table, exclus, tout: src };
  if (/\.html?$/i.test(fichier)) {
    const D = /<script>window\.[A-Z_]+ = /.exec(src); // la zone de données du lab n'est jamais lue
    const dehors = (idx) => D && idx >= D.index && idx < src.indexOf(';</script>', D.index) + 10;
    let reste = src;
    for (const m of src.matchAll(/<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/gi)) {
      reste = reste.replace(m[0], ' ');
      if (dehors(m.index) || MARQUES.test(m[1])) continue;
      r.push(...constatsScript(sansJournal(m[1]), { ...o, decalage: m.index + m[0].indexOf(m[1]) }));
    }
    const nu = reste.replace(/<!--[\s\S]*?-->/g, ' ');
    for (const brut of textesHtml(nu)) {
      const x = norm(brut);
      if (!x || !estAnglais(x, true) || exclus.has(x) || Object.prototype.hasOwnProperty.call(table, x)) continue;
      r.push({ ligne: ligneDe(src, Math.max(0, src.indexOf(brut.trim().slice(0, 40)))), genre: 'squelette-sans-entree', texte: x });
    }
  } else if (/(^|[\\/])serve\.mjs$/.test(fichier)) { // seules les lignes dont les littéraux atteignent la page (messages), jamais un journal
    let dansDescribe = false;
    src.split('\n').forEach((l, k) => {
      if (/^function describe\w*\(/.test(l)) dansDescribe = true; else if (/^}/.test(l)) dansDescribe = false;
      if (/console\.(log|error|warn)/.test(l) || /^\s*\/\//.test(l)) return;
      if (!dansDescribe && !LIGNE_MESSAGE.test(l)) return;
      for (const c of constatsScript(l, { ...o, tout: l, decalage: 0, hors: true })) if (c.genre === 'libre') r.push({ ...c, ligne: k + 1 });
    });
  } else r.push(...constatsScript(sansJournal(src), o));
  return r.sort((a, b) => a.ligne - b.ligne || (a.genre < b.genre ? -1 : 1));
}

if (process.argv[1] && import.meta.url === pathToFileURL(fs.realpathSync(process.argv[1])).href) {
  const args = process.argv.slice(2), fichiers = [], opt = { sans: false, table: null, excl: path.join(ICI, 'vf-cockpit-fr-exclusions.json') };
  for (let k = 0; k < args.length; k++) {
    if (args[k] === '--sans-entrees') opt.sans = true;
    else if (args[k] === '--table') opt.table = args[++k];
    else if (args[k] === '--exclusions') opt.excl = args[++k];
    else if (args[k].startsWith('--')) { console.error(`option inconnue : ${args[k]}`); process.exit(2); } else fichiers.push(args[k]);
  }
  if (!fichiers.length) {
    console.error('usage : vf-cockpit-fr-sources.mjs [--sans-entrees] [--table <fichier.js>] [--exclusions <fichier.json>] <fichier>…');
    process.exit(2);
  }
  let table, exclusions;
  try {
    if (opt.table) table = tableDe(fs.readFileSync(opt.table, 'utf8')); else table = chargerTable();
    exclusions = JSON.parse(fs.readFileSync(opt.excl, 'utf8')).exclusions || [];
  } catch (e) { console.error(`table ou exclusions illisibles : ${e.message}`); process.exit(2); }
  let n = 0;
  for (const f of fichiers) {
    for (const c of constatsDe(fs.readFileSync(f, 'utf8'), { table, exclusions, fichier: f })) {
      if (opt.sans && (c.genre === 'cle-sans-entree' || c.genre === 'squelette-sans-entree')) continue;
      console.log(`${f}:${c.ligne}\t${c.genre}\t${c.texte}`); n++;
    }
  }
  process.exit(n ? 1 : 0);
}
