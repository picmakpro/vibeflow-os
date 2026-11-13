// colonnes-cliquet.mjs — plafond de 160 colonnes en cliquet par fichier (79-11, SOCL-15, P79-D-19). Node seul, aucun processus enfant.
// Une ligne est « longue » au-delà de 160 points de code (jamais des octets), un CR final retiré. La baseline liste, par fichier du périmètre,
// le nombre de lignes longues (entier supérieur à 0) ; elle est SERRÉE : le réel doit l'égaler. Une baisse se suit par `abaisser`, une hausse
// n'entre qu'avec une citation d'arbitrage direct dans le message du commit (`comparer`). Le marqueur des gros fichiers n'exempte rien.
// Usage : perimetre <racine> [--sans-css] · mesurer <racine> · longues <fichier…> · verifier <racine> <baseline> · comparer <avant> <après> <message>
//         · citation <message> [--directe] · abaisser <racine> <baseline> · initialiser <racine> <baseline>
// Codes : 0 conforme · 1 verdict rouge · 2 usage ou fichier illisible (fermé par défaut). La racine porte scripts/ et skills/cockpit-moteur/.
import fs from 'node:fs';
import path from 'node:path';

const SEUIL = 160; // garde:seuil
const MOTEUR = 'skills/cockpit-moteur';
const ENTETE = [
  '# colonnes-baseline.txt — lignes de plus de 160 points de code, par fichier du périmètre (79-11, P79-D-19). Format : <chemin> <n>, trié, n > 0.',
  '# Le périmètre : scripts/*.mjs du module et lignes AJOUT .js .mjs .css de skills/cockpit-moteur/VENDORED.txt. La baseline est serrée (réel = baseline).',
  '# Une baisse : node plugin/cockpit/scripts/tests/colonnes-cliquet.mjs abaisser plugin/cockpit plugin/cockpit/scripts/tests/colonnes-baseline.txt',
  '# Une hausse (ou un fichier neuf à plus de 0) exige dans le message du commit une citation d\'arbitrage direct (canal et date), jamais une délégation.',
];
const sansCr = (l) => l.replace(/\r$/, ''); // garde:cr
const largeur = (l) => [...sansCr(l)].length; // garde:octets
const comptes = (texte) => texte.split('\n').filter((l) => largeur(l) > SEUIL).length; // garde:lecture
const octets = (a, b) => (a < b ? -1 : a > b ? 1 : 0);
const fin = (code, texte) => { if (texte) process.stderr.write(texte + '\n'); process.exit(code); };
const lire = (f) => { try { return fs.readFileSync(f, 'utf8'); } catch { return fin(2, `colonnes-cliquet : fichier illisible : ${f}`); } };

function perimetre(racine, { css = true } = {}) {
  const liste = [];
  let noms;
  try { noms = fs.readdirSync(path.join(racine, 'scripts'), { withFileTypes: true }); }
  catch { return fin(2, `colonnes-cliquet : dossier scripts/ illisible dans ${racine}`); }
  for (const n of noms) if (n.isFile() && n.name.endsWith('.mjs')) liste.push(`scripts/${n.name}`);
  for (const l of lire(path.join(racine, MOTEUR, 'VENDORED.txt')).split('\n')) {
    const m = l.trim().split(/\s+/);
    if (m[0] !== 'AJOUT' || m.length !== 2) continue;
    if (/\.(js|mjs)$/.test(m[1]) || (css && /\.css$/.test(m[1]))) liste.push(`${MOTEUR}/${m[1]}`);
  }
  return [...new Set(liste)].sort(octets);
}
function mesures(racine, opts) {
  const m = new Map();
  for (const f of perimetre(racine, opts)) m.set(f, comptes(lire(path.join(racine, f))));
  return m;
}
// lit une baseline : { entrees: Map chemin -> n, formes: [lignes mal formées] }
function lireBaseline(texte) {
  const entrees = new Map(), formes = [];
  for (const brut of texte.split('\n')) {
    const l = sansCr(brut).trim();
    if (!l || l.startsWith('#')) continue;
    const c = l.split(/\s+/);
    const segments = (c[0] || '').split('/');
    const bonChemin = c[0] && !c[0].startsWith('/') && !c[0].includes('\\') && !segments.includes('..') && !segments.includes('.');
    if (c.length !== 2 || !bonChemin || !/^[1-9][0-9]*$/.test(c[1]) || entrees.has(c[0])) formes.push(l);
    else entrees.set(c[0], Number(c[1]));
  }
  return { entrees, formes };
}
function verdicts(racine, texteBaseline) {
  const { entrees, formes } = lireBaseline(texteBaseline), reel = mesures(racine), perim = new Set(reel.keys()), v = [];
  for (const l of formes) v.push(['FORME', l]);
  for (const [c, n] of entrees) {
    if (!perim.has(c)) v.push(['ORPHELINE', c]); // garde:orpheline
    else if (reel.get(c) > n) v.push(['HAUSSE', `${c} réel=${reel.get(c)} baseline=${n}`]);
    else if (reel.get(c) < n) v.push(['PERIMEE', `${c} réel=${reel.get(c)} baseline=${n}`]);
  }
  for (const [c, n] of reel) if (n > 0 && !entrees.has(c)) v.push(['HAUSSE', `${c} réel=${n} baseline=0`]);
  return { v, reel };
}
// délégation : lue après normalisation (NFKD, marques combinantes et caractères invisibles retirés), sur le radical « deleg » sans égard à la casse :
// délégation, déléguée, délègue, accent combinant, lettre pleine chasse, largeur nulle y tombent ; filtre lexical, un tour de phrase sans le mot n'y tombe pas
const INVISIBLES = /[\u0300-\u036f\u00ad\u200b-\u200d\u2060\ufeff]/g;
const delegation = (l) => /deleg/i.test(l.normalize('NFKD').replace(INVISIBLES, ''));
// citation d'arbitrage : la forme de citation_ok de la garde G-1 (mot-clé, au moins deux virgules, date ISO) ; « directe » écarte toute ligne de délégation
function citationConforme(message, directe) {
  const conforme = (l) => /arbitrage|décision|decision/.test(l) && (l.match(/,/g) || []).length >= 2 && /[0-9]{4}-[0-9]{2}-[0-9]{2}/.test(l);
  return String(message).split('\n').some((l) => conforme(l) && !(directe && delegation(l)));
}
function ecrire(racine, baseline, reel) {
  const lignes = [...reel].filter(([, n]) => n > 0).sort((a, b) => octets(a[0], b[0])).map(([c, n]) => `${c} ${n}`);
  fs.writeFileSync(baseline, [...ENTETE, ...lignes].join('\n') + '\n');
}

