// observateurs-cliquet.mjs — cliquet strict des observateurs de mutations par fichier de ui/*.js (79-17, SOCL-21, P79-D-19). Node seul, aucun processus enfant.
// Un observateur de mutations réparait un état après un redessin ; ce qui le remplace est un événement qui existe (`panel` du moteur, `vf-git:etat`).
// La mesure compte, par fichier du dossier (niveau plat, *.js), les occurrences de la forme constructeur, commentaires compris : une phrase qui porte
// la forme est comptée. La baseline liste les fichiers à plus de 0 (`<fichier> <n>`, trié par octets) et est SERRÉE : le réel doit l'égaler.
// Usage : mesurer <dossier-ui> · juger <dossier-ui> <baseline> · abaisser <dossier-ui> <baseline>
// Verdicts de juger : HAUSSE (réel au-dessus, ou fichier neuf à plus de 0) · PERIMEE (réel au-dessous : la baseline suit la baisse dans le même commit) ·
// ORPHELINE (entrée d'un fichier absent) · FORME (ligne mal formée). Codes : 0 conforme · 1 verdict · 2 usage ou fichier illisible (fermé par défaut).
// `abaisser` réécrit la baseline au réel et refuse (code 1, fichier intact) tout relèvement : une baseline relevée exige dans le message du commit une citation
// d'arbitrage (canal et date) ; la citation n'est pas gardée par machine ici (limite dite).
import fs from 'node:fs';
import path from 'node:path';

const FORME = /new\s+MutationObserver\s*\(/g;
const fin = (code, texte) => { if (texte) process.stderr.write(texte + '\n'); process.exit(code); };
const octets = (a, b) => (a < b ? -1 : a > b ? 1 : 0);

function mesurer(dossier) {
  let noms;
  try { noms = fs.readdirSync(dossier).filter((n) => n.endsWith('.js')); } catch { return fin(2, `observateurs-cliquet : dossier illisible : ${dossier}`); }
  const comptes = new Map();
  for (const n of noms.sort(octets)) {
    let texte;
    try { texte = fs.readFileSync(path.join(dossier, n), 'utf8'); } catch { return fin(2, `observateurs-cliquet : fichier illisible : ${n}`); }
    const k = (texte.match(FORME) || []).length; if (k > 0) comptes.set(n, k);
  }
  return comptes;
}

function lireBaseline(fichier) {
  let texte;
  try { texte = fs.readFileSync(fichier, 'utf8'); } catch { return fin(2, `observateurs-cliquet : baseline illisible : ${fichier}`); }
  const entrees = new Map(), formes = [];
  texte.split('\n').forEach((ligne, i) => {
    const l = ligne.replace(/\r$/, ''); if (l === '' || l.startsWith('#')) return;
    const m = /^(\S+) (\d+)$/.exec(l);
    if (!m || m[1].startsWith('/') || m[1].split('/').includes('..') || m[1].includes('/') || Number(m[2]) < 1 || entrees.has(m[1])) { formes.push(i + 1); return; }
    entrees.set(m[1], Number(m[2]));
  });
  return { entrees, formes };
}

function juger(dossier, fichier) {
  const reel = mesurer(dossier), { entrees, formes } = lireBaseline(fichier), verdicts = [];
  for (const n of formes) verdicts.push(`FORME ligne ${n} de la baseline`);
  for (const [n, k] of reel) {
    const b = entrees.get(n) || 0;
    if (k > b) verdicts.push(`HAUSSE ${n} réel=${k} baseline=${b}`);
    else if (k < b) verdicts.push(`PERIMEE ${n} réel=${k} baseline=${b}`);
  }
  for (const [n, b] of entrees) {
    if (!fs.existsSync(path.join(dossier, n))) verdicts.push(`ORPHELINE ${n} baseline=${b}`);
    else if (!reel.has(n)) verdicts.push(`PERIMEE ${n} réel=0 baseline=${b}`);
  }
  return verdicts;
}

const ENTETE = [
  '# observateurs-baseline.txt — observateurs de mutations (forme constructeur) par fichier de ui/*.js (79-17, SOCL-21). Format : <fichier> <n>, trié, n > 0.',
  '# La baseline est serrée (réel = baseline). Une baisse : node plugin/cockpit/scripts/tests/observateurs-cliquet.mjs abaisser <dossier ui> <ce fichier>.',
  '# Une hausse exige dans le message du commit une citation d\'arbitrage (canal et date) : la règle est « un ajout, un retrait », jamais un relèvement muet.',
];
const [, , mode, dossier, baseline] = process.argv;
if (mode === 'mesurer' && dossier) {
  for (const [n, k] of mesurer(dossier)) console.log(`${n} ${k}`);
} else if (mode === 'juger' && dossier && baseline) {
  const v = juger(dossier, baseline);
  if (v.length) fin(1, v.join('\n') + `\nobservateurs-cliquet : ${v.length} écart(s) à la baseline`);
  console.log('observateurs-cliquet : conforme');
} else if (mode === 'abaisser' && dossier && baseline) {
  const reel = mesurer(dossier), { entrees } = lireBaseline(baseline);
  const hausses = [...reel].filter(([n, k]) => k > (entrees.get(n) || 0)).map(([n]) => n);
  if (hausses.length) fin(1, `observateurs-cliquet : relèvement refusé (${hausses.join(', ')}) : baseline intacte`);
  const corps = [...reel].map(([n, k]) => `${n} ${k}`).join('\n');
  fs.writeFileSync(baseline, ENTETE.join('\n') + '\n' + corps + (corps ? '\n' : ''));
  console.log(`observateurs-cliquet : baseline abaissée (${reel.size} fichier(s))`);
} else fin(2, 'usage : observateurs-cliquet.mjs mesurer <dossier-ui> | juger <dossier-ui> <baseline> | abaisser <dossier-ui> <baseline>');
