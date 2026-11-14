// observateurs-cliquet.mjs — cliquet strict des observateurs de mutations par fichier de ui/ et de ses sous-dossiers, *.js (79-17, SOCL-21, P79-D-19). Node seul, aucun processus enfant.
// Un observateur de mutations réparait un état après un redessin ; ce qui le remplace est un événement qui existe (`panel` du moteur, `vf-git:etat`).
// La mesure compte, par fichier du dossier et de ses sous-dossiers (récursif, *.js ; clé = chemin relatif en `/`, ex. `tiroir/tiroir.js` ; aucun lien symbolique suivi, fichier ou dossier : ignoré), les occurrences du mot MutationObserver (constructeur, aide qui reçoit la classe, alias), commentaires compris : une phrase qui porte
// la forme est comptée. La baseline liste les fichiers à plus de 0 (`<chemin relatif> <n>`, trié par octets sur le chemin) et est SERRÉE : le réel doit l'égaler.
// Usage : mesurer <dossier-ui> · juger <dossier-ui> <baseline> · abaisser <dossier-ui> <baseline>
// Verdicts de juger : HAUSSE (réel au-dessus, ou fichier neuf à plus de 0) · PERIMEE (réel au-dessous : la baseline suit la baisse dans le même commit) ·
// ORPHELINE (entrée d'un fichier absent) · FORME (ligne mal formée). Codes : 0 conforme · 1 verdict · 2 usage ou fichier illisible (fermé par défaut).
// `abaisser` réécrit la baseline au réel et refuse (code 1, fichier intact) tout relèvement : une baseline relevée exige dans le message du commit une citation
// d'arbitrage (canal et date) ; la citation n'est pas gardée par machine ici (limite dite).
import fs from 'node:fs';
import path from 'node:path';

const FORME = /\bMutationObserver\b/g; // le mot seul : constructeur, aide (`obs(MutationObserver, …)`), alias, `window.MutationObserver`
const fin = (code, texte) => { if (texte) process.stderr.write(texte + '\n'); process.exit(code); };
const octets = (a, b) => (a < b ? -1 : a > b ? 1 : 0);

// Tous les *.js de ui/ et de ses sous-dossiers, clé = chemin relatif en `/`, compte compris à 0. Un lien symbolique (Dirent) n'est ni descendu ni lu.
function mesurerTout(dossier) {
  const comptes = new Map();
  const descendre = (rel) => {
    let entrees;
    try { entrees = fs.readdirSync(path.join(dossier, rel), { withFileTypes: true }); } catch { return fin(2, `observateurs-cliquet : dossier illisible : ${rel || dossier}`); }
    for (const e of entrees) {
      const cle = rel ? `${rel}/${e.name}` : e.name;
      if (e.isDirectory()) descendre(cle);
      else if (e.isFile() && e.name.endsWith('.js')) {
        let texte;
        try { texte = fs.readFileSync(path.join(dossier, cle), 'utf8'); } catch { return fin(2, `observateurs-cliquet : fichier illisible : ${cle}`); }
        comptes.set(cle, (texte.match(FORME) || []).length);
      }
    }
  };
  descendre('');
  return new Map([...comptes].sort((a, b) => octets(a[0], b[0])));
}
const mesurer = (dossier) => new Map([...mesurerTout(dossier)].filter(([, k]) => k > 0));

function lireBaseline(fichier) {
  let texte;
  try { texte = fs.readFileSync(fichier, 'utf8'); } catch { return fin(2, `observateurs-cliquet : baseline illisible : ${fichier}`); }
  const entrees = new Map(), formes = [];
  texte.split('\n').forEach((ligne, i) => {
    const l = ligne.replace(/\r$/, ''); if (l === '' || l.startsWith('#')) return;
    const m = /^(\S+) (\d+)$/.exec(l);
    if (!m || m[1].startsWith('/') || m[1].split('/').some((s) => s === '' || s === '..') || Number(m[2]) < 1 || entrees.has(m[1])) { formes.push(i + 1); return; }
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
  '# observateurs-baseline.txt — observateurs de mutations (constructeur nu ou qualifié, alias du constructeur, aide qui le construit) par fichier de ui/ et de ses sous-dossiers, clé = chemin relatif (79-17, SOCL-21). Format : <chemin relatif> <n>, trié par octets, n > 0.',
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