const [mode, a, b, c] = process.argv.slice(2);
const sansCss = process.argv.includes('--sans-css');
if (mode === 'perimetre' && a) { console.log(perimetre(path.resolve(a), { css: !sansCss }).join('\n')); process.exit(0); }
if (mode === 'mesurer' && a) { for (const [f, n] of mesures(path.resolve(a))) if (n > 0) console.log(`${f} ${n}`); process.exit(0); }
if (mode === 'longues' && a) { for (const f of process.argv.slice(3)) console.log(`${f} ${comptes(lire(f))}`); process.exit(0); }
if (mode === 'citation' && a !== undefined) fin(citationConforme(a, process.argv.includes('--directe')) ? 0 : 1);
if (mode === 'verifier' && a && b) {
  const { v, reel } = verdicts(path.resolve(a), lire(b));
  for (const [classe, texte] of v) console.log(`${classe} ${texte}`);
  if (v.length) fin(1, `colonnes-cliquet : ${v.length} écart(s) à la baseline`);
  console.log(`OK fichiers=${reel.size} lignes-longues=${[...reel.values()].reduce((s, n) => s + n, 0)}`); process.exit(0);
}
if (mode === 'comparer' && a && b && c !== undefined) {
  const avant = lireBaseline(lire(a)).entrees, apres = lireBaseline(lire(b)).entrees, hausses = [];
  for (const [f, n] of apres) if (n > (avant.get(f) || 0)) hausses.push(`${f} ${avant.get(f) || 0} -> ${n}`);
  if (hausses.length && !citationConforme(c, true)) {
    for (const h of hausses) console.log(`HAUSSE-SANS-ARBITRAGE ${h}`);
    fin(1, 'colonnes-cliquet : hausse de la baseline sans citation d\'arbitrage direct');
  }
  process.exit(0);
}
if (mode === 'abaisser' && a && b) {
  const racine = path.resolve(a), { v, reel } = verdicts(racine, lire(b));
  const bloque = v.filter(([classe]) => classe === 'HAUSSE' || classe === 'FORME');
  if (bloque.length) {
    for (const [classe, texte] of bloque) console.log(`${classe} ${texte}`);
    fin(1, 'colonnes-cliquet : abaisser refuse un relèvement ou une entrée mal formée ; baseline intacte');
  }
  ecrire(racine, b, reel); process.exit(0);
}
if (mode === 'initialiser' && a && b) {
  if (fs.existsSync(b)) fin(1, 'colonnes-cliquet : la baseline existe déjà (initialiser ne réécrit jamais)');
  ecrire(path.resolve(a), b, mesures(path.resolve(a))); process.exit(0);
}
fin(2, 'usage : colonnes-cliquet.mjs perimetre|mesurer|longues|verifier|comparer|citation|abaisser|initialiser <arguments> (voir l\'en-tête)');
