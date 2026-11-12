#!/usr/bin/env node
// vf-cockpit-fr-inventaire — inventaire déterministe des chaînes d'interface ANGLAISES d'un rendu servi (67-07, CKPT-09).
// Filet de la traduction : à rejouer après toute édition du moteur ou de ses pages servies.
// Entrées : le HTML des pages servies (index.html, project.html) et le source de serve.mjs du moteur du module.
// Sortie : liste triée et dédoublonnée (ordre des points de code), `${…}` d'un gabarit écrit `{}`.
// Exports : inventaire({ html: [...], serveur }), litteraux(src), textesHtml(html), estAnglais(chaine), chainesBibliotheque(xterm), bibliothequeNonTraitee(xterm, client).
// CLI : node vf-cockpit-fr-inventaire.mjs <sortie> [--json]   Code 0 ; 2 sortie sans index.html.
//
// Ce qui entre : littéraux (apostrophes, guillemets, gabarits) des blocs <script> en ligne, texte et attributs
// placeholder/title/aria-label/alt des balises, y compris celles que décrit un littéral HTML ; pour serve.mjs, les seuls
// littéraux des messages renvoyés à la page (lignes `message:`, `error:`, `text:`, `new Error(` et les fonctions
// `describe*`), jamais une ligne de journal console. Ce qui n'y entre pas : la zone de données du lab, les blocs portant
// le marqueur `// vibeflow:fr` (le dictionnaire lui-même) ou un marqueur d'extension VibeFlow (déjà en français).
// Règle « texte anglais » (estAnglais) : un mot d'au moins 3 lettres ASCII, ni URL, chemin, sélecteur ou propriété CSS,
// tracé SVG, identifiant sans espace en minuscules (classe, événement, clé), ni marque de français (accent, mot-outil).
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const MOTS_FR = new Set(['le', 'la', 'les', 'des', 'du', 'un', 'une', 'est', 'et', 'ou', 'pour', 'sur', 'dans', 'par', 'aux', 'ce', 'cette', 'qui', 'que', 'vous', 'nous', 'votre', 'avec', 'sans', 'aucun', 'aucune', 'jamais', 'tous', 'toutes', 'où', 'au', 'cours', 'fait']);
const AVANT_REGEX = new Set(['return', 'typeof', 'case', 'in', 'of', 'delete', 'void', 'throw', 'new', 'else', 'do', 'yield', 'await']);
const ID = /[\w$]/;
// P70-D-04 (UIFN-07) : mots anglais d'une ou deux lettres qui font à eux seuls un libellé (« up · » d'une aide au clavier)
const COURTS = new Set(['up', 'of', 'at', 'in', 'on', 'to', 'by']);
// clés d'interface : la valeur littérale est toujours inventoriée, même en un seul mot minuscule (`word: 'minor'`)
const CLES_UI = /\b(?:word|label|group|title|hint|kicker|note|text)\s*:\s*$/;

// --- littéraux d'un source JavaScript ---------------------------------------------------------------
// Parcours récursif : commentaires et expressions régulières sautés, gabarits lus avec leurs `${…}` (les littéraux
// imbriqués sont lus à leur tour, le gabarit hôte les écrit `{}`).
export function litteraux(src) {
  const out = [];
  out.cles = new Set(); // valeurs lues sous une clé d'interface (CLES_UI)
  let i = 0;
  const n = src.length;
  const motPrecedent = (k) => { let j = k; while (j > 0 && ID.test(src[j - 1])) j--; return src.slice(j, k); };
  function chaine(q) { // i sur la quote ouvrante ; rend la valeur, i après la quote fermante
    let v = ''; i++;
    while (i < n && src[i] !== q) {
      if (src[i] === '\\') { const c = src[i + 1]; v += c === 'n' ? '\n' : c === 't' ? '\t' : c === 'u' || c === 'x' ? '' : c; i += 2; continue; }
      if (src[i] === '\n') break; v += src[i++];
    }
    i++; return v;
  }
  function gabarit() { // i sur le backtick ouvrant
    let v = ''; i++;
    while (i < n && src[i] !== '`') {
      if (src[i] === '\\') { v += src[i + 1] === 'n' ? '\n' : src[i + 1]; i += 2; continue; }
      if (src[i] === '$' && src[i + 1] === '{') { i += 2; code(1); v += '{}'; continue; }
      v += src[i++];
    }
    i++; out.push(v); return v;
  }
  function code(profondeur) { // lit jusqu'à l'accolade fermante qui ramène la profondeur à 0 (0 = fichier entier)
    let dernier = '';
    while (i < n) {
      const c = src[i];
      if (c === '/' && src[i + 1] === '/') { while (i < n && src[i] !== '\n') i++; continue; }
      if (c === '/' && src[i + 1] === '*') { const e = src.indexOf('*/', i + 2); i = e < 0 ? n : e + 2; continue; }
      if (c === '"' || c === "'") { const avant = src.slice(Math.max(0, i - 24), i); const v = chaine(c); out.push(v); if (CLES_UI.test(avant)) out.cles.add(v); dernier = 'x'; continue; }
      if (c === '`') { gabarit(); dernier = 'x'; continue; }
      if (c === '/') {
        const regex = dernier === '' || '(,=:[!&|?{};+-*%<>~^'.includes(dernier) || AVANT_REGEX.has(motPrecedent(i - (src.slice(0, i).match(/\s*$/)[0].length)));
        if (regex) { i++; let cls = false; while (i < n && (src[i] !== '/' || cls) && src[i] !== '\n') { if (src[i] === '\\') i++; else if (src[i] === '[') cls = true; else if (src[i] === ']') cls = false; i++; } i++; while (i < n && /[a-z]/.test(src[i])) i++; dernier = 'x'; continue; }
      }
      if (c === '{' && profondeur > 0) { profondeur++; }
      if (c === '}' && profondeur > 0) { profondeur--; if (profondeur === 0) { i++; return; } }
      if (!/\s/.test(c)) dernier = c;
      i++;
    }
  }
  code(0);
  return out;
}

// --- texte et attributs d'un fragment HTML ----------------------------------------------------------
const ATTRS = /\b(?:placeholder|title|aria-label|alt)=(?:"([^"]*)"|'([^']*)')/g;
export function textesHtml(html) {
  const r = [];
  for (const m of html.matchAll(ATTRS)) r.push(m[1] ?? m[2]);
  const nu = html.replace(/<(script|style)[\s\S]*?<\/\1>/gi, ' ').replace(/<!--[\s\S]*?-->/g, ' ');
  for (const t of nu.split(/<[^>]*>/)) r.push(t);
  return r;
}

// --- règle « texte anglais d'interface » -------------------------------------------------------------
export function estAnglais(s, texte = false) {
  const t = s.replace(/\s+/g, ' ').trim();
  const mots = t.toLowerCase().split(/[^a-z']+/).filter(Boolean);
  const court = mots.length > 0 && mots.every((w) => COURTS.has(w)) && (texte || /[\s·]/.test(t)); // « up · » : anglais, sans mot de 3 lettres
  if (t.length < 2 || t.length > 600 || !(/[A-Za-z]{3,}/.test(t) || /\{\}\s+[a-z]{2,}\s+\{\}/.test(t) || court)) return false;
  if (/[À-ÿ…«»’]/.test(t) && /[À-ÿ«»]/.test(t)) return false; // accent français : pas de l'anglais
  if (/^(https?:|\/\/|\.{0,2}\/|[a-z]:\\)/i.test(t) || /^[\w.-]+\/[\w./+-]+$/.test(t)) return false; // URL, chemin, type MIME
  if (/^[#.@:[]|^--|^\*|^\$|^<|^[\[(]|^\{(?!\})/.test(t) && !/\s[A-Za-z]{3,}\s/.test(t)) return false; // sélecteur, propriété, balise
  if (/[;{}]/.test(t) && /:/.test(t) && !/\{\}/.test(t)) return false; // déclaration CSS
  if (/[[\]]/.test(t) && /,/.test(t)) return false; // liste de sélecteurs
  if (/^[A-Z][A-Z0-9_]+s?$/.test(t)) return false; // sigle ou constante en majuscules (API, JSON, ORTHOGONAL) : identique dans les deux langues
  if (/\d(px|em|rem|vh|vw|ms|s)\b|rgba?\(|hsla?\(|#[0-9a-f]{3,8}\b|var\(|calc\(|translate|gradient/i.test(t)) return false;
  if (/^[MmLlHhVvCcSsQqTtAaZz0-9 .,-]+$/.test(t) && /\d/.test(t)) return false; // tracé SVG : il porte toujours un chiffre (« Calls » n'en est pas un)
  if (!texte && !/\s/.test(t) && !/^[A-Z]/.test(t)) return false; // identifiant, classe, événement, clé : un seul mot en minuscules (hors nœud de texte)
  if (!/\s/.test(t) && /[a-z][A-Z]|[_-]|\./.test(t)) return false; // camelCase, snake_case, kebab-case, point
  if (/^[\w-]+(\.\w+)+$/.test(t) || /\.(js|mjs|json|html|css|md|svg|png|txt)\b/i.test(t) && !/\s/.test(t)) return false;
  if (/^(application|text|image)\//.test(t) || /^(GET|POST|PUT|DELETE|HEAD)$/.test(t)) return false;
  if (/^[a-z]+(\s+[a-z]+){0,3}$/.test(t) && /^(div|span|button|input|path|svg|rect|circle|text|line|g|a|ul|li)\b/.test(t)) return false;
  for (const w of t.toLowerCase().split(/[^a-zà-ÿ']+/)) if (MOTS_FR.has(w)) return false;
  return true;
}
const normaliser = (s) => s.replace(/\s+/g, ' ').trim();
function ajouter(set, brut, texte = false) {
  if (/<[a-z!/][^>]*>/i.test(brut)) { for (const t of textesHtml(brut)) { const x = normaliser(t); if (x && estAnglais(x, true)) { set.add(x); if (/^\{\}[A-Za-z]/.test(x)) set.add(x.slice(2)); } } return; } // gabarit HTML : son texte ; un `{}` collé peut être une icône : le nœud réel est alors le reste
  const x = normaliser(brut);
  if (x && estAnglais(x, texte)) set.add(x);
}

// pluriels construits à l'exécution : `plural(n, 'mot')` rend « 1 mot » ou « n mots » ; l'inventaire en note les deux formes
const PLURIEL = /\bplural\([^'"`\n]*?,\s*'([^']+)'\s*\)/g;
function plurielsConstruits(src) { const r = []; for (const m of src.matchAll(PLURIEL)) r.push(`{} ${m[1]}`, `{} ${m[1]}s`); return r; }

// --- pages servies --------------------------------------------------------------------------------------
// blocs jamais comptés : le dictionnaire (« // vibeflow:fr »), les extensions VibeFlow (« // VibeFlow ( », déjà en français,
// derrière l'en-tête `/* ui/<fichier> */` posé par le build) et le bloc des requêtes sur le graphe, dont les littéraux sont des
// descriptions d'outils et des réponses lues par l'agent (jamais affichés), et la bibliothèque de mise en page vendorisée
// (marqueur `vibeflow:allow-large-file`, messages d'erreur internes)
const MARQUEURS_FR = /^\s*(?:\/\* ui\/[\w.-]+ \*\/\s*)?\/\/ (?:vibeflow:fr|vibeflow:allow-large-file|VibeFlow \()|^\s*\/\/ [\w-]+ graph queries, shared by the viewer/
const DONNEES = /<script>window\.[A-Z_]+ = /;
const sansJournal = (src) => src.split('\n').filter((l) => !/console\.(log|error|warn|info)\(/.test(l)).join('\n'); // jamais une ligne de journal
function blocs(html) { // { scripts: [source], reste: html sans données ni scripts }
  const d = DONNEES.exec(html);
  let h = html;
  if (d) { const fin = html.indexOf(';</script>', d.index); h = html.slice(0, d.index) + html.slice(fin + ';</script>'.length); }
  const scripts = [];
  const reste = h.replace(/<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/gi, (_, s) => { if (!MARQUEURS_FR.test(s)) scripts.push(s); return ' '; });
  return { scripts, reste };
}

// lignes de serve.mjs dont les littéraux atteignent la page ; jamais une ligne de journal console
const LIGNE_MESSAGE = /\b(message|error|text|title|label)\s*:|new Error\(|\bplain\b/;
function litterauxServeur(src) {
  const out = [];
  let dansDescribe = false;
  for (const l of src.split('\n')) {
    if (/^function describe\w*\(/.test(l)) dansDescribe = true;
    else if (/^}/.test(l)) dansDescribe = false;
    if (/console\.(log|error|warn)/.test(l) || /^\s*\/\//.test(l)) continue;
    if (dansDescribe || LIGNE_MESSAGE.test(l)) out.push(...litteraux(l));
  }
  return out;
}

export function inventaire({ html = [], serveur = '' } = {}) {
  const set = new Set();
  for (const page of html) {
    const { scripts, reste } = blocs(page);
    for (const s of scripts) {
      const src = sansJournal(s), L = litteraux(src);
      for (const l of L) ajouter(set, l, L.cles.has(l));
      for (const f of plurielsConstruits(src)) ajouter(set, f);
    }
    for (const t of textesHtml(reste)) ajouter(set, t, true);
  }
  for (const l of litterauxServeur(serveur)) ajouter(set, l);
  return [...set].sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));
}

// --- chaînes que la bibliothèque du terminal affiche d'elle-même (hors pages servies) --------------------------
// Le bundle xterm porte ses phrases d'interface en anglais, rangées dans un module de réglages : `let i="Terminal input";const s={get:()=>i,set:e=>i=e};t.promptLabel=s`.
// Elles n'apparaissent dans aucune page servie, donc l'inventaire des pages ne les voit pas ; le client du terminal doit les poser en français
// (`Terminal.strings.<clé> = '…'`). chainesBibliotheque lit les défauts du bundle, bibliothequeNonTraitee rend les clés dont le client ne pose pas de valeur française.
export function chainesBibliotheque(xterm) {
  const r = {};
  for (const m of xterm.matchAll(/let (\w+)="([^"]+)";const (\w+)=\{get:\(\)=>\1,set:\w+=>\1=\w+\};\w+\.(\w+)=\3/g)) r[m[4]] = m[2];
  return r;
}
export function bibliothequeNonTraitee(xterm, client) {
  const defauts = chainesBibliotheque(xterm);
  return Object.keys(defauts).filter((cle) => {
    const m = new RegExp(`\\.strings\\.${cle}\\s*=\\s*(['"])((?:(?!\\1).)*)\\1`).exec(client);
    return !m || m[2] === defauts[cle] || estAnglais(m[2], true);
  });
}

export function inventaireDeSortie(sortie) {
  const lire = (f) => { try { return fs.readFileSync(path.join(sortie, f), 'utf8'); } catch { return ''; } };
  return inventaire({ html: [lire('index.html'), lire('project.html')].filter(Boolean), serveur: (() => { try { return fs.readFileSync(path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', 'skills', 'cockpit-moteur', 'assets', 'serve.mjs'), 'utf8'); } catch { return ''; } })() }); // serve.mjs est dans le moteur du module, plus dans la sortie
}

if (process.argv[1] && import.meta.url === pathToFileURL(fs.realpathSync(process.argv[1])).href) {
  const sortie = process.argv.slice(2).find((a) => !a.startsWith('--'));
  if (!sortie || !fs.existsSync(path.join(sortie, 'index.html'))) { console.error('usage : vf-cockpit-fr-inventaire.mjs <sortie du cockpit> [--json]'); process.exit(2); }
  const inv = inventaireDeSortie(path.resolve(sortie));
  console.log(process.argv.includes('--json') ? JSON.stringify(inv, null, 1) : inv.join('\n'));
}
